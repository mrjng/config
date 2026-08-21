# Fedora Asahi Terminal Environment Reproduction Guide

Last updated: 2026-08-22

Run commands in order and one block at a time. Read each expected result and
stop condition before continuing. This repository does not install packages,
deploy configuration, or change the login shell automatically.

Markdown fence labels provide syntax highlighting; they do not select a shell.
Except where this guide explicitly starts a temporary Bash process, paste
operational blocks into the current Zsh. The marked Bash processes end with an
explicit `exit` and contain every variable-dependent operation they own.

## 1. Scope and resulting stack

This guide begins after Fedora Asahi Linux is installed and booted on an
`aarch64` machine with KDE Plasma on Wayland. Fedora Asahi installation and
macOS setup are outside its scope.

| Layer | Component | Responsibility |
|---|---|---|
| Terminal | Kitty | Rendering, fonts, URLs, and terminal clipboard |
| Shell | Bare Zsh | Completion, history, aliases, and integrations |
| Prompt | Starship 1.26.0 | Directory, Git, duration, status, and project context |
| Multiplexer | Zellij 0.44.3 | Panes, tabs, sessions, and layouts |
| Font | MesloLGS Nerd Font Mono 3.5.0 | Prompt and status-line glyphs |
| Input | Fcitx5 Hangul | Korean input, toggled with `Ctrl+Space` |

Fcitx5 owns `Ctrl+Space`; Kitty owns `Ctrl+Shift+C` and `Ctrl+Shift+V`;
Zellij owns panes, tabs, sessions, and layouts; KDE keeps desktop shortcuts
such as `Meta+V`. Zellij is not started automatically by `.zshrc`. Terminal
bell suppression remains inactive until physical testing selects a policy.

## 2. Prerequisites

Use a trusted network and allow at least 500 MiB of free space under `/tmp` and
the home filesystem. Artifact blocks use Bash strict mode even when Zsh is the
login shell.

Confirm the platform before installing anything:

```zsh
(
  set -euo pipefail
  [[ $(uname -m) == aarch64 ]]
  grep -Ei 'Fedora.*Asahi' /etc/os-release
  printf 'desktop=%s session=%s shell=%s\n' \
    "${XDG_CURRENT_DESKTOP-}" "${XDG_SESSION_TYPE-}" "${SHELL-}"
  df -h /tmp "$HOME"
)
```

Expected results are `aarch64`, Fedora Asahi, KDE, and Wayland. Stop if the
architecture or OS differs, either filesystem is nearly full, or the machine
identity is uncertain. The pinned binaries below are Linux `aarch64` builds.

Inspect existing commands and targets without changing them:

```zsh
command -v dnf sudo bash

for target in \
  "$HOME/.config/kitty/kitty.conf" \
  "$HOME/.config/kitty/common.conf" \
  "$HOME/.config/kitty/linux.conf" \
  "$HOME/.config/kitty/work/current-theme.conf" \
  "$HOME/.config/starship.toml" \
  "$HOME/.config/zellij/config.kdl" \
  "$HOME/.zshrc"; do
  if [[ -e $target || -L $target ]]; then
    ls -ld -- "$target"
  else
    printf 'absent: %s\n' "$target"
  fi
done
```

Do not continue past an existing target until section 6. Never overwrite an
unexpected file, directory, symlink, or dangling symlink.

## 3. Fedora packages

Inspect availability, then review the proposed transaction before confirming:

```zsh
dnf info \
  kitty zsh git ripgrep curl tar gzip xz coreutils findutils gawk fontconfig \
  zsh-autosuggestions zsh-syntax-highlighting fzf zoxide eza \
  fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-hangul fcitx5-qt
```

```zsh
sudo dnf install \
  kitty zsh git ripgrep curl tar gzip xz coreutils findutils gawk fontconfig \
  zsh-autosuggestions zsh-syntax-highlighting fzf zoxide eza \
  fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-hangul fcitx5-qt
```

Stop if DNF proposes removals, third-party replacements, or unrelated
software. Do not add an unreviewed COPR for Starship or Zellij and never pipe a
remote installer into a shell.

Verify packages and Fedora Zsh integration paths fail-closed:

```zsh
(
  set -euo pipefail
  rpm -q \
    kitty zsh git ripgrep curl tar gzip xz coreutils findutils gawk fontconfig \
    zsh-autosuggestions zsh-syntax-highlighting fzf zoxide eza \
    fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-hangul fcitx5-qt
  rpm -ql fzf | rg '/(key-bindings\.zsh|_fzf)$'
  test -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  test -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
)
```

Any missing package or path makes the block fail before later checks. Fedora's
fzf package provides `key-bindings.zsh` and an `_fzf` completion function;
native Zsh completion discovers `_fzf`.

Configure Fcitx5 as KDE's input method, open `fcitx5-configtool`, add Hangul,
and keep `Ctrl+Space` as its trigger. Log out and back in after changing the
input-method service. Do not add a competing binding to Kitty, Zsh, or Zellij.

## 4. Pinned user-local artifacts and Meslo font

These values are the trust boundary. Change a version, URL, archive checksum,
binary checksum, and validation expectation together.

