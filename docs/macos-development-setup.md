# macOS development setup

This guide migrates an Apple Silicon Mac to the repository's shared Kitty,
bare Zsh, Starship, and Zellij configuration. It keeps installation, repository
editing, and home-directory deployment as separate approval boundaries.

The initial migration target is macOS 26.6 on `arm64`, `/bin/zsh` 5.9,
Homebrew under `/opt/homebrew`, Kitty 0.42.2, and Zellij 0.44.3 under
`~/.cargo/bin`. Font availability is an explicit validation gate rather than
an assumption: Kitty must recognize the `MesloLGS NF` family with Regular,
Bold, Italic, and Bold Italic faces before deployment.

## Ownership and non-goals

- macOS owns `Ctrl+Space`, `Ctrl+Option+Space`, and `Ctrl+Arrow`.
- Kitty keeps its macOS defaults for `Cmd+C/V`, `Cmd+T/W`, and tab navigation.
- Left Option is terminal Alt; right Option remains available for macOS input.
- Zellij retains its default keymap and is started explicitly, never by Zsh.
- Oh My Zsh, Powerlevel10k, `~/.p10k.zsh`, and their installation directories
  are preserved but are not sourced by the new profile.
- `kitty/work/**`, `zsh/work/**`, and `kitty/kitty.macos.conf` remain unchanged
  legacy references.

## 1. Confirm the repository boundary

Run this and every later repository-dependent block from somewhere inside the
clone. Each block resolves the clone root rather than assuming its location:

```zsh
repo=$(git rev-parse --show-toplevel) || exit

git -C "$repo" status --short --branch
git -C "$repo" --no-pager branch -vv
```

Stop for any unexplained branch, staged change, modified file, or untracked
file. Reproduction does not depend on a development-history base commit or on
the worktree state that existed before these instructions were written.

## 2. Inspect the installed environment

```zsh
uname -m
sw_vers
/bin/zsh --version
/opt/homebrew/bin/brew --prefix
/Applications/kitty.app/Contents/MacOS/kitty --version
"$HOME/.cargo/bin/zellij" --version
command -v starship || true
```

Expected architecture is `arm64`, Homebrew prefix is `/opt/homebrew`, and
Starship is initially absent. In Kitty's font chooser, select `MesloLGS NF` and
verify that it lists Regular, Bold, Italic, and Bold Italic. In Font Book, the
corresponding full names are `MesloLGS NF Regular`, `MesloLGS NF Bold`,
`MesloLGS NF Italic`, and `MesloLGS NF Bold Italic`. Stop for installation
approval if the family or any face is missing; this guide does not install
fonts.

## 3. Validate repository changes before installation or deployment

Run syntax and whitespace checks first:

```zsh
repo=$(git rev-parse --show-toplevel) || exit

while IFS= read -r file; do
  /bin/zsh -n "$repo/$file" || exit
done < <(git -C "$repo" ls-files 'zsh/*' | grep -E '\.(zsh|zshrc)$')

git -C "$repo" diff --check
git -C "$repo" status --short
git -C "$repo" --no-pager diff -- \
  . ':(exclude)kitty/work/**' ':(exclude)zsh/work/**' \
  ':(exclude)kitty/kitty.macos.conf'
```

Parse the cross-platform Kitty entry point without opening a window, using the
configuration loader bundled with the installed application:

```zsh
repo=$(git rev-parse --show-toplevel) || exit
kitty_bin=/Applications/kitty.app/Contents/MacOS/kitty
KITTY_CONFIG_DIRECTORY="$repo/kitty" "$kitty_bin" +runpy '
import os
from kitty.config import load_config

config_path = os.path.join(os.environ["KITTY_CONFIG_DIRECTORY"], "kitty.conf")
bad_lines = []
opts = load_config(config_path, accumulate_bad_lines=bad_lines)
print(f"bad_lines={len(bad_lines)}")
print(f"font_family={opts.font_family}")
print(f"font_size={opts.font_size}")
print(f"macos_option_as_alt={opts.macos_option_as_alt}")
for bad_line in bad_lines:
    print(f"bad_line={bad_line}")
if bad_lines:
    raise SystemExit(1)
if str(opts.font_family) != "MesloLGS NF":
    raise SystemExit(1)
if opts.font_size != 14.0:
    raise SystemExit(1)
if opts.macos_option_as_alt != 2:  # left
    raise SystemExit(1)
'
```

