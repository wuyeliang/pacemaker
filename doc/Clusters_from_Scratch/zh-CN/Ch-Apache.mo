��    .      �  =   �      �  �   �  �   �  H  <  �  �
  �    �  �  �  T  j  �  �  K!  �  ,#  R  $%  �   w*  �  2+  ;   *<  i   f<     �<     �<  _   �>  (   O?     x?  '   �?  �   �?  �   j@  �   �@  "   �A  L   �A    B     C     *C  ,   7C  �   dC  �   �C    �D    �E     �G     	H  <  )H  .   fI  �  �I  D   ;K     �K  1   �K  W   �K    #L  	   9N    CN  �   UO  �   �O  H  �P  �  �U  �  y[  �  !_  �  �b  j  Di  �  �l  �  �n  R  �p  �   �u  �  �v  B   ��  L   ч     �  C  =�  U   ��  !   ׉     ��  $   �  j   7�  �   ��  �   <�     ��  K   ݋  �   )�     
�     �  !   &�  �   H�  �   �    ڎ  0  ��     '�     4�  �   M�  '   /�  s  W�  8   ˔     �  -   �  E   E�  �  ��  	   j�                     )         $            
                      -   '         (          %       	                                     +                           *   !             ,       .   &            "   #    
&lt;Location /server-status&gt;
   SetHandler server-status
   Order deny,allow
   Deny from all
   Allow from 127.0.0.1
&lt;/Location&gt;
	   
[root@pcmk-1 ~]# <userinput>cat &lt;&lt;-END &gt;/var/www/html/index.html</userinput>
 &lt;html&gt;
 &lt;body&gt;My Test Site - pcmk-1&lt;/body&gt;
 &lt;/html&gt;
 END
[root@pcmk-1 ~]#
 
[root@pcmk-1 ~]# <userinput>crm configure colocation website-with-ip INFINITY: WebSite ClusterIP</userinput>
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
primitive WebSite ocf:heartbeat:apache \
        params configfile="/etc/httpd/conf/httpd.conf" \
        op monitor interval="1min"
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
<emphasis>colocation website-with-ip inf: WebSite ClusterIP</emphasis>
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Fri Aug 28 16:14:34 2009
Stack: openais
Current DC: pcmk-2 - partition with quorum
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
2 Nodes configured, 2 expected votes
2 Resources configured.
============

Online: [ pcmk-1 pcmk-2 ]

ClusterIP        (ocf::heartbeat:IPaddr):        Started pcmk-2
WebSite        (ocf::heartbeat:apache):        Started pcmk-2
 
[root@pcmk-1 ~]# <userinput>crm configure location prefer-pcmk-1 WebSite 50: pcmk-1</userinput>
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
primitive WebSite ocf:heartbeat:apache \
        params configfile="/etc/httpd/conf/httpd.conf" \
        op monitor interval="1min"
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
<emphasis>location prefer-pcmk-1 WebSite 50: pcmk-1</emphasis>
colocation website-with-ip inf: WebSite ClusterIP
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Fri Aug 28 16:17:35 2009
Stack: openais
Current DC: pcmk-2 - partition with quorum
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
2 Nodes configured, 2 expected votes
2 Resources configured.
============

Online: [ pcmk-1 pcmk-2 ]

ClusterIP        (ocf::heartbeat:IPaddr):        <emphasis>Started pcmk-2</emphasis>
WebSite        (ocf::heartbeat:apache):        <emphasis>Started pcmk-2</emphasis>
 
[root@pcmk-1 ~]# <userinput>crm configure order apache-after-ip mandatory: ClusterIP WebSite</userinput>
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
primitive WebSite ocf:heartbeat:apache \
        params configfile="/etc/httpd/conf/httpd.conf" \
        op monitor interval="1min"
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
colocation website-with-ip inf: WebSite ClusterIP
<emphasis>order apache-after-ip inf: ClusterIP WebSite</emphasis>
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
 
