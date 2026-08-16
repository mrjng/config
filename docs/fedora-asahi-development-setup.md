# Fedora Asahi Development Environment Setup

Last updated: 2026-08-16

This document records the reproducible setup of a Fedora Asahi development environment. It tracks decisions, observed state, validation, migration steps, and rollback points rather than serving as a package list alone.

## Status labels

- `applied`: a command or file change has been completed
- `verified`: behavior has been confirmed from command output or physical testing
- `planned`: the direction is agreed upon but has not been applied
- `deferred`: a dependency or decision is still required

A configuration that parses successfully is not considered physically verified.

## 1. Goals

- Build a Kitty, Zellij, Zsh, and Starship-based environment on Fedora Asahi.
- Preserve useful behavior from the existing macOS-oriented dotfiles.
- Separate macOS-only paths and behavior from Fedora/KDE/Wayland configuration.
- Keep configuration under version control in `~/src/config`.
- Document installation, validation, and rollback so the setup can be repeated on another machine.
- Keep package installation, dotfile deployment, and login-shell changes as independent operations.

## 2. Baseline system state

| Item | Observed state | Status |
|---|---|---|
| Hardware | Apple Silicon M1 Pro | verified |
| Operating system | Fedora Asahi Remix 44, aarch64 | verified |
| Desktop | KDE Plasma on Wayland | verified |
| Terminal | Kitty 0.47.1 | installed and verified |
| Shell | Zsh 5.9 installed; Bash remains the account shell | installed and verified |
| Git | 2.55.0 | installed and verified |
| ripgrep | 15.2.0 | installed |
| Input method | Fcitx5 Hangul, toggled with `Ctrl+Space` | user-verified |
| Apple function keys | `hid_apple.fnmode=2` | applied |

Environment observed inside Kitty:

```text
TERM=xterm-kitty
SHELL=/bin/bash
SESSION=wayland
```

Isolated Zsh test:

```text
PROCESS=zsh
ZSH_VERSION=5.9
DEFAULT_SHELL=/bin/bash
Zsh Hangul input: verified
```

Zsh and Hangul input work correctly. The login shell remains Bash because `chsh` has not been run.

## 3. Completed work

### Base packages

Kitty, Zsh, and Git were installed with:

```bash
sudo dnf install kitty zsh git
```

ripgrep was installed as a weak dependency. The following command paths were verified:

```text
/usr/bin/kitty
/usr/bin/zsh
/usr/bin/git
```

`/usr/bin/zsh` is present in `/etc/shells`.

### Dotfiles repository

```bash
mkdir -p ~/src
git clone https://github.com/mrjng/config.git ~/src/config
```

The repository was clean on `main...origin/main`, and no submodules were configured. Files present at the time of the audit:

```text
kitty/kitty.macos.conf
kitty/work/current-theme.conf
kitty/work/kitty.conf
README.md
zsh/work/.zshrc
zsh/work/.zshrc_custom
```

### Dotfiles audit

Codex CLI 0.147.0 was used from `~/src/config` to audit Fedora Asahi compatibility. The audit did not modify files, install packages, create symlinks, or run `chsh`.

The detailed audit report is retained as an external diagnostic artifact and is
intentionally not committed. Confirmed decisions and reproducible procedures
belong in this document instead.

## 4. Confirmed audit findings

### Deployment state

- The repository's Kitty and Zsh configurations have not been deployed.
- `~/.config/kitty/` was empty, and `~/.zshrc` was absent.
- Bash remains the account login shell.

### Existing Kitty configuration

- Both Kitty files are roughly 2,800-line snapshots of older generated defaults with custom settings embedded throughout.
- `mmap` is not a valid Kitty 0.47.1 directive, so the existing `Ctrl+G` mapping does nothing.
- `/Users/...` wallpaper paths and `/opt/homebrew/bin/nvim` are invalid on Fedora.
- `macos_option_as_alt` is macOS-specific.
- Kitty interprets `cmd` as Super/Meta on Linux. The tracked `cmd+v` conflicts with KDE's `Meta+V` clipboard-history shortcut.
- Kitty pane shortcuts duplicate Zellij if Zellij is adopted as the primary multiplexer.

### Existing Zsh configuration

- The tracked `.zshrc` assumes that Oh My Zsh and Powerlevel10k are installed.
- `zsh-autosuggestions`, `zsh-syntax-highlighting`, `eza`, Neovim, and MesloLGS NF were not installed at audit time.
- The `vi` alias unconditionally points to missing Neovim.
- The `eza`-based aliases cannot currently run.

