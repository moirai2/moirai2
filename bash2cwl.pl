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
my $outdir=defined($opt_d)?$opt_d:".";
my $basename=defined($opt_b)?$opt_b:"bash";
mkdir($outdir);
my @lines=(scalar(@ARGV)==1&&$ARGV[0]=~/\.(ba)?sh$/)?readLines($ARGV[0]):@ARGV;
my @commands=decoder(@lines);
my ($inputs,$outputs)=promptInputOutput(@commands);
my $files=workflow(\@commands,$inputs,$outputs);
my $command=writeWorkflow($files,$basename,$outdir);
print STDERR "$command\n";
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
  tester(\&decodeCommand,"ls -l -t|",0,[{"command"=>"ls","inputs"=>["-l","-t"],"stdout"=>"\|"},9]);#32
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
	my $command=decoder("echo 'Hello World!'");
	my ($lines,$inputs)=encoder($command);
	tester2($command,{"command"=>"echo","inputs"=>["Hello World!"]});#43
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","outputs: []"]);#44
	tester2($inputs,{"input1"=>{"type"=>"string","value"=>"Hello World!"}});#45
	#https://www.commonwl.org/user_guide/03-input/index.html
	$command=decoder("echo -f -i42 --example-string hello --file=whale.txt");
	tester2($command,{"command"=>"echo","inputs"=>["-f","-i42","--example-string","hello","--file=whale.txt"]});#46
	($lines,$inputs)=encoder($command);
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  input1:","    type: boolean","    inputBinding:","      position: 1","      prefix: -f","  input2:","    type: int","    inputBinding:","      position: 2","      prefix: -i","      separate: false","  input3:","    type: string","    inputBinding:","      position: 3","      prefix: --example-string","  input4:","    type: File","    inputBinding:","      position: 4","      prefix: --file=","      separate: false","outputs: []"]);#47
	tester2($inputs,{"input1"=>{"type"=>"boolean","value"=>"true"},"input2"=>{"type"=>"int","value"=>"42"},"input3"=>{"type"=>"string","value"=>"hello"},"input4"=>{"type"=>"File","value"=>"whale.txt"}});#48
	#https://www.commonwl.org/user_guide/04-output/index.html
	$command=decoder("tar --extract --file hello.tar");
	push(@{$command->{"outputs"}},"hello.txt");
	tester2($command,{"command"=>"tar","inputs"=>["--extract","--file","hello.tar"],"outputs"=>["hello.txt"]});#49
	$command->{"command"}=[$command->{"command"},shift(@{$command->{"inputs"}})];
	tester2($command,{"command"=>["tar","--extract"],"inputs"=>["--file","hello.tar"],"outputs"=>["hello.txt"]});#50
	($lines,$inputs)=encoder($command,{"argstart"=>-1});
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: [tar, --extract]","inputs:","  input1:","    type: File","    inputBinding:","      position: 1","      prefix: --file","outputs:","  output1:","    type: File","    outputBinding:","      glob: hello.txt"]);#51
	tester2($inputs,{"input1"=>{"type"=>"File","value"=>"hello.tar"}});#52
	#https://www.commonwl.org/user_guide/05-stdout/index.html
	$command=decoder("echo 'Hello World!' > output.txt");
	tester2($command,{"command"=>"echo","inputs"=>["Hello World!"],"stdout"=>"output.txt"});#53
	($lines,$inputs)=encoder($command);
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","outputs:","  output1:","    type: stdout","stdout: output.txt"]);#54
	tester2($inputs,{"input1"=>{"type"=>"string","value"=>"Hello World!"}});#55
	#https://www.commonwl.org/user_guide/06-params/index.html
	$command=decoder("tar --extract --file hello.tar goodbye.txt");
	push(@{$command->{"outputs"}},"goodbye.txt");
	tester2($command,{"command"=>"tar","inputs"=>["--extract","--file","hello.tar","goodbye.txt"],"outputs"=>["goodbye.txt"]});#56
	$command->{"command"}=[$command->{"command"},shift(@{$command->{"inputs"}})];
	($lines,$inputs)=encoder($command,{"argstart"=>2});
	tester2(encodeType("hello.txt",{"hello.txt"=>1}),"string");#57
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: [tar, --extract]","inputs:","  input1:","    type: File","    inputBinding:","      position: 1","      prefix: --file","  input2:","    type: string","    inputBinding:","      position: 2","outputs:","  output1:","    type: File","    outputBinding:","      glob: \$(inputs.input2)"]);#58
	tester2($inputs,{"input1"=>{"type"=>"File","value"=>"hello.tar"},"input2"=>{"type"=>"string","value"=>"goodbye.txt"}});#59
	#https://www.commonwl.org/user_guide/07-containers/index.html
	$command=decoder("node hello.js > output.txt");
	tester2($command,{"command"=>"node","inputs"=>["hello.js"],"stdout"=>"output.txt"});#60
	($lines,$inputs)=encoder($command,{"dockerPull"=>"node:slim"});
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","hints:","  DockerRequirement:","   dockerPull: node:slim","baseCommand: node","inputs:","  input1:","    type: File","    inputBinding:","      position: 1","outputs:","  output1:","    type: stdout","stdout: output.txt"]);#61
	tester2($inputs,{"input1"=>{"type"=>"File","value"=>"hello.js"}});#62
	#https://www.commonwl.org/user_guide/08-arguments/index.html
	$command=decoder("javac Hello.java");
	push(@{$command->{"outputs"}},"*.class");
	tester2($command,{"command"=>"javac","inputs"=>["Hello.java"],"outputs"=>["*.class"]});#63
	($lines,$inputs)=encoder($command,{"label"=>"Example trivial wrapper for Java 9 compiler","dockerPull"=>"openjdk:9.0.1-11-slim","arguments"=>["-d","\$(runtime.outdir)"]});
	tester2($inputs,{"input1"=>{"type"=>"File","value"=>"Hello.java"}});#64
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","label: Example trivial wrapper for Java 9 compiler","hints:","  DockerRequirement:","   dockerPull: openjdk:9.0.1-11-slim","baseCommand: javac","arguments: [\"-d\",\$(runtime.outdir)]","inputs:","  input1:","    type: File","    inputBinding:","      position: 1","outputs:","  output1:","    type: array","    items: File","    outputBinding:","      glob: \"*.class\""]);#65
	#https://www.commonwl.org/user_guide/09-array-inputs/index.html
	tester2(encodeTypeArray(["one","two","three"]),"string[]");#66
	tester2(encodeTypeArray([1,2,3]),"int[]");#67
	tester2(encodeTypeArray([1.1,2.2,3.3]),"double[]");#68
	tester2(encodeTypeArray(["one.txt","two.txt","three.txt"]),"File[]");#69
	tester2(encodeTypeArray(["one",2,3]),"string[]");#70
	tester2(encodeTypeArray([1.1,2,3]),"double[]");#71
	$command=decoder("echo -A=one,two,three -B four,five,six>out/output.txt");
	push(@{$command->{"inputs"}},["seven","eight","nine"]);
	tester2($command,{"command"=>"echo","inputs"=>["-A=one,two,three","-B","four,five,six",["seven","eight","nine"]],"stdout"=>"out/output.txt"});#72
	($lines,$inputs)=encoder($command);
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  input1:","    type: string[]","    inputBinding:","      position: 1","      prefix: -A=","      separate: false","      itemSeparator: \",\"","  input2:","    type: boolean","    inputBinding:","      position: 2","      prefix: -B","  input3:","    type: string[]","    inputBinding:","      position: 3","      itemSeparator: \",\"","  input4:","    type: string[]","    inputBinding:","      position: 4","outputs:","  output1:","    type: stdout","stdout: out/output.txt"]);#73
	tester2($inputs,{"input1"=>{"type"=>"string[]","value"=>"[one,two,three]"},"input2"=>{"type"=>"boolean","value"=>"true"},"input3"=>{"type"=>"string[]","value"=>"[four,five,six]"},"input4"=>{"type"=>"string[]","value"=>"[seven,eight,nine]"}});#74
	#https://github.com/pitagora-galaxy/cwl/wiki/CWL-Start-Guide-JP
	my @commands=decoder("grep one < mock.txt | wc -l > wcount.txt");
	tester2(\@commands,[{"command"=>"grep","inputs"=>["one"],"stdin"=>"mock.txt","stdout"=>"_pipe1_stdout.txt"},{"command"=>"wc","inputs"=>["-l"],"stdin"=>"_pipe1_stdout.txt","stdout"=>"wcount.txt"}]);#75
	($lines,$inputs)=encoder($commands[0]);
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: grep","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","  input2:","    type: File","    streamable: true","outputs:","  output1:","    type: stdout","stdin: \$(inputs.input2.path)","stdout: _pipe1_stdout.txt",]);#76
	tester2($inputs,{"input1"=>{"type"=>"string","value"=>"one"},"input2"=>{"type"=>"File","value"=>"mock.txt"}});#77
	($lines,$inputs)=encoder($commands[1]);
	tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: wc","inputs:","  input1:","    type: boolean","    inputBinding:","      position: 1","      prefix: -l","  input2:","    type: File","    streamable: true","outputs:","  output1:","    type: stdout","stdin: \$(inputs.input2.path)","stdout: wcount.txt"]);#78
	tester2($inputs,{"input1"=>{"type"=>"boolean","value"=>"true"},"input2"=>{"type"=>"File","value"=>"_pipe1_stdout.txt"}});#79
	my $files=workflow(\@commands,"mock.txt","wcount.txt");
	writeWorkflow($files);
	tester2($files->{"cwl/step1.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: grep","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","  input2:","    type: File","    streamable: true","outputs:","  output1:","    type: stdout","stdin: \$(inputs.input2.path)","stdout: _pipe1_stdout.txt",]);#80
	tester2($files->{"cwl/step2.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: wc","inputs:","  input1:","    type: boolean","    inputBinding:","      position: 1","      prefix: -l","  input2:","    type: File","    streamable: true","outputs:","  output1:","    type: stdout","stdin: \$(inputs.input2.path)","stdout: wcount.txt"]);#81
	tester2($files->{"workflow.cwl"},["cwlVersion: v1.0","class: Workflow","inputs:","  param1:","    type: string","  param2:","    type: File","  param3:","    type: boolean","outputs:","  result1:","    type: File","    outputSource: step2/output1","steps:","  step1:","    run: cwl/step1.cwl","    in:","      input1: param1","      input2: param2","    out: [output1]","  step2:","    run: cwl/step2.cwl","    in:","      input1: param3","      input2: step1/output1","    out: [output1]"]);#82
	tester2($files->{"workflow.yml"},{"param1"=>{"type"=>"string","value"=>"one"},"param2"=>{"type"=>"File","value"=>"mock.txt"},"param3"=>{"type"=>"boolean","value"=>"true"}});#83
	# Connecting two command lines with tmp.txt
	@commands=decoder("  grep  one  <  mock.txt  >  tmp.txt  ","   wc   -l   tmp.txt>wcount.txt   ");
	tester2(\@commands,[{"command"=>"grep","inputs"=>["one"],"stdin"=>"mock.txt","stdout"=>"tmp.txt"},{"command"=>"wc","inputs"=>["-l","tmp.txt"],"stdout"=>"wcount.txt"}]);#84
	my $files=workflow(\@commands,"mock.txt","wcount.txt");
  tester2($files->{"cwl/step1.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: grep","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","  input2:","    type: File","    streamable: true","outputs:","  output1:","    type: stdout","stdin: \$(inputs.input2.path)","stdout: tmp.txt",]);#80
	tester2($files->{"cwl/step2.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: wc","inputs:","  input1:","    type: boolean","    inputBinding:","      position: 1","      prefix: -l","  input2:","    type: File","    inputBinding:","      position: 2","outputs:","  output1:","    type: stdout","stdout: wcount.txt"]);#81
	tester2($files->{"workflow.cwl"},["cwlVersion: v1.0","class: Workflow","inputs:","  param1:","    type: string","  param2:","    type: File","  param3:","    type: boolean","outputs:","  result1:","    type: File","    outputSource: step2/output1","steps:","  step1:","    run: cwl/step1.cwl","    in:","      input1: param1","      input2: param2","    out: [output1]","  step2:","    run: cwl/step2.cwl","    in:","      input1: param3","      input2: step1/output1","    out: [output1]"]);#82
	tester2($files->{"workflow.yml"},{"param1"=>{"type"=>"string","value"=>"one"},"param2"=>{"type"=>"File","value"=>"mock.txt"},"param3"=>{"type"=>"boolean","value"=>"true"}});#83
}
############################## promptInputOutput ##############################
sub promptInputOutput{
	my @commands=@_;
	my $files={};
	my $inputs={};
	my $outputs={};
	foreach my $command(@commands){
		if(exists($command->{"stdin"})){
      my $stdin=$command->{"stdin"};
      if($stdin!~/^_/){$inputs->{$stdin}=1;}
    }
		if(exists($command->{"stdout"})){
      my $stdout=$command->{"stdout"};
      if($stdout!~/^_/){$outputs->{$command->{"stdout"}}=1;}
    }
	}
	foreach my $command(@commands){
		foreach my $file(@{$command->{"inputs"}}){
			if($file!~/\./){next;}
			if($file=~/ /){next;}
			if(exists($outputs->{$file})){next;}
			$files->{$file}=1;
		}
	}
  foreach my $file(keys(%{$files})){
    print STDERR "Is $file [i]nput or [o]utput ? ";
    my $answer=<STDIN>;
    chomp($answer);
    if($answer=~/^[Ii]/){$inputs->{$file}=1;}
    elsif($answer=~/^[Oo]/){$outputs->{$file}=1;}
  }
	my @ins=sort{$a cmp $b}keys(%{$inputs});
	my @outs=sort{$a cmp $b}keys(%{$outputs});
	return (\@ins,\@outs);
}
############################## workflow ##############################
sub workflow{
	my $commands=shift();
	my $userInputs=shift();
  my $userOutputs=shift();
  my $inputHash={};
  my $outputHash={};
  if(defined($userInputs)){
    if(ref($userInputs)ne"ARRAY"){$userInputs=[$userInputs];}
    foreach my $tmp(@{$userInputs}){$inputHash->{$tmp}=1;}
  }
  if(defined($userOutputs)){
    if(ref($userOutputs)ne"ARRAY"){$userOutputs=[$userOutputs];}
    foreach my $tmp(@{$userOutputs}){$outputHash->{$tmp}=1;}
  }
	my @lines=();
	push(@lines,"cwlVersion: v1.0");
	push(@lines,"class: Workflow");
	my @steps=();
	my $inputindex=1;
	my $outputindex=1;
	my $inputs={};
	my $outputs={};
	my $parameters={};
	my @inputLines=();
	my @outputLines=();
	my $outins={};
	my $files={};
  my $tmps={};
  my $stepindex=1;
	foreach my $command(@{$commands}){
		my $basename="step$stepindex";
		push(@steps,$basename);
		my ($lines,$ins,$outs)=encoder($command);
		$files->{"cwl/$basename.cwl"}=$lines;
		while(my($name,$hash)=each(%{$outs})){
			my $value=$hash->{"value"};
			if($value!~/^_/){next;}
			$outins->{$value}="$basename/$name";
		}
		my @keys=sort{$a cmp $b}keys(%{$ins});
		foreach my $key(@keys){
			my $hash=$ins->{$key};
			my $value=$hash->{"value"};
      my $type=$hash->{"type"};
      if(!exists($inputs->{$basename})){$inputs->{$basename}={};}
			if($value=~/^_/){
        if(exists($outins->{$value})){$inputs->{$basename}->{$key}=$outins->{$value};}
        next;
      }elsif(($type eq"File"||$type eq"stdin")&&!exists($inputHash->{$value})){
        if(exists($tmps->{$value})){$inputs->{$basename}->{$key}=$tmps->{$value};}
        next;
      }
      my $name="param$inputindex";
      $inputs->{$basename}->{$key}=$name;
      push(@inputLines,"  $name:");
  		push(@inputLines,"    type: $type");
      $parameters->{$name}=$hash;
      $inputindex++;
  	}
		@keys=sort{$a cmp $b}keys(%{$outs});
		foreach my $key(@keys){
			my $hash=$outs->{$key};
			my $type=$hash->{"type"};
			my $value=$hash->{"value"};
			if(!exists($outputs->{$basename})){$outputs->{$basename}={};}
			$outputs->{$basename}->{$key}=$value;
      $tmps->{$value}="$basename/$key";
			if($value=~/^_/){next;}
      my $name="result$outputindex";
      if(($type eq"File"||$type eq"stdout")&&!exists($outputHash->{$value})){next;}
      push(@outputLines,"  $name:");
      push(@outputLines,"    type: File");
  		push(@outputLines,"    outputSource: $basename/output$outputindex");
      $outputindex++;
		}
		$stepindex++;
	}
	if(scalar(@inputLines)>0){
		push(@lines,"inputs:");
		push(@lines,@inputLines);
	}else{push(@lines,"inputs: []");}
	if(scalar(@outputLines)>0){
		push(@lines,"outputs:");
		push(@lines,@outputLines);
	}else{push(@lines,"outputs: []");}
	push(@lines,"steps:");
	my $stepIndex=1;
	foreach my $step(@steps){
		push(@lines,"  step$stepIndex:");
		push(@lines,"    run: cwl/$step.cwl");
		push(@lines,"    in:");
		my @keys=sort{$a cmp $b}keys(%{$inputs->{$step}});
		foreach my $key(@keys){push(@lines,"      $key: ".$inputs->{$step}->{$key});}
		@keys=sort{$a cmp $b}keys(%{$outputs->{$step}});
		push(@lines,"    out: [".join(", ",@keys)."]");
		$stepIndex++;
	}
	$files->{"workflow.cwl"}=\@lines;
	$files->{"workflow.yml"}=$parameters;
	return $files;
}
############################## readLines ##############################
sub readLines{
	my $file=shift();
	open(IN,$file);
	my @lines=();
	while(<IN>){
		chomp;s/\r//g;
		push(@lines,$_);
	}
	return @lines;
}
############################## writeCwl ##############################
sub writeCwl{
	my $file=shift();
	my $array=shift();
	open(OUT,">$file");
	foreach my $line(@{$array}){print OUT "$line\n";}
	close(OUT);
}
############################## writeYml ##############################
sub writeYml{
	my $file=shift();
	my $hash=shift();
	open(OUT,">$file");
	foreach my $key(sort{$a cmp $b}keys(%{$hash})){
		my $h=$hash->{$key};
		my $type=$h->{"type"};
		my $value=$h->{"value"};
		if($type eq "File"){
			print OUT "$key:\n";
			print OUT "  class: $type\n";
			print OUT "  path: $value\n";
		}else{
			print OUT "$key: $value\n";
		}
	}
	close(OUT);
}
############################## writeWorkflow ##############################
sub writeWorkflow{
	my $files=shift();
  my $basename=shift();
	my $directory=shift();
  if(!defined($basename)){$basename="bash";}
  if(!defined($directory)){$directory=".";}
	my $cwlFile;
	my $ymlFile;
	mkdir($directory);
	mkdir("$directory/cwl");
	while(my($filename,$data)=each(%{$files})){
		if($filename eq "workflow.cwl"){
			$cwlFile="$directory/$basename.cwl";
			writeCwl($cwlFile,$data);
		}elsif($filename eq "workflow.yml"){
			$ymlFile="$directory/$basename.yml";
			writeYml($ymlFile,$data);
		}else{
			writeCwl("$directory/$filename",$data);
		}
	}
  return ($directory ne ".")?"cwltool $directory/$basename.cwl $directory/$basename.yml":"cwltool $basename.cwl $basename.yml";
}
############################## encoder ##############################
sub encoder{
	my $command=shift();
	my $param=shift();
	if(!defined($param)){$param={};}
	my $base=$command->{"command"};
	my @lines=();
	push(@lines,"cwlVersion: v1.0");
	push(@lines,"class: CommandLineTool");
	if(exists($param->{"label"})){
		push(@lines,"label: ".$param->{"label"});
	}
	if(exists($param->{"dockerPull"})){
		push(@lines,"hints:");
		push(@lines,"  DockerRequirement:");
		push(@lines,"   dockerPull: ".$param->{"dockerPull"});
	}
	if(ref($base)eq"ARRAY"){push(@lines,"baseCommand: [".join(", ",@{$base})."]");}
	else{push(@lines,"baseCommand: $base");}
	if(exists($param->{"arguments"})){
		my $line="arguments: [";
		my $index=0;
		foreach my $argument(@{$param->{"arguments"}}){
			if($index>0){$line.=",";}
			if($argument=~/^\$\(\S+\)$/){$line.=$argument;}
			else{$line.="\"$argument\"";}
			$index++;
		}
		$line.="]";
		push(@lines,$line);
	}
	push(@lines,"inputs:");
	my ($inputLines,$inputs)=encodeInput($command,$param);
	push(@lines,@{$inputLines});
	my ($outputLines,$outputs)=encodeOutput($command,$inputs);
	push(@lines,@{$outputLines});
	if(exists($command->{"stdin"})){
		my $stdin=$command->{"stdin"};
		while(my($key,$val)=each(%{$inputs})){
			if($val->{"type"}ne"File"){next;}
			if($stdin ne $val->{"value"}){next;}
			push(@lines,"stdin: \$(inputs.$key.path)");
		}
	}
	if(exists($command->{"stdout"})){push(@lines,"stdout: ".$command->{"stdout"});}
	return (\@lines,$inputs,$outputs);
}
############################## encodeOutput ##############################
sub encodeOutput{
	my $command=shift();
	my $args=shift();
	my @lines=();
	my $index=1;
	my $inouts={};
	my $outputs={};
	if(exists($command->{"outputs"})){
		my $hash={};
		while(my ($k,$v)=each(%{$args})){$hash->{$v->{"value"}}="\$(inputs.$k)";}
		foreach my $output(@{$command->{"outputs"}}){
			if(exists($hash->{$output})){$inouts->{$output}=$hash->{$output}}
		}
	}
	if(exists($command->{"outputs"})){
		if($index==1){push(@lines,"outputs:");}
		foreach my $output(@{$command->{"outputs"}}){
			my $value=$output;
			if(exists($inouts->{$output})){$value=$inouts->{$output};}
			my $name="output$index";
			$outputs->{$name}={};
			if($output=~/\*/){
				push(@lines,"  $name:");
				push(@lines,"    type: array");
				push(@lines,"    items: File");
				push(@lines,"    outputBinding:");
				push(@lines,"      glob: \"$value\"");
				$outputs->{$name}->{"type"}="File[]";
				$outputs->{$name}->{"value"}=$output;
			}else{;
				push(@lines,"  $name:");
				push(@lines,"    type: File");
				push(@lines,"    outputBinding:");
				push(@lines,"      glob: $value");
				$outputs->{$name}->{"type"}="File";
				$outputs->{$name}->{"value"}=$output;
			}
			$index++;
		}
	}
	if(exists($command->{"stdout"})){
		if($index==1){push(@lines,"outputs:");}
		my $name="output$index";
		push(@lines,"  output$index:");
		push(@lines,"    type: stdout");
		$outputs->{$name}->{"type"}="stdout";
		$outputs->{$name}->{"value"}=$command->{"stdout"};
		$index++;
	}
	if(scalar(@lines)==0){push(@lines,"outputs: []");}
	return (\@lines,$outputs);
}
############################## encodeInput ##############################
#https://www.commonwl.org/user_guide/03-input/
sub encodeInput{
	my $command=shift();
	my $param=shift();
	my @inputs=@{$command->{"inputs"}};
	my $outputs={};
	if(exists($command->{"outputs"})){foreach my $output(@{$command->{"outputs"}}){$outputs->{$output}=1;}}
	#0=argument
	#1=option boolean flag -f
	#2=option flag --example-string
	#3=option argument hello
	#4=option with '=' with argument (no separation) --file=whale.txt
	#5=option with '-' with arguments (no separation) -i42
	my @options=();
	for(my $i=0;$i<scalar(@inputs);$i++){
		if($inputs[$i]=~/\=/){$options[$i]=4;}
		elsif($inputs[$i]=~/^\-\-/){$options[$i]=1;}
		elsif($inputs[$i]=~/^\-\w\w+/){$options[$i]=5;}
		elsif($inputs[$i]=~/^\-\w/){$options[$i]=1;}
		else{$options[$i]=0;}
	}
	my $argstart=scalar(@inputs);
	if(exists($param->{"argstart"})){
		if($param->{"argstart"}<0){}
		else{$argstart=$param->{"argstart"};}
	}else{
		for(my $i=$argstart;$i>=0;$i--){if($options[$i]==0){$argstart=$i;}else{last;}}
	}
	for(my $i=0;$i<scalar(@inputs)&&$i<$argstart-1;$i++){if($options[$i]==1&&$options[$i+1]==0){$options[$i]=2;$options[$i+1]=3;}}
	my $position=1;
	my @lines=();
	my $args={};
	for(my $i=0;$i<scalar(@inputs);$i++,$position++){
		if($options[$i]==0){
			my $itemSeparator=($inputs[$i]=~/,/)?",":undef;
			my $type=encodeType($inputs[$i],$outputs);
			push(@lines,"  input$position:");
			push(@lines,"    type: $type");
			push(@lines,"    inputBinding:");
			push(@lines,"      position: $position");
			if(defined($itemSeparator)){push(@lines,"      itemSeparator: \"$itemSeparator\"");}
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
			my $itemSeparator=($inputs[$i+1]=~/,/)?",":undef;
			my $type=encodeType($inputs[$i+1],$outputs);
			push(@lines,"  input$position:");
			push(@lines,"    type: $type");
			push(@lines,"    inputBinding:");
			push(@lines,"      position: $position");
			push(@lines,"      prefix: ".$inputs[$i]);
			if(defined($itemSeparator)){push(@lines,"      itemSeparator: \"$itemSeparator\"");}
			$args->{"input$position"}=encodeValue($type,$inputs[$i+1]);
			$i++;
		}elsif($options[$i]==4){
			my ($argument,$value)=split(/\=/,$inputs[$i],2);
			my $itemSeparator=($value=~/,/)?",":undef;
			my $type=encodeType($value,$outputs);
			push(@lines,"  input$position:");
			push(@lines,"    type: $type");
			push(@lines,"    inputBinding:");
			push(@lines,"      position: $position");
			push(@lines,"      prefix: $argument=");
			push(@lines,"      separate: false");
			if(defined($itemSeparator)){push(@lines,"      itemSeparator: \"$itemSeparator\"");}
			$args->{"input$position"}=encodeValue($type,$value);
		}elsif($options[$i]==5){
			my $argument;
			my $value;
			if($inputs[$i]=~/^(\-\w)(\w+)$/){$argument=$1;$value=$2;}
			split(/\-(\w)/,);
			my $itemSeparator=($value=~/,/)?",":undef;
			my $type=encodeType($value,$outputs);
			push(@lines,"  input$position:");
			push(@lines,"    type: $type");
			push(@lines,"    inputBinding:");
			push(@lines,"      position: $position");
			push(@lines,"      prefix: $argument");
			push(@lines,"      separate: false");
			if(defined($itemSeparator)){push(@lines,"      itemSeparator: \"$itemSeparator\"");}
			$args->{"input$position"}=encodeValue($type,$value);
		}
	}
	if(exists($command->{"stdin"})){
		my $type="File";
		push(@lines,"  input$position:");
		push(@lines,"    type: $type");
		push(@lines,"    streamable: true");
		$args->{"input$position"}=encodeValue($type,$command->{"stdin"});
		$position++;
	}
	return (\@lines,$args);
}
############################## encodeType ##############################
# string, int, long, float, double, and null, array, record, File, Directory
sub encodeType{
	my $argument=shift();
	my $outputs=shift();
	if(ref($argument)eq"ARRAY"){
		return encodeTypeArray($argument,$outputs);
	}elsif($argument=~/,/){
		my @temp=split(/,/,$argument);
		return encodeTypeArray(\@temp,$outputs);
	}else{
		return encodeTypeSub($argument,$outputs);
	}
}
sub encodeTypeArray{
	my $arguments=shift();
	my $outputs=shift();
	my $types={};
	foreach my $arg(@{$arguments}){$types->{encodeTypeSub($arg,$outputs)}++;}
	my @diffs=keys(%{$types});
	if(scalar(@diffs)==1){return $diffs[0]."[]";}
	elsif(exists($types->{"string"})){return "string[]";}
	elsif(exists($types->{"double"})){return "double[]";}
	else{return "string[]";}
}
sub encodeTypeSub{
	my $argument=shift();
	my $outputs=shift();
	#https://docstore.mik.ua/orelly/perl4/cook/ch02_02.htm
	if($argument=~/^[+-]?\d+$/){return "int";}
	if($argument=~/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/){return "double";}
	if($argument=~/[\w_]+\.\w+/){
		if(exists($outputs->{$argument})){return "string";}
		else{return "File";}
	}
	return "string";
}
sub encodeValue{
	my $type=shift();
	my $value=shift();
	if($type =~ /\[\]/){
		if(ref($value)eq"ARRAY"){return {"type"=>$type,"value"=>"[".join(",",@{$value})."]"};}
		else{return {"type"=>$type,"value"=>"[$value]"};}
	}else{return {"type"=>$type,"value"=>$value};}
}
############################## decoder ##############################
#https://devhints.io/bash
sub decoder{
	my @strings=@_;
	my @commands=();
	my $piped=undef;
	foreach my $string(@strings){
		my @chars=split(//,$string);
		my $value;
		my $index=0;
		while($index<scalar(@chars)){
			($value,$index)=decodeCommand(\@chars,$index);
			if(defined($piped)){$value->{"stdin"}=$piped;}
			if(exists($value->{"stdout"})&&$value->{"stdout"}eq"\|"){
				$piped="_pipe".(scalar(@commands)+1)."_stdout.txt";
				$value->{"stdout"}=$piped;
			}else{
				$piped=undef;
			}
			push(@commands,$value);
		}
	}
	return wantarray?@commands:$commands[0];
}
sub decodeCommand{
	my $chars=shift();
	my $index=shift();
  my $value;
  $index=decodeSpace($chars,$index);
	($value,$index)=decodeCommandName($chars,$index);
  if($chars->[$index]eq"="){
    my $command={"command"=>"_assign_","name"=>$value};
    ($value,$index)=decodeCommandToken($chars,$index+1);
    $command->{"value"}=$value;
    return ($command,$index);
  }
  my $command={"command"=>$value};
  if($chars->[$index]eq" "){
    ($value,$index)=decodeCommandTokens($chars,$index+1);
    if(scalar(@{$value})>0){$command->{"inputs"}=$value;}
  }
	if($chars->[$index]eq"<"){
    $index=decodeSpace($chars,$index+1);
    ($value,$index)=decodeCommandToken($chars,$index);
		$command->{"stdin"}=$value;
		$index=decodeSpace($chars,$index);
	}
  if($chars->[$index]eq">"){
    $index=decodeSpace($chars,$index+1);
    ($value,$index)=decodeCommandToken($chars,$index);
		$command->{"stdout"}=$value;
		$index=decodeSpace($chars,$index);
  }
	if($chars->[$index]eq"\|"){
  	$command->{"stdout"}="\|";
		$index=decodeSpace($chars,$index+1);
	}
  return ($command,$index);
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
		elsif($chars->[$index]eq"<"){last;}
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
		elsif($chars->[$index]eq"<"){last;}
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
