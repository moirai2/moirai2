function ImageModel(image){
	this.image=image;
	this.canvas=document.createElement('canvas');
	this.canvas.width=image.width;
	this.canvas.height=image.height;
	this.ctx=this.canvas.getContext('2d');
	this.ctx.drawImage(image,0,0);
	this.pixels=this.ctx.getImageData(0,0,this.canvas.width,this.canvas.height);
}
ImageModel.prototype.removeTransparentPixels=function(){
	let bound={top: null,left: null,right: null,bottom: null};
	for(let i=0;i<this.pixels.data.length;i+=4){
		if(this.pixels.data[i+3]!==0){
			let x=(i/4)%this.canvas.width;
			let y=~~((i/4)/this.canvas.width);
			if(bound.top===null)bound.top=y;
			if(bound.left===null)bound.left=x;
			else if(x < bound.left)bound.left=x;
			if(bound.right===null)bound.right=x;
			else if(bound.right < x)bound.right=x;
			if(bound.bottom===null)bound.bottom=y;
			else if(bound.bottom < y)bound.bottom=y;
		}
	}
	bound.bottom++;
	bound.right++;
	let trimHeight=bound.bottom-bound.top;
	let trimWidth=bound.right-bound.left;
	let trimmed=this.ctx.getImageData(bound.left,bound.top,trimWidth,trimHeight);
	this.canvas.width=trimWidth;
	this.canvas.height=trimHeight;
	this.ctx=this.canvas.getContext('2d');
	this.ctx.putImageData(trimmed,0,0);
	return this;
}
ImageModel.prototype.convertToPngImage=function(){
	let trimmedImage=new Image();
	trimmedImage.src=this.canvas.toDataURL('image/png');
	return trimmedImage;
}
ImageModel.prototype.pickColor=function(x,y){
	let index=y*4*this.canvas.width+4*x;
	return [this.pixels.data[index],this.pixels.data[index+1],this.pixels.data[index+2],this.pixels.data[index+3]];
}
ImageModel.prototype.fillColorWithTransparency=function(x,y,c){
	let done=[];
	let next=[x,y];
	let length=this.canvas.width*this.canvas.height;
	for(let i=0;i<length;i++)done[i]=0;
	for(let y=0;y<this.canvas.height;y++){
		for(let x=0;x<this.canvas.width;x++){
			let index=y*4*this.canvas.width+4*x;
			let r=this.pixels.data[index];
			let g=this.pixels.data[index+1];
			let b=this.pixels.data[index+2];
			let a=this.pixels.data[index+3];
			if(r!=c[0]||g!=c[1]||b!=c[2]||a!=c[3])done[y*this.canvas.width+x]=1;
		}
	}
	while(next.length>0){
		let x=next.shift();
		let y=next.shift();
		this.pixels.data[y*4*this.canvas.width+4*x+3]=0;
		let i=(y-1)*this.canvas.width+x;
		if(done[i]==0){done[i]=1;next.push(x,y-1);}
		i=(y+1)*this.canvas.width+x;
		if(done[i]==0){done[i]=1;next.push(x,y+1);}
		i=y*this.canvas.width+(x-1);
		if(done[i]==0){done[i]=1;next.push(x-1,y);}
		i=y*this.canvas.width+(x+1);
		if(done[i]==0){done[i]=1;next.push(x+1,y);}
	}
	this.ctx.putImageData(this.pixels,0,0);
}
