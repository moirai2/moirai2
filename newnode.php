<?php
$db=htmlspecialchars($_POST["db"]);
if($db==null)return;
$pdo=openDB($db);
echo newNode($pdo);
$pdo=null;
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
//############################## nodeMax ##############################
function nodeMax($pdo){
	try{
		$result=$pdo->query("SELECT max(`id`) FROM node")->fetchAll();
		return $result[0][0];
	}catch(Exception $e){echo $e->getMessage().PHP_EOL;}
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
?>
