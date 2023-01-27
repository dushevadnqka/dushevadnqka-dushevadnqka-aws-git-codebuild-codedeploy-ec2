resource "aws_ecr_repository" "kf-repo" {
  name                 = var.service_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
