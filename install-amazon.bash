#!/bin/bash

set -x

# for node 
curl -sL https://rpm.nodesource.com/setup_10.x | sudo -E bash -

# for xmlstarlet
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

sudo yum update -y

sleep 10

# setting up docker
sudo yum install -y docker
sudo usermod -aG docker ec2-user


# just to be safe removing previously avaialable java if present
sudo yum remove -y java

sudo yum install -y python2-pip jq unzip vim tree biosdevname nc mariadb bind-utils at screen tmux xmlstarlet git java-1.8.0-openjdk nc gcc-c++ make nodejs

sudo -H pip install awscli bcrypt
sudo -H pip install --upgrade awscli 
sudo -H pip install --upgrade aws-ec2-assign-elastic-ip

sudo npm install -g @angular/cli

sudo systemctl enable docker
sudo systemctl enable atd

sudo yum clean all
sudo rm -rf /var/cache/yum/
exit 0

