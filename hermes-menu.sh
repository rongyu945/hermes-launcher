#!/bin/bash
# Hermes 对话启动器 — 由 Hermes.app 调用
# 功能：开始新对话 / 恢复历史对话 / 删除对话记录 / 切换模型 / 更改昵称 / 最近删除
# 说明：Hermes 的所有对话自动保存在 ~/.hermes/state.db，这里只是选择入口。
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

HERMES_BIN="$(command -v hermes 2>/dev/null || printf '%s' "$HOME/.local/bin/hermes")"

GREEN=$'\033[0;32m'; CYAN=$'\033[0;36m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'
RED=$'\033[0;31m'; BRIGHT_RED=$'\033[91m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

# ---------- 最近删除（回收站）----------
TRASH_FILE="$HOME/.hermes/.hermes-trash"
TRASH_DAYS=7   # 超过 7 天自动彻底删除

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
# 直接查询 state.db：按本会话最近一条 user/assistant 消息时间倒序（="最近发言"排序），
# 括号显示相对时间（just now / Xm ago / yesterday / 日期）。
# 固定列宽解析已被 SQL 直查取代。
# 把 unix 时间戳转成相对时间（just now / Xm ago / yesterday / Nd ago / 日期）
rel_time() {  # $1=unix epoch（秒）
  local now diff
  now=$(date +%s)
  diff=$(( now - $1 ))
  if [ "$diff" -lt 0 ]; then diff=0; fi
  if [ "$diff" -lt 60 ]; then echo "just now"; return; fi
  if [ "$diff" -lt 3600 ]; then echo "$((diff/60))m ago"; return; fi
  if [ "$diff" -lt 86400 ]; then echo "$((diff/3600))h ago"; return; fi
  if [ "$diff" -lt 172800 ]; then echo "yesterday"; return; fi
  if [ "$diff" -lt 604800 ]; then echo "$((diff/86400))d ago"; return; fi
  echo "$(date -r "$1" "+%Y-%m-%d")"
}

