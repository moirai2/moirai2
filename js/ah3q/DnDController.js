function DnDController(id){
	var self=this;
	this.id=id;
	if(typeof Utility!='undefined')this.utility=new Utility();
	if(document.readyState=="loading")$(document).ready(function(){self.initialize();});
	else this.initialize();
}
DnDController.prototype.initialize=function(){
	var self=this;
	this.dom=document.getElementById(this.id);
	this.dom.addEventListener("dragenter",function(event){event.stopPropagation();event.preventDefault();},true);
	this.dom.addEventListener("dragover",function(event){event.stopPropagation();event.preventDefault();},true);
	this.dom.addEventListener("drop",function(event){event.stopPropagation();event.preventDefault();self.dropped(event);},true);
}
DnDController.prototype.appendChild=function(element){this.dom.appendChild(element);}
DnDController.prototype.whenFileIsDroppedRead=function(boolean){if(boolean==null)boolean=true;this.readFromFile=boolean;return this;}
DnDController.prototype.whenUrlIsDroppedRead=function(boolean){if(boolean==null)boolean=true;this.readFromUrl=boolean;return this;}
DnDController.prototype.whenUrlIsDroppedSave=function(boolean){if(boolean==null)boolean=true;this.saveFromUrl=boolean;return this;}
DnDController.prototype.whenFileIsDroppedSave=function(boolean){if(boolean==null)boolean=true;this.saveFromFile=boolean;return this;}
DnDController.prototype.whenFileIsDroppedGetFilename=function(boolean){if(boolean==null)boolean=true;this.getFilenameFromFile=boolean;return this;}
DnDController.prototype.whenUrlIsDroppedGetFilename=function(boolean){if(boolean==null)boolean=true;this.getFilenameFromUrl=boolean;return this;}
DnDController.prototype.addEventListener=function(type,listener,useCapture,wantsUntrusted){this.dom.addEventListener(type,listener,useCapture,wantsUntrusted);}
DnDController.prototype.dropped=function(event){
	var self=this;
	var rectangle=this.dom.getBoundingClientRect();
	var x=event.clientX-rectangle.left;
	var y=event.clientY-rectangle.top;
	var dataTransfer=event.dataTransfer;
	var text=dataTransfer.getData("text");
	if(text!==""){
		if(!text.match(/\n/)&&text.startsWith("http://")||text.startsWith("https://")){
			var url=text;
			var filename=this.utility.filename(text);
			if(this.readFromUrl){
				if(this.utility.isImageFile(text))this.utility.readImage(text,function(image){self.dom.dispatchEvent(new CustomEvent("imageWasRead",{detail:{x:x,y:y,image:image,url:url,filename:filename}}));});
				else this.utility.readUrl(text,function(text){self.dom.dispatchEvent(new CustomEvent("textWasRead",{detail:{x:x,y:y,text:text,url:url,filename:filename}}));});
			}else if(this.saveFromUrl){
				this.utility.downloadFile(text,function(path){self.dom.dispatchEvent(new CustomEvent("fileWasSaved",{detail:{x:x,y:y,url:url,path:path,filename:filename}}));});
			}else if(this.getFilenameFromUrl){
				this.dom.dispatchEvent(new CustomEvent("fileNameWasDropped",{detail:{x:x,y:y,url:url,filename:filename}}));
			}else{
				this.dom.dispatchEvent(new CustomEvent("urlWasDropped",{detail:{x:x,y:y,url:url}}));
			}
		}else{
			this.dom.dispatchEvent(new CustomEvent("textWasDropped",{detail:{x:x,y:y,text:text}}));
		}
	}else{
		for(var i=0;i<dataTransfer.files.length;i++){
			var file=dataTransfer.files[i];
			var filename=this.utility.filename(file.name);
			if(this.readFromFile){
				if(this.utility.isImageFile(file.name))this.utility.readImage(file,function(image){self.dom.dispatchEvent(new CustomEvent("imageWasRead",{detail:{x:x,y:y,image:image,filename:filename}}));});
				else this.utility.readFile(file,function(text){self.dom.dispatchEvent(new CustomEvent("textWasRead",{detail:{x:x,y:y,text:text,filename:filename}}));});
			}else if(this.saveFromFile){
				this.utility.uploadFile(file,function(path){self.dom.dispatchEvent(new CustomEvent("fileWasSaved",{detail:{x:x,y:y,path:path,filename:filename}}));});
			}else if(this.getFilenameFromFile){
				this.dom.dispatchEvent(new CustomEvent("fileNameWasDropped",{detail:{x:x,y:y,filename:filename}}));
			}else{
				if(this.utility.isImageFile(file.name))this.dom.dispatchEvent(new CustomEvent("imageWasDropped",{detail:{x:x,y:y,file:file}}));
				else this.dom.dispatchEvent(new CustomEvent("fileWasDropped",{detail:{x:x,y:y,file:file}}));
			}
		}
	}
}
