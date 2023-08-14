provider "aws" {
  region = "us-east-2"  # Altere para a região desejada
}


resource "aws_s3_bucket" "bucket_data_processed" {
  bucket = "bucket-processed"  # Altere para um nome único
  force_destroy = true
  acl    = "private"

  tags = {
    Name = "TerraForm S3 Glue"
  }
}

#Bucket scripts
resource "aws_s3_bucket" "bucket_script" {
  bucket = "bucket-script" 
  force_destroy = true
  acl    = "private"

  tags = {
    Name = "TerraForm S3 Glue"
  }
}

variable "files_script_to_upload" {
  default = ["process_player.py"] 
}

resource "aws_s3_bucket_object" "upload_objects_script" {
 count = length(var.files_script_to_upload)

  bucket = aws_s3_bucket.bucket_data_unprocessed.id
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

## creating aws glue
resource "aws_glue_catalog_database" "catalog_database_players_full" {
  name = "catalog_database_players_full"
}

resource "aws_glue_catalog_table" "table_players_full" {
  name     = "table_players_full"
  database = aws_glue_catalog_database.catalog_database_players_full.name

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location = "s3://bucket-processed/temp/"
  }

  # partition_keys = [
  #   {
  #     name = "partition_column_name",
  #     type = "string",
  #   },
  # ]
}

## recupera o aws account Id
data "aws_caller_identity" "current" {}
locals {
    account_id = data.aws_caller_identity.current.account_id
}

resource "aws_glue_job" "job_history_players" {
  name     = "job_process_history_players"
  role_arn = "arn:aws:iam::${local.account_id}:role/AWSGlueServiceRole-analytics-glue"

  command {
    name            = "glueetl"
    script_location = "s3://bucket-script/process_player.py"
  }

  default_arguments = {
    "--job-language" = "python"
  }

  execution_property {
    max_concurrent_runs = 1
  }
}
