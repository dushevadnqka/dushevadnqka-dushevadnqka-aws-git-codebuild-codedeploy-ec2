#!/bin/bash

if [ ! -x "$(command -v docker)" ] && [ ! -x "$(command --version jq)" ]; then
    echo "Install docker & jq"
    
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
fi

# create a folder where to store the logs (TODO: move to the /var/log instead)
mkdir -p auto_remediate_log

LOG_LOCATION=auto_remediate_log/ec2-app-remediate.log

touch $LOG_LOCATION

# Initialize some logger
function logger () {
    exec > >(tee -i $LOG_LOCATION)
    exec 2>&1
    now=$(date +'%m/%d/%Y %H:%M')
    echo "$1: [$now] $2"
}

# 0. Determine while docker container named TechChallenge is running (TODO: the container name as var)
if [ "$(docker ps --format '{{.Names}}')" == "TechChallengeApp" ]; then
    logger "INFO" "The container is still running. No action required."
    exit 0;
fi

# 1. Determine while EC2 is running along with a pipeline and it waits for deployment
CHECK_PIPELINE_RUNNING=$(aws codepipeline get-pipeline-state --name karakonjul-codepipeline --region ${region} | jq -r '.stageStates[].latestExecution.status' |grep InProgress)

if [ ! -z "$CHECK_PIPELINE_RUNNING" ]; then
    logger "INFO" "CodePipeline is still In Progress. Seems this is a regular deployment and the container will start in a moments..."
    exit 0;
fi

# 2. If the script reached this point - means the container isn't running and there isn't deployment in progress
# Go for the latest build
KEY=$(aws s3 ls ${artifacts_bucket}/${service_name}-codepipel/build/ | sort | tail -n 1 | awk '{print $4}')

if [ -z "$KEY" ]; then
    logger "ERROR" "The requested KEY does not exist in S3 bucket ${artifacts_bucket}. It's a strange situation."
    exit 1;
fi

DOWNLOAD_LATEST_BUILD_ARTIFACTS=$(aws s3 cp s3://${artifacts_bucket}/${service_name}-codepipel/build/$KEY ./latest-build-artifact)

if [ -z "$DOWNLOAD_LATEST_BUILD_ARTIFACTS" ]; then
    logger "ERROR" "The artifacts weren't downloaded. Check the S3 permissions or either the bucket [${artifacts_bucket}] or key [$KEY] exist."

    exit 1;
fi

# 3. Unzip the artifacts
unzip -o latest-build-artifact

# 4. Check scripts folder is now available
CHECK_SCRIPTS_EXISTS=$(ls -la scripts)

if [ -z "$CHECK_SCRIPTS_EXISTS" ]; then
    logger "ERROR" "The scripts folder isn't existing."

    exit 1;
fi

# 5. Run the squence of the scripts: login to ecr
logger "INFO" "Running login_to_ecr script."
chmod +x /scripts/login_to_ecr.sh ; source /scripts/login_to_ecr.sh

# 6. Run the squence of the scripts: start the server
logger "INFO" "Running start_server script."
chmod +x /scripts/start_server.sh ; source /scripts/start_server.sh

# 7. Check if there is running process in docker
IS_DOCKER_RUNNING=$(docker ps) 

if [ -z "$IS_DOCKER_RUNNING" ]; then
    logger "CRITICAL" "You have bigger problem than app not just running. Better check your DB."

    exit 1;
fi
