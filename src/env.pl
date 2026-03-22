#!/usr/bin/perl -w
#
#indx#	env.pl - Print standard perl variables including environment
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
#hist#	2026-03-22 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	env.pl - Print standard perl variables including environment
#doc#	(Tries to be smart about whether being called as CGI or not)
########################################################################

use strict;

sub htmlit
    {
    my( $v ) = @_;
    $v =~ s/&/\&amp;/g;
    $v =~ s/</\&lt;/g;
    $v =~ s/>/\&gt;/g;
    return $v;
    }

sub onevar
    {
    my( $varname, $varval, $description ) = @_;
    $varval =
        ( ! defined( $varval )
	    ? "(undefined)"
	: ref($varval) eq "ARRAY"
	    ? "[".join(", ",@{$varval})."]"
	: ref($varval) eq "HASH"
	    ? "{".join(', ',(map{"$_=>".(defined($varval->{$_})?$varval->{$_}:"(undefined)")} keys %{$varval}))."}"
	: $varval );
    if( $ENV{SCRIPT_FILENAME} )
        { print "<tr>",
		"<th width=10% align=left valign=top>", &htmlit($varname), "</th>",
		"<td width=30% valign=top>", &htmlit($varval), "</td>",
		"<td valign=top>", &htmlit($description), "</td></tr>\n";
    	}
    else
        { print "$varname\t$varval\t$description\n"; }
    }

if( $ENV{SCRIPT_FILENAME} )
    {
    print "Content-type:  text/html\n\n",
    	"<table style='border-collapse:collapse'>",
	"<tr><th>Variable</th><th>Value</th><th>Description</th></tr>\n";
    }
else
    {
    print "Name\tValue\tDescription\n";
    }

&onevar('$_',$_,'The default input and pattern-searching space');
&onevar('@_',"[".join(',',@_)."]",'Within a subroutine the array @_ contains the parameters passed to that subroutine');
&onevar('$"',$",'When an array or an array slice is interpolated into a double-quoted string or a similar context such as /.../, its elements are separated by this value');
&onevar('$$',$$,'The process number of the Perl running this script');
&onevar('$0',$0,'Contains the name of the program being executed');
&onevar('$(',$(,'The real gid of this process');
&onevar('$)',$),'The effective gid of this process');
&onevar('$<',$<,'The real uid of this process');
&onevar('$>',$>,'The effective uid of this process');
&onevar('$;',$;,'The subscript separator for multidimensional array emulation');
#&onevar('$a, $b',"$a, $b",'Special package variables when using sort(), see "sort" in perlfunc');
&onevar('%ENV',\%ENV,'The hash %ENV contains your current environment');
&onevar('$]',$],'The revision, version, and subversion of the Perl interpreter, represented as a decimal of the form 5.XXXYYY, where XXX is the version / 1e3 and YYY is the subversion / 1e6');
&onevar('$^F',$^F,'The maximum system file descriptor, ordinarily 2. System file descriptors are passed to exec()ed processes, while higher file descriptors are not');
#&onevar('@F',\@F,'The array @F contains the fields of each line read in when autosplit mode is turned on');
&onevar('@INC',\@INC,'The array @INC contains the list of places that the do EXPR, require, or use constructs look for their library files');
&onevar('%INC',\%INC,'The hash %INC contains entries for each filename included via the do, require, or use operators');
&onevar('$INC',$INC,'As of 5.37.7 when an @INC hook is executed the index of the @INC array that holds the hook will be localized into the $INC variable');
&onevar('$^I',$^I,'The current value of the inplace-edit extension');
#&onevar('@ISA',\@ISA,'Each package contains a special array called @ISA which contains a list of that class's parent classes, if any');
&onevar('$^M',$^M,'Perl can use the contents of $^M as an emergency memory pool after die()ing');
&onevar('${^MAX_NESTED_EVAL_BEGIN_BLOCKS}',${^MAX_NESTED_EVAL_BEGIN_BLOCKS},'This variable determines the maximum number eval EXPR/BEGIN or require/BEGIN block nesting that is allowed');
&onevar('$^O',$^O,'The name of the operating system under which this copy of Perl was built, as determined during the configuration process');
&onevar('%SIG',\%SIG,'The hash \%SIG contains signal handlers for signals');
&onevar('%{^HOOK}',\%{^HOOK},'This hash contains coderefs which are called when various perl keywords which are hard or impossible to wrap are called');
&onevar('$^T',$^T,'The time at which the program began running, in seconds since the epoch (beginning of 1970)');
&onevar('$^V',$^V,'The revision, version, and subversion of the Perl interpreter, represented as a version object');
#&onevar('$^X',$^X,'The name used to execute the current copy of Perl, from C's argv[0] or (where supported) /proc/self/exe');
#And this is one last line.

print "</table>\n" if( $ENV{SCRIPT_NAME} );
