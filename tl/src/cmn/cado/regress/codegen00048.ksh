#!/bin/sh
#codegen00048 - comment

TESTNAME=codegen00048
echo TESTNAME is $TESTNAME
. ./regress_defs.ksh

codegen -u -cgroot $REGRESS_CG_ROOT -DTESTNAME=$TESTNAME $TESTNAME.cg
