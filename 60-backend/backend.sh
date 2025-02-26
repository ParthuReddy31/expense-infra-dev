#!/bin/bash
dnf install ansible -y

# ansible-playbook -i inventory mysql.yml
# this is for push mechanism

#  for pull 
ansible-pull  -i localhost, -U https://github.com/ParthuReddy31/ansible-rolls-project-tf.git main.yml -e COMPONENT=backend -e ENVIRONMENT=$1


# https://github.com/ParthuReddy31/ansible-rolls-project-tf.git