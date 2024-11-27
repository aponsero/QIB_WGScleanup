#!/bin/bash -l
#SBATCH --job-name=Fastqc
#SBATCH --output=errout/outputr%j.txt
#SBATCH --error=errout/errors_%j.txt
#SBATCH --partition=
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=5
#SBATCH --mem-per-cpu=32GB

# load job configuration
cd $SLURM_SUBMIT_DIR
source config.sh

# echo for log
echo "job started"; hostname; date

cd $IN_DIR

if [[ ! -d "$OUT_DIR" ]]; then
	mkdir -p $OUT_DIR
	mkdir -p $OUT_DIR/3.qc_logs
fi


# Run hostile
if [[ $HOSTILE == "TRUE" ]]; then
	mkdir -p $OUT_DIR/1.hostclean-reads
	eval "$(~/.local/bin/micromamba shell hook -s posix)"
	micromamba activate hostile
        export HOSTILE_CACHE_DIR=/qib/platforms/Informatics/transfer/outgoing/databases/hostile/	
        echo " #### Starting hostile processing ####"
	
	for FOR in $IN_DIR/*_R1.fastq.gz
	do
  		BASENAME=$(basename $FOR | cut -f1 -d_)
  		REV=${FOR/_R1/_R2}
  		hostile clean --fastq1 $FOR --fastq2 $REV --out-dir $OUT_DIR/1.hostclean-reads --threads 16
	done
fi

# Run TrimGalore
if [[ $TRIM == "TRUE" ]]; then
	mkdir -p $OUT_DIR/2.trimmed-reads
        source package 04b61fb6-8090-486d-bc13-1529cd1fb791	
        echo " #### Starting trimgalore processing ####"
        for FOR in $OUT_DIR/1.hostclean-reads/*_1.fastq.gz
        do
                REV=${FOR/_R1.clean_1.fastq.gz/_R2.clean_2.fastq.gz}
                trim_galore --paired -o $OUT_DIR/2.trimmed-reads --fastqc $FOR $REV 
        done
	
	mv $OUT_DIR/2.trimmed-reads/*_fastqc.html $OUT_DIR/3.qc_logs
	mv $OUT_DIR/2.trimmed-reads/*_fastqc.zip $OUT_DIR/3.qc_logs
	mv $OUT_DIR/2.trimmed-reads/*_trimming_report.txt $OUT_DIR/3.qc_logs
fi



echo " #### Ending FastQC processing ####"
echo "####################################"

# Run multiQC
if [[ $MULTIQC == "TRUE" ]]; then
        source package a8a18f99-1c90-4175-8f58-330b0ad61cad 
	echo " #### Starting multiqc processing ####"        
	
	cd $OUT_DIR/3.qc_logs
	multiqc .
fi

