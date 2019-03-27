<?php
$uploaddir="uploaded";
if(!file_exists($uploaddir))mkdir($uploaddir);
chmod($uploaddir,0777);
$directory="$uploaddir/".time();
if(!file_exists($directory))mkdir($directory);
chmod($directory,0777);
$path="$directory/".basename($_FILES['file']['name']);
if(move_uploaded_file($_FILES['file']['tmp_name'],"$path")){chmod("$path",0777);echo $path;}
else echo "ERROR";
?>
