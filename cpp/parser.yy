%skeleton "lalr1.cc" /* -*- C++ -*- */
%require "3.1"
/* write an extra output fle containing macro defnitions for the token type names defined in the grammar,
 as well as a few other declarations */
%defines
/* When variant-based semantic values are enabled (see Section 10.1.2.2
[C++ Variants], page 158), request that symbols be handled as a whole (type,
value, and possibly location) in the scanner. */
%define api.token.constructor
/* This is similar to union,
 but special storage techniques are used to allow any kind of C++ object to be used. */
%define api.value.type variant
/*  In C++, when variants are used (see Section 10.1.2.2 [C++ Variants], page 158),
 symbols must be constructed and destroyed properly. This option checks these constraints. */
%define parse.assert

%code requires {
	# include <string>
	class driver;
}

/* Specify that argument-declaration are additional yylex/yyparse argument declaration. */
%param { driver& drv }
/* Generate the code processing the locations */
%locations
/* enable parser tracing */
%define parse.trace
/* enable verbose error messages */
%define parse.error verbose
/* the code between %code { and } is output in the *.cc file */
%code {
# include "driver.hh"
}

/* Add a prefx to the token names when generating their defnition in the target language.
 For instanceFor generates the defnition of the symbols TOK_ND, TOK_ASSIGN ...*/
%define api.token.prefix {TOK_}

%token
END 0 "end of file"
ASSIGN ":="
MINUS "-"
PLUS "+"
STAR "*"
SLASH "/"
LPAREN "("
RPAREN ")"
;

%token <std::string> IDENTIFIER "identifier"
%token <int> NUMBER "number"
%type <int> exp

%left "+" "-";
%left "*" "/";

/* when the parser print any symbol that has a semantic type tag, 
it display the semantic value by default */
%printer { yyoutput << $$; } <*>;

%%
/* Bison assumes by default that the start symbol for the grammar is the first nonterminal specifed in the grammar specifcation section. 
The programmer may override this restrictionwith the %start declaration */
%start unit;

unit: assignments exp { drv.result = $2; };

assignments:
%empty {}
| assignments assignment {};

assignment:
"identifier" ":=" exp { drv.variables[$1] = $3; };

exp:
exp "+" exp { $$ = $1 + $3; }
| exp "-" exp { $$ = $1 - $3; }
| exp "*" exp { $$ = $1 * $3; }
| exp "/" exp { $$ = $1 / $3; }
| "(" exp ")" { std::swap ($$, $2); }
| "identifier" { $$ = drv.variables[$1]; }
| "number" { std::swap ($$, $1); };
%%

void
yy::parser::error (const location_type& l, const std::string& m)  
{
	std::cerr << l << ": " << m << ’\n’;
}