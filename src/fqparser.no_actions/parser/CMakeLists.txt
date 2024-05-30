# findql/parser/CMakeLists.txt

project(fqparser_parser)

# standalone parser executable with -DBUILD_BISON_MAIN
add_executable(fqparser ${FQPARSER_NO_ACTIONS_BISON_CPP_FILE})
target_compile_definitions(fqparser PRIVATE BUILD_BISON_MAIN)
target_link_libraries(fqparser ${FQPARSER_NO_ACTIONS_FLEXBISONLIB} fmt)

if(CYGWIN)
  target_compile_definitions(fqparser PRIVATE GTEST_HAS_PTHREAD=1 _POSIX_C_SOURCE=200809L)
endif()
if(CMAKE_CXX_COMPILER_ID MATCHES GNU)
  target_compile_options(fqparser PRIVATE -Wall -Werror -Wextra -O0 -ggdb -std=c++23 -pthread)
elseif(CMAKE_CXX_COMPILER_ID MATCHES MSVC)
# ranges library cannot take -Wall -WX
  target_compile_options(fqparser PRIVATE -Od)
elseif(CMAKE_CXX_COMPILER_ID MATCHES Clang)
  target_compile_definitions(fqparser PRIVATE _SILENCE_CLANG_CONCEPTS_MESSAGE)
endif()

# tests

set(TESTNAME fqparser.gtest)

add_executable(${TESTNAME} fqparser.gtest.cpp)

if(CYGWIN)
  target_compile_definitions(${TESTNAME} PRIVATE GTEST_HAS_PTHREAD=1 _POSIX_C_SOURCE=200809L)
endif()
if(CMAKE_CXX_COMPILER_ID MATCHES GNU)
  target_compile_options(${TESTNAME} PRIVATE -Wall -Werror -Wextra -O0 -ggdb -std=c++23 -pthread)
elseif(CMAKE_CXX_COMPILER_ID MATCHES MSVC)
# ranges library cannot take -Wall -WX
  target_compile_options(${TESTNAME} PRIVATE -Od)
elseif(CMAKE_CXX_COMPILER_ID MATCHES Clang)
  target_compile_definitions(${TESTNAME} PRIVATE _SILENCE_CLANG_CONCEPTS_MESSAGE)
endif()

target_link_libraries(${TESTNAME} ${FQPARSER_NO_ACTIONS_FLEXBISONLIB} gmock_main fmt)

enable_testing()
include(GoogleTest)
gtest_discover_tests(${TESTNAME} EXTRA_ARGS --gtest_color=yes)

