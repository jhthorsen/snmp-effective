#!/usr/bin/perl

#==========================
# snmp_effective_example.pl
#==========================

use warnings;
use strict;
use lib qw(./lib ../lib);
use Log::Log4perl;
use SNMP::Effective;

### set up Log::Log4perl, before SNMP::Effective do
my $LOG4PERL = {
    "log4perl.rootLogger"             => "DEBUG, screen",
    "log4perl.appender.screen"        => "Log::Log4perl::Appender::Screen",
    "log4perl.appender.screen.layout" => "Log::Log4perl::Layout::SimpleLayout",
};

Log::Log4perl->init($LOG4PERL) unless(Log::Log4perl->initialized);

### set up SNMP::Effective
my $effective = SNMP::Effective->new(
                    dest_host => "127.0.0.1",
                    get       => "1.3.6.1.2.1.1.1.0", # sysDescr.0
                    getnext   => "sysName",
                    walk      => "ifNames",
                    callback  => sub { my_callback(@_) },
                );

### the end
$effective->execute;
exit 0;


sub my_callback { #===========================================================

    ### init
    my $host  = shift;
    my $error = shift;
    my $heap  = $host->heap;
    my $data;

    ### test for error
    if($error) {
        say("Error: Could not get data from $host: $error");
        return;
    }

    ### get data
    $data = $host->data;

    ### print data
    for my $oid (%$data) {
        say("$host returned oid($oid) with data:");
        say(join "\n\t", map {
                             "$_ => $data->{$oid}{$_}";
                         } keys %{ $data->{$oid} }
        );
    } 

    ### the end
    return; # snmp-effective doesn't care about the return value
}

sub say { #===================================================================
    print "$_\n" for(@_);
}

