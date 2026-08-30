# Prefer eza only when it is available; otherwise the standard ls remains intact.
if (( $+commands[eza] )); then
  alias ls='eza'
  alias ll='eza -lah'
  alias la='eza -a'
  alias lt='eza -aT -L1 --group-directories-first'
  alias lt2='eza -aT -L2 --group-directories-first'
  alias lt3='eza -aT -L3 --group-directories-first'
fi

if (( $+commands[nvim] )); then
  alias vi='nvim'
  alias vim='nvim'
fi

if (( $+commands[bat] )); then
  export BAT_THEME='Monokai Extended'
  alias cat='bat'
fi

if (( $+commands[kitty] )); then
  alias kssh='kitty +kitten ssh'
fi

# Search recursively with GNU grep when installed, falling back to system grep.
xgrep() {
  if (( $# != 1 )); then
    print -u2 'usage: xgrep PATTERN'
    return 2
  fi

  local grep_command=${commands[ggrep]:-${commands[grep]}}
  "$grep_command" -n -r --color=auto -- "$1" .
}
