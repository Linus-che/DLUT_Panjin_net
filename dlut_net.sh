#!/bin/bash

print_error_info() {
  echo "⚠️ 登录状态未知，请检查网络或参数。"
  echo
  echo "当前网络接口及其IP（排除回环）:"
  ip addr | awk '
    $1 ~ /^[0-9]+:/ { iface=$2 }
    iface !~ /^lo/ && /inet / {
      split($2, a, "/")
      ip=a[1]
      if (ip !~ /^127\./) {
        sub(":", "", iface)
        print "  接口: " iface ", IP: " ip
      }
    }
  '
  echo
  echo "常见运营商域名参数示例："
  echo "  电信: dianxin"
  echo "  联通: liantong"
  echo "  移动: yidong"
  echo "  教育网: jiaoyu"
  echo
  echo "脚本示例："
  echo "  $0 -a login -u 用户名 -p 密码 -d dianxin [-i 网口名]"
  echo
  echo "如果你不确定可用的网口名称，可使用 -i 参数指定。"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a) ACTION="$2"; shift 2;;
    -u) USERNAME="$2"; shift 2;;
    -p) PASSWORD="$2"; shift 2;;
    -d) DOMAIN="$2"; shift 2;;
    -i) INTERFACE="$2"; shift 2;;
    *) echo "未知参数: $1"; exit 1;;
  esac
done

if [[ -z "$ACTION" || -z "$USERNAME" || -z "$PASSWORD" || -z "$DOMAIN" ]]; then
  echo "用法: $0 -a {login,logout} -u 用户名 -p 密码 -d 域名 [-i 网口名]"
  exit 1
fi

# 选择网络接口，排除lo和回环IP
if [[ -n "$INTERFACE" ]]; then
  NET_INTERFACE="$INTERFACE"
else
  # 取第一个非lo且IP不为127.x.x.x的接口（Linux和macOS通用）
  NET_INTERFACE=$(ip addr | awk '
    $1 ~ /^[0-9]+:/ { iface=$2 }
    iface !~ /^lo/ && /inet / {
      split($2, a, "/")
      ip=a[1]
      if (ip !~ /^127\./) {
        sub(":", "", iface)
        print iface
        exit
      }
    }
  ')
fi

if [[ -z "$NET_INTERFACE" ]]; then
  echo "⚠️ 找不到可用网络接口"
  exit 1
fi

LOCAL_IP=$(ip -4 addr show "$NET_INTERFACE" 2>/dev/null | grep -oE 'inet ([0-9]+\.){3}[0-9]+' | awk '{print $2}' | head -n 1)
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

CURL_CMD=(curl -s --interface "$NET_INTERFACE" -X POST "$URL" \
  -H "Content-Type: $CONTENT_TYPE" \
  -H "Origin: $ORIGIN" \
  -H "Referer: $REFERER" \
  -H "User-Agent: $USER_AGENT" \
  --data "$POST_DATA" \
  --max-time 10)

RESPONSE=$("${CURL_CMD[@]}")

if echo "$RESPONSE" | grep -q "网络已连接"; then
  echo "✅ 登录成功"
elif echo "$RESPONSE" | grep -q "网络已断开"; then
  echo "✅ 注销成功"
else
  print_error_info
fi
