#include "compiler.h"

extern std::map<std::string, long long int>  variables;
extern std::vector<std::string> ASMCode;
extern std::stack<long long int> jumpPlaces;
extern long long int memoryPointer;

void yyerror(std::string s) {
	std::cout << "Error: " << s << std::endl;
    exit(1);
}

void appendASMCode(std::string code){
    ASMCode.push_back(code);
}

void showASMCode(){
    for(long long int i = 0; i < ASMCode.size(); i++){
        std::cout << ASMCode[i] << std::endl;
    }
}

void declareVariable(std::string var){
    variables[var] = memoryPointer;
    memoryPointer++;
}

void declareArray(std::string array, long long int size){
    variables[array] = memoryPointer;
    memoryPointer += size;
}

bool isVariableDeclared(std::string var){
    std::map<std::string, long long int>::iterator it = variables.find(var);
    return ( it != variables.end() );
}

void setRegister(int registerNumber, long long int value){
    std::string binaryNumber = binary(value);

    appendASMCode("RESET " + intToString(registerNumber));
    for(long long int i = 0; i < binaryNumber.size() - 1; i++){
        if(binaryNumber[i] == '1') appendASMCode("INC " + intToString(registerNumber));
        appendASMCode("SHL " + intToString(registerNumber));
    }
    if(binaryNumber[binaryNumber.size() - 1] == '1') appendASMCode("INC " + intToString(registerNumber));
}

std::string intToString(long long int value){
    std::stringstream ssval;
    ssval << value;
    return ssval.str();
}

void saveCodeToFile(){
    std::ofstream ofs;
    ofs.open("input.iml", std::ofstream::out | std::ofstream::trunc);
    ofs.close();

    std::ofstream output("input.iml", std::ios_base::app | std::ios_base::out);
    for(long long int i = 0; i < ASMCode.size(); i++){
        output << ASMCode[i] << std::endl;
    }
    output.close();
}

std::string binary(long long int x){
    std::string s;
    do{
        s.push_back('0' + (x & 1));
    } while (x >>= 1);
    std::reverse(s.begin(), s.end());
    return s;
}

void loadVarToRegister(VarType var, int registerNumber){
    if(var.elementIndexAddres == -1) setRegister(registerNumber+1, var.memoryStart);
    else{
        setRegister(registerNumber+1, var.memoryStart);
        setRegister(registerNumber+2, var.elementIndexAddres);
        appendASMCode("LOAD " + intToString(registerNumber+3) + " " + intToString(registerNumber+2));
        appendASMCode("ADD " + intToString(registerNumber+1) + " " + intToString(registerNumber+3));
    }
    appendASMCode("LOAD " + intToString(registerNumber) + " " + intToString(registerNumber+1));
}
