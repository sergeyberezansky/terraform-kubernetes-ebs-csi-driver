resource "kubernetes_daemonset" "node" {
  metadata {
    name      = local.daemonset_name
    namespace = var.namespace
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["field.cattle.io/publicEndpoints"],
    ]
  }

  spec {
    selector {
      match_labels = {
        app = local.daemonset_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.daemonset_name
        }
      }

      spec {
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "eks.amazonaws.com/compute-type"
                  operator = "NotIn"
                  values   = ["fargate"]
                }
              }
            }
          }
        }

        node_selector = merge({
          "beta.kubernetes.io/os" : "linux",
        }, var.extra_node_selectors, var.node_extra_node_selectors)

        host_network        = true
        priority_class_name = "system-cluster-critical"

        toleration {
          operator = "Exists"
        }

        dynamic "toleration" {
          for_each = var.node_tolerations
          content {
            key                = lookup(toleration.value, "key", null)
            operator           = lookup(toleration.value, "operator", null)
            effect             = lookup(toleration.value, "effect", null)
            value              = lookup(toleration.value, "value", null)
            toleration_seconds = lookup(toleration.value, "toleration_seconds", null)
          }
        }

        container {
          name  = "ebs-plugin"
          image = "${var.ebs_csi_controller_image == "" ? "amazon/aws-ebs-csi-driver" : var.ebs_csi_controller_image}:${local.ebs_csi_driver_version}"
          args = [
            "node",
            "--endpoint=$(CSI_ENDPOINT)",
            "--logtostderr",
            "--v=5"
          ]

          security_context {
            privileged = true
          }

          env {
            name  = "CSI_ENDPOINT"
            value = "unix:/csi/csi.sock"
          }

          volume_mount {
            mount_path        = "/var/lib/kubelet"
            name              = "kubelet-dir"
            mount_propagation = "Bidirectional"
          }

          volume_mount {
            mount_path = "/csi"
            name       = "plugin-dir"
          }

          volume_mount {
            name       = "device-dir"
            mount_path = "/dev"
          }

          port {
            name           = "healthz"
            container_port = 9808
            host_port      = 9808
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "healthz"
            }

            initial_delay_seconds = 10
            timeout_seconds       = 3
            period_seconds        = 10
            failure_threshold     = 5
          }
        }

        container {
          name  = "node-driver-registrar"
          image = "quay.io/k8scsi/csi-node-driver-registrar:v2.1.0"
          args = [
            "--csi-address=$(ADDRESS)",
            "--kubelet-registration-path=$(DRIVER_REG_SOCK_PATH)",
            "--v=5"
          ]

          lifecycle {
            pre_stop {
              exec {
                command = ["/bin/sh", "-c", "rm -rf /registration/ebs.csi.aws.com-reg.sock /csi/csi.sock"]
              }
            }
          }

          env {
            name  = "ADDRESS"
            value = "/csi/csi.sock"
          }

          env {
            name  = "DRIVER_REG_SOCK_PATH"
            value = "/var/lib/kubelet/plugins/ebs.csi.aws.com/csi.sock"
          }

          volume_mount {
            mount_path = "/csi"
            name       = "plugin-dir"
          }

          volume_mount {
            mount_path = "/registration"
            name       = "registration-dir"
          }
        }

        container {
          name  = "liveness-probe"
          image = "quay.io/k8scsi/livenessprobe:${local.liveness_probe_version}"
          args = [
            "--csi-address=/csi/csi.sock"
          ]

          volume_mount {
            mount_path = "/csi"
            name       = "plugin-dir"
          }
        }

        volume {
          name = "kubelet-dir"

          host_path {
            path = "/var/lib/kubelet"
            type = "Directory"
          }
        }

        volume {
          name = "plugin-dir"

          host_path {
            path = "/var/lib/kubelet/plugins/ebs.csi.aws.com/"
            type = "DirectoryOrCreate"
          }
        }

        volume {
          name = "registration-dir"

          host_path {
            path = "/var/lib/kubelet/plugins_registry/"
            type = "Directory"
          }
        }

        volume {
          name = "device-dir"

          host_path {
            path = "/dev"
            type = "Directory"
          }
        }
      }
    }
  }
}