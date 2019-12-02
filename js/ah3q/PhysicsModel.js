function PhysicsModel(page){
	this.page=page;
	this.container=page.container;
	this.nodes=new Array();//nodes(Shape)
	this.edges=new Array();//eddges(Line)
	this.reduceConstant=0.9;
	this.wallConstant=0.1;
	this.collisionConstant=0.1;
	this.edgeConstant=0.3;
	this.stabilizeConstant=0.1;
	this.fixConstant=0.1;
}
PhysicsModel.prototype.newEdge=function(from,to,drawArrow=true,size=5){
	let line=new createjs.Shape();
	let g=line.graphics.setStrokeDash([2,2]).beginStroke("red").setStrokeStyle(3);
	line.from=from;
	line.to=to;
	let dx=to.x-from.x;
	let dy=to.y-from.y;
	let l=Math.sqrt(dx*dx+dy*dy);
	dx/=l;
	dy/=l;
	let x1=from.x+from.radius*dx;
	let y1=from.y+from.radius*dy;
	let x2=to.x-to.radius*dx;
	let y2=to.y-to.radius*dy;
	let x3=x2-size*(dx+dy);
	let y3=y2-size*(dy-dx);
	let x4=x2-size*(dx-dy);
	let y4=y2-size*(dy+dx);
	line.cm1=g.moveTo(x1,y1).command;
	line.cm2=g.lineTo(x2,y2).command;
	line.graphics.setStrokeDash(null).beginFill("red");
	line.cm3=g.moveTo(x2,y2).command;
	line.cm4=g.lineTo(x3,y3).command;
	line.cm5=g.lineTo(x4,y4).command;
	line.size=size;
	g.closePath();
	this.container.addChildAt(line,0);
	this.addEdge(line);
}
PhysicsModel.prototype.addEdge=function(edge){edge.direction=1;this.edges.push(edge);return this;}
PhysicsModel.prototype.addRepulsion=function(edge){edge.direction=-1;this.edges.push(edge);return this;}
PhysicsModel.prototype.addNode=function(node){
	if(this.nodes.indexOf(node)>=0)return;
	this.nodes.push(node);
	if(node.vx==null)node.vx=0;
	if(node.vy==null)node.vy=0;
	if(node.ax==null)node.ax=0;
	if(node.ay==null)node.ay=0;
	if(node.fx==null)node.fx=0;
	if(node.fy==null)node.fy=0;
	return this;
}
PhysicsModel.prototype.removeChild=function(node){let index=this.nodes.indexOf(node);if(index>=0)this.nodes.splice(index,1);}
PhysicsModel.prototype.calculate=function(){
	this.resetAccelerations();
	this.bounceWall(this.wallConstant);
	this.reduceVelocity(this.reduceConstant);
	this.nodeCollision(this.collisionConstant);
	this.edgeForce(this.edgeConstant);
	this.expandBoundary(this.page.expandConstant);
	this.stabilize(this.stabilizeConstant);
	this.update();
}
PhysicsModel.prototype.expandBoundary=function(str){
	this.page.aw=0;
	this.page.ah=0;
	if(str>0){
		if(this.page.getWidth()<this.page.maxWidth)this.page.aw+=str;
		else if(this.page.getWidth()>this.page.maxWidth)this.page.aw-=str;
		if(this.page.getHeight()<this.page.maxHeight)this.page.ah+=str;
		else if(this.page.getHeight()>this.page.maxHeight)this.page.ah-=str;
	}else if(str<0){
		let minX=this.page.getWidth()/2;
		let minY=this.page.getHeight()/2;
		let maxX=-this.page.getWidth()/2;
		let maxY=-this.page.getHeight()/2;
		for(let i=0;i<this.nodes.length;i++){
			let node=this.nodes[i];
			if(node.isRect){
				if( node.x-node.width<minX)minX=node.x-node.width;
				if(node.y-node.height<minY)minY=node.y-node.height;
				if( node.x+node.width>maxX)maxX=node.x+node.width;
				if(node.y+node.height>maxY)maxY=node.y+node.height;
			}else{
				if(node.x-node.radius<minX)minX=node.x-node.radius;
				if(node.y-node.radius<minY)minY=node.y-node.radius;
				if(node.x+node.radius>maxX)maxX=node.x+node.radius;
				if(node.y+node.radius>maxY)maxY=node.y+node.radius;
			}
		}
		if(this.page.getWidth()>maxX-minX)this.page.aw=str;
		if(this.page.getHeight()>maxY-minY)this.page.ah=str;
	}
}
PhysicsModel.prototype.reduceVelocity=function(str){for(let i=0;i<this.nodes.length;i++){let n=this.nodes[i];n.vx*=str;n.vy*=str;}}
PhysicsModel.prototype.resetAccelerations=function(){for(let i=0;i<this.nodes.length;i++){let n=this.nodes[i];n.ax=0.0;n.ay=0.0;}}
PhysicsModel.prototype.bounceWall=function(str){
	if(str==0)return;
	for(let i=0;i<this.nodes.length;i++){
		let node=this.nodes[i];
		if(node.isRect){
			if(node.x-node.width/2<-this.page.getWidth()/2){node.ax+=str;}
			else if(node.x+node.width/2>this.page.getWidth()/2){node.ax-=str;}
			if(node.y-node.height/2<-this.page.getHeight()/2){node.ay+=str;}
			else if(node.y+node.height/2>this.page.getHeight()/2){node.ay-=str;}
		}else{
			if(node.x-node.radius<-this.page.getWidth()/2){node.ax+=str;}
			else if(node.x+node.radius>this.page.getWidth()/2){node.ax-=str;}
			if(node.y-node.radius<-this.page.getHeight()/2){node.ay+=str;}
			else if(node.y+node.radius>this.page.getHeight()/2){node.ay-=str;}
		}
	}
}
PhysicsModel.prototype.rectRectCollision=function(str,n1,n2){
	if((n1.x-n1.width/2>n2.x+n2.width/2||n2.x-n2.width/2>n1.x+n1.width/2)||(n1.y-n1.height/2>n2.y+n2.height/2||n2.y-n2.height/2>n1.y+n1.height/2))return;
	let dx=n2.x-n1.x;
	let dy=n2.y-n1.y;
	let width=n1.width/2+n2.width/2;
	let height=n1.height/2+n2.height/2
	let w1=n1.width*n1.height;
	let w2=n2.width*n2.height;
	let const1=1-w1/(w1+w2);
	let const2=1-w2/(w1+w2);
	let d=Math.sqrt(dx*dx+dy*dy);
	if(d==0)d=1;
	dx/=d;dy/=d;
	if(dx==0&&dy==0){dx=0.5-Math.random();dy=0.5-Math.random();}
	n1.ax-=const1*dx;
	n1.ay-=const1*dy;
	n2.ax+=const2*dx;
	n2.ay+=const2*dy;
}
PhysicsModel.prototype.circleCircleCollision=function(str,n1,n2){
	let r=n1.radius+n2.radius;
	let dx=n2.x-n1.x;
	let dy=n2.y-n1.y;
	let d=Math.sqrt(dx*dx+dy*dy);
	if(d>=r)return;
	dx/=r;dy/=r;
	let l=(r-d)/10;
	let w1=n1.radius*n1.radius;
	let w2=n2.radius*n2.radius;
	let const1=1-w1/(w1+w2);
	let const2=1-w2/(w1+w2);
	n1.ax-=l*const1*dx;
	n1.ay-=l*const1*dy;
	n2.ax+=l*const2*dx;
	n2.ay+=l*const2*dy;
}
PhysicsModel.prototype.clamp=function(val,min,max){if(val<min)return min;else if(val>max)return max;else return val;}
PhysicsModel.prototype.circleRectCollision=function(str,n1,n2){
	let dx=n2.x-n1.x;
	let dy=n2.y-n1.y;
	let closestX=this.clamp(n1.x,n2.x-n2.width/2,n2.x+n2.width/2);
	let closestY=this.clamp(n1.y,n2.y-n2.height/2,n2.y+n2.height/2);
	let d=Math.sqrt((n1.x-closestX)*(n1.x-closestX)+(n1.y-closestY)*(n1.y-closestY));
	if(d>=n1.radius)return;
	dx/=n2.radius;dy/=n2.radius;
	let l=(n1.radius-d)/10;
	let w1=n1.width*n1.height;
	let w2=n2.radius*n2.radius;
	let const1=1-w1/(w1+w2);
	let const2=1-w2/(w1+w2);
	n1.ax-=l*const1*dx;
	n1.ay-=l*const1*dy;
	n2.ax+=l*const2*dx;
	n2.ay+=l*const2*dy;
}
PhysicsModel.prototype.nodeCollision=function(str){
	if(str==0)return;
	for(let i=0;i<this.nodes.length;i++){
		let n1=this.nodes[i];
		for(let j=i+1;j<this.nodes.length;j++){
			let n2=this.nodes[j];
			if(n1.isRect){
				if(n2.isRect)this.rectRectCollision(str,n1,n2);
				else this.circleRectCollision(str,n2,n1);
			}else{
				if(n2.isRect)this.circleRectCollision(str,n1,n2);
				else this.circleCircleCollision(str,n1,n2);
			}
		}
	}
}
PhysicsModel.prototype.edgeForce=function(str){
	if(str==0)return;
	for(let i=0;i<this.edges.length;i++){
		let edge=this.edges[i];
		let dx=edge.to.x-edge.from.x;
		let dy=edge.to.y-edge.from.y;
		let d=Math.sqrt(dx*dx+dy*dy);
		dx/=d;dy/=d;
		let r=edge.to.radius+edge.from.radius;
		let m=(d-r)/r;
		let w1=edge.from.radius*edge.from.radius;
		let w2=edge.to.radius*edge.to.radius;
		let const1=edge.direction*(1-w1/(w1+w2));
		let const2=edge.direction*(1-w2/(w1+w2));
		edge.from.ax+=const1*str*m*m*dx;
		edge.from.ay+=const1*str*m*m*dy;
		edge.to.ax-=const2*str*m*m*dx;
		edge.to.ay-=const2*str*m*m*dy;
	}
}
PhysicsModel.prototype.stabilize=function(str){
	if(str==0)return;
	for(let i=0;i<this.nodes.length;i++){
		let n=this.nodes[i];
		let dx=n.x-n.fx;
		let dy=n.y-n.fy;
		let d=Math.sqrt(dx*dx+dy*dy);
		if(d<1){n.ax*=str;n.ay*=str;}
		else if(d<0.1){n.ax=0;n.ay=0;}
	}
}
PhysicsModel.prototype.update=function(){
	if(this.page.expandConstant!=0){
		let width=this.page.getWidth()+this.page.aw;
		let height=this.page.getHeight()+this.page.ah;
		this.page.resize(width,height);
	}
	for(let i=0;i<this.nodes.length;i++){
		let n=this.nodes[i];
		if(n.mousedown)continue;
		n.vx+=n.ax;
		n.vy+=n.ay;
		n.x+=n.vx;
		n.y+=n.vy;
		n.fx*=1.0-this.fixConstant;
		n.fy*=1.0-this.fixConstant;
		n.fx+=this.fixConstant*n.x;
		n.fy+=this.fixConstant*n.y;
	}
	for(let i=0;i<this.edges.length;i++){
		let edge=this.edges[i];
		let dx=edge.to.x-edge.from.x;
		let dy=edge.to.y-edge.from.y;
		let l=Math.sqrt(dx*dx+dy*dy);
		dx/=l;
		dy/=l;
		let x1;
		let y1;
		if(edge.from.isRect){
			let p=this.getLineRectIntersection(edge.to.x,edge.to.y,edge.from.x,edge.from.y,edge.from.x-edge.from.width/2,edge.from.y-edge.from.height/2,edge.from.width,edge.from.height);
			x1=p[0]+3*dx;
			y1=p[1]+3*dy;
		}else{
			x1=edge.from.x+edge.from.radius*dx;
			y1=edge.from.y+edge.from.radius*dy;
		}
		let x2;
		let y2;
		if(edge.to.isRect){
			let p=this.getLineRectIntersection(edge.from.x,edge.from.y,edge.to.x,edge.to.y,edge.to.x-edge.to.width/2,edge.to.y-edge.to.height/2,edge.to.width,edge.to.height);
			x2=p[0]-3*dx;
			y2=p[1]-3*dy;
		}else{
			x2=edge.to.x-edge.to.radius*dx;
			y2=edge.to.y-edge.to.radius*dy;
		}
		edge.cm1.x=x1;
		edge.cm1.y=y1;
		edge.cm2.x=x2;
		edge.cm2.y=y2;
		edge.cm3.x=x2;
		// drawing arrow
		let x3=x2-edge.size*(dx+dy);
		let y3=y2-edge.size*(dy-dx);
		let x4=x2-edge.size*(dx-dy);
		let y4=y2-edge.size*(dy+dx);
		edge.cm3.y=y2;
		edge.cm4.x=x3;
		edge.cm4.y=y3;
		edge.cm5.x=x4;
		edge.cm5.y=y4;
	}
}
PhysicsModel.prototype.getRectDirection=function(dx,dy,width,height){
	let ratio1=width/height;
	let ratio2=Math.abs(dx/dy);
	if(dx<0){
		if(dy<0){// - -
			if(ratio2>ratio1)return 2;
			else return 4;
		}else if(dy>0){ // - +
			if(ratio2>ratio1)return 2;
			else return 3;
		}else return 2;
	}else if(dx>0){
		if(dy<0){ // + -
			if(ratio2>ratio1)return 1;
			else return 4;
		}else if(dy>0) { // + +
			if(ratio2>ratio1)return 1;
			else return 3;
		}return 1;
	}else{
		if(dy<0)return 4;
		else if(dy>0) return 3;
		return 0;
	}
}
PhysicsModel.prototype.getLineIntersection=function(x1,y1,x2,y2,x3,y3,x4,y4){
	let d=(y4-y3)*(x2-x1)-(x4-x3)*(y2-y1);
	let ua=(x4-x3)*(y1-y3)-(y4-y3)*(x1-x3);
	let ub=(x2-x1)*(y1-y3)-(y2-y1)*(x1-x3);
	if(d==0)return new Array((x1+x2)/2,(y1+y2)/2);
	ua/=d;ub/=d;
	return new Array(x1+ua*(x2-x1),y1+ua*(y2-y1));
}
PhysicsModel.prototype.getLineRectIntersection=function(x1,y1,x2,y2,x,y,w,h){
	let direction=this.getRectDirection(x1-x2,y1-y2,w,h);
	if(direction==2)return this.getLineIntersection(x1,y1,x2,y2,x,y,x,y+h);
	else if(direction==1)return this.getLineIntersection(x1,y1,x2,y2,x+w,y,x+w,y+h);
	else if(direction==4)return this.getLineIntersection(x1,y1,x2,y2,x,y,x+w,y);
	else if(direction==3)return this.getLineIntersection(x1,y1,x2,y2,x,y+h,x+w,y+h);
	return new Array((x1+x2)/2,(y1+y2)/2);
}
