# Make sure you lock down all providers version.

provider "vsphere" {
  version = "~> 1.16"

  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

provider "local" {
  version = "~> 1.4"
}
