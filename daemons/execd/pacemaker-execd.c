/*
 * Copyright 2012-2019 the Pacemaker project contributors
 *
 * The version control history for this file may have further details.
 *
 * This source code is licensed under the GNU Lesser General Public License
 * version 2.1 or later (LGPLv2.1+) WITHOUT ANY WARRANTY.
 */

#include <crm_internal.h>

#include <glib.h>
#include <unistd.h>
#include <signal.h>

#include <sys/types.h>
#include <sys/wait.h>

#include <crm/crm.h>
#include <crm/msg_xml.h>
#include <crm/services.h>
#include <crm/common/mainloop.h>
#include <crm/common/ipc.h>
#include <crm/common/ipcs.h>
#include <crm/common/remote_internal.h>

#include "pacemaker-execd.h"

#if defined(HAVE_GNUTLS_GNUTLS_H) && defined(SUPPORT_REMOTE)
#  define ENABLE_PCMK_REMOTE

// Hidden in liblrmd
extern int lrmd_tls_send_msg(crm_remote_t *session, xmlNode *msg, uint32_t id,
                             const char *msg_type);
#endif

static GMainLoop *mainloop = NULL;
static qb_ipcs_service_t *ipcs = NULL;
static stonith_t *stonith_api = NULL;
int lrmd_call_id = 0;

#ifdef ENABLE_PCMK_REMOTE
/* whether shutdown request has been sent */
static sig_atomic_t shutting_down = FALSE;

/* timer for waiting for acknowledgment of shutdown request */
static guint shutdown_ack_timer = 0;

static gboolean lrmd_exit(gpointer data);
#endif

static void
stonith_connection_destroy_cb(stonith_t * st, stonith_event_t * e)
{
    stonith_api->state = stonith_disconnected;
    crm_err("Connection to fencer lost");
    stonith_connection_failed();
}

stonith_t *
get_stonith_connection(void)
{
    if (stonith_api && stonith_api->state == stonith_disconnected) {
        stonith_api_delete(stonith_api);
        stonith_api = NULL;
    }

    if (stonith_api == NULL) {
        int rc = pcmk_ok;

        stonith_api = stonith_api_new();
        rc = stonith_api_connect_retry(stonith_api, crm_system_name, 10);
        if (rc != pcmk_ok) {
            crm_err("Could not connect to fencer in 10 attempts: %s "
                    CRM_XS " rc=%d", pcmk_strerror(rc), rc);
            stonith_api_delete(stonith_api);
            stonith_api = NULL;
        } else {
            stonith_api->cmds->register_notification(stonith_api,
                                                     T_STONITH_NOTIFY_DISCONNECT,
                                                     stonith_connection_destroy_cb);
        }
    }
    return stonith_api;
}

static int32_t
lrmd_ipc_accept(qb_ipcs_connection_t * c, uid_t uid, gid_t gid)
{
    crm_trace("Connection %p", c);
    if (crm_client_new(c, uid, gid) == NULL) {
        return -EIO;
    }
    return 0;
}

static void
lrmd_ipc_created(qb_ipcs_connection_t * c)
{
    crm_client_t *new_client = crm_client_get(c);

    crm_trace("Connection %p", c);
    CRM_ASSERT(new_client != NULL);
    /* Now that the connection is offically established, alert
     * the other clients a new connection exists. */

    notify_of_new_client(new_client);
}

static int32_t
lrmd_ipc_dispatch(qb_ipcs_connection_t * c, void *data, size_t size)
{
    uint32_t id = 0;
    uint32_t flags = 0;
    crm_client_t *client = crm_client_get(c);
    xmlNode *request = crm_ipcs_recv(client, data, size, &id, &flags);

    CRM_CHECK(client != NULL, crm_err("Invalid client");
              return FALSE);
    CRM_CHECK(client->id != NULL, crm_err("Invalid client: %p", client);
              return FALSE);

    CRM_CHECK(flags & crm_ipc_client_response, crm_err("Invalid client request: %p", client);
              return FALSE);

    if (!request) {
        return 0;
    }

    if (!client->name) {
        const char *value = crm_element_value(request, F_LRMD_CLIENTNAME);

        if (value == NULL) {
            client->name = crm_itoa(crm_ipcs_client_pid(c));
        } else {
            client->name = strdup(value);
        }
    }

    lrmd_call_id++;
    if (lrmd_call_id < 1) {
        lrmd_call_id = 1;
    }

    crm_xml_add(request, F_LRMD_CLIENTID, client->id);
    crm_xml_add(request, F_LRMD_CLIENTNAME, client->name);
    crm_xml_add_int(request, F_LRMD_CALLID, lrmd_call_id);

    process_lrmd_message(client, id, request);

    free_xml(request);
    return 0;
}

