#!/usr/bin/env bash
# dotfiles bootstrap. Links the shared config, activates one option per choice group,
# and writes ~/.config/dotfiles/env for the shell loaders.
#
# Usage: install.sh [options]
#   -y, --yes              Don't prompt. Uses --choose, env, saved choices, then defaults.
#   --choose GROUP=OPTION  Pick an option for a choice group (repeatable).
#   --profiles LIST        Comma-separated profiles, e.g. work or work,personal.
#   --dry-run              Show what would change; change nothing.
#   --home DIR             Target home directory (default: $HOME). Used for testing.
#   --list-choices         Print choice groups and their options, then exit.
#   -h, --help             This help.
#
# Choice groups and defaults: manifest/choices.conf. Each option is variants/<group>/<option>/.
# Precedence for a group: --choose > DF_CHOICE_<GROUP> env var > saved choice > default.
#
# From a larger bootstrap, source this file and call dotfiles_main:
#   source "$DOTFILES_DIR/install.sh" && dotfiles_main --yes

DF_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
export DF_ROOT
export DOTFILES="$DF_ROOT"
source "$DF_ROOT/lib/common.sh"

DF_TARGET="${HOME%/}"
DF_RUN_TS="$(date +%Y%m%d-%H%M%S)"

df_usage() {
  awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "$DF_ROOT/install.sh"
}

df_load_choices() {
  CH_GROUP=(); CH_DEFAULT=(); CH_OPTS=(); CH_DESC=()
  local g d o desc
  while IFS='|' read -r g d o desc; do
    case "$g" in ''|\#*) continue;; esac
    CH_GROUP+=("$g"); CH_DEFAULT+=("$d"); CH_OPTS+=("$o"); CH_DESC+=("$desc")
  done < "$DF_ROOT/manifest/choices.conf"
}

df_env_name() { echo "DF_CHOICE_$(echo "$1" | tr 'a-z-' 'A-Z_')"; }

df_saved() {  # df_saved KEY: value from the last run, or empty
  local f="$DF_TARGET/.config/dotfiles/choices.conf"
  [ -f "$f" ] || return 0
  sed -n "s/^$1=//p" "$f" | tail -n 1
}

df_has_option() {  # df_has_option GROUP VALUE
  local i
  for i in "${!CH_GROUP[@]}"; do
    if [ "${CH_GROUP[$i]}" = "$1" ]; then
      case ",${CH_OPTS[$i]}," in *",$2,"*) return 0;; esac
      return 1
    fi
  done
  return 1
}

df_group_val() {  # df_group_val GROUP: the resolved option
  local i
  for i in "${!CH_GROUP[@]}"; do
    [ "${CH_GROUP[$i]}" = "$1" ] && { echo "${SEL[$i]}"; return 0; }
  done
  return 1
}

df_resolve() {  # fills SEL[] in manifest order
  local i g v cli kv env_name
  SEL=()
  for kv in "${CLI_CHOICES[@]}"; do
    case "$kv" in *=*) ;; *) e_error "--choose needs GROUP=OPTION, got: $kv"; return 2;; esac
    local known=0
    for g in "${CH_GROUP[@]}"; do [ "$g" = "${kv%%=*}" ] && known=1; done
    [ "$known" = 1 ] || { e_error "unknown choice group: ${kv%%=*}"; return 2; }
  done
  for i in "${!CH_GROUP[@]}"; do
    g="${CH_GROUP[$i]}"; cli=""
    for kv in "${CLI_CHOICES[@]}"; do
      case "$kv" in "$g="*) cli="${kv#*=}";; esac
    done
    env_name="$(df_env_name "$g")"
    v="${cli:-${!env_name:-}}"
    [ -z "$v" ] && v="$(df_saved "$g")"
    [ -z "$v" ] && v="${CH_DEFAULT[$i]}"
    if ! df_has_option "$g" "$v"; then
      e_error "invalid option '$v' for $g (options: ${CH_OPTS[$i]})"
      return 2
    fi
    if [ "$v" = macos-keychain ] && [ "$(df_os)" != darwin ]; then
      e_error "$g=$v needs macOS"
      return 2
    fi
    SEL[$i]="$v"
  done
}

