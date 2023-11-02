resource "google_container_cluster" "primary" {
  name                     = var.cluster_name
  project                  = var.project_id
  location                 = "us-central1-a"
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false
}

resource "google_project_iam_member" "gcr_viewer" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.default.email}"
}

resource "google_service_account" "default" {
  account_id   = "sa-${var.cluster_name}"
  display_name = "Service Account for ${var.cluster_name}"
  project      = var.project_id
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name     = "np-${var.cluster_name}"
  location = "us-central1-a"
  project  = var.project_id
  cluster  = google_container_cluster.primary.name

  autoscaling {
    min_node_count = 1
    max_node_count = 15
  }

  node_config {
    preemptible  = true
    machine_type = "n2-standard-2"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

}

output "kubeconfig" {
  value     = <<EOT
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}
    server: https://${google_container_cluster.primary.endpoint}
  name: ${var.cluster_name}
contexts:
- context:
    cluster: ${var.cluster_name}
    user: ${var.cluster_name}
  name: ${var.cluster_name}
current-context: ${var.cluster_name}
kind: Config
preferences: {}
users:
- name: ${var.cluster_name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: gke-gcloud-auth-plugin
      args:
      - get-token
      - --project=${var.project_id}
      - --cluster=${google_container_cluster.primary.name}
EOT
  sensitive = true
}

