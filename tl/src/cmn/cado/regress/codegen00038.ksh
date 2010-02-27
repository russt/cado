#!/bin/sh
#codegen00038 - comment

TESTNAME=codegen00038
echo TESTNAME is $TESTNAME
. ./regress_defs.ksh

codegen -u -cgroot $REGRESS_CG_ROOT -DTESTNAME=$TESTNAME $TESTNAME.cg
