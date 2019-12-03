#!/usr/bin/perl
use strict 'vars';
use Getopt::Std;
############################## OPTIONS ##############################
use vars qw($opt_b $opt_d $opt_h $opt_i $opt_o $opt_r);
getopts('b:d:hi:o:r');
############################## main ##############################
my $testcount=1;
if(scalar(@ARGV)==1&&$ARGV[0] eq "test"){test();exit();}
my @inputs=();
my @outputs=();
if(defined($opt_i)){@inputs=split(/,/,$opt_i);}
if(defined($opt_o)){@inputs=split(/,/,$opt_o);}
my $outdir=defined($opt_d)?$opt_d:"out";
my $basename=defined($opt_b)?$opt_b:"bash";
mkdir($outdir);
foreach my $arg(@ARGV){
	my @lines=();
	if(-e $arg){
		foreach my $line(readLines($arg)){
			my $command=decode($line);
			my ($lines,$args)=encoder($command);
			print_table($lines);
			print_table($args);
		}
	}else{
		my $command=decode($arg);
		my ($lines,$args)=encoder($command);
		my $cwlfile="$outdir/$basename.cwl";
		my $ymlfile="$outdir/$basename.yml";
		writeArray($cwlfile,$lines);
		writeHash($ymlfile,$args);
		my $command="cwltool $cwlfile $ymlfile";
		print STDERR ">$command\n";
		if(defined($opt_r)){system($command);}
	}
}
############################## test ##############################
sub test{
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
  tester(\&decodeCommand,"ls -l",0,[{"command"=>"ls","inputs"=>["-l"]},5]);#25
  tester(\&decodeCommand,"\"ls\" -l",0,[{"command"=>"ls","inputs"=>["-l"]},7]);#26
  tester(\&decodeCommand,"\"ls\" \"-l\"",0,[{"command"=>"ls","inputs"=>["-l"]},9]);#27
  tester(\&decodeCommandName,"\"l\"\"s\"",0,["ls",6]);#28
  tester(\&decodeCommand,"\"l\"\"s\" '-''l'",0,[{"command"=>"ls","inputs"=>["-l"]},13]);#29
  tester(\&decodeCommand,"ls -l -t",0,[{"command"=>"ls","inputs"=>["-l","-t"]},8]);#30
  tester(\&decodeCommand,"ls -l -t ",0,[{"command"=>"ls","inputs"=>["-l","-t"]},9]);#31
  tester(\&decodeCommand,"ls -l -t|",0,[{"command"=>"ls","inputs"=>["-l","-t"]},8]);#32
  tester(\&decodeCommand,"ls -l -t>output.txt",0,[{"command"=>"ls","inputs"=>["-l","-t"],"stdout"=>"output.txt"},19]);#33
  tester(\&decodeCommand,"ls  -l  -t>output.txt",0,[{"command"=>"ls","inputs"=>["-l","-t"],"stdout"=>"output.txt"},21]);#34
  tester(\&decodeCommand,"ls -l -t > output.txt",0,[{"command"=>"ls","inputs"=>["-l","-t"],"stdout"=>"output.txt"},21]);#35
  tester(\&decodeCommand,"'l's '-l' \"-t\" > \"output\".\'txt\'",0,[{"command"=>"ls","inputs"=>["-l","-t"],"stdout"=>"output.txt"},31]);#36
	tester2(encodeType("10"),"int");#37
	tester2(encodeType("-12"),"int");#38
	tester2(encodeType("1.1"),"double");#39
	tester2(encodeType("-1.2"),"double");#40
	tester2(encodeType("whale.txt"),"File");#41
	tester2(encodeType("Hello World"),"string");#42
	#https://www.commonwl.org/user_guide/02-1st-example/index.html
	my $command=decode("echo 'Hello World!'");
	my ($lines,$args)=encoder($command);
	tester2($command,{"command"=>"echo","inputs"=>["Hello World!"]});#43
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","outputs: []"]);#44
	tester2($args,{"input1"=>"Hello World!"});#45
	#https://www.commonwl.org/user_guide/03-input/index.html
	$command=decode("echo -f -i42 --example-string hello --file=whale.txt");
	tester2($command,{"command"=>"echo","inputs"=>["-f","-i42","--example-string","hello","--file=whale.txt"]});
	($lines,$args)=encoder($command);
	writeHash("hash.txt",$args);
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  input1:","    type: boolean","    inputBinding:","      position: 1","      prefix: -f","  input2:","    type: int","    inputBinding:","      position: 2","      prefix: -i","      separate: false","  input3:","    type: string","    inputBinding:","      position: 3","      prefix: --example-string","  input4:","    type: File","    inputBinding:","      position: 4","      prefix: --file=","      separate: false","outputs: []"]);#46
	tester2($args,{"input1"=>"true","input2"=>"42","input3"=>"hello","input4"=>{"class"=>"File","path"=>"whale.txt"}});#47
	#https://www.commonwl.org/user_guide/04-output/index.html
	$command=decode("tar --extract --file hello.tar");
	tester2($command,{"command"=>"tar","inputs"=>["--extract","--file","hello.tar"]});#48
	$command->{"outputs"}=["hello.txt"];
	$command->{"command"}=[$command->{"command"},shift(@{$command->{"inputs"}})];
	tester2($command,{"command"=>["tar","--extract"],"inputs"=>["--file","hello.tar"],"outputs"=>["hello.txt"]});#48
	($lines,$args)=encoder($command);
	#print_table($command);
	print_table($lines);
	print_table($args);
}
############################## readLines ##############################
sub readLines{
	my $file=shift();
	open(IN,$file);
	my @lines=();
	while(<IN>){
		chomp;s/\r//g;
		open(@lines,$_);
	}
	return @lines;
}
############################## writeArray ##############################
sub writeArray{
	my $file=shift();
	my $array=shift();
	open(OUT,">$file");
	foreach my $line(@{$array}){print OUT "$line\n";}
	close(OUT);
}
############################## writeHash ##############################
sub writeHash{
	my $file=shift();
	my $hash=shift();
	open(OUT,">$file");
	foreach my $key(sort{$a cmp $b}keys(%{$hash})){
		my $val=$hash->{$key};
		if(ref($val)eq"HASH"){
			print OUT "$key:\n";
			foreach my $k(sort{$a cmp $b}keys(%{$val})){
				my $v=$val->{$k};
				print OUT "  $k: $v\n";
			}
		}else{print OUT "$key: $val\n";}
	}
	close(OUT);
}
############################## encoder ##############################
sub encoder{
	my $hash=shift();
	my $command=$hash->{"command"};
	my @lines=();
	push(@lines,"cwlVersion: v1.0");
	push(@lines,"class: CommandLineTool");
	if(ref($command)eq"ARRAY"){push(@lines,"baseCommand: [".join(", ",@{$command})."]");}
	else{push(@lines,"baseCommand: $command");}
	push(@lines,"inputs:");
	my ($inputs,$args)=encodeInput($hash);
	push(@lines,@{$inputs});
	push(@lines,encodeOutput($hash));
	return (\@lines,$args);
}
sub encodeOutput{
	my $command=shift();
	my @lines=();
	if(exists($command->{"stdout"})){
		push(@lines,"outputs:");
		push(@lines,"  output1:");
		push(@lines,"  type: File");
		push(@lines,"  outputBinding:");
		push(@lines,"    glob: ".$command->{"stdout"});
	}else{
		push(@lines,"outputs: []");
	}
	return @lines;
}
#https://www.commonwl.org/user_guide/03-input/
sub encodeInput{
	my $command=shift();
	my @inputs=@{$command->{"inputs"}};
	#0=argument
	#1=option boolean flag -f
	#2=option flag --example-string
	#3=option argument hello
	#4=option with '=' with argument (no separation) --file=whale.txt
	#5=option with '-' with arguments (no separation) -i42
	my @options=();
	for(my $i=0;$i<scalar(@inputs);$i++){
		if($inputs[$i]=~/^\-\-/){
			if($inputs[$i]=~/\=/){$options[$i]=4;}
			else{$options[$i]=1;}
		}elsif($inputs[$i]=~/^\-\w\w+/){$options[$i]=5;}
		elsif($inputs[$i]=~/^\-\w/){$options[$i]=1;}
		else{$options[$i]=0;}
	}
	my $argstart=scalar(@inputs)-1;
	for(my $i=$argstart;$i>=0;$i--){if($options[$i]==0){$argstart=$i;}else{last;}}
	for(my $i=0;$i<scalar(@inputs)&&$i<$argstart-1;$i++){if($options[$i]==1&&$options[$i+1]==0){$options[$i]=2;$options[$i+1]=3;}}
	my $position=1;
	my @lines=();
	my $args={};
	for(my $i=0;$i<scalar(@inputs);$i++,$position++){
		if($options[$i]==0){
			my $type=encodeType($inputs[$i]);
			push(@lines,"  input$position:");
			push(@lines,"    type: $type");
			push(@lines,"    inputBinding:");
			push(@lines,"      position: $position");
			$args->{"input$position"}=encodeValue($type,$inputs[$i]);
		}elsif($options[$i]==1){
			my $type="boolean";
			push(@lines,"  input$position:");
			push(@lines,"    type: $type");
			push(@lines,"    inputBinding:");
			push(@lines,"      position: $position");
			push(@lines,"      prefix: ".$inputs[$i]);
			$args->{"input$position"}=encodeValue($type,"true");
		}elsif($options[$i]==2&&$options[$i+1]==3){
			my $type=encodeType($inputs[$i+1]);
			push(@lines,"  input$position:");
			push(@lines,"    type: $type");
			push(@lines,"    inputBinding:");
			push(@lines,"      position: $position");
			push(@lines,"      prefix: ".$inputs[$i]);
			$args->{"input$position"}=encodeValue($type,$inputs[$i+1]);
			$i++;
		}elsif($options[$i]==4){
			my ($argument,$value)=split(/\=/,$inputs[$i]);
			my $type=encodeType($value);
			push(@lines,"  input$position:");
			push(@lines,"    type: $type");
			push(@lines,"    inputBinding:");
			push(@lines,"      position: $position");
			push(@lines,"      prefix: $argument=");
			push(@lines,"      separate: false");
			$args->{"input$position"}=encodeValue($type,$value);
		}elsif($options[$i]==5){
			my $argument;
			my $value;
			if($inputs[$i]=~/^(\-\w)(\w+)$/){$argument=$1;$value=$2;}
			split(/\-(\w)/,);
			my $type=encodeType($value);
			push(@lines,"  input$position:");
			push(@lines,"    type: $type");
			push(@lines,"    inputBinding:");
			push(@lines,"      position: $position");
			push(@lines,"      prefix: $argument");
			push(@lines,"      separate: false");
			$args->{"input$position"}=encodeValue($type,$value);
		}
	}
	return (\@lines,$args);
}
# string, int, long, float, double, and null, array, record, File, Directory
sub encodeType{
	my $argument=shift();
	#https://docstore.mik.ua/orelly/perl4/cook/ch02_02.htm
	if($argument=~/^[+-]?\d+$/){return "int";}
	if($argument=~/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/){return "double";}
	if($argument=~/[\w_]+\.\w+/){return "File";}
	return "string";
}
sub encodeValue{
	my $type=shift();
	my $value=shift();
	if($type eq "File"){return {"class"=>"File","path"=>$value};}
	else{return "$value";}
}
############################## decoder ##############################
#https://devhints.io/bash
sub decode{
	my $string=shift();
	my @codes=();
  my $value;
	my $index=0;
	my @chars=split(//,$string);
	while($index<scalar(@chars)){
		($value,$index)=decodeCommand(\@chars,$index);
		push(@codes,$value);
	}
	return wantarray?@codes:$codes[0];
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
    if(scalar(@{$value})>0){$hash->{"inputs"}=$value;}
  }
  $index=decodeSpace($chars,$index);
  if($chars->[$index]eq">"){
    $index=decodeSpace($chars,$index+1);
    ($value,$index)=decodeCommandToken($chars,$index);
		$hash->{"stdout"}=$value;
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
	my $index=shift();
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
	my $index=shift();
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
    }elsif($chars->[$index]=~/[A-za-z0-9]/){$value.=$chars->[$index];$index++;}
		else{last;}
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
############################## tester ##############################
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
sub tester2{
	my $a=shift();
  my $b=shift();
	if(compare($a,$b)){
    print STDERR "ERROR at test$testcount\n";
    print STDERR ">wrong\n";
    print_table($a);
    print STDERR ">correct\n";
    print_table($b);
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
