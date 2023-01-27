variable "region" {
  description = "AWS region"
  default     = "us-west-2"
}

variable "github_token" {
  description = "Oauth token for auth to github."
}

variable "git_owner" {
  description = "The username of the repo owner."
}

variable "git_branch" {
  description = "The branch where on push the pipeline will be triggered."
}

variable "ec2_instance_type" {
  description = "The type of the EC2 instance."
}

variable "rds_instance_type" {
  description = "The type of the RDS instance."
}

variable "asg_size" {
  description = "Max count of instances in ASG."
}

variable "service_name" {
  description = "The base name of the app."
}

variable "aws_account_id" {
  description = "The AWS account ID."
}

variable "container_port" {
  description = "The port on which the container will run."
}

variable "memory_reserv" {
  description = "Memory reserv."
}

variable "docker_image_tag" {
  description = "The tag of the docker image."
  default     = "latest"
}

variable "git_repo" {
  description = "the name of the git repo"
}

variable "dockerhub_username" {
  description = "Username for Dockerhub"
}

variable "dockerhub_pass" {
  description = "Password for Dockerhub"
}
