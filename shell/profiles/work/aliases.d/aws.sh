# =============================================================================
# AWS SSO Login Helper
# =============================================================================
check_aws_sso_login() {
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo "Not logged in or token is invalid. Attempting to log in via AWS SSO..."
        if ! aws sso login; then
            echo "AWS SSO login failed. Attempting to force a logout and re-login..."
            aws sso logout >/dev/null 2>&1
            if ! aws sso login; then
                echo "AWS SSO login failed again. Please check your configuration or credentials and try again."
                return 1
            fi
        fi
    else
        echo "Already logged in to AWS."
    fi
}

# =============================================================================
# AWS Profile & Region Shortcuts
# =============================================================================
alias gohighway='export AWS_PROFILE="$DF_WORK_AWS_ROOT_PROFILE"'
alias gomonitoring='export AWS_PROFILE="$DF_WORK_AWS_MONITORING_PROFILE"'
alias goeast='export AWS_REGION=us-east-1'

# Profile shortcuts with auto-login
hr() {
    export AWS_PROFILE="$DF_WORK_AWS_ROOT_PROFILE"
    export AWS_REGION=us-east-1
    check_aws_sso_login
}

hd() {
    export AWS_PROFILE="$DF_WORK_AWS_DEV_PROFILE"
    export AWS_REGION=us-east-1
    check_aws_sso_login
}

# =============================================================================
# ECS Shell Access
# =============================================================================
_ecs_exec() {
    local cluster=$1
    local service=$2
    local container=$3
    
    check_aws_sso_login || return 1
    
    local task_id=$(aws ecs list-tasks --cluster "$cluster" --service-name "$service" \
        --query 'taskArns[0]' --output text)
    
    if [[ -z "$task_id" || "$task_id" == "None" ]]; then
        echo "No tasks found for $service in $cluster."
        return 1
    fi
    
    echo "Executing command on task ID: $task_id"
    aws ecs execute-command --cluster "$cluster" --task "$task_id" \
        --container "$container" --interactive --command "/bin/sh"
}

stg() { _ecs_exec "$DF_WORK_ECS_STAGING_CLUSTER" "monitor" "monitor"; }
nginx-proxy() { _ecs_exec "$DF_WORK_ECS_PROD_CLUSTER" "nginx-proxy-service" "nginx"; }

# =============================================================================
# WAF Log Analysis - Core Helpers
# =============================================================================
WAF_LOG_GROUP="$DF_WORK_WAF_LOG_GROUP"

# Parse time string "HH:MM" to epoch (macOS)
# Args: time_str (HH:MM), days_ago (optional, default 0)
_waf_parse_time() {
    local time_str=$1
    local days_ago=${2:-0}
    local hour=${time_str%:*}
    local min=${time_str#*:}
    date -v-"${days_ago}"d -v${hour}H -v${min}M -v0S +%s
}

# Calculate timestamps for offset-based queries
_waf_offset_times() {
    local hours=${1:-1}
    WAF_START_TS=$(date -v-"${hours}"H +%s)
    WAF_END_TS=$(date +%s)
}

# Calculate timestamps for time window queries (default 08:00-09:30)
# Args: start_time, end_time, days_ago (optional, default 0)
_waf_window_times() {
    local start_h=${1:-08:00}
    local end_h=${2:-09:30}
    local days_ago=${3:-0}
    WAF_START_TS=$(_waf_parse_time "$start_h" "$days_ago")
    WAF_END_TS=$(_waf_parse_time "$end_h" "$days_ago")
}

# Submit query and store ID
_waf_query() {
    local query_string=$1
    local description=$2
    
    echo "$description"
    
    export AWS_QUERY_ID=$(aws logs start-query \
        --log-group-name "$WAF_LOG_GROUP" \
        --start-time "$WAF_START_TS" \
        --end-time "$WAF_END_TS" \
        --query-string "$query_string" \
        --query 'queryId' --output text)
    
    echo "Query ID: $AWS_QUERY_ID"
}

# Wait for query completion and display results
_waf_wait_results() {
    local jq_query=$1
    
    if [ -z "$AWS_QUERY_ID" ]; then
        echo "Error: No AWS_QUERY_ID found. Run a waf_* query first."
        return 1
    fi

    echo -n "Waiting for query to complete"
    while true; do
        local _qstatus=$(aws logs get-query-results --query-id "$AWS_QUERY_ID" \
            --query "status" --output text)
        
        case "$_qstatus" in
            Complete)
                echo -e "\nQuery Complete!"
                aws logs get-query-results --query-id "$AWS_QUERY_ID" \
                    --query "$jq_query" --output table
                break
                ;;
            Failed|Cancelled)
                echo -e "\nQuery $_qstatus."
                return 1
                ;;
            *)
                echo -n "."
                sleep 2
                ;;
        esac
    done
}

