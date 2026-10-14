# =============================================================================
# Jira CLI Aliases and Functions for SRE Workflows
# Source: https://github.com/ankitpokhrel/jira-cli
# 
# Place in aliases.d directory to be sourced by .bashrc/.zshrc
#
# Prerequisites:
#   - jira-cli installed and configured (jira init)
#   - JIRA_API_TOKEN in keychain/password manager (auto-detected below)
#   - fzf (optional, for enhanced selection)
# =============================================================================

# -----------------------------------------------------------------------------
# Suppress Node.js deprecation warnings
# -----------------------------------------------------------------------------
export NODE_OPTIONS="--no-deprecation"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
export JIRA_USER="$(df_secret jira-user)"
export JIRA_SERVER="${DF_WORK_JIRA_SERVER:-}"

# -----------------------------------------------------------------------------
# JIRA_API_TOKEN retrieval from secure storage
# Priority: 1Password > Bitwarden > macOS Keychain > Linux secret-tool > .netrc
# -----------------------------------------------------------------------------
_jira_get_token() {
    local token=""
    
    # 1Password CLI (op)
    if [[ -z "$token" ]] && command -v op &> /dev/null; then
        # Try common item names - adjust "Jira" to match your 1Password item
        token=$(op read "op://Private/Jira/api-token" 2>/dev/null) ||
        token=$(op read "op://Private/Jira API Token/credential" 2>/dev/null) ||
        token=$(op item get "Jira" --fields api-token 2>/dev/null) ||
        token=$(op item get "Jira" --fields credential 2>/dev/null) ||
        token=$(op item get "Jira" --fields password 2>/dev/null)
    fi
    
    # Bitwarden CLI (bw)
    if [[ -z "$token" ]] && command -v bw &> /dev/null; then
        # Ensure session is unlocked
        if bw status 2>/dev/null | grep -q '"status":"unlocked"'; then
            token=$(bw get password "Jira API Token" 2>/dev/null) ||
            token=$(bw get password "jira-api-token" 2>/dev/null) ||
            token=$(bw get password "Jira" 2>/dev/null)
        fi
    fi
    
    # macOS Keychain
    if [[ -z "$token" ]] && [[ "$(uname)" == "Darwin" ]]; then
        token=$(security find-generic-password -s "jira-cli" -w 2>/dev/null) ||
        token=$(security find-generic-password -s "jira" -w 2>/dev/null) ||
        token=$(security find-generic-password -s "jira-api-token" -w 2>/dev/null)
    fi
    
    # Linux secret-tool (GNOME Keyring / libsecret)
    if [[ -z "$token" ]] && command -v secret-tool &> /dev/null; then
        token=$(secret-tool lookup service jira-cli 2>/dev/null) ||
        token=$(secret-tool lookup service jira 2>/dev/null)
    fi
    
    # pass (password-store)
    if [[ -z "$token" ]] && command -v pass &> /dev/null; then
        token=$(pass show jira/api-token 2>/dev/null) ||
        token=$(pass show jira-api-token 2>/dev/null) ||
        token=$(pass show jira 2>/dev/null)
    fi
    
    # .netrc fallback (jira-cli reads this natively, but we can use it too)
    if [[ -z "$token" ]] && [[ -f "$HOME/.netrc" ]]; then
        # Extract password for the configured server
        local server_host=$(echo "$JIRA_SERVER" | sed 's|https\?://||' | sed 's|/.*||')
        token=$(awk -v host="$server_host" '
            $1 == "machine" && $2 == host { found=1 }
            found && $1 == "password" { print $2; exit }
        ' "$HOME/.netrc" 2>/dev/null)
    fi
    
    echo "$token"
}

# Only fetch token if not already set
if [[ -z "$JIRA_API_TOKEN" ]]; then
    _fetched_token=$(_jira_get_token)
    if [[ -n "$_fetched_token" ]]; then
        export JIRA_API_TOKEN="$_fetched_token"
    fi
    unset _fetched_token
fi

# Warn if no token found (but don't block - jira-cli may use keychain directly)
if [[ -z "$JIRA_API_TOKEN" ]]; then
    echo "Warning: JIRA_API_TOKEN not found. Store it in one of:" >&2
    echo "  - 1Password: item 'Jira' with field 'api-token'" >&2
    echo "  - Bitwarden: item 'Jira API Token'" >&2
    echo "  - macOS Keychain: security add-generic-password -s 'jira-cli' -a '$JIRA_USER' -w 'TOKEN'" >&2
    echo "  - Linux secret-tool: secret-tool store --label='jira-cli' service jira-cli account '$JIRA_USER'" >&2
    echo "  - pass: pass insert jira/api-token" >&2
    echo "  - ~/.netrc: machine ${JIRA_SERVER#https://} login $JIRA_USER password TOKEN" >&2
fi
export JIRA_SRE_PROJECT="${JIRA_SRE_PROJECT:-PLFM}"
export JIRA_INCIDENT_LABEL="${JIRA_INCIDENT_LABEL:-incident}"
export JIRA_ONCALL_LABEL="${JIRA_ONCALL_LABEL:-oncall}"
export JIRA_POSTMORTEM_LABEL="${JIRA_POSTMORTEM_LABEL:-postmortem}"
export JIRA_TOIL_LABEL="${JIRA_TOIL_LABEL:-toil}"

# -----------------------------------------------------------------------------
# Core Aliases - Basic Operations
# -----------------------------------------------------------------------------
alias jme='jira me'
alias jwho='jira me'
alias jo='jira open'
alias jv='jira issue view'
alias jvc='jira issue view --comments 10'

# -----------------------------------------------------------------------------
# Issue Listing - My Issues
# -----------------------------------------------------------------------------
alias jmy='jira issue list -a$(jira me) -s"In Progress"'
alias jm='jira issue list -a$(jira me)'
alias jmr='jira issue list -r$(jira me)'
alias jmw='jira issue list -w'
alias jmopen='jira issue list -a$(jira me) -s~Done -s~Closed'
alias jmtoday='jira issue list -a$(jira me) --updated today'

# -----------------------------------------------------------------------------
# Issue Listing - Recent and History
# -----------------------------------------------------------------------------
alias jh='jira issue list --history'
alias jrecent='jira issue list --created -7d'
alias jupdated='jira issue list --updated -24h'

# -----------------------------------------------------------------------------
# Issue Listing - Output Formats (for scripting)
# -----------------------------------------------------------------------------
alias jlp='jira issue list --plain'
alias jlpn='jira issue list --plain --no-headers'
alias jcsv='jira issue list --csv'
alias jraw='jira issue list --raw'

# -----------------------------------------------------------------------------
# Issue Listing - By Status
# -----------------------------------------------------------------------------
alias jtodo='jira issue list -s"To Do"'
alias jinprog='jira issue list -s"In Progress"'
alias jdone='jira issue list -sDone --created -7d'
alias jblocked='jira issue list -sBlocked'
alias jreview='jira issue list -s"In Review"'

# -----------------------------------------------------------------------------
# Issue Listing - By Priority
# -----------------------------------------------------------------------------
alias jcrit='jira issue list -yCritical'
alias jhigh='jira issue list -yHigh'
alias jurgent='jira issue list -yHighest -s~Done'

# -----------------------------------------------------------------------------
# Issue Listing - By Type
# -----------------------------------------------------------------------------
alias jbugs='jira issue list -tBug'
alias jtasks='jira issue list -tTask'
alias jstories='jira issue list -tStory'
alias jepics='jira epic list'

# -----------------------------------------------------------------------------
# Issue Listing - Unassigned
# -----------------------------------------------------------------------------
alias junassigned='jira issue list -ax'
alias jorphans='jira issue list -ax -s~Done --created-before -30d'

# -----------------------------------------------------------------------------
# Board and Backlog Views (PLFM Project)
# -----------------------------------------------------------------------------
alias jboard='jira sprint list -p$JIRA_SRE_PROJECT'
alias jboardm='jira sprint list -p$JIRA_SRE_PROJECT -a$(jira me)'
alias jboardt='jira sprint list -p$JIRA_SRE_PROJECT --table'
alias jboardopen='jira sprint list -p$JIRA_SRE_PROJECT -s~Done'

alias jbacklog='jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done"'
alias jbacklogm='jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done AND assignee = currentUser()"'
alias jbacklogu='jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done AND assignee is EMPTY"'
alias jbackloghigh='jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done AND priority in (High, Highest, Critical)"'
alias jbacklogbugs='jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done AND type = Bug"'
alias jbacklogold='jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done AND created < -30d"'

alias jplfm='jira issue list -p$JIRA_SRE_PROJECT'
alias jplfmopen='jira issue list -p$JIRA_SRE_PROJECT -s~Done -s~Closed'
alias jplfmm='jira issue list -p$JIRA_SRE_PROJECT -a$(jira me)'

# -----------------------------------------------------------------------------
# Sprint Management
# -----------------------------------------------------------------------------
alias js='jira sprint list'
alias jst='jira sprint list --table'
alias jsc='jira sprint list --current'
alias jscm='jira sprint list --current -a$(jira me)'
alias jsp='jira sprint list --prev'
alias jsn='jira sprint list --next'
alias jsactive='jira sprint list --state active'
alias jsfuture='jira sprint list --state future'
alias jscurg='jira sprint list --current -yHigh,Highest'
alias jscblk='jira sprint list --current -sBlocked'
alias jscopen='jira sprint list --current -s~Done'

# -----------------------------------------------------------------------------
# Issue Creation
# -----------------------------------------------------------------------------
alias jc='jira issue create'
alias jcni='jira issue create --no-input'
alias jcbug='jira issue create -tBug'
alias jctask='jira issue create -tTask'
alias jcstory='jira issue create -tStory'
alias jcepic='jira epic create'
alias jcplfm='jira issue create -p$JIRA_SRE_PROJECT'
alias jcplfmbug='jira issue create -p$JIRA_SRE_PROJECT -tBug'
alias jcplfmtask='jira issue create -p$JIRA_SRE_PROJECT -tTask'

# -----------------------------------------------------------------------------
# Issue Modification
# -----------------------------------------------------------------------------
alias je='jira issue edit'
alias ja='jira issue assign'
alias jam='jira issue assign $(jira me)'
alias jmove='jira issue move'
alias jlink='jira issue link'
alias jclone='jira issue clone'
alias jdel='jira issue delete'
alias jcomm='jira issue comment add'
alias jcommls='jira issue comment list'
alias jwl='jira issue worklog list'
alias jwla='jira issue worklog add'

# -----------------------------------------------------------------------------
# SRE-Specific Workflows
# -----------------------------------------------------------------------------
alias jinc='jira issue list -l${JIRA_INCIDENT_LABEL}'
alias jincopen='jira issue list -l${JIRA_INCIDENT_LABEL} -s~Done -s~Closed'
alias jinctoday='jira issue list -l${JIRA_INCIDENT_LABEL} --created today'
alias jincweek='jira issue list -l${JIRA_INCIDENT_LABEL} --created week'
alias jinccrit='jira issue list -l${JIRA_INCIDENT_LABEL} -yCritical,Highest'
alias joncall='jira issue list -l${JIRA_ONCALL_LABEL} -a$(jira me)'
alias joncallopen='jira issue list -l${JIRA_ONCALL_LABEL} -s~Done'
alias jpm='jira issue list -l${JIRA_POSTMORTEM_LABEL}'
alias jpmopen='jira issue list -l${JIRA_POSTMORTEM_LABEL} -s~Done'
alias jpmpending='jira issue list -l${JIRA_POSTMORTEM_LABEL} -s"To Do"'
alias jtoil='jira issue list -l${JIRA_TOIL_LABEL}'
alias jtoilopen='jira issue list -l${JIRA_TOIL_LABEL} -s~Done'

# -----------------------------------------------------------------------------
# Board and Project
# -----------------------------------------------------------------------------
alias jb='jira board list'
alias jp='jira project list'

# =============================================================================
# Functions
# =============================================================================

# -----------------------------------------------------------------------------
# Board and Backlog Filters
# -----------------------------------------------------------------------------
jbackloguser() {
    local user="${1:-}"
    if [[ -z "$user" ]]; then
        echo "Usage: jbackloguser 'User Name'"
        echo "       jbackloguser \$(jira me)"
        return 1
    fi
    jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done AND assignee = '$user'"
}

jboardfilter() {
    local filters=""
    local sprint="--current"
    local columns=""
    
    if [[ $# -eq 0 ]]; then
        cat <<EOF
Usage: jboardfilter [options]
  -u, --user USER      Filter by assignee
  -r, --reporter USER  Filter by reporter
  -s, --status STATUS  Filter by status
  -p, --priority PRI   Filter by priority
  -l, --label LABEL    Filter by label
  -t, --type TYPE      Filter by issue type
  -c, --columns COLS   Columns to display (comma-separated)
  --prev               Previous sprint
  --next               Next sprint
  --plain              Plain output (for scripting)

Columns: TYPE,KEY,SUMMARY,STATUS,ASSIGNEE,REPORTER,PRIORITY,RESOLUTION,CREATED,UPDATED,LABELS

Examples:
  jboardfilter -u "\$(jira me)" -p High
  jboardfilter -s "In Progress" -r "\$(jira me)"
  jboardfilter --prev -c key,status,assignee,summary
EOF
        return 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--user)     filters="$filters -a\"$2\""; shift 2 ;;
            -r|--reporter) filters="$filters -r\"$2\""; shift 2 ;;
            -s|--status)   filters="$filters -s\"$2\""; shift 2 ;;
            -p|--priority) filters="$filters -y\"$2\""; shift 2 ;;
            -l|--label)    filters="$filters -l\"$2\""; shift 2 ;;
            -t|--type)     filters="$filters -t\"$2\""; shift 2 ;;
            -c|--columns)  columns="--columns $2"; shift 2 ;;
            --plain)       filters="$filters --plain"; shift ;;
            --prev)        sprint="--prev"; shift ;;
            --next)        sprint="--next"; shift ;;
            --current)     sprint="--current"; shift ;;
            *) echo "Unknown option: $1"; shift ;;
        esac
    done
    eval "jira sprint list -p$JIRA_SRE_PROJECT $sprint $filters $columns"
}

