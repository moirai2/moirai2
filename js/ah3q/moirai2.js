//######################################## CONSTRUCTOR ########################################
function moirai2(rdfdb){
	var self=this;
	this.rdfdb=rdfdb;
}
//######################################## QUERY ########################################
moirai2.prototype.rdfQuery=function(text,method){
	var self=this;
	var json={rdfdb:self.rdfdb,query:text};
	var post=$.ajax({type:'POST',dataType:'json',url:"moirai2.php?command=query",data:json});
	post.fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});
	post.done(function(data){if(method!=null)method(data);});
}
moirai2.prototype.rdfInsert=function(rdf,method){
	var self=this;
	var json={rdfdb:self.rdfdb,data:JSON.stringify(rdf)};
	var post=$.ajax({type:'POST',dataType:'text',url:"moirai2.php?command=insert",data:json});
	post.fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});
	post.done(function(data){if(method!=null)method(data);});
}
moirai2.prototype.rdfUpdate=function(rdf,method){
	var self=this;
	var json={rdfdb:self.rdfdb,data:JSON.stringify(rdf)};
	var post=$.ajax({type:'POST',dataType:'text',url:"moirai2.php?command=update",data:json});
	post.fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});
	post.done(function(data){if(method!=null)method(data);});
}
moirai2.prototype.submitJob=function(json){
	var self=this;
	if(!("rdfdb" in json))json["rdfdb"]=self.rdfdb;
	var post=$.ajax({type:'POST',dataType:'text',url:"moirai2.php?command=submit",data:json});
	post.fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});
	post.done(function(data){})
}
moirai2.prototype.checkProgress=function(method){
	var self=this;
	var json={rdfdb:self.rdfdb};
	var post=$.ajax({type:'POST',dataType:'json',url:"moirai2.php?command=progress",data:json});
	post.fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});
	post.done(function(data){if(method!=null)method(data);});
}
//######################################## Drag and Drop ########################################
moirai2.prototype.initialize=function(id){
	var self=this;
	if(document.readyState=="loading"){
		$(document).ready(function(){self.initialize(id);});
		return this;
	}
	this.id=id;
	this.dom=document.getElementById(this.id);
	this.dom.addEventListener("dragenter",function(event){event.stopPropagation();event.preventDefault();},true);
	this.dom.addEventListener("dragover",function(event){event.stopPropagation();event.preventDefault();},true);
	this.dom.addEventListener("drop",function(event){event.stopPropagation();event.preventDefault();self.dropped(event);},true);
	return this;
}
moirai2.prototype.appendChild=function(element){this.dom.appendChild(element);}
moirai2.prototype.acceptServerPath=function(boolean){if(boolean==null)boolean=true;this.acceptServerPath=boolean;return this;}
moirai2.prototype.whenFileIsDroppedRead=function(boolean){if(boolean==null)boolean=true;this.readFromFile=boolean;return this;}
moirai2.prototype.whenUrlIsDroppedRead=function(boolean){if(boolean==null)boolean=true;this.readFromUrl=boolean;return this;}
moirai2.prototype.whenUrlIsDroppedSave=function(boolean){if(boolean==null)boolean=true;this.saveFromUrl=boolean;return this;}
moirai2.prototype.whenFileIsDroppedSave=function(boolean){if(boolean==null)boolean=true;this.saveFromFile=boolean;return this;}
moirai2.prototype.whenFileIsDroppedGetFilename=function(boolean){if(boolean==null)boolean=true;this.getFilenameFromFile=boolean;return this;}
moirai2.prototype.whenUrlIsDroppedGetFilename=function(boolean){if(boolean==null)boolean=true;this.getFilenameFromUrl=boolean;return this;}
moirai2.prototype.addEventListener=function(type,listener,useCapture,wantsUntrusted){this.dom.addEventListener(type,listener,useCapture,wantsUntrusted);}
moirai2.prototype.dropped=function(event){
	let self=this;
	let rectangle=this.dom.getBoundingClientRect();
	let x=event.clientX-rectangle.left;
	let y=event.clientY-rectangle.top;
	let dataTransfer=event.dataTransfer;
	let text=dataTransfer.getData("text");
	if(text!==""){
		if(!text.match(/\n/)&&text.startsWith("http://")||text.startsWith("https://")){
			let url=text;
			let filename=this.filename(text);
			if(this.readFromUrl){
				if(this.isImageFile(text))this.readImage(text,function(image){self.dom.dispatchEvent(new CustomEvent("imageWasRead",{detail:{x:x,y:y,image:image,url:url,filename:filename}}));});
				else this.readUrl(text,function(text){self.dom.dispatchEvent(new CustomEvent("textWasRead",{detail:{x:x,y:y,text:text,url:url,filename:filename}}));});
			}else if(this.saveFromUrl){
				this.downloadFile(text,function(path){self.dom.dispatchEvent(new CustomEvent("fileWasSaved",{detail:{x:x,y:y,url:url,path:path,filename:filename}}));});
			}else if(this.getFilenameFromUrl){
				this.dom.dispatchEvent(new CustomEvent("fileNameWasDropped",{detail:{x:x,y:y,url:url,filename:filename}}));
			}else{
				this.dom.dispatchEvent(new CustomEvent("urlWasDropped",{detail:{x:x,y:y,url:url}}));
			}
		}else if(this.acceptServerPath&&text.startsWith("/")){
			let url=text;
			let filename=this.filename(text);
			this.symlinkFile(text,function(path){self.dom.dispatchEvent(new CustomEvent("fileWasSaved",{detail:{x:x,y:y,url:url,path:path,filename:filename}}));});
		}else{
			this.dom.dispatchEvent(new CustomEvent("textWasDropped",{detail:{x:x,y:y,text:text}}));
		}
	}else{
		for(let i=0;i<dataTransfer.files.length;i++){
			let file=dataTransfer.files[i];
			let filename=this.filename(file.name);
			if(this.readFromFile){
				if(this.isImageFile(file.name))this.readImage(file,function(image){self.dom.dispatchEvent(new CustomEvent("imageWasRead",{detail:{x:x,y:y,image:image,filename:filename}}));});
				else this.readFile(file,function(text){self.dom.dispatchEvent(new CustomEvent("textWasRead",{detail:{x:x,y:y,text:text,filename:filename}}));});
			}else if(this.saveFromFile){
				this.uploadFile(file,function(path){self.dom.dispatchEvent(new CustomEvent("fileWasSaved",{detail:{x:x,y:y,path:path,filename:filename}}));});
			}else if(this.getFilenameFromFile){
				this.dom.dispatchEvent(new CustomEvent("fileNameWasDropped",{detail:{x:x,y:y,filename:filename}}));
			}else{
				if(this.isImageFile(file.name))this.dom.dispatchEvent(new CustomEvent("imageWasDropped",{detail:{x:x,y:y,file:file}}));
				else this.dom.dispatchEvent(new CustomEvent("fileWasDropped",{detail:{x:x,y:y,file:file}}));
			}
		}
	}
}
//######################################## Utility ########################################
moirai2.prototype.filename=function(path){return path.substring(path.lastIndexOf('\/')+1);}
moirai2.prototype.isImageFile=function(path){return path.endsWith(".jpg")||path.endsWith(".jpeg")||path.endsWith(".png")||path.endsWith(".gif");}
moirai2.prototype.readImage=function(path,method){if(Object.prototype.toString.call(path)==='[object String]'){var image=new Image();image.onload=function(){method(image);};image.src=path;}else{var reader=new FileReader();reader.onload=function(e){var image=new Image();image.onload=function(){method(image);};image.src=e.target.result;};reader.fail=function(xhr,textStatus){console.log("failed",xhr,textStatus);};reader.readAsDataURL(path);}}
moirai2.prototype.readUrl=function(url,method){var self=this;$.post("moirai2.php?command=proxy",{url:url},function(data){method(data);});}
moirai2.prototype.downloadFile=function(url,method){var self=this;var post=$.ajax({type:'POST',url:"moirai2.php?command=download",data:(typeof url==='object')?url:{'url':url}}).fail(function(xhr,data){console.log("failed",xhr,data);});if(method!=null)post.success(function(path){method(path);});}
moirai2.prototype.symlinkFile=function(url,method){var self=this;var post=$.ajax({type:'POST',url:"moirai2.php?command=symlink",data:(typeof url==='object')?url:{'url':url}}).fail(function(xhr,data){console.log("failed",xhr,data);});if(method!=null)post.success(function(path){method(path);});}
moirai2.prototype.uploadFile=function(file,method){var self=this;var fd=new FormData();fd.append("file",file,file.name);var post=$.ajax({type:'POST',contentType:false,processData:false,url:"moirai2.php?command=upload",data:fd,dataType:"text"}).fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});if(method!=null)post.success(function(path){method(path);});}
moirai2.prototype.readFile=function(path,method){if(Object.prototype.toString.call(path)==='[object String]')$.get(path,function(data){method(data);});else{var reader=new FileReader();reader.onload=function(e){method(e.target.result);};reader.fail=function(xhr,textStatus){console.log("failed",xhr,textStatus);};reader.readAsText(path);}}
