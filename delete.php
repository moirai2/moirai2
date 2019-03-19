<?php
	if(!function_exists('json_decode')){
		function json_decode($content,$assoc=false){
			require_once 'JSON.php';
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
			require_once 'JSON.php';
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
	//############################## nodeSize ##############################
	function nodeSize($pdo){
		try{
			$result=$pdo->query("SELECT count(*) FROM `node`")->fetchAll();
			return $result[0]["count(*)"];
		}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
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
			$size=nodeSize($pdo);
			$stmt=$pdo->prepare("INSERT OR IGNORE INTO `node` (`id`,`data`) VALUES (?,?)");
			$stmt->execute(array($size+1,$data));
			return $size+1;
		}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
	}
	//############################## deleteEdge ##############################
	function deleteEdge($pdo,$subject_id,$predicate_id,$object_id){
		try{
			$stmt=$pdo->prepare("DELETE  FROM `edge` where `subject`=? and `predicate`=? and `object`=?");
			$stmt->execute(array($subject_id,$predicate_id,$object_id));
		}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
	}
	?>
