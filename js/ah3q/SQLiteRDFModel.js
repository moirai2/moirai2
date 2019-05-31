function SQLiteRDFModel(db){
	this.db=db;
	this.address=window.location.href;
	if(this.address.substr(0,4)=="file")alert("'SqliteRDFModel.js' library uses PHP.  Please access through server.");
	this.timeStampUrl="http://localhost/~ah3q/schema/upload/timestamp";
	this.fileUrl="http://localhost/~ah3q/schema/upload/file";
	this.fileContentUrl="http://localhost/~ah3q/schema/upload/filecontent";
	this.linkUrl="http://localhost/~ah3q/schema/upload/link";
	this.textUrl="http://localhost/~ah3q/schema/upload/text";
	this.md5Url="http://localhost/~ah3q/schema/upload/md5";
	this.fileFormatUrl="http://localhost/~ah3q/schema/command/fileformat";
	this.commandUrl="http://localhost/~ah3q/schema/command/command";
	this.inputUrl="http://localhost/~ah3q/schema/command/input";
	this.parameterUrl="http://localhost/~ah3q/schema/command/parameter";
	this.outputUrl="http://localhost/~ah3q/schema/command/output";
	this.executedCommandUrl="http://localhost/~ah3q/schema/command/executedcommand";
	this.bashScriptUrl="http://localhost/~ah3q/schema/command/bashscript";
	this.propertyUrl="http://localhost/~ah3q/schema/property/property";
	this.commandRootUrl="http://localhost/~ah3q/command/";
	this.fileFormatRootUrl="http://localhost/~ah3q/fileformat/";
}
SQLiteRDFModel.prototype.rdfToNetwork=function(rdf){
	var hash={};
	var edges=[];
	var subjects=Object.keys(rdf);
	for(var i=0;i<subjects.length;i++){
		var subject=subjects[i];
		if(!(subject in hash)){hash[subject]=Object.keys(hash).length;}
		var subjectid=hash[subject];
		var predicates=Object.keys(rdf[subject]);
		for(var j=0;j<predicates.length;j++){
			var predicate=predicates[j];
			var predicateid=predicate;
			predicateid=predicateid.replace("http://localhost/~ah3q/schema/","s:");
			predicateid=predicateid.replace("http://localhost/~ah3q/javascript/2018/command/","m:");
			predicateid=predicateid.replace("http://localhost/~ah3q/javascript/2018/control/","c:");
			var object=rdf[subject][predicate];
			if(!Array.isArray(object))object=[object];
			for(var k=0;k<object.length;k++){
				var o=object[k];
				if(!(o in hash)){hash[o]=Object.keys(hash).length;}
				var objectid=hash[o];
				edges.push({from:subjectid,to:objectid,label:predicateid});
			}
		}
	}
	var nodes=[];
	var labels=Object.keys(hash);
	for(var i=0;i<labels.length;i++){
		var label=labels[i];
		var id=hash[label];
		nodes.push({id:id,label:label});
	}
	return {nodes:nodes,edges:edges};
}
SQLiteRDFModel.prototype.getSubjects=function(rdf){var hashtable={};Object.keys(rdf).forEach(function(s){hashtable[s]=1;});return Object.keys(hashtable);}
SQLiteRDFModel.prototype.getPredicates=function(rdf){var hashtable={};Object.keys(rdf).forEach(function(s){Object.keys(rdf[s]).forEach(function(p){hashtable[p]=1;});});return Object.keys(hashtable);}
SQLiteRDFModel.prototype.getObjects=function(rdf){var hashtable={};Object.keys(rdf).forEach(function(s){Object.keys(rdf[s]).forEach(function(p){var o=rdf[s][p];if(Array.isArray(o)){o.forEach(function(v){hashtable[v]=1;});}else{hashtable[o]=1;}});});return Object.keys(hashtable);}
SQLiteRDFModel.prototype.getRDF=function(rdf,json){
	var self=this;
	var subject=json.subject;
	var predicate=json.predicate;
	var object=json.object;
	var excludeSubject=json.excludeSubject;
	var excludePredicate=json.excludePredicate;
	var excludeObject=json.excludeObject;
	var hash={};
	Object.keys(rdf).forEach(function(s){
		if(subject!=null&&s!=subject)return;
		if(excludeSubject!=null&&s==excludeSubject)return;
		Object.keys(rdf[s]).forEach(function(p){
			if(predicate!=null&&p!=predicate)return;
			if(excludePredicate!=null&&p==excludePredicate)return;
			if(!(s in hash))hash[s]={};
			var o=rdf[s][p];
			if(Array.isArray(o)){
				o.forEach(function(v){
					if(object!=null&&v!=object)return;
					if(excludeObject!=null&&v==excludeObject)return;
					if(!(p in hash[s]))hash[s][p]=v;
					else if(Array.isArray(hash[s][p]))hash[s][p].push(v);
					else hash[s][p]=[hash[s][p],v];
				});
			}else{
				if(object!=null&&o!=object)return;
				if(excludeObject!=null&&o==excludeObject)return;
				if(!(p in hash[s]))hash[s][p]=o;
				else if(Array.isArray(hash[s][p]))hash[s][p].push(o);
				else hash[s][p]=[hash[s][p],o];
			}
		});
	});
	return hash;
}
SQLiteRDFModel.prototype.jsonEscape=function(string){if(string==null)return;return string.replace(/\n/g,"\\\\n").replace(/\r/g,"\\\\r").replace(/\t/g,"\\\\t");}
SQLiteRDFModel.prototype.queryRDF=function(json,method){
	var self=this;
	if(!("db" in json))json.db=this.db;
	console.log(json);
	var post=$.ajax({type:'POST',dataType:'json',url:"moirai2.php?command=query",data:json}).fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});
	post.success(function(data){if(method!=null)method(data);});
}
SQLiteRDFModel.prototype.selectRDF=function(json,method){
	var self=this;
	if(typeof json!=='object')json={subject:json};
	if(!("db" in json))json.db=this.db;
	if(!("recursion" in json))json.recursion=0;
	var post=$.ajax({type:'POST',dataType:'json',url:"moirai2.php?command=select",data:json}).fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});
	post.success(function(data){if(method!=null)method(data);});
}
SQLiteRDFModel.prototype.recordText=function(text,method){
	var self=this;
	var text=this.jsonEscape(text);
	var json="{\""+this.address+"\":{\""+this.textUrl+"\":{\""+text+"\":{\""+this.timeStampUrl+"\":"+new Date().getTime()+"}}}}";
	var post=$.ajax({type:'POST',url:"moirai2.php?command=insert",data:{'db':self.db,'data':json}}).fail(function(xhr,data){console.log("failed",xhr,data);});
	if(method!=null)post.success(function(data){method(data)});
}
SQLiteRDFModel.prototype.recordPath=function(path,method){
	var self=this;var json;
	if(Array.isArray(path)){var json="{\""+this.address+"\":{\""+this.fileUrl+"\":{";var i=0;path.forEach(function(p){if(i>0)json+=",";json+="\""+self.jsonEscape(p)+"\":{\""+self.timeStampUrl+"\":"+new Date().getTime()+"}";i++;});json+="}}}";}else{json="{\""+this.address+"\":{\""+this.fileUrl+"\":{\""+this.jsonEscape(path)+"\":{\""+this.timeStampUrl+"\":"+new Date().getTime()+"}}}}";}
	var post=$.ajax({type:'POST',url:"moirai2.php?command=insert",data:{'db':self.db,'data':json}}).fail(function(xhr,data){console.log("failed",xhr,data);});
	if(method!=null)post.success(function(data){method(data)});
}
SQLiteRDFModel.prototype.recordFileFormat=function(filepath,fileformat,method){
	var self=this;
	var text=this.jsonEscape(text);
	var json="{\""+filepath+"\":{\""+this.fileFormatUrl+"\":\""+fileformat+"\"}}";
	var post=$.ajax({type:'POST',url:"moirai2.php?command=insert",data:{'db':self.db,'data':json}}).fail(function(xhr,data){console.log("failed",xhr,data);});
	if(method!=null)post.success(function(data){method(data)});
}
SQLiteRDFModel.prototype.recordMD5=function(file,method){
	var self=this;
	var post=$.ajax({type:'POST',dataType:'text',url:"moirai2.php?command=md5",data:{'file':file}}).fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});
	post.success(function(md5){var json="{\""+file+"\":{\""+self.md5Url+"\":\""+md5+"\"}}";var post=$.ajax({type:'POST',url:"moirai2.php?command=insert",data:{'db':self.db,'data':json}}).fail(function(xhr,data){console.log("failed",xhr,data);});if(method!=null)post.success(function(data){method(data)});});
}
SQLiteRDFModel.prototype.recordLink=function(url,method){
	var self=this;
	var url=this.jsonEscape(url);
	var json="{\""+this.address+"\":{\""+this.linkUrl+"\":{\""+url+"\":{\""+this.timeStampUrl+"\":"+new Date().getTime()+"}}}}";
	var post=$.ajax({type:'POST',url:"moirai2.php?command=insert",data:{'db':self.db,'data':json}}).fail(function(xhr,data){console.log("failed",xhr,data);});
	if(method!=null)post.success(function(data){method(data)});
}
SQLiteRDFModel.prototype.recordXML=function(xml,method){
	var self=this;
	var post=$.ajax({type:'POST',url:"moirai2.php?command=insert",data:{'db':self.db,'data':xml}}).fail(function(xhr,data){console.log("failed",xhr,data);});
	if(method!=null)post.success(function(data){method(data)});
}
SQLiteRDFModel.prototype.deleteRDF=function(json,method){
	var self=this;
	var string=this.jsonEscape(JSON.stringify(json));
	var post=$.ajax({type:'POST',url:"moirai2.php?command=delete",data:{'db':self.db,'data':string}}).fail(function(xhr,data){console.log("failed",xhr,data);});
	if(method!=null)post.success(function(data){method(data)});
}
SQLiteRDFModel.prototype.insertRDF=function(json,method){
	var self=this;
	var string=this.jsonEscape(JSON.stringify(json));
	var post=$.ajax({type:'POST',url:"moirai2.php?command=insert",data:{'db':self.db,'data':string}}).fail(function(xhr,data){console.log("failed",xhr,data);});
	if(method!=null)post.success(function(data){method(data)});
}
SQLiteRDFModel.prototype.updateRDF=function(json,method){
	var self=this;
	var string=this.jsonEscape(JSON.stringify(json));
	var post=$.ajax({type:'POST',url:"moirai2.php?command=update",data:{'db':self.db,'data':string}}).fail(function(xhr,data){console.log("failed",xhr,data);});
	if(method!=null)post.success(function(data){method(data)});
}
SQLiteRDFModel.prototype.newNode=function(method){
	var self=this;
	var post=$.ajax({type:'POST',url:"moirai2.php?command=newnode",data:{'db':self.db}}).fail(function(xhr,data){console.log("failed",xhr,data);});
	if(method!=null)post.success(function(data){method(data)});
}
SQLiteRDFModel.prototype.executeCommand=function(json,method){
	var self=this;
	var string=this.jsonEscape(JSON.stringify(json));
	var post=$.ajax({type:'POST',url:"moirai2.php?command=command",data:{'db':self.db,'data':string}}).fail(function(xhr,data){console.log("failed",xhr,data);});
	if(method!=null)post.success(function(data){method(data)});
}
SQLiteRDFModel.prototype.recordFileContent=function(path,method){
	var self=this;
	if(!("db" in json))json.db=this.db;
	if(!("root" in json))json.root=this.address;
	jQuery.get(path,function(content){var json="{\""+path+"\":{\""+self.fileContentUrl+"\":"+JSON.stringify(content)+"}}";var post=$.ajax({type:'POST',url:"moirai2.php?command=insert",data:{'db':self.db,'data':json}}).fail(function(xhr,data){console.log("failed",xhr,data);});if(method!=null)post.success(function(data){method(data)});})
}
