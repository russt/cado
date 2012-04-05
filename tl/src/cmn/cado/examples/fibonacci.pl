use Math::BigInt;

sub fib_op
{
    my ($var) = @_;
    return &fibonacci($var+0);
}

sub fibr_op
#recursive form
{
    my ($var) = @_;
    return &r_fibonacci($var+0);
}

sub r_fibonacci
#By definition, the first two numbers in the Fibonacci sequence are 0 and 1,
#and each subsequent number is the sum of the previous two.
{
    my ($nn) = @_;
    return $nn if ($nn <= 1);
    return ( &r_fibonacci($nn-1) + &r_fibonacci($nn-2) );
}

sub fibonacci
#By definition, the first two numbers in the Fibonacci sequence are 0 and 1,
#and each subsequent number is the sum of the previous two.
{
    my ($nn) = @_;

    return $nn if ($nn <= 1);

    my ($fl,$fm,$fn) = (0,1,-1);
    for (my $ii=2 ; $ii <= $nn; $ii++) {
        $fn = $fl + $fm;
        #shift:
        $fl = $fm;
        $fm = $fn;
    }
    return $fn;
}

1;
