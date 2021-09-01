%{
	/* begin specs */
	//Benjamin Longwell
    //Last Edit 9/1/2021
int yylex(); //prototype to get rid of gcc warning

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>//added to use the stdlib so we can call exit()
#include <string.h>
#include "emit.h" //now we cna use the emit program
#include "ast.h"//allow this to talk with ast
#include "symtable.h"//allow this to talk with symtable
//For Insert(): struct SymbTab * Insert(char *name, enum OPERATORS Type, int isafunc, int  level, int mysize, int offset, ASTNode * fparms );
extern int linecount;
extern int mydebug;

int level = 0; //level of compound statements (sort of)

int offset = 0; //current offset starts at 0 because we havent done anything yet

int GOFFSET; //Holds the global offset

int MAXOFFSET; //the maximum amount of memory needed for the current function

ASTNode *GlobalTreePointer;

void yyerror (s)  /* Called by yyparse on error ANY TIME THERE IS A SYNTAX ERROR WE CALL THIS FUNCTION*/
     char *s;
{
  fprintf (stderr, "%s on line %d\n", s, linecount);
}

%}

/*  defines the start symbol, what values come back from LEX and how the operators are associated  */
%start PROGRAM

%union {
    int value;
    char * string;
    struct ASTNodeType * node;
    enum DATATYPES datatype;
    enum OPERATOR operator;
} 
%token INT 
%token VOID 
%token AND 
%token OR 
%token NOT 
%token WHILE 
%token DO 
%token IF 
%token THEN 
%token ELSE 
%token READ 
%token WRITE 
%token FOR 
%token RETURN 
%token LE 
%token GE 
%token NE 
%token LT 
%token GT 
%token EQ
%token MYBEGIN 
%token END 
%token MYRETURN 
%token BOOLEAN 
%token TRUE 
%token FALSE

%token <value> INTEGER//join with union
%token <value> NUM//join with union
%token <string> STRING //ADDED DURING FINAL LAB
%token <string> ID//join with union
%token <string> VARIABLE//join with union

//VARS AND DECS
%type <node> VARLIST //show this is node type
%type <node> VARDEC //show this is node type
%type <node> DEC //show this is node type
%type <node> DECLIST //show this is node type
%type <node> FUNDEC //show this is node type
%type <node> LOCDECS //show this is node type
%type <node> PARAMS //show this is node type
%type <node> PARAM //show this is node type
%type <node> PARAMLIST //show this is node type
//STATEMENTS
%type <node> ASSIGNSTMT //show this is node type
%type <node> COMPOUNDSTMT //show this is node type
%type <node> STATEMENT //show this is node type
%type <node> STATEMENTLIST //show this is node type
%type <node> SELECTIONSTMT //show this is node type
%type <node> ITERATIONSTMT //show this is node type
%type <node> EXPRESSIONSTATEMENT //show this is node type
%type <node> RETURNSTMT //show this is node type
//EXPRESSIONS
%type <node> TERM //show this is node type
%type <node> FACTOR //show this is node type
%type <node> ADDEXPR //show this is node type
%type <node> CALL //show this is node type
%type <node> ARGS //show this is node type
%type <node> WRITESTMT //show this is node type
%type <node> READSTMT //show this is node type
%type <node> EXPRESSION //show this is node type
%type <node> SIMPEXPRESSION //show this is node type
%type <node> ARGLIST //show this is node type
%type <node> VAR //show this is node type
//DATATYPE AND OPERATOR
%type <datatype> TYPESPEC//join with union
%type <operator> ADDOP RELOP MULTOP//join with union

%%	/* end specs, begin rules */
PROGRAM     :   DECLIST {GlobalTreePointer = $1;}/*program →declaration-list */
            ;//OK
            
DECLIST     :   DEC {$$ = $1;}
            |   DEC DECLIST {$1->next = $2; $$=$1;}//FLIPPED TO FIX THE TYPE OF RECURSION HERE
            ;//OK
            
