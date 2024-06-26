#!/usr/bin/env bash
if [ -e "$(dirname ${0})/functions.sh" ]; then
  source "$(dirname ${0})/functions.sh"
fi

reset

cpu_mem_usage () {
    # Draw colored percent bar
    finalcolor=${lcolor}
    if [[ $usedpercent -ge 25 ]]; then finalcolor=${color} ; fi
    if [[ $usedpercent -ge 50 ]]; then finalcolor=${dcolor} ; fi
    if [[ $usedpercent -ge 75 ]]; then finalcolor=${vdcolor} ; fi
    echo -ne "${NC}["
    cpt=0
    for((i=0;i<${1};i=i+4)); do echo -ne "${finalcolor}#" ; cpt=$((cpt+1)) ; done
    echo -ne ${NC}
    for((i=${1};i<100;i=i+4)); do echo -ne "-" ; cpt=$((cpt+1)) ; done
    if [ $cpt -lt 26 ] ; then echo -ne "-" ; fi
    echo -ne "]${finalcolor} "
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
        finalcolor=${lcolor}
        if [[ $usedpercent -ge 25 ]]; then finalcolor=${color} ; fi
        if [[ $usedpercent -ge 50 ]]; then finalcolor=${dcolor} ; fi
        if [[ $usedpercent -ge 75 ]]; then finalcolor=${vdcolor} ; fi
        printf "  %-10s" ${1}
        echo -ne "["
        cpt=0
        for((i=0;i<$usedpercent;i=i+2)); do echo -ne "${finalcolor}#" ; cpt=$((cpt+1)) ; done
        echo -ne ${NC}
        for((i=$usedpercent;i<100;i=i+2)); do echo -ne "-" ; cpt=$((cpt+1)) ; done
        if [ $cpt -lt 51 ] ; then echo -ne "-" ; fi
        echo -ne "]${finalcolor}"
        printf "%+3s" ${usedpercent}
        echo -e "% (${used}/${size})${NC}"
    else
        printf "  %-10s" ${1}
        echo -e "[not found]"
    fi
}


# Colors
case $myrelease in
  "debian")
    # vdcolor='\x1b[38;2;189;213;103m' ; dcolor='\x1b[38;2;0;149;151m' ; color='\x1b[38;2;0;199;195m' ; lcolor='\x1b[38;2;255;213;229m'
    vdcolor='\x1b[38;2;139;0;0m' ; dcolor='\x1b[38;2;165;42;42m' ; color='\x1b[38;2;205;92;92m' ; lcolor='\x1b[38;2;240;165;165m'
    ;;
  "ubuntu")
    vdcolor='\x1b[38;2;85;187;255m' ; dcolor='\x1b[38;2;227;91;0m' ; color='\x1b[38;2;255;153;85m' ; lcolor='\x1b[38;2;255;213;229m'
    ;;
  "alpine")
    vdcolor='\x1b[38;2;255;179;128m' ; dcolor='\x1b[38;2;0;85;212m' ; color='\x1b[38;2;42;127;255m' ; lcolor='\x1b[38;2;255;213;229m'
    ;; 
  "fedora")
    vdcolor='\x1b[38;2;0;85;212m' ; dcolor='\x1b[38;2;0;128;255m' ; color='\x1b[38;2;0;153;204m' ; lcolor='\x1b[38;2;0;204;255m'
    ;; 
  *)
    vdcolor='\x1b[38;2;255;102;0m' ; dcolor='\x1b[38;2;255;153;85m' ; color='\x1b[38;2;255;204;170m' ; lcolor='\x1b[38;2;255;230;213m' # orange
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
freememory=$(free | awk 'NR == 2 {print int($3/$2*100)}' | sed -E s/"\..+"/""/)
cpu_used=$(top -bn 1 |grep -i -m 1 "cpu" | awk '{print $2+$4}' | sed -E s/"\..+"/""/)
# Conda
CONDA_EXE=$(which $(command -v conda))
if [[ -z $CONDA_EXE ]]; then
  CONDA_EXE=~/miniconda3/bin/conda
fi
if [[ -z $CONDA_EXE ]]; then
  CONDA_EXE=~/anaconda/bin/conda
fi
if [ -z "$http_proxy" ]; then
  proxy="None"
else
  proxy=$http_proxy
fi
lst_conda_env=$($CONDA_EXE env list | grep -v "#" | grep -v "base" | cut -d " " -f1)
info_array[0]=""
info_array[1]="WELCOME ASTROPAPUA"
info_array[2]="==============================================="
info_array[3]="${dcolor}Date        ${color}$(date +"%A %d %B %Y %H:%M:%S")"
info_array[4]="${dcolor}Uptime      ${color}${uptime}"
info_array[5]="${dcolor}Release     ${color}${release}"
info_array[6]="${dcolor}Proxy       ${color}${proxy}"
info_array[7]="${dcolor}Bash        ${color}$(echo $BASH_VERSION | cut -d '(' -f 1)"
info_array[8]="${dcolor}Python      ${color}$(python3 --version | cut -d " " -f 2)"
info_array[9]="${dcolor}Conda       ${color}$($CONDA_EXE --version 2>/dev/null | cut -d " " -f 2 || echo 'None')"
info_array[10]="${dcolor}CPU load    ${color}$(cpu_mem_usage ${cpu_used})"
info_array[11]="${dcolor}MEM load    ${color}$(cpu_mem_usage ${freememory})"
info_array[13]=""
info_array[14]=""
#Print the split string
for ((i=0;i<${#groot_array[@]};i++))
    do
    echo -ne "${groot_array[$i]}"
    echo -e "${color}${info_array[$i]}${NC}"
done

# disk usage function
echo -e "${dcolor}\nDISK USAGE${NC}"
nano_letter=$(grep "nano" /proc/mounts | sed -E s/".+path=(.):.+"/"\1"/ | tr '[:upper:]' '[:lower:]')
array_disk=("/")
for disk in /mnt/* ; do
<<<<<<< HEAD
<<<<<<< HEAD
  if [[ -d $disk && ! ${disk} == *wsl* ]] && grep -qs "$disk" /proc/mounts; then
    if [ $disk != "/mnt/${nano_letter}" ]; then
      array_disk+=("${disk}")
    fi
=======
=======
>>>>>>> d425b5f413ca2506d983280ec682dde61138dc78
  if [[ -d $disk && ! ${disk} == *wsl* ]]; then
    array_disk+=("${disk}")
>>>>>>> d425b5f413ca2506d983280ec682dde61138dc78
  fi
done

for disk in "${array_disk[@]}"; do
  disk_usage ${disk}
done

# Conda envs display
if [ -n $CONDA_EXE ]; then
  echo -e "${dcolor}\nCONDA ENVS${NC}"
  echo $lst_conda_env | fold -s -w 80 | sed -E s/"^"/"  "/g
fi