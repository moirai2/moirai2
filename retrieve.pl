my $runindex=-1;
my $studyindex=-1;
my @indeces=();
my $hash={};
foreach my $argv(@ARGV){$hash->{$argv}=-1;}
my $line=<STDIN>;
chomp($line);
my @labels=splitline($line);
for(my $i=0;$i<scalar(@labels);$i++){
  if($labels[$i] eq "SRAStudy"){$studyindex=$i;}
  elsif($labels[$i] eq "Run"){$runindex=$i;}
  elsif(exists($hash->{$labels[$i]})){push(@indeces,$i);}
}
if($runindex<0){exit(1);}
if($studyindex<0){exit(1);}
while(<STDIN>){
  chomp;
  if($line eq $_){next;}
  my @tokens=splitline($_);
  my $runid=$tokens[$runindex];
  if($runid eq ""){next;}
  my $studyid=$tokens[$studyindex];
  print "$studyid\tRun\t$runid\n";
  for(my $i=0;$i<scalar(@indeces);$i++){
    my $label=$labels[$indeces[$i]];
    my $token=$tokens[$indeces[$i]];
    if($token ne ""){print "$runid\t$label\t$token\n";}
  }
}
sub splitline{
  my $line=shift();
  my @chars=split(//,$line);
  my @tokens=();
  my $token="";
  my $escape=0;
  my $previsesc=0;
  foreach my $c(@chars){
    if($c eq "," && $escape==0){
      push(@tokens,$token);
      $token="";
    }elsif($c eq "\""){
      if($escape==0){$escape=1;}
      else{$escape=0;}
    }else{
      $token.=$c;
    }
  }
  return @tokens;
}
