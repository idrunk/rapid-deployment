# Create token for kubernetes service discovery
``` bash
kubectl create ns devops
kubectl create sa prometheus -n devops
kubectl create clusterrolebinding prometheus --clusterrole cluster-admin --serviceaccount=devops:prometheus

kubectl create token prometheus -n devops -o yaml --duration=8760h

curl --insecure https://127.0.0.1:10250/metrics -H "Authorization: Bearer {}"
```