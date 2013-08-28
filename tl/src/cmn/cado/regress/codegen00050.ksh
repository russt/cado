#!/bin/sh
#codegen00050 - comment

TESTNAME=codegen00050
echo TESTNAME is $TESTNAME
. ./regress_defs.ksh

#test code goes here:
codegen -u -cgroot $REGRESS_CG_ROOT -DTESTNAME=$TESTNAME $TESTNAME.cg

#VERSION:  $Rev$ $Date$
