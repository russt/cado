#xmlcgutil.pl - utility to generate intermediate files used in creating
#a codegen library that can generate xml docs from a simple declarative spec.

use strict;

################################### xmlutil  ###################################

package xmlutil;

sub get_element_name
#return the first element name in an xml string..
# </foo> => "foo"
{
    my ($token) = @_;
#printf "get_element_name: token='%s'\n", $token;

    return $1 if ( $token =~ /<\/?([a-zA-Z_]+)>/ );
    return "";
}

sub has_xml_element
{
    my ($input_line) = @_;

#printf "has_xml_element: input_line='%s'\n", $input_line;

    if ( $input_line =~ /<\/?[a-zA-Z_]+>/ ) {
        return 1 
    } else {
#printf "has_xml_element: input_line='%s', return 0\n", $input_line;
        return 0;
    }
}

sub has_opening_element
{
    my ($input_line) = @_;

    return 1 if ( $input_line =~ /<[a-zA-Z_]+>/ );
    return 0;
}

sub has_terminal_element
{
    my ($input_line) = @_;

    return 1 if ( $input_line =~ /<\/[a-zA-Z_]+>/ );
    return 0;
}

sub is_terminal_element
#true if input is of the form <foo></foo>
{
    my ($input_line) = @_;

    return 1 if ( $input_line =~ />\s*</ );
    return 0;
}

#################################### TREES  ####################################

package trees;

#generate the element_names spec, which is the input to 
#genmavenlib.cg.  this program reads the xml file with unique
#element names, created by earlier process.

#a note on push/pop, unshift/shift:
#push appends a list, pop takes from end of list.
#unshift preprends list, shift takes from beginning of list.

######### globals
#the null node is a list with zero elements:
my @null = ();
my $nullref = \@null;

#a root node is a triple:  (nodename, null, subtree_ref)
#a terminal node is a triple:  (nodename, parent_ref, null)
#a non-terminal node is a triple:  (nodename, parent_ref, subtree_ref)
my $NODENAME_IDX = 0;
my $PARENT_IDX = 1;
my $SUBTREE_IDX = 2;

my @ORDERED_ELEMENTS = ();

my %LEVEL = ();

######### end globals

sub make_node
#create an empty node with <name>, and return reference
{
    my ($node_name) = @_;

    my @node = ($node_name, $nullref, $nullref);

    return \@node;
}

sub add_node
{
    my ($treeref, $kidref) = @_;
    if (${$treeref}[$SUBTREE_IDX] == $nullref) {
#printf "case I:  add node '%s' to '%s' kid=[%s]\n", &node_name($kidref), &node_name($treeref), &dump_node($kidref);
        my @kids = $kidref;
        ${$treeref}[$SUBTREE_IDX] = \@kids;
    } else {
        my @kids = @{${$treeref}[$SUBTREE_IDX]};
#printf "case II:  add node '%s' to '%s' kids=(%s)\n", &node_name($kidref), &node_name($treeref), join(",", @kids);
        push @kids, $kidref;
        ${$treeref}[$SUBTREE_IDX] = \@kids;
    }

    ${$kidref}[$PARENT_IDX] = $treeref;
}

sub dump_node
{
    my ($tref) = @_;
    return "<NULL>" if ($tref == $nullref);

    return sprintf("%s^%s",
        &node_name($tref),
        &node_name(&parent_ref($tref))
    );
}

sub parent_ref
#return the parent ref of a node
{
    my ($tref) = @_;
    return $nullref if ($tref == $nullref);

    return ${$tref}[$PARENT_IDX];
}

sub subtree_ref
#return the sub-tree ref of a node, which is either nullref
#or a reference to a list of kids
{
    my ($tref) = @_;
    return $nullref if ($tref == $nullref);

    return ${$tref}[$SUBTREE_IDX];
}

sub node_name
#return the node name for a tree
{
    my ($tref) = @_;
    return "<NULL>" if ($tref == $nullref);

    return ${$tref}[$NODENAME_IDX];
}

sub get_kids
#return the list of kids for this node
{
    my ($tref) = @_;
    return @null if ($tref == $nullref);

    return @null if ( ${$tref}[$SUBTREE_IDX] == $nullref);

    return @{${$tref}[$SUBTREE_IDX]};
}

sub indent_str
{
    my ($level) = @_;

    return "\t" x $level;
}

sub prefix_walk
{
    my ($tref, $level) = @_;
    
    printf "%s%s\n", &indent_str($level), &node_name($tref);

    foreach ( &get_kids($tref) ) {
        &prefix_walk($_, $level+1);
    }
}

sub postfix_walk
{
    my ($tref, $level) = @_;
    
    foreach ( &get_kids($tref) ) {
        &postfix_walk($_, $level+1);
    }

    printf "%s%s\n", &indent_str($level), &node_name($tref);
}