df_resolve_profiles() {
  PROFILES="${PROFILES_CLI:-${DF_PROFILES:-$(df_saved profiles)}}"
  if [ -z "$PROFILES" ]; then
    PROFILES=work
    # Davita hosts: macOS machines named DVA-*. Added at install time, as a default.
    if [ "$(df_os)" = darwin ] && [[ "$(hostname -s)" == DVA-* ]]; then
      PROFILES="$PROFILES,davita"
    fi
  fi
}

df_check_deps() {
  if [ "$(df_group_val prompt)" = powerlevel9k ] && [ "$(df_group_val zsh-plugins)" != oh-my-zsh ]; then
    e_error "prompt=powerlevel9k needs zsh-plugins=oh-my-zsh"
    return 2
  fi
  if [ "$(df_group_val zsh-plugins)" = prezto ] && [ "$(df_group_val prompt)" != prezto ]; then
    e_error "zsh-plugins=prezto needs prompt=prezto (prezto draws its own prompt)"
    return 2
  fi
  if [ "$(df_group_val prompt)" = prezto ] && [ "$(df_group_val zsh-plugins)" != prezto ]; then
    e_error "prompt=prezto needs zsh-plugins=prezto"
    return 2
  fi
}

df_interactive() {
  local i n o ans mark
  local opts all
  for i in "${!CH_GROUP[@]}"; do
    IFS=',' read -r -a all <<< "${CH_OPTS[$i]}"
    opts=()
    for o in "${all[@]}"; do
      if [ "$o" = macos-keychain ] && [ "$(df_os)" != darwin ]; then continue; fi
      opts+=("$o")
    done
    e_header "${CH_GROUP[$i]}: ${CH_DESC[$i]}"
    n=0
    for o in "${opts[@]}"; do
      n=$((n + 1)); mark=""
      [ "$o" = "${SEL[$i]}" ] && mark="   <- current"
      printf '  %d) %s%s\n' "$n" "$o" "$mark"
    done
    while :; do
      read -r -p "  number, or Enter to keep [${SEL[$i]}]: " ans
      [ -z "$ans" ] && break
      if [[ "$ans" =~ ^[0-9]+$ ]] && [ "$ans" -ge 1 ] && [ "$ans" -le "${#opts[@]}" ]; then
        SEL[$i]="${opts[$((ans - 1))]}"; break
      fi
      e_error "pick a number from 1 to ${#opts[@]}"
    done
  done
  read -r -p "Profiles (comma list) [$PROFILES]: " ans
  [ -n "$ans" ] && PROFILES="$ans"
  return 0
}

df_plan() {
  local i
  e_header "Choices"
  for i in "${!CH_GROUP[@]}"; do printf '  %-14s %s\n' "${CH_GROUP[$i]}" "${SEL[$i]}"; done
  printf '  %-14s %s\n' "profiles" "$PROFILES"
  printf '  %-14s %s\n' "target" "$DF_TARGET"
  [ -n "$DF_DRY" ] && e_arrow "dry run: nothing will be changed"
}

df_os() {
  case "$(uname -s)" in
    Darwin) echo darwin;;
    Linux) echo linux;;
    *) echo other;;
  esac
}

df_distro() {  # ID from /etc/os-release (ubuntu, debian, ...), or "unknown"
  local id
  id="$( . /etc/os-release 2>/dev/null; echo "$ID" )"
  echo "${id:-unknown}"
}

