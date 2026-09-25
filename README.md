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

------

# 4. `main.c`

`main.c` 非常简单。

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
