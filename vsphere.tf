data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "vm_folder" {
  path          = var.vm_folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "resource_pool" {
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "ubuntu_template" {
  name          = "bionic-server-cloudimg-amd64"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "local_file" "vsphere_storage_class" {
    content = templatefile("vsphere-storageclass.tpl", {
      datastore_url = var.datastore_url,
    })
    filename        = "vsphere-storageclass.yml"
    file_permission = "0644"
}