### Shortcut ownership

| Shortcut | Owner | Decision |
|---|---|---|
| `Ctrl+C` | shell/TUI | Preserve for SIGINT and application input |
| `Ctrl+V` | shell/TUI | Preserve for quoted insert and application input |
| `Ctrl+Shift+C/V` | Kitty | Retain for terminal copy and paste |
| `Ctrl+Space` | Fcitx5 | Reserve for Hangul input switching |
| `Meta+V` | KDE | Retain for clipboard history |
| panes, tabs, sessions | Zellij | Do not duplicate in Kitty |
| editor splits | Neovim | Manage with `<C-w>` or leader mappings |

### Optional feature: terminal bell policy

Status: `deferred until tested`

Shell completion can emit the terminal BEL character, for example when `Tab`
has no useful completion. On Wayland, Kitty may ask the compositor to play the
system-default bell, so the trigger can originate in the shell and Kitty even
when the sound itself appears to come from KDE.

Identify the scope before changing a persistent setting:

```bash
# Test the normal bell in the current terminal.
printf '\a'

# Open an isolated Kitty window with only its audible bell disabled.
kitty -o enable_audio_bell=no
```

Run `printf '\a'` in the isolated window and compare it with the original
window and with the sound caused by `Tab` completion.

Available policies:

| Scope | Setting | Benefit | Cost |
|---|---|---|---|
| Kitty only | `enable_audio_bell no` | Silences terminal BEL without changing other desktop sounds | Other applications may still use the system bell |
| KDE system-wide | Disable **Use System Bell** in System Settings > Accessibility > System Bell | Silences the system bell for all applications | Removes an accessibility and attention cue globally |
| Keep default | No change | Preserves traditional feedback | Completion failures can produce an unwanted sound |

Preferred default: use the Kitty-only setting if the isolated test becomes
silent. Use the KDE system-wide setting only when the same bell is unwanted in
all applications. Do not apply both initially because doing so obscures which
layer solved the issue.

The `window_alert_on_bell` and `bell_on_tab` visual indicators are separate and
remain unchanged unless they also prove distracting.

## 5. Recommended stack

| Area | Choice | Responsibility |
|---|---|---|
| Terminal emulator | Kitty | Rendering, fonts, colors, clipboard |
| Multiplexer | Zellij | Panes, tabs, sessions, project layouts |
| Shell | Bare Zsh | Completion, history, aliases, line editing |
| Prompt | Starship | Path, Git state, runtimes, command status |
| Suggestions | zsh-autosuggestions | History-based command suggestions |
| Highlighting | zsh-syntax-highlighting | Interactive command highlighting |
| Search | fzf | Fuzzy file and history search |
| Navigation | zoxide | Frecency-based directory navigation |
| Font | MesloLGS Nerd Font initially | Compatibility with the previous P10k appearance |
| Theme | Catppuccin Mocha family | Consistent Kitty, Starship, and Zellij colors |
| Editor | Neovim | Configure after the shell is stable |

Atuin is deferred until shell-history storage, synchronization, and sensitive-data policies are explicitly decided.

## 6. Oh My Zsh and Powerlevel10k migration

Oh My Zsh is not deprecated. The new profile will avoid it to make dependencies and startup order more explicit, not because the framework is unusable.

Powerlevel10k is in limited-support mode. The existing files will remain available as legacy reference until the replacement has been validated.

The replacement is not Starship alone:

```text
Oh My Zsh prompt/theme      -> Starship
Oh My Zsh completion       -> Native Zsh completion
Autosuggestions            -> Fedora-packaged Zsh plugin
Syntax highlighting        -> Fedora-packaged Zsh plugin
Oh My Zsh aliases/functions -> Migrate only those still in use
```

Expected benefits:

- Shell behavior and prompt design are separated between `.zshrc` and `starship.toml`.
- The same prompt configuration can be reused on Linux and macOS.
- Only required plugins are loaded, making startup failures easier to diagnose.
- Catppuccin, Pastel Powerline, and similar presets can preserve a decorated P10k-like appearance.
- The new setup does not depend on a prompt project with limited maintenance.

Costs and limitations:

- Some Oh My Zsh aliases and completions must be selected and migrated manually.
- Starship does not reproduce the P10k configuration wizard or every Zsh-specific prompt behavior.
- Starship adds a separate binary dependency.
- Enabling too many modules can make the prompt wide or slow.

## 7. Target repository layout

Use explicit symlinks and a small bootstrap script at the current repository scale. Reconsider GNU Stow if the repository grows into many independent configuration packages.

