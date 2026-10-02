# wholespace-frappe: the oh-my-posh "wholespace" theme rebuilt for oh-my-zsh,
# in the Catppuccin Frappé palette. Mirrors ~/.config/oh-my-posh/wholespace-frappe.omp.json
# (the Windows/WezTerm setup), so both machines show the same prompt.
#
# Line 1:  OS · clock · CPU/RAM · last command time            [node] git
# Line 2:  path, status icon
# After Enter, the prompt collapses to a single arrow (transient prompt).
#
# Needs a Nerd Font for the icons (ttf-nerd-fonts-symbols-mono) and truecolor (kitty has it).

zmodload zsh/datetime zsh/langinfo

# The icons need a UTF-8 locale. Without one, zsh mangles them and miscounts the prompt width,
# so fall back to C.UTF-8 (present on every glibc system) when the current locale isn't UTF-8.
[[ ${langinfo[CODESET]} == UTF-8 ]] || export LC_CTYPE=C.UTF-8
setopt prompt_subst
autoload -Uz add-zsh-hook add-zle-hook-widget

typeset -gA _ws_c=(
  crust    '#232634'  mantle  '#292c3c'  surface0 '#414559'  surface1 '#51576d'
  lavender '#babbf1'  blue    '#8caaee'  sapphire '#85c1dc'  sky      '#99d1db'
  green    '#a6d189'  yellow  '#e5c890'  peach    '#ef9f76'  red      '#e78284'
)

# Nerd Font glyphs by code point; ${(#):-0xNNNN} turns a number into that character
typeset -gA _ws_g=(
  left      "${(#):-0xE0B2}"  right   "${(#):-0xE0B0}"  heart  "${(#):-0x2665}"
  chip      "${(#):-0xE266}"  folder  "${(#):-0xE5FF}"  status   "${(#):-0xEB05}"   tprompt "${(#):-0xE285}"
  node      "${(#):-0xE718}"  npm     "${(#):-0xE5FA}"  yarn     "${(#):-0xE6A7}"
  branch    "${(#):-0xE725} " commit  "${(#):-0xF417}"  stash    "${(#):-0xEB4B}"
  working   "${(#):-0xF044}"  staged  "${(#):-0xF046}"
  github    "${(#):-0xF408}"  gitlab  "${(#):-0xF296}"  bitbucket "${(#):-0xF171}"  azure  "${(#):-0xEBE8}"  git "${(#):-0xE5FB} "
  ahead     "${(#):-0x2191}"  behind  "${(#):-0x2193}"  equal    "${(#):-0x2261}"   gone   "${(#):-0x2262}"
)

