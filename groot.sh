#!/usr/bin/env bash
if [ -e "$(dirname ${0})/functions.sh" ]; then
  source "$(dirname ${0})/functions.sh"
fi

cpu_mem_usage () {
    # Draw colored percent bar
    color=${lcolor}
    if [[ $usedpercent -ge 25 ]]; then color=${color} ; fi
    if [[ $usedpercent -ge 50 ]]; then color=${dcolor} ; fi
    if [[ $usedpercent -ge 75 ]]; then color=${vdcolor} ; fi
    echo -ne "${color}["
    cpt=0
    for((i=0;i<${1};i=i+4)); do echo -ne "${color}#" ; cpt=$((cpt+1)) ; done
    echo -ne ${NC}
    for((i=${1};i<100;i=i+4)); do echo -ne "-" ; cpt=$((cpt+1)) ; done
    if [ $cpt -lt 26 ] ; then echo -ne "-" ; fi
    echo -ne "${color}]${color} "
    printf "%03d" ${1} | sed -E s/"^0"/""/ | sed -E s/"^0"/" "/
    echo -ne "%"
}

disk_usage () {
    # Parse df output
    if df -h ${1} >/dev/null 2>&1 ; then
        df_cmd=$(df -h ${1} | tail -n 1)
        IFS=' ' read -ra my_array <<< "$df_cmd"
        size=${my_array[1]}
        used=${my_array[2]}
        avail=${my_array[3]}
        usedpercent=$(echo ${my_array[4]} | sed s/"%"/""/)
        # Draw colored percent bar
        color=${lcolor}
        if [[ $usedpercent -ge 25 ]]; then color=${color} ; fi
        if [[ $usedpercent -ge 50 ]]; then color=${dcolor} ; fi
        if [[ $usedpercent -ge 75 ]]; then color=${vdcolor} ; fi
        printf "  %-10s" ${1}
        echo -ne "["
        cpt=0
        for((i=0;i<$usedpercent;i=i+2)); do echo -ne "${color}#" ; cpt=$((cpt+1)) ; done
        echo -ne ${NC}
        for((i=$usedpercent;i<100;i=i+2)); do echo -ne "-" ; cpt=$((cpt+1)) ; done
        if [ $cpt -lt 51 ] ; then echo -ne "-" ; fi
        echo -ne "]${color}"
        printf "%+3s" ${usedpercent}
        echo -e "% (${used}/${size})${NC}"
    else
        printf "  %-10s" ${1}
        echo -e "[not found]"
    fi
}


# Colors
random_color=$(( $RANDOM % 5 + 1 ))
case $random_color in
  "1")
    vdcolor='\x1b[38;2;0;128;51m' ; dcolor='\x1b[38;2;0;170;68m' ; color='\x1b[38;2;85;255;153m' ; lcolor='\x1b[38;2;170;255;204m' # green
    ;;
  "2")
    vdcolor='\x1b[38;2;255;102;0m' ; dcolor='\x1b[38;2;255;153;85m' ; color='\x1b[38;2;255;204;170m' ; lcolor='\x1b[38;2;255;230;213m' # orange
    ;;
  "3")
    vdcolor='\x1b[38;2;255;204;0m' ; dcolor='\x1b[38;2;255;221;85m' ; color='\x1b[38;2;255;238;170m' ; lcolor='\x1b[38;2;255;246;213m' # yellow
    ;;
  "4")
    vdcolor='\x1b[38;2;0;212;170m' ; dcolor='\x1b[38;2;85;255;221m' ; color='\x1b[38;2;170;255;238m' ; lcolor='\x1b[38;2;213;255;246m' # turquoise
    ;;
  "5")
    vdcolor='\x1b[38;2;255;42;127m' ; dcolor='\x1b[38;2;255;128;178m' ; color='\x1b[38;2;255;170;204m' ; lcolor='\x1b[38;2;255;213;229m' # pink
    ;;    
  *)
esac
NC='\x1b[0m'

# Header
groot_array[0]="${color}       .^. .  _                ${NC}"
groot_array[1]="${color}      /: ||\`\\/ \\~  ,           ${NC}"    
groot_array[2]="${color}    , [   &    / \\ y'          ${NC}"
groot_array[3]="${color}   {v':   \`\\   / \`&~-,         ${NC}"
groot_array[4]="${color}  'y. '    |\`   .  ' /         ${NC}"
groot_array[5]="${color}   \\   '  .       , y          ${NC}"
groot_array[6]="${color}   v .        '     v          ${NC}"
groot_array[7]="${color}   V  ${dcolor}.~.      .~.${color}  V          ${NC}"
groot_array[8]="${color}   : ${dcolor}(  ${lcolor}0${dcolor})    (  ${lcolor}0${dcolor})${color} :          ${NC}"
groot_array[9]="${color}    i ${dcolor}\`'\`      \`'\`${color} j           ${NC}"    
groot_array[10]="${color}     i     ${dcolor}__${color}    ,j            ${NC}"
groot_array[11]="${color}      \`%\`~....~'&              ${NC}"


uptime=$(uptime | sed -E s/'.+up '/''/ | sed -E s/'[^,]+user.+'/''/ | sed s/":"/" hours, "/ | sed s/" min"/""/ | sed -E s/",$"/" minutes"/)
if command -v lsb_release &>/dev/null; then
  release=$(lsb_release -d -s)
else
  release=$(cat /etc/os-release | grep '^PRETTY_NAME' | cut -d= -f2 | sed s/"\""/""/g)
fi
freememory=$(free | awk 'NR == 2 {print int($3/$2*100)}')
cpu_used=$(top -bn 1 |grep -i -m 1 "cpu" | awk '{print $2+$4}')
info_array[0]=""
info_array[1]="WELCOME ASTROPAPUA"
info_array[2]="==============================================="
info_array[3]="${dcolor}Date        ${color}$(date +"%A %d %B %Y %H:%M:%S")"
info_array[4]="${dcolor}Uptime      ${color}${uptime}"
info_array[5]="${dcolor}Release     ${color}${release}"
info_array[6]="${dcolor}Bash        ${color}$(echo $BASH_VERSION | cut -d '(' -f 1)"
info_array[7]="${dcolor}Python      ${color}$(python --version | cut -d " " -f 2)"
info_array[8]="${dcolor}Conda       ${color}$(conda --version | cut -d " " -f 2)"
info_array[9]="${dcolor}CPU load    ${color}$(cpu_mem_usage ${cpu_used})"
info_array[10]="${dcolor}MEM load    ${color}$(cpu_mem_usage ${freememory})"
info_array[12]=""
info_array[13]=""

# reset
#Print the split string
for ((i=0;i<${#groot_array[@]};i++))
    do
    echo -ne "${groot_array[$i]}"
    echo -e "${color}${info_array[$i]}${NC}"
done
echo -e "${dcolor}\nDISK USAGE${NC}"
# disk usage function
array_disk=("/")
for disk in /mnt/* ; do
  if [[ ! ${disk} == *wsl* ]]; then
    array_disk+=("${disk}")
  fi
done

for disk in "${array_disk[@]}"; do
  disk_usage ${disk}
done

echo ""
