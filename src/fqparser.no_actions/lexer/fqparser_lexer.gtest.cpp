//fqparser_lexer.gtest.cpp

#include "fqparser_lexer.h"

#include <unistd.h>
#include <getopt.h>

#include <sstream>
#include <string>

#include <gtest/gtest.h>
#include <gmock/gmock.h>

#include "fqparser.bison.h"

using namespace std;
using namespace ::testing;

namespace fqparser::testing {

using symbol_kind = FQParser::symbol_kind;
using token = FQParser::token;

TEST(Lexer, test_0) {
  stringstream s("-kind");
  Lexer lexer(s);

  location loc{};

  auto token = lexer.yylex(loc);

  EXPECT_EQ(token.kind(), FQParser::symbol_kind::S_EMPTY);
}

}

