resource "consul_config_entry" "proxy_defaults" {
  kind = "proxy-defaults"
  name = "global"

  config_json = jsonencode({
    Config = {
      protocol                         = "http"
      envoy_extra_static_clusters_json = <<EOL
    {
      "connect_timeout": "3.000s",
      "dns_lookup_family": "V4_ONLY",
      "lb_policy": "ROUND_ROBIN",
      "load_assignment": {
          "cluster_name": "jaeger_9411",
          "endpoints": [
              {
                  "lb_endpoints": [
                      {
                          "endpoint": {
                              "address": {
                                  "socket_address": {
                                      "address": "jaeger.service.aws-us-east-1.consul",
                                      "port_value": 9411,
                                      "protocol": "TCP"
                                  }
                              }
                          }
                      }
                  ]
              }
          ]
      },
      "name": "jaeger_9411",
      "type": "STRICT_DNS"
    }
    EOL
      envoy_tracing_json               = <<EOL
    {
      "http": {
        "name": "envoy.zipkin",
        "config": {
          "collector_cluster": "jaeger_9411",
          "collector_endpoint": "/api/v1/spans",
          "shared_span_context": false
        }
      }
    }
    EOL
    }
  })
}

resource "null_resource" "kube_dns" {

  provisioner "local-exec" {
    command     = "./kube.sh"
    working_dir = "${path.module}/scripts"
  }
}
