resource "mws_vpc_firewall_rule" "firewall_rule_kubeapi_primary" {
  firewall_rule = "webinar-kubeapi-primary"
  network       = mws_vpc_network.network.network
  project       = mws_vpc_network.network.project

  direction = "INGRESS"
  action    = "ALLOW"
  active    = true
  priority  = 1000

  proto_ports = [
    "TCP:6443"
  ]

  source = {
    spec = {
      cidrs = ["0.0.0.0/0"]
    }
  }

  destination = {
    spec = {
      cidrs = ["${mws_vpc_address.address.ip_address}/32"]
    }
  }

  metadata = {
    display_name = "webinar-kubeapi-primary"
  }
}

resource "mws_vpc_firewall_rule" "firewall_rule_nginx" {
  firewall_rule = "webinar-ingress-nginx"
  network       = mws_vpc_network.network.network
  project       = mws_vpc_network.network.project

  direction = "INGRESS"
  action    = "ALLOW"
  active    = true
  priority  = 1000

  proto_ports = [
    "TCP:${var.ingress_nginx_nodeport1}",
    "TCP:${var.ingress_nginx_nodeport2}",
  ]

  source = {
    spec = {
      cidrs = ["0.0.0.0/0"]
    }
  }

  destination = {
    spec = {
      cidrs = [
        mws_vpc_subnet.subnet_b.cidr,
        mws_vpc_subnet.subnet_c.cidr,
      ]
    }
  }

  metadata = {
    display_name = "webinar-ingress-nginx"
  }
}