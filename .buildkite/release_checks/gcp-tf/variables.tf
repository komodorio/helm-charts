variable "cluster_name" {
  type        = string
  description = "The name of the GKE cluster"
}

variable "project_id" {
  type        = string
  default     = "playground-387315"
  description = "The GCP project ID"
}

variable "node_count" {
  type        = number
  default     = 1
  description = "Node count"
}
