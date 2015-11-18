#!/usr/local/bin/perl
###################################################################################################################################
# sys_monitor.pl
#
# Performs various system resources monitoring
#
# $Id: sys_monitor.pl,v 1.11 2004/12/07 21:45:35 jsantos Exp $
###################################################################################################################################
##############################
# perldoc_header             #
##############################

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/LampLite";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";

########################
## Local Core modules ##
########################
use CGI;
use CGI::Carp('fatalsToBrowser');
use Data::Dumper;
use Benchmark;

use strict;

##########################
## Local custom modules ##
##########################
use RGTools::RGIO;
use RGTools::Process_Monitor;
use LampLite::Bootstrap;

use SDB::DBIO;                  ## use to connect to database 

use alDente::Config;            ## use to initialize configuration settings

## Globals ##
my $q               = new CGI;
my $BS              = new Bootstrap();
my $start_benchmark = new Benchmark();
my $yellow_on_black = "\033[1m\033[33m\033[40m";
my $red_on_black = "\033[1m\033[31m\033[40m";
my $default_color = "\033[0m";
my $blue           = "\033[1m\033[34m";
my $cyan			= "\033[36m";
$| = 1;
##############################################################
## Temporary - phase out globals gradually as defined below ##
##############################################################
use vars qw(%Configs);        ## replace with $dbc->config() ... need to also expand config list as done in SDB/Custom_Settings currently...
###############################################################

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
my $Config = new alDente::Config(-initialize=>1, -root=>$FindBin::RealBin . '/..');

my ($home, $version, $domain, $custom, $path, $dbase, $host, $login_type, $session_dir, $init_errors, $url_params, $session_params, $brand_image, $screen_mode, $configs, $custom_login, $css_files, $js_files) = 
    ($Config->{home}, $Config->{version}, $Config->{domain}, $Config->{custom}, $Config->{path}, $Config->{dbase}, $Config->{host}, $Config->{login_type}, $Config->{session_dir}, $Config->{init_errors}, 
        $Config->{url_params}, $Config->{session_params}, $Config->{icon}, $Config->{screen_mode}, $Config->{configs}, $Config->{custom_login}, $Config->{css_files}, $Config->{js_files});
        
if (ref $configs eq 'HASH') { %Configs = %$configs }
###################################################
## END OF Standard Module Initialization Section ##
###################################################

###################################################

use File::Path;
use RGTools::Directory;
use alDente::SDB_Defaults;
use alDente::Notification;
use alDente::Subscription;
use alDente::System;

###################################################

## Load input parameter options (YML file)## 

use vars qw( $administrator_email %Configs @custom_dirs @custom_space @custom_warnings @custom_errors $count @custom_df @custom_du @custom_servers @du_warning);

use YAML;
use Data::Dumper;
use File::Path;

my $filename         = "sys_monitor_config.yml";
my $file        = $FindBin::RealBin . '/../conf/' . $filename;
  my $message;
my $conf = YAML::LoadFile($file);

my $variation				= $conf->{v};
my $watch					= $conf->{watch};
my $notify					= $conf->{notify};
my $url						= $conf->{url};
my $link						= $conf->{link};
my $threshold				= $conf->{threshold};
my $debug 					= $conf->{debug};
my $check					= $conf->{check};
my $log						= $conf->{log};
my $host						= $conf->{host};
my $warning_percent			= $conf->{warning_percent};
my $error_percent			= $conf->{error_percent};
my $b_dbase  				= $configs->{BACKUP_DATABASE};
my $b_host   				= $configs->{BACKUP_HOST};

$configs->{path} = $FindBin::RealBin . '/../www';

##############################
### LOGIC
##############################

my $log_threshold = '0.1G';    ## size at which sizes information is logged for monitoring in primary sys_monitor directory ##

my @checked_location;          ## list of checked directories to avoid cehcking them more than once
my @sent_emails;

