#!/bin/bash

# ====================================
# ROI Frontend 服务器部署脚本
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

# 配置变量
PROJECT_NAME="roi-frontend"
IMAGE_NAME="roi-frontend"
CONTAINER_NAME="roi-frontend-prod"
DOMAIN_NAME="${DOMAIN_NAME:-localhost}"  # 从环境变量获取或使用默认值
SSL_EMAIL="${SSL_EMAIL:-admin@example.com}"
BACKUP_DIR="/var/backups/roi-frontend"
LOG_DIR="./logs"

# 函数：打印带颜色的消息
print_message() {
    echo -e "${2}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_message "$1 未安装，请先安装 $1" $RED
        exit 1
    fi
}

# 函数：检查Docker和Docker Compose
check_dependencies() {
    print_message "检查依赖项..." $BLUE
    check_command "docker"
    check_command "docker-compose"
    
    if ! docker info > /dev/null 2>&1; then
        print_message "Docker未运行，请启动Docker服务" $RED
        exit 1
    fi
    
    print_message "依赖项检查完成" $GREEN
}

# 函数：创建必要的目录
create_directories() {
    print_message "创建必要的目录..." $BLUE
    
    # 创建日志目录
    mkdir -p $LOG_DIR
    
    # 创建备份目录
    sudo mkdir -p $BACKUP_DIR
    
    # 创建SSL目录（如果需要）
    mkdir -p ./ssl
    
    print_message "目录创建完成" $GREEN
}

# 函数：停止现有服务
stop_existing_services() {
    print_message "停止现有服务..." $YELLOW
    
    # 停止并删除现有容器
    docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
    
    # 删除悬空镜像
    docker image prune -f 2>/dev/null || true
    
    print_message "现有服务已停止" $GREEN
}

# 函数：构建镜像
build_image() {
    print_message "开始构建生产环境镜像..." $BLUE
    
    # 构建镜像
    docker build -t ${IMAGE_NAME}:latest .
    
    # 标记镜像版本
    local timestamp=$(date +%Y%m%d_%H%M%S)
    docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${timestamp}
    
    print_message "镜像构建完成: ${IMAGE_NAME}:latest, ${IMAGE_NAME}:${timestamp}" $GREEN
}

