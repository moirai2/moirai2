#!/usr/bin/perl
use strict 'vars';
use File::Basename;
use Getopt::Std;

my $file=shift(@ARGV);
my $genes={};
foreach my $name(@ARGV){$genes->{$name}=1;}
if(scalar(keys(%{$genes}))==0){$genes=undef;}
if(!defined($file)){exit();}
my $name=basename($file,".gz");
my $reader;
if($file=~/\.gz(ip)?$/){open($reader,"gzip -cd $file|");}
elsif($file=~/\.bz(ip)?2$/){open($reader,"bzip2 -cd $file|");}
else{open($reader,$file);}
my $linecount=0;
while(<$reader>){
	if(/^#/){next;}
	chomp;
	my ($seqname,$source,$feature,$start,$end,$score,$strand,$frame,$attribute)=split(/\t/);
	my $hash={};
	foreach my $attribute(split(/;\s*/,$attribute)){
		chomp($attribute);
		if($attribute eq ""){next;}
		my ($key,$val)=split(/ /,$attribute,2);
		if($val=~/^\"(.+)\"$/){$val=$1;}
		elsif($val=~/^\'(.+)\'$/){$val=$1;}
		$hash->{$key}=$val;
	}
	my $gene_name=$hash->{"gene_name"};
	if(defined($genes)&&!exists($genes->{$gene_name})){next;}
	my $node="$name#$linecount";
	print "$node\tseqname\t$seqname\n";
	print "$node\tsource\t$source\n";
	print "$node\tfeature\t$feature\n";
	print "$node\tstart\t$start\n";
	print "$node\tend\t$end\n";
	print "$node\tscore\t$score\n";
	print "$node\tstrand\t$strand\n";
	print "$node\tframe\t$frame\n";
	foreach my $key(sort{$a cmp $b}keys(%{$hash})){my $val=$hash->{$key};print "$node\t$key\t$val\n";}
	$linecount++;
}
close($reader);
