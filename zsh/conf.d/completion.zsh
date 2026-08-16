# Use native Zsh completion. Disable the dump initially to avoid hidden cache state.
autoload -Uz compinit
compinit -D

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
