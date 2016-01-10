%{
#include "compiler.h"
#include "compiler.tab.h"
#include <stdio.h>
#include <string.h>
%}
%%

\[[^\]]*\]          ;
[_a-z]+             { yylval.str = strdup(yytext); return ID; }
[_a-z]+[0-9]+       { printf("Error: nierozpoznany napis\n"); exit(0);}
[0-9]+              { yylval.num = atoll(yytext); return NUM; }
"DECLARE"           { return DECLARE; }
"IN"                { return IN; }
"END"               { return END; }
"IF"                { return IF; }
"ELSE"              { return ELSE; }
"ENDIF"             { return ENDIF; }
"FOR"               { return FOR; }
"ENDFOR"            { return ENDFOR; }
"DOWN"              { return DOWN; }
"FROM"              { return FROM; }
"TO"                { return TO; }
"THEN"              { return THEN; }
"WHILE"             { return WHILE; }
"ENDWHILE"          { return ENDWHILE; }
"DO"                { return DO; }
"GET"               { return GET; }
"PUT"               { return PUT; }
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
.                   {printf("Nierozpoznany ciag znakow."); exit(1);}

%%
int yywrap(void) {
    return 1;
}
