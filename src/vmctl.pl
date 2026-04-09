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
my $CURHOST = `hostname`; chomp($CURHOST);
my $VMHOST = "vmhost0";
my $SSHUSERHOST = $USER.'@'.$VMHOST;
my $RUNNING_ON_VMHOST = &same_host( $VMHOST );
my $VIRSH_URI="qemu+ssh://$SSHUSERHOST/system";

my $BASE = "/var/lib/libvirt/images";
my %DIRS =
    (
    Archives	=> "$BASE/Archives",
    Freezer	=> "$BASE/Freezer",
    ISOs	=> "$BASE/ISOs",
    Disks	=> "$BASE/Disks",
    Commands	=> "$BASE/Commands",
    Logs	=> "$BASE/Logs"
    );

use lib "/usr/local/lib/perl";
use cpi_file qw( echodo fatal files_in read_lines read_file );
use cpi_arguments qw( parse_arguments );
use cpi_perl qw( quotes );
use cpi_inlist qw( inlist );
use cpi_sortable qw( numeric_sort );
use cpi_filename qw( basename );
use cpi_time qw( time_string );
use cpi_vars;

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
	"    -status          (same as '-action=status')",
	"    -action <action>",
	"    -command <script name>" );
    }

#########################################################################
#	Return true if we're running on the named host.			#
#########################################################################
sub same_host
    {
    my( $host0, $host1 ) = @_;
    $host0 ||= $CURHOST;	$host0=lc($host0);
    $host1 ||= $CURHOST;	$host1=lc($host1);
    return 1 if( $host1 eq $host0 );
    foreach my $hostline ( &read_lines("/etc/hosts") )
        {
	my @toks = split(/\s+/,lc($hostline));
	return 1 if( &inlist($host0,@toks) && &inlist($host1,@toks) );
	}
    return undef;
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
#	Return the state of the virtual machines.			#
#	Arguably more importantly, returns a table indexed by all	#
#	possible names for those machines.				#
#########################################################################
sub vm_states
    {
    foreach my $line ( &read_lines("virsh -c $VIRSH_URI list --all |") )
	{
	$line =~ s/^\s+//;
	my @toks = split(/\s+/,$line);
	my( $id, $name, @state ) = split(/\s+/,$line);
	$STATES{$name} = $STATES{lc($name)} =
	    { id=>$id, best=>$name, state=>join(" ",@state) }
	    if( $name && $name ne "Name" );
	}

    foreach my $line ( &read_lines("/etc/hosts") )
        {
	my @toks = split(/\s+/,lc($line));
	my( $match ) = grep( $STATES{$_}, @toks );
	grep( $STATES{$_}=$STATES{$match}, @toks ) if( $match );
	}
    return %STATES;
    }

#########################################################################
#	Returns a list of virtual machines we know about.		#
#########################################################################
sub vm_names
    {
    &vm_states() if( ! %STATES );
    my %seen_bests = map { ($STATES{$_}->{best}, 1) } keys %STATES;
    return &numeric_sort( keys %seen_bests );
    }

#########################################################################
#	Returns best name of specified vm if it's one we know about.	#
#########################################################################
sub best_vmname
    {
    my( $name ) = @_;
    &vm_states() if( ! %STATES );
    my $p = $STATES{ lc( $name ) };
    return ( $p ? $p->{best} : undef );
    }

#########################################################################
#	Make sure the named VM is alive.				#
#########################################################################
sub wake_vm
    {
    my( $current_vm, $timer ) = @_;
    $timer ||= 120;	# 2 minutes

    &echodo("virsh -c $VIRSH_URI start $current_vm");

    do  {
        my $retval = &read_file("ssh $current_vm echo $current_vm is alive. 2>&1 |","");
	print STDERR "Alive check returns [$retval]\n" if( $cpi_vars::VERBOSITY );
	return 1 if( $retval =~ /alive/ );
	sleep(2);
	} while( $timer-- > 0 );
    print STDERR "Failed to wake $current_vm after $timer seconds.";
    return undef;
    }

#########################################################################
#	Main								#
#########################################################################

%ARGS = &parse_arguments({
    non_switches	=>	\@non_switches,
    flags		=>	[ "boot", "shutdown" ],
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
	"status"	=>	{ alias=>["-action=status"] },
	"freeze_media"	=>	{ alias=>["-action=freeze_media"] },
	"reset_media"	=>	{ alias=>["-action=reset_media"] },
	"archive_media"	=>	{ alias=>["-action=archive_media"] },
	"query_from_vm"	=>	{ alias=>["-action=query_from_vm"] },
	"action"	=>	[	"multi_command", "status",
					"ls_media", "disk_boot",
					"iso_boot", "freeze_media",
					"reset_media", "archive_media",
					"setup_links", "query_from_vm" ],
	"command"	=>	""
	}
    });

if( $_ = &best_vmname( $cpi_vars::PROG ) )
    {
    unshift( @non_switches, $_ );
    $cpi_vars::PROG = "vmctl";
    }

