#!/usr/bin/perl -w
#
#indx#	formulae.pl - A program for simple re-calculations on the Web
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
#hist#	2026-10-10 - Christopher.M.Caldwell0@gmail.com - Created header
########################################################################
#doc#	A program for simple re-calculations on the Web
########################################################################

use strict;
use lib "/usr/local/lib/perl";
use cpi_file qw( fatal );
use cpi_cgi qw( CGIreceive CGIheader );
use cpi_setup qw( setup );
use cpi_vars;

my @VARIABLE_ORDER;
my %FORMULAE;
my %UNITS;
my $WIDTH = 0;
my %DISPLAY_AS;
my $SHOW_WORK = 0;
my %WORK;

my $default_unit_type = "Metric";

my $PI = 3.141592654;
my $DEG_TO_RAD = $PI/180.0;
my $SEC_TO_MIN = 60;
my $SEC_TO_HOUR = 60 * $SEC_TO_MIN;
my $ROT_TO_DEG = 360.0;

my %CONVERSIONS=
    (
    "degrees * degrees"				=> 1,
    "degrees * radians"				=> $DEG_TO_RAD,
    "rotations/second * rotations/second"	=> 1,
    "rotations/second * rotations/minute"	=> $SEC_TO_MIN,
    "rotations/second * rotations/hour"		=> $SEC_TO_HOUR,
    "rotations/second * degrees/second"		=> $ROT_TO_DEG,
    "rotations/second * degrees/minute"		=> $ROT_TO_DEG/$SEC_TO_MIN,
    "rotations/second * degrees/hour"		=> $ROT_TO_DEG/$SEC_TO_HOUR,
    "rotations/second * radians/second"		=> $ROT_TO_DEG*$DEG_TO_RAD,
    "rotations/second * radians/minute"		=> $ROT_TO_DEG*$DEG_TO_RAD/$SEC_TO_MIN,
    "rotations/second * radians/hour"		=> $ROT_TO_DEG*$DEG_TO_RAD/$SEC_TO_HOUR,
    "meters Metric meters"			=> 1,
    "meters Metric kilometers"			=> 0.001,
    "meters Imperial inches"			=> 39.37,
    "meters Imperial feet"			=> 3.28,
    "meters Imperial miles"			=> 0.00062137,
    "meters/second Metric meters/second"	=> 1,
    "meters/second Metric kilometers/second"	=> 0.001,
    "meters/second Metric kilometers/hour"	=> 0.36,
    "meters/second Imperial miles/second"	=> 0.00062137,
    "meters/second Imperial miles/hour"		=> 2.2369,
    "meters/second Imperial feet/second"	=> 3.2808,
    "meters/second Imperial feet/hour"		=> 11811.0236,
    "meters/second^2 Metric meters/second^2"	=> 1,
    "meters/second^2 * Gs"			=> 0.1019367,
    "meters/second^2 Imperial miles/second^2"	=> 0.00062137,
    "meters/second^2 Imperial feet/second^2"	=> 3.2808399,
    );

my %UNIT_TO_CONV = ();

my %RESERVED = map { $_, 1 } ( "sqrt", "cos", "cosdeg", "sin", "sindeg" );

my %NARGS =
    (
    "help"=>0, "dump"=>0, "Metric"=>0, "Imperial"=>0, "show"=>0,
    "exit"=>0, "quit"=>0, "clear"=>1, "clear_all"=>0,
    "show_work"=>0, "hide_work"=>0
    );

my $DIGITS	= 10;

my %given = ();
my %calculated = ();
my %tried = ();
my %definitions = ();

#########################################################################
#	Some helper functions.						#
#########################################################################
sub sindeg	{ return sin( $_[0] * $DEG_TO_RAD ); }
sub cosdeg	{ return cos( $_[0] * $DEG_TO_RAD ); }

