use strict 'vars';
use File::Basename;
use IO::File;
if(scalar(@ARGV)<1){
	print STDERR "perlfilter.pl INPUT OUTPUT\n";
	exit(1);
}
my $artifacts=handle_reverse_complement(prepare_artifact());
my $reader=IO::File->new($ARGV[0]);
my $writer=defined($ARGV[1])?IO::File->new(">".$ARGV[1]):undef;
my $total=0;
my $pass=0;
my $counts={};
while(!eof($reader)){
	my $id=<$reader>;chomp($id);
	my $seq=<$reader>;chomp($seq);
	my $id2=<$reader>;chomp($id2);
	my $qual=<$reader>;chomp($qual);
	my $hit=0;
	$total++;
	foreach my $line(@{$artifacts}){
		my ($id,$fwd,$rev)=@{$line};
		if($seq=~/$fwd/){$counts->{$id}++;$hit=1;last;}
		if($seq=~/$rev/){$counts->{$id}++;$hit=1;last;}
	}
	if($hit==0&&defined($writer)){$pass++;print $writer "$id\n$seq\n$id2\n$qual\n";}
}
print "Pass\t$pass\t".sprintf("%.2f",(100*$pass/$total))."%\n";
foreach my $id(keys(%{$counts})){
	my $value=$counts->{$id};
	print "$id\t$value\t".sprintf("%.2f",(100*$value/$total))."%\n";
}
print "Total\t$total\n";
close($reader);
if(defined($writer)){close($writer);}
############################## prepare_artifact ##############################
sub prepare_artifact{
	my @array=(
	["Illumina_Nextera_Read1_Read2_Adapter_Trimming","CTGTCTCTTATACACATCT"],
	["Illumina_TruSight_RNA_Pan-Cancer_Panel_Index_Adapters1","GATCGGAAGAGCACACGTCTGAACTCCAGTCAC"],
	["Illumina_TruSight_RNA_Pan-Cancer_Panel_Index_Adapter2","TCGTATGCCGTCTTCT"],
	["M1ss_primer_anneals_on_the_switch_adapter","AAGCAGTGGTATCAACGCA"],
	["Illumina_Paired_End_PCR_Primer1","GATCGGAAGAGCGGTTCAGCAGGAATGCCGAGA"],
	["Illumina_Paired_End_PCR_Primer2","AAGAGCGGTTCAGCAGGAAT"],
	["Chromium_Single_Cell_3_Reagent_Kits_v3","CCCATGTACTCTGCGTTGATACCACTGCTT"],
	["Drop-seq_Single_Primer_cDNA_Amplification","ACTCTGCGTTGATACCACTGCTT"],
	["TriLink_BioTechnol-ogies_Unmodified_3_Adapter","TGGAATTCTCGGGTGCCAAGG"],
	["Quartz-seq_Tagging_Primer","TATAGAATTCGCGGCCGCTCGCGA"]
	);
	return \@array;
}
############################## handle_reverse_complement ##############################
sub handle_reverse_complement{
	my $array=shift();
	my @temp=();
	foreach my $line(@{$array}){
		my ($id,$sequence)=@{$line};
		my $reverse=$sequence;
		$reverse=~tr/ATGCatgc/TACGtacg/;
		$reverse=reverse($reverse);
		push(@temp,[$id,$sequence, $reverse]);
	}
	return \@temp;
}