The expected result is zero bad lines, family `MesloLGS NF`, size `14.0`, and
`macos_option_as_alt=2`, Kitty's value for `left`. Parsing proves configuration
syntax and values, not font availability or rendering. Reproduce the deployed
Kitty topology in a disposable directory and prove that the entry point finds
the shared, macOS, and theme includes through their deployed sibling links:

```zsh
(
  set -euo pipefail
  repo=$(git rev-parse --show-toplevel) || exit
  kitty_bin=/Applications/kitty.app/Contents/MacOS/kitty
  audit_root=$(mktemp -d /tmp/kitty-macos-symlink-audit.XXXXXXXX)

  cleanup_audit() {
    operation_status=$?
    trap - EXIT INT TERM HUP
    case $audit_root in
      /tmp/kitty-macos-symlink-audit.*) rm -rf -- "$audit_root" ;;
      *) print -u2 -r -- \
           "refusing cleanup outside audit path: $audit_root"
         exit 1 ;;
    esac
    exit "$operation_status"
  }
  trap cleanup_audit EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP

  audit_config_dir="$audit_root/.config/kitty"
  mkdir -p -- "$audit_config_dir/work"
  ln -s -- "$repo/kitty/kitty.conf" "$audit_config_dir/kitty.conf"
  ln -s -- "$repo/kitty/common.conf" "$audit_config_dir/common.conf"
  ln -s -- "$repo/kitty/macos.conf" "$audit_config_dir/macos.conf"
  ln -s -- "$repo/kitty/work/current-theme.conf" \
    "$audit_config_dir/work/current-theme.conf"

  KITTY_CONFIG_DIRECTORY="$audit_config_dir" "$kitty_bin" +runpy '
import os
from kitty.config import load_config

config_path = os.path.join(os.environ["KITTY_CONFIG_DIRECTORY"], "kitty.conf")
bad_lines = []
opts = load_config(config_path, accumulate_bad_lines=bad_lines)
print(f"bad_lines={len(bad_lines)}")
print(f"font_family={opts.font_family}")
print(f"inactive_text_alpha={opts.inactive_text_alpha}")
print(f"background={opts.background.as_sharp}")
if bad_lines:
    raise SystemExit(1)
if str(opts.font_family) != "MesloLGS NF":
    raise SystemExit(1)
if opts.inactive_text_alpha != 0.9:
    raise SystemExit(1)
if opts.background.as_sharp != "#191919":
    raise SystemExit(1)
'
)
```

The expected shared value is `inactive_text_alpha=0.9`; the macOS value is the
`MesloLGS NF` family; and the theme value is `background=#191919`. Any missing
include or other Kitty warning fails this check. Use Kitty's bundled CoreText
resolver to validate the installed family and all four faces without opening a
window:

```zsh
repo=$(git rev-parse --show-toplevel) || exit
kitty_bin=/Applications/kitty.app/Contents/MacOS/kitty
"$kitty_bin" +runpy '
from kitty.fonts.core_text import font_for_family, list_fonts

family = "MesloLGS NF"
expected_styles = {"Regular", "Bold", "Italic", "Bold Italic"}
faces = {
    font["style"]: font
    for font in list_fonts()
    if font["family"] == family
}
for style in sorted(faces):
    font = faces[style]
    print(f"{style}: {font['full_name']} [{font['postscript_name']}]")
if set(faces) != expected_styles:
    raise SystemExit(1)
descriptor, bold, italic = font_for_family(family)
print(f"resolved_family={descriptor['family']}")
print(f"resolved_face={descriptor['postscript_name']}")
if descriptor["family"] != family or bold or italic:
    raise SystemExit(1)
'
```

The resolver must print exactly the four expected styles and resolve the base
face as `MesloLGS-NF-Regular`. Check actual rendering in Kitty's font chooser as
described above, and treat every Kitty warning as a failure until resolved.

Check Zellij without changing its keymap:

```zsh
repo=$(git rev-parse --show-toplevel) || exit
ZELLIJ_CONFIG_FILE="$repo/zellij/config.kdl" \
  "$HOME/.cargo/bin/zellij" setup --check
```

Do not install or deploy if any repository check fails.

## 4. Install the missing executable only after approval

