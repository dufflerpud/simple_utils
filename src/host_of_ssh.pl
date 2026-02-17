#!/usr/bin/perl -w
#
#indx#	host_of_ssh - Print info about inbound SSH connections
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
#doc#	host_of_ssh - Print info about inbound SSH connections.
#doc#	Filters output of lsof.
########################################################################

my $DEBUG = 0;

use strict;

$ENV{PATH} = join(":",$ENV{PATH},"/sbin","/usr/sbin");

my @pidlist = ();
while( $_ = shift(@ARGV) )
    {
    if( $_ eq "-d" )
	{ $DEBUG = 1; }
    else
        { push( @pidlist, $_ ); }
    }

push( @pidlist, $$ ) if( ! @pidlist );

my %pid_to_parent = ();
my %pid_to_ps = ();
open( INF, "ps -efww |" ) || die "Cannot run ps:  $!";
while( $_ = <INF> )
    {
    chomp( $_ );
    my($user,$pid,$ppid,$c,$stime,$tty,$time,@rest) = split(/\s+/);
    $pid_to_ps{$pid} = $_;
    $pid_to_parent{$pid} = $ppid;
    }
close( INF );

my %pid_to_lsof = ();
open( INF, "lsof -n 2>/dev/null |" ) || die "Cannot run lsof:  $!";
my $header = <INF>;
while( $_ = <INF> )
    {
    chomp( $_ );
    my($cmd,$pid,$user,$fd,$type,$device,$size_off,@rest) = split(/\s+/);
    push( @{$pid_to_lsof{$pid}}, $_ );
    }
close( INF );

my $exit_status = 0;
foreach my $pid ( @pidlist )
    {
    my $final_ip;
    while( ! $final_ip )
	{
	print $pid_to_ps{$pid}, "\n" if( $DEBUG );
	$_ = join("\n",@{$pid_to_lsof{$pid}});
	if( $_ =~ /TCP (.*?):ssh->(.*?):/s )
	    {
	    $final_ip = $2;
	    #print $_, "\n" if( $DEBUG );
	    print "\n", grep(/TCP (.*?):ssh->(.*?):/, @{$pid_to_lsof{$pid}}), "\n"
		if( $DEBUG );
	    }
	$pid = $pid_to_parent{$pid};
	last if( $pid <= 1 );
	}

    if( ! $final_ip )
        { $exit_status=1; }
    else
        { print $final_ip, "\n"; }
    }
exit( $exit_status );
