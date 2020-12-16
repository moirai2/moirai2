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
use vars qw($opt_c $opt_d $opt_g $opt_G $opt_h $opt_H $opt_i $opt_l $opt_m $opt_o $opt_p $opt_q $opt_r $opt_s $opt_t);
getopts('c:d:g:G:hHi:lm:o:pqr:s:t:');
############################## CONFIG ##############################
my $udockerDirectory="/work/ah3q/udocker";
my $singularityDirectory="/work/ah3q/singularity";
############################## URLs ##############################
my $urls={};
$urls->{"daemon"}="https://moirai2.github.io/schema/daemon";
$urls->{"daemon/import"}="https://moirai2.github.io/schema/daemon/import";
$urls->{"daemon/import/tag"}="https://moirai2.github.io/schema/daemon/import/tag";
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
$urls->{"daemon/command/line"}="https://moirai2.github.io/schema/daemon/command/line";
$urls->{"daemon/execute"}="https://moirai2.github.io/schema/daemon/execute";
$urls->{"daemon/timeended"}="https://moirai2.github.io/schema/daemon/timeended";
$urls->{"daemon/timestarted"}="https://moirai2.github.io/schema/daemon/timestarted";
$urls->{"daemon/timethrown"}="https://moirai2.github.io/schema/daemon/timethrown";
$urls->{"daemon/unzip"}="https://moirai2.github.io/schema/daemon/unzip";
$urls->{"daemon/description"}="https://moirai2.github.io/schema/daemon/description";
$urls->{"daemon/docker"}="https://moirai2.github.io/schema/daemon/docker";
$urls->{"daemon/error/file/empty"}="https://moirai2.github.io/schema/daemon/error/file/empty";
$urls->{"daemon/error/stderr/ignore"}="https://moirai2.github.io/schema/daemon/error/stderr/ignore";
$urls->{"daemon/error/stdout/ignore"}="https://moirai2.github.io/schema/daemon/error/stdout/ignore";
$urls->{"daemon/md5"}="https://moirai2.github.io/schema/daemon/md5";
$urls->{"daemon/filesize"}="https://moirai2.github.io/schema/daemon/filesize";
$urls->{"daemon/linecount"}="https://moirai2.github.io/schema/daemon/linecount";
$urls->{"daemon/seqcount"}="https://moirai2.github.io/schema/daemon/seqcount";
############################## HELP ##############################
sub help{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Handles MOIRAI2 command using RDF database.\n";
	print "Version: 2020/12/16\n";
	print "Author: Akira Hasegawa (akira.hasegawa\@riken.jp)\n";
	print "\n";
	print "Usage: perl $program_name [Options] COMMAND\n";
	print "\n";
	print "Commands:   assign  Insert user specified triple if SBJ->PRE is not found in RDF database\n";
	print "          automate  Run bash script located under ctrl/automate directory\n";
	print "             check  Check if values specified in input options are same\n";
	print "           command  Execute user specified command instead of a command json URL\n";
	print "            daemon  Look for moirai2 ctrl directories and run automate if there were updates\n";
	print "           compact  Compact scripts and bash files from a command json URL\n";
	print "           extract  Extract scripts and bash files from a command json URL\n";
	print "              html  Create a HTML representation of RDF database\n";
	print "                ls  Create triples from directories/files and show or store them in RDF database\n";
	print "              test  For development purpose (test commands)\n";
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
	print "         -d  RDF database directory (default='moirai').\n";
	print "         -f  file linecount/seqcount/md5/filesize.\n";
	print "         -h  Show help message.\n";
	print "         -H  Show update history.\n";
	print "         -i  Input query for select from database in '\$sub->\$pred->\$obj' format.\n";
	print "         -l  Show STDERR and STDOUT logs from moirai.pl.\n";
	print "         -m  Max number of jobs to throw (default='5').\n";
	print "         -o  Output query for insert to database in '\$sub->\$pred->\$obj' format.\n";
	print "         -p  Prompt input parameter(s) to user, if value is necessary.\n";
	print "         -q  Use qsub for throwing jobs.\n";
	print "         -r  Print return value.\n";
	print "         -s  Loop second (default='10').\n";
	print "         -t  Tag added before predicate when import command is used (default=none).\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "(1) perl $program_name https://moirai2.github.io/command/text/sort.json\n";
	print "\n";
	print " - Executes a sort command with user prompt for input.\n";
	print "\n";
	print "(2) perl $program_name -h https://moirai2.github.io/command/text/sort.json\n";
	print "\n";
	print " - Shows information of a command.\n";
	print "\n";
	print "(3) perl $program_name https://moirai2.github.io/command/text/sort.json input.txt\n";
	print "\n";
	print " - Executes a sort command by specifying input with arguments.\n";
	print " - Output will be sotred in rdf/work.XXXXXXXXX/ directory.\n";
	print "\n";
	print "(4) perl $program_name https://moirai2.github.io/command/text/sort.json input.txt output.txt\n";
	print "\n";
	print " - Executes a sort command by specifying input and output with arguments.\n";
	print " - By specifying output path in argument, output will be saved at specified path.\n";
	print "\n";
	print "(5) perl $program_name https://moirai2.github.io/command/text/sort.json '\$input=input.txt' '\$output=output.txt'\n";
	print "\n";
	print " - Executes a sort command by specifying input and output with variables.\n";
	print " - Input and output variables can be assigned with '='.\n";
	print "\n";
	print "(6) perl $program_name -i 'A->input->\$input' -o 'A->output->\$output' https://moirai2.github.io/command/text/sort.json\n";
	print "\n";
	print " - Executes a sort command with a RDF database and updates.\n";
	print "\n";
	if(defined($opt_H)){
		print "############################## Updates ##############################\n";
		print "\n";
		print "2020/12/16  'check' command added to check values.\n";
		print "2020/12/15  'html' command  added to report workflow in HTML format.\n";
		print "2020/12/14  Create and keep json file from user defined command\n";
		print "2020/12/13  'empty output' and 'ignore stderr/stout' functions added.\n";
		print "2020/12/12  stdout and stderr reported to log file.\n";
		print "2020/12/11  'assign' function added.\n";
		print "2020/12/01  Adapt to new rdf.pl.\n";
		print "2020/11/20  Import and execute workflow bash file.\n";
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
		print "2018/02/01  Created to throw jobs registered in RDF database.\n";
		print "\n";
	}
	exit(0);
}
sub help_assign{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Usage: perl $program_name [Options] assign";
	print "\n";
	print "Options: -o  Output query to assign in '\$sub->\$pred->\$obj' format.\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "1) perl $program_name -o 'A->B->C' assign\n";
	print " - Insert 'A->B->C' triple, if 'A->B->?' is not found in the RDF database.\n";
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
	print "         -d  RDF database directory (default='moirai').\n";
	print "         -i  Input query for select in '\$sub->\$pred->\$obj' format.\n";
	print "         -l  Show STDERR and STDOUT logs.\n";
	print "         -m  Max number of jobs to throw (default='5').\n";
	print "         -o  Output query for insert in '\$sub->\$pred->\$obj' format.\n";
	print "         -q  Use qsub for throwing jobs.\n";
	print "         -r  Print return value.\n";
	print "         -s  Loop second (default='10').\n";	print "\n";
	print "         -t  Tag added before predicate when import command is used (default=none).\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "(1) perl $program_name -o 'root->input->\$output' command << 'EOS'\n";
	print "output=(`ls`)\n";
	print "EOS\n";
	print "\n";
	print " - ls and store them in database with root->input->\$output format.\n";
	print " - When you want an array, be sure to quote with ().\n";
	print "\n";
	print "(2) echo 'output=(`ls`)'|perl $program_name -o 'root->input->\$output' command\n";
	print "\n";
	print " - It is same as example1, but without using 'EOS' notation.\n";
	print "\n";
	print "(3) perl $program_name -i 'A->input->\$input' -o 'A->output->\$output' command << 'EOS'\n";
	print "output=sort/\${input.basename}.txt\n";
	print "sort \$input > \$output\n";
	print "EOS\n";
	print "\n";
	print " - Does sort on the \$input and creates a sorted file \$output\n";
	print " - Query database with 'A->input->\$input' and store new triple 'A->output->\$output'.\n";
	print "\n";
}
sub help_html{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Print out a HTML representation of the database.\n";
	print "\n";
	print "Usage: perl $program_name [Options] html \n";
	print "\n";
}
sub help_extract{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Extracts script and bash files from URL and save them to a directory.\n";
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
	print "Options: -o  Log output directory (default='daemon').\n";
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
	print "Options: -d  RDF database directory (default='moirai').\n";
	print "         -g  grep specific string\n";
	print "         -G  ungrep specific string\n";
	print "         -i  Input query for select in '\$sub->\$pred->\$obj' format.\n";
	print "         -l  Print out logs instead of importing results to the database.\n";
	print "         -o  Output query for insert in '\$sub->\$pred->\$obj' format.\n";
	print "         -r  Recursive search (default=0)\n";
	print "\n";
	print "Variables:\n";
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
	print " - When -i option is used, search will be canceled.\n";
	print " - Use \$file variable for -i option, when specifying a file path.\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "1) perl $program_name -r 0 -g A -G B -o '\$basename->id->\$path' ls DIR DIR2 ..\n";
	print " - List files under DIR and DIR2 with 0 recursion and filename with A and filename without B.\n";
	print "\n";
	print "2) perl $program_name -i 'root->input->\$file->' -o '\$basename->id->\$path' ls\n";
	print " - Go look for file in the database and handle.\n";
	print "\n";
}
############################## MAIN ##############################
my $commands={};
if(defined($opt_h)&&$ARGV[0]=~/\.json$/){printCommand($ARGV[0],$commands);exit(0);}
if(defined($opt_h)&&$ARGV[0]=~/\.(ba)?sh$/){printWorkflow($ARGV[0],$commands);exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"daemon"){help_daemon();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"ls"){help_ls();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"extract"){help_extract();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"command"){help_command();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"file"){help_file();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"assign"){help_assign();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"html"){help_html();exit(0);}
if(defined($opt_h)&&scalar(@ARGV)>0&&$ARGV[0]eq"check"){help_check();exit(0);}
if(defined($opt_h)||defined($opt_H)||scalar(@ARGV)==0){help();}
my $moiraidir=(defined($opt_d))?$opt_d:"moirai";
if($moiraidir=~/^(.+)\/$/){$moiraidir=$1;}
my $rootdir=absolutePath(".");
my $basename=basename($moiraidir);
my $bindir="$rootdir/bin";
my $dbdir="$moiraidir/db";
my $logdir="$moiraidir/log";
my $errordir="$logdir/error";
my $checkdir="$logdir/check";
my $jsondir="$logdir/json";
my $ctrldir="$moiraidir/ctrl";
my $home=`echo \$HOME`;chomp($home);
my $exportpath="$bindir:$home/bin:\$PATH";
my $sleeptime=defined($opt_s)?$opt_s:10;
my $maxjob=defined($opt_m)?$opt_m:5;
if($ARGV[0] eq "assign"){shift(@ARGV);assign(@ARGV);exit(0);}
if($ARGV[0] eq "daemon"){shift(@ARGV);daemon(@ARGV);exit(0);}
if($ARGV[0] eq "test"){shift(@ARGV);test();exit(0);}
if($ARGV[0] eq "extract"){shift(@ARGV);extract(@ARGV);exit(0);}
if($ARGV[0] eq "html"){shift(@ARGV);html(@ARGV);exit(0);}
mkdir($moiraidir);chmod(0777,$moiraidir);
mkdir($dbdir);chmod(0777,$dbdir);
mkdir($logdir);chmod(0777,$logdir);
mkdir($errordir);chmod(0777,$errordir);
mkdir($jsondir);chmod(0777,$jsondir);
mkdir($bindir);chmod(0777,$bindir);
mkdir($ctrldir);chmod(0777,$ctrldir);
mkdir($checkdir);chmod(0777,$checkdir);
mkdir("$ctrldir/bash");chmod(0777,"$ctrldir/bash");
mkdir("$ctrldir/insert");chmod(0777,"$ctrldir/insert");
mkdir("$ctrldir/log");chmod(0777,"$ctrldir/log");
mkdir("$ctrldir/completed");chmod(0777,"$ctrldir/completed");
mkdir("$ctrldir/submit");chmod(0777,"$ctrldir/submit");
mkdir("$ctrldir/error");chmod(0777,"$ctrldir/error");
if($ARGV[0] eq "ls"){shift(@ARGV);ls(@ARGV);exit(0);}
if($ARGV[0] eq "check"){shift(@ARGV);check(@ARGV);exit(0);}
#just in case jobs are completed while moirai2.pl was not running by termination
my $executes={};
controlProcess($executes);
if(getNumberOfJobsRunning()>0){
	print STDERR "There are jobs remaining in ctrl/bash directory.\n";
	print STDERR "Do you want to delete these jobs [y/n]? ";
	my $prompt=<STDIN>;
	chomp($prompt);
	if($prompt ne "y"&&$prompt ne "yes"&&$prompt ne "Y"&&$prompt ne "YES"){system("rm $ctrldir/bash/*");}
}
if($ARGV[0] eq "automate"){automate();exit(0);}
##### handle inputs and outputs #####
my $queryResults={};
my $userdefined={};
my $queryKeys;
my $insertKeys;
if(defined($opt_i)){checkInputOutput($opt_i);}
if(defined($opt_o)){checkInputOutput($opt_o);}
if(defined($opt_i)){
	$queryKeys=handleKeys($opt_i);
	$queryResults=getQueryResults($dbdir,$userdefined,$opt_i);
}
if(!exists($queryResults->{".hashs"})){$queryResults->{".hashs"}=[{}];}
if(defined($opt_o)){
	$insertKeys=handleKeys($opt_o);
	if(defined($opt_i)){removeUnnecessaryExecutes($queryResults,$insertKeys);}
}
if(defined($opt_l)){printRows($queryResults->{".keys"},$queryResults->{".hashs"});}
##### handle commmand #####
my @execids;
my $cmdurl=shift(@ARGV);
my $cmdLine;
if($cmdurl eq "command"){
	my @lines=();
	my ($inputs,$outputs)=handleInputOutput($insertKeys,$queryResults);
	while(<STDIN>){chomp;push(@lines,$_);if(defined($cmdLine)){$cmdLine.=",$_"}else{$cmdLine.=$_;}}
	$cmdurl=createJson($moiraidir,$inputs,$outputs,@lines);
}
if(defined($cmdurl)){
	my ($arguments,$userdefined)=handleArguments(@ARGV);
	@execids=commandProcess($cmdurl,$commands,$queryResults,$userdefined,$queryKeys,$insertKeys,$cmdLine,@{$arguments});
	if(defined($opt_r)){$commands->{$cmdurl}->{$urls->{"daemon/return"}}=removeDollar($opt_r);}
}
##### process #####
my @execurls=();
while(true){
	controlProcess($executes);
	if(getNumberOfJobsRemaining($executes)<$maxjob){
		foreach my $url(lookForNewCommands($dbdir,$commands)){
			my $job=getExecuteJobs($dbdir,$commands->{$url},$executes);
			if($job>0){if(!existsArray(\@execurls,$url)){push(@execurls,$url);}}
		}
	}
	my $jobs_running=getNumberOfJobsRunning();
	if($jobs_running<$maxjob){mainProcess(\@execurls,$commands,$executes,$maxjob-$jobs_running);}
	$jobs_running=getNumberOfJobsRunning();
	if(getNumberOfJobsRemaining($executes)==0&&$jobs_running==0){controlProcess($executes);last;}
	else{sleep($sleeptime);}
}
if(!defined($cmdurl)){
	# command URL not defined
}elsif(defined($opt_o)){
	# Output are defined, so don't print return
}elsif(exists($commands->{$cmdurl}->{$urls->{"daemon/return"}})){
	my $returnvalue=$commands->{$cmdurl}->{$urls->{"daemon/return"}};
	foreach my $execid(sort{$a cmp $b}@execids){
		my $result=`perl $prgdir/rdf.pl -d $moiraidir return $execid $cmdurl#$returnvalue`;
		chomp($result);
		print "$result\n";
	}
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
############################## check ##############################
sub check{
	my @checks=@_;
	if(!defined($opt_i)){print STDERR "Please use option 'i' to assign triple query\n";exit(1);}
	else{checkInputOutput($opt_i);}
	my $queryResults=getQueryResults($dbdir,$userdefined,$opt_i);
	if(defined($opt_o)){
		checkInputOutput($opt_o);
		my $insertKeys=handleKeys($opt_o);
		removeUnnecessaryExecutes($queryResults,$insertKeys);
		my ($writer,$temp)=tempfile(UNLINK=>1);
		my ($writer2,$temp2)=tempfile();
		foreach my $result(@{$queryResults->{".hashs"}}){
			my @lines=checkEval($result,$opt_i,@checks);
			foreach my $line(@lines){print $writer2 "$line\n";}
			my $check=(scalar(@lines)>0)?"ERROR":"OK";
			foreach my $insert(@{$insertKeys}){
				my $line=join("\t",@{$insert});
				while(my($key,$val)=each(%{$result})){$line=~s/\$$key/$val/g;}
				$line=~s/\$check/$check/g;
				print $writer "$line\n";
			}
		}
		close($writer2);
		close($writer);
		system("perl $prgdir/rdf.pl -d $moiraidir import < $temp");
		if(-s $temp2){
			my $id="c".getDatetime();
			my $file="$checkdir/$id.txt";
			while(existsLogFile($file)){
				sleep(1);
				$id="e".getDatetime();
				$file="$checkdir/$id.txt";
			}
			system("mv $temp2 $file");
		}
	}else{
		foreach my $result(@{$queryResults->{".hashs"}}){
			my @lines=checkEval($result,$opt_i,@checks);
			if(scalar(@lines)>0){foreach my $line(@lines){print "$line\n";}}
		}
	}
}
############################## html ##############################
sub html{
	print "<html>\n";
	print "<head>\n";
	print "<title>$basename</title>\n";
	print "<script type=\"text/javascript\" src=\"js/vis/vis-network.min.js\"></script>\n";
	print "<script type=\"text/javascript\" src=\"js/jquery/jquery-3.4.1.min.js\"></script>\n";
	print "<script type=\"text/javascript\" src=\"js/jquery/jquery.columns.min.js\"></script>\n";
	print "<script type=\"text/javascript\">\n";
	my $network=`perl $prgdir/rdf.pl -d $moiraidir export network`;
	chomp($network);
	my $db=`perl $prgdir/rdf.pl -d $moiraidir export db`;
	chomp($db);
	my $log=`perl $prgdir/rdf.pl -d $moiraidir export log`;
	chomp($log);
	print "var network=$network;\n";
	print "var db=$db;\n";
	print "var log=$log;\n";
    print "var nodes = new vis.DataSet(network[0]);\n";
    print "var edges = new vis.DataSet(network[1]);\n";
	print "\$(document).ready(function() {\n";
	print "	var container=\$(\"#network\")[0];\n";
    print "	var data={nodes:nodes,edges:edges,};\n";
    print "	var options={edges:{arrows:'to'}};\n";
    print "	var network=new vis.Network(container,data,options);\n";
	print "	network.on(\"click\",function(params){\n";
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
	print "\$('#dbs').columns({\n";
    print "data:db,\n";
	print "});\n";
	print "\$('#logs').columns({\n";
    print "data:log,\n";
    print "schema: [\n";
    print "{'header': 'execid', 'key': 'daemon/execid'},\n";
    print "{'header': 'execute', 'key': 'daemon/execute'},\n";
    print "{'header': 'timethrown', 'key': 'daemon/timethrown'},\n";
    print "{'header': 'timestarted', 'key': 'daemon/timestarted'},\n";
    print "{'header': 'timeended', 'key': 'daemon/timeended'},\n";
    print "{'header': 'command', 'key': 'daemon/command','template':'<a href=\"{{daemon/command}}\">{{daemon/command}}</a>'}\n";
  	print "]\n";
	print "});\n";
	print "});\n";
	print "</script>\n";
	print "<link rel=\"stylesheet\" href=\"css/classic.css\">\n";
	print "<style type=\"text/css\">\n";
    print "#network {\n";
    print "width: 600px;\n";
    print "height: 400px;\n";
    print "border: 1px solid lightgray;\n";
    print "}\n";
	print "</style>\n";
	print "</head>\n";
	print "<body>\n";
	print "<h1>$basename</h1>\n";
	print "updated: ".getDate("/")." ".getTime(":")."\n";
	print "<hr>\n";
    print "<div id=\"network\"></div>\n";
    print "<div id=\"dbs\"></div>\n";
    print "<div id=\"logs\"></div>\n";
	print "</body>\n";
	print "</html>\n";
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
############################## assign ##############################
sub assign{
	if(!defined($opt_o)){
		print STDERR "Please use option 'o' to assign triple\n";
		exit(1);
	}
	checkInputOutput($opt_o);
	my $insertKeys=handleKeys($opt_o);
	my @lines=();
	foreach my $insert(@{$insertKeys}){
		my @results=selectRDF($insert->[0],$insert->[1],"%");
		if(scalar(@results)>0){next;}
		push(@lines,join("\t",@{$insert}));
	}
	if(scalar(@lines)>0){
		my ($writer,$temp)=tempfile(UNLINK=>1);
		foreach my $line(@lines){print $writer "$line\n";}
		close($writer);
		system("perl $prgdir/rdf.pl -d $moiraidir import < $temp");
	}
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
	my $logdir=defined($opt_o)?$opt_o:"daemon";
	my $databases={};
	my $stderrs={};
	my $stdouts={};
	my $logs={};
	my $directory=defined($opt_d)?$opt_d:".";
	while(1){
		foreach my $file(listMoirais(@directories)){if(!exists($databases->{$file})){$databases->{$file}=0;}}
		while(my($database,$timestamp)=each(%{$databases})){
			my $dirname=dirname($database);
			my $basename=basename($database);
			my @stats=stat($database);
			my $modtime=$stats[9];
			if($timestamp==0){$databases->{$database}=$modtime;$timestamp=$modtime;}
			if(-e "$logdir/$basename.lock" && -e "$logdir/$basename.unlock"){
				unlink("$logdir/$basename.lock");
				unlink("$logdir/$basename.unlock");
				$databases->{$database}=$modtime;
				next;
			}
			if(-e "$logdir/$basename.lock"){next;}
			if(checkCtrlDirectory("$dirname/$basename")){}
			elsif($modtime>$timestamp){}
			else{next;}
			if(!(-e "$logdir/$basename")){mkdirs("$logdir/$basename");}
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
			print OUT "touch $logdir/$basename.lock\n";
			print OUT "$command\n";
			print OUT "touch $logdir/$basename.unlock\n";
			print OUT "rm $shell\n";
			close(OUT);
			$command="bash $shell &";
			system($command);
			$databases->{$database}=$modtime;
		}
		sleep($sleeptime);
	}
}
############################## checkCtrlDirectory ##############################
sub checkCtrlDirectory{
	my $directory=shift();
	my @files=listFiles("txt","$directory/ctrl/submit");
	if(scalar(@files)>0){return 1;}
	@files=listFiles("txt","$directory/ctrl/insert");
	if(scalar(@files)>0){return 1;}
	return;
}
############################## ls ##############################
sub ls{
	my @directories=@_;
	if(scalar(@directories)==0){push(@directories,".");}
	my @files;
	if(defined($opt_i)){
	}else{
		@files=listFilesRecursively($opt_g,$opt_G,$opt_r,@directories);
	}
	if(!defined($opt_o)){$opt_o="\$path";}
	my @lines=();
	foreach my $file(@files){
		my $line=$opt_o;
		my $hash=basenames($file);
		$hash=fileStats($file,$line,$hash);
		$line=~s/\\t/\t/g;
		$line=~s/\-\>/\t/g;
		$line=~s/\\n/\n/g;
		while(my($key,$val)=each(%{$hash})){
			$line=~s/\$\{$key\}/$val/g;
			$line=~s/\$$key/$val/g;
		}
		push(@lines,$line);
	}
	if(defined($opt_l)){
		foreach my $line(@lines){print "$line\n";}
		return;
	}
	my ($writer,$temp)=tempfile(UNLINK=>1);
	foreach my $line(@lines){print $writer "$line\n";}
	close($writer);
	system("perl $prgdir/rdf.pl -d $moiraidir import < $temp");
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
	my $execid=$vars->{"execid"};
	my $url=$command->{$urls->{"daemon/command"}};
	my $workdir="$rootdir/".$vars->{"workdir"};
	my $tmpdir="$rootdir/".$vars->{"tmpdir"};
	my $bashfile="$workdir/".$vars->{"bashfile"};
	my $stderrfile="$workdir/".$vars->{"stderrfile"};
	my $stdoutfile="$workdir/".$vars->{"stdoutfile"};
	my $insertfile="$workdir/".$vars->{"insertfile"};
	my $logfile="$workdir/".$vars->{"logfile"};
	my $completedfile="$workdir/".$vars->{"completedfile"};
	if(defined($opt_c)){$vars->{"rootdir"}="/root";}
	open(OUT,">$bashfile");
	print OUT "#!/bin/sh\n";
	print OUT "########## system ##########\n";
	my @systemvars=("cmdurl","execid","rootdir","ctrldir","workdir","tmpdir");
	my @unusedvars=("bashfile");
	my @systemfiles=("completedfile","insertfile","logfile","stdoutfile","stderrfile");
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
	print OUT "mkdir -p /tmp/\$execid\n";
	print OUT "ln -s /tmp/\$execid \$rootdir/\$workdir/tmp\n";
	print OUT "########## initialize ##########\n";
	print OUT "echo \"\$execid\t".$urls->{"daemon/timestarted"}."\t`date +%s`\">>\$workdir/\$logfile\n";
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
	if(exists($command->{$urls->{"daemon/error/file/empty"}})){
		my $hash=$command->{$urls->{"daemon/error/file/empty"}};
		my $index=0;
		foreach my $input(@{$command->{"input"}}){
			if(!exists($hash->{$input})){next;}
			if($index==0){print OUT "########## check input ##########\n";}
			print OUT "if [[ \"\$(declare -p $input)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for in in \${$input"."[\@]} ; do\n";
			print OUT "if [ ! -s \$in ]; then\n";
			print OUT "echo 'Empty input: \$in'>>\$workdir/\$stderrfile\n";
			print OUT "fi\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "if [ ! -s \$$input ]; then\n";
			print OUT "echo \"Empty input: \$$input\">>\$workdir/\$stderrfile\n";
			print OUT "fi\n";
			print OUT "fi\n";
			$index++;
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
	print OUT "echo \"\$execid\t".$urls->{"daemon/timeended"}."\t`date +%s`\">>\$workdir/\$logfile\n";
	foreach my $output(@{$command->{"output"}}){
		print OUT "if [[ \"\$(declare -p $output)\" =~ \"declare -a\" ]]; then\n";
		print OUT "for out in \${$output"."[\@]} ; do\n";
		print OUT "echo \"\$execid\t\$cmdurl#$output\t\$out\">>\$workdir/\$logfile\n";
		if(exists($inserts->{$output})){
			foreach my $row(@{$inserts->{$output}}){
				my $line=join("\t",@{$row});
				$line=~s/\$$output/\$out/g;
				print OUT "echo \"$line\">>\$workdir/\$insertfile\n";
			}
		}
		print OUT "done\n";
		print OUT "else\n";
		print OUT "echo \"\$execid\t\$cmdurl#$output\t\$$output\">>\$workdir/\$logfile\n";
		if(exists($inserts->{$output})){
			foreach my $row(@{$inserts->{$output}}){print OUT "echo \"".join("\t",@{$row})."\">>\$workdir/\$insertfile\n";}
		}
		print OUT "fi\n";
	}
	if(exists($inserts->{""})){foreach my $row(@{$inserts->{""}}){print OUT "echo \"".join("\t",@{$row})."\">>\$workdir/\$insertfile\n";}}
	if(scalar(@unzips)>0){
		print OUT "########## cleanup ##########\n";
		foreach my $unzip(@unzips){print OUT "rm $unzip\n";}
	}
	print OUT "########## close tmpdir ##########\n";
	print OUT "rm \$workdir/tmp\n";
	print OUT "if [ -z \"\$(ls -A /tmp/\$execid)\" ]; then\n";
  	print OUT "rmdir /tmp/\$execid\n";
	print OUT "else\n";
	print OUT "mv /tmp/\$execid \$workdir/tmp\n";
	print OUT "fi\n";
	if(exists($command->{$urls->{"daemon/error/file/empty"}})){
		my $index=0;
		my $hash=$command->{$urls->{"daemon/error/file/empty"}};
		foreach my $output(@{$command->{"output"}}){
			if(!exists($hash->{$output})){next;}
			if($index==0){print OUT "########## check output ##########\n";}
			print OUT "if [[ \"\$(declare -p $output)\" =~ \"declare -a\" ]]; then\n";
			print OUT "for out in \${$output"."[\@]} ; do\n";
			print OUT "if [ ! -s \$out ]; then\n";
			print OUT "echo 'Empty output: \$out'>>\$workdir/\$stderrfile\n";
			print OUT "fi\n";
			print OUT "done\n";
			print OUT "else\n";
			print OUT "if [ ! -s \$$output ]; then\n";
			print OUT "echo \"Empty output: \$$output\">>\$workdir/\$stderrfile\n";
			print OUT "fi\n";
			print OUT "fi\n";
			$index++;
		}
	}
	if(exists($command->{$urls->{"daemon/error/stdout/ignore"}})){
		print OUT "########## check stdout ##########\n";
		my $lines=$command->{$urls->{"daemon/error/stdout/ignore"}};
		foreach my $line(@{$lines}){
			print OUT "if [ \"\$(grep '$line' \$workdir/\$stdoutfile)\" != \"\" ]; then\n";
			print OUT "rm \$workdir/\$stdoutfile\n";
			print OUT "fi\n";
		}
	}
	if(exists($command->{$urls->{"daemon/error/stderr/ignore"}})){
		print OUT "########## check stderr ##########\n";
		my $lines=$command->{$urls->{"daemon/error/stderr/ignore"}};
		foreach my $line(@{$lines}){
			print OUT "if [ \"\$(grep '$line' \$workdir/\$stderrfile)\" != \"\" ]; then\n";
			print OUT "rm \$workdir/\$stderrfile\n";
			print OUT "fi\n";
		}
	}
	print OUT "########## completed ##########\n";
	my $importcount=0;
	my $nodename=$execid;
	$nodename=~s/[^A-za-z0-9]/_/g;
	for(my $i=0;$i<scalar(@{$command->{$urls->{"daemon/import"}}});$i++){
		my $importfile=$command->{$urls->{"daemon/import"}}->[$i];
		if(exists($command->{$urls->{"daemon/import/tag"}})){
			my $tag=$command->{$urls->{"daemon/import/tag"}};
			print OUT "perl -pe 'my \@token=split(/\\t/);\$_=\"\$token[0]\\t$tag/\$token[1]\\t\$token[2]\\n\"' < $importfile > \$ctrldir/insert/$nodename.$i.import\n";
			print OUT "rm $importfile\n";
		}else{
			print OUT "mv $importfile \$ctrldir/insert/$nodename.$i.import\n";
		}
		$importcount++;
	}
	print OUT "mv \$workdir/\$completedfile \$ctrldir/completed/.\n";
	close(OUT);
	writeCompleteFile($completedfile,$stdoutfile,$stderrfile,$insertfile,$logfile,$bashfile,\@scriptfiles,$ctrldir,$workdir,$tmpdir,$execid);
	if(exists($vars->{"bashfile"})){
		if(defined($opt_c)){push(@{$bashFiles},[$vars->{"rootdir"}."/".$vars->{"workdir"}."/".$vars->{"bashfile"},$stdoutfile,$stderrfile,$execid]);}
		else{push(@{$bashFiles},[$bashfile,$stdoutfile,$stderrfile,$execid]);}
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
	else{my $count=`cat $path|wc -l`;if($count=~/(\d+)/){$count=$1;};return $count;}
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
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my @results=`perl $prgdir/rdf.pl -d $moiraidir select '$subject' '$predicate' '$object'`;
	foreach my $result(@results){
		chomp($result);
		my @tokens=split(/\t/,$result);
		$result=\@tokens;
	}
	return @results;
}
############################## commandProcess ##############################
sub commandProcess{
	my @arguments=@_;
	my $url=shift(@arguments);
	my $commands=shift(@arguments);
	my $queryResults=shift(@arguments);
	my $userdefined=shift(@arguments);
	my $queryKeys=shift(@arguments);
	my $insertKeys=shift(@arguments);
	my $cmdLine=shift(@arguments);
	my $command=loadCommandFromURL($url,$commands);
	$commands->{$url}=$command;
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	if(defined($insertKeys)){push(@{$command->{"insertKeys"}},@{$insertKeys});}
	if(defined($queryKeys)){push(@{$command->{"queryKeys"}},@{$queryKeys});}
	if(defined($opt_t)){$command->{$urls->{"daemon/import/tag"}}=$opt_t;}
	if(defined($opt_l)){
		my $line="#Command: ".basename($command->{$urls->{"daemon/command"}});
		if(scalar(@inputs)>0){$line.=" \$".join(" \$",@inputs);}
		if(scalar(@outputs)>0){$line.=" \$".join(" \$",@outputs);}
		print STDERR "$line\n";
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
	my @execids=();
	my $keys;
	foreach my $hash(@{$queryResults->{".hashs"}}){
		my $vars=commandProcessVars($hash,$userdefined,$insertKeys,\@inputs,\@outputs);
		if(!defined($keys)){my @temp=sort{$a cmp $b}keys(%{$vars});$keys=\@temp;}
		my $execid=commandProcessSub($url,$vars,$cmdLine,\@inputs,\@outputs);
		push(@execids,$execid);
	}
	if(defined($opt_l)){
		print STDERR "Proceed running ".scalar(@execids)." jobs [y/n]? ";
		my $prompt=<STDIN>;
		chomp($prompt);
		if($prompt ne "y"&&$prompt ne "yes"&&$prompt ne "Y"&&$prompt ne "YES"){exit(1);}
	}
	return @execids;
}
############################## commandProcessSub ##############################
sub commandProcessSub{
	my $url=shift();
	my $vars=shift();
	my $cmdLine=shift();
	my $inputs=shift();
	my $outputs=shift();
	my @inserts=();
	my $id="e".getDatetime();
	my $dirname=substr($id,1,8);
	my $file="$logdir/$dirname/$id.txt";
	while(existsLogFile($file)){
		sleep(1);
		$id="e".getDatetime();
		$file="$logdir/$dirname/$id.txt";
	}
	my ($writer,$tempfile)=tempfile();
	if(-e $file){
		my $reader=openFile($file);
		while(<$reader>){chomp;print $writer "$_\n";}
		close($reader);
	}else{mkdirs(dirname($file));}
	print $writer $urls->{"daemon/execute"}."\tregistered\n";
	print $writer $urls->{"daemon/command"}."\t$url\n";
	if(defined($cmdLine)){print $writer $urls->{"daemon/command/line"}."\t$cmdLine\n";}
	foreach my $key(keys(%{$vars})){print $writer "$url#$key\t".$vars->{$key}."\n";}
	close($writer);
	my ($writer2,$tempfile2)=tempfile();
	close($writer2);
	system("sort $tempfile -u > $tempfile2");
	system("mv $tempfile2 $file");
	return $id;
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
############################## getDatetime ##############################
sub getDatetime{my $time=shift;return getDate("",$time).getTime("",$time);}
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
############################## controlLog ##############################
sub controlLog{
	my @files=getFiles("$ctrldir/log");
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $prgdir/rdf.pl -d $moiraidir -f tsv log";
	my $count=`$command`;
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlError ##############################
sub controlError{
	my @files=getFiles("$ctrldir/error");
	foreach my $file(@files){
		my $basename=basename($file,".error");
		my $command="perl $prgdir/rdf.pl -d $moiraidir appendlog $basename<$file";
		system($command);
		unlink($file);
	}
}
############################## controlInsert ##############################
sub controlInsert{
	my @files=getFiles("$ctrldir/insert");
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $prgdir/rdf.pl -d $moiraidir -f tsv insert";
	my $count=`$command`;
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlProcess ##############################
sub controlProcess{
	my $executes=shift();
	my $completed=controlCompleted();
	my $inserted=controlInsert();
	my $logged=controlLog();
	controlError();
	$inserted+=controlSubmit();
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
	if($logged>1){print "$date $time Logged $logged triples.\n";}
	elsif($logged>0){print "$date $time Logged $logged triple.\n";}
}
############################## controlSubmit ##############################
sub controlSubmit{
	my @files=getFiles("$ctrldir/submit");
	if(scalar(@files)==0){return 0;}
	my $total=0;
	foreach my $file(@files){
		my $command="perl $prgdir/rdf.pl -d $moiraidir -f tsv submit<$file";
		$total+=`$command`;
		unlink($file);
	}
	return $total;
}
############################## createJson ##############################
sub createJson{
	my @commands=@_;
	my $dir=shift(@commands);
	my $inputs=shift(@commands);
	my $outputs=shift(@commands);
	my ($writer,$file)=tempfile(DIR=>$dir,SUFFIX=>".json");
	print $writer "{";
	print $writer "\"".$urls->{"daemon/bash"}."\":[\"".join("\",\"",@commands)."\"]";
	if(scalar(@{$inputs})>0){print $writer ",\"".$urls->{"daemon/input"}."\":[\"".join("\",\"",@{$inputs})."\"]";}
	if(scalar(@{$outputs})>0){print $writer ",\"".$urls->{"daemon/output"}."\":[\"".join("\",\"",@{$outputs})."\"]";}
	print $writer "}";
	close($writer);
	if($file=~/^\.\/(.+)$/){$file=$1;}
	my $md5cmd=(`which md5`)?"md5":"md5sum";
	my $md5=`$md5cmd<$file`;chomp($md5);
	my $json;
	foreach my $tmp(listFiles("json",$jsondir)){
		my $m=`$md5cmd<$tmp`;chomp($m);
		if($m eq $md5){$json=$tmp;}
	}
	if(defined($json)){unlink($file);}
	else{
		$json="$jsondir/j".getDatetime().".json";
		while(-e $json){sleep(1);$json="$jsondir/j".getDatetime().".json";}
		system("mv $file $json");
	}
	return $json;
}
############################## existsArray ##############################
sub existsArray{
	my $array=shift();
	my $needle=shift();
	foreach my $value(@{$array}){if($needle eq $value){return 1;}}
	return 0;
}
############################## existsLogFile ##############################
sub existsLogFile{
	my $file=shift();
	if(-e $file){return 1;}
	if(-e "$file.gz"){return 1;}
	if(-e "$file.bz2"){return 1;}
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
############################## getExecuteJobs ##############################
sub getExecuteJobs{
	my $dbdir=shift();
	my $command=shift();
	my $executes=shift();
	my $url=$command->{$urls->{"daemon/command"}};
	my $execids={};
	foreach my $execute(@{$executes->{$url}}){$execids->{$execute->{"execid"}}=1;}
	my $command="perl $prgdir/rdf.pl -d $moiraidir -f json executes $url ".join(" ",keys(%{$execids}));
	my $vars=jsonDecode(`$command`);
	foreach my $key(keys(%{$vars})){$vars->{$key}->{"execid"}=$key;}
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
			if(defined($opt_q)){$line=~s/\s+\-q//;}
			if(defined($opt_c)){$line=~s/\s+\-c\s+\S+//;}
			if(defined($opt_d)){$line=~s/\s+\-d\s+\S+//;}
			$line=~s/moirai2\.pl/moirai2.pl -d $moiraidir/;
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
	my $dbdir=shift();
	my $userdefined=shift();
	my $input=shift();
	my $hash={};
	my ($query,$keys)=parseQuery(replaceStringWithHash($userdefined,$input));
	my @keys=();
	my @queries=split(/,/,$input);
	foreach my $query(@queries){
		my @tokens=split(/\-\>/,$query);
		foreach my $token(@tokens){if($token=~/^\$(.+)$/){push(@keys,$1);}}
	}
	my $command="perl $prgdir/rdf.pl -d $moiraidir -f json query '".join("','",@queries)."'";
	my $result=`$command`;chomp($result);
	my $hashs=jsonDecode($result);
	$hash->{".keys"}=$keys;
	$hash->{".hashs"}=$hashs;
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
	my $dbdir=shift();
	my $command=shift();
	my $vars=shift();
	if(!defined($vars)){$vars={};}
	my $url=$command->{$urls->{"daemon/command"}};
	my $execid=$vars->{"execid"};
	$vars->{"rootdir"}=$rootdir;
	$vars->{"ctrldir"}=$ctrldir;
	$vars->{"cmdurl"}=$url;
	my $workdir="$moiraidir/$execid";
	mkdir($workdir);
	chmod(0777,$workdir);
	$vars->{"workdir"}=$workdir;
	$vars->{"tmpdir"}="$workdir/tmp";
	$vars->{"bashfile"}="$execid.sh";
	$vars->{"stderrfile"}="$execid.stderr";
	$vars->{"stdoutfile"}="$execid.stdout";
	$vars->{"insertfile"}="$execid.insert";
	$vars->{"logfile"}="$execid.log";
	$vars->{"completedfile"}="$execid.completed";
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
############################## listMoirais ##############################
sub listMoirais{
	my @input_directories=@_;
	my @input_files=();
	foreach my $input_directory(@input_directories){
		$input_directory=absolutePath($input_directory);
		if(-f $input_directory){push(@input_files,$input_directory);next;}
		elsif(-l $input_directory){push(@input_files,$input_directory);next;}
		opendir(DIR,$input_directory);
		foreach my $file(readdir(DIR)){	
			if($file eq "."){next;}
			if($file eq "..") {next;}
			if($file eq ""){next;}
			if(-d "$input_directory/$file"){
				if(-d "$input_directory/$file/ctrl"){push(@input_files,$file);}
			}
		}
		closedir(DIR);
	}
	return sort{$a cmp $b}@input_files;
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
	if(exists($command->{$urls->{"daemon/bash"}})){$command->{"bashCode"}=handleCode($command->{$urls->{"daemon/bash"}});}
	if(!exists($command->{$urls->{"daemon/maxjob"}})){$command->{$urls->{"daemon/maxjob"}}=1;}
	if(exists($command->{$urls->{"daemon/script"}})){handleScript($command);}
	if(exists($command->{$urls->{"daemon/error/file/empty"}})){$command->{$urls->{"daemon/error/file/empty"}}=handleHash(@{handleArray($command->{$urls->{"daemon/error/file/empty"}})});}
	if(exists($command->{$urls->{"daemon/error/stderr/ignore"}})){$command->{$urls->{"daemon/error/stderr/ignore"}}=handleArray($command->{$urls->{"daemon/error/stderr/ignore"}});}
	if(exists($command->{$urls->{"daemon/error/stdout/ignore"}})){$command->{$urls->{"daemon/error/stdout/ignore"}}=handleArray($command->{$urls->{"daemon/error/stdout/ignore"}});}
	if(scalar(keys(%{$default}))>0){$command->{"default"}=$default;}
}
############################## lookForNewCommands ##############################
sub lookForNewCommands{
	my $dbdir=shift();
	my $commands=shift();
	my $result=`perl $prgdir/rdf.pl -d $moiraidir commands`;
	chomp($result);
	my @urls=split(" ",$result);
	foreach my $url(@urls){loadCommandFromURL($url,$commands);}
	return @urls;
}
############################## mainProcess ##############################
sub mainProcess{
	my $execurls=shift();
	my $commands=shift();
	my $executes=shift();
	my $available=shift();
	my $thrown=0;
	for(my $i=0;($i<$available)&&(scalar(@{$execurls})>0);$i++){
		my @logs=();
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
				initExecute($dbdir,$command,$vars);
				push(@logs,$vars->{"execid"}."\t".$urls->{"daemon/execute"}."\tthrown");
				my $datetime=`date +%s`;chomp($datetime);
				push(@logs,$vars->{"execid"}."\t".$urls->{"daemon/timethrown"}."\t$datetime");
				bashCommand($command,$vars,$bashFiles);
				$maxjob--;
				$thrown++;
			}
		}
		if(scalar(@logs)>0){
			my ($fh,$file)=mkstemps("$ctrldir/log/XXXXXXXXXX",".log");
			foreach my $log(@logs){print $fh "$log\n";}
			close($fh);
			controlLog();
		}
		throwJobs($bashFiles,$opt_q,$qsubopt,$url,$rootdir,$opt_c,$command->{$urls->{"daemon/docker"}});
		if(scalar(@{$executes->{$url}})>0){push(@{$execurls},$url);}
	}
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
	foreach my $var(@varnames){if($var ne "execid"){push(@inputs,$var);}}
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
		my @results=selectRDF($subject,$predicate,$object);
		$results->{$predicate}=\@results;
	}
	my @array=();
	foreach my $hash(@{$queryResults->{".hashs"}}){
		my $hit=0;
		foreach my $out(@{$insertKeys}){
			my $pred=$out->[1];
			my @array=@{$results->{$pred}};
			if($out->[0]=~/^\$(.+)$/){
				my $sub=$1;
				if($out->[2]=~/^\$(.+)$/){ # ?->P->?
					my $obj=$1;
					my $hitS=checkArray($sub,0,\@array,$hash);
					my $hitO=checkArray($obj,2,\@array,$hash);
					if($hitS&&$hitO){$hit=1;}
				}else{ # ?->P->O
					my $obj=$out->[2];
					my $hitS=checkArray($sub,0,\@array,$hash);
					my $hitO=checkArray($obj,2,\@array);
					if($hitS&&$hitO){$hit=1;}
				}
			}else{
				my $sub=$out->[0];
				if($out->[2]=~/^\$(.+)$/){# S->P->?
					my $obj=$1;
					my $hitS=checkArray($sub,0,\@array);
					my $hitO=checkArray($sub,2,\@array,$hash);
					if($hitS&&$hitO){$hit=1;}
				}else{# S->P->O
					my $obj=$out->[2];
					my $hitS=checkArray($sub,0,\@array);
					my $hitO=checkArray($obj,2,\@array);
					if($hitS&&$hitO){$hit=1;}
				}
			}
		}
		if($hit==0){push(@array,$hash);}
	}
	$queryResults->{".hashs"}=\@array;
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
############################## extract ##############################
sub extract{
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
	unlink("test/moirai");
	open(OUT,">test/A.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/input\":\"\$string\",\"https://moirai2.github.io/schema/daemon/bash\":[\"output=\\\"\$workdir/output.txt\\\"\",\"echo \\\"\$string\\\" > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}\n";
	close(OUT);
	open(OUT,">test/B.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/input\":\"\$input\",\"https://moirai2.github.io/schema/daemon/bash\":[\"output=\\\"\$workdir/output.txt\\\"\",\"sort \$input > \$output\"],\"https://moirai2.github.io/schema/daemon/output\":\"\$output\"}\n";
	close(OUT);
	testCommand("perl moirai2.pl -d test/moirai -s 1 -r '\$output' test/A.json 'Akira Hasegawa' test/output.txt","test/output.txt");
	testCommand("cat test/output.txt","Akira Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test/moirai insert case1 '#string' 'Akira Hasegawa'","inserted 1");
	testCommand("perl moirai2.pl -d test/moirai -s 1 -i '\$id->#string->\$string' -o '\$id->#text->\$output' test/A.json '\$string' 'test/\$id.txt'","");
	testCommand("cat test/case1.txt","Akira Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test/moirai select case1 '#text'","case1\t#text\ttest/case1.txt");
	testCommand("perl moirai2.pl -d test/moirai -s 1 -i '\$id->#text->\$input' -o '\$input->#sorted->\$output' test/B.json 'output=test/\$id.sort.txt'","");
	testCommand("cat test/case1.sort.txt","Akira Hasegawa");
	testCommand("perl $prgdir/rdf.pl -d test/moirai select % '#sorted'","test/case1.txt\t#sorted\ttest/case1.sort.txt");
	open(OUT,">test/case2.txt");print OUT "Hasegawa\nAkira\nChiyo\nHasegawa\n";close(OUT);
	testCommand("perl $prgdir/rdf.pl -d test/moirai insert case2 '#text' test/case2.txt","inserted 1");
	testCommand("perl moirai2.pl -d test/moirai -s 1 -i '\$id->#text->\$input' -o '\$input->#sorted->\$output' test/B.json 'output=test/\$id.sort.txt'","");
	testCommand("cat test/case2.sort.txt","Akira\nChiyo\nHasegawa\nHasegawa");
	unlink("test/output.txt");
	unlink("test/case1.txt");
	unlink("test/case2.txt");
	unlink("test/case1.sort.txt");
	unlink("test/case2.sort.txt");
	unlink("test/A.json");
	unlink("test/B.json");
	open(OUT,">test/C.json");
	print OUT "{\"https://moirai2.github.io/schema/daemon/docker\":\"ubuntu\",\"https://moirai2.github.io/schema/daemon/bash\":\"unamea=\$(uname -a)\",\"https://moirai2.github.io/schema/daemon/output\":\"\$unamea\"}\n";
	close(OUT);
	my $name=`uname -s`;chomp($name);
	testCommand2("perl moirai2.pl -d test/moirai -r unamea test/C.json","^$name");
	testCommand2("perl moirai2.pl -q -d test/moirai -r unamea test/C.json","^$name");
	testCommand2("perl moirai2.pl -d test/moirai -r unamea -c docker test/C.json","^Linux");
	testCommand2("perl moirai2.pl -q -d test/moirai -r unamea -c docker test/C.json","^Linux");
	unlink("test/C.json");
	open(OUT,">test/moirai/ctrl/insert/A.txt");
	print OUT "A\t#name\tAkira\n";
	close(OUT);
	system("echo 'mkdir -p test/moirai/\$dirname'|perl moirai2.pl -d test/moirai -i '\$id->#name->\$dirname' -o '\$id->#mkdir->done' command");
	if(!-e "test/moirai/Akira"){print STDERR "test/moirai/Akira directory not created";}
	open(OUT,">test/moirai/ctrl/insert/B.txt");
	print OUT "B\t#name\tBen\n";
	close(OUT);
	system("echo 'mkdir -p test/moirai/\$dirname'|perl moirai2.pl -d test/moirai -i '\$id->#name->\$dirname' -o '\$id->#mkdir->done' command");
	if(!-e "test/moirai/Ben"){print STDERR "test/moirai/Ben directory not created";}
	system("rm -r test/moirai");
	system("rm -r test");
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
		my ($bashFile,$stdoutFile,$stderrFile,$execid)=@{$files};
		if($execid=~/(.+)#(.+)/){push(@ids,"#$2");}
		else{push(@ids,$execid);}
		if($use_container eq "docker"){
			if(!defined($docker_image)){$docker_image="ubuntu";}
			print $fh "docker \\\n";
			print $fh "  run \\\n";
			print $fh "  --rm \\\n";
			print $fh "  --workdir=/root \\\n";
			print $fh "  -v '$rootdir:/root' \\\n";
			print $fh "  $docker_image \\\n";
			print $fh "  /bin/bash $bashFile \\\n";
			print $fh "  > $stdoutFile \\\n";
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
	if($use_qsub){
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
		my $command="bash $path &";
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
	my $logfile=shift();
	my $bashfile=shift();
	my $scriptfiles=shift();
	my $ctrldir=shift();
	my $workdir=shift();
	my $tmpdir=shift();
	my $execid=shift();
	open(OUT,">$completedfile");
	print OUT "errorfile=\$(mktemp)\n";
	
	print OUT "if [ -s $stdoutfile ];then\n";
	print OUT "echo '======================================== stdout ========================================'>>\$errorfile\n";
	print OUT "cat $stdoutfile>>\$errorfile\n";
	print OUT "fi\n";
	print OUT "rm $stdoutfile\n";
	
	print OUT "if [ -s $stderrfile ];then\n";
	print OUT "echo '======================================== stderr ========================================'>>\$errorfile\n";
	print OUT "cat $stderrfile>>\$errorfile\n";
	print OUT "fi\n";
	print OUT "rm $stderrfile\n";

	print OUT "if [ -s $insertfile ];then\n";
	print OUT "mv $insertfile $ctrldir/insert/.\n";
	print OUT "fi\n";
	
	print OUT "if [ -s \$errorfile ];then\n";
	print OUT "echo \"$execid\t".$urls->{"daemon/execute"}."\terror\">>$logfile\n";
	print OUT "else\n";
	print OUT "echo \"$execid\t".$urls->{"daemon/execute"}."\tcompleted\">>$logfile\n";
	print OUT "fi\n";
	print OUT "mv $logfile $ctrldir/log/.\n";

	print OUT "if [ -s \$errorfile ];then\n";
	print OUT "echo '======================================== bash ========================================'>>\$errorfile\n";
	print OUT "cat $bashfile>>\$errorfile\n";
	foreach my $scriptfile(@{$scriptfiles}){
		print OUT "echo '======================================== $scriptfile ========================================'>>\$errorfile\n";
		print OUT "cat $scriptfile>>\$errorfile\n";
	}
	print OUT "mv \$errorfile $ctrldir/error/$execid.error\n";
	print OUT "fi\n";
	
	print OUT "rm -f $bashfile\n";
	foreach my $scriptfile(@{$scriptfiles}){print OUT "rm -f $scriptfile\n";}
	print OUT "rmdir $tmpdir > /dev/null 2>&1\n";
	print OUT "rmdir $workdir/ > /dev/null 2>&1\n";
	close(OUT);
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
