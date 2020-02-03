#!/usr/bin/perl
use strict 'vars';
use File::Basename;
use Cwd;
use Getopt::Std;
############################## OPTIONS ##############################
use vars qw($opt_b $opt_d $opt_h $opt_i $opt_o $opt_r);
getopts('b:d:hi:o:r');
############################## main ##############################
if(scalar(@ARGV)==0||defined($opt_h)){help();exit();}
my $testcount=1;
if(scalar(@ARGV)==1&&$ARGV[0] eq "test"){test();exit();}
my $inputs=[];
my $outputs=[];
if(defined($opt_i)){my @temp=split(/,/,$opt_i);$inputs=\@temp;}
if(defined($opt_o)){my @temp=split(/,/,$opt_o);$outputs=\@temp;}
my $outdir=defined($opt_d)?$opt_d:".";
my $basename=defined($opt_b)?$opt_b:"bash";
mkdir($outdir);
my @lines=(scalar(@ARGV)==1&&$ARGV[0]=~/\.(ba)?sh$/)?readLines($ARGV[0]):@ARGV;
my @commands=decoder(@lines);
if(scalar(@{$inputs})==0&&scalar(@{$outputs})==0){($inputs,$outputs)=promptInputOutput(@commands);}
my $files=workflow(\@commands,$inputs,$outputs);
my $results=writeWorkflow($files,$basename,$outdir);
if(scalar(@{$inputs})>0){$results->{"inputs"}=$inputs;}
if(scalar(@{$outputs})>0){$results->{"outputs"}=$outputs;}
showWorkflow($results);
if(defined($opt_r)){runWorkflow($results);}
############################## help ##############################
sub help{
  print "\n";
  print "Program: Convert bash command lines to CWL and YML format files.\n";
  print "Author: Akira Hasegawa (akira.hasegawa\@riken.jp)\n";
  print "\n";
  print "Usage: bash2cwl COMMAND [COMMAND ..]\n";
  print "    COMMAND  Command lines to convert.\n";
  print "         -b  CWL and YML base name (default='bash').\n";
  print "         -d  A directory to write CWL and YML files(default='.').\n";
  print "         -h  Show help.\n";
  print "         -i  Register input files of a workflow separated with ',' (default='none').\n";
  print "         -o  Register output files of a workflow separated with ',' (default='none').\n";
  print "         -r  Run workfile with cmltool (default='none').\n";
  print "\n";
  print "    Example: bash2cwl \"echo 'hello world' | wc > count.txt\"\n";
  print "\n";
  print "Usage: bash2cwl BASH\n";
  print "       BASH  A BASH file with command lines to convert.\n";
  print "         -b  CWL and YML base name (default='bash').\n";
  print "         -d  A directory to write CWL and YML files(default='.').\n";
  print "         -h  Show help.\n";
  print "         -i  Register input files of a workflow separated with ',' (default='none').\n";
  print "         -o  Register output files of a workflow separated with ',' (default='none').\n";
  print "         -r  Run workfile with cmltool (default='none').\n";
  print "\n";
  print "Usage: bash2cwl test\n";
  print "\n";
  print "         Runs test for development (Test Driven Development)\n";
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
  tester(\&decodeCommand,"ls -l",0,[{"command"=>"ls","input"=>["-l"]},5]);#25
  tester(\&decodeCommand,"\"ls\" -l",0,[{"command"=>"ls","input"=>["-l"]},7]);#26
  tester(\&decodeCommand,"\"ls\" \"-l\"",0,[{"command"=>"ls","input"=>["-l"]},9]);#27
  tester(\&decodeCommandName,"\"l\"\"s\"",0,["ls",6]);#28
  tester(\&decodeCommand,"\"l\"\"s\" '-''l'",0,[{"command"=>"ls","input"=>["-l"]},13]);#29
  tester(\&decodeCommand,"ls -l -t",0,[{"command"=>"ls","input"=>["-l","-t"]},8]);#30
  tester(\&decodeCommand,"ls -l -t ",0,[{"command"=>"ls","input"=>["-l","-t"]},9]);#31
  tester(\&decodeCommand,"ls -l -t|",0,[{"command"=>"ls","input"=>["-l","-t"],"stdout"=>"\|"},9]);#32
  tester(\&decodeCommand,"ls -l -t>output.txt",0,[{"command"=>"ls","input"=>["-l","-t"],"stdout"=>"output.txt"},19]);#33
  tester(\&decodeCommand,"ls  -l  -t>output.txt",0,[{"command"=>"ls","input"=>["-l","-t"],"stdout"=>"output.txt"},21]);#34
  tester(\&decodeCommand,"ls -l -t > output.txt",0,[{"command"=>"ls","input"=>["-l","-t"],"stdout"=>"output.txt"},21]);#35
  tester(\&decodeCommand,"'l's '-l' \"-t\" > \"output\".\'txt\'",0,[{"command"=>"ls","input"=>["-l","-t"],"stdout"=>"output.txt"},31]);#36
  tester2(encodeType("10"),"int");#37
  tester2(encodeType("-12"),"int");#38
  tester2(encodeType("1.1"),"double");#39
  tester2(encodeType("-1.2"),"double");#40
  tester2(encodeType("whale.txt"),"File");#41
  tester2(encodeType("Hello World"),"string");#42
  #https://www.commonwl.org/user_guide/02-1st-example/index.html
  my $command=decoder("echo 'Hello World!'");
  my ($lines,$inputs)=encoder($command);
  tester2($command,{"command"=>"echo","input"=>["Hello World!"]});#43
  tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","outputs: []"]);#44
  tester2($inputs,{"input1"=>{"type"=>"string","value"=>"Hello World!"}});#45
  #https://www.commonwl.org/user_guide/03-input/index.html
  $command=decoder("echo -f -i42 --example-string hello --file=whale.txt");
  tester2($command,{"command"=>"echo","input"=>["-f","-i42","--example-string","hello","--file=whale.txt"]});#46
  ($lines,$inputs)=encoder($command);
  tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  input1:","    type: boolean","    inputBinding:","      position: 1","      prefix: -f","  input2:","    type: int","    inputBinding:","      position: 2","      prefix: -i","      separate: false","  input3:","    type: string","    inputBinding:","      position: 3","      prefix: --example-string","  input4:","    type: File","    inputBinding:","      position: 4","      prefix: --file=","      separate: false","outputs: []"]);#47
  tester2($inputs,{"input1"=>{"type"=>"boolean","value"=>"true"},"input2"=>{"type"=>"int","value"=>"42"},"input3"=>{"type"=>"string","value"=>"hello"},"input4"=>{"type"=>"File","value"=>"whale.txt"}});#48
  #https://www.commonwl.org/user_guide/04-output/index.html
  $command=decoder("tar --extract --file hello.tar");
  push(@{$command->{"output"}},"hello.txt");
  push(@{$command->{"options"}},"extract","file:");
  tester2($command,{"command"=>"tar","input"=>["--extract","--file","hello.tar"],"output"=>["hello.txt"],"options"=>["extract","file:"]});#49
  $command->{"command"}=[$command->{"command"},shift(@{$command->{"input"}})];
  tester2($command,{"command"=>["tar","--extract"],"input"=>["--file","hello.tar"],"output"=>["hello.txt"],"options"=>["extract","file:"]});#50
  ($lines,$inputs)=encoder($command);
  tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: [tar, --extract]","inputs:","  input1:","    type: File","    inputBinding:","      position: 1","      prefix: --file","outputs:","  output1:","    type: File","    outputBinding:","      glob: hello.txt"]);#51
  tester2($inputs,{"input1"=>{"type"=>"File","value"=>"hello.tar"}});#52
  #https://www.commonwl.org/user_guide/05-stdout/index.html
  $command=decoder("echo 'Hello World!' > output.txt");
  tester2($command,{"command"=>"echo","input"=>["Hello World!"],"stdout"=>"output.txt"});#53
  ($lines,$inputs)=encoder($command);
  #tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","outputs:","  output1:","    type: stdout","stdout: output.txt"]);#54
  #tester2($inputs,{"input1"=>{"type"=>"string","value"=>"Hello World!"}});#55
  tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","  input2:","    type: string","outputs:","  output1:","    type: stdout","stdout: \$(inputs.input2)"]);#54
  tester2($inputs,{"input1"=>{"type"=>"string","value"=>"Hello World!"},"input2"=>{"type"=>"string","value"=>"output.txt"}});#55
  #writeCwl("bash.cwl",$lines);#ok
  #writeYml("bash.yml",$inputs);#ok
  #https://www.commonwl.org/user_guide/06-params/index.html
  $command=decoder("tar --extract --file hello.tar goodbye.txt");
  push(@{$command->{"output"}},"goodbye.txt");
  tester2($command,{"command"=>"tar","input"=>["--extract","--file","hello.tar","goodbye.txt"],"output"=>["goodbye.txt"]});#56
  $command->{"command"}=[$command->{"command"},shift(@{$command->{"input"}})];
  $command->{"options"}=["file:"];
  ($lines,$inputs)=encoder($command);
  tester2(encodeType("hello.txt",{"hello.txt"=>1}),"string");#57
  tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: [tar, --extract]","inputs:","  input1:","    type: File","    inputBinding:","      position: 1","      prefix: --file","  input2:","    type: string","    inputBinding:","      position: 2","outputs:","  output1:","    type: File","    outputBinding:","      glob: \$(inputs.input2)"]);#58
  tester2($inputs,{"input1"=>{"type"=>"File","value"=>"hello.tar"},"input2"=>{"type"=>"string","value"=>"goodbye.txt"}});#59
  #https://www.commonwl.org/user_guide/07-containers/index.html
  $command=decoder("node hello.js > output.txt");
  tester2($command,{"command"=>"node","input"=>["hello.js"],"stdout"=>"output.txt"});#60
  $command->{"dockerPull"}="node:slim";
  ($lines,$inputs)=encoder($command);
  tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","hints:","  DockerRequirement:","   dockerPull: node:slim","baseCommand: node","inputs:","  input1:","    type: File","    inputBinding:","      position: 1","  input2:","    type: string","outputs:","  output1:","    type: stdout","stdout: \$(inputs.input2)"]);#61
  tester2($inputs,{"input1"=>{"type"=>"File","value"=>"hello.js"},"input2"=>{"type"=>"string","value"=>"output.txt"}});#62
  #https://www.commonwl.org/user_guide/08-arguments/index.html
  $command=decoder("javac Hello.java");
  push(@{$command->{"output"}},"*.class");
  tester2($command,{"command"=>"javac","input"=>["Hello.java"],"output"=>["*.class"]});#63
  $command->{"label"}="Example trivial wrapper for Java 9 compiler";
  $command->{"dockerPull"}="openjdk:9.0.1-11-slim";
  $command->{"arguments"}=["-d","\$(runtime.outdir)"];
  ($lines,$inputs)=encoder($command);
  #writeCwl("bash.cwl",$lines);
  #writeYml("bash.yml",$inputs);
  tester2($inputs,{"input1"=>{"type"=>"File","value"=>"Hello.java"}});#64
  tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","label: Example trivial wrapper for Java 9 compiler","hints:","  DockerRequirement:","   dockerPull: openjdk:9.0.1-11-slim","baseCommand: javac","arguments: [\"-d\",\$(runtime.outdir)]","inputs:","  input1:","    type: File","    inputBinding:","      position: 1","outputs:","  output1:","    type:","      type: array","      items: File","    outputBinding:","      glob: \"*.class\""]);#65
  #https://www.commonwl.org/user_guide/09-array-inputs/index.html
  tester2(encodeTypeArray(["one","two","three"]),"string[]");#66
  tester2(encodeTypeArray([1,2,3]),"int[]");#67
  tester2(encodeTypeArray([1.1,2.2,3.3]),"double[]");#68
  tester2(encodeTypeArray(["one.txt","two.txt","three.txt"]),"File[]");#69
  tester2(encodeTypeArray(["one",2,3]),"string[]");#70
  tester2(encodeTypeArray([1.1,2,3]),"double[]");#71
  $command=decoder("echo -A=one,two,three -B four,five,six>out/output.txt");
  push(@{$command->{"input"}},["seven","eight","nine"]);
  tester2($command,{"command"=>"echo","input"=>["-A=one,two,three","-B","four,five,six",["seven","eight","nine"]],"stdout"=>"out/output.txt"});#72
  ($lines,$inputs)=encoder($command);
  tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  input1:","    type: string[]","    inputBinding:","      position: 1","      prefix: -A=","      separate: false","      itemSeparator: \",\"","  input2:","    type: string[]","    inputBinding:","      position: 2","      prefix: -B","      itemSeparator: \",\"","  input3:","    type: string[]","    inputBinding:","      position: 3","  input4:","    type: string","outputs:","  output1:","    type: stdout","stdout: \$(inputs.input4)"]);#73
  tester2($inputs,{"input1"=>{"type"=>"string[]","value"=>"[one,two,three]"},"input2"=>{"type"=>"string[]","value"=>"[four,five,six]"},"input3"=>{"type"=>"string[]","value"=>"[seven,eight,nine]"},"input4"=>{"type"=>"string","value"=>"out/output.txt"}});#74
  #writeCwl("bash.cwl",$lines);
  #writeYml("bash.yml",$inputs);
  #https://github.com/pitagora-galaxy/cwl/wiki/CWL-Start-Guide-JP
  my @commands=decoder("grep one < mock.txt | wc -l > wcount.txt");
  tester2(\@commands,[{"command"=>"grep","input"=>["one"],"stdin"=>"mock.txt","stdout"=>"\$stdout1"},{"command"=>"wc","input"=>["-l"],"stdin"=>"\$stdout1","stdout"=>"wcount.txt"}]);#75
  ($lines,$inputs)=encoder($commands[0]);
  tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: grep","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","  input2:","    type: File","    streamable: true","  input3:","    type: string","outputs:","  output1:","    type: stdout","stdin: \$(inputs.input2.path)","stdout: \$(inputs.input3)",]);#76
  tester2($inputs,{"input1"=>{"type"=>"string","value"=>"one"},"input2"=>{"type"=>"File","value"=>"mock.txt"},"input3"=>{"type"=>"string","value"=>"\$stdout1"}});#77
  #writeCwl("bash.cwl",$lines);
  #writeYml("bash.yml",$inputs);
  ($lines,$inputs)=encoder($commands[1]);
  tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: wc","inputs:","  input1:","    type: boolean","    inputBinding:","      position: 1","      prefix: -l","  input2:","    type: File","    streamable: true","  input3:","    type: string","outputs:","  output1:","    type: stdout","stdin: \$(inputs.input2.path)","stdout: \$(inputs.input3)"]);#78
  tester2($inputs,{"input1"=>{"type"=>"boolean","value"=>"true"},"input2"=>{"type"=>"File","value"=>"\$stdin1"},"input3"=>{"type"=>"string","value"=>"wcount.txt"}});#79
  #writeCwl("bash.cwl",$lines);
  #writeYml("bash.yml",$inputs);
  my $files=workflow(\@commands,"mock.txt","wcount.txt");
  tester2($files->{"cwl/step1.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: grep","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","  input2:","    type: File","    streamable: true","  input3:","    type: string","outputs:","  output1:","    type: stdout","stdin: \$(inputs.input2.path)","stdout: \$(inputs.input3)",]);#80
  tester2($files->{"cwl/step2.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: wc","inputs:","  input1:","    type: boolean","    inputBinding:","      position: 1","      prefix: -l","  input2:","    type: File","    streamable: true","  input3:","    type: string","outputs:","  output1:","    type: stdout","stdin: \$(inputs.input2.path)","stdout: \$(inputs.input3)"]);#81
  tester2($files->{"workflow.cwl"},["cwlVersion: v1.0","class: Workflow","inputs:","  param1:","    type: string","  param2:","    type: File","  param3:","    type: string","  param4:","    type: boolean","  param5:","    type: string","outputs:","  result1:","    type: File","    outputSource: step2/output1","steps:","  step1:","    run: cwl/step1.cwl","    in:","      input1: param1","      input2: param2","      input3: param3","    out: [output1]","  step2:","    run: cwl/step2.cwl","    in:","      input1: param4","      input2: step1/output1","      input3: param5","    out: [output1]"]);#82
  tester2($files->{"workflow.yml"},{"param1"=>{"type"=>"string","value"=>"one"},"param2"=>{"type"=>"File","value"=>"mock.txt"},"param3"=>{"type"=>"string","value"=>"\$stdout1"},"param4"=>{"type"=>"boolean","value"=>"true"},"param5"=>{"type"=>"string","value"=>"wcount.txt"}});#83
  writeWorkflow($files);#ok
  # Connecting two command lines with tmp.txt
  @commands=decoder("  grep  one  <  mock.txt  >  tmp.txt  ","   wc   -l   tmp.txt>wcount.txt   ","#{\"options\":\"-l\"}");
  tester2(\@commands,[{"command"=>"grep","input"=>["one"],"stdin"=>"mock.txt","stdout"=>"tmp.txt"},{"command"=>"wc","input"=>["-l","tmp.txt"],"stdout"=>"wcount.txt","options"=>"-l"}]);#84
  my $files=workflow(\@commands,"mock.txt","wcount.txt");
  tester2($files->{"cwl/step1.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: grep","inputs:","  input1:","    type: string","    inputBinding:","      position: 1","  input2:","    type: File","    streamable: true","  input3:","    type: string","outputs:","  output1:","    type: stdout","stdin: \$(inputs.input2.path)","stdout: \$(inputs.input3)",]);#85
  tester2($files->{"cwl/step2.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: wc","inputs:","  input1:","    type: boolean","    inputBinding:","      position: 1","      prefix: -l","  input2:","    type: File","    inputBinding:","      position: 2","  input3:","    type: string","outputs:","  output1:","    type: stdout","stdout: \$(inputs.input3)"]);#86
  tester2($files->{"workflow.cwl"},["cwlVersion: v1.0","class: Workflow","inputs:","  param1:","    type: string","  param2:","    type: File","  param3:","    type: string","  param4:","    type: boolean","  param5:","    type: string","outputs:","  result1:","    type: File","    outputSource: step2/output1","steps:","  step1:","    run: cwl/step1.cwl","    in:","      input1: param1","      input2: param2","      input3: param3","    out: [output1]","  step2:","    run: cwl/step2.cwl","    in:","      input1: param4","      input2: step1/output1","      input3: param5","    out: [output1]"]);#87
  tester2($files->{"workflow.yml"},{"param1"=>{"type"=>"string","value"=>"one"},"param2"=>{"type"=>"File","value"=>"mock.txt"},"param3"=>{"type"=>"string","value"=>"tmp.txt"},"param4"=>{"type"=>"boolean","value"=>"true"},"param5"=>{"type"=>"string","value"=>"wcount.txt"}});#88
  #writeWorkflow($files);#ok
  #Testing "joinargs" and "options" specified by comment json
  tester2(decodeJson("[]"),[]);#89
  tester2(decodeJson("{}"),{});#90
  tester2(decodeJson("[\"A\",\"B\"]"),["A","B"]);#91
  tester2(decodeJson("{\"A\":\"B\"}"),{"A"=>"B"});#92
  tester2(decodeJson("{\"A\":[\"B\",\"C\"]}"),{"A"=>["B","C"]});#93
  tester2(decodeJson("[{\"A\":\"B\"},{\"C\":\"D\"}]"),[{"A"=>"B"},{"C"=>"D"}]);#94
  tester2(decodeJson("[\"Akira\"]"),["Akira"]);#95
  tester2(decodeJson("{'A':{'B':{'C':['D','E','F']}}}"),{"A"=>{"B"=>{"C"=>["D","E","F"]}}});#96
  tester2(decodeJson("{\"A\":\"B\",\"C\":\"D\"}"),{"A"=>"B","C"=>"D"});#97
  tester2(decodeJson("{\"A\":\"B\",\"C\":{\"D\":\"E\"},\"F\":\"G\"}"),{"A"=>"B","C"=>{"D"=>"E"},"F"=>"G"});#98
  tester2(decodeJson("[\"A\",\"B\",[\"C\",\"D\"]]"),["A","B",["C","D"]]);#99
  tester2(decodeJson("\"Akira Hasegawa\""),"Akira Hasegawa");#100
  my @commands=decoder("javac Hello.java World.java","#{\"arguments\":[\"-d\",\"\$(runtime.outdir)\"],\"output\":[\"*.class\"],\"options\":[\"deprecation\",\"classpath:\"],\"joinargs\":true}");
  tester2($commands[0],{ "command"=>"javac","input"=>["Hello.java","World.java"],"output"=>["*.class"],"arguments"=>["-d","\$(runtime.outdir)"],"options"=>["deprecation","classpath:"],"joinargs"=>"true"});#101
  ($lines,$inputs)=encoder($commands[0]);
  tester2($lines,["cwlVersion: v1.0","class: CommandLineTool","baseCommand: javac","arguments: [\"-d\",\$(runtime.outdir)]","inputs:","  input1:","    type: File[]","    inputBinding:","      position: 1","outputs:","  output1:","    type:","      type: array","      items: File","    outputBinding:","      glob: \"*.class\""]);#102
  tester2($inputs,{"input1"=>{"type"=>"File[]","value"=>[{"class"=>"File","path"=>"Hello.java"},{"class"=>"File","path"=>"World.java"}]}});#103
  $files=workflow(\@commands);
  tester2($files->{"workflow.yml"},{"param1"=>{"type"=>"File[]","value"=>[{"class"=>"File","path"=>"Hello.java"},{"class"=>"File","path"=>"World.java"}]}});#104
  tester2($files->{"workflow.cwl"},["cwlVersion: v1.0","class: Workflow","inputs:","  param1:","    type: File[]","outputs:","  result1:","    type: File[]","    outputSource: step1/output1","steps:","  step1:","    run: cwl/step1.cwl","    in:","      input1: param1","    out: [output1]"]);#105
  tester2($files->{"cwl/step1.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: javac","arguments: [\"-d\",\$(runtime.outdir)]","inputs:","  input1:","    type: File[]","    inputBinding:","      position: 1","outputs:","  output1:","    type:","      type: array","      items: File","    outputBinding:","      glob: \"*.class\""]);#106
  #https://www.commonwl.org/user_guide/10-array-outputs/index.html
  @commands=decoder("touch Hello.java World.java","#{\"joinargs\":\"true\",\"output\":[\"*.txt\"]}");
  $files=workflow(\@commands);
  tester2($files->{"workflow.yml"},{"param1"=>{"type"=>"File[]","value"=>[{"class"=>"File","path"=>"Hello.java"},{"class"=>"File","path"=>"World.java"}]}});#107
  tester2($files->{"workflow.cwl"},["cwlVersion: v1.0","class: Workflow","inputs:","  param1:","    type: File[]","outputs:","  result1:","    type: File[]","    outputSource: step1/output1","steps:","  step1:","    run: cwl/step1.cwl","    in:","      input1: param1","    out: [output1]"]);#108
  tester2($files->{"cwl/step1.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: touch","inputs:","  input1:","    type: File[]","    inputBinding:","      position: 1","outputs:","  output1:","    type:","      type: array","      items: File","    outputBinding:","      glob: \"*.txt\""]);#109
  #https://www.commonwl.org/user_guide/11-records/index.html
  @commands=decoder("echo -A one -B -C -D two -E etc > output.txt","#{\"dependent\":[[\"-A\",\"-B\"],[\"-C\",\"-D\"]],\"exclusive\":[[\"-E\",\"-F\"]]}");
  $files=workflow(\@commands);
  tester2($files->{"cwl/step1.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: echo","inputs:","  inclusive0:","    type:","      - type: record","        fields:","          input1:","            type: string","            inputBinding:","              position: 1","              prefix: -A","          input2:","            type: boolean","            inputBinding:","              position: 2","              prefix: -B","  inclusive1:","    type:","      - type: record","        fields:","          input3:","            type: boolean","            inputBinding:","              position: 3","              prefix: -C","          input4:","            type: string","            inputBinding:","              position: 4","              prefix: -D","  exclusive:","    type:","      type: record","      fields:","        input5:","          type: string","          inputBinding:","            position: 5","            prefix: -E","  input6:","    type: string","outputs:","  output1:","    type: stdout","stdout: \$(inputs.input6)"]);#110
  tester2($files->{"workflow.cwl"},["cwlVersion: v1.0","class: Workflow","inputs:","  param1:","    type: string","  param2:","    type: boolean","  param3:","    type: boolean","  param4:","    type: string","  param5:","    type: string","  param6:","    type: string","outputs: []","steps:","  step1:","    run: cwl/step1.cwl","    in:","      input1: param1","      input2: param2","      input3: param3","      input4: param4","      input5: param5","      input6: param6","    out: [output1]"]);#111
  tester2($files->{"workflow.yml"},{"param1"=>{"type"=>"string","value"=>"one"},"param2"=>{"type"=>"boolean","value"=>"true"},"param3"=>{"type"=>"boolean","value"=>"true"},"param4"=>{"type"=>"string","value"=>"two"},"param5"=>{"type"=>"string","value"=>"etc"},"param6"=>{"type"=>"string","value"=>"output.txt"}});#112
  #https://www.commonwl.org/user_guide/12-env/index.html
  @commands=decoder("export FIRST=AKIRA","export LAST=HASEGAWA","env>env.txt");
  tester2(\@commands,[{"command"=>"export","input"=>["FIRST=AKIRA"]},{"command"=>"export","input"=>["LAST=HASEGAWA"]},{"command"=>"env","stdout"=>"env.txt"}]);#113
  $files=workflow(\@commands,undef,"env.txt");
  tester2($files->{"workflow.cwl"},["cwlVersion: v1.0","class: Workflow","inputs:","  param1:","    type: string","outputs:","  result1:","    type: File","    outputSource: step1/output1","steps:","  step1:","    run: cwl/step1.cwl","    in:","      input1: param1","    out: [output1]"]);#114
  tester2($files->{"cwl/step1.cwl"},["cwlVersion: v1.0","class: CommandLineTool","baseCommand: env","requirements:","  EnvVarRequirement:","    envDef:","      FIRST: AKIRA","      LAST: HASEGAWA","inputs:","  input1:","    type: string","outputs:","  output1:","    type: stdout","stdout: \$(inputs.input1)"]);#115
  #writeWorkflow($files);
  #assign
  @commands=decoder("output='Hello World'","echo \$output");
  tester2(\@commands,[{"command"=>"_assign_","name"=>"output","value"=>"Hello World"},{"command"=>"echo","input"=>["\$output"]}]);#116
  $files=workflow(\@commands);
  writeWorkflow($files);

  #@commands=decoder("output=`echo 'hello world'`","echo \$output");
  #tester2(\@commands,[{"command"=>"_nested_","name"=>"output","value"=>[{"command"=>"echo","input"=>["hello world"]}]},{"command"=>"echo","input"=>["\$output"]}]);#117
  #$files=workflow(\@commands);
  #writeWorkflow($files);
  #https://www.commonwl.org/user_guide/13-expressions/index.html
  #https://www.commonwl.org/user_guide/14-runtime/index.html
  #https://www.commonwl.org/user_guide/15-staging/index.html
  #https://www.commonwl.org/user_guide/16-file-formats/index.html
  #https://www.commonwl.org/user_guide/17-metadata/index.html
  #https://www.commonwl.org/user_guide/19-custom-types/index.html
  #https://www.commonwl.org/user_guide/20-software-requirements/index.html
  #https://www.commonwl.org/user_guide/21-1st-workflow/index.html
  #https://www.commonwl.org/user_guide/22-nested-workflows/index.html
  #https://www.commonwl.org/user_guide/23-scatter-workflow/index.html
  #    fq:
  #      source: [fastq]
  #      linkMerge: merge_flattened
  #conformance test
  #
  # noguchi - intergenic genomic contamination
  # melissa - unmapped
  # imad - QC pipeline
  #writeCwl("bash.cwl",$lines);
  #writeYml("bash.yml",$inputs);
  #writeWorkflow($files);
}
############################## showWorkflow ##############################
sub showWorkflow{
  my $results=shift();
  my $files=$results->{"files"};
  my $directory=$results->{"directory"};
  my $inputs=$results->{"inputs"};
  my $command=$results->{"command"};
  if(!defined($inputs)){$inputs=[];}
  print STDERR "\nfiles:\n";
  foreach my $file(sort{$a cmp $b}@{$files}){print STDERR "  $file\n";}
  if($directory ne "."){
    my @linked=();
    foreach my $input(@{$inputs}){
      my $basename=basename($input);
      if(-e "$directory/$basename"){next;}
      my $fullpath=absolute_path($input);
      my $command="ln -s $fullpath $directory/.";
      system($command);
      push(@linked,"$directory/$basename");
    }
    if(scalar(@linked)>0){
      print STDERR "\nlinked:\n";
      foreach my $link(@linked){print STDERR "  $link\n";}
    }
  }
  print STDERR "\ncommand: $command\n";
}
############################## runWorkflow ##############################
sub runWorkflow{
  my $results=shift();
  my $command=$results->{"command"};
  print STDERR "\nRun [y/n] ?";
  my $prompt=<STDIN>;
  chomp($prompt);
  if($prompt ne "y"&&$prompt ne "yes"&&$prompt ne "Y"&&$prompt ne "YES"){return;}
  system($command);
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
    foreach my $file(@{$command->{"input"}}){
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
  my $files={};
  my $tmps={};
  my $exports={};
  my $variables={};
  my $stepindex=1;
  foreach my $command(@{$commands}){
    if($command->{"command"}eq"export"){
      foreach my $input(@{$command->{"input"}}){if($input=~/(\S+)\=(\S+)/){$exports->{$1}=$2;}}
      next;
    }
    my $basename="step$stepindex";
    push(@steps,$basename);
    if($command->{"command"}eq"_nested_"){
      $stepindex=workflowNested($command,$stepindex);
    }
    if($command->{"command"}eq"_assign_"){
      $variables->{"\$".$command->{"name"}}=$command->{"value"};
    }
    my ($lines,$ins,$outs)=encoder($command,$exports,$variables,$stepindex);
    $files->{"cwl/$basename.cwl"}=$lines;
    my @keys=sort{$a cmp $b}keys(%{$ins});
    foreach my $key(@keys){
      my $hash=$ins->{$key};
      my $value=$hash->{"value"};
      my $type=$hash->{"type"};
      if(!exists($inputs->{$basename})){$inputs->{$basename}={};}
      if($value=~/^\$/ && exists($variables->{$value})){$inputs->{$basename}->{$key}=$variables->{$value};next;}
      if(($type eq"File"||$type eq"stdin")&&!exists($inputHash->{$value})){
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
      my $name="result$outputindex";
      if($value=~/^\$stdout(\d+)/){$variables->{"\$stdin".($1+1)}="$basename/output$outputindex";}
      $outputs->{$basename}->{$key}=$value;
      $tmps->{$value}="$basename/$key";
      if(($type eq"File"||$type eq"stdout")&&!exists($outputHash->{$value})){next;}
      if($type eq "stdout"){$type="File";}
      push(@outputLines,"  $name:");
      push(@outputLines,"    type: $type");
      push(@outputLines,"    outputSource: $basename/$key");
      $outputindex++;
    }
    while(my($name,$hash)=each(%{$outs})){
      my $value=$hash->{"value"};
      if($value=~/^\$stdout(\d+)/){$variables->{$value}="$basename/$name";}
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
  if(scalar(@steps)>0){
    push(@lines,"steps:");
    my $stepIndex=1;
    foreach my $step(@steps){
      push(@lines,"  step$stepIndex:");
      push(@lines,"    run: cwl/$step.cwl");
      my @keys=sort{$a cmp $b}keys(%{$inputs->{$step}});
      if(scalar(@keys)>0){
        push(@lines,"    in:");
        foreach my $key(@keys){push(@lines,"      $key: ".$inputs->{$step}->{$key});}
      }else{
        push(@lines,"    in: []");
      }
      @keys=sort{$a cmp $b}keys(%{$outputs->{$step}});
      push(@lines,"    out: [".join(", ",@keys)."]");
      $stepIndex++;
    }
  }else{push(@lines,"steps: []");}
  $files->{"workflow.cwl"}=\@lines;
  $files->{"workflow.yml"}=$parameters;
  return $files;
}
############################## workflowNested ##############################
sub workflowNested{
  my $command=shift();
  my $stepindex=shift();
  my $name=$command->{"name"};
  my $value=$command->{"value"};
  return $stepindex;
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
  my @keys=keys(%{$hash});
  if(scalar(@keys)==0){
    print OUT "{}";
  }else{
    foreach my $key(sort{$a cmp $b}@keys){
      my $h=$hash->{$key};
      my $type=$h->{"type"};
      my $value=$h->{"value"};
      if($type eq "File"){
        print OUT "$key:\n";
        print OUT "  class: $type\n";
        if($value=~/^\$stdin(\d+)/){print OUT "  path: stdin$1.txt\n";}
        else{print OUT "  path: $value\n";}
      }elsif($type eq "File[]"){
        #https://www.biostars.org/p/303663/
        print OUT "$key: [\n";
        for(my $i=0;$i<scalar(@{$value});$i++){
          my $h=$value->[$i];
          print OUT "  {class: ".$h->{"class"}.", path: ".$h->{"path"}."}";
          if($i+1<scalar(@{$value})){print OUT ",";}
          print OUT "\n";
        }
        print OUT "]\n";
      }elsif($value=~/^\$stdout(\d+)/){
        print OUT "$key: stdout$1.txt\n";
      }else{
        print OUT "$key: $value\n";
      }
    }
  }
  close(OUT);
}
############################## writeWorkflow ##############################
sub writeWorkflow{
  my $files=shift();
  my $basename=shift();
  my $directory=shift();
  my $showFiles=shift();
  if(!defined($basename)){$basename="bash";}
  if(!defined($directory)){$directory=".";}
  my $cwlFile;
  my $ymlFile;
  mkdir($directory);
  mkdir("$directory/cwl");
  my @files=();
  while(my($filename,$data)=each(%{$files})){
    if($filename eq "workflow.cwl"){
      $cwlFile=($directory eq".")?"$basename.cwl":"$directory/$basename.cwl";
      writeCwl($cwlFile,$data);
    }elsif($filename eq "workflow.yml"){
      $ymlFile=($directory eq".")?"$basename.yml":"$directory/$basename.yml";
      writeYml($ymlFile,$data);
    }else{
      my $file=($directory eq".")?$filename:"$directory/$filename";
      writeCwl($file,$data);
      push(@files,$file);
    }
  }
  push(@files,$ymlFile);
  push(@files,$cwlFile);
  my $command="cwltool $cwlFile $ymlFile";
  my $results={};
  $results->{"directory"}=$directory;
  $results->{"basename"}=$basename;
  $results->{"files"}=\@files;
  $results->{"command"}=$command;
  return $results;
}
############################## encoder ##############################
sub encoder{
  my $command=shift();
  my $exports=shift();
  my $variables=shift();
  my $stepindex=shift();
  if(!defined($stepindex)){$stepindex=1;}
  my $base=$command->{"command"};
  my @lines=();
  push(@lines,"cwlVersion: v1.0");
  push(@lines,"class: CommandLineTool");
  if(exists($command->{"label"})){push(@lines,"label: ".$command->{"label"});}
  if(exists($command->{"dockerPull"})){
    push(@lines,"hints:");
    push(@lines,"  DockerRequirement:");
    push(@lines,"   dockerPull: ".$command->{"dockerPull"});
  }
  if(ref($base)eq"ARRAY"){push(@lines,"baseCommand: [".join(", ",@{$base})."]");}
  else{push(@lines,"baseCommand: $base");}
  my @requirements=();
  if(scalar(keys(%{$exports}))>0){
    push(@requirements,"  EnvVarRequirement:");
    push(@requirements,"    envDef:");
    foreach my $key(sort{$a cmp $b}keys(%{$exports})){push(@requirements,"      $key: ".$exports->{$key});}
  }
  if(scalar(@requirements)>0){
    push(@lines,"requirements:");
    foreach my $line(@requirements){push(@lines,$line);}
  }
  if(exists($command->{"arguments"})){
    my $line="arguments: [";
    my $index=0;
    foreach my $argument(@{$command->{"arguments"}}){
      if($index>0){$line.=",";}
      if($argument=~/^\$\(\S+\)$/){$line.=$argument;}
      else{$line.="\"$argument\"";}
      $index++;
    }
    $line.="]";
    push(@lines,$line);
  }
  my ($inputLines,$inputs)=encodeInput($command);
  my $stdoutLine;
  if(exists($command->{"stdout"})){
    my $position=scalar(keys(%{$inputs}))+1;
    my $key="input$position";
    $inputs->{$key}->{"type"}="string";
    if($command->{"stdout"}=~/^\$/){
      $inputs->{$key}->{"value"}="\$stdout$stepindex";
      $stdoutLine="stdout: \$(inputs.$key)";
      push(@{$inputLines},"  $key:");
      push(@{$inputLines},"    type: string");
    }else{
      $inputs->{$key}->{"value"}=$command->{"stdout"};
      $stdoutLine="stdout: \$(inputs.$key)";
      push(@{$inputLines},"  $key:");
      push(@{$inputLines},"    type: string");
    }
  }
  if(scalar(@{$inputLines})>0){push(@lines,"inputs:");push(@lines,@{$inputLines});}
  else{push(@lines,"inputs: []");}
  my ($outputLines,$outputs)=encodeOutput($command,$inputs);
  push(@lines,@{$outputLines});
  if(exists($command->{"stdin"})){
    my $stdin=$command->{"stdin"};
    while(my($key,$val)=each(%{$inputs})){
      if($val->{"type"}ne"File"){next;}
      if($stdin ne $val->{"value"}){next;}
      if($val->{"value"}=~/^\$/){$inputs->{$key}->{"value"}="\$stdin$stepindex";}
      push(@lines,"stdin: \$(inputs.$key.path)");
    }
  }
  if(defined($stdoutLine)){push(@lines,$stdoutLine);}
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
  if(exists($command->{"output"})){
    my $hash={};
    while(my ($k,$v)=each(%{$args})){$hash->{$v->{"value"}}="\$(inputs.$k)";}
    foreach my $output(@{$command->{"output"}}){
      if(exists($hash->{$output})){$inouts->{$output}=$hash->{$output}}
    }
  }
  if(exists($command->{"output"})){
    if($index==1){push(@lines,"outputs:");}
    foreach my $output(@{$command->{"output"}}){
      my $value=$output;
      if(exists($inouts->{$output})){$value=$inouts->{$output};}
      my $name="output$index";
      $outputs->{$name}={};
      if($output=~/\*/){
        push(@lines,"  $name:");
        push(@lines,"    type:");
        push(@lines,"      type: array");
        push(@lines,"      items: File");
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
  my @inputs=@{$command->{"input"}};
  my $outputs={};
  if(exists($command->{"output"})){foreach my $output(@{$command->{"output"}}){$outputs->{$output}=1;}}
  my $flags={};
  if(exists($command->{"options"})){
    my $array=$command->{"options"};
    if(ref($array)ne"ARRAY"){$array=[$array];}
    foreach my $option(@{$array}){
      if($option=~/\-*(\S+)\:(\S)$/){$flags->{$1}=$2;}#with delim
      elsif($option=~/\-*(\S+)\:$/){$flags->{$1}=1;}
      elsif($option=~/\-*(\S+)$/){$flags->{$1}=0;}
    }
  }
  #0=argument
  #1=option boolean
  #2=option argument flag
  #3=option argument value
  #4=option argument with '=' (no separation) --file=whale.txt
  #5=optionargument  with '-' (no separation) -i42
  #6=option boolean(1) or argument(2) flag -f
  my @options=();
  for(my $i=0;$i<scalar(@inputs);$i++){
    if($inputs[$i]=~/\=/){$options[$i]=4;}#4
    elsif($inputs[$i]=~/^\-\-([\w_]+)/){
      my $key=$1;
      if(exists($flags->{$key})){
        if($flags->{$key}==0){$options[$i]=1;}#1
        else{$options[$i]=2;$options[$i+1]=3;$i++;}#2+3
      }else{$options[$i]=6;}#1or2
    }elsif($inputs[$i]=~/^\-\w\w+/){$options[$i]=5;}#5
    elsif($inputs[$i]=~/^\-([\w_])/){
      my $key=$1;
      if(exists($flags->{$key})){
        if($flags->{$key}==0){$options[$i]=1;}#1
        else{$options[$i]=2;$options[$i+1]=3;$i++;}#2+3
      }else{$options[$i]=6;}#1or2
    }else{$options[$i]=0;}#0
  }
  my $argstart=scalar(@inputs);
  for(my $i=0;$i<$argstart;$i++){
    if($options[$i]==6){
      if($i+1<$argstart&&$options[$i+1]==0){$options[$i]=2;$options[$i+1]=3;}
      else{$options[$i]=1;}
    }
  }
  for(my $i=$argstart-1;$i>=0;$i--){if($options[$i]==0){$argstart=$i;}else{last;}}
  if(exists($command->{"joinargs"})){my @array=splice(@inputs,$argstart);push(@inputs,\@array);}
  my $binds={};
  if(exists($command->{"dependent"})){my $bindIndex=0;$binds->{"dependent"}={};foreach my $group(@{$command->{"dependent"}}){foreach my $option(@{$group}){$binds->{"dependent"}->{$option}=$bindIndex;}$bindIndex++;}}
  if(exists($command->{"exclusive"})){my $bindIndex=0;$binds->{"exclusive"}={};foreach my $group(@{$command->{"exclusive"}}){foreach my $option(@{$group}){$binds->{"exclusive"}->{$option}=$bindIndex;}$bindIndex++;}}
  my $lines=[];
  $lines->[0]=[];#normal input lines
  $lines->[1]=[];#dependent input lines
  $lines->[2]=[];#exclusive input lines
  my $position=1;
  my $delim=",";
  my $args={};
  for(my $i=0;$i<scalar(@inputs);$i++,$position++){
    if($options[$i]==0){encodeInputSub($position,undef,$inputs[$i],$delim,$lines,$args,$outputs,$binds);}
    elsif($options[$i]==1){encodeInputSub($position,$inputs[$i],undef,$delim,$lines,$args,$outputs,$binds);}
    elsif($options[$i]==2&&$options[$i+1]==3){encodeInputSub($position,$inputs[$i],$inputs[$i+1],$delim,$lines,$args,$outputs,$binds);$i++;}
    elsif($options[$i]==4){my ($prefix,$value)=split(/\=/,$inputs[$i],2);encodeInputSub($position,"$prefix=",$value,$delim,$lines,$args,$outputs,$binds,1);}
    elsif($options[$i]==5){if($inputs[$i]=~/^(\-\w)(\w+)$/){encodeInputSub($position,$1,$2,$delim,$lines,$args,$outputs,$binds,1);}}
  }
  if(exists($command->{"stdin"})){
    my $type="File";
    push(@{$lines->[0]},"  input$position:");
    push(@{$lines->[0]},"    type: $type");
    push(@{$lines->[0]},"    streamable: true");
    $args->{"input$position"}=encodeValue($type,$command->{"stdin"});
    $position++;
  }
  my @temps=();
  if(scalar(@{$lines->[1]})>0){
    if(scalar(@{$lines->[1]})>1){
      for(my $i=0;$i<scalar(@{$lines->[1]});$i++){
        push(@temps,"  inclusive$i:");
        push(@temps,"    type:");
        push(@temps,"      - type: record");
        for(my $j=0;$j<scalar(@{$lines->[1]->[$i]});$j++){push(@temps,"  ".$lines->[1]->[$i]->[$j]);}
      }
    }else{
      push(@temps,"      type: record");
      push(@temps,@{$lines->[1]->[0]});
    }
  }
  if(scalar(@{$lines->[2]})>0){
    push(@temps,"  exclusive:");
    push(@temps,"    type:");
    if(scalar(@{$lines->[2]})>1){
      for(my $i=0;$i<scalar(@{$lines->[2]});$i++){
        push(@temps,"      - type: record");
        for(my $j=0;$j<scalar(@{$lines->[2]->[$i]});$j++){push(@temps,"  ".$lines->[2]->[$i]->[$j]);}
      }
    }else{
      push(@temps,"      type: record");
      push(@temps,@{$lines->[2]->[0]});
    }
  }
  if(scalar(@{$lines->[0]})){push(@temps,@{$lines->[0]})}
  return (\@temps,$args);
}
sub encodeInputSub{
  my $position=shift();
  my $prefix=shift();
  my $value=shift();
  my $delim=shift();
  my $lines=shift();
  my $args=shift();
  my $outputs=shift();
  my $groups=shift();
  my $nonseparate=shift();
  my $indent="";
  my $pointer=$lines->[0];
  if(exists($groups->{"dependent"}->{$prefix})){
    my $index=$groups->{"dependent"}->{$prefix};
    if(!defined($lines->[1]->[$index])){$lines->[1]->[$index]=[];}
    $pointer=$lines->[1]->[$index];
    if(scalar(@{$pointer})==0){push(@{$pointer},"      fields:");}
    $indent="      ";
  }
  if(exists($groups->{"exclusive"}->{$prefix})){
    my $index=$groups->{"exclusive"}->{$prefix};
    if(!defined($lines->[2]->[$index])){$lines->[2]->[$index]=[];}
    $pointer=$lines->[2]->[$index];
    if(scalar(@{$pointer})==0){push(@{$pointer},"      fields:");}
    $indent="      ";
  }
  if(defined($value)){
    my $itemSeparator=($value=~/$delim/)?$delim:undef;
    my $type=encodeType($value,$outputs,$itemSeparator);
    push(@{$pointer},"$indent  input$position:");
    push(@{$pointer},"$indent    type: $type");
    push(@{$pointer},"$indent    inputBinding:");
    push(@{$pointer},"$indent      position: $position");
    if(defined($prefix)){push(@{$pointer},"$indent      prefix: $prefix");}
    if($nonseparate==1){push(@{$pointer},"$indent      separate: false");}
    if(defined($itemSeparator)){push(@{$pointer},"$indent      itemSeparator: \"$itemSeparator\"");}
    $args->{"input$position"}=encodeValue($type,$value);
  }else{
    my $type="boolean";
    push(@{$pointer},"$indent  input$position:");
    push(@{$pointer},"$indent    type: $type");
    push(@{$pointer},"$indent    inputBinding:");
    push(@{$pointer},"$indent      position: $position");
    push(@{$pointer},"$indent      prefix: ".$prefix);
    $args->{"input$position"}=encodeValue($type,"true");
  }
}

############################## encodeType ##############################
# string, int, long, float, double, and null, array, record, File, Directory
sub encodeType{
  my $argument=shift();
  my $outputs=shift();
  my $delim=shift();
  if(!defined($delim)){$delim=",";}
  if(ref($argument)eq"ARRAY"){return encodeTypeArray($argument,$outputs);}
  elsif($argument=~/$delim/){my @temp=split(/$delim/,$argument);return encodeTypeArray(\@temp,$outputs);}
  else{return encodeTypeSub($argument,$outputs);}
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
  if($type=~/File\[\]/){
    my @array=();
    for(my $i=0;$i<scalar(@{$value});$i++){push(@array,{"class"=>"File","path"=>$value->[$i]});}
    return {"type"=>$type,"value"=>\@array};
  }elsif($type=~/\[\]/){
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
    my $command;
    my $index=0;
    while($index<scalar(@chars)){
      ($command,$index)=decodeCommand(\@chars,$index);
      if(exists($command->{"command"})&&$command->{"command"}eq"_cwl_"){
        my $hash=$command->{"value"};
        if(scalar(@commands)>0){
          my $latest=$commands[scalar(@commands)-1];
          while(my ($key,$val)=each(%{$hash})){
            if(!exists($latest->{$key})){$latest->{$key}=$val;}
            else{
              if(ref($latest->{$key})ne"ARRAY"){$latest->{$key}=[$latest->{$key}];}
              if(ref($val)eq"ARRAY"){push(@{$latest->{$key}},@{$val});}
              else{push(@{$latest->{$key}},$val);}
            }
          }
        }
        next;
      }
      if(defined($piped)){$command->{"stdin"}=$piped;}
      if(exists($command->{"stdout"})&&$command->{"stdout"}eq"\|"){
        $piped="\$stdout".(scalar(@commands)+1);
        $command->{"stdout"}=$piped;
      }else{
        $piped=undef;
      }
      push(@commands,$command);
    }
  }
  return wantarray?@commands:$commands[0];
}
sub decodeCommand{
  my $chars=shift();
  my $index=shift();
  my $value;
  $index=decodeSpace($chars,$index);
  ($value,$index)=decodeComment($chars,$index);
  if(defined($value)){return ({"command"=>"_cwl_","value"=>$value},$index);}
  ($value,$index)=decodeCommandName($chars,$index);
  if($chars->[$index]eq"="){
    $index++;
    my $command={"name"=>$value};
    if($chars->[$index]eq"`"){
      ($value,$index)=decodeBackQuote($chars,$index);
      my @commands=decoder($value);
      $value=\@commands;
      $command->{"command"}="_nested_";
    }else{
      ($value,$index)=decodeCommandToken($chars,$index);
      $command->{"command"}="_assign_";
    }
    $command->{"value"}=$value;
    return ($command,$index);
  }
  my $command={"command"=>$value};
  if($chars->[$index]eq" "){
    ($value,$index)=decodeCommandTokens($chars,$index+1);
    if(scalar(@{$value})>0){$command->{"input"}=$value;}
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
sub decodeComment{
  my $chars=shift();
  my $index=shift();
  $index=decodeSpace($chars,$index);
  if($chars->[$index]ne"#"){return (undef,$index);}
  $index=decodeSpace($chars,$index+1);
  my $value;
  if($chars->[$index]eq"["){($value,$index)=decodeArray($chars,$index);}
  if($chars->[$index]eq"{"){($value,$index)=decodeHash($chars,$index);}
  return ($value,scalar(@{$chars}));
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
    elsif($chars->[$index]eq":"){last;}
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
sub decodeBackQuote{
  my $chars=shift();
  my $index=shift();
  if($chars->[$index]ne"`"){return (undef,$index);}
  my $value;
  for($index++;$index<scalar(@{$chars});$index++){
    if($chars->[$index] eq "`"){if($chars->[$index-1] ne "\\"){last;}}
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
sub decodeArray{
  my $chars=shift();
  my $index=shift();
  my $array=[];
  my $value;
  if($chars->[$index]ne"["){return ($value,$index);}
  $index++;
  my $length=scalar(@{$chars});
  for(;$chars->[$index] ne "]"&&$index<$length;$index++){
    if($chars->[$index] eq "["){($value,$index)=decodeArray($chars,$index);push(@{$array},$value);}
    elsif($chars->[$index] eq "{"){($value,$index)=decodeHash($chars,$index);push(@{$array},$value);}
    elsif($chars->[$index] eq "\""){($value,$index)=decodeDoubleQuote($chars,$index);push(@{$array},$value);}
    elsif($chars->[$index] eq "\'"){($value,$index)=decodeSingleQuote($chars,$index);push(@{$array},$value);}
    if($chars->[$index] eq "]"){$index++;last;}
  }
  return ($array,$index);
}
sub decodeHash{
  my $chars=shift();
  my $index=shift();
  my $hash={};
  my $key;
  my $value;
  if($chars->[$index]ne"{"){return ($value,$index);}
  $index++;
  my $length=scalar(@{$chars});
  for(my $findKey=1;$index<$length;$index++){
    if($chars->[$index] eq "}"){
      if(defined($value)){$hash->{$key}=$value;}
      last;
    }elsif($findKey==1){
      if($value ne ""){$hash->{$key}=$value;$value="";}
      if($chars->[$index] eq ":"){$key=chomp($key);$findKey=0;}
      elsif($chars->[$index] eq "\""){($key,$index)=decodeDoubleQuote($chars,$index);$findKey=0;}
      elsif($chars->[$index] eq "\'"){($key,$index)=decodeSingleQuote($chars,$index);$findKey=0;}
      elsif($chars->[$index]!~/^\s$/){$key.=$chars->[$index];}
    }else{
      if($chars->[$index] eq ":"){next;}
      elsif($chars->[$index] eq ","){$findKey=1;}
      elsif($chars->[$index] eq "["){($value,$index)=decodeArray($chars,$index);$hash->{$key}=$value;$value=undef;}
      elsif($chars->[$index] eq "{"){($value,$index)=decodeHash($chars,$index);$hash->{$key}=$value;$value=undef;}
      elsif($chars->[$index] eq "\""){($value,$index)=decodeDoubleQuote($chars,$index);$hash->{$key}=$value;$value=undef;}
      elsif($chars->[$index] eq "\'"){($value,$index)=decodeSingleQuote($chars,$index);$hash->{$key}=$value;$value=undef;}
      elsif($chars->[$index]!~/^\s$/){$value.=$chars->[$index];}
      if($chars->[$index] eq ","){$findKey=1;next;}
    }
    if($chars->[$index] eq "}"){$index++;last;}
  }
  return ($hash,$index);
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
sub decodeJson{
  my $text=shift();
  my @temp=split(//,$text);
  my $chars=\@temp;
  my $index=0;
  my $value;
  if($chars->[$index] eq "["){($value,$index)=decodeArray($chars,$index);return $value;}
  elsif($chars->[$index] eq "{"){($value,$index)=decodeHash($chars,$index);return $value;}
  elsif($chars->[$index] eq "\""){($value,$index)=decodeDoubleQuote($chars,$index);return $value;}
  elsif($chars->[$index] eq "\'"){($value,$index)=decodeSingleQuote($chars,$index);return $value;}
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
############################## absolute_path ##############################
sub absolute_path {
  my $path      = shift();
  my $directory = dirname( $path );
  my $filename  = basename( $path );
  return Cwd::abs_path( $directory ) . "/" . $filename;
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
