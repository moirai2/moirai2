use strict 'vars';
use File::Basename;
my $input=$ARGV[0];
my $outdir=$ARGV[1];
my $basename=basename($input);
my $multimap="$outdir/$basename.multi.fa.gz";
my $filtered="$outdir/$basename.unmap.fa.gz";
open(IN,"samtools view $input |");
open(MULTI,"|gzip>$multimap");
open(FILTERED,"|gzip>$filtered");
while(<IN>){
if(/^@/){next;}
chomp;s/\r//g;
my ($qname,$flag,$rname,$pos,$mapq,$cigar,$rnext,$pnexxt,$tlen,$seq,$qual,@others)=split(/\t/);
if(($flag&256)>0){next;}
my $multi=0;
if(($flag&4)==0){$multi=1;}
foreach my $other(@others){if($other=~/uT:A:3/){$multi=1;}}
if($multi){print MULTI "\@$qname\n$seq\n+\n$qual\n";}
else{print FILTERED "\@$qname\n$seq\n+\n$qual\n";}
}
close(IN);
close(MULTI);
close(FILTERED);
