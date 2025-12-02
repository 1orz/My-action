#!/bin/bash
# OpenWrt Docker 构建 - 快速开始脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OpenWrt Docker 构建 - 快速开始${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}错误: 未安装 Docker${NC}"
    echo "请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}错误: 未安装 Docker Compose${NC}"
    echo "请先安装 Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# 给脚本添加执行权限
chmod +x build.sh

echo -e "${GREEN}✓${NC} 环境检查通过"
echo ""

# 构建 Docker 镜像
echo -e "${BLUE}步骤 1/3: 构建 Docker 镜像...${NC}"
docker-compose build
echo -e "${GREEN}✓${NC} 镜像构建完成"
echo ""

# 启动容器
echo -e "${BLUE}步骤 2/3: 启动容器...${NC}"
docker-compose up -d
echo -e "${GREEN}✓${NC} 容器已启动"
echo ""

# 显示使用说明
echo -e "${BLUE}步骤 3/3: 准备就绪！${NC}"
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}可用的构建命令:${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "方法一: 使用 Makefile (推荐)"
echo "  make shell          - 进入容器"
echo "  make build-x86      - 构建 x86_64 固件"
echo "  make build-tr3000   - 构建 TR3000 固件"
echo ""
echo "方法二: 直接使用 Docker Compose"
echo "  docker-compose exec openwrt-builder bash"
echo "  然后在容器内运行: ./build.sh x86_64"
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}其他有用命令:${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  make status         - 查看容器状态"
echo "  make logs           - 查看容器日志"
echo "  make list-output    - 查看构建输出"
echo "  docker-compose down - 停止容器"
echo ""
echo -e "${BLUE}查看完整文档: cat DOCKER_README.md${NC}"
echo ""

