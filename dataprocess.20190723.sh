if [ $# -gt 0 ] ; then
nodeid=`perl rdf.pl -d larvae.sqlite3 newnode`
perl rdf.pl -d larvae.sqlite3 insert $nodeid '#read1' $1
perl rdf.pl -d larvae.sqlite3 insert $nodeid '#read2' $2
perl rdf.pl -d larvae.sqlite3 insert $nodeid '#starindex' $3
perl rdf.pl -d larvae.sqlite3 insert root '#star' STAR
perl rdf.pl -d larvae.sqlite3 insert root '#samtools' samtools
#perl rdf.pl -d larvae.sqlite3 install STAR
#perl rdf.pl -d larvae.sqlite3 install samtools
fi

perl moirai2.pl \
-d larvae.sqlite3 \
-i '$id->#starindex->$starindex,$id->#read1->$input1,$id->#read2->$input2' \
-o '$id->#bam->$bam,$id->#log->$log' \
/Users/ah3q/Sites/moirai2.github.io/command/star/align_paired.json

perl moirai2.pl \
-d larvae.sqlite3 \
-i '$id->#read1->$fastq' \
-o '$fastq->#seqcount->$count' \
/Users/ah3q/Sites/moirai2.github.io/command/fastq/countseq.json

perl moirai2.pl \
-d larvae.sqlite3 \
-i '$id->#read2->$fastq' \
-o '$fastq->#seqcount->$count' \
/Users/ah3q/Sites/moirai2.github.io/command/fastq/countseq.json

perl moirai2.pl \
-d larvae.sqlite3 \
-i '$id->#bam->$bam' \
-o '$id->#html->$html' \
/Users/ah3q/Sites/moirai2.github.io/command/sam/samstats.json

perl moirai2.pl \
-d larvae.sqlite3 \
-i '$id->#bam->$input' \
-o '$id->#multicount->$multicount,$id->#unmap1->$unmap1,$id->#unmap2->$unmap2' \
/Users/ah3q/Sites/moirai2.github.io/command/star/remove_multimap_paired.json

perl moirai2.pl \
-d larvae.sqlite3 \
-i '$id->#bam->$input' \
-o '$id->#sorted->$output' \
/Users/ah3q/Sites/moirai2.github.io/command/samtools/sortbam.json

perl moirai2.pl \
-d larvae.sqlite3 \
-i '$id->#sorted->$input' \
-o '$id->#bed->$output' \
/Users/ah3q/Sites/moirai2.github.io/command/bedtools/bam2bed.json
