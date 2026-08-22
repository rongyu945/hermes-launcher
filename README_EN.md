# Hermes Launcher

A native-style macOS launcher for **Hermes Agent** — double-click your way into a Hermes conversation without opening a terminal and typing commands.

![macOS](https://img.shields.io/badge/macOS-12.0%2B-333333?logo=apple&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Bash](https://img.shields.io/badge/Bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)

> 🌐 **Language:** [English](./README_EN.md) | [简体中文](./README.md)

---

## 📖 Table of Contents

- [Features](#features)
- [Screenshot Preview](#screenshot-preview)
- [Installation](#installation)
- [Usage Guide](#usage-guide)
- [Menu Details](#menu-details)
- [Configuration](#configuration)
- [FAQ](#faq)
- [Build from Source](#build-from-source)
- [Project Structure](#project-structure)
- [License](#license)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🖱️ **One-Click Launch** | Double-click the app icon to open a Terminal window with the Hermes menu |
| 💾 **Conversation Persistence** | All conversations auto-save to `~/.hermes/state.db`, recoverable anytime |
| 📋 **Recent Session List** | Home screen shows the 20 most recent conversations, numbered for one-key resume |
| 🕐 **Recent-Activity Sorting** | Sessions are sorted by each session's **latest message time** (most recent first) |
| 🕒 **Relative Timestamps** | Show friendly relative times: `just now`, `3m ago`, `yesterday`, or a date |
| 🔍 **History Browser** | Press `m` to browse up to 300 sessions, paginated locally, open by number |
| 🗑️ **Delete Conversations** | Press `d` to delete (multi-select supported); deleted items go to the trash |
| 🗑️ **Recently Deleted** | Press `r` for the trash: restore or permanently delete; auto-cleans after 7 days |
| 🔄 **Model Switching** | Press `s` to switch between DeepSeek / ECNU / LongCat |
| 👤 **Custom Nickname** | Asked on first launch; shown in the greeting and changeable anytime |
| 🎨 **Smart Greeting Color** | Auto-colors by Beijing time: bright red during DeepSeek peak hours, green otherwise |
| 🖥️ **Window Reuse** | Re-clicking the app never stacks windows; restores a minimized menu window automatically |
| 🧹 **No Terminal Needed** | Full graphical menu — no commands to memorize |

---

## 📸 Screenshot Preview

```
❀ Welcome back, admin ❀

  0) Start a new conversation
   1) Morning notes  (22m ago)
   2) Project planning  (18h ago)
   3) Reading list  (5d ago)
   ...

  Current model: ecnu-max    d) Delete  m) History  s) Switch model    n) Nickname  r) Recently Deleted

  Select: _
```

> The timestamp in parentheses after each title is a **relative time** (e.g. `3m ago`, `yesterday`), always displayed in gray for a consistent look.

---

## 🚀 Installation

### Prerequisites

- macOS 12.0 or later
- [Hermes Agent](https://hermes-agent.nousresearch.com/docs) installed (the `hermes` command available)
  - Verify: run `hermes --version` in a terminal — it should print a version number

### Method 1: Direct Download (Recommended)

1. Download `Hermes.app.zip` from [Releases](https://github.com/rongyu945/hermes-launcher/releases)
2. Unzip, then drag `Hermes.app` into the Applications folder
3. Double-click to open

### Method 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/rongyu945/hermes-launcher.git
cd hermes-launcher

# Build the app (produces build/Hermes.app)
./build.sh

# Copy the app to your Applications folder
cp -R build/Hermes.app /Applications/
```

---

## 📖 Usage Guide

### First Launch

1. Double-click `Hermes.app`
2. On first use a window asks for your nickname (press Enter for the default `admin`)
3. You'll see the main menu; press `0` to start your first conversation

### Daily Use

```
Main menu:
  0) Start a new conversation
  1-20) Resume a past conversation (by number)
  d) Delete conversations
  m) View older history
  s) Switch model
  n) Change nickname
  r) Recently deleted
  q) Quit
```

### Window Behavior

- **Re-clicking the app**: if the menu window is minimized/hidden/behind, it is restored and brought to front — never opens a new window
- **Exiting a conversation**: after typing `/quit` or pressing Ctrl+C in Hermes, you return to the menu automatically

---

## 🧩 Menu Details

### 1. Start a New Conversation (`0`)

Opens a fresh Hermes conversation. Content is auto-saved and can be resumed from the history list after exiting.

### 2. Resume a Past Conversation (`1-20`)

The home screen lists the 20 most recent conversations (sorted by their latest message time). Type the number to seamlessly continue. Hermes restores the context automatically.

### 3. Delete Conversations (`d`)

```
═══ Delete Conversations ═══
Enter numbers to delete (space-separated for multiple); b to go back

  1) Conversation A  (22m ago)
  2) Conversation B  (5d ago)
  ...

  Numbers to delete: 1 3
  Moving to Recently Deleted: Conversation A  (20260821_100000_abc123)
  Moving to Recently Deleted: Conversation C  (20260820_090000_def456)
  Confirm? (Enter to confirm, n to cancel): _
```

- Supports deleting multiple at once (space-separated numbers)
- The list **refreshes instantly** after deletion (local sync, no reload)
- Failed deletions keep the session in the list

### 4. View Older History (`m`)

- The home screen shows only 20; press `m` to browse up to 300
- Paginated locally: `n` older page, `p` newer page, `b` back
- Type any number to open that conversation

### 5. Switch Model (`s`)

```
═══ Switch Model ═══
New conversations will use the selected model by default

  1) DeepSeek（deepseek-v4-flash）
  2) ECNU（ecnu-max）
  3) LongCat（LongCat-2.0）

  Select: _
