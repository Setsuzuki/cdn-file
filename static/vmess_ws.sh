#!/bin/bash

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 root 用户运行此脚本。"
  exit 1
fi

# 检查并安装 uuidgen 和 jq
if ! command -v uuidgen &> /dev/null || ! command -v jq &> /dev/null; then
  echo "正在安装依赖..."
  apt update && apt install -y uuid-runtime jq
  clear
fi

# 创建 v2r 目录
mkdir -p /root/v2r

# 下载并解压 V2Ray
wget -O /root/v2r/v2ray-linux-64.zip https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
unzip /root/v2r/v2ray-linux-64.zip -d /root/v2r
chmod +x /root/v2r/v2ray /root/v2r/v2ctl

# 询问用户是否监听 2095 端口
read -p "是否监听 2095 端口? (y/n): " listen_2095
if [ "$listen_2095" == "y" ]; then
  port=2095
else
  read -p "请输入监听端口: " port
fi

# 生成 UUID
uuid=$(uuidgen)

# 询问用户 WebSocket 路径
read -p "是否使用默认 WebSocket 路径 (/$uuid)? (y/n): " ws_path_default
if [ "$ws_path_default" == "y" ]; then
  ws_path="/$uuid"
else
  read -p "请输入 WebSocket 路径: " ws_path
fi

# 创建配置文件
cat <<EOF > /root/v2r/config.json
{
  "inbounds": [
    {
      "port": $port,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$ws_path"
        }
      },
      "tag": "vmess-inbound"
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "freedom-outbound"
    }
  ]
}
EOF

# 创建 systemd 服务文件
cat <<EOF > /etc/systemd/system/v2ray.service
[Unit]
Description=V2Ray Service
After=network.target

[Service]
Type=simple
ExecStart=/root/v2r/v2ray run /root/v2r/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启动并启用 V2Ray 服务
systemctl daemon-reload
systemctl start v2ray
systemctl enable v2ray

# 获取 IP 信息
ip_info=$(curl -s ipinfo.io)
ip=$(echo $ip_info | jq -r '.ip')
org=$(echo $ip_info | jq -r '.org' | cut -d' ' -f2-)
country=$(echo $ip_info | jq -r '.country')

# 输出 vmess 链接
vmess_link="vmess://$(echo -n "{\"add\":\"$ip\",\"port\":$port,\"id\":\"$uuid\",\"aid\":0,\"net\":\"ws\",\"path\":\"$ws_path\",\"tls\":\"\",\"ps\":\"$org $country\"}" | base64 -w 0)"
echo "你的 vmess 链接是: $vmess_link"
echo "备注 (ps): $org $country"