#!/usr/bin/perl -w
#
#indx#	remind.pl - Send e-mail reminders based on user's .remind
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
#doc#	remind.pl - Send e-mail reminders based on user's .remind
#doc#	Invoked once a day in the wee hours of the morning.
########################################################################
#doc##Remind - Software to send e-mail reminders according to dated entries

use strict;
use Date::Manip;

use lib "/usr/local/lib/perl";
use cpi_vars;
use cpi_file qw( fatal echodo );
use cpi_arguments qw( parse_arguments );
use cpi_send_file qw( sendmail );

$| = 1;

# Put constants here

my @RECURRING_DAYS	= ( 0, 1, 2, 7 );
my @NON_RECURRING_DAYS	= ( 0, 1, 2, 7, 14, 30, 60 );
my $DAY_IN_SECONDS	= ( 60 * 60 * 24 );
#my $FROM		= "reminder\@brightsands.com";
my $FROM		= "chris";

my $SENDMAIL		= "/usr/lib/sendmail";
my $MAIL		= "/usr/bin/Mail";

my $address;
my %entries;
my ($tsec,$tmin,$thour,$tmday,$tmonth,$tyear,$wday);
my $UnixDateOffset	= 18000;

our %ONLY_ONE_DEFAULTS =
    (
    "debug"		=>	0,
    "time"		=>	time(),
    "remindfile"	=>	"$ENV{HOME}/.remind",
    "newremindfile"	=>	"$ENV{HOME}/.remind.new",
    "mode"		=>	"remind"
    );

# Put variables here.

our @problems;
our %ARGS;
our @files;
our $exit_stat = 0;

my $today;

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments>","",
	"where <possible arguments> is:",
	"    -r <remind file>",
	"    -t <date>",
	"    -d <debug level>"
	);
    }

