%{
#include <stdio.h>
#include <string>
#include <vector>
#include <iostream>

const int LINELENGTH = 10;

using namespace std;



typedef struct 
{
    string name;
    string value;
    bool isConst;
} Symbol;

char *tmp = new char[LINELENGTH]; 
int symbolTableSize=0;
int outputCodeSize=0;
vector<Symbol> symbolTable;
vector<int> tmpJmpStack;
vector<string> outputCode;

void errorCatched(string text);
void addOutputCodeLine(string text);
int getSymbolMemIndex(string name);

int yylex(void);
extern int yylineno;
int yyerror(const char *error) 
{ 
    sprintf(tmp, "BLAD: Linia %d - %s", yylineno, error ); 
    errorCatched(tmp);
}

%}


%union{ char *str; char *num;}
%token <str> CONST
%token <str> VAR
%token <str> START
%token <str> END
%token <str> LCOMMENT
%token <str> RCOMMENT
%token <str> IF
%token <str> THEN
%token <str> ELSE
%token <str> WHILE
%token <str> DO
%token <str> READ
%token <str> WRITE
%token <str> ASSIGN
%token <str> PLUS
%token <str> MINUS
%token <str> MULTI
%token <str> DIV
%token <str> MODULO
%token <str> EQUAL
%token <str> LEQUAL
%token <str> GEQUAL
%token <str> LESSER
%token <str> GREATER
%token <str> NEQUAL
%token <num> NUMBER 
%token <str> IDENTIFIER
%token <str> SEMICOLON

%%
program : 	| 
		CONST 
		{
		    Symbol newSymbol = {"__one", "1", true};
		    symbolTable.push_back(newSymbol);
		    symbolTableSize++;
		    
		    sprintf(tmp, "SET %d %s", symbolTableSize-1, newSymbol.value.c_str()); 
		    addOutputCodeLine(tmp);
		}
		cdeclarations VAR vdeclarations START commands END
		{
		    addOutputCodeLine("HALT");
		}
	   
;

cdeclarations : cdeclarations IDENTIFIER EQUAL NUMBER
		{
		    if(getSymbolMemIndex($<str>2) != -1)
		    {
			sprintf(tmp, "BLAD: Linia %d - redelaracja %s", yylineno, $<str>2);
			errorCatched(tmp);
		    }
		    Symbol newSymbol = {$<str>2, $<num>4, true};
		    symbolTable.push_back(newSymbol);
		    symbolTableSize++;
		    sprintf(tmp, "SET %d %s", symbolTableSize-1, newSymbol.value.c_str()); 
		    addOutputCodeLine(tmp);
		}
		|
		
;

vdeclarations : vdeclarations IDENTIFIER
		{
		    if(getSymbolMemIndex($<str>2) != -1)
		    {
			sprintf(tmp, "BLAD: Linia %d - redeklaracja %s", yylineno, $<str>2);
			errorCatched(tmp);
		    }
		    Symbol newSymbol = {$<str>2, "", false};
		    symbolTable.push_back(newSymbol);
		    symbolTableSize++;
		}
		|	
;

commands : commands command
      	   |
;

