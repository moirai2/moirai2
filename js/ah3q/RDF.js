function RDF(){
	this.rdf={};
	return this;
}
RDF.prototype.query=function(string){
	if(string==null)return this;
	if(!Array.isArray(string))string=string.split(",");
	let array=[{}];
	for(let i=0;i<string.length;i++){
		let line=string[i];
		let tokens=line.split("->");
		if(tokens.length!=3)continue;
		let temp=[];
		for(let j=0;j<array.length;j++){
			let hash=array[j];
			let values=[];
			let subject=this.queryvalue(tokens[0],hash);
			let predicate=this.queryvalue(tokens[1],hash);
			let object=this.queryvalue(tokens[2],hash);
			let rdf=this.select(subject,predicate,object);
			let variables=rdf.getVariables(tokens[0],tokens[1],tokens[2],hash);
			for(let k=0;k<variables.length;k++)temp.push(variables[k]);
		}
		array=temp;
	}
	return array;
}
RDF.prototype.getVariables=function(subject,predicate,object,hash){
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
				array.push(temp);
			}
		}
	}
	return array;
}
RDF.prototype.queryhash=function(key,values,hash){
	let array=[];
	for(let i=0;i<values.length;i++){
		let temp={};
		let keys=Object.keys(hash);
		for(let j=0;j<keys.length;j++)temp[keys[j]]=hash[keys[j]];
		temp[key]=values[i];
		array.push(temp);
	}
	return array;
}
RDF.prototype.queryvalue=function(value,hash){
	if(value==null){return null;}
	else if(value.startsWith("$")){if(value in hash)return hash[value];}
	return value;
}
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
RDF.prototype.select=function(subject,predicate,object){
	let rdf=new RDF();
	let subjects=Object.keys(this.rdf);
	for(let i=0;i<subjects.length;i++){
		let subject2=subjects[i];
		if(this.selectsub(subject,subject2))continue;
		let predicates=Object.keys(this.rdf[subject2]);
		for(let j=0;j<predicates.length;j++){
			let predicate2=predicates[j];
			if(this.selectsub(predicate,predicate2))continue;
			let object2=this.rdf[subject2][predicate2];
			if(Array.isArray(object2)){
				for(let k=0;k<object2.length;k++){
					if(this.selectsub(object,object2[k]))continue;
					rdf.add(subject2,predicate2,object2[k]);
				}
			}else{
				if(this.selectsub(object,object2))continue;
				rdf.add(subject2,predicate2,object2);
			}
		}
	}
	return rdf;
}
RDF.prototype.selectsub=function(value,value2){
	if(value==null)return 0;
	else if(value.startsWith("$")){return 0;}
	else if(Array.isArray(value)){for(let i=0;i<value.length;i++){if(this.selectsub(value[i],value2)==0)return 0;}return 1;}
	else if(value.startsWith("!")){if(value.substr(1)==value2)return 1;}
	else{if(value!=value2)return 1;}
	return 0;
}
RDF.prototype.delete=function(subject,predicate,object){
	let rdf=new RDF();
	let subjects=Object.keys(this.rdf);
	for(let i=0;i<subjects.length;i++){
		let subject2=subjects[i];
		if(this.deletesub(subject,subject2))continue;
		let predicates=Object.keys(this.rdf[subject2]);
		for(let j=0;j<predicates.length;j++){
			let predicate2=predicates[j];
			if(this.deletesub(predicate,predicate2))continue;
			let object2=this.rdf[subject2][predicate2];
			if(Array.isArray(object2)){
				for(let k=0;k<object2.length;k++){
					if(this.deletesub(object,object2[k]))continue;
					rdf.add(subject2,predicate2,object2[k]);
				}
			}else{
				if(this.deletesub(object,object2))continue;
				rdf.add(subject2,predicate2,object2);
			}
		}
	}
	return rdf;
}
RDF.prototype.deletesub=function(value,value2){
	if(value==null)return 0;
	else if(value.startsWith("$")){return 0;}
	else if(Array.isArray(value)){for(let i=0;i<value.length;i++){if(this.selectsub(value[i],value2)==1)return 1;}return 0;}
	else if(value.startsWith("!")){if(value.substr(1)==value2)return 0;}
	else{if(value!=value2)return 0;}
	return 1;
}
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
}
RDF.prototype.toHTML=function(){
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
}
RDF.prototype.read=function(text){
	let lines=text.split(/\r?\n/);
	for(let i=0;i<lines.length;i++){
		let line=lines[i];
		let tokens=line.split(/\t/);
		if(tokens.length!=3)continue;
		this.add(tokens[0],tokens[1],tokens[2]);
	}
	return this;
}
