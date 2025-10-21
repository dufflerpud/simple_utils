#!/usr/bin/perl -w

use strict;

my($sec,$min,$hour,$mday,$month,$year) = localtime( $ARGV[0] );

printf("%02d:%02d:%02d %02d/%02d/%04d\n",$hour,$min,$sec,$mday,$month+1,1900+$year);
#print localtime( $ARGV[0] ), ".\n";
exit(0);
