//#################### constructor ####################
function RDF(){
	this.parent;//parent of RDF
	this.rdf={};//triplets
	this.results=[];//results from query()
	this.returns=[];//results from execute()
	this.mode=0;//0=rdf,1=query(),2=execute()
	return this;
}
//#################### add ####################
RDF.prototype.add=function(subject,predicate,object){
	this.mode=0;
	if(!(subject in this.rdf))this.rdf[subject]={};
	if(!(predicate in this.rdf[subject]))this.rdf[subject][predicate]=object;
	else if(Array.isArray(this.rdf[subject][predicate])){
		if(!this.rdf[subject][predicate].contains(object))this.rdf[subject][predicate].push(object);
	}else if(this.rdf[subject][predicate]!=object)this.rdf[subject][predicate]=[this.rdf[subject][predicate],object];
	return this;
}
//#################### build ####################
RDF.prototype.build=function(string){
	if(string==null)return this;
	let keys=this._keys();
	if(!Array.isArray(string))string=string.split(",");
	let inserts=[];
	for(let i=0;i<string.length;i++){
		for(let j=0;j<this.returns.length;j++){
			let line=string[i];
			let tokens=line.split("->");
			if(tokens.length!=3)continue;
			for(let k=0;k<keys.length;k++){
				let key=keys[k]
				let val=this.results[j][key];
				line=line.replace(key,val);
			}
			line=line.replace("$_",this.returns[j]);
			inserts.push(line);
		}
	}
	this.insert(inserts);
	return this;
}
//#################### delete ####################
RDF.prototype.delete=function(subject,predicate,object){
	if(!(subject in this.rdf))return this;
	if(!(predicate in this.rdf[subject]))return this;
	if(Array.isArray(this.rdf[subject][predicate])){
		let array=this.rdf[subject][predicate];
		let temp=[];
		for(let i=0;i<array.length;i++)if(array[i]!=object)temp.push(array[i]);
		if(temp.length==1)this.rdf[subject][predicate]=temp[0];
		else this.rdf[subject][predicate]=temp;
	}else if(this.rdf[subject][predicate]==object){
		delete(this.rdf[subject][predicate]);
		if(Object.keys(this.rdf[subject]).length==0)delete(this.rdf[subject]);
	}
	this.mode=0;
	return this;
}
//#################### exclude ####################
RDF.prototype.exclude=function(subject,predicate,object){
	let rdf=new RDF();
	let subjects=Object.keys(this.rdf);
	for(let i=0;i<subjects.length;i++){
		let subject2=subjects[i];
		if(this._exclude(subject,subject2))continue;
		let predicates=Object.keys(this.rdf[subject2]);
		for(let j=0;j<predicates.length;j++){
			let predicate2=predicates[j];
			if(this._exclude(predicate,predicate2))continue;
			let object2=this.rdf[subject2][predicate2];
			if(Array.isArray(object2)){
				for(let k=0;k<object2.length;k++){
					if(this._exclude(object,object2[k]))continue;
					rdf.add(subject2,predicate2,object2[k]);
				}
			}else{
				if(this._exclude(object,object2))continue;
				rdf.add(subject2,predicate2,object2);
			}
		}
	}
	this.mode=0;
	return rdf;
}
//#################### execute ####################
RDF.prototype.execute=function(func){
	let keys=this._getParams(func);
	this.returns=[];
	for(let i=0;i<this.results.length;i++){
		let h=this.results[i];
		let params=[];
		for(let j=0;j<keys.length;j++)params[j]=h["$"+keys[j]];
		this.returns.push(func.apply(null,params));
	}
	this.mode=2;
	return this;
}
//#################### insert ####################
RDF.prototype.insert=function(){
	for(let i=0;i<arguments.length;i++){
		let string=arguments[i];
		if(!Array.isArray(string))string=string.split(",");
		for(let i=0;i<string.length;i++){
			let line=string[i];
			let tokens=line.split("->");
			if(tokens.length!=3)continue;
			this.add(tokens[0],tokens[1],tokens[2]);
		}
	}
	this.mode=0;
	return this;
}
//#################### put ####################
RDF.prototype.put=function(subject,predicate,object){
	if(!(subject in this.rdf))this.rdf[subject]={};
	this.rdf[subject][predicate]=object;
	this.mode=0;
}
//#################### query ####################
RDF.prototype.query=function(string){
	if(string==null)return this;
	if(!Array.isArray(string))string=string.split(",");
	this.results=[{}];
	for(let i=0;i<string.length;i++){
		let line=string[i];
		let tokens=line.split("->");
		if(tokens.length!=3)continue;
		let temp=[];
		for(let j=0;j<this.results.length;j++){
			let hash=this.results[j];
			let values=[];
			let subject=this._queryvalue(tokens[0],hash);
			let predicate=this._queryvalue(tokens[1],hash);
			let object=this._queryvalue(tokens[2],hash);
			let rdf=this.select(subject,predicate,object);
			let variables=rdf._getVariables(tokens[0],tokens[1],tokens[2],hash);
			for(let k=0;k<variables.length;k++){
				let keys=Object.keys(variables[k]);
				for(let l=0;l<keys.length;l++){
					let key=keys[l];
					let value=variables[k][key];
					if(!isNaN(value))value=Number(value);
					variables[k][key]=value;
				}
				temp.push(variables[k]);
			}
		}
		this.results=temp;
	}
	this.mode=1;
	return this;
}
//#################### read ####################
RDF.prototype.readTable=function(text){
	let lines=text.split(/\r?\n/);
	let labels=lines[0].split(/\t/);
	for(let i=1;i<lines.length;i++){
		let line=lines[i];
		if(line=="")continue;
		let tokens=line.split(/\t/);
		let subject=tokens[0];
		for(let j=0;j<tokens.length;j++){
			let predicate=labels[j];
			let object=tokens[j];
			if(predicate!="")this.add(subject,predicate,object);
		}
	}
	this.mode=0;
	return this;
}
RDF.prototype.readTriple=function(text){
	let lines=text.split(/\r?\n/);
	for(let i=0;i<lines.length;i++){
		let line=lines[i];
		let tokens=line.split(/\t/);
		if(tokens.length!=3)continue;
		this.add(tokens[0],tokens[1],tokens[2]);
	}
	this.mode=0;
	return this;
}
//#################### select ####################
RDF.prototype.select=function(subject,predicate,object){
	let rdf=new RDF();
	let subjects=Object.keys(this.rdf);
	for(let i=0;i<subjects.length;i++){
		let subject2=subjects[i];
		if(this._select(subject,subject2))continue;
		let predicates=Object.keys(this.rdf[subject2]);
		for(let j=0;j<predicates.length;j++){
			let predicate2=predicates[j];
			if(this._select(predicate,predicate2))continue;
			let object2=this.rdf[subject2][predicate2];
			if(Array.isArray(object2)){
				for(let k=0;k<object2.length;k++){
					if(this._select(object,object2[k]))continue;
					rdf.add(subject2,predicate2,object2[k]);
				}
			}else{
				if(this._select(object,object2))continue;
				rdf.add(subject2,predicate2,object2);
			}
		}
	}
	this.mode=0;
	return rdf;
}
//#################### stringify ####################
RDF.prototype.stringify=function(){
	if(this.mode==0)return JSON.stringify(this.rdf);
	else return JSON.stringify(this.results);
}
//#################### toHTML ####################
RDF.prototype.toHTML=function(){
	if(this.mode==0){
		let html=$("<table/>");
			let thead=$("<thead/>").append($("<tr/>").append($("<th>").text("subject")).append($("<th>").text("predicate")).append($("<th>").text("object")));
		html.append(thead);
		let tbody=$("<tbody/>");
		html.append(tbody);
		let subjects=Object.keys(this.rdf);
		for(let i=0;i<subjects.length;i++){
			let subject=subjects[i];
			let predicates=Object.keys(this.rdf[subject]);
			for(let j=0;j<predicates.length;j++){
				let predicate=predicates[j];
				let object=this.rdf[subject][predicate];
				if(Array.isArray(object))for(let k=0;k<object.length;k++)tbody.append($("<tr/>").append($("<td/>").text(subject)).append($("<td/>").text(predicate)).append($("<td/>").text(object[k])));
				else tbody.append($("<tr/>").append($("<td/>").text(subject)).append($("<td/>").text(predicate)).append($("<td/>").text(object)));
			}
		}
		return html;
	}else if(this.mode==1){
		let keys=this._keys();
		let html=$("<table/>");
		let thead=$("<thead/>").append($("<tr/>"));
		for(let i=0;i<keys.length;i++)thead.append($("<th/>").text(keys[i]));
		html.append(thead);
		let tbody=$("<tbody/>");
		for(let i=0;i<this.results.length;i++){
			let tr=tbody.append($("<tr/>"));
			for(let j=0;j<keys.length;j++)tr.append($("<td/>").text(this.results[i][keys[j]]));
		}
		html.append(tbody);
		return html;
	}else{
		let keys=this._keys();
		let html=$("<table/>");
		let thead=$("<thead/>").append($("<tr/>"));
		for(let i=0;i<keys.length;i++)thead.append($("<th/>").text(keys[i]));
		thead.append($("<th/>").text("return"));
		html.append(thead);
		let tbody=$("<tbody/>");
		for(let i=0;i<this.returns.length;i++){
			let tr=tbody.append($("<tr/>"));
			for(let j=0;j<keys.length;j++)tr.append($("<td/>").text(this.results[i][keys[j]]));
			tr.append($("<td/>").text(this.returns[i]));
		}
		html.append(tbody);
		return html;
	}
}
RDF.prototype.toHTMLTable=function(labels){
	if(this.mode==0){
		let html=$("<table/>");
		let thead=$("<thead/>");
		let tr=$("<tr/>");
		for(let i=0;i<labels.length;i++)tr.append($("<th/>").text(labels[i]));
		thead.append(tr);
		html.append(thead);
		let tbody=$("<tbody/>");
		html.append(tbody);
		let hash={};
		for(let i=0;i<labels.length;i++){
			let label=labels[i];
			let array=this.query("$key->"+label+"->$value");
			for(let j=0;j<array.length;j++){
				let h=array[j];
				let key=h["$key"];
				let value=h["$value"];
				if(!(key in hash))hash[key]={};
				if(!(label in hash[key]))hash[key][label]=value;
				else if(Array.isArray(hash[key]))hash[key][label].push(value);
				else hash[key][label]=[hash[key][label],value];
			}
		}
		let keys=Object.keys(hash).sort();
		for(let i=0;i<keys.length;i++){
			let tr=$("<tr/>");
			let h=hash[keys[i]];
			for(let j=0;j<labels.length;j++)tr.append("<td>"+h[labels[j]]+"</td>");
			tbody.append(tr);
		}
		return html;
	}
}
//#################### toText ####################
RDF.prototype.toText=function(string){
	if(this.mode==0){
		let array=[];
		let subjects=Object.keys(this.rdf);
		for(let i=0;i<subjects.length;i++){
			let subject=subjects[i];
			let predicates=Object.keys(this.rdf[subject]);
			for(let j=0;j<predicates.length;j++){
				let predicate=predicates[j];
				let object=this.rdf[subject][predicate];
				if(Array.isArray(object)){for(let k=0;k<object.length;k++){array.push(subject+"\t"+predicate+"\t"+object[k]);}}
				else{array.push(subject+"\t"+predicate+"\t"+object);}
			}
		}
		return array.join("\n");
	}else{
		let keys=this._keys();
		let lines=[];
		for(let i=0;i<this.results.length;i++){
			let line=string;
			for(let j=0;j<keys.length;j++){
				let key=keys[j]
				let val=this.results[i][key];
				line=line.replace(key,val);
			}
			lines.push(line);
		}
		return lines;
	}
}
//#################### triples ####################
RDF.prototype.subjects=function(){return Object.keys(this.rdf);}
RDF.prototype.predicates=function(){
	let subjects=Object.keys(this.rdf);
	let hash={};
	for(let i=0;i<subjects.length;i++){
		let subject2=subjects[i];
		let predicates=Object.keys(this.rdf[subject2]);
		for(let j=0;j<predicates.length;j++){
			let predicate2=predicates[j];
			hash[predicate2]=1;
		}
	}
	return Object.keys(hash);
}
RDF.prototype.objects=function(){
	let subjects=Object.keys(this.rdf);
	let hash={};
	for(let i=0;i<subjects.length;i++){
		let subject2=subjects[i];
		let predicates=Object.keys(this.rdf[subject2]);
		for(let j=0;j<predicates.length;j++){
			let predicate2=predicates[j];
			let object2=this.rdf[subject2][predicate2];
			if(Array.isArray(object2)){for(let k=0;k<object2.length;k++){hash[object2[k]]=1;}}
			else{hash[object2]=1;}
		}
	}
	return Object.keys(hash);
}
//#################### hidden functions ####################
RDF.prototype._getVariables=function(subject,predicate,object,hash){
	let array=[];
	let subjects=Object.keys(this.rdf);
	for(let i=0;i<subjects.length;i++){
		let subject2=subjects[i];
		let predicates=Object.keys(this.rdf[subject2]);
		for(let j=0;j<predicates.length;j++){
			let predicate2=predicates[j];
			let object2=this.rdf[subject2][predicate2];
			if(!Array.isArray(object2))object2=[object2];
			for(let k=0;k<object2.length;k++){
				let temp={};
				let keys=Object.keys(hash);
				for(let l=0;l<keys.length;l++)temp[keys[l]]=hash[keys[l]];
				if(subject.startsWith("$"))temp[subject]=subject2;
				if(predicate.startsWith("$"))temp[predicate]=predicate2;
				if(object.startsWith("$"))temp[object]=object2[k];
				if(Object.keys(temp).length==0){continue;}
				if(!this._includes(array,temp))array.push(temp);
			}
		}
	}
	return array;
}
RDF.prototype._includes=function(array,hash){
	for(let i=0;i<array.length;i++)if(this._equals(array[i],hash))return 1;
	return 0;
}
RDF.prototype._equals=function(hash1,hash2){
	let keys1=Object.keys(hash1).sort();
	let keys2=Object.keys(hash2).sort();
	if(keys1.length!=keys2.length)return 0;
	for(let i=0;i<keys1.length;i++){
		if(keys1[i]!=keys2[i])return 0;
		if(hash1[keys1[i]]!=hash2[keys2[i]])return 0;
	}
	return 1;
}
RDF.prototype._queryvalue=function(value,hash){
	if(value==null||value==""){return new RegExp(".*");}
	else if(value.startsWith("$")){if(value in hash)return hash[value];else return value;}
	else if(value.startsWith("/")&&value.endsWith("/"))return new RegExp(value.substr(1,value.length-2));
	else return value;
}
RDF.prototype._select=function(value,value2){
	if(!isNaN(value))value=String(value);
	if(value==null)return 1;
	else if(Array.isArray(value)){for(let i=0;i<value.length;i++){if(this._select(value[i],value2)==0)return 0;}return 1;}
	else if(value instanceof RegExp)return !value2.match(value);
	else if(value.startsWith("$"))return 0;
	else if(value.startsWith("!")){if(value.substr(1)==value2)return 1;}
	else if(value==value2)return 0;
	else if(value!=value2)return 1;
	else return 0;
}
RDF.prototype._exclude=function(value,value2){
	if(value==null)return 0;
	else if(Array.isArray(value)){for(let i=0;i<value.length;i++){if(this._exclude(value[i],value2)==1)return 1;}return 0;}
	else if(value instanceof RegExp)return value2.match(value);
	else if(value.startsWith("$"))return 0;
	else if(value.startsWith("!")){if(value.substr(1)==value2)return 0;}
	else if(value==value2)return 1;
	else if(value!=value2)return 0;
	else return 1;
}
RDF.prototype._keys=function(){
	let keys=[];
	for(let i=0;i<this.results.length;i++){
		let temp=Object.keys(this.results[i])
		for(let j=0;j<temp.length;j++)if(!keys.includes(temp[j]))keys.push(temp[j]);
	}
	return keys;
}
RDF.prototype._getParams=function(func) {
	var str=func.toString();
	var flag=0;
	var key="";
	for(var i=0;i<str.length;i++){
		if(str[i]=="("){flag=1;continue;}
		if(flag!=1)continue;
		if(str[i]==")")break;
		key+=str[i];
	}
	let keys=key.split(",");
	for(var i=0;i<keys.length;i++)keys[i]=keys[i].trim();
	return keys;
}
