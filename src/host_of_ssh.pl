#!/usr/bin/perl -w

my $DEBUG = 0;

use strict;

$ENV{PATH} = join(":",$ENV{PATH},"/sbin","/usr/sbin");

my @pidlist = ();
while( $_ = shift(@ARGV) )
    {
    if( $_ eq "-d" )
	{ $DEBUG = 1; }
    else
        { push( @pidlist, $_ ); }
    }

push( @pidlist, $$ ) if( ! @pidlist );

my %pid_to_parent = ();
my %pid_to_ps = ();
open( INF, "ps -efww |" ) || die "Cannot run ps:  $!";
while( $_ = <INF> )
    {
    chomp( $_ );
    my($user,$pid,$ppid,$c,$stime,$tty,$time,@rest) = split(/\s+/);
    $pid_to_ps{$pid} = $_;
    $pid_to_parent{$pid} = $ppid;
    }
close( INF );

my %pid_to_lsof = ();
open( INF, "lsof -n 2>/dev/null |" ) || die "Cannot run lsof:  $!";
my $header = <INF>;
while( $_ = <INF> )
    {
    chomp( $_ );
    my($cmd,$pid,$user,$fd,$type,$device,$size_off,@rest) = split(/\s+/);
    push( @{$pid_to_lsof{$pid}}, $_ );
    }
close( INF );

my $exit_status = 0;
foreach my $pid ( @pidlist )
    {
    my $final_ip;
    while( ! $final_ip )
	{
	print $pid_to_ps{$pid}, "\n" if( $DEBUG );
	$_ = join("\n",@{$pid_to_lsof{$pid}});
	if( $_ =~ /TCP (.*?):ssh->(.*?):/s )
	    {
	    $final_ip = $2;
	    #print $_, "\n" if( $DEBUG );
	    print "\n", grep(/TCP (.*?):ssh->(.*?):/, @{$pid_to_lsof{$pid}}), "\n"
		if( $DEBUG );
	    }
	$pid = $pid_to_parent{$pid};
	last if( $pid <= 1 );
	}

    if( ! $final_ip )
        { $exit_status=1; }
    else
        { print $final_ip, "\n"; }
    }
exit( $exit_status );
