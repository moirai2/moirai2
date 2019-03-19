<?php
	try{
		$path=htmlspecialchars($_POST["path"]);
		echo file_exists($path)?"true":"false";
	}catch(Exception $e){echo "ERROR";}
	?>
