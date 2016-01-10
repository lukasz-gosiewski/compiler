%{

#include "compiler.h"

std::vector<CustomVariable>  variables;
std::vector<std::string> ASMCode;
std::stack<long long int> jumpPlaces;
long long int memoryPointer = 0;
std::stack<CustomIterator> iterators;

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
%type <varType> iterator

%%

program
    : DECLARE vdeclarations IN commands END {
        appendASMCode("HALT");
        saveCodeToFile();
    }
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
        if(isIterator($1)) yyerror("You cannot modify iterator");
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
        jumpPlaces.pop();
    }
    | IF condition THEN commands{} ELSE{
            ASMCode[jumpPlaces.top()] += intToString(ASMCode.size() + 1);
            jumpPlaces.pop();
            jumpPlaces.push(ASMCode.size());
            appendASMCode("JUMP ");
        } commands ENDIF{
            ASMCode[jumpPlaces.top()] += intToString(ASMCode.size());
            jumpPlaces.pop();
            jumpPlaces.pop();
        }
    | WHILE condition DO commands ENDWHILE{
        ASMCode[jumpPlaces.top()] += intToString(ASMCode.size() + 1);
        jumpPlaces.pop();

        appendASMCode("JUMP " + intToString(jumpPlaces.top()));
        jumpPlaces.pop();
    }
    | FOR iterator FROM value TO value{
        loadVarToRegister($4, 0);
        setRegister(1, iterators.top().memoryAdress);
        appendASMCode("STORE 0 1");

        loadVarToRegister($4, 0);
        loadVarToRegister($6, 1);

        appendASMCode("SUB 1 0");
        appendASMCode("INC 1");
        setRegister(0, memoryPointer);
        appendASMCode("STORE 1 0");
        iterators.top().iterationsToFinishAddr = memoryPointer;
        memoryPointer++;

        jumpPlaces.push(ASMCode.size());
        setRegister(1, iterators.top().iterationsToFinishAddr);
        appendASMCode("LOAD 0 1");
        jumpPlaces.push(ASMCode.size());
        appendASMCode("JZERO 0 ");

        appendASMCode("DEC 0");
        setRegister(1, iterators.top().iterationsToFinishAddr);
        appendASMCode("STORE 0 1");
    }
    DO commands ENDFOR{
        setRegister(1, iterators.top().memoryAdress);
        appendASMCode("LOAD 0 1");
        appendASMCode("INC 0");
        setRegister(1, iterators.top().memoryAdress);
        appendASMCode("STORE 0 1");

        ASMCode[jumpPlaces.top()] += intToString(ASMCode.size() + 1);
        jumpPlaces.pop();
        appendASMCode("JUMP " + intToString(jumpPlaces.top()));
        jumpPlaces.pop();

        variables.erase(variables.begin() + iterators.top().placeInVector);
        iterators.pop();
    }
    | FOR iterator DOWN FROM value TO value DO commands ENDFOR
    | GET identifier SEMICOLON{
        if($2.elementIndexAddres == -1) setRegister(1, $2.memoryStart);
        else{
            setRegister(1, $2.memoryStart);
            setRegister(2, $2.elementIndexAddres);
            appendASMCode("LOAD 3 2");
            appendASMCode("ADD 1 3");
        }

        appendASMCode("READ 0");
        appendASMCode("STORE 0 1");

    }
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
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);
        appendASMCode("RESET 2");

        appendASMCode("JODD 1 " + intToString(ASMCode.size() + 5));
        appendASMCode("SHL 0");
        appendASMCode("SHR 1");
        appendASMCode("JZERO 1 " + intToString(ASMCode.size() + 5));
        appendASMCode("JUMP " + intToString(ASMCode.size() - 4));
        appendASMCode("ADD 2 0");
        appendASMCode("DEC 1");
        appendASMCode("JUMP " + intToString(ASMCode.size() - 6));

        setRegister(0, memoryPointer);
        memoryPointer++;
        appendASMCode("STORE 2 0");

        $$.memoryStart = memoryPointer - 1;
        $$.elementIndexAddres = -1;
    }
    | value DIV value{
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);
        appendASMCode("RESET 4");

        appendASMCode("JZERO 0 " + intToString(ASMCode.size() + 21));
        appendASMCode("JZERO 1 " + intToString(ASMCode.size() + 20));

        appendASMCode("COPY 2 1");
        appendASMCode("SHL 2");
        appendASMCode("COPY 3 2");
        appendASMCode("SUB 3 0");
        appendASMCode("JZERO 3 " + intToString(ASMCode.size() - 3));

        appendASMCode("SHR 2");
        appendASMCode("COPY 3 2");
        appendASMCode("INC 3");
        appendASMCode("SUB 3 1");
        appendASMCode("JZERO 3 " + intToString(ASMCode.size() + 10));
        appendASMCode("SHL 4");
        appendASMCode("COPY 3 0");
        appendASMCode("INC 3");
        appendASMCode("SUB 3 2");
        appendASMCode("JZERO 3 " + intToString(ASMCode.size() + 3));
        appendASMCode("SUB 0 2");
        appendASMCode("INC 4");
        appendASMCode("SHR 2");
        appendASMCode("JUMP " + intToString(ASMCode.size() - 12));

        setRegister(0, memoryPointer);
        memoryPointer++;
        appendASMCode("STORE 4 0");

        $$.memoryStart = memoryPointer - 1;
        $$.elementIndexAddres = -1;
    }
    | value MOD value{
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        appendASMCode("JZERO 0 " + intToString(ASMCode.size() + 19));
        appendASMCode("JZERO 1 " + intToString(ASMCode.size() + 19));

        appendASMCode("COPY 2 1");
        appendASMCode("SHL 2");
        appendASMCode("COPY 3 2");
        appendASMCode("SUB 3 0");
        appendASMCode("JZERO 3 " + intToString(ASMCode.size() - 3));

        appendASMCode("SHR 2");
        appendASMCode("COPY 3 2");
        appendASMCode("INC 3");
        appendASMCode("SUB 3 1");
        appendASMCode("JZERO 3 " + intToString(ASMCode.size() + 8));
        appendASMCode("COPY 3 0");
        appendASMCode("INC 3");
        appendASMCode("SUB 3 2");
        appendASMCode("JZERO 3 " + intToString(ASMCode.size() + 2));
        appendASMCode("SUB 0 2");
        appendASMCode("SHR 2");
        appendASMCode("JUMP " + intToString(ASMCode.size() - 10));
        appendASMCode("JUMP " + intToString(ASMCode.size() + 2));
        appendASMCode("RESET 0");

        setRegister(1, memoryPointer);
        memoryPointer++;
        appendASMCode("STORE 0 1");

        $$.memoryStart = memoryPointer - 1;
        $$.elementIndexAddres = -1;
    }
    ;

