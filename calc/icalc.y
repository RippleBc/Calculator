/* Reverse Polish Notation calculator. */

%{
#include <stdio.h>
#include <math.h>
#include <ctype.h> 

int yylex (void);
void yyerror (char const *);
%}


/* Bison declarations.	*/ 
%define api.value.type {double} 
%token NUM
%left '-' '+'
%left '*' '/'
%precedence NEG	/* negation(unary minus) */ 
%right '^'	/* exponentiation */


%%
/* The grammar follows.	*/ 
input:
%empty
| input line
;

line:
'\n'
| exp '\n'	{ printf ("\t%.10g\n", $1); }
| error '\n' { yyerror; }
;

exp:
NUM	{ $$ = $1;	}
| exp '+' exp	{ $$ = $1 + $3;	}
| exp '-' exp	{ $$ = $1 - $3;	}
| exp '*' exp	{ $$ = $1 * $3;	}
| exp '/' exp	{ $$ = $1 / $3;	}
| '-' exp	%prec NEG { $$ = -$2;	}
| exp '^' exp	{ $$ = pow ($1, $3); }
| '(' exp ')'	{ $$ = $2;	}
;
%%

/* Called by yyparse on error.	*/ 
void
yyerror (char const *s)
{
	fprintf (stderr, "%s\n", s);
}

int
yylex (void)
{
	int c;

	/* Skip white space.	*/
	while ((c = getchar ()) == ' ' || c == '\t') continue;
	/* Process numbers.	*/
	if (c == '.' || isdigit (c))
	{
		/* 把一个（或多个）字符退回到steam代表的文件流中，可以理解成一个“计数器”。 */
		ungetc (c, stdin); 
		/* %lf represents long float */
		scanf ("%lf", &yylval); 
		return NUM;
	}
	/* Return end-of-input.	*/ 
	if (c == EOF)
		return 0;
	/* Return a single char.	*/ 
	return c;
}

int
main (void)
{
	return yyparse ();
}
