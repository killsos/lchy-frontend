#!/bin/bash

# ====================================
# ROI Frontend 生产环境部署脚本
# 支持零停机部署、蓝绿部署、自动备份与回滚
# ====================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量 - 可通过环境变量覆盖
PROJECT_NAME="${PROJECT_NAME:-roi-frontend}"
IMAGE_NAME="${IMAGE_NAME:-roi-frontend}"
CONTAINER_NAME="${CONTAINER_NAME:-roi-frontend-prod}"
DOMAIN_NAME="${DOMAIN_NAME:-localhost}"
SSL_EMAIL="${SSL_EMAIL:-admin@example.com}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/roi-frontend}"
LOG_DIR="${LOG_DIR:-./logs}"
NGINX_PORT="${NGINX_PORT:-80}"
NGINX_SSL_PORT="${NGINX_SSL_PORT:-443}"
API_BACKEND_URL="${API_BACKEND_URL:-http://localhost:3200}"

# 蓝绿部署配置
BLUE_CONTAINER="${PROJECT_NAME}-blue"
GREEN_CONTAINER="${PROJECT_NAME}-green"
CURRENT_COLOR_FILE=".current-color"

# 函数：打印带颜色的消息
print_message() {
    echo -e "${2}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# 函数：记录日志
log_message() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    # 确保日志目录存在
    mkdir -p "${LOG_DIR}"
    echo "$message" >> "${LOG_DIR}/deploy.log"
    print_message "$1" "$2"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_message "$1 未安装，请先安装 $1" $RED
        exit 1
    fi
}

# 函数：检查依赖项
check_dependencies() {
    log_message "检查系统依赖项..." $BLUE
    
    check_command "docker"
    check_command "docker-compose"
    check_command "curl"
    check_command "jq"
    
    if ! docker info > /dev/null 2>&1; then
        log_message "Docker未运行，请启动Docker服务" $RED
        exit 1
    fi
    
    # 检查Docker版本
    local docker_version=$(docker --version | grep -o '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*' | head -n1)
    log_message "Docker版本: $docker_version" $GREEN
    
    # 检查可用磁盘空间
    local available_space=$(df . | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 1048576 ]; then  # 小于1GB
        log_message "警告: 可用磁盘空间不足1GB，建议清理空间" $YELLOW
    fi
    
    log_message "依赖项检查完成" $GREEN
}

# 函数：创建必要的目录和文件
setup_environment() {
    log_message "设置部署环境..." $BLUE
    
    # 创建目录
    mkdir -p "$LOG_DIR" "$BACKUP_DIR" "./ssl" "./configs"
    
    # 创建环境文件（如果不存在）
    if [ ! -f ".env.production" ]; then
        cat > .env.production << EOF
# 生产环境配置
NODE_ENV=production
VITE_API_BASE_URL=${API_BACKEND_URL}/api
VITE_BASE_URL=/
EOF
        log_message "创建 .env.production 文件" $GREEN
    fi
    
    # 创建nginx配置（如果不存在）
    if [ ! -f "nginx.prod.conf" ]; then
        create_nginx_config
    fi
    
    log_message "环境设置完成" $GREEN
}

# 函数：创建nginx生产配置
create_nginx_config() {
    cat > nginx.prod.conf << 'EOF'
events {
    worker_connections 1024;
    multi_accept on;
    use epoll;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent" "$http_x_forwarded_for"';
    
    # 性能优化
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    server {
        listen 80;
        server_name ${DOMAIN_NAME};
        
        # SSL重定向（如果启用SSL）
        # return 301 https://$server_name$request_uri;
        
        # 静态文件根目录
        root /usr/share/nginx/html;
        index index.html index.htm;
        
        # API代理
        location /api {
            proxy_pass ${API_BACKEND_URL};
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            
            # 超时设置
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }
        
        # Vue Router历史模式支持
        location / {
            try_files $uri $uri/ /index.html;
            
            # 静态资源缓存
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
                access_log off;
            }
        }
        
        # 健康检查端点
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        # Nginx状态监控
        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            deny all;
        }
        
        # 错误页面
        error_page 404 /index.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }
    
    # HTTPS配置（如果需要）
    # server {
    #     listen 443 ssl http2;
    #     server_name ${DOMAIN_NAME};
    #     
    #     ssl_certificate /etc/ssl/certs/cert.pem;
    #     ssl_certificate_key /etc/ssl/private/key.pem;
    #     
    #     ssl_protocols TLSv1.2 TLSv1.3;
    #     ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    #     ssl_prefer_server_ciphers off;
    #     
    #     # 其他配置同HTTP server块
    # }
}
EOF
    log_message "创建 nginx.prod.conf 文件" $GREEN
}

