# OpenWrt Docker 构建指南

本文档介绍如何使用 Docker 构建 OpenWrt 固件。

## 📋 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 30GB 可用磁盘空间
- 建议 16GB+ RAM
- 建议多核 CPU（构建时间取决于 CPU 性能）

## 🚀 快速开始

### 方法一：使用 Docker Compose（推荐）

```bash
# 1. 构建镜像
docker-compose build

# 2. 启动容器（后台运行）
docker-compose up -d

# 3. 进入容器
docker-compose exec openwrt-builder bash

# 4. 在容器内构建固件
./build.sh x86_64        # 构建 x86_64 架构
# 或
./build.sh tr3000        # 构建 TR3000 设备
```

### 方法二：使用 Docker 命令

```bash
# 1. 构建镜像
docker build -t openwrt-builder:latest .

# 2. 运行容器
docker run -it --rm \
  -v $(pwd)/openwrt:/builder/configs:ro \
  -v $(pwd)/output:/builder/output:rw \
  -v openwrt-src:/builder/openwrt:rw \
  -v ccache-data:/builder/.ccache:rw \
  --name openwrt-builder \
  openwrt-builder:latest

# 3. 在容器内构建
./build.sh x86_64
```

## 🏗️ 支持的架构

根据 `openwrt/` 目录下的配置文件：

- `x86_64` - x86 64位架构
- `config-armsr-armv8` - ARM System Ready (ARMv8)
- `config-mips-redmi-ac2100` - MIPS 架构（Redmi AC2100）
- `glinet-mt3000` - GL.iNet MT3000
- `tr3000` - Cudy TR3000
- `tr3000-256M` - Cudy TR3000 (256M 内存版本)

## 📦 构建命令

### 基本构建

```bash
# 构建 x86_64 固件（默认使用所有 CPU 核心）
./build.sh x86_64

# 构建 TR3000 固件（指定使用 4 个线程）
./build.sh tr3000 4

# 构建 ARM System Ready 固件
./build.sh config-armsr-armv8 8
```

### 高级构建

如果需要自定义构建过程，可以手动执行：

```bash
# 1. 进入 OpenWrt 源码目录
cd /builder/openwrt

# 2. 克隆源码（如果还没有）
git clone --depth=1 https://github.com/openwrt/openwrt.git .

# 3. 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 4. 复制配置文件
cp /builder/configs/x86_64 .config

# 5. 生成完整配置
make defconfig

# 6. 可选：打开菜单配置
make menuconfig

# 7. 开始编译
make -j$(nproc) V=s
# 或者单线程详细输出
# make -j1 V=99

# 8. 固件输出在
# bin/targets/ 目录
```

## 📂 目录结构

```
My-action/
├── Dockerfile              # Docker 镜像定义
├── docker-compose.yml      # Docker Compose 配置
├── build.sh                # 构建脚本
├── .dockerignore          # Docker 忽略文件
├── openwrt/               # 配置文件目录
│   ├── x86_64
│   ├── tr3000
│   └── ...
└── output/                # 输出目录（自动创建）
    ├── images/            # 固件镜像
    └── packages/          # 软件包
```

## 🔧 常用 Docker 命令

### 管理容器

```bash
# 启动容器
docker-compose up -d

# 停止容器
docker-compose down

# 查看容器日志
docker-compose logs -f

# 进入运行中的容器
docker-compose exec openwrt-builder bash

# 重启容器
docker-compose restart
```

### 清理和维护

```bash
# 清理未使用的镜像
docker image prune -a

# 清理所有未使用的卷（注意：会删除 ccache 缓存）
docker volume prune

# 仅清理 OpenWrt 源码卷（重新开始）
docker volume rm openwrt-src

# 清理编译缓存
docker volume rm ccache-data

# 完全重建（删除所有内容重新开始）
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

## 💾 缓存管理

Docker 构建使用两个持久化卷来加速编译：

1. **openwrt-src**: OpenWrt 源码（约 5-10GB）
2. **ccache-data**: 编译缓存（约 5GB）

这些卷会在容器重启后保留，大大加速后续构建。

查看卷使用情况：
```bash
docker volume ls
docker volume inspect openwrt-src
docker system df -v
```

## 🐛 故障排除

### 构建失败

如果多线程构建失败，脚本会自动回退到单线程模式。你也可以手动使用单线程：

```bash
cd /builder/openwrt
make -j1 V=99
```

### 磁盘空间不足

```bash
# 检查磁盘空间
df -h

# 清理 OpenWrt 构建临时文件
cd /builder/openwrt
make clean

# 彻底清理（会删除所有编译结果）
make dirclean

# 清理 Docker 缓存
docker system prune -a
```

### 依赖问题

```bash
# 更新 feeds
cd /builder/openwrt
./scripts/feeds clean
./scripts/feeds update -a
./scripts/feeds install -a
```

### 重新开始构建

```bash
# 在容器内
cd /builder/openwrt
rm -rf .config tmp
make distclean

# 然后重新运行构建脚本
cd /builder
./build.sh x86_64
```

## 🌐 多架构镜像构建

如果需要构建支持多平台的 Docker 镜像：

```bash
# 创建 buildx 构建器
docker buildx create --name multiarch --use

# 构建并推送多架构镜像
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t your-registry/openwrt-builder:latest \
  --push .
```

## ⚙️ 自定义配置

### 修改资源限制

编辑 `docker-compose.yml` 中的资源限制：

```yaml
deploy:
  resources:
    limits:
      cpus: '8'      # 最大 CPU 核心数
      memory: 16G    # 最大内存
```

### 添加自定义包

编辑 `build.sh`，在 feeds 更新后添加你的自定义包：

```bash
git clone --depth=1 https://github.com/your/custom-package.git \
    package/feeds/luci/custom-package
```

### 修改 OpenWrt 版本

默认使用 main 分支（最新开发版）。如果需要使用稳定版：

```bash
cd /builder/openwrt
git fetch --depth=1 origin refs/tags/v23.05.2:refs/tags/v23.05.2
git checkout v23.05.2
```

## 📊 性能优化

1. **使用 SSD**: 固态硬盘能大幅提升构建速度
2. **增加内存**: 建议至少 16GB RAM
3. **启用 ccache**: 默认已启用，二次编译速度显著提升
4. **并行编译**: 根据 CPU 核心数调整 `-j` 参数

## 🔐 安全注意事项

- 容器以非 root 用户 `builder` 运行
- 配置文件以只读方式挂载
- 建议不要在生产环境直接使用 `network_mode: "host"`

## 📝 示例工作流

完整的构建流程示例：

```bash
# 1. 首次设置
docker-compose build
docker-compose up -d

# 2. 构建 x86_64 固件
docker-compose exec openwrt-builder bash
./build.sh x86_64

# 3. 构建完成后，检查输出
ls -lh /builder/output/images/

# 4. 退出容器
exit

# 5. 在宿主机查看输出
ls -lh output/images/

# 6. 构建其他架构
docker-compose exec openwrt-builder ./build.sh tr3000

# 7. 完成后停止容器
docker-compose down
```

## 🆘 获取帮助

如果遇到问题：

1. 查看容器日志：`docker-compose logs`
2. 检查磁盘空间：`df -h`
3. 查看构建日志：检查容器内 `/builder/openwrt/logs/` 目录
4. 提交 Issue 到 GitHub 仓库

## 📚 参考资料

- [OpenWrt 官方文档](https://openwrt.org/docs/start)
- [OpenWrt 构建系统](https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem)
- [Docker 官方文档](https://docs.docker.com/)

