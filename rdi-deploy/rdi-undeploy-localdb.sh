#!/bin/bash

### Undeploy RDI
rm -f rdi-values.yaml
kubectl delete pipeline default -n rdi
helm uninstall rdi -n rdi

### Destroy the Redis database
kubectl delete -f rdi-db.yaml -n rdi
kubectl delete -f rdi-rec.yaml -n rdi

### Uninstall the ingress controller
CURRENT_CONTEXT=$(kubectl config current-context)
if [[ "$CURRENT_CONTEXT" == *minikube* ]]; then
	echo "Your K8S cluster is minikube. Disabling the ingress addon..."
	minikube addons disable ingress
elif [[ "$CURRENT_CONTEXT" == *kind* ]]; then
	echo "Your K8S cluster is kind. Using kubectl to uninstall the ingress..."
	kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
else
	echo "Your K8S cluster is $CURRENT_CONTEXT. Using helm charts to uninstall the ingress..."
	helm uninstall ingress-nginx --namespace ingress-nginx
fi

echo "Waiting for ingress-nginx-controller deployment to be deleted..."
while kubectl get deployment ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; do
	sleep 2
done

# Only delete the namespace when everything is done
if kubectl get namespace rdi >/dev/null 2>&1; then
	kubectl delete namespace rdi
fi
