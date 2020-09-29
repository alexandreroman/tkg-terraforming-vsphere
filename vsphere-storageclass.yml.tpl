kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: vsphere-storageclass
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: csi.vsphere.vmware.com
allowVolumeExpansion: true
parameters:
  DatastoreURL: "${datastore_url}"
