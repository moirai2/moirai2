//######################################## UTILITY ########################################
function Utility(){
	this.colors=colors=["#FE0000","#00FF01","#0000FE","#FFFF01","#FF00FE","#01FFFF","#800000","#008001","#010080","#818001","#81007F","#008081","#C0C0C0","#808080","#9A99FF","#993365","#FFFFCD","#CDFFFF","#660066","#FE8081","#0066CB","#CCCCFF","#0100D0","#FF00FE","#FFFF01","#01FFFF","#81007F","#800000","#008081","#0000FE","#00CCFF","#CDFFFF","#CDFFCC","#FEFF99","#99CDFF","#FF99CB","#CC99FE","#FFCC9A","#3366FF","#33CBCC","#99CC01","#FFCC00","#FE9900","#FF6600","#66669A","#969696","#003466","#339967","#013300","#333301","#993400","#993365","#343399","#333333","#000000","#FFFFFF"];
}
Utility.prototype.isObject=function(val){if(val===null){return false;}else return ((typeof val==='function')||(typeof val==='object'));}
Utility.prototype.readUrl=function(url,method){var self=this;$.post("moirai2.php?command=proxy",{url:url},function(data){method(data);});}
Utility.prototype.readJson=function(url,method){var self=this;$.post("moirai2.php?command=proxy",{url:url},function(data){method(data);},'json');}
Utility.prototype.readXML=function(url,method){var self=this;$.post("moirai2.php?command=proxy",{url:url},function(data){method(data);},'xml');}
Utility.prototype.isImageFile=function(path){return path.endsWith(".jpg")||path.endsWith(".jpeg")||path.endsWith(".png")||path.endsWith(".gif");}
Utility.prototype.directory=function(path){return path.substring(0,path.lastIndexOf('\/'));}
Utility.prototype.filename=function(path){return path.substring(path.lastIndexOf('\/')+1);}
Utility.prototype.basename=function(path){var filename=this.filename(path);var index=filename.indexOf('\.');return (index<0)?filename:filename.substring(0,index);}
Utility.prototype.dirname=function(path){if(path.endsWith("/")){path=path.substring(0,path.length-1);return path.substring(path.lastIndexOf('\/')+1);}var filename=this.filename(path);var index=filename.indexOf('\.');if(index<0)return filename;return "";}
Utility.prototype.filesuffix=function(path){var filename=this.filename(path);var index=filename.indexOf('\.');return (index<0)?"":filename.substring(index+1);}
Utility.prototype.basenames=function(path){if(Array.isArray(path)){var tmp=[];for(var i=0;i<path.length;i++){tmp.push(this.basenames(path[i]));}return tmp;}else{if(path.endsWith("/")){var directory=path.substring(0,path.length-1);var index=directory.lastIndexOf('\/');var dirname=(index<0)?directory:directory.substring(0,index);return {"path":path,"directory":directory,"dirname":dirname};}var index=path.lastIndexOf('\/');var directory=path.substring(0,index);var filename=path.substring(index+1);index=filename.lastIndexOf('\.');var basename=(index<0)?filename:filename.substring(0,index);var suffix=(index<0)?"":filename.substring(index+1);return {"filepath":path,"directory":directory,"filename":filename,"basename":basename,"filesuffix":suffix};}}
//######################################## ASSEMBLE ########################################
Utility.prototype.assembleText=function(template,hash,temporary){var self=this;if(typeof template==="function"){return template(hash,temporary);}else if(typeof template==="string"){if(template.includes("$")){var t=template.substring(1);if(t in hash)return hash[t];template=template.replace(new RegExp("\\$_","g"),temporary);var found;var regexp=/\$([\w_]+)/g;var temp=new Object();while((found=regexp.exec(template))!=null){var key=found[1];if(!(key in hash))continue;var val=(key in hash)?hash[key]:"";key="\\$"+key;if(key.match(/(\d+)/)&&Array.isArray(temporary)){var i=Number(key);val=(i<temporary.length)?temporary[i]:"";}temp[key]=val;}regexp=/\$\{([\.\w_]+)\}/g;while((found=regexp.exec(template))!=null){var key=found[1];var keys=found[1].split(".");var val=this.getHashKeys(hash,keys);if(key.match(/(\d+)/)&&Array.isArray(temporary)){var i=Number(key);val=(i<temporary.length)?temporary[i]:"";}}var keys=Object.keys(temp);keys.sort();for(var i=keys.length-1;i>=0;i--){var key=keys[i];var val=temp[key];template=template.replace(new RegExp(key,"g"),val);}return template}}return template}
//######################################## ARRAY HASH ########################################
Utility.prototype.getKeyFromTemplate=function(template){var hash={};var results=template.match(/\$([\w_]+)/g);for(var i=0;i<results.length;i++)hash[results[i].substr(1)]=1;results=template.match(/\$\{([\w_]+)\}/g);for(var i=0;i<results.length;i++)hash[results[i].substr(2,results[i].length-3)]=1;return Object.keys(hash);}
Utility.prototype.hashArrayToArrayHash=function(hashtable){var array=[];var keys=Object.keys(hashtable);var size=0;for(var i=0;i<keys.length;i++){var k=keys[i];var s=(Array.isArray(hashtable[k]))?hashtable[k].length:1;if(size<s)size=s;}for(var i=0;i<size;i++){var hash={};for(var j=0;j<keys.length;j++){var k=keys[j];var value=hashtable[k];if(Array.isArray(value)){var l=value.length;if(i<l)hash[k]=value[i];else hash[k]=value[l-1];}else{hash[k]=value;}}array.push(hash);}return array;}
//######################################## COMPUTATION ########################################
Utility.prototype.sum=function(object){if(Array.isArray(object)){var total=0;object.forEach(function(o){total+=Number(o);});return total;}else if(this.isObject(object)){var total=0;for(var key in object){total+=Number(object[key]);};return total;}else return object;}
//######################################## DATE ########################################
Utility.prototype.handleDate=function(date){var hash={};hash["year"]=""+date.getFullYear();hash["month"]=('0'+(date.getMonth()+1)).slice(-2);hash["day"]=('0'+date.getDate()).slice(-2);hash["hour"]=('0'+date.getHours()).slice(-2);hash["minute"]=('0'+date.getMinutes()).slice(-2);hash["second"]=('0'+date.getSeconds()).slice(-2);hash["time"]=date.getTime();return hash;}
Utility.prototype.formatDate=function(date,format){
	var hash={};
	hash["yyyy"]=date.getFullYear();
	hash["MM"]=('0'+(date.getMonth()+1)).slice(-2);
	hash["dd"]=('0'+date.getDate()).slice(-2);
	hash["hh"]=('0'+date.getHours()).slice(-2);
	hash["mm"]=('0'+date.getMinutes()).slice(-2);
	hash["ss"]=('0'+date.getSeconds()).slice(-2);
	var p=["yyyy","MM","dd","hh","mm","ss"];
	for(var i=0;i<p.length;i++)format=format.replace(new RegExp(p[i],'g'),hash[p[i]]);
	return format;
}
//######################################## DIRECTORY ########################################
Utility.prototype.listDirectory=function(hash,method){var post=$.ajax({type:'POST',dataType:'json',url:"moirai2.php?command=ls",data:hash});post.fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});post.success(function(data){method(data);});return this;}
//######################################## EXPRESSION ########################################
Utility.prototype.handleExpression=function(expression){var hash={};expression=expression.replace(new RegExp("\\\\\\$","g"),"");var exp1=new RegExp("\\$([\\w_]+)");while((found=expression.match(exp1))!=null){var key=found[1];expression=expression.replace(exp1,"");hash[key]=1;}var exp2=new RegExp("\\$\{([~}]+)\}");while((found=expression.match(exp2))!=null){var key=found[1];hash[key]=1;expression=expression.replace(exp2,"");}return Object.keys(hash);}
//######################################## FILE ########################################
Utility.prototype.readImage=function(path,method){if(Object.prototype.toString.call(path)==='[object String]'){var image=new Image();image.onload=function(){method(image);};image.src=path;}else{var reader=new FileReader();reader.onload=function(e){var image=new Image();image.onload=function(){method(image);};image.src=e.target.result;};reader.fail=function(xhr,textStatus){console.log("failed",xhr,textStatus);};reader.readAsDataURL(path);}}
Utility.prototype.readFile=function(path,method){if(Object.prototype.toString.call(path)==='[object String]')$.get(path,function(data){method(data);});else{var reader=new FileReader();reader.onload=function(e){method(e.target.result);};reader.fail=function(xhr,textStatus){console.log("failed",xhr,textStatus);};reader.readAsText(path);}}
Utility.prototype.readRDF=function(path,method){var self=this;if(Object.prototype.toString.call(path)==='[object String]')$.get(path,function(data){method(self.textToRDF(data));});else{var reader=new FileReader();reader.onload=function(e){method(self.textToRDF(e.target.result));};reader.fail=function(xhr,textStatus){console.log("failed",xhr,textStatus);};reader.readAsText(path);}}
Utility.prototype.textToRDF=function(text){
	var lines=text.split(/\r?\n/);
	var rdf={};
	for(var i=0;i<lines.length;i++){
		var line=lines[i];
		var tokens=line.split(/\t/);
		if(tokens.length!=3)continue;
		var s=tokens[0];
		var p=tokens[1];
		var o=tokens[2];
		if(!(s in rdf))rdf[s]={};
		if(!(p in rdf[s]))rdf[s][p]=o;
		else if(Array.isArray(rdf[s][p]))rdf[s][p].push(o);
		else rdf[s][p]=[rdf[s][p],o];
	}
	return rdf;
}
Utility.prototype.uploadXML=function(xml,filename,method){var self=this;var file=new Blob([xml],{type:'text/xml'});file.name=filename;return this.uploadFile(file,method);}
Utility.prototype.uploadText=function(text,method){var self=this;var file=new Blob([text],{type:'text/plain'});file.name="text.txt";return this.uploadFile(file,method);}
Utility.prototype.uploadFile=function(file,method){var self=this;var fd=new FormData();fd.append("file",file,file.name);var post=$.ajax({type:'POST',contentType:false,processData:false,url:"moirai2.php?command=upload",data:fd,dataType:"text"}).fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});if(method!=null)post.success(function(path){method(path);});}
Utility.prototype.downloadFile=function(url,method){var self=this;var post=$.ajax({type:'POST',url:"moirai2.php?command=download",data:(typeof url==='object')?url:{'url':url}}).fail(function(xhr,data){console.log("failed",xhr,data);});if(method!=null)post.success(function(path){method(path);});}
Utility.prototype.symlinkFile=function(url,method){var self=this;var post=$.ajax({type:'POST',url:"moirai2.php?command=symlink",data:(typeof url==='object')?url:{'url':url}}).fail(function(xhr,data){console.log("failed",xhr,data);});if(method!=null)post.success(function(path){method(path);});}
Utility.prototype.fileExists=function(path,method){var self=this;var post=$.ajax({type:'POST',url:"moirai2.php?command=file_exists",data:{'path':path}}).fail(function(xhr,data){console.log("failed",xhr,data);});if(method!=null)post.success(function(path){method(path);});}
Utility.prototype.writeFile=function(filepath,content,method){var self=this;var post=$.ajax({type:'POST',url:"moirai2.php?command=write",data:{"filepath":filepath,"content":content}}).fail(function(xhr,data){console.log("failed",xhr,data);});if(method!=null)post.success(function(path){method(path);});}
//######################################## HASH ########################################
Utility.prototype.getHash=function(hash,key){if(key in hash)return hash[key];var rows=Object.keys(hash);var temp={};for(var i=0;i<rows.length;i++)if(key in hash[rows[i]])temp[rows[i]]=hash[rows[i]][key];return temp;}
Utility.prototype.putHash=function(hash,key,value){if(Array.isArray(key)){var temp=hash;for(var i=0;i<key.length-1;i++){if(temp[key[i]]==null)temp[key[i]]={};temp=temp[key[i]];}temp[key[key.length-1]]=value;}else hash[key]=value;return hash;}
//######################################## HTML ########################################
Utility.prototype.toSelect=function(value,method){var select=$("<select>");if(Array.isArray(value)){select.prop("size",value.length);for(var i=0;i<value.length;i++){var option=$("<option>").text(value[i]);select.append(option);}}else{var option=$("<option>").text(value);select.append(option);}if(method!=null)select.on("change",function(e){var $value=$(e.target).val();method($value);});return select;}
Utility.prototype.toPopup=function(content,label,x,y){var self=this;var div=$("<div>").css("z-index",1).css("position","absolute");if(x!=null&&y!=null)div.css({"top":y+"px","left":x+"px"});div.css("margin","0px").css("padding","0px");div.css("border","1px solid black").css("background-color","white");if(label!=null)div.append($("<div align=center>"+label+"</div>"));if(Array.isArray(content)){for(var i=0;i<content.length;i++)div.append(content[i]);}else{div.append(content);}return div;}
Utility.prototype.searchParentNode=function(target,parent){var tmp=target;while(tmp!=null){if(tmp==parent)return true;else tmp=tmp.parentNode;}return false;}
Utility.prototype.searchClassRecursively=function(target,className){var tmp=target;while(tmp!=null){if($(tmp).hasClass(className))return tmp;else tmp=tmp.parentNode;}return null;}
Utility.prototype.escapeCodeForHTML=function(text){text=text.replace(/</g,"&lt;");text=text.replace(/>/g,"&gt;");text=text.replace(/\n/g,"<BR>");text=text.replace(/\t/g," ");return text;}
Utility.prototype.jsonEscape=function(string){if(string==null)return;return string.replace(/\n/g,"\\n").replace(/\r/g,"\\r").replace(/\t/g,"\\t").replace(/\"/g,"\\\"");}
//######################################## NCBI ########################################
Utility.prototype.appendHash=function(hashtable,name,object){if(!(name in hashtable))hashtable[name]=object;else if(Array.isArray(hashtable[name]))hashtable[name].push(object);else hashtable[name]=[hashtable[name],object];return hashtable;}
Utility.prototype.xmlToHash=function(xml){var self=this;var hashtable={};$(xml).each(function(index){var hash={};var name=this.tagName;if(name==null)name="#document";hashtable[name]=hash;var attrs=this.attributes;if(attrs!=null&&attrs.length>0)for(var i=0;i<attrs.length;i++)self.appendHash(hash,attrs[i].name,attrs[i].value);if(this.children!=null&&this.children.length>0){for(var i=0;i<this.children.length;i++){var result=self.xmlToHash(this.children[i]);Object.keys(result).forEach(function(key){self.appendHash(hash,key,result[key]);});}}else{var text=$(this).text();if(text!=null&&text!=""){if(Object.keys(hash).length==0)hashtable[name]=text;else hash["#text"]=text;}}});return hashtable;}
//######################################## TABLE ########################################
Utility.prototype.tsvToArrayHash=function(text){
	if(!Array.isArray(text))text=[text];
	var array=[];
	for(var i=0;i<text.length;i++){
		var line=text[i];
		var lines=line.split(/\n/);
		var columns=lines.shift().split(/\t/);
		for(var i=0;i<lines.length;i++){if(lines[i]=="")continue;
		var tokens=lines[i].split(/\t/);
		var hashtable={};
		for(var j=0;j<tokens.length;j++)hashtable[columns[j]]=tokens[j];
		array.push(hashtable);}
	}
	return array;
}
Utility.prototype.keyValueToHash=function(text){var hashtable={};var lines=text.split(/\n/);for(var i=0;i<lines.length;i++){if(lines[i]=="")continue;var tokens=lines[i].split(/\t/);hashtable[tokens[0]]=tokens[1];}return hashtable;}
Utility.prototype.tabToHash=function(text){var hashtable={};var lines=text.split(/\n/);for(var i=0;i<lines.length;i++){if(lines[i]=="")continue;var tokens=lines[i].split(/\t/);if(!(tokens[0] in hashtable))hashtable[tokens[0]]={};hashtable[tokens[0]][tokens[1]]=tokens[2];}return hashtable;}
Utility.prototype.hashToTab=function(hashtable){var rows=Object.keys(hashtable);var temp={};rows.forEach(function(row){Object.keys(hashtable[row]).forEach(function(column){temp[column]=1;});});var columns=Object.keys(temp);var returnText="";for(var i=0;i<rows.length;i++){var row=rows[i];for(var j=0;j<columns.length;j++){var column=columns[j];returnText+=row+"\t"+column+"\t"+hashtable[row][column]+"\n";}}return returnText;}
Utility.prototype.hashToTable=function(hashtable){var rows=Object.keys(hashtable);var temp={};rows.forEach(function(row){Object.keys(hashtable[row]).forEach(function(column){temp[column]=1;});});var columns=Object.keys(temp);var returnText="";for(var i=0;i<columns.length;i++)returnText+="\t"+columns[i];returnText+="\n";for(var i=0;i<rows.length;i++){var row=rows[i];returnText+=row;for(var j=0;j<columns.length;j++){var column=columns[j];returnText+="\t"+hashtable[row][column];}returnText+="\n";}return returnText;}
Utility.prototype.dataToHTMLTable=function(data){var self=this;var temp={};for(var i=0;i<data.length;i++){var rows=Object.keys(data[i]);for(var j=0;j<rows.length;j++){temp[rows[j]]++;}}var rows=Object.keys(temp).sort();var table=$("<table/>");var thead=$("<thead/>");table.append(thead);var tr=$("<tr/>");tr.append($("<th></th>"));for(var i=0;i<rows.length;i++){var th=$("<th/>");th.text(rows[i]);tr.append(th);}thead.append(tr);var tbody=$("<tbody/>");for(var i=0;i<data.length;i++){var tr=$("<tr/>");var row=data[i];tr.append($("<th>"+i+"</th>"));for(var j=0;j<rows.length;j++){var td=$("<td/>");var text=row[rows[j]];td.text(text);tr.append(td);}tbody.append(tr);}table.append(tbody);return table;}
Utility.prototype.rdfToHTMLTable=function(rdf){if(rdf==null)return null;var rows=Object.keys(rdf);var temp={};rows.forEach(function(row){Object.keys(rdf[row]).forEach(function(column){temp[column]=1;});});var columns=Object.keys(temp);var html=$("<table/>");var thead=$("<thead/>").append($("<tr/>").append($("<th>").text("subject")).append($("<th>").text("predicate")).append($("<th>").text("object")));html.append(thead);var tbody=$("<tbody/>");html.append(tbody);var subjects=Object.keys(rdf);for(var i=0;i<subjects.length;i++){var subject=subjects[i];var predicates=Object.keys(rdf[subject]);for(var j=0;j<predicates.length;j++){var predicate=predicates[j];var object=rdf[subject][predicate];if(Array.isArray(object))for(var k=0;k<object.length;k++)tbody.append($("<tr/>").append($("<td/>").text(subject)).append($("<td/>").text(predicate)).append($("<td/>").text(object[k])));else tbody.append($("<tr/>").append($("<td/>").text(subject)).append($("<td/>").text(predicate)).append($("<td/>").text(object)));}}return html;}
Utility.prototype.hashToChartJs=function(hashtable){var rows=Object.keys(hashtable);var temp={};rows.forEach(function(row){Object.keys(hashtable[row]).forEach(function(column){temp[column]=1;});});var columns=Object.keys(temp);var canvas=document.createElement("canvas");var ctx=canvas.getContext("2d");var datasets=[];for(var i=0;i<rows.length;i++){var row=rows[i];var dataset={};dataset.label=row;dataset.lineTension=0;dataset.backgroundColor=this.colors[i];dataset.fill=false;datasets.push(dataset);var array=[];for(var j=0;j<columns.length;j++){var column=columns[j];var value=hashtable[row][column];array.push(value);}dataset.data=array;}var config={type:'line',data:{labels:columns,datasets:datasets}};new Chart(ctx,config);return canvas;}
Utility.prototype.mergeHash=function(hashtable,hashtable2){for(var key in hashtable2){var value=hashtable2[key];if(this.isObject(value)){if(!this.isObject(hashtable[key]))hashtable[key]={};this.mergeHash(hashtable[key],value);}else hashtable[key]=value;}return hashtable;}
Utility.prototype.mergeKeyValue=function(hashtable,key2,hashtable2){for(var key in hashtable2){var value=hashtable2[key];if(!this.isObject(hashtable[key]))hashtable[key]={};hashtable[key][key2]=value;}return hashtable;}
//######################################## STRING ########################################
Utility.prototype.getHashKeys=function(hash,keys){return this.getHashKeysSub(hash,keys,0);}
Utility.prototype.getHashKeysSub=function(hash,keys,index){var key=keys[index];if(Array.isArray(hash)){var array=[];for(var i=0;i<hash.length;i++){var value=this.getHashKeysSub(hash[i],keys,index);if(Array.isArray(value))for(var j=0;j<value.length;j++)array.push(value[j]);else if(value!=null)array.push(value);}if(array.length==0)return null;else if(array.length==1)return array[0];else return array;}else if(this.isObject(hash)){hash=hash[key];if(hash==null)return;if(index+1<keys.length)return this.getHashKeysSub(hash,keys,index+1);else return hash;}else{return null;}}
//######################################## URL ########################################
Utility.prototype.handleURL=function(url){var hash={};var index=url.indexOf('#');if(index>-1){hash["fragment"]=url.substr(index+1);url=url.substr(0,index);}index=url.indexOf('?');if(index>-1){var hash2={};var query=url.substr(index+1);url=url.substr(0,index);var array=query.split("&");for(var i=0;i<array.length;i++){var array2=array[i].split("=");hash2[array2[0]]=array2[1];}hash["query"]=hash2;}hash["urladdress"]=url;var exp=new RegExp("^(\\w+)://([^/]+)/(.+)$");var result=exp.exec(url);hash["urlprotocol"]=result[1];hash["urldomain"]=result[2];var urlpath=result[3];hash["urlpath"]=urlpath;index=urlpath.indexOf('.');if(index>-1){index=urlpath.lastIndexOf('/');var urldir=urlpath.substr(0,index);var urlfile=urlpath.substr(index+1);hash["urldirectory"]=urldir;hash["urlfile"]=urlfile;index=urlfile.indexOf('.');hash["urlbasename"]=urlfile.substr(0,index);hash["urlsuffix"]=urlfile.substr(index+1);}else{hash["urldir"]=urlpath;}return hash;}