```

- Switching writes `model.default` + `model.provider` + `model.base_url`
- **Only affects new conversations**; the current conversation is untouched
- The current default model shows a `← current default` marker

### 6. Change Nickname (`n`)

- Takes effect immediately; the home greeting updates
- Saved to `~/.hermes/.hermes-nickname`

### 7. Smart Greeting Color

The greeting color changes by **Beijing time** to show whether you're in DeepSeek API peak hours:

| Time window | Color |
|-------------|-------|
| **09:00-12:00** (peak) | 🔴 Bright red |
| **14:00-18:00** (peak) | 🔴 Bright red |
| **12:00-14:00** (off-peak) | 🟢 Green |
| **18:00-09:00 next day** (off-peak) | 🟢 Green |

> 💡 The greeting is green late at night / early morning and red during daytime peak hours, so you can tell at a glance whether the API might be congested.

### 8. Recently Deleted / Trash (`r`)

Deleting a conversation no longer loses it — it moves to the "Recently Deleted" trash.

- **Enter the trash**: press `r` to list deleted conversations, showing days deleted and remaining days before auto-purge
- **Restore**: in normal mode type a number — the conversation returns to the home history list (the database record stays intact)
- **Permanently delete**: press `x` to enter permanent-delete mode (red warning at the top), then type a number to erase forever
- **Auto-cleanup**: trash entries older than 7 days are permanently deleted on next launch
- **Empty trash**: shows "Trash is empty"; press Enter to go back

The trash list is stored in `~/.hermes/.hermes-trash` in the format `deleted-timestamp|session-id|title`.

---

## ⚙️ Configuration

All config lives in standard Hermes locations — this app adds no extra state:

| File | Purpose |
|------|---------|
| `~/.hermes/state.db` | Conversation database (maintained by Hermes) |
| `~/.hermes/config.yaml` | Model config (default model / provider / base_url) |
| `~/.hermes/.hermes-nickname` | Nickname (auto-created on first launch) |
| `~/.hermes/.hermes-trash` | Recently-deleted list (deleted-timestamp\|session-id\|title) |

### Supported Models

| Option | Model | Provider | Base URL |
|--------|-------|----------|----------|
| 1 | DeepSeek | `deepseek` | `https://api.deepseek.com/v1` |
| 2 | ECNU | `custom:ecnu` | `https://chat.ecnu.edu.cn/open/api/v1` |
| 3 | LongCat | `custom:longcat` | `https://api.longcat.chat/openai/v1` |

