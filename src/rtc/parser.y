%language "c++"
%require "3.2"
%define api.token.constructor
%define api.value.type variant

%code requires {
    namespace yy
    {
        class Lexer;
    }
}

%code top {
    #include "lexer.h"

    static yy::parser::symbol_type yylex(yy::Lexer &lexer)
    {
        return lexer.get_next_token();
    }
}

%lex-param { yy::Lexer &lexer }
%parse-param { yy::Lexer &lexer }
%parse-param { const std::string &path }

%{
#include <iostream>
#include <string>
#include <map>
#include "TestFinder.h"

int last_id_line;
int beginL;

void yy::parser::error(const std::string &message)
{
    std::cerr << "Error: " << message << std::endl;
}

%}

%token END 0
%token CLASS
%token INCLUDE_QT_TEST
%token PREPROCESSOR
%token MODIFIER
%token PRIVATE
%token Q_SLOTS
%token OVZAGRADA
%token ZVZAGRADA
%token DVOTACKA
%token DVEDVOTACKE
%token ZAPETA
%token TACKAZAPETA
%token VOID
%token<std::string> ID

%type<std::string> Id

%%
Program
  : NizNaredbi
  ;

NizNaredbi
  : NizNaredbi Naredba
  |
  ;

Naredba
  : Pretprocesor
  | DefinicijaTipa
  | Blok
  | Skip
  | Test
  ;

Pretprocesor
  : INCLUDE_QT_TEST
  | PREPROCESSOR
  ;

Blok
  : OVZAGRADA NizNaredbi ZVZAGRADA
  ;

Skip
  : Id
  | TACKAZAPETA
  | ZAPETA
  ;

DefinicijaTipa
  : CLASS ID OVZAGRADA NizDeklaracijaUTipu ZVZAGRADA TACKAZAPETA
  | CLASS ID DVOTACKA NizNasledjivaja OVZAGRADA NizDeklaracijaUTipu ZVZAGRADA TACKAZAPETA
  ;

NizDeklaracijaUTipu
  : NizNaredbi
  | NizDeklaracijaUTipu MODIFIER NizID DVOTACKA NizNaredbi
  | NizDeklaracijaUTipu PRIVATE NizID DVOTACKA NizNaredbi
  | NizDeklaracijaUTipu PRIVATE Q_SLOTS DVOTACKA NizNaredbi
  ;

NizNasledjivaja
  : NizNasledjivaja ZAPETA MODIFIER Id
  | NizNasledjivaja ZAPETA PRIVATE Id
  | MODIFIER Id
  | PRIVATE Id
  ;

Id
  : Id DVEDVOTACKE ID { last_id_line = lexer.line_num; $$ = $3; }
  | ID { last_id_line = lexer.line_num; $$ = $1; }
  ;

NizID
  : NizID Id
  |
  ;

NizArgumenata
  : NizArgumenata ZAPETA Id
  | NizArgumenata Id
  |
  ;

Test
  : VOID Id NizArgumenata TACKAZAPETA { TestFinder::testFunctionNames[$2] = lexer.line_num; }
  | VOID Id NizArgumenata
            { if (TestFinder::testFunctionNames.find($2) == TestFinder::testFunctionNames.cend())
                TestFinder::testFunctionNames[$2] = lexer.line_num;
              beginL = last_id_line;
            } Blok { TestFinder::testovi.push_back(TestCase($2, path, TestFinder::testFunctionNames[$2], beginL, lexer.line_num)); }
  ;

%%
