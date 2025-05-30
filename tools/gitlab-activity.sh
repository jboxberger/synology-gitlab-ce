#!/bin/bash

# ls --sort=time | grep production_json.log | head -2

GITLAB_CONTAINER_NAME="synology-gitlab-ce"
docker_bin=$(which docker)

tmp_file="/tmp/$GITLAB_CONTAINER_NAME"
last_log="/tmp/$GITLAB_CONTAINER_NAME.log"
prev_log="/tmp/$GITLAB_CONTAINER_NAME.log.1.gz"

if ! [ -z "$docker_bin" ]; then

  # prepare file
  docker cp $GITLAB_CONTAINER_NAME:/var/log/gitlab/gitlab-rails/production_json.log.1.gz "$prev_log"
  docker cp $GITLAB_CONTAINER_NAME:/var/log/gitlab/gitlab-rails/production_json.log "$last_log"

  zcat "$prev_log" > "$tmp_file"
  cat "$last_log" >> "$tmp_file"

  last_activity=$(cat "$tmp_file" | jq '. | select(.username!=null) .time' | tail -1 | tr -d '"')

  if [ -z "$last_activity" ]; then
    # if no user web interaction at all, use last logfile date as reference fpr last activity
    echo "using logfile date fallback"
    file_timestamp=$(stat -c '%Y' "$prev_log" | tr -d '\r')
    last_activity=$(date '+%F %T' -d "@$file_timestamp")
  fi

  echo "last: $last_activity"

  if ! [ -z "$last_activity" ]; then
    last_activity_unix=$(date -d "$last_activity" +%s)
    current_unix=$(date +%s)

    diffSeconds="$(($current_unix-$last_activity_unix))"

    echo $last_activity_unix $current_unix $diffSeconds

    if [ $diffSeconds -gt 3600 ]; then
      echo "inactivity treshold reached, shutting down"
      #synowebapi --exec api=SYNO.Docker.Container version=1 method=stop name="$GITLAB_CONTAINER_NAME" 2> /dev/null
      synowebapi --exec api=SYNO.Core.Package.Control id="$GITLAB_CONTAINER_NAME" method=stop version=1 2> /dev/null
      synowebapi --exec api=SYNO.Core.Package.Control id=Docker method=stop version=1 2> /dev/null
    else
      echo "do nothing"
    fi
  else
    echo "nothing to do, $GITLAB_CONTAINER_NAME not runnung"
  fi

  rm -f "$tmp_file" "/tmp/$GITLAB_CONTAINER_NAME.log.1.gz" "/tmp/$GITLAB_CONTAINER_NAME.log"

fi

exit 1