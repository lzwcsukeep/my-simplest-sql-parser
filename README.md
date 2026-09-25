下面是一个**最小但完整的 Flex + Bison SQL 解析器 Demo**，结构为：

```text
myparser/
├── parser.y       ← Bison：语法规则
├── lexer.l        ← Flex：词法分析
└── main.c         ← 调用 yyparse()
```

我们让它支持解析：

```sql
CREATE TABLE test (id INT);
```

并最终构造一个非常简单的 AST。

------

# 1. 目录结构

```text
myparser/
├── parser.y
├── lexer.l
└── main.c
```

------

# 2. `parser.y`

这是 **Bison grammar**。

```y
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
```

------

# 3. `lexer.l`

这是 **Flex lexer**。

它负责把：

```sql
CREATE TABLE test (id INT);
```

转换成：

```text
CREATE
TABLE
IDENT("test")
LPAREN
IDENT("id")
TYPE_NAME("INT")
RPAREN
SEMICOLON
```

代码：

```lex
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "parser.tab.h"
%}


/*
 * Flex 的一些定义
 */

%%


/*
 * 关键字
 */

"CREATE"        { return CREATE; }

"TABLE"         { return TABLE; }


/*
 * 符号
 */

"("             { return LPAREN; }

")"             { return RPAREN; }

";"             { return SEMICOLON; }


/*
 * 数据类型
 */

"INT"           {
                    yylval.str = strdup(yytext);
                    return TYPE_NAME;
                }


/*
 * 标识符
 *
 * 例如：
 *
 * test
 * users
 * id
 */
[a-zA-Z_][a-zA-Z0-9_]*  {
                            yylval.str = strdup(yytext);
                            return IDENT;
                         }


/*
 * 空白字符
 */

[ \t\r\n]+      {
                    /* ignore */
                }


/*
 * 其他字符
 */

.               {
                    return yytext[0];
                }


%%
```

------

# 4. `main.c`

`main.c` 非常简单。

```c
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
```

------

# 5. 编译

首先确认：

```bash
bison --version
flex --version
gcc --version
```

然后：

```bash
bison -d parser.y
```

生成：

```text
parser.tab.c
parser.tab.h
```

然后：

```bash
flex lexer.l
```

生成：

```text
lex.yy.c
```

现在目录：

```text
myparser/
├── parser.y
├── lexer.l
├── main.c
├── parser.tab.c
├── parser.tab.h
└── lex.yy.c
```

编译：

```bash
gcc \
    parser.tab.c \
    lex.yy.c \
    main.c \
    -o myparser
```

如果系统需要显式链接 Flex 库，也可以：

```bash
gcc \
    parser.tab.c \
    lex.yy.c \
    main.c \
    -lfl \
    -o myparser
```

------

# 6. 运行

```bash
./myparser
```

输入：

```sql
CREATE TABLE test (id INT);
```

得到：

```text
Input SQL:
CREATE TABLE test (id INT);
Parser: CREATE TABLE statement matched

Parse successfully!

Table name : test
Column name: id
Column type: INT
```

------

# 7. 现在重点看整个调用关系

这是这个 Demo 最重要的地方。

程序启动：

```text
main.c
  |
  |
  | yyparse()
  v
Bison Parser
parser.tab.c
  |
  |
  | yylex()
  v
Flex Lexer
lex.yy.c
  |
  |
  v
stdin
```

所以：

```text
                 main()
                   |
                   v
               yyparse()
                   |
             Bison Parser
                   |
                   | 请求 token
                   v
                yylex()
                   |
              Flex Lexer
                   |
                   v
                stdin
```

------

# 8. 输入 `CREATE TABLE test (id INT);` 后发生什么？

首先：

```text
main()
 |
 +-- yyparse()
```

进入 Bison 生成的 parser。

Parser 需要第一个 token，于是：

```text
yyparse()
   |
   +-- yylex()
```

Flex 看到：

```text
CREATE
```

匹配：

```lex
"CREATE" { return CREATE; }
```

于是返回：

```text
CREATE
```

------

接下来 Parser 再调用：

```text
yylex()
```

Flex 看到：

```text
TABLE
```

返回：

```text
TABLE
```

------

接下来：

```text
test
```

匹配：

