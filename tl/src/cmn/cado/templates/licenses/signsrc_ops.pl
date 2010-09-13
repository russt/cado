#
# signsrc_ops.pl - operations useful for adding licence headers to source files
#

#note package defaults to current package, which is already codegen.
#codegen internal variables are protected; can only be set via function calls.
use strict;

my $pkgname = "signsrc_ops.pl";

sub get_header_notice_var
#get the header notice variable name.
#if it is not defined, then return default.
{
    my ($headervar) = "HEADER_NOTICE";  #default
    if (&var_defined('CG_HEADER_NOTICE_VAR')) {
        $headervar = &lookup_def('CG_HEADER_NOTICE_VAR');
    }

    return $headervar;
}

sub stripjavaheader_op
#process :stripjavaheader postfix op
#this routine strips the current header notice and replaces it
#with the token:  {=HEADER_NOTICE=}.  user can change the name
#of the HEADER_NOTICE variable by setting CG_HEADER_NOTICE_VAR to
#the desired variable name.
{
    my ($var) = @_;
    my ($headervar) = &get_header_notice_var();

    my $eolpat = "\n";
    if ($var =~ /\r/) {
        #set to use dos line endings:
        $eolpat = "\r\n";
    }

    my $var2 = $var;
    my $var3 = $var;

    my ($hasheader) = checkforexistingheader_op($var2);

    if ($hasheader eq "YES")
    {
      $var = removeexistingheader_op($var3);
    }

    my @tmp = split($eolpat, $var);

    while (&is_java_comment(\@tmp) || &is_wsp(\@tmp) ) {
        #eat 'em
    }

    return "{=$headervar=}" . $eolpat . join($eolpat, @tmp) . $eolpat;
}

sub nochange_op
{
    my ($var) = @_;

    my $eolpat = "\n";
    if ($var =~ /\r/) {
        #set to use dos line endings:
        $eolpat = "\r\n";
    }

    my @tmp = split($eolpat, $var);

    return join($eolpat, @tmp);
}


sub stripxmlheader_op
#process :stripxmlheader postfix op
#this routine checks to see if there is a line that starts with <?xml  
#it then adds the token: {=HEADER_NOTICE=} directly after this line.  
#user can change the name of the HEADER_NOTICE variable by setting CG_HEADER_NOTICE_VAR to
#the desired variable name.
{
    my ($var) = @_;
    my ($headervar) = &get_header_notice_var();

    my $eolpat = "\n";
    if ($var =~ /\r/) {
        #set to use dos line endings:
        $eolpat = "\r\n";
    }


    my $var2 = $var;
    my $var3 = $var;

    my ($hasheader) = checkforexistingheader_op($var2);

    if ($hasheader eq "YES")
    {
      $var = removeexistingheader_op($var3);
    }

    my @tmp = split($eolpat, $var);
    my @tmp2 = @tmp;

    my ($include) = 0;

    my ($tokens) = $#tmp2; 
    
    my ($i) = 0;
    for ( $i=0; $i <= $tokens; $i++)
    {
      my ($current_line) = $tmp2[$i]; 
      if ($current_line =~ /^<\?xml/) {
        $include = 1; 
        last;
      }
    }

    if ($include == 1) {
      my ($return_text) = "";
      my ($k) = 0;
      for ($k=0; $k <= $i; $k++)
      {
       $return_text = $return_text . shift(@tmp) . $eolpat;
      }
      return $return_text . "{=$headervar=}" . $eolpat . join($eolpat, @tmp);
    }

    return "{=$headervar=}" . $eolpat . join($eolpat, @tmp);
}

