#!/bin/bash

### Install the nginx ingress controller
if ! kubectl get pods -n ingress-nginx | grep -q ingress-nginx-controller; then
  CURRENT_CONTEXT=$(kubectl config current-context)
  if [[ "$CURRENT_CONTEXT" == *minikube* ]]; then
    echo "Your K8S cluster is minikube. Enabling the ingress addon..."
    minikube addons enable ingress
  elif [[ "$CURRENT_CONTEXT" == *kind* ]]; then
    echo "Your K8S cluster is kind. Using kubectl to install the ingress..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
  else
    echo "Your K8S cluster is $CURRENT_CONTEXT. Using helm charts to install the ingress..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    if ! helm list -n ingress-nginx | grep -q ingress-nginx; then
      if ! kubectl get namespace ingress-nginx >/dev/null 2>&1; then
        kubectl create namespace ingress-nginx
      fi
      helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx
    fi
  fi
fi

echo "Waiting for nginx ingress controller to be ready..."
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx

### Create the RDI namespace if it doesn't exist
if ! kubectl get namespace rdi >/dev/null 2>&1; then
	kubectl create namespace rdi
fi

### Create the Redis database
terraform init
terraform apply -auto-approve

### Deploy RDI with the custom values file
URL="https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-1.14.0.tgz"
HELM_CHART_FILE="rdi-1.14.0.tgz"
if [ ! -f "$HELM_CHART_FILE" ]; then
  curl -L "$URL" -o "$HELM_CHART_FILE"
fi

RDI_DATABASE_HOST=$(terraform output -raw rdi_database_host)
RDI_DATABASE_PORT=$(terraform output -raw rdi_database_port)
RDI_DATABASE_PASSWORD=$(grep "rdi_database_password" terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
JWT_KEY=$(head -c 32 /dev/urandom | base64)

cat > rdi-values.yaml <<EOF
connection:
  host: "$RDI_DATABASE_HOST"
  port: "$RDI_DATABASE_PORT"
  password: "$RDI_DATABASE_PASSWORD"

api:
  jwtKey: "$JWT_KEY"

ingress:
  enabled: true
  className: "nginx"
EOF

helm upgrade --install rdi "$HELM_CHART_FILE" -f rdi-values.yaml -n rdi
