#!/bin/bash
# 本脚本工作目录必须是git仓库的主目录

# Add Some Package

echo 'src-git  kenzok8small https://github.com/kenzok8/small' >> feeds.conf.default
echo 'src-git  kenzok8openwrtpackages https://github.com/kenzok8/openwrt-packages' >> feeds.conf.default
echo 'src-git  Lienolopenwrtpackages https://github.com/Lienol/openwrt-package' >> feeds.conf.default
echo 'src-git  helloworld https://github.com/fw876/helloworld' >> feeds.conf.default
echo 'src-git  OpenClash https://github.com/vernesong/OpenClash' >> feeds.conf.default

mkdir -p package/custom
cd package/custom
git clone https://github.com/openwrt-develop/luci-theme-atmaterial
git clone https://github.com/tty228/luci-app-serverchan
git clone https://github.com/rufengsuixing/luci-app-adguardhome
git clone -b lede https://github.com/pymumu/luci-app-smartdns
git clone https://github.com/pymumu/openwrt-smartdns
git clone -b 18.06  https://github.com/jerrykuku/luci-theme-argon

cd ../../

./scripts/feeds update -a
./scripts/feeds install -a

# Modify default IP

sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168/10.0/g' package/base-files/files/bin/config_generate

# Modify some default settings

#\cp -rf ../lede/zzz-default-settings package/lean/default-settings/files/zzz-default-settings
curl -fsSL https://raw.githubusercontent.com/1orz/My-action/master/lean-lede/zzz-default-settings > package/lean/default-settings/files/zzz-default-settings
