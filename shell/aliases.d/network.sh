ip_info() {
    local ip=$1
    if [ -z "$ip" ]; then echo "Usage: ip_info <IP>"; return 1; fi
    
    # Hits ip-api.com (free for non-commercial/low-volume)
    curl -s "http://ip-api.com/json/$ip" | jq -r '
        "IP: \(.query)\nLocation: \(.city), \(.regionName), \(.country)\nISP: \(.isp)\nOrg: \(.org)"
    '
}
