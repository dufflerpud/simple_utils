#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_vars;
use cpi_file qw( fatal cleanup autopsy echodo read_lines mkdirp fqfiles_in );
use cpi_filename qw( just_ext_of );
use cpi_arguments qw( parse_arguments );

#epson2:net:scan0
#airscan:e0:Brother MFC-L3720CDW series

my $TMP="/tmp/$cpi_vars::PROG";		# or /tmp/$cpi_vars::PROG.$$
my $CVT="/usr/local/bin/nene";
my $AUTOMATIC="ADF";		# Was "Automatic", not "ADF"
my $PAMEXT="pnm";		# Pamcut likes this best

my $exit_status=1;

our %ONLY_ONE_DEFAULTS =
    (
    output_file		=> "scan_output.pdf",
    device		=> $ENV{SCANNER}||"scan0",
    mode		=> "Color",
    resolution		=> 600,
    host		=> "fs0",
    type		=> "epson2",	# Was "epkowa"
    ip			=> "scan0",
    sides		=> 0,		# 1 would imply batch_mode
    batch_mode		=> 0,
    gs			=> "",
    papersize		=> "",
    1			=> { alias=>["-sides=1"] },
    2			=> { alias=>["-sides=2"] },
    a3			=> { alias=>["-papersize=a3"] },
    a4			=> { alias=>["-papersize=a4"] },
    afeed		=> { alias=>["-autofeed"] },
    scanimage_arguments	=> "",
    top			=> "",
    bottom		=> "",
    left		=> "",
    right		=> "",
    verbosity		=> 0,
    debug		=> 0,
    );
our %ARGS;
our @problems;

#########################################################################
#	Print usage message and exit.					#
#########################################################################
sub usage
    {
    &fatal(@_,"","Usage:  $cpi_vars::PROG <arg> <file>",
	"where <file> is the resulting scanned file",
	"and <arg> is of:",
	"	-output_file <output file>",
	"	-device <device>",
	"	-mode Color",
	"	-resolution 600",
	"	-host fs0",
	"	-type epson2",
	"	-ip scan0",
	"	-sides 0",
	"	-batch_mode 0",
	"	-gs <arguments to gs>",
	"	-papersize a3",
	"	-1   Alias to -sides=1",
	"	-2   Alias to -sides=2",
	"	-a3  Alias to -papersize=a3",
	"	-a4  Alias to -papersize=a4",
	"	-afeed",
	"	-scanimage_arguments <arguments to scanimage>",
	"	-top <top border>",
	"	-bottom <bottom border>",
	"	-left <left border>",
	"	-right <right border>",
	"	-verbosity",
	"	-debug");
    }

#########################################################################
#	Return IP address of argument.					#
#########################################################################
my %ip_cache;
sub getip
    {
    my( $lookfor ) = @_;
    &autopsy("getip called with no argument") if( ! $lookfor );
    if( ! $ip_cache{$lookfor} )
	{
	$ip_cache{$lookfor} = "unknown";
	foreach my $line ( &read_lines("dig '$lookfor' |") )
	    {
	    #print "$lookfor [$line]\n";
	    my @toks = split(/\s+/,$line);
	    $ip_cache{$lookfor}=$toks[4], last if( $toks[3] && $toks[3] eq "A" );
	    }
	}
    #print "getip($lookfor) returns ", $ip_cache{$lookfor}||"UNDEF", ".\n";
    return $ip_cache{$lookfor};
    }

#########################################################################
#	Setup devarg							#
#########################################################################
sub setup_devarg
    {
    my $device_ip = $ARGS{device} ? &getip($ARGS{device}) : "";
    #print "setup_devarg(",$ARGS{device}||"UNDEF",")\n";
    $ARGS{device} =
	{
	scan0		=> "localhost:airscan:e0:Brother MFC-L3720CDW series",
	scan1		=> "$ARGS{device}:epson2:net:$ARGS{device}",
	psc_750_aio	=> "localhost:hpaio:/usb/PSC_750?serial=MY2BJD60R4WB",
	psc_750		=> "localhost:hp:/usb/PSC_750?serial=MY2BJD60R4WB",
	A909n		=> "localhost:hpaio:/net/Officejet_Pro_8500_A909n?ip=$device_ip",
	A909a		=> "localhost:hpaio:/net/Officejet_Pro_8500_A909a?ip=$device_ip",
	""		=> "$ARGS{host}:$ARGS{type}:net:$ARGS{ip}"
	} -> { $ARGS{device} }
	|| "$ARGS{host}:$ARGS{type}:net:$ARGS{device}";
    #print "return(",$ARGS{device}||"UNDEF",")\n";
    }

