#!/bin/bash

# ************************************************************************* #
# *****                           FUNCTIONS                           ***** #
# ************************************************************************* #
function banner {
  echo -ne "╭───────────────────────────────────────────────────────────────────╮\n|"
  echo -ne "${colortitle} ＲＮＡｓｅｑ   ｗｏｒｋｆｌｏｗ${NC}                                   "
  echo -ne "|\n╰───────────────────────────────────────────────────────────────────╯\n"
}

function rjust {
  i=1
  repeat_space=$((67-${1}))
  while [ "$i" -le "${repeat_space}" ]; do echo -ne " " ; i=$(($i + 1)) ; done
  if [ "${2}" = true ]; then
    echo -e "|"
  else
    echo -ne "|"
  fi
}

function display_error {
  str_error=${1}
  bool_in_progress=${2}
  str_len_error=${#str_error}
  if [[ ${bool_in_progress} == true ]]; then echo -ne "\n╰───────────────────────────────────────────────────────────────────╯\n" ; fi 
  echo -ne "╭───────────────────────────────────────────────────────────────────╮\n| "
  echo -ne "${colorred}ERROR: ${NC}"
  echo -ne "┊ "
  echo -ne "${colorred}${str_error}${NC}"
  rjust $((${str_len_error}+10))
  echo -ne "\n╰───────────────────────────────────────────────────────────────────╯\n"
  exit 1
}

function usage {
    echo -e "╭───────────────────────────────────────────────────────────────────╮"
    echo -e "|"${colortitlel}$' USAGE: rnaseq_workflow.sh -r REF,REF -o DIR (-t INT -w DIR)'${NC}"       |"
    echo "|                                                                   |"
    echo -e "|"${colortitlel}$' Required options:'${NC}"                                                 |"
    echo "|"$'  -i Input FASTQ folder'"                                            |"
    echo "|"$'  -r Reference FASTA,GFF (could be multiple times)'"                 |"
    echo "|"$'     (FASTA=.fasta,.fna,.fa) (GFF=.gff,.gff3,.gtf)'"                 |"
    echo "|"$'  -o Output results folder'"                                         |"
    echo "|                                                                   |"
    echo -e "|"${colortitlel}$' Optional options:'${NC}"                                                 |"
    echo "|"$'  -t Number of threads'"                                             |"
    echo "|"$'     Default       : 0 (all)'"                                       |"
    echo "|"$'  -w Temporary folder'"                                              |"
    echo "|"$'     Default       : /tmp'"                                          |"
    echo "|                                                                   |"  
    echo -e "|"${colortitlel}$' Tool locations: '${NC}"                                                  |"
    echo "|"$' Specify following tool location if not in ${PATH}'"                 |"
    echo "|"$'  --fastp'"                                                          |"
    echo "|"$'  --bowtie'"                                                         |"    
    echo "|"$'  --htseq-count'"                                                    |"    
    echo "╰───────────────────────────────────────────────────────────────────╯"
}

function progress() {
    # progress percent text color
    local w=30 p=$1 n=$2 color=$3; shift
    echo -ne "| "
    # create a string of spaces, then change them to dots
    printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /.}
    # print those dots on a fixed-width space plus the percentage etc. 
    printf "\r\e[K|%-*s| %3d%%" "$w" "$dots" "$p"
    if [[ ! -z "${n}" ]]; then
      echo -ne "${color} (${n})\x1b[0m"
      rjust $((39+${#n})) false
    else
      rjust 36 false
    fi 
}

function parallel_progress() {
  new_arrayPid=()
  title_str=${1}
  total=${2}
  readarray -t running_pid <<<$(jobs -p)
  for pid in "${arrayPid[@]}"
    do
      if [[ " ${running_pid[*]} " =~ " ${pid} " ]]; then
        new_arrayPid+=(${pid})
      else
        ((cpt_done++))
      fi
  done
  arrayPid=("${new_arrayPid[@]}")   
  percent_done=$(( ${cpt_done}*100/${total} ))
  progress $percent_done
  title "rnaseq | ${title_str} (${percent_done}%%)"
}

function pwait() {
  while [ $(jobs -p | wc -l) -ge $1 ]; do
      sleep 1
  done
}

function summary {
  title "rnaseq | summary"
  echo -e "╭─INFO──────────────────────────────────────────────────────────────╮"
  # ***** DISK USAGE ***** #
  echo -ne "| ${colortitle}Output size :${NC}"
  SPINNY_FRAMES=( " calculating                                         |" " calculating .                                       |" " calculating ..                                      |" " calculating ...                                     |" " calculating ....                                    |" " calculating .....                                   |")
  spinny::start
  folder_size=$(du -hs ${path_dir_out} | cut -f 1)
  spinny::stop
  echo -ne " ${folder_size}"
  rjust $((15+${#folder_size})) true

  # ***** TIME ***** #
  # Time display
  elapsed=$(( SECONDS - start_time ))
  format_elapsed=$(printf '%dh:%dm:%ds\n' $((elapsed/3600)) $((elapsed%3600/60)) $((elapsed%60)))
  echo -ne "| ${colortitle}Elapsed time: ${NC}${format_elapsed}" ; rjust $((15+${#format_elapsed})) true

  # ***** CLEAN & DISPLAY ***** #
  # Remove temporary files
  rm -rf ${dir_tmp}
  # Final display
  echo -e "╰───────────────────────────────────────────────────────────────────╯\n"
  title "rnaseq | finished"
}






# ************************************************************************* #
# *****                        INITIALIZATION                         ***** #
# ************************************************************************* #
# Slurm path (sbatch --export all --mem 64GB --cpus-per-task=12 -o rnaseq.%N.%j.out -e rnaseq.%N.%j.err -p fast rnaseq_workflow.sh -i reads -r P115.fna,V115.fna -g P115.gff,V115.gff -o PICMI_RNASEQ_OUT)
if [ -n $SLURM_JOB_ID ] && [ "$SLURM_JOB_ID" != "" ]
  then
  slurm_bool=true
  job_id="$SLURM_JOB_ID"
  src_path=$(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d " " -f 1)
  source "`dirname \"$src_path\"`"/functions.sh
  source "`dirname \"$src_path\"`"/spinny.sh
  source "`dirname \"$src_path\"`"/slurm_env.sh
# bash rnaseq_workflow.sh -i reads -r P115.fna,V115.fna -g P115.gff,V115.gff -o PICMI_RNASEQ_OUT
else
  path_tmp="/tmp"
  threads=0
  source "`dirname \"$0\"`"/functions.sh
  source "`dirname \"$0\"`"/spinny.sh
fi
title "rnaseq workflow"
# ***** INITIALIZATION ***** #
# Variables
declare -A fastq_map
declare -A ref_fasta_map
declare -A ref_gff_map
declare -A ref_title_map
tmp_folder="/tmp"
htseqcount_args="--mode=union --stranded=yes --order=name --type=gene --minaqual=10 --idattr=locus_tag"
start_time=$SECONDS
# Tools paths
fastp="fastp"
bowtie="bowtie"
htseqcount="htseq-count"
# Colors
colortitle='\x1b[38;2;255;60;60m'
colortitlel='\x1b[38;2;255;128;128m'
colorred='\x1b[38;2;255;85;85m'
colorterm='\x1b[38;2;204;204;204m'
NC='\x1b[0m'
# Header
banner
# Display usage if any argument
if [[ ${#} -eq 0 ]]; then usage ; exit 1 ; fi
# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--fastp") set -- "$@" "-f" ;;
    "--bowtie") set -- "$@" "-b" ;;
    "--htseq-count") set -- "$@" "-c" ;;
    "-fastp") usage ; display_error "Invalid option: -fastp." false ;;
    "-bowtie") usage ; display_error "Invalid option: -bowtie." false ;;
    "-htseq-count") usage ; display_error "Invalid option: -htseq-count." false ;;
    *) set -- "$@" "$arg"
  esac
done
# list of arguments expected in the input
ref_fasta_list=""
optstring=":i:r:g:o:f:b:c:t:w:h"
cpt_ref=1
while getopts ${optstring} arg; do
  case ${arg} in
    h) usage ; exit 0 ;;
    i) path_dir_in="${OPTARG}" ;;
    r) ref_fasta_list="${ref_fasta_list}${OPTARG}#" ;;
    o) path_dir_out="${OPTARG}" ;;
    w) tmp_folder="${OPTARG}" ;;
    t) threads="${OPTARG}" ;;
    f) fastp="${OPTARG}" ;;
    b) bowtie="${OPTARG}" ;;
    c) htseqcount="${OPTARG}" ;;      
    :) usage ; display_error "Must supply an argument to -$OPTARG." false ; exit 1 ;;
    ?) usage ; display_error "Invalid option: -${OPTARG}." false ; exit 2 ;;
  esac
