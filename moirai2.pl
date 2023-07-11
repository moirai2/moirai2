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
my $program_version="2023/07/11";
############################## OPTIONS ##############################
use vars qw($opt_a $opt_A $opt_b $opt_c $opt_C $opt_d $opt_D $opt_e $opt_E $opt_f $opt_F $opt_g $opt_G $opt_h $opt_H $opt_i $opt_I $opt_j $opt_l $opt_L $opt_m $opt_M $opt_n $opt_N $opt_o $opt_O $opt_p $opt_P $opt_q $opt_Q $opt_r $opt_R $opt_s $opt_S $opt_t $opt_u $opt_U $opt_v $opt_V $opt_w $opt_x $opt_X $opt_z $opt_Z);
getopts('a:Ab:c:C:d:D:e:E:f:F:g:G:hHi:I:j:lLm:M:n:N:o:O:pP:q:Q:r:R:s:S:tu:Uv:V:w:xX:zZ:');
############################## HELP ##############################
sub help{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Handles Moirai2 workflow/command using a directed acyclic graph database.\n";
	print "Version: $program_version\n";
	print "Author: Akira Hasegawa (akira.hasegawa\@riken.jp)\n";
	print "\n";
	print "Usage: perl $program_name [Options] COMMAND\n";
	print "\n";
	print "Commands:\n";
	print "        build  Build a command json from command lines and script files\n";
	print "        check  Use ps command to check numbers of moirai2 process running\n";
	print "  clear/clean  Clean command, log, and error from .moirai2 directory\n";
	print "      command  Execute command lines from STDIN\n";
	print "     complete  Run daemon 'complete' mode once with -R 0 option\n";
	print "       daemon  Run moirai2.pl daemon in background to process submitted/crontab jobs\n";
	print "        error  Check error log messages\n";
	print "         exec  Execute command lines from arguments\n";
	print "      history  List up executed commands (needed?)\n";
	print "         html  Output HTML files of command/logs/database\n";
	print "           ls  List files directory\n";
	print "         jobs  List number of jobs remaining and currently running\n";
	print "          log  Print out logs information of processes\n";
	print "    newdaemon  Setup a new daemon specified server\n";
	print "         open  Open .moirai2 directory (for Mac only)\n";
	print "    openstack  Use openstack.pl to create new instance to process jobs\n";
	print "      process  Run Daemon 'process' mode once with -R 0 option\n";
	print "    reprocess  Reprocess/restart jobs that are stopped in the middle (needed?)\n";
	print "     sortsubs  For reorganizing this script(test commands)\n";
	print "       submit  Submit a job file OR submit user command(s), but don't execute\n";
	print "         test  For development purpose (test commands)\n";
	print "         text  Create command line(s) from inputs\n";
	print "   unusedsubs  List up unused perl subs/functions for refactoring\n";
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
		print "2023/07/11  Added increment triple and output/update/increment is used to reduce already dones.\n";
		print "2023/02/18  Fixed small bugs.\n";
		print "2023/02/15  All workdirectory files rsynced to current directory.\n";
		print "2023/02/11  Added -e -u options for deletion and update.\n";
		print "2023/01/27  Fixed small bugs related to remove/server jobs submission.\n";
		print "2023/01/26  Change order of execid to dateid,cmdid,workid,second,etc.\n";
		print "2023/01/20  Fixed small bugs related to daemon job processing.\n";
		print "2023/01/16  Make daemon across SSH work.\n";
		print "2022/11/25  Added machine information to a process directory.\n";
		print "2022/11/02  Fixing minor bugs related to distribution of jobs\n";
		print "2022/09/02  Create daemon at specified server\n";
		print "2022/07/30  Added flag handler where as soon as jobs are created, flags are removed from db\n";
		print "2022/07/24  Added user and group for docker run\n";
		print "2022/07/11  Refactored moirai2.pl and dag.pl\n";
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
		print "2020/12/01  Adapt to new dag.pl which doens't use sqlite3 database.\n";
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
		print "2019/01/17  Subdivide DAG database, revised execute flag to have instance in between.\n";
		print "2018/12/10  Remove unnecessary files when completed.\n";
		print "2018/12/04  Added 'maxjob' and 'nolog' to speed up processed.\n";
		print "2018/11/27  Separating loading, selection, and execution and added 'maxjob'.\n";
		print "2018/11/19  Improving database updates by speed.\n";
		print "2018/11/17  Making daemon faster by collecting individual database accesses.\n";
		print "2018/11/16  Making updating/importing database faster by using improved dag.pl.\n";
		print "2018/11/09  Added import function where user udpate databse through specified file(s).\n";
		print "2018/09/14  Changed to a ticket system.\n";
		print "2018/02/06  Added qsub functionality.\n";
		print "2018/02/01  Created to throw jobs registered in DAG database.\n";
		print "\n";
	}
}
############################## URL ##############################
my $urls={};
$urls->{"daemon"}="https://moirai2.github.io/schema/daemon";
$urls->{"daemon/approximate/time"}="https://moirai2.github.io/schema/daemon/approximate/time";
$urls->{"daemon/bash"}="https://moirai2.github.io/schema/daemon/bash";
$urls->{"daemon/command"}="https://moirai2.github.io/schema/daemon/command";
$urls->{"daemon/command/option"}="https://moirai2.github.io/schema/daemon/command/option";
$urls->{"daemon/container"}="https://moirai2.github.io/schema/daemon/container";
$urls->{"daemon/container/image"}="https://moirai2.github.io/schema/daemon/container/image";
$urls->{"daemon/container/flavor"}="https://moirai2.github.io/schema/daemon/container/flavor";
$urls->{"daemon/dagdb"}="https://moirai2.github.io/schema/daemon/dagdb";
$urls->{"daemon/default"}="https://moirai2.github.io/schema/daemon/default";
$urls->{"daemon/description"}="https://moirai2.github.io/schema/daemon/description";
$urls->{"daemon/delete/inputs"}="https://moirai2.github.io/schema/daemon/delete/inputs";
$urls->{"daemon/donot/delete/results"}="https://moirai2.github.io/schema/daemon/donot/delete/results";
$urls->{"daemon/donot/move/outputs"}="https://moirai2.github.io/schema/daemon/donot/move/outputs";
$urls->{"daemon/donot/update/db"}="https://moirai2.github.io/schema/daemon/donot/update/db";
$urls->{"daemon/downloaded"}="https://moirai2.github.io/schema/daemon/downloaded";
$urls->{"daemon/execid"}="https://moirai2.github.io/schema/daemon/execid";
$urls->{"daemon/execute"}="https://moirai2.github.io/schema/daemon/execute";
$urls->{"daemon/error/file/empty"}="https://moirai2.github.io/schema/daemon/error/file/empty";
$urls->{"daemon/error/stderr/ignore"}="https://moirai2.github.io/schema/daemon/error/stderr/ignore";
$urls->{"daemon/error/stdout/ignore"}="https://moirai2.github.io/schema/daemon/error/stdout/ignore";
$urls->{"daemon/file/md5"}="https://moirai2.github.io/schema/daemon/file/md5";
$urls->{"daemon/upload/jobserver"}="https://moirai2.github.io/schema/daemon/upload/jobserver";
$urls->{"daemon/download/remoteserver"}="https://moirai2.github.io/schema/daemon/download/remoteserver";
$urls->{"daemon/file/filesize"}="https://moirai2.github.io/schema/daemon/file/filesize";
$urls->{"daemon/file/linecount"}="https://moirai2.github.io/schema/daemon/file/linecount";
$urls->{"daemon/file/seqcount"}="https://moirai2.github.io/schema/daemon/file/seqcount";
$urls->{"daemon/file/stats"}="https://moirai2.github.io/schema/daemon/file/stats";
$urls->{"daemon/hostname"}="https://moirai2.github.io/schema/daemon/hostname";
$urls->{"daemon/input"}="https://moirai2.github.io/schema/daemon/input";
$urls->{"daemon/jobserver"}="https://moirai2.github.io/schema/daemon/jobserver";
$urls->{"daemon/localdir"}="https://moirai2.github.io/schema/daemon/localdir"; 
$urls->{"daemon/ls"}="https://moirai2.github.io/schema/daemon/ls";
$urls->{"daemon/maxjob"}="https://moirai2.github.io/schema/daemon/maxjob";
$urls->{"daemon/output"}="https://moirai2.github.io/schema/daemon/output";
$urls->{"daemon/process/lastupdate"}="https://moirai2.github.io/schema/daemon/process/lastupdate";
$urls->{"daemon/process/lastupdate/doublecheck"}="https://moirai2.github.io/schema/daemon/process/lastupdate/doublecheck";
$urls->{"daemon/processid"}="https://moirai2.github.io/schema/daemon/processid";
$urls->{"daemon/processtime"}="https://moirai2.github.io/schema/daemon/processtime";
$urls->{"daemon/qjob"}="https://moirai2.github.io/schema/daemon/qjob";
$urls->{"daemon/qjob/opt"}="https://moirai2.github.io/schema/daemon/qjob/opt";
$urls->{"daemon/queserver"}="https://moirai2.github.io/schema/daemon/queserver";
$urls->{"daemon/query/delete"}="https://moirai2.github.io/schema/daemon/query/delete";
$urls->{"daemon/query/in"}="https://moirai2.github.io/schema/daemon/query/in";
$urls->{"daemon/query/increment"}="https://moirai2.github.io/schema/daemon/query/increment";
$urls->{"daemon/query/not"}="https://moirai2.github.io/schema/daemon/query/not";
$urls->{"daemon/query/out"}="https://moirai2.github.io/schema/daemon/query/out";
$urls->{"daemon/query/update"}="https://moirai2.github.io/schema/daemon/query/update";
$urls->{"daemon/remoteserver"}="https://moirai2.github.io/schema/daemon/remoteserver";
$urls->{"daemon/return"}="https://moirai2.github.io/schema/daemon/return";
$urls->{"daemon/rootdir"}="https://moirai2.github.io/schema/daemon/rootdir";
$urls->{"daemon/script"}="https://moirai2.github.io/schema/daemon/script";
$urls->{"daemon/script/code"}="https://moirai2.github.io/schema/daemon/script/code";
$urls->{"daemon/script/name"}="https://moirai2.github.io/schema/daemon/script/name";
$urls->{"daemon/script/path"}="https://moirai2.github.io/schema/daemon/script/path";
$urls->{"daemon/sleeptime"}="https://moirai2.github.io/schema/daemon/sleeptime";
$urls->{"daemon/suffix"}="https://moirai2.github.io/schema/daemon/suffix";
$urls->{"daemon/timecompleted"}="https://moirai2.github.io/schema/daemon/timecompleted";
$urls->{"daemon/timeended"}="https://moirai2.github.io/schema/daemon/timeended";
$urls->{"daemon/timeregistered"}="https://moirai2.github.io/schema/daemon/timeregistered";
$urls->{"daemon/timestarted"}="https://moirai2.github.io/schema/daemon/timestarted";
$urls->{"daemon/timestamp"}="https://moirai2.github.io/schema/daemon/timestamp";
$urls->{"daemon/unzip"}="https://moirai2.github.io/schema/daemon/unzip";
$urls->{"daemon/uploaded"}="https://moirai2.github.io/schema/daemon/uploaded";
$urls->{"daemon/userdefined"}="https://moirai2.github.io/schema/daemon/userdefined";
$urls->{"daemon/workid"}="https://moirai2.github.io/schema/daemon/workid";
$urls->{"daemon/workdir"}="https://moirai2.github.io/schema/daemon/workdir";
$urls->{"daemon/workflow"}="https://moirai2.github.io/schema/daemon/workflow";
$urls->{"daemon/workflow/urls"}="https://moirai2.github.io/schema/daemon/workflow/urls";
############################## VARIABLES ##############################
my $writeFullLog;#Write full detailed bash and script informations
my $testip="172.18.88.57";# Test server IP
my $testuser="ah3q";# Test server username
my $testserver="$testuser\@$testip";# Test server
my $defaultFlavor="1Core-8GiB-36GiB";#default flavor
my $defaultImage="snapshot-singularity";#default image
my $ignoreTerminateSignal=0;#Ignore program termination
my $averageJobSpan=600;#how much one throw should take per throw
############################## MAIN ##############################
#xxxDir is absoute path, xxxdir is relative path
my $rootDir=absolutePath(".");
my $homeDir=absolutePath(`echo ~`);
my $username=`whoami`;chomp($username);
my $hostname=`hostname`;chomp($hostname);
my $prgmode=shift(@ARGV);
if(defined($opt_q)){if($opt_q eq "qsub"){$opt_q="sge";}elsif($opt_q eq "squeue"){$opt_q="slurm";}}
my $workid=$opt_w;
my $json2workids={};
my $sleeptime=defined($opt_s)?$opt_s:1;
my $maxThread=defined($opt_M)?$opt_M:1;
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
my $incrementdir="$ctrldir/increment";
my $insertdir="$ctrldir/insert";
my $instancedir="$ctrldir/instance";
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
if(defined($dbdir)){mkdir($dbdir);}chmod(0777,$dbdir);
mkdir($bindir);chmod(0777,$bindir);
mkdir($cmddir);chmod(0777,$cmddir);
mkdir($ctrldir);chmod(0777,$ctrldir);
mkdir($configdir);chmod(0777,$configdir);
mkdir($deletedir);chmod(0777,$deletedir);
mkdir($insertdir);chmod(0777,$insertdir);
mkdir($incrementdir);chmod(0777,$incrementdir);
mkdir($instancedir);chmod(0777,$instancedir);
mkdir($jobdir);chmod(0777,$jobdir);
mkdir($processdir);chmod(0777,$processdir);
mkdir($submitdir);chmod(0777,$submitdir);
mkdir($updatedir);chmod(0777,$updatedir);
mkdir($logdir);chmod(0777,$logdir);
mkdir($errordir);chmod(0777,$errordir);
mkdir($throwdir);chmod(0777,$throwdir);
if(defined($workid)){$jobdir.="/$workid";mkdir($jobdir);chmod(0777,$jobdir);}
#reassign
my $sdtoutfh;
my $sdterrfh;
if(defined($opt_L)){assignStdoutStderrToFile($logdir,$prgmode,@ARGV);}
#make sure server paths are correct
# (-j) laptop =queserver=> lsbdt01
# (-j)                     lsbdt01 <=jobserver= moirainodes
# (-a)                     lsbdt01 =remoteserver=> moirainodes
my $remoteServer;
if(defined($opt_a)){$remoteServer=handleServer($opt_a);}
my $jobServer;
if(defined($opt_j)){$jobServer=handleServer($opt_j);}
my $processid;
##### handle commands #####
if(defined($opt_h)){helpMenu($prgmode);}
elsif($prgmode=~/^check$/i){checkMoirai2Status(@ARGV);}
elsif($prgmode=~/^(clean|clear)$/i){cleanMoiraiFiles(@ARGV);}
elsif($prgmode=~/^complete$/i){$processid=assignProcessId($prgmode);if(!defined($opt_R)){$opt_R=0;}runDaemon("complete");}
elsif($prgmode=~/^daemon$/i){$processid=assignProcessId($prgmode);runDaemon(@ARGV);}
elsif($prgmode=~/^error$/i){checkError(@ARGV);}
elsif($prgmode=~/^history$/i){historyCommand(@ARGV);}
elsif($prgmode=~/^html$/i){createHtml(@ARGV);}
elsif($prgmode=~/^jobs$/i){jobsCommand(@ARGV);}
elsif($prgmode=~/^log$/i){logCommand(@ARGV);}
elsif($prgmode=~/^ls$/i){lsCommand(@ARGV);}
elsif($prgmode=~/^open$/i){openCommand(@ARGV);}
elsif($prgmode=~/^openstack$/i){openstackCommand(@ARGV);}
elsif($prgmode=~/^process$/i){$processid=assignProcessId($prgmode);if(!defined($opt_R)){$opt_R=0;}runDaemon("process");}
elsif($prgmode=~/^retrieve$/i){$processid=assignProcessId($prgmode);if(!defined($opt_R)){$opt_R=0;}runDaemon("retrieve");}
elsif($prgmode=~/^sortsubs$/i){sortSubs(@ARGV);}
elsif($prgmode=~/^test$/i){test(@ARGV);}
elsif($prgmode=~/^unusedsubs$/i){unusedSubs(@ARGV);}
else{$processid=assignProcessId($prgmode);moiraiMain($prgmode);}
if(defined($opt_Z)){touchFile($opt_Z);}
terminate(0);
############################## absolutePath ##############################
sub absolutePath{
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
	if(!exists($command->{$urls->{"daemon/input"}})){return;}
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my $keys={};
	foreach my $key(@{$queryResults->[0]}){$keys->{$key}++;}
	foreach my $input(@inputs){
		if(exists($userdefined->{$input})){next;}
		if(exists($keys->{$input})){$userdefined->{$input}="\$$input";next;}
		if(defined($opt_U)){promptCommandInput($command,$userdefined,$input);}
		elsif(exists($command->{$urls->{"daemon/default"}}->{$input})){$userdefined->{$input}=$command->{$urls->{"daemon/default"}}->{$input};}
	}
}
############################## assignExecid ##############################
# 202301262107420000_d16ee129cc8039c9a6d7aac578697112323_local_1_js_rs_st
sub assignExecid{
	my $command=shift();
	my $datetime=shift();
	my $count=shift();
	my $cmdid;
	if(exists($command->{$urls->{"daemon/command"}})){
		my $path=$command->{$urls->{"daemon/command"}};
		if($path=~/\.json$/){$cmdid=basename($path,".json");}
	}else{$cmdid="notjson";}
	if(!defined($datetime)){$datetime=getDatetime();}
	if(!defined($count)){$count=0;}
	my $workid;
	if(exists($command->{$urls->{"daemon/workid"}})){$workid=$command->{$urls->{"daemon/workid"}};}
	if(!defined($workid)){
		if(defined($jobServer)){$workid="server";}#server process
		elsif(defined($remoteServer)){$workid="remote";}#remote process
		else{$workid="local";}#local process
	}
	my $appTime=1;
	if(exists($command->{$urls->{"daemon/approximate/time"}})){$appTime=$command->{$urls->{"daemon/approximate/time"}};}
	my $execid=sprintf("${datetime}%04x",$count)."_${cmdid}_${workid}_${appTime}";
	if(exists($command->{$urls->{"daemon/jobserver"}})){$execid.="_js";}
	if(exists($command->{$urls->{"daemon/queserver"}})){$execid.="_qs";}
	if(exists($command->{$urls->{"daemon/remoteserver"}})){$execid.="_rs";}
	return $execid;
}
############################## assignProcessId ##############################
sub assignProcessId{
	my $datetime=getDatetime();
	my $processid;
	my $directory;
	do{
		$processid="${hostname}_$datetime";
		$directory="$processdir/$processid";
		$datetime++;
	}while(fileExists($directory));
	createDirs($directory);
	createDirs("$throwdir/$processid");
	return $processid;
}
############################## assignStdoutStderrToFile ##############################
# https://stackoverflow.com/questions/3822787/how-can-i-redirect-stdout-and-stderr-to-a-log-file-in-perl
sub assignStdoutStderrToFile{
	my @arguments=@_;
	my $logdir=shift(@arguments);
	my $prgmode=shift(@arguments);
	if($prgmode!~/daemon/i){
		print STDERR "ERROR: Command option '-L' can be used for daemon mode only\n";
		terminate(1);
	}
	*OLD_STDOUT=*STDOUT;
    *OLD_STDERR=*STDERR;
	my $datetime=getDatetime();
	my $basename="${prgmode}_".join("_",@arguments);
	if(defined($workid)){$basename.="_$workid";}
	$basename.="_${datetime}";
	mkdirs("$logdir/daemon/");
	open $sdtoutfh,'>>',"$logdir/daemon/$basename.stdout";
	open $sdterrfh,'>>',"$logdir/daemon/$basename.stderr";
	*STDOUT=$sdtoutfh;
	*STDERR=$sdterrfh;
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
	$hash->{"directory"}=$directory;
	$hash->{"basename"}=$basename;
	$hash->{"filename"}=$filename;
	$hash->{"filepath"}=$path;
	if(defined($suffix)){$hash->{"suffix"}=$suffix;}
	my @dirs=split(/\//,$directory);
	if($dirs[0] eq""){shift(@dirs);}
	for(my $i=0;$i<scalar(@dirs);$i++){$hash->{"dir$i"}=$dirs[$i];}
	my @bases=split(/$delim/,$basename);
	for(my $i=0;$i<scalar(@bases);$i++){$hash->{"base$i"}=$bases[$i];}
	my @suffixs=split(/\./,$suffix);
	for(my $i=0;$i<scalar(@suffixs);$i++){$hash->{"suffix$i"}=$suffixs[$i];}
	return $hash;
}
############################## bashCommand ##############################
sub bashCommand{
	my $command=shift();
	my $vars=shift();
	my $execid=$vars->{"execid"};
	my $url=$command->{$urls->{"daemon/command"}};
	my $suffixs=exists($command->{$urls->{"daemon/suffix"}})?$command->{$urls->{"daemon/suffix"}}:{};
	my $options=exists($command->{$urls->{"daemon/command/option"}})?$command->{$urls->{"daemon/command/option"}}:undef;
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
	my $container=exists($command->{$urls->{"daemon/container"}})?$command->{$urls->{"daemon/container"}}:undef;
	open(OUT,">$bashsrc");
	print OUT "#!/bin/bash\n";
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
			if($value eq""){next;}
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
			if(ref($output)eq"ARRAY"){
				#ARRAY(0x56448a901718)=$tmpdir/ARRAY(0x56448a901718)
				#ARRAY(0x56448a9fb430)=$tmpdir/ARRAY(0x56448a9fb430)
				#ARRAY(0x56448a928920)=$tmpdir/ARRAY(0x56448a928920)
				#There are cases when variable is an array.
				#I don't know the reason yet, but it happens sometimes.
				print STDERR "#ERROR Output variable specification is an ARRAY\n";
				printTable($output);
			}
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
			print OUT "mkdir -p `dirname \$workdir/$value`\n";
			print OUT "mv \$$output \$workdir/$value\n";
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
	if(scalar(@outputvars)>0){
		foreach my $output(@outputvars){
			print OUT "if [[ \"\$(declare -p $output)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$output"."[\@]} ; do\n";
			print OUT "record \"\$cmdurl#$output\" \"\$out\"\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "record \"\$cmdurl#$output\" \"\$$output\"\n";
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
	print OUT "touch \$workdir/status.txt\n";
	close(OUT);
	if(checkBashScript($bashsrc)!=0){
		print STDERR "There is an error in a bash script\n";
		terminate(1);
	}
}
############################## bashCommandHasOptions ##############################
sub bashCommandHasOptions{
	my $command=shift();
	if(exists($command->{$urls->{"daemon/container"}})){return 1;}
	elsif(scalar(@{$command->{$urls->{"daemon/input"}}}>0)){return 1;}
	elsif(scalar(@{$command->{$urls->{"daemon/output"}}}>0)){return 1;}
	elsif(exists($command->{$urls->{"daemon/query/delete"}})){return 1;}
	elsif(exists($command->{$urls->{"daemon/query/increment"}})){return 1;}
	elsif(exists($command->{$urls->{"daemon/query/in"}})){return 1;}
	elsif(exists($command->{$urls->{"daemon/query/not"}})){return 1;}
	elsif(exists($command->{$urls->{"daemon/query/out"}})){return 1;}
	elsif(exists($command->{$urls->{"daemon/query/update"}})){return 1;}
}
############################## calculateProcessTime ##############################
sub calculateProcessTime{
	my $log=shift();
	my $statusfile=shift();
	my $timestarted;
	my $timeended;
	my $reader=openFile($statusfile);
	while(<$reader>){
		chomp;my ($key,$time)=split(/\t/);
		if($key eq "start"){$log->{$urls->{"daemon/timestarted"}}=$time;$timestarted=$time;}
		elsif($key eq "end"){$log->{$urls->{"daemon/timeended"}}=$time;$timeended=$time;}
		elsif($key eq "completed"){$log->{$urls->{"daemon/timecompleted"}}=$time;$log->{$urls->{"daemon/execute"}}="completed";}
		elsif($key eq "error"){$log->{$urls->{"daemon/timecompleted"}}=$time;$log->{$urls->{"daemon/execute"}}="error";}
	}
	close($reader);
	$log->{$urls->{"daemon/processtime"}}=$timeended-$timestarted;
	return $log;
}
############################## checkBashScript ##############################
sub checkBashScript{
	my $path=shift();
	#https://qiita.com/_ydah/items/effeed302800e586d7b5
	#https://stackoverflow.com/questions/7080434/getting-perl-to-return-the-correct-exit-code
	my $exitCode=system("bash -n $path");
	chomp($exitCode);
	return $exitCode;
}
############################## checkDatabaseDirectory ##############################
sub checkDatabaseDirectory{
	my $directory=shift();
	if($directory=~/\.\./){
		print STDERR "ERROR: Please don't use '..' for moirai database directory\n";
		terminate(1);
	}elsif($directory=~/^\//){
		print STDERR "ERROR: moirai directory '$directory' have to be relative to current directory\n";
		terminate(1);
	}
	my $absolutePath=Cwd::abs_path($directory);
	if(isHomeDirectory($absolutePath)){
		print STDERR "ERROR: Deploying moirai2 DAG database on a home directory is not recommended\n";
		print STDERR "       Please create a directory and deploy moirai2 system there\n";
		terminate(1);
	}
	return $directory;
}
############################## checkError ##############################
sub checkError{
	my $history=getHistory($errordir);
	my $index=1;
	my @execids=sort{$a cmp $b}keys(%{$history});
	if(scalar(@execids)==0){terminate(1);}
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
sub checkFileIsEmpty{
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
			foreach my $token(@tokens){if($token eq""){$empty=1;last;}}
			if($empty==1){
				print STDERR "ERROR: '$query' has empty token.\n";
				print STDERR "ERROR: Use single quote '\$a->b->\$c' instead of double quote \"\$a->b->\$c\".\n";
				print STDERR "ERROR: Or escape '\$' with '\\' sign \"\\\$a->b->\\\$c\".\n";
				terminate(1);
			}
		}
	}
	return $triple;
}
############################## checkMoirai2Status ##############################
sub checkMoirai2Status{
	my @args=@_;
	my $mode=shift(@args);
	if(!defined($mode)){$mode="daemon";}
	if($mode eq "daemon"){
		my @lines=`ps -fu $username`;
		my $found=0;
		foreach my $line(@lines){
			if($line=~/moirai2.pl.*\scheck\s/){}
			elsif($line=~/moirai2.pl.*\sdaemon\s/){$found++;}
		}
		if($found>0){print "$found\n";}
	}elsif($mode eq "status"){
		if(scalar(@args)>1){
			foreach my $id(@args){
				my $status=retrieveStatusOfProcess($id);
				print "$id\t$status\n";
			}
		}elsif(scalar(@args)==1){
			my $id=$args[0];
			my $status=retrieveStatusOfProcess($id);
			print "$status\n";
		}
	}
}
############################## checkNotConditions ##############################
sub checkNotConditions{
	my $inputs=shift();
	my $command=shift();
	if(!exists($command->{$urls->{"daemon/query/not"}})){return;}
	my $dagdb=$command->{$urls->{"daemon/dagdb"}};
	my $query=$command->{$urls->{"daemon/query/not"}};
	my $outputs=getQueryResults($dagdb,$query);
	my $inputTemp={};
	foreach my $input(@{$inputs->[0]}){$inputTemp->{$input}=1;}
	my $commonTemp={};
	if(scalar(@{$outputs->[1]})==0){return;}
	foreach my $output(@{$outputs->[0]}){if(exists($inputTemp->{$output})){$commonTemp->{$output}=1;}}
	my @commonKeys=keys(%{$commonTemp});
	if(scalar(@commonKeys)==0){return;}
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
############################## checkProcessIsCompleted ##############################
sub checkProcessIsCompleted{
	my $processes=shift();
	my $commands=shift();
	my $completed=0;
	if(!defined($processes)){return $completed;}
	foreach my $execid(keys(%{$processes})){
		my $process=$processes->{$execid};
		my $status=checkStatusOfProcess($process);
		if(!defined($status)){next;}
		if($status eq "completed"||$status eq "error"){
			my $url=$process->{$urls->{"daemon/command"}};
			my $command=loadCommandFromURL($url,$commands);
			handleCompletedQueServer($command,$process);
			handleCompletedProcess($command,$process,$status);
			if($prgmode=~/^daemon$/){
				#daemon's repeat limit is used to test functionality.
				#Very special case.
				if(!defined($opt_R)){delete($processes->{$execid});}
			}
			$completed++;
		}else{writeProcessArray($process,$urls->{"daemon/execute"}."\t$status");}
	}
	return $completed;
}
############################## checkStatusOfProcess ##############################
sub checkStatusOfProcess{
	my $process=shift();
	if(exists($process->{$urls->{"daemon/queserver"}})){
		my $queserver=$process->{$urls->{"daemon/queserver"}};
		my $execid=$process->{$urls->{"daemon/execid"}};
		my ($username,$servername,$serverdir)=splitServerPath($queserver);
		my $status=`ssh $username\@$servername 'cd $serverdir;perl moirai2.pl check status $execid'`;
		chomp($status);
		return $status;
	}
	my $lastUpdate=$process->{$urls->{"daemon/process/lastupdate"}};
	my $workdir=$process->{$urls->{"daemon/workdir"}};
	my $statusfile="$workdir/status.txt";
	my $timestamp=checkTimestamp($statusfile);
	if(!defined($timestamp)){return;}
	if(!defined($lastUpdate)||$lastUpdate eq ""||$timestamp>$lastUpdate){
		my $status=checkStatusOfProcessSub($process,$statusfile,$timestamp);
		if($status ne "completed"&&$status ne "error"){
			$process->{$urls->{"daemon/process/lastupdate/doublecheck"}}=1;
		}
		return $status;
	}elsif(exists($process->{$urls->{"daemon/process/lastupdate/doublecheck"}})){
		if($sleeptime==0){sleep(1);}
		my $status=checkStatusOfProcessSub($process,$statusfile,$timestamp);
		if(!defined($status)){delete($process->{$urls->{"daemon/process/lastupdate/doublecheck"}});}
		return $status;
	}else{
		return;
	}
}
#Return status if changed
#Return undef if no change
sub checkStatusOfProcessSub{
	my $process=shift();
	my $statusfile=shift();
	my $timestamp=shift();
	my $reader=openFile($statusfile);
	my $currentStatus;
	while(<$reader>){
		chomp;
		my ($key,$val)=split(/\t/);
		$currentStatus=$key;
	}
	close($reader);
	if(!defined($currentStatus)){return;}
	$process->{$urls->{"daemon/process/lastupdate"}}=$timestamp;
	$process->{$urls->{"daemon/execute"}}=$currentStatus;
	if($currentStatus eq "completed"||$currentStatus eq "error"){return $currentStatus;}
	my $lastStatus=$process->{$urls->{"daemon/execute"}};
	if(ref($lastStatus)eq"ARRAY"){$lastStatus=$lastStatus->[scalar(@{$lastStatus})-1];}
	if($currentStatus eq $lastStatus){return;}
	else{return $currentStatus;}
}
############################## checkTimestamp ##############################
# When a directory is created, directory timestamp is updated
# When new file is created under a directory, directory timestamp is updated
# Directory timestamp is not renewed, even if existing file is updated
# When file is deleted, directory timestamp is updated
sub checkTimestamp{
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){
		my $stat=`ssh $1 'perl -e \"if(-e \\\$ARGV[0]){my \@array=stat(\\\$ARGV[0]);print \\\$array[9];}else{print 0;}\" $2'`;
		if($stat eq""){return;}
		return $stat;
	}else{
		my @stats=stat($path);
		return $stats[9];
	}
}
############################## checkTimestampsOfOutputs ##############################
sub checkTimestampsOfOutputs{
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
############################## checkUrlExists ##############################
# https://ameblo.jp/pclindesk/entry-10192327404.html
sub checkUrlExists{
	my $url=shift();
	my $command="wget -q --spider $url";
	my $result=system($command);
	chomp($result);
	return $result;
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
############################## constructTripleFromVariables ##############################
sub constructTripleFromVariables{
	my $dagdb=shift();
	my $insert=shift();
	my $variables=shift();
	my @lines=();
	if($insert=~/^(.+)\-\>(.+)\-\>(.+)$/){$insert="$1\t$dagdb$2\t$3";}
	foreach my $variable(@{$variables}){
		my $line=$insert;
		my @keys=sort{$a cmp $b}(%{$variable});
		foreach my $key(@keys){
			my $val=$variable->{$key};
			$line=~s/\$\{$key\}/$val/g;
			$line=~s/\$$key/$val/g;
		}
		push(@lines,$line);
	}
	return @lines;
}
############################## controlDelete ##############################
sub controlDelete{
	my @files=getFiles($deletedir);
	if(scalar(@files)==0){return 0;}
	while(startLockfile("$deletedir.lock")){if(defined($opt_l)){print getLogtime()."|Waiting for insert slot to open up again\n"}}
	my $command="cat ".join(" ",@files)."|perl $program_directory/dag.pl -f tsv delete";
	my $count=`$command`;
	endLockfile("$deletedir.lock");
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlIncrement ##############################
sub controlIncrement{
	my @files=getFiles($incrementdir);
	if(scalar(@files)==0){return 0;}
	while(startLockfile("$incrementdir.lock")){if(defined($opt_l)){print getLogtime()."|Waiting for insert slot to open up again\n"}}
	my $command="cat ".join(" ",@files)."|perl $program_directory/dag.pl -f tsv increment";
	my $count=`$command`;
	endLockfile("$incrementdir.lock");
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlInsert ##############################
sub controlInsert{
	my @files=getFiles($insertdir);
	if(scalar(@files)==0){return 0;}
	while(startLockfile("$insertdir.lock")){if(defined($opt_l)){print getLogtime()."|Waiting for insert slot to open up again\n"}}
	my $command="cat ".join(" ",@files)."|perl $program_directory/dag.pl -f tsv insert";
	my $count=`$command`;
	endLockfile("$insertdir.lock");
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlUpdate ##############################
sub controlUpdate{
	my @files=getFiles($updatedir);
	if(scalar(@files)==0){return 0;}
	while(startLockfile("$updatedir.lock")){if(defined($opt_l)){print getLogtime()."|Waiting for insert slot to open up again\n"}}
	my $command="cat ".join(" ",@files)."|perl $program_directory/dag.pl -f tsv update";
	my $count=`$command`;
	endLockfile("$updatedir.lock");
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlWorkflow ##############################
sub controlWorkflow{
	my $processes=shift();
	my $commands=shift();
	my $nosync=shift();
	my $completed=0;
	if(defined($processes)&&defined($commands)){
		$completed=checkProcessIsCompleted($processes,$commands);
		if($completed==0){return;}
	}
	my $inserted=controlInsert();
	my $deleted=controlDelete();
	my $updated=controlUpdate();
	my $incremented=controlIncrement();
	if(!defined($opt_l)){return;}
	if($completed>0){print getLogtime()."|Completed $completed job\n";}
	if($inserted>0){print getLogtime()."|Inserted $inserted triple\n";}
	if($deleted>0){print getLogtime()."|Deleted $deleted triple\n";}
	if($updated>0){print getLogtime()."|Updated $updated triple\n";}
	if($incremented>0){print getLogtime()."|Incremented $incremented triple\n";}
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
############################## copyProcessToQueServer ##############################
sub copyProcessToQueServer{
	my @execids=@_;
	my $serverpath=shift(@execids);
	my $remotepath=shift(@execids);
	my $commands=shift(@execids);
	my ($username,$servername,$serverdir)=splitServerPath($serverpath);
	my $processes={};
	my $queUrl=$urls->{"daemon/queserver"};
	foreach my $execid(@execids){
		my $workdir="$moiraidir/$execid";
		my $jobfile="$jobdir/$execid.txt";
		my $processfile="$processdir/$processid/$execid.txt";
		if(system("mv $jobfile $processfile")){next;}#failed to move means someone took it
		if(!-e $processfile){next;}
		my $serverjobdir="$serverpath/.moirai2/ctrl/job";
		createDirs($serverjobdir);
		if(defined($workid)){$serverjobdir.="/$workid";}
		my $serverfile="$serverjobdir/$execid.txt";
		my $process=loadProcessFile($processfile);
		$processes->{$execid}=$process;
		my $serverProcess=loadProcessFile($processfile);
		my $url=$process->{$urls->{"daemon/command"}};
		my $command=loadCommandFromURL($url,$commands);
		uploadCommandToQueServer($process,$serverpath);
		uploadInputsToQueServer($command,$serverProcess,$workdir,$serverpath);
		if(exists($serverProcess->{$urls->{"daemon/queserver"}})){delete($serverProcess->{$urls->{"daemon/queserver"}});}
		$serverProcess->{$urls->{"daemon/delete/inputs"}}="true";
		$serverProcess->{$urls->{"daemon/donot/delete/results"}}="true";
		$serverProcess->{$urls->{"daemon/donot/update/db"}}="true";
		$process->{$urls->{"daemon/workdir"}}="$serverpath/.moirai2/$execid";
		$process->{$urls->{"daemon/processid"}}="$processid";
		my $datetime=`date +%s`;chomp($datetime);
		$process->{$urls->{"daemon/timeregistered"}}=$datetime;
		my $localtmp=writeProcessToTmp($process);
		my $servertmp=writeProcessToTmp($serverProcess);
		system("mv $localtmp $processfile");
		rsyncFileByUpdate($servertmp,$serverfile);
		unlink($servertmp);
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
		foreach my $url(@arguments){
			my $command=loadCommandFromURL($url,$commands);
			push(@lines,createHtmlCommand($command));
		}
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
	}elsif($menu=~/^schema$/i){
		my $schemaFile=shift(@arguments);
		my $schema=loadSchema($schemaFile);
		my $basename=basename($schemaFile,".schema");
		createHtmlSchema($schema,"$basename.html");
	}
}
############################## createHtmlCommand ##############################
sub createHtmlCommand{
	my $command=shift();
	my $url=shift();
	my @lines=();
	my $suffixs=exists($command->{$urls->{"daemon/suffix"}})?$command->{$urls->{"daemon/suffix"}}:{};
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
############################## createHtmlDatabase ##############################
sub createHtmlDatabase{
	print "<html>\n";
	print "<head>\n";
	print "<title>moirai</title>\n";
	print "<script type=\"text/javascript\" src=\"js/vis/vis-network.min.js\"></script>\n";
	print "<script type=\"text/javascript\" src=\"js/jquery/jquery-3.4.1.min.js\"></script>\n";
	print "<script type=\"text/javascript\" src=\"js/jquery/jquery.columns.min.js\"></script>\n";
	print "<script type=\"text/javascript\">\n";
	#my $network=`perl $program_directory/dag.pl -d $dbdir export network`;
	#chomp($network);
	my $db=`perl $program_directory/dag.pl export db`;
	chomp($db);
	my $log=`perl $program_directory/dag.pl export log`;
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
############################## createHtmlForm ##############################
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
############################## createHtmlFunction ##############################
sub createHtmlFunction{
	my $command=shift();
	my @lines=();
	my $url=$command->{$urls->{"daemon/command"}};
	my $suffixs=exists($command->{$urls->{"daemon/suffix"}})?$command->{$urls->{"daemon/suffix"}}:{};
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
			if(exists($suffixs->{$in})){push(@lines,"{\"header\": \"$in\", \"key\": \"$in\", \"template\": '<a href=\"{{$in}}\">{{$in}}</a>'},");}
			else{push(@lines,"{\"header\": \"$in\", \"key\": \"$in\"},");}
		}
	}
	if(exists($command->{$urls->{"daemon/output"}})){
		my $output=$command->{$urls->{"daemon/output"}};
		foreach my $out(@{$output}){
			if(exists($suffixs->{$out})){push(@lines,"{\"header\": \"$out\", \"key\": \"$out\", \"template\": '<a href=\"{{$out}}\">{{$out}}</a>'},");}
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
############################## createHtmlSchema ##############################
sub createHtmlSchema{
	my $hashtable=shift();
	my $outfile=shift();
	my ($writer,$file)=tempfile(UNLINK=>1);
	print $writer "<html>\n";
	print $writer "<head>\n";
	print $writer "<title>cytoscape-cola.js demo</title>\n";
	print $writer "<meta name=\"viewport\" content=\"width=device-width, user-scalable=no, initial-scale=1, maximum-scale=1\">\n";
	print $writer "<script src=\"js/cytoscape/cytoscape.min.js\"></script>\n";
	print $writer "<script src=\"js/cytoscape/cola.min.js\"></script>\n";
	print $writer "<script src=\"js/cytoscape/cytoscape-cola.js\"></script>\n";
	print $writer "<style>\n";
	print $writer "body{font-family:helvetica;font-size:14px;}\n";
	print $writer "h1{opacity:0.5;font-size:1em;}\n";
	print $writer "#cy{width:100%;height:100%;position:absolute;left:0;top:0;z-index:999;}\n";
	print $writer "</style>\n";
	print $writer "<script>\n";
	print $writer "document.addEventListener('DOMContentLoaded',function(){\n";
	print $writer "cy=window.cy=cytoscape({\n";
	print $writer "container:document.getElementById('cy'),\n";
	print $writer "autounselectify:true,\n";
	print $writer "boxSelectionEnabled:false,\n";
	print $writer "layout:{name:'cola'},\n";
	print $writer "style:[\n";
	print $writer "{selector:'node',\n";
	print $writer "css:{'background-color':'#f92411'},\n";
	print $writer "style:{'label':'data(label)'}\n";
	print $writer "},{\n";
	print $writer "selector:'edge',\n";
	print $writer "css:{'line-color':'#f92411'}\n";
	print $writer "}],\n";
	print $writer "elements:\n";
	print $writer jsonEncode($hashtable)."\n";
	print $writer "});});\n";
	print $writer "</script>\n";
	print $writer "</head>\n";
	print $writer "<body id=\"main\">\n";
	print $writer "<h1>Workflow Browser</h1>\n";
	print $writer "<div id=\"cy\"></div>\n";
	print $writer "</body>\n";
	print $writer "</html>\n";
	close($writer);
	system("mv $file $outfile");
}
############################## createNewCommandFromLines ##############################
sub createNewCommandFromLines{
	my @cmdlines=@_;
	my $command={};
	$command->{$urls->{"daemon/bash"}}=\@cmdlines;
	return $command;
}
############################## createNewInstances ##############################
sub createNewInstances{
	my $flavor=shift();
	my $count=shift();
	my $max=shift();
	for(my $i=$count+1;$i<=$max;$i++){
		if(defined($opt_l)){print getLogtime()."|Creating a new '$flavor' instance with openstack.pl ($i/$max)\n";}
		my $cmdline="openstack.pl -f $flavor -i snapshot-singularity add node";
		if(defined($opt_l)){print getLogtime()."|$cmdline\n";}
		my @ips=`$cmdline`;
		my $ip=pop(@ips);chomp($ip);
		if($ip!~/^\d+\.\d+\.\d+\.\d+$/){
			print STDERR "#ERROR: IP returned from creating new instance is not an IP: '$ip'\n";
			terminate(1);
		}
		my $startFile="$instancedir/${ip}_${flavor}.start";
		my $stopFile="$instancedir/${ip}_${flavor}.stop";
		$cmdline="ssh $username\@$ip 'cd $rootDir;nohup perl moirai2.pl -l -L -M 1 -w $flavor -Z $stopFile";
		my @modes=("process","terminate");
		if(defined($jobServer)){$cmdline.=" -j $jobServer";push(@modes,"retrieve");}
		$cmdline.=" daemon ".join(" ",@modes)." > /dev/null 2>&1 &'";
		if(defined($opt_l)){print getLogtime()."|$cmdline\n";}
		if(system($cmdline)!=0){print STDERR "#ERROR: Failed to start daemon for $flavor\n";return;}
		my ($tmpwriter,$tmpfile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
		print $tmpwriter "$ip\n";
		print $tmpwriter "$flavor\n";
		close($tmpwriter);
		system("mv $tmpfile $startFile");
	}
}
############################## daemonCheckNotTimestamp ##############################
sub daemonCheckNotTimestamp{
	my $currentTime=time();
	my $command=shift();
	if(!exists($command->{$urls->{"daemon/query/not"}})){return;}
	my $hit=0;
	my $queries=$command->{$urls->{"daemon/query/not"}};
	my $dagdb=$command->{$urls->{"daemon/dagdb"}};
	my $time1=$command->{$urls->{"daemon/timestamp"}};
	foreach my $query(@{$queries}){
		my @tokens=split(/\-\>/,$query);
		my $predicate=$tokens[1];
		my $time2=`perl $program_directory/dag.pl -d $dagdb timestamp '$predicate'`;
		chomp($time2);
		if($time2 eq""){#file doesn't exist
			if(exists($command->{$urls->{"daemon/notstamp"}})&&exists($command->{$urls->{"daemon/notstamp"}}->{$predicate})){
				delete($command->{$urls->{"daemon/notstamp"}}->{$predicate});
				$hit=1;
				last;
			}	
		}else{#file exists
			if(!exists($command->{$urls->{"daemon/notstamp"}})){$command->{$urls->{"daemon/notstamp"}}={};}
			$command->{$urls->{"daemon/notstamp"}}->{$predicate}=$currentTime;
			if($time1<$time2){$hit=1;last;}
		}
	}
	if($hit){$command->{$urls->{"daemon/timestamp"}}=$currentTime;}
	return $hit;
}
############################## daemonCheckTimestamp ##############################
sub daemonCheckTimestamp{
	my $currentTime=time();
	my $command=shift();
	#First time, so run it anyway
	if(!exists($command->{$urls->{"daemon/timestamp"}})){$command->{$urls->{"daemon/timestamp"}}=$currentTime;return 1;}
	#For second time on, check if files are updated or not
	my $cmdurl=$command->{$urls->{"daemon/command"}};
	if(daemonCheckNotTimestamp($command)){$command->{$urls->{"daemon/timestamp"}}=$currentTime;return 1;}
	my $queries=$command->{$urls->{"daemon/query/in"}};
	if(!defined($queries)){return 1;}
	my $dagdb=$command->{$urls->{"daemon/dagdb"}};
	my $time1=$command->{$urls->{"daemon/timestamp"}};
	my $hit=0;
	foreach my $query(@{$queries}){
		my @tokens=split(/\-\>/,$query);
		my $predicate=$tokens[1];
		my $time2=`perl $program_directory/dag.pl -d $dagdb timestamp '$predicate'`;
		chomp($time2);
		if($time2 eq""){next;}
		if($time1<$time2){$hit=1;last;}
	}
	if($hit){$command->{$urls->{"daemon/timestamp"}}=$currentTime;}
	return $hit;
}
############################## deleteInputsFromServer ##############################
sub deleteInputsFromServer{
	my $command=shift();
	my $process=shift();
	my $process2=shift();
	if(exists($process->{$urls->{"daemon/downloaded"}})){
		my $downloads=$process->{$urls->{"daemon/downloaded"}};
		foreach my $downloaded(ref($downloads)eq"ARRAY"?@{$downloads}:($downloads)){
			if(defined($opt_l)){print getLogtime()."|Deleting $downloaded\n";}
			removeFiles($downloaded);
		}
	}
	if(exists($process->{$urls->{"daemon/uploaded"}})){
		my $uploads=$process->{$urls->{"daemon/uploaded"}};
		foreach my $uploaded(ref($uploads)eq"ARRAY"?@{$uploads}:($uploads)){
			if(defined($opt_l)){print getLogtime()."|Deleting $uploaded\n";}
			removeFiles($uploaded);
		}
	}
}
############################## dirExists ##############################
sub dirExists{
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){my $result=`ssh $1 'if [ -d $2 ]; then echo 1; fi'`;chomp($result);return ($result==1);}
	elsif(-d $path){return 1;}
	return;
}
############################## distributeResources ##############################
#Try to finish small jobs first and then do the time consuming ones later
sub distributeResources{
	my $openstackFlavors=shift();
	my $distributions={};
	my $total=0;
	foreach my $key(keys(%{$openstackFlavors})){
		my $second=$openstackFlavors->{$key};
		if($second==0){next;}
		$distributions->{$key}=$second;
		$total+=$second;
	}
	if(scalar(keys(%{$distributions}))==0){return $distributions;}
	my $maxResource=$maxThread;
	my @keys=sort{$distributions->{$a}<=>$distributions->{$b}}keys(%{$distributions});
	my $size=scalar(@keys);
	for(my $i=0;$i<$size-1;$i++){
		my $key=$keys[$i];
		my $value=$distributions->{$key};
		$value=int($value/$total*$maxThread);
		if($value==0){$value=1;}
		$distributions->{$key}=$value;
		$maxResource=$maxResource-$value;
		if($maxResource==0){last;}
	}
	if($maxResource>0){$distributions->{$keys[$size-1]}=$maxResource;}
	if(defined($opt_l)){
		my $logtime=getLogtime();
		my @outputs=();
		foreach my $wid(sort{$a cmp $b}keys(%{$distributions})){
			my $count=$distributions->{$wid};
			push(@outputs,$wid."($count/$maxThread)");
		}
		print "$logtime|Job distribution: ".join(",",@outputs)."\n";
	}
	return $distributions;
}
############################## downloadCommandFromServer ##############################
sub downloadCommandFromServer{
	my $commands=shift();
	my $process=shift();
	my $serverpath=shift();
	if(!exists($process->{$urls->{"daemon/command"}})){
		print STDERR "ERROR: Command not specified in job file\n";
		terminate(1);
	}
	my $path=$process->{$urls->{"daemon/command"}};
	my ($username,$servername,$serverdir)=splitServerPath($serverpath);
	if(defined($servername)){
		my $filepath="$username\@$servername:";
		if(defined($serverdir)){$filepath.="$serverdir/$path";}
		else{$filepath.=$path;}
		rsyncFileByUpdate($filepath,$path);
	}elsif(defined($serverdir)){
		my $filepath="$serverdir/$path";
		rsyncFileByUpdate($filepath,$path);
	}
	return loadCommandFromURL($path,$commands);
}
############################## downloadInputsFromJobServer ##############################
sub downloadInputsFromJobServer{
	my $command=shift();
	my $process=shift();
	my $serverpath=shift();
	my $url=$process->{$urls->{"daemon/command"}};
	my $workdir="$moiraidir/".$process->{$urls->{"daemon/execid"}};
	foreach my $input(@{$command->{$urls->{"daemon/input"}}}){
		if(!exists($process->{"$url#$input"})){next;}
		my $inputfile=$process->{"$url#$input"};
		if(fileExists($inputfile)){next;}
		my $fromfile="$serverpath/$inputfile";
		if(!fileExists($fromfile)){next;}
		my $jobfile="$workdir/$inputfile";
		rsyncFileByUpdate($fromfile,$jobfile);
		$process->{"$url#$input"}=$jobfile;
		push(@{$process->{$urls->{"daemon/downloaded"}}},$jobfile);
	}
}
############################## downloadJobFiles ##############################
# Move job file from job to process directory at the job server
# Read job file from the job server
# Create a temporary job files for both local nd server
sub downloadJobFiles{
	my @files=@_;
	my $commands=shift(@files);
	my $processes=shift(@files);
	my $serverJobpath=shift(@files);
	my $jobslot=shift(@files);
	if($jobslot==0){return;}
	my $filesize=scalar(@files);
	if($filesize==0){return;}
	my ($serverUser,$serverName,$serverJobdir)=splitServerPath($serverJobpath);
	my $serverCtrldir=$serverJobdir;
	if($serverCtrldir=~/^(.+)\/job/){$serverCtrldir=$1;}
	my $serverMoiraidir=dirname($serverCtrldir);
	my $serverrootdir=dirname($serverMoiraidir);
	my $serverProcessdir="$serverCtrldir/process/$hostname";
	if(defined($serverName)){system("ssh $serverUser\@$serverName mkdir -p $serverProcessdir");}
	else{system("mkdir -p $serverProcessdir");}
	my @jobfiles=();#jobs retrieved from the server
	for(my $i=0;$i<$filesize&&$jobslot>0;$i++){
		my $first=$files[$i];
		my $execid=basename($first,".txt");
		my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,$execid);
		if(defined($workid)&&$workid ne $wid){next;}
		my $serverProcessfile="$serverProcessdir/$execid.txt";
		if(defined($serverName)){#access job server
			if(system("ssh $serverUser\@$serverName 'mv $serverJobdir/$first $serverProcessfile'")){next;}
		}else{#access local directory
			if(system("mv $serverJobdir/$first $serverProcessfile")){next;}
		}
		push(@jobfiles,$serverProcessfile);$jobslot--;
		my $maxjob=getMaxjobFromApproximateTime($appTime);
		if($maxjob<2){next;}
		my $search=substr($dateid,0,14);
		for($i=$i+1;$i<$filesize;$i++){
			my $next=$files[$i];
			my $execid=basename($next,".txt");
			if($execid!~/^$search/){last;}
			my $serverProcessfile="$serverProcessdir/$execid.txt";
			if(defined($serverName)){#access job server
				if(system("ssh $serverUser\@$serverName 'mv $serverJobdir/$next $serverProcessfile'")){next;}
			}else{#access local directory
				if(system("mv $serverJobdir/$first $serverProcessfile")){next;}
			}
			push(@jobfiles,$serverProcessfile);
			$maxjob--;#reduce maxjob
			if($maxjob<2){last;}
		}
	}
	foreach my $serverJobfile(@jobfiles){
		my $joburl=defined($serverName)?"$serverUser\@$serverName:$serverJobfile":$serverJobfile;
		my $execid=basename($serverJobfile,".txt");
		if(defined($opt_l)){print getLogtime()."|Downloading $joburl\n";}
		my ($jobwriter,$jobfile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
		close($jobwriter);
		if(defined($serverName)){
			system("scp $joburl $jobfile 2>&1 1>/dev/null");#scp a job file from server to local
			removeFiles($joburl);#remove from the server
		}else{system("mv $joburl $jobfile 2>&1 1>/dev/null");}
		#check file is empty, don't proceed, since probably the job was handled by other daemon
		if(-z $jobfile){unlink($jobfile);next;}
		my $process=loadProcessFile($jobfile);
		my $serverProcess=loadProcessFile($jobfile);
		my $command=downloadCommandFromServer($commands,$process,$jobServer);
		my $datetime=`date +%s`;chomp($datetime);
		$serverProcess->{$urls->{"daemon/hostname"}}=$hostname;
		$serverProcess->{$urls->{"daemon/workdir"}}="$moiraidir/$execid";
		$serverProcess->{$urls->{"daemon/timeregistered"}}=$datetime;
		downloadInputsFromJobServer($command,$process,$jobServer);
		$process->{$urls->{"daemon/jobserver"}}=defined($serverName)?"$serverUser\@$serverName:$serverrootdir":$serverrootdir;
		$process->{$urls->{"daemon/delete/inputs"}}="true";
		$process->{$urls->{"daemon/donot/update/db"}}="true";
		$process->{$urls->{"daemon/donot/move/outputs"}}="true";
		$process->{$urls->{"daemon/upload/jobserver"}}="true";
		my $localtmp=writeProcessToTmp($process);
		my $servertmp=writeProcessToTmp($serverProcess);
		rsyncFileByUpdate($servertmp,$joburl);
		unlink($servertmp);
		system("mv $localtmp $processdir/$processid/$execid.txt");
		$processes->{$execid}=$process;
	}
}
############################## downloadWorkdirFromRemoteServer ##############################
sub downloadWorkdirFromRemoteServer{
	my $process=shift();
	my $workdir=$process->{$urls->{"daemon/workdir"}};#remote workdir
	my $execid=$process->{$urls->{"daemon/execid"}};
	my $todir="$moiraidir/$execid";
	rsyncDirectory("$workdir/","$moiraidir/$execid");
	$process->{$urls->{"daemon/workdir"}}=$todir;
	my $remoteserver=$process->{$urls->{"daemon/remoteserver"}};
	my ($username,$remotename,$remotedir)=splitServerPath($remoteserver);
	system("ssh $username\@$remotename 'rm -r $remotedir/.moirai2remote/$execid'");
	return $todir;
}
############################## endLockfile ##############################
#Terminate lockfile
sub endLockfile{
	my $lockfile=shift();
	removeFiles($lockfile);
}
############################## equals ##############################
sub equals{
	my $obj1=shift();
	my $obj2=shift();
	my $ref1=ref($obj1);
	my $ref2=ref($obj2);
	if($ref1 ne $ref2){return;}
	if($ref1 eq "ARRAY"){
		my $len1=scalar(@{$obj1});
		my $len2=scalar(@{$obj2});
		if($len1!=$len2){return;}
		for(my $i=0;$i<$len1;$i++){if(!equals($obj1->[$i],$obj2->[$i])){return;}}
		return 1;
	}elsif($ref1 eq "HASH"){
		my @keys1=keys(%{$obj1});
		my @keys2=keys(%{$obj2});
		my $len1=scalar(@keys1);
		my $len2=scalar(@keys2);
		if($len1!=$len2){return;}
		foreach my $key(@keys1){
			if(!exists($obj2->{$key})){return;}
			my $val1=$obj1->{$key};
			my $val2=$obj2->{$key};
			if(!equals($val1,$val2)){return;}
		}
		return 1;
	}
	if($obj1 eq $obj2){return 1;}
}
############################## estimateJobTimes ##############################
sub estimateJobTimes{
	my $jobdir=shift();#$serverpath/.moirai2/ctrl/job or .moirai2/ctrl/job
	my $openstackFlavors=shift();
	$jobdir=defined($jobServer)?"$jobServer/.moirai2/ctrl/job":$jobdir;
	if($jobdir=~/^(.+)\@(.+)\:(.+)/){
		my $username=$1;
		my $servername=$2;
		my $dirname=$3;
		foreach my $flavor(keys(%{$openstackFlavors})){
			$openstackFlavors->{$flavor}=0;
			my @files=`ssh $username\@$servername ls $dirname/$flavor 2> /dev/null`;
			foreach my $file(@files){
				chomp($file);
				if($file=~/^\./){next;}
				if($file!~/\.txt$/){next;}
				my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,basename($file,".txt"));
				if(!exists($openstackFlavors->{$wid})){next;}
				$openstackFlavors->{$wid}+=$appTime;
			}
		}
	}else{
		foreach my $flavor(keys(%{$openstackFlavors})){
			$openstackFlavors->{$flavor}=0;
			opendir(DIR,"$jobdir/$flavor");
			foreach my $file(readdir(DIR)){
				if($file=~/^\./){next;}
				if($file!~/\.txt$/){next;}
				my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,basename($file,".txt"));
				if(!exists($openstackFlavors->{$wid})){next;}
				$openstackFlavors->{$wid}+=$appTime;
			}
			closedir(DIR);
		}
	}
	if(defined($opt_l)){
		my $logtime=getLogtime();
		my @outputs=();
		foreach my $wid(sort{$a cmp $b}keys(%{$openstackFlavors})){
			my $appTime=$openstackFlavors->{$wid};
			if($appTime>0){push(@outputs,"$wid(${appTime}s)");}
		}
		if(scalar(@outputs)>0){print "$logtime|Estimated time: ".join(",",@outputs)."\n";}
	}
	return $openstackFlavors;
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
	if($path=~/^(.+)\:(.+)\@(.+)\:(.+)$/){
		my $result=`sshpass -p $2 ssh $1\@$3 'if [ -e $4 ]; then echo 1; fi'`;chomp($result);return ($result==1);
	}elsif($path=~/^(.+\@.+)\:(.+)$/){
		my $result=`ssh $1 'if [ -e "$2" ]; then echo 1; fi'`;chomp($result);return ($result==1);
	}
	elsif(-e $path){return 1;}
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
	close(DIR);
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
		elsif($key eq "md5"){my $md5=getFileMd5($path);if(defined($md5)){$hash->{$key}=$md5;}}
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
############################## getActiveLogDirs ##############################
sub getActiveLogDirs{
	my $logdir=shift();
	my @directories=();
	opendir(DIR,$logdir);
	foreach my $dirname(readdir(DIR)){#dirname or filename
		if($dirname=~/^\./){next;}
		my $path="$logdir/$dirname";
		if(! -d $path){next;}
		if($dirname=~/^\d{8}$/){push(@directories,$path);}
	}
	closedir(DIR);
	return @directories;
}
############################## getBash ##############################
#2023/02/11
sub getBash{
	my $url=shift();
	my $content=($url=~/https?:\/\//)?getHttpContent($url):readFileContent($url);
	if($content eq""){print STDERR "#Couldn't load bash script '$url'\n";terminate(1);}
	my $command={};
	my $suffixs={};
	my $userdefined={};
	my @lines=();
	my $delete;
	my $increment;
	my $input;
	my $output;
	my $not;
	my $update;
	my $script;
	foreach my $line(split(/\n/,$content)){
		if($line=~/^#\$\s?-a\s+?(.+)$/){$command->{$urls->{"daemon/remoteserver"}}=handleServer($1);}#-a
		elsif($line=~/^#\$\s?-b\s+?(.+)$/){$command->{$urls->{"daemon/command/option"}}=jsonDecode($1);}
		elsif($line=~/^#\$\s?-c\s+?(.+)$/){$command->{$urls->{"daemon/container"}}=$1;}
		elsif($line=~/^#\$\s?-C\s+?(.+)$/){$command->{$urls->{"daemon/description"}}=$1;}
		elsif($line=~/^#\$\s?-d\s+?(.+)$/){$command->{$urls->{"daemon/dagdb"}}=checkDatabaseDirectory($1);}#-d
		elsif($line=~/^#\$\s?-e\s+?(.+)$/){if(defined($delete)){$delete.=",";}$delete.=$1;;}#-e
		elsif($line=~/^#\$\s?-E\s+?(.+)$/){$command->{$urls->{"daemon/error/stderr/ignore"}}=handleKeys($1);}#-E
		elsif($line=~/^#\$\s?-f\s+?(.+)$/){$command->{$urls->{"daemon/file/stats"}}=handleKeys($1);}#-f
		elsif($line=~/^#\$\s?-F\s+?(.+)$/){$command->{$urls->{"daemon/error/file/empty"}}=handleKeys($1);}#-F
		elsif($line=~/^#\$\s?-i\s+?(.+)$/){if(defined($input)){$input.=",";}$input.=$1;}#-i
		elsif($line=~/^#\$\s?-I\s+?(.+)$/){$command->{$urls->{"daemon/container/image"}}=$1;}#-I
		elsif($line=~/^#\$\s?-m\s+?(.+)$/){$command->{$urls->{"daemon/approximate/time"}}=$1;}#-m
		elsif($line=~/^#\$\s?-n\s+?(.+)$/){if(defined($not)){$not.=",";}$not.=$1;;}#-n
		elsif($line=~/^#\$\s?-o\s+?(.+)$/){if(defined($output)){$output.=",";}$output.=$1;}#-o
		elsif($line=~/^#\$\s?-O\s+?(.+)$/){$command->{$urls->{"daemon/error/stdout/ignore"}}=handleKeys($1);}#-O
		elsif($line=~/^#\$\s?-q\s+?(.+)$/){$command->{$urls->{"daemon/qjob"}}=$1;}#-q
		elsif($line=~/^#\$\s?-Q\s+?(.+)$/){$command->{$urls->{"daemon/qjob/opt"}}=$1;}#-Q
		elsif($line=~/^#\$\s?-r\s+?(.+)$/){$command->{$urls->{"daemon/return"}}=handleKeys($1);}#-r
		elsif($line=~/^#\$\s?-s\s+?(.+)$/){$command->{$urls->{"daemon/sleeptime"}}=$1;}#-s
		elsif($line=~/^#\$\s?-S\s+?(.+)$/){if(defined($script)){$script.=",";}$script.=$1;}#-S
		elsif($line=~/^#\$\s?-u\s+?(.+)$/){if(defined($update)){$update.=",";}$update.=$1;}#-u
		elsif($line=~/^#\$\s?-V\s+?(.+)$/){$command->{$urls->{"daemon/container/flavor"}}=$1;}#-V
		elsif($line=~/^#\$\s?-w\s+?(.+)$/){$command->{$urls->{"daemon/workid"}}=$1;}#-w
		elsif($line=~/^#\$\s?-X\s+?(.+)$/){$command->{$urls->{"daemon/suffix"}}=handleSuffix($1);}#-X
		elsif($line=~/^#\$\s?-z\s+?(.+)$/){$command->{$urls->{"daemon/unzip"}}=handleKeys($1);}#-z
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
	if(defined($not)){
		my ($keys,$query)=handleInputOutput($not,$userdefined,$suffixs);
		foreach my $key(@{$keys}){$inputKeys->{$key}=1;}#not is input
		if(defined($query)){$command->{$urls->{"daemon/query/not"}}=$query;}
	}
	if(defined($input)){
		my ($keys,$query)=handleInputOutput($input,$userdefined,$suffixs);
		foreach my $key(@{$keys}){$inputKeys->{$key}=1;}
		if(defined($query)){$command->{$urls->{"daemon/query/in"}}=$query;}
	}
	my $outputKeys={};
	if(defined($delete)){
		my ($keys,$query)=handleInputOutput($delete,$userdefined,$suffixs);
		foreach my $key(@{$keys}){if(!exists($inputKeys->{$key})){$outputKeys->{$key}=1;}}
		if(defined($query)){$command->{$urls->{"daemon/query/delete"}}=$query;}
	}
	if(defined($increment)){
		my ($keys,$query)=handleInputOutput($increment,$userdefined,$suffixs);
		foreach my $key(@{$keys}){if(!exists($inputKeys->{$key})){$outputKeys->{$key}=1;}}
		if(defined($query)){$command->{$urls->{"daemon/query/increment"}}=$query;}
	}
	if(defined($update)){
		my ($keys,$query)=handleInputOutput($update,$userdefined,$suffixs);
		foreach my $key(@{$keys}){if(!exists($inputKeys->{$key})){$outputKeys->{$key}=1;}}
		if(defined($query)){$command->{$urls->{"daemon/query/update"}}=$query;}
	}
	if(defined($output)){
		my ($keys,$query)=handleInputOutput($output,$userdefined,$suffixs);
		foreach my $key(@{$keys}){if(!exists($inputKeys->{$key})){$outputKeys->{$key}=1;}}
		if(defined($query)){$command->{$urls->{"daemon/query/out"}}=$query;}
	}
	my @inputs=sort{$a cmp $b}keys(%{$inputKeys});
	if(scalar(@inputs)>0){$command->{$urls->{"daemon/input"}}=\@inputs;}
	my @outputs=sort{$a cmp $b}keys(%{$outputKeys});
	if(scalar(@outputs)>0){$command->{$urls->{"daemon/output"}}=\@outputs;}
	getBashImportHash($command,$urls->{"daemon/suffix"},$suffixs);
	getBashImportHash($command,$urls->{"daemon/userdefined"},$userdefined);
	return $command;
}
############################## getBashImportHash ##############################
sub getBashImportHash{
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
	if(!defined($md5cmd)){return;}
	my ($writer,$temp)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
	print $writer "$content";
	close($writer);
	my $md5=`$md5cmd<$temp`;
	unlink($temp);
	chomp($md5);
	if(/^\s*(\S+)\s+\-$/){$md5=$1;}
	return $md5;
}
############################## getDate ##############################
sub getDate{
	my $delim=shift();
	my $time=shift();
	if(!defined($delim)){$delim="";}
	if(!defined($time)||$time eq""){$time=localtime();}
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
		if($file eq""){next;}
		my $path="$directory/$file";
		if(!-d $path){next;}
		if(defined($grep)&&$path!~/$grep/){next;}
		push(@dirs,$path);
	}
	closedir(DIR);
	return @dirs;
}
############################## getFileCount ##############################
sub getFileCount{
	my $dirname=shift();
	my $maxsize=shift();
	if(defined($maxsize)){$maxsize="|head -n $maxsize|wc -l"}
	else{$maxsize="|wc -l";}
	my $count=0;
	if($dirname=~/^(.+)\@(.+)\:(.+)/){
		my $username=$1;
		my $servername=$2;
		my $dirname=$3;
		$count=`ssh $username\@$servername 'ls $dirname 2>/dev/null$maxsize'`;
	}else{
		$count=`ls $dirname 2>/dev/null$maxsize`;
	}
	if($count=~/(\d+)/){$count=$1;}
	return $count;
}
############################## getFileMd5 ##############################
sub getFileMd5{
	my $file=shift();
	if(!defined($md5cmd)){return;}
	my $md5=`$md5cmd<$file`;
	chomp($md5);
	if($md5=~/^(\S+)\s+\-$/){$md5=$1;}
	return $md5;
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
			if($file eq""){next;}
			my $path="$directory/$file";
			if(-d $path){next;}
			my $hit=0;
			foreach my $g(@{$grep}){if($path=~/$g/){$hit=1;}}
			if($hit){push(@files,$path);}
		}
	}else{
		foreach my $file(readdir(DIR)){
			if($file=~/^\./){next;}
			if($file eq""){next;}
			my $path="$directory/$file";
			if(-d $path){next;}
			if(defined($grep)&&$path!~/$grep/){next;}
			push(@files,$path);
		}
	}
	closedir(DIR);
	return @files;
}
############################## getFilesFromDir ##############################
sub getFilesFromDir{
	my $dirname=shift();
	my @files=();
	if($dirname=~/^(.+)\@(.+)\:(.+)/){
		my $username=$1;
		my $servername=$2;
		my $dirname=$3;
		@files=`ssh $username\@$servername ls $dirname 2>/dev/null`;
		foreach my $file(@files){chomp($file);}
	}else{
		@files=`ls $dirname 2>/dev/null`;
		foreach my $file(@files){chomp($file);}
	}
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
############################## getInstanceCounts ##############################
sub getInstanceCounts{
	my @startFiles=getFilesFromDir("$instancedir/*.start");
	my $counts={};
	my $total=0;
	foreach my $startFile(@startFiles){
		my ($ip,$flavor)=split(/_/,basename($startFile,".start"));
		if(!exists($counts->{$flavor})){$counts->{$flavor}=0;}
		$counts->{$flavor}++;
		$total++;
	}
	return wantarray?($total,$counts):$total;
}
############################## getJobFiles ##############################
sub getJobFiles{
	my $commands=shift();#command hashtable
	my $processes=shift();#processes hashtable
	my $jobdir=shift();#$serverpath/.moirai2/ctrl/job
	my $jobSlot=shift();#Number of slots available
	my $execids=shift();#defined execids (exec mode)
	my @jobfiles=();
	if($jobSlot==0){return @jobfiles;}
	my @matchIds=();
	if(defined($execids)){#execids already defined
		opendir(DIR,$jobdir);
		foreach my $file(readdir(DIR)){
			if($file=~/^\./){next;}
			my $path="$jobdir/$file";
			if(-d $path){next;}
			my $execid=basename($path,".txt");
			if(!exists($execids->{$execid})){next;}
			push(@jobfiles,$path);
		}
		closedir(DIR);
		@jobfiles=sort{$a cmp $b}@jobfiles;
		getJobFilesSelect($commands,$processes,$jobSlot,@jobfiles);
	}elsif($jobdir=~/^(.+)\@(.+)\:(.+)/){#daemon mode only
		my $username=$1;
		my $servername=$2;
		my $dirname=$3;
		my @filelists=`ssh $username\@$servername ls $dirname`;
		foreach my $file(@filelists){chomp($file);if($file!~/\.txt$/){next;}push(@jobfiles,$file);}
		downloadJobFiles($commands,$processes,$jobdir,$jobSlot,@jobfiles);
	}elsif($jobdir=~/^\.moirai2\//){
		opendir(DIR,$jobdir);
		foreach my $file(readdir(DIR)){
			if($file=~/^\./){next;}#skip current directory
			my $path="$jobdir/$file";
			if(-d $path){next;}#skip directory
			push(@jobfiles,$path);
		}
		closedir(DIR);
		@jobfiles=sort{$a cmp $b}@jobfiles;
		getJobFilesSelect($commands,$processes,$jobSlot,@jobfiles);
	}else{
		my @filelists=`ls $jobdir`;
		foreach my $file(@filelists){chomp($file);if($file!~/\.txt$/){next;}push(@jobfiles,$file);}
		downloadJobFiles($commands,$processes,$jobdir,$jobSlot,@jobfiles);
	}
	return $processes;
}
############################## getJobFilesSelect ##############################
sub getJobFilesSelect{
	my @files=@_;#list of files from local directory only
	my $commands=shift(@files);#commands hashtable
	my $processes=shift(@files);#processes hashtable
	my $jobSlot=shift(@files);#max number of jobs to retrieve
	if($jobSlot<=0){return;}#No need to retrieve
	my $fileCount=scalar(@files);#file size
	if($fileCount==0){return;}#No need to retrieve
	my @jobfiles=();
	for(my $i=0;$i<$fileCount&&$jobSlot>0;$i++){#go through all files until job slot is filled
		my $first=$files[$i];#base group of jobs based on the first one
		my $execid=basename($first,".txt");
		my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,$execid);
		if(defined($workid)&&$workid ne $wid){next;}#workid must match
		my $processfile="$processdir/$processid/$execid.txt";
		if(system("mv $first $processfile")){next;}#move to process directory
		push(@jobfiles,$processfile);$jobSlot--;#reduce job slot
		my $maxjob=getMaxjobFromApproximateTime($appTime);#convert from second => maxjob
		if($maxjob<2){next;}#maxjob=1, no need to group
		for($i=$i+1;$i<$fileCount;$i++){# go through next job files
			my $next=$files[$i];#next file
			my $execid2=basename($next,".txt");
			if($execid2!~/${cmdid}_${wid}/){next;}#no match
			my $processfile2="$processdir/$processid/$execid2.txt";
			if(system("mv $next $processfile2")){next;}#move to process directory
			push(@jobfiles,$processfile2);#remember job files
			$maxjob-=1;#reduce maxjob
			if($maxjob<2){last;}
		}
	}
	foreach my $jobfile(@jobfiles){
		my $execid=basename($jobfile,".txt");
		$processes->{$execid}=loadProcessFile($jobfile);
		my $process=$processes->{$execid};
		my $url=$process->{$urls->{"daemon/command"}};
		my $command=loadCommandFromURL($url,$commands);
		uploadInputsToRemoteServer($command,$process);
	}
}
############################## getJson ##############################
sub getJson{
	my $url=shift();
	my $content=($url=~/https?:\/\//)?getHttpContent($url):readFileContent($url);
	return jsonDecode($content);
}
############################## getLogFileFromExecid ##############################
sub getLogFileFromExecid{
	my $execid=shift();
	if(-e "$errordir/$execid.txt"){return "$errordir/$execid.txt";}
	my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,$execid);
	my $dirname=substr($dateid,0,8);
	if(-e "$logdir/$dirname/$execid.txt"){return "$logdir/$dirname/$execid.txt";}
	elsif(-e "$logdir/$dirname.tgz"){return "$logdir/$dirname.tgz";}
}
############################## getLogtime ##############################
sub getLogtime{my $time=shift();return getDate("/",$time)." ".getTime(":",$time);}
############################## getMaxjobFromApproximateTime ##############################
sub getMaxjobFromApproximateTime{
	my $command=shift();
	my $approximateTime=1;
	if(!defined($command)){
		print STDERR "ERROR: Command is not defined\n";
		terminate(1);
	}elsif(ref($command)ne"HASH"){#not a hash, but a value
		$approximateTime=$command;
	}elsif(exists($command->{$urls->{"daemon/maxjob"}})){#it's been already calculated
		return $command->{$urls->{"daemon/maxjob"}};
	}elsif(exists($command->{$urls->{"daemon/approximate/time"}})){#get approxiamte time from command
		$approximateTime=$command->{$urls->{"daemon/approximate/time"}};
	}else{#default is 1 second
		$approximateTime=1;
	}
	#Calculate max job from approximate time
	my $maxjob=int($averageJobSpan/$approximateTime);#how much one throw should 
	if($maxjob<1){$maxjob=1;}#make sure at least one job is completed
	$command->{$urls->{"daemon/maxjob"}}=$maxjob;#store in a command
	return $maxjob;
}
############################## getNumberOfJobsRemaining ##############################
sub getNumberOfJobsRemaining{
	my $ids=shift();
	my $directory=defined($jobServer)?"$jobServer/.moirai2/ctrl/job":$jobdir;
	if(scalar(keys(%{$ids}))==0){return getFileCount("$directory/*.txt",$maxThread);}
	my $count=0;
	foreach my $file(getFilesFromDir($directory)){
		my $execid=basename($file,".txt");
		if(exists($ids->{$execid})){$count++;}
	}
	return $count;
}
############################## getNumberOfJobsRunning ##############################
sub getNumberOfJobsRunning{return getFileCount("$throwdir/$processid/*.sh",$maxThread);}
############################## getOpenstackFlavors ##############################
#Retrieve list of flavors from openstack.pl 
sub getOpenstackFlavors{
	my $flavors={};
	my $index=scalar(keys(%{$flavors}))+1;
	my @lines=`openstack.pl list flavors`;
	foreach my $line(@lines){
		chomp($line);
		my @tokens=split(/\s*\|\s*/,$line);
		if($tokens[1]!=$index){next;}
		my $flavor=$tokens[3];
		$flavors->{$flavor}=0;
		$index=scalar(keys(%{$flavors}))+1;
	}
	if(scalar(keys(%{$flavors}))==0){
		print STDERR "#ERROR: No flavors found through openstack.pl\n";
		terminate(1);
	}
	return $flavors;
}
############################## getProcessFileFromExecid ##############################
sub getProcessFileFromExecid{
	my $id=shift();
	my @processfiles=`ls $processdir/*/$id.txt 2> /dev/null`;
	if(scalar(@processfiles)>1){
		print STDERR "ERROR: There are multiple process files with ID '$id'\n";
		terminate(1);
	}
	if(scalar(@processfiles)==0){return;}
	my $processfile=$processfiles[0];
	chomp($processfile);
	if($processfile eq""){return;}
	return $processfile;
}
############################## getProcessIds ##############################
sub getProcessIds{
	my $ids={};
	opendir(DIR,$processdir);
	foreach my $dirname(readdir(DIR)){
		if($dirname=~/^\./){next;}
		if(!-d "$processdir/$dirname"){next;}
		$ids->{$dirname}=[];
		opendir(DIR,"$processdir/$dirname");
		foreach my $filename(readdir(DIR)){
			if($filename=~/^\./){next;}
			push(@{$ids->{$dirname}},"$processdir/$dirname/$filename");
		}
		close(DIR);
	}
	close(DIR);
	return $ids;
}
############################## getQueryResults ##############################
sub getQueryResults{
	my $dir=shift();
	my $query=shift();
	if(!defined($dir)){$dir=".";}
	my @queries=ref($query)eq"ARRAY"?@{$query}:split(/,/,$query);
	foreach my $line(@queries){if(ref($line)eq"ARRAY"){$line=join("->",@{$line});}}
	my $command="perl $program_directory/dag.pl -d $dir -f json query '".join("' '",@queries)."'";
	my $result=`$command`;chomp($result);
	my $hashs=jsonDecode($result);
	my $keys=retrieveKeysFromQueries($query);
	return [$keys,$hashs];
}
############################## getStatusFromLogFile ##############################
sub getStatusFromLogFile{
	my $logfile=shift();
	if(!defined($logfile)||$logfile eq ""){return "notfound";}
	my $process=loadProcessFile($logfile);
	if(exists($process->{$urls->{"daemon/execute"}})){
		my $status=$process->{$urls->{"daemon/execute"}};
		if(ref($status)ne"ARRAY"){return $status;}
		my @array=@{$status};
		return $array[scalar(@array)-1];
	}
	if(!exists($process->{$urls->{"daemon/queserver"}})){return "nostatus";}
	my $queserver=$process->{$urls->{"daemon/queserver"}};
	my $execid=$process->{$urls->{"daemon/execid"}};
	my ($username,$servername,$serverdir)=splitServerPath($queserver);
	my $status=`ssh $username\@$servername 'cd $serverdir;perl moirai2.pl check status $execid'`;
	chomp($status);
	return $status;
}
############################## getTime ##############################
sub getTime{
	my $delim=shift();
	my $time=shift();
	if(!defined($delim)){$delim="";}
	if(!defined($time)||$time eq""){$time=localtime();}
	else{$time=localtime($time);}
	my $hour=$time->hour;
	if($hour<10){$hour="0".$hour;}
	my $minute=$time->min;
	if($minute<10){$minute="0".$minute;}
	my $second=$time->sec;
	if($second<10){$second="0".$second;}
	return $hour.$delim.$minute.$delim.$second;
}
############################## getVariableArraysFromProcess ##############################
sub getVariableArraysFromProcess{
	my $command=shift();
	my $process=shift();
	my @variables=({});
	my $url=$process->{$urls->{"daemon/command"}};
	foreach my $name(@{$command->{$urls->{"daemon/input"}}}){
		if(!exists($process->{"$url#$name"})){next;}
		my @ins=ref($process->{"$url#$name"})?@{$process->{"$url#$name"}}:($process->{"$url#$name"});
		my @array=();
		foreach my $variable(@variables){
			foreach my $in(@ins){
				my $hash={};
				while(my($key,$val)=each(%{$variable})){$hash->{$key}=$val;}#copy
				$hash->{$name}=$in;
				push(@array,$hash);
			}
		}
		@variables=@array;
	}
	foreach my $name(@{$command->{$urls->{"daemon/output"}}}){
		if(!exists($process->{"$url#$name"})){next;}
		my @outs=ref($process->{"$url#$name"})?@{$process->{"$url#$name"}}:($process->{"$url#$name"});
		my @array=();
		foreach my $variable(@variables){
			foreach my $out(@outs){
				my $hash={};
				while(my($key,$val)=each(%{$variable})){$hash->{$key}=$val;}#copy
				$hash->{$name}=$out;
				push(@array,$hash);
			}
		}
		@variables=@array;
	}
	return \@variables;
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
############################## handleCompletedProcess ##############################
sub handleCompletedProcess{
	my $command=shift();
	my $process=shift();
	my $status=shift();
	my $execid=$process->{$urls->{"daemon/execid"}};
	my $workdir=$process->{$urls->{"daemon/workdir"}};
	my $processid=$process->{$urls->{"daemon/processid"}};
	my $stderrfile="$workdir/stderr.txt";
	my $stdoutfile="$workdir/stdout.txt";
	my $statusfile="$workdir/status.txt";
	my $logfile="$workdir/log.txt";
	my $bashfile="$workdir/run.sh";
	my $processLog=loadProcessFile($logfile);
	removeWorkdirFromVariableValues($command,$process,$processLog);
	my $processfile="$processdir/$processid/$execid.txt";
	my $dagdb=exists($command->{$urls->{"daemon/dagdb"}})?$command->{$urls->{"daemon/dagdb"}}."/":defined($dbdir)?"$dbdir/":undef;
	if(exists($process->{$urls->{"daemon/hostname"}})){$processfile="$processdir/".$process->{$urls->{"daemon/hostname"}}."/$execid.txt";}
	if(exists($process->{$urls->{"daemon/delete/inputs"}})){deleteInputsFromServer($command,$process,$processLog);}
	#read processfile to get time registered
	my $timeregistered=$process->{$urls->{"daemon/timeregistered"}};
	if(defined($opt_l)){print getLogtime()."|Completing $execid with '$status' status\n";}
	while(my ($key,$val)=each(%{$process})){
		if($key eq $urls->{"daemon/process/lastupdate"}){next;}
		# output specified in job/process might be obsolete in some cases.
		# For example if $id is input parameter and output is specified in format 'output=$id.txt',
		# In job/process, it's noted as output=$id.txt, but in log file, $output might be akira.txt
		# So there is a need to update the value
		if(exists($processLog->{$key})){next;}#processLog has the newest log information, so keep
		$processLog->{$key}=$val;#If not found, use the old log information
	}
	$process=$processLog;
	if(exists($process->{$urls->{"daemon/upload/jobserver"}})){uploadWorkdirToJobServer($process);}
	if(exists($process->{$urls->{"daemon/download/remoteserver"}})){
		$workdir=downloadWorkdirFromRemoteServer($process);
		$stderrfile="$workdir/stderr.txt";
		$stdoutfile="$workdir/stdout.txt";
		$statusfile="$workdir/status.txt";
		$logfile="$workdir/log.txt";
		$bashfile="$workdir/run.sh";
	}
	#calculate process time
	calculateProcessTime($process,$statusfile);
	#write logfile
	my ($logwriter,$logoutput)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
	print $logwriter "######################################## $execid ########################################\n";
	foreach my $key(sort{$a cmp $b}keys(%{$process})){
		if(ref($process->{$key})eq"ARRAY"){foreach my $val(@{$process->{$key}}){print $logwriter "$key\t$val\n";}}
		else{print $logwriter "$key\t".$process->{$key}."\n";}
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
	# writers
	my ($insertwriter,$insertfile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
	my ($deletewriter,$deletefile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
	my ($updatewriter,$updatefile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
	my ($incrementwriter,$incrementfile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
	my $insertcount=0;
	my $deletecount=0;
	my $updatecount=0;
	my $incrementcount=0;
	# handle inserts and updates
	my $variables;
	if(defined($command->{$urls->{"daemon/query/out"}})){
		if(!defined($variables)){$variables=getVariableArraysFromProcess($command,$process);}
		my $queries=$command->{$urls->{"daemon/query/out"}};
		foreach my $query(@{$queries}){
			my @lines=constructTripleFromVariables($dagdb,$query,$variables);
			foreach my $line(@lines){print $insertwriter "$line\n";$insertcount++;}
		}
	}
	if(defined($command->{$urls->{"daemon/query/update"}})){
		if(!defined($variables)){$variables=getVariableArraysFromProcess($command,$process);}
		my $queries=$command->{$urls->{"daemon/query/update"}};
		foreach my $query(@{$queries}){
			my @lines=constructTripleFromVariables($dagdb,$query,$variables);
			foreach my $line(@lines){print $updatewriter "$line\n";$updatecount++;}
		}
	}
	if(defined($command->{$urls->{"daemon/query/delete"}})){
		if(!defined($variables)){$variables=getVariableArraysFromProcess($command,$process);}
		my $queries=$command->{$urls->{"daemon/query/delete"}};
		foreach my $query(@{$queries}){
			my @lines=constructTripleFromVariables($dagdb,$query,$variables);
			foreach my $line(@lines){print $deletewriter "$line\n";$deletecount++;}
		}
	}
	if(defined($command->{$urls->{"daemon/query/increment"}})){
		if(!defined($variables)){$variables=getVariableArraysFromProcess($command,$process);}
		my $queries=$command->{$urls->{"daemon/query/increment"}};
		foreach my $query(@{$queries}){
			my @lines=constructTripleFromVariables($dagdb,$query,$variables);
			foreach my $line(@lines){print $incrementwriter "$line\n";$incrementcount++;}
		}
	}
	#stdoutfile
	$reader=openFile($stdoutfile);
	my $stdoutcount=0;
	while(<$reader>){
		chomp;
		if(/^insert\s+(.+)\-\>(.+)\-\>(.+)/i){print $insertwriter "$1\t$dagdb$2\t$3\n";$insertcount++;next;}
		if(/^delete\s+(.+)\-\>(.+)\-\>(.+)/i){print $deletewriter "$1\t$dagdb$2\t$3\n";$deletecount++;next;}
		if(/^update\s+(.+)\-\>(.+)\-\>(.+)/i){print $updatewriter "$1\t$dagdb$2\t$3\n";$updatecount++;next;}
		if(/^increment\s+(.+)\-\>(.+)\-\>(.+)/i){print $incrementwriter "$1\t$dagdb$2\t$3\n";$incrementcount++;next;}
		if($stdoutcount==0){print $logwriter "######################################## stdout ########################################\n";}
		print $logwriter "$_\n";$stdoutcount++;
	}
	close($reader);
	close($insertwriter);
	close($deletewriter);
	close($updatewriter);
	close($incrementwriter);
	#stderrfile
	$reader=openFile($stderrfile);
	my $stderrcount=0;
	while(<$reader>){
		chomp;
		if($stderrcount==0){print $logwriter "######################################## stderr ########################################\n";}
		print $logwriter "$_\n";$stderrcount++;
	}
	close($reader);
	my $doNotUpdateDb=exists($process->{$urls->{"daemon/donot/update/db"}})?1:($status eq "error")?1:undef;
	#insertfile
	if($insertcount>0&&!$doNotUpdateDb){
		print $logwriter "######################################## insert ########################################\n";
		my $reader=openFile($insertfile);
		while(<$reader>){print $logwriter "$_";}
		close($reader);
		system("mv $insertfile $insertdir/".basename($insertfile));
	}else{unlink($insertfile);}
	#updatefile
	if($updatecount>0&&!$doNotUpdateDb){
		print $logwriter "######################################## update ########################################\n";
		my $reader=openFile($updatefile);
		while(<$reader>){print $logwriter "$_";}
		close($reader);
		system("mv $updatefile $updatedir/".basename($updatefile));
	}else{unlink($updatefile);}
	#deletefile
	if($deletecount>0&&!$doNotUpdateDb){
		print $logwriter "######################################## delete ########################################\n";
		my $reader=openFile($deletefile);
		while(<$reader>){print $logwriter "$_";}
		close($reader);
		system("mv $deletefile $deletedir/".basename($deletefile));
	}else{unlink($deletefile);}
	#incrementfile
	if($incrementcount>0&&!$doNotUpdateDb){
		print $logwriter "######################################## increment ########################################\n";
		my $reader=openFile($incrementfile);
		while(<$reader>){print $logwriter "$_";}
		close($reader);
		system("mv $incrementfile $incrementdir/".basename($incrementfile));
	}else{unlink($incrementfile);}
	#scriptfile
	my @scriptFiles=();
	if(exists($command->{$urls->{"daemon/script"}})){
		foreach my $script(@{$command->{$urls->{"daemon/script"}}}){
			my $name=$script->{$urls->{"daemon/script/name"}};
			push(@scriptFiles,"$workdir/bin/$name");
		}
	}
	#bashfile
	print $logwriter "######################################## bash ########################################\n";
	my $reader=openFile($bashfile);
	if($writeFullLog){
		while(<$reader>){chomp;print $logwriter "$_\n";}
		foreach my $scriptFile(@scriptFiles){
			my $filename=basename($scriptFile);
			print $logwriter "######################################## $filename ########################################\n";
			my $scriptReader=openFile($scriptFile);
			while(<$scriptReader>){chomp;print $logwriter "$_\n";}
			close($scriptReader);
		}
	}else{
		my $commandLineFlag=0;
		while(<$reader>){
			chomp;
			if(/########## command ##########/){$commandLineFlag=1;}
			elsif(/#############################/){last;}
			elsif($commandLineFlag==1){print $logwriter "$_\n";}
		}
	}
	close($reader);
	close($logwriter);
	chmod(0755,$logoutput);
	if(scalar(@scriptFiles)>0){removeFiles(@scriptFiles);removeDirs("$workdir/bin");}
	if(!exists($process->{$urls->{"daemon/donot/delete/results"}})){
		removeFiles($bashfile,$logfile,$stdoutfile,$stderrfile,$statusfile);
		if(!exists($process->{$urls->{"daemon/donot/move/outputs"}})){moveOuputsFromWorkdir($command,$process);}
		system("rm -r $workdir");
	}
	removeFiles($processfile);#Always delete process file
	#setup final log file
	if($status eq "completed"){
		my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,$execid);
		my $date=substr($dateid,0,8);
		mkdir("$logdir/$date/");
		system("mv $logoutput $logdir/$date/$execid.txt");
	}elsif($status eq "error"){
		system("mv $logoutput $errordir/$execid.txt");
	}
}
############################## handleCompletedQueServer ##############################
sub handleCompletedQueServer{
	my $command=shift();
	my $process=shift();
	if(!exists($process->{$urls->{"daemon/queserver"}})){return;}
	if(!exists($process->{$urls->{"daemon/workdir"}})){return;}
	my $queserver=$process->{$urls->{"daemon/queserver"}};
	my $workdir=$process->{$urls->{"daemon/workdir"}};
	rsyncDirectory($workdir,$moiraidir);
	my $execid=$process->{$urls->{"daemon/execid"}};
	my ($username,$servername,$serverdir)=splitServerPath($queserver);
	if(defined($servername)){
		system("ssh $username\@$servername rm -r $serverdir/.moirai2/$execid/");
	}else{
		system("rm -r $serverdir/.moirai2/$execid/");
	}
	$process->{$urls->{"daemon/workdir"}}="$moiraidir/$execid";
	delete($process->{$urls->{"daemon/queserver"}});
}
############################## handleDagdbOption ##############################
sub handleDagdbOption{
	my $command=shift();
	if(defined($opt_d)){$command->{$urls->{"daemon/dagdb"}}=checkDatabaseDirectory($opt_d);}
	elsif(!exists($command->{$urls->{"daemon/dagdb"}})){$command->{$urls->{"daemon/dagdb"}}=".";}
}
############################## handleInputOutput ##############################
# split by ,
# split -> userdefined
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
	}else{@statements=@{splitTokenByComma($statement)};}
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
				my $line=$token;
				if($line=~/^\((.+)\)$/){$line=$1;}#Remove '()' from token
				while($token=~/\$(\w+)/g){#$variable
					my $variable=$1;
					if(!existsArray($keys,$variable)){push(@{$keys},$variable);}
				}
				while($token=~/\$\{(\w+)\}/g){#${variable}
					my $variable=$1;
					if(!existsArray($keys,$variable)){push(@{$keys},$variable);}
				}
			}
			if(!defined($triples)){$triples=[];}
			push(@{$triples},join("->",@tokens));
		}elsif(scalar(@tokens)!=1){
			print STDERR "ERROR: '$statement' has empty token or bad notation.\n";
			print STDERR "ERROR: Use single quote '\$a->b->\$c' instead of double quote \"\$a->b->\$c\".\n";
			print STDERR "ERROR: Or escape '\$' with '\\' sign \"\\\$a->b->\\\$c\".\n";
			terminate(1);
		}else{
			my $variable=$tokens[0];
			if(-e $variable){
				if(!defined($fileKeys)){$fileKeys=[];}
				push(@{$fileKeys},$variable);
				next LINE;
			}elsif($variable=~/\*/){
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
############################## handleOpenstackMode ##############################
sub handleOpenstackMode{
	my $openstackFlavors=shift();
	my ($instanceCount,$instances)=getInstanceCounts();
	$instanceCount=removeUnusedInstances($instanceCount,$instances);
	if($instanceCount>=$maxThread){return;}#No need to create anymore
	my $jobdir=defined($jobServer)?"$jobServer/.moirai2/ctrl/job":$jobdir;
	estimateJobTimes($jobdir,$openstackFlavors);
	my $flavorDistributions=distributeResources($openstackFlavors);
	startNewInstances($flavorDistributions,$instances);
}
############################## handleScript ##############################
#Convert script and code to array
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
	if($line=~/^openstack\:?(.+)$/i){
		my $directory=$1;
		my $flavor=defined($opt_V)?$opt_V:$defaultFlavor;
		my $image=defined($opt_I)?$opt_I:$defaultImage;
		my $command="openstack.pl -q -i $image -f $flavor add node";
		my $ip=`$command`;
		chomp($ip);
		if($ip!~/[\d\.]+/){
			print STDERR "ERROR: Failed to $command\n";terminate(1);
			terminate(1);
		}
		if(defined($directory)){$line="$ip:$directory";}
		else{$line=$ip;}
	}
	if($line=~/^(.+)\@(.+)\:(.+)$/){$username=$1;$servername=$2;$serverdir=$3;}
	elsif($line=~/^(.+)\@(.+)$/){$username=$1;$servername=$2;}
	elsif($line=~/^\d+\.\d+\.\d+\.\d+$/){$username=`whoami`;chomp($username);$servername=$line;}
	elsif($line=~/^(\d+\.\d+\.\d+\.\d+)\:(.+)$/){$username=`whoami`;chomp($username);$servername=$1;$serverdir=$2;}
	elsif(-d $line){return $line;}
	else{$username=`whoami`;chomp($username);$servername=$line;}
	if(!defined($serverdir)){$serverdir="/home/$username";}
	if($serverdir=~/^\//){}
	else{$serverdir="/home/$username/$serverdir";}
	if(system("ssh -o \"ConnectTimeout 3\" $username\@$servername hostname > /dev/null")){
		print STDERR "ERROR: Couldn't login with '$username\@$servername'.\n";
		terminate(1);
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
############################## helpBuild ##############################
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
############################## helpCommand ##############################
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
	print "         -a  Process jobs (a)cross server instead of running on local environment\n";
	print "         -A  Force processes even if input->output queries are (A)lready completed\n";
	print "         -b  Specify (b)oolean options of a command line (example -a:\$optionA,-b:\$optionB).\n";
	print "         -c  Specify (c)ontainer image/path for execution for docker or singularity.\n";
	print "         -C  Simple des(C)ription of a command used for output\n";
	print "         -d  Path to a directed acyclic graph (d)atabase directory (default='.').\n";
	print "         -D  (Delim character for splitting filename (None alphabe/number characters+'_')\n";
	print "         -e  d(e)lete database with '\$sub->\$pred->\$obj' format.\n";
	print "         -E  Ignore STD(E)RR if specific regexp is found in STDERR messages.\n";
	print "         -f  Record (f)ilestats[linecount/seqcount/md5/filesize/utime] of output files.\n";
	print "         -F  If specified output (F)ile has empty content, record as error.\n";
	print "         -h  Show (h)elp message.\n";
	print "         -H  Show update (H)istory.\n";
	print "         -i  (i)nput query for select from database in '\$sub->\$pred->\$obj' format.\n";
	print "         -I  (I)mage of OpenStack instance to build and process and process job.\n";
	print "         -j  Upload jobs to a (j)ob server instead of local .moirai2/ctrl/job.\n";
	print "         -l  Show (l)ogs messages from moirai.pl.\n";
	print "         -L  Write (L)ogs to .moirai/daemon/*.stdout and .moirai/damone/*.stderr.\n";
	print "         -m  Approxi(m)ate time to process (default='1'second).\n";
	print "         -M  (M)ax number of threads handled by daemon(default='1').\n";
	print "         -n  (n)egation of input queries meaning if match, don't execute process.\n";
	print "         -N  i(N)crement database with '\$sub->\$pred->\$obj' format.\n";
	print "         -o  (o)utput query for insert to database in '\$sub->\$pred->\$obj' format.\n";
	print "         -O  Ignore STD(O)UT if specific regexp is found in STDOUT message.\n";
	print "         -p  (p)rint command lines instead of executing for test purpose.\n";
	print "         -P  Use user specified tem(P) directory instead of /tmp.\n";
	print "         -q  Use (q)sub or slurm for throwing jobs [qsub|slurm|openstack].\n";
	print "         -Q  (Q)sub/slurm options [qsub/sge/squeue/slurm].\n";
	print "         -r  Print (r)eturn value (in exec mode, stdout is default).\n";
	print "         -s  Loop (s)leep time in second (default=1).\n";
	print "         -S  Implement/import (S)cript code to a command json file.\n";
	print "         -t  Check (t)imestamp of inputs and outputs and execute command if needed.\n";
	print "         -u  (u)pdate database with '\$sub->\$pred->\$obj' format.\n";
	print "         -U  Run in (U)ser mode where input parameters are prompted.\n";
	print "         -v  (v)olume directories to rsync across net.\n";
	print "         -V  Fla(V)or of Openstack instance to build and process job.\n";
	print "         -w  Assign (w)ork id (default is 'local').\n";
	print "         -x  Don't e(x)ecute process, but just submit process.\n";
	print "         -X  Set suffi(X)s of input/output files (format is '\$output.txt').\n";
	print "         -z  Unzip input files before processing.\n";
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
############################## helpDaemon ##############################
sub helpDaemon{
	print "\n";
	print "Program: Construct and process jobs with moirai2 command scripts.\n";
	print "\n";
	print "Usage: perl $program_name MODE\n";
	print "\n";
	print "MODE:\n";
	print "   complete  Complete processes handled by other computation server\n";
	print "       cron  Submit jobs constructed from command files under ./cron/\n";
	print "  openstack  Using openstack.pl, create instance if needed\n";
	print "    process  Process jobs under .moirai2/ctrl/job/\n";
	print "   retrieve  Retrieve jobs from server defined with -j option\n";
	print "       stop  Stop specific daemon\n";
	print "     submit  Submit jobs constructed from submit files under .moirai2/ctrl/submit/\n";
	print "  terminate  Teminate jobs if no jobs remain\n";
	print "\n";
	print "Options:\n";
	print "         -a  process jobs by (a)cessing remote server instead of using local.\n";
	print "         -b  (B)uild daemon on specified server instead of local environment.\n";
	print "         -d  path to a directed acyclic graph (d)atabase directory (default='.').\n";
	print "         -h  Show (h)elp message.\n";
	print "         -H  Show update (h)istory.\n";
	print "         -j  Retrieve jobs from a (j)ob server instead of retrieving from a local .moirai2/ctrl/job.\n";
	print "         -l  Show (l)ogs from moirai.pl.\n";
	print "         -q  Use (q)sub or slurm for running daemon [qsub|slurm|openstack].\n";
	print "         -M  (M)ax number of threads (default='1').\n";
	print "         -R  Number of time to (R)epeat loop (default=-1='infinite').\n";
	print "         -s  Loop (s)leep time in second (default=10).\n";
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
############################## helpExec ##############################
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
	print "         -a  Process jobs (a)cross server instead of running on local environment\n";
	print "         -A  Force processes where input->output queries are (A)lready completed\n";
	print "         -b  Specify (b)oolean options of a command line (example -a:\$optionA,-b:\$optionB).\n";
	print "         -c  Specify (c)ontainer image/path for execution for docker or singularity.\n";
	print "         -C  Simple des(C)ription of a command used for output\n";
	print "         -d  Path to a directed acyclic graph (d)atabase directory (default='.').\n";
	print "         -D  (Delim character for splitting filename (None alphabe/number characters+'_')\n";
	print "         -e  d(e)lete database with '\$sub->\$pred->\$obj' format.\n";
	print "         -E  Ignore STD(E)RR if specific regexp is found in STDERR messages.\n";
	print "         -f  Record (f)ilestats[linecount/seqcount/md5/filesize/utime] of output files.\n";
	print "         -F  If specified output (F)ile has empty content, record as error.\n";
	print "         -h  Show (h)elp message.\n";
	print "         -H  Show update (H)istory.\n";
	print "         -i  (i)nput query for select from database in '\$sub->\$pred->\$obj' format.\n";
	print "         -I  (I)mage of OpenStack instance to build and process and process job.\n";
	print "         -j  Upload jobs to a (j)ob server instead of local .moirai2/ctrl/job.\n";
	print "         -l  Show (l)ogs messages from moirai.pl.\n";
	print "         -L  Write (L)ogs to .moirai/daemon/*.stdout and .moirai/damone/*.stderr.\n";
	print "         -m  Approxi(m)ate time to process (default='1'second).\n";
	print "         -M  (M)ax number of threads handled by daemon(default='1').\n";
	print "         -n  (n)egation of input queries meaning if match, don't execute process.\n";
	print "         -N  i(N)crement database with '\$sub->\$pred->\$obj' format.\n";
	print "         -o  (o)utput query for insert to database in '\$sub->\$pred->\$obj' format.\n";
	print "         -O  Ignore STD(O)UT if specific regexp is found in STDOUT message.\n";
	print "         -p  (p)rint command lines instead of executing for test purpose.\n";
	print "         -P  Use user specified tem(P) directory instead of /tmp.\n";
	print "         -q  Use (q)sub or slurm for throwing jobs [qsub|slurm|openstack].\n";
	print "         -Q  (Q)sub/slurm options [qsub/sge/squeue/slurm].\n";
	print "         -r  Print (r)eturn value (in exec mode, stdout is default).\n";
	print "         -s  Loop (s)leep time in second (default=1).\n";
	print "         -S  Implement/import (S)cript code to a command json file.\n";
	print "         -t  Check (t)imestamps of inputs and outputs and execute command if needed.\n";
	print "         -u  (u)pdate database with '\$sub->\$pred->\$obj' format.\n";
	print "         -U  Run in (U)ser mode where input parameters are prompted.\n";
	print "         -v  (v)olume directories to rsync across net.\n";
	print "         -V  Fla(V)or of Openstack instance to build and process job.\n";
	print "         -w  Assign (w)ork id (default is 'local').\n";
	print "         -x  Don't e(x)ecute process, but just submit process.\n";
	print "         -X  Set suffi(X)s of input/output files (format is '\$output.txt').\n";
	print "         -z  Unzip input files before processing.\n";
	print "         -Z  Create done file to signal completion to daemon.\n";
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
############################## helpHistory ##############################
sub helpHistory{
	print "\n";
	print "Program: Similar to unix's history.\n";
	print "\n";
	print "Usage: perl $program_name test\n";
	print "\n";
}
############################## helpHtml ##############################
sub helpHtml{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Print out a HTML representation of a workflow.\n";
	print "\n";
	print "Usage: perl $program_name [Options] MODE > HTML\n";
	print "\n";
	print "       HTML  HTML page displaying information of the database\n";
	print "mode:\n";
	print "   command  Print out commands in HTML format\n";
	print "      form  Print out submit form in HTML format\n";
	print "  function  Print out functions in HTML format\n";
	print "  database  Print out database in HTML format\n";
	print "    schema  Print out schema in HTML format\n";
	print "\n";
	print "Options:\n";
	print "         -d  Directed acyclic graph (d)atabase directory (default='.').\n";
	print "\n";
}
############################## helpLs ##############################
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
	print "         -D  Delim character for splitting filename (None alphabe/number characters+'_')\n";
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
	elsif($command=~/^reprocess$/i){helpReprocess();}
	elsif($command=~/^sortsubs$/i){helpSortSubs();}
	elsif($command=~/^test$/i){helpTest();}
	elsif($command=~/\.json$/){printCommand($command);}
	elsif($command=~/\.(ba)?sh$/){printCommand($command);}
	else{help();terminate(0);}
}
############################## helpOpenstack ##############################
sub helpOpenstack{
	print "\n";
	print "Program: Openstack.\n";
	print "\n";
	print "Usage: perl $program_name openstack\n";
	print "\n";
}
############################## helpReprocess ##############################
sub helpReprocess{
	print "\n";
	print "Program: Reprocess/restart jobs that are stopped in the middle.\n";
	print "\n";
	print "Usage: perl $program_name reprocess PROCESSID\n";
	print "\n";
	print "       PROCESSID  Process ID to restart\n";
	print "\n";
}
############################## helpSortSubs ##############################
sub helpSortSubs{
	print "\n";
	print "Program: Sort perl subs/functions in alphabetical order for a developmental purpose.\n";
	print "         It also updates program_version of moirai2.pl\n";
	print "         Before I update github, I execute this command\n";
	print "\n";
	print "Usage: perl $program_name sortsubs\n";
	print "\n";
}
############################## helpTest ##############################
sub helpTest{
	print "\n";
	print "Program: Runs moirai2 test commands for refactoring process for a developmental purpose.\n";
	print "         Make sure all implemented functions are working correctly\n";
	print "         Before I update github, I execute this command\n";
	print "\n";
	print "Usage: perl $program_name test\n";
	print "\n";
}
############################## historyCommand ##############################
sub historyCommand{
	my @arguments=@_;
	if(scalar(@arguments)>0){
		foreach my $execid(@arguments){
			my $file=getLogFileFromExecid($execid);
			if(defined($file)){system("cat $file");}
		}
		terminate(0);
	}
	my @keys=("execid","status","command");
	my $history=getHistory();
	foreach my $execid(sort{$a cmp $b}keys(%{$history})){
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
	my $process=shift();
	my $vars=shift();
	if(!defined($command)){print STDERR "\$command not defined\n";terminate(1);}
	if(!defined($vars)){print STDERR "\$vars not defined\n";terminate(1);}
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
	if(exists($command->{$urls->{"daemon/remoteserver"}})){
		my $remotepath=$command->{$urls->{"daemon/remoteserver"}};
		my ($username,$servername,$remotedir)=splitServerPath($remotepath);
		$rootdir=$remotedir;#/home/ah3q
		$moiraidir="$remotedir/.moirai2remote";#/home/ah3q/.moirai2remote
		if(system("ssh $username\@$servername mkdir -p $moiraidir")){
			print STDERR "ERROR: Couldn't create '$username\@$servername:$moiraidir' directory.\n";
			terminate(1);
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
	writeProcessArray($process,@array);
}
############################## isHomeDirectory ##############################
sub isHomeDirectory{
	my $directory=shift();
	my $username=`whoami`;chomp($username);
	if($directory=~/^\/home\/$username\/?$/){return 1;}#Linux
	elsif($directory=~/^\/Users\/$username\/?$/){return 1;}#MacOS
	return 0;
}
############################## is_number ##############################

# return 1 if value is number (+/-,decimal,e values are all OK) - 2007/03/09
# If array is an input, returns 1 if values are all numbers
# Undefined, HASH, ARRAY will return 0
# +12.345e+67 or -12.345e-67 are numers
# my $boolean = is_number( @array );
sub is_number{
	if(scalar(@_)==0){return 0;}#it's not number, since it's empty...
	for(@_) {#go through inputs
		if(!defined($_)){return 0;} #not defined -_-;...., so return 0
		if(ref($_)ne""){return0;} #not a scalar reference, scalar values return ""
		if(!/^[\+\-]?\d+(\.\d*)?([Ee][\+\-]?\d+)?$/){return 0;}# not a number
	}
	return 1;# all values are number
}
############################## jobsCommand ##############################
#      | remaining | processing | completed |
# jobA |        10 |         20 |        30 |
# jobB |        10 |         20 |        30 |
# jobC |        10 |         20 |        30 |
sub jobsCommand{
	my $jobs=shift();
	if(!defined($jobs)){$jobs={};}
	my @keys=("job","workid","remaining","processing","completed","error");
	loadJobCounts($jobs,$jobdir,"remaining");
	loadJobCounts($jobs,$processdir,"processing");
	loadJobCounts($jobs,"$logdir/error","error");
	foreach my $dir(getActiveLogDirs($logdir)){loadJobCounts($jobs,$dir,"completed");}
	my @array=();
	my $commands={};
	foreach my $job(keys(%{$jobs})){
		my $command=loadCommandFromURL("$moiraidir/cmd/$job.json",$commands);
		my $key=$job;
		my $wid="";
		if(exists($command->{$urls->{"daemon/description"}})){$key=$command->{$urls->{"daemon/description"}};}
		if(exists($command->{$urls->{"daemon/workid"}})){$wid=$command->{$urls->{"daemon/workid"}};}
		my $hash=$jobs->{$job};
		$hash->{"job"}=$key;
		$hash->{"workid"}=$wid;
		if(!exists($hash->{"remaining"})){$hash->{"remaining"}=0;}
		if(!exists($hash->{"processing"})){$hash->{"processing"}=0;}
		if(!exists($hash->{"completed"})){$hash->{"completed"}=0;}
		if(!exists($hash->{"error"})){$hash->{"error"}=0;}
		push(@array,$hash);
	}
	@array=sort{$a->{"job"}cmp$b->{"job"}||$a->{"workid"}cmp$b->{"workid"}}@array;
	printRows(\@keys,\@array,1);
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
	if(!defined($recursivesearch)){$recursivesearch=-1;}
	foreach my $directory (@directories){
		if(-f $directory){push(@inputfiles,$directory);next;}
		elsif(-l $directory){push(@inputfiles,$directory);next;}
		opendir(DIR,$directory);
		foreach my $file(readdir(DIR)){
			if($file eq "."){next;}
			if($file eq ".."){next;}
			if($file eq""){next;}
			if($file=~/^\./){next;}
			my $path=($directory eq ".")?$file:"$directory/$file";
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
############################## loadCommandFromURL ##############################
sub loadCommandFromURL{
	my $url=shift();
	my $commands=shift();
	if(defined($commands)&&exists($commands->{$url})){return $commands->{$url};}
	if(defined($opt_l)){print getLogtime()."|Loading command JSON: $url\n";}
	my $command=($url=~/\.json$/)?getJson($url):getBash($url);
	if(scalar(keys(%{$command}))==0){print "ERROR: Couldn't load $url\n";terminate(1);}
	$command->{$urls->{"daemon/command"}}=$url;
	my $default=$command->{$urls->{"daemon/default"}};
	if(!defined($default)){$default={};}
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/input"},$default);
	loadCommandFromURLRemoveDollar($command,$urls->{"daemon/output"},$default);
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
	loadCommandFromURLToArray($command,$urls->{"daemon/query/delete"});
	loadCommandFromURLToArray($command,$urls->{"daemon/query/increment"});
	loadCommandFromURLToArray($command,$urls->{"daemon/query/in"});
	loadCommandFromURLToArray($command,$urls->{"daemon/query/not"});
	loadCommandFromURLToArray($command,$urls->{"daemon/query/out"});
	loadCommandFromURLToArray($command,$urls->{"daemon/query/update"});
	handleScript($command);
	if(!exists($command->{$urls->{"daemon/approximate/time"}})){$command->{$urls->{"daemon/approximate/time"}}=1;}
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
############################## loadExecutes ##############################
sub loadExecutes{
	my @jobFiles=@_;
	my $commands=shift();
	my $executes=shift();
	my $execurls=shift();
	my $processes=shift();
	my $newjob=0;
	my @execids=();
	foreach my $execid(sort{$a cmp $b}keys(%{$processes})){
		my $process=$processes->{$execid};
		if(exists($process->{$urls->{"daemon/execute"}})){next;}
		$newjob++;
		my $url=$process->{$urls->{"daemon/command"}};#This can be value or array
		if(ref($url)eq"ARRAY"){print STDERR "Multiple URLs found\n";printTable($url);terminate(1);}
		loadCommandFromURL($url,$commands);
		if(!existsArray($execurls,$url)){push(@{$execurls},$url);}
		if(exists($executes->{$url}->{$execid})){next;}
		$executes->{$url}->{$execid}={};
		$executes->{$url}->{$execid}->{"cmdurl"}=$url;
		$executes->{$url}->{$execid}->{"execid"}=$execid;
		while(my ($key,$val)=each(%{$process})){
			if($key=~/^$url#(.+)$/){
				$key=$1;
				if(!exists($executes->{$url}->{$execid}->{$key})){$executes->{$url}->{$execid}->{$key}=$val;}
				elsif(ref($executes->{$url}->{$execid}->{$key})eq"ARRAY"){push(@{$executes->{$url}->{$execid}->{$key}},$val);}
				else{$executes->{$url}->{$execid}->{$key}=[$executes->{$url}->{$execid}->{$key},$val]}
			}
		}
		push(@execids,$execid);
	}
	return @execids;
}
############################## loadJobCounts ##############################
sub loadJobCounts{
	my $counts=shift();
	my $directory=shift();
	my $label=shift();
	opendir(DIR,$directory);
	foreach my $dirname(readdir(DIR)){#dirname or filename
		if($dirname=~/^\./){next;}
		my $path="$directory/$dirname";
		if(-d $path){
			foreach my $file(getFiles($path)){
				my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,basename($file,".txt"));
				if(!exists($counts->{$cmdid})){$counts->{$cmdid}={};}
				$counts->{$cmdid}->{$label}++;
			}
		}else{
			my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,basename($dirname,".txt"));
			if(!exists($counts->{$cmdid})){$counts->{$cmdid}={};}
			$counts->{$cmdid}->{$label}++;
		}
	}
	closedir(DIR);
}
############################## loadOngoingJobVars ##############################
sub loadOngoingJobVars{
	my $hashs=shift();
	my $directory=shift();
	my $label=shift();
	opendir(DIR,$directory);
	foreach my $dirname(readdir(DIR)){#dirname or filename
		if($dirname=~/^\./){next;}
		my $path="$directory/$dirname";
		if(-d $path){
			foreach my $file(getFiles($path)){
				my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,basename($file,".txt"));
				if(!exists($hashs->{$cmdid})){$hashs->{$cmdid}={};}
				if(!exists($hashs->{$cmdid}->{$label})){$hashs->{$cmdid}->{$label}=[];}
				push(@{$hashs->{$cmdid}->{$label}},loadVarsFromFile($file));
			}
		}else{
			my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,basename($dirname,".txt"));
			if(!exists($hashs->{$cmdid})){$hashs->{$cmdid}={};}
			if(!exists($hashs->{$cmdid}->{$label})){$hashs->{$cmdid}->{$label}=[];}
			push(@{$hashs->{$cmdid}->{$label}},loadVarsFromFile($path));
		}
	}
	closedir(DIR);
}
############################## loadProcessFile ##############################
sub loadProcessFile{
	my $file=shift();
	my $process={};
	my $reader=openFile($file);
	while(<$reader>){
		chomp;
		if(/^\#{40} (.+) \#{40}$/){if($1 eq "time"){last;}else{next;}}
		my ($key,$val)=split(/\t/);
		if(ref($process->{$key})eq"ARRAY"){push(@{$process->{$key}},$val);}
		elsif(exists($process->{$key})){$process->{$key}=[$process->{$key},$val];}
		else{$process->{$key}=$val;}
	}
	close($reader);
	return $process;
}
############################## loadSchema ##############################
sub loadSchema{
	my $file=shift();
	my $indeces={};
	my $nodes=[];
	my $edges=[];
	my $reader=openFile($file);
	while(<$reader>){
		chomp;
		my ($sub,$pre,$obj)=split(/\t/);
		if(!exists($indeces->{$sub})){
			my $index=scalar(%{$indeces});
			$indeces->{$sub}=$index;
			push(@{$nodes},{"data"=>{"id"=>$index,"label"=>$sub}});
		}
		if(!exists($indeces->{$obj})){
			my $index=scalar(%{$indeces});
			$indeces->{$obj}=$index;
			push(@{$nodes},{"data"=>{"id"=>$index,"label"=>$obj}});
		}
		my $subIndex=$indeces->{$sub};
		my $objIndex=$indeces->{$obj};
		my $index=scalar(@{$edges});
		push(@{$edges},{"data"=>{"source"=>$subIndex,"target"=>$objIndex,"label"=>$pre}})
	}
	close($reader);
	my $schema={"nodes"=>$nodes,"edges"=>$edges};
	return $schema;
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
	if(!-e $path){print STDERR "ERROR: Submit file '$path' doesn't exist.\n";terminate(1);}
	my $reader=openFile($path);
	my $hash={};
	my $url;
	my $dagdb;
	while(<$reader>){
		chomp;
		my ($key,$val)=split(/\t/);
		if($key eq "url"){$url=$val;}
		elsif($key eq "dagdb"){$dagdb=$val;}
		else{$hash->{$key}=$val;}
	}
	close($reader);
	if(!defined($url)){
		print STDERR "ERROR: Command URL is not specified in '$path'\n";
		terminate(1);
	}
	my $command=loadCommandFromURL($url,$commands);
	if(defined($dagdb)){$command->{$urls->{"daemon/dagdb"}}=$dagdb;}
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
############################## loadVarsFromFile ##############################
sub loadVarsFromFile{
	my $file=shift();
	my $vars={};
	my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,basename($file,".txt"));
	my $reader=openFile($file);
	while(<$reader>){
		chomp;
		if(/^\#{40} (.+) \#{40}$/){if($1 eq "time"){last;}else{next;}}
		my ($key,$val)=split(/\t/);
		if($key=~/$cmdid.json#(.+)$/){
			$key=$1;
			if(ref($vars->{$key})eq"ARRAY"){push(@{$vars->{$key}},$val);}
			elsif(exists($vars->{$key})){$vars->{$key}=[$vars->{$key},$val];}
			else{$vars->{$key}=$val;}
		}
	}
	close($reader);
	return $vars;
}
############################## logCommand ##############################
sub logCommand{
	my $history=getHistory();
	my $array=[];
	foreach my $execid(sort{$a cmp $b}keys(%{$history})){
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
############################## lsCommand ##############################
sub lsCommand{
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
		my ($writer,$temp)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
		foreach my $line(@lines){print $writer "$line\n";}
		close($writer);
		if(defined($opt_l)){system("perl $program_directory/dag.pl -d $rdfdb import < $temp");}
		else{system("perl $program_directory/dag.pl -q -d $rdfdb import < $temp");}
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
		my $command=loadCommandFromURL($url,$commands);
		my $maxjob=getMaxjobFromApproximateTime($command);
		my @variables=();
		if(exists($command->{$urls->{"daemon/bash"}})&&exists($executes->{$url})){
			my $count=0;
			foreach my $execid(sort{$a cmp $b}keys(%{$executes->{$url}})){
				my $process=$processes->{$execid};
				if($count>=$maxjob){last;}
				my $vars=$executes->{$url}->{$execid};
				initExecute($command,$process,$vars);
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
		if($directory=~/^(.+)\@(.+)\:(.+)/){system("ssh $1\@$2 'mkdir -p $3'");}
		else{system("mkdir -p $directory");}
	}
	return 1;
}
############################## moiraiFinally ##############################
sub moiraiFinally{
	my @execids=@_;
	my $commands=shift(@execids);
	my $processes=shift(@execids);
	my $result=0;
	controlWorkflow();
	foreach my $execid(@execids){
		my $process=$processes->{$execid};
		if(returnError($execid)eq"error"){$result=1;}
		my $cmdurl=$process->{$urls->{"daemon/command"}};
		my $command=loadCommandFromURL($cmdurl,$commands);
		foreach my $returnvalue(@{$command->{$urls->{"daemon/return"}}}){
			my $match="$cmdurl#$returnvalue";
			if($returnvalue eq "stdout"){$match="stdout";}
			elsif($returnvalue eq "stderr"){$match="stderr";}
			returnResult($execid,$match);
		}
	}
	if($result==1){terminate(1);}
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
	my $submitOnly;
	my $quietMode;
	if($mode=~/^submit$/i){
		$submitOnly=1;
		if(scalar(@{$arguments})==1&&fileExists($arguments->[0])){#Load submit file
			my $submitfile=shift(@{$arguments});
			($command,$queryResults)=loadSubmit($submitfile,$commands);
		}else{$mode="exec";}#submit only
	}elsif(defined($opt_x)){$submitOnly=1;$quietMode=1;}
	if($mode=~/^exec$/i){if(scalar(@{$arguments})==0){$mode="command";}}
	if($mode=~/^submit$/){
		#pass
	}elsif($mode=~/\.json$/){
		$command=loadCommandFromURL($mode,$commands);
		reassignWorkidFromCommand($command);
	}elsif($mode=~/\.(ba)?sh$/){
		$command=loadCommandFromURL($mode,$commands);
		reassignWorkidFromCommand($command);
	}elsif($mode=~/^build$/i){
		my @cmdlines=();
		if(scalar(@{$arguments})){foreach my $line(@{$arguments}){push(@cmdlines,$line);}}
		else{while(<STDIN>){chomp;push(@cmdlines,$_);}}
		$command=createNewCommandFromLines(@cmdlines);
	}elsif($mode=~/^reprocess$/i){
		my @ids=();
		if(scalar(@{$arguments})==0){foreach my $line(@{$arguments}){push(@ids,$line);}}
		restartProcess(@ids);
	}elsif($mode=~/^command$/i){
		my @cmdlines=();
		while(<STDIN>){chomp;push(@cmdlines,$_);}
		$command=createNewCommandFromLines(@cmdlines);
	}elsif($mode=~/^exec$/i){
		my $cmdline=join(" ",@{$arguments});
		push(@cmdlines,$cmdline);
		$command=createNewCommandFromLines(@cmdlines);
		$arguments=[];
		if(!defined($opt_r)){$opt_r="stdout";}#Print out stdout for exec
		$sleeptime=1;#To get the result as soon as command is completed.
	}elsif($mode=~/^jobtype$/i){
		printJobType();
		terminate(1);
	}elsif($mode=~/^job$/i){
		printJobCount();
		terminate(1);
	}elsif($mode=~/^process$/i){
		printProcessCount();
		terminate(1);
	}elsif($mode=~/^text$/i){
		my $cmdline=join(" ",@{$arguments});
		push(@cmdlines,$cmdline);
		$command=createNewCommandFromLines(@cmdlines);
		setCommandFromOptions($command);
		assignUserdefinedToCommand($command,$userdefined);
		textCommand($command);
		terminate(1);
	}elsif(!defined($mode)){#Process controls anyway
		my $processes=reloadProcesses($commands);
		controlWorkflow($processes,$commands);
		terminate(1);
	}else{
		print STDERR "ERROR: '$mode' not recognized\n";
		help();
		terminate(1);
	}
	setCommandFromOptions($command);
	assignUserdefinedToCommand($command,$userdefined);
	if($mode=~/^exec$/i){setInputsOutputsFromCommand($command);}
	my $cmdurl=saveCommand($command);
	if($mode=~/^build$/i){print "$cmdurl\n";terminate(0);}
	$command=loadCommandFromURL($cmdurl,$commands);
	if(defined($opt_v)){rsyncProcess(convertToArray($opt_v));}
	controlWorkflow();#handle insert/update/delete
	if(!defined($queryResults)){$queryResults=moiraiProcessQuery($command);}
	my @execids=moiraiPrepare($command,$queryResults,@{$arguments});
	#-j server -x = upload inputs, and quit
	#-j server = upload inputs to server, process at server, wait, and download results
	#-j server -a remote = upload inputs to server, upload inputs to remote, process at remote, wait, download results from remote, download results from server
	if(defined($jobServer)){#-j becomes queServer
		copyProcessToQueServer($jobServer,$remoteServer,$commands,@execids);
	}
	if(defined($submitOnly)){
		if(!defined($quietMode)){print join(" ",@execids)."\n";}
		terminate(0);
	}
	my $processes=moiraiRunExecute($commands,$opt_p,@execids);
	moiraiFinally($commands,$processes,@execids);
}
############################## moiraiPrepare ##############################
#https://moirai2.github.io/schema/daemon/command
#https://moirai2.github.io/schema/daemon/execid
#input and output variables
sub moiraiPrepare{
	my @arguments=@_;
	my $command=shift(@arguments);
	my $queryResults=shift(@arguments);
	my $userdefined=$command->{$urls->{"daemon/userdefined"}};
	my $queryKeys=$command->{$urls->{"daemon/query/in"}};
	my $url=$command->{$urls->{"daemon/command"}};
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	if(scalar(@{$queryResults->[1]})==0){
		if(defined($opt_l)){print STDERR "WARNING: No corresponding data found.\n";}
		if(defined($opt_Z)){touchFile($opt_Z);}
		terminate(0);
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
	my $count=0;
	my $datetime=getDatetime();
	foreach my $hash(@{$queryResults->[1]}){
		my $execid=assignExecid($command,$datetime,$count);
		my $vars=moiraiPrepareVars($hash,$userdefined,\@inputs,\@outputs);
		my $job={};
		$job->{$urls->{"daemon/execid"}}=$execid;
		$job->{$urls->{"daemon/command"}}=$url;
		if(defined($remoteServer)){$job->{$urls->{"daemon/remoteserver"}}=$remoteServer;}
		if(defined($jobServer)){$job->{$urls->{"daemon/queserver"}}=$jobServer;}
		foreach my $key(keys(%{$vars})){$job->{"$url#$key"}=$vars->{$key};}
		push(@jobs,$job);
		$count++;
		if($count>=65536){$datetime+=1;$count=0;}
	}
	@jobs=moiraiPrepareCheck(@jobs);
	if(defined($opt_U)&&scalar(@jobs)>0){
		print "Proceed running ".scalar(@jobs)." jobs [y/n]? ";
		if(!getYesOrNo()){terminate(1);}
	}
	if(defined($opt_P)){print "$opt_P\n";}
	my $dagdb=$command->{$urls->{"daemon/dagdb"}};
	if(moiraiPrepareRemoveFlag($dagdb,$queryKeys,$queryResults)>0){controlWorkflow();}
	my $jdir=$jobdir;
	if(!defined($workid)&&exists($command->{$urls->{"daemon/workid"}})){
		$jdir.="/".$command->{$urls->{"daemon/workid"}};
		mkdir($jdir);
		chmod(0777,$jdir);
	}
	my @execids=writeJobHash($jdir,@jobs);
	return @execids;
}
############################## moiraiPrepareCheck ##############################
sub moiraiPrepareCheck{
	my @jobs=@_;
	my $ongoings={};
	loadOngoingJobVars($ongoings,$jobdir,"registered");
	loadOngoingJobVars($ongoings,$processdir,"ongoing");
	loadOngoingJobVars($ongoings,"$logdir/error","error");
	my @array=();
	foreach my $job(@jobs){
		my $execid=$job->{$urls->{"daemon/execid"}};
		my $url=basename($job->{$urls->{"daemon/command"}},".json");
		my $hash={};
		while(my($key,$val)=each(%{$job})){if($key=~/$url.json#(.+)$/){$hash->{$1}=$val;}}
		if(!exists($ongoings->{$url})){push(@array,$job);next;}
		if(moiraiPrepareMatch($hash,$ongoings->{$url}->{"registered"})){
			print STDERR "#WARNING  '$execid' will not be processed, since same job is currently registered\n";
		}elsif(moiraiPrepareMatch($hash,$ongoings->{$url}->{"ongoing"})){
			print STDERR "#WARNING  '$execid' will not be processed, since same job is currently on going\n";
		}elsif(moiraiPrepareMatch($hash,$ongoings->{$url}->{"error"})){
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
		$hit=1;last;
	}
	return $hit;
}
############################## moiraiPrepareRemoveFlag ##############################
sub moiraiPrepareRemoveFlag{
	my $dagdb=shift();
	my $queryKeys=shift();
	my $queryResults=shift();
	my @queries=();
	foreach my $query(@{$queryKeys}){
		my @tokens=split(/\-\>/,$query);
		if($tokens[1]!~/flag\/(\w+)$/){next;}
		push(@queries,$tokens[0]."\t$dagdb/".$tokens[1]."\t".$tokens[2]);
	}
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
	my $count=0;
	foreach my $query(@queries){
		foreach my $result(@{$queryResults->[1]}){		
			my $line=$query;
			foreach my $key(sort{$b cmp $a}keys(%{$result})){
				my $val=$result->{$key};
				$line=~s/\$$key/$val/g;
			}
			print $writer "$line\n";
			$count++;
		}
	}
	close($writer);
	if($count>0){system("mv $file $deletedir/".basename($file));}
	else{unlink($file);}
	return $count;
}
############################## moiraiPrepareVars ##############################
sub moiraiPrepareVars{
	my $hash=shift();
	my $userdefined=shift();
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
	my $dagdb=$command->{$urls->{"daemon/dagdb"}};
	if(exists($command->{$urls->{"daemon/query/in"}})){
		if(exists($command->{$urls->{"daemon/userdefined"}})){
			my $allDefined=1;
			my $userdefined=$command->{$urls->{"daemon/userdefined"}};
			# query/in is defined by userdefined for test cases
			my @keys=@{$command->{$urls->{"daemon/input"}}};
			my $hash={};
			foreach my $key(@keys){
				if(!exists($userdefined->{$key})){$allDefined=0;}
				$hash->{$key}=$userdefined->{$key};
			}
			if($allDefined){$queryResults=[\@keys,[$hash]];}
			else{$queryResults=getQueryResults($dagdb,$command->{$urls->{"daemon/query/in"}});}
		}else{
			$queryResults=getQueryResults($dagdb,$command->{$urls->{"daemon/query/in"}});
		}
	}elsif(exists($command->{$urls->{"daemon/ls"}})){
		my $keys={};
		foreach my $input(@{$command->{$urls->{"daemon/input"}}}){$keys->{$input}=1;}
		foreach my $output(@{$command->{$urls->{"daemon/output"}}}){$keys->{$output}=1;}
		if(exists($command->{$urls->{"daemon/userdefined"}})){#look for variables in userdefined
			while(my ($key,$val)=each(%{$command->{$urls->{"daemon/userdefined"}}})){while($val=~/\$(\w+)/g){$keys->{$1}=1;}}
		}
		my @keys=();
		my @array=();
		my $paths=$command->{$urls->{"daemon/ls"}};
		if(ref($paths)ne"ARRAY"){$paths=[$paths];}
		foreach my $path(@{$paths}){
			my @files=`ls $path`;
			foreach my $file(@files){
				chomp($file);
				my $h=basenames($file,$opt_D);
				$h=fileStats($file,$opt_o,$h);
				my $h2={};
				foreach my $key(keys(%{$h})){
					if(!exists($keys->{$key})){next;}
					if(!existsArray(\@keys,$key)){push(@keys,$key);}
					$h2->{$key}=$h->{$key};
				}
				push(@array,$h2);
			}
		}
		$queryResults=[\@keys,\@array];
	}
	if(!defined($queryResults)){$queryResults=[[],[{}]];}
	if(defined($opt_t)){checkTimestampsOfOutputs($queryResults,$command);}
	elsif(!defined($opt_A)){removeAlreadyDones($queryResults,$command);}
	checkNotConditions($queryResults,$command);
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
	elsif(getNumberOfJobsRemaining($ids)==0){return $processes;}
	while(true){
		controlWorkflow($processes,$commands);
		if(scalar(@{$execurls})==0&&scalar(keys(%{$executes}))==0&&scalar(keys(%{$processes}))>0){
			my $completed=1;#check all processes are completed
			foreach my $execid(keys(%{$ids})){
				my $process=$processes->{$execid};
				if($process->{$urls->{"daemon/execute"}}eq"completed"){next;}#completed
				if($process->{$urls->{"daemon/execute"}}eq"error"){next;}#completed
				$completed=0;
			}
			if($completed){last;}# completed all jobs
		}
		# no slot to throw job?
		my $jobs_running=getNumberOfJobsRunning();
		if($jobs_running>=$maxThread){sleep($sleeptime);next;}
		# no more job to handle?
		my $job_remaining=getNumberOfJobsRemaining($ids);
		if($job_remaining==0){sleep($sleeptime);next;}
		# Try processing next job, if possible
		my $jobSlot=$maxThread-$jobs_running;
		if($jobSlot<1){sleep($sleeptime);next;}
		getJobFiles($commands,$processes,$jobdir,$jobSlot,$ids);
		if(scalar(keys(%{$processes}))==0){sleep($sleeptime);next;}
		loadExecutes($commands,$executes,$execurls,$processes);
		if(defined($printMode)){printJobs($execurls,$commands,$executes);terminate(0);}
		mainProcess($execurls,$commands,$executes,$processes,$jobSlot);
	}
	controlWorkflow($processes,$commands);
	return $processes;
}
############################## moveOuputsFromWorkdir ##############################
sub moveOuputsFromWorkdir{
	my $command=shift();
	my $process=shift();
	my $workdir=$process->{$urls->{"daemon/workdir"}};
	my @files=listFilesRecursively(undef,undef,-1,$workdir);
	foreach my $file(@files){
		my $dirname=dirname($file);
		my $filename=basename($file);
		if($dirname=~/^$workdir\/(.+)$/){$dirname="$1/";system("mkdir -p $dirname");}
		else{$dirname=".";}
		if(defined($opt_l)){print getLogtime()."|Move $file to $dirname\n";}
		system("mv -f $file $dirname");
	}
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
		if($path=~/\.gz(ip)?$/){return IO::File->new("ssh $1 'gzip -cd $2 2>/dev/null'|");}
		elsif($path=~/\.bz(ip)?2$/){return IO::File->new("ssh $1 'bzip2 -cd $2 2>/dev/null'|");}
		elsif($path=~/\.bam$/){return IO::File->new("ssh $1 'samtools view $2 2>/dev/null'|");}
		else{return IO::File->new("ssh $1 'cat $2 2>/dev/null'|");}
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
	if(!-e "$program_directory/openstack.pl"){print STDERR "ERROR: $program_directory/openstack.pl not found\n";terminate(1);}
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
	if(scalar(@inputs)>0){print STDOUT "#Input: ".join(", ",@{$command->{$urls->{"daemon/input"}}})."\n";}
	if(scalar(@outputs)>0){print STDOUT "#Output: ".join(", ",@{$command->{$urls->{"daemon/output"}}})."\n";}
	print STDOUT "#Bash: ";
	if(ref($command->{$urls->{"daemon/bash"}})ne"ARRAY"){print STDOUT $command->{$urls->{"daemon/bash"}}."\n";}
	else{my $index=0;foreach my $line(@{$command->{$urls->{"daemon/bash"}}}){if($index++>0){print STDOUT "     : "}print STDOUT "$line\n";}}
	if(exists($command->{$urls->{"daemon/description"}})){print STDOUT "#Summary: ".join(", ",@{$command->{$urls->{"daemon/description"}}})."\n";}
	if(exists($command->{$urls->{"daemon/approximate/time"}})){print STDOUT "#ApproximateTime: ".$command->{$urls->{"daemon/approximate/time"}}."\n";}
	if(exists($command->{$urls->{"daemon/maxjob"}})){print STDOUT "#Maxjob: ".$command->{$urls->{"daemon/maxjob"}}."\n";}
	if(exists($command->{$urls->{"daemon/qjobopt"}})){print STDOUT "#qjobopt: ".$command->{$urls->{"daemon/qjobopt"}}."\n";}
	if($command->{$urls->{"daemon/workid"}}>1){print STDOUT "#Workid: ".$command->{$urls->{"daemon/workid"}}."\n";}
	foreach my $script(@{$command->{$urls->{"daemon/script"}}}){
		print STDOUT "#Script: ".$script->{$urls->{"daemon/script/name"}}."\n";
		foreach my $line(@{$script->{$urls->{"daemon/script/code"}}}){print STDOUT "       :$line\n";}
	}
	print STDOUT "\n";
	print "Do you want to write scripts to files [y/n]? ";
	if(getYesOrNo()){
		my $outdir=defined($opt_o)?$opt_o:".";
		mkdir($outdir);
		foreach my $out(writeScript($url,$outdir,$commands)){print STDOUT "$out\n";}
	}
	print STDOUT "\n";
}
############################## printJobCount ##############################
sub printJobCount{
	my $count=`ls $jobdir/ | wc -l`;
	chomp($count);
	if($count=~/\s+(\d+)/){$count=$1;}
	print "$count\n";
}
############################## printJobType ##############################
sub printJobType{
	my @array=();
	my @labels=("command","dateid","workid","time");
	my @files=`ls $jobdir/*`;
		foreach my $file(@files){
		$file=basename($file,".txt");
		chomp($file);
		my ($dateid,$cmdid,$wid,$appTime,@others)=split(/_/,basename($file,".txt"));
		my $hash={};
		$hash->{"command"}=$cmdid;
		$hash->{"dateid"}=$dateid;
		$hash->{"workid"}=$wid;
		$hash->{"time"}=$appTime;
		push(@array,$hash);
	}
	printRows(\@labels,\@array);
}
############################## printJobs ##############################
sub printJobs{
	my $execurls=shift();
	my $commands=shift();
	my $executes=shift();
	for(my $i=0;$i<scalar(@{$execurls});$i++){
		my $url=$execurls->[$i];
		my $command=loadCommandFromURL($url,$commands);
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
############################## printProcessCount ##############################
sub printProcessCount{
	my $count=`ls $processdir/* | wc -l`;
	chomp($count);
	if($count=~/\s+(\d+)/){$count=$1;}
	print "$count\n";
}
############################## printRows ##############################
sub printRows{
	my $keys=shift();
	my $hashtable=shift();
	my $dontAddDollar=shift();
	if(scalar(@{$keys})==0){return;}
	my @lengths=();
	my @labels=();
	if(!defined($dontAddDollar)){foreach my $key(@{$keys}){push(@labels,"\$$key");}}
	else{foreach my $key(@{$keys}){push(@labels,$key);}}
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
			if(is_number($token)){
				$line.="|";
				for(my $k=$l;$k<$lengths[$j];$k++){$line.=" ";}
				$line.="$token";
			}else{
				$line.="|$token";
				for(my $k=$l;$k<$lengths[$j];$k++){$line.=" ";}
			}
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
	if($value eq""){if(defined($default)){$value=$default;}else{terminate(1);}}
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
############################## reassignWorkidFromCommand ##############################
sub reassignWorkidFromCommand{
	my $command=shift();
	if(!exists($command->{$urls->{"daemon/workid"}})){return;}
	$workid=$command->{$urls->{"daemon/workid"}};
	if(defined($opt_l)){print getLogtime()."|Reassigning workid to $workid\n";}
	$jobdir.="/$workid";
	mkdir($jobdir);
	chmod(0777,$jobdir);
}
############################## reloadProcesses ##############################
sub reloadProcesses{
	my $commands=shift();
	my $processes=shift();
	if(!defined($processes)){$processes={};}
	my $throws={};
	# These are the processes that are handled by the local processes
	# Since local processes handles its own complete routine, so don't touch them
	foreach my $throw(getDirs($throwdir)){$throws->{basename($throw)}=1;}
	foreach my $dir(getDirs($processdir)){
		my $basename=basename($dir);
		if(exists($throws->{$basename})){next;}
		foreach my $file(getFiles($dir,$workid)){
			my $execid=basename($file,".txt");
			if(exists($processes->{$execid})){next;}
			my $process=loadProcessFile($file);
			#If processed correctly, it should contain work directory information
			#When job is retrieved from another server, job is first moved to process directory
			#And then server and local processes are created and updated
			if(!exists($process->{$urls->{"daemon/command"}})){next;}
			if(!exists($process->{$urls->{"daemon/workdir"}})){next;}
			$processes->{$execid}=$process;#remember this processes
			my $url=$process->{$urls->{"daemon/command"}};
			loadCommandFromURL($url,$commands);
		}
	}
	return $processes;
}
############################## removeAlreadyDones ##############################
sub removeAlreadyDones{
	my $inputs=shift();
	my $command=shift();
	my $dagdb=$command->{$urls->{"daemon/dagdb"}};
	my $queryKeys=$command->{$urls->{"daemon/query/in"}};
	if(!exists($command->{$urls->{"daemon/query/out"}})&&!exists($command->{$urls->{"daemon/query/update"}})&&!exists($command->{$urls->{"daemon/query/increment"}})){return;}
	my $query=[];
	if(exists($command->{$urls->{"daemon/query/out"}})){push(@{$query},@{$command->{$urls->{"daemon/query/out"}}});}
	if(exists($command->{$urls->{"daemon/query/update"}})){push(@{$query},@{$command->{$urls->{"daemon/query/update"}}});}
	if(exists($command->{$urls->{"daemon/query/increment"}})){push(@{$query},@{$command->{$urls->{"daemon/query/increment"}}});}
	my $outputs=getQueryResults($dagdb,$query);
	my $inputTemp={};
	foreach my $input(@{$inputs->[0]}){$inputTemp->{$input}=1;}
	my $commonTemp={};
	foreach my $output(@{$outputs->[0]}){if(exists($inputTemp->{$output})){$commonTemp->{$output}=1;}}
	my @commonKeys=keys(%{$commonTemp});
	my @kepts=();
	my @removeds=();
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
		if($keep){push(@kepts,$input);}
		else{push(@removeds,$input);}
	}
	$inputs->[1]=\@kepts;
	#Query in contains flagged, but output already exist
	#Do't execute, but remove those flagged ones
	my $flagged;
	foreach my $query(@{$queryKeys}){
		my @tokens=split(/\-\>/,$query);
		if($tokens[1]=~/flag\/(\w+)$/){$flagged=1;last;}
	}
	if($flagged&&scalar(@removeds)>0){
		my $dagdb=$command->{$urls->{"daemon/dagdb"}};
		if(moiraiPrepareRemoveFlag($dagdb,$queryKeys,[$inputs->[0],\@removeds])>0){controlWorkflow();}
		#handle insert/update/delete
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
	if(ref($value)eq"ARRAY"){foreach my $v(@{$value}){if($v=~/^\$(.+)$/){$v=$1;}}}
	elsif($value=~/^\$(.+)$/){$value=$1;}
	return $value;
}
############################## removeFiles ##############################
sub removeFiles{
	my @files=@_;
	foreach my $file(@files){
		if($file=~/^(.+\@.+)\:(.+)$/){system("ssh $1 'rm $2'");}
		else{unlink($file);}
	}
}

############################## removeSlash ##############################
sub removeSlash{
	my $path=shift();
	if($path=~/^(.+)\/+$/){$path=$1;}
	return $path;
}
############################## removeUnusedInstances ##############################
#Remove unused instances with stop files 'instancedir/IP_FLAVOR.stop'
sub removeUnusedInstances{
	my $instanceCount=shift();
	my $instances=shift();
	my @stopFiles=getFilesFromDir("$instancedir/*.stop");
	if(scalar(@stopFiles)==0){return 0;}
	my @ips=();
	my $stopCount=0;
	foreach my $stopFile(@stopFiles){
		my $basename=basename($stopFile,".stop");
		my ($ip,$flavor)=split(/_/,$basename);
		if(defined($opt_l)){print getLogtime()."|Stopping $ip instance node ($instanceCount=>".($instanceCount-1).")\n";}
		my @lines=`openstack.pl remove node $ip`;
		my $result=0;
		foreach my $line(@lines){
			chomp;
			if($line=~/\>Trying to shutoff '.+' instance.+\s+OK/){$result++;}
			if($line=~/\>Waiting '.+' status to be 'shutoff'.+\s+OK/){$result++;}
			if($line=~/\>Deleting '.+' instance.+\s+OK/){$result++;}
		}
		if($result<3){
			print STDERR "#ERROR: Failed to stop daemon for $ip\n";
			#It's not a fatal error, so maybe continue with the daemon process?
			#terminate(1);
		}else{
			$instances->{$flavor}--;
			my $startFile="$instancedir/$basename.start";
			removeFiles($startFile,$stopFile);
			$instanceCount--;
		}
	}
	return $instanceCount;
}
############################## removeWorkdirFromVariableValues ##############################
sub removeWorkdirFromVariableValues{
	my $command=shift();
	my $process=shift();
	my $processLog=shift();
	my $url=$process->{$urls->{"daemon/command"}};
	my $workdir=$process->{$urls->{"daemon/workdir"}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	foreach my $output(@outputs){
		if(!exists($processLog->{"$url#$output"})){next;}
		my $value=$processLog->{"$url#$output"};
		if(ref($value)eq"ARRAY"){
			my @array=();
			foreach my $v(@{$value}){
				if($v=~/^$workdir\/(.+)/){push(@array,$1);}
				else{push(@array,$v);}
			}
			$processLog->{"$url#$output"}=\@array;
		}
		elsif($value=~/^$workdir\/(.+)/){$processLog->{"$url#$output"}=$1;}
	}
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
############################## restartProcess ##############################
sub restartProcess{
	my @ids=@_;
	if(scalar(@ids)==0){
		my $ids=getProcessIds();
		printTable($ids);
	}
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
############################## retrieveStatusOfProcess ##############################
sub retrieveStatusOfProcess{
	my $id=shift();
	my $processfile=getProcessFileFromExecid($id);
	if(defined($processfile)&&$processfile ne ""){return getStatusFromLogFile($processfile);}
	my $logfile=getLogFileFromExecid($id);
	if(!defined($logfile)||$logfile eq""){return "notfound";}
	return getStatusFromLogFile($logfile);
}
############################## returnError ##############################
sub returnError{
	my $execid=shift();
	my $file=getLogFileFromExecid($execid);
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
	my $file=getLogFileFromExecid($execid);
	if(!defined($file)){return;}
	if(defined($sdtoutfh)){*STDOUT=*OLD_STDOUT;}#Return to original STDOUT
	if(defined($sdterrfh)){*STDERR=*OLD_STDERR;}#Return to original STDERR
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
	# --recursive             recurse into directories
	# --copy-links  replace symbolic links with actual files/dirs
	# --keep-dirlinks  don't replace target's symbolic link directory with actual directory
	my $command="rsync --quiet --recursive --copy-links --keep-dirlinks $fromDir $toDir";
	if(defined($opt_l)){print getLogtime()."|Rsync $fromDir => $toDir\n";}
	return system($command);
}
############################## rsyncFileByChecksum ##############################
sub rsyncFileByChecksum{
	my $from=shift();
	my $to=shift();
	if(defined($opt_l)){print getLogtime()."|Rsync $from => $to\n";}
	mkdirs(dirname($to));
	# --quiet                 suppress non-error messages
	# --checksum              skip based on checksum, not mod-time & size
	# --copy-links            transform symlink into referent file/dir
	return system("rsync --quiet --recursive --copy-links --checksum $from $to");
}
############################## rsyncFileByUpdate ##############################
sub rsyncFileByUpdate{
	my $from=shift();
	my $to=shift();
	if(defined($opt_l)){print getLogtime()."|Rsync $from => $to\n";}
	mkdirs(dirname($to));
	# --quiet                 suppress non-error messages
	# --update                skip files that are newer on the receiver
	# --recursive             recurse into directories
	# --copy-links            transform symlink into referent file/dir
	return system("rsync --quiet --recursive --copy-links --update $from $to");
}
############################## rsyncProcess ##############################
sub rsyncProcess{
	my $directories=shift();
	if(!defined($remoteServer)&&!defined($jobServer)){
		print STDERR "#ERROR:  Please specify Server information with '-a' or '-j'\n";
	}
	#Copy directory from server
	if(defined($jobServer)){
		foreach my $directory(@{$directories}){rsyncDirectory("$jobServer/$directory","$rootDir");}
	}
	#Copy directory to remote
	if(defined($remoteServer)){
		foreach my $directory(@{$directories}){rsyncDirectory("$rootDir/$directory",$remoteServer);}
	}
}
############################## runDaemon ##############################
sub runDaemon{
	my @arguments=@_;
	my $completeMode;#complete processed jobs
	my $cronMode;#assign new jobs from cron directory
	my $openstackMode;#deploy new instances to process jobs using OpenStack
	my $processMode;#process data production
	my $retrieveMode;#retrieve jobs from another server/directory
	my $stopMode;#stop daemon mode
	my $submitMode;#assign new jobs from submit directory
	my $terminateMode;#If jobless for few loop, it'll terminate
	foreach my $argument(@arguments){
		if($argument=~/^complete$/i){$completeMode=1;}
		if($argument=~/^cron$/i){$cronMode=1;}
		if($argument=~/^openstack$/i){$openstackMode=1;}
		if($argument=~/^process$/i){$processMode=1;}
		if($argument=~/^retrieve$/i){$retrieveMode=1;}
		if($argument=~/^stop$/i){$stopMode=1;}
		if($argument=~/^submit$/i){$submitMode=1;}
		if($argument=~/^terminate$/i){$terminateMode=1;}
	}
	my $openstackFlavors=defined($openstackMode)?getOpenstackFlavors():{};
	if(defined($opt_b)){
		my $serverpathBuild=handleServer($opt_b);
		my ($username,$servername,$serverdir)=splitServerPath($serverpathBuild);
		my $stopFile="$username\@$servername:$serverdir/$moiraidir/stop.txt";
		if(defined($stopMode)){touchFile($stopFile);terminate(1);}
		elsif(fileExists($stopFile)){removeFiles($stopFile);}
		my $command="perl moirai2.pl";
		if(defined($opt_a)){$command.=" -a $opt_a";}
		if(defined($opt_d)){$command.=" -d $opt_d";}
		if(defined($opt_j)){$command.=" -j $opt_j";}
		if(defined($opt_l)){$command.=" -l";}
		if(defined($opt_L)){$command.=" -L";}
		if(defined($opt_m)){$command.=" -m $opt_m";}
		if(defined($opt_M)){$command.=" -M $opt_M";}
		if(defined($opt_R)){$command.=" -R";}
		if(defined($opt_s)){$command.=" -s $opt_s";}
		if(defined($opt_w)){$command.=" -w $opt_w";}
		$command.=" daemon";
		if(defined($cronMode)){$command.=" cron";}
		if(defined($openstackMode)){$command.=" openstack";}
		if(defined($processMode)){$command.=" process";}
		if(defined($retrieveMode)){$command.=" retrieve";}
		if(defined($submitMode)){$command.=" submit";}
		if(defined($stopMode)){$command.=" stop";}
		rsyncFileByUpdate("moirai2.pl","$serverpathBuild/moirai2.pl");
		rsyncFileByUpdate("dag.pl","$serverpathBuild/dag.pl");
		$command="ssh $username\@$servername 'cd $serverdir;nohup $command &>/dev/null 2>&1 &'";
		if(defined($opt_l)){print getLogtime()."|$command\n";}
		system($command);
		terminate(0);
	}
	my $stopFile="$moiraidir/stop.txt";
	if(defined($stopMode)){system("touch $stopFile");terminate(1);}
	elsif(-e $stopFile){unlink($stopFile);}
	my $commands={};
	my $processes={};
	if(defined($completeMode)){reloadProcesses($commands,$processes);}
	my $runCount=defined($opt_R)?$opt_R:undef;
	my $sleeptime=defined($opt_s)?$opt_s:60;#default is 1 minute
	if(defined($retrieveMode)){
		if(defined($jobServer)){
			my $jobdir="$jobServer/.moirai2/ctrl/job";
			if(!dirExists($jobdir)){print STDERR "#ERROR No jobdir found '$jobdir'\n";terminate(1);}
		}else{
			print STDERR "#ERROR Please specify job server by -j option when using retrieve mode.\n";
			terminate(1);
		}
	}
	if(defined($opt_l)){
		print getLogtime()."|Starting moirai2.pl daemon with modes:\n";
		if(defined($cronMode)){print "                   |Create jobs from cron directory: $crondir\n";}
		if(defined($retrieveMode)){print "                   |Retrieve jobs from job server: $jobServer\n";}
		if(defined($submitMode)){print "                   |Retrieve jobs from submit directory: $submitdir\n";}
		if(defined($openstackMode)){
			my @array=sort{$a cmp $b}keys(%${openstackFlavors});
			print "                   |Openstack with flavors: '".join("' '",@array)."'\n";
		}
		if(defined($processMode)){
			print "                   |Process with $maxThread thread";
			if(defined($workid)){print " with workid: $workid";}
			print "\n";
		}
		if(defined($completeMode)){print "                   |Complete jobs processed by other servers\n";}
		if(defined($terminateMode)){print "                   |Terminate this process when no more jobs were found\n";}
	}
	my @crons=();
	my $cronTime=0;
	my $executes={};
	my $execurls=[];
	my @execids=();
	while(true){
		controlWorkflow($processes,$commands);
		if(defined($submitMode)){#handle submit
			foreach my $file(getFiles($submitdir)){
				my $cmdline="perl $program_directory/moirai2.pl";
				$cmdline.=" submit $file";
				if(defined($opt_l)){print getLogtime()."|$cmdline\n";}
				my @ids=`$cmdline`;
			}
		}
		if(defined($cronMode)){# handle cron
			my $time=checkTimestamp($crondir);
			if($cronTime<$time){#reload if there is new updates
				@crons=listFilesRecursively("(\.json|\.sh)\$",undef,-1,$crondir);
				foreach my $url(@crons){
					my $command=loadCommandFromURL($url,$commands);
					if(exists($command->{$urls->{"daemon/timestamp"}})){next;}
					handleDagdbOption($command);
					$command->{$urls->{"daemon/timestamp"}}=0;
				}
				$cronTime=$time;
			}
			foreach my $url(@crons){
				my $command=loadCommandFromURL($url,$commands);
				if(daemonCheckTimestamp($command)){
					if(bashCommandHasOptions($command)){
						my $dagdb=$command->{$urls->{"daemon/dagdb"}};
						my $cmdline="perl $program_directory/moirai2.pl";
						$cmdline.=" -x";
						$cmdline.=" -d $dagdb";
						$cmdline.=" $url";
						if(defined($opt_l)){print getLogtime()."|$cmdline\n";}
						if(defined($runCount)){my @lines=`$cmdline`;foreach my $line(@lines){print $line;}}
						else{system($cmdline);}
						sleep(1);#to make sure IDs 
					}else{
						my ($writer,$script)=tempfile(DIR=>"/tmp",SUFFIX=>".sh",UNLINK=>1);
						print $writer "bash $url\n";
						close($writer);
						system("bash $script");
					}
				}
			}
		}
		if(defined($openstackMode)){handleOpenstackMode($openstackFlavors);}
		if(defined($retrieveMode)){#get job from the server
			my $jobs_running=getNumberOfJobsRunning();
			my $jobSlot=$maxThread-$jobs_running;
			if($jobSlot<=0){sleep($sleeptime);next;}
			my $jobserverdir="$jobServer/.moirai2/ctrl/job";
			if(defined($workid)){$jobserverdir.="/$workid";}
			getJobFiles($commands,$processes,$jobserverdir,$jobSlot);
			if(defined($processMode)){#download job and process, handle as /tmp
				my @ids=loadExecutes($commands,$executes,$execurls,$processes);
				if(defined($runCount)){push(@execids,@ids);}
				mainProcess($execurls,$commands,$executes,$processes,$jobSlot);
			}else{#Move back from process to job directory
				foreach my $execid(sort{$a cmp $b}keys(%{$processes})){
					my $process=$processes->{$execid};
					my $processfile="$processdir/$processid/$execid.txt";
					my $jobfile="$jobdir/$execid.txt";
					if(defined($opt_l)){print getLogtime()."|Transfering $processfile to $jobfile\n"}
					system("mv $processfile $jobfile");
				}
			}
		}elsif(defined($processMode)){# main mode local
			my $jobs_running=getNumberOfJobsRunning();
			my $jobSlot=$maxThread-$jobs_running;
			if($jobSlot<=0){sleep($sleeptime);next;}
			getJobFiles($commands,$processes,$jobdir,$jobSlot);
			my @ids=loadExecutes($commands,$executes,$execurls,$processes);
			if(defined($runCount)){push(@execids,@ids);}
			mainProcess($execurls,$commands,$executes,$processes,$jobSlot);
		}
		if(defined($terminateMode)){
			my $jobs_running=getNumberOfJobsRunning();
			my $job_remaining=getNumberOfJobsRemaining();
			if($jobs_running==0&&$job_remaining==0){
				if(scalar(keys(%{$processes}))>0){controlWorkflow($processes,$commands);}
				else{
					if(defined($opt_l)){print getLogtime()."|Terminating daemon since no jobs remain\n";}
					if(defined($opt_Z)){touchFile($opt_Z);}
					last;
				}
			}
		}
		if(-e $stopFile){$runCount=-1;last;}
		if(defined($runCount)){$runCount--;if($runCount<0){last;}}
		sleep($sleeptime);
		if(defined($completeMode)){reloadProcesses($commands,$processes);}
	}
	#Wait until job is completed when daemon's loop count is defined
	if(defined($runCount)){
		while(true){
			controlWorkflow($processes,$commands);
			my $jobs_running=getNumberOfJobsRunning();
			if($jobs_running>=$maxThread){sleep($sleeptime);next;}
			my $job_remaining=getNumberOfJobsRemaining();
			if($jobs_running==0&&$job_remaining==0){last;}
			sleep($sleeptime);
		}
		controlWorkflow($processes,$commands);#last update
		moiraiFinally($commands,$processes,@execids);
	}
	if(defined($opt_l)){STDOUT->autoflush(0);}
}
############################## saveCommand ##############################
#Save $command in a json format
sub saveCommand{
	my $command=shift();
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".json",UNLINK=>1);
	print $writer "{";
	print $writer saveCommandSub($command,$urls->{"daemon/bash"});
	print $writer saveCommandSub($command,$urls->{"daemon/command/option"});#-b
	print $writer saveCommandSub($command,$urls->{"daemon/container"});#-c
	print $writer saveCommandSub($command,$urls->{"daemon/description"});#-C
	print $writer saveCommandSub($command,$urls->{"daemon/container/flavor"});#-V
	print $writer saveCommandSub($command,$urls->{"daemon/container/image"});#-I
	print $writer saveCommandSub($command,$urls->{"daemon/error/file/empty"});#-F
	print $writer saveCommandSub($command,$urls->{"daemon/error/stderr/ignore"});#-E
	print $writer saveCommandSub($command,$urls->{"daemon/error/stdout/ignore"});#-O
	print $writer saveCommandSub($command,$urls->{"daemon/file/stats"});#-f
	print $writer saveCommandSub($command,$urls->{"daemon/input"});#-i
	print $writer saveCommandSub($command,$urls->{"daemon/ls"});#automatically set
	print $writer saveCommandSub($command,$urls->{"daemon/approximate/time"});#-m
	print $writer saveCommandSub($command,$urls->{"daemon/output"});#-o
	print $writer saveCommandSub($command,$urls->{"daemon/qjob"});#-q
	print $writer saveCommandSub($command,$urls->{"daemon/qjob/opt"});#-Q
	print $writer saveCommandSub($command,$urls->{"daemon/queserver"});#-j
	print $writer saveCommandSub($command,$urls->{"daemon/query/delete"});#-e
	print $writer saveCommandSub($command,$urls->{"daemon/query/increment"});#-N
	print $writer saveCommandSub($command,$urls->{"daemon/query/in"});#-i
	print $writer saveCommandSub($command,$urls->{"daemon/query/not"});#-n
	print $writer saveCommandSub($command,$urls->{"daemon/query/out"});#-o
	print $writer saveCommandSub($command,$urls->{"daemon/query/update"});#-u
	print $writer saveCommandSub($command,$urls->{"daemon/dagdb"});#-d
	print $writer saveCommandSub($command,$urls->{"daemon/remoteserver"});#-a
	print $writer saveCommandSub($command,$urls->{"daemon/jobserver"});#-j
	print $writer saveCommandSub($command,$urls->{"daemon/return"});#-r
	print $writer saveCommandSub($command,$urls->{"daemon/script"});#-S
	print $writer saveCommandSub($command,$urls->{"daemon/sleeptime"});#-s
	print $writer saveCommandSub($command,$urls->{"daemon/suffix"});#-X
	print $writer saveCommandSub($command,$urls->{"daemon/unzip"});#-z
	print $writer saveCommandSub($command,$urls->{"daemon/workid"});#-w
	print $writer saveCommandSub($command,$urls->{"daemon/userdefined"});
	print $writer "}\n";
	close($writer);
	return saveCommandWrite($file,$command->{$urls->{"daemon/command"}});
}
#Make sure json components are working in JSON format
sub saveCommandSub{
	my $command=shift();
	my $url=shift();
	if(exists($command->{$url})){
		if($url eq $urls->{"daemon/sleeptime"}&&$command->{$url}==1){return;}
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
	my $file=shift();# file is still in /tmp directory
	my $url=shift();# url is speicified by user
	my $json;#final result
	my $md5=getFileMd5($file);#check file content by md5
	my $size=-s $file;#filesize of a temp json
	if(defined($url)){
		#With additional options (like -i,-o), command might be different from user specified command
		#This is a step to make sure command contents are same
		#If md5s/contents are same, URL is used
		#if different newly written (/tmp file) command will be used
		if(defined($md5)){
			my $md=getFileMd5($url);
			if($md eq $md5){$json=$url;}#tmp and URL md5 are same, so OK
		}else{#Check file content by filesize and filecontent(line by line)
			my $size2=-s $url;
			if($size!=$size2){}#size don't match
			elsif(!compareFiles($file,$url)){}#content don't match
			else{$json=$url;}#full match!
		}
		if(defined($json)){unlink($file);return $json;}#No problem at all, so return
	}
	if(defined($md5)){#Search for a same json under cmddir by md5
		if(-e "$cmddir/${md5}${size}.json"){$json="$cmddir/${md5}${size}.json";}#file exists!
		my $size2=-s $json;#Check json filesize for safety
		if($size!=$size2){$json=undef;}#No much, that's not possible!
	}
	if(!defined($json)){#Look for file with same filesize and file content, since couldnt find by md5+filesize
		foreach my $tmp(getFiles($cmddir)){#Go through cmddir
			my $size2=-s $tmp;#Check size
			if($size!=$size2){next;}#Size don't match
			if(compareFiles($file,$url)){$json=$size2;last;}#Check by file content
		}
	}
	if(defined($json)){unlink($file);return $json;}#Previous json already exists, so use that instead of new one
	if(defined($md5)){#New name generated from md5 and filesize
		$json="$cmddir/${md5}${size}.json";#filename generated from md5 and filesize
	}else{# old random name generator
		my ($writer,$tmpfile)=tempfile("j".getDatetime()."XXXX",DIR=>$cmddir,SUFFIX=>".json",UNLINK=>1);
		close($writer);
		$json=$tmpfile;
	}
	system("mv $file $json");
	return $json;
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
############################## setCommandFromOptions ##############################
#2023/02/11
sub setCommandFromOptions{
	my $command=shift();
	if(defined($remoteServer)){$command->{$urls->{"daemon/remoteserver"}}=$remoteServer;}
	if(defined($opt_b)){$command->{$urls->{"daemon/command/option"}}=setCommandOptions($opt_b);}
	if(defined($opt_c)){$command->{$urls->{"daemon/container"}}=$opt_c;}
	if(defined($opt_C)){$command->{$urls->{"daemon/description"}}=$opt_C;}
	if(defined($opt_d)){$command->{$urls->{"daemon/dagdb"}}=$opt_d;}
	if(defined($opt_E)){$command->{$urls->{"daemon/error/stderr/ignore"}}=handleKeys($opt_E);}
	if(defined($opt_f)){$command->{$urls->{"daemon/file/stats"}}=handleKeys($opt_f);}
	if(defined($opt_F)){$command->{$urls->{"daemon/error/file/empty"}}=handleKeys($opt_F);}
	if(defined($opt_I)){$command->{$urls->{"daemon/container/image"}}=$opt_I;}
	if(defined($opt_m)){$command->{$urls->{"daemon/approximate/time"}}=$opt_m;}
	if(defined($opt_q)){$command->{$urls->{"daemon/qjob"}}=$opt_q;}
	if(defined($opt_O)){$command->{$urls->{"daemon/error/stdout/ignore"}}=handleKeys($opt_O);}
	if(defined($opt_Q)){$command->{$urls->{"daemon/qjob/opt"}}=$opt_Q;}
	if(defined($opt_s)){$command->{$urls->{"daemon/sleeptime"}}=$opt_s;}
	if(defined($opt_S)){$command->{$urls->{"daemon/script"}}=$opt_S;loadScripts($command);}
	if(defined($opt_V)){$command->{$urls->{"daemon/container/flavor"}}=$opt_V;}
	if(defined($opt_w)){$command->{$urls->{"daemon/workid"}}=$opt_w;}
	if(defined($opt_z)){$command->{$urls->{"daemon/unzip"}}=$opt_z;}
	my $userdefined={};
	my $suffixs={};
	my $inputKeys={};
	my $outputKeys={};
	if(defined($opt_n)){
		my ($keys,$query)=handleInputOutput($opt_n,$userdefined,$suffixs);
		foreach my $key(@{$keys}){$inputKeys->{$key}=1;}
		if(defined($query)){$command->{$urls->{"daemon/query/not"}}=$query;}
	}
	if(defined($opt_i)){
		my ($keys,$query,$files)=handleInputOutput($opt_i,$userdefined,$suffixs);
		foreach my $key(@{$keys}){$inputKeys->{$key}=1;}
		if(defined($query)){$command->{$urls->{"daemon/query/in"}}=$query;}
		if(defined($files)){$command->{$urls->{"daemon/ls"}}=$files;}
	}
	if(defined($opt_r)){
		my ($keys,$query)=handleInputOutput($opt_r,$userdefined,$suffixs);
		foreach my $key(@{$keys}){if(!exists($inputKeys->{$key})){$outputKeys->{$key}=1;}}
		if(scalar(@{$keys})>0){$command->{$urls->{"daemon/return"}}=$keys;}
	}
	if(defined($opt_u)){
		my ($keys,$query)=handleInputOutput($opt_u,$userdefined,$suffixs);
		foreach my $key(@{$keys}){if(!exists($inputKeys->{$key})){$outputKeys->{$key}=1;}}
		if(defined($query)){$command->{$urls->{"daemon/query/update"}}=$query;}
	}
	if(defined($opt_e)){
		my ($keys,$query)=handleInputOutput($opt_e,$userdefined,$suffixs);
		foreach my $key(@{$keys}){if(!exists($inputKeys->{$key})){$outputKeys->{$key}=1;}}
		if(defined($query)){$command->{$urls->{"daemon/query/delete"}}=$query;}
	}
	if(defined($opt_N)){
		my ($keys,$query)=handleInputOutput($opt_N,$userdefined,$suffixs);
		foreach my $key(@{$keys}){if(!exists($inputKeys->{$key})){$outputKeys->{$key}=1;}}
		if(defined($query)){$command->{$urls->{"daemon/query/increment"}}=$query;}
	}
	if(defined($opt_o)){
		my ($keys,$query)=handleInputOutput($opt_o,$userdefined,$suffixs);
		foreach my $key(@{$keys}){if(!exists($inputKeys->{$key})){$outputKeys->{$key}=1;}}
		if(defined($query)){$command->{$urls->{"daemon/query/out"}}=$query;}
	}
	my @inputs=sort{$a cmp $b}keys(%{$inputKeys});
	if(scalar(@inputs)>0){$command->{$urls->{"daemon/input"}}=\@inputs;}
	my @outputs=sort{$a cmp $b}keys(%{$outputKeys});
	if(scalar(@outputs)>0){$command->{$urls->{"daemon/output"}}=\@outputs;}
	handleDagdbOption($command);
	if(defined($opt_X)){handleInputOutput($opt_X,$userdefined,$suffixs);}
	if(scalar(keys(%{$suffixs}))>0){$command->{$urls->{"daemon/suffix"}}=$suffixs;}
	if(scalar(keys(%{$userdefined}))>0){$command->{$urls->{"daemon/userdefined"}}=$userdefined;}
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
	my $suffixs=exists($command->{$urls->{"daemon/suffix"}})?$command->{$urls->{"daemon/suffix"}}:{};
	my $cmdlines=$command->{$urls->{"daemon/bash"}};
	my $lsInputs=exists($command->{$urls->{"daemon/ls"}})?["filepath","directory","basename","suffix","dir\\d+","base\\d+","suffix\\d+"]:[];
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
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".pl",UNLINK=>1);
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
	else{return (undef,undef,$serverpath);}
}
############################## splitTokenByComma ##############################
sub splitTokenByComma{
	my $line=shift();
	my @tokens=();
	my @blocks=();
	my $currentBlock;
	my $quoted;
	my $escapedKey;
	my $isString;
	my $text="";
	my @bases=split(//,$line);
	my $length=scalar(@bases);
	for(my $i=0;$i<$length;$i++){
		my $base=$bases[$i];
		if($escapedKey){$text.="\\".$base;$escapedKey=undef;next;}
		if($base eq "\\"){
			$escapedKey=1;
			next;
		}elsif($base eq","){
			if($quoted){}#skip since quoted
			elsif(defined($currentBlock)){}
			else{
				push(@tokens,$text);
				$text="";
				next;
			}
		}elsif($base eq "\'"){
			if($quoted){
				if($currentBlock eq "\'"){
					$quoted=undef;
					$currentBlock=undef;
					if(scalar(@blocks)>0){$currentBlock=pop(@blocks);}
					if(!defined($currentBlock)){next;}
				}
			}else{
				$quoted=1;
				if(defined($currentBlock)){push(@blocks,$currentBlock);}
				$currentBlock=$base;
				if(scalar(@blocks)==0){next;}
			}
		}elsif($base eq "\""){
			if($quoted){
				if($currentBlock eq "\""){
					$quoted=undef;
					$currentBlock=undef;
					if(scalar(@blocks)>0){$currentBlock=pop(@blocks);}
					if(!defined($currentBlock)){next;}
				}
			}else{
				$quoted=1;
				if(defined($currentBlock)){push(@blocks,$currentBlock);}
				$currentBlock=$base;
				if(scalar(@blocks)==0){next;}
			}
		}elsif($base eq "("){
			if($quoted){}
			else{
				if(defined($currentBlock)){push(@blocks,$currentBlock);}
				$currentBlock=")";
			}
		}elsif($base eq "{"){
			if($quoted){}
			else{
				if(defined($currentBlock)){push(@blocks,$currentBlock);}
				$currentBlock="}";
			}
		}elsif($base eq "<"){
			if($quoted){}
			else{
				if(defined($currentBlock)){push(@blocks,$currentBlock);}
				$currentBlock=">";
			}
		}elsif($base eq "["){
			if($quoted){}
			else{
				if(defined($currentBlock)){push(@blocks,$currentBlock);}
				$currentBlock="]";
			}
		}elsif($base eq $currentBlock){
			$currentBlock=undef;
			if(scalar(@blocks)>0){$currentBlock=pop(@blocks);}
		}
		$text.=$base;
	}
	if(scalar(@blocks)>0){print STDERR "ERROR while parsing CSV line: $line\n";}
	if(defined($text)){push(@tokens,$text);}
	return \@tokens;
}
############################## startLockfile ##############################
#This make sure that only one program is looking at jobdir or insert/delete/update directories
#jobdir can be set across internet (example,jobdir=ah3q@dgt-ac4:moirai2/.moirai2/ctrl/jobdir)
#Program make sure that the processid is correct before progressing
sub startLockfile{
	my $lockfile=shift();
	my $jobCoolingTime=10;
	my $jobDeleteTime=60;
	my $t1;#time when daemon start looking at
	my $ts1;#timestamp of job lock file
	while(fileExists($lockfile)){
		if(!defined($ts1)){$t1=time();$ts1=checkTimestamp($lockfile);}
		my $t2=time();#current time
		my $diff=$t2-$t1;#diff since daemon start looking at this
		if($diff>$jobDeleteTime){
			my $ts2=checkTimestamp($lockfile);
			if($ts1==$ts2){#make sure lockfile is not updated
				if($opt_l){print "#Ignoring $lockfile since $jobDeleteTime seconds passed\n";}
				last;#don't remove the file, but just progress to writing a lockfile
			}
			#update time and timestamp information and repeat from beginning again
			$t1=$t2;
			$ts1=$ts2;
		}
		my $time=$jobCoolingTime+int(rand(3));#Added random seconds to make sure daemons don't synchronize
		if($opt_l){print getLogtime()."|Waiting $time seconds for the next job offer\n";}
		sleep($time);#acutal sleep
	}
	my $keyid=defined($processid)?$processid:$hostname;
	writeFileContent($lockfile,$keyid);
	sleep(1);#This make sure the lockfile is not updated by other daemon
	my $content=readFileContent($lockfile);
	chomp($content);
	if($content eq $keyid){return 0;}
	else{return 1;}
}
############################## startNewInstances ##############################
sub startNewInstances{
	my $flavorDistributions=shift();
	my $instances=shift();
	foreach my $flavor(keys(%{$flavorDistributions})){
		my $max=$flavorDistributions->{$flavor};
		if($max==0){next;}
		my $count=exists($instances->{$flavor})?$instances->{$flavor}:0;
		if($max<=$count){next;}
		createNewInstances($flavor,$count,$max);
	}
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
############################## terminate ##############################
#Remove process directory and exit
sub terminate{
	my $returnCode=shift();
	if($ignoreTerminateSignal){return;}
	if(defined($processid)){
		if(-d "$processdir/$processid"){rmdir("$processdir/$processid");}
		if(-d "$throwdir/$processid"){rmdir("$throwdir/$processid");}
	}
	if(!defined($returnCode)){$returnCode=0;}
	if(defined($sdtoutfh)){close($sdtoutfh);}
	if(defined($sdterrfh)){close($sdterrfh);}
	exit($returnCode);
}
############################## test ##############################
sub test{
	my @arguments=@_;
	my $hash={};
	if(scalar(@arguments)>0){foreach my $arg(@arguments){$hash->{$arg}=1;}}
	else{for(my $i=1;$i<=9;$i++){$hash->{$i}=1;}}
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
	if(exists($hash->{8})){test8();}
	if(exists($hash->{9})){test9();}
	rmdir("test");
}
sub test0{
}
#Testing sub functions
sub test1{
	#testing handleInputOutput function
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
	#testing handleArguments function
	testSubs("handleArguments(\"line1\",\"line2\",\"input=input.txt\",\"output=output.txt\")",["line1","line2"],{"input"=>"input.txt","output"=>"output.txt"});
	testSubs("handleArguments(\"line=`line1`;\",\"input=input.txt\",\"output=output.txt\")",["line=`line1`"],{"input"=>"input.txt","output"=>"output.txt"});
	#testing handleKeys function
	testSub("handleKeys(\"\\\$input\")",["input"]);
	testSub("handleKeys(\"\\\$input1,\\\$input2\")",["input1","input2"]);
	testSub("handleKeys(\"\\\$input1.txt,input2.html\")",["input1","input2"]);
}
#Testing basic json functionality
sub test2{
	#testing basic input and output functionality
	createFile("test/Akira.txt","A","B","C","D","A","D","B");
	testCommand("perl $program_directory/dag.pl -d test insert root file test/Akira.txt","inserted 1");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -i 'root->file->\$file' exec 'sort \$file'","A","A","B","B","C","D","D");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -i 'root->file->\$file' -r 'output' exec 'sort \$file|uniq -c>\$output' '\$output=test/output.txt'","test/output.txt");
	testCommand("perl $program_directory/dag.pl -d test delete root file test/Akira.txt","deleted 1");
	unlink("test/output.txt");
	unlink("test/Akira.txt");
	#testing json command with default arguments
	createFile("test/A.json","{\"https://moirai2.github.io/schema/daemon/input\":\"\$string\",\"https://moirai2.github.io/schema/daemon/bash\":[\"echo \\\"\$string\\\" > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -r '\$output' test/A.json 'Akira Hasegawa' test/output.txt","test/output.txt");
	testCommand("cat test/output.txt","Akira Hasegawa");
	unlink("test/output.txt");
	testCommand("perl $program_directory/dag.pl -d test insert case1 'string' 'Akira Hasegawa'","inserted 1");
	#testing json command with assign arguments
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -i '\$id->string->\$string' -o '\$id->text->\$output' test/A.json 'output=test/\$id.txt'","");
	testCommand("cat test/case1.txt","Akira Hasegawa");
	testCommand("perl $program_directory/dag.pl -d test select case1 text","case1\ttext\ttest/case1.txt");
	unlink("test/A.json");
	#testing json command with database
	createFile("test/B.json","{\"https://moirai2.github.io/schema/daemon/input\":\"\$input\",\"https://moirai2.github.io/schema/daemon/bash\":[\"sort \$input > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -i '\$id->text->\$input' -o '\$input->sorted->\$output' test/B.json '\$output=test/\$id.sort.txt'","");
	testCommand("cat test/case1.sort.txt","Akira Hasegawa");
	testCommand("perl $program_directory/dag.pl -d test select % 'sorted'","test/case1.txt\tsorted\ttest/case1.sort.txt");
	createFile("test/case2.txt","Hasegawa","Akira","Chiyo","Hasegawa");
	testCommand("perl $program_directory/dag.pl -d test insert case2 'text' test/case2.txt","inserted 1");
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
	#testing input and output with JSON notations
	createFile("test/input.txt","Hello World\nAkira Hasegawa\nTsunami Channel");
	testCommand("perl $program_directory/moirai2.pl -r output -i '{\"input\":\"test/input.txt\"}' -o '{\"output\":\"test/output.txt\"}' exec 'wc -l \$input > \$output'","test/output.txt");
	testCommandRegex("cat test/output.txt","3 test/input.txt");
	unlink("test/output.txt");
	testCommandRegex("perl $program_directory/moirai2.pl -m 5 -w execute -r output -i '\$input' -o '\$output.txt' exec 'wc -l < \$input> \$output;' input=test/input.txt","tmp/output.txt\$");
	unlink("test/input.txt");
	unlink("tmp/output.txt");
	rmdir("tmp");
	system("perl $program_directory/moirai2.pl clean dir");
	#Testing flag functionality, no flag => no execute
	testCommand("perl $program_directory/moirai2.pl -d test/db -i '\$name->flag/needparse->true' -o '\$name->done->true' -r output -s 1 exec 'output=\$name;'","");
	if(-e "test/db/done.txt"){print STDERR "test/db/done.txt shouldn't exist\n";}
	#With flag => execute
	createFile("test/db/flag/needparse.txt","akira\ttrue");
	testCommand("perl $program_directory/moirai2.pl -d test/db -i '\$name->flag/needparse->true' -o '\$name->done->true' -r output -s 1 exec 'output=\$name;'","akira");
	if(-e "test/db/flag/needparse.txt"){print STDERR "test/db/flag/needparse.txt should be deleted\n";}
	testCommand("cat test/db/done.txt","akira\ttrue");
	#With flag, but output already exists => no execute
	createFile("test/db/flag/needparse.txt","akira\ttrue");
	testCommand("perl $program_directory/moirai2.pl -d test/db -i '\$name->flag/needparse->true' -o '\$name->done->true' -r output -s 1 exec 'output=\$name;'","");
	if(-e "test/db/flag/needparse.txt"){print STDERR "test/db/flag/needparse.txt should be deleted\n";}
	unlink("test/db/done.txt");
	rmdir("test/db/flag");
	rmdir("test/db");
}
#Testing exec and bash functionality
sub test3{
	#Testing default exec command
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 exec 'ls $moiraidir/ctrl'","config","delete","increment","insert","instance","job","process","submit","update");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -r '\$output' exec 'output=(`ls $moiraidir/ctrl`);'","config delete increment insert instance job process submit update");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -r output exec 'ls -lt > \$output' '\$output=test/list.txt'","test/list.txt");
	unlink("test/list.txt");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -o '$moiraidir/ctrl->file->\$output' exec 'output=(`ls $moiraidir/ctrl`);'","");
	testCommand("perl $program_directory/dag.pl -d test select $moiraidir/ctrl file","$moiraidir/ctrl\tfile\tconfig","$moiraidir/ctrl\tfile\tdelete","$moiraidir/ctrl\tfile\tincrement","$moiraidir/ctrl\tfile\tinsert","$moiraidir/ctrl\tfile\tinstance","$moiraidir/ctrl\tfile\tjob","$moiraidir/ctrl\tfile\tprocess","$moiraidir/ctrl\tfile\tsubmit","$moiraidir/ctrl\tfile\tupdate");
	testCommand("perl $program_directory/dag.pl -d test delete % % %","deleted 9");
	#Testing exec with assign arguments
	createFile("test/hello.txt","A","B","C","A");
	testCommand("perl $program_directory/moirai2.pl -r output -i input -o output exec 'sort -u \$input > \$output;' input=test/hello.txt output=test/output.txt","test/output.txt");
	testCommand("cat test/output.txt","A\nB\nC");
	unlink("test/output.txt");
	testCommand("echo i|perl $program_directory/moirai2.pl -r out1 exec 'sort -u test/hello.txt > test/output2.txt' > /dev/null","test/hello.txt is [I]nput/[O]utput? test/output2.txt");
	testCommand("cat test/output2.txt","A\nB\nC");
	unlink("test/hello.txt");
	unlink("test/output2.txt");
	#Testing bash script execution
	createFile("test/test.sh","#\$-i \$id->input->\$input","#\$-o \$id->output->\$output.txt","sort \$input | uniq -c > \$output");
	createFile("test/input.txt","A","B","D","C","F","E","G","A","A","A");
	testCommand("perl $program_directory/dag.pl -d test/db insert idA input test/input.txt","inserted 1");
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
	#Testing bash script with arguments
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
	#Testing suffix of temporary output file
	createFile("test/input.txt","Hello","World");
	testCommandRegex("perl $program_directory/moirai2.pl -w execute -i input -r output -X '\$output.txt' exec 'wc -l \$input > \$output' input=test/input.txt","tmp/output.txt\$");
	system("perl $program_directory/moirai2.pl clean dir");
	unlink("tmp/output.txt");
	unlink("test/input.txt");
	rmdir("tmp");
	#Testing multiple inputs
	createFile("test/text.txt","example\tAkira","example\tBen","example\tChris","example\tDavid");
	testCommand("perl $program_directory/moirai2.pl -d test  -i 'example->text->(\$input)' exec 'echo \${input\[\@\]}'","Akira Ben Chris David");
	unlink("test/text.txt");
	#Testing multiple outputs
	testCommand("perl $program_directory/moirai2.pl -d test -o 'name->test->\$output' exec 'output=(\"Akira\" \"Ben\" \"Chris\" \"David\");'","");
	testCommand("cat test/test.txt","name\tAkira","name\tBen","name\tChris","name\tDavid");
	unlink("test/test.txt");
	#query with flag to make sure flags are deleted after execution
	createFile("test/db/input.txt","root\takira.txt");
	createFile("test/test.sh","#\$ -i root->input->\$input","#\$ -r \$stdout","echo \$input");
	testCommand("perl $program_directory/moirai2.pl -s 1 -d test/db test/test.sh","akira.txt");
	createFile("test/test.sh","#\$ -i root->input->\$input","#\$ -i \$input->flag/needparse->true","#\$ -r \$stdout","echo \$input");
	testCommand("perl $program_directory/moirai2.pl -s 1 -d test/db test/test.sh");
	createFile("test/db/flag/needparse.txt","akira.txt\ttrue");
	testCommand("perl $program_directory/moirai2.pl -s 1 -d test/db test/test.sh","akira.txt");
	createFile("test/test.sh","#\$ -i \$input->flag/needparse->true","#\$ -i root->input->\$input","#\$ -r \$stdout","echo \$input");
	testCommand("perl $program_directory/moirai2.pl -s 1 -d test/db test/test.sh");
	createFile("test/db/flag/needparse.txt","akira.txt\ttrue");
	testCommand("perl $program_directory/moirai2.pl -s 1 -d test/db test/test.sh","akira.txt");
	unlink("test/test.sh");
	unlink("test/db/input.txt");
	rmdir("test/db/flag");
	rmdir("test/db");
	#Testing not conditions
	createFile("test/db/input.txt","A\ttest/fileA.txt");
	createFile("test/fileA.txt","Akira");
	testCommand("perl $program_directory/moirai2.pl -d test/db -i '\$key->input->\$path' exec 'ls \$path'","test/fileA.txt");
	testCommand("perl $program_directory/moirai2.pl -d test/db -n '\$path->workflow/file->\$status' -i '\$key->input->\$path' exec 'ls \$path'","test/fileA.txt");
	createFile("test/db/workflow/file.txt","test/fileA.txt\tprocessing");
	testCommand("perl $program_directory/moirai2.pl -d test/db -n '\$path->workflow/file->\$status' -i '\$key->input->\$path' exec 'ls \$path'","");
	createFile("test/db/input.txt","A\ttest/fileA.txt","B\ttest/fileB.txt");
	createFile("test/fileB.txt","Tsunami");
	testCommand("perl $program_directory/moirai2.pl -d test/db -n '\$path->workflow/file->\$status' -i '\$key->input->\$path' -o '\$path->workflow/file->completed' exec 'ls \$path'","test/fileB.txt");
	testCommand("perl $program_directory/moirai2.pl -d test/db -n '\$path->workflow/file->\$status' -i '\$key->input->\$path' exec 'ls \$path'","");
	testCommand("perl $program_directory/moirai2.pl -d test/db -n '\$path->workflow/file->processing' -i '\$key->input->\$path' exec 'ls \$path'","test/fileB.txt");
	testCommand("perl $program_directory/moirai2.pl -d test/db -n '\$path->workflow/file->completed' -i '\$key->input->\$path' exec 'ls \$path'","test/fileA.txt");
	unlink("test/fileA.txt");
	unlink("test/fileB.txt");
	system("rm -r test/db");
}
#Testing build and ls functionality
sub test4{
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
	testCommand("perl $program_directory/dag.pl -d test insert root directory test/dir","inserted 1");
	testCommand("perl $program_directory/moirai2.pl -d test -i 'root->directory->\$input' ls","test/dir/A.txt","test/dir/B.gif","test/dir/C.txt");
	testCommand("perl $program_directory/dag.pl -d test delete % % %","deleted 4");
	#Test ls recursive functionality
	testCommandRegex("perl $program_directory/moirai2.pl -r 0 ls","moirai2\\.pl");
	testCommand("perl $program_directory/moirai2.pl -r 0 -d test ls test");
	testCommand("perl $program_directory/moirai2.pl -r 1 -d test ls test","test/dir/A.txt","test/dir/B.gif","test/dir/C.txt");
	system("rm -r test/dir");
	#Testing ls in -i option with * with different basenames
	createFile("test/input.txt","akira\ttrue");
	testCommand("perl $program_directory/moirai2.pl -i 'test/*' -o '\$output' exec 'wc -l < \$filepath > \$output'");
	testCommandRegex("cat tmp/output","1");
	testCommand("perl $program_directory/moirai2.pl -i 'test/*.txt' -o '\$output.txt' exec 'wc -l < \$filepath > \$output'");
	testCommand("perl $program_directory/moirai2.pl -i 'test/*.txt' -o '\$output.txt' exec 'wc -l < \$filepath > tmp/\$basename.\$suffix'");
	testCommandRegex("cat tmp/input.txt","1");
	unlink("test/input.txt");
	system("rm -r tmp");
	# Testing build functionality
	createFile("test/1.sh","ls \$input > \$output");
	testCommand("perl $program_directory/moirai2.pl -d test -i '\$input' -o '\$output' build < test/1.sh|xargs cat","{\"https://moirai2.github.io/schema/daemon/bash\":\"ls \$input > \$output\",\"https://moirai2.github.io/schema/daemon/input\":\"input\",\"https://moirai2.github.io/schema/daemon/output\":\"output\",\"https://moirai2.github.io/schema/daemon/dagdb\":\"test\"}");
	testCommand("perl $program_directory/moirai2.pl -d test -s 5 -i 'root->directory->\$input' -o 'root->content->\$output' build < test/1.sh|xargs cat","{\"https://moirai2.github.io/schema/daemon/bash\":\"ls \$input > \$output\",\"https://moirai2.github.io/schema/daemon/input\":\"input\",\"https://moirai2.github.io/schema/daemon/output\":\"output\",\"https://moirai2.github.io/schema/daemon/query/in\":\"root->directory->\$input\",\"https://moirai2.github.io/schema/daemon/query/out\":\"root->content->\$output\",\"https://moirai2.github.io/schema/daemon/dagdb\":\"test\",\"https://moirai2.github.io/schema/daemon/sleeptime\":\"5\"}");
	unlink("test/1.sh");
	testCommand("perl $program_directory/moirai2.pl build ls|xargs cat","{\"https://moirai2.github.io/schema/daemon/bash\":\"ls\",\"https://moirai2.github.io/schema/daemon/dagdb\":\".\"}");
	#Testing submit function
	createFile("test/submit.json","{\"https://moirai2.github.io/schema/daemon/bash\":[\"ls test\"],\"https://moirai2.github.io/schema/daemon/return\":\"stdout\",\"https://moirai2.github.io/schema/daemon/sleeptime\":\"1\"}");
	createFile("test/submit.txt","url\ttest/submit.json");
	testCommandRegex("perl $program_directory/moirai2.pl -w execute submit test/submit.txt","^\\d{14}\\w{4}_\\w+\\d+_execute_1\$");
	testCommand("perl $program_directory/moirai2.pl -R 0 daemon process");
	testCommand("perl $program_directory/moirai2.pl -w execute -R 0 daemon process","submit.json");
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
	#Testing cron daemon functionality
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
	#Executing cron script from arguments for testing
	createFile("test/cron.sh","#!/bin/sh","#\$ -d db","#\$ -i \$a->test#B->\$c","#\$ -i \$a->test#D->\$e","#\$ -o \$a->test#F->G","echo \$a \$c \$e");
	testCommand("perl moirai2.pl -r '\$a,\$c,\$e' test/cron.sh a=A c=C e=E","A","C","E");
	testCommand("perl moirai2.pl -r '\$a,\$c,\$e' test/cron.sh a=A c=C e=E");
	testCommand("perl moirai2.pl -r '\$a,\$c,\$e' test/cron.sh a=B c=C e=E","B","C","E");
	system("rm test/cron.sh");
	system("rm -r db");
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
	testCommand("perl $program_directory/moirai2.pl -i 'docker-compose/nginx/public/js/ah3q/*.js' exec 'wc -l <\$filepath>test/\$basename.txt'","");
	testCommandRegex("cat test/moirai2.txt","\\s+\\d+");
	testCommandRegex("cat test/tab.txt","\\s+\\d+");
	unlink("test/moirai2.txt");
	unlink("test/tab.txt");
	unlink("test/dnd.txt");
	unlink("test/graphnet.txt");
	#Testing -i * with $tmpdir
	testCommand("perl /Users/ah3q/Sites/moirai2/moirai2.pl -i 'docker-compose/nginx/public/js/ah3q/*.js' exec 'wc -l <\$filepath>\$tmpdir/tmp.txt;uniq -c \$tmpdir/tmp.txt > test/\$basename.txt;rm \$tmpdir/tmp.txt'","");
	testCommandRegex("cat test/moirai2.txt","\\s+\\d+");
	testCommandRegex("cat test/tab.txt","\\s+\\d+");
	unlink("test/moirai2.txt");
	unlink("test/tab.txt");
	unlink("test/dnd.txt");
	unlink("test/graphnet.txt");
	#Testing -i * with $opt_t
	system("mkdir -p test/in");
	system("mkdir -p test/out");
	createFile("test/in/input1.txt","one");
	createFile("test/in/input2.txt","two");
	sleep(1);
	testCommand("perl $program_directory/moirai2.pl -t -w one -r output -i 'test/in/*.txt' exec 'wc -l <\$filepath>\$output;' 'output=test/out/\$basename.txt'","test/out/input1.txt","test/out/input2.txt");
	testCommandRegex("cat test/out/input1.txt","\\s+\\d+");
	testCommandRegex("cat test/out/input2.txt","\\s+\\d+");
	testCommand("perl $program_directory/moirai2.pl -t -w two -r output -i 'test/in/*.txt' exec 'wc -l <\$filepath>\$output;' 'output=test/out/\$basename.txt'","");
	#input1 modified
	system("touch test/in/input1.txt");
	sleep(1);
	testCommand("perl $program_directory/moirai2.pl -t -w three -r output -i 'test/in/*.txt' exec 'wc -l <\$filepath>\$output;' 'output=test/out/\$basename.txt'","test/out/input1.txt");
	testCommand("perl $program_directory/moirai2.pl -t -w four -r output -i 'test/in/*.txt' exec 'wc -l <\$filepath>\$output;' 'output=test/out/\$basename.txt'","");
	#output2 removed
	unlink("test/out/input2.txt");
	testCommand("perl $program_directory/moirai2.pl -t -w five -r output -i 'test/in/*.txt' exec 'wc -l <\$filepath>\$output;' 'output=test/out/\$basename.txt'","test/out/input2.txt");
	testCommand("perl $program_directory/moirai2.pl -t -w six -r output -i 'test/in/*.txt' exec 'wc -l <\$filepath>\$output;' 'output=test/out/\$basename.txt'","");
	unlink("test/in/input1.txt");
	unlink("test/in/input2.txt");
	unlink("test/out/input1.txt");
	unlink("test/out/input2.txt");
	system("rmdir test/in");
	system("rmdir test/out");
	#daemon process
	testCommandRegex("perl $program_directory/moirai2.pl -r stdout -w exec1 -i input -r stdout submit 'echo HelloWorld'","^\\d{14}\\w{4}_\\w+\\d+_exec1_1\$");
	testCommandRegex("perl $program_directory/moirai2.pl -r stdout -w exec2 -i input -r stdout submit 'echo ByeWorld'","^\\d{14}\\w{4}_\\w+\\d+_exec2_1\$");
	testCommandRegex("perl $program_directory/moirai2.pl -s 1 -R 0 -w exec1 daemon process","HelloWorld");
	testCommandRegex("perl $program_directory/moirai2.pl -s 1 -R 0 -w exec2 daemon process","ByeWorld");
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
#Testing daemon across server part1
sub test6{
	#test subs
	testSub("handleServer(\"$testip\")","$testserver:/home/$testuser");
	testSub("handleServer(\"$testuser\\\@$testip\")","$testserver:/home/$testuser");
	createDirs("$testuser\@$testip:moirai3");
	testSub("handleServer(\"$testuser\\\@$testip:moirai3\")","$testserver:/home/$testuser/moirai3");
	testSub("handleServer(\"$testuser\\\@$testip:/home/$testuser/moirai3\")","$testserver:/home/$testuser/moirai3");
	removeDirs("$testuser\@$testip:moirai3");
	createDirs("moirai3");
	testSub("handleServer(\"moirai3\")","moirai3");
	testSub("handleServer(\"".Cwd::abs_path(".")."/moirai3\")",Cwd::abs_path(".")."/moirai3");
	removeDirs("moirai3");
	my $datetime=getDate();
	#copy scripts
	system("ssh $testserver 'mkdir -p moiraitest'");
	system("scp moirai2.pl $testserver:moiraitest/. 2>&1 1>/dev/null");
	system("scp dag.pl $testserver:moiraitest/. 2>&1 1>/dev/null");
	system("ssh $testserver \"cd moiraitest;perl moirai2.pl clear all\"");
	# submit job on the server, copy job to local, and execute on a local daemon
	system("ssh $testserver 'echo \"Hello World\">moiraitest/input.txt'");
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -w execute1 -i input -o output submit 'wc -l \\\$input > \\\$output;' input=input.txt output=output.txt\"","^\\d{14}\\w{4}_\\w+\\d+_execute1_1\$");
	system("perl $program_directory/moirai2.pl -j $testserver:moiraitest -w execute1 -s 1 -R 0 daemon retrieve");
	system("perl $program_directory/moirai2.pl -w execute1 -s 1 -R 0 daemon process");
	system("ssh $testserver \"cd moiraitest;perl moirai2.pl -s 1 -R 0 daemon complete\"");
	testCommandRegex("ssh $testserver 'cat moiraitest/output.txt'","\\s*1 .*input.txt");
	system("ssh $testserver rm moiraitest/input.txt");
	system("ssh $testserver rm moiraitest/output.txt");
	testCommandRegex("ssh $testserver 'ls moiraitest/.moirai2/log/$datetime/*.txt'","moiraitest/.moirai2/log/\\d+/.+\\.txt");
	# assign on a local daemon and execute on a remote server (-a)
	createFile("input2.txt","Akira Hasegawa");
	testCommand("perl $program_directory/moirai2.pl -s 1 -r output -i input -o output -a $testserver:moiraitest exec 'wc -c \$input > \$output;' input=input2.txt output=output2.txt","output2.txt");
	testCommandRegex("cat output2.txt","15 .*input2.txt");
	unlink("input2.txt");
	unlink("output2.txt");
	removeDirs("$program_directory/.moirai2remote");
	# assign job at server, copy and execute job in one command line (daemon process)
	system("ssh $testserver 'echo \"Hello World\nAkira Hasegawa\">moiraitest/input3.txt'");
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -w execute2 -i input -o output submit 'wc -l \\\$input > \\\$output;' input=input3.txt output=output3.txt\"","^\\d{14}\\w{4}_\\w+\\d+_execute2_1\$");
	testCommandRegex("perl $program_directory/moirai2.pl -w execute2 -j $testserver:moiraitest -s 1 -R 1 daemon retrieve process");
	testCommandRegex("ssh $testserver 'cd moiraitest;perl moirai2.pl -R 0 -w execute2 daemon complete'");
	testCommandRegex("ssh $testserver 'cat moiraitest/output3.txt'","\\s*2 .*input3.txt");
	system("ssh $testserver rm moiraitest/input3.txt");
	system("ssh $testserver rm moiraitest/output3.txt");
	# assign job to the server from local with -j option and process
	createFile("input4.txt","Hello World\nAkira Hasegawa\nTsunami Channel");
	testCommandRegex("perl $program_directory/moirai2.pl -s 1 -j $testserver:moiraitest -w execute3 -i input -o output submit 'wc -l \$input > \$output;' input=input4.txt output=output4.txt","^\\d{14}\\w{4}_\\w+\\d+_execute3_1\$");
	system("ssh $testserver 'cd moiraitest;perl moirai2.pl -w execute3 -s 1 -R 0 daemon process'");
	testCommandRegex("perl $program_directory/moirai2.pl -w execute3 -j $testserver:moiraitest -s 1 -R 0 daemon complete");
	testCommandRegex("cat output4.txt","\\s*3 .*input4.txt");
	unlink("input4.txt");
	unlink("output4.txt");
	#Test singularity with remote server
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver:moiraitest exec uname","Linux");
	testCommandRegex("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver:moiraitest -c ubuntu exec uname -a","^Linux .+ x86_64 x86_64 x86_64 GNU/Linux\$");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver:moiraitest -c ../singularity/lolcow.sif exec cowsay 'Hello World'"," _____________","< Hello World >"," -------------","        \\   ^__^","         \\  (oo)\\_______","            (__)\\       )\\/\\","                ||----w |","                ||     ||");
	#testCommandRegex("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver:moiraitest exec hostname","^moirai\\d+-server");
	testCommandRegex("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver:moiraitest exec hostname","lsbdt01");
	system("ssh $testserver 'rm -r moiraitest'");
}
#Testing daemons across server part2
sub test7{
	#Prepare
	system("ssh $testserver 'mkdir -p moiraitest'");
	system("scp moirai2.pl $testserver:moiraitest/. 2>&1 1>/dev/null");
	system("scp dag.pl $testserver:moiraitest/. 2>&1 1>/dev/null");
	system("ssh $testserver \"cd moiraitest;perl moirai2.pl clear all\"");
	#Testing without workid
	system("ssh $testserver 'echo \"one\">moiraitest/input1.txt'");
	system("ssh $testserver 'echo \"two\">moiraitest/input2.txt'");
	system("ssh $testserver 'echo \"three\">moiraitest/input3.txt'");
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -s 1 -i 'system->ls *.txt->\\\$input' submit 'ls -lt \\\$input'\"","\\d{14}\\w{4}_\\w+\\d+_local_1 \\d{14}\\w{4}_\\w+\\d+_local_1 \\d{14}\\w{4}_\\w+\\d+_local_1");
	testCommandRegex("perl moirai2.pl -s 1 -R 1 -j $testserver:moiraitest daemon retrieve process",".*");
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -s 1 -R 0 daemon complete\"");
	my $date=getDate("");
	testCommandRegex("ssh $testserver \"ls moiraitest/.moirai2/log/$date/\"","\\d{14}\\w{4}_\\w+\\d+_local_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_local_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_local_1.txt");
	system("ssh $testserver 'rm moiraitest/input1.txt moiraitest/input2.txt moiraitest/input3.txt'");
	#Test2 with multiple workids
	system("ssh $testserver \"cd moiraitest;perl moirai2.pl clear all\"");
	system("ssh $testserver 'mkdir -p moiraitest/dir'");
	system("ssh $testserver 'echo \"one\">moiraitest/dir/input1.txt'");
	system("ssh $testserver 'echo \"two\">moiraitest/dir/input2.txt'");
	system("ssh $testserver 'echo \"three\">moiraitest/dir/input3.txt'");
	system("ssh $testserver \"cd moiraitest;perl moirai2.pl clear all\"");
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -s 1 -w execute1 -i 'system->ls dir/*.txt->\\\$input' submit 'ls -lt \\\$input'\"","\\d{14}\\w{4}_\\w+\\d+_execute1_1 \\d{14}\\w{4}_\\w+\\d+_execute1_1 \\d{14}\\w{4}_\\w+\\d+_execute1_1");
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -s 1 -w execute2 -i 'system->ls dir/*.txt->\\\$input' submit 'ls \\\$input'\"","\\d{14}\\w{4}_\\w+\\d+_execute2_1 \\d{14}\\w{4}_\\w+\\d+_execute2_1 \\d{14}\\w{4}_\\w+\\d+_execute2_1");
	testCommandRegex("perl moirai2.pl -s 1 -R 1 -j $testserver:moiraitest daemon retrieve process");
	testCommandRegex("perl moirai2.pl -w execute1 -s 1 -R 1 -j $testserver:moiraitest daemon retrieve process",".*");
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -s 1 -R 0 daemon complete\"");
	testCommandRegex("ssh $testserver \"ls moiraitest/.moirai2/log/$date/\"","\\d{14}\\w{4}_\\w+\\d+_execute1_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_execute1_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_execute1_1.txt");
	testCommandRegex("perl moirai2.pl -w execute2 -s 1 -R 1 -j $testserver:moiraitest daemon retrieve process",".*");
	testCommandRegex("ssh $testserver \"ls moiraitest/.moirai2/log/$date\"","\\d{14}\\w{4}_\\w+\\d+_execute1_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_execute1_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_execute1_1.txt");
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -s 1 -R 0 daemon complete\"");
	testCommandRegex("ssh $testserver \"ls moiraitest/.moirai2/log/$date\"","\\d{14}\\w{4}_\\w+\\d+_execute1_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_execute1_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_execute1_1.txt","\\d{14}\\w{4}_\\w+\\d+_execute2_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_execute2_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_execute2_1.txt");
	system("ssh $testserver \"cd moiraitest;perl moirai2.pl clear all\"");
	#Test3 Checking symbolic links
	system("ssh $testserver 'mkdir -p moiraitest/dir2'");
	system("ssh $testserver 'cd moiraitest/dir2;ln -s ../dir/* .'");
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -s 1 -w execute -i 'system->ls dir2/*.txt->\\\$input' submit 'ls -lt \\\$input'\"","\\d{14}\\w{4}_\\w+\\d+_execute_1 \\d{14}\\w{4}_\\w+\\d+_execute_1 \\d{14}\\w{4}_\\w+\\d+_execute_1");
	testCommandRegex("perl moirai2.pl -s 1 -w execute -R 1 -j $testserver:moiraitest daemon retrieve process",".*");
	testCommandRegex("ssh $testserver \"cd moiraitest;perl moirai2.pl -s 1 -R 0 daemon complete\"",".*");
	testCommandRegex("ssh $testserver \"ls moiraitest/.moirai2/log/$date/\"","\\d{14}\\w{4}_\\w+\\d+_execute_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_execute_1.txt\\n\\d{14}\\w{4}_\\w+\\d+_execute_1.txt");
	system("ssh $testserver 'rm -r moiraitest/dir moiraitest/dir2'");
	system("ssh $testserver \"cd moiraitest;perl moirai2.pl clear all\"");
	system("ssh $testserver 'rm -r moiraitest'");
}
#Testing daemons across server part3
sub test8{
	#Prepare
	system("ssh $testserver 'mkdir -p moiraitest'");
	system("scp moirai2.pl $testserver:moiraitest/. 2>&1 1>/dev/null");
	system("scp dag.pl $testserver:moiraitest/. 2>&1 1>/dev/null");
	system("ssh $testserver \"cd moiraitest;perl moirai2.pl clear all\"");
	#que server with multiple directories input/output
	createFile("A/B/input.txt","Akira","Hasegawa");
	testCommand("perl $program_directory/moirai2.pl -s 1 -i input -o output -x -j $testserver:moiraitest exec 'wc -l < \$input > \$output;' input=A/B/input.txt output=B/A/output.txt");
	testCommandRegex("ssh $testserver 'cat moiraitest/.moirai2/ctrl/job/*_server_1.txt|grep uploaded|grep A/B/input.txt'","_server_1/A/B/input.txt");
	testCommand("ssh $testserver 'cd moiraitest;perl moirai2.pl -s 1 -R 0 daemon process'");
	testCommand("perl moirai2.pl -s 1 -R 0 daemon complete");
	testCommandRegex("cat B/A/output.txt","2");
	system("rm -r B");
	#que server with multiple directories input/output and input already exists in the server
	system("rsync --recursive A $testserver:moiraitest/.");
	testCommand("perl $program_directory/moirai2.pl -s 1 -i input -o output -x -j $testserver:moiraitest exec 'wc -l < \$input > \$output;' input=A/B/input.txt output=B/A/output.txt");
	testCommandRegex("ssh $testserver 'cat moiraitest/.moirai2/ctrl/job/*_server_1.txt|grep A/B/input.txt'","\\\tA/B/input.txt");
	testCommand("ssh $testserver 'cd moiraitest;perl moirai2.pl -s 1 -R 0 daemon process'");
	testCommand("perl $program_directory/moirai2.pl -s 1 -R 0 daemon complete");
	testCommandRegex("cat B/A/output.txt","2");
	system("rm -r A B");
	#job server with multiple directories input/output
	testCommand("ssh $testserver \"cd moiraitest;perl moirai2.pl -s 1 -i input -o output -x exec 'wc -l < \\\$input > \\\$output;' input=A/B/input.txt output=B/A/output.txt\"");
	testCommand("perl $program_directory/moirai2.pl -s 1 -R 0 -j $testserver:moiraitest daemon retrieve");
	testCommand("cat .moirai2/20*/A/B/input.txt","Akira","Hasegawa");
	testCommand("perl $program_directory/moirai2.pl -s 1 -R 0 daemon process");
	testCommandRegex("ssh $testserver 'cat moiraitest/.moirai2/20*/B/A/output.txt'","2");
	testCommand("ssh $testserver 'cd moiraitest;perl moirai2.pl -s 1 -R 0 daemon complete'");
	testCommandRegex("ssh $testserver 'cat moiraitest/B/A/output.txt'","2");
	system("ssh $testserver 'rm -r moiraitest/A moiraitest/B moiraitest/.moirai2'");
	system("rm -r .moirai2");
}
#Testing Hokusai openstack (Takes about 5-10 minutes)
sub test9{
	testCommandRegex("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver:moiraitest -q openstack exec hostname","^moirai\\d+-node-\\d+\$");
	testCommand("perl $program_directory/moirai2.pl -d test -s 1 -a $testserver:moiraitest -c ../singularity/lolcow.sif -q openstack exec cowsay"," __","<  >"," --","        \\   ^__^","         \\  (oo)\\_______","            (__)\\       )\\/\\","                ||----w |","                ||     ||");
}
############################## testCommand ##############################
sub testCommand{
	my @values=@_;
	my $command=shift(@values);
	my $value2=join("\n",@values);
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
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
	my ($writer,$file)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
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
############################## textCommand ##############################
sub textCommand{
	my $command=shift();
	my @keys=();
	my @paths=@{$command->{$urls->{"daemon/ls"}}};
	foreach my $bash(@{$command->{$urls->{"daemon/bash"}}}){
		my $line=$bash;
		foreach my $path(@paths){
			my @files=`ls $path`;
			my @array=();
			foreach my $file(@files){
				chomp($file);
				my $h=basenames($file,$opt_D);
				foreach my $k(sort{$b cmp $a}keys(%{$h})){
					my $v=$h->{$k};
					$line=~s/\$\{$k\}/$v/g;
					$line=~s/\$$k/$v/g;
				}
			}
		}
		print "$line\n";
	}
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
		if(defined($opt_l)){print getLogtime()."|$command\n";}
		if(system($command)==0){sleep(1);}
		else{print STDERR "ERROR: Failed to $command\n";terminate(1);}
	}elsif($qjob eq "openstack"){
		my $flavor=defined($opt_V)?$opt_V:$defaultFlavor;
		my $image=defined($opt_I)?$opt_I:$defaultImage;
		my $command;
		if(defined($servername)){
			$command="ssh $servername \"openstack.pl -q -i $image -f $flavor run bash $path > $stdout 2> $stderr &\"";
		}else{
			$command="openstack.pl -q -i $image -f $flavor run $path > $stdout 2> $stderr &";
		}
		if(system($command)==0){sleep(1);}
		else{print STDERR "ERROR: Failed to $command\n";terminate(1);}
	}elsif(defined($servername)){
		my $command="ssh $servername \"bash $path > $stdout 2> $stderr &\"";
		if(system($command)==0){sleep(1);}
		else{print STDERR "ERROR: Failed to $command\n";terminate(1);}
	}else{
		my $command="bash $path >$stdout 2>$stderr &";
		if(system($command)==0){sleep(1);}
		else{print STDERR "ERROR: Failed to $command\n";terminate(1);}
	}
}
############################## throwJobs ##############################
sub throwJobs{
	my @variables=@_;
	my $url=shift(@variables);
	my $command=shift(@variables);
	my $processes=shift(@variables);
	my $qjob=defined($opt_q)?$opt_q:exists($command->{$urls->{"daemon/qjob"}})?$command->{$urls->{"daemon/qjob"}}:undef;
	my $qjobopt=defined($opt_Q)?$opt_Q:exists($command->{$urls->{"daemon/qjob/opt"}})?$command->{$urls->{"daemon/qjob/opt"}}:undef;
	my $remotepath=exists($command->{$urls->{"daemon/remoteserver"}})?$command->{$urls->{"daemon/remoteserver"}}:undef;
	my $username;
	my $servername;
	my $serverdir;
	if(defined($remotepath)){($username,$servername,$serverdir)=splitServerPath($remotepath);}
	if(scalar(@variables)==0){return;}
	my ($fh,$path)=tempfile("bashXXXXXXXXXX",DIR=>"$rootDir/$throwdir/$processid",SUFFIX=>".sh",UNLINK=>1);
	chmod(0777,$path);
	my $serverfile;
	if(defined($remotepath)){$serverfile="$serverdir/.moirai2remote/".basename($path);}
	my $basename=basename($path,".sh");
	my $stderr=defined($remotepath)?"$serverdir/.moirai2remote/$basename.stderr":"$throwdir/$processid/$basename.stderr";
	my $stdout=defined($remotepath)?"$serverdir/.moirai2remote/$basename.stdout":"$throwdir/$processid/$basename.stdout";
	print $fh "#!/bin/bash\n";
	my @execids=();
	foreach my $var(@variables){
		my $execid=$var->{"execid"};
		if(exists($var->{"singularity"})){
			my $container=exists($command->{$urls->{"daemon/container"}})?$command->{$urls->{"daemon/container"}}:undef;
			my $base=exists($var->{"server"})?"server":"base";
			my $bashfile=$var->{$base}->{"bashfile"};
			my $stdoutfile=$var->{$base}->{"stdoutfile"};
			my $stderrfile=$var->{$base}->{"stderrfile"};
			my $statusfile=$var->{$base}->{"statusfile"};
			my $logfile=$var->{$base}->{"logfile"};
			my $rootdir=$var->{$base}->{"rootdir"};
			my $cmdpath=which("singularity",$cmdpaths,defined($remotepath)?"$username\@$servername":undef);
			print $fh "cd $rootdir\n";
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
			my $container=exists($command->{$urls->{"daemon/container"}})?$command->{$urls->{"daemon/container"}}:undef;
			my $base=defined($var->{"server"})?"server":"base";
			my $bashfile=$var->{"docker"}->{"bashfile"};
			my $stdoutfile=$var->{$base}->{"stdoutfile"};
			my $stderrfile=$var->{$base}->{"stderrfile"};
			my $statusfile=$var->{$base}->{"statusfile"};
			my $logfile=$var->{$base}->{"logfile"};
			my $rootdir=$var->{$base}->{"rootdir"};
			my $cmdpath=which("docker",$cmdpaths,defined($remotepath)?"$username\@$servername":undef);
			print $fh "cd $rootdir\n";
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
	#Upload newly created bash script to a remote server
	if(defined($remotepath)){
		rsyncFileByUpdate($path,"$username\@$servername:$serverfile");
		unlink($path);
		$path="$username\@$servername:$serverfile";
	}
	#reload process from newly written process file
	foreach my $execid(@execids){
		my $process=$processes->{$execid};
		writeProcessArray($process,$urls->{"daemon/execute"}."\tprocessed",$urls->{"daemon/processid"}."\t$processid");
	}
	my $date=getDate("/");
	my $time=getTime(":");
	if(defined($opt_l)){
		my $container=exists($command->{$urls->{"daemon/container"}})?$command->{$urls->{"daemon/container"}}:undef;
		print getLogtime()."|Submitting ".join(" ",@execids);
		if(defined($servername)){print " at '$servername' server";}
		if(defined($container)){print " using '$container' container";}
		if(defined($qjob)){print " through '$qjob' system";}
		print "\n";
	}
	throwBashJob($path,$qjob,$qjobopt,$stdout,$stderr);
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
############################## uploadCommandToQueServer ##############################
sub uploadCommandToQueServer{
	my $process=shift();
	my $remotepath=shift();
	my ($username,$servername,$serverdir)=splitServerPath($remotepath);
	if(!exists($process->{$urls->{"daemon/command"}})){
		print STDERR "ERROR: Command not specified in job file\n";
		terminate(1);
	}
	my $path=$process->{$urls->{"daemon/command"}};
	my $filepath="$username\@$servername:";
	if(defined($serverdir)){$filepath.="$serverdir/$path";}
	else{$filepath.=$path;}
	mkdirs(dirname($path));
	rsyncFileByUpdate($path,$filepath);
	return $path;
}
############################## uploadInputsToQueServer ##############################
# upload inputs to job server
sub uploadInputsToQueServer{
	my $command=shift();
	my $process=shift();
	my $workdir=shift();
	my $serverpath=shift();
	if(!exists($command->{$urls->{"daemon/input"}})){return;}
	my $url=$process->{$urls->{"daemon/command"}};
	my $execid=$process->{$urls->{"daemon/execid"}};
	foreach my $input(@{$command->{$urls->{"daemon/input"}}}){
		if(!exists($process->{"$url#$input"})){next;}
		my $inputfile=$process->{"$url#$input"};
		if(!fileExists($inputfile)){next;}
		if(fileExists("$serverpath/$inputfile")){next;}
		my $quefile="$workdir/$inputfile";
		rsyncFileByUpdate($inputfile,"$serverpath/$quefile");
		$process->{"$url#$input"}=$quefile;
		push(@{$process->{$urls->{"daemon/uploaded"}}},$quefile);
	}
}
############################## uploadInputsToRemoteServer ##############################
sub uploadInputsToRemoteServer{
	my $command=shift();
	my $process=shift();
	my $array=shift();
	if(!exists($command->{$urls->{"daemon/remoteserver"}})){next;}
	my $remotepath=$command->{$urls->{"daemon/remoteserver"}};
	my $url=$process->{$urls->{"daemon/command"}};
	my $execid=$process->{$urls->{"daemon/execid"}};
	my $workdir=".moirai2remote/$execid";
	if(exists($command->{$urls->{"daemon/input"}})){
		foreach my $input(@{$command->{$urls->{"daemon/input"}}}){
			if(!exists($process->{"$url#$input"})){next;}
			my $inputfile=$process->{"$url#$input"};
			my $fromFile="$rootDir/$inputfile";
			my $toFile="$workdir/$inputfile";
			rsyncFileByUpdate($fromFile,"$remotepath/$toFile");
			$process->{"$url#$input"}=$toFile;
		}
	}
	$process->{$urls->{"daemon/download/remoteserver"}}="true";
	$process->{$urls->{"daemon/delete/inputs"}}="true";
}
############################## uploadWorkdirToJobServer ##############################
# Moirai daemon looks for a string "completed" in a status file and proceed to completion.
# If output files are huge, there is a chance complete process is executed before uploads are completed.
# To avoid this, we temporary move the status file to /tmp directory and upload all files beforehand.
# After completion, status file will be uploaded to the server.
# Moirai daemon at the server might look for status file, so "touch" is used to create empty file.
sub uploadWorkdirToJobServer{
	my $process=shift();
	my $serverpath=$process->{$urls->{"daemon/jobserver"}};
	my $workdir=$process->{$urls->{"daemon/workdir"}};
	my $execid=$process->{$urls->{"daemon/execid"}};
	my $todir="$serverpath/.moirai2/";
	my $statusFrom="$workdir/status.txt";
	my $statusTo="$serverpath/.moirai2/$execid/status.txt";
	my ($tmpwriter,$tmpfile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
	close($tmpwriter);
	system("mv $statusFrom $tmpfile");
	rsyncDirectory($workdir,$todir);
	system("scp $tmpfile $statusTo 2>&1 1>/dev/null");
	system("mv $tmpfile $statusFrom");
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
	my ($writer,$tmpfile)=tempfile(DIR=>"/tmp",SUFFIX=>".txt",UNLINK=>1);
	foreach my $line(@array){print $writer "$line\n";}
	close($writer);
	if($file=~/^(.+\@.+)\:(.+)$/){system("scp $tmpfile $1:$2 2>&1 1>/dev/null");unlink($tmpfile);}
	else{system("mv $tmpfile $file");}
}
############################## writeJobHash ##############################
sub writeJobHash{
	my @hashs=@_;
	my $jobdir=shift(@hashs);
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
# write new information to process and also update process hashtable also
sub writeProcessArray{
	my @lines=@_;
	my $process=shift(@lines);
	my $execid=$process->{$urls->{"daemon/execid"}};
	my $processid=$process->{$urls->{"daemon/processid"}};
	my $processfile="$processdir/$processid/$execid.txt";
	if(!-e $processfile){#process handled by other servers
		my @files=listFilesRecursively("$execid\.txt\$",undef,1,$processdir);
		if(scalar(@files)==1){$processfile=$files[0];}
	}
	open(OUT,">>$processfile");
	foreach my $element(@lines){
		print OUT "$element\n";
		my ($key,$val)=split(/\t/,$element);
		if(ref($process->{$key})eq"ARRAY"){push(@{$process->{$key}},$val);}
		elsif(exists($process->{$key})){$process->{$key}=[$process->{$key},$val];}
		else{$process->{$key}=$val;}
	}
	close(OUT);
	return $processfile;
}
############################## writeProcessToTmp ##############################
sub writeProcessToTmp{
	my $process=shift();
	my ($writer,$tmpfile)=tempfile(UNLINK=>1);
	foreach my $key(sort{$a cmp $b}keys(%{$process})){
		my $val=$process->{$key};
		if(ref($val)eq"ARRAY"){foreach my $v(@{$val}){print $writer "$key\t$v\n";}}
		else{print $writer "$key\t$val\n";}
	}
	close($writer);
	chmod(0755,$tmpfile);
	return $tmpfile;
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
	if(exists($command->{$urls->{"daemon/bash"}})){
		push(@outs,$outfile);
		open(OUT,">$outfile");
		foreach my $line(@{$command->{$urls->{"daemon/bash"}}}){
			$line=~s/\$workdir\///g;
			print OUT "$line\n";
		}
		close(OUT);
	}
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
