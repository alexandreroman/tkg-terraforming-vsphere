# Make sure you lock down all providers version.

terraform {
  required_providers {
    vsphere = "~> 2.0.1"
    local = "~> 1.4"
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}
