#!/bin/sh
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
# @(#)main.sh - ver 1.1 - 01/04/2006
#
# Copyright 2004-2006 Sun Microsystems, Inc. All Rights Reserved.
# 
# END_HEADER - DO NOT EDIT
#

{=SH_COMMAND_DESCRIPTION=}

##################################### USAGE ####################################

usage()
{
    status=$1

    cat << EOF
{=SH_USAGE_SYNOPSIS=}

{=SH_USAGE_BODY=}
EOF

    exit $status
}

parse_args()
{
    init_defaults

    while [ $# -gt 0 -a "$1" != "" ]
    do
        arg=$1; shift

        case $arg in
        -help )
            usage 0
            ;;
{=SH_PARSE_ARGS_CASES=}
        -* )
            echo "${p}: unknown option, $arg"
            usage 1
            ;;
        * )
            if [ -z "${=SH_ARG_VARNAME=}" ]; then
                {=SH_ARG_VARNAME=}="$arg"
            else
                {=SH_ARG_VARNAME=}="${=SH_ARG_VARNAME=} $arg"
            fi
            ;;
        esac
    done
{=SH_PARSE_ARGS_EPILOG=}
}

init_defaults()
#this routine is responsible for initializing all default parameters
{
    {=SH_ARG_VARNAME=}=
{=SH_INIT_DEFAULTS_BODY=}
}

################################## SUBROUTINES #################################

{=SH_SUBROUTINES=}

##################################### MAIN #####################################

p=`basename $0`
exit_status=0

parse_args "$@"
{=SH_MAIN_BODY=}

exit $exit_status
