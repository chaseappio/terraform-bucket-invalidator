
resource "aws_s3_bucket_notification" "this" {
  bucket = "${var.bucket_id}"

 lambda_function {
    lambda_function_arn = "${aws_lambda_function.this.arn}"
    events              = ["s3:ObjectCreated:*"]
  }
}

#Lambda
locals {
  base_path = "${path.module}/src"
}

data "template_file" "this" {
  template = "${file("${local.base_path}/params.template.json")}"

  vars = {
    PATH_PREFIX = "${var.path_prefix}"
  }
}

resource "local_file" "params" {
  content = "${data.template_file.this.rendered}"
  filename = "${local.base_path}/params.json"
}


data "archive_file" "this" {
  depends_on = [
    "local_file.params"
  ]

  type = "zip"
  output_path = "${local.base_path}/../.archive.zip"
  source_dir = "${local.base_path}"
}

resource "aws_lambda_function" "this" {

  filename = "${data.archive_file.this.output_path}"
  source_code_hash = "${data.archive_file.this.output_base64sha256}"

  function_name    = "${var.name}"
  runtime = "nodejs8.10"
  role    = "${aws_iam_role.this.arn}"
  memory_size = 128
  timeout = 60
  handler = "main.handler"
}
