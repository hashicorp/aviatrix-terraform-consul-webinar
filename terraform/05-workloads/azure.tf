resource "helm_release" "azure-consul" {
  depends_on = [consul_config_entry.proxy_defaults, null_resource.kube_dns]

  provider = helm.azure

  name  = "backend-demo"
  chart = "./helm/backend"

}
