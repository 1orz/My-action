#!/bin/bash
# OpenWrt 固件构建脚本
# 用法: ./build.sh [架构配置文件] [线程数]
# 示例: ./build.sh x86_64 8

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 默认参数
CONFIG_FILE="${1:-x86_64}"
THREADS="${2:-$(nproc)}"
OPENWRT_DIR="/builder/openwrt"
OUTPUT_DIR="/builder/output"

log_info "开始 OpenWrt 固件构建"
log_info "配置文件: $CONFIG_FILE"
log_info "使用线程数: $THREADS"

# 检查 OpenWrt 源码
if [ ! -d "$OPENWRT_DIR" ]; then
    log_info "OpenWrt 源码不存在，开始克隆..."
    git clone --depth=1 https://github.com/openwrt/openwrt.git "$OPENWRT_DIR"
fi

cd "$OPENWRT_DIR"

# 清理旧的配置
log_info "清理旧的构建配置..."
rm -rf tmp .config

# 更新 feeds
# log_info "更新 feeds..."
# ./scripts/feeds update -a
# ./scripts/feeds install -a

# 添加自定义包
log_info "添加自定义包..."
rm -rf package/feeds/openwrt-passwall2 package/feeds/openwrt-passwall-packages 2>/dev/null || true

git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git \
    package/feeds/luci/luci-app-argon-config 2>/dev/null || true
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git \
    package/feeds/luci/luci-theme-argon 2>/dev/null || true
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall2.git \
    package/feeds/openwrt-passwall2 2>/dev/null || true
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages.git \
    package/feeds/openwrt-passwall-packages 2>/dev/null || true

# 删除冲突的包
rm -rf feeds/packages/net/{microsocks,sing-box,v2ray-geodata,xray-core} 2>/dev/null || true

# 再次更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 加载配置文件
if [ -f "/builder/configs/$CONFIG_FILE" ]; then
    log_info "加载配置: /builder/configs/$CONFIG_FILE"
    cp "/builder/configs/$CONFIG_FILE" .config
elif [ -f "/builder/openwrt/$CONFIG_FILE" ]; then
    log_info "加载配置: /builder/openwrt/$CONFIG_FILE"
    cp "/builder/openwrt/$CONFIG_FILE" .config
else
    log_error "配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 启用 ccache 和开发者选项
echo -e 'CONFIG_DEVEL=y\nCONFIG_CCACHE=y' >> .config

# 生成完整配置
log_info "生成默认配置..."
make defconfig

# 修复 Rust LLVM 设置
log_info "修复 Rust LLVM 配置..."
sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/g' \
    feeds/packages/lang/rust/Makefile 2>/dev/null || true

# 显示磁盘空间
log_info "当前磁盘空间:"
df -h | grep -E '(Filesystem|/$|/builder)'

# 开始编译
log_info "开始编译 (使用 $THREADS 线程)..."
log_info "首次尝试多线程编译..."
if make -j${THREADS} V=s; then
    log_info "多线程编译成功！"
else
    log_warn "多线程编译失败，回退到单线程编译..."
    make -j1 V=99
fi

# 显示编译后磁盘空间
log_info "编译后磁盘空间:"
df -h | grep -E '(Filesystem|/$|/builder)'

# 准备输出
log_info "准备输出文件..."
mkdir -p "$OUTPUT_DIR"/{images,packages}

# 复制固件镜像
if [ -d "bin/targets" ]; then
    find bin/targets -name "openwrt-*" -type f -exec cp {} "$OUTPUT_DIR/images/" \;
    find bin/targets -name "sha256sums" -type f -exec cp {} "$OUTPUT_DIR/images/" \;
    log_info "固件镜像已复制到: $OUTPUT_DIR/images/"
fi

# 复制软件包
if [ -d "bin/packages" ]; then
    cp -r bin/packages/* "$OUTPUT_DIR/packages/" 2>/dev/null || true
    log_info "软件包已复制到: $OUTPUT_DIR/packages/"
fi

# 列出生成的文件
log_info "生成的固件文件:"
ls -lh "$OUTPUT_DIR/images/" 2>/dev/null || log_warn "没有找到固件文件"

log_info "构建完成！"
log_info "输出目录: $OUTPUT_DIR"

