variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region in which to create resources."
  type        = string
  default     = "us-central1"
}

variable "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic."
  type        = string
}

variable "pubsub_subscription_name" {
  description = "The name of the Pub/Sub subscription."
  type        = string
}

variable "pubsub_subscription_ack_deadline" {
  description = "The acknowledgement deadline in seconds"
  type        = number
  default     = 10
}

variable "pubsub_subscription_retention_duration" {
  description = "The message retention duration in seconds."
  type        = number
  default     = 604800 # 7 days
}

variable "bigquery_dataset_name" {
  description = "The name of the BigQuery dataset."
  type        = string
}

variable "bigquery_table_name" {
  description = "The name of the BigQuery table."
  type        = string
}

variable "labels" {
  description = "Labels"
  type        = map(string)
  default     = { 
    env = "development", 
    purpose = "challenge-latam"
  }
}