| Artifact | Official URL | Pinned SHA-256 |
|---|---|---|
| Starship 1.26.0 archive | <https://github.com/starship/starship/releases/download/v1.26.0/starship-aarch64-unknown-linux-musl.tar.gz> | `dc30189378d2f2e287384e8a692d3f95ad1df64cf0e8c36aa9201516028aed6b` |
| Extracted Starship binary | Member `starship` of the archive above | `c5a87221f11a7cc36fa2fa4c31dea542457bf08ec825d5c06181008a0666e952` |
| Zellij 0.44.3 archive | <https://github.com/zellij-org/zellij/releases/download/v0.44.3/zellij-aarch64-unknown-linux-musl.tar.gz> | `15e6534d42644d66973d136c590c49739dcfd6a1a2a0d3d917973f16c81b45fb` |
| Extracted Zellij binary | Member `zellij` of the archive above | `439ed44da5df3cd70e578dc4aef5a67dc7b81eabdddec27969d84a6be380b2f0` |
| Meslo 3.5.0 archive | <https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/Meslo.tar.xz> | `24cfe8148aeb600891f1d81180e77ecc967a814cde75dc7e63ec5bc2b0ab3eef` |

Official supporting files:

- Zellij binary checksum: <https://github.com/zellij-org/zellij/releases/download/v0.44.3/zellij-aarch64-unknown-linux-musl.sha256sum>
- Nerd Fonts manifest: <https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/SHA-256.txt>

The Starship binary checksum was derived from the archive's sole member only
after the archive checksum succeeded. An installed executable is not a trust
source.

### Private temporary storage

From the current Zsh, start one dedicated Bash process for the complete artifact
workflow:

```zsh
bash
```

Run every `bash` fence from here through the cleanup fence in that Bash process.
Do not start another shell between them. Prepare its private workspace:

```bash
artifact_tmp=$(umask 077; mktemp -d -p /tmp \
  fedora-asahi-artifacts.XXXXXXXX) || exit 1
if ! mkdir "$artifact_tmp/starship" "$artifact_tmp/zellij" \
    "$artifact_tmp/meslo"; then
  rm -rf -- "$artifact_tmp"
  exit 1
fi
printf 'artifact workspace: %s\n' "$artifact_tmp" || exit 1
```

Stop if either command fails. Do not substitute a predictable path.

### Existing-install verification

If a destination exists, do not run its installation block. Verify the exact
regular non-symlink file before executing it:

```bash
(
  set -euo pipefail
  starship_bin="$HOME/.local/bin/starship"
  [[ -f $starship_bin && ! -L $starship_bin && -x $starship_bin ]]
  printf '%s  %s\n' \
    'c5a87221f11a7cc36fa2fa4c31dea542457bf08ec825d5c06181008a0666e952' \
    "$starship_bin" | sha256sum --check --strict
  starship_version=$("$starship_bin" --version | sed -n '1p')
  [[ $starship_version == 'starship 1.26.0' ]]
  printf '%s\n' "$starship_version"
)
```

```bash
(
  set -euo pipefail
  zellij_bin="$HOME/.local/bin/zellij"
  [[ -f $zellij_bin && ! -L $zellij_bin && -x $zellij_bin ]]
  printf '%s  %s\n' \
    '439ed44da5df3cd70e578dc4aef5a67dc7b81eabdddec27969d84a6be380b2f0' \
    "$zellij_bin" | sha256sum --check --strict
  zellij_version=$("$zellij_bin" --version)
  [[ $zellij_version == 'zellij 0.44.3' ]]
  printf '%s\n' "$zellij_version"
)
```

Expected results are checksum `OK` messages and pinned versions. Stop on a
missing file, symlink, type mismatch, checksum mismatch, or version mismatch.

### Install Starship 1.26.0

Use this only when `~/.local/bin/starship` is absent:

```bash
(
  set -euo pipefail
  : "${artifact_tmp:?Prepare private temporary storage first}"
  archive="$artifact_tmp/starship-aarch64-unknown-linux-musl.tar.gz"
  extracted="$artifact_tmp/starship/starship"
  destination="$HOME/.local/bin/starship"

  [[ ! -e $destination && ! -L $destination ]]
  curl --fail --location --proto '=https' --tlsv1.2 \
    --output "$archive" \
    'https://github.com/starship/starship/releases/download/v1.26.0/starship-aarch64-unknown-linux-musl.tar.gz'
  printf '%s  %s\n' \
    'dc30189378d2f2e287384e8a692d3f95ad1df64cf0e8c36aa9201516028aed6b' \
    "$archive" | sha256sum --check --strict

  [[ $(tar -tzf "$archive") == starship ]]
  tar -xzf "$archive" -C "$artifact_tmp/starship" -- starship
  [[ -f $extracted && ! -L $extracted && -x $extracted ]]
  printf '%s  %s\n' \
    'c5a87221f11a7cc36fa2fa4c31dea542457bf08ec825d5c06181008a0666e952' \
    "$extracted" | sha256sum --check --strict
  [[ $("$extracted" --version | sed -n '1p') == 'starship 1.26.0' ]]

  mkdir -p "$HOME/.local/bin"
  [[ ! -e $destination && ! -L $destination ]]
  install -m 0755 "$extracted" "$destination"
  [[ -f $destination && ! -L $destination && -x $destination ]]
  printf '%s  %s\n' \
    'c5a87221f11a7cc36fa2fa4c31dea542457bf08ec825d5c06181008a0666e952' \
    "$destination" | sha256sum --check --strict
)
```

The archive must report `OK` before `tar` inspects or extracts it. The binary
must report `OK` before either copy is executed.

### Install Zellij 0.44.3

Use this only when `~/.local/bin/zellij` is absent:

