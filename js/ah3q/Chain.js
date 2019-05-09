//######################################## CONSTRUCTOR ########################################
// constructor
function Chain(){
	var self=this;
	if(typeof Utility!='undefined')this.utility=new Utility();//own utility
	this.job=0;//current job index
	this.task=0;//number of parallel jobs to be completed before next job
	this.loop=false;//loop
	this.sleep=0;//sleep
	this.dom=[];//DOM elements stored in array
	this.jobs=[];//jobs to execute
	this.data=[];//stored in array-hash format
	this.temporary=[];//temporary value stored
	this.temporaryForTask=[];//temporary stores array values for multiple tasks
	this.xml=[];//stores XML data
	this.json=[];//stores JSON data
	this.rdf={};//stores in my original rdf format
	this.query={};//stores address query
	this.network={};//network value stored for vis
	var hash={};
	for(var i=0;i<arguments.length;i++){
		var arg=arguments[i];
		if(arg.constructor.name=="SQLiteRDFModel")this.sqliteRDFModel=arg;
		else if(arg.constructor.name=="DnDController")this.dndController=arg;
		else if(arg.constructor.name=="DesktopView")this.desktopView=arg;
		else if(arg.constructor.name=="MouseController")this.mouseController=arg;
		else if(arg.constructor.name=="CustomEvent"){
			if(arg.detail.x!=null)hash["x"]=arg.detail.x;
			if(arg.detail.y!=null)hash["y"]=arg.detail.y;
			if(arg.detail.filename!=null)hash["filename"]=arg.detail.filename;
			if(arg.detail.text!=null)hash["text"]=arg.detail.text;
			if(arg.detail.path!=null)hash["filepath"]=arg.detail.path;
			if(arg.detail.url!=null)hash["url"]=arg.detail.url;
			if(arg.detail.file!=null)hash["file"]=arg.detail.file;
			if(arg.detail.image!=null)hash["image"]=arg.detail.image;
			if(arg.type!=null){
				hash["type"]=arg.type;
				if(arg.type=="imageWasRead")this.temporary.push(hash["image"]);
				if(arg.type=="fileWasSaved")this.temporary.push(hash["filepath"]);
				if(arg.type=="fileNameWasDropped")this.temporary.push(hash["filename"]);
				if(arg.type=="urlWasDropped")this.temporary.push(hash["url"]);
				if(arg.type=="textWasRead")this.temporary.push(hash["text"]);
				if(arg.type=="textWasDropped")this.temporary.push(hash["text"]);
				if(arg.type=="imageWasDropped")this.temporary.push(hash["file"]);
				if(arg.type=="fileWasDropped")this.temporary.push(hash["file"]);
				if(!("x" in hash))hash["x"]=$(document).width()/2;
				if(!("y" in hash))hash["y"]=$(document).height()/2;
				if(!("radius" in hash))hash["radius"]=20;
			}
		}else{this.temporary.push(arg);}
	}
	if(Object.keys(hash).length>0)this.data=[hash];
}
//######################################## BASIC ########################################
Chain.prototype.log=function(){var self=this;this.jobs.push(function(){console.log(self);self.start();});return this;}
Chain.prototype.execute=function(func){var self=this;this.jobs.push(function(){func(self);self.start();});return this;}
Chain.prototype.reload=function(){var　self=this;this.jobs.push(function(){location.reload();self.start();});return this;}
Chain.prototype.sleep=function(time){var self=this;if(time==null)time=500;this.jobs.push(function(){setTimeout(function(){self.start();},time);});return this;}
Chain.prototype.next=function(mode){if(--this.task==0){if(mode=="dom")this.dom=this.temporaryForTask;else if(mode=="xml")this.xml=this.temporaryForTask;else if(mode=="json")this.json=this.temporaryForTask;else if(mode=="rdf"){for(var i=0;i<this.temporaryForTask.length;i++)Object.assign(this.rdf,this.temporaryForTask[i]);}else if(mode=="none"){}else this.temporary=this.temporaryForTask;this.temporaryForTask=[];this.start();}}
Chain.prototype.start=function(){var self=this;if(this.job<this.jobs.length){this.jobs[this.job++].call(this);}else if(this.loop){this.job=0;setTimeout(function(){self.start();},self.sleep);}return this;}
Chain.prototype.repeat=function(sleep){if(sleep==null)sleep=1000;this.loop=true;this.sleep=sleep;return this.start();}
Chain.prototype.assignData=function(hash,index){var self=this;if(this.data[index]==null)this.data[index]={};Object.assign(this.data[index],hash);return this;}
Chain.prototype.addDocumentUrl=function(url){if(!url.startsWith("http://"))url=this.utility.directory(document.URL)+"/"+url;return url;}
Chain.prototype.setTemporarySub=function(keyWord){this.temporary=[];for(var i=0;i<this.data.length;i++)this.temporary.push(this.data[i][keyWord]);}
Chain.prototype.containsKeySub=function(keyWord){for(var i=0;i<this.data.length;i++)if(keyWord in this.data[i])return true;return false;}
//######################################## DATA ########################################
Chain.prototype.get=function(keyWord){
	var self=this;
	if(keyWord==null){
		this.jobs.push(function(){
			self.temporary=[];
			for(var i=0;i<self.data.length;i++)self.temporary.push(self.data[i]);
			self.start();
		});
	}else{
		this.jobs.push(function(){
			self.temporary=[];
			for(var i=0;i<self.data.length;i++)self.temporary.push(self.data[i][keyWord]);
			self.start();
		});
	}
	return this;
}
Chain.prototype.set=function(obj){var self=this;if(obj!=null)this.jobs.push(function(){self.temporary=(Array.isArray(obj))?obj:[obj];self.start();});else this.jobs.push(function(){self.temporary=[];for(var i=0;i<self.data.length;i++)self.temporary.push(self.data[i]);self.start();});return this;}
Chain.prototype.delete=function(keyWord){var self=this;this.jobs.push(function(){for(var i=0;i<self.data.length;i++){delete(self.data[i][keyWord]);}self.start();});return this;}
Chain.prototype.assemble=function(template){var self=this;this.jobs.push(function(){var tlen=Array.isArray(self.temporary)?self.temporary.length:1;var n=Math.max(self.data.length,tlen,1);var array=[];for(var i=0;i<n;i++){var t=(i<self.temporary.length)?self.temporary[i]:self.temporary[self.temporary.length-1];var d=(i<self.data.length)?self.data[i]:{};array.push(self.utility.assembleText(template,d,t));}self.temporary=array;self.start();});return this;}
Chain.prototype.expand=function(){var self=this;this.jobs.push(function(){var array=[];for(var i=0;i<self.temporary.length;i++){if(Array.isArray(self.temporary[i]))for(var j=0;j<self.temporary[i].length;j++)array.push(self.temporary[i][j]);else array.push(self.temporary[i]);}self.temporary=array;self.start();});return this;}
Chain.prototype.collapse=function(){var self=this;this.jobs.push(function(){var array=[];for(var i=0;i<self.temporary.length;i++)array.push(self.temporary[i]);self.temporary=[array];self.start();});return this;}
Chain.prototype.push=function(){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.data.push(self.temporary[i]);self.temporary=[];self.start();});return this;}
Chain.prototype.pop=function(){var self=this;this.jobs.push(function(){self.temporary=[self.data.pop()];self.start();});return this;}
Chain.prototype.clear=function(){var self=this;this.jobs.push(function(){self.data=[];self.temporary=[];self.dom=[];self.start();});return this;}
Chain.prototype.shift=function(){var self=this;this.jobs.push(function(){self.temporary=[self.data.shift()];self.start();});return this;}
Chain.prototype.unshift=function(){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.data.unshift(self.temporary[i]);self.temporary=[];self.start();});return this;}
Chain.prototype.peek=function(){var self=this;this.jobs.push(function(){self.temporary=[self.data.peek()];self.start();});return this;}
Chain.prototype.append=function(tag){var self=this;this.jobs.push(function(){var dom=[];for(var i=0;i<self.dom.length;i++){var elem=$(tag);self.dom[i].append(elem);dom.push(elem);}self.dom=dom;self.start();});return this;}
Chain.prototype.appendTo=function(target,multitarget){var self=this;if(target==null)target="body";if(typeof target==='string'){if(target.charAt(0)=='<'||(target.charAt(0)=='#'&&!target.includes("$"))){this.jobs.push(function(){var dom=[];if(multitarget){for(var i=0;i<self.dom.length;i++){var elem=$(target);elem.append(self.dom[i]);dom.push(elem);}}else{var elem=$(target);for(var i=0;i<self.dom.length;i++){elem.append(self.dom[i]);}dom.push(elem);}self.dom=dom;self.start();});}else{if(target.includes("$")){this.assemble(target);this.jobs.push(function(){var dom=[];for(var i=0;i<self.dom.length;i++){var elem=(typeof self.temporary[i]==="object"&&self.temporary[i] instanceof jQuery)?self.temporary[i]:$(self.temporary[i]);elem.append(self.dom[i]);dom.push(elem);}self.dom=dom;self.start();});}else this.jobs.push(function(){var elem=$(target);for(var i=0;i<self.dom.length;i++)elem.append(self.dom[i]);self.dom=[elem];self.start();});}}else this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)target.append(self.dom[i]);self.dom=[target];self.start();});return this;}
Chain.prototype.br=function(){var self=this;this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)self.dom[i].append("<br>");self.start();});return this;}
Chain.prototype.valTo=function(target){var self=this;this.jobs.push(function(){$(target).val(self.temporary[0]);self.start();});return this;}
Chain.prototype.textTo=function(target){var self=this;this.jobs.push(function(){$(target).text(self.temporary[0]);self.start();});return this;}
Chain.prototype.htmlTo=function(target){var self=this;this.jobs.push(function(){$(target).html(self.temporary[0]);self.start();});return this;}
Chain.prototype.handleAddress=function(address){var self=this;if(address==null)address=window.location.href;this.jobs.push(function(){
	var hash=self.utility.handleURL(address);
	var keys=Object.keys(hash);
	for(var i=0;i<keys.length;i++){
		var key=keys[i];
		var val=hash[key];
		if(key=="query"){
			Object.assign(self.query,val);
		}else{
			if(self.data.length==0)self.data[0]={};
			for(var j=0;j<self.data.length;j++)self.data[j][key]=val;
		}
	}
	self.start();});return this;}
