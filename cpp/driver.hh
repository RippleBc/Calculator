#ifndef DRIVER_HH
# define DRIVER_HH
# include <string>
# include <map>
# include "parser.tab.hh"

/* If you specifed both %define api.value.type variant and %define api.token.constructor,
the parser class also defines the class parser::symbol_type which defnes a complete symbol, 
aggregating its type (i.e., the traditional value returned by yylex), 
its semantic value (i.e., the value passed in yylval), and possibly its location (yylloc) */     
# define YY_DECL yy::parser::symbol_type yylex (driver& drv)
// declare it for the parser’s sake.
YY_DECL;

// Conducting the whole scanning and parsing of Calc++.
class driver {
public:
	driver ();

	// The name of the file being parsed.
	std::string file;
	// Whether to generate parser debug traces.
	bool trace_parsing;
	// Whether to generate scanner debug traces.
	bool trace_scanning;
	/* Create a Location. */
	yy::location location;
	// Used to record variable.
	std::map<std::string, int> variables;
	// Used to record the result of the program
	int result;
	// Run the parser on file F. Return 0 on success.
	int parse (const std::string& f);
	// Handling the scanner.
	void scan_begin ();
	void scan_end ();
};
#endif