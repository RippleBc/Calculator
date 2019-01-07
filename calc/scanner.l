%top {
	#include "parser.h"
}

%{
	#include "../common.h"

	void compute_llocp(yyscan_t, YYLTYPE *);
%}

DIGIT [0-9]
ID [a-z][a-z0-9]*

%option reentrant bison-bridge bison-locations
%option outfile="./calc/scanner.c" header-file="./calc/scanner.h"
%option noyywrap

%%

{DIGIT}+ {
	compute_llocp(yyscanner, yylloc_param);

	yylval_param->NUM = atoi(yytext);
	return NUM;
}

{ID} {
	compute_llocp(yyscanner, yylloc_param);

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
	yylloc_param->first_column = yylloc_param->last_column = 0;

	compute_llocp(yyscanner, yylloc_param);

	yylloc_param->first_line = yylloc_param->last_line;
	yylloc_param->last_line++;

	return '\n';
}

"+" {
	compute_llocp(yyscanner, yylloc_param);

	return '+';
}

"-" {
	compute_llocp(yyscanner, yylloc_param);

	return '-';
}

"*" {
	compute_llocp(yyscanner, yylloc_param);

	return '*';
}

"/" {
	compute_llocp(yyscanner, yylloc_param);

	return '/';
}

"(" {
	compute_llocp(yyscanner, yylloc_param);

	return '(';
}

")" {
	compute_llocp(yyscanner, yylloc_param);

	return ')';
}

. { 
	/* eat up not matched character */

	compute_llocp(yyscanner, yylloc_param);
}

%%

void compute_llocp(yyscan_t scanner, YYLTYPE *yylloc_param)
{
	yylloc_param->first_column = yylloc_param->last_column;
	yylloc_param->last_column += yyget_leng(scanner);
}