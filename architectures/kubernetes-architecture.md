# Hướng Dẫn Kiến Trúc Kubernetes - Từ Newbie Đến Advanced

## Mục Lục
1. [Tổng Quan](#tổng-quan)
2. [Cấp Độ Newbie - Khái Niệm Cơ Bản](#cấp-độ-newbie---khái-niệm-cơ-bản)
3. [Cấp Độ Beginner - Triển Khai Cơ Bản](#cấp-độ-beginner---triển-khai-cơ-bản)
4. [Cấp Độ Intermediate - Quản Lý Nâng Cao](#cấp-độ-intermediate---quản-lý-nâng-cao)
5. [Cấp Độ Advanced - Kiến Trúc Phức Tạp](#cấp-độ-advanced---kiến-trúc-phức-tạp)
6. [Cấp Độ Expert - Production & Enterprise](#cấp-độ-expert---production--enterprise)
7. [Các Lệnh Cần Thiết Theo Cấp Độ](#các-lệnh-cần-thiết-theo-cấp-độ)
8. [Troubleshooting & Debugging](#troubleshooting--debugging)
9. [Best Practices](#best-practices)
10. [Case Studies](#case-studies)

## Tổng Quan

Kubernetes (K8s) là một nền tảng orchestration mã nguồn mở để tự động hóa việc triển khai, mở rộng và quản lý các ứng dụng containerized. Tài liệu này được thiết kế để hướng dẫn bạn từ cấp độ mới bắt đầu đến chuyên gia.

### Các Cấp Độ Học Tập
- **Newbie**: Hiểu khái niệm cơ bản và kiến trúc
- **Beginner**: Triển khai ứng dụng đơn giản
- **Intermediate**: Quản lý ứng dụng phức tạp và networking
- **Advanced**: Tối ưu hóa và kiến trúc microservices
- **Expert**: Production-ready và enterprise features

---

## Cấp Độ Newbie - Khái Niệm Cơ Bản

### 1. Kubernetes Là Gì?

Kubernetes là một hệ thống quản lý container tự động, giúp:
- **Orchestration**: Điều phối và quản lý containers
- **Scaling**: Tự động mở rộng dựa trên tải
- **Service Discovery**: Tự động khám phá và kết nối services
- **Load Balancing**: Cân bằng tải giữa các instances
- **Rolling Updates**: Cập nhật không downtime
- **Self-Healing**: Tự động khôi phục khi có lỗi

### 2. Kiến Trúc Cơ Bản

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│  Control Plane (Master Nodes)                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   API       │  │  Scheduler  │  │ Controller  │        │
│  │  Server     │  │             │  │  Manager    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   etcd      │  │   kubelet   │  │   kube-     │        │
│  │             │  │             │  │   proxy     │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│  Worker Nodes (Data Plane)                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   kubelet   │  │   kubelet   │  │   kubelet   │        │
│  │   kube-     │  │   kube-     │  │   kube-     │        │
│  │   proxy     │  │   proxy     │  │   proxy     │        │
│  │   Pods      │  │   Pods      │  │   Pods      │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### 3. Các Thành Phần Chính

#### Control Plane Components
- **API Server**: Giao diện REST API cho tất cả operations
- **etcd**: Database phân tán lưu trữ cluster state
- **Scheduler**: Quyết định pod nào chạy trên node nào
- **Controller Manager**: Chạy các controller processes
- **Cloud Controller Manager**: Tích hợp với cloud provider

#### Node Components
- **kubelet**: Agent chạy trên mỗi node, quản lý pods
- **kube-proxy**: Network proxy, quản lý network rules
- **Container Runtime**: Docker, containerd, CRI-O

### 4. Khái Niệm Cơ Bản

#### Pod
- **Định nghĩa**: Nhóm nhỏ nhất và đơn giản nhất trong Kubernetes
- **Chứa**: Một hoặc nhiều containers
- **Chia sẻ**: Network và storage resources
- **Lifecycle**: Tạo, chạy, dừng, xóa

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.20
    ports:
    - containerPort: 80
```

#### Node
- **Định nghĩa**: Worker machine trong Kubernetes cluster
- **Chứa**: kubelet, kube-proxy, container runtime
- **Chạy**: Pods được schedule bởi control plane

#### Namespace
- **Định nghĩa**: Virtual cluster trong physical cluster
- **Mục đích**: Tách biệt resources và tổ chức
- **Mặc định**: default, kube-system, kube-public, kube-node-lease

---

## Cấp Độ Beginner - Triển Khai Cơ Bản

### 1. Cài Đặt Kubernetes

#### Minikube (Local Development)
```bash
# Cài đặt Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Khởi động cluster
minikube start

# Kiểm tra trạng thái
kubectl get nodes
```

#### kubeadm (Production-like)
```bash
# Cài đặt kubeadm, kubelet, kubectl
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl

# Khởi tạo cluster
kubeadm init --pod-network-cidr=10.244.0.0/16

# Cài đặt CNI (Flannel)
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

### 2. Các Lệnh Cơ Bản

#### kubectl - Công Cụ Chính
```bash
# Kiểm tra cluster info
kubectl cluster-info

# Xem nodes
kubectl get nodes

# Xem pods
kubectl get pods

# Xem pods trong namespace cụ thể
kubectl get pods -n kube-system

# Xem chi tiết pod
kubectl describe pod <pod-name>

# Xem logs
kubectl logs <pod-name>

# Exec vào pod
kubectl exec -it <pod-name> -- /bin/bash
```

### 3. Triển Khai Ứng Dụng Đơn Giản

#### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
```

#### Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
```

#### Triển Khai
```bash
# Tạo deployment
kubectl apply -f nginx-deployment.yaml

# Tạo service
kubectl apply -f nginx-service.yaml

# Kiểm tra trạng thái
kubectl get deployments
kubectl get services
kubectl get pods
```

### 4. Scaling Cơ Bản

```bash
# Scale deployment
kubectl scale deployment nginx-deployment --replicas=5

# Scale với file YAML
kubectl apply -f nginx-deployment.yaml

# Auto scaling (cần metrics-server)
kubectl autoscale deployment nginx-deployment --min=2 --max=10 --cpu-percent=50
```

---

## Cấp Độ Intermediate - Quản Lý Nâng Cao

### 1. Networking Concepts

#### Service Types
```yaml
# ClusterIP (mặc định)
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080

# NodePort
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080

# LoadBalancer
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
```

#### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

### 2. ConfigMaps và Secrets

#### ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_url: "mysql://localhost:3306/mydb"
  debug: "true"
  log_level: "info"
```

#### Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded
  password: cGFzc3dvcmQ=  # base64 encoded
```

#### Sử dụng trong Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: DB_URL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_url
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: password
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

### 3. Persistent Volumes

#### PersistentVolume
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: slow
  hostPath:
    path: /data
```

#### PersistentVolumeClaim
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: slow
```

#### Sử dụng trong Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: my-pvc
```

### 4. Health Checks

#### Liveness Probe
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-pod
spec:
  containers:
  - name: app
    image: myapp:latest
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
```

#### Readiness Probe
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-pod
spec:
  containers:
  - name: app
    image: myapp:latest
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 3
      successThreshold: 1
      failureThreshold: 3
```

---

## Cấp Độ Advanced - Kiến Trúc Phức Tạp

### 1. Microservices Architecture

#### Service Mesh với Istio
```yaml
# Istio Gateway
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: my-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - myapp.example.com
```

#### Virtual Service
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-virtual-service
spec:
  hosts:
  - myapp.example.com
  gateways:
  - my-gateway
  http:
  - match:
    - uri:
        prefix: /api
    route:
    - destination:
        host: api-service
        port:
          number: 80
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: web-service
        port:
          number: 80
```

### 2. StatefulSets

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-statefulset
spec:
  serviceName: mysql-service
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "password"
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

### 3. DaemonSets

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      containers:
      - name: fluentd-elasticsearch
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-elasticsearch
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.logging.svc.cluster.local"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

### 4. Jobs và CronJobs

#### Job
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-processing-job
spec:
  template:
    spec:
      containers:
      - name: processor
        image: data-processor:latest
        command: ["python", "process_data.py"]
      restartPolicy: Never
  backoffLimit: 3
```

#### CronJob
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 2 * * *"  # Chạy lúc 2:00 AM hàng ngày
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup-tool:latest
            command: ["backup.sh"]
          restartPolicy: OnFailure
```

---

## Cấp Độ Expert - Production & Enterprise

### 1. High Availability Setup

#### Multi-Master Cluster
```yaml
# kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
controlPlaneEndpoint: "k8s-api.example.com:6443"
etcd:
  external:
    endpoints:
    - "https://etcd1.example.com:2379"
    - "https://etcd2.example.com:2379"
    - "https://etcd3.example.com:2379"
    caFile: "/etc/kubernetes/pki/etcd/ca.crt"
    certFile: "/etc/kubernetes/pki/etcd/etcd.crt"
    keyFile: "/etc/kubernetes/pki/etcd/etcd.key"
```

#### Load Balancer Configuration
```yaml
# HAProxy configuration
global
    daemon
    maxconn 4096

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend kubernetes-frontend
    bind *:6443
    mode tcp
    default_backend kubernetes-backend

backend kubernetes-backend
    mode tcp
    balance roundrobin
    option tcp-check
    server k8s-master-1 192.168.1.10:6443 check
    server k8s-master-2 192.168.1.11:6443 check
    server k8s-master-3 192.168.1.12:6443 check
```

### 2. Security Best Practices

#### Pod Security Standards
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    image: myapp:latest
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

#### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 8080
```

#### RBAC (Role-Based Access Control)
```yaml
# ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-account
  namespace: default

# Role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: my-service-account
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### 3. Monitoring và Observability

#### Prometheus Monitoring
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
    - job_name: 'kubernetes-services'
      kubernetes_sd_configs:
      - role: service
```

#### Grafana Dashboard
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard
data:
  dashboard.json: |
    {
      "dashboard": {
        "title": "Kubernetes Cluster Monitoring",
        "panels": [
          {
            "title": "Pod CPU Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(container_cpu_usage_seconds_total[5m])"
              }
            ]
          }
        ]
      }
    }
```

### 4. CI/CD với Kubernetes

#### GitLab CI/CD Pipeline
```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  KUBE_NAMESPACE: production

build:
  stage: build
  script:
    - docker build -t $DOCKER_IMAGE .
    - docker push $DOCKER_IMAGE

test:
  stage: test
  script:
    - kubectl apply -f k8s/test/
    - kubectl wait --for=condition=available deployment/test-app --timeout=300s
    - kubectl run test-runner --image=test-runner:latest --rm -i --restart=Never -- test-suite

deploy:
  stage: deploy
  script:
    - kubectl set image deployment/my-app app=$DOCKER_IMAGE -n $KUBE_NAMESPACE
    - kubectl rollout status deployment/my-app -n $KUBE_NAMESPACE
  only:
    - main
```

#### ArgoCD Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/myapp
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

---

## Các Lệnh Cần Thiết Theo Cấp Độ

### Newbie Commands
```bash
# Kiểm tra cluster
kubectl cluster-info
kubectl get nodes
kubectl get pods

# Tạo và xóa resources
kubectl create deployment nginx --image=nginx
kubectl delete deployment nginx

# Xem logs
kubectl logs <pod-name>
```

### Beginner Commands
```bash
# Quản lý deployments
kubectl apply -f deployment.yaml
kubectl get deployments
kubectl scale deployment nginx --replicas=3
kubectl rollout status deployment nginx

# Quản lý services
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get services

# Port forwarding
kubectl port-forward pod/nginx 8080:80
```

### Intermediate Commands
```bash
# Quản lý configmaps và secrets
kubectl create configmap my-config --from-file=config.properties
kubectl create secret generic my-secret --from-literal=password=secret
kubectl get configmaps
kubectl get secrets

# Quản lý persistent volumes
kubectl get pv
kubectl get pvc
kubectl describe pv <pv-name>

# Quản lý namespaces
kubectl create namespace my-namespace
kubectl get namespaces
kubectl config set-context --current --namespace=my-namespace
```

### Advanced Commands
```bash
# Quản lý statefulsets
kubectl get statefulsets
kubectl describe statefulset mysql

# Quản lý daemonsets
kubectl get daemonsets
kubectl describe daemonset fluentd

# Quản lý jobs
kubectl get jobs
kubectl get cronjobs
kubectl create job my-job --image=busybox -- echo "Hello World"

# Debugging
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
kubectl exec -it <pod-name> -- /bin/bash
```

### Expert Commands
```bash
# Quản lý RBAC
kubectl get roles
kubectl get rolebindings
kubectl create role pod-reader --verb=get,list,watch --resource=pods
kubectl create rolebinding read-pods --role=pod-reader --user=user1

# Quản lý network policies
kubectl get networkpolicies
kubectl describe networkpolicy my-policy

# Quản lý custom resources
kubectl get crd
kubectl get <custom-resource>

# Cluster maintenance
kubectl drain <node-name> --ignore-daemonsets
kubectl uncordon <node-name>
kubectl taint nodes <node-name> key=value:NoSchedule
```

---

## Troubleshooting & Debugging

### 1. Pod Issues

#### Pod Stuck in Pending
```bash
# Kiểm tra events
kubectl describe pod <pod-name>

# Kiểm tra node resources
kubectl top nodes
kubectl describe node <node-name>

# Kiểm tra taints và tolerations
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

#### Pod CrashLoopBackOff
```bash
# Xem logs
kubectl logs <pod-name> --previous

# Kiểm tra events
kubectl describe pod <pod-name>

# Debug container
kubectl exec -it <pod-name> -- /bin/bash
```

### 2. Service Issues

#### Service Not Accessible
```bash
# Kiểm tra service endpoints
kubectl get endpoints <service-name>

# Kiểm tra service selector
kubectl get pods --show-labels

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -O- <service-name>
```

### 3. Network Issues

#### DNS Resolution
```bash
# Test DNS trong pod
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default

# Kiểm tra CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### 4. Storage Issues

#### PVC Stuck in Pending
```bash
# Kiểm tra storage class
kubectl get storageclass

# Kiểm tra PV
kubectl get pv
kubectl describe pv <pv-name>

# Kiểm tra events
kubectl get events --sort-by=.metadata.creationTimestamp
```

---

## Best Practices

### 1. Resource Management
- Sử dụng resource requests và limits
- Implement proper resource quotas
- Monitor resource usage
- Use horizontal pod autoscaling

### 2. Security
- Enable RBAC
- Use network policies
- Implement pod security standards
- Regular security scanning

### 3. Monitoring
- Implement comprehensive logging
- Use monitoring tools (Prometheus, Grafana)
- Set up alerting
- Monitor cluster health

### 4. Backup & Recovery
- Regular etcd backups
- Application data backups
- Disaster recovery planning
- Test recovery procedures

---

## Case Studies

### 1. E-commerce Platform
- Microservices architecture
- Service mesh implementation
- Multi-environment setup
- CI/CD pipeline

### 2. Data Processing Pipeline
- Batch processing with Jobs
- Stream processing with DaemonSets
- Stateful data storage
- Monitoring and alerting

### 3. High-Traffic Web Application
- Auto-scaling configuration
- Load balancing strategies
- Caching implementation
- Performance optimization

---

## Kết Luận

Tài liệu này cung cấp hướng dẫn toàn diện về Kubernetes từ cấp độ newbie đến expert. Mỗi cấp độ được thiết kế để xây dựng kiến thức và kỹ năng một cách có hệ thống, giúp bạn trở thành chuyên gia Kubernetes.

### Lộ Trình Học Tập Khuyến Nghị:
1. **Newbie**: Học khái niệm cơ bản và thực hành với Minikube
2. **Beginner**: Triển khai ứng dụng đơn giản và học các lệnh cơ bản
3. **Intermediate**: Quản lý networking, storage và monitoring
4. **Advanced**: Tối ưu hóa và kiến trúc phức tạp
5. **Expert**: Production-ready và enterprise features

Hãy thực hành thường xuyên và tham gia cộng đồng Kubernetes để nâng cao kỹ năng của bạn!
