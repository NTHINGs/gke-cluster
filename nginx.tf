provider "kubernetes" {
  host = google_container_cluster.cluster.endpoint

  client_certificate     = google_container_cluster.cluster.master_auth.0.client_certificate
  client_key             = google_container_cluster.cluster.master_auth.0.client_key
  #cluster_ca_certificate = google_container_cluster.cluster.master_auth.0.cluster_ca_certificate
  insecure = true
}

resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "nginx-ingress"
  }
}

provider "helm" {
  kubernetes {
    host = google_container_cluster.cluster.endpoint

    client_certificate     = google_container_cluster.cluster.master_auth.0.client_certificate
    client_key             = google_container_cluster.cluster.master_auth.0.client_key
    #cluster_ca_certificate = google_container_cluster.cluster.master_auth.0.cluster_ca_certificate
  }
  insecure = true
}

resource "helm_release" "nginx_ingress" {
  name  = "nginx-ingress"
  chart = "stable/nginx-ingress"

  namespace = kubernetes_namespace.nginx_ingress.id
}