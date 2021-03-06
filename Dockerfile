FROM alpine:3.10
# 3.10 is the last version with Python 3.7 as default. Azure is not compatible with Python 3.8 as of June2020

# Metadata params
ARG BUILD_DATE
ARG ANSIBLE_VERSION
ARG ANSIBLE_LINT_VERSION
ARG DOCKER_TAG
ARG VCS_REF
# Python requirements file for additional modules to install while the deps are loaded
ARG ADDITIONAL_PYTHON_REQS
ARG NODEPS_PYTHON_REQS
# space separated list of Ansible Collections to install during build
ARG ANSIBLE_COLLECTION_PREINSTALL
# This will install the Azure CLI in a separate virtualenv and put it on PATH as it is fairly incompatible with many things
ARG INCLUDE_AZURE_CLI
# This will install the Google Cloud CLI
ARG INCLUDE_GCLOUD_CLI
# This will include Kubectl
ARG INCLUDE_KUBECTL

# Metadata
LABEL maintainer="Chaffelson <chaffelson@gmail.com>" \
      org.label-schema.url="https://github.com/Chaffelson/docker-ansible-alpine/blob/master/README.md" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.version=${DOCKER_TAG} \
      org.label-schema.vcs-url="https://github.com/Chaffelson/docker-ansible-alpine.git" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.description="Ansible on alpine with Cloudera CDP and Cloud Infra automation tooling docker image" \
      org.label-schema.schema-version="1.0"

RUN apk --update --no-cache add \
        ca-certificates \
        git \
        openssh-client \
        openssl \
        python3\
        rsync \
        bash \
        curl \
        groff \
        less \
        tar \
        which \
        mailcap \
        sshpass \
        libxslt-dev \
        libxml2-dev \
        libgcrypt-dev

RUN apk --update add --virtual \
        .build-deps \
        python3-dev \
        libffi-dev \
        openssl-dev \
        musl-dev \
        libc-dev \
        build-base \
 && pip3 install --upgrade \
        pip \
        cffi \
        wheel \
        pipx \
 && pip3 install \
        ansible==${ANSIBLE_VERSION} \
        ansible-lint==${ANSIBLE_LINT_VERSION} \
 && if [ -n "$ADDITIONAL_PYTHON_REQS" ]; then pip3 install -r ${ADDITIONAL_PYTHON_REQS} && pip3 install --no-deps -r ${NODEPS_PYTHON_REQS} ; fi \
 && if [ -n "$INCLUDE_AZURE_CLI" ]; then echo "installing Azure CLI" && curl -LO https://azurecliprod.blob.core.windows.net/install.py && printf "\n/usr/local/bin\nn\n" | python3 install.py ; fi \
 && apk del \
        .build-deps \
 && rm -rf /var/cache/apk/*

RUN if [ -n "$ANSIBLE_COLLECTION_PREINSTALL" ]; then ansible-galaxy collection install ${ANSIBLE_COLLECTION_PREINSTALL}; fi

RUN if [ -n "$INCLUDE_GCLOUD_CLI" ]; then curl -sSL https://sdk.cloud.google.com > /tmp/gcl && bash /tmp/gcl --install-dir=/root --disable-prompts; fi

RUN if [ -n "$INCLUDE_KUBECTL" ]; then \
    echo "installing Kubectl" \
    && curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin \
    && curl -LO https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator \
    && chmod +x ./aws-iam-authenticator \
    && mv ./aws-iam-authenticator /usr/local/bin \
    ; fi

RUN mkdir -p /etc/ansible \
 && echo 'localhost' > /etc/ansible/hosts \
 && echo -e """\
\n\
Host *\n\
    StrictHostKeyChecking no\n\
    UserKnownHostsFile=/dev/null\n\
""" >> /etc/ssh/ssh_config

ENV PATH "$PATH:/root/google-cloud-sdk/bin"

COPY entrypoint /usr/local/bin/

WORKDIR /ansible

ENTRYPOINT ["entrypoint"]

# default command: display Ansible version
CMD [ "ansible-playbook", "--version" ]
