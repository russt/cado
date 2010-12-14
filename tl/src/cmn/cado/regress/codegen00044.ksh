#!/bin/sh
#codegen00044 - comment

TESTNAME=codegen00044
echo TESTNAME is $TESTNAME
. ./regress_defs.ksh

codegen -u -cgroot $REGRESS_CG_ROOT -DTESTNAME=$TESTNAME $TESTNAME.cg
