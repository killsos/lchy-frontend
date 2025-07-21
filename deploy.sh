#!/bin/bash

# ROI Frontend 项目部署脚本
# 使用方法: ./deploy.sh [dev|prod|build|clean]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="roi-frontend"
IMAGE_NAME="roi-frontend"

# 函数：打印带颜色的消息
print_message() {
    echo -e "${2}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# 函数：检查Docker是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_message "Docker未运行，请启动Docker" $RED
        exit 1
    fi
}

# 函数：构建生产镜像
build_production() {
    print_message "开始构建生产环境镜像..." $BLUE
    
    # 停止并删除现有容器
    docker-compose down 2>/dev/null || true
    
    # 构建镜像
    docker build -t ${IMAGE_NAME}:latest .
    
    print_message "生产环境镜像构建完成" $GREEN
}

# 函数：部署生产环境
deploy_production() {
    print_message "开始部署生产环境..." $BLUE
    
    build_production
    
    # 启动服务
    docker-compose up -d
    
    # 等待服务启动
    print_message "等待服务启动..." $YELLOW
    sleep 10
    
    # 检查服务状态
    if docker-compose ps | grep -q "Up"; then
        print_message "生产环境部署成功!" $GREEN
        print_message "访问地址: http://localhost" $GREEN
        print_message "健康检查: http://localhost/health" $GREEN
    else
        print_message "部署失败，检查容器状态" $RED
        docker-compose logs
        exit 1
    fi
}

# 函数：部署开发环境
deploy_development() {
    print_message "开始部署开发环境..." $BLUE
    
    # 构建开发镜像
    docker build -f Dockerfile.dev -t ${IMAGE_NAME}:dev .
    
    # 启动开发服务
    docker-compose -f docker-compose.dev.yml up -d
    
    print_message "开发环境部署成功!" $GREEN
    print_message "访问地址: http://localhost:5173" $GREEN
}

# 函数：清理Docker资源
clean_docker() {
    print_message "开始清理Docker资源..." $BLUE
    
    # 停止并删除容器
    docker-compose down -v 2>/dev/null || true
    docker-compose -f docker-compose.dev.yml down -v 2>/dev/null || true
    
    # 删除镜像
    docker rmi ${IMAGE_NAME}:latest 2>/dev/null || true
    docker rmi ${IMAGE_NAME}:dev 2>/dev/null || true
    
    # 清理未使用的镜像和卷
    docker system prune -f
    
    print_message "Docker资源清理完成" $GREEN
}

# 函数：显示帮助信息
show_help() {
    echo "ROI Frontend 部署脚本"
    echo ""
    echo "使用方法:"
    echo "  ./deploy.sh [命令]"
    echo ""
    echo "可用命令:"
    echo "  prod    - 部署生产环境"
    echo "  dev     - 部署开发环境"
    echo "  build   - 仅构建生产镜像"
    echo "  clean   - 清理Docker资源"
    echo "  help    - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  ./deploy.sh prod   # 部署生产环境"
    echo "  ./deploy.sh dev    # 部署开发环境"
}

# 主函数
main() {
    # 检查Docker
    check_docker
    
    # 根据参数执行不同操作
    case "${1:-help}" in
        "prod"|"production")
            deploy_production
            ;;
        "dev"|"development")
            deploy_development
            ;;
        "build")
            build_production
            ;;
        "clean")
            clean_docker
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

# 执行主函数
main "$@"