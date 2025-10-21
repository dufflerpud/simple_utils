#!/usr/bin/perl -w

use strict;

sub just_dom
    {
    my( $fqhn ) = @_;
    if( $fqhn =~ /(.*)\.(.*?)\.(.*?)$/ )
        { return "$2.$3"; }
    else
        { return $fqhn; }
    }

my %domctr = ();
while( $_ = <STDIN> )
    {
    chomp( $_ );
    if( /.*IPv4.* (.*?):(.*?)->(.*?):(.*?) / )
        {
	my( $fqhn1, $port1, $fqhn2, $port2 ) = ( $1, $2, $3, $4 );
	my( $dom1 ) = &just_dom( $fqhn1 );
	$domctr{$dom1}++;
	my( $dom2 ) = &just_dom( $fqhn2 );
	$domctr{$dom2}++;
	}
    }

foreach my $dom ( sort keys %domctr )
    {
    printf("%-20s%4d\n",$dom.":",$domctr{$dom});
    }
