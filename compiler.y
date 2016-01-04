%{

#include <stack>
#include <string>
#include <iostream>
#include <vector>

void yyerror(std::string s);
int yylex();
int yyparse();

std::stack<long long int> memory;
std::vector<std::string> resultCode;

%}

%union {
    char *str;
    int num;
}

%token DECLARE
%token IN
%token END
%token FOR
%token DOWN
%token FROM
%token TO
%token ENDFOR
%token IF
%token THEN
%token ELSE
%token ENDIF
%token GET
%token PUT
%token WHILE
%token DO
%token ENDWHILE
%token EQUAL
%token ADD
%token SUB
%token MULT
%token DIV
%token MOD
%token DIFF
%token SEMICOLON
%token ASSIGN
%token LESS
%token MORE
%token LESS_EQUAL
%token MORE_EQUAL
%token LEFT_PAR
%token RIGHT_PAR
%token<str> ID
%token<num> NUM

%%

program
    : DECLARE vdeclarations IN commands END {appendASMCode("HALT")}
    ;

vdeclarations
    : vdeclarations ID
    | vdeclarations ID LEFT_PAR NUM RIGHT_PAR
    |
    ;

commands
    : commands command
    |
    ;

command
    : ID ASSIGN expression SEMICOLON
    | IF condition THEN commands ENDIF
    | IF condition THEN commands ELSE commands ENDIF
    | WHILE condition DO commands ENDWHILE
    | FOR ID FROM value TO value DO commands ENDFOR
    | FOR ID DOWN FROM value TO value DO commands ENDFOR
    | GET identifier SEMICOLON
    | PUT value SEMICOLON
    ;

expression
    : value
    | value ADD value
    | value SUB value
    | value MULT value
    | value DIV value
    | value MOD value
    ;

condition
    : value EQUAL value
    | value DIFF value
    | value LESS value
    | value MORE value
    | value LESS_EQUAL value
    | value MORE_EQUAL value
    ;

value
    : NUM
    | identifier
    ;

identifier
    : ID
    | ID LEFT_PAR ID RIGHT_PAR
    | ID LEFT_PAR NUM RIGHT_PAR
    ;

%%

int main(void) {
	return yyparse();
}

void yyerror(std::string s) {
	std::cout << "Error: " << s << std::endl;
}

void appendASMCode(std::string code){

    std::cout << code << std::endl;
}
