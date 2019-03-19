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
$program_directory=substr($program_directory,0,-1); # remove last "/"
############################## OPTIONS ##############################
use vars qw($opt_d $opt_h $opt_H $opt_l $opt_m $opt_q $opt_r $opt_s $opt_S);
getopts('d:hHl:m:qr:s:S:');
############################## HELP ##############################
if(defined($opt_h)||defined($opt_H)){
	print "\n";
	print "Program: Go through a list of RDF databases and starts running daemon when if database is updated.\n";
	print "Author: Akira Hasegawa (ah3q\@gsc.riken.jp)\n";
	print "\n";
	print "Usage: $program_name < LIST\n";
	print "       LIST  List of paths to RDF databases\n";
	print "Options: -d  Path to a directory to search and create a list of SQLite databases (default='.').\n";
	print "         -l  Log directory (default='log').\n";
	print "         -m  Max number of jobs to throw (default='5').\n";
	print "         -q  Use qsub for throwing jobs(default='bash').\n";
	print "         -r  Recursive search through a directory (default='0').\n";
	print "         -s  Loop second (default='10sec').\n";
	print "         -S  Load list of databases from STDIN instead from a directory.\n";
	print "\n";
	print "UPDATED: 2019/01/25 - Created to manage multiple RDF databases.\n";
	print "\n";
	exit(0);
}
############################## MAIN ##############################
my $sleeptime=defined($opt_s)?$opt_s:10;
my $recursive_search=defined($opt_r)?$opt_r:0;
my $logdir=defined($opt_l)?$opt_l:"log";
my $databases={};
my $directory=defined($opt_d)?$opt_d:".";
my $md5cmd=(`which md5`)?"md5":"md5sum";
if(defined($opt_S)){while(<STDIN>){chomp;s/\r//g;if(-e $_){$databases->{$_}=0;}}}
while(1){
	if(!defined($opt_S)){foreach my $file(list_files("sqlite3",$recursive_search,$directory)){if(!exists($databases->{$file})){$databases->{$file}=0;}}}
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
			my $command="perl daemon.pl -r -d $database";
			if(defined($opt_q)){$command.=" -q"}
			if(defined($opt_m)){$command.=" -m $opt_m"}
			my $time=time();
			my $datetime=get_date("",$time).get_time("",$time);
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
# list_files($file_suffix,$recursive_search,@input_directories);
sub list_files{
	my @input_directories=@_;
	my $file_suffix=shift(@input_directories);
	my $recursive_search=shift(@input_directories);
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
			if(-d $file){# start recursive search
				if($recursive_search!=0){push(@input_files,list_files($file_suffix,$recursive_search-1,$file));}# do recursive search
				next;# skip directory element
			}elsif($file!~/$file_suffix$/){next;}
			push(@input_files,$file);
		}
		closedir(DIR);
	}
	return @input_files;
}
############################## print_table ##############################
# print multi dimension array/hash/scalar (recursively) for a check purpose - 2007/01/24
# $return_type = "print", "array", "stderr"
# print_table( $return_type, \@array );
# print_table( $return_type, \%hash );
# print_table( \@array );
# print_table()( \%hash );
sub print_table {
	my @out = @_; # things to output
	my $return_type = $out[ 0 ]; # return type
	# convert $return_type from a string into a number
	if( lc( $return_type ) eq "print" ) { $return_type = 0; shift( @out ); } # print out in STDOUT
	elsif( lc( $return_type ) eq "array" ) { $return_type = 1; shift( @out ); } # don't print out, but store in array
	elsif( lc( $return_type ) eq "stderr" ) { $return_type = 2; shift( @out ); } # print out in STDERR
	else { $return_type = 2; } # return type not defined
	print_table_sub( $return_type, "", @out ); # go recursively to sub methods
}
sub print_table_sub {
	my @out = @_; # things to print out
	my $return_type = shift( @out ); # "print", "stderr", or "array"
	my $string = shift( @out ); # current position string '[0]=>   {1}=>   [2]=>   {3}=>   "Akira Hasegawa"'
	my @output = (); # output in array
	for( @out ) { # go through table
		if( ref( $_ ) eq "ARRAY" ) { # ARRAY
			my @array = @{ $_ }; # array to print
			my $size = scalar( @array );
			if( $size == 0 ) {
				if( $return_type == 0    ) { print $string . "[]\n"; } # print
				elsif( $return_type == 1 ) { push( @output, $string . "[]" ); } # array
				elsif( $return_type == 2 ) { print STDERR $string . "[]\n"; } # stderr
			} else {
				for( my $i = 0; $i < $size; $i++ ) { # go through array
					push( @output, print_table_sub( $return_type, $string . "[$i]=>\t", $array[ $i ] ) ); # go recursively
				}
			}
		} elsif( ref( $_ ) eq "HASH" ) { # HASH
			my %hash = %{ $_ }; # hash to print
			my @keys = sort { $a cmp $b } keys( %hash );
			my $size = scalar( @keys );
			if( $size == 0 ) {
				if( $return_type == 0    ) { print $string . "{}\n"; } # print
				elsif( $return_type == 1 ) { push( @output, $string . "{}" ); } # array
				elsif( $return_type == 2 ) { print STDERR $string . "{}\n"; } # stderr
			} else {
				foreach my $key ( @keys ) { # go through hash elements
					push( @output, print_table_sub( $return_type, $string . "{$key}=>\t", $hash{ $key } ) ); # go recursively
				}
			}
		} elsif( $return_type == 0 ) { print "$string\"$_\"\n"; } # print
		elsif( $return_type == 1 ) { push( @output, "$string\"$_\"" ); } # array
		elsif( $return_type == 2 ) { print STDERR "$string\"$_\"\n"; } # stderr
	}
	return wantarray ? @output : $output[ 0 ]; # return constructed array
}
############################## get_date ##############################
# return date by string - 2007/01/24
# my $date = get_date(); returns 20040424
# my $date = get_date( "/" ); returns 2004/04/24
sub get_date {
	my $delim = shift; # delim used between dates
	my $time  = shift; # time
	if( ! defined( $delim ) ) { $delim = ""; }
	if( ! defined( $time ) || $time eq "" ) { $time = localtime(); } # use local time
	else { $time = localtime( $time ); } # use time
	my $year = $time->year + 1900;
	my $month = $time->mon + 1;
	if( $month < 10 ) { $month = "0" . $month; }
	my $day = $time->mday;
	if( $day < 10 ) { $day = "0" . $day; }
	return $year . $delim . $month . $delim . $day;
}
############################## get_time ##############################
# return current time with specified string- 2007/01/24
# my $time = get_time( $delim, $time );
# my $time = get_time(); returns 234500
# my $time = get_time( ":" ); returns 23:45:00
sub get_time {
	my $delim = shift; # delim used between dates
	my $time  = shift; # time
	if( ! defined( $delim ) ) { $delim = ""; }
	if( ! defined( $time ) || $time eq "" ) { $time = localtime(); } # use local time
	else { $time = localtime( $time ); } # use time
	# hour
	my $hour = $time->hour;
	if( $hour < 10 ) { $hour = "0" . $hour; }
	# minute
	my $minute = $time->min;
	if( $minute < 10 ) { $minute = "0" . $minute; }
	#sec
	my $second = $time->sec;
	if( $second < 10 ) { $second = "0" . $second; }
	# return
	return $hour . $delim . $minute . $delim . $second;
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