my %use_vm;
foreach my $non_switch ( @non_switches )
    {
    my $name0;
    if( $non_switch eq "all" || ($name0=&best_vmname($non_switch)) )
        {
	foreach my $name1 ( $non_switch eq "all" ? &vm_names() : ($name0) )
	    {
	    push(@problems,"$name1 specified multiple times.")
		if( $use_vm{$name1}++ );
	    }
        }
    elsif( $non_switch =~ /.*\.iso$/ )
    	{
	$ARGS{ISO} = $non_switch;
	push(@problems,"Cannot read $non_switch.") if( ! -r $non_switch );
	}
    elsif( $non_switch =~ /[1-9](\d*)G/ )
        {
	push(@problems,"Size specified multiple times with $non_switch.") if( $ARGS{size} );
	$ARGS{size} = $non_switch;
	}
    else
        {
	push( @problems, "WTF is \"$non_switch\"?" );
	}
    }

my @vmlist = sort keys %use_vm;

$ARGS{action} = "status"
    if( ( $ARGS{action} eq "multi_command" )
	&& !$ARGS{boot} && !$ARGS{shutdown} && !$ARGS{command} );

if( ! @vmlist )
    {
    if( $ARGS{action} eq "status" )
        { @vmlist = &vm_names(); }
    else
	{ push(@problems,"No vms specified."); }
    }

&usage(@problems) if( @problems);

$cpi_vars::VERBOSITY = $ARGS{verbosity};

$ARGS{size} ||= "10G";

push( @BOOT_ARGS, "-nographic -serial mon:stdio" )	# -append console=ttyS0"
    if( $ARGS{console} eq "serial" );

my $rem = ( $RUNNING_ON_VMHOST ? "" : "ssh $SSHUSERHOST " );

&fatal("Cannot read $ARGS{command}:  $!")
    if( $ARGS{command} && ! -r $ARGS{command} );

my $printed_header = 0;
foreach my $current_vm ( @vmlist )
    {
    if( $ARGS{action} eq "multi_command" )
        {
	print   "ARGS{boot}=[",($ARGS{boot}||"UNDEF"),"],",
		" ARGS{command}=[",($ARGS{command}||"UNDEF"),"]",
		" ARGS{shutdown}=[",($ARGS{shutdown}||"UNDEF"),"]\n";
	if( $ARGS{boot} && ! &wake_vm( $current_vm ) )
	    { $exit_status = 1; continue; }
	if( $ARGS{command} )
	    {
	    my $bn = &basename( $ARGS{command} );
	    my $log = &time_string("$DIRS{Logs}/$bn.%04d-%02d-%02d-%02d:%02d.$current_vm");
	    &echodo("ssh -T $current_vm <",&quotes($ARGS{command}),">",&quotes($log),"2>&1");
	    }
	&echodo("virsh -c $VIRSH_URI shutdown $current_vm") if( $ARGS{shutdown} );
	}
    elsif( $ARGS{action} eq "multi_command" )	# Old, will not happen
        {
	if( $RUNNING_ON_VMHOST )
	    { &ask_do("cp",&quotes($ARGS{command},"$DIRS{Commands}/$current_vm.sh")); }
	else
	    { &ask_do("scp",&quotes($ARGS{command},"${SSHUSERHOST}:$DIRS{Commands}/$current_vm.sh")); }
	&ask_do("virsh -c $VIRSH_URI start $current_vm");
	}
    elsif( $ARGS{action} eq "ls_media" || $ARGS{action} eq "status" )
	{
	&vm_states() if( ! %STATES );

	printf("%-6s %-20s %s\n","Id","VM name","Status") if( ! $printed_header++ );
	printf("%-6s %-20s %s\n",$STATES{$current_vm}{id},$current_vm,$STATES{$current_vm}{state});
	#print "rem=[${rem}]\n";
	if( $ARGS{action} eq "ls_media" )
	    {
	    if( ! $rem )
		{ system("ls -ldh $BASE/*/$current_vm.*"); }
	    else
		{ system("${rem} \"ls -ldh $BASE/*/$current_vm.*\""); }
	    }
	}
    elsif( $ARGS{action} eq "setup_links" )
        {
	&ask_do("rm -f $current_vm; ln -s $cpi_vars::USRLOCAL/bin/$cpi_vars::PROG $current_vm");
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
    elsif( $ARGS{action} eq "query_from_vm" )
        {
	if( ! chdir( $DIRS{Commands} ) )
	    { &fatal("Cannot chdir($DIRS{Commands}):  $!"); }
	elsif( -r "$current_vm.sh" )
	    {
	    if( rename( "$current_vm.sh", "$current_vm.doing" ) )
		{ print &read_file( "$current_vm.doing" ); }
	    else
		{ fatal("Cannot rename $DIRS{Commands}/current_vm.sh to $DIRS{Commands}/current_vm.doing:  $!"); }
	    }
	}
    else
        { &fatal("Unknown command \"$ARGS{action}\"."); }
    }

exit( $exit_status );
