%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "parser.tab.h"
%}


/* Flex 的一些定义 */

%%

"CREATE"        { return CREATE; }

"TABLE"         { return TABLE; }



"("             { return LPAREN; }

")"             { return RPAREN; }

";"             { return SEMICOLON; }



"INT"           {
                    yylval.str = strdup(yytext);
                    return TYPE_NAME;
                }



[a-zA-Z_][a-zA-Z0-9_]*  {
                            yylval.str = strdup(yytext);
                            return IDENT;
                         }



[ \t\r\n]+      {
                    /* ignore */
                }



.               {
                    return yytext[0];
                }


%%