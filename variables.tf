# General Variables

variable "prefix" {
  description = "The prefix which should be used for all resources in this example."
  default     = "ecs-anywhere"
}

# GCP Variables

variable "gcp_project" {
  type        = string
  default     = "jcolemorrison-ecs-anywhere"
  description = "The GCP project used as context for creating resources."
}
