sub mytolower_op
{
    my ($var) = @_;
    $var =~ tr/[A-Z]/[a-z]/;
    return $var;
}
1;
