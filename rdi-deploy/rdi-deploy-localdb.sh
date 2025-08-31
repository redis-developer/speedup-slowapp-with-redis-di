#!/bin/bash

### Install the nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
if ! helm list -n ingress-nginx | grep -q ingress-nginx; then
  if ! kubectl get namespace ingress-nginx >/dev/null 2>&1; then
    kubectl create namespace ingress-nginx
  fi
  helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx
fi

echo "Waiting for nginx ingress controller to be ready..."
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx

### Create the RDI namespace if it doesn't exist
if ! kubectl get namespace rdi >/dev/null 2>&1; then
	kubectl create namespace rdi
fi

### Create the Redis database
RE_LASTEST_VERSION=`curl --silent https://api.github.com/repos/RedisLabs/redis-enterprise-k8s-docs/releases/latest | grep tag_name | awk -F'"' '{print $4}'`
kubectl apply -f https://raw.githubusercontent.com/RedisLabs/redis-enterprise-k8s-docs/$RE_LASTEST_VERSION/bundle.yaml -n rdi

kubectl apply -f rdi-rec.yaml -n rdi

# Wait for any pod with prefix redis-enterprise-cluster to be created
echo "Waiting for a pod with prefix redis-enterprise-cluster to be created..."
for i in {1..60}; do
  POD_NAME=$(kubectl get pods -n rdi --no-headers -o custom-columns=:metadata.name | grep '^redis-enterprise-cluster' | head -n 1)
  if [ -n "$POD_NAME" ]; then
    echo "Pod $POD_NAME is created."
    break
  fi
  sleep 5
done

if [ -z "$POD_NAME" ]; then
  echo "Error: No pod with prefix redis-enterprise-cluster was created."
  exit 1
fi

kubectl apply -f rdi-db.yaml -n rdi

echo "Waiting for RDI database to be active..."
for i in {1..60}; do
  STATUS=$(kubectl get redb rdidb -o jsonpath="{.status.status}" -n rdi 2>/dev/null)
  if [ "$STATUS" == "active" ]; then
    echo "RDI database is active."
    break
  fi
  sleep 5
done

if [ "$STATUS" != "active" ]; then
  echo "Error: RDI database did not become active."
  exit 1
fi

### Deploy RDI with the custom values file
URL="https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-1.14.0.tgz"
HELM_CHART_FILE="rdi-1.14.0.tgz"
if [ ! -f "$HELM_CHART_FILE" ]; then
  curl -L "$URL" -o "$HELM_CHART_FILE"
fi

RDI_DATABASE_HOST="rdidb.rdi.svc.cluster.local"
RDI_DATABASE_PORT=$(kubectl get secret redb-rdidb -o jsonpath="{.data.port}" -n rdi | base64 --decode)
RDI_DATABASE_PASSWORD=$(kubectl get secret redb-rdidb -o jsonpath="{.data.password}" -n rdi | base64 --decode)
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
