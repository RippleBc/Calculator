/* Generate the parser description file. */
%verbose
/* Enable run-time traces (yydebug). */
%define parse.trace
/* activate a more powerful parser table construction
algorithm */
%define lr.type ielr

%%
def: param_spec return_spec ',';

param_spec:
type
| name_list ':' type
;

return_spec:
type
| name ':' type
;

type: "id";

name: "id";

name_list:
name
| name ',' name_list
;
%%