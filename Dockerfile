FROM alpine:3.11

# Metadata params
ARG BUILD_DATE
ARG ANSIBLE_VERSION
ARG ANSIBLE_LINT_VERSION
ARG VCS_REF
ARG ADDITIONAL_PYTHON_REQS
ARG ANSIBLE_COLLECTION_PREINSTALL

# Metadata
LABEL maintainer="Pascal A. <pascalito@gmail.com>" \
      org.label-schema.url="https://github.com/pad92/docker-ansible-alpine/blob/master/README.md" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.version=${ANSIBLE_VERSION} \
      org.label-schema.vcs-url="https://github.com/pad92/docker-ansible-alpine.git" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.description="Ansible on alpine docker image" \
      org.label-schema.schema-version="1.0"

RUN apk --update --no-cache add \
        ca-certificates \
        git \
        openssh-client \
        openssl \
        python3\
        rsync \
        sshpass

RUN apk --update add --virtual \
        .build-deps \
        python3-dev \
        libffi-dev \
        openssl-dev \
        build-base \
 && pip3 install --upgrade \
        pip \
        cffi \
 && pip3 install \
        ansible==${ANSIBLE_VERSION} \
        ansible-lint==${ANSIBLE_LINT_VERSION} \
 && if [ -n "$ADDITIONAL_PYTHON_REQS" ]; then pip3 install -r ${ADDITIONAL_PYTHON_REQS} ; fi \
 && apk del \
        .build-deps \
 && rm -rf /var/cache/apk/*

RUN if [ -n "$ANSIBLE_COLLECTION_PREINSTALL" ]; then ansible-galaxy collection install ${ANSIBLE_COLLECTION_PREINSTALL} ; fi

RUN mkdir -p /etc/ansible \
 && echo 'localhost' > /etc/ansible/hosts \
 && echo -e """\
\n\
Host *\n\
    StrictHostKeyChecking no\n\
    UserKnownHostsFile=/dev/null\n\
""" >> /etc/ssh/ssh_config

COPY entrypoint /usr/local/bin/

WORKDIR /ansible

ENTRYPOINT ["entrypoint"]

# default command: display Ansible version
CMD [ "ansible-playbook", "--version" ]
