#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import platform
import socket
import subprocess
import sys
import urllib.parse
import urllib.request
import re

VALID_DOMAINS = ['dianxin', 'liantong', 'yidong', 'jiaoyu']
URL = 'http://172.17.3.10/srun_portal_pc.php?ac_id=1'

def get_local_ip():
    system = platform.system()
    try:
        if system == "Windows":
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        elif system == "Darwin":
            output = subprocess.check_output(["ifconfig"]).decode()
            ips = re.findall(r'inet (\d+\.\d+\.\d+\.\d+)', output)
            for ip in ips:
                if not ip.startswith("127."):
                    return ip
        elif system == "Linux":
            output = subprocess.check_output(["ip", "-4", "addr"]).decode()
            ips = re.findall(r'inet (\d+\.\d+\.\d+\.\d+)', output)
            for ip in ips:
                if not ip.startswith("127."):
                    return ip
    except Exception as e:
        print("❌ 获取本地 IP 失败:", e)
    return None

def build_post_data(action, ip, username, password, domain):
    if action == "login":
        data = {
            "action": "login",
            "ac_id": "1",
            "user_ip": ip,
            "nas_ip": "",
            "user_mac": "",
            "url": "",
            "drop": "0",
            "domain": f"@{domain}",
            "username": username,
            "password": password,
            "save_me": "1"
        }
    else:
        data = {
            "action": "logout",
            "ac_id": "1",
            "user_ip": ip,
            "username": username,
            "domain": f"@{domain}"
        }
    return urllib.parse.urlencode(data).encode("utf-8")

def perform_action(action, username, password, domain):
    ip = get_local_ip()
    if not ip:
        print("❌ 无法获取本地 IPv4 地址，请检查网络")
        sys.exit(1)

    print(f"📡 本地 IP：{ip}")
    print(f"🛠 操作：{action}")
    print(f"👤 用户名：{username}")
    print(f"📶 运营商：{domain}")

    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Origin": "http://172.17.3.10/",
        "Referer": "http://172.17.3.10/",
        "User-Agent": "Mozilla/5.0"
    }

    req = urllib.request.Request(URL, data=build_post_data(action, ip, username, password, domain), headers=headers)

    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            text = response.read().decode('utf-8', errors='ignore')
            if "网络已连接" in text:
                print("✅ 登录成功")
            elif "网络已断开" in text:
                print("✅ 注销成功")
            else:
                print("⚠️ 未知状态，响应内容如下：\n")
                print(text[:300], "...")
    except Exception as e:
        print("❌ 请求失败:", e)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="🏫 校园网登录脚本（纯 Python，无需安装依赖）")
    parser.add_argument("-a", "--action", choices=["login", "logout"], required=True, help="login 或 logout")
    parser.add_argument("-u", "--username", required=True, help="校园网用户名")
    parser.add_argument("-p", "--password", required=True, help="密码")
    parser.add_argument("-d", "--domain", required=True, help="运营商：dianxin/liantong/yidong/jiaoyu")
    args = parser.parse_args()

    if args.domain not in VALID_DOMAINS:
        print("❌ 不支持的运营商。请选择：")
        for d in VALID_DOMAINS:
            print(f"  - {d}")
        sys.exit(1)

    perform_action(args.action, args.username, args.password, args.domain)
