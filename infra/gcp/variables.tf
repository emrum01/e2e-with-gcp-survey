variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "asia-northeast1-a"
}

variable "env" {
  description = "Environment (dev, stg, prd)"
  type        = string
  default     = "dev"
}

variable "database_name" {
  description = "The name of the database to create"
  type        = string
  default     = "survey_db"
}

variable "database_user" {
  description = "The name of the database user"
  type        = string
  default     = "survey_user"
}

variable "database_password" {
  description = "The password for the database user"
  type        = string
  sensitive   = true
}
