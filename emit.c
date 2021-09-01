//Benjamin Longwell
//Emit.c
//From an ASTNode pointer, prints out ASM code that represents the tree
//Last edit: 9/1/2021

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "ast.h"
#include "emit.h"

//These values hold the current value of the label we are going to use.
static int GLABEL = 0;; //global label counter
char * CURR_FUNCTION;//representation of the function we are currently in. 

//precondition:                                                                                                                                                                          
//postcondition: genmerates a label used for strings / others at the top of the file
char * genlabel(){
    char s[100];
    char *s1;
    sprintf(s, "_L%d", GLABEL++);
    s1 = strdup(s);
    return s1;
}//end genlabel()

//Precondition: ptr to ASTNode
//Postcondition prints out all the strings in mips format. (found at the top of the asm file always)
void EMITSTRINGS(ASTNode * p, FILE *fp){
    if(p == NULL) return;
    
    if((p->type == MYWRITE) && (p->Name != NULL)){
        //we know its a string
        //printf("%s:\t .asciiz\t%s\n", p->label, p->Name);
        fprintf(fp, "%s:\t .asciiz\t%s\n", p->label, p->Name);
    }//end if
    
    EMITSTRINGS(p->next, fp);
    EMITSTRINGS(p->s1, fp);
    EMITSTRINGS(p->s2, fp);
}//end EMITSTRINGS

//precondition: ptr to ASTNode and file fp
//postcondition: prints out all of the global variables in MIPS format
//these are printed out in the .data segment
void EMITGLOBALS(ASTNode * p, FILE * fp){
    if(p == NULL) return;
    
    if((p->type == VARDEC) && (p->symbol->level == 0)){
        //we know its a global
        fprintf(fp, "%s:\t.space\t%d\n",p->Name, p->symbol->mysize*WSIZE);
        //fprintf(fp, "%s:\t.space\t%d\n",p->Name, p->symbol->mysize*WSIZE);
    }//end if
    EMITGLOBALS(p->next, fp);
    EMITGLOBALS(p->s1, fp);
    //we dont store any globals in s2 ever so no need to recurse
}//end EMITGLOBALS

//helper function that makes my mips code looks pretty
//uses 4 params
//@precondition you get three strings and you have to print them out using assembly formatting IN the file
//ex: emit(fp, "L1","ldi R13, 15","#load a number");
void emit(FILE *fp, char * label, char * command, char * comment){
    if(strcmp("",label)==0) fprintf(fp,"\t\t%s\t\t%s\n", command, comment);
    else fprintf(fp, "%s\t\t%s\t\t%s\n", label, command, comment);
}//of emit

//precondition:  pointer to a fundec ASTnode
//postcondition: no return, emitted code to represent the function head of whatever function we are in
void emit_function_head(ASTNode * p, FILE * fp){
    char s[100];
    emit(fp,p->Name,":","#start of function");
    //set the global function variable
    CURR_FUNCTION = p->Name;
    sprintf(s, "subu $a0, $sp, %d", p->size*WSIZE);
    emit(fp,"",s,"#adjust the stack for function setup");
    emit(fp,"","sw $sp, ($a0)","");
    emit(fp,"","sw $ra, 4($a0)","");
    emit(fp,"","move $sp, $a0", "#adjust the stack pointer");
}//of emit_function_head

void emit_function_return(ASTNode *p, FILE *fp){
    
    if(p != NULL){
        emit_expr(p, fp);//leaves $a0 with the result
    }
    
    //set the activation record back
    emit(fp, "", "", "");
    emit(fp, "", "lw $ra, 4($sp)","#restore RA");
    emit(fp,"", "lw $sp, ($sp)","#restore SP");
    emit(fp,"","","");
    
    //if its main, treat it different
    if(strcmp(CURR_FUNCTION, "main") == 0){
        emit(fp, "","li $v0, 10"," #leave MAIN program ");
        emit(fp, "","syscall","#leave Main");
    }//end if
    else {
        
    }//every other function //FIXME
}//end emit_function_return