# =============================================================================
# WAF Analysis Functions
# =============================================================================

# Analyze blocked/allowed requests by URI and rule (time window)
waf_analyze() {
    local action=${1:-BLOCK}
    local start_h=${2:-08:00}
    local end_h=${3:-09:30}
    local days_ago=${4:-0}
    
    _waf_window_times "$start_h" "$end_h" "$days_ago"
    local day_label=$([[ $days_ago -eq 0 ]] && echo "today" || echo "${days_ago}d ago")
    _waf_query \
        "fields httpRequest.uri, terminatingRuleId
         | filter action = '$action'
         | stats count(*) as requestCount by httpRequest.uri, terminatingRuleId
         | sort requestCount desc
         | limit 20" \
        "Analyzing $action requests (${start_h}-${end_h}, $day_label)..."
}

# Analyze blocked/allowed requests by URI and rule (offset from now)
waf_analyze_offset() {
    local hours=${1:-1}
    local action=${2:-BLOCK}
    
    _waf_offset_times "$hours"
    _waf_query \
        "fields httpRequest.uri, terminatingRuleId
         | filter action = '$action'
         | stats count(*) as requestCount by httpRequest.uri, terminatingRuleId
         | sort requestCount desc
         | limit 20" \
        "Analyzing $action requests (past ${hours}h)..."
}

# Get top endpoints by request count
waf_top_endpoints() {
    local hours=${1:-1}
    
    _waf_offset_times "$hours"
    _waf_query \
        "fields httpRequest.uri
         | stats count(*) as requestCount by httpRequest.uri
         | sort requestCount desc
         | limit 10" \
        "Finding top endpoints (past ${hours}h)..."
}

# Find top IPs hitting a specific URI
waf_top_ips() {
    local target_uri=$1
    local action=${2:-BLOCK}
    local hours=${3:-1}
    
    if [ -z "$target_uri" ]; then
        echo "Usage: waf_top_ips /your/path [BLOCK|ALLOW] [hours]"
        return 1
    fi
    
    _waf_offset_times "$hours"
    _waf_query \
        "fields httpRequest.clientIp, httpRequest.uri, action
         | filter httpRequest.uri = '$target_uri'
         | filter action = '$action'
         | stats count(*) as ipCount by httpRequest.clientIp
         | sort ipCount desc
         | limit 20" \
        "Finding top IPs hitting '$target_uri' ($action, past ${hours}h)..."
}

# Find top talking IPs for a URI (time window)
waf_top_talkers() {
    local target_uri=${1:-/monitor/refresh_jwt}
    local start_h=${2:-08:00}
    local end_h=${3:-09:30}
    local days_ago=${4:-0}
    
    _waf_window_times "$start_h" "$end_h" "$days_ago"
    local day_label=$([[ $days_ago -eq 0 ]] && echo "today" || echo "${days_ago}d ago")
    _waf_query \
        "filter httpRequest.uri = '$target_uri'
         | stats count(*) as hits by httpRequest.clientIp, action
         | sort hits desc
         | limit 20" \
        "Finding top IPs hitting $target_uri (${start_h}-${end_h}, $day_label)..."
}

