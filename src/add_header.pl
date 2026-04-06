#!/usr/bin/perl -w
#
#indx#	add_header - Add Index, RCS ID, copyright, initial histories & doc to source
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
#hist#	2024-04-20 - c.m.caldwell@alumni.unh.edu - Created
#hist#	2026-02-09 - Christopher.M.Caldwell0@gmail.com - Standard header
########################################################################
#doc#	add_header - Add Index entry, RCS ID, copyright, preliminary
#doc#	history & documentation to source.  More complex than at first
#doc#	blush because it needs to figure out comment convention so that new
#doc#	header doesn't change semantics of program.
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal echodo read_file write_file cleanup tempfile );
use cpi_arguments qw( parse_arguments );
use cpi_filename qw( just_ext_of basename );
use cpi_inlist qw( inlist );
use cpi_compress_integer qw( compress_integer );
use cpi_vars;

# Put constants here

my $PROJECT		= "routing";
my $BASEDIR		= "$cpi_vars::USRLOCAL/projects/$PROJECT";
my $TODAY		= `date '+%Y-%m-%d'`;		chomp($TODAY);
my $YEAR		= `date '+%Y'`;			chomp($YEAR);
my $HDR_STRING		= "\@HDR\@";
my $SCREEN_WIDTH	= 72;

my $unique_marker_int	= time()*1000000+$$;

our %ONLY_ONE_DEFAULTS =
    (
    "output_file"		=> "",
    "prologue"			=> "",
    "epilogue"			=> "",
    "comment_intro_character"	=> "",
    "line_character"		=> "#",
    "date"			=> $TODAY,
    "year"			=> $YEAR,
    "email_address"		=> "Christopher.M.Caldwell0\@gmail.com",
    "company"			=> "Brightsands",
    "name"			=> "Christopher Caldwell",
    "postal_address"		=> "P.O. Box 401, Bailey Island, ME 04003",
    "copyright_style"		=> [ "mit", "proprietary" ],
    "documentation"		=> 1,
    "index"			=> 1,
    "history"			=> 1,
    "verbosity"			=> 0
    );


# Put variables here.

our @problems;
our %ARGS;
our @files;
our $exit_stat = 0;

# Put interesting subroutines here

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
    "Usage:  $cpi_vars::PROG {<possible argument>} <file> {<file>}","",
	"Where <possible argument> is:",
	"    -p <comment prologue>      ($ONLY_ONE_DEFAULTS{prologue})",
	"    -ep <comment epilogue>     ($ONLY_ONE_DEFAULTS{epilogue})",
	"    -comm <comment intro char> ($ONLY_ONE_DEFAULTS{comment_intro_character})",
	"    -l <char for lines>        ($ONLY_ONE_DEFAULTS{line_character})",
	"    -d <today as yyyy-mm-dd>   ($ONLY_ONE_DEFAULTS{date})",
	"    -Y <copyright year>        ($ONLY_ONE_DEFAULTS{year})",
	"    -em <email address>        ($ONLY_ONE_DEFAULTS{email_address})",
	"    -comp <company name>       ($ONLY_ONE_DEFAULTS{company})",
	"    -ind <comment for index>	(1=make something up)",
	"    -doc <comment for doc>	(1=make something up)",
	"    -n <author name>           ($ONLY_ONE_DEFAULTS{name})",
	"    -a <copyright address>     ($ONLY_ONE_DEFAULTS{postal_address})",
	"    -cop <header style>        ($ONLY_ONE_DEFAULTS{copyright_style}[0])",
	"    -v <turn on verbose>       ($ONLY_ONE_DEFAULTS{verbosity})"
	);
    }

#########################################################################
#	Return a file in a line array (with no new-lines).		#
#########################################################################
sub lines_in
    {
    my( $filename ) = @_;
    open( LINES_IN, $filename ) || &fatal("Cannot open $filename:  $!");
    my @ret = <LINES_IN>;
    close( LINES_IN );
    chomp( @ret );
    return @ret;
    }

#########################################################################
#	Return a huge string broken up with newlines for readability.	#
#########################################################################
sub format_comment
    {
    my ( $prefix, $to_convert ) = @_;
    my $width = 72 - length($prefix);
    my $tempfile = &tempfile(".txt");
    $to_convert =~ s/^\s*//;
    $to_convert =~ s/\n[ \t]*/\n/gms;
    &write_file( $tempfile, $to_convert );
    return map {"$prefix$_"}
	split(/\n/,&read_file("fmt -$width < $tempfile |"));
    }

