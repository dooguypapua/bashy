#!/bin/bash


# ************************************************************************* #
# *****                           FUNCTIONS                           ***** #
# ************************************************************************* #
function header {
  echo -ne "╭─────────────────────────────────────────────────────────────────────╮\n|"
  echo -ne "${colortitle} ＶＩＲＩＤＩＣ  ｎ💫ｖａ ${NC}                                     v.1.0 "
  echo -ne "|\n╰─────────────────────────────────────────────────────────────────────╯\n"
}

function footer {
  echo -ne "╭─────────────────────────────────────────────────────────────────────╮\n|"
  echo -ne "${colortitle} ＶＩＲＩＤＩＣ  ｎ💥ｖａ  ｃｏｍｐｌｅｔｅｄ !                      ${NC}"
  echo -ne "|\n╰─────────────────────────────────────────────────────────────────────╯\n"
}

function rjust {
  i=1
  repeat_space=$((69-${1}))
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
  if [[ ${bool_in_progress} == true ]]; then echo -ne "\n╰─────────────────────────────────────────────────────────────────────╯\n" ; fi 
  echo -ne "╭─────────────────────────────────────────────────────────────────────╮\n| "
  echo -ne "${colorred}ERROR: ${NC}"
  echo -ne "┊ "
  echo -ne "${colorred}${str_error}${NC}"
  rjust $((${str_len_error}+10))
  echo -ne "\n╰─────────────────────────────────────────────────────────────────────╯\n"
  exit 1
}

function usage {
    echo -e "╭─────────────────────────────────────────────────────────────────────╮"
    echo -e "|"${colortitlel}$' USAGE: viridic_nova.sh -i DIR -o DIR (-t INT -w DIR)'${NC}"                |"
    echo "|                                                                     |"
    echo -e "|"${colortitlel}$' Required options:'${NC}"                                                   |"
    echo "|"$'  -i Input FASTA folder'"                                              |"
    echo "|"$'  -o Output results folder'"                                           |"
    echo "|                                                                     |"
    echo -e "|"${colortitlel}$' Optional options:'${NC}"                                                   |"
    echo "|"$'  -f Filter FASTA expression'"                                         |"
    echo "|"$'     Default       : *'"                                               |"
    echo "|"$'  -d Find FASTA maxdepth'"                                             |"
    echo "|"$'     Default       : 1'"                                               |"
    echo "|"$'  -t Number of threads'"                                               |"
    echo "|"$'     Default       : 0 (all)'"                                         |"
    echo "|"$'  -w Temporary folder'"                                                |"
    echo "|"$'     Default       : /tmp'"                                            |"
    echo "|                                                                     |"
    echo -e "|"${colortitlel}$' CMAP options:'${NC}"                                                       |"
    echo "|"$'  -1 Hexadecimal color for 0%'"                                        |"
    echo "|"$'     Default       : fffde4'"                                          |"
    echo "|"$'  -2 Hexadecimal color for 50%'"                                       |"
    echo "|"$'     Default       : None'"                                            |"
    echo "|"$'  -3 Hexadecimal color for 100%'"                                      |"
    echo "|"$'     Default       : 005AA7'"                                          |"
    echo "|"$'  (basicBlue   -1 fffde4 -3 005AA7) [default]'"                        |"
    echo "|"$'  (basicRed    -1 fffbd5 -3 b20a2c)'"                                  |"
    echo "|"$'  (tealTempest -1 78ffd6 -3 007991)'"                                  |"
    echo "|"$'  (oceanBlaze  -1 0ABFBC -3 FC354C)'"                                  |"
    echo "|                                                                     |"
    echo -e "|"${colortitlel}$' Tool locations: '${NC}"                                                    |"
    echo "|"$' Specify following tool location if not in ${PATH}'"                   |"
    echo "|"$'  --seqkit  '"                                                         |"
    echo "|"$'  --blastn (>=2.11)'"                                                  |"
    echo "|"$'  --blast_formatter (>=2.11)'"                                         |"
    echo "|"$'  --Rscript (>=2.11)'"                                                 |"
    echo "╰─────────────────────────────────────────────────────────────────────╯"
}

function progress() {
    # progress percent text color
    local w=30 p=$1 color=$2; shift
    echo -ne "| "
    # create a string of spaces, then change them to dots
    printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /.}
    # print those dots on a fixed-width space plus the percentage etc. 
    printf "\r\e[K|%-*s| %3d%%" "$w" "$dots" "$p"
    rjust 36 false
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
  if [ "$(type -t title)" = "function" ]; then title "viridic | ${title_str} (${percent_done}%%)" ;fi
}

function pwait() {
  while [ $(jobs -r -p | wc -l) -ge $1 ]; do
      sleep 1
  done
}

function summary {
  title "viridic | summary"
  echo -e "╭─INFO────────────────────────────────────────────────────────────────╮"
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
  echo -e "╰─────────────────────────────────────────────────────────────────────╯\n"
  title "viridic | finished"
}

