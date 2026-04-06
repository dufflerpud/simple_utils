#!/usr/bin/perl -w
#
#indx#	setup_access_point - Configure local WIFI card to be access point
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
#hist#	2026-02-09 - Christopher.M.Caldwell0@gmail.com - Standard header
########################################################################
#doc#	setup_access_point - Configure local WIFI card to be access point
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_vars;
use Data::Dumper;

# Put constants here

my $PROJECT = "setup_ap";
my $PROG = ( $_ = $0, s+.*/++, s/\.[^\.]*$//, $_ );
my $TMP = "/tmp/$PROG.$$";
#my $TMP = "/tmp/$PROG";
my $CONFIG_BASE = "$ENV{HOME}/.config/$PROG";

my $BASEDIR = "%%PROJECTDIR%%";
$BASEDIR = "$cpi_vars::USRLOCAL/projects/$PROG" if( ! -d $BASEDIR );

my %ONLY_ONE_DEFAULTS =
    (
    #"i"	=>	"UNUSED",	# "/dev/stdin",
    #"o"	=>	"UNUSED",	# "/dev/stdout",
    "b"	=>	"Caldwell",	# Used to calculate {s}
    "d"	=>	"",		# "wlp3s0",
    "s"	=>	"",		# "Caldwell-fs0",
    "p"	=>	"deaffeed00",
    "k"	=>	"wpa-psk",
    "c"	=>	"tkip",		# Not ccmp
    "e"	=>	"rsn",
    "w"	=>	"802-11-wireless",
    "m"	=>	"0",
    "v"	=>	1,
    "n"	=>	0
    );

# Put variables here.

my @problems;
my %ARGS;
my @files;
my $exit_stat = 0;
my $config;

# Put interesting subroutines here

#=======================================================================#
#	Verbatim from prototype.pl					#
#=======================================================================#

#########################################################################
#	Print a header if need be.					#
#########################################################################
my $hdrcount = 0;
sub CGIheader
    {
    print "Content-type:  text/html\n\n" if( $hdrcount++ == 0 );
    }

#########################################################################
#	Print out a list of error messages and then exit.		#
#########################################################################
sub fatal
    {
    if( ! $ENV{SCRIPT_NAME} )
        { print join("\n",@_,""); }
    else
        {
	&CGIheader();
	print "<h2>Fatal error:</h2>\n",
	    map { "<dd><font color=red>$_</font>\n" } @_;
	}
    exit(1);
    }


#########################################################################
#	Put <form> information into %FORM (from STDIN or ENV).		#
#########################################################################
my %FORM;
sub CGIreceive
    {
    my ( $name, $value );
    my ( @fields, @ignorefields, @requirefields );
    my ( @parts );
    my $incoming = "";
    return if ! defined( $ENV{'REQUEST_METHOD'} );
    if ($ENV{'REQUEST_METHOD'} eq "POST")
	{ read(STDIN, $incoming, $ENV{'CONTENT_LENGTH'}); }
    else
	{ $incoming = $ENV{'QUERY_STRING'}; }
    
    if( defined($ENV{"CONTENT_TYPE"}) &&
        $ENV{"CONTENT_TYPE"} =~ m#^multipart/form-data# )
	{
	my $bnd = $ENV{"CONTENT_TYPE"};
	$bnd =~ s/.*boundary=//;
	foreach $_ ( split(/--$bnd/s,$incoming) )
	    {
	    if( /^[\r\n]*[^\r\n]* name="([^"]*)"[^\r\n]*\r*\nContent-[^\r\n]*\r*\n\r*\n(.*)[\r]\n/s )
		{
		#### Skip generally blank fields
		next if ($2 eq "");

		#### Allow for multiple values of a single name
		$FORM{$1} .= "," if ($FORM{$1} ne "");

		$FORM{$1} .= $2;

		#### Add to ordered list if not on list already
		push (@fields, $1) unless (grep(/^$1$/, @fields));
		}
	    elsif( /^[\r\n]*[^\r\n]* name="([^"]*)"[^\r\n]*\r*\n\r*\n(.*)[\r]\n/s )
		{
		#### Skip generally blank fields
		next if ($2 eq "");

		#### Allow for multiple values of a single name
		$FORM{$1} .= "," if (defined($FORM{$1}) && $FORM{$1} ne "");

		$FORM{$1} .= $2;

		#### Add to ordered list if not on list already
		push (@fields, $1) unless (grep(/^$1$/, @fields));
		}
	    }
	}
    else
	{
	foreach ( split(/&/, $incoming) )
	    {
	    ($name, $value) = split(/=/, $_);

	    $name  =~ tr/+/ /;
	    $value =~ tr/+/ /;
	    $name  =~ s/%([A-F0-9][A-F0-9])/pack("C", hex($1))/gie;
	    $value =~ s/%([A-F0-9][A-F0-9])/pack("C", hex($1))/gie;

	    #### Strip out semicolons unless for special character
	    $value =~ s/;/$$/g;
	    $value =~ s/&(\S{1,6})$$/&$1;/g;
	    $value =~ s/$$/ /g;

	    #$value =~ s/\|/ /g;
	    $value =~ s/^!/ /g; ## Allow exclamation points in sentences

	    #### Split apart any directive prefixes
	    #### NOTE: colons are reserved to delimit these prefixes
	    @parts = split(/:/, $name);
	    $name = $parts[$#parts];
	    if (grep(/^require$/, @parts))
		{
		push (@requirefields, $name);
		}
	    if (grep(/^ignore$/, @parts))
		{
		push (@ignorefields, $name);
		}
	    if (grep(/^dynamic$/, @parts))
		{
		#### For simulating a checkbox
		#### It may be dynamic, but useless if nothing entered
		next if ($value eq "");
		$name = $value;
		$value = "on";
		}

	    #### Skip generally blank fields
	    next if ($value eq "");

	    #### Allow for multiple values of a single name
	    $FORM{$name} .= "," if( defined($FORM{$name}) && $FORM{$name} ne "");
	    $FORM{$name} .= $value;

	    #### Add to ordered list if not on list already
	    push (@fields, $name) unless (grep(/^$name$/, @fields));
	    }
	}
    }

#########################################################################
#	Print a command and then execute it.				#
#########################################################################
sub echodo
    {
    my $cmd = join(" ",@_);
    if( ! $ARGS{v} && ! $ARGS{n} )
	{ }	# No need to print commands
    elsif( $ENV{SCRIPT_NAME} )
	{ print "<pre>+ $cmd</pre>\n"; }
    else
        { print "+ $cmd\n"; }
    return $ARGS{n} ? "" : system( $cmd );
    }

#########################################################################
#	Read an entire file and return the contents.			#
#	If open fails and a return value is not specified, fail.	#
#########################################################################
sub read_file
    {
    my( $fname, $ret ) = @_;
    if( open(COM_INF,$fname) )
        {
	$ret = do { local $/; <COM_INF> };
	close( COM_INF );
	}
    elsif( scalar(@_) < 2 )
        { &fatal("Cannot open ${fname}:  $!"); }
    return $ret;
    }

#########################################################################
#	Write an entire file.						#
#########################################################################
sub write_file
    {
    my( $fname, @contents ) = @_;
    open( COM_OUT, "> $fname" ) || &fatal("Cannot write ${fname}:  $!");
    print COM_OUT @contents;
    close( COM_OUT );
    }

#=======================================================================#
#	New code not from prototype.pl					#
#		Should at least include:				#
#			parse_arguments()				#
#			CGI_arguments()					#
#			usage()						#
#=======================================================================#

#########################################################################
#	Setup arguments if CGI.						#
#########################################################################
sub CGI_arguments
    {
    &CGIreceive();
    }

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $PROG <possible arguments>","",
	"where <possible arguments> is one or more of:",
	#"    -i	<input file>	$ONLY_ONE_DEFAULTS{i}",
	#"    -o	<output file>	$ONLY_ONE_DEFAULTS{o}",
	"    -b	<base name>	$ONLY_ONE_DEFAULTS{b}",
	"    -d	<device>	$ONLY_ONE_DEFAULTS{d}",
	"    -s	<SSID>		$ONLY_ONE_DEFAULTS{s}",
	"    -p	<password>	$ONLY_ONE_DEFAULTS{p}",
	"    -k	<key mgmt>	$ONLY_ONE_DEFAULTS{k}",
	"    -e	<encryption>	$ONLY_ONE_DEFAULTS{e}",
	"    -c	<protocol>	$ONLY_ONE_DEFAULTS{c} (ccmp does not seem to work with iPhones)",
	"    -w	<module>	$ONLY_ONE_DEFAULTS{w} (You probably do not want to change this)",
	"    -m	<mode>		$ONLY_ONE_DEFAULTS{m} (0=disable 1=enable)",
	"    -v	<flag>		$ONLY_ONE_DEFAULTS{v} (0=silent 1=verbose)",
	"    -n	<flag>		$ONLY_ONE_DEFAULTS{n} (0=do it 1=just show)"
	);
    }