#########################################################################
#	Asks a supplied yes or no question and returns true if answered	#
#	yes, false if answered no, or continues to prompt.		#
#########################################################################
sub confirm
    {
    my( $question ) = @_;
    while(1)
	{
        print $question;
	my $ans = <STDIN>;
	&fatal("EOF not expected.")	if( !defined( $ans ) );
	return 1			if( $ans =~ /^y/i );
	return 0			if( $ans =~ /^n/i );
	print STDERR "'yes' or 'no' expected.\n";
	}
    # Will never reach
    }

#########################################################################
#	Nope, don't no why I have to do this.				#
#########################################################################
sub try_x_times
    {
    my( $times, @cmd_parts ) = @_;
    my $ret = -1;
    do  {
    	my $ret = &echodo( @cmd_parts );
	if( $ret == 0 )
	    { return $ret; }
	elsif( --$times > 0 )
	    { print STDERR "Command returned $ret.  $times tries left.\n"; }
	else
	    { print STDERR "Command returned $ret.  Gifing up.\n"; }
	} while( $times > 0 );
    return $ret;
    }

#########################################################################
#	Invoke scanner.  Stand back.  Bring popcorn.			#
#	Creates one directory per side, each directory filled with	#
#	.$PAMEXT files from that side.					#
#	If you scan one page, you'll end up with $TMP/1/1001.$PAMEXT	#
#########################################################################
sub invoke_scanner
    {
    my $devhost;
    my $devpiece;
    my $scancmd;
    ($devhost,$devpiece)=($1,$2) if( $ARGS{device} =~ /^(.*?):(.*)$/ );
    my( $myname ) = &read_lines("hostname|");

    &echodo("rm -rf $TMP");
    if( -z "$devhost" || "$devhost" eq 'localhost' || &getip($devhost) eq &getip($myname) )
	{ $scancmd="scanimage"; }
    else
	{ $scancmd="ssh $devhost scanimage"; }
    for ( my $side=1; $side <= ($ARGS{sides}||1); $side++ )
	{
        if( $ARGS{autofeed})
	    {
	    while( ! &confirm("Side $side loaded into the autofeeder? ") ) {}
	    &mkdirp( 0755, "$TMP/$side" );
	    if( &try_x_times( 3,
	        $scancmd,
		    "-d",		"'$devpiece'",
		    "--format",		$PAMEXT,
		    "--resolution",	$ARGS{resolution},
		    "--mode",		$ARGS{mode},
		    "--source",		$AUTOMATIC,
		    "--batch=$TMP/$side/%04d.$PAMEXT --batch-start=1001" ) )
		{ $side--; }
	    }
        else
	    {
	    my $page=0;
	    my $ind=1000;
	    my $silent=0;
	    # $ARGS{batch_mode} || $silent=1	# Why not $silent=$ARGS{batch_mode}?
	    while(1)
		{
	        $ind++;
	        $page++;
		last if( !$silent &&
		    ! &confirm("Continue with page $page side $side loaded? ") )
		&mkdirp( 0755, "$TMP/$side" );
		my $fn = "$TMP/$side/$ind.$PAMEXT";
		if( &try_x_times( 3,
		    $scancmd,
			"-d",		"'$devpiece'",
			"--format",	$PAMEXT,
			"--resolution",	$ARGS{resolution},
			"--mode",	$ARGS{mode},
			$ARGS{scanimage_arguments},
			    "> $fn") == 0 )
			{
			&echodo("display $fn");
			# last;
			}
		}
	    }
        }
    }

#########################################################################
#	Convert the file if( required, or just move if( right type.	#
#########################################################################
sub convert_file
    {
    my( $from_file, $to_file ) = @_;
    if( &just_ext_of($from_file) eq &just_ext_of($to_file) )
	{ &echodo("mv $from_file $to_file"); }
    else
	{ &echodo("$CVT -verbosity=$ARGS{verbosity} $from_file $to_file"); }
    }