# 函数：获取当前活跃的容器颜色
get_current_color() {
    if [ -f "$CURRENT_COLOR_FILE" ]; then
        cat "$CURRENT_COLOR_FILE"
    else
        echo "blue"  # 默认使用蓝色
    fi
}

# 函数：获取下一个部署颜色
get_next_color() {
    local current=$(get_current_color)
    if [ "$current" = "blue" ]; then
        echo "green"
    else
        echo "blue"
    fi
}

# 函数：备份当前版本
backup_current_version() {
    if docker images ${IMAGE_NAME}:latest -q > /dev/null 2>&1; then
        log_message "备份当前版本..." $BLUE
        
        local backup_tag="backup_$(date +%Y%m%d_%H%M%S)"
        docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${backup_tag}
        
        # 保存镜像到备份目录
        docker save ${IMAGE_NAME}:${backup_tag} | gzip > ${BACKUP_DIR}/${backup_tag}.tar.gz
        
        # 保存当前容器配置
        docker inspect ${CONTAINER_NAME} > ${BACKUP_DIR}/${backup_tag}_config.json 2>/dev/null || true
        
        log_message "当前版本已备份: ${backup_tag}" $GREEN
        echo "$backup_tag" > "${BACKUP_DIR}/latest_backup.txt"
    fi
}

# 函数：构建新镜像
build_image() {
    log_message "构建生产环境镜像..." $BLUE
    
    local build_tag="build_$(date +%Y%m%d_%H%M%S)"
    
    # 构建镜像，使用构建参数
    docker build \
        --build-arg NODE_ENV=production \
        --build-arg API_BASE_URL="${API_BACKEND_URL}/api" \
        -t ${IMAGE_NAME}:${build_tag} \
        -t ${IMAGE_NAME}:latest .
    
    # 验证镜像构建成功
    if ! docker images ${IMAGE_NAME}:latest -q > /dev/null 2>&1; then
        log_message "镜像构建失败" $RED
        exit 1
    fi
    
    log_message "镜像构建完成: ${IMAGE_NAME}:latest, ${IMAGE_NAME}:${build_tag}" $GREEN
}

# 函数：零停机蓝绿部署
blue_green_deploy() {
    local current_color=$(get_current_color)
    local next_color=$(get_next_color)
    local next_container="${PROJECT_NAME}-${next_color}"
    
    log_message "开始蓝绿部署: $current_color -> $next_color" $PURPLE
    
    # 停止并删除旧的下个颜色容器
    docker stop $next_container 2>/dev/null || true
    docker rm $next_container 2>/dev/null || true
    
    # 启动新容器
    docker run -d \
        --name $next_container \
        --env-file .env.production \
        -v $(pwd)/nginx.prod.conf:/etc/nginx/nginx.conf:ro \
        -v $(pwd)/ssl:/etc/ssl/certs:ro \
        --restart unless-stopped \
        --health-cmd="curl -f http://localhost/health || exit 1" \
        --health-interval=30s \
        --health-timeout=10s \
        --health-start-period=30s \
        --health-retries=3 \
        ${IMAGE_NAME}:latest
    
    # 等待新容器启动并通过健康检查
    log_message "等待新容器启动并通过健康检查..." $YELLOW
    local max_attempts=20
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker inspect --format='{{.State.Health.Status}}' $next_container 2>/dev/null | grep -q "healthy"; then
            log_message "新容器健康检查通过" $GREEN
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_message "新容器健康检查失败，部署中止" $RED
            docker logs $next_container
            docker stop $next_container
            docker rm $next_container
            exit 1
        fi
        
        log_message "健康检查进行中... ($attempt/$max_attempts)" $YELLOW
        sleep 10
        ((attempt++))
    done
    
    # 切换流量到新容器
    switch_traffic $next_color
    
    # 更新当前颜色标记
    echo $next_color > $CURRENT_COLOR_FILE
    
    # 等待一段时间确保切换成功
    sleep 30
    
    # 停止旧容器
    local old_container="${PROJECT_NAME}-${current_color}"
    if docker ps -q -f name=$old_container | grep -q .; then
        log_message "停止旧容器: $old_container" $BLUE
        docker stop $old_container
        # 保留旧容器一段时间，便于快速回滚
    fi
    
    log_message "蓝绿部署完成" $GREEN
}

