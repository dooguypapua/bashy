#!/bin/bash
source /mnt/c/Users/dgoudenege/Dev_prog/bashy/functions.sh
shopt -s expand_aliases
alias gemini='python /mnt/c/Users/dgoudenege/Dev_prog/gemini/gemini.py'


#************************************************************************************************************************
#************************************************************************************************************************
#************************************************************************************************************************


echo -e "contig_id\tcontig_length\tproviral_length\taai_expected_length\taai_completeness\taai_confidence\taai_error\taai_num_hits\taai_top_hit\taai_id\taai_af\thmm_completeness_lower\thmm_completeness_upper\thmm_num_hits\tkmer_freq"
for fna in /mnt/g/db/straboDB/GCA_020*/*.fna.gz; do
    cp $fna /tmp/
    gzip -d /tmp/$(basename $fna)
    checkv completeness -d /mnt/g/db/checkv-db-v1.0 /tmp/$(basename $fna | sed s/".gz"/""/) /tmp/checkV -t 12
    tail -n 1 /tmp/checkV/completeness.tsv >> /tmp/checkV.tsv





# padloc="/mnt/c/Users/dgoudenege/Tools/padloc/bin/padloc"
# for faa in /mnt/c/Users/dgoudenege/Desktop/PICMI_RNAseq/Vibrio_chagasii_34_P_115.faa; do
#     tmp_gff="/tmp/$(basename $faa | sed s/".faa"/".gff"/)"
#     cat $(echo $faa | sed s/".faa"/".gff"/) | sed -E s/"locus_tag = ([^;]+);"/"locus_tag=\1;ID=\1;"/g > ${tmp_gff}
#     tsp ${padloc} --cpu 12 --data /mnt/g/db/padloc-db/1.4.0 --faa ${faa} --gff ${tmp_gff} --outdir /tmp/ --force
# done


# rm -f /tmp/blast.out
# r
# for fastq in */*.fastq ; do
#     rm -f /tmp/nanoreads.fasta
#     sed -n '1~4s/^@/>/p;2~4p' $fastq > /tmp/nanoreads.fasta
#     blastn -query /tmp/temp.fasta -subject /tmp/nanoreads.fasta -outfmt "6 qseqid sseqid evalue bitscore qlen slen qstart qend sstart send qseq sseq" -evalue 1 -max_target_seqs 50000 -word_size 7 -reward 2 -penalty -3 -gapopen 5 -gapextend 2 >> /tmp/blast.out
#     sed -i s/"PCR"/"$(dirname $fastq)"/ /tmp/blast.out
# done

# for bam in /mnt/g/PICMI_RNASEQ/*P115.bam; do
#     sample=$(basename $bam | sed s/".bam"/""/)
#     # mkdir -p /tmp/stringtie_${sample}
#     # tsp /mnt/c/Users/dgoudenege/Tools/stringtie/stringtie -p 12 -eB -G /mnt/c/Users/dgoudenege/Desktop/PICMI_RNAseq/reference/P115.gff $bam -o /tmp/stringtie_${sample}/out.gtf
#     cp /tmp/stringtie_${sample}/t_data.ctab /tmp/stringtie_${sample}.ctab
# done


