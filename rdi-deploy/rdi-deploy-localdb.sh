#!/bin/bash

### Install the nginx ingress controller
if ! kubectl get pods -n ingress-nginx | grep -q ingress-nginx-controller; then
  CURRENT_CONTEXT=$(kubectl config current-context)
  if [[ "$CURRENT_CONTEXT" == "minikube" ]]; then
    echo "Your K8S cluster is minikube. Enabling the ingress addon..."
    minikube addons enable ingress
  else
    echo "Your K8S cluster is something else: $CURRENT_CONTEXT. Using helm charts to install..."
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
RE_LASTEST_VERSION=`curl --silent https://api.github.com/repos/RedisLabs/redis-enterprise-k8s-docs/releases/latest | grep tag_name | awk -F'"' '{print $4}'`
kubectl apply -f https://raw.githubusercontent.com/RedisLabs/redis-enterprise-k8s-docs/$RE_LASTEST_VERSION/bundle.yaml -n rdi

echo "Waiting for Redis Enterprise operator to be ready..."
for i in {1..60}; do
  STATUS=$(kubectl get deployment redis-enterprise-operator -n rdi -o jsonpath="{.status.readyReplicas}" 2>/dev/null)
  if [ "$STATUS" == "1" ]; then
    echo "Redis Enterprise operator is ready."
    break
  fi
  sleep 5
done

if [ "$STATUS" != "1" ]; then
  echo "Error: Redis Enterprise operator did not become ready."
  exit 1
fi

kubectl apply -f rdi-rec.yaml -n rdi
CLUSTER_NAME=$(grep '^  name:' rdi-rec.yaml | awk '{print $2}')
NUM_NODES=$(grep '^  nodes:' rdi-rec.yaml | awk '{print $2}')

echo "Waiting for $NUM_NODES pods from Redis Enterprise Cluster to be running..."

for attempt in {1..60}; do
  READY_COUNT=0
  for i in $(seq 0 $(($NUM_NODES-1))); do
    POD="${CLUSTER_NAME}-${i}"
    STATUS=$(kubectl get pod "$POD" -n rdi --no-headers 2>/dev/null | awk '{print $3}')
    if [ "$STATUS" = "Running" ]; then
      READY_COUNT=$((READY_COUNT+1))
    fi
  done

  if [ "$READY_COUNT" -eq "$NUM_NODES" ]; then
    echo "All $NUM_NODES pods from Redis Enterprise Cluster are running."
    break
  fi

  echo "Currently $READY_COUNT/$NUM_NODES pods from Redis Enterprise Cluster are running. Retrying in 5s..."
  sleep 5
done

if [ "$READY_COUNT" -ne "$NUM_NODES" ]; then
  echo "Error: Not all pods from Redis Enterprise Cluster are running after waiting."
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
