# 🐳 ROI Frontend - Docker 部署指南

## 📋 目录结构

```
frontend-project/
├── Dockerfile              # 生产环境 Dockerfile
├── Dockerfile.dev          # 开发环境 Dockerfile
├── docker-compose.yml      # 生产环境编排
├── docker-compose.dev.yml  # 开发环境编排
├── nginx.conf              # Nginx 配置
├── deploy.sh               # 自动化部署脚本
├── .dockerignore           # Docker 忽略文件
└── DOCKER_README.md        # 本文档
```

## 🚀 快速开始

### 1. 一键部署（推荐）

```bash
# 生产环境部署
./deploy.sh prod

# 开发环境部署
./deploy.sh dev

# 仅构建镜像
./deploy.sh build

# 清理所有资源
./deploy.sh clean
```

### 2. 手动部署

#### 生产环境

```bash
# 构建镜像
docker build -t roi-frontend:latest .

# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

#### 开发环境

```bash
# 构建开发镜像
docker build -f Dockerfile.dev -t roi-frontend:dev .

# 启动开发服务
docker-compose -f docker-compose.dev.yml up -d

# 查看日志
docker-compose -f docker-compose.dev.yml logs -f
```

## 📂 详细配置说明

### Dockerfile（生产环境）

- **多阶段构建**：第一阶段构建，第二阶段运行
- **Node.js 18 Alpine**：轻量级基础镜像
- **Nginx Alpine**：高性能 Web 服务器
- **健康检查**：自动监控服务状态
- **安全优化**：非 root 用户运行

### Nginx 配置特性

- ✅ **SPA 路由支持**：Vue Router History 模式
- ✅ **API 代理**：自动转发 `/api/*` 请求
- ✅ **Gzip 压缩**：减少传输大小
- ✅ **静态资源缓存**：优化加载性能
- ✅ **安全头设置**：XSS、CSRF 防护
- ✅ **健康检查端点**：`/health`

### 环境变量配置

```bash
# 生产环境
NODE_ENV=production

# 开发环境
NODE_ENV=development
VITE_API_BASE_URL=http://localhost:8080
```

## 🌐 访问地址

### 生产环境
- **前端应用**: http://localhost
- **健康检查**: http://localhost/health

### 开发环境
- **前端应用**: http://localhost:5173
- **热重载**: 支持实时代码更新

## 🔧 自定义配置

### 1. 修改端口

**生产环境**（docker-compose.yml）:
```yaml
services:
  frontend:
    ports:
      - "8080:80"  # 改为8080端口
```

**开发环境**（docker-compose.dev.yml）:
```yaml
services:
  frontend-dev:
    ports:
      - "3000:5173"  # 改为3000端口
```

### 2. 配置后端API

修改 `nginx.conf` 中的 API 代理：
```nginx
location /api/ {
    proxy_pass http://your-backend-server:8080/;
    # ... 其他配置
}
```

或修改环境变量：
```bash
VITE_API_BASE_URL=https://your-api-domain.com
```

### 3. 添加SSL支持

```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    # ... 其他SSL配置
}
```

## 📊 容器监控

### 查看容器状态
```bash
# 查看运行状态
docker-compose ps

# 查看资源使用
docker stats

# 查看日志
docker-compose logs -f

# 进入容器
docker-compose exec frontend sh
```

### 健康检查
```bash
# 检查服务健康状态
curl http://localhost/health

# 检查响应时间
curl -w "@curl-format.txt" -o /dev/null -s http://localhost/
```

## 🚨 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 查看端口使用情况
   lsof -i :80
   
   # 停止占用进程或更改端口
   ```

2. **构建失败**
   ```bash
   # 清理Docker缓存
   docker system prune -a
   
   # 重新构建
   docker build --no-cache -t roi-frontend:latest .
   ```

3. **服务无法访问**
   ```bash
   # 检查容器状态
   docker-compose ps
   
   # 查看详细日志
   docker-compose logs frontend
   
   # 检查网络连接
   docker network ls
   ```

4. **API请求失败**
   - 检查 `nginx.conf` 中的代理配置
   - 确认后端服务是否正常运行
   - 验证网络连接

### 性能优化

```bash
# 查看镜像大小
docker images roi-frontend

# 分析构建缓存
docker build --progress=plain .

# 监控资源使用
docker stats roi-frontend
```

## 📝 最佳实践

### 1. 生产环境
- ✅ 使用多阶段构建减小镜像大小
- ✅ 启用 Gzip 压缩和缓存
- ✅ 设置资源限制
- ✅ 配置健康检查
- ✅ 使用非 root 用户运行

### 2. 开发环境
- ✅ 挂载源代码目录支持热重载
- ✅ 暴露调试端口
- ✅ 保留 node_modules 卷
- ✅ 使用开发专用配置

### 3. 安全性
- ✅ 定期更新基础镜像
- ✅ 扫描安全漏洞
- ✅ 限制容器权限
- ✅ 使用秘钥管理

## 📈 扩展部署

### 使用 Docker Swarm
```bash
# 初始化 Swarm
docker swarm init

# 部署服务栈
docker stack deploy -c docker-compose.yml roi-app
```

### 使用 Kubernetes
```bash
# 创建部署配置
kubectl create deployment roi-frontend --image=roi-frontend:latest

# 暴露服务
kubectl expose deployment roi-frontend --port=80 --type=LoadBalancer
```

## 🆘 支持

如有问题，请参考：
- [Docker 官方文档](https://docs.docker.com/)
- [Nginx 配置指南](https://nginx.org/en/docs/)
- [Vue.js 部署指南](https://cli.vuejs.org/guide/deployment.html)

---

**最后更新**: 2025-01-20
**Docker 版本**: 20.10+
**Docker Compose 版本**: 2.0+