# 函数：切换流量
switch_traffic() {
    local target_color=$1
    local target_container="${PROJECT_NAME}-${target_color}"
    
    log_message "切换流量到: $target_color" $BLUE
    
    # 更新nginx upstream配置或使用docker网络
    # 这里使用端口映射的方式
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
    
    # 创建新的代理容器
    docker run -d \
        --name ${CONTAINER_NAME} \
        -p ${NGINX_PORT}:80 \
        -p ${NGINX_SSL_PORT}:443 \
        --link $target_container:backend \
        --restart unless-stopped \
        ${IMAGE_NAME}:latest
    
    log_message "流量切换完成" $GREEN
}

# 函数：标准部署（非蓝绿）
standard_deploy() {
    log_message "开始标准部署..." $BLUE
    
    # 停止现有服务
    docker-compose -f docker-compose.prod.yml down 2>/dev/null || {
        docker stop ${CONTAINER_NAME} 2>/dev/null || true
        docker rm ${CONTAINER_NAME} 2>/dev/null || true
    }
    
    # 启动新服务
    if [ -f "docker-compose.prod.yml" ]; then
        docker-compose -f docker-compose.prod.yml up -d
    else
        # 使用docker run
        docker run -d \
            --name ${CONTAINER_NAME} \
            --env-file .env.production \
            -p ${NGINX_PORT}:80 \
            -p ${NGINX_SSL_PORT}:443 \
            -v $(pwd)/nginx.prod.conf:/etc/nginx/nginx.conf:ro \
            -v $(pwd)/ssl:/etc/ssl/certs:ro \
            --restart unless-stopped \
            --health-cmd="curl -f http://localhost/health || exit 1" \
            --health-interval=30s \
            --health-timeout=10s \
            --health-start-period=30s \
            --health-retries=3 \
            ${IMAGE_NAME}:latest
    fi
    
    log_message "标准部署完成" $GREEN
}

# 函数：健康检查
health_check() {
    log_message "执行应用健康检查..." $BLUE
    
    local max_attempts=15
    local attempt=1
    local health_url="http://localhost:${NGINX_PORT}/health"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s --connect-timeout 5 --max-time 10 "$health_url" > /dev/null 2>&1; then
            log_message "应用健康检查通过 ✓" $GREEN
            
            # 额外检查：验证主页是否可访问
            if curl -f -s --connect-timeout 5 --max-time 10 "http://localhost:${NGINX_PORT}/" > /dev/null 2>&1; then
                log_message "主页访问正常 ✓" $GREEN
                return 0
            else
                log_message "主页访问失败" $YELLOW
            fi
        fi
        
        log_message "健康检查失败，重试中... ($attempt/$max_attempts)" $YELLOW
        sleep 10
        ((attempt++))
    done
    
    log_message "健康检查最终失败，请检查服务状态" $RED
    show_debug_info
    return 1
}

