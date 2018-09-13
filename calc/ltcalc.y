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
| exp '/' exp	
	{
		if($3) {
			$$ = $1 / $3;	
		}
		else {
			$$ = 1;
			fprintf(stderr, "%d.%d-%d.%d: division by zero", @3.first_line, @3.first_column, @3.last_line, @3.last_column);
		}
	}
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
	while ((c = getchar ()) == ' ' || c == '\t') 	
		++yylloc.last_column;

	/* Step. */
	yylloc.first_line = yylloc.last_line;
	yylloc.first_column = yylloc.last_column;

	/* Process numbers.	*/
	if (isdigit (c))
	{
		yylval = c - '0';
		++yylloc.last_column;
		while (isdigit(c = getchar ())) {
			++yylloc.last_column;
			yylval = yylval * 10 + c - '0';
		}
		/* push last non-digit charactor to stdin */
		ungetc (c, stdin);
		return NUM;
	}
	/* Return end-of-input.	*/ 
	if (c == EOF)
		return 0;

  /* update location. */
  if (c == '\n') {
  	++yylloc.last_line;
  	yylloc.last_column = 0;
  }
  else {
  	++yylloc.last_column;
  }

	/* Return a single char.	*/ 
	return c;
}

int
main (void)
{
	yylloc.first_line = yylloc.last_line = 1;
	yylloc.first_column = yylloc.last_column = 0;
	return yyparse ();
}
