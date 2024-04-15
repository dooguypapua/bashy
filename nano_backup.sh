#!/bin/bash


myDirLst=("Data" "Desktop" "Dev_prog" "Documents" "Pictures" "Taf" "Tools" "Videos" "Works")

# Initialization
pathNANO="/mnt/nano/backup/$(hostname)"
mkdir -p pathNANO
pathTMP="/tmp/Get-FolderSizeInfo"
pathHomeWin="C:\\Users\\dgoudenege"
pathHomeUnix="/mnt/c/Users/dgoudenege"
cpu=12

color0="\033[0m"
color1="\x1b[38;2;212;170;0m"
color2="\x1b[38;2;0;136;170m"
color3="\x1b[38;2;0;166;237m"
tableLine=" ---------------------------------------------------------------"
echo -e "${color3}● nanosync${color0}"

# Launch Get-FolderSizeInfo tasks
echo -e "  ... analyse"
mkdir -p /tmp/Get-FolderSizeInfo
rm -f /tmp/Get-FolderSizeInfo/*
for myDir in "${myDirLst[@]}"; do
    pathDIRwin="${pathHomeWin}\\$myDir"
    pathOUT="${pathTMP}/$(basename $myDir).txt"
    powershell.exe -Command "Invoke-Command -ScriptBlock { Get-FolderSizeInfo '${pathDIRwin}' -hidden | Format-Table -View gb }" | grep -A 2 "TotalSize" | tail -n 1 | sed -E s/"\s+"/"\t"/g > ${pathOUT} &
done
wait

# Parse Get-FolderSizeInfo results
echo -e "  ... summarize"
echo -e "${color1}      ${tableLine}"
printf "      | %-35s | %-10s | %-10s |\n" "PATH" "SIZE" "FILES"
echo -e "      ${tableLine}"
tot_size=0
tot_file=0
for myDir in "${myDirLst[@]}"; do
    pathOUT="${pathTMP}/$(basename ${myDir}).txt"
    foldername=$(cut -f 2 ${pathOUT})
    nbfiles=$(cut -f 3 ${pathOUT})
    tot_file=$((tot_file+nbfiles))
    size=$(printf "%.1f" "$(cut -f 4 ${pathOUT} | sed s/','/'.'/)")
    tot_size=$(awk -v num="$tot_size" -v inc="$(cut -f 4 ${pathOUT} | sed s/','/'.'/)" 'BEGIN { print num + inc }')
    echo -ne "${color1}      | "
    echo -ne "${color2}" ; printf "%-35s" "${foldername}"
    echo -ne "${color1} | "
    echo -ne "${color2}" ; printf "%-10s" "${size}Gb"
    echo -ne "${color1} | "
    echo -ne "${color2}" ; printf "%-10s" "${nbfiles}"
    echo -e "${color1} |"    
done
echo -e "${color1}      ${tableLine}"
echo -ne "      | "
printf "%-35s" "TOTAL"
echo -ne " | "
tot_size_f=$(printf "%.1f" "$tot_size")
printf "%-10s" "${tot_size_f}Gb"
echo -ne " | "
printf "%-10s" "${tot_file}"
echo -e " |"
echo -e "      ${tableLine}"


# Rclone
echo -e "${color0}  ... synchronize"
for myDir in "${myDirLst[@]}"; do
    pathSrc="${pathHomeUnix}/${myDir}"
    pathDist=${pathNANO}/${myDir}
    echo -e "${color1}      ${myDir}                     "
    echo -e "${color2}"
    rclone sync --progress --size-only --checkers=${cpu} --transfers=${cpu} ${pathSrc} ${pathDist} > ${pathTMP}/rclone.out 2>&1 &
    rclone_pid=$!
    # Display progress
    while ps -p $rclone_pid > /dev/null; do
        tac ${pathTMP}/rclone.out | grep -m 1 -Po "Transferred:.+ETA.+" | sed s/"Transferred:"/""/
        sleep 1  # Attendre avant de vérifier à nouveau la fin de rclone
        tput cuu1;tput el
    done
    if grep -q "Transferred:            0 / 0" ${pathTMP}/rclone.out ; then
        echo -e "${color2}        [uptodate]"
    else
        echo -e "${color2}        [ update ]"
    fi
done

echo -e "\033[0m"