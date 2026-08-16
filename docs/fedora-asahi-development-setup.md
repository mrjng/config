# Fedora Asahi Development Environment Setup

Last updated: 2026-08-16

This document records the reproducible setup of a Fedora Asahi development environment. It tracks decisions, observed state, validation, migration steps, and rollback points rather than serving as a package list alone.

## Status labels

- `applied`: a command or file change has been completed
- `verified`: behavior has been confirmed from command output or physical testing
- `planned`: the direction is agreed upon but has not been applied
- `deferred`: a dependency or decision is still required

A configuration that parses successfully is not considered physically verified.

Current phase status:

| Phase | State | Evidence or next condition |
|---|---|---|
| Baseline and audit | completed | System, shortcuts, and legacy configuration recorded |
| Fedora shell packages | completed | Exact RPM versions and plugin paths recorded below |
| Repository-only Kitty and Zsh pass | applied | Proposed files exist on `feat/fedora-asahi-dev-env`; validation is recorded below |
| Isolated Kitty and Bare Zsh test | completed, user-verified | Proposed profiles and listed interactive behavior passed Phase 6 |
| Starship, Zellij, Nerd Font, Neovim | deferred | No active configuration or installation in this pass |
| Symlink deployment | deferred | Requires explicit approval, target inspection, and backups |
| Terminal bell policy | deferred | Bell behavior was not selected during the isolated test |
| macOS runtime behavior | unverified | The proposed macOS profile has not been run on macOS |
| Login-shell change | deferred | Bash remains the account shell |

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
| fzf | 0.74.2 | installed and verified from RPM |
| zoxide | 0.9.8 | installed and verified from RPM |
| eza | 0.23.5 | installed and verified from RPM |
| Zsh autosuggestions | 0.7.1 | installed and source path verified |
| Zsh syntax highlighting | 0.8.0 | installed and source path verified |
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

### Fedora shell packages

The Fedora shell-package phase is completed. These exact packages are
installed:

```text
zsh-autosuggestions-0.7.1-4.fc44.noarch
zsh-syntax-highlighting-0.8.0-7.fc44.noarch
fzf-0.74.2-1.fc44.aarch64
zoxide-0.9.8-2.fc44.aarch64
eza-0.23.5-1.fc44.aarch64
```

Confirmed plugin source paths:

```text
/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

`rpm -ql fzf` confirmed `/usr/share/fzf/shell/key-bindings.zsh` and
`/usr/share/zsh/site-functions/_fzf`. Fedora's package does not install a Zsh
`completion.zsh`; native `compinit` discovers the packaged `_fzf` completion,
while the key-binding file is sourced only when readable.

Reproduce the package and path checks with:

```bash
rpm -q \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  fzf \
  zoxide \
  eza

rpm -ql zsh-autosuggestions | rg 'zsh-autosuggestions\.zsh$'
rpm -ql zsh-syntax-highlighting | rg 'zsh-syntax-highlighting\.zsh$'
rpm -ql fzf | rg '/(key-bindings\.zsh|_fzf)$'
```

Stop if an expected file is absent or unreadable. Do not replace a missing
Fedora file with a remote script; update the guarded repository path only after
the installed package layout has been inspected.

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

## 7. Repository layout

The first repository-only pass creates this proposed, undeployed configuration:

```text
README.md
AGENTS.md
docs/
  fedora-asahi-development-setup.md
kitty/
  kitty.conf                 # Fedora entry point
  common.conf
  linux.conf
  macos.conf                 # standalone macOS entry point
zsh/
  .zshrc
  conf.d/
    aliases.zsh
    completion.zsh
    history.zsh
    interactive.zsh
    linux.zsh
    macos.zsh
