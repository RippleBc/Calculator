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

	typedef void* yyscan_t;
}

%code provides {
	void init_table(void);
}

%require "3.0.4"

%define api.pure full
%locations

%param {yyscan_t scanner}

%define api.value.type union

%code {
	int yylex(YYSTYPE *, YYLTYPE *, yyscan_t);
	void yyerror(YYLTYPE *, yyscan_t, char const *);	
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
void yyerror(YYLTYPE *llocp, yyscan_t scanner, char const *s)
{
	fprintf(stderr, "yyerror: %s\n", s);
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