```bash
(
  set -euo pipefail
  : "${artifact_tmp:?Prepare private temporary storage first}"
  archive="$artifact_tmp/zellij-aarch64-unknown-linux-musl.tar.gz"
  extracted="$artifact_tmp/zellij/zellij"
  destination="$HOME/.local/bin/zellij"

  [[ ! -e $destination && ! -L $destination ]]
  curl --fail --location --proto '=https' --tlsv1.2 \
    --output "$archive" \
    'https://github.com/zellij-org/zellij/releases/download/v0.44.3/zellij-aarch64-unknown-linux-musl.tar.gz'
  printf '%s  %s\n' \
    '15e6534d42644d66973d136c590c49739dcfd6a1a2a0d3d917973f16c81b45fb' \
    "$archive" | sha256sum --check --strict

  [[ $(tar -tzf "$archive") == zellij ]]
  tar -xzf "$archive" -C "$artifact_tmp/zellij" -- zellij
  [[ -f $extracted && ! -L $extracted && -x $extracted ]]
  printf '%s  %s\n' \
    '439ed44da5df3cd70e578dc4aef5a67dc7b81eabdddec27969d84a6be380b2f0' \
    "$extracted" | sha256sum --check --strict
  [[ $("$extracted" --version) == 'zellij 0.44.3' ]]

  mkdir -p "$HOME/.local/bin"
  [[ ! -e $destination && ! -L $destination ]]
  install -m 0755 "$extracted" "$destination"
  [[ -f $destination && ! -L $destination && -x $destination ]]
  printf '%s  %s\n' \
    '439ed44da5df3cd70e578dc4aef5a67dc7b81eabdddec27969d84a6be380b2f0' \
    "$destination" | sha256sum --check --strict
)
```

Do not trust a self-reported version until binary identity is verified.

### Install MesloLGS Nerd Font Mono 3.5.0

Install only these faces:

```text
MesloLGSNerdFontMono-Regular.ttf
MesloLGSNerdFontMono-Bold.ttf
MesloLGSNerdFontMono-Italic.ttf
MesloLGSNerdFontMono-BoldItalic.ttf
```

This block removes only its newly published directory if validation fails:

```bash
(
  set -euo pipefail
  : "${artifact_tmp:?Prepare private temporary storage first}"
  archive="$artifact_tmp/Meslo.tar.xz"
  extract_dir="$artifact_tmp/meslo"
  font_parent="$HOME/.local/share/fonts"
  font_dir="$font_parent/MesloLGSNerdFontMono"
  stage_dir=''
  published=0

  cleanup_meslo() {
    operation_status=$?
    trap - EXIT
    if (( operation_status != 0 )); then
      if (( published == 1 )); then
        [[ $font_dir == "$HOME/.local/share/fonts/MesloLGSNerdFontMono" ]]
        [[ -d $font_dir && ! -L $font_dir ]]
        rm -- \
          "$font_dir/MesloLGSNerdFontMono-Regular.ttf" \
          "$font_dir/MesloLGSNerdFontMono-Bold.ttf" \
          "$font_dir/MesloLGSNerdFontMono-Italic.ttf" \
          "$font_dir/MesloLGSNerdFontMono-BoldItalic.ttf"
        rmdir -- "$font_dir"
      elif [[ -n $stage_dir && -d $stage_dir && ! -L $stage_dir ]]; then
        rm -rf -- "$stage_dir"
      fi
    fi
    exit "$operation_status"
  }
  trap cleanup_meslo EXIT

  [[ ! -e $font_dir && ! -L $font_dir ]]
  curl --fail --location --proto '=https' --tlsv1.2 \
    --output "$archive" \
    'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.0/Meslo.tar.xz'
  printf '%s  %s\n' \
    '24cfe8148aeb600891f1d81180e77ecc967a814cde75dc7e63ec5bc2b0ab3eef' \
    "$archive" | sha256sum --check --strict

  archive_members=$(tar -tJf "$archive")
  for font_file in \
    MesloLGSNerdFontMono-Regular.ttf \
    MesloLGSNerdFontMono-Bold.ttf \
    MesloLGSNerdFontMono-Italic.ttf \
    MesloLGSNerdFontMono-BoldItalic.ttf; do
    [[ $(printf '%s\n' "$archive_members" | \
      awk -v name="$font_file" \
      '$0 == name { n++ } END { print n + 0 }') == 1 ]]
  done

  tar -xJf "$archive" -C "$extract_dir" -- \
    MesloLGSNerdFontMono-Regular.ttf \
    MesloLGSNerdFontMono-Bold.ttf \
    MesloLGSNerdFontMono-Italic.ttf \
    MesloLGSNerdFontMono-BoldItalic.ttf

  mkdir -p "$font_parent"
  stage_dir=$(mktemp -d "$font_parent/.MesloLGSNerdFontMono.XXXXXXXX")
  for font_file in \
    MesloLGSNerdFontMono-Regular.ttf \
    MesloLGSNerdFontMono-Bold.ttf \
    MesloLGSNerdFontMono-Italic.ttf \
    MesloLGSNerdFontMono-BoldItalic.ttf; do
    [[ -f $extract_dir/$font_file && ! -L $extract_dir/$font_file ]]
    install -m 0644 "$extract_dir/$font_file" "$stage_dir/$font_file"
  done

  [[ ! -e $font_dir && ! -L $font_dir ]]
  mv -- "$stage_dir" "$font_dir"
  published=1
  stage_dir=''
  fc-cache -f "$font_dir"
  for font_style in Regular Bold Italic 'Bold Italic'; do
    [[ $(fc-match -f '%{family[0]}' \
      "MesloLGS Nerd Font Mono:style=$font_style") == \
      'MesloLGS Nerd Font Mono' ]]
    [[ $(fc-match -f '%{style[0]}' \
      "MesloLGS Nerd Font Mono:style=$font_style") == "$font_style" ]]
  done
  trap - EXIT
)
```

