use warnings;
use strict;
use lib qw(lib);
use Test::More;
use SNMP::Effective;

plan tests => 14;

my @host = qw/10.1.1.2 10.1.1.3/;
my @walk = qw/sysDescr/;
my $timeout = 3;

{
    my $effective = SNMP::Effective->new;
    my $hostlist = $effective->hostlist;
    my $varlist = $effective->_varlist;
    my $host;

    $effective->add( desthost => '127.0.0.1' );
    is($hostlist->length, 1, 'got one host');

    $effective->add( desthost => '127.0.0.2' );
    is($hostlist->length, 2, 'got two hosts');

    $effective->add( get => '127.0.0.1' );
    is($hostlist->length, 2, 'got two host');
    is(@$varlist, 1, 'effective got a varlist item...');

    TODO: {
        local $TODO = 'not sure if this is correct';
        $host = $hostlist->{'127.0.0.2'};
        is(@$host, 1, '...127.0.0.2 also got a varlist item');
    }

    # get, getnext, walk, set
    $effective->add( dest_host => ['127.0.0.1'], get => '1.3.4' );
    $effective->add( DesT_hOst => '127.0.0.1', getnext => ['1.3.5'] );
    $effective->add( DesT_hOst => '127.0.0.1', walk => ['1.3.5'] );
    $effective->add( DesT_hOst => '127.0.0.1', set => ['1.3.5'] );

    $host = $hostlist->{'127.0.0.1'};
    is(@$host, 4, '127.0.0.1 got four varlist item');

    $effective->add(
        Dest_Host => \@host,
        Arg => { Timeout => $timeout },
        CallbaCK => sub { return "test" },
        walK => \@walk,
    );
}