# Analyze auth-related endpoints
waf_analyze_auth() {
    local action=${1:-ALLOW}
    local start_h=${2:-08:00}
    local end_h=${3:-09:30}
    local days_ago=${4:-0}
    
    _waf_window_times "$start_h" "$end_h" "$days_ago"
    local day_label=$([[ $days_ago -eq 0 ]] && echo "today" || echo "${days_ago}d ago")
    _waf_query \
        "fields httpRequest.uri, httpRequest.clientIp
         | filter action = '$action'
         | filter httpRequest.uri like /login/ or httpRequest.uri like /lookup/ or httpRequest.uri like /refresh_jwt/
         | stats count(*) as totalHits, count_distinct(httpRequest.clientIp) as uniqueIPs by httpRequest.uri
         | sort totalHits desc" \
        "Analyzing auth patterns ($action, ${start_h}-${end_h}, $day_label)..."
}

# Deep dive into a specific URI with header analysis
waf_debug_uri() {
    local target_uri=${1:-/monitor/refresh_jwt}
    local start_h=${2:-08:00}
    local end_h=${3:-09:30}
    local days_ago=${4:-0}
    
    _waf_window_times "$start_h" "$end_h" "$days_ago"
    local day_label=$([[ $days_ago -eq 0 ]] && echo "today" || echo "${days_ago}d ago")
    _waf_query \
        "fields @message
         | filter httpRequest.uri = '$target_uri'
         | parse @message '{\"name\":\"User-Agent\",\"value\":\"*\"}' as ua
         | parse @message '{\"name\":\"Referer\",\"value\":\"*\"}' as ref
         | stats count(*) as total, count_distinct(httpRequest.clientIp) as uniqueIPs by ua, ref, action
         | sort total desc
         | limit 30" \
        "Deep diving into $target_uri (${start_h}-${end_h}, $day_label)..."
}

# Investigate all activity for a specific IP
waf_investigate_ip() {
    local target_ip=$1
    local start_h=${2:-08:00}
    local end_h=${3:-09:30}
    local days_ago=${4:-0}
    
    if [ -z "$target_ip" ]; then
        echo "Usage: waf_investigate_ip <IP> [start_time] [end_time] [days_ago]"
        return 1
    fi
    
    _waf_window_times "$start_h" "$end_h" "$days_ago"
    local day_label=$([[ $days_ago -eq 0 ]] && echo "today" || echo "${days_ago}d ago")
    _waf_query \
        "fields httpRequest.uri, action, terminatingRuleId
         | filter httpRequest.clientIp = '$target_ip'
         | stats count(*) as hits by httpRequest.uri, action, terminatingRuleId
         | sort hits desc" \
        "Investigating IP: $target_ip (${start_h}-${end_h}, $day_label)..."
}

# =============================================================================
# WAF Results Display (unified with auto-wait)
# =============================================================================

waf_results() {
    _waf_wait_results \
        'results[*].[{uri: [?field==`httpRequest.uri`].value | [0], rule: [?field==`terminatingRuleId`].value | [0], count: [?field==`requestCount`].value | [0]}]'
}

waf_results_ips() {
    _waf_wait_results \
        'results[*].[{ip: [?field==`httpRequest.clientIp`].value | [0], count: [?field==`ipCount`].value | [0]}]'
}

waf_results_talkers() {
    _waf_wait_results \
        'results[*].[{ip: [?field==`httpRequest.clientIp`].value | [0], action: [?field==`action`].value | [0], count: [?field==`hits`].value | [0]}]'
}

waf_results_auth() {
    _waf_wait_results \
        'results[*].[{uri: [?field==`httpRequest.uri`].value | [0], total: [?field==`totalHits`].value | [0], unique_ips: [?field==`uniqueIPs`].value | [0]}]'
}

