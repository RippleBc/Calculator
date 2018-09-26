/* Any indented text or text enclosed in ‘%{’ and ‘%}’ is also copied verbatim to the output (with the %{ and %} symbols removed) */
%{ /* -*- C++ -*- */
# include <cerrno>
# include <climits>
# include <cstdlib>
# include <string>
# include "driver.hh"
# include "parser.tab.hh"

// Work around an incompatibility in flex (at least versions
// 2.5.31 through 2.5.33): it generates code that does
// not conform to C89. See Debian bug 333231
// <http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=333231>.
# undef yywrap
# define yywrap() 1

// Pacify warnings in yy_init_buffer (observed with Flex 2.6.4)
// and GCC 7.3.0.
#if defined __GNUC__ && 7 <= __GNUC__
# pragma GCC diagnostic ignored "-Wnull-dereference"
#endif

/* Forwarded to the end position. Code run each time a pattern is matched. yyleng	is the length of the most recently matched token */
# define YY_USER_ACTION loc.columns (yyleng);

#define MAX_INCLUDE_DEPTH 10
YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
int include_stack_ptr = 0;
%}

%option 8bit
%option warn nodefault
/* returns the current input line number */
%option yylineno
%option nounput
%option noinput
%option batch
/* sets the debugging flag for the scanner */
%option debug
%option noyywrap
/* Generating C++ Scanners */
%option c++

%x comment
%x str
%x incl

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

[\n]+ loc.lines (yyleng); /* Forwarded to the end position. */ loc.step ();

{int} {
	errno = 0;
	/* yytext is the text of the most recently matched token */
	long n = strtol (yytext, NULL, 10);
	if (! (INT_MIN <= n && n <= INT_MAX && errno != ERANGE))
		throw yy::parser::syntax_error (loc, "integer is out of range: " + std::string(yytext));
	return yy::parser::make_NUMBER (n, loc);
}

{id} return yy::parser::make_IDENTIFIER (yytext, loc);
%%

%%
"/*" BEGIN(comment);

<comment>[^*\n]* /* eat up any character EXCEPT a '*' or a newline */
<comment>[^*\n]*\n ++line_num; /* eat up any character EXCEPT a '*' or a newline followed by a newline */
<comment>"*"+[^*/\n]* /* eat up any number of '*' followed by any character EXCEPT a '*' , a '/' or a '\n' */
<comment>"*"+[^*/\n]*\n ++line_num;
<comment>"*"+"/" BEGIN(INITIAL);
%%

%%
	char string_buf[MAX_STR_CONST];
	char *string_buf_ptr;

\" string_buf_ptr = string_buf; BEGIN(str);

<str>{
	\" {
		/* saw closing quote - all done */
		BEGIN(INITIAL);

		*string_buf_ptr = '\0';

		/* return string constant token type and
		 * value to parser
		 */
		return string_buf_ptr;
	}

	\n {
		printf("error - unterminated string constant");
	}

	\\[0-7]{1,3} {
		/* octal escape sequence */
		int result;

		/* skip first character '\' */
		(void) sscanf( yytext + 1, "%o", &result );

		if ( result > 0xff )
			printf("error, constant is out-of-bounds");

		*string_buf_ptr++ = result;
	}

	\\[0-9]+ {
		/* generate error - bad escape sequence; something
		 * like '\48' or '\0777777'
		 */
	}

	\\n  *string_buf_ptr++ = '\n';
	\\t  *string_buf_ptr++ = '\t';
	\\r  *string_buf_ptr++ = '\r';
	\\b  *string_buf_ptr++ = '\b';
	\\f  *string_buf_ptr++ = '\f';

	\\(.|\n)  *string_buf_ptr++ = yytext[1];

	[^\\\n\"]+ {
		char *yptr = yytext;

		while ( *yptr )
			*string_buf_ptr++ = *yptr++;
	}	
}
%%

%%
include BEGIN(incl);

<incl> {
	[ \t]*	/* eat the whitespace */
	[^ \t\n]+ {
		/* got the include file name */
		if ( include_stack_ptr >= MAX_INCLUDE_DEPTH )
    {
			fprintf( stderr, "Includes nested too deeply" );
			exit( 1 );
    }

		include_stack[include_stack_ptr++] = YY_CURRENT_BUFFER;

		yyin = fopen( yytext, "r" );

		if ( ! yyin )
		    fprintf( stderr, "open include file %s error", yytext);

		yy_switch_to_buffer( yy_create_buffer( yyin, YY_BUF_SIZE ) );

		BEGIN(INITIAL);
	}
}

%%
<<EOF>> {
  if ( --include_stack_ptr == 0 )
  {
  	yyterminate();
  }

  else
  {
	  yy_delete_buffer( YY_CURRENT_BUFFER );
	  yy_switch_to_buffer( include_stack[include_stack_ptr] );
	}
  return yy::parser::make_END(loc);
 }
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