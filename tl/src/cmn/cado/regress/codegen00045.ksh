#!/bin/sh
#codegen00045 - comment

TESTNAME=codegen00045
echo TESTNAME is $TESTNAME
. ./regress_defs.ksh

codegen -u -cgroot $REGRESS_CG_ROOT -DTESTNAME=$TESTNAME $TESTNAME.cg
