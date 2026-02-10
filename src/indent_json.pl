#!/usr/bin/perl -w
#
#indx#	indent_json.pl - Output json in a semi-readable (indented) format
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
#doc#	indent_json.pl - Output json in a semi-readable (indented) format.
#doc#	Note that there are more standard libraries for doing this
#doc#	but the developer wasn't wild about the format.
########################################################################

use strict;

my $INDENT_SPACE = "    ";

my $REMOVE_QUOTES_BEFORE_COLONS = 1;	# Result is easier to read
					# but doesn't pass some JSON
					# interpreters.

my @quotes;

#########################################################################
#	Remove all the quotes from a string so they don't mess up	#
#	the indenter.							#
#########################################################################
sub tame_quotes
    {
    my( $str ) = @_;

    $str =~ s/"([A-Za-z]+[A-Za-z0-9]*)":/$1:/g
	if( $REMOVE_QUOTES_BEFORE_COLONS );

    my @quote_pieces;
    my $in_quote;
    foreach my $piece ( split(/(")/,$str) )
	{
	if( $piece eq '"' )
	    { $in_quote = ! $in_quote; }
	elsif( $in_quote )
	    {
	    push( @quotes, $piece );
	    $piece = "QUOTE".$#quotes."UNQUOTE";
	    }
	push( @quote_pieces, $piece );
	}
    return join("",@quote_pieces);
    }

#########################################################################
#	Indent a json string.						#
#########################################################################
sub indenter
    {
    my( $str ) = @_;
    my $indent = 0;
    my $inline = "";
    my @ret;

    my @pieces = grep(defined($_) && $_ ne "", split( /([,\{\}\[\]])/, $str ) );
    while( @pieces )
	{
	my $piece = shift(@pieces);
	if( ($piece eq "[" && $pieces[0] eq "]")
	  ||($piece eq "{" && $pieces[0] eq "}") )
	    {
	    push( @ret,  $INDENT_SPACE x $indent ) if( ! $inline );
	    push( @ret, $piece, shift(@pieces) );
	    $inline = "\n";
	    }
	elsif( $piece eq "[" || $piece eq "{" )
	    {
	    $indent++;
	    push( @ret, $inline, $INDENT_SPACE x $indent, $piece, "\n" );
	    $inline = "";
	    }
	elsif( $piece eq "]" || $piece eq "}" )
	    {
	    push( @ret, $inline, $INDENT_SPACE x $indent, $piece );
	    $indent--;
	    }
	elsif( $piece eq "," )
	    {
	    push( @ret, $piece, "\n" );
	    $inline = "";
	    }
	else
	    {
	    push( @ret, $INDENT_SPACE x $indent ) if( ! $inline );
	    foreach my $q ( split( /(QUOTE\d+UNQUOTE)/, $piece ) )
		{
		push( @ret, $q =~ /QUOTE(\d+)UNQUOTE/ ? $quotes[$1] : $q );
		}
	    $inline = "\n";
	    }
	}
    push( @ret, $inline );
    return join("",@ret);
    }

#########################################################################
#	Main								#
#########################################################################
print &indenter( &tame_quotes( join("",<STDIN>) ) );
