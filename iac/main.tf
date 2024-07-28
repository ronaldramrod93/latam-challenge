resource "google_pubsub_topic" "pubsub_topic" {
  name    = var.pubsub_topic_name
  project = var.project_id

  labels  = var.labels
}

resource "google_bigquery_dataset" "bq_dataset" {
  dataset_id = var.bigquery_dataset_name
  project = var.project_id

  location   = var.region

  labels = var.labels
}

resource "google_bigquery_table" "bq_table" {
  depends_on = [ google_bigquery_dataset.bq_dataset ]

  dataset_id = google_bigquery_dataset.bq_dataset.dataset_id
  table_id   = var.bigquery_table_name
  project    = var.project_id

  schema     = file("schema.json")

  labels     = var.labels
}

resource "google_pubsub_subscription" "pubsub_subscription" {
  depends_on = [ 
    google_pubsub_topic.pubsub_topic,
    google_bigquery_table.bq_table
  ]

  name  = var.pubsub_subscription_name
  topic = google_pubsub_topic.pubsub_topic.id
  project = var.project_id

  ack_deadline_seconds = var.pubsub_subscription_ack_deadline
  message_retention_duration = "${var.pubsub_subscription_retention_duration}s"

  bigquery_config {
    table             = "${var.project_id}.${google_bigquery_dataset.bq_dataset.dataset_id}.${google_bigquery_table.bq_table.table_id}"
    use_table_schema  = true
  }

  labels = var.labels
}