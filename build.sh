 #!/bin/bash
bison -d compiler.y
flex compiler.l
g++ -o compiler lex.yy.c compiler.h compiler.cpp compiler.tab.c -std=c++11
