#!/usr/bin/perl

use strict;
use Digest::MD5;

sub fatal
    {
    print STDERR "$_[0]\n";
    exit(1);
    }

sub getchecksum
    {
    my( $fn ) = @_;
    if( $fn =~ /^proc\// )
	{ return "-"; }
    elsif( ! open( CS, $fn ) )
	{ return "$fn:  $!"; }
    else
        {
	binmode( CS );
	my $md5 = Digest::MD5->new;
	$md5->addfile( *CS );
	close( CS );
	return $md5->b64digest;
	}
    }

my @dirs = ();
while( $_ = shift(@ARGV) )
    {
    push( @dirs, $_ );
    }

my @fn = ();
my $d;
foreach $d ( @dirs )
    {
    open( INF, "find $d -print |" ) || &fatal("Cannot find $_:  $!");
    while( $_ = <INF> )
        {
	chomp( $_ );
	$_ =~ s/^\.\///;
	push( @fn, $_ );
	}
    close( INF );
    }

my $name;
foreach $name ( sort @fn )
    {
    if( my($dev,$ino,$mode,$nlink,$uid,$gid,$dev2,$size) = lstat($name) )
	{
	my $contentcsum = "-";
	if( -l _ )
	    {
	    $contentcsum = readlink( $name );
	    $contentcsum =~ s/\|/\\|/g;
	    }
	elsif( -b _ || -c _ )
	    {
	    $contentcsum = $dev2;
	    $size = 0;
	    }
	elsif( -d _ )
	    { $size = 0; }
	elsif( -f _ )
	    { $contentcsum = &getchecksum($name); }
	$name =~ s/\|/\\|/g;
	printf("%s|%06o|%d|%d|%d|%s|%s\n",
	    $name, $mode, $uid, $gid, $size, $contentcsum );
	}
    }
exit(0);