# 函数：显示调试信息
show_debug_info() {
    log_message "=== 调试信息 ===" $YELLOW
    
    echo "容器状态:"
    docker ps -a --filter name=${PROJECT_NAME}
    
    echo -e "\n最新日志:"
    docker logs --tail 50 ${CONTAINER_NAME} 2>/dev/null || true
    
    echo -e "\n端口占用:"
    netstat -tlnp | grep ":${NGINX_PORT}\|:${NGINX_SSL_PORT}" || true
    
    echo -e "\n磁盘空间:"
    df -h
}

# 函数：回滚到上一个版本
rollback() {
    log_message "开始回滚到上一个版本..." $YELLOW
    
    if [ ! -f "${BACKUP_DIR}/latest_backup.txt" ]; then
        log_message "没有找到备份信息，无法回滚" $RED
        exit 1
    fi
    
    local backup_tag=$(cat "${BACKUP_DIR}/latest_backup.txt")
    
    if ! docker images ${IMAGE_NAME}:${backup_tag} -q > /dev/null 2>&1; then
        log_message "备份镜像不存在，尝试从文件恢复..." $YELLOW
        
        if [ -f "${BACKUP_DIR}/${backup_tag}.tar.gz" ]; then
            docker load < "${BACKUP_DIR}/${backup_tag}.tar.gz"
        else
            log_message "备份文件不存在，无法回滚" $RED
            exit 1
        fi
    fi
    
    # 停止当前服务
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
    
    # 使用备份镜像启动服务
    docker tag ${IMAGE_NAME}:${backup_tag} ${IMAGE_NAME}:latest
    standard_deploy
    
    if health_check; then
        log_message "回滚成功 ✓" $GREEN
    else
        log_message "回滚失败" $RED
        exit 1
    fi
}

# 函数：清理旧资源
cleanup_old_resources() {
    log_message "清理旧资源..." $BLUE
    
    # 清理旧备份（保留最新10个）
    find ${BACKUP_DIR} -name "backup_*.tar.gz" -type f -printf '%T@ %p\n' | \
        sort -rn | tail -n +11 | cut -d' ' -f2- | xargs -r rm -f
    
    # 清理旧镜像（保留最新5个版本）
    docker images ${IMAGE_NAME} --format "{{.Repository}}:{{.Tag}} {{.CreatedAt}}" | \
        grep -E "build_|backup_" | sort -k2 -r | tail -n +6 | \
        awk '{print $1}' | xargs -r docker rmi 2>/dev/null || true
    
    # 清理无用的Docker资源
    docker system prune -f --volumes
    
    # 清理旧日志（保留30天）
    find ${LOG_DIR} -name "*.log" -type f -mtime +30 -delete 2>/dev/null || true
    
    log_message "资源清理完成" $GREEN
}