```

`kitty/common.conf` temporarily reuses the platform-neutral
`kitty/work/current-theme.conf`. A new theme, Starship configuration, Zellij
configuration and layouts, Nerd Font assets, Neovim configuration, and a
bootstrap script are deferred. None should be created merely to fill out a
planned directory tree.

If deployment is later approved, use explicit symlinks and a small bootstrap
script at the current repository scale. Reconsider GNU Stow if the repository
grows into many independent configuration packages.

Do not delete or modify `kitty/work`, `zsh/work`, or
`kitty/kitty.macos.conf`; they remain legacy references until the replacement
has been physically verified.

## 8. Migration plan

### Phase 0 - Record the baseline (`completed`)

- Record installed versions and executable paths.
- Verify Kitty, Wayland, isolated Zsh, and Hangul input.
- Clone the repository and confirm a clean working tree.
- Audit existing dotfiles.

Rollback: none; this phase was read-only.

### Phase 1 - Create the working branch and commit documentation (`completed`)

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

Observed repository state after this phase:

```text
Branch: feat/fedora-asahi-dev-env
Commit: c12a5d3 docs: document Fedora Asahi environment setup
```

The terminal-bell option remains deferred because no physical test result has
been recorded yet.

### Phase 2 - Query package availability (`completed`)

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

Observed Fedora 44 aarch64 results:

| Package | Version | Repository | Decision |
|---|---:|---|---|
| `zsh-autosuggestions` | 0.7.1-4.fc44 | Fedora | install in Phase 3 |
| `zsh-syntax-highlighting` | 0.8.0-7.fc44 | Fedora | install in Phase 3 |
| `fzf` | 0.74.2-1.fc44 | updates | install in Phase 3 |
| `zoxide` | 0.9.8-2.fc44 | Fedora | install in Phase 3 |
| `eza` | 0.23.5-1.fc44 | updates | install in Phase 3 |
| `neovim` | 0.12.4-3.fc44 | updates | defer until the shell is stable |
| `starship` | no match in enabled repositories | - | compare external options in Phase 4 |
| `zellij` | no match in enabled repositories | - | compare external options in Phase 4 |

At the time of the query, only `kitty`, `zsh`, `git`, and `rg` from this toolset
were present on `PATH`.

Repository hygiene check:

```text
?? docs/SETUP.md
?? docs/fedora-asahi-dotfiles-audit.md
```

Both are intentionally excluded from Git. Confirm that the canonical English
document is tracked, then move these two untracked artifacts outside the
repository rather than deleting them without inspection.

### Phase 3 - Install Fedora-packaged shell dependencies (`completed`)

The five approved packages were installed before the first repository-only
implementation pass. Neovim remained separate. The reproducible installation
command was:

```bash
sudo dnf install \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  fzf \
  zoxide \
  eza
```

The exact installed RPMs and plugin paths are recorded under **Completed work**.
Verification must show all five RPMs, readable plugin files, and commands for
`fzf`, `zoxide`, and `eza`.

Stop if the transaction proposes removing packages, replacing Fedora packages
with third-party builds, or adding Neovim, Starship, or Zellij. Review a new
transaction separately instead of expanding this phase.

Rollback: use the recorded package-manager transaction and remove only packages
that transaction added. Never remove a package that existed before the setup or
is now required by another package.

### Phase 4 - Decide external binaries and the Nerd Font (`planned`)

Starship and Zellij were not available from the currently enabled Fedora or
Fedora Asahi repositories. Do not add another COPR automatically.

Preferred approach: install version-pinned, checksum-verified upstream aarch64
Linux binaries into `~/.local/bin`. This requires no root access, does not grant
an external repository ongoing package-manager trust, and can be rolled back by
removing two explicit files. The tradeoff is that updates are manual and must
be documented.

Release candidates observed on 2026-08-16:

| Tool | Candidate | Asset |
|---|---:|---|
| Starship | 1.26.0 | `starship-aarch64-unknown-linux-musl.tar.gz` |
| Zellij | 0.44.3 | `zellij-aarch64-unknown-linux-musl.tar.gz` |

Alternatives:

- Starship's Fedora instructions use the third-party `atim/starship` COPR.
- Both projects can be installed with Cargo, at the cost of a Rust toolchain and
  local compilation.
- Piping a remote installation script directly into a shell is convenient but
  less auditable and is not the preferred reproducible path.

Do not install either binary until the exact release URLs, upstream checksum
files, destination, update procedure, and rollback command have been reviewed.
Select and install the Nerd Font in the same phase so prompt glyphs can be
tested immediately.

### Phase 5 - Refactor inside the repository only (`applied`)

The first pass on `feat/fedora-asahi-dev-env` does the following:

- Adds repository working rules in `AGENTS.md`.
- Creates concise shared, Fedora/Wayland, and macOS Kitty files.
- Keeps Kitty's default `Ctrl+Shift+C/V` and adds no pane or tab mappings.
- Creates bare Zsh configuration with native completion and Emacs line editing.
- Guards Fedora plugins, fzf key bindings, zoxide, eza, and the future Starship
  initialization point so the shell remains usable when optional tools are absent.
- Sources syntax highlighting last.
- Preserves all legacy files unchanged.
- Leaves Starship, Zellij, Nerd Font, Neovim, deployment, bell policy, and the
  login shell deferred.

No home-directory links, package operations, external downloads, or login-shell
changes belong in this phase.

Run repository validation from the repository root:

```bash
# Every Zsh file, including preserved legacy references, must parse.
while IFS= read -r zsh_file; do
  zsh -n "$zsh_file" || exit 1