[root@pcmk-1 ~]# <userinput>crm configure primitive WebSite ocf:heartbeat:apache params configfile=/etc/httpd/conf/httpd.conf op monitor interval=1min</userinput>
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
<emphasis>primitive WebSite ocf:heartbeat:apache \</emphasis>
<emphasis> params configfile="/etc/httpd/conf/httpd.conf" \</emphasis>
<emphasis> op monitor interval="1min"</emphasis>
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
 
[root@pcmk-1 ~]# <userinput>crm resource move WebSite pcmk-1</userinput>
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Fri Aug 28 16:19:24 2009
Stack: openais
Current DC: pcmk-2 - partition with quorum
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
2 Nodes configured, 2 expected votes
2 Resources configured.
============

Online: [ pcmk-1 pcmk-2 ]

ClusterIP        (ocf::heartbeat:IPaddr):        Started pcmk-1
WebSite        (ocf::heartbeat:apache):        Started pcmk-1
Notice how the colocation rule we created has ensured that ClusterIP was also moved to pcmk-1.
For the curious, we can see the effect of this command by examining the configuration
crm configure show
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
primitive WebSite ocf:heartbeat:apache \
        params configfile="/etc/httpd/conf/httpd.conf" \
        op monitor interval="1min"
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
<emphasis>location cli-prefer-WebSite WebSite \</emphasis>
<emphasis> rule $id="cli-prefer-rule-WebSite" inf: #uname eq pcmk-1</emphasis>
location prefer-pcmk-1 WebSite 50: pcmk-1
colocation website-with-ip inf: WebSite ClusterIP
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
 
[root@pcmk-1 ~]# <userinput>crm resource unmove WebSite</userinput>
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
primitive WebSite ocf:heartbeat:apache \
        params configfile="/etc/httpd/conf/httpd.conf" \
        op monitor interval="1min"
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
location prefer-pcmk-1 WebSite 50: pcmk-1
colocation website-with-ip inf: WebSite ClusterIP
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
 
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Fri Aug 28 16:12:49 2009
Stack: openais
Current DC: pcmk-2 - partition with quorum
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
2 Nodes configured, 2 expected votes
2 Resources configured.
============

Online: [ pcmk-1 pcmk-2 ]

ClusterIP        (ocf::heartbeat:IPaddr):        Started pcmk-2
WebSite        (ocf::heartbeat:apache):        <emphasis>Started pcmk-1</emphasis>
 
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Fri Aug 28 16:20:53 2009
Stack: openais
Current DC: pcmk-2 - partition with quorum
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
2 Nodes configured, 2 expected votes
2 Resources configured.
============

Online: [ pcmk-1 pcmk-2 ]

 ClusterIP        (ocf::heartbeat:IPaddr):        <emphasis>Started pcmk-1</emphasis>
 WebSite        (ocf::heartbeat:apache):        <emphasis>Started pcmk-1</emphasis>
 
[root@pcmk-1 ~]# <userinput>yum install -y wget</userinput>
Setting up Install Process
Resolving Dependencies
--&gt; Running transaction check
---&gt; Package wget.x86_64 0:1.11.4-5.fc12 set to be updated
--&gt; Finished Dependency Resolution

Dependencies Resolved

===========================================================================================
 Package        Arch             Version                      Repository               Size
===========================================================================================
Installing:
 wget          x86_64          1.11.4-5.fc12                   rawhide                393 k

Transaction Summary
===========================================================================================
Install       1 Package(s)
Upgrade       0 Package(s)

Total download size: 393 k
Downloading Packages:
wget-1.11.4-5.fc12.x86_64.rpm                                            | 393 kB     00:00     
Running rpm_check_debug
Running Transaction Test
Finished Transaction Test
Transaction Test Succeeded
Running Transaction
  Installing     : wget-1.11.4-5.fc12.x86_64                                            1/1 

Installed:
  wget.x86_64 0:1.11.4-5.fc12

Complete!
[root@pcmk-1 ~]#
 
