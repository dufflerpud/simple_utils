#!/usr/bin/perl -w
#
#indx#	vmctl.pl - Wrapper to virsh to maintain qemu style virtual machines
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
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
#hist#	2026-03-27 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	vmctl.pl - Wrapper to virsh to maintain qemu style virtual machines
########################################################################

use strict;

my $DISK_FMT="qcow2";
my $ARCH="x86_64";
my @BOOT_ARGS=( "-m 2048 -cpu max -smp 4 -accel kvm" );
my $USER = $ENV{USER};
my $VMHOST = "vmhost0";
my $VIRSH_URI="qemu+ssh://${USER}\@$VMHOST/system";

my $BASE = "/var/lib/libvirt/images";
my %DIRS =
    (
    Archives	=> "$BASE/Archives",
    Freezer	=> "$BASE/Freezer",
    ISOs	=> "$BASE/ISOs",
    Disks	=> "$BASE/Disks"
    );

use lib "/usr/local/lib/perl";
use cpi_file qw( echodo fatal files_in read_lines );
use cpi_arguments qw( parse_arguments );

our @non_switches;		# Used for parsing arguments
our @problems;
our %ARGS;
our $exit_status = 0;
my %STATES;

#########################################################################
#	Print a usage message and exit.					#
#########################################################################
sub usage()
    {
    &fatal( @_, "", "Usage:  $cpi_vars::PROG <arguments>",
	"  where <arguments> are:",
	"    -verbosity <n>",
	"    -yes             (same as '-answer=yes')",
	"    -no              (same as '-answer=no')",
	"    -answer <answer to questions>",
	"    -graphics        (same as '-console=graphics')",
	"    -serial          (same as '-console=serial')",
	"    -console <console type>",
	"    -disk_boot       (same as '-action=disk_boot')",
	"    -iso_boot        (same as '-action=iso_boot')",
	"    -ls_media        (same as '-action=ls_media')",
	"    -freeze_media    (same as '-action=freeze_media')",
	"    -reset_media     (same as '-action=reset_media')",
	"    -archive_media   (same as '-action=archive_media')",
	"    -action <action>",
	"    -command <script name>" );
    }

#########################################################################
#	Show what command you're about to do and then do it.		#
#########################################################################
sub ask_do()
    {
    my( @args ) = @_;
    for( my $ans=$ARGS{answer}; 1; )
        {
	if( $ans =~ /^n/i )
	    { print "# ",join(" ",@args),"\n"; return 0; }
	elsif( $ans =~ /^y/i )
	    { print "+ ",join(" ",@args),"\n"; system(join(' ',@args)); return 1; }
	    #{ print "+ ",join(" ",@args),"\n"; return 1; }
	print join(" ",@args)," (y or n)?  ";
	$ans = <STDIN>;
    	}
    }

#########################################################################
#	Return the state of the virtual machines			#
#########################################################################
sub vm_states
    {
    foreach my $line ( &read_lines("virsh -c $VIRSH_URI list --all |") )
	{
	$line =~ s/^\s+//;
	my @toks = split(/\s+/,$line);
	my( $id, $name, @state ) = split(/\s+/,$line);
	$STATES{$name} = { id=>$id, state=>join(" ",@state) }
	    if( $name && $name ne "Name" );
	}
    return %STATES;
    }

#########################################################################
#	Returns a list of virtual machines we know about.		#
#########################################################################
sub vm_names
    {
    &vm_states() if( ! %STATES );
    return sort keys %STATES;
    }

#########################################################################
#	Returns true if specified machine is a vm we know about.	#
#########################################################################
sub valid_vmname
    {
    &vm_states() if( ! %STATES );
    return ( $STATES{$_[0]} ? 1 : undef );
    }

#########################################################################
#	Main								#
#########################################################################

%ARGS = &parse_arguments({
    non_switches	=>	\@non_switches,
    switches=>
    	{
	"verbosity"	=>	0,
	"yes"		=>	{ alias=>["-answer=yes"] },
	"no"		=>	{ alias=>["-answer=no"] },
	"answer"	=>	[ "ask", "yes", "no" ],
	"graphics"	=>	{ alias=>["-console=graphics"] },
	"serial"	=>	{ alias=>["-console=serial"] },
	"console"	=>	[ "graphics", "serial" ],
	"disk_boot"	=>	{ alias=>["-action=disk_boot"] },
	"iso_boot"	=>	{ alias=>["-action=iso_boot"] },
	"ls_media"	=>	{ alias=>["-action=ls_media"] },
	"freeze_media"	=>	{ alias=>["-action=freeze_media"] },
	"reset_media"	=>	{ alias=>["-action=reset_media"] },
	"archive_media"	=>	{ alias=>["-action=archive_media"] },
	"action"	=>	[ "ls_media", "disk_boot", "iso_boot", "freeze_media", "reset_media", "archive_media", "setup_links" ],
	"command"	=>	""
	}
    });

