/* Reverse Polish Notation calculator. */

%code top {
	#include <stdlib.h>
	#include <stdio.h>
	#include <math.h>
	#include <string.h>
	#include <ctype.h>
}

%code requires {
	#include "../common.h"
}

%code provides {
	void init_table(void);
}

%require "3.0.4"

%define api.pure full
%locations

%define api.value.type union

%code {
	int yylex(YYSTYPE *, YYLTYPE *);
	void yyerror(YYLTYPE *, char const *);	
}

%defines

%token <double> NUM
%token <symrec*> VAR FNCT
%type <double> exp
%precedence '='
%left '-''+'
%left '*' '/'
%precedence NEG
%right '^'

%destructor {
	printf("discard symbol named %s, position %lf %lf.\n", $$->name, @$.first_line, @$.first_column); 
} VAR
%destructor {
	printf("discard symbol named %s, position %lf %lf.\n", $$->name, @$.first_line, @$.first_column); 
} FNCT
%destructor {
	printf("discard symbol, position %lf %lf.\n", @$.first_line, @$.first_column); 
} <double>

%printer
{
	fprintf(yyoutput, "%s\n", $$->name);
} VAR
%printer
{
	fprintf(yyoutput, "%s()\n", $$->name);
} FNCT
%printer {
	fprintf(yyoutput, "%d\n", $$); 
} <double>

%%
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
| VAR { $$ = $VAR->value.var; }
| VAR '=' exp { $$ = $3; $1->value.var = $3; }
| FNCT '(' exp ')' { $$ = (*($1->value.fnctptr))($3); }
| exp '+' exp	{ $$ = $1 + $3;	}
| exp '-' exp	{ $$ = $1 - $3;	}
| exp '*' exp	{ $$ = $1 * $3;	}
| exp '/' exp
{
	if($3)
	{
		$$ = $1 / $3;
	}
	else
	{
		$$ = 1;
		fprintf(stderr, "%lf.%lf-%lf.%lf: division by zero\n", @3.first_line, @3.first_column, @3.last_line, @3.last_column);
	}
}
| '-' exp	%prec NEG { $$ = -$2; }
| exp '^' exp	{ $$ = pow($1, $3); }
| '(' exp ')'	{ $$ = $2; }
;
%%

symrec *putsym(char const *sym_name, int sym_type)
{
	symrec *ptr = (symrec *) malloc (sizeof (symrec)); 
	ptr->name = (char *) malloc (strlen (sym_name) + 1); 
	strcpy (ptr->name,sym_name);
	ptr->type = sym_type;
	ptr->value.var = 0; /* Set value to 0 even if fctn.	*/ 
	ptr->next = (struct symrec *)sym_table;
	sym_table = ptr; 
	return ptr;
}

symrec *getsym(char const *sym_name)
{
	symrec *ptr;
	for(ptr = sym_table; ptr != (symrec *) 0; ptr = (symrec *)ptr->next)
	{
		if(strcmp (ptr->name, sym_name) == 0)
		{
			return ptr;
		}
	}
	return 0;
}

/* Called by yyparse on error.	*/ 
void yyerror(YYLTYPE *llocp, char const *s)
{
	fprintf(stderr, "yyerror: %s\n", s);
}

int yylex(YYSTYPE *lvalp, YYLTYPE *llocp)
{
	int c;

	while((c = getchar()) == ' ' || c == '\t')
	{
		++llocp->last_column;
	}

	llocp->first_line = llocp->last_line;
	llocp->first_column = llocp->last_column;

	if(c == EOF)
	{
		return 0;
	}

	if(c == '.' || isdigit (c))
	{
		double decimalSize = 1;
		int dcimalStartMark = 0;
		if(c == '.') 
		{
			dcimalStartMark = 1;
		}

		double num = c - '0';
		++llocp->last_column;
		while(isdigit(c = getchar()) || c == '.')
		{
			if(dcimalStartMark == 1) 
			{
				decimalSize *= 10;
			}

			if(c == '.') {
				dcimalStartMark = 1;
				continue;
			}

			/* update location. */
			++llocp->last_column;

			num = num * 10 + c - '0';
		}

		lvalp->NUM = num / decimalSize;

		ungetc(c, stdin);

		return NUM;
	}

	if(isalpha (c))
	{
		/* Initially make the buffer long enough for a 40-character symbol name.	*/
		static size_t length = 40; 
		static char *symbuf = 0; 
		symrec *s;
		int i;
		if(!symbuf)
		{
			symbuf = (char *) malloc (length + 1); 
		}

		i = 0;
		do
		{
			/* If buffer is full, make it bigger.	*/ 
			if(i == length)
			{
				length *= 2;
				symbuf = (char *)realloc(symbuf, length + 1);
			}

			/* Add this character to the buffer.	*/ 
			symbuf[i++] = c;

			/* Get another character.	*/ 
			c = getchar();

			/* update location. */
			++llocp->last_column;
		}
		while(isalnum(c));

		ungetc(c, stdin); 
		symbuf[i] = '\0';

		/* try to find the symbol */
		s = getsym(symbuf); 

		/* push new symbol */
		if(s == 0)
		{
			s = putsym(symbuf, VAR);
		}

		if(s->type == VAR)
		{
			lvalp->VAR = s;
		}
		else
		{
			lvalp->FNCT = s;
		}
		
		return s->type;
	}

	/* update location. */
	if(c == '\n')
	{
  	++llocp->last_line;
  	llocp->last_column = 0;
  }
  else
  {
  	++llocp->last_column;
  }

	/* Any other character is a token by itself.	*/ 
	return c;
}

struct init
{
	char const *fname; 
	double (*fnct)(double);
};

struct init const arith_fncts[] =
{
	{ "atan", atan },
	{ "cos",	cos	},
	{ "exp",	exp	},
	{ "ln",	log	},
	{ "sin",	sin	},
	{ "sqrt", sqrt },
	{ "ceil", ceil },
	{ "floor", floor },
	{ 0, 0 }
};

struct init_constant
{
	char const *vname; 
	double val;
};

struct init_constant const constants[] =
{
	{ "PI", 3.1415926 },
	{ "ZERO",	0	},
	{ "INFINITE",	99999 },
	{ 0, 0 }
};

/* The symbol table: a chain of 'struct symrec'.	*/ 
symrec *sym_table;

/* Put arithmetic functions in table.	*/ 
void init_table(void)
{
	int i;
	for(i = 0; arith_fncts[i].fname != 0; i++)
	{
		symrec *ptr = putsym (arith_fncts[i].fname, FNCT);
		ptr->value.fnctptr = arith_fncts[i].fnct;
	}

	for(i = 0; constants[i].vname != 0; i++)
	{
		symrec *ptr = putsym(constants[i].vname, VAR);
		ptr->value.var = constants[i].val;
	}
}