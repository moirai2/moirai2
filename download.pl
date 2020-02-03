use LWP::UserAgent;
use HTTP::Request;
use File::Basename;
my $url=shift(@ARGV);
my $outdir=shift(@ARGV);
my $agent=new LWP::UserAgent();
$agent->agent('download.pl/1.0');
$agent->timeout(10);
$agent->env_proxy;
my $request=HTTP::Request->new(GET=>$url);
my $filename="$outdir/".basename(dirname($url));
my $res=$agent->request($request);
if($res->is_success){
open(OUT,">$filename");
print OUT $res->content;
close(OUT);
print "$filename\n";
}elsif(
$res->is_error){
exit(1);
}
