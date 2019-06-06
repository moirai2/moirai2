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
my ($program_name,$program_directory,$program_suffix)=fileparse($0);
$program_directory=substr($program_directory,0,-1);
my $program_path=Cwd::abs_path($program_directory)."/$program_name";
# require "$program_directory/Utility.pl";
############################## OPTIONS ##############################
use vars qw($opt_c $opt_d $opt_h $opt_H $opt_i $opt_l $opt_m $opt_o $opt_q $opt_Q $opt_r $opt_s);
getopts('c:d:hHi:lm:qo:Q:r:s:');
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
$urls->{"daemon/outputs"}="https://moirai2.github.io/schema/daemon/outputs";
$urls->{"daemon/return"}="https://moirai2.github.io/schema/daemon/return";
$urls->{"daemon/bash"}="https://moirai2.github.io/schema/daemon/bash";
$urls->{"daemon/script"}="https://moirai2.github.io/schema/daemon/script";
$urls->{"daemon/script/code"}="https://moirai2.github.io/schema/daemon/script/code";
$urls->{"daemon/script/name"}="https://moirai2.github.io/schema/daemon/script/name";
$urls->{"daemon/maxjob"}="https://moirai2.github.io/schema/daemon/maxjob";
$urls->{"daemon/singlethread"}="https://moirai2.github.io/schema/daemon/singlethread";
$urls->{"daemon/qsubopt"}="https://moirai2.github.io/schema/daemon/qsubopt";
$urls->{"daemon/command"}="https://moirai2.github.io/schema/daemon/command";
$urls->{"daemon/workflow"}="https://moirai2.github.io/schema/daemon/workflow";
$urls->{"daemon/execute"}="https://moirai2.github.io/schema/daemon/execute";
$urls->{"daemon/stderr"}="https://moirai2.github.io/schema/daemon/stderr";
$urls->{"daemon/stdout"}="https://moirai2.github.io/schema/daemon/stdout";
$urls->{"daemon/timeended"}="https://moirai2.github.io/schema/daemon/timeended";
$urls->{"daemon/timestarted"}="https://moirai2.github.io/schema/daemon/timestarted";
$urls->{"daemon/unzip"}="https://moirai2.github.io/schema/daemon/unzip";
$urls->{"daemon/md5"}="https://moirai2.github.io/schema/daemon/md5";
$urls->{"daemon/filesize"}="https://moirai2.github.io/schema/daemon/filesize";
$urls->{"daemon/linecount"}="https://moirai2.github.io/schema/daemon/linecount";
$urls->{"daemon/seqcount"}="https://moirai2.github.io/schema/daemon/seqcount";
$urls->{"daemon/required"}="https://moirai2.github.io/schema/daemon/required";

$urls->{"system"}="https://moirai2.github.io/schema/system";
$urls->{"system/download"}="https://moirai2.github.io/schema/system/download";
$urls->{"system/upload"}="https://moirai2.github.io/schema/system/upload";
$urls->{"system/path"}="https://moirai2.github.io/schema/system/path";

