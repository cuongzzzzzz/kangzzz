# Hướng Dẫn Kiến Trúc Docker Swarm và Các Lệnh Cần Thiết

## Mục Lục
1. [Tổng Quan](#tổng-quan)
2. [Các Thành Phần Kiến Trúc](#các-thành-phần-kiến-trúc)
3. [Các Loại Node](#các-loại-node)
4. [Service Discovery và Load Balancing](#service-discovery-và-load-balancing)
5. [Mạng](#mạng)
6. [Các Lệnh Cần Thiết](#các-lệnh-cần-thiết)
7. [Chiến Lược Triển Khai](#chiến-lược-triển-khai)
8. [Các Vấn Đề Bảo Mật](#các-vấn-đề-bảo-mật)
9. [Khắc Phục Sự Cố](#khắc-phục-sự-cố)
10. [Thực Hành Tốt Nhất](#thực-hành-tốt-nhất)

## Tổng Quan

Docker Swarm là giải pháp clustering và orchestration (điều phối) gốc của Docker, cho phép bạn tạo và quản lý một cluster (cụm) các Docker node. Nó cung cấp tính khả dụng cao, cân bằng tải, khám phá dịch vụ và cập nhật rolling cho các ứng dụng containerized.

### Các Tính Năng Chính
- **Tích Hợp Docker Gốc**: Được tích hợp sẵn trong Docker Engine
- **Tính Khả Dụng Cao**: Tự động failover và khôi phục dịch vụ
- **Cân Bằng Tải**: Cân bằng tải tích hợp sẵn giữa các node
- **Khám Phá Dịch Vụ**: Tự động khám phá dịch vụ và phân giải DNS
- **Cập Nhật Rolling**: Triển khai không downtime
- **Mở Rộng**: Dễ dàng mở rộng ngang các dịch vụ

## Các Thành Phần Kiến Trúc

### 1. Swarm Cluster
Một Docker Swarm cluster bao gồm nhiều Docker node hoạt động cùng nhau như một hệ thống ảo duy nhất.

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Swarm Cluster                     │
├─────────────────────────────────────────────────────────────┤
│  Manager Nodes (Control Plane)                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Manager   │  │   Manager   │  │   Manager   │        │
│  │   Node 1    │  │   Node 2    │  │   Node 3    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│  Worker Nodes (Data Plane)                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Worker    │  │   Worker    │  │   Worker    │        │
│  │   Node 1    │  │   Node 2    │  │   Node 3    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### 2. Services và Tasks
- **Service (Dịch vụ)**: Định nghĩa cách các container nên được triển khai
- **Task (Nhiệm vụ)**: Một container đơn lẻ chạy trên một node
- **Replicas (Bản sao)**: Số lượng task giống hệt nhau cho một service

### 3. Overlay Network
- **Ingress Network**: Định tuyến lưu lượng bên ngoài
- **Overlay Networks**: Giao tiếp nội bộ giữa các service
- **Bridge Networks**: Giao tiếp local giữa các container

## Các Loại Node

### Manager Nodes (Node Quản Lý)
- **Vai Trò Chính**: Quản lý cluster và điều phối
- **Trách Nhiệm**:
  - Duy trì trạng thái cluster
  - Lên lịch các service
  - Xử lý các yêu cầu API
  - Quản lý các worker node
- **Raft Consensus**: Sử dụng thuật toán Raft để bầu chọn leader
- **Tối Thiểu**: 1 manager (không khuyến nghị cho production)
- **Khuyến Nghị**: 3-5 managers để có tính khả dụng cao

### Worker Nodes (Node Công Việc)
- **Vai Trò Chính**: Thực thi tasks và chạy containers
- **Trách Nhiệm**:
  - Chạy các container tasks
  - Báo cáo trạng thái cho managers
  - Thực thi các service replicas
- **Không Quản Lý**: Không thể quản lý cluster hoặc lên lịch services

## Service Discovery và Load Balancing

### Service Discovery (Khám Phá Dịch Vụ)
- **DNS-based**: Các service có thể truy cập bằng tên service
- **Internal Load Balancing**: Phân phối tải tự động
- **Health Checks**: Tự động thay thế task khi lỗi

### Load Balancing (Cân Bằng Tải)
- **Ingress Load Balancing**: Phân phối lưu lượng bên ngoài
- **Internal Load Balancing**: Giao tiếp giữa các service
- **Session Affinity**: Tùy chọn sticky sessions

## Mạng

### Các Loại Mạng
1. **Ingress Network**: Định tuyến lưu lượng bên ngoài
2. **Overlay Networks**: Giao tiếp giữa các service
3. **Bridge Networks**: Giao tiếp local giữa các container
4. **Host Networks**: Truy cập trực tiếp mạng host

### Kiến Trúc Mạng
```
┌─────────────────────────────────────────────────────────────┐
│                    External Traffic                         │
│                         │                                  │
│                         ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                Ingress Network                          ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    ││
│  │  │   Service   │  │   Service   │  │   Service   │    ││
│  │  │     A       │  │     B       │  │     C       │    ││
│  │  └─────────────┘  └─────────────┘  └─────────────┘    ││
│  └─────────────────────────────────────────────────────────┘│
│                         │                                  │
│                         ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                Overlay Network                          ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    ││
│  │  │   Task 1    │  │   Task 2    │  │   Task 3    │    ││
│  │  └─────────────┘  └─────────────┘  └─────────────┘    ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Các Lệnh Cần Thiết

### Quản Lý Cluster

#### Khởi Tạo Swarm
```bash
# Khởi tạo swarm trên node hiện tại
docker swarm init

# Khởi tạo swarm với địa chỉ advertise cụ thể
docker swarm init --advertise-addr 192.168.1.100

# Khởi tạo swarm với load balancer bên ngoài
docker swarm init --advertise-addr 192.168.1.100:2377 --listen-addr 0.0.0.0:2377
```

#### Thêm Node Vào Swarm
```bash
# Lấy join token cho workers
docker swarm join-token worker

# Lấy join token cho managers
docker swarm join-token manager

# Tham gia như worker node
docker swarm join --token SWMTKN-1-xxx 192.168.1.100:2377

# Tham gia như manager node
docker swarm join --token SWMTKN-1-xxx 192.168.1.100:2377
```

#### Rời Khỏi Swarm
```bash
# Rời khỏi swarm (worker node)
docker swarm leave

# Rời khỏi swarm (manager node) - chỉ khi không phải manager cuối cùng
docker swarm leave

# Buộc rời khỏi swarm
docker swarm leave --force
```

### Quản Lý Node

#### Liệt Kê Node
```bash
# Liệt kê tất cả node trong swarm
docker node ls

# Liệt kê node với format cụ thể
docker node ls --format "table {{.ID}}\t{{.Hostname}}\t{{.Status}}\t{{.Availability}}"
```

#### Các Thao Tác Node
```bash
# Kiểm tra node cụ thể
docker node inspect <node-id>

# Nâng cấp worker thành manager
docker node promote <node-id>

# Hạ cấp manager thành worker
docker node demote <node-id>

# Xóa node khỏi swarm
docker node rm <node-id>

# Cập nhật tính khả dụng của node
docker node update --availability drain <node-id>
docker node update --availability active <node-id>
docker node update --availability pause <node-id>
```

### Quản Lý Service

#### Tạo Service
```bash
# Tạo service với image
docker service create --name web nginx:latest

# Tạo service với replicas
docker service create --name web --replicas 3 nginx:latest

# Tạo service với port mapping
docker service create --name web --publish 80:80 nginx:latest

# Tạo service với biến môi trường
docker service create --name web --env MYSQL_HOST=db nginx:latest

# Tạo service với constraints
docker service create --name web --constraint 'node.role==worker' nginx:latest

# Tạo service với placement preferences
docker service create --name web --placement-pref 'spread=node.labels.zone' nginx:latest
```

#### Các Thao Tác Service
```bash
# Liệt kê services
docker service ls

# Kiểm tra service
docker service inspect <service-name>

# Cập nhật service
docker service update --replicas 5 <service-name>

# Scale service
docker service scale <service-name>=5

# Xóa service
docker service rm <service-name>

# Xem logs service
docker service logs <service-name>

# Xem logs service với follow
docker service logs -f <service-name>
```

#### Cập Nhật Service
```bash
# Cập nhật image service
docker service update --image nginx:1.20 <service-name>

# Cập nhật service với rolling update
docker service update --update-parallelism 2 --update-delay 10s <service-name>

# Rollback service
docker service rollback <service-name>

# Cập nhật biến môi trường service
docker service update --env-add NEW_VAR=value <service-name>
```

### Quản Lý Task

#### Liệt Kê Task
```bash
# Liệt kê tất cả task
docker service ps <service-name>

# Liệt kê task với format cụ thể
docker service ps --format "table {{.ID}}\t{{.Name}}\t{{.Node}}\t{{.DesiredState}}\t{{.CurrentState}}" <service-name>
```

#### Các Thao Tác Task
```bash
# Kiểm tra task cụ thể
docker service ps --no-trunc <service-name>

# Xem logs task
docker logs <task-id>
```

### Quản Lý Mạng

#### Tạo Mạng
```bash
# Tạo overlay network
docker network create --driver overlay --attachable my-network

# Tạo overlay network với mã hóa
docker network create --driver overlay --opt encrypted my-secure-network

# Tạo overlay network với subnet tùy chỉnh
docker network create --driver overlay --subnet 10.0.0.0/24 my-network
```

#### Các Thao Tác Mạng
```bash
# Liệt kê mạng
docker network ls

# Kiểm tra mạng
docker network inspect <network-name>

# Xóa mạng
docker network rm <network-name>

# Kết nối service với mạng
docker service update --network-add <network-name> <service-name>
```

### Quản Lý Secret

#### Tạo Secret
```bash
# Tạo secret từ file
docker secret create <secret-name> <file-path>

# Tạo secret từ stdin
echo "my-secret-value" | docker secret create <secret-name> -

# Tạo secret từ biến môi trường
docker secret create <secret-name> <(echo $MY_SECRET)
```

#### Các Thao Tác Secret
```bash
# Liệt kê secrets
docker secret ls

# Kiểm tra secret
docker secret inspect <secret-name>

# Xóa secret
docker secret rm <secret-name>

# Sử dụng secret trong service
docker service create --secret <secret-name> --name web nginx:latest
```

### Quản Lý Config

#### Tạo Config
```bash
# Tạo config từ file
docker config create <config-name> <file-path>

# Tạo config từ stdin
echo "config-content" | docker config create <config-name> -
```

#### Các Thao Tác Config
```bash
# Liệt kê configs
docker config ls

# Kiểm tra config
docker config inspect <config-name>

# Xóa config
docker config rm <config-name>

# Sử dụng config trong service
docker service create --config <config-name> --name web nginx:latest
```

## Chiến Lược Triển Khai

### 1. Rolling Updates (Cập Nhật Tuần Tự)
```bash
# Cập nhật service với rolling update
docker service update \
  --update-parallelism 2 \
  --update-delay 10s \
  --update-failure-action rollback \
  --image nginx:1.20 \
  web
```

### 2. Blue-Green Deployment (Triển Khai Xanh-Lam)
```bash
# Triển khai phiên bản mới cùng với phiên bản cũ
docker service create --name web-v2 --replicas 3 nginx:1.20

# Chuyển lưu lượng sang phiên bản mới
docker service update --label-add version=v2 web-v2
docker service update --label-add version=v1 web

# Xóa phiên bản cũ
docker service rm web
docker service update --name web web-v2
```

### 3. Canary Deployment (Triển Khai Canary)
```bash
# Triển khai phiên bản canary
docker service create --name web-canary --replicas 1 nginx:1.20

# Tăng dần lưu lượng canary
docker service scale web-canary=2
docker service scale web-canary=3

# Thay thế service chính
docker service update --image nginx:1.20 web
docker service rm web-canary
```

## Các Vấn Đề Bảo Mật

### 1. Cấu Hình TLS/SSL
```bash
# Khởi tạo swarm với TLS
docker swarm init --advertise-addr 192.168.1.100:2377 \
  --cert-expiry 2160h \
  --external-ca <ca-cert> \
  --ca-cert <ca-cert> \
  --ca-key <ca-key>
```

### 2. Quản Lý Secret
```bash
# Tạo secret cho mật khẩu database
echo "secure-password" | docker secret create db_password -

# Sử dụng secret trong service
docker service create \
  --secret db_password \
  --name database \
  postgres:latest
```

### 3. Bảo Mật Mạng
```bash
# Tạo overlay network được mã hóa
docker network create \
  --driver overlay \
  --opt encrypted \
  --opt com.docker.network.driver.mtu=1450 \
  secure-network
```

### 4. Bảo Mật Node
```bash
# Drain node để bảo trì
docker node update --availability drain <node-id>

# Cập nhật node labels cho security zones
docker node update --label-add security.zone=dmz <node-id>
```

## Khắc Phục Sự Cố

### Các Vấn Đề Thường Gặp

#### 1. Service Không Khởi Động
```bash
# Kiểm tra trạng thái service
docker service ps <service-name>

# Kiểm tra logs service
docker service logs <service-name>

# Kiểm tra tài nguyên node
docker node inspect <node-id>
```

#### 2. Vấn Đề Mạng
```bash
# Kiểm tra kết nối mạng
docker exec -it <container-id> ping <service-name>

# Kiểm tra mạng
docker network inspect <network-name>

# Kiểm tra phân giải DNS
docker exec -it <container-id> nslookup <service-name>
```

#### 3. Vấn Đề Node
```bash
# Kiểm tra trạng thái node
docker node ls

# Kiểm tra tài nguyên node
docker node inspect <node-id>

# Kiểm tra logs node
journalctl -u docker.service
```

### Các Lệnh Debug
```bash
# Kiểm tra trạng thái swarm
docker system info

# Kiểm tra chi tiết service
docker service inspect <service-name>

# Kiểm tra chi tiết task
docker service ps --no-trunc <service-name>

# Kiểm tra chi tiết mạng
docker network inspect <network-name>

# Kiểm tra chi tiết node
docker node inspect <node-id>
```

## Thực Hành Tốt Nhất

### 1. Thiết Kế Cluster
- Sử dụng số lẻ manager nodes (3, 5, 7)
- Phân bố managers qua các availability zones
- Sử dụng dedicated manager nodes cho production
- Triển khai chiến lược backup phù hợp

### 2. Thiết Kế Service
- Sử dụng health checks cho tất cả services
- Triển khai logging và monitoring phù hợp
- Sử dụng secrets cho dữ liệu nhạy cảm
- Thiết kế cho statelessness

### 3. Mạng
- Sử dụng overlay networks cho giao tiếp service
- Triển khai network segmentation
- Sử dụng mạng mã hóa cho dữ liệu nhạy cảm
- Giám sát lưu lượng mạng

### 4. Bảo Mật
- Bật TLS cho tất cả giao tiếp
- Sử dụng secrets cho dữ liệu nhạy cảm
- Triển khai access controls phù hợp
- Cập nhật bảo mật thường xuyên

### 5. Giám Sát
- Giám sát sức khỏe cluster
- Giám sát hiệu suất service
- Giám sát sử dụng tài nguyên
- Triển khai alerting

## Ví Dụ Triển Khai

### Stack Ứng Dụng Web Hoàn Chỉnh
```bash
# Tạo overlay network
docker network create --driver overlay web-network

# Tạo database service
docker service create \
  --name database \
  --network web-network \
  --secret db_password \
  --constraint 'node.role==worker' \
  --replicas 1 \
  postgres:13

# Tạo web service
docker service create \
  --name web \
  --network web-network \
  --publish 80:80 \
  --constraint 'node.role==worker' \
  --replicas 3 \
  --update-parallelism 1 \
  --update-delay 10s \
  nginx:latest

# Tạo cache service
docker service create \
  --name cache \
  --network web-network \
  --constraint 'node.role==worker' \
  --replicas 2 \
  redis:6
```

### Stack Giám Sát
```bash
# Tạo monitoring network
docker network create --driver overlay monitoring

# Tạo Prometheus service
docker service create \
  --name prometheus \
  --network monitoring \
  --publish 9090:9090 \
  --constraint 'node.role==manager' \
  --replicas 1 \
  prom/prometheus:latest

# Tạo Grafana service
docker service create \
  --name grafana \
  --network monitoring \
  --publish 3000:3000 \
  --constraint 'node.role==manager' \
  --replicas 1 \
  grafana/grafana:latest
```

## Kết Luận

Docker Swarm cung cấp một giải pháp mạnh mẽ và gốc cho container orchestration với Docker. Bằng cách tuân theo các mẫu kiến trúc và lệnh được nêu trong hướng dẫn này, bạn có thể xây dựng các ứng dụng containerized có thể mở rộng và có tính khả dụng cao. Hãy nhớ triển khai các biện pháp bảo mật phù hợp, giám sát và chiến lược backup cho các triển khai production.

Đối với các kịch bản nâng cao hơn và tính năng doanh nghiệp, hãy xem xét Docker Swarm mode với external load balancers, giải pháp persistent storage và các stack giám sát toàn diện.
