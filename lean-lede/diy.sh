#!/bin/bash
# 本脚本工作目录必须是git仓库的主目录

# Add Some Package

mkdir -p package/custom
cd package/custom
git clone --depth=1 https://github.com/openwrt-develop/luci-theme-atmaterial
git clone --depth=1 https://github.com/tty228/luci-app-serverchan
git clone --depth=1 https://github.com/rufengsuixing/luci-app-adguardhome
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns
git clone --depth=1 -b 18.06  https://github.com/jerrykuku/luci-theme-argon
git clone --depth=1 https://github.com/vernesong/OpenClash
git clone --depth=1 https://github.com/Lienol/openwrt-package
git clone --depth=1 https://github.com/fw876/helloworld
git clone --depth=1 https://github.com/kenzok8/openwrt-packages
git clone --depth=1 https://github.com/kenzok8/small

cd -

./scripts/feeds update -a
./scripts/feeds install -a

# Modify default IP

sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168/10.0/g' package/base-files/files/bin/config_generate

# Modify some default settings

#\cp -rf ../lede/zzz-default-settings package/lean/default-settings/files/zzz-default-settings
curl -fsSL https://raw.githubusercontent.com/1orz/My-action/master/lean-lede/zzz-default-settings > package/lean/default-settings/files/zzz-default-settings
