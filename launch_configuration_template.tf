data "template_file" "kf_lc-codedeploy-agent" {
  template = file("scripts/provision_codedeploy_agent.sh")
  vars = {
    region = var.region
  }
}

data "template_file" "kf_lc-auto-remediate" {
  template = file("scripts/auto_remediate.sh")
  vars = {
    artifacts_bucket = aws_s3_bucket.kf-cdppln-bucket.bucket
    service_name     = var.service_name
    region           = var.region
  }
}

data "template_cloudinit_config" "kf_lc-user-data" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "provision_codedeploy_agent.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.kf_lc-codedeploy-agent.rendered
  }

  part {
    filename     = "auto_remediate.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.kf_lc-auto-remediate.rendered
  }
}
