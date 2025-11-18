#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal cleanup );
use cpi_db qw( dbread dbwrite dbclose );
use cpi_arguments qw( parse_arguments );
use cpi_copy_db qw( copydb );

use Cwd;
use Cwd 'abs_path';

# Put constants here

my $PROG = ( $_=$0, s+.*/++, $_ );
my $TMP = "/tmp/$PROG.$$";
our %ONLY_ONE_DEFAULTS =
    (
    "verbosity"		=> 0
    );

our @problems;
our %ARGS;
our @files;
our $exit_stat = 0;

#=======================================================================#
#	New code not from prototype.pl					#
#		Should at least include:				#
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
    &fatal( @_, "", "Usage:  $PROG <input_database> <output_database>");
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

&usage("Must supply two filenames.") if( scalar(@files) != 2 );

&copydb( abs_path($files[0]), abs_path($files[1]) );

&cleanup($exit_stat);
