<?php
$command=$_GET["command"];
//############################## delete.php ##############################
if($command=="delete"){
	if(!function_exists('json_decode')){
		function json_decode($content,$assoc=false){
			require_once 'js/JSON.php';
			if($assoc){
				$json=new Services_JSON(SERVICES_JSON_LOOSE_TYPE);
			}else{
				$json=new Services_JSON;
			}
			return $json->decode($content);
		}
	}
	if (!function_exists('json_encode')){
		function json_encode($content){
			require_once 'js/JSON.php';
			$json=new Services_JSON;
			return $json->encode($content);
		}
	}
	$db=htmlspecialchars($_POST["db"]);
	$json=json_decode($_POST["data"]);
	if($db==null)return;
	if($json==null)return;
	$pdo=openDB($db);
	echo deleteRDF($pdo,$json);
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
//############################## insert.php ##############################
}else if($command=="insert"){
	if(!function_exists('json_decode')){
		function json_decode($content,$assoc=false){
			require_once 'js/JSON.php';
			if($assoc){
				$json=new Services_JSON(SERVICES_JSON_LOOSE_TYPE);
			}else{
				$json=new Services_JSON;
			}
			return $json->decode($content);
		}
	}
	if (!function_exists('json_encode')){
		function json_encode($content){
			require_once 'js/JSON.php';
			$json=new Services_JSON;
			return $json->encode($content);
		}
	}
	$db=htmlspecialchars($_POST["db"]);
	$data=json_decode($_POST["data"]);
	if($db==null)return;
	if($data==null)return;
	$pdo=openDB($db);
	echo saveRDF($pdo,$data);
	$pdo=null;
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
//############################## newnode.php ##############################
}else if($command=="newnode"){
	$db=htmlspecialchars($_POST["db"]);
	if($db==null)return;
	$pdo=openDB($db);
	echo newNode($pdo);
	$pdo=null;
//############################## proxy.php ##############################
}else if($command == "proxy"){
	$url=$_POST["url"];
	if(startsWith($url,"http://osc-internal.gsc.riken.jp/~ah3q")){
	  $context=stream_context_create(array('http'=>array('header'=>"Authorization: Basic ".base64_encode("ah3q:has_q3ha"))));
	  echo file_get_contents(htmlspecialchars($url),false,$context);
	}else{
	  echo file_get_contents($url);
	}
//############################## query.php ##############################
}else if($command == "query"){
	$db=(isset($_POST["db"])&&strlen($_POST["db"])>0)?htmlspecialchars($_POST["db"]):NULL;
	$query=(isset($_POST["query"])&&strlen($_POST["query"])>0)?$_POST["query"]:NULL;
	if($db==NULL||$query==NULL)exit();
	exec("perl sqlite3.pl -d $db query",$array);
	foreach($array as $line)print "$line\n";
	$array=queryRdfDB(openDB($db),$query);
	printArray($array);
//############################## select.php ##############################
}else if($command == "select"){
	$db=(isset($_POST["db"])&&strlen($_POST["db"])>0)?htmlspecialchars($_POST["db"]):NULL;
	$subject=(isset($_POST["subject"])&&strlen($_POST["subject"])>0)?htmlspecialchars($_POST["subject"]):NULL;
	$predicate=(isset($_POST["predicate"])&&strlen($_POST["predicate"])>0)?htmlspecialchars($_POST["predicate"]):NULL;
	$object=(isset($_POST["object"])&&strlen($_POST["object"])>0)?htmlspecialchars($_POST["object"]):NULL;
	$recursion=(isset($_POST["recursion"])&&strlen($_POST["recursion"])>0)?htmlspecialchars($_POST["recursion"]):0;
	$precursion=(isset($_POST["precursion"])&&strlen($_POST["precursion"])>0)?htmlspecialchars($_POST["precursion"]):0;
	$class=(isset($_POST["class"])&&strlen($_POST["class"])>0)?htmlspecialchars($_POST["class"]):0;
	$rdf=loadRDF(openDB($db),$subject,$predicate,$object,$precursion,$recursion);
	$rdf->{"rdfquery"}=new stdClass();
	if($subject!=NULL)$rdf->{"rdfquery"}->{"subject"}=$subject;
	if($predicate!=NULL)$rdf->{"rdfquery"}->{"predicate"}=$predicate;
	if($object!=NULL)$rdf->{"rdfquery"}->{"object"}=$object;
	if($db!=NULL)$rdf->{"rdfquery"}->{"db"}=$db;
	if($recursion!=NULL)$rdf->{"rdfquery"}->{"recursion"}=$recursion;
	if($precursion!=NULL)$rdf->{"rdfquery"}->{"precursion"}=$precursion;
	if($class!=NULL)$rdf->{"rdfquery"}->{"class"}=$class;
	printRDF($rdf);
//############################## update.php ##############################
}else if($command == "update"){
	if(!function_exists('json_decode')){
		function json_decode($content,$assoc=false){
			require_once 'js/JSON.php';
			if($assoc){
				$json=new Services_JSON(SERVICES_JSON_LOOSE_TYPE);
			}else{
				$json=new Services_JSON;
			}
			return $json->decode($content);
		}
	}
	if (!function_exists('json_encode')){
		function json_encode($content){
			require_once 'js/JSON.php';
			$json=new Services_JSON;
			return $json->encode($content);
		}
	}
	$db=htmlspecialchars($_POST["db"]);
	$json=json_decode($_POST["data"]);
	if($db==null)return;
	if($json==null)return;
	$pdo=openDB($db);
	echo updateRDF($pdo,$json);
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
//############################## insertNode ##############################
function newNode($pdo){
	try{
		$pdo->exec("BEGIN EXCLUSIVE TRANSACTION");
		$id=nodeMax($pdo)+1;
		$name="_node$id"."_";
		$stmt=$pdo->prepare("INSERT OR IGNORE INTO `node` (`id`,`data`) VALUES (?,?)");
		$stmt->execute(array($id,$name));
		$pdo->exec("COMMIT");
		return $name;
	}catch(Exception $e){
		echo $e->getMessage().PHP_EOL;
		$pdo->exec("ROLLBACK");
	}
}
//############################## startsWith ##############################
function startsWith($haystack,$needle){return (strpos($haystack,$needle)===0);}
//############################## loadRdfFromDB ##############################
function queryRdfDB($pdo,$statement){
	try{
		$parsed=parseQuery($statement);
		$query=$parsed[0];
		$variables=$parsed[1];
		$array=array();
		$result=$pdo->query($query)->fetchAll();
		for($i=0;$i<count($result);$i++){
			$rdf=new stdClass();
			for($j=0;$j<count($result[$i]);$j++){$var=$variables[$j];if($var=="")continue;else $rdf->{$var}=$result[$i][$j];}
			array_push($array,$rdf);
		}
		return $array;
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
}
//############################## parseQuery ##############################
function parseQuery($statement){
	$edges=preg_split("/,/",$statement);
	$connects=array();
	$variables=array();
	$columns=array();
	$joins=array();
	$where_conditions=array();
	$connections=array();
	$edge_conditions=array();
	$node_index=0;
	for($i=0;$i<count($edges);$i++){
		$edge_name="e$i";
		$edge_line=($i>0)?"inner join ":"from ";
		$edge=$edges[$i];
		$nodes=preg_split("/->/",$edge);
		$wheres=array();
		for($j=0;$j<count($nodes);$j++){
			if($j==0)$rdf="subject";
			else if($j==1)$rdf="predicate";
			else if($j==2)$rdf="object";
			$node=$nodes[$j];
			$nodeRegisters=array();
			if($node==""){
			}else if(preg_match("/^\!(.+)$/",$node,$matches)){
				$var=$matches[1];
				array_push($where_conditions,"($edge_name.subject is null or $edge_name.subject not in (select subject from edge where $rdf=(select id from node where data='$var')))");
				if($i>0){$edge_line="left outer join ";}
			}else if(preg_match("/^\\\$(.+)$/",$node,$matches)){
				$node_name=$matches[1];
				if(!in_array($node_name,$variables)){
					array_push($variables,$node_name);
					array_push($nodeRegisters,$node_name);
				}
				if($connections[$node_name]==NULL)$connections[$node_name]=array();
				array_push($connections[$node_name],"$edge_name.$rdf");
			}else if(preg_match("/^\\((.+)\\)$/",$node,$matches)){
				$array=array();
				foreach(preg_split("/\\|/",$matches[1]) as $n){
					if(preg_match("/%/",$n)){array_push($array,"data like '$n'");}
					else{array_push($array,"data='$n'");}
					$node_index++;
				}
				array_push($wheres,"$rdf in (select id from node where ".join(" or ",$array).")");
			}else{
				array_push($wheres,"$rdf=(select id from node where data='$node')");
				$node_index++;
			}
			foreach($nodeRegisters as $node_name)array_push($joins,"inner join node as $node_name on $edge_name.$rdf=$node_name.id");
		}
		if(count($wheres)>0){$edge_line.="(select * from edge where ".join(" and ",$wheres).")";}
		else{$edge_line.="edge";}
		$connects[$edge_name]="$edge_line as $edge_name";
	}
	foreach($variables as $var)array_push($columns,"$var.data");
	foreach($connections as $connection){
		$before=$connection[0];
		for($i=1;$i<count($connection);$i++){
			$after=$connection[$i];
			$edge=substr($after,0,strpos($after,"."));
			if($edge_conditions[$edge]==NULL)$edge_conditions[$edge]=array();
			array_push($edge_conditions[$edge],"$after=$before");
			$before=$after;
		}
	}
	foreach(array_keys($edge_conditions) as $edge){
		$connects[$edge].=" on (".join(" and ",$edge_conditions[$edge]).")";
	}
	$connects2=array_values($connects);
	$query="select distinct ".join(", ",$columns)." ".join(" ",$connects2)." ".join(" ",$joins);
	if(count($where_conditions)>0)$query.=" where ".join(" and ",$where_conditions);
	return array($query,$variables);
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
//############################## escapeReturnTab ##############################
function escapeReturnTab($string){return str_replace("\'","\\\'",str_replace("\"","\\\"",str_replace("\r","\\r",str_replace("\t","\\t",str_replace("\n","\\n",str_replace("\\","\\\\",$string))))));}
//############################## loadRDF ##############################
function loadRDF($pdo,$subject=NULL,$predicate=NULL,$object=NULL,$precursion=0,$recursion=0){
	$rdf=loadRdfFromDB($pdo,$subject,$predicate,$object);
	$prevs=array();
	$nexts=array();
	$completed=array();
	foreach(array_keys(get_object_vars($rdf)) as $subject){
		$completed[$subject]=1;
		foreach(array_keys(get_object_vars($rdf->{$subject})) as $predicate){
			$object=$rdf->{$subject}->{$predicate};
			if(is_array($object))foreach($object as $o)$nexts[$o]=1;
			else $nexts[$object]=1;
		}
		$prevs[$subject]=1;
	}
	while($precursion>0){
		$keys=array_keys($prevs);
		$prevs=array();
		$rdf2=loadRdfFromDB($pdo,NULL,NULL,$keys);
		foreach(array_keys(get_object_vars($rdf2)) as $subject){
				if(array_key_exists($subject,$completed))continue;
				else $completed[$subject]=1;
				foreach(array_keys(get_object_vars($rdf2->{$subject})) as $predicate){
				$object=$rdf2->{$subject}->{$predicate};
				if(!property_exists($rdf,$subject))$rdf->{$subject}=new stdClass();
				if(!property_exists($rdf->{$subject},$predicate))$rdf->{$subject}->{$predicate}=$object;
				else if(is_array($rdf->{$subject}->{$predicate}))array_push($rdf->{$subject}->{$predicate},$object);
				else $rdf->{$subject}->{$predicate}=array($rdf->{$subject}->{$predicate},$object);
				$prevs[$subject]=1;
			}
		}
		$precursion--;
	}
	while($recursion>0){
		$keys=array_keys($nexts);
		$nexts=array();
		$rdf2=loadRdfFromDB($pdo,$keys);
		foreach(array_keys(get_object_vars($rdf2)) as $subject){
			if(array_key_exists($subject,$completed))continue;
			else $completed[$subject]=1;
			if(!property_exists($rdf,$subject))$rdf->{$subject}=new stdClass();
			foreach(array_keys(get_object_vars($rdf2->{$subject})) as $predicate){
				$object=$rdf2->{$subject}->{$predicate};
				if(!property_exists($rdf->{$subject},$predicate))$rdf->{$subject}->{$predicate}=$object;
				else if(is_array($rdf->{$subject}->{$predicate}))array_push($rdf->{$subject}->{$predicate},$object);
				else $rdf->{$subject}->{$predicate}=array($rdf->{$subject}->{$predicate},$object);
				if(is_array($object))foreach($object as $o)$nexts[$o]=1;
				else $nexts[$object]=1;
			}
		}
		$recursion--;
	}
	return $rdf;
}
//############################## loadRdfFromWeb ##############################
function loadRdfFromWeb($url,$username=NULL,$password=NULL){
	try{
		if($username!=NULL&&$password!=NULL)$context=stream_context_create(array('http'=>array('header'=>"Authorization: Basic ".base64_encode("$username:$password"))));
		$content=file_get_contents($url,false,$context);
		return json_decode($content);
	}catch(Exception $e){echo "ERROR";}
}
//############################## loadRdfFromDB ##############################
function loadRdfFromDB($pdo,$subject=NULL,$predicate=NULL,$object=NULL){
	try{
		$query="select distinct n1.data,n2.data,n3.data from edge as e1 join node as n1 on e1.subject=n1.id join node as n2 on e1.predicate=n2.id join node as n3 on e1.object=n3.id";
		$where="";
		if($subject!==NULL){
			if(strlen($where)>0)$where.=" and";
			if(is_array($subject))$where.=" e1.subject in (select id from node where data in (\"".join("\",\"",$subject)."\"))";
			else $where.=" e1.subject=(select id from node where data='$subject')";
		}
		if($predicate!==NULL){
			if(strlen($where)>0)$where.=" and";
			if(is_array($predicate))$where.=" e1.predicate in (select id from node where data in (\"".join("\",\"",$predicate)."\"))";
			else $where.=" e1.predicate=(select id from node where data='$predicate')";
		}
		if($object!==NULL){
			if(strlen($where)>0)$where.=" and";
			if(is_array($object))$where.=" e1.object in (select id from node where data in (\"".join("\",\"",$object)."\"))";
			else $where.=" e1.object=(select id from node where data='$object')";
		}
		if($where!=="")$query.=" where$where";
		$result=$pdo->query($query)->fetchAll();
		$rdf=new stdClass();
		for($i=0;$i<count($result);$i++){
			$subject=$result[$i][0];
			$predicate=$result[$i][1];
			$object=$result[$i][2];
			if(!property_exists($rdf,$subject))$rdf->{$subject}=new stdClass();
			if(!property_exists($rdf->{$subject},$predicate))$rdf->{$subject}->{$predicate}=$object;
			else if(is_array($rdf->{$subject}->{$predicate}))array_push($rdf->{$subject}->{$predicate},$object);
			else $rdf->{$subject}->{$predicate}=array($rdf->{$subject}->{$predicate},$object);
		}
		return $rdf;
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
}
//############################## printRDF ##############################
function printRDF($rdf){
	$i=0;
	echo "{";
	if($rdf!=NULL){
		foreach(array_keys(get_object_vars($rdf)) as $subject){
			if($i>0)echo ",";
			if(is_object($rdf->{$subject})){
				echo "\"$subject\":{";
				$j=0;
				foreach(array_keys(get_object_vars($rdf->{$subject})) as $predicate){
					if($j)echo ",";
					echo "\"$predicate\":";
					$object=$rdf->{$subject}->{$predicate};
					if(is_array($object)){
						$k=0;
						echo "[";
						foreach($object as $o){
							if($k>0)echo ",";
							if(is_numeric($o))echo escapeReturnTab($o);
							else echo "\"".escapeReturnTab($o)."\"";
							$k++;
						}
						echo "]";
					}else{
						if(is_numeric($object))echo escapeReturnTab($object);
						else echo "\"".escapeReturnTab($object)."\"";
					}
					$j++;
				}
				echo "}";
			}else{
				echo "\"$subject\":\"".$rdf->{$subject}."\"";
			}
			$i++;
		}
	}
	echo "}";
}
//############################## updateRDF ##############################
function updateRDF($pdo,$json){
	try{
		$pdo->exec("BEGIN EXCLUSIVE TRANSACTION");
		foreach(array_keys(get_object_vars($json)) as $subject){
			$subject_id=handleNode($pdo,$subject);
			foreach(array_keys(get_object_vars($json->{$subject})) as $predicate){
				$predicate_id=handleNode($pdo,$predicate);
				$object=$json->{$subject}->{$predicate};
				if(is_array($object)){
					foreach($object as $o){
						$object_id=handleNode($pdo,$o);
						updateEdge($pdo,$subject_id,$predicate_id,$object_id);
					}
				}else if(is_object($object)){
					foreach(array_keys(get_object_vars($object)) as $o){
						$object_id=handleNode($pdo,$o);
						updateEdge($pdo,$subject_id,$predicate_id,$object_id);
						updateRDF($pdo,$object);//recursion (maybe this might not wok since exclusive transaction will be looped)
					}
				}else{
					$object_id=handleNode($pdo,$object);
					updateEdge($pdo,$subject_id,$predicate_id,$object_id);
				}
			}
		}
		$pdo->exec("COMMIT");
		return 1;
	}catch(Exception $e){
		echo $e->getMessage().PHP_EOL;
		$pdo->exec("ROLLBACK");
		return 0;
	}
}
//############################## data2id ##############################
function data2id($pdo,$data){
	try{
		$stmt=$pdo->prepare("SELECT id FROM node WHERE data=?");
		$stmt->execute(array($data));
		$result=$stmt->fetchAll();
		return $result[0]["id"];
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
}
//############################## updateEdge ##############################
function updateEdge($pdo,$subject_id,$predicate_id,$object_id){
	try{
		$stmt=$pdo->prepare("UPDATE `edge` SET `object`=? where `subject`=? and `predicate`=?");
		$stmt->execute(array($object_id,$subject_id,$predicate_id));
		$stmt=$pdo->prepare("INSERT OR IGNORE INTO `edge` VALUES (?,?,?)");
		$stmt->execute(array($subject_id,$predicate_id,$object_id));
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
}

//############################## deleteRDF ##############################
function deleteRDF($pdo,$json){
	try{
		$pdo->exec("BEGIN EXCLUSIVE TRANSACTION");
		foreach(array_keys(get_object_vars($json)) as $subject){
			$subject_id=handleNode($pdo,$subject);
			foreach(array_keys(get_object_vars($json->{$subject})) as $predicate){
				$predicate_id=handleNode($pdo,$predicate);
				$object=$json->{$subject}->{$predicate};
				if(is_array($object)){
					foreach($object as $o){
						$object_id=handleNode($pdo,$o);
						deleteEdge($pdo,$subject_id,$predicate_id,$object_id);
					}
				}else if(is_object($object)){
					foreach(array_keys(get_object_vars($object)) as $o){
						$object_id=handleNode($pdo,$o);
						deleteEdge($pdo,$subject_id,$predicate_id,$object_id);
					}
				}else{
					$object_id=handleNode($pdo,$object);
					deleteEdge($pdo,$subject_id,$predicate_id,$object_id);
				}
			}
		}
		$pdo->exec("COMMIT");
		return 1;
	}catch(Exception $e){
		echo $e->getMessage().PHP_EOL;
		$pdo->exec("ROLLBACK");
		return 0;
	}
}
//############################## openDB ##############################
function openDB($db){
	try{
		if($db=="")$db="rdf.sqlite3";
		$exists=file_exists($db);
		$pdo=new PDO('sqlite:'.$db);
		$pdo->exec("CREATE TABLE IF NOT EXISTS node(id INTEGER PRIMARY KEY,data TEXT)");
		$pdo->exec("CREATE TABLE IF NOT EXISTS edge(subject INTEGER,predicate INTEGER,object INTEGER,PRIMARY KEY (subject,predicate,object))");
		if(!$exists)chmod($db,0777);
		return $pdo;
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
}
//############################## deleteEdge ##############################
function deleteEdge($pdo,$subject_id,$predicate_id,$object_id){
	try{
		$stmt=$pdo->prepare("DELETE  FROM `edge` where `subject`=? and `predicate`=? and `object`=?");
		$stmt->execute(array($subject_id,$predicate_id,$object_id));
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
}
//############################## saveRDF ##############################
function saveRDF($pdo,$json){
	try{
		$pdo->exec("BEGIN EXCLUSIVE TRANSACTION");
		foreach(array_keys(get_object_vars($json)) as $subject){
			$subject_id=handleNode($pdo,$subject);
			foreach(array_keys(get_object_vars($json->{$subject})) as $predicate){
				$predicate_id=handleNode($pdo,$predicate);
				$object=$json->{$subject}->{$predicate};
				if(is_array($object)){
					foreach($object as $o){
						$object_id=handleNode($pdo,$o);
						insertEdge($pdo,$subject_id,$predicate_id,$object_id);
					}
				}else if(is_object($object)){
					foreach(array_keys(get_object_vars($object)) as $o){
						$object_id=handleNode($pdo,$o);
						insertEdge($pdo,$subject_id,$predicate_id,$object_id);
						saveRDF($pdo,$object);
					}
				}else{
					$object_id=handleNode($pdo,$object);
					insertEdge($pdo,$subject_id,$predicate_id,$object_id);
				}
			}
		}
		$pdo->exec("COMMIT");
		return 1;
	}catch(Exception $e){
		echo $e->getMessage().PHP_EOL;
		$pdo->exec("ROLLBACK");
		return 0;
	}
}
//############################## nodeSize ##############################
function nodeSize($pdo){
	try{
		$result=$pdo->query("SELECT count(*) FROM `node`")->fetchAll();
		return $result[0]["count(*)"];
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
}
//############################## nodeMax ##############################
function nodeMax($pdo){
	try{
		$result=$pdo->query("SELECT max(id) FROM node")->fetchAll();
		return $result[0]["max(id)"];
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
}
//############################## id2data ##############################
function id2data($pdo,$id){
	try{
		$stmt=$pdo->prepare("SELECT data FROM node WHERE id=?");
		$stmt->execute(array($id));
		$result=$stmt->fetchAll();
		return $result[0]["data"];
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
}
//############################## handleNode ##############################
function handleNode($pdo,$data){
	$id=data2id($pdo,$data);
	if($id!="")return $id;
	return insertNode($pdo,$data);
}
//############################## insertNode ##############################
function insertNode($pdo,$data){
	try{
		$size=nodeMax($pdo);
		$stmt=$pdo->prepare("INSERT OR IGNORE INTO `node` (`id`,`data`) VALUES (?,?)");
		$stmt->execute(array($size+1,$data));
		return $size+1;
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
}
//############################## insertEdge ##############################
function insertEdge($pdo,$subject_id,$predicate_id,$object_id){
	try{
		$stmt=$pdo->prepare("INSERT OR IGNORE INTO `edge` (`subject`,`predicate`,`object`) VALUES (?,?,?)");
		$stmt->execute(array($subject_id,$predicate_id,$object_id));
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
}
?>
