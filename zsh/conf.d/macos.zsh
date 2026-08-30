# Apple Silicon Homebrew and Cargo install user commands in these directories.
# Prepend only directories that exist, without duplicating PATH entries.
for _dotfiles_macos_bin_dir in \
  /opt/homebrew/sbin \
  /opt/homebrew/bin \
  "$HOME/.cargo/bin"
do
  [[ -d $_dotfiles_macos_bin_dir ]] || continue
  case ":$PATH:" in
    *":$_dotfiles_macos_bin_dir:"*) ;;
    *) PATH="$_dotfiles_macos_bin_dir:$PATH" ;;
  esac
done
unset _dotfiles_macos_bin_dir

if (( $+commands[nvim] )); then
  export EDITOR=nvim
  export VISUAL=nvim
fi

[[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  _dotfiles_autosuggestions_source=/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  _dotfiles_syntax_highlighting_source=/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