condition
    : value EQUAL value{
        jumpPlaces.push(ASMCode.size());
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        appendASMCode("COPY 2 1");
        appendASMCode("SUB 1 0");
        appendASMCode("SUB 0 2");
        appendASMCode("ADD 0 1");

        std::string targetLine = intToString(ASMCode.size() + 3);
        appendASMCode("JZERO 0 " + targetLine);
        appendASMCode("RESET 0");
        targetLine = intToString(ASMCode.size() + 2);
        appendASMCode("JUMP " + targetLine);
        appendASMCode("INC 0");
        jumpPlaces.push(ASMCode.size());
        appendASMCode("JZERO 0 ");

    }
    | value DIFF value{
        jumpPlaces.push(ASMCode.size());
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        appendASMCode("COPY 2 1");
        appendASMCode("SUB 1 0");
        appendASMCode("SUB 0 2");
        appendASMCode("ADD 0 1");
        jumpPlaces.push(ASMCode.size());
        appendASMCode("JZERO 0 ");
    }
    | value LESS value{
        jumpPlaces.push(ASMCode.size());
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        appendASMCode("SUB 1 0");
        jumpPlaces.push(ASMCode.size());
        appendASMCode("JZERO 1 ");
    }
    | value MORE value{
        jumpPlaces.push(ASMCode.size());
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        appendASMCode("SUB 0 1");
        jumpPlaces.push(ASMCode.size());
        appendASMCode("JZERO 0 ");
    }
    | value LESS_EQUAL value{
        jumpPlaces.push(ASMCode.size());
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        appendASMCode("INC 1");
        appendASMCode("SUB 1 0");
        jumpPlaces.push(ASMCode.size());
        appendASMCode("JZERO 1 ");
    }
    | value MORE_EQUAL value{
        jumpPlaces.push(ASMCode.size());
        loadVarToRegister($1, 0);
        loadVarToRegister($3, 1);

        appendASMCode("INC 0");
        appendASMCode("SUB 0 1");
        jumpPlaces.push(ASMCode.size());
        appendASMCode("JZERO 0 ");
    }
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
        $$.memoryStart = findVarByName(IDAsString).memoryAdress.memoryStart;
        $$.elementIndexAddres = -1;
    }
    | ID LEFT_PAR ID RIGHT_PAR{
        std::string ArrayIDAsString($1);
        std::string ArrayCounterIDAsString($3);

        if(!isVariableDeclared(ArrayIDAsString)) yyerror(ArrayIDAsString + " is undeclared");
        if(!isVariableDeclared(ArrayCounterIDAsString)) yyerror(ArrayCounterIDAsString + " is undeclared");

        $$.memoryStart = findVarByName(ArrayIDAsString).memoryAdress.memoryStart;
        $$.elementIndexAddres = findVarByName(ArrayIDAsString).memoryAdress.elementIndexAddres;

    }
    | ID LEFT_PAR NUM RIGHT_PAR{
        std::string ArrayIDAsString($1);
        if(!isVariableDeclared(ArrayIDAsString)) yyerror(ArrayIDAsString + " is undeclared");

        $$.memoryStart = findVarByName(ArrayIDAsString).memoryAdress.memoryStart + $3;
        $$.elementIndexAddres = -1;
    }
    ;

iterator
    : ID {
        CustomVariable var;
        var.memoryAdress.memoryStart = memoryPointer;
        var.memoryAdress.elementIndexAddres = -1;
        var.name = $1;
        memoryPointer++;
        var.isIterator = true;
        variables.push_back(var);

        CustomIterator iter;
        iter.name = $1;
        iter.memoryAdress = memoryPointer - 1;
        iter.placeInVector = variables.size() - 1;
        iterators.push(iter);

        $$.memoryStart = iter.memoryAdress;
        $$.elementIndexAddres = -1;
    }
    ;

%%

int main(void) {
	return yyparse();
}