# 函数：设置SSL证书
setup_ssl() {
    if [ "$DOMAIN_NAME" != "localhost" ] && [ ! -f "./ssl/cert.pem" ]; then
        log_message "配置SSL证书..." $BLUE
        
        # 检查certbot是否可用
        if command -v certbot &> /dev/null; then
            # 临时停止nginx以获取证书
            docker stop ${CONTAINER_NAME} 2>/dev/null || true
            
            # 获取Let's Encrypt证书
            sudo certbot certonly --standalone \
                --email $SSL_EMAIL \
                --agree-tos \
                --no-eff-email \
                --non-interactive \
                -d $DOMAIN_NAME
            
            # 复制证书
            sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem ./ssl/cert.pem
            sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem ./ssl/key.pem
            sudo chown $(whoami):$(whoami) ./ssl/*.pem
            
            # 更新nginx配置启用SSL
            sed -i 's/# return 301 https/return 301 https/g' nginx.prod.conf
            sed -i 's/# server {/server {/g' nginx.prod.conf
            
            log_message "SSL证书配置完成" $GREEN
        else
            log_message "未安装certbot，跳过SSL配置" $YELLOW
        fi
    fi
}

# 函数：设置监控和告警
setup_monitoring() {
    log_message "设置监控..." $BLUE
    
    # 创建监控脚本
    cat > "${LOG_DIR}/monitor.sh" << 'EOF'
#!/bin/bash
# 简单的监控脚本

CONTAINER_NAME="roi-frontend-prod"
LOG_FILE="./logs/monitor.log"
ALERT_EMAIL="${ALERT_EMAIL:-admin@example.com}"

check_container() {
    if ! docker ps | grep -q $CONTAINER_NAME; then
        echo "[$(date)] 警告: 容器 $CONTAINER_NAME 未运行" >> $LOG_FILE
        return 1
    fi
    return 0
}

check_health() {
    if ! curl -f -s http://localhost/health > /dev/null 2>&1; then
        echo "[$(date)] 警告: 健康检查失败" >> $LOG_FILE
        return 1
    fi
    return 0
}

check_disk_space() {
    local usage=$(df . | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$usage" -gt 85 ]; then
        echo "[$(date)] 警告: 磁盘使用率过高: ${usage}%" >> $LOG_FILE
        return 1
    fi
    return 0
}

# 执行检查
if check_container && check_health && check_disk_space; then
    echo "[$(date)] 系统状态正常" >> $LOG_FILE
else
    echo "[$(date)] 系统检查发现问题" >> $LOG_FILE
    # 这里可以添加邮件通知或其他告警机制
fi
EOF
    
    chmod +x "${LOG_DIR}/monitor.sh"
    
    # 添加到crontab（每5分钟检查一次）
    (crontab -l 2>/dev/null | grep -v "roi-frontend-monitor"; echo "*/5 * * * * $(pwd)/${LOG_DIR}/monitor.sh") | crontab -
    
    log_message "监控设置完成" $GREEN
}

# 函数：显示部署信息
show_deployment_info() {
    local current_color=$(get_current_color)
    
    log_message "=== 部署完成 ===" $CYAN
    echo ""
    print_message "🌐 访问地址:" $BLUE
    
    if [ -f "./ssl/cert.pem" ]; then
        print_message "  HTTPS: https://$DOMAIN_NAME" $GREEN
        print_message "  HTTP:  http://$DOMAIN_NAME (重定向到HTTPS)" $GREEN
    else
        print_message "  HTTP:  http://$DOMAIN_NAME:$NGINX_PORT" $GREEN
    fi
    
    print_message "  健康检查: http://$DOMAIN_NAME:$NGINX_PORT/health" $GREEN
    echo ""
    
    print_message "📊 部署信息:" $BLUE
    print_message "  当前版本: ${IMAGE_NAME}:latest" $GREEN
    print_message "  当前颜色: $current_color" $GREEN
    print_message "  容器名称: ${CONTAINER_NAME}" $GREEN
    print_message "  部署时间: $(date)" $GREEN
    echo ""
    
    print_message "🔧 管理命令:" $BLUE
    print_message "  查看状态: $0 status" $CYAN
    print_message "  查看日志: $0 logs" $CYAN
    print_message "  执行回滚: $0 rollback" $CYAN
    print_message "  资源清理: $0 cleanup" $CYAN
    print_message "  重新部署: $0 deploy" $CYAN
    echo ""
    
    print_message "📈 监控命令:" $BLUE
    print_message "  容器状态: docker ps --filter name=${PROJECT_NAME}" $CYAN
    print_message "  资源使用: docker stats ${CONTAINER_NAME}" $CYAN
    print_message "  nginx状态: curl http://$DOMAIN_NAME:$NGINX_PORT/nginx_status" $CYAN
}

# 函数：完整部署流程
deploy() {
    local start_time=$(date +%s)
    
    log_message "开始ROI Frontend生产环境部署..." $PURPLE
    log_message "部署参数: DOMAIN_NAME=$DOMAIN_NAME, NGINX_PORT=$NGINX_PORT" $BLUE
    
    # 执行部署步骤
    check_dependencies
    setup_environment
    backup_current_version
    build_image
    setup_ssl
    
    # 选择部署策略
    if [ "${DEPLOY_STRATEGY:-standard}" = "blue-green" ]; then
        blue_green_deploy
    else
        standard_deploy
    fi
    
    # 验证部署
    if health_check; then
        cleanup_old_resources
        setup_monitoring
        show_deployment_info
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_message "部署成功完成! 用时: ${duration}秒 🎉" $GREEN
    else
        log_message "部署过程中出现问题，尝试回滚..." $RED
        rollback || log_message "自动回滚也失败了，请手动检查" $RED
        exit 1
    fi
}