# trimmomatic=/mnt/c/Users/dgoudenege/Tools/Trimmomatic-0.39/trimmomatic-0.39.jar
# for r1_path in /mnt/c/Users/dgoudenege/Downloads/Pasteur_archives/Plaque*/*_R1_001.fastq.gz; do
#     plaque=$(basename $(dirname $r1_path))
#     sample=$(basename $r1_path | sed s/"_L001_R1_001.fastq.gz"/""/)
#     sample_name="${plaque}_${sample}"
#     echo ${sample_name}
#     r2_path=$(echo $r1_path | sed s/"_R1_"/"_R2_"/)
#     path_out="/mnt/c/Users/dgoudenege/Downloads/Pasteur_archives/${sample_name}_spades.fna"
#     path_out_meta="/mnt/c/Users/dgoudenege/Downloads/Pasteur_archives/${sample_name}_metaspades.fna"
#     java -jar ${trimmomatic} PE ${r1_path} ${r2_path} /tmp/r1trim.fastq.gz /tmp/r1untrim.fastq.gz /tmp/r2trim.fastq.gz /tmp/r2untrim.fastq.gz LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 > /dev/null 2>&1
#     if [[ -f /tmp/r1untrim.fastq.gz ]]; then
#         cat /tmp/r1untrim.fastq.gz /tmp/r2untrim.fastq.gz > /tmp/untrim.fastq.gz
#         spades.py --isolate -1 /tmp/r1trim.fastq.gz -2 /tmp/r2trim.fastq.gz -s /tmp/untrim.fastq.gz --cov-cutoff off -k 21,33,55,77 -m 10 --threads 12 -o /tmp/spades > /dev/null 2>&1
#         if [[ -f /tmp/spades/contigs.fasta ]]; then
#             mv /tmp/spades/contigs.fasta ${path_out}
#             rm -rf /tmp/spades
#         else
#             spades.py --meta -1 /tmp/r1trim.fastq.gz -2 /tmp/r2trim.fastq.gz -s /tmp/untrim.fastq.gz --cov-cutoff off -k 21,33,55,77 -m 10 --threads 12 -o /tmp/spades > /dev/null 2>&1
#             mv /tmp/spades/contigs.fasta ${path_out_meta}
#             rm -rf /tmp/spades
#         fi
#     fi
#     rm -f /tmp/r1untrim.fastq.gz /tmp/r2untrim.fastq.gz /tmp/untrim.fastq.gz
# done



# echo -e "plaque\tsample\tspades_mode\tnb_read1\tnb_read2\tL10\tL20\tL30\tL40\tL50\tN10\tN20\tN30\tN40\tN50\tgc_content\tlongest\tmean\tmedian\tsequence_count\tshortest\ttotal_bps"
# for r1_path in /mnt/c/Users/dgoudenege/Downloads/Pasteur_archives/Plaque*/*_R1_001.fastq.gz; do
#     plaque=$(basename $(dirname $r1_path))
#     sample=$(basename $r1_path | sed s/"_L001_R1_001.fastq.gz"/""/)
#     sample_name="${plaque}_${sample}"
#     r2_path=$(echo $r1_path | sed s/"_R1_"/"_R2_"/)
#     path_out="/mnt/c/Users/dgoudenege/Downloads/Pasteur_archives/${sample_name}_spades.fna"
#     path_out_meta="/mnt/c/Users/dgoudenege/Downloads/Pasteur_archives/${sample_name}_metaspades.fna"
#     if [[ -f ${path_out_meta} ]]; then
#         mode="meta"
#         path_out=${path_out_meta}
#     else
#         mode="isolate"
#     fi
#     # Count reads
#     nb_read1=$(zgrep -c "^+$" ${r1_path})
#     nb_read2=$(zgrep -c "^+$" ${r2_path})
#     # Assembly stats
#     if [[ -f ${path_out} ]]; then
#         echo ${path_out}
#         rm -f /tmp/temp.json
#         assembly_stats ${path_out} > /tmp/temp.json 2>/dev/null || rm -f /tmp/temp.json
#         if [[ -f /tmp/temp.json ]]; then
#             L10=$(grep -m 1 "L10" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             L20=$(grep -m 1 "L20" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             L30=$(grep -m 1 "L30" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             L40=$(grep -m 1 "L40" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             L50=$(grep -m 1 "L50" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             N10=$(grep -m 1 "N10" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             N20=$(grep -m 1 "N20" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             N30=$(grep -m 1 "N30" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             N40=$(grep -m 1 "N40" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             N50=$(grep -m 1 "N50" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             gc_content=$(grep -m 1 "gc_content" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             longest=$(grep -m 1 "longest" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             mean=$(grep -m 1 "mean" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             median=$(grep -m 1 "median" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             sequence_count=$(grep -m 1 "sequence_count" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             shortest=$(grep -m 1 "shortest" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             total_bps=$(grep -m 1 "total_bps" /tmp/temp.json | sed -E s/".+: "/""/ | sed s/","/""/)
#             # Display
#             echo -e "${plaque}\t${sample}\t${mode}\t${nb_read1}\t${nb_read2}\t${L10}\t${L20}\t${L30}\t${L40}\t${L50}\t${N10}\t${N20}\t${N30}\t${N40}\t${N50}\t${gc_content}\t${longest}\t${mean}\t${median}\t${sequence_count}\t${shortest}\t${total_bps}"
#         else
#          echo -e "${plaque}\t${sample}\t${mode}\t${nb_read1}\t${nb_read2}\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA"
#         fi
#     else echo -e "${plaque}\t${sample}\t${mode}\t${nb_read1}\t${nb_read2}\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA"
#     fi
# done








