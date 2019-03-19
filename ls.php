<?php
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
	//$detail=1;
	//$directory=".";
	$files=list_file($directory,$depth,$grep,$suffix,$getFile,$getDir,$detail,array());
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
	function list_file($path,$depth=1,$grep,$suffix,$getFile=1,$getDir=0,$detail=0,$array){
		if($array==NULL)$array=array();// create new array if needed
		if(is_dir($path)){// directory
			if($getDir)if($grep==""||preg_match("/$grep/",$path)){
				if($detail)array_push($array,array("path"=>$path,"mtime"=>date("Y/m/d H:i:s",filemtime($path)),"atime"=>date("Y/m/d H:i:s",fileatime($path)),"ctime"=>date("Y/m/d H:i:s",filectime($path)),"group"=>posix_getpwuid(filegroup($path))["name"],"owner"=>posix_getpwuid(fileowner($path))["name"],"type"=>filetype($path),"size"=>filesize($path),"perms"=>substr(sprintf('%o',fileperms($path)),-3)));
				else array_push($array,$path);
			}
			$reader=opendir($path);// open directory reader
			while(false!==($names[]=readdir($reader)));// copy into an array
			closedir($reader);// close directory reader
			sort($names);// sort by name
			foreach($names as $name){// go through all files
				if($name==""  )continue;// This is added for some strange reason.
				if($name=="." )continue;// skip current directory
				if($name=="..")continue;// skip previous directory
				if($path!="" && $path!="."){$name="$path/$name";}// add path
				if($depth!=0)$array=list_file($name,$depth-1,$grep,$suffix,$getFile,$getDir,$detail,$array);// gives a pointer of an array
			}
		}else if(is_file($path)||is_link($path)){// file
			if($getFile==0){return $array;}
			if($grep!=""&&!preg_match("/$grep/",$path)){return $array;}
			if($suffix!=""&&!preg_match("/$suffix$/",$path)){return $array;}
			if($detail)array_push($array,array("path"=>$path,"mtime"=>date("Y/m/d H:i:s",filemtime($path)),"atime"=>date("Y/m/d H:i:s",fileatime($path)),"ctime"=>date("Y/m/d H:i:s",filectime($path)),"group"=>posix_getpwuid(filegroup($path))["name"],"owner"=>posix_getpwuid(fileowner($path))["name"],"type"=>filetype($path),"size"=>filesize($path),"perms"=>substr(sprintf('%o',fileperms($path)),-3)));
			else array_push($array,$path);
		}
		return $array;// return array
	}
	?>
