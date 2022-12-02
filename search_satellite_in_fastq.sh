OUT=/tmp/search_PICMI_HMM_phages_fastq
rm -rf ${OUT}
mkdir -p ${OUT}
echo -e "Phage\tTotal reads\tTotal unmapped reads\tPhage Primase\tPhage AlpA\tPhage Integrase\tUnmapped Primase contig\tUnmapped AlpA contig\tUnmapped Integrase contig\tUnmapped Primase read\tUnmapped AlpA read\tUnmapped Integrase read" > ${OUT}/search_PICMI_HMM_phages_fastq.tsv
for R1 in /mnt/c/Users/dgoudenege/Data/myPhage/FASTQ/*_R1*
  do
  name=$(basename ${R1} | sed s/"_R1.fastq.gz"/""/ | sed s/"Vibrio_phage_"/""/)
  R2=$(echo ${R1} | sed s/"R1"/"R2"/)
  FNA=/mnt/c/Users/dgoudenege/Data/myPhage/FNA/Vibrio_phage_${name}.fna
  FAA=/mnt/c/Users/dgoudenege/Data/myPhage/FAA/Vibrio_phage_${name}.faa
  if [ -f ${FNA} ]
    then
    echo "${name}"
    
    echo "... bowtie mapping"
    bowtie2-build ${FNA} ${OUT}/ref > /dev/null 2>&1
    bowtie2 --threads 12 -x ${OUT}/ref -1 ${R1} -2 ${R2} -S ${OUT}/${name}.sam > /dev/null 2>&1
    echo "... extract unmapped"
    samtools view -@12 -f4 -b ${OUT}/${name}.sam > ${OUT}/${name}_unmapped.bam
    bamToFastq -i ${OUT}/${name}_unmapped.bam -fq ${OUT}/${name}_unmapped.fastq
    nb_reads=$(samtools view -@12 -c ${OUT}/${name}.sam)
    nb_unmapped_reads=$(samtools view -@12 -c ${OUT}/${name}_unmapped.bam)
    rm -f ${OUT}/${name}.sam ${OUT}/${name}_unmapped.bam ${OUT}/ref*
    
    echo "... spades unmapped"
    spades.py --isolate -s ${OUT}/${name}_unmapped.fastq --cov-cutoff off -k 21,33,55 -m 10 --threads 12 -o ${OUT}/${name}_spades > /dev/null 2>&1
    mv ${OUT}/${name}_spades/contigs.fasta ${OUT}/${name}_unmapped_contigs.fasta
    rm -rf ${OUT}/${name}_spades
    
    echo "... reads to proteins"
    seqtk seq -a ${OUT}/${name}_unmapped.fastq > ${OUT}/${name}_unmapped.fasta
    transeq -frame 6 -sequence ${OUT}/${name}_unmapped.fasta -outseq ${OUT}/${name}_unmapped_reads.faa -trim > /dev/null 2>&1
    rm -f ${OUT}/${name}_unmapped.fastq
    
    echo "... assembly proteins"
    prodigal -a ${OUT}/${name}_unmapped_contigs.faa -g 11 -i ${OUT}/${name}_unmapped_contigs.fasta -p meta > /dev/null 2>&1
    sed -i -E s/"\s#.+"/""/g ${OUT}/${name}_unmapped_contigs.faa
    rm -f 
    
    echo "... PICMI profiles in phage"
    hmmsearch --cpu 12 -E 0.001 --tblout ${OUT}/${name}_phage.tsv /mnt/g/db/PICMI/fis-hel-alpa-int.hmm ${FAA} > /dev/null 2>&1
    sed -i -e s/"DUF3987"/"primase"/g -e s/"DUF5906"/"primase"/g -e s/"Phage_AlpA"/"alpa"/g -e s/"Vibrio_4_HMM_Profile"/"alpa"/g -e s/"HTH_17"/"alpa"/g -e s/"Phage_integrase"/"integrase"/g -e s/"Vibrio_6_HMM_Profile"/"integrase"/g ${OUT}/${name}_phage.tsv
    nb_primase_phage=$(grep -v "#" ${OUT}/${name}_phage.tsv | sed -E s/"\s+"/"\t"/g | grep "primase" | cut -f 1 | sort -u | wc -l)
    nb_alpa_phage=$(grep -v "#" ${OUT}/${name}_phage.tsv | sed -E s/"\s+"/"\t"/g | grep "alpa" | cut -f 1 | sort -u | wc -l)
    nb_integrase_phage=$(grep -v "#" ${OUT}/${name}_phage.tsv | sed -E s/"\s+"/"\t"/g | grep "integrase" | cut -f 1 | sort -u | wc -l)
    
    echo "... PICMI profiles in unmapped contigs"
    hmmsearch --cpu 12 -E 0.001 --tblout ${OUT}/${name}_contigs.tsv /mnt/g/db/PICMI/fis-hel-alpa-int.hmm ${OUT}/${name}_unmapped_contigs.faa > /dev/null 2>&1
    sed -i -e s/"DUF3987"/"primase"/g -e s/"DUF5906"/"primase"/g -e s/"Phage_AlpA"/"alpa"/g -e s/"Vibrio_4_HMM_Profile"/"alpa"/g -e s/"HTH_17"/"alpa"/g -e s/"Phage_integrase"/"integrase"/g -e s/"Vibrio_6_HMM_Profile"/"integrase"/g ${OUT}/${name}_contigs.tsv
    nb_primase_ctg=$(grep -v "#" ${OUT}/${name}_contigs.tsv | sed -E s/"\s+"/"\t"/g | grep "primase" | cut -f 1 | sort -u | wc -l)
    nb_alpa_ctg=$(grep -v "#" ${OUT}/${name}_contigs.tsv | sed -E s/"\s+"/"\t"/g | grep "alpa" | cut -f 1 | sort -u | wc -l)
    nb_integrase_ctg=$(grep -v "#" ${OUT}/${name}_contigs.tsv | sed -E s/"\s+"/"\t"/g | grep "integrase" | cut -f 1 | sort -u | wc -l)
    
    echo "... PICMI profiles in unmapped read"
    hmmsearch --cpu 12 -E 0.001 --tblout ${OUT}/${name}_reads.tsv /mnt/g/db/PICMI/fis-hel-alpa-int.hmm ${OUT}/${name}_unmapped_reads.faa > /dev/null 2>&1
    sed -i -e s/"DUF3987"/"primase"/g -e s/"DUF5906"/"primase"/g -e s/"Phage_AlpA"/"alpa"/g -e s/"Vibrio_4_HMM_Profile"/"alpa"/g -e s/"HTH_17"/"alpa"/g -e s/"Phage_integrase"/"integrase"/g -e s/"Vibrio_6_HMM_Profile"/"integrase"/g ${OUT}/${name}_reads.tsv
    nb_primase_reads=$(grep -v "#" ${OUT}/${name}_reads.tsv | sed -E s/"\s+"/"\t"/g | grep "primase" | cut -f 1 | sort -u | wc -l)
    nb_alpa_reads=$(grep -v "#" ${OUT}/${name}_reads.tsv | sed -E s/"\s+"/"\t"/g | grep "alpa" | cut -f 1 | sort -u | wc -l)
    nb_integrase_reads=$(grep -v "#" ${OUT}/${name}_reads.tsv | sed -E s/"\s+"/"\t"/g | grep "integrase" | cut -f 1 | sort -u | wc -l)
    
    echo -e "${name}\t${nb_reads}\t${nb_unmapped_reads}\t${nb_primase_phage}\t${nb_alpa_phage}\t${nb_integrase_phage}\t${nb_primase_ctg}\t${nb_alpa_ctg}\t${nb_integrase_ctg}\t${nb_primase_reads}\t${nb_alpa_reads}\t${nb_integrase_reads}" >> ${OUT}/search_PICMI_HMM_phages_fastq.tsv
  fi
done