Expected results are archive `OK`, four unique selected members, and four
matching fontconfig styles. Stop on any mismatch. If the final directory
exists, verify or update it instead of running this first-install block.

Remove only the recorded temporary workspace after all artifacts succeed, then
terminate the dedicated Bash process and return to Zsh:

```bash
if (
  set -euo pipefail
  : "${artifact_tmp:?No artifact workspace is recorded}"
  [[ -d $artifact_tmp && ! -L $artifact_tmp ]]
  case $artifact_tmp in
    /tmp/fedora-asahi-artifacts.*) ;;
    *) printf 'STOP: unexpected temporary path: %s\n' "$artifact_tmp" >&2
       exit 1 ;;
  esac
  rm -rf -- "$artifact_tmp"
); then
  unset artifact_tmp
  exit
else
  printf 'STOP: artifact workspace cleanup failed\n' >&2
  exit 1
fi
```

## 5. Dotfiles repository

Clone into the path used below:

```zsh
mkdir -p "$HOME/src"
git clone https://github.com/mrjng/config.git "$HOME/src/config"
cd "$HOME/src/config"
git status --short --branch
```

If `$HOME/src/config` exists, do not clone over it. Inspect its remote, branch,
and status; use section 10 only after unexplained changes are resolved.

Active Fedora files:

```text
kitty/kitty.conf
kitty/common.conf
kitty/linux.conf
kitty/work/current-theme.conf
zsh/.zshrc
zsh/conf.d/*.zsh
starship/starship.toml
zellij/config.kdl
```

`zsh/.zshrc` adds `~/.local/bin` before integrations and adds `~/bin` only
when it exists. It preserves PATH entries, avoids duplicates, and never assigns
to Zsh's special lowercase `path`. Zellij resolves `default_shell "zsh"`
through PATH and does not auto-start from Zsh.

## 6. Existing-target inspection and preservation

Inspect every target again after cloning:

```zsh
for target in \
  "$HOME/.config/kitty/kitty.conf" \
  "$HOME/.config/kitty/common.conf" \
  "$HOME/.config/kitty/linux.conf" \
  "$HOME/.config/kitty/work/current-theme.conf" \
  "$HOME/.config/starship.toml" \
  "$HOME/.config/zellij/config.kdl" \
  "$HOME/.zshrc"; do
  if [[ -e $target || -L $target ]]; then
    ls -ld -- "$target"
  else
    printf 'absent: %s\n' "$target"
  fi
done
```

Kitty, Starship, and Zsh require absent targets. For configuration worth
keeping, create one private backup directory and move each reviewed target into
it individually:

```zsh
(
  set -euo pipefail
  if [[ -e $HOME/.config || -L $HOME/.config ]]; then
    [[ -d $HOME/.config && ! -L $HOME/.config ]]
  else
    mkdir -- "$HOME/.config"
  fi
  backup_root=$(umask 077; mktemp -d \
    "$HOME/.config/dotfiles-backup.XXXXXXXX")
  printf 'record this backup directory: %s\n' "$backup_root"
)
```

Example for a reviewed regular `.zshrc`:

```zsh
backup_root="$HOME/.config/dotfiles-backup.RECORDED_SUFFIX"
[[ -d $backup_root && ! -L $backup_root ]] &&
  [[ -f $HOME/.zshrc && ! -L $HOME/.zshrc ]] &&
  [[ ! -e $backup_root/zshrc && ! -L $backup_root/zshrc ]] &&
  mv -- "$HOME/.zshrc" "$backup_root/zshrc"
```

Use a distinct name for each target. Do not run a broad recursive move or move
an existing directory merely to make deployment pass. Record the backup path
for section 11.

Handle `~/.config/zellij/config.kdl` separately:

- If absent, use clean Zellij deployment.
- If it is a reviewed regular non-symlink file, use existing-file preservation.
- For a directory, symlink, dangling symlink, or unexpected type, stop and
  resolve it manually. Unknown configuration is user data, not disposable state.

## 7. Deployment

### Kitty, Starship, and Zsh

Kitty resolves relative includes beside the deployed entry point. Deploy the
complete layout:

```text
~/.config/kitty/kitty.conf              -> ~/src/config/kitty/kitty.conf
~/.config/kitty/common.conf             -> ~/src/config/kitty/common.conf
~/.config/kitty/linux.conf              -> ~/src/config/kitty/linux.conf
~/.config/kitty/work/current-theme.conf -> ~/src/config/kitty/work/current-theme.conf
```

Create links only after every destination is absent:

```zsh
(
  set -euo pipefail
  repo_dir="$HOME/src/config"
  for source_file in \
    "$repo_dir/kitty/kitty.conf" \
    "$repo_dir/kitty/common.conf" \
    "$repo_dir/kitty/linux.conf" \
    "$repo_dir/kitty/work/current-theme.conf" \
    "$repo_dir/starship/starship.toml" \
    "$repo_dir/zsh/.zshrc"; do
    [[ -f $source_file && ! -L $source_file ]]
  done
  for destination in \
    "$HOME/.config/kitty/kitty.conf" \
    "$HOME/.config/kitty/common.conf" \
    "$HOME/.config/kitty/linux.conf" \
    "$HOME/.config/kitty/work/current-theme.conf" \
    "$HOME/.config/starship.toml" \
    "$HOME/.zshrc"; do
    [[ ! -e $destination && ! -L $destination ]]
  done

  if [[ -e $HOME/.config || -L $HOME/.config ]]; then
    [[ -d $HOME/.config && ! -L $HOME/.config ]]
  else
    mkdir -- "$HOME/.config"
  fi
  if [[ -e $HOME/.config/kitty || -L $HOME/.config/kitty ]]; then
    [[ -d $HOME/.config/kitty && ! -L $HOME/.config/kitty ]]
  else
    mkdir -- "$HOME/.config/kitty"
  fi
  if [[ -e $HOME/.config/kitty/work || -L $HOME/.config/kitty/work ]]; then
    [[ -d $HOME/.config/kitty/work && ! -L $HOME/.config/kitty/work ]]
  else
    mkdir -- "$HOME/.config/kitty/work"
  fi
  ln -s "$repo_dir/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  ln -s "$repo_dir/kitty/common.conf" "$HOME/.config/kitty/common.conf"
  ln -s "$repo_dir/kitty/linux.conf" "$HOME/.config/kitty/linux.conf"
  ln -s "$repo_dir/kitty/work/current-theme.conf" \
    "$HOME/.config/kitty/work/current-theme.conf"
  ln -s "$repo_dir/starship/starship.toml" "$HOME/.config/starship.toml"
  ln -s "$repo_dir/zsh/.zshrc" "$HOME/.zshrc"
)
```

If this stops after creating some links, inspect them and use exact-link
rollback in section 11 before retrying.

### Zellij clean target

Use only when `~/.config/zellij/config.kdl` is absent:

```zsh
(
  set -euo pipefail
  source_file="$HOME/src/config/zellij/config.kdl"
  config_root="$HOME/.config"
  config_dir="$config_root/zellij"
  destination="$config_dir/config.kdl"
  zellij_bin="$HOME/.local/bin/zellij"
  [[ -f $source_file && ! -L $source_file ]]
  [[ ! -e $destination && ! -L $destination ]]
  [[ -f $zellij_bin && ! -L $zellij_bin && -x $zellij_bin ]]
  printf '%s  %s\n' \
    '439ed44da5df3cd70e578dc4aef5a67dc7b81eabdddec27969d84a6be380b2f0' \
    "$zellij_bin" | sha256sum --check --strict
  ZELLIJ_CONFIG_FILE="$source_file" "$zellij_bin" setup --check

  if [[ -e $config_root || -L $config_root ]]; then
    [[ -d $config_root && ! -L $config_root ]]
  else
    mkdir -- "$config_root"
  fi
  if [[ -e $config_dir || -L $config_dir ]]; then
    [[ -d $config_dir && ! -L $config_dir ]]
  else
    mkdir -- "$config_dir"
  fi
  [[ ! -e $destination && ! -L $destination ]]
  ln -s "$source_file" "$destination"
  [[ $(readlink -- "$destination") == "$source_file" ]]
)
```

Expected result: Zellij reports a well-defined configuration and the target is
the exact repository symlink. This path creates no backup.

### Zellij existing regular file

Use only after reviewing an existing regular non-symlink config. This records
its checksum, preserves it in a unique directory, and restores it if deployment
validation fails:

```zsh
(
  set -euo pipefail
  source_file="$HOME/src/config/zellij/config.kdl"
  config_dir="$HOME/.config/zellij"
  destination="$config_dir/config.kdl"
  zellij_bin="$HOME/.local/bin/zellij"
  backup_dir=''
  backup_file=''
  original_moved=0

  restore_existing_zellij() {
    operation_status=$?
    trap - EXIT
    if (( operation_status != 0 && original_moved == 1 )); then
      if [[ -L $destination ]] && \
          [[ $(readlink -- "$destination") == "$source_file" ]]; then
        unlink "$destination"
      fi
      if [[ ! -e $destination && ! -L $destination && \
          -f $backup_file && ! -L $backup_file ]]; then
        mv -- "$backup_file" "$destination"
        rmdir -- "$backup_dir"
      else
        printf 'STOP: preserved config remains at %s\n' "$backup_file" >&2
      fi
    fi
    exit "$operation_status"
  }
  trap restore_existing_zellij EXIT

  [[ -d $config_dir && ! -L $config_dir ]]
  [[ -f $destination && ! -L $destination ]]
  [[ -f $source_file && ! -L $source_file ]]
  [[ -f $zellij_bin && ! -L $zellij_bin && -x $zellij_bin ]]
  printf '%s  %s\n' \
    '439ed44da5df3cd70e578dc4aef5a67dc7b81eabdddec27969d84a6be380b2f0' \
    "$zellij_bin" | sha256sum --check --strict

  original_sha256=$(sha256sum -- "$destination" | awk '{print $1}')
  backup_dir=$(umask 077; mktemp -d "$config_dir/repository-backup.XXXXXXXX")
  backup_file="$backup_dir/config.kdl"
  mv -- "$destination" "$backup_file"
  original_moved=1
  [[ $(sha256sum -- "$backup_file" | awk '{print $1}') == \
    "$original_sha256" ]]

  ln -s "$source_file" "$destination"
  [[ $(readlink -- "$destination") == "$source_file" ]]
  ZELLIJ_CONFIG_FILE="$destination" "$zellij_bin" setup --check
  printf 'preserved Zellij config: %s\nsha256: %s\n' \
    "$backup_file" "$original_sha256"
  trap - EXIT
)
```

Record the printed path. Never recursively remove a Zellij config or backup.
Open a new Kitty window and Zsh after deployment. Do not change the login shell
yet.

## 8. Automated and physical validation

### Repository and deployed configuration

Run from the repository root:

```zsh
(
  set -euo pipefail
  cd "$HOME/src/config"
  repo_dir="$PWD"
  starship_bin="$HOME/.local/bin/starship"
  zellij_bin="$HOME/.local/bin/zellij"

  [[ -f $starship_bin && ! -L $starship_bin && -x $starship_bin ]]
  printf '%s  %s\n' \
    'c5a87221f11a7cc36fa2fa4c31dea542457bf08ec825d5c06181008a0666e952' \
    "$starship_bin" | sha256sum --check --strict
  [[ -f $zellij_bin && ! -L $zellij_bin && -x $zellij_bin ]]
  printf '%s  %s\n' \
    '439ed44da5df3cd70e578dc4aef5a67dc7b81eabdddec27969d84a6be380b2f0' \
    "$zellij_bin" | sha256sum --check --strict

  [[ $(readlink "$HOME/.config/kitty/kitty.conf") == \
    "$repo_dir/kitty/kitty.conf" ]]
  [[ $(readlink "$HOME/.config/kitty/common.conf") == \
    "$repo_dir/kitty/common.conf" ]]
  [[ $(readlink "$HOME/.config/kitty/linux.conf") == \
    "$repo_dir/kitty/linux.conf" ]]
  [[ $(readlink "$HOME/.config/kitty/work/current-theme.conf") == \
    "$repo_dir/kitty/work/current-theme.conf" ]]
  [[ $(readlink "$HOME/.config/starship.toml") == \
    "$repo_dir/starship/starship.toml" ]]
  [[ $(readlink "$HOME/.zshrc") == "$repo_dir/zsh/.zshrc" ]]
  [[ $(readlink "$HOME/.config/zellij/config.kdl") == \
    "$repo_dir/zellij/config.kdl" ]]

  STARSHIP_CONFIG="$HOME/.config/starship.toml" \
    "$starship_bin" print-config >/dev/null
  ZELLIJ_CONFIG_FILE="$HOME/.config/zellij/config.kdl" \
    "$zellij_bin" setup --check

  zsh_file_list=$(mktemp -p /tmp zsh-validation.XXXXXXXX)
  trap 'rm -f -- "$zsh_file_list"' EXIT
  find zsh -type f -print0 | sort -z > "$zsh_file_list"
  [[ -s $zsh_file_list ]]
  while IFS= read -r -d '' zsh_file; do
    zsh -n "$zsh_file"
  done < "$zsh_file_list"
  rm -f -- "$zsh_file_list"
  trap - EXIT

  KITTY_CONFIG_DIRECTORY="$HOME/.config/kitty" kitty +runpy '
import os
from kitty.config import load_config
config_path = os.path.join(os.environ["KITTY_CONFIG_DIRECTORY"], "kitty.conf")
bad_lines = []
opts = load_config(config_path, accumulate_bad_lines=bad_lines)
print(f"bad_lines={len(bad_lines)}")
print(f"font_family={opts.font_family}")
print(f"linux_display_server={opts.linux_display_server}")
if bad_lines:
    raise SystemExit(1)
if str(opts.font_family) != "MesloLGS Nerd Font Mono":
    raise SystemExit(1)
if str(opts.linux_display_server) != "wayland":
    raise SystemExit(1)
'

  for font_style in Regular Bold Italic 'Bold Italic'; do
    [[ $(fc-match -f '%{family[0]}' \
      "MesloLGS Nerd Font Mono:style=$font_style") == \
      'MesloLGS Nerd Font Mono' ]]
    [[ $(fc-match -f '%{style[0]}' \
      "MesloLGS Nerd Font Mono:style=$font_style") == "$font_style" ]]
  done
)
```

Expected results are two checksum `OK` messages, successful Starship and
Zellij parsing, no Zsh syntax failure, Kitty `bad_lines=0`, Wayland, Meslo, and
four matching font styles. Parser success is not physical proof.

### Fresh-login PATH and command lookup

Do not inherit another shell's PATH. Use a private regular history file and
start interactive Zsh with exactly the minimal PATH. From the current Zsh,
start a temporary Bash process:

```zsh
bash
```

Paste this complete block into Bash. It waits while the nested Zsh is
interactive, then removes its exact history file and terminates Bash:

```bash
(
  zsh_test_history=$(umask 077; mktemp -p /tmp \
    zsh-login-history.XXXXXXXX) || exit 1

  if env -i \
      HOME="$HOME" USER="$USER" LOGNAME="$LOGNAME" \
      SHELL=/usr/bin/zsh TERM="${TERM:-xterm-256color}" \
      PATH=/usr/local/bin:/usr/bin:/bin \
      HISTFILE="$zsh_test_history" \
      ZDOTDIR="$HOME/src/config/zsh" \
      /usr/bin/zsh -d; then
    zsh_login_test_status=0
  else
    zsh_login_test_status=$?
  fi

  case $zsh_test_history in
    /tmp/zsh-login-history.*) ;;
    *) exit 1 ;;
  esac
  [[ -f $zsh_test_history && ! -L $zsh_test_history ]] || exit 1
  rm -- "$zsh_test_history" || exit 1
  if (( zsh_login_test_status != 0 )); then
    printf 'STOP: fresh-login Zsh test failed with status %d\n' \
      "$zsh_login_test_status" >&2
  fi
  exit "$zsh_login_test_status"
)
zsh_login_test_status=$?
exit "$zsh_login_test_status"
```

At the new prompt:

```zsh
print -r -- "$PATH"
print -l -- ${(s.:.)PATH}
command -v starship zellij git awk sed

[[ $(print -l -- ${(s.:.)PATH} | \
  awk -v expected="$HOME/.local/bin" \
  '$0 == expected { n++ } END { print n + 0 }') == 1 ]]
if [[ -d $HOME/bin ]]; then
  [[ $(print -l -- ${(s.:.)PATH} | \
    awk -v expected="$HOME/bin" \
    '$0 == expected { n++ } END { print n + 0 }') == 1 ]]
fi
[[ $(command -v starship) == "$HOME/.local/bin/starship" ]]
[[ $(command -v zellij) == "$HOME/.local/bin/zellij" ]]
for command_name in git awk sed; do
  (( $+commands[$command_name] ))
done
exit
```

Expected result: `~/.local/bin` appears exactly once, `~/bin` appears exactly
once when present, Starship and Zellij resolve from `~/.local/bin`, and the
three system PATH entries remain. Never assign lowercase `path` and never use
`/dev/null` as an interactive HISTFILE. Exiting the nested Zsh triggers exact
cleanup and returns through the temporary Bash to the original Zsh.

### Physical checks

In a new Kitty window, verify:

- Regular, bold, italic, and bold-italic text use the intended Meslo faces.
- Starship and Zellij glyphs are aligned and not clipped.
- `Ctrl+Space` switches Hangul in plain Zsh and a Zellij pane.
- `Ctrl+Shift+C/V` copy and paste outside and inside Zellij; use disposable text.
- A visible URL is detected and opens with the expected desktop handler.
- Kitty font-size controls, padding, theme, and Wayland title bar work.
- Zellij can create and close panes and tabs, detach, list sessions, reattach,
  and exit without leaving an unwanted session.
- KDE `Meta+V`, Overview, screenshots, and virtual desktops still work.

Do not enable bell suppression until an audible and visual test selects a policy.

## 9. Optional login-shell change

This is optional and comes only after automated and physical validation. Skip
it when the account shell is already the intended Zsh.

```zsh
(
  set -euo pipefail
  account_name=$(id -un)
  previous_shell=$(getent passwd "$account_name" | awk -F: '{print $7}')
  [[ -n $previous_shell ]]
  zsh_path=$(command -v zsh)
  [[ $zsh_path == /usr/bin/zsh ]]
  grep -Fx -- "$zsh_path" /etc/shells
  printf 'record previous login shell: %s\n' "$previous_shell"
  printf 'requested login shell: %s\n' "$zsh_path"
  chsh -s "$zsh_path"
)
```

Log out completely and back in. Confirm `SHELL=/usr/bin/zsh`, rerun the
fresh-login PATH check, and open Kitty and Zellij. If anything fails, restore
the previously recorded shell using section 11. Never automate `chsh`.

## 10. Updating

Update one layer at a time and validate it before starting another.

### Fedora packages

```zsh
dnf check-update
sudo dnf upgrade --refresh
```

Review the transaction. Keep DNF history and do not combine package upgrades
with artifact replacement, dotfile deployment, or a login-shell change.

### Repository

Deployed symlinks expose repository changes immediately. Require a clean
worktree and review incoming changes before updating:

```zsh
(
  set -euo pipefail
  cd "$HOME/src/config"
  [[ -z $(git status --short) ]]
  git fetch origin
  git log --oneline --decorate HEAD..@{upstream}
  git diff --stat HEAD..@{upstream}
)
```

If acceptable:

```zsh
(
  set -euo pipefail
  cd "$HOME/src/config"
  [[ -z $(git status --short) ]]
  git merge --ff-only '@{upstream}'
)
```

Stop on local changes, an unexpected branch, a non-fast-forward update, or an
unreviewed configuration change. Repeat section 8 afterward.

### Starship, Zellij, or Meslo

For each release:

1. Read release notes and select the exact Linux `aarch64` asset.
2. Record the new version, official URL, archive checksum, extracted-binary
   checksum, and validation expectation before installation.
3. Download into a new private `mktemp -d` directory.
4. Verify the archive before listing or extracting members.
5. Verify an extracted regular non-symlink binary before execution.
6. Copy the currently verified binary or font directory to a unique backup
   outside Git; record its path and checksum.
7. Install the reviewed files and repeat section 8.
8. Restore the backup immediately if validation fails.

Never derive trust solely from an installed executable, reuse checksums across
versions, or replace a destination whose identity is unknown.

## 11. Rollback

### Configuration links

Verify every target is still the exact repository symlink before unlinking:

```zsh
(
  set -euo pipefail
  repo_dir="$HOME/src/config"
  [[ $(readlink "$HOME/.config/kitty/kitty.conf") == \
    "$repo_dir/kitty/kitty.conf" ]]
  [[ $(readlink "$HOME/.config/kitty/common.conf") == \
    "$repo_dir/kitty/common.conf" ]]
  [[ $(readlink "$HOME/.config/kitty/linux.conf") == \
    "$repo_dir/kitty/linux.conf" ]]
  [[ $(readlink "$HOME/.config/kitty/work/current-theme.conf") == \
    "$repo_dir/kitty/work/current-theme.conf" ]]
  [[ $(readlink "$HOME/.config/starship.toml") == \
    "$repo_dir/starship/starship.toml" ]]
  [[ $(readlink "$HOME/.zshrc") == "$repo_dir/zsh/.zshrc" ]]

  unlink "$HOME/.zshrc"
  unlink "$HOME/.config/starship.toml"
  unlink "$HOME/.config/kitty/work/current-theme.conf"
  unlink "$HOME/.config/kitty/linux.conf"
  unlink "$HOME/.config/kitty/common.conf"
  unlink "$HOME/.config/kitty/kitty.conf"
)
```