//precondition a pointer to an expression as defined in the YACC language
//postcondition: mips code that sets $a0 to the value of the PTR
void emit_expr(ASTNode * p,FILE * fp){
    if(p == NULL) return;
    char s[100];
    switch(p->type){
        case MYNUM:
            sprintf(s, "li $a0, %d", p->size);
            emit(fp,"",s,"#expression is a NUMBER");
            return;
            break;
        case IDENT:
            emit_identifier(p, fp);
            emit(fp, "", "lw $a0, ($a0)", "#fetcj tje value we are using for IDENT");
            return;
            break;
        case MYCALL:
            //have not yet written emit_call
            //use JUMP to go back to where $ra references
            //Emit
            emit_call(p, fp); //$a0 will be the value of the expression
            //printf("Cases not implemented in emit_expression");
        //expression is an expr, deal with it appropriately
    }//end switch (uses p->TYPE)
    
    //Recurse through it becase we can have expressions attached to expressions
    //evaluate the value of s1
    emit_expr(p->s1, fp);
    //keep the value of the s1 we just evaluated and put it in
    sprintf(s, "sw $a0 %d($sp)", p->symbol->offset * WSIZE);
    emit(fp, "", s, "#store RHS in memory.");
    //now we do similar thing but with s2
    emit_expr(p->s2, fp);
    sprintf(s, "move $a1, $a0");//move a0 to a1
    emit(fp, "", s, "#right hand side is now A1");
    
    sprintf(s, "lw $a0 %d($sp)", p->symbol->offset * WSIZE);
    emit(fp, "", s, "#getting the LHS of this expr from memory.");    
    
    //go through the operators and perform the right kinds of math on them
    switch(p->operator){
        case PLUS:
            emit(fp, "", "add $a0, $a0, $a1", "#Add to the expression.");
            break;
        case MINUS:
            emit(fp, "", "sub $a0, $a0, $a1", "#subtract to the expression.");
            break;
        case MULTIPLY:
            emit(fp, "", "mult $a0, $a1", "#mult to the expression.");
            //we want the lower 32 bits, so we use mflo and not mfhi
            emit(fp, "", "mflo $a0", "#mult to the expression.");
            break;
        case DIVIDE:
            emit(fp, "", "div $a0 $a1", "#divide to the expression");
            emit(fp, "", "mflo $a0", "#divide to the expression");
            break;
        case GREATERTHAN:
            emit(fp, "", "sgt $a0, $a0, $a1", "#compare SGT greater than");
            break;
        case LESSTHAN:
            emit(fp, "", "slt $a0, $a0, $a1", "#compare SLT less than");
            break;
        case LESSEQUAL:
            emit(fp, "", "sle $a0, $a0, $a1", "#compare SLE less than or equal to");
            break;
        case GREATEREQUAL:
            emit(fp, "", "sge $a0, $a0, $a1", "#compare SGE greater than equal to");
            break;
        case EQUALTO:
            emit(fp, "", "seq $a0, $a0, $a1", "#compare SEQ equal to");
            break;
        case MYNOT:
            emit(fp, "", "sltiu $a0, $a0, 1", "Compare SLTIU (for not)");
            break;
    }//end switch (uses (P->OPERATOR)
}//end emit_expr

void emit_assign(ASTNode *p, FILE *fp){
    char s[100];
    emit_expr(p->s2, fp);
    sprintf(s, "sw $a0, %d($sp)", p->symbol->offset * WSIZE);
    emit(fp, "", s, "");
    emit_identifier(p->s1, fp);
    sprintf(s, "lw $a1, %d($sp)", p->symbol->offset * WSIZE);
    emit(fp, "", s, "");
    emit(fp, "", "sw $a1, ($a0)", "#end of assign");
}//end emit_assign

void emit_call(ASTNode *p, FILE *fp){
    //fixme
}//end emit_call
void emit_write(ASTNode *p, FILE *fp){
    char s[100];
    if(p->s1 !=  NULL){
        emit_expr(p->s1, fp); //$a0 ius the value set from the expression
        emit(fp, "","li $v0 1"," #print the number");
        emit(fp, "","syscall","#system call for print number");
        emit(fp, "", "", "");
    }//end if
    else{
        //print out a string
        sprintf(s, "la $a0, %s", p->label);
        emit(fp, "", s, "#string address");
        emit(fp, "","li $v0 4"," #write the number");
        emit(fp, "","syscall","#system call for print number");
        emit(fp, "", "", "");
    }//end else
}//end emit_write