[root@pcmk-2 ~]# <userinput>cat &lt;&lt;-END &gt;/var/www/html/index.html</userinput>
 &lt;html&gt;
 &lt;body&gt;My Test Site - pcmk-2&lt;/body&gt;
 &lt;/html&gt;
 END
[root@pcmk-2 ~]#
 
[root@ppcmk-1 ~]# <userinput>yum install -y httpd</userinput>
Setting up Install Process
Resolving Dependencies
--&gt; Running transaction check
---&gt; Package httpd.x86_64 0:2.2.13-2.fc12 set to be updated
--&gt; Processing Dependency: httpd-tools = 2.2.13-2.fc12 for package: httpd-2.2.13-2.fc12.x86_64
--&gt; Processing Dependency: apr-util-ldap for package: httpd-2.2.13-2.fc12.x86_64
--&gt; Processing Dependency: /etc/mime.types for package: httpd-2.2.13-2.fc12.x86_64
--&gt; Processing Dependency: libaprutil-1.so.0()(64bit) for package: httpd-2.2.13-2.fc12.x86_64
--&gt; Processing Dependency: libapr-1.so.0()(64bit) for package: httpd-2.2.13-2.fc12.x86_64
--&gt; Running transaction check
---&gt; Package apr.x86_64 0:1.3.9-2.fc12 set to be updated
---&gt; Package apr-util.x86_64 0:1.3.9-2.fc12 set to be updated
---&gt; Package apr-util-ldap.x86_64 0:1.3.9-2.fc12 set to be updated
---&gt; Package httpd-tools.x86_64 0:2.2.13-2.fc12 set to be updated
---&gt; Package mailcap.noarch 0:2.1.30-1.fc12 set to be updated
--&gt; Finished Dependency Resolution

Dependencies Resolved

=======================================================================================
 Package               Arch             Version                Repository         Size
=======================================================================================
Installing:
 httpd               x86_64           2.2.13-2.fc12            rawhide           735 k
Installing for dependencies:
 apr                 x86_64           1.3.9-2.fc12             rawhide           117 k
 apr-util            x86_64           1.3.9-2.fc12             rawhide            84 k
 apr-util-ldap       x86_64           1.3.9-2.fc12             rawhide            15 k
 httpd-tools         x86_64           2.2.13-2.fc12            rawhide            63 k
 mailcap             noarch           2.1.30-1.fc12            rawhide            25 k

Transaction Summary
=======================================================================================
Install       6 Package(s)
Upgrade       0 Package(s)

Total download size: 1.0 M
Downloading Packages:
(1/6): apr-1.3.9-2.fc12.x86_64.rpm                                   | 117 kB     00:00     
(2/6): apr-util-1.3.9-2.fc12.x86_64.rpm                              |  84 kB     00:00     
(3/6): apr-util-ldap-1.3.9-2.fc12.x86_64.rpm                         |  15 kB     00:00     
(4/6): httpd-2.2.13-2.fc12.x86_64.rpm                                | 735 kB     00:00     
(5/6): httpd-tools-2.2.13-2.fc12.x86_64.rpm                          |  63 kB     00:00     
(6/6): mailcap-2.1.30-1.fc12.noarch.rpm                              |  25 kB     00:00     
----------------------------------------------------------------------------------------
Total                                                       875 kB/s | 1.0 MB     00:01     
Running rpm_check_debug
Running Transaction Test
Finished Transaction Test
Transaction Test Succeeded
Running Transaction
  Installing     : apr-1.3.9-2.fc12.x86_64                                          1/6 
  Installing     : apr-util-1.3.9-2.fc12.x86_64                                     2/6 
  Installing     : apr-util-ldap-1.3.9-2.fc12.x86_64                                3/6 
  Installing     : httpd-tools-2.2.13-2.fc12.x86_64                                 4/6 
  Installing     : mailcap-2.1.30-1.fc12.noarch                                     5/6 
  Installing     : httpd-2.2.13-2.fc12.x86_64                                       6/6 

Installed:
  httpd.x86_64 0:2.2.13-2.fc12                                                          