sub is_terminal
{
    my ($tref) = @_;

    return 1 if (&subtree_ref($tref) == $nullref);
    return 0 if ();
}

sub postfix2_walk
#this is a bit different - we pass thru non-terminal kids first,
#then dump all kids
{
    my ($tref, $level) = @_;
    
    #first pass, we skip terminals
    my $kid;
    foreach $kid ( &get_kids($tref) ) {
        next if (&is_terminal($kid));

        &postfix2_walk($kid, $level+1);
    }

    #now dump all kids:
    foreach $kid ( &get_kids($tref) ) {
        printf "%s%s\n", &indent_str($level+1), &node_name($kid);
    }

    printf ",%s%s\n\n", &indent_str($level), &node_name($tref);
}


sub read_input
#read the maven xml reference document from <stdin>
{
    my ($line, $token, $indent);

    while (<STDIN>) {

        s/\s*$//;          #eliminate trailing whitespace

        $line = $_;        #save line with leading indent
        s/^\s*//;          #eliminate leading whitespace (after saving indent level)

        $token=$_;

        next unless (&xmlutil::has_xml_element($token));    #skip lines not containing at least one xml element

        #calculate and save indent level:
        $_ = $line;
        s/[^\s].*$//;
        $indent = length($_)/4;

        #save ordered list of declared elements:
        if (&xmlutil::has_opening_element($token)) {

            push(@ORDERED_ELEMENTS,
                    &new_input_ref(
                        &xmlutil::get_element_name($token),
                        $indent,
                        &xmlutil::is_terminal_element($token) ? 1 : 0
                    )
                );
        }
    }
}

sub new_input_ref
{
    my (@list) = @_;
    return \@list;
}

sub build_tree
{
    my ($tref, $level, $inputref) = @_;

    my ($name, $tlevel, $is_terminal);
    my ($listref);
    my ($subtref) = $nullref;

#   my $rootref = &make_node("ROOT");
#   &add_node($rootref, &make_node("a"));

#printf "build_tree: level=%d #list=%d list=(%s)\n", $level, $#{$inputref}, join(",", @{$inputref});

    while (@{$inputref}) {
        $listref = shift @{$inputref};
        ($name, $tlevel, $is_terminal) = @{$listref};
#printf "%s%s(%d).%d\n", &indent_str($tlevel), $name, $tlevel, $is_terminal;

        if ($tref == $nullref) {
#printf "ADD ROOT NODE '%s'\n", $name;
            $tref = &make_node($name);
            next;
        }

        #if this node is my kid...
        if ($tlevel == $level+1) {
            $subtref = &make_node($name);
#printf "ADD NODE '%s' level=%d tlevel=%d\n", $name, $level, $tlevel;
            &add_node($tref, $subtref);
        } elsif ($tlevel > $level+1) {
            #... new level of nesting - expand last subtree node:
#printf "RECURSE on NODE '%s' level=%d tlevel=%d\n", $name, $level, $tlevel;
            unshift @$inputref, $listref;
            $subtref = &build_tree($subtref, $level+1, $inputref);
        } else {
            #... return to previous level:
            unshift @$inputref, $listref;
            return $tref;
        }
    }

    return $tref;
}

sub create_postfix_spec
#create a postfix notation of an xml input document.
{
    &read_input();

    #make a copy of input:
    my @input = @ORDERED_ELEMENTS;

    my $tref = &build_tree($nullref, 0, \@input);

    postfix2_walk($tref);
}

sub tree_test
{
    #build a tree:
    my $rootref = &make_node("ROOT");
    &add_node($rootref, &make_node("a"));
    &add_node($rootref, &make_node("b"));
    &add_node($rootref, &make_node("c"));

    my $dref = &make_node("d");
    &add_node($dref, &make_node("d1"));
    &add_node($dref, &make_node("d2"));
    &add_node($dref, &make_node("d3"));

    &add_node($rootref, $dref);

    #&prefix_walk($rootref, 0);
    #&postfix_walk($rootref, 0);
    &postfix2_walk($rootref, 0);
}

################################### GLOBALS ####################################

package main;

# declare global variables, SCALARS only in this section:
my $p = $0;

#options:
my $DEBUG = 0;
my $GEN_MACRO_SKEL = 0;
my $GEN_NON_TERMINALS = 0;
my $GEN_POSTFIX = 0;
my $GEN_TERMINALS = 0;
my $HELPFLAG = 0;
my $VERBOSE = 0;

my %UNIQ_ELEMENTS = ();

#these are elements that are both terminals and non-terminals.
#we create new names for the non-terminal versions:
my %NON_TERM_MAP = (
    'organization', 'organization2',
    'extensions', 'build_extensions',
);

