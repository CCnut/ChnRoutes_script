
#!/usr/bin/env bash
set -e

[[ $DEBUG == true ]] && set -x

genTime=$(date "+%Y-%m-%d %H:%M:%S %z")

log_info(){
    >&2 echo "INFO>" $@
}

get_ipip_data(){
    ipip_data=$(curl -sSL https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt 2>/dev/null)
}

gen_info(){
    echo "$1Author: CCnut
$1Source: https://github.com/CCnut/ChnRoutes_script
$1Time: $genTime
$1"
}

gen_rule(){
    local ruleSuffix=$1
    local rulePrefix=$2
    echo "$ipip_data" | awk "NR==FNR{printf(\"$ruleSuffix%s $rulePrefix\n\",\$0)}" 2>/dev/null
}

gen_mikrotik(){
    local header=':if ([:len [/ip route find where routing-mark=[] distance=1 dynamic=yes static=yes]] = 0) do={
:put "Default gateway not found, exit."
:error
}
:if ([:len [/ip route find routing-mark="NotChnRule"]] = 0) do={
:put "####################################################"
:put "# Please note on the first run:"
:put "#"
:put "# Set \"defconf: drop invalid\" to Not Coming from LAN"
:put "# /ip firewall filter set in-interface-list=!LAN [find comment=\"defconf: drop invalid\"]"
:put "#"
:put "# Bypass your special gateway in ip-routes-rules"
:put "# /ip route rule set src-address=<Your special gateway> action=lookup table=main"
:put "#"
:put "# Set \"ChnRule\" in ip-routes"
:put "# /ip route add dst-address=0.0.0.0/0 routing-mark=ChnRule gateway=<Your gateway>"
:put "# Set \"NotChnRule\" in ip-routes"
:put "# /ip route add dst-address=0.0.0.0/0 routing-mark=NotChnRule gateway=<Your special gateway>"
:put "####################################################"
} else={
#Clear the old rules
/ip route rule remove [find comment="CreatedBy ChnRoutesScript"]
#Add ChnRule rule
/ip route set [find where routing-mark="ChnRule"] gateway=[get [find where routing-mark=[] distance=1 dynamic=yes static=yes] gateway]
#Set new rules
/ip route rule
add dst-address=10.0.0.0/8 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"
add dst-address=100.64.0.0/10 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"
add dst-address=127.0.0.0/8 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"
add dst-address=169.254.0.0/16 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"
add dst-address=172.16.0.0/12 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"
add dst-address=192.168.0.0/16 interface=bridge action=lookup table=main comment="CreatedBy ChnRoutesScript"'
    local rule=$(gen_rule 'add dst-address=' 'interface=bridge action=lookup table=ChnRule comment=\"CreatedBy ChnRoutesScript\"' 2>/dev/null)
    local footer='add dst-address=0.0.0.0/0 interface=bridge action=lookup table=NotChnRule comment="CreatedBy ChnRoutesScript"
}'
    echo "$(gen_info \#)
$header
$rule
$footer"
}

log_info 'Download 17mon/china_ip_list'
get_ipip_data
log_info 'Create Script:'
log_info '- Mikrotik RouterOS'
gen_mikrotik >script/RouterOS_ChnRoutes.rsc 2>/dev/null
log_info 'Done, Clear files'
