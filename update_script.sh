#!/usr/bin/env bash
set -e

[[ $DEBUG == true ]] && set -x

log_info(){
    >&2 echo "INFO>" $@
}

get_ipip_data(){
    curl -sSLo china_ip_list.txt  https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
}

clear_file(){
    rm -f china_ip_list.txt 2>/dev/null
}

gen_rule(){
    local ruleSuffix=$1
    local rulePrefix=$2
    local toFile=$3
    awk "NR==FNR{printf(\"$ruleSuffix%s $rulePrefix\n\",\$0)}" ./china_ip_list.txt >> $toFile 2>/dev/null
}

gen_mikrotik(){
    #chnroutes-ip-route-rule.rsc
    local toFile='mikrotik/chnroutes-ip-route-rule.rsc'
    cat >$toFile <<'EOF'
:if ([:len [/ip route find routing-mark=ChnRule]] = 0) do={
:put "####################################################"
:put "# Please note on the first run:"
:put "#"
:put "# Set \"defconf: drop invalid\" to Not Coming from LAN"
:put "# /ip firewall filter set in-interface-list=!LAN [find comment=\"defconf: drop invalid\"]"
:put "#"
:put "# Bypass your special gateway in ip-route-rule"
:put "# /ip route rule set src-address=<Your special gateway> action=lookup table=main"
:put "#"
:put "# Set \"ChnRule\" and \"NotChnRule\" in ip-route"
:put "# /ip route add dst-address=0.0.0.0/0 routing-mark=ChnRule gateway=<Your gateway>"
:put "# /ip route add dst-address=0.0.0.0/0 routing-mark=NotChnRule gateway=<Your special gateway>"
:put "####################################################"
} else={
#Clear the old rules
/ip route rule remove [find comment="CreatedBy ChnRoutesScript"]
#Set new rules
/ip route rule
add dst-address=10.0.0.0/8 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"
add dst-address=100.64.0.0/10 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"
add dst-address=127.0.0.0/8 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"
add dst-address=169.254.0.0/16 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"
add dst-address=172.16.0.0/12 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"
add dst-address=192.168.0.0/16 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"
EOF
    gen_rule 'add dst-address=' 'interface=bridge action=lookup table=ChnRule comment=\"CreatedBy ChnRoutesScript\"' $toFile
    echo 'add dst-address=0.0.0.0/0 interface=bridge action=lookup table=NotChnRule comment="CreatedBy ChnRoutesScript"' >> $toFile 2>/dev/null
    echo '}' >> $toFile 2>/dev/null
}

log_info 'Download 17mon/china_ip_list'
get_ipip_data
log_info 'Create Script:'
log_info '- Mikrotik RouterOS'
gen_mikrotik
log_info 'Done, Clear files'
clear_file

