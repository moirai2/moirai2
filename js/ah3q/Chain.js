//######################################## CONSTRUCTOR ########################################
// constructor
function Chain(){
	let self=this;
	this.job=0;
	this.jobs=[];
	this.rdf=new RDF();
}
//######################################## BASIC ########################################
Chain.prototype.execute=function(func){
	let self=this;
	this.jobs.push(function(){func(self);self.start();});
	return this;
}
Chain.prototype.log=function(){
	let self=this;
	this.jobs.push(function(){console.log(self);self.start();});
	return this;
}
Chain.prototype.reload=function(){
	let self=this;
	this.jobs.push(function(){location.reload();self.start();});
	return this;
}
Chain.prototype.sleep=function(time){
	let self=this;
	if(time==null)time=500;
	this.jobs.push(function(){setTimeout(function(){self.start();},time);});
	return this;
}
Chain.prototype.start=function(){
	if(this.job<this.jobs.length){
		let job=this.jobs[this.job++];
		if(Array.isArray(job)){
			let cond=job[0];
			let func=job[1];
			func.call(this);
		}else{
			job.call(this);
		}
	}
	return this;
}
