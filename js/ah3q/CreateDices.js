function CreateDices(){
	this.font="px 'ＭＳ ゴシック'";// dice this.font
	this.fillColor="#EEEEEE"// dice color
	this.pixelPerCm=236;//600dpi
	this.pixelPerMm=this.pixelPerCm/10;//23.6
	this.pageWidth=4960;//210mm 600dpi
	this.pageHeight=7016;//297mm 600dpi
	this.diceSize=12*this.pixelPerMm;//12mm
	this.backsides=new Array(4,8,7,6,1,11);// dice back sizes
	this.frontsides=new Array(0,2,3,5,9,10);//dice front sizes
	this.canvas=document.createElement("canvas");//this.canvas
	this.ctx=this.canvas.getContext("2d");//context
	this.initialize();//initialize
}
CreateDices.prototype.setPageSize=function(width,height){this.pageWidth=this.pixelPerMm*width;this.pageHeight=this.pixelPerMm*height;this.initialize();return this;}
CreateDices.prototype.setDiceSize=function(mm){this.diceSize=this.pixelPerMm*mm;this.initialize();return this;}
CreateDices.prototype.initialize=function(){
	this.canvas.width=this.pageWidth;//set this.canvas width
	this.canvas.height=this.pageHeight;//set this.canvas height
	this.cardWidth=Math.floor(3.25*this.diceSize);//32.5mm
	this.cardHeight=Math.floor(4*this.diceSize);//40mm
	this.spanX=0.25*this.diceSize;//span between width
	this.spanY=0;//span between height
	// calculate row and column
	this.diceRowSize=Math.floor(this.pageHeight/this.cardHeight);
	this.diceColumnSize=Math.floor(this.pageWidth/this.cardWidth);
	this.number=this.diceRowSize*this.diceColumnSize;// number of dices created
	var row=Math.floor(this.pageHeight/this.cardWidth);
	var column=Math.floor(this.pageWidth/this.cardHeight);
	var number=row*column;
	if(number>this.number){
		this.number=number;
		this.diceRowSize=row;
		this.diceColumnSize=column;
		this.horizontal=true;
	}else{
		this.horizontal=false;
	}
	this.extra=0.25*this.diceSize;
	this.positionXs=new Array();
	this.positionYs=new Array();
	this.textXs=new Array();
	this.textYs=new Array();
	for(var i=0;i<4;i++){
		for(var j=0;j<3;j++){
			this.positionXs.push(this.spanX+j*this.diceSize);
			this.positionYs.push(this.spanY+i*this.diceSize);
			this.textXs.push(this.spanX+j*this.diceSize+this.diceSize/2);
			this.textYs.push(this.spanY+i*this.diceSize+this.diceSize/2);
		}
	}
	this.card_positionXs=new Array();
	this.card_positionYs=new Array();
	if(this.horizontal){
		this.marginX=(this.pageWidth-this.diceColumnSize*this.cardHeight)/2;
		this.marginY=(this.pageHeight-this.diceRowSize*this.cardWidth)/2+this.cardWidth;
		for(var i=0;i<this.diceRowSize;i++){
			for(var j=0;j<this.diceColumnSize;j++){
				this.card_positionXs.push(this.marginX+j*this.cardHeight);
				this.card_positionYs.push(this.marginY+i*this.cardWidth);
			}
		}
	}else{
		this.marginX=(this.pageWidth-this.diceColumnSize*this.cardWidth)/2;
		this.marginY=(this.pageHeight-this.diceRowSize*this.cardHeight)/2;
		for(var i=0;i<this.diceRowSize;i++){
			for(var j=0;j<this.diceColumnSize;j++){
				this.card_positionXs.push(this.marginX+j*this.cardWidth);
				this.card_positionYs.push(this.marginY+i*this.cardHeight);
			}
		}
	}
	return this;
}
CreateDices.prototype.drawDice=function(){
	this.ctx.save();
	this.ctx.fillStyle="white";
	this.ctx.fillRect(0,0,this.cardWidth,this.cardHeight);
	var f=Math.floor(0.5*this.extra)+this.font;
	for(var i=0;i<this.backsides.length;i++){
		this.fillBG(this.backsides[i],this.fillColor);
		this.drawText(this.backsides[i],"のり"+(i+1),f,"grey","grey",0,0);
	}
	this.ctx.fillStyle=this.fillColor;
	this.ctx.fillRect(this.spanX-this.extra,this.spanY,this.extra,this.diceSize);
	this.ctx.fillStyle="grey";
	this.ctx.textAlign='center';
	this.ctx.textBaseline='middle';
	this.ctx.translate(this.spanX-this.extra/2,this.spanY+this.diceSize/2);
	this.ctx.rotate(-Math.PI/2);
	this.ctx.font=f;
	this.ctx.fillText("のり7",0,0);
	this.ctx.restore();
	return this;
}
CreateDices.prototype.drawLines=function(){
	this.ctx.save();
	this.ctx.strokeStyle="grey";
	this.ctx.lineWidth=1;
	this.ctx.strokeRect(this.spanX-this.extra,this.spanY,this.extra,this.diceSize);
	for(var i=0;i<this.positionXs.length;i++)this.ctx.strokeRect(this.positionXs[i],this.positionYs[i],this.diceSize,this.diceSize);
	this.ctx.beginPath();
	this.ctx.strokeStyle="black";
	this.ctx.setLineDash([15,5]);
	this.ctx.lineWidth=3;
	this.ctx.moveTo(this.positionXs[0]-this.extra,this.positionYs[0]);
	this.ctx.lineTo(this.positionXs[2]+this.diceSize,this.positionYs[2]);
	this.ctx.lineTo(this.positionXs[11]+this.diceSize,this.positionYs[11]+this.diceSize);
	this.ctx.lineTo(this.positionXs[9],this.positionYs[9]+this.diceSize);
	this.ctx.lineTo(this.positionXs[0],this.positionYs[0]+this.diceSize);
	this.ctx.lineTo(this.positionXs[0]-this.extra,this.positionYs[0]+this.diceSize);
	this.ctx.lineTo(this.positionXs[0]-this.extra,this.positionYs[0]);
	this.ctx.moveTo(this.positionXs[1],this.positionYs[1]);
	this.ctx.lineTo(this.positionXs[1],this.positionYs[1]+this.diceSize);
	this.ctx.moveTo(this.positionXs[2],this.positionYs[2]+this.diceSize);
	this.ctx.lineTo(this.positionXs[2]+this.diceSize,this.positionYs[2]+this.diceSize);
	this.ctx.moveTo(this.positionXs[3],this.positionYs[3]+this.diceSize);
	this.ctx.lineTo(this.positionXs[3]+this.diceSize,this.positionYs[3]+this.diceSize);
	this.ctx.moveTo(this.positionXs[4]+this.diceSize,this.positionYs[4]);
	this.ctx.lineTo(this.positionXs[4]+this.diceSize,this.positionYs[4]+this.diceSize);
	this.ctx.moveTo(this.positionXs[7],this.positionYs[7]+this.diceSize);
	this.ctx.lineTo(this.positionXs[7]+this.diceSize,this.positionYs[7]+this.diceSize);
	this.ctx.moveTo(this.positionXs[9]+this.diceSize,this.positionYs[9]);
	this.ctx.lineTo(this.positionXs[9]+this.diceSize,this.positionYs[9]+this.diceSize);
	this.ctx.stroke();
	this.ctx.restore();
	return this;
}
CreateDices.prototype.fillBG=function(index,background){
	this.ctx.fillStyle=background;
	this.ctx.fillRect(this.positionXs[index],this.positionYs[index],this.diceSize,this.diceSize);
	return this;
}
CreateDices.prototype.drawText=function(index,text,font,fillColor,strokeColor,dx,dy){
	this.ctx.save();
	this.ctx.translate(this.textXs[index]+dx,this.textYs[index]+dy);
	this.ctx.font=font;
	this.ctx.textAlign='center';
	this.ctx.textBaseline='middle';
	this.ctx.fillStyle=fillColor;
	this.ctx.strokeStyle=strokeColor;
	this.ctx.strokeText(text,0,0);
	this.ctx.fillText(text,0,0);
	this.ctx.restore();
	return this;
}
CreateDices.prototype.drawDice1=function(index){
	var x=this.textXs[index];
	var y=this.textYs[index];
	var radius=this.diceSize/4;
	this.ctx.save();this.ctx.lineWidth=2;
	this.ctx.translate(x,y);
	this.ctx.beginPath();
	this.ctx.fillStyle="red";
	this.ctx.arc(0,0,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.strokeStyle="black";
	this.ctx.setLineDash([]);
	this.ctx.arc(0,0,radius,0,Math.PI*2,false);
	this.ctx.stroke();
	this.ctx.restore();
	return this;
}
CreateDices.prototype.drawDice2=function(index){
	var x=this.textXs[index];
	var y=this.textYs[index];
	var radius=this.diceSize/8;
	this.ctx.save();
	this.ctx.translate(x,y);
	this.ctx.fillStyle="black";
	this.ctx.beginPath();
	this.ctx.arc(1.5*radius,0,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(-1.5*radius,0,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.restore();
	return this;
}
CreateDices.prototype.drawDice3=function(index){
	var x=this.textXs[index];
	var y=this.textYs[index];
	var radius=this.diceSize/8;
	this.ctx.save();
	this.ctx.translate(x,y);
	this.ctx.fillStyle="black";
	this.ctx.beginPath();
	this.ctx.arc(0,0,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(2*radius,2*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(-2*radius,-2*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.restore();
	return this;
}
CreateDices.prototype.drawDice4=function(index){
	var x=this.textXs[index];
	var y=this.textYs[index];
	var radius=this.diceSize/8;
	this.ctx.save();
	this.ctx.translate(x,y);
	this.ctx.fillStyle="black";
	this.ctx.beginPath();
	this.ctx.arc(1.5*radius,1.5*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(-1.5*radius,-1.5*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(-1.5*radius,1.5*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(1.5*radius,-1.5*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.restore();
	return this;
}
CreateDices.prototype.drawDice5=function(index){
	var x=this.textXs[index];
	var y=this.textYs[index];
	var radius=this.diceSize/8;
	this.ctx.save();
	this.ctx.translate(x,y);
	this.ctx.fillStyle="black";
	this.ctx.beginPath();
	this.ctx.arc(0,0,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(2*radius,2*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(-2*radius,-2*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(-2*radius,2*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(2*radius,-2*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.restore();
	return this;
}
CreateDices.prototype.drawDice6=function(index){
	var x=this.textXs[index];
	var y=this.textYs[index];
	var radius=this.diceSize/8;
	this.ctx.save();
	this.ctx.translate(x,y);
	this.ctx.fillStyle="black";
	this.ctx.beginPath();
	this.ctx.arc(0,1.5*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(0,-1.5*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(2.2*radius,1.5*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(-2.2*radius,-1.5*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(-2.2*radius,1.5*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.beginPath();
	this.ctx.arc(2.2*radius,-1.5*radius,radius,0,Math.PI*2,false);
	this.ctx.fill();
	this.ctx.restore();
	return this;
}
CreateDices.prototype.drawNormal=function(){
	this.drawDice();
	this.ctx.lineWidth=1;
	this.drawDice1(this.frontsides[0]);
	this.drawDice2(this.frontsides[1]);
	this.drawDice3(this.frontsides[4]);
	this.drawDice4(this.frontsides[3]);
	this.drawDice5(this.frontsides[2]);
	this.drawDice6(this.frontsides[5]);
	this.drawLines();
	return this;
}
CreateDices.prototype.create=function(){
	this.ctx.fillStyle="white";
	this.ctx.fillRect(0,0,this.pageWidth,this.pageHeight);
	for(var i=0;i<this.card_positionXs.length;i++){
		var x=this.card_positionXs[i];
		var y=this.card_positionYs[i];
		this.ctx.translate(x,y);
		if(this.horizontal)this.ctx.rotate(-Math.PI/2);
		this.drawNormal();
		if(this.horizontal)this.ctx.rotate(Math.PI/2);
		this.ctx.translate(-x,-y);
	}
	var png=this.canvas.toDataURL('image/png');
	var image=document.createElement("img");
	image.src=png;
	image.width=200;
	image.height=300;
	$("#main").append(image);
	return this;
}