my $logfile = $Config->get_log_file(-ext=>'html', -config=>$configs, -type=>'relative');
my $Report = Process_Monitor->new( -testing => !$log, -url=>$logfile, -variation => $variation, -configs=>$configs ); 
my $dbc = SDB::DBIO->new( -dbase => $b_dbase, -user => 'cron_user', -host => $b_host, -connect => 1, -config=>$configs );
if (! $dbc->{connected} ) { print "Error connecting to $host.$dbase as cron_user\n"; exit; }
my $system = alDente::System->new( -dbc => $dbc, -report => $Report );

my $conf_hosts 			= $conf->{hosts_to_check_for_printers};
my @printer_hosts 		= @{$conf_hosts};
$conf_hosts 			= $conf->{hosts_to_check_for_hubs};
my @hub_hosts			= @{$conf_hosts};
$conf_hosts 			= $conf->{hosts_to_check_for_volumes};
my @volume_hosts			= @{$conf_hosts};
$conf_hosts 			= $conf->{hosts_to_check_for_directories};
my @directory_hosts			= @{$conf_hosts};
my @hosts     = $system->get_all_hosts();    # = ('lims01','limsdev02');#
_create_stat_dirs( -hosts => \@hosts );

my $logging;
if   ($log) { $logging = "Logging ON" }
else        { $logging = "Logging OFF" }

if ( $check =~ /^all/i ) { $check = 'server, printers, hubs, volumes' }


###############################
# Check QUOTA
###############################
$Report->start_Section("Checking Quota...", -target => "QUOTA");
my $QUOTA				= $conf->{QUOTA};
my @quota				= @{$QUOTA};
if (@quota)	{
my $quota_command;
my $quota_warning;
my $quota_error;
foreach my $key (@quota)	{
	
my %hash = %$key;
my @keys = keys %hash ;
my @values = values %hash;
my $Count = 0;
foreach $key (@keys) {
if    ($key eq 'command'			) { $quota_command	= $values[$Count]; }
elsif ($key eq 'warning_percent'	) { $quota_warning	= $values[$Count]; }
elsif ($key eq 'error_percent'	) { $quota_error		= $values[$Count]; }
else	{print "ERROR - invalid argument of QUOTA\n";exit;}
			}
		}
$count = 3;
my $qut = -1;
my $block;
while($qut eq -1 && $count ne 0)	{
	my $fback = try_system_command( -command => $quota_command );
    my @output = split "\n", $fback;
  	my $size = @output;
  	my $line = $size-1;
        $output[$line] =~ /^(\d+)\s+(\d+)/;
$qut = $2;$block =$1;
if (!$qut)	 {  $qut = -1;}
$count--;
				}
if ($qut ne -1 && $qut ne 0 && $qut)	{
	my $percent_used = ($block/$qut)*(100);
	my $rounded_prcnt = sprintf("%.2f", $percent_used);
if ($percent_used < $quota_warning)		{ 
	my @msg = "Disk quota for user aldente: $rounded_prcnt % used | (Blocks = $block) (quota = $qut)";
my @wrng; my @err; my @detail;
	$Report->parse_message_warning_error( \@msg, \@wrng,\@err ,\@detail , -of_sys_monitor => "sys_monitor" );
			}
elsif ($percent_used >= $quota_error)	{ $Report->set_Error("Disk quota for user aldente: $rounded_prcnt % used | (Blocks = $block) (quota = $qut)");}	
else 	{ $Report->set_Warning("Disk quota for user aldente: $rounded_prcnt % used | (Blocks = $block) (quota = $qut)");}
		}
else {$Report->set_Error("Couldn't get 'percent_used' for quota command | (Blocks = $block) (quota = $qut)");	}
	}