```text
README.md
AGENTS.md
docs/
  fedora-asahi-development-setup.md
kitty/
  kitty.conf
  common.conf
  linux.conf
  macos.conf
  themes/
    catppuccin-mocha.conf
zsh/
  .zshrc
  conf.d/
    aliases.zsh
    completion.zsh
    history.zsh
    interactive.zsh
    linux.zsh
    macos.zsh
starship/
  starship.toml
zellij/
  config.kdl
  layouts/
    development.kdl
scripts/
  bootstrap
```

Do not delete `kitty/work`, `zsh/work`, or `kitty/kitty.macos.conf` until the replacement configuration has been used and verified.

## 8. Migration plan

### Phase 0 - Record the baseline (`completed`)

- Record installed versions and executable paths.
- Verify Kitty, Wayland, isolated Zsh, and Hangul input.
- Clone the repository and confirm a clean working tree.
- Audit existing dotfiles.

Rollback: none; this phase was read-only.

### Phase 1 - Create the working branch and commit documentation (`next`)

All repository work starts on a dedicated branch before files are added or
refactored:

```bash
cd ~/src/config
git status --short --branch
git branch --show-current
git switch -c feat/fedora-asahi-dev-env
```

If the branch already exists, use this instead of `git switch -c`:

```bash
git switch feat/fedora-asahi-dev-env
```

Place this document at:

```text
~/src/config/docs/fedora-asahi-development-setup.md
```

Commit only the durable setup document. Do not add the audit report:

```bash
git add docs/fedora-asahi-development-setup.md
git diff --cached --check
git diff --cached
git commit -m "docs: document Fedora Asahi environment setup"
```

Optional terminal-bell evaluation: first open an isolated Kitty window and run
the bell test described above.

```bash
kitty -o enable_audio_bell=no
```

If that window is silent and the Kitty-only policy is preferred, edit the
current live Kitty file without overwriting any file that may now exist.

```bash
mkdir -p ~/.config/kitty
${EDITOR:-nano} ~/.config/kitty/kitty.conf
```

Add or update this directive:

```conf
enable_audio_bell no
```

Reload Kitty with `Ctrl+Shift+F5`, or restart Kitty, and test with:

```bash
printf '\a'
```

This live file is temporary. Before symlink deployment, the bootstrap process
must back it up explicitly. Add the directive to the final tracked Kitty common
configuration only after the policy has been selected.

Rollback: remove only the added directive and reload Kitty. Do not delete the
file if it contains any unrelated setting.

### Phase 2 - Query package availability (`planned`)

Do not install anything yet. Query Fedora 44 aarch64 repositories for candidate packages:

```bash
dnf info \
  zellij \
  starship \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  fzf \
  zoxide \
  eza \
  neovim
```

Record current environment and command availability:

```bash
printf 'SHELL=%s\nTERM=%s\nSESSION=%s\n' \
  "$SHELL" "$TERM" "$XDG_SESSION_TYPE"

command -v \
  kitty zsh git rg \
  zellij starship fzf zoxide eza nvim || true

git -C ~/src/config status --short --branch
```

Stop condition: if Fedora does not provide Zellij or Starship, do not add a COPR or execute an installation script automatically. Compare the official prebuilt binary, Cargo, and external-repository options first.

### Phase 3 - Refactor inside the repository only (`planned`)

- Create a dedicated Git branch.
- Keep this setup record current; retain the audit report outside Git.
- Extract only active Kitty settings into concise files.
- Separate shared, Linux, and macOS settings.
- Remove Kitty pane bindings so Zellij owns panes, tabs, and sessions.
- Implement native Zsh completion and guarded plugin loading.
- Add draft Starship and Zellij configurations.
- Preserve the existing files as legacy reference.

Do not install packages, create home-directory symlinks, or run `chsh` in this phase.

Initial validation:

```bash
zsh -n ~/src/config/zsh/.zshrc
git -C ~/src/config diff --check
git -C ~/src/config status --short
```

Kitty and Zellij validation commands will be finalized after their installed versions are known.

Rollback: discard or revert only the branch commit. No live home configuration is affected.

### Phase 4 - Install approved dependencies (`planned`)

Finalize package names and installation sources after reviewing Phase 2 output.

Rules:

- Prefer official Fedora packages.
- Do not add an external repository merely because Starship or Zellij is absent from Fedora.
- Document the Nerd Font source and installation path.
- Keep Neovim and compiler/toolchain installation separate from shell migration.
- Record the exact set of packages added by this setup.

