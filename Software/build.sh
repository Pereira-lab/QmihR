#!/bin/bash

tar xzvf RSEM_v1.2.29.tar.gz
cd RSEM-1.2.29/
make
cd ..

unzip Trimmomatic-0.36.zip

unzip bowtie2-2.2.7-linux-x86_64.zip

tar xzvf PairEndSync.tar.gz
cd PairEndSync
gcc -Wall -O2 PairSync.c -o pairsync -lz
cd ..

tar jxvf samtools-1.3.1.tar.bz2
cd samtools-1.3.1/
./configure
make
cd ..

tar xzvf pigz-2.3.4.tar.gz
cd pigz-2.3.4
make
cd ..

rm RSEM_v1.2.29.tar.gz Trimmomatic-0.36.zip bowtie2-2.2.7-linux-x86_64.zip samtools-1.3.1.tar.bz2 pigz-2.3.4.tar.gz PairEndSync.tar.gz