###########################################
# Parse 'SHOW_DIR' element in sys_monitor_conf.yml file
########################################### 
my $SHOW_DIR				= $conf->{SHOW_DIR};
my @show_dir				= @{$SHOW_DIR};
my $index = 0;
foreach my $key (@show_dir)	{
	my %hash_key	= %$key;
	my @dir_key		=  keys %hash_key;
	$custom_dirs[$index] = $dir_key[0];
	my @dir_value	= values %hash_key;
	my $d_value	= $dir_value[0];

my %hash = %$d_value;
my @keys = keys %hash ;
my @values = values %hash;
my $Count = 0;
foreach $key (@keys) {
if    ($key eq 'threshold'		) { $custom_space[$index]		= $values[$Count]; }
elsif ($key eq 'warning_percent') { $custom_warnings[$index]	= $values[$Count]; }
elsif ($key eq 'error_percent'	) { $custom_errors[$index]		= $values[$Count]; }
elsif ($key eq 'df'				) { $custom_df[$index]			= $values[$Count]; }
elsif ($key eq 'du'				) { $custom_du[$index]			= $values[$Count]; }
elsif ($key eq 'server'			) { $custom_servers[$index]			= $values[$Count]; }
elsif ($key eq 'du_warning_threshold') { $du_warning[$index]			= $values[$Count]; }
else	{$Report->set_Error("Invalid argument ($key) of SHOW_DIR\n");
		exit;		
		}
	$Count++;
	}
$index++;
}

##################
	
if ($debug)	{
print $blue;
$Report->set_Message("Checking: $check ($logging)");
print $default_color;
}
if ( $check =~ /printer/ ) {
	for my $host (@printer_hosts) {
    ###########################
    #####   SERVER hosts ######
    ###########################
    if ( $check =~ /server/ ) {
        $Report->start_Section("Checking Server: $host", -target => "server");
      
        my $host_active = $system->ping_server( -host => $host );

        unless ($host_active) {
            $Report->set_Error("Host $host is not available");
            $Report->end_Section("Checking Server: $host", -target => "server");
            next;
        }
    }

    ##########################
    #####   Printers    ######
    ##########################
 
        $Report->start_sub_Section("Checking Printers for $host", -target => "printer");
        my %Printers = $system->get_printers_info( -dbc => $dbc, -report => $Report );
        my ( $success, $warning, $error, $detail ) = $system->ping_printers( -printers => \%Printers, -host => $host, -report => $Report );

        $Report->succeeded( int(@$success) );
        $Report->parse_message_warning_error( $success, $warning, $error, $detail, -target => "printer", -of_sys_monitor => "sys_monitor" );

        $Report->end_sub_Section("Checking Printers for $host", -target => "printer");
    }

}

if ( $check =~ /hub/ ) {
for my $host (@hub_hosts) {

    ###########################
    #####   SERVER hosts ######
    ###########################
    if ( $check =~ /server/ ) {
        $Report->start_Section("Checking Server: $host", -target => "server");
        my $host_active = $system->ping_server( -host => $host );

        unless ($host_active) {
            $Report->set_Error("Host $host is not available");
            $Report->end_Section("Checking Server: $host", -target => "server");
            next;
        }
    }

    ##########################
    #####   HUBS        ######
    ##########################
        $Report->start_sub_Section("Checking hubs", -target => "hubs");

        ### Information below should be moved to database (in Machine Default table - ensuring that hubs are in database as Equipment) ###
        my %Hubs;
        $Hubs{'lab_ap1'}{IP}       = 'ap1131-ech-wifi-fl6b';
        $Hubs{'lab_ap1'}{location} = '6th floor South Side of the Lab';
        $Hubs{'lab_ap2'}{IP}       = 'ap1131-ech-wifi-fl6c';
        $Hubs{'lab_ap2'}{location} = '6th floor Front Entrance of the Lab';
        $Hubs{'lab_ap3'}{IP}       = 'ap1131-ech-wifi-fl6d';
        $Hubs{'lab_ap3'}{location} = '6th floor North Side of the Lab';

        $Hubs{'lab_ap4'}{IP}       = 'ap1131-ech-wifi-fl5a';
        $Hubs{'lab_ap4'}{location} = '5th floor lab';

        foreach my $key ( keys %Hubs ) {
            my $ip       = $Hubs{$key}{IP};
            my $location = $Hubs{$key}{location};
            my ( $msg, $warning, $error, $detail ) = $system->ping_hub( -ip => $ip, -location => $location, -host => $host );
            $Report->parse_message_warning_error( $msg, $warning, $error, $detail, -of_sys_monitor => "sys_monitor" );
        }

        $Report->end_sub_Section("Checking hubs", -target => "hubs");
    }
}

