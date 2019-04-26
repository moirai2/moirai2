<?php
$command=$_GET["command"];
//############################## insert.php ##############################
if($command=="insert"){
	$db=filterDatabasePath($_POST["db"]);
	$json=tmpjson($_POST["data"]);
	if($db==null)exit(1);
	if($json==null)exit(1);
	system("perl rdf.pl -d $db -f json insert < $json");
	unlink($json);
//############################## delete.php ##############################
}else if($command=="delete"){
	$db=filterDatabasePath($_POST["db"]);
	if($db==null)exit(1);
	$json=tmpjson($_POST["data"]);
	if($json==null)exit(1);
	system("perl rdf.pl -d $db -f json delete < $json");
	unlink($json);
	//############################## update.php ##############################
}else if($command=="update"){
	$db=filterDatabasePath($_POST["db"]);
	if($db==null)exit(1);
	$json=tmpjson($_POST["data"]);
	if($json==null)exit(1);
	system("perl rdf.pl -d $db -f json update < $json");
	unlink($json);
//############################## newnode.php ##############################
}else if($command=="newnode"){
	$_POST["db"]="20190216.sqlite3";
	$db=filterDatabasePath($_POST["db"]);
	if($db==null)exit(1);
	$id=trim(`perl rdf.pl -d $db newnode`);
	echo $id;
//############################## select.php ##############################
}else if($command == "select"){
	$db=filterDatabasePath($_POST["db"]);
	if($db==null)exit(1);
	$subject=isset($_POST["subject"])?escapeshellarg($_POST["subject"]):"?";
	$predicate=isset($_POST["predicate"])?escapeshellarg($_POST["predicate"]):"?";
	$object=isset($_POST["object"])?escapeshellarg($_POST["object"]):"?";
	$recursion=isset($_POST["recursion"])?escapeshellarg($_POST["recursion"]):0;
	$precursion=isset($_POST["precursion"])?escapeshellarg($_POST["precursion"]):0;
	echo `perl rdf.pl -d $db -R $precursion -r $recursion select $subject $predicate $object`;
//############################## query.php ##############################
}else if($command == "query"){
	$db=filterDatabasePath($_POST["db"]);
	if($db==null)exit(1);
	$json=tmpjson($_POST["query"]);
	if($json==null)exit(1);
	exec("perl rdf.pl -d $db query < $json",$array);
	foreach($array as $line){echo "$line\n";}
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
}else if($command == "proxy"){
	$url=$_POST["url"];
	if(startsWith($url,"http://osc-internal.gsc.riken.jp/~ah3q")){
	  $context=stream_context_create(array('http'=>array('header'=>"Authorization: Basic ".base64_encode("ah3q:has_q3ha"))));
	  echo file_get_contents(htmlspecialchars($url),false,$context);
	}else{
	  echo file_get_contents($url);
	}
//############################## upload.php ##############################
}else if($command == "upload"){
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
}else if($command == "write"){
	$filepath=$_POST["filepath"];
	$content=$_POST["content"];
	if(!isset($filepath))exit();
	$handler=fopen($filepath,'w');
	fwrite($handler,$content);
	fclose($handler);
//############################## zip.php ##############################
}else if($command == "zip"){
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
	//############################## printArray ##############################
	function printArray($array){
		$i=0;
		echo "[";
		foreach($array as $hash){
			$j=0;
			if($i>0)echo ",";
			echo "{";
			foreach(array_keys(get_object_vars($hash)) as $key){
				if($j>0)echo ",";
				$value=escapeReturnTab($hash->{$key});
				if(is_numeric($value))echo "\"$key\":$value";
				else echo "\"$key\":\"$value\"";
				$j++;
			}
			echo "}";
			$i++;
		}
		echo "]";
	}
	function escapeReturnTab($string){return str_replace("\'","\\\'",str_replace("\"","\\\"",str_replace("\r","\\r",str_replace("\t","\\t",str_replace("\n","\\n",str_replace("\\","\\\\",$string))))));}
//############################## startsWith ##############################
function startsWith($haystack,$needle){return (strpos($haystack,$needle)===0);}
//############################## insertEdge ##############################
function filterDatabasePath($db){return preg_replace("/[^a-zA-Z0-9\.\_]+/","",$db);}
//############################## tempjson ##############################
function tmpjson($data){
	if($data==null)return;
	$filepath=tempnam("/tmp","");
	$writer=fopen($filepath,"w");
	fwrite($writer,$data);
	fclose($writer);
	return $filepath;
}
?>