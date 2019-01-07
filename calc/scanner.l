%top {
	
}

%{
	#include "../common.h"
%}

DIGIT [0-9]
ID [a-z][a-z0-9]*

%option reentrant
%option outfile="./calc/scanner.c" header-file="./calc/scanner.h"
%option noyywrap

%%

{DIGIT}+ {
	ECHO;
}

{ID} {
	ECHO;
}

"\n" {
	ECHO;
}

. { /* eat up any unmatched character */ }

%%