# for fna in /mnt/c/Users/dgoudenege/Downloads/Pasteur_archives/*.fna ; \
#     do name=$(basename $fna | sed s/"_spades.fna"/""/) ; \
#     echo -ne "${name}:" >> /mnt/c/Users/dgoudenege/Downloads/Pasteur_archives/assembly_stats.json ; \
#     assembly_stats PlaqueC_S88_spades.fna | head -n -1  >> /mnt/c/Users/dgoudenege/Downloads/Pasteur_archives/assembly_stats.json ; \
#     echo -ne "},\n" >> /mnt/c/Users/dgoudenege/Downloads/Pasteur_archives/assembly_stats.json ; \
# done




# # ***** WITHOUT SPLIT ***** #
# reset ; title "satellite_finder"
# satellite_finder=/mnt/c/Users/dgoudenege/Tools/satellite_finder_0.9.1/bin/satellite_finder.py
# REFORMATDIR="/mnt/c/Users/dgoudenege/Works/Vibrio_FAA_reformat_contig"
# OUT="/mnt/c/Users/dgoudenege/Works/vibrioDB_satellite_finder_contig"
# LOG="${OUT}/output.log"
# mkdir -p ${OUT}
# cpt_done=0
# cpt_total=19189
# find /mnt/g/db/vibrioDB/GC*_000153785* -type f -name '*_genomic.gbff.gz' | while read GBK
# do
#   ((cpt_done++))
#   acc_name=$(basename ${GBK} | sed s/"_genomic.gbff.gz"/""/)
#   path_protein=$(echo ${GBK} | sed s/"_genomic.gbff.gz"/"_protein.faa.gz"/)
#   path_reformat_protein="${REFORMATDIR}/${acc_name}.faa"
#   pathOUTPICMI=${OUT}/${acc_name}_PICMI.tsv
#   echo "${cpt_done}/${cpt_total} ${acc_name}"
#   echo ${pathOUTPICMI}
#   # if [ ! -f ${pathOUTPICMI} ]; then
#   #   # if [ ! -f ${path_reformat_protein} ]; then
#   #   #   echo "  --reformat protein fasta"
#   #   #   # To avoid bad protein order if using *protein.faa.gz
#   #   #   python /mnt/c/Users/dgoudenege/Dev_prog/gemini/gemini.py gbk_to_faa -i ${GBK} -o ${path_reformat_protein} > /dev/null 2>&1
#   #   # fi
#   #   # echo "  --satellite_finder PICMI"
#   #   # if [ ! -s ${path_reformat_protein} ]; then
#   #   #     gzip -d -c ${path_protein} > /tmp/temp.faa
#   #   #     path_reformat_protein="/tmp/temp.faa"
#   #   # fi
#   #   # python ${satellite_finder} --models PICMI --db-type ordered_replicon --worker 10 --idx --sequence-db ${path_reformat_protein} --out-dir /tmp/satellite_finder >> ${LOG} 2>&1
#   #   # if [ ! -f /tmp/satellite_finder/all_best_solutions.tsv ]; then
#   #   #     python ${satellite_finder} --models PICMI --db-type ordered_replicon --worker 10 --idx --sequence-db ${path_protein} --out-dir /tmp/satellite_finder >> ${LOG} 2>&1
#   #   # fi
#   #   # if [ ! -f /tmp/satellite_finder/all_best_solutions.tsv ]; then
#   #   #     echo -e "# macsyfinder 2.0\n# models : SatelliteFinder-0.9\n# /mnt/c/Users/dgoudenege/Tools/satellite_finder_0.9.1/bin/satellite_finder.py --models PICMI --db-type ordered_replicon --worker 10 --idx --sequence-db ${path_reformat_protein} --out-dir /tmp/satellite_finder\n# Bad input fasta\n" > ${pathOUTPICMI}
#   #   # else
#   #   #     cp /tmp/satellite_finder/all_best_solutions.tsv ${pathOUTPICMI}
#   #   # fi
#   #   # rm -rf /tmp/satellite_finder ${path_reformat_protein}.idx
#   # fi
# done


