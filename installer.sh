#!/bin/sh

rm -rf $0
rm -rf /etc/arca/restart_wan
rm -rf /etc/arca/change_ip
>/etc/arca/counter
mkdir -p /etc/arca

log() {
    echo "$(date): $@" >> /etc/arca/log
}

restart_wan_mm() {
    local modem_id=$(mmcli -L | grep -o -E 'Modem\/[0-9]+' | cut -d'/' -f2)
    if [ -z "$modem_id" ]; then
        log "No modem detected via ModemManager"
        return 1
    fi
    mmcli -m $modem_id --disable
    sleep 2
    mmcli -m $modem_id --enable
    sleep 10
    mmcli -m $modem_id --simple-connect="apn=$(uci get modem.modem1.apn)"
    log "ModemManager WAN restarted for modem ID $modem_id"
}

cat << 'EOF' >/etc/arca/change_ip
#!/bin/sh

log() {
    echo "$(date): $@" >> /etc/arca/log
}

monitor_connection() {
    while true; do
        if ! ping -c 5 -q google.com > /dev/null 2>&1; then
            log "Internet disconnected. Attempting to reconnect..."
            restart_wan_mm
        else
            log "Internet is working fine."
        fi
        sleep 30
    done
}

restart_wan_mm() {
    local modem_id=$(mmcli -L | grep -o -E 'Modem\/[0-9]+' | cut -d'/' -f2)
    if [ -z "$modem_id" ]; then
        log "No modem detected via ModemManager"
        return 1
    fi
    mmcli -m $modem_id --disable
    sleep 2
    mmcli -m $modem_id --enable
    sleep 10
    mmcli -m $modem_id --simple-connect="apn=$(uci get modem.modem1.apn)"
    log "ModemManager WAN restarted for modem ID $modem_id"
}

monitor_connection
EOF

chmod +x /etc/arca/change_ip

if pgrep -f /etc/arca/change_ip > /dev/null 2>&1; then
    kill -9 $(pgrep -f /etc/arca/change_ip)
fi

/etc/arca/change_ip &

log "ModemManager auto-reconnect script initialized."
echo "Done. You can close this terminal now."
exit 0
