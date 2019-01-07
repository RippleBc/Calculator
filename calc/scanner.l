%top {
	#include "parser.h"
}

%{
	#include "../common.h"
%}

DIGIT [0-9]
ID [a-z][a-z0-9]*

%option reentrant bison-bridge bison-locations
%option outfile="./calc/scanner.c" header-file="./calc/scanner.h"
%option noyywrap

%%

{DIGIT}+ {
	yylval_param->NUM = atoi(yytext);
	return NUM;
}

{ID} {
	/* try to find the symbol */
	symrec *s = getsym(yytext); 

	/* push new symbol */
	if(s == 0)
	{
		s = putsym(yytext, VAR);
	}

	if(s->type == VAR)
	{
		yylval_param->VAR = s;
	}
	else
	{
		yylval_param->FNCT = s;
	}
	
	return s->type;
}

"\n" {
	yylloc_param->first_line = yylloc_param->last_line;
	yylloc_param->last_line++;

	return '\n';
}

"+" {
	return '+';
}

"-" {
	return '-';
}

"*" {
	return '*';
}

"/" {
	return '/';
}

. { /* eat up not matched character */ }

%%

