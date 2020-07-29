#!/usr/bin/perl
use strict 'vars';
use Getopt::Std;
use FileHandle;
use File::Basename;
use File::Temp qw/tempfile tempdir/;
############################## OPTIONS ##############################
use vars qw($opt_l $opt_o $opt_w);
getopts('l:o:w:');
############################## initialize ##############################
if(scalar(@ARGV<2)){
  print STDERR "intron.pl GFF INPUT(s)\n";
  exit(1);
}
my @originals=@ARGV;
my $gff_file=shift(@originals);
my $window=defined($opt_w)?$opt_w:200;
my $outdir=defined($opt_o)?$opt_o:tempdir(CLEANUP=>1);
my $label=$opt_l;
my @temps=();
mkdir($outdir);
foreach my $file(@originals){
  if($file=~/\.bam/){
    my $basename=basename($file,"\.bam");
    my $bamfile="$outdir/$basename.bam";
    my $bedfile="$outdir/$basename.bed";
    my $command="samtools view -F 0x4 -q 10 -bo $bamfile $file";
    system($command);
    my $command2="bedtools bamtobed -i $bamfile > $bedfile";
    system($command2);
    unlink($bamfile);
    push(@temps,$bedfile);
  }else{
    push(@temps,$file);
  }
}
my @files=@temps;
############################## main ##############################
my $geneTable={};
my $basename=basename($gff_file,".gff");
mkdir("$outdir/$basename");
my $gffs=readGFF($gff_file);
my $regions=regionGFF($gffs->{"region"});
my $exonfile="$outdir/$basename/exon.gff";
my $genefile="$outdir/$basename/gene.gff";
writeGFF($gffs->{"exon"},$exonfile);
writeGFF($gffs->{"gene"},$genefile);
my $utr5file="$outdir/$basename/utr5.gff";
my $utr3file="$outdir/$basename/utr3.gff";
utrGFF($gffs->{"gene"},$regions,$window,$utr5file,$utr3file);
my $intronfile="$outdir/$basename/intron.gff";
intronGFF($gffs->{"exon"},$intronfile);
my $table={};
for(my $i=0;$i<scalar(@files);$i++){
  my $original=$originals[$i];
  my $file=$files[$i];
  intersectBed($original,$file,$table,$exonfile,$intronfile,$utr5file,$utr3file);
}
printHash($label,$table);
############################## printHash ##############################
sub printHash{
  my $label=shift();
  my $table=shift();
  foreach my $file(sort{$a cmp $b}keys(%{$table})){
    my $total=0;
    foreach my $type("utr5","exon","intron","utr3","intergenic"){
      my $count=$table->{$file}->{$type};
      print "$file\t$label$type\t$count\n";
      $total+=$count;
    }
    print "$file\t${label}total\t$total\n";
  }
}
############################## printTable ##############################
sub printTable{
  my $table=shift();
  print "\tUTR5\texon\tintron\tUTR3\tintergenic\ttotal\n";
  foreach my $file(sort{$a cmp $b}keys(%{$table})){
    my $line="$file";
    my $total=0;
    foreach my $type("utr5","exon","intron","utr3","intergenic"){
      my $count=$table->{$file}->{$type};
      $total+=$count;
      $line.="\t$count";
    }
    print "$line\t$total\n";
  }
}
############################## intronGFF ##############################
sub intronGFF{
  my $array=shift();
  my $intronfile=shift();
  my $exons={};
  $exons->{"+"}={};
  $exons->{"-"}={};
  foreach my $token(@{$array}){
    chomp;s/\r//g;
    my ($seqname,$source,$feature,$start,$end,$score,$strand,$frame,@attributes)=@{$token};
    my $hash={};
    foreach my $attribute(@attributes){
      foreach my $token(split(/\;/,$attribute)){
        my ($key,$val)=split(/\=/,$token);
        $hash->{$key}=$val;
      }
    }
    my $parent=$hash->{"Parent"};
    push(@{$exons->{$strand}->{$parent}},$token);
  }
  my $writer=IO::File->new(">$intronfile");
  foreach my $strand(keys(%{$exons})){
    foreach my $parent(keys(%{$exons->{$strand}})){
      my @tokens=sort{$a->[3]<=>$b->[3]}@{$exons->{$strand}->{$parent}};
      my $token=shift(@tokens);
      my $last=$token->[4];
      foreach my $token(@tokens){
        my ($seqname,$source,$feature,$start,$end,$score,$strand,$frame,@attributes)=@{$token};
        print $writer "$seqname\t$source\tintron\t$last\t$start\t$score\t$strand\t$frame\t".join("\t",@attributes)."\n";
        $last=$end;
      }
    }
  }
  close($writer);
}
############################## regionGFF ##############################
sub regionGFF{
  my $array=shift();
  my $hash={};
  foreach my $token(@{$array}){
    chomp;s/\r//g;
    my ($seqname,$source,$feature,$start,$end,$score,$strand,$frame,@attributes)=@{$token};
    $hash->{$seqname}=[$start,$end];
  }
  return $hash;
}
############################## utrGFF ##############################
sub utrGFF{
  my $array=shift();
  my $regions=shift();
  my $window=shift();
  my $utr5file=shift();
  my $utr3file=shift();
  my $writer5=IO::File->new(">$utr5file");
  my $writer3=IO::File->new(">$utr3file");
  foreach my $token(@{$array}){
    chomp;s/\r//g;
    my $hash={};
    my ($seqname,$source,$feature,$start,$end,$score,$strand,$frame,@attributes)=@{$token};
    my ($min,$max)=@{$regions->{$seqname}};
    my $left1=$start-1-$window;
    my $left2=$start-1;
    if($left1<$min){$left1=$min;}
    if($left2<$min){$left2=$min;}
    my $right1=$end+1;
    my $right2=$end+1+$window;
    if($right1>$max){$right1=$max;}
    if($right2>$max){$right2=$max;}
    if($strand eq "+"){
      print $writer5 "$seqname\t$source\t5UTR\t$left1\t$left2\t$score\t$strand\t.\t".join("\t",@attributes)."\n";
      print $writer3 "$seqname\t$source\t3UTR\t$right1\t$right2\t$score\t$strand\t.\t".join("\t",@attributes)."\n";
    }else{
      print $writer5 "$seqname\t$source\t5UTR\t$right1\t$right2\t$score\t$strand\t.\t".join("\t",@attributes)."\n";
      print $writer3 "$seqname\t$source\t3UTR\t$left1\t$left2\t$score\t$strand\t.\t".join("\t",@attributes)."\n";
    }
  }
  close($writer5);
  close($writer3);
}
############################## readGFF ##############################
sub readGFF{
  my $file=shift();
  my $hash={};
  my $reader=IO::File->new($file);
  while(<$reader>){
    if(/^#/){next;}
    chomp;s/\r//g;
    my @tokens=split(/\t/);
    push(@{$hash->{$tokens[2]}},\@tokens);
  }
  close($reader);
  return $hash;
}
############################## writeGFF ##############################
sub writeGFF{
  my $array=shift();
  my $output=shift();
  my $writer=IO::File->new(">$output");
  foreach my $tokens(@{$array}){print $writer join("\t",@{$tokens})."\n";}
  close($writer);
}
############################## intersectBed ##############################
sub intersectBed{
  my @bedfiles=@_;
  my $original=shift(@bedfiles);
  my $file=shift(@bedfiles);
  my $table=shift(@bedfiles);
  my $basename=basename($file,"\.bed");
  my $index=0;
  foreach my $bedfile(@bedfiles){
    my $basename2=basename($bedfile,"\.gff");
    my $output="$outdir/$basename.$basename2.bed";
    my $command="intersectBed -u -wa -bed -a $file -b $bedfile > $output";
    system($command);
    my $count=`cat $output|wc -l`;
    chomp($count);
    if(!exists($table->{$original})){$table->{$original}={};}
    $table->{$original}->{$basename2}=$count;
    my $output2="$outdir/$basename.$basename2.v.bed";
    my $command3="intersectBed -v -wa -bed -a $file -b $bedfile > $output2";
    system($command3);
    if($index>0){unlink($file);}
    $file=$output2;
    $index++;
  }
  my $count=`cat $file|wc -l`;
  chomp($count);
  if(!exists($table->{$original})){$table->{$original}={};}
  $table->{$original}->{"intergenic"}=$count;
  rename($file,"$outdir/$basename.intergenic.bed");
}
