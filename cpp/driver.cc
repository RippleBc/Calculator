#include "driver.hh"

driver::driver ()
: trace_parsing (false), trace_scanning (false)
{
	variables["one"] = 1;
	variables["two"] = 2;
}

int
driver::parse (const std::string &f)
{
	file = f;
	/* Reset the location to an empty range at the given values. */
	location.initialize (&file);
	scan_begin ();
	yy::parser parser (*this);
	parser.set_debug_level (trace_parsing);
	int res = parser.parse ();
	scan_end ();
	return res;
}