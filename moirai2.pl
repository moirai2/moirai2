#!/usr/bin/perl
use strict 'vars';
use Cwd;
use File::Basename;
use File::Temp qw/tempfile tempdir/;
use FileHandle;
use Getopt::Std;
use Time::localtime;
############################## HEADER ##############################
my ($program_name,$prgdir,$program_suffix)=fileparse($0);
$prgdir=Cwd::abs_path($prgdir);
my $program_path="$prgdir/$program_name";
my $program_version="2022/04/07";
############################## OPTIONS ##############################
use vars qw($opt_a $opt_b $opt_c $opt_d $opt_D $opt_E $opt_f $opt_F $opt_g $opt_G $opt_h $opt_H $opt_i $opt_I $opt_l $opt_m $opt_o $opt_O $opt_p $opt_q $opt_Q $opt_r $opt_s $opt_S $opt_u $opt_v $opt_V $opt_w $opt_x $opt_X $opt_Z);
getopts('a:b:c:d:D:E:f:F:g:G:hHi:I:lm:o:O:pq:Q:r:s:S:uv:V:w:xX:Z:');
############################## HELP ##############################
sub help{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Handles Moirai2 workflow/command using triple database.\n";
	print "Version: $program_version\n";
	print "Author: Akira Hasegawa (akira.hasegawa\@riken.jp)\n";
	print "\n";
	print "Usage: perl $program_name [Options] COMMAND\n";
	print "\n";
	print "Commands:\n";
	print "             build  Build a command json from command lines and script files\n";
	print "       clear/clean  Clean all command log and history by removing .moirai2 directory\n";
	print "           command  Execute user specified command from STDIN\n";
	print "            daemon  Checks and runs the submitted and automated scripts/jobs\n";
	print "              exec  Execute user specified command from ARGUMENTS\n";
	print "              html  Create a HTML representation of triple database\n";
	print "           history  List up executed commands\n";
	print "                ls  Create triples from directories/files and show or store them in triple database\n";
	print "              open  Open .moirai2 directory (for Mac only)\n";
	print "          sortsubs  For reorganizing this script(test commands)\n";
	print "            submit  Submit job with command URL and parameters specified in STDIN\n";
	print "              test  For development purpose (test commands)\n";
	print "\n";
	print "############################## Default Usage ##############################\n";
	print "\n";
	print "Program: Executes command.\n";
	print "\n";
	print "Usage: perl $program_name exec ls -lt\n";
	print "\n";
	if(defined($opt_H)){
		print "############################## Updates ##############################\n";
		print "\n";
		print "2022/03/23  rsync workdir with server to upload/download input/output files\n";
		print "2022/03/22  Modifying PHP and JS scripts to modified system\n";
		print "2022/03/21  Refactoring/simplification of main system\n";
		print "2022/02/02  Separated database directory and .moirai2 ctrl directory\n";
		print "2022/01/04  Work ID is added\n";
		print "2021/11/10  Fixed small bugs\n";
		print "2021/09/30  Refactoring 'ls' command\n";
		print "2021/09/27  Upgrade 'ls' command\n";
		print "2021/09/15  Upload input, download outputs, and rsync directory\n";
		print "2021/09/13  Execute command line with docker/singularity and SGE/slurm\n";
		print "2021/08/28  Execute command line across SSH/SCP\n";
		print "2021/08/25  Modified job completion process\n";
		print "2021/07/06  Add import script functionality when creating json file\n";
		print "2021/05/18  Slurm option added to bashCommand\n";
		print "2021/01/08  Added stdout/stderr error handlers with options.\n";
		print "2021/01/04  Added 'boolean options' to enable options without values.\n";
		print "2020/12/15  'html' command  added to report workflow in HTML format.\n";
		print "2020/12/14  Create and keep json file from user defined command\n";
		print "2020/12/13  'empty output' and 'ignore stderr/stout' functions added.\n";
		print "2020/12/12  stdout and stderr reports are appended to a log file.\n";
		print "2020/12/01  Adapt to new rdf.pl which doens't user sqlite3 database.\n";
		print "2020/11/20  Import and execute workflow bash file.\n";
		print "2020/11/11  Added 'singularity' to container function.\n";
		print "2020/11/06  Updated help and daemon functionality.\n";
		print "2020/11/05  Added 'ls' function to insert file information to the database.\n";
		print "2020/10/09  Repeat functionality has been removed, since loop is bad...\n";
		print "2020/07/29  Able to run user defined command using 'EOS'.\n";
		print "2020/02/17  Temporary directory can be /tmp to reduce I/O traffic as much as possible.\n";
		print "2019/07/04  \$opt_i is specified with \$opt_o, it'll check if executing commands are necessary.\n";
		print "2019/05/23  \$opt_r was added for return specified value.\n";
		print "2019/05/15  \$opt_o was added for post-insert and unused batch routine removed.\n";
		print "2019/05/05  Set up 'output' for a command mode.\n";
		print "2019/04/08  'inputs' to pass inputs as variable array.\n";
		print "2019/04/04  Changed name of this program from 'daemon.pl' to 'moirai2.pl'.\n";
		print "2019/04/03  Array output functionality and command line functionality added.\n";
		print "2019/03/04  Stores run options in the SQLite database.\n";
		print "2019/02/07  'rm','rmdir','import' functions were added to batch routine.\n";
		print "2019/01/21  'mv' functionality added to move temporary files to designated locations.\n";
		print "2019/01/18  'process' functionality added to execute command from a control json.\n";
		print "2019/01/17  Subdivide triple database, revised execute flag to have instance in between.\n";
		print "2018/12/12  'singlethread' added for NCBI/BLAST query.\n";
		print "2018/12/10  Remove unnecessary files when completed.\n";
		print "2018/12/04  Added 'maxjob' and 'nolog' to speed up processed.\n";
		print "2018/11/27  Separating loading, selection, and execution and added 'maxjob'.\n";
		print "2018/11/19  Improving database updates by speed.\n";
		print "2018/11/17  Making daemon faster by collecting individual database accesses.\n";
		print "2018/11/16  Making updating/importing database faster by using improved rdf.pl.\n";
		print "2018/11/09  Added import function where user udpate databse through specified file(s).\n";
		print "2018/09/14  Changed to a ticket system.\n";
		print "2018/02/06  Added qsub functionality.\n";
		print "2018/02/01  Created to throw jobs registered in triple database.\n";
		print "\n";
	}
	exit(0);
}
############################## URL ##############################
my $urls={};
$urls->{"daemon"}="https://moirai2.github.io/schema/daemon";
$urls->{"daemon/bash"}="https://moirai2.github.io/schema/daemon/bash";
$urls->{"daemon/command"}="https://moirai2.github.io/schema/daemon/command";
$urls->{"daemon/command/option"}="https://moirai2.github.io/schema/daemon/command/option";
$urls->{"daemon/container"}="https://moirai2.github.io/schema/daemon/container";
$urls->{"daemon/container/image"}="https://moirai2.github.io/schema/daemon/container/image";
$urls->{"daemon/container/flavor"}="https://moirai2.github.io/schema/daemon/container/flavor";
$urls->{"daemon/description"}="https://moirai2.github.io/schema/daemon/description";
$urls->{"daemon/execid"}="https://moirai2.github.io/schema/daemon/execid";
$urls->{"daemon/execute"}="https://moirai2.github.io/schema/daemon/execute";
$urls->{"daemon/error/file/empty"}="https://moirai2.github.io/schema/daemon/error/file/empty";
$urls->{"daemon/error/stderr/ignore"}="https://moirai2.github.io/schema/daemon/error/stderr/ignore";
$urls->{"daemon/error/stdout/ignore"}="https://moirai2.github.io/schema/daemon/error/stdout/ignore";
$urls->{"daemon/file/md5"}="https://moirai2.github.io/schema/daemon/file/md5";
$urls->{"daemon/file/filesize"}="https://moirai2.github.io/schema/daemon/file/filesize";
$urls->{"daemon/file/linecount"}="https://moirai2.github.io/schema/daemon/file/linecount";
$urls->{"daemon/file/seqcount"}="https://moirai2.github.io/schema/daemon/file/seqcount";
$urls->{"daemon/file/stats"}="https://moirai2.github.io/schema/daemon/file/stats";
$urls->{"daemon/input"}="https://moirai2.github.io/schema/daemon/input";
$urls->{"daemon/inputs"}="https://moirai2.github.io/schema/daemon/inputs";
$urls->{"daemon/localdir"}="https://moirai2.github.io/schema/daemon/localdir"; 
$urls->{"daemon/maxjob"}="https://moirai2.github.io/schema/daemon/maxjob";
$urls->{"daemon/output"}="https://moirai2.github.io/schema/daemon/output";
$urls->{"daemon/process/lastupdate"}="https://moirai2.github.io/schema/daemon/process/lastupdate";
$urls->{"daemon/processtime"}="https://moirai2.github.io/schema/daemon/processtime";
$urls->{"daemon/qjob"}="https://moirai2.github.io/schema/daemon/qjob";
$urls->{"daemon/qjob/opt"}="https://moirai2.github.io/schema/daemon/qjob/opt";
$urls->{"daemon/query/in"}="https://moirai2.github.io/schema/daemon/query/in";
$urls->{"daemon/query/out"}="https://moirai2.github.io/schema/daemon/query/out";
$urls->{"daemon/rdfdb"}="https://moirai2.github.io/schema/daemon/rdfdb";
$urls->{"daemon/return"}="https://moirai2.github.io/schema/daemon/return";
$urls->{"daemon/rootdir"}="https://moirai2.github.io/schema/daemon/rootdir";
$urls->{"daemon/script"}="https://moirai2.github.io/schema/daemon/script";
$urls->{"daemon/script/code"}="https://moirai2.github.io/schema/daemon/script/code";
$urls->{"daemon/script/name"}="https://moirai2.github.io/schema/daemon/script/name";
$urls->{"daemon/serverpath"}="https://moirai2.github.io/schema/daemon/serverpath";
$urls->{"daemon/singlethread"}="https://moirai2.github.io/schema/daemon/singlethread";
$urls->{"daemon/sleeptime"}="https://moirai2.github.io/schema/daemon/sleeptime";
$urls->{"daemon/suffix"}="https://moirai2.github.io/schema/daemon/suffix";
$urls->{"daemon/timecompleted"}="https://moirai2.github.io/schema/daemon/timecompleted";
$urls->{"daemon/timeended"}="https://moirai2.github.io/schema/daemon/timeended";
$urls->{"daemon/timeregistered"}="https://moirai2.github.io/schema/daemon/timeregistered";
$urls->{"daemon/timestarted"}="https://moirai2.github.io/schema/daemon/timestarted";
$urls->{"daemon/unzip"}="https://moirai2.github.io/schema/daemon/unzip";
$urls->{"daemon/userdefined"}="https://moirai2.github.io/schema/daemon/userdefined";
$urls->{"daemon/volume"}="https://moirai2.github.io/schema/daemon/volume";
$urls->{"daemon/workdir"}="https://moirai2.github.io/schema/daemon/workdir";
$urls->{"daemon/workflow"}="https://moirai2.github.io/schema/daemon/workflow";
$urls->{"daemon/workid"}="https://moirai2.github.io/schema/daemon/workid";
$urls->{"daemon/workflow/urls"}="https://moirai2.github.io/schema/daemon/workflow/urls";
############################## MAIN ##############################
my $mode=shift(@ARGV);
my $cmdpaths={};
my $sleeptime=defined($opt_s)?$opt_s:60;
my $maximumJob=defined($opt_m)?$opt_m:5;
my $md5cmd=which('md5sum',$cmdpaths);
if(!defined($md5cmd)){$md5cmd=which('md5',$cmdpaths);}
my $hostname=`hostname`;chomp($hostname);
#xxxDir is absoute path, xxxdir is relative path
my $rootDir=absolutePath(".");
my $homeDir=absolutePath(`echo ~`);
my $dbdir=defined($opt_d)?checkDatabaseDirectory($opt_d):".";
my $moiraidir=".moirai2";
my $bindir="$moiraidir/bin";
my $logdir="$moiraidir/log";
my $cmddir="$moiraidir/cmd";
my $ctrldir="$moiraidir/ctrl";
my $daemondir="$moiraidir/daemon";
my $throwdir="$moiraidir/throw";
my $errordir="$logdir/error";
my $insertdir="$ctrldir/insert";
my $updatedir="$ctrldir/update";
my $deletedir="$ctrldir/delete";
my $processdir="$ctrldir/process";
my $submitdir="$ctrldir/submit";
my $jobdir="$ctrldir/job";
mkdir($moiraidir);chmod(0777,$moiraidir);
mkdir($dbdir);chmod(0777,$dbdir);
mkdir($logdir);chmod(0777,$logdir);
mkdir($errordir);chmod(0777,$errordir);
mkdir($cmddir);chmod(0777,$cmddir);
mkdir($ctrldir);chmod(0777,$ctrldir);
mkdir($bindir);chmod(0777,$bindir);
mkdir($processdir);chmod(0777,$processdir);
mkdir($jobdir);chmod(0777,$jobdir);
mkdir($insertdir);chmod(0777,$insertdir);
mkdir($updatedir);chmod(0777,$updatedir);
mkdir($deletedir);chmod(0777,$deletedir);
mkdir($submitdir);chmod(0777,$submitdir);
mkdir($throwdir);chmod(0777,$throwdir);
mkdir($daemondir);chmod(0777,$daemondir);
##### handle commands #####
if(defined($opt_h)){helpMenu($mode);}
elsif($mode=~/^open$/i){openCommand(@ARGV);}
elsif($mode=~/^daemon$/i){runDaemon(@ARGV);}
elsif($mode=~/^html$/i){createHtml(@ARGV);}
elsif($mode=~/^history$/i){historyCommand(@ARGV);}
elsif($mode=~/^(clean|clear)$/i){cleanMoiraiLogs(@ARGV);}
elsif($mode=~/^test$/i){test(@ARGV);}
elsif($mode=~/^sortsubs$/i){sortSubs(@ARGV);}
elsif($mode=~/^ls$/i){ls(@ARGV);}
else{moiraiMain($mode);}
############################## absolutePath ##############################
sub absolutePath {
	my $path=shift();
	my $directory=dirname($path);
	my $filename=basename($path);
	my $path=Cwd::abs_path($directory)."/$filename";
	$path=~s/\/\.\//\//g;
	$path=~s/\/\.$//g;
	return $path
}
############################## appendText ##############################
sub appendText{
	my $line=shift();
	my $file=shift();
	open(OUT,">>$file");
	print OUT "$line\n";
	close(OUT);
}
############################## assignCommand ##############################
sub assignCommand{
	my $command=shift();
	my $userdefined=shift();
	my $queryResults=shift();
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	my $keys={};
	foreach my $key(@{$queryResults->[0]}){$keys->{$key}++;}
	foreach my $input(@inputs){
		if(exists($userdefined->{$input})){next;}
		if(exists($keys->{$input})){$userdefined->{$input}="\$$input";next;}
		if(defined($opt_u)){promptCommandInput($command,$userdefined,$input);}
		elsif(exists($command->{"default"}->{$input})){$userdefined->{$input}=$command->{"default"}->{$input};}
	}
}
############################## assignExecid ##############################
sub assignExecid{
	my $workid=shift();
	if(!defined($workid)){$workid="e";}
	my $execid=$workid.getDatetime();
	my ($writer,$logfile)=tempfile("${execid}XXXX",DIR=>"$jobdir",SUFFIX=>".txt");
	close($writer);
	return basename($logfile,".txt");
}
############################## assignOptionsToCommand ##############################
sub assignOptionsToCommand{
	my $command=shift();
	my $inputs=shift();
	my $outputs=shift();
	my $suffixs=shift();
	if(defined($inputs)&&!exists($command->{$urls->{"daemon/input"}})){$command->{$urls->{"daemon/input"}}=$inputs;}
	if(defined($outputs)&&!exists($command->{$urls->{"daemon/output"}})){$command->{$urls->{"daemon/output"}}=$outputs;}
	if(defined($suffixs)&&!exists($command->{$urls->{"daemon/suffix"}})){$command->{$urls->{"daemon/suffix"}}=$suffixs;}
	if(defined($opt_a)){$command->{$urls->{"daemon/severpath"}}=handleServer($opt_a);}
	if(defined($opt_c)){$command->{$urls->{"daemon/container"}}=$opt_c;}
	if(defined($opt_q)){$command->{$urls->{"daemon/qjob"}}=$opt_q;}
	if(defined($opt_Q)){$command->{$urls->{"daemon/qjob/opt"}}=$opt_Q;}
	if(defined($opt_r)){$command->{$urls->{"daemon/return"}}=removeDollar($opt_r);}
	if(defined($opt_f)){$command->{$urls->{"daemon/file/stats"}}=handleKeys($opt_f);}
	if(defined($opt_E)){$command->{$urls->{"daemon/error/stderr/ignore"}}=handleKeys($opt_E);}
	if(defined($opt_O)){$command->{$urls->{"daemon/error/stdout/ignore"}}=handleKeys($opt_O);}
	if(defined($opt_v)){$command->{$urls->{"daemon/volume"}}=handleKeys($opt_v);}
	loadCommandFromURLSub($command);
}
############################## basenames ##############################
sub basenames{
	my $path=shift();
	my $delim=shift();
	if(!defined($delim)){$delim="[\\W_]+";}
	my $directory=dirname($path);
	my $filename=basename($path);
	my $basename;
	my $suffix;
	my $hash={};
	if($filename=~/^(.+)\.([^\.]+)$/){$basename=$1;$suffix=$2;}
	else{$basename=$filename;}
	$hash->{"path"}="$directory/$filename";
	$hash->{"file"}="$directory/$filename";
	$hash->{"directory"}=$directory;
	$hash->{"filename"}=$filename;
	$hash->{"basename"}=$basename;
	if(defined($suffix)){$hash->{"suffix"}=$suffix;}
	my @dirs=split(/\//,$directory);
	if($dirs[0] eq ""){shift(@dirs);}
	for(my $i=0;$i<scalar(@dirs);$i++){$hash->{"dir$i"}=$dirs[$i];}
	my @bases=split(/$delim/,$basename);
	for(my $i=0;$i<scalar(@bases);$i++){$hash->{"base$i"}=$bases[$i];}
	return $hash;
}
############################## bashCommand ##############################
sub bashCommand{
	my $command=shift();
	my $vars=shift();
	my $bashFiles=shift();
	my $execid=$vars->{"execid"};
	my $url=$command->{$urls->{"daemon/command"}};
	my $suffixs=$command->{$urls->{"daemon/suffix"}};
	my $options=$command->{"options"};
	my $hash=exists($vars->{"singularity"})?$vars->{"singularity"}:exists($vars->{"docker"})?$vars->{"docker"}:exists($vars->{"server"})?$vars->{"server"}:$vars->{"base"};
	my $bashsrc=$vars->{"base"}->{"bashfile"};
	my $bashfile=$hash->{"bashfile"};
	my $exportpath=$hash->{"exportpath"};
	my $logfile=$hash->{"logfile"};
	my $moiraidir=$hash->{"moiraidir"};
	my $rootdir=$hash->{"rootdir"};
	my $statusfile=$hash->{"statusfile"};
	my $stderrfile=$hash->{"stderrfile"};
	my $stdoutfile=$hash->{"stdoutfile"};
	my $tmpdir=$hash->{"tmpdir"};
	my $workdir=$hash->{"workdir"};
	my $container=$command->{$urls->{"daemon/container"}};
	my $serverpath=$command->{$urls->{"daemon/serverpath"}};
	open(OUT,">$bashsrc");
	print OUT "#!/bin/sh\n";
	print OUT "export PATH=$exportpath\n";
	my @systemvars=("cmdurl","execid","base","docker","singularity","server");
	my $inputHash={};
	foreach my $input(@{$command->{"input"}}){$inputHash->{$input}=1}
	my @outputvars=();
	foreach my $output(@{$command->{"output"}}){
		if($output eq "stdout"){next;}
		if($output eq "stderr"){next;}
		if(exists($inputHash->{$output})){next;}
		push(@outputvars,$output);
	}
	print OUT "cmdurl=\"$url\"\n";
	print OUT "execid=\"$execid\"\n";
	print OUT "workdir=\"$workdir\"\n";
	print OUT "rootdir=\"$rootdir\"\n";
	my $tmpExists=existsString("\\\$tmpdir",$command->{"bashCode"})||scalar(@outputvars)>0;
	if($tmpExists){print OUT "tmpdir=\"$tmpdir\"\n";}
	my @keys=();
	foreach my $key(sort{$a cmp $b}keys(%{$vars})){
		my $break=0;
		foreach my $var(@systemvars){if($var eq $key){$break=1;last;}}
		foreach my $var(@outputvars){if($var eq $key){$break=1;last;}}
		if($break){next;}
		push(@keys,$key);
	}
	foreach my $key(@keys){
		my $value=$vars->{$key};
		if(exists($options->{$key})){
			if($value eq ""){next;}
			if($value eq "0"){next;}
			if($value eq "F"){next;}
			if($value=~/false/i){next;}
			$value=$options->{$key};
			print OUT "$key=\"$value\"\n";
		}else{
			if(ref($value)eq"ARRAY"){print OUT "$key=(\"".join("\" \"",@{$value})."\")\n";}
			else{print OUT "$key=\"$value\"\n";}
		}
	}
	if(scalar(@outputvars)>0){
		foreach my $output(@outputvars){
			my $suffix=(exists($suffixs->{$output}))?$suffixs->{$output}:"";
			print OUT "$output=\$tmpdir/$output$suffix\n";
		}
	}
	print OUT "########## init ##########\n";
	print OUT "cd \$rootdir\n";
	my $basenames={};
	foreach my $key(@keys){
		my $value=$vars->{$key};
		if(ref($value)eq"ARRAY"){next;}
		elsif($value=~/[\.\/]/){
			my $hash=basenames($value);
			while(my ($k,$v)=each(%{$hash})){$basenames->{"$key.$k"}=$v;}
		}
	}
	print OUT "touch \$workdir/status.txt\n";
	print OUT "touch \$workdir/log.txt\n";
	print OUT "function status() { echo \"\$1\t\"`date +\%s` >> \$workdir/status.txt ; }\n";
	print OUT "function record() { echo \"\$1\t\$2\" >> \$workdir/log.txt ; }\n";
	if(exists($command->{$urls->{"daemon/file/seqcount"}})){
		print OUT "function seqcount() {\n";
		print OUT "if [[ \$1 =~ \.f(ast)?a\.g(ip)?z\$ ]]; then\n";
		print OUT "echo \"\$1\tfile/seqcount\t\"`gzip -cd \$1 | grep -E \"^>\" | wc -l | tr -d ' '`;\n";
		print OUT "elif [[ \$1 =~ \.f(ast)?a\.bz(ip)?2\$ ]]; then\n";
		print OUT "echo \"\$1\tfile/seqcount\t\"`bzip2 -cd \$1 | grep -E \"^>\" | wc -l | tr -d ' '`;\n";
		print OUT "elif [[ \$1 =~ \.f(ast)?q\.g(ip)?z\$ ]]; then\n";
		print OUT "echo \"\$1\tfile/seqcount\t\"`gzip -cd \$1 | grep -E \"^\\\@\" | wc -l | tr -d ' '`;\n";
		print OUT "elif [[ \$1 =~ \.f(ast)?q\.bz(ip)?2\$ ]]; then\n";
		print OUT "echo \"\$1\tfile/seqcount\t\"`bzip2 -cd \$1 | grep -E \"^\\\@\" | wc -l | tr -d ' '`;\n";
		print OUT "elif [[ \$1 =~ \.f(ast)?a\$ ]]; then\n";
		print OUT "echo \"\$1\tfile/seqcount\t\"`grep -E \"^>\" < \$1 | wc -l | tr -d ' '`;\n";
		print OUT "elif [[ \$1 =~ \.f(ast)?q\$ ]]; then\n";
		print OUT "echo \"\$1\tfile/seqcount\t\"`grep -E \"^\\\@\" < \$1 | wc -l | tr -d ' '`;\n";
		print OUT "fi\n";
		print OUT "}\n";
	}
	if(exists($command->{$urls->{"daemon/file/linecount"}})||exists($command->{$urls->{"daemon/file/stats"}})){
		print OUT "function linecount() {\n";
		print OUT "if [[ \$1 =~ \.gz(ip)?\$ ]]; then\n";
		print OUT "echo \"\$1\tfile/linecount\t\"`gzip -cd \$1 | wc -l | tr -d ' '`;\n";
		print OUT "elif [[ \$1 =~ \.bz(ip)?2\$ ]]; then\n";
		print OUT "echo \"\$1\tfile/linecount\t\"`bzip2 -cd \$1 | wc -l | tr -d ' '`;\n";
		print OUT "else\n";
		print OUT "echo \"\$1\tfile/linecount\t\"`wc -l < \$1 | tr -d ' '`;\n";
		print OUT "fi\n";
		print OUT "}\n";
	}
	if(exists($command->{$urls->{"daemon/file/md5"}})||exists($command->{$urls->{"daemon/file/stats"}})){
		print OUT "function filemd5() { echo \"\$1\tfile/md5\t\"`md5 < \$1 | tr -d ' '`; }\n";
	}
	if(exists($command->{$urls->{"daemon/file/filesize"}})||exists($command->{$urls->{"daemon/file/stats"}})){
		print OUT "function filesize() { echo \"\$1\tfile/filesize\t\"`wc -c < \$1 | tr -d ' '`; }\n";
	}
	if(exists($command->{$urls->{"daemon/filestamp"}})||exists($command->{$urls->{"daemon/file/stats"}})){
		print OUT "function filestamp() { echo \"\$1\tfile/mtime\t\"`stat -f %m \$1 | tr -d ' '`; }\n";
	}
	if(exists($command->{$urls->{"daemon/file/stats"}})){
		print OUT "function filestats() {\n";
		print OUT "f=\$1\n";
		print OUT "linecount \$f\n";
		print OUT "filemd5 \$f\n";
		print OUT "filesize \$f\n";
		print OUT "filestamp \$f\n";
		print OUT "}\n";
	}
	my @scriptfiles=();
	if(exists($command->{"script"})){
		print OUT "mkdir -p \$workdir/bin\n";
		foreach my $name (@{$command->{"script"}}){
			my $path="\$workdir/bin/$name";
			push(@scriptfiles,$name);
			print OUT "cat<<EOF>$path\n";
			foreach my $line(scriptCodeForBash(@{$command->{$name}})){print OUT "$line\n";}
			print OUT "EOF\n";
			print OUT "chmod 755 $path\n";
		}
	}
	if($tmpExists){
		print OUT "mkdir -p /tmp/\$execid\n";
		print OUT "ln -s /tmp/\$execid \$tmpdir\n";
	}
	my @unzips=();
	if(exists($command->{$urls->{"daemon/unzip"}})){
		foreach my $key(@{$command->{$urls->{"daemon/unzip"}}}){
			if(exists($vars->{$key})){
				my @values=(ref($vars->{$key})eq"ARRAY")?@{$vars->{$key}}:($vars->{$key});
				foreach my $value(@values){
					if($value=~/^(.+)\.bz(ip)?2$/){
						my $basename=basename($1);
						print OUT "$key=\$workdir/$basename\n";
						print OUT "bzip2 -cd $value>\$$key\n";
						push(@unzips,"\$workdir/$basename");
					}elsif($value=~/^(.+)\.gz(ip)?$/){
						my $basename=basename($1);
						print OUT "$key=\$workdir/$basename\n";
						print OUT "gzip -cd $value>\$$key\n";
						push(@unzips,"\$workdir/$basename");
					}
				}
			}
		}
	}
	if(exists($command->{$urls->{"daemon/error/file/empty"}})){
		my $hash=$command->{$urls->{"daemon/error/file/empty"}};
		my $index=0;
		foreach my $input(@{$command->{"input"}}){
			if(!exists($hash->{$input})){next;}
			print OUT "if [[ \"\$(declare -p $input)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for in in \${$input"."[\@]} ; do\n";
			print OUT "if [ ! -s \$in ]; then\n";
			print OUT "echo 'Empty input: \$in' 1>&2\n";
			print OUT "fi\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "if [ ! -s \$$input ]; then\n";
			print OUT "echo \"Empty input: \$$input\" 1>&2\n";
			print OUT "fi\n";
			print OUT "fi\n";
			$index++;
		}
	}
	print OUT "status start\n";
	print OUT "########## command ##########\n";
	foreach my $line(@{$command->{"bashCode"}}){
		my $temp=$line;
		if($temp=~/\$\{.+\}/){while(my ($k,$v)=each(%{$basenames})){$temp=~s/\$\{$k\}/$v/g;}}
		print OUT "$temp\n";
	}
	print OUT "#############################\n";
	print OUT "status end\n";
	foreach my $output(@outputvars){
		if(exists($vars->{$output})&&$output ne $vars->{$output}){
			my $value=$vars->{$output};
			print OUT "mv \$$output $value\n";
			print OUT "$output=$value\n";
		}
	}
	if(exists($command->{$urls->{"daemon/file/seqcount"}})){
		foreach my $key(@{$command->{$urls->{"daemon/file/seqcount"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "seqcount \$out\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "seqcount \$$key\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/file/linecount"}})){
		foreach my $key(@{$command->{$urls->{"daemon/file/linecount"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "linecount \$out\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "linecount \$$key\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/file/md5"}})){
		foreach my $key(@{$command->{$urls->{"daemon/file/md5"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "filemd5 \$out\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "filemd5 \$$key\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/file/filesize"}})){
		foreach my $key(@{$command->{$urls->{"daemon/file/filesize"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "filesize \$out\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "filesize \$$key\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/file/filestamp"}})){
		foreach my $key(@{$command->{$urls->{"daemon/file/filestamp"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "filestamp \$out\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "filestamp \$$key\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/file/stats"}})){
		foreach my $key(@{$command->{$urls->{"daemon/file/stats"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "filestats \$out\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "filestats \$$key\n";
			print OUT "fi\n";
		}
	}
	my $inserts={};
	if(exists($command->{"insertKeys"})&&scalar(@{$command->{"insertKeys"}})>0){
		foreach my $insert(@{$command->{"insertKeys"}}){
			my $found=0;
			my $line="insert ".join("->",@{$insert});
			foreach my $output(@outputvars){
				if($line=~/\$$output/){push(@{$inserts->{$output}},$insert);$found=1;last;}
			}
			if($found==0){push(@{$inserts->{""}},$insert);}
		}
	}
	if(exists($command->{"output"})&&scalar(@outputvars)>0){
		foreach my $output(@outputvars){
			print OUT "if [[ \"\$(declare -p $output)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$output"."[\@]} ; do\n";
			print OUT "record \"\$cmdurl#$output\" \"\$out\"\n";
			if(exists($inserts->{$output})){
				foreach my $row(@{$inserts->{$output}}){
					my $line="insert ".join("->",@{$row});
					$line=~s/\$$output/\$out/g;
					print OUT "echo \"$line\"\n";
				}
			}
			print OUT "done\n";
			print OUT "else\n";
			print OUT "record \"\$cmdurl#$output\" \"\$$output\"\n";
			if(exists($inserts->{$output})){
				foreach my $row(@{$inserts->{$output}}){print OUT "echo \"insert ".join("->",@{$row})."\"\n";}
			}
			print OUT "fi\n";
		}
	}
	if(exists($inserts->{""})){foreach my $row(@{$inserts->{""}}){print OUT "echo \"insert ".join("->",@{$row})."\"\n";}}
	if(scalar(@unzips)>0){
		foreach my $unzip(@unzips){print OUT "rm $unzip\n";}
	}
	if($tmpExists){
		print OUT "rm \$workdir/tmp\n";
		print OUT "if [ -z \"\$(ls -A /tmp/\$execid)\" ]; then\n";
	  	print OUT "rmdir /tmp/\$execid\n";
		print OUT "else\n";
		print OUT "mv /tmp/\$execid \$workdir/tmp\n";
		print OUT "fi\n";
	}
	print OUT "status=\"\"\n";
	if(exists($command->{$urls->{"daemon/error/file/empty"}})){
		my $index=0;
		print OUT "if [ -z \"\$status\" ]; then\n";
		my $hash=$command->{$urls->{"daemon/error/file/empty"}};
		foreach my $output(@outputvars){
			if(!exists($hash->{$output})){next;}
			print OUT "if [[ \"\$(declare -p $output)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$output"."[\@]} ; do\n";
			print OUT "if [ ! -s \$out ]; then\n";
			print OUT "echo 'Empty output: \$out' 1>&2\n";
			print OUT "status=error\n";
			print OUT "fi\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "if [ ! -s \$$output ]; then\n";
			print OUT "echo \"Empty output: \$$output\" 1>&2\n";
			print OUT "status=error\n";
			print OUT "fi\n";
			print OUT "fi\n";
			$index++;
		}
		print OUT "fi\n";
	}
	if(exists($command->{$urls->{"daemon/error/stdout/ignore"}})){
		my $lines=$command->{$urls->{"daemon/error/stdout/ignore"}};
		print OUT "if [ -z \"\$status\" ]; then\n";
		foreach my $line(@{$lines}){
			print OUT "if [ \"\$(grep '$line' \$workdir/stdout.txt)\" != \"\" ]; then\n";
			print OUT "status=completed\n";
			print OUT "fi\n";
		}
		print OUT "fi\n";
	}
	if(exists($command->{$urls->{"daemon/error/stderr/ignore"}})){
		my $lines=$command->{$urls->{"daemon/error/stderr/ignore"}};
		print OUT "if [ -z \"\$status\" ]; then\n";
		foreach my $line(@{$lines}){
			print OUT "if [ \"\$(grep '$line' \$workdir/stderr.txt)\" != \"\" ]; then\n";
			print OUT "status=completed\n";
			print OUT "fi\n";
		}
		print OUT "fi\n";
	}
	print OUT "if [ -z \"\$status\" ]; then\n";
	print OUT "if [ -s \$workdir/stderr.txt ]; then\n";
	print OUT "status=error\n";
	print OUT "fi\n";
	print OUT "fi\n";
	print OUT "if [ -z \"\$status\" ]; then\n";
	print OUT "status=completed\n";
	print OUT "fi\n";
	print OUT "status \$status\n";
	# moirai2.pl checks status.txt for status to be 'completed' or 'error' when filestamp is updated.
	# but if status was rewritten when moirai2.pl was reading the file, process never ends.
	# So after 1 second, file is touched to renew filestamp
	print OUT "sleep 1\n";
	print OUT "touch \$workdir/status.txt\n";
	close(OUT);
}
############################## bashCommandHasOptions ##############################
sub bashCommandHasOptions{
	my $command=shift();
	if(exists($command->{$urls->{"daemon/container"}})){return 1;}
	elsif(scalar(@{$command->{$urls->{"daemon/input"}}}>0)){return 1;}
	elsif(scalar(@{$command->{$urls->{"daemon/output"}}}>0)){return 1;}
	elsif(exists($command->{$urls->{"daemon/query/in"}})){return 1;}
	elsif(exists($command->{$urls->{"daemon/query/out"}})){return 1;}
}
############################## checkArray ##############################
sub checkArray{
	my $val=shift();
	my $index=shift();
	my $array=shift();
	my $hash=shift();
	if(defined($hash)){if(!exists($hash->{$val})){return 1;}$val=$hash->{$val};}
	foreach my $t(@{$array}){if($t->[$index] eq $val){return 1;}}
}
############################## checkDatabaseDirectory ##############################
sub checkDatabaseDirectory{
	my $directory=shift();
	if($directory=~/\.\./){
		print STDERR "ERROR: Please don't use '..' for moirai database directory\n";
		exit(1);
	}elsif($directory=~/^\//){
		print STDERR "ERROR: moirai directory '$directory' have to be relative to a root directory\n";
		exit(1);
	}
	return $directory;
}
############################## checkEval ##############################
sub checkEval{
	my @checks=@_;
	my $result=shift(@checks);
	my $input=shift(@checks);
	my @lines=();
	foreach my $check(@checks){
		my $statement=$check;
		foreach my $key(keys(%{$result})){
			my $val=$result->{$key};
			$statement=~s/\$$key/$val/g;
		}
		if(!eval($statement)){
			my $input=$opt_i;
			foreach my $key(keys(%{$result})){
				my $val=$result->{$key};
				$input=~s/\$$key/$val/g;
			}
			push(@lines,"ERROR($statement) $input");
		}
	}
	return @lines;
}
############################## checkFileIsEmpty ##############################
sub checkFileIsEmpty {
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){
		my $size=`ssh $1 'perl -e \"my \@array=stat(\\\$ARGV[0]);print \\\$array[7]\" $2'`;
		chomp($size);
		return ($size==0);
	}else{
		return (-z $path);
	}
}
############################## checkInputOutput ##############################
sub checkInputOutput{
	my $queries=shift();
	my $triple;
	foreach my $query(split(/,/,$queries)){
		my @tokens=split(/->/,$query);
		if(scalar(@tokens)==1){
		}elsif(scalar(@tokens)==3){
			my $empty=0;
			$triple=1;
			foreach my $token(@tokens){if($token eq ""){$empty=1;last;}}
			if($empty==1){
				print STDERR "ERROR: '$query' has empty token.\n";
				print STDERR "ERROR: Use single quote '\$a->b->\$c' instead of double quote \"\$a->b->\$c\".\n";
				print STDERR "ERROR: Or escape '\$' with '\\' sign \"\\\$a->b->\\\$c\".\n";
				exit(1);
			}
		}
	}
	return $triple;
}
############################## checkProcessStatus ##############################
sub checkProcessStatus{
	my $process=shift();
	my $workdir=$process->{$urls->{"daemon/workdir"}};
	my $lastUpdate=$process->{$urls->{"daemon/process/lastupdate"}};
	my $lastStatus=$process->{$urls->{"daemon/execute"}};
	my $statusfile="$workdir/status.txt";
	my $timestamp=checkTimestamp($statusfile);
	if(!defined($timestamp)){return;}
	if(!defined($lastUpdate)||$timestamp>$lastUpdate){
		my $reader=openFile($statusfile);
		my $currentStatus;
		while(<$reader>){
			chomp;
			my ($key,$val)=split(/\t/);
			$currentStatus=$key;
		}
		close($reader);
		if($currentStatus eq $lastStatus){return;}
		$process->{$urls->{"daemon/process/lastupdate"}}=$timestamp;
		$process->{$urls->{"daemon/execute"}}=$currentStatus;
		return $currentStatus;
	}else{
		return;
	}
}
############################## checkQuery ##############################
sub checkQuery{
	my @queries=@_;
	my $hit=0;
	foreach my $query(@queries){
		my $i=0;
		foreach my $node(split(/->/,$query)){
			if($node=~/^\$[\w_]+$/){}
			elsif($node=~/^\$(\w+)/){
				my $label=($i==0)?"subject":($i==1)?"predicate":"object";
				print STDERR "ERROR : '$node' can't be used as $label in query '$query'.\n";
				print STDERR "      : Please specify '\$$1' variable in argument with '\$$1=???????'.\n";
				$hit++;
			}
			$i++;
		}
	}
	return $hit;
}
############################## checkTimestamp ##############################
sub checkTimestamp {
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){
		my $stat=`ssh $1 'perl -e \"my \@array=stat(\\\$ARGV[0]);print \\\$array[9]\" $2'`;
		if($stat eq ""){return;}
		return $stat;
	}else{
		my @stats=stat($path);
		return $stats[9];
	}
}
############################## cleanMoiraiLogs ##############################
sub cleanMoiraiLogs{
	my @arguments=@_;
	foreach my $file(getFiles("$ctrldir/insert")){system("rm $file");}
	foreach my $file(getFiles("$ctrldir/job")){system("rm $file");}
	foreach my $file(getFiles("$ctrldir/process")){system("rm $file");}
	foreach my $file(getFiles("$ctrldir/submit")){system("rm $file");}
	foreach my $file(getFiles("$moiraidir/cmd")){system("rm $file");}
	foreach my $file(getFiles("$logdir/error")){system("rm $file");}
	foreach my $dir(getDirs($moiraidir,"\\d{14}")){system("rm -r $dir");}
	foreach my $dir(getDirs($logdir,"\\d{8}")){system("rm -r $dir");}
	if(-e "$logdir.lock"){unlink("$logdir.lock");}
}
############################## compareFiles ##############################
sub compareFiles{
	my $fileA=shift();
	my $fileB=shift();
	open(INA,$fileA);
	open(INB,$fileB);
	while(!eof(INA)){
		my $lineA=<INA>;
		my $lineB=<INB>;
		if($fileA ne $fileB){return;}
	}
	close(INB);
	close(INA);
	return 1;
}
############################## compareValues ##############################
sub compareValues{
	my $value1=shift();
	my $value2=shift();
	if(ref($value1) eq "ARRAY"){
		if(ref($value2) ne "ARRAY"){return 1;}
		my $l1=scalar(@{$value1});
		my $l2=scalar(@{$value2});
		if($l1!=$l2){return 1;}
		for(my $i=0;$i<$l1;$i++){if(compareValues($value1->[$i],$value2->[$i])){return 1;}}
		return;
	}elsif(ref($value1) eq "HASH"){
		if(ref($value2) ne "HASH"){return 1;}
		my $l1=scalar(keys(%{$value1}));
		my $l2=scalar(keys(%{$value2}));
		if($l1!=$l2){return 1;}
		foreach my $key(keys(%{$value1})){
			if(compareValues($value1->{$key},$value2->{$key})){return 1;}
		}
		return;
	}elsif(ref($value2) eq "ARRAY"){return 1;}
	elsif(ref($value2) eq "HASH"){return 1;}
	if($value1 eq $value2){return;}
	return 1;
}
############################## completeProcess ##############################
sub completeProcess{
	my $process=shift();
	my $commands=shift();
	my $status=shift();
	my $url=$process->{$urls->{"daemon/command"}};
	my $command=$commands->{$url};
	my $execid=$process->{$urls->{"daemon/execid"}};
	my $srcdir="$moiraidir/$execid";
	my $workdir=$process->{$urls->{"daemon/workdir"}};
	my $stderrfile="$workdir/stderr.txt";
	my $stdoutfile="$workdir/stdout.txt";
	my $statusfile="$workdir/status.txt";
	my $logfile="$workdir/log.txt";
	my $bashfile="$workdir/run.sh";
	my $processfile="$processdir/$execid.txt";
	my $dirname=substr(substr($execid,-18),0,8);
	my $jobfile="$jobdir/$execid.txt";
	my $outputfile="$logdir/$dirname/$execid.txt";
	mkdir(dirname($outputfile));
	my $newprocess={};
	#processfile
	my $timeregistered;
	my $execid;
	my $reader=openFile($processfile);
	while(<$reader>){
		chomp;my ($key,$val)=split(/\t/);$newprocess->{$key}=$val;
		if($key eq $urls->{"daemon/timeregistered"}){$timeregistered=$val;}
		if($key eq $urls->{"daemon/execid"}){$execid=$val;}
	}
	close($reader);
	#rereading logfile
	my $log=loadLogFile($logfile);
	if(defined($opt_l)){print "#Completing: $execid with '$status' status\n";}
	if(exists($process->{$urls->{"daemon/localdir"}})){
		my $localdir=$process->{$urls->{"daemon/localdir"}};
		downloadOutputs($command,$process);
		removeFilesFromServer($command,$process);
		unlink("$localdir/run.sh");
	}
	$stderrfile="$workdir/stderr.txt";
	$stdoutfile="$workdir/stdout.txt";
	$statusfile="$workdir/status.txt";
	$logfile="$workdir/log.txt";
	$bashfile="$workdir/run.sh";
	#statusfile
	my $timestarted;
	my $timeended;
	$reader=openFile($statusfile);
	while(<$reader>){
		chomp;my ($key,$time)=split(/\t/);
		if($key eq "start"){$log->{$urls->{"daemon/timestarted"}}=$time;$timestarted=$time;}
		elsif($key eq "end"){$log->{$urls->{"daemon/timeended"}}=$time;$timeended=$time;}
		elsif($key eq "completed"){$log->{$urls->{"daemon/timecompleted"}}=$time;$log->{$urls->{"daemon/execute"}}="completed";}
		elsif($key eq "error"){$log->{$urls->{"daemon/timecompleted"}}=$time;$log->{$urls->{"daemon/execute"}}="error";}
	}
	close($reader);
	$log->{$urls->{"daemon/processtime"}}=$timeended-$timestarted;
	#write logfile
	my ($logwriter,$logoutput)=tempfile();
	print $logwriter "######################################## $execid ########################################\n";
	foreach my $key(sort{$a cmp $b}keys(%{$log})){
		if(ref($log->{$key})eq"ARRAY"){foreach my $val(@{$log->{$key}}){print $logwriter "$key\t$val\n";}}
		else{print $logwriter "$key\t".$log->{$key}."\n";}
	}
	print $logwriter "######################################## status ########################################\n";
	#statusfile
	my $reader=openFile($statusfile);
	print $logwriter "registered\t$timeregistered\n";
	while(<$reader>){chomp;print $logwriter "$_\n";}
	close($reader);
	#stdoutfile
	$reader=openFile($stdoutfile);
	my ($insertwriter,$insertfile)=tempfile();
	my ($deletewriter,$deletefile)=tempfile();
	my ($updatewriter,$updatefile)=tempfile();
	my $stdoutcount=0;
	my $insertcount=0;
	my $deletecount=0;
	my $updatecount=0;
	while(<$reader>){
		chomp;
		if(/insert\s+(.+)\-\>(.+)\-\>(.+)/){print $insertwriter "$1\t$2\t$3\n";$insertcount++;next;}
		if(/delete\s+(.+)\-\>(.+)\-\>(.+)/){print $deletewriter "$1\t$2\t$3\n";$deletecount++;next;}
		if(/update\s+(.+)\-\>(.+)\-\>(.+)/){print $updatewriter "$1\t$2\t$3\n";$updatecount++;next;}
		if($stdoutcount==0){print $logwriter "######################################## stdout ########################################\n";}
		print $logwriter "$_\n";$stdoutcount++;
	}
	close($reader);
	close($insertwriter);
	close($deletewriter);
	close($updatewriter);
	#stderrfile
	$reader=openFile($stderrfile);
	my $stderrcount=0;
	while(<$reader>){
		chomp;
		if($stderrcount==0){print $logwriter "######################################## stderr ########################################\n";}
		print $logwriter "$_\n";$stderrcount++;
	}
	close($reader);
	#insertfile
	if($insertcount>0){
		print $logwriter "######################################## insert ########################################\n";
		my $reader=openFile($insertfile);
		while(<$reader>){chomp;print $logwriter "$_\n";}
		close($reader);
		system("mv $insertfile $insertdir/".basename($insertfile));
	}else{unlink($insertfile);}
	#updatefile
	if($updatecount>0){
		print $logwriter "######################################## update ########################################\n";
		my $reader=openFile($updatefile);
		while(<$reader>){chomp;print $logwriter "$_\n";}
		close($reader);
		system("mv $updatefile $updatedir/".basename($updatefile));
	}else{unlink($updatefile);}
	#deletefile
	if($deletecount>0){
		print $logwriter "######################################## delete ########################################\n";
		my $reader=openFile($deletefile);
		while(<$reader>){chomp;print $logwriter "$_\n";}
		close($reader);
		system("mv $deletefile $deletedir/".basename($deletefile));
	}else{unlink($deletefile);}
	#bashfile
	print $logwriter "######################################## bash ########################################\n";
	my $reader=openFile($bashfile);
	while(<$reader>){chomp;print $logwriter "$_\n";}
	close($reader);
	close($logwriter);
	#scripts
	if(exists($command->{"script"})){
		my @files=();
		foreach my $file(@{$command->{"script"}}){push(@files,"$workdir/bin/$file");}
		removeFile(@files);
		removeDirs("$workdir/bin");
	}
	#complete
	system("mv $logoutput $outputfile");
	removeFile($bashfile,$logfile,$stdoutfile,$stderrfile,$jobfile,$processfile);
	# status file is touched after 1 second at the end processs,
	# There is a possibility that black status.txt is made by the touch.
	# So we need to make sure we wait 1 second before removing the status file.
	sleep(1);
	removeFile($statusfile);
	removeDirs($srcdir,$workdir);
	if($status eq "completed"){}
	elsif($status eq "error"){system("mv $outputfile $errordir/".basename($outputfile));}
}
############################## controlDelete ##############################
sub controlDelete{
	my @files=getFiles($deletedir);
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $prgdir/rdf.pl -q -d $dbdir -f tsv delete";
	my $count=`$command`;
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlInsert ##############################
sub controlInsert{
	my @files=getFiles($insertdir);
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $prgdir/rdf.pl -q -d $dbdir -f tsv insert";
	my $count=`$command`;
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlProcess ##############################
sub controlProcess{
	my $processes=shift();
	my $commands=shift();
	my $completed=0;
	if(!defined($processes)){return $completed;}
	foreach my $execid(keys(%{$processes})){
		my $process=$processes->{$execid};
		my $status=checkProcessStatus($process);
		if(!defined($status)){next;}
		if($status eq "completed"||$status eq "error"){
			completeProcess($process,$commands,$status);
			$completed++;
		}else{writeLog($execid,$urls->{"daemon/execute"}."\t$status");}
	}
	return $completed;
}
############################## controlUpdate ##############################
sub controlUpdate{
	my @files=getFiles($updatedir);
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $prgdir/rdf.pl -q -d $dbdir -f tsv upate";
	my $count=`$command`;
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlWorkflow ##############################
sub controlWorkflow{
	my $processes=shift();
	my $commands=shift();
	my $inserted=controlInsert();
	my $updated=controlUpdate();
	my $deleted=controlDelete();
	my $completed=0;
	if(defined($processes)&&defined($commands)){$completed=controlProcess($processes,$commands);}
	if(!defined($opt_l)){return;}
	if($completed>0){print "#Completed: $completed\n";}
	my $remaining=getNumberOfJobsRemaining();
	if($remaining>0){print "#Remaining: $remaining\n";}
	if($inserted>0){print "#Inserted: $inserted\n";}
	if($deleted>0){print "#Deleted: $deleted\n";}
	if($updated>0){print "#Updated: $updated\n";}
}
############################## createFile ##############################
sub createFile{
	my @lines=@_;
	my $path=shift(@lines);
	mkdirs(dirname($path));
	open(OUT,">$path");
	foreach my $line(@lines){print OUT "$line\n";}
	close(OUT);
}
############################## createHtml ##############################
sub createHtml{
	print "<html>\n";
	print "<head>\n";
	print "<title>moirai</title>\n";
	print "<script type=\"text/javascript\" src=\"js/vis/vis-network.min.js\"></script>\n";
	print "<script type=\"text/javascript\" src=\"js/jquery/jquery-3.4.1.min.js\"></script>\n";
	print "<script type=\"text/javascript\" src=\"js/jquery/jquery.columns.min.js\"></script>\n";
	print "<script type=\"text/javascript\">\n";
	#my $network=`perl $prgdir/rdf.pl -d $dbdir export network`;
	#chomp($network);
	my $db=`perl $prgdir/rdf.pl export db`;
	chomp($db);
	my $log=`perl $prgdir/rdf.pl export log`;
	chomp($log);
	#print "var network=$network;\n";
	print "var db=$db;\n";
	print "var log=$log;\n";
    print "var nodes = new vis.DataSet(db[0]);\n";
    print "var edges = new vis.DataSet(db[1]);\n";
	print "var options = db[2];\n";
	print "\$(document).ready(function() {\n";
	print "	var container=\$(\"#dbs\")[0];\n";
    print "	var data={nodes:nodes,edges:edges,};\n";
    print "	var db=new vis.Network(container,data,options);\n";
	print "	db.on(\"click\",function(params){\n";
    print "		if (params.nodes.length==1) {\n";
    print "			var nodeId=params.nodes[0];\n";
    print "			var node=nodes.get(nodeId);\n";
    print "			console.log(params.event.srcEvent.shiftKey);\n";
    print "			console.log(node.label+' clicked!');\n";
    print "		}\n";
    print "		if (params.edges.length==1) {\n";
	print "			var edgeId=params.edges[0];\n";
	print "			var edge=edges.get(edgeId);\n";
	print "			console.log(edge.label+' clicked!');\n";
	print "		}\n";
  	print "	});\n";
	print "	\$('#logs').columns({\n";
    print "		data:log,\n";
    print "		schema: [\n";
    print "			{'header': 'logfile', 'key': 'daemon/logfile','template':'<a href=\"{{daemon/logfile}}\">{{daemon/logfile}}</a>'},\n";
    print "			{'header': 'execute', 'key': 'daemon/execute'},\n";
    print "			{'header': 'timestarted', 'key': 'daemon/timestarted'},\n";
    print "			{'header': 'timeended', 'key': 'daemon/timeended'},\n";
    print "			{'header': 'command', 'key': 'daemon/command','template':'<a href=\"{{daemon/command}}\">{{daemon/command}}</a>'}\n";
  	print "		]\n";
	print "	});\n";
	print "});\n";
	print "</script>\n";
	print "<link rel=\"stylesheet\" href=\"css/classic.css\">\n";
	print "<style type=\"text/css\">\n";
    print "#dbs {\n";
    print "border: 1px solid lightgray;\n";
    print "}\n";
	print "</style>\n";
	print "</head>\n";
	print "<body>\n";
	print "<h1>moirai</h1>\n";
	print "updated: ".getDate("/")." ".getTime(":")."\n";
	print "<hr>\n";
    print "<div id=\"dbs\"></div>\n";
    print "<div id=\"logs\"></div>\n";
	print "</body>\n";
	print "</html>\n";
}
############################## createJson ##############################
sub createJson{
	my @commands=@_;
	my $inputs=shift(@commands);
	my $outputs=shift(@commands);
	my $suffixs=shift(@commands);
	if(scalar(keys(%{$suffixs}))==0){$suffixs=undef;}
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".json");
	print $writer "{";
	print $writer "\"".$urls->{"daemon/bash"}."\":".jsonEncode(\@commands);
	if(scalar(@{$inputs})>0){print $writer ",\"".$urls->{"daemon/input"}."\":[\"".join("\",\"",@{$inputs})."\"]";}
	if(scalar(@{$outputs})>0){print $writer ",\"".$urls->{"daemon/output"}."\":[\"".join("\",\"",@{$outputs})."\"]";}
	if(defined($opt_a)){print $writer ",\"".$urls->{"daemon/serverpath"}."\":\"".handleServer($opt_a)."\"";}
	if(defined($opt_b)){print $writer ",\"".$urls->{"daemon/command/option"}."\":{".join(",",handleKeys($opt_b))."}";}
	if(defined($opt_c)){print $writer ",\"".$urls->{"daemon/container"}."\":\"$opt_c\"";}
	if(defined($opt_E)){print $writer ",\"".$urls->{"daemon/error/stderr/ignore"}."\":[\"$opt_E\"]";}
	if(defined($opt_f)){print $writer ",\"".$urls->{"daemon/file/stats"}."\":[".join(",",handleKeys($opt_f))."]";}
	if(defined($opt_F)){print $writer ",\"".$urls->{"daemon/error/file/empty"}."\":[".join(",",handleKeys($opt_F))."]";}
	if(defined($opt_I)){print $writer ",\"".$urls->{"daemon/container/image"}."\":\"$opt_I\"";}
	if(defined($opt_m)){print $writer ",\"".$urls->{"daemon/maxjob"}."\":\"$opt_m\"";}
	if(defined($opt_q)){print $writer ",\"".$urls->{"daemon/qjob"}."\":\"$opt_q\"";}
	if(defined($opt_Q)){print $writer ",\"".$urls->{"daemon/qjob/opt"}."\":\"$opt_Q\"";}
	if(defined($opt_O)){print $writer ",\"".$urls->{"daemon/error/stdout/ignore"}."\":[\"$opt_O\"]";}
	if(defined($opt_r)){print $writer ",\"".$urls->{"daemon/return"}."\":\"".removeDollar($opt_r)."\"";}
	if(defined($opt_s)){print $writer ",\"".$urls->{"daemon/sleeptime"}."\":\"$opt_s\"";}
	my $scripts=handleArray($opt_S);
	if(scalar(@{$scripts}>0)){print $writer ",".encodeScripts(@{$scripts});}
	if(defined($opt_v)){print $writer ",\"".$urls->{"daemon/volume"}."\":\"$opt_v\"";}
	if(defined($opt_V)){print $writer ",\"".$urls->{"daemon/container/flavor"}."\":\"$opt_V\"";}
	if(defined($suffixs)){print $writer ",\"".$urls->{"daemon/suffix"}."\":".jsonEncode($suffixs);}
	print $writer "}";
	close($writer);
	if($file=~/^\.\/(.+)$/){$file=$1;}
	my $json;
	if(defined($md5cmd)){
		my $md5=`$md5cmd<$file`;chomp($md5);
		foreach my $tmp(getFiles($cmddir)){
			my $md=`$md5cmd<$tmp`;chomp($md);
			if($md eq $md5){$json=$tmp;}
		}
	}else{
		my $sizeA=-s $file;
		foreach my $tmp(getFiles($cmddir)){
			my $sizeB=-s $tmp;
			if($sizeA!=$sizeB){next;}
			if(compareFiles($sizeA,$sizeB)){$json=$sizeB;last;}
		}
	}
	if(defined($json)){
		unlink($file);
	}else{
		$json="$cmddir/j".getDatetime().".json";
		while(-e $json){sleep(1);$json="$cmddir/j".getDatetime().".json";}
		system("mv $file $json");
	}
	return $json;
}
sub createJsonOld{
	my @commands=@_;
	my $inputs=shift(@commands);
	my $outputs=shift(@commands);
	my $suffixs=shift(@commands);
	if(scalar(keys(%{$suffixs}))==0){$suffixs=undef;}
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".json");
	print $writer "{";
	print $writer "\"".$urls->{"daemon/bash"}."\":".jsonEncode(\@commands);
	if(scalar(@{$inputs})>0){print $writer ",\"".$urls->{"daemon/input"}."\":[\"".join("\",\"",@{$inputs})."\"]";}
	if(scalar(@{$outputs})>0){print $writer ",\"".$urls->{"daemon/output"}."\":[\"".join("\",\"",@{$outputs})."\"]";}
	if(defined($opt_a)){print $writer ",\"".$urls->{"daemon/serverpath"}."\":\"".handleServer($opt_a)."\"";}
	if(defined($opt_b)){print $writer ",\"".$urls->{"daemon/command/option"}."\":{".join(",",handleKeys($opt_b))."}";}
	if(defined($opt_c)){print $writer ",\"".$urls->{"daemon/container"}."\":\"$opt_c\"";}
	if(defined($opt_E)){print $writer ",\"".$urls->{"daemon/error/stderr/ignore"}."\":[\"$opt_E\"]";}
	if(defined($opt_f)){print $writer ",\"".$urls->{"daemon/file/stats"}."\":[".join(",",handleKeys($opt_f))."]";}
	if(defined($opt_F)){print $writer ",\"".$urls->{"daemon/error/file/empty"}."\":[".join(",",handleKeys($opt_F))."]";}
	if(defined($opt_I)){print $writer ",\"".$urls->{"daemon/container/image"}."\":\"$opt_I\"";}
	if(defined($opt_m)){print $writer ",\"".$urls->{"daemon/maxjob"}."\":\"$opt_m\"";}
	if(defined($opt_q)){print $writer ",\"".$urls->{"daemon/qjob"}."\":\"$opt_q\"";}
	if(defined($opt_Q)){print $writer ",\"".$urls->{"daemon/qjob/opt"}."\":\"$opt_Q\"";}
	if(defined($opt_O)){print $writer ",\"".$urls->{"daemon/error/stdout/ignore"}."\":[\"$opt_O\"]";}
	if(defined($opt_r)){print $writer ",\"".$urls->{"daemon/return"}."\":\"".removeDollar($opt_r)."\"";}
	if(defined($opt_s)){print $writer ",\"".$urls->{"daemon/sleeptime"}."\":\"$opt_s\"";}
	my $scripts=handleArray($opt_S);
	if(scalar(@{$scripts}>0)){print $writer ",".encodeScripts(@{$scripts});}
	if(defined($opt_v)){print $writer ",\"".$urls->{"daemon/volume"}."\":\"$opt_v\"";}
	if(defined($opt_V)){print $writer ",\"".$urls->{"daemon/container/flavor"}."\":\"$opt_V\"";}
	if(defined($suffixs)){print $writer ",\"".$urls->{"daemon/suffix"}."\":".jsonEncode($suffixs);}
	print $writer "}";
	close($writer);
	if($file=~/^\.\/(.+)$/){$file=$1;}
	my $json;
	if(defined($md5cmd)){
		my $md5=`$md5cmd<$file`;chomp($md5);
		foreach my $tmp(getFiles($cmddir)){
			my $md=`$md5cmd<$tmp`;chomp($md);
			if($md eq $md5){$json=$tmp;}
		}
	}else{
		my $sizeA=-s $file;
		foreach my $tmp(getFiles($cmddir)){
			my $sizeB=-s $tmp;
			if($sizeA!=$sizeB){next;}
			if(compareFiles($sizeA,$sizeB)){$json=$sizeB;last;}
		}
	}
	if(defined($json)){
		unlink($file);
	}else{
		$json="$cmddir/j".getDatetime().".json";
		while(-e $json){sleep(1);$json="$cmddir/j".getDatetime().".json";}
		system("mv $file $json");
	}
	return $json;
}
############################## daemonCheckTimestamp ##############################
sub daemonCheckTimestamp{
	my $command=shift();
	my $cmdurl=$command->{$urls->{"daemon/command"}};
	my $lockfile="$cmdurl.lock";
	my $unlockfile="$cmdurl.unlock";
	if(-e $lockfile){
		if(-e $unlockfile){unlink($lockfile);unlink($unlockfile);}
		else{return;}
	}
	my $queries=$command->{$urls->{"daemon/query/in"}};
	if(!defined($queries)){return 1;}
	my $rdbdb=$command->{$urls->{"daemon/rdfdb"}};
	my $hit=0;
	foreach my $query(@{$queries}){
		if(ref($query)ne"ARRAY"){next;}
		my $predicate=$query->[1];
		if(defined($rdbdb)){$predicate="$rdbdb/$predicate";}
		my $predFile=getFileFromPredicate($predicate);
		my $time1=$command->{"timestamp"};
		my $time2=checkTimestamp($predFile);
		if($time1<$time2){$hit=1;$command->{"timestamp"}=$time2;}
	}
	return $hit;
}
############################## downloadOutputs ##############################
sub downloadOutputs{
	my $command=shift();
	my $process=shift();
	if(!exists($process->{$urls->{"daemon/serverpath"}})){return;}
	my $serverpath=$command->{$urls->{"daemon/serverpath"}};
	my $url=$process->{$urls->{"daemon/command"}};
	my $rootdir=$process->{$urls->{"daemon/rootdir"}};
	foreach my $output(@{$command->{"output"}}){
		if(!exists($process->{"$url#$output"})){next;}
		my $outputFile=$process->{"$url#$output"};
		my $fromFile="$serverpath/$outputFile";
		my $toFile="$rootdir/$outputFile";
		if(defined($opt_l)){print "#Downloading: $fromFile => $toFile\n";}
		system("scp $fromFile $toFile 2>&1 1>/dev/null");
	}
}
############################## encodeScripts ##############################
sub encodeScripts{
	my @scripts=@_;
	my @codes=();
	foreach my $script(@scripts){
		my $filename=basename($script);
		my @lines=();
		open(IN,$script);
		while(<IN>){
			chomp;
			push(@lines,$_);
		}
		close(IN);
		my $code="{\"".$urls->{"daemon/script/name"}."\":\"$filename\",";
		$code.="\"".$urls->{"daemon/script/code"}."\":".jsonEncode(\@lines)."}";
		push(@codes,$code);
	}
	my $line="\"".$urls->{"daemon/script"}."\":";
	if(scalar(@codes)>1){$line.="[".join(",",@codes)."]";}
	else{$line.=join(",",@codes);}
	return $line;
}
############################## existsArray ##############################
sub existsArray{
	my $array=shift();
	my $value=shift();
	foreach my $val(@{$array}){if($value eq $val){return 1;}}
	return;
}
############################## existsLogFile ##############################
sub existsLogFile{
	my $file=shift();
	if(-e $file){return 1;}
	if(-e "$file.gz"){return 1;}
	if(-e "$file.bz2"){return 1;}
	return 0;
}
############################## existsString ##############################
sub existsString{
	my $string=shift();
	my $lines=shift();
	foreach my $line(@{$lines}){if($line=~/$string/){return 1;}}
}
############################## fileExists ##############################
sub fileExists{
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){my $result=`ssh $1 'if [ -e $2 ]; then echo 1; fi'`;chomp($result);return ($result==1);}
	elsif(-e $path){return 1;}
	return;
}
############################## fileStats ##############################
sub fileStats{
	my $path=shift();
	my $line=shift();
	my $hash=shift();
	if(!defined($hash)){$hash={};}
	my @variables=("linecount","seqcount","filesize","filecount","md5","timestamp","owner","group","permission");
	my $matches={};
	if(defined($line)){foreach my $v(@variables){if($line=~/\$\{$v\}/||$line=~/\$$v/){$matches->{$v}=1;}}}
	foreach my $key(keys(%{$matches})){
		my @stats=stat($path);
		if($key eq "filesize"){$hash->{$key}=$stats[7];}
		elsif($key eq "md5"&&defined($md5cmd)){my $md5=`$md5cmd<$path`;chomp($md5);$hash->{$key}=$md5;}
		elsif($key eq "timestamp"){$hash->{$key}=$stats[9];}
		elsif($key eq "owner"){$hash->{$key}=getpwuid($stats[4]);}
		elsif($key eq "group"){$hash->{$key}=getgrgid($stats[5]);}
		elsif($key eq "permission"){$hash->{$key}=$stats[2]&07777;}
		elsif($key eq "filecount"){if(!(-f $path)){$hash->{$key}=0;}else{my $count=`ls $path|wc -l`;chomp($count);$hash->{$key}=$count;}}
		elsif($key eq "linecount"){$hash->{$key}=linecount($path);}
		elsif($key eq "seqcount"){$hash->{$key}=seqcount($path);}
	}
	return $hash;
}
############################## getBash ##############################
sub getBash{
	my $url=shift();
	my $suffixs=shift();
	my $userdefined=shift();
	my $content=($url=~/https?:\/\//)?getHttpContent($url):readFileContent($url);
	if($content eq ""){print STDERR "#Couldn't load bash script '$url'\n";exit(1);}
	my $command={};
	my @lines=();
	foreach my $line(split(/\n/,$content)){
		if($line=~/^#\$\s?-c\s+?(.+)$/){$command->{$urls->{"daemon/container"}}=$1;}
		elsif($line=~/^#\$\s?-d\s+?(.+)$/){$command->{$urls->{"daemon/rdfdb"}}=$1;}
		elsif($line=~/^#\$\s?-f\s+?(.+)$/){$command->{$urls->{"daemon/file/stats"}}=$1;}
		elsif($line=~/^#\$\s?-E\s+?(.+)$/){$command->{$urls->{"daemon/error/stderr/ignore"}}=$1;}
		elsif($line=~/^#\$\s?-i\s+?(.+)$/){$command->{$urls->{"daemon/input"}}=$1;}
		elsif($line=~/^#\$\s?-o\s+?(.+)$/){$command->{$urls->{"daemon/output"}}=$1;}
		elsif($line=~/^#\$\s?-O\s+?(.+)$/){$command->{$urls->{"daemon/error/stdout/ignore"}}=$1;}
		elsif($line=~/^#\$\s?-q\s+?(.+)$/){$command->{$urls->{"daemon/qjob"}}=$1;}
		elsif($line=~/^#\$\s?-Q\s+?(.+)$/){$command->{$urls->{"daemon/qjob/opt"}}=$1;}
		elsif($line=~/^#\$\s?-r\s+?(.+)$/){$command->{$urls->{"daemon/return"}}=$1;}
		elsif($line=~/^#\$\s?-v\s+?(.+)$/){$command->{$urls->{"daemon/volume"}}=$1;}
		elsif($line=~/^#\$\s?-X\s+?(.+)$/){$command->{$urls->{"daemon/suffix"}}=handleSuffix($1);}
		elsif($line=~/^#\$\s?(.+)\=(.+)$/){
			if(!exists($command->{$urls->{"daemon/userdefined"}})){$command->{$urls->{"daemon/userdefined"}}={};}
			$command->{$urls->{"daemon/userdefined"}}->{$1}=$2;
		}else{push(@lines,$line);}
	}
	$command->{$urls->{"daemon/bash"}}=\@lines;
	my ($inputKeys,$queryIn)=handleInputOutput($command->{$urls->{"daemon/input"}},$userdefined,$suffixs);
	if(defined($inputKeys)){$command->{$urls->{"daemon/input"}}=$inputKeys;}
	if(defined($queryIn)){$command->{$urls->{"daemon/query/in"}}=$queryIn;}
	my ($outputKeys,$queryOut)=handleInputOutput($command->{$urls->{"daemon/output"}},$userdefined,$suffixs);
	if(defined($outputKeys)){$command->{$urls->{"daemon/output"}}=$outputKeys;}
	if(defined($queryOut)){$command->{$urls->{"daemon/query/out"}}=$queryOut;}
	return $command;
}
############################## getContentMd5 ##############################
sub getContentMd5{
	my $content=shift();
	my ($writer,$temp)=tempfile();
	print $writer "$content";
	close($writer);
	my $md5=`$md5cmd<$temp`;
	chomp($md5);
	return $md5;
}
############################## getDate ##############################
sub getDate{
	my $delim=shift;
	my $time=shift;
	if(!defined($delim)){$delim="";}
	if(!defined($time)||$time eq ""){$time=localtime();}
	else{$time=localtime($time);}
	my $year=$time->year+1900;
	my $month=$time->mon+1;
	if($month<10){$month="0".$month;}
	my $day=$time->mday;
	if($day<10){$day="0".$day;}
	return $year.$delim.$month.$delim.$day;
}
############################## getDatetime ##############################
sub getDatetime{my $time=shift;return getDate("",$time).getTime("",$time);}
############################## getDirs ##############################
sub getDirs{
	my $directory=shift();
	my $grep=shift();
	my @dirs=();
	opendir(DIR,$directory);
	foreach my $file(readdir(DIR)){
		if($file=~/^\./){next;}
		if($file eq ""){next;}
		my $path="$directory/$file";
		if(!-d $path){next;}
		if(defined($grep)&&$path!~/$grep/){next;}
		push(@dirs,$path);
	}
	closedir(DIR);
	return @dirs;
}
############################## readFileContent ##############################
sub readFileContent{
	my $path=shift();
	my $reader=openFile($path);
	my $content;
	while(<$reader>){s/\r//g;$content.=$_;}
	close($reader);
	return $content;
}
############################## getFileFromExecid ##############################
sub getFileFromExecid{
	my $execid=shift();
	my $dirname=substr(substr(basename($execid,".txt"),-18),0,8);
	if(-e "$errordir/$execid.txt"){return "$errordir/$execid.txt";}
	elsif(-e "$logdir/$dirname/$execid.txt"){return "$logdir/$dirname/$execid.txt";}
	elsif(-e "$logdir/$dirname.tgz"){return "$logdir/$dirname.tgz";}
}
############################## getFileFromPredicate ##############################
sub getFileFromPredicate{
	my $predicate=shift();
	my $anchor;
	if($predicate=~/^(https?):\/\/(.+)$/){$predicate="$1/$2";}
	elsif($predicate=~/^(.+)\@(.+)\:(.+)/){$predicate="ssh/$1/$2/$3";}
	if($predicate=~/^(.+)#(.+)$/){$predicate=$1;$anchor=$2;}
	if($predicate=~/^(.+)\.json$/){$predicate=$1;}
	if($predicate=~/^(.*)\%/){
		$predicate=$1;
		if($predicate=~/^(.+)\//){return "$dbdir/$1";}
		else{return $dbdir;}
	}elsif(defined($anchor)){return "$dbdir/$predicate.txt";}
	elsif(-e "$dbdir/$predicate.txt.gz"){return "$dbdir/$predicate.txt.gz";}
	elsif(-e "$dbdir/$predicate.txt.bz2"){return "$dbdir/$predicate.txt.bz2";}
	else{return "$dbdir/$predicate.txt";}
}
############################## getFileKeyFromKeys ##############################
sub getFileKeyFromKeys{
	my $keys=shift();
	my @values=();
	foreach my $key(@{$keys}){if($key=~/\*/){push(@values,$key);}}
	my $size=scalar(@values);
	if($size>1){
		print STDERR "ERROR: Can't have multiple file keys...\n";
		foreach my $value(@values){print STDERR "       $value\n";}
		exit(1);
	}elsif($size==1){return $values[0];}
}
############################## getFiles ##############################
sub getFiles{
	my $directory=shift();
	my $grep=shift();
	my @files=();
	opendir(DIR,$directory);
	if(ref($grep)eq"ARRAY"){
		foreach my $file(readdir(DIR)){
			if($file=~/^\./){next;}
			if($file eq ""){next;}
			my $path="$directory/$file";
			if(-d $path){next;}
			my $hit=0;
			foreach my $g(@{$grep}){if($path=~/$g/){$hit=1;}}
			if($hit){push(@files,$path);}
		}
	}else{
		foreach my $file(readdir(DIR)){
			if($file=~/^\./){next;}
			if($file eq ""){next;}
			my $path="$directory/$file";
			if(-d $path){next;}
			if(defined($grep)&&$path!~/$grep/){next;}
			push(@files,$path);
		}
	}
	closedir(DIR);
	return @files;
}
############################## getHistory ##############################
sub getHistory{
	my $history={};
	my @files=listFilesRecursively("\.txt\$",undef,3,$logdir);
	foreach my $file(@files){
		my $execid=basename($file,".txt");
		$history->{$execid}={};
		$history->{$execid}->{"variable"}={};
		$history->{$execid}->{"command"}=[];
		$history->{$execid}->{"stderr"}=[];
		$history->{$execid}->{"stdout"}=[];
		my $reader=openFile($file);
		my $flag=0;
		while(<$reader>){
			chomp;
			if(/^\#{40} (.+) \#{40}$/){
				if($1 eq $execid){$flag=1;next;}
				elsif($1 eq "stderr"){$flag=2;next;}
				elsif($1 eq "stdout"){$flag=3;next;}
				elsif($1 eq "log"){$flag=4;next;}
				else{$flag=0;last;}
			}
			if($flag==1){
				my ($key,$val)=split(/\t/);
				if($key eq $urls->{"daemon/execute"}){$history->{$execid}->{"execute"}=$val;}
				elsif($key eq $urls->{"daemon/processtime"}){$history->{$execid}->{"processtime"}=$val;}
				elsif($key eq $urls->{"daemon/timestarted"}){$history->{$execid}->{"timestarted"}=$val;}
				elsif($key eq $urls->{"daemon/timeended"}){$history->{$execid}->{"timeended"}=$val;}
				elsif($key eq $urls->{"daemon/command"}){$history->{$execid}->{"command"}=$val;}
				elsif($key=~/\.json#(.+)/){$key=$1;$history->{$execid}->{"variable"}->{$key}=$val;}
			}
			elsif($flag==2){push(@{$history->{$execid}->{"stderr"}},$_);}
			elsif($flag==3){push(@{$history->{$execid}->{"stdout"}},$_);}
		}
		while(<$reader>){
			chomp;
			if(/^\#{10} (.+) \#{10}$/){if($1 eq "command"){$flag=1;}else{$flag=0;}}
			elsif(/^\#{29}$/){$flag=0;}
			elsif($flag==1){
				foreach my $key(keys(%{$history->{$execid}->{"variable"}})){
					my $val=$history->{$execid}->{"variable"}->{$key};
					$_=~s/\$$key/$val/g;
					$_=~s/\$\{$key\}/$val/g;
				}
				push(@{$history->{$execid}->{"commandline"}},$_);
			}
		}
		close($reader);
	}
	return $history;
}
############################## getHttpContent ##############################
sub getHttpContent{
	my $url=shift();
	my $content=`curl -m 2 $url`;
	chomp($content);
	return $content;
}
############################## getInputsOutputsFromCommand ##############################
sub getInputsOutputsFromCommand{
	my $cmdline=shift();
	my $userdefined=shift();
	my $inputKeys=shift();
	my $outputKeys=shift();
	my $suffixs=shift();
	my @inputs=();
	my @outputs=();
	my $variables={};
	foreach my $variable(@{$inputKeys}){
		$variables->{$variable}="input";
	}
	foreach my $variable(@{$outputKeys}){
		$variables->{$variable}="output";
	}
	while($cmdline=~/\$([\w\_]+)/g){
		my $variable=$1;
		if(!exists($variables->{$variable})){$variables->{$variable}=1;}
	}
	foreach my $variable(keys(%{$variables})){if($cmdline=~/\s*\>\s*\$$variable/){$variables->{$variable}="output";}}
	foreach my $variable(sort{$a cmp $b}keys(%{$variables})){
		if($variables->{$variable}!=1){next;}
		print "\$$variable is [I]nput/[O]utput? ";
		while(<STDIN>){
			chomp();
			if(/^i/i){$variables->{$variable}="input";last;}
			elsif(/^o/i){$variables->{$variable}="output";last;}
			print "Please type 'i' or 'o' only\n";
			print "\$$variable is [I]nput/[O]utput? ";
		}
	}
	if(!defined($suffixs)){$suffixs={};}
	my $files={};
	while($cmdline=~/([\w\_\/\.]+\.(\w{2,4}))($|\s)/g){
		my $file=$1;
		if(!exists($files->{$file})){$files->{$file}=1;}
	}
	foreach my $file(keys(%{$files})){if($cmdline=~/\s*\>\s*$file/){$files->{$file}="output";}}
	foreach my $file(sort{$a cmp $b}keys(%{$files})){
		if($files->{$file}!=1){next;}
		print "$file is [I]nput/[O]utput? ";
		while(<STDIN>){
			chomp();
			if(/^i/i){$files->{$file}="input";last;}
			elsif(/^o/i){$files->{$file}="output";last;}
			print "Please type 'i' or 'o' only\n";
			print "$file is [I]nput/[O]utput? ";
		}
	}
	while(my ($file,$type)=each(%{$files})){
		my $name;
		if($type eq "input"){
			$name="in".(scalar(@inputs)+1);
			push(@inputs,$name);
			if($file=~/(\.\w{3,4})$/){$suffixs->{$name}=$1;}
		}elsif($type eq "output"){
			$name="out".(scalar(@outputs)+1);
			push(@outputs,$name);
			if($file=~/(\.\w{3,4})$/){$suffixs->{$name}=$1;}
		}else{next;}
		$cmdline=~s/$file/\$$name/g;
		$userdefined->{$name}=$file;
	}
	#Specify text=>variable before variable
	while(my ($variable,$type)=each(%{$variables})){
		if($type eq "input"){push(@inputs,$variable);}
		if($type eq "output"){push(@outputs,$variable);}
	}
	push(@{$inputKeys},@inputs);
	push(@{$outputKeys},@outputs);
	return ($cmdline,$inputKeys,$outputKeys,$suffixs);
}
############################## getJson ##############################
sub getJson{
	my $url=shift();
	my $content=($url=~/https?:\/\//)?getHttpContent($url):readFileContent($url);
	return jsonDecode($content);
}
############################## getKeysFromQuery ##############################
sub getKeysFromQuery{
	my $queryKeys=shift();
	my $keys={};
	foreach my $query(@{$queryKeys}){
		if(ref($query)eq"ARRAY"){foreach my $q(@{$query}){if($q=~/^\$(.+)$/){$keys->{$1}=1;}}}
		elsif($query=~/^\$(.+)$/){$keys->{$1}=1;}
		else{$keys->{$query}=1;}
	}
	my @array=sort{$a cmp $b}keys(%{$keys});
	return \@array;
}
############################## getNumberOfJobsRemaining ##############################
sub getNumberOfJobsRemaining{
	my @greps=@_;
	my @files=();
	push(@files,getFiles($jobdir,\@greps));
	return scalar(@files);
}
############################## getNumberOfJobsRunning ##############################
sub getNumberOfJobsRunning{
	my @files=getFiles($processdir);
	return scalar(@files);
}
############################## getQueryResults ##############################
sub getQueryResults{
	my $dbdir=shift();
	my $query=shift();
	my @queries=ref($query)eq"ARRAY"?@{$query}:split(/,/,$query);
	foreach my $line(@queries){if(ref($line)eq"ARRAY"){$line=join("->",@{$line});}}
	my $command="perl $prgdir/rdf.pl -d $dbdir -f json query '".join("' '",@queries)."'";
	my $result=`$command`;chomp($result);
	my $hashs=jsonDecode($result);
	my $keys=retrieveKeysFromQueries($query);
	return [$keys,$hashs];
}
############################## getTime ##############################
sub getTime{
	my $delim=shift;
	my $time=shift;
	if(!defined($delim)){$delim="";}
	if(!defined($time)||$time eq ""){$time=localtime();}
	else{$time=localtime($time);}
	my $hour=$time->hour;
	if($hour<10){$hour="0".$hour;}
	my $minute=$time->min;
	if($minute<10){$minute="0".$minute;}
	my $second=$time->sec;
	if($second<10){$second="0".$second;}
	return $hour.$delim.$minute.$delim.$second;
}
############################## getYesOrNo ##############################
sub getYesOrNo{
	my $prompt=<STDIN>;
	chomp($prompt);
	if($prompt eq "y"||$prompt eq "yes"||$prompt eq "Y"||$prompt eq "YES"){return 1;}
	return;
}
############################## handleArguments ##############################
sub handleArguments{
	my @arguments=@_;
	my $variables={};
	my @array=();
	my $index;
	for($index=scalar(@arguments)-1;$index>=0;$index--){
		my $argument=$arguments[$index];
		if($argument=~/\;$/){last;}
		elsif($argument=~/^(\$?\w+)\=(.+)$/){
			my $key=$1;
			my $val=$2;
			if($key=~/^\$(.+)$/){$key=$1;}
			$variables->{$key}=$val;
		}else{last;}
	}
	for(my $i=0;$i<=$index;$i++){push(@array,$arguments[$i]);}
	return (\@array,$variables);
}
############################## handleArray ##############################
sub handleArray{
	my $array=shift();
	my $defaults=shift();
	if(!defined($defaults)){$defaults={};}
	if(!defined($array)){return [];}
	if(ref($array)ne"ARRAY"){
		if($array=~/,/){my @temp=split(/,/,$array);$array=\@temp;}
		else{$array=[$array];}
	}
	my @temps=();
	foreach my $variable(@{$array}){
		if(ref($variable)eq"HASH"){
			foreach my $key(keys(%{$variable})){
				my $value=$variable->{$key};
				if($key=~/^\$(.+)$/){$key=$1;}
				push(@temps,$key);
				$defaults->{$key}=$value;
			}
			next;
		}elsif($variable=~/^\$(.+)$/){$variable=$1;}
		push(@temps,$variable)
	}
	return \@temps;
}
############################## handleCode ##############################
sub handleCode{
	my $code=shift();
	if(ref($code) eq "ARRAY"){return $code;}
	my @lines=split(/\n/,$code);
	return \@lines;
}
############################## handleHash ##############################
sub handleHash{
	my @array=@_;
	my $hash={};
	foreach my $input(@array){$hash->{$input}=1;}
	return $hash;
}
############################## handleInputOutput ##############################
# split ,
# split ->fuserdefined
# handles suffix $input.txt
# Remove $ from variable
# Replace predicate with userdefined if defined
sub handleInputOutput{
	my $statement=shift();
	my $userdefined=shift();
	my $suffixs=shift();
	my $triples;
	my $keys=[];
	my @statements;
	if(ref($statement) eq "ARRAY"){@statements=@{$statement};}
	elsif($statement=~/^\{.+\}$/){#in json format
		my $json=jsonDecode($statement);
		foreach my $key(sort{$a cmp $b}keys(%{$json})){
			my $value=$json->{$key};
			if($key=~/^\$(.+)$/){$key=$1;}
			if(ref($value)eq"HASH"){
				foreach my $key2(keys(%{$value})){
					my $value2=$value->{$key2};
					if($key2=~/^default$/){
						if(!defined($userdefined)){$userdefined={};}
						if(!exists($userdefined->{$key})){$userdefined->{$key}=$value2;}
					}
					if($key2=~/^suffix$/){
						if(!defined($suffixs)){$suffixs={};}
						if(!exists($suffixs->{$key})){$suffixs->{$key}=$value2;}
					}
				}
			}else{
				if($key=~/^\$(.+)$/){$key=$1;}
				if(!defined($userdefined)){$userdefined={};}
				if(!exists($userdefined->{$key})){$userdefined->{$key}=$value;}
			}
			if(!existsArray($keys,$key)){push(@{$keys},$key);}
		}
		return wantarray?($keys,$triples,$userdefined,$suffixs):$keys;
	}else{@statements=split(",",$statement);}
	foreach my $line(@statements){
		my @tokens=split(/\-\>/,$line);
		if(scalar(@tokens)==3){
			if(defined($userdefined)){
				while(my($key,$val)=each(%{$userdefined})){$tokens[1]=~s/\$$key/$val/g;}
			}
			if($tokens[2]=~/^\$(\w+)(\.\w{3,4})/){
				if(!defined($suffixs)){$suffixs={};}
				$suffixs->{$1}=$2;
				$tokens[2]="\$$1";
			}
			foreach my $token(@tokens){if($token=~/^\$(.+)$/){
				my $variable=$1;
				if(!existsArray($keys,$variable)){push(@{$keys},$variable);}}
			}
			if(!defined($triples)){$triples=[];}
			push(@{$triples},\@tokens);
		}elsif(scalar(@tokens)!=1){
			print STDERR "ERROR: '$statement' has empty token or bad notation.\n";
			print STDERR "ERROR: Use single quote '\$a->b->\$c' instead of double quote \"\$a->b->\$c\".\n";
			print STDERR "ERROR: Or escape '\$' with '\\' sign \"\\\$a->b->\\\$c\".\n";
			exit(1);
		}else{
			my $variable=$tokens[0];
			if($variable=~/^\$(\w+)(\.\w{3,4})/){
				if(!defined($suffixs)){$suffixs={};}
				$variable=$1;
				$suffixs->{$1}=$2;
			}elsif($variable=~/^\$(.+)$/){$variable=$1;}
			if(!existsArray($keys,$variable)){push(@{$keys},$variable);}
		}
	}
	return wantarray?($keys,$triples,$userdefined,$suffixs):$keys;
}
############################## handleKeys ##############################
sub handleKeys{
	my $line=shift();
	my @keys=split(/,/,$line);
	foreach my $key(@keys){if($key=~/^\$(.+)$/){$key=$1;}}
	return \@keys;
}
############################## handleKeys ##############################
sub handleKeys{
	my $line=shift();
	my @keys=split(/,/,$line);
	foreach my $key(@keys){if($key=~/^\$(.+)$/){$key=$1;}}
	return \@keys;
}
############################## handleScript ##############################
sub handleScript{
	my $command=shift();
	my $scripts=$command->{$urls->{"daemon/script"}};
	if(ref($scripts)ne"ARRAY"){$scripts=[$scripts];}
	foreach my $script(@{$scripts}){
		my $name=$script->{$urls->{"daemon/script/name"}};
		my $code=$script->{$urls->{"daemon/script/code"}};
		if(ref($code)ne"ARRAY"){$code=[$code];}
		$command->{$name}=$code;
		push(@{$command->{"script"}},$name);
	}
	$command->{$urls->{"daemon/script"}}=$scripts;
}
############################## handleServer ##############################
sub handleServer{
	my $line=shift();
	my $username;
	my $servername;
	my $serverdir;
	if($line=~/^(.+)\@(.+)\:(.+)$/){$username=$1;$servername=$2;$serverdir=$3;}
	elsif($line=~/^(.+)\@(.+)$/){$username=$1;$servername=$2;}
	else{$username=`whoami`;chomp($username);$servername=$line;}
	if(!defined($serverdir)){$serverdir="/home/$username";}
	else{$serverdir="/home/$username/$serverdir";}
	if(system("ssh $username\@$servername hostname > /dev/null")){
		print STDERR "ERROR: Couldn't login with '$username\@$servername'.\n";
		exit(1);
	}
	if(system("ssh $username\@$servername mkdir -p $serverdir/.moirai2server")){
		print STDERR "ERROR: Couldn't create '$username\@$servername:$serverdir/.moirai2server' directory.\n";
		exit(1);
	}
	return "$username\@$servername:$serverdir";
}
############################## handleSuffix ##############################
sub handleSuffix{
	my $string=shift();
	my $suffixs=shift();
	if(!defined($suffixs)){$suffixs={};}
	my @lines=split(/,/,$string);
	foreach my $line(@lines){if($line=~/^(\w+)(.\w+)/){$suffixs->{$1}=$2;}}
	return $suffixs;
}
############################## helpMenu ##############################
sub helpMenu{
	my $command=shift();
	if($command=~/^command$/i){helpCommand();}
	elsif($command=~/^build$/i){helpBuild();}
	elsif($command=~/^daemon$/i){helpDaemon();}
	elsif($command=~/^exec$/i){helpExec();}
	elsif($command=~/^html$/i){helpHtml();}
	elsif($command=~/^history$/i){helpHistory();}
	elsif($command=~/^ls$/i){helpLs();}
	elsif($command=~/^sortsubs$/i){helpSortSubs();}
	elsif($command=~/^test$/i){helpTest();}
	elsif($command=~/\.json$/){printCommand($command);}
	elsif($command=~/\.(ba)?sh$/){printCommand($command);}
	else{help();}
}
sub helpDaemon{
	print "\n";
	print "Program: Runs an automate bash script with moirai2 'command' lines.\n";
	print "\n";
	print "Usage: perl $program_name\n";
	print "\n";
	print "Options: -a  (A)ccess server (default='local').\n";
	print "         -d  RDF database directory (default='.').\n";
	print "\n";
	print "Note:  '-a' enables daemon to run on user specified server and checks this server\n";
	print "\n";
}
sub helpBuild{
	print "\n";
	print "Program: Build a command JSON file from command LINES and scripts.\n";
	print "\n";
	print "Usage: perl $program_name [Options] build";
	print "\n";
	print "Options:\n";
	print "         -i  (I)nput query for select from database in '\$sub->\$pred->\$obj' format.\n";
	print "         -o  (O)utput query for insert to database in '\$sub->\$pred->\$obj' format.\n";
	print "         -r  Print (r)eturn value (in exec mode, stdout is default).\n";
	print "         -S  Implement/import (s)cript code to a command json file.\n";
	print "\n";
}
sub helpCommand{
	print "\n";
	print "Usage: perl $program_name [Options] command [ASSIGN ..] << 'EOS'\n";
	print "COMMAND ..\n";
	print "COMMAND2 ..\n";
	print "EOS\n";
	print "\n";
	print "     ASSIGN  Assign a MOIRAI2 variables with '\$VAR=VALUE' format.\n";
	print "    COMMAND  Bash command lines to execute.\n";
	print "        EOS  Assign command lines with Unix's heredoc.\n";
	print "\n";
	print "Options: -a  (A)ccess server and compute (default=local computer).\n";
	print "         -b  Specify (b)oolean options when running a command line (example -a:\$optionA,-b:\$optionB).\n\n";
	print "         -c  Use (c)ontainer image for execution [docker|singularity].\n";
	print "         -d  Moirai (d)atabase directory (default='.').\n";
	print "         -D  Delim character used to split sub->pre->obj file\n";
	print "         -E  Ignore STD(E)RR if specific regexp is found.\n";
	print "         -f  Record (f)ilestats[linecount/seqcount/md5/filesize/utime] of input/output files.\n";
	print "         -F  If specified output (f)ile is empty, record as error.\n";
	print "         -h  Show (h)elp message.\n";
	print "         -H  Show update (h)istory.\n";
	print "         -i  (I)nput query for select from database in '\$sub->\$pred->\$obj' format.\n";
	print "         -I  (I)mage of OpenStack instance.\n";
	print "         -l  Show (l)ogs from moirai.pl.\n";
	print "         -m  (M)ax number of jobs to throw (default='5').\n";
	print "         -o  (O)utput query for insert to database in '\$sub->\$pred->\$obj' format.\n";
	print "         -O  Ignore STD(O)UT if specific regexp is found.\n";
	print "         -p  (P)rint command lines instead of executing.\n";
	print "         -q  Use (q)sub or slurm for throwing jobs [qsub|slurm].\n";
	print "         -Q  (Q)sub/slurm options [qsub/sge/squeue/slurm].\n";
	print "         -r  Print (r)eturn value (in exec mode, stdout is default).\n";
	print "         -s  Loop (s)econd (default='10').\n";
	print "         -S  Implement/import (s)cript code to a command json file.\n";
	print "         -v  (V)olume to rsync with the server.\n";
	print "         -V  Fla(v)or of Openstack instance to create.\n";
	print "         -u  Run in (U)ser mode where input parameters are prompted.\n";
	print "         -w  Don't (w)ait.\n";
	print "         -X  Set suffixs (like '\$output.txt').\n";
	print "         -Z  Create done file to signal completion to daemon.\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "(1) perl $program_name -o 'root->input->\$output' command << 'EOS'\n";
	print "output=(`ls`)\n";
	print "EOS\n";
	print "\n";
	print "  - ls and store them in database with root->input->\$output format.\n";
	print "  - When you want an array, be sure to quote with ().\n";
	print "\n";
	print "(2) echo 'output=(`ls`)'|perl $program_name -o 'root->input->\$output' command\n";
	print "\n";
	print "  - It is same as example1, but without using 'EOS' notation.\n";
	print "\n";
	print "(3) perl $program_name -i 'A->input->\$input' -o 'A->output->\$output' command << 'EOS'\n";
	print "output=sort/\${input.basename}.txt\n";
	print "sort \$input > \$output\n";
	print "EOS\n";
	print "\n";
	print "  - Does sort on the \$input and creates a sorted file \$output\n";
	print "  - Query database with 'A->input->\$input' and store new triple 'A->output->\$output'.\n";
	print "\n";
}
sub helpExec{
	print "\n";
	print "############################## helpExec ##############################\n";
	print "\n";
	print "Program: Execute one line command.\n";
	print "\n";
	print "Usage: perl $program_name [Options] exec CMD ..\n";
	print "\n";
	print "       CMD  One line command like 'ls'.\n";
	print "\n";
	print "Options: -a  (A)ccess server and compute (default=local computer).\n";
	print "         -c  Use (c)ontainer image for execution [docker|singularity].\n";
	print "         -d  Moirai (d)atabase directory (default='.').\n";
	print "         -D  Delim character used to split sub->pre->obj file\n";
	print "         -f  Record (f)ilestats[linecount/seqcount/md5/filesize/utime] of input/output files.\n";
	print "         -F  If specified output (f)ile is empty, record as error.\n";
	print "         -h  Show (h)elp message.\n";
	print "         -H  Show update (h)istory.\n";
	print "         -i  (I)nput query for select from database in '\$sub->\$pred->\$obj' format.\n";
	print "         -I  (I)mage of Openstack instance to create.\n";
	print "         -l  Show (l)ogs from moirai.pl.\n";
	print "         -m  (M)ax number of jobs to throw (default='5').\n";
	print "         -o  (O)utput query for insert to database in '\$sub->\$pred->\$obj' format.\n";
	print "         -p  (P)rint command lines instead of executing.\n";
	print "         -q  Use (q)sub or slurm for throwing jobs [qsub|slurm].\n";
	print "         -Q  (Q)sub/slurm options [qsub/sge/squeue/slurm].\n";
	print "         -r  Print (r)eturn value (in exec mode, stdout is default).\n";
	print "         -s  Loop (s)econd (default='10').\n";
	print "         -S  Implement/import (s)cript code to a command json file.\n";
	print "         -v  (V)olume to rsync with the server.\n";
	print "         -V  Fla(v)or of Openstack instance to create.\n";
	print "         -u  Run in (U)ser mode where input parameters are prompted.\n";
	print "         -w  Don't (w)ait.\n";
	print "\n";
	print "Note: Log file (including execution time, STDOUT, STDERR) stored under moirai/log/YYYYMMDD/ directory\n";
	print "      Error files will be stored under moirai/log/error/ directory\n";
	print "\n";
	print "Example:\n";
	print "(1) perl $program_name exec uname\n";
	print "  - Return uname result\n";
	print "\n";
	print "(2) perl $program_name exec 'ls | cut -c1-3 | sort | uniq | wc -l'\n";
	print "  - Execute piped command line using single quotes\n";
	print "\n";
	print "(3) perl $program_name exec 'ls > output.txt'\n";
	print "  - Write file lists to output files\n";
	print "\n";
	print "(4) perl $program_name -q sge exec ls -lt\n";
	print "  - List files under current directory using Sun Grid Engine (SGE) qsub\n";
	print "\n";
	print "(5) perl $program_name -a ah3q\@dgt-ac4 exec echo hello world\n";
	print "  - Returns 'hello world' at dgt-ac4 server\n";
	print "\n";
	print "(6) perl $program_name -q slurm -a ah3q\@dgt-ac4 exec ls -lt /work/ah3q/\n";
	print "  - List files under /work/ah3q at dgt-ac4 server using slurm queing system\n";
	print "\n";
	print "(7) perl $program_name -o '\$output' exec 'output=(`ls`)'\n";
	print "  - List directory and store results in \$output array\n";
	print "\n";
}
sub helpHtml{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Print out a HTML representation of the database.\n";
	print "\n";
	print "Usage: perl $program_name [Options] > HTML\n";
	print "\n";
	print "       HTML  HTML page displaying information of the database\n";
	print "\n";
	print "Options: -d  Moirai (d)atabase directory (default='.').\n";
	print "\n";
}
sub helpLs{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: List files/directories and store path information to DB.\n";
	print "\n";
	print "Usage: perl $program_name [Options] ls DIR [DIR2] ..\n";
	print "\n";
	print "        DIR  Directory to search for (if not specified, DIR='.').\n";
	print "\n";
	print "Options: -d  RDF database directory (default='.').\n";
	print "         -D  Delim character (None alphabe/number characters + _)\n";
	print "         -g  grep specific string\n";
	print "         -G  ungrep specific string\n";
	print "         -i  Input query for select in '\$sub->\$pred->\$obj' format.\n";
	print "         -o  Output query for insert in '\$sub->\$pred->\$obj' format.\n";
	print "         -r  Recursive search (default=0)\n";
	print "         -x  E(x)ecute data insert instead of showing output.\n";
	print "\n";
	print "Variables:\n";
	print "  \$file        Path to a file\n";
	print "  \$path        Full path to a file\n";
	print "  \$directory   dirname\n";
	print "  \$filename    filename\n";
	print "  \$basename    Without suffix\n";
	print "  \$suffix      suffix without period\n";
	print "  \$dirX        X=int directory name separated by '/'\n";
	print "  \$baseX       X=int filename sepsrsted by alphabet/number\n";
	print "  \$linecount   Print line count of a file (Can take care of gzip and bzip2).\n";
	print "  \$seqcount    Print sequence count of a FASTA/FASTQ files.\n";
	print "  \$filesize    Print size of a file.\n";
	print "  \$md5         Print MD5 of a file.\n";
	print "  \$timestamp   Print time stamp of a file.\n";
	print "  \$owner       Print owner of a file.\n";
	print "  \$group       Print group of a file.\n";
	print "  \$permission  Print permission of a file.\n";
	print "\n";
	print "Note:\n";
	print " - When -i option is used, search will be canceled and RDF value is used instead.\n";
	print " - Use \$file variable when using '-i' option for specifying a file path.\n";
	print " - When -x option to load results to the database instead of displaying.\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "(1) perl $program_name -r 0 -g A -G B -o '\$basename->id->\$path' ls DIR DIR2 ..\n";
	print "  - List files under DIR and DIR2 with 0 recursion and filename with A and filename without B.\n";
	print "\n";
	print "(2) perl $program_name -i 'root->input->\$file->' -o '\$basename->id->\$path' ls\n";
	print "  - Go look for file in the database and handle.\n";
	print "\n";
	print "(2) perl $program_name -o 'root->imageInput->\$path' -x ls image\n";
	print "  - Store file paths under image/ with specified RDF format.\n";
	print "\n";
}
sub helpTest{
	print "\n";
	print "Program: Runs moirai2 test commands for refactoring process.\n";
	print "\n";
	print "Usage: perl $program_name test\n";
	print "\n";
}
sub helpSortsubs{
	print "\n";
	print "Program: Sort subs.\n";
	print "\n";
	print "Usage: perl $program_name sortsubs\n";
	print "\n";
}
sub helpHistory{
	print "\n";
	print "Program: Similar to unix's history.\n";
	print "\n";
	print "Usage: perl $program_name test\n";
	print "\n";
}
############################## historyCommand ##############################
sub historyCommand{
	my @arguments=@_;
	if(scalar(@arguments)>0){
		foreach my $execid(@arguments){
			my $file=getFileFromExecid($execid);
			system("cat $file");
		}
		exit(0);
	}
	my @keys=("execid","status","command");
	my $history=getHistory();
	foreach my $execid(sort {$a cmp $b}keys(%{$history})){
		my @tokens=();
		foreach my $key(@keys){
			if($key eq "execid"){
				push(@tokens,$execid);
			}elsif($key eq "status"){
				my $status=$history->{$execid}->{"execute"};
				if($status eq "error"){$status="E";}
				else{$status=" ";}
				push(@tokens,$status);
			}elsif($key eq "command"){
				push(@tokens,join(";",@{$history->{$execid}->{"commandline"}}));
			}
		}	
		print join(" ",@tokens)."\n";
	}
}
############################## initExecute ##############################
sub initExecute{
	my $command=shift();
	my $vars=shift();
	if(!defined($command)){print STDERR "\$command not defined\n";exit(1);}
	if(!defined($vars)){print STDERR "\$vars not defined\n";exit(1);}
	my $url=$command->{$urls->{"daemon/command"}};
	my $execid=$vars->{"execid"};
	my $rootdir=$rootDir;#/Users/ah3q/Sites/moirai2
	my $moiraidir=$moiraidir;#.moirai
	my $workdir="$moiraidir/$execid";#.moirai2/eYYYYMMDDHHMMSS
	my $exportpath="$rootDir:$rootDir/bin:$rootDir/$moiraidir/bin:\$PATH";
	mkdir($workdir);
	chmod(0777,$workdir);
	$vars->{"base"}={};
	$vars->{"base"}->{"rootdir"}=$rootdir;
	$vars->{"base"}->{"moiraidir"}=$moiraidir;
	$vars->{"base"}->{"workdir"}=$workdir;
	$vars->{"base"}->{"tmpdir"}="$workdir/tmp";
	$vars->{"base"}->{"bashfile"}="$workdir/run.sh";
	$vars->{"base"}->{"stderrfile"}="$workdir/stderr.txt";
	$vars->{"base"}->{"stdoutfile"}="$workdir/stdout.txt";
	$vars->{"base"}->{"statusfile"}="$workdir/status.txt";
	$vars->{"base"}->{"logfile"}="$workdir/log.txt";
	$vars->{"base"}->{"exportpath"}=$exportpath;
	if(exists($command->{"script"})){$vars->{"base"}->{"exportpath"}="$rootdir/$workdir/bin:".$vars->{"base"}->{"exportpath"};}
	my @logs=();
	if(exists($command->{$urls->{"daemon/serverpath"}})){
		my $serverpath=$command->{$urls->{"daemon/serverpath"}};
		push(@logs,$urls->{"daemon/localdir"}."\t$workdir");
		push(@logs,$urls->{"daemon/serverpath"}."\t$serverpath");
		my ($username,$servername,$serverdir)=splitServerPath($serverpath);
		$workdir="$serverdir/.moirai2server/$execid";#/home/ah3q/.moirai2server/eYYYYMMDDHHMMSS
		$rootdir=$serverdir;#/home/ah3q
		$moiraidir="$serverdir/.moirai2server";#/home/ah3q/.moirai2server
		$exportpath="$workdir/bin:$serverdir/bin:$serverdir/.moirai2server/bin:\$PATH";
		$vars->{"server"}={};
		$vars->{"server"}->{"rootdir"}=$rootdir;
		$vars->{"server"}->{"moiraidir"}=$moiraidir;
		$vars->{"server"}->{"workdir"}=$workdir;
		$vars->{"server"}->{"tmpdir"}="$workdir/tmp";
		$vars->{"server"}->{"bashfile"}="$workdir/run.sh";
		$vars->{"server"}->{"stderrfile"}="$workdir/stderr.txt";
		$vars->{"server"}->{"stdoutfile"}="$workdir/stdout.txt";
		$vars->{"server"}->{"statusfile"}="$workdir/status.txt";
		$vars->{"server"}->{"logfile"}="$workdir/log.txt";
		$vars->{"server"}->{"exportpath"}=$exportpath;
		if(exists($command->{"script"})){$vars->{"server"}->{"exportpath"}="$serverdir/$workdir/bin:".$vars->{"server"}->{"exportpath"};}
		push(@logs,$urls->{"daemon/workdir"}."\t$username\@$servername:$workdir");
	}else{
		push(@logs,$urls->{"daemon/workdir"}."\t$workdir");
	}
	if(exists($command->{$urls->{"daemon/container"}})){
		my $container=$command->{$urls->{"daemon/container"}};
		if($container=~/\.sif$/){
			$vars->{"singularity"}={};
			$vars->{"singularity"}->{"rootdir"}=$rootdir;
			$vars->{"singularity"}->{"moiraidir"}=$moiraidir;
			$vars->{"singularity"}->{"workdir"}=$workdir;
			$vars->{"singularity"}->{"tmpdir"}="$workdir/tmp";
			$vars->{"singularity"}->{"bashfile"}="$workdir/run.sh";
			$vars->{"singularity"}->{"stderrfile"}="$workdir/stderr.txt";
			$vars->{"singularity"}->{"stdoutfile"}="$workdir/stdout.txt";
			$vars->{"singularity"}->{"statusfile"}="$workdir/status.txt";
			$vars->{"singularity"}->{"logfile"}="$workdir/log.txt";
			$vars->{"singularity"}->{"exportpath"}=$exportpath;
			if(exists($command->{"script"})){$vars->{"singularity"}->{"exportpath"}="$rootdir/$workdir/bin:".$vars->{"singularity"}->{"exportpath"};}
		}else{
			$rootdir="/root";
			my $moiraidir=exists($vars->{"server"})?"$rootdir/.moirai2server":"$rootdir/.moirai2";
			my $workdir="$moiraidir/$execid";
			$vars->{"docker"}={};
			$vars->{"docker"}->{"rootdir"}="/root";
			$vars->{"docker"}->{"moiraidir"}=$moiraidir;
			$vars->{"docker"}->{"workdir"}=$workdir;
			$vars->{"docker"}->{"tmpdir"}="$workdir/tmp";
			$vars->{"docker"}->{"bashfile"}="$workdir/run.sh";
			$vars->{"docker"}->{"stderrfile"}="$workdir/stderr.txt";
			$vars->{"docker"}->{"stdoutfile"}="$workdir/stdout.txt";
			$vars->{"docker"}->{"statusfile"}="$workdir/status.txt";
			$vars->{"docker"}->{"logfile"}="$workdir/log.txt";
			$vars->{"docker"}->{"exportpath"}="/root:/root/bin:$moiraidir/bin:\$PATH";
			if(exists($command->{"script"})){$vars->{"docker"}->{"exportpath"}="$rootdir/$workdir/bin:".$vars->{"docker"}->{"exportpath"};}
		}
	}
	my $datetime=`date +%s`;chomp($datetime);
	push(@logs,$urls->{"daemon/execute"}."\tregistered");
	push(@logs,$urls->{"daemon/timeregistered"}."\t$datetime");
	push(@logs,$urls->{"daemon/rootdir"}."\t$rootdir");
	writeLog($execid,@logs);
}
############################## isAllTriple ##############################
sub isAllTriple{
	my $query=shift();
	if(ref($query)ne"ARRAY"){return;}
	my $count1=0;
	my $count3=0;
	foreach my $array(@{$query}){
		if(ref($array)ne"ARRAY"){$count1++;}
		else{
			my $count=scalar(@{$array});
			if($count==3){$count3++;}
			else{print STDERR "ERROR: Query has non 3 entries\n";printTable($query);exit(1);}
		}
	}
	if($count1==0&&$count3>0){return 1;}
	elsif($count1>0&&$count3==0){return;}
	else{print STDERR "ERROR: Query has mix of 1 and 3 entries\n";printTable($query);exit(1);}
}
############################## jsonDecode ##############################
sub jsonDecode{
	my $text=shift();
	my @temp=split(//,$text);
	my $chars=\@temp;
	my $index=0;
	my $value;
	if($chars->[$index] eq "["){($value,$index)=toJsonArray($chars,$index+1);return $value;}
	elsif($chars->[$index] eq "{"){($value,$index)=toJsonHash($chars,$index+1);return $value;}
}
sub toJsonArray{
	my $chars=shift();
	my $index=shift();
	my $array=[];
	my $value;
	my $length=scalar(@{$chars});
	for(;$chars->[$index] ne "]"&&$index<$length;$index++){
		if($chars->[$index] eq "["){($value,$index)=toJsonArray($chars,$index+1);push(@{$array},$value);}
		elsif($chars->[$index] eq "{"){($value,$index)=toJsonHash($chars,$index+1);push(@{$array},$value);}
		elsif($chars->[$index] eq "\""){($value,$index)=toJsonStringDoubleQuote($chars,$index+1);push(@{$array},$value);}
		elsif($chars->[$index] eq "\'"){($value,$index)=toJsonStringSingleQuote($chars,$index+1);push(@{$array},$value);}
	}
	return ($array,$index);
}
sub toJsonHash{
	my $chars=shift();
	my $index=shift();
	my $hash={};
	my $key;
	my $value;
	my $length=scalar(@{$chars});
	for(my $findKey=1;$index<$length;$index++){
		if($chars->[$index] eq "}"){
			if(defined($value)){$hash->{$key}=$value;}
			last;
		}elsif($findKey==1){
			if($value ne ""){$hash->{$key}=$value;$value="";}
			if($chars->[$index] eq ":"){$key=chomp($key);$findKey=0;}
			elsif($chars->[$index] eq "\""){($key,$index)=toJsonStringDoubleQuote($chars,$index+1);$findKey=0;}
			elsif($chars->[$index] eq "\'"){($key,$index)=toJsonStringSingleQuote($chars,$index+1);$findKey=0;}
			elsif($chars->[$index]!~/^\s$/){$key.=$chars->[$index];}
		}else{
			if($chars->[$index] eq ":"){next;}
			elsif($chars->[$index] eq ","){$findKey=1;}
			elsif($chars->[$index] eq "["){($value,$index)=toJsonArray($chars,$index+1);$hash->{$key}=$value;$value=undef;}
			elsif($chars->[$index] eq "{"){($value,$index)=toJsonHash($chars,$index+1);$hash->{$key}=$value;$value=undef;}
			elsif($chars->[$index] eq "\""){($value,$index)=toJsonStringDoubleQuote($chars,$index+1);$hash->{$key}=$value;$value=undef;}
			elsif($chars->[$index] eq "\'"){($value,$index)=toJsonStringSingleQuote($chars,$index+1);$hash->{$key}=$value;$value=undef;}
			elsif($chars->[$index]!~/^\s$/){$value.=$chars->[$index];}
		}
	}
	return ($hash,$index);
}
sub toJsonStringDoubleQuote{
	my $chars=shift();
	my $index=shift();
	my $length=scalar(@{$chars});
	my $value;
	my $i;
	for($i=$index;$i<$length;$i++){
		if($chars->[$i] eq "\""){
			if($i==$index){last;}
			elsif($chars->[$i-1] ne "\\"){last;}
		}
		$value.=$chars->[$i];
	}
	return (jsonUnescape($value),$i);
}
sub toJsonStringSingleQuote{
	my $chars=shift();
	my $index=shift();
	my $length=scalar(@{$chars});
	my $value;
	my $i;
	for($i=$index;$i<$length;$i++){
		if($chars->[$i] eq "\'"){
			if($i==$index){last;}
			elsif($chars->[$i-1] ne "\\"){last;}
		}
		$value.=$chars->[$i];
	}
	return (jsonUnescape($value),$i);
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
############################## jsonEncode ##############################
sub jsonEncode{
	my $object=shift;
	if(ref($object) eq "ARRAY"){return jsonEncode_array($object);}
	elsif(ref($object) eq "HASH"){return jsonEncode_hash($object);}
	else{return "\"".json_escape($object)."\"";}
}
sub jsonEncode_array{
	my $hashtable=shift();
	my $json="[";
	my $i=0;
	foreach my $object(@{$hashtable}){
		if($i>0){$json.=",";}
		$json.=jsonEncode($object);
		$i++;
	}
	$json.="]";
	return $json;
}
sub jsonEncode_hash{
	my $hashtable=shift();
	my $json="{";
	my $i=0;
	foreach my $subject (sort{$a cmp $b} keys(%{$hashtable})){
		if($i>0){$json.=",";}
		$json.="\"$subject\":".jsonEncode($hashtable->{$subject});
		$i++;
	}
	$json.="}";
	return $json;
}
sub json_escape{
	my $text=shift();
	$text=~s/\\/\\\\/g;
	$text=~s/\n/\\n/g;
	$text=~s/\r/\\r/g;
	$text=~s/\t/\\t/g;
	$text=~s/\"/\\"/g;
	return $text;
}
############################## linecount ##############################
sub linecount{
	my $path=shift();
	if(!(-f $path)){return 0;}
	elsif($path=~/\.gz(ip)?$/){my $count=`gzip -cd $path|wc -l`;chomp($count);return $count;}
	elsif($path=~/\.bz(ip)?2$/){my $count=`bzip2 -cd $path|wc -l`;chomp($count);return $count;}
	elsif($path=~/\.bam$/){my $count=`samtools view $path|wc -l`;chomp($count);return $count;}
	else{my $count=`cat $path|wc -l`;if($count=~/(\d+)/){$count=$1;};return $count;}
}
############################## listFilesRecursively ##############################
sub listFilesRecursively{
	my @directories=@_;
	my $filegrep=shift(@directories);
	my $fileungrep=shift(@directories);
	my $recursivesearch=shift(@directories);
	my @inputfiles=();
	foreach my $directory (@directories){
		if(-f $directory){push(@inputfiles,$directory);next;}
		elsif(-l $directory){push(@inputfiles,$directory);next;}
		opendir(DIR,$directory);
		foreach my $file(readdir(DIR)){
			if($file eq "."){next;}
			if($file eq ".."){next;}
			if($file eq ""){next;}
			if($file=~/^\./){next;}
			my $path="$directory/$file";
			if(-d $path){
				if($recursivesearch!=0){push(@inputfiles,listFilesRecursively($filegrep,$fileungrep,$recursivesearch-1,$path));}
				next;
			}
			if(defined($filegrep)&&$file!~/$filegrep/){next;}
			if(defined($fileungrep)&&$file=~/$fileungrep/){next;}
			push(@inputfiles,$path);
		}
		closedir(DIR);
	}
	return sort{$a cmp $b}@inputfiles;
}
############################## loadCommandFromURL ##############################
sub loadCommandFromURL{
	my $url=shift();
	my $commands=shift();
	if(defined($commands)&&exists($commands->{$url})){return $commands->{$url};}
	if(defined($opt_l)){print "#Loading: $url\n";}
	my $command=($url=~/\.json$/)?getJson($url):getBash($url);
	if(scalar(keys(%{$command}))==0){print "ERROR: Couldn't load $url\n";exit(1);}
	loadCommandFromURLSub($command);
	$command->{$urls->{"daemon/command"}}=$url;
	if(defined($commands)){$commands->{$url}=$command;}
	return $command;
}
sub loadCommandFromURLSub{
	my $command=shift();
	$command->{"input"}=[];
	$command->{"output"}=[];
	my $default={};
	if(exists($command->{$urls->{"daemon/inputs"}})){
		$command->{$urls->{"daemon/inputs"}}=handleArray($command->{$urls->{"daemon/inputs"}},$default);
		$command->{"inputs"}=handleHash(@{$command->{$urls->{"daemon/inputs"}}});
		if(!exists($command->{$urls->{"daemon/input"}})){$command->{$urls->{"daemon/input"}}=$command->{$urls->{"daemon/inputs"}};}
	}
	if(exists($command->{$urls->{"daemon/input"}})){
		$command->{$urls->{"daemon/input"}}=handleArray($command->{$urls->{"daemon/input"}},$default);
		my @array=();
		foreach my $input(@{$command->{$urls->{"daemon/input"}}}){push(@array,$input);}
		if(exists($command->{$urls->{"daemon/inputs"}})){
			my $hash=handleHash(@{$command->{$urls->{"daemon/input"}}});
			foreach my $input(@{$command->{"daemon/inputs"}}){if(!exists($hash->{$input})){push(@array,$input);}}
		}
		$command->{"input"}=\@array;
	}
	if(exists($command->{$urls->{"daemon/command/option"}})){
		my $hash={};
		while(my ($key,$val)=each(%{$command->{$urls->{"daemon/command/option"}}})){
			if($key=~/^\$(.+)$/){$key=$1}
			$hash->{$key}=$val;
		}
		$command->{"options"}=$hash;
	}
	if(exists($command->{$urls->{"daemon/return"}})){
		$command->{$urls->{"daemon/return"}}=removeDollar($command->{$urls->{"daemon/return"}});
		$command->{$urls->{"daemon/output"}}=handleArray($command->{$urls->{"daemon/output"}},$default);
		my $hash=handleHash(@{$command->{$urls->{"daemon/output"}}});
		my $returnvalue=$command->{$urls->{"daemon/return"}};
		if(!exists($hash->{$returnvalue})){
			if($returnvalue eq "stdout"){}
			else{push(@{$command->{$urls->{"daemon/output"}}},$returnvalue);}
		}
	}
	if(exists($command->{$urls->{"daemon/output"}})){
		$command->{$urls->{"daemon/output"}}=handleArray($command->{$urls->{"daemon/output"}},$default);
		my @array=();
		foreach my $output(@{$command->{$urls->{"daemon/output"}}}){push(@array,$output);}
		$command->{"output"}=\@array;
	}
	my $hash={};
	foreach my $input(@{$command->{"input"}}){$hash->{$input}=1;}
	foreach my $output(@{$command->{"output"}}){$hash->{$output}=1;}
	my @array=keys(%{$hash});
	$command->{"keys"}=\@array;
	if(exists($command->{$urls->{"daemon/unzip"}})){$command->{$urls->{"daemon/unzip"}}=handleArray($command->{$urls->{"daemon/unzip"}});}
	if(exists($command->{$urls->{"daemon/file/stats"}})){$command->{$urls->{"daemon/file/stats"}}=removeDollar($command->{$urls->{"daemon/file/stats"}});}
	if(exists($command->{$urls->{"daemon/file/md5"}})){$command->{$urls->{"daemon/file/md5"}}=handleArray($command->{$urls->{"daemon/file/md5"}});}
	if(exists($command->{$urls->{"daemon/file/filesize"}})){$command->{$urls->{"daemon/file/filesize"}}=handleArray($command->{$urls->{"daemon/file/filesize"}});}
	if(exists($command->{$urls->{"daemon/file/linecount"}})){$command->{$urls->{"daemon/file/linecount"}}=handleArray($command->{$urls->{"daemon/file/linecount"}});}
	if(exists($command->{$urls->{"daemon/file/seqcount"}})){$command->{$urls->{"daemon/file/seqcount"}}=handleArray($command->{$urls->{"daemon/file/seqcount"}});}
	if(exists($command->{$urls->{"daemon/description"}})){$command->{$urls->{"daemon/description"}}=handleArray($command->{$urls->{"daemon/description"}});}
	if(exists($command->{$urls->{"daemon/bash"}})){$command->{"bashCode"}=handleCode($command->{$urls->{"daemon/bash"}});}
	if(!exists($command->{$urls->{"daemon/maxjob"}})){$command->{$urls->{"daemon/maxjob"}}=1;}
	if(exists($command->{$urls->{"daemon/script"}})){handleScript($command);}
	if(exists($command->{$urls->{"daemon/error/file/empty"}})){$command->{$urls->{"daemon/error/file/empty"}}=handleHash(@{handleArray($command->{$urls->{"daemon/error/file/empty"}})});}
	if(exists($command->{$urls->{"daemon/error/stderr/ignore"}})){$command->{$urls->{"daemon/error/stderr/ignore"}}=handleArray($command->{$urls->{"daemon/error/stderr/ignore"}});}
	if(exists($command->{$urls->{"daemon/error/stdout/ignore"}})){$command->{$urls->{"daemon/error/stdout/ignore"}}=handleArray($command->{$urls->{"daemon/error/stdout/ignore"}});}
	if(scalar(keys(%{$default}))>0){$command->{"default"}=$default;}
}
############################## getJobFiles ##############################
sub getJobFiles{
	my $number=shift();
	my $execids=shift();
	my @jobFiles=();
	opendir(DIR,$jobdir);
	foreach my $file(readdir(DIR)){
		if($number<=0){last;}
		if($file=~/^\./){next;}
		my $path="$jobdir/$file";
		if(-d $path){next;}
		if($path!~/\d{14}/){next;}
		if(defined($execids)){
			my $execid=basename($path,".txt");
			if(!exists($execids->{$execid})){next;}
		}
		push(@jobFiles,$path);
		$number--;
	}
	closedir(DIR);
	return @jobFiles;
}
############################## loadExecutes ##############################
sub loadExecutes{
	my @jobFiles=@_;
	my $commands=shift(@jobFiles);
	my $executes=shift(@jobFiles);
	my $execurls=shift(@jobFiles);
	my $newjob=0;
	foreach my $file(@jobFiles){
		if(!-e $file){next;}
		my $id=basename($file,".txt");
		my $hash={};
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			my ($key,$val)=split(/\t/);
			$hash->{$key}=$val;
		}
		close($reader);
		if(exists($hash->{$urls->{"daemon/execute"}})){next;}
		$newjob++;
		my $url=$hash->{$urls->{"daemon/command"}};
		loadCommandFromURL($url,$commands);
		if(!existsArray($execurls,$url)){push(@{$execurls},$url);}
		if(exists($executes->{$url}->{$id})){next;}
		$executes->{$url}->{$id}={};
		$executes->{$url}->{$id}->{"cmdurl"}=$url;
		$executes->{$url}->{$id}->{"execid"}=$id;
		while(my ($key,$val)=each(%{$hash})){
			if($key=~/^$url#(.+)$/){
				$key=$1;
				if(!exists($executes->{$url}->{$id}->{$key})){$executes->{$url}->{$id}->{$key}=$val;}
				elsif(ref($executes->{$url}->{$id}->{$key})eq"ARRAY"){push(@{$executes->{$url}->{$id}->{$key}},$val);}
				else{$executes->{$url}->{$id}->{$key}=[$executes->{$url}->{$id}->{$key},$val]}
			}
		}
	}
	return $newjob;
}
############################## loadJobs ##############################
sub loadJobs{
	my @files=getFiles($jobdir);
	my $hash={};
	foreach my $file(@files){
		my $basename=basename($file,".txt");
		$hash->{$basename}={};
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			my ($key,$val)=split(/\t/);
			$hash->{$basename}->{$key}=$val;
		}
		close($reader);
	}
	return $hash;
}
############################## loadLogFile ##############################
sub loadLogFile{
	my $logfile=shift();
	my $logs={};
	my $reader=openFile($logfile);
	while(<$reader>){
		chomp;my ($key,$val)=split(/\t/);
		if(ref($logs->{$key})eq"ARRAY"){push(@{$logs->{$key}},$val);}
		elsif(exists($logs->{$key})){$logs->{$key}=[$logs->{$key},$val];}
		else{$logs->{$key}=$val;}
	}
	close($reader);
	return $logs;
}
############################## loadSubmit ##############################
sub loadSubmit{
	my $path=shift();
	my $reader=openFile($path);
	my $hash={};
	my $command;
	my $rdfdb;
	while(<$reader>){
		chomp;
		my ($key,$val)=split(/\t/);
		if($key eq "url"){$command=$val;}
		elsif($key eq "rdfdb"){$rdfdb=$val;}
		else{$hash->{$key}=$val;}
	}
	close($reader);
	if(!defined($rdfdb)){$rdfdb=".";}
	if(!defined($command)){
		print STDERR "ERROR: Command URL is not specified in '$path'\n";
		exit(1);
	}
	unlink($path);
	return ($rdfdb,$command,$hash);
}
############################## ls ##############################
sub ls{
	my ($arguments,$userdefined)=handleArguments(@ARGV);
	my @directories=@{$arguments};
	my $suffixs;
	my $queryResults;
	if(defined($opt_i)){
		my ($keys,$queryIn)=handleInputOutput($opt_i,$userdefined,$suffixs);
		$queryResults=getQueryResults($dbdir,$queryIn);
	}else{
		if(scalar(@directories)==0){push(@directories,".");}
		foreach my $directory(@directories){push(@{$queryResults->[1]},{"input"=>$directory});}
		my $tmp={"input"=>1};
		foreach my $key(@{$queryResults->[0]}){$tmp->{$key}=1;}
		my @array=keys(%{$tmp});
		$queryResults->[0]=\@array;
	}
	my $keys=$queryResults->[0];
	my $values=$queryResults->[1];
	my @lines=();
	my $template=defined($opt_o)?$opt_o:"\$path";
	my @templates=split(/,/,$template);
	foreach my $value(@{$values}){
		my $val=$value->{"input"};
		my @files=listFilesRecursively($opt_g,$opt_G,$opt_r,$val);
		foreach my $file(@files){
			my $hash=basenames($file,$opt_D);
			foreach my $template(@templates){
				my $line=$template;
				$hash=fileStats($file,$line,$hash);
				while(my($k,$v)=each(%{$value})){
					$line=~s/\$\{$k\}/$v/g;
					$line=~s/\$$k/$v/g;
				}
				$line=~s/\\t/\t/g;
				$line=~s/\-\>/\t/g;
				$line=~s/\\n/\n/g;
				my @keys=sort{$b cmp $a}keys(%{$hash});
				foreach my $k(@keys){
					my $v=$hash->{$k};
					$line=~s/\$\{$k\}/$v/g;
					$line=~s/\$$k/$v/g;
				}
				push(@lines,$line);
			}
		}
	}
	if(defined($opt_x)&&checkInputOutput($opt_o)){
		my ($writer,$temp)=tempfile();
		foreach my $line(@lines){print $writer "$line\n";}
		close($writer);
		if(defined($opt_l)){system("perl $prgdir/rdf.pl -d $dbdir import < $temp");}
		else{system("perl $prgdir/rdf.pl -q -d $dbdir import < $temp");}
	}else{
		foreach my $line(@lines){print "$line\n";}
	}
}
############################## mainProcess ##############################
sub mainProcess{
	my $execurls=shift();
	my $commands=shift();
	my $executes=shift();
	my $processes=shift();
	my $available=shift();
	my $thrown=0;
	my $url;
	for(my $i=0;($i<$available)&&(scalar(@{$execurls})>0);$i++){
		$url=shift(@{$execurls});
		my $command=$commands->{$url};
		my $singlethread=(exists($command->{$urls->{"daemon/singlethread"}})&&$command->{$urls->{"daemon/singlethread"}} eq "true");
		$sleeptime=$command->{$urls->{"daemon/sleeptime"}};
		my $maxjob=$command->{$urls->{"daemon/maxjob"}};
		if(!defined($maxjob)){$maxjob=1;}
		my @variables=();
		if(exists($command->{$urls->{"daemon/bash"}})){
			my $count=0;
			foreach my $execid(sort{$a cmp $b}keys(%{$executes->{$url}})){
				if(!$singlethread&&$count>=$maxjob){last;}
				my $vars=$executes->{$url}->{$execid};
				initExecute($command,$vars);
				bashCommand($command,$vars);
				push(@variables,$vars);
				delete($executes->{$url}->{$execid});
				$count++;
				$thrown++;
			}
		}
		if(defined($opt_p)){
			foreach my $var(@variables){
				my $execid=$var->{"execid"};
				my $bashsrc=$var->{"base"}->{"bashfile"};
				my $logfile="$jobdir/$execid.txt";
				open(IN,$bashsrc);
				while(<IN>){print;}
				close(IN);
				unlink($bashsrc);
				unlink($logfile);
				rmdir("$moiraidir/$execid");
			}
			exit(0);
		}else{
			throwJobs($url,$command,$processes,@variables);
		}
		if(scalar(keys(%{$executes->{$url}}))>0){unshift(@{$execurls},$url);}
	}
	return $thrown;
}
############################## mkdirs ##############################
sub mkdirs{
	my @directories=@_;
	foreach my $directory(@directories){
		if(-d $directory){next;}
		my @tokens=split(/[\/\\]/,$directory);
		if(($tokens[0] eq "")&&(scalar(@tokens)>1)){
			shift(@tokens);
			my $token=shift(@tokens);
			unshift(@tokens,"/$token");
		}
		my $string="";
		foreach my $token(@tokens){
			$string.=(($string eq "")?"":"/").$token;
			if(-d $string){next;}
			if(!mkdir($string)){return 0;}
		}
	}
	return 1;
}
############################## moiraiCreateCommand ##############################
sub moiraiCreateCommand{
	my $mode=shift();
	my $commands=shift();
	my $insertKeys=shift();
	my $queryResults=shift();
	my $inputKeys=shift();
	my $outputKeys=shift();
	my $suffixs=shift();
	my $arguments=shift();
	my $userdefined=shift();
	my $cmdurl;
	if($mode=~/^command$/i){
		my @lines=();
		while(<STDIN>){chomp;push(@lines,$_);}
		my ($inputs,$outputs)=setupInputOutput($insertKeys,$queryResults,$inputKeys,$outputKeys);
		if(!defined($opt_q)){$sleeptime=1;$opt_s=1;}#When running with qsub, return in 1 second
		$cmdurl=createJson($inputs,$outputs,$suffixs,@lines);
	}elsif($mode=~/^build$/i){
		my @lines=();
		while(<STDIN>){chomp;push(@lines,$_);}
		my ($inputs,$outputs)=setupInputOutput($insertKeys,$queryResults,$inputKeys,$outputKeys);
		$cmdurl=createJson($inputs,$outputs,$suffixs,@lines);
		print "$cmdurl\n";
		exit(0);
	}elsif($mode=~/^exec$/i){
		if(scalar(@{$arguments})==0){print STDERR "ERROR: Please specify command line\n";exit(1);}
		my $cmdLine=join(" ",@{$arguments});
		($cmdLine,$inputKeys,$outputKeys,$suffixs)=getInputsOutputsFromCommand($cmdLine,$userdefined,$inputKeys,$outputKeys,$suffixs);
		@{$arguments}=();
		my ($inputs,$outputs)=setupInputOutput($insertKeys,$queryResults,$inputKeys,$outputKeys);
		if(!defined($opt_r)){$opt_r="\$stdout";}
		if(!defined($opt_a)){$sleeptime=1;$opt_s=1;}#To get the result as soon as command is completed.
		$cmdurl=createJson($inputs,$outputs,$suffixs,$cmdLine);
	}elsif($mode=~/\.json$/){
		$cmdurl=$mode;
		my $command=loadCommandFromURL($cmdurl,$commands);
		my ($inputs,$outputs)=setupInputOutput($insertKeys,$queryResults,$inputKeys,$outputKeys);
		assignOptionsToCommand($command,$inputs,$outputs,$suffixs);
	}elsif($mode=~/\.(ba)?sh$/){
		$cmdurl=$mode;
		my $command=loadCommandFromURL($cmdurl,$commands);
		my ($inputs,$outputs)=setupInputOutput($insertKeys,$queryResults,$inputKeys,$outputKeys);
		if(exists($command->{$urls->{"daemon/userdefined"}})){
			my $hash=$command->{$urls->{"daemon/userdefined"}};
			while(my($key,$val)=each(%{$hash})){
				if(exists($userdefined->{$key})){next;}#priority: user defined>bash defined
				$userdefined->{$key}=$val;
			}
		}
		assignOptionsToCommand($command,$inputs,$outputs,$suffixs);
	}else{
		print STDERR "ERROR: There is no command to process.\n";
		exit(1);
	}
	return $cmdurl;
}
############################## moiraiFinally ##############################
sub moiraiFinally{
	my @execids=@_;
	my $commands=shift(@execids);
	my $processes=shift(@execids);
	my $result=0;
	foreach my $execid(sort{$a cmp $b}@execids){
		my $process=$processes->{$execid};
		if(returnError($execid)eq"error"){$result=1;}
		my $cmdurl=$process->{$urls->{"daemon/command"}};
		my $command=$commands->{$cmdurl};
		my $returnvalue=$command->{$urls->{"daemon/return"}};
		if(defined($returnvalue)){
			my $match="$cmdurl#$returnvalue";
			if($returnvalue eq "stdout"){$match="stdout";}
			elsif($returnvalue eq "stderr"){$match="stderr";}
			foreach my $execid(sort{$a cmp $b}@execids){returnResult($execid,$match);}
		}
	}
	if(defined($opt_Z)){touchFile($opt_Z);}
	if($result==1){exit(1);}
}
############################## moiraiInputProcess ##############################
sub moiraiInputProcess{
	my $userdefined=shift();
	my $queryResults;
	my $queryKeys;
	my $inputKeys;
	my $suffixs={};
	if(defined($opt_X)){$suffixs=handleSuffix($opt_X);}
	if(defined($opt_i)){
		($inputKeys,$queryKeys)=handleInputOutput($opt_i,$userdefined,$suffixs);
		my $fileKey=getFileKeyFromKeys($inputKeys);
		if(defined($queryKeys)){$queryResults=getQueryResults($dbdir,$queryKeys);}
		elsif($fileKey){
			my @files=`ls $opt_i`;
			my @array=();
			my $tmp={};
			foreach my $file(@files){
				chomp($file);
				my $h=basenames($file,$opt_D);
				$h=fileStats($file,$opt_o,$h);
				push(@array,$h);
				foreach my $key(keys(%{$h})){
					if(!existsArray($inputKeys,$key)){push(@{$inputKeys},$key);}
				}
			}
			$queryResults=[$inputKeys,\@array];
		}
	}
	if(!defined($queryResults)){$queryResults=[[],[{}]];}
	if(defined($opt_l)){printRows($queryResults->[0],$queryResults->[1]);}
	return ($queryResults,$queryKeys,$inputKeys,$suffixs);
}
############################## moiraiMain ##############################
sub moiraiMain{
	my $mode=shift();
	my $submitvar;
	my ($arguments,$userdefined)=handleArguments(@ARGV);
	if($mode=~/^submit$/i){($dbdir,$mode,$submitvar)=loadSubmit(@ARGV);}
	if($mode=~/\.(ba)?sh$/){retrieveOptionsFromBash($mode);}
	if(defined($opt_q)){if($opt_q eq "qsub"){$opt_q="sge";}elsif($opt_q eq "squeue"){$opt_q="slurm";}}
	if(defined($opt_a)&&defined($opt_v)){
		my $volumes=handleArray($opt_v);
		my $serverpath=handleServer($opt_a);
		my ($username,$servername,$serverdir)=splitServerPath($serverpath);
		foreach my $volume(@{$volumes}){
			my $fromDir="$rootDir/$volume";
			my $toDir="$serverdir/$volume";
			rsyncDirectory("$fromDir/","$username\@$servername:$toDir/");
		}
	}
	my $commands={};
	controlWorkflow();#handle insert/update/delete
	my ($queryResults,$queryKeys,$inputKeys,$suffixs)=moiraiInputProcess($userdefined);
	if(defined($submitvar)){
		my @array=keys(%{$submitvar});
		$queryResults->[0]=\@array;
		$queryResults->[1]=[$submitvar];
		$queryKeys=\@array;
	}
	my ($insertKeys,$outputKeys)=moiraiOutputProcess($queryResults,$queryKeys,$inputKeys,$userdefined,$suffixs);
	my $cmdurl=moiraiCreateCommand($mode,$commands,$insertKeys,$queryResults,$inputKeys,$outputKeys,$suffixs,$arguments,$userdefined);
	my @execids=moiraiPrepare($cmdurl,$commands,$queryResults,$userdefined,$queryKeys,$insertKeys,@{$arguments});
	my $processes=moiraiRunExecute($commands,@execids);
	moiraiFinally($commands,$processes,@execids);
}
############################## moiraiOutputProcess ##############################
sub moiraiOutputProcess{
	my $queryResults=shift();
	my $queryKeys=shift();
	my $inputKeys=shift();
	my $userdefined=shift();
	my $suffixs=shift();
	my $insertKeys=[];
	my $outputKeys=[];
	if(scalar(keys(%{$userdefined}))>0){
		my $hash={};
		foreach my $key(@{$inputKeys}){$hash->{$key}=1;}
		while(my($key,$val)=each(%{$userdefined})){
			if(!exists($hash->{$key})){push(@{$outputKeys},$key);}
		}
	}
	if(defined($opt_o)){
		($outputKeys,$insertKeys,$suffixs)=handleInputOutput($opt_o,$userdefined,$suffixs);
		if(defined($insertKeys)){
			if(defined($queryKeys)){removeUnnecessaryExecutes($queryResults,$insertKeys);}
		}
	}
	if(defined($opt_r)){
		my $array=handleKeys($opt_r);
		foreach my $value(@{$array}){if(!existsArray($outputKeys,$value)){push(@{$outputKeys},$value);}}
	}
	return ($insertKeys,$outputKeys);
}
############################## moiraiPrepare ##############################
sub moiraiPrepare{
	my @arguments=@_;
	my $url=shift(@arguments);
	my $commands=shift(@arguments);
	my $queryResults=shift(@arguments);
	my $userdefined=shift(@arguments);
	my $queryKeys=shift(@arguments);
	my $insertKeys=shift(@arguments);
	my $command=loadCommandFromURL($url,$commands);
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	if(scalar(@{$queryResults->[1]})==0){
		if(defined($opt_l)){print STDERR "WARNING: No corresponding data found.\n";}
		if(defined($opt_Z)){touchFile($opt_Z);}
		exit(0);
	}
	if(defined($insertKeys)){push(@{$command->{"insertKeys"}},@{$insertKeys});}
	if(defined($queryKeys)){push(@{$command->{"queryKeys"}},@{$queryKeys});}
	foreach my $input(@inputs){
		if(scalar(@arguments)==0){last;}
		if(exists($userdefined->{$input})){next;}
		$userdefined->{$input}=shift(@arguments);
	}
	foreach my $output(@outputs){
		if(scalar(@arguments)==0){last;}
		if(exists($userdefined->{$output})){next;}
		$userdefined->{$output}=shift(@arguments);
	}
	assignCommand($command,$userdefined,$queryResults);
	my $keys;
	my @execids=();
	foreach my $hash(@{$queryResults->[1]}){
		my $execid=assignExecid($opt_w);
		my $vars=moiraiPrepareVars($hash,$userdefined,$insertKeys,\@inputs,\@outputs);
		if(!defined($keys)){my @temp=sort{$a cmp $b}keys(%{$vars});$keys=\@temp;}
		moiraiPrepareSub($execid,$url,$vars);
		push(@execids,$execid);
	}
	if(defined($opt_u)){
		print "Proceed running ".scalar(@execids)." jobs [y/n]? ";
		if(!getYesOrNo()){exit(1);}
	}
	return @execids;
}
############################## moiraiPrepareSub ##############################
sub moiraiPrepareSub{
	my $execid=shift();
	my $url=shift();
	my $vars=shift();
	my $logfile="$jobdir/$execid.txt";
	my @logs=();
	push(@logs,$urls->{"daemon/command"}."\t$url");
	push(@logs,$urls->{"daemon/execid"}."\t$execid");
	foreach my $key(keys(%{$vars})){push(@logs,"$url#$key\t".$vars->{$key});}
	writeLog($execid,@logs);
}
############################## moiraiPrepareVars ##############################
sub moiraiPrepareVars{
	my $hash=shift();
	my $userdefined=shift();
	my $insertKeys=shift();
	my @inputs=@{shift()};
	my @outputs=@{shift()};
	my $vars={};
	for(my $i=0;$i<scalar(@inputs);$i++){
		my $input=$inputs[$i];
		my $value=$input;
		my $found=0;
		if(exists($hash->{$value})){$value=$hash->{$value};$found=1;}
		if(exists($userdefined->{$value})){$value=$userdefined->{$value};$found=1;}
		if($found==1){$vars->{$input}=$value;}
	}
	for(my $i=0;$i<scalar(@outputs);$i++){
		my $output=$outputs[$i];
		my $value=$output;
		my $found=0;
		if(exists($hash->{$value})){$value=$hash->{$value};$found=1;}
		if(exists($userdefined->{$value})){
			$value=$userdefined->{$value};
			if($value=~/\$(\w+)\.(\w+)/){
				if(exists($vars->{$1})){
					my $h=basenames($vars->{$1});
					if(exists($h->{$2})){my $k="\\\$$1\\.$2";my $v=$h->{$2};$value=~s/$k/$v/g;}
				}
			}elsif($value=~/\$\{(\w+)\.(\w+)\}/){
				if(exists($vars->{$1})){
					my $h=basenames($vars->{$1});
					if(exists($h->{$2})){my $k="\\\$\\{$1\\.$2\\}";my $v=$h->{$2};$value=~s/$k/$v/g;}
				}
			}
			$found=1;
		}
		if($found==1){$vars->{$output}=$value;}
	}
	while(my($key,$val)=each(%{$hash})){if(!exists($vars->{$key})){$vars->{$key}=$val;}}
	return $vars;
}
############################## moiraiRunExecute ##############################
sub moiraiRunExecute{
	my @execids=@_;
	my $commands=shift(@execids);
	my $executes={};
	my $processes={};
	my $execurls=[];
	my $ids;
	if(scalar(@execids)>0){$ids={};foreach my $execid(@execids){$ids->{$execid}=1;}}
	while(true){
		controlWorkflow($processes,$commands);
		my $jobs_running=getNumberOfJobsRunning();
		if($jobs_running>=$maximumJob){sleep($sleeptime);next;}
		my $job_remaining=getNumberOfJobsRemaining(@execids);
		if($jobs_running==0&&$job_remaining==0){controlWorkflow($processes,$commands);last;}
		if($job_remaining==0){sleep($sleeptime);next;}
		my $jobSlot=$maximumJob-$jobs_running;
		while(jobOfferStart()){if(defined($opt_l)){"#repeat"}}#repeat
		my @jobFiles=getJobFiles($jobSlot,$ids);
		loadExecutes($commands,$executes,$execurls,@jobFiles);
		jobOfferEnd();
		mainProcess($execurls,$commands,$executes,$processes,$jobSlot);
	}
	return $processes;
}
############################## jobOfferStart ##############################
#This make sure that only one program is looking at jobdir
#jobdir can be set across internet (example,jobdir=ah3q@dgt-ac4:moirai2/.moirai2/ctrl/jobdir)
#make sure that the hostname is correct
sub jobOfferStart{
	my $lockfile="$jobdir.lock";
	my $jobCoolingTime=10;#$sleeptime+1;
	if($jobCoolingTime>60){$jobCoolingTime=60;}
	while(fileExists($lockfile)){
		my $t1=checkTimestamp($lockfile);
		my $t2=time();
		my $diff=$jobCoolingTime-($t2-$t1);
		if($diff>0){
			if($opt_l){print "#Waiting: $diff seconds for next job offer\n";}
			sleep($diff);
		}else{removeFile($lockfile);}
	}
	writeFileContent($lockfile,$hostname);
	sleep(1);
	my $content=readFileContent($lockfile);
	if($content eq $hostname){return 0;}
	else{return 1;}
}
############################## jobOfferEnd ##############################
sub jobOfferEnd{
	my $lockfile="$jobdir.lock";
	removeFile($lockfile);
}
############################## openCommand ##############################
sub openCommand{
	my @arguments=@_;
	my $argument=shift(@arguments);
	if(!defined($argument)){system("open $moiraidir");}
}
############################## openFile ##############################
sub openFile{
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){
		if($path=~/\.gz(ip)?$/){return IO::File->new("ssh $1 'gzip -cd $2'|");}
		elsif($path=~/\.bz(ip)?2$/){return IO::File->new("ssh $1 'bzip2 -cd $2'|");}
		elsif($path=~/\.bam$/){return IO::File->new("ssh $1 'samtools view $2'|");}
		else{return IO::File->new("ssh $1 'cat $2'|");}
	}else{
		if($path=~/\.gz(ip)?$/){return IO::File->new("gzip -cd $path|");}
		elsif($path=~/\.bz(ip)?2$/){return IO::File->new("bzip2 -cd $path|");}
		elsif($path=~/\.bam$/){return IO::File->new("samtools view $path|");}
		else{return IO::File->new($path);}
	}
}
############################## printCommand ##############################
sub printCommand{
	my $url=shift();
	my $commands=shift();
	if(!defined($commands)){$commands={};}
	my $command=loadCommandFromURL($url,$commands);
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	print STDOUT "\n#URL     :".$command->{$urls->{"daemon/command"}}."\n";
	my $line="#URL: ".basename($command->{$urls->{"daemon/command"}});
	if(scalar(@inputs)>0){$line.=" [".join("] [",@inputs)."]";}
	if(scalar(@outputs)>0){$line.=" [".join("] [",@outputs)."]";}
	print STDOUT "$line\n";
	if(scalar(@inputs)>0){print STDOUT "#Input   :".join(", ",@{$command->{"input"}})."\n";}
	if(scalar(@outputs)>0){print STDOUT "#Output  :".join(", ",@{$command->{"output"}})."\n";}
	print STDOUT "#Bash    :";
	if(ref($command->{$urls->{"daemon/bash"}}) ne "ARRAY"){print STDOUT $command->{$urls->{"daemon/bash"}}."\n";}
	else{my $index=0;foreach my $line(@{$command->{$urls->{"daemon/bash"}}}){if($index++>0){print STDOUT "         :"}print STDOUT "$line\n";}}
	if(exists($command->{$urls->{"daemon/description"}})){print STDOUT "#Summary :".join(", ",@{$command->{$urls->{"daemon/description"}}})."\n";}
	if($command->{$urls->{"daemon/maxjob"}}>1){print STDOUT "#Maxjob  :".$command->{$urls->{"daemon/maxjob"}}."\n";}
	if(exists($command->{$urls->{"daemon/singlethread"}})){print STDOUT "#Single  :".($command->{$urls->{"daemon/singlethread"}}?"true":"false")."\n";}
	if(exists($command->{$urls->{"daemon/qjobopt"}})){print STDOUT "#qjobopt :".$command->{$urls->{"daemon/qjobopt"}}."\n";}
	if(exists($command->{$urls->{"daemon/script"}})){
		foreach my $script(@{$command->{$urls->{"daemon/script"}}}){
			print STDOUT "#Script  :".$script->{$urls->{"daemon/script/name"}}."\n";
			foreach my $line(@{$script->{$urls->{"daemon/script/code"}}}){
				print STDOUT "         :$line\n";
			}
		}
		print STDOUT "\n";
		print "Do you want to write scripts to files [y/n]? ";
		if(getYesOrNo()){
			my $outdir=defined($opt_o)?$opt_o:".";
			mkdir($outdir);
			foreach my $out(writeScript($url,$outdir,$commands)){print STDOUT "$out\n";}
		}
	}
	print STDOUT "\n";
}
############################## printRows ##############################
sub printRows{
	my $keys=shift();
	my $hashtable=shift();
	if(scalar(@{$keys})==0){return;}
	my @lengths=();
	my @labels=();
	foreach my $key(@{$keys}){push(@labels,"\$$key");}
	my $indexlength=length("".scalar(@{$hashtable}));
	for(my $i=0;$i<scalar(@labels);$i++){$lengths[$i]=length($labels[$i]);}
	for(my $i=0;$i<scalar(@{$hashtable});$i++){
		my $hash=$hashtable->[$i];
		for(my $j=0;$j<scalar(@labels);$j++){
			my $length=length($hash->{$keys->[$j]});
			if($lengths[$j]<$length){$lengths[$j]=$length;}
		}
	}
	my $tableline="+";
	for(my $i=0;$i<$indexlength;$i++){$tableline.="-"}
	for(my $i=0;$i<scalar(@lengths);$i++){
		$tableline.="+";
		for(my $j=0;$j<$lengths[$i];$j++){$tableline.="-";}
	}
	$tableline.="+";
	print "$tableline\n";
	my $labelline="|";
	for(my $i=0;$i<$indexlength;$i++){$labelline.=" "}
	for(my $i=0;$i<scalar(@labels);$i++){
		my $label=$labels[$i];
		my $l=length($label);
		$labelline.="|";
		my $string=$label;
		for(my $j=$l;$j<$lengths[$i];$j++){if(($j-$l)%2==0){$string.=" ";}else{$string=" $string";}}
		$labelline.=$string;
	}
	$labelline.="|";
	print "$labelline\n";
	print "$tableline\n";
	for(my $i=0;$i<scalar(@{$hashtable});$i++){
		my $hash=$hashtable->[$i];
		my $line=$i+1;
		my $l=length($line);
		for(my $j=$l;$j<$indexlength;$j++){$line=" $line";}
		$line="|$line";
		for(my $j=0;$j<scalar(@{$keys});$j++){
			my $token=$hash->{$keys->[$j]};
			my $l=length($token);
			$line.="|$token";
			for(my $k=$l;$k<$lengths[$j];$k++){$line.=" ";}
		}
		$line.="|";
		print "$line\n";
	}
	print "$tableline\n";
}
############################## printTable ##############################
sub printTable{
	my @out=@_;
	my $return_type=$out[0];
	if(lc($return_type) eq "print"){$return_type=0;shift(@out);}
	elsif(lc($return_type) eq "array"){$return_type=1;shift(@out);}
	elsif(lc($return_type) eq "stderr"){$return_type=2;shift(@out);}
	else{$return_type= 2;}
	printTableSub($return_type,"",@out);
}
sub printTableSub{
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
				for(my $i=0;$i<$size;$i++){push(@output,printTableSub($return_type,$string."[$i]=>\t",$array[$i]));}
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
				foreach my $key(@keys){push(@output,printTableSub($return_type,$string."{$key}=>\t",$hash{$key}));}
			}
		}elsif($return_type==0){print "$string\"$_\"\n";}
		elsif($return_type==1){push( @output,"$string\"$_\"");}
		elsif($return_type==2){print STDERR "$string\"$_\"\n";}
	}
	return wantarray?@output:$output[0];
}
############################## promptCommandInput ##############################
sub promptCommandInput{
	my $command=shift();
	my $variables=shift();
	my $label=shift();
	print STDOUT "#Input: $label";
	my $default;
	if(exists($command->{"default"})&&exists($command->{"default"}->{$label})){
		$default=$command->{"default"}->{$label};
		print STDOUT " [$default]";
	}
	print STDOUT "? ";
	my $value=<STDIN>;
	chomp($value);
	if($value=~/^(.+) +$/){$value=$1;}
	if($value eq ""){if(defined($default)){$value=$default;}else{exit(1);}}
	$variables->{$label}=$value;
}
############################## readText ##############################
sub readText{
	my $file=shift();
	my $text="";
	open(IN,$file);
	while(<IN>){s/\r//g;$text.=$_;}
	close(IN);
	return $text;
}
############################## reloadJobsRunning ##############################
sub reloadJobsRunning{
	my $commands=shift();
	my @files=getFiles($jobdir,$opt_w);
	my $processes={};
	foreach my $file(@files){
		my $execid=basename($file,".txt");
		my $reader=openFile($file);
		$processes->{$execid}={};
		while(<$reader>){
			chomp;
			my ($key,$value)=split(/\t/);
			$processes->{$execid}->{$key}=$value;
			if($key eq $urls->{"daemon/command"}){loadCommandFromURL($value,$commands);}
		}
		close($reader);
	}
	return $processes;
}
############################## removeDirRecursive ##############################
sub removeDirRecursive{
	my @dirs=@_;
	foreach my $dir(@dirs){
		if($dir=~/^(.+\@.+)\:(.+)$/){system("ssh $1 'rm -r $2'");}
		else{system("rm -r $dir");}
	}
}
############################## removeDirs ##############################
sub removeDirs{
	my @dirs=@_;
	foreach my $dir(@dirs){
		if($dir=~/^(.+\@.+)\:(.+)$/){system("ssh $1 'rmdir $2'");}
		else{rmdir($dir);}
	}
}
############################## removeDollar ##############################
sub removeDollar{
	my $value=shift();
	if($value=~/^\$(.+)$/){return $1;}
	return $value;
}
############################## writeFileContent ##############################
sub writeFileContent{
	my @array=@_;
	my $file=shift(@array);
	my ($writer,$tmpfile)=tempfile();
	my $linecount=0;
	foreach my $line(@array){if($linecount>0){print "\n";}print $writer "$line";$linecount++;}
	close($writer);
	if($file=~/^(.+\@.+)\:(.+)$/){system("scp $tmpfile $1:$2");}
	else{system("mv $tmpfile $file");}
}
############################## touchFile ##############################
sub touchFile{
	my @files=@_;
	foreach my $file(@files){
		if($file=~/^(.+\@.+)\:(.+)$/){system("ssh $1 'touch $2'");}
		else{system("touch $file");}
	}
}
############################## removeFile ##############################
sub removeFile{
	my @files=@_;
	foreach my $file(@files){
		if($file=~/^(.+\@.+)\:(.+)$/){system("ssh $1 'rm $2'");}
		else{unlink($file);}
	}
}
############################## removeFilesFromServer ##############################
sub removeFilesFromServer{
	my $command=shift();
	my $process=shift();
	if(!exists($process->{$urls->{"daemon/serverpath"}})){return;}
	my $url=$process->{$urls->{"daemon/command"}};
	my $serverpath=$process->{$urls->{"daemon/serverpath"}};
	my ($username,$servername,$serverdir)=splitServerPath($serverpath);
	foreach my $input(@{$command->{"input"}}){
		if(!exists($process->{"$url#$input"})){next;}
		my $inputFile="$serverdir/".$process->{"$url#$input"};
		print "#Removing $inputFile from $servername\n";
	}
	foreach my $output(@{$command->{"output"}}){
		if(!exists($process->{"$url#$output"})){next;}
		my $outputFile="$serverdir/".$process->{"$url#$output"};
		print "#Removing $outputFile from $servername\n";
	}
}
############################## removeSlash ##############################
sub removeSlash{
	my $path=shift();
	if($path=~/^(.+)\/+$/){$path=$1;}
	return $path;
}
############################## removeUnnecessaryExecutes ##############################
sub removeUnnecessaryExecutes{
	my $inputs=shift();
	my $query=shift();
	my $outputs=getQueryResults($dbdir,$query);
	my $inputKeys={};
	foreach my $input(@{$inputs->[0]}){$inputKeys->{$input}=1;}
	my $outputKeys={};
	foreach my $output(@{$outputs->[0]}){if(!exists($inputKeys->{$output})){$outputKeys->{$output}=1;}}
	my @array=();
	foreach my $input(@{$inputs->[1]}){
		my $skip=0;
		foreach my $output(@{$outputs->[1]}){
			my $hit=1;
			foreach my $key(@{$outputs->[0]}){
				if(exists($outputKeys->{$key})){next;}
				if(!exists($input->{$key})){$hit=0;last;}
				if($input->{$key} ne $output->{$key}){$hit=0;last;}
			}
			if($hit==1){$skip=1;}
		}
		if($skip==0){push(@array,$input);}
	}
	$inputs->[1]=\@array;
}
############################## replaceStringWithHash ##############################
sub replaceStringWithHash{
	my $hash=shift();
	my $string=shift();
	my @keys=sort{length($b)<=>length($a)}keys(%{$hash});
	foreach my $key(@keys){my $value=$hash->{$key};$key="\\\$$key";$string=~s/$key/$value/g;}
	return $string;
}
############################## retrieveKeysFromQueries ##############################
sub retrieveKeysFromQueries{
	my $line=shift();
	my @queries=ref($line)eq"ARRAY"?@{$line}:split(/,/,$line);
	my $temp={};
	foreach my $query(@queries){
		my @keys=ref($query)eq"ARRAY"?@{$query}:split(/->/,$query);
		foreach my $key(@keys){while($key=~/\$(\w+)/g){$temp->{$1}=1;}}
	}
	my @keys=sort{$a cmp $b}keys(%{$temp});
	return \@keys;
}
############################## retrieveOptionsFromBash ##############################
sub retrieveOptionsFromBash{
	my $path=shift();
	my $reader=openFile($path);
	while(<$reader>){
		chomp;
		if(/^#\$\s?-a\s+?(.+)$/){if(!defined($opt_a)){$opt_a=$1;}}
		elsif(/^#\$\s?-b\s+?(.+)$/){if(!defined($opt_b)){$opt_b=$1;}}
		elsif(/^#\$\s?-c\s+?(.+)$/){if(!defined($opt_c)){$opt_c=$1;}}
		elsif(/^#\$\s?-d\s+?(.+)$/){if(!defined($opt_d)){$opt_d=$1;}}
		elsif(/^#\$\s?-D\s+?(.+)$/){if(!defined($opt_D)){$opt_D=$1;}}
		elsif(/^#\$\s?-E\s+?(.+)$/){if(!defined($opt_E)){$opt_E=$1;}}
		elsif(/^#\$\s?-f\s+?(.+)$/){if(!defined($opt_f)){$opt_f=$1;}}
		elsif(/^#\$\s?-F\s+?(.+)$/){if(!defined($opt_F)){$opt_F=$1;}}
		elsif(/^#\$\s?-g\s+?(.+)$/){if(!defined($opt_g)){$opt_g=$1;}}
		elsif(/^#\$\s?-G\s+?(.+)$/){if(!defined($opt_G)){$opt_G=$1;}}
		#elsif(/^#\$\s?-h$/){if(!defined($opt_h)){$opt_h=1;}}
		#elsif(/^#\$\s?-H$/){if(!defined($opt_H)){$opt_H=1;}}
		elsif(/^#\$\s?-i\s+?(.+)$/){if(!defined($opt_i)){$opt_i=$1;}}
		elsif(/^#\$\s?-I\s+?(.+)$/){if(!defined($opt_I)){$opt_I=$1;}}
		#elsif(/^#\$\s?-l/){if(!defined($opt_l)){$opt_l=1;}}
		elsif(/^#\$\s?-m\s+?(.+)$/){if(!defined($opt_m)){$opt_m=$1;}}
		elsif(/^#\$\s?-o\s+?(.+)$/){if(!defined($opt_o)){$opt_o=$1;}}
		elsif(/^#\$\s?-O\s+?(.+)$/){if(!defined($opt_O)){$opt_O=$1;}}
		#elsif(/^#\$\s?-p/){if(!defined($opt_p)){$opt_p=1;}}
		elsif(/^#\$\s?-q\s+?(.+)$/){if(!defined($opt_q)){$opt_q=$1;}}
		elsif(/^#\$\s?-Q\s+?(.+)$/){if(!defined($opt_Q)){$opt_Q=$1;}}
		elsif(/^#\$\s?-r\s+?(.+)$/){if(!defined($opt_r)){$opt_r=$1;}}
		elsif(/^#\$\s?-s\s+?(.+)$/){if(!defined($opt_s)){$opt_s=$1;}}
		elsif(/^#\$\s?-S\s+?(.+)$/){if(!defined($opt_S)){$opt_S=$1;}}
		#elsif(/^#\$\s?-u/){if(!defined($opt_u)){$opt_u=1;}}
		elsif(/^#\$\s?-v\s+?(.+)$/){if(!defined($opt_v)){$opt_v=$1;}}
		elsif(/^#\$\s?-V\s+?(.+)$/){if(!defined($opt_V)){$opt_V=$1;}}
		elsif(/^#\$\s?-w\s+?(.+)$/){if(!defined($opt_w)){$opt_w=$1;}}
		#elsif(/^#\$\s?-x/){if(!defined($opt_x)){$opt_x=1;}}
	}
	close($reader);
	$dbdir=defined($opt_d)?checkDatabaseDirectory($opt_d):".";
	$sleeptime=defined($opt_s)?$opt_s:60;
	$maximumJob=defined($opt_m)?$opt_m:5;
}
############################## returnError ##############################
sub returnError{
	my $execid=shift();
	my $file=getFileFromExecid($execid);
	if(!defined($file)){return;}
	my $reader=openFile($file);
	my $flag=0;
	my $result;
	while(<$reader>){
		chomp;
		if(/^\#{40} (.+) \#{40}$/){if($1 eq $execid){$flag=1;}else{$flag=0;last;}}
		if($flag){
			my ($key,$val)=split(/\t/);
			if($key eq $urls->{"daemon/execute"}){$result=$val;}
		}
	}
	while(<$reader>){
		chomp;
		if(/^\#{40} (.+) \#{40}$/){if($1 eq "stderr"){$flag=1;}else{$flag=0;}}
		elsif($flag==1){print "$_\n";}
	}
	return $result;
}
############################## returnResult ##############################
sub returnResult{
	my $execid=shift();
	my $match=shift();
	my $file=getFileFromExecid($execid);
	if(!defined($file)){return;}
	my $reader=openFile($file);
	if($match eq "stdout"||$match eq "stderr"){
		my $flag=0;
		while(<$reader>){
			chomp;
			if(/^\#{40} (.+) \#{40}$/){if($1 eq $match){$flag=1;}else{$flag=0;}}
			elsif($flag==1){print "$_\n";}
		}
	}else{
		my $flag=0;
		my @results=();
		while(<$reader>){
			chomp;
			if(/^\#{40} (.+) \#{40}$/){if($execid eq $1){$flag=1;}else{$flag=0;}}
			if($flag){
				my ($key,$val)=split(/\t/);
				if($key eq $match){push(@results,$val);}
			}
		}
		if(scalar(@results)==0){return;}
		print join(" ",@results)."\n";
	}
}
############################## rsyncDirectory ##############################
sub rsyncDirectory{
	my $fromDir=shift();
	my $toDir=shift();
	# -r copy  recursively (-a is better?)
	# --copy-links  replace symbolic links with actual files/dirs
	# --keep-dirlinks  don't replace target's symbolic link directory with actual directory
	my $command="rsync -r --copy-links --keep-dirlinks $fromDir $toDir";
	if(defined($opt_l)){print "#Rsync: $fromDir => $toDir\n";}
	return system($command);
}
############################## runDaemon ##############################
sub runDaemon{
	my $commands={};
	my $processes=reloadJobsRunning($commands);
	my $runCount=defined($opt_r)?$opt_r:undef;
	while(true){
		controlWorkflow($processes,$commands);
		my $jobs_running=getNumberOfJobsRunning();
		if($jobs_running>=$maximumJob){
			sleep($sleeptime);
			next;
		}
		# handle submit
		foreach my $file(getFiles($submitdir)){
			my $cmdline="perl $prgdir/moirai2.pl";
			$cmdline.=" -w s";
			$cmdline.=" submit $file";
			if(!defined($opt_r)){$cmdline.=" &";}#Test purpose
			if(defined($opt_l)){print ">$cmdline\n";}
			system($cmdline);
		}
		# handle daemon
		my $jobs_running=getNumberOfJobsRunning();
		if($jobs_running>=$maximumJob){
			sleep($sleeptime);
			next;
		}
		foreach my $cmdurl(listFilesRecursively("(\.json|\.sh)\$",undef,-1,$daemondir)){
			my $command=loadCommandFromURL($cmdurl,$commands);   
			if(exists($command->{"timestamp"})){next;}
			assignOptionsToCommand($command);
			$command->{"timestamp"}=0;
		}
		foreach my $cmdurl(sort{$a cmp $b}keys(%{$commands})){
			my $command=$commands->{$cmdurl};
			my $rdfdb=$command->{$urls->{"daemon/rdfdb"}};
			if(daemonCheckTimestamp($command)){
				my $lockfile="$cmdurl.lock";
				my $unlockfile="$cmdurl.unlock";
				if(bashCommandHasOptions($command)){
					my $cmdline="perl $prgdir/moirai2.pl";
					$cmdline.=" -w a";
					$cmdline.=" -Z $unlockfile";
					if(defined($rdfdb)){$cmdline.=" -d $rdfdb";}
					elsif(defined($dbdir)){$cmdline.=" -d $dbdir";}
					$cmdline.=" $cmdurl";
					if(!defined($opt_r)){$cmdline.=" &";}#Test purpose
					if(defined($opt_l)){print ">$cmdline\n";}
					touchFile($lockfile);
					system($cmdline);
				}else{
					my ($writer,$script)=tempfile();
					print $writer "bash $cmdurl\n";
					print $writer "touch $unlockfile\n";
					close($writer);
					touchFile($lockfile);
					system("bash $script");
				}
			}
		}
		if(defined($runCount)){$runCount--;if($runCount<0){last;}}
		else{sleep($sleeptime);}
	}
	if(defined($opt_l)){STDOUT->autoflush(0);}
	foreach my $cmdurl(keys(%{$commands})){
		my $lockfile="$cmdurl.lock";
		my $unlockfile="$cmdurl.unlock";
		if(-e $lockfile && -e $unlockfile){unlink($lockfile);unlink($unlockfile);}
	}
}
############################## sandbox ##############################
sub sandbox{
	my @lines=@_;
	my $center=shift(@lines);
	my $length=0;
	foreach my $line(@lines){my $l=length($line);if($l>$length){$length=$l;}}
	my $label="";
	for(my $i=0;$i<$length+4;$i++){$label.="#";}
	print "$label\n";
	foreach my $line(@lines){
		for(my $i=length($line);$i<$length;$i++){
			if($center){if(($i%2)==0){$line.=" ";}else{$line=" $line";}}
			else{$line.=" ";}
		}
		print "# $line #\n";
	}
	print "$label\n";
}
############################## scriptCodeForBash ##############################
sub scriptCodeForBash{
	my @codes=@_;
	my @output=();
	for(my $i=0;$i<scalar(@codes);$i++){
		my $line=$codes[$i];
		$line=~s/\\/\\\\/g;
		$line=~s/\n/\\n/g;
		$line=~s/\$/\\\$/g;
		$line=~s/\`/\\`/g;
		push(@output,$line);
	}
	return @output;
}
############################## selectRDF ##############################
sub selectRDF{
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my @results=`perl $prgdir/rdf.pl -d $dbdir select '$subject' '$predicate' '$object'`;
	foreach my $result(@results){
		chomp($result);
		my @tokens=split(/\t/,$result);
		$result=\@tokens;
	}
	return @results;
}
############################## seqcount ##############################
sub seqcount{
	my $path=shift();
	if($path=~/\.f(ast)?a((\.gz(ip)?)|(\.bz(ip)?2))?$/){
		my $reader=openFile($path);
		my $count=0;
		while(<$reader>){if(/^\>/){$count++;}}
		close($reader);
		return $count;
	}elsif($path=~/\.f(ast)?q((\.gz(ip)?)|(\.bz(ip)?2))?$/){
		my $reader=openFile($path);
		my $count=0;
		while(<$reader>){$count++;<$reader>;<$reader>;<$reader>;}
		close($reader);
		return $count;
	}else{return 0;}
}
############################## setupInputOutput ##############################
sub setupInputOutput{
	my $insertKeys=shift();
	my $queryResults=shift();
	my $inputKeys=shift();
	my $outputKeys=shift();
	my $inputs={};
	my $outputs={};
	if(defined($queryResults)){foreach my $token(@{$queryResults->[0]}){$inputs->{"\$$token"}=1;}}
	if(defined($insertKeys)){
		foreach my $token(@{$insertKeys}){
			foreach my $t(@{$token}){
				if($t!~/^\$\w+$/){next;}
				if(exists($inputs->{$t})){next;}
				$outputs->{$t}=1;
			}
		}
	}
	if(defined($inputKeys)){
		foreach my $key(@{$inputKeys}){
			if($key!~/^\$\w+$/){$key="\$$key";}
			$inputs->{$key}=1;
		}
	}
	if(defined($outputKeys)){
		foreach my $key(@{$outputKeys}){
			if($key!~/^\$\w+$/){$key="\$$key";}
			if(exists($inputs->{$key})){next;}
			$outputs->{$key}=1;
		}
	}
	my @ins=sort{$a cmp $b}keys(%{$inputs});
	my @outs=sort{$a cmp $b}keys(%{$outputs});
	return (\@ins,\@outs);
}
############################## sortSubs ##############################
sub sortSubs{
	my $path="$prgdir/$program_name";
	my $reader=openFile($path);
	my @headers=();
	my $name;
	my $blocks={};
	my $block=[];
	my $date=getDate("/");
	my @orders=();
	while(<$reader>){
		chomp;s/\r//g;
		if(/^#{30}\s*(\S+)\s*#{30}$/){
			$name=$1;
			if($name!~/^[A-Z]+$/){push(@{$block},$_);last;}
		}elsif(/^my \$program_version=\"\S+\";/){$_="my \$program_version=\"$date\";";}
		push(@headers,$_);
	}
	while(<$reader>){
		chomp;s/\r//g;
		if(/^#{30}\s*(\S+)\s*#{30}$/){
			$blocks->{$name}=$block;
			push(@orders,$name);
			$name=$1;
			$block=[];
		}
		push(@{$block},$_);
	}
	close($reader);
	if(defined($name)){$blocks->{$name}=$block;push(@orders,$name);}
	my ($writer,$file)=tempfile();
	foreach my $line(@headers){print $writer "$line\n";}
	foreach my $key(sort{$a cmp $b}@orders){foreach my $line(@{$blocks->{$key}}){print $writer "$line\n";}}
	close($writer);
	return system("mv $file $path");
}
############################## splitServerPath ##############################
sub splitServerPath{
	my $serverpath=shift();
	if($serverpath=~/^(.+)\@(.+)\:(.+)/){return ($1,$2,$3);}
	if($serverpath=~/^(.+)\@(.+)/){return ($1,$2);}
	else{return $serverpath;}
}
############################## tarArchiveDirectory ##############################
sub tarArchiveDirectory{
	my $directory=shift();
	$directory=removeSlash($directory);
	my $root=dirname($directory);
	my $dir=basename($directory);
	system("rm $directory/.DS_Store");
	system("tar -C $root -czvf $directory.tgz $dir 2> /dev/null");
	system("rm -r $directory 2> /dev/null");
}
############################## tarListDirectory ##############################
sub tarListDirectory{
	my $file=shift();
	my @files=`tar -ztf $file`;
	return @files;
}
############################## test ##############################
sub test{
	my @arguments=@_;
	my $hash={};
	if(scalar(@arguments)>0){foreach my $arg(@arguments){$hash->{$arg}=1;}}
	else{for(my $i=0;$i<=5;$i++){$hash->{$i}=1;}}
	mkdir("test");
	if(exists($hash->{0})){test0();}
	if(exists($hash->{1})){test1();}
	if(exists($hash->{2})){test2();}
	if(exists($hash->{3})){test3();}
	if(exists($hash->{4})){test4();}
	if(exists($hash->{5})){test5();}
	if(exists($hash->{6})){test6();}
	rmdir("test");
}
#Testing sub functions
sub test0{
	testSub("handleInputOutput(\"\\\$input\")",["input"]);
	testSub("handleInputOutput(\"\\\$input1,\\\$input2\")",["input1","input2"]);
	testSubs("handleInputOutput(\"\\\$input1->input->\\\$input2\")",["input1","input2"],[["\$input1","input","\$input2"]],undef,undef);
	testSubs("handleInputOutput(\"\\\$input1->input->\\\$input2,\\\$input3\")",["input1","input2","input3"],[["\$input1","input","\$input2"]],undef,undef);
	testSub("handleInputOutput(\"\\\$input,*.pl\")",["input","*.pl"]);
	testSubs("handleInputOutput(\"\\\$input.txt\")",["input"],undef,undef,{"input"=>".txt"});
	testSubs("handleInputOutput(\"\\\$root->pred->\\\$input.txt\")",["root","input"],[["\$root","pred","\$input"]],undef,{"input"=>".txt"});
	testSub("handleInputOutput(\"\\\$root->\\\$name/pred->\\\$input.txt\",{\"name\"=>\"Akira\"})",["root","input"]);
	testSubs("handleInputOutput(\"\\\$root->\\\$name/pred->\\\$input.txt\",{\"name\"=>\"Akira\"})",["root","input"],[["\$root","Akira/pred","\$input"]],{"name"=>"Akira"},{"input"=>".txt"});
	testSubs("handleInputOutput(\"\\\$root->pred1/\\\$name/pred2->\\\$input.txt\",{\"name\"=>\"Akira\"})",["root","input"],[["\$root","pred1/Akira/pred2","\$input"]],{"name"=>"Akira"},{"input"=>".txt"});
	testSubs("handleInputOutput(\"\\\$root->pred1/\\\$name/pred2->\\\$input.txt,\\\$input3\",{\"name\"=>\"Akira\"})",["root","input","input3"],[["\$root","pred1/Akira/pred2","\$input"]],{"name"=>"Akira"},{"input"=>".txt"});
	testSub("handleInputOutput(\"{'\\\$input':'defaultvalue'}\")",["input"]);
	testSubs("handleInputOutput(\"{'\\\$input':{'suffix':'.txt'}}\")",["input"],undef,undef,{"input"=>".txt"});
	testSubs("handleInputOutput(\"{'\\\$input':{'default':'something','suffix':'.txt'},'\\\$input2':{'default':'something2','suffix':'.csv'}}\")",["input","input2"],undef,{"input"=>"something","input2"=>"something2"},{"input"=>".txt","input2"=>".csv"});
	testSubs("handleInputOutput(\"{'\\\$input':{'default':'something','suffix':'.txt'}}\")",["input"],undef,{"input"=>"something"},{"input"=>".txt"});
}
#Testing basic json functionality
sub test1{
	#testing input/output 1
	createFile("test/Akira.txt","A","B","C","D","A","D","B");
	testCommand("perl $prgdir/rdf.pl -d test insert root file test/Akira.txt","inserted 1");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -i 'root->file->\$file' exec 'sort \$file'","A","A","B","B","C","D","D");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -i 'root->file->\$file' -r 'output' exec 'sort \$file|uniq -c>\$output' '\$output=test/output.txt'","test/output.txt");
	testCommand("perl $prgdir/rdf.pl -d test delete root file test/Akira.txt","deleted 1");
	unlink("test/output.txt");
	unlink("test/Akira.txt");
	#testing input/output 2
	createFile("test/A.json","{\"https://moirai2.github.io/schema/daemon/input\":\"\$string\",\"https://moirai2.github.io/schema/daemon/bash\":[\"echo \\\"\$string\\\" > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -r '\$output' test/A.json 'Akira Hasegawa' test/output.txt","test/output.txt");
	testCommand("cat test/output.txt","Akira Hasegawa");
	unlink("test/output.txt");
	testCommand("perl $prgdir/rdf.pl -d test insert case1 'string' 'Akira Hasegawa'","inserted 1");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -i '\$id->string->\$string' -o '\$id->text->\$output' test/A.json '\$string' 'test/\$id.txt'","");
	testCommand("cat test/case1.txt","Akira Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test select case1 text","case1\ttext\ttest/case1.txt");
	unlink("test/A.json");
	#testing input/output 3
	createFile("test/B.json","{\"https://moirai2.github.io/schema/daemon/input\":\"\$input\",\"https://moirai2.github.io/schema/daemon/bash\":[\"sort \$input > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -i '\$id->text->\$input' -o '\$input->sorted->\$output' test/B.json '\$output=test/\$id.sort.txt'","");
	testCommand("cat test/case1.sort.txt","Akira Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test select % 'sorted'","test/case1.txt\tsorted\ttest/case1.sort.txt");
	createFile("test/case2.txt","Hasegawa","Akira","Chiyo","Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test insert case2 'text' test/case2.txt","inserted 1");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -i '\$id->text->\$input' -o '\$input->sorted->\$output' test/B.json '\$output=test/\$id.sort.txt'","");
	testCommand("cat test/case2.sort.txt","Akira","Chiyo","Hasegawa","Hasegawa");
	unlink("test/case1.txt");
	unlink("test/case2.txt");
	unlink("test/case1.sort.txt");
	unlink("test/case2.sort.txt");
	unlink("test/B.json");
	unlink("test/sorted.txt");
	unlink("test/string.txt");
	unlink("test/text.txt");
	#testing input/output with "done" flag
	mkdirs("$moiraidir/ctrl/insert/");
	createFile("$moiraidir/ctrl/insert/A.txt","A\tname\tAkira");
	system("echo 'mkdir -p test/\$dirname'|perl $prgdir/moirai2.pl -d test -s 1 -i '\$id->name->\$dirname' -o '\$id->mkdir->done' command");
	if(!-e "test/Akira"){print STDERR "test/Akira directory not created\n";}
	else{rmdir("test/Akira");}
	createFile("$moiraidir/ctrl/insert/B.txt","B\tname\tBen");
	system("echo 'mkdir -p test/\$dirname'|perl $prgdir/moirai2.pl -d test -s 1 -i '\$id->name->\$dirname' -o '\$id->mkdir->done' command");
	if(!-e "test/Ben"){print STDERR "test/Ben directory not created\n";}
	else{rmdir("test/Ben");}
	unlink("test/mkdir.txt");
	unlink("test/name.txt");
}
#Testing exec and bash functionality
sub test2{
	#Testing exec1
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 exec 'ls $moiraidir/ctrl'","delete","insert","job","process","submit","update");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -r '\$output' exec 'output=(`ls $moiraidir/ctrl`);'","delete insert job process submit update");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -r output exec 'ls -lt > \$output' '\$output=test/list.txt'","test/list.txt");
	unlink("test/list.txt");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -o '$moiraidir/ctrl->file->\$output' exec 'output=(`ls $moiraidir/ctrl`);'","");
	testCommand("perl $prgdir/rdf.pl -d test select $moiraidir/ctrl file","$moiraidir/ctrl\tfile\tdelete","$moiraidir/ctrl\tfile\tinsert","$moiraidir/ctrl\tfile\tjob","$moiraidir/ctrl\tfile\tprocess","$moiraidir/ctrl\tfile\tsubmit","$moiraidir/ctrl\tfile\tupdate");
	testCommand("perl $prgdir/rdf.pl -d test delete % % %","deleted 6");
	#Testing exec2
	createFile("test/hello.txt","A","B","C","A");
	testCommand("perl $prgdir/moirai2.pl -r output -i input -o output exec 'sort -u \$input > \$output;' input=test/hello.txt output=test/output.txt","test/output.txt");
	testCommand("cat test/output.txt","A\nB\nC");
	unlink("test/output.txt");
	testCommand("echo i|perl $prgdir/moirai2.pl -r out1 exec 'sort -u test/hello.txt > test/output2.txt' > /dev/null","test/hello.txt is [I]nput/[O]utput? test/output2.txt");
	testCommand("cat test/output2.txt","A\nB\nC");
	unlink("test/hello.txt");
	unlink("test/output2.txt");
	#Testing bash functionality
	createFile("test/test.sh","#\$-i \$id->input->\$input\n#\$-o \$id->output->\$output.txt\nsort \$input | uniq -c > \$output");
	createFile("test/input.txt","A","B","D","C","F","E","G","A","A","A");
	testCommand("perl $prgdir/rdf.pl -d test/db insert idA input test/input.txt","inserted 1");
	testCommand("perl $prgdir/moirai2.pl -d test/db -s 1 -r '\$output' test/test.sh output=test/uniq.txt","test/uniq.txt");
	testCommand("perl $prgdir/moirai2.pl -d test/db -s 1 -r '\$output' test/test.sh output=test/uniq.txt","");
	testCommand("cat test/uniq.txt","   4 A","   1 B","   1 C","   1 D","   1 E","   1 F","   1 G");
	testCommand("cat test/db/output.txt","idA\ttest/uniq.txt");
	unlink("test/uniq.txt");
	unlink("test/test.sh");
	unlink("test/input.txt");
	unlink("test/db/output.txt");
	unlink("test/db/input.txt");
	rmdir("test/db");
	#Testing bash with arguments
	createFile("test/test.sh","#\$-i input","#\$-o output","#\$ input=test/input.txt","#\$ output=test/\${input.basename}.out.txt","sort \$input | uniq -c > \$output");
	createFile("test/input.txt","Hello","World");
	testCommand("perl $prgdir/moirai2.pl -r output -s 1 test/test.sh","test/input.out.txt");
	testCommand("cat test/input.out.txt","   1 Hello","   1 World");
	unlink("test/test.sh");
	unlink("test/input.txt");
	unlink("test/input.out.txt");
}
#Testing build and ls functionality
sub test3{
	# Testing build
	open(OUT,">test/1.sh");
	print OUT "ls \$input > \$output";
	close(OUT);
	testCommand("perl $prgdir/moirai2.pl -d test -i '\$input' -o '\$output' build < test/1.sh|xargs cat","{\"https://moirai2.github.io/schema/daemon/bash\":[\"ls \$input > \$output\"],\"https://moirai2.github.io/schema/daemon/input\":[\"\$input\"],\"https://moirai2.github.io/schema/daemon/output\":[\"\$output\"]}");
	testCommand("perl $prgdir/moirai2.pl -d test -i 'root->directory->\$input' -o 'root->content->\$output' build < test/1.sh|xargs cat","{\"https://moirai2.github.io/schema/daemon/bash\":[\"ls \$input > \$output\"],\"https://moirai2.github.io/schema/daemon/input\":[\"\$input\"],\"https://moirai2.github.io/schema/daemon/output\":[\"\$output\"]}");
	unlink("test/1.sh");
	#Testing ls
	mkdir("test/dir");
	system("touch test/dir/A.txt");
	system("touch test/dir/B.gif");
	system("touch test/dir/C.txt");
	testCommand("perl $prgdir/moirai2.pl -d test ls test/dir","test/dir/A.txt","test/dir/B.gif","test/dir/C.txt");
	testCommand("perl $prgdir/moirai2.pl -d test -o '\$filename' ls test/dir","A.txt","B.gif","C.txt");
	testCommand("perl $prgdir/moirai2.pl -d test -o '\$suffix' ls test/dir","txt","gif","txt");
	testCommand("perl $prgdir/moirai2.pl -d test -o 'root->file->\$path' ls test/dir","root\tfile\ttest/dir/A.txt","root\tfile\ttest/dir/B.gif","root\tfile\ttest/dir/C.txt");
	testCommand("perl $prgdir/moirai2.pl -d test -g txt -o '\$path' ls test/dir","test/dir/A.txt","test/dir/C.txt");
	testCommand("perl $prgdir/moirai2.pl -d test -G txt -o '\$base0' ls test/dir","B");
	testCommand("perl $prgdir/moirai2.pl -d test -lx -o 'root->file->\$path' ls test/dir","inserted 3");
	testCommand("perl $prgdir/rdf.pl -d test insert root directory test/dir","inserted 1");
	testCommand("perl $prgdir/moirai2.pl -d test -i 'root->directory->\$input' ls","test/dir/A.txt","test/dir/B.gif","test/dir/C.txt");
	testCommand("perl $prgdir/rdf.pl -d test delete % % %","deleted 4");
	system("rm -r test/dir");
	#Testing submit function
	createFile("test/submit.json","{\"https://moirai2.github.io/schema/daemon/bash\":[\"ls test\"],\"https://moirai2.github.io/schema/daemon/return\":\"stdout\",\"https://moirai2.github.io/schema/daemon/sleeptime\":\"1\"}");
	createFile("test/submit.txt","url\ttest/submit.json");
	testCommand("perl $prgdir/moirai2.pl -d test submit test/submit.txt","submit.json");
	#Testing submit function with daemon
	createFile(".moirai2/ctrl/submit/submit.txt","url\ttest/submit.json");
	testCommand("perl $prgdir/moirai2.pl -d test -r 0 daemon","submit.json");
	unlink("test/submit.json");
	#Testing bash script submit
	createFile("test/submit.sh","#\$ -i message","#\$ -o output","#\$ -r output","#\$ message=test script","#\$ output=test/output.txt","echo \"Hello \$message\">\$output");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 test/submit.sh message=Akira|xargs cat","Hello Akira");
	#no input argument
	createFile(".moirai2/ctrl/submit/submit.txt","url\ttest/submit.sh");
	testCommand("perl $prgdir/moirai2.pl -d test -r 0 daemon|xargs cat","Hello test script");
	#with input argument
	createFile(".moirai2/ctrl/submit/submit.txt","url\ttest/submit.sh","message\tHasegawa");
	testCommand("perl $prgdir/moirai2.pl -d test -r 0 daemon|xargs cat","Hello Hasegawa");
	unlink("test/submit.sh");
	unlink("test/output.txt");
	#Testing daemon functionality
	createFile(".moirai2/daemon/hello.sh","#\$ -i \$id->message->\$message","#\$ -o \$id->output->\$output","#\$-r output","#\$ message=test","#\$ output=test/\$id.txt","echo \"Hello \$message\">\$output");
	createFile("test/message.txt","Akira\tHasegawa");
	testCommand("perl $prgdir/moirai2.pl -d test -r 0 daemon","test/Akira.txt");
	testCommand("cat test/output.txt","Akira\ttest/Akira.txt");
	testCommand("cat test/Akira.txt","Hello Hasegawa");
	testCommand("perl $prgdir/moirai2.pl -d test -r 0 daemon","");
	unlink("test/Akira.txt");
	unlink("test/output.txt");
	unlink("test/message.txt");
	#Testing bash
	createFile("test/input1.txt","Akira\tHello");
	createFile("test/input2.txt","Akira\tWorld");
	createFile("test/command.sh","#\$ -i \$name->input1->\$input1,\$name->input2->\$input2","#\$ -r stdout","echo \"\$input1 \$input2 \$name\"");
	testCommand("perl $prgdir/moirai2.pl -d test test/command.sh","Hello World Akira");
	unlink("test/input1.txt");
	unlink("test/input2.txt");
	unlink("test/command.sh");
}
#Testing containers
sub test4{
	open(OUT,">test/C.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/bash\":\"unamea=\$(uname -a)\",\"https://moirai2.github.io/schema/daemon/output\":\"\$unamea\"}\n";
	close(OUT);
	my $name=`uname -s`;chomp($name);
	testCommandRegex("perl $prgdir/moirai2.pl -d test -s 1 -r unamea test/C.json","^$name");
	testCommandRegex("perl $prgdir/moirai2.pl -d test -q qsub -s 1 -r unamea test/C.json","^$name");
	testCommandRegex("perl $prgdir/moirai2.pl -d test -s 1 -r unamea -c ubuntu test/C.json","^Linux");
	testCommandRegex("perl $prgdir/moirai2.pl -d test -q qsub -s 1 -r unamea -c ubuntu test/C.json","^Linux");
	unlink("test/C.json");
	open(OUT,">test/D.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/container\":\"ubuntu\",\"https://moirai2.github.io/schema/daemon/bash\":\"unamea=\$(uname -a)\",\"https://moirai2.github.io/schema/daemon/output\":\"\$unamea\"}\n";
	close(OUT);
	testCommandRegex("perl $prgdir/moirai2.pl -d test -s 1 -r unamea test/D.json","^Linux");
	testCommandRegex("perl $prgdir/moirai2.pl -d test -q qsub -s 1 -r unamea test/D.json","^Linux");
	testCommandRegex("perl $prgdir/moirai2.pl -d test -s 1 -r unamea -c ubuntu test/D.json","^Linux");
	testCommandRegex("perl $prgdir/moirai2.pl -d test -q qsub -s 1 -r unamea -c ubuntu test/D.json","^Linux");
	unlink("test/D.json");
}
#Testing server
sub test5{
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -a ah3q\@172.18.91.78 exec uname","Linux");
	testCommandRegex("perl $prgdir/moirai2.pl -d test -s 1 -a ah3q\@172.18.91.78 -c ubuntu exec uname -a","^Linux .+ x86_64 x86_64 x86_64 GNU/Linux\$");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -a ah3q\@172.18.91.78 -c singularity/lolcow.sif exec cowsay 'Hello World'"," _____________","< Hello World >"," -------------","        \\   ^__^","         \\  (oo)\\_______","            (__)\\       )\\/\\","                ||----w |","                ||     ||");
	testCommandRegex("perl $prgdir/moirai2.pl -d test -s 1 -a 172.18.91.78 exec hostname","^moirai\\d+-server");
	testCommandRegex("perl $prgdir/moirai2.pl -d test -s 1 -a 172.18.91.78 -q openstack exec hostname","^moirai\\d+-node-\\d+\$");
	testCommand("perl $prgdir/moirai2.pl -d test -s 1 -a ah3q\@172.18.91.78 -c singularity/lolcow.sif -q openstack exec cowsay"," __","<  >"," --","        \\   ^__^","         \\  (oo)\\_______","            (__)\\       )\\/\\","                ||----w |","                ||     ||");
}
sub test6{
}
############################## testCommand ##############################
sub testCommand{
	my @values=@_;
	my $command=shift(@values);
	my $value2=join("\n",@values);
	my ($writer,$file)=tempfile();
	close($writer);
	if(system("$command > $file")){
		print STDERR ">$command\n";
		print STDERR "Command failed...\n";
		return 1;
	}
	my $value1=readText($file);
	chomp($value1);
	if($value2 eq""){if($value1 eq""){return 0;}}
	if($value1 eq $value2){return 0;}
	print STDERR ">$command\n";
	print STDERR "$value1\n";
	print STDERR "$value2\n";
}
############################## testCommandRegex ##############################
sub testCommandRegex{
	my $command=shift();
	my $value2=shift();
	my ($writer,$file)=tempfile();
	close($writer);
	if(system("$command > $file")){
		print STDERR ">$command\n";
		print STDERR "Command failed...\n";
		return 1;
	}
	my $value1=readText($file);
	chomp($value1);
	if($value2 eq""){if($value1 eq""){return 0;}}
	elsif($value1=~/$value2/){return 0;}
	print STDERR ">$command\n";
	print STDERR "$value1\n";
	print STDERR "$value2\n";
}
############################## testSub ##############################
sub testSub{
	my $command=shift();
	my $value2=shift();
	my $value1=eval($command);
	if(compareValues($value1,$value2)==0){return;}
	print STDERR ">$command\n";
	if(ref($value2)eq"ARRAY"||ref($value2)eq"ARRAY"){
		printTable($value1);
		printTable($value2);
	}else{print STDERR "'$value1' != '$value2'\n";}
}
############################## testSubs ##############################
sub testSubs{
	my @value2=@_;
	my $command=shift(@value2);
	my @value1=eval($command);
	if(compareValues(\@value1,\@value2)==0){return;}
	print STDERR ">$command\n";
	printTable(\@value1);
	printTable(\@value2);
}
############################## throwBashJob ##############################
sub throwBashJob{
	my $path=shift();
	my $qjob=shift();
	my $qjobopt=shift();
	my $stdout=shift();
	my $stderr=shift();
	my $servername;
	if($path=~/^(.+\@.+)\:(.+)$/){$servername=$1;$path=$2;}
	my $basename=basename($path,".sh");
	if($qjob eq "sge"){
		my $command="qsub";
		if(defined($servername)){if(!defined(which("$servername:$command",$cmdpaths))){print STDERR "ERROR: $command not found at $servername\n";exit(1);}}
		elsif(!defined(which($command,$cmdpaths))){print STDERR "ERROR: $command not found\n";exit(1);}
		if(defined($qjobopt)){$command.=" $qjobopt";}
		$command.=" $path";
		if(defined($servername)){$command="ssh $servername \"$command\" 2>&1 1>/dev/null";}
		if(system($command)==0){sleep(1);}
		else{appendText("ERROR: Failed to $command",$stderr);}
	}elsif($qjob eq "slurm"){
		my $command="slurm";
		if(defined($servername)){if(!defined(which("$servername:$command",$cmdpaths))){print STDERR "ERROR: $command not found at $servername\n";exit(1);}}
		elsif(!defined(which($command,$cmdpaths))){print STDERR "ERROR: $command not found\n";exit(1);}
		$command.=" -o $stdout\n";
		$command.=" -e $stderr\n";
		if(defined($qjobopt)){$command.=" $qjobopt";}
		$command.=" $path";
		if(defined($servername)){$command="ssh $servername \"$command\" 2>&1 1>/dev/null";}
		if(system($command)==0){sleep(1);}
		else{print STDERR "ERROR: Failed to $command\n";exit(1);}
	}elsif($qjob eq "openstack"){
		my $flavor=defined($opt_V)?$opt_V:"1Core-8GiB-36GiB";
		my $image=defined($opt_I)?$opt_I:"snapshot-singularity";
		my $command;
		if(defined($servername)){
			$command="ssh $servername \"openstack.pl -q -i $image -f $flavor run bash $path > $stdout 2> $stderr &\"";
		}else{
			$command="openstack.pl -q -i $image -f $flavor run $path > $stdout 2> $stderr &";
		}
		if(system($command)==0){sleep(1);}
		else{print STDERR "ERROR: Failed to $command\n";exit(1);}
	}elsif(defined($servername)){
		my $command="ssh $servername \"bash $path > $stdout 2> $stderr &\"";
		if(system($command)==0){sleep(1);}
		else{print STDERR "ERROR: Failed to $command\n";exit(1);}
	}else{
		my $command="bash $path >$stdout 2>$stderr &";
		if(system($command)==0){sleep(1);}
		else{print STDERR "ERROR: Failed to $command\n";exit(1);}
	}
}
############################## throwJobs ##############################
sub throwJobs{
	my @variables=@_;
	my $url=shift(@variables);
	my $command=shift(@variables);
	my $processes=shift(@variables);
	my $qjob=$command->{$urls->{"daemon/qjob"}};
	my $qjobopt=$command->{$urls->{"daemon/qjob/opt"}};
	my $serverpath=$command->{$urls->{"daemon/serverpath"}};
	my ($username,$servername,$serverdir)=splitServerPath($serverpath);
	if(scalar(@variables)==0){return;}
	my ($fh,$path)=tempfile("bashXXXXXXXXXX",DIR=>"$rootDir/$throwdir",SUFFIX=>".sh");
	chmod(0777,$path);
	my $serverfile;
	if(defined($serverpath)){$serverfile="$serverdir/.moirai2server/".basename($path);}
	my $basename=basename($path,".sh");
	my $stderr=defined($serverpath)?"$serverdir/.moirai2server/$basename.stderr":"$throwdir/$basename.stderr";
	my $stdout=defined($serverpath)?"$serverdir/.moirai2server/$basename.stdout":"$throwdir/$basename.stdout";
	if($qjob eq "sge"){
		print $fh "#\$ -e $stderr\n";
		print $fh "#\$ -o $stdout\n";
	}
	my @ids=();
	foreach my $var(@variables){
		my $execid=$var->{"execid"};
		if(exists($var->{"singularity"})){
			my $container=$command->{$urls->{"daemon/container"}};
			my $base=exists($var->{"server"})?"server":"base";
			my $bashfile=$var->{$base}->{"bashfile"};
			my $stdoutfile=$var->{$base}->{"stdoutfile"};
			my $stderrfile=$var->{$base}->{"stderrfile"};
			my $statusfile=$var->{$base}->{"statusfile"};
			my $logfile=$var->{$base}->{"logfile"};
			my $rootdir=$var->{$base}->{"rootdir"};
			print $fh "cd $rootdir\n";
			print $fh "cmdpath=`which singularity`\n";
			print $fh "echo \"cmdpath=\$cmdpath\" > $stderrfile\n";
			print $fh "echo PATH >> $stderrfile\n";
			print $fh "if [ -z \"\$cmdpath\" ]; then\n";	
			print $fh "echo \"singualarity command not found\" > $stderrfile\n";
			print $fh "echo \"error\t\"`date +\%s` > $statusfile\n";
			print $fh "touch $stdoutfile\n";
			print $fh "touch $logfile\n";
			print $fh "elif [ ! -e $container ]; then\n";	
			print $fh "echo \"'$container' file doesn't exist\" > $stderrfile\n";
			print $fh "echo \"error\t\"`date +\%s` > $statusfile\n";
			print $fh "touch $stdoutfile\n";
			print $fh "touch $logfile\n";
			print $fh "else\n";
			print $fh "\$cmdpath \\\n";
			print $fh "  --silent \\\n";
			print $fh "  exec \\\n";
			print $fh "  --workdir=/root \\\n";
			print $fh "  --bind=$rootdir:/root \\\n";
			print $fh "  $container \\\n";
			print $fh "  /bin/bash $bashfile \\\n";
			print $fh "  > $stdoutfile \\\n";
			print $fh "  2> $stderrfile\n";
			print $fh "fi\n";
		}elsif(exists($var->{"docker"})){
			my $container=$command->{$urls->{"daemon/container"}};
			my $base=defined($var->{"server"})?"server":"base";
			my $bashfile=$var->{"docker"}->{"bashfile"};
			my $stdoutfile=$var->{$base}->{"stdoutfile"};
			my $stderrfile=$var->{$base}->{"stderrfile"};
			my $statusfile=$var->{$base}->{"statusfile"};
			my $logfile=$var->{$base}->{"logfile"};
			my $rootdir=$var->{$base}->{"rootdir"};
			print $fh "cd $rootdir\n";
			print $fh "cmdpath=`which docker`\n";
			print $fh "echo \"cmdpath=\$cmdpath\" > $stderrfile\n";
			print $fh "echo PATH >> $stderrfile\n";
			print $fh "if [ -z \"\$cmdpath\" ]; then\n";	
			print $fh "echo \"singualarity command not found\" > $stderrfile\n";
			print $fh "echo \"error\t\"`date +\%s` > $statusfile\n";
			print $fh "touch $stdoutfile\n";
			print $fh "touch $logfile\n";
			print $fh "elif [[ \"\$(docker images -q $container 2> /dev/null)\" == \"\" ]]; then\n";
			print $fh "echo \"'$container' docker doesn't exist\" > $stderrfile\n";
			print $fh "echo \"error\t\"`date +\%s` > $statusfile\n";
			print $fh "touch $stdoutfile\n";
			print $fh "touch $logfile\n";
			print $fh "else\n";
			print $fh "\$cmdpath \\\n";
			print $fh "  run \\\n";
			print $fh "  --rm \\\n";
			print $fh "  --workdir=/root \\\n";
			print $fh "  -v '$rootdir:/root' \\\n";
			print $fh "  $container \\\n";
			print $fh "  /bin/bash $bashfile \\\n";
			print $fh "  > $stdoutfile \\\n";
			print $fh "  2> $stderrfile\n";
			print $fh "fi\n";
		}elsif(exists($var->{"server"})){
			my $bashfile=$var->{"server"}->{"bashfile"};
			my $stdoutfile=$var->{"server"}->{"stdoutfile"};
			my $stderrfile=$var->{"server"}->{"stderrfile"};
			my $rootdir=$var->{"server"}->{"rootdir"};
			print $fh "cd $rootdir\n";
			print $fh "bash $bashfile \\\n";
			print $fh "  > $stdoutfile \\\n";
			print $fh "  2> $stderrfile\n";
		}else{
			my $bashfile=$var->{"base"}->{"bashfile"};
			my $stdoutfile=$var->{"base"}->{"stdoutfile"};
			my $stderrfile=$var->{"base"}->{"stderrfile"};
			my $rootdir=$var->{"base"}->{"rootdir"};
			print $fh "cd $rootdir\n";
			print $fh "bash $bashfile \\\n";
			print $fh "  > $stdoutfile \\\n";
			print $fh "  2> $stderrfile\n";
		}
		push(@ids,$execid);
		if(exists($var->{"server"})){
			my $fromDir=$var->{"base"}->{"workdir"};
			my $toDir=$var->{"server"}->{"workdir"};
			rsyncDirectory("$fromDir/","$username\@$servername:$toDir/");
		}
	}
	print $fh "if [ -e $stdout ] && [ ! -s $stdout ]; then\n";
	print $fh "rm $stdout\n";
	print $fh "fi\n";
	print $fh "if [ -e $stderr ] && [ ! -s $stderr ]; then\n";
	print $fh "rm $stderr\n";
	print $fh "fi\n";
	if(defined($serverfile)){print $fh "rm $serverfile\n";}
	else{print $fh "rm $path\n";}
	close($fh);
	#Upload input files to the server
	if(defined($serverfile)){
		uploadIfNecessary($path,"$username\@$servername:$serverfile");
		unlink($path);
		foreach my $var(@variables){uploadInputs($command,$var);}
	}
	#$process is updated when job is thrown
	#Before this, process is empty
	foreach my $id(@ids){
		my ($writer,$tempfile)=tempfile();
		writeLog($id,$urls->{"daemon/execute"}."\tprocessed");
		my $logfile=Cwd::abs_path("$jobdir/$id.txt");
		my $processfile="$processdir/$id.txt";
		system("mv $logfile $processfile");
		$processes->{$id}=loadLogFile($processfile);
	}
	my $date=getDate("/");
	my $time=getTime(":");
	if(defined($opt_l)){
		my $container=$command->{$urls->{"daemon/container"}};
		print "#Submitting: ".join(",",@ids);
		if(defined($servername)){print " at '$servername' server";}
		if(defined($container)){print " using '$container' container";}
		if(defined($qjob)){print " through '$qjob' system";}
		print "\n";
	}
	if(defined($serverfile)){
		throwBashJob("$username\@$servername:$serverfile",$qjob,$qjobopt,$stdout,$stderr);
	}else{
		throwBashJob($path,$qjob,$qjobopt,$stdout,$stderr);
	}
}
############################## uploadIfNecessary ##############################
sub uploadIfNecessary{
	my $from=shift();
	my $to=shift();
	my $timeFrom=checkTimestamp($from);
	my $timeTo=checkTimestamp($to);
	if(!defined($timeTo)||$timeFrom>$timeTo){system("scp $from $to 2>&1 1>/dev/null");}
}
############################## uploadInputs ##############################
sub uploadInputs{
	my $command=shift();
	my $var=shift();
	my $serverpath=$command->{$urls->{"daemon/serverpath"}};
	my ($username,$servername,$serverdir)=splitServerPath($serverpath);
	my $rootdir=$var->{"base"}->{"rootdir"};
	foreach my $input(@{$command->{"input"}}){
		if(!exists($var->{$input})){next;}
		my $inputfile=$var->{$input};
		my $fromFile="$rootdir/$inputfile";
		my $toFile="$serverpath/$inputfile";
		if(defined($opt_l)){print "#Uploading: $fromFile => $toFile\n";}
		uploadIfNecessary($fromFile,$toFile);
	}
}
############################## which ##############################
sub which{
	my $cmd=shift();
	my $hash=shift();
	if(!defined($hash)){$hash={};}
	if(exists($hash->{$cmd})){return $hash->{$cmd};}
	my $servername;
	my $command=$cmd;
	if($command=~/^(.+\@.+)\:(.+)$/){
		$servername=$1;
		$command=$2;
	}
	my $result;
	if(defined($servername)){
		open(CMD,"ssh $servername 'which $command' 2>&1 |");
		while(<CMD>){chomp;if($_ ne ""){$result=$_;}}
		close(CMD);
	}else{
		open(CMD,"which $command 2>&1 |");
		while(<CMD>){chomp;if($_ ne ""){$result=$_;}}
		close(CMD);
	}
	if($result ne ""){$hash->{$cmd}=$result;}
	return $result;
}
############################## writeLog ##############################
sub writeLog{
	my @lines=@_;
	my $execid=shift(@lines);
	my $logfile="$jobdir/$execid.txt";
	open(OUT,">>$logfile");
	foreach my $line(@lines){print OUT "$line\n";}
	close(OUT);
	return $logfile;
}
############################## writeScript ##############################
sub writeScript{
	my $url=shift();
	my $outdir=shift();
	my $commands=shift();
	my $command=loadCommandFromURL($url,$commands);
	my $basename=basename($url,".json");
	my $outfile="$outdir/$basename.sh";
	my @outs=();
	push(@outs,$outfile);
	open(OUT,">$outfile");
	foreach my $line(@{$command->{$urls->{"daemon/bash"}}}){
		$line=~s/\$workdir\///g;
		print OUT "$line\n";
	}
	close(OUT);
	if(exists($command->{$urls->{"daemon/script"}})){
		foreach my $script(@{$command->{$urls->{"daemon/script"}}}){
			my $path="$outdir/".$script->{$urls->{"daemon/script/name"}};
			$path=~s/\$workdir\///g;
			push(@outs,$path);
			open(OUT,">$path");
			foreach my $line(@{$script->{$urls->{"daemon/script/code"}}}){print OUT "$line\n";}
			close(OUT);
		}
	}
	return @outs;
}
