# findql/src/CMakeLists.txt

project(findql_src)

include(FetchContent)

set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest
  GIT_TAG main
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(googletest)

FetchContent_Declare(
  fmt
  GIT_REPOSITORY https://github.com/fmtlib/fmt
  GIT_TAG master
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(fmt)

add_subdirectory(fqparser.no_actions)

enable_testing()
