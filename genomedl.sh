#!/bin/bash

# ************************************************************************* #
# *****                           FUNCTIONS                           ***** #
# ************************************************************************* #
function banner {
  echo -ne "╭───────────────────────────────────────────────────────────────────╮\n|"
  echo -ne "${colortitle} ＧｅｎｏｍｅＤＬ＋${NC}                                                "
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
    echo -e "|"${colortitlel}$' USAGE: genomedl.sh -o DIR -d DIV (-t INT -f DIR -w DIR -r INT)'${NC}"    |"
    echo "|                                                                   |"
    echo -e "|"${colortitlel}$' Required options:'${NC}"                                                 |"
    echo "|"$'  -o Output database folder'"                                        |"
    echo "|"$'  -d Division'"                                                      |"
    echo "|"$'     Bacteria      : "BCT"'"                                         |"
    echo "|"$'     Phages        : "PHG"'"                                         |"
    echo "|                                                                   |"
    echo -e "|"${colortitlel}$' Optional options:'${NC}"                                                 |"
    echo "|"$'  -i Taxonomic identifier(s) (comma-separated entries)'"             |"
    echo "|"$'     Caudovirales  : "28883"'"                                       |"
    echo "|"$'     Vibrionaceae  : "641"'"                                         |"
    echo "|"$'     V.crassostreae: "246167"'"                                      |"
    echo "|"$'     V.chagasii    : "170679"'"                                      |"
    echo "|"$'  -t Number of threads'"                                             |"
    echo "|"$'     Default       : 0 (all)'"                                       |"    
    echo "|"$'  -f Force rsync update'"                                            |"
    echo "|"$'     Default       : conservative'"                                  |"
    echo "|"$'  -w Temporary folder'"                                              |"
    echo "|"$'     Default       : /tmp'"                                          |"    
    echo "|"$'  -r Number of attempts to retry for rsync'"                         |"
    echo "|"$'     Default       : 5'"                                             |"
    echo "|"$'  -c Daemon connection timeout for rsync'"                           |"
    echo "|"$'     Default       : 5'"                                             |"
    echo "|"$'  -s Duration time stop (Xm, Xh, Xd)'"                               |"
    echo "|"$'     Default       : 0 (unlimited)'"                                 |"  
    echo "|                                                                   |"  
    echo -e "|"${colortitlel}$' Tool locations: '${NC}"                                                  |"
    echo "|"$' Specify following tool location if not in ${PATH}'"                 |"
    echo "|"$'  --prodigal'"                                                       |"
    echo "|"$'  --extractfeat'"                                                    |"    
    echo "|"$'  --diamond'"                                                        |"    
    echo "|"$'  --phanotate'"                                                      |"    
    echo "|"$'  --transeq'"                                                        |"    
    echo "╰───────────────────────────────────────────────────────────────────╯"
}

function summary {
  title "genomedl | summary"
  elapse_stop=${1}
  # ***** COUNT ***** #
  if [ ${elapse_stop} == true ]; then echo -e "\n╰───────────────────────────────────────────────────────────────────╯" ; fi
  echo -e "╭─INFO──────────────────────────────────────────────────────────────╮"
  if [ ${elapse_stop} == true ]; then echo -ne "| ${colorred}⛔ Duration interruption${NC}" ; rjust 25 true ; fi
  echo -ne "| ${colortitle}Total       : ${NC}${nb_total}" ; rjust $((15+${#nb_total})) true
  echo -ne "| ${colortitle}Sync        : ${NC}${nb_sync}" ; rjust $((15+${#nb_sync})) true
  if [[ "${cpt_download}" == "0" ]]; then
      echo -ne "| ${colortitle}Updated     : ${NC}any" ; rjust 18 true
  else
      echo -ne "| ${colortitle}Updated     : ${NC}${cpt_download}" ; rjust $((15+${#cpt_download})) true
  fi
  if [[ "${cpt_rsync_failed}" != "0" ]]; then echo -ne "| ${colorred}Failed      : ${cpt_rsync_failed}${NC}" ; rjust $((15+${#cpt_rsync_failed})) true ; fi

  # ***** DISK USAGE ***** #
  echo -ne "| ${colortitle}Folder size :${NC}"
  SPINNY_FRAMES=( " calculating                                         |" " calculating .                                       |" " calculating ..                                      |" " calculating ...                                     |" " calculating ....                                    |" " calculating .....                                   |")
  spinny::start
  folder_size=$(du -hs ${path_db} | cut -f 1)
  spinny::stop
  echo -ne " ${folder_size}"
  rjust $((15+${#folder_size})) true

  # ***** TIME ***** #
  # Time display
  elapsed=$(( SECONDS - start_time ))
  format_elapsed=$(printf '%dh:%dm:%ds\n' $((elapsed/3600)) $((elapsed%3600/60)) $((elapsed%60)))
  echo -ne "| ${colortitle}Elapsed time: ${NC}${format_elapsed}" ; rjust $((15+${#format_elapsed})) true
  # Save last update date
  echo $(date +"%d/%m/%y %H:%M:%S" | sed 's/.*/\u&/') > "${path_db}/release.txt"

  # ***** CLEAN & DISPLAY ***** #
  # Remove temporary files
  rm -rf ${dir_tmp}
  # Final display
  echo -e "╰───────────────────────────────────────────────────────────────────╯\n"
  title "genomedl | finished"
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
  title "genomedl | ${title_str} (${percent_done}%%)"
}

function pwait() {
  while [ $(jobs -p | wc -l) -ge $1 ]; do
      sleep 1
  done
}





# ************************************************************************* #
# *****                        INITIALIZATION                         ***** #
# ************************************************************************* #
source "`dirname \"$0\"`"/functions.sh
source "`dirname \"$0\"`"/spinny.sh
title "genomedl | running"
# ***** INITIALIZATION ***** #
# Variables
path_db=""
tax_ids=""
tmp_folder="/tmp"
threads=0
update_rsync=false
elapse_stop=0
rsync_max_retry=5
contimeout=5
all_phage=false
update_dmnd_prot=false
update_dmnd_phanotate=false
start_time=$SECONDS
cpt_download=0
cpt_done=0
cpt_rsync_failed=0
# Tools paths
prodigal="prodigal"
extractfeat="extractfeat"
diamond="diamond"
phanotate="phanotate.py"
transeq="transeq"
# Paths & URLs
taxonomy_efetch_url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=taxonomy"
taxdump_url="ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz"
# Colors
colortitle='\x1b[38;2;221;255;85m'
colortitlel='\x1b[38;2;238;255;170m'
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
    "--prodigal") set -- "$@" "-p" ;;
    "--extractfeat") set -- "$@" "-e" ;;
    "--diamond") set -- "$@" "-m" ;;
    "--phanotate") set -- "$@" "-g" ;;
    "--transeq") set -- "$@" "-a" ;;
    "-prodigal") usage ; display_error "Invalid option: -prodigal." false ;;
    "-extractfeat") usage ; display_error "Invalid option: -extractfeat." false ;;
    "-diamond") usage ; display_error "Invalid option: -diamond." false ;;
    "-phanotate") usage ; display_error "Invalid option: -phanotate." false ;;
    "-transeq") usage ; display_error "Invalid option: -transeq." false ;;
    *) set -- "$@" "$arg"
  esac
done
# list of arguments expected in the input
optstring=":o:d:i:w:r:t:c:p:e:m:g:s:a:fh"
while getopts ${optstring} arg; do
  case ${arg} in
    h) usage ; exit 0 ;;
    o) path_db="${OPTARG}" ;;
    d) division="${OPTARG^^}" ;;
    i) tax_ids="${OPTARG}" ;;
    f) update_rsync=true ;;
    w) tmp_folder="${OPTARG}" ;;
    t) threads="${OPTARG}" ;;
    r) rsync_max_retry="${OPTARG}" ;;
    c) contimeout="${OPTARG}" ;;
    s) elapse_stop="${OPTARG}" ;;
    p) prodigal="${OPTARG}" ;;
    e) extractfeat="${OPTARG}" ;;
    m) diamond="${OPTARG}" ;;      
    :) usage ; display_error "Must supply an argument to -$OPTARG." false ; exit 1 ;;
    ?) usage ; display_error "Invalid option: -${OPTARG}." false ; exit 2 ;;
  esac
