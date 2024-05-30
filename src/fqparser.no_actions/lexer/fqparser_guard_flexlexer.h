#ifndef FQPARSER_GUARD_FLEXLEXER_H
#define FQPARSER_GUARD_FLEXLEXER_H
// fqparser_guard_flexlexer.h

// make sure redefinition happens just once using FlexLexer.h macro that guards yyFlexLexer class definition
#ifndef yyFlexLexerOnce
#  undef yyFlexLexer
#  define yyFlexLexer FQParserFlexLexer
#  include "FlexLexer.h"
#endif

#endif

