#!/bin/sh
#codegen00031 - comment

TESTNAME=codegen00031
echo TESTNAME is $TESTNAME
. ./regress_defs.ksh

#add some more flags to test init of pragma values:
codegen -u -v -q -e -cgroot $REGRESS_CG_ROOT -DTESTNAME=$TESTNAME $TESTNAME.cg
