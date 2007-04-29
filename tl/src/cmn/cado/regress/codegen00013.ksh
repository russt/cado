#!/bin/sh
#codegen00013 - test the codegen interface to the shell

TESTNAME=codegen00013
echo TESTNAME is $TESTNAME
. ./regress_defs.ksh

#we need a private dir for some of these tests:
TSTTMPDIR="$REGRESS_CG_ROOT/${TESTNAME}.dir"
rm -rf "$TSTTMPDIR"
mkdir -p "$TSTTMPDIR"

#---------------------------------------------
tnum=1
TEST_RESULT=FAILED

codegen << 'EOF'
syntax error
EOF

test $? -ne 0 && TEST_RESULT=PASSED
echo $TESTNAME test $tnum $TEST_RESULT

#---------------------------------------------
tnum=`expr $tnum + 1`
TEST_RESULT=FAILED

codegen << 'EOF'
CG_EXIT_STATUS = 1
EOF

test $? -ne 0 && TEST_RESULT=PASSED
echo $TESTNAME test $tnum $TEST_RESULT

#---------------------------------------------
tnum=`expr $tnum + 1`
TEST_RESULT=FAILED

codegen << 'EOF'
CG_ROOT=/etc/bogus
null	/write_to_root.txt
EOF

test $? -ne 0 && TEST_RESULT=PASSED
echo $TESTNAME test $tnum $TEST_RESULT

#---------------------------------------------
tnum=`expr $tnum + 1`
TEST_RESULT=FAILED

codegen << 'EOF'
syntax	error
#user can override bad status:
CG_EXIT_STATUS = 0
EOF

test $? -eq 0 && TEST_RESULT=PASSED
echo $TESTNAME test $tnum $TEST_RESULT

#---------------------------------------------
tnum=`expr $tnum + 1`
TEST_RESULT=FAILED

#note - platforms return different values for bad command status.
#we set it to 256 so as to not cause the test to diff.  RT 6/19/06
codegen << 'EOF'
%shell bad_command
%if $CG_SHELL_STATUS CG_SHELL_STATUS=256
%echo CG_SHELL_STATUS=$CG_SHELL_STATUS
%if $CG_SHELL_STATUS  CG_EXIT_STATUS=1
EOF
status=$?

test $status -eq 1 && TEST_RESULT=PASSED
echo $TESTNAME test $tnum $TEST_RESULT status=$status

#---------------------------------------------
tnum=`expr $tnum + 1`
TEST_RESULT=FAILED

codegen << 'EOF'
date_cmd =
CG_SHELL_COMMAND_ARGS = -badarg
%echo date_cmd:date=$date_cmd:date
%if $CG_SHELL_STATUS CG_SHELL_STATUS=256
%echo CG_SHELL_STATUS=$CG_SHELL_STATUS
%if $CG_SHELL_STATUS  CG_EXIT_STATUS=1
EOF

test $? -eq 1 && TEST_RESULT=PASSED
echo $TESTNAME test $tnum $TEST_RESULT

#---------------------------------------------
#do a bad command followed by good to make sure SHELL_STATUS is cleared
tnum=`expr $tnum + 1`
TEST_RESULT=FAILED

codegen << 'EOF'
%shell bad_command
%if $CG_SHELL_STATUS CG_SHELL_STATUS=256
%echo CG_SHELL_STATUS=$CG_SHELL_STATUS
%shell echo good_command
%echo CG_SHELL_STATUS=$CG_SHELL_STATUS
%ifnot $CG_SHELL_STATUS  CG_EXIT_STATUS=27
EOF

test $? -eq 27 && TEST_RESULT=PASSED
echo $TESTNAME test $tnum $TEST_RESULT

#---------------------------------------------
#make sure that %eecho goes to STDERR
tnum=`expr $tnum + 1`
TEST_RESULT=FAILED

stdout=/tmp/$TESTNAME.out.$$
stderr=/tmp/$TESTNAME.err.$$
rm -f $stdout $stderr
codegen -u << 'EOF' 2> $stderr 1> $stdout
%eecho some output for stderr
EOF

