#!/usr/bin/env -S awk -M -f

################################################################################
# MIT License
#
# Copyright (c) 2024 Zartaj Majeed
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################

# usage:
# findtojson.awk -F $field_separator -v rs=$record_separator -v debug=$debug -v rootslist="$rootslist"

# nested format is directory tree in top-level roots array of entries that are files and directories
# each directory entry has its own entries array
# flat format has top-level paths array of one record per file or directory path with no recursive entries array

# for ord function to convert control characters to their ascii codes
@load "ordchr"

function printFile(rec,    n, i, prop, val) {
  printf "{\n"
  n = length(props)
  for(i = 1; i <= n; ++i) {
    prop = props[i]
    val = rec[prop]
    printf "\"%s\": %s", prop, val
    if(i < n) {
      printf ","
    }
    printf "\n"
  }
  printf "}"
}

function printDir(rec, empty,    n, i, prop, val) {
  printf "{\n"
  n = length(props)
  for(i = 1; i <= n; ++i) {
    prop = props[i]
    val = rec[prop]
    printf "\"%s\": %s,\n", prop, val
  }
  printf "\"entries\": ["
  if(empty) {
    printf "]\n}"
  }
}

# escape special characters for json string
function jsonStringEscape(s,       s1, fields, seps, n, i) {
  s1 = gensub(/["\\]/, "\\\\&", "g", s)

# n is number of fields split by regex
  n = split(s1, fields, /[[:cntrl:]]/, seps)
# return what we have so far because there are no control characters
  if(n < 2) {
    return s1
  }
# replace control characters with hex escapes like \\x09 for tab
  s2 = ""
  for(i = 1; i < n; ++i) {
    s2 = s2 fields[i]
# need double-backslash for json
    s2 = s2 sprintf("\\\\x%.2x", ord(seps[i]))
  }
  s2 = s2 fields[n]

  return s2
}

BEGIN {
  if(format !~ /^nested|flat$/) {
    printf "error: unknown format \"%s\"\n", format >"/dev/stderr"
    exit 1
  }
  if(typeof(debug) == "undefined") {
    debug = 0
  }
}

BEGIN {
  RS = rs
  firstFindRecordNum = 3
  lastdepth = -1 
  printf "{\n"
}

# first record is list of root paths
NR == 1 {
  if(NF == 0) {
    delete roots
  }
  for(i = 1; i <= NF; ++i) {
    roots[i] = $i
  }
  next
}

# second record is header, convert to json
NR == 2 {
  printf "\"header\": {\n"
  for(i = 1; i <= NF; ++i) {
    colon = index($i, ":")
    prop = substr($i, 1, colon - 1)
    val = substr($i, colon + 1) 

    printf "\"%s\": %s,\n", prop, val
  }

# add array of roots to header
  printf "\"%s\": [", "roots"
  for(i = 1; i < length(roots); ++i) {
    printf "\"%s\", ", roots[i]
  }
  printf "\"%s\"]\n", roots[i]
  printf "},\n"

# open top-level array of roots for nested records or paths for flat records
  if(format == "nested") {
    printf "\"roots\": [\n"
  } else if(format == "flat") {
    printf "\"paths\": ["
  }

  next
}

# find file info records start with record 3

# save record as prevRec
format == "nested" && NR >= firstFindRecordNum {
  delete prevRec
  for(prop in rec) {
    prevRec[prop] = rec[prop]
  }
  prevType = type
  prevDepth = depth
}

# fill data structures from find record
{
  delete rec

# add index property for troubleshooting and to compare different output formats
  props[1] = "index"
  rec["index"] = NR - firstFindRecordNum + 1

  for(i = 1; i <= NF; ++i) {
    colon = index($i, ":")
    prop = substr($i, 1, colon - 1)
# maintain order of properties for output
    props[i + 1] = prop

    val = substr($i, colon + 1) 
    if(prop ~ /^name|path$/) {
      val = "\"" jsonStringEscape(substr(val, 2, length(val) - 2)) "\""
    }
    rec[prop] = val
  }
}

# emit json for flat output format
format == "flat" {
# print trailing comma for preceding record from second record on
  printf "%s\n{\n", (NR > firstFindRecordNum? ",": "")
  n = length(props)
  for(i = 1; i <= n; ++i) {
    prop = props[i]
    val = rec[prop]
    printf "\"%s\": %s", prop, val
    if(i < n) {
      printf ","
    }
    printf "\n"
  }
  printf "}"
  next
}

# rest is all nested format

{
# convenience variables for later
  type = substr(rec["type"], 2, 1)
  depth = int(rec["depth"])
}

# start printing previous record from record 3 on
NR == firstFindRecordNum {
  next
}

# main logic for nested format
{
  if(debug) printf "rule_999: NR %d name %s depth %d, print previous entry at depth %d rec %d name %s\n", NR, rec["name"], depth, prevDepth, prevRec["index"], prevRec["name"]

# this should never happen for default order of find traversal of directory trees
  if(prevDepth < depth && prevType != "d") {
    printf "error: unexpected sequence of records, file %s at depth %d followed by record type %s path %s at depth %d, depth can only increase after a directory\n", prevRec["path"], prevDepth, type, depth, rec["path"]
    exit 1
  }

  if(prevType != "d") {
# print previous file record
    printFile(prevRec)
  } else {
# print previous directory record, directory is not empty going down, directory must be empty going up
    emptyDir = prevDepth >= depth
    printDir(prevRec, emptyDir)
  }

# close each level in between previous record at lower level
  for(i = 0; i < prevDepth - depth; ++i) {
    printf "\n]\n}\n"
  }

  # print trailing comma because current record will be printed in next iteration
  if(prevDepth >= depth) {
    printf ","
  }

  printf "\n"

  next
}

# all records already printed for flat format
# last record remains to be printed for nested format
ENDFILE {
# print last record for nested format and close all levels back up to level 0
  if(format == "nested") {
    if(type != "d") {
      printFile(rec)
    } else {
      printDir(rec, 1)
    }
# close each level coming back up to level 0
    for(i = 0; i < depth; ++i) {
      printf "\n]\n}"
    }
  }

# close roots array and document object for flat and nested formats
  printf "\n]\n}\n"
}

