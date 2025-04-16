## synology-gitlab-ce

This is a docker based GitLab CE package for Synology NAS server using the original [gitlab/gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce/) image from hub.docker.com. 
The goal of this project is to lower the entry barrier for new GitLab users and give experienced users a little comfort in maintaining their GitLab installation.     

Everything this package does, can be also done manually over the Synology Docker NAS Application.    

Please note that I can not give you support for GitLab itself, this project covers only the Synology installation/update routines.
If you need GitLab Support you might get it here [https://forum.gitlab.com](https://forum.gitlab.com). 

### Download SPK:
You can download the SPK file in the [Releases](https://github.com/jboxberger/synology-gitlab-ce/releases) section.

### Hardware Requirements:
- 1 CPU core ( 2 cores is recommended )
- 2 GB RAM ( 4GB RAM is recommended )
- DSM 6.0 and DSM 7.0 compatible

### Classic:
very simplistic package, installation and basic configuration over DSM, no ssh or root privileges 
required. But this comes with a tradeoff, container configuration (ports,volumes,etc.) after the installation is not 
possible. This is because of the DSM no root privilege policy. However the settings can be changed but only by uninstalling
and reinstalling the package again. During uninstallation of this package all data will be deleted by DSM. Please do not 
forget to backup before. Upgrade to Advanced is possible, but be careful and backup, backup, backup!

<span style="color:red">WARNING: </span> All gitlab data will be deleted on uninstall! Backup berfore uninstalling!

![Classic installer image](images/gitlab-ce-classic-1.png "Classic installer")

### Advanced: 
this approach bypass the root privileges limitation of the DSM by running the setup over ssh. The final container 
runs exactly with the same privileges and setup as the classic non-root approach but you need to execute the installer 
as root to get the setup done. This is a more flexible variant because this way you get the full access to the container
settings and an update simply exports you current container configuration and imports it again with a modified GitLab image version.
This way all your configuration remains the same and you can downgrade and upgrade as you like. As far as GitLab supports the downgrade
with your specific dataset. The ssh installer/updater gives you also the ability to run multiple gitlab container instances with 
different container/versions and different data shares. You can test your upgrades and migrations without any risk and downtime.

![Advanced installer DSM image](images/gitlab-ce-advanced-1.png "Advanced installer DSM")

**Install Advanced Instance**
![Advanced installer install image](images/gitlab-ce-advanced-3.png "Advanced installer install")

**Update Advanced Instance**
![Advanced installer update image](images/gitlab-ce-advanced-4.png "Advanced installer update")

**Multiple Advanced Instances**
![Advanced multiple instances](images/gitlab-ce-advanced-2.png "Advanced multiple instances")

### Overview Advanced vs Classic
| Feature                                                     | Advanced | Classic |
|-------------------------------------------------------------|:--------:|:-------:|
| DSM only install                                            | &cross;  | &check; |
| requires ssh for install                                    | &check;  | &cross; |
| requires root privileges                                    | &check;  | &cross; |
| gitlab can be upgraded                                      | &check;  | &check; |
| gitlab can be downgraded                                    | &check;  | &cross; |
| multiple parallel gitlab instances                          | &check;  | &cross; |
| start/stop over Synology Package Manager                    | &cross;  | &check; |
| start/stop over Synology Docker app                         | &check;  | &cross; |
| exposed gitlab configuration and data                       | &check;  | &check; |
| container settings accessible                               | &check;  | &cross; |
| access to container environment variables                   | &check;  | &cross; |
| keeps container settings (ports, volumes, links) on updates | &check;  | &cross; |
| GitLab files (data, config) remains on package uninstall    | &check;  | &cross; |

### Build instructions
Clone this repository and execute the build.sh shell script within your terminal 
application. This can be done on any linux and should also work on WSL. 
Except "jq" there are no special packages/binaries required.
```bash
# Syntax: build.sh [options]
# options:
#   --version - GitLab CE version e.g. 13.4.3-ce.0, 
#               when no version given, a selection list of the latest
#               available versions is shown
#   --type    - package type (classic|advanced) - default: classic
#   --dsm     - target DSM version (6|7) - default: 7

./build.sh --version=13.4.3-ce.0 --dsm=7 --type=classic
```

### GitLab Upgrade Path
It's highly recommended to follow the upgrade path especially if you update to another major release. You can check the
recommended upgrade path [here](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/?edition=ce). Please take your 
time and make backups in between updates. Be Patient during update, this may take up to 30 minutes. You can see the 
progress in the Docker app in the Details->Protocol tab. Once no new lines occur in the protocol and the container 
consume over 4GB RAM, the update should be complete.   

see: https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/?edition=ce



### Install/Update Classic Instance
Download the desired SPK Version and install it. If you have a previous version of Gitlab installed, just install the 
new SPK over the existing Gitlab installation. This will automatically update the existing installation.  

### Install Advanced Instance
```bash
# Location: /var/packages/synology-gitlab-ce/scripts
# Syntax: gitlab <action> <container> [options]
# arguments:
#   action       - install or update
#   container    - container name
# options:
#   --version    - GitLab CE version e.g. 13.4.3-ce.0
#   --share      - destination folder which will contain shared gitlab files
#   --port-ssh   - ssh host port
#   --port-http  - http host port
#   --port-https - https host port

cd /var/packages/synology-gitlab-ce/scripts && \
sudo sh gitlab install synology-gitlab-ce \
--version=13.4.3-ce.0 \
--share=synology-gitlab-ce \
--port-ssh=30022 \
--port-http=30080 \
--port-https=30443
```

### Update Advanced Instance
```bash
cd /var/packages/synology-gitlab-ce/scripts && \
sudo sh gitlab update synology-gitlab-ce --version=13.4.5-ce.0
```

### Connect into container
If you want to bash into your gitlab container you can do this with this command
```bash
sudo docker exec -it "<gitlab-container-name>" bash 
```

### Reset Password 
If you forgot your password or after the install GitLab does not redirect you to the 
password reset form. You can reset your password from the command line. On a fresh 
install the main user is 'root'. See also the [documentation](https://docs.gitlab.com/ee/security/reset_user_password.html).
```bash
sudo docker exec -it "<gitlab-container-name>" bash -c "gitlab-rake 'gitlab:password:reset'" 
```

### GitLab Configuration
For configuration of the omnibus based GitLab image please refer to this documentation [https://docs.gitlab.com/omnibus/settings](https://docs.gitlab.com/omnibus/settings).
```bash
# after any change to the gitlab configuration you need to reconfigure 
# gitlab and restart the services, which can be done with this two 
# commands from your ssh terminal   
# gitlab omnibus config: /etc/gitlab/gitlab.rb

sudo docker exec -t "<gitlab-container-name>" bash -c "gitlab-ctl reconfigure"
sudo docker exec -t "<gitlab-container-name>" bash -c "gitlab-ctl restart"
```

### SSL (self-signed) helper
This helper installs for you a self-signed SSL certificate to your gitlab container and configures your gitlab to use this. 
Please do not use this for public accessible instances, this approach only makes sense if you run your GitLab private on 
your LAN and you're lazy to do a proper SSL certificate and install it. In any other case i recommend you to use 
the [GitLab Let's Encrypt](https://docs.gitlab.com/omnibus/settings/ssl.html#lets-encrypt-integration) integration.
```bash
# Location: /var/packages/synology-gitlab-ce/scripts
# Syntax: gitlab-self-signed-cert <action> [<container>] [options]
# arguments:
#   action       - install
#   container    - container name
# options:
#   --hostname   - gitlab hostname - default: xpenology
#   --https-port - https port - default: 80443

cd /var/packages/synology-gitlab-ce/scripts && \
sudo sh gitlab-self-signed-cert install synology-gitlab-ce \
  --hostname=xpenology --https-port=80443
```

### Shortcut helper
If your GitLab shortcut in your DSM got broken or points to the wrong container (port) you can fix it with this helper anytime.
```bash
# Location: /var/packages/synology-gitlab-ce/scripts
# Syntax: gitlab-link-fix [options]
# options:
#   --protocol   - protocol http|https - default: http
#   --port       - port - default: 30080

cd /var/packages/synology-gitlab-ce/scripts && \
sudo sh gitlab-link-fix --protocol=https --port=30443
```

### Backup
Please refer to this documentation [here](https://docs.gitlab.com/omnibus/settings/backups.html).
It is not recommended to store data backups in the same location as your config/credentials backup. Because of this, the 
backup process is split into two steps, the config backup and the data backup.
```bash
# backup gitlab configuration
# you will find you backups in this folder 
# /docker/<gitlab-container-share>/config/config_backup 
sudo docker exec -it "<gitlab-container-name>" gitlab-ctl backup-etc

# backup gitlab data (repositories and content)
# you will find you backups in this folder 
# /docker/<gitlab-container-share>/data/backups
sudo docker exec -it "<gitlab-container-name>" gitlab-backup 
```

### Restore
Please refer to the GitLab documentation [here](https://docs.gitlab.com/ee/raketasks/backup_restore.html#restore-gitlab).
```bash
# restore gitlab configuration
# unzip your configuration backup to the config folder overwriting existing files 
# config folder: /docker/<gitlab-container-share>/config
# after that you can continue with the data restore

# restore gitlab data
# copy your data backup to the data/backups folder 
# /docker/<gitlab-container-share>/data/backups
sudo docker exec -it "<gitlab-container-name>" gitlab-ctl stop puma   
sudo docker exec -it "<gitlab-container-name>" gitlab-ctl stop sidekiq
# verify puma & sidekiq are down
sudo docker exec -it "<gitlab-container-name>" gitlab-ctl status    
# fix permissions
sudo docker exec -it "<gitlab-container-name>" chown git:git /var/opt/gitlab/backups/1647529095_2022_03_17_13.4.3_gitlab_backup.tar
# restore, please omit the "_gitlab_backup.tar" from the backup archive name
sudo docker exec -it "<gitlab-container-name>" gitlab-backup restore BACKUP=1647529095_2022_03_17_13.4.3

# restart the GitLab container
sudo docker restart "<gitlab-container-name>"

# check GitLab
sudo docker exec -it "<gitlab-container-name>" gitlab-rake gitlab:check SANITIZE=true
```

### Set external URL
The Problem here is that the nginx within the container is running on port 80 and this is not exposeable to your 
DSM without big hassle. If you are not familiar with vi editor, please see: [How to edit with vi eidtor](https://www.redhat.com/sysadmin/introduction-vi-editor).
```bash
# connect to gitlab container
sudo docker exec -it "<gitlab-container-name>" bash 

# edit config file 
vi /etc/gitlab/gitlab.rb
  # search for '# external_url 'GENERATED_EXTERNAL_URL'
  external_url 'http://<external_url>:<external_port>'
  # the port in the external_url force nginx to run on another port, we have to set it back to 80/443 because of our 
  # container port mapping
  # search for '# nginx['listen_port'] = nil'
  nginx['listen_port'] = 80
```

### Create GitLab Runner
Migration can only be done within the same GitLab version. Its is basically a backup from synology-gitlab package and restore to
the synology-gitlab-ce package.
```bash
# 1) ssh into your synology and run 
sudo ln -s /var/run/docker.sock /volume1/docker/docker.sock
# 2) download tools/gitlab-runner.json and upload to your synology on any folder over DSM (fil should be accessible over DSM)
# 3) Go to your Docker App Settings->Import and select the gitlab-runner.json and start the import
# 4) bash into your gitlab-runner container
docker exec -it <gitlab-runner-name> bash
# 5) execute the registration command you get from here () http://<external_url>:<external_port>/admin/runners/new
gitlab-runner register  --url http://<external_url>:<external_port>  --token <token>
```


### Migration from [synology-gitlab](https://github.com/jboxberger/synology-gitlab) package
Migration can only be done within the same GitLab version. Its is basically a backup from synology-gitlab package and restore to
the synology-gitlab-ce package.
```bash
# backup config 
# @todo: not found a automated way yet
# here is the config located but its structure differs from the omnibus package, need 
# review and testing. For now, you can look up needed configuration and transfer it 
# manually to your new synology-gitlab-ce instance
sudo docker exec -w "/home/git/gitlab/config" -it synology_gitlab bash

# backup data
sudo docker exec -it synology_gitlab bash -c "sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production CRON=1"

# The synology-gitlab psql user differs from the synology-gitlab-ce so we need to 
# modify the database dump. Simply replace the "gitlab_user" with "gitlab". 
# The tools/fix_synology_gitlab_backup does that for you. 
# Syntax: fix_synology_gitlab_backup <file>
# arguments:
#   file    - path to your gitlab_backup.tar file

./tools/fix_synology_gitlab_backup 1647548012_2022_03_17_13.9.3_gitlab_backup.tar

# you will get a 1647548012_2022_03_17_13.9.3_gitlab_backup.tar.new file as output which 
# is ready for restore. Now you can process with the regular restore procedure above, 
# please do not forget to remove the ".new" suffix from file.

# NOTE: if you get following errors, they seems to be common. Despite the errors the 
# restore seems to work, further investigation needed. 
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/266988
#
# Restoring PostgreSQL database gitlabhq_production ... ERROR:  must be owner of extension pg_trgm
# ERROR:  must be owner of extension btree_gist
# ERROR:  must be owner of extension btree_gist
# ERROR:  must be owner of extension pg_trgm
#
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/266988#note_430408658
# Regarding to this post is everything fine as far as the restore doesn't break.
# Quote: "We ignore 'does not exist' and 'must be owner' of errors"
```