void emit_read(ASTNode *p, FILE *fp){
    emit_identifier(p->s1, fp);
    emit(fp, "","li $v0, 5", "#read a number from input");
    emit(fp,"","syscall","#reading a number ");
    emit(fp, "", "sw $v0, ($a0)","#store the READ into a mem location");
    emit(fp,"","","");
}//end emit_read

void emit_identifier(ASTNode * p, FILE *fp){
    char s[100];
    if(p->symbol->level > 0){
        //FIRST CHECK IF WE ARE AN ARRAY REFERENCE LIKE WE HAVE
        //P-> SYMBOL-> IsAFunc (isafunc has to be 2)
        if(p->symbol->IsAFunc == 2){
            emit_expr(p->s1, fp);//we are setting a0 to the index of the array
            sprintf(s, "sll $a0, $a0, %d", LOGWSIZE);
            emit(fp, "", s, "#identifier is an ARRAY");
            
            sprintf(s, "add $a0, $a0, %d", p->symbol->offset *WSIZE);//add offset to the value in A0
            emit(fp, "", s, "#identifier is a array");
            emit(fp, "", "add $a0, $a0, $sp", "#add on the stack pointer. Array value for an ident."); 
            emit(fp, "","","");
        }//end if (for isafunc == array)
        else{
            //THEN DO REGULAR SCALARS
            sprintf(s, "add $a0, $sp, %d", p->symbol->offset * WSIZE);
            emit(fp,"",s,"#identifier is a SCALAR");
            emit(fp,"","",""); 
        }//end else (not an array)
        
    }
    else{
        //blobals
        sprintf(s, "la $a0, %s", p->Name);
        emit(fp,"",s,"#identifier is a GLOBAL SCALAR");
        emit(fp,"","","");  
    }//end else
}//end emit_identifier

void emit_if(ASTNode *p, FILE *fp){
    //make some labels, we need at most 2
    char * L1;
    char * L2;
    //s to hold labels so we can make our mips code
    char s[100];
    //give them values
    L1 = genlabel();
    L2 = genlabel();
    //p->s1 is our expr
    emit_expr(p->s1, fp);
    emit(fp, "", "ldi t0, 0", "#put 0 in t0");
    sprintf(s, "beq a0, t0, %s", L1);
    emit(fp, "", s, "#if the expression is met, branch.");
    EMITAST(p->s2->s1, fp);//the positive part of the if
    sprintf(s, "j %s", L2);//jump out of if
    sprintf(s, "%s", L1);
    emit(fp, s, "", "#else part ");
    //s now holds L1 label
    EMITAST(p->s2->s2, fp);//this is the else
    sprintf(s, "%s", L2);
    emit(fp, s, "", "#end of if");    
}//end emit_if;

//Start at a head node, recurse through the tree (DO THIS FOR ALL NODES IN THE AST FILE) 
//And print out assembly code that mirrors the user's input.
void EMITAST(ASTNode *p, FILE *fp){
    if(p == NULL) return;
    switch (p -> type){
        case VARDEC: //we dont need any code here
            break;
        case FUNDEC: 
            emit_function_head(p, fp);
            EMITAST(p->s2, fp); //block of the function
            emit_function_return(NULL, fp);
            break;
        case BLOCK:
            EMITAST(p->s2, fp);
            break;
        case MYWRITE:
            emit_write(p, fp);
            break;
        case MYREAD:
            emit_read(p, fp);
            break;
        case SELECTIONSTMT:
            emit_if(p, fp);
            break;
        case MYASSIGN:
            emit_assign(p, fp);
            break;
        default: printf("EMIT AST type isnt implemented.\n");
    }//end switch
    EMITAST(p->next, fp);
}//end EMITAST
