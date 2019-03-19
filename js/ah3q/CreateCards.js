function CreateCards(){
	this.font="px 'ＭＳ ゴシック'";// dice this.font
	this.fillColor="#EEEEEE"// dice color
	this.pixelPerCm=236;//600dpi
	this.pixelPerMm=this.pixelPerCm/10;//23.6
	this.pageWidth=4960;//210mm 600dpi
	this.pageHeight=7016;//297mm 600dpi
	this.cardWidth=55*this.pixelPerMm;//55mm;
	this.cardHeight=91*this.pixelPerMm;//91mm;
	this.canvas=document.createElement("canvas");//this.canvas
	this.ctx=this.canvas.getContext("2d");//context
	this.bounds=[];
	this.datas=[];
	this.images=[];
	this.initialize();//initialize
}
CreateCards.prototype.addData=function(data){this.datas.push(data);return this;}
CreateCards.prototype.addBound=function(bound){this.bounds.push(bound);return this;}
CreateCards.prototype.clearBounds=function(){this.bounds=[];return this;}
CreateCards.prototype.setPageSize=function(width,height){this.pageWidth=this.pixelPerMm*width;this.pageHeight=this.pixelPerMm*height;this.initialize();return this;}
CreateCards.prototype.setCardSize=function(width,height){this.cardWidth=width*this.pixelPerMm;this.cardHeight=height*this.pixelPerMm;this.initialize();return this;}
CreateCards.prototype.loadImage=function(path){
	this.images[path]=document.createElement("img");
	$(this.images[path]).attr("src",path);
	return this;
}
CreateCards.prototype.drawCard=function(data){
	for(var i=0;i<this.bounds.length;i++){
		this.ctx.save();
		var bound=this.bounds[i];
		if('type' in bound){
			if(bound.type=='text')this.printText(this.ctx,bound,data[bound.name]);
			else if(bound.type=='textarea')this.printTextarea(this.ctx,bound,data[bound.name]);
			else if(bound.type=='image')this.printImage(this.ctx,bound,this.images[data[bound.name]]);
			else if(bound.type=='pie')this.printPie(this.ctx,bound,data[bound.name]);
		}else this.drawBound(this.ctx,bound);
		this.ctx.restore();
	}
	return this;
}
CreateCards.prototype.drawBound=function(ctx,bound){
	ctx.save();
	if('lineDash' in bound)ctx.setLineDash(bound.lineDash);
	if('lineWidth' in bound)ctx.lineWidth=bound.lineWidth;
	if('strokeStyle' in bound)this.ctx.strokeStyle=bound.strokeStyle;
	if('fillStyle' in bound)this.ctx.fillStyle=bound.fillStyle;
	ctx.beginPath();
	ctx.rect(bound.x,bound.y,bound.width,bound.height);
	this.ctx.fill();
	this.ctx.stroke();
	ctx.restore();
}
CreateCards.prototype.initialize=function(){
	this.canvas.width=this.pageWidth;//set this.canvas width
	this.canvas.height=this.pageHeight;//set this.canvas height
	this.cardRowSize=Math.floor(this.pageHeight/this.cardHeight);
	this.cardColumnSize=Math.floor(this.pageWidth/this.cardWidth);
	this.number=this.cardRowSize*this.cardColumnSize;// number of dices created
	var row=Math.floor(this.pageHeight/this.cardWidth);
	var column=Math.floor(this.pageWidth/this.cardHeight);
	var number=row*column;
	if(number>this.number){
		this.number=number;
		this.cardRowSize=row;
		this.cardColumnSize=column;
		this.horizontal=true;
	}else{
		this.horizontal=false;
	}
	this.card_positionXs=new Array();
	this.card_positionYs=new Array();
	if(this.horizontal){
		this.marginX=(this.pageWidth-this.cardColumnSize*this.cardHeight)/2;
		this.marginY=(this.pageHeight-this.cardRowSize*this.cardWidth)/2+this.cardWidth;
		for(var i=0;i<this.cardRowSize;i++){
			for(var j=0;j<this.cardColumnSize;j++){
				this.card_positionXs.push(Math.floor(this.marginX+j*this.cardHeight));
				this.card_positionYs.push(Math.floor(this.marginY+i*this.cardWidth));
			}
		}
	}else{
		this.marginX=(this.pageWidth-this.cardColumnSize*this.cardWidth)/2;
		this.marginY=(this.pageHeight-this.cardRowSize*this.cardHeight)/2;
		for(var i=0;i<this.cardRowSize;i++){
			for(var j=0;j<this.cardColumnSize;j++){
				this.card_positionXs.push(Math.floor(this.marginX+j*this.cardWidth));
				this.card_positionYs.push(Math.floor(this.marginY+i*this.cardHeight));
			}
		}
	}
	return this;
}
CreateCards.prototype.printText=function(ctx,bound,text){
	var x=bound.x;
	var y=bound.y;
	var w=bound.width;
	var h=bound.height;
	ctx.save();
	if('lineWidth' in bound)ctx.lineWidth=bound.lineWidth;
	if('strokeStyle' in bound)this.ctx.strokeStyle=bound.strokeStyle;
	if('fillStyle' in bound)this.ctx.fillStyle=bound.fillStyle;
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
	ctx.translate(0,-0.1*h);
	var size=4;
	ctx.font=(('bold' in bound)?"bold ":"")+size+this.font;
	var tmx=ctx.measureText(text);
	var width;
	for(var s=size;tmx.width<0.9*w&&s<h;s++){size=s;width=tmx.width;ctx.font=s+this.font;tmx=ctx.measureText(text);}
	ctx.font=(('bold' in bound)?"bold ":"")+size+this.font;
	var dx=('dx' in bound)?bound.dx:0;
	var dy=('dy' in bound)?bound.dy:0;
	if('center' in bound){ctx.translate((w-width)/2,0);}
	ctx.translate(dx,dy);
	ctx.strokeText(text,0,0);
	ctx.fillText(text,0,0);
	ctx.restore();
}
CreateCards.prototype.printImage=function(ctx,bound,image){
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
CreateCards.prototype.printTextarea=function(ctx,bound,text){
	if(text=="")return;
	ctx.save();
	if('lineWidth' in bound)ctx.lineWidth=bound.lineWidth;
	if('fillStyle' in bound)ctx.fillStyle=bound.fillStyle;
	if('strokeStyle' in bound)ctx.strokeStyle=bound.strokeStyle;
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
CreateCards.prototype.splitByWidth=function(ctx,width,text,h,number){
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
CreateCards.prototype.printPie=function(ctx,bound,pieces){
	ctx.save();
	if('lineWidth' in bound)ctx.lineWidth=bound.lineWidth;
	if('fillStyle' in bound)ctx.fillStyle=bound.fillStyle;
	if('strokeStyle' in bound)ctx.strokeStyle=bound.strokeStyle;
	var numerator=pieces[0];
	var denominator=pieces[1];
	var pieSize=((bound.width>bound.height)?bound.height:bound.width)/2;
	var x=bound.x+bound.width/2;
	var y=bound.y+bound.height/2;
	var start=Math.PI/2;
	var angle=2*Math.PI/denominator;
	var fillStyle=('fillStyle' in bound)?bound.fillStyle:"red";
	if(denominator==0){
		ctx.beginPath();
		ctx.fillStyle="white";
		ctx.arc(x,y,pieSize,0,2*Math.PI,false);
		ctx.stroke();
	}else if(denominator==1){
		ctx.beginPath();
		ctx.fillStyle=fillStyle;
		ctx.arc(x,y,pieSize,0,2*Math.PI,false);
		ctx.fill();
		ctx.stroke();
	}else{
		for(var i=0;i<denominator;i++){
			if(i<numerator)ctx.fillStyle=fillStyle;
			else ctx.fillStyle="white";
			ctx.beginPath();
			ctx.moveTo(x,y);
			ctx.arc(x,y,pieSize,start,start+angle,false);
			ctx.lineTo(x,y);
			ctx.fill();
			ctx.stroke();
			start+=angle;
		}
	}
	ctx.restore();
}
CreateCards.prototype.create=function(){
	this.ctx.fillStyle="white";
	this.ctx.fillRect(0,0,this.pageWidth,this.pageHeight);
	var i=0;
	for(var index=0;index<this.datas.length;index++,i++){
		if(i==this.card_positionXs.length){
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
		this.ctx.translate(this.card_positionXs[i],this.card_positionYs[i]);
		if(this.horizontal)this.ctx.rotate(-Math.PI/2);
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
