%{
#include "compiler.h"
#include "compiler.tab.h"
#include <stdio.h>
#include <string.h>
%}
%%

[_a-z]+             { yylval.str = strdup(yytext); return ID; }
[0-9]+              { yylval.num = atoll(yytext); return NUM; }
"DECLARE"           { return DECLARE; }
"IN"                { return IN; }
"END"               { return END; }
"FOR"               { return FOR; }
"DOWN"              { return DOWN; }
"FROM"              { return FROM; }
"TO"                { return TO; }
"ENDFOR"            { return ENDFOR; }
"IF"                { return IF; }
"THEN"              { return THEN; }
"ELSE"              { return ELSE; }
"ENDIF"             { return ENDIF; }
"GET"               { return GET; }
"PUT"               { return PUT; }
"WHILE"             { return WHILE; }
"DO"                { return DO; }
"ENDWHILE"          { return ENDWHILE; }
"="                 { return EQUAL; }
"+"                 { return ADD; }
"-"                 { return SUB; }
"*"                 { return MULT; }
"/"                 { return DIV; }
"%"                 { return MOD; }
"!="                { return DIFF; }
";"                 { return SEMICOLON; }
":="                { return ASSIGN; }
"<"                 { return LESS; }
">"                 { return MORE; }
"<="                { return LESS_EQUAL; }
">="                { return MORE_EQUAL; }
"("                 { return LEFT_PAR; }
")"                 { return RIGHT_PAR; }
[ \t\n]             ;
.                   ;

%%
int yywrap(void) {
    return 1;
}