fetch_sessions() {
  SESSION_IDS=(); SESSION_TITLES=(); SESSION_TIMES=()
  local line id title epoch
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    id="${line%%|*}"
    in_trash "$id" && continue   # 跳过回收站里的
    rest="${line#*|}"
    title="${rest%%|*}"; rest="${rest#*|}"
    epoch="${rest%%|*}"
    [ -z "$title" ] && title="(未命名对话)"
    [ "$title" = "—" ] && title="(未命名对话)"
    SESSION_IDS+=("$id")
    SESSION_TITLES+=("$title")
    SESSION_TIMES+=("$(rel_time "$epoch")")
  done < <(/usr/bin/sqlite3 ~/.hermes/state.db "
    SELECT s.id, COALESCE(NULLIF(s.title,''),'—'), CAST(s.started_at AS INTEGER)
    FROM sessions s
    WHERE s.source != 'qqbot'
    ORDER BY (SELECT MAX(m.timestamp) FROM messages m WHERE m.session_id=s.id AND m.role IN ('user','assistant')) DESC
    LIMIT ${1:-20};" 2>/dev/null)
}

# ---------- 最近删除（回收站）----------
# 清单格式：每行 "删除时间戳|会话ID|标题"
trash_load() {   # 读清单到全局数组 TRASH_TS TRASH_IDS TRASH_TITLES
  TRASH_TS=(); TRASH_IDS=(); TRASH_TITLES=()
  [ -f "$TRASH_FILE" ] || return 0
  local line ts id title
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    ts="${line%%|*}"; rest="${line#*|}"
    id="${rest%%|*}"; title="${rest#*|}"
    TRASH_TS+=("$ts"); TRASH_IDS+=("$id"); TRASH_TITLES+=("$title")
  done < "$TRASH_FILE"
}

trash_save() {   # 把全局数组写回清单
  local i
  : > "$TRASH_FILE"
  for ((i=0; i<${#TRASH_IDS[@]}; i++)); do
    printf '%s|%s|%s\n' "${TRASH_TS[$i]}" "${TRASH_IDS[$i]}" "${TRASH_TITLES[$i]}" >> "$TRASH_FILE"
  done
}

in_trash() {  # $1=id  判断 ID 是否在回收站
  local i
  for ((i=0; i<${#TRASH_IDS[@]}; i++)); do
    [ "${TRASH_IDS[$i]}" = "$1" ] && return 0
  done
  return 1
}

trash_add() {  # $1=id $2=title  把会话加入回收站（软删除）
  local now
  now=$(date +%s)
  TRASH_TS+=("$now"); TRASH_IDS+=("$1"); TRASH_TITLES+=("$2")
  trash_save
}

trash_remove() {  # $1=id  从回收站移除（恢复）
  local i new_ts=() new_ids=() new_titles=()
  for ((i=0; i<${#TRASH_IDS[@]}; i++)); do
    [ "${TRASH_IDS[$i]}" = "$1" ] && continue
    new_ts+=("${TRASH_TS[$i]}"); new_ids+=("${TRASH_IDS[$i]}"); new_titles+=("${TRASH_TITLES[$i]}")
  done
  TRASH_TS=("${new_ts[@]}"); TRASH_IDS=("${new_ids[@]}"); TRASH_TITLES=("${new_titles[@]}")
  trash_save
}

trash_auto_purge() {  # 自动清理超过 7 天的（真正删除数据库记录 + 从清单移除）
  [ -f "$TRASH_FILE" ] || return 0
  trash_load
  local i now kept_ts=() kept_ids=() kept_titles=() expired=()
  now=$(date +%s)
  for ((i=0; i<${#TRASH_IDS[@]}; i++)); do
    if (( now - TRASH_TS[$i] > TRASH_DAYS*86400 )); then
      expired+=("${TRASH_IDS[$i]}")
    else
      kept_ts+=("${TRASH_TS[$i]}"); kept_ids+=("${TRASH_IDS[$i]}"); kept_titles+=("${TRASH_TITLES[$i]}")
    fi
  done
  TRASH_TS=("${kept_ts[@]}"); TRASH_IDS=("${kept_ids[@]}"); TRASH_TITLES=("${kept_titles[@]}")
  trash_save
  for id in "${expired[@]}"; do
    "$HERMES_BIN" sessions delete --yes "$id" >/dev/null 2>&1
  done
  [ ${#expired[@]} -gt 0 ] && echo -e "${DIM}  已自动清理 ${#expired[@]} 条超过 ${TRASH_DAYS} 天的对话${NC}"
}

# 启动时自动清理 + 加载回收站
trash_auto_purge
trash_load

# 渲染会话列表起始下标 $1 到结束下标 $2（不含）；（首页用编号格式，删除/历史用纯数字）$3=格式
render_sessions() {
  local i fmt
  fmt="${3:-num}"   # num=编号（首页·绿色序号），plain=纯数字无色序号（删除/历史）
  for ((i=$1; i<$2; i++)); do
    if [ "$fmt" = "num" ]; then
      printf '  %s%2d%s) %s  %s(%s)%s\n' "${BOLD}${GREEN}" "$((i+1))" "${NC}" \
        "${SESSION_TITLES[$i]}" "${DIM}" "${SESSION_TIMES[$i]}" "${NC}"
    else
      printf '  %2d) %s  %s(%s)%s\n' "$((i+1))" "${SESSION_TITLES[$i]}" "${DIM}" "${SESSION_TIMES[$i]}" "${NC}"
    fi
  done
}

# 当前模型名（读 config.yaml）
current_model() {
  grep -m1 "^  default:" ~/.hermes/config.yaml 2>/dev/null | awk '{print $2}'
}

# 切换默认模型：一次写入 model.default + provider + base_url（直接改 config.yaml 顶部 model 段，避免多次启动 hermes）
# 实测 hermes config set 每次 ~0.15s ×3，本方案 sed 一次毫秒级
set_model() {  # $1=模型名 $2=provider $3=base_url
  local cfg="$HOME/.hermes/config.yaml"
  /usr/bin/sed -i '' \
    -e "s|^  default:.*|  default: $1|" \
    -e "s|^  provider:.*|  provider: $2|" \
    -e "s|^  base_url:.*|  base_url: $3|" \
    "$cfg" 2>/dev/null
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
  local _home_max=20
  [ "${#SESSION_IDS[@]}" -lt "$_home_max" ] && _home_max=${#SESSION_IDS[@]}
  render_sessions 0 "$_home_max"
  echo
  echo -e "  ${DIM}当前模型: ${BOLD}$(current_model)${NC}    ${BOLD}${YELLOW}d${NC}) 删除对话记录  ${BOLD}${CYAN}m${NC}) 查看更早历史  ${BOLD}${RED}s${NC}) 切换模型    ${BOLD}${GREEN}n${NC}) 更改昵称  ${BOLD}${BLUE}r${NC}) 最近删除"
  echo
}

run_hermes() {
  local args="$1"
  set_win_title "Hermes"
  clear
  echo -e "${CYAN}正在启动 Hermes ...${NC}"
  # 若是恢复已有会话，提示可能因长上下文而慢（避免显得死机）
  if [[ "$args" == *"--resume"* ]]; then
    echo -e "  ${DIM}正在加载对话上下文，长对话可能需要几秒...${NC}"
  fi
  echo -e "  ${DIM}对话会自动保存；退出后按回车返回菜单${NC}"
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
    render_sessions 0 ${#SESSION_IDS[@]} plain
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
      echo -e "  ${RED}将移入最近删除:${NC} ${SESSION_TITLES[$((num-1))]}  (${SESSION_IDS[$((num-1))]})"
    done
    printf '  确认移入最近删除？(按回车确认，n 取消): '
    read -r confirm
    [[ "$confirm" =~ ^[nN] ]] && { echo "已取消"; sleep 1; continue; }
    # 软删除：加入回收站（不真正删除数据库），本地同步列表
    local kept_ids=() kept_titles=() kept_times=()
    for ((i=0; i<${#SESSION_IDS[@]}; i++)); do
      if [[ " ${picks[*]} " == *" $((i+1)) "* ]]; then
        trash_add "${SESSION_IDS[$i]}" "${SESSION_TITLES[$i]}"
        echo -e "${GREEN}  已移入最近删除: ${SESSION_TITLES[$i]}${NC}"
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
    render_sessions "$start" "$end" plain
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

# ---------- 最近删除（回收站）----------
trash_menu() {
  local mode="normal"   # normal=普通(编号恢复)，del=彻底删除模式(编号彻底删)
  while true; do
    trash_load   # 重新加载，反映最新状态
    set_win_title "Hermes · 最近删除"
    clear
    echo
    echo -e "  ${BOLD}${YELLOW}═══ 最近删除 ═══${NC}"
    if [ ${#TRASH_IDS[@]} -eq 0 ]; then
      echo
      echo -e "  ${DIM}回收站为空${NC}"
      echo
      read -r -p "  按回车返回..."
      return
    fi
    echo
    local now i di remain
    now=$(date +%s)
    for ((i=0; i<${#TRASH_IDS[@]}; i++)); do
      di=$(( (now - TRASH_TS[$i]) / 86400 ))
      [ "$di" -lt 0 ] && di=0
      remain=$(( TRASH_DAYS - di ))
      printf '  %2d) %s  %s(已 %d 天，剩 %d 天自动清除)%s\n' "$((i+1))" \
        "${TRASH_TITLES[$i]}" "${DIM}" "$di" "$remain" "${NC}"
    done
    echo
    if [ "$mode" = "del" ]; then
      echo -e "  ${RED}[[ 彻底删除模式 ]]${NC} 输入编号将${BOLD}彻底删除${NC}（不可恢复）；b 退出该模式"
    else
      echo -e "  ${DIM}输入编号恢复；x 进入彻底删除模式；b 返回（超过 ${TRASH_DAYS} 天自动清除）${NC}"
    fi
    echo
    printf '  选择: '
    read -r sel
    case "$sel" in
      b|B|"") 
        if [ "$mode" = "del" ]; then mode="normal"; continue; fi
        return ;;
      x|X)
        mode="del"; continue ;;
      *[0-9]*)
        if [[ "$sel" =~ ^[0-9]+$ ]]; then
          local n=$sel
          if (( n >= 1 && n <= ${#TRASH_IDS[@]} )); then
            local tid=${TRASH_IDS[$((n-1))]}
            if [ "$mode" = "del" ]; then
              "$HERMES_BIN" sessions delete --yes "$tid" >/dev/null 2>&1
              trash_remove "$tid"
              echo -e "${RED}  已彻底删除: ${TRASH_TITLES[$((n-1))]}${NC}"; sleep 1
            else
              trash_remove "$tid"
              echo -e "${GREEN}  已恢复: ${TRASH_TITLES[$((n-1))]}${NC}"; sleep 1
            fi
          else
            echo -e "${RED}  无效编号${NC}"; sleep 1
          fi
        else
          echo -e "${RED}  无效选项: $sel${NC}"; sleep 1
        fi
        ;;
      *) echo -e "${RED}  无效选项: $sel${NC}"; sleep 1 ;;
    esac
  done
}

# ---------- 主循环 ----------
main_loop() {
  while true; do
    fetch_sessions 30   # 拉取 30 条以便回收站过滤后首页仍能补位到 20 条，多出的可在更早历史看到
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
      r|R) trash_menu ;;
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
