# AWS Terraform Cloud infrastructure Project

![Alt text](./graph.svg?sanitize=true)
<img src="./graph.svg?sanitize=true">

## Contains:
- Basic VPC (Including public and private subnets, nat gateways, route tables, etc.): basically with public access to the ALB, and private connectivity (internal) between the services through the private subnets
- Security groups (RDS, ALB, EC2)
- RDS Aurora DB Cluster (single instance - PostgreSQL): single AZ, no replication, vanila..., closed for external connection
- Credentials stored and retreived by System Managers Parameter store (as a code of course): here the github token and dockerhub token could be stored as well, but for the sake of the simplicity I will skip
- Elastic Load Balancer (type Layer 7 ("Application") according to the OSI model)
- ECR (Docker) repository
- Launch Configuration with Auto Scalling Group for the provisioning of the EC2 (Amazon Linux) instances
- S3 buckets for the purposes of CodeBuild and CodePipeline (not encrypted yet - due to the lack of time)
- Simple IAM configuration (could be enhanced to follow more strict security criterias).
- Almost native AWS CI/CD Pipeline (Only GitHub is outside of the native AWS services): GitHub, CodeBuild, CodePipeline, CodeDeploy
- Auto Remediation script - based in any EC2 instance with the purpose to provision the normal work of the app in a situations where the instance is replaced by some reason (again very vanila (naive) implementation)

## Overview:

Very vanila AWS Cloud Infra Project - to provision simple pipeline from the github code change (single branch at the moment - only master), to the full deploy on the EC2 instnces (No A/B deployment strategy implemented at the moment) but with some autoremediation for the needs of the EC2 instances functioning - sometimes (e.g. when you initially bring the cloud with this project) it might take more time to bring functional DB (it takes around 6-7 minutes with this size of the configuration), but meanwhile the app is deployed and brought by docker - unsuccessfully waiting to connect to the DB. Yes - we can just timeout the provisioning of the pipeline (to be sure the RDS is already green), but how long would take - it is different any time, probably should set it to 10 minutes (don't like it :) ). That's why I constructed this script to be sure, when the unhealthy instance got fallen, the new one would take what is necessary 

## Prerequisits (only to apply it on the cloud, not to contribute):
- AWS Account
- AWS CLI installed on the machine: 
- Terraform installed (v1.3.7)*
- Git installed on the machine
- [optional] DockerHub account and `token`* which to use to authenticate while pulling images as https://github.com/dushevadnqka/go-challenge/blob/master/Dockerfile#L2 (while the AWS CodeBuild is running, you can imagine how much requests it makes to DockerHub - after 100 in period of 6 hours, Dockerhub requires an authentication, otherwise your pipeline will be blocked to pull the desired image. Workaround is to store this image on your ECR and to pull from there, but you need to modify the Dockerfile and the [code](https://github.com/dushevadnqka/go-challenge/blob/master/buildspec.yaml#L9) as well)

*Please be carefull if you are going to run it on MacOSX (M1) - as this project is using the deprecated template provider (yeah, I know...), which could fail.

*As storing your creds in the terraform.tfvars file, they will be exposed to your terraform state and console, which is not great. You might have few workarounds: encrypting them and then store (KMS), set them in Parameter store and then inject them as an [env vars into the codebuild](https://github.com/dushevadnqka/dushevadnqka-dushevadnqka-aws-git-codebuild-codedeploy-ec2/blob/master/codebuild.tf#L48) as setting the type `PARAMETER_STORE` (and the key as a value) 

## Install & Run:
1. Create your Access Keys for AWS: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html

2. Configure AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html

3. Check Terraform, Git and AWS cli

4. Create `terraform.tfvars` file from `terraform.tfvars.dist`:
    ```
    cp terraform.tfvars.dist terraform.dist
    ```
5. Fill the `terraform.tfvars` file

6. Init the project and run some plan:
    ```
    terraform init && terraform plan
    ```
7. Apply the changes to your account (it takes less than 10 minutes to bring everything up):
    ```
    terraform apply
    ```
8. Configure the application project to be processed through this infrastructure. So we need these to be set in your app project:
    - https://github.com/dushevadnqka/go-challenge/blob/master/appspec.yml
    - https://github.com/dushevadnqka/go-challenge/blob/master/buildspec.yaml
    - https://github.com/dushevadnqka/go-challenge/tree/master/scripts (for the sake of the TechChallenge)
    - [only for the sake of the TechChallenge]: https://github.com/dushevadnqka/go-challenge/blob/master/Dockerfile#L36 (btw, I have more insights how the go-lang code and the Dockerfile could be optimised, but decided to concentrate mostly on the infra part)

*If you are going to observe that the target group is falling when you provission it for first time, don't worry, probably
your RDS cluster isn't ready and the app couldn't connect. Just relax it will come in few moments automatically :)  

## Found an issue?

If you've found an issue with the application, the documentation, or anything else, we are happy to take contributions. Please raise an issue in the [github repository](https://github.com/dushevadnqka/dushevadnqka-dushevadnqka-aws-git-codebuild-codedeploy-ec2).


