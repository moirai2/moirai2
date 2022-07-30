#!/usr/bin/perl
use strict 'vars';
use Cwd;
use File::Basename;
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
my($program_name,$prgdir,$program_suffix)=fileparse($0);
$prgdir=substr($prgdir,0,-1);
my $program_version="2022/07/24";
############################## OPTIONS ##############################
use vars qw($opt_d $opt_f $opt_g $opt_G $opt_h $opt_i $opt_o $opt_q $opt_r $opt_s $opt_x);
getopts('d:f:g:G:hi:qo:r:s:w:x');
############################## HELP ##############################
sub help{
	print "\n";
	print "############################## HELP ##############################\n";
	print "\n";
	print "Program: Utilities for handling a triple text-based database.\n";
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
	print "              split  split GTF and other files\n";
	print "               test  For development purpose\n";
	print "          timestamp  Get timestamp of specified predicate\n";
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
	print "     -d  database directory path (default='moirai')\n";
	print "     -f  input/output format (json,tsv)\n";
	print "     -h  show help message\n";
	print "     -q  quiet mode\n";
	print "     -s  separate delimiter (default='\t')\n";
	print "     -w  Work ID\n";
	print "     -x  Expand query results (default='limit')\n";
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
############################## FILE ##############################
my $fileSuffixes={
	"(\\.te?xt)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitTriple,
	"(\\.f(ast)?a)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitFasta,
	"(\\.f(ast)?q)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitFastq,
	"(\\.tsv)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitTsv,
	"(\\.csv)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitCsv,
	"(\\.gtf)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitGtf,
	"(\\.bed)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitBed,
	"(\\.sam)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitBam,
	"\\.runinfo\\.csv(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitRunInfo,
	"\\.openprot\\.tsv(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitTsvWithLabel,
	"\\.bam?\$"=>\&splitBam
};
############################## MAIN ##############################
my $splitBamLabels=["qname","flag","rname","pos","mapq","cigar","rnext","pnext","tlen","seq","qual"];
if(defined($opt_h)||scalar(@ARGV)==0){
	my $command=shift(@ARGV);
	if($command eq"config"){help_config();}
	elsif($command eq"prompt"){help_prompt();}
	else{help();}
	exit(0);
}
my $command=shift(@ARGV);
my $rootdir=absolutePath(".");
my $dbdir=defined($opt_d)?checkDatabaseDirectory($opt_d):".";
my $moiraidir=".moirai2";
my $md5cmd=which('md5sum');
if(!defined($md5cmd)){$md5cmd=which('md5');}
if($command=~/^assign$/i){commandAssign(@ARGV);}
elsif($command=~/^config$/i){commandConfig(@ARGV);}
elsif($command=~/^delete$/i){commandDelete(@ARGV);}
elsif($command=~/^export$/i){commandExport(@ARGV);}
elsif($command=~/^filesize$/i){commandFilesize(@ARGV);}
elsif($command=~/^filestats$/i){commandFileStats(@ARGV);}
elsif($command=~/^import$/i){commandImport(@ARGV);}
elsif($command=~/^insert$/i){commandInsert(@ARGV);}
elsif($command=~/^linecount$/i){commandLinecount(@ARGV);}
elsif($command=~/^md5$/i){commandMd5(@ARGV);}
elsif($command=~/^prompt$/i){commandPrompt(@ARGV);}
elsif($command=~/^query$/i){commandQuery(@ARGV);}
elsif($command=~/^select$/i){commandSelect(@ARGV);}
elsif($command=~/^seqcount$/i){commandSeqcount(@ARGV);}
elsif($command=~/^sortsubs$/i){sortSubs(@ARGV);}
elsif($command=~/^split$/i){commandSplit(@ARGV);}
elsif($command=~/^test$/i){test(@ARGV);}
elsif($command=~/^timestamp$/i){commandTimestamp(@ARGV);}
elsif($command=~/^unusedsubs$/i){unusedSubs(@ARGV);}
elsif($command=~/^update$/i){commandUpdate(@ARGV);}
############################## URLs ##############################
my $urls={};
$urls->{"daemon/command"}="https://moirai2.github.io/schema/daemon/command";
$urls->{"daemon/execid"}="https://moirai2.github.io/schema/daemon/execid";
$urls->{"daemon/execute"}="https://moirai2.github.io/schema/daemon/execute";
$urls->{"daemon/timecompleted"}="https://moirai2.github.io/schema/daemon/timecompleted";
$urls->{"daemon/timeended"}="https://moirai2.github.io/schema/daemon/timeended";
$urls->{"daemon/processtime"}="https://moirai2.github.io/schema/daemon/processtime";
$urls->{"daemon/timeregistered"}="https://moirai2.github.io/schema/daemon/timeregistered";
$urls->{"daemon/timestarted"}="https://moirai2.github.io/schema/daemon/timestarted";
$urls->{"daemon/workdir"}="https://moirai2.github.io/schema/daemon/workdir";
my $revUrls={};
while(my($key,$url)=each(%{$urls})){$revUrls->{$url}=$key;}
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
############################## checkBinary ##############################
sub checkBinary{
	my $file=shift();
	while(-l $file){$file=readlink($file);}
	my $result=`file --mime $file`;
	if($result=~/charset\=binary/){return 1;}
}
############################## checkDatabaseDirectory ##############################
sub checkDatabaseDirectory{
	my $directory=shift();
	if($directory=~/\.\./){
		print STDERR "ERROR: Please don't use '..' for moirai database directory\n";
		exit(1);
	}elsif($directory=~/^\//){
		print STDERR "ERROR??: moirai directory '$directory' have to be relative to a root directory\n";
		exit(1);
	}
	return $directory;
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
############################## commandConfig ##############################
sub commandConfig{
	my @args=@_;
	my $file=shift(@args);
	if(!defined($file)){
		print STDERR "\n";
		print STDERR "ERROR: Please specify config file\n";
		print STDERR "perl $prgdir/rdf.pl config FILE\n";
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
		print STDERR "perl $prgdir/rdf.pl config FILE";
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
############################## commandDelete ##############################
sub commandDelete{
	my $json;
	if(scalar(@ARGV)>0){
		$json=tripleSelect(@ARGV);
	}else{
		if(!defined($opt_f)){$opt_f="tsv";}
		my $reader=IO::File->new("-");
		$json=($opt_f eq "tsv")?tsvToJson($reader):readJson($reader);
		close($reader);
	}
	my $total=deleteJson($json);
	if($total>0){utime(undef,undef,$moiraidir);utime(undef,undef,$dbdir);}
	if(!defined($opt_q)){print "deleted $total\n";}
}
sub deleteJson{
	my $json=shift();
	foreach my $sub(keys(%{$json})){
		foreach my $pre(keys(%{$json->{$sub}})){
			my $hash={};
			my $obj=$json->{$sub}->{$pre};
			if(ref($obj)eq"ARRAY"){
				foreach my $o(@{$obj}){$hash->{$o}=1;}
			}else{$hash->{$obj}=1;}
			$json->{$sub}->{$pre}=$hash;
		}
	}
	my $total=0;
	my @predicates=getPredicatesFromJson($json);
	foreach my $predicate(@predicates){
		my $deleted=0;
		my $count=0;
		my $file=getFileFromPredicate($predicate);
		if(-d $file){next;}
		elsif($file=~/\.gz$/){next;}
		elsif($file=~/\.bz2$/){next;}
		elsif(!-e $file){next;}
		my $pre=getPredicateFromFile($file);
		my $reader=openFile($file);
		my ($writer,$tempfile)=tempfile();
		while(<$reader>){
			chomp;
			my @tokens=split(/\t/);
			if(scalar(@tokens)==3){
				my $s=$tokens[0];
				my $p="$pre#".$tokens[1];
				my $o=$tokens[2];
				if(exists($json->{$s}->{$p}->{$o})){$deleted++;}
				else{print $writer join("\t",@tokens)."\n";$count++;}
			}else{
				my $s=$tokens[0];
				my $o=$tokens[1];
				if(exists($json->{$s}->{$pre}->{$o})){$deleted++;}
				else{print $writer join("\t",@tokens)."\n";$count++;}
			}
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
	if($target eq "db"){$result=loadDbToArray($dbdir);}
	elsif($target eq "network"){$result=loadDbToVisNetwork($dbdir);}
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
	if(scalar(@arguments)==0){push(@arguments,"-");}
	chomp($limit);
	foreach my $argument(@arguments){
		my $reader=openFile($argument);
		while(<$reader>){
			chomp;
			my ($s,$p,$o)=split(/$delim/);
			if(!defined($p)){next;}
			if(!defined($o)){next;}
			if(!exists($writers->{$p})&&!exists($excess->{$p})){
				my $file=getFileFromPredicate($p);
				if($file=~/\.gz$/){$writers->{$p}=undef;}
				elsif($file=~/\.bz2$/){$writers->{$p}=undef;}
				elsif(-d $file){$writers->{$p}=undef;}
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
		close($reader);
	}
	while(my($p,$writer)=each(%{$writers})){close($writer);}
	while(my($p,$array)=each(%{$excess})){
		my $file=getFileFromPredicate($p);
		if($file=~/\.gz$/){next;}
		elsif($file=~/\.bz2$/){next;}
		elsif(-d $file){next;}
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
		if(!-e $dbdir){prepareDbDir();}
		system("mv $tempfile2 $file");
	}
	if($total>0){utime(undef,undef,$moiraidir);utime(undef,undef,$dbdir);}
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
	if($total>0){utime(undef,undef,$moiraidir);utime(undef,undef,$dbdir);}
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
		elsif(-d $file){$file="$file.txt";}
		my $anchor;
		if($predicate=~/#(.+)$/){$anchor=$1;}
		my ($writer,$tempfile)=tempfile();
		if(-e $file){
			my $reader=openFile($file);
			while(<$reader>){chomp;print $writer "$_\n";$count++;}
			close($reader);
		}else{mkdirs(dirname($file));}
		foreach my $s(keys(%{$json})){
			if(!exists($json->{$s}->{$predicate})){next;}
			my $object=$json->{$s}->{$predicate};
			if(defined($anchor)){
				if(ref($object)eq"ARRAY"){foreach my $o(@{$object}){print $writer "$s\t$anchor\t$o\n";$inserted++;$count++;}}
				else{print $writer "$s\t$anchor\t$object\n";$inserted++;$count++;}
			}else{
				if(ref($object)eq"ARRAY"){foreach my $o(@{$object}){print $writer "$s\t$o\n";$inserted++;$count++;}}
				else{print $writer "$s\t$object\n";$inserted++;$count++;}
			}
		}
		close($writer);
		if($count==0){unlink($file);}
		elsif($inserted>0){
			my ($writer2,$tempfile2)=tempfile();
			close($writer2);
			chmod(0777,$tempfile2);
			system("sort $tempfile -u > $tempfile2");
			if(!-e $dbdir){prepareDbDir();}
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
			my @hashs=queryResults($opt_x,$query);
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
	my $delim=defined($opt_s)?$opt_s:",";
	my @queries=();
	foreach my $argv(@ARGV){push(@queries,splitQueries($argv));}
	if(scalar(@queries)==0){while(<STDIN>){chomp;push(@queries,split(','));}}
	my @results=queryResults($opt_x,@queries);
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
				if(ref($value)eq"ARRAY"){$line.=join($delim,@{$value});}
				else{$line.=$value;}
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
############################## commandSplit ##############################
sub commandSplit{
	my $utility=shift(@ARGV);
	if($utility eq "gtf"){commandSplitGtfByFeature(@ARGV);}
}
############################## commandSplitGtfByFeature ##############################
sub commandSplitGtfByFeature{
	my $file=shift();
	my $outdir=shift();
	if(!defined($outdir)){
		my $basename=basename($file);
		if($basename=~/^(.+)\.gtf\.gz(ip)?$/){$basename=$1;}
		elsif($basename=~/^(.+)\.gtf\.bz(ip)?2$/){$basename=$1;}
		elsif($basename=~/^(.+)\.gtf\.zip$/){$basename=$1;}
		$outdir="$dbdir/$basename";
	}
	mkdirs($outdir);
	my $reader=openFile($file);
	my $writers={};
	while(<$reader>){
		chomp;
	    my @tokens=split(/\t/);
		my $feature=$tokens[2];
		if(!exists($writers->{$feature})){
			my $output="$outdir/$feature.gtf.gz";
			$writers->{$feature}=IO::File->new("|gzip -c>$output");
		}
		my $writer=$writers->{$feature};
		print $writer "$_\n";
	}
	close($reader);
	foreach my $writer(values(%{$writers})){close($writer);}
}
############################## commandTimestamp ##############################
sub commandTimestamp{
	my @predicates=@_;
	my $timestamp;
	foreach my $predicate(@predicates){
		$predicate=~s/\$\w+/\*/g;
		my @files=`ls $dbdir/$predicate.* 2>/dev/null`;
		foreach my $file(@files){chomp($file);}
		foreach my $file(@files){
			my $t=checkTimestamp($file);
			if(!defined($timestamp)){$timestamp=$t;}
			elsif($t>$timestamp){$timestamp=$t;}
		}
	}
	print "$timestamp\n";
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
	if($total>0){utime(undef,undef,$moiraidir);utime(undef,undef,$dbdir);}
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
		my $anchor;
		if($predicate=~/#(.+)$/){$anchor=$1;}
		my $file=getFileFromPredicate($predicate);
		if($file=~/\.gz$/){next;}
		elsif($file=~/\.bz2$/){next;}
		elsif(-d $file){next;}
		my $reader=openFile($file);
		my ($writer,$tempfile)=tempfile();
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if(!exists($hash->{$s})){
				print $writer "$s\t$o\n";$count++;
			}
		}
		close($reader);
		if(defined($anchor)){
			foreach my $s(keys(%{$hash})){
				if(!exists($hash->{$s})){next;}
				foreach my $o(@{$hash->{$s}}){
					print $writer "$s\t$anchor\t$o\n";$updated++;$count++;
				}
			}
		}else{
			foreach my $s(keys(%{$hash})){
				if(!exists($hash->{$s})){next;}
				foreach my $o(@{$hash->{$s}}){
					print $writer "$s\t$o\n";$updated++;$count++;
				}
			}
		}
		close($writer);
		if($count==0){unlink($file);}
		elsif($updated>0){
			my ($writer2,$tempfile2)=tempfile();
			close($writer2);
			chmod(0777,$tempfile2);
			system("sort $tempfile -u > $tempfile2");
			if(!-e $dbdir){prepareDbDir();}
			system("mv $tempfile2 $file");
		}
		$total+=$updated;
	}
	return $total;
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
############################## getChromSizeFile ##############################
sub getChromSizeFile{
	my $genomeAssembly=shift();
	return"https://hgdownload.soe.ucsc.edu/goldenPath/$genomeAssembly/bigZips/$genomeAssembly.chrom.sizes";
};
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
############################## getDirFromPredicate ##############################
sub getDirFromPredicate{
	my $predicate=shift();
	if($predicate=~/^(https?):\/\/(.+)$/){$predicate="$1/$2";}
	elsif($predicate=~/^(.+)\@(.+)\:(.+)/){$predicate="ssh/$1/$2/$3";}
	my $path="$dbdir/$predicate";
	return dirname($path);
}
############################## getFileFromPredicate ##############################
sub getFileFromPredicate{
	my $predicate=shift();
	my $dir=shift();
	if(!defined($dir)){$dir=$dbdir;}
	my $anchor;
	if($predicate=~/^(https?):\/\/(.+)$/){$predicate="$1/$2";}
	elsif($predicate=~/^(.+)\@(.+)\:(.+)/){$predicate="ssh/$1/$2/$3";}
	if($predicate=~/^(.+)#(.+)$/){$predicate=$1;$anchor=$2;}
	if($predicate=~/^(.+)\.json$/){$predicate=$1;}
	if($predicate=~/^(.+)\/$/){$predicate=$1;}
	if(-e "$dir/$predicate.txt"){return "$dir/$predicate.txt";}
	elsif(-e "$dir/$predicate.txt.gz"){return "$dir/$predicate.txt.gz";}
	elsif(-e "$dir/$predicate.txt.bz2"){return "$dir/$predicate.txt.bz2";}
	elsif(-d "$dir/$predicate"){return "$dir/$predicate";}
	if($predicate=~/^(.*)\%/){
		$predicate=$1;
		if($predicate=~/^(.+)\//){return "$dir/$1";}
		else{return $dir;}
	}elsif($predicate=~/^(.*)\/$/){
		$predicate=$1;
	}else{
		my @paths=`ls $dir/$predicate.* 2>/dev/null`;
		foreach my $path(@paths){chomp($path);}
		foreach my $path(@paths){
			foreach my $suffix(sort{$b cmp $a}keys(%{$fileSuffixes})){
				if($path=~/$suffix$/){return $path;}
			}
		}
	}
	return "$dir/$predicate.txt";
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
############################## getFilesFromQuery ##############################
sub getFilesFromQuery{
	my $predicate=shift();
	my $dir=shift();
	my @files=();
	if(!defined($dir)){$dir=$dbdir;}
	my $anchor;
	if($predicate=~/^(https?):\/\/(.+)$/){$predicate="$1/$2";}
	elsif($predicate=~/^(.+)\@(.+)\:(.+)/){$predicate="ssh/$1/$2/$3";}
	if($predicate=~/^(.+)#(.+)$/){$predicate=$1;$anchor=$2;}
	if($predicate=~/^(.+)\.json$/){$predicate=$1;}
	if($predicate=~/^(.+)\/$/){$predicate=$1;}
	if($predicate=~/\$/){
		$predicate=~s/(\$\w+)/\*/;
		push(@files,getFilesFromQuerySub("$dir/$predicate*"));
	}else{
		if(-e "$dir/$predicate.txt"){push(@files,"$dir/$predicate.txt");}
		elsif(-e "$dir/$predicate.txt.gz"){push(@files,"$dir/$predicate.txt.gz");}
		elsif(-e "$dir/$predicate.txt.bz2"){push(@files,"$dir/$predicate.txt.bz2");}
		elsif(-d "$dir/$predicate"){push(@files,getFilesFromQuerySub("$dir/$predicate"));}
		else{push(@files,getFilesFromQuerySub("$dir/$predicate*"));}
	}
	return wantarray?@files:\@files;
}
sub getFilesFromQuerySub{
	my $directory=shift();
	my @files=();
	my @paths=`ls $directory 2>/dev/null`;
	foreach my $path(@paths){
		chomp($path);
		if($directory!~/\*/){$path="$directory/$path";}
		foreach my $suffix(sort{$b cmp $a}keys(%{$fileSuffixes})){
			if($path=~/$suffix$/){push(@files,$path);}
		}
	}
	return @files;
}
############################## getGencodeAnnotationGtf ##############################
sub getGencodeAnnotationGtf{
	my $genome=shift();#human/mouse
	my $version=shift();
	return "http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_$version/gencode.v$version.annotation.gtf.gz";
}
############################## getGencodeLongNonCodingGtf ##############################
sub getGencodeLongNonCodingGtf{
	my $genome=shift();#human/mouse
	my $version=shift();#39,M30
	return "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_$genome/release_$version/gencode.v$version.long_noncoding_RNAs.gtf.gz";
}
############################## getGencodeLongNonCodingTranscriptFasta ##############################
sub getGencodeLongNonCodingTranscriptFasta{
	my $genome=shift();#human/mouse
	my $version=shift();#39,M30
	return "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_$genome/release_$version/gencode.v$version.lncRNA_transcripts.fa.gz";
}
############################## getGencodeProteinCodingTranscriptFasta ##############################
sub getGencodeProteinCodingTranscriptFasta{
	my $genome=shift();#human/mouse
	my $version=shift();#39,M30
	return "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_$genome/release_$version/gencode.v$version.pc_transcripts.fa.gz";
}
############################## getGencodeProteinCodingTranslationFasta ##############################
sub getGencodeProteinCodingTranslationFasta{
	my $genome=shift();#human/mouse
	my $version=shift();#39,M30
	return "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_$genome/release_$version/gencode.v$version.pc_translations.fa.gz";
}
############################## getGencodeTranscriptFasta ##############################
sub getGencodeTranscriptFasta{
	my $genome=shift();#human/mouse
	my $version=shift();#39,M30
	return "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_$genome/release_$version/gencode.v$version.transcripts.fa.gz";
}
############################## getGencodeTrnaGtf ##############################
sub getGencodeTrnaGtf{
	my $genome=shift();#human/mouse
	my $version=shift();#39,M30
	return "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_$genome/release_$version/gencode.v$version.tRNAs.gtf.gz";
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
############################## getHttpFile ##############################
sub getHttpFile{
	my $url=shift();
    my $file=shift();
	if(-e $file){return $file;}
	mkdirs(dirname($file));
    my $agent='Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)';
    my $timeout=10;
    my $lwp=LWP::UserAgent->new(agent=>$agent,timeout=>$timeout);
    my $res=$lwp->get($url,':content_file'=>$file);
    if($res->is_success){return $file;}
	else{return;}
}
############################## getNewJobID ##############################
sub getNewJobID{
	my $id="j".getDatetime();
	my $results=tripleSelect("daemon","jobid",$id);
	while(scalar(keys(%{$results}))>0){
		sleep(1);
		$id="j".getDatetime();
		$results=tripleSelect("daemon","jobid",$id);
	}
	return $id;
}
############################## getPredicateFromFile ##############################
sub getPredicateFromFile{
	my $path=shift();
	my $dirname=dirname($path);
	my $basename=basename($path);
	if($dirname eq $dbdir){}
	elsif($dirname=~/^$dbdir\/(.+)$/){$basename="$1/$basename";}
	else{$basename="$dirname/$basename";}
	if($basename=~/^(https?)\/(.+)$/){$basename="$1://$2";}
	elsif($basename=~/^ssh\/(.+?)\/(.+?)\/(.+)$/){$basename="$1\@$2:$3";}
	foreach my $suffix(sort{$b cmp $a}keys(%{$fileSuffixes})){
		if($basename=~/^(.+)$suffix/){return $1;}
	}
	return $basename;
}
############################## getPredicatesFromJson ##############################
sub getPredicatesFromJson{
	my $json=shift();
	my $hash={};
	foreach my $s(keys(%{$json})){foreach my $p(keys(%{$json->{$s}})){$hash->{$p}=1;}}
	return sort {$a cmp $b}keys(%{$hash});
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
############################## get_cigar_gene_coverage_length ##############################
# Return gene coverage length from cigar line - 2013/05/12
sub get_cigar_gene_coverage_length{
	my $cigar=shift();
	my $length=0;
	while($cigar ne ""){
		if($cigar=~/^(\d+)M(.*)$/){# match
			$length+=$1;
			$cigar=$2;
		}elsif($cigar=~/^(\d+)D(.*)$/){# deletion
			$length+=$1;
			$cigar=$2;
		}elsif($cigar=~/^(\d+)I(.*)$/){# insertion
			$length-=$1;
			$cigar=$2;
		}elsif($cigar=~/^(\d+)S(.*)$/){# soft
			$cigar=$2;
		}else{
 			$cigar="";
		}
	}
	return $length;
}
############################## get_cigar_genome_length ##############################
# Return genome conveage length from cigar line - 2022/02/28
sub get_cigar_genome_length{
	my $cigar=shift();
	my $length=0;
	while($cigar ne ""){
		if($cigar=~/^(\d+)M(.*)$/){# match
			$length+=$1;
			$cigar=$2;
		}elsif($cigar=~/^(\d+)D(.*)$/){# deletion
			$length+=$1;
			$cigar=$2;
		}elsif($cigar=~/^(\d+)I(.*)$/){# insertion
			$cigar=$2;
		}elsif($cigar=~/^(\d+)S(.*)$/){# soft
			$length+=$1;
			$cigar=$2;
		}elsif($cigar=~/^(\d+)N(.*)$/){# no match
			$length+=$1;
			$cigar=$2;
		}else{
 			$cigar="";
		}
	}
	return $length;
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
############################## jsonEncode ##############################
sub jsonEncode{
	my $object=shift;
	if(ref($object) eq "ARRAY"){return jsonEncodeArray($object);}
	elsif(ref($object) eq "HASH"){return jsonEncodeHash($object);}
	elsif($object=~/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/){return $object;}
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
############################## loadDbToArray ##############################
sub loadDbToArray{
	my $directory=shift();	
	my ($nodes,$edges)=toNodesAndEdges($directory);
	my $options={};
	$options->{"edges"}={"arrows"=>"to"};
	$options->{"groups"}={};
	$options->{"groups"}->{"box"}={"shape"=>"box"};
	return [$nodes,$edges,$options];
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
############################## loadLogToHash ##############################
sub loadLogToHash{
	my $directory=shift();
	my @files=listFiles(undef,undef,-1,$directory);
	my @array=();
	foreach my $file(@files){
		my $hash={};
		$hash->{"daemon/logfile"}=$file;
		my $reader=openFile($file);
		my $url;
		my $index=0;
		while(<$reader>){
			chomp;
			if(/^\#{40}/){if($index>0){last;}else{$index++;next;}}
			my ($p,$o)=split(/\t/);
			if(exists($revUrls->{$p})){$p=$revUrls->{$p};}
			if($p eq "daemon/command"){$url=quotemeta($o);}
			elsif($p eq "daemon/timecompleted"){$o=getDate("/",$o)." ".getTime(":",$o)}
			elsif($p eq "daemon/timeended"){$o=getDate("/",$o)." ".getTime(":",$o)}
			elsif($p eq "daemon/timeregistered"){$o=getDate("/",$o)." ".getTime(":",$o)}
			elsif($p eq "daemon/timestarted"){$o=getDate("/",$o)." ".getTime(":",$o)}
			elsif($p=~/^$url\#(.+)$/){$p=$1;}
			if(!exists($hash->{$p})){$hash->{$p}=$o;}
			elsif(ref($hash->{$p})eq"ARRAY"){push(@{$hash->{$p}},$o);}
			else{$hash->{$p}=[$hash->{$p},$o];}
		}
		close($reader);
		push(@array,$hash);
	}
	return \@array;
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
	my $dbdir=shift(@files);
	my $predicate=shift(@files);
	if($predicate=~/^(.+)#/){$predicate=$1;}
	my @results=();
	if($dbdir eq "."){
		foreach my $file(@files){
			foreach my $acceptedSuffix(sort{$b cmp $a}keys(%{$fileSuffixes})){
				if($file=~/$predicate$acceptedSuffix/){push(@results,$file);last;}
				elsif($file=~/$predicate.+$acceptedSuffix/){push(@results,$file);last;}
			}
		}
	}else{
		foreach my $file(@files){
			foreach my $acceptedSuffix(sort{$b cmp $a}keys(%{$fileSuffixes})){
				if($file=~/$dbdir\/$predicate$acceptedSuffix/){push(@results,$file);last;}
				elsif($file=~/$dbdir\/$predicate.+$acceptedSuffix/){push(@results,$file);last;}
			}
		}
	}
	return @results;
}
############################## openFile ##############################
sub openFile{
	my $path=shift();
	if($path=~/^https?:\/\/(.+)$/){$path=getHttpFile($path,"$dbdir/$1");}
	if($path=~/\.gz(ip)?$/){return IO::File->new("gzip -cd $path|");}
	elsif($path=~/\.bz(ip)?2$/){return IO::File->new("bzip2 -cd $path|");}
	elsif($path=~/\.bam$/){return IO::File->new("samtools view $path|");}
	elsif($path=~/\.tgz$/){return IO::File->new("tar -zxOf $path|");}
	else{return IO::File->new($path);}
}
############################## prepareDbDir ##############################
sub prepareDbDir{
	mkdir($moiraidir);
	chmod(0777,$moiraidir);
	mkdir($dbdir);
	chmod(0777,$dbdir);
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
	my $expand=shift(@queries);
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
		my @temp=();
		my $founds={};
		my @array=@{$values->{$query}};
		foreach my $h1(@results){
			my $found=0;
			for(my $j=0;$j<scalar(@array);$j++){
				my $h2=$array[$j];
				my @keys=sharedKeys($h1,$h2);
				my $error=0;
				my $match=0;
				foreach my $k(@keys){if($h1->{$k}ne$h2->{$k}){$error=1;last;}$match++;}
				if($error==1){next;}
				#if($match==0){next;}#There is a chance where no variable matches...
				my $hash={};
				foreach my $k(keys(%{$h1})){$hash->{$k}=$h1->{$k};}
				foreach my $k(keys(%{$h2})){if(!exists($h1->{$k})){$hash->{$k}=$h2->{$k};}}
				push(@temp,$hash);
				$found=1;
				$founds->{$j}=1;
			}
			if($found==0&&defined($expand)){
				my $h2=$values->{$query}->[0];
				my $hash={};
				foreach my $k(keys(%{$h1})){$hash->{$k}=$h1->{$k};}
				foreach my $k(keys(%{$h2})){if(!exists($h1->{$k})){$hash->{$k}="";}}
				push(@temp,$hash);
			}
		}
		if(defined($expand)){
			for(my $j=0;$j<scalar(@array);$j++){
				if($founds->{$j}){next;}
				my $h1=$results[0];
				my $h2=$array[$j];
				my $hash={};
				foreach my $k(keys(%{$h2})){$hash->{$k}=$h2->{$k};}
				foreach my $k(keys(%{$h1})){if(!exists($h2->{$k})){$hash->{$k}="";}}
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
	my $joinSubject;
	my $joinObject;
	my $subjectR=$subject;
	my $predicateR=$predicate;
	my $objectR=$object;
	if($subjectR=~/^\(\$(\{\w+\}|\w+)\)$/){if($1=~/\{(\w+)\}/){$1=$1;}push(@subVars,$1);$joinSubject=1;$subjectR="(.+)";}
	if($objectR=~/^\(\$(\{\w+\}|\w+)\)$/){if($1=~/\{(\w+)\}/){$1=$1;}push(@objVars,$1);$joinObject=1;$objectR="(.+)";}
	while($subjectR=~/\$(\{\w+\}|\w+)/){if($1=~/\{(\w+)\}/){$1=$1;}push(@subVars,$1);$subjectR=~s/\$(\{\w+\}|\w+)/(.+)/;}
	while($predicateR=~/\$(\{\w+\}|\w+)/){if($1=~/\{(\w+)\}/){$1=$1;}push(@preVars,$1);$predicateR=~s/\$(\{\w+\}|\w+)/(.+)/;}
	while($objectR=~/\$(\{\w+\}|\w+)/){if($1=~/\{(\w+)\}/){$1=$1;}push(@objVars,$1);$objectR=~s/\$(\{\w+\}|\w+)/(.+)/;}
	my $dir=$dbdir;
	my $file;
	if($predicate=~/^http/){#http://URL/basename.txt
		$dir=undef;
		$file=$predicate;
		$predicate=basename($predicate);
		foreach my $suffix(sort{$b cmp $a}keys(%{$fileSuffixes})){if($predicate=~/^(.+)$suffix/){$predicate=$1;last;}}
	}elsif($predicate=~/^\//){#/dirname/basename.txt
		$dir=dirname($predicate);
		$file=$predicate;
		$predicate=basename($predicate);
		foreach my $suffix(sort{$b cmp $a}keys(%{$fileSuffixes})){if($predicate=~/^(.+)$suffix/){$predicate=$1;last;}}
	}
	my $anchor;#key,val
	if($predicate=~/^(.+)\#(.+)$/){
		$predicate=$1;
		my @tokens=split(/\:/,$2);
		if(scalar(@tokens)==1){@tokens=(undef,$tokens[0]);}
		$anchor=\@tokens;
	}
	my @files=getFilesFromQuery($predicate,$dir);
	my @array=();
	if(defined($joinSubject)){
		foreach my $file(@files){
			my $hash={};
			my $p=getPredicateFromFile($file);
			my $function=\&splitTriple;
			foreach my $acceptedSuffix(sort{$b cmp $a}keys(%{$fileSuffixes})){
				if($file=~/$acceptedSuffix/){$function=$fileSuffixes->{$acceptedSuffix};last;}
			}
			my $reader=openFile($file);
			while(!eof($reader)){
				my ($s,$o)=$function->($reader,@{$anchor});
				if(!exists($hash->{$o})){$hash->{$o}=$s;}
				elsif(ref($hash->{$o})eq"ARRAY"){push(@{$hash->{$o}},$s);}
				else{$hash->{$o}=[$hash->{$o},$s];}
			}
			close($reader);
			while(my ($o,$s)=each(%{$hash})){
				if($o!~/^$objectR$/){next;}
				my $h={};
				if(scalar(@subVars)>0){
					for(my $i=0;$i<scalar(@subVars);$i++){$h->{$subVars[$i]}=$s;}
				}
				if(scalar(@preVars)>0){
					my @results=$p=~/^$predicateR$/;
					for(my $i=0;$i<scalar(@preVars);$i++){$h->{$preVars[$i]}=$results[$i];}
				}
				if(scalar(@objVars)>0){
					my @results=$o=~/^$objectR$/;
					for(my $i=0;$i<scalar(@objVars);$i++){$h->{$objVars[$i]}=$results[$i];}
				}
				if(scalar(keys(%{$h}))>0){push(@array,$h);}
			}
		}
	}elsif(defined($joinObject)){
		foreach my $file(@files){
			my $hash={};
			my $p=getPredicateFromFile($file);
			my $function=\&splitTriple;
			foreach my $acceptedSuffix(sort{$b cmp $a}keys(%{$fileSuffixes})){
				if($file=~/$acceptedSuffix/){$function=$fileSuffixes->{$acceptedSuffix};last;}
			}
			my $reader=openFile($file);
			while(!eof($reader)){
				chomp;
				my ($s,$o)=$function->($reader,@{$anchor});
				if(!exists($hash->{$s})){$hash->{$s}=$o;}
				elsif(ref($hash->{$s})eq"ARRAY"){push(@{$hash->{$s}},$o);}
				else{$hash->{$s}=[$hash->{$s},$o];}
			}
			close($reader);
			while(my ($s,$o)=each(%{$hash})){
				if($s!~/^$subjectR$/){next;}
				my $h={};
				if(scalar(@subVars)>0){
					my @results=$s=~/^$subjectR$/;
					for(my $i=0;$i<scalar(@subVars);$i++){$h->{$subVars[$i]}=$results[$i];}
				}
				if(scalar(@preVars)>0){
					my @results=$p=~/^$predicateR$/;
					for(my $i=0;$i<scalar(@preVars);$i++){$h->{$preVars[$i]}=$results[$i];}
				}
				if(scalar(@objVars)>0){
					for(my $i=0;$i<scalar(@objVars);$i++){$h->{$objVars[$i]}=$o;}
				}
				if(scalar(keys(%{$h}))>0){push(@array,$h);}
			}
		}
	}else{
		foreach my $file(@files){
			my $p=getPredicateFromFile($file);
			my $function=\&splitTriple;
			foreach my $acceptedSuffix(sort{$b cmp $a}keys(%{$fileSuffixes})){
				if($file=~/$acceptedSuffix/){$function=$fileSuffixes->{$acceptedSuffix};last;}
			}
			my $reader=openFile($file);
			while(!eof($reader)){
				chomp;
				my ($s,$o)=$function->($reader,@{$anchor});
				if($s!~/^$subjectR$/){next;}
				if($o!~/^$objectR$/){next;}
				my $h={};
				if(scalar(@subVars)>0){
					my @results=$s=~/^$subjectR$/;
					for(my $i=0;$i<scalar(@subVars);$i++){$h->{$subVars[$i]}=$results[$i];}
				}
				if(scalar(@preVars)>0){
					my @results=$p=~/^$predicateR$/;
					for(my $i=0;$i<scalar(@preVars);$i++){$h->{$preVars[$i]}=$results[$i];}
				}
				if(scalar(@objVars)>0){
					my @results=$o=~/^$objectR$/;
					for(my $i=0;$i<scalar(@objVars);$i++){$h->{$objVars[$i]}=$results[$i];}
				}
				if(scalar(keys(%{$h}))>0){push(@array,$h);}
			}
			close($reader);
		}
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
############################## readLogs ##############################
sub readLogs{
	my @logFiles=@_;
	my $hash={};
	foreach my $logFile(@logFiles){
		my $basename=basename($logFile,".txt");
		$hash->{$basename}={};
		$hash->{$basename}->{"logfile"}=$logFile;
		open(IN,$logFile);
		while(<IN>){
			chomp;
			my ($key,$val)=split(/\t/);
			if($key=~/https\:\/\/moirai2\.github\.io\/schema\/daemon\/(.+)$/){
				$key=$1;
				if($key eq "timeregistered"){$key="time";$val=getDate("/",$val)." ".getTime(":",$val);}
				if($key eq "timestarted"){$key="time";$val=getDate("/",$val)." ".getTime(":",$val)}
				if($key eq "timeended"){$key="time";$val=getDate("/",$val)." ".getTime(":",$val)}
				$hash->{$basename}->{$key}=$val;
			}
		}
		if(!defined($hash->{$basename}->{"workid"})){$hash->{$basename}->{"workid"}=$basename;}
		close(IN);
	}
	return $hash;
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
############################## sam2bed ##############################
sub sam2bed{
	my $input=shift();
	my $reader=openFile($input);
	while(<$reader>){
		chomp;
		my ($qname,$flag,$rname,$pos,$mapq,$cigar,$rnext,$pnext,$tlen,$seq,$qual)=split(/\t/);
		my $strand;
		my $length=get_cigar_genome_length($cigar);
		my ($start,$end,$strand)=samStartEndStrand($flag,$pos,$cigar);
		print "$rname\t$start\t$end\t$qname\t$mapq\t$strand\n";
	}
	close($reader);
}
############################## samStartEndStrand ##############################
sub samStartEndStrand{
	my $flag=shift();
	my $pos=shift();
	my $cigar=shift();
	my $length=get_cigar_genome_length($cigar);
	my $start;
	my $end;
	my $strand;
	if($flag&4){next;}
	if($flag&16){
		$strand="-";
		$start=$pos-1;
		$end=$pos+$length-1;
	}else{
		$strand="+";
		$start=$pos-1;
		$end=$pos+$length-1;
	}
	return ($start,$end,$strand);
}
############################## sharedKeys ##############################
sub sharedKeys{
	my $h1=shift();
	my $h2=shift();
	my @keys=();
	foreach my $key(keys(%{$h1})){if(exists($h2->{$key})){push(@keys,$key);}}
	return @keys;
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
	my ($writer,$file)=tempfile("scriptXXXXXXXXXX",DIR=>"/tmp",SUFFIX=>".pl",UNLINK=>1);
	foreach my $line(@headers){print $writer "$line\n";}
	foreach my $key(sort{$a cmp $b}@orders){foreach my $line(@{$blocks->{$key}}){print $writer "$line\n";}}
	close($writer);
	return system("mv $file $path");
}
############################## splitBam ##############################
sub splitBam{
	my $reader=shift();
	my $key=shift();
	my $val=shift();
	if(eof($reader)){return;}
	my $line=<$reader>;
	while($line=~/^\@/){$line=<$reader>;}
	chomp($line);
	my @tokens=split(/\t/,$line);
	my ($qname,$flag,$rname,$pos,$mapq,$cigar,$rnext,$pnext,$tlen,$seq,$qual)=split(/\t/);
	my ($start,$end,$strand)=samStartEndStrand($tokens[1],$tokens[3],$tokens[5]);
	my $position="$rname:$start-$end;$strand";
	my $hash={};
	for(my $i=0;$i<scalar(@{$splitBamLabels});$i++){$hash->{$splitBamLabels->[$i]}=$tokens[$i];}
	$hash->{"start"}=$start;
	$hash->{"end"}=$end;
	$hash->{"strand"}=$strand;
	$hash->{"position"}=$position;
	if(!defined($key)){$key="qname";}
	if(!defined($val)){$val="position";}
	return ($hash->{$key},$hash->{$val});
}
############################## splitBed ##############################
#chr22 1000 5000 cloneA 960 + 1000 5000 0 2 567,488, 0,3512
#chr22 2000 6000 cloneB 900 - 2000 6000 0 2 433,399, 0,3601
sub splitBed{
	my $reader=shift();
	my $key=shift();
	my $val=shift();
	if(!defined($key)){$key="name";}
	if(!defined($val)){$val="position";}
	if(eof($reader)){return;}
	my $line=<$reader>;
	while($line=~/^#/){$line=<$reader>;}
	chomp($line);
	my $hash={};
	my ($chrom,$chromStart,$chromEnd,$name,$score,$strand,$thickStart,$thickEnd,$itemRgb,$blockCount,$blockSizes,$blockStarts)=split(/\t/,$line);
	$hash->{"chrom"}=$chrom;
	$hash->{"chromStart"}=$chromStart;
	$hash->{"chromEnd"}=$chromEnd;
	$hash->{"name"}=$name;
	$hash->{"score"}=$score;
	$hash->{"strand"}=$strand;
	$hash->{"thickStart"}=$thickStart;
	$hash->{"thickEnd"}=$thickEnd;
	$hash->{"itemRgb"}=$itemRgb;
	$hash->{"blockCount"}=$blockCount;
	$hash->{"blockSizes"}=$blockSizes;
	$hash->{"blockStarts"}=$blockStarts;
	$hash->{"chromLength"}=$chromEnd-$chromStart;
	$hash->{"position"}="$chrom:$chromStart..$chromEnd:$strand";
	my @sizes=split(',',$blockSizes);
	my $geneLength=0;
	foreach my $size(@sizes){$geneLength+=$size;}
	$hash->{"genLength"}=$geneLength;
	return ($hash->{$key},$hash->{$val});
}
############################## splitCsv ##############################
sub splitCsv{
	my $reader=shift();
	my $key=shift();
	my $val=shift();
	if(!defined($key)){$key=0;}
	if(!defined($val)){$val=1;}
	if(eof($reader)){return;}
	my $line=<$reader>;
	while($line=~/^#/){$line=<$reader>;}
	chomp($line);
	my @tokens=split(/,/,$line);
	return ($tokens[$key],$tokens[$val]);
}
############################## splitCsvWithLabel ##############################
my $splitCsvWithLabelLabels;
sub splitCsvWithLabel{
	my $reader=shift();
	my $key=shift();
	my $val=shift();
	if(eof($reader)){return;}
	my $line=<$reader>;
	while($line=~/^#/){$line=<$reader>;}
	chomp($line);
	if(!defined($splitCsvWithLabelLabels)){
		my @tokens=split(/,/,$line);
		$splitCsvWithLabelLabels=\@tokens;
		$line=<$reader>;
		chomp($line);
	}
	my @tokens=split(/,/,$line);
	my $hash={};
	for(my $i=0;$i<scalar(@{$splitCsvWithLabelLabels});$i++){$hash->{$splitCsvWithLabelLabels->[$i]}=$tokens[$i];}
	if(!defined($key)){$key=$splitCsvWithLabelLabels->[0];}
	if(!defined($val)){$val=$splitCsvWithLabelLabels->[1];}
	return ($hash->{$key},$hash->{$val});
}
############################## splitFasta ##############################
my $splitFastaLine;
sub splitFasta{
	my $reader=shift();
	my $key=shift();
	my $val=shift();
	if(eof($reader)){return;}
	if(!defined($splitFastaLine)){$splitFastaLine=<$reader>;chomp($splitFastaLine);}
	while($splitFastaLine=~/^#/){$splitFastaLine=<$reader>;chomp($splitFastaLine);}
	my $id=substr($splitFastaLine,1);chomp($id);
	my $sequence;
	while(<$reader>){chomp;if(/^>/){$splitFastaLine=$_;last;}$sequence.=$_;}
	if($val eq"length"){$sequence=length($sequence);}
	return ($id,$sequence);
}
############################## splitFastq ##############################
sub splitFastq{
	my $reader=shift();
	my $key=shift();
	my $val=shift();
	if(eof($reader)){return;}
	my $idLine=<$reader>;
	while($idLine=~/^#/){$idLine=<$reader>;}
	if($idLine=~/^\@\s*(.+)$/){$idLine=$1;}
	my $seqLine=<$reader>;chomp($seqLine);
	my $idLine2=<$reader>;if($idLine2=~/^\+\s*(.+)$/){$idLine2=$1;}
	my $qualLine=<$reader>;chomp($qualLine);
	my $id=$idLine;
	my $value=$seqLine;
	if($val eq"length"){$value=length($seqLine);}
	elsif($val eq"qual"){$value=length($qualLine);}
	return ($id,$value);
}
############################## splitGtf ##############################
sub splitGtf{
	my $reader=shift();
	my $key=shift();
	my $val=shift();
	if(!defined($key)){$key="position";}
	if(!defined($val)){$val="seqname";}
	if(eof($reader)){return;}
	my $line=<$reader>;
	while($line=~/^#/){$line=<$reader>;}
	chomp($line);
	my $hash={};
	my ($seqname,$source,$feature,$start,$end,$score,$strand,$frame,$attribute)=split(/\t/,$line);
	$hash->{"seqname"}=$seqname;
	$hash->{"source"}=$seqname;
	$hash->{"feature"}=$feature;
	$hash->{"start"}=$start;
	$hash->{"end"}=$end;
	$hash->{"score"}=$score;
	$hash->{"strand"}=$strand;
	$hash->{"frame"}=$frame;
	$hash->{"position"}="$seqname:$start..$end";
	foreach my $attr(split(/;\s*/,$attribute)){
		my ($k,$v)=split(/\s/,$attr);
		if($v=~/^\"(.+)\"$/){$v=$1;}
		$hash->{$k}=$v;
	}
	return ($hash->{$key},$hash->{$val});
}
############################## splitQueries ##############################
sub splitQueries{
	my $arg=shift();
	my @tokens=split(',',$arg);
	my @queries=();
	my $query;
	foreach my $token(@tokens){
		my $string=$token;
		my $count=$string=~s/\-\>//g;
		if($count==2){push(@queries,$token);}
		elsif(defined($query)){
			$query.=",$token";
			$string=$query;
			my $count=$string=~s/\-\>//g;
			if($count==2){push(@queries,$query);}
			elsif($count>2){
				$query=undef;
				print STDERR "ERROR: '$query' has multiple '->' (More than 2)\n";
				exit(1);
			}
		}elsif($count<2){$query=$token;}
	}
	return @queries;
}
############################## splitRunInfo ##############################
#Run,ReleaseDate,LoadDate,spots,bases,spots_with_mates,avgLength,size_MB,AssemblyName,download_path,Experiment,LibraryName,LibraryStrategy,LibrarySelection,LibrarySource,LibraryLayout,InsertSize,InsertDev,Platform,Model,SRAStudy,BioProject,Study_Pubmed_id,ProjectID,Sample,BioSample,SampleType,TaxID,ScientificName,SampleName,g1k_pop_code,source,g1k_analysis_group,Subject_ID,Sex,Disease,Tumor,Affection_Status,Analyte_Type,Histological_Type,Body_Site,CenterName,Submission,dbgap_study_accession,Consent,RunHash,ReadHash
my $splitRunInfoLabels;
sub splitRunInfo{
	my $reader=shift();
	my $key=shift();
	my $val=shift();
	if(!defined($key)){$key="Run";}
	if(!defined($val)){$val="download_path";}
	if(eof($reader)){return;}
	my $line=<$reader>;
	while($line=~/^#/){$line=<$reader>;}
	chomp($line);
	if(!defined($splitRunInfoLabels)){
		my @tokens=split(/,/,$line);
		$splitRunInfoLabels=\@tokens;
		$line=<$reader>;
		chomp($line);
	}
	my $hash={};
	my @tokens=split(/,/,$line);
	for(my $i=0;$i<scalar(@{$splitRunInfoLabels});$i++){$hash->{$splitRunInfoLabels->[$i]}=$tokens[$i];}
	return ($hash->{$key},$hash->{$val});
}
############################## splitTriple ##############################
sub splitTriple{
	my $reader=shift();
	my $key=shift();
	my $val=shift();
	while(<$reader>){chomp;return split(/\t/);}
	return;
}
############################## splitTsv ##############################
sub splitTsv{
	my $reader=shift();
	my $key=shift();
	my $val=shift();
	if(!defined($key)){$key=0;}
	if(!defined($val)){$val=1;}
	if(eof($reader)){return;}
	my $line=<$reader>;
	while($line=~/^#/){$line=<$reader>;}
	chomp($line);
	my @tokens=split(/\t/,$line);
	return ($tokens[$key],$tokens[$val]);
}
############################## splitTsvWithLabel ##############################
my $splitTsvWithLabelLabels;
sub splitTsvWithLabel{
	my $reader=shift();
	my $key=shift();
	my $val=shift();
	if(eof($reader)){return;}
	my $line=<$reader>;
	while($line=~/^#/){$line=<$reader>;}
	chomp($line);
	if(!defined($splitTsvWithLabelLabels)){
		my @tokens=split(/\t/,$line);
		$splitTsvWithLabelLabels=\@tokens;
		$line=<$reader>;
		chomp($line);
	}
	my @tokens=split(/\t/,$line);
	my $hash={};
	for(my $i=0;$i<scalar(@{$splitTsvWithLabelLabels});$i++){$hash->{$splitTsvWithLabelLabels->[$i]}=$tokens[$i];}
	if(!defined($key)){$key=$splitTsvWithLabelLabels->[0];}
	if(!defined($val)){$val=$splitTsvWithLabelLabels->[1];}
	return ($hash->{$key},$hash->{$val});
}
############################## test ##############################
sub test{
	my @arguments=@_;
	my $hash={};
	if(scalar(@arguments)>0){foreach my $arg(@arguments){$hash->{$arg}=1;}}
	else{for(my $i=0;$i<=8;$i++){$hash->{$i}=1;}}
	if(fileExistsInDirectory("test")){system("rm -r test/*");}
	mkdir("test");
	if(exists($hash->{0})){test0();}
	if(exists($hash->{1})){test1();}
	if(exists($hash->{2})){test2();}
	if(exists($hash->{3})){test3();}
	rmdir("test");
}
#Test test
sub test0{
	testCommand("perl $prgdir/rdf.pl -d test insert A B C","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test update A B D","updated 1");
	testCommand("perl $prgdir/rdf.pl -d test select A B D","A\tB\tD");
	testCommand("perl $prgdir/rdf.pl -d test -f json select A B D","{\"A\":{\"B\":\"D\"}}");
	system("echo 'A\\tE' >> test/B.txt");
	testCommand("perl $prgdir/rdf.pl -d test select","A\tB\tD","A\tB\tE");
	testCommand("perl $prgdir/rdf.pl -d test -f json select","{\"A\":{\"B\":[\"D\",\"E\"]}}");
	testCommand("perl $prgdir/rdf.pl -d test -f json select % B","{\"A\":{\"B\":[\"D\",\"E\"]}}");
	testCommand("perl $prgdir/rdf.pl -d test -f json select A","{\"A\":{\"B\":[\"D\",\"E\"]}}");
	testCommand("perl $prgdir/rdf.pl -d test -f json select % % D","{\"A\":{\"B\":\"D\"}}");
	system("echo 'F\\tGreg' >> test/B.txt");
	testCommand("perl $prgdir/rdf.pl -d test -f json select % B %","{\"A\":{\"B\":[\"D\",\"E\"]},\"F\":{\"B\":\"Greg\"}}");
	testCommand("perl $prgdir/rdf.pl -d test -f json select % % %eg","{\"F\":{\"B\":\"Greg\"}}");
	testCommand("perl $prgdir/rdf.pl -d test -f json delete % % %e%","deleted 1");
	testCommand("perl $prgdir/rdf.pl -d test -f json select","{\"A\":{\"B\":[\"D\",\"E\"]}}");
	system("rm test/B.txt");
	testCommand("perl $prgdir/rdf.pl -d test -f json select","{}");
}
#Test sub functions
sub test1{
	if(!equals(1,1)){print STDERR "#ERROR at equal test #1\n";}
	if(equals(1,0)){print STDERR "#ERROR at equal test #2\n";}
	if(!equals("A","A")){print STDERR "#ERROR at equal test #3\n";}
	if(equals("A","B")){print STDERR "#ERROR at equal test #4\n";}
	if(equals("A","AA")){print STDERR "#ERROR at equal test #5\n";}
	if(equals("A",undef)){print STDERR "#ERROR at equal test #6\n";}
	if(equals(undef,"A")){print STDERR "#ERROR at equal test #7\n";}
	if(!equals([1,2],[1,2])){print STDERR "#ERROR at equal test #8\n";}
	if(equals([1,2],[2,1])){print STDERR "#ERROR at equal test #9\n";}
	if(equals([1,2],[1,2,3])){print STDERR "#ERROR at equal test #10\n";}
	if(equals([1,2],undef)){print STDERR "#ERROR at equal test #11\n";}
	if(equals(undef,[1,2])){print STDERR "#ERROR at equal test #12\n";}
	if(!equals([1,2,[3,4]],[1,2,[3,4]])){print STDERR "#ERROR at equal test #13\n";}
	if(equals([1,2,[3,4]],[1,2,[3,5]])){print STDERR "#ERROR at equal test #14\n";}
	if(equals([1,2,[3,4]],[1,2,[4,3]])){print STDERR "#ERROR at equal test #15\n";}
	if(equals([1,2,[3,4]],[1,2,[3]])){print STDERR "#ERROR at equal test #16\n";}
	if(!equals([1,2,[3]],[1,2,[3]])){print STDERR "#ERROR at equal test #17\n";}
	if(!equals({"a"=>1},{"a"=>1})){print STDERR "#ERROR at equal test #18\n";}
	if(!equals({"a"=>1,"b"=>"big"},{"a"=>1,"b"=>"big"})){print STDERR "#ERROR at equal test #19\n";}
	if(!equals({"b"=>"big","a"=>1},{"a"=>1,"b"=>"big"})){print STDERR "#ERROR at equal test #20\n";}
	if(equals({"b"=>"big","a"=>1},{"a"=>1,"b"=>"small"})){print STDERR "#ERROR at equal test #21\n";}
	if(!equals({"b"=>"big","a"=>["big","small"]},{"a"=>["big","small"],"b"=>"big"})){print STDERR "#ERROR at equal test #22\n";}
	if(equals({"b"=>"big","a"=>["small","big"]},{"a"=>["big","small"],"b"=>"big"})){print STDERR "#ERROR at equal test #23\n";}
	createFile("$dbdir/B.txt","A\tC");
	testSub("getFilesFromQuery(\"B\")",["$dbdir/B.txt"]);
	testSub("getFilesFromQuery(\"B#D\")",["$dbdir/B.txt"]);
	system("gzip $dbdir/B.txt");
	testSub("getFilesFromQuery(\"B\")",["$dbdir/B.txt.gz"]);
	unlink("$dbdir/B.txt.gz");
	createFile("$dbdir/A/B/C.txt","1\t4");
	createFile("$dbdir/A/B/D.txt","2\t5");
	createFile("$dbdir/A/E/F.txt","3\t6");
	testSub("getFilesFromQuery(\"A/B/C\")",["$dbdir/A/B/C.txt"]);
	testSub("getFilesFromQuery(\"\\\$id/B/C\")",["$dbdir/A/B/C.txt"]);
	testSub("getFilesFromQuery(\"A/\\\$id/C\")",["$dbdir/A/B/C.txt"]);
	testSub("getFilesFromQuery(\"A/B/\\\$id\")",["$dbdir/A/B/C.txt","$dbdir/A/B/D.txt"]);
	testSub("getFilesFromQuery(\"A/\\\$id2/\\\$id3\")",["$dbdir/A/B/C.txt","$dbdir/A/B/D.txt","$dbdir/A/E/F.txt"]);
	testSub("getFilesFromQuery(\"\\\$id1/B/\\\$id3\")",["$dbdir/A/B/C.txt","$dbdir/A/B/D.txt"]);
	testSub("getFilesFromQuery(\"\\\$id1/E/\\\$id3\")",["$dbdir/A/E/F.txt"]);
	system("rm -r $dbdir/A");
	testSub("getPredicateFromFile(\"$dbdir/A.txt\")","A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.txt\")","B/A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.txt.gz\")","B/A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.txt.bz2\")","B/A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.tsv\")","B/A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.tsv.gz\")","B/A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.tsv.bz2\")","B/A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.bed\")","B/A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.bed.gz\")","B/A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.bed.bz2\")","B/A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.sam\")","B/A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.sam.gz\")","B/A");
	testSub("getPredicateFromFile(\"$dbdir/B/A.sam.bz2\")","B/A");
	testSub("getPredicateFromFile(\"/A/B/C/D/E.txt\")","/A/B/C/D/E");
	testSub("getPredicateFromFile(\"test2/B/A.txt\")","test2/B/A");
	testSub("getPredicateFromFile(\"$dbdir/https/moirai2.github.io/schema/daemon/bash.txt\")","https://moirai2.github.io/schema/daemon/bash");
	testSub("getPredicateFromFile(\"$dbdir/http/localhost/~ah3q/gitlab/moirai2dgt/geneBodyCoverage/allImage.txt\")","http://localhost/~ah3q/gitlab/moirai2dgt/geneBodyCoverage/allImage");
	testSub("getPredicateFromFile(\"$dbdir/ssh/ah3q/dgt-ac4/A/B/C.txt\")","ah3q\@dgt-ac4:A/B/C");
	testSub("getPredicateFromFile(\"$dbdir/ssh/ah3q/dgt-ac4/A/B/C.txt.bz2\")","ah3q\@dgt-ac4:A/B/C");
	#default usage
	testSub("getFileFromPredicate(\"A\")","$dbdir/A.txt");
	testSub("getFileFromPredicate(\"A/B\")","$dbdir/A/B.txt");
	testSub("getFileFromPredicate(\"A/B/D\")","$dbdir/A/B/D.txt");
	testSub("getFileFromPredicate(\"A/B%\")","$dbdir/A");
	testSub("getFileFromPredicate(\"A/B/%\")","$dbdir/A/B");
	testSub("getFileFromPredicate(\"A/%/C\")","$dbdir/A");
	testSub("getFileFromPredicate(\"%/B/C\")","$dbdir");
	#directory exists, so directory returned
	system("mkdir -p $dbdir/A");
	testSub("getFileFromPredicate(\"A\")","$dbdir/A");
	#directory doesn't exists, so default text file which doesn't exist yet is returned
	system("rmdir $dbdir/A");
	testSub("getFileFromPredicate(\"A\")","$dbdir/A.txt");
	#directory notation, but directory doesn't exist
	testSub("getFileFromPredicate(\"A/\")","$dbdir/A.txt");
	system("mkdir -p $dbdir/A");
	testSub("getFileFromPredicate(\"A/\")","$dbdir/A");
	system("rmdir $dbdir/A");
	#directory with fileexists, so directory returned
	createFile("$dbdir/A/B.txt","A\tA1");
	testSub("getFileFromPredicate(\"A\")","$dbdir/A");
	testSub("getFileFromPredicate(\"A/B\")","$dbdir/A/B.txt");
	system("gzip $dbdir/A/B.txt");
	testSub("getFileFromPredicate(\"A\")","$dbdir/A");
	testSub("getFileFromPredicate(\"A/B\")","$dbdir/A/B.txt.gz");
	system("rm $dbdir/A/B.txt.gz");
	rmdir("$dbdir/A/");
	testSub("getFileFromPredicate(\"A/B#CDF\")","$dbdir/A/B.txt");
	testSub("getFileFromPredicate(\"A/B.json\")","$dbdir/A/B.txt");
	testSub("getFileFromPredicate(\"A/B.json#D\")","$dbdir/A/B.txt");
	testSub("getFileFromPredicate(\"test2/A/B\")","$dbdir/test2/A/B.txt");
	testSub("getFileFromPredicate(\"http://A/B\")","$dbdir/http/A/B.txt");
	testSub("getFileFromPredicate(\"https://A/B/C/D\")","$dbdir/https/A/B/C/D.txt");
	testSub("getFileFromPredicate(\"http://localhost/~ah3q/gitlab/moirai2dgt/geneBodyCoverage/allImage\")","$dbdir/http/localhost/~ah3q/gitlab/moirai2dgt/geneBodyCoverage/allImage.txt");
	testSub("getFileFromPredicate(\"ah3q\\\@dgt-ac4:A/B\")","$dbdir/ssh/ah3q/dgt-ac4/A/B.txt");
	createFile("$dbdir/A/B.txt","A\tA1");
	createFile("$dbdir/A/C.txt","A\tA1");
	testSub("getFileFromPredicate(\"A/\")","$dbdir/A");
	system("rm $dbdir/A/B.txt");
	system("rm $dbdir/A/C.txt");
	system("rmdir $dbdir/A");
}
#Testing basic functionality
sub test2{
	mkdir("file");
	createFile("test/id.txt","A\tA1","B\tB1","C\tC1","D\tD1");
	createFile("test/name.txt","A1\tAkira","B1\tBen","C1\tChris","D1\tDavid");
	testCommand("perl $prgdir/rdf.pl linecount test/id.txt","test/id.txt\tfile/linecount\t4");
	testCommand("perl $prgdir/rdf.pl md5 test/id.txt","test/id.txt\tfile/md5\t131e61dab9612108824858dc497bf713");
	testCommand("perl $prgdir/rdf.pl filesize test/id.txt","test/id.txt\tfile/filesize\t20");
	testCommand("perl $prgdir/rdf.pl seqcount test/id.txt","test/id.txt\tfile/seqcount\t4");
	testCommand("perl $prgdir/rdf.pl -d test select","A\tid\tA1","A1\tname\tAkira","B\tid\tB1","B1\tname\tBen","C\tid\tC1","C1\tname\tChris","D\tid\tD1","D1\tname\tDavid");
	testCommand("perl $prgdir/rdf.pl -d test select A","A\tid\tA1");
	testCommand("perl $prgdir/rdf.pl -d test select % id","A\tid\tA1","B\tid\tB1","C\tid\tC1","D\tid\tD1");
	testCommand("perl $prgdir/rdf.pl -d test select % % B1","B\tid\tB1");
	testCommand("perl $prgdir/rdf.pl -d test select A%","A\tid\tA1","A1\tname\tAkira");
	testCommand("perl $prgdir/rdf.pl -d test select A% n%","A1\tname\tAkira");
	testCommand("perl $prgdir/rdf.pl -d test select % % A%","A\tid\tA1","A1\tname\tAkira");
	testCommand("perl $prgdir/rdf.pl -d test select %1","A1\tname\tAkira","B1\tname\tBen","C1\tname\tChris","D1\tname\tDavid");
	testCommand("perl $prgdir/rdf.pl -d test delete A%","deleted 2");
	testCommand("perl $prgdir/rdf.pl -d test select ","B\tid\tB1","B1\tname\tBen","C\tid\tC1","C1\tname\tChris","D\tid\tD1","D1\tname\tDavid");
	testCommand("perl $prgdir/rdf.pl -d test delete % name","deleted 3");
	testCommand("perl $prgdir/rdf.pl -d test select ","B\tid\tB1","C\tid\tC1","D\tid\tD1");
	testCommand("perl $prgdir/rdf.pl -d test delete % % %1","deleted 3");
	testCommand("perl $prgdir/rdf.pl -d test insert T name Tsunami","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test select T","T\tname\tTsunami");
	testCommand("perl $prgdir/rdf.pl -d test insert A name Akira","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test select","A\tname\tAkira","T\tname\tTsunami");
	testCommand("perl $prgdir/rdf.pl -d test update A name Alice","updated 1");
	testCommand("perl $prgdir/rdf.pl -d test select","A\tname\tAlice","T\tname\tTsunami");
	createFile("file/import.txt","A\tid\tA2","B\tid\tB2","C\tid\tC2","D\tid\tD2","A\tid\tA1","B\tid\tB1","C\tid\tC1","D\tid\tD1");
	testCommand("perl $prgdir/rdf.pl -d test import < file/import.txt","inserted 8");
	testCommand("perl $prgdir/rdf.pl -d test select % id","A\tid\tA1","A\tid\tA2","B\tid\tB1","B\tid\tB2","C\tid\tC1","C\tid\tC2","D\tid\tD1","D\tid\tD2");
	createFile("file/update.txt","A\tid\tA3","B\tid\tB3");
	testCommand("perl $prgdir/rdf.pl -d test update < file/update.txt","updated 2");
	testCommand("perl $prgdir/rdf.pl -d test select A id","A\tid\tA3");
	testCommand("perl $prgdir/rdf.pl -d test select B id","B\tid\tB3");
	createFile("file/update.json","{\"A\":{\"name\":\"Akira\"},\"B\":{\"name\":\"Bob\"}}");
	testCommand("perl $prgdir/rdf.pl -d test -f json update < file/update.json","updated 2");
	testCommand("perl $prgdir/rdf.pl -d test select % name","A\tname\tAkira\nB\tname\tBob","T\tname\tTsunami");
	testCommand("perl $prgdir/rdf.pl -d test delete < file/update.txt","deleted 2");
	testCommand("perl $prgdir/rdf.pl -d test select % id","C\tid\tC1","C\tid\tC2","D\tid\tD1","D\tid\tD2");
	testCommand("perl $prgdir/rdf.pl -d test -f json delete < file/update.json","deleted 2");
	testCommand("perl $prgdir/rdf.pl -d test select % name","T\tname\tTsunami");
	testCommand("perl $prgdir/rdf.pl -d test delete % % %","deleted 5");
	testCommand("perl $prgdir/rdf.pl -d test -f json insert < file/update.json","inserted 2");
	testCommand("perl $prgdir/rdf.pl -d test insert < file/import.txt","inserted 8");
	testCommand("perl $prgdir/rdf.pl -d test delete % % %","deleted 10");
	#Testing query
	testCommand("echo \"A\tB\tC\nC\tD\tE\nC\tF\tG\"|perl $prgdir/rdf.pl -d test import","inserted 3");
	testCommand("perl $prgdir/rdf.pl -d test query '\$a->B->\$c'","a\tc","A\tC");
	testCommand("perl $prgdir/rdf.pl -d test -f json  query '\$a->B->\$c'","[{\"a\":\"A\",\"c\":\"C\"}]");
	testCommand("perl $prgdir/rdf.pl -d test query '\$a->B->\$c' '\$c->D->\$e'","a\tc\te","A\tC\tE");
	testCommand("perl $prgdir/rdf.pl -d test -f json  query '\$a->B->\$c' '\$c->D->\$e'","[{\"a\":\"A\",\"c\":\"C\",\"e\":\"E\"}]");
	testCommand("echo \"C\tD\tH\"|perl $prgdir/rdf.pl -d test insert","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test query '\$a->B->\$c' '\$c->D->\$e'","a\tc\te","A\tC\tE","A\tC\tH");
	testCommand("perl $prgdir/rdf.pl -d test -f json  query '\$a->B->\$c' '\$c->D->\$e'","[{\"a\":\"A\",\"c\":\"C\",\"e\":\"E\"},{\"a\":\"A\",\"c\":\"C\",\"e\":\"H\"}]");
	testCommand("perl $prgdir/rdf.pl -d test query '\$a->B->\$c' '\$c->D->\$e' '\$c->F->\$g'","a\tc\te\tg","A\tC\tE\tG","A\tC\tH\tG");
	testCommand("perl $prgdir/rdf.pl -d test -f json  query '\$a->B->\$c' '\$c->D->\$e' '\$c->F->\$g'","[{\"a\":\"A\",\"c\":\"C\",\"e\":\"E\",\"g\":\"G\"},{\"a\":\"A\",\"c\":\"C\",\"e\":\"H\",\"g\":\"G\"}]");
	testCommand("perl $prgdir/rdf.pl -d test delete % % %","deleted 4");
	unlink("file/update.txt");
	unlink("file/update.json");
	unlink("file/import.txt");
	rmdir("file");
	#Testing query
	testCommand("perl $prgdir/rdf.pl -d test/A insert id0 name Tsunami","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test/B insert id0 country Japan","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test/A query '\$id->name->\$name'","id\tname","id0\tTsunami");
	testCommand("perl $prgdir/rdf.pl -d test/B query '\$id->country->\$country'","country\tid","Japan\tid0");
	testCommand("perl $prgdir/rdf.pl -d test query '\$id->A/name->\$name,\$id->B/country->\$country'","country\tid\tname","Japan\tid0\tTsunami");
	testCommand("perl $prgdir/rdf.pl query '\$id->test/A/name->\$name,\$id->test/B/country->\$country'","country\tid\tname","Japan\tid0\tTsunami");
	testCommand("perl $prgdir/rdf.pl -d test/A delete % % %","deleted 1");
	testCommand("perl $prgdir/rdf.pl -d test/B delete % % %","deleted 1");
	rmdir("test/B/log");
	rmdir("test/A");
	rmdir("test/B");
	#Tesiting json and tsv format
	testCommand("perl $prgdir/rdf.pl -q -d test insert A B C","");
	testCommand("perl $prgdir/rdf.pl -d test select","A\tB\tC");
	testCommand("perl $prgdir/rdf.pl -f tsv -d test select","A\tB\tC");
	testCommand("perl $prgdir/rdf.pl -d test insert A B D","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test -f tsv select","A\tB\tC","A\tB\tD");
	testCommand("perl $prgdir/rdf.pl -d test -f json select","{\"A\":{\"B\":[\"C\",\"D\"]}}");
	testCommand("perl $prgdir/rdf.pl -d test delete % % %","deleted 2");
	testCommand("perl $prgdir/rdf.pl -q -d test assign A B C","");
	testCommand("perl $prgdir/rdf.pl -f json -d test select","{\"A\":{\"B\":\"C\"}}");
	testCommand("perl $prgdir/rdf.pl -d test assign A B C","inserted 0");
	testCommand("perl $prgdir/rdf.pl -q -d test delete % % %","");
	exit();
}
#Testing advanced cases
sub test3{
	#Testing special queries like ()
	createFile("test/import.txt","A\tB\tC","X\tB\tY","C\tD\tE","C\tD\tH","C\tD\tI","F\tD\tG");
	testCommand("perl $prgdir/rdf.pl -d test insert < test/import.txt","inserted 6");
	testCommand("perl $prgdir/rdf.pl -d test query '\$a->B->\$c,\$c->D->\$e'","a\tc\te","A\tC\tE","A\tC\tH","A\tC\tI");
	testCommand("perl $prgdir/rdf.pl -d test query '\$a->B->\$c,\$c->D->(\$e)'","a\tc\te","A\tC\tE,H,I");
	testCommand("perl $prgdir/rdf.pl -d test query '(\$a)->B->\$c,\$c->D->(\$e)'","a\tc\te","A\tC\tE,H,I");
	testCommand("perl $prgdir/rdf.pl -x -d test query '\$a->B->\$c,\$c->D->\$e'","a\tc\te","A\tC\tE","A\tC\tH","A\tC\tI","X\tY\t","\tF\tG");
	testCommand("perl $prgdir/rdf.pl -x -d test query '\$a->B->\$c,\$c->D->(\$e)'","a\tc\te","A\tC\tE,H,I","X\tY\t","\tF\tG");
	unlink("test/import.txt");
	unlink("test/B.txt");
	unlink("test/D.txt");
	#Testing file predicates, .fa, .csv, .tsv
	createFile("test/name.txt","Akira\tA","Chris\tC","George\tG","Tsunami\tT");
	createFile("test/fasta.fa",">A","AAAAAAAAAAAA","AAAAAAAAAAAA",">C","CCCCCCCCCCCC","CCCCCCCCCCCC","CCCCCCCCCCCC",">G","GGGGGGGGGGGG","GGGGGGGGGGGG","GGGGGGGGGGGG","GGGGGGGGGGGG",">T","TTTTTTTTTTTT","TTTTTTTTTTTT","TTTTTTTTTTTT","TTTTTTTTTTTT","TTTTTTTTTTTT");
	createFile("test/tsv.tsv","A\tA1\tA2","B\tB1\tB2","C\tC1\tC2","D\tD1\tD2","E\tE1\tE2");
	testCommand("perl $prgdir/rdf.pl -d test query '\$name->name->\$alpha\' '\$alpha->fasta->\$fasta\'","alpha\tfasta\tname","A\tAAAAAAAAAAAAAAAAAAAAAAAA\tAkira","C\tCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\tChris","G\tGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\tGeorge","T\tTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\tTsunami");
	testCommand("perl $prgdir/rdf.pl -d test query '\$name->name->\$alpha\' '\$alpha->tsv#1->\$column\'","alpha\tcolumn\tname","A\tA1\tAkira","C\tC1\tChris");
	testCommand("perl $prgdir/rdf.pl -d test query '\$name->name->\$alpha\' '\$alpha->tsv#2->\$column\'","alpha\tcolumn\tname","A\tA2\tAkira","C\tC2\tChris");
	testCommand("perl $prgdir/rdf.pl -d test query '\$a->tsv#1->A1\'","a","A");
	unlink("test/name.txt");
	unlink("test/fasta.fa");
	unlink("test/tsv.tsv");
	#Testing special predicates (directory,anchor)
	mkdir("test/name");
	createFile("test/name/one.txt","Akira\tA","Ben\tB");
	createFile("test/name/two.txt","Chris\tC","David\tD");
	testCommand("perl $prgdir/rdf.pl -d test query '\$name->name->\$initial\'","initial\tname","A\tAkira","B\tBen","C\tChris","D\tDavid");
	testCommand("perl $prgdir/rdf.pl -d test query '\$name->name/one->\$initial\'","initial\tname","A\tAkira","B\tBen");
	testCommand("perl $prgdir/rdf.pl -d test query '\$name->name/two->\$initial\'","initial\tname","C\tChris","D\tDavid");
	testCommand("perl $prgdir/rdf.pl -d test select % name/one %","Akira\tname/one\tA","Ben\tname/one\tB");
	testCommand("perl $prgdir/rdf.pl -d test select % name/two %","Chris\tname/two\tC","David\tname/two\tD");
	testCommand("perl $prgdir/rdf.pl -d test select % name% %","Akira\tname/one\tA","Ben\tname/one\tB","Chris\tname/two\tC","David\tname/two\tD");
	testCommand("perl $prgdir/rdf.pl -d test select % name/% %","Akira\tname/one\tA","Ben\tname/one\tB","Chris\tname/two\tC","David\tname/two\tD");
	testCommand("perl $prgdir/rdf.pl -d test delete % name/o% %","deleted 2");
	testCommand("perl $prgdir/rdf.pl -d test delete % name% %","deleted 2");
	rmdir("test/name");
	testCommand("perl $prgdir/rdf.pl -d test update A B#C D","updated 1");
	testCommand("perl $prgdir/rdf.pl -d test select","A\tB#C\tD");
	testCommand("perl $prgdir/rdf.pl -d test update A B#C E","updated 1");
	testCommand("perl $prgdir/rdf.pl -d test select","A\tB#C\tE");
	testCommand("perl $prgdir/rdf.pl -d test insert A B D","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test select A B","A\tB\tD");
	testCommand("perl $prgdir/rdf.pl -d test select A B#C","A\tB#C\tE");
	testCommand("perl $prgdir/rdf.pl -d test select A B%","A\tB\tD","A\tB#C\tE");
	testCommand("perl $prgdir/rdf.pl -d test select A B#%","A\tB#C\tE");
	testCommand("perl $prgdir/rdf.pl -d test delete A B%","deleted 2");
	testCommand("perl $prgdir/rdf.pl -d test insert A B C","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test insert A B#D C","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test insert A B#E C","inserted 1");
	testCommand("cat test/B.txt","A\tC","A\tD\tC","A\tE\tC");
	testCommand("perl $prgdir/rdf.pl select A test/B","A\ttest/B\tC");
	testCommand("perl $prgdir/rdf.pl select A test/B#D","A\ttest/B#D\tC");
	testCommand("perl $prgdir/rdf.pl select A test/B#%","A\ttest/B#D\tC","A\ttest/B#E\tC");
	testCommand("perl $prgdir/rdf.pl select A test/B%","A\ttest/B\tC","A\ttest/B#D\tC","A\ttest/B#E\tC");
	testCommand("perl $prgdir/rdf.pl -d test delete A B#%","deleted 2");
	testCommand("perl $prgdir/rdf.pl -d test delete A B%","deleted 1");
	#Testing directory and file priority (file has more priority)
	mkdir("test/name");
	testCommand("perl $prgdir/rdf.pl -d test insert A name Akira","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test select A name","A\tname\tAkira");
	testCommand("perl $prgdir/rdf.pl select A test/name","A\ttest/name\tAkira");
	testCommand("perl $prgdir/rdf.pl -d test insert A name/one Akita","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test select A name","A\tname\tAkira");
	testCommand("perl $prgdir/rdf.pl -d test select A name/one","A\tname/one\tAkita");
	testCommand("perl $prgdir/rdf.pl -d test insert B name/one Benben","inserted 1");
	testCommand("perl $prgdir/rdf.pl -d test select A name/%","A\tname/one\tAkita");
	# name.txt exists and name/ exits
	# select % name will select file test/name.txt because it has more priority
	testCommand("perl $prgdir/rdf.pl -d test select","A\tname\tAkira","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $prgdir/rdf.pl -d test select % name","A\tname\tAkira");
	testCommand("perl $prgdir/rdf.pl -d test select % name/","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $prgdir/rdf.pl -d test select % name/%","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $prgdir/rdf.pl -d test select A","A\tname\tAkira","A\tname/one\tAkita");
	# name.txt doesn't exist and name/ exits
	# select % name will select all files under name/ directory
	unlink("test/name.txt");
	testCommand("perl $prgdir/rdf.pl -d test select","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $prgdir/rdf.pl -d test select % name","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $prgdir/rdf.pl -d test select % name/","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $prgdir/rdf.pl -d test select % name/%","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $prgdir/rdf.pl -d test select A","A\tname/one\tAkita");
	unlink("test/name/one.txt");
	rmdir("test/name");
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
############################## testSub ##############################
sub testSub{
	my $command=shift();
	my $value2=shift();
	my $value1=eval($command);
	if(equals($value1,$value2)){return 0;}
	print STDERR ">$command\n";
	printTable($value1);
	printTable($value2);
}
############################## toNodesAndEdges ##############################
sub toNodesAndEdges{
	my $directory=shift();
	my @files=listFiles(undef,undef,-1,$directory);
	my $hashs={};
	my @nodes=();
	my @edges=();
	my $nodeIndex=0;
	foreach my $file(@files){
		my $reader=openFile($file);
		my $p=getPredicateFromFile($file);
		while(<$reader>){
			chomp;
			my ($s,$o)=split(/\t/);
			if(!exists($hashs->{$s})){
				$hashs->{$s}=$nodeIndex;
				push(@nodes,{"id"=>$nodeIndex++,"label"=>$s});
			}
			if(!exists($hashs->{$o})){
				$hashs->{$o}=$nodeIndex;
				push(@nodes,{"id"=>$nodeIndex++,"label"=>$o});
			}
			push(@edges,{"from"=>$hashs->{$s},"label"=>$p,"to"=>$hashs->{$o}});
		}
		close($reader);
	}
	foreach my $node(@nodes){
		my $label=$node->{"label"};
		if($label=~/^.+\.\w{3,4}$/){$node->{"shape"}="box";}
	}
	return (\@nodes,\@edges);
}
############################## tripleSelect ##############################
sub tripleSelect{
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	if($predicate=~/\/$/){$predicate.="%";}
	if(!defined($subject)){$subject="%";}
	if(!defined($predicate)){$predicate="%";}
	if(!defined($object)){$object="%";}
	$subject=~s/\%/.*/g;
	$object=~s/\%/.*/g;
	my @files=();
	if($predicate!~/\%/){#predicate has no ambiguity
		my $path=getFileFromPredicate($predicate);
		if(-d $path){#no file, but directory found
			if($predicate=~/\/$/){$predicate.=".*";}
			else{$predicate.="/.*";}
			@files=listFiles(undef,undef,-1,$path);
		}elsif(-e $path){push(@files,$path);}#file found
	}else{#predicate is wildcard
		$predicate=~s/\%/.*/g;
		my $dir=getDirFromPredicate($predicate);
		@files=listFiles(undef,undef,-1,$dir);
		@files=narrowDownByPredicate($dbdir,$predicate,@files);
	}
	my $results={};
	foreach my $file(@files){
		my $pre=getPredicateFromFile($file);
		if(!-e $file){next;}
		my $reader=openFile($file);
		while(<$reader>){
			chomp;
			my @tokens=split(/\t/);
			my $size=scalar(@tokens);
			my $s=$tokens[0];
			my $p;
			my $o;
			if($size==2){
				$p=$pre;
				$o=$tokens[1];
			}elsif($size==3){
				$p="$pre#".$tokens[1];
				$o=$tokens[2];
			}
			if($s!~/^$subject$/){next;}
			if($p!~/^$predicate$/){next;}
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

############################## unusedSubs ##############################
sub unusedSubs{
	my $path="$prgdir/$program_name";
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
############################## which ##############################
sub which{
	my $cmd=shift();
	my $hash=shift();
	if(!defined($hash)){$hash={};}
	if(exists($hash->{$cmd})){return $hash->{$cmd};}
	my $server;
	my $command=$cmd;
	if($command=~/^(.+\@.+)\:(.+)$/){
		$server=$1;
		$command=$2;
	}
	my $result;
	if(defined($server)){
		open(CMD,"ssh $server 'which $command' 2>&1 |");
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
