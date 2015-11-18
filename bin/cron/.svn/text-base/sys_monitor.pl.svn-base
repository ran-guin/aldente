#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

sys_monitor.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>Performs various system resources monitoring<BR>Reference to standard Perl modules<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
###################################################################################################################################
# sys_monitor.pl
#
# Performs various system resources monitoring
#
# $Id: sys_monitor.pl,v 1.11 2004/12/07 21:45:35 jsantos Exp $
###################################################################################################################################
### Reference to standard Perl modules
use strict;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
### Reference to alDente modules
use alDente::SDB_Defaults;
use alDente::Notification;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Process_Monitor;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
### Global variables
use vars qw($administrator_email %Configs $opt_watch $opt_notify $opt_url $opt_link $opt_threshold);

use Getopt::Long;
&GetOptions(
    'watch=s'     => \$opt_watch,
    'notify=s'    => \$opt_notify,
    'url=s'       => \$opt_url,
    'link=s'      => \$opt_link,
    'threshold=s' => \$opt_threshold,
);

##############################
# modular_vars               #
##############################
my $watch            = $opt_watch;                  ## variable directory name to watch ##
my $notify           = $opt_notify || 'aldente';    ## notification list if space on watched directory gets low
my $url              = $opt_url;                    ## link to this url in message (optional)
my $link             = $opt_link;                   ## name of link to above url (optional)
my $custom_threshold = $opt_threshold;

##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
### Modular variables
######################## construct Process_Monitor object for writing to log file ###########
my $Report = Process_Monitor->new('sys_monitor.pl Script');
my $debug  = 0;                                               ## turn this on for debugging...

#hostname: ap1120-ech-wifi-fl6a.phage.bcgsc.ca
#ip: 10.9.206.10
#location: 6th floor, sequencing side

#hostname: ap1120-ech-wifi-fl6b.phage.bcgsc.ca
#ip: 10.9.206.12
#location: 6th floor, mapping side

#hostname: 3comrf05-ech-wifi-fl5a.phage.bcgsc.ca
#ip: 10.9.206.13
#location: 5th floor lab

use SDB::DBIO;
my %Hubs;
my %Printers;

my ( $dbase, $host, $user, $password ) = ( 'sequence', 'lims01', 'viewer', 'viewer' );
my $dbc = SDB::DBIO->new( -dbase => $dbase, -user => $user, -password => $password, -host => $host, -connect => 1 );
my %printers = $dbc->Table_retrieve( 'Printer', [qw(Printer_ID Printer_Name Printer_Location Printer_Type)], "WHERE Printer_Output <> 'Off'" );

my $i = 0;
while ( defined $printers{Printer_ID}[$i] ) {
    my $id       = $printers{Printer_ID}[$i];
    my $name     = $printers{Printer_Name}[$i];
    my $location = $printers{Printer_Location}[$i];
    my $type     = $printers{Printer_Type}[$i];
    $Printers{$id}{IP}       = $name;
    $Printers{$id}{location} = "$location [$type]";
    $i++;
}

## check access point hubs as well ##
$Hubs{'lab_ap1'}{IP}       = '10.9.206.10';
$Hubs{'lab_ap1'}{location} = '6th floor Sequencing lab';
$Hubs{'lab_ap2'}{IP}       = '10.9.206.16';
$Hubs{'lab_ap2'}{location} = '6th floor GE/Mapping lab';
$Hubs{'lab_ap3'}{IP}       = '10.9.206.15';
$Hubs{'lab_ap3'}{location} = '5th floor lab';

_ping_hubs();
_ping_printers();

########################
# check storage space ##
########################

my %data_volumes;
$data_volumes{'Data_home_dir'} = $Configs{'Data_home_dir'};
$data_volumes{'Home_public'}   = $Configs{'Home_public'};
$data_volumes{'mirror_dir'}    = $Configs{'mirror_dir'};
$data_volumes{'Home_dir'}      = $Configs{'Home_dir'};

$archive_dir = $Configs{'archive_dir'};
chdir("$archive_dir");

#get all data directories in archive
my @archive_volumes = `find -path "*/data?" -maxdepth 3`;
my %archive_filer_vols;

