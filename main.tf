
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

data "local_file" "invalidatorpy" {
  filename = "${local.base_path}/invalidator.py"
}

resource "local_file" "invalidatorpy" {
  content = "${data.local_file.invalidatorpy.content}"
  filename = "${local.base_path}/.archive/invalidator.py"
}

data "local_file" "initpy" {
  filename = "${local.base_path}/__init__.py"
}

resource "local_file" "initpy" {
  content = "${data.local_file.initpy.content}"
  filename = "${local.base_path}/.archive/__init__.py"
}

data "archive_file" "this" {
  depends_on = [
    "local_file.initpy",
    "local_file.invalidatorpy"
  ]

  type = "zip"
  output_path = "${local.base_path}/.archive.zip"
  source_dir = "${local.base_path}/.archive"
}

resource "aws_lambda_function" "this" {

  filename = "${data.archive_file.this.output_path}"
  source_code_hash = "${data.archive_file.this.output_base64sha256}"

  function_name    = "${var.name}"
  runtime = "python3.7"
  role    = "${aws_iam_role.this.arn}"
  memory_size = 128
  timeout = 60
  handler = "invalidator.lambda_handler"
}