Dependency Installed:
  apr.x86_64 0:1.3.9-2.fc12            apr-util.x86_64 0:1.3.9-2.fc12
  apr-util-ldap.x86_64 0:1.3.9-2.fc12  httpd-tools.x86_64 0:2.2.13-2.fc12
  mailcap.noarch 0:2.1.30-1.fc12  

Complete!
[root@pcmk-1 ~]#
 After a short delay, we should see the cluster start apache Also, we need the wget tool in order for the cluster to be able to check the status of the Apache server. Apache - Adding More Services At this point, Apache is ready to go, all that needs to be done is to add it to the cluster. Lets call the resource WebSite. We need to use an OCF script called apache in the heartbeat namespace <footnote> <para> Compare the key used here ocf:heartbeat:apache with the one we used earlier for the IP address: ocf:heartbeat:IPaddr2 </para> </footnote> , the only required parameter is the path to the main Apache configuration file and we’ll tell the cluster to check once a minute that apache is still running. Before continuing, we need to make sure Apache is installed on <emphasis>both</emphasis> hosts. Controlling Resource Start/Stop Ordering Enable the Apache status URL Ensuring Resources Run on the Same Host Even though we now prefer pcmk-1 over pcmk-2, that preference is (intentionally) less than the resource stickiness (how much we preferred not to have unnecessary downtime). First we need to create a page for Apache to serve up. On Fedora the default Apache docroot is /var/www/html, so we’ll create an index file there. For the moment, we will simplify things by serving up only a static site and manually sync the data between the two nodes. So run the command again on pcmk-2. Giving Control Back to the Cluster Highlighted is the automated constraint used to move the resources to pcmk-1 In order to monitor the health of your Apache instance, and recover it if it fails, the resource agent used by Pacemaker assumes the server-status URL is available. Look for the following in /etc/httpd/conf/httpd.conf and make sure it is not disabled or commented out: Include output Installation Manually Moving Resources Around the Cluster Note that the automated constraint is now gone. If we check the cluster status, we can also see that as expected the resources are still active on pcmk-1. Now that we have a basic but functional active/passive two-node cluster, we’re ready to add some real services. We’re going to start with Apache because its a feature of many clusters and relatively simple to configure. Once we’ve finished whatever activity that required us to move the resources to pcmk-1, in our case nothing, we can then allow the cluster to resume normal operation with the unmove command. Since we previously configured a default stickiness, the resources will remain on pcmk-1. Pacemaker does not rely on any sort of hardware symmetry between nodes, so it may well be that one machine is more powerful than the other. In such cases it makes sense to host the resources there if it is available. To do this we create a location constraint. Again we give it a descriptive name (prefer-pcmk-1), specify the resource we want to run there (WebSite), how badly we’d like it to run there (we’ll use 50 for now, but in a two-node situation almost any value above 0 will do) and the host’s name. Preparation Specifying a Preferred Location There are always times when an administrator needs to override the cluster and force resources to move to a specific location. Underneath we use location constraints like the one we created above, happily you don’t need to care. Just provide the name of the resource and the intended location, we’ll do the rest. There is a way to force them to move though... To reduce the load on any one machine, Pacemaker will generally try to spread the configured resources across the cluster nodes. However we can tell the cluster that two resources are related and need to run on the same host (or not at all). Here we instruct the cluster that WebSite can only run on the host that ClusterIP is active on. If ClusterIP is not active anywhere, WebSite will not be permitted to run anywhere. To see the current placement scores, you can use a tool called ptest Update the Configuration Wait a minute, the resources are still on pcmk-2! Wait a moment, the WebSite resource isn’t running on the same host as our IP address! When Apache starts, it binds to the available IP addresses. It doesn’t know about any addresses we add afterwards, so not only do they need to run on the same node, but we need to make sure ClusterIP is already active before we start WebSite. We do this by adding an ordering constraint. We need to give it a name (chose something descriptive like apache-after-ip), indicate that its mandatory (so that any recovery for ClusterIP will also trigger recovery of WebSite) and list the two resources in the order we need them to start. ptest -sL Project-Id-Version: 0