Kitty and Zellij are present on the initial target. If Section 2 confirms all
four font faces, no font installation is needed. Install only Starship:

```zsh
/opt/homebrew/bin/brew install starship
/opt/homebrew/bin/starship --version
```

The Homebrew formula name is `starship`. Re-check it before reproducing this
step much later because package versions change.

## 5. Preserve the live configuration before deployment

Do this only after repository validation and explicit approval. The backup is
private, outside Git, and excludes shell history. Its parent must be a real
directory, not a symlink. `mktemp -d` creates a fresh directory atomically;
never set `backup_root` to an existing directory or reuse an earlier backup.
It records whether each destination was a regular file or absent; stop on a
symlink or other file type rather than guessing how to preserve it:

```zsh
(
  set -euo pipefail
  repo=$(git rev-parse --show-toplevel) || exit
  umask 077
  backup_parent="$HOME/.config-backups"
  [[ $backup_parent == /* ]] || {
    print -u2 -- "STOP: backup parent is not absolute: $backup_parent"
    exit 1
  }
  if [[ -e $backup_parent || -L $backup_parent ]]; then
    [[ -d $backup_parent && ! -L $backup_parent ]] || {
      print -u2 -- "STOP: backup parent is not a non-symlink directory"
      exit 1
    }
  else
    mkdir -- "$backup_parent"
  fi
  [[ -z ${backup_root-} ]] || {
    print -u2 -- "STOP: backup_root is already set; refusing to reuse it"
    exit 1
  }
  backup_root=$(mktemp -d "$backup_parent/dotfiles-macos.XXXXXXXX") || exit
  [[ -d $backup_root && ! -L $backup_root ]] || {
    print -u2 -- "STOP: mktemp did not create a non-symlink directory"
    exit 1
  }
  print -r -- "$repo" >"$backup_root/repository-root"

  record_destination() {
    local source_path=$1 state_name=$2
    if [[ -e $source_path || -L $source_path ]]; then
      [[ -f $source_path && ! -L $source_path ]]
      cp -p -- "$source_path" "$backup_root/$state_name"
      touch -- "$backup_root/$state_name.was-present"
    else
      touch -- "$backup_root/$state_name.was-absent"
    fi
  }

  record_destination "$HOME/.zshrc" zshrc
  record_destination "$HOME/.config/kitty/kitty.conf" kitty.conf
  record_destination "$HOME/.config/kitty/common.conf" kitty-common.conf
  record_destination "$HOME/.config/kitty/macos.conf" kitty-macos.conf
  record_destination "$HOME/.config/kitty/work/current-theme.conf" \
    kitty-current-theme.conf
  record_destination "$HOME/.config/zellij/config.kdl" zellij-config.kdl
  record_destination "$HOME/.config/starship.toml" starship.toml

  [[ ! -e "$HOME/.p10k.zsh" || -f "$HOME/.p10k.zsh" ]]
  [[ ! -e "$HOME/.p10k.zsh" ]] || \
    cp -p -- "$HOME/.p10k.zsh" "$backup_root/p10k.zsh"

  find "$backup_root" -type f -exec shasum -a 256 {} \;
  print -r -- "$backup_root"
)
```

Record the printed path. Its `repository-root` metadata contains the absolute
clone root resolved during backup. Do not continue if that metadata is missing,
if a source file exists but its backup or `was-present` marker is missing, or if
an absent destination lacks its `was-absent` marker. The existing
`~/.oh-my-zsh` and Powerlevel10k directories stay in place and are not deleted.

## 6. Deploy only after a second explicit approval

Paste the recorded backup directory from the preceding step. This block checks
every source, marker, backup, and unchanged destination before modifying
anything. It then stages all links before displacing regular files. If a later
operation fails, its trap removes staged or deployed links and restores every
file already displaced. Newly created configuration directories can remain
empty after such a recovery, but no destination is intentionally left partly
deployed:

