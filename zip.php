<?php
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
?>