jbacklogfilter() {
    local jql="sprint is EMPTY AND status != Done"
    local columns=""
    local extra_flags=""
    
    if [[ $# -eq 0 ]]; then
        cat <<EOF
Usage: jbacklogfilter [options]
  -u, --user USER      Filter by assignee (use 'none' for unassigned)
  -r, --reporter USER  Filter by reporter
  -p, --priority PRI   Filter by priority (e.g., High,Critical)
  -l, --label LABEL    Filter by label
  -t, --type TYPE      Filter by issue type
  -o, --older DAYS     Created more than N days ago
  -n, --newer DAYS     Created within last N days
  -c, --columns COLS   Columns to display (comma-separated)
  --plain              Plain output (for scripting)

Columns: TYPE,KEY,SUMMARY,STATUS,ASSIGNEE,REPORTER,PRIORITY,RESOLUTION,CREATED,UPDATED,LABELS

Examples:
  jbacklogfilter -u "\$(jira me)" -p High
  jbacklogfilter -r "\$(jira me)" -c key,status,summary
  jbacklogfilter -u none -o 30 --plain
  jbacklogfilter -t Bug -l urgent
EOF
        return 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--user)
                if [[ "$2" == "none" ]]; then
                    jql="$jql AND assignee is EMPTY"
                else
                    jql="$jql AND assignee = '$2'"
                fi
                shift 2 ;;
            -r|--reporter)  jql="$jql AND reporter = '$2'"; shift 2 ;;
            -p|--priority)  jql="$jql AND priority in ($2)"; shift 2 ;;
            -l|--label)     jql="$jql AND labels = '$2'"; shift 2 ;;
            -t|--type)      jql="$jql AND type = '$2'"; shift 2 ;;
            -o|--older)     jql="$jql AND created < -${2}d"; shift 2 ;;
            -n|--newer)     jql="$jql AND created >= -${2}d"; shift 2 ;;
            -c|--columns)   columns="--columns $2"; shift 2 ;;
            --plain)        extra_flags="$extra_flags --plain"; shift ;;
            *) echo "Unknown option: $1"; shift ;;
        esac
    done
    
    eval "jira issue list -p$JIRA_SRE_PROJECT -q \"$jql\" $columns $extra_flags"
}

