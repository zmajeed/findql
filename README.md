# findql
A grammar and parser for the predicate expression language used by GNU find

## A grammar for `find`

The Unix and Linux `find` command has a small but powerful language for predicate expressions on files and directories.

The `find` DSL is used to match filesystem objects by forming boolean expressions over their properties. These predicates support pattern matching on filepaths and comparisons on numerical and temporal properties.

Predicates can be grouped and nested arbitrarily.

This `findql` repo has a Bison grammar and LALR(1) parser for the `find` language.

## A parser for `find`

The C++ parser is generated from the Bison rules file in `src/parser.no_actions`. There are unit tests for the Bison parser and Flex lexer that test the grammar without semantic data structures.

## A tool for using filesystem data for testing

The `findtojson.sh` tool in `src/tools` converts file stats data obtained from `find` to JSON. Two output formats are supported. A flat format emits JSON records at a single level. A nested format creates the filesystem trees visited by `find` as nested JSON objects.

The idea is to run the tool once on real filesystems. Then use the JSON data for testing without a filesystem.

## Build And test

Build with cmake then make

```
cmake -B build -S .
make -C build
```

Run unit tests with ctest

```
ctest --test-dir build
```