waf_results_debug() {
    _waf_wait_results \
        'results[*].[{count: [?field==`total`].value | [0], IPs: [?field==`uniqueIPs`].value | [0], action: [?field==`action`].value | [0], referer: [?field==`ref`].value | [0], user_agent: [?field==`ua`].value | [0]}]'
}

waf_results_investigation() {
    _waf_wait_results \
        'results[*].[{uri: [?field==`httpRequest.uri`].value | [0], action: [?field==`action`].value | [0], rule: [?field==`terminatingRuleId`].value | [0], count: [?field==`hits`].value | [0]}]'
}

# =============================================================================
# WAF Full Audit (runs multiple queries)
# =============================================================================
waf_full_audit() {
    local start_h=${1:-08:00}
    local end_h=${2:-09:30}
    local days_ago=${3:-0}
    
    local day_label=$([[ $days_ago -eq 0 ]] && echo "today" || echo "${days_ago}d ago")
    echo "=== WAF Full Audit (${start_h} - ${end_h}, $day_label) ==="
    
    echo -e "\n--- Phase 1: High Level Auth Patterns ---"
    waf_analyze_auth ALLOW "$start_h" "$end_h" "$days_ago"
    local id1=$AWS_QUERY_ID
    
    echo -e "\n--- Phase 2: Deep Header Dive (JWT focus) ---"
    waf_debug_uri "/monitor/refresh_jwt" "$start_h" "$end_h" "$days_ago"
    local id2=$AWS_QUERY_ID
    
    echo -e "\n--- Phase 3: Top Offending IPs ---"
    waf_top_talkers "/monitor/refresh_jwt" "$start_h" "$end_h" "$days_ago"
    local id3=$AWS_QUERY_ID

    echo -e "\n=== Audit Queries Submitted ==="
    echo "1. Auth Patterns:   AWS_QUERY_ID=$id1 then waf_results_auth"
    echo "2. Header Dive:     AWS_QUERY_ID=$id2 then waf_results_debug"
    echo "3. Top IPs:         AWS_QUERY_ID=$id3 then waf_results_talkers"
    
    export AWS_QUERY_ID=$id3
    echo -e "\nAWS_QUERY_ID set to Phase 3 (Top IPs) for immediate follow-up."
}

# =============================================================================
# Quick Reference
# =============================================================================
waf_help() {
    cat << 'EOF'
WAF Analysis Commands:
  waf_analyze [BLOCK|ALLOW] [start] [end] [days_ago]
      - Analyze by URI/rule (default: BLOCK 08:00-09:30 today)
  waf_analyze_offset [hours] [BLOCK|ALLOW]
      - Analyze past N hours from now
  waf_top_endpoints [hours]
      - Top endpoints by traffic
  waf_top_ips <uri> [BLOCK|ALLOW] [hours]
      - Top IPs for specific URI
  waf_top_talkers [uri] [start] [end] [days_ago]
      - Top IPs hitting URI in window
  waf_analyze_auth [BLOCK|ALLOW] [start] [end] [days_ago]
      - Auth endpoint analysis
  waf_debug_uri [uri] [start] [end] [days_ago]
      - Deep header analysis
  waf_investigate_ip <ip> [start] [end] [days_ago]
      - All activity for an IP
  waf_full_audit [start] [end] [days_ago]
      - Run all auth-related queries

Results (all auto-wait for completion):
  waf_results              - For waf_analyze*
  waf_results_ips          - For waf_top_ips
  waf_results_talkers      - For waf_top_talkers
  waf_results_auth         - For waf_analyze_auth
  waf_results_debug        - For waf_debug_uri
  waf_results_investigation - For waf_investigate_ip

Time format: HH:MM (e.g., 08:00, 14:30)
days_ago: 0 = today (default), 1 = yesterday, 2 = two days ago, etc.

Examples:
  waf_full_audit                     # Today 08:00-09:30
  waf_full_audit 08:00 09:30 1       # Yesterday 08:00-09:30
  waf_analyze BLOCK 14:00 15:00 2    # 2 days ago, 14:00-15:00
EOF
}
