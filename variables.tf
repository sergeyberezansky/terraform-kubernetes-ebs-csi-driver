variable "ebs_csi_controller_role_name" {
  description = "The name of the EBS CSI driver IAM role"
  default     = "ebs-csi-driver-controller"
  type        = string
}

variable "ebs_csi_controller_role_policy_name_prefix" {
  description = "The prefix of the EBS CSI driver IAM policy"
  default     = "ebs-csi-driver-policy"
  type        = string
}

variable "ebs_csi_controller_image" {
  description = "The EBS CSI driver controller's image"
  default     = ""
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
  type        = map(string)
}

variable "namespace" {
  description = "The K8s namespace for all EBS CSI driver resources"
  type        = string
  default     = "kube-system"
}

variable "oidc_url" {
  description = "EKS OIDC provider URL, to allow pod to assume role using IRSA"
  type        = string
}

variable "node_tolerations" {
  description = "CSI driver node tolerations"
  type        = list(map(string))
  default     = []
}

variable "csi_controller_tolerations" {
  description = "CSI driver controller tolerations"
  type        = list(map(string))
  default     = []
}

variable "csi_controller_replica_count" {
  description = "Number of EBS CSI driver controller pods"
  type        = number
  default     = 2
}

variable "enable_volume_resizing" {
  description = "Whether to enable volume resizing"
  type        = bool
  default     = false
}

variable "enable_volume_snapshot" {
  description = "Whether to enable volume snapshotting"
  type        = bool
  default     = false
}

variable "extra_create_metadata" {
  description = "If set, add pv/pvc metadata to plugin create requests as parameters."
  type        = bool
  default     = false
}

variable "eks_cluster_id" {
  description = "ID of the Kubernetes cluster used for tagging provisioned EBS volumes"
  type        = string
  default     = ""
}

variable "extra_node_selectors" {
  description = "A map of extra node selectors for all components"
  default     = {}
  type        = map(string)
}

variable "controller_extra_node_selectors" {
  description = "A map of extra node selectors for controller pods"
  default     = {}
  type        = map(string)
}

variable "node_extra_node_selectors" {
  description = "A map of extra node selectors for node pods"
  default     = {}
  type        = map(string)
}