# -----------------------------------------------------------------------------
# Search Functions
# -----------------------------------------------------------------------------
jvclip() {
    local key
    if command -v pbpaste &> /dev/null; then
        key=$(pbpaste | grep -oE '[A-Z]+-[0-9]+' | head -1)
    elif command -v xclip &> /dev/null; then
        key=$(xclip -selection clipboard -o | grep -oE '[A-Z]+-[0-9]+' | head -1)
    fi
    if [[ -n "$key" ]]; then
        jira issue view "$key"
    else
        echo "No issue key found in clipboard"
    fi
}

jjql() {
    if [[ -z "$1" ]]; then
        echo "Usage: jjql 'JQL query'"
        return 1
    fi
    jira issue list -q "$1"
}

jsearch() {
    if [[ -z "$1" ]]; then
        echo "Usage: jsearch 'search text'"
        return 1
    fi
    jira issue list -q "summary ~ \"$1\" OR description ~ \"$1\""
}

jsearchplfm() {
    if [[ -z "$1" ]]; then
        echo "Usage: jsearchplfm 'search text'"
        return 1
    fi
    jira issue list -p$JIRA_SRE_PROJECT -q "summary ~ \"$1\" OR description ~ \"$1\""
}

# -----------------------------------------------------------------------------
# Workflow Functions
# -----------------------------------------------------------------------------
jtakeover() {
    if [[ -z "$1" ]]; then
        echo "Usage: jtakeover ISSUE-KEY"
        return 1
    fi
    jira issue assign "$1" "$(jira me)"
    echo "Assigned $1 to $(jira me)"
}

