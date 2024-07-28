output "pubsub_topic_id" {
  description = "The ID of the created Pub/Sub topic."
  value       = google_pubsub_topic.pubsub_topic.id
}

output "pubsub_subscription_id" {
  description = "The ID of the created Pub/Sub subscription."
  value       = google_pubsub_subscription.pubsub_subscription.id
}

output "bigquery_dataset_id" {
  description = "The ID of the created BigQuery dataset."
  value       = google_bigquery_dataset.bq_dataset.dataset_id
}

output "bigquery_table_id" {
  description = "The ID of the created BigQuery table."
  value       = google_bigquery_table.bq_table.table_id
}
