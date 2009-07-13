package SNMP::Effective::Logger;

=head1 NAME

SNMP::Effective::Logger

=head1 DESCRIPTION

This is a wrapper around C<Log::Log4perl>, but falls back to log everything,
if C<Log::Log4perl> is missing.

=cut

use strict;
use warnings;

our $LOGCONFIG     = {
    "log4perl.rootLogger"             => "ERROR, screen",
    "log4perl.appender.screen"        => "Log::Log4perl::Appender::Screen",
    "log4perl.appender.screen.layout" => "Log::Log4perl::Layout::SimpleLayout",
};
our $AUTOLOAD;


BEGIN {
    eval { require Log::Log4perl };
    warn $@ if($@);
}

=head1 METHODS

=head2 new

Returns either a C<Log::Log4perl> or C<SNMP::Effective::Logger> object.

=cut

sub new {
    if(%{ Log::Log4perl:: }) {
        Log::Log4perl->init($LOGCONFIG) unless(Log::Log4perl->initialized);
        return Log::Log4perl->get_logger(__PACKAGE__);
    }
    else {
        return bless [], __PACKAGE__;
    }
}

=head2 AUTOLOAD

=cut

sub AUTOLOAD {

    my $self   = shift;
    my $msg    = shift || '';
    my($level) = $AUTOLOAD =~ /::(\w+)$/mx;

    return if($level eq 'DESTROY');

    warn "$level: $msg\n";

    return;
}

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<SNMP::Effective>.

=cut

1;