command : IDENTIFIER ASSIGN expression SEMICOLON
	{
	    
	    int index = getSymbolMemIndex($<str>1);	    
	    if (index != -1)
	    {	
		if (symbolTable.at(index).isConst)
		{
		    sprintf(tmp, "BLAD: Linia %d - proba przypisania wartosci stalej %s", yylineno, $<str>1);
		    errorCatched(tmp);
		}
		sprintf(tmp, "STORE 0 %d", index); 
		addOutputCodeLine(tmp);
	   }
	   else
	   {
		sprintf(tmp, "BLAD: Linia %d - nie zadelarowana zmienna %s", yylineno, $<str>1);
		errorCatched(tmp);
	   }
	    
	}
        | IF 
	{
	    tmpJmpStack.push_back(outputCode.size()-1);
	}
	condition THEN commands
	{
	    
	    sprintf(tmp,"%s %d", outputCode.at(tmpJmpStack.at(tmpJmpStack.size()-1)).c_str(), (int)outputCode.size()+1);
	    outputCode.at(tmpJmpStack.at(tmpJmpStack.size()-1)) = tmp;
	    tmpJmpStack.pop_back();
	    sprintf(tmp, "JUMP"); 
	    addOutputCodeLine(tmp);
	    tmpJmpStack.push_back(outputCode.size()-1);
	}	
	ELSE commands END
	{
	    
	    sprintf(tmp,"%s %d", outputCode.at(tmpJmpStack.at(tmpJmpStack.size()-1)).c_str(), (int)outputCode.size());
	    outputCode.at(tmpJmpStack.at(tmpJmpStack.size()-1)) = tmp;
	    tmpJmpStack.pop_back();
	}
        | WHILE 
	{
	    tmpJmpStack.push_back(outputCode.size());
	    tmpJmpStack.push_back(outputCode.size()-1);
	}	
	condition DO commands END
	{
	    
	    sprintf(tmp,"%s %d", outputCode.at(tmpJmpStack.at(tmpJmpStack.size()-1)).c_str(), (int)outputCode.size()+1);
	    outputCode.at(tmpJmpStack.at(tmpJmpStack.size()-1)) = tmp;
	    tmpJmpStack.pop_back();
	    sprintf(tmp, "JUMP %d", tmpJmpStack.at(tmpJmpStack.size()-1)); 
	    addOutputCodeLine(tmp);
	    tmpJmpStack.pop_back();
	}	
        | READ IDENTIFIER SEMICOLON
	{ 
	    int index = getSymbolMemIndex($<str>2);	    
	    if (index != -1)
	    {
		if (symbolTable.at(index).isConst)
		{
		    sprintf(tmp, "BLAD: Linia %d - proba wczytania wartosci stalej %s", yylineno, $<str>2);
		    errorCatched(tmp);
		}
		sprintf(tmp, "READ %d", index); 
		addOutputCodeLine(tmp);
	    }
	    else
	    {
		sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>2);
		errorCatched(tmp);
	    }
	}
        | WRITE IDENTIFIER SEMICOLON
	{ 
	    int index = getSymbolMemIndex($<str>2);	    
	    if (index != -1)
	    {
		sprintf(tmp, "WRITE %d", index); 
		addOutputCodeLine(tmp);
	    }
	    else
	    {
		sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>2);
		errorCatched(tmp);
	    }
	}
;

