#!/bin/bash

### Undeploy RDI
rm -f rdi-values.yaml
kubectl delete pipeline default -n rdi
helm uninstall rdi -n rdi

### Destroy the Redis database
terraform destroy -auto-approve

### Uninstall the ingress controller
CURRENT_CONTEXT=$(kubectl config current-context)
if [[ "$CURRENT_CONTEXT" == "minikube" ]]; then
	echo "Your K8S cluster is minikube. Disabling the ingress addon..."
	minikube addons disable ingress
else
	echo "Your K8S cluster is something else: $CURRENT_CONTEXT. Using helm charts to uninstall..."
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
