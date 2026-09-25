%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * AST
 */
typedef struct CreateTableStmt
{
    char *table_name;
    char *column_name;
    char *column_type;
} CreateTableStmt;

/*
 * lexer.l 会提供
 */
int yylex(void);
void yyerror(const char *s);

/*
 * 保存最终生成的 AST
 */
CreateTableStmt *result = NULL;
%}


/*
 * YYSTYPE 是 token / grammar symbol 携带的数据类型。
 *
 * 我们这里简单一点：
 * 所有字符串都使用 char *
 */
%union
{
    char *str;
}


/*
 * Token
 */
%token CREATE
%token TABLE
%token LPAREN
%token RPAREN
%token SEMICOLON

%token <str> IDENT
%token <str> TYPE_NAME


/*
 * non-terminal 的类型
 */
%type <str> table_name
%type <str> column_name
%type <str> column_type


%%


/*
 * 最顶层 grammar
 */
input:
      create_table_stmt
    ;


/*
 * CREATE TABLE test (id INT);
 *
 *           $1       $2      $3
 */
create_table_stmt:
      CREATE TABLE table_name
      LPAREN column_name column_type RPAREN
      SEMICOLON
    {
        result = malloc(sizeof(CreateTableStmt));

        result->table_name = $3;
        result->column_name = $5;
        result->column_type = $6;

        printf("Parser: CREATE TABLE statement matched\n");
    }
    ;


/*
 * 表名
 */
table_name:
      IDENT
    {
        $$ = $1;
    }
    ;


/*
 * 列名
 */
column_name:
      IDENT
    {
        $$ = $1;
    }
    ;


/*
 * 列类型
 */
column_type:
      TYPE_NAME
    {
        $$ = $1;
    }
    ;


%%


/*
 * Bison parser 出错时调用
 */
void yyerror(const char *s)
{
    fprintf(stderr, "Parser error: %s\n", s);
}