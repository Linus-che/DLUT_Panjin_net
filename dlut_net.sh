#!/bin/bash

# ========= 基本信息 =========
PORTAL_URL="http://172.17.3.10/srun_portal_pc.php?ac_id=1"
ORIGIN="http://172.17.3.10/"
REFERER="http://172.17.3.10/"
USER_AGENT="Mozilla/5.0"
CONTENT_TYPE="application/x-www-form-urlencoded"

# ========= 提示函数 =========
print_usage() {
  echo -e "\n📘 用法:"
  echo "  $0 -a {login|logout} -u 用户名 -p 密码 -d 域名 [-i 网口名]"
  echo -e "\n🌐 常见运营商域名："
  echo "  电信:    dianxin"
  echo "  联通:    liantong"
  echo "  移动:    yidong"
  echo "  教育网:  jiaoyu"
  echo -e "\n🧰 示例:"
  echo "  $0 -a login -u alice -p 123456 -d dianxin"
  echo "  $0 -a logout -u alice -p 123456 -d yidong -i en0"
  echo
}

print_interfaces() {
  echo -e "\n🔎 可用网络接口（排除回环）："
  if [[ "$OS" == "Darwin" ]]; then
    ifconfig | awk '/flags=/{gsub(":", "", $1); iface=$1} /inet / && $2 !~ /^127/ {print "  接口: " iface ", IP: " $2}'
  else
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
  fi
  echo
}

print_error_info() {
  echo -e "\n❌ 登录状态未知，可能是以下原因："
  echo "  - 参数有误"
  echo "  - 网络不可用"
  echo "  - 认证服务器未响应"
  print_interfaces
  print_usage
}

# ========= 解析参数 =========
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a) ACTION="$2"; shift 2;;
    -u) USERNAME="$2"; shift 2;;
    -p) PASSWORD="$2"; shift 2;;
    -d) DOMAIN="$2"; shift 2;;
    -i) INTERFACE="$2"; shift 2;;
    *) echo "❗ 未知参数: $1"; print_usage; exit 1;;
  esac
done

# ========= 参数检查 =========
if [[ -z "$ACTION" || -z "$USERNAME" || -z "$PASSWORD" || -z "$DOMAIN" ]]; then
  echo "❗ 缺少必要参数！"
  print_usage
  exit 1
fi

# ========= 系统类型判断 =========
OS=$(uname)

# ========= 网络接口选择 =========
if [[ -n "$INTERFACE" ]]; then
  NET_IF="$INTERFACE"
else
  if [[ "$OS" == "Darwin" ]]; then
    NET_IF=$(ifconfig | awk '/flags=/{gsub(":", "", $1); iface=$1} /inet / && $2 !~ /^127/ {print iface; exit}')
  else
    NET_IF=$(ip addr | awk '
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
fi

if [[ -z "$NET_IF" ]]; then
  echo "❌ 无法获取网络接口"
  print_interfaces
  exit 1
fi

# ========= 获取本地 IP =========
if [[ "$OS" == "Darwin" ]]; then
  LOCAL_IP=$(ifconfig "$NET_IF" 2>/dev/null | awk '/inet / && $2 !~ /^127/ {print $2; exit}')
else
  LOCAL_IP=$(ip -4 addr show "$NET_IF" 2>/dev/null | grep -oE 'inet ([0-9]+\.){3}[0-9]+' | awk '{print $2}' | head -n 1)
fi

if [[ -z "$LOCAL_IP" ]]; then
  echo "❌ 接口 $NET_IF 无法获取有效 IPv4 地址"
  exit 1
fi

# ========= 构造 POST 数据 =========
if [[ "$ACTION" == "login" ]]; then
  POST_DATA="action=login&ac_id=1&user_ip=$LOCAL_IP&nas_ip=&user_mac=&url=&drop=0&domain=@$DOMAIN&username=$USERNAME&password=$PASSWORD&save_me=1"
elif [[ "$ACTION" == "logout" ]]; then
  POST_DATA="action=logout&ac_id=1&user_ip=$LOCAL_IP&username=$USERNAME&domain=@$DOMAIN"
else
  echo "❗ 未知动作: $ACTION"
  print_usage
  exit 1
fi

# ========= 执行认证请求 =========
echo "🌐 网络接口: $NET_IF"
echo "📡 本地 IP: $LOCAL_IP"
echo "🔄 请求动作: $ACTION"

RESPONSE=$(curl -s --interface "$NET_IF" -X POST "$PORTAL_URL" \
  -H "Content-Type: $CONTENT_TYPE" \
  -H "Origin: $ORIGIN" \
  -H "Referer: $REFERER" \
  -H "User-Agent: $USER_AGENT" \
  --data "$POST_DATA" \
  --max-time 10)

# ========= 简单判断响应内容 =========
if echo "$RESPONSE" | grep -q "网络已连接"; then
  echo -e "✅ 登录成功"
elif echo "$RESPONSE" | grep -q "网络已断开"; then
  echo -e "✅ 注销成功"
else
  print_error_info
fi
