#!/usr/bin/perl
use strict 'vars';
use Cwd;
use File::Basename;
use File::Which;
use File::Temp qw/tempfile tempdir/;
use FileHandle;
use Getopt::Std;
use File::Path;
use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Status;
use Time::HiRes;
use Time::Local;
use Time::localtime;
############################## HEADER ##############################
my($program_name,$program_directory,$program_suffix)=fileparse($0);
$program_directory=substr($program_directory,0,-1);
my $program_version="2021/09/13";
############################## OPTIONS ##############################
use vars qw($opt_d $opt_f $opt_g $opt_G $opt_h $opt_i $opt_o $opt_q $opt_r $opt_s);
getopts('d:f:g:G:hi:qo:r:s:');
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
	print "Version: $program_version\n";
	print "Author: Akira Hasegawa (akira.hasegawa\@riken.jp)\n";
	print "\n";
	print "Usage: perl $program_name [Options] COMMAND\n";
	print "\n";
	print "Commands:    assign  Assign triple if sub+pre doesn't exist\n";
	print "             config  Load config setting to the database\n";
	print "             delete  Delete triple(s)\n";
	print "             export  export database content to moirai2.pl HTML from html()\n";
	print "             import  Import triple(s)\n";
	print "             insert  Insert triple(s)\n";
	print "             prompt  Prompt value from user if necessary\n";
	print "              query  Query with my original format (example: \$a->B->\$c)\n";
	print "             select  Select triple(s)\n";
	print "             submit  Record new job submission from controlSubmit()\n";
	print "               test  For development purpose\n";
	print "             update  Update triple(s)\n";
	print "\n";
	print "Commands of file statistics:\n";
	print "           filesize  Record file size of a file\n";
	print "          filestats  Record filesize/linecount/seqcount/md5 of a file\n";
	print "          linecount  Line count of a file\n";
	print "                md5  Record md5 of a file\n";
	print "           seqcount  Record sequence count of a file\n";
	print "\n";
	print "Options:\n";
	print "     -d  database directory path (default='rdf')\n";
	print "     -f  input/output format (json,tsv)\n";
	print "     -h  show help message\n";
	print "     -q  quiet mode\n";
	print "     -s  separate delimiter (default='\t')\n";
	print "\n";
	print "   NOTE:  Use '%' for undefined subject/predicate/object.\n";
	print "   NOTE:  '%' is wildcard for subject/predicate/object.\n";
	print "   NOTE:  Need to specify database for most manipulations.\n";
	print "\n";
}
sub help_assign{
	print "\n";
	print "############################## assign ##############################\n";
	print "\n";
	print "Program: Insert SUB->PRE->OBJ when SUB->PRE is not assgined yet.\n";
	print "\n";
	print "Usage: perl $program_name [Options] assign SUB PRE OBJ";
	print "\n";
	print "\n";
	print "\n";
}
sub help_config{
	print "\n";
	print "############################## config ##############################\n";
	print "\n";
	print "Usage: perl $program_name [Options] config FILE ARG1 ARG2 ARG3";
	print "\n";
	print "       FILE  config file written in this \"sub->pre obj\" format:.\n";
	print "        ARG  Arguments passed to config in '\$1','\$2','\$3' format just like bash.\n";
	print "\n";
}
sub help_prompt{
	print "\n";
	print "############################## prompt ##############################\n";
	print "\n";
	print "Usage: perl $program_name [Options] prompt [question]";
	print "\n";
	print "Options: -i  Input query for select from database in '\$sub->\$pred->\$obj' format.\n";
	print "         -o  Output query to prompt in '\$sub->\$pred->\$obj' format.\n";
	print "\n";
	print "############################## Examples ##############################\n";
	print "\n";
	print "(1) perl $program_name -o 'A->B->\$answer' prompt 'What is your name?'\n";
	print "  - Insert 'A->B->C' triple, if 'A->B->?' is not found in the RDF database.\n";
	print "\n";
	print "(2) perl $program_name -i 'A->B->C' -o 'C->D->\$answer' prompt 'What is your name?'\n";
	print "  - Ask question if 'A->B->C' is found and 'C->D->?' is not found and insert 'C->D->\$answer' triple.\n";
	print "\n";
}
############################## MAIN ##############################
if(defined($opt_h)||scalar(@ARGV)==0){
	my $command=shift(@ARGV);
	if($command eq"config"){help_config();}
	elsif($command eq"prompt"){help_prompt();}
	else{help();}
	exit();
}
my $command=shift(@ARGV);
my $moiraiDir=(defined($opt_d))?$opt_d:"moirai";
my $jobDir="$moiraiDir/ctrl/job";
my $dbDir="$moiraiDir/db";
my $logDir="$moiraiDir/log";
my $errorDir="$logDir/error";
my $md5cmd=which('md5sum');
if(!defined($md5cmd)){$md5cmd=which('md5');}
if($command eq"test"){test();}
elsif($command eq"assign"){commandAssign(@ARGV);}
elsif($command eq"config"){commandConfig(@ARGV);}
elsif($command eq"delete"){commandDelete(@ARGV);}
elsif($command eq"export"){commandExport(@ARGV);}
elsif($command eq"filesize"){commandFilesize(@ARGV);}
elsif($command eq"filestats"){commandFileStats(@ARGV);}
elsif($command eq"import"){commandImport(@ARGV);}
elsif($command eq"insert"){commandInsert(@ARGV);}
elsif($command eq"linecount"){commandLinecount(@ARGV);}
elsif($command eq"md5"){commandMd5(@ARGV);}
elsif($command eq"prompt"){commandPrompt(@ARGV);}
elsif($command eq"query"){commandQuery(@ARGV);}
elsif($command eq"select"){commandSelect(@ARGV);}
elsif($command eq"seqcount"){commandSeqcount(@ARGV);}
elsif($command eq"submit"){commandSubmit(@ARGV);}
elsif($command eq"update"){commandUpdate(@ARGV);}
############################## checkBinary ##############################
sub checkBinary{
	my $file=shift();
	while(-l $file){$file=readlink($file);}
	my $result=`file --mime $file`;
	if($result=~/charset\=binary/){return 1;}
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
############################## checkRdfQuery ##############################
sub checkRdfQuery{
	my $queries=shift();
	foreach my $query(split(/,/,$queries)){
		my @tokens=split(/->/,$query);
		if(scalar(@tokens)!=3){return;}
	}
	return 1;
}
############################## commandAssign ##############################
sub commandAssign{
	my @args=@_;
	if(scalar(@args)<3){print STDERR "Please specify SUB PRE OBJ\n";return;}
	my $sub=shift(@args);
	my $pre=shift(@args);
	my $obj=shift(@args);
	my @lines=();
	my $results=tripleSelect($sub,$pre,"%");
	my $total=0;
	if(scalar(keys(%{$results}))==0){$total=insertJson({$sub=>{$pre=>$obj}});}
	if(!defined($opt_q)){print "inserted $total\n";}
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
	my $delim=defined($opt_s)?$opt_s:"\t";
	my $limit=`ulimit -n`;
	chomp($limit);
	while(<STDIN>){
		chomp;
		my ($s,$p,$o)=split(/$delim/);
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
		if(!-e $dbDir){prepareDbDir();}
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
			if(!-e $dbDir){prepareDbDir();}
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
############################## commandPrompt ##############################
sub commandPrompt{
	my ($arguments,$userdefined)=handleArguments(@ARGV);
	my $results=[[],[{}]];
	if(defined($opt_i)){
		my $query=$opt_i;
		while(my($key,$val)=each(%{$userdefined})){$query=~s/\$$key/$val/g;}
		checkInputOutput($query);
		if(checkRdfQuery($query)){
			my @hashs=queryResults($query);
			my $temp={};
			foreach my $hash(@hashs){foreach my $key(keys(%{$hash})){$temp->{$key}=1;}}
			my @keys=keys(%{$temp});
			$results=[\@keys,\@hashs];
		}else{
			my $keys=handleInputOutput($query);
			foreach my $key(@{$keys}){
				foreach my $k(@{$keys}){if($k=~/^\$/){$k="%";}}
				my $results=tripleSelect(@{$key});
				if(scalar(keys(%{$results}))==0){return;}
			}
		}
	}
	my @questions=@{$arguments};
	my $triples={};
	if(defined($opt_o)){
		checkInputOutput($opt_o);
		my $insertKeys=handleInputOutput($opt_o);
		my @keys=@{$results->[0]};
		my @values=@{$results->[1]};
		foreach my $insertKey(@{$insertKeys}){
			foreach my $value(@values){
				my @insert=($insertKey->[0],$insertKey->[1],$insertKey->[2]);
				foreach my $key(@keys){my $val=$value->{$key};for(@insert){s/\$$key/$val/g;}}
				while(my($key,$val)=each(%{$userdefined})){for(@insert){s/\$$key/$val/g;}}
				my @array=@insert;
				for(@array){if(/^\$/){$_="%";}}
				my $results=tripleSelect(@array);
				if(scalar(keys(%{$results}))>0){next;}
				my $default;
				my @options;
				for(my $i=0;$i<scalar(@questions);$i++){
					my $question=$questions[$i];
					foreach my $key(@keys){my $val=$value->{$key};$question=~s/\$$key/$val/g;}
					while(my($key,$val)=each(%{$userdefined})){$question=~s/\$$key/$val/g;}
					if($question=~/\[default=(.+)\]/){$default=$1;}
					if($question=~/\{(.+)\}/){@options=split(/\|/,$1);}
					if($i>0){print "\n";}
					print "$question";
				}
				my $answer=<STDIN>;
				chomp($answer);
				if($answer eq""&&defined($default)){$answer=$default;}
				foreach my $token(@insert){$token=~s/\$answer/$answer/g;}
				foreach my $token(@insert){$token=~s/\$_/$answer/g;}
				if(!exists($triples->{$insert[0]})){$triples->{$insert[0]}={};}
				if(!exists($triples->{$insert[0]}->{$insert[1]})){$triples->{$insert[0]}->{$insert[1]}=$insert[2];}
				elsif(ref($triples->{$insert[0]}->{$insert[1]})eq"ARRAY"){push(@{$triples->{$insert[0]}->{$insert[1]}},$insert[2]);}
				else{$triples->{$insert[0]}->{$insert[1]}=[$triples->{$insert[0]}->{$insert[1]},$insert[2]];}
			}
		}
	}
	if(scalar(keys(%{$triples}))>0){insertJson($triples);}
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
############################## commandSelect ##############################
sub commandSelect{
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $results=tripleSelect($subject,$predicate,$object);
	if(!defined($opt_f)){$opt_f="tsv";}
	if($opt_f eq "tsv"){printTripleInTSVFormat($results);}
	elsif($opt_f eq "json"){print jsonEncode($results)."\n";}
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
	my $id="w".getDatetime();
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
		my $hash={};
		foreach my $s(keys(%{$json})){
			if(!exists($json->{$s}->{$predicate})){next;}
			my $o=$json->{$s}->{$predicate};
			if(ref($o)eq"ARRAY"){$hash->{$s}=$o;}
			else{$hash->{$s}=[$o];}
		}
		my $updated=0;
		my $count=0;
		my $file=getFileFromPredicate($predicate);
		if($file=~/\.gz$/){next;}
		elsif($file=~/\.bz2$/){next;}
		my $reader=openFile($file);
		my ($writer,$tempfile)=tempfile();
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if(!exists($hash->{$s})){
				print $writer "$s\t$o\n";$count++;
			}
		}
		foreach my $s(keys(%{$hash})){
			if(!exists($hash->{$s})){next;}
			foreach my $o(@{$hash->{$s}}){
				print $writer "$s\t$o\n";$updated++;$count++;
			}
		}
		close($writer);
		close($reader);
		if($count==0){unlink($file);}
		elsif($updated>0){
			my ($writer2,$tempfile2)=tempfile();
			close($writer2);
			chmod(0777,$tempfile2);
			system("sort $tempfile -u > $tempfile2");
			if(!-e $dbDir){prepareDbDir();}
			system("mv $tempfile2 $file");
		}
		$total+=$updated;
	}
	return $total;
}
############################## commandConfig ##############################
sub commandConfig{
	my @args=@_;
	my $file=shift(@args);
	if(!defined($file)){
		print STDERR "\n";
		print STDERR "ERROR: Please specify config file\n";
		print STDERR "perl rdf.pl config FILE\n";
		print STDERR "\n";
		exit(1);
	}
	open(IN,$file);
	my $numbers={};
	while(<IN>){
		chomp;s/\r//g;
		if(/^#/){next;}
		if(/\$(\d+)/){$numbers->{$1}=$_;}
	}
	my @keys=sort{$a<=>$b}keys(%{$numbers});
	my $nargs=$keys[scalar(@keys)-1];
	close(IN);
	if(scalar(@args)<$nargs){
		print STDERR "\n";
		print STDERR "ERROR: Numbers of arguments doesn't match\n";
		print STDERR ">$file\n";
		for(my $i=0;$i<scalar(@keys);$i++){print $numbers->{$keys[$i]}."\n";}
		print STDERR "\n";
		print STDERR "perl rdf.pl config FILE";
		for(my $i=0;$i<$nargs;$i++){print " ARG".($i+1);}
		print STDERR "\n";
		print STDERR "\n";
		exit(1);
	}
	my $vars={};
	for(my $i=0;$i<scalar(@args);$i++){$vars->{"\$".($i+1)}=$args[$i];}
	my $json={};
	open(IN,$file);
	while(<IN>){
		chomp;s/\r//g;
		if(/^#/){next;}
		my ($key,$val)=split(/\t+/,$_);
		my @tokens=split(/\-\>/,$key);
		push(@tokens,$val);
		if(scalar(@tokens)>2){
			foreach my $token(@tokens){while(my($k,$v)=each(%{$vars})){$token=~s/$k/$v/g;}}
			if(!exists($json->{$tokens[0]})){$json->{$tokens[0]}={};}
			if(!exists($json->{$tokens[0]}->{$tokens[1]})){$json->{$tokens[0]}->{$tokens[1]}=$tokens[2];}
			elsif(ref($json->{$tokens[0]}->{$tokens[1]})eq"ARRAY"){push(@{$json->{$tokens[0]}->{$tokens[1]}},$tokens[2]);}
			else{$json->{$tokens[0]}->{$tokens[1]}=[$json->{$tokens[0]}->{$tokens[1]},$tokens[2]];}
		}else{
			if($key!~/^\$/){$key="\$$key";}
			if($key=~/^\$/){$key="\\$key";}
			if(exists($vars->{$val})){$vars->{$key}=$vars->{$val};}
			else{$vars->{$key}=$val;}
		}
	}
	close(IN);
	my $total=updateJson($json);
	if(!defined($opt_q)){print "updated $total\n";}
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
	mkdirs(dirname($path));
	open(OUT,">$path");
	foreach my $line(@lines){print OUT "$line\n";}
	close(OUT);
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
	my $dirname=substr($execid,1,8);
	if(-e "$errorDir/$execid.txt"){return "$errorDir/$execid.txt";}
	elsif(-e "$logDir/$dirname/$execid.txt"){return "$logDir/$dirname/$execid.txt";}
	elsif(-e "$logDir/$dirname.tgz"){return "$logDir/$dirname.tgz";}
}
############################## getFileFromPredicate ##############################
sub getFileFromPredicate{
	my $predicate=shift();
	my $dir=$dbDir;
	if($predicate=~/^(https?):\/\/(.+)$/){$predicate="$1/$2";}
	elsif($predicate=~/^(.+)\@(.+)\:(.+)/){$predicate="ssh/$1/$2/$3";}
	elsif($predicate=~/^(.+)\:(.+)$/){$dir="$1/db";$predicate=$2;}
	if($predicate=~/^(.+)#(.+)$/){$predicate=$1;}
	if($predicate=~/^(.+)\.json$/){$predicate=$1;}
	if($predicate=~/\%/){return $dir;}
	elsif(-e "$dir/$predicate.txt.gz"){return "$dir/$predicate.txt.gz";}
	elsif(-e "$dir/$predicate.txt.bz2"){return "$dir/$predicate.txt.bz2";}
	else{return "$dir/$predicate.txt";}
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
	elsif($dirname=~/^\//){$basename="$dirname/$basename";}
	elsif($dirname=~/^(.+)\/db\/(.+)$/){$basename="$1:$2/$basename";}
	if($basename=~/^(https?)\/(.+)$/){$basename="$1://$2";}
	elsif($basename=~/^ssh\/(.+?)\/(.+?)\/(.+)$/){$basename="$1\@$2:$3";}
	if($basename=~/^(.+)\.te?xt\.gz(ip)?$/){return $1;}
	elsif($basename=~/^(.+)\.te?xt\.bz(ip)?2$/){return $1;}
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
############################## handleInputOutput ##############################
sub handleInputOutput{
	my $statement=shift();
	my @array=();
	my @statements;
	if(ref($statement) eq "ARRAY"){@statements=@{$statement};}
	else{@statements=split(",",$statement);}
	foreach my $line(@statements){my @tokens=split(/\-\>/,$line);push(@array,\@tokens);}
	return \@array;
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
	my @files=listFiles(".txt\$",undef,-1,$jobDir);
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
	#if($predicate=~/^https?:\/\/(.+)$/){$predicate=$1;}
	my @results=();
	foreach my $file(@files){
		if($file=~/db\/$predicate\.te?xt$/){push(@results,$file);}
		elsif($file=~/db\/$predicate\.te?xt\.gz(ip)?$/){push(@results,$file);}
		elsif($file=~/db\/$predicate\.te?xt\.bz(ip)?2$/){push(@results,$file);}
	}
	return @results;
}
############################## openFile ##############################
sub openFile{
	my $path=shift();
	if($path=~/\.gz(ip)?$/){return IO::File->new("gzip -cd $path|");}
	elsif($path=~/\.bz(ip)?2$/){return IO::File->new("bzip2 -cd $path|");}
	elsif($path=~/\.bam$/){return IO::File->new("samtools view $path|");}
	elsif($path=~/\.tgz$/){return IO::File->new("tar -zxOf $path|");}
	else{return IO::File->new($path);}
}
############################## prepareDbDir ##############################
sub prepareDbDir{
	mkdir($moiraiDir);
	chmod(0777,$moiraiDir);
	mkdir($dbDir);
	chmod(0777,$dbDir);
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
############################## printTripleInTSVFormat ##############################
sub printTripleInTSVFormat{
	my $result=shift();
	foreach my $sub(sort{$a cmp $b}keys(%{$result})){
		foreach my $pre(sort{$a cmp $b}keys(%{$result->{$sub}})){
			my $obj=$result->{$sub}->{$pre};
			if(ref($obj) eq"ARRAY"){foreach my $o(@{$obj}){print "$sub\t$pre\t$o\n";}}
			else{print "$sub\t$pre\t$obj\n";}
		}
	}
}
############################## queryResults ##############################
sub queryResults{
	my @queries=@_;
	my $values={};
	foreach my $query(@queries){
		my ($s,$p,$o)=split(/\-\>/,$query);
		my @array=queryVariables($s,$p,$o);
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
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
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
	my $dir=$dbDir;
	if($predicate=~/^(\S+)\:(\S+)$/){# dir2:dirname/basename.txt
		$dir="$1/db";
		$predicate=$2;
	}elsif($predicate=~/^\//){# /dirname/basename.txt
		$dir=$predicate;
	}
	my @files=listFiles(undef,undef,-1,$dir);
	my @files=narrowDownByPredicate($predicate,@files);
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
############################## setupPredicate ##############################
sub setupPredicate{
	my $predicate=shift();
	my $path=getFileFromPredicate($predicate);
	if($predicate=~/^https?\:\/\//){# https://dirname/basename.txt
		mkdirs(dirname($path));
		getstore("$predicate.txt",$path);
		return $path;
	}elsif($predicate=~/^.+\@.+\:.+/){# ah3q@dgt-ac4:dirname/basename.txt
		my $result=system("find $predicate.txt");

		system("rsync $predicate.txt $path");
		return $path;
	}else{
		return $path;
	}
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
############################## tripleSelect ##############################
sub tripleSelect{
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	if(!defined($subject)){$subject="%";}
	if(!defined($predicate)){$predicate="%";}
	if(!defined($object)){$object="%";}
	$subject=~s/\%/.*/g;
	$predicate=~s/\%/.*/g;
	$object=~s/\%/.*/g;
	my @files=listFiles(undef,undef,-1,$dbDir);
	my @files=narrowDownByPredicate($predicate,@files);
	my $results={};
	foreach my $file(@files){
		my $p=getPredicateFromFile($file);
		if(!-e $file){next;}
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if($s!~/^$subject$/){next;}
			if($o!~/^$object$/){next;}
			if(!exists($results->{$s})){$results->{$s}={};}
			if(!exists($results->{$s}->{$p})){$results->{$s}->{$p}=$o;}
			elsif(ref($results->{$s}->{$p})eq"ARRAY"){push(@{$results->{$s}->{$p}},$o);}
			else{$results->{$s}->{$p}=[$results->{$s}->{$p},$o];}
		}
		close($reader);
	}
	return $results;
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
############################## test ##############################
sub test{
	testSub("getPredicateFromFile(\"$dbDir/A.txt\")","A");
	testSub("getPredicateFromFile(\"$dbDir/B/A.txt\")","B/A");
	testSub("getPredicateFromFile(\"$dbDir/B/A.txt.gz\")","B/A");
	testSub("getPredicateFromFile(\"$dbDir/B/A.txt.bz2\")","B/A");
	testSub("getPredicateFromFile(\"/A/B/C/D/E.txt\")","/A/B/C/D/E");
	testSub("getPredicateFromFile(\"test2/db/B/A.txt\")","test2:B/A");
	testSub("getPredicateFromFile(\"$dbDir/https/moirai2.github.io/schema/daemon/bash.txt\")","https://moirai2.github.io/schema/daemon/bash");
	testSub("getPredicateFromFile(\"$dbDir/http/localhost/~ah3q/gitlab/moirai2dgt/geneBodyCoverage/db/allImage.txt\")","http://localhost/~ah3q/gitlab/moirai2dgt/geneBodyCoverage/db/allImage");
	testSub("getPredicateFromFile(\"$dbDir/ssh/ah3q/dgt-ac4/A/B/C.txt\")","ah3q\@dgt-ac4:A/B/C");
	testSub("getPredicateFromFile(\"$dbDir/ssh/ah3q/dgt-ac4/A/B/C.txt.bz2\")","ah3q\@dgt-ac4:A/B/C");
	testSub("getFileFromPredicate(\"A/B%\")","$dbDir");
	testSub("getFileFromPredicate(\"A\")","$dbDir/A.txt");
	testSub("getFileFromPredicate(\"A/B\")","$dbDir/A/B.txt");
	createFile("$dbDir/A/B.txt","A\tA1");
	system("gzip $dbDir/A/B.txt");
	testSub("getFileFromPredicate(\"A/B\")","$dbDir/A/B.txt.gz");
	system("rm $dbDir/A/B.txt.gz");
	testSub("getFileFromPredicate(\"A/B#CDF\")","$dbDir/A/B.txt");
	testSub("getFileFromPredicate(\"A/B.json\")","$dbDir/A/B.txt");
	testSub("getFileFromPredicate(\"A/B.json#D\")","$dbDir/A/B.txt");
	testSub("getFileFromPredicate(\"test2:A/B\")","test2/db/A/B.txt");
	testSub("getFileFromPredicate(\"http://A/B\")","$dbDir/http/A/B.txt");
	testSub("getFileFromPredicate(\"https://A/B/C/D\")","$dbDir/https/A/B/C/D.txt");
	testSub("getFileFromPredicate(\"http://localhost/~ah3q/gitlab/moirai2dgt/geneBodyCoverage/db/allImage\")","$dbDir/http/localhost/~ah3q/gitlab/moirai2dgt/geneBodyCoverage/db/allImage.txt");
	testSub("getFileFromPredicate(\"ah3q\\\@dgt-ac4:A/B\")","$dbDir/ssh/ah3q/dgt-ac4/A/B.txt");
	rmdir("moirai/db/A/");
	rmdir("moirai/db/");
	rmdir("moirai/");
	mkdir("test");
	mkdir("test/db");
	createFile("test/db/id.txt","A\tA1","B\tB1","C\tC1","D\tD1");
	createFile("test/db/name.txt","A1\tAkira","B1\tBen","C1\tChris","D1\tDavid");
	testCommand("perl rdf.pl linecount test/db/id.txt","test/db/id.txt\tfile/linecount\t4");
	testCommand("perl rdf.pl md5 test/db/id.txt","test/db/id.txt\tfile/md5\t131e61dab9612108824858dc497bf713");
	testCommand("perl rdf.pl filesize test/db/id.txt","test/db/id.txt\tfile/filesize\t20");
	testCommand("perl rdf.pl seqcount test/db/id.txt","test/db/id.txt\tfile/seqcount\t4");
	testCommand("perl rdf.pl -d test select ","A\tid\tA1\nA1\tname\tAkira\nB\tid\tB1\nB1\tname\tBen\nC\tid\tC1\nC1\tname\tChris\nD\tid\tD1\nD1\tname\tDavid");
	testCommand("perl rdf.pl -d test select A","A\tid\tA1");
	testCommand("perl rdf.pl -d test select % id","A\tid\tA1\nB\tid\tB1\nC\tid\tC1\nD\tid\tD1");
	testCommand("perl rdf.pl -d test select % % B1","B\tid\tB1");
	testCommand("perl rdf.pl -d test select A%","A\tid\tA1\nA1\tname\tAkira");
	testCommand("perl rdf.pl -d test select A% n%","A1\tname\tAkira");
	testCommand("perl rdf.pl -d test select % % A%","A\tid\tA1\nA1\tname\tAkira");
	testCommand("perl rdf.pl -d test select %1","A1\tname\tAkira\nB1\tname\tBen\nC1\tname\tChris\nD1\tname\tDavid");
	testCommand("perl rdf.pl -d test delete A%","deleted 2");
	testCommand("perl rdf.pl -d test select ","B\tid\tB1\nB1\tname\tBen\nC\tid\tC1\nC1\tname\tChris\nD\tid\tD1\nD1\tname\tDavid");
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
	testCommand("perl rdf.pl -d test update < test/update.txt","updated 2");
	testCommand("perl rdf.pl -d test select A id","A\tid\tA3");
	testCommand("perl rdf.pl -d test select B id","B\tid\tB3");
	createFile("test/update.json","{\"A\":{\"name\":\"Akira\"},\"B\":{\"name\":\"Bob\"}}");
	testCommand("perl rdf.pl -d test -f json update < test/update.json","updated 2");
	testCommand("perl rdf.pl -d test select % name","A\tname\tAkira\nB\tname\tBob\nT\tname\tTsunami");
	testCommand("perl rdf.pl -d test delete < test/update.txt","deleted 2");
	testCommand("perl rdf.pl -d test select % id","C\tid\tC1\nC\tid\tC2\nD\tid\tD1\nD\tid\tD2");
	testCommand("perl rdf.pl -d test -f json delete < test/update.json","deleted 2");
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
	testCommand("perl rdf.pl -d test/A insert id0 name Tsunami","inserted 1");
	testCommand("perl rdf.pl -d test/B insert id0 country Japan","inserted 1");
	testCommand("perl rdf.pl -d test/A query '\$id->name->\$name'","id\tname\nid0\tTsunami");
	testCommand("perl rdf.pl -d test/B query '\$id->country->\$country'","country\tid\nJapan\tid0");
	testCommand("perl rdf.pl -d test/A query '\$id->name->\$name,\$id->test/B:country->\$country'","country\tid\tname\nJapan\tid0\tTsunami");
	testCommand("perl rdf.pl -d test/A query '\$id->test/A:name->\$name,\$id->test/B:country->\$country'","country\tid\tname\nJapan\tid0\tTsunami");
	testCommand("perl rdf.pl query '\$id->test/A:name->\$name,\$id->test/B:country->\$country'","country\tid\tname\nJapan\tid0\tTsunami");
	testCommand("perl rdf.pl -d test/A delete % % %","deleted 1");
	testCommand("perl rdf.pl -d test/B delete % % %","deleted 1");
	rmdir("test/A/db");
	rmdir("test/B/db");
	rmdir("test/B/log");
	rmdir("test/A");
	rmdir("test/B");
	testCommand("perl rdf.pl -q -d test insert A B C","");
	testCommand("perl rdf.pl -d test select","A\tB\tC");
	testCommand("perl rdf.pl -f tsv -d test select","A\tB\tC");
	testCommand("perl rdf.pl -d test insert A B D","inserted 1");
	testCommand("perl rdf.pl -d test -f tsv select","A\tB\tC\nA\tB\tD");
	testCommand("perl rdf.pl -d test -f json select","{\"A\":{\"B\":[\"C\",\"D\"]}}");
	testCommand("perl rdf.pl -d test delete % % %","deleted 2");
	testCommand("perl rdf.pl -q -d test assign A B C","");
	testCommand("perl rdf.pl -f json -d test select","{\"A\":{\"B\":\"C\"}}");
	testCommand("perl rdf.pl -d test assign A B C","inserted 0");
	testCommand("perl rdf.pl -q -d test delete % % %","");
	rmdir("test/db");
	rmdir("test");
}