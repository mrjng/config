# Use predictable Emacs-style line editing without claiming Fcitx5's Ctrl+Space.
bindkey -e

# Search history entries by the text already typed at the prompt.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# Interpret Kitty's Option/Alt-arrow escape sequences as word navigation.
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
setopt INTERACTIVE_COMMENTS

# Recover from mouse and focus reporting left enabled by an interrupted remote
# terminal application. A local Zellij session owns these modes itself.
autoload -Uz add-zsh-hook

reset-terminal-mode() {
  [[ -n ${ZELLIJ-} ]] && return
  printf '\033[?1000;1002;1003;1004;1005;1006;1007;1015;1016l\033[?25h'
}

add-zsh-hook -d precmd reset-terminal-mode 2>/dev/null
add-zsh-hook precmd reset-terminal-mode

# Keep a usable prompt even while Starship remains absent.
PROMPT='%F{blue}%~%f %# '