df_write_state() {
  local dir="$DF_TARGET/.config/dotfiles" i
  [ -n "$DF_DRY" ] && return 0
  mkdir -p "$dir"
  {
    echo "# written by install.sh $(date '+%F %T'); edit by re-running install.sh"
    for i in "${!CH_GROUP[@]}"; do echo "${CH_GROUP[$i]}=${SEL[$i]}"; done
    echo "profiles=$PROFILES"
  } > "$dir/choices.conf"
  {
    echo "# generated by install.sh; sourced by the shell loaders. Do not edit."
    echo "export DF_ROOT=\"$DF_ROOT\""
    echo "export DOTFILES=\"$DF_ROOT\""
    echo "export DF_ACTIVE=\"$dir/active\""
    echo "export DF_PROFILES=\"$PROFILES\""
    echo "export DF_PROMPT=\"$(df_group_val prompt)\""
    echo "export DF_ZSH_PLUGINS=\"$(df_group_val zsh-plugins)\""
    echo "export DF_OS=\"$(df_os)\""
    echo "export DF_DISTRO=\"$(df_distro)\""
    echo "export DF_STATE=\"$dir\""
    echo "export DF_SECRETS=\"$(df_group_val secrets)\""
  } > "$dir/env"
  e_success "wrote $dir/choices.conf and $dir/env"
}