# use hash to get list of unique volumes in archive
foreach my $archive_volume (@archive_volumes) {
    my $filer_vol = try_system_command("df -hP $archive_volume");
    $archive_filer_vols{"$filer_vol"} = "$archive_dir/$archive_volume";
}

## add archive volumes to data_volumes##
foreach my $archive_filer_vol ( values %archive_filer_vols ) {
    $data_volumes{"$archive_filer_vol"} = "$archive_filer_vol";
}

_check_disk_usages( -threshold => '100' );    ## pass in custom thresholds via input parameters (eg -watch solexa -notify mhirst -threshold 2000);

$Report->completed();
$Report->DESTROY();
exit;

#############################
# check printer connectivity
#############################
sub _ping_printers {
#############################
    my @printers = sort keys %Printers;
    $Report->set_Message("\nChecking Printers");

    my $print_test_str = '';
    $print_test_str .= "checking lpstat for printers:\n";
    map { $print_test_str .= "$_ : $Printers{$_}{IP} in $Printers{$_}{location}\n"; } @printers;
    $print_test_str .= "\n\n";
    $Report->set_Detail($print_test_str);

    my $tested = 0;
    foreach my $printer (@printers) {
        my $printer_name = $Printers{$printer}{IP};
        my $check        = try_system_command("lpstat -v $printer_name");
        $print_test_str .= $check;
        if ( $check =~ /disabled/ ) {
            $Report->set_Error("$printer_name ($Printers{$printer}{location} disabled");
        }
        elsif ( $check =~ /unknown/i ) {
            $Report->set_Error("$printer_name ($Printers{$printer}{location} unknown");
        }
        else {
            $Report->succeeded();
            $Report->set_Message("$printer_name: $Printers{$printer}{location} status: OK");
        }
        $tested++;
    }

    $Report->set_Detail("\ntested $tested printers\n\n");
    return 1;
} ## end sub _ping_printers

########################
# Ping the wireless hubs
########################
sub _ping_hubs {
########################

    my @hubs = sort keys %Hubs;
    $Report->set_Message("\nChecking hubs");

    my $PING_TRIALS = 2;

    my $hub_str = '';

    $hub_str .= "pinging hubs:\n";
    map { $hub_str .= "$_ : $Hubs{$_}{IP} in $Hubs{$_}{location}\n"; } @hubs;
    $hub_str .= "\n\n";

    my $summary_str = '';

    foreach my $hub ( sort keys %Hubs ) {
        my $address = $Hubs{$hub}{IP};
        my $cmd     = "ping -c $PING_TRIALS $address";
        $hub_str = "$cmd...\n";
        my $fback = try_system_command($cmd);
        $hub_str .= "$fback\n";

        $Report->set_Detail($hub_str);
        print $hub_str if $debug;

        my ( $warnings, $errors ) = ( 0, 0 );
        foreach my $line ( split /\n/, $fback ) {
            my $detail = "$hub : $line";
            if ( $line =~ /Destination Host Unreachable/ ) {
                $errors++;
                $detail .= " (Host Unreachable)";
            }
            elsif ( $line =~ /unknown host/ ) {
                $errors++;
                $detail .= " (Unknown Host)";
            }
            elsif ( $line =~ /,\s+[1-9]+%\s+packet loss/ ) {
                $warnings++;
                $detail .= " (packet loss)";
            }
            else {
                ## OK On this pass
            }
            $Report->set_Detail($detail);
        }

        if ($errors) {
            $Report->set_Error("$hub: $Hubs{$hub}{location} status: ERROR");
        }
        elsif ($warnings) {
            $Report->set_Warning("$hub: $Hubs{$hub}{location} status: WARNING");
        }
        else {
            $Report->succeeded();
            $Report->set_Message("$hub: $Hubs{$hub}{location} status: OK");
        }
    } ## end foreach my $hub ( sort keys...
    return 1;
} ## end sub _ping_hubs

