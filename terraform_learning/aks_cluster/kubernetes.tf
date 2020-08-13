terraform {
    required_providers {
        kubernetes = {
            source = "hashicorp/kubernetes"
        }
    }
}

provider "kubernetes" {
  load_config_file = false

  host     = azurerm_kubernetes_cluster.default.kube_config.0.host
  username = azurerm_kubernetes_cluster.default.kube_config.0.username
  password = azurerm_kubernetes_cluster.default.kube_config.0.password

  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)}"
}

resource "kubernetes_deployment" "nginx" {
    metadata {
        name = "scalable-nginx-example"
        labels = {
            App = "ScalableNginxExample"
        }
    }

    spec {
        replicas = 4
        selector {
            match_labels = {
                App = "ScalableNginxExample"
            }
        }
        template {
            metadata {
                labels = {
                    App = "ScalableNginxExample"
                }
            }
            spec {
                container {
                    image = "nginx:latest"
                    name = "nginx"

                    port {
                        container_port = 80
                    }

                    resources {
                        limits {
                            cpu    = "0.5"
                            memory = "512Mi"
                        }
                        requests {
                            cpu    = "250m"
                            memory = "50Mi"
                        }
                    }
                }
            }
        }
    }
}

resource "kubernetes_service" "nginx" {
    metadata {
        name = "nginx-service"
    }

    spec {
        selector = {
            App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
        }
        port {
            port        = 80
            target_port = 80
        }

        type = "LoadBalancer"
    }
}

output "lb_ip" {
    value = kubernetes_service.nginx.load_balancer_ingress[0].ip
}