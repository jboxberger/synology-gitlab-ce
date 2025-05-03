#!/usr/bin/env bash

trap "exit 1" 10
PROC="$$"

###########################################################
# CHECK DEPENDENCIES!
###########################################################
DEPENDENCIES_LIST="jq"
echo "$DEPENDENCIES_LIST" | tr ' ' '\n' | while read item; do
  if [ -z $(which "$item" 2>/dev/null) ]; then
    echo "$item is not installed."
    echo "dependencies not met, exiting."
    kill -10 $PROC
  fi
done

###########################################################
# FUNCTIONS
###########################################################
dockerhub_get_available_image_version_list() {
  local image_name="$1"
  local page_size=20
  local version_list=$(curl https://hub.docker.com/v2/repositories/"$image_name"/tags?page_size=$page_size 2>/dev/null | jq -r '.results[].name' | grep "\-ce")
  local version_list_sorted=""
  readarray -td '' version_list_sorted < <(printf '%s\n' "${version_list[@]}" | sort -ru)
  echo ${version_list_sorted[@]}
}

# Custom `select` implementation that allows *empty* input.
# Pass the choices as individual arguments.
# Output is the chosen item, or "", if the user just pressed ENTER.
# Example:
#    choice=$(show_select_menu_with_default 'one' 'two' 'three')
show_select_menu_with_default() {

  local item i=0 numItems=$#
  local default_value=""

  # Print numbered menu items, based on the arguments passed.
  for item; do         # Short for: for item in "$@"; do
    printf '%s\n' "$((++i))) $item"

    # fist item is default
    if [ -z "$default_value" ]; then
      default_value="$item"
    fi
  done >&2 # Print to stderr, as `select` does.

  PS3="please select version [default $default_value]: "

  # Prompt the user for the index of the desired item.
  while :; do
    printf %s "${PS3-#? }" >&2 # Print the prompt string to stderr, as `select` does.
    read -r index

    # Make sure that the input is either empty or that a valid index was entered.
    if [ -z $index ]; then # empty input
      break
    fi

    if [ $(expr $index : '^[0-9]\{1,2\}$') -eq 0 ] || [ $index -lt 1 ] || [ $index -gt $numItems ]; then
      echo "Invalid selection. Please Select a number 1-$numItems or Enter for default." >&2
      continue
    fi
    break
  done

  # Output the selected item, if any.
  if [ ! -z $index ]; then
    printf %s "${@: index:1}"
  else
    printf %s "$default_value"
  fi

}

help()
{
   # Display Help
   echo "Syntax: build [options]"
   echo "options:"
   echo "  --version - GitLab CE version e.g. 13.4.3-ce.0, "
   echo "              when no version given, a selection list of the latest"
   echo "              available versions is shown"
   echo "  --type    - package type (classic|advanced) - default: classic"
   echo "  --dsm     - target DSM version (6|7) - default: 7"
   echo
   echo "Example: build --version=13.4.3-ce.0 --dsm=7 --type=classic"
   exit 0
}

###########################################################
# DEFAULT VARIABLES
###########################################################
PACKAGE_TYPE="classic"
DSM_VERSION="7"
GITLAB_IMAGE_NAME="gitlab/gitlab-ce"
GITLAB_IMAGE_VERSION=""

DIRECTORY_SPK="./spk"
DIRECTORY_TMP="./tmp"
###########################################################
# PARAMETER HANDLING
###########################################################
PARAMS=""
for i in "$@"
do
    case ${i} in
      --version=*)
          GITLAB_IMAGE_VERSION="${i#*=}"
      ;;
      --type=*)
          PACKAGE_TYPE="${i#*=}"
      ;;
      --dsm=*)
          DSM_VERSION="${i#*=}"
      ;;
      -h|--help)
          help
      ;;
      *) # unknown option
          PARAMS="$PARAMS \"$1\""
      ;;
    esac
    shift
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

if [ "$PACKAGE_TYPE" != "classic" ] && [ "$PACKAGE_TYPE" != "advanced" ]; then
  echo "type $PACKAGE_TYPE is unknown, only classic|advanced allowed!"
  exit 1
fi

# Validate DSM version
if [ "$DSM_VERSION" != "6" ] && [ "$DSM_VERSION" != "7" ]; then
  echo "DSM version $DSM_VERSION is unknown, only 6|7 allowed!"
  exit 1
fi

