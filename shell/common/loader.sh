# Shell-neutral loader, sourced by both bash and zsh after DF_ROOT and DF_ACTIVE are set.
. "$DF_ROOT/shell/common/environment.sh"

# utility scripts from bin/ (both shells; was zsh-only). Once only, even when sourced twice.
case ":$PATH:" in *":$DF_ROOT/bin:"*) ;; *) PATH="$DF_ROOT/bin:$PATH"; export PATH;; esac
. "$DF_ROOT/shell/common/commonrc.sh"

# per-machine identity and work values (written by bootstrap.sh; not in the repo), then secret lookup
DF_STATE="${DF_STATE:-$HOME/.config/dotfiles}"
[ -r "$DF_STATE/settings.env" ] && . "$DF_STATE/settings.env"
. "$DF_ROOT/shell/common/secrets.sh"

# codeangler helpers (functions, menus, OS checks) and their small alias sets
for f in "$DF_ROOT"/shell/lib/*.sh; do [ -f "$f" ] && . "$f"; done

# choice-driven aliases: the active variant decides
for v in ls-aliases editor gr-alias; do
  [ -f "$DF_ACTIVE/$v/aliases.sh" ] && . "$DF_ACTIVE/$v/aliases.sh"
done

# per-topic aliases (always on)
# private per-machine shell files (local/shell/*.sh; not in the repo)
for f in "$DF_ROOT"/local/shell/*.sh; do [ -f "$f" ] && . "$f"; done

# OS-specific aliases: shell/os/$DF_OS/*.sh
for f in "$DF_ROOT"/shell/os/"$DF_OS"/*.sh; do [ -f "$f" ] && . "$f"; done

# ls function: after the choice files, which set DF_LS_PREFER
. "$DF_ROOT/shell/common/ls.sh"

for f in "$DF_ROOT"/shell/aliases.d/*.sh; do [ -f "$f" ] && . "$f"; done

# profile aliases: only profiles listed in DF_PROFILES
for pdir in "$DF_ROOT"/shell/profiles/*; do
  p="${pdir##*/}"
  case ",$DF_PROFILES," in *",$p,"*) ;; *) continue;; esac
  for f in "$pdir"/aliases.d/*.sh; do [ -f "$f" ] && . "$f"; done
done
