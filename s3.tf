# AWS CodeBuild Resources:
resource "aws_s3_bucket" "kf-cbld-bucket" {
  bucket = "kf-cbld-${var.service_name}-bucket"
}

resource "aws_s3_bucket_acl" "kf-cbld-bucket-acl" {
  bucket = aws_s3_bucket.kf-cbld-bucket.id
  acl    = "private"
}

# AWS CodePipeline Resources:
resource "aws_s3_bucket" "kf-cdppln-bucket" {
  bucket = "kf-cdppln-${var.service_name}-bucket"
}

resource "aws_s3_bucket_acl" "kf-cdppln-bucket-acl" {
  bucket = aws_s3_bucket.kf-cdppln-bucket.id
  acl    = "private"
}
