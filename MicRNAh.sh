#!/bin/bash

#
#  Copyright 2017, Bruno Cavadas <bcavadas@ipatimup.pt>
# 
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
# 
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
# 
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
#  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
#  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
#  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#  SUCH DAMAGE.
#

# ***************************** Software PATH *************************************
# Please Modify according to your location - By default it uses the Software folder
# on the default location of this file. Please change the MY_PATH.

MY_PATH="${PWD}"

SAMTOOLS=${MY_PATH}/Software/samtools-1.3.1/samtools
PAIR_END_SYNC=${MY_PATH}/Software/PairEndSync/pairsync
PIGZ=${MY_PATH}/Software/pigz-2.3.4/pigz
TRIMMOMATIC=${MY_PATH}/Software/Trimmomatic-0.36/
BOWTIE2=${MY_PATH}/Software/bowtie2-2.2.7/
RSEM=${MY_PATH}/Software/RSEM-1.2.29/
R_ABUNDANCE=${MY_PATH}/Software/calculateRelativeAbundance
BLASTN=${MY_PATH}/blastn

# *********************************************************************************

# Print options
function help_options {
    echo "MicRNAh: pipeline for microbiome characterization from human-centered RNA-seq datasets"
    echo "Usage: $0 -i <input bam file> -r <Reference_filename> -b <blast_db> -s <set_id> -p <threads> -o <output>"
    echo "Options:"
    echo "         -i, --input=<Input_bam>                 Input bam file"
    echo "         -r, --reference=<Reference_filename>    Reference filename"
    echo "         -b, --blast=<blast_db>                  Blast database folder. Default: BlastDb"
    echo "         -s, --setid=<set_id>                    File with bacterial name and corresponding ids"
    echo "         -o, --output=<Output_Name>              Output name"
    echo "         -p, --threads=NUM                       Number of threads. Default: 1"
}

# Parse input options and their arguments
# Default variables.
BAMFILE=""
OUTPUT=""
REFERENCE=""
SET_ID=""
BLAST_DB="${MY_PATH}/BlastDB/"
THREADS=1

while true; do
    case "$1" in
	-i|--input)
	    case "$2" in
		"") BAMFILE="" ; shift 2 ;;
		*)  BAMFILE="$2" ; shift 2 ;;
	    esac ;;
	
	-r|--reference)
	    case "$2" in
		"") REFERENCE="" ; shift 2 ;;
		*)  REFERENCE="$2" ; shift 2 ;;
	    esac ;;

	-s|--setid)
	    case "$2" in
		"") SET_ID="" ; shift 2 ;;
		*)  SET_ID="$2" ; shift 2 ;;
	    esac ;;

	-b|--blast)
	    case "$2" in
		"") BLAST_DB="${MY_PATH}/BlastDB/" ; shift 2 ;;
		*)  BLAST_DB="$2" ; shift 2 ;;
	    esac ;;
	
	-o|--output)
	    case "$2" in
		"") OUTPUT="" ; shift 2 ;;
		*)  OUTPUT="$2" ; shift 2 ;;
	    esac ;;
	
	-p|--threads)
	    case "$2" in
		"") THREADS=1 ; shift 2 ;;
		*)  THREADS="$2" ; shift 2 ;;
	    esac ;;
	
	-h|--help)
	    help_options ; exit 1 ;;

	--) shift ; break ;;

	-*) help_options ;
	    echo "Error: Unknown input argument $1";
	    exit 1 ;;

	*) break ;;
    esac
done

# *********************************************************************************
# Sanitize input variables

if [ -z $BAMFILE ] || [ $BAMFILE != *.bam ] || [ ! -f ${PWD}/$BAMFILE ] ; then
    echo "ERROR: You need to specify a valid input file in bam format"
    exit 1;
fi

if [ -z $REFERENCE ] || [ ! -f ${REFERENCE}.ti ] ; then
    echo "ERROR: You need to specify a valid reference"
    exit 1;
fi