/*!
 * \internal
 * \brief Free a client connection, and exit if appropriate
 *
 * \param[in] client  Client connection to free
 */
void
lrmd_client_destroy(crm_client_t *client)
{
    crm_client_destroy(client);

#ifdef ENABLE_PCMK_REMOTE
    /* If we were waiting to shut down, we can now safely do so
     * if there are no more proxied IPC providers
     */
    if (shutting_down && (ipc_proxy_get_provider() == NULL)) {
        lrmd_exit(NULL);
    }
#endif
}

static int32_t
lrmd_ipc_closed(qb_ipcs_connection_t * c)
{
    crm_client_t *client = crm_client_get(c);

    if (client == NULL) {
        return 0;
    }

    crm_trace("Connection %p", c);
    client_disconnect_cleanup(client->id);
#ifdef ENABLE_PCMK_REMOTE
    ipc_proxy_remove_provider(client);
#endif
    lrmd_client_destroy(client);
    return 0;
}

static void
lrmd_ipc_destroy(qb_ipcs_connection_t * c)
{
    lrmd_ipc_closed(c);
    crm_trace("Connection %p", c);
}

static struct qb_ipcs_service_handlers lrmd_ipc_callbacks = {
    .connection_accept = lrmd_ipc_accept,
    .connection_created = lrmd_ipc_created,
    .msg_process = lrmd_ipc_dispatch,
    .connection_closed = lrmd_ipc_closed,
    .connection_destroyed = lrmd_ipc_destroy
};

int
lrmd_server_send_reply(crm_client_t * client, uint32_t id, xmlNode * reply)
{

    crm_trace("Sending reply (%d) to client (%s)", id, client->id);
    switch (client->kind) {
        case CRM_CLIENT_IPC:
            return crm_ipcs_send(client, id, reply, FALSE);
#ifdef ENABLE_PCMK_REMOTE
        case CRM_CLIENT_TLS:
            return lrmd_tls_send_msg(client->remote, reply, id, "reply");
#endif
        default:
            crm_err("Could not send reply: unknown client type %d",
                    client->kind);
    }
    return -ENOTCONN;
}

int
lrmd_server_send_notify(crm_client_t * client, xmlNode * msg)
{
    crm_trace("Sending notification to client (%s)", client->id);
    switch (client->kind) {
        case CRM_CLIENT_IPC:
            if (client->ipcs == NULL) {
                crm_trace("Could not notify local client: disconnected");
                return -ENOTCONN;
            }
            return crm_ipcs_send(client, 0, msg, crm_ipc_server_event);
#ifdef ENABLE_PCMK_REMOTE
        case CRM_CLIENT_TLS:
            if (client->remote == NULL) {
                crm_trace("Could not notify remote client: disconnected");
                return -ENOTCONN;
            }
            return lrmd_tls_send_msg(client->remote, msg, 0, "notify");
#endif
        default:
            crm_err("Could not notify client: unknown type %d", client->kind);
    }
    return -ENOTCONN;
}

/*!
 * \internal
 * \brief Clean up and exit immediately
 *
 * \param[in] data  Ignored
 *
 * \return Doesn't return
 * \note   This can be used as a timer callback.
 */
static gboolean
lrmd_exit(gpointer data)
{
    crm_info("Terminating with %d clients",
             crm_hash_table_size(client_connections));

    if (stonith_api) {
        stonith_api->cmds->remove_notification(stonith_api, T_STONITH_NOTIFY_DISCONNECT);
        stonith_api->cmds->disconnect(stonith_api);
        stonith_api_delete(stonith_api);
    }
    if (ipcs) {
        mainloop_del_ipc_server(ipcs);
    }

#ifdef ENABLE_PCMK_REMOTE
    lrmd_tls_server_destroy();
    ipc_proxy_cleanup();
#endif

    crm_client_cleanup();
    g_hash_table_destroy(rsc_list);

    if (mainloop) {
        lrmd_drain_alerts(mainloop);
    }

    crm_exit(CRM_EX_OK);
    return FALSE;
}

/*!
 * \internal
 * \brief Request cluster shutdown if appropriate, otherwise exit immediately
 *
 * \param[in] nsig  Signal that caused invocation (ignored)
 */
