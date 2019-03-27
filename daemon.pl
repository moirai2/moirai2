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
use vars qw($opt_c $opt_d $opt_h $opt_H $opt_m $opt_q $opt_Q $opt_r $opt_s $opt_v $opt_x);
getopts('c:d:hHm:qQ:rs:v:x');
############################## HELP ##############################
if(defined($opt_h)||defined($opt_H)||!defined($opt_d)){
	print "\n";
	print "Program: Process execute tickets stored in a RDF database.\n";
	print "Author: Akira Hasegawa (ah3q\@gsc.riken.jp)\n";
	print "\n";
	print "Usage: $program_name -d DB CMD\n";
	print "\n";
	print "         DB  SQLite3 database in RDF format.\n";
	print "        CMD  Command (default='run').\n";
	print "\n";
	print "Options: -c  Path to control directory (default='./ctrl').\n";
	print "         -d  Database file (always required).\n";
	print "         -m  Max number of jobs to throw (default='5').\n";
	print "         -q  Use qsub for throwing jobs(default='bash').\n";
	print "         -Q  Export specified bin directory when throwing with qsub(default='\$HOME/bin').\n";
	print "         -r  Run only once mode (default='loop').\n";
	print "         -s  Loop second (default='10sec').\n";
	print "         -v  Store Variables used for running in a specified path (default='none').\n";
	print "         -x  No STDERR and STDOUT logs (default='show').\n";
	print "\n";
	print "Updates: 2019/03/04  Stores run options in the SQLite database.\n";
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
	print "         2018/11/16  Making updating/importing database faster by using improved sqlite3.pl.\n";
	print "         2018/11/09  Added import function where user udpate databse through specified file(s).\n";
	print "         2018/09/14  Changed to a ticket system.\n";
	print "         2018/02/06  Added qsub functionality.\n";
	print "         2018/02/01  Created to throw jobs registered in RDF SQLite3 database.\n";
	print "\n";
	exit(0);
}
############################## MAIN ##############################
my $urls={};
$urls->{"selectUrl"}="https://moirai2.github.io/schema/daemon/select";
$urls->{"insertUrl"}="https://moirai2.github.io/schema/daemon/insert";
$urls->{"deleteUrl"}="https://moirai2.github.io/schema/daemon/delete";
$urls->{"importUrl"}="https://moirai2.github.io/schema/daemon/import";
$urls->{"inputUrl"}="https://moirai2.github.io/schema/daemon/input";
$urls->{"outputUrl"}="https://moirai2.github.io/schema/daemon/output";
$urls->{"bashUrl"}="https://moirai2.github.io/schema/daemon/bash";
$urls->{"batchUrl"}="https://moirai2.github.io/schema/daemon/batch";
$urls->{"processUrl"}="https://moirai2.github.io/schema/daemon/process";
$urls->{"scriptUrl"}="https://moirai2.github.io/schema/daemon/script";
$urls->{"scriptCodeUrl"}="https://moirai2.github.io/schema/daemon/script/code";
$urls->{"scriptNameUrl"}="https://moirai2.github.io/schema/daemon/script/name";
$urls->{"executeUrl"}="https://moirai2.github.io/schema/daemon/execute";
$urls->{"controlUrl"}="https://moirai2.github.io/schema/daemon/control";
$urls->{"commandUrl"}="https://moirai2.github.io/schema/daemon/command";
$urls->{"tmpdirUrl"}="https://moirai2.github.io/schema/daemon/tmpdir";
$urls->{"execidUrl"}="https://moirai2.github.io/schema/daemon/execid";
$urls->{"timeStartedUrl"}="https://moirai2.github.io/schema/daemon/timestarted";
$urls->{"timeEndedUrl"}="https://moirai2.github.io/schema/daemon/timeended";
$urls->{"stderrUrl"}="https://moirai2.github.io/schema/daemon/stderr";
$urls->{"stdoutUrl"}="https://moirai2.github.io/schema/daemon/stdout";
$urls->{"maxjobUrl"}="https://moirai2.github.io/schema/daemon/maxjob";
$urls->{"nologUrl"}="https://moirai2.github.io/schema/daemon/nolog";
$urls->{"singleThreadUrl"}="https://moirai2.github.io/schema/daemon/singlethread";
$urls->{"qsubOptUrl"}="https://moirai2.github.io/schema/daemon/qsubopt";
$urls->{"refreshUrl"}="https://moirai2.github.io/schema/daemon/refresh";
$urls->{"newNodeUrl"}="https://moirai2.github.io/schema/daemon/newnode";
$urls->{"mvUrl"}="https://moirai2.github.io/schema/daemon/mv";
$urls->{"rmUrl"}="https://moirai2.github.io/schema/daemon/rm";
$urls->{"rmdirUrl"}="https://moirai2.github.io/schema/daemon/rmdir";
$urls->{"rmTmpdirUrl"}="https://moirai2.github.io/schema/daemon/rmtmpdir";
$urls->{"mkdirUrl"}="https://moirai2.github.io/schema/daemon/mkdir";
$urls->{"concatUrl"}="https://moirai2.github.io/schema/daemon/concat";
$urls->{"toInsertUrl"}="https://moirai2.github.io/schema/daemon/toinsert";
$urls->{"tmpfileUrl"}="https://moirai2.github.io/schema/daemon/tmpfile";
$urls->{"newEdgeUrl"}="https://moirai2.github.io/schema/daemon/newedge";
$urls->{"scpUploadUrl"}="https://moirai2.github.io/schema/daemon/scp/upload";
$urls->{"scpProcessUrl"}="https://moirai2.github.io/schema/daemon/scp/process";
$urls->{"scpDownloadUrl"}="https://moirai2.github.io/schema/daemon/scp/download";
my $newExecuteQuery="select distinct n.data from edge as e1 inner join edge as e2 on e1.object=e2.subject inner join node as n on e2.object=n.id where e1.predicate=(select id from node where data=\"".$urls->{"executeUrl"}."\") and e2.predicate=(select id from node where data=\"".$urls->{"commandUrl"}."\")";
my $newControlQuery="select distinct n.data from edge as e inner join node as n on e.object=n.id where e.predicate=(select id from node where data=\"".$urls->{"controlUrl"}."\")";
my $refreshQuery="select distinct n.data from edge as e inner join node as n on e.object=n.id where e.predicate=(select id from node where data=\"".$urls->{"refreshUrl"}."\")";
my $cwd=Cwd::getcwd();
#setup database in absolute path
my $rdfdb=$opt_d;
if($rdfdb!~/^\//){$rdfdb="$cwd/$opt_d";}
#other options
my $sleeptime=defined($opt_s)?$opt_s:10;
my $use_qsub=$opt_q;
my $home=`echo \$HOME`;
chomp($home);
my $qsubbin=defined($opt_Q)?$opt_Q:"$home/bin";
my $nolog=$opt_x;
my $maxjob=defined($opt_m)?$opt_m:5;
my $ctrldir=Cwd::abs_path(defined($opt_c)?$opt_c:"$cwd/ctrl");
if(!$nolog){
	print STDERR "# program path   : $program_path\n";
	print STDERR "# rdf database   : $rdfdb\n";
	print STDERR "# ctrl directory : $ctrldir\n";
	if($opt_r){print STDERR "# run mode       : once\n";}
	else{print STDERR "# run mode       : normal\n";}
	print STDERR "# sleeptime      : $sleeptime sec\n";
	print STDERR "# max job        : $maxjob job".(($maxjob>1)?"s":"")."\n";
	if(defined($use_qsub)){
		print STDERR "# job submission : qsub\n";
		print STDERR "# qsub bin       : $qsubbin\n";
	}else{
		print STDERR "# job submission : bash\n";
	}
}
mkdir("tmp");
mkdir($ctrldir);
mkdir("$ctrldir/bash");
mkdir("$ctrldir/insert");
mkdir("$ctrldir/delete");
mkdir("$ctrldir/completed");
mkdir("$ctrldir/stdout");
mkdir("$ctrldir/stderr");
if(!$nolog){print STDERR "year/mon/date\thr:min:sec\tcontrol\tnewjob\tremain\tinsert\tdelete\tdone\n";}
my $commands={};
my $executes={};
my $jsons={};
my @execurls=();
my $jobcount=0;
my $ctrlcount=0;
while(true){
	my $jobs_running=getNumberOfJobsRunning();
	controlAll($rdfdb,$executes,$ctrlcount,$jobcount);
	$jobcount=0;
	$ctrlcount=0;
	refreshCommands($rdfdb,$refreshQuery,$commands);
	if(scalar(@execurls)==0&&$jobs_running==0){
		my @newurls=lookForNewCommands($rdfdb,$newControlQuery,$commands);
		foreach my $url(@newurls){
			my $job=getExecuteJobs($rdfdb,$commands->{$url},$executes);
			if($job>0){$ctrlcount+=$job;push(@execurls,$url)}
		}
		mainProcess(\@execurls,$commands,$executes,$maxjob-$jobs_running);
		my @newurls=lookForNewCommands($rdfdb,$newExecuteQuery,$commands);
		foreach my $url(@newurls){
			my $job=getExecuteJobs($rdfdb,$commands->{$url},$executes);
			if($job>0){
				$jobcount+=$job;
				my $found=0;
				foreach my $url2(@{@execurls}){if($url eq $url2){$found++;}}
				if($found==0){push(@execurls,$url);}
			}
		}
	}
	$jobs_running=getNumberOfJobsRunning();
	mainProcess(\@execurls,$commands,$executes,$maxjob-$jobs_running);
	$jobs_running=getNumberOfJobsRunning();
	if($opt_r&&scalar(@execurls)==0&&$jobs_running==0){last;}
	else{sleep($sleeptime);}
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
		my $singlethread=(exists($command->{$urls->{"singleThreadUrl"}})&&$command->{$urls->{"singleThreadUrl"}} eq "true");
		my $qsubopt=$command->{$urls->{"qsubOptUrl"}};
		my $maxjob=$command->{$urls->{"maxjobUrl"}};
		if(!defined($maxjob)){$maxjob=1;}
		my @bashFiles=();
		if(exists($command->{$urls->{"batchUrl"}})){
			my $variables=initExecute($rdfdb,$command);
			my @datas=();
			while(scalar(@{$executes->{$url}})>0){
				if(!$singlethread&&$maxjob<=0){last;}
				my $execute=shift(@{$executes->{$url}});
				my $hash={};
				while(my($key,$val)=each(%{$execute})){$hash->{"\$$key"}=$val;}
				updateExecuteTicket($command,$execute,\@deletes);
				push(@datas,$hash);
				$maxjob--;
			}
			if(exists($command->{$urls->{"newNodeUrl"}})){newNodeCommand($rdfdb,$variables,$command->{$urls->{"newNodeUrl"}});}
			batchCommand($command,$variables,\@datas);
			if(exists($variables->{"bashfile"})){push(@bashFiles,[$variables->{"cwd"}."/".$variables->{"tmpdir"}."/".$variables->{"bashfile"},$variables->{"cwd"}."/".$variables->{"tmpdir"}."/".$variables->{"stdoutfile"},$variables->{"cwd"}."/".$variables->{"tmpdir"}."/".$variables->{"stderrfile"}]);}
			$thrown++;
		}elsif(exists($command->{$urls->{"bashUrl"}})){
			while(scalar(@{$executes->{$url}})>0){
				if(!$singlethread&&$maxjob<=0){last;}
				my $variables=shift(@{$executes->{$url}});
				initExecute($rdfdb,$command,$variables);
				updateExecuteTicket($command,$variables,\@deletes);
				if(exists($command->{$urls->{"newNodeUrl"}})){newNodeCommand($rdfdb,$variables,$command->{$urls->{"newNodeUrl"}});}
				bashCommand($command,$variables);
				if(exists($variables->{"bashfile"})){push(@bashFiles,[$variables->{"cwd"}."/".$variables->{"tmpdir"}."/".$variables->{"bashfile"},$variables->{"cwd"}."/".$variables->{"tmpdir"}."/".$variables->{"stdoutfile"},$variables->{"cwd"}."/".$variables->{"tmpdir"}."/".$variables->{"stderrfile"}]);}
				$maxjob--;
				$thrown++;
			}
		}
		throwJobs(\@bashFiles,$use_qsub,$qsubopt,$url);
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
############################## refreshCommands ##############################
sub refreshCommands{
	my $rdfdb=shift();
	my $query=shift();
	my $commands=shift();
	my $dbh=openDB($rdfdb);
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $rows=$sth->fetchall_arrayref();
	$dbh->disconnect;
	my $needrefresh=0;
	foreach my $row(@{$rows}){if($row->[0] eq "true"){$needrefresh=1;last;}}
	if($needrefresh==0){return;}
	foreach my $url(keys(%{$commands})){$commands->{$url}=loadCommandFromURL($url);}
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
	my $date=getDate("/");
	my $time=getTime(":");
	my @execurls=keys(%{$executes});
	my $remaining=0;
	foreach my $url(@execurls){my $count=scalar(@{$executes->{$url}});if($count>0){$remaining++;}}
	if(!$nolog){print STDERR "$date\t$time\t$ctrlcount\t$jobcount\t$remaining\t$inserted\t$deleted\t$completed\n";}
}
############################## throwJobs ##############################
sub throwJobs{
	my $bashFiles=shift();
	my $use_qsub=shift();
	my $qsubopt=shift();
	my $url=shift();
	if(scalar(@{$bashFiles})==0){return;}
	my $cwd=Cwd::getcwd();
	my ($fh,$path)=mkstemps("$ctrldir/bash/runXXXXXXXXXX",".sh");
	my $filebsnm=basename($path,".sh");
	my $error_file="$ctrldir/stderr/$filebsnm.stderr";
	my $log_file="$ctrldir/stdout/$filebsnm.stdout";
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
		if(!$nolog){print "#Submitting $path:\t";}
		my $command="qsub";
		if(defined($qsubopt)){$command.=" $qsubopt";}
		$command.=" $path";
		if(system($command)==0){print "OK\n";}
		else{print "FAILED\n";exit(1);}
	}else{
		if(!$nolog){print "#Executing $path:\t";}
		my $command="bash";
		$command.=" $path &";
		if(system($command)==0){if(!$nolog){print "OK\n";}}
		else{if(!$nolog){print "FAILED\n";}exit(1);}
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
	my $command="cat ".join(" ",@files)."|perl sqlite3.pl -d $rdfdb -f tsv delete";
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
	my $command="cat ".join(" ",@files)."|perl sqlite3.pl -d $rdfdb -f tsv insert";
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
############################## loadCommandFromURL ##############################
sub loadCommandFromURL{
	my $url=shift();
	if(!$nolog){print "#Loading $url:\t";}
	my $command=getJson($url);
	if(scalar(keys(%{$command}))==0){print "FAILED\n";return;}
	loadCommandFromURLSub($command,$url);
	$command->{$urls->{"commandUrl"}}=$url;
	if(!$nolog){print "OK\n";}
	return $command;
}
sub loadCommandFromURLSub{
	my $command=shift();
	my $url=shift();
	$command->{"inputs"}=[];
	$command->{"outputs"}=[];
	if(exists($command->{$urls->{"selectUrl"}})){
		my @temp=parseQuery($command->{$urls->{"selectUrl"}});
		$command->{"rdfQuery"}=$temp[0];
		$command->{"inputs"}=$temp[1];
		$command->{"selectKeys"}=handleKeys($command->{$urls->{"selectUrl"}});
		if(defined($temp[2])){$command->{"execvar"}=$temp[2];}
	}
	if(exists($command->{$urls->{"outputUrl"}})){
		my $outputs=$command->{$urls->{"outputUrl"}};
		if(ref($outputs)ne"ARRAY"){
			if($outputs=~/,/){my @array=split(/,/,$outputs);$outputs=\@array;}
			else{$outputs=[$outputs];}
		}
		foreach my $output(@{$outputs}){if($output=~/^\$(.+)$/){$output=$1;}}
		$command->{"outputs"}=$outputs;
	}
	if(exists($command->{$urls->{"importUrl"}})){if(ref($command->{$urls->{"importUrl"}}) ne "ARRAY"){$command->{$urls->{"importUrl"}}=[$command->{$urls->{"importUrl"}}];}}
	if(exists($command->{$urls->{"newNodeUrl"}})){if(ref($command->{$urls->{"newNodeUrl"}}) ne "ARRAY"){$command->{$urls->{"newNodeUrl"}}=[$command->{$urls->{"newNodeUrl"}}];}}
	if(exists($command->{$urls->{"batchUrl"}})){if(ref($command->{$urls->{"batchUrl"}}) ne "ARRAY"){$command->{$urls->{"batchUrl"}}=[$command->{$urls->{"batchUrl"}}];}}
	if(exists($command->{$urls->{"insertUrl"}})){$command->{"insertKeys"}=handleKeys($command->{$urls->{"insertUrl"}},$command);}
	if(exists($command->{$urls->{"deleteUrl"}})){$command->{"deleteKeys"}=handleKeys($command->{$urls->{"deleteUrl"}},$command);}
	if(exists($command->{$urls->{"bashUrl"}})){$command->{"bashCode"}=handleCode($command->{$urls->{"bashUrl"}});}
	if(!exists($command->{$urls->{"maxjobUrl"}})){$command->{$urls->{"maxjobUrl"}}=1;}
	if(exists($command->{$urls->{"scriptUrl"}})){handleScript($command);}
}
############################## handleScript ##############################
sub handleScript{
	my $command=shift();
	my $scripts=$command->{$urls->{"scriptUrl"}};
	if(ref($scripts)ne"ARRAY"){$scripts=[$scripts];}
	foreach my $script(@{$scripts}){
		my $name=$script->{$urls->{"scriptNameUrl"}};
		my $code=$script->{$urls->{"scriptCodeUrl"}};
		if(ref($code)ne"ARRAY"){$code=[$code];}
		foreach my $c(@{$code}){$c=~s/\\t/\t/g;$c=~s/\\\\/\\\\\\\\/g;$c=~s/\$/\\\$/g;}
		$command->{$name}=$code;
		push(@{$command->{"script"}},$name);
	}
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
		if(exists($commands->{$url})){next;}
		my $command=loadCommandFromURL($url);
		if(defined($command)){$commands->{$url}=$command}
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
	my $url=$command->{$urls->{"commandUrl"}};
	my $query=$command->{"rdfQuery"};
	my $keys=$command->{"inputs"};
	my $dbh=openDB($rdfdb);
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $rows=$sth->fetchall_arrayref();
	$dbh->disconnect;
	my $count=0;
	foreach my $row(@{$rows}){
		my $variables={};
		for(my $i=0;$i<scalar(@{$row});$i++){
			my $value=$row->[$i];
			my $key=$keys->[$i];
			$variables->{$key}=$value;
		}
		push(@{$executes->{$url}},$variables);
		$count++;
	}
	return $count;
}
############################## newNodeCommand ##############################
sub newNodeCommand{
	my $dbh=shift();
	my $variables=shift();
	my $names=shift();
	if(ref($names) ne "ARRAY"){$names=[$names];}
	my $dbh=openDB($rdfdb);
	foreach my $name(@{$names}){if($name=~/^\$(.+)$/){$name=$1;}$variables->{$name}=newNode($dbh);}
	$dbh->disconnect;
}
############################## updateExecuteTicket ##############################
sub updateExecuteTicket{
	my $command=shift();
	my $variables=shift();
	my $deletes=shift();
	my $execvar="\$".$command->{"execvar"};
	foreach my $query(@{$command->{"selectKeys"}}){
		my @tokens=@{$query};
		if(scalar(@tokens)<3){next;}
		if($tokens[1] eq $urls->{"executeUrl"}&&$tokens[2] eq $execvar){
			my @outs=();
			for(my $i=0;$i<3;$i++){
				my $line=$tokens[$i];
				foreach my $key (sort{$b cmp $a} keys(%{$variables})){my $value=$variables->{$key};$line=~s/\$$key/$value/g;}
				push(@outs,$line);
			}
			push(@{$deletes},join("\t",@outs));
		}
	}
}
############################## initExecute ##############################
sub initExecute{
	my $rdfdb=shift();
	my $command=shift();
	my $variables=shift();
	if(!defined($variables)){$variables={};}
	my $url=$command->{$urls->{"commandUrl"}};
	my $cwd=Cwd::getcwd();
	$variables->{"cwd"}=$cwd;
	$variables->{"cmdurl"}=$url;
	my $filebsnm=basename($url,".json");
	$variables->{"rdfdb"}=$rdfdb;
	my $tmpdir=mkdtemp("tmp/$filebsnm.XXXXXXXXXX");
	chmod(0777,$tmpdir);
	$variables->{"tmpdir"}=$tmpdir;
	my $filebsnm=substr($tmpdir,4);
	$variables->{"bashfile"}="$filebsnm.sh";
	$variables->{"stderrfile"}="$filebsnm.stderr";
	$variables->{"stdoutfile"}="$filebsnm.stdout";
	$variables->{"insertfile"}="$filebsnm.insert";
	$variables->{"deletefile"}="$filebsnm.delete";
	$variables->{"completedfile"}="$filebsnm.completed";
	$variables->{"filebsnm"}=$filebsnm;
	if(exists($command->{"execvar"})){$variables->{"execid"}=$variables->{$command->{"execvar"}};}
	else{$variables->{"execid"}=$filebsnm;}
	$variables->{"localdb"}="$cwd/$tmpdir/$filebsnm.sqlite3";
	return $variables;
}
############################## bashCommand ##############################
sub bashCommand{
	my $command=shift();
	my $variables=shift();
	my $cwd=$variables->{"cwd"};
	my $tmpdir=$variables->{"tmpdir"};
	my $execid=$variables->{"execid"};
	my $execvar=$command->{"execvar"};
	my $url=$command->{$urls->{"commandUrl"}};
	my $bashfile="$cwd/$tmpdir/".$variables->{"bashfile"};
	my $stderrfile="$cwd/$tmpdir/".$variables->{"stderrfile"};
	my $stdoutfile="$cwd/$tmpdir/".$variables->{"stdoutfile"};
	my $insertfile="$cwd/$tmpdir/".$variables->{"insertfile"};
	my $deletefile="$cwd/$tmpdir/".$variables->{"deletefile"};
	my $completedfile="$cwd/$tmpdir/".$variables->{"completedfile"};
	my $execid=$variables->{"execid"};
	open(OUT,">$bashfile");
	print OUT "#!/bin/sh\n";
	print OUT "########## system ##########\n";
	my @systemvars=("cmdurl","rdfdb","execid","cwd","tmpdir","filebsnm");
	my @systemfiles=("bashfile","stdoutfile","stderrfile","deletefile","insertfile","completedfile");
	my @unusedvars=("localdb");
	foreach my $var(@systemvars){print OUT "$var=\"".$variables->{$var}."\"\n";}
	foreach my $var(@systemfiles){print OUT "$var=\"".$variables->{$var}."\"\n";}
	print OUT "########## variables ##########\n";
	foreach my $key(sort{$a cmp $b}keys(%{$variables})){
		my $break=0;
		foreach my $var(@systemvars){if($var eq $key){$break=1;last;}}
		foreach my $var(@systemfiles){if($var eq $key){$break=1;last;}}
		foreach my $var(@unusedvars){if($var eq $key){$break=1;last;}}
		if($key eq $execvar){$break=1;}
		if($break){next;}
		my $value=$variables->{$key};
		print OUT "$key=\"$value\"\n";
	}
	print OUT "########## initialize ##########\n";
	print OUT "cd \$cwd\n";
	my @scriptfiles=();
	foreach my $name (@{$command->{"script"}}){
		push(@scriptfiles,"$cwd/$name");
		print OUT "cat<<EOF>$name\n";
		foreach my $code(@{$command->{$name}}){print OUT "$code\n";}
		print OUT "EOF\n";
	}
	print OUT "cat<<EOF>>\$tmpdir/\$insertfile\n";
	my $inputs=$command->{"inputs"};
	my @keys=(ref($inputs)eq"ARRAY")?@{$inputs}:keys(%{$inputs});
	foreach my $key(@keys){if($key eq $execvar){next;}print OUT "\$execid\t$url#$key\t\$$key\n";}
	print OUT "\$execid\t$url#tmpdir\t\$tmpdir\n";
	print OUT "\$execid\t$url#stderrfile\t\$stderrfile\n";
	print OUT "\$execid\t$url#stdoutfile\t\$stdoutfile\n";
	print OUT "\$execid\t".$urls->{"timeStartedUrl"}."\t`date +%s`\n";
	print OUT "EOF\n";
	print OUT "########## command ##########\n";
	foreach my $line(@{$command->{"bashCode"}}){print OUT "$line\n";}
	print OUT "########## database ##########\n";
	print OUT "cat<<EOF>>\$tmpdir/\$insertfile\n";
	print OUT "\$execid\t".$urls->{"timeEndedUrl"}."\t`date +%s`\n";
	foreach my $output(@{$command->{"outputs"}}){print OUT "\$execid\t$url#$output\t\$$output\n";}
	if(scalar(@{$command->{"insertKeys"}})>0){foreach my $row(@{$command->{"insertKeys"}}){print OUT join("\t",@{$row})."\n";}}
	print OUT "EOF\n";
	if(scalar(@{$command->{"deleteKeys"}})>0){
		print OUT "cat<<EOF>>\$tmpdir/\$deletefile\n";
		foreach my $row(@{$command->{"deleteKeys"}}){print OUT join("\t",@{$row})."\n";}
		print OUT "EOF\n";
	}
	print OUT "if [ -s \$tmpdir/\$stdoutfile ];then\n";
	print OUT "echo \"\$execid\t".$urls->{"stdoutUrl"}."\t\$tmpdir/\$stdoutfile\">>\$tmpdir/\$insertfile\n";
	print OUT "fi\n";
	print OUT "if [ -s \$tmpdir/\$stderrfile ];then\n";
	print OUT "echo \"\$execid\t".$urls->{"stderrUrl"}."\t\$tmpdir/\$stderrfile\">>\$tmpdir/\$insertfile\n";
	print OUT "fi\n";
	print OUT "########## completed ##########\n";
	my $importcount=0;
	foreach my $importfile(@{$command->{$urls->{"importUrl"}}}){print OUT "mv \$cwd/$importfile $ctrldir/insert/$execid.import\n";$importcount++;}
	print OUT "mv \$cwd/\$tmpdir/\$completedfile $ctrldir/completed/\$filebsnm.sh\n";
	close(OUT);
	writeCompleteFile($completedfile,$stdoutfile,$stderrfile,$insertfile,$deletefile,$bashfile,\@scriptfiles,$tmpdir,$cwd);
}
############################## batchCommand ##############################
#batchCommand(\%command,\%variables,\@datas);
sub batchCommand{
	my $command=shift();
	my $variables=shift();
	my $datas=shift();
	my $cwd=$variables->{"cwd"};
	my $execid=$variables->{"execid"};
	my $tmpdir=$variables->{"tmpdir"};
	my $localdb=$variables->{"localdb"};
	my $url=$command->{$urls->{"commandUrl"}};
	my $bashfile="$cwd/$tmpdir/".$variables->{"bashfile"};
	my $insertfile="$cwd/$tmpdir/".$variables->{"insertfile"};
	my $deletefile="$cwd/$tmpdir/".$variables->{"deletefile"};
	my $completedfile="$cwd/$tmpdir/".$variables->{"completedfile"};
	my $stdoutfile="$cwd/$tmpdir/".$variables->{"stdoutfile"};
	my $stderrfile="$cwd/$tmpdir/".$variables->{"stderrfile"};
	open(OUT,">$bashfile");
	print OUT "#!/bin/sh\n";
	print OUT "########## system ##########\n";
	my @systemvars=("cmdurl","rdfdb","execid","cwd","tmpdir","filebsnm");
	my @systemfiles=("bashfile","stdoutfile","stderrfile","completedfile","localdb");
	my @unusedvars=();
	if(exists($command->{$urls->{"insertUrl"}})||existsProcess($command,$urls->{"toInsertUrl"})){push(@systemfiles,"insertfile");}
	else{push(@unusedvars,"insertfile");}
	if(exists($command->{$urls->{"deleteUrl"}})){push(@systemfiles,"deletefile");}
	else{push(@unusedvars,"deletefile");}
	foreach my $var(@systemvars){print OUT "$var=\"".$variables->{$var}."\"\n";}
	foreach my $var(@systemfiles){print OUT "$var=\"".$variables->{$var}."\"\n";}
	print OUT "########## initialize ##########\n";
	print OUT "cd \$cwd\n";
	my @scriptfiles=();
	foreach my $name (@{$command->{"script"}}){
		push(@scriptfiles,"$cwd/$name");
		print OUT "cat<<EOF>$name\n";
		foreach my $code(@{$command->{$name}}){print OUT "$code\n";}
		print OUT "EOF\n";
	}
	print OUT "cat<<EOF|perl $cwd/sqlite3.pl -qd \$localdb -f tsv import\n";
	printRowsWithData($datas,$command->{"selectKeys"});
	print OUT "\$execid\t".$urls->{"timeStartedUrl"}."\t`date +%s`\n";
	print OUT "EOF\n";
	if(exists($command->{$urls->{"tmpfileUrl"}})){
		my $value=$command->{$urls->{"tmpfileUrl"}};
		print OUT "########## tmpfile ##########\n";
		my @array=(ref($value)eq"ARRAY")?@{$value}:($value);
		foreach my $val(@array){
			my $name=substr($val,1);
			print OUT "$name=\$(mktemp $tmpdir/XXXXXXXXXX)\n";
			print OUT "chmod 777 $val\n";
			for(my $i=0;$i<scalar(@{$datas});$i++){$datas->[$i]->{$val}=$val;}
		}
	}
	print OUT "########## batch ##########\n";
	my $currentCommandUrl;
	foreach my $batch(@{$command->{$urls->{"batchUrl"}}}){
		while(my ($key,$value)=each(%{$batch})){
			if($key eq $urls->{"newNodeUrl"}){
				my @array=(ref($value)eq"ARRAY")?@{$value}:($value);
				foreach my $val(@array){
					my $name=substr($val,1);
					for(my $i=0;$i<scalar(@{$datas});$i++){
						print OUT "$name$i=`perl $cwd/sqlite3.pl -d \$localdb newnode`\n";
						$datas->[$i]->{"\$$name"}="\$$name$i";
					}
				}
			}elsif($key eq $urls->{"processUrl"}){
				print OUT "cat<<EOF|perl $cwd/sqlite3.pl -qd \$localdb -f tsv import\n";
				my $keys=handleKeys($value);
				$currentCommandUrl=getCurrentCommandUrl($keys);
				printRowsWithData($datas,$keys);
				print OUT "EOF\n";
				print OUT "perl $cwd/daemon.pl -xrm 1 -d \$localdb -c \$tmpdir/ctrl\n";
			}elsif($key eq $urls->{"insertUrl"}){
				my ($query,$format)=constructQueryAndFormat($currentCommandUrl,$value);
				print OUT "perl \$cwd/sqlite3.pl -qd \$localdb -f '$format' query $query|perl $cwd/sqlite3.pl -qd \$localdb -f tsv insert\n";
			}elsif($key eq $urls->{"deleteUrl"}){
				my ($query,$format)=constructQueryAndFormat($currentCommandUrl,$value);
				print OUT "perl \$cwd/sqlite3.pl -qd \$localdb -f '$format' query $query|perl $cwd/sqlite3.pl -qd \$localdb -f tsv delete\n";
			}elsif($key eq $urls->{"mkdirUrl"}){
				my ($template,$keys)=constructMkdirTemplate($value);
				my ($query,$format)=constructQueryAndFormat($currentCommandUrl,$template,$keys);
				if(scalar(@{$keys})==0){print OUT "$format\n";}
				else{print OUT "perl \$cwd/sqlite3.pl -qd \$localdb -f '$format' query $query|bash\n";}
			}elsif($key eq $urls->{"tmpfileUrl"}){
				my @array=(ref($value)eq"ARRAY")?@{$value}:($value);
				foreach my $val(@array){
					my $name=substr($val,1);
					for(my $i=0;$i<scalar(@{$datas});$i++){
						print OUT "$name$i=\$(mktemp $tmpdir/XXXXXXXXXX)\n";
						print OUT "chmod 777 $name$i\n";
						$datas->[$i]->{"\$$name"}="\$$name$i";
					}
				}
			}elsif($key eq $urls->{"concatUrl"}){
				my ($template,$keys)=constructConcatTemplate($value);
				my ($query,$format)=constructQueryAndFormat($currentCommandUrl,$template,$keys);
				if(scalar(@{$keys})==0){print OUT "$format\n";}
				else{print OUT "perl \$cwd/sqlite3.pl -qd \$localdb -f '$format' query $query|bash\n";}
			}elsif($key eq $urls->{"toInsertUrl"}){
				my ($template,$keys)=constructToInsertTemplate($value);
				my ($query,$format)=constructQueryAndFormat($currentCommandUrl,$template,$keys);
				if(scalar(@{$keys})==0){print OUT "$format\n";}
				else{print OUT "perl \$cwd/sqlite3.pl -qd \$localdb -f '$format' query $query|bash>>\$tmpdir/\$insertfile\n";}
			}elsif($key eq $urls->{"mvUrl"}){
				my ($template,$keys)=constructMvTemplate($value);
				my ($query,$format)=constructQueryAndFormat($currentCommandUrl,$template,$keys);
				if(scalar(@{$keys})==0){print OUT "$format\n";}
				else{print OUT "perl \$cwd/sqlite3.pl -qd \$localdb -f '$format' query $query|perl $cwd/sqlite3.pl -qd \$localdb -f tsv rename\n";}
			}elsif($key eq $urls->{"importUrl"}){
				my ($template,$keys)=constructImportTemplate($value);
				my ($query,$format)=constructQueryAndFormat($currentCommandUrl,$template,$keys);
				if(scalar(@{$keys})==0){print OUT "$format\n";}
				else{print OUT "perl \$cwd/sqlite3.pl -qd \$localdb -f '$format' query $query|bash\n";}
			}elsif($key eq $urls->{"rmdirUrl"}){
				my ($template,$keys)=constructRmdirTemplate($value);
				my ($query,$format)=constructQueryAndFormat($currentCommandUrl,$template,$keys);
				if(scalar(@{$keys})==0){print OUT "$format\n";}
				else{print OUT "perl \$cwd/sqlite3.pl -qd \$localdb -f '$format' query $query|bash\n";}
			}elsif($key eq $urls->{"rmUrl"}){
				my ($template,$keys)=constructRmTemplate($value);
				my ($query,$format)=constructQueryAndFormat($currentCommandUrl,$template,$keys);
				if(scalar(@{$keys})==0){print OUT "$format\n";}
				else{print OUT "perl \$cwd/sqlite3.pl -qd \$localdb -f '$format' query $query|bash\n";}
			}elsif($key eq $urls->{"scpUploadUrl"}){
			}elsif($key eq $urls->{"scpDownloadUrl"}){
			}elsif($key eq $urls->{"scpProcessUrl"}){
			}
		}
	}
	print OUT "perl \$cwd/sqlite3.pl -qd \$localdb -f 'rmdir \$tmpdir > /dev/null 2>&1' query '\$nodeid->$currentCommandUrl#tmpdir->\$tmpdir'|bash\n";
	print OUT "########## database ##########\n";
	print OUT "cat<<EOF|perl $cwd/sqlite3.pl -qd \$localdb -f tsv import\n";
	print OUT "\$execid\t".$urls->{"timeEndedUrl"}."\t`date +%s`\n";
	print OUT "EOF\n";
	if(scalar(@{$command->{"insertKeys"}})>0){
		my @queries=();
		foreach my $row(@{$command->{"insertKeys"}}){
			if(scalar(@{$row})!=3){next;}
			push(@queries,"'".join("->",@{$row})."'");
		}
		print OUT "perl \$cwd/sqlite3.pl -qd \$localdb query ".join(" ",@queries).">>\$tmpdir/\$insertfile\n";
	}
	if(scalar(@{$command->{"deleteKeys"}})>0){
		my @queries=();
		foreach my $row(@{$command->{"deleteKeys"}}){
			if(scalar(@{$row})!=3){next;}
			push(@queries,"'".join("->",@{$row})."'");
		}
		print OUT "perl \$cwd/sqlite3.pl -qd \$localdb query ".join(",",@queries).">>\$tmpdir/\$deletefile\n";
	}
	print OUT "if [ -s \$tmpdir/\$stdoutfile ];then\n";
	print OUT "cat<<EOF|perl $cwd/sqlite3.pl -qd \$localdb -f tsv import\n";
	print OUT "\$execid\t".$urls->{"stdoutUrl"}."\t\$tmpdir/\$stdoutfile\n";
	print OUT "EOF\n";
	print OUT "fi\n";
	print OUT "if [ -s \$tmpdir/\$stderrfile ];then\n";
	print OUT "cat<<EOF|perl $cwd/sqlite3.pl -qd \$localdb -f tsv import\n";
	print OUT "\$execid\t".$urls->{"stderrUrl"}."\t\$tmpdir/\$stderrfile\n";
	print OUT "EOF\n";
	print OUT "fi\n";
	print OUT "########## completed ##########\n";
	my $importcount=0;
	foreach my $importfile(@{$command->{$urls->{"importUrl"}}}){print OUT "mv \$cwd/$importfile $ctrldir/insert/$execid.import\n";$importcount++;}
	print OUT "mv \$cwd/\$tmpdir/\$completedfile $ctrldir/completed/\$filebsnm.sh\n";
	close(OUT);
	writeCompleteFile($completedfile,$stdoutfile,$stderrfile,$insertfile,$deletefile,$bashfile,\@scriptfiles,$tmpdir,$cwd,$localdb);
}
############################## existsProcess ##############################
#existsProcess(\%command,$url);
sub existsProcess{
	my $command=shift();
	my $url=shift();
	if(!exists($command->{$urls->{"batchUrl"}})){return 0;}
	foreach my $process(@{$command->{$urls->{"batchUrl"}}}){if(exists($process->{$url})){return 1;}}
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
		if($row->[1] eq $urls->{"commandUrl"}){return $row->[2];}
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
	print OUT "if [ \$keep = 0 ];then\n";
	print OUT "rm -f $bashfile\n";
	foreach my $scriptfile(@{$scriptfiles}){print OUT "rm -f $scriptfile\n";}
	print OUT "fi\n";
	print OUT "rmdir $tmpdir/ctrl/bash > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/completed > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/delete > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/insert > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/stderr > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/stdout > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ctrl/ > /dev/null 2>&1\n";
	print OUT "rmdir $tmpdir/ > /dev/null 2>&1\n";
	close(OUT);
}
############################## replaceWithVariables ##############################
sub replaceWithVariables{
	my @lines=@_;
	my $variables=shift(@lines);
	foreach my $line(@lines){
		foreach my $key(keys(%{$variables})){
			my $value=$variables->{$key};
			$key="\\\$$key";
			$line=~s/$key/$value/g;
		}
	}
	return @lines;
}
############################## handleKeys ##############################
sub handleKeys{
	my $statement=shift();
	my $command=shift();
	my @array=();
	my @statements;
	if(ref($statement) eq "ARRAY"){@statements=@{$statement};}
	else{@statements=split(",",$statement);}
	foreach my $line (@statements){
		my @tokens=split(/->/,$line);
		push(@array,\@tokens);
		foreach my $token(@tokens){
			if($token=~/^\$(\w+)$/){
				my $key=$1;
				my $found=0;
				foreach my $input(@{$command->{"inputs"}}){if($key eq $input){$found=1;}}
				if($found==0){push(@{$command->{"outputs"}},$key);}
			}
		}
	}
	return \@array;
}
############################## parseQuery ##############################
sub parseQuery{
	my $statement=shift();
	my @statements=(ref($statement)ne"ARRAY")?($statement):@{$statement};
	my @edges=();
	my $execvar;
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
		if($nodes[1] eq $urls->{"executeUrl"}){$execvar=substr($nodes[2],1);}
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
	return ($query,\@varnames,$execvar);
}
############################## getConfigJson ##############################
sub getConfigJson{
	my $url=shift();
	my $json=getJson($url);
	my $variables={};
	while(my ($key,$value)=each(%{$json})){
		if(ref($value)eq"ARRAY"){next;}
		if($value!~/\-\>/){$variables->{$key}=$value;}
	}
	while(my ($key,$value)=each(%{$json})){
		if(exists($variables->{$key})){next;}
		if(ref($value)eq"ARRAY"){foreach my $line(@{$value}){while(my ($k,$v)=each(%{$variables})){$line=~s/\$$k/$v/g;}}}
		else{while(my ($k,$v)=each(%{$variables})){$value=~s/\$$k/$v/g;}}
		$json->{$key}=$value;
	}
	return $json;
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
	while(<IN>){
		chomp;s/\r//g;
		$content.=$_;
	}
	close(IN);
	return $content;
}
############################## updateRDF ##############################
sub updateRDF{
	my $dbh=shift();
	my $json=shift();
	foreach my $subject(keys(%{$json})){
		my $subject_id=handleNode($dbh,$subject);
		foreach my $predicate(sort{$a cmp $b} keys(%{$json->{$subject}})){
			my $predicate_id=handleNode($dbh,$predicate);
			my $object=$json->{$subject}->{$predicate};
			if(ref($object)eq"ARRAY"){
				foreach my $o(@{$object}){
					my $object_id=handleNode($dbh,$o);
					updateEdge($dbh,$subject_id,$predicate_id,$object_id);
				}
			}elsif(ref($object)eq"HASH"){
				foreach my $o(keys(%{$object})){
					my $object_id=handleNode($dbh,$o);
					updateEdge($dbh,$subject_id,$predicate_id,$object_id);
				}
			}else{
				my $object_id=handleNode($dbh,$object);
				updateEdge($dbh,$subject_id,$predicate_id,$object_id);
			}
		}
	}
}
############################## insertRDF ##############################
sub insertRDF{
	my $dbh=shift();
	my $json=shift();
	foreach my $subject(keys(%{$json})){
		my $subject_id=handleNode($dbh,$subject);
		foreach my $predicate(sort{$a cmp $b} keys(%{$json->{$subject}})){
			my $predicate_id=handleNode($dbh,$predicate);
			my $object=$json->{$subject}->{$predicate};
			if(ref($object)eq"ARRAY"){
				foreach my $o(@{$object}){
					my $object_id=handleNode($dbh,$o);
					insertEdge($dbh,$subject_id,$predicate_id,$object_id);
				}
			}elsif(ref($object)eq"HASH"){
				foreach my $o(keys(%{$object})){
					my $object_id=handleNode($dbh,$o);
					insertEdge($dbh,$subject_id,$predicate_id,$object_id);
				}
			}else{
				my $object_id=handleNode($dbh,$object);
				insertEdge($dbh,$subject_id,$predicate_id,$object_id);
			}
		}
	}
}
############################## deleteRDF ##############################
sub deleteRDF{
	my $dbh=shift();
	my $json=shift();
	if(ref($json)eq"HASH"){}#hash
	elsif(ref($json)eq"ARRAY"){foreach my $j(@{$json}){updateRDF($j);}return;}#array
	else{$json=parseRDF($json);}#string
	foreach my $subject(keys(%{$json})){
		my $subject_id=handleNode($dbh,$subject);
		foreach my $predicate(sort{$a cmp $b} keys(%{$json->{$subject}})){
			my $predicate_id=handleNode($dbh,$predicate);
			my $object=$json->{$subject}->{$predicate};
			if(ref($object)eq"ARRAY"){
				foreach my $o(@{$object}){
					my $object_id=handleNode($dbh,$o);
					deleteEdge($dbh,$subject_id,$predicate_id,$object_id);
				}
			}elsif(ref($object)eq"HASH"){
				foreach my $o(keys(%{$object})){
					my $object_id=handleNode($dbh,$o);
					deleteEdge($dbh,$subject_id,$predicate_id,$object_id);
					deleteRDF($dbh,$object);
				}
			}else{
				my $object_id=handleNode($dbh,$object);
				deleteEdge($dbh,$subject_id,$predicate_id,$object_id);
			}
		}
	}
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
############################## RDF SQLITE3 DATABASE ##############################
sub openDB{
	my $db=shift();
	my $dbh=DBI->connect("dbi:SQLite:dbname=$db");
	$dbh->do("CREATE TABLE IF NOT EXISTS node(id INTEGER PRIMARY KEY,data TEXT)");
	$dbh->do("CREATE TABLE IF NOT EXISTS edge(subject INTEGER,predicate INTEGER,object INTEGER,PRIMARY KEY (subject,predicate,object))");
	chmod(0777,$db);
	return $dbh;
}
sub nodeSize{
	my $dbh=shift();
	my $sth=$dbh->prepare("SELECT count(*) FROM `node`");
	$sth->execute();
	my @row=$sth->fetchrow_array();
	return $row[0];
}
sub data2id{
	my $dbh=shift();
	my $data=shift();
	my $sth=$dbh->prepare("SELECT id FROM node WHERE data=?");
	$sth->execute($data);
	my @row=$sth->fetchrow_array();
	return $row[0];
}
sub id2data{
	my $dbh=shift();
	my $data=shift();
	my $sth=$dbh->prepare("SELECT data FROM node WHERE id=?");
	$sth->execute($data);
	my @row=$sth->fetchrow_array();
	return $row[0];
}
sub handleNode{
	my $dbh=shift();
	my $data=shift();
	my $id=data2id($dbh,$data);
	if($id!=""){return $id;}
	return insertNode($dbh,$data);
}
sub insertNode{
	my $dbh=shift();
	my $data=shift();
	my $size=nodeSize($dbh);
	my $sth=$dbh->prepare("INSERT OR IGNORE INTO `node` (`id`,`data`) VALUES (?,?)");
	$sth->execute($size+1,$data);
	return $size+1;
}
sub newNode{
	my $dbh=shift();
	my $id=nodeMax($dbh)+1;
	my $name="_node$id"."_";
	my $sth=$dbh->prepare("INSERT OR IGNORE INTO node(id,data) VALUES(?,?)");
	$sth->execute($id,$name);
	return $name;
}
sub nodeMax{
	my $dbh=shift();
	my $sth=$dbh->prepare("SELECT max(id) FROM node");
	$sth->execute();
	my @row=$sth->fetchrow_array();
	return $row[0];
}
sub insertEdge{
	my $dbh=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $sth=$dbh->prepare("INSERT OR IGNORE INTO `edge` (`subject`,`predicate`,`object`) VALUES (?,?,?)");
	$sth->execute($subject,$predicate,$object);
}
sub updateEdge{
	my $dbh=shift();
	my $subject_id=shift();
	my $predicate_id=shift();
	my $object_id=shift();
	my $sth=$dbh->prepare("UPDATE `edge` SET `object`=? where `subject`=? AND `predicate`=?");
	$sth->execute($object_id,$subject_id,$predicate_id);
	$sth=$dbh->prepare("INSERT OR IGNORE INTO `edge` VALUES (?,?,?)");
	$sth->execute($subject_id,$predicate_id,$object_id);
}
sub deleteEdge{
	my $dbh=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $sth=$dbh->prepare("DELETE FROM `edge` WHERE `subject`=? AND `predicate`=? AND `object`=?");
	$sth->execute($subject,$predicate,$object);
}
############################## HTTP ##############################
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