df_link() {  # df_link SRC DEST: SRC absolute in the repo, DEST absolute under the target home
  local src="$1" dest="$2" rel bdir
  rel="${dest#$DF_TARGET/}"
  if [ ! -e "$src" ]; then
    case "$src" in "$DF_ROOT"/local/*) return 0;; esac   # optional per-machine file
    e_error "missing ${src#$DF_ROOT/} (skipped ~/$rel)"
    DF_WARN=$((DF_WARN + 1))
    return 0
  fi
  # never write through a symlinked folder: it would move or create files inside another tree (e.g. ~/.dotfiles)
  local parent="$(dirname "$dest")"
  while [ "$parent" != "$DF_TARGET" ] && [ "$parent" != "/" ] && [ -n "$parent" ]; do
    if [ -L "$parent" ]; then
      e_arrow "kept ~/$rel: ${parent#$DF_TARGET/} is a symlink to another folder (not written through)"
      return 0
    fi
    parent="$(dirname "$parent")"
  done
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    e_success "already linked ~/$rel"
    return 0
  fi
  if [ -n "$DF_DRY" ]; then
    e_arrow "would link ~/$rel -> ${src#$DF_ROOT/}"
    return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    bdir="$DF_TARGET/.dotfiles-backup/$DF_RUN_TS"
    mkdir -p "$bdir/$(dirname "$rel")"
    mv "$dest" "$bdir/$rel"
    e_arrow "backed up ~/$rel"
    DF_BACKUPS=1
  fi
  mkdir -p "$(dirname "$dest")"
  if ln -s "$src" "$dest"; then e_success "linked ~/$rel"; else e_error "could not link ~/$rel"; DF_WARN=$((DF_WARN + 1)); fi
}

# df_npmrc DEST: ~/.npmrc is home/npmrc plus local/npmrc (per-machine, gitignored), written as a plain
# file so private registry and CA lines never sit in the tracked file. With no local/npmrc it is the
# plain link, as before. npm has no include, so the two are concatenated here.
df_npmrc() {
  local dest="$1" frag="$DF_ROOT/local/npmrc" tmp rel bdir
  if [ ! -f "$frag" ]; then
    df_link "$DF_ROOT/home/npmrc" "$dest"
    return 0
  fi
  rel="${dest#$DF_TARGET/}"
  if [ -n "$DF_DRY" ]; then
    e_arrow "would write ~/$rel from home/npmrc + local/npmrc"
    return 0
  fi
  tmp=$(mktemp) || return 1
  { cat "$DF_ROOT/home/npmrc"; printf '\n# --- local/npmrc (per machine, not tracked) ---\n'; cat "$frag"; } > "$tmp"
  if [ -f "$dest" ] && [ ! -L "$dest" ] && cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"
    e_success "already up to date ~/$rel"
    return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    bdir="$DF_TARGET/.dotfiles-backup/$DF_RUN_TS"
    mkdir -p "$bdir/$(dirname "$rel")"
    mv "$dest" "$bdir/$rel"
    e_arrow "backed up ~/$rel"
    DF_BACKUPS=1
  fi
  mkdir -p "$(dirname "$dest")"
  mv "$tmp" "$dest" && chmod 600 "$dest"
  e_success "wrote ~/$rel (home/npmrc + local/npmrc)"
}

df_tool_dirs() {  # directories that tool configs refer to and do not create themselves
  local d
  for d in "$DF_TARGET/.terraform.d/plugin-cache"; do   # terraformrc: plugin_cache_dir (terraform needs it to exist)
    [ -d "$d" ] && continue
    if [ -n "$DF_DRY" ]; then e_arrow "would create ~/${d#$DF_TARGET/}"; continue; fi
    mkdir -p "$d" && e_success "created ~/${d#$DF_TARGET/}"
  done
}

# df_probe "app:Name.app,cmd:name,...": 0 when the list is empty, or when any listed app or command is installed
df_probe() {
  local list="$1" p
  [ -z "$list" ] && return 0
  local IFS=','
  for p in $list; do
    case "$p" in
      app:*)
        if [ -d "/Applications/${p#app:}" ] || [ -d "$HOME/Applications/${p#app:}" ]; then return 0; fi ;;
      cmd:*)
        if command -v "${p#cmd:}" >/dev/null 2>&1; then return 0; fi ;;
    esac
  done
  return 1
}

df_link_home() {  # df_link_home [DEST]: every home link, or only the one whose destination is DEST
  local src dest os probe
  while IFS='|' read -r src dest os probe; do
    case "$src" in ''|\#*) continue;; esac
    [ -z "$os" ] && os=any
    if [ -n "$1" ] && [ "$dest" != "$1" ]; then continue; fi
    if [ "$os" != any ] && [ "$os" != "$(df_os)" ]; then continue; fi
    if ! df_probe "$probe"; then
      e_arrow "not linked ~/$dest yet: $probe is not installed (the end-of-run pass links it)"
      continue
    fi
    if [ "$src" = home/npmrc ]; then
      df_npmrc "$DF_TARGET/$dest"
    else
      df_link "$DF_ROOT/$src" "$DF_TARGET/$dest"
    fi
  done < "$DF_ROOT/manifest/links.conf"
}

df_drop_stale() {  # df_drop_stale GROUP KEEP: unlink destinations left by the options not chosen
  local g="$1" keep="$2" odir o src dest target rel lf
  for odir in "$DF_ROOT"/variants/"$g"/*/; do
    [ -d "$odir" ] || continue
    o="$(basename "$odir")"
    [ "$o" = "$keep" ] && continue
    lf="$(df_links_file "${odir%/}")"
    [ -n "$lf" ] || continue
    while IFS='|' read -r src dest; do
      case "$src" in ''|\#*) continue;; esac
      dest="$DF_TARGET/$dest"
      [ -L "$dest" ] || continue
      target="$(readlink "$dest")"
      case "$target" in
        "$DF_ROOT/variants/$g/$keep/"*) continue;;   # already points at the chosen option
        "$DF_ROOT/variants/$g/"*) ;;
        *) continue;;
      esac
      rel="${dest#$DF_TARGET/}"
      if [ -n "$DF_DRY" ]; then e_arrow "would unlink stale ~/$rel"; continue; fi
      mkdir -p "$DF_TARGET/.dotfiles-backup/$DF_RUN_TS/$(dirname "$rel")"
      mv "$dest" "$DF_TARGET/.dotfiles-backup/$DF_RUN_TS/$rel"
      e_arrow "unlinked stale ~/$rel (from option $o)"
      DF_BACKUPS=1
    done < "$lf"
  done
}

df_links_file() {  # df_links_file VARIANT_DIR: its .links file, inside the folder or beside it (VARIANT_DIR.links)
  if [ -f "$1/.links" ]; then echo "$1/.links"; elif [ -f "$1.links" ]; then echo "$1.links"; fi
}

