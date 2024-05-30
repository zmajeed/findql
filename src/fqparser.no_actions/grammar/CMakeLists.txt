# findql/grammar/CMakeLists.txt

project(fqparser_grammar)

find_package(FLEX)
find_package(BISON)

# generated source filename should match .l filename
flex_target(flex_files fqparser.flex.l ${CMAKE_CURRENT_BINARY_DIR}/fqparser.flex.cpp COMPILE_FLAGS -f)

# generated source filename should match .y filename
bison_target(bison_files fqparser.bison.y ${CMAKE_CURRENT_BINARY_DIR}/fqparser.bison.cpp COMPILE_FLAGS "-Wall -Wdangling-alias -Werror --report lookaheads --report-file bisonreport.txt")

add_flex_bison_dependency(flex_files bison_files)

set(FQPARSER_NO_ACTIONS_BISON_CPP_FILE ${BISON_bison_files_OUTPUT_SOURCE} CACHE STRING "" FORCE)
set(FQPARSER_NO_ACTIONS_FLEX_CPP_FILE ${FLEX_flex_files_OUTPUTS} CACHE STRING "" FORCE)

set(FQPARSER_NO_ACTIONS_FLEXBISONLIB flexbisonlib.fqparser_no_actions CACHE STRING "" FORCE)

add_library(${FQPARSER_NO_ACTIONS_FLEXBISONLIB} STATIC ${FLEX_flex_files_OUTPUTS} ${BISON_bison_files_OUTPUT_SOURCE})
target_compile_definitions(${FQPARSER_NO_ACTIONS_FLEXBISONLIB} PRIVATE _POSIX_C_SOURCE=200809L)
target_compile_options(${FQPARSER_NO_ACTIONS_FLEXBISONLIB} PRIVATE -Wall -Werror -Wextra -O0 -ggdb -std=c++23 -pthread)
target_include_directories(${FQPARSER_NO_ACTIONS_FLEXBISONLIB} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/.. ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(${FQPARSER_NO_ACTIONS_FLEXBISONLIB} fmt)