sub striptextheader_op
#process :striptextheader postfix op
#this routine checks to see if there is a line that starts with !#  
#it then adds the token: {=HEADER_NOTICE=} directly after this line.  
#user can change the name of the HEADER_NOTICE variable by setting CG_HEADER_NOTICE_VAR to
#the desired variable name.
{
    my ($var) = @_;
    my ($headervar) = &get_header_notice_var();

    my $eolpat = "\n";
    if ($var =~ /\r/) {
        #set to use dos line endings:
        $eolpat = "\r\n";
    }

    my ($hasheader) = checkforexistingheader_op($var);

    if ($hasheader eq "YES") {
      $var = removeexistingheader_op($var);
    }

    my @tmp = split($eolpat, $var);
    my @tmp2 = @tmp;

    my ($include) = 0;

    my ($ntokens) = $#tmp; 
    
    my ($i) = 0;
    for ( $i=0; $i <= $ntokens; $i++)
    {
      my ($current_line) = $tmp2[$i]; 
      if ($current_line =~ /^#!\//) {
        $include = 1; 
        last;
      }
    }

    if ($include == 1) {
      my ($return_text) = "";
      my ($k) = 0;
      for ($k=0; $k <= $i; $k++)
      {
       $return_text = $return_text . shift(@tmp) . $eolpat;
      }
      return $return_text . "{=$headervar=}" . $eolpat . join($eolpat, @tmp . $eolpat);
    }

    return "{=$headervar=}" . $eolpat . join($eolpat, @tmp) . $eolpat;
}

sub stripplheader_op
#process :stripplheader postfix op
#this routine checks to make sure whether the first line starts with a !# or a package statement then 
#adds the token:  {=HEADER_NOTICE=} either before or after as is appropriate.  
#user can change the name of the HEADER_NOTICE variable by setting CG_HEADER_NOTICE_VAR to
#the desired variable name.
{
    my ($var) = @_;
    printf STDERR "%s: ERROR: stripplheader is not implemented\n", $pkgname;
    return($var);
}

sub removeexistingheader_op
#process :removeexistingheader postfix op
{
    my ($var) = @_;
    my ($headervar) = &get_header_notice_var();

    my $eolpat = "\n";
    if ($var =~ /\r/) {
      #set to use dos line endings:
      $eolpat = "\r\n";
    }

    my @tmp = split($eolpat, $var);
    my @tmp2 = split($eolpat, $var);
    my ($tokens) = $#tmp; 
    my ($returnstring) = "";
    my ($startline) = 0;
    my ($endline) = 0;

    my ($m) = 0;
    for ( $m=0; $m <= $tokens; $m++)
    {
      my ($current_line) = $tmp[$m]; 
      if ($current_line =~ /BEGIN_HEADER/) {
        $startline= $m - 1; 
      }
      if ($current_line =~ /END_HEADER/) {
        $endline= $m + 1; 
      }
    }

    my ($mm) = 0;
    for ( $mm=0; $mm <= $tokens; $mm++)
    {
      my ($current_line) = $tmp[$mm]; 

      if($mm < $startline)
      {
       $returnstring = $returnstring . $current_line . $eolpat;
      }

      if($mm > $endline)
      {
       $returnstring = $returnstring . $current_line . $eolpat;
      }
    }

    return $returnstring;
}

sub checkforexistingheader_op
#process :checkforexistingheader postfix op
#this routine checks to see if there is already a header in the file
{
    my ($var) = @_;

    my $eolpat = "\n";
    if ($var =~ /\r/) {
        #set to use dos line endings:
        $eolpat = "\r\n";
    }

    my @tmp = split($eolpat, $var);
    my ($tokens) = $#tmp; 

    my ($first) = "NO";
    my ($second) = "NO";

    my ($j) = 0;
    for ( $j=0; $j <= $tokens; $j++) {
      my ($current_line) = $tmp[$j]; 
      if ($current_line =~ /BEGIN_HEADER/) {
        $first = "YES"; 
      }
      if ($current_line =~ /END_HEADER/) {
        $second = "YES"; 
        last;
      }
    }

    if ($first eq "YES" && $second eq "YES") {
      return "YES";
    } else {
      return "NO";
    }
}
