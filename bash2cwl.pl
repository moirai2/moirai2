#!/usr/bin/perl
use strict 'vars';
#https://devhints.io/bash
#push(@ARGV,"\"John\"");
#push(@ARGV,"\'Silver\'");
#push(@ARGV,"NAME=\"John\"");
#push(@ARGV,"wc -l a.txt > b.txt");
#@ARGV=("\$test\$test2","wc -l a.txt > b.txt");
my $testcount=1;
if(scalar(@ARGV)==1&&$ARGV[0] eq "test"){test();exit();}
foreach my $command(@ARGV){
	chomp($command);
	print STDERR ">$command\n";
	my @chars=split(//,$command);
	my @codes=decode(\@chars,0);
	print_table(\@codes);
}
sub test(){
  tester(\&decodeParenthesis,"hello",0,[undef,0]);#1
  tester(\&decodeParenthesis,"{hello}",0,["hello",7]);#2
  tester(\&decodeSingleQuote,"hello",0,[undef,0]);#3
  tester(\&decodeSingleQuote,"'hello'",0,["hello",7]);#4
  tester(\&decodeDoubleQuote,"hello",0,[undef,0]);#5
  tester(\&decodeDoubleQuote,"\"hello\"",0,["hello",7]);#6
  tester(\&decodeVariable,"hello",0,[undef,0]);#7
  tester(\&decodeVariable,"\$hello",0,["\$hello",6]);#8
  tester(\&decodeVariable,"\${hello}",0,["\$hello",8]);#9
  tester(\&decodeCommandName,"hello",0,["hello",5]);#10
  tester(\&decodeCommandName,"hello>",0,["hello",5]);#11
  tester(\&decodeCommandName,"hello>",0,["hello",5]);#12
  tester(\&decodeCommandName,"hello|",0,["hello",5]);#13
  tester(\&decodeCommandName,"123",0,[undef,0]);#14
  tester(\&decodeCommandName,"h123",0,["h123",4]);#15
  tester(\&decodeCommandName,"h123#",0,["h123",4]);#16
  tester(\&decodeCommandName,"\$ls",0,["\$ls",3]);#17
  tester(\&decodeCommandName,"\"ls\"",0,["ls",4]);#18
  tester(\&decodeCommandName,"\'ls\'",0,["ls",4]);#19
  tester(\&decodeDoubleQuote,"\"hello\$hello\"",0,["hello\$hello",13]);#20
  tester(\&decodeCommand,"ls",0,[{"command"=>"ls"},2]);#21
  tester(\&decodeCommand,"\'ls\'",0,[{"command"=>"ls"},4]);#22
  tester(\&decodeCommand,"\"ls\"",0,[{"command"=>"ls"},4]);#23
  tester(\&decodeCommand,"a=b",0,[{"command"=>"_assign_","name"=>"a","value"=>"b"},3]);#24
  tester(\&decodeCommand,"ls -l",0,[{"command"=>"ls","arguments"=>["-l"]},5]);#25
  tester(\&decodeCommand,"\"ls\" -l",0,[{"command"=>"ls","arguments"=>["-l"]},7]);#26
  tester(\&decodeCommand,"\"ls\" \"-l\"",0,[{"command"=>"ls","arguments"=>["-l"]},9]);#27
  tester(\&decodeCommandName,"\"l\"\"s\"",0,["ls",6]);#28
  tester(\&decodeCommand,"\"l\"\"s\" '-''l'",0,[{"command"=>"ls","arguments"=>["-l"]},13]);#29
  tester(\&decodeCommand,"ls -l -t",0,[{"command"=>"ls","arguments"=>["-l","-t"]},8]);#30
  tester(\&decodeCommand,"ls -l -t ",0,[{"command"=>"ls","arguments"=>["-l","-t"]},9]);#31
  tester(\&decodeCommand,"ls -l -t|",0,[{"command"=>"ls","arguments"=>["-l","-t"]},8]);#32
  tester(\&decodeCommand,"ls -l -t>output.txt",0,[{"command"=>{"command"=>"ls","arguments"=>["-l","-t"]},"stdout"=>"output.txt"},19]);#33
  tester(\&decodeCommand,"ls  -l  -t>output.txt",0,[{"command"=>{"command"=>"ls","arguments"=>["-l","-t"]},"stdout"=>"output.txt"},21]);#34
  tester(\&decodeCommand,"ls -l -t > output.txt",0,[{"command"=>{"command"=>"ls","arguments"=>["-l","-t"]},"stdout"=>"output.txt"},21]);#35
  tester(\&decodeCommand,"'l's '-l' \"-t\" > \"output\".\'txt\'",0,[{"command"=>{"command"=>"ls","arguments"=>["-l","-t"]},"stdout"=>"output.txt"},31]);#35
}
sub tester{
  my $function=shift();
  my $string=shift();
  my $index=shift();
  my $answer=shift();
  my @chars=split(//,$string);
  my @result=$function->(\@chars,$index);
  if(compare(\@result,$answer)){
    print STDERR "ERROR at test$testcount\n";
    print STDERR ">wrong\n";
    print_table(\@result);
    print STDERR ">correct\n";
    print_table($answer);
  }
  $testcount++;
}
sub compare{
  my $a=shift();
  my $b=shift();
  if(!defined($a)&&!defined($b)){
    return 0;
  }elsif(ref($a)eq"ARRAY"){
    if(ref($b)ne"ARRAY"){return 1;}
    my $len1=scalar(@{$a});
    my $len2=scalar(@{$b});
    if($len1!=$len2){return 1;}
    for(my $i=0;$i<$len1;$i++){if(compare($a->[$i],$b->[$i])){return 1;}}
  }elsif(ref($a)eq"HASH"){
    if(ref($b)ne"HASH"){return 1;}
    my @keys1=keys(%{$a});
    my @keys2=keys(%{$b});
    if(scalar(@keys1)!=scalar(@keys2)){return 1;}
    foreach my $key(@keys1){
      if(!exists($b->{$key})){return 1;}
      if(compare($a->{$key},$b->{$key})){return 1;}
    }
  }else{
    if($a ne $b){return 1;}
  }
  return 0;
}
sub decode{
	my $chars=shift();
	my $start=shift();
	my @codes=();
  my $value;
	for(my $index=$start;$index<scalar(@{$chars});$index++){
		($value,$index)=decodeCommand($chars,$index);
		push(@codes,$value);
	}
	return @codes;
}
sub decodeCommand{
	my $chars=shift();
	my $index=shift();
  my $value;
	($value,$index)=decodeCommandName($chars,$index);
  if($chars->[$index]eq"="){
    my $hash={"command"=>"_assign_","name"=>$value};
    ($value,$index)=decodeCommandToken($chars,$index+1);
    $hash->{"value"}=$value;
    return ($hash,$index);
  }
  my $hash={"command"=>$value};
  if($chars->[$index]eq" "){
    ($value,$index)=decodeCommandTokens($chars,$index+1);
    if(scalar(@{$value})>0){$hash->{"arguments"}=$value;}
  }
  $index=decodeSpace($chars,$index);
  if($chars->[$index]eq">"){
    $index=decodeSpace($chars,$index+1);
    ($value,$index)=decodeCommandToken($chars,$index);
    my $temp={"stdout"=>$value,"command"=>$hash};
    $hash=$temp;
  }
  return ($hash,$index);
}
sub decodeSpace{
  my $chars=shift();
	my $index=shift();
	while($index<scalar(@{$chars})){
    if($chars->[$index]eq" "){$index++;}
    else{last;}
  }
  return $index;
}
sub decodeCommandToken{
	my $chars=shift();
	my $start=shift();
	my $index=$start;
  my $token="";
	my $value;
	while($index<scalar(@{$chars})){
    if($chars->[$index]eq" "){last;}
    elsif($chars->[$index]eq"|"){last;}
    elsif($chars->[$index]eq">"){last;}
		elsif($chars->[$index] eq "\$"){
      ($value,$index)=decodeVariable($chars,$index);
      $token.=$value;
    }elsif($chars->[$index] eq "\""){
      ($value,$index)=decodeDoubleQuote($chars,$index);
      $token.=$value;
    }elsif($chars->[$index] eq "\'"){
      ($value,$index)=decodeSingleQuote($chars,$index);
      $token.=$value;
    }else{
      $token.=$chars->[$index];
      $index++;
    }
	}
	return ($token,$index);
}
sub decodeCommandTokens{
  my $chars=shift();
	my $index=shift();
  my @tokens=();
  my $value;
  while($index<scalar(@{$chars})){
    if($chars->[$index]eq" "){$index++;next;}
    elsif($chars->[$index]eq"|"){last;}
    elsif($chars->[$index]eq">"){last;}
    ($value,$index)=decodeCommandToken($chars,$index);
    if(scalar($value)){push(@tokens,$value);}
  }
	return (\@tokens,$index);
}
sub decodeCommandName{
	my $chars=shift();
	my $start=shift();
	my $index=$start;
  if($chars->[$index]!~/[A-za-z\$\"\']/){return (undef,$index);}
	my $value;
	while($index<scalar(@{$chars})){
		if($chars->[$index] eq "\$"){
      my ($value2,$index2)=decodeVariable($chars,$index);
      $value.=$value2;
      $index=$index2;
    }elsif($chars->[$index] eq "\""){
      my ($value2,$index2)=decodeDoubleQuote($chars,$index);
      $value.=$value2;
      $index=$index2;
    }elsif($chars->[$index] eq "\'"){
      my ($value2,$index2)=decodeSingleQuote($chars,$index);
      $value.=$value2;
      $index=$index2;
    }elsif($chars->[$index]=~/[A-za-z0-9]/){$value.=$chars->[$index];$index++;
    }else{last;}
	}
	return ($value,$index);
}
sub decodeVariable{
	my $chars=shift();
	my $index=shift();
  if($chars->[$index]ne"\$"){return (undef,0);}
	my $value;
  $index++;
	if($chars->[$index] eq "{"){
		my ($value2,$index2)=decodeParenthesis($chars,$index);
    return ("\$$value2",$index2);
	}
	for(;$index<scalar(@{$chars});$index++){
		if($chars=~/[a-zA-Z_0-9]/){$value.=$chars->[$index];}
	}
	return ("\$$value",$index);
}
sub decodeParenthesis{
	my $chars=shift();
	my $index=shift();
	my $value="";
  if($chars->[$index]ne"{"){return (undef,$index);}
	for($index++;$index<scalar(@{$chars});$index++){
    if($chars->[$index] eq "}"){last;}
    else{$value.=$chars->[$index];}
	}
	return ($value,$index+1);
}
sub decodeDoubleQuote{
	my $chars=shift();
	my $index=shift();
  if($chars->[$index]ne"\""){return (undef,$index);}
	my $value;
	for($index++;$index<scalar(@{$chars});$index++){
		if($chars->[$index] eq "\""){if($chars->[$index-1] ne "\\"){last;}}
		$value.=$chars->[$index];
	}
	return (jsonUnescape($value),$index+1);
}
sub decodeSingleQuote{
	my $chars=shift();
	my $index=shift();
  if($chars->[$index]ne"\'"){return (undef,$index);}
	my $value;
	for($index++;$index<scalar(@{$chars});$index++){
		if($chars->[$index] eq "\'"){if($chars->[$index-1] ne "\\"){last;}}
		$value.=$chars->[$index];
	}
	return (jsonUnescape($value),$index+1);
}
sub jsonUnescape{
	my $text=shift();
	$text=~s/\\\\/#_ESCAPED_#/g;
	$text=~s/\\"/\"/g;
	$text=~s/\\t/\t/g;
	$text=~s/\\r/\r/g;
	$text=~s/\\n/\n/g;
	$text=~s/#_ESCAPED_#/\\/g;
	return $text;
}
############################## print_table ##############################
sub print_table{
	my @out=@_;
	my $return_type=$out[0];
	if(lc($return_type) eq "print"){$return_type=0;shift(@out);}
	elsif(lc($return_type) eq "array"){$return_type=1;shift(@out);}
	elsif(lc($return_type) eq "stderr"){$return_type=2;shift(@out);}
	else{$return_type= 2;}
	print_table_sub($return_type,"",@out);
}
sub print_table_sub{
	my @out=@_;
	my $return_type=shift(@out);
	my $string=shift(@out);
	my @output=();
	for(@out){
		if(ref( $_ ) eq "ARRAY"){
			my @array=@{$_};
			my $size=scalar(@array);
			if($size==0){
				if($return_type==0){print $string."[]\n";}
				elsif($return_type==1){push(@output,$string."[]");}
				elsif($return_type==2){print STDERR $string."[]\n";}
			}else{
				for(my $i=0;$i<$size;$i++){push(@output,print_table_sub($return_type,$string."[$i]=>\t",$array[$i]));}
			}
		} elsif(ref($_)eq"HASH"){
			my %hash=%{$_};
			my @keys=sort{$a cmp $b}keys(%hash);
			my $size=scalar(@keys);
			if($size==0){
				if($return_type==0){print $string."{}\n";}
				elsif($return_type==1){push( @output,$string."{}");}
				elsif($return_type==2){print STDERR $string."{}\n";}
			}else{
				foreach my $key(@keys){push(@output,print_table_sub($return_type,$string."{$key}=>\t",$hash{$key}));}
			}
		}elsif($return_type==0){print "$string\"$_\"\n";}
		elsif($return_type==1){push( @output,"$string\"$_\"");}
		elsif($return_type==2){print STDERR "$string\"$_\"\n";}
	}
	return wantarray?@output:$output[0];
}