#########################################################################
#	Determine the value of a variable, recursing through formula	#
#	definitions as needed.						#
#########################################################################
sub calculate
    {
    my( $vname ) = @_;
    my $nl = ( $ENV{SCRIPT_NAME} ? "<br><ul>" : "\n\t" );

    return $given{$vname}	if(  defined($given{$vname}      ) );
    return $calculated{$vname}	if(  defined($calculated{$vname} ) );
    return undef		if(  defined($tried{$vname}	 ) );
    #return undef		if( !defined($FORMULAE{$vname}   ) );

    $tried{$vname} = 1;

    if( $FORMULAE{$vname} )
	{
	foreach my $formula ( @{$FORMULAE{$vname}} )
	    {
	    my @to_evaluate = ();
	    my $formula_ok = 1;
	    foreach my $piece ( split(/([a-zA-Z]\w*)/,$formula) )
		{
#		    print $piece, " is ",
#		        ( defined($RESERVED{$piece})
#		        ? "A function"
#			: "Not a function" ),
#			"\n";
		if( $piece !~ /^[a-zA-Z]/ || $RESERVED{$piece} )
		    { push( @to_evaluate, $piece ); }
		else
		    {
		    my $result = &calculate( $piece );
#			print "Calculate($piece) returned ",
#			    ( defined($result) ? $result : "Undefined" ),
#			    "\n";
		    if( defined($result) )
			{ push( @to_evaluate, $result ); }
		    else
			{
			$formula_ok = 0;
			last;
			}
		    }
		}
	    if( $formula_ok )
		{
		my $substdone = join("",@to_evaluate);
		$substdone =~ s/\^/**/gs;
		$calculated{$vname} = eval( $substdone );
		$WORK{$vname} = $formula .
		    ( $formula ne $substdone
			?  " or $substdone" : "" ) .
		    ( $calculated{$vname} ne $substdone
			? " or $calculated{$vname}" : "" )
		    if( $formula !~ /^[\d\-\.]+$/ );
		return $calculated{$vname};
		}
	    else
		{
		# print "Rejecting $formula.\n";
		}
	    }
	}
    return undef;
    print STDERR "Not enough information to calculate $vname.\n";
    }

#########################################################################
#	Print a category if any entries in it.				#
#########################################################################
sub print_category
    {
    my( $mode, $title, $color, @vals ) = @_;
    if( ! @vals )
        { return ""; }
    elsif( ! $mode )
	{ return ( $title, @vals ); }
    else
	{
	$_ = join("",
	    "<tr><th CAT_SUBST style='border-top:2px outset black;' align=left colspan=4>$title</th></tr>",@vals);
	$_ =~ s/CAT_SUBST/bgcolor='$color'/g;
	return $_;
	}
    }

#########################################################################
#	Look up conversion factor for a particular unit and
#########################################################################
sub search_conv
    {
    my( $uname, $val, $tofrom ) = @_;
    foreach my $entry ( keys %CONVERSIONS )
        {
	return
	    ( $tofrom
	    ? $val * $CONVERSIONS{$entry}
	    : $val / $CONVERSIONS{$entry}
	    ) if( $entry =~ /^(.*?)\s+(.*?)\s+(.*?)$/ && $3 eq $uname );
	}
    }

#########################################################################
#	Set a default units based on the unit type.			#
#########################################################################
sub set_units
    {
    my( $unit_type, @vlist ) = @_;
    @vlist = @VARIABLE_ORDER if( ! @vlist );
    foreach my $vname ( @vlist )
        {
	my $units = $UNITS{$vname}[0];

	next if( ! defined($units) );

	my $v = (defined($given{$vname}) ? $given{$vname} : &calculate($vname));

	my $best_units;
	my $best_value = 0;
	my $fallback_units = $units;

	foreach my $entry ( keys %CONVERSIONS )
	    {
	    if( $entry =~ /^(.*?)\s+(.*?)\s+(.*?)$/
		&& $1 eq $units
		&& ( $2 eq "*" || $unit_type eq "" || $unit_type eq $2 ) )
		{
		my( $new_units ) = $3;
		$fallback_units = $new_units;
		if( defined($v) )
		    {
		    my( $cur_value ) = $v * $CONVERSIONS{$entry};
		    if( $cur_value > $best_value && $cur_value < 10000.0 )
			{
			$best_value = $cur_value;
			$best_units = $new_units;
			}
		    }
		}
	    }
	$best_units = $fallback_units if( ! defined($best_units) );
	$DISPLAY_AS{$vname} = $best_units;
	}
    }