POT-Creation-Date: 2010-12-15T23:32:36
PO-Revision-Date: 2010-12-15 23:37+0800
Last-Translator: Charlie Chen <laneovcc@gmail.com>
Language-Team: None
Language: 
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
 
&lt;Location /server-status&gt;
   SetHandler server-status
   Order deny,allow
   Deny from all
   Allow from 127.0.0.1
&lt;/Location&gt;
	   
[root@pcmk-1 ~]# <userinput>cat &lt;&lt;-END &gt;/var/www/html/index.html</userinput>
 &lt;html&gt;
 &lt;body&gt;My Test Site - pcmk-1&lt;/body&gt;
 &lt;/html&gt;
 END
[root@pcmk-1 ~]#
 
[root@pcmk-1 ~]# <userinput>crm configure colocation website-with-ip INFINITY: WebSite ClusterIP</userinput>
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
primitive WebSite ocf:heartbeat:apache \
        params configfile="/etc/httpd/conf/httpd.conf" \
        op monitor interval="1min"
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
<emphasis>colocation website-with-ip inf: WebSite ClusterIP</emphasis>
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Fri Aug 28 16:14:34 2009
Stack: openais
Current DC: pcmk-2 - partition with quorum
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
2 Nodes configured, 2 expected votes
2 Resources configured.
============

Online: [ pcmk-1 pcmk-2 ]

ClusterIP        (ocf::heartbeat:IPaddr):        Started pcmk-2
WebSite        (ocf::heartbeat:apache):        Started pcmk-2
 
[root@pcmk-1 ~]# <userinput>crm configure location prefer-pcmk-1 WebSite 50: pcmk-1</userinput>
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
primitive WebSite ocf:heartbeat:apache \
        params configfile="/etc/httpd/conf/httpd.conf" \
        op monitor interval="1min"
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
<emphasis>location prefer-pcmk-1 WebSite 50: pcmk-1</emphasis>
colocation website-with-ip inf: WebSite ClusterIP
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Fri Aug 28 16:17:35 2009
Stack: openais
Current DC: pcmk-2 - partition with quorum
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
2 Nodes configured, 2 expected votes
2 Resources configured.
============

Online: [ pcmk-1 pcmk-2 ]

ClusterIP        (ocf::heartbeat:IPaddr):        <emphasis>Started pcmk-2</emphasis>
WebSite        (ocf::heartbeat:apache):        <emphasis>Started pcmk-2</emphasis>
 
[root@pcmk-1 ~]# <userinput>crm configure order apache-after-ip mandatory: ClusterIP WebSite</userinput>
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
primitive WebSite ocf:heartbeat:apache \
        params configfile="/etc/httpd/conf/httpd.conf" \
        op monitor interval="1min"
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
colocation website-with-ip inf: WebSite ClusterIP
<emphasis>order apache-after-ip inf: ClusterIP WebSite</emphasis>
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
 
[root@pcmk-1 ~]# <userinput>crm configure primitive WebSite ocf:heartbeat:apache params configfile=/etc/httpd/conf/httpd.conf op monitor interval=1min</userinput>
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
<emphasis>primitive WebSite ocf:heartbeat:apache \</emphasis>
<emphasis> params configfile="/etc/httpd/conf/httpd.conf" \</emphasis>
<emphasis> op monitor interval="1min"</emphasis>
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
 
[root@pcmk-1 ~]# <userinput>crm resource move WebSite pcmk-1</userinput>
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Fri Aug 28 16:19:24 2009
Stack: openais
Current DC: pcmk-2 - partition with quorum
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
2 Nodes configured, 2 expected votes
2 Resources configured.
============

Online: [ pcmk-1 pcmk-2 ]

