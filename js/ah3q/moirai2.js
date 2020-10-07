//######################################## CONSTRUCTOR ########################################
// constructor
function moirai2(){
	var self=this;
}
moirai2.prototype.submitJob=function(json){
	var self=this;
	var post=$.ajax({type:'POST',dataType:'text',url:"moirai2.php?command=submit",data:json});
	post.fail(function(xhr,textStatus){console.log("failed",xhr,textStatus);});
	post.done(function(data){console.log(data);})
}
