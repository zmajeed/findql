// fqparser.gtest.cpp

#include <unistd.h>
#include <getopt.h>

#include <sstream>
#include <string>
#include <optional>

#include <fmt/format.h>

#include <gtest/gtest.h>
#include <gmock/gmock.h>

#include "lexer/fqparser_lexer.h"
#include "fqparser.bison.h"

using namespace std;
using namespace fmt;

using namespace ::testing;

namespace fqparser::testing {

using Token = FQParser::symbol_kind;

MATCHER_P(IsTokenKind, tokenKind, "") { return arg.kind() == tokenKind; }

// custom matcher macro
MATCHER_P(MatchTokenP, expectedToken, "custom token matcher macro") {
  if(arg.kind() != expectedToken.kind()) {
    return false;
  }
  switch(arg.kind()) {
  case Token::S_STARTING_POINT:
  case Token::S_STRING_ARG:
    return arg.value.template as<string>() == expectedToken.value.template as<string>();
  case Token::S_NUMBER_ARG:
    return arg.value.template as<NumberArg>() == expectedToken.value.template as<NumberArg>();
  default:
    return true;
  }
}

// custom matcher class
struct TokenMatcher {
  using is_gtest_matcher = void;

  FQParser::symbol_type expectedToken;

  TokenMatcher(const FQParser::symbol_type& expected): expectedToken(expected) {}

  bool MatchAndExplain(const FQParser::symbol_type& token, ostream*) const {
    if(token.kind() != expectedToken.kind()) {
      return false;
    }
    switch(token.kind()) {
    case Token::S_STARTING_POINT:
    case Token::S_STRING_ARG:
      return token.value.template as<string>() == expectedToken.value.as<string>();
    case Token::S_NUMBER_ARG:
      return token.value.template as<NumberArg>() == expectedToken.value.as<NumberArg>();
    default:
      return true;
    }
  }

  void DescribeTo(ostream* os) const {*os << "match success";}

