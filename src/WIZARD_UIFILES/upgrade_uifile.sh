#!/bin/sh
PACKAGE_TYPE=""
GITLAB_IMAGE_VERSION=""

PKG_NAME="synology-gitlab-ce"
PKG_PATH="/var/packages/$PKG_NAME"
ETC_PATH="$PKG_PATH/etc"

HOSTNAME=$(hostname)
GITLAB_SHELL_SSH_PORT="30022"
GITLAB_HTTP_PORT="30080"
GITLAB_HTTPS_PORT="30443"

if [ -f "$ETC_PATH/config" ]; then
  source "$ETC_PATH/config"
fi

page_append()
{
	if [ -z "$1" ]; then
		echo "$2"
	elif [ -z "$2" ]; then
		echo "$1"
	else
		echo "$1,$2"
	fi
}

install_title="Update GitLab CE"

recommended_memory="Recommended memory size"
mem_total_check_fail="A minimum of {1} RAM is required to install or update <a href=\"{2}\" target=\"_blank\">the latest version of GitLab</a>. Please expand the memory of your Synology NAS and try again."
mem_total_check_warning="A minimum of {1} RAM is required to install or update GitLab. Insufficient memory may cause unexpected errors when you run GitLab, so you are recommended to expand the memory of your Synology NAS. <a href=\"{2}\" target=\"_blank\">Learn more</a>."
additional_memory_required="Insufficient memory"

hostname_label="Hostname/Domain"
hostname_desc="The hostname of your synology server, also used in emails ("localhost" or "127.0.0.1" will not work)"

ssh_port_label="SSH port number"
ssh_port_desc="Please enter the SSH port number."

http_port_label="HTTP port number"
http_port_desc="Please enter the HTTP port number."

https_port_label="HTTPS port number"
https_port_desc="Please enter the HTTPS port number."

PageInstallSetting() {
	domain_value_warning="<br><b>$domain_value_warning</b>"

  local page=$(cat << EOF
{
	"step_title": "$install_title",
	"invalid_next_disabled_v2": true,
	"items": [{
    "type": "textfield",
    "desc": "$hostname_desc",
    "subitems": [{
      "key": "pkgwizard_hostname",
      "desc": "$hostname_label",
      "defaultValue": "$HOSTNAME",
      "disabled": true,
      "validator": {
        "allowBlank": false
      }
    }]
  },{
    "type": "textfield",
    "desc": "$ssh_port_desc",
    "subitems": [{
      "key": "pkgwizard_ssh_port",
      "desc": "$ssh_port_label",
      "defaultValue": "$GITLAB_SHELL_SSH_PORT",
      "disabled": true,
      "validator": {
        "allowBlank": false,
        "regex": {
          "expr": "/^[1-9]\\\\d{0,4}$/"
        }
      }
    }]
  },{
		"type": "textfield",
		"desc": "$http_port_desc",
		"subitems": [{
			"key": "pkgwizard_http_port",
			"desc": "$http_port_label",
			"defaultValue": "$GITLAB_HTTP_PORT",
			"disabled": true,
			"validator": {
				"allowBlank": false,
				"regex": {
					"expr": "/^[1-9]\\\\d{0,4}$/"
				}
			}
		}]
	},{
		"type": "textfield",
		"desc": "$https_port_desc",
		"subitems": [{
			"key": "pkgwizard_https_port",
			"desc": "$https_port_label",
			"defaultValue": "$GITLAB_HTTPS_PORT",
			"disabled": true,
			"validator": {
				"allowBlank": false,
				"regex": {
					"expr": "/^[1-9]\\\\d{0,4}$/"
				}
			}
		}]
	}]
}
EOF
)
	echo "$page"
}

PageInstallSummary() {
	domain_value_warning="<br><b>$domain_value_warning</b>"

  local page=$(cat << EOF
{
	"step_title": "$install_title",
	"invalid_next_disabled_v2": true,
	"activeate": "",
	"items": [{
    "key": "summary",
    "desc": "If you have not done your Backup yet, please cancel the update and do it NOW!
    <a href=\"https://github.com/jboxberger/synology-gitlab-ce?tab=readme-ov-file#backup\" target=\"_blank\">Here is tutorial how to do it</a>.
    If you have modified your GitLab ENVIRONMENT variables since installation, please backup them as well, they will be reset to the previous values
    since Synology has locked everything up, there is no privilege as a 3rd-party App to modify them automatically."
  },{
    "type": "multiselect",
    "desc": "Confirmation Required",
    "subitems": [{
      "key": "confirm",
      "desc": "I confirm that I created a backup and understand that GitLab migrations, which are running by GitLab after
      update, may brick my GitLab instance. Especially when I am not following the
      <a href=\"https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/?edition=ce\" target=\"_blank\">GitLab upgrade path</a>
      and skip required versions. ",
      "defaultValue": false,
      "validator": {
        "fn": "{var v=arguments[0]; if (!v) return false; return true;}"
      }
   }]
  },{
    "key": "summary",
    "desc": "After the installation is complete, your GitLab Docker container needs couple of minutes to do the migrations and boot. Please be patient!"
  }]
}
EOF
)
	echo "$page"
}


main()
{
	local upgrade_page=""

	if [ "$PACKAGE_TYPE" = "classic" ]; then
    install_title="${install_title} Classic";
    upgrade_page=$(page_append "$upgrade_page" "$(PageInstallSetting)")
    upgrade_page=$(page_append "$upgrade_page" "$(PageInstallSummary)")
	fi

	echo "[$upgrade_page]" > "${SYNOPKG_TEMP_LOGFILE}"
	return 0
}

main "$@"
