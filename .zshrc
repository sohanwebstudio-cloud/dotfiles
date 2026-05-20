eval "$(starship init zsh)"
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
alias ls='ls --color=auto'
echo "it's $(date +%I:%M%p)  $(uptime -p)"

# fnm
FNM_PATH="/home/sohan/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi
export PATH="$HOME/.local/bin:$PATH"

meteo() {
  curl "wttr.in/${1:-Vannes}?m"
}
export PATH="$HOME/.cargo/bin:$PATH"

# pnpm
export PNPM_HOME="/home/sohan/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# Added by LM Studio CLI tool (lms)
export PATH="$PATH:/home/sohan/.lmstudio/bin"
export PATH="/home/sohan/.lmstudio/bin:$PATH"

# Bat theme
export BAT_THEME="Monokai Extended Origin"

# pywal — restaure les couleurs et séquences terminal au démarrage
(cat ~/.cache/wal/sequences &)
xrdb -merge ~/.cache/wal/colors.Xresources 2>/dev/null

# nmtui — thème calé sur les slots pywal (0-15)
export NEWT_COLORS="
root=white,black
border=gray,black
window=white,black
shadow=black,black
title=brightcyan,black
checkbox=white,black
button=black,cyan
compactbutton=white,black
listbox=white,black
actlistbox=black,cyan
textbox=white,black
acttextbox=black,gray
label=white,black
entry=white,black
disentry=gray,black
scale=,cyan
emptyscale=,black
fullscale=,cyan
helpline=black,white
roottext=black,white
"

export EDITOR=nvim
export VISUAL=nvim

alias sxiv='sxiv -n 300'
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
