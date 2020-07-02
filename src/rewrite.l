%{
#include <stdio.h>
#include <string.h>
#include "rewrite.tab.h"
#include "node.h"

struct nodeType* newTokenNode(int tokenType);

int line_no = 1;
int chr_no = 0;

#define YY_USER_ACTION chr_no+=yyleng;

%}

A [aA]
B [bB]
C [cC]
D [dD]
E [eE]
F [fF]
G [gG]
H [hH]
I [iI]
J [jJ]
K [kK]
L [lL]
M [mM]
N [nN]
O [oO]
P [pP]
Q [qQ]
R [rR]
S [sS]
T [tT]
U [uU]
V [vV]
W [wW]
X [xX]
Y [yY]
Z [zZ]
_ [_]

DIGIT [0-9]

%%

{R}{E}{W}{R}{I}{T}{E}{_}{S}{T}{A}{R}{T} 	{yylval.node = newTokenNode(REWRITE_START); return(REWRITE_START);}
{R}{E}{W}{R}{I}{T}{E}{_}{E}{N}{D}	    	{yylval.node = newTokenNode(REWRITE_END); return(REWRITE_END);}
{R}{E}{W}{R}{I}{T}{E}{_}{I}{F}		 	{yylval.node = newTokenNode(REWRITE_START); return(IF);}
{R}{E}{W}{R}{I}{T}{E}{_}{F}{O}{R}	 	{yylval.node = newTokenNode(REWRITE_START); return(WHILE);}
{R}{E}{W}{R}{I}{T}{E}{_}{S}{T}{R}{I}{N}{G} 	{yylval.node = newTokenNode(STRING); return(STRING);}
{R}{E}{W}{R}{I}{T}{E}{_}{N}{U}{M}{B}{E}{R} 	{yylval.node = newTokenNode(INTEGER); return(INTEGER);}
{R}{E}{W}{R}{I}{T}{E}{_}{D}{E}{C}{L}{A}{R}{A}{C}{I}{O}{N} 	{yylval.node = newTokenNode(DECLARACION); return(DECLARACION);}

"{"	      		     {yylval.node = newTokenNode(YINICIO); return(YINICIO);}
"}"	      		     {yylval.node = newTokenNode(YFINAL); return(YFINAL);}

{E}{L}{S}{E}                 {yylval.node = newTokenNode(ELSE); return(ELSE);}
[a-zA-Z]([a-zA-Z0-9])*       {yylval.node = newTokenNode(IDENTIFICADOR); yylval.node->string = (char*) malloc(yyleng+1); strcpy(yylval.node->string, yytext); return(IDENTIFICADOR);}
{DIGIT}*[a-zA-Z]+            fprintf(stdout, "[ERROR] %s nombre de IDENTIFICADOR incorrecto en %d:%d\n", yytext, line_no, chr_no-yyleng+1);
[a-zA-Z]+([@$?_])+  fprintf(stdout, "[ERROR] %s nombre de IDENTIFICADOR incorrecto\n", yytext);
\n                           {line_no++; chr_no = 0;}
":"                          {yylval.node = newTokenNode(DOSPUNTOS); return(DOSPUNTOS);}
"="                          {yylval.node = newTokenNode(ASIGNACION); return(ASIGNACION);}
","                          {yylval.node = newTokenNode(COMA); return(COMA);}
{DIGIT}+                     {yylval.node = newTokenNode(DIGSEQ); yylval.node->valueValid = VALUE_I_VALID; yylval.node->iValue = atoi(yytext); return(DIGSEQ);}
"."                          {yylval.node = newTokenNode(PUNTO); return(PUNTO);}
"=="                          {yylval.node = newTokenNode(EQUAL); yylval.node->op = OP_EQ; return(EQUAL);}
"!="                         {yylval.node = newTokenNode(notEQUAL); yylval.node->op = OP_NE; return(notEQUAL);}
">="                         {yylval.node = newTokenNode(GE); yylval.node->op = OP_GE; return(GE);}
">"                          {yylval.node = newTokenNode(GT); yylval.node->op = OP_GT; return(GT);}
"<="                         {yylval.node = newTokenNode(LE); yylval.node->op = OP_LE; return(LE);}
"["                          {yylval.node = newTokenNode(LCORCHETE); return(LCORCHETE);}
"("                          {yylval.node = newTokenNode(LPAREN); return(LPAREN);}
"<"                          {yylval.node = newTokenNode(LT); yylval.node->op = OP_LT; return(LT);}
"-"                          {yylval.node = newTokenNode(MENOS); yylval.node->op = OP_SUB; return(MENOS);}
"+"                          {yylval.node = newTokenNode(SUMA); yylval.node->op = OP_ADD; return(SUMA);}