#########################################################################
#	Create new file with header.					#
#########################################################################
sub do_one_file
    {
    my( $filename ) = @_;
    print STDERR "Processing $filename.\n" if( $ARGS{verbosity} );
    my @lines = &lines_in( $filename );
    my @ret;
    push( @ret, shift(@lines) ) if( $lines[0]=~/^#!/ || $lines[0]=~/<script/ );

    my $tag = "doctag_".&compress_integer($unique_marker_int++);

    my $prologue = "";
    my $epilogue = "";
    my $horiz_bar = "";
    my $c = "";

    if( grep( $ARGS{$_} ne "", "prologue", "epilogue", "comment_intro_character" ) )
        {
	$prologue = $ARGS{prologue};
	$epilogue = $ARGS{epilogue};
	$c = $ARGS{comment_intro_character};
	$horiz_bar = $ARGS{line_character};
	}
    else
	{
	my $ext = &just_ext_of($filename);
	if( grep($ext eq $_, "c", "c++", "h" ) )
	    {
	    my $bar = '*'x$SCREEN_WIDTH;
	    $prologue="/$bar";
	    $epilogue=" $bar/";
	    $c=" *";
	    $horiz_bar=" $bar";
#	    print "prologue=[$prologue]\n";
#	    print "epilogue=[$epilogue]\n";
#	    print "c=[$c]\n";
#	    print "l=[$horiz_bar]\n";
#	    exit(0);
	    }
	elsif( grep($ext eq $_, "f", "for" ) )
	    { $c="C"; $horiz_bar="-"x$SCREEN_WIDTH; }
	elsif( grep($ext eq $_, "js" ) )
	    { $c="//"; $horiz_bar="/"x$SCREEN_WIDTH; }
	elsif( grep($ext eq $_, "html", "htm" ) )
	    {
	    $c="--";
	    my $bar = "-" x $SCREEN_WIDTH;
	    $prologue="<!$bar";
	    $epilogue="$c$bar>";
	    $horiz_bar="$c$bar"; }
	else
	    { $c="#"; $horiz_bar=${c}x$SCREEN_WIDTH; }
	}

    #$prologue = $horiz_bar if( $prologue eq "" );
    $epilogue = $horiz_bar if( $epilogue eq "" );

    my $id = "\$Id\$";
    my $year_string = $ARGS{year};
    foreach ( @lines )
        {
	if( /$HDR_STRING.*(\$Id.*\$)/ )
	    { $id=$1; }
	elsif( /$HDR_STRING.*Copyright (.*) by/ )
	    {
	    my $years = $1;
	    if( $years =~ /^(.*?)\s*(\d\d\d\d)$/ )
	        {
		my( $prefix, $lastyear ) = ( $1, $2 );
		if( $lastyear == $ARGS{year} )
		    { $year_string=$years; }
		elsif( $prefix eq "" )
		    { $year_string="$lastyear-$ARGS{year}"; }
		elsif( $prefix =~ /.*-$/ )
		    { $year_string=$prefix.$ARGS{year}; }
		#elsif( $prefix =~ /.*,$/ )
		else
		    { $year_string="$years,$ARGS{year}"; }
		}
	    }
	}

    push( @ret, $prologue ) if( $prologue );

    my $filename_base = &basename($filename);
    if( $ARGS{index} )
	{
	my $index_text =
	    ( $ARGS{index} eq "1"
	    ? "(VERY brief explanation of what this file is/does)"
	    : $ARGS{index} );
	push( @ret,
	    $c,
	    "${c}indx#\t$filename_base - $index_text",
	    );
	}

    push( @ret, "$c$HDR_STRING\t$id" );

    if( $ARGS{copyright_style} eq "proprietary" )
	{
	push( @ret,
"$c$HDR_STRING",
"$c$HDR_STRING\t\tCopyright $year_string by",
"$c$HDR_STRING\t\t$ARGS{name}/$ARGS{company}",
"$c$HDR_STRING\t\t$ARGS{postal_address}",
"$c$HDR_STRING\t\tAll Rights Reserved",
"$c$HDR_STRING",
&format_comment( "$c$HDR_STRING\t", <<EOF ) );
 This software comprises unpublished confidential information
 of $ARGS{company} and may not be used, copied or made available
 to anyone, except in accordance with the license under which
 it is furnished.
EOF
	}
    elsif( $ARGS{copyright_style} eq "mit" )
        {
	push( @ret,
"$c$HDR_STRING",
"$c$HDR_STRING\tCopyright (c) $year_string $ARGS{name} ($ARGS{email_address})",
"$c$HDR_STRING",
&format_comment( "$c$HDR_STRING\t", <<EOF ) );
 Permission is hereby granted, free of charge, to
 any person obtaining a copy of this software and
 associated documentation files (the "Software"),
 to deal in the Software without restriction,
 including without limitation the rights to
 use, copy, modify, merge, publish, distribute,
 sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is
 furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission
 notice shall be included in all copies or
 substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
 WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
 OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
EOF
	}
    
    push( @ret,
	$c,
	"${c}hist#\t$TODAY - $ARGS{email_address} - Created" )
	if( $ARGS{history} );

    if( $ARGS{documentation} )
	{
	my $doc_text =
	    ( $ARGS{documentation} eq "1"
	    ? "(Less brief explanation of what this file is/does)"
	    : $ARGS{documentation} );
	push( @ret,
$horiz_bar,
"${c}doc#\t$doc_text"
	    );
	}

    push( @ret, $epilogue );

    @lines = grep( ! /$HDR_STRING/, @lines );
    my $str = join("\n",@ret,@lines,"");
    $str =~ s:/\*\n\*/\n::gms;
    &write_file( $ARGS{output_file}||$filename, $str );
    }

#########################################################################
#	Main								#
#########################################################################

if( 0 && $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

#print join("\n\t","Args:",map{"$_:\t$ARGS{$_}"} sort keys %ARGS), "\n";

foreach my $filename ( @files )
    { &do_one_file($filename); }

&cleanup( $exit_stat );
