#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";

use cpi_file qw( read_file write_file fatal );
use cpi_cgi qw( CGIreceive CGIheader );

# Put constants here

my $PROG = ( $_=$0, s+.*/++, $_ );
my $TMP = "/tmp/$PROG.$$";
my $OCT_DIR = "/usr/local/projects/octagon";
my $CURRENT_SCREENS = "$OCT_DIR/state/screens";

my %ONLY_ONE_DEFAULTS =
    (
    "geometry"	=>	"",	# Where to put image
    "rate"	=>	1.0,	# Rate for movie playback
    "screen"	=>	"",	# Which screen
    "fullscreen"=>	"",	# Use full screen or not
    "fs"	=>	"",	# Specify which full screen
    "yesno"	=>	"",	# Filename to put answer in
    "bleft"	=>	2580,	# Left of box
    "btop"	=>	2100,	# Top of box
    "bheight"	=>	"",	# Height of image
    "urls"	=>	"$OCT_DIR/cfg/urls.pl",
    "macros"	=>	"$OCT_DIR/cfg/urlmacros.pl",
    "title"	=>	"",	# Title
    "at"	=>	0,	# Do not announce the title
    "ao"	=>	"pulse",# or null	(mpv Audio Output driver)
    "vo"	=>	"",	# or null	(mpv Video Output driver)
    "loop"	=>	1	# 0 means loop forever
    );

my @CLIP_SELECTIONS=("XA_PRIMARY","XA_SECONDARY","XA_CLIPBOARD","c");
my $CVT="/usr/local/bin/nene";
my $MPLAYER="mplayer -really-quiet";
my $MPV="mpv --really-quiet";
my $YOUTUBEDL="youtube-dl";

# Put variables here.

my @problems;
my %ARGS;
my @files;
my $exit_stat = 0;
my %screen;

# Put interesting subroutines here

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
	"    where <possible arguments> are",
	"	-geometry rxc		Where to put image",
	"	-rate n.n.		Rate for movie playback",
	"	-screen <screen>	Which screen",
	"	-fullscreen 1 or 0	Use full screen or not",
	"	-fs <screen>		Specify which full screen",
	"	-yesno <filename>	Filename to put answer in",
	"	-bleft <n>		Left of box",
	"	-btop <n>		Top of box",
	"	-bheight <n>		Height of image",
	"	-urls <filename>	File containing URLs (perl)",
	"	-macros <filename>	File containing macros (perl)",
	"	-title <title>		Title",
	"	-at <n>			Do not announce the title",
	"	-ao <driver>		mpv Audio Output driver",
	"	-vo <driver>		mpv Video Output driver",
	"	-loop <n>		0 means loop forever",
	"	<filenames to show or display>"
	);
    }

#########################################################################
#	Look for processes matching description and kill them!		#
#	Tries to be nice at first (TERM), but if not ... KILL!		#
#########################################################################
sub kill_matching
    {
    my( $searchfor ) = @_;
    my $sig = "TERM";
    my $count;
    while(1)
	{
	$count = 0;
	open( INF, "ps -efww |" ) || &fatal("Cannot run ps:  $!");
	while( $_ = <INF> )
	    {
	    chomp( $_ );
	    next if( ! /$searchfor/ );
	    my( $user, $pid, $ppid ) =  split(/\s+/);
	    print "kill -$sig ${pid}:  $_\n";
	    kill $sig => ${pid};
	    $count++;
	    }
	close( INF );
	last if( $count == 0 );
	$sig = "KILL";
	print "Checking again in 1 second...\n";
	sleep(1);
	}
    }

#########################################################################
#	Try to kill off anything else running on a screen before	#
#	attaching to it for our purposes.				#
#########################################################################
sub acquire_screen
    {
    my( $thing ) = @_;
    if( $ARGS{screen} )
	{
	if( ! $thing )
	    {
	    print "Releasing screen $ARGS{screen}.\n";
	    unlink( "$CURRENT_SCREENS/$ARGS{screen}" );
	    }
	else
	    {
	    print "Acquiring screen $ARGS{screen} for $thing.\n";
	    &kill_matching( "fs-screen=$screen{MPV} " );
	    &write_file( "$CURRENT_SCREENS/$ARGS{screen}", $thing );
	    }
	}
    }

