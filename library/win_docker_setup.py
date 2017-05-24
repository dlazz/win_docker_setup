#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2017, Daniele Lazzari <lazzari@mailup.com>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# this is a windows documentation stub.  actual code lives in the .ps1
# file of the same name

ANSIBLE_METADATA = {'metadata_version': '1.0',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = r'''
---
module: win_docker_setup
version_added: "2.4"
short_description: Add, remove or update docker for windows.
description:
    - Add, remove or update docker for window. This script automate the setup
      of a stable version of Docker and installs the latest stable if any
      version is provided.
      'Containers' windows feature is installed if not already present.
options:
  state:
    description:
      - If present, it installs Docker.
        If absent, it removes Docker.
        If update, it updates Docker to the latest available version.
    default: present
    choices:
      - present
      - absent
      - update
  version:
    desrcription:
      - Docker desired version.
        Docker available versions can be found at
        https://docs.docker.com/docker-for-windows/release-notes/
        or in a json file downloadable at 
        https://go.microsoft.com/fwlink/?LinkID=825636&clcid=0x409
        Version can be set in short mode (ie 17.03.0, 1.13-cs) or extended
        (ie. 17.03.0-ee, 1.13.1-cs1).
notes:
  - Runs only in Windows 2016.
    KB3176936 has to be previously installed. Ensure your windows server has
    the latest available updates.
author: Daniele Lazzari
'''

EXAMPLES = r'''
---

- name: install Docker
  win_docker_setup:
    state: present

- name: install a specific version of Docker
  win_docker_setup:
    state: present
    version: 1.13-cs

- name: remove Docker
  win_docker_setup:
    state: absent

- name: update Docker
  win_docker_setup:
    state: update
'''
RETURN = r'''
output:
  description: message describing the task
  returned: always
  type: string
  sample: "Docker installed."
restart_needed:
  description: indicates whether or not the machine requires a resart
  returned: always
  type: bool
  sample: False
container_feature:
  description: indicates if the Containers windows feature is installed by
               the module
    returned: when container feature is installed
    type: string
    sample: installed
docker_version:
  description: installed docker version
  returned: when docker is installed or updated
  type: string
  sample: "17.03.1-ee"
'''
