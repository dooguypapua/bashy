#!/bin/bash

# ************************************************************************* #
# *****                           FUNCTIONS                           ***** #
# ************************************************************************* #
function display_error {
  str_error=${1}
  bool_in_progress=${2}
  first_print=${3}
  str_len_error=${#str_error}
  if [ "${first_print}" != "" ] ; then echo -ne "|     ⮡ ${colorred}${first_print}${NC}" ; rjust $((${#first_print}+7)) true ; fi
  if [[ ${bool_in_progress} == true ]]; then echo -ne "╰───────────────────────────────────────────────────────────────────────────╯\n" ; fi 
  spinny::stop
  if [ "${last_cmd}" != "" ]
    then echo -e " ${colorred}ERROR: ${str_error}\n${NC}" ; echo ${last_cmd}
  else echo -e " ${colorred}ERROR: ${str_error}${NC}\n"
  fi
  exit 1
}

function banner {
  echo -ne "╭───────────────────────────────────────────────────────────────────────────╮\n|"
  echo -ne "${colortitle} ｍｙＳｃａｆｆｏｌｄｅｒ${NC}                                                  "
  echo -ne "|\n╰───────────────────────────────────────────────────────────────────────────╯\n"
}

function rjust {
  i=1
  repeat_space=$((75-${1}))
  while [ "$i" -le "${repeat_space}" ]; do echo -ne " " ; i=$(($i + 1)) ; done
  if [ "${2}" = true ]; then
    echo -e "|"
  else
    echo -ne "|"
  fi
}

function usage {
    echo -e "╭───────────────────────────────────────────────────────────────────────────╮"
    echo -e "|"${colortitlel}$' USAGE: myScaffolder.sh -i INPUT (-t INT -k INT)'${NC}"                           |"
    echo "|                                                                           |"
    echo -e "|"${colortitlel}$' Required options:'${NC}"                                                         |"
    echo "|"$'  -i, --in       Tabulated file with required inputs'"                       |"
    echo "|"$'  [ NAME | OUTPUT | CONTIGS | R1 FASTQ | R2 FASTQ | REFERENCE(S) ]'"         |"
    echo "|                                                                           |"
    echo -e "|"${colortitlel}$' Optional options:'${NC}"                                                         |"
    echo "|"$'  -c, --qcov     blastn qcov threshold [90]'"                                |"
    echo "|"$'  -k, --kmer     Kmer size use by Abyss-PE [64]'"                            |"
    echo "|"$'  -t, --threads  Number of threads [0 (max -2)]'"                            |"
    echo "|"$'  -m, --memory   Memory in Go [0 (max -2Go)]'"                               |"
    echo "|"$'  -w, --work     Temporary folder [/tmp]'"                                   |"
    echo "|                                                                           |"  
    echo -e "|"${colortitlel}$' Tool locations: '${NC}"                                                          |"
    echo "|"$' Specify following tool location if not in ${PATH}'"                         |"
    echo "|"$'  --fastp'"                                                                  |"
    echo "|"$'  --abysspe'"                                                                |"    
    echo "|"$'  --abysssealer'"                                                            |"    
    echo "|"$'  --spades'"                                                                 |"    
    echo "|"$'  --blastn'"                                                                 |"
    echo "|"$'  --nucmer'"                                                                 |"
    echo "|"$'  --show-coords'"                                                            |"
    echo "|"$'  --ragtag'"                                                                 |"    
    echo "|"$'  --seqkit'"                                                                 |"
    echo "|"$'  --fasta2camsa_points'"                                                     |"
    echo "|"$'  --run_camsa'"                                                              |"
    echo "|"$'  --camsa_points2fasta'"                                                     |"
    echo "|"$'  --jq'"                                                                     |"
    echo "╰───────────────────────────────────────────────────────────────────────────╯"
    echo -e "╭───────────────────────────────────────────────────────────────────────────╮"
    echo -e "|       fastp abyss|spades blastn  ragtag abysssealer blastn   camsa        |"
    echo -e "|       ╭────╮ ╭────────╮ ╭──────╮ ╭─────╮ ╭───────╮ ╭──────╮ ╭─────╮       |"
    echo -e "| FASTQ→|TRIM|→|ASSEMBLE|→|ASSIGN|→|SCAFF|→|GAPFILL|→|FILTER|→|MERGE|→FASTA |"
    echo -e "|       ╰────╯ ╰────────╯ ╰──────╯ ╰─────╯ ╰───────╯ ╰──────╯ ╰─────╯       |"
    echo -e "|                         ╭──────╮ ╭─────╮           ╭──────╮ ╭─────╮       |"
    echo -e "| FASTA------------------→|ASSIGN|→|SCAFF|----------→|FILTER|→|MERGE|→FASTA |"
    echo -e "|                         ╰──────╯ ╰─────╯           ╰──────╯ ╰─────╯       |"
    echo -e "╰───────────────────────────────────────────────────────────────────────────╯\n"
}

function make_check_json {
  in=${1}
  tmp=${2}
  cat ${in} | sed -e :a -e 's|\t\t|\t.\t|;ta' > "${tmp}/input.txt"

  # ***** CREATE JSON *****#
  JSON="{"
  while read -r line; do
        if [[ ${line:0:1} != "#" ]]; then
          IFS=$'\t'
          split_line=($line)
          name=${split_line[0]}
          output=${split_line[1]}
          contigs=${split_line[2]}
          path_r1=${split_line[3]}
          path_r2=${split_line[4]}
          ref=${split_line[5]}
          IFS=$','
          lst_ref=(${ref})
          IFS=$'\t'
          JSON="${JSON}\n\"${name}\":"
          JSON="${JSON}\t{\n"
          JSON="${JSON}\t\"output\":\"${output}\",\n"
          JSON="${JSON}\t\"contigs\":\"${contigs}\",\n"
          JSON="${JSON}\t\"path_r1\":\"${path_r1}\",\n"
          JSON="${JSON}\t\"path_r2\":\"${path_r2}\",\n"
          JSON="${JSON}\t\"ref\":["
          for ref in "${lst_ref[@]}"; do JSON="${JSON}\"${ref}\","; done
          JSON="${JSON%?}]\n"
          JSON="${JSON}\t},"
        fi
      done < ${tmp}/input.txt
  JSON="${JSON%?}}\n"
  echo -e ${JSON} | ${JQ} --tab > ${tmp}/input.json
  # ***** CHECK DATA *****#
  declare -a array_strain="($(${JQ} -r 'keys[] | @sh' ${tmp}/input.json))"
  str_error_input=""
  path_input_stats=${tmp}/input_stats.txt
  for strain in "${array_strain[@]}"
    do
    # Output writeable
    path_out=$(${JQ} -r ".\"${strain}\".output" ${path_json})
    mkdir -p ${path_out} 2>/dev/null
    if [[ ! $? -eq 0 ]]; then str_error_input=${str_error_input}"\n        Cannot create output directory (${path_out})" ; fi
    # Input contigs
    contigs=$(${JQ} -r ".\"${strain}\".contigs" ${path_json})
    if [[ "$contigs" != "." ]] && [[ ! -f "${contigs}" ]]; then str_error_input=${str_error_input}"\n        ${strain} contigs file not found \"${contigs}\"." ; fi
    # Input FASTQ
    path_r1=$(${JQ} -r ".\"${strain}\".path_r1" ${path_json})
    if [[ "$path_r1" != "." ]] && [[ ! -f "${path_r1}" ]]
      then str_error_input=${str_error_input}"\n        ${strain} path_r1 file not found \"${path_r1}\"."
    fi
    path_r2=$(${JQ} -r ".\"${strain}\".path_r2" ${path_json})
    if [[ "$path_r2" != "." ]] && [[ ! -f "${path_r2}" ]]; then str_error_input=${str_error_input}"\n        ${strain} path_r2 file not found \"${path_r2}\"." ; fi
    # Required Contigs OR FASTQ
    if [[ "$contigs" == "." ]]
      then
        if [[ "$path_r1" == "." || "$path_r2" == "." ]]; then str_error_input=${str_error_input}"\n        ${strain} required contigs or fastq file."
        else echo "FASTQ" >> ${path_input_stats}
        fi
      else
        if [[ "$path_r1" != "." && "$path_r2" != "." ]]; then echo "FASTQ" >> ${path_input_stats}
        else echo "CONTIGS" >> ${path_input_stats}
        fi
    fi
    # Reference(s)
    declare -a lst_ref="($(${JQ} -r ".\"${strain}\".ref | @sh" ${path_json}))"
    for ref in "${lst_ref[@]}"
      do
      if [[ ! -f "${ref}" ]]
        then str_error_input=${str_error_input}"\n        ${strain} reference file not found \"${ref}\"."
        else echo "REF#${ref}" >> ${path_input_stats}
      fi
    done
  done
  # Display errors
  if [[ "${str_error_input}" != "" ]]; then usage ; display_error ${str_error_input:10} false ; fi
}

function nucmer_cov_filter {
  in=${1}
  qcov=${2}
  out=${3}
  declare -A array_query_cov
  declare -A array_query_len
  # Parse show-coords output
  while read -r line; do
    if [[ ${line:0:1} != "#" ]]; then
      IFS=$'\t'
      split_line=($line)
      qalignlen=${split_line[5]}
      qlen=${split_line[7]}
      query=${split_line[11]}
      array_query_len[$query]=${qlen}
      if [[ -z "${array_query_cov[$query]}" ]]
        then array_query_cov[$query]=${qalignlen}
      else array_query_cov[$query]=$(( ${array_query_cov[$query]} + $qalignlen ))
      fi
    fi
  done < ${in}
  # Count overall reference coverage petr query
  for key in "${!array_query_cov[@]}"
    do
      cov=$(( ${array_query_cov[$key]} * 100 / ${array_query_len[$key]} ))
      if [ $cov -ge $qcov ] ; then echo $key >> ${out} ; fi
  done
}





# ************************************************************************* #
# *****                        INITIALIZATION                         ***** #
# ************************************************************************* #
source "`dirname \"$0\"`"/functions.sh
source "`dirname \"$0\"`"/spinny.sh
title "myScaffolder"
# Variables
path_in=""
qcov=90
kmer=64
last_cmd=""
# Slurm JOB (sbatch --mem 32GB -o myscaff.%N.%j.out -e myscaff.%N.%j.err --cpus-per-task=12 -p fast myScaffolder.sh -i myscaff.conf)
if command -v sbatch &> /dev/null
then
  path_tmp="/shared/projects/gv/dgoudenege/tmp"
  threads=$(printenv SLURM_CPUS_ON_NODE)
  memory=$(sacct --format=reqmem -j 35384664 | tail -n 1 | grep -Po "\d+")
  slurm_bool=true
  module load fastp/0.23.1
  module load abyss/2.2.1
  module load spades/3.15.2
  module load blast/2.13.0
  module load ragtag/1.0.2
  module load seqkit/2.1.0
  module load jq/1.6
  export PYTHONPATH=/home/umr8227/gv/dgoudenege/.local/lib/python3.8/site-packages/
  FASTA2CAMSA=/home/umr8227/gv/dgoudenege/.local/lib/python3.8/site-packages/camsa/utils/fasta/fasta2camsa_points.py
  RUN_CAMSA=/home/umr8227/gv/dgoudenege/.local/lib/python3.8/site-packages/camsa/run_camsa.py
  CAMSA_POINTS2FASTA=/home/umr8227/gv/dgoudenege/.local/lib/python3.8/site-packages/camsa/utils/fasta/camsa_points2fasta.py
# Local JOB
else slurm_bool=false
  path_tmp="/tmp"
  threads=0
  memory=0
  FASTA2CAMSA=$(which fasta2camsa_points.py)
  RUN_CAMSA=$(which run_camsa.py)
  CAMSA_POINTS2FASTA=$(which camsa_points2fasta.py)
fi
# Tools $PATH
COMPRESSOR=$(which pigz) # gzip
FASTP=$(which fastp)
ABYSSPE=$(which abyss-pe)
ABYSSSEALER=$(which abyss-sealer)
SPADES=$(which spades.py)
NUCMER=$(which nucmer)
SHOWCOORDS=$(which show-coords)
BLASTN=$(which blastn)
RAGTAG=$(which ragtag.py)
SEQKIT=$(which seqkit)
JQ=$(which jq)
# Colors
colortitle='\x1b[38;2;0;205;255m'
colortitlel='\x1b[38;2;19;167;199m'
colorred='\x1b[38;2;255;85;85m'
colorterm='\x1b[38;2;204;204;204m'
NC='\x1b[0m'
decoration=$(printf '=%.0s' {1..100})
# Header
banner
# Display usage if any argument
if [[ ${#} -eq 0 ]]; then usage ; exit 0 ; fi
# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--in") set -- "$@" "-i" ;;
    "--thread") set -- "$@" "-t" ;;
    "--mem") set -- "$@" "-m" ;;
    "--kmer") set -- "$@" "-k" ;;
    "--qcov") set -- "$@" "-c" ;;
    "--work") set -- "$@" "-w" ;;
    "--help") set -- "$@" "-h" ;;
    "-help") set -- "$@" "-h" ;;
    "--h") set -- "$@" "-h" ;;
    "--fastp") set -- "$@" "-a" ;;
    "--abysspe") set -- "$@" "-b" ;;
    "--abysssealer") set -- "$@" "-d" ;;
    "--spades") set -- "$@" "-e" ;;
    "--nucmer") set -- "$@" "-f" ;;
    "--show-coords") set -- "$@" "-g" ;;
    "--blastn") set -- "$@" "-j" ;;
    "--ragtag") set -- "$@" "-l" ;;
    "--seqkit") set -- "$@" "-n" ;;
    "--fasta2camsa_pointsy") set -- "$@" "-o" ;;
    "--run_camsa") set -- "$@" "-p" ;;
    "--camsa_points2fasta") set -- "$@" "-q" ;;
    "--jq") set -- "$@" "-r" ;;
    # Bad colon check
    "-in") usage ; display_error "Invalid option: -in." false ;;
    "-thread") usage ; display_error "Invalid option: -thread." false ;;
    "-kmer") usage ; display_error "Invalid option: -kmer." false ;;
    "-qcov") usage ; display_error "Invalid option: -qcov." false ;;
    "-fastp") usage ; display_error "Invalid option: -fastp." false ;;
    "-abysspe") usage ; display_error "Invalid option: -abysspe." false ;;
    "-abysssealer") usage ; display_error "Invalid option: -abysssealer." false ;;
    "-spades") usage ; display_error "Invalid option: -spades." false ;;
    "-nucmer") usage ; display_error "Invalid option: -nucmer." false ;;
    "-show-coords") usage ; display_error "Invalid option: -show-coords." false ;;
    "-blastn") usage ; display_error "Invalid option: -blastn." false ;;
    "-ragtag") usage ; display_error "Invalid option: -ragtag." false ;;
    "-seqkit") usage ; display_error "Invalid option: -seqkit." false ;;
    "--fasta2camsa_pointsy") usage ; display_error "Invalid option: -fasta2camsa_points" false ;;
    "--run_camsa") usage ; display_error "Invalid option: -run_camsa." false ;;
    "--camsa_points2fasta") usage ; display_error "Invalid option: -camsa_points2fasta." false ;;
    "-jq") usage ; display_error "Invalid option: -jq." false ;;
    *) set -- "$@" "$arg"
  esac