DEC         :   VARDEC {$$ = $1;}
            |   FUNDEC {$$ = $1;}
            ;//OK
            
VARDEC      :   TYPESPEC VARLIST ';' {$$ = $2;
                                        ASTNode * p = $2;
                                        while(p != NULL){
                                            p->dt = $1;
                                            Search(p->Name, level, 0)->Type=$1;
                                            p = p->s1;
                                        }//end while
                                    }
            ;//OK
            
VARLIST     :   ID {
                    if(Search($1, level, 0) != NULL){
                        yyerror("Duplicate Variable ");
                        yyerror($1);
                        exit(1);
                    }//end if, now we know the element is NOT in the symbtab
                    
                    $$ = ASTcreateNode(VARDEC);
                    $$->Name = $1;
                    //insert the symbol
                    $$->symbol = Insert($1, -1, 0, level, 1, offset, NULL); //OMG
                    offset = offset + 1;//the size of the element (1 in this case)

                }//set name (ID)
                
            |   ID'['NUM']' {
                            if(Search($1, level, 0) != NULL){
                                yyerror("Duplicate Variable ");
                                yyerror($1);
                                exit(1);
                            }//end if, now we know the element is NOT in the symbtab
                            
                            $$ = ASTcreateNode(VARDEC); 
                            $$->Name = $1; 
                            $$->size = $3;
                            //insert the symbol
                            $$->symbol = Insert($1, -1, 2, level, $3, offset, NULL); //OMG
                            offset = offset + $3;//the size of the element ($3 in this case)
                            }//set name and size (we have an array)
                            
            |   ID','VARLIST {
                                //For Insert(): struct SymbTab * Insert(char *name, enum OPERATORS Type, int isafunc, int  level, int mysize, int offset, ASTNode * fparms );
                                if(Search($1, level, 0) != NULL){
                                    yyerror("Duplicate Variable ");
                                    yyerror($1);
                                    exit(1);
                                }//end if, now we know the element is NOT in the symbtab
                                
                                $$ = ASTcreateNode(VARDEC); 
                                $$->Name = $1; 
                                $$->s1 = $3;
                                
                                //insert the symbol
                                $$->symbol = Insert($1, -1, 0, level, 1, offset, NULL); //OMG
                                offset = offset + 1;//the size of the element (1 in this case)
                                
                                }//set name and attach to VARLIST
            |   ID'['NUM']'','VARLIST 
                    {
                        //For Insert(): struct SymbTab * Insert(char *name, enum OPERATORS Type, int isafunc, int  level, int mysize, int offset, ASTNode * fparms );
                        if(Search($1, level, 0) != NULL){
                            yyerror("Duplicate Variable ");
                            yyerror($1);
                            exit(1);
                        }//end if, now we know the element is NOT in the symbtab
                        
                        $$ = ASTcreateNode(VARDEC);
                        $$->Name = $1;
                        $$->size = $3;
                        $$->s1 = $6;
                        //insert the symbol ARRAY
                        $$->symbol = Insert($1, -1, 2, level, 1, offset, NULL); //OMG
                        offset = offset + $3;//the size of the element (1 in this case)
                    }
            ;//OK
            
TYPESPEC    :   INT {$$ = INTTYPE;}
            |   VOID {$$ = VOIDTYPE;}
            |   BOOLEAN {$$ = BOOLEANTYPE;}
            ;//OK
            
