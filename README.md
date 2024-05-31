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

## The `find` expression language

The `find` expression language is described in detail in Section 2.1 of the GNU Findutils manual https://www.gnu.org/software/findutils/manual/html_mono/find.html. It's also in the Posix spec is at https://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html.

A `find` expression is composed of primaries like `-name`, `-type` and `-exec`. There are four kinds of primaries. Tests like `-name` and `type` that are true or false based on a property of the file. Actions like `-exec` and `-print` that perform an action that has side effects. Operators like `-and` and `-or` that affect the evaluation of other primaries. And options like `-depth` and `regextype` that affect the processing of all files rather than a single file.

Nearly all primaries start with dash `-`. This makes them look like commandline options. But primaries are not options but arguments to the `find` command that together make up a predicate expression.  Some operators do not have a dash prefix. These are the negation operator `!` though it's an alias for `-not`, the grouping operators `(` and `)`, and the comma operator `,`. Also the `-and` operator is implied if there isn't any other operator between two primaries.

The `findql` grammar below is for the language described in the GNU Findutils manual. It uses terminology from the manual.


```
find_command: "find" binary_expression | "find" starting_points binary_expression

starting_points: STARTING_POINT | starting_points STARTING_POINT

binary_expression: and_expression | or_expression | comma_expression

and_expression: unary_expression | and_expression and_operator unary_expression

and_operator: %empty | "-and"

or_expression: binary_expression "-or" and_expression

comma_expression: binary_expression "," and_expression

unary_expression: primary | "-not" primary | group

group: "(" binary_expression ")"

primary: test | action | global_option | positional_option

test:
  "-amin"                      number_arg
| "-anewer"                    string_arg
| "-atime"                     number_arg
| "-cmin"                      number_arg
| "-cnewer"                    string_arg
| "-ctime"                     number_arg
| "-empty"
| "-executable"
| "-false"
| "-fstype"                    string_arg
| "-gid"                       number_arg
| "-group"                     string_arg
| "-ilname"                    string_arg
| "-iname"                     string_arg
| "-inum"                      number_arg
| "-ipath"                     string_arg
| "-iregex"                    string_arg
| "-iwholename"                string_arg
| "-links"                     number_arg
| "-lname"                     string_arg
| "-mmin"                      number_arg
| "-mtime"                     number_arg
| "-name"                      string_arg
| "-newer"                     string_arg
| "-newerXY"                   string_arg
| "-nogroup"
| "-nouser"
| "-path"                      string_arg
| "-perm"                      string_arg
| "-readable"
| "-regex"                     string_arg
| "-samefile"
| "-size"                      number_arg
| "-true"
| "-type"                      string_arg
| "-uid"                       number_arg
| "-used"                      number_arg
| "-user"                      string_arg
| "-wholename"                 string_arg
| "-writable"
| "-xtype"                     string_arg

action:
  "-delete"
| "-exec"                      exec_args
| "-execdir"                   exec_args
| "-fls"                       string_arg
| "-fprint"                    string_arg
| "-fprint0"                   string_arg
| "-fprintf"                   string_arg
| "-ls"
| "-ok"                        exec_args
| "-okdir"                     exec_args
| "-print"
| "-print0"
| "-printf"                    string_arg
| "-prune"
| "-quit"

global_option:
  "-depth"
| "-files0-from"               string_arg
| "-help"
| "-ignore_readdir_race"
| "-maxdepth"                  number_arg
| "-mindepth"                  number_arg
| "-mount"
| "-noignore_readdir_race"
| "-noleaf"
| "-xdev"

positional_option:
  "-daystart"
| "-follow"
| "-nowarn"
| "-regextype"                 string_arg
| "-warn"

string_arg: "string"

number_arg: "number"

exec_args: strings ";"

strings: "string" | strings "string"

```
