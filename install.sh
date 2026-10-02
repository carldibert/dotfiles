#!/usr/bin/env bash
# Installs these dotfiles on Linux: packages (Arch), oh-my-zsh + plugins, then symlinks the configs.
# Existing files are moved aside to <file>.bak-<date> before linking.
#
#   ./install.sh               everything
#   ./install.sh --no-packages skip pacman (non-Arch machines, servers)
#   ./install.sh --dry-run     print what would happen, change nothing
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
PACKAGES=1

for arg in "$@"; do
  case $arg in
    --dry-run)     DRY_RUN=1 ;;
    --no-packages) PACKAGES=0 ;;
    -h|--help)     sed -n '2,8p' "$0"; exit 0 ;;
    *)             echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
run() { if (( DRY_RUN )); then echo "    $*"; else "$@"; fi; }

# Symlink $1 (in this repo) to $2, backing up whatever is there now
link() {
  local src="$DOTFILES/$1" dst="$2"
  if [[ -L $dst && "$(readlink -f "$dst")" == "$src" ]]; then
    echo "    ok      $dst"
    return
  fi
  run mkdir -p "$(dirname "$dst")"
  if [[ -e $dst || -L $dst ]]; then
    echo "    backup  $dst -> $dst.bak-$STAMP"
    run mv "$dst" "$dst.bak-$STAMP"
  fi
  echo "    link    $dst -> $src"
  run ln -s "$src" "$dst"
}

clone() {
  local url="$1" dir="$2"
  if [[ -d $dir ]]; then echo "    ok      $dir"; else run git clone --depth 1 "$url" "$dir"; fi
}

if (( PACKAGES )); then
  if command -v pacman >/dev/null; then
    say "Installing packages (sudo pacman)"
    mapfile -t pkgs < <(sed 's/#.*//; /^[[:space:]]*$/d' "$DOTFILES/packages/arch.txt" | awk '{print $1}')
    run sudo pacman -S --needed --noconfirm "${pkgs[@]}"
  else
    say "Not Arch: install these yourself, then rerun with --no-packages"
    sed 's/#.*//; /^[[:space:]]*$/d' "$DOTFILES/packages/arch.txt" | sed 's/^/    /'
  fi
fi

say "oh-my-zsh"
if [[ -d $ZSH_DIR ]]; then
  echo "    ok      $ZSH_DIR"
else
  run env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

say "zsh plugins"
clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$ZSH_CUSTOM_DIR/plugins/fast-syntax-highlighting"

say "Linking configs"
link zsh/.zshrc                            "$HOME/.zshrc"
link zsh/themes/wholespace-frappe.zsh-theme "$ZSH_CUSTOM_DIR/themes/wholespace-frappe.zsh-theme"
if command -v kitty >/dev/null || [[ -d $HOME/.config/kitty ]]; then
  link kitty/kitty.conf "$HOME/.config/kitty/kitty.conf"
else
  echo "    skip    kitty.conf (kitty not installed)"
fi
if command -v wezterm >/dev/null || [[ -d $HOME/.config/wezterm ]]; then
  link wezterm/wezterm.lua "$HOME/.config/wezterm/wezterm.lua"
else
  echo "    skip    wezterm.lua (wezterm not installed)"
fi
if command -v oh-my-posh >/dev/null; then
  link oh-my-posh/wholespace-frappe.omp.json "$HOME/.config/oh-my-posh/wholespace-frappe.omp.json"
else
  echo "    skip    wholespace-frappe.omp.json (oh-my-posh not installed)"
fi

if command -v oh-my-posh >/dev/null && [[ -d $HOME/.claude ]]; then
  link claude/claude-statusline.omp.json "$HOME/.claude/claude-statusline.omp.json"
  link claude/subagent-statusline.py     "$HOME/.claude/subagent-statusline.py"
  if ! grep -q '"statusLine"' "$HOME/.claude/settings.json" 2>/dev/null; then
    say "Add the statusLine settings from claude/README.md to ~/.claude/settings.json"
  fi
else
  echo "    skip    Claude Code statusline (needs oh-my-posh and ~/.claude)"
fi

if [[ "$(basename "${SHELL:-}")" != zsh ]]; then
  say "Your login shell is ${SHELL:-unknown}. Switch with: chsh -s \"\$(command -v zsh)\""
fi

say "Done. Open a new terminal or run: exec zsh"
