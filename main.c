#include "./calc/parser.h"
#include "./calc/scanner.h"

int main(int argc, char const* argv[])
{
	yydebug = 0;
	init_table(); 

	yyscan_t scanner;
	yylex_init(&scanner);
	
	yyparse(scanner);
	
	yylex_destroy(scanner);
}