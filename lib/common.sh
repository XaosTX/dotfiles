#!/usr/bin/env bash
# Shared shell helpers, extracted from the codeangler dotfiles driver (MIT, see licenses/).
# Sourced by install.sh and by shell/lib/00_dotfiles.sh. Defines no aliases.

###########################################
# GENERAL PURPOSE EXPORTED VARS / FUNCTIONS
###########################################

# Where the magic happens.
export DOTFILES="${DOTFILES:-$DF_ROOT}"

# Logging stuff.
function e_header()   { echo -e "\n\033[1m$@\033[0m"; }
function e_success()  { echo -e " \033[1;32m✔\033[0m  $@"; }
function e_error()    { echo -e " \033[1;31m✖\033[0m  $@"; }
function e_arrow()    { echo -e " \033[1;34m➜\033[0m  $@"; }

# For testing.
function assert() {
  local success modes equals actual expected
  modes=(e_error e_success); equals=("!=" "=="); expected="$1"; shift
  actual="$("$@")"
  [[ "$actual" == "$expected" ]] && success=1 || success=0
  ${modes[success]} "\"$actual\" ${equals[success]} \"$expected\""
}

# OS detection
function is_osx() {
  [[ "$OSTYPE" =~ ^darwin ]] || return 1
}
function is_ubuntu() {
  ( . /etc/os-release 2>/dev/null; case " $ID $ID_LIKE " in *" ubuntu "*) exit 0;; *) exit 1;; esac ) || return 1
}
function get_os() {
  for os in osx ubuntu; do
    is_$os; [[ $? == ${1:-0} ]] && echo $os
  done
}

function get_install_type() {
  echo $install_type
}

# Remove an entry from $PATH
# Based on http://stackoverflow.com/a/2108540/142339
function path_remove() {
  local arg path
  path=":$PATH:"
  for arg in "$@"; do path="${path//:$arg:/:}"; done
  path="${path%:}"
  path="${path#:}"
  echo "$path"
}

function select_menu() {
  PS3='Selection: '
  select opt in "${!1}"; do echo $opt; break; done
}

# Display a fancy multi-select menu.
# Inspired by http://serverfault.com/a/298312
function prompt_menu() {
  local exitcode prompt choices nums i n
  exitcode=0
  if [[ "$2" ]]; then
    _prompt_menu_draws "$1"
    read -t $2 -n 1 -sp "To edit this list, press any key within $2 seconds. "
    exitcode=$?
    echo ""
  fi 1>&2
  if [[ "$exitcode" == 0 ]]; then
    prompt="Toggle options (Separate options with spaces, ENTER when done): "
    while _prompt_menu_draws "$1" 1 && read -rp "$prompt" nums && [[ "$nums" ]]; do
      _prompt_menu_adds $nums
    done
  fi 1>&2
  _prompt_menu_adds
}

function _prompt_menu_iter() {
  local i sel state
  local fn=$1; shift
  for i in "${!menu_options[@]}"; do
    state=0
    for sel in "${menu_selects[@]}"; do
      [[ "$sel" == "${menu_options[i]}" ]] && state=1 && break
    done
    $fn $state $i "$@"
  done
}

function _prompt_menu_draws() {
  e_header "$1"
  _prompt_menu_iter _prompt_menu_draw "$2"
}

function _prompt_menu_draw() {
  local modes=(error success)
  if [[ "$3" ]]; then
    e_${modes[$1]} "$(printf "%2d) %s\n" $(($2+1)) "${menu_options[$2]}")"
  else
    e_${modes[$1]} "${menu_options[$2]}"
  fi
}

function _prompt_menu_adds() {
  _prompt_menu_result=()
  _prompt_menu_iter _prompt_menu_add "$@"
  menu_selects=("${_prompt_menu_result[@]}")
}

function _prompt_menu_add() {
  local state i n keep match
  state=$1; shift
  i=$1; shift
  for n in "$@"; do
    if [[ $n =~ ^[0-9]+$ ]] && (( n-1 == i )); then
      match=1; [[ "$state" == 0 ]] && keep=1
    fi
  done
  [[ ! "$match" && "$state" == 1 || "$keep" ]] || return
  _prompt_menu_result=("${_prompt_menu_result[@]}" "${menu_options[i]}")
}

# Given strings containing space-delimited words A and B, "setdiff A B" will
# return all words in A that do not exist in B. Arrays in bash are insane
# (and not in a good way).
# From http://stackoverflow.com/a/1617303/142339
function setdiff() {
  local debug skip a b
  if [[ "$1" == 1 ]]; then debug=1; shift; fi
  if [[ "$1" ]]; then
    local setdiffA setdiffB setdiffC
    setdiffA=($1); setdiffB=($2)
  fi
  setdiffC=()
  for a in "${setdiffA[@]}"; do
    skip=
    for b in "${setdiffB[@]}"; do
      [[ "$a" == "$b" ]] && skip=1 && break
    done
    [[ "$skip" ]] || setdiffC=("${setdiffC[@]}" "$a")
  done
  [[ "$debug" ]] && for a in setdiffA setdiffB setdiffC; do
    echo "$a ($(eval echo "\${#$a[*]}")) $(eval echo "\${$a[*]}")" 1>&2
  done
  [[ "$1" ]] && echo "${setdiffC[@]}"
}

