#
# BEGIN_HEADER - DO NOT EDIT
#
# The contents of this file are subject to the terms
# of the Common Development and Distribution License
# (the "License").  You may not use this file except
# in compliance with the License.
#
# You can obtain a copy of the license at
# https://open-esb.dev.java.net/public/CDDLv1.0.html.
# See the License for the specific language governing
# permissions and limitations under the License.
#
# When distributing Covered Code, include this CDDL
# HEADER in each file and include the License file at
# https://open-esb.dev.java.net/public/CDDLv1.0.html.
# If applicable add the following below this CDDL HEADER,
# with the fields enclosed by brackets "[]" replaced with
# your own identifying information: Portions Copyright
# [year] [name of copyright owner]
#

#
# @(#)cado.pl - ver 1.87 - 11-Dec-2010
#
# Copyright 2003-2008 Sun Microsystems, Inc.  All Rights Reserved.
# Copyright 2009-2010 Russ Tremain.  All Rights Reserved.
#
# END_HEADER - DO NOT EDIT
#

#
# cado - create a tree full of source code
#
# Author: Russ Tremain
#
#  12-Nov-2003 (russt)
#       Initial revision
#  06-Jan-2004 (russt)
#       add TEMPLATE_PATHS - search path for templates
#  21-Jan-2004 (russt)
#       add here-now defs, {} comments, %echo macro
#  12-Mar-2004 (russt)
#       add ifn?def, echo statements
#  19-Mar-2004 (russt)
#       implement -u (update) option
#  29-Sep-2004 (russt)
#       add postfix operators
#  28-Oct-2004 (russt)
#       add append file-spec directive
#  30-Apr-2005 (russt)
#       add := operator, %evalmacro, %evaltemplate, %readtemplate
#  27-Jul-2005 (russt)
#       add %if, %ifnot
#  29-Jul-2005 (russt)
#       add CG_SHELL_STATUS, user defined CG_EXIT_STATUS, correct exit status
#  02-Aug-2005 (russt)
#       add -V -version args
#       add %interpret statement
#       add %echo -n
#       add :valueof op
#       add :nameof op
#       add :env op
#       allow assignment to contents of a variable ($var on lhs).
#       allow $var in %if?ndef, %undef expressions (now works like %if and %ifnot).
#       fix :indent<integer> macro to indent all lines.
#       if CGROOT undefined, set to "." on first use instead of creating "NULL" directory.
#  04-Aug-2005 (russt) [Version 1.41]
#       add %whiledef, %while statements.
#       add :xmlcomment, :xmlcommentblock operators.
#       changed semantics of %if, %ifnot:  false <==> zero or empty string, true <==> !false
#       change :incr, :decr, :plus, etc. to preserve width of input, e.g., 00, 01, etc.
#       variable names in %ifndef, etc, no longer incorporate leading/trailing white space.
#  11-Aug-2005 (russt) [Version 1.42]
#       add file i/o operators:
#           :openfile
#           :getnextline
#           :currentline
#           :currentlinenumber (1..nlines), 0 => file closed
#           :closefile
#       add match, compare operators:
#           :match or :m - will match against CG_MATCH_SPEC
#           :substitute or :s - will match against CG_SUBSTITUTE_SPEC
#           :eq, :ne, :gt, :lt, :ge, :le - will compare against CG_COMPARE_SPEC
#       add %push, %pop statements.
#       add %call alias for %interpret
#       %exit was requiring spaces after keyword
#       add %return alias for %exit
#       add %halt <status>, also aliased to %abort <status>
#       add %eecho (echo to stderr).
#       add tracing for allocate/free of file handles, and the limit 40 from 30
#       fix &is_number(..) (was requiring '.').
#       set result of perl =~ expressions to {0,1}, as they're undefined if false.
#       standardize most of the error/warning messages.  needs more work.
#  20-Aug-2005 (russt) [Version 1.43]
#       add %shift operator
#       allow patterns in %undef operator
#       no longer need to escape % in input (existing scripts using %% have to be updated).
#       ignore leading space in file spec statements
#       %exit/%return - ignore exit message if empty string.
#       add built-in CG_ARGV stack variable, which saves arguments to interpreter
#       add :basename :dirname :suffix operators
#       add :stripjavaheader operator
#  22-Aug-2005 (russt) [Version 1.44]
#       add -Dvar[=value] command line arg
#  29-Aug-2005 (russt) [Version 1.45]
#       :env now returns empty string if variable is undefined.
#       add %export/%unexport operators to modify environment of sub-shells
#       handle binary files specs.
#       fix bug where $foovar:nameof[:op]+ was not updating var contents with [:op]+.
#  17-Oct-2005 (russt) [Version 1.46]
#       double the number of available file-descriptors to 80, add -debugfd option.
#       fix bug in get_avaliable_filehandle() - was failing with descriptors available.
#  18-Oct-2005 (russt) [Version 1.47]
#       fix pathname creation in write_string_to_cg_tmp_file()
#           (cygwin thinks //tmp is a network drive).
#  20-Oct-2005 (russt) [Version 1.48]
#       we were not freeing file-descriptors in close_fileop().
#  05-Jun-2006 (russt) [Version 1.49]
#       CG_TEMPLATE_PATH: . was overriding path. added :freq postfix op.
#  15-Jun-2006 (russt) [Version 1.50]
#       added %pragma statement, preserve_multiline_lnewline pragma.
#  18-Jun-2006 (russt) [Version 1.51]
#       added copy pragma, :rangelb, :rangeub, :split operators.
#       move tests to regress subdir and adapt to jregress requirements.
#  18-Jun-2006 (russt) [Version 1.52]
#       restructure postfix eval to use function pointers.
#  20-Jun-2006 (russt) [Version 1.53]
#       add %foreach statement
#  21-Jun-2006 (russt) [Version 1.54]
#       match operator was generating spurious errors.
#  25-Jun-2006 (russt) [Version 1.55]
#       Add :pad operator.
#       Add warning if -u option not specified.
#       Add %print (%echo) & %printe (%eecho) aliases
#       Re-work numeric %foreach to pad iterator, improve efficiency.
#       Add pattern matching foreach variant.
#       Fix "cascading failure" bug in &interpret.
#       Rename %SPEC_VARS to %CG_USER_VARS, and add get_user_vars() function to access.
#       Add debug, ddebug, quiet, verbose %pragma statements.  
#       Change :valueof to return ${var:undef} instead of NULL for undefined variables.
#  04-Oct-2006 (russt) [Version 1.56]
#       Fix checkforexistingheader -> checkforexistingheader_op when called internally.
#  14-Dec-2006 (russt) [Version 1.57]
#       delete signsrc operators (not part of core interpreter).  add :fixeol op.
#  20-Dec-2006 (russt) [Version 1.58]
#       add -x -S options to allow "#!/bin/cado" scripts.
#       add :crc :crcstr :crcfile ops.  add CG_LINE_NUMBER user variable.
#       enhance -help message: add %pragma section, update user-variables, etc.
#  21-Dec-2006 (russt) [Version 1.59]
#       add :tounix :todos ops.
#       add :cap, :uncap ops to capitalize or uncapitalize a string (first letter only).
#       add file-test ops: :r,:w,:x,:e,:z,:sz,:f,:d,:l,:T,:B (same as perl, except :sz = -s).
#       fix bug in %undef - was matching all vars with indicated prefix.
#  22-Dec-2006 (russt) [Version 1.60]
#       :crcstr op was not cleaning tmp file. eliminated redundant string copy in %readtemplate.
#  22-Dec-2006 (russt) [Version 1.61]
#       add %void statement.  re-order main interpreter loop based on estimated frequency of use.
#       add :clr op.  %undef was not clearing CG_* vars.  :undef op now returns ${var:undef} like %undef.
#       move test CG_ROOT to ../bld/cgtstroot, and clear it before first test.
#  21-Feb-2007 (russt) [Version 1.62]
#       filetest ops were emitting "unititialized" messages when result was false (undefined).
#       add %upush statement, to maintain stack with unique elements.
#       add $CG_STACK_DELIMITER user variable, to allow user to %push lists.
#       add %pragma reset_stack_delimiter to restore CG_STACK_DELIMITER to default value.
#       add :stackminus to subtract elements of $CG_STACK_SPEC from a named stack.
#  02-Apr-2007 (russt) [Version 1.63]
#       Add :_<iden> op to wrap xml/html elements, and CG_ATTRIBUTE_<n> spec to
#       decorate element with optional attributes.
#       Fix bug in :indent op - was using stale value for CG_INDENT_STRING.
#  14-Apr-2007 (russt) [Version 1.64]
#       add -T <tmpdir> option.
#  15-May-2007 (russt) [Version 1.65]
#       was not halting if %halt was in included file
#  26-Oct-2007 (russt) [Version 1.66]
#       Add .=, .:= append assignment operators.
#       Add -=, +=, *=, /=, **=, %=, |=, &=, ^=, and x= assignment operators.
#       Implement :split, :top, :bottom, :car, :cdr.
#       Add alias :i for :incr.
#       Add %pushv statement, to create a stack of varibles names matching a pattern.
#       Interpret ${varname:undef} as undefined value for $varname.
#       Add versioned cgdoc.txt to distribution.
#  04-Dec-2007 (russt) [Version 1.67]
#       Search for unimplemented "%" commands externally (e.g. %mkdir, etc).
#       All external commands (%shell and postfix ops) now first cd to CG_SHELL_CWD,
#       Add %pragma "filegen_notices_to_stdout".  If set, will redirect file
#       generation messages to stdout (default is stderr).
#  06-Mar-2008 (russt) [no version change]
#       Fix bug in maven templates, and add some instructions.
#  20-May-2008 (russt) [Version 1.68]
#       Fix bug in :basename operator, and add regression test for it.
#  12-June-2008 (russt) [Version 1.69]
#       Fixed bug in %pushv causing interpreter to exit when user program passes in a bad RE.
#       Add :studyclass op, which generates CG_ class variables.
#       Rework %evalmacro to use more efficient expand_string_template().
#       The template operators: gen_imports, and gen_javadoc, are now evaluated in place.
#       The %echo template operator will also expand in place, but only if %pragma echo_expands 1.
#       Added documentation for template expansion operators.
#  15-Aug-2008 (russt) [Version 1.70]
#       Fixed bug in %ifdef whereby :undef vars were considered defined.
#       Implemented %exec template operator (can also use back-tick syntax).
#       Add :clrifndef op.  Add %pragma update.
#  05-Jan-2009 (russt) [Version 1.71]
#       Correct copyright and version headers.
#       Allow %undef patterns to be wrapped with /match/ or /^match$/.
#       No longer truncate postfix op processing at :undef, so we can operate on undefined values (:clrifndef).
#       Fix bug in template expansion - macros alone on lines and resolving to non-empty strings
#       were reducing newline, and lines at EOF without EOL were adding newline.
#       Fix bug in template expansion of lines containing "%s" sequences.
#       The %pragma statement was not expanding the rhs pragma expression.
#       Emit WARNING and ignore setting for simple boolean %pragma's, unless passed numeric value
#       Add pragmas clrifndef and trim_multiline_rnewline.
#       Add :pragmavalue op.
#       Add :factorShSubs, :factorShVars, and :factorCshVars postfix ops.
#       Add :eolsqeeze op.
#       Add :substituteliteral (alias :sl) op.
#       Add %return -e -s <status> options.
#       Add %eval * (recursive) statement.
#       TODO:  Add recursive (*) option to %evaltemplate statement.
#       Add doc for %halt, %return, %if*, and other missing doc (trim ops, etc.)
#  09-Jan-2009 (russt) [Version 1.72]
#       Fix bug in :factorShSubs - was not using shsub_*_ref macro in subroutine() name declaration.
#       Fix bug in %pop/%shift and :stacksize.  Was not handling empty-string elements correctly.
#       Issue warning if :substituteliteral contains too many separators, and guess where separators belong.
#       Add test #36 to check %while/%whiledef looping methods using stacks; test handling of empty elements.
#       Add examples directory and a few examples.
#  20-Jun-2009 (russt) [Version 1.73]
#       Add %assign (alias %a) template operator.
#  22-Jun-2009 (russt) [Version 1.74]
#       Require whitespace to disambiguate "x=" op, e.g. use "xx x=10" instead of "xxx=10".
#  20-Feb-2010 (russt) [Version 1.75]
#       Use :nameof in trim_multiline_rnewline save/restore in :factorShSubs.  Change :pragmavalue to use
#       :nameof if var is undefined or empty instead of just undefined.
#  26-Feb-2010 (russt) [Version 1.76]
#       Fix bug in :factorShVars, :factorCshVars where variables first appearing on rhs
#       of definition were being omitted.  Also fix more subtle bug whereby variables appearing
#       in generated rhs values, did not always appear in macrotized form.
#  16-Mar-2010 (russt) [Version 1.77]
#       Document perl 5.8.8 on linux bug when copying binary files.  Work-around is "setenv PERLIO stdio".
#       Parameterize package name so we can run as "cado" as well as "codegen".
#  26-Mar-2010 (russt) [Version 1.78]
#       Factor out default values for CG_STACK_DELIMITER & CG_SPLIT_PATTERN.
#       Reset CG_SPLIT_PATTERN during :split if it is undefined.
#  16-Jul-2010 (russt) [Version 1.79]
#       Add :urlencode, :urldecode, :hexencode, :hexdecode, :q <=> :quote, :dq <=> :dquote,
#       :echo <=> :print, :eecho <=> :eprint,  :root, and :cgvar ops.
#       Make %pushv work like %undef, so that it accepts a variable holding the pattern.
#       Correct all %push operations so that if evaluation of rhs results in zero elements,
#       we do not assign anything (leave it undefined.)  (A stack holding an empty string is
#       considered to have size 1, whereas an undefined stack variable has size 0.)
#  22-Jul-2010 (russt) [Version 1.80]
#       Fix a bug in external shell operators whereby trailing newlines are stripped.
#       Correct/add tests to not compensate for extra/missing newlines.  Add test to ensure that
#       FOO = $FOO:cat is identical to original string.
#       Fix a bug in :hexencode, :urlencode ops - were not encoding newlines.
#  25-Jul-2010 (russt) [Version 1.81]
#       Add :s2, :s3, :s4, & :s5 ops, which performs :substitute with $CG_SUBSTITUTE_SPEC<n>.
#       Change verbosity of :env (only squawk about undefined env. vars if -v is set).
#  30-Jul-2010 (russt) [Version 1.82]
#       Add symlink capability for filespecs:   afile <- alinktoafile
#  06-Aug-2010 (russt) [Version 1.83]
#       Add :nl alias, add builtin :pwd op.  Change -u to remove outfiles if they are
#       symlinks and we are generating a regular file.  Pragma's are now getting sync'd to
#       argument settings for: {-u,-q,-v,-ddebug,-debug}.  Quiet now turns off verbose
#       (last setting wins). Add %pragma environment {0|1}, to temporarily allow env. vars.
#  01-Sep-2010 (russt) [Version 1.84]
#       Comment out debugging in exec_shell_op().
#  17-Nov-2010 (russt) [Version 1.85]
#       Add -se (show external) option to trace external commands invoked as operators.
#       Xml library was adding extra newlines due to fix introduced in vers. 1.71 of 11/21/08.
#       Regenerated maven2 libraries to verify process with current version of cado.
#  24-Nov-2010 (russt) [Version 1.86]
#       add :append assignment op.
#  11-Dec-2010 (russt) [Version 1.87]
#       add :unique stack op.  "%upush foostk $value" was not resulting in unique values.
#       add :parse_antprops and associated operators.
#       add tests for new ant ops, :unique.  update %upush tests.
#

use strict;
package cado;

my (
    $VERSION,
    $VERSION_DATE,
) = (
    "1.87",         #VERSION - the program version number.
    "11-Dec-2010",  #VERSION_DATE - date this version was released.
);

require "path.pl";
require "os.pl";
require "pcrc.pl";

# declare global variables, SCALARS only in this section:
my (
    $p,
    $VERBOSE,
    $QUIET,
    $DEBUG,
    $DDEBUG,
    $DEBUG_FD,
    $HELPFLAG,
    $ENV_VARS_OKAY,
    $FORCE_GEN,
    $UPDATE,
    $SHOW_EXTERNS,
    $CG_TEMPLATE_PATH,
    $CG_ROOT,
    $CG_TMPDIR,
    $INPUT_FILE,
    $LOGNAME,
    $DOT,
    $CG_NEWLINE_BEFORE_CLASS_BRACE,
    $CG_INDENT_STRING,
    $GLOBAL_ERROR_COUNT,
    $CG_TMPFILE_CNT,
    $LINE_CNT,
    $LINE_CNT_REF,
    $STRIPTOSHARPBANG,
    $LOOKINPATH,
    $CG_STACK_DELIMITER_DEFAULT_VALUE,
    $CG_SPLIT_PATTERN_DEFAULT_VALUE,
) = (
    $main::p,       #program name inherited from prlskel caller.
    0,              #VERBOSE
    0,              #QUIET
    0,              #DEBUG
    0,              #DDEBUG
    0,              #DEBUG_FD - debug allocation of file descriptors
    0,              #HELPFLAG
    0,              #ENV_VARS_OKAY - true if we allow environment vars in templates and spec
    0,              #FORCE_GEN - overwrite all output files, even if they already exist
    0,              #UPDATE - update generated files only if different
    0,              #SHOW_EXTERNS - show use of external operators (:op)
    "NULL",         #CG_TEMPLATE_PATH - semicolon separated search path for template files.
    "NULL",         #CG_ROOT - output code generation root.
    "NULL",         #CG_TMPDIR - directory for temporary files.
    "",             #INPUT_FILE
    "",             #LOGNAME
    $main::DOT,
    " ",            #CG_NEWLINE_BEFORE_CLASS_BRACE - default is not
    " " x 4,        #CG_INDENT_STRING - define one level of indent, usually 4 spaces
    0,              #GLOBAL_ERROR_COUNT - global error count
    0,              #CG_TMPFILE_CNT - counter to create unique filename for %interpret specs
    0,              #LINE_CNT - current line of file being interpreted
    undef,          #LINE_CNT_REF - reference to user-level line count var CG_LINE_NUMBER
    0,              #STRIPTOSHARPBANG -  true if we have a -x option
    0,              #LOOKINPATH - true if we have a -S option
    "\t",           #CG_STACK_DELIMITER_DEFAULT_VALUE
    '/[\n\t,]/',    #CG_SPLIT_PATTERN_DEFAULT_VALUE
);

#these are global variables that we share within the eval context of postfix ops, for example.
#note that "my" variables are not entered in the symbol table and therefore cannot be looked up by name.
our (
    #note:  don't forget to add new pragmas to %PRAGMA definition below.
    $pragma_preserve_multiline_lnewline,
    $pragma_trim_multiline_rnewline,
    $pragma_copy,
    $pragma_update,
    $pragma_echo_expands,
    $pragma_environment,
    $pragma_require,
    $pragma_debug,
    $pragma_ddebug,
    $pragma_quiet,
    $pragma_verbose,
    $pragma_filegen_notices_to_stdout,
    $pragma_clrifndef,
    $pragma_maxevaldepth,
) = (
    0,              #pragma_preserve_multiline_lnewline - preserve left newline in here-now defs.
    0,              #pragma_trim_multiline_rnewline - trim final newline in here-now defs.
    0,              #pragma_copy - generate files without macro interpolation
    0,              #pragma_update - turn $UPDATE option on or off
    0,              #pragma_echo_expands - template %echo expands macros in argument expression.
    0,              #pragma_environment - use variables from the environment.
    0,              #pragma_require - require a new perl file to allow user to add postfix ops dynamically
    0,              #pragma_debug - set DEBUG option
    0,              #pragma_ddebug - set DDEBUG option
    0,              #pragma_quiet - set QUIET option
    0,              #pragma_verbose - set VERBOSE option
    0,              #pragma_filegen_notices_to_stdout - send file generation (x -> y) messages to stdout, not stderr.
    0,              #pragma_clrifndef - initialize undefined variables to empty string during macro expansion.
    10,             #pragma_maxevaldepth - max depth of recursion for %evalmacro * (recursive).
);

#these are the user names for pragmas.  internal variable is prefixed with "pragma_".
my %PRAGMAS = (
    'preserve_multiline_lnewline', 1,
    'trim_multiline_rnewline', 1,
    'copy', 1,
    'update', 1,
    'echo_expands', 1,
    'environment', 1,
    'require', 1,
    'debug', 1,
    'ddebug', 1,
    'verbose', 1,
    'quiet', 1,
    'reset_stack_delimiter', 1,
    'filegen_notices_to_stdout', 1,
    'clrifndef', 1,
    'maxevaldepth', 1,
);

my @INPUT_DATA;
my %CG_USER_VARS;     #holds varible,value pairs defined in INPUT_FILE
my %CLASS_VARS;    #storage for local class vars - scope is valid between generation directives

#holds implementations of all of our %macro functions for templates
my %MACRO_FUNCTIONS = (
    'include', \&cg_include,
    'perl', \&cg_perl,
    'gen_imports', \&cg_gen_imports,
    'gen_javadoc', \&cg_gen_javadoc,
    'echo', \&cg_echo,
    'exec', \&cg_exec,
    'assign', \&cg_assign,
    'a', \&cg_assign,
);

#keep track of template file descriptors for nested includes:
my ($TEMPLATE_FD_KEY, $LAST_TEMPLATE_FD_KEY, $TEMPLATE_FD_MAX_USED) = (0,79,0);
my @TEMPLATE_FD_REFS = (
    \*TEMPLATE00, \*TEMPLATE01, \*TEMPLATE02, \*TEMPLATE03, \*TEMPLATE04,
    \*TEMPLATE05, \*TEMPLATE06, \*TEMPLATE07, \*TEMPLATE08, \*TEMPLATE09,
    \*TEMPLATE10, \*TEMPLATE11, \*TEMPLATE12, \*TEMPLATE13, \*TEMPLATE14,
    \*TEMPLATE15, \*TEMPLATE16, \*TEMPLATE17, \*TEMPLATE18, \*TEMPLATE19,
    \*TEMPLATE20, \*TEMPLATE21, \*TEMPLATE22, \*TEMPLATE23, \*TEMPLATE24,
    \*TEMPLATE25, \*TEMPLATE26, \*TEMPLATE27, \*TEMPLATE28, \*TEMPLATE29,
    \*TEMPLATE30, \*TEMPLATE31, \*TEMPLATE32, \*TEMPLATE33, \*TEMPLATE34,
    \*TEMPLATE35, \*TEMPLATE36, \*TEMPLATE37, \*TEMPLATE38, \*TEMPLATE39,
    \*TEMPLATE40, \*TEMPLATE41, \*TEMPLATE42, \*TEMPLATE43, \*TEMPLATE44,
    \*TEMPLATE45, \*TEMPLATE46, \*TEMPLATE47, \*TEMPLATE48, \*TEMPLATE49,
    \*TEMPLATE50, \*TEMPLATE51, \*TEMPLATE52, \*TEMPLATE53, \*TEMPLATE54,
    \*TEMPLATE55, \*TEMPLATE56, \*TEMPLATE57, \*TEMPLATE58, \*TEMPLATE59,
    \*TEMPLATE60, \*TEMPLATE61, \*TEMPLATE62, \*TEMPLATE63, \*TEMPLATE64,
    \*TEMPLATE65, \*TEMPLATE66, \*TEMPLATE67, \*TEMPLATE68, \*TEMPLATE69,
    \*TEMPLATE70, \*TEMPLATE71, \*TEMPLATE72, \*TEMPLATE73, \*TEMPLATE74,
    \*TEMPLATE75, \*TEMPLATE76, \*TEMPLATE77, \*TEMPLATE78, \*TEMPLATE79,
);

#this array tracks which TEMPLATE_FD_REFS are in use
my @TEMPLATE_FD_INUSE = (
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
);

my %CG_OPEN_FILE_DESCRIPTORS = ();
my %CG_OFD_CURRENTLINE = ();
my %CG_OFD_CURRENTLINECOUNT = ();
my %CG_OPEN_FILE_FD_INDEXES = ();

&init;      #init globals

sub main
{
    local (*ARGV, *ENV) = @_;

    #unbuffer stdout, stderr:
    my $oldfh;
    $oldfh = select(STDOUT); $| = 1; select($oldfh);
    $oldfh = select(STDERR); $| = 1; select($oldfh);

    #set global flags:
    return (1) if (&parse_args(*ARGV, *ENV) != 0);
    return (0) if ($HELPFLAG);

    #initialize built-in variables:
    &init_spec_vars();

    $INPUT_FILE = &findInputFileInPath($INPUT_FILE) if ( $LOOKINPATH );

    my $rval = &interpret($INPUT_FILE, 1);

    #check to see if any file-descriptors have not been returned:
    printf STDERR "%s:  Allocated max of %d file-handles,  %d/%d free at program end.\n",
        $p, $TEMPLATE_FD_MAX_USED, &free_filehandle_count(), $LAST_TEMPLATE_FD_KEY+1
        if ($DEBUG_FD);

    return $rval;
}