If only some links were deployed, verify and unlink those individually. Restore
reviewed files from the recorded backup directory only into absent targets. For
example:

```zsh
backup_root="$HOME/.config/dotfiles-backup.RECORDED_SUFFIX"
[[ -d $backup_root && ! -L $backup_root ]] &&
  [[ -f $backup_root/zshrc && ! -L $backup_root/zshrc ]] &&
  [[ ! -e $HOME/.zshrc && ! -L $HOME/.zshrc ]] &&
  mv -- "$backup_root/zshrc" "$HOME/.zshrc"
```

### Zellij clean deployment

Use only when no migration backup exists:

```zsh
(
  set -euo pipefail
  config_dir="$HOME/.config/zellij"
  destination="$config_dir/config.kdl"
  source_file="$HOME/src/config/zellij/config.kdl"
  migration_backups=$(find "$config_dir" -mindepth 1 -maxdepth 1 \
    -name 'repository-backup.*' -print)
  [[ -z $migration_backups ]]
  [[ -L $destination ]]
  [[ $(readlink -- "$destination") == "$source_file" ]]
  unlink "$destination"
)
```

Any matching backup makes this refuse to unlink. Use migrated rollback instead.

### Zellij migrated deployment

Set the placeholder in this self-contained block to the exact directory printed
during migration. Restore only the preserved regular file into an absent
destination:

```zsh
(
  set -euo pipefail
  config_dir="$HOME/.config/zellij"
  destination="$config_dir/config.kdl"
  source_file="$HOME/src/config/zellij/config.kdl"
  zellij_backup_dir="$config_dir/repository-backup.RECORDED_SUFFIX"
  backup_file="$zellij_backup_dir/config.kdl"
  [[ $(dirname -- "$zellij_backup_dir") == "$config_dir" ]]
  [[ $(basename -- "$zellij_backup_dir") == repository-backup.* ]]
  [[ -d $zellij_backup_dir && ! -L $zellij_backup_dir ]]
  [[ -f $backup_file && ! -L $backup_file ]]
  [[ -L $destination ]]
  [[ $(readlink -- "$destination") == "$source_file" ]]
  unlink "$destination"
  [[ ! -e $destination && ! -L $destination ]]
  mv -- "$backup_file" "$destination"
  [[ -f $destination && ! -L $destination ]]
  rmdir -- "$zellij_backup_dir"
)
```

Never recursively remove the Zellij config or backup. Stop if any path, type,
or symlink target differs.

### User-local artifacts

For a failed update, restore the recorded verified backup and repeat section 8.
For complete binary removal, first ensure no Zellij session or shell depends on
them, then verify identity before removal:

```zsh
(
  set -euo pipefail
  starship_bin="$HOME/.local/bin/starship"
  zellij_bin="$HOME/.local/bin/zellij"
  [[ -f $starship_bin && ! -L $starship_bin ]]
  printf '%s  %s\n' \
    'c5a87221f11a7cc36fa2fa4c31dea542457bf08ec825d5c06181008a0666e952' \
    "$starship_bin" | sha256sum --check --strict
  [[ -f $zellij_bin && ! -L $zellij_bin ]]
  printf '%s  %s\n' \
    '439ed44da5df3cd70e578dc4aef5a67dc7b81eabdddec27969d84a6be380b2f0' \
    "$zellij_bin" | sha256sum --check --strict
  rm -- "$starship_bin" "$zellij_bin"
)
```

Remove Meslo only when its dedicated directory contains exactly the four files
listed in section 4, all regular non-symlink files, and no unrelated font:

```zsh
(
  set -euo pipefail
  font_dir="$HOME/.local/share/fonts/MesloLGSNerdFontMono"
  expected=$(printf '%s\n' \
    MesloLGSNerdFontMono-Regular.ttf \
    MesloLGSNerdFontMono-Bold.ttf \
    MesloLGSNerdFontMono-Italic.ttf \
    MesloLGSNerdFontMono-BoldItalic.ttf | sort)
  installed=$(find "$font_dir" -mindepth 1 -maxdepth 1 \
    -printf '%f\n' | sort)
  [[ $installed == "$expected" ]]
  while IFS= read -r font_file; do
    [[ -f $font_dir/$font_file && ! -L $font_dir/$font_file ]]
  done <<< "$expected"

  rm -- \
    "$font_dir/MesloLGSNerdFontMono-Regular.ttf" \
    "$font_dir/MesloLGSNerdFontMono-Bold.ttf" \
    "$font_dir/MesloLGSNerdFontMono-Italic.ttf" \
    "$font_dir/MesloLGSNerdFontMono-BoldItalic.ttf"
  rmdir -- "$font_dir"
  fc-cache -f
)
```

Never recursively remove a shared font directory.

Use `dnf history` to identify package transactions. Remove packages only after
checking that no other software depends on them.

### Login shell

Restore the exact shell recorded before `chsh`, after confirming it is listed
in `/etc/shells`:

```zsh
(
  set -euo pipefail
  previous_shell=/absolute/path/recorded/before/change
  grep -Fx -- "$previous_shell" /etc/shells
  chsh -s "$previous_shell"
)
```

The change applies at next login. If Zsh cannot start, use a TTY or another
administrator account.

## 12. Future automation

A future setup tool should use one machine-readable set of pinned versions,
URLs, and checksums; default to dry-run; inspect every destination; preserve
unknown user data in unique backups; validate before publishing; roll back only
what it created; and never automate `sudo`, DNF confirmation, remote
download-and-execute, or `chsh`. Implement and validate Fedora and macOS paths
separately.
