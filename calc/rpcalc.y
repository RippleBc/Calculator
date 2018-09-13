/* Reverse Polish Notation calculator. */

%{
#include <stdio.h>
#include <math.h>
#include <ctype.h> 

int yylex (void);
void yyerror (char const *);
%}


%define api.value.type {double}
%token NUM

%%
input:
%empty
| input line
;

line:
'\n'
| exp '\n' { printf ("%.10g\n", $1); }
;

exp:
NUM { $$ = $1; }
| exp exp '+' { $$ = $1 + $2; }
| exp exp '-' { $$ = $1 - $2; }
| exp exp '*' { $$ = $1 * $2; }
| exp exp '/' { $$ = $1 / $2; }
| exp exp '^' { $$ = pow ($1, $2); }
| exp 'n' { $$ = -$1; }
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
