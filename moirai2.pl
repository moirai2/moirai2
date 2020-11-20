#!/usr/bin/perl
use strict 'vars';
use Cwd;
use File::Basename;
use File::Temp;
use FileHandle;
use Getopt::Std;
use DBI;
use LWP::UserAgent;
use HTTP::Request;
use Time::Local;
use Time::localtime;
use File::Temp qw/tempfile tempdir/;
############################## HEADER ##############################
my ($program_name,$prgdir,$program_suffix)=fileparse($0);
$prgdir=Cwd::abs_path($prgdir);
my $program_path="$prgdir/$program_name";
############################## OPTIONS ##############################
use vars qw($opt_c $opt_d $opt_g $opt_G $opt_h $opt_H $opt_i $opt_l $opt_m $opt_o $opt_p $opt_q $opt_r $opt_s);
getopts('c:d:g:G:hHi:lm:o:pqr:s:');
############################## CONFIG ##############################
my $udockerDirectory="/work/ah3q/udocker";
my $singularityDirectory="/work/ah3q/singularity";
############################## URLs ##############################
my $urls={};
$urls->{"daemon"}="https://moirai2.github.io/schema/daemon";
$urls->{"daemon/select"}="https://moirai2.github.io/schema/daemon/select";
$urls->{"daemon/insert"}="https://moirai2.github.io/schema/daemon/insert";
$urls->{"daemon/delete"}="https://moirai2.github.io/schema/daemon/delete";
$urls->{"daemon/update"}="https://moirai2.github.io/schema/daemon/update";
$urls->{"daemon/import"}="https://moirai2.github.io/schema/daemon/import";
$urls->{"daemon/input"}="https://moirai2.github.io/schema/daemon/input";
$urls->{"daemon/inputs"}="https://moirai2.github.io/schema/daemon/inputs";
$urls->{"daemon/output"}="https://moirai2.github.io/schema/daemon/output";
$urls->{"daemon/return"}="https://moirai2.github.io/schema/daemon/return";
$urls->{"daemon/bash"}="https://moirai2.github.io/schema/daemon/bash";
$urls->{"daemon/script"}="https://moirai2.github.io/schema/daemon/script";
$urls->{"daemon/script/code"}="https://moirai2.github.io/schema/daemon/script/code";
$urls->{"daemon/script/name"}="https://moirai2.github.io/schema/daemon/script/name";
$urls->{"daemon/maxjob"}="https://moirai2.github.io/schema/daemon/maxjob";
$urls->{"daemon/singlethread"}="https://moirai2.github.io/schema/daemon/singlethread";
$urls->{"daemon/qsubopt"}="https://moirai2.github.io/schema/daemon/qsubopt";
$urls->{"daemon/command"}="https://moirai2.github.io/schema/daemon/command";
$urls->{"daemon/execute"}="https://moirai2.github.io/schema/daemon/execute";
$urls->{"daemon/stderr"}="https://moirai2.github.io/schema/daemon/stderr";
$urls->{"daemon/stdout"}="https://moirai2.github.io/schema/daemon/stdout";
$urls->{"daemon/timeended"}="https://moirai2.github.io/schema/daemon/timeended";
$urls->{"daemon/timestarted"}="https://moirai2.github.io/schema/daemon/timestarted";
$urls->{"daemon/timethrown"}="https://moirai2.github.io/schema/daemon/timethrown";
$urls->{"daemon/unzip"}="https://moirai2.github.io/schema/daemon/unzip";
$urls->{"daemon/md5"}="https://moirai2.github.io/schema/daemon/md5";
$urls->{"daemon/filesize"}="https://moirai2.github.io/schema/daemon/filesize";
$urls->{"daemon/linecount"}="https://moirai2.github.io/schema/daemon/linecount";
$urls->{"daemon/seqcount"}="https://moirai2.github.io/schema/daemon/seqcount";
$urls->{"daemon/description"}="https://moirai2.github.io/schema/daemon/description";
$urls->{"daemon/docker"}="https://moirai2.github.io/schema/daemon/docker";
############################## HELP ##############################
sub help{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Handles MOIRAI2 command with SQLITE3 database.\n";
	print "Version: 2020/11/05\n";
	print "Author: Akira Hasegawa (akira.hasegawa\@riken.jp)\n";
	print "\n";
	print "Usage: perl $program_name [Options] COMMAND\n";
	print "\n";
	print "Commands: daemon   Run daemon\n";
	print "          file     Checks file information\n";
	print "          ls       list directories/files\n";
	print "          command  Execute from user specified command instead of a command json\n";
	print "          loop     Loop check and execution indefinitely \n";
	print "          script   Retrieve scripts and bash files from a command json\n";
	print "          test     For development purpose\n";
	print "\n";
	print "############################## Default Usage ##############################\n";
	print "\n";
	print "Program: Executes MOIRAI2 command of a spcified URL json.\n";
	print "\n";
	print "Usage: perl $program_name [Options] JSON/BASH [ASSIGN/ARGV ..]\n";
	print "\n";
	print "       JSON  URL or path to a command json file (from https://moirai2.github.io/command/).\n";
	print "       BASH  URL or path to a command bash file (from https://moirai2.github.io/workflow/).\n";
	print "     ASSIGN  Assign a MOIRAI2 variables with '\$VAR=VALUE' format.\n";
	print "       ARGV  Arguments for input/output parameters.\n";
	print "\n";
	print "Options: -c  Use container for execution [docker,udocker,singularity].\n";
	print "         -d  RDF sqlite3 database (default='rdf.sqlite3').\n";
	print "         -h  Show help message.\n";
	print "         -H  Show update history.\n";
	print "         -i  Input query for select in '\$sub->\$pred->\$obj' format.\n";
	print "         -l  Show STDERR and STDOUT logs.\n";
	print "         -m  Max number of jobs to throw (default='5').\n";
	print "         -o  Output query for insert in '\$sub->\$pred->\$obj' format.\n";
	print "         -p  Prompt input parameter(s) to user.\n";
	print "         -q  Use qsub for throwing jobs.\n";
	print "         -r  Print return value.\n";
	print "         -s  Loop second (default='10').\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "1) perl $program_name https://moirai2.github.io/command/text/sort.json\n";
	print " - Executes a sort command with user prompt for input.\n";
	print "\n";
	print "2) perl $program_name -h https://moirai2.github.io/command/text/sort.json\n";
	print " - Shows information of a command.\n";
	print "\n";
	print "3) perl $program_name https://moirai2.github.io/command/text/sort.json input.txt\n";
	print " - Executes a sort command by specifying input with arguments.\n";
	print " - Output will be sotred in rdf/work.XXXXXXXXX/ directory.\n";
	print "\n";
	print "4) perl $program_name https://moirai2.github.io/command/text/sort.json input.txt output.txt\n";
	print " - Executes a sort command by specifying input and output with arguments.\n";
	print " - By specifying output path in argument, output will be saved at specified path.\n";
	print "\n";
	print "5) perl $program_name https://moirai2.github.io/command/text/sort.json '\$input=input.txt' '\$output=output.txt'\n";
	print " - Executes a sort command by specifying input and output with variables.\n";
	print " - Input and output variables can be assigned with '='.\n";
	print "\n";
	print "6) perl $program_name -i 'A->#input->\$input' -o 'A->#output->\$output' https://moirai2.github.io/command/text/sort.json\n";
	print " - Executes a sort command with a RDF database and updates.\n";
	print "\n";
	if(defined($opt_H)){
		print "############################## Updates ##############################\n";
		print "\n";
		print "2020/11/11  Added 'singularity' to container function.\n";
		print "2020/11/06  Updated help and daemon functionality.\n";
		print "2020/11/05  Added 'ls' function.\n";
		print "2020/10/09  Repeat functionality removed.\n";
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
		print "2019/01/17  Subdivide RDF database, revised execute flag to have instance in between.\n";
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
		print "2018/02/01  Created to throw jobs registered in RDF SQLite3 database.\n";
		print "\n";
	}
	exit(0);
}
sub help_file{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Check and store file information to the database.\n";
	print "\n";
	print "Usage: perl $program_name [Options] file\n";
	print "\n";
	print "Options: -d  RDF sqlite3 database (default='rdf.sqlite3').\n";
	print "         -i  Input query for select in '\$sub->\$pred->\$obj' format.\n";
	print "         -o  Output query for insert in '\$sub->\$pred->\$obj' format.\n";
	print "\n";
	print "Variables:\n";
	print "  \$linecount   Print line count of a file (Can take care of gzip and bzip2).\n";
	print "  \$seqcount    Print sequence count of a FASTA/FASTQ files.\n";
	print "  \$filesize    Print size of a file.\n";
	print "  \$md5         Print MD5 of a file.\n";
	print "  \$timestamp   Print time stamp of a file.\n";
	print "  \$owner       Print owner of a file.\n";
	print "  \$group       Print group of a file.\n";
	print "  \$permission  Print permission of a file.\n";
	print "\n";
}
sub help_loop{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Check for Moirai2 commands every X seconds and execute.\n";
	print "\n";
	print "Usage: perl $program_name [Options] loop\n";
	print "\n";
	print "Options: -d  RDF sqlite3 database (default='rdf.sqlite3').\n";
	print "         -l  Show STDERR and STDOUT logs.\n";
	print "         -m  Max number of jobs to throw (default='5').\n";
	print "         -q  Use qsub for throwing jobs(default='bash').\n";
	print "         -s  Loop second (default='no loop').\n";
	print "\n";
}
sub help_command{
	print "\n";
	print "############################## HELP ##############################\n";
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
	print "Options: -c  Use container for execution [docker,udocker,singularity].\n";
	print "         -d  RDF sqlite3 database (default='rdf.sqlite3').\n";
	print "         -i  Input query for select in '\$sub->\$pred->\$obj' format.\n";
	print "         -l  Show STDERR and STDOUT logs.\n";
	print "         -m  Max number of jobs to throw (default='5').\n";
	print "         -o  Output query for insert in '\$sub->\$pred->\$obj' format.\n";
	print "         -q  Use qsub for throwing jobs.\n";
	print "         -r  Print return value.\n";
	print "         -s  Loop second (default='10').\n";	print "\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "1) perl $program_name -i 'A->#input->\$input' -o 'A->#output->\$output' command << 'EOS'\n";
	print "output=sort/\${input.basename}.txt\n";
	print "sort \$input > \$output\n";
	print "EOS\n";
	print " - Creates directory and store information to database.\n";
	print "\n";
}
sub help_script{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Retrieves script and bash files from URL and save them to a directory.\n";
	print "\n";
	print "Usage: perl $program_name [Options] script JSON\n";
	print "\n";
	print "       JSON  URL or path to a command json file (from https://moirai2.github.io/command/).\n";
	print "\n";
	print "Options: -o  Output directory (default='.').\n";
	print "\n";
}
sub help_daemon{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Look for Other moirai2 databases under directory and run database once if it is updated.\n";
	print "\n";
	print "Usage: perl $program_name [Options] daemon DIR\n";
	print "\n";
	print "       DIR  Directories to look for.  Default is current directory.\n";
	print "\n";
	print "Options: -o  Log output directory (default='log').\n";
	print "         -r  Recursive search through a directory (default='0').\n";
	print "         -s  Loop second (default='10 sec').\n";
	print "\n";
}
sub help_ls{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: List files/directories and store path information to DB.\n";
	print "\n";
	print "Usage: perl $program_name [Options] ls DIR DIR2 ..\n";
	print "\n";
	print "        DIR  Directory to search for (if not specified, DIR='.').\n";
	print "\n";
	print "Options: -d  RDF sqlite3 database (default='rdf.sqlite3').\n";
	print "         -g  grep specific string\n";
	print "         -G  ungrep specific string\n";
	print "         -o  Output query for insert in '\$sub->\$pred->\$obj' format.\n";
	print "         -r  Recursive search (default=0)\n";
	print "\n";
	print "Variables: \$path, \$directory, \$filename, \$basename, \$suffix, \$dirX (X=0~9), \$baseX (X=0~9)\n";	
	print "\n";
	print "Example: perl $program_name -d DB -r 0 -g GREP -G UNREP -o '\$basename->#id->\$path' ls DIR DIR2 ..\n";
	print "\n";
}
############################## MAIN ##############################
my $commands={};
if(defined($opt_h)&&$ARGV[0]=~/\.json$/){printCommand($ARGV[0],$commands);exit(0);}
if(defined($opt_h)&&$ARGV[0]=~/\.(ba)?sh$/){printWorkflow($ARGV[0],$commands);exit(0);}
if(scalar(@ARGV)>0&&$ARGV[0]eq"daemon"&&defined($opt_h)){help_daemon();exit(0);}
if(scalar(@ARGV)>0&&$ARGV[0]eq"ls"&&defined($opt_h)){help_ls();exit(0);}
if(scalar(@ARGV)>0&&$ARGV[0]eq"script"&&defined($opt_h)){help_script();exit(0);}
if(scalar(@ARGV)>0&&$ARGV[0]eq"command"&&defined($opt_h)){help_command();exit(0);}
if(scalar(@ARGV)>0&&$ARGV[0]eq"loop"&&defined($opt_h)){help_loop();exit(0);}
if(scalar(@ARGV)>0&&$ARGV[0]eq"file"&&defined($opt_h)){help_file();exit(0);}
if(defined($opt_h)||defined($opt_H)||scalar(@ARGV)==0){help();}
my $newExecuteQuery="select distinct n.data from edge as e1 inner join edge as e2 on e1.object=e2.subject inner join node as n on e2.object=n.id where e1.predicate=(select id from node where data=\"".$urls->{"daemon/execute"}."\") and e2.predicate=(select id from node where data=\"".$urls->{"daemon/command"}."\")";
my $rdfdb=(defined($opt_d))?$opt_d:"rdf.sqlite3";
my $rootdir=absolutePath(dirname($rdfdb));
my $basename=basename($rdfdb,".sqlite3");
my $bindir="$rootdir/bin";
my $workdir="$rootdir/$basename";
my $ctrldir="$rootdir/$basename/ctrl";
my $home=`echo \$HOME`;chomp($home);
my $exportpath="$bindir:$home/bin:\$PATH";
my $sleeptime=defined($opt_s)?$opt_s:10;
my $maxjob=defined($opt_m)?$opt_m:5;
my $loopMode=(scalar(@ARGV)>0&&$ARGV[0]eq"loop")?1:0;
if($ARGV[0] eq "daemon"){shift(@ARGV);daemon(@ARGV);exit(0);}
if($ARGV[0] eq "test"){shift(@ARGV);test();exit(0);}
if($ARGV[0] eq "ls"){shift(@ARGV);ls(@ARGV);exit(0);}
if($ARGV[0] eq "script"){shift(@ARGV);script(@ARGV);exit(0);}
mkdir($bindir);chmod(0777,$bindir);
mkdir($workdir);chmod(0777,$workdir);
mkdir($ctrldir);chmod(0777,$ctrldir);
mkdir("$ctrldir/bash");chmod(0777,"$ctrldir/bash");
mkdir("$ctrldir/insert");chmod(0777,"$ctrldir/insert");
mkdir("$ctrldir/delete");chmod(0777,"$ctrldir/delete");
mkdir("$ctrldir/update");chmod(0777,"$ctrldir/update");
mkdir("$ctrldir/completed");chmod(0777,"$ctrldir/completed");
mkdir("$ctrldir/submit");chmod(0777,"$ctrldir/submit");
#just in case jobs are completed while moirai2.pl was not running by termination
my $executes={};
controlProcess($rdfdb,$executes);
if(getNumberOfJobsRunning()>0){
	print STDERR "There are jobs remaining in ctrl/bash directory.\n";
	print STDERR "Do you want to delete these jobs [y/n]? ";
	my $prompt=<STDIN>;
	chomp($prompt);
	if($prompt ne "y"&&$prompt ne "yes"&&$prompt ne "Y"&&$prompt ne "YES"){system("rm $ctrldir/bash/*");}
}
if($ARGV[0] eq "automate"){automate($rdfdb);exit(0);}
##### handle inputs and outputs #####
my $queryResults={};
my $userdefined={};
my $insertKeys;
if(defined($opt_i)){checkInputOutput($opt_i);}
if(defined($opt_o)){checkInputOutput($opt_o);}
if(defined($opt_i)){$queryResults=getQueryResults($rdfdb,$userdefined,$opt_i);}
if(!exists($queryResults->{".hashs"})){$queryResults->{".hashs"}=[{}];}
if(defined($opt_o)){
	$insertKeys=handleKeys($opt_o);
	if(defined($opt_i)){removeUnnecessaryExecutes($queryResults,$insertKeys);}
}
if(defined($opt_l)){printRows($queryResults->{".keys"},$queryResults->{".hashs"});}
##### handle commmand #####
my @nodeids;
my $cmdurl=shift(@ARGV);
if($cmdurl eq "command"){
	my @lines=();
	my ($inputs,$outputs)=handleInputOutput($insertKeys,$queryResults);
	while(<STDIN>){chomp;push(@lines,$_);}
	$cmdurl=createJson($rootdir,$inputs,$outputs,@lines);
}
if(defined($cmdurl)){
	my ($arguments,$userdefined)=handleArguments(@ARGV);
	@nodeids=commandProcess($cmdurl,$commands,$queryResults,$userdefined,$insertKeys,@{$arguments});
	if(defined($opt_r)){$commands->{$cmdurl}->{$urls->{"daemon/return"}}=removeDollar($opt_r);}
}
##### process #####
my @execurls=();
while(true){
	controlProcess($rdfdb,$executes);
	if(getNumberOfJobsRemaining($executes)<$maxjob){
		foreach my $url(lookForNewCommands($rdfdb,$newExecuteQuery,$commands)){
			my $job=getExecuteJobs($rdfdb,$commands->{$url},$executes);
			if($job>0){if(!existsArray(\@execurls,$url)){push(@execurls,$url);}}
		}
	}
	my $jobs_running=getNumberOfJobsRunning();
	if($jobs_running<$maxjob){mainProcess(\@execurls,$commands,$executes,$maxjob-$jobs_running);}
	$jobs_running=getNumberOfJobsRunning();
	if($loopMode){sleep($sleeptime);}
	elsif(getNumberOfJobsRemaining($executes)==0&&$jobs_running==0){controlProcess($rdfdb,$executes);last;}
	else{sleep($sleeptime);}
}
if($loopMode){
	# loop mode
}elsif(!defined($cmdurl)){
	# command URL not defined
}elsif(defined($opt_o)){
	# Output are defined, so don't print return
}elsif(exists($commands->{$cmdurl}->{$urls->{"daemon/return"}})){
	my $returnvalue=$commands->{$cmdurl}->{$urls->{"daemon/return"}};
	foreach my $nodeid(sort{$a cmp $b}@nodeids){
		my $result=`perl $prgdir/rdf.pl -d $rdfdb object $nodeid $cmdurl#$returnvalue`;
		chomp($result);
		print "$result\n";
	}
}
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
############################## assignCommand ##############################
sub assignCommand{
	my $command=shift();
	my $userdefined=shift();
	my $queryResults=shift();
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	my $keys={};
	foreach my $key(@{$queryResults->{".keys"}}){$keys->{$key}++;}
	foreach my $input(@inputs){
		if(exists($userdefined->{$input})){next;}
		if(exists($keys->{$input})){$userdefined->{$input}="\$$input";next;}
		if(!defined($opt_p)&&exists($command->{"default"}->{$input})){$userdefined->{$input}=$command->{"default"}->{$input};}
		else{promtCommandInput($command,$userdefined,$input);}
	}
}
############################## daemon ##############################
sub daemon{
	my @directories=@_;
	if(scalar(@directories)==0){push(@directories,".");}
	my $sleeptime=defined($opt_s)?$opt_s:10;
	my $logdir=defined($opt_o)?$opt_o:"log";
	my $databases={};
	my $stderrs={};
	my $stdouts={};
	my $logs={};
	my $directory=defined($opt_d)?$opt_d:".";
	my $md5cmd=(`which md5`)?"md5":"md5sum";
	while(1){
		foreach my $file(listFiles("sqlite3",@directories)){if(!exists($databases->{$file})){$databases->{$file}=0;}}
		while(my($database,$timestamp)=each(%{$databases})){
			my $dirname=dirname($database);
			my $basename=basename($database,".sqlite3");
			if(!(-e "$logdir/$basename")){mkdirs("$logdir/$basename");}
			my @stats=stat($database);
			my $modtime=$stats[9];
			if(-e "$logdir/$basename.lock" && -e "$logdir/$basename.unlock"){
				my $md4=`cat $logdir/$basename.unlock`;
				my $md5=`$md5cmd<$database`;
				unlink("$logdir/$basename.lock");
				unlink("$logdir/$basename.unlock");
				if($md4 ne $md5){$timestamp=0;}
				else{$databases->{$database}=$modtime;next;}
			}
			if(-e "$logdir/$basename.lock"){next;}
			elsif(scalar(listFiles(".txt","$dirname/$basename/ctrl/completed"))>0){}
			elsif(scalar(listFiles(".txt","$dirname/$basename/ctrl/delete"))>0){}
			elsif(scalar(listFiles(".txt","$dirname/$basename/ctrl/insert"))>0){}
			elsif(scalar(listFiles(".txt","$dirname/$basename/ctrl/submit"))>0){}
			elsif(scalar(listFiles(".txt","$dirname/$basename/ctrl/update"))>0){}
			elsif($modtime<=$timestamp){next;}
			my $command="perl moirai2.pl -d $database";
			if(defined($opt_q)){$command.=" -q"}
			if(defined($opt_m)){$command.=" -m $opt_m"}
			$command.=" automate";
			my $time=time();
			my $datetime=getDate("",$time).getTime("",$time);
			mkdirs("$logdir/$basename");
			if(!exists($stdouts->{$database})){$stdouts->{$database}="$logdir/$basename/$datetime.stdout";}
			my $stdout=$stdouts->{$database};
			if(!exists($stderrs->{$database})){$stderrs->{$database}="$logdir/$basename/$datetime.stderr";}
			my $stderr=$stderrs->{$database};
			$command.=">>$stdout 2>>$stderr";
			my $shell="$logdir/$basename/daemon.sh";
			open(OUT,">$shell");
			print OUT "$md5cmd<$database>$logdir/$basename.lock\n";
			print OUT "sleep 10\n";
			print OUT "touch $database\n";
			print OUT "$md5cmd<$database>$logdir/$basename.unlock\n";
			close(OUT);
			$command="bash $shell &";
			system($command);
			$databases->{$database}=$modtime;
		}
		sleep($sleeptime);
	}
}
############################## ls ##############################
sub ls{
	my @directories=@_;
	if(scalar(@directories)==0){push(@directories,".");}
	my @files=listFilesRecursively($opt_g,$opt_G,$opt_r,@directories);
	if(!defined($opt_o)){$opt_o="\$path";}
	foreach my $file(@files){
		my $line=$opt_o;
		my $hash=basenames($file);
		$hash=fileStats($file,$line,$hash);
		$line=~s/\\t/\t/g;
		$line=~s/\\n/\n/g;
		while(my($key,$val)=each(%{$hash})){
			$line=~s/\$\{$key\}/$val/g;
			$line=~s/\$$key/$val/g;
		}
		print "$line\n";
	}
}
############################## basenames ##############################
sub basenames{
	my $path=shift();
	my $directory=dirname($path);
	my $filename=basename($path);
	my $basename;
	my $suffix;
	my $hash={};
	if($filename=~/^(.+)\.([^\.]+)$/){$basename=$1;$suffix=$2;}
	else{$basename=$filename;}
	$hash->{"path"}="$directory/$filename";
	$hash->{"directory"}=$directory;
	$hash->{"filename"}=$filename;
	$hash->{"basename"}=$basename;
	if(defined($suffix)){$hash->{"suffix"}=$suffix;}
	my @dirs=split(/\//,$directory);
	if($dirs[0] eq ""){shift(@dirs);}
	for(my $i=0;$i<scalar(@dirs);$i++){$hash->{"dir$i"}=$dirs[$i];}
	my @bases=split(/[\W_]+/,$basename);
	for(my $i=0;$i<scalar(@bases);$i++){$hash->{"base$i"}=$bases[$i];}
	return $hash;
}
############################## bashCommand ##############################
sub bashCommand{
	my $command=shift();
	my $vars=shift();
	my $bashFiles=shift();
	my $nodeid=$vars->{"nodeid"};
	my $url=$command->{$urls->{"daemon/command"}};
	my $workdir="$rootdir/".$vars->{"workdir"};
	my $bashfile="$workdir/".$vars->{"bashfile"};
	my $stderrfile="$workdir/".$vars->{"stderrfile"};
	my $stdoutfile="$workdir/".$vars->{"stdoutfile"};
	my $insertfile="$workdir/".$vars->{"insertfile"};
	my $deletefile="$workdir/".$vars->{"deletefile"};
	my $updatefile="$workdir/".$vars->{"updatefile"};
	my $completedfile="$workdir/".$vars->{"completedfile"};
	if(defined($opt_c)){
		$vars->{"rootdir"}="/root";
		$vars->{"prgdir"}="/root";
		$vars->{"ctrldir"}="/root/$basename/ctrl";
	}
	open(OUT,">$bashfile");
	print OUT "#!/bin/sh\n";
	print OUT "########## system ##########\n";
	my @systemvars=("cmdurl","rdfdb","nodeid","ctrldir","prgdir","rootdir","tmpdir","workdir");
	my @unusedvars=();
	my @systemfiles=("bashfile","stdoutfile","stderrfile","deletefile","updatefile","insertfile","completedfile");
	my @outputvars=(@{$command->{"output"}});
	foreach my $var(@systemvars){print OUT "$var=\"".$vars->{$var}."\"\n";}
	foreach my $var(@systemfiles){print OUT "$var=\"".$vars->{$var}."\"\n";}
	my @keys=();
	foreach my $key(sort{$a cmp $b}keys(%{$vars})){
		my $break=0;
		foreach my $var(@systemvars){if($var eq $key){$break=1;last;}}
		foreach my $var(@systemfiles){if($var eq $key){$break=1;last;}}
		foreach my $var(@unusedvars){if($var eq $key){$break=1;last;}}
		foreach my $var(@outputvars){if($var eq $key){$break=1;last;}}
		if($break){next;}
		push(@keys,$key);
	}
	print OUT "cd \$rootdir\n";
	if(scalar(@keys)>0){print OUT "########## variables ##########\n";}
	foreach my $key(@keys){
		my $value=$vars->{$key};
		if(ref($value)eq"ARRAY"){print OUT "$key=(\"".join("\" \"",@{$value})."\")\n";}
		else{print OUT "$key=\"$value\"\n";}
	}
	my $basenames={};
	foreach my $key(@keys){
		my $value=$vars->{$key};
		if(ref($value)eq"ARRAY"){next;}
		elsif($value=~/[\.\/]/){
			my $hash=basenames($value);
			while(my ($k,$v)=each(%{$hash})){$basenames->{"$key.$k"}=$v;}
		}
	}
	my @scriptfiles=();
	if(exists($command->{"script"})){
		print OUT "########## script ##########\n";
		foreach my $name (@{$command->{"script"}}){
			push(@scriptfiles,"$workdir/$name");
			print OUT "cat<<EOF>$name\n";
			foreach my $line(scriptCodeForBash(@{$command->{$name}})){print OUT "$line\n";}
			print OUT "EOF\n";
		}
	}
	print OUT "########## open tmpdir ##########\n";
	print OUT "mkdir -p /tmp/\$nodeid\n";
	print OUT "ln -s /tmp/\$nodeid \$rootdir/\$workdir/tmp\n";
	print OUT "########## initialize ##########\n";
	print OUT "cat<<EOF>>\$workdir/\$insertfile\n";
	my $inputs=$command->{"inputs"};
	print OUT "\$nodeid\t".$urls->{"daemon/command"}."\t\$cmdurl\n";
	if(!exists($command->{"isworkflow"})){
		foreach my $input(@{$command->{"input"}}){
			if(exists($inputs->{$input})){foreach my $value(@{$vars->{$input}}){print OUT "\$nodeid\t\$cmdurl#$input\t$value\n";}}
			else{print OUT "\$nodeid\t\$cmdurl#$input\t\$$input\n";}
		}
		print OUT "\$nodeid\t".$urls->{"daemon/timestarted"}."\t`date +%s`\n";
	}
	print OUT "EOF\n";
	my @unzips=();
	if(exists($command->{$urls->{"daemon/unzip"}})){
		print OUT "########## unzip ##########\n";
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
	print OUT "########## command ##########\n";
	foreach my $line(@{$command->{"bashCode"}}){
		my $temp=$line;
		if($temp=~/\$\{.+\}/){
			while(my ($k,$v)=each(%{$basenames})){$temp=~s/\$\{$k\}/$v/g;}
		}
		print OUT "$temp\n";
	}
	foreach my $output(@{$command->{"output"}}){
		my $count=0;
		if(exists($vars->{$output})&&$output ne $vars->{$output}){
			my $value=$vars->{$output};
			if($count==0){print OUT "########## move ##########\n";}
			print OUT "mv \$$output $value\n";
			print OUT "$output=$value\n";
			$count++;
		}
	}
	if(exists($command->{$urls->{"daemon/linecount"}})){
		print OUT "########## linecount ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/linecount"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl \$prgdir/rdf.pl linecount \$out>>\$workdir/\$insertfile\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl \$prgdir/rdf.pl linecount \$$key>>\$workdir/\$insertfile\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/seqcount"}})){
		print OUT "########## seqcount ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/seqcount"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl \$prgdir/rdf.pl seqcount \$out>>\$workdir/\$insertfile\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl \$prgdir/rdf.pl seqcount \$$key>>\$workdir/\$insertfile\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/md5"}})){
		print OUT "########## md5 ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/md5"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl \$prgdir/rdf.pl md5 \$out>>\$workdir/\$insertfile\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl \$prgdir/rdf.pl md5 \$$key>>\$workdir/\$insertfile\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/filesize"}})){
		print OUT "########## filesize ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/filesize"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl \$prgdir/rdf.pl filesize \$out>>\$workdir/\$insertfile\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl \$prgdir/rdf.pl seqcount \$$key>>\$workdir/\$insertfile\n";
			print OUT "fi\n";
		}
	}
	print OUT "########## database ##########\n";
	my $inserts={};
	if(exists($command->{"insertKeys"})){
		foreach my $insert(@{$command->{"insertKeys"}}){
			my $found=0;
			my $line=join("->",@{$insert});
			foreach my $output(@{$command->{"output"}}){
				if($line=~/\$$output/){push(@{$inserts->{$output}},$insert);$found=1;last;}
			}
			if($found==0){push(@{$inserts->{""}},$insert);}
		}
	}
	print OUT "echo \"\$nodeid\t".$urls->{"daemon/timeended"}."\t`date +%s`\">>\$workdir/\$insertfile\n";
	foreach my $output(@{$command->{"output"}}){
		print OUT "if [[ \"\$(declare -p $output)\" =~ \"declare -a\" ]]; then\n";
		print OUT "for out in \${$output"."[\@]} ; do\n";
		if(exists($vars->{$output})){print OUT "echo \"\$nodeid\t\$cmdurl#$output\t\$out\">>\$workdir/\$updatefile\n";}
		else{print OUT "echo \"\$nodeid\t\$cmdurl#$output\t\$out\">>\$workdir/\$insertfile\n";}
		if(exists($inserts->{$output})){
			foreach my $row(@{$inserts->{$output}}){
				my $line=join("\t",@{$row});
				$line=~s/\$$output/\$out/g;
				print OUT "echo \"$line\">>\$workdir/\$insertfile\n";
			}
		}
		print OUT "done\n";
		print OUT "else\n";
		if(exists($vars->{$output})){print OUT "echo \"\$nodeid\t\$cmdurl#$output\t\$$output\">>\$workdir/\$updatefile\n";}
		else{print OUT "echo \"\$nodeid\t\$cmdurl#$output\t\$$output\">>\$workdir/\$insertfile\n";}
		if(exists($inserts->{$output})){
			foreach my $row(@{$inserts->{$output}}){print OUT "echo \"".join("\t",@{$row})."\">>\$workdir/\$insertfile\n";}
		}
		print OUT "fi\n";
	}
	if(exists($inserts->{""})){foreach my $row(@{$inserts->{""}}){print OUT "echo \"".join("\t",@{$row})."\">>\$workdir/\$insertfile\n";}}
	if(exists($command->{$urls->{"daemon/linecount"}})){
		print OUT "########## linecount ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/linecount"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl \$prgdir/rdf.pl linecount \$out>>\$workdir/\$insertfile\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl \$prgdir/rdf.pl linecount \$$key>>\$workdir/\$insertfile\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/seqcount"}})){
		print OUT "########## seqcount ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/seqcount"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl \$prgdir/rdf.pl seqcount \$out>>\$workdir/\$insertfile\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl \$prgdir/rdf.pl seqcount \$$key>>\$workdir/\$insertfile\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/md5"}})){
		print OUT "########## md5 ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/md5"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl \$prgdir/rdf.pl md5 \$out>>\$workdir/\$insertfile\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl \$prgdir/rdf.pl md5 \$$key>>\$workdir/\$insertfile\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/filesize"}})){
		print OUT "########## filesize ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/filesize"}}}){
			print OUT "if [[ \"\$(declare -p $key)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$key"."[\@]} ; do\n";
			print OUT "perl \$prgdir/rdf.pl filesize \$out>>\$workdir/\$insertfile\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "perl \$prgdir/rdf.pl filesize \$$key>>\$workdir/\$insertfile\n";
			print OUT "fi\n";
		}
	}
	if(scalar(@{$command->{"updateKeys"}})>0){
		print OUT "cat<<EOF>>\$workdir/\$updatefile\n";
		foreach my $row(@{$command->{"updateKeys"}}){print OUT join("\t",@{$row})."\n";}
		print OUT "EOF\n";
	}
	if(scalar(@{$command->{"deleteKeys"}})>0){
		print OUT "cat<<EOF>>\$workdir/\$deletefile\n";
		foreach my $row(@{$command->{"deleteKeys"}}){print OUT join("\t",@{$row})."\n";}
		print OUT "EOF\n";
	}
	print OUT "if [ -s \$workdir/\$stdoutfile ];then\n";
	print OUT "echo \"\$nodeid\t".$urls->{"daemon/stdout"}."\t\$workdir/\$stdoutfile\">>\$workdir/\$insertfile\n";
	print OUT "fi\n";
	print OUT "if [ -s \$workdir/\$stderrfile ];then\n";
	print OUT "echo \"\$nodeid\t".$urls->{"daemon/stderr"}."\t\$workdir/\$stderrfile\">>\$workdir/\$insertfile\n";
	print OUT "fi\n";
	if(scalar(@unzips)>0){
		print OUT "########## cleanup ##########\n";
		foreach my $unzip(@unzips){print OUT "rm $unzip\n";}
	}
	print OUT "########## close tmpdir ##########\n";
	print OUT "rm \$workdir/tmp\n";
	print OUT "if [ -z \"\$(ls -A /tmp/\$nodeid)\" ]; then\n";
  	print OUT "rmdir /tmp/\$nodeid\n";
	print OUT "else\n";
	print OUT "mv /tmp/\$nodeid \$workdir/tmp\n";
	print OUT "fi\n";
	print OUT "########## completed ##########\n";
	my $importcount=0;
	my $nodename=$nodeid;
	$nodename=~s/[^A-za-z0-9]/_/g;
	foreach my $importfile(@{$command->{$urls->{"daemon/import"}}}){print OUT "mv \$workdir/$importfile \$ctrldir/insert/$nodename.import\n";$importcount++;}
	print OUT "mv \$workdir/\$completedfile \$ctrldir/completed/\$nodeid.sh\n";
	close(OUT);
	writeCompleteFile($completedfile,$stdoutfile,$stderrfile,$insertfile,$deletefile,$updatefile,$bashfile,\@scriptfiles,$ctrldir,$workdir);
	if(exists($vars->{"bashfile"})){
		if(defined($opt_c)){push(@{$bashFiles},[$vars->{"rootdir"}."/".$vars->{"workdir"}."/".$vars->{"bashfile"},$stdoutfile,$stderrfile,$nodeid]);}
		#if(defined($opt_c)){push(@{$bashFiles},[$vars->{"rootdir"}."/".$vars->{"workdir"}."/".$vars->{"bashfile"},$vars->{"rootdir"}."/".$vars->{"workdir"}."/".$vars->{"stdoutfile"},$vars->{"rootdir"}."/".$vars->{"workdir"}."/".$vars->{"stderrfile"},$nodeid]);}
		else{push(@{$bashFiles},[$bashfile,$stdoutfile,$stderrfile,$nodeid]);}
	}
}
############################## checkInputOutput ##############################
sub checkInputOutput{
	my $queries=shift();
	foreach my $query(split(/,/,$queries)){
		my $empty=0;
		foreach my $token(split(/->/,$query)){if($token eq ""){$empty=1;last;}}
		if($empty==1){
			print STDERR "ERROR: '$query' has empty token.\n";
			print STDERR "ERROR: Use single quote '\$a->b->\$c' instead of double quote \"\$a->b->\$c\".\n";
			print STDERR "ERROR: Or escape '\$' with '\\' sign \"\\\$a->b->\\\$c\".\n";
			exit(1);
		}
	}
}
############################## fileStats ##############################
sub fileStats{
	my $path=shift();
	my $line=shift();
	my $hash=shift();
	if(!defined($hash)){$hash={};}
	my @variables=("linecount","seqcount","filesize","filecount","md5","timestamp","owner","group","permission","check");
	my $matches={};
	foreach my $v(@variables){if($line=~/\$\{$v\}/||$line=~/\$$v/){$matches->{$v}=1;}}
	foreach my $key(keys(%{$matches})){
		my @stats=stat($path);
		if($key eq "filesize"){$hash->{$key}=$stats[7];}
		elsif($key eq "md5"){my $md5cmd=(`which md5`)?"md5":"md5sum";my $md5=`$md5cmd<$path`;chomp($md5);$hash->{$key}=$md5;}
		elsif($key eq "timestamp"){$hash->{$key}=$stats[9];}
		elsif($key eq "owner"){$hash->{$key}=getpwuid($stats[4]);}
		elsif($key eq "group"){$hash->{$key}=getgrgid($stats[5]);}
		elsif($key eq "permission"){$hash->{$key}=$stats[2]&07777;}
		elsif($key eq "filecount"){if(!(-f $path)){$hash->{$key}=0;}else{my $count=`ls $path|wc -l`;chomp($count);$hash->{$key}=$count;}}
		elsif($key eq "linecount"){$hash->{$key}=linecount($path);}
		elsif($key eq "seqcount"){$hash->{$key}=seqcount($path);}
		elsif($key eq "check"){$hash->{$key}=check($path);}
	}
	return $hash;
}
############################## filecheck ##############################
sub filecheck{
	my $path=shift();
	if($path=~/\.te?xt$/){
	}if($path=~/\.gz(ip)?$/){
	}elsif($path=~/\.bz(ip)?2$/){
	}
}
############################## linecount ##############################
sub linecount{
	my $path=shift();
	if(!(-f $path)){return 0;}
	elsif($path=~/\.gz(ip)?$/){my $count=`gzip -cd $path|wc -l`;chomp($count);return $count;}
	elsif($path=~/\.bz(ip)?2$/){my $count=`bzip2 -cd $path|wc -l`;chomp($count);return $count;}
	elsif($path=~/\.bam$/){my $count=`samtools view $path|wc -l`;chomp($count);return $count;}
	else{my $count=`cat $path|wc -l`;chomp($count);return $count;}
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
############################## openFile ##############################
sub openFile{
	my $path=shift();
	if($path=~/\.gz(ip)?$/){return IO::File->new("gzip -cd $path|");}
	elsif($path=~/\.bz(ip)?2$/){return IO::File->new("bzip2 -cd $path|");}
	elsif($path=~/\.bam$/){return IO::File->new("samtools view $path|");}
	else{return IO::File->new($path);}
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
############################## selectRDF ##############################
sub selectRDF{
	my $database=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my @results=`perl $prgdir/rdf.pl -d $database select '$subject' '$predicate' '$object'`;
	foreach my $result(@results){
		chomp($result);
		my @tokens=split(/\t/,$result);
		$result=\@tokens;
	}
	return @results;
}
############################## checkRDFObject ##############################
sub checkRDFObject{
	my $database=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $result=`perl $prgdir/rdf.pl -d $database object '$subject' '$predicate' '$object'`;
	chomp($result);
	return $result;
}
############################## commandProcess ##############################
sub commandProcess{
	my @arguments=@_;
	my $url=shift(@arguments);
	my $commands=shift(@arguments);
	my $queryResults=shift(@arguments);
	my $userdefined=shift(@arguments);
	my $insertKeys=shift(@arguments);
	my $command=loadCommandFromURL($url,$commands);
	$commands->{$url}=$command;
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	if(defined($insertKeys)){push(@{$command->{"insertKeys"}},@{$insertKeys});}
	if(defined($opt_l)){
		my $cmdline="#Command: ".basename($command->{$urls->{"daemon/command"}});
		if(scalar(@inputs)>0){$cmdline.=" \$".join(" \$",@inputs);}
		if(scalar(@outputs)>0){$cmdline.=" \$".join(" \$",@outputs);}
		print STDERR "$cmdline\n";
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
	my @inserts=();
	my @nodeids=();
	my $keys;
	foreach my $hash(@{$queryResults->{".hashs"}}){
		my $vars=commandProcessVars($hash,$userdefined,$insertKeys,\@inputs,\@outputs);
		if(!defined($keys)){my @temp=sort{$a cmp $b}keys(%{$vars});$keys=\@temp;}
		my ($nodeid,@array)=commandProcessSub($url,$vars);
		push(@nodeids,$nodeid);
		push(@inserts,@array);
	}
	if(defined($opt_l)){
		print STDERR "Proceed running ".scalar(@nodeids)." jobs [y/n]? ";
		my $prompt=<STDIN>;
		chomp($prompt);
		if($prompt ne "y"&&$prompt ne "yes"&&$prompt ne "Y"&&$prompt ne "YES"){exit(1);}
	}
	writeInserts(@inserts);
	return @nodeids;
}
############################## commandProcessSub ##############################
sub commandProcessSub{
	my $url=shift();
	my $vars=shift();
	my @inserts=();
	my $nodeid=`perl $prgdir/rdf.pl -d $rdfdb newnode`;
	chomp($nodeid);
	push(@inserts,$urls->{"daemon"}."\t".$urls->{"daemon/execute"}."\t$nodeid");
	push(@inserts,"$nodeid\t".$urls->{"daemon/command"}."\t$url");
	foreach my $key(keys(%{$vars})){push(@inserts,"$nodeid\t$url#$key\t".$vars->{$key});}
	return ($nodeid,@inserts);
}
############################## commandProcessVars ##############################
sub commandProcessVars{
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
############################## automate ##############################
sub automate{
	my @files=getFiles("$ctrldir/automate");
	if(scalar(@files)==0){return 0;}
	foreach my $file(sort{$a cmp $b}@files){
		my $command=getBash($file);
		my @lines=@{$command->{$urls->{"daemon/bash"}}};
		my ($writer,$temp)=tempfile("bashXXXXXXXXXX",DIR=>$ctrldir,UNLINK=>1,SUFFIX=>".sh");
		foreach my $line(@lines){print $writer "$line\n";}
		system("bash $temp");
		if(defined($opt_l)){print STDERR "bash $temp\n";}
	}
}
############################## controlCompleted ##############################
sub controlCompleted{
	my @files=getFiles("$ctrldir/completed");
	my $count=scalar(@files);
	if($count==0){return 0;}
	foreach my $file(@files){system("bash $file");unlink($file);}
	return $count;
}
############################## controlDelete ##############################
sub controlDelete{
	my $rdfdb=shift();
	my @files=getFiles("$ctrldir/delete");
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $prgdir/rdf.pl -d $rdfdb -f tsv delete";
	my $count=`$command`;
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlInsert ##############################
sub controlInsert{
	my $rdfdb=shift();
	my @files=getFiles("$ctrldir/insert");
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $prgdir/rdf.pl -d $rdfdb -f tsv insert";
	my $count=`$command`;
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlProcess ##############################
sub controlProcess{
	my $rdfdb=shift();
	my $executes=shift();
	my $completed=controlCompleted();
	my $inserted=controlInsert($rdfdb);
	my $deleted=controlDelete($rdfdb);
	my $updated=controlUpdate($rdfdb);
	$inserted+=controlSubmit($rdfdb);
	if(!defined($opt_l)){return;}
	my $date=getDate("/");
	my $time=getTime(":");
	if($completed>0){
		my $remain=getNumberOfJobsRemaining($executes);
		if($completed>1){print "$date $time Completed $completed jobs (Remaining $remain).\n";}
		else{print "$date $time Completed $completed job ($remain remain).\n";}
	}
	if($inserted>1){print "$date $time Inserted $inserted triples.\n";}
	elsif($inserted>0){print "$date $time Inserted $inserted triple.\n";}
	if($deleted>1){print "$date $time Deleted $deleted triples.\n";}
	elsif($deleted>0){print "$date $time Deleted $deleted triple.\n";}
	if($updated>1){print "$date $time Updated $updated triples.\n";}
	elsif($updated>0){print "$date $time Updated $updated triple.\n";}
}
############################## controlSubmit ##############################
sub controlSubmit{
	my $rdfdb=shift();
	my @files=getFiles("$ctrldir/submit");
	if(scalar(@files)==0){return 0;}
	my $total=0;
	foreach my $file(@files){
		my $command="perl $prgdir/rdf.pl -d $rdfdb -f tsv submit<$file";
		$total+=`$command`;
		unlink($file);
	}
	return $total;
}
############################## controlUpdate ##############################
sub controlUpdate{
	my $rdfdb=shift();
	my @files=getFiles("$ctrldir/update");
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $prgdir/rdf.pl -d $rdfdb -f tsv update";
	my $count=`$command`;
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## createJson ##############################
sub createJson{
	my @commands=@_;
	my $dir=shift(@commands);
	my $inputs=shift(@commands);
	my $outputs=shift(@commands);
	my ($writer,$file)=tempfile(DIR=>$dir,UNLINK=>1,SUFFIX=>".json");
	print $writer "{";
	print $writer "\"".$urls->{"daemon/bash"}."\":[\"".join("\",\"",@commands)."\"]";
	if(scalar(@{$inputs})>0){print $writer ",\"".$urls->{"daemon/input"}."\":[\"".join("\",\"",@{$inputs})."\"]";}
	if(scalar(@{$outputs})>0){print $writer ",\"".$urls->{"daemon/output"}."\":[\"".join("\",\"",@{$outputs})."\"]";}
	print $writer "}";
	close($writer);
	if($file=~/^\.\/(.+)$/){$file=$1;}
	return $file;
}
############################## printKeyVal ##############################
sub printKeyVal(){
	my @arguments=@_;
	my $queryResults=shift(@arguments);
	my $insertKeys=shift(@arguments);
	my @keys=sort{$b cmp $a}@{$queryResults->{".keys"}};
	foreach my $hash(@{$queryResults->{".hashs"}}){
		foreach my $argument(@arguments){
			my $line=$argument;
			foreach my $key(@keys){
				my $value=$hash->{$key};
				$line=~s/\$$key/$value/g;
				$line=~s/\$\{$key\}/$value/g;
			}
			print "$line\n";
		}
	}
}
############################## existsArray ##############################
sub existsArray{
	my $array=shift();
	my $needle=shift();
	foreach my $value(@{$array}){if($needle eq $value){return 1;}}
	return 0;
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
############################## getExecuteJobsSelect ##############################
sub getExecuteJobsSelect{
	my $rdfdb=shift();
	my $command=shift();
	my $executes=shift();
	my $query=$command->{"rdfQuery"};
	my $dbh=openDB($rdfdb);
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $rows=$sth->fetchall_arrayref();
	$dbh->disconnect;
	my $url=$command->{$urls->{"daemon/command"}};
	my $keys=$command->{"keys"};
	my $count=0;
	if(exists($command->{$urls->{"daemon/inputs"}})){
		my $inputs=$command->{$urls->{"daemon/inputs"}};
		my $temp={};
		foreach my $row(@{$rows}){
			my $label="|";
			for(my $i=0;$i<scalar(@{$row});$i++){
				my $key=$keys->[$i];
				my $value=$row->[$i];
				if(!exists($inputs->{$key})){$label.="$value|";}
			}
			if(!exists($temp->{$label})){
				$temp->{$label}=[];
				for(my $i=0;$i<scalar(@{$row});$i++){
					my $key=$keys->[$i];
					my $value=$row->[$i];
					if(exists($inputs->{$key})){$temp->{$label}->[$i]=[];}
					else{$temp->{$label}->[$i]=$value;}
				}
			}
			for(my $i=0;$i<scalar(@{$row});$i++){
				my $key=$keys->[$i];
				my $value=$row->[$i];
				if(exists($inputs->{$key})){push(@{$temp->{$label}->[$i]},$value);}
			}
		}
		foreach my $value(values(%{$temp})){
			my $vars={};
			for(my $i=0;$i<scalar(@{$value});$i++){$vars->{$keys->[$i]}=$value->[$i];}
			push(@{$executes->{$url}},$vars);
			$count++;
		}
	}else{
		foreach my $row(@{$rows}){
			my $vars={};
			for(my $i=0;$i<scalar(@{$row});$i++){
				my $key=$keys->[$i];
				my $value=$row->[$i];
				$vars->{$key}=$value;
			}
			push(@{$executes->{$url}},$vars);
			$count++;
		}
	}
	return $count;
}
############################## getExecuteJobs ##############################
sub getExecuteJobs{
	my $rdfdb=shift();
	my $command=shift();
	my $executes=shift();
	if(exists($command->{$urls->{"daemon/select"}})){return getExecuteJobsSelect($rdfdb,$command,$executes);}
	else{return getExecuteJobsNodeid($rdfdb,$command,$executes);}
}
############################## getExecuteJobsNodeid ##############################
sub getExecuteJobsNodeid{
	my $rdfdb=shift();
	my $command=shift();
	my $executes=shift();
	my $url=$command->{$urls->{"daemon/command"}};
	my $nodeids={};
	foreach my $execute(@{$executes->{$url}}){$nodeids->{$execute->{"nodeid"}}=1;}
	my $query="select distinct k.data,s.data,p.data,o.data from edge as e1 inner join edge as e2 on e1.object=e2.subject inner join node as k on e1.subject=k.id inner join node as s on e2.subject=s.id inner join node as p on e2.predicate=p.id inner join node as o on e2.object=o.id where e1.predicate=(select id from node where data=\"".$urls->{"daemon/execute"}."\")";
	if(scalar(keys(%{$nodeids}))>0){$query.=" and e1.object not in(select id from node where data in (\"".join("\",\"",keys(%{$nodeids}))."\"))";}
	my $dbh=openDB($rdfdb);
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $rows2=$sth->fetchall_arrayref();
	$dbh->disconnect;
	my @keys=@{$command->{"keys"}};
	my $vars={};
	foreach my $row(@{$rows2}){
		my @array=();
		my $keyinput=$row->[0];
		my $nodeid=$row->[1];
		if(exists($nodeids->{$nodeid})){next;}
		my $predicate=$row->[2];
		my $object=$row->[3];
		if(!exists($vars->{$nodeid})){$vars->{$nodeid}={};$vars->{$nodeid}->{"nodeid"}=$nodeid;}
		if($object eq $url){next;}
		if($predicate=~/^$url#(.+)$/){
			my $key=$1;
			if(!exists($vars->{$nodeid}->{$key})){$vars->{$nodeid}->{$key}=$object;}
			elsif(ref($vars->{$nodeid}->{$key})eq"ARRAY"){push(@{$vars->{$nodeid}->{$key}},$object);}
			else{$vars->{$nodeid}->{$key}=[$vars->{$nodeid}->{$key},$object]}
		}
	}
	my $count=0;
	foreach my $key(sort{$a cmp $b}keys(%{$vars})){push(@{$executes->{$url}},$vars->{$key});$count++;}
	return $count;
}
############################## getFileContent ##############################
sub getFileContent{
	my $path=shift();
	open(IN,$path);
	my $content;
	while(<IN>){s/\r//g;$content.=$_;}
	close(IN);
	return $content;
}
############################## getFiles ##############################
sub getFiles{
	my $directory=shift();
	my @files=();
	opendir(DIR,$directory);
	foreach my $file(readdir(DIR)){
		if($file=~/^\./){next;}
		if($file eq ""){next;}
		push(@files,"$directory/$file");
	}
	closedir(DIR);
	return @files;
}
############################## getHttpContent ##############################
sub getHttpContent{
	my $url=shift();
	my $username=shift();
	my $password=shift();
	my $agent=new LWP::UserAgent();
	my $request=HTTP::Request->new(GET=>$url);
	if($username ne ""||$password ne ""){$request->authorization_basic($username,$password);}
	my $res=$agent->request($request);
	if($res->is_success){return $res->content;}
	elsif($res->is_error){print $res;}
}
############################## getBash ##############################
sub getBash{
	my $url=shift();
	my $username=shift();
	my $password=shift();
	my $content=($url=~/https?:\/\//)?getHttpContent($url,$username,$password):getFileContent($url);
	my $line;
	my @lines=();
	foreach my $c(split(/\n/,$content)){
		if($c=~/^\s*(.+)\s+\\$/){
			if(defined($line)){$line.=" $1";}
			else{$line=$1;}
		}elsif(defined($line)){
			$line.=" $c";
			push(@lines,$line);
			$line=undef;
		}else{push(@lines,$c);}
	}
	if(defined($line)){push(@lines,$line);}
	foreach my $line(@lines){
		if($line=~/(perl )?moirai2\.pl/){
			$line=~s/\s+\-q//;
			$line=~s/\s+\-c\s+\S+//;
			$line=~s/\s+\-d\s+\S+//;
			$line=~s/moirai2\.pl/moirai2.pl -d $rdfdb/;
		}
	}
	return {$urls->{"daemon/bash"}=>\@lines};
}
############################## getJson ##############################
sub getJson{
	my $url=shift();
	my $username=shift();
	my $password=shift();
	my $content=($url=~/https?:\/\//)?getHttpContent($url,$username,$password):getFileContent($url);
	my $directory=dirname($url);
	$content=~s/\$this/$url/g;
	$content=~s/\$\{this:directory\}/$directory/g;
	return jsonDecode($content);
}
############################## getNumberOfJobsRemaining ##############################
sub getNumberOfJobsRemaining{
	my $executes=shift();
	my $count=0;
	foreach my $url(keys(%{$executes})){$count+=scalar(@{$executes->{$url}});}
	return $count;
}
############################## getNumberOfJobsRunning ##############################
sub getNumberOfJobsRunning{my @files=getFiles("$ctrldir/bash");return scalar(@files);}
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
############################## getQueryResults ##############################
sub getQueryResults{
	my $rdfdb=shift();
	my $userdefined=shift();
	my $input=shift();
	my $hash={};
	my ($query,$keys)=parseQuery(replaceStringWithHash($userdefined,$input));
	my $dbh=openDB($rdfdb);
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $rows=$sth->fetchall_arrayref();
	$dbh->disconnect;
	my @hashs=();
	foreach my $row(@{$rows}){
		my $hash={};
		for(my $i=0;$i<scalar(@{$keys});$i++){$hash->{$keys->[$i]}=$row->[$i];}
		push(@hashs,$hash);
	}
	$hash->{".keys"}=$keys;
	$hash->{".hashs"}=\@hashs;
	return $hash;
}
############################## handleArguments ##############################
sub handleArguments{
	my @arguments=@_;
	my $variables={};
	my @array=();
	foreach my $argument(@arguments){if($argument=~/^(.+)=(.+)$/){
		my $key=$1;
		my $val=$2;
		if($key=~/^\$(.+)$/){$key=$1;}
		$variables->{$key}=$val;
	}else{push(@array,$argument);}}
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
sub handleInputOutput{
	my $insertKeys=shift();
	my $queryResults=shift();
	my $inputs={};
	my $outputs={};
	foreach my $token(@{$queryResults->{".keys"}}){$inputs->{"\$$token"}=1;}
	foreach my $token(@{$insertKeys}){
		foreach my $t(@{$token}){
			if($t!~/^\$/){next;}
			if(exists($inputs->{$t})){next;}
			$outputs->{$t}=1;
		}
	}
	my @ins=keys(%{$inputs});
	my @outs=keys(%{$outputs});
	return (\@ins,\@outs);
}
############################## handleKeys ##############################
sub handleKeys{
	my $statement=shift();
	my @array=();
	my @statements;
	if(ref($statement) eq "ARRAY"){@statements=@{$statement};}
	else{@statements=split(",",$statement);}
	foreach my $line(@statements){
		my @tokens=split(/->/,$line);
		push(@array,\@tokens);
	}
	return \@array;
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
		#foreach my $c(@{$code}){$c=~s/\\"/"/;}#Is this needed?
		$command->{$name}=$code;
		push(@{$command->{"script"}},$name);
	}
	$command->{$urls->{"daemon/script"}}=$scripts;
}
############################## initExecute ##############################
sub initExecute{
	my $rdfdb=shift();
	my $command=shift();
	my $vars=shift();
	if(!defined($vars)){$vars={};}
	my $url=$command->{$urls->{"daemon/command"}};
	my $nodeid=$vars->{"nodeid"};
	$vars->{"rootdir"}=$rootdir;
	$vars->{"prgdir"}=$prgdir;
	$vars->{"ctrldir"}=$ctrldir;
	$vars->{"cmdurl"}=$url;
	$vars->{"rdfdb"}=$rdfdb;
	my $directory="$workdir/$nodeid";
	mkdir($directory);
	chmod(0777,$directory);
	$vars->{"workdir"}="$basename/$nodeid";
	$vars->{"tmpdir"}="$basename/$nodeid/tmp";
	$vars->{"bashfile"}="$nodeid.sh";
	$vars->{"stderrfile"}="$nodeid.stderr";
	$vars->{"stdoutfile"}="$nodeid.stdout";
	$vars->{"insertfile"}="$nodeid.insert";
	$vars->{"deletefile"}="$nodeid.delete";
	$vars->{"updatefile"}="$nodeid.update";
	$vars->{"completedfile"}="$nodeid.completed";
	return $vars;
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
############################## listFilesRecursively ##############################
sub listFilesRecursively{
	my @directories=@_;
	my $filegrep=shift(@directories);
	my $fileungrep=shift(@directories);
	my $recursivesearch=shift(@directories);
	my @inputfiles=();
	foreach my $directory (@directories){
		$directory=Cwd::abs_path($directory);
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
############################## listFiles ##############################
# list files under a directory - 2018/02/01
# Fixed recursion problem - 2018/02/01
# listFiles($file_suffix,@input_directories);
sub listFiles{
	my @input_directories=@_;
	my $file_suffix=shift(@input_directories);
	my @input_files=();
	foreach my $input_directory (@input_directories){
		$input_directory=absolutePath($input_directory);
		if(-f $input_directory){push(@input_files,$input_directory);next;}# It's a file, so process file
		elsif(-l $input_directory){push(@input_files,$input_directory);next;}# It's a file, so process file
		opendir(DIR,$input_directory);
		foreach my $file(readdir(DIR)){# go through input directory
			if($file eq "."){next;}
			if($file eq "..") {next;}
			if($file eq ""){next;}
			$file="$input_directory/$file";
			if(-d $file){next;}# skip directory element
			elsif($file!~/$file_suffix$/){next;}
			push(@input_files,$file);
		}
		closedir(DIR);
	}
	return sort{$a cmp $b}@input_files;
}
############################## loadCommandFromURL ##############################
sub loadCommandFromURL{
	my $url=shift();
	my $commands=shift();
	if(exists($commands->{$url})){return $commands->{$url};}
	if(defined($opt_l)){print STDERR "#Loading $url:\t";}
	my $command=($url=~/\.json$/)?getJson($url):getBash($url);
	if(scalar(keys(%{$command}))==0){print "ERROR: Couldn't load $url\n";exit(1);}
	loadCommandFromURLSub($command,$url);
	$command->{$urls->{"daemon/command"}}=$url;
	if(defined($opt_l)){print STDERR "OK\n";}
	$commands->{$url}=$command;
	return $command;
}
sub loadCommandFromURLSub{
	my $command=shift();
	my $url=shift();
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
	if(exists($command->{$urls->{"daemon/return"}})){
		$command->{$urls->{"daemon/output"}}=handleArray($command->{$urls->{"daemon/output"}},$default);
		my $hash=handleHash(@{$command->{$urls->{"daemon/output"}}});
		my $returnvalue=$command->{$urls->{"daemon/return"}};
		if(!exists($hash->{$returnvalue})){push(@{$command->{$urls->{"daemon/output"}}},$returnvalue);}
	}
	if(exists($command->{$urls->{"daemon/output"}})){
		$command->{$urls->{"daemon/output"}}=handleArray($command->{$urls->{"daemon/output"}},$default);
		my @array=();
		foreach my $output(@{$command->{$urls->{"daemon/output"}}}){push(@array,$output);}
		$command->{"output"}=\@array;
	}
	my @array=();
	foreach my $input(@{$command->{"input"}}){push(@array,$input);}
	foreach my $output(@{$command->{"output"}}){push(@array,$output);}
	$command->{"keys"}=\@array;
	if(exists($command->{$urls->{"daemon/return"}})){$command->{$urls->{"daemon/return"}}=removeDollar($command->{$urls->{"daemon/return"}});}
	if(exists($command->{$urls->{"daemon/unzip"}})){$command->{$urls->{"daemon/unzip"}}=handleArray($command->{$urls->{"daemon/unzip"}});}
	if(exists($command->{$urls->{"daemon/md5"}})){$command->{$urls->{"daemon/md5"}}=handleArray($command->{$urls->{"daemon/md5"}});}
	if(exists($command->{$urls->{"daemon/filesize"}})){$command->{$urls->{"daemon/filesize"}}=handleArray($command->{$urls->{"daemon/filesize"}});}
	if(exists($command->{$urls->{"daemon/linecount"}})){$command->{$urls->{"daemon/linecount"}}=handleArray($command->{$urls->{"daemon/linecount"}});}
	if(exists($command->{$urls->{"daemon/seqcount"}})){$command->{$urls->{"daemon/seqcount"}}=handleArray($command->{$urls->{"daemon/seqcount"}});}
	if(exists($command->{$urls->{"daemon/import"}})){if(ref($command->{$urls->{"daemon/import"}}) ne "ARRAY"){$command->{$urls->{"daemon/import"}}=[$command->{$urls->{"daemon/import"}}];}}
	if(exists($command->{$urls->{"daemon/description"}})){$command->{$urls->{"daemon/description"}}=handleArray($command->{$urls->{"daemon/description"}});}
	if(exists($command->{$urls->{"daemon/insert"}})){$command->{"insertKeys"}=handleKeys($command->{$urls->{"daemon/insert"}});}
	if(exists($command->{$urls->{"daemon/update"}})){$command->{"updateKeys"}=handleKeys($command->{$urls->{"daemon/update"}});}
	if(exists($command->{$urls->{"daemon/delete"}})){$command->{"deleteKeys"}=handleKeys($command->{$urls->{"daemon/delete"}});}
	if(exists($command->{$urls->{"daemon/bash"}})){$command->{"bashCode"}=handleCode($command->{$urls->{"daemon/bash"}});}
	if(!exists($command->{$urls->{"daemon/maxjob"}})){$command->{$urls->{"daemon/maxjob"}}=1;}
	if(exists($command->{$urls->{"daemon/script"}})){handleScript($command);}
	if(scalar(keys(%{$default}))>0){$command->{"default"}=$default;}
}
############################## lookForNewCommands ##############################
sub lookForNewCommands{
	my $rdfdb=shift();
	my $query=shift();
	my $commands=shift();
	my $dbh=openDB($rdfdb);
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $rows=$sth->fetchall_arrayref();
	$dbh->disconnect;
	my @founds=();
	foreach my $row(@{$rows}){
		my $url=$row->[0];
		push(@founds,$url);
		loadCommandFromURL($url,$commands);
	}
	return @founds;
}
############################## mainProcess ##############################
sub mainProcess{
	my $execurls=shift();
	my $commands=shift();
	my $executes=shift();
	my $available=shift();
	my @deletes=();
	my @inserts=();
	my $thrown=0;
	for(my $i=0;($i<$available)&&(scalar(@{$execurls})>0);$i++){
		my $url=shift(@{$execurls});
		my $command=$commands->{$url};
		my $singlethread=(exists($command->{$urls->{"daemon/singlethread"}})&&$command->{$urls->{"daemon/singlethread"}} eq "true");
		my $qsubopt=$command->{$urls->{"daemon/qsubopt"}};
		my $maxjob=$command->{$urls->{"daemon/maxjob"}};
		if(!defined($maxjob)){$maxjob=1;}
		my $bashFiles=[];
		if(exists($command->{$urls->{"daemon/bash"}})){
			while(scalar(@{$executes->{$url}})>0){
				if(!$singlethread&&$maxjob<=0){last;}
				my $vars=shift(@{$executes->{$url}});
				initExecute($rdfdb,$command,$vars);
				push(@deletes,$urls->{"daemon"}."\t".$urls->{"daemon/execute"}."\t".$vars->{"nodeid"});
				my $datetime=`date +%s`;chomp($datetime);
				push(@inserts,$vars->{"nodeid"}."\t".$urls->{"daemon/timethrown"}."\t$datetime");
				bashCommand($command,$vars,$bashFiles);
				$maxjob--;
				$thrown++;
			}
		}
		throwJobs($bashFiles,$opt_q,$qsubopt,$url,1,$rootdir,$opt_c,$command->{$urls->{"daemon/docker"}});
		if(scalar(@{$executes->{$url}})>0){push(@{$execurls},$url);}
	}
	writeDeletes(@deletes);
	writeInserts(@inserts);
	return $thrown;
}
############################## mkdirs ##############################
# create directories recursively if necessary - 2007/01/24
# mkdirs( @directories );
sub mkdirs {
	my @directories = @_;
	foreach my $directory ( @directories ) {
		if( -d $directory ) { next; } # skip... since it already exists...
		my @tokens = split( /[\/\\]/, $directory );
		if( ( $tokens[ 0 ] eq "" ) && ( scalar( @tokens ) > 1 ) ) { # This happend when handling absolute path
			shift( @tokens ); # remove empty string
			my $token = shift( @tokens ); # get next string
			unshift( @tokens, "/$token" ); # push in
		}
		my $string = "";
		foreach my $token ( @tokens ) { # go through directory
			$string .= ( ( $string eq "" ) ? "" : "/" ) . $token;
			if( -d $string ) { next; } # directory already exists
			if( ! mkdir( $string ) ) { return 0; } # couldn't create directory
		}
	}
	return 1; # was able to create directory
}
############################## openDB ##############################
sub openDB{
	my $db=shift();
	my $dbh=DBI->connect("dbi:SQLite:dbname=$db");
	$dbh->do("CREATE TABLE IF NOT EXISTS node(id INTEGER PRIMARY KEY,data TEXT)");
	$dbh->do("CREATE TABLE IF NOT EXISTS edge(subject INTEGER,predicate INTEGER,object INTEGER,PRIMARY KEY (subject,predicate,object))");
	chmod(0777,$db);
	return $dbh;
}
############################## parseQuery ##############################
sub parseQuery{
	my @arguments=@_;
	my @statements=();
	foreach my $argument(@arguments){
		if(ref($argument)eq"ARRAY"){push(@statements,@{$argument});}
		else{push(@statements,$argument);}
	}
	my @edges=();
	foreach my $s(@statements){push(@edges,split(/,/,$s));}
	if(checkQuery(@edges)){exit(1);}
	my $connects={};
	my $vars={};
	my @columns=();
	my @joins=();
	my @where_conditions=();
	my $connections={};
	my $edge_conditions={};
	my $node_index=0;
	for(my $i=0;$i<scalar(@edges);$i++){
		my $edge_name="e$i";
		my $edge_line=($i>0)?"inner join ":"from ";
		my $edge=$edges[$i];
		my @nodes=split(/->/,$edge);
		my @wheres=();
		for(my $j=0;$j<scalar(@nodes);$j++){
			my $rdf;
			if($j==0){$rdf="subject";}
			elsif($j==1){$rdf="predicate";}
			elsif($j==2){$rdf="object";}
			my $node=$nodes[$j];
			my @nodeRegisters=();
			if($node eq ""){
			}elsif($node=~/^\!(.+)$/){
				my $var=$1;
				push(@where_conditions,"($edge_name.subject is null or $edge_name.subject not in (select subject from edge where $rdf=(select id from node where data='$var')))");
				if($i>0){$edge_line="left outer join ";}
			}elsif($node=~/^\$(.+)$/){
				my $node_name=$1;
				if(!exists($vars->{$node_name})){$vars->{$node_name}=scalar(keys(%{$vars}));push(@nodeRegisters,$node_name);}
				if(!exists($connections->{$node_name})){$connections->{$node_name}=[];}
				push(@{$connections->{$node_name}},"$edge_name.$rdf");
			}elsif($node=~/^\(.+\)$/){
				my @array=();
				foreach my $n(split(/\|/,$1)){
					if($n=~/%/){push(@array,"data like '$n'");}
					else{push(@array,"data='$n'");}
					$node_index++;
				}
				push(@wheres,"$rdf in (select id from node where ".join(" or ",@array).")");
			}else{
				push(@wheres,"$rdf=(select id from node where data='$node')");
				$node_index++;
			}
			foreach my $node_name(@nodeRegisters){push(@joins,"inner join node as $node_name on $edge_name.$rdf=$node_name.id");}
		}
		if(scalar(@wheres)>0){$edge_line.="(select * from edge where ".join(" and ",@wheres).")"}
		else{$edge_line.="edge";}
		$connects->{$edge_name}="$edge_line as $edge_name";
	}
	my @varnames=sort{$vars->{$a}<=>$vars->{$b}}keys(%{$vars});
	foreach my $var (@varnames){push(@columns,"$var.data");}
	foreach my $connection (values(%{$connections})){
		my $before=$connection->[0];
		for(my $i=1;$i<scalar(@{$connection});$i++){
			my $after=$connection->[$i];
			my $edge=substr($after,0,index($after,"."));
			if(!exists($edge_conditions->{$edge})){$edge_conditions->{$edge}=[];}
			push(@{$edge_conditions->{$edge}},"$after=$before");
			$before=$after;
		}
	}
	foreach my $edge (keys(%{$edge_conditions})){$connects->{$edge}.=" on (".join(" and ",@{$edge_conditions->{$edge}}).")";}
	my @connects2=();
	foreach my $key(sort{$a cmp $b}keys(%{$connects})){push(@connects2,$connects->{$key});}
	my $query="select distinct ".join(", ",@columns)." ".join(" ",@connects2)." ".join(" ",@joins);
	if(scalar(@where_conditions)>0){$query.=" where ".join(" and ",@where_conditions);}
	my @inputs=();
	foreach my $var(@varnames){if($var ne "nodeid"){push(@inputs,$var);}}
	return ($query,\@varnames,\@inputs);
}
############################## printCommand ##############################
sub printCommand{
	my $url=shift();
	my $commands=shift();
	my $command=loadCommandFromURL($url,$commands);
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	print STDOUT "\n#URL     :".$command->{$urls->{"daemon/command"}}."\n";
	my $cmdline="#Command :".basename($command->{$urls->{"daemon/command"}});
	if(scalar(@inputs)>0){$cmdline.=" [".join("] [",@inputs)."]";}
	if(scalar(@outputs)>0){$cmdline.=" [".join("] [",@outputs)."]";}
	print STDOUT "$cmdline\n";
	if(exists($command->{$urls->{"daemon/select"}})){print STDOUT "#Select  :".join("\n         :",@{$command->{$urls->{"daemon/select"}}})."\n";}
	if(exists($command->{$urls->{"daemon/insert"}})&&scalar(@{$command->{$urls->{"daemon/insert"}}})>0){print STDOUT "#Insert  :".join("\n         :",@{$command->{$urls->{"daemon/insert"}}})."\n";}
	if(scalar(@inputs)>0){print STDOUT "#Input   :".join(", ",@{$command->{"input"}})."\n";}
	if(scalar(@outputs)>0){print STDOUT "#Output  :".join(", ",@{$command->{"output"}})."\n";}
	print STDOUT "#Bash    :";
	if(ref($command->{$urls->{"daemon/bash"}}) ne "ARRAY"){print STDOUT $command->{$urls->{"daemon/bash"}}."\n";}
	else{my $index=0;foreach my $line(@{$command->{$urls->{"daemon/bash"}}}){if($index++>0){print STDOUT "         :"}print STDOUT "$line\n";}}
	if(exists($command->{$urls->{"daemon/description"}})){print STDOUT "#Summary :".join(", ",@{$command->{$urls->{"daemon/description"}}})."\n";}
	if($command->{$urls->{"daemon/maxjob"}}>1){print STDOUT "#Maxjob  :".$command->{$urls->{"daemon/maxjob"}}."\n";}
	if(exists($command->{$urls->{"daemon/singlethread"}})){print STDOUT "#Single  :".($command->{$urls->{"daemon/singlethread"}}?"true":"false")."\n";}
	if(exists($command->{$urls->{"daemon/qsubopt"}})){print STDOUT "#QsubOpt :".$command->{$urls->{"daemon/qsubopt"}}."\n";}
	if(exists($command->{$urls->{"daemon/script"}})){
		foreach my $script(@{$command->{$urls->{"daemon/script"}}}){
			print STDOUT "#Script  :".$script->{$urls->{"daemon/script/name"}}."\n";
			foreach my $line(@{$script->{$urls->{"daemon/script/code"}}}){
				print STDOUT "         :$line\n";
			}
		}
	}
	print STDOUT "\n";
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
############################## printRows ##############################
sub printRows{
	my $keys=shift();
	my $hashtable=shift();
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
	print STDERR "$tableline\n";
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
	print STDERR "$labelline\n";
	print STDERR "$tableline\n";
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
		print STDERR "$line\n";
	}
	print STDERR "$tableline\n";
}
############################## promtCommandInput ##############################
sub promtCommandInput{
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
############################## removeDollar ##############################
sub removeDollar{
	my $value=shift();
	if($value=~/^\$(.+)$/){return $1;}
	return $value;
}
############################## removeUnnecessaryExecutes ##############################
sub removeUnnecessaryExecutes{
	my $queryResults=shift();
	my $insertKeys=shift();
	my $results={};
	my $temp={};
	foreach my $out(@{$insertKeys}){
		my $subject=$out->[0];
		my $predicate=$out->[1];
		my $object=$out->[2];
		if($subject=~/^\$/){$subject="%";}
		if($object=~/^\$/){$object="%";}
		my @results=selectRDF($rdfdb,$subject,$predicate,$object);
		$results->{$predicate}=\@results;
	}
	my @array=();
	foreach my $hash(@{$queryResults->{".hashs"}}){
		my $hit=0;
		foreach my $out(@{$insertKeys}){
			my $pred=$out->[1];
			my @array=@{$results->{$pred}};
			if($out->[0]=~/^\$(.+)$/){
				my $key=$1;
				my $val=$out->[0];
				if($hash->{$key}){$val=$hash->{$key};}
				foreach my $t(@array){if($t->[0] eq $val){$hit=1;last;}}
				if($hit==1){last;}
			}
			if($out->[2]=~/^\$(.+)$/){
				my $key=$1;
				my $val=$out->[2];
				if($hash->{$key}){$val=$hash->{$key};}
				foreach my $t(@array){if($t->[2] eq $val){$hit=1;last;}}
				if($hit==1){last;}
			}
		}
		if($hit==0){push(@array,$hash);}
	}
	$queryResults->{".hashs"}=\@array;
}
############################## replaceStringWithHash ##############################
sub replaceStringWithHash{
	my $hash=shift();
	my $string=shift();
	my @keys=sort{length($b)<=>length($a)}keys(%{$hash});
	foreach my $key(@keys){my $value=$hash->{$key};$key="\\\$$key";$string=~s/$key/$value/g;}
	return $string;
}
############################## sandbox ##############################
sub sandbox{
	my @lines=@_;
	my $center=shift(@lines);
	my $length=0;
	foreach my $line(@lines){my $l=length($line);if($l>$length){$length=$l;}}
	my $label="";
	for(my $i=0;$i<$length+4;$i++){$label.="#";}
	print STDERR "$label\n";
	foreach my $line(@lines){
		for(my $i=length($line);$i<$length;$i++){
			if($center){if(($i%2)==0){$line.=" ";}else{$line=" $line";}}
			else{$line.=" ";}
		}
		print STDERR "# $line #\n";
	}
	print STDERR "$label\n";
}
############################## script ##############################
sub script{
	my @urls=@_;
	my $outdir=$opt_o;
	if(!defined($outdir)){$outdir=".";}
	mkdir($outdir);
	foreach my $url(@urls){
		foreach my $out(writeScript($url,$outdir,$commands)){print "$out\n";}
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
############################## test ##############################
sub test{
	mkdir(test);
	unlink("test/rdf.sqlite3");
	open(OUT,">test/A.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/input\":\"\$string\",\"https://moirai2.github.io/schema/daemon/bash\":[\"output=\\\"\$workdir/output.txt\\\"\",\"echo \\\"\$string\\\" > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}\n";
	close(OUT);
	open(OUT,">test/B.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/input\":\"\$input\",\"https://moirai2.github.io/schema/daemon/bash\":[\"output=\\\"\$workdir/output.txt\\\"\",\"sort \$input > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}\n";
	close(OUT);
	open(OUT,">test/C.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/docker\":\"ubuntu\",\"https://moirai2.github.io/schema/daemon/bash\":\"unamea=\$(uname -a)\",\"https://moirai2.github.io/schema/daemon/output\":\"\$unamea\"}\n";
	close(OUT);
	testCommand("perl moirai2.pl -d test/rdf.sqlite3 -s 1 -r '\$output' test/A.json 'Akira Hasegawa' output.txt","output.txt");
	testCommand("cat test/output.txt","Akira Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test/rdf.sqlite3 insert case1 '#string' 'Akira Hasegawa'","inserted 1");
	testCommand("perl moirai2.pl -d test/rdf.sqlite3 -s 1 -i '\$id->#string->\$string' -o '\$id->#text->\$output' test/A.json '\$string' '\$id.txt'","");
	testCommand("cat test/case1.txt","Akira Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test/rdf.sqlite3 object case1 '#text'","case1.txt");
	testCommand("perl moirai2.pl -d test/rdf.sqlite3 -s 1 -i '\$id->#text->\$input' -o '\$input->#sorted->\$output' test/B.json 'output=\$id.sort.txt'","");
	testCommand("cat test/case1.sort.txt","Akira Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test/rdf.sqlite3 object % '#sorted'","case1.sort.txt");
	open(OUT,">test/case2.txt");print OUT "Hasegawa\nAkira\nChiyo\nHasegawa\n";close(OUT);
	testCommand("perl $prgdir/rdf.pl -d test/rdf.sqlite3 insert case2 '#text' case2.txt","inserted 1");
	testCommand("perl moirai2.pl -d test/rdf.sqlite3 -s 1 -i '\$id->#text->\$input' -o '\$input->#sorted->\$output' test/B.json 'output=\$id.sort.txt'","");
	testCommand("cat test/case2.sort.txt","Akira\nChiyo\nHasegawa\nHasegawa");
	my $name=`uname -s`;chomp($name);
	testCommand2("perl moirai2.pl -d test/rdf.sqlite3 -r unamea test/C.json","^$name");
	testCommand2("perl moirai2.pl -q -d test/rdf.sqlite3 -r unamea test/C.json","^$name");
	testCommand2("perl moirai2.pl -d test/rdf.sqlite3 -r unamea -c docker test/C.json","^Linux");
	testCommand2("perl moirai2.pl -q -d test/rdf.sqlite3 -r unamea -c docker test/C.json","^Linux");
	unlink("test/output.txt");
	unlink("test/case1.txt");
	unlink("test/case2.txt");
	unlink("test/case1.sort.txt");
	unlink("test/case2.sort.txt");
	unlink("test/A.json");
	unlink("test/B.json");
	unlink("test/C.json");
	open(OUT,">test/rdf/ctrl/insert/A.txt");
	print OUT "A\t#name\tAkira\n";
	close(OUT);
	system("echo 'mkdir -p rdf/\$dirname'|perl moirai2.pl -d test/rdf.sqlite3 -i '\$id->#name->\$dirname' -o '\$id->#mkdir->done' command");
	if(!-e "test/rdf/Akira"){print STDERR "test/rdf/Akira directory not created";}
	open(OUT,">test/rdf/ctrl/insert/B.txt");
	print OUT "B\t#name\tBen\n";
	close(OUT);
	system("echo 'mkdir -p rdf/\$dirname'|perl moirai2.pl -d test/rdf.sqlite3 -i '\$id->#name->\$dirname' -o '\$id->#mkdir->done' command");
	if(!-e "test/rdf/Ben"){print STDERR "test/rdf/Ben directory not created";}
	system("rm -r test/rdf");
	unlink("test/rdf.sqlite3");
	rmdir("test/bin");
	rmdir("test");
}
############################## testCommand ##############################
sub testCommand{
	my $command=shift();
	my $value2=shift();
	my ($writer,$file)=tempfile(UNLINK=>1);
	close($writer);
	if(system("$command > $file")){return 1;}
	my $value1=readText($file);
	chomp($value1);
	if($value1 eq $value2){return 0;}
	print STDERR ">$command\n";
	print STDERR "$value1\n";
	print STDERR "$value2\n";
}
############################## testCommand2 ##############################
sub testCommand2{
	my $command=shift();
	my $value2=shift();
	my ($writer,$file)=tempfile(UNLINK=>1);
	close($writer);
	if(system("$command > $file")){return 1;}
	my $value1=readText($file);
	chomp($value1);
	if($value1=~/$value2/){return 0;}
	print STDERR ">$command\n";
	print STDERR "[$value1]\n";
	print STDERR "[$value2]\n";
}
############################## throwJobs ##############################
sub throwJobs{
	my $bashFiles=shift();
	my $use_qsub=shift();
	my $qsubopt=shift();
	my $url=shift();
	my $background=shift();
	my $rootdir=shift();
	my $use_container=shift();
	my $docker_image=shift();
	if(scalar(@{$bashFiles})==0){return;}
	my $template=($use_qsub)?"$ctrldir/bash/qsubXXXXXXXXXX":"$ctrldir/bash/bashXXXXXXXXXX";
	my ($fh,$path)=mkstemps($template,".sh");
	my $fileid=basename($path,".sh");
	my $qsub_stderr="$ctrldir/$fileid.stderr";
	my $qsub_stdout="$ctrldir/$fileid.stdout";
	if($use_qsub){
		print $fh "#\$ -e $qsub_stderr\n";
		print $fh "#\$ -o $qsub_stdout\n";
	}
	print $fh "PATH=$exportpath\n";
	my @ids=();
	foreach my $files(@{$bashFiles}){
		my ($bashFile,$stdoutFile,$stderrFile,$nodeid)=@{$files};
		if($nodeid=~/(.+)#(.+)/){push(@ids,"#$2");}
		else{push(@ids,$nodeid);}
		if($use_container eq "docker"){
			if(!defined($docker_image)){$docker_image="ubuntu";}
			print $fh "docker \\\n";
			print $fh "  run \\\n";
			print $fh "  --rm \\\n";
			print $fh "  --workdir=/root \\\n";
			print $fh "  -v '$rootdir:/root' \\\n";
			print $fh "  $docker_image \\\n";
			print $fh "  /bin/bash $bashFile \\\n";
			print $fh "  > $qsub_stderr \\\n";
			print $fh "  2> $stderrFile\n";
		}elsif($use_container eq "udocker"){
			print $fh "udocker \\\n";
			print $fh "  --repo=$udockerDirectory \\\n";
			print $fh "  run \\\n";
			print $fh "  --rm \\\n";
			print $fh "  --user=root \\\n";
			print $fh "  --workdir=/root \\\n";
			print $fh "  --volume=$rootdir:/root \\\n";
			print $fh "  $docker_image \\\n";
			print $fh "  /bin/bash $bashFile \\\n";
			print $fh "  > $stdoutFile \\\n";
			print $fh "  2> $stderrFile\n";
		}elsif($use_container eq "singularity"){
			$docker_image="$singularityDirectory/$docker_image.sif";
			print $fh "singularity \\\n";
			print $fh "  exec \\\n";
			print $fh "  --bind=$rootdir:/root \\\n";
			print $fh "  $docker_image \\\n";
			print $fh "  /bin/bash $bashFile \\\n";
			print $fh "  > $stdoutFile \\\n";
			print $fh "  2> $stderrFile\n";
		}else{
			print $fh "bash $bashFile \\\n";
			print $fh "  > $stdoutFile \\\n";
			print $fh "  2> $stderrFile\n";
		}
	}
	if($use_qsub||defined($use_container)){
		print $fh "if [ ! -s $qsub_stderr ];then\n";
		print $fh "rm -f $qsub_stderr\n";
		print $fh "fi\n";
		print $fh "if [ ! -s $qsub_stdout ];then\n";
		print $fh "rm -f $qsub_stdout\n";
		print $fh "fi\n";
	}
	print $fh "rm -f $path\n";
	close($fh);
	my $number=scalar(@{$bashFiles});
	my $date=getDate("/");
	my $time=getTime(":");
	if($use_qsub){
		if(defined($opt_l)){print STDERR "$date $time Submitting job ".join(",",@ids).":\t";}
		my $command="qsub";
		if(defined($qsubopt)){$command.=" $qsubopt";}
		$command.=" $path";
		if(system($command)==0){if(defined($opt_l)){print STDERR "OK\n";}}
		else{print "ERROR: Failed to $command\n";exit(1);}
	}else{
		if(defined($opt_l)){print STDERR "$date $time Executing jobs ".join(",",@ids).":\t";}
		my $command="bash $path";
		if(defined($background)){$command.=" &";}
		if(system($command)==0){if(defined($opt_l)){print STDERR "OK\n";}}
		else{if(defined($opt_l)){print STDERR "ERROR: Failed to $command\n";}exit(1);}
	}
}
############################## writeCompleteFile ##############################
sub writeCompleteFile{
	my $completedfile=shift();
	my $stdoutfile=shift();
	my $stderrfile=shift();
	my $insertfile=shift();
	my $deletefile=shift();
	my $updatefile=shift();
	my $bashfile=shift();
	my $scriptfiles=shift();
	my $ctrldir=shift();
	my $workdir=shift();
	open(OUT,">$completedfile");
	print OUT "keep=0\n";
	print OUT "if [ -s $stdoutfile ];then\n";
	print OUT "keep=1\n";
	print OUT "else\n";
	print OUT "rm -f $stdoutfile\n";
	print OUT "fi\n";
	print OUT "if [ -s $stderrfile ];then\n";
	print OUT "keep=1\n";
	print OUT "else\n";
	print OUT "rm -f $stderrfile\n";
	print OUT "fi\n";
	print OUT "if [ -s $insertfile ];then\n";
	print OUT "if [ \$keep = 1 ];then\n";
	print OUT "ln -s $insertfile $ctrldir/insert/.\n";
	print OUT "else\n";
	print OUT "mv $insertfile $ctrldir/insert/.\n";
	print OUT "fi\n";
	print OUT "fi\n";
	print OUT "if [ -s $deletefile ];then\n";
	print OUT "if [ \$keep = 1 ];then\n";
	print OUT "ln -s $deletefile $ctrldir/delete/.\n";
	print OUT "else\n";
	print OUT "mv $deletefile $ctrldir/delete/.\n";
	print OUT "fi\n";
	print OUT "fi\n";
	print OUT "if [ -s $updatefile ];then\n";
	print OUT "if [ \$keep = 1 ];then\n";
	print OUT "ln -s $updatefile $ctrldir/update/.\n";
	print OUT "else\n";
	print OUT "mv $updatefile $ctrldir/update/.\n";
	print OUT "fi\n";
	print OUT "fi\n";
	print OUT "if [ \$keep = 0 ];then\n";
	print OUT "rm -f $bashfile\n";
	foreach my $scriptfile(@{$scriptfiles}){print OUT "rm -f $scriptfile\n";}
	print OUT "fi\n";
	print OUT "rmdir $workdir/ > /dev/null 2>&1\n";
	close(OUT);
}
############################## writeDeletes ##############################
sub writeDeletes{
	my @lines=@_;
	if(scalar(@lines)>0){
		my ($fh,$file)=mkstemps("$ctrldir/delete/XXXXXXXXXX",".delete");
		foreach my $line(@lines){print $fh "$line\n";}
		close($fh);
	}
}
############################## writeInserts ##############################
sub writeInserts{
	my @lines=@_;
	if(scalar(@lines)>0){
		my ($fh,$file)=mkstemps("$ctrldir/insert/XXXXXXXXXX",".insert");
		foreach my $line(@lines){print $fh "$line\n";}
		close($fh);
	}
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