df_activate_groups() {  # df_activate_groups all | GROUP...
  local i g vdir src dest s want="$*"
  for i in "${!CH_GROUP[@]}"; do
    g="${CH_GROUP[$i]}"
    if [ "$want" != all ]; then case " $want " in *" $g "*) ;; *) continue;; esac; fi
    vdir="$DF_ROOT/variants/$g/${SEL[$i]}"
    df_drop_stale "$g" "${SEL[$i]}"
    df_link "$vdir" "$DF_TARGET/.config/dotfiles/active/$g"
    lf="$(df_links_file "$vdir")"
    [ -n "$lf" ] || continue
    while IFS='|' read -r src dest; do
      case "$src" in ''|\#*) continue;; esac
      if [ "$src" = "." ]; then s="$vdir"; else s="$vdir/$src"; fi
      df_link "$s" "$DF_TARGET/$dest"
    done < "$lf"
  done
}

df_activate() { df_activate_groups all; }

df_git_existing() {  # df_git_existing KEY: value from the existing local.gitconfig, else the repo's local/ copy
  local f="$DF_TARGET/.config/dotfiles/local.gitconfig"
  [ -r "$f" ] || f="$DF_ROOT/local/local.gitconfig"
  sed -n "s/^[[:space:]]*$1 = //p" "$f" 2>/dev/null | head -n 1
}

df_load_existing() {  # current values, so a re-run keeps what is already set
  local d="$DF_TARGET/.config/dotfiles"
  [ -r "$DF_ROOT/local/settings.env" ] && . "$DF_ROOT/local/settings.env"
  [ -r "$d/settings.env" ] && . "$d/settings.env"
  case "$(df_group_val git-identity)" in
    xaostx|none)
      DF_GIT_NAME="$(df_git_existing name)"
      DF_GIT_EMAIL="$(df_git_existing email)"
      DF_GIT_SIGNKEY="$(df_git_existing signingkey)"
      DF_GIT_GHUSER="$(df_git_existing user)"
      DF_WORK_SAFE_DIR="${DF_WORK_SAFE_DIR:-$(df_git_existing directory)}"
      ;;
    *) DF_GIT_NAME= ; DF_GIT_EMAIL= ; DF_GIT_SIGNKEY= ; DF_GIT_GHUSER= ;;
  esac
}

df_ask() {  # df_ask LABEL DEFAULT: Enter keeps DEFAULT (blank is allowed)
  local ans
  if [ -n "$2" ]; then read -r -p "  $1 [$2]: " ans; else read -r -p "  $1: " ans; fi
  printf '%s' "${ans:-$2}"
}

df_ask_secret() {  # df_ask_secret LABEL CURRENT: like df_ask, for values that are kept in a secret store
  local ans
  read -r -p "  $1 (Enter keeps the current value): " ans
  printf '%s' "${ans:-$2}"
}

df_keychain_store() {  # df_keychain_store KEY LABEL: macOS Keychain item dotfiles.KEY; security prompts for the value
  local ans
  read -r -p "  Store $2 in the macOS Keychain now? [y/N]: " ans
  case "$ans" in y|Y|yes|YES) ;; *) return 0;; esac
  if ! security add-generic-password -a "$USER" -s "dotfiles.$1" -U -w; then e_error "Keychain store failed for $1"; DF_WARN=$((DF_WARN + 1)); fi
}

