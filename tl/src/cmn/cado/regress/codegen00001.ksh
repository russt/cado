#!/bin/sh
#codegen00001 - comment

TESTNAME=codegen00001
echo TESTNAME is $TESTNAME
. ./regress_defs.ksh

#clean up from previous run:
rm -rf "$REGRESS_CG_ROOT"

codegen -u -cgroot $REGRESS_CG_ROOT -DTESTNAME=$TESTNAME $TESTNAME.cg
