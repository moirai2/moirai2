zcat ../gencodegtf/download/gencode.v30lift37.annotation.gtf.gz | grep "gene_name \"BRCA1\"" > data/gtf/BRCA1.gtf
zcat ../gencodegtf/download/gencode.v30lift37.annotation.gtf.gz | grep "gene_name \"BRCA2\"" > data/gtf/BRCA2.gtf
zcat ../gencodegtf/download/gencode.v30lift37.annotation.gtf.gz | grep "gene_name \"TP53\"" > data/gtf/TP53.gtf
zcat ../gencodegtf/download/gencode.v30lift37.annotation.gtf.gz | grep "gene_name \"PTEN\"" > data/gtf/PTEN.gtf
zcat ../gencodegtf/download/gencode.v30lift37.annotation.gtf.gz | grep "gene_name \"CDH1\"" > data/gtf/CDH1.gtf
zcat ../gencodegtf/download/gencode.v30lift37.annotation.gtf.gz | grep "gene_name \"STK11\"" > data/gtf/STK11.gtf
zcat ../gencodegtf/download/gencode.v30lift37.annotation.gtf.gz | grep "gene_name \"NF1\"" > data/gtf/NF1.gtf
zcat ../gencodegtf/download/gencode.v30lift37.annotation.gtf.gz | grep "gene_name \"PALB2\"" > data/gtf/PALB2.gtf
zcat ../gencodegtf/download/gencode.v30lift37.annotation.gtf.gz | grep "gene_name \"ATM\"" > data/gtf/ATM.gtf
zcat ../gencodegtf/download/gencode.v30lift37.annotation.gtf.gz | grep "gene_name \"CHEK2\"" > data/gtf/CHEK2.gtf
zcat ../gencodegtf/download/gencode.v30lift37.annotation.gtf.gz | grep "gene_name \"NBN\"" > data/gtf/NBN.gtf
mkdir -p data/bed
Basename.pl -f data/gtf "perl regions.pl [path] data/bed/[basename]" | bash
Basename.pl -f data/gtf "perl window.pl [path] > data/bed/[basename]/promotor500.bed" | bash
Basename.pl -f data/gtf "perl window.pl [path] transcript 1000 > data/bed/[basename]/promotor1000.bed" | bash
mkdir -p data/fasta
Basename.pl -Ff data/bed "mkdir -p data/fasta/[basename]" | bash
Basename.pl -f data/bed "bedtools getfasta -s -fi /analysisdata/genomes/hg19/hg19.fa -bed [path] > data/fasta/[dir2]/[basename].fa" | bash
source activate meme
mkdir -p data/fimo
Basename.pl -f data/fasta "mkdir -p data/fimo/[dir2]"|bash
Basename.pl -f data/fasta "fimo -o data/fimo/[dir2]/[basename] ../meme/motif_databases/JASPAR/JASPAR2018_CORE_vertebrates_non-redundant.meme [path]"
