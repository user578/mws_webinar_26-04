resource "mws_mk8s_cluster" "webinar" {
  availability = {
    standalone = {
      zone = "ru-central1-a"
    }
    # zonal_ha = { // zonal high available
    #   zone = "ru-central1-b"
    # }
  }

  cluster_name = var.cluster_name

  metadata = {
    description  = "Cluster for Webinar Project"
    display_name = "standalone-k8s"
  }

  network = {
    pods_cidr     = var.pods_cidr
    services_cidr = var.services_cidr
    primary_endpoint = {
      ref = mws_vpc_address.address.id
    }
    public_endpoint = {
      ref = mws_vpc_external_address.kubeapi.id
    }
  }

  version_control = {
    release_channel = "stable"
    maintenance_window = {
      weekly = {
        days = ["MONDAY", "WEDNESDAY"]
        hour = 3
      }
    }
    version = "v1.34.1-mws.1"
  }
}