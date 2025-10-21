#!/usr/bin/perl -w

#########################################################################
#	A program to read an html file from standard input and replace	#
#	<img src='url'> with <img src='data:image/png;base64,...'>.	#
#########################################################################

use strict;

my $DEBUG = "/tmp";	# If set to directory, leaves around temporary files
undef $DEBUG;

my $ind = 1000;

foreach my $piece ( split(/(src='.*?'|src=".*?")/m,join("",<STDIN>)) )
    {
    if( $piece !~ /^src=(['"])(.*)(['"])$/ )
        { print $piece; }
    else
        {
	my $cmd =
	    ( -f $2 ? "< '$2'" : "wget -q -O - '$2' |") .
	    ( $DEBUG ? " tee $DEBUG/$ind.jpg |" : "" ) .
	    " base64" .
	    ( $DEBUG ? " | tee $DEBUG/$ind.b64" : "" );
	$ind++;
	#print STDERR "[$cmd]\n";
	open( INF, "-|", $cmd ) || die("$cmd failed:  $!");
	print "src='data:image/png;base64,", <INF>, "'";
	close( INF );
	}
    }
