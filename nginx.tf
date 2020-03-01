data "google_client_config" "current" {}

provider "kubernetes" {
  load_config_file       = false
  host                   = "https://${google_container_cluster.cluster.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "nginx-ingress"
  }
}

provider "helm" {
  kubernetes {
    load_config_file       = false
    host                   = "https://${google_container_cluster.cluster.endpoint}"
    cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)
    token                  = data.google_client_config.current.access_token
  }
}

data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}

resource "helm_release" "nginx_ingress" {
  name          = "nginx-ingress"
  repository    = data.helm_repository.stable.metadata[0].name
  chart         = "stable/nginx-ingress"
  namespace     = kubernetes_namespace.nginx_ingress.id

  values = [
    file("${path.module}/values.yaml"),
  ]
}