#these are duplicate non-terminal elements that have differing content.
#generate these after we generate from input xml document.
#this mapping is from the base generator macro name to the original element name.
my %SUPPLEMENTAL_ELEMENTS = (
    'dm_repository', 'repository',
    'profile_build', 'build',
    'reporting_plugins', 'plugins',
    'reporting_plugin', 'plugin',
);

##################################### MAIN #####################################

my $status = &main(*ARGV, *ENV);
exit $status;

sub main()
{
    local (*ARGV, *ENV) = @_;

    #set up program name argument:
    my(@tmp) = split(/[\/\\]+/, $0);
    # figure out the program name and put it into p
    $p = $tmp[$#tmp];
    $p =~ s/\.(ksh|bat)$//;

    #set global flags:
    return (1) if (&parse_args(*ARGV, *ENV) != 0);
    return (0) if ($HELPFLAG);

    if ($GEN_POSTFIX) {
        #this uses a different read_input() method:
#&trees::tree_test();
        &trees::create_postfix_spec();
        return 0;
    }

    &read_input();

    if ($GEN_NON_TERMINALS) {
        &create_cg_generators_for_non_terminals();
    }

    if ($GEN_TERMINALS) {
        &create_cg_generators_for_terminals();
    }

    if ($GEN_MACRO_SKEL) {
        &create_cg_macro_skel();
    }

    return 0;
}

################################ USAGE SUBROUTINES ###############################

sub usage
{
    my($status) = @_;

    print STDERR <<"!";
Usage:  $p -nonterminals < xmldoc
Usage:  $p -terminals < xmldoc
Usage:  $p -macroskel < xmldoc
Usage:  $p -postfix < xmldoc

Synopsis:
  Create codegen generator macros for modifying an xml element vocabulary.

Options:
  -help         display this usage message and exit.
  -v            verbose output
  -d            show debug output
  -nonterminals create codegen defs to generate xml non-terminal elements
  -terminals    create codegen defs to generate xml terminal elements
  -macroskel    create skeletal macros that can be hand-customized to rename xml elements
  -postfix      create postfix representation of xml doc, suitable as input to genmavenlib.cg

Examples:
  $p -nonterminals < maven2/settings_element_ref.txt > maven2/gen_settings_non_terminal.defs
  $p -terminals < maven2/settings_element_ref.txt > maven2/gen_settings_terminal.defs
  $p -macroskel < maven2/settings_element_ref.txt > maven2/gen_settings_macro.defs
  $p -postfix < maven2/settings_element_unique.txt > maven2/settings_element_names.txt

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

        if ($flag =~ '^-h') {
            $HELPFLAG = 1;
            return(&usage(0));
        } elsif ($flag =~ '^-v') {
            $VERBOSE = 1;
        } elsif ($flag =~ '^-d') {
            $DEBUG = 1;
        } elsif ($flag =~ '^-n') {
            #create codegen defs to generate xml non-terminal elements
            $GEN_NON_TERMINALS = 1;
        } elsif ($flag =~ '^-t') {
            #create codegen defs to generate xml terminal elements
            $GEN_TERMINALS = 1;
        } elsif ($flag =~ '^-m') {
            #create skeletal macros that can be hand-customized to rename xml elements
            $GEN_MACRO_SKEL = 1;
        } elsif ($flag =~ '^-p') {
            #create postfix representation of xml doc, suitable as input to genmavenlib.cg
            $GEN_POSTFIX = 1;
        } else {
            return(&usage(1));
        }
    }

    return(0);
}

sub create_cg_generators_for_terminals
{
    foreach ( sort keys %UNIQ_ELEMENTS ) {
        my $token = $_;
        next unless (/^\s*<[a-zA-Z_]+><\/[a-zA-Z_]+>\s*$/ );    #skip non-terminal elements
        $token = &xmlutil::get_element_name($token);
        next if ($token eq "");

        my $generator = <<"!";
{
gen_${token}_element := << EOF
    %ifndef L1_ELEMENT_PREFIX  L1_ELEMENT_PREFIX =
    %ifndef L2_ELEMENT_PREFIX  L2_ELEMENT_PREFIX =
    XML_ELEMENT_NAME = \${L1_ELEMENT_PREFIX}\${L2_ELEMENT_PREFIX}${token}

    \%call xml_line_element
EOF
}
!
        printf "%s\n", $generator;
    }
}

