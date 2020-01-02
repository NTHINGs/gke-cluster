# Copyright 2019 Jetstack Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

terraform {
  required_version = "~> 0.12"

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "tecnoly"

    workspaces {
      name = "gke-cluster"
    }
  }
}

# Local values assign a name to an expression, that can then be used multiple
# times within a module. They are used here to determine the GCP region from
# the given location, which can be either a region or zone.
locals {
  gcp_location_parts = split("-", var.gcp_location)
  gcp_region         = format("%s-%s", local.gcp_location_parts[0], local.gcp_location_parts[1])
}

# https://www.terraform.io/docs/providers/google/index.html
provider "google" {
  project     = var.gcp_project_id
  region      = local.gcp_region
  credentials = base64decode(var.gcp_credentials)
}

resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_network_name
  auto_create_subnetworks = "false"
}

# https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
resource "google_compute_subnetwork" "vpc_subnetwork" {
  name = var.vpc_subnetwork_name

  ip_cidr_range = var.vpc_subnetwork_cidr_range
  network       = var.vpc_network_name
  secondary_ip_range {
    range_name    = var.cluster_secondary_range_name
    ip_cidr_range = var.cluster_secondary_range_cidr
  }
  secondary_ip_range {
    range_name    = var.services_secondary_range_name
    ip_cidr_range = var.services_secondary_range_cidr
  }
  private_ip_google_access = true

  depends_on = [
    google_compute_network.vpc_network,
  ]
}

module "cluster" {
  source  = "jetstack/gke-cluster/google"
  version = "0.2.0-alpha1"

  # These values are set from the terrafrom.tfvas file
  gcp_project_id                         = var.gcp_project_id
  cluster_name                           = var.cluster_name
  gcp_location                           = var.gcp_location
  daily_maintenance_window_start_time    = var.daily_maintenance_window_start_time
  node_pools                             = var.node_pools
  cluster_secondary_range_name           = var.cluster_secondary_range_name
  services_secondary_range_name          = var.services_secondary_range_name
  master_ipv4_cidr_block                 = var.master_ipv4_cidr_block
  access_private_images                  = var.access_private_images
  http_load_balancing_disabled           = var.http_load_balancing_disabled
  master_authorized_networks_cidr_blocks = var.master_authorized_networks_cidr_blocks

  # Refer to the vpc-network and vpc-subnetwork by the name value on the
  # resource, rather than the variable used to assign the name, so that
  # Terraform knows they must be created before creating the cluster

  vpc_network_name    = google_compute_network.vpc_network.name
  vpc_subnetwork_name = google_compute_subnetwork.vpc_subnetwork.name
}