done
# list of arguments expected in the input
optstring=":i:t:c:k:w:h:a:b:d:e:f:g:j:l:n:o:p:q:r"
while getopts ${optstring} arg; do
  case ${arg} in
    h) usage ; exit 0 ;;
    i) path_in="${OPTARG}" ;;
    t) threads="${OPTARG}" ;;
    m) memory="${OPTARG}" ;;
    c) qcov="${OPTARG}" ;;
    k) kmer="${OPTARG}" ;;
    w) path_tmp="${OPTARG}" ;;
    a) FASTP="${OPTARG}" ;;
    b) ABYSSPE="${OPTARG}" ;;
    d) ABYSSSEALER="${OPTARG}" ;;
    e) SPADES="${OPTARG}" ;;
    f) NUCMER="${OPTARG}" ;;
    g) SHOWCOORDS="${OPTARG}" ;;
    j) BLASTN="${OPTARG}" ;;
    l) RAGTAG="${OPTARG}" ;;
    n) SEQKIT="${OPTARG}" ;;
    o) FASTA2CAMSA="${OPTARG}" ;;
    p) RUN_CAMSA="${OPTARG}" ;;
    q) CAMSA_POINTS2FASTA="${OPTARG}" ;;
    r) JQ="${OPTARG}" ;;
    :) usage ; display_error "Must supply an argument to -$OPTARG." false ; exit 1 ;;
    ?) usage ; display_error "Invalid option: -${OPTARG}." false ; exit 2 ;;
  esac