function make_viridic_script {
  VIRIDIC_SCRIPT=$(cat <<'EOF'
suppressPackageStartupMessages(
    { library(magrittr, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(tibble, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(purrr, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(seqinr, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(stringr, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(tidyr, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(IRanges, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(reshape2, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(pheatmap, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(ggplot2, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(fastcluster, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(parallelDist, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(furrr, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE)
library(future, quietly = TRUE, warn.conflicts = FALSE, verbose = FALSE) }) 
input0 <- as.character(commandArgs(trailingOnly = TRUE))
in1 <- str_which(input0, "blastres=")
in2 <- str_which(input0, "out=")
input <- ""
input[1] <- str_remove(input0[in1], "blastres=")
input[2] <- str_remove(input0[in2], "out=")
blastn_out_path <- input[1]
outfmt<- ' -outfmt "6 qseqid sseqid evalue bitscore qlen slen qstart qend sstart send qseq sseq nident gaps"'
nident_fun <- function(DF, gen_len) {
  if(nrow(DF)== 1) { dfs <- DF%>% mutate(nident_recalc = nident)%>% mutate(alig_q = abs(qstart-qend)+1) }
  else {
    dfs <- DF %>% filter(qstart == 1, qend == gen_len)
    if(nrow(dfs) == 1) { dfs <- dfs%>% mutate(nident_recalc = nident)%>% mutate(alig_q = abs(qstart-qend)+1) }
    else {
      if(nrow(dfs) == 0) {
        rm(dfs) ; ir <- IRanges(start = as.numeric(DF$qstart), end = as.numeric(DF$qend), names = seq(from = 1, to = nrow(DF))); cov <- coverage(ir) %>% as.vector() ; cov2 <- cov[cov >1]
        if(length(cov2) == 0) { dfs <- DF %>% mutate(nident_recalc = nident)%>% mutate(alig_q = abs(qstart-qend)+1) }
        else {
          rm(ir, cov, cov2) ; dfs <- DF %>% mutate(alig_q = abs(qstart-qend)+1) %>% arrange(desc(alig_q))
          for(a in nrow(dfs):2) {
            for(b in 1:(a-1)) { if(dfs$qstart[b] <= dfs$qstart[a] & dfs$qend[a] <= dfs$qend[b]) { dfs <- dfs[-a, ] ; break() } }
            rm(b)
          }
          rm(a) ; ir <- IRanges(start = dfs$qstart, end = dfs$qend, names = seq(from = 1, to = nrow(dfs))) ; cov <- coverage(ir) %>% as.vector() ; cov2 <- cov[cov >1]
          if(length(cov2) > 0) {
            for(i in nrow(dfs):1) {
              cov_r <- cov[dfs$qstart[i]:dfs$qend[i]] %>% min()
              if(cov_r > 1) { dfs <- dfs[-i, ] ; ir <- IRanges(start = dfs$qstart, end = dfs$qend, names = seq(from = 1, to = nrow(dfs))) ; cov <- coverage(ir) %>% as.vector() }
              rm(cov_r) }
            rm(i) ; cov2 <- cov[cov >1]
            if(length(cov2) == 0) { dfs <- dfs %>% mutate(nident_recalc = nident) }
            else {
              dfs <- dfs %>% arrange(dplyr::desc(qstart)) %>% mutate(nident_recalc = nident) %>% mutate(qstart_recalc = qstart) %>% mutate(qend_recalc = qend)
              for(a in nrow(dfs):2) {
                for(b in (a-1):1) {
                  if((dfs$qend_recalc[a] >= dfs$qstart_recalc[b]) & (dfs$qstart_recalc[a] < dfs$qstart_recalc[b])) {
                    overlap <- dfs$qend_recalc[a] - dfs$qstart_recalc[b] + 1
                    q_over_a <- dfs$qseq[a] %>% str_replace_all("-", "") %>% str_sub(start = -overlap, end = -1) %>% s2c %>% paste0("-*") %>% c2s()
                    q_over_a_ext <- dfs$qseq[a] %>% str_extract(q_over_a) %>% s2c() 
                    s_over_a <- dfs$sseq[a] %>% str_sub(start = -length(q_over_a_ext), end = -1) %>% s2c()
                    diffe_a <- str_match(q_over_a_ext, s_over_a) %>% is.na() %>% sum()
                    dfs[a,"nident_recalc"] <- dfs$nident[a] - (length(q_over_a_ext) - diffe_a)
                    dfs[a, "qend_recalc"] <- dfs$qstart_recalc[b]-1
                    rm(overlap, q_over_a, q_over_a_ext, s_over_a, diffe_a)
                  }}}}}
          else { dfs <- dfs %>% mutate(nident_recalc = nident) }
        }
      }else { dfs <- dfs%>% mutate(nident_recalc = 100000)%>% mutate(alig_q = abs(qstart-qend)+1) }
    }
  }
  nident_o <- sum(dfs$nident_recalc)
  align_q_o <- sum(dfs$alig_q)
  outp <- c(nident_o, align_q_o)
  return(outp)
}
s_nident_fun <- function(q, s, DF) {
  DF2 <- DF %>% filter(sseqid == q, qseqid == s)
  if(nrow(DF2) == 1) { ret <- c(DF2$q_nident, DF2$q_fract_aligned) }
  else {
    if(nrow(DF2) == 0) { ret <- c(0, 0) }
    else { ret <- c(-100, -100) }
  }
  return(ret)
}
det_dist_fun <- function(simDF, th, sim_dist) {
  simDF_ma <- as.matrix(simDF)
  th <- as.numeric(th)
  if(sim_dist == "distance") { th <- 100 - th; elems <- base::which(simDF <= th); intergenome <- simDF_ma[elems] %>% max() }
  else { elems <- base::which(simDF >= th); intergenome <- simDF_ma[elems] %>% min() }
  sel_elem <- which(simDF == intergenome)
  return(sel_elem)
}
blastn_DF <- data.table::fread(blastn_out_path, sep = "\t", header = FALSE, stringsAsFactors = FALSE, drop = c(3, 4))
colnames(blastn_DF) <- c("qseqid", "sseqid", "qlen", "slen", "qstart", "qend", "sstart", "send", "qseq", "sseq", "nident", "gaps")
blastn_DF_g <- blastn_DF %>%
  group_by(qseqid, sseqid, qlen, slen) %>%
  nest()
rm(blastn_DF)
# adjust workers to half main thread
plan(multisession)
options(future.globals.maxSize = 1073741824)
outp_ls <- future_map2(.x = blastn_DF_g$data, .y = blastn_DF_g$qlen, .f = nident_fun)
blastn_DF_g[, "q_nident"] <- lapply(outp_ls, "[[", 1) %>%
  unlist()
blastn_DF_g[, "q_aligned"] <- lapply(outp_ls, "[[", 2) %>%
  unlist()
blastn_DF_g <- blastn_DF_g %>%
  mutate(q_fract_aligned = round(q_aligned/qlen, digits = 2))
rm(outp_ls)
#options(future.globals.maxSize = 1073741824)
ret_ls <- future_map2(.x = blastn_DF_g$qseqid, .y = blastn_DF_g$sseqid, .f = s_nident_fun, DF = blastn_DF_g)
blastn_DF_g[, "s_nident"] <- lapply(ret_ls, "[", 1) %>%
  unlist
blastn_DF_g[, "s_fract_aligned"] <- lapply(ret_ls, "[", 2) %>%
  unlist
rm(ret_ls)
blastn_DF_gbkp <- blastn_DF_g
blastn_DF_g <- blastn_DF_gbkp %>%
  select(-data) %>%
  ungroup() %>%
  mutate(qs_nident = (as.numeric(q_nident) + as.numeric(s_nident))) %>%
  mutate(qs_len = (qlen + slen)) %>%
  mutate(interg_sim = (qs_nident/qs_len)*100) %>%
  mutate(interg_sim = round(interg_sim, digits =3)) %>%
  mutate(fract_qslen = (pmin(qlen, slen)/pmax(qlen,slen))) %>%
  mutate(fract_qslen = round(fract_qslen, digits = 1)) %>%
  select(qseqid, sseqid, qlen, slen, q_nident, q_aligned, s_nident, qs_nident, qs_len, interg_sim, fract_qslen, q_fract_aligned, s_fract_aligned)
blastn_DF_g <- blastn_DF_g %>%
  as.data.frame(stringsAsFactors = FALSE)
write.table(x = blastn_DF_g, file = paste0(input[2]), sep = "\t", row.names = FALSE, col.names = TRUE)
EOF
)
  R_thread=${2}
  echo "${VIRIDIC_SCRIPT}" | sed s/"plan(multisession)"/"plan(multisession, workers = $((R_thread/2)))"/ > ${1}
}

function make_python_matrix_script {
  PYTHON_SCRIPT=$(cat <<EOF
IN = open("${2}", 'r')
lstLines = IN.read().split("\n")
IN.close()
dicoMatrix = {}
for line in lstLines[:-1]:
    splitLine = line.split("\t")
    try: dicoMatrix[splitLine[0]][splitLine[1]] = float(splitLine[2])
    except KeyError: dicoMatrix[splitLine[0]] = {splitLine[0]: "100.0", splitLine[1]: float(splitLine[2])}
    try: dicoMatrix[splitLine[1]][splitLine[0]] = float(splitLine[2])
    except KeyError: dicoMatrix[splitLine[1]] = {splitLine[1]: "100.0", splitLine[0]: float(splitLine[2])}
OUT = open("${3}", 'w')
OUT.write("\t"+"\t".join(list(dicoMatrix.keys()))+"\n")
for phage1 in dicoMatrix:
    line = phage1
    for phage2 in dicoMatrix:
        try: line += "\t"+str(dicoMatrix[phage1][phage2])
        except KeyError: line += "\t0.0"
    OUT.write(line+"\n")
OUT.close()
EOF
)
  echo "${PYTHON_SCRIPT}" > ${1}
}

function make_python_assign_script {
  PYTHON_SCRIPT=$(cat <<EOF
import pandas as pd
import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors as colors
pathIN="${2}/viridic_matrix.tsv"
pathOUTphage="${2}/viridic_per_phage.tsv"
pathOUTrank="${2}/viridic_per_rank.tsv"
pathOUTcluster="${2}/viridic_clustered_matrix.tsv"
pathOUTpng="${2}/viridic_clustered_matrix.png"
pathOUTsvg="${2}/viridic_clustered_matrix.svg"
cmap_min="${3}"
cmap_med="${4}"
cmap_max="${5}"
IN = open(pathIN,'r')
lstLines = IN.read().split("\n")
IN.close()
lstColName = lstLines[0].split("\t")
dicoDist = {}
for line in lstLines[1:]:
    if line != "" and not line[0] == "#":
        splitLine = line.split("\t")
        dicoDist[splitLine[0]] = {}
        for i in range(1,len(splitLine),1):
            try: dicoDist[splitLine[0]][lstColName[i]] = float(splitLine[i])
            except: dicoDist[splitLine[0]][lstColName[i]] = 0.0

dicoTaxo = {'family': {}, 'genus': {}, 'specie': {}}
for orgName1 in dicoDist:
    for orgName2 in dicoDist:
        for orderTuple in [("family", 50), ("genus", 70), ("specie", 95)]:
            if dicoDist[orgName1][orgName2] >= orderTuple[1]:
                findOrder = False
                for orderNum in dicoTaxo[orderTuple[0]]:
                    if orgName1 in dicoTaxo[orderTuple[0]][orderNum] or orgName2 in dicoTaxo[orderTuple[0]][orderNum]:
                        dicoTaxo[orderTuple[0]][orderNum].update({orgName1, orgName2})
                        findOrder = True
                        break
                if findOrder is False:
                    dicoTaxo[orderTuple[0]][len(dicoTaxo[orderTuple[0]])+1] = set({orgName1, orgName2})
# Per rank dict
OUTrank = open(pathOUTrank, 'w')
for level in dicoTaxo:
    for group in dicoTaxo[level]:
        OUTrank.write(level+"\t"+str(group)+"\t"+",".join(dicoTaxo[level][group])+"\n")
OUTrank.close()
# Per phage dict
OUTphage = open(pathOUTphage, 'w')
dicoPerPhage = {}
for level in dicoTaxo:
    for group in dicoTaxo[level]:
        for phageName in dicoTaxo[level][group]:
            OUTphage.write(phageName+"\t"+level+"\t"+str(group)+"\n")
OUTphage.close()
# Clustering matrix and plots
df = pd.DataFrame(dicoDist)
# CMAP colors
if cmap_min[0] != "#": cmap_min = "#"+cmap_min
if cmap_med != "None" and cmap_med[0] != "#": cmap_med = "#"+cmap_med
if cmap_max[0] != "#": cmap_max = "#"+cmap_max
if cmap_med == "None": cmap = colors.LinearSegmentedColormap.from_list('my_cmap', [cmap_min, cmap_max])
else: cmap = colors.LinearSegmentedColormap.from_list('my_cmap', [cmap_min, cmap_med, cmap_max])
cg = sns.clustermap(df, cmap=cmap, method="complete", metric='euclidean', figsize=(50, 50), tree_kws={'linewidths': 2.5}, dendrogram_ratio=0.15, annot_kws={"size": 35 / np.sqrt(len(df))}, vmin=0, xticklabels=df.columns.values, yticklabels=df.index.values, linewidths=0.0, rasterized=True)
# Retrieve ordered ticks label
newColums = df.columns[cg.dendrogram_col.reordered_ind]
newIndexs = df.index[cg.dendrogram_row.reordered_ind]
newData = df.loc[newIndexs, newColums]
orderedOrg = list(newData.keys())
# Plot clustered heatmap
cg.ax_cbar.tick_params(labelsize=40)
cg.ax_cbar.yaxis.label.set_size(50)
font_size = int(100 / np.sqrt(len(df)))
cg.ax_heatmap.tick_params(labelsize=font_size)
cg.savefig(pathOUTpng, dpi=300)
cg.savefig(pathOUTsvg)
OUT = open(pathOUTcluster, 'w')
header = "Organism"
for orgName in orderedOrg:
    header += "\t"+orgName
OUT.write(header+"\n")
for orgName1 in orderedOrg:
    line = orgName1
    for orgName2 in orderedOrg:
        line += "\t"+str(dicoDist[orgName1][orgName2]).replace(".", ",")
    OUT.write(line+"\n")
OUT.close()
EOF
)
  echo "${PYTHON_SCRIPT}" > ${1}
}



# ************************************************************************* #
# *****                        INITIALIZATION                         ***** #
# ************************************************************************* #
if [ -n $SLURM_JOB_ID ] && [ "$SLURM_JOB_ID" != "" ]
  then
  slurm_bool=true
  job_id="$SLURM_JOB_ID"
  src_path=$(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d " " -f 1)
  if [[ -f "`dirname \"$src_path\"`"/bashy/functions.sh ]]; then source "`dirname \"$src_path\"`"/bashy/functions.sh ; fi
  if [[ -f "`dirname \"$src_path\"`"/bashy/spinny.sh ]]; then source "`dirname \"$src_path\"`"/bashy/spinny.sh ; fi
else
  threads=0
  if [[ -f "`dirname \"$0\"`"/functions.sh ]]; then source "`dirname \"$0\"`"/functions.sh ; fi
  if [[ -f "`dirname \"$0\"`"/spinny.sh ]]; then source "`dirname \"$0\"`"/spinny.sh ; fi
fi
if [ "$(type -t title)" = "function" ]; then title "viridic workflow" ; fi
# ***** INITIALIZATION ***** #
# Variables
maxdepth=1
fasta_filter="*"
tmp_folder="/tmp"
start_time=$SECONDS
n_strech_len=100
n_strech=$(printf "N%.0s" $(seq 1 $n_strech_len))
outfmt='6 qseqid sseqid evalue bitscore qlen slen qstart qend sstart send qseq sseq nident gaps'
outfmt_reverse='6 sseqid qseqid evalue bitscore slen qlen sstart send qstart qend sseq qseq nident gaps'
blast_param='-evalue 1 -max_target_seqs 50000 -word_size 7 -reward 2 -penalty -3 -gapopen 5 -gapextend 2'
# R and python packages
r_packages=("magrittr" "dplyr" "tibble" "purrr" "seqinr" "stringr" "tidyr" "IRanges" "reshape2" "pheatmap" "ggplot2" "fastcluster" "parallelDist" "furrr" "future")
py_packages=("pandas" "seaborn" "numpy" "matplotlib")
# viridic="viridic"
seqkit=$(which seqkit)
blastn=$(which blastn)
blast_formatter=$(which blast_formatter)
rscript=$(which Rscript)
# Colors
colortitle='\x1b[38;2;255;176;46m'
colortitlel='\x1b[38;2;225;224;130m'
colorred='\x1b[38;2;255;85;85m'
colorterm='\x1b[38;2;204;204;204m'
NC='\x1b[0m'
# Header
header
# Display usage if any argument
if [[ ${#} -eq 0 ]]; then usage ; exit 1 ; fi
# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--seqkit") set -- "$@" "-s" ;;
    "--blastn") set -- "$@" "-b" ;;
    "--blast_formatter") set -- "$@" "-c" ;;
    "--rscript") set -- "$@" "-e" ;;
    *) set -- "$@" "$arg"
  esac
done
# list of arguments expected in the input
ref_fasta_list=""
optstring=":i:o:f:d:v:t:s:b:c:e:g:1:2:3:w:h"
while getopts ${optstring} arg; do
  case ${arg} in
    h) usage ; exit 0 ;;
    i) path_dir_in="${OPTARG}" ;;
    o) path_dir_out="${OPTARG}" ;;
    f) fasta_filter="${OPTARG}" ;;
    d) maxdepth="${OPTARG}" ;;
    w) tmp_folder="${OPTARG}" ;;
    t) threads="${OPTARG}" ;;
    s) seqkit="${OPTARG}" ;;
    b) blastn="${OPTARG}" ;;
    c) blast_formatter="${OPTARG}" ;;
    e) rscript="${OPTARG}" ;;
    1) cmap_min="${OPTARG}" ;;
    2) cmap_med="${OPTARG}" ;;
    3) cmap_max="${OPTARG}" ;;
    :) usage ; display_error "Must supply an argument to -$OPTARG." false ; exit 1 ;;
    ?) usage ; display_error "Invalid option: -${OPTARG}." false ; exit 2 ;;
  esac
