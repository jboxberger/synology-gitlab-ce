#!/bin/sh
GITLAB_IMAGE_VERSION=""
PKG_NAME="synology-gitlab-ce"
install_title="Update GitLab CE"

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



PageInstallSummary() {
	domain_value_warning="<br><b>$domain_value_warning</b>"

  local page=$(cat << EOF
{
	"step_title": "$install_title",
	"invalid_next_disabled_v2": true,
	"activeate": "",
	"items": [{
    "key": "summary",
    "desc": "This update just updates your GitLab toolkit files. Your GitLab environment stays untouched.
    You have to run the following command to update your GitLab environment after this update wizzard is completed.<br>
    <br>
    <div style=\"user-select: text; cursor: initial; font-family: monospace;\">
    cd /var/packages/$PKG_NAME/scripts && &bsol;<br>
    sudo sh gitlab update $PKG_NAME --version=$GITLAB_IMAGE_VERSION
    </div>
    <br>
    (to copy this command just mark it and press CTRL+C)<br>
    "
  }]
}
EOF
)
	echo "$page"
}


main()
{
	local upgrade_page=""

  install_title="${install_title}";
  upgrade_page=$(page_append "$upgrade_page" "$(PageInstallSummary)")

	echo "[$upgrade_page]" > "${SYNOPKG_TEMP_LOGFILE}"
	return 0
}

main "$@"
