#!/bin/bash

# ====================================
# 服务器环境配置脚本
# Ubuntu 20.04/22.04 LTS
# ====================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${2}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# 更新系统
update_system() {
    print_message "更新系统包..." $BLUE
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y curl wget git unzip htop
    print_message "系统更新完成" $GREEN
}

# 安装Docker
install_docker() {
    if command -v docker &> /dev/null; then
        print_message "Docker已安装，跳过安装" $YELLOW
        return
    fi
    
    print_message "安装Docker..." $BLUE
    
    # 安装依赖
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # 添加Docker官方GPG密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加Docker仓库
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # 将当前用户添加到docker组
    sudo usermod -aG docker $USER
    
    # 启动并启用Docker服务
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_message "Docker安装完成" $GREEN
}

# 安装Docker Compose
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        print_message "Docker Compose已安装，跳过安装" $YELLOW
        return
    fi
    
    print_message "安装Docker Compose..." $BLUE
    
    # 获取最新版本
    local version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    
    # 下载并安装
    sudo curl -L "https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    print_message "Docker Compose安装完成" $GREEN
}

# 安装Nginx（备用）
install_nginx() {
    print_message "安装Nginx（备用）..." $BLUE
    sudo apt install -y nginx
    sudo systemctl stop nginx
    sudo systemctl disable nginx
    print_message "Nginx安装完成（已停用，使用Docker容器版本）" $GREEN
}

# 安装Certbot（SSL证书）
install_certbot() {
    print_message "安装Certbot..." $BLUE
    sudo apt install -y certbot python3-certbot-nginx
    print_message "Certbot安装完成" $GREEN
}

# 配置防火墙
configure_firewall() {
    print_message "配置防火墙..." $BLUE
    
    # 启用UFW
    sudo ufw --force enable
    
    # 允许SSH
    sudo ufw allow ssh
    
    # 允许HTTP和HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # 显示状态
    sudo ufw status
    
    print_message "防火墙配置完成" $GREEN
}

# 创建项目用户
create_project_user() {
    local username="roi-frontend"
    
    if id "$username" &>/dev/null; then
        print_message "用户 $username 已存在，跳过创建" $YELLOW
        return
    fi
    
    print_message "创建项目用户..." $BLUE
    
    # 创建用户
    sudo useradd -m -s /bin/bash $username
    
    # 将用户添加到docker组
    sudo usermod -aG docker $username
    
    # 创建项目目录
    sudo mkdir -p /opt/roi-frontend
    sudo chown $username:$username /opt/roi-frontend
    
    print_message "项目用户创建完成" $GREEN
}

# 配置SSH密钥（如果提供）
setup_ssh_key() {
    local username="roi-frontend"
    
    if [ ! -z "$SSH_PUBLIC_KEY" ]; then
        print_message "配置SSH密钥..." $BLUE
        
        sudo mkdir -p /home/$username/.ssh
        echo "$SSH_PUBLIC_KEY" | sudo tee /home/$username/.ssh/authorized_keys
        sudo chown -R $username:$username /home/$username/.ssh
        sudo chmod 700 /home/$username/.ssh
        sudo chmod 600 /home/$username/.ssh/authorized_keys
        
        print_message "SSH密钥配置完成" $GREEN
    fi
}

# 优化系统性能
optimize_system() {
    print_message "优化系统性能..." $BLUE
    
    # 增加文件描述符限制
    echo '*               soft    nofile          65536' | sudo tee -a /etc/security/limits.conf
    echo '*               hard    nofile          65536' | sudo tee -a /etc/security/limits.conf
    
    # 优化内核参数
    sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
# 网络优化
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr

# 文件系统优化
fs.file-max = 2097152
vm.swappiness = 10
EOF
    
    sudo sysctl -p
    
    print_message "系统优化完成" $GREEN
}

