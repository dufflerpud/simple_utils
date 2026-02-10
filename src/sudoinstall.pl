#!/usr/bin/perl -w
#
#indx#	sudoinstall.pl - Try to install something.  I fail, sudo and try again.
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
#hist#	2024-04-18 - Christopher.M.Caldwell0@gmail.com - Created
#hist#	2026-02-09 - Christopher.M.Caldwell0@gmail.com - Standard header
########################################################################
#doc#	sudoinstall.pl - Try to install something.  I fail, sudo and try again.
#doc#	A utility to run the install command, usually used by Makefile.	#
#doc#	Attempts the install first, and if it fails, does the same	#
#doc#	command under sudo.  Prevents user from having to become root	#
#doc#	just to do an install (all they need to do is type in their	#
#doc#	password).  If Makefile is already running as root		#
#doc#	presumably the install won't fail, so we don't do a sudo.	#
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