done
# Check missing required arguments
if [[ -z "${path_dir_in}" ]]; then usage ; display_error "Input FASTA folder is required (-i)" false ; fi
if [[ ! -d "${path_dir_in}" ]]; then usage ; display_error "Input FASTA folder not found (-i)" false ; fi
if [[ -z "${path_dir_out}" ]]; then usage ; display_error "Output results folder is required (-o)" false ; fi
# Check arguments format
if [[ ! -z "${maxdepth}" && ! "${maxdepth}" =~ ^[0-9,]+$ ]]; then usage ; display_error "Find FASTA maxdepth is invalid (must be integer)" false ; fi
if [[ ! -z "${threads}" && ! "${threads}" =~ ^[0-9,]+$ ]]; then usage ; display_error "Number of threads is invalid (must be integer)" false ; fi
if [ $threads == 0 ]; then threads=$(grep -c ^processor /proc/cpuinfo) ; fi
# Check cmap colors
if [[ -z "${cmap_min}" && -z "${cmap_med}" && -z "${cmap_max}" ]]; then
  cmap_min="#fffde4" ; cmap_med="None" ; cmap_max="#005AA7"
  check_cmap=true
elif [[ ! -z "${cmap_min}" && ! -z "${cmap_med}" && ! -z "${cmap_max}" ]]; then
  check_cmap=true
