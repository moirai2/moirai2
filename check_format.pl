#!/usr/bin/perl
use strict 'vars';
use FileHandle;
my $check="true";
while(!eof(STDIN)){if(!check(STDIN)){$check="false";last;}}
print "$check\n";
############################## check ##############################
sub check{
  my $reader=shift();
  chomp;
  my $id_line=<$reader>;
  chomp($id_line);
  if($id_line!~/^@/){return 0;}
  my $seq_line=<$reader>;
  chomp($seq_line);
  if(length($seq_line)==0){return 0;}
  my $id2_line=<$reader>;
  chomp($id2_line);
  if($id2_line!~/^\+/){return 0;}
  my $qual_line=<$reader>;
  chomp($qual_line);
  if(length($qual_line)==0){return 0;}
  return 1;
}
