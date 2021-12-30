# global
# variable "environment" {}

# project
variable "project_name" {}
variable "org_id" {}

# cluster
variable "create_cluster" {
  type = bool
}
variable "cluster_name" {}

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

  # Provider Settings "block"
  provider_name               = "TENANT"
  backing_provider_name       = "AWS"
  provider_region_name        = "US_EAST_1"
  provider_instance_size_name = "M0"
}

# resource "mongodbatlas_database_user" "user" {
#   username           = var.user_name
#   password           = var.user_password
#   project_id         = var.project_id
#   auth_database_name = "admin"

#   roles {
#     role_name     = "readWrite"
#     database_name = "dbforApp"
#   }

#   roles {
#     role_name     = "readAnyDatabase"
#     database_name = "admin"
#   }

#   labels {
#     key   = "My Key"
#     value = "My Value"
#   }

#   scopes {
#     name = "My cluster name"
#     type = "CLUSTER"
#   }

#   scopes {
#     name = "My second cluster name"
#     type = "CLUSTER"
#   }
# }