jstart() {
    if [[ -z "$1" ]]; then
        echo "Usage: jstart ISSUE-KEY [comment]"
        return 1
    fi
    local key="$1"
    local comment="${2:-Starting work on this issue}"
    jira issue assign "$key" "$(jira me)"
    jira issue move "$key" "In Progress" --comment "$comment"
    echo "Started working on $key"
}

jfinish() {
    if [[ -z "$1" ]]; then
        echo "Usage: jfinish ISSUE-KEY [comment]"
        return 1
    fi
    local key="$1"
    local comment="${2:-Completed}"
    jira issue move "$key" "Done" --comment "$comment"
    echo "Completed $key"
}

jblock() {
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "Usage: jblock ISSUE-KEY 'blocking reason'"
        return 1
    fi
    jira issue move "$1" "Blocked" --comment "Blocked: $2"
    echo "Blocked $1"
}

jnote() {
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "Usage: jnote ISSUE-KEY 'comment text'"
        return 1
    fi
    jira issue comment add "$1" --body "$2"
}

jlog() {
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "Usage: jlog ISSUE-KEY TIME [comment]"
        echo "Example: jlog PLFM-123 2h 'Investigating issue'"
        return 1
    fi
    local comment="${3:-}"
    if [[ -n "$comment" ]]; then
        jira issue worklog add "$1" "$2" --comment "$comment"
    else
        jira issue worklog add "$1" "$2"
    fi
}

