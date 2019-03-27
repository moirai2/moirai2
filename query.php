<?php
	$db=(isset($_POST["db"])&&strlen($_POST["db"])>0)?htmlspecialchars($_POST["db"]):NULL;
	$query=(isset($_POST["query"])&&strlen($_POST["query"])>0)?$_POST["query"]:NULL;
	if($db==NULL||$query==NULL)exit();
	$array=queryRdfDB(openDB($db),$query);
	printArray($array);
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
	function escapeReturnTab($string){return str_replace("\'","\\\'",str_replace("\"","\\\"",str_replace("\r","\\r",str_replace("\t","\\t",str_replace("\n","\\n",str_replace("\\","\\\\",$string))))));}
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
	?>
