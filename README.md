# Terraforming vSphere for Tanzu Kubernetes Grid (TKG)

Use this repository to deploy [TKG](https://tanzu.vmware.com/kubernetes-grid)
to vSphere 6.7U3, leveraging these Terraform scripts.

## Prerequisites

### Download components

Download TKG bits to your workstation. The following components are required:

- TKG CLI for Linux: includes the `tkg` CLI used to operate TKG and workload clusters from the jumpbox VM
- Photon OS node OVA: used for TKG nodes
- Photon OS HAProxy OVA: used for control plane load balancers
- [Ubuntu Bionic server cloud image OVA](https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.ova): used for the jumpbox VM

Make sure to copy the TKG CLI archive (`tkg-linux-amd64-*.gz`) to this repository.

### Prepare vSphere infrastructure

First, make sure DHCP is enabled: this service is required for all TKG nodes.

Create a resource pool under the cluster where TKG is deployed to: use name `TKG`.

![Create a new resource pool](images/vsphere-resource-pool.png)

All TKG VMs will be deployed to this resource pool.

You should have 3 OVA files on your workstation
(Ubuntu Bionic server cloud image, Photon OS node, Photon OS HAProxy):
we're about to deploy each of these files to vSphere.

Repeat the next steps for each OVA file:

![Deploy OVF template](images/vsphere-deploy-ovf-part1.png)

![Upload OVF template](images/vsphere-deploy-ovf-part2.png)

![Select OVF template location](images/vsphere-deploy-ovf-part3.png)

![Select resource pool](images/vsphere-deploy-ovf-part4.png)

![Validate OVF template deployment](images/vsphere-deploy-ovf-part5.png)

All OVA files will be uploaded to your vSphere instance as new VMs.
**Make sure you do not start any of these VMs**.

You can now convert each of these VMs to templates:

![Convert VM to template](images/vsphere-deploy-ovf-part6.png)

### Create Terraform configuration

Starting from `terraform.tfvars.tpl`, create new file `terraform.tfvars`:

```yaml
vsphere_password = "changeme"
vsphere_server   = "vcsa.mycompany.com"

network       = "changeme"
datastore_url = "ds:///vmfs/volumes/changeme/"

# TKG 1.0.0
tkg_cli_file_name    = "tkg-linux-amd64-v1.0.0+vmware.1.gz"
tkg_node_template    = "photon-3-kube-v1.17.3+vmware.2"
tkg_haproxy_template = "capv-haproxy"

# TKG 1.1.0.RC1
#tkg_cli_file_name    = "tkg-linux-amd64-v1.1.0-rc.1+vmware.1.gz"
#tkg_node_template    = "photon-3-kube-v1.18.1+vmware.1"
#tkg_haproxy_template = "photon-3-haproxy-v1.2.4+vmware.1"
```

You must align this configuration file with the TKG version you deployed
to your vSphere instance.

## Bootstrap the jumpbox

Run this command to create a jumpbox VM using Terraform:
```bash
$ terraform apply
```

Using the jumpbox, you'll be able to interact with TKG using the `tkg` CLI.
You'll also use this jumpbox to connect to nodes using SSH.

Deploying the jumpbox VM takes less than 5 minutes.

At the end of this process, you can retrieve the jumpbox IP address:
```bash
$ terraform output jumpbox_ip_address
10.160.28.120
```

You may connect to the jumpbox VM using account `ubuntu`.

## Deploy TKG management cluster

Connect to the jumpbox VM using SSH:
```bash
$ ssh ubuntu@$(terraform output jumpbox_ip_address)
```

Create the TKG management cluster:
```bash
$ tkg init --infrastructure vsphere -v 6 -p dev
```

This process takes less than 10 minutes.

## Create TKG workload clusters

From the jumpbox VM, create a workload cluster:
```bash
$ tkg create cluster dev01 -p dev -v 6
```

This process takes less than 5 minutes.

Create a `kubeconfig` file to access your workload cluster:
```bash
$ tkg get credentials dev01 --export-file dev01.kubeconfig
```

You can now use this file to access your workload cluster:
```bash
$ KUBECONFIG=dev01.kubeconfig kubectl get nodes
NAME                          STATUS   ROLES    AGE     VERSION
dev01-control-plane-r5nwl     Ready    master   10m     v1.17.3+vmware.2
dev01-md-0-65bc768c89-xjn7h   Ready    <none>   9m44s   v1.17.3+vmware.2
```

Just copy this file to your workstation to access the cluster
without using the jumpbox VM.

**Tips** - use this command to merge 2 or more `kubeconfig` files:
```bash
$ KUBECONFIG=dev01.kubeconfig:dev02.kubeconfig kubectl config view --flatten > merged.kubeconfig
```

You may connect to a TKG node using this command (from the jumpbox VM):
```bash
$ ssh capv@node_ip_address
```

Use this command to add more nodes to your workload cluster (from the jumpbox VM):
```bash
$ tkg scale cluster dev01 --worker-machine-count 3
```

## Connect your workload cluster to a vSphere datastore

The workload cluster you created already includes a vSphere CSI.

The only thing you need to do is to apply a configuration file, designating the
vSphere datastore to use when creating Kubernetes persistent volumes.

Use generated file `vsphere-storageclass.yml`:
```bash
$ kubectl apply -f vsphere-storageclass.yml
```

You're done with TKG deployment. Enjoy!

## Contribute

Contributions are always welcome!

Feel free to open issues & send PR.

## License

Copyright &copy; 2020 [VMware, Inc. or its affiliates](https://vmware.com).

This project is licensed under the [Apache Software License version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