elif [[ ! -z "${cmap_min}" && ! -z "${cmap_max}" ]]; then
  cmap_med="None"
  check_cmap=true
else
  check_cmap=false
fi
if [ "$check_cmap" = "false" ]; then usage ; display_error "CMAP arguments must be -1 (& -2) & -3" false ; fi
if [[ ! $cmap_min =~ ^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$ ]]; then usage ; display_error "CMAP hexadecimal color for 0% is invalid (must be hexa)" false ; fi
if [[ "$cmap_med" != "None" && ! $cmap_med =~ ^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$ ]]; then usage ; display_error "CMAP hexadecimal color for 50% is invalid (must be hexa)" false ; fi
if [[ ! $cmap_max =~ ^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$ ]]; then usage ; display_error "CMAP hexadecimal color for 100% is invalid (must be hexa)" false ; fi
# Check free memory
total_mem=$(free -g | awk '/Mem/ {print $7}')
max_memory=$((total_mem*75/100))
# Check tools
if ! command -v ${blastn} &> /dev/null; then display_error "blastn not found (use \$PATH or specify it)" false ; fi
blastn_version=$(${blastn} -version | grep -oP 'blastn: \K\d+\.\d+\.\d+')
if [ "$(printf '%s\n' "$blastn_version" "2.11.0" | sort -V | tail -n1)" = "2.11.0" ];  then display_error "blastn version is older than 2.11 (found ${blastn_version})" false ; fi
if ! command -v ${blast_formatter} &> /dev/null; then display_error "blast_formatter not found (use \$PATH or specify it)" false ; fi
blast_formatter_version=$(${blast_formatter} -version | grep -oP 'blast_formatter: \K\d+\.\d+\.\d+')
if [ "$(printf '%s\n' "$blast_formatter_version" "2.11.0" | sort -V | tail -n1)" = "2.11.0" ];  then display_error "blast_formatter version is older than 2.11 (found ${blast_formatter_version})" false ; fi
if ! command -v ${seqkit} &> /dev/null; then display_error "seqkit not found (use \$PATH or specify it)" false ; fi
if ! command -v ${rscript} &> /dev/null; then display_error "rscript not found (use \$PATH or specify it)" false ; fi
# Output Folder/Files
mkdir -p ${path_dir_out} ${path_dir_out}/blastn ${path_dir_out}/viridic 2>/dev/null
if [[ ! $? -eq 0 ]] ; then usage && display_error "Cannot create output directory" false ; fi
# History file
if [[ ! -f "${path_dir_out}/history.txt" ]]; then touch "${path_dir_out}/history.txt" ; fi
# Log file
log="${path_dir_out}/viridic_nova.log"
rm -f ${log}
touch ${log}
# Temporary folder and files
uuidgen=$(uuidgen | cut -d "-" -f 1,2)
dir_tmp="${tmp_folder}/viridic_${uuidgen}"
mkdir -p ${dir_tmp} ${dir_tmp}/blastn ${dir_tmp}/viridic 2>/dev/null
if [[ ! $? -eq 0 ]] ; then usage && display_error "Cannot create temp directory" false ; fi
# Create VIRIDIC script
path_viridic_modif="${dir_tmp}/viridic.R"
make_viridic_script ${path_viridic_modif} $((threads/3))