# -----------------------------------------------------------------------------
# Incident Management
# -----------------------------------------------------------------------------
jincnew() {
    local summary="$1"
    local priority="${2:-High}"
    if [[ -z "$summary" ]]; then
        echo "Usage: jincnew 'Incident summary' [priority]"
        echo "Priority: Lowest, Low, Medium, High, Highest, Critical"
        return 1
    fi
    jira issue create -p"$JIRA_SRE_PROJECT" -tBug -s"[INCIDENT] $summary" \
        -y"$priority" -l"$JIRA_INCIDENT_LABEL" --no-input
}

jp1() {
    local summary="$1"
    if [[ -z "$summary" ]]; then
        echo "Usage: jp1 'Critical incident summary'"
        return 1
    fi
    jira issue create -p"$JIRA_SRE_PROJECT" -tBug -s"[P1] $summary" \
        -yCritical -l"$JIRA_INCIDENT_LABEL" -lp1 -lsev1 --no-input
}

jpmcreate() {
    local incident_key="$1"
    if [[ -z "$incident_key" ]]; then
        echo "Usage: jpmcreate INCIDENT-KEY"
        return 1
    fi
    jira issue create -p"$JIRA_SRE_PROJECT" -tTask \
        -s"[Postmortem] $incident_key" \
        -l"$JIRA_POSTMORTEM_LABEL" \
        -b"Postmortem for incident $incident_key

## Timeline

## Root Cause

## Action Items
" \
        --no-input
    echo "Link to incident: jlink NEW-KEY $incident_key 'relates to'"
}