done


# Check missing required arguments
if [[ -z "${path_dir_in}" ]]; then usage ; display_error "Input FASTQ folder (-i)" false ; fi
if [[ -z "${ref_fasta_list}" ]]; then usage ; display_error "Reference FASTA/GFF is required (-r)" false ; fi
if [[ -z "${path_dir_out}" ]]; then usage ; display_error "Output results folder is required (-o)" false ; fi
# Check input fastq
for file in "$path_dir_in"/*.fastq "$path_dir_in"/*.fq "$path_dir_in"/*.fastq.gz "$path_dir_in"/*.fq.gz; do
  if [ -e "$file" ]; then
    filename="$(basename "$file" | sed 's/.fastq.gz//' | sed 's/.fq.gz//' | sed 's/.fastq//' | sed 's/.fq//')"
    fastq_map["$filename"]="$file"
  fi
done
if (( ${#fastq_map[@]} == 0 )); then usage ; display_error "Any input FASTQ found (-i)" false ; fi
# Check reference FASTA
cpt_ref=1
IFS='#' read -ra ref_array <<< "$ref_fasta_list"
for ref_couple in "${ref_array[@]}"; do
  pair1=$(echo ${ref_couple} | cut -d "," -f 1)
  pair2=$(echo ${ref_couple} | cut -d "," -f 2)
  ref_fasta=""
  ref_gff=""
  if [[ "$pair1" == *".fasta" ||  "$pair1" == *".fna" ||  "$pair1" == *".fa" ]]; then ref_fasta=${pair1} ; fi
  if [[ "$pair1" == *".gff" ||  "$pair1" == *".gtf" ||  "$pair1" == *".gff3" ]]; then ref_gff=${pair1} ; fi
  if [[ "$pair2" == *".fasta" ||  "$pair2" == *".fna" ||  "$pair2" == *".fa" ]]; then ref_fasta=${pair2} ; fi
  if [[ "$pair2" == *".gff" ||  "$pair2" == *".gtf" ||  "$pair2" == *".gff3" ]]; then ref_gff=${pair2} ; fi
  if [[ "$ref_fasta" == "" ]]; then usage ; display_error "Missing FASTA for reference '${ref_couple}'" false ; fi
  if [[ "$ref_gff" == "" ]]; then usage ; display_error "Missing GFF for reference '${ref_couple}'" false ; fi
  if [[ ! -f $ref_fasta ]]; then usage ; display_error "Reference FASTA not found '${ref_fasta}'" false ; fi
  if [[ ! -f $ref_gff ]]; then usage ; display_error "Reference GFF not found '${ref_gff}'" false ; fi
  ref_fasta_map["${cpt_ref}"]=$ref_fasta
  ref_gff_map["${cpt_ref}"]=$ref_gff
  ref_title_map["${cpt_ref}"]=$(basename $ref_fasta | sed s/".fasta"/""/ | sed s/".fna"/""/ | sed s/".fa"/""/)
  ((cpt_ref++))
done
# Check arguments format
if [[ ! -z "${threads}" && ! "${threads}" =~ ^[0-9,]+$ ]]; then usage ; display_error "Number of threads is invalid (must be integer)" false ; fi
if [ $threads == 0 ]; then threads=$(grep -c ^processor /proc/cpuinfo) ; fi
# Check tools
if ! command -v ${fastp} &> /dev/null; then display_error "fastp not found (use \$PATH or specify it)" false ; fi
if ! command -v ${bowtie} &> /dev/null; then display_error "bowtie not found (use \$PATH or specify it)" false ; fi
if ! command -v ${htseqcount} &> /dev/null; then display_error "htseq-count not found (use \$PATH or specify it)" false ; fi
mkdir -p ${path_dir_out} 2>/dev/null
if [[ ! $? -eq 0 ]] ; then usage && display_error "Cannot create output directory (${path_dir_out})" false ; fi
# Log file
log="${path_dir_out}/rnaseq_workflow.log"
rm -f ${log}
touch ${log}
# Temporary folder and files
uuidgen=$(uuidgen | cut -d "-" -f 1,2)
dir_tmp="${tmp_folder}/rnaseq_${uuidgen}"
mkdir -p ${dir_tmp} 2>/dev/null
if [[ ! $? -eq 0 ]] ; then usage && display_error "Cannot create temp directory (${dir_tmp})" false ; fi





# # ************************************************************************* #
# # *****                         PREPROCESSING                         ***** #
# # ************************************************************************* #
# ***** DISPLAY INFOS ***** #
in=$(echo ${path_dir_in} | sed 's/.*\(.\{47\}\)/...\1/')
nb_fastq=${#fastq_map[@]}
nb_fastq_ref=$((${#fastq_map[@]}*${#ref_fasta_map[@]}))
echo -e "╭─INIT──────────────────────────────────────────────────────────────╮"
echo -ne "| ${colortitle}FASTQ folder: ${NC}${in}" ; rjust $((15+${#in})) true
echo -ne "| ${colortitle}FASTQ found : ${NC}${nb_fastq}" ; rjust $((15+${#nb_fastq})) true
for (( ref_num=1; ref_num<=${#ref_title_map[@]}; ref_num++ )); do
    if [[ $ref_num -lt 10 ]]; then
      echo -ne "| ${colortitle}Reference ${ref_num} : ${NC}${ref_title_map[$ref_num]}"
    else
      echo -ne "| ${colortitle}Reference ${ref_num}: ${NC}${ref_title_map[$ref_num]}"
    fi 
    rjust $((15+${#ref_title_map[$ref_num]})) true
done
echo -ne "| ${colortitle}Output dir  : ${NC}${path_dir_out}" ; rjust $((15+${#path_dir_out})) true
echo -ne "| ${colortitle}TMP folder  : ${NC}${dir_tmp}" ; rjust $((15+${#dir_tmp})) true
echo -ne "| ${colortitle}Threads     : ${NC}${threads}" ; rjust $((15+${#threads})) true
echo -e "╰───────────────────────────────────────────────────────────────────╯"





# ************************************************************************* #
# *****                          PROCESSING                           ***** #
# ************************************************************************* #
echo -e "╭─PROCESSING────────────────────────────────────────────────────────╮"

# ***** CREATE BOWTIE INDEX ***** #
for (( ref_num=1; ref_num<=${#ref_title_map[@]}; ref_num++ )); do
    if [[ $ref_num -lt 10 ]]; then
      echo -ne "| ${colortitle}Indexing ${ref_num}  :${NC}"
    else
      echo -ne "| ${colortitle}Indexing ${ref_num} :${NC}"
    fi 
    ref_name=${ref_title_map[$ref_num]}
    ref_idx_path="${dir_tmp}/${ref_title_map[$ref_num]}"
    if [[ ! -f  "${ref_idx_path}.1.ebwt" ]]; then
        SPINNY_FRAMES=( " reference indexing                                  |" " reference indexing .                                |" " reference indexing ..                               |" " reference indexing ...                              |" " reference indexing ....                             |" " reference indexing .....                            |")
        spinny::start
        bowtie-build --threads ${threads} -f ${ref_fasta_map[$ref_num]} ${ref_idx_path} >> ${log} 2>&1
        spinny::stop
    fi
    echo -ne " ${ref_name}" ; rjust $((15+${#ref_name})) true
done

# ***** TRIMMING FASTQ *****#
echo -ne "| ${colortitle}Trimming    :${NC}${colortitlel} in progress${NC}" ; rjust 26 true
cpt_done=0
for fastq_name in "${!fastq_map[@]}"; do
  path_fastq=${fastq_map[$fastq_name]}
  path_trim=${path_dir_out}/${fastq_name}_trim.fq.gz
  # Trimming
  if [[ ! -f  ${path_trim} ]]; then
      fastp -i ${path_fastq} -o ${path_trim} --length_required 36 --cut_right_window_size 4 --cut_right_mean_quality 20 --thread ${threads} >> ${log} 2>&1
  fi
  ((cpt_done++))
  percent_done=$(( ${cpt_done}*100/${#fastq_map[@]} ))
  progress ${percent_done} "${fastq_name:0:25}" ${colorterm}
done
echo -ne '\e[2A\e[K\n'
echo -ne "| ${colortitle}Trimming    :${NC} done" ; rjust 19 true

# ***** MAPPING FASTQ *****#
echo -ne "| ${colortitle}Mapping     :${NC}${colortitlel} in progress${NC}" ; rjust 26 true
cpt_done=0
for fastq_name in "${!fastq_map[@]}"; do
    for (( ref_num=1; ref_num<=${#ref_title_map[@]}; ref_num++ )); do
        ref_name=${ref_title_map[$ref_num]}
        ref_idx_path="${dir_tmp}/${ref_name}"
        path_trim=${path_dir_out}/${fastq_name}_trim.fq.gz
        path_sam=${path_dir_out}/${fastq_name}_${ref_name}.sam
        # Mapping
        if [[ ! -f  ${path_sam} ]]; then
            bowtie -S --threads ${threads} ${ref_idx_path} ${path_trim} > ${path_sam} 2>>${log}
        fi
        ((cpt_done++))
        percent_done=$(( ${cpt_done}*100/${nb_fastq_ref}))
        progress ${percent_done} "${fastq_name:0:12}|${ref_name:0:12}" ${colorterm}
    done
done
echo -ne '\e[2A\e[K\n'
echo -ne "| ${colortitle}Mapping     :${NC} done" ; rjust 19 true


# ***** HTSEQ COUNT *****#
echo -ne "| ${colortitle}Count       :${NC}${colortitlel} in progress${NC}" ; rjust 26 true
cpt_done=0
for fastq_name in "${!fastq_map[@]}"; do
    for (( ref_num=1; ref_num<=${#ref_title_map[@]}; ref_num++ )); do
        ref_name=${ref_title_map[$ref_num]}
        path_ref_gff=${ref_gff_map[$ref_num]}
        path_sam=${path_dir_out}/${fastq_name}_${ref_name}.sam
        path_count=${path_dir_out}/${fastq_name}_${ref_name}_count.sam
        # htseq-count
        if [[ ! -f  ${path_sam} ]]; then
            htseq-count ${htseqcount_args} ${path_sam} ${path_ref_gff} > ${path_count} 2>>${log} &
            arrayPid+=($!)
            pwait ${threads} ; parallel_progress "htseq-count" "${nb_fastq_ref}"
        fi
    done
done
# Final wait & progress
while [ $(jobs -p | wc -l) -gt 1 ]; do parallel_progress "htseq-count" "${nb_fastq_ref}" ; sleep 1 ; done
echo -ne '\e[2A\e[K\n'
echo -ne "| ${colortitle}Count       :${NC} done" ; rjust 19 true
# End processing
echo -e "╰───────────────────────────────────────────────────────────────────╯"
summary false
