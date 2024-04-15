#!/usr/bin/env bash


#***** Fast basename *****#
function get_base() {
  set -- "${1%"${1##*[!/]}"}"
  printf '%s\n' "${1##*/}"
}


#***** Fast list files in folder*****#
function scandir() {
  scan_folder="${1}"
  output_file="${2}"
  threads=$(($(nproc) - 2))  
  temp_file=$(mktemp)
  rm -f $output_file
  # Get files list
  parallel -j $threads ls -RU1 ::: $scan_folder > $temp_file
  # Convert to absolute path
  current_path=""
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      if [[ $line == *":" ]]; then
        current_path="${line%:}"  # Supprime le dernier caractère ":"
      elif [ -n "$current_path" ]; then
        echo "${current_path}/${line}" >> "$output_file"
      fi
    fi
  done < "$temp_file"
  rm -f temp_file
}


#***** Add border to text *****#
function border () {
    local str="$*"      # Put all arguments into single string
    local len=${#str}
    local i
    for (( i = 0; i < len + 4; ++i )); do
        printf '-'
    done
    printf "\n| $str |\n"
    for (( i = 0; i < len + 4; ++i )); do
        printf '-'
    done
    echo
}

#***** Terminal title *****#
function title () {
  if [ -n "$starttitle" ]; then
    if [ $# -eq 0 ]; then
      text=${starttitle}
    else
      if [[ "${1}" == *"${starttitle}"* ]]; then
        text="${starttitle}"
      else
        text="${starttitle}   -   ${1}"
      fi
    fi
  else
    text="┌∩┐(◣_◢)┌∩┐"
  fi
  justify=$((29-${#text}))
  if (( $justify % 2 == 0 ))
    then
    ljust=$(($justify / 2))
    rjust=$ljust
  else
    ljust=$(($justify / 2))
    rjust=$(($ljust + 1))
  fi
  term=$(basename "$(cat "/proc/$PPID/comm")") || term=""
  if [[ "$myrelease" == "fedora" ]]; then
    title=$(printf '\033]0;'"%s%${ljust}s${text}%s%${rjust}s"'\a')
    export PS1='\[\e]0;${title}\a\]'${PS1}
  elif [[ "$term" == *"gnome-terminal"* ]]; then
    printf "\033]0;${text}\a"
  else
    printf '\033]0;'".%s%${ljust}s${text}%s%${rjust}s."'\a'
  fi
  export currenttitle="$(echo "$1" | sed s/"✓  "/""/ | sed s/"X  "/""/)"
}

#***** Toast notify *****#
function toast () {
  powershell.exe -NonInteractive -NoProfile -command New-BurntToastNotification -Text $1 -AppLogo \"C:\\Users\\dgoudenege\\Pictures\\Icone\\EVE-icon.png\"
  title "$1"
}

#***** Script replay *****#
function replay () {
  cmd=${1}
  out=${2}
  script -q -c "${cmd}" --timing=${out}.tm ${out}.rec
  query_duration=10
  elapse_time=$(awk '{sum+=$1;}END{print sum;}' /tmp/timing.tm | cut -d "." -f 1)
  divisor=$(( $elapse_time / $query_duration ))
  scriptreplay --divisor ${divisor} --timing=/tmp/timing.tm /tmp/script.rec
}

#***** Blink functions *****#
function blinkon () {
  if [ "$?" = 0 ] ; then 
    powershell.exe -NonInteractive -NoProfile -command "Import-Module PowerBlink ; Initialize-Blink1Devices ; Set-Blink1Color -DeviceNumber 0 -ColorR 0 -ColorG 85 -ColorB 0"
  else
    powershell.exe -NonInteractive -NoProfile -command "Import-Module PowerBlink ; Initialize-Blink1Devices ; Set-Blink1Color -DeviceNumber 0 -ColorR 85 -ColorG 0 -ColorB 0"
  fi
}

function blinkoff () {
  powershell.exe -NonInteractive -NoProfile -command "Import-Module PowerBlink ; Initialize-Blink1Devices ; Set-Blink1Color -DeviceNumber 0 -ColorR \"\" -ColorG \"\" -ColorB \"\""
}

#***** Reverse complement *****#
function rc() {
    echo $1 | tr ACGTacgt TGCAtgca | rev
}


#***** Pretty table print *****#
function printTable() {
  local -r delimiter="${1}"
  local -r data="$(removeEmptyLines "${2}")"
  if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
  then
      local -r numberOfLines="$(wc -l <<< "${data}")"
      if [[ "${numberOfLines}" -gt '0' ]]
      then
          local table=''
          local i=1
          for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
          do
              local line=''
              line="$(sed "${i}q;d" <<< "${data}")"
              local numberOfColumns='0'
              numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"
              # Add Line Delimiter
              if [[ "${i}" -eq '1' ]]
              then
                  table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
              fi
              # Add Header Or Body
              table="${table}\n"
              local j=1
              for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
              do
                  if [[ ""${delimiter}"" == "\t" ]]
                      then table="${table}$(printf '#| %s' "$(cut -f "${j}" <<< "${line}")")"
                      else table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                  fi
              done
              table="${table}#|\n"
              # Add Line Delimiter
              if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
              then
                  table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
              fi
          done
          if [[ "$(isEmptyString "${table}")" = 'false' ]]
          then
              echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
          fi
      fi
  fi
}

function removeEmptyLines() {
  local -r content="${1}"
  echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString() {
  local -r string="${1}"
  local -r numberToRepeat="${2}"
  if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
  then
      local -r result="$(printf "%${numberToRepeat}s")"
      echo -e "${result// /${string}}"
  fi
}

function isEmptyString() {
  local -r string="${1}"
  if [[ "$(trimString "${string}")" = '' ]]
  then
      echo 'true' && return 0
  fi
  echo 'false' && return 1
}

function trimString(){
  local -r string="${1}"
  sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}


#***** Git folder *****# git_folder repo folder
function git_folder () {
  repo=${1}
  path=${2}
  token=${3}
  commit_desc=${4}
  # if any commit description use date
  if [[ "${commit_desc}" == "" ]]; then commit_desc=$(date '+%Y-%m-%d'); fi
  src_path=$(pwd)
  cd ${path}
  git add *
  git commit -m "${commit_desc}"
  git push https://${token}@github.com/dooguypapua/${repo}.git
  cd ${src_path}
}


#***** Convert text to unicode *****#
function convert_to_unicode() {
    input="$1"
    output=""
    for ((i = 0; i < ${#input}; i++)); do
        char="${input:$i:1}"
        case "$char" in
            A) output+="𝗔" ;;
            B) output+="𝗕" ;;
            C) output+="𝗖" ;;
            D) output+="𝗗" ;;
            E) output+="𝗘" ;;
            F) output+="𝗙" ;;
            G) output+="𝗚" ;;
            H) output+="𝗛" ;;
            I) output+="𝗜" ;;
            J) output+="𝗝" ;;
            K) output+="𝗞" ;;
            L) output+="𝗟" ;;
            M) output+="𝗠" ;;
            N) output+="𝗡" ;;
            O) output+="𝗢" ;;
            P) output+="𝗣" ;;
            Q) output+="𝗤" ;;
            R) output+="𝗥" ;;
            S) output+="𝗦" ;;
            T) output+="𝗧" ;;
            U) output+="𝗨" ;;
            V) output+="𝗩" ;;
            W) output+="𝗪" ;;
            X) output+="𝗫" ;;
            Y) output+="𝗬" ;;
            Z) output+="𝗭" ;;
            a) output+="𝗮" ;;
            b) output+="𝗯" ;;
            c) output+="𝗰" ;;
            d) output+="𝗱" ;;
            e) output+="𝗲" ;;
            f) output+="𝗳" ;;
            g) output+="𝗴" ;;
            h) output+="𝗵" ;;
            i) output+="𝗶" ;;
            j) output+="𝗷" ;;
            k) output+="𝗸" ;;
            l) output+="𝗹" ;;
            m) output+="𝗺" ;;
            n) output+="𝗻" ;;
            o) output+="𝗼" ;;
            p) output+="𝗽" ;;
            q) output+="𝗾" ;;
            r) output+="𝗿" ;;
            s) output+="𝘀" ;;
            t) output+="𝘁" ;;
            u) output+="𝘂" ;;
            v) output+="𝘃" ;;
            w) output+="𝘄" ;;
            x) output+="𝘅" ;;
            y) output+="𝘆" ;;
            z) output+="𝘇" ;;
            *) output+="$char" ;;
        esac
    done
    echo "$output"
}