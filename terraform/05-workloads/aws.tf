resource "helm_release" "aws-consul" {
  depends_on = [consul_config_entry.proxy_defaults, null_resource.kube_dns]

  provider = helm.aws

  name  = "frontend-demo"
  chart = "./helm/frontend"

}