done
# Check missing required arguments
if [[ -z "${path_in}" ]]; then usage ; display_error "Input file is required (-i --in)" false ; fi
if [ ! -f "${path_in}" ]; then usage ; display_error "Input file not found." false ; fi
# Check arguments format
if [[ ! -z "${threads}" && ! "${threads}" =~ ^[0-9,]+$ ]]; then usage ; display_error "Number of threads is invalid (must be integer)" false ; fi
if [ $threads == 0 ]; then threads=$(expr $(grep -c ^processor /proc/cpuinfo) - 2); fi
if [[ ! -z "${memory}" && ! "${memory}" =~ ^[0-9,]+$ ]]; then usage ; display_error "Number of memory is invalid (must be integer)" false ; fi
if [ $memory == 0 ]; then memory=$(expr $(grep "MemTotal" /proc/meminfo | awk '{print $2}') / 1024 / 1024 - 6) ; fi
if [[ ! -z "${qcov}" && ! "${qcov}" =~ ^[0-9,]+$ ]]; then usage ; display_error "qcov size is invalid (must be integer)" false ; fi
if [[ ! -z "${kmer}" && ! "${kmer}" =~ ^[0-9,]+$ ]]; then usage ; display_error "Kmer size is invalid (must be integer)" false ; fi
# Check tools
if ! command -v ${JQ} &> /dev/null; then usage ; display_error "jq not found (use \$PATH or specify it)" false ; fi
if ! command -v ${FASTP} &> /dev/null; then usage ; display_error "fastp not found (use \$PATH or specify it)" false ; fi
if ! command -v ${ABYSSPE} &> /dev/null; then usage ; display_error "abyss-pe not found (use \$PATH or specify it)" false ; fi
if ! command -v ${ABYSSSEALER} &> /dev/null; then usage ; display_error "abyss-sealer not found (use \$PATH or specify it)" false ; fi
if ! command -v ${SPADES} &> /dev/null; then usage ; display_error "spades.py not found (use \$PATH or specify it)" false ; fi
if ! command -v ${NUCMER} &> /dev/null; then usage ; display_error "nucmer not found (use \$PATH or specify it)" false ; fi
if ! command -v ${SHOWCOORDS} &> /dev/null; then usage ; display_error "show-coords not found (use \$PATH or specify it)" false ; fi
if ! command -v ${BLASTN} &> /dev/null; then usage ; display_error "blastn not found (use \$PATH or specify it)" false ; fi
if ! command -v ${RAGTAG} &> /dev/null; then usage ; display_error "ragtag.py not found (use \$PATH or specify it)" false ; fi
if ! command -v ${SEQKIT} &> /dev/null; then usage ; display_error "seqkit not found (use \$PATH or specify it)" false ; fi
if [ ! command -v ${FASTA2CAMSA} &> /dev/null ] && [ ! -f ${FASTA2CAMSA} ]; then usage ; display_error "fasta2camsa_points.py not found (use \$PATH or specify it)" false ; fi
if [ ! command -v ${RUN_CAMSA} &> /dev/null ] && [ ! -f ${RUN_CAMSA} ]; then usage ; display_error "run_camsa.py not found (use \$PATH or specify it)" false ; fi
if [ ! command -v ${CAMSA_POINTS2FASTA} &> /dev/null ] && [ ! -f ${CAMSA_POINTS2FASTA} ]; then usage ; display_error "camsa_points2fasta.py not found (use \$PATH or specify it)" false ; fi
if [[ "$COMPRESSOR" == *"pigz"* ]]; then COMPRESSOR="${COMPRESSOR} -p ${threads}" ; fi
# Temporary folder
uuidgen=$(uuidgen | cut -d "-" -f 1,2)
dir_tmp="${path_tmp}/scf_${uuidgen}"
mkdir -p ${dir_tmp} 2>/dev/null
if [[ ! $? -eq 0 ]] ; then usage && display_error "Cannot create temp directory (${dir_tmp})" false ; fi
mkdir -p ${dir_tmp}/ref
# Input JSON file
path_json="${dir_tmp}/input.json"
# Log file
path_log=${dir_tmp}/log.txt
if [ ! -f "${path_log}" ]; then touch ${path_log} ; fi
# Longest replicon name
longest_replicon_name=12





