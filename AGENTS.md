# Repository Working Rules

## Scope

- Work inside this repository only unless the user explicitly approves a broader operation.
- Linux and macOS are supported profiles. Fedora Asahi on KDE/Wayland is the current Linux target.
- Repository changes do not imply package installation or deployment to a home directory.

## Actions requiring explicit approval

Do not install or remove packages, change home-directory files, create symlinks,
change the login shell, stage changes, create commits, or run remote installation
scripts without explicit approval. Never automate `sudo`, `dnf`, `chsh`, or a
download-and-execute workflow.

## Files and data to preserve

- Treat `kitty/work/**`, `zsh/work/**`, and `kitty/kitty.macos.conf` as legacy reference files. Do not modify, move, or delete them.
- Preserve unrelated user changes and stop when the worktree contains unexplained changes.
- Never add credentials, tokens, SSH material, shell history, caches, private environment files, or generated state.
- Keep diagnostic audit artifacts outside Git. Durable decisions belong in tracked documentation.

## Configuration conventions

- Prefer concise configuration files that explain intent. Do not commit generated snapshots of complete default configurations.
- Put genuinely shared behavior in common files and isolate Linux- and macOS-specific behavior.
- Fcitx5 owns `Ctrl+Space`.
- Kitty owns `Ctrl+Shift+C` and `Ctrl+Shift+V` for terminal copy and paste.
- Zellij will own panes, tabs, sessions, and layouts. Do not duplicate those bindings in Kitty.
- Keep terminal bell suppression inactive until physical testing selects a policy.

## Validation

- Run `zsh -n` on every tracked Zsh configuration file that is created or modified.
- Parse the Fedora Kitty entry point with the installed Kitty version and treat warnings as failures.
- Run `git diff --check` and inspect `git status --short` before handoff.
- Check new Fedora Kitty files for macOS paths and forbidden shortcut ownership before handoff.
- Parsing proves syntax only; record physical verification separately.
