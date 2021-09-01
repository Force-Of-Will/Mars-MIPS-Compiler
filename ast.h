//Benjamin Longwell
//Abstract Syntax Tree (c) (H FILE)
//Last Edited 9/1/2021

#ifndef AST
#define AST

//prelists the types a node can be, uses enum
enum NODETYPE{
        VARDEC, //OK
        FUNDEC, //OK
        PARAM,  //OK
        MYASSIGN, //OK
        BLOCK, //OK
        MYWRITE, //OK
        MYREAD, //OK
        MYNUM, //OK
        EXPR, //OK
        ARG, //OK
        WHILESTMT,//OK
        WHILESTMT1,//OK
        SELECTIONSTMT, //OK
        SELECTIONSTMT1, //OK
        IDENT, //OK
        MYCALL,//OK
        RET //OK
};//of notetype enum

//prelists the types of data we have, uses enum
enum DATATYPES{
        INTTYPE,
        BOOLEANTYPE,
        VOIDTYPE
};//of ENUM DATATYPE

//prelists the types of operators we can have, uses enum
enum OPERATOR {
	PLUS,
	MINUS,
    LESSEQUAL,
    GREATEREQUAL,
    LESSTHAN,
    GREATERTHAN,
    EQUALTO,
    MYNOT,
    NOTEQUAL,
    MULTIPLY,
    DIVIDE,
    ANDOP,
    OROP
};//of enum OPERATOR

//lists our prototype for astnode
typedef struct ASTNodeType{
	    char *Name;
        char *label;
        enum NODETYPE type;
        enum DATATYPES dt;
        enum DATATYPES semType;//cooper used operator but i used datatypes :)
        enum OPERATOR operator;
        struct ASTNodeType *s1, *s2, *next;
        struct SymbTab * symbol; //ADDED SO WE CAN HAVE ACCESS TO SYMBOL WHEN WE START GENERATING CODE
        int size;
} ASTNode;//of structure definiton

void prtLvl(int level);//prototype for printing level
void ASTprint(ASTNode *p, int level);//prototype for ASTprint
ASTNode* ASTcreateNode(enum NODETYPE DesiredType);//prototype for ASTcreateNode
#endif /*AST_H_*/