#########################################################################
#	Parse the arguments						#
#########################################################################
sub parse_arguments
    {
    my $arg;
    while( defined($arg = shift(@ARGV) ) )
	{
	# Put better argument parsing here.

	if( $arg =~ /^-(.)(.*)$/ && defined($ONLY_ONE_DEFAULTS{$1}) )
	    {
	    if( defined($ARGS{$1}) )
		{ push( @problems, "-$1 specified multiple times." ); }
	    else
		{ $ARGS{$1} = ( $2 ne "" ? $2 : shift(@ARGV) ); }
	    }
	elsif( $arg =~ /^-(t)(.*)$/ )
	    {
	    my $val = ( $2 ? $2 : shift(@ARGV) );
	    if( $#files <= 0 )
	        {
		if( defined($files[$#files]->{$1}) )
		    {
		    push( @problems,
			$files[$#files]->{name} .
			    " -$1 specified multiple times." );
		    }
		else
		    { $files[$#files]->{$1} = $val; }
		}
	    elsif( defined( $ARGS{$1} ) )
		{ push( @problems, "-$1 specified multiple times." ); }
	    else
		{ $ARGS{$1} = $val; }
	    }
	elsif( $arg =~ /^-.*/ )
	    { push( @problems, "Unknown argument [$arg]" ); }
	else
	    { push( @files, $arg ); }
	}

    if( scalar(@files) == 1 && $files[0] =~ /up/i )
	{ $ARGS{m} = 1; }
    elsif( scalar(@files) == 1 && $files[0] =~ /down/i )
	{ $ARGS{m} = 0; }
    elsif( @files )
	{ push( @problems, "Do not know what to do with:  ".join(" ",@files) ); }
	
    #push( @problems, "No files specified" ) if( ! @files );
    &usage( @problems ) if( @problems );

    # Put interesting code here.

    grep( $ARGS{$_}=(defined($ARGS{$_})?$ARGS{$_}:$ONLY_ONE_DEFAULTS{$_}),
	keys %ONLY_ONE_DEFAULTS );

    if( ! defined($ARGS{m}) || $ARGS{m} eq "" )
	{ push( @problems, "-m must be specified" ); }
    elsif( $ARGS{m} != 0 && $ARGS{m} != 1 )
	{ push( @problems, "Bad value $ARGS{m} for -m" ); }
    }

#########################################################################
#	Issue nmcli commands to setup or take down an access point.	#
#########################################################################
sub do_it
    {
    &echodo("nmcli con down $ARGS{s}");
    &echodo("nmcli con delete $ARGS{s}");
    if( $ARGS{m} )
	{
	&echodo(
	    "nmcli con add type wifi",
	    "ifname $ARGS{d}",
	    "con-name $ARGS{s}",
	    "autoconnect yes",
	    "ssid $ARGS{s}",
	    "$ARGS{w}.mode ap",
	    "$ARGS{w}.band bg",
	    "ipv4.method shared",
	    "wifi-sec.key-mgmt $ARGS{k}",
	    "wifi-sec.psk '$ARGS{p}'",
	# Enforce WPA2
	    "$ARGS{w}-security.proto $ARGS{e}",
	# Enfore specified encryption
	    "$ARGS{w}-security.pairwise $ARGS{c}",
	    "$ARGS{w}-security.group $ARGS{c}",
	# BUG FIX
	    "$ARGS{w}-security.pmf 1");
    # Active the hotspot
	&echodo("nmcli con up $ARGS{s}");
	}
    }

#########################################################################
#	Some argument defaults should be determined by getting		#
#	interfaces and hostname.					#
#########################################################################
sub calculate_defaults
    {
    my $hostname = &read_file("hostname | ");
    chomp( $hostname );
    $config = ( $hostname ? "$CONFIG_BASE.$hostname" : $CONFIG_BASE );

    eval( &read_file($config) ) if( -r $config );
    
    if( ! $ONLY_ONE_DEFAULTS{d} )
	{
	foreach my $ln ( split(/\n/,&read_file("ifconfig -a |")) )
	    {
	    $ONLY_ONE_DEFAULTS{d}=$1 if( $ln =~ /^(w\w*):/ );
	    }
	}

    if( ! $ONLY_ONE_DEFAULTS{s} && $hostname )
	{
	my $no_domain = $hostname;
	$no_domain =~ s/\..*//;
	$ONLY_ONE_DEFAULTS{s} = "$ONLY_ONE_DEFAULTS{b}-$no_domain";
	}
    }

#########################################################################
#	Main								#
#########################################################################

&calculate_defaults();

if( 0 && $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

#print join("\n\t","$PROG args:",map{"$_:\t$ARGS{$_}"} sort keys %ARGS), "\n";

&do_it();

# Save interesting part of configuration
print STDERR "Creating $config.\n" if( ! -r $config );
$ARGS{m} = 0;	# Don't ever want to DEFAULT to setting up access point
$ARGS{n} = 0;	# Don't ever want to DEFAULT to doing nothing
$Data::Dumper::Indent = 1;
&write_file($config,  Data::Dumper->Dump( [ \%ARGS ], [ qw(*ONLY_ONE_DEFAULTS) ] ) );

exec("rm -rf $TMP");