# # cpt_done=0
# # find /mnt/g/db/vibrioDB/GC* -type f -name '*_genomic.gbff.gz' | while read GBK
# # do
# #     ((cpt_done++))
# #     acc_name=$(basename ${GBK} | sed s/"_genomic.gbff.gz"/""/)
# #     path_protein=$(echo ${GBK} | sed s/"_genomic.gbff.gz"/"_protein.faa.gz"/)
# #     path_reformat_protein="${REFORMATDIR}/${acc_name}.faa"
# #     pathOUTPICMI=${OUT}/${acc_name}_PICMI.tsv
# #     echo "${cpt_done}/${cpt_total} ${acc_name}"
# #     # Check if PICMI system found
# #     if grep -q "# Systems found:" "$pathOUTPICMI"; then
# #         for model in "cfPICI" "PICI" "P4" "PLE"; do
# #             pathOUTMODEL=${OUT}/${acc_name}_${model}.tsv
# #             if [ ! -f ${pathOUTMODEL} ]; then
# #                 echo "  --satellite_finder ${model}"
# #                 if [ ! -s ${path_reformat_protein} ]; then
# #                     gzip -d -c ${path_protein} > /tmp/temp.faa
# #                     path_reformat_protein="/tmp/temp.faa"
# #                 fi
# #                 python ${satellite_finder} --models ${model} --db-type ordered_replicon --worker 10 --idx --sequence-db ${path_reformat_protein} --out-dir /tmp/satellite_finder >> ${LOG} 2>&1
# #                 if [ ! -f /tmp/satellite_finder/all_best_solutions.tsv ]; then
# #                     python ${satellite_finder} --models ${model} --db-type ordered_replicon --worker 10 --idx --sequence-db ${path_protein} --out-dir /tmp/satellite_finder >> ${LOG} 2>&1
# #                 fi
# #                 if [ ! -f /tmp/satellite_finder/all_best_solutions.tsv ]; then
# #                     echo -e "# macsyfinder 2.0\n# models : SatelliteFinder-0.9\n# /mnt/c/Users/dgoudenege/Tools/satellite_finder_0.9.1/bin/satellite_finder.py --models ${model} --db-type ordered_replicon --worker 10 --idx --sequence-db ${path_reformat_protein} --out-dir /tmp/satellite_finder\n# Bad input fasta\n" > ${pathOUTPICMI}
# #                 else
# #                     cp /tmp/satellite_finder/all_best_solutions.tsv ${pathOUTMODEL}
# #                 fi
# #                 rm -rf /tmp/satellite_finder ${path_reformat_protein}.idx
# #             fi
# #         done
# #     fi
# # done