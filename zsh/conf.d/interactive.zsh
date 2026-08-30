# Use predictable Emacs-style line editing without claiming Fcitx5's Ctrl+Space.
bindkey -e
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
