MicRNAh: pipeline for microbiome characterization from human-centered RNA-seq datasets

README

I. Dependencies

MicRNAh make use of several software packages that require some packages to be installed. Please 
during installation of the software in the Software folder, pay attention to potential errors. In
the BlastDB, the perl script to update the blast library required perldoc to be installed. In
Ubuntu this can be achieved by executing the following command:

	> sudo apt-get install perl-doc

II. Compiling and Installing packages:

MicRNAh Software folder already provides a build.sh script that decompresses and installs
all packages. This installation can be performed using:

	> bash build.sh

To update the blast database for nucleotides execute:

	> ./update_blastdb.pl blastdb nt --decompress

Please also download the taxa and decompress using:

	> wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz
	> tar xzvf taxdb.tar.gz

III. Generate Reference database

To generate the reference database fasta and gff files should be downloaded preferably from
refseq or ncbi. In order for the program to identify a species with higher accuracy, a 
"representative" strain should be chosen for each species. The criteria of which is left to
the user. 

After download of the fasta and gff of all species, the fasta files and gff should be decompressed
and merged using:

	> cat *.fna > bacterial_reference.fna
	> cat *gff | grep -v "^#" > bacterial_reference.gff

WARNING: Although not required, plasmid should be removed from this database

To create the reference database with rsem the gff files can be converted to gtf using the gffread
present in the cufflinks suite (http://cole-trapnell-lab.github.io/cufflinks/)

	> gffread bacterial_reference.gff -T -o bacterial_reference.gtf

To generate the database please execute:

	> rsem-prepare-reference --gtf bacterial_reference.gtf \
				 bacterial_reference.fna bacterial_reference_ref \
				 --bowtie2 --bowtie2-path Software/bowtie2-2.2.7/

In this case bacterial_reference_ref is the name of the reference database and is the name that should
be passed to the reference flag in MicRNAh.

IV. Input files

MicRNAh: pipeline for microbiome characterization from human-centered RNA-seq datasets"
Usage: ./MicRNAh -i <input bam file> -r <Reference_filename> -b <blast_db> -s <set_id> -p <threads> -o <output>"
Options:
         -i, --input=<Input_bam>                 Input bam file
         -r, --reference=<Reference_filename>    Reference filename
         -b, --blast=<blast_db>                  Blast database folder. Default: BlastDb
         -s, --setid=<set_id>                    File with bacterial name and corresponding ids
         -o, --output=<Output_Name>              Output name
         -p, --threads=NUM                       Number of threads. Default: 1


V. Helper scripts

Since blast output can be rather extensive and can only align to a species in only one of the strands, in the Software
folder there is a script entitled blast_parser that parses the blast output and only outputs species present in both 
strands. This step can significantly decrease the blast file size. This script can be run using:

	> ./blast_parser <blast_output> 

VI. Example data for reproducing the results in the paper

An example of how to create the reference database is present in the Example folder. This folder contains the sequence
in fasta and gff of Helicobacter pylori and Clostridium citronae. Please read the script for explanation of the steps.

VI. Citing MicRNAh

Nothing yet. Hopefully this section will be updated
