#!/usr/bin/perl
use strict 'vars';
use Cwd;
use File::Basename;
use File::Temp qw/tempfile tempdir/;
use FileHandle;
use Getopt::Std;
use IO::File;
use Time::localtime;
############################## HEADER ##############################
my ($program_name,$program_directory,$program_suffix)=fileparse($0);
$program_directory=Cwd::abs_path($program_directory);
my $program_path="$program_directory/$program_name";
my $program_version="2022/09/02";
############################## OPTIONS ##############################
use vars qw($opt_a $opt_b $opt_c $opt_d $opt_D $opt_E $opt_f $opt_F $opt_g $opt_G $opt_h $opt_H $opt_i $opt_I $opt_j $opt_l $opt_m $opt_M $opt_o $opt_O $opt_p $opt_q $opt_Q $opt_r $opt_R $opt_s $opt_S $opt_t $opt_T $opt_u $opt_U $opt_v $opt_V $opt_w $opt_x $opt_X $opt_Z);
getopts('a:b:c:d:D:E:f:F:g:G:hHi:j:I:lm:M:o:O:pq:Q:R:r:s:S:tTuUv:V:w:xX:Z:');
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
	print "             error  Check error logs\n";
	print "              exec  Execute user specified command from ARGUMENTS\n";
	print "              html  Output HTML files of command/logs/database\n";
	print "           history  List up executed commands\n";
	print "                ls  Create triples from directories/files and show or store them in triple database\n";
	print "               log  Print out logs information of processes\n";
	print "              open  Open .moirai2 directory (for Mac only)\n";
	print "         newdaemon  Setup a new daemon specified server\n";
	print "         openstack  Use openstack.pl to create new instance to process jobs\n";
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
		print "2022/07/30  Added flag handler where as soon as jobs are created, flags are removed from db\n";
		print "2022/07/24  Added user and group for docker run\n";
		print "2022/07/11  Refactored moirai2.pl and rdf.pl\n";
		print "2022/05/25  Update mode added where input/output relation is ignored\n";
		print "2022/05/14  Added error command functionality to view error logs\n";
		print "2022/05/10  Added a function to stop jobs ended with error\n";
		print "2022/05/09  Added a function to stop duplicated jobs\n";
		print "2022/04/24  Fixing bugs in remote server and job server\n";
		print "2022/04/20  Fixing small bugs on remote server functionality\n";
		print "2022/04/14  Daemon system completed\n";
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
$urls->{"daemon/default"}="https://moirai2.github.io/schema/daemon/default";
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
$urls->{"daemon/hostname"}="https://moirai2.github.io/schema/daemon/hostname";
$urls->{"daemon/input"}="https://moirai2.github.io/schema/daemon/input";
$urls->{"daemon/inputs"}="https://moirai2.github.io/schema/daemon/inputs";
$urls->{"daemon/localdir"}="https://moirai2.github.io/schema/daemon/localdir"; 
$urls->{"daemon/ls"}="https://moirai2.github.io/schema/daemon/ls";
$urls->{"daemon/maxjob"}="https://moirai2.github.io/schema/daemon/maxjob";
$urls->{"daemon/output"}="https://moirai2.github.io/schema/daemon/output";
$urls->{"daemon/process/lastupdate"}="https://moirai2.github.io/schema/daemon/process/lastupdate";
$urls->{"daemon/processtime"}="https://moirai2.github.io/schema/daemon/processtime";
$urls->{"daemon/qjob"}="https://moirai2.github.io/schema/daemon/qjob";
$urls->{"daemon/qjob/opt"}="https://moirai2.github.io/schema/daemon/qjob/opt";
$urls->{"daemon/query/in"}="https://moirai2.github.io/schema/daemon/query/in";
$urls->{"daemon/query/out"}="https://moirai2.github.io/schema/daemon/query/out";
$urls->{"daemon/rdfdb"}="https://moirai2.github.io/schema/daemon/rdfdb";
$urls->{"daemon/remotepath"}="https://moirai2.github.io/schema/daemon/remotepath";
$urls->{"daemon/return"}="https://moirai2.github.io/schema/daemon/return";
$urls->{"daemon/rootdir"}="https://moirai2.github.io/schema/daemon/rootdir";
$urls->{"daemon/script"}="https://moirai2.github.io/schema/daemon/script";
$urls->{"daemon/script/code"}="https://moirai2.github.io/schema/daemon/script/code";
$urls->{"daemon/script/name"}="https://moirai2.github.io/schema/daemon/script/name";
$urls->{"daemon/script/path"}="https://moirai2.github.io/schema/daemon/script/path";
$urls->{"daemon/serverpath"}="https://moirai2.github.io/schema/daemon/serverpath";
$urls->{"daemon/singlethread"}="https://moirai2.github.io/schema/daemon/singlethread";
$urls->{"daemon/sleeptime"}="https://moirai2.github.io/schema/daemon/sleeptime";
$urls->{"daemon/suffix"}="https://moirai2.github.io/schema/daemon/suffix";
$urls->{"daemon/timecompleted"}="https://moirai2.github.io/schema/daemon/timecompleted";
$urls->{"daemon/timeended"}="https://moirai2.github.io/schema/daemon/timeended";
$urls->{"daemon/timeregistered"}="https://moirai2.github.io/schema/daemon/timeregistered";
$urls->{"daemon/timestarted"}="https://moirai2.github.io/schema/daemon/timestarted";
$urls->{"daemon/timestamp"}="https://moirai2.github.io/schema/daemon/timestamp";
$urls->{"daemon/unzip"}="https://moirai2.github.io/schema/daemon/unzip";
$urls->{"daemon/userdefined"}="https://moirai2.github.io/schema/daemon/userdefined";
$urls->{"daemon/workdir"}="https://moirai2.github.io/schema/daemon/workdir";
$urls->{"daemon/workflow"}="https://moirai2.github.io/schema/daemon/workflow";
$urls->{"daemon/workid"}="https://moirai2.github.io/schema/daemon/workid";
$urls->{"daemon/workflow/urls"}="https://moirai2.github.io/schema/daemon/workflow/urls";
############################## MAIN ##############################
#xxxDir is absoute path, xxxdir is relative path
my $rootDir=absolutePath(".");
my $homeDir=absolutePath(`echo ~`);
my $hostname=`hostname`;chomp($hostname);
my $prgmode=shift(@ARGV);
if(defined($opt_q)){if($opt_q eq "qsub"){$opt_q="sge";}elsif($opt_q eq "squeue"){$opt_q="slurm";}}
if(!defined($opt_s)){$opt_s=10;}
if(!defined($opt_m)){$opt_m=1;}
my $sleeptime=$opt_s;
my $maxThread=defined($opt_M)?$opt_M:5;
my $cmdpaths={};
my $md5cmd=which('md5sum',$cmdpaths);
if(!defined($md5cmd)){$md5cmd=which('md5',$cmdpaths);}
my $dbdir=defined($opt_d)?checkDatabaseDirectory($opt_d):undef;
my $moiraidir=".moirai2";
my $bindir="$moiraidir/bin";
my $cmddir="$moiraidir/cmd";
my $crondir="cron";
my $ctrldir="$moiraidir/ctrl";
my $configdir="$ctrldir/config";
my $deletedir="$ctrldir/delete";
my $insertdir="$ctrldir/insert";
my $jobdir="$ctrldir/job";
my $processdir="$ctrldir/process";
my $submitdir="$ctrldir/submit";
my $updatedir="$ctrldir/update";
my $logdir="$moiraidir/log";
my $errordir="$logdir/error";
my $throwdir="$moiraidir/throw";
#if dbdir is homedir, a whole user directory becomes 777, which is bad
#Suddenly ssh login failed with 'Authentication refused: bad ownership or modes for directory'
#I need to rethink about the permission of these directories
#For now, I commented out all chmods.
mkdir($moiraidir);#chmod(0777,$moiraidir);
if(defined($dbdir)){mkdir($dbdir);}#chmod(0777,$dbdir);
mkdir($bindir);#chmod(0777,$bindir);
mkdir($cmddir);#chmod(0777,$cmddir);
mkdir($ctrldir);#chmod(0777,$ctrldir);
mkdir($configdir);#chmod(0777,$configdir);
mkdir($deletedir);#chmod(0777,$deletedir);
mkdir($insertdir);#chmod(0777,$insertdir);
mkdir($jobdir);#chmod(0777,$jobdir);
mkdir($processdir);#chmod(0777,$processdir);
mkdir($submitdir);#chmod(0777,$submitdir);
mkdir($updatedir);#chmod(0777,$updatedir);
mkdir($logdir);#chmod(0777,$logdir);
mkdir($errordir);#chmod(0777,$errordir);
mkdir($throwdir);#chmod(0777,$throwdir);
##### handle commands #####
if(defined($opt_h)){helpMenu($prgmode);}
elsif($prgmode=~/^(clean|clear)$/i){cleanMoiraiFiles(@ARGV);}
elsif($prgmode=~/^check$/i){checkMoirai2IsRunning(@ARGV);}
elsif($prgmode=~/^daemon$/i){runDaemon(@ARGV);}
elsif($prgmode=~/^error$/i){checkError(@ARGV);}
elsif($prgmode=~/^html$/i){createHtml(@ARGV);}
elsif($prgmode=~/^history$/i){historyCommand(@ARGV);}
elsif($prgmode=~/^log$/i){logCommand(@ARGV);}
elsif($prgmode=~/^ls$/i){ls(@ARGV);}
elsif($prgmode=~/^open$/i){openCommand(@ARGV);}
elsif($prgmode=~/^openstack$/i){openstackCommand(@ARGV);}
elsif($prgmode=~/^sortsubs$/i){sortSubs(@ARGV);}
elsif($prgmode=~/^test$/i){test(@ARGV);}
elsif($prgmode=~/^unusedsubs$/i){unusedSubs(@ARGV);}
else{moiraiMain($prgmode);}
############################## absolutePath ##############################
sub absolutePath {
	my $path=shift();
	chomp($path);
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
		elsif(exists($command->{$urls->{"daemon/default"}}->{$input})){$userdefined->{$input}=$command->{$urls->{"daemon/default"}}->{$input};}
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
############################## assignUserdefinedToCommand ##############################
sub assignUserdefinedToCommand{
	my $command=shift();
	my $userdefined=shift();
	my @keys=keys(%{$userdefined});
	if(scalar(@keys)==0){return;}
	if(!exists($command->{$urls->{"daemon/userdefined"}})){$command->{$urls->{"daemon/userdefined"}}={};}
	my $hashtable=$command->{$urls->{"daemon/userdefined"}};
	foreach my $key(@keys){$hashtable->{$key}=$userdefined->{$key}}
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
	$hash->{"filepath"}="$directory/$filename";
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
	my $options=$command->{$urls->{"daemon/command/option"}};
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
	open(OUT,">$bashsrc");
	print OUT "#!/bin/sh\n";
	print OUT "export PATH=$exportpath\n";
	my @systemvars=("cmdurl","execid","base","docker","singularity","server");
	my $inputHash={};
	my @inputvars=();
	foreach my $input(@{$command->{$urls->{"daemon/input"}}}){$inputHash->{$input}=1;push(@inputvars,$input);}
	my @outputvars=();
	foreach my $output(@{$command->{$urls->{"daemon/output"}}}){
		if($output eq "stdout"){next;}
		if($output eq "stderr"){next;}
		if(exists($inputHash->{$output})){next;}
		push(@outputvars,$output);
	}
	print OUT "cmdurl=\"$url\"\n";
	print OUT "execid=\"$execid\"\n";
	print OUT "workdir=\"$workdir\"\n";
	print OUT "rootdir=\"$rootdir\"\n";
	my $tmpExists=existsString("\\\$tmpdir",$command->{$urls->{"daemon/bash"}})||scalar(@outputvars)>0;
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
			print OUT "$key=".jsonEncode($value)."\n";
		}else{
			if(ref($value)eq"ARRAY"){
				print OUT "$key=(";
				for(my $i=0;$i<scalar(@{$value});$i++){
					my $v=$value->[$i];
					if($i>0){print OUT " ";}
					print OUT jsonEncode($v);
				}
				print OUT ")\n";}
			else{print OUT "$key=".jsonEncode($value)."\n";}
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
	if(exists($command->{$urls->{"daemon/script"}})){
		print OUT "mkdir -p \$workdir/bin\n";
		foreach my $script(sort{$a->{$urls->{"daemon/script/name"}} cmp $b->{$urls->{"daemon/script/name"}}}@{$command->{$urls->{"daemon/script"}}}){
			my $name=$script->{$urls->{"daemon/script/name"}};
			my $code=$script->{$urls->{"daemon/script/code"}};
			my $path="\$workdir/bin/$name";
			push(@scriptfiles,$name);
			print OUT "cat<<EOF>$path\n";
			foreach my $line(scriptCodeForBash(@{$code})){print OUT "$line\n";}
			print OUT "EOF\n";
			print OUT "chmod 755 $path\n";
		}
	}
	if($tmpExists){
		print OUT "mkdir -p /tmp/\$execid\n";
		print OUT "ln -s /tmp/\$execid \$tmpdir\n";
	}
	#print OUT "record ".$urls->{"daemon/execid"}." $execid\n";
	#print OUT "record ".$urls->{"daemon/command"}." $url\n";
	#if(scalar(@inputvars)>0){
	#	foreach my $input(@inputvars){
	#		print OUT "if [[ \"\$(declare -p $input)\" =~ \"declare -a\" ]]; then\n";
	#		print OUT "for out in \${$input"."[\@]} ; do\n";
	#		print OUT "record \"\$cmdurl#$input\" \"\$out\"\n";
	#		print OUT "done\n";
	#		print OUT "else\n";
	#		print OUT "record \"\$cmdurl#$input\" \"\$$input\"\n";
	#		print OUT "fi\n";
	#	}
	#}
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
		foreach my $input(@{$command->{$urls->{"daemon/input"}}}){
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
	foreach my $line(@{$command->{$urls->{"daemon/bash"}}}){
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
	my $insertIns=[];
	my $insertOuts={};
	if(exists($command->{$urls->{"daemon/query/out"}})){
		foreach my $insert(@{$command->{$urls->{"daemon/query/out"}}}){
			my $hit=0;
			foreach my $output(@outputvars){
				if($insert=~/$output/){
					if(exists($insertOuts->{$output})){push(@{$insertOuts->{$output}},$insert);}
					else{$insertOuts->{$output}=[$insert];}
					$hit=1;
					last;
				}
			}
			if($hit==0){push(@{$insertIns},$insert)}
		}
	}
	if(scalar(@{$insertIns})>0){
		foreach my $insert(@{$insertIns}){print OUT "echo \"insert $insert\"\n";}
	}
	if(scalar(@outputvars)>0){
		foreach my $output(@outputvars){
			print OUT "if [[ \"\$(declare -p $output)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$output"."[\@]} ; do\n";
			print OUT "record \"\$cmdurl#$output\" \"\$out\"\n";
			if(exists($insertOuts->{$output})){
				foreach my $insert(@{$insertOuts->{$output}}){
					my $line="insert $insert";
					$line=~s/\$$output/\$out/g;
					print OUT "echo \"$line\"\n";
				}
			}
			print OUT "done\n";
			print OUT "else\n";
			print OUT "record \"\$cmdurl#$output\" \"\$$output\"\n";
			if(exists($insertOuts->{$output})){
				foreach my $insert(@{$insertOuts->{$output}}){
					print OUT "echo \"insert $insert\"\n";
				}
			}
			print OUT "fi\n";
		}
	}
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
############################## c ##############################
sub moiraiFinally{
	my @execids=@_;
	my $commands=shift(@execids);
	my $processes=shift(@execids);
	my $result=0;
	foreach my $execid(@execids){
		my $process=$processes->{$execid};
		if(returnError($execid)eq"error"){$result=1;}
		my $cmdurl=$process->{$urls->{"daemon/command"}};
		my $command=$commands->{$cmdurl};
		foreach my $returnvalue(@{$command->{$urls->{"daemon/return"}}}){
			my $match="$cmdurl#$returnvalue";
			if($returnvalue eq "stdout"){$match="stdout";}
			elsif($returnvalue eq "stderr"){$match="stderr";}
			returnResult($execid,$match);
		}
	}
	if(defined($opt_Z)){touchFile($opt_Z);}
	if($result==1){exit(1);}
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
############################## checkError ##############################
sub checkError{
	my $history=getHistory($errordir);
	my $index=1;
	my @execids=sort{$a cmp $b}keys(%{$history});
	if(scalar(@execids)==0){exit(1);}
	foreach my $execid(@execids){
		my $hash=$history->{$execid};
		my $timeEnd=$hash->{"time"}->{"end"};
		my @stderrs=@{$hash->{"stderr"}};
		my @cmdLines=@{$hash->{"commandline"}};
		my @bashLines=@{$hash->{"bashline"}};
		my $variables=$hash->{"variable"};
		print "\n";
		print "$index) $execid ($timeEnd)\n";
		foreach my $stderr(@stderrs){print "$stderr\n";}
		foreach my $key(sort{$a cmp $b}keys(%{$variables})){
			my $value=$variables->{$key};
			print "$key=$value\n";
		}
		foreach my $bashLine(@bashLines){print "$bashLine\n";}
		$index++;
	}
	print "\n";
	print "Do you want to delete all error logs [y/n]? ";
	if(getYesOrNo()){
		foreach my $execid(keys(%{$history})){
			my $path=$history->{$execid}->{"filepath"};
			print "rm $path\n";
			unlink($path);
		}
	}
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
############################## checkMoirai2IsRunning ##############################
sub checkMoirai2IsRunning{
	my $mode=shift();
	if(!defined($mode)){$mode="daemon";}
	if($mode eq "daemon"){
		my $username=`whoami`;
		chomp($username);
		my @lines=`ps -fu $username`;
		my $found=0;
		foreach my $line(@lines){
			if($line=~/moirai2.pl.*\scheck\s/){}
			elsif($line=~/moirai2.pl.*\sdaemon\s/){$found++;}
		}
		if($found>0){print "$found\n";}
	}
}
############################## checkProcessStatus ##############################
sub checkProcessStatus{
	my $process=shift();
	my $lastUpdate=$process->{$urls->{"daemon/process/lastupdate"}};
	my $lastStatus=$process->{$urls->{"daemon/execute"}};
	my $workdir=$process->{$urls->{"daemon/workdir"}};
	if(ref($lastStatus)eq"ARRAY"){$lastStatus=$lastStatus->[scalar(@{$lastStatus})-1];}
	if(!defined($workdir)){#This happens when process is running on different server
		my $execid=$process->{$urls->{"daemon/execid"}};
		$workdir="$moiraidir/$execid";
	}
	my $statusfile="$workdir/status.txt";
	if(!fileExists($statusfile)){return;}
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
		$process->{$urls->{"daemon/process/lastupdate"}}=$timestamp;
		$process->{$urls->{"daemon/execute"}}=$currentStatus;
		if($currentStatus eq $lastStatus){return;}
		else{return $currentStatus;}
	}else{
		return;
	}
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
############################## cleanMoiraiFiles ##############################
sub cleanMoiraiFiles{
	my @arguments=@_;
	my $hash={};
	foreach my $arg(@arguments){
		if($arg=~/^bin$/){$hash->{"bin"}=1;}
		if($arg=~/^cmd$/){$hash->{"cmd"}=1;}
		if($arg=~/^ctrl$/){$hash->{"ctrl"}=1;}
		if($arg=~/^dir$/){$hash->{"dir"}=1;}
		if($arg=~/^error$/){$hash->{"error"}=1;}
		if($arg=~/^log$/){$hash->{"log"}=1;}
		if($arg=~/^all$/){
			$hash->{"bin"}=1;
			$hash->{"cmd"}=1;
			$hash->{"ctrl"}=1;
			$hash->{"dir"}=1;
			$hash->{"error"}=1;
			$hash->{"log"}=1;
		}
	}
	if(-e "$jobdir.lock"){unlink("$jobdir.lock");}
	if(exists($hash->{"bin"})){foreach my $file(getFiles("$moiraidir/bin")){system("rm $file");}}
	if(exists($hash->{"cmd"})){foreach my $file(getFiles("$moiraidir/cmd")){system("rm $file");}}
	if(exists($hash->{"ctrl"})){
		foreach my $file(getFiles("$ctrldir/delete")){system("rm $file");}
		foreach my $file(getFiles("$ctrldir/insert")){system("rm $file");}
		foreach my $file(getFiles("$ctrldir/job")){system("rm $file");}
		foreach my $file(getFiles("$ctrldir/process")){system("rm $file");}
		foreach my $dir(getDirs("$ctrldir/process")){foreach my $file(getFiles($dir)){system("rm $file");}}
		foreach my $file(getFiles("$ctrldir/submit")){system("rm $file");}
		foreach my $file(getFiles("$ctrldir/update")){system("rm $file");}
		foreach my $file(getFiles("$moiraidir/throw")){system("rm $file");}
	}
	foreach my $dir(getDirs("$ctrldir/process")){system("rm -r $dir");}
	if(exists($hash->{"dir"})){foreach my $dir(getDirs($moiraidir,"\\d{14}")){system("rm -r $dir");}}
	if(exists($hash->{"error"})){foreach my $file(getFiles("$logdir/error")){system("rm $file");}}
	if(exists($hash->{"log"})){foreach my $dir(getDirs($logdir,"\\d{8}")){system("rm -r $dir");}}
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
	if(ref($value1)eq"ARRAY"){
		if(ref($value2) ne "ARRAY"){return 1;}
		my $l1=scalar(@{$value1});
		my $l2=scalar(@{$value2});
		if($l1!=$l2){return 1;}
		for(my $i=0;$i<$l1;$i++){if(compareValues($value1->[$i],$value2->[$i])){return 1;}}
		return;
	}elsif(ref($value1)eq"HASH"){
		if(ref($value2)ne"HASH"){return 1;}
		my $l1=scalar(keys(%{$value1}));
		my $l2=scalar(keys(%{$value2}));
		if($l1!=$l2){return 1;}
		foreach my $key(keys(%{$value1})){
			if(compareValues($value1->{$key},$value2->{$key})){return 1;}
		}
		return;
	}elsif(ref($value2)eq"ARRAY"){return 1;}
	elsif(ref($value2)eq"HASH"){return 1;}
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
	my $rdfdb=exists($command->{$urls->{"daemon/rdfdb"}})?$command->{$urls->{"daemon/rdfdb"}}."/":defined($dbdir)?"$dbdir/":undef;
	if(exists($process->{$urls->{"daemon/hostname"}})){$processfile="$processdir/".$process->{$urls->{"daemon/hostname"}}."/$execid.txt";}
	my $dirname=substr(substr($execid,-18),0,8);
	my $serverpath=$process->{$urls->{"daemon/serverpath"}};
	if(defined($serverpath)){
		my $fromdir=$srcdir;
		my $todir="$serverpath/.moirai2/";
		my $statusFrom="$srcdir/status.txt";
		my $statusTo="$serverpath/.moirai2/$execid/status.txt";
		my ($tmpwriter,$tmpfile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
		close($tmpwriter);
		system("mv $statusFrom $tmpfile");
		rsyncDirectory($fromdir,$todir);
		uploadOutputs($command,$process);
		removeInputsOutputs($command,$process);
		system("scp $tmpfile $statusTo 2>&1 1>/dev/null");
		unlink($tmpfile);
		# Moirai daemon looks for a string "completed" in a status file and proceed to completion.
		# If output files are huge, there is a chance complete process is executed before uploads are completed.
		# To avoid this, we temporary move the status file to /tmp directory and upload all files beforehand.
		# After completion, status file will be uploaded to the server.
		# Moirai daemon at the server might look for status file, so "touch" is used to create empty file.
	}
	#outputfile
	my $outputfile="$logdir/$dirname/$execid.txt";
	mkdir(dirname($outputfile));
	#processfile
	my $timeregistered;
	my $reader=openFile($processfile);
	while(<$reader>){
		chomp;my ($key,$val)=split(/\t/);
		if($key eq $urls->{"daemon/timeregistered"}){$timeregistered=$val;}
	}
	close($reader);
	if(defined($opt_l)){print "#Completing: $execid with '$status' status\n";}
	$stderrfile="$workdir/stderr.txt";
	$stdoutfile="$workdir/stdout.txt";
	$statusfile="$workdir/status.txt";
	$logfile="$workdir/log.txt";
	$bashfile="$workdir/run.sh";
	#logfile
	my $log=loadProcessFile($logfile);
	$log->{$urls->{"daemon/timeregistered"}}=$timeregistered;
	while(my ($key,$val)=each(%{$process})){
		if($key eq $urls->{"daemon/process/lastupdate"}){next;}
		# output specified in job/process might be obsolete in some cases.
		# For example if $id is input parameter and output is specified in format 'output=$id.txt',
		# In job/process, it's noted as output=$id.txt, but in log file, $output might be akira.txt
		if(exists($log->{$key})){next;}
		$log->{$key}=$val;
	}
	#download outputs
	if(exists($process->{$urls->{"daemon/localdir"}})){
		my $localdir=$process->{$urls->{"daemon/localdir"}};
		downloadOutputs($command,$process);
		removeFilesFromServer($command,$process);
		unlink("$localdir/run.sh");
	}
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
	my ($logwriter,$logoutput)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
	print $logwriter "######################################## $execid ########################################\n";
	foreach my $key(sort{$a cmp $b}keys(%{$log})){
		if(ref($log->{$key})eq"ARRAY"){foreach my $val(@{$log->{$key}}){print $logwriter "$key\t$val\n";}}
		else{print $logwriter "$key\t".$log->{$key}."\n";}
	}
	print $logwriter "######################################## time ########################################\n";
	#statusfile
	my $reader=openFile($statusfile);
	print $logwriter "registered\t".getDate("/",$timeregistered)." ".getTime(":",$timeregistered)."\n";
	while(<$reader>){
		chomp;
		my ($id,$time)=split(/\t/);
		print $logwriter "$id\t".getDate("/",$time)." ".getTime(":",$time)."\n";
	}
	close($reader);
	#stdoutfile
	$reader=openFile($stdoutfile);
	my ($insertwriter,$insertfile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
	my ($deletewriter,$deletefile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
	my ($updatewriter,$updatefile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
	my $stdoutcount=0;
	my $insertcount=0;
	my $deletecount=0;
	my $updatecount=0;
	while(<$reader>){
		chomp;
		if(/insert\s+(.+)\-\>(.+)\-\>(.+)/i){print $insertwriter "$1\t$rdfdb$2\t$3\n";$insertcount++;next;}
		if(/delete\s+(.+)\-\>(.+)\-\>(.+)/i){print $deletewriter "$1\t$rdfdb$2\t$3\n";$deletecount++;next;}
		if(/update\s+(.+)\-\>(.+)\-\>(.+)/i){print $updatewriter "$1\t$rdfdb$2\t$3\n";$updatecount++;next;}
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
		while(<$reader>){print $logwriter "$_";}
		close($reader);
		system("mv $insertfile $insertdir/".basename($insertfile));
	}else{unlink($insertfile);}
	#updatefile
	if($updatecount>0){
		print $logwriter "######################################## update ########################################\n";
		my $reader=openFile($updatefile);
		while(<$reader>){print $logwriter "$_";}
		close($reader);
		system("mv $updatefile $updatedir/".basename($updatefile));
	}else{unlink($updatefile);}
	#deletefile
	if($deletecount>0){
		print $logwriter "######################################## delete ########################################\n";
		my $reader=openFile($deletefile);
		while(<$reader>){print $logwriter "$_";}
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
	if(exists($command->{$urls->{"daemon/script"}})){
		my @files=();
		foreach my $script(@{$command->{$urls->{"daemon/script"}}}){
			my $name=$script->{$urls->{"daemon/script/name"}};
			push(@files,"$workdir/bin/$name");
		}
		removeFile(@files);
		removeDirs("$workdir/bin");
	}
	#complete
	system("mv $logoutput $outputfile");
	removeFile($bashfile,$logfile,$stdoutfile,$stderrfile,$processfile);
	# status file is touched after 1 second at the end processs,
	# There is a possibility that black status.txt is made by the touch.
	# So we need to make sure we wait 1 second before removing the status file.
	if(!defined($serverpath)){sleep(1);}
	removeFile($statusfile);
	removeDirs($srcdir,$workdir);
	if($status eq "completed"){}
	elsif($status eq "error"){system("mv $outputfile $errordir/".basename($outputfile));}
}
############################## controlDelete ##############################
sub controlDelete{
	my @files=getFiles($deletedir);
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $program_directory/rdf.pl -q -f tsv delete";
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
	my $command="cat ".join(" ",@files)."|perl $program_directory/rdf.pl -q -f tsv insert";
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
			if($prgmode=~/^daemon$/){
				#daemon's repeat limit is used to test functionality.
				#Very special case.
				if(!defined($opt_R)){delete($processes->{$execid});}
			}
			$completed++;
		}else{writeProcessArray($execid,$urls->{"daemon/execute"}."\t$status");}
	}
	return $completed;
}
############################## controlUpdate ##############################
sub controlUpdate{
	my @files=getFiles($updatedir);
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $program_directory/rdf.pl -q -f tsv update";
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
############################## convertToArray ##############################
sub convertToArray{
	my $array=shift();
	my $default=shift();
	if(!defined($array)){return [];}
	if(ref($array)ne"ARRAY"){
		if($array=~/,/){my @temp=split(/,/,$array);$array=\@temp;}
		else{$array=[$array];}
	}
	my @temps=();
	foreach my $variable(@{$array}){
		if(ref($variable)eq"ARRAY"){
			foreach my $var(@{$variable}){push(@temps,$var);}
		}elsif(ref($variable)eq"HASH"){
			foreach my $key(sort{$a cmp $b}keys(%{$variable})){
				my $value=$variable->{$key};
				if($key=~/^\$(.+)$/){$key=$1;}
				push(@temps,$key);
				if(defined($default)){$default->{$key}=$value;}
			}
			next;
		}else{
			if($variable=~/^\$(.+)$/){$variable=$1;}
			push(@temps,$variable);
		}
	}
	return \@temps;
}
############################## copyJobToServer ##############################
sub copyJobToServer{
	my $execid=shift();
	my $serverpath=shift();
	my $commands=shift();
	my $jobfile="$jobdir/$execid.txt";
	my $serverfile="$serverpath/.moirai2/ctrl/job/$execid.txt";
	scpFileIfNecessary($jobfile,$serverfile);
	return $jobfile;
}
############################## copyToJobServer ##############################
sub copyToJobServer{
	my @execids=@_;
	my $serverpath=shift(@execids);
	my $commands=shift(@execids);
	my $processes={};
	foreach my $execid(@execids){
		my $jobfile=copyJobToServer($execid,$serverpath);
		my $process=loadProcessFile($jobfile);
		my $url=$process->{$urls->{"daemon/command"}};
		my $command=loadCommandFromURL($url,$commands);
		$process->{$urls->{"daemon/serverpath"}}=$serverpath;
		uploadInputs($command,$process);
		uploadCommand($process,$serverpath);
		#move job file to appropriate directory
		writeJobArray($execid,$urls->{"daemon/serverpath"}."\t$serverpath");
		my ($username,$servername,$serverdir)=splitServerPath($serverpath);
		mkdir("$processdir/$servername");
		rename($jobfile,"$processdir/$servername/".basename($jobfile));
		$processes->{$execid}=$process;
	}
	return $processes;
}
############################## createDirs ##############################
sub createDirs{
	my @dirs=@_;
	foreach my $dir(@dirs){
		if($dir=~/^(.+\@.+)\:(.+)$/){system("ssh $1 'mkdir -p $2' 2>&1 1>/dev/null");}
		else{system("mkdir -p $dir 2>&1 1>/dev/null");}
	}
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
	my @arguments=@_;
	my $menu=shift(@arguments);
	if($menu=~/^command$/i){
		my $commands={};
		foreach my $url(@arguments){if($url=~/\.json$/){loadCommandFromURL($url,$commands);}}
		my @lines=();
		push(@lines,"<table>");
		foreach my $url(@arguments){push(@lines,createHtmlCommand($commands->{$url}));}
		push(@lines,"</table>");
		foreach my $line(@lines){print "$line\n";}
	}elsif($menu=~/^form$/i){
		my $url=shift(@arguments);
		my @lines=();
		my $command=loadCommandFromURL($url);
		push(@lines,createHtmlForm($command));
		foreach my $line(@lines){print "$line\n";}
	}elsif($menu=~/^function$/i){
		my $url=shift(@arguments);
		my @lines=();
		my $command=loadCommandFromURL($url);
		push(@lines,createHtmlFunction($command));
		foreach my $line(@lines){print "$line\n";}
	}elsif($menu=~/^database$/i){
		createHtmlDatabase(@arguments);
	}
}
sub createHtmlFunction{
	my $command=shift();
	my @lines=();
	my $url=$command->{$urls->{"daemon/command"}};
	my $suffix=$command->{$urls->{"daemon/suffix"}};
	my @lines=();
	push(@lines,"<script>");
	push(@lines,"var moirai=new moirai2();");
	push(@lines,"\$(document).ready(function() {");
	push(@lines,"moirai.commandResults(\"$url\",function(json){\$('#result').columns({");
	push(@lines,"data:json,");
	push(@lines,"size:25,");
	push(@lines,"schema: [");
	if(exists($command->{$urls->{"daemon/input"}})){
		my $input=$command->{$urls->{"daemon/input"}};
		foreach my $in(@{$input}){
			if(exists($suffix->{$in})){push(@lines,"{\"header\": \"$in\", \"key\": \"$in\", \"template\": '<a href=\"{{$in}}\">{{$in}}</a>'},");}
			else{push(@lines,"{\"header\": \"$in\", \"key\": \"$in\"},");}
		}
	}
	if(exists($command->{$urls->{"daemon/output"}})){
		my $output=$command->{$urls->{"daemon/output"}};
		foreach my $out(@{$output}){
			if(exists($suffix->{$out})){push(@lines,"{\"header\": \"$out\", \"key\": \"$out\", \"template\": '<a href=\"{{$out}}\">{{$out}}</a>'},");}
			else{push(@lines,"{\"header\": \"$out\", \"key\": \"$out\"},");}
		}
	}
	push(@lines,"]");
	push(@lines,"});});");
	push(@lines,"progress();");
	push(@lines,"});");
	push(@lines,"function progress(){");
	push(@lines,"moirai.checkProgress(function(json){\$('#progress').columns({");
	push(@lines,"data:json,");
	push(@lines,"size:10,");
	push(@lines,"schema: [");
	push(@lines,"{\"header\": \"status\", \"key\": \"execute\"},");
	push(@lines,"{\"header\": \"time\", \"key\": \"time\"},");
	push(@lines,"{\"header\": \"logfile\", \"key\": \"logfile\",\"template\": '<a href=\"{{logfile}}\">{{logfile}}</a>'},");
	push(@lines,"]");
	push(@lines,"});});");
	push(@lines,"}");
	push(@lines,"function submitJob(){");
	push(@lines,"moirai.submitJob({");
	push(@lines,"\"url\":\"$url\",");
	if(exists($command->{$urls->{"daemon/input"}})){
		my $input=$command->{$urls->{"daemon/input"}};
		foreach my $in(@{$input}){push(@lines,"\"$in\":\$(\"#$in\").val(),");}
	}
	push(@lines,"});");
	push(@lines,"}");
	return @lines;
}
sub createHtmlForm{
	my $command=shift();
	my @lines=();
	my $defaults=$command->{$urls->{"daemon/default"}};
	if(exists($command->{$urls->{"daemon/command"}})){
		my $url=$command->{$urls->{"daemon/command"}};
		push(@lines,"<tr><th colspan=3><a href=\"$url\">$url</a></th></td>");
	}
	if(exists($command->{$urls->{"daemon/bash"}})){
		my $cmds=$command->{$urls->{"daemon/bash"}};
		my $line="";
		foreach my $cmd(@{$cmds}){
			if($line ne ""){$line.="<br>";}
			$line.=$cmd;
		}
		push(@lines,"<tr><th>command</th><td colspan=2>$line</td></tr>");
	}
	if(exists($command->{$urls->{"daemon/input"}})){
		my $input=$command->{$urls->{"daemon/input"}};
		my $index=0;
		foreach my $in(@{$input}){
			my $line;
			if($index==0){$line="<tr><th rowspan=".scalar(@{$input}).">in</th>";}
			else{$line="<tr>";}
			$line.="<th>\$$in</th><td><input id=\"$in\" type=\"text\" size=50";
			if(exists($defaults->{$in})){$line.=" default=\"".$defaults->{$in}."\"";}
			$line.="></td></tr>";
			push(@lines,$line);
			$index++;
		}
	}
	push(@lines,"<input type=\"button\" onClick=\"submitJob()\" value=\"Submit\"/></input>");
	return @lines;
}
sub createHtmlCommand{
	my $command=shift();
	my $url=shift();
	my @lines=();
	my $suffixs=$command->{$urls->{"daemon/suffix"}};
	if(exists($command->{$urls->{"daemon/command"}})){
		my $url=$command->{$urls->{"daemon/command"}};
		push(@lines,"<tr><th colspan=2><a href=\"$url\">$url</a></th></td>");
	}
	if(exists($command->{$urls->{"daemon/bash"}})){
		my $cmds=$command->{$urls->{"daemon/bash"}};
		my $line="";
		foreach my $cmd(@{$cmds}){
			if($line ne ""){$line.="<br>";}
			$line.=$cmd;
		}
		push(@lines,"<tr><th>cmds</th><td>$line</td></tr>");
	}
	if(exists($command->{$urls->{"daemon/input"}})){
		my $input=$command->{$urls->{"daemon/input"}};
		my $line="";
		foreach my $in(@{$input}){
			if($line ne ""){$line.="<br>";}
			$line.="\$$in";
			if(exists($suffixs->{$in})){$line.=" (suffix=".$suffixs->{$in}.")";}
		}
		push(@lines,"<tr><th>input</th><td>$line</td></tr>");
	}
	if(exists($command->{$urls->{"daemon/output"}})){
		my $output=$command->{$urls->{"daemon/output"}};
		my $line="";
		foreach my $out(@{$output}){
			if($line ne ""){$line.="<br>";}
			$line.="\$$out";
			if(exists($suffixs->{$out})){$line.=" (suffix=".$suffixs->{$out}.")";}
		}
		push(@lines,"<tr><th>output</th><td>$line</td></tr>");
	}
	if(exists($command->{$urls->{"daemon/return"}})){
		my $return=$command->{$urls->{"daemon/return"}};
		push(@lines,"<tr><th>return</th><td>\$$return</td>");
	}
	return @lines;
}
sub createHtmlDatabase{
	print "<html>\n";
	print "<head>\n";
	print "<title>moirai</title>\n";
	print "<script type=\"text/javascript\" src=\"js/vis/vis-network.min.js\"></script>\n";
	print "<script type=\"text/javascript\" src=\"js/jquery/jquery-3.4.1.min.js\"></script>\n";
	print "<script type=\"text/javascript\" src=\"js/jquery/jquery.columns.min.js\"></script>\n";
	print "<script type=\"text/javascript\">\n";
	#my $network=`perl $program_directory/rdf.pl -d $dbdir export network`;
	#chomp($network);
	my $db=`perl $program_directory/rdf.pl export db`;
	chomp($db);
	my $log=`perl $program_directory/rdf.pl export log`;
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
############################## createNewCommandFromLines ##############################
sub createNewCommandFromLines{
	my @cmdlines=@_;
	my $command={};
	$command->{$urls->{"daemon/bash"}}=\@cmdlines;
	return $command;
}
############################## daemonCheckTimestamp ##############################
sub daemonCheckTimestamp{
	my $currentTime=time();
	my $command=shift();
	if(!exists($command->{$urls->{"daemon/timestamp"}})){
		$command->{$urls->{"daemon/timestamp"}}=$currentTime;
		return 1;
	}
	my $cmdurl=$command->{$urls->{"daemon/command"}};
	my $queries=$command->{$urls->{"daemon/query/in"}};
	if(!defined($queries)){return 1;}
	my $rdfdb=$command->{$urls->{"daemon/rdfdb"}};
	my $time1=$command->{$urls->{"daemon/timestamp"}};
	my $hit=0;
	foreach my $query(@{$queries}){
		my @tokens=split(/\-\>/,$query);
		my $predicate=$tokens[1];
		$predicate=~s/\$\w+/%/g;
		my $time2=`perl $program_directory/rdf.pl -d $rdfdb timestamp '$predicate'`;
		chomp($time2);
		if($time1<$time2){$hit=1;last;}
	}
	if($hit){$command->{$urls->{"daemon/timestamp"}}=$currentTime;}
	return $hit;
}
############################## dirExists ##############################
sub dirExists{
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){my $result=`ssh $1 'if [ -d $2 ]; then echo 1; fi'`;chomp($result);return ($result==1);}
	elsif(-d $path){return 1;}
	return;
}
############################## downloadCommand ##############################
sub downloadCommand{
	my $process=shift();
	my $serverpath=shift();
	my ($username,$servername,$serverdir)=splitServerPath($serverpath);
	if(!exists($process->{$urls->{"daemon/command"}})){
		print STDERR "ERROR: Command not specified in job file\n";
		exit(1);
	}
	my $path=$process->{$urls->{"daemon/command"}};
	my $filepath="$username\@$servername:";
	if(defined($serverdir)){$filepath.="$serverdir/$path";}
	else{$filepath.=$path;}
	mkdirs(dirname($path));
	scpFileIfNecessary($filepath,$path);
	return $path;
}
############################## downloadInputs ##############################
sub downloadInputs{
	my $command=shift();
	my $process=shift();
	if(!exists($process->{$urls->{"daemon/serverpath"}})){return;}
	my $serverpath=$process->{$urls->{"daemon/serverpath"}};
	my $url=$process->{$urls->{"daemon/command"}};
	my @files=();
	foreach my $input(@{$command->{$urls->{"daemon/input"}}}){
		if(!exists($process->{"$url#$input"})){next;}
		my $inputfile=$process->{"$url#$input"};
		my $fromfile="$serverpath/$inputfile";
		my $tofile="$rootDir/$inputfile";
		if(defined($opt_l)){print "#Downloading: $fromfile => $tofile\n";}
		system("scp $fromfile $tofile 2>&1 1>/dev/null");
		push(@files,$tofile);
	}
	return @files;
}
############################## downloadJobFiles ##############################
# Read job file from the job server
# Create a temporary job file locally
# Move job file from job to process directory at the job server
sub downloadJobFiles{
	my @files=@_;
	my $serverpath=shift(@files);
	my ($username,$servername,$serverdir)=splitServerPath($serverpath);
	my $jobdir="$serverdir/.moirai2/ctrl/job";
	my $processdir="$serverdir/.moirai2/ctrl/process/$hostname";
	system("ssh $username\@$servername mkdir -p $processdir");
	my @jobfiles=();
	foreach my $file(@files){
		if(defined($opt_l)){print "#Downloading $username\@$servername:$jobdir/$file\n";}
		my $reader=openFile("$username\@$servername:$jobdir/$file");
		my $execid=basename($file,".txt");
		my ($writer,$tmp)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
		my ($writer2,$tmp2)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
		while(<$reader>){chomp;print $writer "$_\n";;print $writer2 "$_\n";}
		close($reader);
		print $writer $urls->{"daemon/serverpath"}."\t$serverpath\n";
		print $writer2 $urls->{"daemon/hostname"}."\t$hostname\n";
		print $writer2 $urls->{"daemon/workdir"}."\t$serverdir/.moirai2/$execid\n";
		close($writer);
		push(@jobfiles,$tmp);
		if(defined($opt_l)){print "#Moving job file from $jobdir/$file to $processdir/.\n";}
		system("ssh $username\@$servername rm $jobdir/$file");
		system("scp $tmp2 $username\@$servername:$processdir/. 2>&1 1>/dev/null");
	}
	return @jobfiles;
}
############################## downloadOutputs ##############################
sub downloadOutputs{
	my $command=shift();
	my $process=shift();
	if(!exists($command->{$urls->{"daemon/remotepath"}})){return;}
	my $remotepath=$command->{$urls->{"daemon/remotepath"}};
	my $url=$process->{$urls->{"daemon/command"}};
	foreach my $output(@{$command->{$urls->{"daemon/output"}}}){
		if(!exists($process->{"$url#$output"})){next;}
		my $outputfile=$process->{"$url#$output"};
		my $fromfile="$remotepath/$outputfile";
		my $tofile="$rootDir/$outputfile";
		if(defined($opt_l)){print "#Downloading: $fromfile => $tofile\n";}
		system("scp $fromfile $tofile 2>&1 1>/dev/null");
	}
}
############################## existsArray ##############################
sub existsArray{
	my $array=shift();
	my $value=shift();
	foreach my $val(@{$array}){if($value eq $val){return 1;}}
	return;
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
	my $cwd=Cwd::abs_path(".");
	return;
}
############################## fileExistsInDirectory ##############################
sub fileExistsInDirectory{
	my $directory=shift();
	opendir(DIR,$directory);
	foreach my $file(readdir(DIR)){
		if($file=~/^\./){next;}
		else{return 1;}
	}
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
	my $input;
	my $output;
	my $script;
	foreach my $line(split(/\n/,$content)){
		if($line=~/^#\$\s?-b\s+?(.+)$/){$command->{$urls->{"daemon/command/option"}}=jsonDecode($1);}
		elsif($line=~/^#\$\s?-c\s+?(.+)$/){$command->{$urls->{"daemon/container"}}=$1;}
		elsif($line=~/^#\$\s?-V\s+?(.+)$/){$command->{$urls->{"daemon/container/flavor"}}=$1;}#-V
		elsif($line=~/^#\$\s?-I\s+?(.+)$/){$command->{$urls->{"daemon/container/image"}}=$1;}#-I
		elsif($line=~/^#\$\s?-E\s+?(.+)$/){$command->{$urls->{"daemon/error/stderr/ignore"}}=handleKeys($1);}#-E
		elsif($line=~/^#\$\s?-F\s+?(.+)$/){$command->{$urls->{"daemon/error/file/empty"}}=handleKeys($1);}#-F
		elsif($line=~/^#\$\s?-O\s+?(.+)$/){$command->{$urls->{"daemon/error/stdout/ignore"}}=handleKeys($1);}#-O
		elsif($line=~/^#\$\s?-f\s+?(.+)$/){$command->{$urls->{"daemon/file/stats"}}=handleKeys($1);}#-f
		elsif($line=~/^#\$\s?-i\s+?(.+)$/){if(defined($input)){$input.=",";}$input.=$1;}#-i
		elsif($line=~/^#\$\s?-m\s+?(.+)$/){$command->{$urls->{"daemon/maxjob"}}=$1;}#-m
		elsif($line=~/^#\$\s?-o\s+?(.+)$/){if(defined($output)){$output.=",";}$output.=$1;}#-o
		elsif($line=~/^#\$\s?-q\s+?(.+)$/){$command->{$urls->{"daemon/qjob"}}=$1;}#-q
		elsif($line=~/^#\$\s?-Q\s+?(.+)$/){$command->{$urls->{"daemon/qjob/opt"}}=$1;}#-Q
		elsif($line=~/^#\$\s?-d\s+?(.+)$/){$command->{$urls->{"daemon/rdfdb"}}=checkDatabaseDirectory($1);}#-d
		elsif($line=~/^#\$\s?-a\s+?(.+)$/){$command->{$urls->{"daemon/remotepath"}}=handleServer($1);}#-a
		elsif($line=~/^#\$\s?-r\s+?(.+)$/){$command->{$urls->{"daemon/return"}}=handleKeys($1);}#-r
		elsif($line=~/^#\$\s?-s\s+?(.+)$/){$command->{$urls->{"daemon/sleeptime"}}=$1;}#-s
		elsif($line=~/^#\$\s?-S\s+?(.+)$/){if(defined($script)){$script.=",";}$script.=$1;}#-S
		elsif($line=~/^#\$\s?-S\s+?(.+)$/){if(defined($script)){$script.=",";}$script.=$1;}#-S
		elsif($line=~/^#\$\s?-T$/){$command->{$urls->{"daemon/singlethread"}}="true";}#-T
		elsif($line=~/^#\$\s?-X\s+?(.+)$/){$command->{$urls->{"daemon/suffix"}}=handleSuffix($1);}#-X
		elsif($line=~/^#\$\s?(.+)\=(.+)$/){
			if(!exists($command->{$urls->{"daemon/userdefined"}})){$command->{$urls->{"daemon/userdefined"}}={};}
			$command->{$urls->{"daemon/userdefined"}}->{$1}=$2;
		}else{push(@lines,$line);}
	}
	if(defined($script)){
		$command->{$urls->{"daemon/script"}}=$script;
		loadScripts($command);
	}
	$command->{$urls->{"daemon/bash"}}=\@lines;
	my $inputKeys={};
	my $suffixs={};
	my $userdefined={};
	if(defined($input)){
		my ($keys,$query)=handleInputOutput($input,$userdefined,$suffixs);
		foreach my $key(@{$keys}){$inputKeys->{$key}=1;}
		my @array=sort{$a cmp $b}keys(%{$inputKeys});
		if(scalar(@array)>0){$command->{$urls->{"daemon/input"}}=\@array;}
		if(defined($query)){$command->{$urls->{"daemon/query/in"}}=$query;}
	}
	my $outputKeys={};
	if(defined($output)){
		my ($keys,$query)=handleInputOutput($output,$userdefined,$suffixs);
		foreach my $key(@{$keys}){if(!exists($inputKeys->{$key})){$outputKeys->{$key}=1;}}
		my @array=sort{$a cmp $b}keys(%{$outputKeys});
		if(scalar(@array)>0){$command->{$urls->{"daemon/output"}}=\@array;}
		if(defined($query)){$command->{$urls->{"daemon/query/out"}}=$query;}
	}
	getBashImport($command,$urls->{"daemon/suffix"},$suffixs);
	getBashImport($command,$urls->{"daemon/userdefined"},$userdefined);
	return $command;
}
sub getBashImport{
	my $command=shift();
	my $url=shift();
	my $hash2=shift();
	if(scalar(keys(%{$hash2}))==0){return;}
	if(!exists($command->{$url})){$command->{$url}={};}
	my $hash1=$command->{$url};
	while(my ($key,$val)=each(%{$hash2})){if(!exists($hash1->{$key})){$hash1->{$key}=$val;}}
}
############################## getContentMd5 ##############################
sub getContentMd5{
	my $content=shift();
	my ($writer,$temp)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
	print $writer "$content";
	close($writer);
	my $md5=`$md5cmd<$temp`;
	chomp($md5);
	return $md5;
}
############################## getDate ##############################
sub getDate{
	my $delim=shift();
	my $time=shift();
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
sub getDatetime{my $time=shift();return getDate("",$time).getTime("",$time);}
############################## getDatetimeISO8601 ##############################
sub getDatetimeISO8601{
	my $time=shift();
	my $timezone=shift();
	if(!defined($timezone)){$timezone="+00:00";}
	return getDate("-",$time)."T".getTime(":",$time).$timezone;
}
############################## getDatetimeJpISO8601 ##############################
sub getDatetimeJpISO8601{my $time=shift();return getDatetimeISO8601($time,"+09:00");}
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
############################## getFileFromExecid ##############################
sub getFileFromExecid{
	my $execid=shift();
	my $dirname=substr(substr(basename($execid,".txt"),-18),0,8);
	if(-e "$errordir/$execid.txt"){return "$errordir/$execid.txt";}
	elsif(-e "$logdir/$dirname/$execid.txt"){return "$logdir/$dirname/$execid.txt";}
	elsif(-e "$logdir/$dirname.tgz"){return "$logdir/$dirname.tgz";}
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
	my $dir=shift();
	if(!defined($dir)){$dir=$logdir}
	my $history={};
	# 0 log/
	# 1 log/20220101/ or log/error/
	my @files=listFilesRecursively("\.txt\$",undef,2,$dir);
	foreach my $file(@files){
		my $execid=basename($file,".txt");
		$history->{$execid}={};
		$history->{$execid}->{"filepath"}=$file;
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
				elsif($1 eq "time"){$flag=4;next;}
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
			elsif($flag==2){
				push(@{$history->{$execid}->{"stderr"}},$_);
			}elsif($flag==3){push(@{$history->{$execid}->{"stdout"}},$_);}
			elsif($flag==4){
				my ($key,$datetime)=split(/\t/);
				$history->{$execid}->{"time"}->{$key}=$datetime;
			}
		}
		my $index=0;
		while(<$reader>){
			chomp;
			$index++;
			if(/^\#{10} (.+) \#{10}$/){if($1 eq "command"){$flag=1;}else{$flag=0;}}
			elsif(/^\#{29}$/){$flag=0;}
			elsif($flag==1){
				push(@{$history->{$execid}->{"bashline"}},$_);
				foreach my $key(keys(%{$history->{$execid}->{"variable"}})){
					my $val=$history->{$execid}->{"variable"}->{$key};
					$_=~s/\$$key/$val/g;
					$_=~s/\$\{$key\}/$val/g;
				}
				push(@{$history->{$execid}->{"commandline"}},$_);
			}
		}
		close($reader);
		if(scalar(keys(%{$history->{$execid}->{"variable"}}))==0){delete($history->{$execid}->{"variable"});}
		if(scalar(@{$history->{$execid}->{"command"}})==0){delete($history->{$execid}->{"command"});}
		if(scalar(@{$history->{$execid}->{"stderr"}})==0){delete($history->{$execid}->{"stderr"});}
		if(scalar(@{$history->{$execid}->{"stdout"}})==0){delete($history->{$execid}->{"stdout"});}
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
############################## getJobFiles ##############################
sub getJobFiles{
	my $jobdir=shift();#$serverpath/.moirai2/ctrl/job
	my $number=shift();
	my $execids=shift();
	my @jobfiles=();
	if($jobdir=~/^(.+)\@(.+)\:(.+)/){
		my @files=`ssh $1\@$2 ls $3`;
		foreach my $file(@files){
			if($number<=0){last;}
			chomp($file);
			if($file=~/^\./){next;}
			my $path="$jobdir/$file";
			push(@jobfiles,$path);
			$number--;
		}
		my $serverpath=dirname(dirname(dirname($jobdir)));
		@jobfiles=downloadJobFiles($serverpath,@files);
		#@jobfiles are currently under /tmp
	}elsif(defined($execids)){
		opendir(DIR,$jobdir);
		foreach my $file(readdir(DIR)){
			if($file=~/^\./){next;}
			my $path="$jobdir/$file";
			if(-d $path){next;}
			if(defined($execids)){
				my $execid=basename($path,".txt");
				if(!exists($execids->{$execid})){next;}
			}
			push(@jobfiles,$path);
		}
		closedir(DIR);
	}else{
		opendir(DIR,$jobdir);
		foreach my $file(readdir(DIR)){
			if($number<=0){last;}
			if($file=~/^\./){next;}
			my $path="$jobdir/$file";
			if(-d $path){next;}
			if(defined($execids)){
				my $execid=basename($path,".txt");
				if(!exists($execids->{$execid})){next;}
			}
			push(@jobfiles,$path);
			$number--;
		}
		closedir(DIR);
	}
	return @jobfiles;
}
############################## getJson ##############################
sub getJson{
	my $url=shift();
	my $content=($url=~/https?:\/\//)?getHttpContent($url):readFileContent($url);
	return jsonDecode($content);
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
	my @files=getFiles($throwdir);
	return scalar(@files);
}
############################## getQueryResults ##############################
sub getQueryResults{
	my $dir=shift();
	my $query=shift();
	if(!defined($dir)){$dir=".";}
	my @queries=ref($query)eq"ARRAY"?@{$query}:split(/,/,$query);
	foreach my $line(@queries){if(ref($line)eq"ARRAY"){$line=join("->",@{$line});}}
	my $command="perl $program_directory/rdf.pl -d $dir -f json query '".join("' '",@queries)."'";
	my $result=`$command`;chomp($result);
	my $hashs=jsonDecode($result);
	my $keys=retrieveKeysFromQueries($query);
	return [$keys,$hashs];
}
############################## getTime ##############################
sub getTime{
	my $delim=shift();
	my $time=shift();
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
# line1 line2 input=input.txt output=output.txt
# return ["line1","line2"] {"input"=>"input.txt","output"=>"output.txt"}
sub handleArguments{
	my @arguments=@_;
	my $variables={};
	my @array=();
	my $index;
	for($index=scalar(@arguments)-1;$index>=0;$index--){
		my $argument=$arguments[$index];
		if($argument=~/^(.+)\;$/){$arguments[$index]=$1;last;}
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
	my $fileKeys;
	my @statements;
	if(ref($statement)eq"ARRAY"){@statements=@{$statement};}
	elsif($statement=~/^\{.+\}$/){#in json format
		my $json=jsonDecode($statement);
		foreach my $key(sort{$a cmp $b}keys(%{$json})){
			my $value=$json->{$key};
			if($key=~/^\$(\w+)$/){$key=$1;}
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
				if($key=~/^\$(\w+)$/){$key=$1;}
				if(!defined($userdefined)){$userdefined={};}
				if(!exists($userdefined->{$key})){$userdefined->{$key}=$value;}
			}
			if(!existsArray($keys,$key)){push(@{$keys},$key);}
		}
		return wantarray?($keys,$triples,undef,$suffixs):$keys;
	}else{@statements=split(",",$statement);}
	LINE: foreach my $line(@statements){
		my @tokens=split(/\-\>/,$line);
		if(scalar(@tokens)==3){
			if(defined($userdefined)){
				while(my($key,$val)=each(%{$userdefined})){$tokens[1]=~s/\$$key/$val/g;}
			}
			if($tokens[2]=~/^\$(\w+)(\.\w{2,4})/){
				if(!defined($suffixs)){$suffixs={};}
				$suffixs->{$1}=$2;
				$tokens[2]="\$$1";
			}
			foreach my $token(@tokens){
				my $variable=$token;
				if($variable=~/^\((.+)\)$/){$variable=$1;}
				if($variable=~/^\$(\w+)$/){
					$variable=$1;
					if(!existsArray($keys,$variable)){push(@{$keys},$variable);}
				}
			}
			if(!defined($triples)){$triples=[];}
			push(@{$triples},join("->",@tokens));
		}elsif(scalar(@tokens)!=1){
			print STDERR "ERROR: '$statement' has empty token or bad notation.\n";
			print STDERR "ERROR: Use single quote '\$a->b->\$c' instead of double quote \"\$a->b->\$c\".\n";
			print STDERR "ERROR: Or escape '\$' with '\\' sign \"\\\$a->b->\\\$c\".\n";
			exit(1);
		}else{
			my $variable=$tokens[0];
			if($variable=~/\*/){
				if(!defined($fileKeys)){$fileKeys=[];}
				push(@{$fileKeys},$variable);
				next LINE;
			}elsif($variable=~/^\$(\w+)(\.\w{2,4})/){
				if(!defined($suffixs)){$suffixs={};}
				$variable=$1;
				$suffixs->{$1}=$2;
			}elsif($variable=~/^\$(\w+)$/){$variable=$1;}
			if(!existsArray($keys,$variable)){push(@{$keys},$variable);}
		}
	}
	return wantarray?($keys,$triples,$fileKeys,$suffixs):$keys;
}
############################## handleKeys ##############################
sub handleKeys{
	my $line=shift();
	my @keys=split(/,/,$line);
	foreach my $key(@keys){
		if($key=~/^\$(.+)$/){$key=$1;}
		if($key=~/^(\w+)(\.\w{2,4})$/){$key=$1;}
	}
	return \@keys;
}
############################## handleRdfdbOption ##############################
sub handleRdfdbOption{
	my $command=shift();
	if(defined($opt_d)){$command->{$urls->{"daemon/rdfdb"}}=checkDatabaseDirectory($opt_d);}
	elsif(!exists($command->{$urls->{"daemon/rdfdb"}})){$command->{$urls->{"daemon/rdfdb"}}=".";}
}
############################## handleScript ##############################
sub handleScript{
	my $command=shift();
	if(!exists($command->{$urls->{"daemon/script"}})){return;}
	my $scripts=$command->{$urls->{"daemon/script"}};
	if(ref($scripts)ne"ARRAY"){$scripts=[$scripts];}
	foreach my $script(@{$scripts}){
		my $name=$script->{$urls->{"daemon/script/name"}};
		my $code=$script->{$urls->{"daemon/script/code"}};
		if(ref($code)ne"ARRAY"){$code=[$code];}
		$script->{$urls->{"daemon/script/code"}}=$code;
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
	if(system("ssh -o \"ConnectTimeout 3\" $username\@$servername hostname > /dev/null")){
		print STDERR "ERROR: Couldn't login with '$username\@$servername'.\n";
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
	foreach my $line(@lines){if($line=~/^(\w+)(\.\w{2,4})$/){$suffixs->{$1}=$2;}}
	return $suffixs;
}
############################## helpMenu ##############################
sub helpMenu{
	my $command=shift();
	if($command=~/^command$/i){helpCommand();}
	elsif($command=~/^build$/i){helpBuild();}
	elsif($command=~/^daemon$/i){helpDaemon();}
	elsif($command=~/^error$/i){helpError();}
	elsif($command=~/^exec$/i){helpExec();}
	elsif($command=~/^html$/i){helpHtml();}
	elsif($command=~/^history$/i){helpHistory();}
	elsif($command=~/^ls$/i){helpLs();}
	elsif($command=~/^openstack$/i){helpOpenstack();}
	elsif($command=~/^sortsubs$/i){helpSortSubs();}
	elsif($command=~/^test$/i){helpTest();}
	elsif($command=~/\.json$/){printCommand($command);}
	elsif($command=~/\.(ba)?sh$/){printCommand($command);}
	else{help();exit(0);}
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
	print "Options:\n";
	print "         -a  (A)ccess remote server for computation\n";
	print "         -b  Specify (b)oolean options when running a command line (example -a:\$optionA,-b:\$optionB).\n\n";
	print "         -c  Use (c)ontainer image for execution [docker|singularity].\n";
	print "         -d  RDF (d)atabase directory (default='.').\n";
	print "         -D  Delim character used to split sub->pre->obj file\n";
	print "         -E  Ignore STD(E)RR if specific regexp is found.\n";
	print "         -f  Record (f)ilestats[linecount/seqcount/md5/filesize/utime] of input/output files.\n";
	print "         -F  If specified output (f)ile is empty, record as error.\n";
	print "         -h  Show (h)elp message.\n";
	print "         -H  Show update (h)istory.\n";
	print "         -i  (I)nput query for select from database in '\$sub->\$pred->\$obj' format.\n";
	print "         -I  (I)mage of OpenStack instance.\n";
	print "         -j  Job server to get jobs from.\n";
	print "         -l  Show (l)ogs from moirai.pl.\n";
	print "         -m  (m)ax number of jobs per throw (default='1').\n";
	print "         -M  (M)ax number of threads (default='5').\n";
	print "         -o  (O)utput query for insert to database in '\$sub->\$pred->\$obj' format.\n";
	print "         -O  Ignore STD(O)UT if specific regexp is found.\n";
	print "         -p  (P)rint command lines instead of executing.\n";
	print "         -q  Use (q)sub or slurm for throwing jobs [qsub|slurm].\n";
	print "         -Q  (Q)sub/slurm options [qsub/sge/squeue/slurm].\n";
	print "         -r  Print (r)eturn value (in exec mode, stdout is default).\n";
	print "         -s  Loop (s)econd (default='10').\n";
	print "         -S  Implement/import (s)cript code to a command json file.\n";
	print "         -t  Check timestamp of inputs and outputs and execute command if needed.\n";
	print "         -T  Run in single (T)hread mode meaning only one process can run per computer.\n";
	print "         -v  (v)olume to rsync.\n";
	print "         -V  Fla(v)or of Openstack instance to create.\n";
	print "         -u  Run in (U)ser mode where input parameters are prompted.\n";
	print "         -U  (U)pdate by forcing a command process.\n";
	print "         -w  Don't (w)ait.\n";
	print "         -x  Dont execute.\n";
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
sub helpDaemon{
	print "\n";
	print "Program: Construct and process jobs with moirai2 command scripts.\n";
	print "\n";
	print "Usage: perl $program_name MODE\n";
	print "\n";
	print "MODE:\n";
	print "       cron  Submit jobs constructed from command files under ./cron/\n";
	print "     submit  Submit jobs constructed from submit files under .moirai2/ctrl/submit/\n";
	print "    process  Process jobs under .moirai2/ctrl/job/\n";
	print "\n";
	print "Options:\n";
	print "         -a  (A)ccess remote server and process jobs there instead of using local.\n";
	print "         -b  (B)uild daemon on specified server instead of local.\n";
	print "         -d  RDF (d)atabase directory (default='.').\n";
	print "         -h  Show (h)elp message.\n";
	print "         -H  Show update (h)istory.\n";
	print "         -j  Retrieve jobs from a (j)ob server instead of retrieving from a local.\n";
	print "         -l  Show (l)ogs from moirai.pl.\n";
	print "         -M  (M)ax number of threads (default='5').\n";
	print "         -r  Number of time to (r)epeat loop (default=-1='infinite').\n";
	print "         -s  Loop (s)econd (default='10').\n";
	print "\n";
	print "Note:\n";
	print " perl $program_name cron submit (server)\n";
	print " perl $program_name -j USER\@SERVER:DIR process (remote)\n";
	print " 'cron' and 'submit' only throw jobs and does not 'process' jobs.\n";
	print " Functionality is separated to enable remote computation.\n";
	print " For example, use command above to set up a server which only create jobs,\n";
	print " and use command below on node to process jobs created by the server.\n";
	print "\n";
	print " perl $program_name cron submit process\n";
	print " This will 'process' jobs along with 'cron' and 'submit',\n";
	print "\n";
	print " perl $program_name -a USER\@SERVER:DIR  process\n";
	print " This will process jobs using remote server specified with '-a'\n";
	print " Make sure you have SSH access to the remote server.\n";
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
	print "Options:\n";
	print "         -a  (A)ccess remote server for computation.\n";
	print "         -c  Use (c)ontainer image for execution [docker|singularity].\n";
	print "         -d  RDF (d)atabase directory (default='.').\n";
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
sub helpHistory{
	print "\n";
	print "Program: Similar to unix's history.\n";
	print "\n";
	print "Usage: perl $program_name test\n";
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
	print "Options:\n";
	print "         -d  RDF (d)atabase directory (default='.').\n";
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
	print "Options:\n";
	print "         -d  RDF (d)atabase directory (default='.').\n";
	print "         -D  Delim character (None alphabe/number characters+'_')\n";
	print "         -g  grep specific string\n";
	print "         -G  ungrep specific string\n";
	print "         -i  Input query for select in '\$sub->\$pred->\$obj' format.\n";
	print "         -o  Output query for insert in '\$sub->\$pred->\$obj' format.\n";
	print "         -r  Recursive search (default=0)\n";
	print "         -x  Don't e(x)ecute data insert specified with '-o', instead show output results.\n";
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
sub helpRsync{
	print "\n";
	print "Program: Rsync directories.\n";
	print "\n";
	print "Usage: perl $program_name rsync DIR\n";
	print "\n";
	print "Options:\n";
	print "         -a  Copy directories to a remove server.\n";
	print "         -j  Copy directories from a job server.\n";
	print "\n";
}
sub helpOpenstack{
	print "\n";
	print "Program: Openstack.\n";
	print "\n";
	print "Usage: perl $program_name openstack\n";
	print "\n";
}
sub helpSortsubs{
	print "\n";
	print "Program: Sort subs.\n";
	print "\n";
	print "Usage: perl $program_name sortsubs\n";
	print "\n";
}
sub helpTest{
	print "\n";
	print "Program: Runs moirai2 test commands for refactoring process.\n";
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
			if(defined($file)){system("cat $file");}
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
				my @lines=@{$history->{$execid}->{"commandline"}};
				for(my $i=0;$i<scalar(@lines);$i++){
					if($i==0){
						push(@tokens,$lines[$i]);
						print join(" ",@tokens)."\n";
					}else{
						print join(" ",("                   "," ",$lines[$i]))."\n";
					}
				}
			}
		}
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
	my $moiraidir=$moiraidir;#.moirai2
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
	if(exists($command->{$urls->{"daemon/script"}})){$vars->{"base"}->{"exportpath"}="$rootdir/$workdir/bin:".$vars->{"base"}->{"exportpath"};}
	my @array=();
	if(exists($command->{$urls->{"daemon/remotepath"}})){
		my $remotepath=$command->{$urls->{"daemon/remotepath"}};
		push(@array,$urls->{"daemon/localdir"}."\t$workdir");
		my ($username,$servername,$remotedir)=splitServerPath($remotepath);
		$rootdir=$remotedir;#/home/ah3q
		$moiraidir="$remotedir/.moirai2remote";#/home/ah3q/.moirai2remote
		if(system("ssh $username\@$servername mkdir -p $moiraidir")){
			print STDERR "ERROR: Couldn't create '$username\@$servername:$moiraidir' directory.\n";
			exit(1);
		}
		$workdir="$moiraidir/$execid";#/home/ah3q/.moirai2remote/eYYYYMMDDHHMMSS
		$exportpath="$workdir/bin:$remotedir/bin:$remotedir/.moirai2remote/bin:\$PATH";
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
		if(exists($command->{$urls->{"daemon/script"}})){$vars->{"server"}->{"exportpath"}="$remotedir/$workdir/bin:".$vars->{"server"}->{"exportpath"};}
		push(@array,$urls->{"daemon/workdir"}."\t$username\@$servername:$workdir");
	}else{
		push(@array,$urls->{"daemon/workdir"}."\t$workdir");
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
			if(exists($command->{$urls->{"daemon/script"}})){$vars->{"singularity"}->{"exportpath"}="$rootdir/$workdir/bin:".$vars->{"singularity"}->{"exportpath"};}
		}else{
			$rootdir="/root";
			my $moiraidir=exists($vars->{"server"})?"$rootdir/.moirai2remote":"$rootdir/.moirai2";
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
			if(exists($command->{$urls->{"daemon/script"}})){$vars->{"docker"}->{"exportpath"}="$workdir/bin:".$vars->{"docker"}->{"exportpath"};}
		}
	}
	my $datetime=`date +%s`;chomp($datetime);
	push(@array,$urls->{"daemon/execute"}."\tregistered");
	push(@array,$urls->{"daemon/timeregistered"}."\t$datetime");
	push(@array,$urls->{"daemon/rootdir"}."\t$rootdir");
	writeJobArray($execid,@array);
}
############################## jobOfferEnd ##############################
sub jobOfferEnd{
	my $jobdir=shift();
	my $lockfile="$jobdir.lock";
	removeFile($lockfile);
}
############################## jobOfferStart ##############################
#This make sure that only one program is looking at jobdir
#jobdir can be set across internet (example,jobdir=ah3q@dgt-ac4:moirai2/.moirai2/ctrl/jobdir)
#make sure that the hostname is correct
sub jobOfferStart{
	my $jobdir=shift();
	my $lockfile="$jobdir.lock";
	my $jobCoolingTime=10;
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
	chomp($content);
	if($content eq $hostname){return 0;}
	else{return 1;}
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
	my $object=shift();
	if(ref($object)eq"ARRAY"){return jsonEncodeArray($object);}
	elsif(ref($object)eq"HASH"){return jsonEncodeHash($object);}
	else{return "\"".jsonEscape($object)."\"";}
}
sub jsonEncodeArray{
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
sub jsonEncodeHash{
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
sub jsonEscape{
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
	return wantarray?sort{$a cmp $b}@inputfiles:$inputfiles[0];
}
############################## loadAllUnfinishedJobs ##############################
sub loadAllUnfinishedJobs{
	my $commands=shift();
	my $processes={};
	$processes->{"registered"}={};
	$processes->{"ongoing"}={};
	$processes->{"error"}={};
	loadOnGoingVars($commands,$jobdir,$processes->{"registered"});
	loadOnGoingVars($commands,$processdir,$processes->{"ongoing"});
	loadErrorVars($commands,$processes->{"error"});
	return $processes;
}
############################## loadCommandFromOptions ##############################
sub loadCommandFromOptions{
	my $command=shift();
	if(defined($opt_b)){$command->{$urls->{"daemon/command/option"}}=setCommandOptions($opt_b);}
	if(defined($opt_c)){$command->{$urls->{"daemon/container"}}=$opt_c;}
	if(defined($opt_V)){$command->{$urls->{"daemon/container/flavor"}}=$opt_V;}
	if(defined($opt_I)){$command->{$urls->{"daemon/container/image"}}=$opt_I;}
	if(defined($opt_F)){$command->{$urls->{"daemon/error/file/empty"}}=handleKeys($opt_F);}
	if(defined($opt_E)){$command->{$urls->{"daemon/error/stderr/ignore"}}=handleKeys($opt_E);}
	if(defined($opt_O)){$command->{$urls->{"daemon/error/stdout/ignore"}}=handleKeys($opt_O);}
	if(defined($opt_f)){$command->{$urls->{"daemon/file/stats"}}=handleKeys($opt_f);}
	if(defined($opt_m)){$command->{$urls->{"daemon/maxjob"}}=$opt_m;}
	if(defined($opt_q)){$command->{$urls->{"daemon/qjob"}}=$opt_q;}
	if(defined($opt_Q)){$command->{$urls->{"daemon/qjob/opt"}}=$opt_Q;}
	if(defined($opt_d)){$command->{$urls->{"daemon/rdfdb"}}=$opt_d;}
	if(defined($opt_a)){$command->{$urls->{"daemon/remotepath"}}=handleServer($opt_a);}
	if(defined($opt_r)){$command->{$urls->{"daemon/return"}}=handleKeys($opt_r);}
	if(defined($opt_S)){$command->{$urls->{"daemon/script"}}=$opt_S;loadScripts($command);}
	if(defined($opt_s)){$command->{$urls->{"daemon/sleeptime"}}=$opt_s;}
	if(defined($opt_T)){$command->{$urls->{"daemon/singlethread"}}="true";}
	my $userdefined={};
	my $suffixs={};
	my $inputKeys={};
	if(defined($opt_i)){
		my ($keys,$query,$files)=handleInputOutput($opt_i,$userdefined,$suffixs);
		foreach my $key(@{$keys}){$inputKeys->{$key}=1;}
		my @array=sort{$a cmp $b}keys(%{$inputKeys});
		if(scalar(@array)>0){$command->{$urls->{"daemon/input"}}=\@array;}
		if(defined($query)){$command->{$urls->{"daemon/query/in"}}=$query;}
		if(defined($files)){$command->{$urls->{"daemon/ls"}}=$files;}
	}
	my $outputKeys={};
	if(defined($opt_o)){
		my ($keys,$query)=handleInputOutput($opt_o,$userdefined,$suffixs);
		foreach my $key(@{$keys}){if(!exists($inputKeys->{$key})){$outputKeys->{$key}=1;}}
		my @array=sort{$a cmp $b}keys(%{$outputKeys});
		if(scalar(@array)>0){$command->{$urls->{"daemon/output"}}=\@array;}
		if(defined($query)){$command->{$urls->{"daemon/query/out"}}=$query;}
	}
	if(exists($command->{$urls->{"daemon/return"}})){
		my $hash={};
		foreach my $output(@{$command->{$urls->{"daemon/output"}}}){$hash->{$output}=1;}
		foreach my $output(@{$command->{$urls->{"daemon/return"}}}){$hash->{$output}=1;}
		my @array=sort{$a cmp $b}keys(%{$hash});
		$command->{$urls->{"daemon/output"}}=\@array;
	}
	handleRdfdbOption($command);
	if(defined($opt_X)){handleInputOutput($opt_X,$userdefined,$suffixs);}
	if(scalar(keys(%{$suffixs}))>0){$command->{$urls->{"daemon/suffix"}}=$suffixs;}
	if(scalar(keys(%{$userdefined}))>0){$command->{$urls->{"daemon/userdefined"}}=$userdefined;}
}
############################## loadCommandFromURL ##############################
sub loadCommandFromURL{
	my $url=shift();
	my $commands=shift();
	if(defined($commands)&&exists($commands->{$url})){return $commands->{$url};}
	if(defined($opt_l)){print "#Loading: $url\n";}
	my $command=($url=~/\.json$/)?getJson($url):getBash($url);
	if(scalar(keys(%{$command}))==0){print "ERROR: Couldn't load $url\n";exit(1);}
	$command->{$urls->{"daemon/command"}}=$url;
	my $default=$command->{$urls->{"daemon/default"}};
	if(!defined($default)){$default={};}
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/input"},$default);
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/output"},$default);
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/inputs"});
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/outputs"});
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/return"});
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/unzip"});
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/file/stats"});
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/file/md5"});
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/file/filesize"});
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/file/linecount"});
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/file/seqcount"});
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/error/file/empty"});
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/error/stderr/ignore"});
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/error/stdout/ignore"});
	loadCommandFromURLToArray($command,$urls->{"daemon/bash"});
	loadCommandFromURLToArray($command,$urls->{"daemon/query/in"});
	loadCommandFromURLToArray($command,$urls->{"daemon/query/out"});
	handleScript($command);
	if(scalar(keys(%{$default}))>0){$command->{$urls->{"daemon/default"}}=$default;}
	if(defined($commands)){$commands->{$url}=$command;}
	return $command;
}
sub loadCommandFromURLToArray{
	my $command=shift();
	my $url=shift();
	if(!exists($command->{$url})){return;}
	if(ref($command->{$url})ne"ARRAY"){$command->{$url}=[$command->{$url}];}
}
sub loadCommandFromURLRemoveDollar{
	my $command=shift();
	my $url=shift();
	my $default=shift();
	if(!exists($command->{$url})){return;}
	$command->{$url}=removeDollar(convertToArray($command->{$url},$default));
}
############################## loadErrorVars ##############################
sub loadErrorVars{
	my $commands=shift();
	my $processes=shift();
	my @files=getFiles($errordir,$opt_w);
	if(!defined($processes)){$processes={};}
	foreach my $file(@files){
		my $reader=openFile($file);
		my $url;
		while(<$reader>){
			chomp;
			my ($key,$val)=split(/\t/);
			if($key eq $urls->{"daemon/command"}){
				$url=$val;
				if(defined($commands)){loadCommandFromURL($url,$commands);}
				last;
			}
		}
		close($reader);
		if(!exists($processes->{$url})){$processes->{$url}=[];}
		my $hash;
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			my ($key,$val)=split(/\t/);
			if(/^\#{40} (.+) \#{40}$/){
				if(!defined($hash)){$hash={};}
				else{last;}
			}elsif($key=~/^$url#(.+)$/){$hash->{$1}=$val;}
		}
		close($reader);
		push(@{$processes->{$url}},$hash);
	}
	return $processes;
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
			if(!exists($hash->{$key})){$hash->{$key}=$val;}
			elsif(ref($hash->{$key})eq"ARRAY"){push(@{$hash->{$key}},$val);}
			else{$hash->{$key}=[$hash->{$key},$val];}
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
		$executes->{$url}->{$id}->{"jobfile"}=$file;
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
############################## loadOnGoingVars ##############################
sub loadOnGoingVars{
	my $commands=shift();
	my $directory=shift();
	my $processes=shift();
	if(!defined($processes)){$processes={};}
	foreach my $file(listFilesRecursively("\.txt\$",undef,-1,$directory)){
		my $process=loadProcessFile($file);
		my $url=$process->{$urls->{"daemon/command"}};
		if(!exists($processes->{$url})){$processes->{$url}=[];}
		my $hash={};
		while(my($key,$val)=each(%{$process})){if($key=~/^$url#(.+)$/){$hash->{$1}=$val;}}
		push(@{$processes->{$url}},$hash);
	}
	return $processes;
}
############################## loadProcessFile ##############################
sub loadProcessFile{
	my $logfile=shift();
	my $process={};
	my $reader=openFile($logfile);
	while(<$reader>){
		chomp;my ($key,$val)=split(/\t/);
		if(ref($process->{$key})eq"ARRAY"){push(@{$process->{$key}},$val);}
		elsif(exists($process->{$key})){$process->{$key}=[$process->{$key},$val];}
		else{$process->{$key}=$val;}
	}
	close($reader);
	return $process;
}
############################## loadScripts ##############################
sub loadScripts{
	my $command=shift();
	if(!exists($command->{$urls->{"daemon/script"}})){return;}
	my $files=$command->{$urls->{"daemon/script"}};
	if(ref($files)ne"ARRAY"){
		my @array=split(/,/,$files);
		$files=\@array;
	}
	my @array=();
	foreach my $file(@{$files}){
		if(!-e $file){print STDERR "#ERROR: '$file' script doesn't exist.\n";}
		my $hash={};
		my $reader=openFile($file);
		my @codes=();
		while(<$reader>){chomp;push(@codes,$_);}
		close($reader);
		$hash->{$urls->{"daemon/script/code"}}=\@codes;
		$hash->{$urls->{"daemon/script/name"}}=basename($file);
		push(@array,$hash);
	}
	@array=sort{$a->{$urls->{"daemon/script/name"}} cmp $b->{$urls->{"daemon/script/name"}}}@array;
	$command->{$urls->{"daemon/script"}}=\@array;
}
############################## loadSubmit ##############################
sub loadSubmit{
	my $path=shift();
	my $commands=shift();
	if(!-e $path){
		print STDERR "ERROR: Submit file '$path' doesn't exist.\n";
		exit(1);
	}
	my $reader=openFile($path);
	my $hash={};
	my $url;
	my $rdfdb;
	while(<$reader>){
		chomp;
		my ($key,$val)=split(/\t/);
		if($key eq "url"){$url=$val;}
		elsif($key eq "rdfdb"){$rdfdb=$val;}
		else{$hash->{$key}=$val;}
	}
	close($reader);
	if(!defined($url)){
		print STDERR "ERROR: Command URL is not specified in '$path'\n";
		exit(1);
	}
	my $command=loadCommandFromURL($url,$commands);
	if(defined($rdfdb)){$command->{$urls->{"daemon/rdfdb"}}=$rdfdb;}
	my $inputKeys=$command->{$urls->{"daemon/input"}};
	my $userdefined=$command->{$urls->{"daemon/userdefined"}};
	my $inputHash={};
	foreach my $input(@{$inputKeys}){
		if(exists($hash->{$input})){$inputHash->{$input}=$hash->{$input};}
		elsif(exists($userdefined->{$input})){$inputHash->{$input}=$userdefined->{$input};}
	}
	unlink($path);
	my $queryResults=[];
	$queryResults->[0]=$inputKeys;
	$queryResults->[1]=[$inputHash];
	return ($command,$queryResults);
}
############################## logCommand ##############################
sub logCommand{
	my $history=getHistory();
	my $array=[];
	foreach my $execid(sort {$a cmp $b}keys(%{$history})){
		my $hash=$history->{$execid};
		$hash->{"execid"}=$execid;
		push(@{$array},$hash);
	}
	if($opt_o eq "json"){
		print jsonEncode($array)."\n";
	}else{
		my @keys=("execid","execute","timestarted","timeended","processtime","commandline","stdout","stderr");
		print join("\t",@keys)."\n";
		foreach my $hash(@{$array}){
			my $line;
			my $index=0;
			foreach my $key(@keys){
				my $val=$hash->{$key};
				if($index>0){$line.="\t";}
				if(ref($val)eq"ARRAY"){$line.=join(";",@{$val});}
				else{$line.=$val;}
				$index++;
			}
			print "$line\n";
		}
	}
}
############################## ls ##############################
sub ls{
	my ($arguments,$userdefined)=handleArguments(@ARGV);
	my @directories=@{$arguments};
	my $suffixs;
	my $queryResults;
	my $rdfdb=defined($dbdir)?$dbdir:".";
	if(defined($opt_i)){
		my ($keys,$queryIn)=handleInputOutput($opt_i,$userdefined,$suffixs);
		$queryResults=getQueryResults($rdfdb,$queryIn);
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
	my $template=defined($opt_o)?$opt_o:"\$filepath";
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
	if(!defined($opt_x)&&checkInputOutput($opt_o)){
		my ($writer,$temp)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
		foreach my $line(@lines){print $writer "$line\n";}
		close($writer);
		if(defined($opt_l)){system("perl $program_directory/rdf.pl -d $rdfdb import < $temp");}
		else{system("perl $program_directory/rdf.pl -q -d $rdfdb import < $temp");}
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
	my $jobslot=shift();
	my $thrown=0;
	my $url;
	my @handled=();#handled URls
	for(my $i=0;($i<$jobslot)&&(scalar(@{$execurls})>0);$i++){
		$url=shift(@{$execurls});#get first URL
		my $command=$commands->{$url};
		if(exists($command->{$urls->{"daemon/singlethread"}})&&$command->{$urls->{"daemon/singlethread"}} eq "true"){
			my $singleThreadOnGoing=0;#single-thread job still on going?
			foreach my $execid(keys(%{$processes})){
				my $process=$processes->{$execid};
				if($process->{$urls->{"daemon/execute"}}eq"completed"){next;}#completed
				if($url eq $process->{$urls->{"daemon/command"}}){$singleThreadOnGoing=1;last;}
			}
			if($singleThreadOnGoing){push(@handled,$url);next;}
		}
		my $maxjob=$command->{$urls->{"daemon/maxjob"}};#number of max jobs per throw
		if(!defined($maxjob)){$maxjob=1;}#default is one job per throw
		my @variables=();
		if(exists($command->{$urls->{"daemon/bash"}})&&exists($executes->{$url})){
			my $count=0;
			foreach my $execid(sort{$a cmp $b}keys(%{$executes->{$url}})){
				if($count>=$maxjob){last;}
				my $vars=$executes->{$url}->{$execid};
				initExecute($command,$vars);
				bashCommand($command,$vars);
				push(@variables,$vars);
				delete($executes->{$url}->{$execid});
				$count++;
				$thrown++;
			}
			if(scalar(keys(%{$executes->{$url}}))>0){unshift(@{$execurls},$url);}# Still remains jobs
			else{delete($executes->{$url});}
		}
		throwJobs($url,$command,$processes,@variables);
	}
	push(@{$execurls},@handled);#put to the last
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
############################## moiraiMain ##############################
sub moiraiMain{
	my $mode=shift();
	my $submitvar;
	my ($arguments,$userdefined)=handleArguments(@ARGV);
	my @cmdlines=();
	my $commands={};
	my $command;
	my $queryResults;
	if($mode=~/^submit$/i){
		if(scalar(@{$arguments})==0){print STDERR "Submit file doesn't exist\n";exit(1);}
		($command,$queryResults)=loadSubmit($arguments->[0],$commands);
	}elsif($mode=~/\.json$/){
		$command=loadCommandFromURL($mode,$commands);
	}elsif($mode=~/\.(ba)?sh$/){
		$command=loadCommandFromURL($mode,$commands);
	}elsif($mode=~/^build$/i){
		my @cmdlines=();
		while(<STDIN>){chomp;push(@cmdlines,$_);}
		$command=createNewCommandFromLines(@cmdlines);
	}elsif($mode=~/^command$/i){
		my @cmdlines=();
		while(<STDIN>){chomp;push(@cmdlines,$_);}
		$command=createNewCommandFromLines(@cmdlines);
	}elsif($mode=~/^exec$/i){
		if(scalar(@{$arguments})==0){print STDERR "ERROR: Please specify command line\n";exit(1);}
		my $cmdline=join(" ",@{$arguments});
		push(@cmdlines,$cmdline);
		$command=createNewCommandFromLines(@cmdlines);
		$arguments=[];
		if(!defined($opt_r)){$opt_r="\$stdout";}#Print out stdout for exec
		$opt_s=1;#To get the result as soon as command is completed.
	}else{
		print STDERR "ERROR: '$mode' not recognized\n";
		help();
		exit(1);
	}
	loadCommandFromOptions($command);
	assignUserdefinedToCommand($command,$userdefined);
	if($mode=~/^exec$/i){setInputsOutputsFromCommand($command);}
	my $cmdurl=saveCommand($command);
	if($mode=~/^build$/i){print "$cmdurl\n";exit(0);}
	$command=loadCommandFromURL($cmdurl,$commands);
	if(defined($opt_v)){rsyncProcess(convertToArray($opt_v));}
	controlWorkflow();#handle insert/update/delete
	if(!defined($queryResults)){$queryResults=moiraiProcessQuery($command);}
	my @execids=moiraiPrepare($command,$queryResults,@{$arguments});
	#-j server -x = upload inputs, and quit
	#-j server = upload inputs server, process at server, wait, and download results
	#-j server -a remote = upload inputs to server, upload inputs to remote, process at remote, wait, download results from remote, download results from server
	#-a remote 
	if(defined($opt_j)){
		my $serverpath=handleServer($opt_j);
		my $processes=copyToJobServer($serverpath,$commands,@execids);
		if(defined($opt_x)){print join(" ",@execids)."\n";exit(0);}
	}else{
		if(defined($opt_x)){print join(" ",@execids)."\n";exit(0);}
		my $processes=moiraiRunExecute($commands,$opt_p,@execids);
		moiraiFinally($commands,$processes,@execids);
	}
}
############################## moiraiPrepare ##############################
sub moiraiPrepare{
	my @arguments=@_;
	my $command=shift(@arguments);
	my $queryResults=shift(@arguments);
	my $userdefined=$command->{$urls->{"daemon/userdefined"}};
	my $queryKeys=$command->{$urls->{"daemon/query/in"}};
	my $insertKeys=$command->{$urls->{"daemon/query/out"}};
	my $url=$command->{$urls->{"daemon/command"}};
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	if(scalar(@{$queryResults->[1]})==0){
		if(defined($opt_l)){print STDERR "WARNING: No corresponding data found.\n";}
		if(defined($opt_Z)){touchFile($opt_Z);}
		exit(0);
	}
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
	my @jobs=();
	foreach my $hash(@{$queryResults->[1]}){
		my $execid=assignExecid($opt_w);
		my $vars=moiraiPrepareVars($hash,$userdefined,$insertKeys,\@inputs,\@outputs);
		my $job={};
		$job->{$urls->{"daemon/execid"}}=$execid;
		$job->{$urls->{"daemon/command"}}=$url;
		foreach my $key(keys(%{$vars})){$job->{"$url#$key"}=$vars->{$key};}
		push(@jobs,$job);
	}
	@jobs=moiraiPrepareCheck(@jobs);
	if(defined($opt_u)&&scalar(@jobs)>0){
		print "Proceed running ".scalar(@jobs)." jobs [y/n]? ";
		if(!getYesOrNo()){exit(1);}
	}
	my $rdfdb=$command->{$urls->{"daemon/rdfdb"}};
	moiraiPrepareRemoveFlag($rdfdb,$queryKeys,$queryResults);
	my @execids=writeJobHash(@jobs);
	return @execids;
}
############################## moiraiPrepareCheck ##############################
sub moiraiPrepareCheck{
	my @jobs=@_;
	my $processes=loadAllUnfinishedJobs();
	my @array=();
	foreach my $job(@jobs){
		my $execid=$job->{$urls->{"daemon/execid"}};
		my $url=$job->{$urls->{"daemon/command"}};
		my $hash={};
		while(my($key,$val)=each(%{$job})){if($key=~/^$url#(.+)$/){$hash->{$1}=$val;}}
		if(moiraiPrepareMatch($hash,$processes->{"registered"}->{$url})){
			print STDERR "#WARNING  '$execid' will not be processed, since same job is currently registered\n";
		}elsif(moiraiPrepareMatch($hash,$processes->{"ongoing"}->{$url})){
			print STDERR "#WARNING  '$execid' will not be processed, since same job is currently on going\n";
		}elsif(moiraiPrepareMatch($hash,$processes->{"error"}->{$url})){
			print STDERR "#WARNING  '$execid' will not be processed, since earlier job ended with error\n";
			print STDERR "#WARNING  Use 'perl moirai2.pl error' to check error messages\n";
		}else{push(@array,$job);next;}
		unlink("$jobdir/$execid.txt");
	}
	return @array;
}
############################## moiraiPrepareMatch ##############################
sub moiraiPrepareMatch{
	my $hash=shift();
	my $vars=shift();
	if(!defined($vars)){return;}
	my $hit;
	foreach my $var(@{$vars}){
		my $match=1;
		while(my($key,$val)=each(%{$hash})){
			if(!exists($var->{$key})){$match=0;last;}
			elsif($val ne $var->{$key}){$match=0;last;}
		}
		if($match==0){next;}
		$hit=1;
		last;
	}
	return $hit;
}
############################## moiraiPrepareRemoveFlag ##############################
sub moiraiPrepareRemoveFlag{
	my $rdfdb=shift();
	my $queryKeys=shift();
	my $queryResults=shift();
	my @queries=();
	foreach my $query(@{$queryKeys}){
		my @tokens=split(/\-\>/,$query);
		if($tokens[1]!~/flag\/(\w+)$/){next;}
		push(@queries,$tokens[0]."\t$rdfdb/".$tokens[1]."\t".$tokens[2]);
	}
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>0);
	foreach my $query(@queries){
		foreach my $result(@{$queryResults->[1]}){		
			my $line=$query;
			foreach my $key(sort{$b cmp $a}keys(%{$result})){
				my $val=$result->{$key};
				$line=~s/\$$key/$val/g;
			}
			print $writer "$line\n";
		}
	}
	close($writer);
	system("mv $file $deletedir/".basename($file));
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
############################## moiraiProcessQuery ##############################
sub moiraiProcessQuery{
	my $command=shift();
	my $queryResults;
	my $rdfdb=$command->{$urls->{"daemon/rdfdb"}};
	if(exists($command->{$urls->{"daemon/query/in"}})){
		$queryResults=getQueryResults($rdfdb,$command->{$urls->{"daemon/query/in"}});
	}elsif(exists($command->{$urls->{"daemon/ls"}})){
		my @keys=();
		my $query=$command->{$urls->{"daemon/ls"}};
		my @files=`ls $query`;
		my @array=();
		foreach my $file(@files){
			chomp($file);
			my $h=basenames($file,$opt_D);
			$h=fileStats($file,$opt_o,$h);
			push(@array,$h);
			foreach my $key(keys(%{$h})){if(!existsArray(\@keys,$key)){push(@keys,$key);}}
		}
		$queryResults=[\@keys,\@array];
	}
	if(!defined($queryResults)){$queryResults=[[],[{}]];}
	if(!defined($opt_U)){removeUnnecessaryExecutes($queryResults,$command);}
	if(defined($opt_t)){removeUnnecessaryOutputs($queryResults,$command);}
	if(defined($opt_l)){printRows($queryResults->[0],$queryResults->[1]);}
	return $queryResults;
}
############################## moiraiRunExecute ##############################
sub moiraiRunExecute{
	my @execids=@_;
	my $commands=shift(@execids);
	my $printMode=shift(@execids);
	my $executes={};
	my $processes={};
	my $execurls=[];
	my $ids;
	if(scalar(@execids)>0){$ids={};foreach my $execid(@execids){$ids->{$execid}=1;}}
	while(true){
		controlWorkflow($processes,$commands);
		if(scalar(@{$execurls})==0&&scalar(keys(%{$executes}))==0&&scalar(keys(%{$processes}))>0){
			my $completed=1;#check all processes are completed
			foreach my $execid(keys(%{$processes})){
				my $process=$processes->{$execid};
				if($process->{$urls->{"daemon/execute"}}eq"completed"){next;}#completed
				$completed=0;
			}
			if($completed){last;}# completed all jobs
		}
		my $jobs_running=getNumberOfJobsRunning();
		if($jobs_running>=$maxThread){sleep($opt_s);next;}# no slot to throw job
		my $job_remaining=getNumberOfJobsRemaining(@execids);
		if($job_remaining==0){sleep($opt_s);next;}# no more job to handle
		my $jobSlot=$maxThread-$jobs_running;
		while(jobOfferStart($jobdir)){if(defined($opt_l)){"#Waiting for job slot\n"}}
		my @jobfiles=getJobFiles($jobdir,$jobSlot,$ids);
		jobOfferEnd($jobdir);
		loadExecutes($commands,$executes,$execurls,@jobfiles);
		if(defined($printMode)){printJobs($execurls,$commands,$executes);exit(0);}
		mainProcess($execurls,$commands,$executes,$processes,$jobSlot);
	}
	controlWorkflow($processes,$commands);
	return $processes;
}
############################## mvProcessFromTmpToJobdir ##############################
sub mvProcessFromTmpToJobdir{
	my $tmpfile=shift();
	my $process=shift();
	my $execid=$process->{$urls->{"daemon/execid"}};
	my $jobfile="$jobdir/$execid.txt";
	if(defined($opt_l)){print "#Moving $tmpfile to $jobfile\n"}
	system("mv $tmpfile $jobfile");
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
############################## openstackCommand ##############################
sub openstackCommand{
	my @arguments=@_;
	if(!-e "$program_directory/openstack.pl"){print STDERR "ERROR: $program_directory/openstack.pl not found\n";exit(1);}
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
	if(scalar(@inputs)>0){print STDOUT "#Input   :".join(", ",@{$command->{$urls->{"daemon/input"}}})."\n";}
	if(scalar(@outputs)>0){print STDOUT "#Output  :".join(", ",@{$command->{$urls->{"daemon/output"}}})."\n";}
	print STDOUT "#Bash    :";
	if(ref($command->{$urls->{"daemon/bash"}})ne"ARRAY"){print STDOUT $command->{$urls->{"daemon/bash"}}."\n";}
	else{my $index=0;foreach my $line(@{$command->{$urls->{"daemon/bash"}}}){if($index++>0){print STDOUT "         :"}print STDOUT "$line\n";}}
	if(exists($command->{$urls->{"daemon/description"}})){print STDOUT "#Summary :".join(", ",@{$command->{$urls->{"daemon/description"}}})."\n";}
	if($command->{$urls->{"daemon/maxjob"}}>1){print STDOUT "#Maxjob  :".$command->{$urls->{"daemon/maxjob"}}."\n";}
	if(exists($command->{$urls->{"daemon/singlethread"}})){print STDOUT "#SingleThread  :".($command->{$urls->{"daemon/singlethread"}}?"true":"false")."\n";}
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
############################## printJobs ##############################
sub printJobs{
	my $execurls=shift();
	my $commands=shift();
	my $executes=shift();
	for(my $i=0;$i<scalar(@{$execurls});$i++){
		my $url=$execurls->[$i];
		my $command=$commands->{$url};
		if(!exists($command->{$urls->{"daemon/bash"}})){next;}
		foreach my $execid(sort{$a cmp $b}keys(%{$executes->{$url}})){
			print "============================== $execid ==============================\n";
			my $vars=$executes->{$url}->{$execid};
			initExecute($command,$vars);
			bashCommand($command,$vars);
			my $bashsrc=$vars->{"base"}->{"bashfile"};
			my $jobfile="$jobdir/$execid.txt";
			open(IN,$bashsrc);
			while(<IN>){print;}
			close(IN);
			unlink($bashsrc);
			unlink($jobfile);
			rmdir("$moiraidir/$execid");
			delete($executes->{$url}->{$execid});
		}
	}
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
		if(ref($_)eq"ARRAY"){
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
	if(exists($command->{$urls->{"daemon/default"}})&&exists($command->{$urls->{"daemon/default"}}->{$label})){
		$default=$command->{$urls->{"daemon/default"}}->{$label};
		print STDOUT " [$default]";
	}
	print STDOUT "? ";
	my $value=<STDIN>;
	chomp($value);
	if($value=~/^(.+) +$/){$value=$1;}
	if($value eq ""){if(defined($default)){$value=$default;}else{exit(1);}}
	$variables->{$label}=$value;
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
############################## readText ##############################
sub readText{
	my $file=shift();
	my $text="";
	open(IN,$file);
	while(<IN>){s/\r//g;$text.=$_;}
	close(IN);
	return $text;
}
############################## reloadProcesses ##############################
sub reloadProcesses{
	my $commands=shift();
	my $processes=shift();
	if(!defined($processes)){$processes={};}
	my @files=getFiles($processdir,$opt_w);
	foreach my $file(@files){
		my $execid=basename($file,".txt");
		$processes->{$execid}=loadProcessFile($file);
	}
	foreach my $execid(keys(%{$processes})){
		my $process=$processes->{$execid};
		if(!exists($process->{$urls->{"daemon/command"}})){next;}
		loadCommandFromURL($process->{$urls->{"daemon/command"}},$commands);
	}
	return $processes;
}
############################## reloadServerProcesses ##############################
sub reloadServerProcesses{
	my $commands=shift();
	my $processes=shift();
	if(!defined($processes)){$processes={};}
	foreach my $dir(getDirs($processdir)){
		my $hostname=basename($dir);
		foreach my $file(getFiles($dir,$opt_w)){
			my $execid=basename($file,".txt");
			$processes->{$execid}=loadProcessFile($file);
		}
	}
	foreach my $execid(keys(%{$processes})){
		my $process=$processes->{$execid};
		if(!exists($process->{$urls->{"daemon/command"}})){next;}
		loadCommandFromURL($process->{$urls->{"daemon/command"}},$commands);
	}
	return $processes;
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
	if(ref($value)eq"ARRAY"){foreach my $v(@{$value}){if($v=~/^\$(.+)$/){$v=$1;}}}
	elsif($value=~/^\$(.+)$/){$value=$1;}
	return $value;
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
	if(!exists($command->{$urls->{"daemon/remotepath"}})){return;}
	my $url=$process->{$urls->{"daemon/command"}};
	my $remotepath=$command->{$urls->{"daemon/remotepath"}};
	my ($username,$servername,$remotedir)=splitServerPath($remotepath);
	foreach my $input(@{$command->{$urls->{"daemon/input"}}}){
		if(!exists($process->{"$url#$input"})){next;}
		my $inputFile="$remotepath/".$process->{"$url#$input"};
		if(defined($opt_l)){print "#Removing $inputFile\n";}
		removeFile($inputFile);
	}
	foreach my $output(@{$command->{$urls->{"daemon/output"}}}){
		if(!exists($process->{"$url#$output"})){next;}
		my $outputFile="$remotepath/".$process->{"$url#$output"};
		if(defined($opt_l)){print "#Removing $outputFile\n";}
		removeFile($outputFile);
	}
}
############################## removeInputsOutputs ##############################
sub removeInputsOutputs{
	my $command=shift();
	my $process=shift();
	my $url=$process->{$urls->{"daemon/command"}};
	foreach my $input(@{$command->{$urls->{"daemon/input"}}}){
		if(!exists($process->{"$url#$input"})){next;}
		my $inputfile=$process->{"$url#$input"};
		my $inFile="$rootDir/$inputfile";
		if(defined($opt_l)){print "#Removing Input: $inFile\n";}
		unlink($inFile);
	}
	foreach my $output(@{$command->{$urls->{"daemon/output"}}}){
		if(!exists($process->{"$url#$output"})){next;}
		my $outputfile=$process->{"$url#$output"};
		my $outFile="$rootDir/$outputfile";
		if(defined($opt_l)){print "#Removing Output: $outFile\n";}
		unlink($outFile);
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
	my $command=shift();
	my $rdfdb=$command->{$urls->{"daemon/rdfdb"}};
	if(!exists($command->{$urls->{"daemon/query/out"}})){return;}
	my $query=$command->{$urls->{"daemon/query/out"}};
	my $outputs=getQueryResults($rdfdb,$query);
	my $inputTemp={};
	foreach my $input(@{$inputs->[0]}){$inputTemp->{$input}=1;}
	my $commonTemp={};
	my $outputTemp={};
	foreach my $output(@{$outputs->[0]}){
		if(exists($inputTemp->{$output})){$commonTemp->{$output}=1;}
		else{$outputTemp->{$output}=1;}
	}
	my @outputKeys=keys(%{$outputTemp});
	my @commonKeys=keys(%{$commonTemp});
	my @array=();
	foreach my $input(@{$inputs->[1]}){
		my $keep=1;
		foreach my $output(@{$outputs->[1]}){
			my $skip=0;
			foreach my $commonKey(@commonKeys){
				if($input->{$commonKey}ne$output->{$commonKey}){$skip=1;last;}
			}
			if($skip){next;}
			$keep=0;last;
		}
		if($keep){push(@array,$input);}
	}
	$inputs->[1]=\@array;
}
############################## removeUnnecessaryOutputs ##############################
sub removeUnnecessaryOutputs{
	my $queryResults=shift();
	my $command=shift();
	if(!exists($command->{$urls->{"daemon/input"}})){return;}
	if(!exists($command->{$urls->{"daemon/output"}})){return;}
	if(!exists($command->{$urls->{"daemon/userdefined"}})){return;}
	my $inputs=$command->{$urls->{"daemon/input"}};
	my $outputs=$command->{$urls->{"daemon/output"}};
	my $userdefined=$command->{$urls->{"daemon/userdefined"}};
	my $keys=$queryResults->[0];
	my $hashs=$queryResults->[1];
	my @array=();
	foreach my $hash(@{$hashs}){
		my $outputFiles={};
		foreach my $output(@{$outputs}){
			if(!exists($userdefined->{$output})){next;}
			my $outputFile=replaceLineWithHash($hash,$userdefined->{$output});
			if(!fileExists($outputFile)){$outputFiles->{$outputFile}=0;}
			else{$outputFiles->{$outputFile}=checkTimestamp($outputFile);}
		}
		my $inputFiles={};
		foreach my $input(@{$inputs}){
			my $inputFile=replaceLineWithHash($hash,"\$$input");
			if(!fileExists($inputFile)){next;}
			$inputFiles->{$inputFile}=checkTimestamp($inputFile);
		}
		my $inputTime;
		while(my ($file,$time)=each(%{$inputFiles})){
			if(!defined($inputTime)){$inputTime=$time;}
			elsif($time>$inputTime){$inputTime=$time;}
		}
		my $outputTime;
		while(my ($file,$time)=each(%{$outputFiles})){
			if(!defined($outputTime)){$outputTime=$time;}
			elsif($time<$outputTime){$outputTime=$time;}
		}
		if(!defined($outputTime)){next;}
		if(!defined($inputTime)){next;}
		if($inputTime<$outputTime){next;}
		push(@array,$hash);
	}
	if(scalar(@array)==0){$queryResults->[0]=[];}
	$queryResults->[1]=\@array;
}
############################## replaceLineWithHash ##############################
sub replaceLineWithHash{
	my $hash=shift();
	my $line=shift();
	foreach my $key(sort{$a cmp $b}keys(%{$hash})){
		my $val=$hash->{$key};
		$line=~s/\$$key/$val/g;
	}
	return $line;
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
############################## retrieveServerJobs ##############################
sub retrieveServerJobs{
	my $serverpath=shift();
	my $commands=shift();
	my $jobSlot=shift();
	my $processes={};
	my $jobdir="$serverpath/.moirai2/ctrl/job";
	while(jobOfferStart($jobdir)){if(defined($opt_l)){"#repeat"}}#repeat
	my @jobfiles=getJobFiles($jobdir,$jobSlot);
	jobOfferEnd($jobdir);
	foreach my $jobfile(@jobfiles){#job file is /tmp
		my $process=loadProcessFile($jobfile);
		my $url=downloadCommand($process,$serverpath);
		my $command=loadCommandFromURL($url,$commands);
		downloadInputs($command,$process);
		mvProcessFromTmpToJobdir($jobfile,$process);
	}
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
		close($reader);
		if(scalar(@results)==0){return;}
		print join(" ",@results)."\n";
	}
}
############################## rsyncDirectory ##############################
sub rsyncDirectory{
	my $fromDir=shift();
	my $toDir=shift();
	# rsyncDirectory("from/","to"); # A directory "from" will be copied
	# rsyncDirectory("from","to"); # Filed under directory "from" will be copied
	# -r copy  recursively (-a is better?)
	# --copy-links  replace symbolic links with actual files/dirs
	# --keep-dirlinks  don't replace target's symbolic link directory with actual directory
	my $command="rsync -r --copy-links --keep-dirlinks $fromDir $toDir";
	if(defined($opt_l)){print "#Rsync: $fromDir => $toDir\n";}
	return system($command);
}
############################## rsyncProcess ##############################
sub rsyncProcess{
	my $directories=shift();
	if(!defined($opt_a)&&!defined($opt_j)){
		print STDERR "#ERROR:  Please specify Server information with '-a' or '-s'\n";
		exit(1);
	}
	if(defined($opt_j)){#Copy directory from server
		my $fromServer=handleServer($opt_j);
		foreach my $directory(@{$directories}){rsyncDirectory("$fromServer/$directory","$rootDir");}
	}
	if(defined($opt_a)){#Copy directory too remote
		my $toServer=handleServer($opt_a);
		foreach my $directory(@{$directories}){rsyncDirectory("$rootDir/$directory",$toServer);}
	}
}
############################## runDaemon ##############################
sub runDaemon{
	my @arguments=@_;
	my $submitMode;
	my $cronMode;
	my $processMode;
	my $deployMode;
	my $stopMode;
	if(scalar(@arguments)==0){$submitMode=1;$cronMode=1;$processMode=1;}
	foreach my $argument(@arguments){
		if($argument=~/^cron$/i){$cronMode=1;}
		if($argument=~/^process$/i){$processMode=1;}
		if($argument=~/^submit$/i){$submitMode=1;}
		if($argument=~/^deploy$/i){$deployMode=1;}
		if($argument=~/^stop$/i){$stopMode=1;}
	}
	my $stopFile="$moiraidir/stop.txt";
	if(defined($stopMode)){system("touch $stopFile");exit(1);}
	elsif(-e $stopFile){unlink($stopFile);}
	if(defined($opt_b)){
		my $serverpath=handleServer($opt_b);
		my ($username,$servername,$serverdir)=splitServerPath($serverpath);
		my $command="perl moirai2.pl";
		if(defined($opt_a)){$command.=" -a $opt_a";}
		if(defined($opt_d)){$command.=" -d $opt_d";}
		if(defined($opt_j)){$command.=" -j $opt_j";}
		if(defined($opt_l)){$command.=" -l";}
		if(defined($opt_m)){$command.=" -m $opt_m";}
		if(defined($opt_M)){$command.=" -M $opt_M";}
		if(defined($opt_R)){$command.=" -R";}
		if(defined($opt_s)){$command.=" -s $opt_s";}
		$command.=" daemon";
		if(defined($cronMode)){$command.=" cron";}
		if(defined($submitMode)){$command.=" submit";}
		if(defined($processMode)){$command.=" process";}
		if(defined($deployMode)){$command.=" deploy";}
		scpFileIfNecessary("moirai2.pl","$serverpath/moirai2.pl");
		$command="ssh $username\@$servername 'cd $serverdir;nohup $command &>/dev/null &'";
		if(defined($opt_l)){print ">$command\n";}
		system($command);
		exit(0);
	}
	my $commands={};
	my $processes=reloadProcesses($commands);
	my $serverProcesses=reloadServerProcesses($commands);
	my $runCount=defined($opt_R)?$opt_R:undef;
	my $sleeptime=defined($opt_s)?$opt_s:10;
	my $jobserver;
	if(defined($opt_j)){
		$jobserver=handleServer($opt_j);
		my $jobdir.="$jobserver/.moirai2/ctrl/job";
		if(!dirExists($jobdir)){print STDERR "#ERROR No jobdir found '$jobdir'\n";exit(1);}
	}
	if(defined($opt_l)){
		print "#Running moirai2 daemon with:\n";
		if(defined($submitMode)){print "#  - Look for new job sumitted on '$submitdir' directory.\n" }
		if(defined($cronMode)){print "#  - Automatically execute cron specified at '$crondir' directory.\n" }
		if(defined($processMode)){print "#  - Process jobs found at '$jobdir' directory.\n" }
		if(defined($jobserver)){print "#  - Jobs will retrieved from '$jobserver' server.\n" }
	}
	my @crons=();
	my $cronTime=0;
	my $executes={};
	my $execurls=[];
	my @execids=();
	while(true){
		controlWorkflow($processes,$commands);
		controlWorkflow($serverProcesses,$commands);
		if(defined($submitMode)){
			foreach my $file(getFiles($submitdir)){
				my $cmdline="perl $program_directory/moirai2.pl";
				$cmdline.=" -x -w s";
				$cmdline.=" submit $file";
				if(defined($opt_l)){print ">$cmdline\n";}
				my @ids=`$cmdline`;
				if(defined($runCount)){foreach my $id(@ids){chomp($id);push(@execids,$id);}}
			}
		}
		if(defined($cronMode)){# handle cron
			my $time=checkTimestamp($crondir);
			if($cronTime<$time){
				@crons=listFilesRecursively("(\.json|\.sh)\$",undef,-1,$crondir);
				foreach my $url(@crons){
					my $command=loadCommandFromURL($url,$commands);
					if(exists($command->{$urls->{"daemon/timestamp"}})){next;}
					handleRdfdbOption($command);
					$command->{$urls->{"daemon/timestamp"}}=0;
				}
				$cronTime=$time;
			}
			foreach my $url(@crons){
				my $command=$commands->{$url};
				if(daemonCheckTimestamp($command)){
					if(bashCommandHasOptions($command)){
						my $rdfdb=$command->{$urls->{"daemon/rdfdb"}};
						my $cmdline="perl $program_directory/moirai2.pl";
						$cmdline.=" -d $rdfdb";
						$cmdline.=" -x -w a";
						$cmdline.=" $url";
						if(defined($opt_l)){print ">$cmdline\n";}
						my @ids=`$cmdline`;
						if(defined($runCount)){foreach my $id(@ids){chomp($id);push(@execids,$id);}}
					}else{
						my ($writer,$script)=tempfile(DIR=>"/tmp",SUFFIX=>".sh");
						print $writer "bash $url\n";
						close($writer);
						system("bash $script");
					}
				}
			}
		}
		if(defined($processMode)){# main mode local
			my $jobs_running=getNumberOfJobsRunning();
			my $jobSlot=$maxThread-$jobs_running;
			if($jobSlot<=0){sleep($opt_s);next;}
			while(jobOfferStart($jobdir)){if(defined($opt_l)){"#Waiting for job slot\n"}}
			my @jobFiles=getJobFiles($jobdir,$jobSlot);
			jobOfferEnd($jobdir);
			loadExecutes($commands,$executes,$execurls,@jobFiles);
			mainProcess($execurls,$commands,$executes,$processes,$jobSlot);
		}
		if(defined($jobserver)){#get job from the server
			my $jobs_running=getNumberOfJobsRunning();
			my $jobSlot=$maxThread-$jobs_running;
			if($jobSlot<=0){sleep($opt_s);next;}
			retrieveServerJobs($jobserver,$commands,$jobSlot);
		}
		if(-e $stopFile){$runCount=-1;last;}
		if(defined($runCount)){$runCount--;if($runCount<0){last;}}
		sleep($sleeptime);
	}
	#Wait until job is completed when daemon's loop count is defined
	if(defined($runCount)){
		while(true){
			controlWorkflow($processes,$commands);
			my $jobs_running=getNumberOfJobsRunning();
			if($jobs_running>=$maxThread){sleep(opt_s);next;}
			my $job_remaining=getNumberOfJobsRemaining();
			if($jobs_running==0&&$job_remaining==0){controlWorkflow($processes,$commands);last;}
			if($job_remaining==0){sleep(opt_s);}
		}
		moiraiFinally($commands,$processes,@execids);
	}
	if(defined($opt_l)){STDOUT->autoflush(0);}
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
############################## saveCommand ##############################
sub saveCommand{
	my $command=shift();
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".json");
	print $writer "{";
	print $writer saveCommandSub($command,$urls->{"daemon/bash"});
	print $writer saveCommandSub($command,$urls->{"daemon/command/option"});#-b
	print $writer saveCommandSub($command,$urls->{"daemon/container"});#-c
	print $writer saveCommandSub($command,$urls->{"daemon/container/flavor"});#-V
	print $writer saveCommandSub($command,$urls->{"daemon/container/image"});#-I
	print $writer saveCommandSub($command,$urls->{"daemon/error/file/empty"});#-F
	print $writer saveCommandSub($command,$urls->{"daemon/error/stderr/ignore"});#-E
	print $writer saveCommandSub($command,$urls->{"daemon/error/stdout/ignore"});#-O
	print $writer saveCommandSub($command,$urls->{"daemon/file/stats"});#-f
	print $writer saveCommandSub($command,$urls->{"daemon/input"});#-i
	print $writer saveCommandSub($command,$urls->{"daemon/ls"});#-l
	print $writer saveCommandSub($command,$urls->{"daemon/maxjob"});#-m
	print $writer saveCommandSub($command,$urls->{"daemon/output"});#-o
	print $writer saveCommandSub($command,$urls->{"daemon/qjob"});#-q
	print $writer saveCommandSub($command,$urls->{"daemon/qjob/opt"});#-Q
	print $writer saveCommandSub($command,$urls->{"daemon/query/in"});#-i
	print $writer saveCommandSub($command,$urls->{"daemon/query/out"});#-o
	print $writer saveCommandSub($command,$urls->{"daemon/rdfdb"});#-d
	print $writer saveCommandSub($command,$urls->{"daemon/remotepath"});#-a
	print $writer saveCommandSub($command,$urls->{"daemon/serverpath"});#-a
	print $writer saveCommandSub($command,$urls->{"daemon/return"});#-r
	print $writer saveCommandSub($command,$urls->{"daemon/sleeptime"});#-s
	print $writer saveCommandSub($command,$urls->{"daemon/script"});#-S
	print $writer saveCommandSub($command,$urls->{"daemon/singlethread"});#-T
	print $writer saveCommandSub($command,$urls->{"daemon/suffix"});#-X
	print $writer saveCommandSub($command,$urls->{"daemon/userdefined"});
	print $writer "}\n";
	close($writer);
	return saveCommandWrite($file,$command->{$urls->{"daemon/command"}});
}
sub saveCommandSub{
	my $command=shift();
	my $url=shift();
	if(exists($command->{$url})){
		if($url eq $urls->{"daemon/maxjob"}&&$command->{$url}==1){return;}
		if($url eq $urls->{"daemon/sleeptime"}&&$command->{$url}==10){return;}
		my $line="";
		if($url ne $urls->{"daemon/bash"}){$line=",";}
		my $value=$command->{$url};
		if(ref($value)eq"ARRAY"){
			if(scalar(@{$value})==0){return;}
			if(scalar(@{$value})==1){$value=$value->[0];}
		}elsif(ref($value)eq"HASH"){
			if(scalar(keys(%{$value}))==0){return;}
		}
		$line.="\"$url\":".jsonEncode($value);
		return $line;
	}
}
sub saveCommandWrite{
	my $file=shift();
	my $url=shift();
	if($file=~/^\.\/(.+)$/){$file=$1;}
	my $json;
	if(defined($url)){
		if(defined($md5cmd)){
			my $md5=`$md5cmd<$file`;chomp($md5);
			my $md=`$md5cmd<$url`;chomp($md);
			if($md eq $md5){$json=$url;}
		}else{
			my $sizeA=-s $file;
			my $sizeB=-s $url;
			if($sizeA!=$sizeB){next;}
			if(compareFiles($sizeA,$sizeB)){$json=$sizeB;last;}
		}
		if(defined($json)){unlink($file);return $json;}
	}
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
		my ($writer,$tmpfile)=tempfile("j".getDatetime()."XXXX",DIR=>$cmddir,SUFFIX=>".json");
		close($writer);
		$json=$tmpfile;
		system("mv $file $json");
	}
	return $json;
}
############################## scpFileIfNecessary ##############################
sub scpFileIfNecessary{
	my $from=shift();
	my $to=shift();
	my $timeFrom=checkTimestamp($from);
	my $timeTo=checkTimestamp($to);
	if(!defined($timeTo)||$timeFrom>$timeTo){
		createDirs(dirname($to));
		if(defined($opt_l)){print "#Coyping $from => $to\n";}
		system("scp -r $from $to 2>&1 1>/dev/null");
	}
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
############################## setCommandOptions ##############################
sub setCommandOptions{
	my $line=shift();
	my $hash={};
	my @tokens=split(/,/,$line);
	foreach my $token(@tokens){
		my @t=split(/:/,$token);
		if($t[0]=~/^\$(.+)$/){$t[0]=$1;}
		$hash->{$t[0]}=$t[1];
	}
	return $hash;
}
############################## setInputsOutputsFromCommand ##############################
sub setInputsOutputsFromCommand{
	my $command=shift();
	my $userdefined=$command->{$urls->{"daemon/userdefined"}};
	my $inputKeys=$command->{$urls->{"daemon/input"}};
	my $outputKeys=$command->{$urls->{"daemon/output"}};
	my $suffixs=$command->{$urls->{"daemon/suffix"}};
	my $cmdlines=$command->{$urls->{"daemon/bash"}};
	my $lsInputs=exists($command->{$urls->{"daemon/ls"}})?["filepath","directory","filename","basename","suffix","base\\d+","dir\\d+"]:[];
	my $systemInputs=["cmdurl","execid","workdir","rootdir","tmpdir"];
	my @inputs=();
	my @outputs=();
	my $files={};
	my $variables={};
	my $temporaries={};# '$tmpdir/temporary.txt', for example
	my @outlines=();
	if(!defined($inputKeys)){$inputKeys=[];}
	if(!defined($outputKeys)){$outputKeys=[];}
	if(!defined($suffixs)){$suffixs={};}
	my $scriptNames={};
	if(exists($command->{$urls->{"daemon/script"}})){
		foreach my $script(@{$command->{$urls->{"daemon/script"}}}){
			$scriptNames->{$script->{"daemon/script/name"}}=1;
		}
	}
	foreach my $variable(@{$inputKeys}){$variables->{$variable}="input";}
	foreach my $variable(@{$outputKeys}){$variables->{$variable}="output";}
	foreach my $cmdline(@{$cmdlines}){
		push(@outlines,$cmdline);
		while($cmdline=~/(\$tmpdir\/\S+\.(\w{2,4}))(\;|$||\s|\>)/g){
			my $temporary=$1;
			if(!exists($temporaries->{$temporary})){$temporaries->{$temporary}=1;}
		}
		while($cmdline=~/(\$workdir\/\S+\.(\w{2,4}))(\;|$||\s|\>)/g){
			my $temporary=$1;
			if(!exists($temporaries->{$temporary})){$temporaries->{$temporary}=1;}
		}
		while($cmdline=~/([\w\_\/\.\$]+\.(\w{2,4}))(\;|$||\s|\>)/g){
			my $file=$1;
			if($file=~/\$/){next;}
			if(!exists($files->{$file})){$files->{$file}=1;}
		}
		foreach my $file(keys(%{$files})){
			if($files->{$file}!=1){next;}
			if($cmdline=~/\s*\>\s*$file/){$files->{$file}="output";}
		}
		foreach my $file(keys(%{$files})){
			if($files->{$file}!=1){next;}
			if($cmdline=~/^\s*[\/\_\w]*$file/){$files->{$file}="script";}
		}
		foreach my $program("perl","bash","java","python","R"){
			foreach my $file(keys(%{$files})){
				if($files->{$file}!=1){next;}
				if($cmdline=~/^\s*$program \s*[\/\_\w]*$file/){$files->{$file}="script";}
			}
		}
		while($cmdline=~/\$([\w\_]+)/g){
			my $variable=$1;
			
			if(!exists($variables->{$variable})){$variables->{$variable}=1;}
		}
		foreach my $variable(keys(%{$variables})){
			if($variables->{$variable}!=1){next;}
			foreach my $input(@{$lsInputs}){if($variable=~/$input/){$variables->{$variable}="input"}}
			foreach my $input(@{$systemInputs}){if($variable=~/$input/){$variables->{$variable}="input"}}
		}
		foreach my $variable(keys(%{$variables})){
			if($variables->{$variable}!=1){next;}
			if($cmdline=~/\s*\>\s*\$$variable/){$variables->{$variable}="output";}
		}
	}
	foreach my $file(keys(%{$files})){if($scriptNames->{$file}){$files->{$file}="script";}}
	foreach my $variable(sort{$a cmp $b}keys(%{$variables})){
		if($variables->{$variable}!=1){next;}
		print "\$$variable is [I]nput/[O]utput? ";
		while(<STDIN>){
			chomp();
			if(/^i/i){$variables->{$variable}="input";last;}
			elsif(/^o/i){$variables->{$variable}="output";last;}
			elsif(/^n/i){last;}
			print "Please type 'i' or 'o' only\n";
			print "\$$variable is [I]nput/[O]utput? ";
		}
	}
	foreach my $file(sort{$a cmp $b}keys(%{$files})){
		if($files->{$file}!=1){next;}
		print "$file is [I]nput/[O]utput? ";
		while(<STDIN>){
			chomp();
			if(/^i/i){$files->{$file}="input";last;}
			elsif(/^o/i){$files->{$file}="output";last;}
			elsif(/^n/i){last;}
			print "Please type 'i' or 'o' only\n";
			print "$file is [I]nput/[O]utput? ";
		}
	}
	while(my ($file,$type)=each(%{$files})){
		my $name;
		if($type eq "input"){
			$name="in".(scalar(@inputs)+1);
			$variables->{$name}=$type;
			if($file=~/(\.\w{2,4})$/){$suffixs->{$name}=$1;}
		}elsif($type eq "output"){
			$name="out".(scalar(@outputs)+1);
			$variables->{$name}=$type;
			if($file=~/(\.\w{2,4})$/){$suffixs->{$name}=$1;}
		}else{next;}
		foreach my $line(@outlines){$line=~s/$file/\$$name/g;}
		$userdefined->{$name}=$file;
	}
	#Specify text=>variable before variable
	while(my ($variable,$type)=each(%{$variables})){
		if($type eq "input"){push(@inputs,$variable);}
		if($type eq "output"){push(@outputs,$variable);}
	}
	foreach my $input(@inputs){if(!existsArray($inputKeys,$input)){push(@{$inputKeys},$input);}}
	foreach my $output(@outputs){if(!existsArray($outputKeys,$output)){push(@{$outputKeys},$output);}}
	if(scalar(keys(%{$userdefined}))>0){$command->{$urls->{"daemon/userdefined"}}=$userdefined;}
	if(scalar(@{$inputKeys})>0){$command->{$urls->{"daemon/input"}}=$inputKeys;}
	if(scalar(@{$outputKeys})>0){$command->{$urls->{"daemon/output"}}=$outputKeys;}
	if(scalar(keys(%{$suffixs}))>0){$command->{$urls->{"daemon/suffix"}}=$suffixs;}
	$command->{$urls->{"daemon/bash"}}=\@outlines;
}
############################## sortSubs ##############################
sub sortSubs{
	my $path="$program_directory/$program_name";
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
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".pl");
	foreach my $line(@headers){print $writer "$line\n";}
	foreach my $key(sort{$a cmp $b}@orders){foreach my $line(@{$blocks->{$key}}){print $writer "$line\n";}}
	close($writer);
	chmod(0755,$file);
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
	system("tar -C $root -czvf $directory.tgz $dir 2>/dev/null");
	system("rm -r $directory 2>/dev/null");
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
	else{for(my $i=0;$i<=7;$i++){$hash->{$i}=1;}}
	if(fileExistsInDirectory("test")){system("rm -r test/*");}
	mkdir("test");
	if(exists($hash->{0})){test0();}
	if(exists($hash->{1})){test1();}
	if(exists($hash->{2})){test2();}
	if(exists($hash->{3})){test3();}
	if(exists($hash->{4})){test4();}
	if(exists($hash->{5})){test5();}
	if(exists($hash->{6})){test6();}
	if(exists($hash->{7})){test7();}
	rmdir("test");
}
#Test test
sub test0{
}
#Testing sub functions
sub test1{
	testSub("handleInputOutput(\"\\\$input\")",["input"]);
	testSub("handleInputOutput(\"\\\$input1,\\\$input2\")",["input1","input2"]);
	testSubs("handleInputOutput(\"\\\$input1->input->\\\$input2\")",["input1","input2"],["\$input1->input->\$input2"],undef,undef);
	testSubs("handleInputOutput(\"\\\$input1->input->\\\$input2,\\\$input3\")",["input1","input2","input3"],["\$input1->input->\$input2"],undef,undef);
	testSubs("handleInputOutput(\"\\\$input,*.pl\")",["input"],undef,["*.pl"],undef);
	testSubs("handleInputOutput(\"\\\$input.txt\")",["input"],undef,undef,{"input"=>".txt"});
	testSubs("handleInputOutput(\"\\\$root->pred->\\\$input.txt\")",["root","input"],["\$root->pred->\$input"],undef,{"input"=>".txt"});
	testSub("handleInputOutput(\"\\\$root->\\\$name/pred->\\\$input.txt\",{\"name\"=>\"Akira\"})",["root","input"]);
	testSubs("handleInputOutput(\"\\\$root->\\\$name/pred->\\\$input.txt\",{\"name\"=>\"Akira\"})",["root","input"],["\$root->Akira/pred->\$input"],undef,{"input"=>".txt"});
	testSubs("handleInputOutput(\"\\\$root->pred1/\\\$name/pred2->\\\$input.txt\",{\"name\"=>\"Akira\"})",["root","input"],["\$root->pred1/Akira/pred2->\$input"],undef,{"input"=>".txt"});
	testSubs("handleInputOutput(\"\\\$root->pred1/\\\$name/pred2->\\\$input.txt,\\\$input3\",{\"name\"=>\"Akira\"})",["root","input","input3"],["\$root->pred1/Akira/pred2->\$input"],undef,{"input"=>".txt"});
	testSub("handleInputOutput(\"{'\\\$input':'defaultvalue'}\")",["input"]);
	testSubs("handleInputOutput(\"{'\\\$input':{'suffix':'.txt'}}\")",["input"],undef,undef,{"input"=>".txt"});
	testSubs("handleInputOutput(\"{'\\\$input':{'default':'something','suffix':'.txt'},'\\\$input2':{'default':'something2','suffix':'.csv'}}\")",["input","input2"],undef,undef,{"input"=>".txt","input2"=>".csv"});
	testSubs("handleInputOutput(\"{'\\\$input':{'default':'something','suffix':'.txt'}}\")",["input"],undef,undef,{"input"=>".txt"});
	testSubs("handleArguments(\"line1\",\"line2\",\"input=input.txt\",\"output=output.txt\")",["line1","line2"],{"input"=>"input.txt","output"=>"output.txt"});
	testSubs("handleArguments(\"line=`line1`;\",\"input=input.txt\",\"output=output.txt\")",["line=`line1`"],{"input"=>"input.txt","output"=>"output.txt"});
	testSubs("handleKeys(\"\\\$input\")",["input"]);
	testSubs("handleKeys(\"\\\$input1,\\\$input2\")",["input1","input2"]);
	testSubs("handleKeys(\"\\\$input1.txt,input2.html\")",["input1","input2"]);
}
#Testing basic json functionality
sub test2{
	#testing input/output 1
	createFile("test/Akira.txt","A","B","C","D","A","D","B");
	testCommand("perl $program_directory/rdf.pl -d test insert root file test/Akira.txt","inserted 1");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -i 'root->file->\$file' exec 'sort \$file'","A","A","B","B","C","D","D");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -i 'root->file->\$file' -r 'output' exec 'sort \$file|uniq -c>\$output' '\$output=test/output.txt'","test/output.txt");
	testCommand("perl $program_directory/rdf.pl -d test delete root file test/Akira.txt","deleted 1");
	unlink("test/output.txt");
	unlink("test/Akira.txt");
	#testing input/output 2
	createFile("test/A.json","{\"https://moirai2.github.io/schema/daemon/input\":\"\$string\",\"https://moirai2.github.io/schema/daemon/bash\":[\"echo \\\"\$string\\\" > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -r '\$output' test/A.json 'Akira Hasegawa' test/output.txt","test/output.txt");
	testCommand("cat test/output.txt","Akira Hasegawa");
	unlink("test/output.txt");
	testCommand("perl $program_directory/rdf.pl -d test insert case1 'string' 'Akira Hasegawa'","inserted 1");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -i '\$id->string->\$string' -o '\$id->text->\$output' test/A.json 'output=test/\$id.txt'","");
	testCommand("cat test/case1.txt","Akira Hasegawa");
	testCommand("perl $program_directory/rdf.pl -d test select case1 text","case1\ttext\ttest/case1.txt");
	unlink("test/A.json");
	#testing input/output 3
	createFile("test/B.json","{\"https://moirai2.github.io/schema/daemon/input\":\"\$input\",\"https://moirai2.github.io/schema/daemon/bash\":[\"sort \$input > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -i '\$id->text->\$input' -o '\$input->sorted->\$output' test/B.json '\$output=test/\$id.sort.txt'","");
	testCommand("cat test/case1.sort.txt","Akira Hasegawa");
	testCommand("perl $program_directory/rdf.pl -d test select % 'sorted'","test/case1.txt\tsorted\ttest/case1.sort.txt");
	createFile("test/case2.txt","Hasegawa","Akira","Chiyo","Hasegawa");
	testCommand("perl $program_directory/rdf.pl -d test insert case2 'text' test/case2.txt","inserted 1");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -i '\$id->text->\$input' -o '\$input->sorted->\$output' test/B.json '\$output=test/\$id.sort.txt'","");
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
	createFile("$moiraidir/ctrl/insert/A.txt","A\ttest/name\tAkira");
	system("echo 'mkdir -p test/\$dirname'|perl $program_directory/moirai2.pl -d test -s 1 -i '\$id->name->\$dirname' -o '\$id->mkdir->done' command");
	if(!-e "test/Akira"){print STDERR "test/Akira directory not created\n";}
	else{rmdir("test/Akira");}
	createFile("$moiraidir/ctrl/insert/B.txt","B\ttest/name\tBen");
	system("echo 'mkdir -p test/\$dirname'|perl $program_directory/moirai2.pl -d test -s 1 -i '\$id->name->\$dirname' -o '\$id->mkdir->done' command");
	if(!-e "test/Ben"){print STDERR "test/Ben directory not created\n";}
	else{rmdir("test/Ben");}
	unlink("test/mkdir.txt");
	unlink("test/name.txt");
	#input and output defaults
	createFile("test/input.txt","Hello World\nAkira Hasegawa\nTsunami Channel");
	testCommand("perl $program_directory/moirai2.pl -r output -i '{\"input\":\"test/input.txt\"}' -o '{\"output\":\"test/output.txt\"}' exec 'wc -l \$input > \$output'","test/output.txt");
	testCommandRegex("cat test/output.txt","3 test/input.txt");
	unlink("test/output.txt");
	testCommandRegex("perl $program_directory/moirai2.pl -r output -i '\$input' -o '\$output.txt' exec 'wc -l < \$input> \$output;' input=test/input.txt",".moirai2/e\\w{18}/tmp/output.txt\$");
	unlink("test/input.txt");
	system("perl $program_directory/moirai2.pl clean dir");
}
#Testing exec and bash functionality
sub test3{
	#Testing exec1
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 exec 'ls $moiraidir/ctrl'","config","delete","insert","job","process","submit","update");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -r '\$output' exec 'output=(`ls $moiraidir/ctrl`);'","config delete insert job process submit update");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -r output exec 'ls -lt > \$output' '\$output=test/list.txt'","test/list.txt");
	unlink("test/list.txt");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -o '$moiraidir/ctrl->file->\$output' exec 'output=(`ls $moiraidir/ctrl`);'","");
	testCommand("perl $program_directory/rdf.pl -d test select $moiraidir/ctrl file","$moiraidir/ctrl\tfile\tconfig","$moiraidir/ctrl\tfile\tdelete","$moiraidir/ctrl\tfile\tinsert","$moiraidir/ctrl\tfile\tjob","$moiraidir/ctrl\tfile\tprocess","$moiraidir/ctrl\tfile\tsubmit","$moiraidir/ctrl\tfile\tupdate");
	testCommand("perl $program_directory/rdf.pl -d test delete % % %","deleted 7");
	#Testing exec2
	createFile("test/hello.txt","A","B","C","A");
	testCommand("perl $program_directory/moirai2.pl -r output -i input -o output exec 'sort -u \$input > \$output;' input=test/hello.txt output=test/output.txt","test/output.txt");
	testCommand("cat test/output.txt","A\nB\nC");
	unlink("test/output.txt");
	testCommand("echo i|perl $program_directory/moirai2.pl -r out1 exec 'sort -u test/hello.txt > test/output2.txt' > /dev/null","test/hello.txt is [I]nput/[O]utput? test/output2.txt");
	testCommand("cat test/output2.txt","A\nB\nC");
	unlink("test/hello.txt");
	unlink("test/output2.txt");
	#Testing bash functionality
	createFile("test/test.sh","#\$-i \$id->input->\$input","#\$-o \$id->output->\$output.txt","sort \$input | uniq -c > \$output");
	createFile("test/input.txt","A","B","D","C","F","E","G","A","A","A");
	testCommand("perl $program_directory/rdf.pl -d test/db insert idA input test/input.txt","inserted 1");
	testCommand("perl $program_directory/moirai2.pl -d test/db -s 1 -r '\$output' test/test.sh output=test/uniq.txt","test/uniq.txt");
	testCommand("perl $program_directory/moirai2.pl -d test/db -s 1 -r '\$output' test/test.sh output=test/uniq.txt","");
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
	testCommand("perl $program_directory/moirai2.pl -r output -s 1 test/test.sh","test/input.out.txt");
	testCommand("cat test/input.out.txt","   1 Hello","   1 World");
	unlink("test/test.sh");
	unlink("test/input.txt");	
	unlink("test/input.out.txt");
	createFile("test/test.sh","#\$-o output","echo 'Hello World' > \$output");
	testCommand("perl $program_directory/moirai2.pl -r output test/test.sh output=test/output.txt","test/output.txt");
	unlink("test/test.sh");
	unlink("test/output.txt");
	#Testing suffix
	createFile("test/input.txt","Hello","World");
	testCommandRegex("perl $program_directory/moirai2.pl -i input -r output -X '\$output.txt' exec 'wc -l \$input > \$output' input=test/input.txt",".moirai2/e\\w{18}/tmp/output.txt\$");
	system("perl $program_directory/moirai2.pl clean dir");
	unlink("test/input.txt");
	#Testing multiple inputs
	createFile("test/text.txt","example\tAkira","example\tBen","example\tChris","example\tDavid");
	testCommand("perl $program_directory/moirai2.pl -d test  -i 'example->text->(\$input)' exec 'echo \${input\[\@\]}'","Akira Ben Chris David");
	unlink("test/text.txt");
	#Testing multiple outputs
	testCommand("perl $program_directory/moirai2.pl -d test -o 'name->test->\$output' exec 'output=(\"Akira\" \"Ben\" \"Chris\" \"David\");'","");
	testCommand("cat test/test.txt","name\tAkira","name\tBen","name\tChris","name\tDavid");
	unlink("test/test.txt");
}
#Testing build and ls functionality
sub test4{
	# Testing build
	createFile("test/1.sh","ls \$input > \$output");
	testCommand("perl $program_directory/moirai2.pl -d test -i '\$input' -o '\$output' build < test/1.sh|xargs cat","{\"https://moirai2.github.io/schema/daemon/bash\":\"ls \$input > \$output\",\"https://moirai2.github.io/schema/daemon/input\":\"input\",\"https://moirai2.github.io/schema/daemon/output\":\"output\",\"https://moirai2.github.io/schema/daemon/rdfdb\":\"test\"}");
	testCommand("perl $program_directory/moirai2.pl -d test -i 'root->directory->\$input' -o 'root->content->\$output' build < test/1.sh|xargs cat","{\"https://moirai2.github.io/schema/daemon/bash\":\"ls \$input > \$output\",\"https://moirai2.github.io/schema/daemon/input\":\"input\",\"https://moirai2.github.io/schema/daemon/output\":\"output\",\"https://moirai2.github.io/schema/daemon/query/in\":\"root->directory->\$input\",\"https://moirai2.github.io/schema/daemon/query/out\":\"root->content->\$output\",\"https://moirai2.github.io/schema/daemon/rdfdb\":\"test\"}");
	unlink("test/1.sh");
	#Testing ls
	mkdir("test/dir");
	system("touch test/dir/A.txt");
	system("touch test/dir/B.gif");
	system("touch test/dir/C.txt");
	testCommand("perl $program_directory/moirai2.pl -d test ls test/dir","test/dir/A.txt","test/dir/B.gif","test/dir/C.txt");
	testCommand("perl $program_directory/moirai2.pl -d test -o '\$filename' ls test/dir","A.txt","B.gif","C.txt");
	testCommand("perl $program_directory/moirai2.pl -d test -o '\$suffix' ls test/dir","txt","gif","txt");
	testCommand("perl $program_directory/moirai2.pl -d test -x -o 'root->file->\$filepath' ls test/dir","root\tfile\ttest/dir/A.txt","root\tfile\ttest/dir/B.gif","root\tfile\ttest/dir/C.txt");
	testCommand("perl $program_directory/moirai2.pl -d test -g txt -o '\$filepath' ls test/dir","test/dir/A.txt","test/dir/C.txt");
	testCommand("perl $program_directory/moirai2.pl -d test -G txt -o '\$base0' ls test/dir","B");
	testCommand("perl $program_directory/moirai2.pl -d test -l -o 'root->file->\$filepath' ls test/dir","inserted 3");
	testCommand("perl $program_directory/rdf.pl -d test insert root directory test/dir","inserted 1");
	testCommand("perl $program_directory/moirai2.pl -d test -i 'root->directory->\$input' ls","test/dir/A.txt","test/dir/B.gif","test/dir/C.txt");
	testCommand("perl $program_directory/rdf.pl -d test delete % % %","deleted 4");
	system("rm -r test/dir");
	#Testing submit function
	createFile("test/submit.json","{\"https://moirai2.github.io/schema/daemon/bash\":[\"ls test\"],\"https://moirai2.github.io/schema/daemon/return\":\"stdout\",\"https://moirai2.github.io/schema/daemon/sleeptime\":\"1\"}");
	createFile("test/submit.txt","url\ttest/submit.json");
	testCommand("perl $program_directory/moirai2.pl -d test submit test/submit.txt","submit.json");
	#Testing submit function with daemon
	createFile(".moirai2/ctrl/submit/submit.txt","url\ttest/submit.json");
	testCommand("perl $program_directory/moirai2.pl -d test -R 0 daemon submit process","submit.json");
	unlink("test/submit.json");
	#Testing bash script submit
	createFile("test/submit.sh","#\$ -i message","#\$ -o output","#\$ -r output","#\$ message=test script","#\$ output=test/output.txt","echo \"Hello \$message\">\$output");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 test/submit.sh message=Akira|xargs cat","Hello Akira");
	#no input argument
	createFile(".moirai2/ctrl/submit/submit.txt","url\ttest/submit.sh");
	testCommand("perl $program_directory/moirai2.pl -d test -R 0 daemon submit process|xargs cat","Hello test script");
	#with input argument
	createFile(".moirai2/ctrl/submit/submit.txt","url\ttest/submit.sh","message\tHasegawa");
	testCommand("perl $program_directory/moirai2.pl -d test -R 0 daemon submit process|xargs cat","Hello Hasegawa");
	unlink("test/submit.sh");
	unlink("test/output.txt");
	#Testing daemon functionality
	mkdir("cron");
	createFile("cron/hello.sh","#\$ -i \$id->message->\$message","#\$ -o \$id->output->\$output","#\$ -r output","#\$ message=test","#\$ output=test/\$id.txt","echo \"Hello \$message\">\$output");
	createFile("test/message.txt","Akira\tHasegawa");
	testCommand("perl $program_directory/moirai2.pl -d test -R 0 daemon cron process","test/Akira.txt");
	testCommand("cat test/output.txt","Akira\ttest/Akira.txt");
	testCommand("cat test/Akira.txt","Hello Hasegawa");
	testCommand("perl $program_directory/moirai2.pl -d test -R 0 daemon cron process","");
	unlink("test/Akira.txt");
	unlink("test/output.txt");
	unlink("test/message.txt");
	unlink("cron/hello.sh");
	#Testing bash
	createFile("test/input1.txt","Akira\tHello");
	createFile("test/input2.txt","Akira\tWorld");
	createFile("test/command.sh","#\$ -i \$name->input1->\$input1,\$name->input2->\$input2","#\$ -r stdout","echo \"\$input1 \$input2 \$name\"");
	testCommand("perl $program_directory/moirai2.pl -d test test/command.sh","Hello World Akira");
	unlink("test/input1.txt");
	unlink("test/input2.txt");
	unlink("test/command.sh");
	mkdir("test");
	#Testing -i *
	testCommand("perl $program_directory/moirai2.pl -i 'js/ah3q/*.js' exec 'wc -l <\$filepath>test/\$basename.txt'","");
	testCommandRegex("cat test/moirai2.txt","\\s+\\d+");
	testCommandRegex("cat test/tab.txt","\\s+\\d+");
	unlink("test/moirai2.txt");
	unlink("test/tab.txt");
	#Testing -i * with $tmpdir
	testCommand("perl /Users/ah3q/Sites/moirai2/moirai2.pl -i 'js/ah3q/*.js' exec 'wc -l <\$filepath>\$tmpdir/tmp.txt;uniq -c \$tmpdir/tmp.txt > test/\$basename.txt;rm \$tmpdir/tmp.txt'","");
	testCommandRegex("cat test/moirai2.txt","\\s+\\d+");
	testCommandRegex("cat test/tab.txt","\\s+\\d+");
	unlink("test/moirai2.txt");
	unlink("test/tab.txt");
	#Testing -i * with $opt_t
	system("mkdir -p test/in");
	system("mkdir -p test/out");
	createFile("test/in/input1.txt","one");
	createFile("test/in/input2.txt","two");
	testCommand("perl $program_directory/moirai2.pl -t -r output -i 'test/in/*.txt' exec 'wc -l <\$filepath>\$output;' 'output=test/out/\$basename.txt'","test/out/input1.txt","test/out/input2.txt");
	testCommandRegex("cat test/out/input1.txt","\\s+\\d+");
	testCommandRegex("cat test/out/input2.txt","\\s+\\d+");
	testCommand("perl $program_directory/moirai2.pl -t -r output -i 'test/in/*.txt' exec 'wc -l <\$filepath>\$output;' 'output=test/out/\$basename.txt'","");
	system("touch test/in/input1.txt");
	testCommand("perl $program_directory/moirai2.pl -t -r output -i 'test/in/*.txt' exec 'wc -l <\$filepath>\$output;' 'output=test/out/\$basename.txt'","test/out/input1.txt");
	unlink("test/out/input2.txt");
	testCommand("perl $program_directory/moirai2.pl -t -r output -i 'test/in/*.txt' exec 'wc -l <\$filepath>\$output;' 'output=test/out/\$basename.txt'","test/out/input2.txt");
	testCommand("perl $program_directory/moirai2.pl -t -r output -i 'test/in/*.txt' exec 'wc -l <\$filepath>\$output;' 'output=test/out/\$basename.txt'","");
	unlink("test/in/input1.txt");
	unlink("test/in/input2.txt");
	unlink("test/out/input1.txt");
	unlink("test/out/input2.txt");
	system("rmdir test/in");
	system("rmdir test/out");
}
#Testing containers
sub test5{
	createFile("test/C.json","{\"https://moirai2.github.io/schema/daemon/bash\":\"unamea=\$(uname -a)\",\"https://moirai2.github.io/schema/daemon/output\":\"\$unamea\"}");
	my $name=`uname -s`;chomp($name);
	testCommandRegex("perl $program_directory/moirai2.pl -d test -s 1 -r unamea test/C.json","^$name");
	testCommandRegex("perl $program_directory/moirai2.pl -d test -q qsub -s 1 -r unamea test/C.json","^$name");
	testCommandRegex("perl $program_directory/moirai2.pl -d test -s 1 -r unamea -c ubuntu test/C.json","^Linux");
	testCommandRegex("perl $program_directory/moirai2.pl -d test -q qsub -s 1 -r unamea -c ubuntu test/C.json","^Linux");
	unlink("test/C.json");
	createFile("test/D.json","{\"https://moirai2.github.io/schema/daemon/container\":\"ubuntu\",\"https://moirai2.github.io/schema/daemon/bash\":\"unamea=\$(uname -a)\",\"https://moirai2.github.io/schema/daemon/output\":\"\$unamea\"}");
	testCommandRegex("perl $program_directory/moirai2.pl -d test -s 1 -r unamea test/D.json","^Linux");
	testCommandRegex("perl $program_directory/moirai2.pl -d test -q qsub -s 1 -r unamea test/D.json","^Linux");
	testCommandRegex("perl $program_directory/moirai2.pl -d test -s 1 -r unamea -c ubuntu test/D.json","^Linux");
	testCommandRegex("perl $program_directory/moirai2.pl -d test -q qsub -s 1 -r unamea -c ubuntu test/D.json","^Linux");
	unlink("test/D.json");
}
#Testing daemon across server
sub test6{
	my $testserver="ah3q\@172.18.91.78"; #My Hokusai server
	system("ssh $testserver 'mkdir -p moiraitest'");
	system("ssh $testserver 'echo \"Hello World\">moiraitest/input.txt'");
	system("scp moirai2.pl $testserver:moiraitest/. 2>&1 1>/dev/null");
	system("scp rdf.pl $testserver:moiraitest/. 2>&1 1>/dev/null");
	system("ssh $testserver \"cd moiraitest;perl moirai2.pl clear all\"");
	# assign job at the server, copy job to local, and execute on a local daemon (-x)
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -x -i input -o output exec 'wc -l \\\$input > \\\$output;' input=input.txt output=output.txt\"","^e\\d{14}\\w{4}\$");
	system("perl $program_directory/moirai2.pl -j $testserver:moiraitest -s 1 -R 0 daemon");
	testCommand("cat input.txt","Hello World");#copied from job server
	system("perl $program_directory/moirai2.pl -s 1 -R 0 daemon process");
	testCommand("ssh $testserver 'cat moiraitest/input.txt'","Hello World");
	system("ssh $testserver \"cd moiraitest;perl moirai2.pl -R 0 daemon\"");
	testCommand("ssh $testserver 'cat moiraitest/input.txt'","Hello World");
	testCommand("ssh $testserver 'cat moiraitest/output.txt'","       1 input.txt");
	my $datetime=getDate();
	testCommandRegex("ssh $testserver 'ls moiraitest/.moirai2/log/$datetime/*.txt'","moiraitest/.moirai2/log/\\d+/.+\\.txt");
	# assign on a local daemon and execute on a remote server (-a)
	createFile("input2.txt","Akira Hasegawa");
	testCommand("perl $program_directory/moirai2.pl -r output -i input -o output -a $testserver:moiraitest exec 'wc -c \$input > \$output;' input=input2.txt output=output2.txt","output2.txt");
	testCommand("cat output2.txt","15 input2.txt");
	unlink("input2.txt");
	unlink("output2.txt");
	# assign job at server, copy and execute job in one command line (daemon process)
	system("ssh $testserver 'echo \"Hello World\nAkira Hasegawa\">moiraitest/input3.txt'");
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -x -i input -o output exec 'wc -l \\\$input > \\\$output;' input=input3.txt output=output3.txt\"","^e\\d{14}\\w{4}\$");
	system("perl $program_directory/moirai2.pl -j $testserver:moiraitest -s 1 -R 1 daemon process");
	testCommand("ssh $testserver 'cat moiraitest/output3.txt'","       2 input3.txt");
	# assign job to the server from local with -j option
	createFile("input4.txt","Hello World\nAkira Hasegawa\nTsunami Channel");
	testCommandRegex("perl $program_directory/moirai2.pl -x -j $testserver:moiraitest -i input -o output exec 'wc -l \$input > \$output;' input=input4.txt output=output4.txt","^e\\d{14}\\w{4}\$");
	system("ssh $testserver 'cd moiraitest;perl moirai2.pl -s 1 -R 0 daemon process'");
	testCommand("ssh $testserver 'cat moiraitest/output4.txt'","3 input4.txt");
	unlink("input4.txt");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver exec uname","Linux");
	testCommandRegex("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver -c ubuntu exec uname -a","^Linux .+ x86_64 x86_64 x86_64 GNU/Linux\$");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver -c singularity/lolcow.sif exec cowsay 'Hello World'"," _____________","< Hello World >"," -------------","        \\   ^__^","         \\  (oo)\\_______","            (__)\\       )\\/\\","                ||----w |","                ||     ||");
	testCommandRegex("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver exec hostname","^moirai\\d+-server");
	system("ssh $testserver 'rm -r moiraitest'");
}
#Testing Hokusai openstack (Takes about 5-10 minutes)
sub test7{
	my $testserver="ah3q\@172.18.91.78"; #My Hokusai server
	testCommandRegex("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver -q openstack exec hostname","^moirai\\d+-node-\\d+\$");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver -c singularity/lolcow.sif -q openstack exec cowsay"," __","<  >"," --","        \\   ^__^","         \\  (oo)\\_______","            (__)\\       )\\/\\","                ||----w |","                ||     ||");
}
############################## testCommand ##############################
sub testCommand{
	my @values=@_;
	my $command=shift(@values);
	my $value2=join("\n",@values);
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
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
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
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
	if(ref($value2)eq"ARRAY"||ref($value2)eq"ARRAY"){printTable($value1);printTable($value2);}
	else{print STDERR "'$value1' != '$value2'\n";}
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
		my $command=which("qsub",$cmdpaths,$servername);
		if(defined($qjobopt)){$command.=" $qjobopt";}
		$command.=" $path";
		if(defined($servername)){$command="ssh $servername \"$command\" 2>&1 1>/dev/null";}
		if(system($command)==0){sleep(1);}
		else{appendText("ERROR: Failed to $command",$stderr);}
	}elsif($qjob eq "slurm"){
		my $command=which("sbatch",$cmdpaths,$servername);
		$command.=" -o $stdout";
		$command.=" -e $stderr";
		if(defined($qjobopt)){$command.=" $qjobopt";}
		$command.=" $path";
		if(defined($servername)){$command="ssh $servername \"$command\" 2>&1 1>/dev/null";}
		if(defined($opt_l)){print ">$command\n";}
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
	my $remotepath=$command->{$urls->{"daemon/remotepath"}};
	my $username;
	my $servername;
	my $serverdir;
	if(defined($remotepath)){($username,$servername,$serverdir)=splitServerPath($remotepath);}
	if(scalar(@variables)==0){return;}
	my ($fh,$path)=tempfile("bashXXXXXXXXXX",DIR=>"$rootDir/$throwdir",SUFFIX=>".sh");
	chmod(0777,$path);
	my $serverfile;
	if(defined($remotepath)){$serverfile="$serverdir/.moirai2remote/".basename($path);}
	my $basename=basename($path,".sh");
	my $stderr=defined($remotepath)?"$serverdir/.moirai2remote/$basename.stderr":"$throwdir/$basename.stderr";
	my $stdout=defined($remotepath)?"$serverdir/.moirai2remote/$basename.stdout":"$throwdir/$basename.stdout";
	print $fh "#!/bin/sh\n";
	my @execids=();
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
			my $cmdpath=which("singularity",$cmdpaths,defined($remotepath)?"$username\@$servername":undef);
			print $fh "cd $rootdir\n";
			#print $fh "cmdpath=`which singularity`\n";
			#print $fh "if [ -z \"\$cmdpath\" ]; then\n";	
			#print $fh "echo \"singualarity command not found\" >> $stderrfile\n";
			#print $fh "echo \"error\t\"`date +\%s` > $statusfile\n";
			#print $fh "touch $stdoutfile\n";
			#print $fh "touch $logfile\n";
			#print $fh "exit\n";
			#print $fh "elif [ ! -e $container ]; then\n";	
			print $fh "if [ ! -e $container ]; then\n";	
			print $fh "echo \"'$container' file doesn't exist\" > $stderrfile\n";
			print $fh "echo \"error\t\"`date +\%s` > $statusfile\n";
			print $fh "touch $stdoutfile\n";
			print $fh "touch $logfile\n";
			print $fh "exit\n";
			print $fh "else\n";
			print $fh "$cmdpath \\\n";
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
			my $cmdpath=which("docker",$cmdpaths,defined($remotepath)?"$username\@$servername":undef);
			print $fh "cd $rootdir\n";
			#print $fh "cmdpath=`which docker`\n";
			#print $fh "if [ -z \"\$cmdpath\" ]; then\n";	
			#print $fh "echo \"singualarity command not found\" > $stderrfile\n";
			#print $fh "echo \"error\t\"`date +\%s` > $statusfile\n";
			#print $fh "touch $stdoutfile\n";
			#print $fh "touch $logfile\n";
			#print $fh "exit\n";
			#print $fh "elif [[ \"\$(docker images -q $container 2> /dev/null)\" == \"\" ]]; then\n";
			print $fh "if [[ \"\$($cmdpath images -q $container 2> /dev/null)\" == \"\" ]]; then\n";
			print $fh "echo \"'$container' docker doesn't exist\" > $stderrfile\n";
			print $fh "echo \"error\t\"`date +\%s` > $statusfile\n";
			print $fh "touch $stdoutfile\n";
			print $fh "touch $logfile\n";
			print $fh "exit\n";
			print $fh "else\n";
			print $fh "$cmdpath \\\n";
			print $fh "  run \\\n";
			print $fh "  --rm \\\n";
			print $fh "  --workdir=/root \\\n";
			print $fh "  -u `id -u`:`id -g` \\\n";
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
		my $workdir=$var->{"base"}->{"workdir"};
		my $logfile="$jobdir/$execid.txt";
		push(@execids,$execid);
		if(defined($remotepath)){
			my $fromDir=$var->{"base"}->{"workdir"};
			my $toDir=$var->{"server"}->{"workdir"};
			rsyncDirectory("$fromDir/","$username\@$servername:$toDir");
		}
	}
	print $fh "if [ -e $stdout ] && [ ! -s $stdout ]; then\n";
	print $fh "rm $stdout\n";
	print $fh "fi\n";
	print $fh "if [ -e $stderr ] && [ ! -s $stderr ]; then\n";
	print $fh "rm $stderr\n";
	print $fh "fi\n";
	if(defined($remotepath)){print $fh "rm $serverfile\n";}
	else{print $fh "rm $path\n";}
	close($fh);
	#Upload input files to the server
	if(defined($remotepath)){
		scpFileIfNecessary($path,"$username\@$servername:$serverfile");
		unlink($path);
		foreach my $var(@variables){uploadInputsByVar($command,$var);}
	}
	#$process is updated when job is thrown
	#Before this, process is empty
	foreach my $execid(@execids){
		my $logfile=Cwd::abs_path("$jobdir/$execid.txt");
		my $processfile="$processdir/$execid.txt";
		system("mv $logfile $processfile");
		writeProcessArray($execid,$urls->{"daemon/execute"}."\tprocessed");
		$processes->{$execid}=loadProcessFile($processfile);
	}
	my $date=getDate("/");
	my $time=getTime(":");
	if(defined($opt_l)){
		my $container=$command->{$urls->{"daemon/container"}};
		print "#Submitting: ".join(",",@execids);
		if(defined($servername)){print " at '$servername' server";}
		if(defined($container)){print " using '$container' container";}
		if(defined($qjob)){print " through '$qjob' system";}
		print "\n";
	}
	if(defined($remotepath)){
		throwBashJob("$username\@$servername:$serverfile",$qjob,$qjobopt,$stdout,$stderr);
	}else{
		throwBashJob($path,$qjob,$qjobopt,$stdout,$stderr);
	}
}
############################## touchFile ##############################
sub touchFile{
	my @files=@_;
	foreach my $file(@files){
		if($file=~/^(.+\@.+)\:(.+)$/){system("ssh $1 'touch $2'");}
		else{system("touch $file");}
	}
}
############################## unusedSubs ##############################
sub unusedSubs{
	my $path="$program_directory/$program_name";
	my $reader=openFile($path);
	my $names={};
	while(<$reader>){
		chomp;s/\r//g;
		if(/^#{30}\s*(\S+)\s*#{30}$/){
			my $name=$1;
			if($name!~/^[A-Z]+$/){last;}
		}
	}
	while(<$reader>){
		chomp;s/\r//g;
		if(/^#{30}\s*(\S+)\s*#{30}$/){$names->{$1}=0;}
	}
	close($reader);
	foreach my $name(keys(%{$names})){
		my $count=`grep '$name(' $path| wc -l`;
		chomp($count);
		$names->{$name}=$count;
	}
	foreach my $name(sort{$names->{$b} <=> $names->{$a}}keys(%{$names})){
		print "$name\t".$names->{$name}."\n";
	}
}
############################## uploadCommand ##############################
sub uploadCommand{
	my $process=shift();
	my $serverpath=shift();
	my ($username,$servername,$serverdir)=splitServerPath($serverpath);
	if(!exists($process->{$urls->{"daemon/command"}})){
		print STDERR "ERROR: Command not specified in job file\n";
		exit(1);
	}
	my $path=$process->{$urls->{"daemon/command"}};
	my $filepath="$username\@$servername:";
	if(defined($serverdir)){$filepath.="$serverdir/$path";}
	else{$filepath.=$path;}
	mkdirs(dirname($path));
	scpFileIfNecessary($path,$filepath);
	return $path;
}
############################## uploadInputs ##############################
sub uploadInputs{
	my $command=shift();
	my $process=shift();
	if(!exists($process->{$urls->{"daemon/serverpath"}})){return;}
	my $serverpath=$process->{$urls->{"daemon/serverpath"}};
	my $url=$process->{$urls->{"daemon/command"}};
	foreach my $input(@{$command->{$urls->{"daemon/input"}}}){
		if(!exists($process->{"$url#$input"})){next;}
		my $inputfile=$process->{"$url#$input"};
		my $fromFile="$rootDir/$inputfile";
		my $toFile="$serverpath/$inputfile";
		scpFileIfNecessary($fromFile,$toFile);
	}
}
############################## uploadInputsByVar ##############################
sub uploadInputsByVar{
	my $command=shift();
	my $var=shift();
	if(!exists($command->{$urls->{"daemon/remotepath"}})){return;}
	my $remotepath=$command->{$urls->{"daemon/remotepath"}};
	my $url=$var->{$urls->{"daemon/command"}};
	my $rootdir=$var->{"base"}->{"rootdir"};
	foreach my $input(@{$command->{$urls->{"daemon/input"}}}){
		if(!exists($var->{$input})){next;}
		my $inputfile=$var->{$input};
		my $fromFile="$rootdir/$inputfile";
		my $toFile="$remotepath/$inputfile";
		scpFileIfNecessary($fromFile,$toFile);
	}
}
############################## uploadOutputs ##############################
sub uploadOutputs{
	my $command=shift();
	my $process=shift();
	if(!exists($process->{$urls->{"daemon/serverpath"}})){return;}
	my $serverpath=$process->{$urls->{"daemon/serverpath"}};
	my $url=$process->{$urls->{"daemon/command"}};
	my $rootdir=$process->{$urls->{"daemon/rootdir"}};
	foreach my $output(@{$command->{$urls->{"daemon/output"}}}){
		if(!exists($process->{"$url#$output"})){next;}
		my $outputfile=$process->{"$url#$output"};
		my $fromfile="$rootdir/$outputfile";
		my $tofile="$serverpath/$outputfile";
		scpFileIfNecessary($fromfile,$tofile);
	}
}
############################## which ##############################
sub which{
	my $cmd=shift();
	my $cmdpaths=shift();
	my $serverpath=shift();
	if(!defined($cmdpaths)){$cmdpaths={};}
	if(exists($cmdpaths->{$cmd})){return $cmdpaths->{$cmd};}
	my $result;
	if(defined($serverpath)){
		open(CMD,"ssh $serverpath \"bash -l -c 'which $cmd 2>&1'\" |");
		while(<CMD>){chomp;if($_=~/$cmd$/){$result=$_;}}
		close(CMD);
		if($result ne ""){$cmdpaths->{$cmd}=$result;}
	}else{
		open(CMD,"which $cmd 2>&1 |");
		while(<CMD>){chomp;if($_=~/$cmd$/){$result=$_;}}
		close(CMD);
		if($result ne ""){$cmdpaths->{$cmd}=$result;}
	}
	return $result;
}
############################## writeFileContent ##############################
sub writeFileContent{
	my @array=@_;
	my $file=shift(@array);
	my ($writer,$tmpfile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt");
	foreach my $line(@array){print $writer "$line\n";}
	close($writer);
	if($file=~/^(.+\@.+)\:(.+)$/){system("scp $tmpfile $1:$2 2>&1 1>/dev/null");}
	else{system("mv $tmpfile $file");}
}
############################## writeJobArray ##############################
sub writeJobArray{
	my @lines=@_;
	my $execid=shift(@lines);
	my $jobfile="$jobdir/$execid.txt";
	open(OUT,">>$jobfile");
	foreach my $element(@lines){print OUT "$element\n";}
	close(OUT);
	return $jobfile;
}
############################## writeJobHash ##############################
sub writeJobHash{
	my @hashs=@_;
	my @execids=();
	foreach my $hash(@hashs){
		my $execid=$hash->{$urls->{"daemon/execid"}};
		my $jobfile="$jobdir/$execid.txt";
		open(OUT,">>$jobfile");
		foreach my $key(sort{$a cmp $b}keys(%{$hash})){
			my $val=$hash->{$key};
			if(ref($val)eq"ARRAY"){foreach my $v(@{$val}){print OUT "$key\t$v\n";}}
			else{print OUT "$key\t$val\n";}
		}
		close(OUT);
		push(@execids,$execid);
	}
	return @execids;
}
############################## writeProcessArray ##############################
sub writeProcessArray{
	my @lines=@_;
	my $execid=shift(@lines);
	my $processfile="$processdir/$execid.txt";
	if(!-e $processfile){
		# 0 process/
		# 1 process/dgt-ac4/
		my @files=listFilesRecursively("$execid\.txt\$",undef,1,$processdir);
		if(scalar(@files)==1){$processfile=$files[0];}
	}
	open(OUT,">>$processfile");
	foreach my $element(@lines){print OUT "$element\n";}
	close(OUT);
	return $processfile;
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