# -----------------------------------------------------------------------------
# Reporting Functions
# -----------------------------------------------------------------------------
jcount() {
    echo "=== Issue Count by Status ==="
    echo -n "To Do: "; jira issue list -s"To Do" --plain --no-headers 2>/dev/null | wc -l
    echo -n "In Progress: "; jira issue list -s"In Progress" --plain --no-headers 2>/dev/null | wc -l
    echo -n "Done (this week): "; jira issue list -sDone --created week --plain --no-headers 2>/dev/null | wc -l
    echo -n "Blocked: "; jira issue list -sBlocked --plain --no-headers 2>/dev/null | wc -l
}

jcountplfm() {
    echo "=== PLFM Issue Count ==="
    echo -n "To Do: "; jira issue list -p$JIRA_SRE_PROJECT -s"To Do" --plain --no-headers 2>/dev/null | wc -l
    echo -n "In Progress: "; jira issue list -p$JIRA_SRE_PROJECT -s"In Progress" --plain --no-headers 2>/dev/null | wc -l
    echo -n "Done (this week): "; jira issue list -p$JIRA_SRE_PROJECT -sDone --created week --plain --no-headers 2>/dev/null | wc -l
    echo -n "Backlog: "; jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done" --plain --no-headers 2>/dev/null | wc -l
}

jmyload() {
    local me=$(jira me)
    echo "=== Workload for $me ==="
    echo -n "Assigned (open): "; jira issue list -a"$me" -s~Done -s~Closed --plain --no-headers 2>/dev/null | wc -l
    echo -n "High priority: "; jira issue list -a"$me" -yHigh,Highest,Critical -s~Done --plain --no-headers 2>/dev/null | wc -l
    echo -n "In current sprint: "; jira sprint list --current -a"$me" --plain --no-headers 2>/dev/null | wc -l
    echo -n "In backlog: "; jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done AND assignee = currentUser()" --plain --no-headers 2>/dev/null | wc -l
    echo ""
    echo "=== My Open Issues ==="
    jira issue list -a"$me" -s~Done -s~Closed --plain --columns key,status,priority,summary
}

jsprintprog() {
    echo "=== Current Sprint Progress ==="
    local total=$(jira sprint list --current --plain --no-headers 2>/dev/null | wc -l)
    local done=$(jira sprint list --current -sDone --plain --no-headers 2>/dev/null | wc -l)
    local inprog=$(jira sprint list --current -s"In Progress" --plain --no-headers 2>/dev/null | wc -l)
    local todo=$(jira sprint list --current -s"To Do" --plain --no-headers 2>/dev/null | wc -l)
    echo "Total: $total | Done: $done | In Progress: $inprog | To Do: $todo"
    if [[ $total -gt 0 ]]; then
        echo "Completion: $((done * 100 / total))%"
    fi
}

