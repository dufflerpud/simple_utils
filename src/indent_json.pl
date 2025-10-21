#!/usr/bin/perl -w

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
