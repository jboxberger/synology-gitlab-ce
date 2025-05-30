#!/bin/sh
GITLAB_IMAGE_VERSION=""
PKG_NAME="synology-gitlab-ce"
install_title="Install GitLab CE"

HOSTNAME=$(hostname)
GITLAB_SHELL_SSH_PORT="30022"
GITLAB_HTTP_PORT="30080"

memory_lt()
{
	mem_total=$(/bin/free -m | grep Mem |awk '{print $2}')
	if [ "$mem_total" -lt "$1" ]; then
		return 0
	else
		return 1
	fi
}

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

quote_json() {
	sed -e 's|\\|\\\\|g' -e 's|\"|\\\"|g'
}

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

PageInstallSetting() {
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

PageAdvancedSettings() {
  local page=$(cat << EOF
{
	"step_title": "$install_title",
	"invalid_next_disabled_v2": true,
	"activeate": "{
	  const summary = document.getElementById('pkgwizard-install-summary');
	  if(summary) {
	  	  const hostname = document.querySelector('[name=\"pkgwizard_hostname\"]').value;
    	  const ssh_port = document.querySelector('[name=\"pkgwizard_ssh_port\"]').value;
    	  const http_port = document.querySelector('[name=\"pkgwizard_http_port\"]').value;

    	  summary.innerHTML =
    	    'cd /var/packages/$PKG_NAME/scripts && &bsol;<br>' +
    	    'sudo sh gitlab install $PKG_NAME &bsol;<br>' +
    	    '--version=$GITLAB_IMAGE_VERSION &bsol;<br>' +
    	    '--share=$PKG_NAME &bsol;<br>' +
    	    '--hostname='+hostname+' &bsol;<br>' +
    	    '--port-ssh='+ssh_port+' &bsol;<br>' +
    	    '--port-http='+http_port;
	  }
	}",
	"items": [{
    "desc": "
After the installation is complete, you need to <a href=\"https://kb.synology.com/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet\" target=\"_blank\">login on your synology over ssh</a> and execute this command with root privileges. Please modify the arguments to fit your needs.<br>
<br>
<div id=\"pkgwizard-install-summary\" style=\"user-select: text; cursor: initial; font-family: monospace;\">
  <br><br><br><br><br><br><br><br><br><br> <!-- reserve some space -->
</div><br>
(to copy this command just mark it and press CTRL+C)<br>
"
  }]
}
EOF
)
	echo "$page"
}

PageMemoryCheck()
{
	min_mem="4GB"
	gitlab_mem_requirement_link=https://gitlab.com/gitlab-org/gitlab-ce/blob/v13.6.2/doc/install/requirements.md#memory
	mem_total_check_fail=${mem_total_check_fail//\{1\}/"$min_mem"}
	mem_total_check_fail=${mem_total_check_fail//\{2\}/"$gitlab_mem_requirement_link"}
	mem_total_check_warning=${mem_total_check_warning//\{1\}/$min_mem}
	mem_total_check_warning=${mem_total_check_warning//\{2\}/"$gitlab_mem_requirement_link"}
	is_soft_check=$1
	if $is_soft_check; then
		memtitle="$recommended_memory"
		desc="$(echo $mem_total_check_warning | quote_json)"
	else
		memtitle="$additional_memory_required"
		desc="$(echo $mem_total_check_fail | quote_json)"
	fi
cat << EOF
{
	"invalid_next_disabled_v2": true,
	"step_title": "$memtitle",
	"items": [{
		"type": "textfield",
		"desc": "$desc",
		"subitems": [{
			"hidden": true,
			"validator": {
				"fn": "{return $is_soft_check;}"
			} 
		}]
	}]
}
EOF
}

main()
{
	local install_page=""
	local memory_check_page=""

	# 2GB and 4GB check
	if memory_lt 1800; then
		memory_check_page="$(PageMemoryCheck false)"
	elif memory_lt 3800; then
		memory_check_page="$(PageMemoryCheck true)"
	fi

	install_page=$(page_append "$install_page" "$memory_check_page")

  install_title="${install_title} Advanced";
  install_page=$(page_append "$install_page" "$(PageInstallSetting)")
  install_page=$(page_append "$install_page" "$(PageAdvancedSettings)")

	echo "[$install_page]" > "${SYNOPKG_TEMP_LOGFILE}"
	return 0
}

main "$@"
