#!/usr/bin/perl
use IO::File;
use strict 'vars';
use File::Basename;
use Getopt::Std;
my $file=$ARGV[0];
my $target=$ARGV[1];
my $before=$ARGV[2];
my $after=$ARGV[3];
if(!defined($target)){$target="transcript";}
if(!defined($before)){$before=500;}
if(!defined($after)){$after=0;}
my $command="$file";
if($file=~/\.bz2$/){$command="bzip2 -cd $file|"}
if($file=~/\.gz$/){$command="gzip -cd $file|"}
open(IN,$command);
while(<IN>){
  if(/#/){next;}
  chomp;
  my ($seqname,$source,$feature,$start,$end,$score,$strand,$frame,$attribute)=split(/\t/);
  if($feature ne $target){next;}
  my $transcript_id;
  if($attribute=~/transcript_id \"(\S+)\"/){$transcript_id=$1;}
  if($strand eq "-"){
    my $s=$end-$after-1;
    if($s<0){next;}
    my $e=$end+$before;
    print "$seqname\t$s\t$e\t$transcript_id\t0\t$strand\n";
  }else{
    my $s=$start-$before-1;
    if($s<0){next;}
    my $e=$start+$after;
    print "$seqname\t$s\t$e\t$transcript_id\t0\t$strand\n";
  }
}
close(IN);