  void DescribeNegationTo(ostream* os) const {*os << "match failure";}

};

TokenMatcher MatchToken(const FQParser::symbol_type& token) {
  return TokenMatcher(token);
}

TEST(FQParser, test_0) {
  stringstream s("find -true");
  Lexer lexer(s);

  location loc{};
  BisonParam bisonParam{lexer};

  FQParser parser([&lexer](location& loc) -> FQParser::symbol_type {
    return lexer.yylex(loc);
  },
  bisonParam,
  loc);

  EXPECT_EQ(parser(), 0);
}

TEST(FQParser, test_1) {
  stringstream s("find -false");
  Lexer lexer(s);

  location loc{};
  BisonParam bisonParam{lexer};

  FQParser parser([&lexer](location& loc) -> FQParser::symbol_type {
    return lexer.yylex(loc);
  },
  bisonParam,
  loc);

  EXPECT_EQ(parser(), 0);
}

TEST(FQParser, test_2) {
  stringstream s("find ( -name build ) -prune");
  Lexer lexer(s);

  location loc{};
  BisonParam bisonParam{lexer};

  FQParser parser([&lexer](location& loc) -> FQParser::symbol_type {
    return lexer.yylex(loc);
  },
  bisonParam,
  loc);

  EXPECT_EQ(parser(), 0);
}

TEST(FQParser, test_3) {
  stringstream s("find ( -name build -o -name node_modules ) -prune");
  Lexer lexer(s);

  location loc{};
  BisonParam bisonParam{lexer};

  FQParser parser([&lexer](location& loc) -> FQParser::symbol_type {
    return lexer.yylex(loc);
  },
  bisonParam,
  loc);

  EXPECT_EQ(parser(), 0);
}

TEST(FQParser, test_4) {
  stringstream s("find -true");
  Lexer lexer(s);

  location loc{};
  BisonParam bisonParam{lexer};

  NiceMock<MockFunction<FQParser::symbol_type(location&)>> mock_yylex;
  NiceMock<MockFunction<void(FQParser::symbol_kind_type)>> check_token;

  ON_CALL(mock_yylex, Call).WillByDefault([&lexer, &check_token](location& loc){
      auto token = lexer.yylex(loc);
      check_token.Call(token.kind());
      return token;
  });

  EXPECT_CALL(mock_yylex, Call(_)).Times(3);

  EXPECT_CALL(check_token, Call(Token::S_FIND));
  EXPECT_CALL(check_token, Call(Token::S_TRUE));
  EXPECT_CALL(check_token, Call(Token::S_YYEOF));

  FQParser parser(mock_yylex.AsStdFunction(), bisonParam, loc);

  EXPECT_EQ(parser(), 0);
}

TEST(FQParser, test_5) {
  stringstream s("find ( -name build -o -name node_modules ) -prune");
  Lexer lexer(s);

  location loc{};
  BisonParam bisonParam{lexer};

  NiceMock<MockFunction<FQParser::symbol_type(location&)>> mock_yylex;
  NiceMock<MockFunction<void(const FQParser::symbol_kind_type)>> checkTokenType;
  NiceMock<MockFunction<void(const string&)>> checkStringToken;

  ON_CALL(mock_yylex, Call).WillByDefault([&lexer, &checkTokenType, &checkStringToken](location& loc) {
      auto token = lexer.yylex(loc);
      checkTokenType.Call(token.kind());
      if(token.kind() == Token::S_STRING_ARG) {
        checkStringToken.Call(token.value.as<string>());
      }
      return token;
  });

  EXPECT_CALL(mock_yylex, Call(_)).Times(AnyNumber());

  EXPECT_CALL(checkTokenType, Call(Token::S_FIND));
  EXPECT_CALL(checkTokenType, Call(Token::S_LEFT_PAREN));
  EXPECT_CALL(checkTokenType, Call(Token::S_NAME)).Times(2);
  EXPECT_CALL(checkTokenType, Call(Token::S_STRING_ARG)).Times(2);
  EXPECT_CALL(checkTokenType, Call(Token::S_OR));
  EXPECT_CALL(checkTokenType, Call(Token::S_RIGHT_PAREN));
  EXPECT_CALL(checkTokenType, Call(Token::S_PRUNE));
  EXPECT_CALL(checkTokenType, Call(Token::S_YYEOF));

  EXPECT_CALL(checkStringToken, Call("build"));
  EXPECT_CALL(checkStringToken, Call("node_modules"));

  FQParser parser(mock_yylex.AsStdFunction(), bisonParam, loc);

  EXPECT_EQ(parser(), 0);
}

TEST(FQParser, test_6) {
  stringstream s("find -type d -mindepth 2 -maxdepth 4");
  Lexer lexer(s);

  location loc{};
  BisonParam bisonParam{lexer};

  NiceMock<MockFunction<FQParser::symbol_type(location&)>> mock_yylex;
  NiceMock<MockFunction<void(const FQParser::symbol_kind_type)>> checkTokenType;
  NiceMock<MockFunction<void(const string&)>> checkStringToken;
  NiceMock<MockFunction<void(const NumberArg&)>> checkNumberToken;

  ON_CALL(mock_yylex, Call).WillByDefault(
    [&lexer, &checkTokenType, &checkStringToken, &checkNumberToken](location& loc) {
      auto token = lexer.yylex(loc);
      checkTokenType.Call(token.kind());
      if(token.kind() == Token::S_STRING_ARG) {
        checkStringToken.Call(token.value.as<string>());
      } else if(token.kind() == Token::S_NUMBER_ARG) {
        checkNumberToken.Call(token.value.as<NumberArg>());
      }
      return token;
  });

  EXPECT_CALL(mock_yylex, Call(_)).Times(AtLeast(1));

  EXPECT_CALL(checkStringToken, Call("d"));
  EXPECT_CALL(checkNumberToken, Call(FieldsAre(2u, 0)));
  EXPECT_CALL(checkNumberToken, Call(FieldsAre(4u, 0)));

  FQParser parser(mock_yylex.AsStdFunction(), bisonParam, loc);

  EXPECT_EQ(parser(), 0);
}

TEST(FQParser, test_7) {
  stringstream s("find src tools -type d -mindepth 2 -maxdepth 4");
  Lexer lexer(s);

  location loc{};
  BisonParam bisonParam{lexer};

  NiceMock<MockFunction<FQParser::symbol_type(location&)>> mock_yylex;
  NiceMock<MockFunction<void(const FQParser::symbol_kind_type)>> checkTokenType;
  NiceMock<MockFunction<void(const string&)>> checkStringToken;
  NiceMock<MockFunction<void(const NumberArg&)>> checkNumberToken;

  ON_CALL(mock_yylex, Call).WillByDefault(
    [&lexer, &checkTokenType, &checkStringToken, &checkNumberToken](location& loc) {
      auto token = lexer.yylex(loc);
      checkTokenType.Call(token.kind());
      switch(token.kind()) {
      case Token::S_STRING_ARG:
      case Token::S_STARTING_POINT:
        checkStringToken.Call(token.value.as<string>());
        break;
      case Token::S_NUMBER_ARG:
        checkNumberToken.Call(token.value.as<NumberArg>());
        break;
      default:
        break;
      }
      return token;
  });

  EXPECT_CALL(mock_yylex, Call(_)).Times(AtLeast(1));

  EXPECT_CALL(checkTokenType, Call(_)).Times(AnyNumber());
  EXPECT_CALL(checkTokenType, Call(Token::S_STARTING_POINT)).Times(2);

  EXPECT_CALL(checkStringToken, Call("src"));
  EXPECT_CALL(checkStringToken, Call("tools"));
  EXPECT_CALL(checkStringToken, Call("d"));
  EXPECT_CALL(checkNumberToken, Call(FieldsAre(2u, 0)));
  EXPECT_CALL(checkNumberToken, Call(FieldsAre(4u, 0)));

  FQParser parser(mock_yylex.AsStdFunction(), bisonParam, loc);

  EXPECT_EQ(parser(), 0);
}

TEST(FQParser, test_8) {
  stringstream s("find src tools -type f -exec ls -l {} ;");
  Lexer lexer(s);

  location loc{};
  BisonParam bisonParam{lexer};

  NiceMock<MockFunction<FQParser::symbol_type(location&)>> mock_yylex;
  NiceMock<MockFunction<void(const FQParser::symbol_kind_type)>> checkTokenType;

  NiceMock<MockFunction<void(const FQParser::symbol_type&)>> checkTokenType1;

  NiceMock<MockFunction<void(const string&)>> checkStringToken;
  NiceMock<MockFunction<void(const NumberArg&)>> checkNumberToken;

  NiceMock<MockFunction<FQParser::symbol_type(const FQParser::symbol_type&)>> checkTokenType2;
  ON_CALL(checkTokenType2, Call).WillByDefault(ReturnArg<0>());

  ON_CALL(mock_yylex, Call).WillByDefault(
    [&lexer, &checkTokenType, &checkStringToken, &checkNumberToken, &checkTokenType1, &checkTokenType2](location& loc) -> FQParser::symbol_type {
      FQParser::symbol_type token(lexer.yylex(loc));
      checkTokenType.Call(token.kind());

      checkTokenType1.Call(token);

      switch(token.kind()) {
      case Token::S_STRING_ARG:
      case Token::S_STARTING_POINT:
        checkStringToken.Call(token.value.as<string>());
        break;
      case Token::S_NUMBER_ARG:
        checkNumberToken.Call(token.value.as<NumberArg>());
        break;
      default:
        break;
      }

      return checkTokenType2.Call(token);
  });

  EXPECT_CALL(mock_yylex, Call(_)).Times(AtLeast(1));

  EXPECT_CALL(checkTokenType, Call(_)).Times(AnyNumber());
  EXPECT_CALL(checkTokenType, Call(Token::S_STARTING_POINT)).Times(AtLeast(1));
  EXPECT_CALL(checkTokenType, Call(Token::S_EXEC));
  EXPECT_CALL(checkTokenType, Call(Token::S_SEMICOLON));

  EXPECT_CALL(checkTokenType1, Call(_)).Times(AnyNumber());
  EXPECT_CALL(checkTokenType1, Call(IsTokenKind(Token::S_EXEC)));
  EXPECT_CALL(checkTokenType1, Call(Truly([](const FQParser::symbol_type& token) {return token.kind() == Token::S_SEMICOLON;})));
  EXPECT_CALL(checkTokenType1, Call(MatchToken(FQParser::make_STARTING_POINT("src", loc))));
  EXPECT_CALL(checkTokenType1, Call(MatchToken(FQParser::make_STARTING_POINT("tools", loc))));

  EXPECT_CALL(checkTokenType2, Call(_)).Times(AnyNumber());
  EXPECT_CALL(checkTokenType2, Call(MatchToken(FQParser::make_STARTING_POINT("src", loc))));

  EXPECT_CALL(checkStringToken, Call(_)).Times(AnyNumber());
  EXPECT_CALL(checkStringToken, Call("src"));
  EXPECT_CALL(checkStringToken, Call("f"));
  EXPECT_CALL(checkStringToken, Call("ls"));
  EXPECT_CALL(checkStringToken, Call("-l"));
  EXPECT_CALL(checkStringToken, Call("{}"));

  FQParser parser(mock_yylex.AsStdFunction(), bisonParam, loc);

  EXPECT_EQ(parser(), 0);
}

TEST(FQParser, test_9) {
  stringstream s("find . -type f ! -path '*/node_modules/*'");
  Lexer lexer(s);

  location loc{};
  BisonParam bisonParam{lexer};

  NiceMock<MockFunction<FQParser::symbol_type(const FQParser::symbol_type&)>> mock_yylex_return;
  ON_CALL(mock_yylex_return, Call).WillByDefault(ReturnArg<0>());

  EXPECT_CALL(mock_yylex_return, Call(_)).Times(AnyNumber());
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_STARTING_POINT(".", loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_TYPE(loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_STRING_ARG("f", loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_NOT(loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_PATH(loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_STRING_ARG("*/node_modules/*", loc))));

  FQParser parser([&lexer, &mock_yylex_return](location& loc) -> FQParser::symbol_type {
    return mock_yylex_return.Call(lexer.yylex(loc));
  },
  bisonParam,
  loc);


  EXPECT_EQ(parser(), 0);
}

TEST(FQParser, test_10) {
  stringstream s("find . -type f ! -path '*/node_modules/*'");
  Lexer lexer(s);

  location loc{};
  BisonParam bisonParam{lexer};

  NiceMock<MockFunction<FQParser::symbol_type(const FQParser::symbol_type&)>> mock_yylex_return;
  ON_CALL(mock_yylex_return, Call).WillByDefault(ReturnArg<0>());

  EXPECT_CALL(mock_yylex_return, Call(_)).Times(AnyNumber());
  EXPECT_CALL(mock_yylex_return, Call(MatchTokenP(FQParser::make_STARTING_POINT(".", loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_TYPE(loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_STRING_ARG("f", loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_NOT(loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_PATH(loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_STRING_ARG("*/node_modules/*", loc))));

  FQParser parser([&lexer, &mock_yylex_return](location& loc) -> FQParser::symbol_type {
    return mock_yylex_return.Call(lexer.yylex(loc));
  },
  bisonParam,
  loc);


  EXPECT_EQ(parser(), 0);
}

TEST(FQParser, test_11) {
  stringstream s("find . -type f ! -path '*/node_modules/*'");
  Lexer lexer(s);

  NiceMock<MockFunction<FQParser::symbol_type(const FQParser::symbol_type&)>> mock_yylex_return;
  ON_CALL(mock_yylex_return, Call).WillByDefault(ReturnArg<0>());

  NiceMock<MockFunction<void()>> mock_binary_expression_from_and_cb;
  NiceMock<MockFunction<void()>> mock_and_expression_from_list_cb;
  NiceMock<MockFunction<void()>> mock_unary_expression_from_not_cb;
  NiceMock<MockFunction<void(const string&)>> mock_string_arg_cb;

  location loc{};
  BisonParam bisonParam{lexer,
    {
      mock_binary_expression_from_and_cb.AsStdFunction(),
      mock_and_expression_from_list_cb.AsStdFunction(),
      mock_unary_expression_from_not_cb.AsStdFunction(),
      mock_string_arg_cb.AsStdFunction(),
    }
  };

  EXPECT_CALL(mock_yylex_return, Call(_)).Times(AnyNumber());
  EXPECT_CALL(mock_yylex_return, Call(MatchTokenP(FQParser::make_STARTING_POINT(".", loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_TYPE(loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_STRING_ARG("f", loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_NOT(loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_PATH(loc))));
  EXPECT_CALL(mock_yylex_return, Call(MatchToken(FQParser::make_STRING_ARG("*/node_modules/*", loc))));

  EXPECT_CALL(mock_string_arg_cb, Call(_)).Times(AnyNumber());
  EXPECT_CALL(mock_string_arg_cb, Call("f"));
  EXPECT_CALL(mock_string_arg_cb, Call("*/node_modules/*"));

// both After() clause and InSequence codeblock work but test case expression has just one -and and one -not so cannot have more than one expectation for each
#if 1
  Expectation expect_and = EXPECT_CALL(mock_and_expression_from_list_cb, Call());
  Expectation expect_not = EXPECT_CALL(mock_unary_expression_from_not_cb, Call());

  EXPECT_CALL(mock_binary_expression_from_and_cb, Call())
    .After(expect_and, expect_not);
#else
  {
    InSequence s;
    EXPECT_CALL(mock_unary_expression_from_not_cb, Call());
    EXPECT_CALL(mock_and_expression_from_list_cb, Call());
    EXPECT_CALL(mock_binary_expression_from_and_cb, Call());
  }
#endif

  FQParser parser([&lexer, &mock_yylex_return](location& loc) -> FQParser::symbol_type {
    return mock_yylex_return.Call(lexer.yylex(loc));
  },
  bisonParam,
  loc);


  EXPECT_EQ(parser(), 0);
}


}

