output "kubeapi_ipv4" {
  description = "Allocated IPv4 address of the kubeapi external address"
  value       = mws_vpc_external_address.kubeapi.status.ip_address
}

output "cluster_name" {
  value = var.cluster_name
}