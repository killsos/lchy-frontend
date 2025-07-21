# 🚀 ROI Frontend 服务器部署完整指南

## 📋 目录

1. [服务器要求](#服务器要求)
2. [快速部署](#快速部署)
3. [详细部署步骤](#详细部署步骤)
4. [CI/CD自动部署](#cicd自动部署)
5. [SSL证书配置](#ssl证书配置)
6. [监控和维护](#监控和维护)
7. [故障排除](#故障排除)
8. [安全最佳实践](#安全最佳实践)

## 🖥️ 服务器要求

### 最低配置
- **CPU**: 2核心
- **内存**: 4GB RAM
- **存储**: 20GB SSD
- **系统**: Ubuntu 20.04/22.04 LTS
- **网络**: 公网IP，开放80/443端口

### 推荐配置
- **CPU**: 4核心+
- **内存**: 8GB+ RAM
- **存储**: 40GB+ SSD
- **带宽**: 100Mbps+

## ⚡ 快速部署

### 1. 一键环境配置

```bash
# 在服务器上运行（需要root权限）
wget https://raw.githubusercontent.com/your-repo/roi-frontend/main/server-setup.sh
sudo chmod +x server-setup.sh
sudo ./server-setup.sh
```

### 2. 部署应用

```bash
# 切换到项目用户
sudo su - roi-frontend

# 克隆项目
git clone https://github.com/your-repo/roi-frontend.git /opt/roi-frontend
cd /opt/roi-frontend

# 设置环境变量
export DOMAIN_NAME="your-domain.com"
export SSL_EMAIL="admin@your-domain.com"

# 一键部署
./deploy-server.sh deploy
```

## 📖 详细部署步骤

### 步骤1: 准备服务器环境

#### 1.1 连接到服务器
```bash
ssh root@your-server-ip
```

#### 1.2 更新系统
```bash
apt update && apt upgrade -y
```

#### 1.3 运行环境配置脚本
```bash
curl -sSL https://raw.githubusercontent.com/your-repo/roi-frontend/main/server-setup.sh | sudo bash
```

### 步骤2: 配置域名和DNS

#### 2.1 DNS记录配置
```
A     @              your-server-ip
A     www            your-server-ip
AAAA  @              your-ipv6-address (可选)
```

#### 2.2 验证DNS解析
```bash
nslookup your-domain.com
```

### 步骤3: 部署应用

#### 3.1 克隆项目代码
```bash
# 切换到项目用户
sudo su - roi-frontend

# 克隆代码
git clone https://github.com/your-repo/roi-frontend.git /opt/roi-frontend
cd /opt/roi-frontend
```

#### 3.2 配置环境变量
```bash
# 创建环境变量文件
cat > .env.production << EOF
DOMAIN_NAME=your-domain.com
SSL_EMAIL=admin@your-domain.com
BACKEND_API_URL=https://api.your-domain.com
EOF

# 加载环境变量
source .env.production
```

#### 3.3 执行部署
```bash
./deploy-server.sh deploy
```

### 步骤4: 验证部署

#### 4.1 检查服务状态
```bash
docker-compose -f docker-compose.prod.yml ps
```

#### 4.2 测试应用访问
```bash
# 健康检查
curl -f http://your-domain.com/health

# 检查网站
curl -I http://your-domain.com
```

## 🔄 CI/CD自动部署

### 配置GitHub Actions

#### 1. 添加Repository Secrets

在GitHub仓库设置中添加以下secrets：

```bash
SERVER_HOST=your-server-ip
SERVER_USER=roi-frontend
SERVER_SSH_KEY=-----BEGIN OPENSSH PRIVATE KEY-----...
DOMAIN_NAME=your-domain.com
SSL_EMAIL=admin@your-domain.com
SLACK_WEBHOOK_URL=https://hooks.slack.com/... (可选)
```

#### 2. 生成SSH密钥对

```bash
# 在本地生成密钥对
ssh-keygen -t ed25519 -C "github-actions" -f ./github-actions-key

# 将公钥添加到服务器
ssh-copy-id -i ./github-actions-key.pub roi-frontend@your-server-ip

# 将私钥添加到GitHub Secrets (SERVER_SSH_KEY)
cat ./github-actions-key
```

#### 3. 推送代码触发部署

```bash
git add .
git commit -m "feat: deploy to production"
git push origin main
```

### 手动触发部署

在GitHub Actions页面可以手动触发部署工作流。

## 🔐 SSL证书配置

### 自动SSL证书（Let's Encrypt）

部署脚本会自动配置SSL证书：

```bash
# 确保域名已正确解析到服务器IP
# 设置环境变量
export DOMAIN_NAME="your-domain.com"
export SSL_EMAIL="admin@your-domain.com"

# 运行部署脚本（会自动配置SSL）
./deploy-server.sh deploy
```

### 手动SSL证书配置

如果需要使用自己的SSL证书：

```bash
# 将证书文件放置到ssl目录
mkdir -p ssl
cp your-cert.pem ssl/cert.pem
cp your-key.pem ssl/key.pem

# 确保权限正确
chmod 600 ssl/*.pem
chown roi-frontend:roi-frontend ssl/*.pem

# 重新部署
./deploy-server.sh restart
```

### SSL证书续期

Let's Encrypt证书会通过cron自动续期：

```bash
# 查看续期任务
sudo crontab -l

# 手动测试续期
sudo certbot renew --dry-run
```

## 📊 监控和维护

### 服务监控

#### 1. 查看服务状态
```bash
# 容器状态
docker-compose -f docker-compose.prod.yml ps

# 资源使用
docker stats

# 详细监控
ctop
```

#### 2. 查看日志
```bash
# 应用日志
docker-compose -f docker-compose.prod.yml logs -f

# Nginx访问日志
tail -f logs/access.log

# 错误日志
tail -f logs/error.log
```

#### 3. 健康检查
```bash
# 自动健康检查
./deploy-server.sh status

# 手动检查
curl -f http://your-domain.com/health
```

### 性能监控

#### 1. 系统资源
```bash
# CPU和内存
htop

# 磁盘使用
df -h

# 网络连接
ss -tuln
```

#### 2. 应用性能
```bash
# Nginx状态
curl http://your-domain.com/nginx_status

# 响应时间测试
curl -w "@curl-format.txt" -o /dev/null -s http://your-domain.com/
```

### 备份管理

#### 1. 自动备份
```bash
# 查看备份文件
ls -la /var/backups/roi-frontend/

# 手动备份
./deploy-server.sh backup
```

#### 2. 恢复备份
```bash
# 查看可用备份
docker images roi-frontend

# 回滚到指定版本
docker tag roi-frontend:backup_20240120_030000 roi-frontend:latest
./deploy-server.sh restart
```

## 🔧 故障排除

### 常见问题

#### 1. 服务无法启动

```bash
# 检查容器状态
docker-compose -f docker-compose.prod.yml ps

# 查看详细错误
docker-compose -f docker-compose.prod.yml logs

# 检查端口占用
sudo netstat -tulnp | grep :80
```

#### 2. SSL证书问题

```bash
# 检查证书文件
ls -la ssl/

# 测试SSL配置
openssl s_client -connect your-domain.com:443

# 重新申请证书
sudo certbot delete --cert-name your-domain.com
sudo certbot certonly --standalone -d your-domain.com
```

#### 3. 域名解析问题

```bash
# 检查DNS解析
nslookup your-domain.com
dig your-domain.com

# 测试连接
ping your-domain.com
telnet your-domain.com 80
```

#### 4. 性能问题

```bash
# 检查资源使用
docker stats
htop

# 检查磁盘空间
df -h

# 清理Docker资源
docker system prune -a
```

### 日志分析

#### 1. Nginx错误日志
```bash
# 查看错误日志
tail -f logs/error.log

# 常见错误模式
grep "error" logs/error.log | tail -20
```

#### 2. 应用日志
```bash
# 实时日志
docker-compose -f docker-compose.prod.yml logs -f frontend

# 错误过滤
docker-compose -f docker-compose.prod.yml logs frontend | grep -i error
```

### 紧急恢复

#### 1. 快速回滚
```bash
# 停止当前服务
docker-compose -f docker-compose.prod.yml down

# 使用备份镜像
docker tag roi-frontend:backup_latest roi-frontend:latest

# 重新启动
docker-compose -f docker-compose.prod.yml up -d
```

#### 2. 从备份恢复
```bash
# 查看备份
ls /var/backups/roi-frontend/

# 恢复镜像
gunzip -c /var/backups/roi-frontend/backup_20240120.tar.gz | docker load

# 重新部署
./deploy-server.sh restart
```

## 🛡️ 安全最佳实践

### 1. 服务器安全

#### 防火墙配置
```bash
# 查看防火墙状态
sudo ufw status

# 只允许必要端口
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

#### SSH安全
```bash
# 禁用密码登录（推荐使用密钥）
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# 更改SSH端口（可选）
sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
```

### 2. 应用安全

#### 安全头配置
已在 `nginx.prod.conf` 中配置：
- X-Frame-Options
- X-XSS-Protection
- X-Content-Type-Options
- Content-Security-Policy
- Strict-Transport-Security

#### 访问控制
```bash
# 限制管理接口访问
# 在nginx.prod.conf中配置IP白名单
location /admin {
    allow 192.168.1.0/24;
    deny all;
}
```

### 3. 数据安全

#### 定期备份
```bash
# 设置定期备份（已自动配置）
crontab -l

# 测试备份脚本
/opt/roi-frontend/backup.sh
```

#### 敏感信息保护
```bash
# 确保环境变量文件权限
chmod 600 .env.production

# 不要在代码中硬编码密钥
# 使用环境变量或密钥管理服务
```

## 📞 技术支持

### 获取帮助

1. **查看日志**: 首先检查应用和系统日志
2. **健康检查**: 运行内置的健康检查命令
3. **社区支持**: 提交GitHub Issues
4. **文档查阅**: 参考官方文档

### 联系信息

- **项目仓库**: https://github.com/your-repo/roi-frontend
- **问题反馈**: GitHub Issues
- **技术文档**: 项目Wiki

---

**最后更新**: 2025-01-20  
**版本**: v1.0.0  
**维护者**: Your Team

---

> 💡 **提示**: 部署前请仔细阅读此文档，确保理解每个步骤。如有疑问，请先查看故障排除章节。