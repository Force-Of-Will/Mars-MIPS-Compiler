//Benjamin Longwell
//Emit.h for use in teh final lab
//Last edit 9/1/2021
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifndef EMIT_H
#define EMIT_H

#include "ast.h" //so we can use the ast nodes and such
#include "symtable.h" //so we can access the symtable
#define WSIZE 4  // number of bytes in a word
#define LOGWSIZE 2  // number of shifts to get to WSIZE
//THESE CAME WITH THE FILE
//static int GLABEL = 0; //Global label counter DELETED because we have it in the c file
char * genlabel();
//THESE I ADDED
void emit(FILE *fp, char * label, char * command, char * comment);
void emit_function_head(ASTNode * p, FILE * fp);
void EMITAST(ASTNode *p, FILE *fp);
void emit_expr(ASTNode * p,FILE * fp_);
void emit_identifier(ASTNode * p, FILE *fp);
void emit_call(ASTNode *p, FILE *fp);
void emit_if(ASTNode *p, FILE *fp);
void EMITSTRINGS(ASTNode * p, FILE * fp);
void EMITGLOBALS(ASTNode * p, FILE * fp);
//void EMITGLOBALS(ASTnode * p);

#endif  // of EMIT.h
