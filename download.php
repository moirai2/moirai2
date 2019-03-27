<?php
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
?>