df_write_settings() {  # per-machine identity and work values: ~/.config/dotfiles/settings.env, mode 600
  local f="$DF_TARGET/.config/dotfiles/settings.env" k v
  [ -n "$DF_DRY" ] && return 0
  mkdir -p "$(dirname "$f")"
  (
    umask 077
    {
      echo "# Written by install.sh for this machine only. Not part of the repo. Keep mode 600."
      for k in DF_PERSONAL_ONLYKEY_IDENTITY DF_WORK_JIRA_SERVER DF_WORK_AWS_ROOT_PROFILE DF_WORK_AWS_DEV_PROFILE \
               DF_WORK_AWS_MONITORING_PROFILE DF_WORK_ECS_STAGING_CLUSTER DF_WORK_ECS_PROD_CLUSTER \
               DF_WORK_WAF_LOG_GROUP DF_WORK_NO_PROXY_DOMAIN DF_WORK_SAFE_DIR DF_WORK_JIRA_USER DF_WORK_OPS_PASS_PATH; do
        eval "v=\${$k-}"
        if [ -n "$v" ]; then printf 'export %s=%q\n' "$k" "$v"; fi
      done
    } > "$f"
  )
  chmod 600 "$f"
}

df_collect_settings() {  # identity and work values: asked when interactive, otherwise kept as they are
  local work=0
  [ -n "$DF_DRY" ] && return 0
  df_load_existing
  if [ -z "$DF_INTERACTIVE" ]; then
    e_arrow "identity and work values kept as they were (run without --yes to change them)"
    df_write_settings
    return 0
  fi
  e_header "Identity and work values (Enter keeps the current value; blank skips). Stored in ~/.config/dotfiles, not in the repo."
  case "$(df_group_val git-identity)" in
    xaostx|none)
      DF_GIT_NAME="$(df_ask 'Git name for commits' "$DF_GIT_NAME")"
      DF_GIT_EMAIL="$(df_ask 'Git email' "$DF_GIT_EMAIL")"
      DF_GIT_SIGNKEY="$(df_ask 'GPG signing key ID (optional)' "$DF_GIT_SIGNKEY")"
      DF_GIT_GHUSER="$(df_ask 'GitHub username (optional)' "$DF_GIT_GHUSER")"
      ;;
  esac
  DF_PERSONAL_ONLYKEY_IDENTITY="$(df_ask 'onlykey SSH identity (optional, usually your email)' "${DF_PERSONAL_ONLYKEY_IDENTITY:-$DF_GIT_EMAIL}")"
  case ",$PROFILES," in *",work,"*) work=1;; esac
  if [ "$work" = 1 ]; then
    e_header "Work profile values"
    DF_WORK_JIRA_SERVER="$(df_ask 'Jira server URL' "$DF_WORK_JIRA_SERVER")"
    DF_WORK_AWS_ROOT_PROFILE="$(df_ask 'AWS root profile name' "$DF_WORK_AWS_ROOT_PROFILE")"
    DF_WORK_AWS_DEV_PROFILE="$(df_ask 'AWS dev profile name' "$DF_WORK_AWS_DEV_PROFILE")"
    DF_WORK_AWS_MONITORING_PROFILE="$(df_ask 'AWS monitoring profile name' "$DF_WORK_AWS_MONITORING_PROFILE")"
    DF_WORK_ECS_STAGING_CLUSTER="$(df_ask 'ECS staging cluster name' "$DF_WORK_ECS_STAGING_CLUSTER")"
    DF_WORK_ECS_PROD_CLUSTER="$(df_ask 'ECS production cluster name' "$DF_WORK_ECS_PROD_CLUSTER")"
    DF_WORK_WAF_LOG_GROUP="$(df_ask 'WAF log group name' "$DF_WORK_WAF_LOG_GROUP")"
    DF_WORK_NO_PROXY_DOMAIN="$(df_ask 'Proxy bypass domain, e.g. example.com (macOS, optional)' "$DF_WORK_NO_PROXY_DOMAIN")"
    DF_WORK_SAFE_DIR="$(df_ask 'Git safe.directory path (optional)' "$DF_WORK_SAFE_DIR")"
    if [ "$(df_group_val secrets)" = macos-keychain ]; then
      df_keychain_store jira-user "Jira user (email)"
      df_keychain_store ops-pass-path "password-manager path for the ops alias"
      DF_WORK_JIRA_USER=; DF_WORK_OPS_PASS_PATH=
    else
      DF_WORK_JIRA_USER="$(df_ask_secret 'Jira user (email)' "$DF_WORK_JIRA_USER")"
      DF_WORK_OPS_PASS_PATH="$(df_ask_secret 'Password-manager path for the ops alias' "$DF_WORK_OPS_PASS_PATH")"
    fi
  fi
  df_write_settings
}

