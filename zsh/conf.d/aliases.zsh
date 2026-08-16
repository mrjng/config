# Prefer eza only when it is available; otherwise the standard ls remains intact.
if (( $+commands[eza] )); then
  alias ls='eza'
  alias ll='eza -lah'
  alias la='eza -a'
  alias lt='eza -aT -L1 --group-directories-first'
  alias lt2='eza -aT -L2 --group-directories-first'
  alias lt3='eza -aT -L3 --group-directories-first'
fi

if (( $+commands[kitty] )); then
  alias kssh='kitty +kitten ssh'
fi
