function RDF(){
	this.rdf={};
	return this;
}
RDF.prototype.insert=function(string){
	if(string==null)return this;
	if(!Array.isArray(string))string=string.split(",");
	for(var i=0;i<string.length;i++){
		var line=string[i];
		var tokens=line.split("->");
		if(tokens.length!=3)continue;
		this.add(tokens[0],tokens[1],tokens[2]);
	}
	return this;
}
RDF.prototype.add=function(subject,predicate,object){
	if(!(subject in this.rdf))this.rdf[subject]={};
	if(!(predicate in this.rdf[subject]))this.rdf[subject][predicate]=object;
	else if(Array.isArray(this.rdf[subject][predicate]))this.rdf[subject][predicate].push(object);
	else this.rdf[subject][predicate]=[this.rdf[subject][predicate],object];
	return this;
}
RDF.prototype.toText=function(){
	var array=[];
	var subjects=Object.keys(this.rdf);
	for(var i=0;i<subjects.length;i++){
		var subject=subjects[i];
		var predicates=Object.keys(this.rdf[subject]);
		for(var j=0;j<predicates.length;j++){
			var predicate=predicates[j];
			var object=this.rdf[subject][predicate];
			if(Array.isArray(object)){for(var k=0;k<object.length;k++){array.push(subject+"\t"+predicate+"\t"+object[k]);}}
			else{array.push(subject+"\t"+predicate+"\t"+object);}
		}
	}
	return array.join("\n");
}
RDF.prototype.toHTML=function(){
	var html=$("<table/>");
		var thead=$("<thead/>").append($("<tr/>").append($("<th>").text("subject")).append($("<th>").text("predicate")).append($("<th>").text("object")));
	html.append(thead);
	var tbody=$("<tbody/>");
	html.append(tbody);
	var subjects=Object.keys(this.rdf);
	for(var i=0;i<subjects.length;i++){
		var subject=subjects[i];
		var predicates=Object.keys(this.rdf[subject]);
		for(var j=0;j<predicates.length;j++){
			var predicate=predicates[j];
			var object=this.rdf[subject][predicate];
			if(Array.isArray(object))for(var k=0;k<object.length;k++)tbody.append($("<tr/>").append($("<td/>").text(subject)).append($("<td/>").text(predicate)).append($("<td/>").text(object[k])));
			else tbody.append($("<tr/>").append($("<td/>").text(subject)).append($("<td/>").text(predicate)).append($("<td/>").text(object)));
		}
	}
	return html;
}
RDF.prototype.read=function(text){
	var lines=text.split(/\r?\n/);
	for(var i=0;i<lines.length;i++){
		var line=lines[i];
		var tokens=line.split(/\t/);
		if(tokens.length!=3)continue;
		this.add(tokens[0],tokens[1],tokens[2]);
	}
	return this;
}