if ( $check =~ /volume/ ) {
for my $host (@volume_hosts) {

    ###########################
    #####   SERVER hosts ######
    ###########################
    if ( $check =~ /server/ ) {
        $Report->start_Section("Checking Server: $host", -target => "server");
        my $host_active = $system->ping_server( -host => $host );

        unless ($host_active) {
            $Report->set_Error("Host $host is not available");
            $Report->end_Section("Checking Server: $host", -target => "server");
            next;
        }
    }
    ##########################
    ##### Data Volumes  ######
    ##########################
        $Report->start_sub_Section("Checking 'df' Usage on $host", -target => "volume");
        monitor_df_usage( -system => $system, -host => $host );
        $Report->end_sub_Section("Checking 'df' Usage on $host", -target => "volume");

		$Report->start_sub_Section("Checking 'du' Usage on $host", -target => "volume");
        monitor_du_usage( -system => $system, -host => $host );
        $Report->end_sub_Section("Checking 'du' Usage on $host", -target => "volume");

    }
}
######## OLD and detailed way of checking 'du'
   if ( $check =~ /director/ ) {
for my $host (@directory_hosts) {

    ###########################
    #####   SERVER hosts ######
    ###########################
    if ( $check =~ /server/ ) {
        $Report->start_Section("Checking Server: $host", -target => "server");
        my $host_active = $system->ping_server( -host => $host );

        unless ($host_active) {
            $Report->set_Error("Host $host is not available");
            $Report->end_Section("Checking Server: $host", -target => "server");
            next;
        }
    }
    ############################
    ##### Directory Usage ######
    ############################
        $Report->start_Section("Checking Directories For: $host", -target => "directory");

        monitor_directory_usage( $system, $host );
        $Report->end_Section("Checking Directories For: $host", -target => "directory");

    }
}

if ( $check =~ /volume/ ) {
    $system->log_directory_usage( -host => 'shared', -threshold => $log_threshold );    ##

if ( $message =~ /\w/ ) {
    print "Sending notification\n";
        send_notification_message( -dbc => $system->{dbc}, -message => $message, -subject => 'Volume Warning / Errors' );    ## , -url=>$url, -link=>$link,
    }
}


##########################
#### Directory Sizes #####
##########################

$Report->completed();
$Report->DESTROY();

exit;
##############################
### END OF LOGIC
##############################

#
# Given a system object and a host, this method monitors disk usage on all primary paths used by alDente
# It also searches for soft links to retrieve disk usage for remotely accessed directories
#
#
############################
sub monitor_df_usage {
############################
    my %args	= filter_input( \@_ );
    my $host	= $args{-host};
    my $system	= $args{-system};

    my $link = "Solexa Run Data Storage Page";
    my $url  = "http://lims02.bcgsc.ca/SDB/cgi-bin/barcode.pl?User=Auto&Generate+Results=1&File=/opt/alDente/www/dynamic/cache//Group/11/general/SLX+-+Runs+Ready+for+Image+Deletion+and+Storage.yml";

    my %Volumes;

 		### if no threshold or warning or error percent given ..it uses the below ones###
 		unless ($threshold ) 		{ $threshold = '50G' } 
        unless ($warning_percent)	{ $warning_percent = '95'}
        unless ($error_percent)		{ $error_percent = '98'} 
        ###
        my $my_threshold = $threshold;
        my $my_warning_percent = $warning_percent;
        my $my_error_percent = $error_percent;
        my $df_command;
      	$count = 0; 
      my $index = -1; 
        if ($conf->{SHOW_DIR})	{ 
    foreach my $path (@custom_dirs ) {
		$index++;
			if ($custom_servers[$index] && ($custom_servers[$index] ne 'default'))	{
				if ($custom_servers[$index] !~ /$host/ ) {next;}			
					}
        	if($custom_space[$index] && $custom_space[$index] ne 'n/a')		 {	$my_threshold = $custom_space[$index]; }
		else {	$my_threshold = $threshold;}
        	if($custom_warnings[$index] && $custom_warnings[$index]	ne 'n/a'){$my_warning_percent = $custom_warnings[$index];}
		else {	$my_warning_percent = $warning_percent;}
        	if($custom_errors[$index] && $custom_errors[$index]	ne 'n/a')	{$my_error_percent = $custom_errors[$index];}
		else {	$my_error_percent = $error_percent;}
        			$df_command = $custom_df[$index];
if ($df_command ) {$count++;}
$path =~ /^(\W+)\w/;
if ($1 ne "/") { $path = "/".$path; }
        #####################################
        my ($df_usage) = $system->check_disk_usage( -df_command => $df_command, -path => $path, -host => $host, -log => $log);    ## retrieve df output
		my ( $msg, $warning, $error, $detail ) = $system->log_df_usage( -df_command => $df_command, -df_usage => $df_usage, -path => $path, -host => $host, -avail_threshold => $my_threshold, -warning_percent => $my_warning_percent, -error_percent => $my_error_percent, -log => $log);
         $Report->parse_message_warning_error( $msg, $warning, $error, $detail, -of_sys_monitor => "sys_monitor" );

        if ( @$warning || @$error ) {
      
        	foreach my $war (@$warning)	{
        	$message .= qq(<p> <span style="background-color:#000; color:#ffff00;">WARNING:</span> ) ;
			$message .= $war;
			$message .= "</p>";
				}
				foreach my $err (@$error)	{
				$message .= '<p> <span style="background-color:#000000; color:#ff0000;">ERROR:</span> ' ;
			$message .= $err;
			$message .= "</p>";
				}
        }
     }   
 }    
     print $blue;
 $Report->set_Message("CHECKED: $count directories for 'df' usage on host[$host]");
 	print $default_color;
    return;
}