if [ -z $BLAST_DB ] || [ ! -d $BLAST_DB ] || [ -z `find $BLAST_DB | grep nt.[0-9] | cut -f 1-2 -d "." | sort -u | tr "\n" " "`  ] ; then
    echo "ERROR: You need to a valid BLAST_DB or the folder specified is empty"
    exit 1;
fi

if [ -z $SET_ID ] || [ ! -f $SET_ID ] ; then
    echo "ERROR: You need to specify a valid setId"
    exit 1;
fi

case $THREADS in
    ''|*[!0-9]*) echo "Warning: Invalid threads number. Using Default"
		 THREADS=1 ;;
    *) ;;
esac

if [ "$THREADS" -gt `grep -c ^processor /proc/cpuinfo` ]; then
    echo "Warning: Number of threads greater than available. Using Default"
    THREADS=1
fi

if [ -z $OUTPUT ] ; then
    echo "ERROR: You need to specify output filename"
    exit 1
fi

# *********************************************************************************

echo "MicRNAh: pipeline for microbiome characterization from human-centered RNA-seq datasets"
echo "Input=$BAMFILE"
echo "Reference=$REFERENCE"
echo "Blast_DB=$BLAST_DB"
echo "Ouput=$OUTPUT"
echo "Threads=$THREADS"

mkdir -p $OUTPUT
cd $OUTPUT

echo "Extracting unmapped reads from bam.."
#extract unmapped reads from bam file
$SAMTOOLS fastq -f 4 ${PWD}/$BAMFILE -1 ${OUTPUT}_1.fastq -2 ${OUTPUT}_2.fastq

echo "Synchronize paired reads.."
#Synchronize paired reads
$PAIR_END_SYNC ${OUTPUT}_1.fastq ${OUTPUT}_2.fastq $OUTPUT

echo "Compressing reads.."
# compress reads. required for Trimmomatic
$PIGZ -p $THREADS ${OUTPUT}_sync_1.fastq ${OUTPUT}_sync_2.fastq

echo "Removing adapters and low quality bases.."
# Trimmomatic removes adapters and imposes an average minimum of two consecutive reads
# above 20. Reads below 40bp are removed
# WARNING: you migth need to change the adapters file
java -Xmx8g -jar ${TRIMMOMATIC}/trimmomatic-0.36.jar PE \
     ${OUTPUT}_sync_1.fastq.gz ${OUTPUT}_sync_2.fastq.gz \
     ${OUTPUT}_1_paired.fq.gz ${OUTPUT}_1_unpaired.fq.gz \
     ${OUTPUT}_2_paired.fq.gz ${OUTPUT}_2_unpaired.fq.gz \
     -threads $THREADS ILLUMINACLIP:${TRIMMOMATIC}/adapters/TruSeq2-PE.fa:2:30:10 \
     SLIDINGWINDOW:2:20 MINLEN:40

echo "Quantifying reads.."
#Rsem quantification
${RSEM}/rsem-calculate-expression -p $THREADS --paired-end \
     --bowtie2 --bowtie2-path $BOWTIE2 \
     --estimate-rspd \
     --append-names \
     <(zcat ${OUTPUT}_1_paired.fq.gz) <(zcat ${OUTPUT}_2_paired.fq.gz) \
     $REFERENCE \
     ${OUTPUT}

echo "Normalizing ..."
$R_ABUNDANCE ${OUTPUT}.rsem.results $SET_ID > ${OUTPUT}.rsem.results.normalized

echo "Extracting unmapped reads to database"
#Extract unmapped reads
$SAMTOOLS fasta -f 4 ${OUTPUT}.transcript.bam > ${OUTPUT}_databaseUnmapped.fa

echo "Running blast on unmapped reads"
#Run blast with percentage of identity above 97%
$BLASTN -query ${OUTPUT}_databaseUnmapped.fa \
	-db `find $BLAST_DB | grep nt.[0-9] | cut -f 1-2 -d "." | sort -u | tr "\n" " "` \
	-evalue 1e-20 -num_threads $THREADS -out ${OUTPUT}_blast.out -perc_identity 97 \
	-outfmt "6 qseqid sseqid pident qlen length mismatch gapope evalue bitscore sscinames scomnames" 

echo "All Done."
cd ..
