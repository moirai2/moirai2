#!/usr/bin/perl
use Getopt::Std;
use vars qw($opt_b);
getopts('b:');
my $hash={};
my $totals={};
my $base=defined($opt_b)?$opt_b:33;
my $file=shift(@ARGV);
my $command="$file";
if($file=~/\.bz2$/){$command="bzip2 -cd $file|"}
if($file=~/\.gz$/){$command="gzip -cd $file|"}
open(IN,$command);
while(!eof(IN)){
<IN>;
<IN>;
<IN>;
my $quality=<IN>;
chomp($quality);
my @chars=split(//,$quality);
for(my $index=0;$index<scalar(@chars);$index++){
my $char=$chars[$index];
if(!exists($hash->{$index})){$hash->{$index}={};}
$hash->{$index}->{$char}++;
$totals->{$char}++;
}
}
my @chars=();
my $max_value=0;
foreach my $char(keys(%{$totals})){my $value=ord($char)-$base;if($value>$max_value){$max_value=$value;}}
for(my $value=0;$value<$max_value+1;$value++){my $char=chr($value+$base);push(@chars,$char);print "\t$value";}
print "\n";
foreach my $index(sort{$a<=>$b}keys(%{$hash})){
print $index+1;
for(my $i=0;$i<=$max_value;$i++){my $char=$chars[$i];my $count=exists($hash->{$index}->{$char})?$hash->{$index}->{$char}:0;print "\t$count";}
print "\n";
}
