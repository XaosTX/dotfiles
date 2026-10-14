# dotfiles

Shell, git, editor and terminal configuration, merged from two earlier repos. `bootstrap.sh` links it into your home directory and asks which of the conflicting options you want.

Licensed under the MIT License. See `LICENSE` and `NOTICE.md`.

## Quick start

```sh
git clone <this repo> ~/dotfiles        # any location works
cd ~/dotfiles
./bootstrap.sh --dry-run --yes          # see what would change; nothing is written
./bootstrap.sh                          # interactive: asks each question
```

## Commands

| Command | What it does |
|---|---|
| `./bootstrap.sh` | Interactive. Asks for each choice, then the profiles, then git access. |
| `./bootstrap.sh --yes` | Non-interactive. Uses `--choose`, environment variables, saved choices, then defaults. Skips git access. |
| `./bootstrap.sh --dry-run` | Prints what would be linked, backed up, or activated. Writes nothing. |
| `./bootstrap.sh --list-choices` | Prints each choice group, its options, its default, and what it means. |
| `./bootstrap.sh --profiles work,personal` | Turns on profiles (default: `work`). |
| `./bootstrap.sh --choose GROUP=OPTION` | Picks an option for a group. Repeat for several groups. |
| `./bootstrap.sh --install` | Also runs the `install/` steps (packages, fonts, default tools). |
| `./bootstrap.sh --optional` | Also runs `install/optional/` (oh-my-zsh, Chef, Eclipse). Implies `--install`. |
| `./bootstrap.sh --home DIR` | Targets another directory instead of `$HOME`. Use it to test. |
| `./bootstrap.sh --help` | Prints the usage text. |

Example:

```sh
./bootstrap.sh --yes --profiles work --choose prompt=powerlevel9k --choose zsh-plugins=oh-my-zsh
```

### Exit status

- `0`: finished with no warnings.
- `1`: finished, but with warnings (for example a missing file or a failed submodule fetch). Everything else was applied.
- `2`: bad arguments or an invalid choice. Nothing was changed.

## Interactive questions

Run without `--yes` in a terminal, the bootstrap asks:

1. **Each choice group.** Each one lists its options with the current value marked. Enter keeps it, or type the option's number. The current value is the saved choice from your last run, or a `--choose`/environment value if you gave one.
2. **Profiles.** A comma-separated list. Enter keeps the current value.
3. **Git access.** Three choices:
   - **SSH key (recommended).** Asks for a key path. If there is no key, it offers to generate an ed25519 key. It adds the key to `ssh-agent` and prints the public key so you can add it to your git host. It does not change `~/.ssh/config`.
   - **HTTPS access token.** Asks for a username and a token (typed input is hidden). The token goes into an OS credential store where one exists (macOS Keychain, or libsecret on Linux). Otherwise it goes into `~/.git-credentials` in plain text, mode 600, and the bootstrap warns you. Use a token with read access to the repos you need.
   - **Skip.** Nothing is stored. You can run the bootstrap again later.

   If the git identity choice is `none`, it also asks for your name and email for commits.

Git access is never asked for in `--yes` mode, because the bootstrap won't prompt for secrets without a terminal.

## Choices

Each group is one switch. Its options are in `variants/<group>/<option>/`, and the defaults are in `manifest/choices.conf`.

| Group | Default | Other options | What it controls |
|---|---|---|---|
| `prompt` | `starship` | `powerlevel9k` | Shell prompt. `powerlevel9k` needs `zsh-plugins=oh-my-zsh`. |
| `zsh-plugins` | `zinit` | `oh-my-zsh` | Zsh plugin framework. zinit clones itself from GitHub the first time a shell starts. |
| `vim` | `plug` | `submodule` | `plug` is vendored and works offline. `submodule` fetches XaosTX/dotvim, which needs git access. |
| `tmux` | `oh-my-tmux` | `codeangler` | tmux config. |
| `git-identity` | `xaostx` | `codeangler`, `none` | Name, email and signing key. `none` asks for name and email during git access. |
| `git-extras` | `codeangler` | `none` | Extra git settings (whitespace, CRLF, some aliases, URL shortcuts). |
| `gitignore` | `combined` | `codeangler`, `xaostx` | Global ignore list. `combined` is both lists merged, without duplicates. |
| `ls-aliases` | `xaostx` | `codeangler` | `ls`, `ll`, `l`, `la` and related aliases. |
| `editor` | `vim` | `codeangler` | `EDITOR`, `vi`, and `vim` aliases. |
| `gr-alias` | `git-remote` | `grafanactl` | What `gr` means. |
| `alacritty` | `toml` | `yml` | Alacritty config format. |
| `gitui` | `default` | `vim` | gitui key bindings. |