expression : IDENTIFIER
	   {
	       int index = getSymbolMemIndex($<str>1);
	       if (index !=-1)
	       {
		   sprintf(tmp, "LOAD 0 %d", index); 
		   addOutputCodeLine(tmp);
	       }
	       else
	       {
		   sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		   errorCatched(tmp);
	       }	
	   }
	   | IDENTIFIER PLUS IDENTIFIER
	   {
	       int index1 = getSymbolMemIndex($<str>1);
	       int index2 = getSymbolMemIndex($<str>3);
	       if ((index1 !=-1) && (index2 !=-1))
	       {
		   sprintf(tmp, "LOAD 0 %d", index1);
		   addOutputCodeLine(tmp);
		   sprintf(tmp, "LOAD 1 %d", index2);
		   addOutputCodeLine(tmp);
		   addOutputCodeLine("ADD 0 1");
	       }
	       if (index1 ==-1)
	       {
		   sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		   errorCatched(tmp);
	       }
	       if (index2 ==-1)
	       {
		   sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>3);
		   errorCatched(tmp);
	       }
	   }
           | IDENTIFIER MINUS IDENTIFIER
	   {
	       int index1 = getSymbolMemIndex($<str>1);
	       int index2 = getSymbolMemIndex($<str>3);
	       if ((index1 !=-1) && (index2 !=-1))
	       {
		   sprintf(tmp, "LOAD 0 %d", index1);
		   addOutputCodeLine(tmp);
		   sprintf(tmp, "LOAD 1 %d", index2);
		   addOutputCodeLine(tmp);
		   addOutputCodeLine("SUB 0 1");
	       }
	       if (index1 ==-1)
	       {
		   sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		   errorCatched(tmp);
	       }
	       if (index2 ==-1)
	       {
		   sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>3);
		   errorCatched(tmp);
	       }
	   }
           | IDENTIFIER MULTI IDENTIFIER
	   {
	   	int index1 = getSymbolMemIndex($<str>1);
	   	int index2 = getSymbolMemIndex($<str>3);   		
		if (index1 != -1 && index2 != -1)
		{
		     sprintf(tmp, "SUB 0 0", symbolTableSize);
		     addOutputCodeLine(tmp);
		     sprintf(tmp, "LOAD 1 %d", index1);
		     addOutputCodeLine(tmp);
		     sprintf(tmp, "LOAD 2 %d", index2);
		     addOutputCodeLine(tmp);
		     int codeLineCount = outputCodeSize;
		     sprintf(tmp, "JODD 2 %d", codeLineCount+5);
		     addOutputCodeLine(tmp);
		     addOutputCodeLine("ADD 1 1");
		     addOutputCodeLine("HALF 2");
		     sprintf(tmp, "JZ 2 %d", codeLineCount+7);
		     addOutputCodeLine(tmp);
		     sprintf(tmp, "JUMP %d", codeLineCount);
		     addOutputCodeLine(tmp);
		     addOutputCodeLine("ADD 0 1");
		     sprintf(tmp, "JUMP %d", codeLineCount+1);
		     addOutputCodeLine(tmp);
		} 
	        if (index1 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		    errorCatched(tmp);
	        }
	        if (index2 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>3);
		    errorCatched(tmp);
	        }

	   }
           | IDENTIFIER DIV IDENTIFIER
	   {
		int index1 = getSymbolMemIndex($<str>1);
	   	int index2 = getSymbolMemIndex($<str>3);   		
		if (index1 != -1 && index2 != -1)
		{
		     int codeLineCount = outputCodeSize;
		     sprintf(tmp, "SUB 0 0");  addOutputCodeLine(tmp);
		     sprintf(tmp, "STORE 0 %d", symbolTableSize+1);  addOutputCodeLine(tmp);
		     sprintf(tmp, "LOAD 2 %d", index2);  addOutputCodeLine(tmp);
		     sprintf(tmp, "JZ 2 %d", codeLineCount+23);  addOutputCodeLine(tmp);
		     sprintf(tmp, "LOAD 1 %d", index1);  addOutputCodeLine(tmp);
		     sprintf(tmp, "LOAD 2 %d", index2);  addOutputCodeLine(tmp);
		     sprintf(tmp, "SUB 0 0");  addOutputCodeLine(tmp);
		     sprintf(tmp, "ADD 0 2");  addOutputCodeLine(tmp);
		     sprintf(tmp, "SUB 0 1");  addOutputCodeLine(tmp);
		     sprintf(tmp, "JG 0 %d", codeLineCount+23);  addOutputCodeLine(tmp);
		     sprintf(tmp, "LOAD 3 0");  addOutputCodeLine(tmp);	     
		     sprintf(tmp, "ADD 0 2");  addOutputCodeLine(tmp);
		     sprintf(tmp, "ADD 0 0");  addOutputCodeLine(tmp);
		     sprintf(tmp, "SUB 0 1");  addOutputCodeLine(tmp);
		     sprintf(tmp, "JG 0 %d", codeLineCount+18);  addOutputCodeLine(tmp);
		     sprintf(tmp, "ADD 2 2");  addOutputCodeLine(tmp);		
		     sprintf(tmp, "ADD 3 3");  addOutputCodeLine(tmp);	     
		     sprintf(tmp, "JUMP %d", codeLineCount+11);  addOutputCodeLine(tmp);
		     sprintf(tmp, "SUB 1 2");  addOutputCodeLine(tmp);
		     sprintf(tmp, "LOAD 0 %d", symbolTableSize+1);  addOutputCodeLine(tmp);		     
		     sprintf(tmp, "ADD 0 3");  addOutputCodeLine(tmp);
		     sprintf(tmp, "STORE 0 %d", symbolTableSize+1);  addOutputCodeLine(tmp);
		     sprintf(tmp, "JUMP %d", codeLineCount+5);  addOutputCodeLine(tmp);
		     sprintf(tmp, "LOAD 0 %d", symbolTableSize+1);  addOutputCodeLine(tmp);
		}
	        if (index1 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		    errorCatched(tmp);
	        }
	        if (index2 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>3);
		    errorCatched(tmp);
	        }
	   }
           | IDENTIFIER MODULO IDENTIFIER
	   {
		int index1 = getSymbolMemIndex($<str>1);
	   	int index2 = getSymbolMemIndex($<str>3);   		
		if (index1 != -1 && index2 != -1)
		{
		     int codeLineCount = outputCodeSize;
		     sprintf(tmp, "LOAD 1 %d", index2);  addOutputCodeLine(tmp);
		     sprintf(tmp, "JZ 1 %d", codeLineCount+17);  addOutputCodeLine(tmp);
		     sprintf(tmp, "LOAD 0 %d", index1);  addOutputCodeLine(tmp);
	    	     sprintf(tmp, "SUB 2 2");  addOutputCodeLine(tmp);
		     sprintf(tmp, "SUB 3 3");  addOutputCodeLine(tmp);
		     sprintf(tmp, "ADD 3 1");  addOutputCodeLine(tmp);	
		     sprintf(tmp, "SUB 3 0");  addOutputCodeLine(tmp);
		     sprintf(tmp, "JG 3 %d", codeLineCount+17);  addOutputCodeLine(tmp);
		     sprintf(tmp, "ADD 2 1");  addOutputCodeLine(tmp);	
		     sprintf(tmp, "ADD 3 2");  addOutputCodeLine(tmp);	
		     sprintf(tmp, "ADD 3 3");  addOutputCodeLine(tmp);
		     sprintf(tmp, "SUB 3 0");  addOutputCodeLine(tmp);
		     sprintf(tmp, "JG 3 %d", codeLineCount+15); addOutputCodeLine(tmp);
		     sprintf(tmp, "ADD 2 2");  addOutputCodeLine(tmp);	     
		     sprintf(tmp, "JUMP %d", codeLineCount+9);  addOutputCodeLine(tmp);
		     sprintf(tmp, "SUB 0 2");  addOutputCodeLine(tmp);
		     sprintf(tmp, "JUMP %d", codeLineCount+3);  addOutputCodeLine(tmp);
		}	
	        if (index1 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		    errorCatched(tmp);
	        }
	        if (index2 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>3);
		    errorCatched(tmp);
	        }
	   }
