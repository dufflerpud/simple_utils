#!/usr/bin/perl -w
#
#indx#	words_with - Show words using specified letters
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
########################################################################
#doc#	words_with - Show words using specified letters
########################################################################

use strict;

my $WORDS = "/usr/share/dict/words";
my $PROG = ( $_ = $0, s+.*/++, s/\.[^\.]*$//, $_ );

my %letter_points =
    (
    "a"=>1, "b"=>3, "c"=>3, "d"=>2, "e"=>1, "f"=>4, "g"=>2, "h"=>4, "i"=>1,
    "j"=>8, "k"=>5, "l"=>1, "m"=>3, "n"=>1, "o"=>1, "p"=>3, "q"=>10, "r"=>1,
    "s"=>1, "t"=>1, "u"=>4, "w"=>4, "x"=>8, "y"=>4, "z"=>10
    );

my $pattern;
my $before;
my $esplen;
my $check_pattern;
my $dot_pattern;
my @patlets;

#########################################################################
sub usage
#########################################################################
    {
    print <<EOF;
$_[0]

Usage:  $PROG letters [pattern]
EOF
    exit(1);
    }

my %contains = ();
#########################################################################
sub read_words
#########################################################################
    {
    open( INF, $WORDS ) || die("Cannot open ${WORDS}:  $!");
    while( $_ = <INF> )
	{
	chomp( $_ );
	next if( /[^a-z]/ );
	my $letlist = join("",sort(split(//,$_)));
	push( @{$contains{$letlist}}, $_ );
	}
    }

#########################################################################
sub pattern_score
#########################################################################
    {
    my( $w ) = @_;
    my $best_score = -1;
    #print "Checking [$w] against [$check_pattern]";
    if( $w =~ /$check_pattern/ )
        {
	my @wlets = split(//,$w);
	my $wlen = scalar(@wlets);
	my $wiggle = $wlen - $esplen;
	#print " before=$before wlen=$wlen esplen=$esplen wiggle=$wiggle";

	for( my $j=0; $j<=$wiggle; $j++ )
	    {
	    my $index_into_pattern = $before - $wiggle + $j;
	    my $pat_part = substr( $dot_pattern, $index_into_pattern, $wlen );
	    #print " [$pat_part]";
	    if( $w =~ /^$pat_part$/ )
	        {
		my $pos_score = 0;
		for( my $i=0; $i<$wlen; $i++ )
		    {
		    my $dig = $patlets[$index_into_pattern+$i];
		    if( !defined($dig) )
		        {
			print "PROBLEM with [$w] on j=$j i=$i iip=$index_into_pattern.\n";
			print "patlets=",join(",",@patlets),".\n";
			}
		    $pos_score +=
		        $letter_points{$wlets[$i]}
			    * ( ( $dig =~ /\d/ ) ? $dig : 1 );
		    }
		#print "($pos_score)";
		$best_score = $pos_score if( $pos_score > $best_score );
		}
	    }
	}
    #print ".\n";
    return $best_score;
    }

#########################################################################
sub generate_lex
#########################################################################
    {
    my( $letters_to_use ) = @_;
    my %in_use = ();
    my @lets = split(//,$letters_to_use);
    my $len = scalar(@lets);
    my @bits = 0 .. ($len-1);

    for( my $ctr=(2**$len)-1; $ctr>0; $ctr-- )
	{
	$in_use{
	    join("",
		sort(
		    map( $lets[$_],
			grep( ((2**$_) & $ctr),
			    @bits
			    )
			)
		    )
		)
	    } = 1;
	}
    return keys %in_use;
    }

#########################################################################
#	Main								#
#########################################################################

{
my $letters;

while( defined( $_ = shift( @ARGV ) ) )
    {
    if( ! $letters )
        { $letters = $_; }
    elsif( ! $pattern )
        { $pattern = $_; }
    else
        { &usage("Unknown argument \"$_\"."); }
    }

if( $pattern )
    {
    $_ = $pattern;
    s/\d//g;
    $letters .= $_;

    if( $pattern =~ /^(\d*)(.*?)(\d*)$/ )
        {
	$before = length($1);
	my $after = length($3);
        $check_pattern = $2;
	$dot_pattern = $pattern;
	$dot_pattern =~ s/\d/./g;
	$esplen = length( $check_pattern );
	@patlets = split(//,$pattern);
	print "check_pattern=$check_pattern before=$before esplen=$esplen, patlets=",join(",",@patlets).".\n";
	print "Lexicon is now [$letters]\n";
	}
    }

my @combinations = grep( length($_)>1, &generate_lex( $letters ) );

&read_words();

my %scores;
if( ! $pattern )
    {
    foreach my $used_letters ( @combinations )
        {
	my $s = 0;
	grep( $s+=$letter_points{$_}, split(//,$used_letters) );
	$scores{$used_letters} = $s;
	}
    foreach my $letlist ( sort { $scores{$b}<=>$scores{$a} } @combinations )
	{
	my %seen_word = map ( ($_, 1 ), @{$contains{$letlist}} );
	print join("\n    ",
		"Possible words for $letlist ($scores{$letlist}) are:",
		sort keys %seen_word),"\n"
		if( %seen_word );
	}
    }
else
    {
    my %seen_word = ();
    foreach my $letlist ( @combinations )
	{
	foreach my $word ( grep( length($_)>1, @{$contains{$letlist}}) )
	    {
	    next if( $seen_word{$word} );
	    $seen_word{$word} = 1;
	    $scores{$word} = $_ if( ($_=&pattern_score($word)) > 0 )
	    }
	}
    foreach my $word ( sort {$scores{$b}<=>$scores{$a}} keys %scores )
        {
	printf("%4d %s\n",$scores{$word},$word);
	}
    }
}
