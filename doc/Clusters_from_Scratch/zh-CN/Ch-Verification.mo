��          �      <      �  �   �  �  ?    �  �    e  �
  �    �   �  o   r  "   �  S     Z   Y  4   �      �     
     &     C  T   a    �  �   �  �  V      �    e  �  �  3   �   �#  {   �$  (   %  Q   .%  Z   �%  1   �%  !   &     /&     E&     ]&  K   v&                                                                               
           	           
[root@pcmk-1 ~]# <userinput>/etc/init.d/corosync start</userinput>
<emphasis>Starting Corosync Cluster Engine (corosync): [ OK ]</emphasis>
 
[root@pcmk-1 ~]# <userinput>grep -e "corosync.*network interface" -e "Corosync Cluster Engine" -e "Successfully read main configuration file" /var/log/messages</userinput>
Aug 27 09:05:34 pcmk-1 corosync[1540]: [MAIN  ] Corosync Cluster Engine ('1.1.0'): started and ready to provide service.
Aug 27 09:05:34 pcmk-1 corosync[1540]: [MAIN  ] Successfully read main configuration file '/etc/corosync/corosync.conf'.
[root@pcmk-1 ~]# <userinput>grep TOTEM /var/log/messages</userinput>
Aug 27 09:05:34 pcmk-1 corosync[1540]: [TOTEM ] Initializing transport (UDP/IP).
Aug 27 09:05:34 pcmk-1 corosync[1540]: [TOTEM ] Initializing transmit/receive security: libtomcrypt SOBER128/SHA1HMAC (mode 0).
Aug 27 09:05:35 pcmk-1 corosync[1540]: [TOTEM ] <emphasis>The network interface [192.168.122.101] is now up.</emphasis>
Aug 27 09:05:35 pcmk-1 corosync[1540]: [TOTEM ] <emphasis>A processor joined or left the membership and a new membership was formed.</emphasis>
 
[root@pcmk-1 ~]# <userinput>grep ERROR: /var/log/messages | grep -v unpack_resources</userinput>
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Thu Aug 27 16:54:55 2009
<emphasis>Stack: openais</emphasis>
Current DC: pcmk-1 - <emphasis>partition with quorum</emphasis>
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
<emphasis>2 Nodes configured, 2 expected votes</emphasis>
<emphasis>0 Resources configured</emphasis>.
============

<emphasis>Online: [ pcmk-1 pcmk-2 ]</emphasis>
 
[root@pcmk-1 ~]# <userinput>grep TOTEM /var/log/messages</userinput>
Aug 27 09:05:34 pcmk-1 corosync[1540]: [TOTEM ] Initializing transport (UDP/IP).
Aug 27 09:05:34 pcmk-1 corosync[1540]: [TOTEM ] Initializing transmit/receive security: libtomcrypt SOBER128/SHA1HMAC (mode 0).
Aug 27 09:05:35 pcmk-1 corosync[1540]: [TOTEM ] <emphasis>The network interface [192.168.122.101] is now up.</emphasis>
Aug 27 09:05:35 pcmk-1 corosync[1540]: [TOTEM ] <emphasis>A processor joined or left the membership and a new membership was formed.</emphasis>
Aug 27 09:12:11 pcmk-1 corosync[1540]: [TOTEM ] <emphasis>A processor joined or left the membership and a new membership was formed</emphasis>.
 
[root@pcmk-1 ~]# <userinput>grep pcmk_startup /var/log/messages</userinput>
Aug 27 09:05:35 pcmk-1 corosync[1540]:   [pcmk  ] info: pcmk_startup: <emphasis>CRM: Initialized</emphasis>
Aug 27 09:05:35 pcmk-1 corosync[1540]:   [pcmk  ] Logging: Initialized pcmk_startup
Aug 27 09:05:35 pcmk-1 corosync[1540]:   [pcmk  ] info: pcmk_startup: Maximum core file size is: 18446744073709551615
Aug 27 09:05:35 pcmk-1 corosync[1540]:   [pcmk  ] info: pcmk_startup: <emphasis>Service: 9</emphasis>
Aug 27 09:05:35 pcmk-1 corosync[1540]:   [pcmk  ] info: pcmk_startup: <emphasis>Local hostname: pcmk-1</emphasis>
 
[root@pcmk-1 ~]# <userinput>ps axf</userinput>
  PID TTY      STAT   TIME COMMAND
    2 ?        S&lt;     0:00 [kthreadd]
    3 ?        S&lt;     0:00  \_ [migration/0]
... lots of processes ...
 2166 pts/0    SLl    0:01 <emphasis>/usr/sbin/corosync</emphasis>
 2172 ?        SLs    0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>stonithd</emphasis>
 2173 pts/0    S      0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>cib</emphasis>
 2174 pts/0    S      0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>lrmd</emphasis>
 2175 pts/0    S      0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>attrd</emphasis>
 2176 pts/0    S      0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>pengine</emphasis>
 2177 pts/0    S      0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>crmd</emphasis>
 
[root@pcmk-1 ~]# <userinput>ssh pcmk-2 -- /etc/init.d/corosync start</userinput>
<emphasis>Starting Corosync Cluster Engine (corosync): [ OK ]</emphasis>
[root@pcmk-1 ~]#
 And finally, check for any ERRORs during startup, there shouldn’t be any, and display the cluster’s status. Check the cluster formed correctly Check the cluster started correctly and that an initial membership was able to form Now that we have confirmed that Corosync is functional we can check the rest of the stack. Now verify the Pacemaker processes have been started Start Corosync on the first node Verify Cluster Installation Verify Corosync Installation Verify Pacemaker Installation With one node functional, its now safe to start Corosync on the second node as well. Project-Id-Version: 0