#########################################################################
#	Return units specified for particular variable.			#
#	This usually just returns the set value, but may need to figure	#
#	it out.								#
#########################################################################
sub units_for
    {
    my( $vname ) = @_;
    &set_units($default_unit_type,$vname) if( !defined($DISPLAY_AS{$vname}) );
    return $DISPLAY_AS{$vname};
    }

#########################################################################
#	Print out all of the various variables, sorting them out.	#
#	Handles both stdout and CGI.					#
#########################################################################
sub print_world
    {
    my( $mode, $show_work ) = @_;
    my @givens = ();
    my @calculateds = ();
    my @unknowns = ();
    my @constants = ();
    %calculated = ();
    my @text = ();
    %WORK = ();
    foreach my $vname ( @VARIABLE_ORDER )
        {
	%tried = ();

	my $units = $UNITS{$vname}[0];

	next if( ! defined($units) );

	my $v = (defined($given{$vname}) ? $given{$vname} : &calculate($vname));
	my $best_value;

	if( defined($v) )
	    {
	    $best_value = $v * $UNIT_TO_CONV{&units_for($vname)};
	    #print "v=$v da=$DISPLAY_AS{$vname} c=",$UNIT_TO_CONV{$DISPLAY_AS{$vname}}
	    }

	if( !defined($best_value) )
	    { $best_value = "Unknown"; }
	else
	    {
	    my $dec;
	       if( $best_value > 10000	)  	{ $dec = 0; }
	    elsif( $best_value > 1000	) 	{ $dec = 1; }
	    elsif( $best_value > 100	)	{ $dec = 2; }
	    elsif( $best_value > 10	)	{ $dec = 3; }
	    elsif( $best_value > 1	)	{ $dec = 4; }
	    elsif( $best_value > 0.1	)	{ $dec = 5; }
	    elsif( $best_value > 0.01	)	{ $dec = 6; }
	    elsif( $best_value > 0.001	)	{ $dec = 7; }
	    elsif( $best_value > 0.0001	)	{ $dec = 8; }

	    $best_value = sprintf("%.${dec}f",$best_value) if( defined($dec) );
	    }

#	print $vname, ": ",
#	    "FU=",
#	    (defined($cpi_vars::FORM{"units_$vname"})?$cpi_vars::FORM{"units_$vname"}:"Unknown"),
#	    " v=", (defined($v)?$v:"(Unknown)"),
#	    " units=$units best_units=$best_units value=$best_value.<br>\n";

	my $line;

	if( ! $mode )
	    {
	    my $wid = $WIDTH + 2;
	    $line = sprintf("  %-${wid}s%${DIGITS}s XL(%s)",
		$vname.":", $best_value, &units_for($vname) );
	    $line = join("\n\t",$line,split(/ or /,$WORK{$vname}))
		if( $show_work && defined($WORK{$vname}) );
	    $line .= "\n";
	    }
	else
	    {
	    my $pretty_vname = $vname;
	    $pretty_vname =~ s/_/ /g if( $ENV{SCRIPT_NAME} );
	    $best_value = "" if( $best_value eq "Unknown" );

	    my $nrow = 1;
	    my @works = ();

	    $line = "<tr><th valign=top align=left CAT_SUBST>"
	        . "&nbsp;&nbsp;&nbsp;&nbsp;"
		. "XL(${pretty_vname}):</th>";
	    $line .= "<td CAT_SUBST>";
		$line .= join("<br>or ",split(/ or /,$WORK{$vname}))
		    if( $show_work && defined($WORK{$vname}) );

	    $line .= "</td><td align=right CAT_SUBST>";

	    if( $given{$vname} || ! defined($v) )
		{
		$line .= "<input type=text name=$vname onChange='submit();'";
		$line .= " placeholder='".$pretty_vname."'";
		$line .= " value='$best_value'" if(defined($best_value));
		$line .= " style='text-align:right'>";
		}
	    else
	        { $line .= $best_value; }
	    $line .= "<td CAT_SUBST>"
		. "<input type=hidden name=old_$vname value="
		. "\"" . &units_for( $vname ) . "\">"
	        . "<select name=units_$vname"
	        . " onChange='submit();'>";
	    foreach my $entry ( sort keys %CONVERSIONS )
	        {
		$line .= "<option value='$3'"
		    . ( &units_for($vname) eq $3 ? " selected" : "" )
		    . ">XL($3)\n"
		    if( $entry =~ /^(.*?)\s+(.*?)\s+(.*?)$/
			&& $1 eq $units );
		}
	    $line .= "</select></td></tr>\n";
	    grep( $line .= "<tr><td colspan=2 CAT_SUBST>$_</td></tr>\n", @works );
	    }
	if( !defined($given{$vname}) && $FORMULAE{$vname}[0]=~/^[\d\.]+$/ )
	    { push( @constants, $line ); }
	elsif( defined($given{$vname}) )
	    { push( @givens, $line ); }
	elsif( defined($v) )
	    { push( @calculateds, $line ); }
	else
	    { push( @unknowns, $line ); }
	}

    if( $mode )
        {
	my @fncs = ();
	push( @text, <<EOF );
</head><body $cpi_vars::BODY_TAGS>
<form name=form method=post>
<input type=hidden name=show_work value=$SHOW_WORK>
<center><table cellspacing=0 frame=box>
<tr><td>
    <select name=fnc onChange='submit();'>
	<option>XL(Select command)
        <option value=Metric>XL(Set Metric units)
        <option value=Imperial>XL(Set Imperial units)
	<option value=hide_work>XL(Hide work)
	<option value=show_work>XL(Show work)
	<option value=clear_all>XL(Clear all)
EOF
	grep( push(@text,"<option value='$_'>XL($_)"), sort keys %definitions );
	push( @text, <<EOF );
    </select></td></tr>
EOF
	}
    push( @text,
	&print_category( $mode, "XL(Constants):",  "#d0d0d0", @constants  ),
	&print_category( $mode, "XL(Given):",      "#d0ffff", @givens     ),
	&print_category( $mode, "XL(Calculated):", "#d0ffd0", @calculateds),
	&print_category( $mode, "XL(Unknowns):",   "#ff8080", @unknowns   ) );
    push( @text, "</table></center></form>\n" ) if( $mode );
    $_ = join("",@text);
    s+XL\((.*?)\)+$1+gs;
    print $_;
    }

