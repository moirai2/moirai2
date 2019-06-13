#!/usr/bin/perl
use strict 'vars';
use Cwd;
use File::Basename;
use File::Temp qw/tempfile tempdir/;
use FileHandle;
use Getopt::Std;
use DBI;
use File::Path;
use LWP::UserAgent;
use HTTP::Request::Common;
use Time::HiRes;
use Time::Local;
use Time::localtime;
############################## HEADER ##############################
my($program_name,$program_directory,$program_suffix)=fileparse($0);
$program_directory=substr($program_directory,0,-1);
# require "$program_directory/Utility.pl";
############################## OPTIONS ##############################
use vars qw($opt_d $opt_D $opt_e $opt_f $opt_g $opt_h $opt_H $opt_l $opt_q $opt_r $opt_t $opt_w);
getopts('d:D:e:f:g:hHl:qr:tw:');
############################## URLs ##############################
my $urls={};
$urls->{"daemon"}="https://moirai2.github.io/schema/daemon";
$urls->{"daemon/command"}="https://moirai2.github.io/schema/daemon/command";
$urls->{"daemon/execute"}="https://moirai2.github.io/schema/daemon/execute";
$urls->{"daemon/execid"}="https://moirai2.github.io/schema/daemon/execid";
$urls->{"daemon/timestarted"}="https://moirai2.github.io/schema/daemon/timestarted";
$urls->{"daemon/timeended"}="https://moirai2.github.io/schema/daemon/timeended";

$urls->{"file"}="https://moirai2.github.io/schema/file";
$urls->{"file/md5"}="https://moirai2.github.io/schema/file/md5";
$urls->{"file/filesize"}="https://moirai2.github.io/schema/file/filesize";
$urls->{"file/linecount"}="https://moirai2.github.io/schema/file/linecount";
$urls->{"file/seqcount"}="https://moirai2.github.io/schema/file/seqcount";

$urls->{"software"}="https://moirai2.github.io/schema/software";
$urls->{"software/bin"}="https://moirai2.github.io/schema/software/bin";
$urls->{"software/version"}="https://moirai2.github.io/schema/software/version";

$urls->{"system"}="https://moirai2.github.io/schema/system";
$urls->{"system/download"}="https://moirai2.github.io/schema/system/download";

$urls->{"miniconda3"}="https://moirai2.github.io/software/miniconda3";
$urls->{"miniconda3/bin"}="https://moirai2.github.io/software/miniconda3/bin";