Set a choice in one of three ways:

- `--choose GROUP=OPTION` on the command line
- `DF_CHOICE_<GROUP>=<option>` in the environment (for example `DF_CHOICE_PROMPT=powerlevel9k`)
- Re-run the bootstrap and answer the question. The answer is saved to `~/.config/dotfiles/choices.conf`.

Precedence, highest first: `--choose`, environment, saved choice, default.

## Operating systems

The bootstrap detects the OS once and writes it to `~/.config/dotfiles/env`:

- `DF_OS`: `darwin` or `linux`
- `DF_DISTRO`: the `ID` from `/etc/os-release` (for example `ubuntu`, `pop`, `debian`)

Shell files check `$DF_OS` to choose macOS or Linux settings. Ubuntu-family systems (including Pop!_OS) are detected through `ID_LIKE` in `/etc/os-release`. Install steps are chosen by OS name, as before.

## Personal and work values

Identity and work-specific values are not in the repo. The bootstrap asks for them when you run it interactively, and writes them to your home directory:

- `~/.config/dotfiles/local.gitconfig`: git name, email, signing key, GitHub user and safe.directory. Read by git.
- `~/.config/dotfiles/settings.env` (mode 600): onlykey identity and the work values (Jira server, AWS profile names, ECS cluster names, WAF log group, proxy bypass domain). Read by the shell at startup.

Enter keeps the current value on a re-run. `--yes` runs keep the values as they are and never ask.

### Secrets: the `secrets` choice

The Jira user and the password-manager path for `ops` are secrets. The `secrets` choice picks where they are kept:

- `local` (default): in `settings.env`, mode 600.
- `macos-keychain`: in the login keychain, as the item `dotfiles.jira-user` or `dotfiles.ops-pass-path`. Only offered on macOS. The bootstrap asks whether to store each one, and `security` then prompts for the value, so it never goes on the command line. Nothing secret is written to `settings.env`.

The shell reads secrets through `df_secret` (`shell/common/secrets.sh`), which uses the store the bootstrap recorded.

## Profiles

A profile adds shell aliases and functions for one context. Profiles are loaded from `shell/profiles/<name>/`, and only the ones listed in `--profiles` (or the saved list) are loaded.

- **`work`** (default): Centene (macOS certificates and proxy, plus AWS and npm settings), Nubis, AWS, Jira, Grafana, Kubernetes and smartlog aliases, and an `ops` alias that signs in to a password manager. Employer names and values come from `settings.env` and the secret store.
- **`davita`**: for macOS hosts whose name starts with `DVA-`. The bootstrap adds it to the default list on those machines. The profile also checks the host name and OS when it loads, so it does nothing elsewhere. Settings are added as they are discovered.

Turn profiles on or off with `--profiles`. The profile list is saved between runs. A saved list is used as is, so a `DVA-` host with a saved list needs `davita` added to it.

## What gets linked and where

- Shell entry points (`~/.zshrc`, `~/.bashrc`, `~/.profile`) are short files. They load `shell/`.
- `~/.gitconfig` is a link into the repo. Per-machine git settings are in `~/.config/dotfiles/local.gitconfig`, which the base config includes last.
- Each group's chosen option is linked to `~/.config/dotfiles/active/<group>`. The shell and git configs read from there, so switching an option doesn't change the files that load it.
- Files that must sit at a fixed path (for example `~/.vimrc`, `~/.tmux.conf`) are listed in that option's `.links` file.
- `~/.config/dotfiles/env` is generated on each run. The shell entry points read it.

