//######################################## CONSTRUCTOR ########################################
function graphnet(id){
	var self=this;
	this.mod=mod;
	this.cy;
	this.nodes={};
	this.edges=[];
	this.elements={nodes:[],edges:[]};
	this.cy=window.cy=cytoscape({
		container:document.getElementById('cy'),
		autounselectify:true,
		boxSelectionEnabled:false,
		layout:{name:'cola'},
		style:[
			{
				selector:'node',
				css:{'background-color':'#f92411'},
				style:{'label':'data(label)'}
			},{
				selector:'edge',
				css:{'line-color':'#f92411'}
			}
		]
		
	});
	this.cy.on("tap","edge",function(evt){
		console.log("tap edge",evt);
	});
	this.cy.on("tap","node",function(evt){
		console.log("tap node",evt);
	});
	this.cy.on("dbltap","edge",function(evt){
		console.log("dbltap edge",evt);
	});
	this.cy.on("dbltap","node",function(evt){
		console.log("dbltap node",evt);
	});
	this.cy.on("taphold","edge",function(evt){
		console.log("taphold edge",evt);
	});
	this.cy.on("taphold","node",function(evt){
		console.log("taphold node",evt);
	});
	this.cy.on("taphold",function(evt){
		this.cy.add({
			group: 'nodes',
			data: { "id":1, "label":"test", weight: 75 },
			position: { x: 200, y: 200 }
		});
	});
}
//######################################## QUERY ########################################
graphnet.prototype.handleInput=function(inputVars,line){
	const inputre=new RegExp("-i '(.+?)'");
	var match=line.match(inputre);
	if(match!=null){
		for(var j=1;j<match.length;j++){
			var triples=match[j].split(',');
			triples.forEach(triple=>{
				var tokens=triple.split('->');
				var sub=tokens[0];//root
				var pre=tokens[1];//input
				var obj=tokens[2];//$input
				if(obj.startsWith("$"))inputVars[obj]="$"+pre;
			});
		}
		return 1;
	}
}
graphnet.prototype.handleOutput=function(inputVars,line,index){
	const outputre=new RegExp("-o '(.+?)'");
	var match=line.match(outputre);
	if(match!=null){
		for(var j=1;j<match.length;j++){
			var triples=match[j].split(',');
			triples.forEach(triple=>{
				var tokens=triple.split('->');
				var sub=tokens[0];//root
				var pre=tokens[1];//input
				var obj=tokens[2];//$input
				if(sub.startsWith("$")){
					var s=inputVars[sub];
					if(obj.startsWith("$")){//true edge
						var p="command"+index;
						var o="$"+pre;
						console.log("edge",s,p,o);
						addEdge(s,p,o);
					}else{
						console.log("edge",s,pre,obj);
						addEdge(s,pre,obj);
					}
				}else{
					if(obj.startsWith("$")){//true edge
						var p="command"+index;
						var o="$"+pre;
						console.log("edge",sub,p,o);
						addEdge(sub,p,o);
					}else{
						console.log(sub,pre,obj);
						addEdge(sub,pre,obj);
					}
				}
			});
		}
		return 1;
	}
}
graphnet.prototype.addNode=function(node){
	if(this.nodes[node]!=null)return this.nodes[node];
	var id="n"+Object.keys(this.nodes).length;
	var hash={"data":{"id":id,"label":node}};
	this.nodes[node]=id;
	this.elements["nodes"].push(hash);
	return id;
}
graphnet.prototype.addEdge=function(from,edge,to){
	var f=addNode(from);
	var t=addNode(to);
	var id="e"+elements["edges"].length;
	var hash={"data":{"id":id,"source":f,"target":t,"label":edge}};
	this.elements["edges"].push(hash);
}
graphnet.prototype.readWorkflow=function(text){
	const graphnetre=new RegExp('graphnet.pl');
	const continuere=new RegExp("^(.+)\\s+\\\\");
	lines=text.split(/\n/);
	var index=0;
	for(var i=0,concat=0;i<lines.length;i++,index++){
		var match=lines[i].match(continuere);
		if(match!=null){
			if(i==index){
				lines[index]=match[1];
			}else if(i>index){
				lines[index]+=" ";
				lines[index]+=match[1];
			}
			concat=1;
			index--;
			continue;
		}
		if(concat==1){lines[index]+=" "+lines[i];}
		else{lines[index]=lines[i];}
		concat=0;
	}
	var extra=lines.length-index;
	var commandIndex=0;
	for(var i=0;i<extra;i++){lines.pop();}
	lines.forEach(line=>{
		if(line.search(graphnetre)>0){
			var inputVars={};
			handleInput(inputVars,line);
			handleOutput(inputVars,line,commandIndex);
			commandIndex++;
		}
	});
	this.cy.json({"elements":this.elements});
	this.cy.layout({name:'cola'}).run();
}