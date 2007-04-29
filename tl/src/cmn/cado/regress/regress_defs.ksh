#common set-up for codegen regression suite.

#set path-separator:
unset PS; PS=':' ; _doscnt=`echo $PATH | grep -c ';'` ; [ $_doscnt -ne 0 ] && PS=';' ; unset _doscnt

export REGRESS_CG_ROOT
REGRESS_CG_ROOT=../bld/cgtstroot

#test src codegen.pl
export PERL_LIBPATH
PERL_LIBPATH="..;$PERL_LIBPATH"

#test src templates:
export CG_TEMPLATE_PATH
CG_TEMPLATE_PATH="../templates;$CG_TEMPLATE_PATH"
