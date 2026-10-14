# TODO

## OS-specific paths and commands

Done:
- [x] The bootstrap writes `DF_OS` (darwin or linux) and `DF_DISTRO` (from `/etc/os-release`) to `~/.config/dotfiles/env`.
- [x] Centene setup (`shell/profiles/work/zsh/centene.zsh`): the macOS certificate and proxy setup runs only on darwin. AWS, npm and the alias run everywhere.
- [x] `shell/profiles/work/aliases.d/grafana.sh`: reads the macOS config path first, then `$XDG_CONFIG_HOME/grafanactl/config.yaml`.
- [x] `shell/lib/50_file.sh`: `fs` uses BSD `stat` on darwin and GNU `stat` elsewhere.
- [x] `variants/vim/plug/vimrc`: loads fzf only from a Homebrew path that exists.
- [x] `variants/tmux/codeangler/tmux.conf`: powerline loads only when installed, and its files only when present.
- [x] `variants/tmux/oh-my-tmux/vi-bindings`: clipboard keys use pbcopy/pbpaste, else xclip.
- [x] `lib/common.sh`: `is_ubuntu` reads `/etc/os-release` (`ID` or `ID_LIKE`). This also matches Pop!_OS and other Ubuntu-based distros, which the old `/etc/issue` check did not.

Still open:
- [ ] Confirm grafanactl's real config path on Linux. The XDG path is a guess.
- [ ] Centene setup on Linux: the certificate and proxy source is unknown. Only the portable settings apply there.
- [ ] Find the Linux powerline install path for the codeangler tmux option.
- [ ] Review the ~30 `bin/` scripts from codeangler. Several are macOS-only (`osx_*`, `ssid`, `manp` uses `open`, `ssh-keygen` and `ssh-copy-id` call Homebrew paths).
- [x] OS-only aliases now live in `shell/os/darwin/` and `shell/os/linux/`, loaded by `DF_OS`. The Ubuntu apt aliases only load on Linux.
- [ ] `shell/common/environment.sh` checks for `~/homebrew` and `/usr/local/bin` by existence, so it's safe, but the PATH order differs per OS. Review.
- [x] Review the contents of `install/` (fonts, zsh, Homebrew, apt, Chef, Eclipse, and the Dropbox step are fixed or moved; see the README).

## Security

- [x] Secret scan (done): gitleaks 8.30.1 and trufflehog 3.99.2 (in `~/.local/bin`, checksums verified). No findings in the new repo tree, the original xaostx history (80 commits), or the codeangler history (489 commits). Both tools detected a planted fake token, so the scan works.
- [x] Private identifiers moved out of the repo: personal and work values are asked for at install and written to `~/.config/dotfiles/` (`local.gitconfig`, `settings.env`). The Jira user and ops path can be kept in the macOS Keychain (`secrets=macos-keychain`).
- [ ] Left in the repo on purpose: codeangler attribution, including its author's email in `variants/git-identity/codeangler/`, and the `/Users/stephenroberts` path in the iTerm2 plist, which is codeangler's author's home directory. Decide whether to change either.
- [ ] Not yet tested on macOS: the Keychain store and lookup (`security add-generic-password` and `find-generic-password`), and the `DVA-*` gate.
  - Run a secret scanner (for example gitleaks or trufflehog) over the whole tree and the full git history. The keyword scan done so far was not exhaustive.
  - Identifiers found by grep (personal and work): personal email in `onlykey.sh`, `identity.gitconfig` (email, signing key ID,), work account email in `ops.sh`, Jira user email and `gohighway.atlassian.net` in `jira.sh`, Highway AWS profile names in `aws.sh`, `*.centene.com` in `centene.zsh`, and `/Users/stephenroberts` in the iTerm2 plist. Codeangler attribution lines are expected.
  - Earlier checklist: the work account email in the `ops` alias, the signing key ID in `variants/git-identity/xaostx/identity.gitconfig`, employer hostnames and project names in the work profile.
  - Check the install scripts for tokens and keys. `install/deferred/common/60_ssh_keys.sh` handles a Dropbox token.
  - Check `variants/` for leftover credentials.
  - Confirm `.gitignore` covers generated files that could hold credentials (`~/.git-credentials` is outside the repo, but `local/` should stay ignored).

## Codeangler GitLab dotfiles (merged)

- [ ] Rotate the Hugging Face token that was in the public GitLab repo. It is now only in `local/shell/private.sh`.
- [ ] Decide on the iTerm2 plist. The GitLab copy is 53 KB and newer than the one merged, and needs a review before it replaces ours.
- [ ] The employer aliases in `local/shell/megacorp.zsh` still use `$HOME/Work` paths. Decide whether to move them to `~/ws`.
- [ ] `.gitconfig-google` (the Google identity for `~/g/Google-RA`) is not in the GitLab repo. Needed if you want that identity.
- [ ] Test prezto and the other dotfiles in the container test. The scratch-home test passed.