############################
sub monitor_du_usage {
############################
    my %args	= filter_input( \@_ );
    my $host	= $args{-host};
    my $system	= $args{-system};
    my $du_command;
      	$count = 0; 
      my $index = -1; 
        if ($conf->{SHOW_DIR})	{ 
    foreach my $path (@custom_dirs ) {
		$index++;
			if ($custom_servers[$index] && ($custom_servers[$index] ne 'default'))	{
				if ($custom_servers[$index] !~ /$host/ ) {next;}			
					}
        			$du_command = $custom_du[$index]; 
if ($du_command ) {$count++;}
$path =~ /^(\W+)\w/;
if ($1 ne "/") { $path = "/".$path; }
        	 my ($du_usage) = $system->check_du( -du_command => $du_command, -path => $path, -host => $host, -log => $log);    		## retrieve du output
		my ($msg, $warning, $error, $detail ) = $system->log_du_usage( -du_command => $du_command, -du_usage => $du_usage, -path => $path, -host => $host, -log => $log, -du_warning=>$du_warning[$index] );   
       $Report->parse_message_warning_error( $msg, $warning, $error, $detail, -of_sys_monitor => "sys_monitor" );

        if ( @$warning || @$error ) {
      
        	foreach my $war (@$warning)	{
        	$message .= qq(<p> <span style="background-color:#000; color:#ffff00;">WARNING:</span> ) ;
			$message .= $war;
			$message .= "</p>";
				}
				foreach my $err (@$error)	{
				$message .= '<p> <span style="background-color:#000000; color:#ff0000;">ERROR:</span> ' ;
			$message .= $err;
			$message .= "</p>";
				}
        }
     }   
 }    
    print $blue;
 $Report->set_Message("CHECKED: $count directories for 'du' usage on host[$host]");
 	print $default_color;
    return;
}

      
#####################################
sub monitor_directory_usage {
#####################################
    my $system = shift;
    my $host   = shift;

    my %directories = %{ $system->get_watched_directories( -scope => $host ) };
    my @watched = sort keys %directories;

    Message("Watched $host directories:");
    foreach my $watch (@watched) {
        Message("$watch");
    }

    my $min_size = '100M';    ## minimum size at which directory usage is logged ##

    foreach my $directory (@watched) {

        my $usage = $system->check_directory_usage( -host => $host, -directory => $directory, -max_depth => 3, -log => $log, -threshold => $min_size );

        if ( $directory =~ /\*/ ) {
            my @follow = _get_soft_links( $directory, $host, -maxdepth => 0 );    ## monitor softlinks within N layers of watched directories ? ## 2 levels generates too many soft links (run links)
            foreach my $follow_dir (@follow) { Message(" * found link under $directory :  $follow_dir") }
        }

        #	$system->clear_Usage(-threshold=>0.001);
        my ( $msg, $warning, $error, $detail ) = $system->log_directory_usage( -host => $host, -threshold => $log_threshold );
        $Report->parse_message_warning_error( $msg, $warning, $error, $detail, -of_sys_monitor => "sys_monitor" );
    }
    return;
    ## may also wish to generate warning message if more softlinks exist outside of expected directories ##
}

