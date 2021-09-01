#makefile for compiler
#benjamin longwell
# Last edit: 9/1/2021

all:
	yacc -d analyze.y 
	lex analyze.l
	gcc -o final y.tab.c emit.c ast.c lex.yy.c symtable.c
	
clean:
	rm y.tab.c
	rm y.tab.h
	rm lex.yy.c
	
