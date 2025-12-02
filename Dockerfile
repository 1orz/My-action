# OpenWrt 固件构建 Docker 镜像
# 支持多架构: x86_64, aarch64, mipsel

FROM ubuntu:22.04

LABEL maintainer="1orz"
LABEL description="OpenWrt Firmware Build Environment"

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 设置工作目录
WORKDIR /workspace

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

# 配置 ccache 加速编译（使用临时目录）
ENV USE_CCACHE=1
ENV CCACHE_DIR=/tmp/.ccache
RUN mkdir -p ${CCACHE_DIR} && \
    ccache -M 5G

# 创建非 root 用户
RUN useradd -m -u 1000 -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER builder

# 默认命令
CMD ["/bin/bash"]