POT-Creation-Date: 2010-12-15T23:32:37
PO-Revision-Date: 2010-12-16 00:39+0800
Last-Translator: Charlie Chen <laneovcc@gmail.com>
Language-Team: None
Language: 
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
 
[root@pcmk-1 ~]# <userinput>/etc/init.d/corosync start</userinput>
<emphasis>Starting Corosync Cluster Engine (corosync): [ OK ]</emphasis>
 
[root@pcmk-1 ~]# <userinput>grep -e "corosync.*network interface" -e "Corosync Cluster Engine" -e "Successfully read main configuration file" /var/log/messages</userinput>
Aug 27 09:05:34 pcmk-1 corosync[1540]: [MAIN  ] Corosync Cluster Engine ('1.1.0'): started and ready to provide service.
Aug 27 09:05:34 pcmk-1 corosync[1540]: [MAIN  ] Successfully read main configuration file '/etc/corosync/corosync.conf'.
[root@pcmk-1 ~]# <userinput>grep TOTEM /var/log/messages</userinput>
Aug 27 09:05:34 pcmk-1 corosync[1540]: [TOTEM ] Initializing transport (UDP/IP).
Aug 27 09:05:34 pcmk-1 corosync[1540]: [TOTEM ] Initializing transmit/receive security: libtomcrypt SOBER128/SHA1HMAC (mode 0).
Aug 27 09:05:35 pcmk-1 corosync[1540]: [TOTEM ] <emphasis>The network interface [192.168.122.101] is now up.</emphasis>
Aug 27 09:05:35 pcmk-1 corosync[1540]: [TOTEM ] <emphasis>A processor joined or left the membership and a new membership was formed.</emphasis>
 
[root@pcmk-1 ~]# <userinput>grep ERROR: /var/log/messages | grep -v unpack_resources</userinput>
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Thu Aug 27 16:54:55 2009
<emphasis>Stack: openais</emphasis>
Current DC: pcmk-1 - <emphasis>partition with quorum</emphasis>
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
<emphasis>2 Nodes configured, 2 expected votes</emphasis>
<emphasis>0 Resources configured</emphasis>.
============

<emphasis>Online: [ pcmk-1 pcmk-2 ]</emphasis>
 
[root@pcmk-1 ~]# <userinput>grep TOTEM /var/log/messages</userinput>
Aug 27 09:05:34 pcmk-1 corosync[1540]: [TOTEM ] Initializing transport (UDP/IP).
Aug 27 09:05:34 pcmk-1 corosync[1540]: [TOTEM ] Initializing transmit/receive security: libtomcrypt SOBER128/SHA1HMAC (mode 0).
Aug 27 09:05:35 pcmk-1 corosync[1540]: [TOTEM ] <emphasis>The network interface [192.168.122.101] is now up.</emphasis>
Aug 27 09:05:35 pcmk-1 corosync[1540]: [TOTEM ] <emphasis>A processor joined or left the membership and a new membership was formed.</emphasis>
Aug 27 09:12:11 pcmk-1 corosync[1540]: [TOTEM ] <emphasis>A processor joined or left the membership and a new membership was formed</emphasis>.
 
[root@pcmk-1 ~]# <userinput>grep pcmk_startup /var/log/messages</userinput>
Aug 27 09:05:35 pcmk-1 corosync[1540]:   [pcmk  ] info: pcmk_startup: <emphasis>CRM: Initialized</emphasis>
Aug 27 09:05:35 pcmk-1 corosync[1540]:   [pcmk  ] Logging: Initialized pcmk_startup
Aug 27 09:05:35 pcmk-1 corosync[1540]:   [pcmk  ] info: pcmk_startup: Maximum core file size is: 18446744073709551615
Aug 27 09:05:35 pcmk-1 corosync[1540]:   [pcmk  ] info: pcmk_startup: <emphasis>Service: 9</emphasis>
Aug 27 09:05:35 pcmk-1 corosync[1540]:   [pcmk  ] info: pcmk_startup: <emphasis>Local hostname: pcmk-1</emphasis>
 
[root@pcmk-1 ~]# <userinput>ps axf</userinput>
  PID TTY      STAT   TIME COMMAND
    2 ?        S&lt;     0:00 [kthreadd]
    3 ?        S&lt;     0:00  \_ [migration/0]
... lots of processes ...
 2166 pts/0    SLl    0:01 <emphasis>/usr/sbin/corosync</emphasis>
 2172 ?        SLs    0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>stonithd</emphasis>
 2173 pts/0    S      0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>cib</emphasis>
 2174 pts/0    S      0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>lrmd</emphasis>
 2175 pts/0    S      0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>attrd</emphasis>
 2176 pts/0    S      0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>pengine</emphasis>
 2177 pts/0    S      0:00  <emphasis>\_ </emphasis>/usr/lib64/heartbeat/<emphasis>crmd</emphasis>
 
[root@pcmk-1 ~]# <userinput>ssh pcmk-2 -- /etc/init.d/corosync start</userinput>
<emphasis>Starting Corosync Cluster Engine (corosync): [ OK ]</emphasis>
[root@pcmk-1 ~]#
 最后我们检查启动的过程中有没有错误，按照常理应该没有任何错误并显示集群当前的状态。 检查集群关系有没有正确建立: 查看集群是否正确启动并且已经可以与其他节点建立集群关系 现在我们已经确认Corosync正常，我们可以开始检查其他部分是否正常. 现在确认pacemaker进程是否正常启动了: 在第一个节点启动Corosync: 检验集群的安装 检验Corosync的安装 检查Pacemaker的安装 第一个节点正常以后，我们可以安全地启动第二个节点。 