if( &valid_vmname( $cpi_vars::PROG ) )
    {
    unshift( @non_switches, $cpi_vars::PROG );
    $cpi_vars::PROG = "vmctl";
    }

my %use_vm;
foreach my $name0 ( @non_switches )
    {
    if( $name0 eq "all" || &valid_vmname( $name0 ) )
        {
	foreach my $name1 ( $name0 eq "all" ? &vm_names() : ($name0) )
	    {
	    push(@problems,"$name1 specified multiple times.")
		if( $use_vm{$name1}++ );
	    }
        }
    elsif( $name0 =~ /.*\.iso$/ )
    	{
	$ARGS{ISO} = $name0;
	push(@problems,"Cannot read $name0.") if( ! -r $name0 );
	}
    elsif( $name0 =~ /[1-9](\d*)G/ )
        {
	push(@problems,"Size specified multiple times with $name0.") if( $ARGS{size} );
	$ARGS{size} = $name0;
	}
    else
        {
	push( @problems, "WTF is \"$name0\"?" );
	}
    }

my @vmlist = sort keys %use_vm;

push(@problems,"No vms specified.") if( ! @vmlist );

&usage(@problems) if( @problems);

$ARGS{size} ||= "10G";

push( @BOOT_ARGS, "-nographic -serial mon:stdio" )	# -append console=ttyS0"
    if( $ARGS{console} eq "serial" );

my $rem = "ssh vmhost0 ";
$rem = "";

foreach my $current_vm ( @vmlist )
    {
    if( $ARGS{action} eq "ls_media" )
	{
	&vm_states() if( ! %STATES );
	printf("%-6s %-20s %s\n",$STATES{$current_vm}{id},$current_vm,$STATES{$current_vm}{state});
	if( ! $rem )
	    { system("${rem}ls -ldh $BASE/*/$current_vm.*"); }
	else
	    { system("${rem} \"ls -ldh $BASE/*/$current_vm.*\""); }
	}
    elsif( $ARGS{action} eq "setup_links" )
        {
	&ask_do("rm -f $current_vm; ln -s /usr/local/bin/$cpi_vars::PROG $current_vm");
	}
    elsif( $ARGS{action} eq "reset_media" )
	{
	&ask_do("virsh -c $VIRSH_URI destroy $current_vm");
	&ask_do("${rem}cp -f $DIRS{Freezer}/$current_vm.$DISK_FMT $DIRS{Disks}/$current_vm.$DISK_FMT");
	&ask_do("virsh -c $VIRSH_URI start $current_vm");
	}
    elsif( $ARGS{action} eq "freeze_media" )
	{
	&ask_do("${rem}cp -f $DIRS{Disks}/$current_vm.$DISK_FMT $DIRS{Freezer}/$current_vm.$DISK_FMT");
	}
    elsif( $ARGS{action} eq "archive_media" )
	{
	if( $rem )
	    { &ask_do("${rem}'bzip2 < $DIRS{Disks}/$current_vm.$DISK_FMT > $DIRS{Archives}/$current_vm.$DISK_FMT.bz2'"); }
	else
	    { &ask_do("bzip2 < $DIRS{Disks}/$current_vm.$DISK_FMT > $DIRS{Archives}/$current_vm.$DISK_FMT.bz2"); }
	}
    elsif( $ARGS{action} eq "disk_boot" )
	{
	&ask_do(
	    "${rem}exec qemu-system-$ARCH", @BOOT_ARGS,
	    "-drive file=$DIRS{Disks}/$current_vm.$DISK_FMT",
	    "-boot menu=on" );
	}
    elsif( $ARGS{action} eq "iso_boot" )
	{
	&ask_do("${rem}qemu-img create -f $DISK_FMT $DIRS{Disks}/$current_vm.$DISK_FMT $ARGS{size}");
	&ask_do(
	    "${rem}qemu-system-$ARCH", @BOOT_ARGS,
	    "-drive file=$DIRS{Disks}/$current_vm.$DISK_FMT",
	    "-boot d -cdrom",
	    ( $ARGS{ISO} ? $ARGS{ISO} : "$DIRS{ISOs}/$current_vm.iso" ) );
	}
    else
        { &fatal("Unknown command \"$ARGS{action}\"."); }
    }

exit( $exit_status );
