#ifndef DRIVER_HH
# define DRIVER_HH
# include <string>
# include <map>
# include "parser.hh"

// Tell Flex the lexer’s prototype ...
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
	// The token’s location used by the scanner.
	yy::location location;
	// 
	std::map<std::string, int> variables;
	//
	int result;
	// Run the parser on file F. Return 0 on success.
	int parse (const std::string& f);
	// Handling the scanner.
	void scan_begin ();
	void scan_end ();
};
#endif