jstale() {
    local days="${1:-30}"
    echo "=== Issues Not Updated in $days+ Days ==="
    jira issue list -s~Done -s~Closed --updated-before "-${days}d" \
        --plain --columns key,status,assignee,updated,summary
}

jaging() {
    echo "=== Open Issues by Age ==="
    echo -n ">90 days: "; jira issue list -s~Done -s~Closed --created-before -90d --plain --no-headers 2>/dev/null | wc -l
    echo -n ">60 days: "; jira issue list -s~Done -s~Closed --created-before -60d --plain --no-headers 2>/dev/null | wc -l
    echo -n ">30 days: "; jira issue list -s~Done -s~Closed --created-before -30d --plain --no-headers 2>/dev/null | wc -l
    echo -n ">7 days: "; jira issue list -s~Done -s~Closed --created-before -7d --plain --no-headers 2>/dev/null | wc -l
}

jbackloghealth() {
    echo "=== PLFM Backlog Health ==="
    echo -n "Total: "; jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done" --plain --no-headers 2>/dev/null | wc -l
    echo -n "Unassigned: "; jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done AND assignee is EMPTY" --plain --no-headers 2>/dev/null | wc -l
    echo -n "High priority: "; jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done AND priority in (High, Highest, Critical)" --plain --no-headers 2>/dev/null | wc -l
    echo -n ">30 days old: "; jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done AND created < -30d" --plain --no-headers 2>/dev/null | wc -l
    echo -n ">90 days old: "; jira issue list -p$JIRA_SRE_PROJECT -q "sprint is EMPTY AND status != Done AND created < -90d" --plain --no-headers 2>/dev/null | wc -l
}

# -----------------------------------------------------------------------------
# fzf Integration (optional)
# -----------------------------------------------------------------------------
jfzf() {
    if ! command -v fzf &> /dev/null; then
        echo "fzf not installed. Using standard list."
        jira issue list "$@"
        return
    fi
    local selected=$(jira issue list --plain --no-headers --columns key,status,summary "$@" | \
        fzf --preview 'jira issue view {1}' --preview-window=right:60%)
    if [[ -n "$selected" ]]; then
        local key=$(echo "$selected" | awk '{print $1}')
        echo "Selected: $key"
        echo "Actions: [v]iew, [o]pen, [m]ove, [a]ssign, [c]omment, [q]uit"
        read -r -n 1 action
        echo
        case "$action" in
            v) jira issue view "$key" ;;
            o) jira open "$key" ;;
            m) jira issue move "$key" ;;
            a) jira issue assign "$key" ;;
            c) jira issue comment add "$key" ;;
            q) return ;;
            *) echo "Unknown action" ;;
        esac
    fi
}

jpick() {
    if ! command -v fzf &> /dev/null; then
        echo "fzf required for jpick"
        return 1
    fi
    local key=$(jira issue list --plain --no-headers --columns key,summary "$@" | fzf | awk '{print $1}')
    [[ -n "$key" ]] && jira issue view "$key"
}

jpickopen() {
    if ! command -v fzf &> /dev/null; then
        echo "fzf required for jpickopen"
        return 1
    fi
    local key=$(jira issue list --plain --no-headers --columns key,summary "$@" | fzf | awk '{print $1}')
    [[ -n "$key" ]] && jira open "$key"
}

# -----------------------------------------------------------------------------
# Git Integration
# -----------------------------------------------------------------------------
jbranch() {
    if [[ -z "$1" ]]; then
        echo "Usage: jbranch ISSUE-KEY [prefix]"
        echo "Example: jbranch PLFM-123 feature"
        return 1
    fi
    local key="$1"
    local prefix="${2:-feature}"
    local summary=$(jira issue view "$key" --plain 2>/dev/null | \
        grep -E "^Summary:" | sed 's/Summary:[[:space:]]*//' | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-z0-9]/-/g' | \
        sed 's/-\+/-/g' | \
        sed 's/^-//' | \
        sed 's/-$//' | \
        cut -c1-50)
    echo "${prefix}/${key,,}-${summary}"
}

