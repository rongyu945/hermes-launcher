# Hermes 启动器（Hermes Launcher）

一个 macOS 原生风格的图形启动器，让你**双击即可进入 Hermes Agent 对话**，无需打开终端手动输入命令。

![macOS](https://img.shields.io/badge/macOS-12.0%2B-333333?logo=apple&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Bash](https://img.shields.io/badge/Bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)

---

## 📖 目录

- [功能简介](#功能简介)
- [截图预览](#截图预览)
- [安装方法](#安装方法)
- [使用指南](#使用指南)
- [菜单功能详解](#菜单功能详解)
- [配置说明](#配置说明)
- [常见问题 FAQ](#常见问题-faq)
- [从源码构建](#从源码构建)
- [项目结构](#项目结构)
- [许可证](#许可证)

---

## ✨ 功能简介

| 功能 | 说明 |
|------|------|
| 🖱️ **一键启动** | 双击 App 图标，自动打开 Terminal 窗口并进入 Hermes 对话菜单 |
| 💾 **对话持久化** | 所有对话自动保存在 `~/.hermes/state.db`，退出后随时恢复 |
| 📋 **历史会话列表** | 首页显示最近 20 条对话，按编号一键恢复 |
| 🔍 **更早历史浏览** | 按 `m` 浏览 300 条历史，本地分页，输入编号直接打开 |
|| 🗑️ **删除对话** | 按 `d` 删除对话，支持多选，删除后移入「最近删除」回收站 |
|| 🗑️ **最近删除** | 按 `r` 进入回收站，可恢复或彻底删除；超 7 天自动清理 |
| 🔄 **模型切换** | 按 `s` 在 DeepSeek / ECNU / LongCat 三个模型间切换 |
| 👤 **个性化昵称** | 首次启动询问昵称，之后问候语显示你的名字，随时可改 |
| 🎨 **智能问候语** | 按北京时间自动变色：DeepSeek 高峰时段亮红，其余绿色 |
| 🖥️ **窗口复用** | 重复点击 App 不会堆叠窗口，自动恢复最小化的菜单窗口 |
| 🧹 **免终端操作** | 全程图形菜单，无需记忆任何命令 |

---

## 📸 截图预览

```
❀ 欢迎回来，admin ❀
  别来无恙，山水有相逢

  0) 开始新对话
   1) Paragon残留致U盘无法写入  (22m ago)
   2) 配置清理与DeepSeek模型切换测试  (18h ago)
   3) 极短标题功能实测与代码排查  (5d ago)
   ...

  当前模型: ecnu-max    d) 删除对话记录  m) 查看更早历史  s) 切换模型    n) 更改昵称  r) 最近删除

  请选择: _
```

---

## 🚀 安装方法

### 前提条件

- macOS 12.0 或更高版本
- 已安装 [Hermes Agent](https://hermes-agent.nousresearch.com/docs)（`hermes` 命令可用）
  - 安装后确认：终端输入 `hermes --version` 能输出版本号

### 方法一：直接下载（推荐）

1. 从 [Releases](https://github.com/rongyu945/hermes-launcher/releases) 下载 `Hermes.app.zip`
2. 解压后，将 `Hermes.app` 拖入「应用程序」文件夹
3. 双击打开

### 方法二：从源码构建

```bash
# 克隆仓库
git clone https://github.com/rongyu945/hermes-launcher.git
cd hermes-launcher

# 构建 App（会生成 build/Hermes.app）
./build.sh

# 将 App 复制到应用程序文件夹
cp -R build/Hermes.app /Applications/
```

---

## 📖 使用指南

### 首次启动

1. 双击 `Hermes.app`
2. 首次使用会弹出窗口询问昵称（直接回车默认 `admin`）
3. 进入主菜单，按 `0` 开始你的第一个对话

### 日常使用

```
主菜单:
  0) 开始新对话
  1-20) 恢复历史对话（按编号）
  d) 删除对话记录
  m) 查看更早历史
  s) 切换模型
  n) 更改昵称
  q) 退出
```

### 窗口行为

- **重复点击 App**：如果菜单窗口被最小化/隐藏/置后，会自动恢复并前置，不会新开窗口
- **对话中退出**：输入 `/quit` 或 Ctrl+C 退出 Hermes 后，自动返回菜单

---

## 🧩 菜单功能详解

### 1. 开始新对话（`0`）

进入全新的 Hermes 对话会话。对话内容自动保存，退出后可从历史列表恢复。

### 2. 恢复历史对话（`1-20`）

首页列出最近 20 条对话，输入对应编号即可无缝继续之前的对话。Hermes 会自动恢复上下文。

### 3. 删除对话记录（`d`）

```
═══ 删除对话记录 ═══
输入编号删除，可空格分隔多个；b 返回

  1) 对话A  (22m ago)
  2) 对话B  (5d ago)
  ...

  要删除的编号: 1 3
  将删除: 对话A  (20260821_100000_abc123)
  将删除: 对话C  (20260820_090000_def456)
  确认删除？(按回车确认，n 取消): _
```

- 支持一次删除多个（空格分隔编号）
- 删除后列表**即时刷新**（本地同步，不重新加载）
- 删除失败的会话会保留在列表中

### 4. 查看更早历史（`m`）

- 首页只显示 20 条；按 `m` 可浏览全部 300 条历史
- 本地分页显示：`n` 更早一页、`p` 更新一页、`b` 返回
- 输入任意编号直接打开对应对话

### 5. 切换模型（`s`）

```
═══ 切换模型 ═══
切换后新对话默认使用所选模型

  1) DeepSeek（deepseek-v4-flash）
  2) ECNU（ecnu-max）
  3) LongCat（LongCat-2.0）

  选择: _
```

- 切换会同时写入 `model.default` + `model.provider` + `model.base_url` 三个配置项
- **只影响之后的新对话**，当前正在进行的对话不受影响
- 当前默认模型会显示 `← 当前默认` 标记

### 6. 更改昵称（`n`）

- 修改后立即生效，首页问候语随之更新
- 昵称保存在 `~/.hermes/.hermes-nickname`

### 7. 智能问候语颜色

欢迎词颜色按 **北京时间** 自动变化，一眼看出当前是否为 DeepSeek API 高峰时段：

| 时段 | 颜色 |
|------|------|
| **09:00-12:00**（高峰） | 🔴 亮红色 |
| **14:00-18:00**（高峰） | 🔴 亮红色 |
| **12:00-14:00**（低谷） | 🟢 绿色 |
| **18:00-次日09:00**（低谷） | 🟢 绿色 |

> 💡 深夜/凌晨用 Hermes 时欢迎词是绿色，白天高峰期是红色，方便你判断 API 是否会拥堵。

### 8. 最近删除（回收站）（`r`）

删除对话时不再直接丢失，而是移入「最近删除」回收站。

- **进入回收站**：按 `r` 查看已删除的对话列表，显示已删天数和剩余自动清除天数
- **恢复**：在普通模式下输入编号，该对话回到首页历史列表（数据库记录完整保留）
- **彻底删除**：按 `x` 进入彻底删除模式（界面顶部红色警示），再输入编号即可永久删除
- **自动清理**：超过 7 天的回收站条目会在下次启动时自动彻底删除
- **回收站为空时**：显示「回收站为空」，按回车返回

回收站清单保存在 `~/.hermes/.hermes-trash`，格式为 `删除时间戳|会话ID|标题`。

---

## ⚙️ 配置说明

所有配置都存储在标准 Hermes 位置，本 App 不引入额外状态：

| 文件 | 用途 |
|------|------|
|| `~/.hermes/state.db` | 所有对话数据库（Hermes 自动维护） |
|| `~/.hermes/config.yaml` | 模型配置（默认模型/provider/base_url） |
|| `~/.hermes/.hermes-nickname` | 昵称（首次启动自动创建） |
|| `~/.hermes/.hermes-trash` | 最近删除回收站清单（删除时间戳|会话ID|标题） |

### 支持的模型

| 选项 | 模型 | Provider | Base URL |
|------|------|----------|----------|
| 1 | DeepSeek | `deepseek` | `https://api.deepseek.com/v1` |
| 2 | ECNU | `custom:ecnu` | `https://chat.ecnu.edu.cn/open/api/v1` |
| 3 | LongCat | `custom:longcat` | `https://api.longcat.chat/openai/v1` |

> 💡 想加更多模型？编辑 `Hermes.app/Contents/Resources/hermes-menu.sh` 中的 `model_menu()` 函数即可。

---

## ❓ 常见问题 FAQ

### Q1: 双击 App 没反应？

- 确认已安装 Hermes Agent（`hermes --version` 可用）
- 首次打开如果提示「无法打开，因为无法验证开发者」，右键点击 App → 打开
- 或运行：`xattr -dr com.apple.quarantine /Applications/Hermes.app`

### Q2: 提示「无法控制 Terminal」？

系统设置 → 隐私与安全性 → 自动化，允许 Hermes 控制 Terminal。

### Q3: 为什么我的对话在另一台电脑上看不到？

对话保存在**本机** `~/.hermes/state.db`，不会同步。如需迁移，复制该文件到新机器相同位置即可。

### Q4: 换了模型为什么当前对话没变？

模型切换只影响**新对话**。当前对话内输入 `/model` 可实时切换。

### Q5: 首页只显示 20 条？

是的，首页设计为显示最近 20 条。按 `m` 可以浏览全部历史。

### Q6: 删除对话能恢复吗？

可以。删除后对话会移入「最近删除」回收站（按 `r` 进入），在回收站内输入编号即可恢复。超过 7 天或手动彻底删除后不可恢复。

### Q7: 这个 App 会修改我的 Hermes 配置吗？

只有两个操作会写配置：
- 切换模型时写 `model.default/provider/base_url`
- 首次启动时创建昵称文件
其他操作都是只读（读取会话列表）。

---

## 🔧 从源码构建

仓库包含可直接运行的 App，也提供源码供二次开发：

```
hermes-launcher/
├── Hermes.app/          # 可直接运行的 App
├── hermes-menu.sh       # 菜单脚本源码（核心）
├── launcher.sh          # 启动器脚本源码（窗口管理）
├── build.sh             # 一键构建脚本
├── README.md            # 本文档
└── LICENSE              # MIT 许可证
```

### 手动构建 App

```bash
# 1. 创建目录结构
mkdir -p Hermes.app/Contents/{MacOS,Resources}

# 2. 复制脚本
cp hermes-menu.sh Hermes.app/Contents/Resources/
cp launcher.sh Hermes.app/Contents/MacOS/Hermes
chmod +x Hermes.app/Contents/MacOS/Hermes

# 3. 生成 Info.plist
cat > Hermes.app/Contents/Info.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Hermes</string>
    <key>CFBundleDisplayName</key><string>Hermes</string>
    <key>CFBundleIdentifier</key><string>com.hermes.launcher</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleExecutable</key><string>Hermes</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>12.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF

# 4. 可选：替换图标（AppIcon.icns）

# 5. 签名（可选，本地使用可跳过）
codesign --force --deep -s - Hermes.app
```

---

## 📁 项目结构

```
hermes-launcher/
├── Hermes.app/                    # 完整可运行的 macOS App
│   └── Contents/
│       ├── MacOS/Hermes          # 启动器（窗口管理 + 打开菜单）
│       ├── Resources/
│       │   ├── hermes-menu.sh    # 菜单脚本（核心逻辑）
│       │   └── AppIcon.icns      # 应用图标
│       └── Info.plist            # App 配置
├── hermes-menu.sh                 # 菜单脚本源码
├── launcher.sh                    # 启动器源码
├── build.sh                       # 构建脚本
├── README.md                      # 本文档
└── LICENSE                        # MIT 许可证
```

### 核心文件说明

| 文件 | 作用 |
|------|------|
| `hermes-menu.sh` | 对话菜单：会话列表、删除、历史浏览、模型切换、昵称管理 |
| `launcher.sh` | 窗口管理器：检测已有菜单窗口并恢复/前置，避免多开 |

---

## 📄 许可证

[MIT License](LICENSE)

Copyright (c) 2026 Hermes Launcher contributors

---

## 🙏 致谢

- [Hermes Agent](https://hermes-agent.nousresearch.com) — 由 Nous Research 开发的 AI Agent 框架
