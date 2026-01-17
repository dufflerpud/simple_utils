#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( echodo fatal cleanup write_file tempfile );
use cpi_arguments qw( parse_arguments );
use cpi_mime qw( read_mime_types );
use cpi_filename qw( just_ext_of );
use cpi_perl qw( quotes );
use cpi_inlist qw( inlist );
use cpi_english qw( plural );
use Data::Dumper;

my $CVT		= "/usr/local/bin/nene";
my $FFMPEG	= "ffmpeg -loglevel error";
my $GS		= "gs -q -dBATCH -dNOPAUSE";

my $out_ext;
my $out_type;
our @problems;
our @input_files;
our %ARGS;

my @pre_cat_files;
my @cmds;

my %logic_for;

my %BEST_FFMPEG_EXTS =
    (
    "audio"	=> [ "mp3", "wav" ],
    "video"	=> [ "mp4", "mov" ]
    );

#########################################################################
#	Print a usage message and exit.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <arguments> <input_file> <input_file> <input_file> ... -o <output_file>",
	" where <input_file> is one of the files to concatinate",
	" and <output_file> is the resulting file",
	" <argument> can be any of:",
	"	-v 1 | 0	Specify verbosity" );
    }

#########################################################################
#	Return appropriate quoted string for file conversion.		#
#########################################################################
sub convert_file
    {
    my( $infile, $outfile ) = @_;
    return "$CVT -v=$ARGS{verbosity} ".&quotes($infile,$outfile);
    }

#########################################################################
#	If input file is correct extension, just return it.		#
#	Else create a temp name that is correct extension and add	#
#	a command to convert file.					#
#########################################################################
sub file_must_be
    {
    my( $input_file, $ext ) = @_;
    return $input_file if( &just_ext_of($input_file) eq $ext );
    my $tfile = &tempfile(".$ext");
    push( @cmds, &convert_file( $input_file, $tfile ) );
    return $tfile;
    }

#########################################################################
$logic_for{image} = sub
    {
    if( @_ )
        { push( @pre_cat_files, &file_must_be($_[0],"pnm") ); }
    else
	{
	push( @cmds,
	    "pamcat -$ARGS{tblr} -j$ARGS{justify} -$ARGS{bgcolor} "
	    . &quotes( @pre_cat_files )
	    . ( $out_ext eq "pnm" ? " > '$ARGS{output_file}'" : " | ".&convert_file("-.pnm",$ARGS{output_file}) ) );
        }
    };

#########################################################################
$logic_for{page} = sub
    {
    if( @_ )
        { push( @pre_cat_files, &file_must_be($_[0],"pdf")); }
    else
	{
	if( $out_ext eq "Xpdf" )
	    {
	    push(@cmds, "pdfunite ".&quotes(@pre_cat_files,$ARGS{output_file}) );
	    }
	elsif( &inlist( $out_ext, "ps", "pdf" ) )
	    {
	    push(@cmds,"$GS -sDEVICE=${out_ext}write -sOutputFile="
		. &quotes( $ARGS{output_file}, @pre_cat_files ) );
	    }
	elsif( &inlist( $out_ext, "odg" ) )
	    {
	    my $tfile = &tempfile(".pdf");
	    push(@cmds,"$GS -sDEVICE=pdfwrite -sOutputFile="
		. &quotes( $tfile, @pre_cat_files ) );
	    push(@cmds,&convert_file($tfile,$ARGS{output_file}));
	    }
        }
    };

#########################################################################
$logic_for{gif} = sub
    {
    if( @_ )
        { push( @pre_cat_files, &file_must_be($_[0],"png")); }
    else
	{
	my $concat_file = &tempfile(".files");
	&write_file( $concat_file, join("",map{"file '$_'\n"}@pre_cat_files) );
	my $ffmpeg_args = $ARGS{ffmpeg_gif};
	push(@cmds,"$FFMPEG -y -safe 0 -f concat -i $concat_file $ffmpeg_args $ARGS{output_file}");
        }
    };

