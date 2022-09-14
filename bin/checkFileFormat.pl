#!/usr/bin/perl
use strict 'vars';
use Cwd;
use File::Basename;
use File::Temp qw/tempfile tempdir/;
use FileHandle;
use Getopt::Std;
use IO::File;
use Time::localtime;
############################## HEADER ##############################
my ($program_name,$program_directory,$program_suffix)=fileparse($0);
$program_directory=Cwd::abs_path($program_directory);
my $program_path="$program_directory/$program_name";
my $program_version="2022/09/13";
############################## OPTIONS ##############################
use vars qw($opt_l);
getopts('l');
############################## MAIN ##############################
foreach my $file(@ARGV){
    my $fileFormat=guessFileFormatFromFileSuffix($file);
	checkFileIsBinary($file,$fileFormat);
    guessFileFormatFromFirstLine($file,$fileFormat);
    printFinalResult($file,$fileFormat);
	if(defined($opt_l)){printTable($fileFormat);}
}
############################## checkFileIsBinary ##############################
sub checkFileIsBinary{
    my $file=shift();
    my $fileFormat=shift();
    my $filename=basename($file);
    if($filename=~/\.bam$/){$fileFormat->{"binary"}|=1;}
	if(checkBinary($file)){$fileFormat->{"binary"}=2;}
}
############################## printFinalResult ##############################
sub printFinalResult{
    my $file=shift();
    my $fileFormat=shift();
    my @results=sort{$fileFormat->{$b}<=>$fileFormat->{$a}}(keys(%{$fileFormat}));
    my $bestResult=$results[0];
    print "$file\tfileformat\t$bestResult\n";
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
		if(ref($_)eq"ARRAY"){
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
############################## getFirstUncommentLine ##############################
sub getFirstUncommentLine{
    my $file=shift();
    my $reader=openFile($file);
    my $line;
    while(<$reader>){
        if(/^#/){next;}
        chomp;
        $line=$_;
        last;
    }
    close($reader);
    return $line;
}
############################## guessFileFormatFromFileSuffix ##############################
# 1 by file suffix
# 2 by first line of file content
# 4 by entire file content
sub guessFileFormatFromFileSuffix{
    my $file=shift();
    my $fileFormat=shift();
    if(!defined($fileFormat)){$fileFormat={};}
    my $filename=basename($file);
    if($filename=~/^(.+)\.gz(ip)?$/){$filename=$1;$fileFormat->{"GZIPPED"}|=1;}
    if($filename=~/^(.+)\.bz(ip)?2$/){$filename=$1;$fileFormat->{"BZIPPED"}|=1;}
    if($filename=~/^(.+)\.zip$/){$filename=$1;$fileFormat->{"ZIPPED"}|=1;}
    if($filename=~/^(.+)\.tar$/){$filename=$1;$fileFormat->{"TARED"}|=1;}
    if($filename=~/\.f(ast)?a$/){$fileFormat->{"FASTA"}|=1;}
    elsif($filename=~/\.f(sta)?q$/){$fileFormat->{"FASTQ"}|=1;}
    elsif($filename=~/\.bam$/){$fileFormat->{"BAM"}|=1;}
    elsif($filename=~/\.sam$/){$fileFormat->{"SAM"}|=1;}
    elsif($filename=~/\.bed$/){$fileFormat->{"BED"}|=1;}
    elsif($filename=~/\.te?xt$/){$fileFormat->{"TEXT"}|=1;}
    return $fileFormat;
}
############################## checkBinary ##############################
sub checkBinary{
	my $file=shift();
	while(-l $file){$file=readlink($file);}
	my $result=`file --mime $file`;
	if($result=~/charset\=binary/){return 1;}
}
############################## guessFileFormatFromFirstLine ##############################
sub guessFileFormatFromFirstLine{
    my $file=shift();
    my $fileFormat=shift();
    if(!defined($fileFormat)){$fileFormat={};}
    my $firstLine=getFirstUncommentLine($file);
    if($firstLine=~/^>/){$fileFormat->{"FASTA"}|=2;}
    if($firstLine=~/^@/){$fileFormat->{"FASTQ"}|=2;}
	print "firstLine=$firstLine\n";
	if($firstLine=~/\t/){#line contains tab
		my @tokens=split(/\t/,$firstLine);
		my $size=scalar(@tokens);
		if($size>=3){#https://genome.ucsc.edu/FAQ/FAQformat.html#format1
			if($tokens[0]eq""){next;}#chrom
			if($tokens[1]!~/^\d+$/){next;}#start
			if($tokens[2]!~/^\d+$/){next;}#end
			if($size>4&&$tokens[5]!~/[\.\+\-]/){next;}#strand
			$fileFormat->{"BED"}|=2;
		}
		if($size>=11){#https://samtools.github.io/hts-specs/SAMv1.pdf
			if($tokens[1]!~/^\d+$/){next;}#flag
			if($tokens[3]!~/^\d+$/){next;}#pos
			if($tokens[4]!~/^\d+$/){next;}#mapq
			if($tokens[7]!~/^\d+$/){next;}#pnext
			if($tokens[8]!~/^\d+$/){next;}#tlen
			$fileFormat->{"SAM"}|=2;
			$fileFormat->{"BAM"}|=2;
		}
	}#no tab
    return $fileFormat;
}
############################## openFile ##############################
sub openFile{
	my $path=shift();
	if($path=~/^(.+\@.+)\:(.+)$/){
		if($path=~/\.gz(ip)?$/){return IO::File->new("ssh $1 'gzip -cd $2'|");}
		elsif($path=~/\.bz(ip)?2$/){return IO::File->new("ssh $1 'bzip2 -cd $2'|");}
		elsif($path=~/\.bam$/){return IO::File->new("ssh $1 'samtools view $2'|");}
		else{return IO::File->new("ssh $1 'cat $2'|");}
	}else{
		if($path=~/\.gz(ip)?$/){return IO::File->new("gzip -cd $path|");}
		elsif($path=~/\.bz(ip)?2$/){return IO::File->new("bzip2 -cd $path|");}
		elsif($path=~/\.bam$/){return IO::File->new("samtools view $path|");}
		else{return IO::File->new($path);}
	}
}