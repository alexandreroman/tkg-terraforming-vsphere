variable "vsphere_user" {
  type    = string
  default = "administrator@vsphere.local"
}

variable "vsphere_password" {
  type = string
}

variable "vsphere_server" {
  type = string
}

variable "datacenter" {
  type    = string
  default = "Datacenter"
}

variable "cluster" {
  type    = string
  default = "Cluster"
}

variable "datastore" {
  type    = string
  default = "LUN01"
}

variable "datastore_url" {
  type = string
}

variable "vm_folder" {
  type    = string
  default = "tkg"
}

variable "resource_pool" {
  type    = string
  default = "TKG"
}

variable "network" {
  type    = string
  default = "VM Network"
}

variable "tanzu_cli_file_name" {
  type    = string
  default = "tanzu-cli-bundle-v1.3.1-linux-amd64.tar"
}

variable "ubuntu_template" {
  type    = string
  default = "focal-server-cloudimg-amd64"
}

variable "http_proxy_host" {
  type    = string
  default = ""
}

variable "http_proxy_port" {
  type    = number
  default = 0
}

variable "control_plane_endpoint" {
  type = string
}