;

condition :  IDENTIFIER EQUAL IDENTIFIER
	   {
		int index1 = getSymbolMemIndex($<str>1);
	   	int index2 = getSymbolMemIndex($<str>3); 
		if (index1 != -1 && index2 != -1)
		{
		    sprintf(tmp, "LOAD 0 %d", index1);
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "LOAD 1 %d", index2);
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "SUB  2 2");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "ADD 2 0");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "SUB 0 1");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "SUB 1 2");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "ADD 0 1");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "JG 0");
		    addOutputCodeLine(tmp);
 		    tmpJmpStack.at(tmpJmpStack.size()-1) += 8;
		}
	        if (index1 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		    errorCatched(tmp);
	        }
	        if (index2 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>3);
		    errorCatched(tmp);
	        }
	   }	
	   | IDENTIFIER NEQUAL IDENTIFIER
	   {		
		int index1 = getSymbolMemIndex($<str>1);
	   	int index2 = getSymbolMemIndex($<str>3); 
		if (index1 != -1 && index2 != -1)
		{
		    sprintf(tmp, "LOAD 0 %d", index1);
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "LOAD 1 %d", index2);
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "SUB 2 2");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "ADD 2 0");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "SUB 0 1");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "SUB 1 2");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "ADD 0 1");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "JZ 0");
		    addOutputCodeLine(tmp);
 		    tmpJmpStack.at(tmpJmpStack.size()-1) += 8;
		}
	        if (index1 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		    errorCatched(tmp);
	        }
	        if (index2 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>3);
		    errorCatched(tmp);
	        }
	   }
	   | IDENTIFIER LESSER IDENTIFIER
	   {		
		int index1 = getSymbolMemIndex($<str>1);
	   	int index2 = getSymbolMemIndex($<str>3); 
		if (index1 != -1 && index2 != -1)
		{
		    sprintf(tmp, "LOAD 0 %d", index1);
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "LOAD 1 %d", index2);
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "SUB 1 0");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "JZ 1");
		    addOutputCodeLine(tmp);
 		    tmpJmpStack.at(tmpJmpStack.size()-1) += 4;
		}
	        if (index1 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		    errorCatched(tmp);
	        }
	        if (index2 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>3);
		    errorCatched(tmp);
	        }
		
	   }
	   | IDENTIFIER GREATER IDENTIFIER
	   {		
		int index1 = getSymbolMemIndex($<str>1);
	   	int index2 = getSymbolMemIndex($<str>3); 
		if (index1 != -1 && index2 != -1)
		{
		    sprintf(tmp, "LOAD 0 %d", index1);  addOutputCodeLine(tmp);
		    sprintf(tmp, "LOAD 1 %d", index2);  addOutputCodeLine(tmp);
		    sprintf(tmp, "SUB 0 1");  addOutputCodeLine(tmp);
		    sprintf(tmp, "JZ 0");  addOutputCodeLine(tmp);
 		    tmpJmpStack.at(tmpJmpStack.size()-1) += 4;
		}
	        if (index1 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		    errorCatched(tmp);
	        }
	        if (index2 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>3);
		    errorCatched(tmp);
	        }
	   }
	   | IDENTIFIER LEQUAL IDENTIFIER
	   {		
		int index1 = getSymbolMemIndex($<str>1);
	   	int index2 = getSymbolMemIndex($<str>3); 
		if (index1 != -1 && index2 != -1)
		{
		    sprintf(tmp, "LOAD 0 %d", index1);
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "LOAD 1 %d", index2);
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "SUB 0 1");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "JG 0");
		    addOutputCodeLine(tmp);
 		    tmpJmpStack.at(tmpJmpStack.size()-1) += 4;
		}
	        if (index1 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		    errorCatched(tmp);
	        }
	        if (index2 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>3);
		    errorCatched(tmp);
	        }
	   }
	   | IDENTIFIER GEQUAL IDENTIFIER
	   {		
		int index1 = getSymbolMemIndex($<str>1);
	   	int index2 = getSymbolMemIndex($<str>3); 
		if (index1 != -1 && index2 != -1)
		{
		    sprintf(tmp, "LOAD 0 %d", index1);
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "LOAD 1 %d", index2);
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "SUB 1 0");
		    addOutputCodeLine(tmp);
		    sprintf(tmp, "JG 1");
		    addOutputCodeLine(tmp);
 		    tmpJmpStack.at(tmpJmpStack.size()-1) += 4;
		}
	        if (index1 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>1);
		    errorCatched(tmp);
	        }
	        if (index2 ==-1)
	        {
		    sprintf(tmp, "BLAD: Linia %d - niezadeklarowana zmienna %s", yylineno, $<str>3);
		    errorCatched(tmp);
	        }
	   }
;

%%
int yyerror( char * str )
{
	printf( "BLAD: %s\n", str );
	exit(0);
}

int main()
{ 
	yyparse(); 
 	for (int i =0; i<outputCodeSize; i++)
	   cout  <<outputCode[i] << endl;
	return 0;
}

void addOutputCodeLine(string text)
{
     outputCode.push_back(text);
     outputCodeSize++;	
}


int getSymbolMemIndex(string name)
{
    for(int i = 0; i < symbolTableSize; i++ )
    {
	if (symbolTable.at(i).name == name)
	    return i;
    }
    return (-1);
} 

void errorCatched(string text) 
{
    cout << text << endl;
    exit(0);
}

