#!/usr/bin/perl -w
#
#indx#	fls.pl - Show all directories and links leading up to specified file
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
#hist#	2026-05-02 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	fls.pl - Show all directories and links leading up to specified file
########################################################################

use strict;

my $lsargs = "d";
my $cwd = `/bin/pwd`;
chomp( $cwd );

sub do_one_file
    {
    my( $fname ) = @_;
    my ( @processing ) = split(/\//,$fname);
    my @sofar = ();
    my $part;
    while( defined($part = shift(@processing)) )
        {
	if( $part eq "." )
	    { }
	elsif( $part eq ".." )
	    { pop(@sofar); }
	else
	    {
	    my $fqfn = join("/","",@sofar,$part);
	    $fqfn =~ s+//*+/+g;
	    my $points_to;
	    system("ls -$lsargs $fqfn");
	    if( ! defined($points_to = readlink( $fqfn ) ) )
		{ push( @sofar, $part ); }
	    else
		{
		my @points_to = split(/\//,$points_to);
		if( $points_to[0] eq "" )
		    {
		    shift( @points_to );
		    @sofar = ();
		    }
		@processing = ( @points_to, @processing );
		}
	    }
	}
    }

my @files;
while( $_ = shift(@ARGV) )
    {
    if( /^-(.*)/ )
        { $lsargs = "$lsargs$1"; }
    elsif( /^\// )
	{ push( @files, $_ ); }
    else
        { push( @files, "$cwd/$_" ); }
    }

foreach my $fname ( @files )
    {
    do_one_file( $fname );
    }