> 💡 Want more models? Edit the `model_menu()` function in `Hermes.app/Contents/Resources/hermes-menu.sh`.

---

## ❓ FAQ

### Q1: Double-clicking the app does nothing?

- Make sure Hermes Agent is installed (`hermes --version` works)
- If the first open says "cannot be opened because the developer cannot be verified", right-click the app → Open
- Or run: `xattr -dr com.apple.quarantine /Applications/Hermes.app`

### Q2: "Cannot control Terminal"?

System Settings → Privacy & Security → Automation, and allow Hermes to control Terminal.

### Q3: Why can't I see my conversations on another computer?

Conversations are stored **locally** in `~/.hermes/state.db` and are not synced. To migrate, copy that file to the same location on the new machine.

### Q4: Why didn't my current conversation change after switching models?

Model switching only affects **new conversations**. Inside the current conversation, type `/model` to switch live.

### Q5: Only 20 items on the home screen?

Yes — the home screen is designed to show the 20 most recent. Press `m` to browse all history.

### Q6: Can deleted conversations be recovered?

Yes. Deleting moves a conversation to "Recently Deleted" (press `r`), and typing its number there restores it. It can't be recovered once 7 days pass or after a manual permanent delete.

### Q7: Does this app modify my Hermes config?

Only two operations write config:
- Switching models writes `model.default` / `model.provider` / `model.base_url`
- First launch creates the nickname file
Everything else is read-only (reading the session list).

---

## 🔧 Build from Source

The repository ships a ready-to-run app and also the source for further development:

```
hermes-launcher/
├── Hermes.app/          # Ready-to-run app
├── hermes-menu.sh       # Menu script source (core)
├── launcher.sh          # Launcher script source (window management)
├── build.sh             # One-click build script
├── README.md            # This document (Chinese)
├── README_EN.md         # English document
└── LICENSE              # MIT License
```

### Build Manually

```bash
# 1. Create the directory structure
mkdir -p Hermes.app/Contents/{MacOS,Resources}

# 2. Copy scripts
cp hermes-menu.sh Hermes.app/Contents/Resources/
cp launcher.sh Hermes.app/Contents/MacOS/Hermes
chmod +x Hermes.app/Contents/MacOS/Hermes

# 3. Generate Info.plist
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

# 4. Optional: replace the icon (AppIcon.icns)

# 5. Sign (optional; skip for local use)
codesign --force --deep -s - Hermes.app
```

---

## 📁 Project Structure

```
hermes-launcher/
├── Hermes.app/                    # Complete runnable macOS app
│   └── Contents/
│       ├── MacOS/Hermes          # Launcher (window management + opens menu)
│       ├── Resources/
│       │   ├── hermes-menu.sh    # Menu script (core logic)
│       │   └── AppIcon.icns      # App icon
│       └── Info.plist            # App config
├── hermes-menu.sh                 # Menu script source
├── launcher.sh                    # Launcher source
├── build.sh                       # Build script
├── README.md                      # This document (Chinese)
├── README_EN.md                   # English document
└── LICENSE                        # MIT License
```

### Key Files

| File | Purpose |
|------|---------|
| `hermes-menu.sh` | Conversation menu: session list, delete, history, model switch, nickname |
| `launcher.sh` | Window manager: detects and restores the menu window, avoids duplicates |

---

## 📄 License

[MIT License](LICENSE)

Copyright (c) 2026 Hermes Launcher contributors

---

## 🙏 Acknowledgements

- [Hermes Agent](https://hermes-agent.nousresearch.com) — the AI Agent framework by Nous Research