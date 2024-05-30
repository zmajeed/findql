#!/bin/bash

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

# findtojson.sh

scriptSrcDir=$(dirname ${BASH_SOURCE[0]})

function usage {
  echo "Usage: findtojson.sh [-f format] [-z timezone] [-h] [-d] [path ...]"
  echo "prints file info as json in flat or nested format for entries returned by find for path arguments"
  echo
  echo "-f format: format is flat or nested, flat prints an array of file info objects, nested prints an array of nested file info objects, default is flat"
  echo "-z timezone: timezone used for time fields in output, default America/Chicago"
  echo "-h: help"
  echo "path ...: starting points for find command"
  echo
  echo "Examples:"
  echo "findtojson.sh -f nested /tmp"
}

while getopts "df:hz:" opt; do
  case $opt in
    d) debug=true;;
    f) format=$OPTARG;;
    h) usage; exit 0;;
    z) timezone=$OPTARG;;

    *) usage; exit 1
  esac
done
shift $((OPTIND-1))

roots=$*

: ${format:=flat}
: ${debug:=false}
: ${timezone:=America/Chicago}

export TZ=$timezone

# true and false are bash builtins not integers
$debug && debugAwk=1 || debugAwk=0

gentime=$(date +%F_%T.%9N)

# nul escape field separator
FS='\0'
# double-nul escape record terminator
RS='\0\0'

# fields are separated by FS, record ends with RS
# each field is colon-separated property and value
{
# generate header record
  echo -en "\
msg:\"Generated by findtojson.sh $*\"\
${FS}time:\"$gentime\"\
${FS}timezone:\"$timezone\"\
${FS}pwd:\"$PWD\"\
${FS}format:\"$format\"\
${FS}debug:$debugAwk\
${RS}"

# generate find records
  
# provide nul-terminated path arguments to find on stdin to allow paths with spaces and other special characters
  for ((i = 1; i <=$#; ++i)); do
    echo -en "${@:$i:1}\x00"
  done |
  find -files0-from - -printf "\
depth:%d\
${FS}name:\"%f\"\
${FS}atime:\"%AF_%AT\"\
${FS}atimeplus:\"%A+\"\
${FS}ctime:\"%BF_%BT\"\
${FS}fstype:\"%F\"\
${FS}gid:%G\
${FS}group:\"%g\"\
${FS}inum:%i\
${FS}links:%n\
${FS}mode:\"%#m\"\
${FS}mtime:\"%TF_%TT\"\
${FS}path:\"%p\"\
${FS}perm:\"%M\"\
${FS}size:%s\
${FS}stime:\"%CF_%CT\"\
${FS}type:\"%y\"\
${FS}uid:%U\
${FS}user:\"%u\"\
${RS}"
} |
# transform to json and print with awk
{

  {
# pass list of roots as first record
    for ((i = 1; i <= $#; ++i)); do
      echo -en "${@:$i:1}${FS}"
    done
    if (($# == 0)); then
      echo -en "${FS}"
    fi
    echo -en "${FS}"
# pass header and find records
    cat
  } |
  $scriptSrcDir/findtojson.awk -F "$FS" -v rs="$RS" -v debug=$debugAwk -v format=$format

}