# 安装监控工具
install_monitoring() {
    print_message "安装监控工具..." $BLUE
    
    # 安装htop, iotop, nethogs
    sudo apt install -y htop iotop nethogs
    
    # 安装Docker监控工具
    sudo curl -L "https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64" -o /usr/local/bin/ctop
    sudo chmod +x /usr/local/bin/ctop
    
    print_message "监控工具安装完成" $GREEN
}

# 配置日志轮转
configure_log_rotation() {
    print_message "配置日志轮转..." $BLUE
    
    sudo tee /etc/logrotate.d/roi-frontend > /dev/null <<EOF
/opt/roi-frontend/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 roi-frontend roi-frontend
    postrotate
        docker-compose -f /opt/roi-frontend/docker-compose.prod.yml exec frontend nginx -s reload 2>/dev/null || true
    endscript
}
EOF
    
    print_message "日志轮转配置完成" $GREEN
}

# 设置定时备份
setup_backup_cron() {
    print_message "设置定时备份..." $BLUE
    
    # 创建备份脚本
    sudo tee /opt/roi-frontend/backup.sh > /dev/null <<'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/roi-frontend"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份Docker镜像
docker save roi-frontend:latest | gzip > $BACKUP_DIR/roi-frontend_$TIMESTAMP.tar.gz

# 备份配置文件
tar -czf $BACKUP_DIR/config_$TIMESTAMP.tar.gz -C /opt/roi-frontend \
    docker-compose.prod.yml nginx.prod.conf

# 清理超过7天的备份
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

# 日志
echo "$(date): Backup completed" >> /var/log/roi-frontend-backup.log
EOF
    
    sudo chmod +x /opt/roi-frontend/backup.sh
    sudo chown roi-frontend:roi-frontend /opt/roi-frontend/backup.sh
    
    # 添加到crontab
    echo "0 3 * * * /opt/roi-frontend/backup.sh" | sudo crontab -u roi-frontend -
    
    print_message "定时备份设置完成" $GREEN
}

# 显示完成信息
show_completion_info() {
    print_message "=== 服务器环境配置完成 ===" $GREEN
    echo ""
    print_message "📋 已安装的软件:" $BLUE
    echo "  ✓ Docker $(docker --version 2>/dev/null || echo 'Not installed')"
    echo "  ✓ Docker Compose $(docker-compose --version 2>/dev/null || echo 'Not installed')"
    echo "  ✓ Nginx $(nginx -v 2>&1 || echo 'Not installed')"
    echo "  ✓ Certbot $(certbot --version 2>/dev/null || echo 'Not installed')"
    echo ""
    print_message "🔧 配置完成:" $BLUE
    echo "  ✓ 防火墙配置"
    echo "  ✓ 项目用户创建"
    echo "  ✓ 系统优化"
    echo "  ✓ 监控工具"
    echo "  ✓ 日志轮转"
    echo "  ✓ 定时备份"
    echo ""
    print_message "📝 下一步:" $BLUE
    echo "  1. 重启服务器以应用所有更改"
    echo "  2. 使用 roi-frontend 用户登录"
    echo "  3. 克隆项目代码到 /opt/roi-frontend"
    echo "  4. 运行部署脚本"
    echo ""
    print_message "🔐 重要提醒:" $YELLOW
    echo "  - 请重新登录以使Docker组权限生效"
    echo "  - 确保已配置SSH密钥访问"
    echo "  - 建议重启服务器"
    echo ""
}

# 主函数
main() {
    print_message "开始配置ROI Frontend服务器环境..." $BLUE
    
    update_system
    install_docker
    install_docker_compose
    install_nginx
    install_certbot
    configure_firewall
    create_project_user
    setup_ssh_key
    optimize_system
    install_monitoring
    configure_log_rotation
    setup_backup_cron
    
    show_completion_info
    
    print_message "服务器环境配置完成！建议重启服务器。" $GREEN
}

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   print_message "此脚本需要root权限运行" $RED
   print_message "请使用: sudo $0" $RED
   exit 1
fi

# 执行主函数
main "$@"