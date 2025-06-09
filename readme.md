## synology-gitlab-ce

This is a docker based GitLab CE toolkit package for Synology NAS server using the original [gitlab/gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce/) image from hub.docker.com. 
The goal of this project is to lower the entry barrier for new GitLab users and give experienced users a little comfort in maintaining their GitLab installation.

### Features
- easy GitLab self update (no wait for maintainer)
- auto backup on update
- multiple parallel GitLab instances possible (debugging, migration tests)
- GitLab debug helper when migrations failed
- Self-Signed SSL Cert helper
- Synology GitLab shutdown on inactivity helper
- DSM Integration

Everything this package does, can be also done manually over SSH and the Synology Docker NAS Application.

Please note that I can not give you support for GitLab itself, this project covers only the Synology installation/update routines.
If you need GitLab Support you might get it here [https://forum.gitlab.com](https://forum.gitlab.com). 

### Download SPK:
You can download the SPK file in the [Releases](https://github.com/jboxberger/synology-gitlab-ce/releases) section.

### Hardware Requirements:
- 1 CPU core ( 2 cores is recommended )
- 2 GB RAM ( 4GB RAM is recommended )
- DSM 6.0 and DSM 7.0 compatible

This package bypass the root privileges limitation of the DSM by running the setup over ssh. The final container 
runs exactly with the same privileges and setup as the classic non-root approach, but you need to execute the installer 
as root to get the setup done. This is a more flexible variant because this way you get the full access to the container
settings and an update simply exports you current container configuration and imports it again with a modified GitLab image version.
This way all your configuration remains the same, and you can downgrade and upgrade as you like. As far as GitLab supports the downgrade
with your specific dataset. The ssh installer/updater gives you also the ability to run multiple gitlab container instances with 
different container/versions and different data shares. You can test your upgrades and migrations without any risk and downtime.

![Advanced installer DSM image](images/gitlab-ce-advanced-1.png "Advanced installer DSM")

**Install Instance**
![Install Instance image](images/gitlab-ce-advanced-3.png "Install Instanc")

**Update Instance**
![Update Instance image](images/gitlab-ce-advanced-4.png "Update Instance")

**Multiple Instances**
![Multiple Instances image](images/gitlab-ce-advanced-2.png "Multiple instances")

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
#   --dsm     - target DSM version (6.0-6.2|7.0-7.2) - default: 7.1"

./build.sh --version=13.4.3-ce.0 --dsm=7.1
```

### GitLab Upgrade Path
It's highly recommended to follow the upgrade path especially if you update to another major release. You can check the
recommended upgrade path [here](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/?edition=ce). Please take your 
time and make backups in between updates. Be Patient during update, this may take up to 30 minutes. You can see the 
progress in the Docker app in the Details->Protocol tab. Once no new lines occur in the protocol and the container 
consume over 4GB RAM, the update should be complete.   

see: https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/?edition=ce


### Install GitLab Instance
Download the desired SPK Version and install it. If you have a previous version of Gitlab installed, just install the 
new SPK over the existing Gitlab installation. This will not update your gitlab, just the tooling scripts. After you 
installed the SPK you need to run this command:

```bash
# Location: /var/packages/synology-gitlab-ce/scripts
# Syntax: gitlab install <container> [options]
# arguments:
#   container    - container name
# options:
#   --version    - GitLab CE version e.g. 13.4.3-ce.0
#   --share      - destination folder which will contain shared gitlab files
#   --hostname   - the URL/Hostname of your synology
#   --port-ssh   - ssh host port
#   --port-http  - http host port

cd /var/packages/synology-gitlab-ce/scripts && \
sudo sh gitlab install synology-gitlab-ce \
--version=13.4.3-ce.0 \
--share=synology-gitlab-ce \
--port-ssh=30022 \
--port-http=30080
```

### Update GitLab Instance
```bash
# Location: /var/packages/synology-gitlab-ce/scripts
# Syntax: gitlab update <container> [options]
# arguments:
#   container    - container name
# options:
#   --version    - GitLab CE version e.g. 13.4.3-ce.0

cd /var/packages/synology-gitlab-ce/scripts && \
sudo sh gitlab update synology-gitlab-ce --version=13.4.5-ce.0
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
#   --port       - https port - default: 30443

cd /var/packages/synology-gitlab-ce/scripts && \
sudo sh gitlab-self-signed-cert install "<gitlab-container-name>" \
  --hostname=xpenology --port=30443
```

### Shortcut helper
If your GitLab shortcut in your DSM got broken or points to the wrong container (port) you can fix it with this helper anytime.
```bash
# Location: /var/packages/synology-gitlab-ce/scripts
# Syntax: gitlab-link list|add|set|remove name [options]
# options:
#   --title      - add a title which is shown in DSM
#   --protocol   - protocol http|https - default: http
#   --port       - port - default: 30080

cd /var/packages/synology-gitlab-ce/scripts && \
sudo sh gitlab-link add "<gitlab-container-name>" --title="My Gitlab" --protocol=https --port=30443
```

### Inactivity shutdown
This script helps you to shutdown your GitLab instance (and docker service) on inactivity.
```bash
# Location: /var/packages/synology-gitlab-ce/scripts
# Syntax: gitlab-inactivity-shutdown <container> [options]
# arguments:
#   container    - container name
# options:
#   --seconds         - inactivity seconds - default: 3600
#   --shutdown-docker - also shutdown the docker/container service

cd /var/packages/synology-gitlab-ce/scripts && \
sudo sh gitlab-inactivity-shutdown "<gitlab-container-name>" --seconds=3600 --shutdown-docker
```

### Docker Container Bootlooping
When you data gets corrupted during migrations, the container starts boot-looping, and you can't enter it to fix the issue.
For that issue we start a new container without the default gitlab-ce start script and boot gitlab manually. When you run 
into the error, the container will still run, and you can fix your data issue. Before running the container from cli, please
stop the boot-looping container.
```bash
# 1) run container from command line
cd /var/packages/synology-gitlab-ce/scripts && \
sudo ./gitlab-debug "<gitlab-container-name>"

# 2) execute the GitLab start script
# docker container before "17.10.0"
./assets/wrapper

# docker container from "17.10.0"
./assets/init-container
```

### Create GitLab Runner
Migration can only be done within the same GitLab version. Its is basically a backup from synology-gitlab package and restore to
the synology-gitlab-ce package.
```bash
# 1) ssh into your synology and run 
sudo ln -s /var/run/docker.sock /volume1/docker/docker.sock
# 2) download tools/gitlab-runner.json and upload to your synology on any folder over DSM (file should be accessible over DSM)
# 3) Go to your Docker App Settings->Import and select the gitlab-runner.json and start the import
# 4) bash into your gitlab-runner container
docker exec -it <gitlab-runner-name> bash
# 5) execute the registration command you get from your DSM http://<external_url>:<external_port>/admin/runners/new
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