Chain.prototype.handleDate=function(date){var self=this;if(date==null)date=new Date;this.jobs.push(function(){self.assignData(self.utility.handleDate(date),0);self.start();});return this;}
Chain.prototype.put=function(keyWord,template){
	var self=this;
	if(template!=null){
		if(typeof template==="function"){template(self);}
		else self.assemble(template);
	}
	if(keyWord==null){
		this.jobs.push(function(){
			for(var i=0;i<self.temporary.length;i++){
				if(self.data[i]==null)self.data[i]={};
				if(typeof self.temporary[i]==="object")Object.assign(self.data[i],self.temporary[i]);
			}
			self.start();
		});
	}else if(Array.isArray(keyWord)){
		this.jobs.push(function(){
			for(var i=0;i<self.temporary.length;i++){
				if(self.data[i]==null)self.data[i]={};
				for(var j=0;j<keyWord.length;j++)self.data[i][keyWord[j]]=self.temporary[i][j];
			}
			self.start();
		});
	}else if(typeof keyWord==="object"){
		this.jobs.push(function(){
			if(self.data.length==0)self.data.push({});
			for(var i=0;i<self.data.length;i++)for(var k in keyWord)self.data[i][k]=keyWord[k];
			self.start();
		});
	}else{
		this.jobs.push(function(){
			for(var i=0;i<self.temporary.length;i++){
				if(self.data[i]==null)self.data[i]={};
				if(typeof self.temporary[i]==="object")Object.assign(self.data[i],self.temporary[i]);
				else self.data[i][keyWord]=self.temporary[i];
			}
			self.start();
		});
	}
	return this;
}
Chain.prototype.fill=function(key){
	var self=this;
	this.jobs.push(function(){
		if(self.data.length>1){
			var value=self.data[0][key];
			for(var i=1;i<self.data.length;i++)self.data[i][key]=value;
		}
		self.start();
	});
	return this;
}
//######################################## DOM ########################################
Chain.prototype.create=function(template){
	var self=this;
	if(template!=null){
		if(Array.isArray(template))template=template.join("");
		if(template=="<popup>"){
			this.jobs.push(function(){
				self.dom=[self.utility.toPopup(self.temporary,"popup",self.x,self.y)];
				self.start();
			});
			return this;
		}else if(template.includes("$")){
			self.assemble(template);
		}else{
			this.jobs.push(function(){
				self.dom=[];
				if(self.temporary.length==0)self.temporary=[template];
				for(var i=0;i<self.temporary.length;i++)self.dom.push($(template));
				self.start();
			});
			return this;
		}
	}
	this.jobs.push(function(){
		self.dom=[];
		for(var i=0;i<self.temporary.length;i++)self.dom.push($(self.temporary[i]));
		self.start();
	});
	return this;
}
Chain.prototype.createTable=function(header){
	var self=this;
	if(Array.isArray(header))header=header.join(",");
	this.jobs.push(function(){
		var table=$("<table>");
		var thead=$("<thead>");
		table.append(thead);
		thead.append($(header));
		var tbody=$("<tbody>");
		table.append(tbody);
		for(var i=0;i<self.dom.length;i++)tbody.append(self.dom[i]);
		self.dom=[table];
		self.start();
	});
	return this;
}
Chain.prototype.addAttr=function(keyWord,template){var self=this;if(template!=null)this.assemble(template);if(typeof keyWord==="object"){this.jobs.push(function(){for(var k in keyWord)for(var i=0;i<self.dom.length;i++)self.dom[i].attr(k,keyWord[k]);self.start();});}else{this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)self.dom[i].attr(keyWord,self.temporary[i]);self.start();});}return this;}
Chain.prototype.addCss=function(keyWord,template){var self=this;if(template!=null)this.assemble(template);if(typeof keyWord==="object"){this.jobs.push(function(){for(var k in keyWord)for(var i=0;i<self.dom.length;i++)self.dom[i].css(k,keyWord[k]);self.start();});}else{this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)self.dom[i].css(keyWord,self.temporary[i]);self.start();});}return this;}
Chain.prototype.addClass=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)self.dom[i].addClass(self.temporary[i]);self.start();});return this;}
Chain.prototype.setId=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)self.dom[i].attr("id",self.temporary[i]);self.start();});return this;}
Chain.prototype.setText=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)self.dom[i].text(self.temporary[i]);self.start();});return this;}
Chain.prototype.setHtml=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)self.dom[i].html(self.temporary[i]);self.start();});return this;}
Chain.prototype.setVal=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)self.dom[i].val(self.temporary[i]);self.start();});return this;}
Chain.prototype.on=function(type,fun){var self=this;this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)$(self.dom[i]).on(type,fun);self.start();});return this;}
Chain.prototype.off=function(type){var self=this;this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)$(self.dom[i]).off(type);self.start();});return this;}
Chain.prototype.setLocation=function(templateX,templateY){var self=this;this.assemble(templateX);this.css("left");	this.assemble(templateY);this.css("top");	return this;}
Chain.prototype.hover=function(){this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)self.dom[i].css({"z-index":1,position:"absolute"});self.start();});return this;}
Chain.prototype.movable=function(){var self=this;this.jobs.push(function(){for(var i=0;i<self.dom.length;i++)self.dom[i].attr("movable",true);self.start();});return this;}
Chain.prototype.domToData=function(keyWord){var self=this;this.jobs.push(function(){for(var i=0;i<self.dom.length;i++){if(self.data[i]==null)self.data[i]={};self.data[i][keyWord]=self.dom[i];}self.start();});return this;}
//######################################## FILE ########################################
//"directory", "filesuffix", "depth", "getDir", "getFile", "grep"
Chain.prototype.listDirectory=function(directory){var self=this;if(!self.utility.isObject(directory))directory={"directory":directory};this.put(directory);this.jobs.push(function(){self.temporaryForTask=[];self.task=self.data.length;for(var i=0;i<self.data.length;i++)self.listDirectorySub(i,self.data[i]);});this.expand();return this;}
Chain.prototype.listDirectorySub=function(index,json){var self=this;this.utility.listDirectory(json,function(data){self.temporaryForTask[index]=data;self.next();});}
Chain.prototype.fileExists=function(path){var self=this;this.put("path",path);this.jobs.push(function(){self.temporaryForTask=[];self.task=self.data.length;for(var i=0;i<self.data.length;i++)self.fileExistsSub(i,self.data[i]);});return this;}
Chain.prototype.fileExistsSub=function(index,json){var self=this;var post=$.ajax({type:'POST',dataType:'text',url:"moirai2.php?command=file_exists",data:json});post.fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});post.success(function(data){self.temporaryForTask[index]=(data=="true");self.next();});}
//######################################## ICON (Desktop) ########################################
Chain.prototype.addChild=function(){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.desktopView.addChild(self.temporary[i]);self.start();});return this;}
Chain.prototype.removeChild=function(){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.desktopView.removeChild(self.temporary[i]);self.start();});return this;}
Chain.prototype.createCircleIcon=function(){var self=this;this.jobs.push(function(){self.temporary=[self.desktopView.createCircleIcon(self)];self.start();});return this;}
Chain.prototype.createRectangleIcon=function(){var self=this;this.jobs.push(function(){self.temporary=[self.desktopView.createRectangleIcon(self)];self.start();});return this;}
Chain.prototype.createPolygonIcon=function(){var self=this;this.jobs.push(function(){self.temporary=[self.desktopView.createPolygonIcon(self)];self.start();});return this;}
Chain.prototype.createFileIcon=function(path){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.temporary[i]=self.desktopView.createFileIcon(self.temporary[i],self);self.start();});return this;}
Chain.prototype.createDirectoryIcon=function(path){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.temporary[i]=self.desktopView.createDirectoryIcon(self.temporary[i],self);self.start();});return this;}
Chain.prototype.createTextCircleIcon=function(text){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.temporary[i]=self.desktopView.createTextCircleIcon(self.temporary[i],self);self.start();});return this;}
Chain.prototype.createImageIcon=function(image){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.temporary[i]=self.desktopView.createImageIcon(self.temporary[i],self);self.start();});return this;}
Chain.prototype.createDialogIcon=function(text){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.temporary[i]=self.desktopView.createDialogIcon(self.temporary[i],self);self.start();});return this;}
//processing
Chain.prototype.showProcessing=function(){var self=this;this.jobs.push(function(){self.processing=self.desktopView.createProcessingIcon(self);self.processing.time=new Date().getTime();self.desktopView.addChild(self.processing);self.start();});return this;}
Chain.prototype.hideProcessing=function(){var self=this;this.jobs.push(function(){var diff=new Date().getTime()-self.processing.time;var duration=500;if(diff<duration)setTimeout(function(){self.desktopView.removeChild(self.processing);self.start();},duration-diff);else{self.desktopView.removeChild(self.processing);self.start();}});return this;}
Chain.prototype.clickAndHide=function(){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.desktopView.clickAndHide(self.temporary[i]);self.start();});return this;}
//######################################## MODIFY ########################################
Chain.prototype.dataLoop=function(method){var self=this;this.jobs.push(function(){for(var i=0;i<self.data.length;i++){method(self.data[i]);}self.start();});return this;}
Chain.prototype.domLoop=function(method){var self=this;this.jobs.push(function(){for(var i=0;i<self.dom.length;i++){method(self.dom[i]);}self.start();});return this;}
Chain.prototype.tempLoop=function(method){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++){method(self.temporary[i]);}self.start();});return this;}
Chain.prototype.modifyTemp=function(method){var self=this;this.jobs.push(function(){if(Array.isArray(self.temporary)){for(var i=0;i<self.temporary.length;i++)self.temporary[i]=method(self.temporary[i],i);}else{self.temporary=method(self.temporary,0);}self.start();});return this;}
Chain.prototype.modifyDom=function(method){var self=this;this.jobs.push(function(){var array=[];if(Array.isArray(self.temporary)){for(var i=0;i<self.temporary.length;i++)array.push(method(self.temporary[i],i));}else{array.push(method(self.temporary,0));}self.dom=array;self.start();});return this;}
Chain.prototype.modifyData=function(method){var self=this;this.jobs.push(function(){var array=[];if(Array.isArray(self.temporary)){for(var i=0;i<self.temporary.length;i++)array.push(method(self.temporary[i],i));}else{array.push(method(self.temporary,0));}self.data=array;self.start();});return this;}
Chain.prototype.modifyPut=function(method){var self=this;this.jobs.push(function(){if(Array.isArray(self.temporary)){for(var i=0;i<self.temporary.length;i++)self.assignData(method(self.temporary[i],i),i);}else{self.assignData(method(self.temporary,0),0);}self.start();});return this;}
Chain.prototype.basenames=function(template){var self=this;if(template!=null)this.assemble(template);this.modifyPut(function(o){return self.utility.basenames(o);});return this;}
Chain.prototype.handleURL=function(template){var self=this;if(template!=null)this.assemble(template);this.modifyPut(function(o){return self.utility.handleURL(o);});return this;}
Chain.prototype.replace=function(from,to){this.modifyTemp(function(o){return o.replace(from,to);});return this;}
Chain.prototype.split=function(delim){if(typeof delim==='string')delim=new RegExp(delim);this.modifyTemp(function(o){return o.split(delim);});return this;}
Chain.prototype.join=function(delim){this.modifyTemp(function(o){if(Array.isArray(o))return o.join(delim);else return o;});return this;}
Chain.prototype.formatDate=function(format){var self=this;this.modifyTemp(function(o){return self.utility.formatDate(new Date(o),format);});return this;}
Chain.prototype.trim=function(){this.modifyTemp(function(o){return o.trim();});return this;}
Chain.prototype.stringify=function(template){if(template!=null)this.assemble(template);this.modifyTemp(function(o){return JSON.stringify(o);});return this;}
Chain.prototype.typeOf=function(){this.modifyTemp(function(o){return (typeof o);});return this;}
Chain.prototype.number=function(template){if(template!=null)this.assemble(template);this.modifyTemp(function(o){return Number(o);});return this;}
Chain.prototype.escapeCodeForHTML=function(template){if(template!=null)this.assemble(template);this.modifyTemp(function(o){return self.utility.escapeCodeForHTML(o);});return this;}
Chain.prototype.find=function(query){var self=this;this.modifyTemp(function(o){return $(o).find(query);});return this;}
Chain.prototype.toText=function(){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.temporary[i]=self.temporary[i].text();self.start();});return this;}
Chain.prototype.toVal=function(){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.temporary[i]=self.temporary[i].val();self.start();});return this;}
Chain.prototype.toHtml=function(){var self=this;this.jobs.push(function(){for(var i=0;i<self.temporary.length;i++)self.temporary[i]=self.temporary[i].html();self.start();});return this;}
Chain.prototype.grep=function(exp){var self=this;if(typeof exp==='string')exp=new RegExp(exp);this.jobs.push(function(){var array=[];for(var i=0;i<self.temporary.length;i++)if(self.temporary[i].match(exp))array.push(self.temporary[i]);self.temporary=array;self.start();});return this;}
Chain.prototype.ungrep=function(exp){var self=this;if(typeof exp==='string')exp=new RegExp(exp);this.jobs.push(function(){var array=[];for(var i=0;i<self.temporary.length;i++)if(!self.temporary[i].match(exp))array.push(self.temporary[i]);self.temporary=array;self.start();});return this;}
Chain.prototype.match=function(exp){var self=this;if(typeof exp==='string')exp=new RegExp(exp);this.modifyTemp(function(o){var result=exp.exec(o);var array=[];for(var i=1;i<result.length;i++)array.push(result[i]);return array;});return this;}
//######################################## NCBI ########################################
Chain.prototype.ncbiESearch=function(json){
	var self=this;
	this.jobs.push(function(){
		self.temporaryForTask=[];
		if(json!=null){
			self.task=1;
			self.ncbiESearchSub(json,0);
		}else{
			self.task=self.data.length;
			for(var i=0;i<self.data.length;i++)self.ncbiESearchSub(self.data[i],i);
		}
	});
	return this;
}
Chain.prototype.ncbiESearchUrl=function(json){
	var url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?usehistory=y";
	var esearchs=["id","db","term","retstart","retmax","rettype","retmode","sort","field","datetype","reldate","mindate","maxdate"];
	for(var i=0;i<esearchs.length;i++){
		var key=esearchs[i];
		var object=json[key];
		if(key in json)url+="&"+key+"="+((key=="term")?object.replace(new RegExp(" ","g"),'+'):object);
	}
	return url;
}
Chain.prototype.ncbiESearchSub=function(json,index){
	var self=this;
	Utility.prototype.readXML(self.ncbiESearchUrl(json),function(data){
		if("db" in json)$(data).children(0).append($($.parseXML("<db>"+json["db"]+"</db>")).children(0));
		if("retmax" in json)$(data).children(0).append($($.parseXML("<retmax>"+json["retmax"]+"</retmax>")).children(0));
		self.xml[index]=$(data);
		self.temporaryForTask[index]=$(data);
		self.next();
	});
}
Chain.prototype.ncbiESummary=function(){
	var self=this;
	this.jobs.push(function(){
		self.temporaryForTask=[];
		self.task=self.xml.length;
		for(var i=0;i<self.xml.length;i++)self.ncbiESummarySub(self.xml[i],i);
	});
	return this;
}
Chain.prototype.ncbiESummaryUrl=function(xml){
	var db=xml.find("db").text();
	var url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db="+db;
	var webEnv=xml.find("WebEnv").text();
	if(webEnv!=null&&webEnv!="")url+="&WebEnv="+webEnv;
	var queryKey=xml.find("QueryKey").text();
	if(queryKey!=null&&queryKey!="")url+="&query_key="+queryKey;
	var retmax=xml.find("retmax").text();
	if(retmax!=null&&retmax!="")url+="&retmax="+retmax;
	return url;
}
Chain.prototype.ncbiESummarySub=function(xml,index){
	var self=this;
	Utility.prototype.readXML(self.ncbiESummaryUrl(xml),function(data){
		self.xml[index]=$(data);
		self.temporaryForTask[index]=$(data);
		self.next();
	});
}
Chain.prototype.ncbiEFetch=function(){
	var self=this;
	this.jobs.push(function(){
		self.temporaryForTask=[];
		self.task=self.xml.length;
		for(var i=0;i<self.xml.length;i++)self.ncbiEFetchSub(self.xml[i],i);
	});
	return this;
}
Chain.prototype.ncbiEFetchUrl=function(xml,json){
	var url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?retmode=xml";
	var db=xml.find("db").text();
	if(db!=null&&db!="")url+="&db="+db;
	var webEnv=xml.find("WebEnv").text();
	if(webEnv!=null&&webEnv!="")url+="&WebEnv="+webEnv;
	var queryKey=xml.find("QueryKey").text();
	if(queryKey!=null&&queryKey!="")url+="&query_key="+queryKey;
	var retmax=xml.find("retmax").text();
	if(retmax!=null&&retmax!="")url+="&retmax="+retmax;
	return url;
}
Chain.prototype.ncbiEFetchSub=function(xml,index){
	var self=this;
	Utility.prototype.readXML(self.ncbiEFetchUrl(xml),function(data){
		self.xml[index]=$(data);
		self.temporaryForTask[index]=$(data);
		self.next();
	});
}
Chain.prototype.ncbiEDownload=function(json){
	var self=this;
	this.jobs.push(function(){
		self.temporary=[];
		for(var i=0;i<self.xml.length;i++){
			var hash={};
			hash["url"]=self.ncbiEFetchUrl(self.xml[i],json);
			hash["filename"]="ncbi.xml";
			self.temporary[i]=hash;
		}
		self.start();
	});
	self.downloadFile();
	return this;
}
Chain.prototype.ncbiELink=function(json){
	var self=this;
	this.jobs.push(function(){
		self.temporaryForTask=[];
		if(json!=null){
			self.task=1;
			self.ncbiELinkSub(json,0);
		}else{
			self.task=self.data.length;
			for(var i=0;i<self.data.length;i++)self.ncbiELinkSub(self.data[i],i);
		}
	});
	return this;
}
Chain.prototype.ncbiELinkUrl=function(json){
	var url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?usehistory=y&cmd=neighbor_history";
	var webEnv=$(self.temporary).find("WebEnv").text();
	if(webEnv!=null&&webEnv!="")url+="&WebEnv="+webEnv;
	var queryKey=$(self.temporary).find("QueryKey").text();
	if(queryKey!=null&&queryKey!="")url+="&query_key="+queryKey;
	var retmax=$(self.temporary).find("retmax").text();
	if(retmax!=null&&retmax!="")url+="&retmax="+retmax;
	var elinks=["id","db","dbfrom","cmd","retmod","linkname","term","holding","datetype","reldate","mindate","maxdate"];
	for(var i=0;i<elinks.length;i++)if(elinks[i] in json)url+="&"+elinks[i]+"="+json[elinks[i]];
	console.log(url);
	return url;
}
Chain.prototype.ncbiELinkSub=function(json,index){
	var self=this;
	Utility.prototype.readXML(self.ncbiELinkUrl(json),function(data){
		if("db" in json)$(data).children(0).append($($.parseXML("<db>"+json["db"]+"</db>")).children(0));
		if("retmax" in json)$(data).children(0).append($($.parseXML("<retmax>"+json["retmax"]+"</retmax>")).children(0));
		self.temporaryForTask[index]=$(data);
		self.xml[index]=$(data);
		self.next();
	});
}
//######################################## PARAMETER ########################################
Chain.prototype.setRadius=function(radius){var self=this;this.jobs.push(function(){self.radius=radius;self.start();});return this;}
Chain.prototype.setSize=function(width,height){var self=this;this.jobs.push(function(){self.width=width;self.height=height;self.start();});return this;}
//######################################## RDF ########################################
Chain.prototype.readRDF=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){if(Array.isArray(self.temporary)){self.task=self.temporary.length;self.temporaryForTask=[];for(var i=0;i<self.temporary.length;i++){self.readRDFSub(i);}}else{self.utility.readRDF(self.temporary,function(data){self.temporary=data;self.start();})}});return this;}
Chain.prototype.readRDFSub=function(index){var self=this;self.utility.readRDF(self.temporary[index],function(data){self.temporaryForTask[index]=data;self.next("rdf");});}
Chain.prototype.parseControls=function(controls){
	var self=this;
	this.jobs.push(function(){
		var urladdress=self.data[0]["urladdress"];
		controls.forEach(function(control){self.putRDFSub(urladdress,"http://localhost/~ah3q/schema/daemon/control",control);});
		self.start();
	});
	return this;
}
Chain.prototype.rdfToNetwork=function(){
	var self=this;
	this.jobs.push(function(){
		var hash={};
		var edges=[];
		var subjects=Object.keys(self.rdf);
		for(var i=0;i<subjects.length;i++){
			var subject=subjects[i];
			if(!(subject in hash)){hash[subject]=Object.keys(hash).length;}
			var subjectid=hash[subject];
			var predicates=Object.keys(self.rdf[subject]);
			for(var j=0;j<predicates.length;j++){
				var predicate=predicates[j];
				var predicateid=predicate;
				predicateid=predicateid.replace("http://localhost/~ah3q/schema/","s:");
				predicateid=predicateid.replace("http://localhost/~ah3q/javascript/2018/command/","m:");
				predicateid=predicateid.replace("http://localhost/~ah3q/javascript/2018/control/","c:");
				var object=self.rdf[subject][predicate];
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
		self.network={nodes:nodes,edges:edges};
		self.start();
	});
	return this;
}
Chain.prototype.rdfToData=function(row,column){
	var self=this;
	this.jobs.push(function(){
		var rows=[];
		var rname;
		var subjects=Object.keys(self.rdf);
		for(var i=0;i<subjects.length;i++){
			var subject=subjects[i];
			var predicates=Object.keys(self.rdf[subject]);
			for(var j=0;j<predicates.length;j++){
				var predicate=predicates[j];
				var object=self.rdf[subject][predicate];
				if(predicate in row){
					if(rname==null)rname=row[predicate];
					if(Array.isArray(object)){for(var k=0;k<object.length;k++)rows.push(object[k]);}
					else{rows.push(object);}
				}
			}
		}
		for(var i=0;i<rows.length;i++){
			var subject=rows[i];
			var hash={};
			hash[rname]=subject;
			if(!(subject in self.rdf))continue;
			var predicates=Object.keys(self.rdf[subject]);
			for(var j=0;j<predicates.length;j++){
				var predicate=predicates[j];
				if(!(predicate in column))continue;
				var cname=column[predicate];
				var object=self.rdf[subject][predicate];
				hash[cname]=object;
			}
			self.assignData(hash,i);
		}
		self.start();
	});
	return this;
}
Chain.prototype.rdfToDom=function(template){
	var self=this;if(template==null)template={};this.jobs.push(function(){
		if("class" in template&&"class" in self.rdf["rdfquery"])self.dom.push(template["class"](self.rdf["rdfquery"]["class"],self.rdf));
		if("subject" in template&&"subject" in self.rdf["rdfquery"])self.dom.push(template["subject"](self.rdf["rdfquery"]["subject"],self.rdf));
		if("predicate" in template&&"predicate" in self.rdf["rdfquery"])self.dom.push(template["predicate"](self.rdf["rdfquery"]["predicate"],self.rdf));
		if("object" in template&&"object" in self.rdf["rdfquery"])self.dom.push(template["object"](self.rdf["rdfquery"]["object"],self.rdf));
		var subjects=Object.keys(self.rdf);
		for(var i=0;i<subjects.length;i++){
			var subject=subjects[i];
			if(subject=="rdfquery"){continue;}
			var predicates=Object.keys(self.rdf[subject]);
			for(var j=0;j<predicates.length;j++){
				var predicate=predicates[j];
				var object=self.rdf[subject][predicate];
				if(!(predicate in template)){
					if("." in template){
						if(Array.isArray(object)){for(var k=0;k<object.length;k++)self.dom.push(template["."](subject,predicate,object[k],self.rdf));}
						else self.dom.push(template["."](subject,predicate,object,self.rdf));
					}else continue;
				}else{
					if(Array.isArray(object)){for(var k=0;k<object.length;k++)self.dom.push(template[predicate](subject,predicate,object[k],self.rdf));}
					else self.dom.push(template[predicate](subject,predicate,object,self.rdf));
				}
			}
		}
		self.start();
	});
	return this;
}
Chain.prototype.recordFileFormat=function(){var self=this;this.jobs.push(function(){self.task=self.temporary.length;self.temporaryForTask=[];for(var i=0;i<self.data.length;i++)self.recordFileFormatSub(i);});return this;}
Chain.prototype.recordFileFormatSub=function(index){var self=this;self.sqliteRDFModel.recordFileFormat(this.data[index]["filepath"],this.data[index]["fileformat"],function(){self.next();});}
Chain.prototype.recordPath=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){if(template==null&&self.containsKeySub("path"))self.setTemporarySub("path");self.task=self.temporary.length;self.temporaryForTask=[];for(var i=0;i<self.temporary.length;i++)self.recordPathSub(i);});return this;}
Chain.prototype.recordPathSub=function(index){var self=this;self.sqliteRDFModel.recordPath(self.temporary[index],function(data){self.temporaryForTask[index]=data;self.next();});}
Chain.prototype.downloadFile=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){if(template==null&&self.containsKeySub("url"))self.setTemporarySub("url");self.task=self.temporary.length;self.temporaryForTask=[];for(var i=0;i<self.temporary.length;i++)self.downloadFileSub(i);});return this;}
Chain.prototype.downloadFileSub=function(index){var self=this;self.utility.downloadFile(self.temporary[index],function(data){self.temporaryForTask[index]=data;if(self.data[index]!=null)self.data[index]["path"]=data;self.next();});}
Chain.prototype.uploadFile=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){if(template==null&&self.containsKeySub("file"))self.setTemporarySub("file");self.task=self.temporary.length;self.temporaryForTask=[];for(var i=0;i<self.temporary.length;i++)self.uploadFileSub(i);});return this;}
Chain.prototype.uploadFileSub=function(index){var self=this;self.utility.uploadFile(self.temporary[index],function(data){self.temporaryForTask[index]=data;if(self.data[index]!=null)self.data[index]["path"]=data;self.next();});}
Chain.prototype.searchCommand=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){if(template==null&&self.containsKeySub("fileformat"))self.setTemporarySub("fileformat");self.task=self.temporary.length;self.temporaryForTask=[];for(var i=0;i<self.temporary.length;i++)self.searchCommandSub(i);});return this;}
Chain.prototype.searchCommandSub=function(index){var self=this;var fileformat=this.temporary[index];self.sqliteRDFModel.searchCommand(fileformat,function(data){self.temporaryForTask[index]=data;if(self.data[index]!=null)self.data[index]["command"]=data;self.next();});}
Chain.prototype.searchFileFormat=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){if(template==null&&self.containsKeySub("filesuffix"))self.setTemporarySub("filesuffix");self.task=self.temporary.length;self.temporaryForTask=[];for(var i=0;i<self.temporary.length;i++)self.searchFileFormatSub(i);});return this;}
Chain.prototype.searchFileFormatSub=function(index){var self=this;var suffix=this.temporary[index];self.sqliteRDFModel.searchFileFormat(suffix,function(data){if(self.data[index]!=null)self.data[index]["fileformat"]=data;self.temporaryForTask[index]=data;self.next();});}
Chain.prototype.queryToData=function(json){
	var self=this;
	if(json==null)json={};
	this.jobs.push(function(){
		var keys=Object.keys(self.query);
		var hash=(keys.length>0)?self.query:json;
		if(self.data.length==0)self.data[0]={};
		for(var i=0;i<self.data.length;i++)Object.assign(self.data[i],hash);
		self.start();
	});
	return this;
}
Chain.prototype.putQuery=function(json){
	var self=this;
	if(json==null)json={};
	this.jobs.push(function(){
		Object.assign(self.query,json);
		self.start();
	});
	return this;
}
Chain.prototype.newNode=function(key){
	var self=this;
	this.jobs.push(function(){
		if(self.data.length==0)self.data[0]={};
		self.task=self.data.length;self.temporaryForTask=[];
		for(var i=0;i<self.data.length;i++)self.newNodeSub(self.data[i],key);
	});
	return this;
}
Chain.prototype.newNodeSub=function(data,key){var self=this;this.sqliteRDFModel.newNode(function(name){data[key]=name;self.next();});}
Chain.prototype.executeCommand=function(template){
	var self=this;
	if(template!=null)this.assemble(template);
	this.jobs.push(function(){
		var json=JSON.parse(self.temporary);
		self.sqliteRDFModel.executeCommand(json,function(){self.start();});
	});
	return this;
}
Chain.prototype.selectRDF=function(json){var self=this;this.jobs.push(function(){if(json==null)json=self.query;self.sqliteRDFModel.selectRDF(json,function(rdf){self.rdf=rdf;self.start();});});return this;}
Chain.prototype.insertRDF=function(template){var self=this;if(template!=null)this.parseRDF(template);this.jobs.push(function(){self.sqliteRDFModel.insertRDF(self.rdf,function(){self.start();});});return this;}
Chain.prototype.updateRDF=function(template){var self=this;if(template!=null)this.parseRDF(template);this.jobs.push(function(){self.sqliteRDFModel.updateRDF(self.rdf,function(){self.start();});});return this;}
Chain.prototype.deleteRDF=function(template){var self=this;if(template!=null)this.parseRDF(template);this.jobs.push(function(){self.sqliteRDFModel.deleteRDF(self.rdf,function(){self.start();});});return this;}
Chain.prototype.parseRDF=function(template){
	var self=this;
	if(template!=null){
		if(Array.isArray(template)){template=template.join(",");}
		this.assemble(template);
	}
	this.modifyTemp(function(o){
		var tokens=o.split(",");
		for(var i=0;i<tokens.length;i++){
			var elements=tokens[i].split("->");
			if(elements.length==3)self.putRDFSub(elements[0],elements[1],elements[2]);
		}
		return o;
	});
	return this;
}
Chain.prototype.getRDF=function(json){var self=this;this.jobs.push(function(){if(json==null)json={};self.rdf=self.sqliteRDFModel.getRDF(self.rdf,json);self.start();});return this;}
Chain.prototype.getRDFSubjects=function(json){var self=this;if(json==null)json={};this.jobs.push(function(){self.temporary=self.sqliteRDFModel.getSubjects(self.rdf);self.start();});return this;}
Chain.prototype.getRDFPredicates=function(json){var self=this;if(json==null)json={};this.jobs.push(function(){self.temporary=self.sqliteRDFModel.getPredicates(self.rdf);self.start();});return this;}
Chain.prototype.getRDFObjects=function(json){var self=this;if(json==null)json={};this.jobs.push(function(){self.temporary=self.sqliteRDFModel.getObjects(self.rdf);self.start();});return this;}
Chain.prototype.putRDF=function(subject,predicate,object){var self=this;this.jobs.push(function(){if(object==null)object=self.temporary;self.putRDFSub(subject,predicate,object);self.start();});return this;}
Chain.prototype.putRDFSub=function(subject,predicate,object){if(!(subject in this.rdf))this.rdf[subject]={};if(!(predicate in this.rdf[subject])){this.rdf[subject][predicate]=object;}else{if(!Array.isArray(this.rdf[subject][predicate]))this.rdf[subject][predicate]=[this.rdf[subject][predicate]];if(Array.isArray(object))for(var i=0;i<object.length;i++)this.rdf[subject][predicate].push(object[i]);else this.rdf[subject][predicate].push(object);}}
Chain.prototype.queryRDF=function(query,key){
	var self=this;
	this.jobs.push(function(){
		if(query==null)query=self.temporary;
		if(Array.isArray(query)){query=query.join(",");}
		if(key!=null){
			self.sqliteRDFModel.queryRDF({query:query},function(data){
				for(var i=0;i<data.length;i++){
					var k=data[i][key];
					var index=-1;
					for(var j=0;j<self.data.length;j++){if(k==self.data[j][key]){index=j;break;}}
					if(index<0){index=self.data.length;self.data[index]={};}
					Object.assign(self.data[index],data[i]);
				}
				self.start();
			});
		}else{
			self.sqliteRDFModel.queryRDF({query:query},function(data){
				for(var i=0;i<data.length;i++){
					if(self.data[i]==null)self.data[i]={};
					Object.assign(self.data[i],data[i]);
					self.temporary[i]=data[i];
				}
				if(data.length>0)self.start();
			});
		}
	});
	return this;
}
//######################################## READ ########################################
Chain.prototype.readImage=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){self.task=self.temporary.length;self.temporaryForTask=[];for(var i=0;i<self.temporary.length;i++)self.readImageSub(i);});return this;}
Chain.prototype.readImageSub=function(index){var self=this;var path=self.temporary[index];self.utility.readImage(path,function(data){self.temporaryForTask[index]=$(data);self.next("dom");});}
Chain.prototype.readFile=function(template){var self=this;if(template!=null)this.assemble(template);this.jobs.push(function(){if(Array.isArray(self.temporary)){self.task=self.temporary.length;self.temporaryForTask=[];for(var i=0;i<self.temporary.length;i++){self.readFileSub(i);}}else{self.utility.readFile(self.temporary,function(data){self.temporary=data;self.start();})}});return this;}
Chain.prototype.readFileSub=function(index){var self=this;self.utility.readFile(self.temporary[index],function(data){self.temporaryForTask[index]=data;self.next();});}
Chain.prototype.readJson=function(template){
	var self=this;
	if(template!=null)this.assemble(template);
	this.jobs.push(function(){
		var index=self.json.length;
		if(Array.isArray(self.temporary)){
			self.task=self.temporary.length;
			self.temporaryForTask=[];
			for(var i=0;i<self.temporary.length;i++)self.readJsonSub(index+i,self.temporary[i]);
		}else{
			self.utility.readJson(self.temporary,function(data){
				self.json[index]=data;
				self.temporary=[data];
				self.start();
			});
		}
	});
	return this;
}
Chain.prototype.readJsonSub=function(index,url){
	var self=this;
	this.utility.readJson(url,function(data){
		self.json[index]=data;
		self.temporaryForTask[index]=data;
		self.next();
	});
}
Chain.prototype.jsonToData=function(){
	var self=this;
	this.jobs.push(function(){
		for(var i=0;i<self.json.length;i++){
			if(self.data[i]==null)self.data[i]={};
			Object.assign(self.data[i],self.json[i]);
		}
		self.start();
	});
	return this;
}
//######################################## TABLE ########################################
Chain.prototype.createFileTable=function(){var self=this;this.jobs.push(function(){var table=$("<table>");table.append($("<tr><th>filepath</th><th>filesize</th><th>last modified</th></tr>"));for(var i=0;i<self.data.length;i++){var path=self.data[i]["path"];var size=self.data[i]["size"];var mtime=self.data[i]["mtime"];table.append($("<tr><td>"+path+"</td><td>"+size+"</td><td>"+mtime+"</td></tr>"));}self.dom=[table];self.start();});return this;}
Chain.prototype.dataToHTMLTable=function(){var self=this;this.jobs.push(function(){self.dom=[self.utility.dataToHTMLTable(self.data)];self.start();});return this;}
Chain.prototype.rdfToHTMLTable=function(){var self=this;this.jobs.push(function(){self.dom=[self.utility.rdfToHTMLTable(self.rdf)];self.start();});return this;}
Chain.prototype.rdfToHTMLPage=function(template){
	var self=this;
	this.jobs.push(function(){
		var subjects=Object.keys(self.rdf);
		for(var i=0;i<subjects.length;i++){
			var subject=subjects[i];
			var predicates=Object.keys(self.rdf[subject]);
			for(var j=0;j<predicates.length;j++){
				var predicate=predicates[j];
				var object=self.rdf[subject][predicate];
				var regexp=new RegExp("\\$"+predicate,"g");
				template=template.replace(regexp,object);
			}
		}
		self.dom=[$(template)];
		self.start();
	});
	return this;
}
//######################################## TEMPORARY ########################################
Chain.prototype.forLoop=function(number,method){var self=this;this.jobs.push(function(){for(var i=0;i<number;i++){self.temporary[i]=method(i,self);}self.start();});return this;}
Chain.prototype.tsvToArrayHash=function(){var self=this;this.jobs.push(function(){self.data=self.utility.tsvToArrayHash(self.temporary);self.start();});return this;}
//######################################## XML ########################################
Chain.prototype.readXML=function(template){
	var self=this;
	if(template!=null)this.assemble(template);
	this.jobs.push(function(){
		var index=self.xml.length;
		if(Array.isArray(self.temporary)){
			self.task=self.temporary.length;
			self.temporaryForTask=[];
			for(var i=0;i<self.temporary.length;i++)self.readXMLSub(index+i,self.temporary[i]);
		}else{
			self.utility.readXML(self.temporary,function(data){
				self.xml[index]=data;
				self.temporary=[data];
				self.start();
			});
		}
	});
	return this;
}
Chain.prototype.readXMLSub=function(index,url){
	var self=this;
	this.utility.readXML(url,function(data){
		self.xml[index]=data;
		self.temporaryForTask[index]=data;
		self.next();
	});
}
Chain.prototype.parseXML=function(){
	var self=this;
	this.modifyTemp(function(o){return $.parseXML(o);});
	return this;
}
Chain.prototype.xmlToHash=function(){
	var self=this;
	this.jobs.push(function(){
		self.data=[];
		for(var i=0;i<self.xml.length;i++)self.data[i]=self.utility.xmlToHash(self.xml[i]);
		self.start();
	});
	return this;
}
Chain.prototype.uploadXML=function(query){
	var self=this;
	this.jobs.push(function(){
		if(!Array.isArray(self.xml))self.xml=[self.xml];
		self.task=self.xml.length;
		self.temporaryForTask=[];
		for(var i=0;i<self.xml.length;i++)self.uploadXMLSub(query,i);
	});
	return this;
}
Chain.prototype.uploadXMLSub=function(query,index){
	var self=this;
	var s=new XMLSerializer();
	var text=s.serializeToString(self.xml[index]);
	var filename=(query!=null)?$(self.xml[index]).find(query).text():"undefined";
	filename+=".xml";
	self.utility.uploadXML(text,filename,function(data){
		self.temporaryForTask[index]=data;
		if(self.data[index]==null)self.data[index]={};
		self.data[index]["path"]=data;
		self.next();
	});
}
Chain.prototype.xmlToData=function(keyWord){
	var self=this;this.jobs.push(function(){
		for(var i=0;i<self.xml.length;i++){
			if(self.data[i]==null)self.data[i]={};
			self.data[i][keyWord]=self.xml[i];
		}
		self.start();
	});
	return this;
}
Chain.prototype.xmlFind=function(query){
	var self=this;
	this.jobs.push(function(){
		var temp=[];
		for(var i=0;i<self.xml.length;i++){
			var result=$(self.xml[i]).find(query);
			for(var j=0;j<result.length;j++)temp.push(result[j]);
		}
		self.xml=temp;
		self.start();
	});
	return this;
}
Chain.prototype.xmlPut=function(keyWord,query){
	var self=this;
	this.jobs.push(function(){
		var hash={};
		if(query!=null)hash[keyWord]=query;
		else if(self.utility.isObject(keyWord))hash=keyWord;
		Object.keys(hash).forEach(function(k){
			var q=hash[k];
			if(Array.isArray(q)){
				var q2=q[0];
				var exp=q[1];
				for(var i=0;i<self.xml.length;i++){
					if(self.data[i]==null)self.data[i]={};
					if(self.data[i][k]==null)self.data[i][k]=[];
					var result=$(self.xml[i]).find(q2);
					for(var j=0;j<result.length;j++){
						var vars=self.utility.handleExpression(exp);
						var temp={};
						for(var l=0;l<vars.length;l++)temp[vars[l]]=$(result[j]).find(vars[l]).text();
						var exp2=self.utility.assembleText(exp,temp);
						self.data[i][k].push(exp2);
					}
				}
			}else{
				for(var i=0;i<self.xml.length;i++){
					if(self.data[i]==null)self.data[i]={};
					if(self.data[i][k]==null)self.data[i][k]=[];
					var result=$(self.xml[i]).find(q);
					for(var j=0;j<result.length;j++)self.data[i][k].push($(result[j]).text());
				}
			}
		});
		self.start();
	});
	return this;
}
//######################################## WRITE ########################################
Chain.prototype.writeFile=function(template){
	var self=this;
	if(template!=null){this.assemble(template);this.put("content");}
	this.jobs.push(function(){if(Array.isArray(self.temporary)){self.task=self.temporary.length;self.temporaryForTask=[];for(var i=0;i<self.temporary.length;i++){self.writeFileSub(i);}}else{self.utility.writeFile(self.temporary,function(data){self.temporary=data;self.start();})}});return this;}
	Chain.prototype.writeFileSub=function(index){var self=this;self.utility.writeFile(self.data[index]["filepath"],self.data[index]["content"],function(data){self.temporaryForTask[index]=data;self.next();});}