jgitstart() {
    if [[ -z "$1" ]]; then
        echo "Usage: jgitstart ISSUE-KEY [prefix]"
        return 1
    fi
    local branch=$(jbranch "$1" "${2:-feature}")
    echo "Creating branch: $branch"
    git checkout -b "$branch"
    jstart "$1" "Started work, branch: $branch"
}

jfromgit() {
    local branch=$(git branch --show-current 2>/dev/null)
    local key=$(echo "$branch" | grep -oE '[A-Z]+-[0-9]+' | head -1)
    if [[ -n "$key" ]]; then
        echo "$key"
    else
        echo "No issue key found in branch: $branch" >&2
        return 1
    fi
}

jgitview() {
    local key=$(jfromgit)
    [[ -n "$key" ]] && jira issue view "$key"
}

jgitopen() {
    local key=$(jfromgit)
    [[ -n "$key" ]] && jira open "$key"
}

jgitcomment() {
    local key=$(jfromgit)
    if [[ -n "$key" ]] && [[ -n "$1" ]]; then
        jira issue comment add "$key" --body "$1"
    else
        echo "Usage: jgitcomment 'comment text'"
    fi
}

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------
jcopyurl() {
    if [[ -z "$1" ]]; then
        echo "Usage: jcopyurl ISSUE-KEY"
        return 1
    fi
    local url=$(jira issue view "$1" --plain 2>/dev/null | grep -E "^Web:" | awk '{print $2}')
    if [[ -n "$url" ]]; then
        if command -v pbcopy &> /dev/null; then
            echo -n "$url" | pbcopy
        elif command -v xclip &> /dev/null; then
            echo -n "$url" | xclip -selection clipboard
        else
            echo "$url"
            return
        fi
        echo "Copied: $url"
    else
        echo "Could not get URL for $1"
    fi
}

jstatus() {
    local key="${1:-$(jfromgit 2>/dev/null)}"
    if [[ -n "$key" ]]; then
        jira issue view "$key" --plain 2>/dev/null | grep -E "^(Key:|Summary:|Status:)" | sed 's/^/  /'
    fi
}

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------
jhelp() {
    cat <<'EOF'
=== Jira CLI Aliases Quick Reference ===

LISTING:
  jm / jmopen      My issues / my open issues
  jh               Recently viewed
  jsc / jscm       Current sprint / my sprint issues
  jtodo / jinprog  By status
  jcrit / jhigh    By priority

BOARD & BACKLOG (PLFM):
  jboard / jboardm      Board view / my board issues
  jbacklog / jbacklogm  Backlog / my backlog
  jbacklogu             Unassigned backlog
  jbacklogfilter        Flexible backlog filter (run for help)
  jboardfilter          Flexible board filter (run for help)

ACTIONS:
  jc / jv KEY / jo KEY  Create / view / open in browser
  je KEY / jmove KEY    Edit / transition
  ja KEY USER           Assign

WORKFLOW:
  jstart KEY      Assign to me + move to In Progress
  jfinish KEY     Move to Done
  jblock KEY why  Block with reason
  jnote KEY msg   Add comment
  jlog KEY 2h     Log time

SRE:
  jinc / jincnew       List / create incidents
  jp1 "summary"        Create P1 incident
  jpm / jpmcreate      Postmortems

REPORTS:
  jcount / jcountplfm  Count by status
  jmyload              My workload summary
  jsprintprog          Sprint progress
  jbackloghealth       Backlog health check
  jstale 30            Stale issues

GIT:
  jgitstart KEY   Create branch + start work
  jgitview        View issue from current branch
  jgitopen        Open issue from current branch

FZF (if installed):
  jfzf            Interactive picker with preview
  jpick / jpickopen

Type 'jhelp' to see this again.
EOF
}
