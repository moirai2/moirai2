<?php
$command=$_GET["command"];
//############################## submit.php ##############################
if($command=="submit"){
	foreach($_POST as $key=>$value){$params[$key]=$value;}
	$db=filterDatabasePath($params["rdfdb"]);
	if($db==null)exit(1);
	unset($params["rdfdb"]);
	$ctrldir=basename($db);
	if(preg_match("/^([^\.]+)\./",$ctrldir,$matches)){$ctrldir=$matches[1];}
	$tsv=tmpData($params);
	chmod($tsv,0777);
	if($tsv==null)exit(1);
	if(!file_exists($ctrldir)){mkdir($ctrldir);chmod($ctrldir,0777);}
	if(!file_exists("$ctrldir/ctrl")){mkdir("$ctrldir/ctrl");chmod("$ctrldir/ctrl",0777);}
	if(!file_exists("$ctrldir/ctrl/submit")){mkdir("$ctrldir/ctrl/submit");chmod("$ctrldir/ctrl/submit",0777);}
	rename($tsv,"$ctrldir/ctrl/submit/".basename($tsv).".txt");
//############################## insert.php ##############################
}else if($command=="insert"){
	$db=filterDatabasePath($_POST["rdfdb"]);
	if($db==null)exit(1);
	$file=tmpData($_POST["data"]);
	if($file==null)exit(1);
	system("perl rdf.pl -q -d $db -f json insert < $file");
	unlink($file);
//############################## delete.php ##############################
}else if($command=="delete"){
	$db=filterDatabasePath($_POST["rdfdb"]);
	if($db==null)exit(1);
	$json=tmpData($_POST["data"]);
	if($json==null)exit(1);
	system("perl rdf.pl -d $db -f json delete < $json");
	unlink($json);
	//############################## update.php ##############################
}else if($command=="update"){
	$db=filterDatabasePath($_POST["rdfdb"]);
	if($db==null)exit(1);
	$json=tmpData($_POST["data"]);
	if($json==null)exit(1);
	system("perl rdf.pl -d $db -f json update < $json");
	unlink($json);
//############################## newnode.php ##############################
}else if($command=="newnode"){
	$db=filterDatabasePath($_POST["rdfdb"]);
	if($db==null)exit(1);
	$id=trim(`perl rdf.pl -d $db newnode`);
	echo $id;
//############################## command.php ##############################
}else if($command=="command"){
	$db=filterDatabasePath($_POST["rdfdb"]);
	$json=tmpData($_POST["data"]);
	if($db==null)exit(1);
	$id=trim(`perl rdf.pl -d $db -f json command < $json`);
	unlink($json);
	echo $id;
//############################## select.php ##############################
}else if($command=="select"){
	$db=filterDatabasePath($_POST["rdfdb"]);
	if($db==null)exit(1);
	$json=tmpData($_POST["query"]);
	if($json==null)exit(1);
	exec("perl rdf.pl -d $db select < $json",$array);
	unlink($json);
	foreach($array as $line){echo "$line\n";}
//############################## query.php ##############################
}else if($command=="query"){
	$db=filterDatabasePath($_POST["rdfdb"]);
	if($db==null)exit(1);
	$json=tmpData($_POST["query"]);
	if($json==null)exit(1);
	exec("perl rdf.pl -d $db query < $json",$array);
	unlink($json);
	foreach($array as $line){echo "$line\n";}
//############################## symlink.php ##############################
}else if($command=="symlink"){
	$url=(isset($_POST["url"])&&strlen($_POST["url"])>0)?htmlspecialchars($_POST["url"]):NULL;
	if($url==NULL)exit();
	$filename=(isset($_POST["filename"])&&strlen($_POST["filename"])>0)?htmlspecialchars($_POST["filename"]):NULL;
	if($filename==null)$filename=basename($url);
	$symlinkdir="symlink";
	if(!file_exists($symlinkdir))mkdir($symlinkdir);
	chmod($symlinkdir,0777);
	$directory="$symlinkdir/".time();
	if(!file_exists($directory))mkdir($directory);
	chmod($directory,0777);
	$path="$directory/$filename";
	system("ln -s $url $path");
	echo $path;
//############################## download.php ##############################
}else if($command=="download"){
	try{
		$url=(isset($_POST["url"])&&strlen($_POST["url"])>0)?htmlspecialchars($_POST["url"]):NULL;
		if($url==NULL)exit();
		$path=(isset($_POST["path"])&&strlen($_POST["path"])>0)?htmlspecialchars($_POST["path"]):NULL;
		if($path!==NULL){
			$uploaddir=dirname($path);
			if(!file_exists($uploaddir)){mkdir($uploaddir,0777,true);chmod($uploaddir,0777);}
			$reader=fopen($url,'rb');
			$writer=fopen("$path",'wb');
			while(!feof($reader))fwrite($writer,fread($reader,4096),4096);
			fclose($reader);
			fclose($writer);
			chmod("$path",0777);
			echo $path;
		}else{
			$filename=(isset($_POST["filename"])&&strlen($_POST["filename"])>0)?htmlspecialchars($_POST["filename"]):NULL;
			if($filename==null)$filename=basename($url);
			$uploaddir="uploaded";
			if(!file_exists($uploaddir))mkdir($uploaddir);
			chmod($uploaddir,0777);
			$directory="$uploaddir/".time();
			if(!file_exists($directory))mkdir($directory);
			chmod($directory,0777);
			$reader=fopen($url,'rb');
			$path="$directory/$filename";
			$writer=fopen("$path",'wb');
			while(!feof($reader))fwrite($writer,fread($reader,4096),4096);
			fclose($reader);
			fclose($writer);
			chmod("$path",0777);
			echo $path;
		}
	}catch(Exception $e){echo "ERROR";}
//############################## ls.php ##############################
}else if($command=="ls"){
	$directory=$_POST["directory"];
	$suffix=$_POST["filesuffix"];
	$depth=$_POST["depth"];
	$getDir=$_POST["getDir"];
	$getFile=$_POST["getFile"];
	$detail=$_POST["detail"];
	$grep=$_POST["grep"];
	if($depth==NULL)$depth=1;
	if($getFile==NULL)$getFile=1;
	if($getDir==NULL)$getDir=0;
	$files=ls_file($directory,$depth,$grep,$suffix,$getFile,$getDir,$detail,array());
	echo "[";
	$i=0;
	foreach($files as $file){
		if($i>0)echo ",";
		if(is_array($file)){
			echo "{";
			$j=0;
			foreach(array_keys($file) as $s){
				if($j>0)echo ",";
				echo "\"$s\":\"".$file[$s]."\"";
				$j++;
			}
			echo "}";
		}else echo "\"$file\"\n";
		$i++;
	}
	echo "]";
//############################## proxy.php ##############################
}else if($command=="proxy"){
	$url=$_POST["url"];
	echo file_get_contents($url);
//############################## upload.php ##############################
}else if($command=="upload"){
	$uploaddir="uploaded";
	if(!file_exists($uploaddir))mkdir($uploaddir);
	chmod($uploaddir,0777);
	$directory="$uploaddir/".time();
	if(!file_exists($directory))mkdir($directory);
	chmod($directory,0777);
	$path="$directory/".basename($_FILES['file']['name']);
	if(move_uploaded_file($_FILES['file']['tmp_name'],"$path")){chmod("$path",0777);echo $path;}
	else echo "ERROR";
//############################## write.php ##############################
}else if($command=="write"){
	$filepath=$_POST["filepath"];
	$content=$_POST["content"];
	if(!isset($filepath))exit();
	$handler=fopen($filepath,'w');
	fwrite($handler,$content);
	fclose($handler);
//############################## zip.php ##############################
}else if($command=="zip"){
	$directory=$_GET["directory"];
	$directory="input";
	if(!isset($directory))exit();
	$zip=new ZipArchive();
	$zipFilepath=tempnam(sys_get_temp_dir(),"download");
	$downloadName="download.zip";
	$result=$zip->open($zipFilepath,ZIPARCHIVE::CREATE|ZIPARCHIVE::OVERWRITE);
	if($result!==true){exit();}
	foreach(list_file($directory)as $file){
		$filename=basename($file);
		$dirname=dirname($file);
		if($dirname!=""&&$dirname!=".")$zip->addEmptyDir($dirname);
		$zip->addFromString($file,file_get_contents($file));
	}
	$zip->close();
	header('Content-Disposition:attachment;filename="'.$downloadName.'"');
	header('Content-Type:application/zip;name="'.$downloadName.'"');
	header('Content-Length:'.filesize($zipFilepath));
	echo file_get_contents($zipFilepath);
	unlink($zipFilepath);
//############################## default ##############################
}else{
}
//############################## ls_file ##############################
function ls_file($path,$depth=1,$grep,$suffix,$getFile=1,$getDir=0,$detail=0,$array){
	if($array==NULL)$array=array();
	if(is_dir($path)){
		if($getDir)if($grep==""||preg_match("/$grep/",$path)){
			if($detail)array_push($array,array("path"=>$path,"mtime"=>date("Y/m/d H:i:s",filemtime($path)),"atime"=>date("Y/m/d H:i:s",fileatime($path)),"ctime"=>date("Y/m/d H:i:s",filectime($path)),"group"=>posix_getpwuid(filegroup($path))["name"],"owner"=>posix_getpwuid(fileowner($path))["name"],"type"=>filetype($path),"size"=>filesize($path),"perms"=>substr(sprintf('%o',fileperms($path)),-3)));
			else array_push($array,$path);
		}
		$reader=opendir($path);
		while(false!==($names[]=readdir($reader)));
		closedir($reader);
		sort($names);
		foreach($names as $name){
			if($name==""  )continue;
			if($name=="." )continue;
			if($name=="..")continue;
			if($path!="" && $path!="."){$name="$path/$name";}
			if($depth!=0)$array=ls_file($name,$depth-1,$grep,$suffix,$getFile,$getDir,$detail,$array);
		}
	}else if(is_file($path)||is_link($path)){
		if($getFile==0){return $array;}
		if($grep!=""&&!preg_match("/$grep/",$path)){return $array;}
		if($suffix!=""&&!preg_match("/$suffix$/",$path)){return $array;}
		if($detail)array_push($array,array("path"=>$path,"mtime"=>date("Y/m/d H:i:s",filemtime($path)),"atime"=>date("Y/m/d H:i:s",fileatime($path)),"ctime"=>date("Y/m/d H:i:s",filectime($path)),"group"=>posix_getpwuid(filegroup($path))["name"],"owner"=>posix_getpwuid(fileowner($path))["name"],"type"=>filetype($path),"size"=>filesize($path),"perms"=>substr(sprintf('%o',fileperms($path)),-3)));
		else array_push($array,$path);
	}
	return $array;
}
// ############################## list_file ##############################
function list_file($path,$recursive=-1,$add_directory=0,$suffix="",$array=NULL){
	if($array==NULL)$array=array();
	if(is_file($path)){
		if(!preg_match("/$suffix$/",$path))return $array;
		array_push($array,$path);
	}else if(is_link($path)){
		if(!preg_match("/$suffix$/",$path))return $array;
		array_push($array,$path);
	}else if(is_dir($path)){
		$reader=opendir($path);
		while(false!==($names[]=readdir($reader)));
		closedir($reader);
		sort($names);
		foreach($names as $name){
			$basename=basename($name);
			if($basename=="")continue;
			if(preg_match("/^\\./",$basename))continue;
			if($path!="" && $path!="."){ $name="$path/$name"; }
			if(is_file($name)){
				if(preg_match("/$suffix$/",$basename))array_push($array,$name);
			}else if(is_dir($name)){
				if($add_directory)array_push($array,"$name/");
				if($recursive!=0)$array=list_file($name,$recursive-1,$add_directory,$suffix,$array);
			}
		}
	}
	return $array;
}
//############################## filterDatabasePath ##############################
function filterDatabasePath($db){return preg_replace("/[^a-zA-Z0-9\.\_]+/","",$db);}
//############################## tmpData ##############################
function tmpData($data){
	if($data==null)return;
	if(!file_exists("tmp")){mkdir("tmp");chmod("tmp",0777);}
	$filepath=tempnam("tmp","tmp");
	$writer=fopen($filepath,"w");
	if(is_array($data)){
		foreach($data as $key=>$value){
			fwrite($writer,"$key\t$value\n");
		}
	}else{
		fwrite($writer,$data);
	}
	fclose($writer);
	return $filepath;
}
?>
