#!/bin/sh
PACKAGE_TYPE=""
GITLAB_IMAGE_VERSION=""

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


install_title="Install GitLab CE"

recommended_memory="Recommended memory size"
mem_total_check_fail="A minimum of {1} RAM is required to install or update <a href=\"{2}\" target=\"_blank\">the latest version of GitLab</a>. Please expand the memory of your Synology NAS and try again."
mem_total_check_warning="A minimum of {1} RAM is required to install or update GitLab. Insufficient memory may cause unexpected errors when you run GitLab, so you are recommended to expand the memory of your Synology NAS. <a href=\"{2}\" target=\"_blank\">Learn more</a>."
additional_memory_required="Insufficient memory"

hostname_label="Domain name"
hostname_desc="The hostname of your synology server, also used in emails ("localhost" or "127.0.0.1" will not work)"

ssh_port_label="SSH port number"
ssh_port_desc="Please enter the SSH port number."

http_port_label="HTTP port number"
http_port_desc="Please enter the HTTP port number."

https_port_label="HTTPS port number"
https_port_desc="Please enter the HTTPS port number."

PageInstallSetting()
{
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
      "defaultValue": "$(hostname)",
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
      "defaultValue": "30022",
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
			"defaultValue": "30080",
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
			"defaultValue": "30443",
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


PageAdvancedSettings()
{
	domain_value_warning="<br><b>$domain_value_warning</b>"

  local page=$(cat << EOF
{
	"step_title": "$install_title",
	"invalid_next_disabled_v2": true,
	"items": [{
    "desc": "
After the installation is complete, you need to <a href=\"https://kb.synology.com/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet\" target=\"_blank\">login on your synology over ssh</a> and execute this command with root privileges. Please modify the arguments to fit your needs.<br>
<br>
You can copy this command with CTRL+C.<br>
<br>
<pre style=\"user-select: text; cursor: initial;\">
cd /var/packages/synology-gitlab-ce/scripts && &bsol;
sudo sh gitlab install synology-gitlab-ce &bsol;
--version=$GITLAB_IMAGE_VERSION &bsol;
--share=synology-gitlab-ce &bsol;
--port-ssh=30022 &bsol;
--port-http=30080 &bsol;
--port-https=30443
</pre>
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
	local install_setting_page=""

	DEFAULT_RESTORE=false

	# 2GB and 4GB check
	if memory_lt 1800; then
		memory_check_page="$(PageMemoryCheck false)"
	elif memory_lt 3800; then
		memory_check_page="$(PageMemoryCheck true)"
	fi



	install_page=$(page_append "$install_page" "$memory_check_page")


	if [ "$PACKAGE_TYPE" = "advanced" ]; then
    install_summary_page="$(PageAdvancedSettings)"
    install_page=$(page_append "$install_page" "$install_summary_page")
  else
    install_setting_page="$(PageInstallSetting)"
    install_page=$(page_append "$install_page" "$install_setting_page")
	fi

	echo "[$install_page]" > "${SYNOPKG_TEMP_LOGFILE}"
	return 0
}

main "$@"