#########################################################################
#	Execute a command and trap standard out.			#
#########################################################################
sub command_result
    {
    my( $cmd ) = join(" ",@_);
    print "+ $cmd\n";
    open( CR, "$cmd |" ) || &fatal("Cannot run ${cmd}:  $!");
    my $ret = <CR>;
    close( CR );
    chomp( $ret );
    return $ret;
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

	my $flags = join("|",reverse sort keys %ONLY_ONE_DEFAULTS);
	if( $flags && ( $arg =~ /^-($flags)=(.*)$/ || $arg =~ /^-($flags)(.*)$/ ) )
	    {
	    my( $argname, $rest ) = ( $1, $2 );
	    if( defined($ARGS{$argname}) )
		{ push( @problems, "-$argname specified multiple times." ); }
	    elsif( !defined($rest) || $rest eq "" )
		{
		if( defined( $ARGV[0] ) && $ARGV[0] !~ /^-/ )
		    { $ARGS{$argname} = shift(@ARGV); }
		else
		    { $ARGS{$argname} = 1; }
		}
	    else
		{ $ARGS{$argname} = $rest; }
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
    
    push( @problems, "No files specified" ) if( ! @files );
    &usage( @problems ) if( @problems );

    # Put interesting code here.

    grep( $ARGS{$_}=(defined($ARGS{$_})?$ARGS{$_}:$ONLY_ONE_DEFAULTS{$_}),
	keys %ONLY_ONE_DEFAULTS );

    $ARGS{screen}=$ARGS{fullscreen}=$ARGS{fs} if( $ARGS{fs} );
    }
    
#########################################################################
#	We we asked for full screen, we need parameters to obtain.	#
#########################################################################
sub set_screen_logic
    {
    if( $ARGS{screen} =~ /^[0-9][hml]$/ )
        {}
    elsif( $ARGS{screen} =~ /^m([0-9]+)$/ )
        { $ARGS{screen} = &command_result("screens -m$1 -N"); }
    elsif( $ARGS{screen} =~ /^(X.+)$/ )
        { $ARGS{screen} = &command_result("screens -p$1 -N"); }
    else
	{ push(@problems,"Illegal screen definition:  $ARGS{screen}"); }

    &usage( @problems ) if( @problems );

    open( INF, "screens -n$ARGS{screen} |" )
	|| &fatal("Cannot run screens -n$ARGS{screen}:  $!");
    chomp($_=<INF>);	my @fieldnames	= split(/\s+/);
    chomp($_=<INF>);	my @values	= split(/\s+/);
    close( INF );
    #print "fn:  ", join(' : ',@fieldnames), "\n";
    #print "values  ", join(' : ',@values), "\n";

    # Name Host Port MPV Dimensions Location Geometry URL
    my $last_field = pop(@fieldnames);
    grep( $screen{$_}=shift(@values), @fieldnames );
    $screen{$last_field} = join(" ",@values);
    #print join("\n\t","Screen",map{"$_:\t$screen{$_}"} sort keys %screen), "\n";

    $screen{mpvarg} = " -fs-screen=$screen{MPV}";
    $screen{geometry} = " -geometry $screen{Geometry}";
    $screen{display} =
	( $ARGS{fullscreen}
	? " -geometry $screen{Geometry} -extent $screen{Dimensions}"
	: " -geometry $screen{Location}" );
    }

#########################################################################
#	Set all clip buffers to what we need.				#
#########################################################################
sub setclip()
    {
    my( $clip ) = @_;
    foreach my $clipbuf ( @CLIP_SELECTIONS )
	{
	open( SC, "| xclip -selection $clipbuf" )
	    || &fatal("Cannot run xclip:  $!");
	print SC $clip ;
	close( SC );
    	}
    }

#########################################################################
#	Return useful parameters to display (ala dispic)		#
#########################################################################
sub display_size
    {
    my( $fn ) = @_;
    my $width = $ARGS{w};
    my $height = $ARGS{bheight};
    my $ratio;

    if( !$width || !$height )
	{
	if( $fn =~ /\.jpg$/i || $fn =~ /\.jpeg$/i )
	    {
	    open( INF, "exiv2 -q '$fn' 2>/dev/null |" ) || &fatal("Cannot open exiv2 ${fn}:  $!");
	    while( (!$ratio) && ($_=<INF>) )
		{
		# Image size      : 3264 x 2448
		$ratio = 1.0*$1 / $2 if( /^Image size\s+:\s+(\d+) x (\d+)\s*$/i );
		}
	    close( INF );
	    }

	if( ! $ratio )
	    {
	    my $sizefile = $fn;
	    if( $fn =~ /\.pnm$/i )
		{
		open( INF, "pnmfile $fn |")
		    || &fatal("Cannot pnmfile $fn for dimensions:  $!");
		}
	    else
		{
		open( INF, "$CVT $fn -.pnm | pnmfile - |")
		    || &fatal("Cannot convert $fn and get dimensions:  $!");
		}
	    while( (!$ratio) && ($_=<INF>) )
		{
		# -:	PPM raw, 1000 by 748  maxval 255
		$ratio = 1.0*$1 / $2 if( /, (\d+) by (\d+)\s+maxval$/i );
		}
	    close( INF );
	    }

	if( ! defined( $ratio ) )
	    { print STDERR "Cannot find width or height of ${fn}.\n"; }
	elsif( $width )
	    { $height = int( $ARGS{w} / $ratio ); }
	elsif( $height )
	    { $width = int( $ARGS{bheight} * $ratio ); }
	}
    return ( $width, $height );
    }

#########################################################################
#########################################################################
sub display_cmd
    {
    my( $filename ) = @_;
    #print "display=", $screen{display} || "UNDEF", "\n";
    my $modifier = "";
    if( $ARGS{geometry} )
	{ $modifier = " -geometry $ARGS{geometry}"; }
    elsif( $ARGS{screen} && $ARGS{fullscreen} )
	{ $modifier = $screen{display}; }
    else
	{
	my( $width, $height ) = &display_size( $filename );
	$modifier = " -geometry ";
	$modifier .= "${width}x$height" if( $width && $height );
	$modifier .=
	    ( $screen{Location}
	    ? $screen{Location}
	    : "+$ARGS{bleft}+$ARGS{btop}" );
	$modifier .= " -resize ${width}x$height" if( $width && $height );
	}
    &echodo( "display$modifier '$filename'");
    }

#########################################################################
#	Figure out which utility to best display a file based on	#
#	extension and then display it.					#
#########################################################################
my %URLS;
sub display_one()
    {
    my( $unmapped_filename ) = @_;
    &acquire_screen( $unmapped_filename );
    my $pnmtmp = "$TMP.pnm";
    my $filename = $unmapped_filename;

    if( $filename =~ /^@(.*)/ )
	{
	my $macroname = $1;
	if( ! %URLS )
	    {
	    eval( &read_file($ARGS{"-macros"}) );
	    eval( "%URLS=".&read_file($ARGS{"-urls"}).";" );
	    foreach my $urlkey ( keys %URLS )
		{
		$URLS{$2} = $URLS{$urlkey}
		    if( $urlkey =~ /(.*):\s+(.*?)$/ );
		}
	    }
	if( ! $macroname )
	    { $filename = $URLS{$screen{URL}}; }
	else
	    { $filename = $URLS{$macroname}; }
	}

    if( $ARGS{at} )
	{
	my @text;
	push( @text, "Displaying" );
	if( $ARGS{at} ne "1" )
	    { push( @text, $ARGS{at} ); }
	elsif( $ARGS{title} )
	    { push( @text, $ARGS{title} ); }
	elsif( $unmapped_filename =~ /^@(.*)$/ )
	    { push( @text, $1 ); }
	elsif( $unmapped_filename =~ /([^\/]+)\.[a-z]+$/ )
	    { push( @text, $1 ); }
	else
	    { push( @text, $unmapped_filename ); }
	push( @text, " on panel $1 ", {h=>"top",m=>"mid-level",l=>"bottom"}->{$2}, " screen" )
	    if( $ARGS{screen} =~ /^(\d+)([hml])$/ );
	&echodo("announce -start '".join(" ",@text,".")."'");
	}

    if( $filename =~ /\.pdf$/i )
	{ &echodo("evince '$filename'"); }
    elsif( $filename =~ /\.(jpg|jpeg|pnm|png|tiff)$/i )
	{
	&setclip( $filename );
	&display_cmd( $filename );
	}
    elsif( $filename =~ /\.(3gp|avi|asf|flv|matrosca|mov|mp4|nut|ogg|ogm|realmedia|bink|gif)$/i
	|| $filename =~ /http.*youtube.*/i )
	{
	my @avcmd;
	if( $ARGS{screen} || $filename =~ /^https*:/ )	# Specifies a screen, only mpv can do that
	    {
	    push( @avcmd, $MPV );

	    push( @avcmd, "--ao=".($ARGS{ao}||"null") )	if( $ARGS{ao} ne "" );
	    push( @avcmd, "--vo=".($ARGS{vo}||"null") )	if( $ARGS{vo} ne "" );

	    push( @avcmd, "--loop-playlist=".($ARGS{loop}?$ARGS{loop}:"inf") );
	    push( @avcmd, "--fs" )			if( $ARGS{fullscreen} || $ARGS{screen});
	    push( @avcmd, "--speed=$ARGS{rate}" )		if( $ARGS{rate} );
	    push( @avcmd, "--title=='$ARGS{title}'" )	if( $ARGS{title} );
	    push( @avcmd, $screen{mpvarg} )		if( $ARGS{screen} );		# Will always happen
	    if( $ARGS{title} )
		{
		my $nltext = $ARGS{title};
		$nltext =~ s/\n/\\n/gms;
		&write_file( "$TMP.0.lua", "mp.osd_message(\"$nltext\",2147483)\n" );
		push( @avcmd, "--script=$TMP.0.lua" );
		}
	    push( @avcmd, "'$filename'" );
	    }
	else			# Else, give it to mplayer and hope
	    {
	    if( $filename =~ /^http/ )
		{
		push( @avcmd, $YOUTUBEDL, "-o -" );
		push( @avcmd, "-f bestaudio" ) if( $ARGS{ao} );
		push( @avcmd, "'$filename' 2>/dev/null |" );
		}
	    push( @avcmd, $MPLAYER );
	    push( @avcmd, "-loop $ARGS{loop}" );

	    push( @avcmd, "-ao", $ARGS{ao}||"null" )	if( $ARGS{ao} ne "" );
	    push( @avcmd, "-vo", $ARGS{vo}||"null" )	if( $ARGS{vo} ne "" );
	    push( @avcmd, "-fixed-vo" )
		if( $ARGS{vo} ne "0" && $ARGS{vo} ne "null" && $ARGS{loop} != 1 );

	    push( @avcmd, "-fs" )			if( $ARGS{fullscreen} );
	    push( @avcmd, "-speed $ARGS{rate}" )		if( $ARGS{rate} );
	    push( @avcmd, "-title '$ARGS{title}'" )		if( $ARGS{title} );
							# Will never happen
	    push( @avcmd, $screen{mplayerarg} )		if( $ARGS{screen} );

	    if( $ARGS{title} )
		{
		&write_file( "$TMP.0", "<txt name=\"main\" file=\"$TMP.1\"/>\n" );
		&write_file( "$TMP.1", "$ARGS{title}\n\n" );
		push( @avcmd, "-menu -menu-startup -menu-cfg $TMP.0" );
		}
	    push( @avcmd, $filename !~ /^http/ ? "'$filename'" : "-cache 8192 -" );
	    }
	&echodo( join(" ",@avcmd) );
	}
    elsif( $filename =~ /^(http|https):/i || $filename =~ /\.(html|htm)$/i )
    	{
	&echodo( "google-chrome" .
	    ( $ARGS{geometry}
	    ? " -geometry $ARGS{geometry}"
	    : "" ) .
	    " '$filename'" );
	}
    elsif( $filename =~ /\.(html|htm)$/i )
    	{
	if( &echodo("$CVT '$filename' '$pnmtmp' 2>/dev/null 2>&1") == 0 )
	    { &display_cmd($pnmtmp); }
	}
    elsif( &echodo("play -q '$filename' 2>/dev/null") == 0 )
    	{}
    elsif( &echodo("anytopnm '$filename' > $pnmtmp 2>/dev/null")==0
      && &display_cmd($pnmtmp)==0 )
    	{}
    elsif( &echodo("$CVT '$filename' '$pnmtmp' >/dev/null 2>&1") == 0
      && -s $pnmtmp )
        { &display_cmd( $pnmtmp ); }
    else
	{ print STDERR "Don't know how to $PROG $filename.\n"; }
    &acquire_screen();
    }

#########################################################################
#	Do all the files.						#
#########################################################################
sub process_files
    {
    foreach my $filename ( @_ )
	{
	if( $filename =~ /^@(.*)/ )
	    {
	    if( ! %URLS )
		{
		eval( "%URLS=".&read_file($ARGS{"-urls"}).";" );
		foreach my $urlkey ( keys %URLS )
		    {
		    $URLS{$2} = $URLS{$urlkey}
		        if( $urlkey =~ /(.*):\s+(.*?)$/ );
		    }
		}
	    }
	&display_one( $filename );
	if( $ARGS{yesno} )
	    {
	    my $lsoutput = `ls -ld "$filename"`;
	    chomp( $lsoutput );
	    while( 1 )
		{
		print "$lsoutput?  ";
		return if( !defined($_ = <STDIN>) );
		chomp( $_ );
		if( /^n/i )
		    { last; }
		elsif( /^y/i )
		    {
		    open( OUT, ">> $ARGS{yesno}" )
			|| &fatal("Cannot append to $ARGS{yesno}:  $!");
		    print OUT $filename, "\n";
		    close( OUT );
		    last;
		    }
		else
		    { print "You must answer 'y' or 'n'.\n"; }
		}
	    }
	}
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

#print join("\n\t","Args:",map{"$_:\t$ARGS{$_}"} sort keys %ARGS), "\n";

&set_screen_logic() if( $ARGS{screen} );

&process_files( @files );
system("rm -rf $TMP.*");

exit($exit_stat);