#########################################################################
#	Read remind file into %entries (and set destination address).	#
#########################################################################
sub read_remind_file
    {
    open( INF, $ARGS{remindfile} ) || die("Cannot read $ARGS{remindfile}:  $!");
    while( my $input = <INF> )
	{
	#$_ = $input;
	#chomp( $_ );
	chomp( $input );
	$_ = $input;
	s/#.*//;
	s/\s*$//;
	next if( $_ eq "" );
	if( /^[^\s@]+@[\w\.]+\.\w+$/ )
	    { $address = $_; }
	elsif(  m~^(\d+)/(\d+)/(\d+):(\d+)\s*(.*)$~		||
		m~^(\d+|\*)/(\d+|\*)/(\d+|\*)(\s+)(.*)$~	)
	    {
	    my ( $mon, $day, $yr, $every, $rest ) = ( $1, $2, $3, $4, $5 );
	    my $to_print = $input;
	    my $recurring = 0;
	    if( $every =~ /\d/ )
	        {
		$to_print = $rest;
		$recurring = 1;
		}
	    $recurring=1, $mon=$tmonth	if( $mon eq "*" );
	    $recurring=1, $day=$tmday	if( $day eq "*" );
	    $recurring=1, $yr =$tyear	if( $yr  eq "*" );
	    printf("%02d/%02d/%04d:%-5s [%s]\n",
	        $mon, $day, ( $yr < 100 ? $yr + 2000 : $yr ), $every, $rest )
		if( $ARGS{debug} > 1 );
	    push(@{$entries{$address}},
		{
		"when"=>UnixDate( ParseDate( "$mon/$day/$yr" ), "%s" ) + $UnixDateOffset,
		"every"=>($every =~ /\d/ ? $every : undef),
		"type"=>($recurring?"Recurring":"Non recurring"),
		"content"=>$to_print
		});
	    }
	elsif( scalar(@{$entries{$address}}) > 0 )
	    { $entries{$address}[$#{$entries{$address}}]{"rest"}.=$input; }
	else
	    { print "$_ not connected to an entry.  Skipping.\n"; }
	}
    close( INF );
    }

#########################################################################
#	Go through entrys hash figuring out e-mail.			#
#########################################################################
sub do_mail
    {
    my $now_day = $ARGS{time} - ($ARGS{time} % $DAY_IN_SECONDS);
    my %day_flags;

    grep( $day_flags{$_}{"Recurring"}=1, @RECURRING_DAYS );
    grep( $day_flags{$_}{"Non recurring"}=1, @NON_RECURRING_DAYS );

    foreach $address ( sort keys %entries )
	{
	my $last_header = "";
	my $txt = "";
	my $found = 0;
	foreach my $offset ( sort { $a <=> $b } keys %day_flags )
	    {
	    foreach my $entry_type ( "Non recurring", "Recurring" )
		{
		if( $day_flags{$offset}{$entry_type} )
		    {
		    #$txt .= "Looking at offset=$offset entry_type=$entry_type\n";
		    my $hdr = "\n$entry_type events " .
		        ( $offset <= 0 ? "today"
			: $offset <= 1 ? "tomorrow"
			: "in $offset days" ) . ":\n";
		    for( my $ind=0; $ind<scalar(@{$entries{$address}}); $ind++ )
			{
			next if( $entries{$address}[$ind]{type} ne $entry_type );
			my $diff = $entries{$address}[$ind]{when} - $now_day;
			my $match = 0;
			
			if( ! defined( $entries{$address}[$ind]{every} ) )
			    {
			    $match = 1
				if( ($diff >= 0)
				 && ($diff > $offset*$DAY_IN_SECONDS)
				 && ($diff < ($offset+1)*$DAY_IN_SECONDS) );
			    }
			else
			    {
			    my $mdiff = $diff
			        % ($entries{$address}[$ind]{every}
				    *$DAY_IN_SECONDS);
			    $match = 1
				if( ($mdiff > $offset*$DAY_IN_SECONDS)
				 && ($mdiff < ($offset+1)*$DAY_IN_SECONDS) );

#			    my $c = $entries{$address}[$ind]{content};
#			    chomp( $c );
#			    print "diff=$diff",
#			        " mdiff=$mdiff",
#				" offset=$offset",
#				" every=",
#				( $entries{$address}[$ind]{every} || "NE" ),
#				" match=$match",
#				" [$c]\n";
			    $diff = $mdiff;
			    }

			if( $match )
			    {
			    if( $hdr ne $last_header )
				{
				$txt .= $hdr;
				$last_header = $hdr;
				}
#			    $txt .= sprintf("%d-%02d:%02d:%02d %s",
#				$diff/$DAY_IN_SECONDS,
#				($diff % $DAY_IN_SECONDS) / 3600,
#				($diff % 3600) / 60,
#				($diff %60),
			    $txt .= sprintf(" %s\n",
				$entries{$address}[$ind]{content} );
			    $found++;
			    }
			}
		    }
		}
	    }

	my $subject =
	    ( $found<=0 ?	"NO reminders for $today"
	    : $found==1 ?	"$found reminder for $today"
	    :			"$found reminders to $today" );

	if( $ARGS{debug} )
	    {
	    print "Debug Mail -s '$subject' $address\n",
	        ( $txt ? $txt : "$subject\n" );
	    }
	elsif( 1 )
	    {
	    &sendmail( $FROM, $address, $subject, $txt );
	    }
	elsif( $MAIL )
	    {
	    #print "Mail subject=[$subject] address=[$address]\n";
	    open(OUT, "|Mail -s '$subject' $address")
		|| die("Cannot run ${MAIL}:  $!");
	    print OUT ( $txt ? $txt : "$subject\n" );
	    close( OUT );
	    }
	elsif( $SENDMAIL )
	    {
	    #print "Sendmail logic.\n";
	    if( $FROM )
		{
		open(OUT, "| $SENDMAIL -t -f $FROM" )
		    || die("Cannot run ${SENDMAIL}:  $!");
		}
	    else
		{
		open(OUT, "| $SENDMAIL -t" )
		    || die("Cannot run ${SENDMAIL}:  $!");
		}
	    print OUT <<MAILEOF;
To:  $address
Subject:  $subject

$txt
MAILEOF
	    close(OUT);
	    }
	}
    }

#########################################################################
#	Read file in and sort it.					#
#########################################################################
sub do_sort
    {
    open( INF, $ARGS{remindfile} ) || &fatal("Cannot open ${ARGS{remindfile}}:  $!");
    my @lines = <INF>;
    close( INF );

    grep( s/[\r\n]+//g, @lines );

    my @other;
    my %events;

    foreach $_ ( @lines )
        {
	my( $mon, $day, $year, $interval, $rest_of_line );
	if( m~^([\d\*]+)/([\d\*]+)/([\d\*]+):([\d]+)\s+(.*)$~ )
	    {($mon,$day,$year,$interval,$rest_of_line) = ($1,$2,$3,$4,$5);}
	elsif( m~^([\d\*]+)/([\d\*]+)/([\d\*]+)\s+(.*)$~ )
	    {($mon,$day,$year,$rest_of_line) = ($1,$2,$3,$4);}
	else
	    { push( @other, $_ ); }
	if( $mon )
	    {
	    my $repeats =
		( ( $year eq "*" || $mon eq "*" || $day eq "*" || $interval )
		? 0
		: 1 );
	    my $sort_tok = sprintf("%1d %04d %02d %02d",
		$repeats,
	        ( $year eq "*" ? 0 : 2000+$year ),
		( $mon  eq "*" ? 0 : $mon ),
		( $day  eq "*" ? 0 : $day ) );
	    push( @{ $events{$sort_tok} }, $_ );
	    }
	}

    open( OUT, ">$ARGS{newremindfile}" ) || &fatal("Cannot write ${ARGS{newremindfile}}:  $!");
#    print OUT join("\n",
#        (sort @other),
#	grep( (sort @{$events{$_}}), (sort keys %events) ),
#	"" );
    print OUT join("\n",@other,"");
    foreach $_ ( sort keys %events )
        {
	print OUT join("\n",(sort @{ $events{$_} }),"");
	}
    close( OUT );

    #print "size of $ARGS{remindfile} = ", -s $ARGS{remindfile}, ".\n";
    #print "size of $ARGS{newremindfile} = ", -s $ARGS{newremindfile}, ".\n";
    &fatal("Sorting from $ARGS{newremindfile} to $ARGS{remindfile} caused a corruption.")
        if( -s $ARGS{remindfile} != -s $ARGS{newremindfile} );
    #print "+ cat '$ARGS{newremindfile}' > '$ARGS{remindfile}' && rm -f '$ARGS{newremindfile}'\n";
    &echodo("cat '$ARGS{newremindfile}' > '$ARGS{remindfile}' && rm -f '$ARGS{newremindfile}'");
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

if( $ARGS{mode} eq "sort" )
    { &do_sort(); }
else
    {
    $today = localtime( $ARGS{time} );
    $today =~ s/ \d\d:\d\d:\d\d//;
    $today =~ s/\s+/ /g;
    $today =~ s/( \d\d\d\d)/,$1/;
    ($tsec,$tmin,$thour,$tmday,$tmonth,$tyear,$wday) = localtime($ARGS{time});
    $tmonth++;
    $tyear += 1900;
    print "today=[$today]\n" if( $ARGS{debug} );
    
    &read_remind_file();
    do_mail();
    }

exit($exit_stat);
