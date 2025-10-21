#!/usr/bin/perl -w
#@HDR@	$Id$
#@HDR@		Copyright 2024 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.

#########################################################################
#	sudoinstall.pl							#
#		2024-04-18	- c.m.caldwell@alumni.unh.edu		#
#									#
#	A utility to run the install command, usually used by Makefile.	#
#	Attempts the install first, and if it fails, does the same	#
#	command under sudo.  Prevents user from having to become root	#
#	just to do an install (all they need to do is type in their	#
#	password).  If Makefile is already running as root		#
#	presumably the install won't fail, so we don't do a sudo.	#
#########################################################################

use strict;

my $INSTALLER = "/bin/install";
my $SUDO = "/bin/sudo";

my $cmdstring = join(" ",map {"'$_'"} ($INSTALLER,@ARGV));

#print STDERR __LINE__,": open($cmdstring)...\n";
open( CMDRESULT, "$cmdstring 2>&1 |")
    || die("Cannot run ${cmdstring}:  $!");
my $result_contents = join("",<CMDRESULT>);
close( CMDRESULT );
my $result = $?;
if( !$result
  || ( $result_contents!~/Permission denied/i 
     && $result_contents!~/Operation not permitted/i ) )
    {
    print $result_contents;
    }
else
    {
    $cmdstring = join(" ",map {"'$_'"} ($SUDO,$INSTALLER,@ARGV));
    #print STDERR __LINE__,": exec($cmdstring)...\n";
    exec( $cmdstring );
    die( "exec $cmdstring failed:  $!" );
    }
exit($result);
