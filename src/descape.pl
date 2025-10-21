#!/usr/bin/perl

while( $_ = <STDIN> )
    {
    s/\r*//g;
    s/\033\[.*?m//g;
    print $_;
    }
