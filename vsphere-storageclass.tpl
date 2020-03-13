kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: vsphere-storageclass
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/vsphere-volume
parameters:
  datastore: ${datastore}
  diskformat: thin