# 函数：配置SSL证书（使用Let's Encrypt）
setup_ssl() {
    if [ "$DOMAIN_NAME" != "localhost" ] && [ ! -f "./ssl/cert.pem" ]; then
        print_message "配置SSL证书..." $BLUE
        
        # 检查certbot是否安装
        if command -v certbot &> /dev/null; then
            # 获取SSL证书
            sudo certbot certonly --standalone \
                --email $SSL_EMAIL \
                --agree-tos \
                --no-eff-email \
                -d $DOMAIN_NAME
            
            # 复制证书到项目目录
            sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem ./ssl/cert.pem
            sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem ./ssl/key.pem
            sudo chown $(whoami):$(whoami) ./ssl/*.pem
            
            print_message "SSL证书配置完成" $GREEN
        else
            print_message "certbot未安装，跳过SSL配置。请手动配置SSL证书。" $YELLOW
        fi
    fi
}

# 函数：更新Nginx配置
update_nginx_config() {
    print_message "更新Nginx配置..." $BLUE
    
    # 替换域名
    sed -i.bak "s/server_name _;/server_name $DOMAIN_NAME;/g" nginx.prod.conf
    
    # 如果有SSL证书，启用SSL配置
    if [ -f "./ssl/cert.pem" ]; then
        sed -i 's/# ssl_certificate/ssl_certificate/g' nginx.prod.conf
        sed -i 's/# ssl_/ssl_/g' nginx.prod.conf
        print_message "SSL配置已启用" $GREEN
    fi
    
    print_message "Nginx配置更新完成" $GREEN
}

# 函数：启动服务
start_services() {
    print_message "启动生产环境服务..." $BLUE
    
    # 使用生产环境配置启动
    docker-compose -f docker-compose.prod.yml up -d
    
    # 等待服务启动
    print_message "等待服务启动..." $YELLOW
    sleep 15
    
    # 检查服务状态
    if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
        print_message "服务启动成功!" $GREEN
    else
        print_message "服务启动失败，检查日志..." $RED
        docker-compose -f docker-compose.prod.yml logs
        exit 1
    fi
}

# 函数：健康检查
health_check() {
    print_message "执行健康检查..." $BLUE
    
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost/health > /dev/null 2>&1; then
            print_message "健康检查通过 ✓" $GREEN
            return 0
        fi
        
        print_message "健康检查失败，重试中... ($attempt/$max_attempts)" $YELLOW
        sleep 10
        ((attempt++))
    done
    
    print_message "健康检查失败，请检查服务状态" $RED
    return 1
}

# 函数：备份当前版本
backup_current_version() {
    if docker images ${IMAGE_NAME} -q | head -n 1 > /dev/null; then
        print_message "备份当前版本..." $BLUE
        
        local backup_tag="backup_$(date +%Y%m%d_%H%M%S)"
        docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${backup_tag}
        
        # 保存镜像到备份目录
        docker save ${IMAGE_NAME}:${backup_tag} | gzip > ${BACKUP_DIR}/${backup_tag}.tar.gz
        
        print_message "当前版本已备份: ${backup_tag}" $GREEN
    fi
}

# 函数：清理旧备份
cleanup_old_backups() {
    print_message "清理旧备份..." $BLUE
    
    # 保留最新的5个备份
    find $BACKUP_DIR -name "backup_*.tar.gz" -type f -printf '%T@ %p\n' | \
        sort -rn | tail -n +6 | cut -d' ' -f2- | xargs -r rm -f
    
    # 清理旧的Docker镜像（保留最新的3个版本）
    docker images ${IMAGE_NAME} --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}" | \
        grep -v "latest" | tail -n +4 | awk '{print $2}' | xargs -r docker rmi ${IMAGE_NAME}: 2>/dev/null || true
    
    print_message "旧备份清理完成" $GREEN
}

# 函数：设置定时任务
setup_cron_jobs() {
    print_message "设置定时任务..." $BLUE
    
    # 每天凌晨2点备份
    (crontab -l 2>/dev/null | grep -v "roi-frontend-backup"; echo "0 2 * * * $(pwd)/deploy-server.sh backup") | crontab -
    
    # 每周日凌晨3点清理
    (crontab -l 2>/dev/null | grep -v "roi-frontend-cleanup"; echo "0 3 * * 0 $(pwd)/deploy-server.sh cleanup") | crontab -
    
    print_message "定时任务设置完成" $GREEN
}

# 函数：显示部署信息
show_deployment_info() {
    print_message "=== 部署完成 ===" $CYAN
    echo ""
    print_message "🌐 访问地址:" $BLUE
    if [ -f "./ssl/cert.pem" ]; then
        print_message "  HTTPS: https://$DOMAIN_NAME" $GREEN
        print_message "  HTTP:  http://$DOMAIN_NAME (自动重定向到HTTPS)" $GREEN
    else
        print_message "  HTTP:  http://$DOMAIN_NAME" $GREEN
    fi
    print_message "  健康检查: http://$DOMAIN_NAME/health" $GREEN
    echo ""
    print_message "📊 监控信息:" $BLUE
    print_message "  容器状态: docker-compose -f docker-compose.prod.yml ps" $CYAN
    print_message "  查看日志: docker-compose -f docker-compose.prod.yml logs -f" $CYAN
    print_message "  Nginx状态: curl http://$DOMAIN_NAME/nginx_status" $CYAN
    echo ""
    print_message "🔧 管理命令:" $BLUE
    print_message "  更新部署: $0 deploy" $CYAN
    print_message "  停止服务: $0 stop" $CYAN
    print_message "  备份数据: $0 backup" $CYAN
    print_message "  清理旧数据: $0 cleanup" $CYAN
    echo ""
}

# 函数：完整部署流程
deploy() {
    print_message "开始ROI Frontend生产环境部署..." $PURPLE
    
    check_dependencies
    create_directories
    backup_current_version
    stop_existing_services
    build_image
    setup_ssl
    update_nginx_config
    start_services
    
    if health_check; then
        cleanup_old_backups
        setup_cron_jobs
        show_deployment_info
        print_message "部署成功完成! 🎉" $GREEN
    else
        print_message "部署过程中出现问题，请检查日志" $RED
        exit 1
    fi
}

# 函数：停止服务
stop_services() {
    print_message "停止服务..." $YELLOW
    docker-compose -f docker-compose.prod.yml down
    print_message "服务已停止" $GREEN
}

# 函数：查看状态
show_status() {
    print_message "=== 服务状态 ===" $BLUE
    docker-compose -f docker-compose.prod.yml ps
    echo ""
    print_message "=== 镜像信息 ===" $BLUE
    docker images ${IMAGE_NAME}
    echo ""
    print_message "=== 磁盘使用 ===" $BLUE
    df -h
}

# 函数：显示帮助
show_help() {
    echo "ROI Frontend 服务器部署脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [命令]"
    echo ""
    echo "可用命令:"
    echo "  deploy    - 完整部署流程"
    echo "  stop      - 停止服务"
    echo "  restart   - 重启服务"
    echo "  status    - 查看服务状态"
    echo "  backup    - 备份当前版本"
    echo "  cleanup   - 清理旧备份"
    echo "  logs      - 查看服务日志"
    echo "  help      - 显示此帮助信息"
    echo ""
    echo "环境变量:"
    echo "  DOMAIN_NAME  - 域名 (默认: localhost)"
    echo "  SSL_EMAIL    - SSL证书邮箱 (默认: admin@example.com)"
    echo ""
    echo "示例:"
    echo "  DOMAIN_NAME=example.com SSL_EMAIL=admin@example.com $0 deploy"
}

# 主函数
main() {
    case "${1:-help}" in
        "deploy")
            deploy
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            stop_services
            sleep 5
            start_services
            health_check
            ;;
        "status")
            show_status
            ;;
        "backup")
            backup_current_version
            ;;
        "cleanup")
            cleanup_old_backups
            ;;
        "logs")
            docker-compose -f docker-compose.prod.yml logs -f
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_message "未知命令: $1" $RED
            show_help
            exit 1
            ;;
    esac
}

# 检查是否以root权限运行
if [[ $EUID -eq 0 ]]; then
   print_message "请不要以root权限运行此脚本" $RED
   exit 1
fi

# 执行主函数
main "$@"