done
# Check missing required arguments
if [[ -z "${path_db}" ]]; then usage ; display_error "Output database is required (-o)" false ; fi
if [[ -z "${division}" ]]; then usage ; display_error "Division is required (-d)" false ; fi
# Check arguments format
if [[ "${division}" != "BCT" && "${division}" != "PHG" ]]; then usage ; display_error "Invalid division (must be BCT or PHG)" false ; fi
if [[ ! -z "${tax_ids}" && ! "${tax_ids}" =~ ^[0-9,]+$ ]]; then usage ; display_error "Taxonomy identifier is invalid (must be integer)" false ; fi
if [[ ! -z "${threads}" && ! "${threads}" =~ ^[0-9,]+$ ]]; then usage ; display_error "Number of threads is invalid (must be integer)" false ; fi
if [ $threads == 0 ]; then threads=$(grep -c ^processor /proc/cpuinfo) ; fi
if [[ ! -z "${rsync_max_retry}" && ! "${rsync_max_retry}" =~ ^[0-9,]+$ ]]; then usage ; display_error "Number of rsync attempts is invalid (must be integer)" false ; fi
if [[ ! -z "${contimeout}" && ! "${contimeout}" =~ ^[0-9,]+$ ]]; then usage ; display_error "Number of daemon connection timeout is invalid (must be integer)" false ; fi
# Duration stop time
if [ $elapse_stop != 0 ]; then 
  elapse_stop_format=$(echo $elapse_stop | tr -d '0123456789')
  elapse_stop_num=$(echo $elapse_stop | tr -d 'mhd')
  case $elapse_stop_format in
    m) elapse_stop_sec=$((elapse_stop_num*60)) ;;
    h) elapse_stop_sec=$((elapse_stop_num*3600)) ;;
    d) elapse_stop_sec=$((elapse_stop_num*3600*24)) ;;
    *) usage ; display_error "Duration time stop format is invalid (must be Xm, Xh, Xd)" false ;;
  esac
fi
# Check tools
if ! command -v rsync &> /dev/null; then display_error "rsync not found (must be in path)" false ; fi
if ! command -v gzip &> /dev/null; then display_error "gzip not found (must be in path)" false ; fi
if ! command -v zgrep &> /dev/null; then display_error "zgrep not found (must be in path)" false ; fi
if ! command -v ${extractfeat} &> /dev/null; then display_error "extractfeat [EMBOSS] not found (use \$PATH or specify it)" false ; fi
if ! command -v ${prodigal} &> /dev/null; then display_error "prodigal not found (use \$PATH or specify it)" false ; fi
if ! command -v ${diamond} &> /dev/null; then display_error "diamond not found (use \$PATH or specify it)" false ; fi
if ! command -v ${phanotate} &> /dev/null; then display_error "phanotate not found (use \$PATH or specify it)" false ; fi
if ! command -v ${transeq} &> /dev/null; then display_error "transeq not found (use \$PATH or specify it)" false ; fi
# Data & Output folder
if [ "${division}" == "BCT" ]; then summary_url="ftp.ncbi.nlm.nih.gov/genomes/genbank/bacteria/assembly_summary.txt" ; division_title="bacteria" ; fi
if [ "${division}" == "PHG" ]; then summary_url="ftp.ncbi.nlm.nih.gov/genomes/genbank/viral/assembly_summary.txt" ; division_title="phage" ; fi
mkdir -p ${path_db} 2>/dev/null
if [[ ! $? -eq 0 ]] ; then usage && display_error "Cannot create output directory (${path_db})" false ; fi
log="${path_db}/genomedl.log"
# Temporary folder and files
uuidgen=$(uuidgen | cut -d "-" -f 1,2)
dir_tmp="${tmp_folder}/gdl_${uuidgen}"
mkdir -p ${dir_tmp} 2>/dev/null
if [[ ! $? -eq 0 ]] ; then usage && display_error "Cannot create temp directory (${dir_tmp})" false ; fi
rsync_out_ass_sum="${dir_tmp}/rsyncAssSum.txt"
rsync_out_tax_dump="${dir_tmp}/rsyncTaxDump.txt"
rsync_out_dl="${dir_tmp}/rsyncDL.txt"
rsync_exclude="${dir_tmp}/rsyncExclude.txt"
lineage_taxids="${dir_tmp}/lineage_taxids.txt"
download_urls_refseq="${dir_tmp}/download_urls_refseq.txt"
download_urls_genbank="${dir_tmp}/download_urls_genbank.txt"
download_urls="${dir_tmp}/download_urls.txt"
download_urls_final="${dir_tmp}/download_urls_filtered.txt"
taxidlineage_dmp="${dir_tmp}/taxidlineage.dmp"
nodes_dmp="${dir_tmp}/nodes.dmp"
summary_sorted="${dir_tmp}/assembly_summary_sorted.txt"