############################## HELP ##############################
sub help{
	print "PROGRAM: $program_name\n";
	print "  USAGE: Utilities for handling a RDF sqlite3 database.\n";
	print "COMMAND: $program_name -d DB select SUB PRE OBJ\n";
	print "COMMAND: $program_name -d DB insert SUB PRE OBJ\n";
	print "COMMAND: $program_name -d DB update SUB PRE OBJ\n";
	print "COMMAND: $program_name -d DB delete SUB PRE OBJ\n";
	print "COMMAND: $program_name -d DB object SUB PRE OBJ\n";
	print "COMMAND: $program_name -d DB import < TSV\n";
	print "COMMAND: $program_name -d DB dump > TSV\n";
	print "COMMAND: $program_name -d DB -f json dump > JSON\n";
	print "COMMAND: $program_name -d DB query QUERY > JSON\n";
	print "COMMAND: $program_name -d DB replace FROM TO\n";
	print "COMMAND: $program_name -d DB mv FROM TO\n";
	print "COMMAND: $program_name -d DB newnode > NODE\n";
	print "COMMAND: $program_name -d DB reindex\n";
	print "COMMAND: $program_name -d DB download URL\n";
	print "COMMAND: $program_name -d DB software URL\n";
	print "COMMAND: $program_name -d DB -f json command < JSON\n";
	print "COMMAND: $program_name -d DB merge DB2 DB3\n";
	print "COMMAND: $program_name -d DB conda\n";
	print "COMMAND: $program_name -d DB ls < STDIN\n";
	print "\n";
	print "COMMAND: $program_name linecount DIR/FILE > TSV\n";
	print "COMMAND: $program_name seqcount DIR/FILE > TSV\n";
	print "COMMAND: $program_name md5 DIR/FILE > TSV\n";
	print "COMMAND: $program_name ls DIR/FILE > TSV\n";
	print "\n";
	print "   NOTE:  Use '?' for undefined subject/predicate/object.\n";
	print "   NOTE:  Need to specify database for most manipulations.\n";
	print "\n";
	print " AUTHOR: Akira Hasegawa\n";
	if(defined($opt_H)){
		print "UPDATED: 2019/06/04  Added 'executes' and 'html' to retrieve execute log informations.\n";
		print "         2019/05/07  Added 'md5' to calculate md5 of files.\n";
		print "         2019/04/26  Changed name from 'sqlite3.pl' to 'rdf.pl'.\n";
		print "         2019/03/13  'linecount' and 'seqcount' added to count files.\n";
		print "         2019/01/28  Insert and query RDF through PHP with HTTP POST added.\n";
		print "         2019/01/16  Remove 'empty' was added to remove empty node and edges.\n";
		print "         2019/01/10  'rmdup' was added to remove duplicated edges.\n";
		print "         2019/01/09  'copy' was added to divide database into two.\n";
		print "         2019/01/08  'merge' was added to combine two database into one.\n";
		print "         2018/12/25  'replace' and 'rename' was added to change node values for 'mv' command.\n";
		print "         2018/11/27  'reindex' was added to reindex node ids after removing controls.\n";
		print "         2018/11/27  Remove 'execute','control', and 'log' were added.\n";
		print "         2018/11/19  insert/update/delete with tsv/json format were added.\n";
		print "         2018/11/08  Made import faster by storing nodes and edges data in perl hashtables.\n";
		print "         2018/11/07  Added assemble expression codes.\n";
		print "         2018/11/06  Speed up recursion of select method.\n";
		print "         2018/10/30  Modified import to handle multiple cases.\n";
		print "         2018/08/03  parseQuery() added for handing RDF query.\n";
		print "         2018/02/24  'import' function was added to import TSV into database.\n";
		print "         2018/02/15  Modified insert to accept object from STDIN.\n";
		print "         2018/01/30  Created this to handle RDF SQLite database from bash script.\n";
	}
}
############################## test ##############################
sub test{
	mkdir(test);
	unlink("test/rdf.sqlite3");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 insert A B C","inserted 1");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 select","A\tB\tC");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 insert D E F","inserted 1");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 select","A\tB\tC\nD\tE\tF");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 select A","A\tB\tC");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 select ? E","D\tE\tF");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 select ? ? C","A\tB\tC");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 delete A B C","deleted 1");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 select","D\tE\tF");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 -f json select","{\"D\":{\"E\":\"F\"}}");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 -f '[0]-[1]-[2]' select","D-E-F");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 insert D G H","inserted 1");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 -f tsv select","D	E	F\nD	G	H");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 -f json select","{\"D\":{\"E\":\"F\",\"G\":\"H\"}}");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 delete ? ? H","deleted 1");
	testCommand("echo 'D\tE\tF'|perl rdf.pl -d test/rdf.sqlite3 -f tsv delete","deleted 1");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 newnode","test/rdf.sqlite3#node1");
	testCommand("echo '' > test/test.txt","");
	testCommand("perl rdf.pl md5 test/test.txt","test/test.txt	".$urls->{"file/md5"}."	d41d8cd98f00b204e9800998ecf8427e");
	testCommand("perl rdf.pl linecount test/test.txt","test/test.txt	".$urls->{"file/linecount"}."	0");
	testCommand("perl rdf.pl seqcount test/test.txt","test/test.txt	".$urls->{"file/seqcount"}."	0");
	testCommand("echo '{\"A\":{\"B\":\"C\"}}'|perl rdf.pl -d test/rdf.sqlite3 -f json insert ","inserted 1");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 replace C D","replaced 1");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 replace C D","replaced 0");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 replace D E","replaced 1");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 dump","A	B	E");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 mv test/test.txt test/test3.txt","replaced 0");
	testCommand("perl rdf.pl md5 test/test.txt | perl rdf.pl -d test/rdf.sqlite3 import","imported 1");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 mv test/test.txt test/test2.txt","replaced 1");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 delete ? ".$urls->{"file/md5"}." ?","deleted 1");
	testCommand("echo \"A\tB\tB\nA\tB\tC\nA\tC\tD\" | perl rdf.pl -d test/rdf.sqlite3 -f tsv insert","inserted 3");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 object","(B C D E)");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 object A","(B C D E)");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 object A B","(B C E)");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 object A B C","C");
	testCommand("perl rdf.pl -d test/rdf.sqlite3 object A C","D");
	unlink("test/test2.txt");
	unlink("test/rdf.sqlite3");
	rmdir("test");
}
############################## MAIN ##############################
my $database=$opt_d;
if(!defined($database)){$database="rdf.sqlite3";}
my $iswebdb=($database=~/^https?:\/\//)?1:0;
my $command=shift(@ARGV);
if(defined($opt_h)||defined($opt_H)||!defined($command)){
	help();
	exit(0);
}elsif($command eq "test"){
	test();
	exit(0);
}elsif($command eq "linecount"){
	my @files=();
	if(scalar(@ARGV)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@ARGV;}
	if(defined($opt_d)){
		my ($writer,$file)=tempfile(UNLINK=>1);
		countLines($writer,$opt_r,$opt_g,@files);
		close($writer);
		my $reader=IO::File->new($file);
		my $linecount=importDB($database,$reader);
		close($reader);
	}else{
		my $writer=IO::File->new(">&STDOUT");
		countLines($writer,$opt_r,$opt_g,@files);
		close($writer);
	}
	exit(0);
}elsif($command eq "seqcount"){
	my @files=();
	if(scalar(@ARGV)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@ARGV;}
	if(defined($opt_d)){
		my ($writer,$file)=tempfile(UNLINK=>1);
		countSequences($writer,$opt_r,$opt_g,@files);
		close($writer);
		my $reader=IO::File->new($file);
		my $linecount=importDB($database,$reader);
		close($reader);
	}else{
		my $writer=IO::File->new(">&STDOUT");
		countSequences($writer,$opt_r,$opt_g,@files);
		close($writer);
	}
	exit(0);
}elsif($command eq "filesize"){
	my @files=();
	if(scalar(@ARGV)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@ARGV;}
	if(defined($opt_d)){
		my ($writer,$file)=tempfile(UNLINK=>1);
		sizeFiles($writer,$opt_r,$opt_g,@files);
		close($writer);
		my $reader=IO::File->new($file);
		my $linecount=importDB($database,$reader);
		close($reader);
	}else{
		my $writer=IO::File->new(">&STDOUT");
		sizeFiles($writer,$opt_r,$opt_g,@files);
		close($writer);
	}
	exit(0);
}elsif($command eq "md5"){
	my @files=();
	if(scalar(@ARGV)==0){while(<STDIN>){chomp;push(@files,$_);}}
	else{@files=@ARGV;}
	if(defined($opt_d)){
		my ($writer,$file)=tempfile(UNLINK=>1);
		md5Files($writer,$opt_r,$opt_g,@files);
		close($writer);
		my $reader=IO::File->new($file);
		my $linecount=importDB($database,$reader);
		close($reader);
	}else{
		my $writer=IO::File->new(">&STDOUT");
		md5Files($writer,$opt_r,$opt_g,@files);
		close($writer);
	}
	exit(0);
}elsif(lc($command) eq "select"){
	my $subject=shift(@ARGV);
	my $predicate=shift(@ARGV);
	my $object=shift(@ARGV);
	if($subject eq "?"){$subject=undef;}
	if($predicate eq "?"){$predicate=undef;}
	if($object eq "?"){$object=undef;}
	my $json={$subject=>{$predicate=>$object}};
	my $rdf=($iswebdb)?webSelect($database,$json):dbSelect($database,$subject,$predicate,$object);
	my $format=defined($opt_f)?$opt_f:"tsv";
	my $writer=IO::File->new(">&STDOUT");
	if($format eq "tsv"){outputInColumnFormat($rdf,$writer);}
	elsif($format eq "json"){outputInJsonFormat($rdf,$writer);}
	else{outputInAssembleFormat($rdf,$format,$writer);}
	close($writer);
}elsif(lc($command) eq "object"){
	my $subject=shift(@ARGV);
	my $predicate=shift(@ARGV);
	my $object=shift(@ARGV);
	if($subject eq "?"){$subject=undef;}
	if($predicate eq "?"){$predicate=undef;}
	if($object eq "?"){$object=undef;}
	my $json={$subject=>{$predicate=>$object}};
	my $rdf=($iswebdb)?webSelect($database,$json):dbSelect($database,$subject,$predicate,$object);
	my @objects=();
	foreach my $subject(keys(%{$rdf})){
		foreach my $predicate(keys(%{$rdf->{$subject}})){
			my $object=$rdf->{$subject}->{$predicate};
			if(ref($object)eq"ARRAY"){foreach my $o(@{$object}){push(@objects,$o);}}
			else{push(@objects,$object);}
		}
	}
	if(scalar(@objects)==1){print $objects[0]."\n";}
	else{
		@objects=sort{$a cmp $b}@objects;
		print "(".join(" ",@objects).")\n";
	}
}elsif(lc($command) eq "insert"){
	if(!defined($opt_f)){
		my $subject=shift(@ARGV);
		my $predicate=shift(@ARGV);
		my $object=shift(@ARGV);
		if($subject eq "?"){$subject=undef;}
		if($predicate eq "?"){$predicate=undef;}
		if($object eq "?"){$object=undef;}
		if(!defined($subject)){exit(1);}
		if(!defined($predicate)){exit(1);}
		if(!defined($object)){$object="";while(<STDIN>){$object.=$_;}chomp($object);}
		my $json={$subject=>{$predicate=>$object}};
		my $linecount=($iswebdb)?webInsert($database,$json):dbInsert($database,$subject,$predicate,$object);
		if(!$opt_q){print "inserted $linecount\n";}
	}elsif($opt_f eq "tsv"){
		my $reader=IO::File->new("-");
		my $linecount=($iswebdb)?webInsert($database,readJson($reader)):importDB($database,$reader);
		close($reader);
		if(!$opt_q){print "inserted $linecount\n";}
	}elsif($opt_f eq "json"){
		my $reader=IO::File->new("-");
		my $json=readJson($reader);
		close($reader);
		my $linecount=($iswebdb)?webInsert($database,$json):jsonInsert($database,$json);
		if(!$opt_q){print "inserted $linecount\n";}
	}else{
		my $reader=IO::File->new("-");
		my $file=($opt_f=~/\-\>/)?assembleJson($reader,$opt_f):assembleFile($reader,$opt_f);
		close($reader);
		$reader=IO::File->new($file);
		if(defined($opt_t)){while(<$reader>){print;};exit(0);}
		my $linecount=importDB($database,$reader);
		close($reader);
		if(!$opt_q){print "inserted $linecount\n";}
	}
}elsif(lc($command) eq "import"){
	my $reader=IO::File->new("-");
	my $linecount=importDB($database,$reader);
	close($reader);
	if(!$opt_q){print "imported $linecount\n";}
}elsif(lc($command) eq "query"){
	my @queries=@ARGV;
	if(scalar(@queries)==0){while(<STDIN>){chomp;push(@queries,$_);}}
	my $results=[];
	while(1){
		if($iswebdb){$results=webQuery($database,{"query"=>join(",",@queries)});}
		else{my $dbh=openDB($database);$results=getResults($dbh,parseQuery(join(",",@queries)));$dbh->disconnect;}
		if(!defined($opt_w)){last;}
		elsif(scalar(@{$results})>0){last;}
		else{sleep($opt_w);}
	}
	if(!defined($opt_f)){my $writer=IO::File->new(">&STDOUT");printQueryResults($results,$writer);close($writer);}
	elsif($opt_f eq "json"){
		my ($writer,$file)=tempfile(UNLINK=>1);
		assembleJsonResults($results,join(",",@queries),$writer);
		close($writer);
		my $reader=IO::File->new($file);
		my $rdf=tsvToJson($reader);
		close($reader);
		$writer=IO::File->new(">&STDOUT");
		outputInJsonFormat($rdf,$writer);
		close($writer);
	}elsif($opt_f eq "tsv"){outputQueryResults($results);}
	else{my $writer=IO::File->new(">&STDOUT");assembleJsonResults($results,$opt_f,$writer);close($writer);}
}elsif(lc($command) eq "dump"){
	my $writer=IO::File->new(">&STDOUT");
	dumpDB($database,$opt_f,$writer);
	close($writer);
}elsif(lc($command) eq "reindex"){
	my ($fh,$filename)=tempfile;
	dumpDB($database,"tsv",$fh);
	close($fh);
	my $newdatabase="$database.tmp";
	my $reader=IO::File->new($filename);
	my $linecount=importDB($newdatabase,$reader);
	close($reader);
	unlink($filename);
	rename("$database.tmp",$database);
	if(!$opt_q){print "reindexed $linecount\n";}
}elsif(lc($command) eq "update"){
	if(!defined($opt_f)){
		my $subject=shift(@ARGV);
		my $predicate=shift(@ARGV);
		my $object=shift(@ARGV);
		if($subject eq "?"){$subject=undef;}
		if($predicate eq "?"){$predicate=undef;}
		if($object eq "?"){$object=undef;}
		if($iswebdb){webUpdate($database,{$subject=>{$predicate=>$object}});}
		else{dbUpdate($database,$subject,$predicate,$object);}
	}elsif($opt_f eq "tsv"){
		my $reader=IO::File->new("-");
		my ($json,$linecount)=tsvToJson($reader);
		close($reader);
		if($iswebdb){webUpdate($database,$json);}
		else{jsonUpdate($database,$json);}
		if(!$opt_q){print "updated $linecount\n";}
	}elsif($opt_f eq "json"){
		my $reader=IO::File->new("-");
		my $json=readJson($reader);
		close($reader);
		if($iswebdb){webUpdate($database,$json);}
		else{jsonUpdate($database,$json);}
	}else{
		my $reader=IO::File->new("-");
		my $file=($opt_f=~/\-\>/)?assembleJson($reader,$opt_f):assembleFile($reader,$opt_f);
		close($reader);
		if(defined($opt_t)){
			my $reader=IO::File->new($file);
			while(<$reader>){print;}
			close($reader);
		}else{
			my $reader=IO::File->new($file);
			my ($json,$linecount)=tsvToJson($reader);
			close($reader);
			if($iswebdb){webUpdate($database,$json);}
			else{jsonUpdate($database,$json);}
		}
	}
}elsif(lc($command) eq "delete"){
	if(!defined($opt_f)){
		my $subject=shift(@ARGV);
		my $predicate=shift(@ARGV);
		my $object=shift(@ARGV);
		if($subject eq "?"){$subject=undef;}
		if($predicate eq "?"){$predicate=undef;}
		if($object eq "?"){$object=undef;}
		my $linecount=dbDelete($database,$subject,$predicate,$object);
		if(!$opt_q){print "deleted $linecount\n";}
	}elsif($opt_f eq "tsv"){
		if($iswebdb){
			my $reader=IO::File->new("-");
			webDelete($database,readJson($reader));
			close($reader);
		}else{
			my $dbh=openDB($database);
			my $reader=IO::File->new("-");
			my $linecount=deleteTSV($dbh,$database,$reader);
			close($reader);
			$dbh->disconnect;
			if(!$opt_q){print "deleted $linecount\n";}
		}
	}elsif($opt_f eq "json"){
		my $reader=IO::File->new("-");
		my $json=readJson($reader);
		close($reader);
		my $dbh=openDB($database);
		$dbh->begin_work;
		my $linecount=deleteRDF($dbh,$json);
		$dbh->commit;
		$dbh->disconnect;
	}else{
		my $reader=IO::File->new("-");
		my $file=($opt_f=~/\-\>/)?assembleJson($reader,$opt_f):assembleFile($reader,$opt_f);
		close($reader);
		if(defined($opt_t)){
			my $reader=IO::File->new($file);
			while(<$reader>){print;}
			close($reader);
		}else{
			my $reader=IO::File->new($file);
			my ($json,$linecount)=tsvToJson($reader);
			close($reader);
			my $dbh=openDB($database);
			$dbh->begin_work;
			my $linecount=deleteRDF($dbh,$json);
			$dbh->commit;
			$dbh->disconnect;
		}
	}
}elsif(lc($command) eq "replace"){
	if($opt_f eq "tsv"){
		my $dbh=openDB($database);
		my $reader=IO::File->new("-");
		my $linecount=replaceTSV($dbh,$database,$reader);
		close($reader);
		$dbh->disconnect;
		if(!$opt_q){print "replaced $linecount\n";}
	}else{
		my $from=shift(@ARGV);
		my $to=shift(@ARGV);
		my $linecount=dbReplace($database,$from,$to);
		if(!$opt_q){print "replaced $linecount\n";}
	}
}elsif(lc($command) eq "mv"){
	if($opt_f eq "tsv"){
		my $dbh=openDB($database);
		my $reader=IO::File->new("-");
		my $linecount=replaceTSV($dbh,$database,$reader,1);
		close($reader);
		$dbh->disconnect;
		if(!$opt_q){print "renamed $linecount\n";}
	}else{
		my @froms=@ARGV;
		if(scalar(@froms<2)){
			print STDERR "ERROR Need to specify at least two arguments.\n";
			print STDERR "perl rdf.pl mv SOURCE TARGET\n";
			exit(1);
		}
		my $to=pop(@froms);
		if($to=~/^(.+)\/\.$/){$to=$1;}
		elsif($to=~/^(.+)\/$/){$to=$1;}
		elsif($to=~/^\.$/){$to="";}
		my $linecount=0;
		if(-d $to){
			if($to ne ""){$to="$to/";}
			foreach my $from(@froms){$linecount+=dbReplace($database,$from,$to.basename($from),1);}
		}elsif(scalar(@froms)>1){
			print STDERR "ERROR multiple files were specified and target wasn't a directory.";
			print STDERR "perl rdf.pl mv SOURCE SOURCE SOURCE DIRECTORY\n";
			exit(1);
		}else{
			$linecount=dbReplace($database,$froms[0],$to,1);
		}
		if(!$opt_q){print "replaced $linecount\n";}
	}
}elsif(lc($command) eq "merge"){
	my ($writer,$file)=tempfile(UNLINK=>1);
	foreach my $database(@ARGV){
		my $dbh=openDB($database);
		dumpDB($dbh,"tsv",$writer);
		$dbh->disconnect;
	}
	close($writer);
	my $reader=IO::File->new($file);
	my $linecount=importDB($database,$reader);
	close($reader);
	if(!$opt_q){print "insert $linecount\n";}
}elsif(lc($command) eq "copy"){
	my $dbh=openDB($database);
	my ($writer,$file)=tempfile(UNLINK=>1);
	my @queries=();
	foreach my $query(@ARGV){push(@queries,split(/,/,$query));}
	queryTotsv($writer,\@queries,getResults($dbh,parseQuery(\@queries)));
	close($writer);
	$dbh->disconnect;
	$database=$opt_D;
	my $reader=IO::File->new($file);
	my $linecount=importDB($database,$reader);
	close($reader);
	if(!$opt_q){print "copied $linecount\n";}
}elsif(lc($command) eq "newnode"){
	print newNode($database)."\n";
}elsif(lc($command) eq "command"){
	my $reader=IO::File->new("-");
	my $json=readJson($reader);
	close($reader);
	print executeComand($database,$json)."\n";
}elsif(lc($command) eq "download"){
	registerDownloads($database,@ARGV);
	my @files=downloadFiles($database);
	if(scalar(@files)>1){print "(".join(" ",@files).")\n";}
	else{print $files[0]."\n";}
}elsif(lc($command) eq "executes"){
	my $hashtable=retrieveExecutes($database);
	printExecutesInJson($hashtable);
}elsif(lc($command) eq "html"){
	my $hashtable=retrieveExecutes($database);
	printExecutesInHTML($hashtable);
}elsif(lc($command) eq "conda"){
	whichConda($database);
}elsif(lc($command) eq "software"){
	whichSoftware($database,@ARGV);
}elsif(lc($command) eq "ls"){
	ls($database,$opt_f,$opt_g,$opt_r,@ARGV);
}
############################## basenames ##############################
sub basenames{
	my $file=$_[0];
	my @out=();
	if($file=~/^(.+)\/([^\/]+)$/){
		$out[0]=$1;
		$out[1]=$2;
	}elsif($file =~/^(.*)\/$/){
		$out[0]=$1;
		$out[1]="";
	}else{
		$out[0]="";
		$out[1]=$file;
	}
	if($out[1]=~/^(.+)\.([^\.]+)$/){
		$out[2]=$1;
		$out[3]=$2;
	}else{
		$out[2]=$out[1];
		$out[3]="";
	}
	return wantarray?@out:$out[1];
}
############################## ls ##############################
sub ls{
	my @files=@_;
	my $database=shift(@files);
	my $format=shift(@files);
	my $filegrep=shift(@files);
	my $recursive=shift(@files);
	if(scalar(@files)==0){push(@files,".");}
	if(defined($format)){
		foreach my $path(listFiles($filegrep,$recursive,@files)){
			my @outputs=basenames($path);
			print_table(\@outputs);
		}
	}else{
		foreach my $path(listFiles($filegrep,$recursive,@files)){
			print "$path\n";
		}
	}
}
############################## whichConda ##############################
sub whichConda{
	my $database=shift();
	my $hash=dbSelect($database,undef,$urls->{"software/bin"},undef);
	my $condabin=`which conda`;
	chomp($condabin);
	if($condabin eq ""){return;}
	my $condadir=dirname(dirname($condabin));
	my $json={$urls->{"miniconda3"}=>{$urls->{"miniconda3/bin"}=>$condabin}};
	my $dbh=openDB($database);
	$dbh->begin_work;
	my $linecount=insertRDF($dbh,$json);
	$dbh->commit;
	$dbh->disconnect;
	print "$condabin\n";
}
############################## printExecutesInHTML ##############################
sub printExecutesInHTML{
	my $hashtable=shift();
	print "<html>\n";
	print "<head>\n";
	print "<style type=\"text/css\">h1{text-align:center}table{text-align:center;border-collapse:collapse;}th{border: 1px solid black}td{border: 1px solid black}</style>";
	print "</head>\n";
	foreach my $url(sort{$a cmp $b}keys(%{$hashtable})){
		print "<table>\n";
		my $temp={};
		foreach my $node(@{$hashtable->{$url}}){
			foreach my $key(keys(%{$node})){
				if($key!~/^\$/){next;}
				$temp->{substr($key,1)}=1;
			}
		}
		my @keys=sort{$a cmp $b}keys(%{$temp});
		my $size=scalar(@keys)+3;
		print "<tr><th colspan=$size><a href=\"$url\">$url</a></th></tr>\n";
		if(scalar(@keys)>0){print "<tr><th>Start</th><th>End</th><th>Time</th><th>".join("</th><th>",@keys)."</th></tr>\n";}
		foreach my $node(@{$hashtable->{$url}}){
			my $start=$node->{$urls->{"daemon/timestarted"}};
			my $end=$node->{$urls->{"daemon/timeended"}};
			my $diff=$end-$start;
			my $startstring=getDate("/",$start)." ".getTime(":",$start);
			my $endstring=getDate("/",$end)." ".getTime(":",$end);
			my $line="<tr><td>$startstring</td><td>$endstring</td><td>$diff</td>";
			foreach my $key(@keys){
				my $value=$node->{"\$".$key};
				if(ref($value)eq"ARRAY"){
					$line.="<td>".join("<br>",@{$value})."</td>"
				}
				else{
					if(-e $value){$line.="<td><a href=\"$value\">$value</a></td>";}
						else{$line.="<td>$value</td>";}
				}
			}
			$line.="</tr>";
			print "$line\n";
		}
		print "</table>\n";
	}
	print "</html>\n";
}
############################## printExecutesInJson ##############################
sub printExecutesInJson{
	my $hashtable=shift();
	print "{";
	my $urlindex=0;
	foreach my $url(keys(%{$hashtable})){
		my @datas=();
		foreach my $node(@{$hashtable->{$url}}){
			my @values=();
			foreach my $key(keys(%{$node})){
				my $line="\"$key\":";
				my $value=$node->{$key};
				if(ref($value)eq"ARRAY"){$line.="[\"".join("\",\"",@{$value})."\"]";}
				else{$line.="\"$value\"";}
				push(@values,$line);
			}
			push(@datas,"{".join(",",@values)."}");
		}
		if($urlindex>0){print ",";}
		print "\"$url\":";
		if(scalar(@datas)>1){print "[".join(",",@datas)."]";}
		else{print $datas[0];}
		$urlindex++;
	}
	print "}\n";
}
############################## retrieveExecutes ##############################
sub retrieveExecutes{
	my $database=shift();
	my $dbh=openDB($database);
	my $query="select distinct subject, n2.data, n3.data from edge as e1 left outer join node as n2 on e1.predicate=n2.id left outer join node as n3 on e1.object=n3.id where e1.subject in (select subject from edge where predicate=(select id from node where data=\"".$urls->{"daemon/command"}."\"))";
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $hash={};
	my $executes={};
	while(my @rows=$sth->fetchrow_array()){
		my $subject=$rows[0];
		my $predicate=$rows[1];
		my $object=$rows[2];
		if($predicate=~/^.+#(.+)$/){$predicate="\$$1";}
		if($predicate eq $urls->{"daemon/command"}){push(@{$executes->{$object}},$subject);next;}
		if(!exists($hash->{$subject})){$hash->{$subject}={};}
		if(!exists($hash->{$subject}->{$predicate})){$hash->{$subject}->{$predicate}=$object;}
		elsif(ref($hash->{$subject}->{$predicate})eq"ARRAY"){
			my $match=0;
			foreach my $obj(@{$hash->{$subject}->{$predicate}}){if($obj eq $object){$match=1;}}
			if($match==0){push(@{$hash->{$subject}->{$predicate}},$object);}
		}elsif($hash->{$subject}->{$predicate} ne $object){$hash->{$subject}->{$predicate}=[$hash->{$subject}->{$predicate},$object];}
	}
	$dbh->disconnect;
	my $hashtable={};
	foreach my $url(keys(%{$executes})){
		foreach my $nodeid(sort{$a<=>$b}@{$executes->{$url}}){
			push(@{$hashtable->{$url}},$hash->{$nodeid});
		}
	}
	return $hashtable
}
############################## whichSoftware ##############################
sub whichSoftware{
	my @softwares=@_;
	my $database=shift(@softwares);
	my $hash=dbSelect($database,undef,$urls->{"software/bin"},undef);
	foreach my $software(@softwares){
		if(exists($hash->{$software})){
			my $path=$hash->{$software}->{$urls->{"software/bin"}};
			print "$path\n";
			next;
		}
		my $path=`which $software`;
		chomp($path);
		if($path ne ""){
			dbInsert($database,$software,$urls->{"software/bin"},$path);
			print "$path\n";
		}
	}
}
############################## executeComand ##############################
sub executeComand{
	my $database=shift();
	my $json=shift();
	my $nodeid=newNode($database);
	my $rdf={};
	my $url=$json->{"url"};
	$rdf->{$urls->{"daemon"}}={};
	$rdf->{$urls->{"daemon"}}->{$urls->{"daemon/execute"}}=$nodeid;
	$rdf->{$nodeid}={};
	$rdf->{$nodeid}->{$urls->{"daemon/command"}}=$url;
	foreach my $key(keys(%{$json})){
		if($key eq "url"){next;}
		my $value=$json->{$key};
		$rdf->{$nodeid}->{"$url#$key"}=$value;
	}
	jsonInsert($database,$rdf);
	return $nodeid;
}
############################## mkdirDownload ##############################
sub mkdirDownload{my $path="download/".time();mkdir("download");mkdir($path);return $path}
############################## getObject ##############################
sub getObject{
	my $database=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $hash=dbSelect($database,$subject,$predicate,$object);
	if(scalar(keys(%{$hash}))==0){return;}
	my $object=$hash->{$subject}->{$predicate};
	if(ref($object)ne"ARRAY"){return $object;}
	return $object->[0];
}
############################## getObjects ##############################
sub getObjects{
	my $database=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $hash=dbSelect($database,$subject,$predicate,$object);
	if(scalar(keys(%{$hash}))==0){return;}
	my $object=$hash->{$subject}->{$predicate};
	if(ref($object)ne"ARRAY"){$object=[$object];}
	return @{$object};
}
############################## downloadFiles ##############################
sub downloadFiles{
	my $database=shift();
	my @downloads=getObjects($database,$urls->{"system"},$urls->{"system/download"});
	my @files=();
	foreach my $url(@downloads){
		my $node=getObject($database,$url,$urls->{"file"});
		my $path=downloadFile($url,mkdirDownload());
		if(!defined($path)){next;}
		dbReplace($database,$node,$path);
		push(@files,$path);
	}
	return @files;
}
############################## registerDownloads ##############################
sub registerDownloads{
	my @urls=@_;
	my $database=shift(@urls);
	my @nodes=();
	foreach my $url(@urls){
		my $node=newNode($database);
		dbInsert($database,$urls->{"system"},$urls->{"system/download"},$url);
		dbInsert($database,$url,$urls->{"file"},$node);
		push(@nodes,$node);
	}
	return @nodes;
}
############################## downloadFile ##############################
sub downloadFile{
	my $url=shift();
	my $outdir=shift();
	my $agent=new LWP::UserAgent();
	$agent->agent('rdf.pl/1.0');
	$agent->timeout(10);
	$agent->env_proxy;
	my $request=HTTP::Request->new(GET=>$url);
	my $filename="$outdir/".basename($url);
	my $res=$agent->request($request);
	if($res->is_success){
		open(OUT,">$filename");
		print OUT $res->content;
		close(OUT);
	}elsif($res->is_error){return;}
	return $filename;
}
############################## printQueryResults ##############################
sub printQueryResults{
	my $results=shift();
	my $writer=shift();
	my @a=();
	foreach my $result(@{$results}){
		my @b=();
		foreach my $key(keys(%{$result})){push(@b,"\"$key\":\"".$result->{$key}."\"");}
		push(@a,"{".join(",",@b)."}");
	}
	print "[".join(",",@a)."]\n";
}
############################## assembleJsonResults ##############################
sub assembleJsonResults{
	my $results=shift();
	my $template=shift();
	my $writer=shift();
	$template=unescapeOption($template);
	my @lines=split(/,/,$template);
	foreach my $result(@{$results}){
		foreach my $line(@lines){
			my @tokens=split(/\-\>/,$line);
			foreach my $token(@tokens){
				foreach my $key(sort{$b cmp $a} keys(%{$result})){
					my $val=$result->{$key};
					$token=~s/\$$key/$val/g;
				}
			}
			print $writer join("\t",@tokens)."\n";
		}
	}
}
############################## outputQueryResults ##############################
sub outputQueryResults{
	my $results=shift();
	my $temp={};
	foreach my $res(@{$results}){foreach my $key(keys(%{$res})){$temp->{$key}++;}}
	my @variables=sort{$a cmp $b}keys(%{$temp});
	print join("\t",@variables)."\n";
	foreach my $res(@{$results}){
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
############################## checkReponse ##############################
sub checkReponse{
	my $response=shift();
	my $success=0;
	foreach my $line(split(/\n/,$response)){if($line=~/HTTP\/\d+\.\d+\s+200\s+OK/){$success=1;}}
	if($success){print STDERR "OK\n";}
	else{print STDERR "FAILED\n";}
}
############################## dbDelete ##############################
sub dbDelete{
	my $database=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $query="delete from edge";
	my @wheres=();
	if(defined($subject)){
		if(ref($subject) eq "ARRAY"){push(@wheres,"subject in(select id from node where data in(\"".join("\",\"",@{$subject})."\"))");}
		else{push(@wheres,"subject=(select id from node where data='$subject')");}
	}
	if(defined($predicate)){
		if(ref($predicate) eq "ARRAY"){push(@wheres,"predicate in(select id from node where data in(\"".join("\",\"",@{$predicate})."\"))");}
		else{push(@wheres,"predicate=(select id from node where data='$predicate')");}
	}
	if(defined($object)){
		if(ref($object) eq "ARRAY"){push(@wheres,"object in(select id from node where data in(\"".join("\",\"",@{$object})."\"))");}
		else{push(@wheres,"object=(select id from node where data='$object')");}
	}
	if(scalar(@wheres)>0){$query.=" where ".join(" and ",@wheres);}
	my $dbh=openDB($database);
	$dbh->begin_work;
	my $sth=$dbh->prepare($query);
	my $linecount=$sth->execute();
	$dbh->commit;
	$dbh->disconnect;
	if($linecount eq "0E0"){$linecount=0;}
	return $linecount;
}
############################## dbInsert ##############################
sub dbInsert{
	my $database=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $json={$subject=>{$predicate=>$object}};
	my $dbh=openDB($database);
	$dbh->begin_work;
	my $linecount=insertRDF($dbh,$json);
	$dbh->commit;
	$dbh->disconnect;
	return $linecount;
}
############################## dbReplace ##############################
sub dbReplace{
	my $database=shift();
	my $from=shift();
	my $to=shift();
	my $rename=shift();
	my $query="update node set data=\"$to\" where data=\"$from\"";
	my $dbh=openDB($database);
	$dbh->begin_work;
	my $sth=$dbh->prepare($query);
	my $linecount=$sth->execute();
	$dbh->commit;
	$dbh->disconnect;
	if($linecount eq "0E0"){return 0;}
	if($rename && -e $from){
		if($to=~/^(.+)\/\.$/){$to="$1/".basename($from);}
		mkpath(dirname($to));
		rename($from,$to);
	}
	return $linecount;
}
############################## dbSelect ##############################
sub dbSelect{
	my $database=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $dbh=openDB($database);
	my $query="select n1.data,n2.data,n3.data from edge as e1 join node as n1 on e1.subject=n1.id join node as n2 on e1.predicate=n2.id join node as n3 on e1.object=n3.id";
	my $where="";
	if($subject ne ""){
		if(length($where)>0){$where.=" and";}
		if(ref($subject) eq "ARRAY"){$where.=" e1.subject in(select id from node where data in(\"".join("\",\"",@{$subject})."\"))";}
		else{$where.=" e1.subject=(select id from node where data='$subject')";}
	}
	if($predicate ne ""){
		if(length($where)>0){$where.=" and";}
		if(ref($predicate) eq "ARRAY"){$where.=" e1.predicate in(select id from node where data in(\"".join("\",\"",@{$predicate})."\"))";}
		else{$where.=" e1.predicate=(select id from node where data='$predicate')";}
	}
	if($object ne ""){
		if(length($where)>0){$where.=" and";}
		if(ref($object) eq "ARRAY"){$where.=" e1.object in(select id from node where data in(\"".join("\",\"",@{$object})."\"))";}
		else{$where.=" e1.object=(select id from node where data='$object')";}
	}
	if($where ne ""){$query.=" where$where";}
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $hash={};
	while(my @rows=$sth->fetchrow_array()){
		my $subject=$rows[0];
		my $predicate=$rows[1];
		my $object=$rows[2];
		if(!exists($hash->{$subject})){$hash->{$subject}={};}
		if(!exists($hash->{$subject}->{$predicate})){$hash->{$subject}->{$predicate}=$object;}
		elsif(ref($hash->{$subject}->{$predicate}) eq "ARRAY"){push(@{$hash->{$subject}->{$predicate}},$object);}
		else{$hash->{$subject}->{$predicate}=[$hash->{$subject}->{$predicate},$object];}
	}
	$dbh->disconnect;
	return $hash;
}
############################## dbUpdate ##############################
sub dbUpdate{
	my $database=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $json={$subject=>{$predicate=>$object}};
	my $dbh=openDB($database);
	$dbh->begin_work;
	updateRDF($dbh,$json);
	$dbh->commit;
	$dbh->disconnect;
}
############################## jsonInsert ##############################
sub jsonInsert{
	my $database=shift();
	my $json=shift();
	my $dbh=openDB($database);
	$dbh->begin_work;
	my $linecount=insertRDF($dbh,$json);
	$dbh->commit;
	$dbh->disconnect;
	return $linecount;
}
############################## jsonUpdate ##############################
sub jsonUpdate{
	my $database=shift();
	my $json=shift();
	my $dbh=openDB($database);
	$dbh->begin_work;
	updateRDF($dbh,$json);
	$dbh->commit;
	$dbh->disconnect;
}
############################## webDelete ##############################
sub webDelete{
	my $database=shift();
	my $json=shift();
	my $url=dirname($database)."/moirai.php?command=delete";
	my $dbname=basename($database);
	my $data={'db'=>basename($database),'data'=>jsonEncode($json)};
	my $request=POST($url,$data);
	my $agent=LWP::UserAgent->new;
	my $content=$agent->request($request)->content;
	print "$content\n";
}
############################## webInsert ##############################
sub webInsert{
	my $database=shift();
	my $json=shift();
	my $url=dirname($database)."/moirai.php?command=insert";
	my $dbname=basename($database);
	my $data={'db'=>basename($database),'data'=>jsonEncode($json)};
	my $request=POST($url,$data);
	my $agent=LWP::UserAgent->new;
	my $content=$agent->request($request)->content;
	print "$content\n";
}
############################## webQuery ##############################
sub webQuery{
	my $database=shift();
	my $data=shift();
	my $url=dirname($database)."/moirai.php?command=query";
	my $dbname=basename($database);
	$data->{"db"}=basename($database);
	my $request=POST($url,$data);
	my $agent=LWP::UserAgent->new;
	my $content=$agent->request($request)->content;
	my $json=jsonDecode($content);
	return $json;
}
############################## webSelect ##############################
sub webSelect{
	my $database=shift();
	my $json=shift();
	my $url=dirname($database)."/moirai.php?command=select";
	my $dbname=basename($database);
	my $data={'db'=>basename($database),'data'=>jsonEncode($json)};
	my $request=POST($url,$data);
	my $agent=LWP::UserAgent->new;
	my $content=$agent->request($request)->content;
	my $json=jsonDecode($content);
	delete($json->{"rdfquery"});
	return $json;
}
############################## webUpdate ##############################
sub webUpdate{
	my $database=shift();
	my $json=shift();
	my $url=dirname($database)."/moirai.php?command=update";
	my $dbname=basename($database);
	my $data={'db'=>basename($database),'data'=>jsonEncode($json)};
	my $request=POST($url,$data);
	my $agent=LWP::UserAgent->new;
	my $content=$agent->request($request)->content;
	print "$content\n";
}
############################## queryTotsv ##############################
sub queryTotsv{
	my $writer=shift();
	my $queries=shift();
	my $results=shift();
	foreach my $result(@{$results}){
		foreach my $query(@{$queries}){
			my @tokens=split(/->/,$query);
			foreach my $token(@tokens){if($token=~/^\$(.+)$/){if(exists($result->{$1})){$token=$result->{$1}}}}
			print $writer join("\t",@tokens)."\n";
		}
	}
}
############################## assembleJson ##############################
sub assembleJson{
	my $reader=shift();
	my $template=shift();
	my $json=readJson($reader);
	my ($writer,$file)=tempfile(UNLINK=>1);
	assembleJsonResults($json,$template,$writer);
	close($writer);
	return $file;
}
############################## assembleFile ##############################
sub assembleFile{
	my $reader=shift();
	my $template=shift();
	my ($writer,$file)=tempfile(UNLINK=>1);
	my $expression=expressionCreate($template);
	while(<$reader>){
		chomp;s/\r//g;
		my @tokens=expressionExtract($expression,$_);
		print $writer join("\t",@tokens)."\n";
	}
	close($writer);
	return $file;
}
############################## importDB ##############################
sub importDB{
	my $dbname=shift();
	my $reader=shift();
	my $delim="\t";
	my $dbh=openDB($dbname);
	my $size=nodeMax($dbh);
	my $nodes=getNodeHash($dbh);
	my $edges=getEdgeHash($dbh,$delim);
	$dbh->disconnect;
	my ($nodehandler,$nodefile)=tempfile(UNLINK=>1);
	my ($edgehandler,$edgefile)=tempfile(UNLINK=>1);
	my $nodecount=0;
	my $edgecount=0;
	my $linecount=0;
	while(<$reader>){
		chomp;
		s/\r//g;
		my($subject,$predicate,$object)=split(/\t/);
		my $subid=$nodes->{$subject};
		if(!defined($subid)){$subid=++$size;$nodes->{$subject}=$subid;$nodecount++;print $nodehandler "$size$delim$subject\n";}
		my $preid=$nodes->{$predicate};
		if(!defined($preid)){$preid=++$size;$nodes->{$predicate}=$preid;$nodecount++;print $nodehandler "$size$delim$predicate\n";}
		my $objid=$nodes->{$object};
		if(!defined($objid)){$objid=++$size;$nodes->{$object}=$objid;$nodecount++;print $nodehandler "$size$delim$object\n";}
		my $line="$subid$delim$preid$delim$objid";
		if(!exists($edges->{$line})){$edges->{$line}=1;$edgecount++;print $edgehandler "$line\n";}
		$linecount++;
	}
	close($nodehandler);
	close($edgehandler);
	if($edgecount>0||$nodecount>0){
		my ($cmdhandler,$cmdfile)=tempfile(UNLINK=>1);
		print $cmdhandler ".mode tabs\n";
		if($nodecount>0){print $cmdhandler ".import $nodefile node\n";}
		if($edgecount>0){print $cmdhandler ".import $edgefile edge\n";}
		close($cmdhandler);
		my $command="sqlite3 $dbname < $cmdfile";
		system($command);
	}
	return $linecount;
}
############################## mergeDB ##############################
sub mergeDB{
	my $dbname=shift();
	my $reader=shift();
	my $delim="\t";
	my $dbh=openDB($dbname);
	my $size=nodeMax($dbh);
	my $nodes=getNodeHash($dbh);
	my $edges=getEdgeHash($dbh,$delim);
	$dbh->disconnect;
	my ($nodehandler,$nodefile)=tempfile(UNLINK=>1);
	my ($edgehandler,$edgefile)=tempfile(UNLINK=>1);
	my $nodecount=0;
	my $edgecount=0;
	my $linecount=0;
	my $newnodes={};
	while(<$reader>){
		chomp;
		s/\r//g;
		my($subject,$predicate,$object)=split(/\t/);
		if($subject=~/^_node(\d+)_$/){
			if(exists($newnodes->{$subject})){$subject=$newnodes->{$subject};}
			else{my $temp="_node$size"."_";$newnodes->{$subject}=$temp;$subject=$temp;}
		}
		my $subid=$nodes->{$subject};
		if(!defined($subid)){$subid=++$size;$nodes->{$subject}=$subid;$nodecount++;print $nodehandler "$size$delim$subject\n";}
		if($predicate=~/^_node(\d+)_$/){
			if(exists($newnodes->{$predicate})){$predicate=$newnodes->{$predicate};}
			else{my $temp="_node$size"."_";$newnodes->{$predicate}=$temp;$predicate=$temp;}
		}
		my $preid=$nodes->{$predicate};
		if(!defined($preid)){$preid=++$size;$nodes->{$predicate}=$preid;$nodecount++;print $nodehandler "$size$delim$predicate\n";}
		if($object=~/^_node(\d+)_$/){
			if(exists($newnodes->{$object})){$object=$newnodes->{$object};}
			else{my $temp="_node$size"."_";$newnodes->{$object}=$temp;$object=$temp;}
		}
		my $objid=$nodes->{$object};
		if(!defined($objid)){$objid=++$size;$nodes->{$object}=$objid;$nodecount++;print $nodehandler "$size$delim$object\n";}
		my $line="$subid$delim$preid$delim$objid";
		if(!exists($edges->{$line})){$edges->{$line}=1;$edgecount++;print $edgehandler "$line\n";}
		$linecount++;
	}
	close($nodehandler);
	close($edgehandler);
	if($edgecount>0||$nodecount>0){
		my ($cmdhandler,$cmdfile)=tempfile(UNLINK=>1);
		print $cmdhandler ".mode tabs\n";
		if($nodecount>0){print $cmdhandler ".import $nodefile node\n";}
		if($edgecount>0){print $cmdhandler ".import $edgefile edge\n";}
		close($cmdhandler);
		my $command="sqlite3 $dbname < $cmdfile";
		system($command);
	}
	return $linecount;
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
############################## readText ##############################
sub readText{
	my $file=shift();
	my $text="";
	open(IN,$file);
	while(<IN>){s/\r//g;$text.=$_;}
	close(IN);
	return $text;
}
############################## readJson ##############################
sub readJson{
	my $reader=shift();
	my $json="";
	while(<$reader>){chomp;s/\r//g;$json.=$_;}
	return jsonDecode($json);
}
############################## parseQuery ##############################
sub parseQuery{
	my $statement=shift();
	my @statements=(ref($statement)ne"ARRAY")?($statement):@{$statement};
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
			}elsif($node=~/^\!(.+)$/){
				my $var=$1;
				push(@where_conditions,"($edge_name.subject is null or $edge_name.subject not in (select subject from edge where $rdf=(select id from node where data='$var')))");
				if($i>0){$edge_line="left outer join ";}
			}elsif($node=~/^\$(.+)$/){
				my $node_name=$1;
				if(!exists($variables->{$node_name})){$variables->{$node_name}=scalar(keys(%{$variables}));push(@nodeRegisters,$node_name);}
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
	return ($query,\@varnames);
}
############################## outputInAssembleFormat ##############################
sub outputInAssembleFormat{
	my $rdf=shift();
	my $template=shift();
	my $writer=shift();
	my $expression=expressionCreate($template);
	foreach my $subject(sort{$a cmp $b}keys(%{$rdf})){
		foreach my $predicate(sort{$a cmp $b}keys(%{$rdf->{$subject}})){
			my $object=$rdf->{$subject}->{$predicate};
			if(ref($object) eq "ARRAY"){foreach my $o(sort{$a cmp $b}@{$object}){print $writer expressionAssemble($expression,$subject,$predicate,$o)."\n";}}
			else{print $writer expressionAssemble($expression,$subject,$predicate,$object)."\n";}
		}
	}
}
############################## outputInColumnFormat ##############################
sub outputInColumnFormat{
	my $rdf=shift();
	my $writer=shift();
	foreach my $subject(sort{$a cmp $b}keys(%{$rdf})){
		foreach my $predicate(sort{$a cmp $b}keys(%{$rdf->{$subject}})){
			my $object=$rdf->{$subject}->{$predicate};
			if(ref($object) eq "ARRAY"){foreach my $o(sort{$a cmp $b}@{$object}){print $writer "$subject\t$predicate\t$o\n";}}
			else{print $writer "$subject\t$predicate\t$object\n";}
		}
	}
}
############################## outputInJsonFormat ##############################
sub outputInJsonFormat{
	my $rdf=shift();
	my $writer=shift();
	my $i=0;
	print $writer "{";
	if(defined($rdf)){
		foreach my $subject(sort{$a cmp $b}keys(%{$rdf})){
			if($i>0){print $writer ","};
			print $writer "\"$subject\":{";
			my $j=0;
			foreach my $predicate(sort{$a cmp $b}keys(%{$rdf->{$subject}})){
				if($j){print $writer ",";}
				print $writer "\"$predicate\":";
				my $object=$rdf->{$subject}->{$predicate};
				if(ref($object) eq "ARRAY"){
					my $k=0;
					print $writer "[";
					foreach my $o(sort{$a cmp $b}@{$object}){
						if($k>0){print $writer ",";}
						print $writer "\"".escapeReturnTab($o)."\"";
						$k++;
					}
					print $writer "]";
				}else{
					print $writer "\"".escapeReturnTab($object)."\"";
				}
				$j++;
			}
			print $writer "}";
			$i++;
		}
	}
	print $writer "}\n";
}
############################## escapeReturnTab ##############################
sub escapeReturnTab{
	my $string=shift();
	$string=~s/\\/\\\\/g;
	$string=~s/\n/\\\n/g;
	$string=~s/\t/\\\t/g;
	$string=~s/\r/\\\r/g;
	$string=~s/\"/\\\"/g;
	$string=~s/\'/\\\'/g;
	return $string;
}
############################## loadJsonFromWeb ##############################
sub loadJsonFromWeb{
	my $url=shift();
	my $username=shift();
	my $password=shift();
	my $content=getHttpContent($url,$username,$password);
	return jsonDecode($content);
}
############################## queryCount ##############################
sub queryCount{
	my $dbh=shift();
	my $query=shift();
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $count=0;
	while(my @rows=$sth->fetchrow_array()){$count++;}
	return $count;
}
############################## getResults ##############################
sub getResults{
	my $dbh=shift();
	my $query=shift();
	my $variables=shift();
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my @array=();
	while(my @rows=$sth->fetchrow_array()){
		my $hashtable={};
		my $undefined=0;
		for(my $i=0;$i<scalar(@{$variables});$i++){
			if($rows[$i]eq"_undef_"){$undefined=1;last;}
			my $variable=$variables->[$i];
			$hashtable->{$variable}=$rows[$i];
		}
		if($undefined){next;}
		push(@array,$hashtable);
	}
	return \@array;
}
############################## dumpDB ##############################
sub dumpDB{
	my $database=shift();
	my $format=shift();
	my $writer=shift();
	my $dbh=openDB($database);
	my $query="select n1.data,n2.data,n3.data from edge as e1 join node as n1 on e1.subject=n1.id join node as n2 on e1.predicate=n2.id join node as n3 on e1.object=n3.id";
	my $where="";
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $hash={};
	if($format eq "json"){
		my $rdf={};
		while(my @rows=$sth->fetchrow_array()){
			my $subject=$rows[0];
			my $predicate=$rows[1];
			my $object=$rows[2];
			if(!exists($rdf->{$subject})){$rdf->{$subject}={};}
			if(!exists($rdf->{$subject}->{$predicate})){$rdf->{$subject}->{$predicate}=$object;}
			elsif(ref($rdf->{$subject}->{$predicate}) eq "ARRAY"){push(@{$rdf->{$subject}->{$predicate}},$object);}
			else{$rdf->{$subject}->{$predicate}=[$rdf->{$subject}->{$predicate},$object];}
		}
		outputInJsonFormat($rdf,$writer);
	}else{
		while(my @rows=$sth->fetchrow_array()){
			my $subject=$rows[0];
			my $predicate=$rows[1];
			my $object=$rows[2];
			print $writer "$subject\t$predicate\t$object\n";
		}
	}
	$dbh->disconnect;
}
############################## deleteTSV ##############################
sub deleteTSV{
	my $dbh=shift();
	my $dbname=shift();
	my $reader=shift();
	my $delim="\t";
	my $nodes=getNodeHash($dbh);
	my $edges=getEdgeHash($dbh,$delim);
	my $linecount=0;
	while(<$reader>){
		chomp;
		s/\r//g;
		my($subject,$predicate,$object)=split(/\t/);
		if(!exists($nodes->{$subject})){next;}
		if(!exists($nodes->{$predicate})){next;}
		if(!exists($nodes->{$object})){next;}
		my $line=$nodes->{$subject}.$delim.$nodes->{$predicate}.$delim.$nodes->{$object};
		delete($edges->{$line});
		$linecount++;
	}
	if($linecount==0){return $linecount;}
	my ($edgehandler,$edgefile)=tempfile(UNLINK=>1);
	my $usedids={};
	foreach my $edge(keys(%{$edges})){
		my ($subid,$preid,$objid)=split("\t",$edge);
		$usedids->{$subid}=1;
		$usedids->{$preid}=1;
		$usedids->{$objid}=1;
		print $edgehandler "$edge\n";
	}
	close($edgehandler);
	my ($nodehandler,$nodefile)=tempfile(UNLINK=>1);
	foreach my $data(sort{$nodes->{$a}<=>$nodes->{$b}}keys(%{$nodes})){
		my $id=$nodes->{$data};
		if(!exists($usedids->{$id})){next;}
		print $nodehandler "$id\t$data\n";
	}
	close($nodehandler);
	my ($cmdhandler,$cmdfile)=tempfile(UNLINK=>1);
	print $cmdhandler ".mode tabs\n";
	print $cmdhandler ".import $nodefile node\n";
	print $cmdhandler ".import $edgefile edge\n";
	close($cmdhandler);
	$dbh=openDB("$dbname.tmp");
	$dbh->disconnect;
	my $command="sqlite3 $dbname.tmp < $cmdfile";
	system($command);
	system("mv $dbname.tmp $dbname");
	return $linecount;
}
############################## replaceTSV ##############################
sub replaceTSV{
	my $dbh=shift();
	my $dbname=shift();
	my $reader=shift();
	my $rename=shift();
	my $delim="\t";
	my $hash={};
	my $linecount=0;
	while(<$reader>){
		chomp;s/\r//g;
		my($from,$to)=split(/\t/);
		if($rename && -e $from){
			if($to=~/^(.+)\/\.$/){$to="$1/".basename($from);}
			mkpath(dirname($to));
			rename($from,$to);
		}
		$hash->{$from}=$to;
		$linecount++;
	}
	my $nodes=getNodeIdHash($dbh);
	my ($nodehandler,$nodefile)=tempfile(UNLINK=>1);
	foreach my $id(sort{$a<=>$b}keys(%{$nodes})){
		my $data=$nodes->{$id};
		if(exists($hash->{$data})){$data=$hash->{$data};}
		print $nodehandler "$id\t$data\n";
	}
	close($nodehandler);
	my $edges=getEdgeHash($dbh,$delim);
	my ($edgehandler,$edgefile)=tempfile(UNLINK=>1);
	foreach my $edge(keys(%{$edges})){print $edgehandler "$edge\n";}
	close($edgehandler);
	my ($cmdhandler,$cmdfile)=tempfile(UNLINK=>1);
	print $cmdhandler ".mode tabs\n";
	print $cmdhandler ".import $nodefile node\n";
	print $cmdhandler ".import $edgefile edge\n";
	close($cmdhandler);
	$dbh=openDB("$dbname.tmp");
	$dbh->disconnect;
	my $command="sqlite3 $dbname.tmp < $cmdfile";
	system($command);
	system("mv $dbname.tmp $dbname");
	return $linecount;
}
############################## deleteRDF ##############################
sub deleteRDF{
	my $dbh=shift();
	my $json=shift();
	my $linecount=0;
	if(ref($json)eq"HASH"){}
	elsif(ref($json)eq"ARRAY"){foreach my $j(@{$json}){$linecount+=deleteRDF($dbh,$j);}return;}
	else{$json=parseRDF($json);}
	foreach my $subject(keys(%{$json})){
		my $subject_id=handleNode($dbh,$subject);
		foreach my $predicate(sort{$a cmp $b} keys(%{$json->{$subject}})){
			my $predicate_id=handleNode($dbh,$predicate);
			my $object=$json->{$subject}->{$predicate};
			if(ref($object)eq"ARRAY"){
				foreach my $o(@{$object}){
					my $object_id=handleNode($dbh,$o);
					$linecount+=deleteEdge($dbh,$subject_id,$predicate_id,$object_id);
				}
			}elsif(ref($object)eq"HASH"){
				foreach my $o(keys(%{$object})){
					my $object_id=handleNode($dbh,$o);
					$linecount+=deleteEdge($dbh,$subject_id,$predicate_id,$object_id);
				}
			}else{
				my $object_id=handleNode($dbh,$object);
				$linecount+=deleteEdge($dbh,$subject_id,$predicate_id,$object_id);
			}
		}
	}
	return $linecount;
}
############################## insertRDF ##############################
sub insertRDF{
	my $dbh=shift();
	my $json=shift();
	my $linecount=0;
	if(ref($json)eq"HASH"){}
	elsif(ref($json)eq"ARRAY"){foreach my $j(@{$json}){$linecount+=insertRDF($dbh,$j);}return;}
	else{$json=parseRDF($json);}
	foreach my $subject(keys(%{$json})){
		my $subject_id=handleNode($dbh,$subject);
		foreach my $predicate(sort{$a cmp $b} keys(%{$json->{$subject}})){
			my $predicate_id=handleNode($dbh,$predicate);
			my $object=$json->{$subject}->{$predicate};
			if(ref($object)eq"ARRAY"){
				foreach my $o(@{$object}){
					my $object_id=handleNode($dbh,$o);
					$linecount+=insertEdge($dbh,$subject_id,$predicate_id,$object_id);
				}
			}elsif(ref($object)eq"HASH"){
				foreach my $o(keys(%{$object})){
					my $object_id=handleNode($dbh,$o);
					$linecount+=insertEdge($dbh,$subject_id,$predicate_id,$object_id);
				}
			}else{
				my $object_id=handleNode($dbh,$object);
				$linecount+=insertEdge($dbh,$subject_id,$predicate_id,$object_id);
			}
		}
	}
	return $linecount;
}
############################## parseRDF ##############################
sub parseRDF{
	my $text=shift();
	my $rdf={};
	my @lines=split(/,/,$text);
	foreach my $line(@lines){
		my @tokens=split(/\>/,$line);
		if(scalar(@tokens)!=3){next;}
		my $subject=$tokens[0];
		my $predicate=$tokens[1];
		my $object=$tokens[2];
		if(!exists($rdf->{$subject})){$rdf->{$subject}={};}
		if(!exists($rdf->{$subject}->{$predicate})){$rdf->{$subject}->{$predicate}=$object;}
		elsif(ref($rdf->{$subject}->{$predicate}) eq "ARRAY"){push(@{$rdf->{$subject}->{$predicate}},$object);}
		else{$rdf->{$subject}->{$predicate}=[$rdf->{$subject}->{$predicate},$object];}
	}
	return $rdf;
}
############################## updateRDF ##############################
sub updateRDF{
	my $dbh=shift();
	my $json=shift();
	my $linecount=0;
	if(ref($json)eq"HASH"){}
	elsif(ref($json)eq"ARRAY"){foreach my $j(@{$json}){$linecount+=updateRDF($dbh,$j);}return;}
	else{$json=parseRDF($json);}
	foreach my $subject(keys(%{$json})){
		my $subject_id=handleNode($dbh,$subject);
		foreach my $predicate(sort{$a cmp $b} keys(%{$json->{$subject}})){
			my $predicate_id=handleNode($dbh,$predicate);
			my $object=$json->{$subject}->{$predicate};
			if(ref($object)eq"ARRAY"){
				foreach my $o(@{$object}){
					my $object_id=handleNode($dbh,$o);
					$linecount+=updateEdge($dbh,$subject_id,$predicate_id,$object_id);
				}
			}elsif(ref($object)eq"HASH"){
				foreach my $o(keys(%{$object})){
					my $object_id=handleNode($dbh,$o);
					$linecount+=updateEdge($dbh,$subject_id,$predicate_id,$object_id);
				}
			}else{
				my $object_id=handleNode($dbh,$object);
				$linecount+=updateEdge($dbh,$subject_id,$predicate_id,$object_id);
			}
		}
	}
	return $linecount;
}
############################## expressionCreate ##############################
sub expressionCreate{
	my $line=shift();
	my @texts=();
	my @inserts=();
	my $start=0;
	$line=escapeTag($line);
	my $index=index($line,"[",$start);
	while($index>=0){
		my $index2=index($line,"]",$index+1);
		my $text=substr($line,$start,$index-$start);
		my $insert=substr($line,$index+1,$index2-$index-1);
		$start=$index2+1;
		$index=index($line,"[",$start);
		push(@texts,$text);
		push(@inserts,$insert);
	}
	if($start<length($line)){
		my $text=substr($line,$start);
		push(@texts,$text);
	}
	my $extras={};
	my $index=0;
	foreach my $insert(@inserts){
		my @tokens=split(/\:/,$insert);
		$insert=shift(@tokens);
		if(scalar(@tokens)<1){$index++;next;}
		$extras->{$index}=\@tokens;
		$index++;
	}
	foreach my $text(@texts){$text=unescapeTag($text);$text=~s/\\t/\t/g;}
	my $hashtable={};
	$hashtable->{"texts"}=\@texts;
	$hashtable->{"inserts"}=\@inserts;
	$hashtable->{"extras"}=$extras;
	$hashtable->{"line"}=$line;
	my $regexp="^";
	my $size=scalar(@texts)>scalar(@inserts)?scalar(@texts):scalar(@inserts);
	for(my $i=0;$i<$size;$i++){
		if($i<scalar(@texts)){$regexp.=escapeCharacter($texts[$i]);}
		if($i<scalar(@inserts)){$regexp.="(.+)";}
	}
	$regexp.="\$";
	$hashtable->{"regular expression"}=$regexp;
	return $hashtable;
}
############################## expressionAssemble ##############################
sub expressionAssemble{
	my @tokens=@_;
	my $expression=shift(@tokens);
	my $line;
	my $texts=$expression->{"texts"};
	my $inserts=$expression->{"inserts"};
	my $extras=$expression->{"extras"};
	my $size_t=scalar(@{$texts});
	my $size_i=scalar(@{$inserts});
	for(my $i=0;$i<$size_i;$i++){
		my $text=$texts->[$i];
		my $insert=$inserts->[$i];
		my $value;
		if($insert=~/^(\d+)$/){$value=$tokens[$1];}
		elsif($insert=~/^(\d+)-$/){$value=[];for(my $i=$1;$i<scalar(@tokens);$i++){push(@{$value},$tokens[$i]);}}
		elsif($insert=~/^(\d+)-(\d+)$/){$value=[];for(my $i=$1;$i<scalar(@tokens)&&$i<=$2;$i++){push(@{$value},$tokens[$i]);}}
		elsif($insert=~/-(\d+)$/){$value=[];for(my $i=0;$i<scalar(@tokens)&&$i<=$1;$i++){push(@{$value},$tokens[$i]);}}
		foreach my $extra(@{$extras->{$i}}){
			if(!defined($extra)){next;}
			elsif($extra eq ""){next;}
			elsif($extra=~/directory/){
				if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=get_directory($val);}}
				else{$value=get_directory($value);}
			} elsif($extra=~/path/){
			} elsif($extra=~/pwd/){
				if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=Cwd::abs_path($val);}}
				else{$value=Cwd::abs_path($value);}
			} elsif($extra=~/basename/){
				if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=get_basename(remove_zip_suffix($val));}}
				else{$value=get_basename(remove_zip_suffix($value));}
			} elsif($extra=~/base(\d+)/){
				my $index=$1;
				if(ref($value) eq "ARRAY"){
					foreach my $val(@{$value}){
						my $filename=get_basename($val);
						my @token=split(/\W+/,$filename);
						$val=$token[$index];
					}
				} else{
					my $filename=get_basename($value);
					my @token=split(/\W+/,$filename);
					$value=$token[$index];
				}
			} elsif($extra=~/dir(\d+)/){
				my $index=$1;
				if(ref($value) eq "ARRAY"){
					foreach my $val(@{$value}){
						my $directory=get_directory($val);
						my @token=split(/\//,$directory);
						$val=$token[$index];
					}
				} else{
					$value=get_directory($value);
					my @token=split(/\//,$value);
					$value=$token[$index];
				}
			} elsif($extra=~/nosuffix/){
				if(ref($value) eq "ARRAY"){
					foreach my $val(@{$value}){
						my $directory=get_directory($val);
						$val=get_basename($val);
						if($directory ne ""){$val="$directory/$val";}
					}
				} else{
					my $directory=get_directory($value);
					$value=get_basename($value);
					if($directory ne ""){$value="$directory/$value";}
				}
			} elsif($extra=~/suffix/){
				if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=get_suffix($val);}}
				else{$value=get_suffix($value);}
			} elsif($extra=~/filename/){
				if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=get_filename($val);}}
				else{$value=get_filename($value);}
			} elsif($extra=~/files/){
				if(ref($value) eq "ARRAY"){$value=join(" ",@{$value});}
			} elsif($extra=~/sort/){
				if(ref($value) eq "ARRAY"){$value=\{sort(" ",@{$value})};}
			} elsif($extra eq "content" || $extra eq "column"){
				if(ref($value) eq "ARRAY"){
					my @lines=();
					foreach my $val(@{$value}){push(@lines,content_line_to_array($val));}
					$value=\@lines;
				} else{
					my @lines=();
					push(@lines,content_line_to_array($value));
					$value=\@lines;
				}
			} elsif($extra=~/column(.*)/){
				my $index=$1;
				if(defined($index)){
					if(ref($value) eq "ARRAY"){
						my @lines=();
						foreach my $val(@{$value}){push(@lines,content_column_to_array($index,$val));}
						$value=\@lines;
					} else{
						my @lines=();
						push(@lines,content_column_to_array($index,$value));
						$value=\@lines;
					}
				}
			} elsif($extra=~/join(.*)/){
				my $delim=$1;
				if(ref($value) eq "ARRAY"){$value=join($delim,@{$value});}
			} elsif($extra=~/split(.+)/){
				my $delim=$1;
				if(ref($value) eq "ARRAY"){
					my @array=();
					foreach my $val(@{$value}){push(@array,split(/$delim/,$val));}
					$value=\@array;
				} else{
					my @tokens=split(/$delim/,$value);
					$value=\@tokens;
				}
			} elsif($extra=~/count/){
				if(ref($value) eq "ARRAY"){$value=scalar(@{$value});}
				else{$value=1;}
			} elsif($extra=~/length/){
				if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=length($val);}}
				else{$value=length($value);}
			} elsif($extra=~/s\/(.*)\/(.*)\/([ig]+)?/){
				my $before=$1;
				my $after=$2;
				my $other=$3;
				if($other=~/g/ && $other=~/i/){
					if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=~s/$before/$after/gi;}}
					else{$value=~s/$before/$after/gi;}
				} elsif($other=~/g/){
					if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=~s/$before/$after/g;}}
					else{$value=~s/$before/$after/g;}
				} elsif($other=~/i/){
					if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=~s/$before/$after/i;}}
					else{$value=~s/$before/$after/i;}
				} else{
					if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=~s/$before/$after/;}}
					else{$value=~s/$before/$after/;}
				}
			} elsif($extra=~/^(\d+)\-(\d+)$/){
				if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=substr($val,$1,$2);}}
				else{$value=substr($value,$1,$2);}
			} elsif($extra=~/^\-(\d+)$/){
				if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=substr($val,0,$1+1);}}
				else{$value=substr($value,0,$1+1);}
			} elsif($extra=~/^(\d+)\-$/){
				if(ref($value) eq "ARRAY"){foreach my $val(@{$value}){$val=substr($val,$1);}}
				else{$value=substr($value,$1);}
			} elsif($extra=~/\/(.+)\//){
				my $select=$1;
				if(ref($value) eq "ARRAY"){
					my @array=();
					foreach my $val(@{$value}){
						if($val !~ /$select/){next;}
						push(@array,$val);
					}
					$value=\@array;
				} else{
					if($value !~ /$select/){$value="";}
				}
			}
		}
		if(ref($value) eq "ARRAY"){$value=join(" ",@{$value});}
		$line.=$text . $value;
	}
	if($size_t>$size_i){$line.=$texts->[$size_t-1];}
	return $line;
}
############################## expressionExtract ##############################
sub expressionExtract{
	my $expression=shift();
	my $string=shift();
	my @output={};
	my @inserts=@{$expression->{"inserts"}};
	my @texts= @{$expression->{"texts"}};
	my $regexp=$expression->{"regular expression"};
	if($string=~/$regexp/){
		for(my $i=0;$i<scalar(@inserts);$i++){
			my $insert=$inserts[$i];
			$output[$insert]=${$i+1};
		}
	}
	return @output;
}
############################## escapeSqlite ##############################
sub escapeSqlite{my @out=@_;for(@out){s/\'/''/g;s/\"/""/g;}return wantarray?@out:$out[0];}
############################## escapeTag ##############################
sub escapeTag{my @out=@_;for(@out){s/\\\[/#right#/g;s/\\\]/#left#/g;}return wantarray?@out:$out[0];}
############################## unescapeTag ##############################
sub unescapeTag{my @out=@_;for(@out){s/#right#/[/g;s/#left#/]/g;}return wantarray?@out:$out[0];}
############################## escapeCharacter ##############################
sub escapeCharacter{
	my @out=@_;
	for(@out){
		if(!defined($_)){$_="";}
		s/\\/_escape_yen_mark_/g;
		s/ /\\s/g;
		s/\t/\\t/g;
		s/\n/\\n/g;
		s/\r/\\r/g;
		s/\^/\\\^/g;
		s/\./\\\./g;
		s/\*/\\\*/g;
		s/\[/\\\[/g;
		s/\]/\\\]/g;
		s/\(/\\\(/g;
		s/\)/\\\)/g;
		s/\{/\\\{/g;
		s/\}/\\\}/g;
		s/\$/\\\$/g;
		s/\|/\\\|/g;
		s/\+/\\\+/g;
		s/\?/\\\?/g;
		s/\//\\\//g;
		s/_escape_yen_mark_/\\\\/g;
	}
	return wantarray?@out:$out[0];
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
############################## unescapeOption ##############################
sub unescapeOption{
	my $text=shift();
	$text=~s/\\"/\"/g;
	$text=~s/\\'/\'/g;
	$text=~s/\\t/\t/g;
	$text=~s/\\r/\r/g;
	$text=~s/\\n/\n/g;
	$text=~s/\\\\/\\/g;
	return $text;
}
############################## RDF SQLITE3 DATABASE ##############################
sub openDB{
	my $database=shift();
	my $dbh=DBI->connect("dbi:SQLite:dbname=$database");
	$dbh->do("CREATE TABLE IF NOT EXISTS node(id INTEGER PRIMARY KEY,data TEXT)");
	$dbh->do("CREATE TABLE IF NOT EXISTS edge(subject INTEGER,predicate INTEGER,object INTEGER,PRIMARY KEY(subject,predicate,object))");
	chmod(0777,$database);
	return $dbh;
}
sub getEdgeHash{
	my $dbh=shift();
	my $delim=shift();
	my $sth=$dbh->prepare("SELECT subject,predicate,object FROM edge");
	$sth->execute();
	my $edges={};
	my @row=();
	while(@row=$sth->fetchrow_array()){
		$edges->{$row[0].$delim.$row[1].$delim.$row[2]}=1;
	}
	return $edges;
}
sub getNodeIdHash{
	my $dbh=shift();
	my $sth=$dbh->prepare("SELECT id,data FROM node");
	$sth->execute();
	my $nodes={};
	my @row=();
	while(@row=$sth->fetchrow_array()){
		$nodes->{$row[0]}=$row[1];
	}
	return $nodes;
}
sub getNodeHash{
	my $dbh=shift();
	my $sth=$dbh->prepare("SELECT id,data FROM node");
	$sth->execute();
	my $nodes={};
	my @row=();
	while(@row=$sth->fetchrow_array()){
		$nodes->{$row[1]}=$row[0];
	}
	return $nodes;
}
sub nodeMax{
	my $dbh=shift();
	my $sth=$dbh->prepare("SELECT max(id) FROM node");
	$sth->execute();
	my @row=$sth->fetchrow_array();
	return $row[0];
}
sub nodeSize{
	my $dbh=shift();
	my $sth=$dbh->prepare("SELECT count(*) FROM node");
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
sub newNode{
	my $database=shift();
	my $dbh=openDB($database);
	my $id=nodeMax($dbh)+1;
	my $name="$database#node$id";
	my $sth=$dbh->prepare("INSERT OR IGNORE INTO node(id,data) VALUES(?,?)");
	$sth->execute($id,$name);
	$dbh->disconnect;
	return $name;
}
sub insertNode{
	my $dbh=shift();
	my $data=shift();
	my $size=nodeMax($dbh);
	my $sth=$dbh->prepare("INSERT OR IGNORE INTO node(id,data) VALUES(?,?)");
	$sth->execute($size+1,$data);
	return $size+1;
}
sub updateNode{
	my $dbh=shift();
	my $from=shift();
	my $to=shift();
	my $sth=$dbh->prepare("update node set data=? where id=(select id from node where data=?)");
	my $linecount=$sth->execute($to,$from);
	if($linecount eq "0E0"){$linecount=0;}
	return $linecount;
}
sub insertEdge{
	my $dbh=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $sth=$dbh->prepare("INSERT OR IGNORE INTO edge(subject,predicate,object) VALUES(?,?,?)");
	my $linecount=$sth->execute($subject,$predicate,$object);
	if($linecount eq "0E0"){$linecount=0;}
	return $linecount;
}
sub updateEdge{
	my $dbh=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $sth=$dbh->prepare("UPDATE edge SET object=? where subject=? and predicate=?");
	$sth->execute($object,$subject,$predicate);
	$sth=$dbh->prepare("INSERT OR IGNORE INTO edge VALUES(?,?,?)");
	my $linecount=$sth->execute($subject,$predicate,$object);
	if($linecount eq "0E0"){$linecount=0;}
	return $linecount;
}
sub deleteEdge{
	my $dbh=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $sth=$dbh->prepare("DELETE FROM edge WHERE subject=? AND predicate=? AND object=?");
	my $linecount=$sth->execute($subject,$predicate,$object);
	if($linecount eq "0E0"){$linecount=0;}
	return $linecount;
}
sub getEdges{
	my $dbh=shift();
	my $subject=shift();
	my $predicate=shift();
	my $object=shift();
	my $query="select n1.data,n2.data,n3.data from edge as e1 join node as n1 on e1.subject=n1.id join node as n2 on e1.predicate=n2.id join node as n3 on e1.object=n3.id";
	my $where="";
	if($subject ne ""){if(length($where)>0){$where.=" and";}$where.=" e1.subject=(select id from node where data='$subject')";}
	if($predicate ne ""){if(length($where)>0){$where.=" and";}$where.=" e1.predicate=(select id from node where data='$predicate')";}
	if($object ne ""){if(length($where)>0){$where.=" and";}$where.=" e1.object=(select id from node where data='$object')";}
	if($where ne ""){$query.=" where$where";}
	my $sth=$dbh->prepare($query);
	$sth->execute();
	my $array=[];
	while(my @rows=$sth->fetchrow_array()){push(@{$array},\@rows);}
	return $array;
}
############################## HTTP ##############################
sub getHttpContent{
	my $url=shift();
	my $username=shift();
	my $password=shift();
	my $agent=new LWP::UserAgent();
	my $request=HTTP::Request->new(GET=>$url);
	if($username ne "" || $password ne ""){$request->authorization_basic($username,$password);}
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
############################## getDatetime ##############################
sub getDatetime{my $time=shift;return getDate("",$time).getTime("",$time);}
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
############################## listFiles ##############################
sub listFiles{
	my @inputdirectories=@_;
	my $filegrep=shift(@inputdirectories);
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
			$file=($inputdirectory eq ".")?$file:"$inputdirectory/$file";
			if(-d $file){
				if($recursivesearch!=0){push(@inputfiles,listFiles($filegrep,$recursivesearch-1,$file));}
				next;
			}elsif($file!~/$filegrep$/){next;}
			push(@inputfiles,$file);
		}
		closedir(DIR);
	}
	return @inputfiles;
}
############################## countLines ##############################
sub countLines{
	my @files=@_;
	my $writer=shift(@files);
	my $filegrep=shift(@files);
	my $recursivesearch=shift(@files);
	if(!defined($recursivesearch)){$recursivesearch=-1;}
	foreach my $file(listFiles($filegrep,$recursivesearch,@files)){
		my $count=0;
		if($file=~/\.bam$/){$count=`samtools view $file|wc -l`;}
		elsif($file=~/\.sam$/){$count=`samtools view $file|wc -l`;}
		elsif($file=~/\.gz(ip)?$/){$count=`gzip -cd $file|wc -l`;}
		elsif($file=~/\.bz(ip)?2$/){$count=`bzip2 -cd $file|wc -l`;}
		else{$count=`cat $file|wc -l`;}
		if($count=~/(\d+)/){$count=$1;}
		print $writer "$file\t".$urls->{"file/linecount"}."\t$count\n";
	}
}
############################## sizeFiles ##############################
sub sizeFiles{
	my @files=@_;
	my $writer=shift(@files);
	my $filegrep=shift(@files);
	my $recursivesearch=shift(@files);
	if(!defined($recursivesearch)){$recursivesearch=-1;}
	foreach my $file(listFiles($filegrep,$recursivesearch,@files)){
		my $size=-s $file;
		print $writer "$file\t".$urls->{"file/filesize"}."\t$size\n";
	}
}
############################## md5Files ##############################
sub md5Files{
	my @files=@_;
	my $writer=shift(@files);
	my $filegrep=shift(@files);
	my $recursivesearch=shift(@files);
	if(!defined($recursivesearch)){$recursivesearch=-1;}
	foreach my $file(listFiles($filegrep,$recursivesearch,@files)){
		my $md5=`which md5`;
		my $md5sum=`which md5sum`;
		if(defined($md5)){
			chomp($md5);
			my $sum=`$md5 $file`;
			chomp($sum);
			if($sum=~/(\S+)$/){$sum=$1;}
			print $writer "$file\t".$urls->{"file/md5"}."\t$sum\n";
		}elsif(defined($md5sum)){
			chomp($md5sum);
			my $sum=`$md5sum $file`;
			chomp($sum);
			if($sum=~/^(\S+)/){$sum=$1;}
			print $writer "$file\t".$urls->{"file/md5"}."\t$sum\n";
		}
	}
}
############################## countSequences ##############################
sub countSequences{
	my @files=@_;
	my $writer=shift(@files);
	my $filegrep=shift(@files);
	my $recursivesearch=shift(@files);
	if(!defined($recursivesearch)){$recursivesearch=-1;}
	foreach my $file(listFiles($filegrep,$recursivesearch,@files)){
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
		print $writer "$file\t".$urls->{"file/seqcount"}."\t$count\n";
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
