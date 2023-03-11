//######################################## CONSTRUCTOR ########################################
function DnD(id){
	var self=this;
	this.initialize(id);
}
//######################################## Drag and Drop ########################################
DnD.prototype.initialize=function(id){
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
DnD.prototype.whenFileIsDroppedRead=function(boolean){if(boolean==null)boolean=true;this.readFromFile=boolean;return this;}
DnD.prototype.whenUrlIsDroppedRead=function(boolean){if(boolean==null)boolean=true;this.readFromUrl=boolean;return this;}
DnD.prototype.whenFileIsDroppedGetFilename=function(boolean){if(boolean==null)boolean=true;this.getFilenameFromFile=boolean;return this;}
DnD.prototype.whenUrlIsDroppedGetFilename=function(boolean){if(boolean==null)boolean=true;this.getFilenameFromUrl=boolean;return this;}
DnD.prototype.addEventListener=function(type,listener,useCapture,wantsUntrusted){this.dom.addEventListener(type,listener,useCapture,wantsUntrusted);}
DnD.prototype.dropped=function(event){
	console.log(event);
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
			}else if(this.getFilenameFromUrl){
				this.dom.dispatchEvent(new CustomEvent("fileNameWasDropped",{detail:{x:x,y:y,url:url,filename:filename}}));
			}else{
				this.dom.dispatchEvent(new CustomEvent("urlWasDropped",{detail:{x:x,y:y,url:url}}));
			}
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
DnD.prototype.filename=function(path){return path.substring(path.lastIndexOf('\/')+1);}
DnD.prototype.isImageFile=function(path){return path.endsWith(".jpg")||path.endsWith(".jpeg")||path.endsWith(".png")||path.endsWith(".gif");}
DnD.prototype.readImage=function(path,method){if(Object.prototype.toString.call(path)==='[object String]'){var image=new Image();image.onload=function(){method(image);};image.src=path;}else{var reader=new FileReader();reader.onload=function(e){var image=new Image();image.onload=function(){method(image);};image.src=e.target.result;};reader.fail=function(xhr,textStatus){console.log("failed",xhr,textStatus);};reader.readAsDataURL(path);}}
DnD.prototype.readUrl=function(url,method){var self=this;$.post("DnD.php?command=proxy",{url:url},function(data){method(data);});}
DnD.prototype.readFile=function(path,method){if(Object.prototype.toString.call(path)==='[object String]')$.get(path,function(data){method(data);});else{var reader=new FileReader();reader.onload=function(e){method(e.target.result);};reader.fail=function(xhr,textStatus){console.log("failed",xhr,textStatus);};reader.readAsText(path);}}
