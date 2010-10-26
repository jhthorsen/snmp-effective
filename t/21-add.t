use warnings;
use strict;
use lib qw(lib);
use Test::More;
use SNMP::Effective;

plan tests => 14;

{
    my $effective = SNMP::Effective->new;
    my $hostlist = $effective->hostlist;
    my $varlist = $effective->_varlist;

    $effective->add( desthost => '127.0.0.1' );
    is($hostlist->count, 1, 'got one host');
    is(@$varlist, 0, 'got zero varlist items');

    $effective->add( desthost => '127.0.0.1' );
    is($hostlist->count, 1, 'got one host');

    $effective->add( desthost => '127.0.0.1' );

    $effective->add( dest_host => [qw/ 127.2 127.0.0.3 /] );
    $effective->add( Dest_hOst => '127.0.0.4' );

    # get, getnext, walk, set
    $effective->add( get => '1.3.4' );

    # alter one host
    $effective->add(
        DesT_hOst => '127.0.0.4'
        walk => ['1.3.5'],
    );
$effective->add(
    Dest_Host => \@host,
    Arg      => { Timeout => $timeout },
    CallbaCK => sub { return "test" },
    walK     => \@walk,
);

