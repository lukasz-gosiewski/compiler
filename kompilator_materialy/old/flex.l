%option noyywrap
%option yylineno
%{
#include "bison.tab.h"
int yylex();

%}
%x comment

%%

"(*"			BEGIN(comment);
<comment>[^*\n]*        ;
<comment>"*"+[^*)\n]*   ;
<comment>\n             ;
<comment>"*"+")"        BEGIN(INITIAL);

[ \t\r\n]+	{} 	
CONST	{ return(CONST); }
VAR	{ return(VAR); }
BEGIN	{ return(START); }
END	{ return(END); }
":="	{ return(ASSIGN); }
WHILE	{ return(WHILE); }
DO	{ return(DO); }
IF	{ return(IF); }
THEN	{ return(THEN); }
ELSE	{ return(ELSE); }
WRITE	{ return(WRITE); }
READ	{ return(READ); }
"="	{ return(EQUAL); } 
"<"	{ return(LESSER); }
">"	{ return(GREATER); }
"<="	{ return(LEQUAL); }
">="	{ return(GEQUAL); }
"!="	{ return(NEQUAL); }
"+"	{ return(PLUS); }
"-"	{ return(MINUS); }
"*"	{ return(MULTI); }
"/"	{ return(DIV); }
"%"	{ return(MODULO); }
[0-9]+	{    
	     yylval.num = (char *) strdup(yytext);
	     return(NUMBER);
	}
[_a-z]+	{ 
	     yylval.str = (char *) strdup(yytext);
	     return(IDENTIFIER);  
	}
";"	{ return(SEMICOLON); }
.	;
%%
