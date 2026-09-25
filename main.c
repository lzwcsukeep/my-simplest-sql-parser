#include <stdio.h>
#include <stdlib.h>

/*
 * Bison 生成的 parser
 */
int yyparse(void);


/*
 * parser.y 中定义的 AST
 */
typedef struct CreateTableStmt
{
    char *table_name;
    char *column_name;
    char *column_type;
} CreateTableStmt;


/*
 * parser.y 中的全局变量
 */
extern CreateTableStmt *result;


int main(void)
{
    printf("Input SQL:\n");

    /*
     * 启动 Bison Parser
     */
    if (yyparse() == 0)
    {
        printf("\nParse successfully!\n");

        printf("Table name : %s\n", result->table_name);
        printf("Column name: %s\n", result->column_name);
        printf("Column type: %s\n", result->column_type);
    }
    else
    {
        printf("\nParse failed!\n");
    }

    return 0;
}

