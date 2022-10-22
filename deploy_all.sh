#!/usr/bin/env sh
set -e

usage() {
  echo "Usage: $0 <method>"
  echo " e.g.: $0 docker_build"
  echo " "
  echo "<method> = k8s_cluster|csi_driver|metric_server|docker_build|docker_push|nginx_ingress|spring_api|logging|monitoring|flask_api"
  exit 1
}

if [ -z "$1" ];then
  usage
elif
  [ "$1" != "k8s_cluster" ] && [ "$1" != "csi_driver" ] && [ "$1" != "metric_server" ] && [ "$1" != "docker_build" ] && [ "$1" != "docker_push" ] && [ "$1" != "nginx_ingress" ] && [ "$1" != "spring_api" ] && [ "$1" != "jenkins_deployment" ] && [ "$1" != "logging" ] && [ "$1" != "monitoring" ] && [ "$1" != "flask_api" ];then
    printf "Please choose correct method, it should be k8s_cluster|csi_driver|metric_server|docker_build|docker_push|logging|monitoring|flask_api"
    usage
  exit 1
fi

k8s_cluster(){

  eksctl create cluster -f ./kubernetes/eks.yaml

}

csi_driver(){

  #ebs csi driver is mandotary for this case. Because it will provide automatic creation for ebs disks in the AWS.
  kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.12"

}

metric_server(){
  
  #metric server provides to see more efficient metrics for pods, nodes.
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

}

docker_build(){

  docker build -t halil9/flask-api:v3 ./flask-api

}

docker_push(){

  docker push halil9/flask-api:v3

}

nginx_ingress(){

  #helm repo add nginx-stable https://helm.nginx.com/stable
  #helm repo update
  helm upgrade --install --create-namespace --namespace ingress-nginx ingress-nginx bitnami/nginx-ingress-controller -f ./kubernetes/nginx_values.yaml

}

logging(){

  #helm repo add elastic https://helm.elastic.co
  #helm repo update
  helm upgrade --install --create-namespace --namespace logging elasticsearch bitnami/elasticsearch -f ./kubernetes/elastic_values.yaml

  #fluentd installation to aggragete logs
  helm upgrade --install --create-namespace --namespace logging fluentd fluent/fluentd -f ./kubernetes/fluentd_values.yaml

}

monitoring() {

  #helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 
  #helm repo update
  helm upgrade --install --create-namespace --namespace monitoring monitoring-stack prometheus-community/kube-prometheus-stack -f ./kubernetes/kube_prometheus.yaml

}

flask_api(){

  helm upgrade --install --create-namespace --namespace flask-api flask-api ./kubernetes/flask-api
  
}

$1
