/* Any indented text or text enclosed in ‘%{’ and ‘%}’ is also copied verbatim to the output (with the %{ and %} symbols removed) */
%{ /* -*- C++ -*- */
# include <cerrno>
# include <climits>
# include <cstdlib>
# include <string>
# include "driver.hh"
# include "parser.hh"
// Pacify warnings in yy_init_buffer (observed with Flex 2.6.4)
// and GCC 7.3.0.
#if defined __GNUC__ && 7 <= __GNUC__
# pragma GCC diagnostic ignored "-Wnull-dereference"
#endif

// Code run each time a pattern is matched.
// yyleng	current matched text's length
# define YY_USER_ACTION loc.columns (yyleng);
%}

%option noyywrap nounput batch debug noinput
/* exclusive begin condition */
%x comment

/* definitions section contains declarations of simple name definitions */
/* Defines id to be a regular expression which first matches a single alphabets and then some characters what can be alphabets or digit */
id [a-zA-Z][a-zA-Z_0-9]*
/* Defines id to be a regular expression which can be some digit */
int [0-9]+
/* Defines blank to be a regular expression which can be blank or \t */
blank [ \t]

/* If no match is found, the next character in the input is considered matched and copied to the standard output */
%%
%{
	/* drv is passed as a lex param*/
	// A handy shortcut to the location held by the driver.
	yy::location& loc = drv.location;

	// Code run each time yylex is called. Move begin onto end.
	loc.step ();

	int line_num = 1;
%}
"-" return yy::parser::make_MINUS (loc);
"+" return yy::parser::make_PLUS (loc);
"*" return yy::parser::make_STAR (loc);
"/" return yy::parser::make_SLASH (loc);
"(" return yy::parser::make_LPAREN (loc);
")" return yy::parser::make_RPAREN (loc);
":=" return yy::parser::make_ASSIGN (loc);

{blank}+ loc.step ();

[\n]+ loc.lines (yyleng); loc.step ();

{int} {
	errno = 0;
	// yytext is the current matched text
	long n = strtol (yytext, NULL, 10);
	if (! (INT_MIN <= n && n <= INT_MAX && errno != ERANGE))
		throw yy::parser::syntax_error (loc, "integer is out of range: " + std::string(yytext));
	return yy::parser::make_NUMBER (n, loc);
}

{id} return yy::parser::make_IDENTIFIER (yytext, loc);

. {
	throw yy::parser::syntax_error
	(loc, "invalid character: " + std::string(yytext));
}

"/*"         BEGIN(comment);
<comment>[^*\n]*        /* eat anything that's not a '*' */
<comment>"*"+[^*/\n]*   /* eat up '*'s not followed by '/'s */
<comment>\n             ++line_num;
<comment>"*"+"/"        BEGIN(INITIAL);

"/*" {
	int c;
	for ( ; ; )
	{
	while ( (c = input()) != '*' &&
	        c != EOF )
	    ;    /* eat up text of comment */

	if ( c == '*' )
	    {
	    while ( (c = input()) == '*' )
	        ;
	    if ( c == '/' )
	        break;    /* found the end */
	    }

	if ( c == EOF )
	    {
	    error( "EOF in comment" );
	    break;
	    }
	}
}

<<EOF>> return yy::parser::make_END (loc);
%%

void
driver::scan_begin ()
{
	yy_flex_debug = trace_scanning;

	if (file.empty () || file == "-")
		/* Whenever yylex() is called, 
		it scans tokens from the global input file ‘yyin’ */
		yyin = stdin;
	else if (!(yyin = fopen (file.c_str (), "r")))
	{
		std::cerr << "cannot open " << file << ": " << strerror(errno) << ’\n’;
		exit (EXIT_FAILURE);
	}
}
void
driver::scan_end ()
{
	fclose (yyin);
}