ClusterIP        (ocf::heartbeat:IPaddr):        Started pcmk-1
WebSite        (ocf::heartbeat:apache):        Started pcmk-1
Notice how the colocation rule we created has ensured that ClusterIP was also moved to pcmk-1.
For the curious, we can see the effect of this command by examining the configuration
crm configure show
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
primitive WebSite ocf:heartbeat:apache \
        params configfile="/etc/httpd/conf/httpd.conf" \
        op monitor interval="1min"
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
<emphasis>location cli-prefer-WebSite WebSite \</emphasis>
<emphasis> rule $id="cli-prefer-rule-WebSite" inf: #uname eq pcmk-1</emphasis>
location prefer-pcmk-1 WebSite 50: pcmk-1
colocation website-with-ip inf: WebSite ClusterIP
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
 
[root@pcmk-1 ~]# <userinput>crm resource unmove WebSite</userinput>
[root@pcmk-1 ~]# <userinput>crm configure show</userinput>
node pcmk-1
node pcmk-2
primitive WebSite ocf:heartbeat:apache \
        params configfile="/etc/httpd/conf/httpd.conf" \
        op monitor interval="1min"
primitive ClusterIP ocf:heartbeat:IPaddr2 \
        params ip="192.168.122.101" cidr_netmask="32" \
        op monitor interval="30s"
location prefer-pcmk-1 WebSite 50: pcmk-1
colocation website-with-ip inf: WebSite ClusterIP
property $id="cib-bootstrap-options" \
        dc-version="1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7" \
        cluster-infrastructure="openais" \
        expected-quorum-votes="2" \
        stonith-enabled="false" \
        no-quorum-policy="ignore"
rsc_defaults $id="rsc-options" \
        resource-stickiness="100"
 
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Fri Aug 28 16:12:49 2009
Stack: openais
Current DC: pcmk-2 - partition with quorum
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
2 Nodes configured, 2 expected votes
2 Resources configured.
============

Online: [ pcmk-1 pcmk-2 ]

ClusterIP        (ocf::heartbeat:IPaddr):        Started pcmk-2
WebSite        (ocf::heartbeat:apache):        <emphasis>Started pcmk-1</emphasis>
 
[root@pcmk-1 ~]# <userinput>crm_mon</userinput>
============
Last updated: Fri Aug 28 16:20:53 2009
Stack: openais
Current DC: pcmk-2 - partition with quorum
Version: 1.0.5-462f1569a43740667daf7b0f6b521742e9eb8fa7
2 Nodes configured, 2 expected votes
2 Resources configured.
============

Online: [ pcmk-1 pcmk-2 ]

 ClusterIP        (ocf::heartbeat:IPaddr):        <emphasis>Started pcmk-1</emphasis>
 WebSite        (ocf::heartbeat:apache):        <emphasis>Started pcmk-1</emphasis>
 
[root@pcmk-1 ~]# <userinput>yum install -y wget</userinput>
Setting up Install Process
Resolving Dependencies
--&gt; Running transaction check
---&gt; Package wget.x86_64 0:1.11.4-5.fc12 set to be updated
--&gt; Finished Dependency Resolution

Dependencies Resolved

===========================================================================================
 Package        Arch             Version                      Repository               Size
===========================================================================================
Installing:
 wget          x86_64          1.11.4-5.fc12                   rawhide                393 k

Transaction Summary
===========================================================================================
Install       1 Package(s)
Upgrade       0 Package(s)

Total download size: 393 k
Downloading Packages:
wget-1.11.4-5.fc12.x86_64.rpm                                            | 393 kB     00:00     
Running rpm_check_debug
Running Transaction Test
Finished Transaction Test
Transaction Test Succeeded
Running Transaction
  Installing     : wget-1.11.4-5.fc12.x86_64                                            1/1 

Installed:
  wget.x86_64 0:1.11.4-5.fc12

Complete!
[root@pcmk-1 ~]#
 
[root@pcmk-2 ~]# <userinput>cat &lt;&lt;-END &gt;/var/www/html/index.html</userinput>
 &lt;html&gt;
 &lt;body&gt;My Test Site - pcmk-2&lt;/body&gt;
 &lt;/html&gt;
 END
[root@pcmk-2 ~]#
 
