my $file=$ARGV[0];
my $filter=$ARGV[1];
if($file=~/.gz(ip)?$/){open($reader,"gzip -cd $file|");}
elsif($file=~/.bz(ip)?2$/){open($reader,"bzip2 -cd $file|");}
else{open($reader,$file);}
while(!eof($reader)){
  my $id=<$reader>;
  my $seq=<$reader>;
  my $id2=<$reader>;
  my $qual=<$reader>;
  if($seq=~/$filter/){print "$id$seq$id2$qual";}
}
close($reader);
