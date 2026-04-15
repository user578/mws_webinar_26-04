resource "mws_vpc_network" "network" {
  network = var.network_name
  project = var.project_id
}

resource "mws_vpc_subnet" "subnet_a" {
  subnet  = "${var.subnet_name}-a"
  network = mws_vpc_network.network.network
  cidr    = var.subnet_cidr_a
}

resource "mws_vpc_subnet" "subnet_b" {
  subnet  = "${var.subnet_name}-b"
  network = mws_vpc_network.network.network
  cidr    = var.subnet_cidr_b
}

resource "mws_vpc_subnet" "subnet_c" {
  subnet  = "${var.subnet_name}-c"
  network = mws_vpc_network.network.network
  cidr    = var.subnet_cidr_c
}

resource "mws_vpc_address" "address" {
  address    = var.address_name
  network    = mws_vpc_network.network.network
  subnet     = mws_vpc_subnet.subnet_a.metadata.id
  ip_address = var.primary_endpoint_ip
}

resource "mws_vpc_external_address" "egress_nat_address" {
  external_address = "egress-nat-address"
}

# external address to expose kubeapi
resource "mws_vpc_external_address" "kubeapi" {
  external_address = "kubeapi"
}

# external address to expose nginx ingress via LB service
resource "mws_vpc_external_address" "ingress-nginx" {
  external_address = "ingress-nginx"
}

resource "mws_vpc_egress_nat" "egress_nat" {
  egress_nat = "egress-nat"
  network    = mws_vpc_network.network.network

  external = {
    addresses = [
      {
        ref = mws_vpc_external_address.egress_nat_address.id
      }
    ]
  }

  internal = {
    subnets = [
      mws_vpc_subnet.subnet_b.id,
      mws_vpc_subnet.subnet_c.id,
    ]
  }
}