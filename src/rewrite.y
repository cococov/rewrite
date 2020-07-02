%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "node.h"
  #include "symtab.h"
  #include "gencode.h"

  struct nodeType* newOpNode(int op);
  extern struct nodeType* ASTRoot;

  void yyerror(const char *str) {
    extern char *yytext;
    extern int line_no, chr_no;
    fprintf(stdout, "[ERROR] %s en la linea %d:%d symbol '%s'\n", str, line_no, chr_no, yytext);
    exit(0);
  }
%}

%union {
  struct nodeType *node;
}

%token <node> DECLARACION ELSE YFINAL IDENTIFICADOR IF YINICIO WHILE ASIGNACION DOSPUNTOS COMA REWRITE_START REWRITE_END PUNTO EQUAL GE GT LCORCHETE LE LPAREN LT MENOS NOTEQUAL SUMA RCORCHETE RPAREN PUNTOYCOMA SLASH DSTAR STAR notEQUAL INTEGER STRING DIGSEQ NUMBER CHARACTER_STRING END_OF_FILE

%type <node> goal prog identifier_list block compound_statement statement_list statement constant type var_list var_declaration standard_type optional_statements else_statement expression procedure_statement variable tail term simple_expression factor relop var_asgn expression_list negative


%%
goal: prog {
  fprintf(stdout, "\n");
  ASTRoot = $1; YYACCEPT;
};
prog : REWRITE_START block compound_statement REWRITE_END {
  $$ = newNode(NODE_PROGRAM); 
  addChild($$, $2);
  addChild($$, $3);
  deleteNode($1); deleteNode($4);
}| error END_OF_FILE {
  fprintf(stdout, "[ERROR]\n");
  yyerrok;
}; 

identifier_list : IDENTIFICADOR {
  $$ = newNode(NODE_LIST);
  addChild($$, $1);
}| identifier_list COMA IDENTIFICADOR {
  $$ = $1;
  addChild($$, $3);
  deleteNode($2);
};

negative: MENOS DIGSEQ {
  $$ = newNode(NODE_INT); $$->iValue = -($2->iValue);
  deleteNode($1);
} | MENOS NUMBER {
  $$ = newNode(NODE_REAL); $$->rValue = -($2->rValue);
  deleteNode($1);
};

standard_type: INTEGER {
  $$ = newNode(NODE_TYPE_INT);
}| STRING {
  $$ = newNode(NODE_TYPE_CHAR);
};

type : standard_type {
  $$ = $1;
} | IDENTIFICADOR {
   $$ = $1;
};

var_asgn : type identifier_list {
  $$ = newNode(NODE_VAR_DECL);
  addChild($$, $2); addChild($$, $1);
};

var_list : var_asgn {
  $$ = newNode(NODE_LIST);
  addChild($$, $1);
}| var_list var_asgn {
  $$ = $1;
  addChild($$, $2);
};

block : var_declaration {
  $$ = newNode(NODE_BLOCK);
  addChild($$, $1);
};

var_declaration : var_declaration var_list {
  $$ = $1;
  addChild($$, $2);
}| {
  $$ = newNode(NODE_LIST);
}| error PUNTOYCOMA {
  fprintf(stdout, "[ERROR] declaracion de variable incorrecta\n");
  yyerrok;
};

compound_statement : YINICIO optional_statements YFINAL {
  $$ = $2;;
  deleteNode($1); deleteNode($3);
}| error YFINAL {
  fprintf(stdout, "[ERROR] declaracion compuesta incorrecta.\n");
  yyerrok;
};
optional_statements : statement_list {
  $$ = $1;
};
statement_list : statement {
  $$ = newNode(NODE_LIST);
  addChild($$, $1);
}| statement_list statement {
  $$ = $1;
  addChild($$, $2);
};
else_statement : ELSE statement {
  $$ = newNode(NODE_ELSE);
  addChild($$, $2); deleteNode($1);
}| {
  $$ = newNode(NODE_EMPTY);
};
statement : variable ASIGNACION expression {
  $$ = newNode(NODE_ASSIGN_STMT);
  addChild($$, $1);
  addChild($$, $3);
  $1->nodeType = NODE_SYM_REF;
  deleteNode($2);
}| procedure_statement {
  $$ = $1;
}| compound_statement {
  $$ = $1;
}| IF expression statement else_statement {
  $$ = newNode(NODE_IF);
  addChild($$, $2); addChild($$, $3); addChild($$, $4);
  deleteNode($1);
}| WHILE expression statement {
  $$ = newNode(NODE_WHILE);
  addChild($$, $2); addChild($$, $3);
  deleteNode($1);
}| {
  $$ = newNode(NODE_EMPTY);
};

