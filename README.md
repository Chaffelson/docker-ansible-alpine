# Docker-Ansible base image

[![Layers](https://images.microbadger.com/badges/image/chaffelson/cdp-ansible.svg)](https://microbadger.com/images/chaffelson/cdp-ansible) [![GitHub issues](https://img.shields.io/github/issues/Chaffelson/docker-ansible-alpine.svg)](https://github.com/Chaffelson/docker-ansible-alpine) [![Github Automated build](https://img.shields.io/github/workflow/status/chaffelson/docker-ansible-alpine/Docker%20Image%20CI?maxAge=2592000)](https://github.com/Chaffelson/docker-ansible-alpine/actions?query=workflow%3A%22Docker+Image+CI%22) [![Docker Pulls](https://img.shields.io/docker/pulls/chaffelson/cdp-ansible.svg)](https://hub.docker.com/r/chaffelson/cdp-ansible/)

## Usage

### Environnement variable

| Variable             | Default Value    | Usage                                       |
|----------------------|------------------|---------------------------------------------|
| PIP_REQUIREMENTS     | requirements.txt | install python library requirements         |
| ANSIBLE_REQUIREMENTS | requirements.yml | install ansible galaxy roles requirements   |
| ANSIBLE_COLLECTION_REQUIREMENTS | collection_requirements.yml | install ansible galaxy collection requirements   |
| DEPLOY_KEY           |                  | pass an SSH private key to use in container |

### Run Playbook

```
docker run -it --rm \
  -v ${PWD}:/ansible \
  pad92/ansible-alpine:latest \
  ansible-playbook -i inventory playbook.yml
```

### Run with mounted Cloud Service Profile
docker run -it --rm \
  -v ${PWD}:/ansible \
  --mount "type=bind,source=${HOME}/.aws,target=/root/.aws" \
  --mount "type=bind,source=${HOME}/.cdp,target=/root/.cdp" \
  --mount "type=bind,source=${HOME}/.azure,target=/root/.azure" \
  chaffelson/cdp-ansible:latest \
  playbook.yml

### Generate Base Role structure

```
docker run -it --rm \
  -v ${PWD}:/ansible \
  pad92/ansible-alpine:latest \
  ansible-galaxy init role-name
```

### Lint Role

```
docker run -it --rm pad92/ansible-alpine:latest \
  -v ${PWD}:/ansible ansible-playbook tests/playbook.yml --syntax-check
```
### Run with forwarding ssh agent

```
docker run -it --rm \
  -v $(readlink -f $SSH_AUTH_SOCK):/ssh-agent \
  -v ${PWD}:/ansible \
  -e SSH_AUTH_SOCK=/ssh-agent \
  pad92/ansible-alpine:latest \
  sh
```

### Build locally with additional options
```
docker build \
--build-arg ANSIBLE_VERSION=2.9.10 \
--build-arg ANSIBLE_LINT_VERSION=4.2.0 \
--build-arg ADDITIONAL_PYTHON_REQS='https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements-azure.txt' \
--build-arg ANSIBLE_COLLECTION_PREINSTALL='azure.azcollection community.aws amazon.aws' \
--build-arg INCLUDE_AZURE_CLI=true \
-t myimg:latest .
```