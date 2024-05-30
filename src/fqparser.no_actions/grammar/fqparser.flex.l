/* fqparser.flex.l */

/*
MIT License

Copyright (c) 2024 Zartaj Majeed

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

 // c++-style comments can start at second column outside rules section
/* c-style commens can start at first column outside rules section */

 // c++ scanner
%option c++

 // custom c++ lexer class
%option yyclass="Lexer"

 // custom prefix to rename yyFlexLexer class in flex header to FQFlexLexer
%option prefix="FQParser"

 // enable states stack
%option stack

%option warn

%option 8bit

%option debug

%option nodefault

%option never-interactive

%option noyywrap

%option nounput noinput batch

 // flex start conditions ie states
%x STARTING_POINTS_WHITESPACE
%x STARTING_POINTS
%x PRIMARY
%x STRING_ARG_WHITESPACE
%x STRING_ARG
%x NUMBER_ARG_WHITESPACE
%x NUMBER_ARG
%x SKIP_TO_EOL

%x EXEC_ARGS_WHITESPACE
%x EXEC_ARGS

%top{
// appears at top of generated .cpp file
}

%{
// appears after flex state tables and before start state defines before yylex in generated .cpp file

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string>

// bison generated header with C++ namespace and token definitions
#include "fqparser.bison.h"
#include "lexer/fqparser_lexer.h"

#undef YY_DECL
#define YY_DECL fqparser::FQParser::symbol_type fqparser::Lexer::yylex(location& loc)

// fix flex error could not convert 0 from int to symbol_type for #define YY_NULL 0
// caused by turning on bison %locations because symbol_type no longer has single int constructor for implicit conversion
#define yyterminate() return symbol_type(YY_NULL, loc)

using namespace std;
using namespace fqparser;

// needed for custom yyterminate
using symbol_type = FQParser::symbol_type;

%}

 // flex rules section
 /* only c-style comments starting at second column allowed inside rules section */

%%

 // code appears inside yylex function at start

  loc.step();
  int errState;
  char errChar;

 // token patterns

find {
  loc.columns(yyleng);
  yy_push_state(STARTING_POINTS_WHITESPACE);
  return FQParser::make_FIND(loc);
}

<STARTING_POINTS_WHITESPACE>{
  [[:space:]]* {
    yy_pop_state();
    loc.columns(yyleng);
    yy_push_state(STARTING_POINTS);
  }
}

 /* directory paths must not begin with any of [-!(] because these characters can be the start of a find primary term */
 /* workaround for directories that do begin with one of these characters is to use absolute paths or relative paths that start with "./" */
