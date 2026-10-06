#!/usr/bin/perl -w
#
#indx#	cd_rip_names.pl - Create an html file from a table ripped from a CD
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
#hist#	2026-10-05 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	Create an html file from a table ripped from a CD
########################################################################

use strict;
use lib "/usr/local/lib/perl";
use cpi_file qw( write_file read_file fatal cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_filename qw( text_to_filename );

# Put constants here

our %ONLY_ONE_DEFAULTS =
    (
    "i" =>	"/dev/stdin"
    );

# Put variables here.

our @problems;
our %ARGS;
our $exit_stat = 0;
our @files;		# Not used.

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG -i <file with track names>"
	);
    }

#########################################################################
#	Read in all the title names, and all the current files and	#
#	figure out which ones go with which, and then rename.		#
#########################################################################
sub all_tracks
    {
    my $album = &read_file("/bin/pwd|");
    $album =~ s/_/ /g;
    my @lines = ( "<center><table>","<tr><th colspan=2>$album</th></tr>");

    open( INF, $ARGS{i} ) || &fatal("Cannot open ${ARGS{i}}:  $!");
    my @titles = <INF>;
    chomp( @titles );
    close( INF );

    opendir( D, "." ) || &fatal("Cannot opendir(.):  $!");
    my @old_filenames = sort( grep(/^\d+\./,readdir(D)) );
    closedir( D );

    foreach my $fname ( @old_filenames )
	{
	if( $fname !~ /^(\d+)\.(.*)\.(\w+)$/ )
	    { print STDERR "$fname is not in correct format.\n"; }
	else
	    {
	    my( $ind, $middle, $ext ) = ( $1, $2, $3 );
	    $ind =~ s/^0*//g;
	    $ind = 0 if( ! $ind );
	    my $title_index = $ind - 1;
	    my $newfilename = sprintf("%02d.%s.%s",
	        $ind, &text_to_filename($titles[$title_index]), $ext );
	    &echodo( "mv $fname $newfilename" );
	    push( @lines, "<tr>",
		"<th align=left>". $titles[$title_index]. "</th>".
		"<td><a href='$newfilename'>$newfilename</a></td></tr>");
	    }
	}
    push( @lines, "</table></center>" );
    &write_file( "index.html", join("\n",@lines,"") );
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

#print join("\n\t","Args:",map{"$_:\t$ARGS{$_}"} sort keys %ARGS), "\n";

&all_tracks();

&cleanup($exit_stat);
