#!/bin/bash
# REALITY相关默认设置
port=443
fingerprint="chrome"
spiderx=""
domains=("www.mitsubishi.com" "updates.cdn-apple.com" "gadebate.un.org" "www.cdnetworks.com" "news.un.org" "api.datapacket.com" 
         "yelp.com" "concert.io" "jstor.org" "www.cisco.com" "s0.awsstatic.com" "d1.awsstatic.com" "www.python.org" 
         "www.cosmopolitan.com" "archive.cloudera.com" "www.shopjapan.co.jp" "www.boots.com" "download-installer.cdn.mozilla.net")

# 获取UUID和HOST
export UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
export HOST=${HOST:-$(curl ipv4.ip.sb)}

# 启用多用户
if [ "$1" == "-g" ]; then
    # 初始化数组
    numbers=(0 1 2 3 4 5 6 7 8 9)

    # 检查是否有删除特定数字的请求
    if [[ -n "$2" ]]; then
        # 去重并过滤无效字符，只保留0-9之间的数字
        delete_list=$(echo "$2" | grep -o '[0-9]' | tr -s ' ' | tr -d '\n' | fold -w1 | sort -u | tr -d '\n')

        # 删除数组中的指定元素
        for num in $(echo "$delete_list" | grep -o .); do
            numbers=("${numbers[@]/$num}")
        done

        # 移除空元素，形成新的数组
        filtered_numbers=()
        for num in "${numbers[@]}"; do
            if [[ -n "$num" ]]; then
                filtered_numbers+=("$num")
            fi
        done
    else
        # 如果没有删除指定数字，直接使用原始数组
        filtered_numbers=("${numbers[@]}")
    fi

    # 生成新的字符串数组，将 hash 值前16位存入 guest_hash 数组中
    guest_hash=()
    for num in "${filtered_numbers[@]}"; do
        hash=$(echo -n "${UUID}${num}" | md5sum | awk '{print $1}' | cut -c 1-16)
        guest_hash+=("$hash")
    done

    guest_vless=""
    for hash in "${guest_hash[@]}"; do
        guest_vless+='{ "id": "'${hash}'","flow": "xtls-rprx-vision" },'
    done

    guest_vmess=""
    for hash in "${guest_hash[@]}"; do
        guest_vmess+='{ "id": "'${hash}'" },'
    done
fi

# 安装Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 生成SNI域名和vmess端口号
uuid_short=$(echo "$UUID" | head -c 8)
seed=$((16#$uuid_short))
vmessport=$(($seed % 8000 + 2000)) 
domain=${domains[$(($seed % 18))]}

# 生成私钥公钥
private_key=$(echo -n ${UUID} | md5sum | head -c 32 | base64 -w 0 | tr '+/' '-_' | tr -d '=')
tmp_key=$(echo -n ${private_key} | xargs xray x25519 -i)
private_key=$(echo ${tmp_key} | awk '{print $3}')
public_key=$(echo ${tmp_key} | awk '{print $6}')

# 打开BBR
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" >>/etc/sysctl.conf
echo "net.core.default_qdisc = fq" >>/etc/sysctl.conf
sysctl -p 

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
            $guest_vmess
                {
                    "id": "${UUID}"
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
        $guest_vless
          {
            "id": "${UUID}",   
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
      "1.1.1.1",
      "2001:4860:4860::8888",
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

# 链接生成
vless_reality_url="vless://${UUID}@${HOST}:${port}?flow=xtls-rprx-vision&encryption=none&type=tcp&security=reality&sni=${domain}&fp=${fingerprint}&pbk=${public_key}&sid=${shortid}&spx=${spiderx}&#Reality_${HOST}_$(date +%H%M)"
temp_url='{"add":"IP","aid":"0","alpn":"","fp":"","host":"","id":"UUID","net":"tcp","path":"","port":"VMESSPORT","ps":"Vmess_IP_TIME","scy":"auto","sni":"","tls":"","type":"","v":"2"}'
o_vmess_url=$(sed -e "s/IP/${HOST}/g" \
                   -e "s/UUID/${UUID}/g" \
                   -e "s/VMESSPORT/${vmessport}/g" \
                   -e "s/TIME/$(date +%H%M)/g" <<< "${temp_url}")
vmess_url=$(echo -n "${o_vmess_url}" | base64 -w 0)

# 节点信息保存到文件中
echo "---------- VLESS Reality URL 建议直连使用----------" > ~/_xray_url_
echo $vless_reality_url >> ~/_xray_url_
echo  >> ~/_xray_url_
echo "---------- Vmess URL 建议中转使用----------" >> ~/_xray_url_
echo "目标地址:端口号 ${HOST}:${vmessport}" >> ~/_xray_url_
echo "vmess://${vmess_url}" >> ~/_xray_url_

if [ "$1" == "-g" ]; then
         echo >> ~/_xray_url_
         echo "已启用宾客数据" >> ~/_xray_url_
         for i in "${!filtered_numbers[@]}"; do
                 echo "宾客${i} 凭证UUID ${guest_hash[$i]}" >> ~/_xray_url_
         done
fi

echo >> ~/_xray_url_
echo "以上节点信息保存在 ~/_xray_url_ 中, 日后用 cat _xray_url_ 查看" >> ~/_xray_url_
echo >> ~/_xray_url_
echo "若你重装本机系统，可以使用下面的脚本恢复到相同配置" >> ~/_xray_url_
if [[ ${HOST} =~ \. && ${HOST} =~ [[:alpha:]] ]]; then
    insert="HOST=${HOST} "
fi
echo "${insert}UUID=${UUID} bash <(curl -L https://github.com/arcmosh/xray-easymuti/raw/main/install.sh) $1 $2" >> ~/_xray_url_

#展示
echo
cat ~/_xray_url_
