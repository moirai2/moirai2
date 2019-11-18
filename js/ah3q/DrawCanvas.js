function DrawCanvas(){
	var self=this;
	for(var i=0;i<arguments.length;i++){
		var arg=arguments[i];
		if(arg.constructor.name=="SQLiteRDFModel")this.sqliteRDFModel=arg;
		else if(arg.constructor.name=="DnDController")this.dndController=arg;
		else if(arg.constructor.name=="PhysicsModel")this.PhysicsModel=arg;
		else if(arg.constructor.name=="MouseController")this.mouseController=arg;
		else this.id=arg;
	}
	if(document.readyState=="loading")$(document).ready(function(){self.initialize();});
	else this.initialize();
	if(typeof Utility!='undefined')this.utility=new Utility();
}
DrawCanvas.prototype.initialize=function(){
	var self=this;
	this.dom=document.getElementById(this.id);
	$(this.dom).css("margin","0px");
	$(this.dom).css("-webkit-user-select","none");
	this.canvas=document.createElement("canvas");
	$(this.canvas).attr("id","canvas");
	$(this.canvas).css("padding","0px");
	$(this.canvas).css("margin","0px");
	$(this.canvas).css("position","absolute");
	$(this.canvas).css("top","0px");
	$(this.canvas).css("left","0px");
	$(this.canvas).css("z-index",-1);
	$(this.canvas).css("background-color","#FAFAFA");
	$(this.dom).append(this.canvas);
	this.stage=new createjs.Stage("canvas");
	window.addEventListener("resize",function(event){self.resizeHandler(event);},true);
	this.resizeHandler();
	this.dragLineStart=(function(e){
		var x=e.detail.x;
		var y=e.detail.y;
		self.dragLine=new createjs.Shape();
		var g=self.dragLine.graphics.setStrokeDash([2,2]).beginStroke("red").setStrokeStyle(1).moveTo(x,y);
		self.dragLine.command=g.lineTo(x,y).command;
		self.stage.addChild(self.dragLine);
		self.originX=x;
		self.originY=y;
	});
	this.dragRectangleStart=(function(e){
		var x=e.detail.x;
		var y=e.detail.y;
		self.dragRect=new createjs.Shape();
		var g=self.dragRect.graphics.setStrokeDash([2,2]).beginStroke("red").setStrokeStyle(1);
		self.dragRect.command=g.drawRect(x,y,0,0).command;
		self.stage.addChild(self.dragRect);
		self.originX=x;
		self.originY=y;
	});
	this.dragEllipseStart=(function(e){
		var x=e.detail.x;
		var y=e.detail.y;
		self.dragEllipse=new createjs.Shape();
		var g=self.dragEllipse.graphics.setStrokeDash([2,2]).beginStroke("red").setStrokeStyle(1);
		self.dragEllipse.command=g.drawEllipse(x,y,0,0).command;
		self.stage.addChild(self.dragEllipse);
		self.originX=x;
		self.originY=y;
	});
	this.dragLineDrag=(function(e){
		var x=e.detail.x;
		var y=e.detail.y;
		var w=Math.abs(x-self.originX);
		var h=Math.abs(y-self.originY);
		self.dragLine.command.x=x;
		self.dragLine.command.y=y;
	});
	this.dragRectangleDrag=(function(e){
		var x=e.detail.x;
		var y=e.detail.y;
		var dx=x-self.dragRect.command.x;
		var dy=y-self.dragRect.command.y;
		var adx=Math.abs(dx);
		var ady=Math.abs(dy);
		if(e.detail.shiftKey){if(adx<ady)dy=(dy<0)?-adx:adx;else dx=(dx<0)?-ady:ady;}
		self.dragRect.command.w=dx;
		self.dragRect.command.h=dy;
	});
	this.dragEllipseDrag=(function(e){
		var dx=e.detail.x-self.originX;
		var dy=e.detail.y-self.originY;
		var adx=Math.abs(dx);
		var ady=Math.abs(dy);
		if(e.detail.shiftKey){if(adx<ady)dy=(dy<0)?-adx:adx;else dx=(dx<0)?-ady:ady;}
		var x=self.originX-dx;
		var y=self.originY-dy;
		var w=2*dx;
		var h=2*dy;
		self.dragEllipse.command.x=x;
		self.dragEllipse.command.y=y;
		self.dragEllipse.command.w=w;
		self.dragEllipse.command.h=h;
	});
	this.dragLineEnd=(function(e){self.stage.removeChild(self.dragLine);self.dragLine=null;});
	this.dragRectangleEnd=(function(e){self.stage.removeChild(self.dragRect);self.dragRect=null;});
	this.dragEllipseEnd=(function(e){self.stage.removeChild(self.dragEllipse);self.dragEllipse=null;});
	if(this.mouseController!=null){
		this.mouseController.addEventListener("dragStarted",function(e){self.moveTarget=self.getChildFromPoint(e.detail.x,e.detail.y);if(self.moveTarget!=null&&!self.moveTarget.movable)self.moveTarget=null;});
		this.mouseController.addEventListener("dragged",function(e){if(self.moveTarget!=null){self.moveTarget.x+=e.detail.dx;self.moveTarget.y+=e.detail.dy;}});
		this.mouseController.addEventListener("dragEnded",function(e){if(self.moveTarget!=null){self.moveTarget.x+=e.detail.dx;self.moveTarget.y+=e.detail.dy;}});
		// This is to pass single, double, and long click events from mouseController to canvas which has z-index of -1
		this.mouseController.addEventListener("singleClick",function(e){var child=self.getChildFromPoint(e.detail.x,e.detail.y);if(child==null||child._listeners==null)return;;if("singleClick" in child._listeners){child._listeners.singleClick.forEach(function(f){f.apply(child,e);});}});
		this.mouseController.addEventListener("doubleClick",function(e){var child=self.getChildFromPoint(e.detail.x,e.detail.y);if(child==null||child._listeners==null)return;if("doubleClick" in child._listeners){child._listeners.doubleClick.forEach(function(f){f.apply(child,e);});}});
		this.mouseController.addEventListener("longClick",function(e){var child=self.getChildFromPoint(e.detail.x,e.detail.y);if(child==null||child._listeners==null)return;if("longClick" in child._listeners){child._listeners.longClick.forEach(function(f){f.apply(child,e);});}});
	}
	this.start();
}
DrawCanvas.prototype.resizeHandler=function(event){
	var self=this;
	this.width=$(window).width();
	this.height=$(window).height();
	this.dom.width=this.width;
	this.dom.height=this.height;
	this.canvas.width=this.width;
	this.canvas.height=this.height;
	desktop.stage.update();
}
DrawCanvas.prototype.start=function(fps){
	if(fps==null)fps=60;
	createjs.Ticker.framerate=fps;
	createjs.Ticker.addEventListener("tick",this.stage);
}
DrawCanvas.prototype.getChildFromPoint=function(x,y){
	var p=this.stage.globalToLocal(x,y);
	var size=this.stage.children.length;
	for(var i=size-1;i>=0;i--){
		var child=this.stage.children[i];
		var p2=child.globalToLocal(p.x,p.y);
		if(child.hitTest(p2.x,p2.y))return child;
	}
}
DrawCanvas.prototype.addChild=function(child){this.stage.addChild(child);}
DrawCanvas.prototype.removeChild=function(child){this.stage.removeChild(child);}
DrawCanvas.prototype.clickAndHide=function(child){var self=this;child.addEventListener("singleClick",function(e){createjs.Tween.get(child).to({alpha:0},300).call(self.removeChild,child);});}
//https://ics.media/tutorial-createjs/tween.html
DrawCanvas.prototype.drawLineWithDrag=function(boolean){
	if(boolean==null)boolean=true;
	if(boolean){
		this.mouseController.addEventListener("dragStarted",this.dragLineStart);
		this.mouseController.addEventListener("dragged",this.dragLineDrag);
		this.mouseController.addEventListener("dragCompleted",this.dragLineEnd);
	}else{
		this.mouseController.removeEventListener("dragStarted",this.dragLineStart);
		this.mouseController.removeEventListener("dragged",this.dragLineDrag);
		this.mouseController.removeEventListener("dragCompleted",this.dragLineEnd);
	}
}
DrawCanvas.prototype.drawRectangleWithDrag=function(boolean){
	if(boolean==null)boolean=true;
	if(boolean){
		this.mouseController.addEventListener("dragStarted",this.dragRectangleStart);
		this.mouseController.addEventListener("dragged",this.dragRectangleDrag);
		this.mouseController.addEventListener("dragCompleted",this.dragRectangleEnd);
	}else{
		this.mouseController.removeEventListener("dragStarted",this.dragRectangleStart);
		this.mouseController.removeEventListener("dragged",this.dragRectangleDrag);
		this.mouseController.removeEventListener("dragCompleted",this.dragRectangleEnd);
	}
}
DrawCanvas.prototype.drawEllipseWithDrag=function(boolean){
	if(boolean==null)boolean=true;
	if(boolean){
		this.mouseController.addEventListener("dragStarted",this.dragEllipseStart);
		this.mouseController.addEventListener("dragged",this.dragEllipseDrag);
		this.mouseController.addEventListener("dragCompleted",this.dragEllipseEnd);
	}else{
		this.mouseController.removeEventListener("dragStarted",this.dragEllipseStart);
		this.mouseController.removeEventListener("dragged",this.dragEllipseDrag);
		this.mouseController.removeEventListener("dragCompleted",this.dragEllipseEnd);
	}
}
DrawCanvas.prototype.createProcessingIcon=function(json){
	var icon=new createjs.Container();
	icon.x=(json.x!=null)?json.x:this.width/2;
	icon.y=(json.y!=null)?json.y:this.height/2;
	var radius=(json.radius!=null)?json.radius:20;
	for(var i=0;i<12;i++){
		var circle=new createjs.Shape();
		var x=radius*Math.cos(Math.PI*i/6);
		var y=radius*Math.sin(Math.PI*i/6);
		var d=parseInt(256/12*(12-i));
		if(d>0){var c=createjs.Graphics.getRGB(d,d,d);circle.graphics.beginFill(c).drawCircle(x,y,radius/10*(1+0.1*i));icon.addChild(circle);}
	}
	icon.width=2*radius;
	icon.height=2*radius;
	icon.radius=radius;
	var mtween=new createjs.Tween.get(icon,{loop:true}).to({rotation:-360},1000,createjs.Ease.linear);
	return icon;
}
DrawCanvas.prototype.createCircleIcon=function(json){
	var icon=new createjs.Shape();
	icon.x=(json.x!=null)?json.x:this.width/2;
	icon.y=(json.y!=null)?json.y:this.height/2;
	var radius=(json.radius!=null)?json.radius:20;
	var foregroundColor=(json.foregroundColor!=null)?json.foregroundColor:"black";
	var backgroundColor=(json.backgroundColor!=null)?json.backgroundColor:"white";
	icon.graphics.beginFill(backgroundColor);
	icon.graphics.beginStroke(foregroundColor);
	icon.command=icon.graphics.drawCircle(0,0,json.radius).command;
	icon.width=2*radius;
	icon.height=2*radius;
	icon.radius=radius;
	return icon;
}
DrawCanvas.prototype.createPolygonIcon=function(json){
	var icon=new createjs.Shape();
	icon.x=(json.x!=null)?json.x:this.width/2;
	icon.y=(json.y!=null)?json.y:this.height/2;
	var width=(json.width!=null)?json.width:40;
	var height=(json.height!=null)?json.height:40;
	var radius=Math.sqrt(width/2*width/2+height/2*height/2);
	var foregroundColor=(json.foregroundColor!=null)?json.foregroundColor:"black";
	var backgroundColor=(json.backgroundColor!=null)?json.backgroundColor:"white";
	var count=(json.count!=null)?json.count:6;
	var rotate=(json.rotate!=null)?json.rotate:Math.PI;
	icon.graphics.beginFill(backgroundColor);
	for(var i=0;i<count;i++){
		var x=width/2*Math.sin(2*Math.PI/count*i+rotate);
		var y=height/2*Math.cos(2*Math.PI/count*i+rotate);
		if(i==0)icon.graphics.moveTo(x,y);
		else icon.graphics.lineTo(x,y);
	}
	icon.graphics.closePath();
	icon.graphics.beginStroke(foregroundColor);
	for(var i=0;i<count;i++){
		var x=width/2*Math.sin(2*Math.PI/count*i+rotate);
		var y=height/2*Math.cos(2*Math.PI/count*i+rotate);
		if(i==0)icon.graphics.moveTo(x,y);
		else icon.graphics.lineTo(x,y);
	}
	icon.graphics.closePath();
	icon.width=width;
	icon.height=height;
	icon.radius=radius;
	return icon;
}
DrawCanvas.prototype.createRectangleIcon=function(json){
	var icon=new createjs.Shape();
	icon.x=(json.x!=null)?json.x:this.width/2;
	icon.y=(json.y!=null)?json.y:this.height/2;
	var width=(json.width!=null)?json.width:40;
	var height=(json.height!=null)?json.height:40;
	var radius=Math.sqrt(width/2*width/2+height/2*height/2);
	var foregroundColor=(json.foregroundColor!=null)?json.foregroundColor:"black";
	var backgroundColor=(json.backgroundColor!=null)?json.backgroundColor:"white";
	icon.graphics.beginFill(backgroundColor);
	icon.graphics.beginStroke(foregroundColor);
	icon.command=icon.graphics.drawRect(-width/2,-height/2,width,height).command;
	icon.width=width;
	icon.height=height;
	icon.radius=radius;
	return icon;
}
DrawCanvas.prototype.createTextCircleIcon=function(text,json){
	if(text==null)text="undefined";
	var x=(json.x!=null)?json.x:this.width/2;
	var y=(json.y!=null)?json.y:this.height/2;
	var radius=(json.radius!=null)?json.radius:20;
	var font=(font in json)?json.font:"18px Arial";
	var icon=new createjs.Container();
	var r=360/(text.length+1);
	for (var i=0;i<text.length;i++){
		var t=new createjs.Text(text[i],font);
		t.textAlign="center";
		t.textBaseline="middle";
		t.regY=radius;
		t.rotation=r*i;
		icon.addChild(t);
	}
	icon.x=x;
	icon.y=y;
	icon.width=2*radius;
	icon.height=2*radius;
	icon.radius=radius;
	var mtween=new createjs.Tween.get(icon,{loop:true}).to({rotation:-360},10000,createjs.Ease.linear);
	return icon;
}
DrawCanvas.prototype.createDirectoryIcon=function(path,json){
	if(path==null)path="undefined";
	var width=(json.width!=null)?json.width:40;
	var height=(json.height!=null)?json.height:40;
	var font=(font in json)?json.font:"18px Arial";
	var foregroundColor=(json.foregroundColor!=null)?json.foregroundColor:"black";
	var backgroundColor=(json.backgroundColor!=null)?json.backgroundColor:"white";
	var icon=new createjs.Container();
	var shape=new createjs.Shape();
	var halfWidth=width/2.0;
	var sixthHeight=height/6.0;
	var twentythHeight=height/20.0;
	var halfHeight=height/2.0;
	var name=this.utility.dirname(path);
	shape.graphics.beginFill("#EEEEEE");
	shape.graphics.moveTo(-halfWidth,-halfHeight+sixthHeight);
	shape.graphics.lineTo(-halfWidth+twentythHeight,-halfHeight);
	shape.graphics.lineTo(-halfWidth+2*sixthHeight-twentythHeight,-halfHeight);
	shape.graphics.lineTo(-halfWidth+2*sixthHeight,-halfHeight+sixthHeight);
	shape.graphics.lineTo(+halfWidth,-halfHeight+sixthHeight);
	shape.graphics.lineTo(+halfWidth,+halfHeight);
	shape.graphics.lineTo(-halfWidth,+halfHeight);
	shape.graphics.closePath();
	shape.graphics.beginStroke("#000000");
	shape.graphics.moveTo(-halfWidth,-halfHeight+sixthHeight);
	shape.graphics.lineTo(-halfWidth+twentythHeight,-halfHeight);
	shape.graphics.lineTo(-halfWidth+2*sixthHeight-twentythHeight,-halfHeight);
	shape.graphics.lineTo(-halfWidth+2*sixthHeight,-halfHeight+sixthHeight);
	shape.graphics.lineTo(+halfWidth,-halfHeight+sixthHeight);
	shape.graphics.lineTo(+halfWidth,+halfHeight);
	shape.graphics.lineTo(-halfWidth,+halfHeight);
	shape.graphics.lineTo(-halfWidth,-halfHeight+sixthHeight);
	shape.graphics.lineTo(-halfWidth+2*sixthHeight,-halfHeight+sixthHeight);
	icon.addChild(shape);
	var label=new createjs.Text(name,font);
	label.textAlign="center";
	label.textBaseline="middle";
	label.x=0;
	label.y=halfHeight+label.getMeasuredHeight();
	icon.addChild(label);
	icon.x=(json.x!=null)?json.x:this.width/2;
	icon.y=(json.y!=null)?json.y:this.height/2;
	icon.radius=Math.sqrt(width/2*width/2+height/2*height/2);
	icon.width=width;
	icon.height=height;
	return icon;
}
DrawCanvas.prototype.createFileIcon=function(path,json){
	if(path==null)path="undefined";
	var radius=(json.radius!=null)?json.radius:20;
	var font=(font in json)?json.font:"18px Arial";
	var width=(json.width!=null)?json.width:40;
	var height=(json.height!=null)?json.height:40;
	var foregroundColor=(json.foregroundColor!=null)?json.foregroundColor:"black";
	var backgroundColor=(json.backgroundColor!=null)?json.backgroundColor:"white";
	var icon=new createjs.Container();
	var shape=new createjs.Shape();
	var halfWidth=width/2.0;
	var thirdWidth=width/3.0;
	var halfHeight=height/2.0;
	var name=this.utility.filename(path);
	shape.graphics.beginFill("#EEEEEE");
	shape.graphics.moveTo(+halfWidth,-halfHeight+thirdWidth);
	shape.graphics.lineTo(+halfWidth,+halfHeight);
	shape.graphics.lineTo(-halfWidth,+halfHeight);
	shape.graphics.lineTo(-halfWidth,-halfHeight);
	shape.graphics.lineTo(+halfWidth-thirdWidth,-halfHeight);
	shape.graphics.closePath();
	shape.graphics.beginStroke("#000000");
	shape.graphics.moveTo(+halfWidth,-halfHeight+thirdWidth);
	shape.graphics.lineTo(+halfWidth-thirdWidth,-halfHeight);
	shape.graphics.lineTo(+halfWidth-thirdWidth,-halfHeight+thirdWidth);
	shape.graphics.lineTo(+halfWidth,-halfHeight+thirdWidth);
	shape.graphics.lineTo(+halfWidth,+halfHeight);
	shape.graphics.lineTo(-halfWidth,+halfHeight);
	shape.graphics.lineTo(-halfWidth,-halfHeight);
	shape.graphics.lineTo(+halfWidth-thirdWidth,-halfHeight);
	icon.addChild(shape);
	var label=new createjs.Text(name,font);
	label.textAlign="center";
	label.textBaseline="top";
	label.x=0;
	label.y=halfHeight;
	icon.addChild(label);
	icon.path=path;
	icon.url=path;
	icon.name=name;
	icon.x=(json.x!=null)?json.x:this.width/2;
	icon.y=(json.y!=null)?json.y:this.height/2;
	icon.width=width;
	icon.height=height;
	icon.radius=radius;
	return icon;
}
DrawCanvas.prototype.createDialogIcon=function(text,json){
	if(text==null)text="undefined";
	var font=(font in json)?json.font:"18px Arial";
	var icon=new createjs.Container();
	icon.x=(json.x!=null)?json.x:this.width/2;
	icon.y=(json.y!=null)?json.y:this.height/2;
	var tokens=text.split("\n");
	var width=0;
	var height=0;
	var os=Array();
	for(var i=0,newY=0;i<tokens.length;i++){
		var o=new createjs.Text(tokens[i],font);
		o.textAlign="left";
		o.textBaseline="top";
		var w=o.getMeasuredWidth();
		if(w>width)width=w;
		var h=o.getMeasuredHeight()
		height+=h;
		o.y=newY;
		newY+=h;
		os[i]=o;
	}
	for(var i=0;i<os.length;i++){os[i].x=-width/2;os[i].y-=height/2;}
	var margin=(width>height?width:height)/10;
	var w=width/2;
	var h=height/2;
	var box=new createjs.Shape();
	box.graphics.beginFill("#FFFFFF");
	box.graphics.moveTo(-w-margin,h);
	box.graphics.lineTo(-w-margin,-h);
	box.graphics.quadraticCurveTo(-w-margin,-h-margin,-w,-h-margin);
	box.graphics.lineTo(w,-h-margin);
	box.graphics.quadraticCurveTo(w+margin,-h-margin,w+margin,-h);
	box.graphics.lineTo(w+margin,h);
	box.graphics.quadraticCurveTo(w+margin,h+margin,w,h+margin);
	box.graphics.lineTo(-w+margin,h+margin);
	box.graphics.lineTo(-w-margin,h+2*margin);
	box.graphics.lineTo(-w,h+margin);
	box.graphics.quadraticCurveTo(-w-margin,h+margin,-w-margin,h);
	box.graphics.closePath();
	box.graphics.beginStroke("#000000");
	box.graphics.moveTo(-w-margin,h);
	box.graphics.lineTo(-w-margin,-h);
	box.graphics.quadraticCurveTo(-w-margin,-h-margin,-w,-h-margin);
	box.graphics.lineTo(w,-h-margin);
	box.graphics.quadraticCurveTo(w+margin,-h-margin,w+margin,-h);
	box.graphics.lineTo(w+margin,h);
	box.graphics.quadraticCurveTo(w+margin,h+margin,w,h+margin);
	box.graphics.lineTo(-w+margin,h+margin);
	box.graphics.lineTo(-w-margin,h+2*margin);
	box.graphics.lineTo(-w,h+margin);
	box.graphics.quadraticCurveTo(-w-margin,h+margin,-w-margin,h);
	box.graphics.closePath();
	icon.addChild(box);
	for(var i=0;i<os.length;i++)icon.addChild(os[i]);
	icon.text=text;
	icon.width=width;
	icon.height=height;
	icon.radius=Math.sqrt(width/2*width/2+height/2*height/2);
	return icon;
}
DrawCanvas.prototype.createImageIcon=function(image,json){
	var width=(json.width!=null)?json.width:40;
	var height=(json.height!=null)?json.height:40;
	var scaleX=width/image.width;
	var scaleY=height/image.height;
	var icon=new createjs.Container();
	var bmp=new createjs.Bitmap(image);
	bmp.scaleX=scaleX;
	bmp.scaleY=scaleY;
	bmp.x=-width/2;
	bmp.y=-height/2;
	icon.addChild(bmp);
	icon.x=(json.x!=null)?json.x:this.width/2;
	icon.y=(json.y!=null)?json.y:this.height/2;
	icon.width=width;
	icon.height=height;
	icon.radius=Math.sqrt(width/2*width/2+height/2*height/2);
	return icon;
}
DrawCanvas.prototype.createTextIcon=function(text,json){
	if(text==null)text="undefined";
	var icon=new createjs.Container();
	icon.x=x;
	icon.y=y;
	var tokens=text.split("\n");
	var margin=5;
	var width=0;
	var height=0;
	var os=Array();
	for(var i=0,newY=0;i<tokens.length;i++){
		var o=new createjs.Text(tokens[i],font);
		o.textAlign="left";
		o.textBaseline="top";
		var w=o.getMeasuredWidth();
		if(w>width)width=w;
		var h=o.getMeasuredHeight()
		height+=h;
		o.y=newY;
		newY+=h;
		os[i]=o;
	}
	for(var i=0;i<os.length;i++){os[i].x=-width/2;os[i].y-=height/2;}
	width+=2*margin;
	height+=2*margin;
	width=width;
	height=height;
	var x=-width/2;
	var y=-height/2;
	var rect=new createjs.Shape();
	rect.graphics.beginFill("white").drawRect(x,y,width,height);
	rect.graphics.beginStroke("black").drawRect(x,y,width,height);
	icon.addChild(rect);
	for(var i=0;i<os.length;i++)icon.addChild(os[i]);
	width=width;
	height=height;
	radius=Math.sqrt(width/2*width/2+height/2*height/2);
	icon.text=text;
	icon.url=text;
	icon.width=width;
	icon.height=height;
	icon.radius=radius;
	icon.isRect=true;
	return icon;
}
DrawCanvas.prototype.createButton=function(json){
	if(text==null)text="undefined";
	var icon=new createjs.Container();
	icon.x=x;
	icon.y=y;
	var tokens=text.split("\n");
	var margin=20;
	var width=0;
	var height=0;
	var background=(json!=null&&"background" in json)?json["background"]:"white";
	var foreground=(json!=null&&"foreground" in json)?json["foreground"]:"black";
	var middleground=(json!=null&&"middleground" in json)?json["middleground"]:"grey";
	var os=Array();
	for(var i=0,newY=0;i<tokens.length;i++){
		var o=new createjs.Text(tokens[i],font,foreground);
		o.textAlign="left";
		o.textBaseline="top";
		var w=o.getMeasuredWidth();
		if(w>width)width=w;
		var h=o.getMeasuredHeight()
		height+=h;
		o.y=newY;
		newY+=h;
		os[i]=o;
	}
	for(var i=0;i<os.length;i++){os[i].x=-width/2;os[i].y-=height/2;}
	width+=2*margin;
	height+=2*margin;
	width=width;
	height=height;
	var x=-width/2;
	var y=-height/2;
	var rect=new createjs.Shape();
	rect.fillcmd=rect.graphics.beginFill(background).command;
	rect.graphics.drawRoundRect(x,y,width,height,width/5,height/5);
	rect.graphics.beginStroke(foreground).drawRoundRect(x,y,width,height,width/5,height/5);
	icon.addChild(rect);
	for(var i=0;i<os.length;i++)icon.addChild(os[i]);
	width=width;
	height=height;
	radius=Math.sqrt(width/2*width/2+height/2*height/2);
	icon.text=text;
	icon.url=text;
	icon.width=width;
	icon.height=height;
	icon.radius=radius;
	icon.isRect=true;
	return icon;
}
