 #!/bin/bash
bison -d compiler.y
flex compiler.l
g++ -o compiler lex.yy.c compiler.tab.c
