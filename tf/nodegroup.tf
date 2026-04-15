resource "mws_mk8s_node_group" "ng-1" {
  cluster_name    = mws_mk8s_cluster.webinar.cluster_name
  node_group_name = "${mws_mk8s_cluster.webinar.cluster_name}-ng-1"

  service_account = {
    ref = var.service_account_ref
  }

  subnet = {
    ref = mws_vpc_subnet.subnet_b.metadata.id
  }

  vm_type = {
    ref = "compute/vmTypes/gen-4-16"  # mws compute vm-type list
  }

  scale = {
    fixed = 3
  }

  rollout_strategy = {
    max_surge       = 1
    max_unavailable = 0
  }

  version_control = {
    auto_update = true
    version     = "v1.34.1-mws.1"
    maintenance_window = {
      weekly = {
        days     = ["MONDAY", "WEDNESDAY"]
        hour     = 3
        duration = "4h"
      }
    }
  }

  image_storage_size = "30Gb"

  labels = [
    { key = "environment", value = "production" },
    { key = "team", value = "devops" }
  ]

  taints = []

  zone = "ru-central1-b"
}