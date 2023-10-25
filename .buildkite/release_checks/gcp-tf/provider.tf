provider "google" {
  credentials = file("sa.json")
  project     = var.project_id
}