sub interpret
#returns 0 if success, error count if problems.
#read input a line at a time, parse, and execute.
{
    my ($infile, $return_global_status) = @_;
    $return_global_status = 0 if (!defined($return_global_status));  #ignore global errs

    my ($linecnt) = 0;
    my ($line) = "";
    my ($errcnt) = 0;
    my ($use_stdin) = ($infile eq '<STDIN>');
    my ($fhref) = undef;
    my ($fhidx) = -1;
    my ($exit_early) = 0;
    my ($halt_program) = 0;
    my ($is_raw) = 0;     #for := assignment operator
    my ($is_append) = 0;  #for .= assignment operator
    my ($numop) = 0;   #for +=, -=, /=, *= ...

    #initialize line counts:
    $LINE_CNT = $$LINE_CNT_REF = $linecnt;

    my ($save_infile) = "";
    $save_infile = $CG_USER_VARS{'CG_INFILE'} if (defined($CG_USER_VARS{'CG_INFILE'}));
    $CG_USER_VARS{'CG_INFILE'} = $infile;

    if (!$use_stdin) {
        $fhidx = &get_avaliable_filehandle("interpret");

        if ($fhidx < 0) {
            printf STDERR "%s [interpret]: ERROR: out of file descriptors for nested templates (max is %d).\n", $p, $LAST_TEMPLATE_FD_KEY+1;
            ++$GLOBAL_ERROR_COUNT;
            return 1;
        }

        $fhref = $TEMPLATE_FD_REFS[$fhidx];
        if (!open($fhref, $infile)) {
            printf STDERR "%s [interpret]: ERROR: cannot open definition file '%s' (%s)\n", $p, $infile, $!;
            &free_filehandle($fhidx, "interpret");   #free our allocated filehandle
            ++$GLOBAL_ERROR_COUNT;
            return 1;
        }
    }

    $line = $use_stdin? <STDIN> : <$fhref>;    #read one line of input

    #do we need to ignore lines before #! ?
    #note that this could eat the whole file
    while ($STRIPTOSHARPBANG && defined($line)) {
        last if ( $line =~ /^#!/ );    #don't increment line number yet
        chomp $line; ++$linecnt; ++$LINE_CNT; ++$$LINE_CNT_REF;

        $line = $use_stdin? <STDIN> : <$fhref>;    #read one line of input
    }

    #IMPORTANT:  we only do this when called from main the first time:
    $STRIPTOSHARPBANG = 0;

    while (!$exit_early && defined($line)) {
        ++$linecnt; chomp $line; ++$LINE_CNT; ++$$LINE_CNT_REF;
        printf STDERR "line[%d] (%s)='%s'\n", $linecnt, $infile, $line if ($DEBUG);

        my ($dointerpret) = 1;  #used by %ifdef/ifndef

        while ($dointerpret) {
            $dointerpret = 0;   #used by %ifdef/ifndef

            if ($line =~ /^\s*$/ || &comment($line)) {
                ;       #comment or blank:  SKIP
            } elsif (&includespec($line, $linecnt)) {
                ;       #process the named include file.
            } elsif (&interpretspec($line, \$linecnt, $use_stdin, $fhref, $infile)) {
                ;       #create an include file from a variable and include it.
            } elsif (&echospec($line, $linecnt)) {
                ;       #echo some text to stdout
            } elsif (&ifdefspec(\$line, $linecnt, \$dointerpret)) {
                #this may force another loop
                printf STDERR "AFTER ifn?def: line='%s' dointerpret=%d\n", $line, $dointerpret if ($DEBUG);
            } elsif (&ifspec(\$line, $linecnt, \$dointerpret)) {
                #this may force another loop
                printf STDERR "AFTER if[not]: line='%s' dointerpret=%d\n", $line, $dointerpret if ($DEBUG);
            } elsif (&shellspec($line, $linecnt)) {
                ;       #process a shell command.
            } elsif (&foreachspec($line, $linecnt)) {
                ;
            } elsif (&whiledefspec($line, $linecnt)) {
                ;
            } elsif (&whilespec($line, $linecnt)) {
                ;
            } elsif (&pushspec($line, $linecnt)) {
                ;
            } elsif (&popspec($line, $linecnt)) {
                ;
            } elsif (&evalmacro_spec($line, $linecnt)) {
                ;       #evaluate a template-var into an output var
            } elsif (&evaltemplate_spec($line, $linecnt)) {
                ;       #evaluate a template file into an output var
            } elsif (&readtemplate_spec($line, $linecnt)) {
                ;       #read a template file into an output var
            } elsif (&voidspec($line, $linecnt)) {
                ;       #allows uni-variable assignments
            } elsif (&returncommand($line, $linecnt)) {
                #exit intepreter:
                $exit_early = 1;
            } elsif (&undefspec($line, $linecnt)) {
                ;       #undefine a variable
            } elsif (&pragma_spec($line, $linecnt, $infile)) {
                ;       #process a %pragma
            } elsif (&exportspec($line, $linecnt)) {
                ;       #export a variable to the environment
            } elsif (&haltcommand($line, $linecnt)) {
                #exit to shell:
                $exit_early = 1;
                $halt_program = 1;
            } elsif (&definition($line, \$linecnt, $use_stdin, $fhref, $infile)) {
                ;  #note that definitions() can advance the linecnt.
            } elsif (&extern_cmd($line, $linecnt)) {
                ;
            } elsif (&filespec($line, $linecnt)) {
                ;       #process filespec and generate source file
            } else {
                #unrecognized input - generate error:
                printf STDERR "Unrecognized input, line %d:\n'%s'\n", $linecnt, $line;
                ++$errcnt;
            }
        }

        $line = $use_stdin? <STDIN> : <$fhref>;   #get next line
    }

    if (!$use_stdin) {
        close $fhref;
        &free_filehandle($fhidx, "interpret");   #free our allocated filehandle
    }

    #restore the previous input filename if we saved it:
    $CG_USER_VARS{'CG_INFILE'} = $save_infile if ($save_infile ne "");

    #if we are called from %foreach, etc, ignore global errors.
    if (!$halt_program && !$return_global_status) {
        return $errcnt 
    }

    #if user has set exit status, use it:
    my $status = 0;
    if (defined($CG_USER_VARS{'CG_EXIT_STATUS'})) {
        $status =  $CG_USER_VARS{'CG_EXIT_STATUS'};
    } else {
        #otherwise, return interpreter processing error count:
        $status =  $errcnt + $GLOBAL_ERROR_COUNT;
    }

    #####
    #exit immediately if we found a %halt or %abort:
    #####
    exit $status if ($halt_program);

    return $status;
}

sub pushspec
#returns true if we have an %push spec
{
    my ($line, $linecnt) = @_;

    return 0 unless ($line =~ /^\s*(%upush|%push|%pushv)\s+/);
    my $token = $1;
    $line =~ s/^\s*$token\s*//;

    #true if we have $upush statement:
    my ($push_unique) = ($token eq "%upush") ? 1 : 0;
    my ($push_vars) = ($token eq "%pushv") ? 1 : 0;

#printf STDERR "pushspec T2 token='%s' line='%s' push_vars=%d push_unique=%d\n", $token, $line, $push_vars, $push_unique;

    #note:  we do not trim trailing white-space, remainder of line is
    #       treated in the same way as the rhs of an assignment.

    my ($lhs, $rhs)  = split(/\s+/, $line, 2);
    if (!defined($lhs)) {
        printf STDERR "%s: missing stack name in input, line %d:\n'%s'\n", $linecnt, $line;
        return 1;
    }

    #expand lhs varible refs:
    $lhs = &expand_macros($lhs);

    #this is a PUSH operation, so we add to lhs if defined:
    my $lhs_contents = $CG_USER_VARS{$lhs};
    my @rhs_contents = ();

    #NOTE: if we are processing a %pushv spec, then missing rhs => *all* variables.
    if ($push_vars) {
        if (!defined($rhs)) {
            @rhs_contents = &get_user_vars();
        } else {
            #if variable is a variable reference (e.g., $fooptr), then test valueof:
            my $varname = $rhs;
            $varname = &expand_macros($rhs) if ($rhs =~ /^\$/);

            if ($varname ne $rhs && $varname =~ /^\$/) {
                printf STDERR "%s: WARNING: line %d: variable reference '%s' in %s statement is INVALID - ignored.\n",
                    $p, $linecnt, $rhs, $token unless ($QUIET);
                ++ $GLOBAL_ERROR_COUNT;
                #we processed an pushv statement, even if there were errors::
                return 1;
            } else {
                #we found a variable reference and expanded it:
                $rhs = $varname;
            }

            #we now expect rhs to be a perl RE.  find variable names matching pattern:
            my $pat = $rhs;
            $pat =~ s/^\///;    #strip leading slashes
            $pat =~ s/\/$//;    #strip trailing slashes
#printf STDERR "pushv rhs='%s' pat='%s'\n", $rhs, $pat;
            #we use eval here so interpreter does not exit if passed a bad RE:
            eval( "\@rhs_contents = grep(\$_ =~ /$pat/, \&get_user_vars());" );
#printf STDERR "pushv pat='%s' \@rhs_contents=(%s)\n", $pat, join(',', @rhs_contents) ;
        }
    } else {
        #if no value, then we're done:
        return 1 unless (defined($rhs));

        my $rhs_contents = &expand_macros($rhs);
        #split rhs using CG_STACK_DELIMITER (defauts to "\t"):
        @rhs_contents = split(&get_stack_delimiter(), $rhs_contents, -1);

#printf STDERR "pushspec T8 delimiter='%s' rhs_contents='%s' \@rhs_contents=(%s)\n", &get_stack_delimiter(), $rhs_contents, join(',', @rhs_contents) ;
    }

    #if we generate no elements, then don't do anything:
    if ($#rhs_contents >= 0) {
        if (defined($lhs_contents)) {
            if ($lhs_contents ne "") {
                $CG_USER_VARS{$lhs} = join($;, $lhs_contents, @rhs_contents);
            } else {
                $CG_USER_VARS{$lhs} = join($;, @rhs_contents);
            }
        } else {
            $CG_USER_VARS{$lhs} = join($;, @rhs_contents);
        }

        #make stack unique if we had a %upush:
        $CG_USER_VARS{$lhs} = &unique_op($CG_USER_VARS{$lhs}) if ($push_unique == 1);
    }

    return 1;
}

sub MINUS
#returns A - B
#usage:  my (@a, @b); ... ; @difference = &MINUS(\@a, \@b);
{
    my($A, $B) = @_;
    my(%mark);

    for (@{$B}) { $mark{$_}++;}
    return(grep(!$mark{$_}, @{$A}));
}

sub popspec
#returns true if we have an %pop or %shift spec
{
    my ($line, $linecnt) = @_;
    return 0 unless ($line =~ /^\s*%(pop|shift)\s+/);

    my ($ispop) = ($line =~ /^\s*%pop\s+/) ? 1 : 0;
    my ($token) = ($ispop) ? "%pop" : "%shift";

    $line =~ s/^\s*$token\s*//;
    #trim trailing spaces too:
    $line =~ s/\s*$//;

    #the rhs is the stack var, lhs is going to get the top element:
    my (@tmp)  = split(/\s+/, $line, 2);
    if ($#tmp < 1) {
        #error - not enough parameters:
        printf STDERR "%s[%s]: ERROR: line %d: too few parameters:  Usage:  %s topvar stackvar\n",
            $p, $token, $linecnt, $token;

        ++ $GLOBAL_ERROR_COUNT;
        $CG_USER_VARS{'CG_EXIT_STATUS'} = 1;

        return 1;  #we processed a %pop or %shift
    }

    my ($topvarname, $stackvarname)  = (@tmp[0,1]);

    #expand varible refs in statement:
    $stackvarname = &expand_macros($stackvarname);
    $topvarname = &expand_macros($topvarname);

    #undef lhs if the stack is undefined:
    if (!defined($CG_USER_VARS{$stackvarname})) {
        printf STDERR "%s[%s]: WARNING: line %d: stack variable '%s' is undefined.\n",
            $p, $token, $linecnt, $stackvarname if($VERBOSE);

        #force user var to be undefined:
        delete $CG_USER_VARS{$topvarname} if (defined($CG_USER_VARS{$topvarname}));

        return 1;   #return true because we parsed a popspec
    }

    my $stack_contents = $CG_USER_VARS{$stackvarname};
    my (@stack) = ();

    #note:  if stack is empty string, then we avoid split since it sets $#stack (incorrectly IMO) to -1
    if ( $stack_contents eq '' ) {
        push @stack, $stack_contents;
    } else {
        @stack = split($;, $stack_contents, -1); #preserve empty fields
    }

    if ($ispop) {
        #get the top (right end) of the stack:
        $CG_USER_VARS{$topvarname} = pop @stack;
    } else {
        #get the bottom (left end) of the stack:
        $CG_USER_VARS{$topvarname} = shift @stack;
#printf STDERR "shifted: %s='%s' stack=(%s)#stack=%d\n", $topvarname, $CG_USER_VARS{$topvarname}, (@stack) ? join(',', @stack) : "UNDEF", $#stack;
    }

    #if stack has more elements, then save it:
    if ($#stack >= 0) {
        $CG_USER_VARS{$stackvarname} = join($;, @stack);
    } else {
        #stack is now undefined:
        delete $CG_USER_VARS{$stackvarname};
    }

    return 1;
}

sub pragma_spec
#returns true if we have an %pragma spec, which looks like this:
#    %pragma var value
#<var> must be a legitimate perl variable.
#
#WARNING:  you may need to modify :pragmavalue if you add a new pragma here.
#
{
    my ($line, $linecnt, $infile) = @_;
    return 0 unless ($line =~ /^\s*%pragma/);

    my $token = '%pragma';

    $line =~ s/^\s*$token\s*//;
    #trim trailing spaces too:
    $line =~ s/\s*$//;

    return 1 if ($line eq "");

    my ($lhs, $rhs) = split(/\s+/, $line);
    if ( !defined($PRAGMAS{$lhs}) ) {
        printf STDERR "%s: WARNING: %%pragma '%s' unrecognized in file %s line %d.  Valid pragma names are: (%s)\n",
             $p, $lhs, $infile, $linecnt, join(", ", sort keys %PRAGMAS) unless ($QUIET);
        return 1;  #recognized and processed a %pragma
    }

    #######
    #create a named reference to this pragma:
    #######
    my $pragma_var = "pragma_" . $lhs;    #this is the variable we set internally.
    no strict "refs";
    my $pragma_ref = \${$pragma_var};
    use strict "refs";

    ########
    #process the special case pragmas:
    ########

    #reset_stack_delimiter require no value:
    if ($lhs eq 'reset_stack_delimiter') {
        $CG_USER_VARS{'CG_STACK_DELIMITER'} = "\t" ;
        return 1;  #recognized and processed a %pragma
    }

    if ( !defined($rhs) ) {
        printf STDERR "%s: WARNING: %%pragma '%s': no value specified, file %s, line %d. Statement ignored.\n",
             $p, $lhs, $infile, $linecnt unless ($QUIET);
        return 1;  #recognized and processed a %pragma
    }

    #otherwise, continue and expand any variable expressions in rhs:
    $rhs = &expand_macros($rhs);

    printf STDERR "%s:  %%pragma:  line='%s' lhs='%s' rhs='%s'\n", $p, $line, $lhs, $rhs if ($DDEBUG);

    if ( $pragma_var eq "pragma_require" ) {
        #save current value of pragma, which is this case is the name of the include file.
        $$pragma_ref = $rhs;

        #this routine will read in the perl file specified by the user:
        &pragma_require($rhs, $linecnt, $infile);
        return 1;  #recognized and processed a %pragma
    }

    ########
    #process the simple boolean pragmas:
    ########

    if ($rhs =~ /\d+/) {
        #set the pragma through the reference we created earlier:
        $$pragma_ref = $rhs;
    } else {
        printf STDERR "%s: WARNING: %%pragma '%s': value '%s' must be in: {0,1}, file %s, line %d.\n",
            $p, $lhs, $rhs, $infile, $linecnt unless ($QUIET);
    }
    
    #for pragmas that effect options, set corresponding option:
    if ($pragma_var eq "pragma_debug") {
        $DEBUG   = $pragma_debug;
    } elsif ($pragma_var eq "pragma_ddebug") {
        $DDEBUG  = $pragma_ddebug;
    } elsif ($pragma_var eq "pragma_quiet") {
        $QUIET   = $pragma_quiet;
    } elsif ($pragma_var eq "pragma_verbose") {
        $VERBOSE = $pragma_verbose;
    } elsif ($pragma_var eq "pragma_update") {
        $UPDATE = $pragma_update;
    } elsif ($pragma_var eq "pragma_environment") {
        $ENV_VARS_OKAY = $pragma_environment;
    }

    return 1;
}

sub pragma_require
#this routine will read in the perl file specified by the user:
#returns 0 if processed successfully.
{
    my ($perlfn, $linecnt, $infile) = @_;

    #does $the file exist in our template path?
    my ($intemplate) = &find_template($perlfn);
    if (! -r $intemplate) {
        printf STDERR "%s: ERROR: %%pragma require: file %s, line %d: can't find file '%s' in template path: %s\n",
            $p, $infile, $linecnt, $intemplate, $! unless ($QUIET);
        printf STDERR "\tCG_TEMPLATE_PATH='%s'\n", $CG_USER_VARS{'CG_TEMPLATE_PATH'};

        ++ $GLOBAL_ERROR_COUNT;
        $CG_USER_VARS{'CG_EXIT_STATUS'} = 1;
        return 1;    #ERRORS
    }

    #if so, require it.
    my $result = eval "require \"$intemplate\"";

    #if errors, then what?
    if ($@) {
        printf STDERR "%s: ERROR: %%pragma require: file %s, line %d: require of file '%s' FAILED: %s\n",
            $p, $infile, $linecnt, $intemplate, $@ unless ($QUIET);

        ++ $GLOBAL_ERROR_COUNT;
        $CG_USER_VARS{'CG_EXIT_STATUS'} = 1;
        return 1;    #ERRORS
    } elsif (!defined($result)) {
        #WARNING:  the $@ construct doesn't seem to work on perl 5.005_03.  RT 6/19/06
        printf STDERR "%s: ERROR: %%pragma require: file %s, line %d: require of file '%s' FAILED: %s\n",
            $p, $infile, $linecnt, $intemplate, "ERROR in eval" unless ($QUIET);

        ++ $GLOBAL_ERROR_COUNT;
        $CG_USER_VARS{'CG_EXIT_STATUS'} = 1;
        return 1;    #ERRORS
    }

    return 0;    #SUCCESS
}

sub evalrecursive
#private routine returns true if we have an %eval * (recursive) statement.
#if output var is prefixed by '>>', then we append the variable.
#NOTE:  when we get here we have already scanned "%evalmacro *".
{
    my ($line, $linecnt, $token) = @_;

    my $is_append = 0;
    if ($line =~ /^>>\s*/) {
        $is_append = 1;
        $line =~ s/^>>\s*//;
    }

    my ($output_var, $macro_var_ref_in)  = split(/\s+/, $line, 2);

    if (!defined($output_var) || !defined($macro_var_ref_in)) {
        printf STDERR "%s[%s *]: ERROR: line %d: Usage %s * OUT IN\n",
            $p, $token, $linecnt, $token unless($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        return 1;   #return true because we parsed a %evalmacro
    }

    #expand varible refs in statement:
    $output_var = &expand_macros($output_var);
    my $macro_var_ref = &expand_macros($macro_var_ref_in);

    if (!defined($CG_USER_VARS{$macro_var_ref})) {
        printf STDERR "%s[%s *]: ERROR: line %d: variable '%s' is undefined.\n",
            $p, $token, $linecnt, $macro_var_ref_in unless($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        return 1;   #return true because we parsed a %evalmacro
    }

    my $macro_var = $CG_USER_VARS{$macro_var_ref};

    printf STDERR "evalrecursive: output_var='%s' macro_var='%s'\n", $output_var, $macro_var if ($DEBUG);

    my $tmp = &expand_string_template($macro_var);
    my ($cnt, $lasteval) = (0,"");

    #while eval is different...
    while(1 < 2) {
        ++$cnt;
#printf STDERR "evalrecursive LOOP cnt=%d max=%d tmp='%s'\n", $cnt, $pragma_maxevaldepth,  $tmp;

        #max == 1 <=> %evalmacro
        if ($pragma_maxevaldepth > 0 && $cnt >= $pragma_maxevaldepth) {
#printf STDERR "evalrecursive EXIT LOOP A cnt=%d max=%d tmp='%s'\n", $cnt, $pragma_maxevaldepth, $tmp;
            printf STDERR "%s: WARNING: line %d: %s * exceeded max recursion depth: %%pragma maxevaldepth %d\n",
                $p, $linecnt, $token, $pragma_maxevaldepth unless ($QUIET);
            last;
        }

        $lasteval = $tmp;
        $tmp = &expand_string_template($tmp);
        if ($tmp eq $lasteval) {
#printf STDERR "evalrecursive EXIT LOOP B cnt=%d max=%d tmp='%s' lasteval='%s'\n", $cnt, $pragma_maxevaldepth, $tmp, $lasteval;
            last;
        }
    }

    if ($is_append && defined($CG_USER_VARS{$output_var})) {
        $CG_USER_VARS{$output_var} .= $tmp;
    } else {
        $CG_USER_VARS{$output_var} = $tmp;
    }

    printf STDERR "evalrecursive: AFTER expand_string_template: var='%s value='%s'\n", $output_var, $CG_USER_VARS{$output_var} if ($DEBUG);

    return 1;
}

sub evalmacro_spec
#returns true if we have an %evalmacro spec
#if output var is prefixed by '>>', then we append the variable.
{
    my ($line, $linecnt) = @_;
    return 0 unless ($line =~ /^\s*%evalmacro/);

    my $token = '%evalmacro';

    $line =~ s/^\s*$token\s*//;
    #trim trailing spaces too:
    $line =~ s/\s*$//;

    if ($line =~ /^\*\s*/) {
        #scan past recursive designator:
        $line =~ s/^\*\s*//;
        return &evalrecursive($line, $linecnt, $token);
    }

    my $is_append = 0;
    if ($line =~ /^>>\s*/) {
        $is_append = 1;
        $line =~ s/^>>\s*//;
    }

    my ($output_var, $macro_var_ref_in)  = split(/\s+/, $line, 2);

    #expand varible refs in statement:
    $output_var = &expand_macros($output_var);
    my $macro_var_ref = &expand_macros($macro_var_ref_in);

    if (!defined($CG_USER_VARS{$macro_var_ref})) {
        printf STDERR "%s[%s]: ERROR: line %d: variable '%s' is undefined.\n",
            $p, $token, $linecnt, $macro_var_ref_in unless($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        return 1;   #return true because we parsed a evalmacro_spec
    }

    my $macro_var = $CG_USER_VARS{$macro_var_ref};

    printf STDERR "evalmacro_spec: output_var='%s' macro_var='%s'\n", $output_var, $macro_var if ($DEBUG);

    my $tmp = &expand_string_template($macro_var);

    if ($is_append && defined($CG_USER_VARS{$output_var})) {
        $CG_USER_VARS{$output_var} .= $tmp;
    } else {
        $CG_USER_VARS{$output_var} = $tmp;
    }

    printf STDERR "evalmacro_spec: AFTER expand_string_template: var='%s value='%s'\n", $output_var, $CG_USER_VARS{$output_var} if ($DEBUG);

    return 1;
}

sub evaltemplate_spec
#returns true if we have an %evaltemplate spec
{
    my ($line, $linecnt) = @_;
    return 0 unless ($line =~ /^\s*%evaltemplate/);

    $line =~ s/^\s*%evaltemplate\s*//;
    #trim trailing spaces too:
    $line =~ s/\s*$//;

    my $is_append = 0;

    if ($line =~ /^>>\s*/) {
        $is_append = 1;
        $line =~ s/^>>\s*//;
    }

    my ($output_var, $template_fn)  = split(/\s+/, $line, 2);

    #expand varible refs in statement:
    $output_var = &expand_macros($output_var);
    #NOTE:  $template_fn is expanded by filespec.

    #get a tempfile name:
    my $tmpfile = sprintf("_cado.evaltemplate.%d", $$);
    my $tmpfile_fullpath = &get_cg_tmpfile_name($tmpfile);
    unlink $tmpfile_fullpath;    #this filename is not unique, make sure it is gone.

    my $filespecline = sprintf("%s\t/%s", $template_fn, $tmpfile);
#printf "evaltemplate_spec: output_var='%s' template_fn='%s' filespecline='%s'\n", $output_var, $template_fn, $filespecline;
    my $save_quiet = $QUIET;
    $QUIET = 1;
    if (!&filespec($filespecline, $linecnt, $CG_USER_VARS{'CG_TMPDIR'})) {
        printf STDERR "%s/evaltemplate_spec: line %d: FAILED to execute filespec '%s'\n", $p, $linecnt, $filespecline;
        ++ $GLOBAL_ERROR_COUNT;
        $QUIET = $save_quiet;
        return 1;   #return true because we parsed a evaltemplate_spec
    }
    $QUIET = $save_quiet;

    #read the output file into the output_var:
    my $tmp = "";
    if (&os::read_file2str(\$tmp, $tmpfile_fullpath) == 0) {
        if ($is_append && defined($CG_USER_VARS{$output_var})) {
            $CG_USER_VARS{$output_var} .= $tmp;
        } else {
            $CG_USER_VARS{$output_var} = $tmp;
        }
    } else {
        printf STDERR "%s/evaltemplate_spec: FAILED to read file '%s'\n", $p, $tmpfile_fullpath;
        ++ $GLOBAL_ERROR_COUNT;
    }

    #delete the tmp file:
    unlink $tmpfile_fullpath;
#printf "evaltemplate_spec: output_var='%s' template_fn='%s'\n", $output_var, $template_fn;
    return 1;
}

sub readtemplate_spec
#returns true if we have an %readtemplate spec
{
    my ($line, $linecnt) = @_;
    return 0 unless ($line =~ /^\s*%readtemplate\s+/);

    $line =~ s/^\s*%readtemplate\s+//;
    #trim trailing spaces too:
    $line =~ s/\s*$//;

    my ($output_var, $template_fn)  = split(/\s+/, $line, 2);

    #expand varible refs in statement:
    $output_var = &expand_macros($output_var);
    $template_fn = &expand_macros($template_fn);
    $template_fn = &expand_include_fn($template_fn);

#printf "readtemplate_spec: output_var='%s' template_fn='%s'\n", $output_var, $template_fn;

    #read the template file into the output_var:
    my $ovref = \$CG_USER_VARS{$output_var};
    $$ovref = "";
    if (&os::read_file2str($ovref, $template_fn) != 0) {
        $$ovref = "";
        printf STDERR "%s/readtemplate_spec: FAILED to read file '%s'\n", $p, $template_fn;
        ++ $GLOBAL_ERROR_COUNT;
    }

    return 1;
}

sub includespec
#returns true if we have an include spec.
#process include.  (this is a recursive call)
{
    my ($line, $linecnt) = @_;
    return 0 unless ($line =~ /^\s*%include\s+/);

    #we have an include - get the file name:
    my $includefn = $line;

    $includefn =~ s/^\s*%include\s+//;
    #trim trailing spaces too:
    $includefn =~ s/\s*$//;

    #expand include file name to full path with variable substitution:
    $includefn = &expand_include_fn($includefn);

    printf STDERR "%s: Including definition file '%s'\n", $p, $includefn if ($VERBOSE);

    ++$GLOBAL_ERROR_COUNT unless (&interpret($includefn) == 0);

    return 1;   #we found and processed an include, even if there were errors...
}

sub interpretspec
#create an include file from a variable and include it.
#returns true if we have an %interpret <varname> spec
{
    my ($line, $linecnt, $use_stdin, $fhref, $infile) = @_;
        #note:  $linecnt is a reference.

#printf STDERR "interpretspec: line='%s'\n", $line;

    return 0 unless ($line =~ /^\s*%call/ || $line =~ /^\s*%interpret/);

    my $token = '%interpret';
    $token = '%call' if ($line =~ /^\s*%call/);

    $line =~ s/^\s*$token\s+//;

    my ($input_var)  = $line;
    my ($tmpvarname)  = "";

    #check for here-now doc:
    if ($line =~ /=\s*<</) {
        #add a tmp varname in front of assignment:
        $tmpvarname = &newtmpvarname();
        $line = sprintf("%s %s\n", $tmpvarname, $line);
        $input_var  = $tmpvarname;

#printf STDERR "interpretspec: line='%s'\n", $line;

        if (&definition($line, $linecnt, $use_stdin, $fhref, $infile)) {
            ;
        } else {
            #processing for rhs of assignment failed:
            printf STDERR "%s[%s]: failed to parse here-now definition: '%s'\n", $p, $token, $line;
            ++ $GLOBAL_ERROR_COUNT;
            &undef_tmpvar($tmpvarname);
            return 1;   #return true because we parsed an interpretspec
        }
    } else {
        #not a here-now - trim trailing spaces:
        $line =~ s/\s*$//;
    }

    #expand varible refs in statement:
    my $input_var_ref = &expand_macros($input_var);

#printf STDERR "%s: input_var='%s' input_var_ref='%s' tmpvarname{%s}='%s'\n", $token, $input_var, $input_var_ref, $tmpvarname, $CG_USER_VARS{$tmpvarname};

    printf STDERR "%s: input_var='%s' input_var_ref='%s'\n", $token, $input_var, $input_var_ref if ($DEBUG);

    #ensure that our variable reference is defined.
    if (!defined($CG_USER_VARS{$input_var_ref})) {
        printf STDERR "%s[%s]: variable '%s'->'%s' is undefined.\n", $p, $token, $input_var, $input_var_ref;
        ++ $GLOBAL_ERROR_COUNT;
        &undef_tmpvar($tmpvarname);
        return 1;   #return true because we parsed an interpretspec
    }

    #write contents of our <input_var> into a tmp file:
    my $input_var_contents = $CG_USER_VARS{$input_var_ref};
    my $tmpfile_fullpath = &write_string_to_cg_tmp_file($input_var_contents);
    if ($tmpfile_fullpath eq "NULL") {
        printf STDERR "%s[%s]: ERROR: line %d: cannot create temp file.\n",
            $p, $token, $$linecnt unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        &undef_tmpvar($tmpvarname);
        return 1;   #return true because we parsed a evalmacro_spec
    }

    ##########
    #interpret contents of variable as if it were an %include:
    ##########
    ++$GLOBAL_ERROR_COUNT unless (&interpret($tmpfile_fullpath) == 0);

    #clean up tmp file, tmpvar:
    &undef_tmpvar($tmpvarname);
    unlink $tmpfile_fullpath;

    return 1;
}

sub expand_include_fn
#search CG_TEMPLATE_PATH for an include file
#return the full path of the file if found, otherwise, return input.
{
    my ($includefn) = @_;

    #expand definitions in include file name:
    my $tmpfn = &expand_macros($includefn);

    if ($tmpfn eq "") {
        printf STDERR "%s[expand_include_fn]: WARNING: %%include '%s' expands to empty filename.\n", $p, $includefn;
        return $includefn;
    }

    #if include file is not an absolute path...
    if ($tmpfn !~ /^\//) {
        #then make it relative to the template root:
        $tmpfn = &find_template($tmpfn);
    }

    return $tmpfn;
}

sub get_shell_cwd
#if CG_SHELL_CWD is defined, then return it - otherwise, return CG_ROOT.
#if CG_ROOT is used and doesn't exist, then we create it.
{
    return &lookup_def('CG_SHELL_CWD') if (&var_defined('CG_SHELL_CWD'));

    return($DOT);
}

sub get_shell_cd_cmd
#generate command string to cd to the current shell directory.
#if directory doesn't exist, then return empty string.
{
    my $cwd = &get_shell_cwd();

    return "" if ($cwd eq $DOT);  #skip cd if we are already there

    return ( (-d $cwd)? sprintf("cd %s && ", $cwd) : "" );
}

sub extern_cmd
#processed last.  If we have a "%" command that is not handled,
#then we look for an external command of the same name.
#returns true if command is processed.
#does not work if command name has spaces in it.
{
    my ($line, $linecnt) = @_;

    return 0 unless ($line =~ /^\s*%([a-zA-Z0-9_\\\/\-\.]+)\s*(.*)$/);

    #otherwise, pull out the command name:
    my $cmdname = $1;
    my $cmdargs = (defined($2) ? " " . $2 : "");

    #for simplicity, we currently do not allow the command name to be a variable expression.  RT 11/21/07
    $cmdargs = &expand_macros($cmdargs) if ($cmdargs ne "");

    #execute command in current shell directory:
    my $cmd = sprintf("sh -c '%s%s%s'", &get_shell_cd_cmd(), $cmdname, $cmdargs);

    printf STDERR "%s: processing external shell command '%s'\n", $p, $cmd if ($VERBOSE);

    $CG_USER_VARS{'CG_SHELL_STATUS'} = 254;    #unless shell sets status, we assume bad
    system($cmd);
    $CG_USER_VARS{'CG_SHELL_STATUS'} = $?;

    return 1;   #we found and processed a shell command, even if there were errors...
}

sub shellspec
#returns true if we have an call to the shell
{
    my ($line, $linecnt) = @_;
    return 0 unless ($line =~ /^\s*%shell\s+/);

    #we have an shell command - get the command string:
    my $cmd = $line;

    $cmd =~ s/^\s*%shell\s+//;

    #expand definitions in command string:
    $cmd = &expand_macros($cmd);

    $cmd = sprintf("sh -c '%s%s'", &get_shell_cd_cmd(), $cmd);

    printf STDERR "%s: processing shell command '%s'\n", $p, $cmd if ($VERBOSE);

    $CG_USER_VARS{'CG_SHELL_STATUS'} = 254;    #unless shell sets status, we assume bad
    system($cmd);
    $CG_USER_VARS{'CG_SHELL_STATUS'} = $?;

    return 1;   #we found and processed a shell command, even if there were errors...
}

sub echospec
#returns true if we have an %echo (alias %print) command
{
    my ($line, $linecnt) = @_;
    my ($token) = "";

    $token = $1 if ($line =~ /^\s*(%e?echo)\s*/ || $line =~ /^\s*(%printe?)\s*/);
    return if ($token eq "");

    my ($use_stderr) = ($token eq "%eecho" || $token eq "%eprint") ? 1 : 0;

    #we have an echo command - delete the command:
    $line =~ s/^\s*$token\s*//;

    #do we have a -n?
    my $nonewline = ($line =~ /^-n\s+/) ? 1 : 0;
    $line =~ s/^-n\s+// if ($nonewline);

    my $echotext = $line;

    printf STDERR "\nechospec: token='%s' use_stderr=%d echotext='%s'\n",
        $token, $use_stderr, $echotext if ($DEBUG);

    #expand definitions in text:
    $echotext = &expand_macros($echotext) if ($echotext ne "");

    if ($use_stderr) {
        print STDERR sprintf "%s%s", $echotext, $nonewline ? "" : "\n";
    } else {
        print sprintf "%s%s", $echotext, $nonewline ? "" : "\n";
    }

    return 1;   #we found and processed a echo command
}

sub voidspec
#returns true if we have an %void command
{
    my ($line, $linecnt) = @_;
    return 0 unless ($line =~ /^\s*%void\s+/);

    #we have an void command - get the command string:
    my $cmd = $line;

    $cmd =~ s/^\s*%void\s+//;

    #expand definitions in command string:
    $cmd = &expand_macros($cmd);

    printf STDERR "%s: processing void command '%s'\n", $p, $cmd if ($VERBOSE);

    return 1;   #we found and processed a void command, even if there were errors...
}

sub returncommand
#returns true if we have an %return or %exit command
#NOTE:  use %halt to exit to shell
{
    my ($line, $linecnt) = @_;
    my $token = "";

    return 0 unless ($line =~ /^\s*%(exit|return)\s*$/ || $line =~ /^\s*%(exit|return)\s+/);

    #skip past command token:
    $line =~ s/^\s*%(exit|return)\s*//;
    $token = $1;

    #check for options:
    #  -e      redirects message to stderr
    #  -s num  set CG_EXIT_STATUS to <num>

    my $msgtostderr = 0;

    while ($line =~ /^-[es]/) {
        if ( $line =~ /^-e(\s+|$)/ ) {
            $line =~ s/^-e\s*//;
            $msgtostderr = 1;
        } elsif ( $line =~ /^-s(\s+|$)/ ) {
            $line =~ s/^-s\s*//;

            if ( $line =~ /^(-?\d+)(\s+|$)/ ) {
                #set exit status:
                $CG_USER_VARS{'CG_EXIT_STATUS'} = $1;

                $line =~ s/^-?\d+\s*//;
            } else {
                printf STDERR "%s: ERROR: line %d: Usage:  %s [-e] [-s status] [message]\n",
                    $p, $linecnt, ('%' . $token) unless ($QUIET);
                ++ $GLOBAL_ERROR_COUNT;
            }
        }
    }

    #we get the message string:
    my $exitmessage = $line;

    #can have exit message:
    if ($exitmessage ne "") {
        #expand definitions in text:
        $exitmessage = &expand_macros($exitmessage);

        #if still not empty...
        if ($exitmessage ne "") {
            if ($msgtostderr) {
                print STDERR "$exitmessage\n" 
            } else {
                print "$exitmessage\n" 
            }
        }
    }

    return 1;   #we found and processed a exit command
}

sub haltcommand
#returns true if we have an %halt or %abort command
#this command will exit to shell.  if status is provided,
#exit with status, otherwise, exit with zero status.
{
    my ($line, $linecnt) = @_;
    return 0 unless ($line =~ /^\s*%(halt|abort)\s*$/ || $line =~ /^\s*%(halt|abort)\s+/);

    #we have an exit command - get the command string:
    my $exitstatus = $line;

    $exitstatus =~ s/^\s*%(halt|abort)\s*//;

    #can have exit message:
    if ($exitstatus ne "") {
        #expand definitions in text:
        $exitstatus = &expand_macros($exitstatus);

        #set error if exit status does not expand to a number:
        $exitstatus = 1 unless (&is_integer($exitstatus));
        $CG_USER_VARS{'CG_EXIT_STATUS'} = $exitstatus;
    }

    return 1;   #we found and processed a halt command
}

sub comment
#true if comment or blank line
#comment lines can start with #, {, or }.
#curly braces are useful for navigating large cado.
{
    my ($line) = @_;
    return ($line =~ /^\s*[#{}]/);
}

sub filespec
#true if line contains a filespec, which is of the form:
#
#  template  [>>]full_class_name
#or, for symlink creation:
#  linkto  <- path
#
#the full_class_name is just a java class name or a file path.
#if prefixed or delimited by '.', we assume a java class and generate a file with a .java suffix.
#otherwise, if prefixed or delimited by '/' then user must supply suffix if desired
#if prefixed by '>>', then we append to the file, otherwise we create new.
{
    my ($line, $linecnt, $cgroot, $isTmpFilespec) = @_;

    #if we are processing an internally generated filespec, then we take a slightly
    #different path.  In particular, we don't disturb the CG_* class variables.
    #NOTE:  formerly, we generated an internal filespec to process %evalmacro.  Now we
    #use expand_string_template(), which is simpler and more efficient.
    #Hence the isTmpFilespec feature is currently unused.  RT 5/30/08.
    $isTmpFilespec = 0 unless (defined($isTmpFilespec));

    #kill leading white-space:
    $line =~ s/^\s+//;

    #split into two fields:
    my (@tmp) = split(/\s+/, $line, 2);

    return 0 if ($#tmp != 1);

    #otherwise, proceed...
    my ($template, $filespec) = @tmp;
    my $is_append = 0;
    my $is_symlink = 0;

#printf STDERR "BEFORE append check template='%s' filespec='%s' is_append=%d\n", $template, $filespec, $is_append;

    if ($filespec =~ /\s*<-\s*/) {
        $is_symlink = 1;
        $filespec =~ s/\s*<-//;
    }

    if ($filespec =~ /\s*>>\s*/) {
        $is_append = 1;
        $filespec =~ s/\s*>>//;
    }

    #eliminate leading, trailing spaces from file name, but allow internal whitespace:
    $filespec =~ s/^\s+//;
    $filespec =~ s/\s+$//;

#printf STDERR "AFTER append check template='%s' filespec='%s' is_append=%d\n", $template, $filespec, $is_append;

    #create the following class variables:
    #  (dirname, filename, fullclassname, relativeclassname, fullpackagename, relativepackagename)
    #create the following template variables:
    #  templatefilename

    $filespec = &expand_macros($filespec);
    $template = &expand_macros($template);

    my $fvars_ref = undef;
    if ($isTmpFilespec) {
        #don't want to rewrite these based on tmp filespec generated by %evalmacro:
        my %anonhash = ();
        $fvars_ref = \%anonhash;
    } else {
        $fvars_ref = \%CLASS_VARS; 
    }

    &gen_classvars($fvars_ref, $filespec);

    #expand template var a second time, AFTER we create the class vars from the filespec:
    #$template = &expand_macros($template) unless ($isTmpFilespec);

    #reset input template:
    $$fvars_ref{'CG_TEMPLATE'} = $template;

    &dumphash(\%CLASS_VARS, "CLASS_VARS") if ($DEBUG);

    #make sure that CG_ROOT is defined unless it was passed as parameter:
    if (!defined($cgroot)) {
        #default is to generate to CG_ROOT
        if (!&create_cg_root()) {
            printf STDERR "%s[filespec]: ERROR: line %d: cannot create CG_ROOT, '%s'\n",
                $p, $linecnt, $CG_USER_VARS{'CG_ROOT'}  unless ($QUIET);
            ++ $GLOBAL_ERROR_COUNT;
            #we processed a file-spec, even if there were errors:
            return 1;
        }

        #set it after call to create_cg_root, as this could init it:
        $cgroot = $CG_USER_VARS{'CG_ROOT'};
    }

    #now create the sourcefile or symlink from the template:
    &gen_sourcefile($fvars_ref, $line, $linecnt, $is_append, $is_symlink, $cgroot);

    return 1;
}

sub gen_classvars
#INPUT:   a file/class specification, starting at the cado root.
#         example:  com.sun.jbi.admin.packaging.unzip
#OUTPUT:  add vars to <cvar_ref> hash, indexed by the following keys:
#  (DIRNAME, FILENAME, REL_PKGNAME, FULL_PKGNAME, CLASSNAME, FULL_CLASSNAME)
{
    my ($cvar_ref, $filespec) = @_;
    my (%out) = (); #cvar_ref is value-result parameter

    printf STDERR "genclassvars:  filespec='%s'\n", $filespec if ($DEBUG);

    my ($isjava) = ($filespec =~ /\./ && $filespec !~ /\//);
    my (@parts);

    if ($isjava) {
        @parts = split(/[\.]+/, $filespec);
    } else {
        @parts = split(/[\/]+/, $filespec);
    }

    #FILENAME
    my ($filename) = $parts[$#parts];
    #add .java to filename if we are doing java:
    $filename = "$filename.java" if ($isjava);

    #DIRNAME
    my ($dirname) = join('/', @parts[0..$#parts-1]);

    #FULL_PKGNAME
    my ($fullpkg) = join('.', @parts[0..$#parts-1]);

    #PKGNAME
    my ($pkgname) = join('.', $parts[$#parts-1]);

    #CLASSNAME
    my ($classname) = $parts[$#parts];
    #eliminate suffix in classname if present:
    $classname =~ s/\.[a-zA-Z0-9_]*$//;

    #####
    #save results in caller's hash:
    #####
    ${$cvar_ref}{'CG_DIRNAME'}        = $dirname;
    ${$cvar_ref}{'CG_FILENAME'}       = $filename;

    ${$cvar_ref}{'CG_PKGNAME'}    = $pkgname;
    ${$cvar_ref}{'CG_FULL_PKGNAME'}   = $fullpkg;

    ${$cvar_ref}{'CG_CLASSNAME'}  = $classname;
    ${$cvar_ref}{'CG_FULL_CLASSNAME'} = "$fullpkg.$classname";

    return 0;       #0 => no errors
}

sub undefspec
#true if we see an %undef
#this eliminates a variable from our table.
{
    my ($line, $linecnt) = @_;
    my $token = '%undef';
    return 0 unless ($line =~ /^\s*$token\s+/);

    #we have an undef - get the variable name:
    my $varname_in = $line;

    $varname_in =~ s/^\s*$token\s+//;

    #if variable name is missing ...
    if (!defined($varname_in)) {
        printf STDERR "%s: ERROR: line %d: %s missing variable name\n", $p, $linecnt, $token;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #if variable is a variable reference (e.g., $fooptr), then test valueof:
    my $varname = $varname_in;
    $varname = &expand_macros($varname_in) if ($varname_in =~ /^\$/);

    if ($varname ne $varname_in && $varname =~ /^\$/) {
        printf STDERR "%s: WARNING: line %d: variable reference '%s' in %s statement is INVALID - ignored.\n",
            $p, $linecnt, $varname_in, $token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        #we processed an undef statement, even if there were errors::
        return 1;
    }

    #finally, treat spec as a match expression, and delete all vars that match:
    my $match_cnt = 0;
    my @matchvars = ();
    my $vpat = $varname;

    #delete leading/trailing "/" chars:
    $vpat =~ s|^/|| ; $vpat =~ s|/$||;

    #also delete leading "^" and trailing "$" chars:
    $vpat =~ s|^\^|| ; $vpat =~ s|\$$||;

    #user must fully specify match pattern from beginning of variable names:
    $vpat = '^' . $vpat . '$';

    printf STDERR "UNDEF SPEC:  vpat='%s'\n", $vpat if ($DEBUG);

    foreach my $kk (keys %CG_USER_VARS) {
        if ($kk =~ /$vpat/) {
            push @matchvars, $kk;
            delete $CG_USER_VARS{$kk};
            ++$match_cnt;
        }
    }

    printf STDERR "%s: INFO:  line %d: undefined %d variables: (%s)\n",
        $token, $LINE_CNT, $match_cnt, join(', ', @matchvars) if ($VERBOSE);

    return 1;   #we found and processed an undef, even if there were errors...
}

sub exportspec
#true if we see an %export or %unexport
#this will export or unexport a variable from the env.
{
    my ($line, $linecnt) = @_;
    return 0 unless ($line =~ /^\s*%(export|unexport)\s+/);

    my ($isexport) = ($line =~ /^\s*%export\s+/) ? 1 : 0;
    my ($token) = ($isexport) ? "%export" : "%unexport";

    $line =~ s/^\s*$token\s*//;
    #trim trailing spaces too:
    $line =~ s/\s*$//;

    #we have an export/unexport - get the variable name:
    my $varname_in = $line;

    #if variable name is missing ...
    if (!defined($varname_in)) {
        printf STDERR "%s: ERROR: line %d: %s missing variable name\n", $p, $linecnt, $token;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #if variable is a variable reference (e.g., $fooptr), then test valueof:
    my $varname = $varname_in;
    $varname = &expand_macros($varname_in) if ($varname_in =~ /\$/);

    if ($varname ne $varname_in && $varname =~ /\$/) {
        printf STDERR "%s: WARNING: line %d: variable reference '%s' in %s statement is INVALID - ignored.\n",
            $p, $linecnt, $varname_in, $token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        #we processed an export/unexport statement, even if there were errors::
        return 1;
    }

    #finally, export or unexport the variable to the ENV hash:
    if ($isexport) {
        $ENV{$varname} = $CG_USER_VARS{$varname};
    } else {
        delete $ENV{$varname};
    }

    printf STDERR "%s: INFO:  line %d: %sed %s='%s'\n",
        $p, $LINE_CNT, $token, $varname, $CG_USER_VARS{$varname} if ($VERBOSE);

    return 1;   #we found and processed an export/unexport, even if there were errors...
}

sub ifdefspec
#true if we see an %ifdef or %ifndef.
#sets _do_eval to 1 if we are to evaluate modified _line
#example:  %ifdef CG_ROOT CGROOT_BASE = $CG_ROOT
#example:  %ifdef FOOVAR %echo FOOVAR is '$FOOVAR'
{
    my ($_line, $linecnt, $_doeval) = @_;
    my ($line) = ${$_line};

    #RESULT:
    ${$_doeval} = 0;

    return 0 unless ($line =~ /^\s*%ifn?def\s+/);

    my ($isifdef) = ($line =~ /^\s*%ifdef\s+/) ? 1 : 0;
    my ($token) = ($isifdef) ? "%ifdef" : "%ifndef";

    #scan past %ifdef:
    $line =~ s/^\s*%ifn?def\s+//;

    #get variable token
    my ($varname_in,$def_expr) = split(/\s+/, $line, 2);
    printf STDERR "%s: varname_in=%s def_expr=%s\n", $token, $varname_in, $def_expr if ($DEBUG);

    #if variable name is missing ...
    if (!defined($varname_in)) {
        printf STDERR "%s: ERROR: line %d: %s missing variable name\n",$p,$linecnt,$token;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #if DEFINITION expression missing ...
    if (!defined($def_expr)) {
        printf STDERR "%s: ERROR: line %d: %s missing statement clause\n",$p,$linecnt,$token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #if variable is a variable reference (e.g., $fooptr), then test valueof:
    my $varname = $varname_in;
    $varname = &expand_macros($varname_in) if ($varname_in =~ /\$/);

    if ( $varname ne $varname_in && ($varname =~ /\$/ && !&isUndefinedValue($varname)) ) {
        printf STDERR "%s: WARNING: line %d: variable reference '%s' in %s expression is INVALID - ignored.\n",
            $p, $linecnt, $varname_in, $token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        #we processed an ifn?def statement, even if there were errors::
        return 1;
    }

    my $vardefined  = &var_defined_strict($varname);
    my $doeval = ( ($vardefined && $isifdef) || (!$vardefined && !$isifdef) );

    printf STDERR "%s: vardefined=%d doeval=%d\n", $token, $vardefined, $doeval if ($DEBUG);

    return 1 unless ($doeval);     #we are done with this line.

    #otherwise, re-interpret the remainder of the line:
    ${$_line} = $def_expr;
    ${$_doeval} = 1;

    return 1;
}

sub ifspec
#true if we see an %if or %ifnot.
#sets _do_eval to 1 if we are to evaluate modified _line
#i.e., if string or variable evaluates to non-zero or non-empty, it is true
{
    my ($_line, $linecnt, $_doeval) = @_;
    my ($line) = ${$_line};

    #RESULT:
    ${$_doeval} = 0;

    return 0 unless ($line =~ /^\s*%(if|ifnot)\s+/);

    my ($isifexpr) = ($line =~ /^\s*%if\s+/) ? 1 : 0;
    my ($token) = ($isifexpr) ? "%if" : "%ifnot";

    #scan past %if or %ifnot:
    if ($isifexpr) {
        $line =~ s/^\s*%if\s+//;
    } else {
        $line =~ s/^\s*%ifnot\s+//;
    }

    #get variable token
    my ($varexpr,$if_clause) = split(/\s+/, $line, 2);
    printf STDERR "%s: varexpr=%s if_clause=%s\n", $token, $varexpr, $if_clause if ($DEBUG);

    #if variable name is missing ...
    if (!defined($varexpr)) {
        printf STDERR "%s: ERROR: line %d: %s missing variable expression\n",$p,$linecnt,$token;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #if statement clause missing ...
    if (!defined($if_clause)) {
        printf STDERR "%s: ERROR: line %d: %s missing statement clause\n",$p,$linecnt,$token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    my $varvalue = &expand_macros($varexpr);

    my $doeval = ( ($isifexpr && &istrueExpr($varvalue)) || (!$isifexpr && !&istrueExpr($varvalue)) );

    printf STDERR "%s: varvalue=%d doeval=%d\n", $token, $varvalue, $doeval if ($DEBUG);

    return 1 unless ($doeval);     #we are done with this line.

    #otherwise, re-interpret the remainder of the line:
    ${$_line} = $if_clause;
    ${$_doeval} = 1;

    return 1;
}

sub whiledefspec
#true if we see an %whiledef statement.
#example:  %whiledef FOOVAR %UNDEF FOOVAR
{
    my ($line, $linecnt) = @_;

    return 0 unless ($line =~ /^\s*%whiledef\s+/);

    my ($token) = "%whiledef" ;

    #scan past %ifdef:
    $line =~ s/^\s*%whiledef\s+//;

    #get variable token
    my ($varname_in,$theStatement) = split(/\s+/, $line, 2);
    printf STDERR "%s: varname_in=%s theStatement=%s\n", $token, $varname_in, $theStatement if ($DEBUG);

    #if variable name is missing ...
    if (!defined($varname_in)) {
        printf STDERR "%s: ERROR: line %d: %s missing variable name\n",$p,$linecnt,$token;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #if DEFINITION expression missing ...
    if (!defined($theStatement)) {
        printf STDERR "%s: ERROR: line %d: %s missing statement clause\n",$p,$linecnt,$token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #if variable is a variable reference (e.g., $fooptr), then test valueof:
    my $varname = $varname_in;
    $varname = &expand_macros($varname_in) if ($varname_in =~ /\$/);

    if ($varname ne $varname_in && $varname =~ /\$/) {
        printf STDERR "%s: WARNING: line %d: variable reference '%s' in %s expression is INVALID - ignored.\n",
            $p, $linecnt, $varname_in, $token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        #we processed an %whiledef statement, even if there were errors::
        return 1;
    }

    #nothing to do if variable is undefined:
    return 1 unless (&var_defined($varname));

    #otherwise, write command to file and process the file until condition satisfied:
    my $tmpfile_fullpath = &write_string_to_cg_tmp_file($theStatement);
    if ($tmpfile_fullpath eq "NULL") {
        printf STDERR "%s[%s]: ERROR: line %d: cannot create temp file.\n",
            $p, $token, $linecnt unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        #we processed an %whiledef statement, even if there were errors::
        return 1;
    }

    my $cnt = 0;
    while (&var_defined($varname)) {
        ++$cnt;
        if (&interpret($tmpfile_fullpath) != 0) {
            printf STDERR "%s[%s]: ERROR: line %d: fail to interpret %s clause on %dth count.\n",
                $p, $token, $linecnt, $token, $cnt unless ($QUIET);
            ++ $GLOBAL_ERROR_COUNT;
            last;
        }
        $varname = &expand_macros($varname_in) if ($varname_in =~ /\$/);
    }

    unlink $tmpfile_fullpath;

    #we processed an %whiledef statement, even if there were errors::
    return 1;
}

sub whilespec
#true if we see an %while statement
#sets _do_eval to 1 if we are to evaluate modified _line
#i.e., if string or variable evaluates to "true, TRUE, 1", then interpret remainder.
#OTHERWISE, interpret as false.  By definition, any "non-true" expression is false.
{
    my ($line, $linecnt) = @_;

    return 0 unless ($line =~ /^\s*%while\s+/);

    my ($token) = "%while";

    $line =~ s/^\s*%while\s+//;

    #get variable token
    my ($varexpr, $theStatement) = split(/\s+/, $line, 2);
    printf STDERR "%s: varexpr=%s theStatement=%s\n", $token, $varexpr, $theStatement if ($DEBUG);

    #if variable name is missing ...
    if (!defined($varexpr)) {
        printf STDERR "%s: ERROR: line %d: %s missing variable expression\n",$p,$linecnt,$token;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #if statement clause missing ...
    if (!defined($theStatement)) {
        printf STDERR "%s: ERROR: line %d: %s missing statement clause\n",$p,$linecnt,$token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    my $varvalue = &expand_macros($varexpr);
    printf STDERR "%s: varvalue=%d\n", $token, $varvalue if ($DEBUG);

    #nothing to do if expression is false or variable undefined:
    return 1 unless (&istrueExpr($varvalue));

    #otherwise, write command to file and process the file until condition satisfied:
    my $tmpfile_fullpath = &write_string_to_cg_tmp_file($theStatement);
    if ($tmpfile_fullpath eq "NULL") {
        printf STDERR "%s[%s]: ERROR: line %d: cannot create temp file.\n",
            $p, $token, $linecnt unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        #we processed an %while statement, even if there were errors::
        return 1;
    }

    my $cnt = 0;
    while (&istrueExpr($varvalue)) {
        ++$cnt;
        if (&interpret($tmpfile_fullpath) != 0) {
            printf STDERR "%s[%s]: ERROR: line %d: fail to interpret %s clause on %dth count.\n",
                $p, $token, $linecnt, $token, $cnt unless ($QUIET);
            ++ $GLOBAL_ERROR_COUNT;
            last;
        }
        $varvalue = &expand_macros($varexpr);
    }

    unlink $tmpfile_fullpath;

    #we processed an %while statement, even if there were errors::
    return 1;
}

sub foreachspec
#true if we see an %foreach statement:
#  %foreach iterator_var range_var statement
#evaluate a statement with a range of values.
#Range variables can be a pointer to the variable
#name to use to provide the range.  The iterator
#variable is expected to be a simple variable name.
#
#added 6/24/06 - range variable can now be a pattern,
#enclosed in "/<pattern/".
{
    my ($line, $linecnt) = @_;

    return 0 unless ($line =~ /^\s*%foreach\s+/);

    my ($token) = "%foreach" ;

    #scan past %ifdef:
    $line =~ s/^\s*%foreach\s+//;

    #get variable token
    my ($itrname_in, $rgname_in, $theStatement) = split(/\s+/, $line, 3);
    printf STDERR "%s: itrname_in=%s rgname_in=%s theStatement=%s\n", $token, $itrname_in, $rgname_in, $theStatement if ($DEBUG);

    #if variable name is missing ...
    if (!defined($itrname_in)) {
        printf STDERR "%s: ERROR: line %d: %s missing iterator variable name\n",$p,$linecnt,$token;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #if variable name is missing ...
    if (!defined($rgname_in)) {
        printf STDERR "%s: ERROR: line %d: %s missing range variable name\n",$p,$linecnt,$token;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #if statement missing ...
    if (!defined($theStatement)) {
        printf STDERR "%s: ERROR: line %d: %s missing statement clause\n",$p,$linecnt,$token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #if iterator variable is a variable reference (e.g., $fooptr), then test valueof:
    my $itrname = $itrname_in;

    if ($itrname =~ /\$/) {
        printf STDERR "%s: WARNING: line %d: iterator variable '%s' is not a simple variable name - %s ignored.\n",
            $p, $linecnt, $itrname, $token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        #we processed an %foreach statement, even if there were errors::
        return 1;
    }

    #if range variable is a variable reference (e.g., $fooptr), then test valueof:
    my $rgname = $rgname_in;
    $rgname = &expand_macros($rgname_in) if ($rgname_in =~ /\$/);

    #if we couldn't expand the variable expression...
    if ($rgname ne $rgname_in && $rgname =~ /\$/) {
        printf STDERR "%s: WARNING: line %d: iterator variable reference '%s' in %s expression is INVALID - ignored.\n",
            $p, $linecnt, $rgname_in, $token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        #we processed an %foreach statement, even if there were errors::
        return 1;
    }

    #nothing to do if range variable is undefined:
    if (!&var_defined($rgname)) {
        printf STDERR "%s: WARNING: line %d: range variable reference undefined: ('%s'->'%s') - %s ignored.\n",
            $p, $linecnt, $rgname_in, $rgname, $token unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        #we processed an %foreach statement, even if there were errors::
        return 1;
    }

    #get the value of the range variable:
    my $rgvalue = &lookup_def($rgname);

    #if range value is a pattern...
    if ($rgvalue =~ /^\// && $rgvalue =~ /\/$/) {
        $GLOBAL_ERROR_COUNT
            += &exec_pattern_foreach($line, $linecnt, $token, $theStatement, $itrname, $rgname, $rgvalue);
    } else {
        $GLOBAL_ERROR_COUNT
            += &exec_numeric_foreach($line, $linecnt, $token, $theStatement, $itrname, $rgname, $rgvalue);
    }

    #we processed an %foreach statement, even if there were errors::
    return 1;
}

sub exec_pattern_foreach
#execute the /pattern/ form of %foreach.
#returns number of errors encountered.
{
    my ($line, $linecnt, $token, $theStatement, $itrname, $rgname, $vpattern) = @_;
    my $errcnt = 0;

    #eliminate / chars at beginning and end of pattern (pattern has already been checked):
    $vpattern = $1 if ( $vpattern =~ /^\/(.*)\/$/ );

    #generate list of  all vars matching pattern:
    my @matchvars = grep(/$vpattern/, sort keys %CG_USER_VARS);

    printf STDERR "%s %s %s->'%s': matchvars=(%s)\n", $token, $itrname, $rgname, $vpattern, join(",", @matchvars)
        if ($DEBUG);

    #return if no variables match:
    return $errcnt if ($#matchvars < 0);

    #otherwise, write command to file and process the file while iterator is in range:
    my $tmpfile_fullpath = &write_string_to_cg_tmp_file($theStatement);
    if ($tmpfile_fullpath eq "NULL") {
        printf STDERR "%s[%s]: ERROR: line %d: cannot create temp file.\n",
            $p, $token, $linecnt unless ($QUIET);

        return ++$errcnt;
    }

    #foreach value in range...
    my $ii;
    foreach $ii (@matchvars) {
        #set iterator variable to current value in range:
        $CG_USER_VARS{$itrname} = $ii;
        if (&interpret($tmpfile_fullpath) != 0) {
            printf STDERR "%s[%s]: ERROR: line %d: fail to interpret %s clause '%s' for value '%s' in /%s/.\n",
                $p, $token, $linecnt, $token, $theStatement, $ii, $vpattern unless ($QUIET);

            ++$errcnt;
            last;
        }
    }

    unlink $tmpfile_fullpath;

    return $errcnt;    #return 0 if no errors.
}

sub exec_numeric_foreach
#returns number of errors encountered.
{
    my ($line, $linecnt, $token, $theStatement, $itrname, $rgname, $rgvalue) = @_;
    my $errcnt = 0;

    my $rglb = &rangelb_op($rgvalue);
    my $rgub = &rangeub_op($rgvalue);
    if (!&is_integer($rglb) || !&is_integer($rglb)) {
        printf STDERR "%s: WARNING: line %d: range variable '%s'->'%s' contains non-integer value - %s ignored.\n",
            $p, $linecnt, $rgname, $rgvalue, $token unless ($QUIET);

        return ++$errcnt;
    }

    if ($DDEBUG) {
        printf STDERR "%s: itrname=%s rgname=%s var_defined(%s)=%d rgvalue='%s' rglb=%s rgub=%s\n",
            $token, $itrname, $rgname, $rgname, &var_defined($rgname), $rgvalue, $rglb, $rgub;
    }

    #otherwise, write command to file and process the file while iterator is in range:
    my $tmpfile_fullpath = &write_string_to_cg_tmp_file($theStatement);
    if ($tmpfile_fullpath eq "NULL") {
        printf STDERR "%s[%s]: ERROR: line %d: cannot create temp file.\n",
            $p, $token, $linecnt unless ($QUIET);

        return ++$errcnt;
    }

    #set padding to zero-fill if either var is zero-filled:
    my $padfmt = "%d";
    if ($rglb =~ /^0/ || $rgub =~ /^0/) {
        my $padlen = length("$rgub");
        $padlen = length("$rglb") if (length("$rglb") > $padlen);  #set pad length;
        $padfmt = "%0" . $padlen . "d";    #e.g., %02d
    }

    #foreach value in range...
    my $ii;
    for ($ii=0+$rglb; $ii<=$rgub; $ii++) {
        #set iterator variable to current value in range:
        $CG_USER_VARS{$itrname} = sprintf($padfmt, $ii);
        if (&interpret($tmpfile_fullpath) != 0) {
            printf STDERR "%s[%s]: ERROR: line %d: fail to interpret %s clause for value %d in {%s}.\n",
                $p, $token, $linecnt, $token, $ii, $rgvalue unless ($QUIET);

            ++$errcnt;
            last;
        }
    }

    unlink $tmpfile_fullpath;

    return $errcnt;    #return 0 if no errors.
}

sub istrueExpr
#return true if arg is one of:  {true, TRUE, 1}
{
    my ($boolstr) = @_;

    return 0 if ($boolstr eq "" || $boolstr eq "0" || &isUndefinedValue($boolstr));
    return 0 if ($boolstr =~ /^\s*[-+]?\s*\d+\s*$/ && $boolstr == 0);

    return 1;
}

sub definition
#true if we see a definition.  add definition to global hash.
# USAGE:  definition($line, \$linecnt, $use_stdin, $fhref, $infile)
{
    my ($line, $linecnt, $use_stdin, $fhref, $infile) = @_;

    #return early if this cannot be a definition:
    return 0 unless ($line =~  /=/);

    my ($is_raw)       = 0;
    my ($is_append)    = 0;
    my ($numop)        = 0;    #if detected, we set to ord(op), where op is +,0,/,*, etc.

#printf STDERR "\ndefinition:  line='%s'\n", $line;

    my ($lhs,$rhs);
    if ($line =~ /^\s*([^\s\.=:]*)\s*\.:=\s*(.*)$/) {
        $lhs = $1; $rhs = $2;
        $is_raw = $is_append = 1;
#printf STDERR "T1 line='%s' lhs='%s' rhs='%s'\n", $line, $lhs, $rhs;
    } elsif ($line =~ /^\s*([^\*\s]*)\s*\*\*=\s*(.*)$/) {
        $lhs = $1; $numop = ord('e'); $rhs = $2;  # 'e' for exponent
#printf STDERR "T2 lhs='%s' rhs='%s' numop=%d(%s)\n", $lhs, $rhs, $numop, chr($numop);
    } elsif ( ($line =~ /^\s*([a-zA-Z_0-9\${}:]+)\s*([:\.\/\*\+\-\%\&\|\^])=\s*(.*)$/) ||
              ($line =~ /^\s*([a-zA-Z_0-9\${}:]+)\s+(x)=\s*(.*)$/) ) {
        #note second case:  x= requires a space in front to disambiguate "xx=rhs" from "x x=rhs"
        $lhs = $1; $numop = ord($2); $rhs = $3;
        if ($numop == ord('.')) {
            $is_append = 1; $numop=0;
        } elsif ($numop == ord(':')) {
            $is_raw = 1;  $numop=0;
        } else {
            $numop = $numop;    #we have a valid numeric op (+=, etc)
        }
#printf STDERR "T3 lhs='%s' rhs='%s' numop=%d(%s)\n", $lhs, $rhs, $numop, chr($numop);
    } elsif ($line =~ /^\s*([^=\s]*)\s*=\s*(.*)$/) {
        $lhs = $1; $rhs = $2;
#printf STDERR "T4 lhs='%s' rhs='%s'\n", $lhs, $rhs;
    } else {
#printf STDERR "T5\n";
        return 0;
    }

#printf STDERR "T6 lhs='%s'numop=%d  rhs='%s'\n", $lhs, $numop, $rhs;

    my (@tmp, $xx, $eoi_tok);

    #if we have a here-now doc...
    if ($rhs =~ /<</) {
        @tmp = split('<<', $rhs);
        if ($#tmp >= 0) {
            $xx = $tmp[$#tmp];
            $xx =~ s/\s//g;    #remove any white-space in eoi-tok
            $eoi_tok = $xx;
            $rhs = "";   #clear rhs
        } else {
            printf STDERR "%s: ERROR: run-away here-now string starting on line %d!\n", $p, $$linecnt;
            ++ $GLOBAL_ERROR_COUNT;
            return 1;
        }

        $line = $use_stdin? <STDIN> : <$fhref>;   #get next line
        $rhs = "\n" if ($pragma_preserve_multiline_lnewline && defined($line)); #preserve left newline
        while (defined($line)) {
            ++${$linecnt}; chomp $line; ++$LINE_CNT; ++$$LINE_CNT_REF;
#printf STDERR "%s << %s line[%d] (%s)='%s'\n", $lhs, $eoi_tok, $$linecnt, $infile, $line;
            printf STDERR "<< %s line[%d] (%s)='%s'\n", $eoi_tok, $$linecnt, $infile, $line if ($DDEBUG);

            if ($line eq $eoi_tok) {
                #then close up this definition:
                chomp $rhs if ($pragma_trim_multiline_rnewline); #trim final newline if requested
                last;   #DONE
            } else {
                $rhs .= "$line\n";    #put the newline back
                $line = $use_stdin? <STDIN> : <$fhref>;   #get next line
            }
        }
    }

    #note - add_definition() does variable expansion:
    return &add_definition($lhs, $rhs, $$linecnt, $is_raw, $is_append, $numop);
}

sub add_definition
#add a definition to the global hash.
#return true (1) if okay.
{
    my ($lhs_in, $rhs, $linecnt, $israw, $isappend, $numop) = @_;

    #if lhs_in is a variable reference (e.g., $fooptr), then assign to valueof:
    my $lhs = $lhs_in;
    $lhs = &expand_macros($lhs_in) if ($lhs_in =~ /\$/);

    if ($lhs ne $lhs_in && $lhs =~ /\$/) {
        printf STDERR "%s: WARNING: line %d: variable reference '%s' on left-hand side of assignment is INVALID - ignored.\n",
            $p, $linecnt, $lhs_in unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        #we processed a definition statement, even if there were errors::
        return 1;
    }

    printf STDERR "add_definition: lhs_in='%s' lhs='%s' rhs='%s' israw='%d' isappend='%d'\n", $lhs_in, $lhs, $rhs, $israw, $isappend if ($DEBUG);

    #if := assignment...
    if ($israw) {
        if ($isappend) {
            $CG_USER_VARS{$lhs} .= $rhs;
        } else {
            $CG_USER_VARS{$lhs} = $rhs;
        }
        return 1;
    }

    my @spfexpr = &strtospf($rhs);

    if ($lhs eq 'CG_TEMPLATES') {
        printf STDERR "%s: WARNING: line %d: use of CG_TEMPLATES deprecated, resetting CG_TEMPLATE_PATH instead.\n", $p, $linecnt unless ($QUIET);
        $lhs = 'CG_TEMPLATE_PATH';
    }

    if ($isappend) {
        $CG_USER_VARS{$lhs} .= &eval_spf_expr(@spfexpr);
    } elsif ($numop != 0) {
        if    ($numop == ord('+')) { $CG_USER_VARS{$lhs} += &eval_spf_expr(@spfexpr); }
        elsif ($numop == ord('-')) { $CG_USER_VARS{$lhs} -= &eval_spf_expr(@spfexpr); }
        elsif ($numop == ord('*')) { $CG_USER_VARS{$lhs} *= &eval_spf_expr(@spfexpr); }
        elsif ($numop == ord('/')) { $CG_USER_VARS{$lhs} /= &eval_spf_expr(@spfexpr); }
        elsif ($numop == ord('%')) { $CG_USER_VARS{$lhs} %= &eval_spf_expr(@spfexpr); }
        elsif ($numop == ord('|')) { $CG_USER_VARS{$lhs} |= &eval_spf_expr(@spfexpr); }
        elsif ($numop == ord('&')) { $CG_USER_VARS{$lhs} &= &eval_spf_expr(@spfexpr); }
        elsif ($numop == ord('^')) { $CG_USER_VARS{$lhs} ^= &eval_spf_expr(@spfexpr); }
        elsif ($numop == ord('x')) { $CG_USER_VARS{$lhs} x= &eval_spf_expr(@spfexpr); }
        #'e' for exponent
        elsif ($numop == ord('e')) { $CG_USER_VARS{$lhs} **= &eval_spf_expr(@spfexpr); }
        else {
            printf STDERR "%s: ERROR: line %d: unrecognized assignment operator: '%s='\n",
                $p, $linecnt, chr($numop) unless ($QUIET);
        }
    } else {
        $CG_USER_VARS{$lhs} = &eval_spf_expr(@spfexpr);
    }
    return 1;
}

sub get_user_vars
#return the list of defined user variable names
{
    return (sort keys %CG_USER_VARS);
}

sub expand_macros
# INPUT:  string with variable references
# OUTPUT:  string with substitued variable values
{
    my ($str) = (@_);

    my @spfexpr = &strtospf($str);

    return &eval_spf_expr(@spfexpr);
}

sub eval_spf_expr
#INPUT:  sprintf list:  (fmt, var*)
#OUTPUT:  string containing sprintf(fmt, lookup(var)*)
{
    my ($fmt, @varlist) = @_;
    my $evalstr = "";
    my @ops = ();

    printf STDERR "eval_spf_expr:  input=(%s)\n", join(',', $fmt, @varlist) if ($DEBUG);

    if ($#varlist < 0) {
        $evalstr = sprintf($fmt);
    } else {
        #otherwise, look up variable defs:
        my $ii;
        for ($ii=0; $ii<=$#varlist; $ii++) {
            my $varname = $varlist[$ii];
            @ops = ();

            if ($varname =~ /:/) {
                @ops = split(':', $varname);
                $varname = shift @ops;
            }

            my $varvalue = &lookup_def($varname);   #get value of var
            if ($#ops >= 0) {
                #apply operations to the variable, in order listed:
                my $op;
                for (@ops) {
                    $op = $_;
                    $varvalue = &eval_postfix_op($op, $varvalue, $varname, $LINE_CNT);

                    #we used to exit early if we had an undef op.
                    #I'm reversing this decision because if a subsequent op can
                    #operate on the undef value (see :pragmavalue op) then we need
                    #to allow it to.  RT 12/10/08
                    #last if ($op eq "undef");
                }
            }
            $varlist[$ii] = $varvalue;
        }
        $evalstr = sprintf($fmt, @varlist);
    }

    printf STDERR "eval_spf_expr:  output='%s'\n", $evalstr if ($DEBUG);

    return $evalstr;
}


sub lookup_def
#INPUT:   variable name
#output:  variable value or the string "${varname:undef}" (if undefined)
#IMPORTANT:  this routine defines the precedence of variable names:
#  1. local file specification line ($CG_CLASSNAME, $CG_PACKAGE_NAME, etc)
#  2. variables defined in the specification file
#  3. environment variables, if allowed
#WARNING:  if you change this routine, you may also need to change var_defined()
#WARNING:  if you change this routine, you may also need to change undef_op()
{
    my ($varname) = @_;
    my $undefvalue = &undefname($varname);
    my $varval = $undefvalue;

    return $undefvalue unless (defined($varname));

    if ( defined($CLASS_VARS{$varname}) ) {
        $varval = $CLASS_VARS{$varname};
    } elsif (!defined($CG_USER_VARS{$varname}) && $pragma_clrifndef == 1) {
        #clear undefined variables if %pragma clrifndef 1
        $varval = "";
        $CG_USER_VARS{$varname} = $varval;
    } elsif (defined($CG_USER_VARS{$varname})) {
        $varval = $CG_USER_VARS{$varname};
        #if value of variable is undefined, then garbage collect variable:
        delete $CG_USER_VARS{$varname} if (&isUndefinedVarnameValue($varname, $varval));
    } elsif ($ENV_VARS_OKAY && defined($ENV{$varname})) {
        $varval = $ENV{$varname};
    }

    printf STDERR "lookup_def:  in='%s' out='%s'\n", $varname, $varval if ($DEBUG);

    return $varval;
}

sub var_defined_non_empty
#return 1 if a cado variable is defined and is not empty
{
    my ($varname) = @_;
    my $varval = &lookup_def($varname);

    return ( !&isUndefinedVarnameValue($varname, $varval) && ($varval ne "") );
}

sub var_defined
#return 1 if a cado variable is defined
{
    my ($varname) = @_;
    my $varval = &lookup_def($varname);

#printf STDERR "var_defined:  isUndefinedVarnameValue(%s, %s)=%d\n", $varname, $varval, isUndefinedVarnameValue($varname, $varval);
    return !&isUndefinedVarnameValue($varname, $varval);
}

sub var_defined_strict
#return 1 if a cado variable is defined in the strict sense.
#this means the variable does not contain the undefined value of another variable.
#used only in %ifdef statement
{
    my ($varname) = @_;
    my $varval = &lookup_def($varname);

    return (!&isUndefinedVarnameValue($varname, $varval) && !&isUndefinedValue($varval));
}

sub isUndefinedVarnameValue
#true if variable is undefined or has the undefined value
{
    my ($varname, $varval) = @_;

    return 1 if ( !defined($varname) || !defined($varval) || $varval eq &nullundefname() || $varval eq &undefname($varname) );
    return 0;
}

sub isUndefinedValue
#return true if argument is an undefined variable pattern,
{
    my ($varval) = @_;
    return 1 if (!defined($varval) || $varval =~ /^\${[a-zA-Z_][a-zA-Z_0-9]*:undef}$/);
    return 0;
}

sub undefname
#return the unique name for an undefined variable.
{
    my ($varname) = @_;

    return &nullundefname() unless (defined($varname));

    return sprintf('${%s:undef}', $varname);
}

sub nullundefname
#return the unique name for an undefined variable.
{
    return '${null:undef}';
}

sub find_template
#INPUT:   template filename, relative to a template root in CG_TEMPLATE_PATH
#OUTPUT:  full path name of template or input is unmodified.
{
    my ($template) = @_;
    my ($result) = $template;

    #get current template path:
    my (@templatepath) = split(';', $CG_USER_VARS{'CG_TEMPLATE_PATH'});

    my $tdir;
    foreach $tdir (@templatepath) {
        my $tmpfn = &path::mkpathname($tdir, $template);
        if (-r $tmpfn) {
            $result = $tmpfn ;
            last;
        }
    }

    printf STDERR "find_template: input='%s' output='%s'\n", $template, $result if ($DEBUG);

    return $result;
}

sub gen_sourcefile
#INPUT:   FILE_VARS hash, which contains spec for generating a source file
#OUTPUT:  a file generated from input template in output location.
#RETURNS:  zero if no errors, otherwise error count.
{
    my ($fvar_ref, $line, $linecnt, $is_append, $is_symlink, $cgroot) = @_;

    #this is the file handle where we send file generation messages:
    my $msgfh = \*STDERR;
    $msgfh = \*STDOUT if ($pragma_filegen_notices_to_stdout);    #we want messages on stdout

    #fetch generation context variables:
    my ($dirname) = ${$fvar_ref}{'CG_DIRNAME'};
    my ($filename) = ${$fvar_ref}{'CG_FILENAME'};
    my ($template) = ${$fvar_ref}{'CG_TEMPLATE'};
    my ($linkto) = "NULL";
    my ($errcnt) = 0;
    my ($intemplate) = "";

#printf STDERR "gen_sourcefile: cgroot='%s', dirname='%s' filename='%s' template='%s'\n", $cgroot, $dirname, $filename, $template;

    if ($is_symlink) {
        #template is just the contents of the link we are going to create:
        $linkto = $template;
    } else {
        #exit early if we can't read in the template

        $intemplate = &find_template($template);
        if (! -r $intemplate) {
            printf STDERR "%s [gen_sourcefile]: ERROR line %d: can't open template file, '%s' (%s)\n", $p, $linecnt, $template, $!;
            printf STDERR "\tCG_TEMPLATE_PATH='%s'\n", $CG_USER_VARS{'CG_TEMPLATE_PATH'};
            ++ $GLOBAL_ERROR_COUNT;
            return 1;
        }
    }

    #install output dir:
    my ($outdir) = &path::mkpathname($cgroot, $dirname);

#printf STDERR "gen_sourcefile: mkpathname('%s','%s')='%s'\n", $cgroot, $dirname, &path::mkpathname($cgroot, $dirname);

    &os::createdir($outdir, 0775) if (! -d $outdir);
    if (!-d $outdir) {
        printf STDERR "%s [gen_sourcefile] line %d: can't create output dir, '%s' (%s)\n", $p, $linecnt, $outdir, $!;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    my ($outfile) = &path::mkpathname($outdir, $filename);
    my ($original_outfile) = "NULL";
    my ($original_crc) = 0;

#printf STDERR "gen_sourcefile: outfile='%s'is_append=%d is_symlink=%d\n", $outfile, $is_append, $is_symlink;

    #if output file already exists, then only re-write if $FORCE_GEN or $UPDATE and different...
    if (-l $outfile || -e $outfile) {
#printf STDERR "gen_sourcefile: OUTFILE EXISTS\n";
        if ($is_append) {
            #okay if file exists - do nothing.
            ;
        } elsif ($FORCE_GEN) {
            if (&os::rmFile($outfile) != 0) {
                printf STDERR "%s: ERROR: overwriting output file '%s' (%s)\n", $p, $outfile, $!;
                ++ $GLOBAL_ERROR_COUNT;
                return 1;
            }
        } elsif ($UPDATE) {
            if ($is_symlink) {
#printf STDERR "gen_sourcefile: UPDATE->IS_SYMLINK\n";
                #if outfile is a symlink, then read its contents and compare to $linkto:
                if ( -l $outfile ) {
                    my $linkcontents = "";
                    if ( defined($linkcontents = readlink($outfile)) ) {
#printf STDERR "gen_sourcefile: linkcontents='%s' linkto='%s'\n", $linkcontents, $linkto;
                        if ( $linkcontents eq $linkto ) {
                            #then we are done.
                            printf $msgfh "%s <- %s -> update -> link contents unchanged.\n", $template, $original_outfile if ($VERBOSE);
                            return 0;  #success
                        } else {
                            #remove it - it is different from our link-to file:
                            if (&os::rmFile($outfile) != 0) {
                                printf STDERR "%s: ERROR: cannot remove symlink '%s' (%s)\n", $p, $outfile, $!;
                                ++ $GLOBAL_ERROR_COUNT;
                                return 1;
                            }
                        }
                    } else {
                        #file is symlink but there was an error reading the contents:
                        printf STDERR "%s [gen_sourcefile]: ERROR: cannot read contents of symlink '%s': check type & permissions.\n", $p, $outfile, $!;
                        ++ $GLOBAL_ERROR_COUNT;
                        return 1;
                    }
                } else {
                    #file exists but is not a symlink. remove it:
                    if (&os::rmFile($outfile) != 0) {
                        printf STDERR "%s: ERROR: cannot remove output file '%s' (%s)\n", $p, $outfile, $!;
                        ++ $GLOBAL_ERROR_COUNT;
                        return 1;
                    }

                    #o'wise we removed the file.  create the symlink below.
                }
            } else {
                #generating plain file.
                if (-f $outfile && -r $outfile) {
                    #get the crc of the old file, and write to a different file
                    $original_outfile = $outfile;
                    $original_crc =  &pcrc::CalculateFileCRC($original_outfile);

                    #create a temporary file in the same dir and write to that:
                    $outfile =  &path::mkpathname($outdir, sprintf("%d_%s", $$, $filename));
                } elsif ( -l $outfile ) {
                    #we are replacing a previously genrated symlink with a regular file - remove it:
                    if (&os::rmFile($outfile) != 0) {
                        printf STDERR "%s: ERROR: overwriting output file '%s' (%s)\n", $p, $outfile, $!;
                        ++ $GLOBAL_ERROR_COUNT;
                        return 1;
                    }
                } else {
                    #file exists but is not a plain file or a symlink, or we cannot read it
                    printf STDERR "%s [gen_sourcefile]: ERROR: cannot open output file '%s': check type & permissions.\n", $p, $outfile, $!;
                    ++ $GLOBAL_ERROR_COUNT;
                    return 1;
                }
            }
        } else {
            printf STDERR "%s: INFO: not overwriting output file '%s'\n", $p, $outfile if ($VERBOSE);
            return 0;
        }
    }

    if ($is_symlink) {
        #NOTE:  symlink("foo", "blah") creates:  blah@ -> foo
        #we want:  filespec@ -> linkto.

        #DO IT (this should be inside an eval in case we are on windows!):
        eval { symlink($linkto, $outfile); };

        #did we create the link?
        if ( -l $outfile ) {
            printf $msgfh "%s <- %s\n", $linkto, $outfile unless ($QUIET);
            #note - do not call setmode - does not work on symlinks.
            #$errcnt += &setmode($outfile);
        } else {
            printf STDERR "%s [gen_sourcefile]: ERROR: failed to create symlink '%s' - [%s].\n", $p, $outfile, $!;
            ++ $errcnt;
        }

        ++ $GLOBAL_ERROR_COUNT if ($errcnt > 0);
        return $errcnt;
    }

    if ($is_append) {
#printf STDERR "gen_sourcefile: OPENING FOR APPEND\n";
        if (!open(OUTFILE, ">>$outfile")) {
            printf STDERR "%s [gen_sourcefile]: ERROR: cannot open output file '%s' for append (%s).\n", $p, $outfile, $!;
            ++ $GLOBAL_ERROR_COUNT;
            return 1;
        }
    } elsif (!open(OUTFILE, ">$outfile")) {
        printf STDERR "%s [gen_sourcefile]: ERROR: cannot open output file '%s' for writing (%s).\n", $p, $outfile, $!;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    #we are ready to expand the template into the ouput file:

    $errcnt = &expand_template(\*OUTFILE, $intemplate);
    close OUTFILE;

    #if we are appending...
    if ($is_append) {
        #normally we suppress append messages, since we are usually generating to temp files:
        printf STDERR "%s ->> %s\n", $template, $outfile if ($VERBOSE);
        $errcnt += &setmode($outfile);
    } elsif ($UPDATE && $original_outfile ne "NULL") {
        #if we are updating an existing file ...
        #get the crc of the new file:
        my ($new_crc) =  &pcrc::CalculateFileCRC($outfile);

        #if files are the same...
        if ($original_crc == $new_crc) {
            #...then just remove the temp file:
            if (&os::rmFile($outfile) != 0) {
                printf STDERR "%s [gen_sourcefile]: ERROR: cannot remove temp file '%s' (%s)\n", $p, $outfile, $!;
                ++$errcnt;
            } 
            printf $msgfh "%s -> %s -> update -> dest same as source.\n", $template, $original_outfile if ($VERBOSE);
        } else {
            #move the temp file to the original:
            if (&os::rename($outfile, $original_outfile) != 0) {
                printf STDERR "%s [gen_sourcefile]: ERROR: cannot replace '%s' with temp file '%s' (%s)\n", $p, $original_outfile, $outfile, $!;
                ++$errcnt;
            } else {
                printf $msgfh "%s -> %s\n", $template, $original_outfile unless ($QUIET);
                $errcnt += &setmode($original_outfile);
            }
        }
    } else {
        printf $msgfh "%s -> %s\n", $template, $outfile unless ($QUIET);
        $errcnt += &setmode($outfile);
    }

    ++ $GLOBAL_ERROR_COUNT if ($errcnt > 0);
    return $errcnt;
}

sub setmode
#set the mode on <fn>.
#return 0 if successful, o'wise display error and return 1;
{
    my ($fn) = @_;
    my $mode = oct($CG_USER_VARS{'CG_MODE'});

    return 0 if (chmod($mode, $fn) == 1);  #success

    #otherwise, failed:
    printf STDERR "%s [setmode]: ERROR: cannot set mode of '%s' to '0%o' (%s).\n", $p, $fn, $mode, $!;
    ++ $GLOBAL_ERROR_COUNT;

    return 1;
}

sub expand_string_template
#this routine takes a string, expands template macros, and returns the
#resultant string.
{
    my($inputStr) = @_;
    my($token) = "expand_string_template";

    #this is an optimization - avoid macro processing if no macros:
    return $inputStr if ( $inputStr eq "" || ($inputStr !~ /{=/ && $inputStr !~ /=}/) );

    #get a tempfile names:
    my $tmpfile = sprintf("_cg_%s_in.%d", $token, $$);
    my $tmpfile_fullpath = &get_cg_tmpfile_name($tmpfile);
    unlink $tmpfile_fullpath;

    #get another temp file name for output:
    my $tmpfileB = sprintf("_cg_%s_out.%d", $token, $$);
    my $tmpfileB_fullpath = &get_cg_tmpfile_name($tmpfileB);
    unlink $tmpfileB_fullpath;

    #open outfile, as expand_template expects a file-ref:
    my ($fhidx) = &get_avaliable_filehandle($token);

    if ($fhidx < 0) {
        printf STDERR "%s [%s]: ERROR: out of file descriptors for nested templates (max is %d).\n", $p, $token, $LAST_TEMPLATE_FD_KEY+1;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    my ($outfile_ref) = $TEMPLATE_FD_REFS[$fhidx];
    if (!open($outfile_ref, ">$tmpfileB_fullpath")) {
        printf STDERR "%s [%s]: ERROR: cannot open file '%s' (%s)\n", $p, $token, $tmpfileB_fullpath, $!;
        ++ $GLOBAL_ERROR_COUNT;
        &free_filehandle($fhidx, $token);   #free our allocated filehandle
        return 1;
    }

    #write input string to tmp file:
    if ( &os::write_str2file(\$inputStr, $tmpfile_fullpath) != 0) {
        printf STDERR "%s[%s]: ERROR: FAILED to write macro to file '%s': %s\n",
            $p, $token, $tmpfile_fullpath, $! unless($QUIET);
        ++ $GLOBAL_ERROR_COUNT;

        #clean up transaction:
        close($outfile_ref);
        unlink $tmpfile_fullpath, $tmpfileB_fullpath;
        &free_filehandle($fhidx, $token);   #free our allocated filehandle

        return $inputStr;    #return input string
    }


    #######
    #expand template into output file:
    #######
    &expand_template($outfile_ref, $tmpfile_fullpath);

    #close file so we can re-read it:
    close($outfile_ref);
    &free_filehandle($fhidx, $token);   #free our allocated filehandle

    #read string from outfile and return it:
    my $outputStr = "";
    if (&os::read_file2str(\$outputStr, $tmpfileB_fullpath) != 0) {
        printf STDERR "%s[%s]: ERROR: FAILED to read file '%s': %s\n",
            $p, $token, $tmpfileB_fullpath, $! unless($QUIET);
        ++ $GLOBAL_ERROR_COUNT;

        unlink $tmpfile_fullpath, $tmpfileB_fullpath;
        return $inputStr;    #return input string
    }

    printf STDERR "%s: inputStr=\n'%s'\noutputStr=\n'%s'\n", $token, $inputStr, $outputStr if ($DEBUG);

    unlink $tmpfile_fullpath, $tmpfileB_fullpath;

    return $outputStr;    #success!
}

sub expand_template
#INPUT:  template file, name of output file.  can be called recursively
#OUTPUT: expanded template written to <outfile>
#RETURNS:  zero on success, or non-zero if errors
{
    my ($outfile_ref, $template) = @_;
    my ($fhidx) = &get_avaliable_filehandle("expand_template");

    if ($fhidx < 0) {
        printf STDERR "%s [expand_template]: ERROR: out of file descriptors for nested templates (max is %d).\n", $p, $LAST_TEMPLATE_FD_KEY+1;
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    my ($tplfd_ref) = $TEMPLATE_FD_REFS[$fhidx];
    if (!open($tplfd_ref, $template)) {
        printf STDERR "%s [expand_template]: ERROR: cannot open template file '%s' (%s)\n", $p, $template, $!;
        ++ $GLOBAL_ERROR_COUNT;
        &free_filehandle($fhidx, "expand_template");   #free our allocated filehandle
        return 1;
    }

    #are we using cado to copy binary files?
    if ( $pragma_copy || !(-T $template) ) {
        #we are writing a binary file:
        binmode $tplfd_ref;
        binmode $outfile_ref;

        #########
        # WARNING:  certain versions of perl have a bug that shows up mainly on linux when using PERLIO
        # to copy files (which is faster that stdio).  I've only ever seen this with larger binary files.
        # Work-around is "setenv PERLIO stdio".  I added an minstall processor ( & noperlio) to implement
        # this in the shell start-up line.  Perl 5.8.8 on redhat 5.3 has this issue, and I've seen it before.
        #
        # See the following Bug reports:
        #    http://rt.perl.org/rt3//Public/Bug/Display.html?id=39060
        #    https://bugzilla.redhat.com/show_bug.cgi?id=221113
        #    useful google search:  "perl 5.8.8 linux Bad file descriptor errors"
        #
        # RT 3/16/10
        #########

        my $buf = "";
        my $BUFSIZE = 1024*8;
        while (read($tplfd_ref, $buf, $BUFSIZE)) {
            print $outfile_ref $buf;
            if ($! != 0) {
                #IMPORTANT!! must check for write errors!!
                printf STDERR "%s [expand_template]: ERROR during binary copy of '%s' (%s)\n", $p, $template, $!;
                ++ $GLOBAL_ERROR_COUNT;
                last;
            }
        }
    } else {
        #we have a text file - copy and do macro substitutions:
        my $tpline  = "";
        while ($tpline = <$tplfd_ref>) {
            my $hadnl = chomp $tpline;
            #expand the template macro.  This macro will print to the outfile:
            &expand_template_macro($outfile_ref, $tpline, $hadnl);
        }
    }

    close $tplfd_ref;
    &free_filehandle($fhidx, "expand_template");   #free filehandle

    return 0;
}

sub expand_template_macro
#INPUT:    a line from template
#OUTPUT:   prints results to supplied filehandle.
#RETURNS:  0 if success, otherwise error count
{
    my ($outfile_ref, $tpline, $hadnl) = @_;

    #eliminate comments:
    #TODO:  template comments need to be bracketed by {=%# a comment=} or something.
    #return 0 if (&comment($tpline));

    #this is an optimization - avoid macro processing if no macros:
    if ($tpline !~ /{=.*=}/) {
        print $outfile_ref $tpline . ($hadnl ? "\n" : ""); 
        return 0;
    }

    #if the input line *only* contains a macro def, then save this info
    #so later we will not output an empty line if the macro expands to empty string.
    #note use of non-greedy op:  .*?
    my $line_is_macro_only = ($tpline =~ /^{=.*?=}$/)? 1 : 0;

    my @spfexpr = &tpl_strtospf($tpline);

    return &eval_template_expr($outfile_ref, \@spfexpr, $line_is_macro_only, $hadnl);
}

sub eval_template_expr
#INPUT:    sprintf list:  (fmt, template_macro*)
#OUTPUT:   string containing sprintf(fmt, exec(template_macro)*)
#RETURNS:  0 if success, otherwise error count
{
    my ($outfile_ref, $mlist_ref, $line_is_macro_only, $hadnl) = @_;
    my ($errcnt) = 0;
    my (@macrolist) = @{$mlist_ref};
    my ($fmt) = shift @macrolist;

    printf STDERR "eval_template_expr:  fmt='%s' macrolist=(%s)\n", $fmt, join(',', @macrolist) if ($DEBUG);

    #if no macros...
    if ($#macrolist < 0) {
        $fmt =~ s/#%#s#/%s/g;  #revert to original %s sequences if any
        print $outfile_ref sprintf($fmt) . ($hadnl ? "\n" : ""); 
        return 0;
    }

    #use strlist to control the output.  We must have one macro after each
    #strlist element, e.g. str0, macro0, str1, macro1, etc.

    my (@strlist) = split('%s', $fmt, -1);  #note:  -1 gets us all fields, including null.

    my $txt = "";      #tmp var to track of what we write below:
    my $outtxt = "";   #contents of any macro expansion we write to ouput file.
    my ($ii, $macro);

    for ($ii=0; $ii <= $#strlist; ++$ii) {

        printf STDERR "eval_template_expr LOOP:  strlist[%d]='%s'\n", $ii, $strlist[$ii] if ($DEBUG);

        $txt = $strlist[$ii];

        my $origtxt = $txt;
        $origtxt =~ s/#%#s#/%s/g;  #revert to original %s sequences if any

        print $outfile_ref $origtxt;
        $outtxt .=  $origtxt;  #keep track of what we have printed so far.

        next if ($ii == $#strlist);     #no macro for last element

        printf STDERR "eval_template_expr LOOP:  macrolist[%d]='%s'\n", $ii, $macrolist[$ii] if ($DEBUG);
        $macro = $macrolist[$ii];

        #back-tick expression is syntactic sugar for %exec:
        if ($macro =~ /^`/) {
            $macro =~ s/`(.*)`/%exec $1/;
        }
        
        if ($macro =~ /^#/) {
            #ignore comments
            $txt = "";
        } elsif ($macro =~ /^%/) {
            $errcnt += &exec_macro($outfile_ref, $macro);   #member with results of execution
            $txt = "";    #we assume that whatever operator we called takes care of it's own newline.
        } elsif ($macro =~ /\$/) {
            #we have a variable expression:
            my @spfexpr = &strtospf($macro);
            $txt = &eval_spf_expr(@spfexpr);
            print $outfile_ref $txt;
            #TODO:  check for errors
        } elsif ($macro =~ /^[a-zA-Z_0-9]+$/) {
            #we have a simple variable - look it up and return it:
            $txt = &lookup_def($macro);
            print $outfile_ref $txt;   #replace var with its value
            #TODO:  check for errors
        } else {
            #we don't know what we have, so just rewrap it in macro brackets:
            $txt = "{=" . $macro . "=}";
            print $outfile_ref $txt;
            ++$errcnt;
        }

        $outtxt .=  $txt;  #keep track of what we have output.
    }

    #this macro lists represents a single template input line, so output a newline,
    #unless the macro is alone on the line AND EXPANSION IS EMPTY:
    print $outfile_ref "\n" unless ( ($line_is_macro_only && $outtxt eq "") || $hadnl == 0 );

    return $errcnt;
}

sub exec_macro
#INPUT:  a "%<token> args.." macro expression
#OUTPUT:  (string) the output from the macro subroutine.
#EXAMPLE:  %include $somevar/somefile.txt
#ERRORS:  generate re-bracket'ed macro string if we detect.
#RETURNS:  0 if okay, otherwise error count.
{
    my ($outfile_ref, $macro) = @_;

    printf STDERR "exec_macro: macro='%s'\n", $macro if ($DEBUG);

    return $macro if ($macro !~ /^%/);

    my ($macro_name, $macro_args) = split(/\s+/, $macro, 2);
    $macro_name =~ s/^%//;

    #look up the macro name in our table of function refereces:
    my ($macro_ref) = $MACRO_FUNCTIONS{$macro_name};

    if (!defined($macro_ref)) {
        printf STDERR "%s [exec_macro]: sorry, macro '%s' has not been implemented\n", $p, $macro_name;
        print $outfile_ref sprintf("{=%s=}", $macro);
        ++ $GLOBAL_ERROR_COUNT;
        return 1;
    }

    return( &{$macro_ref}($outfile_ref, $macro_args) );
}

sub tpl_strtospf
#this routine is exactly the same as strtospf, except that it
#extracts template operators, which are enclosed in '{=', '=}' pairs.
#example:
#    INPUT:  "astring{=FOOVAR=}; {=%include ${CG_CLASSNAME}_imports.jtpl=}"
#    OUTPUT:  ("astring%s; %s", 'FOOVAR', '%include ${CG_CLASSNAME}_imports.jtpl')
{
    my ($str) = @_;
    my (@spf) = ();
    my ($matchpat) = $; . '([^' . $; . ']*)' . $; ;

    #return early if nothing to process:
    if ($str !~ /{=.*=}/) {
        push @spf, $str;
        return(@spf) 
    }

    #otherwise, create the format string and varible list.

    #first, replace any "%s" sequences in input with #%#s#, since later we will split on %s:
    $str =~ s/%s/#%#s#/g;

    #next, replace {= and =} with $; (standard non-printing perl list separator):
    $str =~ s/{=/$;/g;
    $str =~ s/=}/$;/g;

    #replace the contents between $; and $; with %s:
    my $fmt = $str;
    $fmt =~ s/$matchpat/\%s/g;
    push @spf, $fmt;

    #next, get the var list using the match operator, which
    #returns a list of matched expressions:
    push @spf, ($str =~ m/$matchpat/g);

    printf STDERR "tpl_strtospf:  fmt='%s', full spf=(%s)\n", $fmt, join(',', @spf) if ($DEBUG);

    return(@spf);
}

sub strtospf
#this routine returns a list which can be evaluated and then passed to sprintf.
#the list is of the form:  (format_specifier identifier* )
#example:
#    INPUT:  "astring$avar.${bvar}blah$another"
#    OUTPUT:  ("astring%s.%sblah%s", 'avar', 'bvar', 'another')
#If the list returned only has one item then we didn't find any variable references.
{
    my ($str) = @_;
    my (@spf) = ();

    #first, preserve % in input:
    $str =~ s/%/%%/g;

    #return early if nothing to process:
    if ($str !~ /\$/) {
        push @spf, $str;
        return(@spf) 
    }

    #otherwise, create the format string and varible list:

    #first, replace $var and ${var} refs with '%s':
    my $fmt = $str;
    $fmt =~ s/\${?[a-zA-Z_][:a-zA-Z_0-9]*}?/\%s/g;
    push @spf, $fmt;

    #next, get the var list using the match operator, which
    #returns a list of matched expressions:
    #Q:  is there a way to avoid generating match elements with nested ()'s?
    #    if so, we can make this match more precise.  RT 9/27/04
    my @args = ($str =~ /\${?([a-zA-Z_][:a-zA-Z_0-9]*)}?/g);
    push @spf, @args;

    printf STDERR "strtospf:  fmt='%s', args=(%s)\n", $fmt, join('|', @args) if ($DEBUG);

    return(@spf);
}

################################# MACRO FUNCTIONS ################################

sub cg_include
#this is the include-file processing macro.
#note that the include file can also contain macros,
#so this call may cause a recursive loop.
#returns 0 if okay, otherwise error count.
{
    my($outfile_ref, $includefn) = @_;

    printf STDERR "%s [cg_include]: includefn=%s\n", $p, $includefn if ($DEBUG);

    #expand include file name to full path with variable substitution:
    $includefn = &expand_include_fn($includefn);

    printf STDERR "including %s\n", $includefn if ($VERBOSE);
    return &expand_template($outfile_ref, $includefn);
}

sub cg_perl
#this is the %perl macro.
#Evaluate the enclosed perl expression.
#return 0 if okay, otherwise error count.
{
    my($outfile_ref, $ptxt) = @_;
    my($result, $theOutput);
    my($errcnt) = 0;

    printf STDERR "%s[cg_perl]: ptxt=%s\n", $p, $ptxt if ($DEBUG);

    $result = eval $ptxt;
    if ($@ ne "") {
        chomp $@;
        $theOutput = "{=%perl $ptxt -> ERROR: '$@'=}";
        ++$errcnt;
    } elsif (!defined($result)) {
        #WARNING:  the $@ construct doesn't seem to work on perl 5.005_03.  RT 6/19/06
        $theOutput = "{=%perl $ptxt -> (undef)=}";
        ++$errcnt;
    } else {
        $theOutput = $result;
    }

    printf STDERR "%s[cg_perl]: ptxt='%s' -> '%s'\n", $p, $ptxt, $result if ($DEBUG);

    print $outfile_ref $theOutput unless ($theOutput eq "");
    ++ $GLOBAL_ERROR_COUNT if ($errcnt > 0);
    return $errcnt;
}

sub cg_gen_imports
#this generates a java import statements from the list provided
#Example:  {=%gen_imports a,b,c=} =>
#               import a;
#               import b;
#               import c;
#the import list can also be a variable expression
#empty elements (,,) generate newlines.
#returns 0 if okay, otherwise error count.
{
    my($outfile_ref, $importlist) = @_;

    printf STDERR "%s[cg_gen_imports]: importlist=%s\n", $p, $importlist if ($DEBUG);

    #expand macros in arg:
    $importlist = &expand_macros($importlist);

    #expand template macros in arg:
    $importlist = &expand_string_template($importlist);

#printf STDERR "%s[cg_gen_imports]: importlist=%s\n", $p, $importlist;

    #eliminate trailing whitespace (already did leading whitespace):
    $importlist =~ s/\s+$//;
    #okay if list is empty:
    return 0 if ($importlist eq "");

    my (@ilist) = split(/\s*,\s*/, $importlist);

#printf STDERR "%s[cg_gen_imports]: ilist=(%s)\n", $p, join(',', @ilist);

    #eliminate duplicate imports:
    my (%mark, @nlist);
    for (@ilist) {
        chomp;
        if (/^$/ || /^[^a-zA-z]/) {
            #always push blank lines or non-identifier lines (i.e., comments):
            push(@nlist, $_);
        } else {
            push(@nlist, $_) unless ($mark{$_});
            $mark{$_}++;
        }
    }
#printf STDERR "%s[cg_gen_imports]: nlist=(%s)\n", $p, join(',', @nlist);

    for (@nlist) {
        #output whitespace lines or non-import token lines:
        if (/^$/ || /^[^a-zA-z]/ ) {
            print $outfile_ref "$_\n";
        } else {
            print $outfile_ref sprintf("import %s;\n", $_);
        }
    }

    print $outfile_ref "\n" unless $#nlist < 0;
    return 0;
}

sub cg_gen_javadoc
#this generates a javadoc comment from the string provided
#Example:  {=%gen_javadoc This is some javadoc for fooclass\n and here is some more=} =>
#               /**
#                * This is some javadoc for fooclass
#                * and here is some more.
#                */
#the import list can also be a variable expression
#returns 0 if okay, otherwise error count.
{
    my($outfile_ref, $doctxt) = @_;

    printf STDERR "%s[cg_gen_javadoc]: doctxt=%s\n", $p, $doctxt if ($DEBUG);

    #expand macros in arg:
    $doctxt = &expand_macros($doctxt);

    #expand template macros in arg:
    $doctxt = &expand_string_template($doctxt);

    #eliminate trailing whitespace (already did leading whitespace):
    $doctxt =~ s/\s+$//;
    #okay no javadoc
    return 0 if ($doctxt eq "");

    #do special char expansion, so far only tab chars:
    $doctxt =~ s/\\t/\t/g;

    #this should not be necessary, but some perls have trouble splitting on the literal '\n'
    $doctxt =~ s/\\n/\n/g;

    my (@doclist) = split("\n", $doctxt);
    printf STDERR "%s[cg_gen_javadoc]: doclist=(%s)\n", $p, join('|', @doclist) if ($DEBUG);

    print $outfile_ref "/**\n";

    my $line;
    foreach $line (@doclist) {
        #only add space after * if line is not empty:
        printf $outfile_ref " *%s\n", ($line ne ""? " $line" : "");
    }

    print $outfile_ref " */\n";

    return 0;
}

sub cg_echo
#this expands its arguments and outputs the result
#
#Example:  {=%echo somestuff='$somestuff'=}
#
#returns 0 if okay, otherwise error count.
{
    my($outfile_ref, $echotxt) = @_;
    my $token = "cg_echo";

    printf STDERR "%s[%s]: echotxt=%s\n", $p, $token, $echotxt if ($DEBUG);

    #expand variable expression:
    $echotxt = &expand_macros($echotxt);

    return 0 if ($echotxt eq "");

    #expand macros in argument expression if pragma is set:
    $echotxt = &expand_string_template($echotxt) if ( $pragma_echo_expands );
    print $outfile_ref $echotxt;

    return 0;
}

sub cg_exec
#this  executes an external command and returns the results

#Example:  {=%exec date=}
#
#returns the output of the date command.
{
    my($outfile_ref, $exectxt) = @_;
    my $token = "cg_exec";

    printf STDERR "%s[%s]: exectxt=%s\n", $p, $token, $exectxt if ($DEBUG);

    #expand variable expression:
    $exectxt = &expand_macros($exectxt);

    return 0 if ($exectxt eq "");

    #split into at most 2 fields:
    my ($cmdname, $tmp)  = split(/\s+/, $exectxt, 2);

    my $cmdargs = "";
    $cmdargs = " " . $tmp if (defined($tmp));

    #execute command in current shell directory:
    my $cmd = sprintf("%s%s%s", &get_shell_cd_cmd(), $cmdname, $cmdargs);

    $CG_USER_VARS{'CG_SHELL_STATUS'} = 255;    #unless shell sets status, we assume bad
    print $outfile_ref `sh -c '$cmd'`;
    $CG_USER_VARS{'CG_SHELL_STATUS'} = $?;

    return 0;
}

sub cg_assign
#this executes a restricted form of the assignment statement from within a macro.
#
#Example:  {=%assign foo = blah=}
#
#will create a variable $foo with contents 'blah'.
{
    my($outfile_ref, $assignment_txt) = @_;
        #note:  outfile_ref is unused here, as there is no output generated from the assignment.
    my $token = "cg_assign";

    printf STDERR "%s[%s]: assignment_txt=%s\n", $p, $token, $assignment_txt if ($DEBUG);

    return 0 if ($assignment_txt eq "");

    my ($lhs, $rhs, $is_multiline, $eoi_tok) = ("", "", 0, "");
    my ($is_raw) = 0;     #for := assignment operator
    my ($is_append) = 0;  #for .= assignment operator
    my ($numop) = 0;   #for +=, -=, /=, *= ...

    #now we can call normal definition parser:
    &definition($assignment_txt, 0, \$lhs, \$rhs, \$is_multiline, \$eoi_tok, \$is_raw, \$is_append, \$numop);

    return 0;
}

##################################### UTILITY ####################################

sub get_avaliable_filehandle
#return the index of an available file-handle
#return -1 if we are out of descriptors
{
    my($caller) = @_;
    my ($ii, $kk) = (0,0);

    for ($ii = 0; $ii <= $LAST_TEMPLATE_FD_KEY; $ii++) {
        $kk = ($ii + $TEMPLATE_FD_KEY) % ($LAST_TEMPLATE_FD_KEY+1);
        if ($TEMPLATE_FD_INUSE[$kk] == 0) {
            $TEMPLATE_FD_INUSE[$kk] = 1;
            $TEMPLATE_FD_KEY = $kk;   #where we start next time
            printf STDERR "ALLOCATE file handle #%d nfree=%d/%d caller=%s\n",
                $kk, &free_filehandle_count(), $LAST_TEMPLATE_FD_KEY+1,
                defined($caller)? $caller: "???"
                if ($DEBUG_FD);
            return $kk;
        }
    }

    printf STDERR "ALLOCATE FD FAILED nfree=%d/%d TEMPLATE_FD_KEY=%d LAST_TEMPLATE_FD_KEY=%d ii=%d kk=%d caller=%s\n",
        &free_filehandle_count(), $LAST_TEMPLATE_FD_KEY+1,
        $TEMPLATE_FD_KEY, $LAST_TEMPLATE_FD_KEY, $ii, $kk,
        defined($caller)? $caller: "???"
        if ($DEBUG_FD);

    $TEMPLATE_FD_KEY = 0;   #maybe someone will return one later.
    return -1;
}

sub free_filehandle
#mark a filehandle as being free
{
    my($fhidx, $caller) = @_;
    if ($fhidx >= 0 && $fhidx <= $LAST_TEMPLATE_FD_KEY) {
        $TEMPLATE_FD_INUSE[$fhidx] = 0;
        printf STDERR "    FREE file handle #%d nfree=%d/%d caller=%s\n",
            $fhidx, &free_filehandle_count(), $LAST_TEMPLATE_FD_KEY+1,
            defined($caller)? $caller: "???"
            if ($DEBUG_FD);
    } else {
        printf STDERR "%s[free_filehandle]: ERROR: bad filehandle index, %d\n", $p, $fhidx;
        ++ $GLOBAL_ERROR_COUNT;
    }
}

sub free_filehandle_count
#return the number of free file handles currently available
{
    my $cnt = 0;
    for (@TEMPLATE_FD_INUSE) {
        ++$cnt if ($_ == 0);
    }

    my $nused = ($LAST_TEMPLATE_FD_KEY+1) - $cnt;
    $TEMPLATE_FD_MAX_USED = $nused if ($nused > $TEMPLATE_FD_MAX_USED);
    return $cnt;
}


################################ USAGE SUBROUTINES ###############################

sub usage
{
    my($status) = @_;

    print STDERR <<"!";
Usage:  $p [options] [${p}_program]

Synopsis:
  Generate a hierarchy of files as described in <${p}_program>.
  If this file is not supplied, then read the program from stdin.

Options:
  -help   display this usage message and exit.
  -v      verbose output
  -V, -version
          display the interpreter version information.
  -x      strip off text before #!/bin/... line
  -S      look for ${p}_program in \$PATH.
  -debug  show debug output
  -ddebug show more debug output
  -se     show operator (:op) calls to external commands.
  -e      allow environment variable references in <${p}_program>
          file and in any template files referenced in same.
  -f      force regeneration of output files (default is to not overwrite).
  -u      regenerate output files if different.  Implies -f for those files.
  -cgroot output_dir
          write all output files relative to <output_dir>.  Sets value of
          builtin variable \$CG_ROOT, and overrides environment setting if -e.
  -templates template_path
          search for template files in <template_path>, which is a semi-colon
          list of directories. Sets \$CG_TEMPLATE_PATH.  Note: \$CG_TEMPLATE_PATH
          is inherited from environment if defined regardless of -e setting.
  -Dvar[=value]
          define <var>, and optionally initialize it to <value>.
  -T <tmpdir>
          create all $p temporary files in <tmpdir>.


$p grammar:
  The $p grammar has three types of entries:
    1. definitions of the form:  var = value
    2. file specifications of the form:
            template [>>] pathname
       If <pathname> contains or is prefixed by '.', we assume
       that <pathname> is a java class name, and we will
       append a ".java" to the filename automatically.
       If <pathname> contains or is prefixed by '/', we assume a
       non-java output file.  You can use "/foo.out" to force the non-java
       convention in the case where files are being generated to ".".
    3. comments or blank lines - comment lines start with '#', '{', or '}'.
       Curly brace comments are useful delimiting sections in large $p files.
    4. $p \% statements, for example:
        %include filename

  NOTE:  each ${p} program is interpreted, so the last value defined for
         a variable is used for subsequent expansions.  This means that
         you must define variables before referencing them.

Template files:
  Template files are text files that can include macros of the form:

  {=IDENTIFIER=}
     where IDENTIFIER is of the form:  [A-Za-z_]([A-Za-z_0-9])*
     Example:  {=user_name=}, where \$user_name is defined.

  {=VAR_EXPRESSION=}
     where VAR_EXPRESSION is a string containing one or more variable references.

     Example:

     import {=\$MY_BASE_CLASS.\$A_PACKAGE.\$SOMECLASS=};
     public interface {=CG_CLASSNAME=} {
         String dosomething () throws {=\$EXCEPTION1, \$EXCEPTION2=};
     }

     Note that {=a_var=}, {=\$a_var=}, and {=\${a_var}=} are equivalent.

  {=%include fn=}
     Include the file <fn>.  Includes can be nested.  <fn> can contain variables.
     All includes are processed relative to directories listed in \$CG_TEMPLATE_PATH,
     unless an absolute path name is specified.

     Example:  {=%include standard/copyright.txt=}

  {=%perl perl_expression...=}
     Evaluate a perl expression, and output the result string.  The expression
     must be a valid perl expression, and can use the $p built-in variables or
     any variables defined in the $p input script. Perl statements are
     separated with semi-colons.  The final semi-colon is optional.

     Example:  {=%perl \@list = (1,2,3); sprintf "(%s)\\n", join(',', \@list);=}
     Result:   1,2,3

     NOTE:  Every perl expression returns a result as a string.  For example,
            "\$a = 3;" will return the string "3" and output it to the generated file.
            If you do not want this, then use "\$a = 3;""" - i.e., modify the
            expression to return an empty string.

     NOTE:  Creating new perl variables can modify the operation of the $p
            program itself.  In order to avoid this, use a unique package
            name for all of your variables.  For example, use "\$cg::a = 3"
            instead of "\$a = 3".  This will create the variable \$a
            in the package "cg", which is not used by $p.

Built-in variables:

  \$CG_ROOT  The root of the output directory.  all files are generated relative
            to \$CG_ROOT.  Can also be supplied via -cgroot option.  Default is
            the current working directory.
  \$CG_TEMPLATE_PATH
            Semi-colon separated list of directories where we look for template files.
            Can also be supplied via -templates option.  This variable is always
            inherited from the environment, regardless of -e setting.
  \$CG_TMPDIR
            Write all temporary files to the directory.  Can also be supplied via -T option.
            Default is the current working directory.  This variable is always
            inherited from the environment, regardless of -e setting.
  \$CG_ARGV         
            a $p stack holding the arguments to the script.
  \$CG_MODE         
            the mode in octal that $p will set generated output files to.
  \$CG_SHELL_STATUS
            status of the last \%shell statement executed.
  \$CG_EXIT_STATUS
            user-settable variable to set the shell exit status of the input script.
  \$CG_INFILE         
            the name of the current input file.
  \$CG_LINE_NUMBER         
            the line number of the current statement, relative to the current CG_INFILE
  \$CG_NEWLINE_BEFORE_CLASS_BRACE         
            set to a newline if you like to see a newline before the opening class brace.
  \$CG_STACK_DELIMITER         
            For %push, %upush, split on this value to add list of stack elements.
            Default is \$; (perl delimiter). Example:  if delimiter is '.', then
            %push foostack a.b.c  will push three elements (a,b,c) on to \$foostack.

Variables that modify postfix operations:
  \$CG_INDENT_STRING         
            the indent string, used by :indent<n> post-op for each level.
  \$CG_SHELL_COMMAND_ARGS         
            arguments to pass to an external command processor for postfix variable
            operators.  (e.g., CG_SHELL_COMMAND_ARGS = -n; \$FOO=\${FOO:sort})
  \$CG_MATCH_SPEC         
            the match pattern to apply for :m (or :match) operator.
  \$CG_SUBSTITUTE_SPEC         
            the substitute pattern to apply for :s (or :substitute) operator.
  \$CG_COMPARE_SPEC         
            the compare spec for :eq, :ne, :gt, :lt, :ge, :le  operators.

Pragmas modifiy the behavior of the interpreter as follows:
    \%pragma require perl_file
            read a <perl_file> into the current context.  Can be used to add custom operators.
    \%pragma reset_stack_delimiter
            restore CG_STACK_DELIMITER to default value. 

    \%pragma echo_expands [1|0]
            if 1, auto-expand macros in %echo template argument list.
    \%pragma maxevaldepth <num>
            if <= 0, max recursion depth for %evalmacro * (recursive) is unbounded.
            if >= 1, max recursion depth for %evalmacro * is set to <num>.
            NOTE:  default setting is ${pragma_maxevaldepth}.

    \%pragma clrifndef [1|0]
            if 1, undefined template macros resolve to empty string instead of \${var:undef}.

    \%pragma copy [1|0]
            do not expand templates when generating documents.
    \%pragma update [1|0]
            set -u(pdate) option.

    \%pragma debug [1|0]
            set -debug option.
    \%pragma ddebug [1|0]
            set -ddebug option.
    \%pragma quiet [1|0]
            set -q(uiet) option.
    \%pragma verbose [1|0]
            set -v(erbose) option.

    \%pragma filegen_notices_to_stdout [1|0]
            send file generation (x -> y) messages to stdout instead of stderr.
    \%pragma preserve_multiline_lnewline [1|0]
            preserve the first newline in a here-now document (normally trimmed).
    \%pragma trim_multiline_rnewline [1|0]
            trim the final newline in a here-now document (normally added).

Class variables:
  Class variables are available during the processing of a file-spec line.
  For example, assume that your filespec is:

    mytemplate.jtpl  com.acme.roles.baker.BreadMaker

  Then the following variables are available during file generation:

    CG_TEMPLATE        the name of the template file (mytemplate.jtpl).
    CG_DIRNAME         the name of the output dir (com/acme/roles/baker).
    CG_FILENAME        the name of the output file (BreadMaker.java).
    CG_CLASSNAME       the name of the current class (BreadMaker).
    CG_FULL_CLASSNAME  the full class name (com.acme.roles.baker.BreadMaker).
    CG_PKGNAME         the relative package name (baker).
    CG_FULL_PKGNAME    the full package name (com.acme.roles.baker).

  Note that the file specification is parsed before the template name,
  so you can include the above variables in a template spec.  Example:

    \$CG_PKGNAME/mytemplate.jtpl  com.acme.roles.baker.BreadMaker

  Note further that the class variables are available until the
  next file-spec line:
    basic/aclass.jtpl  com.acme.roles.baker.BreadMaker
    BAKER_CLASS = \$CG_CLASSNAME
        [sets \$BAKER_CLASS to "BreadMaker"]

Examples:
  $p -v -cgroot ./output -templates ./templates myjavatree.txt
!
    return($status);
}

sub parse_args
#proccess command-line aguments
{
    local(*ARGV, *ENV) = @_;
    my ($flag, $arg);

    #eat up flag args:
    while ($#ARGV+1 > 0 && $ARGV[0] =~ /^-/) {
        $flag = shift(@ARGV);

        if ($flag eq '-') {
            $INPUT_FILE = "<STDIN>";
        } elsif ($flag =~ '^-h') {
            $HELPFLAG = 1;
            return(&usage(0));
        } elsif ($flag =~ '^-x') {
            #-x:   strip off text before #!/bin/... line
            $STRIPTOSHARPBANG = 1;
        } elsif ($flag =~ '^-S') {
            #-S:   look for programfile using PATH environment variable
            $LOOKINPATH = 1;
        } elsif ($flag =~ '^-vers' || $flag =~ '^-V') {
            $HELPFLAG = 1;
            return(&version(0));
        } elsif ($flag =~ '^-v') {
            $VERBOSE = 1;
            $QUIET = 0;
        } elsif ($flag =~ '^-q') {
            $QUIET = 1;    #turns off WARNINGS as well
            $VERBOSE = 0;
        } elsif ($flag =~ '^-dd') {
            $DDEBUG = 1;
        } elsif ($flag =~ '^-debugfd') {
            $DEBUG_FD = 1;
        } elsif ($flag =~ '^-d') {
            $DEBUG = 1;
        } elsif ($flag =~ '^-se') {
            $SHOW_EXTERNS = 1;
        } elsif ($flag =~ '^-D') {
            #expect a definition of the form:  -Dvar[=value]
            my $var = "";
            my $val = "";
            $var = $1 if ( $flag =~ /^-D([^=]+)/ );
            $val = $1 if ( $flag =~ /^-D[^=]+=(.*)$/ );
            if ($var ne "") {
                #add definition:
                $CG_USER_VARS{$var} = $val;
            } else {
                printf STDERR "%s:  -D should be of the form: '-Dvar[=value]'\n", $p;
                return 1;
            }
        } elsif ($flag =~ '^-e') {
            $ENV_VARS_OKAY = 1;
        } elsif ($flag =~ '^-f') {
            $FORCE_GEN = 1;
        } elsif ($flag =~ '^-u') {
            $UPDATE = 1;
        } elsif ($flag eq "-T") {
            if ($#ARGV+1 > 0 && $ARGV[0] !~ /^-/) {
                $CG_TMPDIR = shift(@ARGV);
            } else {
                printf STDERR "%s:  -T requires a directory name\n", $p;
                return 1;
            }
        } elsif ($flag =~ '^-cgroot') {
            if ($#ARGV+1 > 0 && $ARGV[0] !~ /^-/) {
                $CG_ROOT = shift(@ARGV);
            } else {
                printf STDERR "%s:  -cgroot requires a directory name\n", $p;
                return 1;
            }
        } elsif ($flag =~ '^-templates') {
            if ($#ARGV+1 > 0 && $ARGV[0] !~ /^-/) {
                $CG_TEMPLATE_PATH = shift(@ARGV);
            } else {
                printf STDERR "%s:  -templates requires a directory name\n", $p;
                return 1;
            }
        } else {
            return(&usage(1));
        }
    }

    #eliminate empty args (this happens on some platforms):
    @ARGV = grep(!/^$/, @ARGV);

    #if input file is not yet set...
    if ($INPUT_FILE eq "") {
        if ($#ARGV < 0) {
            $INPUT_FILE = "<STDIN>";
        } else {
            $INPUT_FILE = shift(@ARGV);
        }
    }

    if (!$UPDATE && !$QUIET) {
        printf STDERR "%s:  WARNING: -u not specified - existing files will not be updated\n", $p;
    }

    #NOTE:  remaining arguments are arguments to cado script.
    #the cado arguments are initialized in init_spec_vars().

    #re-init pragma values based on arguments passed in:
    $pragma_environment = $ENV_VARS_OKAY;
    $pragma_debug = $DEBUG;
    $pragma_ddebug = $DDEBUG;
    $pragma_quiet = $QUIET;
    $pragma_update = $UPDATE;
    $pragma_verbose = $VERBOSE;

    return(0);
}

sub findInputFileInPath
#look for the file name in path, and return the full path name if found.
#otherwise, return the original name.
{
    my ($infile) = @_;
    printf STDERR "findInputFileInPath: infile='%s'\n", $infile if ($DEBUG);;
    return $infile if ($infile eq '<STDIN>');

    #look for the obvious first:
    return $infile if (-r $infile);

    #otherwise, look in $PATH:
    my $outfn =  &path::which($infile);
    printf STDERR "findInputFileInPath: which(%s)='%s'\n", $infile, &path::which($infile) if ($DEBUG);
    return ($outfn ne "" ? $outfn : $infile);
}

sub version
{
    my($status) = @_;
    print STDERR <<"!";
$p: Version $VERSION, $VERSION_DATE.
!
    return($status);
}

sub dumphash
{
    my ($ref, $name) = @_;

    my ($kk, $vv);
    print STDERR "\n========== $name\n";
    foreach $kk (sort keys %{$ref}) {
        printf STDERR "%s{'%s'}\t='%s'\n", $name, $kk, ${$ref}{$kk};
    }
    print STDERR "========== $name\n";
}

sub init
#copies of global vars from main package:
{
    $p = $'p;       #$main'p is the program name set by the skeleton

    #collect some env vars:
    $LOGNAME = "";
    $LOGNAME = $ENV{'LOGNAME'} if (defined($ENV{'LOGNAME'}));
}

sub init_spec_vars
#initialize "special" built-in variables.
{
    #save arguments passed in to cado script:
    if ($#ARGV >= 0) {
        #create a stack variable:
        $CG_USER_VARS{'CG_ARGV'} = join($;, @ARGV);
    }

    if ($CG_ROOT eq "NULL") {
        if ($ENV_VARS_OKAY && defined($ENV{'CG_ROOT'})) {
            $CG_ROOT = $ENV{'CG_ROOT'};
            printf STDERR "%s: INFO: inherited CG_ROOT='%s' from environment.\n", $p, $CG_ROOT if ($VERBOSE);
        } else {
            $CG_ROOT = &undefname('CG_ROOT');
        }
    }

    #####
    #NOTE - we always inherit CG_TMPDIR and CG_TEMPLATE_PATH from the env.
    #       you can still override them on the command line or in the cado source file:
    #####

    if ($CG_TMPDIR eq "NULL") {
        if (defined($ENV{'CG_TMPDIR'})) {
            $CG_TMPDIR = $ENV{'CG_TMPDIR'};
            printf STDERR "%s: INFO: inherited CG_TMPDIR='%s' from environment.\n", $p, $CG_TMPDIR if ($VERBOSE);
        } else {
            $CG_TMPDIR = &undefname('CG_TMPDIR');
        }
        #note we avoid setting until used.
    }

    if ($CG_TEMPLATE_PATH eq "NULL") {
        if (defined($ENV{'CG_TEMPLATE_PATH'})) {
            $CG_TEMPLATE_PATH = $ENV{'CG_TEMPLATE_PATH'};
            printf STDERR "%s: INFO: inherited CG_TEMPLATE_PATH='%s' from environment.\n", $p, $CG_TEMPLATE_PATH if ($VERBOSE);
        } else {
            $CG_TEMPLATE_PATH = '.';   #use default value
        }
    }

    #we keep this as a string, but make sure you convert it to decimal using oct() before using:
    $CG_USER_VARS{'CG_MODE'} = "0664";

    $CG_USER_VARS{'CG_ROOT'} = $CG_ROOT;
    $CG_USER_VARS{'CG_TMPDIR'} = $CG_TMPDIR;
    $CG_USER_VARS{'CG_TEMPLATE_PATH'} = $CG_TEMPLATE_PATH;
    $CG_USER_VARS{'CG_NEWLINE_BEFORE_CLASS_BRACE'} = $CG_NEWLINE_BEFORE_CLASS_BRACE;
    $CG_USER_VARS{'CG_INDENT_STRING'} = $CG_INDENT_STRING;
    $CG_USER_VARS{'CG_SHELL_COMMAND_ARGS'} = undef;
    $CG_USER_VARS{'CG_SHELL_STATUS'} = undef;
    $CG_USER_VARS{'CG_EXIT_STATUS'} = undef;
    $CG_USER_VARS{'CG_LINE_NUMBER'} = 0;
    &reset_stack_delimiter();  #input/output stack display delimiter:
    &reset_split_pattern();    #split pattern for :split op
    $LINE_CNT_REF = \$CG_USER_VARS{'CG_LINE_NUMBER'};
}

sub reset_split_pattern
#split pattern for :split op
{
    $CG_USER_VARS{'CG_SPLIT_PATTERN'} = $CG_SPLIT_PATTERN_DEFAULT_VALUE;
}

sub reset_stack_delimiter
#input/output stack display delimiter.
{
    $CG_USER_VARS{'CG_STACK_DELIMITER'} = $CG_STACK_DELIMITER_DEFAULT_VALUE;
}

sub get_stack_delimiter
#escape meta-characters for stack delimiters so we can use them as split pattern.
{
    my $d = $CG_USER_VARS{'CG_STACK_DELIMITER'};
    return "\\$1" if ($d =~ /(^[\|\$\^\&\-\*\@\?\'\"\.\+\(\)\[\}\{\}\\]$)/);
    return $d;
}

sub create_cg_root
#create the current CG_ROOT dir if it doesn't yet exist
#return false if unable to create
{
    if (!&var_defined('CG_ROOT')) {
        #default it to cwd:
        $CG_USER_VARS{'CG_ROOT'} = $DOT;
        printf STDERR "%s: WARNING: CG_ROOT is UNDEFINED, setting to '%s'\n",
            $p, $CG_USER_VARS{'CG_ROOT'} unless ($QUIET);
        return 1;
    }

    #otherwise, create CG_ROOT
    my $cg_root = $CG_USER_VARS{'CG_ROOT'};

    &os::createdir($cg_root, 0775) unless (-d $cg_root);
    if (!-d $cg_root) {
        return 0;   #FAIL
    }

    return 1;    #true if dir is there or we created.
}

sub create_cg_tmpdir
#create the current CG_TMPDIR directory if it doesn't yet exist
#return false if unable to create
{
    if (!&var_defined('CG_TMPDIR')) {
        #if there is already a dir named "./tmp", then use it.
        #this prevents problems if we run in /:
        if (-d &path::mkpathname($DOT, "tmp")) {
            $CG_USER_VARS{'CG_TMPDIR'} = &path::mkpathname($DOT, "tmp");
        } else {
            $CG_USER_VARS{'CG_TMPDIR'} = $DOT;
        }
        printf STDERR "%s: WARNING: CG_TMPDIR is UNDEFINED, setting to '%s'\n",
            $p, $CG_USER_VARS{'CG_TMPDIR'} if ($VERBOSE);

        #we are using an existing dir so we are done:
        return 1;
    }

    my $cg_tmpdir = $CG_USER_VARS{'CG_TMPDIR'};

    &os::createdir($cg_tmpdir, 0775) unless (-d $cg_tmpdir);
    if (!-d $cg_tmpdir) {
        return 0;
    }

    return 1;    #true if dir is there or we created.
}

my $TMPVAR_CNT = 0;

sub newtmpvarname
#return the next available cado tmp varname
{
    return sprintf("CG_TMPVAR_%04d", ++$TMPVAR_CNT);
}

sub undef_tmpvar
{
    my ($tmpvarname) = @_;
    return unless $tmpvarname =~ /^CG_TMPVAR_(\d+)$/;

    #we had a match - save tmpvar counter
    my $cnt = $1;

    #decrement the counter if we are freeing the last allocated:
    --$TMPVAR_CNT if ($cnt = $TMPVAR_CNT);

    #delete the variable:
    delete $CG_USER_VARS{$tmpvarname};
}

sub get_cg_tmpfile_name
#return the next available cado temp-file name.
#
#INPUT:  (optional) the leaf filename to use in generating the fullpath of the temp file name
#OUTPUT: the fullpath of the temp file name
#
#WARNING:  paths that start with "//" mean "network drive" to cygwin, so
#          use &path::mkpathname() to create pathnames.
{
    my ($tmpfile) = @_;

    #if caller doesn't supply filename, then generate next available name:
    $tmpfile = sprintf("_cado.tmpfile.%d.%d", $$, $CG_TMPFILE_CNT++) unless (defined($tmpfile));

    if (!&create_cg_tmpdir()) {
        printf STDERR "%s[get_cg_tmpfile_name]: ERROR: line %d: cannot create CG_TMPDIR '%s': %s\n",
            $p, $LINE_CNT, $CG_USER_VARS{'CG_TMPDIR'}, $!;
        return "NULL";   #FAILED
    }

    #now it is safe to use CG_TMPDIR:
    my $cg_tmpdir = $CG_USER_VARS{'CG_TMPDIR'};

    my $tmpfile_fullpath = &path::mkpathname($cg_tmpdir, $tmpfile);

    printf STDERR "get_cg_tmpfile_name: cg_tmpdir='%s' (-d '\$cg_tmpdir/tmp')=%d tmpfile'%s' tmpfile_fullpath='%s'\n",
        $cg_tmpdir, (-d &path::mkpathname($cg_tmpdir, "tmp"))?1:0, $tmpfile, $tmpfile_fullpath if ($DEBUG);

    return $tmpfile_fullpath;
}

sub write_string_to_cg_tmp_file
#create a CG tmp file, and write a string to it.
#return the name of the file, or "NULL" if failed to create file
#NOTE:  caller must remove tmp file.
#NOTE:  caller must decide to increment global error count
{
    my ($theStr) = @_;

    #get a tempfile name:
    my $tmpfile_fullpath = &get_cg_tmpfile_name();

    #write the string into tmp file:
    if ( &os::write_str2file(\$theStr, $tmpfile_fullpath) != 0 ) {
        printf STDERR "%s[write_string_to_cg_tmp_file]: ERROR: line %d: write FAILED\n",
            $p, $LINE_CNT, $tmpfile_fullpath;
        return "NULL";   #FAILED
    }

    return $tmpfile_fullpath;
}

sub cleanup
{
}


sub eval_postfix_op
#implement postfix operations for variables
#returns input string with operation applied.
{
    my ($op, $var, $varname, $linecnt) = @_;

    my $fname = sprintf("%s_op", $op);
    my $fref = \&{$fname};

    #printf STDERR "eval_postfix_op:  op='%s' varname='%s' var='%s' fname='%s'\n", $op, $varname, $var, $fname if ($DEBUG);
#printf STDERR "eval_postfix_op:  op='%s' varname='%s' var='%s' fname='%s'\n", $op, $varname, $var, $fname;

    if ( defined(&{$fref}) ) {
        $var = &{$fref}($var, $varname, $linecnt);
        printf STDERR "eval_postfix_op:  AFTER var='%s'\n", $var if ($DEBUG);
#printf STDERR "eval_postfix_op:  AFTER var='%s'\n", $var;
        return $var;
    }

    #otherwise, we have an arithmetic op, or external command.

    if ($op =~ /^indent(\d*)$/) {
        #add n indent levels, as defined by CG_INDENT_STRING
        if (defined($1) and $1 ne "") {
            $var = &increase_indent($var, $1) unless ($var eq "");
        } else {
            #no indent level supplied - assume 1:
            $var = &increase_indent($var, 1) unless ($var eq "");
        }
    } elsif ($op =~ /^_([^\s]*)$/) {
        #this is the xml/html wrapper op.  $foo:_p => <p>$foo</p>
        if (defined($1) and $1 ne "") {
            my $ee = $1;  #save element name

            #if we have CG_ATTRIBUTE_$ee defined ...
            if (&var_defined("CG_ATTRIBUTE_$ee")) {
                $var = sprintf "<%s %s>%s</%s>", $ee, &lookup_def("CG_ATTRIBUTE_$ee"), $var, $ee;
            } else {
                $var = sprintf "<%s>%s</%s>", $ee, $var, $ee;
            }
        }
    } elsif ($op =~ /^plus(\d*)$/) {
        my $tmp = $var; $tmp =~ s/^\s*[-+]\s*//;
        $var = sprintf "%.*d", length($tmp), ($var + $1) if (defined($1) and $1 ne "");
    } elsif ($op =~ /^minus(\d*)$/) {
        my $tmp = $var; $tmp =~ s/^\s*[-+]\s*//;
        $var = sprintf "%.*d", length($tmp), ($var - $1) if (defined($1) and $1 ne "");
    } elsif ($op =~ /^times(\d*)$/) {
        my $tmp = $var; $tmp =~ s/^\s*[-+]\s*//;
        $var = sprintf "%.*d", length($tmp), ($var * $1) if (defined($1) and $1 ne "");
    } elsif ($op =~ /^div(\d*)$/) {
        my $tmp = $var; $tmp =~ s/^\s*[-+]\s*//;
        $var = sprintf "%.*d", length($tmp), ($var / $1) if (defined($1) and $1 ne "");
    } elsif ($op =~ /^rem(\d*)$/) {
        my $tmp = $var; $tmp =~ s/^\s*[-+]\s*//;
        $var = sprintf "%.*d", length($tmp), ($var % $1) if (defined($1) and $1 ne "");
    } elsif ($op =~ /^\s*$/) {
        #silently ignore empty operators
    } else {
        #assume that operator is a valid shell command:
        printf STDERR "%s [eval_postfix_op]: invoking '%s' as external command.\n", $p, $op if ($SHOW_EXTERNS);
        $var = &exec_shell_op($op, $var);
    }

    printf STDERR "eval_postfix_op:  AFTER var='%s'\n", $var if ($DEBUG);
    return $var;
}

sub increase_indent
#increase the indent level of each line in input 
{
    my ($var, $indent_level) = @_;
    my $leadin = &lookup_def("CG_INDENT_STRING") x $indent_level;

    my $eolpat = "\n";
    if ($var =~ /\r/) {
        #set to use dos line endings:
        $eolpat = "\r\n";
    }
    my @tmp = split($eolpat, $var, -1);
        #-1 => include trailing null fields, i.e., empty lines in this case

#printf STDERR "increase_indent: leadin='%s' tmp=(%s)\n", $leadin, join(',', @tmp);

    #this is much faster than a for loop:
    grep ((!/^\s*$/) && ($_ = "$leadin$_"), @tmp);

    return join("\n", @tmp);
}

sub exec_shell_op
#open a command processor as a pipe, and feed <var> as stdin.
#returns <var> unmodified if there is an error creating the pipe,
#otherwise, the output from the command.
{
    my ($cmdname, $var) = @_;
#printf STDERR "exec_shell_op: cmdname='%s' var='%s'\n", $cmdname, $var;

    #write $var to a tmp file:
    my $tmpfile = &os'TempFile;
    if (!open(TMPFILE, ">$tmpfile")) {
        printf STDERR "%s [exec_shell_op]: ERROR: cannot open '%s' for write: %s\n", $p, $tmpfile, $!;
        ++ $GLOBAL_ERROR_COUNT;
        # var is unmodified
        return $var;
    }
    
    #copy contents of var to tmp file:
    print TMPFILE $var;

    #make sure that input to pipe has at least one EOL.
    #otherwise, mks won't read the pipe.
    #if ($var !~ /\n$/s ) {
    #    print TMPFILE "\n";
    #}

    close TMPFILE;

    #check for command line arguments:
    my $cmdargs = "";
    $cmdargs = (" " .  &lookup_def('CG_SHELL_COMMAND_ARGS')) if (&var_defined('CG_SHELL_COMMAND_ARGS'));

    #execute command in current shell directory:
    my $cmd = sprintf("%s%s%s", &get_shell_cd_cmd(), $cmdname, $cmdargs);

    #now open pipe to command:
    $CG_USER_VARS{'CG_SHELL_STATUS'} = 255;    #unless shell sets status, we assume bad
    if (!open(CMDPIPE, "sh -c '$cmd' <$tmpfile|")) {
        printf STDERR "%s [exec_shell_op]: ERROR: cannot open pipe to command '%s': %s\n", $p, $cmd, $!;
        ++ $GLOBAL_ERROR_COUNT;

        # var is unmodified
        return $var;
    }
    
    #read stdout of pipe back into var:
    my @var = <CMDPIPE>;
    close CMDPIPE;
    $CG_USER_VARS{'CG_SHELL_STATUS'} = $?;

    #join to produce final string:
    $var = join("",@var);

    return $var;
}

sub is_number
#true if <var> is a number (integer or decimal).
{
    my ($var) = @_;
    my $result = ( ($var =~ /^\s*[-+]?\s*\d+(\.\d+)?\s*$/) ? 1 : 0 );

#printf STDERR "is_number: var='%s' result=%d\n", $var, $result;

    return $result;
}

sub is_integer
#true if <var> is an integer
{
    my ($var) = @_;
    return ($var =~ /^\s*[-+]?\s*\d+\s*$/);
}

sub is_java_comment
{
    my ($lref) = @_;
    my (@lines) = @{$lref};
    my ($ans) = 0;

    while ($#lines >= 0) {
        if (&is_java_line_comment($lines[0])) {
            $ans = 1;
            shift @lines;
        } elsif (&is_java_block_comment_start($lines[0])) {
            #loop until we find the end:
            shift @lines;
            while ($#lines >= 0 && !($ans = &is_java_block_comment_end($lines[0]))) {
                shift @lines;
            }
            shift @lines if ($ans);
        } else {
            last;
        }
    }

    #replace original only if we modified it:
    @{$lref} = @lines if ($ans);

    return $ans;
}

sub is_java_block_comment_start
{
    my ($txt) = @_;

    #look for /*, but not /** ..
    return 1 if ($txt =~ /^\s*\/\*/ && $txt !~ /^\s*\/\*\*/);
    return 0;
}

sub is_java_block_comment_end
{
    my ($txt) = @_;
    return ($txt =~ /\*\//) ? 1 : 0;
}

sub is_java_line_comment
{
    my ($txt) = @_;

    #look for // ...
    return 1 if ($txt =~ /^\s*\/\//);

    #look for /* ... */, but not /** .. */
    if ($txt =~ /^\s*\/\*/ && $txt =~ /\*\//) {
        #we don't count javadoc as part of the header:
        return 1 unless $txt =~ /^\s*\/\*\*/;
    }

    return 0;
}

sub is_wsp
{
    my ($lref) = @_;
    my (@lines) = @{$lref};
    my ($ans) = 0;

    while ($#lines >= 0 && $lines[0] =~ /^\s*$/) {
        shift @lines;
        $ans = 1;
    }

    #replace original only if we modified it:
    @{$lref} = @lines if ($ans);

    return $ans;
}


sub rtrim_op
#process :rtrim postfix op
{
    my ($var) = @_;
    $var =~ s/\s+$//s;
    return $var;
}

sub trim_op
#process :trim postfix op
{
    my ($var) = @_;
    $var =~ s/^\s+//;
    $var =~ s/\s+$//s;
    return $var;
}

sub undef_op
#process :undef postfix op
{
    my ($var, $varname) = @_;
    #undefine $varname
    delete $CG_USER_VARS{$varname} if (defined($CG_USER_VARS{$varname}));
    $var = sprintf('${%s:undef}', $varname);   #same as lookup_def returns.
    return $var;
}

sub studyclass_op
#generate CG_ classname variables.
#return 1 if successful
{
    my ($classname) = @_;

    %CLASS_VARS = (); 
    &gen_classvars(\%CLASS_VARS, $classname);

    return 1;
}

sub m_op
#alias for :match
{
    return &match_op(@_);
}

sub match_op
#process :match postfix op
#:match or :m - will match against CG_MATCH_SPEC
#return 1 if match, else 0.
{
    my ($var) = @_;
    my $spec = $CG_USER_VARS{'CG_MATCH_SPEC'};

    return 0 unless (defined($spec));

#printf "expr_match: var='%s' spec='%s'\n", $var, $spec;

    my $ans = eval "\$var =~ $spec";

    if ($@) {
        printf STDERR "%s[match]: ERROR: line %d: evaluation of CG_MATCH_SPEC (%s) failed: %s\n",
            $p, $LINE_CNT, $spec, $@;
        return 0;
    } elsif (!defined($ans)) {
        #WARNING:  the $@ construct doesn't seem to work on perl 5.005_03.  RT 6/19/06
        printf STDERR "%s[match]: ERROR: line %d: evaluation of CG_MATCH_SPEC (%s) failed: %s\n",
            $p, $LINE_CNT, $spec, "ERROR in eval" ;
        return 0;
    }

    return ($ans eq ""? 0 : 1);
}

sub pad_op
#process :pad postfix op
#pad a number or string as specified by CG_PAD_SPEC
#Default is to zero-pad integers to width 2.
#CG_PAD_SPEC is take as an sprintf format spec.
{
    my ($var) = @_;
    my $spec = $CG_USER_VARS{'CG_PAD_SPEC'};

    if (!defined($spec)) {
        if (&is_integer($var)) {
            $spec = "%02d";
        } else {
            $spec = "%2s";
        }
    }

    printf "pad_op: var='%s' spec='%s'\n", $var, $spec if ($DEBUG);

    return sprintf($spec, $var);
}

sub s_op
#alias for :substitute
{
    return &dosubstitute('CG_SUBSTITUTE_SPEC', @_);
}

sub substitute_op
#process :substitute postfix op
#:substitute or :s - will match against CG_SUBSTITUTE_SPEC
{
    return &dosubstitute('CG_SUBSTITUTE_SPEC', @_);
}

#additional substitutions for nested substitution expressions:
sub s2_op { return &dosubstitute('CG_SUBSTITUTE_SPEC2', @_); }
sub s3_op { return &dosubstitute('CG_SUBSTITUTE_SPEC3', @_); }
sub s4_op { return &dosubstitute('CG_SUBSTITUTE_SPEC4', @_); }
sub s5_op { return &dosubstitute('CG_SUBSTITUTE_SPEC5', @_); }

sub dosubstitute
#implement substitution operators.
{
    my ($specvar, $var) = @_;

#printf STDERR "dosubstitute var='%s' specvar='%s'\n", $var, $specvar;

    my $spec = &lookup_def($specvar);
    return $var unless (&var_defined($specvar));

    my $savevar = $var;
    my $result = eval "\$var =~ $spec";

    if ($@) {
        printf STDERR "%s[substitute]: ERROR: line %d: evaluation of %s (%s) failed: %s\n",
            $p, $LINE_CNT, $specvar, $spec, $@;
        return $savevar;
    } elsif (!defined($result)) {
        #WARNING:  the $@ construct doesn't seem to work on perl 5.005_03.  RT 6/19/06
        printf STDERR "%s[substitute]: ERROR: line %d: evaluation of %s (%s) failed: %s\n",
            $p, $LINE_CNT, $specvar, $spec, "ERROR in eval" ;
        return $savevar;
    }

    return $var;
}

sub sl_op
#alias for :substituteliteral (literal substitute).
{
    return(substituteliteral_op(@_));
}

sub substituteliteral_op
#process :substituteliteral postfix op (literal substitute).
{
    my ($var) = @_;

    my $spec = &lookup_def('CG_SUBSTITUTE_SPEC');
    return $var unless (&var_defined('CG_SUBSTITUTE_SPEC'));

    my $input_spec = $spec;    #save original for messages.
    #skip over "s" in substitute spec:
    $spec =~ s/\s*s\s*//;

    #what is the delimiter?
    my $sep = substr($spec, 0, 1);

    #eliminate leading delimiter:
    $spec =~ s/^$sep//;

    #convert non-escaped separators to $;
    $spec =~ s/\\\\/!#%EsCaPeD_BaCkSlAsHeS%#!/g; #substitute escaped backslashes with special pattern
    $spec =~ s/$sep/$;/g;                        #convert sep chars to $;
    $spec =~ s/\\$;/$sep/g;                      #revert escaped sep chars
    $spec =~ s/!#%EsCaPeD_BaCkSlAsHeS%#!/\\\\/g; #revert escaped backslashes

    my (@tmp) = split($;, $spec, -1);
    my ($lit, $rep) = ("", "");
    my $modifiers = "";

    ###
    #Set subst/replace strings.  try to compensate for some common user errors.
    ###
    if ($#tmp == 2) {
        #case I:  3 elements:  lit/rep/modfiers  (modifiers can be empty)
        #                      0   1   2
        ($lit, $rep, $modifiers) = @tmp;
    } elsif ($#tmp == 1) {
        #case II:  2 elements:  lit/rep
        #                       0   1
        #we assume user forgot to add final separator.
        ($lit, $rep) = @tmp;
    } elsif ($#tmp > 2) {
        #case II:  >2 elements:  lit/rep/modifiers
        #                        0   $-1
        #either lit or rep has separators.  we assume lit and issue warning.

        my $nn = $#tmp;
#printf STDERR "nn=%d tmp=(%s)\n", $nn, join('!', @tmp);
        ($lit, $rep, $modifiers) = (join($sep, @tmp[0..$nn-2]), $tmp[$nn-1], $tmp[$nn]);

    printf STDERR "%s[substituteliteral]: WARNING: line %d: too many separators in CG_SUBSTITUTE_SPEC (%s) - assuming they belong to lhs.\n",
            $p, $LINE_CNT, $input_spec unless($QUIET);
    }

    my $isglobal = 0;
    $isglobal = 1 if ($modifiers eq "g");  #currently g is the only allowed modifier

#printf STDERR "substituteliteral_op: (sep lit rep modifiers isglobal)=('%s' '%s' '%s' '%s' '%s')\n", $sep, $lit, $rep, $modifiers, $isglobal;

    #return if $lit is the same as $rep - this is a nop and will prevent loop below from terminating.
    return $var if ($lit eq $rep);

    my ($idx, $len) = (index($var, $lit), length($lit));

#printf STDERR "substituteliteral_op: (idx,len)=(%d,%d)\n", $idx, $len;

    #if literal is found in var, then replace it:
    if ($idx >= 0) {
        substr($var, $idx, $len) = $rep;

        #replace all occurances if "g" specified:
        while ($isglobal && ($idx = index($var, $lit)) >= 0) {
            substr($var, $idx, $len) = $rep;
        }
    }

    return $var;
}

sub tounix_op
#convert a string to unix text
{
    my ($var) = @_;

    $var =~ s/\r\n/\n/gm;
    return $var;
}

sub todos_op
#convert a string to dos text
{
    my ($var) = @_;

    #make sure it is in unix format:
    $var =~ &tounix_op($var);

    $var =~ s/\n/\r\n/gm;
    return $var;
}

sub eq_op
#process :eq postfix op
#:eq - will compare against CG_COMPARE_SPEC
{
    my ($var) = @_;

    my $spec = $CG_USER_VARS{'CG_COMPARE_SPEC'};
    return 0 unless (defined($spec));
    return ($var == $spec) if (&is_number($var) && &is_number($spec));
    return ($var eq $spec);
}

sub ne_op
#process :ne postfix op
#:ne - will compare against CG_COMPARE_SPEC
{
    my ($var) = @_;

    my $spec = $CG_USER_VARS{'CG_COMPARE_SPEC'};
    return 0 unless (defined($spec));
    return ($var != $spec) if (&is_number($var) && &is_number($spec));
    return ($var ne $spec);
}

sub gt_op
#process :gt postfix op
#:gt - will compare against CG_COMPARE_SPEC
{
    my ($var) = @_;

    my $spec = $CG_USER_VARS{'CG_COMPARE_SPEC'};
    return 0 unless (defined($spec));
    return ($var > $spec) if (&is_number($var) && &is_number($spec));
    return ($var gt $spec);
}

sub ge_op
#process :ge postfix op
#:ge - will compare against CG_COMPARE_SPEC
{
    my ($var) = @_;

    my $spec = $CG_USER_VARS{'CG_COMPARE_SPEC'};
    return 0 unless (defined($spec));
    return ($var >= $spec) if (&is_number($var) && &is_number($spec));
    return ($var ge $spec);
}

sub lt_op
#process :lt postfix op
#:lt - will compare against CG_COMPARE_SPEC
{
    my ($var) = @_;

    my $spec = $CG_USER_VARS{'CG_COMPARE_SPEC'};
    return 0 unless (defined($spec));
    return ($var < $spec) if (&is_number($var) && &is_number($spec));
    return ($var lt $spec);
}

sub le_op
#process :le postfix op
#:le - will compare against CG_COMPARE_SPEC
{
    my ($var) = @_;

    my $spec = $CG_USER_VARS{'CG_COMPARE_SPEC'};
    return 0 unless (defined($spec));
    return ($var <= $spec) if (&is_number($var) && &is_number($spec));
    return ($var le $spec);
}

sub basename_op
#process :basename postfix op
#return basename of input var
{
    my ($var) = @_;

    #if not a path name, then just return simple name:
    return $var unless ( $var =~ /[\/\\]/ );

    return $1 if ( $var =~ /[\/\\]([^\/\\]*)$/ );
    return "";
}

sub dirname_op
#process :dirname postfix op
#return dirname of input var
{
    my ($var) = @_;
    $var =~ s/[\/\\][^\/\\]*$//;
    return $var;
}

sub suffix_op
#process :suffix postfix op
#return suffix of input var
{
    my ($var) = @_;

    return $1 if ( $var =~ /\.([^\.\\\/]*)$/ );
    return "";
}

sub root_op
#process :root postfix op
#return root of input var (i.e., var minus suffix).
{
    my ($var) = @_;

    return $1 if ( $var =~ /^(.*)\.[^\.\\\/]*$/ );
    return $var;
}

sub echo_op
#dump current contents of var to stdout (or current default output handle).
#useful in %void statements to display selected output.
{
    my ($var) = @_;
    print $var;
    return $var;
}

sub print_op
#alias for echo_op
{
    return &echo_op(@_);
}

sub eecho_op
#dump current contents of var to stderr.
{
    my ($var) = @_;
    print STDERR $var;
    return $var;
}

sub eprint_op
#alias for eecho_op
{
    return &eecho_op(@_);
}

sub top_op
#process :top postfix op
#:top - return the top (last in) element on the stack
{
    my ($var) = @_;

    return $var if (!defined($var) || $var eq "");

    my @tmp = split($;, $var, -1);  #note -1 => don't delete trailing empty fields.

#printf STDERR "top_op: var='%s' #tmp=%d\n", $var, $#tmp;
    return (pop @tmp);
}

sub car_op
#alias for :bottom, for lisp affectionados.
{
    return &bottom_op(@_);
}

sub cdr_op
#process :cdr postfix op, which is the stack minus it's :car.
{
    my ($var, $varname) = @_;

    return undef if (!defined($var));

    my @tmp = split($;, $var, -1);  #note -1 => don't delete trailing empty fields.
    shift @tmp;

    #if stack is now empty, return last element, but undef stack:
    if ($#tmp < 0) {
        return sprintf("\${%s:undef}", $varname);
    } else {
        return join($;, @tmp);
    }
}

sub bottom_op
#process :bottom postfix op
#:bottom - return the bottom (first in) element on the stack
{
    my ($var) = @_;

    return "" if ($var eq "");

    my @tmp = split($;, $var, -1);  #note -1 => don't delete trailing empty fields.

#printf STDERR "bottom_op: var='%s' #tmp=%d\n", $var, $#tmp;
    return (shift @tmp);
}

sub showstack_op
#display stack as list with $CG_STACK_DELIMITER separating elements.
{
    my ($var, $varname) = @_;
    return &undefname($varname)  unless (defined($var));

    my @tmp = split($;, $var, -1);  #note -1 => don't delete trailing empty fields.

    my $FS = &lookup_def('CG_STACK_DELIMITER');

    return sprintf("%s", join($FS, @tmp));
}

sub stacksize_op
#process :stacksize postfix op
#:stacksize - return the stacksize of a scalar.
#only variables created by %push will have a stacksize > 1
#undef stack has zero elements.  however an empty string on the stack is
#considered to have one element.
{
    my ($var, $varname) = @_;

    return 0 unless (&var_defined($varname));

    #this is a little confusing, but allows for stacks to have empty elements.
    #i.e., a stack has zero elements only if it is undefined.
    return 1 if ($var eq '');

    my @tmp = split($;, $var, -1);  #note -1 => don't delete trailing empty fields.

#printf STDERR "stacksize_op: varname='%s' value='%s' #tmp=%d\n", $varname, $var, $#tmp;

    return $#tmp +1;
}

sub stackminus_op
#process :stackminus postfix op
#:stackminus - subtract the members of CG_STACK_SPEC from current stack.
{
    my ($var) = @_;

    return $var if ($var eq "");

    my @thisStack = split($;, $var, -1);
#printf STDERR "thisStack=(%s)\n", join(",", @thisStack);
    my $specStack = $CG_USER_VARS{'CG_STACK_SPEC'};
    return $var unless (defined($specStack));

    my @specStack = split($;, $specStack, -1);
#printf STDERR "specStack=(%s)\n", join(",", @specStack);

    my @new = &MINUS(\@thisStack, \@specStack);
#printf STDERR "new=(%s)\n", join(",", @new);

    return join($;, @new);
}

sub unique_op
#process :unique postfix op
#:unique - eliminate duplicate values from a stack, preserving original order
{
    my ($var) = @_;

    return $var if ($var eq "");

    my @thisStack = split($;, $var, -1);

    my (%mark);
    for (@thisStack) { $mark{$_}++;}

    my @new = ();
    for (@thisStack) {
        push(@new, $_) if ($mark{$_});
        $mark{$_} = 0;
    }

#printf STDERR "thisStack=(%s)\n", join(",", @thisStack);
#printf STDERR "new=(%s)\n", join(",", @new);

    return join($;, @new);
}

sub pv_op
#alias for pragmavalue_op.
{
    return &pragmavalue_op(@_);
}

sub pragmavalue_op
#retrieve the value of the pragma named by the contents of a variable, or of
#the variable name if the contents are undefined.
{
    my ($var, $varname, $linecnt) = @_;
    #use varname if contents is undefined:
    my $pragma_name = ( (&isUndefinedVarnameValue($varname,$var) || $var eq "") ? $varname : $var);

#printf STDERR "pragmavalue_op A: varname='%s' var='%s' pragma_name='%s'\n", $varname, $var, $pragma_name;
#printf STDERR "%s='%s'\n", "pragma_preserve_multiline_lnewline", $pragma_preserve_multiline_lnewline;
#printf STDERR "%s='%s'\n", "pragma_trim_multiline_rnewline", $pragma_trim_multiline_rnewline;
#printf STDERR "%s='%s'\n", "pragma_copy", $pragma_copy;
#printf STDERR "%s='%s'\n", "pragma_update", $pragma_update;
#printf STDERR "%s='%s'\n", "pragma_echo_expands", $pragma_echo_expands;
#printf STDERR "%s='%s'\n", "pragma_require", $pragma_require;
#printf STDERR "%s='%s'\n", "pragma_debug", $pragma_debug;
#printf STDERR "%s='%s'\n", "pragma_ddebug", $pragma_ddebug;
#printf STDERR "%s='%s'\n", "pragma_quiet", $pragma_quiet;
#printf STDERR "%s='%s'\n", "pragma_verbose", $pragma_verbose;
#printf STDERR "%s='%s'\n", "pragma_filegen_notices_to_stdout", $pragma_filegen_notices_to_stdout;
#printf STDERR "%s='%s'\n", "pragma_clrifndef", $pragma_clrifndef;


    if ( !defined($PRAGMAS{$pragma_name}) ) {
        printf STDERR "%s: WARNING: '%s' is not a recognized pragma in :pragmavalue expression, line %d\n",
             $p, $pragma_name, $linecnt, join(", ", sort keys %PRAGMAS) unless ($QUIET);
        return "";
    }

    #####
    #look up value of pragma:
    #####

    if ($pragma_name eq 'reset_stack_delimiter') {
        #special case - no real value so just return what we would set it to:
        return "\t";
    }

    my $pragma_var = "pragma_" . $pragma_name;    #this is the variable we set internally.

    no strict "refs";
    my $pragma_ref = \${$pragma_var};
    use strict "refs";

    my $pragma_val = $$pragma_ref;

#printf STDERR "pragmavalue_op: pragma_var='%s' pragma_val='%s'\n", $pragma_var, defined($pragma_val)? $pragma_val : "undef";

    return $pragma_val;
}

sub openfile_op
#process :openfile postfix op
#open a file if it is open. return error string or empty if no error.
{
    my ($fn, $varname) = @_;

    my $fhref = $CG_OPEN_FILE_DESCRIPTORS{$fn};
    my $fhidx = -1;

    if (defined($fhref)) {
        #then close before re-open:
        close $fhref;
        $fhidx = $CG_OPEN_FILE_FD_INDEXES{$fn};
    } else {
        #get the next file reference:
        $fhidx = &get_avaliable_filehandle("open_fileop");

        if ($fhidx < 0) {
            return sprintf("%s: ERROR: out of file descriptors (max is %d).", $p, $LAST_TEMPLATE_FD_KEY+1);
        }

        $fhref = $TEMPLATE_FD_REFS[$fhidx];
    }


    if (!open($fhref, $fn)) {
        &free_filehandle($fhidx, "open_fileop") if ($fhidx >= 0);   #free if we allocated filehandle
        my $errtxt = sprintf("%s", $!);
        return $errtxt unless ($errtxt eq "");
        return "UNKNOWN ERROR";
    }


    #init line contents, count for newly opened file:
    $CG_OFD_CURRENTLINE{$fn} = "";
    $CG_OFD_CURRENTLINECOUNT{$fn} = 0;

    #save file-handle:
    $CG_OPEN_FILE_DESCRIPTORS{$fn} = $fhref;
    $CG_OPEN_FILE_FD_INDEXES{$fn} = $fhidx;

    return "";
}

sub getnextline_op
#process :getnextline postfix op
#get the next line of a file if it is open.
#return varname if line is defined, otherwise, return "".
#undefine varname if file is not open or we have read past the end.
{
    my ($fn, $varname) = @_;

    if ($fn eq "-" || $fn =~ /stdin/i) {
        my $line = <>;
        if (!defined($line)) {
            delete $CG_USER_VARS{$varname} if (defined($CG_USER_VARS{$varname}));
            return "";
        }
        chomp $line;
        $CG_OPEN_FILE_DESCRIPTORS{'<STDIN>'} = '<STDIN>';
        $CG_OFD_CURRENTLINE{'<STDIN>'} = $line;
        ++$CG_OFD_CURRENTLINECOUNT{'<STDIN>'};    #this keeps a tally of how many lines read from stdin

        #we read a line from stdin.
        $CG_USER_VARS{$varname} = '<STDIN>';  #normalize name of stdin
        return $varname;
    }

    my $fhref = $CG_OPEN_FILE_DESCRIPTORS{$fn};
    my $line = <$fhref> if (defined($fhref));

    if (!defined($fhref) || !defined($line)) {
        delete $CG_USER_VARS{$varname} if (defined($CG_USER_VARS{$varname}));
        return "";
    }

    #otherwise, make a copy of current line, and increment line count:
    if (defined($line)) {
        chomp $line;
        $CG_OFD_CURRENTLINE{$fn} = $line;
        ++$CG_OFD_CURRENTLINECOUNT{$fn};
    }

    printf "getnextline_fileop: varname=%s fn=%s line='%s'\n", $varname, $fn, $line if ($DEBUG);

    #return the name of the input variable, for use in %whiledef loops:
    return $varname;
}

sub currentline_op
#process :currentline postfix op
#return the current input line of a file, or undef varname if file is closed
{
    my ($fn, $varname) = @_;

    return $CG_OFD_CURRENTLINE{$fn} if (defined($CG_OFD_CURRENTLINE{$fn}));

    #otherwise, undefine the caller's variable:
    delete $CG_USER_VARS{$varname} if (defined($CG_USER_VARS{$varname}));
    #otherwise, undefine the caller's variable:
    delete $CG_USER_VARS{$varname} if (defined($CG_USER_VARS{$varname}));
    return sprintf('${%s}', $varname);   #same as lookup_def returns.
}

sub currentlinenumber_op
#process :currentlinenumber postfix op
#(1..nlines), 0 => file closed
{
    my ($fn, $varname) = @_;

    return $CG_OFD_CURRENTLINECOUNT{$fn} if (defined($CG_OFD_CURRENTLINECOUNT{$fn}));

    return 0;    #allows %ifnot to detect that file is not open
}

sub closefile_op
#process :closefile postfix op
#close a file if it is open. set $var to error or empty if no error.
{
    my ($fn, $varname) = @_;
    my $fhref = $CG_OPEN_FILE_DESCRIPTORS{$fn};

    if (defined($fhref)) {
        #then close:
        close $fhref;

        #clear variables related to this file:
        delete $CG_OPEN_FILE_DESCRIPTORS{$fn} if (defined($CG_OPEN_FILE_DESCRIPTORS{$fn}));
        delete $CG_OFD_CURRENTLINE{$fn} if (defined($CG_OFD_CURRENTLINE{$fn}));
        delete $CG_OFD_CURRENTLINECOUNT{$fn} if (defined($CG_OFD_CURRENTLINECOUNT{$fn}));

        if (defined($CG_OPEN_FILE_FD_INDEXES{$fn})) {
            &free_filehandle($CG_OPEN_FILE_FD_INDEXES{$fn}, "close_fileop");
            delete $CG_OPEN_FILE_FD_INDEXES{$fn};
        }
    }

    #we don't return any errors for now...

    return "";
}

sub eoltrim_op
#trim whitespace preceeding newlines
{
    my ($var) = @_;
    $var =~ s/[ \t]+\n/\n/g;
    return $var;
}

sub eolsqueeze_op
#compress multiple empty lines into a single empty line.
{
    my ($var) = @_;

    $var =~ s/\n\n\n+/\n\n/g;

    return $var;
}

sub lspace_op
#process :lspace postfix op
#add one space to beginning of string iff it is a non-empty string:
{
    my ($var) = @_;
    $var = " $var" unless ($var eq "");
    return $var;
}

sub rspace_op
#process :rspace postfix op
{
    my ($var) = @_;
    #add one space to end of string iff it is a non-empty string:
    $var = "$var " unless ($var eq "");
    return $var;
}

sub space_op
#process :space postfix op
#use this to add spaces to empty string.
{
    my ($var) = @_;
    return $var = $var . " ";
}

sub rnewline_op
#append trailing (right) newline iff non-empty string.
{
    my ($var) = @_;
    #add one newline to end of string iff it is a non-empty string:
    $var = "$var\n" unless ($var eq "");
    return $var;
}

sub lnewline_op
#process :lnewline postfix op
#insert leading (left) newline iff non-empty string.
{
    my ($var) = @_;
    $var = "\n$var" unless ($var eq "");
    return $var;
}

sub newline_op
#alias for nl_op
{
    return &nl_op(@_);
}

sub nl_op
#append trailing newline unconditionally.
{
    my ($var) = @_;
    return "$var\n";
}

sub fixeol_op
#force at most one newline at the end of the string
{
    my ($var) = @_;

    #ignore empty strings or strings that already have a newline:
    return $var if ($var eq "" || $var =~ /\n$/);

    $var = "$var\n";
    return $var;
}

sub oneline_op
#process :oneline postfix op
#replace \s*EOL\s* sequences with a single space, and trim result:
{
    my ($var) = @_;

    $var =~ s/\s*(\r\n)+\s*/ /g;
    $var =~ s/\s*(\n\r)+\s*/ /g;
    $var =~ s/\s*\n+\s*/ /g;
    $var =~ s/\s*\r+\s*/ /g;

    #trim:
    $var =~ s/^\s+//;
    $var =~ s/\s+$//;

    return $var;
}

sub rangelb_op
#process :rangelb postfix op
#Interpret m..n as a range value.
#    :rangelb => m..n => m
#    :rangeub => m..n => n
#    common behavior
#        strings are trimmed
#        if missing range operator "..", then reflect original value
#        "" => 0
#        m => m
{
    my ($var) = @_;

    #trim leading/trailing whitespace:
    $var = $1 if ($var =~ /^\s*([^\s]+)\s*$/);

    return 0 if ($var eq "");

    my @lbub  = split(/\.\./, $var, 2);

    return $lbub[0] if ($#lbub >= 0);

    return $var;
}

sub rangeub_op
#process :rangeub postfix op
#Interpret m..n as a range value.
#    :rangelb => m..n => m
#    :rangeub => m..n => n
#    common behavior
#        strings are trimmed
#        if missing range operator "..", then reflect original value
#        "" => 0
#        m => m
{
    my ($var) = @_;

    #trim leading/trailing whitespace:
    $var = $1 if ($var =~ /^\s*([^\s]+)\s*$/);

    return 0 if ($var eq "");

    my @lbub  = split(/\.\./, $var, 2);

    return $lbub[0] if ($#lbub == 0);
    return $lbub[1] if ($#lbub == 1);

    return $var;
}

sub isint_op
#process :isint postfix op
#returns 1 if <val> is a positive integer, else zero.
{
    my ($var) = @_;

    return 1 if ( $var =~ /^\s*\d+\s*$/ );
    return 0;
}

sub split_op
#process :split postfix op
#splits variable into a push/pop reference
#default split pattern is /[\t,]/
{
    my ($var) = @_;

    &reset_split_pattern() unless (&var_defined('CG_SPLIT_PATTERN'));
    my $spat = $CG_USER_VARS{'CG_SPLIT_PATTERN'};

    #we are going to make a STACK var out of our var, so we are really just doing
    #a substitute op:
    my $savevar = $var;
    my $result = 0;

#printf STDERR "SPLIT BEFORE spat='%s' var='%s'\n", $spat, $var;
    
    if ($spat =~ /^\/.*\/$/ ) {
        #split spec has slashes.
        eval "\$var =~ s${spat}$;/g";
    } else {
        #split spec has no slashes.
        eval "\$var =~ s/${spat}/$;/g";
    }

#my @rec = split(/$;/, $var, -1);
#printf STDERR "SPLIT AFTER spat='%s' var='%s' rec=(%s) cnt=%d\n", $spat, $var, join(',', @rec), $#rec;

    if ($@) {
        printf STDERR "%s[split]: ERROR: line %d: evaluation of CG_SPLIT_PATTERN (%s) failed for var '%s': %s\n",
            $p, $LINE_CNT, $spat, $var, $@;
        return $savevar;
    } elsif (!defined($result)) {
        #WARNING:  the $@ construct doesn't seem to work on perl 5.005_03.  RT 6/19/06
        printf STDERR "%s[split]: ERROR: line %d: evaluation of CG_SPLIT_PATTERN (%s) failed for var '%s': %s\n",
            $p, $LINE_CNT, $spat, $var, "ERROR in eval" ;
        return $savevar;
    }

    return $var;
}

sub onecol_op
#process :onecol postfix op
{
    my ($var) = @_;

    #trim, then replace \s+ sequences with newlines:
    $var =~ s/^\s+//;
    $var =~ s/\s+$//;
    #Q: should I use \r\n on DOS?
    $var =~ s/\s+/\n/g;

    return $var;
}

sub method2rec_op
#process :method2rec postfix op
#convert a java method signature to a tab separated record:
#parse a line containing a java method signature declaration, and output
#a tab-separated record containing:
#    (method attributes, return type, name(parmeters), exceptions thrown) 
{
    my ($var) = @_;

    #make input easier to parse:
    $var = &oneline_op($var);

    #get rid of any tabs:
    $var =~ s/\t//g;

    #get rid of any terminating semi-colons:
    $var =~ s/\s*;.*$//;

    #get rid of any open-brace expressions:
    $var =~ s/\s*{.*$//; #}

    #pull out throws clause:
    my $throws = "";
    #WARNING: we localize the scope of $1 from the match, as perl leaves the
    #most recent match defined until it is overriden, which means defined($1) is always
    #true after the first match.  not what we want...
    {
        $var =~ s/\s+throws\s+(.*)//;
        $throws = $1 if (defined($1));
    }

#printf STDERR "method2rec: var='%s' throws='%s'\n", $var, $throws;

    #pull out methodname(args...):
    my $name = "";
    {
        #get formal parameters:
        $var =~ s/\s*(\(.*)$//;
        $name = $1 if (defined($1));
        #get method name:
        $var =~ s/\s+(\S+)$//;
        $name = "$1$name" if (defined($1));
    }

#printf STDERR "method2rec: var='%s' name='%s'\n", $var, $name;

    #pull out return type:
    my $returns = "";
    #get array brackets if present:
    {
        $var =~ s/\s*(\[.*)$//;
        $returns = $1 if (defined($1));
        #get return type name
        #note that pattern can start at beginning of line if interface
        #with no attributes, because access attribute (public,private...)  is optional:
        $var =~ s/\s*(\S+)$//;
        $returns = "$1$returns" if (defined($1));
    }

#printf STDERR "method2rec: var='%s' returns='%s'\n", $var, $returns;

    #whatever is left are the method attributes:
    my $attributes = $var;

#printf STDERR "method2rec: var='%s' attributes='%s'\n", $var, $attributes;

    #return tab-separated record:
    return join("\t", $attributes, $returns, $name, $throws);
}

sub ltrim_op
#process :ltrim postfix op
{
    my ($var, $varname, $linecnt) = @_;
    $var =~ s/^\s+//;
    return $var;
}

sub antvar_op
#process :antvar postfix op
#convert to an ant variable reference:
#  $foo:nameof:antvar -> ${foo}.
{
    my ($var) = @_;
    return '$' . "{$var}";
}

sub cgvar_op
#process :cgvar postfix op
#wrap value as an cado template reference - e.g., $foo:nameof:cgvar -> {=foo=}
{
    my ($var) = @_;
    return '{=' . $var . '=}';
}

sub q_op
#wrap contents of var in single quotes.
{
    my ($var) = @_;
    return "'" . $var . "'";
}

sub quote_op
#alias for q_op
{
    return &q_op(@_);
}

sub dq_op
#wrap contents of var in single quotes.
{
    my ($var) = @_;
    return '"' . $var . '"';
}

sub dquote_op
#alias for q_op
{
    return &q_op(@_);
}

sub xmlcommentblock_op
#process :xmlcommentblock postfix op
#wrap $var in multi-line xml comment:
#wrap the input string in an xml comment
{
    my ($var) = @_;

    my $eolpat = "\n";
    if ($var =~ /\r/) {
        #set to use dos line endings:
        $eolpat = "\r\n";
    }

    my @tmp = split($eolpat, $var);

    $var = sprintf("<!--\n # %s\n-->", join("\n # ", @tmp));

#    <!--
#     # this
#     # is a comment
#    -->

    return $var;
}

sub xmlcomment_op
#process :xmlcomment postfix op
#wrap $var in xml comment:
{
    my ($var) = @_;
    return sprintf("<!-- %s -->", $var);
}

sub stripxmlcomments_op
#INPUT:  string containing xml snippet
#OUTPUT: string with xml comments stripped out.
{
    my ($varvalue) = @_;

    $varvalue =~ s/<!--.*?-->//gs;

    return $varvalue;
}

sub tab_op
#process :tab postfix op
#use this to add tabs to empty string.
{
    my ($var) = @_;
    return $var . "\t";
}

sub tolower_op
#process :tolower postfix op
{
    my ($var) = @_;
    $var =~ tr/[A-Z]/[a-z]/;
    return $var;
}

sub toupper_op
#process :toupper postfix op
{
    my ($var) = @_;
    $var =~ tr/[a-z]/[A-Z]/;
    return $var;
}

#init hex decode map:
my %hex_decode_map = map { sprintf( "%02X", $_ ) => chr($_) } ( 0 ... 255 );

sub urlencode_op
{
    my ($value) = @_;
    $value =~ s/([^a-zA-Z_0-9])/"%" . uc(sprintf "%02X" , unpack("C", $1))/egs;
    return ($value);
}

sub urldecode_op
#process :urldecode postfix op
#decode a url encoded string to a regular string.
{
    my ($url) = @_;
    return unless $url;

    # Decode percent encoding
    $url =~ s/%([a-fA-F0-9]{2})/$hex_decode_map{$1}/egs;
    return $url;
}

sub hexencode_op
#process :hexencode postfix op
#encode a regular string to hex representation.
{
    my ($value) = @_;
    $value =~ s/(.)/uc(sprintf "%02X" , unpack("C", $1))/egs;
    return ("HEX_" . $value);
}

sub hexdecode_op
#process :hexdecode postfix op
#decode a hex encoded string to a regular string.
{
    my ($hexstr) = @_;
    return unless $hexstr =~ /^HEX_/;

    $hexstr =~ s/^HEX_//;

    $hexstr =~ s/([A-F0-9]{2})/$hex_decode_map{$1}/egs;
    return $hexstr;
}

sub cap_op
#process :cap postfix op
#this op capitalizes the first letter of a string.
{
    my ($var) = @_;
    #ignore leading spaces:
    $var =~ s/^(\s*)([a-z])(.*)$/$1\u$2$3/;
    return $var;
}

sub uncap_op
#process :uncap postfix op
#this op uncapitalizes the first letter of a string.
{
    my ($var) = @_;
    #ignore leading spaces:
    $var =~ s/^(\s*)([A-Z])(.*)$/$1\l$2$3/;
    return $var;
}

sub i_op
#alias for :incr
{
    return &incr_op(@_);
}

sub incr_op
#process :incr postfix op
{
    my ($var) = @_;

    #we do fixed-width increment, e.g., 001, 002, ... 999
    my $tmp = $var; $tmp =~ s/^\s*[-+]\s*//;
    $var = sprintf "%.*d", length($tmp), $var+1;

    return $var;
}

sub decr_op
#process :decr postfix op
{
    my ($var) = @_;

    #we do fixed-width decrement, e.g., 999, 998, ... 000;
    my $tmp = $var; $tmp =~ s/^\s*[-+]\s*//;
    $var = sprintf "%.*d", length($tmp), $var-1;

    return $var;
}

sub env_op
#process :env postfix op
{
    my ($var, $varname, $linecnt) = @_;

    #use varname if contents is undefined:
    my $env_name = (&isUndefinedVarnameValue($varname,$var) ? $varname : $var);

    if (defined($ENV{$env_name})) {
        $var = $ENV{$env_name};
    } else {
        printf STDERR "%s: WARNING: line %d:  \$%s:%s is UNDEFINED.\n", $p, $linecnt, $env_name, "env" if ($VERBOSE);
        $var = "";
    }

    return $var;
}

sub pwd_op
#process :pwd postfix op
{
    my ($var) = @_;

    #use the system library since it is more portable:
    use Cwd;
    $var = getcwd();

    return $var;
}

sub freq_op
#process :freq postfix op
#get the frequency of each line, and ouput in the form:
#  <cnt><tab><unique_lines>
#where <unique_lines> is the original data with leading/trailing whitespace trimmed
{
    my ($var) = @_;
    my $eolpat = "\n";
    if ($var =~ /\r/) {
        #set to use dos line endings:
        $eolpat = "\r\n";
    }
    my @tmp = split($eolpat, $var);

#printf STDERR "freq: tmp=(%s)\n", join(',', @tmp);

    #this is much faster than a for loop:
    @tmp = grep (s/^\s*//, @tmp);
    @tmp = grep (s/\s*$//, @tmp);

    #now count unique occurances:
    my %FREQ = ();
    grep (++$FREQ{$_}, @tmp);

#printf "keys FREQ=(%s)\n", join(",", sort keys %FREQ);
#printf "values FREQ=(%s)\n", join(",", sort values %FREQ);

    @tmp = grep($_ = "$FREQ{$_}\t$_", sort keys %FREQ);

    return join("\n", @tmp);
}

sub nameof_op
#process :nameof postfix op
{
    my ($var, $varname) = @_;
    return $varname;
}

sub valueof_op
#process :valueof postfix op
{
    my ($var, $varname, $linecnt) = @_;

    #show the value of the variable named by $var:
    if (&var_defined($var)) {
        $var = $CG_USER_VARS{$var};
    } else {
        printf STDERR "%s: WARNING: line %d:  \$%s:%s is UNDEFINED\n", $p, $linecnt, $var, "valueof" unless ($QUIET);
        $var = sprintf("\${%s:undef}", $varname);;
    }

    return $var;
}

sub a_op
#alias for :assign
{
    return &assign_op(@_);
}

sub assign_op
#process :assign postfix op
{
    my ($var, $varname, $linecnt) = @_;

    #update the value of $var:
    $CG_USER_VARS{$varname} = $var;
    printf STDERR "eval_postfix_op:  var='%s' CG_USER_VARS{%s}='%s'\n", $var, $varname, $CG_USER_VARS{$varname} if ($DEBUG);

    return $var;
}

sub append_op
#process :append postfix op - append a value to a variable.
{
    my ($var, $varname, $linecnt) = @_;

    $CG_USER_VARS{$varname} = "" unless (defined($CG_USER_VARS{$varname}));
    $CG_USER_VARS{$varname} .= $var;
    printf STDERR "eval_postfix_op:  var='%s' CG_USER_VARS{%s}='%s'\n", $var, $varname, $CG_USER_VARS{$varname} if ($DEBUG);

    return $var;
}

sub insert_op
#process :insert postfix op - prepend a value to a variable.
{
    my ($var, $varname, $linecnt) = @_;

    $CG_USER_VARS{$varname} = "" unless (defined($CG_USER_VARS{$varname}));
    $CG_USER_VARS{$varname} = $var . $CG_USER_VARS{$varname};

    printf STDERR "eval_postfix_op:  var='%s' CG_USER_VARS{%s}='%s'\n", $var, $varname, $CG_USER_VARS{$varname} if ($DEBUG);

    return $var;
}

sub clr_op
#set a variable to empty string.
{
    my ($var, $varname, $linecnt) = @_;
    return &assign_op("", $varname, $linecnt);
}

sub clrifndef_op
#clear variable if it is not defined
{
    my ($var, $varname, $linecnt) = @_;

    if (!defined($CG_USER_VARS{$varname})) {
        return &assign_op("", $varname, $linecnt);
    }

    return $var;
}

sub zero_op
#set a variable to zero.
{
    my ($var, $varname, $linecnt) = @_;
    return &assign_op(0, $varname, $linecnt);
}

my @RCS_KEYWORDS = (
        "Author",
        "Date",
        "Header",
        "Id",
        "Locker",
        "Log",
        "Name",
        "RCSfile",
        "Revision",
        "Source",
        "State",
    );

sub stripRcsKeywords_op
#strip all RCS keywords from the string
{
    my ($var) = @_;

    #optimization - don't look at strings unless there is at
    #least one possible rcs keyword sequence:
    return $var unless ($var =~ /\$[A-Z][a-z]/ );

    for my $kw (@RCS_KEYWORDS) {
        #this will only strip keywords that are properly terminated.
        #for example, $Id .. <EOL>  will not be touched,
        #but $Id ... $ will be deleted.
        $var =~ s/\$$kw[^\$\n]*\$//g
    }

    return $var;
}

sub crcfile_op
#return the crc of the file named by the string.
#open the file directly, and if that fails, look in CG_ROOT.
#return zero if file is not readable, otherwise,
#hex number representing the crc.
{
    my ($fn) = @_;
    my $crc = "0";

    #if we can read file directly...
    if ( -r $fn ) {
        $crc =  sprintf("%x", &pcrc::CalculateFileCRC($fn));
        return "$crc";
    } else {
        #otherwise, look in CG_ROOT:
        my ($cgfn) = &path::mkpathname($CG_USER_VARS{'CG_ROOT'}, $fn);

        if ( -r $cgfn ) {
            $crc =  sprintf("%x", &pcrc::CalculateFileCRC($cgfn));
            return "$crc";
        }
    }

    return "0";    #return zero if we cannot open file
}

sub crcstr_op
#return the crc of the contents of a string
{
    my ($var) = @_;

    my $tmpfile_fullpath = &write_string_to_cg_tmp_file($var);
    if ($tmpfile_fullpath eq "NULL") {
        #we treat this as an internal error (as opposed to a user error):
        printf STDERR "%s[%s]: ERROR: line %d: cannot create temp file.\n",
            $p, "crcstr_op", $LINE_CNT unless ($QUIET);
        ++ $GLOBAL_ERROR_COUNT;
        return "0";    #return zero if we cannot open file
    }

    #return crc of temp file containing string:
    my $crc = &crcfile_op($tmpfile_fullpath);
    unlink $tmpfile_fullpath;
    return $crc;
}

sub crc_op
#return crcfile, and if that fails, crcstr.
#use explicit ops if you want to force it one way or the other.
{
    my ($var) = @_;
    my $crc = 0;

    $crc =  &crcfile_op($var);
    return $crc if ( $crc ne "0" );

    #otherwise, return crc of string:
    return &crcstr_op($var);
}


sub r_op
#return non-zero if file is readable.
{
    my ($fn) = @_;
    return 0 if (!defined($fn) || $fn eq "");
    return (-r $fn)? 1 : 0;
}

sub w_op
#return non-zero if file is writable.
{
    my ($fn) = @_;
    return 0 if (!defined($fn) || $fn eq "");
    return (-w $fn)? 1 : 0;
}

sub x_op
#return non-zero if file is executable.
{
    my ($fn) = @_;
    return 0 if (!defined($fn) || $fn eq "");
    return (-x $fn)? 1 : 0;
}

sub e_op
#return non-zero if file is exists.
{
    my ($fn) = @_;
    return 0 if (!defined($fn) || $fn eq "");
    return (-e $fn)? 1 : 0;
}

sub z_op
#return non-zero if file is zero length.
{
    my ($fn) = @_;
    return 0 if (!defined($fn) || $fn eq "");
    return (-z $fn)? 1 : 0;
}

sub sz_op
#return non-zero if file is non-zero size (returns size).
{
    my ($fn) = @_;
    return 0 if (!defined($fn) || $fn eq "");
    return (-s $fn)? 1 : 0;
}

sub f_op
#return non-zero if file is plain file.
{
    my ($fn) = @_;
    return 0 if (!defined($fn) || $fn eq "");
    return (-f $fn)? 1 : 0;
}

sub d_op
#return non-zero if file is directory.
{
    my ($fn) = @_;
    return 0 if (!defined($fn) || $fn eq "");
    return (-d $fn)? 1 : 0;
}

sub l_op
#return non-zero if file is symlink.
{
    my ($fn) = @_;
    return 0 if (!defined($fn) || $fn eq "");
    return (-l $fn)? 1 : 0;
}

sub T_op
#return non-zero if file is Text file.
{
    my ($fn) = @_;
    return 0 if (!defined($fn) || $fn eq "");
    return (-T $fn)? 1 : 0;
}

sub B_op
#return non-zero if file is Binary file.
{
    my ($fn) = @_;
    return 0 if (!defined($fn) || $fn eq "");
    return (-B $fn)? 1 : 0;
}


#
#ant_ops.pl - operate on ant files
#

#this is a global hash for storing all ant properties.
my %ANTPROPS = ();

sub expand_antrefs_op
#look-up all ant var references in input.  if we have a defnition, then substitute
#reference with its definition.  one pass only.
{
    my ($varvalue) = @_;

    $varvalue =~ s/(\${[^}]*?})/&lookup_ant_ref($1)/ge;

    return $varvalue;
}

sub expand_antprops_op
#retrieve the ant properties and expand any variable references that are defined
#INPUT:   %ANTPROPS (must be initialized via :parse_antprops)
#OUTPUT:  the stack of ant property names.
{
    my ($varvalue) = @_;

    my ($lasthash) = "0";
    my ($keyhash) = &antpropnames_op($varvalue);

    #the return value is the full stack, which we will now proceed to expand:
    $varvalue = $keyhash;

#printf STDERR "\nkeyhash=(%s) lasthash=(%s)\n", join(",", split($;, $keyhash)), join(",", split($;, $lasthash));
    #while more variables to expand ...
    while (($keyhash = &getunexpanded_antvars($keyhash)) ne $lasthash) {
#printf STDERR "\nLOOP:\tkeyhash=(%s) lasthash=(%s)\n", join(",", split($;, $keyhash)), join(",", split($;, $lasthash));
        $lasthash = $keyhash;
    }

    return $varvalue;
}

sub getunexpanded_antvars
#pass through list of ant props supplied, expanding prop value having ant var refs.
{
    my ($keyhash) = @_;

    return "" if (!defined($keyhash) || $keyhash eq "");

    my (@listin) = split($;, $keyhash);
    my (@listout) = ();

#printf STDERR "\nEXPAND:\tlistin=(%s)\n", join(",", @listin);

    foreach my $kk (@listin) {
        my ($vv);
        if (defined($vv = $ANTPROPS{$kk}) && &has_ant_var_refs($vv)) {
            my ($tmp) = &expand_antrefs_op($vv);
#printf STDERR "\nEXPAND LOOP:\tkk='%s' vv='%s' tmp='%s'\n", $kk, $vv, $tmp;

            #if expanded var has more refs, then refs are either undefined are not yet fully expanded:
            push(@listout, $kk) if (&has_ant_var_refs($vv));

            $ANTPROPS{$kk} = $tmp;
        }
    }

    return "" if ($#listout < 0);

    return join($;, @listout);
}

sub has_ant_var_refs
#true if input has ant variable refs, e.g. ${foo}
{
    my ($txt) = @_;

    return 1 if ($txt =~ /\${([^}]*?)}/);

    return 0;
}

sub lookup_ant_ref
#look up the value of an ant reference.  if not found,
#return the input.
{
    my ($varref) = @_;

    if ($varref =~ /^\${([^}]*?)}/) {
        return &antpropvalue_op($1);
    } else {
        #ERROR
        printf STDERR "lookup_ant_ref: PARSE ERROR FOR INPUT '%s'\n", $varref;
    }

    return $varref;
}


sub antpropvalue_op
#look up the value of an ant property.
#INPUT:  name of ant prop
#OUPUT:  value of ant prop
{
    my ($varvalue) = @_;

    return $ANTPROPS{$varvalue} if (defined($ANTPROPS{$varvalue}));

    #otherwise return an undefined var like ant would:
    return &antvar_op($varvalue);
}

sub antpropnames_op
#return all the ant property names as a cado stack.
{
    my ($varvalue) = @_;

    #note - cado stacks use $; as separator:
    $varvalue = join($;, sort keys %ANTPROPS);

    return $varvalue;
}

sub clear_antprops_op
#clear the global ANTPROPS storage
{
    my ($varvalue) = @_;

    %ANTPROPS = ();

    return $varvalue;
}

sub parse_antprops_op
#INPUT:  string containing ant project xml (or snippet)
#OUTPUT: <property> elements with cado legal vars; references also translated
#SIDE EFFECT:  populates global ANTPROPS hash with all ant properties.
#e.g:
#   <property name="foo.com-one" value="one,two,three"  />
#   <echo>foo.com-one=${foo.com-one}</echo>
#results in:
#   <property name="foo_com_one" value="one,two,three"  />
#   <echo>foo.com-one=${foo_com_one}</echo>
#and creates cado var:
#   _antVar_foo_com_one  = one,two,three
#
#does not handle collisions in vars that hash to the same cado variable name,
# e.g. ${foo.com} and ${foo-com}  will both map to:  $_antVar_foo_com
{
    my ($varvalue, $varname, $linecnt) = @_;

    #note:  varvalue contains the ant script.

    #strip comments:
    my ($str) = stripxmlcomments_op($varvalue);

    #iterate through the string and store the properties in our array:
    $str =~ s/<property\s+name="([^"]*)"\s+(value|refid)="([^"]*)"\s*[^\/]*\/>/&store_antprop($1, $2, $3)/ge;

    #return input for futher ops:
    return $varvalue;
}

sub store_antprop
#store an ant property in our global ANTPROPS hash
{
    my ($name, $type, $value) = @_;

#printf STDERR "\nstore_antprop:  name='%s' type='%s' value='%s'\n", $name, $type, $value;

    #note - we don't store refid's because we don't have the code to interprolate them:
    $ANTPROPS{$name} = $value if ($type eq "value");

    #return a normalized form for the substitution op:
    return sprintf("<property name=\"%s\" %s=\"%s\"/>\n",$name, $type, $value);
}

sub property_match
#internal function to parse ant <property> elements.
#DEPRECATED - not used
{
    my ($antprops, $str) = @_;

    return "" unless ($str =~ /<property/);
    $str =~ s/^.*?<property/<property/s;

#printf STDERR "property_match:  str='%s'\n", $str;

    if ($str =~  /^<property\s+name="([^"]*)"\s+(value|refid)="([^"]*)"\s*[^\/]*\/>/s ) {
        my ($name, $type, $value) = ($1, $2, $3);
        $str =~ s/^<property\s+name="([^"]*)"\s+(value|refid)="([^"]*)"\s*[^\/]*\/>//s;

#printf STDERR "property_match:  name='%s' value='%s'\n", $name, $value;

        #note - we don't store refid's because they are not usable:
        $$antprops{$name} = $value if ($type eq "value");
        return $str;
    }

    printf STDERR "property_match:  ERROR:  parse failed\n";
    return "";
}

sub showantvars_op
#dump the ant properties
{
    my ($varvalue) = @_;

    $varvalue = "";
    foreach my $kk (sort keys %ANTPROPS) {
        $varvalue .= sprintf("<property name=\"%s\" value=\"%s\"/>\n", $kk, $ANTPROPS{$kk});
    }

    return $varvalue;
}

sub isantprop_op
#return 1 if input is the name of an ant property, otherwise 0.
{
    my ($varvalue) = @_;

    return 1 if ( defined($ANTPROPS{$varvalue}) );
    return 0;
}


sub factorCshVars_op
{
    my ($var, $varname, $linecnt) = @_;
    my $prefix = "cshvar_";
    my $xpat = "";
    my $ipat = "";

    #output intermediate variables:
    my $shvardeftxt = "";
    my (@shvars) = ();
    my (@cgshvars) = ();
    my (@shvarvals) = ();

    if ( &var_defined_non_empty("CG_CSHVAR_PREFIX") ) {
        $prefix = $CG_USER_VARS{'CG_CSHVAR_PREFIX'}          
    } else {
        #otherwise, initialize prefix to the default so user can retrieve it:
        &assign_op($prefix, 'CG_CSHVAR_PREFIX', $linecnt);
    }

    $xpat =   $CG_USER_VARS{'CG_CSHVAR_EXCLUDE_PATTERN'} if ( &var_defined_non_empty("CG_CSHVAR_EXCLUDE_PATTERN") );
    $ipat =   $CG_USER_VARS{'CG_CSHVAR_INCLUDE_PATTERN'} if ( &var_defined_non_empty("CG_CSHVAR_INCLUDE_PATTERN") );

    #remove leading/trailing slashes if necessary:
    ($xpat =~ s|^/|| && $xpat =~ s|/$||) unless ($xpat eq "");
    ($ipat =~ s|^/|| && $ipat =~ s|/$||) unless ($ipat eq "");

    #clear output variables:
    &assign_op("", 'CG_CSHVAR_DEFS', $linecnt);
    &assign_op("", 'CG_CSHVAR_LIST', $linecnt);
    &assign_op("", 'CG_CSHVARVAL_LIST', $linecnt);

    #variable reference forms for csh:
    #    set foo = (xx yy zz)
    #    echo form1=$?foo
    #    echo form2=${?foo}
    #    echo form3=$#foo
    #    echo form4=${#foo}
    #    echo form5=$foo[2]
    #    echo form6=${foo[2]}
    
    #####
    #LOOP 1 - find variable initializations and save them:
    #####

    ##########
    #eliminate continuation lines, and split variable text.
    #RE patterns used below are line-by-line based, and do not handle continuation lines.
    #TODO:  handle multi-line statements.  this is currently handled poorly.
    ##########
    $var =~ s/\\\n//sg;
    my (@var) = split("\n", $var, -1);

    my $set_def = 'set\s+([a-z_A-Z]\w*)\s*=';
    my $env_def = 'setenv\s+([a-z_A-Z]\w*)(\s|$)';
    my $re_ref = '\$\{?[#?]?([a-z_A-Z]\w*)';

    my $vptr = "";
    foreach $vptr (@var) {
        my $line = $vptr;  #make a copy otherwise will rewrite input

        #skip comments, empty lines:
        next if ($line =~ /^\s*#/ || $line =~ /^\s*$/);

        while ($line =~ /$set_def/ || $line =~ /$env_def/ || $line =~ /$re_ref/) {
            my $shvname = $1;
            $line =~ s/$shvname//;

            #ignore if we are excluding this variable name:
            next if ( &sh_name_is_excluded($shvname, $ipat, $xpat) );

            #otherwise, we have a var - add to list:
            push @shvars, $shvname;
        }
    }

    #eliminate duplicates, preserving order:
    my %VARVALS = ();
    my (@tmp) = ();
    for (@shvars) {
        next if (defined($VARVALS{$_}));
        $VARVALS{$_} = 0;   #later used to generate macro names for values assigned to this var.
        push @tmp, $_;
    }
    @shvars = @tmp;

    #create output array for CG_CSHVAR_LIST
    @cgshvars = @shvars;
    grep($_ =~ s/^/${prefix}/, @cgshvars);

#printf STDERR "cgshvars=(%s)\n", join(",", @cgshvars);

    #####
    #LOOP 2 - foreach var def, substitute in macro name:
    #####

    #sort backwards so longest variable names are applied first:
    my $shvar = "";
    foreach $shvar (sort { $b cmp $a } @shvars) {
        my $cg_shvar = "$prefix$shvar";
        my $macroref = "{##$cg_shvar##}";    #use temp delimiters for macro brackets

        my $re_def = '(set\s+)' . $shvar . '(\s*=)';
        my $re_ref = '(\$\{?[#?]?)' . $shvar;
        my $re_iden = '(\s|#)' . $shvar . '($|\s|[\-\.,;&|])';

        #do substitutions for defs & refs:
        grep($_ =~ s/$re_def/$1${macroref}$2/g, @var);
        grep($_ =~ s/$re_ref/$1${macroref}/g, @var);
        grep(/^\s*(setenv\s|unsetenv\s|unset\s|#)/ && $_ =~ s/$re_iden/$1${macroref}$2/g, @var);
    }

    #####
    #LOOP 3 - foreach var def, create uniquely numbered rhs value definitions
    #####

    #sort backwards so longest variable names are applied first:
    $shvar = "";
    foreach $shvar (sort { $b cmp $a } @shvars) {
        my $cg_shvar = "$prefix$shvar";
        my $macroref = "{##$cg_shvar##}";    #use temp delimiters for macro brackets

        #generate variable definition:
        $shvardeftxt .= sprintf("\n%s := %s\n", $cg_shvar, $shvar);

        #for each definitional instance, create value variables:
        my ($varvaltxt, $lref, $cg_varval, $varval_macro, $issetenv);
        for (@var) {
            $lref = \$_;
            if ($$lref =~ /setenv[ \t]+(${macroref})[ \t]+(.*)$/) {
                $varvaltxt = $2;
                $issetenv = 1;
            } elsif ($$lref =~ /set[ \t]+(${macroref})[ \t]*=[ \t]*(.*)$/) {
                $varvaltxt = $2;
                $issetenv = 0;
            } else {
                #line does not contain set or setenv pattern:
                next;
            }

            $varvaltxt  =~ s/{##/{=/g;
            $varvaltxt  =~ s/##}/=}/g;
#printf "line='%s' 1='%s' 2='%s' varvaltxt='%s'\n", $$lref, $1, $2, $varvaltxt;

            $cg_varval = sprintf("%s_val%02d", $cg_shvar, ++$VARVALS{$shvar});
            push(@shvarvals, $cg_varval);
            $varval_macro = "{##$cg_varval##}";

            #this only does first substitution - does not work on multi-statement lines
            #or assignments with continuation lines:
            if ($issetenv) {
                $$lref =~ s/(setenv[ \t]+${macroref}[ \t]+)(.*)$/$1${varval_macro}/;
            } else {
                $$lref =~ s/(set[ \t]+${macroref}[ \t]*=[ \t]*)(.*)$/$1${varval_macro}/;
            }

            #add var-value definition:
            $shvardeftxt .= sprintf("%s := %s\n", $cg_varval, $varvaltxt);
        }
    }

    #substitute in correct macro brackets:
    grep($_ =~ s/{##/{=/g, @var);
    grep($_ =~ s/##}/=}/g, @var);

    ######
    #write variable text instrumented with macros:
    ######
    $var = join("\n", @var);

    ######
    #write results to user vars:
    ######
    my $FS = &lookup_def('CG_STACK_DELIMITER');

    #overwrite results if we had any:
    &assign_op($shvardeftxt, 'CG_CSHVAR_DEFS', $linecnt)          if ($shvardeftxt ne "");;
    &assign_op(join($FS, @cgshvars), 'CG_CSHVAR_LIST', $linecnt)     if ($#cgshvars >= 0);
    &assign_op(join($FS, @shvarvals), 'CG_CSHVARVAL_LIST', $linecnt) if ($#shvarvals >= 0);

    return $var;
}

sub factorShVars_op
{
    my ($var, $varname, $linecnt) = @_;
    my $prefix = "shvar_";
    my $xpat = "";
    my $ipat = "";

    #output intermediate variables:
    my $shvardeftxt = "";
    my (@shvars) = ();
    my (@cgshvars) = ();
    my (@shvarvals) = ();

    if ( &var_defined_non_empty("CG_SHVAR_PREFIX") ) {
        $prefix = $CG_USER_VARS{'CG_SHVAR_PREFIX'}          
    } else {
        #otherwise, initialize prefix to the default so user can retrieve it:
        &assign_op($prefix, 'CG_SHVAR_PREFIX', $linecnt);
    }

    $xpat =   $CG_USER_VARS{'CG_SHVAR_EXCLUDE_PATTERN'} if ( &var_defined_non_empty("CG_SHVAR_EXCLUDE_PATTERN") );
    $ipat =   $CG_USER_VARS{'CG_SHVAR_INCLUDE_PATTERN'} if ( &var_defined_non_empty("CG_SHVAR_INCLUDE_PATTERN") );

    #remove leading/trailing slashes if necessary:
    ($xpat =~ s|^/|| && $xpat =~ s|/$||) unless ($xpat eq "");
    ($ipat =~ s|^/|| && $ipat =~ s|/$||) unless ($ipat eq "");

    #clear output variables:
    &assign_op("", 'CG_SHVAR_DEFS', $linecnt);
    &assign_op("", 'CG_SHVAR_LIST', $linecnt);
    &assign_op("", 'CG_SHVARVAL_LIST', $linecnt);

    #
    #Q:  what about when an equals appears in a string?  i.e., "foo=$foo" or 'foo=$foo'
    #Q:  what an equals appears in an echo or printf statement?
    #Q:  what if the equals is backslash escaped to the next line?  i.e.:
    #    foo\
    #    =xxx
    #

    #####
    #LOOP 1 - find variable initializations and save them:
    #####

    ##########
    #eliminate continuation lines, and split variable text.
    #RE patterns used below are line-by-line based, and do not handle continuation lines.
    #TODO:  handle multi statement lines (delimited by ; etc).  this is currently not handled.
    ##########
    $var =~ s/\\\n//sg;
    my (@var) = split("\n", $var, -1);

    #init regular expressions defining sh variable defs and refs:
    my $re_def = '([a-z_A-Z]\w*)=';
    my $re_ref = '\$\{?([a-z_A-Z]\w*)';

    my $vptr = "";
    foreach $vptr (@var) {
        my $line = $vptr;  #make a copy otherwise will rewrite input
        #skip comments, empty lines:
        next if ($line =~ /^\s*#/ || $line =~ /^\s*$/);

        while ($line =~ /$re_def/ || $line =~ /$re_ref/) {
            my $shvname = $1;
            $line =~ s/$shvname//;

            #ignore if we are excluding this variable name:
            next if ( &sh_name_is_excluded($shvname, $ipat, $xpat) );

            #otherwise, we have a var - add to list:
            push @shvars, $shvname;
        }
    }

    #eliminate duplicates, preserving order:
    my %VARVALS = ();
    my (@tmp) = ();
    for (@shvars) {
        next if (defined($VARVALS{$_}));
        $VARVALS{$_} = 0;   #later used to generate macro names for values assigned to this var.
        push @tmp, $_;
    }
    @shvars = @tmp;

    #create output array for CG_SHVAR_LIST
    @cgshvars = @shvars;
    grep($_ =~ s/^/${prefix}/, @cgshvars);

#printf STDERR "cgshvars=(%s)\n", join(",", @cgshvars);

    #####
    #LOOP 2 - foreach var def, substitute in macro name:
    #####

    #sort backwards so longest variable names are applied first:
    my $shvar = "";
    foreach $shvar (sort { $b cmp $a } @shvars) {
        my $cg_shvar = "$prefix$shvar";
        my $macroref = "{##$cg_shvar##}";    #use temp delimiters for macro brackets

        my $re_def = '(^|\s|[;&|])' . $shvar . '(=)';
        my $re_ref = '(\$\{?)' . $shvar;
        my $re_iden = '(\s|#)' . $shvar . '($|\s|[\-\.,;&|])';


#printf "processing shvar '%s' re_ref='%s'\n", $cg_shvar, $re_ref;

        #do substitutions for defs & refs:
        grep($_ =~ s/$re_def/$1${macroref}$2/g, @var);
        grep($_ =~ s/$re_ref/$1${macroref}/g, @var);
        grep(/^\s*(export\s|unset\s|#)/ && $_ =~ s/$re_iden/$1${macroref}$2/g, @var);
    }

    #####
    #LOOP 3 - foreach var def, create uniquely numbered rhs value definitions
    #####

    $shvar = "";
    foreach $shvar (sort { $b cmp $a } @shvars) {
        my $cg_shvar = "$prefix$shvar";
        my $macroref = "{##$cg_shvar##}";    #use temp delimiters for macro brackets

        #generate variable definition:
        $shvardeftxt .= sprintf("\n%s := %s\n", $cg_shvar, $shvar);

        #for each definitional instance, create value variables:
        my ($varvaltxt, $lref, $cg_varval, $varval_macro);
        for (@var) {
            $lref = \$_;
            next unless ($$lref =~ /(${macroref})=(.*)$/);
            $varvaltxt = $2;
#printf "line='%s' 1='%s' 2='%s' varvaltxt='%s'\n", $$lref, $1, $2, $varvaltxt;
            $varvaltxt  =~ s/{##/{=/g;
            $varvaltxt  =~ s/##}/=}/g;

            $cg_varval = sprintf("%s_val%02d", $cg_shvar, ++$VARVALS{$shvar});
            push(@shvarvals, $cg_varval);
            $varval_macro = "{##$cg_varval##}";

            #this only does first substitution - does not work on multi-statement lines
            #or assignments with continuation lines:
            $$lref =~ s/(${macroref})=(.*$)/$1=${varval_macro}/;

            #add var-value definition:
            $shvardeftxt .= sprintf("%s := %s\n", $cg_varval, $varvaltxt);
        }
    }

    #substitute in correct macro brackets:
    grep($_ =~ s/{##/{=/g, @var);
    grep($_ =~ s/##}/=}/g, @var);

    ######
    #write variable text instrumented with macros:
    ######
    $var = join("\n", @var);

    ######
    #write results to user vars:
    ######
    my $FS = &lookup_def('CG_STACK_DELIMITER');

    #overwrite results if we had any:
    &assign_op($shvardeftxt, 'CG_SHVAR_DEFS', $linecnt)          if ($shvardeftxt ne "");;
    &assign_op(join($FS, @cgshvars), 'CG_SHVAR_LIST', $linecnt)     if ($#cgshvars >= 0);
    &assign_op(join($FS, @shvarvals), 'CG_SHVARVAL_LIST', $linecnt) if ($#shvarvals >= 0);

    return $var;
}

sub factorShSubs_op
{
    my ($var, $varname, $linecnt) = @_;
    my $prefix = "shsub_";
    my $xpat = "";
    my $ipat = "";

    if ( &var_defined_non_empty("CG_SHSUB_PREFIX") ) {
        $prefix = $CG_USER_VARS{'CG_SHSUB_PREFIX'}          
    } else {
        #otherwise, initialize prefix to the default so user can retrieve it:
        &assign_op($prefix, 'CG_SHSUB_PREFIX', $linecnt);
    }

    $xpat =   $CG_USER_VARS{'CG_SHSUB_EXCLUDE_PATTERN'} if ( &var_defined_non_empty("CG_SHSUB_EXCLUDE_PATTERN") );
    $ipat =   $CG_USER_VARS{'CG_SHSUB_INCLUDE_PATTERN'} if ( &var_defined_non_empty("CG_SHSUB_INCLUDE_PATTERN") );

    #remove leading/trailing slashes if necessary:
    ($xpat =~ s|^/|| && $xpat =~ s|/$||) unless ($xpat eq "");
    ($ipat =~ s|^/|| && $ipat =~ s|/$||) unless ($ipat eq "");

    #clear output variables:
    &assign_op("", 'CG_SHSUB_DEFS', $linecnt);
    &assign_op("", 'CG_SHSUB_LIST', $linecnt);

    #INPUT:
    # a()
    # {
    #     echo sub a: $v_1
    # }
    # 
    # b (  ){
    #     echo sub b: $v2
    #     }
    # 
    # # c() { echo sub c }
    # 
    # c()
    # {
    # echo sub c: $V3
    # }
    #
    # _123()
    # {
    # echo sub _123
    # a=${v2}
    # }
    #
    #OUTPUT:
    # {=shsub_a=}
    # {=shsub_b=}
    # #c() { echo sub c }
    # {=shsub_c=}
    # {=shsub__123=}
    #
    #NOTES:
    # - brackets are only used in var refs & subroutine defs.
    # - expression below requires at least one newline before each subrouting declaration.
    #   this means that we will miss subroutines declared in first line of file.
    # - note the use of .+? in the expression.  this forces the engine to match the first
    #{  instance of \n\s*} which terminates the subroutine def.  otherwise, it would do
    #   a "greedy" match, and match the last instance.
    # - the /so modifiers treat the multi-line string as a single string,
    #   and compile the pattern only once.

    my %shsub_defs = ();
    my %shsub_names = ();
    my @cg_srnames_initial = ();
    my $re = '\n([\t ]*)([a-z_A-Z]\w*)(\s*\(\s*\)[^{]*\{.+?\n\s*\})(\s*?)\n';
    #} match bracket
    my ($cg_srname, $srtxt, $srname, $wsp_leading, $wsp_trailing) = ("", "", "", "", "");

    #####
    #LOOP 1 - parse subroutines declarations and save them:
    #####

    #prepend newline to fix bug where subroutine not detected if declared on first line:
    #later, we will remove it.  fixed in 1.72.  RT 1/7/09
    $var = "\n" . $var;

    while ($var =~ /$re/so ) {
        $wsp_leading = $1;
        $srname = $2;
        $srtxt = "$2$3";
        $wsp_trailing = $4;
        $cg_srname = "$prefix$srname";

#printf "srtxt='%s'\n", $srtxt;

        my $repl = sprintf("\n%s{=%s=}%s\n", $wsp_leading, $cg_srname, $wsp_trailing);

        #replace the subroutine text with the generated cg macro name:
        $var =~ s/$re/$repl/so;

        #save the name and text of the subroutine:
        $shsub_defs{$cg_srname} = $srtxt;
        $shsub_names{$cg_srname} = $srname;

        #push the cg sr name on to preserve order of input:
        push @cg_srnames_initial, $cg_srname;
    }

#printf "INTERMEDIATE VAR=,%s,\n", $var;

    my (@srnames) = ();
    my (@cg_srnames_final) = ();

    #####
    #LOOP 2  - restore the original text for subroutines we are ignoring.
    #####

    #####
    foreach $cg_srname (@cg_srnames_initial) {
        $srtxt = $shsub_defs{$cg_srname};
        $srname = $shsub_names{$cg_srname};
        my $macroref = "{=$cg_srname=}";

        #if this subroutine is excluded by name...
        if ( &sh_name_is_excluded($srname, $ipat, $xpat) ) {
            #... then restore original text in the input:
            $var =~ s/$macroref/$srtxt/s;

            next;   #do not output text or variable if we are excluding
        }

        #otherwise, append to user variables:  definition text, and subroutine name list:
        push @srnames, $srname;
        push @cg_srnames_final, $cg_srname;
    }

    #####
    #LOOP 3 - replace references to factored subroutines with macros:
    #####

    #now it is safe to remove prepended newline:
    $var =~ s/^\n//;

    #split variable text:
    my (@var) = split("\n", $var, -1);

    #sort backwards so longest variable names are applied first:
    foreach $cg_srname (sort { $b cmp $a } @cg_srnames_final) {
        $srname = $shsub_names{$cg_srname};
        my $cg_srname_ref = "${cg_srname}_ref";
        my $macroref = "{=$cg_srname_ref=}";

        #note option to match at ^ or $.
        my $re   = '(^|[;:|&\s])' . $srname . '($|[;:|&\s])' ;

        grep( $_ !~ /^\s*#/ && s/$re/$1${macroref}$2/g, @var);

        #also perform substitutions for text of each subroutine:
        my $cg_srname2 = "";
        foreach $cg_srname2 (@cg_srnames_final) {
            my (@srtxt) = split("\n", $shsub_defs{$cg_srname2}, -1);
            if (grep( $_ !~ /^\s*#/ && s/$re/$1${macroref}$2/g, @srtxt)) {
                $shsub_defs{$cg_srname2} = join("\n", @srtxt);
            }
        }
    }

    #restore variable text:
    $var = join("\n", @var);

    #definiton PREFIX:
    #set pragma to trim final newlines in here-now defs we generate for subroutines.
    #this allows us to substitute macros and restore the spacing of the original text.
    my $srdeftxt = << "!";
_save_trim_multiline_rnewline = \$trim_multiline_rnewline:nameof:pragmavalue
\%pragma trim_multiline_rnewline 1

!

    #####
    #LOOP 4 - write out definitions:
    #####

    foreach $cg_srname (@cg_srnames_final) {
        $srname = $shsub_names{$cg_srname};
        my $cg_srname_ref = "${cg_srname}_ref";
        my $cg_srname_ref_macro = "{=$cg_srname_ref=}";
        $srtxt = $shsub_defs{$cg_srname};

        #change name of sub-routine to use reference:
        #note:  srtxt retains whitespace in the subroutine declaration line, whereas srname is trimmed.
        $srtxt =~ s/^(\s*)$srname(\s*\()/$1$cg_srname_ref_macro$2/;

        #output definition:
        $srdeftxt .= << "!";

##sh subroutine $srname()
${cg_srname}_ref := $srname
$cg_srname := << ${prefix}EOF
$srtxt
${prefix}EOF

!
    }

    #POST-SCRIPT:
    $srdeftxt .= << "!";

#restore normal behavior for here-now defs:
\%pragma trim_multiline_rnewline \$_save_trim_multiline_rnewline

!


    ######
    #write results to user vars:
    ######
    my $FS = &lookup_def('CG_STACK_DELIMITER');

    #overwrite results if we had any:
    &assign_op($srdeftxt, 'CG_SHSUB_DEFS', $linecnt)          if ($srdeftxt ne "");;
    &assign_op(join($FS, @srnames), 'CG_SHSUB_LIST', $linecnt) if ($#srnames >= 0);

    return $var;
}

sub sh_name_is_excluded
#return 1 if <name> is excluded, 0 otherwise
#(local  utility).
{
    my ($name, $ipat, $xpat) = @_;

    #do not excluded if neither include or exclude pattern was specified:
    return 0 if ($ipat eq "" && $xpat eq "");

    #exclude if exclude pattern is specified and matches:
    return 1 if ($xpat ne "" && $name =~ /$xpat/);

    #do not exclude if include pattern was not specified or if it is specified and matches:
    return 0 if ($ipat eq "" || $name =~ /$ipat/);

    #include pattern was specified, but did not match:
    return 1;
}


1;