FUNDEC      :   TYPESPEC ID'('
                    {
                    //check if this has already been declared
                    if(Search($2, level,0) != NULL){
                        yyerror("Duplicate Variable ");
                        yyerror($2);
                        exit(1);
                    }//end if
                    else{
                        //we can insert it
                        //For Insert(): struct SymbTab * Insert(char *name, enum OPERATORS Type, int isafunc, int  level, int mysize, int offset, ASTNode * fparms );
                        /* isafunc
                        0 -> scalar
                        1 -> function
                        2 -> array
                        */
                        Insert($2, $1, 1, level, 0, 0, NULL); //OMG
                    }//end else
                     //DEAL WITH OFFSET
                    GOFFSET = offset;
                    offset = 2;//will eventually be 2?
                    MAXOFFSET = offset;
                    }
                PARAMS')' 
                    {
                    //we can see the formal params now so now we can update them
                    Search($2, level, 0)->fparms = $5;
                    }
                COMPOUNDSTMT    
                    {
                    $$ = ASTcreateNode(FUNDEC);
                    $$->Name = $2;
                    $$->dt = $1;
                    $$->s1 = $5;
                    $$->s2 = $8;
                    $$->size = MAXOFFSET;
                    offset = GOFFSET;
                    //store the size of the function into the symbol table
                    $$->symbol = Search($2,0,0);
                    $$->symbol->mysize = MAXOFFSET;
                    
                    $$->semType = $1;
                    
                    }
            ;//OK
            
PARAMS      :   VOID {$$ = NULL;}//NULL is ok here because its a void param
            |   PARAMLIST {$$ = $1;}
            ;//OK
            
PARAMLIST   :   PARAM   {$$ = $1;}
            |   PARAM','PARAMLIST {$1->next = $3; $$ = $1;}
            ;//OK
            
PARAM       :   TYPESPEC ID 
                    {   
                                //PUT IN SYMTABLE
                                if(Search($2, level+1, 0) != NULL){
                                    yyerror("Duplicate Variable ");
                                    yyerror($2);
                                    exit(1);
                                }//end if, now we know the element is NOT in the symbtab
                                
                                $$ = ASTcreateNode(PARAM);
                                $$->dt = $1;
                                $$->Name = $2;
                                $$->size = 0;
                                
                                //insert the symbol
                                $$->symbol = Insert($2, $1, 0, level+1, 1, offset, NULL); //OMG
                                offset++;
                    }
            |   TYPESPEC ID'[' ']' {
                                //PUT IN SYMTABLE
                                if(Search($2, level+1, 0) != NULL){
                                    yyerror("Duplicate Variable ");
                                    yyerror($2);
                                    exit(1);
                                }//end if, now we know the element is NOT in the symbtab
                                
                                $$ = ASTcreateNode(PARAM);
                                $$->dt = $1;
                                $$->Name = $2;
                                $$->size = -1;
                                
                                //insert the symbol
                                $$->symbol = Insert($2, $1, 2, level+1, 1, offset, NULL); //OMG
                                offset++;
                                }//fixed
            ;//OK
            
COMPOUNDSTMT :  MYBEGIN { level ++; } 
                LOCDECS STATEMENTLIST END	
                        {
                            $$ = ASTcreateNode(BLOCK);//node for the compound statement
							$$->s1 = $3;//s1 is the locdecs
							$$->s2 = $4;//s2 is the statement list
							if (offset > MAXOFFSET) MAXOFFSET = offset;
							offset -= Delete(level);
							level--;
                        }
             ;//OK
            
LOCDECS     :   /*empty*/ {$$ = NULL;}//ok
            |   VARDEC LOCDECS  {
                                 $1->next = $2;
                                 $$ = $1;
                                 }
            ;//OK
            
STATEMENTLIST : /*empty*/ {$$ = NULL;}//ok
            |   STATEMENT STATEMENTLIST {
                    $1->next = $2;
                    $$ = $1;            
                }//end SDSA
            ;//OK
            
STATEMENT   :   EXPRESSIONSTATEMENT {$$ = $1;}
            |   COMPOUNDSTMT        {$$ = $1;}
            |   SELECTIONSTMT       {$$ = $1;}
            |   ITERATIONSTMT       {$$ = $1;}
            |   ASSIGNSTMT          {$$ = $1;}
            |   RETURNSTMT          {$$ = $1;}
            |   READSTMT            {$$ = $1;}
            |   WRITESTMT           {$$ = $1;}
            ;
            
EXPRESSIONSTATEMENT :   EXPRESSION';' {$$ = $1;}
                    | ';' {$$ = NULL;}/*empty only semicolon*/
                    ;//OK
                    
