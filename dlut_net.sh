#!/bin/bash

# 参数示例：-a login -u 用户名 -p 密码 -d dianxin [-i 网口名]

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a) ACTION="$2"; shift 2;;
    -u) USERNAME="$2"; shift 2;;
    -p) PASSWORD="$2"; shift 2;;
    -d) DOMAIN="$2"; shift 2;;
    -i) INTERFACE="$2"; shift 2;;
    *) echo "Unknown parameter: $1"; exit 1;;
  esac
done

if [[ -z "$ACTION" || -z "$USERNAME" || -z "$PASSWORD" || -z "$DOMAIN" ]]; then
  echo "Usage: $0 -a {login,logout} -u USERNAME -p PASSWORD -d DOMAIN [-i INTERFACE]"
  exit 1
fi

# 默认接口自动选择，如果指定则用指定
if [[ -n "$INTERFACE" ]]; then
  NET_INTERFACE="$INTERFACE"
else
  # 取第一个非lo的网口（macOS 和 Linux 都适用）
  NET_INTERFACE=$(ip addr | awk '/state UP/ && $2 !~ /lo/ {print $2}' | sed 's/://g' | head -n 1)
fi

if [[ -z "$NET_INTERFACE" ]]; then
  echo "⚠️ 找不到可用网络接口"
  exit 1
fi

# 获取该接口的IPv4地址
LOCAL_IP=$(ip -4 addr show "$NET_INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)

if [[ -z "$LOCAL_IP" ]]; then
  echo "⚠️ 网络接口 $NET_INTERFACE 没有IPv4地址"
  exit 1
fi

URL='http://172.17.3.10/srun_portal_pc.php?ac_id=1'

CONTENT_TYPE="application/x-www-form-urlencoded"
ORIGIN="http://172.17.3.10/"
REFERER="http://172.17.3.10/"
USER_AGENT="Mozilla/5.0"

if [[ "$ACTION" == "login" ]]; then
  POST_DATA="action=login&ac_id=1&user_ip=$LOCAL_IP&nas_ip=&user_mac=&url=&drop=0&domain=@$DOMAIN&username=$USERNAME&password=$PASSWORD&save_me=1"
elif [[ "$ACTION" == "logout" ]]; then
  POST_DATA="action=logout&ac_id=1&user_ip=$LOCAL_IP&username=$USERNAME&domain=@$DOMAIN"
else
  echo "未知动作: $ACTION"
  exit 1
fi

echo "使用网络接口: $NET_INTERFACE"
echo "本地IP地址: $LOCAL_IP"
echo "请求动作: $ACTION"

# 构造curl命令
CURL_CMD=(curl -s --interface "$NET_INTERFACE" -X POST "$URL" \
  -H "Content-Type: $CONTENT_TYPE" \
  -H "Origin: $ORIGIN" \
  -H "Referer: $REFERER" \
  -H "User-Agent: $USER_AGENT" \
  --data "$POST_DATA" \
  --max-time 10)

# 执行请求
RESPONSE=$("${CURL_CMD[@]}")

# 调试模式下打印完整响应（默认不打印）
if [[ "$DEBUG" == "1" ]]; then
  echo "服务器响应:"
  echo "$RESPONSE"
fi

# 简单判断结果（根据实际响应内容修改）
if echo "$RESPONSE" | grep -q "网络已连接"; then
  echo "✅ 登录成功"
elif echo "$RESPONSE" | grep -q "网络已断开"; then
  echo "✅ 注销成功"
else
  echo "⚠️ 登录状态未知，请检查网络或参数。"
fi
