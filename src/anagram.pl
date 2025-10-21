#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_vars;

our %ONLY_ONE_DEFAULTS =
    (
    "n" =>	-1,
    "x" =>	-1,
    "w" =>	"/usr/share/dict/words",
    "m" =>	""
    );

# Put variables here.

our @problems;
our %ARGS;
our @words;
our $exit_stat = 0;

my %wordmap;

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
	"Usage:  $cpi_vars::PROG <possible arguments> <word> { <word> } ... ","",
	"where <possible arguments> is:",
	"    -w <word file>"
	);
    }

#########################################################################
#	Return all letters in a word sorted so any anagram of the word	#
#	would return the same letters.					#
#########################################################################
sub letters_in
    {
    #my $ret = join("",sort split(//, lc $_[0] ));
    #print "letters_in($_[0]) returns [$ret]\n";
    return join("",sort split(//, lc $_[0] ));
    }

#########################################################################
#	Loop through all words, finding letters in each and adding	#
#	the word to the list specified by those letters.		#
#########################################################################
sub setup_wordmap
    {
    my( $fname ) = @_;
    open( INF, $fname ) || &fatal("Cannot open ${fname}:  $!");
    while( $_ = <INF> )
	{
	chomp( $_ );
	push( @{ $wordmap{ &letters_in( $_ ) } }, $_ );
	}
    close( INF );
    }

#########################################################################
#	Returns all of the permutations of whether or not letters are	#
#	included.							#
#########################################################################
sub permute
    {
    my( $sofar, $ind, $mn, $mx, @lets ) = @_;
    my( $l ) = length($sofar);
    my( @trylist );
    push( @trylist, $sofar ) if( $l >= $mn );
    if( $l < $mx && $ind <= $#lets )
	{
	push( @trylist, &permute($sofar,$ind+1,$mn,$mx,@lets) );
	push( @trylist, &permute($sofar.$lets[$ind],$ind+1,$mn,$mx,@lets) );
	}
    return @trylist;
    }

#########################################################################
#	Print all the permutations of letters in a word within the	#
#	ranges specified.						#
#########################################################################
sub anagram
    {
    my ( $word ) = @_;
    my $l = length( $word );
    my $mn = ( $ARGS{n} eq -1 ? $l : $ARGS{n} );
    my $mx = ( $ARGS{x} eq -1 ? $l : $ARGS{x} );
    my %seen = ( $word => 1 );
    my @mask;
    my $masklen = 0;
    if( $ARGS{m} )
	{
        @mask = split(//,$ARGS{m});
	$masklen = scalar(@mask);
	$mn = $mx = $masklen;
	}
    foreach my $try_word ( &permute("",0,$mn,$mx,split(//,$word) ) )
	{
        if( my $wordlistp = $wordmap{ &letters_in($try_word) } )
	    {
	    if( ! $masklen )
	        { grep( $seen{$_}=1, @{$wordlistp} ); }
	    else
		{
		foreach my $cword ( @{$wordlistp} )
		    {
		    my @clets = split(//,$cword);
		    my $i;
		    for( $i=0; $i<$masklen; $i++ )
			{
			last if( $mask[$i] ne '?' && $mask[$i] ne $clets[$i] );
			}
		    $seen{$cword} = 1 if( $i >= $masklen );
		    }
		}
	    }
	}
    my @found = ( grep $_ ne $word, keys %seen );
    
    if( ! @found )
	{ print STDERR "'$word' has no anagrams.\n"; return 1; return 1; }
    else
	{ print join("\n\t","'$word' anagrams:",@found),"\n"; return 0; }
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    {
    %ARGS = &parse_arguments({
	switches	=> \%ONLY_ONE_DEFAULTS,
	non_switches	=> \@words
	} );
    }

&setup_wordmap( $ARGS{w} );

grep( $exit_stat |= &anagram($_), @words );

&cleanup($exit_stat);
