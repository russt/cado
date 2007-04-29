#note package defaults to current package, which is already codegen.
#codegen internal variables are protected; can only be set via function calls.
use strict;

sub xmlcg_default_value_range_op
#set a default range for variables that do not have a COUNT variable associated
#with them.
#returns the range, or 0.
#the <var> is the name of the range variable we want to set.
{
    my ($var, $varname, $linecnt) = @_;

    my $retval = "0";
    my $parent_instance = 0;
    my $value_varname = "";

    if ($var =~ /^(.*)_COUNT_(\d\d)$/) {
        $value_varname = $1;
        $parent_instance = $2;
        my $value_varname_nn = $value_varname . "_" . "$parent_instance";

#printf STDERR "xmlcg_default_value_range: var_defined(%s)=%d var_defined(%s)=%d parent_instance=%d\n",                    $value_varname_nn, &var_defined($value_varname_nn), $value_varname, &var_defined($value_varname), $parent_instance;

        if ($parent_instance == 1) {
            if ( &var_defined($value_varname_nn) || &var_defined($value_varname) ) {
                $retval = "01..01";
            }
        } else {
            if ( &var_defined($value_varname_nn) ) {
                $retval = sprintf("%s..%s", $parent_instance, $parent_instance);
            }
        }
    }

#printf STDERR "xmlcg_default_value_range: var='%s' varname='%s' value_varname='%s' parent_instance='%s' retval='%s'\n",     $var, $varname, $value_varname, $parent_instance, $retval;

    #no instance count:
    return $retval;
}

sub xmlcg_normalize_counts_op
#normalize counts and values declared by user, for all variables
#prefixed with <prefix>..
#return 1 if successful, 0 if errors.
{
    my ($libprefix, $varname, $linecnt) = @_;

    my @varlist = grep(/$libprefix/, &get_user_vars());

    #probably an error if no variables found:
    if ($#varlist < 0) {
        printf STDERR "xmlcg_normalize_counts: ERROR: no variables found with prefix '%s'\n", $libprefix;
        return 0;
    }

#printf STDERR "xmlcg_normalize_counts: ALL '%s' vars=(%s)\n", $libprefix, join(",", @varlist);

    #get _COUNT vars:
    my @count_vars = grep(/_COUNT(_\d\d)?$/, @varlist);

#printf STDERR "xmlcg_normalize_counts: count_vars=(%s)\n", join(",", @count_vars);

    #get _COUNT variables missing a parent suffix:
    my @count_vars_missing_parent = grep($_ !~ /_COUNT(_\d\d)$/, @count_vars);

#printf STDERR "xmlcg_normalize_counts: count_vars_missing_parent=(%s)\n", join(",", @count_vars_missing_parent);

    #normalize count vars:
    my $vname;
    foreach $vname (@count_vars_missing_parent) {
        #set value:
        my $val = &valueof_op($vname, $varname, $linecnt);
        &assign_op($val, $vname . "_01", $linecnt);
    }

##get list of now normalized _COUNT vars:
#@varlist = grep(/$libprefix/, &get_user_vars());
#@count_vars = grep(/_COUNT(_\d\d)/, @varlist);
#printf STDERR "xmlcg_normalize_counts: <NORMALIZED> count_vars=(%s)\n", join(",", @count_vars);

    return 1;
}

1;
