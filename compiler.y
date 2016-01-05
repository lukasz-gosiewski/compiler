%{

#include <stack>
#include <string>
#include <iostream>
#include <vector>
#include<map>
#include <sstream>
#include <algorithm>
#include <fstream>

void yyerror(std::string s);
int yylex();
int yyparse();

void appendASMCode(std::string code);
void showASMCode();
void declareVariable(std::string var);
void declareArray(std::string array, int size);
bool isVariableDeclared(std::string var);
void setRegister(int registerNumber, int value);
std::string intToString(int value);
std::string binary(unsigned x);
void saveCodeToFile();


std::map<std::string, int>  variables;
std::vector<std::string> ASMCode;
int memoryPointer = 0;

struct VarType{
    int memoryStart;
    int elementIndexAddres;
};
%}

%union {
    struct VarType{
        int memoryStart;
        int elementIndexAddres;
    };

    char *str;
    int num;
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
    : DECLARE vdeclarations IN commands END {appendASMCode("HALT"); showASMCode(); saveCodeToFile();}
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
    : ID ASSIGN expression SEMICOLON{
        
    }
    | IF condition THEN commands ENDIF
    | IF condition THEN commands ELSE commands ENDIF
    | WHILE condition DO commands ENDWHILE
    | FOR ID FROM value TO value DO commands ENDFOR
    | FOR ID DOWN FROM value TO value DO commands ENDFOR
    | GET identifier SEMICOLON
    | PUT value SEMICOLON{
        setRegister(1, $2.memoryStart);
        appendASMCode("LOAD 0 1");
        appendASMCode("WRITE 0");
    }
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
    | value LESS value{
        if($1.elementIndexAddres != -1){
            setRegister(0, $1.memoryStart);
            setRegister(1, $1.elementIndexAddres);
            appendASMCode("LOAD 2 1");
            appendASMCode("ADD 0 2");
        }
        else setRegister(0, $1.memoryStart);

        if($3.elementIndexAddres != -1){
            setRegister(1, $3.memoryStart);
            setRegister(2, $3.elementIndexAddres);
            appendASMCode("LOAD 3 2");
            appendASMCode("ADD 1 3");
        }
        else setRegister(0, $1.memoryStart);

        appendASMCode("LOAD 2 0");
        appendASMCode("LOAD 3 1");
        appendASMCode("SUB 3 2");
        setRegister(2, memoryPointer);
        memoryPointer++;
        appendASMCode("STORE 3 2");
        $$.memoryStart = memoryPointer - 1;
        $$.elementIndexAddres = -1;
    }
    | value MORE value
    | value LESS_EQUAL value
    | value MORE_EQUAL value
    ;

value
    : NUM{
        int numAddr = memoryPointer;
        memoryPointer++;

        setRegister(0, $1);
        setRegister(1, numAddr);
        appendASMCode("STORE 0 1");

        $$.memoryStart = numAddr;
        $$.elementIndexAddres = -1;
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

void yyerror(std::string s) {
	std::cout << "Error: " << s << std::endl;
    exit(1);
}

void appendASMCode(std::string code){
    ASMCode.push_back(code);
}

void showASMCode(){
    for(int i = 0; i < ASMCode.size(); i++){
        std::cout << ASMCode[i] << std::endl;
    }
}

void declareVariable(std::string var){
    variables[var] = memoryPointer;
    memoryPointer++;
}

void declareArray(std::string array, int size){
    variables[array] = memoryPointer;
    memoryPointer += size;
}

bool isVariableDeclared(std::string var){
    std::map<std::string, int>::iterator it = variables.find(var);
    return ( it != variables.end() );
}

void setRegister(int registerNumber, int value){
    std::string binaryNumber = binary(value);

    appendASMCode("RESET " + intToString(registerNumber));
    for(int i = 0; i < binaryNumber.size() - 1; i++){
        if(binaryNumber[i] == '1') appendASMCode("INC " + intToString(registerNumber));
        appendASMCode("SHL " + intToString(registerNumber));
    }
    if(binaryNumber[binaryNumber.size() - 1] == '1') appendASMCode("INC " + intToString(registerNumber));
}

std::string intToString(int value){
    std::stringstream ssval;
    ssval << value;
    return ssval.str();
}

void saveCodeToFile(){
    std::ofstream ofs;
    ofs.open("input.iml", std::ofstream::out | std::ofstream::trunc);
    ofs.close();

    std::ofstream output("input.iml", std::ios_base::app | std::ios_base::out);
    for(int i = 0; i < ASMCode.size(); i++){
        output << ASMCode[i] << std::endl;
    }
    output.close();
}

std::string binary(unsigned x){
    std::string s;
    do
    {
        s.push_back('0' + (x & 1));
    } while (x >>= 1);
    std::reverse(s.begin(), s.end());
    return s;

}
