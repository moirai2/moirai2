<?php
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
	function startsWith($haystack,$needle){return (strpos($haystack,$needle)===0);}
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
