#include "compiler.h"

extern std::vector<CustomVariable>  variables;
extern std::vector<std::string> ASMCode;
extern std::stack<long long int> jumpPlaces;
extern long long int memoryPointer;
extern std::stack<CustomIterator> iterators;

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
	CustomVariable vari;
	vari.memoryAdress = memoryPointer;
	vari.name = var;
	vari.isIterator = false;
	vari.isInit = false;
	vari.isArray = false;
	variables.push_back(vari);
    memoryPointer++;
}

void declareArray(std::string array, long long int size){
	CustomVariable var;
	var.memoryAdress = memoryPointer;
	var.name = array;
	var.isInit = false;
	var.isIterator = false;
	var.isArray = true;
	variables.push_back(var);
    memoryPointer += size;
}

bool isVariableDeclared(std::string var){

	for(int i = 0; i < variables.size(); i++){
		if(variables[i].name == var) return true;
	}
	return false;
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

CustomVariable findVarByName(std::string name){
	for(int i = variables.size() - 1; i >= 0; i--){
		if(variables[i].name == name) return variables[i];
	}
}

bool isIterator(long long int var){
	for(int i = variables.size() -1; i >= 0; i--){
		if(var == variables[i].memoryAdress && variables[i].isIterator == true) {
			return true;
		}
	}
	return false;
}

void setInitialized(long long int var){
	for(int i = variables.size() -1; i >= 0; i--){
		if(var == variables[i].memoryAdress) {
			CustomVariable cus = variables[i];
			cus.isInit = true;
			variables[i] = cus;
			return;
		}
	}
}

bool isVariableInitialized(long long int var){
	for(int i = variables.size() - 1; i >= 0; i--){
		if(var == variables[i].memoryAdress) {
			return variables[i].isInit;
		}
	}
}

std::string findVariableNameByAddr(long long int var){
	for(int i = variables.size() -1; i >= 0; i--){
		if(var == variables[i].memoryAdress) {
			return variables[i].name;
		}
	}
}

bool isArray(std::string name){
	for(int i = variables.size() -1; i >= 0; i--){
		if(name == variables[i].name && variables[i].isArray == true) {
			return true;
		}
	}
	return false;
}
