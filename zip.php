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
// list files under a directory
function list_file($path,$recursive=-1,$add_directory=0,$suffix="",$array=NULL){
	if( $array == NULL ) $array = array(); // create new array if needed
	if( is_file( $path ) ) { // file
		if( ! preg_match( "/$suffix$/", $path ) ) return $array;
		array_push( $array, $path ); // remember
	} else if( is_link( $path ) ) { // file
		if( ! preg_match( "/$suffix$/", $path ) ) return $array;
		array_push( $array, $path ); // remember
	} else if( is_dir( $path ) ) { // directory
		$reader = opendir( $path ); // open directory reader
		while( false !== ( $names[] = readdir( $reader ) ) ); // copy into an array
		closedir( $reader ); // close directory reader
		sort( $names ); // sort by name
		foreach( $names as $name ) { // go through all files
			$basename = basename( $name );
			if( $basename == ""   ) continue; // This is added for some strange reason.
			if( preg_match( "/^\\./", $basename ) ) continue; // skip ".", "..", ".bash=profile"
			//if( $basename == "."  ) continue; // skip current directory
			//if( $basename == ".." ) continue; // skip previous directory
			if( $path != "" && $path != "." ) { $name = "$path/$name"; } // add path
			if( is_file( $name ) ) { // it is a file!!
				if( preg_match( "/$suffix$/", $basename ) ) array_push( $array, $name ); // remember
			} else if( is_dir( $name ) ) { // it is a directory!!
				if( $add_directory ) array_push( $array, "$name/" );
				if( $recursive != 0 ) $array = list_file( $name, $recursive - 1, $add_directory, $suffix, $array );
			}
		}
	}
	return $array; // return array
}
?>
