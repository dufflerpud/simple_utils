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

use lib "/usr/local/lib/perl";

use cpi_file qw( fatal read_file );
use cpi_hash qw( hashof );
use cpi_arguments qw( parse_arguments );
use cpi_vars;

########################################################################
#	Return the checksum of the file.
########################################################################
sub getchecksum
    {
    my( $fn ) = @_;
    if( $fn =~ /^proc\// )
	{ return "-"; }
    elsif( ! -r $fn )
	{ return "$fn:  $!"; }
    else
        { return &hashof( &read_file($fn) ); }
    }

########################################################################
#	Main
########################################################################

my @todo;
my %ARGS = &parse_arguments({
    non_switches =>	\@todo,
    switches =>
    	{
	"verbosity"	=> 0
	}
    });

# Get the full list of files to return from the todo list (no recursion)
my @files;
while( @todo )
    {
    my $f = shift(@todo);
    push( @files, $f );
    if( ! -l $f && -d $f )
        { 
	if( ! opendir(D,$f) )
	    { print STDERR "Cannot opendir($f):  $!\n"; }
	else
	    {
	    push( @todo,
		map{"$f/$_"}
		    grep($_ ne "." && $_ ne "..",
			readdir(D) ) );
	    closedir(D);
	    }
	}
    }

# lstat() each file and checksum actual data files
foreach my $name ( sort @files )
    {
    if( my($dev,$ino,$mode,$nlink,$uid,$gid,$dev2,$size) = lstat($name) )
	{
	my $contentcsum = "-";

	# "_" refers to the filehandle perl cached with the last stat
	# or lstat as above.  It cuts down on the stat()ting which is a
	# pretty cool efficiency hack but talk about obscure!
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
