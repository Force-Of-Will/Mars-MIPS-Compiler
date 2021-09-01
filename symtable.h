/*  Symbol Table --linked list  headers
    Used for Compiler
*/

#include "ast.h"

#ifndef _SYMTAB 
#define _SYMTAB

//int mem=0;
void Display();
int Delete();

int FetchAddr (char *lab);

struct SymbTab
{
     char *name;
     int offset; /* from activation record boundary */
     int mysize;  /* number of words this item is 1 or more */
     int level;  /* the level where we found the variable */
     enum OPERATOR Type;  /* the type of the symbol */
     int IsAFunc;  /* the element is a function */
     ASTNode * fparms; /* pointer to parameters of the function in the AST */

     struct SymbTab *next;
};

struct SymbTab * Insert(char *name, enum OPERATOR Type, int isafunc, int  level, int mysize, int offset, ASTNode * fparms );//prototype for insert(), edited to match my ASTNode class
char * CreateTemp(); //added to include the CreateTemp method
struct SymbTab * Search(char name[], int level, int recur);//Prototype for search(), edited to match my ASTNode class
#endif
