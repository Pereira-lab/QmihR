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

#decompress files
gzip -d *.gz

#Concatenate files (SIMPLE)
cat *.fna > test_db_simple.fna
cat *.gff | grep -v "$^" > test_db_simple.gff

#Concatenate files (Without plasmids)
../Software/samtools-1.3.1/samtools faidx test_db_simple.fna 
cat *.fna | grep ">" | grep -v "plasmid" | cut -f 1 -d " " | sed "s/>//g" > tmp.txt
while read line
do
    ../Software/samtools-1.3.1/samtools faidx test_db_simple.fna "$line"
done < tmp.txt > test_db.fna

grep -f tmp.txt test_db_simple.gff > test_db.gff
awk '{gsub(/Parent=/,"Parent="$1"_"); print }' test_db.gff > tmp.gff
awk '{gsub(/ID=/,"ID="$1"_"); print }' tmp.gff > test_db.gff

rm tmp.gff

#Generate set id file
cat test_db_simple.fna | grep ">" | grep -v "plasmid" | cut -f 2-3 -d " " | sort -u > IDS.txt

while read line; do
    printf "${line}\t"
    cat test_db_simple.fna | grep -w "$line" | cut -f 1 -d " " | sed "s/>//g" | tr -s "\n" "\t"
    echo ""
done < IDS.txt > test_set_id.txt

#Indexing database

./gffread test_db.gff -T -o test_db.gtf

../Software/RSEM-1.2.29/rsem-prepare-reference \
    --gtf test_db.gtf \
    test_db.fna test_db_ref \
    --bowtie2 --bowtie2-path ../Software/bowtie2-2.2.7/

#removing
rm *simple* IDS.txt tmp.txt