# ************************************************************************* #
# *****                         PREPROCESSING                         ***** #
# ************************************************************************* #
# Rsync exclude patterns
echo -e "*_wgsmaster.gbff.gz\n*_assembly_structure\n*_assembly_stats.txt\nannotation_hashes.txt\n*_assembly_report.txt\n*_cds_from_genomic.fna.gz\n*_feature_table.txt.gz\n*_genomic.gff.gz\n*_genomic.gtf.gz\n*_genomic_gaps.txt.gz\n*_protein.gpff.gz\n*_rna_from_genomic.fna.gz\n*_translated_cds.faa.gz\nassembly_status.txt\nREADME.txt\n" > ${rsync_exclude}
# Log file
rm -f ${log}
touch ${log}
# Modify sort separator
shopt -s expand_aliases
alias sort="sort --field-separator=$'\t'"
# Display infos
echo -e "╭─INIT──────────────────────────────────────────────────────────────╮"
echo -ne "| ${colortitle}DB folder   : ${NC}${path_db}" ; rjust $((15+${#path_db})) true
echo -ne "| ${colortitle}TMP folder  : ${NC}${dir_tmp}" ; rjust $((15+${#dir_tmp})) true
echo -ne "| ${colortitle}Threads     : ${NC}${threads}" ; rjust $((15+${#threads})) true
echo -ne "| ${colortitle}RsyncRetry  : ${NC}${rsync_max_retry}" ; rjust $((15+${#rsync_max_retry})) true
echo -ne "| ${colortitle}RsyncTimeout: ${NC}${contimeout}" ; rjust $((15+${#contimeout})) true
if [ ! -z ${elapse_stop_sec} ]; then
  echo -ne "| ${colortitle}Duration    : ${NC}${elapse_stop}" ; rjust $((15+${#elapse_stop})) true
else
  echo -ne "| ${colortitle}Duration    : ${NC}unlimited" ; rjust 24 true
fi
echo -ne "| ${colortitle}Division    : ${NC}${division} (${division_title})" ; rjust $((18+${#division}+${#division_title})) true
if [[ -z "${tax_ids}" ]]; then
  echo -ne "| ${colortitle}Taxonomy ID : ${NC}all" ; rjust 18 true
else
  echo -ne "| ${colortitle}Taxonomy ID : ${NC}${tax_ids}" ; rjust $((15+${#tax_ids})) true
fi
# Display update mode
if [ ${update_rsync} = true ]; then
  echo -ne "| ${colortitle}Update mode${NC} : force" ; rjust "20" true
else
  echo -ne "| ${colortitle}Update mode${NC} : conservative" ; rjust "27" true
fi
# Display last release date
if [ -f "${path_db}/release.txt" ]; then
  last_release=$(cat "${path_db}/release.txt")  
  echo -ne "| ${colortitle}Last release: ${NC}${last_release}" ; rjust $((15+${#last_release})) true
else
  echo -ne "| ${colortitle}Last release: ${NC}any found" ; rjust "24" true
fi
echo -e "╰───────────────────────────────────────────────────────────────────╯"





# ************************************************************************* #
# *****                          PROCESSING                           ***** #
# ************************************************************************* #
# Don't forget that the port 873 must be open in the firewall
# ***** RSYNC summary & taxdump ***** #
echo -e "╭─PROCESSING────────────────────────────────────────────────────────╮"
SPINNY_FRAMES=( " synchronizing                                       |" " synchronizing .                                     |" " synchronizing ..                                    |" " synchronizing ...                                   |" " synchronizing ....                                  |" " synchronizing .....                                 |")
# Rsync assembly_summary
echo -ne "| ${colortitle}Summary     :${NC}"
spinny::start
cur_ass_summary="${path_db}/assembly_summary.txt"
tmp_ass_summary="${dir_tmp}/assembly_summary.txt"
cpt_retry=0
while [ $cpt_retry -le $rsync_max_retry ]
    do rsync -u --copy-links --no-motd --contimeout=${contimeout} -q rsync://${summary_url} ${tmp_ass_summary} 2>>${log} | tee ${rsync_out_ass_sum}
    if [ -f ${tmp_ass_summary} ]; then break ; fi
    sleep 5
    ((cpt_retry++))
done
spinny::stop
if [ ! -f ${tmp_ass_summary} ]; then display_error "Failed to download assembly_summary.txt" true ; fi
# Check if assembly_summary is updated
if cmp -s ${cur_ass_summary} ${tmp_ass_summary} ; then
  echo -ne " up-to-date" ; rjust "25" true
else
  echo -ne "${colortitlel} updated${NC}" ; rjust "22" true
  cp ${tmp_ass_summary} ${cur_ass_summary}
fi
# Rsync taxdump.tar.gz
echo -ne "| ${colortitle}Taxdump     :${NC}"
spinny::start
cur_taxdump="${path_db}/taxdump.tar.gz"
tmp_taxdump="${dir_tmp}/taxdump.tar.gz"
cpt_retry=0
while [ $cpt_retry -le $rsync_max_retry ]
    do rsync -u --copy-links --no-motd --contimeout=${contimeout} -q rsync://${taxdump_url} ${tmp_taxdump} 2>>${log} | tee ${rsync_out_tax_dump}
    if [ -f ${tmp_taxdump} ]; then break ; fi
    sleep 5
    ((cpt_retry++))
done
spinny::stop
if [ ! -f ${tmp_taxdump} ]; then display_error "Failed to download taxdump.tar.gz" true ; fi
# Check if taxdump is updated
if cmp -s ${cur_taxdump} ${tmp_taxdump} ; then
  echo -ne " up-to-date" ; rjust "25" true
else
  echo -ne "${colortitlel} updated${NC}" ; rjust "22" true
  cp ${tmp_taxdump} ${cur_taxdump}
fi

# ***** FILTERING ***** # (disable if division=BCT and without taxonomy identifier)
echo -ne "| ${colortitle}Filtering   :${NC}"
# Sort assembly
SPINNY_FRAMES=( " summary reading                                     |" " summary reading .                                   |" " summary reading ..                                  |" " summary reading ...                                 |" " summary reading ....                                |" " summary reading .....                               |")
spinny::start
grep "^#" ${cur_ass_summary} > "${path_db}/assembly_summary_taxids.txt"
grep -v "^#" ${cur_ass_summary} | sort -k 6,6 > "${summary_sorted}"
spinny::stop
# Any filtering
if [[ -z "${tax_ids}" && "${division}" == "BCT" ]]; then
  cp ${summary_sorted} "${path_db}/assembly_summary_taxids.txt"
# All phages filtering (based on gencode 11)
elif [[ -z "${tax_ids}" && "${division}" == "PHG" ]]; then
  # Get nodes
  SPINNY_FRAMES=( " nodes extraction                                    |" " nodes extraction .                                  |" " nodes extraction ..                                 |" " nodes extraction ...                                |" " nodes extraction ....                               |" " nodes extraction .....                              |")
  spinny::start
  tar xf ${cur_taxdump} -C ${dir_tmp} $(get_base ${nodes_dmp}) 2>>${log}
  spinny::stop
  # Lineage filtering
  SPINNY_FRAMES=( " gencode filtering                                   |" " gencode filtering .                                 |" " gencode filtering ..                                |" " gencode filtering ...                               |" " gencode filtering ....                              |" " gencode filtering .....                             |")
  spinny::start
  # Get lineage with gencode 11
  cut -f 1,13 ${nodes_dmp} | grep -P "\t11" > ${lineage_taxids}
  spinny::stop
  SPINNY_FRAMES=( " lineage filtering                                   |" " lineage filtering .                                 |" " lineage filtering ..                                |" " lineage filtering ...                               |" " lineage filtering ....                              |" " lineage filtering .....                             |")
  spinny::start
  # Sort, remove duplicate & filter assembly_summary
  awk '$1' ${lineage_taxids} | sort -u -o ${lineage_taxids}
  join_as_fields1="1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,1.20,1.21,1.22,1.23"
  join -1 6 -2 1 "${summary_sorted}" ${lineage_taxids} -o ${join_as_fields1} -t$'\t' | sort | uniq >> "${path_db}/assembly_summary_taxids.txt"
  spinny::stop  
else
  # Get taxidlineage
  SPINNY_FRAMES=( " taxidlineage extraction                             |" " taxidlineage extraction .                           |" " taxidlineage extraction ..                          |" " taxidlineage extraction ...                         |" " taxidlineage extraction ....                        |" " taxidlineage extraction .....                       |")
  spinny::start
  tar xf ${cur_taxdump} -C ${dir_tmp} $(get_base ${taxidlineage_dmp}) 2>>${log}
  spinny::stop
  # Get only taxids in the lineage section
  SPINNY_FRAMES=( " taxids to lineage                                   |" " taxids to lineage .                                 |" " taxids to lineage ..                                |" " taxids to lineage ...                               |" " taxids to lineage ....                              |" " taxids to lineage .....                             |")
  spinny::start
  echo $tax_ids > ${lineage_taxids}
  for tx in ${tax_ids//,/ }; do
      txids_lin=$(grep "[^0-9]${tx}[^0-9]" ${taxidlineage_dmp} | cut -f 1)
      echo "${txids_lin}" >> ${lineage_taxids}
  done
  spinny::stop
  # Lineage filtering
  SPINNY_FRAMES=( " lineage filtering                                   |" " lineage filtering .                                 |" " lineage filtering ..                                |" " lineage filtering ...                               |" " lineage filtering ....                              |" " lineage filtering .....                             |")
  spinny::start
  # Sort, remove duplicate & filter assembly_summary
  awk '$1' ${lineage_taxids} | sort -u -o ${lineage_taxids}
  join_as_fields1="1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,1.20,1.21,1.22,1.23"
  join -1 6 -2 1 "${summary_sorted}" ${lineage_taxids} -o ${join_as_fields1} -t$'\t' | sort | uniq >> "${path_db}/assembly_summary_taxids.txt"
  spinny::stop
fi
# Count genomes
nb_total=$(grep -cPv "^#" ${path_db}/assembly_summary_taxids.txt)
# Making url files 
SPINNY_FRAMES=( " create url files                                    |" " create url files .                                  |" " create url files ..                                 |" " create url files ...                                |" " create url files ....                               |" " create url files .....                              |")
spinny::start
input_data=$(tail -n+3 "${path_db}/assembly_summary_taxids.txt" | cut -f 1,18,20 | tr "\t" "#") # replace tabs with alarm bell
declare -A assArrayRefseqSrcFTPpath
while IFS="#" read assembly_accession gbrs_paired_asm ftp_path
  do
  if [ "$ftp_path" != "na" ]; then
    if [ "$gbrs_paired_asm" == "na" ]; then
      echo ${ftp_path} >> ${download_urls_genbank}
    else
      echo "${gbrs_paired_asm}#${ftp_path}" >> ${download_urls_refseq}
      assArrayRefseqSrcFTPpath["$gbrs_paired_asm"]=${ftp_path}
    fi
  fi
done <<< "$input_data"
if [ -f ${download_urls_genbank} ]; then
  sed -i s/"https"/"rsync"/g ${download_urls_genbank}
else
  touch ${download_urls_genbank}
fi
if [ -f ${download_urls_refseq} ]; then
  sed -i s~"/"~"#"~g ${download_urls_refseq}
  sed -i s/"_"/"#"/g ${download_urls_refseq}
  awk 'BEGIN {FS="#";OFS="_"} {print "rsync://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/"$9"/"$10"/"$11"/"$1,$2,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30}' ${download_urls_refseq} > "${download_urls_refseq}_2"
  mv "${download_urls_refseq}_2" ${download_urls_refseq}
  sed -i -e s/"__.*"/""/g ${download_urls_refseq}
  sed -i -e s/"__.*"/""/g ${download_urls_refseq}
else
  touch ${download_urls_refseq}
fi  
cat ${download_urls_genbank} ${download_urls_refseq} > ${download_urls}
# Create associative array for fast basename from URL
declare -A assArrayURL
while read -r dl_line; do
  basename=$(get_base ${dl_line})
  assArrayURL["$basename"]=${dl_line}
  echo $basename >> ${dir_tmp}/list_all.txt
done < ${download_urls}
# End
spinny::stop
echo -ne " ${nb_total} genomes" ; rjust $((23+${#nb_total})) true

# ***** COMPARE NEW and OLD assemblies ***** #
echo -ne "| ${colortitle}Synchronize :${NC}"
nb_sync=0
nb_removed=0
# Get previous genome folder
ls -1 ${path_db} | grep -P "^GC" > ${dir_tmp}/list_yet.txt
# Check new genome
SPINNY_FRAMES=( " check new genomes                                   |" " check new genomes .                                 |" " check new genomes ..                                |" " check new genomes ...                               |" " check new genomes ....                              |" " check new genomes .....                             |")
spinny::start
if [[ ${update_rsync} = true ]]; then
  cp ${download_urls} ${download_urls_final}
  nb_sync=${nb_total}
else
  diff ${dir_tmp}/list_yet.txt ${dir_tmp}/list_all.txt | grep ">" | cut -d " " -f 2 > ${dir_tmp}/missing.txt
  while read -r dl_line; do
    echo ${assArrayURL["$dl_line"]} >> ${download_urls_final}
    ((nb_sync++))
  done < ${dir_tmp}/missing.txt
fi
spinny::stop
# Check removed/replaced genomes
SPINNY_FRAMES=( " check deleted genomes                               |" " check deleted genomes .                             |" " check deleted genomes ..                            |" " check deleted genomes ...                         |" " check deleted genomes ....                          |" " check deleted genomes .....                         |")
spinny::start
diff ${dir_tmp}/list_yet.txt ${dir_tmp}/list_all.txt | grep "<" | cut -d " " -f 2 > ${dir_tmp}/removed.txt
  while read -r rm_line; do
    rm -rf ${path_db}/${rm_line} 2>>${log}
    ((nb_removed++))
  done < ${dir_tmp}/removed.txt
spinny::stop
echo -ne " done" ; rjust 19 true

# ***** DELETE replaced/removed genomes ***** #
if [[ ${nb_removed} -eq 0 ]]; then
  echo -ne "| ${colortitle}Deleting    :${NC} up-to-date" ; rjust 25 true
else
  echo -ne "| ${colortitle}Deleting    :${NC} ${nb_removed} genomes" ; rjust $((23+${#nb_removed})) true
fi

# ***** SYNCHRONIZE ***** #
if [[ ${nb_sync} -eq 0 ]]; then
  echo -ne "| ${colortitle}Downloading :${NC} up-to-date" ; rjust 25 false
else
  echo -ne "| ${colortitle}Downloading :${NC} ${nb_sync} genomes" ; rjust $((23+${#nb_sync})) true
  while read -r dl_line; do
    if [[ ! -z "${elapse_stop_sec}" && $(($SECONDS-start_time)) -ge ${elapse_stop_sec} ]]; then summary true ; exit 0 ; fi
    cpt_retry=1
    basename=$(get_base ${dl_line})
    acc_name=$(echo $basename | cut -d "_" -f 1,2)
    path_db_acc="${path_db}/$basename"
    rm -f ${rsync_out_dl}
    # Display progress
    ((cpt_done++))
    percent_done=$(( ${cpt_done}*100/${nb_sync} ))
    if [[ ${update_rsync} = true || ! -d ${path_db_acc} ]]; then
      while [ $cpt_retry -le $rsync_max_retry ]
          do
          progress ${percent_done} "${acc_name}/${cpt_retry}" ${colortitlel}
          rsync -r -u --no-motd --copy-links --contimeout=${contimeout} --itemize-changes --exclude-from=${rsync_exclude} ${dl_line} ${path_db}/ >${rsync_out_dl} 2>>${log} && break
          # for some refseq GCF URL doesn't work try GCA URL
          rsync -r -u --no-motd --copy-links --contimeout=${contimeout} --itemize-changes --exclude-from=${rsync_exclude} $(echo ${assArrayRefseqSrcFTPpath["$acc_name"]}"/" | sed s/"https"/"rsync"/g) ${path_db_acc} >${rsync_out_dl} 2>>${log} && break
          ((cpt_retry++))
      done
      if [ ! -s ${rsync_out_dl} ]; then
        ((cpt_download++))
        # remove postprocessing file if updated
        rm -f ${path_db_acc}/*.ffn ${path_db_acc}/*.dmnd ${path_db_acc}/*phanotate*
      fi
      else
        progress ${percent_done} "${acc_name}" ${colorterm}
      # Check genome folder and gbff file
      if ! ls ${path_db_acc}/*.gbff.gz >/dev/null 2>&1; then
        echo -e "${basename}: rsync failed" >> ${log}
        ((cpt_rsync_failed++))
      fi
    fi
    # Display percent done
    title "genomedl | rsync (${percent_done}%%)"
  done < ${download_urls_final}
  echo -ne '\e[1A\e[K'
fi
echo -e "\n╰───────────────────────────────────────────────────────────────────╯"





# ************************************************************************* #
# *****                        POSTPROCESSING                         ***** #
# ************************************************************************* #
if [[ ! -z "${elapse_stop_sec}" && $(($SECONDS-start_time)) -ge ${elapse_stop_sec} ]]; then summary true ; exit 0 ; fi
echo -e "╭─POSTPROCESSING────────────────────────────────────────────────────╮"

# ***** FFN ***** #
echo -ne "| ${colortitle}FFN files   :${NC}"
title "genomedl | ffn"
SPINNY_FRAMES=( " check missing                                       |" " check missing .                                     |" " check missing ..                                    |" " check missing ...                                   |" " check missing ....                                  |" " check missing .....                                 |")
spinny::start
totalMissingFFN=$((${nb_total}-${cpt_rsync_failed}-$(find ${path_db}/GC* -type f -name '*_gene.ffn.gz' | wc -l)))
spinny::stop
cpt_done=0
arrayPid=()
if [[ ${totalMissingFFN} -gt 0 ]]; then
  echo -ne " ${totalMissingFFN} missing gene files" ; rjust $((34+${#totalMissingFFN})) true
  # CREATE PROCESS BASH
  for ass_dir in ${path_db}/GC*
    do
    if [[ ! -z "${elapse_stop_sec}" && $(($SECONDS-start_time)) -ge ${elapse_stop_sec} ]]; then summary true ; exit 0 ; fi
    if ! ls ${ass_dir}/*_gene.ffn.gz 1> /dev/null 2>&1; then
      # Paths
      gbk_path=$(ls -1 ${ass_dir}/*.gbff.gz)
      ffn_path=$(echo "${gbk_path}" | sed s/"_genomic.gbff.gz"/"_gene.ffn"/)
      acc_name=$(get_base ${gbk_path} | sed s/"_genomic.gbff.gz"/""/)
      org_name=$(zgrep -m 1 "SOURCE" ${gbk_path} | cut -d " " -f 7-  | tr ' ' '_' | tr '/' '-' | tr ':' '-' | cut -d "(" -f 1 | cut -d "=" -f 1)
      bash_process="${dir_tmp}/${acc_name}_extract.sh"
      # Construct process bash / extract gene or CDS
      echo -e "gzip -d -c \"${gbk_path}\" 1>\"${dir_tmp}/${acc_name}.gbk\"" > ${bash_process}
      echo -e "${extractfeat} -sequence \"${dir_tmp}/${acc_name}.gbk\" -outseq \"${dir_tmp}/${acc_name}.ffn\" -type gene" >> ${bash_process}
      echo -e "if [ -s \"${dir_tmp}/${acc_name}.ffn\" ]; then" >> ${bash_process} # Check if file is empty due to bad gene tag in gbff
      echo -e "  sed -E s/\"\\s.+\"/\" extractfeat gene [${org_name}]\"/g \"${dir_tmp}/${acc_name}.ffn\" > ${ffn_path}" >> ${bash_process}
      echo -e "  gzip -f \"${ffn_path}\"" >> ${bash_process}
      echo -e "else" >> ${bash_process}
      echo -e "  ${extractfeat} -sequence \"${dir_tmp}/${acc_name}.gbk\" -outseq \"${dir_tmp}/${acc_name}.ffn\" -type cds" >> ${bash_process}
      echo -e "  if [ -s \"${dir_tmp}/${acc_name}.ffn\" ]; then" >> ${bash_process} # Check if file is empty due to bad gene tag in gbff
      echo -e "    sed -E s/\"\\s.+\"/\" extractfeat cds [${org_name}]\"/g \"${dir_tmp}/${acc_name}.ffn\" > ${ffn_path}" >> ${bash_process}
      echo -e "    gzip -f \"${ffn_path}\"" >> ${bash_process}
      echo -e "  else" >> ${bash_process} # if any gene or CDS create an empty file
      echo -e "    touch ${ffn_path}.gz" >> ${bash_process}
      echo -e "  fi" >> ${bash_process}
      echo -e "fi" >> ${bash_process}
      #echo -e "rm -f \"${dir_tmp}/${acc_name}.gbk\" \"${dir_tmp}/${acc_name}.ffn\"" >> ${bash_process}
      # Launch process
      bash ${bash_process} 2>>${log} &
      arrayPid+=($!)
      pwait ${threads} ; parallel_progress "gbk2ffn" "${totalMissingFFN}"
    fi
  done
  # Final wait & progress
  while [ $(jobs -p | wc -l) -gt 1 ]; do parallel_progress "gbk2ffn" ${totalMissingFFN} ; sleep 1 ; done
  rm -f "${dir_tmp}/*_extract.sh"
  echo -e '\e[1A\e[K'
else
  echo -e " any missing gene file" ; rjust 36 false
fi

# ***** Phanotate ***** # (for phage)
if [[ ! -z "${elapse_stop_sec}" && $(($SECONDS-start_time)) -ge ${elapse_stop_sec} ]]; then summary true ; exit 0 ; fi
if [ ${division} == "PHG" ]; then
  echo -ne "| ${colortitle}Phanotate   :${NC}"
  title "genomedl | phanotate"
  SPINNY_FRAMES=( " check missing                                       |" " check missing .                                     |" " check missing ..                                    |" " check missing ...                                   |" " check missing ....                                  |" " check missing .....                                 |")
  spinny::start
  totalMissingPhanotateFFN=$((${nb_total}-${cpt_rsync_failed}-$(find ${path_db}/GC* -type f -name '*_phanotate.ffn.gz' | wc -l)))
  spinny::stop
  cpt_done=0
  arrayPid=()
  if [[ "${totalMissingPhanotateFFN}" != "0" ]]; then
    echo -ne " ${totalMissingPhanotateFFN} missing phanotate files" ; rjust $((39+${#totalMissingPhanotateFFN})) true
    for ass_dir in ${path_db}/GC*
      do
      if [[ ! -z "${elapse_stop_sec}" && $(($SECONDS-start_time)) -ge ${elapse_stop_sec} ]]; then summary true ; exit 0 ; fi
      if ! ls ${ass_dir}/*_phanotate.ffn.gz 1> /dev/null 2>&1; then
        # Paths
        gbk_path=$(ls -1 ${ass_dir}/*.gbff.gz)
        ffn_path=$(echo "${gbk_path}" | sed s/"_genomic.gbff.gz"/"_phanotate.ffn"/)
        faa_path=$(echo "${gbk_path}" | sed s/"_genomic.gbff.gz"/"_phanotate.faa"/)
        rm -f ${ass_dir}/*.dmnd
        acc_name=$(get_base ${gbk_path} | sed s/"_genomic.gbff.gz"/""/)    
        org_name=$(zgrep -m 1 "SOURCE" ${gbk_path} | cut -d " " -f 7- | tr ' ' '_' | tr '/' '-' | tr ':' '-' | cut -d "(" -f 1 | cut -d "=" -f 1)
        bash_process="${dir_tmp}/${acc_name}_phanotate.sh"
        # Construct process bash
        echo -e "gzip -d -c \"${gbk_path}\" 1>\"${dir_tmp}/${acc_name}.gbk\"" > ${bash_process}
        echo -e "${extractfeat} -sequence \"${dir_tmp}/${acc_name}.gbk\" -outseq \"${dir_tmp}/${acc_name}.fna\"" >> ${bash_process}
        echo -e "${phanotate} --outfmt fasta -o \"${ffn_path}\" \"${dir_tmp}/${acc_name}.fna\"" >> ${bash_process}
        echo -e "sed -i -E s/\"\\[START.+\"/\"phanotate gene \\[${org_name}\\]\"/g \"${ffn_path}\"" >> ${bash_process}
        echo -e "${transeq} -sequence \"${ffn_path}\" -outseq \"${faa_path}\" -frame 1 -table 11 -trim" >> ${bash_process}
        echo -e "sed -i s/\"_1 phanotate gene\"/\" phanotate protein\"/g \"${faa_path}\"" >> ${bash_process}
        echo -e "gzip -f \"${ffn_path}\"" >> ${bash_process}
        echo -e "gzip -f \"${faa_path}\"" >> ${bash_process}
        echo -e "rm -f \"${dir_tmp}/${acc_name}.gbk\" \"${dir_tmp}/${acc_name}.fna\"" >> ${bash_process}
        # Launch process
        bash ${bash_process} 2>>${log} &
        arrayPid+=($!)
        pwait ${threads} ; parallel_progress "phanotate" "${totalMissingPhanotateFFN}"
      fi
    done
    # Final wait & progress
    while [ $(jobs -p | wc -l) -gt 1 ]; do parallel_progress "phanotate" ${totalMissingPhanotateFFN} ; sleep 1 ; done
    rm -f "${dir_tmp}/*_phanotate.sh"
    echo -e '\e[1A\e[K'
  else
    echo -ne " any missing phanotate file" ; rjust 41 true
  fi
fi

# ***** Prodigal ***** # (for missing bacteria genes/CDS)
if [[ ! -z "${elapse_stop_sec}" && $(($SECONDS-start_time)) -ge ${elapse_stop_sec} ]]; then summary true ; exit 0 ; fi
if [ ${division} == "BCT" ]; then
  echo -ne "| ${colortitle}Prodigal    :${NC}"
  title "genomedl | prodigal"
  SPINNY_FRAMES=( " check missing                                       |" " check missing .                                     |" " check missing ..                                    |" " check missing ...                                   |" " check missing ....                                  |" " check missing .....                                 |")
  spinny::start
  totalMissingFAA=$((${nb_total}-${cpt_rsync_failed}-$(find ${path_db}/GC* -type f -name '*_protein.faa.gz' | wc -l)))
  spinny::stop
  cpt_done=0
  arrayPid=()
  if [[ "${totalMissingFAA}" != "0" ]]; then
    echo -ne " ${totalMissingFAA} missing protein files" ; rjust $((37+${#totalMissingFAA})) true
    for ass_dir in ${path_db}/GC*
      do
      if [[ ! -z "${elapse_stop_sec}" && $(($SECONDS-start_time)) -ge ${elapse_stop_sec} ]]; then summary true ; exit 0 ; fi
      if ! ls ${ass_dir}/*_protein.faa.gz 1> /dev/null 2>&1; then
        # Paths
        fna_path=$(ls -1 ${ass_dir}/*.fna.gz)
        gbk_path=$(ls -1 ${ass_dir}/*.gbff.gz)
        faa_path=$(echo ${gbk_path} | sed s/"_genomic.gbff.gz"/"_protein.faa"/)
        ffn_path=$(echo ${gbk_path} | sed s/"_genomic.gbff.gz"/"_gene.ffn"/)
        rm -f ${ass_dir}/*.dmnd
        acc_name=$(get_base ${gbk_path} | sed s/"_genomic.gbff.gz"/""/)          
        org_name=$(zgrep -m 1 "SOURCE" ${gbk_path} | cut -d " " -f 7- | tr ' ' '_' | tr '/' '-' | tr ':' '-' | cut -d "(" -f 1 | cut -d "=" -f 1)
        bash_process="${dir_tmp}/${acc_name}_prodigal.sh"
        # Construct process bash
        echo -e "gzip -d -c \"${fna_path}\" 1>\"${dir_tmp}/${acc_name}.fna\"" > ${bash_process}
        echo -e "${prodigal} -d \"${dir_tmp}/${acc_name}.ffn\" -a \"${dir_tmp}/${acc_name}.faa\" -g 11 -i \"${dir_tmp}/${acc_name}.fna\" -o /dev/null -p single -q" >> ${bash_process}
        echo -e "sed -E -i s/\"\\s.+\"/\" prodigal protein [${org_name}]\"/g \"${dir_tmp}/${acc_name}.faa\"" >> ${bash_process}
        echo -e "sed s/\"*\"/\"\"/g \"${dir_tmp}/${acc_name}.faa\" > ${faa_path}" >> ${bash_process}
        echo -e "gzip -f ${faa_path}" >> ${bash_process}
        echo -e "if [[ ! -f \"${ffn_path}\" && ! -f \"${ffn_path}.gz\" ]]; then" >> ${bash_process}
        echo -e "  sed -E s/\"\\s.+\"/\" prodigal gene [${org_name}]\"/g \"${dir_tmp}/${acc_name}.ffn\" > ${ffn_path}" >> ${bash_process}
        echo -e "  gzip -f ${ffn_path}" >> ${bash_process}
        echo -e "fi" >> ${bash_process}
        echo -e "rm -f \"${dir_tmp}/${acc_name}.fna\" \"${dir_tmp}/${acc_name}.ffn\" \"${dir_tmp}/${acc_name}.faa\"" >> ${bash_process}
        # Launch process
        bash ${bash_process} 2>>${log} &
        arrayPid+=($!)
        pwait ${threads} ; parallel_progress "prodigal" "${totalMissingFAA}"
      fi
    done
    # Final wait & progress
    while [ $(jobs -p | wc -l) -gt 1 ]; do parallel_progress "prodigal" ${totalMissingFAA} ; sleep 1 ; done
    rm -f "${dir_tmp}/*_prodigal.sh"
    echo -e '\e[1A\e[K'
  else
    echo -ne " any missing protein file" ; rjust 39 true
  fi
fi

# ***** FAA ***** # (for missing phage FAA)
if [[ ! -z "${elapse_stop_sec}" && $(($SECONDS-start_time)) -ge ${elapse_stop_sec} ]]; then summary true ; exit 0 ; fi
if [ ${division} == "PHG" ]; then
  echo -ne "| ${colortitle}FAA files   :${NC}"
  title "genomedl | faa"
  SPINNY_FRAMES=( " check missing                                       |" " check missing .                                     |" " check missing ..                                    |" " check missing ...                                   |" " check missing ....                                  |" " check missing .....                                 |")
  spinny::start
  totalMissingFAA=$((${nb_total}-${cpt_rsync_failed}-$(find ${path_db}/GC* -type f -name '*_protein.faa.gz' | wc -l)))
  spinny::stop
  cpt_done=0
  arrayPid=()
  if [[ "${totalMissingFAA}" != "0" ]]; then
    echo -ne " ${totalMissingFAA} missing protein files" ; rjust $((37+${#totalMissingFAA})) true
    for ass_dir in ${path_db}/GC*
      do
      if [[ ! -z "${elapse_stop_sec}" && $(($SECONDS-start_time)) -ge ${elapse_stop_sec} ]]; then summary true ; exit 0 ; fi
      if ! ls ${ass_dir}/*_protein.faa.gz 1> /dev/null 2>&1; then
        # Paths
        gbk_path=$(ls -1 ${ass_dir}/*.gbff.gz)
        faa_path=$(echo ${gbk_path} | sed s/"_genomic.gbff.gz"/"_protein.faa"/)
        ffn_path=$(echo "${gbk_path}" | sed s/"_genomic.gbff.gz"/"_gene.ffn.gz"/)
        acc_name=$(get_base ${ffn_path} | sed s/"_gene.ffn.gz"/""/)
        rm -f ${ass_dir}/*.dmnd
        bash_process="${dir_tmp}/${acc_name}_missingfaa.sh"
        # Construct process bash
        echo -e "if [ ! -s \"${ffn_path}\" ]; then" > ${bash_process} # Check if gene file is empty due to bad gene tag in gbff
        echo -e "  touch ${faa_path}.gz" >> ${bash_process}
        echo -e "else" >> ${bash_process}
        echo -e "  gzip -d -c \"${ffn_path}\" 1>\"${dir_tmp}/${acc_name}.ffn\"" >> ${bash_process}
        echo -e "  ${transeq} -sequence \"${dir_tmp}/${acc_name}.ffn\" -outseq \"${faa_path}\" -frame 1 -table 11 -trim" >> ${bash_process}
        echo -e "  gzip -f \"${faa_path}\"" >> ${bash_process}
        echo -e "fi" >> ${bash_process}
        # Launch process
        bash ${bash_process} 2>>${log} &
        arrayPid+=($!)
        pwait ${threads} ; parallel_progress "missing FAA" "${totalMissingFAA}"        
      fi
    done
    # Final wait & progress
    while [ $(jobs -p | wc -l) -gt 1 ]; do parallel_progress "missing FAA" ${totalMissingFAA} ; sleep 1 ; done
    rm -f "${dir_tmp}/*_missingfaa.sh"
    echo -e '\e[1A\e[K'
  else
    echo -ne " any missing protein file" ; rjust 39 true
  fi
fi

# ***** DIAMOND makedb ***** # (for phage two dmnd, original and phanotate)
echo -ne "| ${colortitle}DiamondDB   :${NC}"
title "genomedl | diamonddb"
SPINNY_FRAMES=( " check missing                                       |" " check missing .                                     |" " check missing ..                                    |" " check missing ...                                   |" " check missing ....                                  |" " check missing .....                                 |")
spinny::start
if [ ${division} == "PHG" ]; then
  totalMissingDMND=$((${nb_total}*2-${cpt_rsync_failed}-$(find ${path_db}/GC* -type f -name '*.dmnd' | wc -l)))
else
  totalMissingDMND=$((${nb_total}-${cpt_rsync_failed}-$(find ${path_db}/GC* -type f -name '*.dmnd' | wc -l)))
fi
spinny::stop
cpt_done=0
arrayPid=()
if [[ "${totalMissingDMND}" != "0" ]]; then
  echo -ne " ${totalMissingDMND} missing diamond files" ; rjust $((37+${#totalMissingDMND})) true
  for ass_dir in ${path_db}/GC*
    do
    if [[ ! -z "${elapse_stop_sec}" && $(($SECONDS-start_time)) -ge ${elapse_stop_sec} ]]; then summary true ; exit 0 ; fi
    if ! ls ${ass_dir}/*_protein.dmnd 1> /dev/null 2>&1; then
      update_dmnd_prot=true
      faa_path=$(ls -1 ${ass_dir}/*_protein.faa.gz)
      dmnd_path=$(echo ${faa_path} | sed s/"_protein.faa.gz"/"_protein.dmnd"/)
      # Launch makedb
      ${diamond} makedb --in ${faa_path} --db ${dmnd_path} --quiet &
      arrayPid+=($!)
      pwait ${threads} ; parallel_progress "diamond makedb" "${totalMissingDMND}"
    fi
    if [ ${division} == "PHG" ]; then
      if ! ls ${ass_dir}/*_phanotate.dmnd 1> /dev/null 2>&1; then
        update_dmnd_phanotate=true
        faa_path=$(ls -1 ${ass_dir}/*_phanotate.faa.gz)
        dmnd_path=$(echo ${faa_path} | sed s/"_phanotate.faa.gz"/"_phanotate.dmnd"/)
        # Launch makedb
        ${diamond} makedb --in ${faa_path} --db ${dmnd_path} --quiet
        arrayPid+=($!)
        pwait ${threads} ; parallel_progress "diamond makedb" "${totalMissingDMND}"
      fi
    fi
  done
  # Final wait & progress
  while [ $(jobs -p | wc -l) -gt 1 ]; do parallel_progress "diamond makedb" ${totalMissingDMND} ; sleep 1 ; done
  echo -e '\e[1A\e[K'
else
  echo -ne " any missing diamond files" ; rjust 40 true
fi

# ***** DIAMONDDB merge ***** # (for phage two dmnd, original and phanotate)
# For *_protein.faa.gz
if [[ ${update_dmnd_prot} = true || ! -s ${path_db}/all_protein.dmnd ]]; then
  # Merging all protein.faa.gz
  echo -ne "| ${colortitle}Merging     :${NC} ${nb_total} protein dmnd" ; rjust $((28+${#nb_total})) true
  title "genomedl | merging prot."
  cpt_done=0
  for ass_dir in ${path_db}/GC*
    do
    acc_name=$(get_base ${ass_dir})
    faa_path=$(ls -1 ${ass_dir}/*_protein.faa.gz 2>/dev/null || echo "None")
    if [ "${faa_path}" != "None" ]; then cat ${faa_path} >> ${dir_tmp}/all_protein.faa.gz ; fi
    ((cpt_done++))
    percent_done=$(( ${cpt_done}*100/${nb_total} ))
    progress ${percent_done} "${acc_name}" ${colorterm}
  done
  echo -e '\e[1A\e[K'
  # Makedb for merge proteins
  echo -ne "| ${colortitle}DiamondDB   :${NC}"
  title "genomedl | diamonddb prot."
  SPINNY_FRAMES=( " all protein                                         |" " all protein .                                       |" " all protein ..                                      |" " all protein ...                                     |" " all protein ....                                    |" " all protein .....                                   |")
  spinny::start
  ${diamond} makedb --in ${dir_tmp}/all_protein.faa.gz --db ${path_db}/all_protein.dmnd --quiet
  spinny::stop
  echo -ne " all protein" ; rjust 26 true
fi
# For *_phanotate.faa.gz
if [[ ${update_dmnd_phanotate} = true || ! -s ${path_db}/all_phanotate.dmnd ]]; then
  # Merging all phanotate.faa.gz
  echo -ne "| ${colortitle}Merging     :${NC} ${nb_total} phanotate dmnd" ; rjust $((30+${#nb_total})) true
  title "genomedl | merging phan."
  cpt_done=0
  for ass_dir in ${path_db}/GC*
    do
    acc_name=$(get_base ${ass_dir})
    faa_path=$(ls -1 ${ass_dir}/*_phanotate.faa.gz 2>/dev/null || echo "None")
    if [ "${faa_path}" != "None" ]; then cat ${faa_path} >> ${dir_tmp}/all_phanotate.faa.gz ; fi
    ((cpt_done++))
    percent_done=$(( ${cpt_done}*100/${nb_total} ))
    progress ${percent_done} "${acc_name}" ${colorterm}
  done
  echo -e '\e[1A\e[K'
  # Makedb for merge phanotate
  echo -ne "| ${colortitle}DiamondDB   :${NC}"
  title "genomedl | diamonddb phan."
  SPINNY_FRAMES=( " all phanotate                                       |" " all phanotate .                                     |" " all phanotate ..                                    |" " all phanotate ...                                   |" " all phanotate ....                                  |" " all phanotate .....                                 |")
  spinny::start
  ${diamond} makedb --in ${dir_tmp}/all_phanotate.faa.gz --db ${path_db}/all_phanotate.dmnd --quiet
  spinny::stop
  echo -ne " all phanotate" ; rjust 28 true
fi
# End postprocessing
echo -e "╰───────────────────────────────────────────────────────────────────╯"





# ************************************************************************* #
# *****                            SUMMARY                            ***** #
# ******************************************************************