<STARTING_POINTS>{
  [-!(] {
    yy_pop_state();
    yy_push_state(PRIMARY);
    yyless(0);
  }

  [^-!(][[:^space:]]* {
    yy_pop_state();
    loc.columns(yyleng);
    yy_push_state(STARTING_POINTS_WHITESPACE);
    return FQParser::make_STARTING_POINT(yytext, loc);
  }
}

<PRIMARY>{

-amin {
  loc.columns(yyleng);
  return FQParser::make_AMIN(loc);
}

-and|-a {
  loc.columns(yyleng);
  return FQParser::make_AND(loc);
}

-anewer {
  loc.columns(yyleng);
  return FQParser::make_ANEWER(loc);
}

-atime {
  loc.columns(yyleng);
  return FQParser::make_ATIME(loc);
}

-cmin {
  loc.columns(yyleng);
  return FQParser::make_CMIN(loc);
}

-cnewer {
  loc.columns(yyleng);
  return FQParser::make_CNEWER(loc);
}

-ctime {
  loc.columns(yyleng);
  return FQParser::make_CTIME(loc);
}

-daystart {
  loc.columns(yyleng);
  return FQParser::make_DAYSTART(loc);
}

-delete {
  loc.columns(yyleng);
  return FQParser::make_DELETE(loc);
}

-depth {
  loc.columns(yyleng);
  return FQParser::make_DEPTH(loc);
}

-empty {
  loc.columns(yyleng);
  return FQParser::make_EMPTY(loc);
}

-exec {
  loc.columns(yyleng);
  return FQParser::make_EXEC(loc);
}

-execdir {
  loc.columns(yyleng);
  return FQParser::make_EXECDIR(loc);
}

-executable {
  loc.columns(yyleng);
  return FQParser::make_EXECUTABLE(loc);
}

-false {
  loc.columns(yyleng);
  return FQParser::make_FALSE(loc);
}

-files0-from {
  loc.columns(yyleng);
  return FQParser::make_FILES0_FROM(loc);
}

-fls {
  loc.columns(yyleng);
  return FQParser::make_FLS(loc);
}

-follow {
  loc.columns(yyleng);
  return FQParser::make_FOLLOW(loc);
}

-fstype {
  loc.columns(yyleng);
  return FQParser::make_FSTYPE(loc);
}

-fprint {
  loc.columns(yyleng);
  return FQParser::make_FPRINT(loc);
}

-fprint0 {
  loc.columns(yyleng);
  return FQParser::make_FPRINT0(loc);
}

-fprintf {
  loc.columns(yyleng);
  return FQParser::make_FPRINTF(loc);
}

-gid {
  loc.columns(yyleng);
  return FQParser::make_GID(loc);
}

-group {
  loc.columns(yyleng);
  return FQParser::make_GROUP(loc);
}

-help {
  loc.columns(yyleng);
  return FQParser::make_HELP(loc);
}

-ignore_readdir_race {
  loc.columns(yyleng);
  return FQParser::make_IGNORE_READDIR_RACE(loc);
}

-ilname {
  loc.columns(yyleng);
  return FQParser::make_ILNAME(loc);
}

-iname {
  loc.columns(yyleng);
  return FQParser::make_INAME(loc);
}

-inum {
  loc.columns(yyleng);
  return FQParser::make_INUM(loc);
}

-ipath {
  loc.columns(yyleng);
  return FQParser::make_IPATH(loc);
}

-iregex {
  loc.columns(yyleng);
  return FQParser::make_IREGEX(loc);
}

-iwholename {
  loc.columns(yyleng);
  return FQParser::make_IWHOLENAME(loc);
}

-links {
  loc.columns(yyleng);
  return FQParser::make_LINKS(loc);
}

-lname {
  loc.columns(yyleng);
  return FQParser::make_LNAME(loc);
}

-ls {
  loc.columns(yyleng);
  return FQParser::make_LS(loc);
}

-maxdepth {
  loc.columns(yyleng);
  return FQParser::make_MAXDEPTH(loc);
}

-mindepth {
  loc.columns(yyleng);
  return FQParser::make_MINDEPTH(loc);
}

-mmin {
  loc.columns(yyleng);
  return FQParser::make_MMIN(loc);
}

-mtime {
  loc.columns(yyleng);
  return FQParser::make_MTIME(loc);
}

-name {
  loc.columns(yyleng);
  return FQParser::make_NAME(loc);
}

-newer {
  loc.columns(yyleng);
  return FQParser::make_NEWER(loc);
}

-newerXY {
  loc.columns(yyleng);
  return FQParser::make_NEWERXY(loc);
}

-nogroup {
  loc.columns(yyleng);
  return FQParser::make_NOGROUP(loc);
}

-not|! {
  loc.columns(yyleng);
  return FQParser::make_NOT(loc);
}

-nouser {
  loc.columns(yyleng);
  return FQParser::make_NOUSER(loc);
}

-ok {
  loc.columns(yyleng);
  return FQParser::make_OK(loc);
}

-okdir {
  loc.columns(yyleng);
  return FQParser::make_OKDIR(loc);
}

-or|-o {
  loc.columns(yyleng);
  return FQParser::make_OR(loc);
}

-perm {
  loc.columns(yyleng);
  return FQParser::make_PERM(loc);
}

-prune {
  loc.columns(yyleng);
  return FQParser::make_PRUNE(loc);
}

-path {
  loc.columns(yyleng);
  return FQParser::make_PATH(loc);
}

-print {
  loc.columns(yyleng);
  return FQParser::make_PRINT(loc);
}

-print0 {
  loc.columns(yyleng);
  return FQParser::make_PRINT0(loc);
}

-printf {
  loc.columns(yyleng);
  return FQParser::make_PRINTF(loc);
}

-prune {
  loc.columns(yyleng);
  return FQParser::make_PRUNE(loc);
}

-quit {
  loc.columns(yyleng);
  return FQParser::make_QUIT(loc);
}

-readable {
  loc.columns(yyleng);
  return FQParser::make_READABLE(loc);
}

-regex {
  loc.columns(yyleng);
  return FQParser::make_REGEX(loc);
}

-samefile {
  loc.columns(yyleng);
  return FQParser::make_SAMEFILE(loc);
}

-size {
  loc.columns(yyleng);
  return FQParser::make_SIZE(loc);
}

-true {
  loc.columns(yyleng);
  return FQParser::make_TRUE(loc);
}

-type {
  loc.columns(yyleng);
  return FQParser::make_TYPE(loc);
}

-uid {
  loc.columns(yyleng);
  return FQParser::make_UID(loc);
}

-used {
  loc.columns(yyleng);
  return FQParser::make_USED(loc);
}

-user {
  loc.columns(yyleng);
  return FQParser::make_USER(loc);
}

-wholename {
  loc.columns(yyleng);
  return FQParser::make_WHOLENAME(loc);
}

-writable {
  loc.columns(yyleng);
  return FQParser::make_WRITABLE(loc);
}

-xtype {
  loc.columns(yyleng);
  return FQParser::make_XTYPE(loc);
}

"," {
  loc.columns(yyleng);
  return FQParser::make_COMMA(loc);
}

"(" {
  loc.columns(yyleng);
  return FQParser::make_LEFT_PAREN(loc);
}

")" {
  loc.columns(yyleng);
  return FQParser::make_RIGHT_PAREN(loc);
}

 /* match newlines separately to correctly update line numbers */
\n {
  loc.lines();
}

 /* whitespace except newline, same as [ \t\v\f\r] but easier to understand */
([[:space:]]{-}[\n])+ {
  loc.columns(yyleng);
}

}

<STRING_ARG_WHITESPACE>{
  [[:space:]]+ {
    yy_pop_state();
    loc.columns(yyleng);
    yy_push_state(STRING_ARG);
  }
}

<STRING_ARG>{
  [^"'][^[:space:]]* {
    loc.columns(yyleng);
    return FQParser::make_STRING_ARG(yytext, loc);
  }

 /* assumes multiline string literals are not allowed */
  (?x: ["] ( ( [^"\n] | \\["] | \\\\ )* ["] ) | ( ['] ( [^'\n] | \\['] | \\\\ )* ['] ) ) {
    yy_pop_state();
    loc.columns(yyleng);
    return FQParser::make_STRING_ARG(string(yytext + 1, yyleng - 2), loc);
  }
}

<NUMBER_ARG_WHITESPACE>{
  [[:space:]]+ {
    yy_pop_state();
    loc.columns(yyleng);
    yy_push_state(NUMBER_ARG);
  }
}

<NUMBER_ARG>{
  [-+]?[0-9]+ {
    loc.columns(yyleng);
    const char firstChar = yytext[0];
    char* digitStart = yytext;
    int sign = 0;

    if(firstChar == '+') {
      sign = 1;
      ++digitStart;
    } else if(firstChar == '-') {
      sign = -1;
      ++digitStart;
    }
    return FQParser::make_NUMBER_ARG({.val = (uint64_t)atoll(digitStart), .sign = sign}, loc);
  }
}

 /* lexer moves from EXEC_ARGS_WHITESPACE to EXEC_ARGS_WHITESPACE state and back until parser tells it to pop EXEC_ARGS_WHITESPACE state */
<EXEC_ARGS_WHITESPACE>{
  [[:space:]]+ {
    loc.columns(yyleng);
    yy_push_state(EXEC_ARGS);
  }
}

<EXEC_ARGS>{

  [^";][^[:space:]]* {
    yy_pop_state();
    loc.columns(yyleng);
    return FQParser::make_STRING_ARG(yytext, loc);
  }

 /* assumes multiline string literals are not allowed */
  (?x: ["] ( [^"\n] | \\["] | \\\\ )* ["] ) {
    yy_pop_state();
    loc.columns(yyleng);
    return FQParser::make_STRING_ARG(string(yytext + 1, yyleng - 2), loc);
  }

  ";" {
    yy_pop_state();
    loc.columns(yyleng);
    return FQParser::make_SEMICOLON(loc);
  }

}

<*>.|\n {
  errChar = *yytext;
  if(errChar == '\n') {
    loc.lines();
  } else {
    loc.columns(yyleng);
  }
  errState = YY_START;
  BEGIN(SKIP_TO_EOL);
}

<SKIP_TO_EOL>{
  .+ {
    BEGIN(0);
    loc.columns(yyleng);
    throw FQParser::syntax_error(loc, "bad input \""s + errChar + yytext + "\""s + " flex state " + to_string(errState));
  }
}

%%

#include "lexer/fqparser_lexer_methods.h"