echo STDERR=`cat $stderr`
echo STDOUT=`cat $stdout`

test -r $stderr -a -z "`cat $stdout`" && TEST_RESULT=PASSED
echo $TESTNAME test $tnum $TEST_RESULT
rm -f $stderr

#---------------------------------------------
#test %halt/%abort
tnum=0
tnum=`expr $tnum + 1`
tname=%halt/%abort

TEST_RESULT=FAILED
codegen << 'EOF'
%halt
EOF

test $? -eq 0 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test %halt/%abort
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
codegen << 'EOF'
%abort
EOF

test $? -eq 0 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test %halt/%abort
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
codegen << 'EOF'
%halt 27
EOF

test $? -eq 27 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test %halt/%abort
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
codegen << 'EOF'
%halt bad status string
EOF

test $? -eq 1 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test %halt/%abort
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
codegen << 'EOF'
exit_status = 33
%halt $exit_status
EOF

test $? -eq 33 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test CG_ARGV
tname=CG_ARGV
tnum=0
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
codegen - << 'EOF'
%ifndef CG_ARGV %halt 1
EOF

test $? -eq 1 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test CG_ARGV
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
codegen - arg1 arg2 arg3 << 'EOF'
%ifndef CG_ARGV %halt 1

show_arg := << !
%echo arg[$cnt:incr:assign]='$arg'
%shift arg CG_ARGV
!

cnt=0
%shift arg CG_ARGV
%whiledef arg %call show_arg
EOF

test $? -eq 0 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test -Dvar[=value]
tname=Dargs
tnum=0
tnum=`expr $tnum + 1`
echo

TEST_RESULT=FAILED
codegen -Dfoo1 -Dfoo2=foovalue2 -Dfoo3="a b c" << 'EOF'
CG_EXIT_STATUS=0

%ifndef foo1 CG_EXIT_STATUS=1
%ifndef foo2 CG_EXIT_STATUS=2

CG_COMPARE_SPEC=foovalue2
%if $CG_COMPARE_SPEC:ne CG_EXIT_STATUS=3

CG_COMPARE_SPEC=a b c
%if $CG_COMPARE_SPEC:ne CG_EXIT_STATUS=4

%echo foo1='$foo1' foo2='$foo2' foo3='$foo3'
EOF

test $? -eq 0 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test -Dvar[=value]
tname=Dargs
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
codegen -D << 'EOF'
EOF

test $? -ne 0 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test -Dvar[=value]
tname=Dargs
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
codegen -D=blah << 'EOF'
EOF

test $? -ne 0 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test -S with bad file
tname=findInputFileInPath
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
codegen -S no_such_file

test $? -ne 0 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test -S with <STDIN>
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
codegen -S << 'EOF'
%echo HELLO from <STDIN>
EOF

test $? -eq 0 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
#test -S with good file in path
tnum=`expr $tnum + 1`

#generate a good script in CG_ROOT:
codegen -u -cgroot $TSTTMPDIR << 'EOF'
ECHO_TXT= << eof
%echo HELLO - I'm a good file
eof
echo bin/good
EOF

save_path="$PATH"
export PATH
PATH="$TSTTMPDIR/bin${PS}$PATH"

TEST_RESULT=FAILED
codegen -S good

test $? -eq 0 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#restore path:
PATH="$save_path"

#---------------------------------------------
#test -S with good file not in path but referenced explicity
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
1>&2 echo codegen -S $TSTTMPDIR/bin/good
codegen -S $TSTTMPDIR/bin/good

test $? -eq 0 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#---------------------------------------------
tname=stripToSharpBang
#test -x with <STDIN>
tnum=`expr $tnum + 1`

TEST_RESULT=FAILED
codegen -x << 'EOF'
bogus
bogus 2
#!/bin/codegen
%echo HELLO from <STDIN> line $CG_LINE_NUMBER
EOF

test $? -eq 0 && TEST_RESULT=PASSED
echo $TESTNAME $tname test $tnum $TEST_RESULT

#clean-up
rm -f /tmp/$TESTNAME.*
