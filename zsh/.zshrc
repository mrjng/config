# Bare Zsh profile. Oh My Zsh and Powerlevel10k are intentionally not required.
[[ -o interactive ]] || return

typeset -g _dotfiles_zsh_root=${${(%):-%N}:A:h}
typeset -g _dotfiles_autosuggestions_source=''
typeset -g _dotfiles_syntax_highlighting_source=''
typeset -g _dotfiles_fzf_key_bindings_source=''

case $OSTYPE in
  linux*)
    source "$_dotfiles_zsh_root/conf.d/linux.zsh"
    ;;
  darwin*)
    source "$_dotfiles_zsh_root/conf.d/macos.zsh"
    ;;
esac

source "$_dotfiles_zsh_root/conf.d/history.zsh"
source "$_dotfiles_zsh_root/conf.d/completion.zsh"
source "$_dotfiles_zsh_root/conf.d/interactive.zsh"
source "$_dotfiles_zsh_root/conf.d/aliases.zsh"

[[ -r $_dotfiles_fzf_key_bindings_source ]] &&
  source "$_dotfiles_fzf_key_bindings_source"

[[ -r $_dotfiles_autosuggestions_source ]] &&
  source "$_dotfiles_autosuggestions_source"

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

# Keep the fallback prompt usable before Starship is installed or deployed.
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# Syntax highlighting must be sourced after widgets, bindings, and prompt setup.
[[ -r $_dotfiles_syntax_highlighting_source ]] &&
  source "$_dotfiles_syntax_highlighting_source"

unset _dotfiles_autosuggestions_source
unset _dotfiles_syntax_highlighting_source
unset _dotfiles_fzf_key_bindings_source
unset _dotfiles_zsh_root