#########################################################################
my $converting_ext;
$logic_for{audio} = $logic_for{video} = sub
    {
    my( $input_file ) = @_;
    if( $input_file )
	{
	$converting_ext =
	    ( &inlist($out_ext,@{$BEST_FFMPEG_EXTS{$out_type}})
	    ? $out_ext
	    : $BEST_FFMPEG_EXTS{$out_type}[0] );
	my $tfile = &tempfile(".$converting_ext");
	my $ffmpeg_args = $ARGS{"ffmpeg_".$out_type};
	push( @cmds, "$FFMPEG -y -i '$input_file' $ffmpeg_args '$tfile'" );
	push( @pre_cat_files, $tfile );
	}
    else
	{
	my $concat_file = &tempfile(".files");
	&write_file( $concat_file, join("",map{"file '$_'\n"}@pre_cat_files) );
	my $cmd = "$FFMPEG -y -safe 0 -f concat -i '$concat_file' -c copy";
	if( $converting_ext eq $out_ext )
	    { push( @cmds, "$cmd '$ARGS{output_file}'" ); }
	else
	    {
	    my $itemp = &tempfile(".$converting_ext");
	    push( @cmds,
	        "$cmd $itemp; ".&convert_file($itemp,$ARGS{output_file}) );
	    }
	}
    };

#########################################################################
$logic_for{default} = sub
    {
    return &file_must_be( $_[0], $out_ext ) if( @_ );
    push( @cmds, "cat".(map {" '$_'"} @pre_cat_files)." > '$ARGS{output_file}'" );
    };

#########################################################################
#	Main								#
#########################################################################
%ARGS = &parse_arguments({
    non_switches	=> \@input_files,
    flags		=> [ "yes" ],
    switches=>
	{
	"output_file"	=> "",
	"verbosity"	=> 1,
	"ffmpeg_gif"	=> "",
	"ffmpeg_audio"	=> "-ab 128k -ar 44100 -ac 2",
	"ffmpeg_video"	=> "-ab 128k -ar 44100 -ac 2",
	"bgcolor"	=> "black",
	"black"		=> { alias=>["-bgcolor=black"] },
	"white"		=> { alias=>["-bgcolor=white"] },
	"justify"	=> "",
	"tblr"		=> "tb",
	"tb"		=> { alias=>["-tblr=tb"] },
	"lr"		=> { alias=>["-tblr=lr"] },
	"justify"	=> "center",
	"jleft",	=> { alias=>["-justify=left"] },
	"jright",	=> { alias=>["-justify=right"] },
	"jtop",		=> { alias=>["-justify=top"] },
	"jbottom",	=> { alias=>["-justify=bottom"] },
	"jcenter",	=> { alias=>["-justify=center"] },
	}});
$cpi_vars::VERBOSITY = $ARGS{verbosity};
#print "ARGS=((",Dumper(\%ARGS),"))\n";

&read_mime_types();

if( $ARGS{output_file} eq "" )
    { push( @problems, "Output file (-o) not specified." ); }
else
    {
    if( ($out_ext = &just_ext_of($ARGS{output_file})) eq "" )
        { push( @problems, "Unrecognized extension for output file (-o)." ); }
    elsif( ! ($out_type = $cpi_vars::EXT_TO_BASE_TYPE{$out_ext}) )
        { push( @problems, "Unrecognized base type for output file from $out_ext." ); }
    elsif( &inlist($out_type,"postscript","ps","odg","pdf") )
        { $out_type = "page" }
    push( @problems, "$ARGS{output_file} already exists.  Specify -y to overwrite.")
    	if( -e $ARGS{output_file} && ! $ARGS{yes} );
    push(@problems, "Do not know how to concatinate ".&plural($out_type).".")
	if( $out_type && ! $logic_for{$out_type} );
    }

foreach my $input_file ( @input_files )
    {
    my $in_ext = &just_ext_of( $input_file );
    if( ! $in_ext )
        { push( @problems, "Unrecognized extension for $input_file." ); }
    else
	{
	my $in_type = $cpi_vars::EXT_TO_BASE_TYPE{$in_ext};
	if( ! $in_type  )
            { push( @problems, "Unrecognized base type for $input_file." ); }
	if( $out_type && $in_type )
	    {
	    if( $out_type eq $in_type )
	        {}
	    elsif( $out_type eq "page" && $in_type eq "image" )
	        {}
	    elsif( $out_type eq "gif" && $in_type eq "image" )
		{}
	    else
		{
		push( @problems,
		    "Base type for $input_file ($in_type)"
		    . " does not match $ARGS{output_file} ($out_type)." );
		}
	    }
	}
    }

&usage(@problems) if(@problems);

foreach my $input_file ( @input_files )
    {
    &{$logic_for{$out_type}||$logic_for{default}}( $input_file );
    }

&{$logic_for{$out_type}||$logic_for{default}}();

# Yes, we could do this, but you really couldn't see the individual
# programs AS they run
#&echodo( join(";",@cmds) );

# Turns out this is much clearer to watch:
&echodo( $_ ) foreach @cmds;
&cleanup(0);
