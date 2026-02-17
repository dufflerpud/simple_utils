#!/usr/bin/perl -w
#
#indx#	count_domains - Read ip log file & count packets by domain
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
#@HDR@
#@HDR@	Permission is hereby granted, free of charge, to any person
#@HDR@	obtaining a copy of this software and associated documentation
#@HDR@	files (the "Software"), to deal in the Software without
#@HDR@	restriction, including without limitation the rights to use,
#@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
#@HDR@	sell copies of the Software, and to permit persons to whom
#@HDR@	the Software is furnished to do so, subject to the following
#@HDR@	conditions:
#@HDR@	
#@HDR@	The above copyright notice and this permission notice shall be
#@HDR@	included in all copies or substantial portions of the Software.
#@HDR@	
#@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
#@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#@HDR@	OTHER DEALINGS IN THE SOFTWARE.
#
#hist#	2026-02-09 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	count_domains - Read ip log file & count packets by domain
#doc#	Information assumed to be on standard in put.
########################################################################

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
