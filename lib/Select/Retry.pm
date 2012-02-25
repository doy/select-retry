package Select::Retry;
use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [ 'retry_select' ],
    groups => { default => [ 'retry_select' ] },
};

sub retry_select {
    my $options = (@_ > 1 && ref($_[0]) eq 'HASH'
        ? shift
        : { mode => 'r' });
    my (@handles) = @_;

    my ($out, $eout);
    my ($in, $ein) = (_build_select_vec(@handles)) x 2;
    my $res;
    if ($options->{mode} eq 'r') {
        $res = select($out = $in, undef, $eout = $ein, $options->{timeout});
    }
    else {
        $res = select(undef, $out = $in, $eout = $ein, $options->{timeout});
    }
    my $again = $!{EAGAIN} || $!{EINTR};

    if ($res == -1) {
        if ($again) {
            warn "retrying...";
            return retry_select(@_);
        }
        else {
            Carp::croak("select failed: $!");
        }
    }

    return ($out, $eout);
}

sub _build_select_vec {
    my @handles = @_;

    my $vec = '';
    for my $handle (@handles) {
        vec($vec, fileno($handle), 1) = 1;
    }

    return $vec;
}

1;
