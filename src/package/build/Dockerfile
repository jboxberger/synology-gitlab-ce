FROM gitlab/gitlab-ce:${GITLAB_IMAGE_VERSION}

COPY ./gitlab_pre_reconfigure_script.sh /assets/
COPY ./gitlab_post_reconfigure_script.sh /assets/

RUN apt update && apt install -y nano \
  && rm -rf /var/lib/apt/lists/*