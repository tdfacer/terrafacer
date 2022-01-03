# global
# variable "environment" {}
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type = string
}

variable "aws_account_id" {
  type = string
}

# project
variable "project_name" {}
variable "org_id" {}

# cluster
variable "create_cluster" {
  type = bool
}
variable "cluster_name" {}
variable "cluster_version" {
  type = string
}

# database
variable "database_name" {}

# user
variable "user_name" {}
variable "user_password" {}

# access
variable "whitelist_ips" {
  type = map(object({
    ip          = string
    description = string
  }))
}

resource "mongodbatlas_project" "project" {
  name   = var.project_name
  org_id = var.org_id
}

resource "mongodbatlas_cluster" "cluster" {
  # Optionally run stack without creating the cluster since Atlas does not
  # support the create cluster API for free tier. This allows one to deploy
  # the stack without the cluster then import the cluster later.
  count                        = var.create_cluster == true ? 1 : 0
  project_id                   = mongodbatlas_project.project.id
  name                         = var.cluster_name
  auto_scaling_disk_gb_enabled = false
  mongo_db_major_version       = var.cluster_version

  # Provider Settings "block"
  provider_name               = "TENANT"
  backing_provider_name       = "AWS"
  provider_region_name        = "US_EAST_1"
  provider_instance_size_name = "M0"
}

resource "mongodbatlas_database_user" "user" {
  username           = var.user_name
  password           = var.user_password
  project_id         = mongodbatlas_project.project.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = var.database_name
  }

  scopes {
    name = var.cluster_name
    type = "CLUSTER"
  }
}

resource "mongodbatlas_project_ip_access_list" "access_list" {
  project_id = mongodbatlas_project.project.id
  for_each   = var.whitelist_ips

  ip_address = each.value.ip
  comment    = each.value.description
}

data "mongodbatlas_cluster" "cluster" {
  project_id = mongodbatlas_project.project.id
  name       = mongodbatlas_project.project.name
}

resource "mongodbatlas_network_peering" "network_peering" {
  # count                = var.create_cluster == true ? 1 : 0
  accepter_region_name = var.region
  project_id           = mongodbatlas_project.project.id
  # container_id           = mongodbatlas_cluster.cluster[0].container_id
  # container_id           = mongodbatlas_cluster.cluster.container_id
  container_id = data.mongodbatlas_cluster.cluster.container_id
  # container_id           = mongodbatlas_cluster.cluster[0].container_id
  provider_name          = "AWS"
  route_table_cidr_block = "192.168.0.0/24"
  vpc_id                 = var.vpc_id
  aws_account_id         = var.aws_account_id
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  # count                     = var.create_cluster == true ? 1 : 0
  # vpc_peering_connection_id = mongodbatlas_network_peering.network_peering[0].connection_id
  vpc_peering_connection_id = mongodbatlas_network_peering.network_peering.connection_id
  auto_accept               = true
}