df_write_local_git() {  # per-machine git settings: credential helper, identity, GitHub user, safe.directory
  local f="$DF_TARGET/.config/dotfiles/local.gitconfig"
  [ -n "$DF_DRY" ] && return 0
  mkdir -p "$(dirname "$f")"
  {
    echo "# Written by install.sh for this machine only. Not part of the repo."
    if [ -n "$DF_GIT_HELPER" ]; then printf '[credential]\n\thelper = %s\n' "$DF_GIT_HELPER"; fi
    if [ -n "$DF_GIT_NAME" ] || [ -n "$DF_GIT_EMAIL" ] || [ -n "$DF_GIT_SIGNKEY" ]; then
      echo "[user]"
      [ -n "$DF_GIT_NAME" ] && printf '\tname = %s\n' "$DF_GIT_NAME"
      [ -n "$DF_GIT_EMAIL" ] && printf '\temail = %s\n' "$DF_GIT_EMAIL"
      [ -n "$DF_GIT_SIGNKEY" ] && printf '\tsigningkey = %s\n' "$DF_GIT_SIGNKEY"
    fi
    if [ -n "$DF_GIT_GHUSER" ]; then printf '[github]\n\tuser = %s\n' "$DF_GIT_GHUSER"; fi
    if [ -n "$DF_WORK_SAFE_DIR" ]; then printf '[safe]\n\tdirectory = %s\n' "$DF_WORK_SAFE_DIR"; fi
  } > "$f"
}

df_git_ssh() {
  local key ans gen
  key="$DF_TARGET/.ssh/id_ed25519"
  read -r -p "  SSH key path [$key]: " ans; key="${ans:-$key}"
  if [ ! -f "$key" ]; then
    read -r -p "  No key at $key. Generate an ed25519 key now? [Y/n]: " gen
    case "$gen" in n|N|no|NO) e_error "no SSH key; skipping SSH setup"; return 1;; esac
    mkdir -p "$(dirname "$key")"
    ssh-keygen -t ed25519 -f "$key" -C "${DF_GIT_EMAIL:-$USER@$(hostname)}" || return 1
  fi
  if command -v ssh-add >/dev/null 2>&1; then
    [ -n "$SSH_AUTH_SOCK" ] || eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$key" || e_error "ssh-add failed; the key is not loaded into the agent"
  fi
  e_header "Public key (add it to GitHub under Settings > SSH and GPG keys):"
  cat "$key.pub"
  read -r -p "  Press Enter once the key is added to your git host..." _
  DF_GIT_MODE=ssh
  e_success "SSH key ready: $key"
}

df_git_token() {
  local user tok helper
  read -r -p "  Git username: " user
  read -r -s -p "  Access token (hidden): " tok; echo
  if [ "$(df_os)" = darwin ] && command -v git-credential-osxkeychain >/dev/null 2>&1; then
    helper=osxkeychain
  elif command -v git-credential-libsecret >/dev/null 2>&1; then
    helper=libsecret
  else
    helper=store
    e_error "no OS credential store found: the token will be saved in plain text in ~/.git-credentials (mode 600)"
  fi
  printf 'protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n' "$user" "$tok" \
    | git -c "credential.helper=$helper" credential approve || { e_error "could not store the token"; return 1; }
  chmod 600 "$DF_TARGET/.git-credentials" 2>/dev/null
  tok=""
  DF_GIT_HELPER="$helper"
  DF_GIT_MODE=token
  e_success "token stored via $helper for github.com"
}

