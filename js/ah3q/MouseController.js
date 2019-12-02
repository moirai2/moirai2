function MouseController(id){
	var self=this;
	if(id instanceof Element)this.dom=id;
	else this.id=id;
	this.isMaciPhone=((navigator.userAgent.match(/iPad/i)!=null)||(navigator.userAgent.match(/iPhone/i)!=null)||(navigator.userAgent.match(/iPod/i)!=null))?true:false;
	this.isAndroid=(navigator.userAgent.match(/Android/i)!=null)?true:false;
	this.isSafari=navigator.userAgent.match(/Safari/i)?true:false;
	this.isFirefox=navigator.userAgent.match(/Firefox/i)?true:false;
	this.isChrome=navigator.userAgent.match(/Chrome/i)?true:false;
	this.clickCount=0;//number of clicked count
	this.longSecond=800;
	this.doubleSecond=400;
	this.movableTarget;//"movable" class should be added to the target
	this.mouseDown;//used to check if mouse is moving or dragging
	this.previousMouseX=new Array(0,0);//previous mouse location X record upto two touches
	this.previousMouseY=new Array(0,0);//previous mouse location Y record upto two touches
	this.longTimer;//long click timer
	this.doubleTimer;//double click timer
	if(document.readyState=="loading")$(document).ready(function(){self.initialize();});
	else this.initialize();
}
MouseController.prototype.initialize=function(){
	var self=this;
	if(this.dom==null)this.dom=document.getElementById(this.id);
	if(this.isMaciPhone||this.isAndroid){
		this.dom.addEventListener("touchstart",function(event){self.touchStartHandler(event);event.preventDefault();},false);
		this.dom.addEventListener("touchmove",function(event){self.touchMoveHandler(event);event.preventDefault();},false);
		this.dom.addEventListener("touchend",function(event){self.touchEndHandler(event);event.preventDefault();},false);
	}else{
		this.dom.addEventListener("mousedown",function(event){self.mouseDownHandler(event);},false);
		this.dom.addEventListener("mouseup",function(event){self.mouseUpHandler(event);},false);
		this.dom.addEventListener("mousemove",function(event){self.mouseMoveHandler(event);},false);
	}
	return this;
}
MouseController.prototype.addEventListener=function(type,listener,useCapture,wantsUntrusted){this.dom.addEventListener(type,listener,useCapture,wantsUntrusted);}
MouseController.prototype.removeEventListener=function(type,listener,useCapture){this.dom.removeEventListener(type,listener,useCapture);}
MouseController.prototype.touchStartHandler=function(event){var size=event.touches.length;if(size==1){this.mouseDownHandler(event);return;}}
MouseController.prototype.singleClickHandler=function(event,target,x,y){if(!this.removeRegisteredDom(target))this.dom.dispatchEvent(new CustomEvent("singleClick",{detail:this.addKeyPressed(event,{target:target,x:x,y:y})}));}
MouseController.prototype.doubleClickHandler=function(event,target,x,y){this.dom.dispatchEvent(new CustomEvent("doubleClick",{detail:this.addKeyPressed(event,{target:target,x:x,y:y})}));}
MouseController.prototype.longClickHandler=function(event,target,x,y){this.dom.dispatchEvent(new CustomEvent("longClick",{detail:this.addKeyPressed(event,{target:target,x:x,y:y})}));}
MouseController.prototype.touchMoveHandler=function(event){
	var size=event.touches.length;
	if(size==1){this.mouseMoveHandler(event);return;}
	if(!this.pinched){
		if(this.longTimer){clearTimeout(this.longTimer);self.longTimer=null;}
		var x1=this.getPositionX(event,0);
		var y1=this.getPositionY(event,0);
		var x2=this.getPositionX(event,1);
		var y2=this.getPositionY(event,1);
		this.startDistance=Math.sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1));
		this.downStartX=(x1+x2)/2;
		this.downStartY=(y1+y2)/2;
		this.previousX=this.downStartX;
		this.previousY=this.downStartY;
		this.previousDistance=this.startDistance;
		this.pinched=true;
		return;
	}
	var x1=this.getPositionX(event,0);
	var y1=this.getPositionY(event,0);
	var x2=this.getPositionX(event,1);
	var y2=this.getPositionY(event,1);
	var distance=Math.sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1));
	var x=(x2+x1)/2;
	var y=(y2+y1)/2;
	var zoomfactor=distance/this.previousDistance;
	var dx=x-this.previousX;
	var dy=y-this.previousY;
	this.dom.dispatchEvent(new CustomEvent("pinched",{detail:this.addKeyPressed(event,{target:event.target,zoomfactor:zoomfactor})}));
	this.dom.dispatchEvent(new CustomEvent("scrolled",{detail:this.addKeyPressed(event,{target:event.target,dx:dx,dy:dy})}));
	this.previousX=x;
	this.previousY=y;
	this.previousDistance=distance;
}
MouseController.prototype.touchEndHandler=function(event){
	var self=this;
	if(!this.pinched){this.mouseUpHandler(event);return;}
	var x1=this.getPositionX(event,0);
	var y1=this.getPositionY(event,0);
	var x2=this.getPositionX(event,1);
	var y2=this.getPositionY(event,1);
	var distance=Math.sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1));
	var x=(x2+x1)/2;
	var y=(y2+y1)/2;
	var zoomfactor=distance/this.startDistance;
	var dx=x-this.downStartX;
	var dy=y-this.downStartY;
	this.dom.dispatchEvent(new CustomEvent("pinchCompleted",{detail:this.addKeyPressed(event,{target:event.target,zoomfactor:zoomfactor})}));
	this.dom.dispatchEvent(new CustomEvent("scrollCompleted",{detail:this.addKeyPressed(event,{target:event.target,dx:dx,dy:dy})}));
	this.pinched=false;
}
MouseController.prototype.mouseDownHandler=function(event){
	var self=this;
	if((this.movableTarget=this.searchClassRecursively(event.target,"movable"))!=null){}
	else if(event.target!=this.dom){return;}//2018/04/02 Added to stop mouse propagation
	this.downStartX=this.getPositionX(event,0);
	this.downStartY=this.getPositionY(event,0);
	var x=this.downStartX;
	var y=this.downStartY;
	this.mouseDown=true;
	this.dragged=false;
	if(this.movableTarget==null)this.longTimer=setTimeout(function(){self.longTimer=null;self.clickCount=0;self.longClickHandler(event,event.target,x,y)},this.longSecond);
}
MouseController.prototype.addKeyPressed=function(event,json){
	if(event.shiftKey)json["shiftKey"]=true;
	if(event.altKeyPressed)json["shiftKey"]=true;
	if(event.ctrlKeyPressed)json["shiftKey"]=true;
	if(event.metaKeyPressed)json["shiftKey"]=true;
	return json;
}
MouseController.prototype.mouseMoveHandler=function(event){
	var self=this;
	var prevX=this.previousMouseX[0];
	var prevY=this.previousMouseY[0];
	var x=this.getPositionX(event,0);
	var y=this.getPositionY(event,0);
	if(this.mouseDown){
		if(this.longTimer){clearTimeout(this.longTimer);this.longTimer=null;}
		if(!this.dragged){
			this.dragged=true;
			this.dom.dispatchEvent(new CustomEvent("dragStarted",{detail:this.addKeyPressed(event,{target:event.target,x:x,y:y})}));
		}else{
			var dx=x-prevX;
			var dy=y-prevY;
			if(this.movableTarget!=null){
				$(this.movableTarget).css({left:"+="+dx,top:"+="+dy});
				this.dom.dispatchEvent(new CustomEvent("moved",{detail:this.addKeyPressed(event,{target:this.movableTarget,prevX:prevX,prevY:prevY,x:x,y:y,dx:dx,dy:dy})}));
			}else this.dom.dispatchEvent(new CustomEvent("dragged",{detail:this.addKeyPressed(event,{target:event.target,prevX:prevX,prevY:prevY,x:x,y:y,dx:dx,dy:dy})}));
		}
	}else if(this.doubleTimer){
		if(Math.abs(x-this.prevClickX)>10||Math.abs(y-this.prevClickY)>10){
			clearTimeout(this.doubleTimer);
			this.doubleTimer=null;
			this.mouseDown=false;
			this.clickCount=0;
			this.singleClickHandler(event,event.target,this.prevClickX,this.prevClickY);
		}
	}
}
MouseController.prototype.mouseUpHandler=function(event){
	var self=this;
	var prevX=this.previousMouseX[0];
	var prevY=this.previousMouseY[0];
	var x=this.getPositionX(event,0);
	var y=this.getPositionY(event,0);
	if(!this.mouseDown)return false;
	this.mouseDown=false;
	if(this.dragged){
		if(this.movableTarget!=null){
			this.dom.dispatchEvent(new CustomEvent("moveEnded",{detail:this.addKeyPressed(event,{target:this.movableTarget,x:x,y:y})}));
			this.dom.dispatchEvent(new CustomEvent("moveCompleted",{detail:this.addKeyPressed(event,{target:this.movableTarget,startX:this.downStartX,startY:this.downStartY,endX:x,endY:y})}));
			this.movableTarget=null;
		}else{
			var dx=x-prevX;
			var dy=y-prevY;
			var l=Math.sqrt(dx*dx+dy*dy);
			this.dom.dispatchEvent(new CustomEvent("dragEnded",{detail:this.addKeyPressed(event,{target:event.target,prevX:prevX,prevY:prevY,x:x,y:y,dx:dx,dy:dy})}));
			dx=x-this.downStartX;
			dy=y-this.downStartY;
			l=Math.sqrt(dx*dx+dy*dy);
			this.dom.dispatchEvent(new CustomEvent("dragCompleted",{detail:this.addKeyPressed(event,{endTarget:event.target,startX:this.downStartX,startY:this.downStartY,length:l,endX:x,endY:y,x:x,y:y})}));
		}
		return;
	}else if(this.longTimer){clearTimeout(this.longTimer);this.longTimer=null;this.clickCount++;}
	if(this.clickCount==1){
		this.prevClickX=x;
		this.prevClickY=y;
		this.doubleTimer=setTimeout(function(){self.doubleTimer=null;self.mouseDown=false;self.clickCount=0;self.singleClickHandler(event,event.target,x,y);},this.doubleSecond);
	}else if(this.clickCount>1){
		if(this.doubleTimer){clearTimeout(this.doubleTimer);this.doubleTimer=null;}
		this.clickCount=0;
		this.doubleClickHandler(event,event.target,x,y);
	}
}
MouseController.prototype.getScrollY=function(){
	if(window.pageYOffset)return window.pageYOffset;
	else if(document.documentElement.scrollTop)return document.documentElement.scrollTop;
	else if(document.body.scrollTop)return document.body.scrollTop;
	else return 0;
}
MouseController.prototype.getScrollX=function(){
	if(window.pageXOffset)return window.pageXOffset;
	else if(document.documentElement.scrollLeft)return document.documentElement.scrollLeft;
	else if(document.body.scrollLeft)return document.body.scrollLeft;
	else return 0;
}
MouseController.prototype.getPositionX=function(event,index){
	var rectangle=this.dom.getBoundingClientRect();
	if(this.isMaciPhone||this.isAndroid){if(event.touches[index]==undefined)return this.previousMouseX[index];this.previousMouseX[index]=Math.floor(event.touches[index].pageX-rectangle.left-this.getScrollX());}
	else this.previousMouseX[index]=Math.floor(event.clientX-rectangle.left);
	return this.previousMouseX[index];
}
MouseController.prototype.getPositionY=function(event,index){
	var rectangle=this.dom.getBoundingClientRect();
	if(this.isMaciPhone||this.isAndroid){if(event.touches[index]==undefined)return this.previousMouseY[index];this.previousMouseY[index]=Math.floor(event.touches[index].pageY-rectangle.top-this.getScrollY());}
	else{this.previousMouseY[index]=Math.floor(event.clientY-rectangle.top);}
	return this.previousMouseY[index];
}
MouseController.prototype.removeRegisteredDom=function(parent){
	var hit=false;
	var children=parent.childNodes;
	var tmp=[];
	for(var i=0;i<children.length;i++){var child=children[i];if($(child).hasClass("removeWhenClickedOutside")){tmp.push(child);}}
	for(var i=0;i<tmp.length;i++)parent.removeChild(tmp[i]);
	return tmp.length>0;
}
MouseController.prototype.searchClassRecursively=function(target,className){var tmp=target;while(tmp!=null){if($(tmp).hasClass(className))return tmp;else tmp=tmp.parentNode;}return null;}
