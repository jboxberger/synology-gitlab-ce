#!/usr/bin/env bash

###########################################################
# CHECK DEPENDENCIES!
###########################################################
DEPENDENCIES_OK=1
DEPENDENCIES_LIST="jq"
echo "$DEPENDENCIES_LIST" | tr ' ' '\n' | while read item; do
  if [ -z $(which "$item" 2>/dev/null) ]; then
    echo "$item is not installed."
    DEPENDENCIES_OK=0
  fi
done

if [ $DEPENDENCIES_OK -eq 0 ]; then
  echo "dependencies not met, exiting."
  exit 1
fi

###########################################################
# FUNCTIONS
###########################################################
get_latest_version_number_from_dockerhub() {
  local image_name="$1"

  version="$(curl https://hub.docker.com/v2/repositories/"$image_name"/tags 2>/dev/null | jq -r '.results[].name' | tr "\n" ' ')"

  latest=$(echo "$version" | tr ' ' '\n' | while read item; do
    if [ -n "$item" ] && [ "$(expr "$item" : '^[0-9\.]*-ce\.[0-9]$')" -gt 0 ] ; then
      echo "$item"
      break;
    fi
  done)

  if [ -z "$latest" ]; then
    latest="-1"
  fi
  echo "$latest"
}

help()
{
   # Display Help
   echo "Syntax: build <version> [options]"
   echo "arguments:"
   echo "  version - GitLab CE version e.g. 13.4.3-ce.0"
   echo "options:"
   echo "  --type  - package type (classic|advanced) - default: classic"
   echo "  --dsm   - target DSM version (6|7) - default: 7"
   echo
   echo "Example: build 13.4.3-ce.0 --dsm=7 --type=classic"
   exit 0
}

###########################################################
# DEFAULT VARIABLES
###########################################################
GITLAB_PACKAGE_TYPE="classic"
GITLAB_DSM_VERSION="7"
GITLAB_IMAGE_NAME="gitlab/gitlab-ce"
GITLAB_IMAGE_VERSION="13.4.3-ce.0"

DIRECTORY_SPK="./spk"
DIRECTORY_TMP="./tmp"

###########################################################
# PARAMETER HANDLING
###########################################################
PARAMS=""
for i in "$@"
do
    case ${i} in
      --type=*)
          GITLAB_PACKAGE_TYPE="${i#*=}"
      ;;
      --dsm=*)
          GITLAB_DSM_VERSION="${i#*=}"
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

if [ "$GITLAB_PACKAGE_TYPE" != "classic" ] && [ "$GITLAB_PACKAGE_TYPE" != "advanced" ]; then
  echo "GITLAB_PACKAGE_TYPE $GITLAB_PACKAGE_TYPE is unknown, only classic|advanced allowed."
  exit 1
fi

if [ "$GITLAB_DSM_VERSION" != "6" ] && [ "$GITLAB_DSM_VERSION" != "7" ]; then
  echo "GITLAB_DSM_VERSION $GITLAB_DSM_VERSION is unknown, only 6|7 allowed."
  exit 1
fi

# validate version
if [ -z "$1" ]; then
  GITLAB_VERSION_LATEST="$(get_latest_version_number_from_dockerhub "$GITLAB_IMAGE_NAME")"
  read -ep "gitlab version [default (latest): $GITLAB_VERSION_LATEST]: " GITLAB_IMAGE_VERSION
  if [ -z "$GITLAB_IMAGE_VERSION" ]; then
    GITLAB_IMAGE_VERSION="$GITLAB_VERSION_LATEST"
  fi
else
  GITLAB_IMAGE_VERSION="$1"
fi

if [ "$(expr "$GITLAB_IMAGE_VERSION" : '^[0-9\.]*-ce\.[0-9]$')" -eq 0 ]; then
  echo "invalid version pattern '$GITLAB_IMAGE_VERSION', e.g. 13.4.3-ce.0"
  exit 1
fi

if [ "$GITLAB_DSM_VERSION" == "6" ] && [ "$GITLAB_PACKAGE_TYPE" == "classic" ]; then
  echo "$GITLAB_PACKAGE_TYPE package type is not supported for dsm$GITLAB_DSM_VERSION"
  exit 1
fi

########################################################################################################################
# PACKAGE BUILD
########################################################################################################################
[ ! -d "$DIRECTORY_SPK" ] && mkdir -p "$DIRECTORY_SPK"
[ -d "$DIRECTORY_TMP" ] && rm -rf "$DIRECTORY_TMP"

cp -r ./src "$DIRECTORY_TMP"
if [ "$GITLAB_PACKAGE_TYPE" == "advanced" ]; then
  rm -f "$DIRECTORY_TMP/conf/resource"
elif [ "$GITLAB_PACKAGE_TYPE" == "classic" ]; then
  rm -f "$DIRECTORY_TMP/scripts/gitlab"
  rm -rf "$DIRECTORY_TMP/scripts/templates"
  echo $(jq --arg version "$GITLAB_IMAGE_VERSION" '.docker.services[0].tag = $version' "$DIRECTORY_TMP/conf/resource") > "$DIRECTORY_TMP/conf/resource"
fi

FILES="$DIRECTORY_TMP/WIZARD_UIFILES/*"
for f in $FILES
do
  sed -i -e "/^GITLAB_PACKAGE_TYPE=/s/=.*/=\"$GITLAB_PACKAGE_TYPE\"/" "$f"
  sed -i -e "/^GITLAB_PACKAGE_VERSION=/s/=.*/=\"$GITLAB_IMAGE_VERSION\"/" "$f"
done



# COMPRESS PACKAGE DIR
cd "$DIRECTORY_TMP/package/" && tar -zcf "../package.tgz" * && cd ../../ && rm -rf "$DIRECTORY_TMP/package/"
EXTRACTSIZE=$(du -k --block-size=1KB "$DIRECTORY_TMP/package.tgz" | cut -f1)
GITLAB_IMAGE_VERSION_SHORT=$(echo "$GITLAB_IMAGE_VERSION" | cut -f1 -d-)

# UPDATE INFO FILE
sed -i -e "/^version=/s/=.*/=\"$GITLAB_IMAGE_VERSION_SHORT\"/" "$DIRECTORY_TMP/INFO"
sed -i -e "/^os_min_ver=/s/=.*/=\"$GITLAB_DSM_VERSION.0-00000\"/" "$DIRECTORY_TMP/INFO"
sed -i -e "/^description=/s/=.*/=\"GitLab CE docker container ($GITLAB_PACKAGE_TYPE)\"/" "$DIRECTORY_TMP/INFO"
sed -i -e "/^extractsize=/s/=.*/=\"$EXTRACTSIZE\"/" "$DIRECTORY_TMP/INFO"


# CREATE FILE
OUTPUT_FILE_NAME="synology-gitlab-ce-$GITLAB_IMAGE_VERSION_SHORT-dsm$GITLAB_DSM_VERSION-$GITLAB_PACKAGE_TYPE.spk"
cd "$DIRECTORY_TMP/" && tar --format=gnu -cf "../$DIRECTORY_SPK/$OUTPUT_FILE_NAME" * && cd ../

rm -rf "$DIRECTORY_TMP"
echo "build complete: $OUTPUT_FILE_NAME"