## Backups and restoring

Before replacing anything, the bootstrap moves the existing file or link to `~/.dotfiles-backup/<timestamp>/`, keeping its path relative to home. Links that a previous option created and no longer needs are moved there too.

To restore a file, remove the link at its original path and move the backup back:

```sh
ls ~/.dotfiles-backup/                  # find the run you want
mv ~/.dotfiles-backup/<timestamp>/.zshrc ~/.zshrc   # only after removing the link at ~/.zshrc
```

The bootstrap never deletes a regular file. It only moves files and removes links it created.

## Install steps

Install steps are grouped by OS, the same way as the shell aliases:

- `install/common/` runs on every OS (fonts).
- `install/darwin/` runs only on macOS (Xcode tools, Homebrew, casks and recipes, fzf, iTerm2, node, ruby, vim plugins, misc).
- `install/linux/` runs only on Linux (apt packages and `dist-upgrade`, vim plugins).

`install/` runs with `--install`. `install/optional/` runs with `--optional`, one prompt per step when interactive: `common/` (oh-my-zsh and the powerlevel9k theme; zinit is the default plugin framework), `linux/` (Chef DK, disabled until fixed; Eclipse with eclim, old pinned releases). `install/deferred/` is not run by any flag: the Dropbox key step, being reworked.

The OS folder is chosen by `DF_OS`. Fonts are pinned to Nerd Fonts `v3.5.1`. oh-my-zsh and powerlevel9k are cloned at pinned commits. The powerlevel9k theme is archived upstream.

## Using it from a larger bootstrap

Source `bootstrap.sh` and call `dotfiles_main` with the same flags:

```sh
source "$DOTFILES_DIR/bootstrap.sh"
dotfiles_main --yes --profiles work
```

Sourcing does not run anything by itself. From zsh, `dotfiles_main` hands the run to bash, because the script uses bash syntax. The return value is the exit status above.

## Testing

Test against a scratch directory, never your home directory:

```sh
mkdir -p /tmp/dotfiles-test
HOME=/tmp/dotfiles-test ./bootstrap.sh --yes --home /tmp/dotfiles-test
```

Setting `HOME` as well as `--home` matters: git reads `HOME` directly, so the git config and credential store go to the test directory too.

**Not yet tested:** starting zsh or bash with the generated config. Syntax is checked (`bash -n`, `zsh -n`), but a shell that loads the config has not been run.

## Layout

| Path | Contents |
|---|---|
| `bootstrap.sh` | Entry point: interactive questions, linking, git access, install. |
| `manifest/choices.conf` | Choice groups, options, defaults. |
| `manifest/links.conf` | Files linked into `$HOME`, with the OS each applies to. |
| `home/` | Files linked into `$HOME`. The shell entry points are thin. |
| `shell/common/` | Shell-neutral config: environment, aliases, the loader. |
| `shell/os/darwin/`, `shell/os/linux/` | Aliases for one OS only. The loader loads the folder matching `DF_OS`. |
| `shell/lib/` | Helper functions from the codeangler repo. |
| `shell/aliases.d/` | Per-topic aliases, always on. |
| `shell/zsh/`, `shell/bash/` | Shell-specific loaders and settings. |
| `shell/profiles/<name>/` | Profiles, selected with `--profiles`. |
| `variants/<group>/<option>/` | Options for each choice group. |
| `os/darwin/`, `os/linux/` | OS-specific files, linked only on that OS. |
| `bin/` | Utility scripts from the codeangler repo, added to `$PATH`. |
| `install/common/`, `install/darwin/`, `install/linux/` | Install steps by OS, run with `--install`. `install/optional/` and `install/deferred/` follow the same layout. |
| `lib/common.sh` | Logging, OS detection and menu helpers. |
| `test/` | Shell tests from the codeangler repo. |
| `archive/` | Kept for reference, not linked. |
| `licenses/`, `NOTICE.md` | Third-party licences and attribution. |

## Licence

MIT. See `LICENSE`. Third-party code keeps its own notices; see `NOTICE.md`.
