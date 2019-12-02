function LineDetectionModel(image){
	let self=this;
	if(Object.prototype.toString.call(image)==='[object String]'){
		let newImage=new Image();
		newImage.onload=function(e){self.setImage(newImage);}
		newImage.src=image;
	}else{
		self.setImage(image);
	}
	this.lineNumber=5;
	this.lineWidth=5;
	this.zoomFactor=1;
}
LineDetectionModel.prototype.setImage=function(image){
	this.image=image;
	this.width=image.width;
	this.height=image.height;
	this.canvas=this.createCanvas(image.width,image.height);
	this.ctx=this.canvas.getContext("2d");
	this.ctx.strokeStyle="black";
	this.ctx.fillStyle="white";
	this.ctx.drawImage(image,0,0,image.width,image.height);
	this.pixels=this.ctx.getImageData(0,0,image.width,image.height);
}
LineDetectionModel.prototype.randomColor=function(){
	let r=Math.floor(Math.random()*256);
	let g=Math.floor(Math.random()*256);
	let b=Math.floor(Math.random()*256);
	return "rgb("+r+","+g+","+b+")";
}
LineDetectionModel.prototype.randomCurve=function(){
	for(let i=0;i<this.lineNumber;i++){
		ctx.beginPath();
		let width=Math.random()*this.lineWidth;
		if(width<1)width=1;
		ctx.lineWidth=width;
		let x1=Math.random()*ctx.canvas.clientWidth;
		let y1=Math.random()*ctx.canvas.clientHeight;
		let x2=Math.random()*ctx.canvas.clientWidth;
		let y2=Math.random()*ctx.canvas.clientHeight;
		let x3=Math.random()*ctx.canvas.clientWidth;
		let y3=Math.random()*ctx.canvas.clientHeight;
		let x4=Math.random()*ctx.canvas.clientWidth;
		let y4=Math.random()*ctx.canvas.clientHeight;
		ctx.moveTo(x1,y1);
		ctx.bezierCurveTo(x2,y2,x3,y3,x4,y4);
		ctx.stroke();
	}
}
LineDetectionModel.prototype.randomLine=function(){
	for(let i=0;i<this.lineNumber;i++){
		ctx.beginPath();
		let width=Math.random()*this.lineWidth;
		if(width<1)width=1;
		ctx.lineWidth=width;
		let x1=Math.random()*ctx.canvas.clientWidth;
		let y1=Math.random()*ctx.canvas.clientHeight;
		let x2=Math.random()*ctx.canvas.clientWidth;
		let y2=Math.random()*ctx.canvas.clientHeight;
		ctx.moveTo(x1,y1);
		ctx.lineTo(x2,y2);
		ctx.stroke();
	}
}
LineDetectionModel.prototype.createCanvas=function(width,height){
	let canvas=document.createElement("canvas");
	canvas.setAttribute("width",width);
	canvas.setAttribute("height",height);
	$("#main").append(canvas);
	return canvas;
}
LineDetectionModel.prototype.detectLine=function(){
	this.detectElements();
	let elementCanvas=this.createCanvas(this.zoomFactor*this.width,this.zoomFactor*this.height);
	this.printElements(elementCanvas);
	this.detectOutlines();
	let outlineCanvas=this.createCanvas(this.zoomFactor*this.width,this.zoomFactor*this.height);
	this.printOutlines(outlineCanvas);
	this.smoothLine();
	let smoothCanvas=this.createCanvas(this.zoomFactor*this.width,this.zoomFactor*this.height);
	this.printOutlines(smoothCanvas);
}
LineDetectionModel.prototype.detectElements=function(){
	this.elements=[];
	for(let x=0;x<this.width;x++){
		this.elements[x]=[];
		let hit=false;
		for(let y=0;y<this.height;y++){
			this.elements[x][y]=0;
			let avg=this.getPixelAverage(x,y);
			if(hit){
				if(avg>128){this.elements[x][y-1]+=4;hit=false;}
			}else{
				if(avg<=128){this.elements[x][y]+=1;hit=true;}
			}
		}
		if(hit){this.elements[x][y-1]+=4;}
	}
	for(let y=0;y<this.height;y++){
		let hit=false;
		for(let x=0;x<this.width;x++){
			let avg=this.getPixelAverage(x,y);
			if(hit){
				if(avg>128){this.elements[x-1][y]+=2;hit=false;}
			}else{
				if(avg<=128){this.elements[x][y]+=8;hit=true;}
			}
		}
		if(hit){this.elements[x-1][y]+=2;}
	}
}
LineDetectionModel.prototype.printElements=function(canvas){
	let ctx=canvas.getContext("2d");
	let dx=canvas.clientWidth/this.elements.length;
	let dy=canvas.clientHeight/this.elements[0].length;
	for(let i=0;i<this.elements.length;i++){
		for(let j=0;j<this.elements[i].length;j++){
			let value=this.elements[i][j];
			if(value==0)continue;
			let x=dx*i;
			let y=dx*j;
			if((value&16)>0)ctx.strokeStyle="red";
			else ctx.strokeStyle="black";
			if((value&1)>0){ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x+dx,y);ctx.stroke();}
			if((value&2)>0){ctx.beginPath();ctx.moveTo(x+dx,y);ctx.lineTo(x+dx,y+dx);ctx.stroke();}
			if((value&4)>0){ctx.beginPath();ctx.moveTo(x+dx,y+dx);ctx.lineTo(x,y+dx);ctx.stroke();}
			if((value&8)>0){ctx.beginPath();ctx.moveTo(x,y+dx);ctx.lineTo(x,y);ctx.stroke();}
		}
	}
}
LineDetectionModel.prototype.getPixelAverage=function(x,y){
	if(x<0)return 255;
	else if(x>=this.width)return 255;
	else if(y<0)return 255;
	else if(y>=this.height)return 255;
	let index=y*4*this.width+4*x;
	let r=this.pixels.data[index];
	let g=this.pixels.data[index+1];
	let b=this.pixels.data[index+2];
	let a=this.pixels.data[index+3];
	return a/255*(r+g+b)/3+(255-a);
}
LineDetectionModel.prototype.getElementValue=function(x,y){
	let width=this.elements.length;
	if(x<0||x>=width)return 0;
	let height=this.elements[x].length;
	if(y<0||y>=height)return 0;
	else return this.elements[x][y];
}
LineDetectionModel.prototype.detectOutlines=function(){
	let array=this.elements.map(function(arr){return arr.slice();});
	let width=this.elements.length;
	let height=this.elements[0].length;
	this.outlines=[];
	for(let x=0;x<this.width;x++){
		for(let y=0;y<this.height;y++){
			let value=array[x][y];
			if((value&1)>0){
				array[x][y]-=1;
				let line={};
				let currentX=x+1;
				let currentY=y;
				line.points=[x,y,currentX,currentY];
				let direction=1;
				while(currentX!=x||currentY!=y){
					if(direction==1){//right
						if((this.getElementValue(currentX,currentY-1)&8)>0){
							array[currentX][currentY-1]-=8;
							direction=8;
							currentY--;
						}else if((this.getElementValue(currentX,currentY)&1)>0){
							array[currentX][currentY]-=1;
							direction=1;
							currentX++;
						}else if((this.getElementValue(currentX-1,currentY)&2)>0){
							array[currentX-1][currentY]-=2;
							direction=2;
							currentY++;
						}
					}else if(direction==2){//down
						if((this.getElementValue(currentX,currentY)&1)>0){
							array[currentX][currentY]-=1;
							direction=1;
							currentX++;
						}else if((this.getElementValue(currentX-1,currentY)&2)>0){
							array[currentX-1][currentY]-=2;
							direction=2;
							currentY++;
						}else if((this.getElementValue(currentX-1,currentY-1)&4)>0){
							array[currentX-1][currentY-1]-=4;
							direction=4;
							currentX--;
						}
					}else if(direction==4){//left
						if((this.getElementValue(currentX-1,currentY)&2)>0){
							array[currentX-1][currentY]-=2;
							direction=2;
							currentY++;
						}else if((this.getElementValue(currentX-1,currentY-1)&4)>0){
							array[currentX-1][currentY-1]-=4;
							direction=4;
							currentX--;
						}else if((this.getElementValue(currentX,currentY-1)&8)>0){
							array[currentX][currentY-1]-=8;
							direction=8;
							currentY--;
						}
					}else if(direction==8){//up
						if((this.getElementValue(currentX-1,currentY-1)&4)>0){
							array[currentX-1][currentY-1]-=4;
							direction=4;
							currentX--;
						}else if((this.getElementValue(currentX,currentY-1)&8)>0){
							array[currentX][currentY-1]-=8;
							direction=8;
							currentY--;
						}else if((this.getElementValue(currentX,currentY)&1)>0){
							array[currentX][currentY]-=1;
							direction=1;
							currentX++;
						}
					}
					line.points.push(currentX,currentY);
				}
				this.outlines.push(line);
			}
		}
	}
}
LineDetectionModel.prototype.printOutlines=function(canvas){
	let ctx=canvas.getContext("2d");
	let dx=canvas.clientWidth/this.elements.length;
	let dy=canvas.clientHeight/this.elements[0].length;
	for(let i=0;i<this.outlines.length;i++){
		let outline=this.outlines[i];
		ctx.beginPath();
		ctx.strokeStyle=this.randomColor();
		for(let j=0;j<outline.points.length;j+=2){
			let x=dx*outline.points[j];
			let y=dx*outline.points[j+1];
			if(j==0)ctx.moveTo(x,y);
			else ctx.lineTo(x,y);
		}
		ctx.stroke();
	}
}
LineDetectionModel.prototype.smoothLine=function(){
	for(let i=0;i<this.outlines.length;i++){
		let line=this.outlines[i];
		line.points.pop();line.points.pop();
		let prevX=line.points[line.points.length-2];
		let prevY=line.points[line.points.length-1];
		let array=[];
		for(let j=0;j<line.points.length;j+=2){
			let x=line.points[j];
			let y=line.points[j+1];
			array.push((prevX+x)/2,(prevY+y)/2);
			prevX=x;
			prevY=y;
		}
		let x=line.points[0];
		let y=line.points[1];
		array.push((prevX+x)/2,(prevY+y)/2,array[0],array[1]);
		line.points=array;
	}
}
