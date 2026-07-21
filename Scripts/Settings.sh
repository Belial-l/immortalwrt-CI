#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")

# 添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"

if [ -f "$WIFI_SH" ]; then
    # 修改WIFI名称
    sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
    # 修改WIFI密码
    sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
    # 修改WIFI名称
    sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
    # 修改WIFI密码
    sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"

# 修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE

# 修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

# 配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

# 引入私有扩展配置
if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
    echo "Applying private configurations from PRIVATE.txt..."
    cat $GITHUB_WORKSPACE/Config/PRIVATE.txt >> ./.config
fi

# 手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
    echo -e "$WRT_PACKAGE" >> ./.config
fi

# 无WIFI配置标志
if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
    echo "WRT_WIFI=wifi-no" >> $GITHUB_ENV
fi

# ========== 新增：强制只编译 NN6000 V2 ==========
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
    echo "Locking device to link_nn6000-v2 only..."
    
    # 启用 NN6000 V2
    echo "CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_link_nn6000-v2=y" >> ./.config
    
    # 禁用其他所有设备
    cat >> ./.config << 'EOF'
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_anysafe_e1 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_cmiot_ax18 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_dptech_ap3000-2c is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_glinet_gl-ax1800 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_glinet_gl-axt1800 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-cs-02 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-cs-07 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-ss-01 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_link_nn6000-v1 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_linksys_mr7350 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_linksys_mr7500 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_philips_ly1800 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_qihoo_360v6 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_redmi_ax5 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_redmi_ax5-jdcloud is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_sy_y6010 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_xiaomi_ax1800 is not set
# CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_zn_m2 is not set
EOF
fi
