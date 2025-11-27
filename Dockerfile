# OpenWrt 固件构建 Docker 镜像
# 支持多架构: x86_64, aarch64, mipsel

FROM ubuntu:24.10

LABEL maintainer="1orz"
LABEL description="OpenWrt Firmware Build Environment"

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 设置工作目录
WORKDIR /builder

# 安装系统依赖和构建工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # 基础工具
    build-essential clang llvm flex bison g++ gawk \
    # 网络工具
    git git-core wget curl rsync \
    # 开发库
    libncurses-dev libssl-dev libelf-dev \
    libgnutls28-dev libgmp-dev libmpc-dev libfuse-dev \
    # Python 环境
    python3 python3-dev python3-pip python3-setuptools \
    # 其他依赖
    gettext-base unzip zlib1g-dev swig jq subversion \
    qemu-utils rename coccinelle file \
    # 调试和信息工具
    neofetch vim nano ccache \
    # 清理缓存
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 配置 ccache 加速编译
ENV USE_CCACHE=1
ENV CCACHE_DIR=/builder/.ccache
RUN mkdir -p ${CCACHE_DIR} && \
    ccache -M 5G

# 创建非 root 用户
RUN useradd -m -u 1000 -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER builder

# 克隆 OpenWrt 源码（可选，也可以在运行时挂载）
# 默认注释掉，运行时再克隆以获取最新代码
# RUN git clone --depth=1 https://github.com/openwrt/openwrt.git /builder/openwrt

# 创建构建脚本
COPY --chown=builder:builder build.sh /builder/build.sh
RUN chmod +x /builder/build.sh

# 暴露卷以便挂载配置和输出
VOLUME ["/builder/openwrt", "/builder/output", "/builder/.ccache"]

# 默认命令
CMD ["/bin/bash"]

