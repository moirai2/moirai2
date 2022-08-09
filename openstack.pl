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
my $program_version="2022/03/03";
############################## OPTIONS ##############################
use vars qw($opt_c $opt_d $opt_f $opt_h $opt_i $opt_p $opt_q $opt_r $opt_s);
getopts('c:d:f:hi:p:qr:s:');
############################## LINKS ##############################
# Riken HokusaiSS:  https://hssa.riken.jp/
# Riken HokusaiSS:  https://hssb.riken.jp/
# HokusaiSS Document: http://172.18.93.248
# openrc: https://docs.openstack.org/ja/user-guide/common/cli-set-environment-variables-using-openstack-rc.html
# https://www.yokoweb.net/2020/08/14/ubuntu-20_04-apache-php/
############################## SETTING ##############################
#setting modes
my $modeOpenStackDocker;
my $modeWebService;
my $modeUserAccount;
my $modeOpenStackCli;
my $modeTimezone;
#completed
my $installedOpenStackPerl;
my $installedApachePhp;
my $setupUserAccount;
my $installedOpenStackCli;
my $setupTimezone;
#checks
my $openStackConnectionChecked;
my $openStackPasswordChecked;
#openstack
my $openStackTimezone="Asia/Tokyo";
my $openStackEnvironment="HOKUSAI";
my $openStackDockerImage="moirai2/openstack";
my $openStackRootUser="ubuntu";
my $openrcLines;
my $openStackMoiraiId;
my $openStackPassword;
my $openStackProjectName;
#singularity
my $goVersion="1.17.4";
my $singularityVersion="3.9.1";
#docker
my $dockerComposeVersion="1.27.3";
#lists
my $flavorLists;
my $imageLists;
my $networkLists;
my $securityGroupLists;
#server
my $defaultUserPassword="password";
my $serverFlavor;
my $serverImage;
my $serverInstance;
my $serverIP;
my $rootKeyPair;
my $serverKeyPair;
my $serverNetwork;
my $serverPassword;
my $serverPort;
my $serverSecurityGroup;
my $serverPublicKey;
my $serverOpenStackPerlPath;
my $serverRootDir;
my $serverMaxJob=5;
#node
my $nodeInstance;
############################## HELP ##############################
sub help{
	print "\n";
	print "Program: Utilities for handling openstack.\n";
	print "Version: $program_version\n";
	print "Author: Akira Hasegawa (akira.hasegawa\@riken.jp)\n";
	print "\n";
	print "Usage: perl $program_name [options] COMMAND\n";
	print "\n";
	print "Commands:\n";
	print "  add node             Create new computational instance\n";
	print "  add user             Add new user to the server\n";
	print "  check connection     Check connection with openstackservice\n";
	print "  check docker         Check if Docker and openstack are installed correctly\n";
	print "  check file           Check if exists on the server\n";
	print "  check password       Check password for openstack is correct\n";
	print "  config server        Setup server configuration\n";
	print "  config user          Setup user configuration\n";
	print "  config time          Setup timezone on the server\n";
	print "  create keypair       Create keypair for openstack\n";
	print "  create singularity   Create ubuntu instance with singularity installed\n";
	print "  docker login         Enter docker openstack instance in BASH\n";
	print "  info group           Show group info\n";
	print "  info user            Show user info\n";
	print "  list openstack       List up openstack lists\n";
	print "  list flavors         List up flavors\n";
	print "  list images          List up images\n";
	print "  list securityGroups  List up securityGroups\n";
	print "  list networks        List up networks\n";
	print "  list ports           List up ports\n";
	print "  list keypairs        List up keypairs\n";
	print "  list servers         List up servers\n";
	print "  install apache       Install Apache2+php on the server\n";
	print "  install bigwig       Install bigwig tools on the server\n";
	print "  install django       Install django on the server\n";
	print "  install docker       Install docker on the server\n";
	print "  install jupyter      Install jupyter on the server\n";
	print "  install openstack    Install openstack CLI on the server\n";
	print "  install singularity  Install singularity on the server\n";
	print "  log                  Print out log\n";
	print "  php info             Open php info page with browser\n";
	print "  print fingerprint    Print fingerprint of user's ssh-key\n";
	print "  print openrc         Print out openrc content\n";
	print "  print userdata       Print out userdata content\n";
	print "  reload lists         Reload flavors/images/securityGroups/networks lists\n";
	print "  remove node          Remove computational instance node created\n";
	print "  remove singularity   Remove singularity snapshot instance created\n";
	print "  reset config         Reset all openstack/server configurations\n";
	print "  run                  Create instance, execute command line, and close instance\n";
	print "  setup                Setup docker-compose\n";
	print "  ssh                  Access openstack service server through SSH\n";
	print "  start server         Start openstack server service\n";
	print "  stop server          Stop openstack server service\n";
	print "  transfer instance    Transfer snapshot instance from project to project\n";
	print "  transfer keys        Transfer .ssh/authorized_keys from ubuntu user to user\n";
	print "  upload openstack.pl  Upload this script to the server\n";
	print "\n";
}
############################## MAIN ##############################
if(defined($opt_h)){helpMenu();exit();}
my $sleepTime=defined($opt_s)?$opt_s:60;
my $user=`whoami`;
chomp($user);
my $workdir=Cwd::abs_path();
my $openstackdir=defined($serverRootDir)?$serverRootDir:".openstack";
my $bashdir="$openstackdir/bash";
my $completedir="$openstackdir/complete";
my $stderrdir="$openstackdir/stderr";
my $stdoutdir="$openstackdir/stdout";
my $logdir="$openstackdir/log";
mkdir($openstackdir);
mkdir($bashdir);
mkdir($completedir);
mkdir($stderrdir);
mkdir($stdoutdir);
mkdir($logdir);
chmod(0711,$openstackdir);
chmod(0700,$bashdir);
chmod(0700,$completedir);
chmod(0700,$stderrdir);
chmod(0700,$stdoutdir);
chmod(0700,$logdir);
my $logFile="$logdir/".getDate().".txt";
my $dockerExecCommand="docker run --rm -v $workdir:/home/$user --workdir /home/$user $openStackDockerImage";
my $dockerLoginCommand="docker run -it --rm -v $workdir:/home/$user --workdir /home/$user $openStackDockerImage";
if(defined($opt_p)){$openStackPassword=$opt_p;}
#Not recommended to write password in option, since other user can see the detail of a command
my $command=shift(@ARGV);
if($command=~/^add$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^node$/i){my $ip=addNodeInstance($opt_i,$opt_f);print "$ip\n";}
		elsif($arg=~/^user$/i){addUserToServer(@ARGV);}
	}
}elsif($command=~/^check$/i){
	my $hash={};
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^docker$/i){checkDockerOpenstack();}
		elsif($arg=~/^file$/i){print fileExists(@ARGV)."\n";}
		elsif($arg=~/^password$/i){if(checkOpenStackPassword($hash)){replaceVariableFromThisScript($hash);}}
		elsif($arg=~/^connection$/i){if(checkConnectionWithOpenStack($hash)){replaceVariableFromThisScript($hash);}}
	}
}elsif($command=~/^config$/i){
	if(scalar(@ARGV)>0){
		my $hash={};
		my $arg=shift(@ARGV);
		if($arg=~/^server$/i){
			initialize();
			initServer();
			configServer();
			if(defined($serverInstance)){setupServer();}
		}elsif($arg=~/^time$/i){setServerTimezone(@ARGV);}
	}
}elsif($command=~/^create$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^keypair$/i){createKeyPair(@ARGV);}
		elsif($arg=~/^docker$/i){createDockerSnapshot(@ARGV);}
		elsif($arg=~/^singularity$/i){createSingularitySnapshot(@ARGV);}
	}
}elsif($command=~/^docker$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^login$/i){system("$dockerLoginCommand bash");}
	}
}elsif($command=~/^info$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if(!defined($arg)){$arg="openstack";}
		if($arg=~/^openstack$/i){printInfo();}
		elsif($arg=~/^user$/i){my $hash=getUserInfo(@ARGV);print jsonEncode($hash)."\n";}
		elsif($arg=~/^group$/i){my $hash=getGroupInfo(@ARGV);print jsonEncode($hash)."\n";}
	}
}elsif($command=~/^install$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^apache$/i){installApachePhpOnServer(@ARGV);}
		elsif($arg=~/^django$/i){installDjangoOnServer(@ARGV);}
		elsif($arg=~/^docker$/i){installDockerOnServer(@ARGV);}
		elsif($arg=~/^openstack$/i){installOpenstackOnServer(@ARGV);}
		elsif($arg=~/^singularity$/i){installSingularityOnServer(@ARGV);}
	}
}elsif($command=~/^list$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^openstack$/i){printInfo();}
		elsif($arg=~/^servers$/i){initialize();printRows(listServers(),["Flavor","Image","Name","Status"]);}
		elsif($arg=~/^flavors$/i){initialize();printRows(listFlavors(),["Disk","Name","RAM","VCPUs"]);}
		elsif($arg=~/^images$/i){initialize();printRows(listImages(),["Name","Status"]);}
		elsif($arg=~/^securitygroups$/i){initialize();printRows(listSecurityGroups(),["Name"]);}
		elsif($arg=~/^networks$/i){initialize();printRows(listNetworks(),["Name"]);}
		elsif($arg=~/^keypairs$/i){initialize();printRows(listKeyPairs(),["Name","Type","Fingerprint"]);}
		elsif($arg=~/^ports$/i){
			initialize();
			my $portLists=listPorts();
			foreach my $port(@{$portLists}){
				my $address=$port->{"Fixed IP Addresses"};
				foreach my $hash(@{$address}){$port->{"ip_address"}=$hash->{"ip_address"};}
			}
			printRows($portLists,["Name","Status","ip_address"]);
		}
	}
}elsif($command=~/^log$/i){
	printLogs();
}elsif($command=~/^php$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^disco$/i){system("open http://$serverIP/info.php");}
		elsif($arg=~/^maxsize$/i){phpSetMaxSize(@ARGV);}
	}
}elsif($command=~/^print$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^fingerprint$/i){print getSshFingerPrint()."\n";}
		elsif($arg=~/^openrc$/i){printOpenrcFile();}
		elsif($arg=~/^userdata$/i){printUserData();}
	}
}elsif($command=~/^reload$/i){
	my $hash={};
	if(reloadLists($hash,"force")){replaceVariableFromThisScript($hash);}
}elsif($command=~/^remove$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^node$/i){removeNode(@ARGV);}
	}
}elsif($command=~/^reset$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^config$/i){resetSetting();}
	}
}elsif($command=~/^run$/i){
	runCommand(join(" ",@ARGV));
}elsif($command=~/^sort$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^subs$/i){sortSubs(@ARGV);}
	}
}elsif($command=~/^snapshot$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^instance$/i){
			my $name=$ARGV[0];
			snapshotInstanceGracefully(@ARGV);
		}
	}
}elsif($command=~/^ssh$/i){
	promptSsh();
}elsif($command=~/^start$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^server$/i){
			initialize();
			initServer();
			configServer();
			startServer();
			setupServer();
		}
	}
}elsif($command=~/^stop$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^server$/i){
			my $array=[];
			if(stopServer($array)){resetVariableFromThisScript(@{$array});}
		}
	}else{helpStop();}
}elsif($command=~/^test$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^moo$/i){testMoo();}
	}else{test();}
}elsif($command=~/^transfer$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^keys$/i){transferAuthorizedKeys(@ARGV);}
		elsif($arg=~/^instance$/i){transferInstance(@ARGV);}
	}
}elsif($command=~/^upload$/i){
	if(scalar(@ARGV)>0){
		my $arg=shift(@ARGV);
		if($arg=~/^openstack.pl$/i){uploadOpenstackScriptToInstance(@ARGV);}
	}
}
############################## addFloatingIP ##############################
sub addFloatingIP{
	my $instance=shift();
	my $ip=shift();
	if(!defined($opt_q)){print ">Adding floating IP to the server instance...  ";}
	if(!defined($instance)){
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "ERROR: Please specify instance\n";
		exit(1);
	}
	if(!defined($ip)){
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "ERROR: Please specify IP\n";
		exit(1);
	}
	my $result=getResultFromOpenstack("openstack server add floating ip $instance $ip");
	if($result){
		if(!defined($opt_q)){print "OK\n";}
	}else{
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "ERROR: Couldn't add floating IP '$ip' to '$instance'\n";
		exit(1);
	}
	return checkServerConnection($ip,$instance);
}
############################## addGroupToServer ##############################
sub addGroupToServer{
	my $ip=shift();
	my $groups=shift();
	if(!defined($groups)){print STDERR "Please specify group\n";return;}
	if(!defined($ip)){$ip=$serverIP;}
	my $info=getGroupInfo(undef,$ip);
	my $used={};
	foreach my $hash(values(%{$info})){$used->{$hash->{"id"}}=1;}
	my @names=();
	my $ids={};
	foreach my $name(keys(%{$groups})){
		my $id=$groups->{$name};
		if($name=~/^_/){next;}#ubuntu addgroup doesn't like '_'
		if(exists($used->{$id})){next;}
		if(exists($info->{$name})){next;}
		push(@names,$name);
		$ids->{$name}=$id;
	}
	if(scalar(@names)==0){return 1;}
	if(!defined($opt_q)){print ">Adding groups '".join("','",@names)."' to '$ip'...  ";}
	my @commands=();
	foreach my $name(@names){push(@commands,"sudo addgroup --gid ".$ids->{$name}." $name");}
	if(!executeCommands($ip,\@commands)){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## addNodeInstance ##############################
sub addNodeInstance{
	my $nodeImage=shift();
	my $nodeFlavor=shift();
	if(!defined($nodeFlavor)){$nodeFlavor=promptFlavor();}
	elsif(!existsFlavor($nodeFlavor)){print STDERR "ERROR: Flavor '$nodeFlavor' your specified doens't exist\n";exit(1);}
	if(!defined($nodeImage)){$nodeImage=promptImage();}
	elsif(!existsImage($nodeImage)){print STDERR "ERROR: Image '$nodeImage' your specified doens't exist\n";exit(1);}
	my $keyPair=createUserKeyPair();
	my $nodeSecurityGroup=promptSecurityGroup();
	my $nodeNetwork=promptNetwork();
	my $nodePort=chooseServerPort();
	my $name="$openStackMoiraiId-node-".getDatetime();
	my $sshDir=$ENV{"HOME"}."/.ssh";
	transferAuthorizedKeys("$sshDir/id_rsa.pub","$sshDir/authorized_keys");
	waitForAllInstanceToComplete();
	$nodeInstance=createInstance($nodeFlavor,$nodeImage,$keyPair,$nodeSecurityGroup,$nodeNetwork,$nodePort,$name,$serverPassword);
	my $ip=getIpFromInstance($name);
	if(!checkServerIsUpByPing($ip)){exit(1);}
	removeKnownHosts($ip);
	if(!checkServerConnection($ip,$name)){exit(1);}
	if(!uploadOpenstackScriptToInstance($ip,$serverOpenStackPerlPath)){exit(1);}
	if(!addUserToServer($user,$ip,undef,undef,1)){exit(1);}
	if(!setServerTimezone($openStackTimezone,$ip)){exit(1);}
	if(!replaceUbuntuAuthoriedKeys($ip)){exit(1);}
	return $ip;
}
############################## addUbuntuSshKeyToUser ##############################
sub addUbuntuSshKeyToUser{
	my $user=shift();
	my $ip=shift();
	if(!defined($ip)){print STDERR "ERROR: Please specify IP\n";exit(1);}
	if(!defined($opt_q)){print ">Copying ubuntu ssh key to user '$user'...  ";}
	my @commands=();
	push(@commands,"sudo cp ~/.ssh/id_rsa ~$user/.ssh/.");
	push(@commands,"sudo chown $user ~$user/.ssh/id_rsa");
	push(@commands,"sudo chgrp $user ~$user/.ssh/id_rsa");
	push(@commands,"sudo chmod 600 ~$user/.ssh/id_rsa");
	push(@commands,"sudo cp ~/.ssh/id_rsa.pub ~$user/.ssh/.");
	push(@commands,"sudo chown $user ~$user/.ssh/id_rsa.pub");
	push(@commands,"sudo chgrp $user ~$user/.ssh/id_rsa.pub");
	push(@commands,"sudo chmod 644 ~$user/.ssh/id_rsa.pub");
	if(!executeCommands($ip,\@commands)){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## addUserToServer ##############################
sub addUserToServer{
	my $user=shift();
	my $ip=shift();
	my $uid=shift();
	my $gid=shift();
	my $copy=shift();
	if(!defined($user)){print STDERR "Please specify user\n";return;}
	if(!defined($ip)){
		if(defined($serverIP)){$ip=$serverIP;}
		else{print STDERR "Please specify IP\n";return;}
	}
	my $info=getUserInfo($user,$ip);
	if(defined($info)){return 1;}
	my $original=getUserInfo($user);
	my $group;
	my $groups;
	if($copy&&defined($original)){
		$group=$original->{"group"}->{"name"};
		$groups=$original->{"groups"};
		$uid=$original->{"user"}->{"id"};
		$gid=$original->{"group"}->{"id"};
		addGroupToServer($ip,$groups);
	}
	if(!defined($opt_q)){print ">Adding user '$user' to '$ip'...  ";}
	my @commands=();
	my $command="sudo adduser";
	if(defined($uid)){$command.=" --uid $uid";}
	if(defined($gid)){$command.=" --gid $gid";}
	$command.=" $user << EOF";
	push(@commands,$command);
	push(@commands,$defaultUserPassword);
	push(@commands,$defaultUserPassword);
	push(@commands,"");
	push(@commands,"");
	push(@commands,"");
	push(@commands,"");
	push(@commands,"");
	push(@commands,"");
	push(@commands,"");
	push(@commands,"");
	push(@commands,"");
	push(@commands,"EOF");
	foreach my $name(keys(%{$groups})){push(@commands,"sudo adduser $user $name");}
	if(defined($group)){$group=$user;}
	if(!executeCommands($ip,\@commands)){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## changeOwnerGroup ##############################
sub changeOwnerGroup{
	my @files=@_;
	my $owner=shift(@files);
	my $group=shift(@files);
	my $commands=shift(@files);
	foreach my $file(@files){
		push(@{$commands},"sudo chown $owner $file");
		if(defined($group)){push(@{$commands},"sudo chgrp $group $file");}
		else{push(@{$commands},"sudo chgrp $owner $file");}
	}
}
############################## checkCommand ##############################
sub checkCommand{
	my $command=shift();
	my $result=`which $command`;
	chomp($result);
	return ($result ne"");
}
############################## checkConnectionWithOpenStack ##############################
sub checkConnectionWithOpenStack{
	if($openStackConnectionChecked){return 1;}
	my $hash=shift();
	if(!defined($hash)){$hash={};}
	checkOpenrcLines($hash);
	if(!defined($opt_q)){print ">Checking connection with openstack service...  ";}
	my $url;
	foreach my $line(@{$openrcLines}){if($line=~/^export OS_AUTH_URL\=(\S+)$/){$url=$1;}}
	if(!defined($url)){
		print STDERR "OS_AUTH_URL not defined in XXXXXXX_openrc.sh file.\n";
		replaceVariableFromThisScript($hash);
		exit(1);
	}
	my $result=`curl -s --connect-timeout 5 $url`;
	chomp($result);
	if($result eq""){
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "ERROR: Coudln't connect to openstack URL specified in XXXXXXX_openrc.sh file\n";
		print STDERR "        Check your internet environment or turn on VPN?\n";
		replaceVariableFromThisScript($hash);
		exit(1);
	}
	if(!defined($opt_q)){print "OK\n";}
	$openStackConnectionChecked=1;
	return 1;
}
############################## checkDockerOpenstack ##############################
sub checkDockerOpenstack{
	if(!defined($modeOpenStackDocker)){
		my $hash={};
		$modeOpenStackDocker=promptYesNo("Do you want Docker for openstack commands");
		$hash->{"\$modeOpenStackDocker"}=$modeOpenStackDocker;
		replaceVariableFromThisScript($hash);
	}
	if(!defined(checkDockerVersion())){
		print STDERR "ERROR: Docker not installed\n";
		print STDERR "ERROR: Please install Docker from https://docker.com/\n";
		exit(1);
	}
	if(!checkOpenStackDockerImage()){
		createOpenstackDockerImage();
		if(!checkOpenStackDockerImage()){
			print STDERR "ERROR: $openStackDockerImage Docker image doesn't exist\n";
			print STDERR "ERROR: Please prepare $openStackDockerImage Docker image\n";
			exit(1);
		}
	}
	if(!defined(checkOpenStackVersion())){
		print STDERR "ERROR: openstack not properly installed\n";
		print STDERR "ERROR: Please check Docker, Docker Image, and its setting\n";
		exit(1);
	}
	if(checkOpenstackIsOutdated()){
		print STDERR "ERROR: openStack client is outdated, so rebuilding doker image\n";
		if(!executeCommands(undef,["docker rmi $openStackDockerImage"])){
			print STDERR "ERROR: Couldn't delete docker image\n";
			exit(1);
		}
		createOpenstackDockerImage();
		if(!checkOpenStackDockerImage()){
			print STDERR "ERROR: $openStackDockerImage Docker image doesn't exist\n";
			print STDERR "ERROR: Please prepare $openStackDockerImage Docker image\n";
			exit(1);
		}
	}
}
############################## checkDockerVersion ##############################
sub checkDockerVersion{
	if(!defined($opt_q)){print ">Checking docker version...  ";}
	my @lines=`docker version`;
	my $version;
	foreach my $line(@lines){
		chomp;$line=~s/\r//g;
		if($line=~/Version\:\s+(\d+\.\d+\.\d+)/){$version=$1;last;}
	}
	if(!defined($opt_q)){print "$version\n";}
	return $version;
}
############################## checkFilePath ##############################
sub checkFilePath{
	my $path=shift();
	if(!defined($path)){print STDERR "Please specify path\n";return;}
	while(! -e $path){
		print STDERR "'$path' does NOT exit. please re-enter: ";
		$path=<STDIN>;
		chomp($path);
		if($path eq ""){print STDERR "ERROR: filepath NOT specified...  quit\n";last;}
	}
	return $path;
}
############################## checkInstanceIsRunning ##############################
sub checkInstanceIsRunning{
	my $name=shift();
	if(!defined($name)){return;}
	my $servers=listServers();
	foreach my $server(@{$servers}){
		if($server->{"Name"}ne$name){next;}
		if($server->{"Status"}eq"ACTIVE"){return 1;}
		print STDERR "ERROR: Instance '$name' is found but not ACTIVE\n";
		return;
	}
	print STDERR "ERROR: Couldn't find instance '$name' in the list\n";
}
############################## checkOpenStackDockerImage ##############################
sub checkOpenStackDockerImage{
	my @lines=`docker images`;
	foreach my $line(@lines){
		chomp($line);
		if($line=~/$openStackDockerImage/){return 1;}
	}
}
############################## checkOpenStackPassword ##############################
sub checkOpenStackPassword{
	if($openStackPasswordChecked){return 1;}
	my $hash=shift();
	if(!defined($hash)){$hash={};}
	if(!defined($modeOpenStackDocker)){
		if(checkCommand("openstack")){$modeOpenStackDocker=0;}
		else{$modeOpenStackDocker=promptYesNo("Do you want to use Docker for executing openstack commands");}
		$hash->{"\$modeOpenStackDocker"}=$modeOpenStackDocker;
	}
	if(!defined($openStackPassword)){$openStackPassword=promptPassword("Please enter password to access openstack: ");}
	checkConnectionWithOpenStack($hash);
	if(!defined($opt_q)){print ">Verifying openstack password...  ";}
	my $json=getJsonFromOpenstack("openstack token issue -f json");
	if(scalar(keys(%{$json}))==0){
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "ERROR: Failed to verify openstack password.  Password your entered is wrong\n";
		exit(1);
	}
	if(!defined($opt_q)){print "OK\n";}
	$openStackPasswordChecked=1;
	return 1;
}
############################## checkOpenStackVersion ##############################
sub checkOpenStackVersion{
	if(!defined($opt_q)){print ">Checking openstack client version...  ";}
	my $command=($modeOpenStackDocker)?$dockerExecCommand:"";
	my @lines=`$command openstack --version`;
	my $version;
	foreach my $line(@lines){
		chomp($line);$line=~s/[\r\t\n\r\f\b\a\e]//g;#openstack returns strange characters...
		if($line=~/(\d+\.\d+\.\d+)/){$version=$1;}
	}
	if(!defined($opt_q)){print "$version\n";}
	return $version;
}
############################## checkOpenrcLines ##############################
sub checkOpenrcLines{
	my $hash=shift();
	if(!defined($hash)){$hash={};}
	if(defined($openrcLines)){return;}
	my $openrcPath=(defined($opt_r))?$opt_r:undef;
	if(!defined($openrcPath)){$openrcPath=promptString("Please enter path to your openstack XXXXXXX_openrc.sh: ");}
	if(!loadOpenrcCommands($openrcPath,$hash)){
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "ERROR: Failed to load XXXXXXX_openrc.sh file\n";
		replaceVariableFromThisScript($hash);
		exit(1);
	}
	if(!defined($openStackProjectName)){
		foreach my $line(@{$openrcLines}){
			if($line=~/^export OS_PROJECT_NAME\=\"(\S+)\"$/){
				$openStackProjectName=$1;
				$hash->{"\$openStackProjectName"}=$openStackProjectName;
			}elsif($line=~/^export OS_TENANT_NAME=\"(\w+)\"$/){
				#https://docs.openstack.org/ja/user-guide/common/cli-set-environment-variables-using-openstack-rc.html
				$openStackProjectName=$1;
				$hash->{"\$openStackProjectName"}=$openStackProjectName;
			}
		}
		if(!defined($openStackProjectName)){
			print STDERR "ERROR: OS_PROJECT_NAME not found in XXXXXXX_openrc.sh\n";
			exit(1);
		}
	}
	return $openrcPath;
}
############################## checkOpenstackIsOutdated ##############################
sub checkOpenstackIsOutdated{
	if(!defined($opt_q)){print ">Checking openstack client is latest...  ";}
	my $command=($modeOpenStackDocker)?$dockerExecCommand:"";
	my @lines=`$command pip list --outdated`;
	my $version;
	foreach my $line(@lines){if($line=~/python-openstackclient\s+(\S+)\s+(\S+)/){$version=$2;}}
	if(!defined($opt_q)){print "OK\n";}
	if(defined($version)){
		if(!defined($opt_q)){print "\n";}
		print STDERR "#WARNING openstack client version $version is available\n";
	}
	return $version;
}
############################## checkServerConnection ##############################
sub checkServerConnection{
	my $ip=shift();
	my $hostname=shift();
	my $numberOfTries=6;
	if(!defined($opt_q)){print ">Checking '$ip' connection with name '$hostname'...";}
	if(!defined($ip)||!defined($hostname)){
		if(!defined($opt_q)){print "  FAIL\n";}
		print STDERR "ERROR: IP or hostname are not defined.\n";
		exit(1);
	}
	my $result=`ssh -o "ConnectTimeout 5" -oStrictHostKeyChecking=no $openStackRootUser\@$ip hostname 2> /dev/null`;
	chomp($result);
	if(defined($opt_q)){STDOUT->autoflush(1);}
	for(my $i=0;$i<$numberOfTries&&$result eq "";$i++){
		if(!defined($opt_q)){print ".";}
		sleep(10);
		$result=`ssh -o "ConnectTimeout 5" -oStrictHostKeyChecking=no $openStackRootUser\@$ip hostname 2> /dev/null`;
		chomp($result);
	}
	if($result=~/Operation timed out/){
		if(!defined($opt_q)){
			print "  FAIL\n";
			STDOUT->autoflush(0);
		}
		print STDERR "ERROR: Coudln't connect to the server\n";
		exit(1);
	}elsif($result=~/$hostname/){
		if(!defined($opt_q)){
			print "  OK\n";
			STDOUT->autoflush(0);
		}
		return 1;
	}else{
		if(!defined($opt_q)){
			print "  FAIL\n";
			STDOUT->autoflush(0);
		}
		print STDERR "ERROR: Hostname '$hostname' didn't match with the server hostname\n";
		exit(1);
	}
}
############################## checkServerIsUpByPing ##############################
sub checkServerIsUpByPing{
	my $ip=shift();
	if(!defined($opt_q)){
		STDOUT->autoflush(1);
		print ">Checking '$ip' is accessible by sending ping..";
	}
	my $result=`ping -c 1 -t 1 $ip`;
	my $count=20;
	for(my $i=0;$i<$count;$i++){
		if($result=~/1 packets transmitted, 1 received, 0% packet loss/){
			if(!defined($opt_q)){
				print "  OK\n";
				STDOUT->autoflush(0);
			}
			return 1;
		}
		if(!defined($opt_q)){print ".";}
		$result=`ping -c 1 -t 1 $ip`;
	}
	if(!defined($opt_q)){
		print "  ERROR\n";
		STDOUT->autoflush(0);
	}
	print STDERR "ERROR: Tried sending $count pings, but server '$ip' didn't respond.\n";
	return;
}
############################## checkUserDirectory ##############################
sub checkUserDirectory{
	# .ssh 0700
	# .ssh/authorized_keys 0600
	# .bash_logout 0644
	# .bashrc 0644
	# .profile 0644
	# .ssh/id_rsa 0600
	# .ssh/id_rsa.pub 0644
	# Make sure user and group are set correctly
}
############################## chooseComputationFlavor ##############################
sub chooseComputationFlavor{
	my $flavors=shift();
	my $cpu=shift();
	if(!defined($cpu)){$cpu=2;}
	my $memory=shift();
	if(defined($memory)){$memory*=1024;}#1GB=1024MB
	my $storage=shift();
	my $index;
	my $size=scalar(@{$flavors});
	for(my $i=0;$i<$size;$i++){
		my $flavor=$flavors->[$i];
		if(defined($cpu)&&$flavor->{"VCPUs"}!=$cpu){next;}
		if(defined($memory)&&$flavor->{"RAM"}!=$memory){next;}
		if(defined($storage)&&$flavor->{"Disk"}!=$storage){next;}
		$index=$i;
	}
	if(!defined($index)){
		print STDERR "ERROR: No flavor with a good VCPUs was found.\n";
		exit(1);
	}
	return $flavors->[$index]->{"Name"};
}
############################## chooseFloatingIP ##############################
sub chooseFloatingIP{
	my $index;
	my $ips=listFloatingIPs();
	my $size=scalar(@{$ips});
	for(my $i=0;$i<$size;$i++){
		my $ip=$ips->[$i];
		if($ip->{"Fixed IP Address"}ne"null"){next;}
		$index=$i;
	}
	if(!defined($index)){
		print STDERR "ERROR: No available floating IP was found.\n";
		exit(1);
	}
	return $ips->[$index]->{"Floating IP Address"};
}
############################## chooseServerFlavor ##############################
sub chooseServerFlavor{
	my $flavors=shift();
	my $minimum;
	my $index;
	my $size=scalar(@{$flavors});
	for(my $i=0;$i<$size;$i++){
		my $flavor=$flavors->[$i];
		if(!defined($minimum)){$minimum=$flavor->{"VCPUs"};$index=$i;}
		elsif($flavor->{"VCPUs"}<$minimum){$minimum=$flavor->{"VCPUs"};$index=$i;}
	}
	if(!defined($index)){
		print STDERR "ERROR: No flavor with a good VCPUs was found.\n";
		exit(1);
	}
	return $flavors->[$index]->{"Name"};
}
############################## chooseServerImage ##############################
sub chooseServerImage{
	my $images=shift();
	my $index;
	my $size=scalar(@{$images});
	for(my $i=0;$i<$size;$i++){
		my $image=$images->[$i];
		my $name=$image->{"Name"};
		if($openStackEnvironment eq "HOKUSAI" && $name!~/Lustre/i){next;}
		if($name=~/Ubuntu/i){$index=$i;}
	}
	if(!defined($index)){
		print STDERR "ERROR: No image with 'Ubuntu' as a name was found.\n";
		exit(1);
	}
	return $images->[$index]->{"Name"};
}
############################## chooseServerNetwork ##############################
sub chooseServerNetwork{
	my $networks=shift();
	my $index;
	my $size=scalar(@{$networks});
	if($openStackEnvironment eq "HOKUSAI"){
		for(my $i=0;$i<$size;$i++){
			my $network=$networks->[$i];
			my $name=$network->{"Name"};
			if($name=~/$openStackProjectName/i){$index=$i;}
		}
	}
	if(!defined($index)){
		print STDERR "ERROR: No network with correct project was found\n";
		exit(1);
	}
	return $networks->[$index]->{"Name"};
}
############################## chooseServerPort ##############################
sub chooseServerPort{
	my $ports=listPorts();
	my $index;
	my $size=scalar(@{$ports});
	my @lists=();
	if($openStackEnvironment eq "HOKUSAI"){
		for(my $i=0;$i<$size;$i++){
			my $port=$ports->[$i];
			my $name=$port->{"Name"};
			if($name!~/$openStackProjectName-storage-port/i){next;}
			if($port->{"Status"} eq "DOWN"){$index=$i;last;}
			push(@lists,$name);
		}
	}
	if(!defined($index)){$index=rand(scalar(@lists));}
	return $ports->[$index]->{"ID"};
}
############################## chooseServerSecurityGroup ##############################
sub chooseServerSecurityGroup{
	my $groups=shift();
	my $index;
	my $size=scalar(@{$groups});
	if($openStackEnvironment eq "HOKUSAI"){
		for(my $i=0;$i<$size;$i++){
			my $group=$groups->[$i];
			my $name=$group->{"Name"};
			if($name=~/$openStackProjectName/i){$index=$i;}
		}
	}
	if(!defined($index)){
		print STDERR "ERROR: No good security group was found\n";
		exit(1);
	}
	return $groups->[$index]->{"Name"};
}
############################## createFlavor ##############################}
sub createFlavor{
	# openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
}
############################## configServer ##############################
sub configServer{
	my $hash={};
	reloadLists($hash);
	if(!defined($serverFlavor)){
		$serverFlavor=chooseServerFlavor($flavorLists);
		$hash->{"\$serverFlavor"}=$serverFlavor;
	}
	if(!defined($serverImage)){
		$serverImage=chooseServerImage($imageLists);
		$hash->{"\$serverImage"}=$serverImage;
	}
	if(!defined($serverNetwork)){
		$serverNetwork=chooseServerNetwork($networkLists);
		$hash->{"\$serverNetwork"}=$serverNetwork;
	}
	if(!defined($serverSecurityGroup)){
		$serverSecurityGroup=chooseServerSecurityGroup($securityGroupLists);
		$hash->{"\$serverSecurityGroup"}=$serverSecurityGroup;
	}
	if(!defined($serverPort)){
		$serverPort=chooseServerPort();
		$hash->{"\$serverPort"}=$serverPort;
	}
	if(!defined($rootKeyPair)){
		my $name="$openStackMoiraiId-root-keypair";
		if(!existsKeyPair($name)){
			my $publicKey=createSshKey();
			$rootKeyPair=createKeyPair($publicKey,$name);
			if(!defined($rootKeyPair)){replaceVariableFromThisScript($hash);exit(1);}
		}else{$rootKeyPair=$name;}
		$hash->{"\$rootKeyPair"}=$rootKeyPair;
	}
	replaceVariableFromThisScript($hash);
}
############################## createDefaultInstance ##############################
sub createDefaultInstance{
	my $name=shift();
	my $ip=shift();
	my $instance=getInstance($name);
	if(defined($instance)){return $instance;}
	configServer();
	my $nodeFlavor=chooseComputationFlavor($flavorLists);
	my $nodeImage=$serverImage;
	my $nodeSecurityGroup=$serverSecurityGroup;
	my $nodeNetwork=$serverNetwork;
	my $nodePort=chooseServerPort();
	$instance=createInstance($nodeFlavor,$nodeImage,$rootKeyPair,$nodeSecurityGroup,$nodeNetwork,$nodePort,$name,$serverPassword);
	removeKnownHosts($ip);
	if(defined($ip)){#created from root local computer
		addFloatingIP($name,$ip);
		$instance=getInstance($name);
	}else{#created from root server computer
		$ip=getIpFromInstance($instance);
		if(!checkServerIsUpByPing($ip)){exit(1);}
		if(!checkServerConnection($ip,$name)){exit(1);}
	}
	return $instance;
}
############################## createDockerSnapshot ##############################
sub createDockerSnapshot{
	my $name=shift();
	my $ip=shift();
	initialize();
	if(!defined($name)){$name="snapshot-docker";}
	if(existsImage($name)){print STDERR "Snapshot '$name' already exists.\n";return 1;}
	if(!defined($ip)){$ip=chooseFloatingIP();}
	elsif($ip!~/^[\d\.]+$/){$ip=undef;}
	my $instance=createDefaultInstance($name,$ip);
	if(!defined($ip)){$ip=getIpFromInstance($instance);}
	installDockerOnServer($ip);
	snapshotInstanceGracefully($name,$name);
	deleteInstanceGracefully($name);
	replaceVariableFromThisScript({"\$imageLists"=>listImages()});
	return 1;
}
############################## createInstance ##############################
# https://docs.openstack.org/ja/user-guide/cli-nova-launch-instance-from-image.html
sub createInstance{
	my $flavor=shift();
	my $image=shift();
	my $keyname=shift();
	my $securitygroup=shift();
	my $network=shift();
	my $port=shift();
	my $name=shift();
	my $password=shift();
	my $userdata=shift();
	my $property=shift();
	if(!defined($opt_q)){print ">Creating '$name' instance...  ";}
	if(!defined($flavor)){print "FAIL\n";print STDERR "ERROR: Flavor not defined";exit(1);}
	if(!defined($image)){print "FAIL\n";print STDERR "ERROR: Image not defined";exit(1);}
	if(!defined($keyname)){print "FAIL\n";print STDERR "ERROR: User keypair not defined";exit(1);}
	if(!defined($securitygroup)){print "FAIL\n";print STDERR "ERROR: Security group not defined";exit(1);}
	if(!defined($network)){print "FAIL\n";print STDERR "ERROR: Network not defined";exit(1);}
	if(!defined($port)){print "FAIL\n";print STDERR "ERROR: Port not defined";exit(1);}
	my $command="openstack server create";
	$command.=" --flavor $flavor";
	$command.=" --image $image";
	$command.=" --key-name $keyname";
	$command.=" --security-group $securitygroup";
	$command.=" --network $network";
	if(defined($password)){
		my ($writer,$file)=tempfile("textXXXXXXXXXX",DIR=>$openstackdir,SUFFIX=>".txt",UNLINK=>1);
		if(defined($userdata)){
			my $reader=openFile($userdata);
			while(<$reader>){chomp;print $writer "$_\n";}
			close($reader);
		}
		print $writer "#cloud-config\n";
		print $writer "password: $password\n";
		print $writer "chpasswd: { expire: False }\n";
		close($writer);
		$userdata=$file;
	}
	if(defined($userdata)){$command.=" --user-data $userdata";}
	if(defined($port)){$command.=" --port $port";}
	if(defined($property)){$command.=" --property $property";}
	$command.=" -f json";
	$command.=" $name";
	my $instance=getJsonFromOpenstack($command);
	unlink($userdata);
	if(!defined($instance)){
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "#ERROR:  Couldn't create '$name' instance\n";
		exit(1);
	}
	if(!defined($opt_q)){print "OK\n";}
	if(!waitUntillInstanceIsActive($name)){exit(1);}
	$instance=getInstance($name);
	if(!defined($instance)){
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "#ERROR:  Instance was created, but '$instance' is not listed\n";
		exit(1);
	}
	return $instance;
}
############################## createKeyPair ##############################
sub createKeyPair{
	my $publicKeyFile=shift();
	my $keyPairName=shift();
	if(!defined($publicKeyFile)){print STDERR "ERROR: Please specify path to a SSH public-key\n";}
	if(!defined($keyPairName)){print STDERR "ERROR: Please specify name of a keypair\n";}
	if(!defined($opt_q)){print ">Creating '$keyPairName' keypair...  ";}
	if($publicKeyFile=~/^\S+\@\S+\:(\S+)$/){
		if(!executeCommands(undef,["scp $publicKeyFile ."])){if(defined($opt_q)){print "FAIL\n";}exit(1);}
		$publicKeyFile=$1;
	}else{
		if(!executeCommands(undef,["cp $publicKeyFile ."])){
			if(defined($opt_q)){print "FAIL\n";}
			print STDERR "ERROR: Make sure SSH public key file exists (e.g. ~/.ssh/id_rsa.pub)\n";
			print STDERR "        If not, you might need to create a public key with 'ssh-keygen'\n";
			unlink($publicKeyFile);
			exit(1);
		}
	}
	$publicKeyFile=basename($publicKeyFile);
	my $keyPair=getJsonFromOpenstack("openstack keypair create -f json --public-key $publicKeyFile \"$keyPairName\"");
	unlink($publicKeyFile);
	if(!defined($opt_q)){print "OK\n";}
	return $keyPair->{"name"};
}
############################## createOpenStackBash ##############################
sub createOpenStackBash{
	my @commands=@_;
	my $password=shift(@commands);
	my ($writer,$file)=tempfile("bashXXXXXXXXXX",DIR=>$openstackdir,SUFFIX=>".sh",UNLINK=>1);
	if(scalar(@{$openrcLines})==0){
		if(!defined($opt_q)){print "ERROR\n";}
		print STDERR "ERROR: XXXXXXX_openrc.sh hasn't been setup yet\n";
		exit(1);
	}
	foreach my $line(@{$openrcLines}){
		my $tmp=$line;
		if($tmp eq "read -sr OS_PASSWORD_INPUT"){$tmp="OS_PASSWORD_INPUT=\"$password\"";}
		print $writer "$tmp\n";
	}
	foreach my $line(@commands){print $writer "$line\n";}
	close($writer);
	chmod(0755,$file);
	return $file;
}
############################## createOpenstackDockerImage ##############################
sub createOpenstackDockerImage{
	if(!defined($opt_q)){
		if(!promptYesNo("#Do you want to create openstack Docker image")){return;}
		print ">Creating openstack docker image...  \n";
	}
	mkdir("tmp");
	open(OUT,">tmp/Dockerfile");
	print OUT "FROM python\n";
	print OUT "LABEL maintainer=\"Akira Hasegawa <akira.hasegawa\@riken.jp>\"\n";
	print OUT "RUN pip install \\\n";
	print OUT "python-openstackclient \\\n";
	print OUT "&& rm -rf /root/.cache/\n";
	close(OUT);
	my @commands=();
	push(@commands,"cd tmp");
	push(@commands,"docker build --no-cache -t $openStackDockerImage .");
	push(@commands,"rm -r tmp");
	if(!executeCommands(undef,\@commands)){if(defined($opt_q)){print "FAIL\n";exit(1);}}
	if(!defined($opt_q)){print "OK\n";}
}
############################## createPassword ##############################
sub createPassword{
	my $number=shift();
	if(!defined($number)||$number<12){$number=12;}
	my @alphabets=();
	for(my $i=65;$i<=90;$i++){push(@alphabets,chr($i));}
	for(my $i=97;$i<=122;$i++){push(@alphabets,chr($i));}
	my @numbers=();
	for(my $i=48;$i<=57;$i++){push(@numbers,chr($i));}
	my @symbols=('-','.','+','!','/','_');
	my @arrays=();
	for(my $i=0;$i<$number;$i++){push(@arrays,\@alphabets);}
	my $numindex=int(rand($number));
	my $symindex=int(rand($number));
	while($numindex==$symindex){$symindex=int(rand($number));}
	$arrays[$numindex]=\@numbers;
	$arrays[$symindex]=\@symbols;
	my $password="";
	for(my $i=0;$i<$number;$i++){
		my $array=$arrays[$i];
		my $index=int(rand(scalar(@{$array})));
		$password.=$array->[$index];
	}
	return $password;
}
############################## createRandomDirname ##############################
sub createRandomName{
	my $number=shift();
	if(!defined($number)||$number<12){$number=12;}
	my @chars=();
	for(my $i=65;$i<=90;$i++){push(@chars,chr($i));}
	for(my $i=97;$i<=122;$i++){push(@chars,chr($i));}
	for(my $i=48;$i<=57;$i++){push(@chars,chr($i));}
	my $name="";
	for(my $i=0;$i<$number;$i++){$name.=$chars[int(rand(scalar(@chars)))];}
	return $name;
}
############################## createSingularitySnapshot ##############################
sub createSingularitySnapshot{
	my $name=shift();
	my $ip=shift();
	initialize();
	if(!defined($name)){$name="snapshot-singularity";}
	if(existsImage($name)){print STDERR "Snapshot '$name' already exists.\n";return 1;}
	if(!defined($ip)){$ip=chooseFloatingIP();}
	elsif($ip!~/^[\d\.]+$/){$ip=undef;}
	my $instance=createDefaultInstance($name,$ip);
	if(!defined($ip)){$ip=getIpFromInstance($instance);}
	installSingularityOnServer($ip);
	snapshotInstanceGracefully($name,$name);
	deleteInstanceGracefully($name);
	replaceVariableFromThisScript({"\$imageLists"=>listImages()});
	return 1;
}
############################## createSshKey ##############################
sub createSshKey{
	my $ip=shift();
	my $privateKey=(defined($ip))?"$openStackRootUser\@$ip:.ssh/id_rsa":"~/.ssh/id_rsa";
	my $publicKey="$privateKey.pub";
	if(fileExists($privateKey)){return $publicKey;}
	if(!defined($opt_q)){
		if(defined($ip)){print ">Creating SSH key with ssh-keygen at '$ip'...  ";}
		else{print ">Creating SSH key with ssh-keygen at local...  ";}
	}
	my @commands=();
	push(@commands,"ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''");
	if(!executeCommands($ip,\@commands)){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	return $publicKey;
}
############################## createUserKeyPair ##############################
sub createUserKeyPair{
	my $name="$user-keypair";
	if(existsKeyPair($name)){deleteKeyPair($name);}
	my $publicKey=createSshKey();
	my $userKeyPair=createKeyPair($publicKey,$name);
	return $name;
}
############################## deleteInstance ##############################
sub deleteInstance{
	my $instanceName=shift();
	if(!defined($opt_q)){print ">Deleting '$instanceName' instance...  ";}
	my $command="openstack server delete $instanceName";
	my $result=getResultFromOpenstack($command);
	if(!defined($opt_q)){print "OK\n";}
	return $result;
}
############################## deleteInstanceGracefully ##############################
sub deleteInstanceGracefully{
	my $instanceName=shift();
	my $result=1;
	if(!shutoffInstance($instanceName)){$result=0;}
	if(!deleteInstance($instanceName)){$result=0;}
	return $result;
}
############################## deleteKeyPair ##############################
sub deleteKeyPair{
	my $keyPair=shift();
	if(!defined($opt_q)){print ">Deleting '$keyPair' keypair...  ";}
	my $command="openstack keypair delete $keyPair";
	my $result=getResultFromOpenstack($command);
	if(!defined($opt_q)){print "OK\n";}
	return $result;
}
############################## deleteUserFromServer ##############################
sub deleteUserFromServer{
	my $user=shift();
	if(!defined($user)){print STDERR "Please specify user\n";return;}
	my $ip=shift();
	if(!defined($ip)){$ip=$serverIP;}
	my $command="sudo userdel $user";
	my $result=executeCommands($ip,[$command]);
	if(!$result){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	if(!defined($opt_q)){print "OK\n";}
	return $result;
}
############################## executeCommands ##############################
sub executeCommands{
	my $ip=shift();
	my $commands=shift();
	my $user=shift();
	my $singularityFile=shift();
	my $runInBackground=shift();
	if(!defined($user)){$user="ubuntu";}
	my ($writer,$file)=tempfile("bashXXXXXXXXXX",DIR=>$openstackdir,SUFFIX=>".sh",UNLINK=>1);
	open(OUT,">>$logFile");
	my $basename=basename($file);
	my $datetime=getDate("/")." ".getTime(":");
	print OUT "############################## $datetime ##############################\n";
	foreach my $command(@{$commands}){print $writer "$command\n";print OUT ">$command\n";}
	if(defined($ip)){print $writer "rm $basename\n";}
	else{print $writer "rm $file\n";}
	close($writer);
	close(OUT);
	my $command=defined($ip)?"bash $basename":"bash $file";
	if(defined($singularityFile)){$command="singularity exec $singularityFile $command";}
	$command.=" >>$logFile 2>&1";
	if(defined($runInBackground)){$command.=" &";}
	if(defined($ip)){
		my $result=system("scp $file $user\@$ip:. >>$logFile 2>&1");
		unlink($file);
		if($result){return;}
		if(system("ssh $user\@$ip $command")){return;}
	}else{
		if(system($command)){return;}
	}
	return 1;
}
############################## existsFlavor ##############################
sub existsFlavor{
	my $string=shift();
	my $index;
	my $flavors=listFlavors();
	my $size=scalar(@{$flavors});
	for(my $i=0;$i<$size;$i++){
		my $flavor=$flavors->[$i];
		my $name=$flavor->{"Name"};
		if($name=~/^$string$/){$index=$i;}
	}
	if(defined($index)){return 1;}
	return;
}
############################## existsImage ##############################
sub existsImage{
	my $string=shift();
	my $index;
	my $images=listImages();
	my $size=scalar(@{$images});
	for(my $i=0;$i<$size;$i++){
		my $image=$images->[$i];
		my $name=$image->{"Name"};
		if($name=~/^$string$/){$index=$i;}
	}
	if(defined($index)){return 1;}
	return;
}
############################## existsInstance ##############################
sub existsInstance{
	my $string=shift();
	my $index;
	my $instances=listServers();
	my $size=scalar(@{$instances});
	for(my $i=0;$i<$size;$i++){
		my $instance=$instances->[$i];
		my $name=$instance->{"Name"};
		if($name=~/^$string$/){$index=$i;}
	}
	if(defined($index)){return 1;}
	return;
}
############################## existsKeyPair ##############################
sub existsKeyPair{
	my $name=shift();
	my $finger=shift();
	my $index;
	my $keyPairs=listKeyPairs();
	my $size=scalar(@{$keyPairs});
	for(my $i=0;$i<$size;$i++){
		my $keyPair=$keyPairs->[$i];
		my $name=$keyPair->{"Name"};
		if($name!~/^$name$/){next;}
		if(defined($finger)&&$finger ne $keyPair->{"Fingerprint"}){next;}
		$index=$i;
	}
	if(defined($index)){return 1;}
	return;
}
############################## fileExists ##############################
sub fileExists{
	my $path=shift();
	open(OUT,">>$logFile");
	my $datetime=getDate("/")." ".getTime(":");
	print OUT "############################## $datetime ##############################\n";
	my $command="ssh $1 ls $2";
	if($path=~/^(.+\@.+)\:(.+)$/){$command="ssh $1 ls -l $2";}
	else{$command="ls -l $path";}
	print OUT ">$command\n";
	close(OUT);
	my $result=`$command 2>>$logFile`;
	chomp($result);
	if($result ne ""){return $result;}
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
############################## getGroupInfo ##############################
sub getGroupInfo{
	my $group=shift();
	my $ip=shift();
	my $command=defined($ip)?"ssh $openStackRootUser\@$ip cat /etc/group":"cat /etc/group";
	my @results=`$command 2> /dev/null`;
	my $hash={};
	foreach my $result(@results){
		chomp($result);
		my ($name,$star,$id,$groups)=split(/:/,$result);
		if($name=~/^#/){next;}#MacOS
		$hash->{$name}={};
		$hash->{$name}->{"name"}=$name;
		$hash->{$name}->{"id"}=$id;
	}
	if(defined($group)){
		if(exists($hash->{$group})){$hash=$hash->{$group};}
		else{$hash=undef;}
	}
	return $hash;
}
############################## getInstance ##############################
sub getInstance{
	my $string=shift();
	my $index;
	my $servers=listServers();
	my $size=scalar(@{$servers});
	for(my $i=0;$i<$size;$i++){
		my $server=$servers->[$i];
		my $name=$server->{"Name"};
		if($name=~/^$string$/){$index=$i;}
	}
	if(defined($index)){return $servers->[$index];}
	return;
}
############################## getInstanceFromIp ##############################
sub getInstanceFromIp{
	my $string=shift();
	my $index;
	my $servers=listServers();
	my $size=scalar(@{$servers});
	for(my $i=0;$i<$size;$i++){
		my $server=$servers->[$i];
		if(!exists($server->{"Networks"})){return;}
		foreach my $name(keys(%{$server->{"Networks"}})){
			foreach my $ip(@{$server->{"Networks"}->{$name}}){
				if($ip eq $string){$index=$i;last;}
			}
			if(defined($index)){last;}
		}
		if(defined($index)){last;}
	}
	if(defined($index)){return $servers->[$index]->{"Name"};}
}
############################## getIpFromInstance ##############################
sub getIpFromInstance{
	my $instance=shift();
	if(ref($instance)ne"HASH"){
		my $index;
		my $servers=listServers();
		my $size=scalar(@{$servers});
		for(my $i=0;$i<$size;$i++){
			my $server=$servers->[$i];
			my $name=$server->{"Name"};
			if($name=~/^$instance$/){$index=$i;}
		}
		if(!defined($index)){return;}
		$instance=$servers->[$index];
	}
	my $name="$openStackProjectName-network";
	if(!exists($instance->{"Networks"})){return;}
	if(!exists($instance->{"Networks"}->{$name})){return;}
	my @ips=@{$instance->{"Networks"}->{$name}};
	if(scalar(@ips)==1){return $ips[0];}
	foreach my $ip(@ips){
		if($ip=~/^10\./){next;}
		return $ip;
	}
}
############################## getJsonFromOpenstack ##############################
sub getJsonFromOpenstack{
	my @commands=@_;
	open(OUT,">>$logFile");
	my $datetime=getDate("/")." ".getTime(":");
	print OUT "############################## $datetime ##############################\n";
	foreach my $command(@commands){print OUT ">$command\n";}
	close(OUT);
	my $path=createOpenStackBash($openStackPassword,@commands);
	my $command=($modeOpenStackDocker)?$dockerExecCommand:"";
	$command="$command bash $path";
	my @lines=`$command 2>>$logFile`;
	unlink($path);
	if(scalar(@lines)==0){return;}
	my @table=();
	foreach my $line(@lines){
		chomp($line);
		$line=~s/\r//g;
	}
	my $line=jsonDecode(join(" ",@lines));
	if($line ne ""){return $line;}
	return;
}
############################## getMacAdress ##############################
sub getMacAdress{
	my $result=`/bin/ip link show eth0`;
	if($result=~/link\/ether\s(\S+)/){return $1;}
	return;
}
############################## getResultFromOpenstack ##############################
sub getResultFromOpenstack{
	my @commands=@_;
	open(OUT,">>$logFile");
	my $datetime=getDate("/")." ".getTime(":");
	print OUT "############################## $datetime ##############################\n";
	foreach my $command(@commands){print OUT ">$command\n";}
	close(OUT);
	my $path=createOpenStackBash($openStackPassword,@commands);
	my $command=($modeOpenStackDocker)?$dockerExecCommand:"";
	$command="$command bash $path >>$logFile 2>&1";
	my $result=system($command);
	unlink($path);
	return $result==0;
}
############################## getSshFingerPrint ##############################
sub getSshFingerPrint{
	my $file=shift();
	if(!defined($file)){$file="~/.ssh/id_rsa.pub";}
	my $command="ssh-keygen -l -E md5 -f $file";
	my $result=`$command`;
	chomp($result);
	my ($id,$fingerprint,$user,$type)=split(/ /,$result);
	if($fingerprint=~/^MD5:(.+)$/){$fingerprint=$1;}
	return $fingerprint;
}
############################## getStatusOfInstance ##############################
sub getStatusOfInstance{
	my $name=shift();
	my $servers=listServers();
	foreach my $server(@{$servers}){
		if($server->{"Name"}ne$name){next;}
		return $server->{"Status"};
	}
	return;
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
############################## getUserInfo ##############################
sub getUserInfo{
	my $user=shift();
	my $ip=shift();
	if(!defined($user)){$user=`whoami`;chomp($user);}
	my $command=defined($ip)?"ssh $openStackRootUser\@$ip id $user":"id $user";
	my $result=`$command 2> /dev/null`;
	chomp($result);
	if($result eq ""){return;}
	my ($uid,$gid,$groups)=split(/ /,$result);
	my $hash={};
	if($uid=~/^uid\=(\d+)\((\w+)\)$/){
		if(!defined($hash->{"user"})){$hash->{"user"}={};}
		$hash->{"user"}->{"id"}=$1;
		$hash->{"user"}->{"name"}=$2;
	}
	if($gid=~/^gid\=(\d+)\((\w+)\)$/){
		if(!defined($hash->{"group"})){$hash->{"group"}={};}
		$hash->{"group"}->{"id"}=$1;
		$hash->{"group"}->{"name"}=$2;
	}
	if($groups=~/^groups\=(\S+)$/){
		$groups=$1;
		if(!defined($hash->{"groups"})){$hash->{"groups"}={};}
		foreach my $token(split(/,/,$groups)){
			if($token=~/^(\d+)\((\w+)\)$/){$hash->{"groups"}->{$2}=$1;}
		}
	}
	return $hash;
}
############################## hashToString ##############################
sub hashToString{
	my $val=shift();
	if(ref($val)eq"HASH"){
		my $line="";
		my @keys=sort{$a cmp $b}keys(%{$val});
		foreach my $key(@keys){
			my $v=$val->{$key};
			if(length($line)>0){$line.=","}
			$line.=hashToString($key)."=>".hashToString($v);
		}
		return "{$line}";
	}elsif(ref($val)eq"ARRAY"){
		my $line="";
		foreach my $v(@{$val}){
			if(length($line)>0){$line.=","}
			$line.=hashToString($v);
		}
		return "[$line]";
	}elsif($val=~/^(\d+)$/){return $val;}
	else{
		my $line=$val;
		$line=~s/"/\\"/g;
		$line=~s/\$/\\\$/g;
		$line=~s/\@/\\\@/g;
		return "\"$line\"";
	}
}
############################## helpMenu ##############################
sub helpMenu{
	if(scalar(@ARGV)==0){help();}
	elsif($ARGV[0]eq"add"){helpAdd();}
	elsif($ARGV[0]eq"check"){helpCheck();}
	elsif($ARGV[0]eq"config"){helpConfig();}
	elsif($ARGV[0]eq"info"){helpInfo();}
	elsif($ARGV[0]eq"install"){helpInstall();}
	elsif($ARGV[0]eq"reload"){helpReload();}
	elsif($ARGV[0]eq"remove"){helpRemove();}
	elsif($ARGV[0]eq"reset"){helpReset();}
	elsif($ARGV[0]eq"run"){helpRun();}
	elsif($ARGV[0]eq"ssh"){helpSsh();}
	elsif($ARGV[0]eq"start"){helpStart();}
	elsif($ARGV[0]eq"stop"){helpStop();}
	elsif($ARGV[0]eq"transfer"){helpTransfer();}
}
sub helpAdd{}
sub helpCheck{}
sub helpConfig{}
sub helpInfo{}
sub helpInstall{}
sub helpReload{}
sub helpRemove{}
sub helpReset{}
sub helpRun{}
sub helpSsh{}
sub helpStart{}
sub helpStop{}
sub helpTransfer{}
############################## initServer ##############################
sub initServer{
	my $hash={};
	if(!defined($serverInstance)){
		if(!promptYesNo("Do you want to start up a new server")){
			$serverInstance=promptServer();
			if(defined($serverInstance)){$hash->{"\$serverInstance"}=$serverInstance;}
		}	
	}
	if(!defined($serverInstance)){
		if(!defined($modeWebService)){
			$modeWebService=promptYesNo("Do you want to install Apache+PHP");
			$hash->{"\$modeWebService"}=$modeWebService;
		}
		if(!defined($modeUserAccount)){
			$modeUserAccount=promptYesNo("Do you want to setup '$user' account on the server");
			$hash->{"\$modeUserAccount"}=$modeUserAccount;
		}
		if(!defined($modeOpenStackCli)){
			$modeOpenStackCli=promptYesNo("Do you want to setup openstack CLI on the server");
			$hash->{"\$modeOpenStackCli"}=$modeOpenStackCli;
		}
		if(!defined($modeTimezone)){
			$modeTimezone=promptYesNo("Do you want to setup timezone on the server");
			$hash->{"\$modeTimezone"}=$modeTimezone;
		}
	}
	if(!defined($serverPassword)){
		if(!defined($opt_q)){print ">Creating a random server password...  ";}
		$serverPassword=createPassword();
		$hash->{"\$serverPassword"}=$serverPassword;
		if(!defined($opt_q)){print "OK\n";}
	}
	replaceVariableFromThisScript($hash);
}
############################## initialize ##############################
sub initialize{
	my $hash={};
	if(!defined($openStackMoiraiId)){
		$openStackMoiraiId="moirai".getDate();
		$hash->{"\$openStackMoiraiId"}=$openStackMoiraiId;
	}
	checkOpenrcLines($hash);
	checkOpenStackPassword($hash);
	replaceVariableFromThisScript($hash);
}
############################## installApachePhpOnServer ##############################
sub installApachePhpOnServer{
	my $ip=shift();
	if(!defined($ip)){
		if(defined($serverIP)){$ip=$serverIP;}
		else{print STDERR "No IP is specified\n";exit(1);}
	}
	if(!defined($opt_q)){print ">Installing Apache+PHP on instance '$ip'...  ";}
	my @commands=();
	push(@commands,"sudo apt-get -y update");
	push(@commands,"sudo apt-get -y install apache2 php libapache2-mod-php");
	push(@commands,"apache2 -v");
	push(@commands,"php -v");
	push(@commands,"sudo tee /var/www/html/info.php<<EOF>/dev/null");
	push(@commands,"<?php");
	push(@commands,"phpinfo();");
	push(@commands,"?>");
	push(@commands,"EOF");
	if(!executeCommands($ip,\@commands)){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## installBigWigOnServer ##############################
sub installBigWigOnServer{
	my $ip=shift();
	if(!defined($ip)){
		if(defined($serverIP)){$ip=$serverIP;}
		else{print STDERR "No IP is specified\n";exit(1);}
	}
	if(!defined($opt_q)){print ">Installing bigwig on instance '$ip'...  ";}
	my @commands=();
	push(@commands,"rsync -aP rsync://hgdownload.soe.ucsc.edu/genome/admin/exe/linux.x86_64/ bin/");
	push(@commands,"sudo cp bin/* /usr/local/bin/.");
	if(!executeCommands($ip,\@commands)){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## installDjangoOnServer ##############################
sub installDjangoOnServer{
	my $ip=shift();
	if(!defined($ip)){
		if(defined($serverIP)){$ip=$serverIP;}
		else{print STDERR "No IP is specified\n";exit(1);}
	}
	if(!defined($opt_q)){print ">Installing django on instance '$ip'...  ";}
	my @commands=();
	push(@commands,"sudo apt-get update");
	if(!executeCommands($ip,\@commands)){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## installDockerOnServer ##############################
sub installDockerOnServer{
	my $ip=shift();
	if(!defined($ip)){
		if(defined($serverIP)){$ip=$serverIP;}
		else{print STDERR "No IP is specified\n";exit(1);}
	}
	if(!defined($opt_q)){print ">Installing Docker on instance '$ip'...  ";}
	my @commands=();
	push(@commands,"sudo apt-get update");
	push(@commands,"sudo apt-get install -y ca-certificates curl gnupg lsb-release");
	push(@commands,"curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg");
	push(@commands,"echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null");
	push(@commands,"sudo apt-get update");
 	push(@commands,"sudo apt-get install -y docker-ce docker-ce-cli containerd.io");
	push(@commands,"sudo groupadd docker");
	push(@commands,"sudo usermod -aG docker ubuntu");
	push(@commands,"docker --version");
	push(@commands,"sudo curl -L \"https://github.com/docker/compose/releases/download/$dockerComposeVersion/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose");
	push(@commands,"sudo chmod +x /usr/local/bin/docker-compose");
	push(@commands,"docker-compose --version");
	if(!executeCommands($ip,\@commands)){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## installOpenstackOnServer ##############################
sub installOpenstackOnServer{
	my $ip=shift();
	if(!defined($ip)){
		if(defined($serverIP)){$ip=$serverIP;}
		else{print STDERR "No IP is specified\n";exit(1);}
	}
	if(!defined($opt_q)){print ">Installing OpenStack CLI on instance '$ip'...  ";}
	my @commands=();
	push(@commands,"sudo apt-get -y update");
	push(@commands,"sudo apt-get -y install python3-dev python3-pip");
	push(@commands,"sudo pip install python-openstackclient");
	push(@commands,"openstack --version");
	if(!executeCommands($ip,\@commands)){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## installSingularityOnServer ##############################
sub installSingularityOnServer{
	my $ip=shift();
	if(!defined($ip)){
		if(defined($serverIP)){$ip=$serverIP;}
		else{print STDERR "No IP is specified\n";exit(1);}
	}elsif($ip eq "."||$ip eq "localhost"){$ip=undef;}
	my $os="linux";
	my $arch="amd64";
	my $goFile="go$goVersion.$os-$arch.tar.gz";
	my $singularityFile="singularity-ce-$singularityVersion.tar.gz";
	my $singularityDir="singularity-ce-$singularityVersion";
	if(!defined($opt_q)){print ">Installing singularity on instance '$ip' (takes 5 minutes)...  ";}
	my @commands=();
	push(@commands,"sudo apt-get install -y build-essential libssl-dev uuid-dev libgpgme11-dev squashfs-tools libseccomp-dev wget pkg-config git");
  	push(@commands,"wget https://dl.google.com/go/$goFile");
	push(@commands,"sudo tar -C /usr/local -xzvf $goFile");
  	push(@commands,"rm $goFile");
	push(@commands,"echo 'export PATH=/usr/local/go/bin:\$PATH' >> ~/.bashrc && source ~/.bashrc");
	push(@commands,"export PATH=/usr/local/go/bin:\$PATH");
	push(@commands,"wget https://github.com/sylabs/singularity/releases/download/v$singularityVersion/$singularityFile");
	push(@commands,"tar -xzf $singularityFile");
	push(@commands,"cd singularity-ce-$singularityVersion");
	push(@commands,"./mconfig");
    push(@commands,"make -C builddir");
    push(@commands,"sudo make -C builddir install");
    push(@commands,"cd ..");
  	push(@commands,"rm $singularityFile");
  	push(@commands,"rm -r $singularityDir");
  	push(@commands,"sudo rm -r go");
    push(@commands,"singularity --version");
	if(!executeCommands($ip,\@commands,"ah3q")){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## isIpAddress ##############################
sub isIpAddress{
	my $string=shift();
	if($string=~/^\d+\.\d+\.\d+\.\d+$/){return 1;}
	return;
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
############################## jsonEncode ##############################
sub jsonEncode{
	my $object=shift;
	if(ref($object) eq "ARRAY"){return jsonEncode_array($object);}
	elsif(ref($object) eq "HASH"){return jsonEncode_hash($object);}
	else{return "\"".json_escape($object)."\"";}
}
sub jsonEncode_array{
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
sub jsonEncode_hash{
	my $hashtable=shift();
	my $json="{";
	my $i=0;
	foreach my $subject (sort{$a cmp $b} keys(%{$hashtable})){
		if($i>0){$json.=",";}
		$json.="\"$subject\":".jsonEncode($hashtable->{$subject});
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
	return sort{$a cmp $b}@inputfiles;
}
############################## lists ##############################
sub listFlavors{return getJsonFromOpenstack("openstack flavor list -f json");}
sub listFloatingIPs{return getJsonFromOpenstack("openstack floating ip list -f json");}
sub listImages{return getJsonFromOpenstack("openstack image list -f json");}
sub listKeyPairs{return getJsonFromOpenstack("openstack keypair list -f json");}
sub listNetworks{return getJsonFromOpenstack("openstack network list -f json");}
sub listPorts{return getJsonFromOpenstack("openstack port list -f json");}
sub listSecurityGroups{return getJsonFromOpenstack("openstack security group list -f json");}
sub listServers{return getJsonFromOpenstack("openstack server list -f json");}
############################## loadOpenrcCommands ##############################
sub loadOpenrcCommands{
	my $file=shift();
	my $hash=shift();
	if(!-e $file){print STDERR "#ERROR $file doesn't exist\n";exit(1);}
	my $reader=openFile($file);
	my @originals=();
	my @lines=();
	while(<$reader>){
		chomp;
		if(/^#/){next;}
		if(/^echo/){next;}
		push(@lines,$_);
	}
	close($reader);
	$openrcLines=\@lines;
	$hash->{"\$openrcLines"}=\@lines;
	return 1;
}
############################## loadPublicKey ##############################
sub loadPublicKey{
	my $publicKeyFile=shift();
	if(!defined($publicKeyFile)){print STDERR "ERROR: Please specify path to a SSH public-key\n";}
	if(!defined($opt_q)){print ">Loading '$publicKeyFile' to this script...  ";}
	if($publicKeyFile=~/^\S+\@\S+\:(\S+)$/){
		if(!executeCommands(undef,["scp $publicKeyFile ."])){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
		$publicKeyFile=$1;
	}else{
		if(!executeCommands(undef,["cp $publicKeyFile ."])){if(!defined($opt_q)){print "FAIL\n";}unlink($publicKeyFile);exit(1);}
	}
	$publicKeyFile=basename($publicKeyFile);
	my $reader=openFile($publicKeyFile);
	my $key="";
	while(<$reader>){chomp;$key.=$_;}
	close($reader);
	unlink($publicKeyFile);
	if(!defined($opt_q)){print "OK\n";}
	return $key;
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
############################## phpSetMaxSize ##############################
sub phpSetMaxSize{

}
############################## printInfo ##############################
sub printInfo{
	initialize();
	print "\n>flavors\n";
	my $flavorLists=listFlavors();
	printRows($flavorLists,["Disk","Name","RAM","VCPUs"]);
	print "\n>images\n";
	my $imageLists=listImages();
	printRows($imageLists,["Name","Status"]);
	print "\n>security groups\n";
	my $securityGroupLists=listSecurityGroups();
	printRows($securityGroupLists,["Name"]);
	print "\n>networks\n";
	my $networkLists=listNetworks();
	printRows($networkLists,["Name"]);
	print "\n>Ports\n";
	my $portLists=listPorts();
	foreach my $port(@{$portLists}){
		my $address=$port->{"Fixed IP Addresses"};
		foreach my $hash(@{$address}){$port->{"ip_address"}=$hash->{"ip_address"};}
	}
	printRows($portLists,["Name","Status","ip_address"]);
	print "\n>keypairs\n";
	my $keyPairLists=listKeyPairs();
	printRows($keyPairLists,["Name","Type"]);
	print "\n>servers\n";
	my $serverLists=listServers();
	printRows($serverLists,["Flavor","Image","Name","Status"]);
	print "\n";
}
############################## printLogs ##############################
sub printLogs{
	my @logFiles=listFilesRecursively("\.txt",undef,0,$logdir);
	foreach my $logFile(@logFiles){
		my $reader=openFile($logFile);
		while(<$reader>){print;}
		close($reader);
	}
}
############################## printOpenrcFile ##############################
sub printOpenrcFile{
	if(scalar(@{$openrcLines})==0){return;}
	foreach my $line(@{$openrcLines}){print "$line\n";}
}
############################## printRows ##############################
sub printRows{
	my $hashtable=shift();
	my @keys=@{shift()};
	if(scalar(@keys)==0){
		my $temps={};
		foreach my $hash(@{$hashtable}){foreach my $key(keys(%{$hash})){$temps->{$key}++;}}
		@keys=sort{$a cmp $b}keys(%{$temps});
	}
	if(scalar(@keys)==0){return;}
	my @lengths=();
	my @labels=();
	foreach my $key(@keys){push(@labels,"$key");}
	my $indexlength=length("".scalar(@{$hashtable}));
	for(my $i=0;$i<scalar(@labels);$i++){$lengths[$i]=length($labels[$i]);}
	for(my $i=0;$i<scalar(@{$hashtable});$i++){
		my $hash=$hashtable->[$i];
		for(my $j=0;$j<scalar(@labels);$j++){
			my $key=$keys[$j];
			my $val=$hash->{$key};
			if($val=~/^\"(.*)\"$/){$val=$1;}
			my $length=length($val);
			if($lengths[$j]<$length){$lengths[$j]=$length;}
		}
	}
	my $tableline="+";
	for(my $i=0;$i<$indexlength;$i++){$tableline.="-"}
	for(my $i=0;$i<scalar(@lengths);$i++){
		$tableline.="+";
		for(my $j=0;$j<$lengths[$i];$j++){$tableline.="-";}
	}
	$tableline.="+";
	print "$tableline\n";
	my $labelline="|";
	for(my $i=0;$i<$indexlength;$i++){$labelline.=" "}
	for(my $i=0;$i<scalar(@labels);$i++){
		my $label=$labels[$i];
		my $l=length($label);
		$labelline.="|";
		my $string=$label;
		for(my $j=$l;$j<$lengths[$i];$j++){if(($j-$l)%2==0){$string.=" ";}else{$string=" $string";}}
		$labelline.=$string;
	}
	$labelline.="|";
	print "$labelline\n";
	print "$tableline\n";
	for(my $i=0;$i<scalar(@{$hashtable});$i++){
		my $hash=$hashtable->[$i];
		my $line=$i+1;
		my $l=length($line);
		for(my $j=$l;$j<$indexlength;$j++){$line=" $line";}
		$line="|$line";
		for(my $j=0;$j<scalar(@keys);$j++){
			my $key=$keys[$j];
			my $val=hashToString($hash->{$key});
			if($val=~/^\"(.*)\"$/){$val=$1;}
			my $l=length($val);
			if($val=~/^\d+$/){
				$line.="|";
				for(my $k=$l;$k<$lengths[$j];$k++){$line.=" ";}
				$line.="$val";
			}else{
				$line.="|$val";
				for(my $k=$l;$k<$lengths[$j];$k++){$line.=" ";}
			}
		}
		$line.="|";
		print "$line\n";
	}
	print "$tableline\n";
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
############################## printUserData ##############################
sub printUserData{
	print "#cloud-config\n";
	print "password: $serverPassword\n";
	print "chpasswd: { expire: False }\n";
}
############################## promptFlavor ##############################
sub promptFlavor{
	my $size=scalar(@{$flavorLists});
	my $selectedFlavor=$opt_f;
	if(defined($selectedFlavor)){
		my $found;
		if($selectedFlavor=~/^\d+$/){
			foreach my $flavor(@{$flavorLists}){
				if($flavor->{"VCPUs"}eq$selectedFlavor){$selectedFlavor=$flavor->{"Name"};$found=1;last;}
			}
		}else{
			foreach my $flavor(@{$flavorLists}){
				if($flavor->{"Name"}eq$selectedFlavor){$found=1;last;}
			}
		}
		if($found){return $selectedFlavor;}
	}
	printRows($flavorLists,["Disk","Name","RAM","VCPUs"]);
	my $selectedIndex=promptNumber("Please select flavor [1~$size]:",$size);
	if(!defined($selectedIndex)){return;}
	$selectedFlavor=$flavorLists->[$selectedIndex]->{"Name"};
	print "Selected '$selectedFlavor' for flavor.\n";
	return $selectedFlavor;
}
############################## promptImage ##############################
sub promptImage{
	my $size=scalar(@{$imageLists});
	my $selectedImage=$opt_i;
	if(defined($selectedImage)){
		my $found;
		foreach my $image(@{$imageLists}){if($image->{"Name"}eq$selectedImage){$found=1;last;}}
		if($found){return $selectedImage;}
	}
	printRows($imageLists,["Name","Status"]);
	my $selectedIndex=promptNumber("Please select image [1~$size]:",$size);
	if(!defined($selectedIndex)){return;}
	$selectedImage=$imageLists->[$selectedIndex]->{"Name"};
	print "Selected '$selectedImage' for image.\n";
	return $selectedImage;
}
############################## promptNetwork ##############################
sub promptNetwork{
	my $selectedNetwork=$serverNetwork;
	my $size=scalar(@{$networkLists});
	my $found;
	foreach my $network(@{$networkLists}){if($network->{"Name"}eq$selectedNetwork){$found=1;last;}}
	if($found){return $selectedNetwork;}
	printRows($networkLists,["Flavor","Image","Name","Status"]);
	my $selectedIndex=promptNumber("Please select network [1~$size]:",$size);
	if(!defined($selectedIndex)){return;}
	$selectedNetwork=$networkLists->[$selectedIndex]->{"Name"};
	print "Selected '$selectedNetwork' for network.\n";
	return $selectedNetwork;
}
############################## promptNumber ##############################
sub promptNumber{
	my $question=shift();
	my $number=shift();
	print "$question ";
	my $selected;
	while(<STDIN>){
		chomp;
		if(/^\d+/ &&$_>0&&$_<=$number){return ($_-1);}
		elsif($_ eq""){print STDERR "ERROR: Nothing selected...  quit\n";return;}
		else{print "$question ";}
	}
}
############################## promptPassword ##############################
sub promptPassword{
	my $question=shift();
	print STDERR $question;
	system ("stty -echo");  
	my $password=<STDIN>;  
	system ("stty echo");
	chomp($password);
	print STDERR "\n";
	return $password
}
############################## promptSecurityGroup ##############################
sub promptSecurityGroup{
	my $selectedSecurityGroup=$serverSecurityGroup;
	my $size=scalar(@{$securityGroupLists});
	my $found;
	foreach my $group(@{$securityGroupLists}){if($group->{"Name"}eq$selectedSecurityGroup){$found=1;last;}}
	if($found){return $selectedSecurityGroup;}
	printRows($securityGroupLists,["Name"]);
	my $selectedIndex=promptNumber("Please select security group [1~$size]:",$size);
	if(!defined($selectedIndex)){return;}
	$selectedSecurityGroup=$securityGroupLists->[$selectedIndex]->{"Name"};
	print "Selected '$selectedSecurityGroup' for security group.\n";
	return $selectedSecurityGroup;
}
############################## promptServer ##############################
sub promptServer{
	my $serverLists=listServers();
	my $size=scalar(@{$serverLists});
	my $selectedServer=defined($serverInstance)?$serverInstance->{"Name"}:undef;
	my $found;
	foreach my $server(@{$serverLists}){if($server->{"Name"}eq$selectedServer){$found=1;last;}}
	if($found){return $selectedServer;}
	printRows($serverLists,["Flavor","Image","Name","Status"]);
	my $selectedIndex=promptNumber("Please select server [1~$size]:",$size);
	if(!defined($selectedIndex)){return;}
	$selectedServer=$serverLists->[$selectedIndex];
	print "Selected '".$selectedServer->{"Name"}."' for server.\n";
	return $selectedServer;
}
############################## promptSsh ##############################
sub promptSsh{
	my $username=shift(@ARGV);
	if(!defined($serverInstance)||!defined($serverIP)||!defined($logFile)){
		print STDERR "ERROR: Please start/config the server first\n";
		exit(1);
	}
	if(!defined($username)){$username=$user;}
	if(!checkServerConnection($serverIP,$serverInstance->{"Name"})){exit(1);}
	system("ssh $username\@$serverIP");
}
############################## promptString ##############################
sub promptString{
	my $question=shift();
	my $default=shift();
	print STDERR $question;
	my $string=<STDIN>;
	chomp($string);
	if(defined($default)&&$string eq ""){$string=$default}
	return $string
}
############################## promptYesNo ##############################
sub promptYesNo{
	my $question=shift();
	print "$question [Yes/No]? ";
	my $answer=<STDIN>;
	chomp($answer);
	if($answer!~/n/i){return 1;}
	else{return 0;}
}
############################## recheckPassword ##############################
sub recheckPassword{
	my $password=promptPassword("Please enter password to access openstack: ");
	if($password eq $openStackPassword){return 1;}
	return;
}
############################## reloadLists ##############################
sub reloadLists{
	my $hash=shift();
	my $force=shift();
	initialize();
	if(!defined($hash)){$hash={};}
	my $changed=0;
	if(defined($force)||!defined($flavorLists)){
		$changed=1;
		if(!defined($opt_q)){print ">Retrieving flavor information...  ";}
		$flavorLists=listFlavors();
		if(!defined($opt_q)){print "OK\n";}
		$hash->{"\$flavorLists"}=$flavorLists;
	}
	if(defined($force)||!defined($imageLists)){
		$changed=1;
		if(!defined($opt_q)){print ">Retrieving image information...  ";}
		$imageLists=listImages();
		if(!defined($opt_q)){print "OK\n";}
		$hash->{"\$imageLists"}=$imageLists;
	}
	if(defined($force)||!defined($securityGroupLists)){
		$changed=1;
		if(!defined($opt_q)){print ">Retrieving security group information...  ";}
		$securityGroupLists=listSecurityGroups();
		if(!defined($opt_q)){print "OK\n";}
		$hash->{"\$securityGroupLists"}=$securityGroupLists;
	}
	if(defined($force)||!defined($networkLists)){
		$changed=1;
		if(!defined($opt_q)){print ">Retrieving network information...  ";}
		$networkLists=listNetworks();
		if(!defined($opt_q)){print "OK\n";}
		$hash->{"\$networkLists"}=$networkLists;
	}
	return $changed;
}
############################## removeFloatingIP ##############################
sub removeFloatingIP{
	my $instance=shift();
	my $ipAddress=shift();
	if(!defined($opt_q)){print ">Removing floating IP from the server instance...  ";}
	my $command="openstack server remove floating ip $instance $ipAddress";
	my $result=getResultFromOpenstack($command);
	if(!defined($opt_q)){print "OK\n";}
	return $result;
}
############################## removeKnownHosts ##############################
# ssh-keygen -R XXX.XXX.XXX.XXX when "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"
sub removeKnownHosts{
	my $ip=shift();
	if(!defined($opt_q)){print ">Removing '$ip' from ssh known_hosts...  ";}
	my $result=executeCommands(undef,["ssh-keygen -R $ip"]);
	if(!defined($opt_q)){print "OK\n";}
	return $result;
}
############################## removeNode ##############################
sub removeNode{
	my @instances=@_;
	foreach my $instance(@instances){
		if(isIpAddress($instance)){$instance=getInstanceFromIp($instance);}
		deleteInstanceGracefully($instance);
	}
}
############################## replaceUbuntuAuthoriedKeys ##############################
sub replaceUbuntuAuthoriedKeys{
	my $ip=shift();
	if(!defined($ip)){print STDERR "ERROR: Please specify IP at replaceUbuntuAuthoriedKeys()";exit(1);}
	if(!defined($opt_q)){print ">Replacing ubuntu's authorized_keys with real ubuntu for safety...  ";}
	my ($writer,$file)=tempfile("textXXXXXXXXXX",DIR=>$openstackdir,SUFFIX=>".txt",UNLINK=>1);
	print $writer "$serverPublicKey\n";
	close($writer);
	my @commands=();
	my $filename=basename($file);
	push(@commands,"scp $file $openStackRootUser\@$ip:.");
	push(@commands,"ssh $openStackRootUser\@$ip sudo mv $filename ~ubuntu/.ssh/authorized_keys");
	if(!executeCommands(undef,\@commands)){if(!defined($opt_q)){print "FAIL\n";}unlink($file);exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	unlink($file);
	return 1;
}
############################## replaceVariableFromThisScript ##############################
sub replaceVariableFromThisScript{
	my $hash=shift();
	if(scalar(keys(%{$hash})==0)){return;}
	my $output=shift();
	my $path=shift();
	if(!defined($opt_q)&&!defined($output)){print ">Saving settings...  ";}
	if(!defined($path)){$path="$program_directory/$program_name";}
	if(-B $path){return;}
	my @keys=keys(%{$hash});
	my ($writer,$tmpfile)=tempfile("scriptXXXXXXXXXX",DIR=>$openstackdir,SUFFIX=>".pl",UNLINK=>1);
	my $reader=openFile($path);
	while(<$reader>){
		chomp;
		foreach my $key(@keys){
			my $regexp=($key=~/^\$/)?"\\$key":$key;
			if(/^my $regexp\s*\=\s*/ || /^my $regexp;$/){
				my $value=$hash->{$key};
				if(defined($value)){$_="my $key=".hashToString($value).";";}
				else{$_="my $key;";}
			}
		}
		print $writer "$_\n";
	}
	close($reader);
	close($writer);
	if(defined($output)){system("mv $tmpfile $output");}
	else{system("mv $tmpfile $path");}
	if(!defined($opt_q)&&!defined($output)){print "OK\n";}
}
############################## resetSetting ##############################
sub resetSetting{
	if(defined($openrcLines)){checkOpenStackPassword();}
	resetVariableFromThisScript("\$openrcLines","\$openStackMoiraiId","\$openStackPassword","\$openStackProjectName","\$flavorLists","\$imageLists","\$networkLists","\$securityGroupLists","\$serverFlavor","\$serverImage","\$serverInstance","\$serverIP","\$serverKeyPair","\$rootKeyPair","\$serverNetwork","\$serverOpenStackPerlPath","\$serverPassword","\$serverPublicKey","\$serverPort","\$serverSecurityGroup","\$modeOpenStackDocker","\$modeWebService","\$modeUserAccount","\$modeOpenStackCli","\$modeTimezone","\$installedOpenStackPerl","\$installedOpenStackCli","\$installedApachePhp","\$setupUserAccount","\$setupTimezone","\$useSingularitySnapshot");
}
############################## resetVariableFromThisScript ##############################
sub resetVariableFromThisScript{
	my @variables=@_;
	my $hash={};
	foreach my $variable(@variables){$hash->{$variable}=undef;}
	replaceVariableFromThisScript($hash);
}
############################## restartInstance ##############################
sub restartInstance{
	my $instanceName=shift();
	if(!getResultFromOpenstack("openstack server start $instanceName")){
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "ERROR: Couldn't restart the server\n";
		return;
	}
	if(!defined($opt_q)){print "OK\n";}
	waitUntillInstanceIsActive($instanceName);
	return 1;
}
############################## runCommand ##############################
sub runCommand{
	my $command=shift();
	my $ip=addNodeInstance($opt_i,$opt_f);
	my $homedir=`pwd`;
	chomp($homedir);
	my ($writer,$tempFile)=tempfile("bashXXXXXXXXXX",DIR=>"/tmp",SUFFIX=>".log");
	my $basename=basename($tempFile,".log");
	my $logFile="$homedir/$bashdir/$basename.sh";
	my $completeFile="$homedir/$completedir/$basename.txt";
	my $stderrFile="$homedir/$stderrdir/$basename.txt";
	my $stdoutFile="$homedir/$stdoutdir/$basename.txt";
	print $writer "ip\t$ip\n";
	print $writer "command\t$command\n";
	print $writer "start\t".getDate("/")." ".getTime(":")."\n";
	print $writer "bash\t$logFile\n";
	print $writer "complete\t$completeFile\n";
	print $writer "stdout\t$stdoutFile\n";
	print $writer "stderr\t$stderrFile\n";
	close($writer);
	waitForFreeJobQueue($serverMaxJob);
	rename($tempFile,$logFile);
	my @commands=();
	push(@commands,"$command > $stdoutFile 2> $stderrFile");
	push(@commands,"touch $completeFile");
	if(!defined($opt_q)){
		if(defined($ip)){print ">Executing a command with '$user' at '$ip'...  ";}
		else{print ">Executing a command with '$user'...  ";}
	}
	if(!executeCommands($ip,\@commands,$user,$opt_c,"run_in_background")){if(!defined($opt_q)){print "FAIL\n";}}
	elsif(!defined($opt_q)){print "OK\n";}
	waitForJobIsToComplete($logFile,$completeFile,$stdoutFile,$stderrFile);
	removeNode($ip);
}
############################## setServerTimezone ##############################
sub setServerTimezone{
	my $timezone=shift();
	my $ip=shift();
	if(!defined($timezone)){print STDERR "Please specify timezone...";exit(1);}
	if(!defined($ip)){print STDERR "Please specify IP...";exit(1);}
	if(!defined($opt_q)){print ">Trying to set server timezone to '$timezone'...  ";}
	my @commands=();
	push(@commands,"sudo ln -sf /usr/share/zoneinfo/$timezone /etc/localtime");
	push(@commands,"echo \'ZONE=\"$timezone\"\'>timezone.txt");
	push(@commands,"sudo mv -f timezone.txt /etc/sysconfig/clock");
	if(!executeCommands($ip,\@commands)){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	if(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## setupServer ##############################
sub setupServer{
	my $hash={};
	if(!defined($serverIP)){
		$serverIP=getIpFromInstance($serverInstance);
		if(defined($serverIP)){$hash->{"\$serverIP"}=$serverIP;}
	}
	my $publicKey=createSshKey($serverIP);
	if(!defined($serverPublicKey)){
		$serverPublicKey=loadPublicKey($publicKey);
		if(defined($serverPublicKey)){$hash->{"\$serverPublicKey"}=$serverPublicKey;}
	}
	if(!defined($serverKeyPair)){
		my $name="$openStackMoiraiId-server-keypair";
		if(existsKeyPair($name)){deleteKeyPair($name);}
		$serverKeyPair=createKeyPair($publicKey,$name);
		if(defined($serverKeyPair)){$hash->{"\$serverKeyPair"}=$serverKeyPair;}
	}
	if($modeOpenStackCli&&!defined($installedOpenStackCli)){
		if(installOpenstackOnServer($serverIP)){
			$installedOpenStackCli="completed";
			$hash->{"\$installedOpenStackCli"}=$installedOpenStackCli;
		}
	}
	if($modeWebService&&!defined($installedApachePhp)){
		if(installApachePhpOnServer($serverIP)){
			$installedApachePhp="completed";
			$hash->{"\$installedApachePhp"}=$installedApachePhp;
		}
	}
	if($modeTimezone&&!defined($setupTimezone)){
		setServerTimezone($openStackTimezone,$serverIP);
		$setupTimezone="completed";
		$hash->{"\$setupTimezone"}=$setupTimezone;
	}
	if($modeUserAccount&&!defined($setupUserAccount)){
		if(addUserToServer($user,$serverIP)&&addUbuntuSshKeyToUser($user,$serverIP)){
			$setupUserAccount="completed";
			$hash->{"\$setupUserAccount"}=$setupUserAccount;
		}
	}
	if(!defined($installedOpenStackPerl)){uploadOpenstackScriptToInstance($serverIP);}
	replaceVariableFromThisScript($hash);
}
############################## shutoffInstance ##############################
sub shutoffInstance{
	my $instanceName=shift();
	my $status=getStatusOfInstance($instanceName);
	if(!defined($status)){return;}
	if($status eq "ACTIVE"){
		if(!defined($opt_q)){print ">Trying to shutoff '$instanceName' instance...  ";}
		if(!getResultFromOpenstack("openstack server stop $instanceName")){
			if(!defined($opt_q)){print "FAIL\n";}
			print STDERR "ERROR: Couldn't stop the server\n";
			return;
		}
		if(!defined($opt_q)){print "OK\n";}
		waitUntillInstanceIsShutoff($instanceName);
	}
	return 1;
}
############################## snapshotInstance ##############################
sub snapshotInstance{
	my $instanceName=shift();
	my $snapshotName=shift();
	if(!defined($opt_q)){print ">Taking snapshot of '$instanceName' instance...  ";}
	if(!getResultFromOpenstack("openstack server image create --name $snapshotName $instanceName")){
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "ERROR: Couldn't take a snapshot of '$instanceName' instance\n";
		exit(1);
	}
	if(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## snapshotInstanceGracefully ##############################
sub snapshotInstanceGracefully{
	my $instanceName=shift();
	my $snapshotName=shift();
	my $restart=shift();
	if(!defined($snapshotName)){$snapshotName=$instanceName;}
	initialize();
	shutoffInstance($instanceName);
	snapshotInstance($instanceName,$snapshotName);
	if(defined($restart)){restartInstance($instanceName);}
	waitUntillImageIsActive($instanceName);
	return 1;
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
	my ($writer,$file)=tempfile("scriptXXXXXXXXXX",DIR=>$openstackdir,SUFFIX=>".pl",UNLINK=>1);
	foreach my $line(@headers){print $writer "$line\n";}
	foreach my $key(sort{$a cmp $b}@orders){foreach my $line(@{$blocks->{$key}}){print $writer "$line\n";}}
	close($writer);
	return executeCommands(undef,["mv $file $path"]);
}
############################## startServer ##############################
sub startServer{
	my $hash={};
	if(defined($serverInstance)&&checkInstanceIsRunning($serverInstance->{"name"})){
		# no need to create new server instance
	}else{
		my $name="$openStackMoiraiId-server";
		if(existsInstance($name)){deleteInstanceGracefully($name);}
		$serverInstance=createInstance($serverFlavor,$serverImage,$rootKeyPair,$serverSecurityGroup,$serverNetwork,$serverPort,$name,$serverPassword);
		$hash->{"\$serverInstance"}=$serverInstance;
	}
	if(!defined($serverIP)){
		$serverIP=chooseFloatingIP();
		removeKnownHosts($serverIP);
		if(addFloatingIP($serverInstance->{"Name"},$serverIP)){$hash->{"\$serverIP"}=$serverIP;}
	}
	replaceVariableFromThisScript($hash);
}
############################## stopServer ##############################
sub stopServer{
	if(!defined($serverInstance)){return;}
	if(!promptYesNo("Are you sure you want to stop the server")){return;}
	if(!checkOpenStackPassword()){return;}
	if(!promptYesNo("Are you really sure you want to stop the server")){return;}
	my $array=shift();
	if(!defined($array)){$array=[];}
	my $changed=0;
	my $serverName=$serverInstance->{"Name"};
	shutoffInstance($serverName);
	removeKnownHosts($serverIP);
	if(defined($serverIP)){removeFloatingIP($serverName,$serverIP);}
	if(defined($serverInstance)){deleteInstanceGracefully($serverName);}
	if(defined($rootKeyPair)){deleteKeyPair($rootKeyPair);}
	if(defined($serverKeyPair)){deleteKeyPair($serverKeyPair);}
	push(@{$array},"\$serverFlavor","\$serverImage","\$serverInstance","\$serverIP","\$serverKeyPair","\$rootKeyPair","\$serverNetwork","\$serverPassword","\$serverPort","\$serverSecurityGroup","\$serverPublicKey","\$installedOpenStackPerl","\$installedOpenStackCli","\$installedApachePhp","\$setupUserAccount","\$setupTimezone","\$serverOpenStackPerlPath");
	return 1;
}
############################## stringToHash ##############################
sub stringToHash{
	my $string=shift();
	my @tokens=split(/[, ]/,$string);
	my $hash={};
	foreach my $token(@tokens){
		my ($key,$val)=split(/\=/,$string);
		$hash->{$key}=$val;
	}
	return $hash;
}
############################## test ##############################
my $testcount;
sub test{
	$testcount=1;
	$openrcLines=undef;
	my $openrcFile=checkOpenrcLines();
	checkOpenStackPassword();
	initialize();
	initServer();
	configServer();
	mkdir("test");
	#testCommand("perl $program_name -r $openrcFile check docker");
	#testCommand("perl $program_name -r $openrcFile check file $program_name");
	#testCommand("perl $program_name -r $openrcFile check connection");
	#testCommand("perl $program_name -r $openrcFile -p $openStackPassword check password");
	#testCommand("perl $program_name info group");
	#testCommand("perl $program_name info user");
	#testCommand("perl $program_name -r $openrcFile -p $openStackPassword info openstack");
	#testCommand("perl $program_name -r $openrcFile -p $openStackPassword list flavors");
	#testCommand("perl $program_name -r $openrcFile -p $openStackPassword list images");
	#testCommand("perl $program_name -r $openrcFile -p $openStackPassword list securityGroups");
	#testCommand("perl $program_name -r $openrcFile -p $openStackPassword list networks");
	#testCommand("perl $program_name -r $openrcFile -p $openStackPassword list ports");
	#testCommand("perl $program_name -r $openrcFile -p $openStackPassword list keypairs");
	#testCommand("perl $program_name -r $openrcFile -p $openStackPassword list servers");
}
############################## testCommand ##############################
sub testCommand{
	my $command=shift();
	print "[$testcount]$command...  ";
	my $stderr="test/$testcount.stderr.txt";
	my $stdout="test/$testcount.stdout.txt";
	$command.=" > $stdout 2>$stderr";
	my $result=system($command);
	$testcount++;
	if($result!=0){print "FAIL (exit with '$result')\n";return;}
	if(-s $stderr){print "FAIL (stderr not empty)\n";return;}
	else{unlink($stderr);}
	if(-z $stdout){print "FAIL (empty stdout)\n";return;}
	print "OK\n";
}
############################## testMoo ##############################
sub testMoo{
	system("singularity pull library://sylabsed/examples/lolcow");
	system("openstack.pl -c sif/lolcow_latest.sif run 'cowsay moo > moo.txt'");
}
############################## transferAuthorizedKeys ##############################
sub transferAuthorizedKeys{
	my $fromFile=shift();
	my $toFile=shift();
	if(!defined($fromFile)||!defined($toFile)){
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "Please specify FROM TO\n";
		exit(1);
	}
	my $reader=openFile($fromFile);
	my $lines={};
	while(<$reader>){chomp;$lines->{$_}=1;}
	close($reader);
	$reader=openFile($toFile);
	while(<$reader>){chomp;if(exists($lines->{$_})){delete($lines->{$_});}}
	close($reader);
	if(scalar(keys(%{$lines}))==0){return 1;}
	if(!defined($opt_q)){print ">Transfering authorized keys...  ";}
	my ($writer,$file)=tempfile("textXXXXXXXXXX",DIR=>$openstackdir,SUFFIX=>".txt",UNLINK=>1);
	foreach my $line(sort{$a cmp $b}keys(%{$lines})){print $writer "$line\n";}
	close($writer);
	if(!executeCommands(undef,["cat $file >> $toFile"])){if(!defined($opt_q)){print "FAIL\n";}unlink($file);exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	unlink($file);
	return 1;
}
############################## transferInstance ##############################
#https://docs.openstack.org/ja/user-guide/cli-use-snapshots-to-migrate-instances.html
sub transferInstance{
	my $openrcFrom=$ARGV[0];
	my $openrcTo=$ARGV[1];
	my $instance=$ARGV[2];
	my $snapshot="$instance.snapshot";
	my @commands=();
	push(@commands,"echo \"Please enter your OpenStack Password for project FROM:\"");
	push(@commands,"read -sr OS_PASSWORD_INPUT");
	push(@commands,"echo \"Please enter your OpenStack Password for project TO:\"");
	push(@commands,"read -sr OS_PASSWORD_INPUT2");
	my $reader=openFile($openrcFrom);
	while(<$reader>){
		chomp;s/\r//g;
		if(/^#/){next;}
		if(/^echo/){next;}
		if($_ eq "read -sr OS_PASSWORD_INPUT"){next;}
		push(@commands,$_);
	}
	close($reader);
	push(@commands,"openstack server stop $instance");
	push(@commands,"openstack server image create --name $snapshot $instance");
	push(@commands,"openstack server start $instance");
	push(@commands,"openstack image save --file $snapshot $snapshot");
	$reader=openFile($openrcTo);
	while(<$reader>){
		chomp;s/\r//g;
		if(/^#/){next;}
		if(/^echo/){next;}
		if($_ eq "read -sr OS_PASSWORD_INPUT"){next;}
		s/OS_PASSWORD_INPUT/OS_PASSWORD_INPUT2/g;
		push(@commands,$_);
	}
	close($reader);
	push(@commands,"openstack image create --file $snapshot --container-format bare --disk-format qcow2 $instance");
	return executeCommands(undef,\@commands);
}
############################## uploadOpenstackScriptToInstance ##############################
sub uploadOpenstackScriptToInstance{
	my $ip=shift();
	my $path=shift();
	# $path not defined when uploading from local to server => setting will be modified
	# $path defined when uploading from server to node => no change
	if(!defined($ip)){
		if(defined($serverIP)){$ip=$serverIP;}
		else{
			if(!defined($opt_q)){print "FAIL\n";}
			print STDERR "ERROR: Please specify server IP\n";
			exit(1);
		}
	}
	initialize();
	if(!defined($path)&&defined($serverOpenStackPerlPath)){
		#Copying from local to server already uploaded
		my $dir=tempdir(CLEANUP=>1);
		$path="$dir/openstack.pl";
		my $hash={};
		$hash->{"\$openStackPassword"}=$openStackPassword;
		$hash->{"\$modeOpenStackDocker"}=0;
		replaceVariableFromThisScript($hash,$path);
		if(!defined($opt_q)){print ">Uploading openstack.pl to '$ip'...  ";}
		if(!executeCommands(undef,["scp $path $openStackRootUser\@$ip:$serverOpenStackPerlPath"])){
			if(!defined($opt_q)){print "FAIL\n";}
			unlink($path);
			exit(1);
		}elsif(!defined($opt_q)){print "OK\n";}
		unlink($path);		
		return 1;
	}
	my $hiddendir;
	my $realpath;
	my $tmpCreated;
	if(!defined($serverOpenStackPerlPath)){
		if(!defined($opt_q)){print ">Setting openstack.pl at '$ip' server...  ";}
		my $homedir=`ssh $openStackRootUser\@$ip pwd`;
		chomp($homedir);
		if($homedir eq""){
			if(!defined($opt_q)){print "FAIL\n";}
			print STDERR "ERROR: Couldn't get homedir of $openStackRootUser\@$ip'\n";
			exit(1);
		}
		if(!defined($opt_q)){print "OK\n";}
		$hiddendir="$homedir/$openstackdir/".createRandomName(20);
		$realpath="$hiddendir/openstack.pl";
	}else{
		$realpath=$serverOpenStackPerlPath;
		$hiddendir=dirname($realpath);
	}
	if(!defined($path)){
		my $hash={};
		$installedOpenStackPerl="completed";
		$hash->{"\$installedOpenStackPerl"}=$installedOpenStackPerl;
		$hash->{"\$serverOpenStackPerlPath"}=$realpath;
		replaceVariableFromThisScript($hash);
		my $dir=tempdir(CLEANUP=>1);
		$hash->{"\$openStackPassword"}=$openStackPassword;
		$hash->{"\$modeOpenStackDocker"}=0;
		$path="$dir/openstack.pl";
		replaceVariableFromThisScript($hash,$path);
		$tmpCreated=1;
	}elsif(!-e $path){
		if(!defined($opt_q)){print "FAIL\n";}
		print STDERR "ERROR: '$path' specified doesn't exist\n";
		exit(1);
	}
	if(!defined($opt_q)){print ">Uploading openstack.pl to '$ip'...  ";}
	my $filename=basename($path);
	if(!executeCommands(undef,["scp $path $openStackRootUser\@$ip:."])){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	if($tmpCreated){unlink($path);}
	my @commands=();
	push(@commands,"mkdir -p $openstackdir");
	push(@commands,"mkdir -p $hiddendir");
	push(@commands,"chmod 711 $openstackdir");
	push(@commands,"chmod 711 $hiddendir");
	push(@commands,"cat<<EOF>main.c");
	push(@commands,"#include <stdlib.h>");
	push(@commands,"#include <unistd.h>");
	push(@commands,"int main (int argc,char* argv[]){");
    push(@commands,"char* path=\"$realpath\";");
    push(@commands,"execv(path,argv);");
    push(@commands,"exit(EXIT_SUCCESS);");
	push(@commands,"}");
	push(@commands,"EOF");
	push(@commands,"cc main.c");
	push(@commands,"chmod 711 a.out");
	push(@commands,"chmod 755 openstack.pl");
	push(@commands,"mv openstack.pl $hiddendir/.");
	push(@commands,"sudo mv a.out /usr/local/bin/openstack.pl");
	push(@commands,"rm main.c");
	if(!executeCommands($ip,\@commands)){if(!defined($opt_q)){print "FAIL\n";}exit(1);}
	elsif(!defined($opt_q)){print "OK\n";}
	return 1;
}
############################## waitForFreeJobQueue ##############################
sub waitForFreeJobQueue{
	my $maxJob=shift();
	if(!defined($opt_q)){
		STDOUT->autoflush(1);
		print ">Waiting for a free job queue..";
	}
	my @files=listFilesRecursively("\.sh",undef,0,$bashdir);
	while(scalar(@files)>=$maxJob){
		if(defined($opt_q)){print ".";}
		sleep($sleepTime);
		@files=listFilesRecursively("\.sh",undef,0,$bashdir);
	}
	if(!defined($opt_q)){print "  OK\n";STDOUT->autoflush(0);}
	return 1;
}
############################## waitForJobIsToComplete ##############################
sub waitForJobIsToComplete{
	my $logFile=shift();
	my $completeFile=shift();
	my $stdoutFile=shift();
	my $stderrFile=shift();
	my $basename=basename($logFile,".sh");
	if(!defined($opt_q)){
		STDOUT->autoflush(1);
		print ">Waiting for run command to complete..";
	}
	while(!-e $completeFile){if(!defined($opt_q)){print ".";}sleep($sleepTime);}
	if(!defined($opt_q)){print "  OK\n";STDOUT->autoflush(1);}
	if(-s $stdoutFile){
		my $reader=openFile($stdoutFile);
		while(<$reader>){print STDOUT;}
		close($reader);
	}
	if(-s $stderrFile){
		my $reader=openFile($stderrFile);
		while(<$reader>){print STDERR;}
		close($reader);
	}
	unlink($logFile);
	unlink($completeFile);
	unlink($stdoutFile);
	unlink($stderrFile);
}
############################## waitUntillImageStatusIsXXXXX ##############################
sub waitUntillImageIsActive{return waitUntillImageStatusIsXXXXX(shift(),"active");}
sub waitUntillImageStatusIsXXXXX{
	my $name=shift();
	my $status=shift();
	if(!defined($opt_q)){
		STDOUT->autoflush(1);
		print ">Waiting '$name' image to be '$status'...";
	}
	my $found;
	while(1){
		my $images=listImages();
		foreach my $image(@{$images}){
			if($image->{"Name"}ne$name){next;}
			if($image->{"Status"}=~/$status/i){
				if(!defined($opt_q)){
					print "  OK\n";
					STDOUT->autoflush(0);
				}
				return 1;
			}
			$found=1;
		}
		if($found==0){
			if(!defined($opt_q)){
				print "  ERROR\n";
				STDOUT->autoflush(0);
			}
			print STDERR "ERROR: Image '$name' doesn't exist.\n";
			return;
		}
		if(!defined($opt_q)){print ".";}
		sleep(30);
	}
	return;
}
############################## waitForAllInstanceToComplete ##############################
sub waitForAllInstanceToComplete{
	if(!defined($opt_q)){
		STDOUT->autoflush(1);
		print ">Waiting for openstack to complete build or shutoff.";
	}
	while(1){
		my $hit=0;
		my $servers=listServers();
		foreach my $server(@{$servers}){
			if($server->{"Status"}=~/build/i){$hit=1;last;}
			elsif($server->{"Status"}=~/shutoff/i){$hit=1;last;}
		}
		if($hit==0){last;}
		if(!defined($opt_q)){print ".";}
		sleep(30);
	}
	if(!defined($opt_q)){
		print "  OK\n";
		STDOUT->autoflush(0);
	}
	return 1;
}
############################## waitUntillInstanceStatusIsXXXXX ##############################
sub waitUntillInstanceIsActive{return waitUntillInstanceStatusIsXXXXX(shift(),"active");}
sub waitUntillInstanceIsShutoff{return waitUntillInstanceStatusIsXXXXX(shift(),"shutoff");}
sub waitUntillInstanceStatusIsXXXXX{
	my $name=shift();
	my $status=shift();
	if(!defined($opt_q)){
		STDOUT->autoflush(1);
		print ">Waiting '$name' status to be '$status'...";
	}
	my $found;
	while(1){
		my $servers=listServers();
		foreach my $server(@{$servers}){
			if($server->{"Name"}ne$name){next;}
			if($server->{"Status"}=~/$status/i){
				if(!defined($opt_q)){
					print "  OK\n";
					STDOUT->autoflush(0);
				}
				return 1;
			}
			$found=1;
		}
		if($found==0){
			if(!defined($opt_q)){
				print "  ERROR\n";
				STDOUT->autoflush(0);
			}
			print STDERR "ERROR: Instance '$name' doesn't exist.\n";
			return;
		}
		if(!defined($opt_q)){print ".";}
		sleep(30);
	}
	return;
}