sub create_cg_macro_skel
{
    foreach ( sort keys %UNIQ_ELEMENTS ) {
        my $token = $_;
        next if (/^\s*<[a-zA-Z_]+><\/[a-zA-Z_]+>\s*$/ );    #skip terminal elements
        $token = &xmlutil::get_element_name($token);
        next if ($token eq "");
        my $element_name = $token;
        $token = $NON_TERM_MAP{$token} if ($NON_TERM_MAP{$token});

        my $generator = <<"!";
{
gen_${token}_macro := << EOF
#<${element_name}>
#    ...
#</${element_name}>

EOF
}
!
        printf "%s\n", $generator;
    }
}

sub create_cg_generators_for_non_terminals
{
    #output preamble:
    print STDOUT <<"!";
#initialize prefixes if not already defined::
\%ifndef L1_ELEMENT_PREFIX  L1_ELEMENT_PREFIX =
\%ifndef L2_ELEMENT_PREFIX  L2_ELEMENT_PREFIX =

!

    foreach ( sort keys %UNIQ_ELEMENTS ) {
        my $token = $_;
        next if (/^\s*<[a-zA-Z_]+><\/[a-zA-Z_]+>\s*$/ );    #skip terminal elements
        $token = &xmlutil::get_element_name($token);
        next if ($token eq "");
        my $element_name = $token;
        $token = $NON_TERM_MAP{$token} if ($NON_TERM_MAP{$token});
        printf "%s\n", &non_teminal_generator($token, $element_name);
    }

    #now generate supplemental generators:
    foreach ( sort keys %SUPPLEMENTAL_ELEMENTS ) {
        my $token = $_;
        my $element_name = $SUPPLEMENTAL_ELEMENTS{$token};
        printf "%s\n", &non_teminal_generator($token, $element_name);
    }
}

sub non_teminal_generator
#return string containing non-terminal generator for <token>, <element_name>
{
    my ($token, $element_name) = @_;

        my $generator = <<"!";
{
gen_${token}_element := << EOF
    #create volitile reference to my token, element names.
    #these are only useful for setting the prefixes:
    _token = $token
    _element_name = $element_name

    #save input accumulator
    gen_${token}_element_input_ptr = \$MACRO_OUTPUT_ACCUMULATOR

    #set/clear our working accumulator
    MACRO_OUTPUT_ACCUMULATOR =	gen_${token}_element_output_ptr
    \$MACRO_OUTPUT_ACCUMULATOR =

    #save the input prefixes:
    gen_${token}_element_l1_prefix = \$L1_ELEMENT_PREFIX
    gen_${token}_element_l2_prefix = \$L2_ELEMENT_PREFIX

    #also create volitile refs to the input prefixes:
    _parent_l1_prefix = \$L1_ELEMENT_PREFIX
    _parent_l2_prefix = \$L1_ELEMENT_PREFIX

    #default the element prefixes - user macro may override:
    L1_ELEMENT_PREFIX =
    L2_ELEMENT_PREFIX =

    #########
    #call macro to generate inner elements:
    #########
    %call gen_${token}_macro

    #########
    #generate outer element:
    #########
    #restore the input prefixes prior to generating outer element:
    L1_ELEMENT_PREFIX = \$gen_${token}_element_l1_prefix
    L2_ELEMENT_PREFIX = \$gen_${token}_element_l2_prefix

    XML_ELEMENT_NAME = \${L1_ELEMENT_PREFIX}\${L2_ELEMENT_PREFIX}${element_name}
    XML_ELEMENT_BODY=\$MACRO_OUTPUT_ACCUMULATOR:valueof
    \$MACRO_OUTPUT_ACCUMULATOR =
    \%call xml_nested_element

    #append original accumulator with new results and restore original:
    \$gen_${token}_element_input_ptr = \${gen_${token}_element_input_ptr:valueof}\${MACRO_OUTPUT_ACCUMULATOR:valueof}
    MACRO_OUTPUT_ACCUMULATOR = \$gen_${token}_element_input_ptr

EOF
}
!
    return $generator;
}

sub read_input
#read the maven xml reference document from <stdin>
{
    my ($line, $token, $element_name);

    while (<STDIN>) {

        s/\s*$//;          #eliminate trailing whitespace

        $line = $_;        #save line with leading indent
        s/^\s*//;          #eliminate leading whitespace (after saving indent level)

        $token=$_;

        next unless (&xmlutil::has_terminal_element($token));    #skip lines unless they terminal: </element>

        $element_name = &xmlutil::get_element_name($token);
        if ($element_name =~ /_/) {
            printf STDERR "%s: WARNING: input element name '%s' contains reserved '_' characters.\n", $p, $element_name;
        }

        #save unique elements:
        $UNIQ_ELEMENTS{$token}++;

        printf STDERR "read_input: token='%s' element_name='%s' UNIQ_ELEMENTS{%s}=%d\n", $token, $element_name, $token, $UNIQ_ELEMENTS{$token} if ($DEBUG);
    }
}