[root@ppcmk-1 ~]# <userinput>yum install -y httpd</userinput>
Setting up Install Process
Resolving Dependencies
--&gt; Running transaction check
---&gt; Package httpd.x86_64 0:2.2.13-2.fc12 set to be updated
--&gt; Processing Dependency: httpd-tools = 2.2.13-2.fc12 for package: httpd-2.2.13-2.fc12.x86_64
--&gt; Processing Dependency: apr-util-ldap for package: httpd-2.2.13-2.fc12.x86_64
--&gt; Processing Dependency: /etc/mime.types for package: httpd-2.2.13-2.fc12.x86_64
--&gt; Processing Dependency: libaprutil-1.so.0()(64bit) for package: httpd-2.2.13-2.fc12.x86_64
--&gt; Processing Dependency: libapr-1.so.0()(64bit) for package: httpd-2.2.13-2.fc12.x86_64
--&gt; Running transaction check
---&gt; Package apr.x86_64 0:1.3.9-2.fc12 set to be updated
---&gt; Package apr-util.x86_64 0:1.3.9-2.fc12 set to be updated
---&gt; Package apr-util-ldap.x86_64 0:1.3.9-2.fc12 set to be updated
---&gt; Package httpd-tools.x86_64 0:2.2.13-2.fc12 set to be updated
---&gt; Package mailcap.noarch 0:2.1.30-1.fc12 set to be updated
--&gt; Finished Dependency Resolution

Dependencies Resolved

=======================================================================================
 Package               Arch             Version                Repository         Size
=======================================================================================
Installing:
 httpd               x86_64           2.2.13-2.fc12            rawhide           735 k
Installing for dependencies:
 apr                 x86_64           1.3.9-2.fc12             rawhide           117 k
 apr-util            x86_64           1.3.9-2.fc12             rawhide            84 k
 apr-util-ldap       x86_64           1.3.9-2.fc12             rawhide            15 k
 httpd-tools         x86_64           2.2.13-2.fc12            rawhide            63 k
 mailcap             noarch           2.1.30-1.fc12            rawhide            25 k

Transaction Summary
=======================================================================================
Install       6 Package(s)
Upgrade       0 Package(s)

Total download size: 1.0 M
Downloading Packages:
(1/6): apr-1.3.9-2.fc12.x86_64.rpm                                   | 117 kB     00:00     
(2/6): apr-util-1.3.9-2.fc12.x86_64.rpm                              |  84 kB     00:00     
(3/6): apr-util-ldap-1.3.9-2.fc12.x86_64.rpm                         |  15 kB     00:00     
(4/6): httpd-2.2.13-2.fc12.x86_64.rpm                                | 735 kB     00:00     
(5/6): httpd-tools-2.2.13-2.fc12.x86_64.rpm                          |  63 kB     00:00     
(6/6): mailcap-2.1.30-1.fc12.noarch.rpm                              |  25 kB     00:00     
----------------------------------------------------------------------------------------
Total                                                       875 kB/s | 1.0 MB     00:01     
Running rpm_check_debug
Running Transaction Test
Finished Transaction Test
Transaction Test Succeeded
Running Transaction
  Installing     : apr-1.3.9-2.fc12.x86_64                                          1/6 
  Installing     : apr-util-1.3.9-2.fc12.x86_64                                     2/6 
  Installing     : apr-util-ldap-1.3.9-2.fc12.x86_64                                3/6 
  Installing     : httpd-tools-2.2.13-2.fc12.x86_64                                 4/6 
  Installing     : mailcap-2.1.30-1.fc12.noarch                                     5/6 
  Installing     : httpd-2.2.13-2.fc12.x86_64                                       6/6 

Installed:
  httpd.x86_64 0:2.2.13-2.fc12                                                          

Dependency Installed:
  apr.x86_64 0:1.3.9-2.fc12            apr-util.x86_64 0:1.3.9-2.fc12
  apr-util-ldap.x86_64 0:1.3.9-2.fc12  httpd-tools.x86_64 0:2.2.13-2.fc12
  mailcap.noarch 0:2.1.30-1.fc12  

