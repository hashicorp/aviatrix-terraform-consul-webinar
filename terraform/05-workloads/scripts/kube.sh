#Azure
export KUBECONFIG=../../01-infra/kube_config/kubeconfig_aws

kubectl set env daemonset -n kube-system aws-node AWS_VPC_K8S_CNI_EXTERNALSNAT=true
CONSUL_DNS_IP=$(kubectl get svc hashicorp-consul-dns -o jsonpath='{.spec.clusterIP}')
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          upstream
          fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
    consul {
      errors
      cache 30
      forward . ${CONSUL_DNS_IP}
    }
EOF
kubectl delete pod --namespace kube-system -l k8s-app=kube-dns

#AWS
export KUBECONFIG=../../01-infra/kube_config/kubeconfig_azure

CONSUL_DNS_IP=$(kubectl get svc hashicorp-consul-dns -o jsonpath='{.spec.clusterIP}')
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  consul.server: |
    consul {
           errors
           cache 30
           forward . $CONSUL_DNS_IP
    }
EOF
kubectl delete pod --namespace kube-system -l k8s-app=kube-dns
