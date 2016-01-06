%{

#include "compiler.h"

std::map<std::string, long long int>  variables;
std::vector<std::string> ASMCode;
std::stack<long long int> jumpPlaces;
long long int memoryPointer = 0;

%}

%union {
    char *str;
    long long int num;
    VarType varType;
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
%token <str> ID
%token <num> NUM
%type <varType> expression
%type <varType> identifier
%type <varType> value
%type <varType> condition

%%

program
    : DECLARE vdeclarations IN commands END {appendASMCode("HALT"); saveCodeToFile();}
    ;

vdeclarations
    : vdeclarations ID {
        std::string IDAsString($2);
        if(isVariableDeclared(IDAsString)) yyerror(IDAsString + " is already declared");
        else declareVariable(IDAsString);
    }
    | vdeclarations ID LEFT_PAR NUM RIGHT_PAR {
        std::string IDAsString($2);
        if(isVariableDeclared(IDAsString)) yyerror(IDAsString + " is already declared");
        else declareArray(IDAsString, $4);
    }
    |
    ;

commands
    : commands command
    |
    ;

command
    : identifier ASSIGN expression SEMICOLON{
        if($1.elementIndexAddres == -1) setRegister(0, $1.memoryStart);
        else{
            setRegister(0, $1.memoryStart);
            setRegister(1, $1.elementIndexAddres);
            appendASMCode("LOAD 2 1");
            appendASMCode("ADD 0 2");
        }

        if($3.elementIndexAddres == -1) setRegister(2, $3.memoryStart);
        else{
            setRegister(2, $3.memoryStart);
            setRegister(3, $3.elementIndexAddres);
            appendASMCode("LOAD 4 3");
            appendASMCode("ADD 2 4");
        }
        appendASMCode("LOAD 1 2");

        appendASMCode("STORE 1 0");
    }
    | IF condition THEN commands ENDIF{
        ASMCode[jumpPlaces.top()] += intToString(ASMCode.size());
        jumpPlaces.pop();
    }
    | IF condition THEN commands ELSE commands ENDIF
    | WHILE condition DO commands ENDWHILE
    | FOR ID FROM value TO value DO commands ENDFOR
    | FOR ID DOWN FROM value TO value DO commands ENDFOR
    | GET identifier SEMICOLON
    | PUT value SEMICOLON{
        loadVarToRegister($2, 0);
        appendASMCode("WRITE 0");
    }
    ;

expression
    : value{
        $$ = $1;
    }
    | value ADD value{
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        appendASMCode("ADD 0 1");
        setRegister(1, memoryPointer);
        memoryPointer++;
        appendASMCode("STORE 0 1");

        $$.memoryStart = memoryPointer - 1;
        $$.elementIndexAddres = -1;
    }
    | value SUB value{
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        appendASMCode("SUB 0 1");
        setRegister(1, memoryPointer);
        memoryPointer++;
        appendASMCode("STORE 0 1");
        $$.memoryStart = memoryPointer - 1;
        $$.elementIndexAddres = -1;
    }
    | value MULT value{
        //TODO: Usprawnic ten algorytm
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        setRegister(2, 1);
        appendASMCode("COPY 3 0");
        appendASMCode("RESET 0");
        long long int startingASMLine = ASMCode.size();
        appendASMCode("ADD 0 3");
        appendASMCode("SUB 1 2");
        long long int finishASMLine = ASMCode.size() + 3;
        appendASMCode("JZERO 1 " + intToString(finishASMLine));
        appendASMCode("JUMP " + intToString(startingASMLine));
        setRegister(1, memoryPointer);
        memoryPointer++;
        appendASMCode("STORE 0 1");

        $$.memoryStart = memoryPointer - 1;
        $$.elementIndexAddres = -1;
    }
    | value DIV value{
        //TODO: Usprawnic ten algorytm
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        appendASMCode("RESET 2");
        appendASMCode("INC 0");
        appendASMCode("SUB 0 1");
        long long int finishASMLine = ASMCode.size() + 3;
        appendASMCode("JZERO 0 " + intToString(finishASMLine));
        appendASMCode("INC 2");
        long long int startASMLine = ASMCode.size() - 3;
        appendASMCode("JUMP " + intToString(startASMLine));
        setRegister(0, memoryPointer);
        memoryPointer++;
        appendASMCode("STORE 2 0");

        $$.memoryStart = memoryPointer - 1;
        $$.elementIndexAddres = -1;
    }
    | value MOD value //TODO: Implement this
    ;

condition
    : value EQUAL value
    | value DIFF value{
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        appendASMCode("COPY 2 1");
        appendASMCode("SUB 1 0");
        appendASMCode("SUB 0 2");
        appendASMCode("ADD 0 1");
        jumpPlaces.push(ASMCode.size());
        appendASMCode("JZERO 0 ");
    }
    | value LESS value
    | value MORE value
    | value LESS_EQUAL value
    | value MORE_EQUAL value
    ;

value
    : NUM{
        long long int numAddr = memoryPointer;
        memoryPointer++;

        setRegister(0, $1);
        setRegister(1, numAddr);
        appendASMCode("STORE 0 1");

        $$.memoryStart = numAddr;
        $$.elementIndexAddres = - 1;
    }
    | identifier {$$ = $1;}
    ;

identifier
    : ID {
        std::string IDAsString($1);
        if(!isVariableDeclared(IDAsString)) yyerror(IDAsString + " is undeclared");
        $$.memoryStart = variables[IDAsString];
        $$.elementIndexAddres = -1;
    }
    | ID LEFT_PAR ID RIGHT_PAR{
        std::string ArrayIDAsString($1);
        std::string ArrayCounterIDAsString($3);

        if(!isVariableDeclared(ArrayIDAsString)) yyerror(ArrayIDAsString + " is undeclared");
        if(!isVariableDeclared(ArrayCounterIDAsString)) yyerror(ArrayCounterIDAsString + " is undeclared");

        $$.memoryStart = variables[ArrayIDAsString];
        $$.elementIndexAddres = variables[ArrayCounterIDAsString];

    }
    | ID LEFT_PAR NUM RIGHT_PAR{
        std::string ArrayIDAsString($1);
        if(!isVariableDeclared(ArrayIDAsString)) yyerror(ArrayIDAsString + " is undeclared");

        $$.memoryStart = variables[ArrayIDAsString] + $3;
        $$.elementIndexAddres = -1;
    }
    ;

%%

int main(void) {
	return yyparse();
}