#########################################################################
#	Do calculations from stdin and stdout.				#
#########################################################################
sub read_commands
    {
    my( $fh, @remainder ) = @_;
    $default_unit_type = "Metric";

    my $var;
    my $def;

    while( 1 )
	{
	if( @remainder )
	    { $_ = pop( @remainder ); }
	elsif( ! $fh )
	    { last; }
	else
	    {
	    print "> " if( -t $fh );
	    last if( ! defined( $_ = <$fh> ) );
	    }
	s/\s*[\r\n#].*//s;
	s/^\s*//g;
	if( $def )
	    {
	    $definitions{$def} .= "\n$_";
	    $NARGS{$def} = 0;
	    if( $definitions{$def} =~ /(.*?)}(.*)/s )
	        {
		$definitions{$def} = $1;
		push( @remainder, $2 );
		undef $def;
		}
	    }
	elsif( $var )
	    {
	    $var .= " $_";
	    if( $var =~ /(.*?);(.*)/ )
	        {
		$var = $1;
		push( @remainder, $2 );

		my( $vname, @attributes ) = grep( $_ ne "", split(/\s+/,$var) );

		next if( !defined($vname) || $vname eq "" );
		push( @VARIABLE_ORDER, $vname );

		$_ = length($vname);
		$WIDTH = $_ if( $_ > $WIDTH );

		foreach my $attribute ( @attributes )
		    {
		    if( defined($UNIT_TO_CONV{$attribute}) )
			{ push( @{$UNITS{$vname}}, $attribute ); }
		    else
			{ push( @{$FORMULAE{$vname}}, $attribute ); }
		    }
		$NARGS{$vname} = 1;
		&set_units( $default_unit_type, $var );
		undef $var;
		}
	    }
	elsif( /^var\s+(.*?)$/ )
	    {
	    $var = $1;
	    }
	elsif( /^problem\s+(.*?)\s+{(.*)/ )
	    {
	    $def = $1;
	    $definitions{$def} = $2;
	    }
	elsif( /\s*([A-Za-z]\w*)\s*=\s*(.+?)\s+(.+?)$/ )
	    {
	    my( $vname, $v, $unit ) = ( $1, $2, $3 );
	    if( ! $UNITS{$vname} )
	        { print STDERR "$vname is not a variable.\n"; }
	    elsif( $v !~ /^[\d\.]+$/ )
	        { print STDERR "$v is not a number.\n"; }
	    elsif( ! defined($UNIT_TO_CONV{$unit}) )
	        { print STDERR "$unit is not a unit of measure.\n"; }
	    else
	        {
		$DISPLAY_AS{$vname} = $unit;
		$given{$vname} = $v / $UNIT_TO_CONV{$unit};
		}
	    }
	elsif( /\s*([A-Za-z]\w*)\s*=\s*(.*?)\s*$/ )
	    {
	    my( $vname, $v ) = ( $1, $2 );
	    if( ! $UNITS{$vname} )
	        { print STDERR "$1 is not a variable.\n"; }
	    elsif( $v !~ /^[\d\.]+$/ )
	        { print STDERR "$2 is not a number.\n"; }
	    else
	        { $given{$vname} = $v / $UNIT_TO_CONV{&units_for($vname)}; }
	    }
	else
	    {
	    my( $cmd, @toks ) = split(/\s+/);
	    my $nargs = scalar(@toks);

	    if( defined($cmd) )
		{
		if( !  defined($NARGS{$cmd}) )
		    { print STDERR "Unrecognized command \"$cmd\".\n"; }
		else
		    {
		    if( $NARGS{$cmd} != $nargs )
		        {
			print STDERR
			    "Incorrect number of arguments for '$cmd'.\n";
			}
		    elsif( $cmd eq "help" )
		        { &do_help(); }
		    elsif( $cmd eq "dump" )
		        { &dump_definitions(); }
		    elsif( $cmd eq "Metric" || $cmd eq "Imperial" )
			{
			$default_unit_type = $cmd;
			&set_units( $default_unit_type, @VARIABLE_ORDER );
			}
		    elsif( $cmd eq "show" )
			{ &print_world( 0, $SHOW_WORK ); }
		    elsif( $cmd eq "show_work" )
			{ $SHOW_WORK=1; }
		    elsif( $cmd eq "hide_work" )
			{ $SHOW_WORK=0; }
		    elsif( $cmd eq "exit" || $cmd eq "quit" )
			{ exit(0); }
		    elsif( $cmd eq "clear_all" )
		        { %given = (); }
		    elsif( $cmd eq "clear" )
			{
			if( ! defined( $given{$toks[0]} ) )
			    { print STDERR "No value to clear in $toks[0].\n"; }
			else
			    { undef $given{ $toks[0] }; }
			}
		    elsif( defined($UNIT_TO_CONV{$cmd}) )
			{
			if( ! $UNITS{$toks[0]} )
			    { print STDERR "$toks[0] is not a variable.\n"; }
			else
			    { $DISPLAY_AS{$toks[0]} = $cpi_vars::FORM{"units_$toks[0]"} = $cmd; }
			}
		    elsif( $UNITS{$cmd} )
			{
			if( ! $UNIT_TO_CONV{$toks[0]} )
			    { print STDERR "$toks[0] is not a unit type.\n"; }
			else
			    { $DISPLAY_AS{$cmd} = $cpi_vars::FORM{"units_$cmd"} = $toks[0]; }
			}
		    elsif( $definitions{$cmd} )
		        {
			push( @remainder,
			    reverse split(/\n/s,$definitions{$cmd}) );
			}
		    }
		}
	    }
	}
    }

#########################################################################
#	Print out the possible commands.				#
#########################################################################
sub do_help
    {
    $_ = join("\n\t","XL(Commands are):",sort keys %NARGS);
    s+XL\((.*?)\)+$1+gs;
    print $_, "\n";
    }

#########################################################################
#	Print the variable definitions.					#
#########################################################################
sub dump_definitions
    {
    foreach my $vname ( @VARIABLE_ORDER )
        {
	print $vname;
	print " ", join(" ",@{$UNITS{$vname}}) if( $UNITS{$vname} );
	print "\n\t# DISPLAY_AS=$DISPLAY_AS{$vname}" if( $DISPLAY_AS{$vname} );
	print "\n\t",join("\n\t",@{$FORMULAE{$vname}}) if( $FORMULAE{$vname} );
	print " ;\n";
	}
    foreach my $def ( sort keys %definitions )
        {
	print "define $def { ", $definitions{$def}, "}\n";
	}
    }

#########################################################################
#	Interactive logic for web servers.				#
#########################################################################
sub CGI_logic
    {
    &CGIreceive();
    &CGIheader();
    #print "Content-type:  text/html\n\n";
    $SHOW_WORK = ($cpi_vars::FORM{show_work} || 0);
    foreach my $vname ( @VARIABLE_ORDER )
        {
	$DISPLAY_AS{$vname} = $cpi_vars::FORM{"units_$vname"}
	    if( $cpi_vars::FORM{"units_$vname"} );
	if( defined($cpi_vars::FORM{$vname}) && $cpi_vars::FORM{$vname} ne "" && $cpi_vars::FORM{$vname} ne "Unknown" )
	    {
	    if( $cpi_vars::FORM{"old_$vname"}
		&& $cpi_vars::FORM{"old_$vname"} ne $DISPLAY_AS{$vname} )
		{
		$given{$vname} = $cpi_vars::FORM{$vname}
		    / $UNIT_TO_CONV{$cpi_vars::FORM{"old_$vname"}};
		}
	    else
		{
		$given{$vname} = $cpi_vars::FORM{$vname}
		    / $UNIT_TO_CONV{$DISPLAY_AS{$vname}};
		}
	    }
	}
    &read_commands( "", $cpi_vars::FORM{fnc} ) if( defined( $cpi_vars::FORM{fnc} ) );
    &print_world( 1, $SHOW_WORK );
    }

#########################################################################
#	Define a conversion factor (and a command based on the name).	#
#	Is smart and defines the singular version as well.		#
#	This allows users to say "1 inch" instead of "1 inches".	#
#########################################################################
sub set_conv
    {
    my( $unit, $conv ) = @_;
    $UNIT_TO_CONV{$unit} = $conv;
    $NARGS{$unit} = 1;
    $unit =~ s+es$++;
    $unit =~ s+s$++;
    $unit =~ s+es/+/+;
    $unit =~ s+s/+/+;
    $UNIT_TO_CONV{$unit} = $conv;
    $NARGS{$unit} = 1;
    }

#########################################################################
#	Setup definitions and conversions.				#
#########################################################################
sub local_setup
    {
    foreach my $ucon ( keys %CONVERSIONS )
	{
	if( $ucon =~ /^(.+?)\s+(.+?)\s+(.+?)$/ )
	    {
	    my( $baseunit, $unittype, $destunit ) = ( $1, $2, $3 );
	    &set_conv( $baseunit, 1.0 );
	    &set_conv( $destunit, $CONVERSIONS{$ucon} );
	    }
	}
    open( INF, $ARGV[0] ) || die("Cannot read $ARGV[0]:  $!");
    &read_commands( *INF );
    close( INF );
    #&dump_definitions();
    }

#########################################################################
#	Main								#
#########################################################################
&setup( nologin=>1 );
&local_setup();
if( $ENV{SCRIPT_NAME} )
    { &CGI_logic(); }
else
    { &read_commands( *STDIN ); }
