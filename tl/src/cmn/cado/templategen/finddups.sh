#!/bin/sh

#find duplicate elements in maven/maven_doc.defs

infile=maven/maven_doc.defs

grep ':=' $infile | sed -e 's/_doc.*//' | sort > all
sort -u all > uu
comm -23 all uu
