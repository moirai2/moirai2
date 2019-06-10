my @chromosomes={};
while(<STDIN>){
	chomp;
	if(/^\@SQ\t(.+)$/){
		my $chromosome;
		my $size;
		foreach my $token(split(/\t/,$1)){
			my ($key,$val)=split(/\:/,$token);
			if($key eq "SN"){$chromosome=$val;}
			if($key eq "LN"){$size=$val;}
		}
		$chromosomes->{$chromosome}=$size;
	}
}
foreach my $chromosome(sort{$a cmp $b}keys(%{$chromosomes})){
	my $size=$chromosomes->{$chromosome};
	print "$chromosome\t$size\n";
}
