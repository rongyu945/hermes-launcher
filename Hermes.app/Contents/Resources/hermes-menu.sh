#!/bin/bash
# Hermes 对话启动器 — 由 Hermes.app 调用
# 功能：开始新对话 / 恢复历史对话 / 删除对话记录 / 切换模型 / 更改昵称
# 说明：Hermes 的所有对话自动保存在 ~/.hermes/state.db，这里只是选择入口。
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

HERMES_BIN="$(command -v hermes 2>/dev/null || printf '%s' "$HOME/.local/bin/hermes")"

GREEN=$'\033[0;32m'; CYAN=$'\033[0;36m'; YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'; BRIGHT_RED=$'\033[91m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

NICKNAME_FILE="$HOME/.hermes/.hermes-nickname"

# ---------- 昵称 ----------
get_nickname() {
  if [[ -s "$NICKNAME_FILE" ]]; then
    cat "$NICKNAME_FILE"
    return
  fi
  local name
  clear
  echo
  echo -e "  ${BOLD}${CYAN}❀ 欢迎使用 Hermes ❀${NC}"
  echo
  echo -e "  ${DIM}这是你第一次使用。${NC}"
  echo
  printf '  你希望我怎么称呼你？: '
  read -r name
  name="${name## }"; name="${name%% }"
  [[ -z "$name" ]] && name="admin"
  printf '%s' "$name" > "$NICKNAME_FILE"
  echo "$name"
}

NICKNAME="$(get_nickname)"

# ---------- 问候语颜色（DeepSeek 高峰：北京 09-12 / 14-18 亮红，其余绿）----------
_GREET_COLOR="$GREEN"
_HOUR="${DEEPSEEK_PEAK_HOUR:-$(TZ=Asia/Shanghai date +%H)}"
_HOUR=$((10#${_HOUR}))
if { [ "$_HOUR" -ge 9 ] && [ "$_HOUR" -lt 12 ]; } || { [ "$_HOUR" -ge 14 ] && [ "$_HOUR" -lt 18 ]; }; then
  _GREET_COLOR="$BRIGHT_RED"
fi

# 把窗口标题设为 Hermes，方便 app 复用它（避免堆叠多个窗口）
set_win_title() { printf '\033]0;%s\007' "$1"; }

if [ ! -x "$HERMES_BIN" ]; then
  echo -e "${RED}错误：找不到 hermes 命令。${NC}"
  echo "请确认 Hermes 已安装，或编辑本脚本顶部的 HERMES_BIN 路径。"
  read -r -p "按回车退出..."
  exit 1
fi

SESSION_IDS=()
SESSION_TITLES=()
SESSION_TIMES=()

# ---------- 会话列表 ----------
# 解析 hermes sessions list 的输出（固定列宽表格）：
#   Title 占 1-28 列, Workspace 从 30 列, Last Active 从 49 列, ID 从 63 列
# 用固定列宽切分，避免逐 token 猜测（"yesterday"/"3h ago"/日期等格式都安全）
fetch_sessions() {
  SESSION_IDS=(); SESSION_TITLES=(); SESSION_TIMES=()
  local line id title t
  while IFS= read -r line; do
    [ ${#line} -lt 84 ] && continue
    id="${line:62:22}"
    [[ "$id" =~ ^[0-9]{8}_[0-9]{6}_[a-f0-9]{6}$ ]] || continue
    title="${line:0:28}"
    t="${line:48:14}"
    # 去尾部空格
    title="${title%${title##*[![:space:]]}}"
    t="${t%${t##*[![:space:]]}}"
    [ -z "$title" ] && title="(未命名对话)"
    [ "$title" = "—" ] && title="(未命名对话)"
    SESSION_IDS+=("$id")
    SESSION_TITLES+=("$title")
    SESSION_TIMES+=("$t")
  done < <("$HERMES_BIN" sessions list --limit "${1:-20}" 2>/dev/null | tail -n +3)
}

# 渲染会话列表（首页/删除/历史共用）
render_sessions() {  # $1=起始下标(含) $2=结束下标(不含)
  local i
  for ((i=$1; i<$2; i++)); do
    printf '  %s%2d%s) %s  %s(%s)%s\n' "${BOLD}${GREEN}" "$((i+1))" "${NC}" \
      "${SESSION_TITLES[$i]}" "${DIM}" "${SESSION_TIMES[$i]}" "${NC}"
  done
}

# 当前模型名（读 config.yaml）
current_model() {
  grep -m1 "^  default:" ~/.hermes/config.yaml 2>/dev/null | awk '{print $2}'
}

# 切换默认模型：写入 model.default + provider + base_url（与 /model X --global 落盘一致）
set_model() {  # $1=模型名 $2=provider $3=base_url
  "$HERMES_BIN" config set model.default "$1" >/dev/null 2>&1 \
    && "$HERMES_BIN" config set model.provider "$2" >/dev/null 2>&1 \
    && "$HERMES_BIN" config set model.base_url "$3" >/dev/null 2>&1
}

# ---------- 主菜单 ----------
print_main_menu() {
  set_win_title "Hermes"
  clear
  echo
  echo -e "  ${BOLD}${_GREET_COLOR}❀ 欢迎回来，${NICKNAME} ❀${NC}"
  echo -e "  ${DIM}别来无恙，山水有相逢${NC}"
  echo
  echo -e "  ${BOLD}${GREEN}0${NC}) 开始新对话"
  render_sessions 0 ${#SESSION_IDS[@]}
  echo
  echo -e "  ${DIM}当前模型: ${BOLD}$(current_model)${NC}    ${BOLD}${YELLOW}d${NC}) 删除对话记录  ${BOLD}${CYAN}m${NC}) 查看更早历史  ${BOLD}${RED}s${NC}) 切换模型    ${BOLD}${GREEN}n${NC}) 更改昵称"
  echo
}

run_hermes() {
  local args="$1"
  set_win_title "Hermes"
  clear
  echo -e "${CYAN}正在启动 Hermes ...${NC}（对话会自动保存；退出后按回车返回菜单）"
  echo
  # shellcheck disable=SC2086
  "$HERMES_BIN" $args
  echo
  read -r -p "按回车返回菜单..." _
}

# ---------- 删除对话 ----------
delete_menu() {
  while true; do
    fetch_sessions
    set_win_title "Hermes"
    clear
    echo
    echo -e "  ${BOLD}${RED}═══ 删除对话记录 ═══${NC}"
    echo -e "  ${DIM}输入编号删除，可空格分隔多个；b 返回${NC}"
    echo
    render_sessions 0 ${#SESSION_IDS[@]}
    echo
    printf '  要删除的编号: '
    read -r sel
    case "$sel" in
      b|B|"") return ;;
    esac
    local picks=() valid=1 num
    for num in $sel; do
      if [[ "$num" =~ ^[0-9]+$ ]] && ((num >= 1 && num <= ${#SESSION_IDS[@]})); then
        picks+=("$num")
      else
        valid=0
      fi
    done
    if [ "$valid" = 0 ] || [ ${#picks[@]} -eq 0 ]; then
      echo -e "${RED}  无效编号${NC}"; sleep 1; continue
    fi
    echo
    for num in "${picks[@]}"; do
      echo -e "  ${RED}将删除:${NC} ${SESSION_TITLES[$((num-1))]}  (${SESSION_IDS[$((num-1))]})"
    done
    printf '  确认删除？(按回车确认，n 取消): '
    read -r confirm
    [[ "$confirm" =~ ^[nN] ]] && { echo "已取消"; sleep 1; continue; }
    # 执行删除并在本地同步列表（不重新调用 hermes，删除后立即回到列表不卡顿）
    local kept_ids=() kept_titles=() kept_times=()
    for ((i=0; i<${#SESSION_IDS[@]}; i++)); do
      if [[ " ${picks[*]} " == *" $((i+1)) "* ]]; then
        if "$HERMES_BIN" sessions delete --yes "${SESSION_IDS[$i]}" >/dev/null 2>&1; then
          echo -e "${GREEN}  已删除: ${SESSION_TITLES[$i]}${NC}"
        else
          echo -e "${RED}  删除失败: ${SESSION_TITLES[$i]}${NC}"
          kept_ids+=("${SESSION_IDS[$i]}"); kept_titles+=("${SESSION_TITLES[$i]}"); kept_times+=("${SESSION_TIMES[$i]}")
        fi
      else
        kept_ids+=("${SESSION_IDS[$i]}"); kept_titles+=("${SESSION_TITLES[$i]}"); kept_times+=("${SESSION_TIMES[$i]}")
      fi
    done
    SESSION_IDS=("${kept_ids[@]}"); SESSION_TITLES=("${kept_titles[@]}"); SESSION_TIMES=("${kept_times[@]}")
    sleep 0.4
  done
}

# ---------- 更早历史 ----------
history_menu() {
  fetch_sessions 300
  local total=${#SESSION_IDS[@]}
  if [ "$total" -le 20 ]; then
    clear
    echo
    echo -e "  ${YELLOW}没有更早的历史对话了${NC}"
    sleep 1
    return
  fi
  local page=1 per=20 sel start end i
  local maxpage=$(( (total - 1) / per ))
  while true; do
    set_win_title "Hermes · 历史浏览器"
    clear
    echo
    echo -e "  ${BOLD}${CYAN}═══ 更早的历史对话 ═══${NC}"
    echo -e "  ${DIM}第 $((page+1))/$((maxpage+1)) 页（共 ${total} 条）· 输入编号打开 · n 更早一页 · p 更新一页 · b 返回${NC}"
    echo
    start=$((page * per)); end=$((start + per))
    [ "$end" -gt "$total" ] && end=$total
    render_sessions "$start" "$end"
    echo
    printf '  选择: '
    read -r sel
    case "$sel" in
      b|B|"") return ;;
      q|Q|quit|exit) echo "再见！"; exit 0 ;;
      n|N) [ "$page" -lt "$maxpage" ] && page=$((page+1)) || { echo -e "  ${YELLOW}已经没有更早的了${NC}"; sleep 1; } ;;
      p|P) [ "$page" -gt 0 ] && page=$((page-1)) || { echo -e "  ${YELLOW}已经是最新一页了${NC}"; sleep 1; } ;;
      *)
        if [[ "$sel" =~ ^[0-9]+$ ]] && ((sel >= 1 && sel <= total)); then
          run_hermes "--resume ${SESSION_IDS[$((sel-1))]}"
        else
          echo -e "  ${RED}无效选项: $sel${NC}"; sleep 1
        fi
        ;;
    esac
  done
}

# ---------- 切换模型 ----------
model_menu() {
  local cur cur_lc sel
  cur=$(current_model)
  while true; do
    clear
    echo
    echo -e "  ${BOLD}${CYAN}═══ 切换模型 ═══${NC}"
    echo -e "  ${DIM}切换后新对话默认使用所选模型${NC}"
    echo
    cur_lc=$(echo "$cur" | tr '[:upper:]' '[:lower:]')
    if [[ "$cur_lc" == deepseek* ]]; then
      echo -e "  ${BOLD}${GREEN}1${NC}) DeepSeek（deepseek-v4-flash）${DIM}← 当前默认${NC}"
    else
      echo -e "  ${BOLD}1${NC}) DeepSeek（deepseek-v4-flash）"
    fi
    if [[ "$cur_lc" == *ecnu* ]]; then
      echo -e "  ${BOLD}${GREEN}2${NC}) ECNU（ecnu-max）${DIM}← 当前默认${NC}"
    else
      echo -e "  ${BOLD}2${NC}) ECNU（ecnu-max）"
    fi
    if [[ "$cur_lc" == *longcat* ]]; then
      echo -e "  ${BOLD}${GREEN}3${NC}) LongCat（LongCat-2.0）${DIM}← 当前默认${NC}"
    else
      echo -e "  ${BOLD}3${NC}) LongCat（LongCat-2.0）"
    fi
    echo
    echo -e "  ${DIM}b 返回${NC}"
    echo
    printf '  选择: '
    read -r sel
    case "$sel" in
      b|B|"") return ;;
      1) set_model deepseek-v4-flash deepseek https://api.deepseek.com/v1 \
           && cur=deepseek-v4-flash && echo -e "  ${GREEN}已切换到 DeepSeek（默认）${NC}"; sleep 1 ;;
      2) set_model ecnu-max custom:ecnu https://chat.ecnu.edu.cn/open/api/v1 \
           && cur=ecnu-max && echo -e "  ${GREEN}已切换到 ECNU（默认）${NC}"; sleep 1 ;;
      3) set_model LongCat-2.0 custom:longcat https://api.longcat.chat/openai/v1 \
           && cur=LongCat-2.0 && echo -e "  ${GREEN}已切换到 LongCat（默认）${NC}"; sleep 1 ;;
      *) echo -e "  ${RED}无效选项: $sel${NC}"; sleep 1 ;;
    esac
  done
}

# ---------- 更改昵称 ----------
rename_nickname() {
  local name
  clear
  echo
  echo -e "  ${BOLD}${CYAN}═══ 更改昵称 ═══${NC}"
  echo
  printf '  新的昵称: '
  read -r name
  name="${name## }"; name="${name%% }"
  if [[ -n "$name" ]]; then
    printf '%s' "$name" > "$NICKNAME_FILE"
    NICKNAME="$name"
    echo -e "  ${GREEN}已更新为：${name}${NC}"
  else
    echo -e "  ${DIM}昵称未更改${NC}"
  fi
  sleep 1
}

# ---------- 主循环 ----------
main_loop() {
  while true; do
    fetch_sessions
    print_main_menu
    printf '  请选择: '
    read -r choice
    case "$choice" in
      q|Q|quit|exit) echo "再见！"; exit 0;;
      0|new) run_hermes "" ;;
      d|D) delete_menu ;;
      m|M) history_menu ;;
      s|S) model_menu ;;
      n|N) rename_nickname ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#SESSION_IDS[@]})); then
          run_hermes "--resume ${SESSION_IDS[$((choice-1))]}"
        else
          echo -e "${RED}  无效选项: $choice${NC}"; sleep 1
        fi
        ;;
    esac
  done
}

main_loop
