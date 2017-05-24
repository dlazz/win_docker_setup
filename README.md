# win_docker_setup

**win_docker_setup** is an *Ansible* module to install docker on windows 2016

----------

## Usage
Add *library* folder to your role/playbook,

####Usage examples:
```yml
---
# Install the Docker latest version
- name: install docker
  win_docker_setup:

# Install a Docker specific version
- name: install docker 1.13-cs
  win_docker_setup:
    state: present
    version: 1.13-cs

# Remove Docker
- name: remove docker
  win_docker_setup:
    state: absent

# Update docker to the latest available version
- name: update docker
  win_docker_setup:
    state: update
  
``` 

###Note:
>This module uses Docker manual setup as described here: https://docs.docker.com/docker-ee-for-windows/install/

>KB3176936 has to be previously installed. Ensure your windows server has the latest available updates.

>The Containers windows feature is automatically installed if not already present.
