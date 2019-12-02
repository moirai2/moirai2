//######################################## CONSTRUCTOR ########################################
function Chain(){
	this.job=0;
	this.jobs=[];
	this.rdf;
	this.data=[];
	this.tmp=[];
	this.task=0;
	if(typeof RDF!='undefined')this.rdf=new RDF();
	if(typeof Utility!='undefined')this.utility=new Utility();
	for(let i=0;i<arguments.length;i++){
		let arg=arguments[i];
		if(arg.constructor.name=="SQLiteRDFModel")this.sqliteRDFModel=arg;
		else if(arg.constructor.name=="DnDController")this.dndController=arg;
		else if(arg.constructor.name=="DrawView")this.drawView=arg;
		else if(arg.constructor.name=="MouseController")this.mouseController=arg;
		else if(arg.constructor.name=="FileList"){
			if("files" in event.dataTransfer){
				this.file=[];
				for(let i=0;i<event.dataTransfer.files.length;i++)this.file.push(event.dataTransfer.files[i]);
				this.tmp=this.file;
			}
		}else if(arg.constructor.name=="CustomEvent"){
			if("x" in arg.detail)this.x=arg.detail.x;
			if("y" in arg.detail)this.y=arg.detail.y;
			if("filename" in arg.detail)this.filename=arg.detail.filename;
			if("text" in arg.detail)this.text=arg.detail.text;
			if("filepath" in arg.detail)this.path=arg.detail.path;
			if("url" in arg.detail)this.url=arg.detail.url;
			if("file" in arg.detail)this.file=arg.detail.file;
			if("image" in arg.detail)this.image=arg.detail.image;
			if(arg.type!=null){
				this.type=arg.type;
				if(arg.type=="imageWasRead")this.tmp.push(arg.detail.image);
				if(arg.type=="fileWasSaved")this.tmp.push(arg.detail.path);
				if(arg.type=="fileNameWasDropped")this.tmp.push(arg.detail.filename);
				if(arg.type=="urlWasDropped")this.tmp.push(arg.detail.url);
				if(arg.type=="textWasRead")this.tmp.push(arg.detail.text);
				if(arg.type=="textWasDropped")this.tmp.push(arg.detail.text);
				if(arg.type=="imageWasDropped")this.tmp.push(arg.detail.file);
				if(arg.type=="fileWasDropped")this.tmp.push(arg.detail.file);
			}
		}else{this.tmp.push(arg);}
	}
}
//######################################## BASIC ########################################
Chain.prototype.execute=function(func){
	let self=this;
	this.jobs.push(function(self,hash){func(self);self.next();});
	return this;
}
Chain.prototype.log=function(){
	let self=this;
	this.jobs.push({once:true,keep:true,job:function(self){console.log(self);self.start();}});
	return this;
}
Chain.prototype.prompt=function(question,answer){
	this.jobs.push({once:true,job:function(self){
		let text=prompt(question,answer);
		if(text==null||text=="")return;
		self.tmp=[text];
		self.start();
	}});
	return this;
}
Chain.prototype.reload=function(){
	let self=this;
	this.jobs.push({once:true,job:function(self){location.reload();}});
	return this;
}
Chain.prototype.sleep=function(time){
	if(time==null)time=500;
	this.jobs.push({once:true,job:function(self){setTimeout(function(){self.next();},time);}});
	return this;
}
Chain.prototype.next=function(){
	if(--this.task>0){return;}
	this.tmp=[];
	for(let i=0;i<this.data.length;i++){if("output" in this.data[i])this.tmp.push(this.data[i]["output"]);}
	if(this.tmp.length>0)this.start();
}
Chain.prototype.start=function(mode){
	if(this.job<this.jobs.length){
		if(mode==null)mode={};
		let hash={};
		let job=this.jobs[this.job++];
		if((typeof job==='function')){}
		else if((typeof job==='object')){hash=job;job=hash["job"];}
		if("set" in hash&&hash["set"]!=null)this.tmp=[hash["set"]];
		if("set" in mode&&hash["set"]!=null)this.tmp=[mode["set"]];
		if(!("keep" in hash)&&!("keep" in mode)){
			this.data=[];
			for(let i=0;i<this.tmp.length;i++)this.data[i]={input:this.tmp[i]};
		}
		if("put" in hash&&hash["put"]!=null)this.startPut(hash["put"]);
		if("put" in mode&&mode["put"]!=null)this.startPut(mode["put"]);
		if(this.data.length==0){this.data.push({});}
		let task=this.data.length;
		this.task=task;
		if("once" in hash){job(this,this.data[0]);}
		else{for(let i=0;i<task;i++){job(this,this.data[i]);}}
	}
	return this;
}
Chain.prototype.startPut=function(data){
	let keys=Object.keys(data);
	for(let i=0;i<keys.length;i++){
		for(let j=0;j<this.data.length;j++)this.data[j][keys[i]]=data[keys[i]];
	}
}
Chain.prototype.attr=function(json){
	let self=this;
	this.jobs.push({job:function(self,hash){
		let object=hash["input"];
		let keys=Object.keys(json);
		for(let i=0;i<keys.length;i++)$(object).attr(keys[i],json[keys[i]]);
		hash["output"]=object;
		self.next();
	}});
	return this;
}
//######################################## canvas ########################################
Chain.prototype.addChild=function(){
	let self=this;
	if(this.drawView==null){alert("Please specify DrawView");return this;}
	this.jobs.push({job:function(self,hash){self.drawView.addChild(hash["input"]);self.next();}});
	return this;
}
Chain.prototype.createImageIcon=function(image){
	let self=this;
	if(this.drawView==null){alert("Please specify DrawView");return this;}
	this.jobs.push({set:image,job:function(self,hash){hash["output"]=self.drawView.createImageIcon(hash["input"],self);self.next();}});
	return this;
}
Chain.prototype.createTextIcon=function(text){
	let self=this;
	if(this.drawView==null){alert("Please specify DrawView");return this;}
	this.jobs.push({set:text,job:function(self,hash){hash["output"]=self.drawView.createTextIcon(hash["input"],self);self.next();}});
	return this;
}
Chain.prototype.createButtonIcon=function(){
	let self=this;
	if(this.drawView==null){alert("Please specify DrawView");return this;}
	this.jobs.push(function(self,hash){hash["output"]=self.drawView.createButtonIcon(self);self.next();});
	return this;
}
//######################################## data ########################################
Chain.prototype.dataAdd=function(){
	let self=this;
	let args=arguments;
	this.jobs.push({once:true,job:function(self){
		for(let i=0;i<self.data.length;i++){
			for(let j=0;j<args.length;j++){
				let arg=args[j];
				if((!Array.isArray(arg))&&(typeof arg==="object")){
					let keys=Object.keys(arg);
					for(let k=0;k<keys.length;k++){
						let key=keys[k];
						let val=arg[key];
						self.data[i][key]=val;
					}
				}else{
					let index=(j<self.tmp.length)?j:self.tmp.length-1;
					self.data[i][arg]=self.tmp[index];
				}
			}
		}
		self.tmp=[];
		self.start({keep:true});
	}});
	return this;
}
Chain.prototype.dataGet=function(){
	let self=this;
	let args=arguments;
	this.jobs.push({once:true,function(self){
		self.tmp=[];
		for(let i=0;i<args.length;i++){

		}
		self.start({keep:true});
	}});
	return this;
}
Chain.prototype.put=function(){
	let self=this;
	let args=arguments;
	this.jobs.push({once:true,job:function(self,hash){
		for(let i=0;i<args.length;i++){
			let expression=args[i];
		}
		self.start({keep:true});
	}});
	return this;
}
//######################################## HTML ########################################
Chain.prototype.appendTo=function(target){
	let self=this;
	if(target==null)target=document.body;
	this.jobs.push({put:{target:target},job:function(self,hash){
		let html=hash["input"];
		let target=hash["target"];
		$(target).append(html);
		self.next();
	}});
	return this;
}
Chain.prototype.hashToHTML=function(hash){
	let html=$("<table/>");
	let thead=$("<thead/>");
	let tr=$("<tr/>");
	tr.append($("<th/>").text("key"));
	tr.append($("<th/>").text("value"));
	thead.append(tr);
	html.append(thead);
	let tbody=$("<tbody/>");
	if(Array.isArray(hash)){
		for(let i=0;i<hash.length;i++){
			let tr=$("<tr/>");
			tr.append($("<td/>").text(i));
			tr.append($("<td/>").text(JSON.stringify(hash[i])));
			tbody.append(tr);
		}
	}else if(typeof hash==="object"){
		let keys=Object.keys(hash);
		for(let i=0;i<keys.length;i++){
			let key=keys[i];
			let val=hash[keys[i]];
			let tr=$("<tr/>");
			tr.append($("<td/>").text(key));
			if(typeof val==='object')tr.append($("<td/>").text(JSON.stringify(val)));
			else tr.append($("<td/>").text(val));
			tbody.append(tr);
		}
	}else{
		let tr=$("<tr/>");
		tr.append($("<td/>").text(i));
		tr.append($("<td/>").text(JSON.stringify(hash)));
		tbody.append(tr);
	}
	html.append(tbody);
	return html;
}
Chain.prototype.tmpToHTML=function(){
	let self=this;
	this.jobs.push({once:true,job:function(self){self.tmp=[self.hashToHTML(self.tmp)];self.start();}});
	return this;
}
Chain.prototype.dataToHTML=function(){
	let self=this;
	this.jobs.push(function(self,hash){hash["output"]=self.hashToHTML(hash);self.next();});
	return this;
}
Chain.prototype.rdfToHTML=function(){
	let self=this;
	this.jobs.push(function(self,hash){hash["output"]=self.rdf.toHTML();self.next();});
	return this;
}
//######################################## read ########################################
Chain.prototype.readFile=function(){
	let self=this;
	if(arguments.length>0)this.tmpSet.apply(this,arguments);
	this.jobs.push(function(self,hash){self.utility.readFile(hash["input"],function(text){hash["output"]=text;self.next();});});
	return this;
}
Chain.prototype.readImage=function(){
	let self=this;
	if(arguments.length>0)this.tmpSet.apply(this,arguments);
	this.jobs.push(function(self,hash){self.utility.readImage(hash["input"],function(image){hash["output"]=image;self.next();});});
	return this;
}
//######################################## RDF ########################################
Chain.prototype.rdfAdd=function(s,p,o){
	let self=this;
	if(s!=null&&p!=null&&o!=null)this.tmpSet([s,p,o]);
	this.jobs.push({once:true,job:function(self,hash){
		let triple=hash["input"];
		if(Array.isArray(triple))self.rdf.add(triple[0],triple[1],triple[2]);
		self.next();
	}});
	return this;
}
Chain.prototype.rdfPut=function(s,p,o){
	let self=this;
	if(s!=null&&p!=null&&o!=null)this.tmpSet([s,p,o]);
	this.jobs.push({once:true,job:function(self,hash){
		let triple=hash["input"];
		if(Array.isArray(triple))self.rdf.put(triple[0],triple[1],triple[2]);
		self.next();
	}});
	return this;
}
Chain.prototype.rdfReadTable=function(text){
	let self=this;
	if(text!=null)this.tmpSet(text);
	this.jobs.push(function(self,hash){
		let text=hash["input"];
		self.rdf.readTable(text);
		self.next();
	});
	return this;
}
Chain.prototype.rdfReadTriple=function(text){
	let self=this;
	if(text!=null)this.tmpSet(text);
	this.jobs.push(function(self,hash){
		let text=hash["input"];
		self.rdf.readTriple(text);
		self.next();
	});
	return this;
}
//######################################## tmp ########################################
Chain.prototype.tmpSet=function(){
	let self=this;
	let args=arguments;
	this.jobs.push({once:true,job:function(self){
		self.tmp=[];
		for(let i=0;i<args.length;i++)self.tmp[i]=args[i];
		self.start();
	}});
	return this;
}
Chain.prototype.tmpAdd=function(){
	let self=this;
	let args=arguments;
	this.jobs.push({once:true,keep:true,job:function(self){
		for(let i=0;i<args.length;i++)self.tmp.push(args[i]);
		self.start();
	}});
	return this;
}
