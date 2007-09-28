
#=============================
package SNMP::Effective::Host;
#=============================

use warnings;
use strict;
use overload '""'  => sub { shift()->{'Addr'}    };
use overload '${}' => sub { shift()->{'Session'} };
use overload '@{}' => sub { shift()->{'VarList'} };


BEGIN {
    no strict 'refs';
    my %sub2key = qw/
                      address   Addr
                      sesssion  Session
                      varlist   VarList
                      callback  Callback
                      memory    Memory
                  /;
    for my $subname (keys %sub2key) {
        *$subname = sub {

            ### init
            my $self = shift;
            my $set  = shift;

            $self->{ $sub2key{$subname} } = $set if($set);

            ### the end
            return $self->{$sub2key{$subname}};
        }
    }
}


sub data { #==================================================================

    ### init
    my $self = shift;

    ### save data
    if(@_) {
        
        ### init save
        my $r       = shift;
        my $ref_oid = shift || '';
        my $iid     = $r->[1]
                   || SNMP::Effective::match_oid($r->[0], $ref_oid)
                   || 1;

        $ref_oid    =~ s/^\.//;

        ### save
        $self->{'_data'}{$ref_oid}{$iid} = $r->[2];
        $self->{'_type'}{$ref_oid}{$iid} = $r->[3];
    }

    ### the end
    return($self->{'_data'}, $self->{'_type'});
}

sub arg { #===================================================================

    ### init
    my $self = shift;
    my $arg  = shift;

    ### set value
    if(ref $arg eq 'HASH') {
        $self->{'Arg'}{$_} = $arg->{$_} for(keys %$arg);
    }

    ### the end
    return wantarray ? (%{$self->{'Arg'}}, DestHost => "$self") : ();
}

sub new { #===================================================================
    
    ### init
    my $class = shift;
    my $addr  = shift or return;
    my %args  = @_;
    my($session, @varlist);

    ### tie
    tie @varlist, "SNMP::Effective::VarList";

    ### the end
    return bless {
        Addr     => $addr,
        Session  => \$session,
        VarList  => \@varlist,
        Callback => sub {},
        Arg      => {},
        Data     => {},
        Memory   => {},
        %args,
    }, $class;
}

#=============================================================================
1983;
__END__

=head1 NAME

SNMP::Effective::HostList - Helper module for SNMP::Effective

=head1 VERSION

This document refers to version 0.01 of SNMP::Effective::HostList.

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

Get host address, also overloaded by ""

=head2 C<sesssion>

Get SNMP::Session

=head2 C<varlist>

Probably empty

=head2 C<callback>

Get a ref to the callback method

=head2 C<memory>

Get / set any data you like
           
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

