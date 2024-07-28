terraform {
    backend "gcs" {
        bucket  = "tf-state-dev-430003"
        prefix  = "terraform/challenge-latam"
    }
}