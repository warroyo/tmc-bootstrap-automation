
locals {
  tkgs_cluster_variables = {
    "controlPlaneCertificateRotation" : {
      "activate" : true,
      "daysBefore" : 30
    },
    "defaultStorageClass" : var.storage_class,
    "defaultVolumeSnapshotClass" : var.storage_class,
    "nodePoolLabels" : [

    ],
    "nodePoolVolumes" : [
      {
        "capacity" : {
          "storage" : var.containerd_storage
        },
        "mountPath" : "/var/lib/containerd",
        "name" : "containerd",
        "storageClass" : var.storage_class
      },
      {
        "capacity" : {
          "storage" : var.kubelet_storage
        },
        "mountPath" : "/var/lib/kubelet",
        "name" : "kubelet",
        "storageClass" : var.storage_class
      }
    ],
    "ntp" : "172.16.20.10",
    "storageClass" : var.storage_class,
    "storageClasses" : [
     var.storage_class
    ],
    "vmClass" : var.cp_vm_class
  }

  tkgs_nodepool_a_overrides = {
    "nodePoolLabels" : [
    ],
    "storageClass" : var.storage_class,
    "vmClass" :var.np_vm_class
  }
}

resource "random_integer" "cluster-suffix" {
  min = 1000
  max = 5000
}


resource "tanzu-mission-control_tanzu_kubernetes_cluster" "tkgs_cluster" {
  name                    = "${var.cluster_name}${random_integer.cluster-suffix.result}"
  management_cluster_name = var.management_cluster_name
  provisioner_name        = var.provisioner_name

  spec {
    cluster_group_name = var.cluster_group

    topology {
      version           = var.k8s_version
      cluster_class     = "tanzukubernetescluster"
      cluster_variables = jsonencode(local.tkgs_cluster_variables)

      control_plane {
        replicas = var.cp_replicas

        os_image {
          name    = "photon"
          version = "3"
          arch    = "amd64"
        }
      }

      nodepool {
        name        = "md-0"

        spec {
          worker_class = "node-pool"
          replicas     = var.np_replicas
          overrides    = jsonencode(local.tkgs_nodepool_a_overrides)

          os_image {
            name    = "photon"
            version = "3"
            arch    = "amd64"
          }
        }
      }

      network {
        pod_cidr_blocks = [
          "100.96.0.0/11",
        ]
        service_cidr_blocks = [
          "100.64.0.0/13",
        ]
        service_domain = "cluster.local"
      }
    }
  }

  timeout_policy {
    timeout             = 60
    wait_for_kubeconfig = true
    fail_on_timeout     = true
  }
}
output "cluster_name" {
    value = tanzu-mission-control_tanzu_kubernetes_cluster.tkgs_cluster.name
}