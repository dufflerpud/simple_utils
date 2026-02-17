#!/usr/bin/perl -w
#
#indx#	tmog - Type, Mode, Owner and Group - create specified file
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2024-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
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
#doc#	tmog - Type, Mode, Owner and Group - create specified file
#doc#	Similar to linux install utility but a lot faster to type
#doc#	because if can look at the arguments to know whether they apply
#doc#	to the file type, its mode etc.
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal cleanup echodo );
use cpi_arguments qw( parse_arguments );
use cpi_inlist qw( inlist );
use cpi_vars;

# Put constants here

my @TYPES = ( "f", "d", "l", "c", "b", "u", "p" );

our @files;
our @problems;
our %ARGS;
our $exit_stat = 0;

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments> <file>","",
	"-type f|d|l|p|b|c|u     Specify file to create",
	"-mode <ugo>             Specify protection",
	"-owner <owner>          Specify owner of file",
	"-group <group>          Specify group of file",
	"-major <major number>   Specify major node for mknod",
	"-minor <minor number>   Specify minor node for mknod",
	"-link <linked to file>  File to link to");
    }

#########################################################################
#########################################################################
sub typearg
    {
    my( $arg ) = @_;
    return if( $ARGS{$arg} );
    if( @files )
	{ $ARGS{$arg} = shift(@files); }
    else
	{ push( @problems, "-$arg not specified." ); }
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    {
    %ARGS = &parse_arguments({
	flags		=>	[ "delete" ],
	non_switches	=>	\@files,
	switches=>
	    {
	    "verbosity"	=>	0,
	    "type"	=>	[ "", @TYPES ],
	    "mode"	=>	{ default=>"", re=>"[0-7][0-7][0-7]|[0-7][0-7][0-7][0-7]|[ugorwxst,=+\\-]*[=+\\-][rwxst]+" },
	    "owner"	=>	{ default=>"", re=>"\\w+" },
	    "group"	=>	{ default=>"", re=>"\\w+" },
	    "major"	=>	{ default=>"", re=>"\\d+" },
	    "minor"	=>	{ default=>"", re=>"\\d+" },
	    "linked"	=>	""
	    } } );
    }

$cpi_vars::VERBOSITY = $ARGS{verbosity};

my @remaining;
foreach my $f ( @files )
    {
    if( &inlist( $f, @TYPES ) && $ARGS{type} eq "" )
	{ $ARGS{type}=$f; }
    elsif( $ARGS{mode} eq "" &&
	( $f=~/^[0-7][0-7][0-7][0-7]$/
	|| $f=~/^[0-7][0-7][0-7]$/
	|| $f=~/^[ugorwxst,=+\-]*[=+\-][rwxst]+$/ )
	&& $ARGS{mode} eq "" )
	{ $ARGS{mode}=$f; }
    elsif( $f =~ /^(\w*):(\w*)$/ )
	{
	$ARGS{owner} ||= $1;
	$ARGS{group} ||= $2;
	}
    elsif( $f =~ /^(\d*),(\d*)$/ )
	{
	$ARGS{major} ||= $1;
	$ARGS{minor} ||= $2;
	}
    else
	{
	push( @remaining, $f );
	}
    }

@files = @remaining;
if( $ARGS{type} eq "l" && ! $ARGS{link} && @files )
    {
    $ARGS{link} = pop( @files );
    }

push( @problems, "No files specified.") if( ! @files );
&usage(@problems) if( @problems );

umask( 0 );
foreach my $f ( @files )
    {
    &echodo( "rm -f '$f'" ) if( $ARGS{delete} && -e $f );
    if( ! -e $f )
	{
	if   ( $ARGS{type} eq "f" )	{ &echodo( "dd of='$f' status=none" ); }
	elsif( $ARGS{type} eq "d" )	{ &echodo( "mkdir -p '$f'" ); }
	elsif( $ARGS{type} eq "l" )	{ &echodo( "ln -s '$ARGS{link}' '$f'" ); }
	elsif( $ARGS{type} eq "p" )	{ &echodo( "mkfifo '$f'" ); }
	elsif( &inlist( $ARGS{type}, "c", "b", "u" ) )
	    { &echodo( "mknod '$f' $ARGS{type} $ARGS{major} $ARGS{minor}" ); }
	}
    if( $ARGS{type} ne "l" )
        {
	if( $ARGS{owner} eq "" )
	    { ($ARGS{group} ne "") && &echodo( "chgrp $ARGS{group} '$f'" ); }
	elsif( $ARGS{group} ne "" )
	    { &echodo( "chown $ARGS{owner}:$ARGS{group} '$f'" ); }
	else
	    { &echodo( "chown $ARGS{owner} '$f'" ); }
	($ARGS{mode} ne "") && &echodo( "chmod $ARGS{mode} '$f'" );
	}
    }

cleanup($exit_stat);
