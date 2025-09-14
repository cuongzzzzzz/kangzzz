# Kubernetes Cheatsheet - Hướng Dẫn Lệnh Chi Tiết

## 📋 Mục Lục
1. [Cài đặt và Cấu hình](#cài-đặt-và-cấu-hình)
2. [Cluster Management](#cluster-management)
3. [Pod Operations](#pod-operations)
4. [Deployment Operations](#deployment-operations)
5. [Service Operations](#service-operations)
6. [ConfigMap & Secret](#configmap--secret)
7. [Namespace Operations](#namespace-operations)
8. [Node Management](#node-management)
9. [Debugging & Troubleshooting](#debugging--troubleshooting)
10. [Monitoring & Logs](#monitoring--logs)
11. [Security & RBAC](#security--rbac)
12. [Storage Operations](#storage-operations)
13. [Network Operations](#network-operations)
14. [Advanced Operations](#advanced-operations)

---

## 🚀 Cài đặt và Cấu hình

### Cài đặt kubectl
```bash
# Cài đặt kubectl trên Ubuntu/Debian
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Cài đặt kubectl trên macOS
brew install kubectl

# Cài đặt kubectl trên Windows
choco install kubernetes-cli
```

### Cấu hình kubeconfig
```bash
# Xem cấu hình hiện tại
kubectl config view

# Xem context hiện tại
kubectl config current-context

# Chuyển đổi context
kubectl config use-context <context-name>

# Thêm cluster mới
kubectl config set-cluster <cluster-name> --server=https://<server-ip>:6443

# Thêm user mới
kubectl config set-credentials <user-name> --token=<token>

# Tạo context mới
kubectl config set-context <context-name> --cluster=<cluster-name> --user=<user-name>
```

---

## 🏗️ Cluster Management

### Thông tin cluster
```bash
# Xem thông tin cluster
kubectl cluster-info

# Xem version của cluster và client
kubectl version

# Xem thông tin chi tiết về cluster
kubectl cluster-info dump

# Kiểm tra kết nối đến cluster
kubectl get nodes
```

### Quản lý cluster
```bash
# Xem tất cả resources trong cluster
kubectl api-resources

# Xem API versions
kubectl api-versions

# Xem thông tin về API groups
kubectl get --raw /api/v1

# Kiểm tra health của cluster
kubectl get --raw /healthz
```

---

## 🐳 Pod Operations

### Tạo và quản lý Pod
```bash
# Tạo pod từ file YAML
kubectl create -f pod.yaml

# Tạo pod từ command line
kubectl run nginx-pod --image=nginx --port=80

# Tạo pod với environment variables
kubectl run my-pod --image=nginx --env="KEY1=value1" --env="KEY2=value2"

# Tạo pod với resource limits
kubectl run my-pod --image=nginx --limits="cpu=200m,memory=256Mi" --requests="cpu=100m,memory=128Mi"
```

### Xem thông tin Pod
```bash
# Liệt kê tất cả pods
kubectl get pods

# Liệt kê pods với thông tin chi tiết
kubectl get pods -o wide

# Xem pods trong namespace cụ thể
kubectl get pods -n <namespace>

# Xem pods trên tất cả namespaces
kubectl get pods --all-namespaces

# Xem thông tin chi tiết về pod
kubectl describe pod <pod-name>

# Xem logs của pod
kubectl logs <pod-name>

# Xem logs của container cụ thể trong pod
kubectl logs <pod-name> -c <container-name>

# Xem logs real-time (follow)
kubectl logs -f <pod-name>

# Xem logs với timestamp
kubectl logs <pod-name> --timestamps=true
```

### Thao tác với Pod
```bash
# Xóa pod
kubectl delete pod <pod-name>

# Xóa pod với force
kubectl delete pod <pod-name> --force --grace-period=0

# Xóa tất cả pods
kubectl delete pods --all

# Exec vào pod
kubectl exec -it <pod-name> -- /bin/bash

# Exec vào container cụ thể
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash

# Copy file từ pod ra ngoài
kubectl cp <pod-name>:/path/to/file ./local-file

# Copy file từ ngoài vào pod
kubectl cp ./local-file <pod-name>:/path/to/file

# Port forward
kubectl port-forward <pod-name> 8080:80

# Attach vào pod
kubectl attach <pod-name>
```

---

## 🚀 Deployment Operations

### Tạo và quản lý Deployment
```bash
# Tạo deployment từ file YAML
kubectl create -f deployment.yaml

# Tạo deployment từ command line
kubectl create deployment nginx-deployment --image=nginx --replicas=3

# Tạo deployment với port
kubectl create deployment nginx-deployment --image=nginx --port=80

# Tạo deployment với environment variables
kubectl create deployment my-app --image=my-app --env="ENV=production"
```

### Xem thông tin Deployment
```bash
# Liệt kê deployments
kubectl get deployments

# Xem thông tin chi tiết về deployment
kubectl describe deployment <deployment-name>

# Xem pods của deployment
kubectl get pods -l app=<deployment-name>

# Xem replica sets
kubectl get rs

# Xem history của deployment
kubectl rollout history deployment/<deployment-name>

# Xem chi tiết revision cụ thể
kubectl rollout history deployment/<deployment-name> --revision=2
```

### Cập nhật và Rollback
```bash
# Cập nhật image của deployment
kubectl set image deployment/<deployment-name> nginx=nginx:1.16

# Cập nhật deployment từ file YAML
kubectl apply -f deployment.yaml

# Cập nhật deployment với strategy
kubectl patch deployment <deployment-name> -p '{"spec":{"strategy":{"type":"RollingUpdate"}}}'

# Rollout deployment
kubectl rollout restart deployment/<deployment-name>

# Pause rollout
kubectl rollout pause deployment/<deployment-name>

# Resume rollout
kubectl rollout resume deployment/<deployment-name>

# Rollback về revision trước
kubectl rollout undo deployment/<deployment-name>

# Rollback về revision cụ thể
kubectl rollout undo deployment/<deployment-name> --to-revision=2

# Xem status của rollout
kubectl rollout status deployment/<deployment-name>
```

### Scaling
```bash
# Scale deployment
kubectl scale deployment <deployment-name> --replicas=5

# Scale deployment với file YAML
kubectl apply -f deployment.yaml

# Scale deployment với autoscaling
kubectl autoscale deployment <deployment-name> --min=2 --max=10 --cpu-percent=80
```

---

## 🌐 Service Operations

### Tạo và quản lý Service
```bash
# Tạo service từ file YAML
kubectl create -f service.yaml

# Tạo service từ command line
kubectl expose deployment nginx-deployment --port=80 --type=LoadBalancer

# Tạo service với NodePort
kubectl expose deployment nginx-deployment --port=80 --type=NodePort

# Tạo service với ClusterIP
kubectl expose deployment nginx-deployment --port=80 --type=ClusterIP
```

### Xem thông tin Service
```bash
# Liệt kê services
kubectl get services

# Xem thông tin chi tiết về service
kubectl describe service <service-name>

# Xem endpoints của service
kubectl get endpoints <service-name>

# Xem service với thông tin chi tiết
kubectl get services -o wide
```

### Ingress Operations
```bash
# Tạo ingress từ file YAML
kubectl create -f ingress.yaml

# Xem ingresses
kubectl get ingress

# Xem thông tin chi tiết về ingress
kubectl describe ingress <ingress-name>

# Xem ingress classes
kubectl get ingressclass
```

---

## 🔐 ConfigMap & Secret

### ConfigMap Operations
```bash
# Tạo ConfigMap từ file YAML
kubectl create -f configmap.yaml

# Tạo ConfigMap từ command line
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2

# Tạo ConfigMap từ file
kubectl create configmap my-config --from-file=config.properties

# Tạo ConfigMap từ directory
kubectl create configmap my-config --from-file=./config-dir/

# Xem ConfigMaps
kubectl get configmaps

# Xem thông tin chi tiết về ConfigMap
kubectl describe configmap <configmap-name>

# Xem data của ConfigMap
kubectl get configmap <configmap-name> -o yaml

# Xóa ConfigMap
kubectl delete configmap <configmap-name>
```

### Secret Operations
```bash
# Tạo Secret từ file YAML
kubectl create -f secret.yaml

# Tạo Secret từ command line
kubectl create secret generic my-secret --from-literal=username=admin --from-literal=password=secret

# Tạo Secret từ file
kubectl create secret generic my-secret --from-file=username.txt --from-file=password.txt

# Tạo Secret cho Docker registry
kubectl create secret docker-registry my-registry-secret --docker-server=myregistry.com --docker-username=admin --docker-password=secret --docker-email=admin@myregistry.com

# Tạo Secret cho TLS
kubectl create secret tls my-tls-secret --cert=path/to/cert.crt --key=path/to/cert.key

# Xem Secrets
kubectl get secrets

# Xem thông tin chi tiết về Secret
kubectl describe secret <secret-name>

# Xem data của Secret (base64 encoded)
kubectl get secret <secret-name> -o yaml

# Decode Secret data
kubectl get secret <secret-name> -o jsonpath='{.data.password}' | base64 -d

# Xóa Secret
kubectl delete secret <secret-name>
```

---

## 📁 Namespace Operations

### Quản lý Namespace
```bash
# Tạo namespace
kubectl create namespace <namespace-name>

# Tạo namespace từ file YAML
kubectl create -f namespace.yaml

# Xem namespaces
kubectl get namespaces

# Xem thông tin chi tiết về namespace
kubectl describe namespace <namespace-name>

# Xóa namespace
kubectl delete namespace <namespace-name>

# Xem resources trong namespace
kubectl get all -n <namespace-name>

# Chuyển đổi namespace mặc định
kubectl config set-context --current --namespace=<namespace-name>
```

---

## 🖥️ Node Management

### Xem thông tin Node
```bash
# Liệt kê nodes
kubectl get nodes

# Xem thông tin chi tiết về node
kubectl describe node <node-name>

# Xem nodes với thông tin chi tiết
kubectl get nodes -o wide

# Xem tài nguyên của nodes
kubectl top nodes

# Xem pods trên node cụ thể
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node-name>
```

### Quản lý Node
```bash
# Cordon node (ngăn scheduling pods mới)
kubectl cordon <node-name>

# Uncordon node (cho phép scheduling pods mới)
kubectl uncordon <node-name>

# Drain node (di chuyển pods ra khỏi node)
kubectl drain <node-name>

# Drain node với force
kubectl drain <node-name> --force --ignore-daemonsets

# Xem taint của node
kubectl describe node <node-name> | grep Taints

# Thêm taint cho node
kubectl taint nodes <node-name> key=value:NoSchedule

# Xóa taint của node
kubectl taint nodes <node-name> key=value:NoSchedule-
```

---

## 🔍 Debugging & Troubleshooting

### Debugging Pods
```bash
# Xem events của pod
kubectl get events --sort-by=.metadata.creationTimestamp

# Xem events của pod cụ thể
kubectl describe pod <pod-name>

# Xem logs của pod với previous container
kubectl logs <pod-name> --previous

# Xem logs với tail
kubectl logs <pod-name> --tail=100

# Xem logs với since
kubectl logs <pod-name> --since=1h

# Debug pod với ephemeral container
kubectl debug <pod-name> -it --image=busybox --target=<container-name>
```

### Debugging Services
```bash
# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup <service-name>

# Test service với curl
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- curl <service-name>

# Xem endpoints của service
kubectl get endpoints <service-name>

# Test port forwarding
kubectl port-forward service/<service-name> 8080:80
```

### Debugging Network
```bash
# Xem network policies
kubectl get networkpolicies

# Xem thông tin chi tiết về network policy
kubectl describe networkpolicy <network-policy-name>

# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default

# Xem CNI configuration
kubectl get pods -n kube-system | grep -E "(flannel|calico|weave)"
```

---

## 📊 Monitoring & Logs

### Resource Monitoring
```bash
# Xem resource usage của pods
kubectl top pods

# Xem resource usage của nodes
kubectl top nodes

# Xem resource usage trong namespace
kubectl top pods -n <namespace>

# Xem resource usage với labels
kubectl top pods --selector=app=nginx
```

### Log Management
```bash
# Xem logs của tất cả pods trong namespace
kubectl logs -l app=nginx --all-containers=true

# Xem logs với timestamps
kubectl logs <pod-name> --timestamps=true

# Xem logs với since time
kubectl logs <pod-name> --since=2023-01-01T00:00:00Z

# Xem logs với since duration
kubectl logs <pod-name> --since=1h

# Xem logs với tail
kubectl logs <pod-name> --tail=50

# Xem logs với follow
kubectl logs -f <pod-name>
```

### Metrics và Monitoring
```bash
# Xem metrics server
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes

# Xem metrics của pods
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods

# Xem custom resource definitions
kubectl get crd

# Xem custom resources
kubectl get <custom-resource-name>
```

---

## 🔒 Security & RBAC

### Service Account Operations
```bash
# Tạo service account
kubectl create serviceaccount <service-account-name>

# Xem service accounts
kubectl get serviceaccounts

# Xem thông tin chi tiết về service account
kubectl describe serviceaccount <service-account-name>

# Xóa service account
kubectl delete serviceaccount <service-account-name>
```

### RBAC Operations
```bash
# Xem roles
kubectl get roles

# Xem cluster roles
kubectl get clusterroles

# Xem role bindings
kubectl get rolebindings

# Xem cluster role bindings
kubectl get clusterrolebindings

# Xem thông tin chi tiết về role
kubectl describe role <role-name>

# Xem thông tin chi tiết về role binding
kubectl describe rolebinding <role-binding-name>
```

### Security Context
```bash
# Xem security context của pod
kubectl get pod <pod-name> -o yaml | grep -A 10 securityContext

# Xem capabilities của pod
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].securityContext.capabilities}'

# Xem seccomp profile
kubectl get pod <pod-name> -o jsonpath='{.spec.securityContext.seccompProfile}'
```

---

## 💾 Storage Operations

### Persistent Volume Operations
```bash
# Xem persistent volumes
kubectl get pv

# Xem thông tin chi tiết về persistent volume
kubectl describe pv <pv-name>

# Xem persistent volume claims
kubectl get pvc

# Xem thông tin chi tiết về persistent volume claim
kubectl describe pvc <pvc-name>

# Xóa persistent volume
kubectl delete pv <pv-name>

# Xóa persistent volume claim
kubectl delete pvc <pvc-name>
```

### Storage Class Operations
```bash
# Xem storage classes
kubectl get storageclass

# Xem thông tin chi tiết về storage class
kubectl describe storageclass <storage-class-name>

# Xem default storage class
kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'
```

---

## 🌐 Network Operations

### Network Policy Operations
```bash
# Tạo network policy từ file YAML
kubectl create -f network-policy.yaml

# Xem network policies
kubectl get networkpolicies

# Xem thông tin chi tiết về network policy
kubectl describe networkpolicy <network-policy-name>

# Xóa network policy
kubectl delete networkpolicy <network-policy-name>
```

### Service Discovery
```bash
# Xem services với labels
kubectl get services --show-labels

# Xem services với selector
kubectl get services --selector=app=nginx

# Test service discovery
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup <service-name>.<namespace>.svc.cluster.local
```

---

## 🚀 Advanced Operations

### Custom Resource Operations
```bash
# Xem custom resource definitions
kubectl get crd

# Xem thông tin chi tiết về CRD
kubectl describe crd <crd-name>

# Xem custom resources
kubectl get <custom-resource-name>

# Xem thông tin chi tiết về custom resource
kubectl describe <custom-resource-name> <resource-name>
```

### Job và CronJob Operations
```bash
# Tạo job từ file YAML
kubectl create -f job.yaml

# Xem jobs
kubectl get jobs

# Xem thông tin chi tiết về job
kubectl describe job <job-name>

# Xem pods của job
kubectl get pods -l job-name=<job-name>

# Xóa job
kubectl delete job <job-name>

# Tạo cronjob từ file YAML
kubectl create -f cronjob.yaml

# Xem cronjobs
kubectl get cronjobs

# Xem thông tin chi tiết về cronjob
kubectl describe cronjob <cronjob-name>

# Xóa cronjob
kubectl delete cronjob <cronjob-name>
```

### StatefulSet Operations
```bash
# Tạo statefulset từ file YAML
kubectl create -f statefulset.yaml

# Xem statefulsets
kubectl get statefulsets

# Xem thông tin chi tiết về statefulset
kubectl describe statefulset <statefulset-name>

# Xem pods của statefulset
kubectl get pods -l app=<statefulset-name>

# Scale statefulset
kubectl scale statefulset <statefulset-name> --replicas=5

# Xóa statefulset
kubectl delete statefulset <statefulset-name>
```

### DaemonSet Operations
```bash
# Tạo daemonset từ file YAML
kubectl create -f daemonset.yaml

# Xem daemonsets
kubectl get daemonsets

# Xem thông tin chi tiết về daemonset
kubectl describe daemonset <daemonset-name>

# Xem pods của daemonset
kubectl get pods -l app=<daemonset-name>

# Xóa daemonset
kubectl delete daemonset <daemonset-name>
```

---

## 🛠️ Utility Commands

### Output Formatting
```bash
# Output dạng YAML
kubectl get pods -o yaml

# Output dạng JSON
kubectl get pods -o json

# Output dạng table với custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,AGE:.metadata.creationTimestamp

# Output dạng wide
kubectl get pods -o wide

# Output dạng name only
kubectl get pods -o name
```

### Label và Selector Operations
```bash
# Xem labels của resource
kubectl get pods --show-labels

# Xem resources với selector
kubectl get pods --selector=app=nginx

# Xem resources với multiple selectors
kubectl get pods --selector=app=nginx,version=1.0

# Thêm label cho resource
kubectl label pod <pod-name> app=nginx

# Xóa label của resource
kubectl label pod <pod-name> app-

# Cập nhật label của resource
kubectl label pod <pod-name> app=nginx --overwrite
```

### Annotation Operations
```bash
# Xem annotations của resource
kubectl get pod <pod-name> -o jsonpath='{.metadata.annotations}'

# Thêm annotation cho resource
kubectl annotate pod <pod-name> description="This is a test pod"

# Xóa annotation của resource
kubectl annotate pod <pod-name> description-

# Cập nhật annotation của resource
kubectl annotate pod <pod-name> description="Updated description" --overwrite
```

---

## 📚 Tài liệu tham khảo

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

---

## 🤝 Đóng góp

Nếu bạn có góp ý hoặc muốn cập nhật cheatsheet này, vui lòng tạo issue hoặc pull request.

---

*Cheatsheet này được tạo để phục vụ cộng đồng DevOps Việt Nam. Cập nhật lần cuối: $(date)*
