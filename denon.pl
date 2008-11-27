#!/usr/bin/perl

use strict;
use IO::Socket::INET;
use Carp qw(croak);

my $host = "10.0.0.179";
my $port = 23;

("\xff\xfd\x03" eq fromhex("ff fd", " 03 ")) or die;

my $sock = IO::Socket::INET->new(PeerAddr => $host,
                                 PeerPort => $port)
    or die "Failed to connect to $host:$port";

my $hello = fromhex("ff fd 03", # Do Suppress Go ahead
                    "ff fb 18", # Will Terminal Type
                    "ff fb 1f", # Will Negotiate About Window Size
                    "ff fb 20", # Will Terminal Speed
                    "ff fb 21", # Wlil Remote Flow Control
                    "ff fb 22", # Will Linemode
                    "ff fb 27", # Will New Enivronment Option
                    "ff fd 05", # Do Status
                    );

send_to_denon($hello);

expect_from_denon(fromhex("ff fb 03"));  # Will Suppress Go Ahead
expect_from_denon(fromhex("ff fa 18 01 ff f0")); # Send your terminal type

print "send terminal.\n";
send_to_denon(fromhex("ff fa 18 00",
                      "rxvt",
                      "ff f0",  # suboption end
                      ));

expect_from_denon("BridgeCo AG Telnet server\x0a\x0d");

print "Reading...\n";
my $buf;
while (sysread($sock, $buf, 300)) {
    print "Read: [", printable($buf), "]\n";
}

sub expect_from_denon {
    my $expected = shift;
    my $got = "";
    my $buf;
    print "Waiting on ", printable($expected), "...";
    while (length($got) < length($expected) &&
           sysread($sock, $buf, length($expected) - length($got))) {
        $got .= $buf;
    }
    croak "Didn't get expected input." unless $got eq $expected;
    print "Got it.\n";
    return 1;
}

sub fromhex {
    my $in = join('', @_);
    $in =~ s/\s*(..)\s*/chr(hex($1))/eg;
    return $in;
}

sub send_to_denon {
    my $str = shift;
    syswrite($sock, $str) == length($str) or die;
}

sub printable {
    my $str = shift;
    $str =~ s/[^[:print:]]/sprintf("[%02x]", ord($&))/eg;
    return $str;
}



                    