```lex
[a-zA-Z_][a-zA-Z0-9_]*
```

执行：

```c
yylval.str = strdup(yytext);
return IDENT;
```

所以返回：

```text
IDENT
```

同时：

```text
yylval.str
      |
      v
   "test"
```

------

# 9. `yylval` 是什么？

这个东西非常重要。

Lexer 不仅要告诉 Parser：

> “我发现了一个 IDENT。”

有时候还需要告诉 Parser：

> “这个 IDENT 的具体值是 `test`。”

所以：

```c
yylval.str = strdup(yytext);
```

就是把：

```text
test
```

传给 Parser。

然后：

```y
table_name:
      IDENT
    {
        $$ = $1;
    }
```

这里：

```text
$1
```

就是：

```text
"test"
```

最终：

```text
$$
```

也是：

```text
"test"
```

所以：

```text
IDENT("test")
      |
      v
table_name
      |
      v
"test"
```

------

# 10. Parser 最终匹配哪个 grammar？

输入：

```sql
CREATE TABLE test (id INT);
```

Lexer 返回：

```text
CREATE
TABLE
IDENT("test")
LPAREN
IDENT("id")
TYPE_NAME("INT")
RPAREN
SEMICOLON
```

Parser 根据 `parser.y`：

```y
create_table_stmt:
      CREATE TABLE table_name
      LPAREN column_name column_type RPAREN
      SEMICOLON
```

进行归约：

```text
CREATE
TABLE
IDENT
(
IDENT
TYPE_NAME
)
;
```

↓

```text
CREATE TABLE
table_name
(
column_name
column_type
)
;
```

↓

```text
create_table_stmt
```

然后执行 semantic action：

```c
{
    result = malloc(sizeof(CreateTableStmt));

    result->table_name = $3;
    result->column_name = $5;
    result->column_type = $6;
}
```

最终得到：

```text
CreateTableStmt
       |
       +-- table_name  = "test"
       |
       +-- column_name = "id"
       |
       +-- column_type = "INT"
```

这其实已经非常接近 PostgreSQL 的思路了。

------

# 11. 对照 PostgreSQL

现在再看 PostgreSQL，就会非常清楚。

我们的 Demo：

```text
lexer.l
   |
 Flex
   |
   v
yylex()
   |
   v
parser.y
   |
 Bison
   |
   v
yyparse()
```

PostgreSQL：

```text
src/backend/parser/scan.l
             |
            Flex
             |
             v
       base_yylex()
             |
             v
src/backend/parser/gram.y
             |
           Bison
             |
             v
       base_yyparse()
             |
             v
      PostgreSQL Parse Tree
```

而 Bootstrap：

```text
src/backend/bootstrap/bootscanner.l
             |
            Flex
             |
             v
       boot_yylex()
             |
             v
src/backend/bootstrap/bootparse.y
             |
           Bison
             |
             v
       boot_yyparse()
```

所以你之前看到：

```c
boot_yyparse();
```

现在可以非常具体地理解成：

> **调用 Bison 根据 `bootparse.y` 生成的 Parser，让它开始从 `boot_yylex()` 获取 token，并按照 PostgreSQL bootstrap grammar 解析输入。**

------

## 12. 这个 Demo 和 PostgreSQL 的对应关系

| 我们的 Demo    | PostgreSQL                          |
| -------------- | ----------------------------------- |
| `lexer.l`      | `scan.l` / `bootscanner.l`          |
| `yylex()`      | `base_yylex()` / `boot_yylex()`     |
| `parser.y`     | `gram.y` / `bootparse.y`            |
| `yyparse()`    | `base_yyparse()` / `boot_yyparse()` |
| `IDENT`        | PostgreSQL 的各种 token             |
| `yylval`       | token 携带的语义值                  |
| `$$`           | grammar rule 的结果                 |
| `$1` `$2` `$3` | rule 中各 symbol 的语义值           |
| `result`       | PostgreSQL 的 Parse Tree / Node     |

你可以先把这个 Demo 编译跑通，然后**最值得做的下一步是打开生成的 `parser.tab.c`，搜索 `yyparse`，看看 Bison 是如何把你写的 `parser.y` 转换成一个真正的 shift/reduce Parser 的**。这样就能把“`.y` → `yyparse()`”这条链彻底打通。