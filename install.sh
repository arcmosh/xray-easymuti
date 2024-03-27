#!/bin/bash

# fakeSNI
domain="updates.cdn-apple.com"

# 设置reality端口号
port=443

# 指纹FingerPrint
fingerprint="ios"

# SpiderX
spiderx=""

# 获取UUID
uuid=$(cat /proc/sys/kernel/random/uuid)

# 参数1是UUID时覆盖当前
if [[ -n ${1} ]]; then
    uuid=${1}
fi

# 获取UUID的前8个字符
uuid_short=$(echo "$uuid" | head -c 8)

# 将UUID转换为10进制
decimal_uuid=$((16#$uuid_short))

# 计算端口号（确保在有效范围内）
vmessport=$((decimal_uuid % 8000 + 2000)) 

# 打印变量值
echo "UUID: $uuid"
echo "vmessport: $vmessport"

# 准备工作
apt update
apt install -y curl sudo jq qrencode

# 安装Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 生成私钥公钥
private_key=$(echo -n ${uuid} | md5sum | head -c 32 | base64 -w 0 | tr '+/' '-_' | tr -d '=')
tmp_key=$(echo -n ${private_key} | xargs xray x25519 -i)
private_key=$(echo ${tmp_key} | awk '{print $3}')
public_key=$(echo ${tmp_key} | awk '{print $6}')

# 打开BBR
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" >>/etc/sysctl.conf
echo "net.core.default_qdisc = fq" >>/etc/sysctl.conf
sysctl -p >/dev/null 2>&1

# 打印生成的私钥公钥
echo "Private Key: $private_key"
echo "Public Key: $public_key"

# 配置 VLESS_Reality 模式, 需要:端口, UUID, x25519公私钥, 目标网站
ip=$(curl ipv4.ip.sb)

# 配置config.json
cat > /usr/local/etc/xray/config.json <<-EOF
{ 
  "log": {
    "access": "none",
    "error": "/var/log/xray/error.log",
    "loglevel": "error"
  },
  "inbounds": [
    {
        "listen": "0.0.0.0",
        "port": ${vmessport},
        "protocol": "vmess",
        "settings": {
            "clients": [
                {
                    "id": "${uuid}"
                }
            ]
        },
        "streamSettings": {
            "network": "tcp"
        }
    },
    {
      "listen": "0.0.0.0",
      "port": ${port},    
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",   
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "${domain}:443",    
          "xver": 0,
          "serverNames": ["${domain}"], 
          "privateKey": "${private_key}",  
          "shortIds": [""] 
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ],
  "dns": {
    "servers": [
      "8.8.8.8",
      "8.8.4.4",
      "2001:4860:4860::8888",
      "2606:4700:4700::1111",
      "localhost"
    ]
  },
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": []
  }
}
EOF

# 重启 Xray
service xray restart

echo "---------- VLESS Reality URL ----------"
vless_reality_url="vless://${uuid}@${ip}:${port}?flow=xtls-rprx-vision&encryption=none&type=tcp&security=reality&sni=${domain}&fp=${fingerprint}&pbk=${public_key}&sid=${shortid}&spx=${spiderx}&#Reality_${ip}_$(date +%H%M)"
echo -e "${vless_reality_url}"
echo

echo "---------- Vmess URL ----------"
temp_url='{"add":"IP","aid":"0","alpn":"","fp":"","host":"","id":"${uuid}","net":"tcp","path":"","port":"VMESSPORT","ps":"Vmess_${ip}_TIME","scy":"auto","sni":"","tls":"","type":"","v":"2"}'
O_vmess_url=$(sed -e "s/IP/${ip}/g" -e "s/VMESSPORT/${vmessport}/g" -e "s/TIME/$(date +%H%M)/g" <<< "$temp_url")
echo -e "$o_vmess_url"

echo "以上节点信息保存在 ~/_vless_reality_url_ 中"

# 节点信息保存到文件中
echo $vless_reality_url > ~/_vless_reality_url_