# ************************************************************************* #
# *****                         PREPROCESSING                         ***** #
# ************************************************************************* #
in=$(echo ${path_dir_in} | sed 's/.*\(.\{49\}\)/...\1/')
out=$(echo ${path_dir_out} | sed 's/.*\(.\{49\}\)/...\1/')
# ***** INPUT INFOS ***** #
echo -e "╭─${colortitlel}INIT${NC}────────────────────────────────────────────────────────────────╮"
echo -ne "| ${colortitle}Input folder  : ${NC}${in}" ; rjust $((17+${#in})) true
if [ "${fasta_filter}" != "*" ]; then echo -ne "| ${colortitle}FASTA filter  : ${NC}${fasta_filter}" ; rjust $((17+${#fasta_filter})) true ; fi
# ***** CHECK INPUT FASTA & MAKE PATH ASSOCIATIVE ARRAY ***** #
SPINNY_FRAMES=( "| Read input                                                          |" "| Read input  .                                                       |" "| Read input  ..                                                      |" "| Read input  ...                                                     |" "| Read input  ....                                                    |" "| Read input  .....                                                   |")
spinny::start
declare -A file_paths
for fasta_phage in $(find ${path_dir_in} -maxdepth ${maxdepth} -type f | grep -E ".*${fasta_filter}.*\.(fna|fasta|fa)(\.gz)?$"); do
  if [[ -f "${fasta_phage}" ]]; then 
    phage_name=$(basename ${fasta_phage} | sed -e s/"_genomic.fna.gz"/""/ -e s/".fna"/""/ -e s/".fasta"/""/ -e s/".fa"/""/ -e s/".gz"/""/)
    file_paths["$phage_name"]="$fasta_phage"
  fi
done
spinny::stop
# Check number of FASTA found
array_size=${#file_paths[@]}
if [ ${array_size} -lt 2 ]; then
  display_error "${array_size} FASTA was found (must be greater than 2)" true
else
  echo -ne "| ${colortitle}Phage FASTA   : ${NC}${array_size} files" ; rjust $((23+${#array_size})) true
fi
# ***** OTHERS INFOS ***** #
echo -ne "| ${colortitle}Output dir    : ${NC}${out}" ; rjust $((17+${#out})) true
echo -ne "| ${colortitle}TMP folder    : ${NC}${dir_tmp}" ; rjust $((17+${#dir_tmp})) true
echo -ne "| ${colortitle}Threads       : ${NC}${threads}" ; rjust $((17+${#threads})) true
if [[ "$cmap_med" == "None" ]]; then
  echo -ne "| ${colortitle}CMAP colors   : ${NC}${cmap_min} > ${cmap_max}" ; rjust $((20+${#cmap_min}+${#cmap_max})) true
else
  echo -ne "| ${colortitle}CMAP colors   : ${NC}${cmap_min} > ${cmap_med} > ${cmap_max}" ; rjust $((23+${#cmap_min}+${#cmap_med}+${#cmap_max})) true
fi
# Check R packages
SPINNY_FRAMES=( "| Check R packages                                                    |" "| Check R packages  .                                                 |" "| Check R packages  ..                                                |" "| Check R packages  ...                                               |" "| Check R packages  ....                                              |" "| Check R packages  .....                                             |")
spinny::start
for package in "${r_packages[@]}"; do
  if ! Rscript -e "if(!require('${package}', quietly = TRUE)) stop()" 2>/dev/null ; then display_error "Required R package \"${package}\" not found" false ; fi
done
spinny::stop
# Check python packages
SPINNY_FRAMES=( "| Check python packages                                               |" "| Check python packages  .                                            |" "| Check python packages  ..                                           |" "| Check python packages  ...                                          |" "| Check python packages  ....                                         |" "| Check python packages  .....                                        |")
spinny::start
for package in "${py_packages[@]}"; do
  python -c "import ${package}" 2>/dev/null || display_error "Required python package \"${package}\" not found" false
done
spinny::stop
# Init python scripts
make_python_matrix_script ${dir_tmp}/matrix.py ${dir_tmp}/all_viridic.out ${path_dir_out}/viridic_matrix.tsv
make_python_assign_script ${dir_tmp}/assign.py ${path_dir_out} ${cmap_min} ${cmap_med} ${cmap_max}
echo -e "╰─────────────────────────────────────────────────────────────────────╯"


# ************************************************************************* #
# *****                          PROCESSING                           ***** #
# ************************************************************************* #
echo -e "╭─${colortitlel}PROCESSING${NC}──────────────────────────────────────────────────────────╮"

# ***** CHECK AVAILABLE BlastN comparisons ***** #
echo -ne "| ${colortitle}Check history :${NC}"
SPINNY_FRAMES=( " init comparisons                                    |" " init comparisons .                                  |" " init comparisons ..                                 |" " init comparisons ...                                |" " init comparisons ....                               |" " init comparisons .....                              |")
spinny::start
# Generate all expected comparisons
nb_expected_comp=0
for phage_name1 in "${!file_paths[@]}"; do
  path_final_blast="${path_dir_out}/blastn/${phage_name1}.out"
  if [[ ! -f "${path_final_blast}" ]]; then touch "${path_final_blast}" ; fi
  for phage_name2 in "${!file_paths[@]}"; do
    if [[ $phage_name1 != $phage_name2 ]]; then
      echo -e "${phage_name1}\t${phage_name2}" >> ${dir_tmp}/results_expected.txt
      ((nb_expected_comp++))
    fi
  done
done
sort -o ${dir_tmp}/results_expected.txt ${dir_tmp}/results_expected.txt
nb_expected_comp=$((nb_expected_comp/2)) # for reciprocal comparison
spinny::stop
# Check missing blastn
SPINNY_FRAMES=( " check missing                                       |" " check missing .                                     |" " check missing ..                                    |" " check missing ...                                   |" " check missing ....                                  |" " check missing .....                                 |")
spinny::start
# Sort / diff / remove reciprocal blast like AvsB and BvsA
sort ${path_dir_out}/history.txt | diff --speed-large-files ${dir_tmp}/results_expected.txt - | grep "<" | cut -d " " -f 2,3 > ${dir_tmp}/results_missing.txt
cat ${dir_tmp}/results_missing.txt | awk '{if ($1 < $2) print $0; else if ($1 > $2) print $2"\t"$1}' | sort -u > ${dir_tmp}/results_missing_reduce.txt
nb_missing_comp=$(wc -l <${dir_tmp}/results_missing_reduce.txt)
spinny::stop
if [[ ${nb_missing_comp} -eq 0 ]]; then
  echo -ne "| ${colortitle}Check history :${NC} ${nb_expected_comp} [up-to-date]" ; rjust $((${#nb_expected_comp}+30)) true
else
  echo -ne '\r\e[K'
  echo -ne "| ${colortitle}Check history :${NC} ${nb_missing_comp}/${nb_expected_comp} missing" ; rjust $((${#nb_expected_comp}+${#nb_missing_comp}+26)) true
fi

# ***** LAUNCH missing blastn comparisons ***** #
# blast output could be empty if any similarity found
if [[ ! ${nb_missing_comp} -eq 0 ]]; then
  echo -ne "| ${colortitle}Launch BlastN :${NC}${colortitlel} in progress${NC}" ; rjust 28 true
  arrayPid=()
  cpt_done=0
  while IFS=$'\t' read -r line; do
    phage_name1=$(echo -e "${line}" | cut -f 1)
    path_fasta_src1="${file_paths["$phage_name1"]}"
    path_fasta_reformat1="${dir_tmp}/${phage_name1}.fasta"
    path_missing_blast1="${dir_tmp}/blastn/${phage_name1}.out"
    path_final_blast1="${path_dir_out}/blastn/${phage_name1}.out"
    phage_name2=$(echo -e "${line}" | cut -f 2)
    path_fasta_src2="${file_paths["$phage_name2"]}"
    path_fasta_reformat2="${dir_tmp}/${phage_name2}.fasta"
    path_missing_blast2="${dir_tmp}/blastn/${phage_name2}.out"  
    path_final_blast2="${path_dir_out}/blastn/${phage_name2}.out"
    # Join contig with 'N' and use filename as header
    if [[ ! -f "${path_fasta_reformat1}" ]]; then 
      seqkit seq ${path_fasta_src1} -w 0 -s > ${path_fasta_reformat1} 2>> ${log} 2>&1 || display_error "seqkit for '${phage_name1}'" true
      awk -v s="$n_strech" '{printf("%s%s", (NR>1)?(i++?s:""):"",$0)} END{print ""}' ${path_fasta_reformat1} > ${dir_tmp}/temp.fasta
      echo ">${phage_name1}" > ${path_fasta_reformat1}
      cat ${dir_tmp}/temp.fasta >> ${path_fasta_reformat1}
    fi
    if [[ ! -f "${path_fasta_reformat2}" ]]; then 
      seqkit seq ${path_fasta_src2} -w 0 -s > ${path_fasta_reformat2} 2>> ${log} 2>&1 || display_error "seqkit for '${phage_name2}'" true
      awk -v s="$n_strech" '{printf("%s%s", (NR>1)?(i++?s:""):"",$0)} END{print ""}' ${path_fasta_reformat2} > ${dir_tmp}/temp.fasta
      echo ">${phage_name2}" > ${path_fasta_reformat2}
      cat ${dir_tmp}/temp.fasta >> ${path_fasta_reformat2}
    fi
    # Launch blast
    job_name="${phage_name1}_____${phage_name2}"
    bash_process="${dir_tmp}/${job_name}_blast.sh"
    # Construct process bash: blast > Reformat blast (for reverse don't forget to inverse subjectpos if reverse) > cat > clean
    echo -e "${blastn} -query ${path_fasta_reformat1} -subject ${path_fasta_reformat2} -out ${dir_tmp}/${job_name}_blast.asn -outfmt \"11\" ${blast_param}" > ${bash_process}
    echo -e "${blast_formatter} -archive ${dir_tmp}/${job_name}_blast.asn -outfmt \"${outfmt}\" -out ${dir_tmp}/${job_name}_blast.out " >> ${bash_process}
    echo -e "${blast_formatter} -archive ${dir_tmp}/${job_name}_blast.asn -outfmt \"${outfmt_reverse}\" | awk '{OFS=\"\\\\t\"; if(\$7>\$8) {t=\$7; \$7=\$8; \$8=t ; t=\$9; \$9=\$10; \$10=t} print}' > ${dir_tmp}/${job_name}_blastr.out" >> ${bash_process}
    echo -e "echo \"\" >> ${dir_tmp}/${job_name}_blast.out" >> ${bash_process}
    echo -e "echo \"\" >> ${dir_tmp}/${job_name}_blastr.out" >> ${bash_process}
    # Launch process
    bash ${bash_process} 2>>${log} &
    arrayPid+=($!)
    pwait ${threads} ; parallel_progress "blastn" "${nb_missing_comp}"
  done < ${dir_tmp}/results_missing_reduce.txt
  # Final wait & progress
  while [ $(jobs -p | wc -l) -gt 1 ]; do parallel_progress "blastn" "${nb_missing_comp}" ; sleep 1 ; done
  rm -f ${dir_tmp}/*_blast.sh ${dir_tmp}/blastn/*.lock ${path_dir_out}/blastn/*.lock
  echo -ne '\e[1A\e[K'
  echo -ne '\e[1A\e[K'
  echo -ne "| ${colortitle}Launch BlastN :${NC} done" ; rjust 21 true
fi


# ***** MERGE blastn results ***** #
if [[ ! ${nb_missing_comp} -eq 0 ]]; then
  nb_blast_out=$(find "${dir_tmp}/" -type f -name '*_blast*.out' | wc -l)
  echo -ne "| ${colortitle}Merging       :${NC} ${nb_blast_out} blast out" ; rjust $((27+${#nb_blast_out})) true
  if [ "$(type -t title)" = "function" ]; then title "viridic | merge .out" ; fi
  cpt_done=0
  for blast_file in ${dir_tmp}/*_blast.out; do 
    job_name=$(basename $blast_file | sed s/"_blast.out"/""/)
    phage_name1=$(echo $job_name | awk '{ gsub(/_____/, " " ); print $1; }')
    cat ${blast_file} >> "${dir_tmp}/blastn/${phage_name1}.out"
    cat ${blast_file} >> "${path_dir_out}/blastn/${phage_name1}.out"
    ((cpt_done++))
    percent_done=$(( ${cpt_done}*100/${nb_blast_out} ))
    progress ${percent_done} "" ${colorterm}
  done
  for blastr_file in ${dir_tmp}/*_blastr.out; do 
    job_name=$(basename $blastr_file | sed s/"_blastr.out"/""/)
    phage_name2=$(echo $job_name | awk '{ gsub(/_____/, " " ); print $2; }')
    cat ${blastr_file} >> "${dir_tmp}/blastn/${phage_name2}.out"
    cat ${blastr_file} >> "${path_dir_out}/blastn/${phage_name2}.out"
    ((cpt_done++))
    percent_done=$(( ${cpt_done}*100/${nb_blast_out} ))
    progress ${percent_done} ${colorterm}
  done
  echo -e '\e[1A\e[K'
fi


# ***** LAUNCH missing viridic comparisons ***** #
if [[ ! ${nb_missing_comp} -eq 0 ]]; then
  echo -ne "| ${colortitle}Launch VIRIDIC:${NC}${colortitlel} in progress${NC}" ; rjust 28 true
  rm -f ${dir_tmp}/blastn/*.lock
  nb_blast_file=$(ls -f1 ${dir_tmp}/blastn | wc -l)
  arrayPid=()
  cpt_done=0
  for blast_out in ${dir_tmp}/blastn/*.out; do
    # Remove empty line in blastn files
    sed -i '/^$/d' ${blast_out}
    path_missing_viridic=${dir_tmp}/viridic/$(basename ${blast_out})
    path_final_viridic=${path_dir_out}/viridic/$(basename ${blast_out})
    # Launch viridic
    # ${rscript} ${path_viridic_modif} blastres=${blast_out} out=${path_missing_viridic} 2>&1 >>${log} &
    ${rscript} --vanilla --verbose ${path_viridic_modif} blastres=${blast_out} out=${path_missing_viridic} 2>>${log} &
    arrayPid+=($!)
    pwait ${threads} ; parallel_progress "viridic" "${nb_blast_file}"
  done
  # Final wait & progress
  while [ $(jobs -p | wc -l) -gt 1 ]; do parallel_progress "viridic" "${nb_blast_file}" ; sleep 1 ; done
  echo -e '\e[1A\e[K'
  echo -ne '\e[1A\e[K'
  echo -ne "| ${colortitle}Launch VIRIDIC:${NC} done" ; rjust 21 true 
fi

# ***** Reformat VIRIDIC ***** #
# if not use reciprocal blast, viridic must be sum of both comparison
if [[ ! ${nb_missing_comp} -eq 0 ]]; then
  echo -ne "| ${colortitle}Format VIRIDIC:${NC}"
  if [ "$(type -t title)" = "function" ]; then title "viridic | reformat" ; fi
  SPINNY_FRAMES=( " reformat                                            |" " reformat .                                          |" " reformat ..                                         |" " reformat ...                                        |" " reformat ....                                       |" " reformat .....                                      |")
  spinny::start
  for viridic_out in ${dir_tmp}/viridic/*; do
    path_final_viridic=${path_dir_out}/viridic/$(basename ${viridic_out})
    if [[ ! -f "${path_final_viridic}" ]]; then echo -e "\"qseqid\"\t\"sseqid\"\t\"qlen\"\t\"slen\"\t\"q_nident\"\t\"q_aligned\"\t\"s_nident\"\t\"qs_nident\"\t\"qs_len\"\t\"interg_sim\"\t\"fract_qslen\"\t\"q_fract_aligned\"\t\"s_fract_aligned\"" > ${path_final_viridic} ; fi
    tail -n +2 ${viridic_out} | awk '{OFS="\t"; {t=$10; $10=t*2} print}' >> ${path_final_viridic}
    sleep 1
  done
  spinny::stop
  echo -ne " done" ; rjust 21 true
fi

# ***** UPDATE missing in history ***** #
if [[ ! ${nb_missing_comp} -eq 0 ]]; then
  echo -ne "| ${colortitle}Update history:${NC}"
  if [ "$(type -t title)" = "function" ]; then title "viridic | update" ; fi
  SPINNY_FRAMES=( " updating                                            |" " updating .                                          |" " updating ..                                         |" " updating ...                                        |" " updating ....                                       |" " updating .....                                      |")
  spinny::start
  cat ${dir_tmp}/results_missing.txt >> ${path_dir_out}/history.txt
  sort -u ${path_dir_out}/history.txt > ${dir_tmp}/sort_history.txt
  mv ${dir_tmp}/sort_history.txt ${path_dir_out}/history.txt
  spinny::stop
  echo -ne " done" ; rjust 21 true
fi

# ***** Create distance matrix ***** #
echo -ne "| ${colortitle}Create matrix :${NC}"
if [ "$(type -t title)" = "function" ]; then title "viridic | matrix" ; fi
SPINNY_FRAMES=( " computing                                           |" " computing .                                         |" " computing ..                                        |" " computing ...                                       |" " computing ....                                      |" " computing .....                                     |")
spinny::start
for file in ${path_dir_out}/viridic/*.out; do
    phage_name=$(basename $file | sed s/".out"/""/)
    tail -n +2 ${file} | cut -f 1,2,10 | sed s/"\""/""/g >> ${dir_tmp}/all_viridic.out
    echo -e "${phage_name}\t${phage_name}\t100.0" >> ${dir_tmp}/all_viridic.out
done
python3 ${dir_tmp}/matrix.py 2>>${log}
if [ $? -ne 0 ]; then spinny::stop ; echo -ne " fail" ; rjust 21 true ; display_error "matrix.py error (check log)" false ; fi
spinny::stop
if [[ ! -f "${path_dir_out}/viridic_matrix.tsv" ]]; then echo -ne " fail" ; rjust 21 true ; display_error "Any viridic matrix created (check log)" false ; fi
echo -ne " done" ; rjust 21 true

# ***** Create distance matrix ***** #
echo -ne "| ${colortitle}Assignment    :${NC}"
if [ "$(type -t title)" = "function" ]; then title "viridic | assign" ; fi
SPINNY_FRAMES=( " taxonomic assignment                                |" " taxonomic assignment .                              |" " taxonomic assignment ..                             |" " taxonomic assignment ...                            |" " taxonomic assignment ....                           |" " taxonomic assignment .....                          |")
spinny::start
python3 ${dir_tmp}/assign.py 2>>${log}
if [ $? -ne 0 ]; then spinny::stop ; echo -ne " fail" ; rjust 21 true ; display_error "assign.py error (check log)" false ; fi
spinny::stop
nb_family=$(grep -cE "^family" ${path_dir_out}/viridic_per_rank.tsv)
nb_genus=$(grep -cE "^genus" ${path_dir_out}/viridic_per_rank.tsv)
nb_specie=$(grep -cE "^specie" ${path_dir_out}/viridic_per_rank.tsv)
summary_assign=" (families:${nb_family}, genus:${nb_genus}, specie:${nb_specie})"
echo -ne " done${summary_assign}" ; rjust $((21+${#summary_assign})) true

# End processing
echo -e "╰─────────────────────────────────────────────────────────────────────╯"
rm -f ${path_dir_out}/blastn/*.lock
# rm -rf ${dir_tmp}
if [ "$(type -t title)" = "function" ]; then title "viridic | done" ; fi
footer