# validate version
if [ -z "$GITLAB_IMAGE_VERSION" ]; then
  # Print the prompt message and call the custom select function.
  GITLAB_VERSION_LIST=($(dockerhub_get_available_image_version_list "$GITLAB_IMAGE_NAME"))
  GITLAB_IMAGE_VERSION=$(show_select_menu_with_default "${GITLAB_VERSION_LIST[@]:0:9}") # take only first 9 items
fi

if [ "$(expr "$GITLAB_IMAGE_VERSION" : '^[0-9\.]*-ce\.[0-9]$')" -eq 0 ]; then
  echo "invalid version pattern '$GITLAB_IMAGE_VERSION', e.g. 13.4.3-ce.0"
  exit 1
fi

# Classic not supported on DSM6
if [ "$DSM_VERSION" = "6" ] && [ "$PACKAGE_TYPE" = "classic" ]; then
  echo "package type '$PACKAGE_TYPE' is not supported for DSM$DSM_VERSION"
  exit 1
fi

echo -n "building '$GITLAB_IMAGE_VERSION' as '$PACKAGE_TYPE' for DSM$DSM_VERSION... "

########################################################################################################################
# PACKAGE BUILD
########################################################################################################################
START_TIME=$(date +%s.%3N)

[ ! -d "$DIRECTORY_SPK" ] && mkdir -p "$DIRECTORY_SPK"
[ -d "$DIRECTORY_TMP" ] && rm -rf "$DIRECTORY_TMP"

cp -r ./src "$DIRECTORY_TMP"
if [ "$PACKAGE_TYPE" = "advanced" ]; then
  rm -f "$DIRECTORY_TMP/conf/resource"
elif [ "$PACKAGE_TYPE" = "classic" ]; then
  rm -f "$DIRECTORY_TMP/scripts/gitlab"
  rm -rf "$DIRECTORY_TMP/scripts/templates"
  echo $(jq --arg version "$GITLAB_IMAGE_VERSION" '.docker.services[0].tag = $version' "$DIRECTORY_TMP/conf/resource") > "$DIRECTORY_TMP/conf/resource"
  echo -e "ARG GITLAB_IMAGE_VERSION=$GITLAB_IMAGE_VERSION\n\n$(cat "$DIRECTORY_TMP/package/build/Dockerfile")" > "$DIRECTORY_TMP/package/build/Dockerfile"
fi

FILES="$DIRECTORY_TMP/WIZARD_UIFILES/*"
for f in $FILES
do
  sed -i -e "/^PACKAGE_TYPE=/s/=.*/=\"$PACKAGE_TYPE\"/" "$f"
  sed -i -e "/^GITLAB_IMAGE_VERSION=/s/=.*/=\"$GITLAB_IMAGE_VERSION\"/" "$f"
done

# COMPRESS PACKAGE DIR
cd "$DIRECTORY_TMP/package/" && tar -zcf "../package.tgz" * && cd ../../ && rm -rf "$DIRECTORY_TMP/package/"
EXTRACTSIZE=$(du -k --block-size=1KB "$DIRECTORY_TMP/package.tgz" | cut -f1)
GITLAB_IMAGE_VERSION_SHORT=$(echo "$GITLAB_IMAGE_VERSION" | cut -f1 -d-)

# UPDATE INFO FILE
sed -i -e "/^version=/s/=.*/=\"$GITLAB_IMAGE_VERSION_SHORT\"/" "$DIRECTORY_TMP/INFO"
sed -i -e "/^os_min_ver=/s/=.*/=\"$DSM_VERSION.0-00000\"/" "$DIRECTORY_TMP/INFO"
sed -i -e "/^description=/s/=.*/=\"GitLab CE docker container ($PACKAGE_TYPE)\"/" "$DIRECTORY_TMP/INFO"
sed -i -e "/^extractsize=/s/=.*/=\"$EXTRACTSIZE\"/" "$DIRECTORY_TMP/INFO"

# CREATE FILE
OUTPUT_FILE_NAME="synology-gitlab-ce-$GITLAB_IMAGE_VERSION_SHORT-dsm$DSM_VERSION-$PACKAGE_TYPE.spk"
cd "$DIRECTORY_TMP/" && tar --format=gnu -cf "../$DIRECTORY_SPK/$OUTPUT_FILE_NAME" * && cd ../

rm -rf "$DIRECTORY_TMP"

RUN_TIME=$( echo "scale=3; $(date +%s.%3N) - $START_TIME" | bc )
echo "complete in "$RUN_TIME"s"
echo "file: $DIRECTORY_SPK/$OUTPUT_FILE_NAME"
