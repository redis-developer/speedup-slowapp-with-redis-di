#!/bin/bash

### Undeploy RDI
rm -f rdi-values.yaml
kubectl delete pipeline default -n rdi
helm uninstall rdi -n rdi

### Destroy the Redis database
kubectl delete -f rdi-db.yaml -n rdi
kubectl delete -f rdi-rec.yaml -n rdi

### Uninstall the ingress controller
helm uninstall ingress-nginx --namespace ingress-nginx

echo "Waiting for ingress-nginx-controller deployment to be deleted..."
while kubectl get deployment ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; do
	sleep 2
done

# Only delete the namespace when everything is done
if kubectl get namespace rdi >/dev/null 2>&1; then
	kubectl delete namespace rdi
fi
