variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-west-2"
}

variable "github_token" {
  type        = string
  description = "Oauth token for auth to github."
}

variable "git_owner" {
  type        = string
  description = "The username of the repo owner."
}

variable "git_branch" {
  type        = string
  description = "The branch where on push the pipeline will be triggered."
}

variable "ec2_instance_type" {
  type        = string
  description = "The type of the EC2 instance."
}

variable "rds_instance_type" {
  type        = string
  description = "The type of the RDS instance."
}

variable "asg_size" {
  type        = string
  description = "Max count of instances in ASG."
}

variable "service_name" {
  type        = string
  description = "The base name of the app."
}

variable "aws_account_id" {
  type        = string
  description = "The AWS account ID."
}

variable "container_port" {
  type        = number
  description = "The port on which the container will run."
}

variable "memory_reserv" {
  type        = number
  description = "Memory reserv."
}

variable "docker_image_tag" {
  type        = string
  description = "The tag of the docker image."
  default     = "latest"
}

variable "git_repo" {
  type        = string
  description = "the name of the git repo"
}

variable "dockerhub_username" {
  type        = string
  description = "Username for Dockerhub"
}

variable "dockerhub_pass" {
  type        = string
  description = "Password for Dockerhub"
}
