# project
variable "project_name" {}
variable "org_id" {}

# cluster
variable "cluster_name" {}

resource "mongodbatlas_project" "project" {
  name   = var.project_name
  org_id = var.org_id
}

resource "mongodbatlas_cluster" "cluster-test" {
  project_id = mongodbatlas_project.project.id
  name       = var.cluster_name

  # Provider Settings "block"
  provider_name               = "TENANT"
  backing_provider_name       = "AWS"
  provider_region_name        = "US_EAST_1"
  provider_instance_size_name = "M0"
}
