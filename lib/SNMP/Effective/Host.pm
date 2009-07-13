package SNMP::Effective::Host;

=head1 NAME

SNMP::Effective::Host - Helper module for SNMP::Effective

=head1 DESCRIPTION

This is a helper module for SNMP::Effective

=cut

use warnings;
use strict;
use overload '""'  => sub { shift()->{'_address'} };
use overload '${}' => sub { shift()->{'_session'} };
use overload '@{}' => sub { shift()->{'_varlist'} };

=head1 OBJECT ATTRIBUTES

=head2 C<address>

Get host address, also overloaded by "$self"

=head2 C<sesssion>

Get SNMP::Session, also overloaded by $$self

=head2 C<varlist>

The remaining OIDs to get/set, also overloaded by @$self

=head2 C<callback>

Get a ref to the callback method

=head2 C<heap>

Get / set any data you like. By default, it returns a hash-ref, so you can do:

 $host->heap->{'mykey'} = "remember this";
           
=head2 C<log>

Get the same logger as SNMP::Effective use. Ment to be used, if you want to
log through the same interface as SNMP::Effective.

=cut

BEGIN { ## no critic # for strict
    no strict 'refs';
    my %sub2key = qw/
                      address   _address
                      sesssion  _session
                      varlist   _varlist
                      callback  _callback
                      heap      _heap
                      log       _log
                  /;
    for my $subname (keys %sub2key) {
        *$subname = sub {
            my($self, $set)               = @_;
            $self->{ $sub2key{$subname} } = $set if(defined $set);
            $self->{ $sub2key{$subname} };
        }
    }
}

=head2 C<data>

Get the retrieved data 

=cut

sub data {
    my $self = shift;

    if(@_) {
        my $r       = shift;
        my $ref_oid = shift || '';
        my $iid     = $r->[1]
                   || SNMP::Effective::match_oid($r->[0], $ref_oid)
                   || 1;

        $ref_oid    =~ s/^\.//mx;

        $self->{'_data'}{$ref_oid}{$iid} = $r->[2];
        $self->{'_type'}{$ref_oid}{$iid} = $r->[3];
    }

    return $self->{'_data'};
}

=head2 C<clear_data>

Remove data from the host cache

=cut

sub clear_data {
    my $self = shift;

    $self->{'_data'} = {};
    $self->{'_type'} = {};

    return;
}

=head2 C<arg>

Get SNMP::Session args

=cut

sub arg {
    my $self = shift;
    my $arg  = shift;

    if(ref $arg eq 'HASH') {
        $self->{'_arg'}{$_} = $arg->{$_} for(keys %$arg);
    }

    return %{$self->{'_arg'}}, DestHost => "$self" if(wantarray);
    return   $self->{'_arg'};
}

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my $host  = shift or return;
    my $log   = shift;
    my($session, @varlist);

    tie @varlist, "SNMP::Effective::VarList";

    return bless {
        _address  => $host,
        _log      => $log,
        _session  => \$session,
        _varlist  => \@varlist,
        _callback => sub {},
        _arg      => {},
        _data     => {},
        _heap     => {},
    }, $class;
}

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>.

=cut

1;
