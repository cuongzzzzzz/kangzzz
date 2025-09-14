# Tình huống 6: Docker Issues - Container Không Hoạt Động

## 🚨 Mô tả tình huống
- Docker containers không start được
- Containers bị crash liên tục
- Docker daemon không hoạt động
- Images không pull được
- Ports không accessible từ bên ngoài
- Volumes không mount được

## 🔍 Các bước chẩn đoán

### Bước 1: Kiểm tra Docker daemon
```bash
# Kiểm tra Docker service status
sudo systemctl status docker
sudo systemctl is-active docker

# Kiểm tra Docker daemon
docker version
docker info

# Kiểm tra Docker logs
sudo journalctl -u docker
sudo journalctl -u docker -f
```

### Bước 2: Kiểm tra containers
```bash
# Xem tất cả containers
docker ps -a
docker container ls -a

# Xem containers đang chạy
docker ps
docker container ls

# Xem container logs
docker logs <container_name>
docker logs -f <container_name>
docker logs --tail 100 <container_name>
```

### Bước 3: Kiểm tra images và volumes
```bash
# Xem images
docker images
docker image ls

# Xem volumes
docker volume ls
docker volume inspect <volume_name>

# Xem networks
docker network ls
docker network inspect <network_name>
```

## 🛠️ Các nguyên nhân thường gặp và cách giải quyết

### 1. Docker daemon không hoạt động
```bash
# Restart Docker service
sudo systemctl restart docker
sudo systemctl start docker

# Enable Docker auto-start
sudo systemctl enable docker

# Kiểm tra Docker daemon config
sudo nano /etc/docker/daemon.json

# Restart Docker daemon
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 2. Container không start được
```bash
# Xem container logs để debug
docker logs <container_name>

# Start container với interactive mode
docker run -it <image_name> /bin/bash

# Start container với specific command
docker run <image_name> <command>

# Start container với environment variables
docker run -e <ENV_VAR>=<value> <image_name>

# Start container với port mapping
docker run -p <host_port>:<container_port> <image_name>
```

### 3. Container bị crash liên tục
```bash
# Xem container logs
docker logs <container_name>

# Xem container details
docker inspect <container_name>

# Start container với restart policy
docker run --restart=always <image_name>

# Start container với resource limits
docker run --memory=512m --cpus=1 <image_name>

# Debug container
docker run --rm -it <image_name> /bin/bash
```

### 4. Port không accessible
```bash
# Kiểm tra port mapping
docker port <container_name>

# Start container với port mapping
docker run -p 80:80 <image_name>
docker run -p 8080:80 <image_name>

# Kiểm tra ports đang listen
netstat -tulpn | grep :80
ss -tulpn | grep :80

# Test port connectivity
telnet localhost 80
curl localhost:80
```

### 5. Volume không mount được
```bash
# Kiểm tra volume exists
docker volume ls
docker volume inspect <volume_name>

# Create volume nếu cần
docker volume create <volume_name>

# Mount volume
docker run -v <volume_name>:/data <image_name>
docker run -v /host/path:/container/path <image_name>

# Kiểm tra volume mount
docker inspect <container_name> | grep -A 10 "Mounts"
```

### 6. Network issues
```bash
# Kiểm tra Docker networks
docker network ls
docker network inspect bridge

# Create custom network
docker network create <network_name>

# Connect container to network
docker run --network <network_name> <image_name>
docker network connect <network_name> <container_name>

# Test network connectivity
docker exec <container_name> ping <other_container>
```

## 🚀 Các lệnh khôi phục nhanh

### Emergency Docker recovery
```bash
# 1. Restart Docker service
sudo systemctl restart docker

# 2. Clean up unused resources
docker system prune -f
docker container prune -f
docker image prune -f
docker volume prune -f

# 3. Restart containers
docker restart $(docker ps -q)

# 4. Rebuild images nếu cần
docker build -t <image_name> .
```

### Container recovery
```bash
# Stop và remove container có vấn đề
docker stop <container_name>
docker rm <container_name>

# Start container mới
docker run -d --name <container_name> <image_name>

# Start container với proper config
docker run -d \
  --name <container_name> \
  -p 80:80 \
  -v <volume_name>:/data \
  -e <ENV_VAR>=<value> \
  <image_name>
```

### Image recovery
```bash
# Pull image mới
docker pull <image_name>:latest

# Remove old image
docker rmi <image_name>:old

# Rebuild image
docker build -t <image_name> .
docker build --no-cache -t <image_name> .
```

## 📊 Monitoring và Analysis

### Docker monitoring
```bash
# Monitor Docker resources
docker stats
docker stats --no-stream

# Monitor specific container
docker stats <container_name>

# Monitor Docker events
docker events
docker events --filter container=<container_name>
```

### Container debugging
```bash
# Xem container processes
docker top <container_name>

# Execute command trong container
docker exec -it <container_name> /bin/bash
docker exec -it <container_name> sh

# Copy files từ/đến container
docker cp <container_name>:/path/to/file /host/path
docker cp /host/path <container_name>:/container/path
```

### Log analysis
```bash
# Xem container logs
docker logs <container_name>
docker logs -f <container_name>
docker logs --since="1h" <container_name>

# Xem Docker daemon logs
sudo journalctl -u docker
sudo journalctl -u docker -f

# Xem system logs
sudo journalctl -f
```

## 🔧 Advanced Solutions

### Docker Compose recovery
```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart <service_name>

# Rebuild và restart
docker-compose up --build -d

# Scale services
docker-compose up --scale <service_name>=3 -d

# View logs
docker-compose logs
docker-compose logs -f <service_name>
```

### Docker Swarm recovery
```bash
# Kiểm tra Swarm status
docker node ls
docker service ls

# Restart service
docker service update --force <service_name>

# Scale service
docker service scale <service_name>=3

# Remove service
docker service rm <service_name>
```

### Resource optimization
```bash
# Set resource limits
docker run --memory=512m --cpus=1 <image_name>

# Set restart policy
docker run --restart=always <image_name>
docker run --restart=on-failure:5 <image_name>

# Set health check
docker run --health-cmd="curl -f http://localhost:80/health" <image_name>
```

## 📝 Checklist khôi phục

- [ ] Kiểm tra Docker daemon status
- [ ] Kiểm tra container logs
- [ ] Kiểm tra image và volume
- [ ] Kiểm tra network configuration
- [ ] Restart Docker service
- [ ] Clean up unused resources
- [ ] Restart containers
- [ ] Test application functionality
- [ ] Monitor Docker performance
- [ ] Document incident và solution

## 🎯 Best Practices

1. **Thiết lập Docker monitoring** và alerts
2. **Use Docker Compose** cho multi-container apps
3. **Implement health checks** cho containers
4. **Set resource limits** để tránh resource exhaustion
5. **Use proper restart policies** cho containers
6. **Backup volumes** và images quan trọng
7. **Monitor Docker logs** thường xuyên
8. **Test container recovery procedures** định kỳ

---

*Tình huống này cần xử lý nhanh để restore containerized applications. Luôn monitor Docker performance và implement proper health checks.*
