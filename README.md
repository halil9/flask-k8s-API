# flask Flask API

## Directory Structure

``` sh
.
├── README.md
├── deploy_all.sh
├── flask-api
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── grafana
│   └── dashboards
│       └── dashboard.json
└── kubernetes
    ├── flask-api
    │   ├── Chart.yaml
    │   ├── charts
    │   ├── templates
    │   │   ├── NOTES.txt
    │   │   ├── _helpers.tpl
    │   │   ├── deployment.yaml
    │   │   ├── hpa.yaml
    │   │   ├── ingress.yaml
    │   │   ├── service-monitor.yaml
    │   │   ├── service.yaml
    │   │   ├── serviceaccount.yaml
    │   │   └── tests
    │   │       └── test-connection.yaml
    │   └── values.yaml
    ├── eks.yaml
    ├── elastic_values.yaml
    ├── fluentd_values.yaml
    ├── kube_prometheus.yaml
    └── nginx_values.yaml
``` 

## flask API

A small example 

The flask API shows timestamp and hostname. Also you can see all endpoints below;

- /timestamp/ --> it has timestamp
- /hostname/ --> it has hostname
- /health/ --> it has healthy status for API
- /metrics --> it has default prometheus metrics for API

You can run with `python3` in your local with the following command;

``` sh
cd flask-api
python3 app.py
```

`NOTE: You can use released URL to requests after the deployment for k8s; https://flask.importante.info`

## Deployments

### Docker Build and Push

You can run `flask api` with prepared `multistage Dockerfile` in the root directory. 

`MacOsX`

``` sh
docker buildx build --platform linux/amd64 -t <repository:tag> -f Dockerfile .
```

`Linux and Macos and Other Platforms`

``` sh
docker build -t <repository:tag> -f Dockerfile .
```

Also, you can use the bash script prepared for the automation of deployment in the root path.

``` sh
chmod +x all_deploy.sh
./all_deploy.sh docker_build
```
and then you can push the repository;

``` sh
chmod +x all_deploy.sh
./all_deploy.sh docker_push
```

`or`

``` sh
docker push <repository:tag>
```

### K8s Cluster Creation and Component Deployments

### Requirements

- Kubernetes Cluster (eks kind etc.)
- Helm3
- eksctl
- kubectl

We've already dockerized API. So it is ready for Kubernetes.

`First Step`; We need to create a kubernetes cluster for the API deployments and other components.

We can perefer `eks` for creation of k8s cluster step. I have prepared a config yaml file to create an eks cluster. you can see the config file in the `kubernetes/eks.yaml` directory.

I used `eksctl` to create the cluster. Also I have prepared bash script provision to cluster and other components. You can use following command to provision cluster.

``` sh
./deploy_all.sh k8s_cluster
```

This command creates cluster and node groups for us. After the setup was completed successfully, also you have to deploy `ebs-csi-driver` to provision automaticly ebs disks in the AWS. You can deploy following command.

``` sh
./deploy_all csi_driver
```
and also, you have to add `AmazonEBSCSIDriverPolicy` to your EKS NodeInstance Role.

and then you have to install `metric-server` for HPA.

``` sh
./deploy_all metric_server
```

`NOTE: If you want to use kind, You can use this config file to provision a cluster below.`

```YAML
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
```
Also for the nginx ingress side, You have to pass your domain address to the your `/etc/hosts` file in your local.

### Flask API Kubernetes Deployment

We can start to deploy our API in kubernetes cluster.

`NOTE: The cluster version is 1.23, So You have to use compatible version of kubectl client.`

`Second Step`; I used helm package provider to deploy flask api and other components in kubernetes cluster. You can see all helm files for flask-api in the `kubernetes/flask-api` directory.

Also, I mentioned the k8s cluster create part above. You can use `deploy_all.sh` to deploy all components.

``` sh
./deploy_all flask_api
```

### Logging, Monitoring, ingress-nginx Components Deployment

Also I have prepared components to provide;

- logging(elasticsearch,kibana,fluentd)
- monitoring(kube-prometheus-stack)
- LoadBalancing(ingress-nginx)

with their offical helmcharts in the cluster.

On this site, You can see all helm values files for dependencies in `kubernetes/` directory.

You can deploy components with `./deploy_all.sh` script.

``` sh
./deploy_all.sh <component_name>
```

After all deployment steps complated successfully, You can see monitoring and logging side following links;

- [kibana.importante.info]
- [grafana.importante.info]
- [flask.importante.info]

and you can see more information for components below;

### Nginx Ingress SSL Termination

In the ingress nginx side, I created ssl certificate in ACM AWS for the ingress nginx ssl termination. Also I've created route 53 hosted zome and record for components domains with the CNAME of nginx ingress LoadBalancer. Those steps creted manually in AWS UI.

### Monitoring

I've used prometheus-stack helm chart to provide monitoring in the cluster. This chart contains grafana, prometheus and alertmanager tools. In the grafana side it has dashboards about cluster metrics and I've added API metrics dashboard in the `kubernetes/grafana/dashboards` directory.

### Logging

I've used elasticsearch and kibana helmchart for logging. Also I used fluentd helmchart to aggregate cluster logs.

For the logs agregation, Just you can pass `ElASTIC_HOST and ELASTIC_PORT` envs in the fluentd `kubernetes/fluentd_values.yaml` like this;

```sh
env:
- name: FLUENT_ELASTICSEARCH_HOST
  value: "elasticsearch"
- name: FLUENT_ELASTICSEARCH_PORT
  value: "9200"
```
Also you have to define output.conf;

```sh
  04_outputs.conf: |-
    <label @OUTPUT>
      <match **>
        @type elasticsearch
        include_tag_key true
        host "elasticsearch"
        port 9200
        logstash_format true
      </match>
    </label>
```
for the logs aggregation to elasticsearch.


## Continuous Integration with Github Actions

I've created github actions yml for `python code security checks`, `build docker image` and `image vulnerability checks` stages that you can see in the `.github/workflows/gthub-actions.yml`

[kibana.importante.info]: https://kibana.importante.info
[grafana.importante.info]: https://grafana.importante.info
[flask.importante.info]: https://flask.importante.info
