#!/usr/bin/env bash


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
  export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
  text=${1}
  justify=$((58-${#text}))
  if (( $justify % 2 == 0 ))
    then
    ljust=$(($justify / 2))
    rjust=$ljust
  else
    ljust=$(($justify / 2))
    rjust=$(($ljust + 1))
  fi
  printf '\033]0;'".%s%${ljust}s${text}%s%${rjust}s."'\a'
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
  title "┌∩┐(◣_◢)┌∩┐"
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
  if [[ "${commit_desc}" == "" ]]
    then commit_desc=$(date '+%Y-%m-%d')
  fi 
  src_path=$(pwd)
  cd ${path}
  git add *
  git commit -m "\"${commit_desc}\""
  git push https://${token}@github.com/dooguypapua/${repo}.git
  cd ${src_path}
}