# ************************************************************************* #
# *****                         PREPROCESSING                         ***** #
# ************************************************************************* #
echo -e "╭─INIT──────────────────────────────────────────────────────────────────────╮"
# Make input JSON
SPINNY_FRAMES=( "| Read input                                                                |" "| Read input  .                                                             |" "| Read input  ..                                                            |" "| Read input  ...                                                           |" "| Read input  ....                                                          |" "| Read input  .....                                                         |")
spinny::start
make_check_json ${path_in} ${dir_tmp}
declare -a array_strain="($(${JQ} -r 'keys[] | @sh' ${path_json}))"
declare -a array_ref="($(grep "REF#" ${tmp}/input_stats.txt | sort -u | cut -d "#" -f 2))"
spinny::stop
echo -ne "| ${colortitle}Check input  : ${NC}done" ; rjust "20" true
# Display infos
nb_strain=${#array_strain[@]}
nb_from_fastq=$(grep -c "FASTQ" ${tmp}/input_stats.txt)
nb_from_contigs=$(grep -c "CONTIGS" ${tmp}/input_stats.txt)
nb_diff_ref=$(grep "REF#" ${tmp}/input_stats.txt | sort -u | wc -l)
in=$(echo ${path_in} | sed 's/.*\(.\{47\}\)/...\1/')
tmp=$(echo ${dir_tmp} | sed 's/.*\(.\{47\}\)/...\1/')
echo -ne "| ${colortitle}Input        : ${NC}${in}" ; rjust $((16+${#in})) true
echo -ne "| ${colortitle}Organism     : ${NC}${nb_strain}" ; rjust $((16+${#nb_strain})) true
echo -ne "| ${colortitle}From FASTQ   : ${NC}${nb_from_fastq}" ; rjust $((16+${#nb_from_fastq})) true
echo -ne "| ${colortitle}From contigs : ${NC}${nb_from_contigs}" ; rjust $((16+${#nb_from_contigs})) true
echo -ne "| ${colortitle}Reference    : ${NC}${nb_diff_ref}" ; rjust $((16+${#nb_diff_ref})) true
echo -ne "| ${colortitle}qcov %       : ${NC}${qcov}" ; rjust $((16+${#qcov})) true
echo -ne "| ${colortitle}Kmer size    : ${NC}${kmer}" ; rjust $((16+${#kmer})) true
echo -ne "| ${colortitle}Threads      : ${NC}${threads}" ; rjust $((16+${#threads})) true
echo -ne "| ${colortitle}Memory       : ${NC}${memory}G" ; rjust $((17+${#memory})) true
echo -ne "| ${colortitle}Working dir  : ${NC}${tmp}" ; rjust $((16+${#tmp})) true
echo -e "╰───────────────────────────────────────────────────────────────────────────╯"





# ************************************************************************* #
# *****                          PROCESSING                           ***** #
# ************************************************************************* #
echo -e "╭─PROCESSING────────────────────────────────────────────────────────────────╮"

# ***** Split REF FASTA per replicon ***** #
# Header must be like ">replicon [orgName]"
echo -ne "| ${colortitle}Split reference${NC}" ; rjust 16 true
for path_ref in "${array_ref[@]}"
  do
  ref_name=$(basename ${path_ref} | sed -e s/".fasta"/""/g -e s/".fna"/""/g)
  mkdir -p ${dir_tmp}/ref/${ref_name}
  cd ${dir_tmp}/ref/${ref_name}
  sed -E s/"\s.+"/""/g ${path_ref} | awk '/^>/ {OUT=substr($0,2) ".fasta";print " ">OUT}; OUT{print >OUT}'
  sed -i '1{/^ $/d}' * # remove first empty line
  echo -ne "|   ${colortitlel}${ref_name}${NC}" ; rjust $((${#ref_name}+3)) true
done

# ***** BROWSE INPUT ***** #
echo -ne "| ${colortitle}Scaffolding${NC}" ; rjust 12 true
for strain in "${array_strain[@]}"
  do
  path_out=$(${JQ} -r ".\"${strain}\""."output" ${path_json})
  mkdir -p ${path_out}
  path_ctg=$(${JQ} -r ".\"${strain}\""."contigs" ${path_json})
  path_r1=$(${JQ} -r ".\"${strain}\""."path_r1" ${path_json})
  path_r2=$(${JQ} -r ".\"${strain}\""."path_r2" ${path_json})
  declare -a array_strain_ref="($(${JQ} -r ".\"${strain}\""."ref" ${path_json} | tr -d '[]," '))"
  path_tmp="${dir_tmp}/${strain}"
  mkdir -p ${path_tmp}
  echo -ne "|   ${colortitlel}${strain}${NC}" ; rjust $((${#strain}+3)) true
  echo -e "\n\n${decoration}\nSample: ${strain}\n${decoration}" >> ${path_log}

  #***** FASTQ INPUT *****#
  if [[ "$path_r1" != "." ]]
    then
    # Trimming path
    path_outdir_fastq=${path_out}/Trimming
    mkdir -p ${path_outdir_fastq}
    path_trim_r1=${path_outdir_fastq}/r1trim.fastq.gz
    path_trim_r2=${path_outdir_fastq}/r2trim.fastq.gz
    path_untrim=${path_outdir_fastq}/untrim.fastq.gz

    # ***** REFORMAT fastQ header ***** # (if missing /1 /2 in read name)
    badheader1=$(zcat ${path_r1} | head -n 1 | grep -c -P "^@.+/1")
    if [[ ! -s "${path_trim_r1}" || ! -s "${path_trim_r2}" || ! -s "${path_untrim}" ]] && [[ "${badheader1}" != "1" ]]
      then
      SPINNY_FRAMES=( "|     ⮡ reformat R1                                                         |" "|     ⮡ reformat R1  .                                                      |" "|     ⮡ reformat R1  ..                                                     |" "|     ⮡ reformat R1  ...                                                    |" "|     ⮡ reformat R1  ....                                                   |" "|     ⮡ reformat R1  .....                                                  |")
      spinny::start
      path_reformat_r1=${path_tmp}/reformat_R1.fastq.gz
      last_cmd=$(echo "zcat ${path_r1} | paste - - | sed 's/^\(\S*\)\.1/\1\/1/' | sed -E 's/\s.+\\t/\\t/' | tr \"\\t\" \"\\n\" | ${COMPRESSOR} > ${path_reformat_r1}" | tee -a ${path_log})
      zcat ${path_r1} | paste - - | sed 's/^\(\S*\)\.1/\1\/1/' | sed -E 's/\s.+\t/\t/' | tr "\t" "\n" | eval ${COMPRESSOR} > ${path_reformat_r1} 2>>${path_log} || display_error "reformat R1 for '${strain}'" true "reformat "
      path_r1=${path_reformat_r1}
      spinny::stop
      echo -ne "|     ⮡ reformat_R1 " ; rjust "19" true
    fi
    badheader2=$(zcat ${path_r2} | head -n 1 | grep -c -P "^@.+/2")
    if [[ ! -s "${path_trim_r1}" || ! -s "${path_trim_r2}" || ! -s "${path_untrim}" ]] && [[ "${badheader2}" != "1" ]]
      then
      SPINNY_FRAMES=( "|     ⮡ reformat R2                                                         |" "|     ⮡ reformat R2  .                                                      |" "|     ⮡ reformat R2  ..                                                     |" "|     ⮡ reformat R2  ...                                                    |" "|     ⮡ reformat R2  ....                                                   |" "|     ⮡ reformat R2  .....                                                  |")
      spinny::start
      path_reformat_r2=${path_tmp}/reformat_R2.fastq.gz
      last_cmd=$(echo "zcat ${path_r2} | paste - - | sed 's/^\(\S*\)\.1/\1\/1/' | sed -E 's/\s.+\\t/\\t/' | tr \"\\t\" \"\\n\" | ${COMPRESSOR} > ${path_reformat_r2}" | tee -a ${path_log})
      zcat ${path_r2} | paste - - | sed 's/^\(\S*\)\.2/\1\/2/' | sed -E 's/\s.+\t/\t/' | tr "\t" "\n" | eval ${COMPRESSOR} > ${path_reformat_r2} 2>>${path_log} || display_error "reformat R2 for '${strain}'" true "reformat "
      path_r2=${path_reformat_r2}
      spinny::stop
      echo -ne "|     ⮡ reformat_R2 " ; rjust "19" true
    fi

    # ***** FASTP *****#
    if [[ ! -s "${path_trim_r1}" || ! -s "${path_trim_r2}" || ! -s "${path_untrim}" ]]
      then
      SPINNY_FRAMES=( "|     ⮡ fastp                                                               |" "|     ⮡ fastp  .                                                            |" "|     ⮡ fastp  ..                                                           |" "|     ⮡ fastp  ...                                                          |" "|     ⮡ fastp  ....                                                         |" "|     ⮡ fastp  .....                                                        |")
      spinny::start
      last_cmd=$(echo "" | tee -a ${path_log})
      ${FASTP} -i ${path_r1} -I ${path_r2} -o ${path_trim_r1} -O ${path_trim_r2} --unpaired1 ${path_untrim} --unpaired2 ${path_untrim} --detect_adapter_for_pe --length_required 36 --cut_right_window_size 4 --cut_right_mean_quality 20 --thread ${threads} --json ${path_tmp}/fastp.json --html ${path_tmp}/fastp.html >> ${path_log} 2>&1 || display_error "fastp  for '${strain}'" true "fastp "
      spinny::stop
    fi
    echo -ne "|     ⮡ fastp " ; rjust "13" true

    # ***** ABySS-pe *****#
    path_outdir_assembly=${path_out}/Assembly
    mkdir -p ${path_outdir_assembly}
    path_abyss_contigs=${path_outdir_assembly}/abyss-pe-contigs.fasta
    path_abyss_scaffolds=${path_outdir_assembly}/abyss-pe-scaffolds.fasta
    if [[ ! -s "${path_abyss_contigs}" || ! -s "${path_abyss_scaffolds}" ]]
      then
      SPINNY_FRAMES=( "|     ⮡ abyss-pe                                                            |" "|     ⮡ abyss-pe .                                                          |" "|     ⮡ abyss-pe ..                                                         |" "|     ⮡ abyss-pe ...                                                        |" "|     ⮡ abyss-pe ....                                                       |" "|     ⮡ abyss-pe .....                                                      |")
      spinny::start
      cd ${path_tmp}
      last_cmd=$(echo "${ABYSSPE} j=${threads} k=${kmer} B=${memory}G name=abyss-pe in=\"${path_trim_r1} ${path_trim_r2}\"" | tee -a ${path_log})
      ${ABYSSPE} j=${threads} k=${kmer} B=${memory}G name=abyss-pe in="${path_trim_r1} ${path_trim_r2}" >> ${path_log} 2>&1 || display_error "abyss-pe for '${strain}'" true "abyss-pe"
      cp abyss-pe-contigs.fa ${path_abyss_contigs}
      cp abyss-pe-scaffolds.fa ${path_abyss_scaffolds}
      spinny::stop
    fi
    echo -ne "|     ⮡ abyss-pe" ; rjust "15" true

    # ***** SPADES *****# with '--trusted-contigs' (+filter size >=1000)
    path_final_contigs=${path_outdir_assembly}/spades-contigs.fasta
    if [ ! -s "${path_final_contigs}" ]
      then
      SPINNY_FRAMES=( "|     ⮡ spades                                                              |" "|     ⮡ spades .                                                            |" "|     ⮡ spades ..                                                           |" "|     ⮡ spades ...                                                          |" "|     ⮡ spades ....                                                         |" "|     ⮡ spades .....                                                        |")
      spinny::start
      last_cmd=$(echo "${SPADES} --isolate -1 ${path_trim_r1} -2 ${path_trim_r2} -s ${path_untrim} --cov-cutoff off -k 21,33,55,77 -m ${memory} --threads ${threads} -o ${path_tmp}/spades --trusted-contigs ${path_abyss_contigs}" | tee -a ${path_log})
      ${SPADES} --isolate -1 ${path_trim_r1} -2 ${path_trim_r2} -s ${path_untrim} --cov-cutoff off -k 21,33,55,77 -m ${memory} --threads ${threads} -o ${path_tmp}/spades --trusted-contigs ${path_abyss_contigs} >> ${path_log} 2>&1 || display_error "spades for '${strain}'" true "spades"
      awk -v n=1000 '/^>/{ if(l>n) print b; b=$0;l=0;next } {l+=length;b=b ORS $0}END{if(l>n) print b }' ${path_tmp}/spades/contigs.fasta | awk 'BEGIN {RS=">";FS="\n";OFS=""} NR>1 {print ">"$1; $1=""; print}' > ${path_final_contigs}
      spinny::stop
    fi
    echo -ne "|     ⮡ spades" ; rjust "13" true
  
  #***** CONTIGS INPUT *****#
  else
    path_final_contigs=${path_out}/src-contigs.fasta
    cp ${path_ctg} ${path_final_contigs}
  fi

  #***** FOREACH REFERENCE ***** #
  path_outdir_assign=${path_out}/Assignment
  mkdir -p ${path_outdir_assign}
  path_outdir_ragtag=${path_out}/Ragtag
  mkdir -p ${path_outdir_ragtag}
  for ref in "${array_strain_ref[@]}"
    do
    ref_name=$(basename ${ref} | sed s/".fasta"/""/g)
    echo -ne "|     [REF] ${ref_name}" ; rjust $((${#ref_name}+11)) true
    path_dir_ref=${dir_tmp}/ref/${ref_name}

    # ***** CHECK missing replicon output files *****#
    not_assign=false
    not_ragtag=false
    for replicon in ${path_dir_ref}/*.fasta
      do replicon_name=$(basename ${replicon} | sed s/".fasta"/""/)
      path_assign_out=${path_outdir_assign}/${ref_name}_${replicon_name}.fasta
      path_ragtag_out=${path_outdir_ragtag}/${ref_name}_${replicon_name}.fasta
      if [ ! -s "${path_assign_out}" ] ; then not_assign=true ; fi
      if [ ! -s "${path_ragtag_out}" ] ; then not_ragtag=true ; fi
    done

    # ***** ASSIGN CONTIGS to replicon *****#
    if [ "$not_assign" = true ]
      then
      SPINNY_FRAMES=( "|       ⮡ assign contigs                                                    |" "|       ⮡ assign contigs .                                                  |" "|       ⮡ assign contigs ..                                                 |" "|       ⮡ assign contigs ...                                                |" "|       ⮡ assign contigs ....                                               |" "|       ⮡ assign contigs .....                                              |")
      spinny::start
      for replicon in ${path_dir_ref}/*.fasta
        do replicon_name=$(basename ${replicon} | sed s/".fasta"/""/)
        path_nucmer_out=${path_tmp}/${ref_name}_${replicon_name}_nucmer
        last_cmd=$(echo "${NUCMER} --maxmatch -c 100 -p ${path_nucmer_out} ${replicon} ${path_final_contigs}" | tee -a ${path_log})
        ${NUCMER} --maxmatch -c 100 -p ${path_nucmer_out} ${replicon} ${path_final_contigs} || display_error "nucmer for '${strain}' and replicon '${ref_name}_${replicon_name}'" true "assign contigs"
        last_cmd=$(echo "${SHOWCOORDS} -q -c -l -T -b -H ${path_nucmer_out}.delta | sort -u -k3,4 -k5" | tee -a ${path_log})
        ${SHOWCOORDS} -q -c -l -T -b -H ${path_nucmer_out}.delta | sort -u -k3,4 -k5 > ${path_nucmer_out}.coords || display_error "show-coords for '${strain}' and replicon '${ref_name}_${replicon_name}'" true "assign contigs"
        nucmer_cov_filter ${path_nucmer_out}.coords ${qcov} ${path_tmp}/${ref_name}_${replicon_name}_contigs.txt || display_error "coords filtering for '${strain}' and replicon '${ref_name}_${replicon_name}'" true "assign contigs"
      done
      # Get unassigned contigs
      cat ${path_tmp}/${ref_name}_*_contigs.txt | sort -u > ${path_tmp}/${ref_name}_found_contigs.txt
      grep ">" ${path_final_contigs} | tr -d ">" | grep -v --file=${path_tmp}/${ref_name}_found_contigs.txt > ${path_tmp}/${ref_name}_unassigned_contigs.txt
      grep -a -A 1 --file=${path_tmp}/${ref_name}_unassigned_contigs.txt ${path_final_contigs} | sed -E s/"\r"/"\n"/g | sed ':a;N;$!ba;s/--\n//g' > ${path_tmp}/${ref_name}_unassigned_contigs.fasta
      # Add not found to all replicon & split
      for replicon in ${path_dir_ref}/*.fasta
        do replicon_name=$(basename ${replicon} | sed s/".fasta"/""/)
        if [ -s "${path_tmp}/${ref_name}_${replicon_name}_contigs.txt" ] # case of any contig found for a replicon
          then
          grep -a -A 1 --file=${path_tmp}/${ref_name}_${replicon_name}_contigs.txt ${path_final_contigs} | sed -E s/"\r"/"\n"/g | sed ':a;N;$!ba;s/--\n//g' > ${path_outdir_assign}/${ref_name}_${replicon_name}.fasta
        fi          
      done
      spinny::stop
    fi
    echo -ne "|       ⮡ assign contigs" ; rjust "23" true  

    # ***** RagTag *****#
    if [ "$not_ragtag" = true ]
      then
      SPINNY_FRAMES=( "|       ⮡ ragtag                                                            |" "|       ⮡ ragtag .                                                          |" "|       ⮡ ragtag ..                                                         |" "|       ⮡ ragtag ...                                                        |" "|       ⮡ ragtag ....                                                       |" "|       ⮡ ragtag .....                                                      |")
      spinny::start
      for replicon in ${path_dir_ref}/*.fasta
        do replicon_name=$(basename ${replicon} | sed s/".fasta"/""/)
        last_cmd=$(echo "${RAGTAG} scaffold -o ${path_tmp}/ragtag_${ref_name}_${replicon_name} ${replicon} ${path_outdir_assign}/${ref_name}_${replicon_name}.fasta" | tee -a ${path_log})
        ${RAGTAG} scaffold -o ${path_tmp}/ragtag_${ref_name}_${replicon_name} ${replicon} ${path_outdir_assign}/${ref_name}_${replicon_name}.fasta >> ${path_log} 2>&1 || display_error "ragtag for '${strain}' and replicon '${replicon_name}'" true "ragtag"
        if [ -f "${path_tmp}/ragtag_${ref_name}_${replicon_name}/ragtag.scaffold.fasta" ]
          then cp ${path_tmp}/ragtag_${ref_name}_${replicon_name}/ragtag.scaffold.fasta ${path_outdir_ragtag}/${ref_name}_${replicon_name}.fasta
        fi
      done
      rm -f ${path_outdir_assign}/*.fai
      spinny::stop
    fi
    echo -ne "|       ⮡ ragtag" ; rjust "15" true

    # ***** ABySS-sealer (if reads available) *****#
    path_outdir_scaffold=${path_out}/Scaffolds
    mkdir -p ${path_outdir_scaffold}
    path_scaffold_out=${path_outdir_scaffold}/${ref_name}_abyss-sealer.fasta
    if [[ "$path_r1" != "." ]]
      then
      if [ ! -s "${path_scaffold_out}" ]
        then
        SPINNY_FRAMES=( "|       ⮡ abyss-sealer                                                      |" "|       ⮡ abyss-sealer .                                                    |" "|       ⮡ abyss-sealer ..                                                   |" "|       ⮡ abyss-sealer ...                                                  |" "|       ⮡ abyss-sealer ....                                                 |" "|       ⮡ abyss-sealer .....                                                |")
        spinny::start
        for replicon in ${path_dir_ref}/*.fasta
          do
          replicon_name=$(basename ${replicon} | sed s/".fasta"/""/)
          if [ -f "${path_outdir_ragtag}/${ref_name}_${replicon_name}.fasta" ]
            then
            last_cmd=$(echo "${ABYSSSEALER} -b${memory}G -k64 -k96 -k128 -k192 --threads ${threads} -o ${path_tmp}/${ref_name}_${replicon_name}_sealer_scaffolds -S ${path_outdir_ragtag}/${ref_name}_${replicon_name}.fasta ${path_trim_r1} ${path_trim_r2}" | tee -a ${path_log})
            ${ABYSSSEALER} -b${memory}G -k64 -k96 -k128 -k192 --threads ${threads} -o ${path_tmp}/${ref_name}_${replicon_name}_sealer_scaffolds -S ${path_outdir_ragtag}/${ref_name}_${replicon_name}.fasta ${path_trim_r1} ${path_trim_r2} >> ${path_log} 2>&1 || display_error "abyss-sealer for '${strain}' and replicon '${replicon_name}'" true "abyss-sealer"
          fi  
        done
        cat ${path_tmp}/${ref_name}_*_sealer_scaffolds_scaffold.fa > ${path_tmp}/${ref_name}_sealer.fasta
        last_cmd=$(echo "${SEQKIT} rmdup -n ${path_tmp}/${ref_name}_sealer.fasta 2>>${path_log} | awk 'BEGIN {RS=\">\";FS=\"\\n\";OFS=""} NR>1 {print \">\"$1; $1=\"\"; print}' > ${path_scaffold_out}" | tee -a ${path_log})
        ${SEQKIT} rmdup -n ${path_tmp}/${ref_name}_sealer.fasta 2>>${path_log} | awk 'BEGIN {RS=">";FS="\n";OFS=""} NR>1 {print ">"$1; $1=""; print}' > ${path_scaffold_out} 2>>${path_log} || display_error "rmdup for '${strain} ref:${ref_name}'" true "abyss-sealer"
        spinny::stop
      fi
      echo -ne "|       ⮡ abyss-sealer" ; rjust "21" true
    # If no reads
    else
      path_scaffold_out=${path_outdir_scaffold}/${ref_name}_ragtag.fasta
      cat ${path_outdir_ragtag}/${ref_name}_*.fasta > ${path_scaffold_out}
    fi

    # ***** FILTERING *****# contigs due to repeat
    path_scaffolds_out=${path_outdir_scaffold}/${ref_name}_scaffolds.fasta
    path_contigs_out=${path_outdir_scaffold}/${ref_name}_contigs.fasta
    path_contigs_scaffolds_out=${path_outdir_scaffold}/${ref_name}_contigs_scaffolds.fasta
    if [ ! -s "${path_contigs_out}" ]
      then
      SPINNY_FRAMES=( "|       ⮡ filtering                                                         |" "|       ⮡ filtering .                                                       |" "|       ⮡ filtering ..                                                      |" "|       ⮡ filtering ...                                                     |" "|       ⮡ filtering ....                                                    |" "|       ⮡ filtering .....                                                   |")
      spinny::start
      sed -E ':a;N;$!ba;s/\n[^>]/#/g' ${path_scaffold_out} | grep -P ">.+_RagTag" | sed s/"#"/"\n"/g  | sed s/"_RagTag"/"_scaffold"/g > ${path_scaffolds_out}
      sed -E ':a;N;$!ba;s/\n[^>]/#/g' ${path_scaffold_out} | grep -v -P ">.+_RagTag" | sed s/" "/""/g | sed s/"#"/"\n"/g > ${path_tmp}/others_scaffolds.fasta
      # Add unassigned contigs to final contigs file
      cat ${path_tmp}/${ref_name}_unassigned_contigs.fasta > ${path_contigs_out}    
      last_cmd=$(echo "${BLASTN} -task blastn -query ${path_tmp}/others_scaffolds.fasta -subject ${path_out}/${strain}_scaffolds.fasta -max_hsps 5 -max_target_seqs 1 -qcov_hsp_perc ${qcov} -outfmt \"6 delim=; qseqid\" -evalue 0.001 | sort -u > ${path_tmp}/repeated_contigs.txt" | tee -a ${path_log})
      ${BLASTN} -task blastn -query ${path_tmp}/others_scaffolds.fasta -subject ${path_outdir_scaffold}/${ref_name}_scaffolds.fasta -max_hsps 5 -max_target_seqs 1 -qcov_hsp_perc ${qcov} -outfmt "6 delim=; qseqid" -evalue 0.001 2>>${path_log} | sort -u > ${path_tmp}/repeated_contigs.txt || display_error "filtering for '${strain}'" true "filtering"
      sed -E ':a;N;$!ba;s/\n[^>]/#/g' ${path_tmp}/others_scaffolds.fasta | grep -v --file=${path_tmp}/repeated_contigs.txt | sed s/" "/""/g | sort -u | sed s/"#"/"\n"/g | awk '/^>/{sub(">.+_length", ">contig"++i "_length")}1' >> ${path_contigs_out}
      cat ${path_scaffolds_out} ${path_contigs_out} > ${path_contigs_scaffolds_out}
      spinny::stop
    fi
    echo -ne "|       ⮡ filtering" ; rjust "18" true
  done # end for ref

  # ***** CAMSA *****#
  path_final_out=${path_out}/${strain}_scaffolds.fasta
  if [ ! -s "${path_final_out}" ]
    then
    if [[ ${#array_strain_ref[@]} -eq 1 ]]
      then
      cp ${path_outdir_scaffold}/${ref_name}_contigs_scaffolds.fasta ${path_final_out}
    else
      SPINNY_FRAMES=( "|     ⮡ merging                                                             |" "|     ⮡ merging .                                                           |" "|     ⮡ merging ..                                                          |" "|     ⮡ merging ...                                                         |" "|     ⮡ merging ....                                                        |" "|     ⮡ merging .....                                                       |")
      spinny::start
      cd ${path_tmp}
      ref_name=$(basename ${array_strain_ref[0]} | sed s/".fasta"/""/)
      path_contigs_scaffolds_ref=${path_outdir_scaffold}/${ref_name}_contigs_scaffolds.fasta
      path_tmp_merged_camsa=${path_tmp}/merged_camsa.fasta
      for ((i=1; i< ${#array_strain_ref[@]}; i++ ))
        do
        target_name=$(basename ${array_strain_ref[$i]} | sed s/".fasta"/""/)
        path_contigs_scaffolds_ref=${path_outdir_scaffold}/${target_name}_contigs_scaffolds.fasta
        last_cmd=$(echo "python3 ${FASTA2CAMSA} ${path_contigs_scaffolds_ref} ${path_contigs_scaffolds_ref} -o scaffolds_points" | tee -a ${path_log})
        python3 ${FASTA2CAMSA} ${path_contigs_scaffolds_ref} ${path_contigs_scaffolds_ref} -o scaffolds_points 2>>${path_log} || display_error "merging for '${strain}'" true "merging"
        last_cmd=$(echo python3 "${RUN_CAMSA} scaffolds_points/${target_name}_contigs_scaffolds.camsa.points -o ." | tee -a ${path_log})
        python3 ${RUN_CAMSA} scaffolds_points/${target_name}"_contigs_scaffolds.camsa.points" -o . 2>>${path_log} || display_error "merging for '${strain}'" true "merging"
        last_cmd=$(echo "python3 ${CAMSA_POINTS2FASTA} --allow-singletons --points merged/merged.camsa.points --fasta ${path_contigs_scaffolds_ref} -o ${path_tmp_merged_camsa}" | tee -a ${path_log})
        python3 ${CAMSA_POINTS2FASTA} --allow-singletons --points merged/merged.camsa.points --fasta ${path_contigs_scaffolds_ref} -o ${path_tmp_merged_camsa} 2>>${path_log} || display_error "merging for '${strain}'" true "merging"
        path_tmp_merged_camsa=${path_contigs_scaffolds_ref}
      done
      awk 'BEGIN {RS=">";FS="\n"} NR>1 {seq=""; for (i=2;i<=NF;i++) seq=seq$i; print ">"$1"\n"seq}' ${path_tmp_merged_camsa} > ${path_final_out}
      spinny::stop
      echo -ne "|       ⮡ merging" ; rjust "16" true
    fi
  fi

  # ***** STATS *****#
  path_stats_out=${path_out}/${strain}_scaffolds_stats.txt
  if [ ! -s "${path_stats_out}" ]
    then
    SPINNY_FRAMES=( "|     ⮡ statistics                                                          |" "|     ⮡ statistics .                                                        |" "|     ⮡ statistics ..                                                       |" "|     ⮡ statistics ...                                                      |" "|     ⮡ statistics ....                                                     |" "|     ⮡ statistics .....                                                    |")
    spinny::start
    previousTag=""
    stats=""
    nbContig=0
    lenContig=0
    while read -r line; do
      if [[ ${line:0:1} == ">" ]]; then
        previousTag=$(echo ${line} | sed s/">"/""/)
      else
        if [[ ${previousTag} == *"scaffold"* ]]; then stats=$(echo "${stats}${previousTag};${#line}\n")
        else nbContig=$((nbContig+1)) ; lenContig=$((lenContig+${#line}))
        fi
      fi
    done < ${path_final_out}
    if [[ $nbContig -gt 0 ]] ; then stats=$(echo "${stats}${nbContig} contigs;${lenContig}\n") ; fi
    echo -e $stats > ${path_stats_out}
    spinny::stop
  fi
  echo -ne "|     ⮡ statistics" ; rjust "17" true 

done # end for strain
echo -e "╰───────────────────────────────────────────────────────────────────────────╯"

# Longest replicon name
for replicon in ${dir_tmp}/ref/*/*.fasta
  do replicon_name=$(basename ${replicon} | sed s/".fasta"/""/)
  if [ ${#replicon_name} -gt ${longest_replicon_name} ] ; then longest_replicon_name=${#replicon_name} ; fi
done
# ***** STATS DISPLAY *****#
echo -e "╭─STATISTICS────────────────────────────────────────────────────────────────╮"
for strain in "${array_strain[@]}"
  do
  path_out=$(${JQ} -r ".\"${strain}\""."output" ${path_json})
  path_stats_out=${path_out}/${strain}_scaffolds_stats.txt
  echo -ne "| ${colortitle}${strain}${NC}" ; rjust $((${#strain}+1)) true
  if [[ ! -s ${path_stats_out} ]]
    then echo -ne "|     ⮡ ${colorred}Error${NC}" ; rjust 12 true 
  else
    # Scaffold
    echo -ne "|   ${colortitlel}Scaffolds${NC}" ; rjust 12 true
    while read -r line; do
      if [[ "$line" == *"scaffold"* ]]
      then
        replicon_name=$(echo -ne ${line} | sed -E s/"_scaffold.+"/""/g)
        size=$(echo -ne ${line} | sed -E s/"^.+;"/""/g)
        rjust=$(( ${longest_replicon_name}-${#replicon_name} ))
        for (( i=1; i<=$rjust; i++ )); do replicon_name="${replicon_name} " ; done
        replicon_name="${replicon_name}: ${size}"
        echo -ne "|     ⮡ ${replicon_name}"; rjust $((${#replicon_name}+7)) true 
      fi
    done < $path_stats_out
    # Contig
    echo -ne "|   ${colortitlel}Contigs${NC}" ; rjust 10 true
    contig_count=$(grep "contigs" ${path_stats_out} | sed -E s/" contigs.+"/""/g)
    contig_size=$(grep "contigs" ${path_stats_out} | sed -E s/"^.+;"/""/g)
    to_display="${contig_count} contigs"
    rjust=$(( ${longest_replicon_name}-${#to_display} ))
    for (( i=1; i<=$rjust; i++ )); do to_display="${to_display} " ; done
    to_display="${to_display}: ${contig_size}"
    echo -ne "|     ⮡ ${to_display}"; rjust $((${#to_display}+7)) true 
  fi
done
echo -e "╰───────────────────────────────────────────────────────────────────────────╯"


# Remove temp folder
rm -rf ${dir_tmp}
