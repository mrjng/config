# Fedora packages expose completions and integrations at system paths.
if [[ -d /usr/share/zsh/site-functions ]]; then
  fpath=(/usr/share/zsh/site-functions $fpath)
fi

[[ -r /usr/share/fzf/shell/key-bindings.zsh ]] &&
  _dotfiles_fzf_key_bindings_source=/usr/share/fzf/shell/key-bindings.zsh

[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  _dotfiles_autosuggestions_source=/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  _dotfiles_syntax_highlighting_source=/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