variable : IDENTIFICADOR tail {
  $$ = newNode(NODE_VAR);
  $$->string = $1->string;
  addChild($$, $1); addChild($$, $2);
 } | IDENTIFICADOR {
   $$ = newNode(NODE_VAR);
   $$->string = $1->string;
   addChild($$, $1);
};
tail : LCORCHETE expression RCORCHETE tail {
  $$ = $4;
  addChild($$, $2);
  deleteNode($1); deleteNode($3);
}| LCORCHETE expression RCORCHETE {
  $$ = newNode(NODE_LIST);
  addChild($$, $2);
  deleteNode($1); deleteNode($3);
};
procedure_statement : IDENTIFICADOR {
  $$ = $1;
  $$->nodeType = NODE_VAR_OR_PROC;
}| IDENTIFICADOR LPAREN expression_list RPAREN {
  $$ = newNode(NODE_PROC_STMT);
  addChild($$, $1); addChild($$, $3);
  deleteNode($2); deleteNode($4);
};
expression_list : expression {
  $$ = newNode(NODE_LIST);
  addChild($$, $1);
}| expression_list COMA expression {
  $$ = $1;
  addChild($$, $3);
  deleteNode($2);
};
expression : simple_expression {
  $$ = $1;
}| simple_expression relop simple_expression {
  $$ = newOpNode($2->op);
  addChild($$, $1); addChild($$, $3);
};
simple_expression : term {
  $$ = $1;
}| simple_expression SUMA term {
  $$ = newOpNode(OP_ADD);
  addChild($$, $1); addChild($$, $3);
  deleteNode($2);
}| simple_expression MENOS term {
  $$ = newOpNode(OP_SUB);
  addChild($$, $1); addChild($$, $3);
  deleteNode($2);
}| negative {
  $$ = $1;
};
term : factor {
  $$ = $1;
}| term STAR factor {
  $$ = newOpNode(OP_MUL);
  addChild($$, $1);
  addChild($$, $3);
  deleteNode($2); 
} | term SLASH factor {
  $$ = newOpNode(OP_DIV);
  addChild($$, $1);
  addChild($$, $3);
  deleteNode($2);
};
constant : NUMBER {
  $$ = $1;
  $$->nodeType = NODE_REAL;
}| DIGSEQ {
  $$ = $1;
  $$->nodeType = NODE_INT;
}| CHARACTER_STRING {
  $$ = newNode(NODE_CHAR);
  char *str = malloc(sizeof(char)*50);
  strcpy(str, $1->string);
  $$->string = str;
};
factor : IDENTIFICADOR {
  $$ = $1;
  $$->nodeType = NODE_VAR_OR_PROC;
 }| IDENTIFICADOR tail {
  $$ = newNode(NODE_SYM_REF);
  $$->string = $1->string;
  addChild($$, $1); addChild($$, $2);
 } | IDENTIFICADOR LPAREN expression_list RPAREN {
  $$ = newNode(NODE_PROC_STMT);
  addChild($$, $1); addChild($$, $3);
  deleteNode($2); deleteNode($4);
}| constant {
  $$ = $1;
}| LPAREN expression RPAREN {
  $$ = $2;
  deleteNode($1); deleteNode($3);
}| error RPAREN {
  fprintf(stdout, "[ERROR] factor equivocado.\n");
  yyerrok;
};
relop : LT { $$->op = OP_LT; }
| GT { $$->op = OP_GT; }
| EQUAL { $$->op = OP_EQ; }
| LE { $$->op = OP_LE; }
| GE { $$->op = OP_GE; }
| notEQUAL { $$->op = OP_NE; }
;
%%

struct nodeType *ASTRoot;

struct nodeType* newOpNode(int op) {
    struct nodeType *node = newNode(NODE_OP);
    node->op = op;

    return node;
}

int main(int argc, char** argv) {  
  int res;
  if (argc != 3) { fprintf(stdout, "[ERROR] por favor ingrese [INPUT].rwrt y [OUTPUT].j!\n"); exit(1); }
  if (NULL == freopen(argv[1], "r", stdin)) { fprintf(stdout, "[ERROR] No se puede abrir el archivo. %s\n", argv[1]); exit(1); }
  yyparse();
  printf("[Sin errores de sintaxis]\n");
  semanticCheck(ASTRoot);
  if(SymbolTable.error == 0)
    printf("[Sin errores semanticos]\n");
  printf("\n\nPrograma compilado con exito...\n"); 
  char *outFile = (char *)malloc(sizeof(char)*(strlen(argv[2])+3));
  strcpy(outFile, argv[2]); strcat(outFile, ".j");
  if (NULL == freopen(outFile, "w", stdout)) { fprintf(stderr, "[ERROR] No se puede escirbir en el archivo. %s\n", outFile); exit(1);}
  genCode(ASTRoot, argv[2]);   
  return 0;
}
