variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "instance_0_public_ip" {
  type        = string
  description = "Pass this in at runtime"
}

variable "instance_1_public_ip" {
  type        = string
  description = "Pass this in at runtime"
}

variable "pre_shared_key" {
  type        = string
  sensitive   = true
  description = "Pass this in at runtime"
}

variable "vnet_cidr" {
  type    = string
  default = "10.55.0.0/24"
}

variable "subnet_mask" {
  type    = string
  default = "255.255.255.192"
}

variable "subnet_out_cidr" {
  type    = string
  default = "10.55.0.0/26"
}

variable "subnet_in_cidr" {
  type    = string
  default = "10.55.0.64/26"
}

variable "subnet_vm_cidr" {
  type    = string
  default = "10.55.0.128/26"
}

variable "subnet_bh_cidr" {
  type    = string
  default = "10.55.0.192/26"
}

variable "route_out_subnet" {
  type    = string
  default = "10.44.0.0"
}

variable "route_out_subnet_mask" {
  type    = string
  default = "255.255.0.0"
}

variable "route_out_gateway_ip" {
  type    = string
  default = "10.55.0.1"
}