function CreatePops(){
	this.font="px 'ＭＳ ゴシック'";// dice this.font
	this.fillColor="#EEEEEE"// dice color
	this.pixelPerCm=236;//600dpi
	this.pixelPerMm=this.pixelPerCm/10;//23.6
	this.pageWidth=4960;//210mm 600dpi
	this.pageHeight=7016;//297mm 600dpi
	this.cardWidth=50*this.pixelPerMm;//50mm
	this.cardHeight=80*this.pixelPerMm;//80mm;
	this.popBottom=20*this.pixelPerMm;//20mm
	this.canvas=document.createElement("canvas");//this.canvas
	this.ctx=this.canvas.getContext("2d");//context
	this.bounds=[];
	this.datas=[];
	this.images=[];
	this.initialize();
}
CreatePops.prototype.addData=function(data){this.datas.push(data);return this;}
CreatePops.prototype.addBound=function(bound){this.bounds.push(bound);return this;}
CreatePops.prototype.clearBounds=function(){this.bounds=[];return this;}
CreatePops.prototype.setPageSize=function(width,height){this.pageWidth=this.pixelPerMm*width;this.pageHeight=this.pixelPerMm*height;this.initialize();return this;}
CreatePops.prototype.setCardSize=function(width,height){this.cardWidth=width*this.pixelPerMm;this.cardHeight=height*this.pixelPerMm;this.initialize();return this;}
CreatePops.prototype.setPopBottom=function(bottom){this.popBottom=bottom*this.pixelPerMm;this.initialize();return this;}
CreatePops.prototype.loadImage=function(path){
	this.images[path]=document.createElement("img");
	$(this.images[path]).attr("src",path);
	return this;
}
CreatePops.prototype.drawCard=function(data){
	this.drawBounds();
	this.drawBottom();
	for(var i=0;i<this.bounds.length;i++){
		this.ctx.save();
		var bound=this.bounds[i];
		if('type' in bound){
			if(bound.type=='text')this.printStringBold(this.ctx,bound,data[bound.name]);
			else if(bound.type=='textarea')this.printTextarea(this.ctx,bound,data[bound.name]);
			else if(bound.type=='image')this.printImage(this.ctx,bound,this.images[data[bound.name]]);
		}else{
			this.ctx.beginPath();
			this.ctx.rect(bound.x,bound.y,bound.width,bound.height);
			this.ctx.stroke();
		}
		this.ctx.restore();
	}
	return this;
}
CreatePops.prototype.drawBottom=function(){
	this.ctx.save();
	this.ctx.beginPath();
	this.ctx.rect(0,this.cardHeight,this.cardWidth,this.popBottom);
	this.ctx.fillStyle="#EEEEEE";
	this.ctx.fill();
	this.ctx.strokeStyle="black";
	this.ctx.stroke();
	this.ctx.restore();
}
CreatePops.prototype.drawBounds=function(){
	this.ctx.save();
	for(var i=0;i<this.bounds.length;i++){
		var bound=this.bounds[i];
		this.ctx.beginPath();
		this.ctx.rect(bound.x,bound.y,bound.width,bound.height);
		if('fillStyle' in bound){
			this.ctx.fillStyle=bound.fillStyle;
			this.ctx.fill();
		}
		if('strokeStyle' in bound){
			this.ctx.strokeStyle=bound.strokeStyle;
			this.ctx.stroke();
		}
	}
	this.ctx.restore();
}
CreatePops.prototype.initialize=function(){
	this.canvas.width=this.pageWidth;//set this.canvas width
	this.canvas.height=this.pageHeight;//set this.canvas height
	this.popWidth=this.cardWidth;
	this.popHeight=2*(this.cardHeight+this.popBottom);
	this.popRowSize=Math.floor(this.pageHeight/this.popHeight);
	this.popColumnSize=Math.floor(this.pageWidth/this.popWidth);
	this.number=this.popRowSize*this.popColumnSize;// number of dices created
	var row=Math.floor(this.pageHeight/this.popWidth);
	var column=Math.floor(this.pageWidth/this.popHeight);
	var number=row*column;
	if(number>this.number){
		this.number=number;
		this.popRowSize=row;
		this.popColumnSize=column;
		this.horizontal=true;
	}else{
		this.horizontal=false;
	}
	this.popPositionXs=new Array();
	this.popPositionYs=new Array();
	if(this.horizontal){
		this.marginX=(this.pageWidth-this.popColumnSize*this.popHeight)/2+this.popBottom+this.cardHeight;
		this.marginY=(this.pageHeight-this.popRowSize*this.popWidth)/2+this.popWidth/2;
		for(var i=0;i<this.popRowSize;i++){
			for(var j=0;j<this.popColumnSize;j++){
				this.popPositionXs.push(Math.floor(this.marginX+j*this.popHeight));
				this.popPositionYs.push(Math.floor(this.marginY+i*this.popWidth));
			}
		}
	}else{
		this.marginX=(this.pageWidth-this.popColumnSize*this.popWidth)/2+this.popWidth/2;
		this.marginY=(this.pageHeight-this.popRowSize*this.popHeight)/2+this.popBottom+this.cardHeight;
		for(var i=0;i<this.popRowSize;i++){
			for(var j=0;j<this.popColumnSize;j++){
				this.popPositionXs.push(Math.floor(this.marginX+j*this.popWidth));
				this.popPositionYs.push(Math.floor(this.marginY+i*this.popHeight));
			}
		}
	}
	return this;
}
CreatePops.prototype.printStringBold=function(ctx,bound,text){
	var x=bound.x;
	var y=bound.y;
	var w=bound.width;
	var h=bound.height;
	ctx.save();
	ctx.translate(x,y);
	if('rotate' in bound){
		ctx.rotate(Math.PI/180*bound.rotate);
		if(bound.rotate==90){
			w=bound.height;
			h=bound.width;
		}else if(bound.rotate==180){
			ctx.translate(-bound.width,0);
		}else if(bound.rotate==-90){
			w=bound.height;
			h=bound.width;
			ctx.translate(-w,h);
		}else{
			ctx.translate(0,bound.height);
		}
	}else{
		ctx.translate(0,bound.height);
	}
	ctx.translate(0,h);
	var size=4;
	ctx.lineWidth=16;//8
	ctx.font="bold "+size+this.font;
	var tmx=ctx.measureText(text);
	var width;
	for(var s=size;tmx.width<0.9*w&&s<h;s++){size=s;width=tmx.width;ctx.font=s+this.font;tmx=ctx.measureText(text);}
	ctx.font="bold "+size+this.font;
	if('strokeStyle' in bound)this.ctx.strokeStyle=bound.strokeStyle;
	if('fillStyle' in bound)this.ctx.fillStyle=bound.fillStyle;
	if('center' in bound){ctx.translate((w-width)/2,0);}
	ctx.strokeText(text,0,0);
	ctx.fillText(text,0,0);
	ctx.restore();
}
CreatePops.prototype.printImage=function(ctx,bound,image){
	var dx=image.width/bound.width;
	var dy=image.height/bound.height;
	var width=image.width/dy;
	var height=image.height/dx;
	var location={};
	if(height<=bound.height){
		width=bound.width;
		location.width=width;
		location.height=height;
		location.x=bound.x;
		location.y=bound.y+(bound.height-location.height)/2;
	}else if(width<=bound.width){
		height=bound.height;
		location.width=width;
		location.height=height;
		location.y=bound.y;
		location.x=bound.x+(bound.width-location.width)/2;
	}
	ctx.drawImage(image,location.x,location.y,location.width,location.height);
}
CreatePops.prototype.printTextarea=function(ctx,bound,text){
	if(text=="")return;
	ctx.lineWidth=4;
	ctx.save();
	ctx.fillStyle="black";
	ctx.strokeStyle="white";
	var h=10;
	var ascent_ratio=0.8;
	ctx.font=h+this.font;
	var text_width_per_height=ctx.measureText(text).width/h;
	var bound_width_per_height=bound.width/bound.height;
	var number=Math.ceil(Math.sqrt(text_width_per_height/bound_width_per_height));
	h=Math.floor(bound.height/number);
	ctx.font=h+this.font;
	// double check with actual font height
	while(ctx.measureText(text).width/bound.width>number){
		number++;
		h=bound.height/number;
		ctx.font=Math.floor(h+font);
	}
	var array=this.splitByWidth(ctx,bound.width,text,h,number);
	while(array.length>number){
		array=this.splitByWidth(ctx,bound.width,text,h--,number);
	}
	var max_width=0;
	for(var i=0;i<array.length;i++){
		var width=ctx.measureText(array[i]).width;
		if(width>max_width)max_width=width;
	}
	var dx=(bound.width-max_width)/2;
	if(dx<0)dx=0;
	for(var i=0;i<array.length;i++){
		ctx.strokeText(array[i],bound.x+dx,bound.y+(i+ascent_ratio)*h);
		ctx.fillText(array[i],bound.x+dx,bound.y+(i+ascent_ratio)*h);
	}
	ctx.restore();
	return this;
}
CreatePops.prototype.splitByWidth=function(ctx,width,text,h,number){
	ctx.font=h+this.font;
	var array=new Array();
	if(text.length==1)return new Array(text);
	var original=text;
	var average=Math.floor(text.length/number);
	var extra_char="　";
	while(text.length>0){
		var splitIndex=average;
		var length=ctx.measureText(text.substr(0,splitIndex)+extra_char).width;
		if(length>=width){
			for(splitIndex--;length>=width;splitIndex--){
				length=ctx.measureText(text.substr(0,splitIndex)+extra_char).width;
				if(length<width)break;
			}
		}else{
			for(;length<width;splitIndex++){
				if(splitIndex>=text.length){splitIndex=text.length+1;break;}
				length=ctx.measureText(text.substr(0,splitIndex)+extra_char).width;
			}
			splitIndex--;
		}
		var c=text.charCodeAt(splitIndex);
		if(c==12290||c==12289)splitIndex++;
		array.push(text.substr(0,splitIndex));
		text=text.substr(splitIndex);
	}
	return array;
}
CreatePops.prototype.create=function(){
	this.ctx.fillStyle="white";
	this.ctx.fillRect(0,0,this.pageWidth,this.pageHeight);
	var i=0;
	for(var index=0;index<this.datas.length;index++,i++){
		if(i==this.popPositionXs.length){
			var png=this.canvas.toDataURL('image/png');
			var image=document.createElement("img");
			image.src=png;
			image.width=200;
			image.height=300;
			$("#main").append(image);
			this.ctx.fillStyle="white";
			this.ctx.fillRect(0,0,this.pageWidth,this.pageHeight);
			i=0;
		}
		this.ctx.save();
		this.ctx.translate(this.popPositionXs[i],this.popPositionYs[i]);
		if(this.horizontal)this.ctx.rotate(-Math.PI/2);
		this.ctx.translate(-this.popWidth/2,0);
		this.drawCard(this.datas[index]);
		this.ctx.rotate(Math.PI);
		this.ctx.translate(-this.popWidth,0);
		this.drawCard(this.datas[index]);
		this.ctx.restore();
	}
	if(i>0){
		var png=this.canvas.toDataURL('image/png');
		var image=document.createElement("img");
		image.src=png;
		image.width=200;
		image.height=300;
		$("#main").append(image);
	}
	return this;
}
