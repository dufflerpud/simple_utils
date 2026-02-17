#!/usr/bin/perl
#
#indx#	sumdir - Create a file containing checksums of files in directory
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
#doc#	sumdir - Create a file containing checksums of files in directory
########################################################################

use strict;
use Digest::MD5;

sub fatal
    {
    print STDERR "$_[0]\n";
    exit(1);
    }

sub getchecksum
    {
    my( $fn ) = @_;
    if( $fn =~ /^proc\// )
	{ return "-"; }
    elsif( ! open( CS, $fn ) )
	{ return "$fn:  $!"; }
    else
        {
	binmode( CS );
	my $md5 = Digest::MD5->new;
	$md5->addfile( *CS );
	close( CS );
	return $md5->b64digest;
	}
    }

my @dirs = ();
while( $_ = shift(@ARGV) )
    {
    push( @dirs, $_ );
    }

my @fn = ();
my $d;
foreach $d ( @dirs )
    {
    open( INF, "find $d -print |" ) || &fatal("Cannot find $_:  $!");
    while( $_ = <INF> )
        {
	chomp( $_ );
	$_ =~ s/^\.\///;
	push( @fn, $_ );
	}
    close( INF );
    }

my $name;
foreach $name ( sort @fn )
    {
    if( my($dev,$ino,$mode,$nlink,$uid,$gid,$dev2,$size) = lstat($name) )
	{
	my $contentcsum = "-";
	if( -l _ )
	    {
	    $contentcsum = readlink( $name );
	    $contentcsum =~ s/\|/\\|/g;
	    }
	elsif( -b _ || -c _ )
	    {
	    $contentcsum = $dev2;
	    $size = 0;
	    }
	elsif( -d _ )
	    { $size = 0; }
	elsif( -f _ )
	    { $contentcsum = &getchecksum($name); }
	$name =~ s/\|/\\|/g;
	printf("%s|%06o|%d|%d|%d|%s|%s\n",
	    $name, $mode, $uid, $gid, $size, $contentcsum );
	}
    }
exit(0);