$urls->{"file"}="https://moirai2.github.io/schema/file";
$urls->{"file/md5"}="https://moirai2.github.io/schema/file/md5";
$urls->{"file/linecount"}="https://moirai2.github.io/schema/file/linecount";
$urls->{"file/seqcount"}="https://moirai2.github.io/schema/file/seqcount";
############################## HELP ##############################
my $commands={};
if(defined($opt_h)&&$ARGV[0]=~/\.json$/){printCommand($ARGV[0],$commands);exit(0);}
if(defined($opt_h)||defined($opt_H)||(scalar(@ARGV)==0&&!defined($opt_d ))){
	print "\n";
	print "Program: Executes MOIRAI2 command(s) using a local RDF SQLITE3 database.\n";
	print "Author: Akira Hasegawa (akira.hasegawa\@riken.jp)\n";
	print "\n";
	print "Usage: $program_name -d DB URL [INPUT/OUTPUT ..]\n";
	print "\n";
	print "             Executes a MOIRAI2 command with user specified arguments\n";
	print "         DB  SQLite3 database in RDF format (default='./rdf.sqlite3').\n";
	print "        URL  Command URL or path (command URLs from https://moirai2.github.io/).\n";
	print "      INPUT  inputs of a MOIRAI2 command (varies among commands).\n";
	print "     OUTPUT  outputs of a MOIRAI2 command (varies among commands).\n";
	print "\n";
	print "Usage: $program_name -d DB -s SEC\n";
	print "\n";
	print "             Check for Moirai2 commands every X seconds and execute.\n";
	print "         DB  SQLite3 database in RDF format (default='./rdf.sqlite3').\n";
	print "        SEC  Loop search every specified seconds (default='run only once').\n";
	print "\n";
	print "Options: -c  Path to control directory (default='./ctrl').\n";
	print "         -d  RDF sqlite3 database (default='rdf.sqlite3').\n";
	print "         -i  Input query (default='none').\n";
	print "         -l  Show STDERR and STDOUT logs (default='none').\n";
	print "         -m  Max number of jobs to throw (default='5').\n";
	print "         -o  Output query (default='none').\n";
	print "         -q  Use qsub for throwing jobs(default='bash').\n";
	print "         -Q  Export specified bin directory when throwing with qsub(default='\$HOME/bin').\n";
	print "         -r  Return value (default='none').\n";
	print "         -s  Loop second (default='no loop').\n";
	print "\n";
	print "Usage: $program_name daemon\n";
	print "\n";
	print "             Look for RDF databases and run once if filestamps are updated.\n";
	print "Options: -d  Directory to search for (default='.').\n";
	print "         -l  Log directory (default='./log').\n";
	print "         -r  Recursive search through a directory (default='0').\n";
	print "         -s  Loop second (default='10 sec').\n";
	print "\n";
	print " AUTHOR: Akira Hasegawa\n";
	print "\n";
	if(defined($opt_H)){
		print "Updates: 2019/05/23  opt_r was added for return specified value.\n";
		print "         2019/05/15  opt_o was added for post-insert and unused batch routine removed.\n";
		print "         2019/05/05  Set up 'output' for a command mode.\n";
		print "         2019/04/08  'inputs' to pass inputs as variable array.\n";
		print "         2019/04/04  Changed program name from 'daemon.pl' to 'moirai2.pl'.\n";
		print "         2019/04/03  Array output functionality and command line functionality added.\n";
		print "         2019/03/04  Stores run options in the SQLite database.\n";
		print "         2019/02/07  'rm','rmdir','import' functions were added to batch routine.\n";
		print "         2019/01/21  'mv' functionality added to move temporary files to designated locations.\n";
		print "         2019/01/18  'process' functionality added to execute command from a control json.\n";
		print "         2019/01/17  Subdivide RDF database, revised execute flag to have instance in between.\n";
		print "         2018/12/12  'singlethread' added for NCBI/BLAST query.\n";
		print "         2018/12/10  Remove unnecessary files when completed.\n";
		print "         2018/12/04  Added 'maxjob' and 'nolog' to speed up processed.\n";
		print "         2018/11/27  Separating loading, selection, and execution and added 'maxjob'.\n";
		print "         2018/11/19  Improving database updates by speed.\n";
		print "         2018/11/17  Making daemon faster by collecting individual database accesses.\n";
		print "         2018/11/16  Making updating/importing database faster by using improved rdf.pl.\n";
		print "         2018/11/09  Added import function where user udpate databse through specified file(s).\n";
		print "         2018/09/14  Changed to a ticket system.\n";
		print "         2018/02/06  Added qsub functionality.\n";
		print "         2018/02/01  Created to throw jobs registered in RDF SQLite3 database.\n";
		print "\n";
	}
	exit(0);
}
############################## MAIN ##############################
my $newExecuteQuery="select distinct n.data from edge as e1 inner join edge as e2 on e1.object=e2.subject inner join node as n on e2.object=n.id where e1.predicate=(select id from node where data=\"".$urls->{"daemon/execute"}."\") and e2.predicate=(select id from node where data=\"".$urls->{"daemon/command"}."\")";
my $executeQuery="select distinct s.data,p.data,o.data from edge as e1 inner join edge as e2 on e1.object=e2.subject inner join node as s on e2.subject=s.id inner join node as p on e2.predicate=p.id inner join node as o on e2.object=o.id where e1.predicate=(select id from node where data=\"".$urls->{"daemon/execute"}."\")";
my $cwd=Cwd::getcwd();
if(scalar(@ARGV)==1&&$ARGV[0] eq "daemon"){autodaemon();exit();}
my $rdfdb=$opt_d;
if(!defined($rdfdb)){
	if(scalar(@ARGV)>0){$rdfdb="rdf.sqlite3";}
	else{print STDERR "Please specify database by -d option.\n";exit(1);}
}
if($rdfdb!~/^\//){$rdfdb="$cwd/$rdfdb";}
my $sleeptime=defined($opt_s)?$opt_s:10;
my $use_qsub=$opt_q;
my $home=`echo \$HOME`;
chomp($home);
my $qsubbin=defined($opt_Q)?$opt_Q:"$home/bin";
$qsubbin.=":$cwd/miniconda3/bin";
my $showlog=$opt_l;
my $runmode=defined($opt_s)?0:1;
my $maxjob=defined($opt_m)?$opt_m:5;
my $ctrldir=Cwd::abs_path(defined($opt_c)?$opt_c:dirname($rdfdb)."/ctrl");
mkdir("tmp");
chmod(0777,"tmp");
mkdir("$ctrldir");
mkdir("$ctrldir/bash");
mkdir("$ctrldir/insert");
mkdir("$ctrldir/delete");
mkdir("$ctrldir/update");
mkdir("$ctrldir/completed");
mkdir("$ctrldir/stdout");
mkdir("$ctrldir/stderr");
my $workflows={};
my $executes={};
my $workflows={};
my @execurls=();
my $jobcount=0;
my $ctrlcount=0;
my $cmdurl;
my @nodeids;
my $returnvalue;
my $results={};
if(defined($opt_i)){
	my @temp=parseQuery($opt_i);
	my $dbh=openDB($rdfdb);
	my $keys=$temp[1];
	my $sth=$dbh->prepare($temp[0]);
	$sth->execute();
	my $rows=$sth->fetchall_arrayref();
	$dbh->disconnect;
	$results->{"rows"}=$rows;
	$results->{"keys"}=$keys;
	print_rows($keys,$rows);
}
if(scalar(@ARGV)>0){
	$cmdurl=shift(@ARGV);
	if($cmdurl=~/\/workflow\/.+json$/){
		my @lines=workflowProcess($cmdurl,$commands,$workflows);
		print_table(\@lines);
	}else{@nodeids=commandProcess($cmdurl,$commands,$results,@ARGV);}
	if(defined($opt_r)){$commands->{$cmdurl}->{$urls->{"daemon/return"}}=removeDollar($opt_r);}
}
if($showlog){
	print STDERR "# program path   : $program_path\n";
	print STDERR "# rdf database   : $rdfdb\n";
	print STDERR "# ctrl directory : $ctrldir\n";
	if($runmode){print STDERR "# run mode       : once\n";}
	else{print STDERR "# run mode       : normal\n";}
	print STDERR "# sleeptime      : $sleeptime sec\n";
	print STDERR "# max job        : $maxjob job".(($maxjob>1)?"s":"")."\n";
	if(defined($use_qsub)){
		print STDERR "# job submission : qsub\n";
		print STDERR "# qsub bin       : $qsubbin\n";
	}else{
		print STDERR "# job submission : bash\n";
	}
	if(defined($cmdurl)){print STDERR "# command URL    : $cmdurl\n";}
	foreach my $nodeid(@nodeids){if(defined($nodeid)){print STDERR "# command NodeID : $nodeid\n";}}
	print STDERR "year/mon/date\thr:min:sec\tworkflow\tnewjob\tremain\tinsert\tdelete\tupdate\tdone\n";
}
while(true){
	my $jobs_running=getNumberOfJobsRunning();
	controlAll($rdfdb,$executes,$ctrlcount,$jobcount);
	$jobcount=0;
	$ctrlcount=0;
	if($jobs_running<$maxjob){
		my @newurls=lookForNewCommands($rdfdb,$newExecuteQuery,$commands);
		foreach my $url(@newurls){
			my $job=getExecuteJobs($rdfdb,$commands->{$url},$executes);
			if($job>0){$jobcount+=$job;if(!existsArray(\@execurls,$url)){push(@execurls,$url);}}
		}
	}
	$jobs_running=getNumberOfJobsRunning();
	mainProcess(\@execurls,$commands,$executes,$maxjob-$jobs_running);
	$jobs_running=getNumberOfJobsRunning();
	if($runmode&&scalar(@execurls)==0&&$jobs_running==0){last;}
	else{sleep($sleeptime);}
}
if(defined($cmdurl)&&exists($commands->{$cmdurl}->{$urls->{"daemon/return"}})){
	my $returnvalue=$commands->{$cmdurl}->{$urls->{"daemon/return"}};
	foreach my $nodeid(sort{$a cmp $b}@nodeids){
		my $result=`perl $cwd/rdf.pl -d $rdfdb object $nodeid $cmdurl#$returnvalue`;
		chomp($result);
		print "$result\n";
	}
}
############################## printCommand ##############################
sub printCommand{
	my $url=shift();
	my $commands=shift();
	my $command=loadCommandFromURL($url,$commands);
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	print STDOUT "\n#URL    :".$command->{$urls->{"daemon/command"}}."\n";
	my $cmdline="#Command:".basename($command->{$urls->{"daemon/command"}});
	if(scalar(@inputs)>0){$cmdline.=" [".join("] [",@inputs)."]";}
	if(scalar(@outputs)>0){$cmdline.=" [".join("] [",@outputs)."]";}
	print STDOUT "$cmdline\n";
	if(scalar(@inputs)>0){print STDOUT "#Input  :".join(" ",@{$command->{"input"}})."\n";}
	if(scalar(@outputs)>0){print STDOUT "#Output :".join(" ",@{$command->{"output"}})."\n";}
	print STDOUT "#Bash   :";
	my $index=0;
	foreach my $line(@{$command->{$urls->{"daemon/bash"}}}){if($index++>0){print STDOUT "        :"}print STDOUT "$line\n";}
	if($command->{$urls->{"daemon/maxjob"}}>1){print STDOUT "#Maxjob :".$command->{$urls->{"daemon/maxjob"}}."\n";}
	if(exists($command->{$urls->{"daemon/singlethread"}})){print STDOUT "#Single :".($command->{$urls->{"daemon/singlethread"}}?"true":"false")."\n";}
	if(exists($command->{$urls->{"daemon/qsubopt"}})){print STDOUT "#QsubOpt:".$command->{$urls->{"daemon/qsubopt"}}."\n";}
	if(exists($command->{$urls->{"daemon/script"}})){
		foreach my $script(@{$command->{$urls->{"daemon/script"}}}){
			print STDOUT "#Script :".$script->{$urls->{"daemon/script/name"}}."\n";
			foreach my $line(@{$script->{$urls->{"daemon/script/code"}}}){print STDOUT "        :$line\n";}
		}
	}
	print STDOUT "\n";
}
############################## assignCommand ##############################
sub assignCommand{
	my $command=shift();
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	my @arguments=();
	foreach my $input(@inputs){push(@arguments,promtCommandInput($command,$input));}
	foreach my $output(@outputs){push(@arguments,promtCommandOutput($command,$output));}
	return @arguments;
}
############################## promtCommandInput ##############################
sub promtCommandInput{
	my $command=shift();
	my $label=shift();
	print STDOUT "#Input [$label]?";
	my $value=<STDIN>;
	chomp($value);
	if($value eq ""){exit(1);}
	return $value;
}
############################## promtCommandOutput ##############################
sub promtCommandOutput{
	my $command=shift();
	my $label=shift();
	print STDOUT "#Output [$label]?";
	my $value=<STDIN>;
	chomp($value);
	if($value eq ""){return;}
	return $value;
}
############################## workflowProcess ##############################
sub workflowProcess{
	my $cmdurl=shift();
	my $commands=shift();
	my $workflows=shift();
	my $nodeid=shift();
	if(!defined($nodeid)){$nodeid=`perl $cwd/rdf.pl -d $rdfdb newnode`;}
	my $workflow=loadWorkflowFromURL($cmdurl,$workflows);
	my $command=loadCommandFromURL($cmdurl,$commands);
	print STDERR "cmdurl=$cmdurl\n";
	my @lines=("$nodeid->".$urls->{"daemon/workflow"}."->$cmdurl");
	if(exists($command->{"updateKeys"})){
		foreach my $update(@{$command->{"updateKeys"}}){
			my ($subject,$predicate,$object)=@{$update};
			if(exists($workflow->{$predicate})){
				foreach my $url(keys(%{$workflow->{$predicate}})){
					my $object=$workflow->{$predicate}->{$url};
					if(ref($object)ne"ARRAY"){$object=[$object];}
					foreach my $o(@{$object}){
						if(!exists($workflow->{$o})){next;}
						foreach my $url(keys(%{$workflow->{$o}})){
							push(@lines,workflowProcess($url,$commands,$workflows,$nodeid));
						}
					}
				}
			}
		}
	}
	return @lines;
}
############################## loadWorkflowFromURL ##############################
sub loadWorkflowFromURL{
	my $url=shift();
	my $workflows=shift();
	if($url=~/https:\/\/moirai2\.github\.io\/workflow\/([^\/]+)\//){$url="https://moirai2.github.io/workflow/$1.json";}
	if(exists($workflows->{$url})){return $workflows->{$url};}
	$workflows->{$url}=getJson($url);
	return $workflows->{$url};
}
############################## commandProcess ##############################
sub commandProcess{
	my @arguments=@_;
	my $url=shift(@arguments);
	my $commands=shift(@arguments);
	my $results=shift(@arguments);
	my $command=loadCommandFromURL($url,$commands);
	$commands->{$url}=$command;
	if(defined($opt_o)){push(@{$command->{"insertKeys"}},@{handleKeys($opt_o,$command)});}
	my @inputs=@{$command->{$urls->{"daemon/input"}}};
	my @outputs=@{$command->{$urls->{"daemon/output"}}};
	if($showlog){
		my $cmdline="#Command: ".basename($command->{$urls->{"daemon/command"}});
		if(scalar(@inputs)>0){$cmdline.=" [".join("] [",@inputs)."]";}
		if(scalar(@outputs)>0){$cmdline.=" [".join("] [",@outputs)."]";}
		print STDERR "$cmdline\n";
	}
	if(scalar(@inputs)>0&&scalar(@arguments)==0){@arguments=assignCommand($command);}
	if(scalar(@arguments)<scalar(@inputs)){exit(1);}
	my @lines=();
	my @nodeids=();
	if(scalar(keys(%{$results}))>0){
		foreach my $row(@{$results->{"rows"}}){
			my $variables={};
			for(my $i=0;$i<scalar(@{$row});$i++){
				my $key=$results->{"keys"}->[$i];
				my $val=$row->[$i];
				$variables->{"\$$key"}=$val;
			}
			my $hash={};
			for(my $i=0;$i<scalar(@inputs);$i++){
				my $input=$inputs[$i];
				my $argument=$arguments[$i];
				if(exists($variables->{$argument})){$argument=$variables->{$argument};}
				$hash->{$input}=$argument;
			}
			my ($nodeid,@array)=commandProcessSub($url,$hash);
			push(@nodeids,$nodeid);
			push(@lines,@array);
		}
	}else{
		my $hash={};
		foreach my $input(@inputs){$hash->{$input}=shift(@arguments);}
		foreach my $output(@outputs){
			if(scalar(@arguments)==0){last;}
			$hash->{$output}=shift(@arguments);
		}
		my ($nodeid,@array)=commandProcessSub($url,$hash);
		push(@nodeids,$nodeid);
		push(@lines,@array);
	}
	my ($fh,$file)=mkstemps("$ctrldir/insert/XXXXXXXXXX",".insert");
	foreach my $line(@lines){print $fh "$line\n";}
	close($fh);
	return @nodeids;
}
sub commandProcessSub{
	my $url=shift();
	my $hash=shift();
	my @lines=();
	my $nodeid=`perl $cwd/rdf.pl -d $rdfdb newnode`;
	chomp($nodeid);
	push(@lines,$urls->{"daemon"}."\t".$urls->{"daemon/execute"}."\t$nodeid");
	push(@lines,"$nodeid\t".$urls->{"daemon/command"}."\t$url");
	foreach my $key(keys(%{$hash})){push(@lines,"$nodeid\t$url#$key\t".$hash->{$key});}
	return ($nodeid,@lines);
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
				my $variables=shift(@{$executes->{$url}});
				initExecute($rdfdb,$command,$variables);
				push(@deletes,$urls->{"daemon"}."\t".$urls->{"daemon/execute"}."\t".$variables->{"nodeid"});
				bashCommand($command,$variables,$bashFiles);
				$maxjob--;
				$thrown++;
			}
		}
		throwJobs($bashFiles,$use_qsub,$qsubopt,$url,1);
		if(scalar(@{$executes->{$url}})>0){push(@{$execurls},$url);}
	}
	if(scalar(@deletes)>0){
		my ($fh,$file)=mkstemps("$ctrldir/delete/XXXXXXXXXX",".delete");
		foreach my $delete(@deletes){print $fh "$delete\n";}
		close($fh);
	}
	if(scalar(@inserts)>0){
		my ($fh,$file)=mkstemps("$ctrldir/insert/XXXXXXXXXX",".insert");
		foreach my $insert(@inserts){print $fh "$insert\n";}
		close($fh);
	}
	return $thrown;
}
############################## controlAll ##############################
sub controlAll{
	my $rdfdb=shift();
	my $executes=shift();
	my $ctrlcount=shift();
	my $jobcount=shift();
	my $completed=controlCompleted();
	my $inserted=controlInsert($rdfdb);
	my $deleted=controlDelete($rdfdb);
	my $update=controlUpdate($rdfdb);
	my $date=getDate("/");
	my $time=getTime(":");
	my @execurls=keys(%{$executes});
	my $remaining=0;
	foreach my $url(@execurls){my $count=scalar(@{$executes->{$url}});if($count>0){$remaining++;}}
	if($showlog){print STDERR "$date\t$time\t$ctrlcount\t$jobcount\t$remaining\t$inserted\t$deleted\t$update\t$completed\n";}
}
############################## throwJobs ##############################
sub throwJobs{
	my $bashFiles=shift();
	my $use_qsub=shift();
	my $qsubopt=shift();
	my $url=shift();
	my $background=shift();
	if(scalar(@{$bashFiles})==0){return;}
	my $cwd=Cwd::getcwd();
	my ($fh,$path)=mkstemps("$ctrldir/bash/runXXXXXXXXXX",".sh");
	my $dirname=basename($path,".sh");
	my $error_file="$ctrldir/stderr/$dirname.stderr";
	my $log_file="$ctrldir/stdout/$dirname.stdout";
	if($use_qsub){
		print $fh "#\$ -e $error_file\n";
		print $fh "#\$ -o $log_file\n";
		print $fh "PATH=$qsubbin:\$PATH\n";
		print $fh "export PATH\n";
	}
	foreach my $files(@{$bashFiles}){
		my ($bashFile,$stdoutFile,$stderrFile)=@{$files};
		print $fh "bash $bashFile > $stdoutFile 2> $stderrFile\n";
	}
	if($use_qsub){
		print $fh "if [ ! -s $error_file ];then\n";
		print $fh "rm -f $error_file\n";
		print $fh "fi\n";
		print $fh "if [ ! -s $log_file ];then\n";
		print $fh "rm -f $log_file\n";
		print $fh "fi\n";
	}
	print $fh "rm -f $path\n";
	close($fh);
	my $number=scalar(@{$bashFiles});
	if($use_qsub){
		if($showlog){print STDERR "#Submitting $path:\t";}
		my $command="qsub";
		if(defined($qsubopt)){$command.=" $qsubopt";}
		$command.=" $path";
		if(system($command)==0){print "OK\n";}
		else{print "FAILED\n";exit(1);}
	}else{
		if($showlog){print STDERR "#Executing $path:\t";}
		my $command="bash $path";
		if(defined($background)){$command.=" &";}
		if(system($command)==0){if($showlog){print STDERR "OK\n";}}
		else{if($showlog){print STDERR "FAILED\n";}exit(1);}
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
############################## controlUpdate ##############################
sub controlUpdate{
	my $rdfdb=shift();
	my @files=getFiles("$ctrldir/update");
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $cwd/rdf.pl -d $rdfdb -f tsv update";
	my $count=`$command`;
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## controlDelete ##############################
sub controlDelete{
	my $rdfdb=shift();
	my @files=getFiles("$ctrldir/delete");
	if(scalar(@files)==0){return 0;}
	my $command="cat ".join(" ",@files)."|perl $cwd/rdf.pl -d $rdfdb -f tsv delete";
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
	my $command="cat ".join(" ",@files)."|perl $cwd/rdf.pl -d $rdfdb -f tsv insert";
	my $count=`$command`;
	foreach my $file(@files){unlink($file);}
	$count=~/(\d+)/;
	$count=$1;
	return $count;
}
############################## getFiles ##############################
sub getFiles{
	my $directory=shift();
	my @files=();
	opendir(DIR,$directory);
	foreach my $file(readdir(DIR)){
		if($file eq "."){next;}
		if($file eq ".."){next;}
		if($file eq ""){next;}
		push(@files,"$directory/$file");
	}
	closedir(DIR);
	return @files;
}
############################## removeDollar ##############################
sub removeDollar{
	my $value=shift();
	if($value=~/^\$(.+)$/){return $1;}
	return $value;
}
############################## handleHash ##############################
sub handleHash{
	my @array=@_;
	my $hash={};
	foreach my $input(@array){$hash->{$input}=1;}
	return $hash;
}
############################## handleArray ##############################
sub handleArray{
	my $inputs=shift();
	if(!defined($inputs)){return [];}
	if(ref($inputs)ne"ARRAY"){
		if($inputs=~/,/){my @array=split(/,/,$inputs);$inputs=\@array;}
		else{$inputs=[$inputs];}
	}
	foreach my $input(@{$inputs}){if($input=~/^\$(.+)$/){$input=$1;};}
	return $inputs;
}
############################## loadCommandFromURL ##############################
sub loadCommandFromURL{
	my $url=shift();
	my $commands=shift();
	if(exists($commands->{$url})){return $commands->{$url};}
	if($showlog){print STDERR "#Loading $url:\t";}
	my $command=getJson($url);
	if(scalar(keys(%{$command}))==0){print "FAILED\n";return;}
	loadCommandFromURLSub($command,$url);
	$command->{$urls->{"daemon/command"}}=$url;
	if($showlog){print STDERR "OK\n";}
	$commands->{$url}=$command;
	return $command;
}
sub loadCommandFromURLSub{
	my $command=shift();
	my $url=shift();
	$command->{"input"}=[];
	$command->{"output"}=[];
	if(exists($command->{$urls->{"daemon/inputs"}})){
		$command->{$urls->{"daemon/inputs"}}=handleArray($command->{$urls->{"daemon/inputs"}});
		$command->{"inputs"}=handleHash(@{$command->{$urls->{"daemon/inputs"}}});
		if(!exists($command->{$urls->{"daemon/input"}})){$command->{$urls->{"daemon/input"}}=$command->{$urls->{"daemon/inputs"}};}
	}
	if(exists($command->{$urls->{"daemon/input"}})){
		$command->{$urls->{"daemon/input"}}=handleArray($command->{$urls->{"daemon/input"}});
		my @array=();
		foreach my $input(@{$command->{$urls->{"daemon/input"}}}){push(@array,$input);}
		if(exists($command->{$urls->{"daemon/inputs"}})){
			my $hash=handleHash(@{$command->{$urls->{"daemon/input"}}});
			foreach my $input(@{$command->{"daemon/inputs"}}){if(!exists($hash->{$input})){push(@array,$input);}}
		}
		$command->{"input"}=\@array;
	}
	if(exists($command->{$urls->{"daemon/outputs"}})){
		$command->{$urls->{"daemon/outputs"}}=handleArray($command->{$urls->{"daemon/outputs"}});
		$command->{"outputs"}=$command->{$urls->{"daemon/outputs"}};
	}
	if(exists($command->{$urls->{"daemon/return"}})){
		$command->{$urls->{"daemon/output"}}=handleArray($command->{$urls->{"daemon/output"}});
		my $hash=handleHash(@{$command->{$urls->{"daemon/output"}}});
		my $returnvalue=$command->{$urls->{"daemon/return"}};
		if(!exists($hash->{$returnvalue})){push(@{$command->{$urls->{"daemon/output"}}},$returnvalue);}
	}
	if(exists($command->{$urls->{"daemon/output"}})){
		$command->{$urls->{"daemon/output"}}=handleArray($command->{$urls->{"daemon/output"}});
		my @array=();
		foreach my $output(@{$command->{$urls->{"daemon/output"}}}){push(@array,$output);}
		if(exists($command->{$urls->{"daemon/outputs"}})){
			my $hash=handleHash(@{$command->{$urls->{"daemon/output"}}});
			foreach my $output(@{$command->{"daemon/outputs"}}){if(!exists($hash->{$output})){push(@array,$output);}}
		}
		$command->{"output"}=\@array;
	}
	if(scalar(@{$command->{"input"}})==0&&!exists($command->{$urls->{"daemon/select"}})){$command->{$urls->{"daemon/select"}}="";}
	if(exists($command->{$urls->{"daemon/select"}})){
		my @temp=parseQuery($command->{$urls->{"daemon/select"}},$urls->{"daemon"}."->".$urls->{"daemon/execute"}."->\$nodeid,\$nodeid->".$urls->{"daemon/command"}."->$url");
		$command->{"rdfQuery"}=$temp[0];
		$command->{"keys"}=$temp[1];
		$command->{"input"}=$temp[2];
		$command->{"selectKeys"}=handleKeys($command->{$urls->{"daemon/select"}});
	}else{
		my @array=();
		foreach my $input(@{$command->{"input"}}){push(@array,$input);}
		foreach my $output(@{$command->{"output"}}){push(@array,$output);}
		$command->{"keys"}=\@array;
	}
	if(exists($command->{$urls->{"daemon/return"}})){$command->{$urls->{"daemon/return"}}=removeDollar($command->{$urls->{"daemon/return"}});}
	if(exists($command->{$urls->{"system/install"}})){$command->{$urls->{"system/install"}}=handleArray($command->{$urls->{"system/install"}});}
	if(exists($command->{$urls->{"daemon/unzip"}})){$command->{$urls->{"daemon/unzip"}}=handleArray($command->{$urls->{"daemon/unzip"}});}
	if(exists($command->{$urls->{"daemon/md5"}})){$command->{$urls->{"daemon/md5"}}=handleArray($command->{$urls->{"daemon/md5"}});}
	if(exists($command->{$urls->{"daemon/filesize"}})){$command->{$urls->{"daemon/filesize"}}=handleArray($command->{$urls->{"daemon/filesize"}});}
	if(exists($command->{$urls->{"daemon/linecount"}})){$command->{$urls->{"daemon/linecount"}}=handleArray($command->{$urls->{"daemon/linecount"}});}
	if(exists($command->{$urls->{"daemon/seqcount"}})){$command->{$urls->{"daemon/seqcount"}}=handleArray($command->{$urls->{"daemon/seqcount"}});}
	if(exists($command->{$urls->{"daemon/import"}})){if(ref($command->{$urls->{"daemon/import"}}) ne "ARRAY"){$command->{$urls->{"daemon/import"}}=[$command->{$urls->{"daemon/import"}}];}}
	if(exists($command->{$urls->{"daemon/insert"}})){$command->{"insertKeys"}=handleKeys($command->{$urls->{"daemon/insert"}},$command);}
	if(exists($command->{$urls->{"daemon/update"}})){$command->{"updateKeys"}=handleKeys($command->{$urls->{"daemon/update"}},$command);}
	if(exists($command->{$urls->{"daemon/delete"}})){$command->{"deleteKeys"}=handleKeys($command->{$urls->{"daemon/delete"}},$command);}
	if(exists($command->{$urls->{"daemon/bash"}})){
		$command->{"bashCode"}=handleCode($command->{$urls->{"daemon/bash"}});
		foreach my $line(@{$command->{"bashCode"}}){if($line=~/moirai2.pl/){$command->{"batchmode"}=1;}}
	}
	if(!exists($command->{$urls->{"daemon/maxjob"}})){$command->{$urls->{"daemon/maxjob"}}=1;}
	if(exists($command->{$urls->{"daemon/script"}})){handleScript($command);}
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
############################## handleCode ##############################
sub handleCode{
	my $code=shift();
	if(ref($code) eq "ARRAY"){return $code;}
	my @lines=split(/\n/,$code);
	return \@lines;
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
	my $query="select distinct k.data,s.data,p.data,o.data from edge as e1 inner join edge as e2 on e1.object=e2.subject inner join node as k on e1.subject=k.id inner join node as s on e2.subject=s.id inner join node as p on e2.predicate=p.id inner join node as o on e2.object=o.id where e1.predicate=(select id from node where data=\"".$urls->{"daemon/execute"}."\")";
	my $url=$command->{$urls->{"daemon/command"}};
	my $dbh=openDB($rdfdb);
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $rows2=$sth->fetchall_arrayref();
	$dbh->disconnect;
	my @keys=@{$command->{"keys"}};
	my $variables={};
	foreach my $row(@{$rows2}){
		my @array=();
		my $keyinput=$row->[0];
		my $nodeid=$row->[1];
		my $predicate=$row->[2];
		my $object=$row->[3];
		if($object eq $url){next;}
		if(!exists($variables->{$nodeid})){$variables->{$nodeid}={};$variables->{$nodeid}->{"nodeid"}=$nodeid;}
		if($predicate=~/^$url#(.+)$/){
			my $key=$1;
			if(!exists($variables->{$nodeid}->{$key})){$variables->{$nodeid}->{$key}=$object;}
			elsif(ref($variables->{$nodeid}->{$key})eq"ARRAY"){push(@{$variables->{$nodeid}->{$key}},$object);}
			else{$variables->{$nodeid}->{$key}=[$variables->{$nodeid}->{$key},$object]}
		}
	}
	my $count=0;
	foreach my $key(sort{$a cmp $b}keys(%{$variables})){push(@{$executes->{$url}},$variables->{$key});$count++;}
	return $count;
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
			my $variables={};
			for(my $i=0;$i<scalar(@{$value});$i++){$variables->{$keys->[$i]}=$value->[$i];}
			push(@{$executes->{$url}},$variables);
			$count++;
		}
	}else{
		foreach my $row(@{$rows}){
			my $variables={};
			for(my $i=0;$i<scalar(@{$row});$i++){
				my $key=$keys->[$i];
				my $value=$row->[$i];
				$variables->{$key}=$value;
			}
			push(@{$executes->{$url}},$variables);
			$count++;
		}
	}
	foreach my $line(@{$command->{"selectKeys"}}){
		my @tokens=@{$line};
		if($tokens[1] eq $urls->{"daemon/execute"}){
			my $nodekey=substr($tokens[2],1);
			foreach my $variables(@{$executes->{$url}}){$variables->{"nodeid"}=$variables->{$nodekey};}
		}
	}
	return $count;
}
############################## initExecute ##############################
sub initExecute{
	my $rdfdb=shift();
	my $command=shift();
	my $variables=shift();
	if(!defined($variables)){$variables={};}
	my $url=$command->{$urls->{"daemon/command"}};
	my $cwd=Cwd::getcwd();
	$variables->{"cwd"}=$cwd;
	$variables->{"cmdurl"}=$url;
	my $dirname=basename($url,".json");
	$variables->{"rdfdb"}=$rdfdb;
	my $tmpdir=mkdtemp("tmp/$dirname.XXXXXXXXXX");
	chmod(0777,$tmpdir);
	$variables->{"tmpdir"}=$tmpdir;
	my $dirname=substr($tmpdir,4);
	$variables->{"bashfile"}="$dirname.sh";
	$variables->{"stderrfile"}="$dirname.stderr";
	$variables->{"stdoutfile"}="$dirname.stdout";
	$variables->{"insertfile"}="$dirname.insert";
	$variables->{"deletefile"}="$dirname.delete";
	$variables->{"updatefile"}="$dirname.update";
	$variables->{"completedfile"}="$dirname.completed";
	$variables->{"dirname"}=$dirname;
	$variables->{"localdb"}="$cwd/$tmpdir/rdf.sqlite3";
	return $variables;
}
############################## bashCommand ##############################
sub bashCommand{
	my $command=shift();
	my $variables=shift();
	my $bashFiles=shift();
	my $cwd=$variables->{"cwd"};
	my $tmpdir=$variables->{"tmpdir"};
	my $nodeid=$variables->{"nodeid"};
	my $localdb=$variables->{"localdb"};
	my $url=$command->{$urls->{"daemon/command"}};
	my $bashfile="$cwd/$tmpdir/".$variables->{"bashfile"};
	my $stderrfile="$cwd/$tmpdir/".$variables->{"stderrfile"};
	my $stdoutfile="$cwd/$tmpdir/".$variables->{"stdoutfile"};
	my $insertfile="$cwd/$tmpdir/".$variables->{"insertfile"};
	my $deletefile="$cwd/$tmpdir/".$variables->{"deletefile"};
	my $updatefile="$cwd/$tmpdir/".$variables->{"updatefile"};
	my $completedfile="$cwd/$tmpdir/".$variables->{"completedfile"};
	open(OUT,">$bashfile");
	print OUT "#!/bin/sh\n";
	print OUT "set -eu\n";
	print OUT "########## system ##########\n";
	my @systemvars=("cmdurl","dirname","rdfdb","cwd","nodeid","tmpdir");
	my @systemfiles=("bashfile","stdoutfile","stderrfile","deletefile","updatefile","insertfile","completedfile");
	my @unusedvars=();
	my @outputvars=(@{$command->{"output"}});
	if(exists($command->{"batchmode"})){push(@systemvars,"localdb");}
	else{push(@unusedvars,"localdb");}
	foreach my $var(@systemvars){print OUT "$var=\"".$variables->{$var}."\"\n";}
	foreach my $var(@systemfiles){print OUT "$var=\"".$variables->{$var}."\"\n";}
	my @keys=();
	foreach my $key(sort{$a cmp $b}keys(%{$variables})){
		my $break=0;
		foreach my $var(@systemvars){if($var eq $key){$break=1;last;}}
		foreach my $var(@systemfiles){if($var eq $key){$break=1;last;}}
		foreach my $var(@unusedvars){if($var eq $key){$break=1;last;}}
		foreach my $var(@outputvars){if($var eq $key){$break=1;last;}}
		if($break){next;}
		push(@keys,$key);
	}
	if(scalar(@keys)>0){print OUT "########## variables ##########\n";}
	foreach my $key(@keys){
		my $value=$variables->{$key};
		if(ref($value)eq"ARRAY"){print OUT "$key=(\"".join("\" \"",@{$value})."\")\n";}
		else{print OUT "$key=\"$value\"\n";}
	}
	my @scriptfiles=();
	if(exists($command->{"script"})){
		print OUT "########## script ##########\n";
		foreach my $name (@{$command->{"script"}}){
			push(@scriptfiles,"$cwd/$name");
			print OUT "cat<<EOF>$name\n";
			for(my $i=0;$i<scalar(@{$command->{$name}});$i++){
				my $code=$command->{$name}->[$i];
				$code=~s/\$/\\\$/g;
				print OUT "$code\n";
			}
			print OUT "EOF\n";
		}
	}
	print OUT "########## initialize ##########\n";
	print OUT "cd \$cwd\n";
	print OUT "cat<<EOF>>\$tmpdir/\$insertfile\n";
	my $inputs=$command->{"inputs"};
	print OUT "\$nodeid\t".$urls->{"daemon/command"}."\t\$cmdurl\n";
	foreach my $input(@{$command->{"input"}}){
		if(exists($inputs->{$input})){foreach my $value(@{$variables->{$input}}){print OUT "\$nodeid\t\$cmdurl#$input\t$value\n";}}
		else{print OUT "\$nodeid\t\$cmdurl#$input\t\$$input\n";}
	}
	print OUT "\$nodeid\t".$urls->{"daemon/timestarted"}."\t`date +%s`\n";
	print OUT "EOF\n";
	my @unzips=();
	if(exists($command->{$urls->{"daemon/unzip"}})){
		print OUT "########## unzip ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/unzip"}}}){
			if(exists($variables->{$key})){
				my @values=(ref($variables->{$key})eq"ARRAY")?@{$variables->{$key}}:($variables->{$key});
				foreach my $value(@values){
					if($value=~/^(.+)\.bz(ip)?2$/){
						my $basename=basename($1);
						print OUT "$key=\$tmpdir/$basename\n";
						print OUT "bzip2 -cd $value>\$$key\n";
						push(@unzips,"\$tmpdir/$basename");
					}elsif($value=~/\.gz(ip)?$/){
						my $basename=basename($1);
						print OUT "$key=\$tmpdir/$basename\n";
						print OUT "gzip -cd $value>\$$key\n";
						push(@unzips,"\$tmpdir/$basename");
					}
				}
			}
		}
	}
	if(exists($command->{$urls->{"system/install"}})){
		foreach my $url(@{$command->{$urls->{"system/install"}}}){
			if($url=~/^https\:\/\/anaconda\.org\/(.+)$/){
				my $environment=$1;
				$environment=~s/\//_/g;
				my $command="perl $cwd/rdf.pl -d $rdfdb -e $environment miniconda $url";
				print STDERR "$command\n";
			}
		}
	}
	print OUT "########## command ##########\n";
	foreach my $line(@{$command->{"bashCode"}}){print OUT "$line\n";}
	foreach my $output(@{$command->{"output"}}){
		my $count=0;
		if(exists($variables->{$output})){
			my $value=$variables->{$output};
			if($count==0){print OUT "########## move ##########\n";}
			print OUT "mv \$$output $value\n";
			print OUT "$output=$value\n";
			$count++;
		}
	}
	if(exists($command->{$urls->{"daemon/linecount"}})){
		print OUT "########## linecount ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/linecount"}}}){
			if(existsArray($command->{"input"},$key)){print OUT "perl \$cwd/rdf.pl linecount \$$key>>\$tmpdir/\$insertfile\n";}
			elsif(existsArray($command->{"inputs"},$key)){
				print OUT "for e in \${$key"."[\@]} ; do\n";
				print OUT "perl \$cwd/rdf.pl linecount \$$key>>\$tmpdir/\$insertfile\n";
				print OUT "done\n";
			}
		}
	}
	if(exists($command->{$urls->{"daemon/seqcount"}})){
		print OUT "########## seqcount ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/seqcount"}}}){
			if(existsArray($command->{"input"},$key)){print OUT "perl \$cwd/rdf.pl seqcount \$$key>>\$tmpdir/\$insertfile\n";}
			elsif(existsArray($command->{"inputs"},$key)){
				print OUT "for e in \${$key"."[\@]} ; do\n";
				print OUT "perl \$cwd/rdf.pl seqcount \$$key>>\$tmpdir/\$insertfile\n";
				print OUT "done\n";
			}
		}
	}
	if(exists($command->{$urls->{"daemon/md5"}})){
		print OUT "########## md5 ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/md5"}}}){
			if(existsArray($command->{"input"},$key)){print OUT "perl \$cwd/rdf.pl md5 \$$key>>\$tmpdir/\$insertfile\n";}
			elsif(existsArray($command->{"inputs"},$key)){
				print OUT "for e in \${$key"."[\@]} ; do\n";
				print OUT "perl \$cwd/rdf.pl md5 \$$key>>\$tmpdir/\$insertfile\n";
				print OUT "done\n";
			}
		}
	}
	if(exists($command->{$urls->{"daemon/filesize"}})){
		print OUT "########## filesize ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/filesize"}}}){
			if(existsArray($command->{"input"},$key)){print OUT "perl \$cwd/rdf.pl filesize \$$key>>\$tmpdir/\$insertfile\n";}
			elsif(existsArray($command->{"inputs"},$key)){
				print OUT "for e in \${$key"."[\@]} ; do\n";
				print OUT "perl \$cwd/rdf.pl filesize \$$key>>\$tmpdir/\$insertfile\n";
				print OUT "done\n";
			}
		}
	}
	print OUT "########## database ##########\n";
	print OUT "cat<<EOF>>\$tmpdir/\$insertfile\n";
	print OUT "\$nodeid\t".$urls->{"daemon/timeended"}."\t`date +%s`\n";
	foreach my $output(@{$command->{"output"}}){print OUT "\$nodeid\t\$cmdurl#$output\t\$$output\n";}
	if(scalar(@{$command->{"insertKeys"}})>0){foreach my $row(@{$command->{"insertKeys"}}){print OUT join("\t",@{$row})."\n";}}
	print OUT "EOF\n";
	foreach my $output(@{$command->{"outputs"}}){
		print OUT "for e in \${$output"."[\@]} ; do\n";
		print OUT "echo \"\$nodeid\t\$cmdurl#$output\t\$e\">>\$tmpdir/\$insertfile\n";
		print OUT "done\n";
	}
	if(exists($command->{"batchmode"})){print OUT "perl \$cwd/rdf.pl -d \$localdb dump >> \$tmpdir/\$insertfile\nrm \$localdb\n";}
	if(exists($command->{$urls->{"daemon/linecount"}})){
		print OUT "########## linecount ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/linecount"}}}){
			if(existsArray($command->{"output"},$key)){print OUT "perl \$cwd/rdf.pl linecount \$$key>>\$tmpdir/\$insertfile\n";}
			elsif(existsArray($command->{"outputs"},$key)){
				print OUT "for e in \${$key"."[\@]} ; do\n";
				print OUT "perl \$cwd/rdf.pl linecount \$$key>>\$tmpdir/\$insertfile\n";
				print OUT "done\n";
			}
		}
	}
	if(exists($command->{$urls->{"daemon/seqcount"}})){
		print OUT "########## seqcount ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/seqcount"}}}){
			if(existsArray($command->{"output"},$key)){print OUT "perl \$cwd/rdf.pl seqcount \$$key>>\$tmpdir/\$insertfile\n";}
			elsif(existsArray($command->{"outputs"},$key)){
				print OUT "for e in \${$key"."[\@]} ; do\n";
				print OUT "perl \$cwd/rdf.pl seqcount \$$key>>\$tmpdir/\$insertfile\n";
				print OUT "done\n";
			}
		}
	}
	if(exists($command->{$urls->{"daemon/md5"}})){
		print OUT "########## md5 ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/md5"}}}){
			if(existsArray($command->{"output"},$key)){print OUT "perl \$cwd/rdf.pl md5 \$$key>>\$tmpdir/\$insertfile\n";}
			elsif(existsArray($command->{"outputs"},$key)){
				print OUT "for e in \${$key"."[\@]} ; do\n";
				print OUT "perl \$cwd/rdf.pl md5 \$$key>>\$tmpdir/\$insertfile\n";
				print OUT "done\n";
			}
		}
	}
	if(exists($command->{$urls->{"daemon/filesize"}})){
		print OUT "########## filesize ##########\n";
		foreach my $key(@{$command->{$urls->{"daemon/filesize"}}}){
			if(existsArray($command->{"output"},$key)){print OUT "perl \$cwd/rdf.pl filesize \$$key>>\$tmpdir/\$insertfile\n";}
			elsif(existsArray($command->{"outputs"},$key)){
				print OUT "for e in \${$key"."[\@]} ; do\n";
				print OUT "perl \$cwd/rdf.pl filesize \$$key>>\$tmpdir/\$insertfile\n";
				print OUT "done\n";
			}
		}
	}
	if(scalar(@{$command->{"updateKeys"}})>0){
		print OUT "cat<<EOF>>\$tmpdir/\$updatefile\n";
		foreach my $row(@{$command->{"updateKeys"}}){print OUT join("\t",@{$row})."\n";}
		print OUT "EOF\n";
	}
	if(scalar(@{$command->{"deleteKeys"}})>0){
		print OUT "cat<<EOF>>\$tmpdir/\$deletefile\n";
		foreach my $row(@{$command->{"deleteKeys"}}){print OUT join("\t",@{$row})."\n";}
		print OUT "EOF\n";
	}
	print OUT "if [ -s \$tmpdir/\$stdoutfile ];then\n";
	print OUT "echo \"\$nodeid\t\$cmdurl#stdoutfile\t\$tmpdir/\$stdoutfile\">>\$tmpdir/\$insertfile\n";
	print OUT "echo \"\$nodeid\t".$urls->{"daemon/stdout"}."\t\$tmpdir/\$stdoutfile\">>\$tmpdir/\$insertfile\n";
	print OUT "fi\n";
	print OUT "if [ -s \$tmpdir/\$stderrfile ];then\n";
	print OUT "echo \"\$nodeid\t\$cmdurl#stderrfile\t\$tmpdir/\$stderrfile\">>\$tmpdir/\$insertfile\n";
	print OUT "echo \"\$nodeid\t".$urls->{"daemon/stderr"}."\t\$tmpdir/\$stderrfile\">>\$tmpdir/\$insertfile\n";
	print OUT "fi\n";
	if(scalar(@unzips)>0){
		print OUT "########## cleanup ##########\n";
		foreach my $unzip(@unzips){print OUT "rm $unzip\n";}
	}
	print OUT "########## completed ##########\n";
	my $importcount=0;
	foreach my $importfile(@{$command->{$urls->{"daemon/import"}}}){print OUT "mv \$cwd/$importfile $ctrldir/insert/$nodeid.import\n";$importcount++;}
	print OUT "mv \$cwd/\$tmpdir/\$completedfile $ctrldir/completed/\$dirname.sh\n";
	close(OUT);
	writeCompleteFile($completedfile,$stdoutfile,$stderrfile,$insertfile,$deletefile,$updatefile,$bashfile,\@scriptfiles,$tmpdir,$cwd);
	if(exists($variables->{"bashfile"})){push(@{$bashFiles},[$variables->{"cwd"}."/".$variables->{"tmpdir"}."/".$variables->{"bashfile"},$variables->{"cwd"}."/".$variables->{"tmpdir"}."/".$variables->{"stdoutfile"},$variables->{"cwd"}."/".$variables->{"tmpdir"}."/".$variables->{"stderrfile"}]);}
}
############################## existsArray ##############################
sub existsArray{
	my $array=shift();
	my $needle=shift();
	foreach my $value(@{$array}){if($needle eq $value){return 1;}}
	return 0;
}
############################## existsProcess ##############################
#existsProcess(\%command,$url);
sub existsProcess{
	my $command=shift();
	my $url=shift();
	if(!exists($command->{$urls->{"daemon/batch"}})){return 0;}
	foreach my $process(@{$command->{$urls->{"daemon/batch"}}}){if(exists($process->{$url})){return 1;}}
	return 0;
}
############################## constructMvTemplate ##############################
#my (\@templates,\@keys)=constructMvTemplate($value)
sub constructMvTemplate{
	my $hash=shift();
	my @templates=();
	my @keys=();
	while(my($key,$value)=each(%{$hash})){
		push(@templates,"$key\t$value");
		my $line=$key;
		while($line=~/\$(\w+)/){my $name=$1;$line=~s/\$$name//g;push(@keys,"\$$name");}
		$line=$value;
		while($line=~/\$(\w+)/){my $name=$1;$line=~s/\$$name//g;push(@keys,"\$$name");}
	}
	if(scalar(@keys)>0){return (\@templates,[\@keys]);}
	else{return (\@templates,[]);}
}
############################## constructMkdirTemplate ##############################
#my (\@templates,\@keys)=constructMkdirTemplate(\@array)
sub constructMkdirTemplate{
	my $array=shift();
	my @templates=();
	my @keys=();
	if(ref($array)ne"ARRAY"){$array=[$array];}
	for(my $i=0;$i<scalar(@{$array});$i++){
		 my $dirname=$array->[$i];
		push(@templates,"mkdir -p $dirname");
		while($dirname=~/\$(\w+)/){my $name=$1;$dirname=~s/\$$name//g;push(@keys,"\$$name");}
	}
	if(scalar(@keys)>0){return (\@templates,[\@keys]);}
	else{return (\@templates,[]);}
}
############################## constructToInsertTemplate ##############################
#my (\@templates,\@keys)=constructToInsertTemplate(\@array)
sub constructToInsertTemplate{
	my $array=shift();
	my @templates=();
	my @keys=();
	if(ref($array)ne"ARRAY"){$array=[$array];}
	for(my $i=0;$i<scalar(@{$array});$i++){
		 my $file=$array->[$i];
		push(@templates,"cat $file");
		while($file=~/\$(\w+)/){my $name=$1;$file=~s/\$$name//g;push(@keys,"\$$name");}
	}
	if(scalar(@keys)>0){return (\@templates,[\@keys]);}
	else{return (\@templates,[]);}
}
############################## constructImportTemplate ##############################
#my (\@templates,\@keys)=constructImportTemplate(\@array)
sub constructImportTemplate{
	my $array=shift();
	my @templates=();
	my @keys=();
	if(ref($array)ne"ARRAY"){$array=[$array];}
	for(my $i=0;$i<scalar(@{$array});$i++){
		 my $file=$array->[$i];
		push(@templates,"mv $file $ctrldir/insert/.");
		while($file=~/\$(\w+)/){my $name=$1;$file=~s/\$$name//g;push(@keys,"\$$name");}
	}
	if(scalar(@keys)>0){return (\@templates,[\@keys]);}
	else{return (\@templates,[]);}
}
############################## constructRmdirTemplate ##############################
#my (\@templates,\@keys)=constructRmdirTemplate(\@array)
sub constructRmdirTemplate{
	my $array=shift();
	my @templates=();
	my @keys=();
	if(ref($array)ne"ARRAY"){$array=[$array];}
	for(my $i=0;$i<scalar(@{$array});$i++){
		my $dirname=$array->[$i];
		push(@templates,"rmdir $dirname");
		while($dirname=~/\$(\w+)/){my $name=$1;$dirname=~s/\$$name//g;push(@keys,"\$$name");}
	}
	if(scalar(@keys)>0){return (\@templates,[\@keys]);}
	else{return (\@templates,[]);}
}
############################## constructRmTemplate ##############################
#my (\@templates,\@keys)=constructRmTemplate(\@array)
sub constructRmTemplate{
	my $array=shift();
	my @templates=();
	my @keys=();
	if(ref($array)ne"ARRAY"){$array=[$array];}
	for(my $i=0;$i<scalar(@{$array});$i++){
		 my $file=$array->[$i];
		push(@templates,"rm $file");
		while($file=~/\$(\w+)/){my $name=$1;$file=~s/\$$name//g;push(@keys,"\$$name");}
	}
	if(scalar(@keys)>0){return (\@templates,[\@keys]);}
	else{return (\@templates,[]);}
}
############################## constructConcatTemplate ##############################
#my (\@templates,\@keys)=constructConcatTemplate(\@array)
sub constructConcatTemplate{
	my $hash=shift();
	my @templates=();
	my @keys=();
	while(my($key,$value)=each(%{$hash})){
		if(ref($value)eq"ARRAY"){push(@templates,"cat ".join(" ",@{$value}).">>$key");}
		else{push(@templates,"cat $value>>$key");}
		my $line=$key;
		while($line=~/\$(\w+)/){my $name=$1;$line=~s/\$$name//g;push(@keys,"\$$name");}
		$line=$value;
		while($line=~/\$(\w+)/){my $name=$1;$line=~s/\$$name//g;push(@keys,"\$$name");}
	}
	if(scalar(@keys)>0){return (\@templates,[\@keys]);}
	else{return (\@templates,[]);}
}
############################## getCurrentCommandUrl ##############################
#getCurrentCommandUrl(\@rows);
sub getCurrentCommandUrl{
	my $rows=shift();
	foreach my $row(@{$rows}){
		if(scalar(@{$row})!=3){next;}
		if($row->[1] eq $urls->{"daemon/command"}){return $row->[2];}
	}
}
############################## printRowsWithData ##############################
sub printRowsWithData{
	my $datas=shift();
	my $rows=shift();
	foreach my $data(@{$datas}){
		foreach my $row(@{$rows}){
			if(scalar(@{$row})!=3){next;}
			my @out=();
			for(my $i=0;$i<3;$i++){
				my $token=$row->[$i];
				if(exists($data->{$token})){$token=$data->{$token};}
				push(@out,$token);
			}
			print OUT join("\t",@out)."\n";
		}
	}
}
############################## constructQueryAndFormat ##############################
sub constructQueryAndFormat{
	my $url=shift();
	my $template=shift();
	my $keys=shift();
	my $variables={};
	if(!defined($keys)){$keys=handleKeys($template);}
	foreach my $key(@{$keys}){foreach my $k(@{$key}){if($k=~/^\$(.+)$/){$variables->{$1}="$url#$1";}}}
	my @queries=();
	while(my($k,$v)=each(%{$variables})){push(@queries,"'\$nodeid->$v->\$$k'");}
	my $query=join(" ",@queries);
	my $format=(ref($template)eq"ARRAY")?join(",",@{$template}):$template;
	return ($query,$format);
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
	my $tmpdir=shift();
	my $cwd=shift();
	my $localdb=shift();
	open(OUT,">$completedfile");
	print OUT "cwd=$cwd\n";
	print OUT "tmpdir=$tmpdir\n";
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
	print OUT "rmdir $tmpdir/ctrl/bash > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/completed > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/delete > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/insert > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/update > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/stderr > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/stdout > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/ > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ > /dev/null 2>&1\n";
	close(OUT);
}
############################## handleKeys ##############################
sub handleKeys{
	my $statement=shift();
	my $command=shift();
	my @array=();
	my @statements;
	if(ref($statement) eq "ARRAY"){@statements=@{$statement};}
	else{@statements=split(",",$statement);}
	foreach my $line (@statements){my @tokens=split(/->/,$line);push(@array,\@tokens);}
	return \@array;
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
	my $connects={};
	my $variables={};
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
				#empty=skip
			}elsif($node=~/^\!(.+)$/){
				#negation
				my $var=$1;
				push(@where_conditions,"($edge_name.subject is null or $edge_name.subject not in (select subject from edge where $rdf=(select id from node where data='$var')))");
				if($i>0){$edge_line="left outer join ";}
			}elsif($node=~/^\$(.+)$/){
				#variable
				my $node_name=$1;
				if(!exists($variables->{$node_name})){$variables->{$node_name}=scalar(keys(%{$variables}));push(@nodeRegisters,$node_name);}
				if(!exists($connections->{$node_name})){$connections->{$node_name}=[];}
				push(@{$connections->{$node_name}},"$edge_name.$rdf");
			}elsif($node=~/^\(.+\)$/){
				#non variable OR
				my @array=();
				foreach my $n(split(/\|/,$1)){
					if($n=~/%/){push(@array,"data like '$n'");}
					else{push(@array,"data='$n'");}
					$node_index++;
				}
				push(@wheres,"$rdf in (select id from node where ".join(" or ",@array).")");
			}else{
				#non variable
				push(@wheres,"$rdf=(select id from node where data='$node')");
				$node_index++;
			}
			foreach my $node_name(@nodeRegisters){push(@joins,"inner join node as $node_name on $edge_name.$rdf=$node_name.id");}
		}
		if(scalar(@wheres)>0){$edge_line.="(select * from edge where ".join(" and ",@wheres).")"}
		else{$edge_line.="edge";}
		$connects->{$edge_name}="$edge_line as $edge_name";
	}
	my @varnames=sort{$variables->{$a}<=>$variables->{$b}}keys(%{$variables});
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
############################## getJson ##############################
sub getJson{
	my $url=shift();
	my $username=shift();
	my $password=shift();
	my $content=($url=~/https?:\/\//)?getHttpContent($url,$username,$password):getFileContent($url);
	$content=~s/\$this/$url/g;
	return json_decode($content);
}
############################## getFileContent ##############################
sub getFileContent{
	my $path=shift();
	open(IN,$path);
	my $content;
	while(<IN>){chomp;s/\r//g;$content.=$_;}
	close(IN);
	return $content;
}
############################## json_encode ##############################
sub json_encode{
	my $object=shift;
	if(ref($object) eq "ARRAY"){return json_encode_array($object);}
	elsif(ref($object) eq "HASH"){return json_encode_hash($object);}
	else{return "\"".json_escape($object)."\"";}
}
sub json_encode_array{
	my $hashtable=shift();
	my $json="[";
	my $i=0;
	foreach my $object(@{$hashtable}){
		if($i>0){$json.=",";}
		$json.=json_encode($object);
		$i++;
	}
	$json.="]";
	return $json;
}
sub json_encode_hash{
	my $hashtable=shift();
	my $json="{";
	my $i=0;
	foreach my $subject (sort{$a cmp $b} keys(%{$hashtable})){
		if($i>0){$json.=",";}
		$json.="\"$subject\":".json_encode($hashtable->{$subject});
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
############################## json_decode ##############################
sub json_decode{
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
############################## openDB ##############################
sub openDB{
	my $db=shift();
	my $dbh=DBI->connect("dbi:SQLite:dbname=$db");
	$dbh->do("CREATE TABLE IF NOT EXISTS node(id INTEGER PRIMARY KEY,data TEXT)");
	$dbh->do("CREATE TABLE IF NOT EXISTS edge(subject INTEGER,predicate INTEGER,object INTEGER,PRIMARY KEY (subject,predicate,object))");
	chmod(0777,$db);
	return $dbh;
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
############################## print_rows ##############################
sub print_rows{
	my $keys=shift();
	my $rows=shift();
	my @lengths=();
	my @labels=();
	foreach my $key(@{$keys}){push(@labels,"\$$key");}
	my $indexlength=length("".scalar(@{$rows}));
	for(my $i=0;$i<scalar(@labels);$i++){$lengths[$i]=length($labels[$i]);}
	for(my $i=0;$i<scalar(@{$rows});$i++){
		for(my $j=0;$j<scalar(@{$rows->[$i]});$j++){
			my $token=$rows->[$i]->[$j];
			my $length=length($token);
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
		$labelline.=$label;
		for(my $j=$l;$j<$lengths[$i];$j++){$labelline.=" ";}
	}
	$labelline.="|";
	print STDERR "$labelline\n";
	print STDERR "$tableline\n";
	for(my $i=0;$i<scalar(@{$rows});$i++){
		my $line="$i";
		my $l=length($line);
		for(my $j=$l;$j<$indexlength;$j++){$line=" $line";}
		$line="|$line";
		for(my $j=0;$j<scalar(@{$rows->[$i]});$j++){
			my $token=$rows->[$i]->[$j];
			my $l=length($token);
			$line.="|$token";
			for(my $k=$l;$k<$lengths[$j];$k++){$line.=" ";}
		}
		$line.="|";
		print STDERR "$line\n";
	}
	print STDERR "$tableline\n";
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
############################## getNumberOfJobsRunning ##############################
sub getNumberOfJobsRunning{my @files=getFiles("$ctrldir/bash");return scalar(@files);}
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
############################## absolute_path ##############################
# Return absolute path - 2012/04/07
# This returns absolute path of a file
# Takes care of symbolic link problem where Cwd::abs_path returns the actual file instead of fullpath
# $path absolute_path( $path );
sub absolute_path {
	my $path      = shift();
	my $directory = dirname( $path );
	my $filename  = basename( $path );
	return Cwd::abs_path( $directory ) . "/" . $filename;
}
############################## list_files ##############################
# list files under a directory - 2018/02/01
# Fixed recursion problem - 2018/02/01
# list_files($file_suffix,@input_directories);
sub list_files{
	my @input_directories=@_;
	my $file_suffix=shift(@input_directories);
	my @input_files=();
	foreach my $input_directory (@input_directories){
		$input_directory=absolute_path($input_directory);
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
	return @input_files;
}
############################## autodaemon ##############################
sub autodaemon{
	my $sleeptime=defined($opt_s)?$opt_s:10;
	my $logdir=defined($opt_l)?$opt_l:"log";
	my $databases={};
	my $directory=defined($opt_d)?$opt_d:".";
	my $md5cmd=(`which md5`)?"md5":"md5sum";
	while(1){
		foreach my $file(list_files("sqlite3",$directory)){if(!exists($databases->{$file})){$databases->{$file}=0;}}
		while(my($database,$timestamp)=each(%{$databases})){
			my $basename=basename($database);
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
			if($modtime>$timestamp){
				if(-e "$logdir/$basename.lock"){next;}
				my $command="perl moirai2.pl -d $database";
				if(defined($opt_q)){$command.=" -q"}
				if(defined($opt_m)){$command.=" -m $opt_m"}
				my $time=time();
				my $datetime=getDate("",$time).getTime("",$time);
				mkdirs("$logdir/$basename");
				$command.=">$logdir/$basename/$datetime.stdout";
				$command.=" 2>$logdir/$basename/$datetime.stderr";
				$command="$md5cmd<$database>$logdir/$basename.lock;$command;$md5cmd<$database>$logdir/$basename.unlock";
				system($command);
				$databases->{$database}=$modtime;
			}
		}
		sleep($sleeptime);
	}
}