SELECTIONSTMT   :   IF EXPRESSION THEN STATEMENT	{ 	$$ = ASTcreateNode(SELECTIONSTMT);//make new sstmt node
								$$->s1 = $2;//s1 is now the expression
								$$->s2 = ASTcreateNode(SELECTIONSTMT1);//s2 is now the selection
								$$->s2->s1 = $4;//s2's s1 is now the statement
								$$->s2->s2 = NULL;//s2's s2 is null becase we dont need it
							}
                |   IF EXPRESSION THEN STATEMENT ELSE STATEMENT
							{	$$ = ASTcreateNode(SELECTIONSTMT);//make new sstmt node
								$$->s1 = $2;//s1 is the expression
								$$->s2 = ASTcreateNode(SELECTIONSTMT1);//s2 is the selection
								$$->s2->s1 = $4;//s2's s1 is now the 'then' statement
								$$->s2->s2 = $6;//s2's s2 is now the 'else' statement
							}
                ;//OK
                
ITERATIONSTMT   :   WHILE EXPRESSION DO STATEMENT   { $$ = ASTcreateNode(WHILESTMT);//$$ is a new WHILESTMT
                                                      $$->s1 = $2;//$$->s1 is now the expression
                                                      $$->s2 = $4;
                                                      }
                ;//OK
                
RETURNSTMT  :   MYRETURN';' {$$ = ASTcreateNode(RET);}//fixed this because of conflict with reserved words
            |   MYRETURN EXPRESSION';'{
                    $$ = ASTcreateNode(RET);
                    $$->s1 = $2;
            }
            ;//OK
            
READSTMT    :   READ VAR ';' {$$ = ASTcreateNode(MYREAD);
                        $$->s1 = $2;
                        }
            ;//OK
            
WRITESTMT   :   WRITE EXPRESSION';' 	
                    {	
                        $$ = ASTcreateNode(MYWRITE);//make a new node
						$$->s1 = $2;//s1 is the expression
					}
					
                | WRITE STRING';'
                    {   
                        //ADDED DURING FINAL LAb
                        $$ = ASTcreateNode(MYWRITE);//make a new node
						$$->Name = $2;//s1 is the expression
						$$->label = genlabel();
                    
                    }
            ;//OK
            
ASSIGNSTMT  :   VAR '=' SIMPEXPRESSION ';' 
                    {
                        if($1->semType != $3->semType){
                            //barf cause they dont match
                            yyerror("Type mismatch on assignment!");
                            exit(1);
                        }//end if
                        $$ = ASTcreateNode(MYASSIGN);
                        $$-> s1 = $1;
                        $$-> s2 = $3;
                        $$->Name=CreateTemp();
                        $$->symbol=Insert($$->Name,INTTYPE,0,level,1,offset, NULL);
                        offset++;
                    }
            ;//OK
            
EXPRESSION  :   SIMPEXPRESSION {$$ = $1;}//pass it up
            ;//OK
/* isafunc
    0 -> scalar
    1 -> function
    2 -> array
*/
VAR         :   ID 
                    {
                        struct SymbTab *s;
                        s = Search($1, level, 1);
                        //see if its there
                        if(s == NULL){
                            yyerror($1);
                            yyerror(" Variable does not exist!");
                            exit(1);
                        }//end if
                        //cant be a variable
                        if(s->IsAFunc != 0){
                            yyerror($1);
                            yyerror("Needs to be a scalar.");
                            exit(1);
                        }//end if
                        //Now we're happy
                        
                        $$ = ASTcreateNode(IDENT);
                        $$->s1 = NULL;
                        $$->Name = $1;//there is no value accompanying this var call
                        $$->symbol = s; //STORE THE SYMBOL TABLE POINTER
                        $$->semType = s->Type; //pulls it from the symbol table
                    }
            |   ID'['EXPRESSION']' 
                    {
                        struct SymbTab *s;
                        s = Search($1, level, 1);
                        //see if its there
                        if(s == NULL){
                            yyerror($1);
                            yyerror(" Variable does not exist!");
                            exit(1);
                        }//end if
                        //cant be a variable
                        if(s->IsAFunc != 2){
                            yyerror($1);
                            yyerror("Needs to be an array!");
                            exit(1);
                        }//end if
                        //Now we're happy
                        $$ = ASTcreateNode(IDENT);
                        $$->Name = $1;
                        $$->s1 = $3;
                        $$->symbol = s;//store the pointer to symbol
                        $$->semType = s->Type; //pull it form the symbol table
                    }
            ;//OK
            