Complete!
[root@pcmk-1 ~]#
 过了一会，我们可以看到集群把apache启动起来了。 同样的，为了检测Apache服务器，我们要安装wget这个工具。 Apache - 添加更多的服务 现在 ，Apache已经可以添加到集群中了。我们管这个资源叫WebSite。我们需要用一个叫做apache的OCF脚本，这个脚本在heartbeat这个名字空间里，唯一一个需要设定的参数就是Apache的主配置文件路径，并且我们告诉集群每一分钟检测一次Apache是否运行。 在继续之前，我们先确保两个节点<emphasis>都</emphasis>安装了Apache. 控制资源的启动停止顺序 开启 Apache status URL 确保资源在同一个节点运行 即使我们更希望资源在pcmk-1上面运行，但是 这个优先值还是比资源黏性值要小。 首先我们为Apache创建一个主页。在Fedora上面默认的Apache docroot是/var/www/html，所以我们在这个目录下面建立一个主页。 为了方便，我们简化所用的页面并人工地在两个节点直接同步数据。所以在pcmk-2上面运行这个命令。 把控制权交还给集群 斜体部分是用来移动资源到pcmk-1约束，它是自动生成的。 为了监控Apache实例的健康状态,并在它挂掉的时候恢复Apache服务，资源agent会假设 server-status URL是可用的。查看/etc/httpd/conf/httpd.conf并确保下面的选项没有被禁用或注释掉。 Include output 安装Apache 在集群中手工地移动资源 可以看到自动生成的约束已经没有了。如果我们查看集群的状态，我们也可以看到就如我们所预期的，资源还是在pcmk-1上面跑 现在我们有了一个基本的但是功能齐全的双节点集群,我们已经可以往里面加些真的服务了。我们准备启动一个Apache服务，因为它是许多集群的主角，并且相对来说比较容易配置。 当我们完成那些要求要资源移动到pcmk-1的操作－－在我们的例子里面啥都没干 －－我们可以用unmove命令把集群恢复到强制移动前的状态。因为我们之前配置了默认的资源黏性值，恢复了以后资源还是会在pcmk-1上面。 Pacemaker 并不要求你机器的硬件配置是相同的，可能某些机器比另外的机器配置要好。这种状况下我们会希望设置:当某个节点可用时，资源就要跑在上面之类的规则。为了达到这个效果我们创建location约束。同样的，我们给他取一个描述性的名字(prefer-pcmk-1)，指明我们想在上面跑WebSite这个服务，多想在上面跑(我们现在指定分值为50，但是在双节点的集群状态下，任何大于0的值都可以达到想要的效果)，以及目标节点的名字: 准备工作 指定优先的 Location 经常性的会有管理员想要无视集群然后强制把资源移动到指定的地方。 底层的操作就像我们上面创建的location约束一样。只要提供资源和目标地址，我们会补全剩余部分。 这里有个办法强制地移动资源 为了减少每个机器的负载，Pacemaker会智能地尝试将资源分散到各个节点上面。 然而我们可以告诉集群某两个资源是有联系并且要在同一个节点运行(或不同的节点运行)。这里我们告诉集群WebSite只能在有ClusterIP的节点上运行。如果ClusterIP在哪个节点都不存在，那么WebSite也不能运行。 如果要看现在的分值，可以用ptest这个命令 更新配置文件 等等，资源还是在pcmk-2上面跑的！ 等等！WebSite这个资源跟IP没有跑在同一个节点上面！ 当Apache启动了，它跟可用的IP绑在了一起。它不会知道我们后来添加的IP，所以我们不仅需要控制他们在相同的节点运行，也要确保ClusterIP在WebSite之前就启动了。我们用添加ordering约束来达到这个效果。我们需要给这个order取个名字(apache-after-ip之类 描述性的)，并指出他是托管的(这样当ClusterIP恢复了，同时会触发WebSite的恢复) 并且写明了这两个资源的启动顺序。 ptest -sL 