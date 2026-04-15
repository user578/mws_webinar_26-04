variable "network_name" {
  type        = string
  default     = "webinar"
  description = "VPC network name"
}

variable "subnet_name" {
  type        = string
  default     = "webinar"
  description = "Base name for subnets"
}

variable "subnet_cidr_a" {
  type        = string
  default     = "192.168.0.0/24"
  description = "CIDR for subnet A"
}

variable "subnet_cidr_b" {
  type        = string
  default     = "192.168.1.0/24"
  description = "CIDR for subnet B"
}

variable "subnet_cidr_c" {
  type        = string
  default     = "192.168.2.0/24"
  description = "CIDR for subnet C used by the manual ng-2 node group"
}

variable "address_name" {
  type        = string
  default     = "k8s-primary-ip"
  description = "Name for the primary endpoint address"
}

variable "primary_endpoint_ip" {
  type        = string
  default     = "192.168.0.10"
  description = "Predetermined IP address for the cluster primary endpoint in subnet A"
}

variable "cluster_name" {
  type        = string
  default     = "webinar"
  description = "Name of the Kubernetes cluster"
}

variable "pods_cidr" {
  type        = string
  default     = "10.222.0.0/18"
  description = "Pods CIDR block"
}

variable "services_cidr" {
  type        = string
  default     = "10.222.64.0/18"
  description = "Services CIDR block"
}

variable "service_account_ref" {
  type        = string
  default     = "iam/projects/mws-sdf/serviceAccounts/sa-tf-node-group"
  description = "Service account reference (iam/projects/<project>/serviceAccounts/<service-account>)"
}

variable "ingress_nginx_nodeport1" {
  type    = number
  default = 32079
}

variable "ingress_nginx_nodeport2" {
  type    = number
  default = 32080
}
