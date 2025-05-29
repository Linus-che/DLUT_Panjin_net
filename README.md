# 🏫 CampusNet Login Script（校园网一键登录脚本）

一个用于大连理工大学盘锦校区的校园网认证的命令行脚本，兼容 **Linux** 与 **macOS**，支持常见运营商登录与注销。

---

## ✨ 功能特性

- ✅ 支持校园网 `登录 (login)` 与 `注销 (logout)`
- ✅ 自动检测本地 IPv4 地址与网络接口
- ✅ 兼容 macOS 和 Linux
- ✅ 错误时提供接口列表和帮助文档

---

## 🚀 快速开始

### 1. 克隆项目

下载脚本dlut_net.sh，在终端中授权
```bash
chmod +x dlut_net.sh.sh
````

### 2. 登录校园网

```bash
./dlut_net.sh.sh -a login -u [username] -p [password] -d dianxin
```

### 3. 注销校园网

```bash
./dlut_net.sh.sh -a logout -u [username] -p [password] -d dianxin
```

---

## ⚙️ 参数说明

| 参数   | 是否必填 | 说明                         |
| ---- | ---- | -------------------------- |
| `-a` | ✅    | 动作类型：`login` 或 `logout`    |
| `-u` | ✅    | 学号                         |
| `-p` | ✅    | 密码                         |
| `-d` | ✅    | 网络运营商域名，见下方                |
| `-i` | ❌    | 网络接口名，如 `eth0`、`en0`，可自动识别 |

---

## 🌐 支持的运营商域名

| 运营商 | 对应参数       |
| --- | ---------- |
| 电信  | `dianxin`  |
| 联通  | `liantong` |
| 移动  | `yidong`   |
| 教育网 | `jiaoyu`   |

---

## 💡 示例

```bash
# 自动选择接口登录电信网络
./dlut_net.sh.sh -a login -u [username] -p [password] -d dianxin

# 指定网卡登录移动网络
./dlut_net.sh.sh -a login -u [username] -p [password] -d yidong -i en0

# 注销当前连接
./dlut_net.sh.sh -a logout -u [username] -p [password] -d yidong
```

---

## 🧩 系统兼容性

| 系统      | 支持状态  | 工具依赖                              |
| ------- | ----- | --------------------------------- |
| macOS   | ✅ 支持  | `ifconfig`, `awk`, `grep`, `curl` |
| Linux   | ✅ 支持  | `ip`, `awk`, `grep`, `curl`       |
| Windows | ❌ 不支持 | 推荐使用 WSL 或 Git Bash 运行脚本          |

---

## ❓ 常见问题（FAQ）

### ⚠️ 脚本提示“无法获取本地 IP 地址”？

* 请检查是否已连接校园网
* 或尝试通过 `-i` 参数手动指定正确的网卡名

### ⚠️ 报错 "Unknown parameter"?

* 检查是否输入了非法参数或忘记填写值
* 正确示例：`-a login` 而不是 `-a`

### ⚠️ 登录无响应或失败？

* 检查认证服务器地址是否是默认的 `172.17.3.10`
* 检查用户名、密码、运营商是否正确
* 使用 `curl` 时增加 `--max-time` 限制避免卡死

---

## 🔐 安全提示

* 本脚本不会保存用户名或密码，请放心使用
---

## 🧑‍💻 作者与贡献

欢迎大家提交 PR 或 Issue 改进脚本、适配更多平台。

---

## 📄 LICENSE

本项目采用 [MIT License](LICENSE)，可自由使用和修改，请保留原作者署名。

---
