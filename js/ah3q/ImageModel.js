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
	var bound={top: null,left: null,right: null,bottom: null};
	for(var i=0;i<this.pixels.data.length;i+=4){
		if(this.pixels.data[i+3]!==0){
			var x=(i/4)%this.canvas.width;
			var y=~~((i/4)/this.canvas.width);
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
	var trimHeight=bound.bottom-bound.top;
	var trimWidth=bound.right-bound.left;
	var trimmed=this.ctx.getImageData(bound.left,bound.top,trimWidth,trimHeight);
	this.canvas.width=trimWidth;
	this.canvas.height=trimHeight;
	this.ctx=this.canvas.getContext('2d');
	this.ctx.putImageData(trimmed,0,0);
	return this;
}
ImageModel.prototype.convertToPngImage=function(){
	var trimmedImage=new Image();
	trimmedImage.src=this.canvas.toDataURL('image/png');
	return trimmedImage;
}
ImageModel.prototype.pickColor=function(x,y){
	var index=y*4*this.canvas.width+4*x;
	return [this.pixels.data[index],this.pixels.data[index+1],this.pixels.data[index+2],this.pixels.data[index+3]];
}
ImageModel.prototype.fillColorWithTransparency=function(x,y,c){
	var done=[];
	var next=[x,y];
	var length=this.canvas.width*this.canvas.height;
	for(var i=0;i<length;i++)done[i]=0;
	for(var y=0;y<this.canvas.height;y++){
		for(var x=0;x<this.canvas.width;x++){
			var index=y*4*this.canvas.width+4*x;
			var r=this.pixels.data[index];
			var g=this.pixels.data[index+1];
			var b=this.pixels.data[index+2];
			var a=this.pixels.data[index+3];
			if(r!=c[0]||g!=c[1]||b!=c[2]||a!=c[3])done[y*this.canvas.width+x]=1;
		}
	}
	while(next.length>0){
		var x=next.shift();
		var y=next.shift();
		this.pixels.data[y*4*this.canvas.width+4*x+3]=0;
		var i=(y-1)*this.canvas.width+x;
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
