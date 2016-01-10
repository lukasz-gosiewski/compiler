#ifndef COMPILER_H
#define COMPILER_H

#include <stack>
#include <string>
#include <iostream>
#include <vector>
#include <map>
#include <sstream>
#include <algorithm>
#include <fstream>

typedef struct{
    long long int memoryStart;
    long long int elementIndexAddres;
} VarType;

typedef struct{
    std::string name;
    long long int memoryAdress;
    bool isIterator;
} CustomVariable;

typedef struct{
    int placeInVector;
    std::string name;
    int memoryAdress;
    int iterationsToFinishAddr;
} CustomIterator;

extern std::vector<CustomVariable>  variables;
extern std::vector<std::string> ASMCode;
extern std::stack<long long int> jumpPlaces;
extern long long int memoryPointer;
extern std::stack<CustomIterator> iterators;

void yyerror(std::string s);
int yylex();
int yyparse();

void appendASMCode(std::string code);
void showASMCode();
void declareVariable(std::string var);
void declareArray(std::string array, long long int size);
bool isVariableDeclared(std::string var);
void setRegister(int registerNumber, long long int value);
std::string intToString(long long int value);
std::string binary(long long int x);
void saveCodeToFile();
void loadVarToRegister(VarType var, int registerNumber);
CustomVariable findVarByName(std::string name);
bool isIterator(long long int addr);

#endif
