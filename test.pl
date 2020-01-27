my $outdir=$ARGV[0];
my $label=$ARGV[1];
if(!defined($label)){$label="#splitfile";}
my @files=`ls $outdir`;
foreach my $file(@files){
chomp($file);
if($file=~/^(\w+)\..+\.(\w+)\.fq\.gz$/){
$library=$1;
$barcode=$2;
print "$1.$2\t$label\t$outdir/$file\n";
}
