#include "./calc/parser.h"

int main(int argc, char const* argv[])
{
	yydebug = 0;
	init_table(); 
	return yyparse();
}