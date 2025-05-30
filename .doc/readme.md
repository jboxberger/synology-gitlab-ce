#### Logfiles Hooks preisntall, postinstall etc..
/var/log/packages/synology-gitlab-ce.log

#### Logfile Package Manager
/var/log/synopkg.log
/var/log/synoplugin.log
/var/log/synoscgi.log

#### Common Error messages
/var/log/messages

#### Package Folder
/var/packages/synology-gitlab-ce
/var/packages/synology-gitlab-ce/var        # docker-compse.yaml
/var/packages/synology-gitlab-ce/installing # status file install is running

#### force uninstall classic package
rm /var/packages/synology-gitlab-ce/conf/resource.own
uninstall

/volume1/@appconf/synology-gitlab-ce
/var/packages/synology-gitlab-ce/etc