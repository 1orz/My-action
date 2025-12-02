# OpenWrt Docker 构建 Makefile
# 简化常用 Docker 操作

.PHONY: help build up down restart shell logs clean clean-all build-x86 build-arm build-mips

# 默认目标
help:
	@echo "OpenWrt Docker 构建工具"
	@echo ""
	@echo "可用命令:"
	@echo "  make build       - 构建 Docker 镜像"
	@echo "  make up          - 启动容器（后台）"
	@echo "  make down        - 停止并删除容器"
	@echo "  make restart     - 重启容器"
	@echo "  make shell       - 进入容器 shell"
	@echo "  make logs        - 查看容器日志"
	@echo ""
	@echo "构建固件:"
	@echo "  make build-x86       - 构建 x86_64 固件"
	@echo "  make build-arm       - 构建 ARM (armsr-armv8) 固件"
	@echo "  make build-mips      - 构建 MIPS (Redmi AC2100) 固件"
	@echo "  make build-tr3000    - 构建 TR3000 固件"
	@echo ""
	@echo "清理:"
	@echo "  make clean       - 清理容器和未使用的镜像"
	@echo "  make clean-all   - 清理所有（容器和镜像）"
	@echo "  make clean-build - 清理构建目录（openwrt-build 和 output）"

# 构建 Docker 镜像
build:
	@echo "构建 Docker 镜像..."
	docker-compose build

# 启动容器
up:
	@echo "启动容器..."
	docker-compose up -d
	@echo "容器已启动，使用 'make shell' 进入容器"

# 停止容器
down:
	@echo "停止容器..."
	docker-compose down

# 重启容器
restart:
	@echo "重启容器..."
	docker-compose restart

# 进入容器 shell
shell:
	@echo "进入容器..."
	docker-compose exec openwrt-builder bash

# 查看日志
logs:
	docker-compose logs -f

# 构建 x86_64 固件
build-x86:
	@echo "构建 x86_64 固件..."
	@mkdir -p output
	docker-compose exec openwrt-builder ./build.sh x86_64

# 构建 ARM 固件
build-arm:
	@echo "构建 ARM (armsr-armv8) 固件..."
	@mkdir -p output
	docker-compose exec openwrt-builder ./build.sh config-armsr-armv8

# 构建 MIPS 固件
build-mips:
	@echo "构建 MIPS (Redmi AC2100) 固件..."
	@mkdir -p output
	docker-compose exec openwrt-builder ./build.sh config-mips-redmi-ac2100

# 构建 TR3000 固件
build-tr3000:
	@echo "构建 TR3000 固件..."
	@mkdir -p output
	docker-compose exec openwrt-builder ./build.sh tr3000

# 清理容器和镜像
clean:
	@echo "清理容器和未使用的镜像..."
	docker-compose down
	docker image prune -f

# 完全清理
clean-all:
	@echo "⚠️  警告：这将删除容器和镜像！"
	@read -p "确定要继续吗？[y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down; \
		docker image prune -af; \
		echo "清理完成！"; \
	else \
		echo "已取消"; \
	fi

# 清理构建目录
clean-build:
	@echo "清理构建目录..."
	@rm -rf openwrt-build output
	@echo "构建目录已清理"

# 查看容器状态
status:
	@echo "容器状态:"
	@docker-compose ps
	@echo ""
	@echo "磁盘使用情况:"
	@du -sh openwrt-build 2>/dev/null || echo "构建目录不存在"
	@du -sh output 2>/dev/null || echo "输出目录不存在"

# 查看输出文件
list-output:
	@echo "构建输出文件:"
	@if [ -d output/images ]; then \
		ls -lh output/images/; \
	else \
		echo "输出目录不存在"; \
	fi

# 初始化（首次使用）
init:
	@echo "初始化 Docker 构建环境..."
	@chmod +x build.sh
	@mkdir -p output
	make build
	make up
	@echo ""
	@echo "✅ 初始化完成！"
	@echo "使用 'make shell' 进入容器，然后运行 './build.sh x86_64' 开始构建"