```zsh
(
  set -euo pipefail
  repo=$(git rev-parse --show-toplevel) || exit
  current_repo=$repo
  backup_root=/paste/the/printed/backup/path
  [[ -f "$backup_root/repository-root" && \
    ! -L "$backup_root/repository-root" ]]
  IFS= read -r recorded_repo <"$backup_root/repository-root"
  [[ -n $recorded_repo && $recorded_repo == /* ]]
  [[ $current_repo == $recorded_repo ]]
  repo=$recorded_repo
  typeset -a sources destinations state_names
  sources=(
    "$repo/zsh/.zshrc"
    "$repo/kitty/kitty.conf"
    "$repo/kitty/common.conf"
    "$repo/kitty/macos.conf"
    "$repo/kitty/work/current-theme.conf"
    "$repo/zellij/config.kdl"
    "$repo/starship/starship.toml"
  )
  destinations=(
    "$HOME/.zshrc"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.config/kitty/common.conf"
    "$HOME/.config/kitty/macos.conf"
    "$HOME/.config/kitty/work/current-theme.conf"
    "$HOME/.config/zellij/config.kdl"
    "$HOME/.config/starship.toml"
  )
  state_names=(
    zshrc
    kitty.conf
    kitty-common.conf
    kitty-macos.conf
    kitty-current-theme.conf
    zellij-config.kdl
    starship.toml
  )

  [[ -d $backup_root && ! -L $backup_root ]]
  integer index
  for (( index = 1; index <= ${#sources}; index++ )); do
    source_path=${sources[index]}
    destination=${destinations[index]}
    state_name=${state_names[index]}
    present_marker="$backup_root/$state_name.was-present"
    absent_marker="$backup_root/$state_name.was-absent"
    [[ -f $source_path && ! -L $source_path ]]
    [[ ! -e "$destination.dotfiles-new" && \
      ! -L "$destination.dotfiles-new" ]]
    [[ ! -e "$backup_root/$state_name.pre-deploy" && \
      ! -L "$backup_root/$state_name.pre-deploy" ]]
    if [[ -f $present_marker && ! -e $absent_marker ]]; then
      [[ -f $destination && ! -L $destination ]]
      [[ -f "$backup_root/$state_name" ]]
      cmp -s -- "$destination" "$backup_root/$state_name"
    elif [[ -f $absent_marker && ! -e $present_marker ]]; then
      [[ ! -e $destination && ! -L $destination ]]
    else
      exit 1
    fi
  done

  recover_partial_deployment() {
    trap - EXIT INT TERM HUP
    set +e
    for (( index = 1; index <= ${#sources}; index++ )); do
      source_path=${sources[index]}
      destination=${destinations[index]}
      state_name=${state_names[index]}
      displaced="$backup_root/$state_name.pre-deploy"
      [[ ! -L "$destination.dotfiles-new" ]] || \
        unlink -- "$destination.dotfiles-new"
      if [[ -L $destination && $(readlink "$destination") == $source_path ]]; then
        unlink -- "$destination"
      fi
      if [[ -e $displaced || -L $displaced ]]; then
        [[ ! -e $destination && ! -L $destination ]] && \
          mv -- "$displaced" "$destination"
      fi
    done
  }
  trap recover_partial_deployment EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP

  mkdir -p -- \
    "$HOME/.config/kitty/work" \
    "$HOME/.config/zellij"
  for (( index = 1; index <= ${#sources}; index++ )); do
    ln -s -- "${sources[index]}" "${destinations[index]}.dotfiles-new"
  done

  for (( index = 1; index <= ${#sources}; index++ )); do
    destination=${destinations[index]}
    state_name=${state_names[index]}
    if [[ -f "$backup_root/$state_name.was-present" ]]; then
      mv -- "$destination" "$backup_root/$state_name.pre-deploy"
    fi
    mv -- "$destination.dotfiles-new" "$destination"
  done

  trap - EXIT INT TERM HUP
)
```

This does not change the login shell. `.p10k.zsh`, Oh My Zsh, and
Powerlevel10k remain available for rollback. Keep the backup directory: its
state markers distinguish destinations that must be restored from destinations
that must simply be removed. The deployed links contain this absolute recorded
root. Moving or renaming the clone while they are deployed breaks the links;
use rollback with the recorded metadata or redeploy them from the new clone
location.

## 7. Validate the deployed shell and applications

Start a fresh interactive Zsh without replacing the current process:

```zsh
/bin/zsh -i -c '
  print -r -- "zsh=$ZSH_VERSION"
  print -r -- "starship=${commands[starship]-missing}"
  print -r -- "zellij=${commands[zellij]-missing}"
  print -r -- "ZELLIJ=${ZELLIJ-unset}"
'
```