done < <(find zsh -type f -print | sort)

# Kitty 0.47.1 must parse the Fedora entry point without warnings.
kitty +runpy '
from kitty.config import load_config
path = "kitty/kitty.conf"
bad_lines = []
load_config(path, accumulate_bad_lines=bad_lines)
print(f"bad_lines={len(bad_lines)}")
raise SystemExit(bool(bad_lines))
' 2>&1

# These checks should print no matches.
rg -n '/Users|/opt/homebrew' \
  kitty/kitty.conf kitty/common.conf kitty/linux.conf

rg -n -i \
  'ctrl\+space|cmd\+[cv]|alt\+(left|right)|ctrl\+g|neighboring_window|goto_tab|launch.*split' \
  kitty/kitty.conf kitty/common.conf kitty/linux.conf

# Legacy references must remain unchanged, and whitespace must be clean.
git diff --exit-code -- kitty/work zsh/work kitty/kitty.macos.conf
git diff --check

# Review every untracked path; no generated private state may appear.
git status --short --untracked-files=all
```

Expected results: every Zsh command exits zero; Kitty prints only
`bad_lines=0`; both `rg` commands and the legacy `git diff` print nothing;
`git diff --check` exits zero; status lists only the intended files in this
phase. The status must not contain `.zsh_history`, `.zcompdump`, `.env`, cache
directories, credentials, tokens, SSH files, or an audit report.

Stop on any parser warning, unexpected path, forbidden binding, legacy diff,
whitespace error, or unexplained status entry.

Observed on 2026-08-16:

- All nine Zsh files, including the two legacy files, passed `zsh -n`.
- Kitty 0.47.1 parsed `kitty/kitty.conf` with `bad_lines=0` and no warnings.
- Effective Kitty settings retained URL detection, the `monospace` fallback,
  Wayland, and default `Ctrl+Shift+C/V`; Ctrl+Space, Alt+Left, and Ctrl+G had no
  Kitty action.
- An isolated PTY-backed Zsh load with `HISTFILE=/dev/null` confirmed native
  Emacs bindings, fzf Ctrl+T, eza aliases, zoxide, autosuggestions, syntax
  highlighting, and the fallback prompt.
- Forbidden-path, shortcut-ownership, private-state, and legacy-diff checks
  produced no matches. `git diff --check` passed.
- Repository validation alone does not physically verify settings; the separate
  user-verified Phase 6 results are recorded below.

Rollback before deployment: revert the eventual branch commit, or—while still
uncommitted—remove only the exact new files listed in this phase and restore
only `README.md` and this document after reviewing their diffs. No live home
configuration is affected.

### Phase 6 - Test without changing live home configuration (`completed, user-verified`)

Launch a new Kitty window that uses both proposed repository profiles:

```bash
HISTFILE=/dev/null \
ZDOTDIR="$HOME/src/config/zsh" \
kitty --config "$HOME/src/config/kitty/kitty.conf" /usr/bin/zsh -d
```

- `HISTFILE=/dev/null` prevents this isolated test from writing command history.
- `ZDOTDIR` points Zsh to the proposed repository configuration.
- `/usr/bin/zsh -d` skips global Zsh startup files while still loading the proposed
  interactive `.zshrc`.
- Closing the test Kitty window is the rollback.

User-verified results:

- The proposed Kitty configuration launched successfully.
- The proposed Bare Zsh profile loaded successfully.
- `HISTFILE=/dev/null` prevented persistent test history.
- Emacs `Ctrl+A` and `Ctrl+E` line-editing bindings worked.
- `Ctrl+C` interrupted the foreground command.
- Native Zsh completion worked.
- Autosuggestions and syntax highlighting worked.
- fzf `Ctrl+R` history search and `Ctrl+T` file selection worked.
- zoxide initialization and navigation worked.
- Guarded eza aliases were available.
- Fcitx5 retained `Ctrl+Space`, and Hangul input worked.
- Kitty retained `Ctrl+Shift+C/V` clipboard behavior.
- Kitty URL detection worked.

Terminal bell policy, macOS runtime behavior, Starship, Zellij, Nerd Font,
Neovim, symlink deployment, and the login-shell change remain deferred or
unverified.

Rollback: close the test Kitty window.

### Phase 7 - Deploy symlinks (`planned`)

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

### Phase 8 - Broader physical verification (`partially completed`)

Phase 6 user-verified Fcitx5 `Ctrl+Space`, Hangul input, Kitty clipboard
behavior, URL detection, and the proposed Kitty and Zsh profiles. These broader
items remain unverified or deferred:

- Confirm that Apple Command arrives as Super and Option as Alt.
- Test KDE `Meta+V`, Overview, screenshots, and virtual desktops.
- Test Kitty font-size controls.
- Select and test the terminal bell policy.
- Test the macOS profile on macOS.
- Test Starship, Zellij, Nerd Font, and Neovim after their deferred phases.
- Test symlink deployment only after target inspection and backups are approved.
- Compare readability, smoothness, and battery use before and after enabling transparency.

Do not mark an item verified merely because its configuration parses.

### Phase 9 - Finalize the branch (`planned`)

After repository validation and physical testing, and only with explicit
approval to stage and commit:

```bash
cd ~/src/config
git status --short --branch
git diff --check
git add \
  AGENTS.md \
  README.md \
  docs/fedora-asahi-development-setup.md \
  kitty/kitty.conf kitty/common.conf kitty/linux.conf kitty/macos.conf \
  zsh/.zshrc zsh/conf.d
