//Benjamin Longwell
//ast.c
//Last Edit: 9/1/2021
#include "ast.h"
#include <stdio.h>
#include<malloc.h>
//Prints per-level for clean (or at least I tried) indentation
void prtLvl(int level){
    for(int i = 0; i < level; i++) printf(" ");
}//end printlvl

//Takes a head node, and depending on the type of node, goes through the whole tree and prints out stuff parsed in from lex and yacc
void ASTprint(ASTNode *p, int level){
    
    prtLvl(level);
    
    if(p == NULL) return;
    
    switch (p->type){
        case VARDEC: 
            printf("Vardec found. ");
            printf("name is %s \n", p->Name);
            ASTprint(p->s1, level);
            if(p->size >= 1){
                printf(" is an array with size %d \n", p->size);
            }
            break;//ok
        case FUNDEC: 
            printf("fundec found. ");
            printf("name is %s\n", p->Name);
            if(p->s1 == NULL) printf("VOID PARAMS\n");
            else ASTprint(p->s1, level + 1);
            ASTprint(p->s2, level + 2);
            break;//ok
        case PARAM:  
            printf("parameter found. ");//IS IT AN ARRAY OR NOT NEED TO ADD
            printf("name is %s ", p->Name);
            
            if(p->size >= 1){
                printf(" is an array with size %d.", p->size);
            }
            printf("\n");
            
            break;//ok  
        case MYASSIGN: 
            printf("Assignment statement found:\n");
            ASTprint(p->s1, level + 1);
            ASTprint(p->s2, level + 1);
            break;//OK
        case BLOCK:  
            printf("block found.\n");//IS IT AN ARRAY OR NOT NEED TO ADD
            ASTprint(p->s1, level + 1);
            ASTprint(p->s2, level + 1);
            break; //OK
        case MYWRITE: 
            printf("write statement found.\n");
            if( p->s1 != NULL){
                ASTprint(p->s1, level+1);
            }//end if
            else {
                //we are a print string
                prtLvl(level + 1);
                printf("%s %s\n",p->label,  p->Name);
            }//end eelse
			   break; //OK
        case MYREAD:
            printf("read statement found.\n");
            ASTprint(p->s1, level + 1);            
            break; //OK
        case MYNUM:  
            printf("Number found. ");
            printf("Value is: %d\n", p->size);
		      //ASTprint(p->s1, level + 1);//COOPER RECOMENDS REMOVE
            break;//for MYNUM OK
        case EXPR: 
            printf("expression found ");
            printf("operator for the expression is :");
            switch (p->operator){
                case PLUS: printf("plus\n"); 
                    break;
                case MINUS: printf("minus\n");
                    break;
                case LESSEQUAL: printf("less than or equal to\n");
                    break;
                case GREATEREQUAL: printf("greater than or equal to\n");
                    break;
                case LESSTHAN: printf("Less than.\n");
                    break;
                case GREATERTHAN: printf("greater than.\n");
                    break;
                case EQUALTO: printf("equal to.\n");
                    break;
                case NOTEQUAL: printf("not equal to.\n");
                    break;
                case MULTIPLY: printf("multiply\n");
                    break;
                case DIVIDE: printf("divide.\n");
                    break;
                case ANDOP: printf("and operator\n");
                    break;
                case OROP: printf("or operator\n");
                    break; 
                    //MYNOT
                default: printf("no operator matched\n");
                    break;
                ASTprint(p->s1, level + 1);
            }//of p->operator switch     
            break;//for case EXPR
        case ARG: 
            printf("Argument (list) found:\n");
            ASTprint(p->s1, level + 1);
            //ASTprint(p->s2, level + 1);//only NEXT attached, not S2
            break;//OK
        case WHILESTMT:
            printf("while statement:\n");
            ASTprint(p->s1, level + 1);
            ASTprint(p->s2, level + 1);
            break;
        case SELECTIONSTMT:
            printf("If statement found:\n");
            ASTprint(p->s1, level + 1);
            ASTprint(p->s2, level + 1);
            break;//ok
        case SELECTIONSTMT1:
            printf("then / else statement:\n");
            ASTprint(p->s1, level + 1);
            ASTprint(p->s2, level + 1);            
            break;
        case IDENT: 
            printf("Identifier name %s. ", p->Name);
            if(p->s1 == NULL) printf("\n");
            else {
                printf("With a reference to a location (expression).\n");
                ASTprint(p->s1, level + 1);
            }//end else
            
            break;//OK
        case MYCALL:
            printf("call found to name%s\n", p->Name);
            ASTprint(p->s1, level + 1);
            break;            
        case RET: 
            printf("return statement found\n");
            if(p->s1 == NULL) printf("\n");
            else {
                printf("With a reference to a location (expression).");
                ASTprint(p->s1, level + 1);
            }//end else
            break;//OK
        default: 
            printf("Unknown type in ASTprint.\n");
    }//of switch
    
    ASTprint(p->next, level);//print the next node
    
}//of ASTprint
//constructor
ASTNode* ASTcreateNode(enum NODETYPE DesiredType){
        ASTNode *p;
        p = (ASTNode *)(malloc (sizeof(struct ASTNodeType)));
        p->type = DesiredType;
        p->s1 = NULL;
        p->s2 = NULL;
        p->next = NULL;
        p->size = 0;
        p->Name = NULL;
        return p;
}