static void
lrmd_shutdown(int nsig)
{
#ifdef ENABLE_PCMK_REMOTE
    crm_client_t *ipc_proxy = ipc_proxy_get_provider();

    /* If there are active proxied IPC providers, then we may be running
     * resources, so notify the cluster that we wish to shut down.
     */
    if (ipc_proxy) {
        if (shutting_down) {
            crm_notice("Waiting for cluster to stop resources before exiting");
            return;
        }

        crm_info("Sending shutdown request to cluster");
        if (ipc_proxy_shutdown_req(ipc_proxy) < 0) {
            crm_crit("Shutdown request failed, exiting immediately");

        } else {
            /* We requested a shutdown. Now, we need to wait for an
             * acknowledgement from the proxy host (which ensures the proxy host
             * supports shutdown requests), then wait for all proxy hosts to
             * disconnect (which ensures that all resources have been stopped).
             */
            shutting_down = TRUE;

            /* Stop accepting new proxy connections */
            lrmd_tls_server_destroy();

            /* Older controller versions will never acknowledge our request, so
             * set a fairly short timeout to exit quickly in that case. If we
             * get the ack, we'll defuse this timer.
             */
            shutdown_ack_timer = g_timeout_add_seconds(20, lrmd_exit, NULL);

            /* Currently, we let the OS kill us if the clients don't disconnect
             * in a reasonable time. We could instead set a long timer here
             * (shorter than what the OS is likely to use) and exit immediately
             * if it pops.
             */
            return;
        }
    }
#endif
    lrmd_exit(NULL);
}

/*!
 * \internal
 * \brief Defuse short exit timer if shutting down
 */
void handle_shutdown_ack()
{
#ifdef ENABLE_PCMK_REMOTE
    if (shutting_down) {
        crm_info("Received shutdown ack");
        if (shutdown_ack_timer > 0) {
            g_source_remove(shutdown_ack_timer);
            shutdown_ack_timer = 0;
        }
        return;
    }
#endif
    crm_debug("Ignoring unexpected shutdown ack");
}

/*!
 * \internal
 * \brief Make short exit timer fire immediately
 */
void handle_shutdown_nack()
{
#ifdef ENABLE_PCMK_REMOTE
    if (shutting_down) {
        crm_info("Received shutdown nack");
        if (shutdown_ack_timer > 0) {
            g_source_remove(shutdown_ack_timer);
            shutdown_ack_timer = g_timeout_add(0, lrmd_exit, NULL);
        }
        return;
    }
#endif
    crm_debug("Ignoring unexpected shutdown nack");
}


static pid_t main_pid = 0;
static void
sigdone(void)
{
    exit(CRM_EX_OK);
}

static void
sigreap(void)
{
    pid_t pid = 0;
    int status;
    do {
        /*
         * Opinions seem to differ as to what to put here:
         *  -1, any child process
         *  0,  any child process whose process group ID is equal to that of the calling process
         */
        pid = waitpid(-1, &status, WNOHANG);
        if(pid == main_pid) {
            /* Exit when pacemaker-remote exits and use the same return code */
            if (WIFEXITED(status)) {
                exit(WEXITSTATUS(status));
            }
            exit(CRM_EX_ERROR);
        }

    } while (pid > 0);
}

static struct {
	int sig;
	void (*handler)(void);
} sigmap[] = {
	{ SIGCHLD, sigreap },
	{ SIGINT,  sigdone },
};

static void spawn_pidone(int argc, char **argv, char **envp)
{
    sigset_t set;

    if (getpid() != 1) {
        return;
    }

    sigfillset(&set);
    sigprocmask(SIG_BLOCK, &set, 0);

    main_pid = fork();
    switch (main_pid) {
	case 0:
            sigprocmask(SIG_UNBLOCK, &set, NULL);
            setsid();
            setpgid(0, 0);

            /* Child remains as pacemaker-remoted */
            return;
	case -1:
            perror("fork");
    }

    /* Parent becomes the reaper of zombie processes */
    /* Safe to initialize logging now if needed */

#ifdef HAVE___PROGNAME
    /* Differentiate ourselves in the 'ps' output */
    {
        char *p;
        int i, maxlen;
        char *LastArgv = NULL;
        const char *name = "pcmk-init";

	for(i = 0; i < argc; i++) {
		if(!i || (LastArgv + 1 == argv[i]))
			LastArgv = argv[i] + strlen(argv[i]);
	}

	for(i = 0; envp[i] != NULL; i++) {
		if((LastArgv + 1) == envp[i]) {
			LastArgv = envp[i] + strlen(envp[i]);
		}
	}

        maxlen = (LastArgv - argv[0]) - 2;

        i = strlen(name);
        /* We can overwrite individual argv[] arguments */
        snprintf(argv[0], maxlen, "%s", name);

        /* Now zero out everything else */
        p = &argv[0][i];
        while(p < LastArgv)
            *p++ = '\0';
        argv[1] = NULL;
    }
#endif /* HAVE___PROGNAME */

    while (1) {
	int sig;
	size_t i;

        sigwait(&set, &sig);
        for (i = 0; i < DIMOF(sigmap); i++) {
            if (sigmap[i].sig == sig) {
                sigmap[i].handler();
                break;
            }
        }
    }
}

