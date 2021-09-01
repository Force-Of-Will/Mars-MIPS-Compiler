%{
/*    
Lex that parses for tokens
(Used for Compiler)
Benjamin Longwell, April 3, 2020
*/
int mydebug=0;
int linecount = 1;

#include "ast.h"
#include "y.tab.h"
%}

%%
int         {return(INT);}
void        {return(VOID);}
boolean     {return(BOOLEAN);}
"begin"     {return(MYBEGIN);}
end         {return(END);}
if          {return(IF);}
then        {return(THEN);}
else        {return(ELSE);}
while       {return(WHILE);}
do          {return(DO);}
"return"    {return(MYRETURN);}
read        {return(READ);}
write       {return(WRITE);}
"<="        {return(LE);}
"<"         {return(LT);}
">"         {return(GT);}
">="        {return(GE);}
"=="        {return(EQ);}
"!="        {return(NE);}
and         {return(AND);}
or          {return(OR);}
true        {return(TRUE);}
false       {return(FALSE);}
not         {return(NOT);}

\".*\"      {   //ADDED DURING FINAL LAB SO WE CAN USE STRINGS
                yylval.string=strdup(yytext); 
                return(STRING);
            }

[a-zA-Z]+[a-zA-Z0-9]*		{if (mydebug) fprintf(stderr,"Letter found\n"); //if debug is on, say Letter Found
                                yylval.string=strdup(yytext); return(ID);}//shows the value of the letter as a number
[0-9][0-9]*	{if (mydebug) fprintf(stderr,"Digit found\n"); 
                       yylval.value=atoi((const char *)yytext); return(NUM);}
[ \t]		{if (mydebug) fprintf(stderr,"Whitespace found\n");}
[\[\]=\-+**/%&|;(),] 	{ if (mydebug) fprintf(stderr,"return a token %c\n",*yytext); 
                       return (*yytext);}
\n 		{ if (mydebug) fprintf(stderr,"cariage return %c\n",*yytext); linecount++;}

%%

int yywrap(void)
{ return 1;}