###########################
# Check disk usages
#
# For custom warnings include the following flags in the call to sys_monitor:
#
# -watch (watch directory)
# -notify (target list)
# -threshold (custom threshold)
# -url       (optional url link included in message)
# -link      (optional link text to replace url tag)
#
# Eg: sys_monitor.pl -watch solexa -notify mhirst,tzeng -threshold 2000 -url "http://lims02.bcgsc.ca/SDB/cgi-bin/barcode.pl" -link 'Log into LIMS'
#
###########################
sub _check_disk_usages {
    my %args           = @_;
    my $disk_threshold = $args{-threshold};
    $Report->set_Message("\nChecking Disk Usage");

    my $WARNING_PERCENT = 90;
    my $ERROR_PERCENT   = 98;

    foreach my $data_volume ( keys %data_volumes ) {

        my $fback = try_system_command( -command => "df -hP $data_volumes{$data_volume}" );
        $Report->set_Detail($fback);

        my @output = split '\n', $fback;
        foreach my $line (@output) {
            if ( $line =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/ ) {
                my $disk = $1;
                if ( $disk =~ /Filesystem/ ) { next; }
                my $size         = $2;
                my $used         = $3;
                my $avail        = $4;
                my $used_percent = $5;
                my $mount        = $6;
                my $avail_disk;

                if ( $avail =~ /(\d+)G/i ) {
                    $avail_disk = $1;
                }
                elsif ( $avail =~ /(\d+\.\d+)T/i ) {
                    $avail_disk = $1;
                    $avail_disk *= 1000;
                }
                if ( $used_percent =~ /(\d+)%/ ) { $used_percent = $1 }
                my $msg = "$disk = $used_percent % Used ! ($avail available)";

                my $custom_warning = ( $data_volumes{$data_volume} =~ /$watch/ ) && ( $avail_disk < $custom_threshold );

                if ( $used_percent > $ERROR_PERCENT && $avail_disk < $disk_threshold ) {
                    $Report->set_Error($msg);
                }
                elsif ( $used_percent > $WARNING_PERCENT && $avail_disk < $disk_threshold ) {
                    $Report->set_Warning($msg);
                }
                elsif ($custom_warning) {
                    $Report->set_Warning("Custom Warning: $msg");
                }
                else {
                    $Report->set_Detail($msg);
                    $Report->set_Message("Checking volume: $data_volumes{$data_volume} : OK");
                    $Report->set_Message("$msg");
                    $Report->succeeded();
                }

                ## also generate custom warning emails if applicable ##

                if ($custom_warning) {
                    ## customized watches ##

                    my $subject = "CUSTOM WARNING: $avail_disk G left on $data_volumes{$data_volume}";
                    my $to_address = $notify || 'aldente';
                    $subject .= " (custom watch)";

                    #  my $to_address = 'mhirst@bcgsc.ca,tzeng@bcgsc.ca,yzhao@bcgsc.ca,mingham@bcgsc.ca';
                    my $from_address = 'aldente@bcgsc.ca';

                   # my $url = &Link_To("http://lims02.bcgsc.ca/SDB/cgi-bin/barcode.pl?User=Auto&Generate+Results=1&File=/opt/alDente/www/dynamic/cache//Group/11/general/SLX+-+Runs+Ready+for+Image+Deletion+and+Storage.yml","Solexa Run Data Storage Page");
                    my $email_body = $subject;

                    if ($url) { $email_body .= "\n\n" . Link_To( $url, $link ) }

                    my $ok = &alDente::Notification::Email_Notification(
                        -to_address   => $to_address,
                        -from_address => $from_address,
                        -subject      => $subject,

                        #									    -header=>"html", #doesn't work, why?
                        -body_message => $email_body,
                        -verbose      => 0,
                        -content_type => 'html',
                    );

                } ## end if ($custom_warning)
            } ## end if ( $line =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/)
        } ## end foreach my $line (@output)
    } ## end foreach my $data_volume ( keys...
    my @monitor_directories = ( '/opt/alDente', '/home/aldente' );

    foreach my $directory (@monitor_directories) {
        my $output = try_system_command("du --max-depth=2 -h $directory");
        $Report->set_Detail( "$directory usage " . date_time() . "\n*****************************\n$output" );
    }
} ## end sub _check_disk_usages

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

##############################

$Report->DESTROY();
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: sys_monitor.pl,v 1.11 2004/12/07 21:45:35 jsantos Exp $ (Release: $Name:  $)

=cut 