({DIGIT}+|{DIGIT}+"."{DIGIT}+)E(''|[+-])(''|{DIGIT}+|{DIGIT}+"."{DIGIT}+)     return(NUMBER);
{DIGIT}+"."{DIGIT}+          {yylval.node = newTokenNode(NUMBER); yylval.node->valueValid = VALUE_R_VALID; yylval.node->rValue=atof(yytext); return(NUMBER);}
"]"                          {yylval.node = newTokenNode(RCORCHETE); return(RCORCHETE);}
")"                          {yylval.node = newTokenNode(RPAREN); return(RPAREN);}
";"                          {yylval.node = newTokenNode(PUNTOYCOMA); return(PUNTOYCOMA);}
"/"                          {yylval.node = newTokenNode(SLASH); yylval.node->op = OP_DIV; return(SLASH);}
"*"                          {yylval.node = newTokenNode(STAR); yylval.node->op = OP_MUL; return(STAR);}

"//".*\n                     {fprintf (stdout, "%s", yytext); chr_no = 0; line_no++;}
\'([^\'\n]|\\\'|'')*\'       {yylval.node = newTokenNode(CHARACTER_STRING); yylval.node->string = yytext; return(CHARACTER_STRING);}
\"([^\"\n]|\\\"|'')*\"       {yylval.node = newTokenNode(CHARACTER_STRING); yylval.node->string = yytext; return(CHARACTER_STRING);}

\'([^\']|\\\'|\n)*\' {
fprintf(stdout, "linea %d:%d Cross-Line String %s\n", line_no, chr_no-yyleng+1, yytext);
register int c;
for (c = 0; c < strlen(yytext); c++)
       if (c == '\n') line_no++;
}
\"([^\"]|\\\"|\n)*\" {
fprintf(stdout, "linea %d:%d Cross-Line String %s\n", line_no, chr_no, yytext);
register int c;
for (c = 0; c < strlen(yytext); c++)
       if (c == '\n') line_no++;
}
\"([^\"\n])*$ fprintf(stdout, "[ERROR] String suelto %s detectado en %d:%d\n", yytext, line_no, chr_no-yyleng+1);
\'([^\'\n])*$ fprintf(stdout, "[ERROR] String suelto %s detectado en %d:%d\n", yytext, line_no, chr_no-yyleng+1);
"(*"   { register int c;
     while ((c = input()))
     {
      if (c == '*')
      {
       if ((c = input()) == ')')
        break;
       else
        unput (c);
      }
      else if (c == '\n')
       line_no++;
      else if (c == 0)
        fprintf (stdout, "[ERROR] dato inesperado dentr de una linea de comentario %d\n",line_no);
     }
    }

[ \t\f]    ;

\r         ;
.    {fprintf(stdout,"[ERROR] error analizador lexico en la linea %d : %s\n",line_no,yytext);}
<<EOF>>    return END_OF_FILE;

%%

int yywrap() {
  fclose(yyin);
  exit(1);
return 0;
}

struct nodeType* newTokenNode(int tokenType) {
  struct nodeType *node = newNode(NODE_TOKEN);
  node->tokenType = tokenType;
  return node;
}
