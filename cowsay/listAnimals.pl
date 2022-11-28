#!/usr/bin/perl

my @animals=();
while(<STDIN>){
	if(/files/){next;}
	my @tokens=split(/\s/);
	push(@animals,@tokens);
}
print join(" ",@animals)."\n";