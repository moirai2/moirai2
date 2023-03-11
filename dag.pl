#!/usr/bin/perl
use strict 'vars';
use Cwd;
use File::Basename;
use File::Temp qw/tempfile tempdir/;
use FileHandle;
use Getopt::Std;
use File::Path;
use Time::HiRes;
use Time::Local;
use Time::localtime;
############################## HEADER ##############################
my($program_name,$program_directory,$program_suffix)=fileparse($0);
$program_directory=substr($program_directory,0,-1);
my $program_version="2023/03/11";
############################## OPTIONS ##############################
use vars qw($opt_d $opt_D $opt_f $opt_g $opt_G $opt_h $opt_i $opt_o $opt_q $opt_r $opt_s $opt_x);
getopts('d:D:f:g:G:hi:qo:r:s:w:x');
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
	print "             export  export database content to moirai2.pl HTML from html\n";
	print "             import  Import triple(s)\n";
	print "             insert  Insert triple(s)\n";
	print "            process  Process input/delete/update input\n";
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
	print "     -g  Grep for filestats, filesize, linecount, md5, seqcount\n";
	print "     -G  Ungrep for filestats, filesize, linecount, md5, seqcount\n";
	print "     -h  show help message\n";
	print "     -i  Input query for propt mode\n";
	print "     -o  Output query for propt mode\n";
	print "     -q  quiet mode\n";
	print "     -r  Recursive mode for filestats, filesize, linecount, md5, seqcount (default=0,-1 for infinite)\n";
	print "     -s  separate delimiter (default='\t')\n";
	print "     -x  Expand query results (default='limit to only matching')\n";
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
	print "  - Insert 'A->B->C' triple, if 'A->B->?' is not found in the directed acyclic graph (DAG) database.\n";
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
	"(\\.sam)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitSam,
	"\\.runinfo\\.csv(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitRunInfo,
	"\\.openprot\\.tsv(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>\&splitTsv,
	"\\.bam?\$"=>\&splitSam,
	"\\.sqlite3?\$"=>\&splitSqlite3,
	"\\.db?\$"=>\&splitSqlite3
};
my $fileIndeces={
	#"(\\.te?xt)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>undef,
	"(\\.f(ast)?a)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>["id","sequence"],
	"(\\.f(ast)?q)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>["id","sequence"],
	"(\\.tsv)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>[0,1],
	"(\\.csv)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>[0,1],
	"(\\.gtf)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>["position","attribute"],
	"(\\.bed)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>["name","position"],
	"(\\.sam)(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>["qname","position"],
	"\\.runinfo\\.csv(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>["Run","download_path"],
	"\\.openprot\\.tsv(\\.gz(ip)?|\\.bz(ip)?2)?\$"=>[0,1],
	"\\.bam?\$"=>["qname","position"],
	"\\.sqlite3?\$"=>['*'],
	"\\.db?\$"=>[0,1]
};
############################## MAIN ##############################
if(defined($opt_h)||scalar(@ARGV)==0){
	my $command=shift(@ARGV);
	if($command eq"config"){help_config();}
	elsif($command eq"prompt"){help_prompt();}
	else{help();}
	exit(0);
}
my $command=shift(@ARGV);
my $rootdir=absolutePath(".");
my $dbdir=defined($opt_d)?checkDirPathIsSafe($opt_d):".";
my $moiraidir=".moirai2";
my $cmdHash={};
my $md5cmd=which('md5sum',$cmdHash);
if(!defined($md5cmd)){$md5cmd=which('md5',$cmdHash);}
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
elsif($command=~/^process$/i){commandProcess(@ARGV);}
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
############################## arrayAssignRank ##############################
sub arrayAssignRank{
	my $array=shift();
	my $reverse=shift();
	my $average=shift();
	my $depth=checkArrayDimension($array);
	if($depth==0){print STDERR "Please make sure input is array\n";exit(1);}
	my $hash=arrayCalculateRank($array,$reverse,$average);
	return arrayAssignRankR($array,$hash);
}
sub arrayAssignRankR{
	my $array=shift();
	my $hash=shift();
	my $ranked=[];
	my $size=scalar(@{$array});
	for(my $i=0;$i<$size;$i++){
		my $v=$array->[$i];
		if(ref($v)eq"ARRAY"){$ranked->[$i]=arrayAssignRankR($v,$hash);}
		else{$ranked->[$i]=$hash->{$array->[$i]};}
	}
	return $ranked;
}
############################## arrayCalculateRank ##############################
sub arrayCalculateRank{
	my $array=shift();
	my $reverse=shift();
	my $average=shift();
	my $hash={};
	retrieveValuesFromArrayR($array,$hash);
	my @values=keys(%{$hash});
	if($reverse){@values=sort{$b<=>$a}@values;}
	else{@values=sort{$a<=>$b}@values;}
	my $rank=1;
	if(defined($average)){
		for(my $i=0;$i<scalar(@values);$i++){
			my $value=@values[$i];
			my $count=$hash->{$value};
			my $total=0;
			for(my $j=0;$j<$count;$j++){$total+=$rank;$rank++;}
			$hash->{$value}=$total/$count;
		}
	}else{
		for(my $i=0;$i<scalar(@values);$i++){
			my $value=@values[$i];
			my $count=$hash->{$value};
			$hash->{$value}=$rank;
			$rank+=$count;
		}
	}
	return $hash;
}
############################## assignResults ##############################
sub assignResults{
	my $results=shift();
	my $key=shift();
	my $val=shift();
	if(!defined($val)){return;}
	if($val=~/^\{/){return;}#Can't handle json in hash format
	if($val=~/^\[/){$val=jsonDecode($val);}#Can handle json in array format
	if(ref($val)ne"ARRAY"){$val=[$val];}
	my $results2=[];
	foreach my $v(@{$val}){
		if(ref($v)eq"ARRAY"){print STDERR "WARNING: '$v' can't be ARRAY.  Ignoring this value.\n";next;}
		if(ref($v)eq"HASH"){print STDERR "WARNING: '$v' can't be HASH.  Ignoring this value.\n";next;}
		push(@{$results2},$v);
	}
	my $size1=scalar(@{$results});
	my $size2=scalar(@{$results2});
	if($size2==0){return;}
	if($size1==0){$results->[0]={};$size1=1;}
	if($size2>1){
		for(my $i=1;$i<$size2;$i++){
			for(my $j=0;$j<$size1;$j++){
				my $h1=$results->[$j];
				$results->[$i*$size1+$j]={};
				while(my($key,$val)=each(%{$h1})){
					$results->[$i*$size1+$j]->{$key}=$val;
				}
			}
		}
	}
	for(my $i=0;$i<$size2;$i++){
		my $val2=$results2->[$i];
		for(my $j=0;$j<$size1;$j++){
			$results->[$i*$size1+$j]->{$key}=$val2;
		}
	}
}
############################## avgArray ##############################
sub avgArray{
	my @data=@_;
	my $total=0;
	foreach(@data){$total+=$_;}
	my $count=scalar(@data);
	if($count==0){return;}
	my $average=$total/$count;
	return $average;
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
############################## checkArrayDimension ##############################
sub checkArrayDimension{
	my $array=shift();
	return checkArrayDimensionR($array,0);
}
sub checkArrayDimensionR{
	my $array=shift();
	my $depth=shift();
	if(ref($array)ne"ARRAY"){return $depth;}
	my $size=scalar(@{$array});
	my $maxDepth=$depth;
	for(my $i=0;$i<$size;$i++){
		my $d=checkArrayDimensionR($array->[$i],$depth+1);
		if($d>$maxDepth){$maxDepth=$d;}
	}
	return $maxDepth;
}
############################## checkBinary ##############################
sub checkBinary{
	my $file=shift();
	while(-l $file){$file=readlink($file);}
	my $result=`file --mime $file`;
	if($result=~/charset\=binary/){return 1;}
}
############################## checkDagQuery ##############################
sub checkDagQuery{
	my $queries=shift();
	foreach my $query(split(/,/,$queries)){
		my @tokens=split(/->/,$query);
		if(scalar(@tokens)!=3){return;}
	}
	return 1;
}
############################## checkDirPathIsSafe ##############################
sub checkDirPathIsSafe{
	my $directory=shift();
	if($directory=~/\.\./){
		print STDERR "ERROR: Please don't use '..' for a directory path '$directory'\n";
		exit(1);
	}elsif($directory=~/^\//){
		print STDERR "ERROR: Please don't use absolute path for a directory path '$directory'\n";
		exit(1);
	}elsif($directory=~/\|/){
		print STDERR "ERROR: Please don't use pipe for a directory path '$directory'\n";
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
############################## checkTimestamp ##############################
sub checkTimestamp{
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){
		my $stat=`ssh $1 'perl -e \"my \@array=stat(\\\$ARGV[0]);print \\\$array[9]\" $2'`;
		if($stat eq ""){return;}
		return $stat;
	}elsif($path=~/^https?:\/\//){
		my $wgetCmd=which('wget',$cmdHash);
		if(defined($wgetCmd)){
			my @lines=`$wgetCmd -qS --spider $path 2>&1`;
			foreach my $line(@lines){if($line=~/Last-Modified: (.+)$/){return convertGmtToSecond($1);}}
		}
		my $curlCmd=which('curl',$cmdHash);
		if(defined($curlCmd)){
			my @lines=`$curlCmd -sIL $path`;
			foreach my $line(@lines){if($line=~/Last-Modified: (.+)$/){return convertGmtToSecond($1);}}
		}
		print STDERR "Please install wget or curl tools\n";
		exit(1);
	}else{
		my @stats=stat($path);
		return $stats[9];
	}
}
############################## checkTripleAnchor ##############################
# return 2 if it's a triple with index
# return 1 if it's a triple with anchor
# return 0 if no anchor found
sub checkTripleAnchor{
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $anchor=shift();
	if($subject=~/^\(\$(\{\w+\}|\w+)\)$/){return;}
	if($object=~/^\(\$(\{\w+\}|\w+)\)$/){return;}
	$predicate=basename($predicate);
	foreach my $suffix(sort{$b cmp $a}keys(%{$fileSuffixes})){if($predicate=~/^(.+)$suffix/){return 2;}}#index.csv
	my @index=split(/\:/,$anchor);#table#0:1 table#0:1,2 table#index:number
	if(scalar(@index)>1){return 2;}
	return 1;#triple#number
}
############################## checkValueType ##############################
sub checkValueType{
	my $type=shift();
	my $value=shift();
	#priority: TEXT > REAL > INTEGER
	if(ref($value)eq"ARRAY"){return "text";}
	if($type eq "text"){
		return "text";
	}elsif($type eq "real"){
		if($value=~/\d+\.\d+/){return "real";}
		else{return "text";}
	}
	if($value=~/\d+/){return "integer";}
	elsif($value=~/\d+\.\d+/){return "real";}
	else{return "text";}
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
		print STDERR "perl $program_directory/dag.pl config FILE\n";
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
		print STDERR "perl $program_directory/dag.pl config FILE";
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
		if(/^\s*$/){next;}
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
	my @args=@_;
	my $json;
	if(scalar(@args)>0){
		$json=tripleSelect(@args);
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
		my ($writer,$tempfile)=tempfile(UNLINK=>1);
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
			my $anchor;
			if($p=~/^(.+)#(.+)$/){$p=$1;$anchor=$2;}
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
				if(defined($anchor)){push(@{$excess->{$p}},"$s\t$anchor\t$o");}
				else{push(@{$excess->{$p}},"$s\t$o");}
				next;
			}
			my $writer=$writers->{$p};
			if(!defined($writer)){next;}
			if(defined($anchor)){print $writer "$s\t$anchor\t$o\n";}
			else{print $writer "$s\t$o\n";}
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
		my ($writer2,$tempfile2)=tempfile(UNLINK=>1);
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
	my @args=@_;
	my $json;
	my $total=0;
	if(scalar(@args)>0){
		my $json={$args[0]=>{$args[1]=>$args[2]}};
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
		my ($writer,$tempfile)=tempfile(UNLINK=>1);
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
			my ($writer2,$tempfile2)=tempfile(UNLINK=>1);
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
	my @args=@_;
	my @files=();
	if(scalar(@args)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@args;}
	my $writer=IO::File->new(">&STDOUT");
	countLines($writer,$opt_g,$opt_G,$opt_r,@files);
	close($writer);
}
############################## commandMd5 ##############################
sub commandMd5{
	my @args=@_;
	my @files=();
	if(scalar(@args)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@args;}
	my $writer=IO::File->new(">&STDOUT");
	md5Files($writer,$opt_g,$opt_G,$opt_r,@files);
	close($writer);
}
############################## commandProcess ##############################
#Only allows tsv format
#order is delete, insert, and update
sub commandProcess{
	my @args=@_;
	my ($deleteWriter,$deleteTemp)=tempfile(UNLINK=>1);
	my ($insertWriter,$insertTemp)=tempfile(UNLINK=>1);
	my ($updateWriter,$updateTemp)=tempfile(UNLINK=>1);
	my $deleteCount=0;
	my $insertCount=0;
	my $updateCount=0;
	while(<STDIN>){
		chomp;
		if(/^delete\s(.+)$/i){
			my ($sub,$pre,$obj,$anchor)=commandProcessSplit($1);	
			print $deleteWriter "$pre\t$anchor\t$sub\t$obj\n";
			$deleteCount++;
		}elsif(/^insert\s(.+)$/i){
			my ($sub,$pre,$obj,$anchor)=commandProcessSplit($1);
			print $insertWriter "$pre\t$anchor\t$sub\t$obj\n";
			$insertCount++;
		}elsif(/^update\s(.+)$/i){
			my ($sub,$pre,$obj,$anchor)=commandProcessSplit($1);
			print $updateWriter "$pre\t$anchor\t$sub\t$obj\n";
			$updateCount++;
		}
	}
	close($deleteWriter);
	close($insertWriter);
	close($updateWriter);
	if($deleteCount==0){unlink($deleteTemp);}
	else{
		$deleteCount=processTsv(\&deleteTsv,$deleteTemp);
		if(!defined($opt_q)){print "deleted $deleteCount\n";}
	}
	if($insertCount==0){unlink($insertTemp);}
	else{
		$insertCount=processTsv(\&insertTsv,$insertTemp);
		if(!defined($opt_q)){print "inserted $insertCount\n";}
	}
	if($updateCount==0){unlink($updateTemp);}
	else{
		$updateCount=processTsv(\&updateTsv,$updateTemp);
		if(!defined($opt_q)){print "updated $updateCount\n";}
	}
}
############################## commandProcessSplit ##############################
sub commandProcessSplit{
	my $line=shift();
	my $s;
	my $p;
	my $o;
	if($line=~/^(.+)\-\>(.+)\-\>(.+)$/){$s=$1;$p=$2;$o=$3;}
	elsif($line=~/^(.+)\t(.+)\t(.+)$/){$s=$1;$p=$2;$o=$3;}
	elsif($line=~/^(.+)\,(.+)\,(.+)$/){$s=$1;$p=$2;$o=$3;}
	elsif($line=~/^(.+)\s(.+)\s(.+)$/){$s=$1;$p=$2;$o=$3;}
	if($p=~/^(.+)#(.+)$/){return ($s,$1,$o,$2);}
	else{return ($s,$p,$o);}
}
############################## commandPrompt ##############################
sub commandPrompt{
	my @args=@_;
	my ($arguments,$userdefined)=handleArguments(@args);
	my $results=[[],[{}]];
	if(defined($opt_i)){
		my $query=$opt_i;
		while(my($key,$val)=each(%{$userdefined})){$query=~s/\$$key/$val/g;}
		checkInputOutput($query);
		if(checkDagQuery($query)){
			my @hashs=queryResults($opt_x,[],$query);
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
	my @args=@_;
	my $delim=defined($opt_s)?$opt_s:" ";
	my @queries=();
	my @results=();
	foreach my $arg(@args){
		foreach my $token(@{splitTokenByComma($arg)}){splitQueries($token,\@queries,\@results);}
	}
	if(scalar(@queries)==0&&scalar(@results)==0){
		while(<STDIN>){
			chomp;
			foreach my $token(@{splitTokenByComma($_)}){splitQueries($token,\@queries,\@results);}
		}
	}
	foreach my $query(@queries){downloadUrlFromQuery($query);}
	if(!defined($opt_f)){$opt_f="tsv";}
	my @results=queryResults($opt_x,\@results,@queries);
	my ($writer,$tempfile)=tempfile(UNLINK=>1);
	if($opt_f eq "json"){
		print $writer jsonEncode(\@results)."\n";
	}elsif($opt_f=~/^sqlite3/){
		my @tokens=split(/\:/,$opt_f);shift(@tokens);
		my $databaseName;
		my $tableName;
		if(scalar(@tokens)>1){
			$databaseName=$tokens[0];
			$tableName=$tokens[1];
		}elsif(scalar(@tokens)>0){
			$tableName=$tokens[0];
		}
		if(defined($databaseName)){
			if($databaseName!~/\./){$databaseName.=".db";}
			if(defined($dbdir)){$databaseName="$dbdir/$databaseName";}
		}
		if(!defined($tableName)){$tableName="root";}
		my $temp={};
		foreach my $res(@results){foreach my $key(keys(%{$res})){$temp->{$key}++;}}
		my @variables=sort{$a cmp $b}keys(%{$temp});
		my $types=sqliteCheckType(\@variables,\@results);
		my $line="drop table if exists \"$tableName\"";
		my $line="create table if not exists \"$tableName\"(";
		for(my $i=0;$i<scalar(@variables);$i++){
			my $variable=$variables[$i];
			my $type=$types->{$variable};
			if($i>0){$line.=","}
			$line.="$variable $type";
		}
		$line.=");";
		print $writer "$line\n";
		foreach my $h(@results){
			my $line="insert into \"$tableName\" values(";
			for(my $i=0;$i<scalar(@variables);$i++){
				my $variable=$variables[$i];
				my $type=$types->{$variable};
				if($i>0){$line.=","}
				if($type eq "text"){$line.="\"".$h->{$variable}."\"";}
				else{$line.=$h->{$variable};}
			}
			$line.=");";
			print $writer "$line\n";
		}
		close($writer);
		if(defined($databaseName)){
			my $command="cat $tempfile | sqlite3 $databaseName";
			if(!defined($opt_q)){print "created 1\n"}
			system($command);
		}else{
			my $command="cat $tempfile";
			system($command);
		}
		unlink($tempfile);
		return;
	}elsif($opt_f eq "tsv"){
		my $temp={};
		foreach my $res(@results){foreach my $key(keys(%{$res})){$temp->{$key}++;}}
		my @variables=sort{$a cmp $b}keys(%{$temp});
		print $writer join("\t",@variables)."\n";
		foreach my $res(@results){
			my $line="";
			for(my $i=0;$i<scalar(@variables);$i++){
				my $key=$variables[$i];
				my $value=$res->{$key};
				if($i>0){$line.="\t";}
				if(ref($value)eq"ARRAY"){$line.=join($delim,@{$value});}
				else{$line.=$value;}
			}
			print $writer "$line\n";
		}
	}else{
		my $temp={};
		foreach my $res(@results){
			my $line=$opt_f;
			$line=~s/\\t/\t/g;
			$line=~s/\\n/\n/g;
			$line=~s/\$dbdir/$dbdir/g;
			foreach my $key(keys(%{$res})){
				my $val=$res->{$key};
				$line=~s/\$\{$key\}/$val/g;
				$line=~s/\$$key/$val/g;
			}
			print $writer "$line\n";
		}
	}
	close($writer);
	if(defined($opt_o)){moveTempToDest($tempfile,$opt_o);}
	else{system("cat $tempfile");}
	unlink($tempfile);
}
############################## commandSelect ##############################
sub commandSelect{
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	downloadUrlFromPredicate($predicate);
	my $results=tripleSelect($subject,$predicate,$object);
	if(!defined($opt_f)){$opt_f="tsv";}
	if($opt_f eq "tsv"){printTripleInTSVFormat($results);}
	elsif($opt_f eq "json"){print jsonEncode($results)."\n";}
}
############################## commandSeqcount ##############################
sub commandSeqcount{
	my @args=@_;
	my @files=();
	if(scalar(@args)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@args;}
	my $writer=IO::File->new(">&STDOUT");
	countSequences($writer,$opt_g,$opt_G,$opt_r,@files);
	close($writer);
}
############################## commandSplit ##############################
sub commandSplit{
	my @args=@_;
	my $utility=shift(@args);
	if($utility eq "gtf"){commandSplitGtfByFeature(@args);}
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
		$predicate=~s/\%/\*/g;
		$predicate=~s/\#\w+$//g;
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
	my @args=@_;
	my $total=0;
	if(scalar(@args)>0){
		my $json={$args[0]=>{$args[1]=>$args[2]}};
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
		my ($writer,$tempfile)=tempfile(UNLINK=>1);
		if(! -e $file){mkdirs(dirname($file));}
		if(defined($anchor)){
			my $reader=openFile($file);
			while(<$reader>){
				chomp;
				my @token=split(/\t/);
				if(scalar(@token)==3){if(exists($hash->{$token[0]})&&$anchor eq $token[1]){next;}}
				print $writer join("\t",@token)."\n";
				$count++;
			}
			close($reader);
			foreach my $s(keys(%{$hash})){
				if(!exists($hash->{$s})){next;}
				foreach my $o(@{$hash->{$s}}){
					print $writer "$s\t$anchor\t$o\n";$updated++;$count++;
				}
			}
		}else{
			my $reader=openFile($file);
			while(<$reader>){
				chomp;
				my @token=split(/\t/);
				if(scalar(@token)==2){if(exists($hash->{$token[0]})){next;}}
				print $writer join("\t",@token)."\n";
				$count++;
			}
			close($reader);
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
			my ($writer2,$tempfile2)=tempfile(UNLINK=>1);
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
############################## constructJoinKey ##############################
sub constructJoinKey{
	my $joinKeys=shift();
	my $hash=shift();
	my $joinKey;
	foreach my $key(@{$joinKeys}){
		if(defined($joinKey)){$joinKey.=" ";}
		$joinKey.=$hash->{$key};
	}
	return $joinKey;
}
############################## convertGmtToSecond ##############################
#https://currentmillis.com
#Sat, 20 Aug 2022 14:12:52 GMT => 1661004772
sub convertGmtToSecond{
	my $datestr=shift();
	my $monthToNumber={"Jan"=>0,"Feb"=>1,"Mar"=>2,"Apr"=>3,"May"=>4,"Jun"=>5,"Jul"=>6,"Aug"=>7,"Sep"=>8,"Oct"=>9,"Nov"=>10,"Dec"=>11};
	if($datestr=~/(\w+), (\d+) (\w+) (\d+) (\d+):(\d+):(\d+) GMT/){
		my $day=$2;
		my $month=$monthToNumber->{$3};
		my $year=$4;
		my $hour=$5;
		my $minute=$6;
		my $second=$7;
		return timegm($second,$minute,$hour,$day,$month,$year);
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
############################## cramersvCorrelation ##############################
sub cramersvCorrelation{
	my $x=shift();
	my $y=shift();
	my $table=createTextTextTable($x,$y);
	totalLabeledTable($table);
	expectedLabeledTable($table);
	my $tables=$table->{"tables"};
	my $expected=$table->{"expected"};
	my $rowSize=$table->{"rowSize"};
	my $colSize=$table->{"colSize"};
	my $sampleSize=$table->{"sampleSize"};
	my $minSize=($rowSize<$colSize)?$rowSize:$colSize;
	if($minSize<2){print STDERR "ERROR: Please make sure col/row sizes are >1";exit(1);}
	my $sum=0;
	for(my $i=0;$i<$rowSize;$i++){
		for(my $j=0;$j<$colSize;$j++){
			my $a=$tables->[$i]->[$j];
			my $b=$expected->[$i]->[$j];
			my $d=$a-$b;
			$sum+=$d*$d/$b;
		}
	}
	#printLabledTable($table);
	my $r=sqrt($sum/$sampleSize/($minSize-1));
	my $t=$r*sqrt(($sampleSize-2)/(1-$r*$r));
	$r=sprintf("%.2f",$r);
	$t=sprintf("%.2f",$t);
	return wantarray?($r,$t):$r;
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
############################## createTextNumberTable ##############################
sub createTextNumberTable{
	my $x=shift();
	my $y=shift();
	my $countX=scalar(@{$x});
	my $countY=scalar(@{$y});
	if($countX!=$countY){print STDERR "ERROR: Please make sure array sizes are same";exit(1);}
	my $hash={};
	my $rowHash={};
	for(my $i=0;$i<$countX;$i++){
		my $a=$x->[$i];
		my $b=$y->[$i];
		$rowHash->{$a}=1;
		if(!exists($hash->{$a})){$hash->{$a}=[];}
		push(@{$hash->{$a}},$b);
	}
	my @rowKeys=sort{$a<=>$b}keys(%{$rowHash});
	my $rowSize=scalar(@rowKeys);
	my $tables=[];
	my $colSize=0;
	for(my $i=0;$i<$rowSize;$i++){
		my $a=$rowKeys[$i];
		my $columns=$hash->{$a};
		my $size=scalar(@{$columns});
		if($size>$colSize){$colSize=$size;}
		$tables->[$i]=$columns;
	}
	my $hashtable={};
	$hashtable->{"tables"}=$tables;
	$hashtable->{"rows"}=\@rowKeys;
	$hashtable->{"cols"}=[];
	$hashtable->{"rowSize"}=$rowSize;
	$hashtable->{"colSize"}=$colSize;
	$hashtable->{"sampleSize"}=$countX;
	return $hashtable;
}
############################## createTextTextTable ##############################
sub createTextTextTable{
	my $x=shift();
	my $y=shift();
	my $countX=scalar(@{$x});
	my $countY=scalar(@{$y});
	if($countX!=$countY){print STDERR "ERROR: Please make sure array sizes are same";exit(1);}
	my $hash={};
	my $rowHash={};
	my $colHash={};
	for(my $i=0;$i<$countX;$i++){
		my $a=$x->[$i];
		my $b=$y->[$i];
		$rowHash->{$a}=1;
		$colHash->{$b}=1;
		if(!exists($hash->{$a})){$hash->{$a}={};}
		$hash->{$a}->{$b}++;
	}
	my @rowKeys=sort{$a<=>$b}keys(%{$rowHash});
	my $rowSize=scalar(@rowKeys);
	my @colKeys=sort{$a<=>$b}keys(%{$colHash});
	my $colSize=scalar(@colKeys);
	my $tables=[];
	for(my $i=0;$i<$rowSize;$i++){
		$tables->[$i]=[];
		for(my $j=0;$j<$colSize;$j++){
			$tables->[$i]->[$j]=0;
		}
	}
	for(my $i=0;$i<$rowSize;$i++){
		my $a=$rowKeys[$i];
		if(!exists($hash->{$a})){next;}
		for(my $j=0;$j<$colSize;$j++){
			my $b=$colKeys[$j];
			if(!exists($hash->{$a}->{$b})){next;}
			my $count=$hash->{$a}->{$b};
			$tables->[$i]->[$j]=$count;
		}
	}
	my $hashtable={};
	$hashtable->{"tables"}=$tables;
	$hashtable->{"rows"}=\@rowKeys;
	$hashtable->{"cols"}=\@colKeys;
	$hashtable->{"rowSize"}=$rowSize;
	$hashtable->{"colSize"}=$colSize;
	$hashtable->{"sampleSize"}=$countX;
	return $hashtable;
}
############################## deleteTsv ##############################
sub deleteTsv{
	my $predicate=shift();
	my $tempfile=shift();
	my $writer=shift();
	close($writer);
	my $file=getFileFromPredicate($predicate);
	if($file=~/\.gz$/){return;}
	elsif($file=~/\.bz2$/){return;}
	elsif(-d $file){return;}
	my $hash1=readTsvToKeyValHash($file);#original
	my $hash2=readTsvToKeyValHash($tempfile);#updates
	my $count=0;
	while(my($key,$val)=each(%{$hash2})){if(exists($hash1->{$key})){delete($hash1->{$key});$count++;}}
	writeKeyValHash($file,$hash1);
	return $count;
}
############################## downloadUrl ##############################
sub downloadUrl{
	my $url=shift();
	my $outpath=shift();
	my $timestamp1=checkTimestamp($url);
	if(!defined($timestamp1)){print STDERR "$url not found...\n";return;}
	my $timestamp2=checkTimestamp($outpath);
	if(defined($timestamp2)){if($timestamp1<=$timestamp2){return 1;}}
	if(!defined($opt_q)){print STDERR "Downloading $url to $outpath\n";}
	mkdirs(dirname($outpath));
	my $wgetCmd=which('wget',$cmdHash);
	if(defined($wgetCmd)){system("wget -N -qO $outpath $url");if(-e $outpath){return 1;}}
	my $wgetCmd=which('curl',$cmdHash);
	if(defined($wgetCmd)){system("curl -s -R -o $outpath $url");if(-e $outpath){return 1;}}
	if(!defined($wgetCmd)&&!defined($wgetCmd)){print STDERR "Please install wget or curl tools\n";}
	else{print STDERR "Failed to download $url to $outpath\n";}
	exit(1);
}
############################## downloadUrlFromJson ##############################
sub downloadUrlFromJson{
	my $json=shift();
	my $hash={};
	foreach my $s(keys(%{$json})){foreach my $p(keys(%{$json->{$s}})){$hash->{$p}=1}}
	my $success=1;
	foreach my $predicate(keys(%{$hash})){if(!downloadUrlFromPredicate($predicate)){$success=undef;}}
	return $success;
}
############################## downloadUrlFromPredicate ##############################
sub downloadUrlFromPredicate{
	my $predicate=shift();
	if($predicate!~/https?:\/\//){return;}
	my $localfile=getFileFromPredicate($predicate);
	return downloadUrl($predicate,$localfile);
}
############################## downloadUrlFromQuery ##############################
sub downloadUrlFromQuery{
	my $query=shift();
	my ($subject,$predicate,$object)=split(/->/,$query);
	return downloadUrlFromPredicate($predicate);
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
############################## existsArray ##############################
sub existsArray{
	my $array=shift();
	my $value=shift();
	foreach my $val(@{$array}){if($value eq $val){return 1;}}
	return;
}
############################## expectedLabeledTable ##############################
sub expectedLabeledTable{
	my $hashtable=shift();
	my $rowSize=$hashtable->{"rowSize"};
	my $colSize=$hashtable->{"colSize"};
	my $tables=$hashtable->{"tables"};
	my $rowTotals=$hashtable->{"rowTotals"};
	my $colTotals=$hashtable->{"colTotals"};
	my $total=$hashtable->{"total"};
	my $expectTable=[];
	for(my $i=0;$i<$rowSize;$i++){
		my $rowTotal=$rowTotals->[$i];
		for(my $j=0;$j<$colSize;$j++){
			my $colTotal=$colTotals->[$j];
			$expectTable->[$i]->[$j]=$rowTotal*$colTotal/$total;
		}
	}
	$hashtable->{"expected"}=$expectTable;
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
############################## functionAvg ##############################
sub functionAvg{
	my $value=shift();
	if(ref($value)ne"ARRAY"){return $value;}
	my $total;
	my $size=scalar(@{$value});
	foreach my $v(@{$value}){$total+=$v;}
	return ($total/$size);
}
############################## functionCount ##############################
sub functionCount{
	my $value=shift();
	if(ref($value)ne"ARRAY"){return 1;}
	return scalar(@{$value});
}
############################## functionMax ##############################
sub functionMax{
	my $value=shift();
	if(ref($value)ne"ARRAY"){return $value;}
	my $max;
	foreach my $val(@{$value}){
		if(!defined($max)){$max=$val;}
		elsif($val>$max){$max=$val;}
	}
	return $max;
}
############################## functionMin ##############################
sub functionMin{
	my $value=shift();
	if(ref($value)ne"ARRAY"){return $value;}
	my $min;
	foreach my $val(@{$value}){
		if(!defined($min)){$min=$val;}
		elsif($val<$min){$min=$val;}
	}
	return $min;
}
############################## functionSplit ##############################
sub functionSplit{
	my $delim=shift();
	my $value=shift();
	if(ref($value)ne"ARRAY"){
		my @tokens=split(/$delim/,$value);
		return \@tokens;
	}else{
		my @tokens=();
		foreach my $v(@{$value}){
			push(@tokens,split(/$delim/,$v));
		}
		return \@tokens;
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
	if($predicate=~/^(https?):\/\/(.+)$/){
		$predicate="$1/$2";
		if($predicate=~/^(.+)#(.+)$/){$predicate=$1;$anchor=$2;}
		return $predicate;
	}elsif($predicate=~/^(.+)\@(.+)\:(.+)$/){
		$predicate="ssh/$1/$2/$3";
		if($predicate=~/^(.+)#(.+)$/){$predicate=$1;$anchor=$2;}
		return $predicate;
	}
	if($predicate=~/^(.+)#(.+)$/){$predicate=$1;$anchor=$2;}
	if($predicate=~/^(.+)\.json$/){$predicate=$1;}
	if($predicate=~/^(.+)\/$/){$predicate=$1;}
	if($predicate=~/\.\w{2,4}$/ && -e $predicate){
		foreach my $suffix(sort{$b cmp $a}keys(%{$fileSuffixes})){
			if($predicate=~/$suffix$/){return $predicate;}
		}
	}
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
		if($directory eq"."){push(@files,$file);}
		else{push(@files,"$directory/$file");}
	}
	closedir(DIR);
	return @files;
}
############################## getFilesByLs ##############################
sub getFilesByLs{
	my $directory=shift();
	if(-d $directory){$directory="$directory/*";}
	my @files=`ls $directory`;
	my @outs=();
	my $isDir=0;
	foreach my $file(@files){
		chomp($file);
		if($file=~/^(.+):$/){$file=$1;$isDir=1;}
		elsif($file eq ""){$isDir=0;next;}
		elsif($isDir==1){next;}
		push(@outs,$file);
	}
	return sort{$a cmp $b}@outs;
}
############################## getFilesFromQuery ##############################
sub getFilesFromQuery{
	my $predicate=shift();
	my $dir=shift();
	my $results=shift();
	my @predicates=();
	if(!defined($dir)){$dir=$dbdir;}
	if(defined($results)){
		foreach my $hash(@{$results}){
			my $pre=$predicate;
			foreach my $key(sort{$b cmp $a}keys(%{$hash})){
				my $val=$hash->{$key};
				$pre=~s/\$$key/$val/g;
			}
			push(@predicates,$pre);
		}
	}else{
		push(@predicates,$predicate);
	}
	my $temp={};
	foreach my $predicate(@predicates){
		my $anchor;
		if($predicate=~/^(https?):\/\/(.+)$/){
			$predicate="$1/$2";
			if(-e $predicate){return $predicate;}
		}elsif($predicate=~/^(.+)\@(.+)\:(.+)/){
			$predicate="ssh/$1/$2/$3";
			if(-e $predicate){return $predicate;}
		}
		if($predicate=~/^(.+)#(.+)$/){$predicate=$1;$anchor=$2;}
		if($predicate=~/^(.+)\.json$/){$predicate=$1;}
		if($predicate=~/^(.+)\/$/){$predicate=$1;}
		if($predicate=~/\$/){
			$predicate=~s/(\$\w+)/\*/g;
			foreach my $file(getFilesFromQuerySub("$dir/$predicate*")){$temp->{$file}=1;}
		}else{
			if($predicate=~/\.\w{2,4}$/ && -e $predicate){
				foreach my $suffix(sort{$b cmp $a}keys(%{$fileSuffixes})){
					if($predicate=~/$suffix$/){
						$temp->{$predicate}=1;
						last;
					}
				}
			}elsif(-e "$dir/$predicate.txt"){$temp->{"$dir/$predicate.txt"}=1;}
			elsif(-e "$dir/$predicate.txt.gz"){$temp->{"$dir/$predicate.txt.gz"}=1;}
			elsif(-e "$dir/$predicate.txt.bz2"){$temp->{"$dir/$predicate.txt.bz2"}=1;}
			elsif(-d "$dir/$predicate"){
				foreach my $file(getFilesFromQuerySub("$dir/$predicate")){$temp->{$file}=1;}
			}else{
				foreach my $file(getFilesFromQuerySub("$dir/$predicate*")){$temp->{$file}=1;}
			}
		}
	}
	my @files=();
	foreach my $file(sort{$a cmp $b}keys(%{$temp})){push(@files,$file);}
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
	elsif($dirname eq "."){}
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
############################## getSchemaFromSqlite3 ##############################
sub getSchemaFromSqlite3{
	my $file=shift();
	my @tables=`sqlite3 $file .schema`;
	my $hash={};
	foreach my $table(@tables){
		chomp($table);
		if($table=~/^CREATE TABLE IF NOT EXISTS (.+)$/){$table=$1;}
		if($table=~/^CREATE TABLE (.+)$/){$table=$1;}
		if($table=~/^(.+)\((.+)\);$/){
			my $name=$1;
			my $tokens=$2;
			if($name=~/^\"(.+)\"$/){$name=$1;}
			$hash->{$name}=[];
			foreach my $token(split(/,/,$tokens)){
				my ($var,$type)=split(/ /,$token);
				push(@{$hash->{$name}},$var);
			}
		}
	}
	return $hash;
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
############################## handleTripleQueries ##############################
sub handleTripleQueries{
	my @queries=@_;
	my @triples=();
	my $anchorHashtable={};
	foreach my $query(@queries){
		my ($subject,$predicate,$object)=split(/\-\>/,$query);
		my $anchor;
		my $parameter;
		if($predicate=~/^(.+)\#(.+)$/){$predicate=$1;$anchor=$2;}
		if($predicate=~/^(.+)\?(.+)$/){$predicate=$1;$parameter=$2;}
		if(defined($anchor)){
			my $type=checkTripleAnchor($subject,$predicate,$object,$anchor);
			if($type==1){
				handleTripleQueriesMergeAnchors($anchorHashtable,\@triples,[$query,$subject,$predicate,$object,$anchor,$parameter]);
				next;
			}elsif($type==2){
				handleTripleQueriesMergeAnchors($anchorHashtable,\@triples,[$query,$subject,$predicate,$object,$anchor,$parameter],1);
				next;
			}
		}
		my $hash={"query"=>$query,"subject"=>$subject,"predicate"=>$predicate,"object"=>$object};
		if(defined($anchor)){$hash->{"anchor"}=$anchor;}
		if(defined($parameter)){$hash->{"parameter"}=$parameter;}
		push(@triples,$hash);
	}
	foreach my $triple(@triples){
		my $variables={};
		foreach my $key("subject","predicate","object"){
			if(!exists($triple->{$key})){next;}
			handleTripleQueriesRegexpVars($triple,$key,$variables);
		}
		if(exists($triple->{"anchor"})){
			if(ref($triple->{"anchor"})eq"HASH"){
				foreach my $key(keys(%{$triple->{"anchor"}})){
					handleTripleQueriesRegexpVars($triple->{"anchor"}->{$key},"predicate",$variables);
					handleTripleQueriesRegexpVars($triple->{"anchor"}->{$key},"object",$variables);
				}
			}else{
				handleTripleQueriesRegexpVars($triple,"anchor",$variables);
			}
		}
		my @keys=sort{$a cmp $b}keys(%{$variables});
		$triple->{"variables"}=\@keys;
	}
	return @triples;
}
############################## handleTripleQueriesFunction ##############################
sub handleTripleQueriesFunction{
	my @args=@_;
	my $triple=shift(@args);
	my $key=shift(@args);
	my $function=shift(@args);
	$triple->{"$key.join"}=1;
	if(!exists($triple->{"$key.functions"})){$triple->{"$key.functions"}=[];}
	unshift(@{$triple->{"$key.functions"}},[$function,@args]);
}
############################## handleTripleQueriesMergeAnchors ##############################
sub handleTripleQueriesMergeAnchors{
	my $hashtable=shift();
	my $triples=shift();
	my $tripleWithAnchors=shift();
	my $isIndex=shift();
	my $variables={};
	my ($query,$subject,$predicate,$object,$anchor,$parameter)=@{$tripleWithAnchors};
	my $pred=getPredicateFromFile($predicate);
	if(!exists($hashtable->{$subject})){$hashtable->{$subject}={};}
	if(!exists($hashtable->{$subject}->{$predicate})){
		my $tmp={};
		if(defined($isIndex)){$tmp->{"isIndex"}="true";}
		else{$tmp->{"isAnchor"}="true";}
		$tmp->{"query"}=[];
		$tmp->{"order"}=[];
		$tmp->{"subject"}=$subject;
		$tmp->{"predicate"}=$pred;
		if(defined($parameter)){
			my $hash={};
			foreach my $param(split(/\&/,$parameter)){
				my ($key,$val)=split(/\=/,$param);
				$hash->{$key}=$val;
			}
			$tmp->{"parameter"}=$hash;
		}
		$tmp->{"predicateUrl"}=$predicate;
		$tmp->{"anchor"}={};
		if($anchor=~/\$\w+/){$tmp->{"isVariableAnchor"}="true";}
		$hashtable->{$subject}->{$predicate}=$tmp;
		push(@{$triples},$tmp);
	}
	my $tmp=$hashtable->{$subject}->{$predicate};
	push(@{$tmp->{"query"}},$query);
	if(defined($isIndex)){
		my ($key,@vals)=split(/\:/,$anchor);
		my @objs=split(/\:/,$object);
		my $size=scalar(@vals);
		if($size!=scalar(@objs)){
			print STDERR "Number of anchors and values don't match\n";
			print STDERR "values=".join(",",@vals);
			print STDERR "objects=".join(",",@objs);
			exit(1);
		}
		$tmp->{"index"}=[$key,@vals];
		for(my $i=0;$i<$size;$i++){
			my $v=$vals[$i];
			my $o=$objs[$i];
			$tmp->{"anchor"}->{$v}={"predicate"=>"$pred#$v","object"=>$o};
		}
		for(my $i=0;$i<scalar(@vals);$i++){push(@{$tmp->{"order"}},$vals[$i]);}
	}else{
		push(@{$tmp->{"order"}},$anchor);
		my $hash={"predicate"=>"$pred#$anchor","object"=>$object};
		$tmp->{"anchor"}->{$anchor}=$hash;
	}
}
############################## handleTripleQueriesRegexpVars ##############################
sub handleTripleQueriesRegexpVars{
	my $triple=shift();
	my $key=shift();
	my $variables=shift();
	my $value=$triple->{$key};
	my @vars=();
	my $joinValue;
	while($value=~/^\w+\(.+\)$/){
		if($value=~/^count\((.+)\)$/){$value=$1;handleTripleQueriesFunction($triple,$key,\&functionCount);next;}
		if($value=~/^max\((.+)\)$/){$value=$1;handleTripleQueriesFunction($triple,$key,\&functionMax);next;}
		if($value=~/^min\((.+)\)$/){$value=$1;handleTripleQueriesFunction($triple,$key,\&functionMin);next;}
		if($value=~/^avg\((.+)\)$/){$value=$1;handleTripleQueriesFunction($triple,$key,\&functionAvg);next;}
		if($value=~/^split\((.+)\)$/){
			my @tokens=@{splitTokenByComma($1)};
			my $delim=$tokens[0];
			$value=$tokens[1];
			handleTripleQueriesFunction($triple,$key,\&functionSplit,$delim);
			next;
		}
		last;
	}
	if($value=~/^\(\$(\{\w+\}|\w+)\)$/){#(${key}) OR ($key)
		if($1=~/\{(\w+)\}/){$1=$1;}
		push(@vars,$1);
		$value="(.+)";
		$triple->{"$key.join"}=1;
	}
	while($value=~/\$(\{\w+\}|\w+)/){
		if($1=~/\{(\w+)\}/){$1=$1;}
		push(@vars,$1);
		$variables->{$1}=1;
		$value=~s/\$(\{\w+\}|\w+)/(.+)/;
	}
	if($value=~/\*/){$value=~s/\*/\.\*/g;}#convert wildcard '*' to regexp wildcards
	$triple->{"$key.regexp"}=$value;
	$triple->{"$key.variables"}=\@vars;
	if($key eq "object"){
		my @tokens=split(/\(\.\+\)/,$value);
		if(@tokens>0){
			my $pipedVars=1;
			foreach my $token(@tokens){if($token eq ""||$token eq ":"){next;}$pipedVars=0;}
			if($pipedVars){$triple->{"$key.regexp"}=undef;}
		}
	}
}
############################## insertTsv ##############################
sub insertTsv{
	my $predicate=shift();
	my $tempfile=shift();
	my $writer=shift();
	close($writer);
	my $file=getFileFromPredicate($predicate);
	if($file=~/\.gz$/){return;}
	elsif($file=~/\.bz2$/){return;}
	elsif(-d $file){return;}
	my $hash=readTsvToKeyValHash($file);#original
	my $count;
	($hash,$count)=readTsvToKeyValHash($tempfile,$hash);#updates
	writeKeyValHash($file,$hash);
	return $count;
}
############################## isArrayAllInteger ##############################
sub isArrayAllInteger{
	my $array=shift();
	foreach my $a(@{$array}){if($a!~/\d+/){return;}}
	return 1;
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
############################## kendallRankCorrelation ##############################
sub kendallRankCorrelation{
	my $x=shift();
	my $y=shift();
	my $sort=shift();
	my $reverse=shift();
	my $countX=scalar(@{$x});
	my $countY=scalar(@{$y});
	if($countX!=$countY){print STDERR "ERROR: Please make sure array sizes are same";exit(1);}
	if($sort){
		$x=arrayAssignRank($x,$reverse);
		$y=arrayAssignRank($y,$reverse);
	}
	my $hx={};
	my $hy={};
	foreach my $v(@{$x}){$hx->{$v}++;}
	foreach my $v(@{$y}){$hy->{$v}++;}
	my $t=0;
	my $u=0;
	while(my($key,$val)=each(%{$hx})){$t+=$val*$val-$val;}
	while(my($key,$val)=each(%{$hy})){$u+=$val*$val-$val;}
	$t/=2;
	$u/=2;
	my $p=0;
	my $q=0;
	for(my $i=0;$i<$countX;$i++){
		for(my $j=$i+1;$j<$countY;$j++){
			my $bx=$x->[$i] < $x->[$j];
			my $by=$y->[$i] < $y->[$j];
			print STDERR "$i $j $bx $by\n";
			if($bx==$by){$p++;}
			else{$q++;}
		}
	}
	my $r=($p-$q)/sqrt(($p+$q+$t)*($p+$q+$u));
	my $z=$r/sqrt(2*(2*$countX+5)/(9*$countX*($countX-1)));
	my $p=2*(1-normsdist($z));
	my $r1=6*sumDiffSquare($x,$y);
	my $r2=$countX*($countX*$countY-1);
	if($r2==0){return wantarray?(0,0):0;}
	my $r=1-$r1/$r2;
	my $t=$r*sqrt(($countX-2)/(1-$r*$r));
	$r=sprintf("%.2f",$r);
	$t=sprintf("%.2f",$t);
	return wantarray?($r,$t):$r;
}
############################## kruskalWallisCorrelation ##############################
sub kruskalWallisCorrelation{
	my $x=shift();
	my $y=shift();
	my $reverse=shift();
	my $hashtable=createTextNumberTable($x,$y);
	$hashtable->{"ranked"}=arrayAssignRank($hashtable->{"tables"},$reverse,1);
	totalLabeledTable($hashtable);
	my $ranked=$hashtable->{"ranked"};
	my $sampleSize=$hashtable->{"sampleSize"};
	my $totals=[];
	my $counts=[];
	my $size=$hashtable->{"rowSize"};
	for(my $i=0;$i<$size;$i++){
		my $cols=$ranked->[$i];
		my $colSize=scalar(@{$cols});
		$counts->[$i]=$colSize;
		for(my $j=0;$j<$colSize;$j++){$totals->[$i]+=$ranked->[$i]->[$j];}
	}
	my $t=0;
	for(my $i=0;$i<$size;$i++){
		my $total=$totals->[$i];
		my $count=$counts->[$i];
		$t+=$total*$total/$count;
	}
	$t=12/$sampleSize/($sampleSize+1)*$t-3*($sampleSize+1);
	my $colHash={};
	for(my $i=0;$i<scalar(@{$y});$i++){$colHash->{$y->[$i]}++;}
	my $r=0;
	while(my($key,$val)=each(%{$colHash})){$r+=$val*$val*$val-$val;}
	$r=1-$r/($sampleSize*$sampleSize*$sampleSize-$sampleSize);
	my $t2=$t/$r;
	$t2=sprintf("%.2f",$t2);
	return $t2;
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
sub mkdirs{
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
############################## moveTempToDest ##############################
sub moveTempToDest{
	my $file=shift();
	my $dest=shift();
	mkdir(dirname($dest));
	system("mv $file $dest");
	chmod(0755,$dest);
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
############################## pearsonsCorrelation ##############################
sub pearsonsCorrelation{
	my $x=shift();
	my $y=shift();
	my $countX=scalar(@{$x});
	my $countY=scalar(@{$y});
	if($countX!=$countY){print STDERR "ERROR: Please make sure array sizes are same";exit(1);}
	my $sumX=sumArray(@{$x});
	my $sumY=sumArray(@{$y});
	my $sumX2=sumArraySquare(@{$x});
	my $sumY2=sumArraySquare(@{$y});
	my $sumXY=sumCrossProduct($x,$y);
	my $r1=$countX*$sumXY-$sumX*$sumY;
	my $r2=sqrt(abs($countX*$sumX2-$sumX*$sumX)*abs($countY*$sumY2-$sumY*$sumY));
	if($r2==0){return wantarray?(0,0):0;}
	my $r=$r1/$r2;
	my $t=$r*sqrt(($countX-2)/(1-$r*$r));
	$r=sprintf("%.2f",$r);
	$t=sprintf("%.2f",$t);
	return wantarray?($r,$t):$r;
}
############################## prepareDbDir ##############################
sub prepareDbDir{
	mkdir($moiraidir);
	chmod(0777,$moiraidir);
	mkdir($dbdir);
	chmod(0777,$dbdir);
}
############################## prepareLabeledTable ##############################
sub prepareLabeledTable{
	my $tables=shift();#it's already 2Dtable
	my $hashtable={};
	$hashtable->{"tables"}=$tables;
	my $rowSize=scalar(@{$tables});
	my $colSize=0;
	my $sampleSize=0;
	my @rows=();
	for(my $i=0;$i<$rowSize;$i++){
		my $array=$tables->[$i];
		my $size=scalar(@{$array});
		if($size>$colSize){$colSize=$size;}
		$sampleSize+=$size;
		push(@rows,"R".($i+1));
	}
	my @cols=();
	for(my $j=0;$j<$colSize;$j++){push(@cols,"C".($j+1));}
	$hashtable->{"rows"}=\@rows;
	$hashtable->{"cols"}=\@cols;
	$hashtable->{"rowSize"}=$rowSize;
	$hashtable->{"colSize"}=$colSize;
	$hashtable->{"sampleSize"}=$sampleSize;
	return $hashtable;
}
############################## printLabledTable ##############################
sub printLabledTable{
	my $hashtable=shift();
	my $cols=$hashtable->{"cols"};
	my $rows=$hashtable->{"rows"};
	my $rowSize=$hashtable->{"rowSize"};
	my $colSize=$hashtable->{"colSize"};
	my $rowTotals=$hashtable->{"rowTotals"};
	my $colTotals=$hashtable->{"colTotals"};
	my $tables=$hashtable->{"tables"};
	my $total=$hashtable->{"total"};
	for(my $j=0;$j<$colSize;$j++){print "\t".$cols->[$j];}
	print "\n";
	for(my $i=0;$i<$rowSize;$i++){
		print $rows->[$i];
		for(my $j=0;$j<$colSize;$j++){print "\t".$tables->[$i]->[$j];}
		print "\t".$rowTotals->[$i];
		print "\n";
	}
	for(my $j=0;$j<$colSize;$j++){print "\t".$colTotals->[$j];}
	print "\t$total\n";
	if(exists($hashtable->{"expected"})){
		my $expected=$hashtable->{"expected"};
		for(my $j=0;$j<$colSize;$j++){print "\t".$cols->[$j];}
		print "\n";
		for(my $i=0;$i<$rowSize;$i++){
			print $rows->[$i];
			for(my $j=0;$j<$colSize;$j++){print "\t".$expected->[$i]->[$j];}
			print "\t".$rowTotals->[$i];
			print "\n";
		}
		for(my $j=0;$j<$colSize;$j++){print "\t".$colTotals->[$j];}
		print "\t$total\n";
	}
	if(exists($hashtable->{"ranked"})){
		my $expected=$hashtable->{"ranked"};
		for(my $j=0;$j<$colSize;$j++){print "\t".$cols->[$j];}
		print "\n";
		for(my $i=0;$i<$rowSize;$i++){
			print $rows->[$i];
			for(my $j=0;$j<$colSize;$j++){print "\t".$expected->[$i]->[$j];}
			print "\t".$rowTotals->[$i];
			print "\n";
		}
		for(my $j=0;$j<$colSize;$j++){print "\t".$colTotals->[$j];}
		print "\t$total\n";
	}
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
############################## processTripleFunction ##############################
sub processTripleFunction{
	my $query=shift();
	my $array=shift();
	foreach my $key("subject","object"){
		if(exists($query->{"$key.functions"})){
			my $variable=processTripleFunctionGetVariable($query->{"$key.variables"});
			foreach my $function(@{$query->{"$key.functions"}}){
				my ($func,@args)=@{$function};
				foreach my $h(@{$array}){$h->{$variable}=$func->(@args,$h->{$variable});}
			}
		}
	}
}
############################## processTripleFunctionGetVariable ##############################
sub processTripleFunctionGetVariable{
	my $variables=shift();
	if(scalar(@{$variables})==0){print STDERR "variable should be specified for function\n";exit(1);}
	elsif(scalar(@{$variables})>1){print STDERR "variable should be one for function\n";exit(1);}
	return $variables->[0];
}
############################## processTsv ##############################
sub processTsv{
	my $process=shift();
	my $file=shift();
	#sort by predicate to speed up process
	my ($sortwriter,$sorttemp)=tempfile(UNLINK=>1);
	close($sortwriter);
	system("sort $file > $sorttemp");
	my $reader=openFile($sorttemp);
	my $prevPredicate;
	my $writer;
	my $tempfile;
	my $count=0;
	while(<$reader>){
		chomp;
		my ($predicate,$anchor,$subject,$object)=split(/\t/);
		if($predicate ne $prevPredicate){
			if(defined($writer)&&defined($tempfile)){$count+=$process->($prevPredicate,$tempfile,$writer);}
			($writer,$tempfile)=tempfile(UNLINK=>1);
			$prevPredicate=$predicate;
		}
		if($anchor ne""){print $writer "$subject\t$anchor\t$object\n";}
		else{print $writer "$subject\t$object\n";}
	}
	close($reader);
	unlink($sorttemp);
	unlink($file);
	if(defined($writer)&&defined($tempfile)){$count+=$process->($prevPredicate,$tempfile,$writer);}
	return $count;
}
############################## queryResults ##############################
sub queryResults{
	my @queries=@_;
	my $expand=shift(@queries);
	my $results=shift(@queries);
	my $values={};
	my @tripleAnchors=();
	@queries=handleTripleQueries(@queries);
	my $joined;
	my $joinKeys=[];
	my $currentKeys=[];
	if(!defined($results)){$results=[];}
	else{
		my $hash={};
		foreach my $result(@{$results}){foreach my $key(keys(%{$result})){$hash->{$key}=1;}}
		@{$currentKeys}=sort{$a cmp $b}keys(%{$hash});
	}
	for(my $i=0;$i<scalar(@queries);$i++){
		my $query=$queries[$i];
		if($i==0){
			my $queryResult=queryVariables($query,$expand);
			if(scalar(@{$queryResult}==0)){return @{$queryResult};}
			($joinKeys,$currentKeys,$joined)=sharedKeys($currentKeys,$query);
			$results=$queryResult;
			next;
		}
		($joinKeys,$currentKeys,$joined)=sharedKeys($currentKeys,$query);
		if($joined!=1){
			print STDERR "Please make sure variables specified in queries are connected\n";
			exit(1);
		}
		my $queryResult=queryVariables($query,$expand,$joinKeys,$results);
		if(ref($queryResult)eq"ARRAY"){
			if(scalar(@{$queryResult}==0)){return @{$queryResult};}
			$results=$queryResult;
			next;
		}
		my @temp=();
		my $founds={};
		my @array=();
		my $usedKeys={};
		foreach my $h1(@{$results}){
			my $found=0;
			my $joinKey=constructJoinKey($joinKeys,$h1);
			if(exists($queryResult->{$joinKey})){
				my $h2s=$queryResult->{$joinKey};
				if(ref($h2s)ne"ARRAY"){$h2s=[$h2s];}
				foreach my $h2(@{$h2s}){
					my $h={};
					foreach my $k(keys(%{$h1})){$h->{$k}=$h1->{$k};}
					foreach my $k(keys(%{$h2})){if(!exists($h1->{$k})){$h->{$k}=$h2->{$k};}}
					push(@temp,$h);
				}
				$found=1;
				$usedKeys->{$joinKey}=1;
			}
			if($found==0&&defined($expand)){
				my $h={};
				foreach my $k(keys(%{$h1})){$h->{$k}=$h1->{$k};}
				foreach my $k(@{$currentKeys}){if(!exists($h->{$k})){$h->{$k}="";}}
				push(@temp,$h);
			}
		}
		if(defined($expand)){
			foreach my $joinKey(keys(%{$queryResult})){
				if(exists($usedKeys->{$joinKey})){next;}
				my $h2s=$queryResult->{$joinKey};
				if(ref($h2s)ne"ARRAY"){$h2s=[$h2s];}
				foreach my $h2(@{$h2s}){
					my $h={};
					foreach my $k(keys(%{$h2})){$h->{$k}=$h2->{$k};}
					foreach my $k(@{$currentKeys}){if(!exists($h->{$k})){$h->{$k}="";}}
					push(@temp,$h);
				}
			}
		}
		@{$results}=@temp;
		if(scalar(@{$results})==0){last;}
	}
	return @{$results};
}
############################## queryVariables ##############################
# perl dag.pl -d db query '$day->$id/json->$json' '$studyid->id2json->$json' '$studyid->$id/perJson#filesize->$filesize' '$studyid->$id/perJson#study->$study' '$studyid->$id/perJson#sample->$sample' '$studyid->$id/perJson#experiment->$experiment' '$studyid->$id/perJson#run->$run'
sub queryVariables{
	my $query=shift();
	my $expand=shift();
	my $joinKeys=shift();
	my $results=shift();
	my $dir=$dbdir;
	my $subject=$query->{"subject"};
	if($subject eq "system"){return queryVariablesSystem($query,$joinKeys);}
	my $subjectR=$query->{"subject.regexp"};
	my $subVars=$query->{"subject.variables"};
	my $predicate=$query->{"predicate"};
	my $predicateR=$query->{"predicate.regexp"};
	my $preVars=$query->{"predicate.variables"};
	my $object=$query->{"object"};
	my $objectR=$query->{"object.regexp"};
	my $objVars=$query->{"object.variables"};
	my $anchor=exists($query->{"anchor"})?$query->{"anchor"}:undef;
	my $anchorR=exists($query->{"anchor.regexp"})?$query->{"anchor.regexp"}:undef;
	my $anchorVars=exists($query->{"anchor.variables"})?$query->{"anchor.variables"}:undef;
	my @files=getFilesFromQuery($predicate,$dir,$results);
	my @array=();
	my $hashtable={};
	my $joinKeysFake;#All the variables become joinKeys for join/anchor/index cases, if not defined joinkeys
	my $noJoinKey;
	if(scalar(@{$joinKeys})==0){$joinKeys=undef;}#Convert empty array to undef
	#anchor exists, but join key doesn't exit yet meaning it's a first merging process
	my $joinFunction=\&queryVariablesMerge;
	if(!defined($joinKeys)){
		if(exists($query->{"subject.join"})){
			push(@{$joinKeysFake},@{$preVars});
			push(@{$joinKeysFake},@{$objVars});
			if(scalar(@{$joinKeysFake})==0){$joinKeysFake=undef;$noJoinKey=1;}
		}elsif(exists($query->{"object.join"})){
			push(@{$joinKeysFake},@{$subVars});
			push(@{$joinKeysFake},@{$preVars});
			if(scalar(@{$joinKeysFake})==0){$joinKeysFake=undef;$noJoinKey=1;}
		}elsif(exists($query->{"isAnchor"})&&scalar(keys(%{$query->{"anchor"}}))>1){
			push(@{$joinKeysFake},@{$subVars});
			push(@{$joinKeysFake},@{$preVars});
			push(@{$joinKeysFake},@{$objVars});
		}elsif(exists($query->{"isIndex"})&&scalar(keys(%{$query->{"anchor"}}))>1){
			push(@{$joinKeysFake},@{$subVars});
			push(@{$joinKeysFake},@{$preVars});
			push(@{$joinKeysFake},@{$objVars});
		}
	}
	my $acceptKeys;#To speed up small search in exchange with memory
	if(defined($joinKeys)&&defined($results)&&!defined($expand)){
		$acceptKeys={};
		foreach my $h(@{$results}){$acceptKeys->{constructJoinKey($joinKeys,$h)}=1;}
	}
	my $joinKeyCounts={};
	my $fakeKeyCounts={};
	if(exists($query->{"subject.join"})||exists($query->{"object.join"})){$joinFunction=\&queryVariablesJoin;}
	foreach my $file(@files){
		my $p=getPredicateFromFile($file);
		my ($reader,$readerFunction)=queryVariablesFileHandler($query,$file);
		queryVariablesInitiate($query,$reader,$readerFunction);
		while(!eof($reader)){
			foreach my $result($readerFunction->($reader,$query)){
				my ($s,$o,$a)=@{$result};
				my $h=queryVariablesHash($p,$query,$result);
				if(!defined($h)){next;}
				if(exists($query->{"isVariableAnchor"})){# handle normal join keys
					push(@array,$h);
					next;
				}
				if(defined($joinKeysFake)){#handle fake join keys
					my $joinKey=constructJoinKey($joinKeysFake,$h);
					# There is a very special case where query's subject or object is an actual value
					# This is when query is used to narrow down candidates
					# If multiple anchors exist, it's possible to have mixture of success and failure ones.
					# I later remove hashtable with failure one later.
					$fakeKeyCounts->{$joinKey}++;
					$joinFunction->($hashtable,\@array,$joinKey,$h,$a);
					next;
				}
				if(defined($noJoinKey)){#handle no join keys
					$joinFunction->($hashtable,\@array,"",$h,$a);
					next;
				}
				if(!defined($joinKeys)){push(@array,$h);next;}
				my $joinKey=constructJoinKey($joinKeys,$h);
				if(defined($acceptKeys)&&!exists($acceptKeys->{$joinKey})){next;}
				$joinKeyCounts->{$joinKey}++;
				$joinFunction->($hashtable,\@array,$joinKey,$h,$a);
			}
		}
		close($reader);
	}
	#handle fake join keys
	my $max=exists($query->{"anchor"})?scalar(keys(%{$query->{"anchor"}})):0;
	if($max>0&&!defined($expand)){
		if(defined($joinKeysFake)){
			my $deleted=0;
			while(my($key,$count)=each(%{$fakeKeyCounts})){if($count<$max){delete($hashtable->{$key});$deleted++;}}
			if($deleted>0){
				my @temp=();
				foreach my $h(@array){
					my $joinKey=constructJoinKey($joinKeysFake,$h);
					if($fakeKeyCounts->{$joinKey}==$max){push(@temp,$h);}
				}
				@array=@temp;
			}
		}elsif(defined($joinKeys)){
			my $deleted=0;
			while(my($key,$count)=each(%{$joinKeyCounts})){if($count<$max){delete($hashtable->{$key});$deleted++;}}
			if($deleted>0){
				my @temp=();
				foreach my $h(@array){
					my $joinKey=constructJoinKey($joinKeysFake,$h);
					if($joinKeyCounts->{$joinKey}==$max){push(@temp,$h);}
				}
				@array=@temp;
			}
		}
	}
	processTripleFunction($query,\@array);
	if(!defined($joinKeys)){
		if(defined($results)){@array=queryVariablesJoinResults($results,\@array);}
	}
	if(defined($joinKeysFake)){return \@array;}
	if(defined($noJoinKey)){return \@array;}
	if(defined($joinKeys)){return $hashtable;}
	return \@array;#just in case
}
############################## queryVariablesFileHandler ##############################
sub queryVariablesFileHandler{
	my $query=shift();
	my $file=shift();
	my $function=\&splitTriple;#default
	my $fileSuffix;#file suffix
	foreach my $acceptedSuffix(sort{$b cmp $a}keys(%{$fileSuffixes})){
		if($file=~/$acceptedSuffix/){
			$fileSuffix=$acceptedSuffix;
			$function=$fileSuffixes->{$acceptedSuffix};
			last;
		}
	}
	#handle sqlite3 db before anything
	if($fileSuffix eq "\\.db?\$"){
		delete($query->{"isAnchor"});
		$query->{"isIndex"}="true";
		my $tableName="root";
		if(exists($query->{"parameter"})){
			if(exists($query->{"parameter"}->{"table"})){
				$tableName=$query->{"parameter"}->{"table"};
			}
		}
		my @columns;
		my $tables=getSchemaFromSqlite3($file);
		if(!exists($tables->{$tableName})){
			print STDERR "Table '$tableName' doesn't exist in $file\n";
			exit(1);
		}
		if(!exists($query->{"index"})){
			@columns=(@{$tables->{$tableName}});
			$query->{"index"}=\@columns;
			if(!exists($query->{"anchor"})){
				my @orders=();
				$query->{"anchor"}={};
				my $object=$query->{"object"};
				my $predicate=$query->{"predicate"};
				my $variables={};
				for(my $i=1;$i<scalar(@columns);$i++){
					my $key=$columns[$i];
					$query->{"anchor"}->{$key}={"predicate"=>"$predicate#$key","object"=>$object};
					handleTripleQueriesRegexpVars($query->{"anchor"}->{$key},"predicate",$variables);
					handleTripleQueriesRegexpVars($query->{"anchor"}->{$key},"object",$variables);
					push(@orders,$key);
				}
				$query->{"orders"}=\@orders;
			}
			unlink($query->{"object"});
			unlink($query->{"object.object.regexp"});
			unlink($query->{"object.object.variables"});
		}else{
			@columns=(@{$query->{"index"}});
		}
		my $command="sqlite3 -header -cmd '.mode tabs' $file 'select ".join(",",@columns)." from \"$tableName\"'";
		my $reader=openFile("$command |");
		return ($reader,\&splitTsv);
	}
	if(exists($query->{"isVariableAnchor"})){return (openFile($file),\&splitTripleWithvariableAnchor);}
	if(exists($query->{"isAnchor"})){return (openFile($file),\&splitTripleWithAnchor);}
	#.txt default is triple, but if index is defined, tsv is used
	if(exists($query->{"isIndex"})){
		if($fileSuffix eq "(\\.te?xt)(\\.gz(ip)?|\\.bz(ip)?2)?\$"){
			$fileSuffix="(\\.tsv)(\\.gz(ip)?|\\.bz(ip)?2)?\$";
			$function=\&splitTsv;
		}
	}
	#Set default index for all file types
	if(!exists($query->{"index"})&&exists($fileIndeces->{$fileSuffix})){$query->{"index"}=$fileIndeces->{$fileSuffix};}
	if(!exists($query->{"anchor"})){#Set up anchor from variable and index information
		my $anchor={};
		my $variables={};
		foreach my $variable(@{$query->{"variables"}}){$variables->{$variable}=1;}
		my $predicate=$query->{"predicate"};
		my $object=$query->{"object"};
		for(my $i=1;$i<scalar(@{$query->{"index"}});$i++){
			my $key=$query->{"index"}->[$i];
			$anchor->{$key}={"predicate"=>"$predicate#$key","object"=>$object};
			handleTripleQueriesRegexpVars($anchor->{$key},"predicate",$variables);
			handleTripleQueriesRegexpVars($anchor->{$key},"object",$variables);
		}
		my @keys=sort{$a cmp $b}keys(%{$variables});
		if(keys(%{$anchor})>0){$query->{"anchor"}=$anchor;}
		$query->{"variables"}=\@keys;
	}
	return (openFile($file),$function);
}
############################## queryVariablesHash ##############################
sub queryVariablesHash{
	my $p=shift();
	my $query=shift();
	my $result=shift();
	my ($s,$o,$a)=@{$result};
	if(!defined($s)){return;}
	if(!defined($o)){return;}
	my $subjectR=$query->{"subject.regexp"};
	my $predicateR=$query->{"predicate.regexp"};
	my $objectR=$query->{"object.regexp"};
	my $subVars=$query->{"subject.variables"};
	my $preVars=$query->{"predicate.variables"};
	my $objVars=$query->{"object.variables"};
	my $predicate=$p;
	if(defined($a)){
		if($query->{"isVariableAnchor"}){
			foreach my $order(@{$query->{"order"}}){
				$predicateR=$query->{"anchor"}->{$order}->{"predicate.regexp"};
				$objectR=$query->{"anchor"}->{$order}->{"object.regexp"};
				$preVars=$query->{"anchor"}->{$order}->{"predicate.variables"};
				$objVars=$query->{"anchor"}->{$order}->{"object.variables"};
				$predicate="$p#$a";
				if($predicate=~/$predicateR/){last;}
			}
		}else{
			$predicateR=$query->{"anchor"}->{$a}->{"predicate.regexp"};
			$objectR=$query->{"anchor"}->{$a}->{"object.regexp"};
			$preVars=$query->{"anchor"}->{$a}->{"predicate.variables"};
			$objVars=$query->{"anchor"}->{$a}->{"object.variables"};
			$predicate="$p#$a";
		}
	}
	if($s!~/^$subjectR$/){return;}
	if($o!~/^$objectR$/){return;}
	my $h={};
	if(defined($subVars)>0){
		my @regexp=$s=~/^$subjectR$/;
		for(my $i=0;$i<scalar(@{$subVars});$i++){$h->{$subVars->[$i]}=$regexp[$i];}
	}
	if(defined($preVars)>0){
		my @regexp=$predicate=~/^$predicateR$/;
		for(my $i=0;$i<scalar(@{$preVars});$i++){$h->{$preVars->[$i]}=$regexp[$i];}
	}
	if(defined($objVars)>0){
		my @regexp=$o=~/^$objectR$/;
		for(my $i=0;$i<scalar(@{$objVars});$i++){$h->{$objVars->[$i]}=$regexp[$i];}
	}
	if(scalar(keys(%{$h}))==0){return;}
	return $h;
}
############################## queryVariablesInitiate ##############################
sub queryVariablesInitiate{
	my $query=shift();
	my $reader=shift();
	my $function=shift();
	if(eof($reader)){return;}
	if(!exists($query->{"index"})){return;}
	my $index=$query->{"index"};
	if(isArrayAllInteger($index)){return;}
	if($function==\&splitCsv){
		my $line=<$reader>;
		while($line=~/^#\s*(.+)$/){
			$line=$1;
			if(splitCsvTsvHandleLabel($query,$line,",")){return;};
			if(eof($reader)){return;}
			$line=<$reader>;
		}
		if(!splitCsvTsvHandleLabel($query,$line,",")){$query->{"previousLine"}=$line;}
	}elsif($function==\&splitTsv){
		my $line=<$reader>;
		while($line=~/^#/){
			while($line=~/^#\s*(.+)$/){$line=$1;}
			if(splitCsvTsvHandleLabel($query,$line,"\t")){return;};
			if(eof($reader)){return;}
			$line=<$reader>;
		}
		if(!splitCsvTsvHandleLabel($query,$line,"\t")){$query->{"previousLine"}=$line;}
	}
}
############################## queryVariablesJoin ##############################
sub queryVariablesJoin{
	my $hashtable=shift();
	my $array=shift();
	my $joinKey=shift();
	my $h=shift();
	if(!exists($hashtable->{$joinKey})){$hashtable->{$joinKey}=$h;push(@{$array},$h);return;}
	my $h2=$hashtable->{$joinKey};
	while(my($key,$val)=each(%{$h})){
		if(!exists($h2->{$key})){$h2->{$key}=$val;next;}
		if(ref($h2->{$key})ne"ARRAY"){
			my $val2=$h2->{$key};
			if($val eq $val2){next;}
			$h2->{$key}=[$val2,$val];
		}
		if(existsArray($h2->{$key},$val)){next;}
		push(@{$h2->{$key}},$val);
	}
}
############################## queryVariablesJoinResults ##############################
sub queryVariablesJoinResults{
	my $results=shift();
	my $array=shift();
	my @sharedKeys=sharedKeysFromArrays($results,$array);
	my $h1={};
	my @joined=();
	foreach my $h(@{$results}){
		my $joinKey=constructJoinKey(\@sharedKeys,$h);
		if(exists($h1->{$joinKey})){push(@{$h1->{$joinKey}},$h)}
		else{$h1->{$joinKey}=[$h];}
	}
	foreach my $h2(@{$array}){
		my $joinKey=constructJoinKey(\@sharedKeys,$h2);
		if(!exists($h1->{$joinKey})){next;}
		my @array=@{$h1->{$joinKey}};
		for(my $i=0;$i<scalar(@array);$i++){
			if($i==0){
				while(my($k,$v)=each(%{$array[$i]})){
					if(exists($h2->{$k})){next;}
					$h2->{$k}=$v;
				}
				push(@joined,$h2);
				next;
			}
			my $h={};
			while(my($k,$v)=each(%{$h2})){$h->{$k}=$v;}
			while(my($k,$v)=each(%{$array[$i]})){$h->{$k}=$v;}
			push(@joined,$h);
		}
	}
	return @joined;
}
############################## queryVariablesMerge ##############################
sub queryVariablesMerge{
	my $hashtable=shift();
	my $array=shift();
	my $joinKey=shift();
	my $h=shift();
	my $a=shift();
	if(!exists($hashtable->{$joinKey})){$hashtable->{$joinKey}=$h;push(@{$array},$h);return;}
	if(!defined($a)){
		if(ref($hashtable->{$joinKey})eq"ARRAY"){push(@{$hashtable->{$joinKey}},$h);}
		else{$hashtable->{$joinKey}=[$hashtable->{$joinKey},$h];}
		return;
	}
	my $h2=$hashtable->{$joinKey};
	while(my($key,$val)=each(%{$h})){
		if(!exists($h2->{$key})){$h2->{$key}=$val;next;}
		if(ref($h2->{$key})ne"ARRAY"){
			my $val2=$h2->{$key};
			if($val eq $val2){next;}
			$h2->{$key}=[$val2,$val];
		}
		if(existsArray($h2->{$key},$val)){next;}
		push(@{$h2->{$key}},$val);
	}
}
############################## queryVariablesSystem ##############################
sub queryVariablesSystem{
	my $query=shift();
	my $joinKeys=shift();
	my $predicate=$query->{"predicate"};
	if($predicate eq "ls"){$predicate="ls *";}
	if($predicate=~/^ls\s(.+)$/){
		my $directory=checkDirPathIsSafe($1);
		my @files=getFilesByLs($directory);
		my @objVars=exists($query->{"object.variables"})?@{$query->{"object.variables"}}:undef;
		my $objectR=$query->{"object.regexp"};
		my $size=scalar(@objVars);
		my @array=();
		if($size==0){print STDERR "ERROR: Please specify variables for object\n";exit(1);}
		if(defined($joinKeys)){
			my $hashtable={};
			if(defined($objectR)){
				foreach my $file(@files){
					my $h={};
					my @results=$file=~/^$objectR$/;
					for(my $i=0;$i<scalar(@objVars);$i++){$h->{$objVars[$i]}=$results[$i];}
					my $joinKey=constructJoinKey($joinKeys,$h);
					$hashtable->{$joinKey}=$h;
				}
			}else{
				foreach my $file(@files){
					my $h={};
					my $basenames=basenames($file);
					if($size==1){$h={$objVars[0]=>$basenames->{"filepath"}};}
					if($size==2){$h={$objVars[0]=>$basenames->{"directory"},$objVars[1]=>$basenames->{"filename"}};}
					if($size==3){$h={$objVars[0]=>$basenames->{"directory"},$objVars[1]=>$basenames->{"basename"},$objVars[2]=>$basenames->{"suffix"}};}
					my $joinKey=constructJoinKey($joinKeys,$h);
					$hashtable->{$joinKey}=$h;
				}
			}
			return $hashtable;
		}else{
			my @array=();
			if(defined($objectR)){
				foreach my $file(@files){
					my $h={};
					my @results=$file=~/^$objectR$/;
					for(my $i=0;$i<scalar(@objVars);$i++){$h->{$objVars[$i]}=$results[$i];}
					push(@array,$h);
				}
			}else{
				if($size>4){print STDERR "ERROR: Please specify four variables for object at most\n";exit(1);}
				foreach my $file(@files){
					my $basenames=basenames($file);
					if($size==1){push(@array,{$objVars[0]=>$basenames->{"filepath"}});}
					if($size==2){push(@array,{$objVars[0]=>$basenames->{"filepath"},$objVars[1]=>$basenames->{"directory"}});}
					if($size==3){push(@array,{$objVars[0]=>$basenames->{"filepath"},$objVars[1]=>$basenames->{"directory"},$objVars[2]=>$basenames->{"basename"}});}
					if($size==4){push(@array,{$objVars[0]=>$basenames->{"filepath"},$objVars[1]=>$basenames->{"directory"},$objVars[2]=>$basenames->{"basename"},$objVars[3]=>$basenames->{"suffix"}});}
				}
			}
			return \@array;
		}
	}
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
############################## readTsvToKeyValHash ##############################
sub readTsvToKeyValHash{
	my $file=shift();
	my $hash=shift();
	if(!defined($hash)){$hash={};}
	my $count=0;
	my $reader=openFile($file);
	while(<$reader>){
		chomp;
		my @tokens=split(/\t/);
		my $size=scalar(@tokens);
		my $key;
		my $val;
		if($size==2){$key=$tokens[0];$val=$tokens[1];}
		elsif($size==3){$key=$tokens[0]."\t".$tokens[1];$val=$tokens[2];}
		if(exists($hash->{$key})){push(@{$hash->{$key}},$val);}
		else{$hash->{$key}=[$val];}
		$count++;
	}
	close($reader);
	return wantarray?($hash,$count):$hash;
}
############################## retrieveValuesFromArrayR ##############################
sub retrieveValuesFromArrayR{
	my $array=shift();
	my $hash=shift();
	if(ref($array)ne"ARRAY"){$hash->{$array}++;return;}
	foreach my $a(@{$array}){retrieveValuesFromArrayR($a,$hash);}
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
	if($flag&4){return;}
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
	my $array1=shift();
	my $query=shift();
	my $h1={};
	my $h2={};
	my $total={};
	my $joined=0;
	foreach my $a(@{$array1}){$h1->{$a}=1;$total->{$a}=1;}
	foreach my $a(@{$query->{"subject.variables"}}){$h2->{$a}=1;$total->{$a}=1;if(exists($h1->{$a})){$joined=1;}}
	foreach my $a(@{$query->{"predicate.variables"}}){$total->{$a}=1;if(exists($h1->{$a})){$joined=1;}}
	if(exists($query->{"anchor"})){
		foreach my $v(values(%{$query->{"anchor"}})){
			foreach my $a(@{$v->{"object.variables"}}){$h2->{$a}=1;$total->{$a}=1;if(exists($h1->{$a})){$joined=1;}}
		}
	}else{
		foreach my $a(@{$query->{"object.variables"}}){$h2->{$a}=1;$total->{$a}=1;if(exists($h1->{$a})){$joined=1;}}
	}
	my @keys=();
	foreach my $key(keys(%{$h1})){if(exists($h2->{$key})){push(@keys,$key);}}
	@keys=sort{$a cmp $b}@keys;
	my @totalKeys=sort{$a cmp $b}keys(%{$total});
	return (\@keys,\@totalKeys,$joined);
}
############################## sharedKeysFromArrays ##############################
sub sharedKeysFromArrays{
	my $array1=shift();
	my $array2=shift();
	my $hash={};
	my @keys=();
	foreach my $h(@{$array1}){while(my ($key,$val)=each(%{$h})){$hash->{$key}=1;}}
	foreach my $h(@{$array2}){
		while(my ($key,$val)=each(%{$h})){
			if(exists($hash->{$key})){
				push(@keys,$key);
				delete($hash->{$key});
			}
		}
	}
	@keys=sort{$a cmp $b}@keys;
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
############################## sortFile ##############################
sub sortFile{
	my $input=shift();
	my ($writer,$output)=tempfile(UNLINK=>1);
	close($writer);
	system("sort -u $input > $output");
	chmod(0755,$output);
	return $output;
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
	my ($writer,$file)=tempfile("scriptXXXXXXXXXX",DIR=>"/tmp",SUFFIX=>".pl");
	foreach my $line(@headers){print $writer "$line\n";}
	foreach my $key(sort{$a cmp $b}@orders){foreach my $line(@{$blocks->{$key}}){print $writer "$line\n";}}
	close($writer);
	chmod(0755,$file);
	return system("mv $file $path");
}
############################## spearmansRankCorrelation ##############################
sub spearmansRankCorrelation{
	my $x=shift();
	my $y=shift();
	my $sort=shift();
	my $reverse=shift();
	my $countX=scalar(@{$x});
	my $countY=scalar(@{$y});
	if($countX!=$countY){print STDERR "ERROR: Please make sure array sizes are same";exit(1);}
	if($sort){
		$x=arrayAssignRank($x,$reverse,1);
		$y=arrayAssignRank($y,$reverse,1);
	}
	my $r1=6*sumDiffSquare($x,$y);
	my $r2=$countX*($countX*$countY-1);
	if($r2==0){return wantarray?(0,0):0;}
	my $r=1-$r1/$r2;
	my $t=$r*sqrt(($countX-2)/(1-$r*$r));
	$r=sprintf("%.2f",$r);
	$t=sprintf("%.2f",$t);
	return wantarray?($r,$t):$r;
}
############################## splitBed ##############################
#chr22 1000 5000 cloneA 960 + 1000 5000 0 2 567,488, 0,3512
#chr22 2000 6000 cloneB 900 - 2000 6000 0 2 433,399, 0,3601
sub splitBed{
	my $reader=shift();
	my $query=shift();
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
	$hash->{"0"}=$chrom;
	$hash->{"1"}=$chromStart;
	$hash->{"2"}=$chromEnd;
	$hash->{"3"}=$name;
	$hash->{"4"}=$score;
	$hash->{"5"}=$strand;
	$hash->{"6"}=$thickStart;
	$hash->{"7"}=$thickEnd;
	$hash->{"8"}=$itemRgb;
	$hash->{"9"}=$blockCount;
	$hash->{"10"}=$blockSizes;
	$hash->{"11"}=$blockStarts;
	$hash->{"chromLength"}=$chromEnd-$chromStart;
	$hash->{"position"}="$chrom:$chromStart..$chromEnd:$strand";
	my @sizes=split(',',$blockSizes);
	my $geneLength=0;
	foreach my $size(@sizes){$geneLength+=$size;}
	$hash->{"genLength"}=$geneLength;
	my @output=();
	my $indeces=$query->{"index"};
	my ($key,@anchors)=@{$indeces};
	foreach my $anchor(@anchors){push(@output,[$hash->{$key},$hash->{$anchor},$anchor]);}
	return @output;
}
############################## splitCsv ##############################
sub splitCsv{
	my $reader=shift();
	my $query=shift();
	return splitCsvTsv($reader,$query,",");
}
############################## splitCsvTsv ##############################
sub splitCsvTsv{
	my $reader=shift();
	my $query=shift();
	my $delim=shift();
	if(eof($reader)){return;}
	my $line;
	if(exists($query->{"previousLine"})){$line=$query->{"previousLine"};$query->{"previousLine"}=undef;}
	else{$line=<$reader>;}
	while($line=~/^#/){$line=<$reader>;}
	chomp($line);
	my @tokens=($delim eq ",")?@{splitTokenByComma($line)}:split(/$delim/,$line);
	my $hash={};
	for(my $i=0;$i<scalar(@tokens);$i++){$hash->{$i}=$tokens[$i];}
	my $columns=$query->{"columns"};
	if(defined($columns)){for(my $i=0;$i<scalar(@tokens);$i++){$hash->{$columns->[$i]}=$tokens[$i];}}
	my ($key,@indeces)=@{$query->{"index"}};
	my @array=();
	$key=$hash->{$key};
	for(my $i=0;$i<scalar(@indeces);$i++){
		my $index=$indeces[$i];
		push(@array,[$key,$hash->{$index},$index]);
	}
	return @array;
}
############################## splitCsvTsvHandleLabel ##############################
sub splitCsvTsvHandleLabel{
	my $query=shift();
	my $line=shift();
	my $delim=shift();
	if(!defined($delim)){$delim="\t";}
	if(exists($query->{"columns"})){return;}
	chomp($line);
	if($line=~/^\s+(.+)$/){$line=$1;}
	my @columns=($delim eq ",")?@{splitTokenByComma($line)}:split(/$delim/,$line);
	my $hash={};
	for(my $i=0;$i<scalar(@columns);$i++){$hash->{$columns[$i]}=$i;}
	my $hit=0;
	foreach my $key(@{$query->{"index"}}){if($hash->{$key}){$hit++;}}
	if($hit==0){return;}
	$query->{"columns"}=\@columns;
	return $hit;
}
############################## splitFasta ##############################
sub splitFasta{
	my $reader=shift();
	my $query=shift();
	my $delim=shift();
	if(eof($reader)){return;}
	my $line;
	if(exists($query->{"previousLine"})){$line=$query->{"previousLine"};$query->{"previousLine"}=undef;}
	else{$line=<$reader>;}
	while($line=~/^#/){$line=<$reader>;}
	chomp($line);
	my $id=substr($line,1);chomp($id);
	my $sequence;
	while(<$reader>){chomp;if(/^>/){$line=$query->{"previousLine"}=$_;last;}$sequence.=$_;}
	my $hash={};
	$hash->{"id"}=$id;
	$hash->{"sequence"}=$sequence;
	$hash->{"length"}=length($sequence);
	my ($key,@indeces)=@{$query->{"index"}};
	my @array=();
	$key=$hash->{$key};
	for(my $i=0;$i<scalar(@indeces);$i++){
		my $index=$indeces[$i];
		push(@array,[$key,$hash->{$index},$index]);
	}
	return @array;
}
############################## splitFastq ##############################
sub splitFastq{
	my $reader=shift();
	my $query=shift();
	my $delim=shift();
	if(eof($reader)){return;}
	my $line=<$reader>;
	while($line=~/^#/){$line=<$reader>;}
	chomp($line);
	my $id=substr($line,1);chomp($id);if($id=~/^\@\s*(.+)$/){$id=$1;}
	my $sequence=<$reader>;chomp($sequence);
	$line=<$reader>;
	my $id2=substr($line,1);chomp($id2);if($id2=~/^\+\s*(.+)$/){$id2=$1;}
	my $quality=<$reader>;chomp($quality);
	my $hash={};
	$hash->{"id"}=$id;
	$hash->{"sequence"}=$sequence;
	$hash->{"quality"}=$quality;
	$hash->{"length"}=length($sequence);
	my ($key,@indeces)=@{$query->{"index"}};
	my @array=();
	$key=$hash->{$key};
	for(my $i=0;$i<scalar(@indeces);$i++){
		my $index=$indeces[$i];
		push(@array,[$key,$hash->{$index},$index]);
	}
	return @array;
}
############################## splitGtf ##############################
sub splitGtf{
	my $reader=shift();
	my $query=shift();
	if(eof($reader)){return;}
	my $line=<$reader>;
	while($line=~/^#/){$line=<$reader>;}
	chomp($line);
	my ($seqname,$source,$feature,$start,$end,$score,$strand,$frame,$attribute)=split(/\t/,$line);
	if($attribute=~/^\s(.+)$/){$attribute=$1;}
	my $hash={};
	$hash->{"seqname"}=$seqname;
	$hash->{"source"}=$source;
	$hash->{"feature"}=$feature;
	$hash->{"start"}=$start;
	$hash->{"end"}=$end;
	$hash->{"score"}=$score;
	$hash->{"strand"}=$strand;
	$hash->{"frame"}=$frame;
	$hash->{"position"}="$seqname:$start..$end";
	$hash->{"attribute"}=$attribute;
	$hash->{"line"}=$line;
	foreach my $attr(split(/;\s*/,$attribute)){
		my ($k,$v)=split(/\s/,$attr);
		if($v=~/^\"(.+)\"$/){$v=$1;}
		$hash->{$k}=$v;
	}
	my ($key,@indeces)=@{$query->{"index"}};
	my @array=();
	$key=$hash->{$key};
	for(my $i=0;$i<scalar(@indeces);$i++){
		my $index=$indeces[$i];
		push(@array,[$key,$hash->{$index},$index]);
	}
	return @array;
}
############################## splitQueries ##############################
sub splitQueries{
	my $query=shift();
	my $queries=shift();
	my $results=shift();
	if($query=~/^\$(\w+)\=(.+)$/){assignResults($results,$1,$2);return;}
	my @tokens=split(/\-\>/,$query);
	my $count=scalar(@tokens);
	if($count==3){push(@{$queries},$query);}
	elsif($count>3){print STDERR "ERROR: '$query' has multiple '->' (More than 2)\n";exit(1);}
	elsif($count>1){print STDERR "ERROR: '$query' doesn't have enough '->' (Less than 2)\n";exit(1);}
	else{#Probably it's in json format
		my $json=jsonDecode($query);
		if(ref($json)ne"ARRAY"){$json=[$json];}
		foreach my $j(@{$json}){
			if(ref($j)ne"HASH"){return;}
			my @remkeys=();
			my @keys=keys(%{$j});
			foreach my $key(@keys){
				my $val=$j->{$key};
				if(ref($val)eq"HASH"){delete($j->{$key});}
				elsif(ref($val)eq"ARRAY"){delete($j->{$key});}
			}
			push(@{$results},$j);
		}
	}
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
	return [$hash->{$key},$hash->{$val}];
}
############################## splitSam ##############################
sub splitSam{
	my $reader=shift();
	my $query=shift();
	if(eof($reader)){return;}
	my $line=<$reader>;
	while($line=~/^\@/){$line=<$reader>;}
	chomp($line);
	my $hash={};
	my ($qname,$flag,$rname,$pos,$mapq,$cigar,$rnext,$pnext,$tlen,$seq,$qual)=split(/\t/,$line);
	my ($start,$end,$strand)=samStartEndStrand($flag,$pos,$cigar);
	$hash->{"start"}=$start;
	$hash->{"end"}=$end;
	$hash->{"strand"}=$strand;
	$hash->{"chromLength"}=$end-$start;
	$hash->{"position"}="$qname:$start..$end:$strand";
	$hash->{"qname"}=$qname;
	$hash->{"flag"}=$flag;
	$hash->{"rname"}=$rname;
	$hash->{"pos"}=$pos;
	$hash->{"mapq"}=$mapq;
	$hash->{"cigar"}=$cigar;
	$hash->{"rnext"}=$rnext;
	$hash->{"pnext"}=$pnext;
	$hash->{"tlen"}=$tlen;
	$hash->{"seq"}=$seq;
	$hash->{"qual"}=$qual;
	$hash->{"line"}=$line;
	$hash->{"0"}=$qname;
	$hash->{"1"}=$flag;
	$hash->{"2"}=$rname;
	$hash->{"3"}=$pos;
	$hash->{"4"}=$mapq;
	$hash->{"5"}=$cigar;
	$hash->{"6"}=$rnext;
	$hash->{"7"}=$pnext;
	$hash->{"8"}=$tlen;
	$hash->{"9"}=$seq;
	$hash->{"10"}=$qual;
	my @output=();
	my $indeces=$query->{"index"};
	my ($key,@anchors)=@{$indeces};
	foreach my $anchor(@anchors){push(@output,[$hash->{$key},$hash->{$anchor},$anchor]);}
	return @output;
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
############################## splitTriple ##############################
sub splitTriple{
	my $reader=shift();
	my $query=shift();
	while(<$reader>){
		chomp;
		my @tokens=split(/\t/);
		if(scalar(@tokens)==3){next;}
		elsif(scalar(@tokens)==1){return ["root",$tokens[0]];}
		else{return [$tokens[0],$tokens[1]];}
	}
	return;
}
############################## splitTripleWithAnchor ##############################
sub splitTripleWithAnchor{
	my $reader=shift();
	my $query=shift();
	my $hash=$query->{"anchor"};
	while(<$reader>){
		chomp;
		my @tokens=split(/\t/);
		if(scalar(@tokens)!=3){next;}
		if(!exists($hash->{$tokens[1]})){next;}
		return [$tokens[0],$tokens[2],$tokens[1]];
	}
	return;
}
############################## splitTripleWithvariableAnchor ##############################
sub splitTripleWithvariableAnchor{
	my $reader=shift();
	my $query=shift();
	while(<$reader>){
		chomp;
		my @tokens=split(/\t/);
		if(scalar(@tokens)!=3){next;}
		return [$tokens[0],$tokens[2],$tokens[1]];
	}
	return;
}
############################## splitTsv ##############################
sub splitTsv{
	my $reader=shift();
	my $query=shift();
	return splitCsvTsv($reader,$query,"\t");
}
############################## sqliteCheckType ##############################
sub sqliteCheckType{
	my $variables=shift();
	my $results=shift();
	my $types={};
	foreach my $variable(@{$variables}){
		my $type;
		foreach my $h(@{$results}){
			$type=checkValueType($type,$h->{$variable});
		}
		$types->{$variable}=$type;
	}
	return $types;
}
############################## sumArray ##############################
sub sumArray{
	my @data=@_;
	my $total=0;
	foreach(@data){$total+=$_;}
	return $total;
}
############################## sumArraySquare ##############################
sub sumArraySquare{
	my @data=@_;
	my $total=0;
	foreach(@data){$total+=$_*$_;}
	return $total;
}
############################## sumCrossProduct ##############################
sub sumCrossProduct{
	my $x=shift();
	my $y=shift();
	my $total=0;
	for(my $i=0;$i<scalar(@{$x});$i++){$total+=$x->[$i]*$y->[$i];}
	return $total;
}
############################## sumDiffSquare ##############################
sub sumDiffSquare{
	my $x=shift();
	my $y=shift();
	my $size=scalar(@{$x});
	my $total=0;
	for(my $i=0;$i<$size;$i++){
		my $d=$x->[$i]-$y->[$i];
		$total+=$d*$d;
	}
	return $total;
}
############################## test ##############################
sub test{
	my @arguments=@_;
	my $hash={};
	if(scalar(@arguments)>0){foreach my $arg(@arguments){$hash->{$arg}=1;}}
	else{for(my $i=1;$i<=7;$i++){$hash->{$i}=1;}}
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
sub test0{
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
	#timestamp
	testSub("convertGmtToSecond(\"Sat, 20 Aug 2022 14:12:52 GMT\")",1661004772);
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
	testSub("getFileFromPredicate(\"$dbdir/A/B.txt\")","$dbdir/A/B.txt");
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
	testSub("getFileFromPredicate(\"http://A/B\")","http/A/B");
	testSub("getFileFromPredicate(\"https://A/B/C/D\")","https/A/B/C/D");
	testSub("getFileFromPredicate(\"http://localhost/~ah3q/gitlab/moirai2dgt/geneBodyCoverage/allImage\")","http/localhost/~ah3q/gitlab/moirai2dgt/geneBodyCoverage/allImage");
	testSub("getFileFromPredicate(\"ah3q\\\@dgt-ac4:A/B\")","ssh/ah3q/dgt-ac4/A/B");
	createFile("$dbdir/A/B.txt","A\tA1");
	createFile("$dbdir/A/C.txt","A\tA1");
	testSub("getFileFromPredicate(\"A/\")","$dbdir/A");
	system("rm $dbdir/A/B.txt");
	system("rm $dbdir/A/C.txt");
	system("rmdir $dbdir/A");
	#splitTokenByComma
	testSub("splitTokenByComma(\"A,B,C\")",["A","B","C"]);
	testSub("splitTokenByComma(\"'A',B,'C'\")",["A","B","C"]);
	testSub("splitTokenByComma(\"'A',,B,,'C'\")",["A","","B","","C"]);
	testSub("splitTokenByComma(\"'A',\\\"B\\\",'C'\")",["A","B","C"]);
	testSub("splitTokenByComma(\"'A',\\\"B,C\\\",'D,E'\")",["A","B,C","D,E"]);
	testSub("splitTokenByComma(\"'A\\tB','C\\nD','E\\\\F'\")",["A\tB","C\nD","E\\F"]);
	testSub("splitTokenByComma(\"\\\$a->B->\\\$c\")",["\$a->B->\$c"]);
	testSub("splitTokenByComma(\"A,B,C\")",["A","B","C"]);
	testSub("splitTokenByComma(\"'A',B,'C'\")",["A","B","C"]);
	testSub("splitTokenByComma(\"\\\"A,B\\\",'C,D',\\\"E,F\\\"\")",["A,B","C,D","E,F"]);
	testSub("splitTokenByComma(\"A(),B(),C()\")",["A()","B()","C()"]);
	testSub("splitTokenByComma(\"A(1),B(2,3),C(4)\")",["A(1)","B(2,3)","C(4)"]);
	testSub("splitTokenByComma(\"A(\\\"A\\\"),B(\\\"B\\\",\\\"C\\\"),C(\\\"D\\\")\")",["A(\"A\")","B(\"B\",\"C\")","C(\"D\")"]);
	testSub("splitTokenByComma(\"A(1),B(1,2,\\\"B\\\",\\\"C\\\"),C(5,D(\\\"E,F\\\",6))\")",["A(1)","B(1,2,\"B\",\"C\")","C(5,D(\"E,F\",6))"]);
	testSub("splitTokenByComma(\"'A',,B,,'C'\")",["A","","B","","C"]);
	testSub("splitTokenByComma(\"'A',\\\"B\\\",'C'\")",["A","B","C"]);
	testSub("splitTokenByComma(\"'A',\\\"B,C\\\",'D,E'\")",["A","B,C","D,E"]);
	testSub("splitTokenByComma(\"'A\\tB','C\\nD','E\\\\F'\")",["A\tB","C\nD","E\\F"]);
	#testing array manipulation
	testSub("checkArrayDimension(1)",0);
	testSub("checkArrayDimension([1])",1);
	testSub("checkArrayDimension([1,2,3,4])",1);
	testSub("checkArrayDimension([[1,2],[3,4]])",2);
	testSub("checkArrayDimension([[[1,2],[3,4]],[[5,6],7]])",3);
	testSub("arrayAssignRank([2,3,2,1,1,1,2,3,2,4,4,2,4,5,5,4],0,1)",[6,9.5,6,2,2,2,6,9.5,6,12.5,12.5,6,12.5,15.5,15.5,12.5]);
	testSub("arrayAssignRank([2,3,2,1,1,1,2,3,2,4,4,2,4,5,5,4],1,1)",[11,7.5,11,15,15,15,11,7.5,11,4.5,4.5,11,4.5,1.5,1.5,4.5]);
	#default test
	testCommand("perl $program_directory/dag.pl -d test insert A B C","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test update A B D","updated 1");
	testCommand("perl $program_directory/dag.pl -d test select A B D","A\tB\tD");
	testCommand("perl $program_directory/dag.pl -d test -f json select A B D","{\"A\":{\"B\":\"D\"}}");
	system("echo 'A\\tE' >> test/B.txt");
	testCommand("perl $program_directory/dag.pl -d test select","A\tB\tD","A\tB\tE");
	testCommand("perl $program_directory/dag.pl -d test -f json select","{\"A\":{\"B\":[\"D\",\"E\"]}}");
	testCommand("perl $program_directory/dag.pl -d test -f json select % B","{\"A\":{\"B\":[\"D\",\"E\"]}}");
	testCommand("perl $program_directory/dag.pl -d test -f json select A","{\"A\":{\"B\":[\"D\",\"E\"]}}");
	testCommand("perl $program_directory/dag.pl -d test -f json select % % D","{\"A\":{\"B\":\"D\"}}");
	system("echo 'F\\tGreg' >> test/B.txt");
	testCommand("perl $program_directory/dag.pl -d test -f json select % B %","{\"A\":{\"B\":[\"D\",\"E\"]},\"F\":{\"B\":\"Greg\"}}");
	testCommand("perl $program_directory/dag.pl -d test -f json select % % %eg","{\"F\":{\"B\":\"Greg\"}}");
	testCommand("perl $program_directory/dag.pl -d test -f json delete % % %e%","deleted 1");
	testCommand("perl $program_directory/dag.pl -d test -f json select","{\"A\":{\"B\":[\"D\",\"E\"]}}");
	system("rm test/B.txt");
	testCommand("perl $program_directory/dag.pl -d test -f json select","{}");
}
#Testing basic functionality
sub test2{
	mkdir("file");
	createFile("test/id.txt","A\tA1","B\tB1","C\tC1","D\tD1");
	createFile("test/name.txt","A1\tAkira","B1\tBen","C1\tChris","D1\tDavid");
	testCommand("perl $program_directory/dag.pl linecount test/id.txt","test/id.txt\tfile/linecount\t4");
	testCommand("perl $program_directory/dag.pl md5 test/id.txt","test/id.txt\tfile/md5\t131e61dab9612108824858dc497bf713");
	testCommand("perl $program_directory/dag.pl filesize test/id.txt","test/id.txt\tfile/filesize\t20");
	testCommand("perl $program_directory/dag.pl seqcount test/id.txt","test/id.txt\tfile/seqcount\t4");
	testCommand("perl $program_directory/dag.pl -d test select","A\tid\tA1","A1\tname\tAkira","B\tid\tB1","B1\tname\tBen","C\tid\tC1","C1\tname\tChris","D\tid\tD1","D1\tname\tDavid");
	testCommand("perl $program_directory/dag.pl -d test select A","A\tid\tA1");
	testCommand("perl $program_directory/dag.pl -d test select % id","A\tid\tA1","B\tid\tB1","C\tid\tC1","D\tid\tD1");
	testCommand("perl $program_directory/dag.pl -d test select % % B1","B\tid\tB1");
	testCommand("perl $program_directory/dag.pl -d test select A%","A\tid\tA1","A1\tname\tAkira");
	testCommand("perl $program_directory/dag.pl -d test select A% n%","A1\tname\tAkira");
	testCommand("perl $program_directory/dag.pl -d test select % % A%","A\tid\tA1","A1\tname\tAkira");
	testCommand("perl $program_directory/dag.pl -d test select %1","A1\tname\tAkira","B1\tname\tBen","C1\tname\tChris","D1\tname\tDavid");
	testCommand("perl $program_directory/dag.pl -d test delete A%","deleted 2");
	testCommand("perl $program_directory/dag.pl -d test select ","B\tid\tB1","B1\tname\tBen","C\tid\tC1","C1\tname\tChris","D\tid\tD1","D1\tname\tDavid");
	testCommand("perl $program_directory/dag.pl -d test delete % name","deleted 3");
	testCommand("perl $program_directory/dag.pl -d test select ","B\tid\tB1","C\tid\tC1","D\tid\tD1");
	testCommand("perl $program_directory/dag.pl -d test delete % % %1","deleted 3");
	testCommand("perl $program_directory/dag.pl -d test insert T name Tsunami","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test select T","T\tname\tTsunami");
	testCommand("perl $program_directory/dag.pl -d test insert A name Akira","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test select","A\tname\tAkira","T\tname\tTsunami");
	testCommand("perl $program_directory/dag.pl -d test update A name Alice","updated 1");
	testCommand("perl $program_directory/dag.pl -d test select","A\tname\tAlice","T\tname\tTsunami");
	createFile("file/import.txt","A\tid\tA2","B\tid\tB2","C\tid\tC2","D\tid\tD2","A\tid\tA1","B\tid\tB1","C\tid\tC1","D\tid\tD1");
	testCommand("perl $program_directory/dag.pl -d test import < file/import.txt","inserted 8");
	testCommand("perl $program_directory/dag.pl -d test select % id","A\tid\tA1","A\tid\tA2","B\tid\tB1","B\tid\tB2","C\tid\tC1","C\tid\tC2","D\tid\tD1","D\tid\tD2");
	createFile("file/update.txt","A\tid\tA3","B\tid\tB3");
	testCommand("perl $program_directory/dag.pl -d test update < file/update.txt","updated 2");
	testCommand("perl $program_directory/dag.pl -d test select A id","A\tid\tA3");
	testCommand("perl $program_directory/dag.pl -d test select B id","B\tid\tB3");
	createFile("file/update.json","{\"A\":{\"name\":\"Akira\"},\"B\":{\"name\":\"Bob\"}}");
	testCommand("perl $program_directory/dag.pl -d test -f json update < file/update.json","updated 2");
	testCommand("perl $program_directory/dag.pl -d test select % name","A\tname\tAkira\nB\tname\tBob","T\tname\tTsunami");
	testCommand("perl $program_directory/dag.pl -d test delete < file/update.txt","deleted 2");
	testCommand("perl $program_directory/dag.pl -d test select % id","C\tid\tC1","C\tid\tC2","D\tid\tD1","D\tid\tD2");
	testCommand("perl $program_directory/dag.pl -d test -f json delete < file/update.json","deleted 2");
	testCommand("perl $program_directory/dag.pl -d test select % name","T\tname\tTsunami");
	testCommand("perl $program_directory/dag.pl -d test delete % % %","deleted 5");
	testCommand("perl $program_directory/dag.pl -d test -f json insert < file/update.json","inserted 2");
	testCommand("perl $program_directory/dag.pl -d test insert < file/import.txt","inserted 8");
	testCommand("perl $program_directory/dag.pl -d test delete % % %","deleted 10");
	#Testing query
	testCommand("echo \"A\tB\tC\nC\tD\tE\nC\tF\tG\"|perl $program_directory/dag.pl -d test import","inserted 3");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->B->\$c'","a\tc","A\tC");
	testCommand("perl $program_directory/dag.pl -d test -f json  query '\$a->B->\$c'","[{\"a\":\"A\",\"c\":\"C\"}]");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->B->\$c' '\$c->D->\$e'","a\tc\te","A\tC\tE");
	testCommand("perl $program_directory/dag.pl -d test -f json  query '\$a->B->\$c' '\$c->D->\$e'","[{\"a\":\"A\",\"c\":\"C\",\"e\":\"E\"}]");
	testCommand("echo \"C\tD\tH\"|perl $program_directory/dag.pl -d test insert","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->B->\$c' '\$c->D->\$e'","a\tc\te","A\tC\tE","A\tC\tH");
	testCommand("perl $program_directory/dag.pl -d test -f json  query '\$a->B->\$c' '\$c->D->\$e'","[{\"a\":\"A\",\"c\":\"C\",\"e\":\"E\"},{\"a\":\"A\",\"c\":\"C\",\"e\":\"H\"}]");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->B->\$c' '\$c->D->\$e' '\$c->F->\$g'","a\tc\te\tg","A\tC\tE\tG","A\tC\tH\tG");
	testCommand("perl $program_directory/dag.pl -d test -f json  query '\$a->B->\$c' '\$c->D->\$e' '\$c->F->\$g'","[{\"a\":\"A\",\"c\":\"C\",\"e\":\"E\",\"g\":\"G\"},{\"a\":\"A\",\"c\":\"C\",\"e\":\"H\",\"g\":\"G\"}]");
	testCommand("perl $program_directory/dag.pl -d test delete % % %","deleted 4");
	unlink("file/update.txt");
	unlink("file/update.json");
	unlink("file/import.txt");
	rmdir("file");
	#Testing query
	testCommand("perl $program_directory/dag.pl -d test/A insert id0 name Tsunami","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test/B insert id0 country Japan","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test/A query '\$id->name->\$name'","id\tname","id0\tTsunami");
	testCommand("perl $program_directory/dag.pl -d test/B query '\$id->country->\$country'","country\tid","Japan\tid0");
	testCommand("perl $program_directory/dag.pl -d test query '\$id->A/name->\$name,\$id->B/country->\$country'","country\tid\tname","Japan\tid0\tTsunami");
	testCommand("perl $program_directory/dag.pl query '\$id->test/A/name->\$name,\$id->test/B/country->\$country'","country\tid\tname","Japan\tid0\tTsunami");
	testCommand("perl $program_directory/dag.pl -d test/A delete % % %","deleted 1");
	testCommand("perl $program_directory/dag.pl -d test/B delete % % %","deleted 1");
	rmdir("test/B/log");
	rmdir("test/A");
	rmdir("test/B");
	#Tesiting json and tsv format
	testCommand("perl $program_directory/dag.pl -q -d test insert A B C","");
	testCommand("perl $program_directory/dag.pl -d test select","A\tB\tC");
	testCommand("perl $program_directory/dag.pl -f tsv -d test select","A\tB\tC");
	testCommand("perl $program_directory/dag.pl -d test insert A B D","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test -f tsv select","A\tB\tC","A\tB\tD");
	testCommand("perl $program_directory/dag.pl -d test -f json select","{\"A\":{\"B\":[\"C\",\"D\"]}}");
	testCommand("perl $program_directory/dag.pl -d test delete % % %","deleted 2");
	testCommand("perl $program_directory/dag.pl -q -d test assign A B C","");
	testCommand("perl $program_directory/dag.pl -f json -d test select","{\"A\":{\"B\":\"C\"}}");
	testCommand("perl $program_directory/dag.pl -d test assign A B C","inserted 0");
	testCommand("perl $program_directory/dag.pl -q -d test delete % % %","");
	#testing query
	createFile("db/input.txt","root\takira.txt");
	testCommand("perl $program_directory/dag.pl -d db query 'root->input->\$input'","input","akira.txt");
	testCommand("perl $program_directory/dag.pl -d db query 'root->input->\$input,\$input->flag/needparse->true'");
	createFile("db/flag/needparse.txt","akira.txt\ttrue");
	testCommand("perl $program_directory/dag.pl -d db query 'root->input->\$input,\$input->flag/needparse->true'","input","akira.txt");
	createFile("db/flag/needparse.txt","akira.txt\tfalse");
	testCommand("perl $program_directory/dag.pl -d db query 'root->input->\$input,\$input->flag/needparse->true'");
	unlink("db/flag/needparse.txt");
	testCommand("perl $program_directory/dag.pl -d db query 'root->input->\$input,\$input->flag/needparse->true'");
	testCommand("perl $program_directory/dag.pl -d db query '\$input->flag/needparse->true,root->input->\$input'");
	rmdir("db/flag");
	unlink("db/input.txt");
	rmdir("db");
	#Testing * and ? with one column file
	createFile("test/single.txt","A","B","C","D");
	testCommand("perl $program_directory/dag.pl query 'root->test/single->\$var'","var","A","B","C","D");
	testCommand("perl $program_directory/dag.pl query '*->test/single->\$var'","var","A","B","C","D");
	testCommand("perl $program_directory/dag.pl query '?->test/single->\$var'","var","A","B","C","D");
	unlink("test/single.txt");
	#Testing variables in predicates
	createFile("test/root.txt","A","root2\tB");
	createFile("test/A/value.txt","B\t2","B\t3","C\t4","D\t5");
	createFile("test/B/value.txt","E\t6");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir'","dir","A");
	testCommand("perl $program_directory/dag.pl -d test query 'root2->root->\$dir'","dir","B");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir' '\$key->\$dir/value->\$val'","dir\tkey\tval","A\tB\t2","A\tB\t3","A\tC\t4","A\tD\t5");
	testCommand("perl $program_directory/dag.pl -d test query 'root2->root->\$dir' '\$key->\$dir/value->\$val'","dir\tkey\tval","B\tE\t6");
	createFile("test/root.txt","A");
	createFile("test/A/value.txt","AA\tB\t1","CA\tB\t2","EA\tB\t3","AA\tC\t4","CA\tC\t5","EA\tC\t6");
	createFile("test/B/value.txt","AB\tB\t4","CB\tB\t5","EB\tB\t6");
	testCommand("perl $program_directory/dag.pl -d test query '\$key->A/value#B->\$val'","key\tval","AA\t1","CA\t2","EA\t3");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir' '\$key->\$dir/value#B->\$val'","dir\tkey\tval","A\tAA\t1","A\tCA\t2","A\tEA\t3");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir' '\$key->\$dir/value#C->\$val'","dir\tkey\tval","A\tAA\t4","A\tCA\t5","A\tEA\t6");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir' '\$key->\$dir/value#\$anchor->\$val'","anchor\tdir\tkey\tval","B\tA\tAA\t1","B\tA\tCA\t2","B\tA\tEA\t3","C\tA\tAA\t4","C\tA\tCA\t5","C\tA\tEA\t6");
	testCommand("perl $program_directory/dag.pl -d test query '\$key->\$dir/value#B->\$val'","dir\tkey\tval","A\tAA\t1","A\tCA\t2","A\tEA\t3","B\tAB\t4","B\tCB\t5","B\tEB\t6");
	unlink("test/root.txt");
	unlink("test/A/value.txt");
	unlink("test/B/value.txt");
	rmdir("test/A");
	rmdir("test/B");
	#Testing assign arguments
	testCommand("perl $program_directory/dag.pl -d test query '\$a=\"A\"'","a","A");
	testCommand("perl $program_directory/dag.pl -d test query '\$a=\"A\"' '\$b=\"H\"'","a\tb","A\tH");
	testCommand("perl $program_directory/dag.pl -d test query '\$a=\"A\",\$b=\"H\"'","a\tb","A\tH");
	testCommand("perl $program_directory/dag.pl -d test query '\$a=[\"A\",\"T\"],\$b=\"H\"'","a\tb","A\tH","T\tH");
	testCommand("perl $program_directory/dag.pl -d test query '\$a=[\"A\",\"T\"],\$b=[\"H\"]'","a\tb","A\tH","T\tH");
	testCommand("perl $program_directory/dag.pl -d test query '\$a=[\"A\",\"T\"],\$b=[\"H\",\"J\"]'","a\tb","A\tH","T\tH","A\tJ","T\tJ");
	testCommand("perl $program_directory/dag.pl -d test query '{\"a\":\"A\",\"b\":\"H\"}'","a\tb","A\tH");
	testCommand("perl $program_directory/dag.pl -d test query '{\"a\":\"A\",\"b\":\"H\"}' '{\"c\":\"T\",\"d\":\"J\"}'","a\tb\tc\td","A\tH\t\t","\t\tT\tJ");
	testCommand("perl $program_directory/dag.pl -d test query '[{\"a\":\"A\",\"b\":\"H\"},{\"a\":\"T\",\"b\":\"J\"}]'","a\tb","A\tH","T\tJ");
	testCommand("perl $program_directory/dag.pl -d test query '[{\"a\":\"A\"},{\"b\":\"H\"}]'","a\tb","A\t","\tH");
	testCommand("perl $program_directory/dag.pl -d test query '{\"c\":\"T\",\"d\":\"J\"}' '\$a=[\"A\",\"H\"]'","a\tc\td","A\tT\tJ","H\tT\tJ");
	testCommand("perl $program_directory/dag.pl -d test query '{\"c\":\"T\",\"d\":\"J\"}' '{\"b\":\"T\",\"d\":\"J\"}' '\$a=[\"A\",\"H\"]'","a\tb\tc\td","A\t\tT\tJ","A\tT\t\tJ","H\t\tT\tJ","H\tT\t\tJ");
}
#Testing advanced cases
sub test3{
	#Testing query with anchors
	createFile("test/input.txt","A\tB","C\tD\tE","F\tG","H\tI\tJ");
	testCommand("perl $program_directory/dag.pl -d test query '\$one->input->\$two'","one\ttwo","A\tB","F\tG");
	testCommand("perl $program_directory/dag.pl -d test query '\$one->input#D->\$two'","one\ttwo","C\tE");
	testCommand("perl $program_directory/dag.pl -d test query '\$one->input#I->\$two'","one\ttwo","H\tJ");
	testCommand("perl $program_directory/dag.pl -d test query '\$one->input#D->\$two' '\$one->input#I->\$three'");
	testCommand("perl $program_directory/dag.pl -x -d test query '\$one->input#D->\$two' '\$one->input#I->\$three'","one\tthree\ttwo","C\t\tE","H\tJ\t");
	testCommand("perl $program_directory/dag.pl -d test query '\$one->input#\$two->\$three'","one\tthree\ttwo","C\tE\tD","H\tJ\tI");
	testCommand("perl $program_directory/dag.pl -d test query '\$one->\$two#\$three->\$four'","four\tone\tthree\ttwo","E\tC\tD\tinput","J\tH\tI\tinput");
	unlink("test/input.txt");
	createFile("test/input2.txt","A\tBC\tD","E\tBF\tG","H\tIJ\tK","L\tIM\tN");
	testCommand("perl $program_directory/dag.pl -d test query '\$one->\$two#B\$three->\$four' '\$one->\$two#I\$five->\$four'","five\tfour\tone\tthree\ttwo","\tD\tA\tC\tinput2","\tG\tE\tF\tinput2","J\tK\tH\t\tinput2","M\tN\tL\t\tinput2");
	unlink("test/input2.txt");
	#Testing special queries like ()
	createFile("test/import.txt","A\tB\tC","X\tB\tY","C\tD\tE","C\tD\tH","C\tD\tI","F\tD\tG");
	testCommand("perl $program_directory/dag.pl -d test insert < test/import.txt","inserted 6");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->B->\$c,\$c->D->\$e'","a\tc\te","A\tC\tE","A\tC\tH","A\tC\tI");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->B->\$c,\$c->D->(\$e)'","a\tc\te","A\tC\tE H I");
	testCommand("perl $program_directory/dag.pl -d test query '(\$a)->B->\$c,\$c->D->(\$e)'","a\tc\te","A\tC\tE H I");
	testCommand("perl $program_directory/dag.pl -x -d test query '\$a->B->\$c,\$c->D->\$e'","a\tc\te","A\tC\tE","A\tC\tH","A\tC\tI","X\tY\t","\tF\tG");
	testCommand("perl $program_directory/dag.pl -x -d test query '\$a->B->\$c,\$c->D->(\$e)'","a\tc\te","A\tC\tE H I","X\tY\t","\tF\tG");
	unlink("test/import.txt");
	unlink("test/B.txt");
	unlink("test/D.txt");
	#Testing special predicates (directory,anchor)
	mkdir("test/name");
	createFile("test/name/one.txt","Akira\tA","Ben\tB");
	createFile("test/name/two.txt","Chris\tC","David\tD");
	testCommand("perl $program_directory/dag.pl -d test query '\$name->name->\$initial\'","initial\tname","A\tAkira","B\tBen","C\tChris","D\tDavid");
	testCommand("perl $program_directory/dag.pl -d test query '\$name->name/one->\$initial\'","initial\tname","A\tAkira","B\tBen");
	testCommand("perl $program_directory/dag.pl -d test query '\$name->name/two->\$initial\'","initial\tname","C\tChris","D\tDavid");
	testCommand("perl $program_directory/dag.pl -d test select % name/one %","Akira\tname/one\tA","Ben\tname/one\tB");
	testCommand("perl $program_directory/dag.pl -d test select % name/two %","Chris\tname/two\tC","David\tname/two\tD");
	testCommand("perl $program_directory/dag.pl -d test select % name% %","Akira\tname/one\tA","Ben\tname/one\tB","Chris\tname/two\tC","David\tname/two\tD");
	testCommand("perl $program_directory/dag.pl -d test select % name/% %","Akira\tname/one\tA","Ben\tname/one\tB","Chris\tname/two\tC","David\tname/two\tD");
	testCommand("perl $program_directory/dag.pl -d test delete % name/o% %","deleted 2");
	testCommand("perl $program_directory/dag.pl -d test delete % name% %","deleted 2");
	rmdir("test/name");
	testCommand("perl $program_directory/dag.pl -d test update A B#C D","updated 1");
	testCommand("perl $program_directory/dag.pl -d test select","A\tB#C\tD");
	testCommand("perl $program_directory/dag.pl -d test update A B#C E","updated 1");
	testCommand("perl $program_directory/dag.pl -d test select","A\tB#C\tE");
	testCommand("perl $program_directory/dag.pl -d test insert A B D","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test select A B","A\tB\tD");
	testCommand("perl $program_directory/dag.pl -d test select A B#C","A\tB#C\tE");
	testCommand("perl $program_directory/dag.pl -d test select A B%","A\tB\tD","A\tB#C\tE");
	testCommand("perl $program_directory/dag.pl -d test select A B#%","A\tB#C\tE");
	testCommand("perl $program_directory/dag.pl -d test delete A B%","deleted 2");
	testCommand("perl $program_directory/dag.pl -d test insert A B C","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test insert A B#D C","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test insert A B#E C","inserted 1");
	testCommand("cat test/B.txt","A\tC","A\tD\tC","A\tE\tC");
	testCommand("perl $program_directory/dag.pl select A test/B","A\ttest/B\tC");
	testCommand("perl $program_directory/dag.pl select A test/B#D","A\ttest/B#D\tC");
	testCommand("perl $program_directory/dag.pl select A test/B#%","A\ttest/B#D\tC","A\ttest/B#E\tC");
	testCommand("perl $program_directory/dag.pl select A test/B%","A\ttest/B\tC","A\ttest/B#D\tC","A\ttest/B#E\tC");
	testCommand("perl $program_directory/dag.pl -d test delete A B#%","deleted 2");
	testCommand("perl $program_directory/dag.pl -d test delete A B%","deleted 1");
	#Testing directory and file priority (file has more priority)
	mkdir("test/name");
	testCommand("perl $program_directory/dag.pl -d test insert A name Akira","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test select A name","A\tname\tAkira");
	testCommand("perl $program_directory/dag.pl select A test/name","A\ttest/name\tAkira");
	testCommand("perl $program_directory/dag.pl -d test insert A name/one Akita","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test select A name","A\tname\tAkira");
	testCommand("perl $program_directory/dag.pl -d test select A name/one","A\tname/one\tAkita");
	testCommand("perl $program_directory/dag.pl -d test insert B name/one Benben","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test select A name/%","A\tname/one\tAkita");
	# name.txt exists and name/ exits
	# select % name will select file test/name.txt because it has more priority
	testCommand("perl $program_directory/dag.pl -d test select","A\tname\tAkira","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $program_directory/dag.pl -d test select % name","A\tname\tAkira");
	testCommand("perl $program_directory/dag.pl -d test select % name/","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $program_directory/dag.pl -d test select % name/%","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $program_directory/dag.pl -d test select A","A\tname\tAkira","A\tname/one\tAkita");
	# name.txt doesn't exist and name/ exits
	# select % name will select all files under name/ directory
	unlink("test/name.txt");
	testCommand("perl $program_directory/dag.pl -d test select","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $program_directory/dag.pl -d test select % name","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $program_directory/dag.pl -d test select % name/","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $program_directory/dag.pl -d test select % name/%","A\tname/one\tAkita","B\tname/one\tBenben");
	testCommand("perl $program_directory/dag.pl -d test select A","A\tname/one\tAkita");
	unlink("test/name/one.txt");
	rmdir("test/name");
	# Testing URL with anchor
	testCommand("perl $program_directory/dag.pl -d test/db insert A id A1","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test/db select","A\tid\tA1");
	createFile("test/insert.txt","A\tid#one\tAone","B\tid#one\tBone");
	testCommand("perl $program_directory/dag.pl -d test/db insert <test/insert.txt","inserted 2");
	testCommand("perl $program_directory/dag.pl -d test/db select","A\tid\tA1","A\tid#one\tAone","B\tid#one\tBone");
	testCommand("perl $program_directory/dag.pl -d test/db update A id A11","updated 1");
	testCommand("perl $program_directory/dag.pl -d test/db select","A\tid\tA11","A\tid#one\tAone","B\tid#one\tBone");
	testCommand("perl $program_directory/dag.pl -d test/db update A 'id#one' Atwo","updated 1");
	testCommand("perl $program_directory/dag.pl -d test/db select","A\tid\tA11","A\tid#one\tAtwo","B\tid#one\tBone");
	createFile("test/update.txt","A\tid#one\tAthree","B\tid#one\tBthree");
	testCommand("perl $program_directory/dag.pl -d test/db update < test/update.txt","updated 2");
	testCommand("perl $program_directory/dag.pl -d test/db select","A\tid\tA11","A\tid#one\tAthree","B\tid#one\tBthree");
	createFile("test/update.txt","A\tid\tAfour","B\tid#one\tBfour");
	testCommand("perl $program_directory/dag.pl -d test/db update < test/update.txt","updated 2");
	testCommand("perl $program_directory/dag.pl -d test/db select","A\tid\tAfour","A\tid#one\tAthree","B\tid#one\tBfour");
	testCommand("perl $program_directory/dag.pl -d test/db delete < test/update.txt","deleted 2");
	testCommand("perl $program_directory/dag.pl -d test/db select","A\tid#one\tAthree");
	testCommand("perl $program_directory/dag.pl -d test/db delete A 'id#one' Athree","deleted 1");
	unlink("test/insert.txt");
	unlink("test/update.txt");
	rmdir("test/db");
	#Testing predicate with variables
	createFile("test/one.txt","A:B:C\tD","A:B:C\tE");
	testCommand("perl $program_directory/dag.pl -d test query '\$a:\$b:\$c->one->\$d'","a\tb\tc\td","A\tB\tC\tD","A\tB\tC\tE");
	createFile("test/A/B/C/D.txt","D\tE");
	createFile("test/A/B/C/E.txt","E\tF");
	createFile("test/A/B/C/F.txt","F\tG");
	createFile("test/A/B/C/G.txt","G\tH");
	testCommand("perl $program_directory/dag.pl -d test query '\$a:\$b:\$c->one->\$d' '\$f->\$a/\$b/\$c/\$d->\$g'","a\tb\tc\td\tf\tg","A\tB\tC\tD\tD\tE","A\tB\tC\tE\tE\tF");
	unlink("test/one.txt");
	unlink("test/A/B/C/D.txt");
	unlink("test/A/B/C/E.txt");
	unlink("test/A/B/C/F.txt");
	unlink("test/A/B/C/G.txt");
	rmdir("test/A/B/C");
	rmdir("test/A/B");
	rmdir("test/A");
	#Testing multiple predicate variable query
	createFile("test/root.txt","A");
	createFile("test/A/value.txt","AA\tB\t1","CA\tB\t2","EA\tB\t3","AA\tC\t4","CA\tC\t5","EA\tC\t6");
	createFile("test/B/value.txt","AB\tB\t4","CB\tB\t5","EB\tB\t6");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir' '\$key->\$dir/value#A->\$val'");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir' '\$key->\$dir/value#B->\$val'","dir\tkey\tval","A\tAA\t1","A\tCA\t2","A\tEA\t3");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir' '\$key->\$dir/value#C->\$val'","dir\tkey\tval","A\tAA\t4","A\tCA\t5","A\tEA\t6");
	createFile("test/AA.txt","a\ta");
	createFile("test/CA.txt","c\ta");
	createFile("test/EA.txt","e\ta");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir' '\$key->\$dir/value#B->\$val' '\$k->\$key->\$v'","dir\tk\tkey\tv\tval","A\ta\tAA\ta\t1","A\tc\tCA\ta\t2","A\te\tEA\ta\t3");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir' '\$key->\$dir/value#\$anchor->\$val'","anchor\tdir\tkey\tval","B\tA\tAA\t1","B\tA\tCA\t2","B\tA\tEA\t3","C\tA\tAA\t4","C\tA\tCA\t5","C\tA\tEA\t6");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir' '\$key->\$dir/value#A->\$val' '\$k->\$key->\$v'");
	testCommand("perl $program_directory/dag.pl -d test query 'root->root->\$dir' '\$key->\$dir/value#\$anchor->\$val' '\$k->\$key->\$v'","anchor\tdir\tk\tkey\tv\tval","B\tA\ta\tAA\ta\t1","C\tA\ta\tAA\ta\t4","B\tA\tc\tCA\ta\t2","C\tA\tc\tCA\ta\t5","B\tA\te\tEA\ta\t3","C\tA\te\tEA\ta\t6");
	unlink("test/root.txt");
	unlink("test/A/value.txt");
	unlink("test/B/value.txt");
	unlink("test/AA.txt");
	unlink("test/CA.txt");
	unlink("test/EA.txt");
	rmdir("test/A");
	rmdir("test/B");
	#Testing selction with anchor functionality
	createFile("test/A.txt","A\tname\tAkira","A\tage\t18","B\tname\tBen","B\tage\t19");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->A#name->\$name' '\$a->A#age->\$age'","a\tage\tname","A\t18\tAkira","B\t19\tBen");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->A#name->Akira' '\$a->A#age->\$age'","a\tage","A\t18");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->A#name->Ben' '\$a->A#age->\$age'","a\tage","B\t19");
	unlink("test/A.txt");
}
sub test4{
	#Testing file predicates FASTA, CSV, TSV
	createFile("test/fasta.fa",">A","AAAAAAAAAAAA","AAAAAAAAAAAA",">C","CCCCCCCCCCCC","CCCCCCCCCCCC","CCCCCCCCCCCC",">G","GGGGGGGGGGGG","GGGGGGGGGGGG","GGGGGGGGGGGG","GGGGGGGGGGGG",">T","TTTTTTTTTTTT","TTTTTTTTTTTT","TTTTTTTTTTTT","TTTTTTTTTTTT","TTTTTTTTTTTT");
	testCommand("perl $program_directory/dag.pl -d test query '\$id->test/fasta->\$seq'","");
	testCommand("perl $program_directory/dag.pl query '\$id->test/fasta->\$seq'","id\tseq","A\tAAAAAAAAAAAAAAAAAAAAAAAA","C\tCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC","G\tGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG","T\tTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT");
	testCommand("perl $program_directory/dag.pl -d test query '\$id->test/fasta.fa->\$seq'","id\tseq","A\tAAAAAAAAAAAAAAAAAAAAAAAA","C\tCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC","G\tGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG","T\tTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT");
	createFile("test/name.txt","Akira\tA","Chris\tC","George\tG","Tsunami\tT");
	testCommand("perl $program_directory/dag.pl -d test query '\$name->name->\$initial'","initial\tname","A\tAkira","C\tChris","G\tGeorge","T\tTsunami");
	testCommand("perl $program_directory/dag.pl -f json -d test query '\$name->name->\$initial'","[{\"initial\":\"A\",\"name\":\"Akira\"},{\"initial\":\"C\",\"name\":\"Chris\"},{\"initial\":\"G\",\"name\":\"George\"},{\"initial\":\"T\",\"name\":\"Tsunami\"}]");
	testCommand("perl $program_directory/dag.pl -f json -d test query '\$firstname->name->\$initial'","[{\"firstname\":\"Akira\",\"initial\":\"A\"},{\"firstname\":\"Chris\",\"initial\":\"C\"},{\"firstname\":\"George\",\"initial\":\"G\"},{\"firstname\":\"Tsunami\",\"initial\":\"T\"}]");
	createFile("test/tsv.tsv","A\tA1\tA2","B\tB1\tB2","C\tC1\tC2","D\tD1\tD2","E\tE1\tE2");
	testCommand("perl $program_directory/dag.pl -d test query '\$name->name->\$alpha\' '\$alpha->fasta->\$fasta\'","alpha\tfasta\tname","A\tAAAAAAAAAAAAAAAAAAAAAAAA\tAkira","C\tCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\tChris","G\tGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\tGeorge","T\tTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\tTsunami");
	testCommand("perl $program_directory/dag.pl -d test query '\$name->name->\$alpha\' '\$alpha->test/fasta.fa->\$fasta\'","alpha\tfasta\tname","A\tAAAAAAAAAAAAAAAAAAAAAAAA\tAkira","C\tCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\tChris","G\tGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\tGeorge","T\tTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\tTsunami");
	testCommand("perl $program_directory/dag.pl -d test query '\$name->name->\$alpha\' '\$alpha->tsv#0:1->\$column\'","alpha\tcolumn\tname","A\tA1\tAkira","C\tC1\tChris");
	testCommand("perl $program_directory/dag.pl -d test query '\$name->name->\$alpha\' '\$alpha->tsv#0:2->\$column\'","alpha\tcolumn\tname","A\tA2\tAkira","C\tC2\tChris");
	testCommand("perl $program_directory/dag.pl -d test query '\$name->name->\$alpha\' '\$alpha->test/tsv.tsv#0:1->\$column\'","alpha\tcolumn\tname","A\tA1\tAkira","C\tC1\tChris");
	testCommand("perl $program_directory/dag.pl -d test query '\$name->name->\$alpha\' '\$alpha->test/tsv.tsv#0:2->\$column\'","alpha\tcolumn\tname","A\tA2\tAkira","C\tC2\tChris");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->tsv#0:1->A1\'","a","A");
	unlink("test/name.txt");
	unlink("test/fasta.fa");
	#TSV
	unlink("test/tsv.tsv");
	createFile("test/input.tsv","A\t1\t2\t3\t4\t5","B\t6\t7\t8\t9\t10","C\t11\t12\t13\t14\t15");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.tsv#0:1->\$value\'","key\tvalue","A\t1","B\t6","C\t11");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.tsv#0:2->\$value\'","key\tvalue","A\t2","B\t7","C\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.tsv#1:2->\$value\'","key\tvalue","1\t2","6\t7","11\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.tsv#2:3->\$value\'","key\tvalue","2\t3","7\t8","12\t13");
	unlink("test/input.tsv");
	createFile("test/input2.tsv","name\tone\ttwo\tthree\tfour\tfive","A\t1\t2\t3\t4\t5","B\t6\t7\t8\t9\t10","C\t11\t12\t13\t14\t15");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.tsv#0:1->\$value\'","key\tvalue","name\tone","A\t1","B\t6","C\t11");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.tsv#0:2->\$value\'","key\tvalue","name\ttwo","A\t2","B\t7","C\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.tsv#0:2->\$value\'","key\tvalue","name\ttwo","A\t2","B\t7","C\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.tsv#1:2->\$value\'","key\tvalue","one\ttwo","1\t2","6\t7","11\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.tsv#2:3->\$value\'","key\tvalue","two\tthree","2\t3","7\t8","12\t13");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.tsv#name:one->\$value\'","key\tvalue","A\t1","B\t6","C\t11");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.tsv#name:two->\$value\'","key\tvalue","A\t2","B\t7","C\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.tsv#two:three->\$value\'","key\tvalue","2\t3","7\t8","12\t13");
	unlink("test/input2.tsv");
	createFile("test/input.tsv","A\t1\t2\t3\t4\t5","B\t6\t7\t8\t9\t10");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.tsv#0:1->\$val\'","key\tval","A\t1","B\t6");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.tsv#0:1:2:3:5->\$v1:\$v2:\$v3:\$v5\'","key\tv1\tv2\tv3\tv5","A\t1\t2\t3\t5","B\t6\t7\t8\t10");
	unlink("test/input.tsv");
	#CSV
	createFile("test/input.bed","chr22\t1000\t5000\tcloneA\t960\t+\t1000\t5000\t0\t2\t567,488,\t0,3512","chr22\t2000\t6000\tcloneB\t900\t-\t2000\t6000\t0\t2\t433,399,\t0,3601");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.bed->\$val'","key\tval","cloneA\tchr22:1000..5000:+","cloneB\tchr22:2000..6000:-");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.bed#name:position->\$val'","key\tval","cloneA\tchr22:1000..5000:+","cloneB\tchr22:2000..6000:-");
	testCommand("perl $program_directory/dag.pl query '\$id->test/input.bed#name:chrom->\$chr'","chr\tid","chr22\tcloneA","chr22\tcloneB");
	testCommand("perl $program_directory/dag.pl query '\$id->test/input.bed#3:0:1:2:4:5->\$chr:\$start:\$end:\$score:\$strand'","chr\tend\tid\tscore\tstart\tstrand","chr22\t5000\tcloneA\t960\t1000\t+","chr22\t6000\tcloneB\t900\t2000\t-");
	testCommand("perl $program_directory/dag.pl query '\$id->test/input.bed#3:0:1:2:4:5:chromLength:position->\$chr:\$start:\$end:\$score:\$strand:\$chromLength:\$position'","chr\tchromLength\tend\tid\tposition\tscore\tstart\tstrand","chr22\t4000\t5000\tcloneA\tchr22:1000..5000:+\t960\t1000\t+","chr22\t4000\t6000\tcloneB\tchr22:2000..6000:-\t900\t2000\t-");
	unlink("test/input.bed");
	createFile("test/input.csv","'A',1,2,3,4,5","'B',6,7,8,9,10","'C',11,12,13,14,15");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.csv#0:1->\$value\'","key\tvalue","A\t1","B\t6","C\t11");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.csv#0:2->\$value\'","key\tvalue","A\t2","B\t7","C\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.csv#1:2->\$value\'","key\tvalue","1\t2","6\t7","11\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input.csv#2:3->\$value\'","key\tvalue","2\t3","7\t8","12\t13");
	unlink("test/input.csv");
	#CSV with labels
	createFile("test/input2.csv","\"name\",\"one\",\"two\",\"three\",\"four\",\"five\"","\"A\",1,2,3,4,5","\"B\",6,7,8,9,10","\"C\",11,12,13,14,15");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.csv#0:1->\$value\'","key\tvalue","name\tone","A\t1","B\t6","C\t11");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.csv#0:2->\$value\'","key\tvalue","name\ttwo","A\t2","B\t7","C\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.csv#0:2->\$value\'","key\tvalue","name\ttwo","A\t2","B\t7","C\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.csv#1:2->\$value\'","key\tvalue","one\ttwo","1\t2","6\t7","11\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.csv#2:3->\$value\'","key\tvalue","two\tthree","2\t3","7\t8","12\t13");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.csv#name:one->\$value\'","key\tvalue","A\t1","B\t6","C\t11");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.csv#name:two->\$value\'","key\tvalue","A\t2","B\t7","C\t12");
	testCommand("perl $program_directory/dag.pl query '\$key->test/input2.csv#two:three->\$value\'","key\tvalue","2\t3","7\t8","12\t13");
	unlink("test/input2.csv");
	#FASTQ
	createFile("test/input.fq","\@idA","AAAAAAAAAAAA","+","////////////","\@idB","BBBBBBBBBBBB","+","////////////");
	testCommand("perl $program_directory/dag.pl query '\$id->test/input.fq->\$seq'","id\tseq","idA\tAAAAAAAAAAAA","idB\tBBBBBBBBBBBB");
	createFile("test/input.fq","\@idA","AAAAAAAAAAAA","+","////////////","\@idB","BBBBBBBBBBBB","+","////////////");
	testCommand("perl $program_directory/dag.pl query '\$qual->test/input.fq#quality:id:sequence->\$id:\$seq'","id\tqual\tseq","idA idB\t////////////\tAAAAAAAAAAAA BBBBBBBBBBBB");
	testCommand("perl $program_directory/dag.pl query '\$id->test/input.fq#id:sequence:quality:length->\$sequence:\$quality:\$length'","id\tlength\tquality\tsequence","idA\t12\t////////////\tAAAAAAAAAAAA","idB\t12\t////////////\tBBBBBBBBBBBB");
	unlink("test/input.fq");
	#GTF
	createFile("test/input.gtf","GL000213.1\tprotein_coding\tCDS\t138767\t139287\t.\t-\t0\t gene_id \"ENSG00000237375\"; transcript_id \"ENST00000327822\"; exon_number \"1\"; gene_name \"BX072566.1\"; gene_biotype \"protein_coding\"; transcript_name \"BX072566.1-201\"; protein_id \"ENSP00000329990\";","GL000213.1\tprotein_coding\tstart_codon\t139285\t139287\t.\t-\t0\t gene_id \"ENSG00000237375\"; transcript_id \"ENST00000327822\"; exon_number \"1\"; gene_name \"BX072566.1\"; gene_biotype \"protein_coding\"; transcript_name \"BX072566.1-201\";","GL000213.1\tprotein_coding\texon\t134276\t134390\t.\t-\t.\t gene_id \"ENSG00000237375\"; transcript_id \"ENST00000327822\"; exon_number \"2\"; gene_name \"BX072566.1\"; gene_biotype \"protein_coding\"; transcript_name \"BX072566.1-201\";","GL000213.1\tprotein_coding\tCDS\t134276\t134390\t.\t-\t1\t gene_id \"ENSG00000237375\"; transcript_id \"ENST00000327822\"; exon_number \"2\"; gene_name \"BX072566.1\"; gene_biotype \"protein_coding\"; transcript_name \"BX072566.1-201\"; protein_id \"ENSP00000329990\";","GL000213.1\tprotein_coding\texon\t133943\t134116\t.\t-\t.\t gene_id \"ENSG00000237375\"; transcript_id \"ENST00000327822\"; exon_number \"3\"; gene_name \"BX072566.1\"; gene_biotype \"protein_coding\"; transcript_name \"BX072566.1-201\";");
	testCommand("perl $program_directory/dag.pl query '\$id->test/input.gtf->\$value'","id\tvalue","GL000213.1:138767..139287\tgene_id \"ENSG00000237375\"; transcript_id \"ENST00000327822\"; exon_number \"1\"; gene_name \"BX072566.1\"; gene_biotype \"protein_coding\"; transcript_name \"BX072566.1-201\"; protein_id \"ENSP00000329990\";","GL000213.1:139285..139287\tgene_id \"ENSG00000237375\"; transcript_id \"ENST00000327822\"; exon_number \"1\"; gene_name \"BX072566.1\"; gene_biotype \"protein_coding\"; transcript_name \"BX072566.1-201\";","GL000213.1:134276..134390\tgene_id \"ENSG00000237375\"; transcript_id \"ENST00000327822\"; exon_number \"2\"; gene_name \"BX072566.1\"; gene_biotype \"protein_coding\"; transcript_name \"BX072566.1-201\";","GL000213.1:134276..134390\tgene_id \"ENSG00000237375\"; transcript_id \"ENST00000327822\"; exon_number \"2\"; gene_name \"BX072566.1\"; gene_biotype \"protein_coding\"; transcript_name \"BX072566.1-201\"; protein_id \"ENSP00000329990\";","GL000213.1:133943..134116\tgene_id \"ENSG00000237375\"; transcript_id \"ENST00000327822\"; exon_number \"3\"; gene_name \"BX072566.1\"; gene_biotype \"protein_coding\"; transcript_name \"BX072566.1-201\";");
	testCommand("perl $program_directory/dag.pl query '\$id->test/input.gtf#position:gene_id:transcript_id->\$geneId:\$transcriptId'","geneId\tid\ttranscriptId","ENSG00000237375\tGL000213.1:138767..139287\tENST00000327822","ENSG00000237375\tGL000213.1:139285..139287\tENST00000327822","ENSG00000237375\tGL000213.1:134276..134390\tENST00000327822","ENSG00000237375\tGL000213.1:133943..134116\tENST00000327822");
	unlink("test/input.gtf");
	#Testing multiple objects
	createFile("test/input.tsv","#id\tposition","Akira\t1 2","Akita\t3 4","Akisa\t5 6");
	testCommand("perl $program_directory/dag.pl -d test query '\$id->input#id:position->\$x \$y'","id\tx\ty","Akira\t1\t2","Akita\t3\t4","Akisa\t5\t6");
	unlink("test/input.tsv");
}
#Testing list and advanced () functionality
sub test5{
	mkdir("css");
	createFile("css/classic.css");
	createFile("css/clean.css");
	createFile("css/flex.css");
	createFile("css/tab.css");
	#Check system->ls with ':'
	testCommand("perl $program_directory/dag.pl -f json query 'system->ls css->\$filepath'","[{\"filepath\":\"css/classic.css\"},{\"filepath\":\"css/clean.css\"},{\"filepath\":\"css/flex.css\"},{\"filepath\":\"css/tab.css\"}]");
	testCommand("perl $program_directory/dag.pl -f json query 'system->ls css->\$filepath:\$dir'","[{\"dir\":\"css\",\"filepath\":\"css/classic.css\"},{\"dir\":\"css\",\"filepath\":\"css/clean.css\"},{\"dir\":\"css\",\"filepath\":\"css/flex.css\"},{\"dir\":\"css\",\"filepath\":\"css/tab.css\"}]");
	testCommand("perl $program_directory/dag.pl -f json query 'system->ls css->\$file:\$dir:\$filename'","[{\"dir\":\"css\",\"file\":\"css/classic.css\",\"filename\":\"classic\"},{\"dir\":\"css\",\"file\":\"css/clean.css\",\"filename\":\"clean\"},{\"dir\":\"css\",\"file\":\"css/flex.css\",\"filename\":\"flex\"},{\"dir\":\"css\",\"file\":\"css/tab.css\",\"filename\":\"tab\"}]");
	testCommand("perl $program_directory/dag.pl -f json query 'system->ls css->\$file:\$dir:\$filename:\$suffix'","[{\"dir\":\"css\",\"file\":\"css/classic.css\",\"filename\":\"classic\",\"suffix\":\"css\"},{\"dir\":\"css\",\"file\":\"css/clean.css\",\"filename\":\"clean\",\"suffix\":\"css\"},{\"dir\":\"css\",\"file\":\"css/flex.css\",\"filename\":\"flex\",\"suffix\":\"css\"},{\"dir\":\"css\",\"file\":\"css/tab.css\",\"filename\":\"tab\",\"suffix\":\"css\"}]");
	#check system->ls
	testCommand("perl $program_directory/dag.pl query 'system->ls css/*->\$file'","file","css/classic.css","css/clean.css","css/flex.css","css/tab.css");
	testCommand("perl $program_directory/dag.pl query 'system->ls css/*->\$dir/\$file'","dir\tfile","css\tclassic.css","css\tclean.css","css\tflex.css","css\ttab.css");
	testCommand("perl $program_directory/dag.pl query 'system->ls css/*->\$dir/\$basename.css'",
"basename\tdir","classic\tcss","clean\tcss","flex\tcss","tab\tcss");
	system("rm -r css");
	#A->B->C
	#A->B->D
	testCommand("perl $program_directory/dag.pl -d test insert A B C","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test insert A B D","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test query 'A->B->(\$c)'","c","C D");
	testCommand("perl $program_directory/dag.pl -d test -f json query 'A->B->(\$c)'","[{\"c\":[\"C\",\"D\"]}]");
	testCommand("perl $program_directory/dag.pl -d test query 'A->*->(\$c)'","c","C D");
	testCommand("perl $program_directory/dag.pl -d test -f json query 'A->*->(\$c)'","[{\"c\":[\"C\",\"D\"]}]");
	testCommand("perl $program_directory/dag.pl -d test query '*->*->(\$c)'","c","C D");
	testCommand("perl $program_directory/dag.pl -d test -f json query '*->*->(\$c)'","[{\"c\":[\"C\",\"D\"]}]");
	testCommand("perl $program_directory/dag.pl -d test delete A B D","deleted 1");
	#A->B->C
	#A->D->E
	testCommand("perl $program_directory/dag.pl -d test insert A D E","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test query 'A->*->\$c'","c","C","E");
	testCommand("perl $program_directory/dag.pl -d test query 'A->*->(\$c)'","c","C E");
	testCommand("perl $program_directory/dag.pl -d test -f json query 'A->*->(\$c)'","[{\"c\":[\"C\",\"E\"]}]");
	testCommand("perl $program_directory/dag.pl -d test query '*->*->(\$c)'","c","C E");
	testCommand("perl $program_directory/dag.pl -d test -f json query '*->*->(\$c)'","[{\"c\":[\"C\",\"E\"]}]");
	#A->B->C
	#A->D->E
	#D->E->F
	testCommand("perl $program_directory/dag.pl -d test insert D E F","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test query 'A->*->\$c'","c","C","E");
	testCommand("perl $program_directory/dag.pl -d test -f json query 'A->*->\$c'","[{\"c\":\"C\"},{\"c\":\"E\"}]");
	testCommand("perl $program_directory/dag.pl -d test query 'A->*->(\$c)'","c","C E");
	testCommand("perl $program_directory/dag.pl -d test -f json query 'A->*->(\$c)'","[{\"c\":[\"C\",\"E\"]}]");
	testCommand("perl $program_directory/dag.pl -d test query '*->*->\$c'","c","C","E","F");
	testCommand("perl $program_directory/dag.pl -d test -f json query '*->*->\$c'","[{\"c\":\"C\"},{\"c\":\"E\"},{\"c\":\"F\"}]");
	testCommand("perl $program_directory/dag.pl -d test query '*->*->(\$c)'","c","C E F");
	testCommand("perl $program_directory/dag.pl -d test -f json query '*->*->(\$c)'","[{\"c\":[\"C\",\"E\",\"F\"]}]");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->*->*'","a","A","A","D");
	testCommand("perl $program_directory/dag.pl -d test query '(\$a)->*->*'","a","A D");
	testCommand("perl $program_directory/dag.pl -d test delete % % %","deleted 3");
	# when anchor is variable, results should be expanded
	testCommand("perl $program_directory/dag.pl -d test insert A B#C D","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test insert A B#E F","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test query '\$a->\$b#\$c->\$d'","a\tb\tc\td","A\tB\tC\tD","A\tB\tE\tF");
	testCommand("perl $program_directory/dag.pl -d test delete % %#% %","deleted 2");
	# count/min/max functionality
	testCommand("perl $program_directory/dag.pl -d test insert A B 3","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test query 'A->B->count(\$c)'","c","1");
	testCommand("perl $program_directory/dag.pl -d test insert A B 2","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test query 'A->B->count(\$c)'","c","2");
	testCommand("perl $program_directory/dag.pl -d test insert A B 1","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test query 'A->B->count(\$c)'","c","3");
	testCommand("perl $program_directory/dag.pl -d test query 'A->B->min(\$c)'","c","1");
	testCommand("perl $program_directory/dag.pl -d test query 'A->B->max(\$c)'","c","3");
	testCommand("perl $program_directory/dag.pl -d test -f json delete % % %","deleted 3");
	testCommand("perl $program_directory/dag.pl -d test insert A B '1,2,3,4,5'","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test query 'A->B->split(\",\",\$c)'","c","1 2 3 4 5");
	testCommand("perl $program_directory/dag.pl -d test query 'A->B->count(split(\",\",\$c))'","c","5");
	testCommand("perl $program_directory/dag.pl -d test query 'A->B->max(split(\",\",\$c))'","c","5");
	testCommand("perl $program_directory/dag.pl -d test query 'A->B->min(split(\",\",\$c))'","c","1");
	testCommand("perl $program_directory/dag.pl -d test query 'A->B->avg(split(\",\",\$c))'","c","3");
	testCommand("perl $program_directory/dag.pl -d test -f json delete % % %","deleted 1");
	#Testing sqlite3 db
	testCommand("perl $program_directory/dag.pl -d test insert A id2num 1","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test insert B id2num 2","inserted 1");
	testCommand("perl $program_directory/dag.pl -d test insert C id2num 3","inserted 1");
	testCommand("perl dag.pl -d test -f sqlite3 query '\$id->id2num->\$number'","create table if not exists \"root\"(id text,number integer);","insert into \"root\" values(\"A\",1);","insert into \"root\" values(\"B\",2);","insert into \"root\" values(\"C\",3);");
	testCommand("perl dag.pl -d test -f sqlite3:tb1 query '\$id->id2num->\$number'","create table if not exists \"tb1\"(id text,number integer);","insert into \"tb1\" values(\"A\",1);","insert into \"tb1\" values(\"B\",2);","insert into \"tb1\" values(\"C\",3);");
	testCommand("perl dag.pl -d test -f sqlite3:db:table query '\$id->id2num->\$number'","created 1");
	unlink("test/id2num.txt");
	testCommand("perl dag.pl -d test query '\$id->db?table=table#id:number->\$number'","id\tnumber","A\t1","B\t2","C\t3");
	testCommand("perl dag.pl -d test query '\$id->db?table=table#id:number->\$number'","id\tnumber","A\t1","B\t2","C\t3");
	unlink("test/db.db");
}
#Testing correlation functions
sub test6{
	#https://mathwords.net/syakudo
	#http://www.snap-tck.com/room04/c01/stat/stat05/stat0505.html
	#http://www.snap-tck.com/room04/c01/stat/stat05/stat0503.html
	#https://corvus-window.com/excel_cramers-v/
	testSubs("cramersvCorrelation([\"F\",\"M\",\"F\",\"F\",\"M\",\"F\",\"F\",\"F\",\"F\",\"F\",\"M\",\"F\",\"M\",\"F\",\"F\",\"M\",\"M\",\"M\",\"M\",\"F\",\"M\",\"F\",\"F\",\"F\",\"F\",\"M\",\"M\",\"F\",\"M\",\"M\",\"F\",\"F\",\"M\",\"F\",\"M\",\"M\",\"F\",\"F\",\"M\",\"F\",\"M\",\"F\",\"M\",\"M\",\"M\",\"M\",\"F\",\"F\",\"M\",\"M\",\"M\",\"M\",\"M\",\"M\",\"F\",\"M\",\"M\",\"F\",\"F\",\"M\",\"F\",\"M\",\"M\",\"F\",\"F\"],[\"N\",\"Y\",\"N\",\"N\",\"N\",\"Y\",\"N\",\"N\",\"N\",\"N\",\"Y\",\"N\",\"N\",\"N\",\"N\",\"N\",\"Y\",\"N\",\"N\",\"Y\",\"N\",\"N\",\"N\",\"Y\",\"N\",\"Y\",\"Y\",\"Y\",\"Y\",\"Y\",\"N\",\"N\",\"Y\",\"Y\",\"N\",\"Y\",\"N\",\"Y\",\"N\",\"Y\",\"N\",\"N\",\"Y\",\"N\",\"N\",\"Y\",\"N\",\"N\",\"N\",\"N\",\"Y\",\"Y\",\"Y\",\"Y\",\"N\",\"N\",\"N\",\"Y\",\"N\",\"Y\",\"N\",\"Y\",\"Y\",\"N\",\"N\"])","0.30",2.51);
	#https://www.scribbr.com/statistics/pearson-correlation-coefficient/
	testSub("pearsonsCorrelation([3.63,3.02,3.82,3.42,3.59,2.87,3.03,3.46,3.36,3.3],[53.1,49.7,48.4,54.2,54.9,43.7,47.2,45.2,54.4,50.4])",0.47);
	testSubs("pearsonsCorrelation([3.63,3.02,3.82,3.42,3.59,2.87,3.03,3.46,3.36,3.3],[53.1,49.7,48.4,54.2,54.9,43.7,47.2,45.2,54.4,50.4])",0.47,1.51);
	#https://www.questionpro.com/blog/ja/スピアマンの相関係数/
	testSub("spearmansRankCorrelation([3,5,1,6,7,2,8,9,4],[5,3,2,6,8,1,7,9,4])","0.90");
	testSubs("spearmansRankCorrelation([3,5,1,6,7,2,8,9,4],[5,3,2,6,8,1,7,9,4])","0.90",5.46);
	#https://en.wikipedia.org/wiki/Spearman%27s_rank_correlation_coefficient#Determining_significance
	testSub("spearmansRankCorrelation([106,100,86,101,99,103,97,113,112,110],[7,27,2,50,28,29,20,12,6,17],1)",-0.18);
	testSubs("spearmansRankCorrelation([106,100,86,101,99,103,97,113,112,110],[7,27,2,50,28,29,20,12,6,17],1)",-0.18,"-0.50");
	#https://corvus-window.com/all_spearmans-rank-correlation/
	testSub("spearmansRankCorrelation([4,5,3,3,1,2,5,2,1,1],[3,5,2,3,1,1,4,3,2,1],1)",0.85);
	testSubs("spearmansRankCorrelation([4,5,3,3,1,2,5,2,1,1],[3,5,2,3,1,1,4,3,2,1],1)",0.85,4.59);
	testSub("spearmansRankCorrelation([3430,2920,3285,2690,3260,3877,2835,1440,2030],[38.5,38.3,40.9,37.3,40.3,42.4,40.1,29.3,36.0],1)",0.87);
	#https://corvus-window.com/all_kruskal-wallis-test/
	testSub("kruskalWallisCorrelation([20,20,20,20,20,30,30,30,30,40,40,40,50,50,50,50],[2,3,2,1,1,1,2,3,2,4,4,2,4,5,5,4],1)",10.08);
	#https://corvus-window.com/all_kendalls-tau/
	#testSub("kendallRankCorrelation([4,5,3,3,1,2,5,2,1,1],[3,5,2,3,1,1,4,3,2,1],1)",0.85);
}
sub test7{
	# Test insert/delete/update process
	createFile("test/insert.txt","insert\tA->B->C");
	testCommand("perl $program_directory/dag.pl -d test/db process < test/insert.txt","inserted 1");
	unlink("test/insert.txt");
	testCommand("cat test/db/B.txt","A\tC");
	createFile("test/delete.txt","delete\tA->B->C");
	testCommand("perl $program_directory/dag.pl -d test/db process < test/delete.txt","deleted 1");
	unlink("test/delete.txt");
	if(-e "test/db/B.txt"){print STDERR "test/db/B.txt shouldn't exist";}
	createFile("test/update.txt","update\tA->B->C","update\tD->B->E");
	testCommand("perl $program_directory/dag.pl -d test/db process < test/update.txt","updated 2");
	unlink("test/update.txt");
	testCommand("cat test/db/B.txt","A\tC","D\tE");
	createFile("test/update2.txt","update\tA->B->F","update\tG->B->H");
	testCommand("perl $program_directory/dag.pl -d test/db process < test/update2.txt","updated 2");
	unlink("test/update2.txt");
	testCommand("cat test/db/B.txt","A\tF","D\tE","G\tH");
	unlink("test/db/B.txt");
	system("rmdir test/db");
	# Test insert/delete/update process with anchor
	createFile("test/insert.txt","insert\tA->B#C->D");
	testCommand("perl $program_directory/dag.pl -d test/db process < test/insert.txt","inserted 1");
	unlink("test/insert.txt");
	testCommand("cat test/db/B.txt","A\tC\tD");
	createFile("test/delete.txt","delete\tA->B#C->D");
	testCommand("perl $program_directory/dag.pl -d test/db process < test/delete.txt","deleted 1");
	unlink("test/delete.txt");
	if(-e "test/db/B.txt"){print STDERR "test/db/B.txt shouldn't exist";}
	createFile("test/update.txt","update\tA->B#C->D","update\tE->B#F->G");
	testCommand("perl $program_directory/dag.pl -d test/db process < test/update.txt","updated 2");
	unlink("test/update.txt");
	testCommand("cat test/db/B.txt","A\tC\tD","E\tF\tG");
	createFile("test/update.txt","update\tA->B#C->H","update\tE->B#I->J");
	testCommand("perl $program_directory/dag.pl -d test/db process < test/update.txt","updated 2");
	unlink("test/update.txt");
	testCommand("cat test/db/B.txt","A\tC\tH","E\tF\tG","E\tI\tJ");
	unlink("test/db/B.txt");
	# Test insert/delete/update process with anchor
	createFile("test/insert.txt","insert\tA->B#C->D","insert\tE->F->G","insert\tH->I->J");
	testCommand("perl $program_directory/dag.pl -d test/db process < test/insert.txt","inserted 3");
	unlink("test/insert.txt");
	testCommand("cat test/db/B.txt","A\tC\tD");
	testCommand("cat test/db/F.txt","E\tG");
	testCommand("cat test/db/I.txt","H\tJ");
	createFile("test/update.txt","update\tA->B#K->L","update\tA->F->B","update\tH->I#A->O");
	testCommand("perl $program_directory/dag.pl -d test/db process < test/update.txt","updated 3");
	unlink("test/update.txt");
	testCommand("cat test/db/B.txt","A\tC\tD","A\tK\tL");
	testCommand("cat test/db/F.txt","A\tB","E\tG");
	testCommand("cat test/db/I.txt","H\tA\tO","H\tJ");
	createFile("test/update.txt","update\tA->B#K->P","update\tA->F->Q","update\tH->I#A->R","update\tH->I->A");
	testCommand("perl $program_directory/dag.pl -d test/db process < test/update.txt","updated 4");
	unlink("test/update.txt");
	testCommand("cat test/db/B.txt","A\tC\tD","A\tK\tP");
	testCommand("cat test/db/F.txt","A\tQ","E\tG");
	testCommand("cat test/db/I.txt","H\tA","H\tA\tR");
	unlink("test/db/B.txt");
	unlink("test/db/F.txt");
	unlink("test/db/I.txt");
	system("rmdir test/db");
}
############################## testCommand ##############################
sub testCommand{
	my @values=@_;
	my $command=shift(@values);
	my $value2=join("\n",@values);
	my ($writer,$file)=tempfile(UNLINK=>1);
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
############################## testSubs ##############################
sub testSubs{
	my @value2=@_;
	my $command=shift(@value2);
	my @value1=eval($command);
	if(equals(\@value1,\@value2)){return 0;}
	print STDERR ">$command\n";
	printTable(\@value1);
	printTable(\@value2);
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
		if($label=~/^.+\.\w{2,4}$/){$node->{"shape"}="box";}
	}
	return (\@nodes,\@edges);
}
############################## totalLabeledTable ##############################
sub totalLabeledTable{
	my $hashtable=shift();
	my $total=0;
	my $rowTotals=[];
	my $colTotals=[];
	my $rowSize=$hashtable->{"rowSize"};
	my $colSize=$hashtable->{"colSize"};
	my $tables=$hashtable->{"tables"};
	my $rowTotals=[];
	my $colTotals=[];
	my $total=0;
	for(my $i=0;$i<$rowSize;$i++){$rowTotals->[$i];}
	for(my $j=0;$j<$colSize;$j++){$colTotals->[$j];}
	for(my $i=0;$i<$rowSize;$i++){
		for(my $j=0;$j<$colSize;$j++){
			my $count=$tables->[$i]->[$j];
			$rowTotals->[$i]+=$count;
			$colTotals->[$j]+=$count;
			$total+=$count;
		}
	}
	$hashtable->{"rowTotals"}=$rowTotals;
	$hashtable->{"colTotals"}=$colTotals;
	$hashtable->{"total"}=$total;
	return $hashtable;
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
############################## tripleTohash ##############################
sub tripleTohash{
	my $hash=shift();
	my $sub=shift();
	my $pre=shift();
	my $obj=shift();
	if(!defined($sub)||!defined($pre)||!defined($obj)){return;}
	if(!exists($hash->{$sub})){$hash->{$sub}={};}
	if(!exists($hash->{$sub}->{$pre})){$hash->{$sub}->{$pre}=$obj;}
	elsif(ref($hash->{$sub}->{$pre})eq"ARRAY"){push(@{$hash->{$sub}->{$pre}},$obj);}
	else{$hash->{$sub}->{$pre}=[$hash->{$sub}->{$pre},$obj];}
}
############################## tripleTohashUniq ##############################
sub tripleTohashUniq{
	my $hash=shift();
	my $sub=shift();
	my $pre=shift();
	my $obj=shift();
	if(!defined($sub)||!defined($pre)||!defined($obj)){return;}
	if(!exists($hash->{$sub})){$hash->{$sub}={};}
	$hash->{$sub}->{$pre}=$obj;
}
############################## tsvToJson ##############################
sub tsvToJson{
	my $reader=shift();
	my $json={};
	my $linecount=0;
	while(<$reader>){
		chomp;
		s/\r//g;
		my ($subject,$predicate,$object)=split(/\t|\-\>/);
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
############################## updateTsv ##############################
sub updateTsv{
	my $predicate=shift();
	my $tempfile=shift();
	my $writer=shift();
	close($writer);
	my $file=getFileFromPredicate($predicate);
	if($file=~/\.gz$/){return;}
	elsif($file=~/\.bz2$/){return;}
	elsif(-d $file){return;}
	my $hash=readTsvToKeyValHash($file);#original
	my $hash2=readTsvToKeyValHash($tempfile);#updates
	my $count=0;
	while(my($key,$val)=each(%{$hash2})){
		$hash->{$key}=$val;
		$count++;
	}
	writeKeyValHash($file,$hash);
	return $count;
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
############################## writeKeyValHash ##############################
sub writeKeyValHash{
	my $output=shift();
	my $hash=shift();
	my ($writer,$tempfile)=tempfile(UNLINK=>1);
	my $count=0;
	while(my($key,$val)=each(%{$hash})){foreach my $v(@{$val}){print $writer "$key\t$v\n";$count++;}}
	close($writer);
	if($count==0){unlink($output);return;}
	my $sortfile=sortFile($tempfile);
	unlink($tempfile);
	mkdirs(dirname($output));
	system("mv $sortfile $output");
}
