function SequenceModel(){this.sequences={};}
SequenceModel.prototype.readFasta=function(text){
	this.sequences=[];
	let sequence;
	let lines=text.split(/\n/);
	for(let i=0;i<lines.length;i++){
		let line=lines[i];
		if(line.lastIndexOf('>',0)===0){
			if(sequence!=null)this.sequences.push(sequence);
			sequence={};
			sequence.id=line.substr(1).trim();
			sequence.sequence="";
		}else sequence.sequence+=line.trim();
	}
	return this;
}
SequenceModel.prototype.sequenceLengths=function(){
	let distributions={};
	for(let i=0;i<this.sequences.length;i++){
		let length=this.sequences[i].sequence.length;
		if(!(length in distributions))distributions[length]=0;
		distributions[length]++;
	}
	return distributions;
}
SequenceModel.prototype.getLongestSequenceLength=function(){let longest=0;for(let i=0;i<this.sequences.length;i++){let length=this.sequences[i].sequence.length;if(length>longest)longest=length;}return longest;}
SequenceModel.prototype.reverseComplementAll=function(){for(let i=0;i<this.sequences.length;i++){let sequence=this.sequences[i];sequence.sequence=this.reverseComplement(sequence.sequence);}return this;}
SequenceModel.prototype.outputToTextarea=function(textarea){for(let i=0;i<this.sequences.length;i++){let sequence=this.sequences[i];textarea.append(">"+sequence.id+"\n"+sequence.sequence+"\n");}}
SequenceModel.prototype.reverseComplement=function(string){return this.complement(this.reverse(string));}
SequenceModel.prototype.reverse=function(string){let chars=string.split("");chars.reverse();return chars.join("");}
SequenceModel.prototype.complement=function(string){
	string=string.replace(/A/g,1);
	string=string.replace(/C/g,2);
	string=string.replace(/G/g,4);
	string=string.replace(/T/g,8);
	string=string.replace(/1/g,"T");
	string=string.replace(/2/g,"G");
	string=string.replace(/4/g,"C");
	string=string.replace(/8/g,"A");
	string=string.replace(/a/g,1);
	string=string.replace(/c/g,2);
	string=string.replace(/g/g,4);
	string=string.replace(/t/g,8);
	string=string.replace(/1/g,"t");
	string=string.replace(/2/g,"g");
	string=string.replace(/4/g,"c");
	string=string.replace(/8/g,"a");
	return string;
}
