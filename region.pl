#!/usr/bin/perl
use strict 'vars';
use File::Basename;
use Getopt::Std;
my @gene_regions=();
my @exon_regions=();
my @cds_regions=();
my @utr_regions=();
my @transcript_regions=();
my @start_codon_regions=();
my @stop_codon_regions=();
my $gene_name;
while(<STDIN>){
	my ($seqname,$source,$feature,$start,$end,$score,$strand,$frame,$attribute)=split(/\t/);
	if($attribute=~/gene_name \"(\S+)\"/){if($gene_name ne $1){printResult();$gene_name=$1;}}
	my $region=[$start,$end];
	if($feature eq "gene"){@gene_regions=pushRegion(\@gene_regions,$region);}
	elsif($feature eq "exon"){@exon_regions=pushRegion(\@exon_regions,$region);}
	elsif($feature eq "CDS"){@cds_regions=pushRegion(\@cds_regions,$region);}
	elsif($feature eq "UTR"){@utr_regions=pushRegion(\@utr_regions,$region);}
	elsif($feature eq "transcript"){@transcript_regions=pushRegion(\@transcript_regions,$region);}
	elsif($feature eq "start_codon"){@start_codon_regions=pushRegion(\@start_codon_regions,$region);}
	elsif($feature eq "stop_codon"){@stop_codon_regions=pushRegion(\@stop_codon_regions,$region);}
}
printResult();
############################## printResult ##############################
sub printResult{
	if(!defined($gene_name)){return;}
	my @intron_regions=calculateIntron(\@exon_regions);
	printRegion($gene_name,"gene",\@gene_regions);
	printRegion($gene_name,"exon",\@exon_regions);
	printRegion($gene_name,"intron",\@intron_regions);
	printRegion($gene_name,"CDS",\@cds_regions);
	printRegion($gene_name,"UTR",\@utr_regions);
	printRegion($gene_name,"transcript",\@transcript_regions);
	printRegion($gene_name,"start_codon",\@start_codon_regions);
	printRegion($gene_name,"stop_codon",\@stop_codon_regions);
	@gene_regions=();
	@exon_regions=();
	@cds_regions=();
	@utr_regions=();
	@transcript_regions=();
	@start_codon_regions=();
	@stop_codon_regions=();
}
############################## calculateIntron ##############################
sub calculateIntron{
	my $exons=shift();
	my @introns=();
	my $prevend;
	foreach my $exon(@{$exons}){
		my ($start,$end)=@{$exon};
		if(defined($prevend)){push(@introns,[$prevend+1,$start-1]);}
		$prevend=$end;
	}
	return @introns;
}
############################## printRegion ##############################
sub printRegion{
	my $gene_name=shift();
	my $type=shift();
	my $array=shift();
	foreach my $line(@{$array}){
		my ($start,$end)=@{$line};
		print "$gene_name\t$type\t$start\t$end\n";
	}
}
############################## pushRegion ##############################
sub pushRegion{
	my $regions=shift();
	my ($start,$end)=@{shift()};
	if(scalar(@{$regions})==0){return ([$start,$end]);}
	my @array=();
	my $found=0;
	foreach my $line(@{$regions}){
		my ($start2,$end2)=@{$line};
		if($found==1){
			push(@array,[$start2,$end2]);
		}elsif($end<$start2-1){
			push(@array,[$start,$end]);
			push(@array,[$start2,$end2]);
			$found=1;
		}elsif($end2<$start-1){
			push(@array,[$start2,$end2]);
		}elsif($start<$start2){
			push(@array,[$start,$end2]);
			$found=1;
		}elsif($end2<$end){
			push(@array,[$start2,$end]);
			$found=1;
		}else{
			push(@array,[$start2,$end2]);
			$found=1;
		}
	}
	if($found==0){push(@array,[$start,$end]);}
	return @array;
}