SIMPEXPRESSION  :   ADDEXPR {$$ = $1;}
                |   SIMPEXPRESSION RELOP ADDEXPR 
                        {
                            if($1->semType != $3->semType){
                                yyerror("Type mismatch in SIMPEXPRESSION");
                                exit(1);
                            }//end if
                            $$ = $$ = ASTcreateNode(EXPR);
                            $$->s1 = $1;
                            $$->s2 = $3;
                            $$->operator = $2;
                            $$->semType = $1->semType;
                            $$->Name=CreateTemp();
                            $$->symbol=Insert($$->Name,INTTYPE,0,level,1,offset, NULL);
                            offset++;
                        }
                ;//OK
                
RELOP       :   LE {$$ = LESSEQUAL;}//included these in the <operator> union 
            |   GE {$$ = GREATEREQUAL;}//pass them up
            |   LT {$$ = LESSTHAN;}
            |   GT {$$ = GREATERTHAN;}
            |   EQ {$$ = EQUALTO;}
            |   NE {$$ = NOTEQUAL;}
            ;//OK
            
ADDEXPR     :   TERM {$$ = $1;}
            |   ADDEXPR ADDOP TERM 
                    {
                        if($1->semType != $3->semType){
                            yyerror("Type mismatch for addexpr");
                            exit(1);
                        }//end if
                        $$ = ASTcreateNode(EXPR);
                        $$->s1 = $1;//s1 is now an addexpr
                        $$->s2 = $3;//s2 is now the term
                        $$->operator = $2;//sets operator to the operation
                        $$->semType = $1->semType;
                        $$->Name=CreateTemp();
                        $$->symbol=Insert($$->Name,INTTYPE,0,level,1,offset, NULL);
                        offset++;
                    } 
            ;//OK
            
ADDOP       :   '+' {$$ = PLUS;}
            |   '-' {$$ = MINUS;}
            ;//OK

            
/* isafunc
    0 -> scalar
    1 -> function
    2 -> array
*/
TERM		: 	FACTOR  {$$ = $1;}
			|	TERM MULTOP FACTOR 
                    {
                        if($1->semType != $3->semType){
                            yyerror("Type mismatch for term");
                            exit(1);
                        }//end if
                        $$ = ASTcreateNode(EXPR);
						$$->s1 = $1;
						$$->s2 = $3;
						$$->operator = $2;
						$$->semType = $1->semType;
						$$->Name=CreateTemp();
                        $$->symbol=Insert($$->Name,INTTYPE,0,level,1,offset, NULL);
                        offset++;
                    }
			;//OK
			
MULTOP		:	'*' {$$ = MULTIPLY;}
			|	'/' {$$ = DIVIDE;}
			|	AND {$$ = ANDOP;}
			|	OR  {$$ = OROP;}
			;//OK
			
FACTOR		:	'(' EXPRESSION ')' {$$ = $2;}
			|	NUM {$$ = ASTcreateNode(MYNUM);
                     		$$->size = $1;
                     		$$->semType = INTTYPE;
                    }//end SDSA for NUM
			|	VAR    {$$ = $1;}
			|	CALL   {$$ = $1;}//ok
			|	TRUE   {$$ = ASTcreateNode(MYNUM);
                        $$->size = 1;
                        $$->semType = BOOLEANTYPE;}
			| 	FALSE  {$$ = ASTcreateNode(MYNUM);
                        $$->size = 0;
                        $$->semType = BOOLEANTYPE;}
			|	NOT FACTOR     {
                                if($2->semType != BOOLEANTYPE){
                                    //if the semtype isnt a boolean, barf
                                    yyerror("Not factor needs a boolean type!");
                                    exit(1);
                                }//end if
                                $$ = ASTcreateNode(EXPR);
                                $$->s1 = $2;
                                $$->operator = MYNOT;
                                $$->semType = $2->semType;
                                }
			;//OK
			
