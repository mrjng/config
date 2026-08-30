# Dotfiles

Concise terminal configuration for Fedora Asahi Linux and Apple Silicon macOS.
The shared stack uses Kitty, bare Zsh, Starship, and Zellij. Fedora uses
MesloLGS Nerd Font Mono plus Fcitx5 Hangul input; macOS uses MesloLGS NF.
Shared Zsh also performs narrow stale terminal-mode recovery. Platform files
select optional standalone Zsh integrations, while macOS keeps its personal
Kitty wallpaper in an unmanaged host-local include. Legacy configurations
remain tracked as reference.

Platform procedures are kept separate:

- [Fedora Asahi development setup](docs/fedora-asahi-development-setup.md)
- [macOS development setup](docs/macos-development-setup.md)

Repository changes do not install software, deploy files into a home directory,
create symlinks, or change a login shell automatically.
