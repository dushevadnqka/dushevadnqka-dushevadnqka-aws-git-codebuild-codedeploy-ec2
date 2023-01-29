#!/bin/bash

# install the AWS CodeDeploy agent
yum update -y
yum install -y ruby
yum install wget
cd /home/ec2-user
wget https://aws-codedeploy-${region}.s3.${region}.amazonaws.com/latest/install
chmod +x ./install
./install auto

# start the CodeDeploy agent
service codedeploy-agent start

# Install the necessary packages
yum update -y
yum install -y docker

# Start the Docker service
service docker start

# Add the ec2-user to the docker group
usermod -a -G docker ec2-user

# Install jq
yum update -y
yum install jq -y
