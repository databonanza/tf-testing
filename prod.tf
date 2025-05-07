#Production

terraform {
  required_providers {
    aws = {
      source	= "hashicorp/aws"
      version	= "~> 5.0"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }  
  required_version = ">= 1.10.4"
}

locals {
  aws_region = "us-east-1"
  aws_profile = "my-prod-aws-profile"
  ecr_add = "prod-ecr-add"
  config_file = "./prod_conf.json"
  ecr_name = "prod-ecr-name"
  image_version = "latest"
  plat_arch = "linux/x86"
  cluster_name = "prod-cluster"
  ecs_name = "prod-ecs"
  profile = "tf-test"
}

provider "aws" {
  region = "${local.aws_region}"
  profile = "${local.profile}"
}

provider "docker" {
  registry_auth {
    address = "${local.ecr_add}"
    config_file = pathexpand("${local.config_file}")
  }
}

resource "aws_ecr_repository" "prod" {
  name = "${local.ecr_name}"
}

data "aws_ecr_authorization_token" "prod_token" {}

resource "docker_image" "prod_image" {
  name = "${data.aws_ecr_authorization_token.prod_token.proxy_endpoint}/${local.ecr_name}:${local.image_version}"
  build {
    context = "."
  }
  platform = "${local.plat_arch}"
}

resource "docker_registry_image" "prod" {
  name = docker_image.prod_image.name
  keep_remotely = true
}

resource "aws_ecs_cluster" "prod" {
  name = "${local.cluster_name}"
#  log_configuration {
#    cloud_watch_encryption_enabled = true
#  }
}

resource "aws_ecs_service" "prod" {
  name = "${local.ecs_name}"
  cluster = aws_ecs_cluster.prod.id
}
