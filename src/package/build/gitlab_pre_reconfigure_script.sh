#!/usr/bin/env sh

echo "executing: gitlab_pret_reconfigure_script.sh"

GITLAB_CONFIG="/etc/gitlab/gitlab.rb"
if [ ! -z "${EXTERNAL_URL}" ]; then
  sed -i -e "s|^\s*#\s*external_url\s*'.*'.*$|external_url '$EXTERNAL_URL'|g" "$GITLAB_CONFIG"
fi

if [ ! -z "${GITLAB_SHELL_SSH_PORT}" ]; then
    sed -i -e "s|^\s*#\s*gitlab_rails\['gitlab_shell_ssh_port'\]\s*=.*$|gitlab_rails['gitlab_shell_ssh_port'] = $GITLAB_SHELL_SSH_PORT|g" "$GITLAB_CONFIG"
fi