# OS logo picked from /etc/os-release, like oh-my-posh's os segment (generic Linux penguin otherwise)
typeset -gA _ws_os_icons=(
  arch 0xF303  debian 0xF306  ubuntu 0xF31B  fedora 0xF30A  manjaro 0xF312  alpine 0xF300
  centos 0xF304  gentoo 0xF30D  opensuse 0xF314  raspbian 0xF315  linuxmint 0xF30F  elementary 0xF309
)
() {
  local id
  [[ -r /etc/os-release ]] && id=${${${(M)${(f)"$(</etc/os-release)"}:#ID=*}#ID=}//\"/}
  _ws_g[os]="${(#):-${_ws_os_icons[$id]:-0xE712}} "
}

# --- drawing helpers (zsh prompt escapes, so width counting stays correct) ---

# Rounded cap on the left of a pill: glyph in the pill colour on the terminal background
_ws_open()  { print -rn -- "%F{${_ws_c[$1]}}${_ws_g[left]}%f" }
# Pill body
_ws_pill()  { print -rn -- "%K{${_ws_c[$1]}}%F{${_ws_c[$2]}}$3%f%k" }
# Notch cut out of the pill's right edge (reverse video = terminal background shows through)
_ws_notch() { print -rn -- "%F{${_ws_c[$1]}}%S${_ws_g[left]}%s%f" }
# Arrow closing a pill
_ws_close() { print -rn -- "%F{${_ws_c[$1]}}${_ws_g[right]}%f" }
# Literal text inside a prompt: escape %
_ws_lit()   { print -rn -- "${1//\%/%%}" }

# --- segments ---

_ws_cpu() {
  setopt local_options extended_glob
  local -a f; f=(${=${(M)${(f)"$(</proc/stat)"}:#cpu *}})
  local -i idle=$(( f[5] + f[6] )) total=0 v
  for v in ${f[2,-1]}; do (( total += v )); done
  local -i dt=$(( total - ${_ws_cpu_total:-0} )) di=$(( idle - ${_ws_cpu_idle:-0} ))
  typeset -gi _ws_cpu_total=$total _ws_cpu_idle=$idle
  local pct; (( dt > 0 )) && pct=$(( 100.0 * (dt - di) / dt )) || pct=0
  pct=$(printf '%.2f' $pct); pct=${pct%%0#}; pct=${pct%.}
  print -rn -- $pct
}

_ws_ram() {
  local line; local -i total=0 avail=0
  for line in ${(f)"$(</proc/meminfo)"}; do
    case $line in
      MemTotal:*)     total=${${line#*:}%kB} ;;
      MemAvailable:*) avail=${${line#*:}%kB} ;;
    esac
  done
  printf '%.1f/%.0f' $(( (total - avail) / 1048576.0 )) $(( total / 1048576.0 ))
}

# oh-my-posh "roundrock" style: 214ms, 1s 214ms, 1m 15s 432ms, 1h 2m 5s 0ms
_ws_duration() {
  local -i ms=$1
  local -a u=( $(( ms / 86400000 ))d $(( ms / 3600000 % 24 ))h $(( ms / 60000 % 60 ))m $(( ms / 1000 % 60 ))s $(( ms % 1000 ))ms )
  while (( $#u > 1 )) && [[ ${u[1]} == 0* ]]; do shift u; done
  print -rn -- "${(j: :)u}"
}

_ws_path() {
  local p
  if [[ $PWD == $HOME ]]; then p=home
  elif [[ $PWD == $HOME/* ]]; then p=home/${PWD#$HOME/}
  elif [[ $PWD == / ]]; then p=/
  else p=${PWD#/}
  fi
  _ws_lit "$p"
}

_ws_node() {
  local -a js=( *.(js|mjs|cjs|ts|tsx)(N[1]) )
  [[ -f package.json || -f .nvmrc || -f .node-version || $#js -gt 0 ]] || return
  (( $+commands[node] )) || return
  local bin=${commands[node]}
  if [[ $bin != $_ws_node_bin ]]; then
    typeset -g _ws_node_bin=$bin _ws_node_ver=${$(node --version 2>/dev/null)#v}
  fi
  local icon
  if [[ -f yarn.lock ]]; then icon=" %F{${_ws_c[sapphire]}}${_ws_g[yarn]}%F{${_ws_c[green]}} "
  elif [[ -f package-lock.json ]]; then icon=" %F{${_ws_c[red]}}${_ws_g[npm]}%F{${_ws_c[green]}}  "
  fi
  print -rn -- "$(_ws_open surface0)$(_ws_pill surface0 green "${_ws_g[node]} ${icon}$(_ws_lit $_ws_node_ver)")$(_ws_notch surface0)"
}

_ws_git() {
  local out; out=$(git status --porcelain=v2 --branch --show-stash 2>/dev/null) || return
  local line head oid upstream ab stash=0
  local -i wu=0 wa=0 wm=0 wd=0 wx=0 sa=0 sm=0 sd=0
  for line in ${(f)out}; do
    case $line in
      '# branch.oid '*)      oid=${line#\# branch.oid } ;;
      '# branch.head '*)     head=${line#\# branch.head } ;;
      '# branch.upstream '*) upstream=${line#\# branch.upstream } ;;
      '# branch.ab '*)       ab=${line#\# branch.ab } ;;
      '# stash '*)           stash=${line#\# stash } ;;
      '? '*)                 (( wu++ )) ;;
      'u '*)                 (( wx++ )) ;;
      [12]' '*)
        case ${line[3]} in A) (( sa++ )) ;; D) (( sd++ )) ;; [MRCT]) (( sm++ )) ;; esac
        case ${line[4]} in A) (( wa++ )) ;; D) (( wd++ )) ;; [MRCT]) (( wm++ )) ;; esac ;;
    esac
  done

  # Upstream host icon, taken from the upstream remote (or origin)
  local remote=${upstream%%/*} url icon=${_ws_g[git]}
  url=$(git config --get remote.${remote:-origin}.url 2>/dev/null)
  case $url in
    *github.com*)                         icon=${_ws_g[github]} ;;
    *gitlab*)                             icon=${_ws_g[gitlab]} ;;
    *bitbucket*)                          icon=${_ws_g[bitbucket]} ;;
    *dev.azure.com*|*visualstudio.com*)   icon=${_ws_g[azure]} ;;
  esac

  local ref
  if [[ $head == '(detached)' ]]; then ref="${_ws_g[branch]}detached at ${_ws_g[commit]}${oid[1,7]}"
  else ref="${_ws_g[branch]}$(_ws_lit $head)"
  fi

  local bs
  if [[ -z $upstream ]]; then bs=${_ws_g[gone]}
  else
    local -i a=${${ab%% *}#+} b=${${ab##* }#-}
    if (( a == 0 && b == 0 )); then bs=${_ws_g[equal]}
    else
      (( a )) && bs+=" ${_ws_g[ahead]}$a"
      (( b )) && bs+=" ${_ws_g[behind]}$b"
      bs=${bs# }
    fi
  fi

  local -a w s
  (( wu )) && w+="?$wu"; (( wa )) && w+="+$wa"; (( wm )) && w+="~$wm"; (( wd )) && w+="-$wd"; (( wx )) && w+="x$wx"
  (( sa )) && s+="+$sa"; (( sm )) && s+="~$sm"; (( sd )) && s+="-$sd"

  local text=" ${icon}${ref} ${bs}"
  (( $#w )) && text+=" ${_ws_g[working]} ${(j: :)w}"
  (( $#w && $#s )) && text+=" |"
  (( $#s )) && text+=" ${_ws_g[staged]} ${(j: :)s}"
  (( stash > 0 )) && text+=" ${_ws_g[stash]} $stash"
  text+=" "

  print -rn -- "$(_ws_open mantle)$(_ws_pill mantle green "$text")$(_ws_close mantle)"
}

# --- prompt assembly ---

_ws_preexec() { typeset -gF _ws_start=$EPOCHREALTIME }

_ws_precmd() {
  local -i ms=0
  if (( ${+_ws_start} )); then
    ms=$(( (EPOCHREALTIME - _ws_start) * 1000 ))
    unset _ws_start
  fi

  local left
  left+="$(_ws_open crust)$(_ws_pill crust blue " ${_ws_g[os]}")$(_ws_notch crust)"
  left+="$(_ws_open crust)$(_ws_pill crust peach " ${_ws_g[heart]} $(strftime %H:%M:%S $EPOCHSECONDS) ")$(_ws_notch crust)"
  left+="$(_ws_open surface0)$(_ws_pill surface0 sky "${_ws_g[chip]} CPU: $(_ws_cpu)%% | RAM: $(_ws_ram) ${_ws_g[chip]} ")$(_ws_notch surface0)"
  left+="$(_ws_open surface1)$(_ws_pill surface1 yellow " $(_ws_duration $ms) ")$(_ws_close surface1)"

  local right="$(_ws_node)$(_ws_git)"

  # Right-align the git block on line 1; drop it if the window is too narrow
  local line1=$left
  if [[ -n $right ]]; then
    local -i pad=$(( COLUMNS - $(_ws_width "$left") - $(_ws_width "$right") ))
    (( pad >= 1 )) && line1+="${(l:pad:: :)}$right"
  fi

  local line2="%F{${_ws_c[blue]}} ${_ws_g[folder]} $(_ws_path) %f%(?.%F{${_ws_c[green]}}.%F{${_ws_c[red]}}) ${_ws_g[status]} %f"

  typeset -g _ws_prompt="${line1}"$'\n'"${line2}"
  PROMPT='${_ws_prompt}'
  RPROMPT=''

  # Tab title = current folder name
  print -n -- "\e]0;${${PWD:t}:-/}\a"
}

# Visible width of a prompt string
_ws_width() {
  setopt local_options extended_glob
  local s=${(%)1}
  s=${s//$'\e'\[[0-9;]#m/}
  print -rn -- ${(m)#s}
}

# Transient prompt: collapse the finished prompt to a single arrow
_ws_line_finish() {
  PROMPT="%F{${_ws_c[lavender]}}${_ws_g[tprompt]} %f"
  zle .reset-prompt
}

add-zsh-hook preexec _ws_preexec
add-zsh-hook precmd  _ws_precmd
add-zle-hook-widget line-finish _ws_line_finish

# The old utkbansal theme set this; the venv name would otherwise prefix the prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1
