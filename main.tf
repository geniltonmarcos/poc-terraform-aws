provider "aws" {
  region = "us-east-2"  # Altere para a região desejada
}


## BUCKET
resource "aws_s3_bucket" "bucket_data_processed" {
  bucket = "bucket-glue-processed" 
  force_destroy = true
  acl    = "private"

  tags = {
    Name = "TerraForm S3 Glue"
  }
}

#Bucket scripts
resource "aws_s3_bucket" "bucket_script" {
  bucket = "bucket-glue-script" 
  force_destroy = true
 
  tags = {
    Name = "TerraForm S3 Glue"
  }
}

variable "files_script_to_upload" {
  default = ["process_player.py"] 
}

resource "aws_s3_bucket_object" "upload_objects_script" {
 count = length(var.files_script_to_upload)

  bucket = aws_s3_bucket.bucket_script.id
  key    = var.files_script_to_upload[count.index]
  source = "script/${var.files_script_to_upload[count.index]}"
}

#Bucket data
resource "aws_s3_bucket" "bucket_data_unprocessed" {
  bucket = "bucket-unprocessed" 
  force_destroy = true
  acl    = "private"

  tags = {
    Name = "TerraForm S3 Glue"
  }
}

variable "files_data_to_upload" {
  default = ["addresses.csv", "mlb_players.csv"]  # Adicione os nomes dos arquivos aqui
}

resource "aws_s3_bucket_object" "upload_objects_data" {
 count = length(var.files_data_to_upload)

  bucket = aws_s3_bucket.bucket_data_unprocessed.id
  key    = var.files_data_to_upload[count.index]
  source = "files/${var.files_data_to_upload[count.index]}"
}

#### GLUE
locals {
  full_name = "${var.organization}${length(var.organization) > 0 ? "-" : ""}${var.environment}-${var.name}"
  tags      = merge({
    Terraform   = "True"
    Environment = var.environment
  }, var.tags)
}

resource "aws_glue_job" "this" {
  name                   = local.full_name
  role_arn               = var.create_role ? join("", aws_iam_role.role.*.arn) : var.role_arn
  connections            = var.connections
  description            = var.description
  glue_version           = var.glue_version
  max_retries            = var.max_retries
  timeout                = var.timeout
  security_configuration = var.create_security_configuration ? join("", aws_glue_security_configuration.sec_cfg.*.id) : var.security_configuration
  worker_type            = var.worker_type
  number_of_workers      = var.number_of_workers
  tags                   = local.tags

  command {
    name            = "glueetl"
    script_location = var.script_location
    python_version  = var.python_version
  }

  default_arguments = {
    "--job_process_history_players"           = local.full_name
    "--job-language"                          = var.job_language
    "--class"                                 = var.class
    "--extra-py-files"                        = length(var.extra_py_files) > 0 ? join(",", var.extra_py_files) : null
    "--extra-jars"                            = length(var.extra_jars) > 0 ? join(",", var.extra_jars) : null
    "--user-jars-first"                       = var.user_jars_first
    "--use-postgres-driver"                   = var.use_postgres_driver
    "--extra-files"                           = length(var.extra_files) > 0 ? join(",", var.extra_files) : null
    "--job-bookmark-option"                   = var.job_bookmark_option
    "--TempDir"                               = var.temp_dir
    "--enable-s3-parquet-optimized-committer" = var.enable_s3_parquet_optimized_committer
    "--enable-rename-algorithm-v2"            = var.enable_rename_algorithm_v2
    "--enable-glue-datacatalog"               = var.enable_glue_datacatalog ? "" : null
    "--enable-metrics"                        = var.enable_metrics ? "" : null
    "--enable-continuous-cloudwatch-log"      = var.enable_continuous_cloudwatch_log
    "--enable-continuous-log-filter"          = var.enable_continuous_log_filter
    "--continuous-log-logGroup"               = join("", aws_cloudwatch_log_group.log_group.*.name)
    "--continuous-log-logStreamPrefix"        = var.continuous_log_stream_prefix
    "--continuous-log-conversionPattern"      = var.continuous_log_conversion_pattern
    "--enable-spark-ui"                       = var.enable_spark_ui
    "--spark-event-logs-path"                 = var.spark_event_logs_path
    "--additional-python-modules"             = length(var.additional_python_modules) > 0 ? join(",", var.additional_python_modules) : null
  }

  execution_property {
    max_concurrent_runs = var.max_concurrent_runs
  }

  dynamic "notification_property" {
    for_each = var.notify_delay_after == null ? [] : [1]

    content {
      notify_delay_after = var.notify_delay_after
    }
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws-glue/jobs/${local.full_name}"
  retention_in_days = var.log_group_retention_in_days
  tags              = var.tags
}

resource "aws_glue_security_configuration" "sec_cfg" {
  count = var.create_security_configuration ? 1 : 0
  name  = "${local.full_name}-sec-config"

  encryption_configuration {
    dynamic "cloudwatch_encryption" {
      for_each = [var.security_configuration_cloudwatch_encryption]

      content {
        cloudwatch_encryption_mode = cloudwatch_encryption.value.cloudwatch_encryption_mode
        kms_key_arn                = cloudwatch_encryption.value.kms_key_arn
      }
    }

    dynamic "job_bookmarks_encryption" {
      for_each = [var.security_configuration_job_bookmarks_encryption]

      content {
        job_bookmarks_encryption_mode = job_bookmarks_encryption.value.job_bookmarks_encryption_mode
        kms_key_arn                   = job_bookmarks_encryption.value.kms_key_arn
      }
    }

    dynamic "s3_encryption" {
      for_each = [var.security_configuration_s3_encryption]

      content {
        s3_encryption_mode = s3_encryption.value.s3_encryption_mode
        kms_key_arn        = s3_encryption.value.kms_key_arn
      }
    }
  }
}

resource "aws_iam_role" "role" {
  count = var.create_role ? 1 : 0
  name  = "${local.full_name}-role"
  tags  = local.tags

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = [
          "sts:AssumeRole"
        ]
        Principal = {
          "Service" = "glue.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]
}
