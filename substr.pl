my $file=$ARGV[0];
my $start=$ARGV[1];
my $end=$ARGV[2];
if(!defined($end)){$end=-1;}
if($file=~/.gz(ip)?$/){open($reader,"gzip -cd $file|");}
elsif($file=~/.bz(ip)?2$/){open($reader,"bzip2 -cd $file|");}
else{open($reader,$file);}
while(!eof($reader)){
my $id=<$reader>;
chomp($id);
my $seq=<$reader>;
chomp($seq);
my $id2=<$reader>;
chomp($id2);
my $qual=<$reader>;
chomp($qual);
$seq=substr($seq,$start,$end);
$qual=substr($qual,$start,$end);
print "$id\n$seq\n$id2\n$qual\n";
}
close($reader);
