# Use predictable Emacs-style line editing without claiming Fcitx5's Ctrl+Space.
bindkey -e
setopt INTERACTIVE_COMMENTS

# Keep a usable prompt even while Starship remains absent.
PROMPT='%F{blue}%~%f %# '