Rollback: remove only packages introduced by this phase. Do not remove pre-existing dependencies.

### Phase 5 - Test without changing live home configuration (`planned`)

Start Zsh explicitly and launch Kitty with an explicit test configuration.

Validate:

- Prompt and Nerd Font glyph rendering
- Hangul input and input-method switching
- `Ctrl+C` interruption of a long-running command
- `Ctrl+Shift+C/V` terminal copy and paste
- Zsh completion, autosuggestions, and syntax highlighting
- Starship Git state and project runtime detection
- Zellij panes, tabs, detach/attach, and layouts
- KDE global-shortcut behavior

Rollback: close the test shell or terminal window.

### Phase 6 - Deploy symlinks (`planned`)

The bootstrap script must default to `--dry-run` and meet these requirements:

- Use an explicit target allowlist.
- Refuse to overwrite an existing regular file.
- Back up each target individually with a timestamp.
- Treat an already-correct symlink as success.
- Provide `--check` behavior.
- Roll back only links created by the script.
- Never run a package manager or `chsh`.

Expected links:

```text
~/.config/kitty/kitty.conf  -> ~/src/config/kitty/kitty.conf
~/.config/zellij/config.kdl -> ~/src/config/zellij/config.kdl
~/.config/starship.toml     -> ~/src/config/starship/starship.toml
~/.zshrc                    -> ~/src/config/zsh/.zshrc
```

### Phase 7 - Physical verification (`planned`)

- Confirm that Apple Command arrives as Super and Option as Alt.
- Test Fcitx5 `Ctrl+Space`.
- Test KDE `Meta+V`, Overview, screenshots, and virtual desktops.
- Test Kitty clipboard and font-size controls.
- Test Zellij panes, tabs, sessions, and layouts.
- If Neovim has been added, test editor-split ownership.
- Compare readability, smoothness, and battery use before and after enabling transparency.

Do not mark an item verified merely because its configuration parses.

### Phase 8 - Change the login shell (`optional and last`)

Consider this only after Zsh has worked reliably inside Kitty for several days:

```bash
chsh -s /usr/bin/zsh
```

The change takes effect in a new login session. Roll back to Bash with:

```bash
chsh -s /bin/bash
```

Keeping Bash as the login shell and starting Zsh only inside Kitty remains a valid configuration.

## 9. Starship configuration plan

Start from the official Catppuccin Powerline preset, then reduce it to the information that is useful in daily work.

Show by default:

- Current directory
- Git branch and working-tree state
- Language/runtime versions only inside matching projects
- Duration only for commands exceeding a threshold
- Previous command success or failure

Hide by default:

- Local username and hostname
- Always-visible operating-system icons
- Runtimes unrelated to the current project
- Cloud or container modules not currently in use

Show username and hostname conditionally in SSH sessions. Use `starship timings` after configuration to find slow modules.

Zsh integration point:

```zsh
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
```

## 10. Safety rules

- Never commit SSH keys, tokens, credentials, shell history, or private environment variables.
- Never overwrite a pre-existing home file without inspecting it and creating a targeted backup.
- Keep package installation separate from dotfile deployment.
- Do not automate `sudo`, `dnf`, `chsh`, or remote installation scripts without explicit approval.
- Put only genuinely shared settings in common files; isolate Linux and macOS behavior.
- Do not commit another generated snapshot of Kitty's complete default configuration.
- Record validation commands and rollback instructions with each configuration change.

## 11. Next checkpoint

The next action is Phase 1: create or switch to the dedicated branch and commit
only this setup document. Then run the read-only package and command query in
Phase 2. Review that output before deciding:

1. How to install Starship and Zellij
2. How to install the selected Nerd Font
3. Which paths Fedora uses for the packaged Zsh plugins
4. The exact scope of the repository refactor
5. The file list for the first implementation commit

## References

- Kitty documentation: <https://sw.kovidgoyal.net/kitty/>
- Zellij user guide: <https://zellij.dev/documentation/>
- Starship configuration: <https://starship.rs/config/>
- Starship presets: <https://starship.rs/presets/>
- Zsh documentation: <https://zsh.sourceforge.io/Doc/>
- Fedora packages: <https://packages.fedoraproject.org/>
- KDE Accessibility and System Bell: <https://docs.kde.org/stable_kf6/en/plasma-desktop/kcontrol/kcmaccess/kcmaccess.pdf>
- Powerlevel10k support status: <https://github.com/romkatv/powerlevel10k>
- Oh My Zsh: <https://github.com/ohmyzsh/ohmyzsh>
