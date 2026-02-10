#!/usr/bin/perl -w
#
#indx#	send_text.pl - Send a text to specified phone by e-mail to special address
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
#doc#	send_text.pl - Send a text to specified phone by e-mail to special address
#doc#	Really just a front end to e-mail.
########################################################################

use strict;

use lib "/usr/local/lib/perl";

use cpi_file qw( read_file fatal write_lines cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_send_file qw( sendmail );

# Put constants here

our %ONLY_ONE_DEFAULTS =
    (
    "from"		=>	$ENV{USER}||"chris",
    #"from"		=>	"chris.interim\@gmail.com",
    #"to"		=>	"2078417418\@vzwpix.com",
    "to"		=>	"2078417418\@vtext.com",
    "input_file"	=>	"/dev/stdin",
    "subject"		=>	"",
    "message"		=>	"",
    "debug"		=>	0,

    #Ideally, the following would be "api", but "api" invokes
    #cpi_send_file's sendmail which uses MIME::Lite which seems to send
    #the body of the e-mail as an attachment which looks weird to the
    #recipient of the text.  Therefore, we invoke sendmail directly.
    "use"		=>	[ "sendmail", "api" ]
    );

# Put variables here.

our @problems;
our %ARGS;
our @files;	# Unused by makes parse_arguments happier.
our $exit_stat = 0;

# Put interesting subroutines here

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, <<USAGE_EOF );

Usage:  $cpi_vars::PROG <possible arguments>

Where <possible arguments> are:
	-from <email>		E-mail address sending text
	-input_file <file>	File to send (excludes -m)
	-message <message>	Body of message (excludes -i)
	-to <email>		Destination of e-mail (often nnnnnnnnnn\@vtext.com)
	-subject <subject>	Subject heading for message
USAGE_EOF
    }

#########################################################################
#	Do the actual work (opening files, sendmail, etc ).		#
#########################################################################
sub send_the_text
    {
    $ARGS{message} ||=
	( @files
	? join(" ",@files)
	: &read_file( $ARGS{input_file} ) );

    my @tosend = ();
    push( @tosend, "To: $ARGS{to}" )		if( defined($ARGS{to}) );
    push( @tosend, "From: $ARGS{from}" )	if( defined($ARGS{from}) );
    push( @tosend, "Subject: $ARGS{subject}" )	if( defined($ARGS{subject}) );
    push( @tosend, "", $ARGS{message} )		if( defined($ARGS{message}) );

    if( $ARGS{debug} )
	{
	print "Would $cpi_vars::SENDMAIL $ARGS{from} the following:\n",
	    map { "    $_\n" } @tosend;
	}
    elsif( $ARGS{use} eq "api" )
	{
	#print STDERR "api logic...\n";
	&sendmail( $ARGS{from}, $ARGS{to}, $ARGS{subject}, $ARGS{message} );
	}
    else	# if( $ARG{use} eq "sendmail" )
	{
	#print STDERR "sendmail logic...\n";
	&write_lines( "| $cpi_vars::SENDMAIL -t -f $ARGS{from}", @tosend );
	}
    }

#########################################################################
#	Main								#
#########################################################################
%ARGS = &parse_arguments();

&send_the_text();

&cleanup(0);