`starship` should resolve below `/opt/homebrew`, `zellij` below
`~/.cargo/bin`, and `ZELLIJ` should remain unset outside an explicitly started
session. Open a new Kitty window and verify:

- prompt glyphs render correctly in regular, bold, italic, and bold italic;
- `Cmd+C/V`, `Cmd+T/W`, and `Shift+Cmd+[/]` remain Kitty actions;
- `Ctrl+Space`, `Ctrl+Option+Space`, and `Ctrl+Arrow` remain macOS actions;
- left Option sends Alt combinations while right Option enters macOS characters;
- `zellij` starts only when invoked and still uses its default keymap.

Syntax parsing does not prove physical shortcut or font behavior. Stop and roll
back if input-source switching, Spaces navigation, character entry, clipboard,
or tab behavior differs from the ownership policy.

## Rollback

Use the recorded backup path. This block needs neither Git nor a live clone and
can run from any directory. It reads the absolute repository root solely from
the selected backup's metadata. The preflight accepts only a symlink created by
this guide or a destination already rolled back, so an unrelated replacement is
never overwritten. A destination marked `was-present` is restored from the
regular file moved during deployment; one marked `was-absent` is left absent.
The operation is resumable if interrupted:

```zsh
(
  set -euo pipefail
  backup_root=/paste/the/printed/backup/path
  [[ -d $backup_root && ! -L $backup_root ]]
  repository_root_file="$backup_root/repository-root"
  [[ -f $repository_root_file && ! -L $repository_root_file ]]
  IFS= read -r repo <"$repository_root_file"
  [[ -n $repo && $repo == /* ]]
  metadata_lines=$(wc -l <"$repository_root_file")
  (( metadata_lines == 1 ))
  typeset -a sources destinations state_names
  sources=(
    "$repo/zsh/.zshrc"
    "$repo/kitty/kitty.conf"
    "$repo/kitty/common.conf"
    "$repo/kitty/macos.conf"
    "$repo/kitty/work/current-theme.conf"
    "$repo/zellij/config.kdl"
    "$repo/starship/starship.toml"
  )
  destinations=(
    "$HOME/.zshrc"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.config/kitty/common.conf"
    "$HOME/.config/kitty/macos.conf"
    "$HOME/.config/kitty/work/current-theme.conf"
    "$HOME/.config/zellij/config.kdl"
    "$HOME/.config/starship.toml"
  )
  state_names=(
    zshrc
    kitty.conf
    kitty-common.conf
    kitty-macos.conf
    kitty-current-theme.conf
    zellij-config.kdl
    starship.toml
  )

  integer index
  for (( index = 1; index <= ${#sources}; index++ )); do
    source_path=${sources[index]}
    destination=${destinations[index]}
    state_name=${state_names[index]}
    displaced="$backup_root/$state_name.pre-deploy"
    if [[ -f "$backup_root/$state_name.was-present" &&
      ! -e "$backup_root/$state_name.was-absent" ]]; then
      if [[ -L $destination ]]; then
        [[ $(readlink "$destination") == $source_path ]]
        [[ -f $displaced && ! -L $displaced ]]
      elif [[ ! -e $destination ]]; then
        [[ -f $displaced && ! -L $displaced ]]
      else
        [[ -f $destination && ! -L $destination ]]
        [[ ! -e $displaced && ! -L $displaced ]]
        cmp -s -- "$destination" "$backup_root/$state_name"
      fi
    elif [[ -f "$backup_root/$state_name.was-absent" &&
      ! -e "$backup_root/$state_name.was-present" ]]; then
      [[ ! -e $destination || -L $destination ]]
      [[ ! -L $destination || $(readlink "$destination") == $source_path ]]
      [[ ! -e $displaced && ! -L $displaced ]]
    else
      exit 1
    fi
  done

  for (( index = 1; index <= ${#sources}; index++ )); do
    destination=${destinations[index]}
    state_name=${state_names[index]}
    displaced="$backup_root/$state_name.pre-deploy"
    [[ ! -L $destination ]] || unlink -- "$destination"
    if [[ -f "$backup_root/$state_name.was-present" &&
      ( -e $displaced || -L $displaced ) ]]; then
      mv -- "$displaced" "$destination"
    fi
  done
)
```

Open a new shell to reactivate the restored Oh My Zsh and Powerlevel10k setup.
