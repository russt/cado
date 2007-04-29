#!/bin/sh
#codegen00016 - comment

TESTNAME=codegen00016
echo TESTNAME is $TESTNAME
. ./regress_defs.ksh

codegen -u -cgroot $REGRESS_CG_ROOT -DTESTNAME=$TESTNAME $TESTNAME.cg
