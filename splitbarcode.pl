use strict 'vars';
use IO::File;
my @barcodes=@ARGV;
my $file=shift(@barcodes);
my $outdir=shift(@barcodes);
if(!defined($outdir)){$outdir="out";}
mkdir($outdir);
my $reader;
if($file=~/.gz(ip)?$/){open($reader,"gzip -cd $file|");}
elsif($file=~/.bz(ip)?2$/){open($reader,"bzip2 -cd $file|");}
else{open($reader,$file);}
my $writers={};
foreach my $barcode(@barcodes){$writers->{$barcode}=IO::File->new(">$outdir/$barcode.fq");}
my $nomatch=IO::File->new(">$outdir/nomatch.fq");
while(!eof($reader)){
	my $id=<$reader>;
	chomp($id);
	my $seq=<$reader>;
	chomp($seq);
	my $id2=<$reader>;
	chomp($id2);
	my $qual=<$reader>;
	chomp($qual);
	my $found=0;
	print STDERR "found=$found\n";
	foreach my $barcode(@barcodes){
		if($seq=~/^$barcode(.+)$/){
			print STDERR "barcode=$barcode\n";
			$seq=$1;
			$qual=substr($qual,length($barcode));
			my $writer=$writers->{$barcode};
			print $writer "$id\n$seq\n$id2\n$qual\n";
			$found=1;
			last;
		}
	}
	print STDERR "found=$found\n";
	if($found==0){print $nomatch "$id\n$seq\n$id2\n$qual\n";}
}
close($reader);
foreach my $barcode(@barcodes){close($writers->{$barcode});}
close($nomatch);
