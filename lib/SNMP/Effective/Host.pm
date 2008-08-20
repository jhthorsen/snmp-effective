
#=============================
package SNMP::Effective::Host;
#=============================

use warnings;
use strict;
use overload '""'  => sub { shift->{'_address'} };
use overload '${}' => sub { shift->{'_session'} };
use overload '@{}' => sub { shift->{'_varlist'} };


BEGIN { ## no critic # for strict
    no strict 'refs';
    my %sub2key = qw/
                      address   _address
                      sesssion  _session
                      varlist   _varlist
                      callback  _callback
                      heap      _heap
                      log       _log
                      data      _data
                  /;
    for my $subname (keys %sub2key) {
        *$subname = sub {
            my($self, $set)               = @_;
            $self->{ $sub2key{$subname} } = $set if(defined $set);
            $self->{ $sub2key{$subname} };
        }
    }
}

sub _save_data { #============================================================
    my $self  = shift;
    my $refs  = shift;
    my $names = shift;
    my $data  = $$self->var_bind_list;
    my $type  = $$self->var_bind_types;

    ### fallback to all
    $names = [ $$self->var_bind_names ] unless(ref $names);

    ### cannot save data
    unless(@$names == @$refs) {
        $self->log->error("Fatal error: refs!=names");
        return;
    }

    DATA:
    while(@$refs) {
        my $ref  = shift @$refs  or last DATA;
        my $name = shift @$names or last DATA;
        my $iid  = SNMP::Effective::match_oid($name, $ref) || 1;

        ### remove leading dot
        $ref =~ s/^\.//mx;

        $self->{'_data'}{$ref}{$iid} = $data->{$name};
        $self->{'_type'}{$ref}{$iid} = $type->{$name};
    }

    return;
}

sub _clear_data { #===========================================================
    my $self = shift;

    $self->{'_data'} = {};
    $self->{'_type'} = {};

    return;
}

sub arg { #===================================================================
    my $self = shift;
    my $arg  = shift;

    if(ref $arg eq 'HASH') {
        $self->{'_arg'}{$_} = $arg->{$_} for(keys %$arg);
    }

    return %{$self->{'_arg'}}, -hostname => "$self" if(wantarray);
    return   $self->{'_arg'};
}

sub new { #===================================================================
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

#=============================================================================
1983;
__END__

=head1 NAME

SNMP::Effective::Host - Helper module for SNMP::Effective

=head1 VERSION

See SNMP::Effective

=head1 DESCRIPTION

This is a helper module for SNMP::Effective

=head1 METHODS

=head2 C<new>

Constructor

=head2 C<arg>

Get SNMP::Session args

=head2 C<data>

Get the retrieved data 

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

=head1 DEBUGGING

Debugging is enabled through Log::Log4perl. If nothing else is spesified,
it will default to "error" level, and print to STDERR. The component-name
you want to change is "SNMP::Effective", inless this module ins inherited.

=head1 NOTES

=head1 TODO

=head1 AUTHOR

Jan Henning Thorsen, C<< <pm at flodhest.net> >>

=head1 ACKNOWLEDGEMENTS

Various contributions by Oliver Gorwits.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