#########################################################################
#	Return all of the files in the specified object.		#
#########################################################################
sub all_files_in
    {
    my( @todo ) = @_;
    my @ret;
    my $srcfile;
    while( defined($srcfile=shift(@todo)) )
	{
	if( -f $srcfile )
	    { push( @ret, $srcfile ); }
	elsif( -d $srcfile )
	    { @todo = ( &numeric_sort( &fqfiles_in($srcfile) ), @todo ); }
	}
    return @ret;
    }

#########################################################################
#	Start scanning							#
#########################################################################
sub start_scanning
    {
    my( $outname ) = @_;

    &invoke_scanner();

    if( ! -f "$TMP/1/1001.$PAMEXT" )
        { print STDERR "Scanning failed.\n"; }
    else
	{
	if( $ARGS{trim_arguments} )
	    {
            foreach my $fn ( &all_files_in($TMP) )
		{
	        &echodo("pamcut $ARGS{trim_arguments} < $fn > $fn.new && mv $fn.new $fn");
	        }
	    }
	if( $outname =~ /%/ )
	    {
	    my $loop1=0;
	    foreach my $fn ( &all_files_in( $TMP ) )
		{
		my $name1;
		do { $name1 = sprintf($outname,$loop1++); } while( -f "$name1" );
		&convert_file( $fn, $name1 );
		}
	    }
	elsif( -f "$TMP/2/1001.$PAMEXT" ) 
	    { $exit_status = &echodo("merge_scan_batch -verbosity=$ARGS{verbosity} $ARGS{gs} -o $outname $TMP/*"); }
	elsif( -f "$TMP/1/1002.$PAMEXT" )
	    { $exit_status = &echodo("cat_media -verbosity=$ARGS{verbosity} $ARGS{gs} -o $outname $TMP/*/*"); }
	else
	    { $exit_status = &convert_file( "$TMP/1/1001.$PAMEXT", $outname ); }
	}
    }

#########################################################################
#	Handle case where output file has % in it (multiple files)	#
#########################################################################
sub multiple_files
    {
    my( $template ) = @_;
    my $loop0=0;
    while(1)
	{
        my $name0=sprintf( $template, $loop0++ );
        if( ! -f $name0 )
	    {
	    &confirm("Document loaded for $name0? ") || last;
	    &start_scanning( $name0 );
	    }
	}
    }

#########################################################################
#	Print arguments after defaults have been taken.			#
#########################################################################
sub dump_args
    {
    print "Args:\n",
	( map {sprintf("  %-30s %s\n",$_.":",$ARGS{$_})} sort keys %ARGS );
    }

#########################################################################
#	Main								#
#########################################################################

%ARGS = &parse_arguments({flags=>["trim","autofeed"],switches=>\%ONLY_ONE_DEFAULTS});
    
$ARGS{batch_mode} ||= ( $ARGS{autofeed} || $ARGS{sides} );
if( $ARGS{trim} )
    {
    $ARGS{bottom} = 3300;
    $ARGS{resolution} = 150;
    }
$ARGS{trim_arguments} =
    join(" ",
	map { "-$_=$ARGS{$_}" }
	    grep( $ARGS{$_} ne "", "top", "bottom", "left", "right" ) );
$ARGS{gs}.=($ARGS{gs} ? " " : "") . "-sPAPERSIZE=$ARGS{papersize}" if( $ARGS{papersize} );
push( @problems, "$ARGS{output_file} already exists, aborting.")
    if( -e $ARGS{output_file} );
$cpi_vars::VERBOSITY = $ARGS{verbosity};

&usage(@problems) if( @problems );
&setup_devarg() if( $ARGS{device} !~ /:/ );

&dump_args() if( $ARGS{debug} > 0 );
#exit(1);

if( $ARGS{autofeed} )
    { &start_scanning($ARGS{output_file}); }
elsif( $ARGS{output_file} =~ /%/ )
    { &multiple_files($ARGS{output_file}); }
else   
    { &start_scanning($ARGS{output_file}); }

#&echodo("rm -rf $TMP") if( $exit_status == 0 );

&cleanup( $exit_status );