git diff --cached
git commit -m "feat: add Fedora Asahi terminal environment"
```

Do not use `git add --all`. Review `git status --short --untracked-files=all`
and the explicit path list first so an audit report or private state cannot be
staged accidentally.

Merge only after the deployed configuration has passed Phase 8:

```bash
git switch main
git merge --ff-only feat/fedora-asahi-dev-env
```

### Phase 10 - Change the login shell (`optional and last`)

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

Review the first repository-only Kitty and Zsh pass together with the completed
Phase 6 user-verified results. Decide separately whether any remaining Phase 8
Linux tests should be performed before deployment planning.

Keep Starship, Zellij, the Nerd Font, Neovim, symlink deployment, terminal bell
policy, and `chsh` deferred until each corresponding decision and rollback plan
receives explicit approval.

## References

- Kitty documentation: <https://sw.kovidgoyal.net/kitty/>
- Zellij user guide: <https://zellij.dev/documentation/>
- Starship configuration: <https://starship.rs/config/>
- Starship presets: <https://starship.rs/presets/>
- Starship releases: <https://github.com/starship/starship/releases>
- Zsh documentation: <https://zsh.sourceforge.io/Doc/>
- Zellij releases: <https://github.com/zellij-org/zellij/releases>
- Fedora packages: <https://packages.fedoraproject.org/>
- KDE Accessibility and System Bell: <https://docs.kde.org/stable_kf6/en/plasma-desktop/kcontrol/kcmaccess/kcmaccess.pdf>
- Powerlevel10k support status: <https://github.com/romkatv/powerlevel10k>
- Oh My Zsh: <https://github.com/ohmyzsh/ohmyzsh>