CALL		:	ID '('ARGS')' 
                    {
                        struct SymbTab *s;
                        s = Search($1, level, 1);
                        //see if its there
                        if(s == NULL){
                            yyerror($1);
                            yyerror(" function is not defined!");
                            exit(1);
                        }//end if
                        //cant be a variable
                        if(s->IsAFunc != 1){
                            yyerror($1);
                            yyerror(" Needs to be a function!");
                            exit(1);
                        }//end if
                        //Now we're happy
                        
                        $$ = ASTcreateNode(MYCALL);
                        $$->Name = $1;
                        $$->s1 = $3;
                        $$->symbol = s;
                        $$->semType = s->Type;//type comes form symbol table
                    }
			;
			
ARGS		:	/**/ {$$ = NULL;}//THESE ARE CORRECT JUST UNCOMMENT TO GET THEM WORKING
			|	ARGLIST {$$ = $1;}
			;
			
ARGLIST		:	EXPRESSION { $$ = ASTcreateNode(ARG);
                             $$->s1 = $1;
                             $$->Name=CreateTemp();
                             $$->symbol=Insert($$->Name,INTTYPE,0,level,1,offset, NULL);
                                offset++;
                            }
			|	EXPRESSION ',' ARGLIST { $$ = ASTcreateNode(ARG); //SWITCHED ORDER OF EXPRESSION AND ARGLIST BECAUSE I HAD THE WRONG TYPE OF RECURSION
                                         $$->s1 = $1;//s1 is now the expression, 
                                         $$->next = $3;//next is the arglist
                                         $$->Name=CreateTemp();
                                         $$->symbol=Insert($$->Name,INTTYPE,0,level,1,offset, NULL);
                                         offset++;
                                        }
			;
%%	/* end of rules, start of program */

int main(int argc, char * argv[])
{
    int i = 1;
    char s[100];
    FILE * fd;
    int foundit = 0;
    while (i < argc){
        //check if our argument is "-d"
        if(strcmp(argv[i],"-d") == 0){
            mydebug = 1;
        }//if we want to turn on debug
        else if(strcmp(argv[i],"-o")==0){
            //we assume that i + 1 is a file prefix (a file we want to create / open)
            if(argc > (i+1))foundit  = 1;
            sprintf(s, "%s.asm",argv[i+1]);
            i = i + 2;
        }
        else i = i + 1;
        i = i+ 1;
    }//end while
    if(foundit == 0){
        printf("You have to give me a -o argument \n");
        exit(1);
    }
    fd = fopen(s,"w");
    if(fd == NULL){
        printf("Cannot open file %s \n", s);
        exit(1);
    }//if we couldnt find a file
    printf("my debug is %d\n", mydebug);
    printf("my file name is %s\n", s);
    printf("main has %d arguments with %s as the string \n", argc, argv[0]);
    yyparse();
    //fprintf(stderr, "The input is syntactically correct.\n");
    //commented because we dont need this for lab9
    //this prints out the tree starting from the global pointer
    //ASTprint(GlobalTreePointer, 0);
    fprintf(fd, ".data\n\n");
    EMITSTRINGS(GlobalTreePointer, fd); //print out all the strings
    fprintf(fd, "NL:\t.asciiz\t\"\\n\"\n");
    fprintf(fd, ".align 2\n\n");
    EMITGLOBALS(GlobalTreePointer, fd);
    fprintf(fd, "\n.text\n\n");
    fprintf(fd, "\n.globl main\n");
    EMITAST(GlobalTreePointer, fd);
}
