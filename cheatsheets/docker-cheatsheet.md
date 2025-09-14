# Docker Cheatsheet

## 📋 Mục lục
- [Cài đặt và cấu hình](#cài-đặt-và-cấu-hình)
- [Quản lý Images](#quản-lý-images)
- [Quản lý Containers](#quản-lý-containers)
- [Dockerfile](#dockerfile)
- [Docker Compose](#docker-compose)
- [Docker Networks](#docker-networks)
- [Docker Volumes](#docker-volumes)
- [Docker Registry](#docker-registry)
- [Monitoring và Debugging](#monitoring-và-debugging)
- [Docker Security](#docker-security)
- [Docker Swarm](#docker-swarm)
- [Tips và Best Practices](#tips-và-best-practices)

---

## Cài đặt và cấu hình

### Cài đặt Docker
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io

# CentOS/RHEL
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io

# macOS (với Homebrew)
brew install --cask docker

# Kiểm tra cài đặt
docker --version                  # Xem phiên bản Docker
docker info                       # Xem thông tin chi tiết Docker
docker run hello-world            # Test Docker hoạt động
```

### Cấu hình Docker
```bash
# Thêm user vào docker group (tránh dùng sudo)
sudo usermod -aG docker $USER     # Thêm user hiện tại vào docker group
newgrp docker                     # Apply group changes
sudo systemctl start docker       # Khởi động Docker service
sudo systemctl enable docker      # Tự động khởi động Docker khi boot
sudo systemctl status docker      # Kiểm tra trạng thái Docker

# Cấu hình Docker daemon
sudo nano /etc/docker/daemon.json  # Edit Docker daemon config
sudo systemctl restart docker      # Restart Docker sau khi config
```

---

## Quản lý Images

### Tìm kiếm và tải Images
```bash
# Tìm kiếm images
docker search <image_name>        # Tìm kiếm image trên Docker Hub
docker search --limit 5 nginx     # Giới hạn kết quả tìm kiếm

# Tải images
docker pull <image_name>          # Tải image mới nhất
docker pull <image_name>:<tag>    # Tải image với tag cụ thể
docker pull ubuntu:20.04          # Tải Ubuntu 20.04
docker pull nginx:alpine          # Tải Nginx Alpine

# Xem images đã tải
docker images                     # Liệt kê tất cả images
docker images -a                  # Liệt kê tất cả images (kể cả dangling)
docker images --filter "dangling=true"  # Chỉ hiển thị dangling images
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"  # Format output
```

### Quản lý Images
```bash
# Xóa images
docker rmi <image_id>             # Xóa image theo ID
docker rmi <image_name>:<tag>     # Xóa image theo tên và tag
docker rmi $(docker images -q)    # Xóa tất cả images
docker rmi $(docker images -f "dangling=true" -q)  # Xóa dangling images
docker image prune                # Xóa unused images
docker image prune -a             # Xóa tất cả unused images

# Tag images
docker tag <image_id> <new_name>:<tag>  # Tạo tag mới cho image
docker tag nginx:latest my-nginx:v1.0   # Tag nginx:latest thành my-nginx:v1.0

# Inspect image
docker inspect <image_name>       # Xem thông tin chi tiết image
docker history <image_name>       # Xem lịch sử layers của image
```

---

## Quản lý Containers

### Tạo và chạy Containers
```bash
# Chạy container
docker run <image_name>           # Chạy container từ image
docker run -d <image_name>        # Chạy container ở background (detached)
docker run -it <image_name>       # Chạy container interactive với terminal
docker run --name <container_name> <image_name>  # Đặt tên cho container
docker run -p <host_port>:<container_port> <image_name>  # Port mapping
docker run -v <host_path>:<container_path> <image_name>  # Volume mounting
docker run -e <env_var>=<value> <image_name>     # Set environment variable

# Ví dụ cụ thể
docker run -d --name web-server -p 8080:80 nginx  # Chạy Nginx trên port 8080
docker run -it --name ubuntu-container ubuntu:20.04 bash  # Chạy Ubuntu interactive
docker run -d --name mysql-db -e MYSQL_ROOT_PASSWORD=secret mysql:8.0  # MySQL với password
```

### Quản lý Containers
```bash
# Xem containers
docker ps                         # Xem containers đang chạy
docker ps -a                      # Xem tất cả containers (kể cả stopped)
docker ps -q                      # Chỉ hiển thị container IDs
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"  # Format output

# Dừng và khởi động containers
docker start <container_name>     # Khởi động container đã dừng
docker stop <container_name>      # Dừng container gracefully
docker restart <container_name>   # Khởi động lại container
docker kill <container_name>      # Force kill container
docker pause <container_name>     # Tạm dừng container
docker unpause <container_name>   # Tiếp tục container đã pause

# Xóa containers
docker rm <container_name>        # Xóa container đã dừng
docker rm -f <container_name>     # Force xóa container (kể cả đang chạy)
docker rm $(docker ps -aq)        # Xóa tất cả containers
docker container prune            # Xóa stopped containers
```

### Tương tác với Containers
```bash
# Truy cập container
docker exec -it <container_name> <command>  # Chạy command trong container
docker exec -it <container_name> bash       # Truy cập bash shell
docker exec -it <container_name> sh         # Truy cập sh shell
docker attach <container_name>              # Attach vào container

# Copy files
docker cp <container_name>:<container_path> <host_path>  # Copy từ container ra host
docker cp <host_path> <container_name>:<container_path>  # Copy từ host vào container
docker cp web-server:/var/log/nginx/access.log ./nginx.log  # Copy log file

# Xem logs
docker logs <container_name>      # Xem logs của container
docker logs -f <container_name>   # Follow logs real-time
docker logs --tail 100 <container_name>  # Xem 100 dòng cuối
docker logs --since "2023-01-01" <container_name>  # Logs từ ngày cụ thể
```

---

## Dockerfile

### Cú pháp cơ bản
```dockerfile
# FROM - Chỉ định base image
FROM ubuntu:20.04

# LABEL - Thêm metadata
LABEL maintainer="your-email@example.com"
LABEL version="1.0"

# ENV - Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV APP_HOME=/app

# WORKDIR - Set working directory
WORKDIR $APP_HOME

# RUN - Chạy commands trong build process
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# COPY - Copy files từ host vào container
COPY requirements.txt .
COPY src/ ./src/

# ADD - Tương tự COPY nhưng hỗ trợ URL và auto-extract
ADD https://example.com/file.tar.gz /tmp/

# EXPOSE - Khai báo port mà container sẽ listen
EXPOSE 8080

# VOLUME - Tạo mount point
VOLUME ["/data"]

# USER - Chuyển sang user khác
USER appuser

# CMD - Default command khi chạy container
CMD ["python3", "app.py"]

# ENTRYPOINT - Entry point command (khó override hơn CMD)
ENTRYPOINT ["python3"]
CMD ["app.py"]
```

### Multi-stage Build
```dockerfile
# Build stage
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Production stage
FROM node:16-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
```

### Build và tối ưu hóa
```bash
# Build image
docker build -t <image_name> .                    # Build từ Dockerfile trong thư mục hiện tại
docker build -t <image_name>:<tag> .              # Build với tag
docker build -f <dockerfile_path> -t <image_name> .  # Build với Dockerfile khác
docker build --no-cache -t <image_name> .         # Build không dùng cache

# Build với build args
docker build --build-arg <arg_name>=<value> -t <image_name> .

# Build multi-platform
docker buildx build --platform linux/amd64,linux/arm64 -t <image_name> .

# Xem build history
docker history <image_name>                       # Xem layers của image
```

---

## Docker Compose

### Cấu trúc file docker-compose.yml
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    container_name: web-server
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    environment:
      - NGINX_HOST=localhost
    depends_on:
      - db
    networks:
      - app-network

  db:
    image: mysql:8.0
    container_name: mysql-db
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: myapp
      MYSQL_USER: user
      MYSQL_PASSWORD: password
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - app-network

  redis:
    image: redis:alpine
    container_name: redis-cache
    networks:
      - app-network

volumes:
  mysql_data:

networks:
  app-network:
    driver: bridge
```

### Docker Compose Commands
```bash
# Quản lý services
docker-compose up                 # Khởi động tất cả services
docker-compose up -d              # Khởi động ở background
docker-compose up <service_name>  # Khởi động service cụ thể
docker-compose down               # Dừng và xóa tất cả services
docker-compose stop               # Dừng services (không xóa)
docker-compose start              # Khởi động services đã dừng
docker-compose restart            # Khởi động lại services

# Build và rebuild
docker-compose build              # Build images
docker-compose build --no-cache   # Build không dùng cache
docker-compose up --build         # Build và khởi động

# Xem logs và status
docker-compose logs               # Xem logs tất cả services
docker-compose logs <service>     # Xem logs service cụ thể
docker-compose logs -f            # Follow logs
docker-compose ps                 # Xem trạng thái services
docker-compose top                # Xem processes trong containers

# Scale services
docker-compose up --scale <service>=<count>  # Scale service
docker-compose up --scale web=3              # Chạy 3 instances của web service
```

---

## Docker Networks

### Quản lý Networks
```bash
# Xem networks
docker network ls                 # Liệt kê tất cả networks
docker network inspect <network>  # Xem thông tin chi tiết network

# Tạo và xóa networks
docker network create <network_name>                    # Tạo network
docker network create --driver bridge <network_name>    # Tạo bridge network
docker network create --driver overlay <network_name>   # Tạo overlay network
docker network rm <network_name>                        # Xóa network
docker network prune                                    # Xóa unused networks

# Kết nối containers với network
docker network connect <network> <container>            # Kết nối container với network
docker network disconnect <network> <container>         # Ngắt kết nối

# Chạy container với network cụ thể
docker run --network <network_name> <image_name>        # Chạy container trong network
docker run --network host <image_name>                  # Sử dụng host network
docker run --network none <image_name>                  # Không có network
```

### Network Types
```bash
# Bridge network (default)
docker network create --driver bridge my-bridge

# Host network
docker run --network host nginx  # Container sử dụng network của host

# Overlay network (cho Swarm)
docker network create --driver overlay my-overlay

# Macvlan network
docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 -o parent=eth0 my-macvlan
```

---

## Docker Volumes

### Quản lý Volumes
```bash
# Xem volumes
docker volume ls                  # Liệt kê tất cả volumes
docker volume inspect <volume>    # Xem thông tin chi tiết volume

# Tạo và xóa volumes
docker volume create <volume_name>     # Tạo volume
docker volume rm <volume_name>         # Xóa volume
docker volume prune                    # Xóa unused volumes

# Mount volumes
docker run -v <volume_name>:<container_path> <image>  # Named volume
docker run -v <host_path>:<container_path> <image>    # Bind mount
docker run -v <host_path>:<container_path>:ro <image> # Read-only mount

# Ví dụ
docker run -v mysql_data:/var/lib/mysql mysql:8.0     # Named volume
docker run -v /home/user/data:/app/data nginx         # Bind mount
```

### Volume Types
```bash
# Named volumes (quản lý bởi Docker)
docker volume create my-data
docker run -v my-data:/data alpine

# Bind mounts (mount trực tiếp từ host)
docker run -v /host/path:/container/path alpine

# tmpfs mounts (in-memory)
docker run --tmpfs /tmp alpine

# Volume với Docker Compose
# Trong docker-compose.yml:
volumes:
  - ./data:/app/data              # Bind mount
  - db_data:/var/lib/mysql        # Named volume
```

---

## Docker Registry

### Docker Hub
```bash
# Login vào Docker Hub
docker login                      # Login vào Docker Hub
docker logout                     # Logout khỏi Docker Hub

# Push và pull images
docker tag <image> <username>/<repository>:<tag>  # Tag image cho Docker Hub
docker push <username>/<repository>:<tag>         # Push image lên Docker Hub
docker pull <username>/<repository>:<tag>         # Pull image từ Docker Hub

# Ví dụ
docker tag my-app:latest john/my-app:v1.0
docker push john/my-app:v1.0
```

### Private Registry
```bash
# Chạy private registry
docker run -d -p 5000:5000 --name registry registry:2

# Tag và push vào private registry
docker tag my-app:latest localhost:5000/my-app:latest
docker push localhost:5000/my-app:latest

# Pull từ private registry
docker pull localhost:5000/my-app:latest
```

---

## Monitoring và Debugging

### Container Monitoring
```bash
# Xem resource usage
docker stats                       # Xem resource usage real-time
docker stats <container_name>      # Xem stats của container cụ thể
docker stats --no-stream           # Xem stats một lần

# Xem processes trong container
docker top <container_name>        # Xem processes trong container
docker exec <container_name> ps aux  # Xem processes với ps

# Inspect container
docker inspect <container_name>    # Xem thông tin chi tiết container
docker inspect --format='{{.State.Status}}' <container_name>  # Chỉ xem status

# Xem logs
docker logs <container_name>       # Xem logs
docker logs -f <container_name>    # Follow logs
docker logs --tail 50 <container_name>  # 50 dòng cuối
```

### Debugging
```bash
# Truy cập container đang chạy
docker exec -it <container_name> bash  # Truy cập bash
docker exec -it <container_name> sh    # Truy cập sh

# Debug container đã dừng
docker run -it --rm <image_name> bash  # Chạy container mới để debug

# Xem changes trong container
docker diff <container_name>       # Xem file changes

# Export/Import container
docker export <container_name> > container.tar  # Export container
docker import container.tar <image_name>        # Import thành image
```

---

## Docker Security

### Security Best Practices
```bash
# Chạy container với user không phải root
docker run --user 1000:1000 <image_name>  # Chạy với UID:GID cụ thể
docker run --user $(id -u):$(id -g) <image_name>  # Chạy với user hiện tại

# Giới hạn resources
docker run --memory=512m --cpus=1 <image_name>  # Giới hạn RAM và CPU
docker run --memory-swap=1g <image_name>        # Giới hạn swap

# Read-only filesystem
docker run --read-only <image_name>              # Chạy với read-only filesystem
docker run --read-only --tmpfs /tmp <image_name> # Read-only với tmpfs cho /tmp

# Security options
docker run --security-opt no-new-privileges <image_name>  # Không cho phép privilege escalation
docker run --cap-drop ALL --cap-add NET_BIND_SERVICE <image_name>  # Drop tất cả capabilities, chỉ giữ lại cần thiết

# Network security
docker run --network none <image_name>           # Không có network access
docker run -p 127.0.0.1:8080:80 <image_name>    # Chỉ bind localhost
```

### Image Security
```bash
# Scan image cho vulnerabilities
docker scan <image_name>          # Scan image (cần Docker Scout)
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image <image_name>  # Scan với Trivy

# Xem layers của image
docker history <image_name>       # Xem layers và commands
docker image inspect <image_name> # Xem metadata chi tiết
```

---

## Docker Swarm

### Swarm Management
```bash
# Khởi tạo Swarm
docker swarm init                  # Khởi tạo Swarm cluster
docker swarm init --advertise-addr <ip>  # Khởi tạo với IP cụ thể

# Join nodes
docker swarm join-token worker    # Lấy token cho worker nodes
docker swarm join-token manager   # Lấy token cho manager nodes
docker swarm join <token>         # Join node vào Swarm

# Quản lý Swarm
docker node ls                    # Xem tất cả nodes
docker node inspect <node_id>     # Xem thông tin node
docker node rm <node_id>          # Xóa node khỏi Swarm
docker swarm leave                # Rời khỏi Swarm
docker swarm leave --force        # Force leave

# Deploy services
docker service create --name <service_name> <image>  # Tạo service
docker service ls                 # Xem services
docker service ps <service_name>  # Xem tasks của service
docker service scale <service_name>=<replicas>  # Scale service
docker service rm <service_name>  # Xóa service
```

### Stack Deployment
```bash
# Deploy stack từ docker-compose.yml
docker stack deploy -c docker-compose.yml <stack_name>

# Quản lý stacks
docker stack ls                   # Xem stacks
docker stack services <stack_name>  # Xem services trong stack
docker stack ps <stack_name>      # Xem tasks trong stack
docker stack rm <stack_name>      # Xóa stack
```

---

## Tips và Best Practices

### Performance Optimization
```bash
# Multi-stage builds để giảm image size
# Sử dụng .dockerignore để loại trừ files không cần thiết
# Sử dụng specific tags thay vì 'latest'
# Combine RUN commands để giảm layers
# Sử dụng Alpine images cho production

# Clean up
docker system prune               # Xóa unused data
docker system prune -a            # Xóa tất cả unused data
docker system df                  # Xem disk usage
```

### Useful Aliases
```bash
# Thêm vào ~/.bashrc hoặc ~/.zshrc
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dstop='docker stop'
alias drm='docker rm'
alias drmi='docker rmi'
alias dclean='docker system prune -f'
```

### One-liners hữu ích
```bash
# Xóa tất cả containers đã dừng
docker container prune -f

# Xóa tất cả images không được sử dụng
docker image prune -a -f

# Xem top 10 containers sử dụng nhiều RAM nhất
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | sort -k3 -hr | head -10

# Backup tất cả volumes
docker run --rm -v /var/lib/docker/volumes:/backup -v $(pwd):/output alpine tar czf /output/volumes-backup.tar.gz /backup

# Xem logs của tất cả containers
docker logs $(docker ps -q)

# Restart tất cả containers
docker restart $(docker ps -q)

# Xem size của images
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | sort -k3 -hr
```

### Dockerfile Best Practices
```dockerfile
# 1. Sử dụng specific tags
FROM node:16-alpine

# 2. Sử dụng .dockerignore
# .dockerignore
node_modules
npm-debug.log
.git
.gitignore
README.md
.env

# 3. Combine RUN commands
RUN apt-get update && \
    apt-get install -y python3 && \
    rm -rf /var/lib/apt/lists/*

# 4. Sử dụng non-root user
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# 5. Expose ports
EXPOSE 8080

# 6. Sử dụng HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# 7. Sử dụng CMD thay vì RUN cho commands cuối
CMD ["node", "app.js"]
```

---

## 📚 Tài liệu tham khảo

- [Docker Official Documentation](https://docs.docker.com/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

---

## 🔧 Troubleshooting

### Common Issues
```bash
# Container không start
docker logs <container_name>      # Xem logs để debug
docker inspect <container_name>   # Xem config chi tiết

# Permission denied
sudo chown -R $USER:$USER ~/.docker  # Fix Docker permissions

# Port already in use
sudo lsof -i :<port>              # Tìm process đang dùng port
sudo kill -9 <PID>                # Kill process

# Out of space
docker system prune -a            # Clean up unused data
docker volume prune               # Clean up unused volumes

# Network issues
docker network ls                 # Xem networks
docker network inspect <network>  # Debug network config
```

---

*Cheatsheet này được tạo để hỗ trợ các DevOps engineers làm việc với Docker. Hãy thường xuyên cập nhật và bổ sung thêm các lệnh hữu ích khác!*
