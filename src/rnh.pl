#!/usr/bin/perl -w

use strict;

open( OUT, "| rnotroff | nroff -man" )	|| die("Cannot run rnotroff:  $!");
while( $_ = <STDIN> )
    {
    next if( /^\.LC/ );
    next if( /^\.FLAG CAPITALIZE/ );
    tr/A-Z/a-z/;
    foreach my $word ( split(/(<[^\s]*)/) )
	{
        if( $word !~ /<(.*)/ )
	    { print OUT $word; }
	else
	    {
	    $word = $1;
	    $word =~ tr/a-z/A-Z/;
	    print OUT $word;
	    }
	}
    }
close( OUT );
exit(0);
