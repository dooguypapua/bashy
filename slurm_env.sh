# required modules
module load python/3.9
module load fastp/0.23.1
module load abyss/2.2.1
module load spades/3.15.2
module load blast/2.13.0
module load ragtag/1.0.2
module load seqkit/2.1.0
module load jq/1.6
module load mummer4/4.0.0rc1
module load bowtie2/2.5.0
module load pysam/0.16.0
# module load htseq/0.13.5
module load samtools/1.15.1
# required paths
path_tmp="/shared/projects/gv/dgoudenege/tmp"
export PYTHONPATH="${PYTHONPATH}:/home/umr8227/gv/dgoudenege/.local/lib/python3.9/site-packages/:/home/umr8227/gv/dgoudenege/.local/lib/python3.8/site-packages/:/usr/lib/python3/dist-packages" #:/shared/software/miniconda/envs/python-pytorch-tensorflow-3.9-1.11.0-2.6.2/lib/python3.9/site-packages"
FASTA2CAMSA=/home/umr8227/gv/dgoudenege/.local/lib/python3.9/site-packages/camsa/utils/fasta/fasta2camsa_points.py
RUN_CAMSA=/home/umr8227/gv/dgoudenege/.local/lib/python3.9/site-packages/camsa/run_camsa.py
CAMSA_POINTS2FASTA=/home/umr8227/gv/dgoudenege/.local/lib/python3.9/site-packages/camsa/utils/fasta/camsa_points2fasta.py
# Execution variables
threads=$(printenv SLURM_CPUS_ON_NODE)
memory=$(expr $SLURM_MEM_PER_NODE / 1024 - 10)
