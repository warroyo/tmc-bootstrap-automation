variable "cluster_name" {
  type = string
}

variable "cluster_group" {
  type = string
}

variable "storage_class" {
  type = string
}

variable "cp_replicas" {
  type = number
  default = 1
}

variable "np_replicas" {
    type = number
    default = 3
}
variable "k8s_version" {
  type = string
}

variable "cp_vm_class" {
  type = string
}

variable "np_vm_class" {
  type = string
}

variable "containerd_storage" {
  type = string
  default = "20G"
}

variable "kubelet_storage" {
  type = string
  default = "20G"
}
variable "management_cluster_name" {
  type = string
}

variable "provisioner_name" {
  type = string
}

variable "ntp" {
  type = string
}