# 函数：查看状态
show_status() {
    log_message "=== 系统状态 ===" $BLUE
    
    echo "容器状态:"
    docker ps --filter name=${PROJECT_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n镜像信息:"
    docker images ${IMAGE_NAME} --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    
    echo -e "\n当前部署:"
    if [ -f "$CURRENT_COLOR_FILE" ]; then
        echo "当前颜色: $(cat $CURRENT_COLOR_FILE)"
    fi
    
    echo -e "\n资源使用:"
    docker stats --no-stream ${CONTAINER_NAME} 2>/dev/null || echo "容器未运行"
    
    echo -e "\n磁盘使用:"
    df -h . | head -2
    
    echo -e "\n最近日志:"
    tail -10 "${LOG_DIR}/deploy.log" 2>/dev/null || echo "暂无部署日志"
}

# 函数：显示帮助
show_help() {
    cat << EOF
ROI Frontend 生产环境部署脚本 v2.0

使用方法:
  $0 [命令] [选项]

可用命令:
  deploy    - 执行完整部署流程
  rollback  - 回滚到上一个版本
  status    - 查看系统状态
  logs      - 查看应用日志
  cleanup   - 清理旧资源
  stop      - 停止服务
  restart   - 重启服务
  help      - 显示此帮助信息

环境变量:
  PROJECT_NAME      - 项目名称 (默认: roi-frontend)
  DOMAIN_NAME       - 域名 (默认: localhost)
  NGINX_PORT        - HTTP端口 (默认: 80)
  NGINX_SSL_PORT    - HTTPS端口 (默认: 443)
  SSL_EMAIL         - SSL证书邮箱
  API_BACKEND_URL   - 后端API地址
  DEPLOY_STRATEGY   - 部署策略 (standard|blue-green)

示例:
  # 标准部署
  $0 deploy
  
  # 蓝绿部署
  DEPLOY_STRATEGY=blue-green $0 deploy
  
  # 自定义域名部署
  DOMAIN_NAME=example.com SSL_EMAIL=admin@example.com $0 deploy
  
  # 查看状态
  $0 status
  
  # 执行回滚
  $0 rollback

注意事项:
  1. 首次部署前请确保Docker和Docker Compose已安装
  2. 生产环境部署建议使用非root用户
  3. SSL证书需要certbot支持
  4. 确保防火墙已开放相应端口
EOF
}

# 主函数
main() {
    # 检查是否以root用户运行
    if [[ $EUID -eq 0 ]]; then
        log_message "警告: 建议不要以root权限运行此脚本" $YELLOW
        sleep 3
    fi
    
    # 创建日志目录
    mkdir -p "$LOG_DIR"
    
    case "${1:-help}" in
        "deploy")
            deploy
            ;;
        "rollback")
            rollback
            ;;
        "status")
            show_status
            ;;
        "logs")
            docker logs -f ${CONTAINER_NAME} 2>/dev/null || log_message "容器未运行" $YELLOW
            ;;
        "cleanup")
            cleanup_old_resources
            ;;
        "stop")
            log_message "停止服务..." $YELLOW
            docker stop ${CONTAINER_NAME} 2>/dev/null || true
            log_message "服务已停止" $GREEN
            ;;
        "restart")
            log_message "重启服务..." $BLUE
            docker restart ${CONTAINER_NAME} 2>/dev/null && health_check
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_message "未知命令: $1" $RED
            show_help
            exit 1
            ;;
    esac
}

# 设置信号处理
trap 'log_message "部署被中断" $YELLOW; exit 130' INT TERM

# 执行主函数
main "$@"