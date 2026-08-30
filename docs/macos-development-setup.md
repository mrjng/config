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
- The standalone Homebrew autosuggestions and syntax-highlighting scripts are
  reused when readable; their absence never prevents Zsh from starting.
- Neovim becomes `EDITOR` and `VISUAL` when it is available. Git continues to
  use its existing `core.editor`; this profile does not set `GIT_EDITOR`.
- A prompt hook recovers narrowly scoped terminal mouse and focus modes outside
  Zellij. It never calls the broad `reset` command.
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
/opt/homebrew/bin/brew list --versions zsh-autosuggestions || true
/opt/homebrew/bin/brew list --versions zsh-syntax-highlighting || true
test -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh || true
test -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh || true
NVIM_LOG_FILE=/dev/null command nvim --version | sed -n '1p'
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
print(f"background={opts.background.as_sharp}")
print(f"background_opacity={opts.background_opacity}")
print(f"background_blur={opts.background_blur}")
print(f"background_image={opts.background_image}")
print(f"background_image_layout={opts.background_image_layout}")
print(f"background_tint={opts.background_tint}")
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
if opts.background.as_sharp != "#191919":
    raise SystemExit(1)
if opts.background_opacity != 0.8 or opts.background_blur != 0:
    raise SystemExit(1)
if opts.background_image is not None:
    raise SystemExit(1)
if opts.background_image_layout != "scaled" or opts.background_tint != 0.95:
    raise SystemExit(1)
'
```

The expected result is zero bad lines, family `MesloLGS NF`, size `14.0`, and
`macos_option_as_alt=2`, Kitty's value for `left`. It also proves the portable
background color, opacity, blur, layout, and tint while the optional image is
absent without a warning. Parsing proves configuration syntax and values, not
font availability or rendering. Reproduce the deployed Kitty topology in a
disposable directory and prove that the entry point finds the shared, macOS,
and theme includes through their deployed sibling links:

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
if opts.background_opacity != 0.8 or opts.background_blur != 0:
    raise SystemExit(1)
if opts.background_image is not None:
    raise SystemExit(1)
if opts.background_image_layout != "scaled" or opts.background_tint != 0.95:
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

## 4. Install missing Homebrew formulae only after approval

Kitty and Zellij are present on the initial target. If Section 2 confirms all
four font faces, no font installation is needed. Inspect each formula first,
then install only the missing names. This example builds that exact list and
suppresses automatic update and post-install cleanup for the scoped operation:

```zsh
typeset -a missing_formulae
for formula in starship zsh-autosuggestions zsh-syntax-highlighting; do
  /opt/homebrew/bin/brew list --versions "$formula" >/dev/null 2>&1 ||
    missing_formulae+=("$formula")