df_git_access() {
  local choice
  DF_GIT_MODE=; DF_GIT_HELPER=
  if [ -n "$DF_DRY" ]; then e_arrow "would set up git access (SSH key or HTTPS token) and write local.gitconfig"; return 0; fi
  if [ -n "$DF_INTERACTIVE" ]; then
    e_header "Git access"
    echo "  1) SSH key (recommended)"
    echo "  2) HTTPS access token"
    echo "  3) skip for now"
    read -r -p "  choose [3]: " choice
    case "${choice:-3}" in
      1) df_git_ssh || DF_WARN=$((DF_WARN + 1));;
      2) df_git_token || DF_WARN=$((DF_WARN + 1));;
      *) e_arrow "git access skipped";;
    esac
  else
    e_arrow "git access: skipped in non-interactive mode (run without --yes to set an SSH key or token)"
  fi
  df_write_local_git
}

df_vim_submodule() {
  [ "$(df_group_val vim)" = submodule ] || return 0
  if [ -n "$DF_DRY" ]; then
    e_arrow "would run: git submodule update --init variants/vim/submodule"
    return 0
  fi
  # token mode fetches over https; ssh mode uses the SSH URL in .gitmodules
  local rewrite=
  [ "$DF_GIT_MODE" = token ] && rewrite='url.https://github.com/.insteadOf=git@github.com:'
  if ! git ${rewrite:+-c "$rewrite"} -C "$DF_ROOT" submodule update --init variants/vim/submodule; then
    e_error "could not fetch the vim submodule (needs SSH access to XaosTX/dotvim)"
    DF_WARN=$((DF_WARN + 1))
  fi
}


dotfiles_main() {
  # bash-only syntax below: when sourced from zsh, hand the whole run to bash
  if [ -n "$ZSH_VERSION" ]; then bash "$DF_ROOT/install.sh" "$@"; return $?; fi
  local yes= list= i
  DF_DRY=; DF_WARN=0; DF_BACKUPS=; PROFILES_CLI=; CLI_CHOICES=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -y|--yes) yes=1;;
      --dry-run) DF_DRY=1;;
      --list-choices) list=1;;
      --profiles) PROFILES_CLI="$2"; shift;;
      --choose) CLI_CHOICES+=("$2"); shift;;
      --home) DF_TARGET="${2%/}"; shift;;
      -h|--help) df_usage; return 0;;
      *) e_error "unknown option: $1"; df_usage >&2; return 2;;
    esac
    shift
  done

  df_load_choices || return 1
  if [ -n "$list" ]; then
    for i in "${!CH_GROUP[@]}"; do
      printf '%s (default %s)\n  options: %s\n  %s\n' "${CH_GROUP[$i]}" "${CH_DEFAULT[$i]}" "${CH_OPTS[$i]}" "${CH_DESC[$i]}"
    done
    return 0
  fi

  df_resolve || return $?
  df_resolve_profiles
  DF_INTERACTIVE=
  if [ -z "$yes" ] && [ -t 0 ] && [ -t 1 ]; then df_interactive || return 1; DF_INTERACTIVE=1; fi
  df_check_deps || return $?
  df_plan
  df_collect_settings
  df_write_state
  # git first: config, identity and ignore list, then access (so the submodule can be fetched)
  df_link_home ".gitconfig"
  df_activate_groups git-identity git-extras gitignore
  df_git_access
  df_tool_dirs
  df_link_home
  df_activate
  df_vim_submodule

  [ -n "$DF_BACKUPS" ] && e_arrow "previous files moved to $DF_TARGET/.dotfiles-backup/$DF_RUN_TS"
  if [ "$DF_WARN" -gt 0 ]; then
    e_error "finished with $DF_WARN warning(s); see above"
    return 1
  fi
  e_success "done. Open a new shell, or: source ~/.config/dotfiles/env"
  return 0
}

if [ -n "${BASH_VERSION:-}" ] && [ "${BASH_SOURCE[0]}" = "$0" ]; then   # run only when executed, never when sourced
  dotfiles_main "$@"
  exit $?
fi