/* *INDENT-OFF* */
static struct crm_option long_options[] = {
    /* Top-level Options */
    {"help",    0, 0,    '?', "\tThis text"},
    {"version", 0, 0,    '$', "\tVersion information"  },
    {"verbose", 0, 0,    'V', "\tIncrease debug output"},

    {"logfile", 1, 0,    'l', "\tSend logs to the additional named logfile"},
#ifdef ENABLE_PCMK_REMOTE
    {"port", 1, 0,       'p', "\tPort to listen on"},
#endif

    {0, 0, 0, 0}
};
/* *INDENT-ON* */

#ifdef ENABLE_PCMK_REMOTE
#  define EXECD_TYPE "remote"
#else
#  define EXECD_TYPE "local"
#endif

int
main(int argc, char **argv, char **envp)
{
    int flag = 0;
    int index = 0;
    int bump_log_num = 0;
    const char *option = NULL;

    /* If necessary, create PID1 now before any FDs are opened */
    spawn_pidone(argc, argv, envp);

#ifndef ENABLE_PCMK_REMOTE
    crm_log_preinit("pacemaker-execd", argc, argv);
    crm_set_options(NULL, "[options]", long_options,
                    "Resource agent executor daemon for cluster nodes");
#else
    crm_log_preinit("pacemaker-remoted", argc, argv);
    crm_set_options(NULL, "[options]", long_options,
                    "Resource agent executor daemon for Pacemaker Remote nodes");
#endif

    while (1) {
        flag = crm_get_option(argc, argv, &index);
        if (flag == -1) {
            break;
        }

        switch (flag) {
            case 'l':
                crm_add_logfile(optarg);
                break;
            case 'p':
                setenv("PCMK_remote_port", optarg, 1);
                break;
            case 'V':
                bump_log_num++;
                break;
            case '?':
            case '$':
                crm_help(flag, CRM_EX_OK);
                break;
            default:
                crm_help('?', CRM_EX_USAGE);
                break;
        }
    }

    crm_log_init(NULL, LOG_INFO, TRUE, FALSE, argc, argv, FALSE);

    while (bump_log_num > 0) {
        crm_bump_log_level(argc, argv);
        bump_log_num--;
    }

    option = daemon_option("logfacility");
    if(option && safe_str_neq(option, "none")) {
        setenv("HA_LOGFACILITY", option, 1);  /* Used by the ocf_log/ha_log OCF macro */
    }

    option = daemon_option("logfile");
    if(option && safe_str_neq(option, "none")) {
        setenv("HA_LOGFILE", option, 1);      /* Used by the ocf_log/ha_log OCF macro */

        if (daemon_option_enabled(crm_system_name, "debug")) {
            setenv("HA_DEBUGLOG", option, 1); /* Used by the ocf_log/ha_debug OCF macro */
        }
    }

    crm_notice("Starting Pacemaker " EXECD_TYPE " executor");

    /* The presence of this variable allegedly controls whether child
     * processes like httpd will try and use Systemd's sd_notify
     * API
     */
    unsetenv("NOTIFY_SOCKET");

    /* Used by RAs - Leave owned by root */
    crm_build_path(CRM_RSCTMP_DIR, 0755);

    rsc_list = g_hash_table_new_full(crm_str_hash, g_str_equal, NULL, free_rsc);
    ipcs = mainloop_add_ipc_server(CRM_SYSTEM_LRMD, QB_IPC_SHM, &lrmd_ipc_callbacks);
    if (ipcs == NULL) {
        crm_err("Failed to create IPC server: shutting down and inhibiting respawn");
        crm_exit(CRM_EX_FATAL);
    }

#ifdef ENABLE_PCMK_REMOTE
    if (lrmd_init_remote_tls_server() < 0) {
        crm_err("Failed to create TLS listener: shutting down and staying down");
        crm_exit(CRM_EX_FATAL);
    }
    ipc_proxy_init();
#endif

    mainloop_add_signal(SIGTERM, lrmd_shutdown);
    mainloop = g_main_loop_new(NULL, FALSE);
    crm_notice("Pacemaker " EXECD_TYPE " executor successfully started and accepting connections");
    g_main_loop_run(mainloop);

    /* should never get here */
    lrmd_exit(NULL);
    return CRM_EX_OK;
}