##############################
### Internal Functions
##############################

#####################################
sub send_notification_message {
#####################################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $url        = $args{-url};
    my $link       = $args{ -link };
    my $email_body = $args{-message};
    my $subject    = $args{-subject};

    if ($url) { $email_body .= "\n\n" . Link_To( $url, $link ) }

    my $ok = alDente::Subscription::send_notification(
        -dbc          => $dbc,
        -name         => 'System Monitor',
        -from         => 'System Monitor<aldente@bcgsc.bc.ca>',
        -subject      => "$subject",
        -body         => "$email_body",
        -content_type => 'html',
        -testing      => !$log
    );
    return;
}

#
# Generate context specific list of directories to look at when monitoring disk volume usage
#
# This should include standard accessed directories + specifically identified archive volume directories
#
# Return: array of directories to monitor
################################
sub _disk_usage_directories {
################################
    my %args   = filter_input( \@_ );
    my $system = $args{ -system };
    my $host   = $args{-host};
    my $depth  = $args{-depth};

    my @check_dirs;
   
    ## Generate list of all directories aliased in Configs hash + soft links found below these directories ##
    foreach my $primary ( keys %{$configs} ) {
        if ( $primary !~ /\_dir$/ ) {next}
       unless(!$debug){ $dbc->message("*** $primary -> $configs->{$primary} ***");}
        
        push @check_dirs, $configs->{$primary};

        my @more_soft_links = _get_soft_links( $configs->{$primary}, $host, -maxdepth => $depth );    ## go two deep in standard config directories to find volumes of interest ##
        if ( @more_soft_links && $more_soft_links[0] ) {
            push @check_dirs, @more_soft_links;
         unless(!$debug) {$dbc->message( " + " . int(@more_soft_links) . " $primary soft link(s)" );}
        }
    }

    ## also retrieve archive directories (4 deep from archive directory) ##
    my @archive_dirs = _get_soft_links( "$configs->{archive_dir}/", $host, 4 );                       ## go 4 deep in archive directory to find Data -> soft links (need to add / suffix to follow softlinks past archive soft link)

    my @unique_dirs = @{ RGTools::RGIO::unique_items( \@check_dirs ) };
    return ( @unique_dirs, @archive_dirs );
}

########################
sub _get_soft_links {
########################
    my %args  = filter_input( \@_, -args => 'dir,host,maxdepth' );
    my $dir   = $args{-dir};
    my $host  = $args{-host};
    my $depth = $args{-maxdepth};

    my $maxdepth;
    if ( defined $depth ) { $maxdepth = "-maxdepth $depth" }

    my @link_dirs;
    foreach my $dir ($dir) {
        my $command;
        if ( !$system->visible_host($host) ) { $command .= "ssh -n $host " }
        $command .= "find  $dir -type l -mindepth 0 $maxdepth";    ## no / suffix on directory or all run_maps will be retrieved....
        @link_dirs = split "\n", try_system_command($command);
        if ( $link_dirs[0] =~ /No such file|Permission Denied/ ) {
            Message("$yellow_on_black Warning:$default_color $link_dirs[0]");
            @link_dirs = ();
        }
    }

    return @link_dirs;
}

#############################
sub _create_stat_dirs {
#############################
    my %args      = filter_input( \@_ );
    my $hosts_ref = $args{-hosts};
    my @hosts     = @$hosts_ref if $hosts_ref;
    my $main_dir  = $configs->{Sys_monitor_dir};
    my @date      = split '-', &today();
    my $date_root = join '/', @date;

    for my $host (@hosts) {
        my $dir = $main_dir . '/' . $host . '/' . $date_root;
        print "Create $dir...\n";   
        mkpath($dir);
    }
}

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

##############################

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
