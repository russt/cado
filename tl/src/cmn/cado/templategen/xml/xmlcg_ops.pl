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
# @(#)xmlcg_ops.pl
#
# Copyright 2003-2008 Sun Microsystems, Inc.  All Rights Reserved.
# Copyright 2009-2011 Russ Tremain.  All Rights Reserved.
#
# END_HEADER - DO NOT EDIT
#

#note package defaults to current package, which is already codegen.
#codegen internal variables are protected; can only be set via function calls.

#
# xmlcg_ops.pl - some specialized ops for generating xml from indexed variables.
#
# Author: Russ Tremain
#
#  17-Aug-2011 (russt)
#       Remove 2 digit limit for :xmlcg_default_value_range_op.
#

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

    if ($var =~ /^(.*)_COUNT_(\d+)$/) {
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
    my @count_vars = grep(/_COUNT(_\d+)?$/, @varlist);

#printf STDERR "xmlcg_normalize_counts: count_vars=(%s)\n", join(",", @count_vars);

    #get _COUNT variables missing a parent suffix:
    my @count_vars_missing_parent = grep($_ !~ /_COUNT(_\d+)$/, @count_vars);

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
#@count_vars = grep(/_COUNT(_\d+)/, @varlist);
#printf STDERR "xmlcg_normalize_counts: <NORMALIZED> count_vars=(%s)\n", join(",", @count_vars);

    return 1;
}

1;
