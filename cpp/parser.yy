%skeleton "lalr1.cc" /* -*- C++ -*- */
%require "3.1"
/* write an extra output fle containing macro defnitions for 
the token type names defined in the grammar, as well as a few other declarations */
%defines
%define api.token.constructor
%define api.value.type variant
%define parse.assert

%code requires {
	# include <string>
	class driver;
}

/* Specify that argument-declaration are additional yylex/yyparse argument declaration. */
%param { driver& drv }
/* request location tracking */
%locations
/* enable parser tracing */
%define parse.trace
/* enable verbose error messages */
%define parse.error verbose
/* the code between %code { and } is output in the *.cc fle */
%code {
# include "driver.hh"
}

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

%printer { yyoutput << $$; } <*>;

%%
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