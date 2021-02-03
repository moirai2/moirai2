#!/usr/bin/perl
use strict 'vars';
use Cwd;
use File::Basename;
use File::Which;
use File::Temp qw/tempfile tempdir/;
use FileHandle;
use Getopt::Std;
use File::Path;
use LWP::UserAgent;
use HTTP::Request::Common;
use Time::HiRes;
use Time::Local;
use Time::localtime;
use Time::Piece;
############################## HEADER ##############################
my($program_name,$program_directory,$program_suffix)=fileparse($0);
$program_directory=substr($program_directory,0,-1);
############################## OPTIONS ##############################
use vars qw($opt_d $opt_f $opt_g $opt_G $opt_h $opt_q $opt_r);
getopts('d:f:g:G:hqr:');
############################## URLs ##############################
my $urls={};
$urls->{"daemon/command"}="https://moirai2.github.io/schema/daemon/command";
$urls->{"daemon/execute"}="https://moirai2.github.io/schema/daemon/execute";
$urls->{"daemon/timeended"}="https://moirai2.github.io/schema/daemon/timeended";
$urls->{"daemon/timestarted"}="https://moirai2.github.io/schema/daemon/timestarted";
$urls->{"daemon/timethrown"}="https://moirai2.github.io/schema/daemon/timethrown";
############################## HELP ##############################
sub help{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Utilities for handling a RDF sqlite3 database.\n";
	print "Version: 2020/12/03\n";
	print "Author: Akira Hasegawa (akira.hasegawa\@riken.jp)\n";
	print "\n";
	print "Usage: perl $program_name [Options] COMMAND\n";
	print "\n";
	print "Commands:    delete  Delete triple(s)\n";
	print "             import  Import triple(s)\n";
	print "             insert  Insert triple(s)\n";
	print "              query  Query with my original format (example: \$a->B->\$c)\n";
	print "             select  Select triple(s)\n";
	print "             update  Update triple(s)\n";
	print "\n";
	print "Commands used by moirai2.pl:\n";
	print "             export  export database content to moirai2.pl HTML\n";
	print "           commands  Return commands to be executed\n";
	print "           filesize  Record file size of a file\n";
	print "          filestats  Record filesize/linecount/seqcount/md5 of a file\n";
	print "               jobs  Return jobs to be executed\n";
	print "          linecount  Line count of a file\n";
	print "                log  Record log information\n";
	print "                md5  Record md5 of a file\n";
	print "             return  Return result(s) from logs\n";
	print "           seqcount  Record sequence count of a file\n";
	print "             submit  Record new job submission\n";
	print "               test  For development purpose\n";
	print "          appendlog  Append stderr/stdout/bash/script information to log file\n";
	print "\n";
}
sub help_import{
	print "PROGRAM: $program_name\n";
	print "  USAGE: Utilities for handling a RDF sqlite3 database.\n";
	print "COMMAND: $program_name -d DB COMMAND\n";
	print "\n";
	print "Options:\n";
	print "     -d  database directory path (default='rdf')\n";
	print "     -f  input/output format (json,tsv)\n";
	print "     -h  show help message\n";
	print "     -q  quiet mode\n";
	print "\n";
	print "   NOTE:  Use '%' for undefined subject/predicate/object.\n";
	print "          '%' is wildcard for subject/predicate/object.\n";
	print "          Need to specify database for most manipulations.\n";
	print "          When DB text file is gzipped/bzipped, DB can't be updated.\n";
	print "          Update = insertion / update / deletion\n";
	print "\n";
	print "UPDATED: 2021/01/31  Now can access RDF database through web\n";
	print "         2021/01/07  Predicate of query can have variable\n";
	print "         2020/11/27  Shift system to a database directory structure\n";
	print "\n";
}
############################## MAIN ##############################
if(defined($opt_h)||scalar(@ARGV)==0){help();exit();}
my $command=shift(@ARGV);
if($command eq"test"){test();}
my $moiraiDir=(defined($opt_d))?$opt_d:"moirai";
my $dbDir="$moiraiDir/db";
my $logDir="$moiraiDir/log";
my $errorDir="$logDir/error";
mkdir($moiraiDir);chmod(0777,$moiraiDir);
mkdir($dbDir);chmod(0777,$dbDir);
mkdir($logDir);chmod(0777,$logDir);
mkdir($errorDir);chmod(0777,$errorDir);
my $md5cmd=which('md5sum');
if(!defined($md5cmd)){$md5cmd=which('md5');}
if($command eq"appendlog"){commandAppendLog(@ARGV);}
elsif($command eq"commands"){commandCommands(@ARGV);}
elsif($command eq"delete"){commandDelete(@ARGV);}
elsif($command eq"executes"){commandExecutes(@ARGV);}
elsif($command eq"export"){commandExport(@ARGV);}
elsif($command eq"filesize"){commandFilesize(@ARGV);}
elsif($command eq"filestats"){commandFileStats(@ARGV);}
elsif($command eq"import"){commandImport(@ARGV);}
elsif($command eq"insert"){commandInsert(@ARGV);}
elsif($command eq"linecount"){commandLinecount(@ARGV);}
elsif($command eq"log"){commandLog(@ARGV);}
elsif($command eq"md5"){commandMd5(@ARGV);}
elsif($command eq"query"){commandQuery(@ARGV);}
elsif($command eq"return"){commandReturn(@ARGV);}
elsif($command eq"select"){commandSelect(@ARGV);}
elsif($command eq"seqcount"){commandSeqcount(@ARGV);}
elsif($command eq"submit"){commandSubmit(@ARGV);}
elsif($command eq"update"){commandUpdate(@ARGV);}
############################## commandExport ##############################
sub commandExport{
	my $target=shift();
	if(!defined($target)){$target="db";}
	my $result;
	if($target eq "db"){$result=loadDbToArray($dbDir);}
	elsif($target eq "log"){$result=loadLogToHash($logDir);}
	elsif($target eq "network"){$result=loadDbToVisNetwork($dbDir);}
	print jsonEncode($result)."\n";
}
############################## commandAppendLog ##############################
sub commandAppendLog{
	my $id=shift();
	my $file=getFileFromExecid($id);
	if($file=~/\.gz$/){return;}
	elsif($file=~/\.bz2$/){return;}
	if(!-e $file){return;}
	open(OUT,">>$file");
	while(<STDIN>){print OUT;}
	close(OUT);
}
############################## commandCommands ##############################
sub commandCommands{
	my $logs=loadLogs();
	my @urls=();
	foreach my $id(keys(%{$logs})){
		if($logs->{$id}->{$urls->{"daemon/execute"}}ne"registered"){next;}
		if(exists($logs->{$id}->{$urls->{"daemon/command"}})){push(@urls,$logs->{$id}->{$urls->{"daemon/command"}});}
	}
	if(!defined($opt_f)){$opt_f="tsv";}
	if($opt_f eq "json"){print "[\"".join("\",\"",@urls)."\"]\n";}
	else{foreach my $url(@urls){print "$url\n";}}
}
############################## commandDelete ##############################
sub commandDelete{
	my $total=0;
	if(scalar(@ARGV)>0){
		$total=deleteArgv(@ARGV);
	}else{
		if(!defined($opt_f)){$opt_f="tsv";}
		my $reader=IO::File->new("-");
		my $json=($opt_f eq "tsv")?tsvToJson($reader):readJson($reader);
		close($reader);
		$total=deleteJson($json);
	}
	if($total>0){utime(undef,undef,$moiraiDir);utime(undef,undef,$dbDir);}
	if(!defined($opt_q)){print "deleted $total\n";}
}
sub deleteArgv{
	my @arguments=@_;
	my $subject=shift(@arguments);
	my $predicate=shift(@arguments);
	my $object=shift(@arguments);
	if(!defined($subject)){$subject="%";}
	if(!defined($predicate)){$predicate="%";}
	if(!defined($object)){$object="%";}
	$subject=~s/\%/.*/g;
	$predicate=~s/\%/.*/g;
	$object=~s/\%/.*/g;
	my @files=listFiles(undef,undef,-1,$dbDir);
	my @files=narrowDownByPredicate($predicate,@files);
	my $total=0;
	foreach my $file(@files){
		if($file=~/\.gz$/){next;}
		elsif($file=~/\.bz2$/){next;}
		if(!-e $file){next;}
		my $deleted=0;
		my $count=0;
		my $p=getPredicateFromFile($file);
		my $reader=openFile($file);
		my ($writer,$tempfile)=tempfile();
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if($s=~/^$subject$/ && $o=~/^$object$/){$deleted++;}
			else{print $writer "$s\t$o\n";$count++;}
		}
		close($writer);
		chmod(0777,$tempfile);
		close($reader);
		if($count==0){unlink($file);}
		elsif($deleted>0){system("mv $tempfile $file");}
		$total+=$deleted;
	}
	return $total;
}
sub deleteJson{
	my $json=shift();
	my $total=0;
	my @predicates=getPredicatesFromJson($json);
	foreach my $predicate(@predicates){
		my $deleted=0;
		my $count=0;
		my $file=getFileFromPredicate($predicate);
		if($file=~/\.gz$/){next;}
		elsif($file=~/\.bz2$/){next;}
		if(!-e $file){next;}
		my $reader=openFile($file);
		my ($writer,$tempfile)=tempfile();
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if(exists($json->{$s})&&$json->{$s}->{$predicate} eq $o){$deleted++;}
			else{print $writer "$s\t$o\n";$count++;}
		}
		close($writer);
		chmod(0777,$tempfile);
		close($reader);
		if($count==0){unlink($file);}
		elsif($deleted>0){system("mv $tempfile $file");}
		$total+=$deleted;
	}
	return $total;
}
############################## commandExecutes ##############################
sub commandExecutes{
	my @ids=@ARGV;
	my $url=shift(@ids);
	my $logs=loadLogs();
	my $hash={};
	foreach my $id(@ids){$hash->{$id}=1;}
	my $executes={};
	foreach my $id(keys(%{$logs})){
		if(exists($hash->{$id})){next;}
		if($logs->{$id}->{$urls->{"daemon/execute"}}ne"registered"){next;}
		if($logs->{$id}->{$urls->{"daemon/command"}}ne $url){next;}
		if(!exists($executes->{$id})){$executes->{$id}={};}
		while(my ($key,$val)=each(%{$logs->{$id}})){
			if($key eq $urls->{"daemon/execute"}){next;}
			if($key eq $urls->{"daemon/command"}){next;}
			if($key=~/^$url#(.+)$/){
				$key=$1;
				if(!exists($executes->{$id}->{$key})){$executes->{$id}->{$key}=$val;}
				elsif(ref($executes->{$id}->{$key})eq"ARRAY"){push(@{$executes->{$id}->{$key}},$val);}
				else{$executes->{$id}->{$key}=[$executes->{$id}->{$key},$val]}
			}
		}
	}
	print jsonEncode($executes)."\n";
}
############################## commandFileStats ##############################
sub commandFileStats{
	my @arguments=@_;
	my @files=();
	if(scalar(@arguments)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@arguments;}
	my $writer=IO::File->new(">&STDOUT");
	fileStats($writer,$opt_g,$opt_G,$opt_r,@files);
	close($writer);
}
############################## commandFilesize ##############################
sub commandFilesize{
	my @arguments=@_;
	my @files=();
	if(scalar(@arguments)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@arguments;}
	my $writer=IO::File->new(">&STDOUT");
	sizeFiles($writer,$opt_g,$opt_G,$opt_r,@files);
	close($writer);
}
############################## commandImport ##############################
sub commandImport{
	my @arguments=@_;
	my $writers={};
	my $excess={};
	my $files={};
	my $total=0;
	my $limit=`ulimit -n`;
	chomp($limit);
	while(<STDIN>){
		chomp;
		my ($s,$p,$o)=split(/\t/);
		if(!defined($p)){next;}
		if(!defined($o)){next;}
		if(!exists($writers->{$p})&&!exists($excess->{$p})){
			my $file=getFileFromPredicate($p);
			if($file=~/\.gz$/){$writers->{$p}=undef;}
			elsif($file=~/\.bz2$/){$writers->{$p}=undef;}
			elsif(keys(%{$writers})<$limit-2){
				my ($writer,$tempfile)=tempfile(UNLINK=>1);
				if(-e $file){
					my $reader=openFile($file);
					while(<$reader>){chomp;print $writer "$_\n";}
					close($reader);
				}else{mkdirs(dirname($file));}
				$writers->{$p}=$writer;
				$files->{$file}=$tempfile;
			}else{
				$excess->{$p}=[];
			}
		}
		if(exists($excess->{$p})){
			push(@{$excess->{$p}},"$s\t$o");
			next;
		}
		my $writer=$writers->{$p};
		if(!defined($writer)){next;}
		print $writer "$s\t$o\n";
		$total++;
	}
	while(my($p,$writer)=each(%{$writers})){close($writer);}
	while(my($p,$array)=each(%{$excess})){
		my $file=getFileFromPredicate($p);
		if($file=~/\.gz$/){next;}
		elsif($file=~/\.bz2$/){next;}
		my ($writer,$tempfile)=tempfile(UNLINK=>1);
		if(-e $file){
			my $reader=openFile($file);
			while(<$reader>){chomp;print $writer "$_\n";}
			close($reader);
		}else{mkdirs(dirname($file));}
		foreach my $line(@{$array}){print $writer "$line\n";$total++;}
		close($writer);
		$files->{$file}=$tempfile;
	}
	while(my($file,$tempfile)=each(%{$files})){
		my ($writer2,$tempfile2)=tempfile();
		close($writer2);
		chmod(0777,$tempfile2);
		system("sort $tempfile -u > $tempfile2");
		system("mv $tempfile2 $file");
	}
	if($total>0){utime(undef,undef,$moiraiDir);utime(undef,undef,$dbDir);}
	if(!defined($opt_q)){print "inserted $total\n";}
}
############################## commandInsert ##############################
sub commandInsert{
	my $total=0;
	if(scalar(@ARGV)>0){
		my $json={$ARGV[0]=>{$ARGV[1]=>$ARGV[2]}};
		$total=insertJson($json);
	}else{
		if(!defined($opt_f)){$opt_f="tsv";}
		my $reader=IO::File->new("-");
		my $json=($opt_f eq "tsv")?tsvToJson($reader):readJson($reader);
		close($reader);
		$total=insertJson($json);
	}
	if($total>0){utime(undef,undef,$moiraiDir);utime(undef,undef,$dbDir);}
	if(!defined($opt_q)){print "inserted $total\n";}
}
sub insertJson{
	my $json=shift();
	my $total=0;
	my @predicates=getPredicatesFromJson($json);
	foreach my $predicate(@predicates){
		my $inserted=0;
		my $count=0;
		my $file=getFileFromPredicate($predicate);
		if($file=~/\.gz$/){next;}
		elsif($file=~/\.bz2$/){next;}
		my ($writer,$tempfile)=tempfile();
		if(-e $file){
			my $reader=openFile($file);
			while(<$reader>){chomp;print $writer "$_\n";$count++;}
			close($reader);
		}else{mkdirs(dirname($file));}
		foreach my $s(keys(%{$json})){
			if(!exists($json->{$s}->{$predicate})){next;}
			my $object=$json->{$s}->{$predicate};
			if(ref($object)eq"ARRAY"){foreach my $o(@{$object}){print $writer "$s\t$o\n";$inserted++;$count++;}}
			else{print $writer "$s\t$object\n";$inserted++;$count++;}
		}
		close($writer);
		if($count==0){unlink($file);}
		elsif($inserted>0){
			my ($writer2,$tempfile2)=tempfile();
			close($writer2);
			chmod(0777,$tempfile2);
			system("sort $tempfile -u > $tempfile2");
			system("mv $tempfile2 $file");
		}
		$total+=$inserted;
	}
	return $total;
}
############################## commandLinecount ##############################
sub commandLinecount{
	my @arguments=@_;
	my @files=();
	if(scalar(@arguments)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@arguments;}
	my $writer=IO::File->new(">&STDOUT");
	countLines($writer,$opt_g,$opt_G,$opt_r,@files);
	close($writer);
}
############################## commandLog ##############################
sub commandLog{
	my $total=0;
	if(scalar(@ARGV)>0){
		my $json={$ARGV[0]=>{$ARGV[1]=>$ARGV[2]}};
		$total=logJson($json);
	}else{
		if(!defined($opt_f)){$opt_f="tsv";}
		my $reader=IO::File->new("-");
		my $json=($opt_f eq "tsv")?tsvToJson($reader):readJson($reader);
		close($reader);
		$total=logJson($json);
	}
	if($total>0){utime(undef,undef,$moiraiDir);utime(undef,undef,$logDir);}
	if(!defined($opt_q)){ "inserted $total\n";}
}
sub logJson{
	my $json=shift();
	my $total=0;
	foreach my $id(keys(%{$json})){
		my $inserted=0;
		my $count=0;
		my $file=getFileFromExecid($id);
		if($file=~/\.gz$/){next;}
		elsif($file=~/\.bz2$/){next;}
		my ($writer,$tempfile)=tempfile();
		if(-e $file){
			my $reader=openFile($file);
			while(<$reader>){
				chomp;
				my ($key,$val)=split(/\t/);
				if($key eq $urls->{"daemon/execute"}){next;}
				print $writer "$_\n";
				$count++;
			}
			close($reader);
		}else{mkdirs(dirname($file));}
		my $completed=0;
		while(my ($key,$val)=each(%{$json->{$id}})){
			if($key eq $urls->{"daemon/execute"}&&$val eq "completed"){$completed=1;}
			elsif($key eq $urls->{"daemon/execute"}&&$val eq "error"){$completed=-1;}
			if(ref($val)eq"ARRAY"){
				foreach my $v(@{$val}){print $writer "$key\t$v\n";$inserted++;$count++;}
			}else{print $writer "$key\t$val\n";$inserted++;$count++;}
		}
		close($writer);
		if($count==0){unlink($file);}
		elsif($inserted>0){
			my ($writer2,$tempfile2)=tempfile();
			close($writer2);
			chmod(0777,$tempfile2);
			system("sort $tempfile -u > $tempfile2");
			system("mv $tempfile2 $file");
			if($completed<0){
				my $error=getFileFromExecid($id,1);
				mkdirs(dirname($error));
				system("mv $file $error");
			}elsif($completed>0){system("gzip $file");}
		}
		$total+=$inserted;
	}
	return $total;
}
############################## commandMd5 ##############################
sub commandMd5{
	my @arguments=@_;
	my @files=();
	if(scalar(@arguments)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@arguments;}
	my $writer=IO::File->new(">&STDOUT");
	md5Files($writer,$opt_g,$opt_G,$opt_r,@files);
	close($writer);
}
############################## commandQuery ##############################
sub commandQuery{
	my @queries=();
	foreach my $argv(@ARGV){push(@queries,split(',',$argv));}
	if(scalar(@queries)==0){while(<STDIN>){chomp;push(@queries,split(','));}}
	my @results=queryResults(@queries);
	if(!defined($opt_f)){$opt_f="tsv";}
	if($opt_f eq "json"){print jsonEncode(\@results)."\n";}
	elsif($opt_f eq "tsv"){
		my $temp={};
		foreach my $res(@results){foreach my $key(keys(%{$res})){$temp->{$key}++;}}
		my @variables=sort{$a cmp $b}keys(%{$temp});
		print join("\t",@variables)."\n";
		foreach my $res(@results){
			my $line="";
			for(my $i=0;$i<scalar(@variables);$i++){
				my $key=$variables[$i];
				my $value=$res->{$key};
				if($i>0){$line.="\t";}
				$line.=$value;
			}
			print "$line\n";
		}
	}
}
############################## commandReturn ##############################
sub commandReturn{
	my @arguments=@_;
	my $execid=shift(@arguments);
	my $match=shift(@arguments);
	my $file=getFileFromExecid($execid);
	my $reader=openFile($file);
	my @results=();
	while(<$reader>){
		chomp;
		my ($key,$val)=split(/\t/);
		if($key eq $match){push(@results,$val);}
	}
	if(scalar(@results)==0){return;}
	print join(" ",@results)."\n";
}
############################## commandSelect ##############################
sub commandSelect{
	my @arguments=@_;
	my $subject=shift(@arguments);
	my $predicate=shift(@arguments);
	my $object=shift(@arguments);
	if(!defined($subject)){$subject="%";}
	if(!defined($predicate)){$predicate="%";}
	if(!defined($object)){$object="%";}
	$subject=~s/\%/.*/g;
	$predicate=~s/\%/.*/g;
	$object=~s/\%/.*/g;
	downloadPredicate($predicate);
	my @files=listFiles(undef,undef,-1,$dbDir);
	my @files=narrowDownByPredicate($predicate,@files);
	foreach my $file(@files){
		my $p=getPredicateFromFile($file);
		if(!-e $file){next;}
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if($s!~/^$subject$/){next;}
			if($o!~/^$object$/){next;}
			print "$s\t$p\t$o\n";
		}
		close($reader);
	}
}
############################## commandSeqcount ##############################
sub commandSeqcount{
	my @arguments=@_;
	my @files=();
	if(scalar(@arguments)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@arguments;}
	my $writer=IO::File->new(">&STDOUT");
	countSequences($writer,$opt_g,$opt_G,$opt_r,@files);
	close($writer);
}
############################## commandSubmit ##############################
sub commandSubmit{
	my $total=0;
	if(!defined($opt_f)){$opt_f="tsv";}
	my $reader=IO::File->new("-");
	my $json=($opt_f eq "tsv")?readHash($reader):readJson($reader);
	close($reader);
	my $id="s".getDatetime();
	my $rdf={};
	$rdf->{$id}={};
	foreach my $key(keys(%{$json})){$rdf->{$id}->{$key}=$json->{$key};}
	my $total=insertJson($rdf);
	if($total>0){utime(undef,undef,$moiraiDir);}
	if(!defined($opt_q)){print "inserted $total\n";}
}
############################## commandUpdate ##############################
sub commandUpdate{
	my $total=0;
	if(scalar(@ARGV)>0){
		my $json={$ARGV[0]=>{$ARGV[1]=>$ARGV[2]}};
		$total=updateJson($json);
	}else{
		if(!defined($opt_f)){$opt_f="tsv";}
		my $reader=IO::File->new("-");
		my $json=($opt_f eq "tsv")?tsvToJson($reader):readJson($reader);
		close($reader);
		$total=updateJson($json);
	}
	if($total>0){utime(undef,undef,$moiraiDir);utime(undef,undef,$dbDir);}
	if(!defined($opt_q)){print "updated $total\n";}
}
sub updateJson{
	my $json=shift();
	my $total=0;
	my @predicates=getPredicatesFromJson($json);
	foreach my $predicate(@predicates){
		my $updated=0;
		my $count=0;
		my $file=getFileFromPredicate($predicate);
		if($file=~/\.gz$/){next;}
		elsif($file=~/\.bz2$/){next;}
		if(!-e $file){next;}
		my $reader=openFile($file);
		my ($writer,$tempfile)=tempfile();
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if(exists($json->{$s})&&exists($json->{$s}->{$predicate})){print $writer "$s\t".$json->{$s}->{$predicate}."\n";$updated++;$count++;}
			else{print $writer "$s\t$o\n";$count++;}
		}
		close($writer);
		close($reader);
		if($count==0){unlink($file);}
		elsif($updated>0){
			my ($writer2,$tempfile2)=tempfile();
			close($writer2);
			chmod(0777,$tempfile2);
			system("sort $tempfile -u > $tempfile2");
			system("mv $tempfile2 $file");
		}
		$total+=$updated;
	}
	return $total;
}
############################## checkBinary ##############################
sub checkBinary{
	my $file=shift();
	while(-l $file){$file=readlink($file);}
	my $result=`file --mime $file`;
	if($result=~/charset\=binary/){return 1;}
}
############################## getURLFromPredicate ##############################
sub getURLFromPredicate{
	my $predicate=shift();
	if($predicate=~/^(.+)#(.+)$/){$predicate=$1;}
	if($predicate=~/^(.+)\.json$/){$predicate=$1;}
	my $url="$predicate.txt.gz";
	my $lastModified=getLastModified($url);
	if(defined($lastModified)){return ($url,$lastModified);}
	$url="$predicate.txt.bz2";
	$lastModified=getLastModified($url);
	if(defined($lastModified)){return ($url,$lastModified);}
	$url="$predicate.txt";
	$lastModified=getLastModified($url);
	if(defined($lastModified)){return ($url,$lastModified);}
	return;
}
############################## downloadPredicate ##############################
sub downloadPredicate{
	my $predicate=shift();
	if($predicate!~/https?:\/\//){next;}
	my ($url,$lastModified)=getURLFromPredicate($predicate);
	if(!defined($lastModified)){return;}
	my $file=getFileFromPredicate($predicate);
	if(-e $file){
		my $modTime=$lastModified->epoch;
		my $modTime2=getModTime($file);
		if($modTime2>=$modTime){return;}
	}
	mkdirs(dirname($file));
	if(!defined($opt_q)){print STDERR "Downloading: $file\n";}
	downloadHttpContent($url,$file);
	system("gzip $file");
}
############################## getModTime ##############################
sub getModTime{
	my $file=shift();
	my @stats=stat($file);
	return $stats[9];
}
############################## getLastModified ##############################
sub getLastModified{
	my $url=shift();
	my $ua=LWP::UserAgent->new;
	my $req=HTTP::Request->new(GET=>$url);
	my $res=$ua->simple_request($req);
	foreach my $line(split(/\n/,$res->headers_as_string)){
		if($line=~/Last-Modified:\s(\S+),\s(\S+)\s(\S+)\s(\S+)\s(\S+)\sGMT$/){
			my $week=$1;
			my $day=$2;
			my $month=$3;
			my $year=$4;
			my $time=$5;
			if($month=~/^Jan/){$month="01";}
			elsif($month=~/^Feb/){$month="02";}
			elsif($month=~/^Mar/){$month="03";}
			elsif($month=~/^Apr/){$month="04";}
			elsif($month=~/^May/){$month="05";}
			elsif($month=~/^Jun/){$month="06";}
			elsif($month=~/^Jul/){$month="07";}
			elsif($month=~/^Aug/){$month="08";}
			elsif($month=~/^Sep/){$month="09";}
			elsif($month=~/^Oct/){$month="10";}
			elsif($month=~/^Nov/){$month="11";}
			elsif($month=~/^Dec/){$month="12";}
			my $t=Time::Piece->strptime("$year$month$day $time", "%Y%m%d %H:%M:%S");
			return $t;
		}
	}
	return;
}
############################## fileStats ##############################
sub fileStats{
	my @files=@_;
	my $writer=shift(@files);
	my $filegrep=shift(@files);
	my $fileungrep=shift(@files);
	my $recursivesearch=shift(@files);
	foreach my $file(listFiles($filegrep,$fileungrep,$recursivesearch,@files)){
		# count line and seq
		my $linecount;
		my $seqcount;
		if($file=~/\.bam$/){#bam file
			$linecount=`samtools view -c $file`;
			chomp($linecount);
			$seqcount=`samtools view -c -f 0x2 $file`;
			$seqcount=($seqcount>0)?1:0;
			if($seqcount){$seqcount=`samtools view -c -f 0x2 -F 0x184 $file`;}
			else{$seqcount=`samtools view -c -F 0x184 $file`;}
			chomp($seqcount);
		}elsif($file=~/\.sam$/){#sam
			$linecount=`samtools view -S -c $file`;
			chomp($linecount);
			$seqcount=`samtools view -S -c -f 0x2 $file`;
			$seqcount=($seqcount>0)?1:0;
			if($seqcount){$seqcount=`samtools view -S -c -f 0x2 -F 0x184 $file`;}
			else{$seqcount=`samtools view -S -c -F 0x184 $file`;}
			chomp($seqcount);
		}elsif($file=~/\.gz(ip)?$/){#gzip
			$linecount=`gzip -cd $file|wc -l`;
			chomp($linecount);
			if($file=~/\.f(ast)?a\.gz(ip)?$/){$seqcount=`gzip -cd $file|grep '>'|wc -l`;chomp($seqcount);}
			elsif($file=~/\.f(ast)?q\.gz(ip)?$/){$seqcount=$linecount/4;chomp($seqcount);}
		}elsif($file=~/\.bz(ip)?2$/){ #bzip
			$linecount=`bzip2 -cd $file|wc -l`;
			chomp($linecount);
			if($file=~/\.f(ast)?a\.bz(ip)?2$/){$seqcount=`bzip -cd $file|grep '>'|wc -l`;chomp($seqcount);}
			elsif($file=~/\.f(ast)?q\.bz(ip)?2$/){$seqcount=$linecount/4;chomp($seqcount);}
		}elsif(checkBinary($file)){# binary file
			print $writer "$file\tfile/binary\ttrue\n";
		}else{
			$linecount=`cat $file|wc -l`;
			chomp($linecount);
			if($file=~/\.f(ast)?a$/){$seqcount=`cat $file|grep '>'|wc -l`;chomp($seqcount);}
			elsif($file=~/\.f(ast)?q$/){$seqcount=$linecount/4;chomp($seqcount);}
		}
		if(defined($linecount)){
			if($linecount=~/(\d+)/){$linecount=$1;}
			print $writer "$file\tfile/linecount\t$linecount\n";
		}
		if(defined($seqcount)){
			if($seqcount=~/(\d+)/){$seqcount=$1;}
			print $writer "$file\tfile/seqcount\t$seqcount\n";
		}
		#md5
		if(defined($md5cmd)){
			my $sum=`$md5cmd<$file`;
			chomp($sum);
			if($sum=~/^(\w+)/){$sum=$1;}
			print $writer "$file\tfile/md5\t$sum\n";
		}
		#filesize
		my $filesize=-s $file;
		print $writer "$file\tfile/filesize\t$filesize\n";
		my @stats=stat($file);
		my $mtime=$stats[9];
		print $writer "$file\tfile/mtime\t$mtime\n";
	}
}
############################## countLines ##############################
sub countLines{
	my @files=@_;
	my $writer=shift(@files);
	my $filegrep=shift(@files);
	my $fileungrep=shift(@files);
	my $recursivesearch=shift(@files);
	foreach my $file(listFiles($filegrep,$fileungrep,$recursivesearch,@files)){
		my $count=0;
		if($file=~/\.bam$/){$count=`samtools view $file|wc -l`;}
		elsif($file=~/\.sam$/){$count=`samtools view $file|wc -l`;}
		elsif($file=~/\.gz(ip)?$/){$count=`gzip -cd $file|wc -l`;}
		elsif($file=~/\.bz(ip)?2$/){$count=`bzip2 -cd $file|wc -l`;}
		else{$count=`cat $file|wc -l`;}
		if($count=~/(\d+)/){$count=$1;}
		print $writer "$file\tfile/linecount\t$count\n";
	}
}
############################## countSequences ##############################
sub countSequences{
	my @files=@_;
	my $writer=shift(@files);
	my $filegrep=shift(@files);
	my $fileungrep=shift(@files);
	my $recursivesearch=shift(@files);
	foreach my $file(listFiles($filegrep,$fileungrep,$recursivesearch,@files)){
		my $count=0;
		if($file=~/\.bam$/){
			my $paired=`samtools view $file|head -n 1|perl -ne 'if(\$_&2){print \"0\";}else{print \"1\";}'`;
			if($paired eq "1"){$count=`samtools view -f 0x2 -F 0x184 $file|wc -l`;}
			else{$count=`samtools view -F 0x184 $file|wc -l`;}
		}elsif($file=~/\.sam$/){
			my $paired=`samtools view -S $file|head -n 1|perl -ne 'if(\$_&2){print \"1\";}else{print \"0\";}'`;
			if($paired eq "1"){$count=`samtools view -S -f 0x2 -F 0x184 $file|wc -l`;}
			else{$count=`samtools view -S -F 0x184 $file|wc -l`;}
		}elsif($file=~/\.f(ast)?a$/){$count=`cat $file|grep '>'|wc -l`;}
		elsif($file=~/\.f(ast)?q$/){$count=`cat $file|wc -l`;$count/=4;}
		elsif($file=~/\.f(ast)?a\.gz(ip)?$/){$count=`gzip -cd $file|grep '>'|wc -l`;}
		elsif($file=~/\.f(ast)?a\.bz(ip)?2$/){$count=`bzip2 -cd $file|grep '>'|wc -l`;}
		elsif($file=~/\.f(ast)?q\.gz(ip)?$/){$count=`gzip -cd $file|wc -l`;$count/=4;}
		elsif($file=~/\.f(ast)?q\.bz(ip)?2$/){$count=`bzip2 -cd $file|wc -l`;$count/=4;}
		elsif($file=~/\.gz(ip)?$/){$count=`gzip -cd $file|wc -l`;}
		elsif($file=~/\.bz(ip)?2$/){$count=`bzip2 -cd $file|wc -l`;}
		else{$count=`cat $file|wc -l`;}
		if($count=~/(\d+)/){$count=$1;}
		print $writer "$file\tfile/seqcount\t$count\n";
	}
}
############################## createFile ##############################
sub createFile{
	my @lines=@_;
	my $path=shift(@lines);
	open(OUT,">$path");
	foreach my $line(@lines){print OUT "$line\n";}
	close(OUT);
}
############################## getCommandUrlFromFile ##############################
sub getCommandUrlFromFile{
	my $file=shift();
	my $reader=openFile($file);
	while(<$reader>){
		chomp;
		if(/^========================================/){next;}
		my ($p,$o)=split(/\t/);
		if($p eq $urls->{"daemon/command"}){return $o;}
	}
	return;
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
############################## getFileFromExecid ##############################
sub getFileFromExecid{
	my $execid=shift();
	my $errorflag=shift();
	my $dirname=substr($execid,1,8);
	my $path="$logDir/$dirname/$execid.txt";
	if(-e "$errorDir/$execid.txt"){return "$errorDir/$execid.txt";}
	elsif(-e "$path.gz"){return "$path.gz";}
	elsif(-e "$path.bz2"){return "$path.bz2";}
	elsif(defined($errorflag)){return "$errorDir/$execid.txt";}
	else{return $path;}
}
############################## getFileFromPredicate ##############################
sub getFileFromPredicate{
	my $predicate=shift();
	if($predicate=~/^(https?):\/\/(.+)$/){$predicate="$1/$2";}
	if($predicate=~/^(.+)#(.+)$/){$predicate=$1;}
	if($predicate=~/^(.+)\.json$/){$predicate=$1;}
	if(-e "$dbDir/$predicate.txt.gz"){return "$dbDir/$predicate.txt.gz";}
	elsif(-e "$dbDir/$predicate.txt.bz2"){return "$dbDir/$predicate.txt.bz2";}
	else{return "$dbDir/$predicate.txt";}
}
############################## downloadHttpContent ##############################
sub downloadHttpContent{
	my $url=shift();
	my $file=shift();
	my $lwp = LWP::UserAgent->new(timeout=>10);
    my $res=$lwp->get($url,':content_file'=>$file);
    if (!$res->is_success){print STDERR "ERROR downloading $url to $file\n";}
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
############################## getPredicateFromFile ##############################
sub getPredicateFromFile{
	my $path=shift();
	my $dirname=dirname($path);
	my $basename=basename($path);
	if($dirname=~/^$dbDir\/(.+)$/){$basename="$1/$basename";}
	if($basename=~/^https\/(.+)$/){$basename="https://$1";}
	elsif($basename=~/^http\/(.+)$/){$basename="http://$1";}
	if($basename=~/^(.+)\.te?xt\.gz(ip)?$/){return $1;}
	elsif($basename=~/^(.+)\.te?xt\.bz(ip)2?$/){return $1;}
	elsif($basename=~/^(.+)\.te?xt$/){return $1;}
	else{return $basename;}
}
############################## getPredicatesFromJson ##############################
sub getPredicatesFromJson{
	my $json=shift();
	my $hash={};
	foreach my $s(keys(%{$json})){foreach my $p(keys(%{$json->{$s}})){$hash->{$p}=1;}}
	return sort {$a cmp $b}keys(%{$hash});
}
############################## getSubjectFromFile ##############################
sub getSubjectFromFile{
	my $path=shift();
	my $basename=basename($path);
	$basename=~s/\.gz$//;
	$basename=~s/\.bz2$//;
	$basename=~s/\.txt$//;
	return $basename;
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
############################## jsonEncode ##############################
sub jsonEncode{
	my $object=shift;
	if(ref($object) eq "ARRAY"){return jsonEncodeArray($object);}
	elsif(ref($object) eq "HASH"){return jsonEncodeHash($object);}
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
	foreach my $subject(sort{$a cmp $b} keys(%{$hashtable})){
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
	return($array,$index);
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
			if($chars->[$index] eq ":"){chomp($key);$findKey=0;}
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
	return($hash,$index);
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
	return(jsonUnescape($value),$i);
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
	return(jsonUnescape($value),$i);
}
sub jsonUnescape{
	my $text=shift();
	$text=~s/\\"/\"/g;
	$text=~s/\\t/\t/g;
	$text=~s/\\r/\r/g;
	$text=~s/\\n/\n/g;
	$text=~s/\\\\/\\/g;
	return $text;
}
############################## listFiles ##############################
sub listFiles{
	my @inputdirectories=@_;
	my $filegrep=shift(@inputdirectories);
	my $fileungrep=shift(@inputdirectories);
	my $recursivesearch=shift(@inputdirectories);
	my @inputfiles=();
	foreach my $inputdirectory (@inputdirectories){
		if(-f $inputdirectory){push(@inputfiles,$inputdirectory);next;}
		elsif(-l $inputdirectory){push(@inputfiles,$inputdirectory);next;}
		opendir(DIR,$inputdirectory);
		foreach my $file(readdir(DIR)){
			if($file eq "."){next;}
			if($file eq ".."){next;}
			if($file eq ""){next;}
			if($file=~/^\./){next;}
			my $path=($inputdirectory eq ".")?$file:"$inputdirectory/$file";
			if(-d $path){
				if($recursivesearch!=0){push(@inputfiles,listFiles($filegrep,$fileungrep,$recursivesearch-1,$path));}
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
############################## loadLogToHash ##############################
sub loadLogToHash{
	my $directory=shift();
	my @files=listFiles(undef,undef,-1,$directory);
	my @array=();
	foreach my $file(@files){
		my $hash={};
		my $s=getSubjectFromFile($file);
		my $daemonregexp=quotemeta("https://moirai2.github.io/schema/daemon/");
		my $url=getCommandUrlFromFile($file)."#";
		if(!defined($url)){next;}
		my $urlregexp=quotemeta($url);
		my $reader=openFile($file);
		$hash->{"daemon/execid"}=$s;
		while(<$reader>){
			chomp;
			if(/^========================================/){next;}
			my ($p,$o)=split(/\t/);
			if($p eq $urls->{"daemon/timestarted"}){$o=getDate("/",$o)." ".getTime(":",$o)}
			elsif($p eq $urls->{"daemon/timeended"}){$o=getDate("/",$o)." ".getTime(":",$o)}
			elsif($p eq $urls->{"daemon/timethrown"}){$o=getDate("/",$o)." ".getTime(":",$o)}
			if($p=~s/^$daemonregexp//){$p="daemon/$p";}
			if($p=~s/^$urlregexp//){}
			if(!exists($hash->{$p})){$hash->{$p}=$o;}
			elsif(ref($hash->{$p})eq"ARRAY"){push(@{$hash->{$p}},$o);}
			else{$hash->{$p}=[$hash->{$p},$o];}
		}
		close($reader);
		push(@array,$hash);
	}
	return \@array;
}
############################## loadDbToArray ##############################
sub loadDbToArray{
	my $directory=shift();	
	my ($nodes,$edges)=toNodesAndEdges($directory);
	my @queries=();
	foreach my $from(keys(%{$edges})){
		my $labelFrom="\$".$nodes->{$from};
		foreach my $to(keys(%{$edges->{$from}})){
			my $labelTo="\$".$nodes->{$to};
			my $pred=$edges->{$from}->{$to};
			my $query="$labelFrom->$pred->$labelTo";
			push(@queries,$query);
		}
	}
	my @results=queryResults(@queries);
	return \@results;
}
############################## loadDbToHash ##############################
sub loadDbToHash{
	my $directory=shift();
	my @files=listFiles(undef,undef,-1,$directory);
	my $hash={};
	foreach my $file(@files){
		my $p=getPredicateFromFile($file);
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if(!exists($hash->{$s})){$hash->{$s};}
			if(!exists($hash->{$s}->{$p})){$hash->{$s}->{$p}=$o;}
			elsif(ref($hash->{$s}->{$p})eq"ARRAY"){push(@{$hash->{$s}->{$p}},$o);}
			else{$hash->{$s}->{$p}=[$hash->{$s}->{$p},$o];}
		}
		close($reader);
	}
	return $hash;
}
############################## loadDbToVisNetwork ##############################
sub loadDbToVisNetwork{
	my $directory=shift();	
	my ($nodes,$edges)=toNodesAndEdges($directory);
	my $visEdges=[];
	my $visNodes=[];
	foreach my $from(keys(%{$edges})){
		my $hash={"from"=>$from};
		foreach my $to(keys(%{$edges->{$from}})){
			$hash->{"to"}=$to;
			$hash->{"label"}=$edges->{$from}->{$to};
			$hash->{"color"}="lightGrey";
		}
		push(@{$visEdges},$hash);
	}
	foreach my $index(keys(%{$nodes})){
		my $label=$nodes->{$index};
		my $hash={"id"=>$index,"label"=>$label};
		if($label eq "root"){
			$hash->{"shape"}="circle";
			$hash->{"font"}=10;
			$hash->{"color"}="red";
		}elsif($label eq "file"){
			$hash->{"shape"}="box";
			$hash->{"font"}=20;
			$hash->{"color"}="lightBlue";
		}elsif($label eq "num"){
			$hash->{"shape"}="circle";
			$hash->{"color"}="lightGrey";
		}elsif($label eq "val"){
			$hash->{"shape"}="circle";
			$hash->{"color"}="lightGrey";
		}
		push(@{$visNodes},$hash);
	}
	return [$visNodes,$visEdges];
}
############################## loadLogs ##############################
sub loadLogs{
	my @files=listFiles(".txt\$",undef,-1,$logDir);
	my $hash={};
	foreach my $file(@files){
		my $basename=basename($file,".txt");
		$hash->{$basename}={};
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			if(/^========================================/){next;}
			my ($key,$val)=split(/\t/);
			$hash->{$basename}->{$key}=$val;
		}
		close($reader);
	}
	return $hash;
}
############################## md5Files ##############################
sub md5Files{
	my @files=@_;
	my $writer=shift(@files);
	my $filegrep=shift(@files);
	my $fileungrep=shift(@files);
	my $recursivesearch=shift(@files);
	foreach my $file(listFiles($filegrep,$fileungrep,$recursivesearch,@files)){
		if(defined($md5cmd)){
			my $sum=`$md5cmd $file`;
			chomp($sum);
			if($sum=~/(\S+)$/){$sum=$1;}
			print $writer "$file\tfile/md5\t$sum\n";
		}
	}
}
############################## mkdirs ##############################
sub mkdirs {
	my @directories=@_;
	foreach my $directory(@directories){
		if(-d $directory){next;}
		my @tokens=split(/[\/\\]/,$directory);
		if(($tokens[0]eq"")&&(scalar(@tokens)>1)){
			shift( @tokens );
			my $token=shift(@tokens);
			unshift(@tokens,"/$token");
		}
		my $string="";
		foreach my $token(@tokens){
			$string.=(($string eq"")?"":"/").$token;
			if(-d $string){next;}
			if(!mkdir($string)||!chmod(0777,$string)){return 0;}
		}
	}
	return 1;
}
############################## narrowDownByPredicate ##############################
sub narrowDownByPredicate{
	my @files=@_;
	my $predicate=shift(@files);
	if($predicate=~/^(https?):\/\/(.+)$/){$predicate="$1/$2";}
	my @results=();
	foreach my $file(@files){
		if($file=~/^$dbDir\/$predicate\.te?xt$/){push(@results,$file);}
		elsif($file=~/^$dbDir\/$predicate\.te?xt\.gz(ip)?$/){push(@results,$file);}
		elsif($file=~/^$dbDir\/$predicate\.te?xt\.bz(ip)?2$/){push(@results,$file);}
	}
	return @results;
}
############################## openFile ##############################
sub openFile{
	my $path=shift();
	if($path=~/\.gz(ip)?$/){return IO::File->new("gzip -cd $path|");}
	elsif($path=~/\.bz(ip)?2$/){return IO::File->new("bzip2 -cd $path|");}
	elsif($path=~/\.bam$/){return IO::File->new("samtools view $path|");}
	else{return IO::File->new($path);}
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
############################## queryResults ##############################
sub queryResults{
	my @queries=@_;
	my $values={};
	foreach my $query(@queries){
		my ($s,$p,$o)=split(/\-\>/,$query);
		downloadPredicate($p);
	}
	my @files=listFiles(undef,undef,-1,$dbDir);
	foreach my $query(@queries){
		my ($s,$p,$o)=split(/\-\>/,$query);
		my @array=queryVariables($s,$p,$o,@files);
		if(scalar(@array)>0){$values->{$query}=\@array;}
	}
	my @results=();
	for(my $i=0;$i<scalar(@queries);$i++){
		my $query=$queries[$i];
		if($i==0){@results=@{$values->{$query};};next;}
		my $array=$values->{$query};
		my @temp=();
		foreach my $h(@results){
			foreach my $h2(@{$array}){
				my $error=0;
				my $found=0;
				foreach my $k(keys(%{$h})){
					if(!exists($h2->{$k})){next;}
					$found++;
					if($h->{$k}ne$h2->{$k}){$error++;}
				}
				if($error>0){next;}
				my $hash={};
				if($found>0){
					foreach my $k(keys(%{$h})){$hash->{$k}=$h->{$k};}
					foreach my $k(keys(%{$h2})){if(!exists($h->{$k})){$hash->{$k}=$h2->{$k};}}
				}else{
					foreach my $k(keys(%{$h})){$hash->{$k}=$h->{$k};}
					foreach my $k(keys(%{$h2})){$hash->{$k}=$h2->{$k};}
				}
				push(@temp,$hash);
			}
		}
		@results=@temp;
		if(scalar(@results)==0){last;}
	}
	return @results;
}
############################## queryVariables ##############################
sub queryVariables{
	my @files=@_;
	my $subject=shift(@files);
	my $predicate=shift(@files);
	my $object=shift(@files);
	my @subVars=();
	my @preVars=();
	my @objVars=();
	if($subject=~/\$(\w+)/){
		while($subject=~/\$(\w+)/){
			push(@subVars,$1);
			$subject=~s/\$(\w+)/(.+)/;
		}
		$subject="$subject";
	}
	if($predicate=~/\$(\w+)/){
		while($predicate=~/\$(\w+)/){
			push(@preVars,$1);
			$predicate=~s/\$(\w+)/(.+)/;
		}
		$predicate="$predicate";
	}
	if($object=~/\$(\w+)/){
		while($object=~/\$(\w+)/){
			push(@objVars,$1);
			$object=~s/\$(\w+)/(.+)/;
		}
		$object="$object";
	}
	@files=narrowDownByPredicate($predicate,@files);
	my @array=();
	foreach my $file(@files){
		my $p=getPredicateFromFile($file);
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if($s!~/^$subject$/){next;}
			if($o!~/^$object$/){next;}
			my $h={};
			if(scalar(@subVars)>0){
				my @results=$s=~/^$subject$/;
				for(my $i=0;$i<scalar(@subVars);$i++){$h->{$subVars[$i]}=$results[$i];}
			}
			if(scalar(@preVars)>0){
				my @results=$p=~/^$predicate$/;
				for(my $i=0;$i<scalar(@preVars);$i++){$h->{$preVars[$i]}=$results[$i];}
			}
			if(scalar(@objVars)>0){
				my @results=$o=~/^$object$/;
				for(my $i=0;$i<scalar(@objVars);$i++){$h->{$objVars[$i]}=$results[$i];}
			}
			if(scalar(keys(%{$h}))>0){push(@array,$h);}
		}
		close($reader);
	}
	return @array;
}
############################## readHash ##############################
sub readHash{
	my $reader=shift();
	my $hash={};
	while(<$reader>){
		chomp;
		s/\r//g;
		my ($key,$value)=split(/\t/);
		if($key ne ""){$hash->{$key}=$value;}
	}
	return $hash;
}
############################## readJson ##############################
sub readJson{
	my $reader=shift();
	my $json="";
	while(<$reader>){chomp;s/\r//g;$json.=$_;}
	return jsonDecode($json);
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
############################## sizeFiles ##############################
sub sizeFiles{
	my @files=@_;
	my $writer=shift(@files);
	my $filegrep=shift(@files);
	my $fileungrep=shift(@files);
	my $recursivesearch=shift(@files);
	foreach my $file(listFiles($filegrep,$fileungrep,$recursivesearch,@files)){
		my $size=-s $file;
		print $writer "$file\tfile/filesize\t$size\n";
	}
}
############################## toNodesAndEdges ##############################
sub toNodesAndEdges{
	my $directory=shift();	
	my @files=listFiles(undef,undef,-1,$directory);
	my $objects={};
	my $nodes={};
	my $predicates={};
	my $nodeindex=1;
	foreach my $file(@files){
		my $p=getPredicateFromFile($file);
		$predicates->{$p}=$nodeindex;
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if($s eq"root"&&!exists($objects->{"root"})){$objects->{"root"}=0;$nodes->{0}="root";}
			if($o!~/^[\+\-]?\d+(\.\d*)?([Ee][\+\-]?\d+)?$/){
				$objects->{$o}=$nodeindex;
				if(!exists($nodes->{$nodeindex})){
					if($o=~/^\S+\.\w+$/){$nodes->{$nodeindex}=$p;}
					else{$nodes->{$nodeindex}=$p;}
				}
			}elsif(!exists($nodes->{$nodeindex})){$nodes->{$nodeindex}=$p;}
		}
		close($reader);
		$nodeindex++;
	}
	my $subjectIndex=0;
	foreach my $file(@files){
		my $p=getPredicateFromFile($file);
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if(!exists($objects->{$s})){
				$objects->{$s}=$nodeindex;
				if(!exists($nodes->{$nodeindex})){
					if($s=~/^\S+\.\w+$/){$nodes->{$nodeindex}="file$subjectIndex";}
					else{$nodes->{$nodeindex}="val$subjectIndex";}
					$subjectIndex++;
				}
			}
		}
		close($reader);
		$nodeindex++;
	}
	my $edges={};
	foreach my $file(@files){
		my $p=getPredicateFromFile($file);
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if(!exists($objects->{$s})){next;}
			my $from=$objects->{$s};
			if(!exists($edges->{$from})){$edges->{$from}={};}
			if(exists($objects->{$o})){
				my $to=$objects->{$o};
				if(!exists($edges->{$from}->{$to})){$edges->{$from}->{$to}=$p;}
			}elsif($o=~/^[\+\-]?\d+(\.\d*)?([Ee][\+\-]?\d+)?$/){
				my $to=$predicates->{$p};
				if(!exists($edges->{$from}->{$to})){$edges->{$from}->{$to}=$p;}
			}
		}
		close($reader);
	}
	return ($nodes,$edges);
}
############################## tsvToJson ##############################
sub tsvToJson{
	my $reader=shift();
	my $json={};
	my $linecount=0;
	while(<$reader>){
		chomp;
		s/\r//g;
		my ($subject,$predicate,$object)=split(/\t/);
		if(!exists($json->{$subject})){$json->{$subject}={};}
		if(!exists($json->{$subject}->{$predicate})){$json->{$subject}->{$predicate}=$object;}
		elsif(ref($json->{$subject}->{$predicate}) eq "ARRAY"){push(@{$json->{$subject}->{$predicate}},$object);}
		else{$json->{$subject}->{$predicate}=[$json->{$subject}->{$predicate},$object];}
		$linecount++;
	}
	return wantarray?($json,$linecount):$json;
}
############################## testCommand ##############################
sub testCommand{
	my $command=shift();
	my $value2=shift();
	my $file=shift();
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
############################## testSub ##############################
sub testSub{
	my $command=shift();
	my $value2=shift();
	my $value1=eval($command);
	if($value1 eq $value2){return 0;}
	print STDERR ">$command\n";
	print STDERR "'$value1' != '$value2'\n";
}
############################## test ##############################
sub test{
	testSub("getPredicateFromFile(\"$dbDir/A.txt\")","A");
	testSub("getPredicateFromFile(\"$dbDir/B/A.txt\")","B/A");
	testSub("getPredicateFromFile(\"$dbDir/https/moirai2.github.io/schema/daemon/bash.txt\")","https://moirai2.github.io/schema/daemon/bash");
	testSub("getPredicateFromFile(\"$dbDir/http/localhost/~ah3q/moirai2/A.txt.gz\")","http://localhost/~ah3q/moirai2/A");
	testSub("getFileFromPredicate(\"A\")","$dbDir/A.txt");
	testSub("getFileFromPredicate(\"A/B\")","$dbDir/A/B.txt");
	testSub("getFileFromPredicate(\"A/B#CDF\")","$dbDir/A/B.txt");
	testSub("getFileFromPredicate(\"A/B.json\")","$dbDir/A/B.txt");
	testSub("getFileFromPredicate(\"A/B.json#D\")","$dbDir/A/B.txt");
	testSub("getFileFromPredicate(\"http://A.B.C/D/E\")","$dbDir/http/A.B.C/D/E.txt");
	testSub("getFileFromPredicate(\"https://A.B.C/D/E.json#F\")","$dbDir/https/A.B.C/D/E.txt");
	mkdir("test");
	mkdir("test/db");
	createFile("test/db/id.txt","A\tA1","B\tB1","C\tC1","D\tD1");
	createFile("test/db/name.txt","A1\tAkira","B1\tBen","C1\tChris","D1\tDavid");
	testCommand("perl rdf.pl linecount test/db/id.txt","test/db/id.txt\tfile/linecount\t4");
	testCommand("perl rdf.pl md5 test/db/id.txt","test/db/id.txt\tfile/md5\t131e61dab9612108824858dc497bf713");
	testCommand("perl rdf.pl filesize test/db/id.txt","test/db/id.txt\tfile/filesize\t20");
	testCommand("perl rdf.pl seqcount test/db/id.txt","test/db/id.txt\tfile/seqcount\t4");
	testCommand("perl rdf.pl -d test select ","A\tid\tA1\nB\tid\tB1\nC\tid\tC1\nD\tid\tD1\nA1\tname\tAkira\nB1\tname\tBen\nC1\tname\tChris\nD1\tname\tDavid");
	testCommand("perl rdf.pl -d test select A","A\tid\tA1");
	testCommand("perl rdf.pl -d test select % id","A\tid\tA1\nB\tid\tB1\nC\tid\tC1\nD\tid\tD1");
	testCommand("perl rdf.pl -d test select % % B1","B\tid\tB1");
	testCommand("perl rdf.pl -d test select A%","A\tid\tA1\nA1\tname\tAkira");
	testCommand("perl rdf.pl -d test select A% n%","A1\tname\tAkira");
	testCommand("perl rdf.pl -d test select % % A%","A\tid\tA1\nA1\tname\tAkira");
	testCommand("perl rdf.pl -d test select %1","A1\tname\tAkira\nB1\tname\tBen\nC1\tname\tChris\nD1\tname\tDavid");
	testCommand("perl rdf.pl -d test delete A%","deleted 2");
	testCommand("perl rdf.pl -d test select ","B\tid\tB1\nC\tid\tC1\nD\tid\tD1\nB1\tname\tBen\nC1\tname\tChris\nD1\tname\tDavid");
	testCommand("perl rdf.pl -d test delete % name","deleted 3");
	testCommand("perl rdf.pl -d test select ","B\tid\tB1\nC\tid\tC1\nD\tid\tD1");
	testCommand("perl rdf.pl -d test delete % % %1","deleted 3");
	testCommand("perl rdf.pl -d test insert T name Tsunami","inserted 1");
	testCommand("perl rdf.pl -d test select T","T\tname\tTsunami");
	testCommand("perl rdf.pl -d test insert A name Akira","inserted 1");
	testCommand("perl rdf.pl -d test select","A\tname\tAkira\nT\tname\tTsunami");
	testCommand("perl rdf.pl -d test update A name Alice","updated 1");
	testCommand("perl rdf.pl -d test select","A\tname\tAlice\nT\tname\tTsunami");
	createFile("test/import.txt","A\tid\tA2","B\tid\tB2","C\tid\tC2","D\tid\tD2","A\tid\tA1","B\tid\tB1","C\tid\tC1","D\tid\tD1");
	testCommand("perl rdf.pl -d test import < test/import.txt","inserted 8");
	testCommand("perl rdf.pl -d test select % id","A\tid\tA1\nA\tid\tA2\nB\tid\tB1\nB\tid\tB2\nC\tid\tC1\nC\tid\tC2\nD\tid\tD1\nD\tid\tD2");
	createFile("test/update.txt","A\tid\tA3","B\tid\tB3");
	testCommand("perl rdf.pl -d test update < test/update.txt","updated 4");
	testCommand("perl rdf.pl -d test select A id","A\tid\tA3");
	testCommand("perl rdf.pl -d test select B id","B\tid\tB3");
	createFile("test/update.json","{\"A\":{\"name\":\"Akira\"},\"B\":{\"name\":\"Bob\"}}");
	testCommand("perl rdf.pl -d test -f json update < test/update.json","updated 1");
	testCommand("perl rdf.pl -d test select % name","A\tname\tAkira\nT\tname\tTsunami");
	testCommand("perl rdf.pl -d test delete < test/update.txt","deleted 2");
	testCommand("perl rdf.pl -d test select % id","C\tid\tC1\nC\tid\tC2\nD\tid\tD1\nD\tid\tD2");
	testCommand("perl rdf.pl -d test -f json delete < test/update.json","deleted 1");
	testCommand("perl rdf.pl -d test select % name","T\tname\tTsunami");
	testCommand("perl rdf.pl -d test delete % % %","deleted 5");
	testCommand("perl rdf.pl -d test -f json insert < test/update.json","inserted 2");
	testCommand("perl rdf.pl -d test insert < test/import.txt","inserted 8");
	testCommand("echo \"A\tB\nC\tD\n\"|perl rdf.pl -d test submit","inserted 2");
	testCommand("echo \"{'E':'F','G':'H'}\n\"|perl rdf.pl -d test -f json submit","inserted 2");
	testCommand("perl rdf.pl -d test delete % % %","deleted 14");
	testCommand("echo \"A\tB\tC\nC\tD\tE\nC\tF\tG\"|perl rdf.pl -d test import","inserted 3");
	testCommand("perl rdf.pl -d test query '\$a->B->\$c'","a\tc\nA\tC");
	testCommand("perl rdf.pl -d test -f json  query '\$a->B->\$c'","[{\"a\":\"A\",\"c\":\"C\"}]");
	testCommand("perl rdf.pl -d test query '\$a->B->\$c' '\$c->D->\$e'","a\tc\te\nA\tC\tE");
	testCommand("perl rdf.pl -d test -f json  query '\$a->B->\$c' '\$c->D->\$e'","[{\"a\":\"A\",\"c\":\"C\",\"e\":\"E\"}]");
	testCommand("echo \"C\tD\tH\"|perl rdf.pl -d test insert","inserted 1");
	testCommand("perl rdf.pl -d test query '\$a->B->\$c' '\$c->D->\$e'","a\tc\te\nA\tC\tE\nA\tC\tH");
	testCommand("perl rdf.pl -d test -f json  query '\$a->B->\$c' '\$c->D->\$e'","[{\"a\":\"A\",\"c\":\"C\",\"e\":\"E\"},{\"a\":\"A\",\"c\":\"C\",\"e\":\"H\"}]");
	testCommand("perl rdf.pl -d test query '\$a->B->\$c' '\$c->D->\$e' '\$c->F->\$g'","a\tc\te\tg\nA\tC\tE\tG\nA\tC\tH\tG");
	testCommand("perl rdf.pl -d test -f json  query '\$a->B->\$c' '\$c->D->\$e' '\$c->F->\$g'","[{\"a\":\"A\",\"c\":\"C\",\"e\":\"E\",\"g\":\"G\"},{\"a\":\"A\",\"c\":\"C\",\"e\":\"H\",\"g\":\"G\"}]");
	testCommand("perl rdf.pl -d test delete % % %","deleted 4");
	unlink("test/update.txt");
	unlink("test/update.json");
	unlink("test/import.txt");
	rmdir("test/db");
	rmdir("test/log/error");
	rmdir("test/log");
	rmdir("test");
}