done
if (( ${#missing_formulae} )); then
  HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 \
    /opt/homebrew/bin/brew install "${missing_formulae[@]}"
fi

/opt/homebrew/bin/brew list --versions \
  starship zsh-autosuggestions zsh-syntax-highlighting
for plugin_file in \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -r $plugin_file && -f $plugin_file ]]
  resolved_plugin_file=${plugin_file:A}
  [[ -f $resolved_plugin_file && ! -L $resolved_plugin_file ]]
done
unset formula missing_formulae plugin_file resolved_plugin_file
```

These are standalone scripts; `oh-my-zsh.sh` remains unsourced and the
preserved Oh My Zsh plugin checkouts are neither updated nor used. The two
plugins are optional integrations in the shell configuration, so a machine
without them still receives a usable prompt. Installing the packages is the
reproducible fresh-machine path; reusing an existing readable installation is
not an installation step. Re-check formula names and versions before
reproducing this step much later because package versions change.

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
  record_destination "$HOME/.config/kitty/macos.local.conf" \
    kitty-macos-local.conf
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

### Create an optional host-local Kitty wallpaper file

`macos.local.conf` is a private regular file beside the deployed Kitty links,
not another repository symlink. The tracked configuration contains only the
portable opacity, layout, and tint. Run this block from somewhere inside the
clone after replacing `wallpaper` with an absolute path. It refuses an existing
file, directory, or symlink, requires the selected backup to say the destination
was absent, and publishes the one-line file atomically:

```zsh
(
  set -euo pipefail
  repo=$(git rev-parse --show-toplevel) || exit
  current_repo=$repo
  backup_root=/paste/the/printed/backup/path
  wallpaper=/absolute/path/to/personal-wallpaper.jpg
  destination="$HOME/.config/kitty/macos.local.conf"
  config_dir=${destination:h}
  deployed_record="$backup_root/kitty-macos-local.conf.deployed"
  [[ -d $backup_root && ! -L $backup_root ]]
  [[ -f $backup_root/repository-root && ! -L $backup_root/repository-root ]]
  IFS= read -r recorded_repo <"$backup_root/repository-root"
  [[ -n $recorded_repo && $recorded_repo == /* ]]
  [[ $current_repo == $recorded_repo ]]
  [[ -f $backup_root/kitty-macos-local.conf.was-absent ]]
  [[ ! -e $backup_root/kitty-macos-local.conf.was-present ]]
  [[ ! -e $deployed_record && ! -L $deployed_record ]]
  [[ $wallpaper == /* && -f $wallpaper && ! -L $wallpaper ]]
  [[ -d $config_dir && ! -L $config_dir ]]
  [[ ! -e $destination && ! -L $destination ]]

  umask 077
  integer deployed_record_created=0
  temporary_file=$(mktemp "$config_dir/.macos.local.conf.XXXXXXXX")
  cleanup_local_file() {
    operation_status=$?
    trap - EXIT INT TERM HUP
    case $temporary_file in
      "$config_dir"/.macos.local.conf.*)
        [[ ! -e $temporary_file && ! -L $temporary_file ]] ||
          rm -f -- "$temporary_file"
        ;;
      *) print -u2 -- "refusing cleanup outside Kitty config: $temporary_file" ;;
    esac
    if (( deployed_record_created )) &&
      [[ ! -e $destination && ! -L $destination ]]; then
      rm -f -- "$deployed_record"
    fi
    exit "$operation_status"
  }
  trap cleanup_local_file EXIT INT TERM HUP
  print -r -- "background_image $wallpaper" >"$temporary_file"
  [[ -f $temporary_file && ! -L $temporary_file ]]
  [[ $(stat -f '%Lp' "$temporary_file") == 600 ]]
  cp -p -- "$temporary_file" "$deployed_record"
  deployed_record_created=1
  [[ -f $deployed_record && ! -L $deployed_record ]]
  cmp -s -- "$temporary_file" "$deployed_record"
  [[ ! -e $destination && ! -L $destination ]]
  mv -- "$temporary_file" "$destination"
  trap - EXIT INT TERM HUP
)
```

If the backup records `was-present`, retain the existing local file instead of
running this block. A missing local file is valid: `globinclude` then matches
nothing and Kitty must still parse without a warning. The local file remains in
place if the clone moves, although the absolute repository symlinks break and
must be rolled back or redeployed.

Validate the deployed topology and local image without opening Kitty. Run from
somewhere inside the clone; any bad line or warning is a failure:

```zsh
repo=$(git rev-parse --show-toplevel) || exit
kitty_bin=/Applications/kitty.app/Contents/MacOS/kitty
KITTY_CONFIG_DIRECTORY="$HOME/.config/kitty" "$kitty_bin" +runpy '
import os
from kitty.config import load_config

config_path = os.path.join(os.environ["KITTY_CONFIG_DIRECTORY"], "kitty.conf")
bad_lines = []
opts = load_config(config_path, accumulate_bad_lines=bad_lines)
for bad_line in bad_lines:
    print(f"bad_line={bad_line}")
if bad_lines:
    raise SystemExit(1)
if opts.background.as_sharp != "#191919":
    raise SystemExit(1)
if opts.background_opacity != 0.8 or opts.background_blur != 0:
    raise SystemExit(1)
if not opts.background_image or not os.path.isfile(opts.background_image):
    raise SystemExit(1)
if opts.background_image_layout != "scaled" or opts.background_tint != 0.95:
    raise SystemExit(1)
if str(opts.font_family) != "MesloLGS NF" or opts.macos_option_as_alt != 2:
    raise SystemExit(1)
print(f"background_image={opts.background_image}")
'
```

## 7. Validate the deployed shell and applications

Start a fresh interactive Zsh without replacing the current process:

```zsh
/bin/zsh -i -c '
  print -r -- "zsh=$ZSH_VERSION"
  print -r -- "starship=${commands[starship]-missing}"
  print -r -- "zellij=${commands[zellij]-missing}"
  print -r -- "ZELLIJ=${ZELLIJ-unset}"
  print -r -- "EDITOR=${EDITOR-unset}"
  print -r -- "VISUAL=${VISUAL-unset}"
  print -r -- "GIT_EDITOR=${GIT_EDITOR-unset}"
  print -r -- "git_editor=$(git var GIT_EDITOR)"
  (( $+functions[_zsh_autosuggest_start] ))
  (( $+functions[_zsh_highlight] ))
'
```

`starship` should resolve below `/opt/homebrew`, `zellij` below
`~/.cargo/bin`, and `ZELLIJ` should remain unset outside an explicitly started
session. `EDITOR` and `VISUAL` must be `nvim`, `GIT_EDITOR` must remain unset,
and `git var GIT_EDITOR` must print `nvim`. Zellij consequently receives
`EDITOR=nvim` without a keymap change. Autosuggestions load after any configured
fzf widgets; zoxide and Starship initialize next; syntax highlighting loads
last.

The shared `precmd` hook sends only DEC private-mode resets for mouse tracking
1000, 1002, 1003, 1005, 1006, 1007, 1015, and 1016, focus reporting 1004, then
shows the cursor with mode 25. This repairs stale escape-sequence handling after
an interrupted remote SSH or Zellij application. It intentionally emits
nothing when `ZELLIJ` is set because the local Zellij session owns mouse input.
It does not reset bracketed paste, cursor shape, colors, or unrelated state.

Open a new Kitty window and verify:

- prompt glyphs render correctly in regular, bold, italic, and bold italic;
- the personal wallpaper, opacity, scale, and tint match the intended host;
- autosuggestions appear and accept with Right Arrow, `Ctrl+F`, and `Ctrl+E`;
- syntax coloring remains active after Starship initializes;
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

  local_destination="$HOME/.config/kitty/macos.local.conf"
  local_present_marker="$backup_root/kitty-macos-local.conf.was-present"
  local_absent_marker="$backup_root/kitty-macos-local.conf.was-absent"
  if [[ -f $local_present_marker && ! -e $local_absent_marker ]]; then
    [[ -f $local_destination && ! -L $local_destination ]]
    [[ -f $backup_root/kitty-macos-local.conf &&
      ! -L $backup_root/kitty-macos-local.conf ]]
    cmp -s -- "$local_destination" "$backup_root/kitty-macos-local.conf"
  elif [[ -f $local_absent_marker && ! -e $local_present_marker ]]; then
    if [[ -e $local_destination || -L $local_destination ]]; then
      [[ -f $local_destination && ! -L $local_destination ]]
      local_deployed_record="$backup_root/kitty-macos-local.conf.deployed"
      [[ -f $local_deployed_record && ! -L $local_deployed_record ]]
      cmp -s -- "$local_destination" "$local_deployed_record"
    fi
  else
    exit 1
  fi

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

  if [[ -f $local_absent_marker &&
    ( -e $local_destination || -L $local_destination ) ]]; then
    rm -- "$local_destination"
  fi
)
```

Open a new shell to reactivate the restored Oh My Zsh and Powerlevel10k setup.
The host-local wallpaper file is preserved unchanged when it existed before
deployment and is removed when this deployment created it from an absent
destination and it still matches the recorded deployed content. The existing
backup directory and its metadata are retained.

A deployment record created by an older guide may have neither local-file
marker. The rollback above intentionally refuses to infer prior state in that
case. After rolling back the repository links with the guide version associated
with that record, remove a later host-local wallpaper only when its provenance
and exact content are independently known. This self-contained check needs no
live clone and validates the recorded absolute root without dereferencing it:

```zsh
(
  set -euo pipefail
  backup_root=/paste/the/printed/backup/path
  expected_wallpaper=/absolute/path/to/personal-wallpaper.jpg
  destination="$HOME/.config/kitty/macos.local.conf"
  repository_root_file="$backup_root/repository-root"
  [[ -d $backup_root && ! -L $backup_root ]]
  [[ -f $repository_root_file && ! -L $repository_root_file ]]
  IFS= read -r recorded_repo <"$repository_root_file"
  [[ -n $recorded_repo && $recorded_repo == /* ]]
  metadata_lines=$(wc -l <"$repository_root_file")
  (( metadata_lines == 1 ))
  [[ $expected_wallpaper == /* ]]
  [[ -f $destination && ! -L $destination ]]
  local_lines=$(wc -l <"$destination")
  (( local_lines == 1 ))
  IFS= read -r local_setting <"$destination"
  [[ $local_setting == "background_image $expected_wallpaper" ]]
  rm -- "$destination"
)
```
