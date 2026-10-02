export ZSH="$HOME/.oh-my-zsh"

# Prompt: zsh/themes/wholespace-frappe.zsh-theme in this repo
ZSH_THEME="wholespace-frappe"

plugins=(git zsh-autosuggestions fast-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

export PATH="$HOME/.local/bin:$PATH"

# kitty's ssh kitten copies kitty's terminfo and shell integration to the remote host
[[ $TERM == xterm-kitty ]] && alias ssh='kitten ssh'
