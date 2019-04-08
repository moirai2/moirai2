############################## pushRegion ##############################
sub pushRegion{
  my $regions=shift();
  my ($start,$end)=@{shift()};
  if(scalar(@{$regions})==0){return ([$start,$end]);}
  my @array=();
  my $found=0;
  my $start1=0;
  foreach my $line(@{$regions}){
    my ($start2,$end2)=@{$line};
    if($found==1){
      if($end<$start2){push(@array,[$start1,$end]);push(@array,[$start2,$end2]);$found=2;}
      elsif($end<=$end2){push(@array,[$start1,$end2]);$found=2;}
    }elsif($found==2){
      push(@array,[$start2,$end2]);
    }elsif($end<$start2-1){
      push(@array,[$start,$end]);
      push(@array,[$start2,$end2]);
      $found=2;
    }elsif($end2<$start-1){
      push(@array,[$start2,$end2]);
    }elsif($start<$start2){
      if($end<=$end2){push(@array,[$start,$end2]);$found=2;}
      else{$start1=$start;$found=1;}
    }else{
      if($end<=$end2){push(@array,[$start2,$end2]);$found=2}
      else{$start1=$start2;$found=1;}
    }
  }
  if($found==0){push(@array,[$start,$end]);}
  elsif($found==1){push(@array,[$start1,$end]);}
  return @array;
}
