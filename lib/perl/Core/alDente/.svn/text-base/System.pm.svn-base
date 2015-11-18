###################################################################################################################################
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package alDente::System;

use strict;
use File::Path;
use Data::Dumper;
use FindBin;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Directory;
use RGTools::Conversion;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::Installation;

## alDente modules

use alDente::Subscription;

use vars qw( %Configs );

#####################
my @sent_emails;
my @checked_location;
my $yellow_on_black = "\033[1m\033[33m\033[40m";
my $red_on_black    = "\033[1m\033[31m\033[40m";
my $default_color   = "\033[0m";
##########################################################
##      Constructor
##########################################################
#############################
sub new {
#############################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my @unique_filesystem;
    my $self = {};
    $self->{dbc} = $dbc;

    #$self->{Warning_Percent} = 90;
    #$self->{Error_Percent}   = 98;
    $self->{index}             = 0;
    $self->{unique_filesystem} = \@unique_filesystem;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    my $file = $Configs{web_dir} . '/../conf/vol_size.conf';    ## xml file storing directories to explicitly watch ##
    $self->{vol_size_file} = $file;
    $self->load();

    return $self;
}

##########################################################
##      DATA
##########################################################

##########################################################
##      MAIN METHODS
##########################################################
###############################
sub load {
###############################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'custom' );

    my $custom_installation = $args{-custom};

    my $configs = SDB::Installation::load_custom_config($custom_installation);

    my $custom  = $custom_installation || $Configs{custom};
    my $host    = $configs->{DEV_HOST}{value};
    my $version = $configs->{CODE_VERSION}{value};
    $version =~ s/\./\_/;

    $self->{COMPARE_DEV_DATABASE}  = $custom . '_beta';
    $self->{COMPARE_TEST_DATABASE} = $custom;
    $self->{CORE_DATABASE}         = 'Core';
    $self->{RELEASE_CORE_DATABASE} = 'Core' . '_' . $version;
    $self->{COMPARE_DEV_HOST}      = $host;
    $self->{COMPARE_TEST_HOST}     = $host;
    $self->{CORE_HOST}             = $host;
    $self->{RELEASE_CORE_HOST}     = $host;

    return;
}

###############################
sub get_all_databases {
###############################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $qualified = $args{-qualified};

    #    my $host = $args{-host}; 						NOT IMPLEMENTED YET
    #    my $active_only = $args{-active_only};			NOT IMPLEMENTED YET

    my @result;
    for my $entry ( keys %Configs ) {
        if ( $entry =~ /^(.+)_DATABASE/ ) {
            if ($qualified) {
                if ( $Configs{ $1 . '_HOST' } ) {
                    push @result, $Configs{ $1 . '_HOST' } . '.' . $Configs{ $1 . '_DATABASE' };
                }
            }
            else {
                Message $1;
                push @result, $Configs{ $1 . '_DATABASE' };
            }
        }
    }
    return @result;

}
###############################
sub check_directory_usage {
###############################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $host      = $args{-host};
    my $dir       = $args{-directory};
    my $threshold = $args{-threshold} || 0;    ## only keep track of directories over this size threshold (in G)
    my $max_depth = $args{-max_depth} || 3;
    my $force     = $args{-force};             ## regenerate usage even if already stored (useful for soft links)
    my $log       = $args{ -log };             ## log to dated scope directory ##
    my $debug     = $args{-debug} || 1;

    my $threshold_num = RGTools::Conversion::get_number($threshold);    ## enables conversion from '1.5G' (for example) ##

    $dir =~ s/\/\*$//;
    $host = $self->find_locality( -host => $host, -directory => $dir );
    if ( !$host ) {return}                                              ## not found ##

    if ( $self->{directory_usage}{$host}{$dir} && !$force ) {
        return $self->{directory_usage}{$host}{$dir};
    }

    my $command;
    if ( !-e $dir ) { Message("Directory: $dir does not exist (on $host)"); return; }

    if   ( ( $host eq 'shared' ) || !$host ) { $command = "du -k --exclude=\".snapshot\" --max-depth=$max_depth '$dir'" . '/' }
    else                                     { $command = "ssh -n $host du -k --exclude=\".snapshot\" --max-depth=$max_depth '$dir'" . '/' }

    if ($debug) { Message("-- Checking $max_depth levels from $host directory: '$dir' for space usage -- ") }
    my @output = split "\n", try_system_command($command);

    ## Store output per directory as system attributes ##
    foreach my $line (@output) {
        if ( $line =~ /Permission denied$/i ) { Message("Warning: $line"); next; }

        if ( $line =~ /\b([\d\.]+\w?)\t(.+)$/ ) {
            ## Note the regexp above allows for STDOUT randomly spliced non-cleanly into STDERR (or vice versa) ## (useful when permission errors arise for some subdirectories)
            my $size = $1;

            my $sub_dir = $2;
            $sub_dir =~ s/\/$//;    ## truncate directory / character

            my $scope = $self->find_locality( -host => $host, -directory => $sub_dir );    ## enables locality to be determined even if this is a soft link to a shared volume ... ##

            if ( $log && $scope ) { $self->log_dated_file( -path => "$Configs{Sys_monitor_dir}/$scope/dirs/", -file => 'size.stats', -header => "Dir\tSize(K)", -append => "$sub_dir\t$size" ) }

            if ( $self->{directory_usage}{$scope}{$sub_dir} ) {
                if   ( $size > $self->{directory_usage}{$scope}{$sub_dir} ) { Message "Overwriting Size information for $scope : $sub_dir (larger than before)" }
                else                                                        { Message "Ignoring duplicate size information for $scope : $sub_dir" }
            }
            elsif ( $size * 1000 > $threshold_num ) {
                Message("$scope ($host : $sub_dir) Size: $size K (> $threshold)");
                $self->{directory_usage}{$scope}{$sub_dir} = $size;
            }
        }
        else { Message("** Unrecognized: $line") }
    }
    return \@output;
}

##############################
sub log_directory_usage {
##############################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $host      = $args{-host};
    my $threshold = $args{-threshold};

    $threshold = RGTools::Conversion::get_number($threshold);    ## enables conversion from '1.5G' (for example) ##
    my ( @msg, @warning, @error, @details );

    my @directories = keys %{ $self->{directory_usage}{$host} };

    foreach my $sub_dir ( sort @directories ) {
        if ( $sub_dir =~ /Permission denied/i ) { push @warning, $sub_dir; next; }
        my $size = $self->{directory_usage}{$host}{$sub_dir};
        if ( $size * 1000 < $threshold ) {next}

        my $w_size = $self->get_directory_limit( -host => $host, -dir => $sub_dir, -type => 'warning' );
        my $e_size = $self->get_directory_limit( -host => $host, -dir => $sub_dir, -type => 'error' );

        my $error_size   = RGTools::Conversion::get_number($e_size);
        my $warning_size = RGTools::Conversion::get_number($w_size);

        #	$self->write_to_Stat_file_OLD( -size => $size, -dir => $sub_dir, -host => $host );

        ## This means the current directory id a custom directory
        my $file = $self->get_stat_file( -host => $host, -dir => $sub_dir );

        #	Message("LOG -> $file");

        if ( !-e $file ) { append_file( -append => "Date\tSize(k)", -file => $file ) }
        &append_file( -append => $size, -file => $file, -datestamp => 1 );

        if ( $size * 1000 > $error_size ) {
            push @warning, "$host $sub_dir is larger than max size of '$error_size'" . " (Size: $size K)";
        }
        elsif ( $size * 1000 > $warning_size ) {
            push @warning, "$host $sub_dir is larger than warning size of '$warning_size'" . " (Size: $size K)";
        }
        else {
            push @msg, "$host $sub_dir size ($size K) is OK";
        }
    }

    return ( \@msg, \@warning, \@error, \@details );
}

####################
#
# Clears usage for given conditions.
#
# -directory => $dir - to clear usage for given directory (useful if regenerating usage for soft links)
# -threshold => $threshold - to clear trivial size records below a certain threshold
#
####################
sub clear_Usage {
####################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $host      = $args{-host};
    my $directory = $args{-directory};
    my $threshold = $args{-threshold} || 0;

    my $threshold_num = RGTools::Conversion::get_number($threshold);    ## enables conversion from '1.5G' (for example) ##

    my @hosts;
    if   ($host) { @hosts = ($host) }
    else         { @hosts = keys %{ $self->{directory_usage} } }

    Message("Clearing usage for @hosts ($directory > $threshold )");
    foreach my $thisHost (@hosts) {
        my @dirs;
        if   ($directory) { @dirs = ($directory) }
        else              { @dirs = keys %{ $self->{directory_usage}{$thisHost} } }
        foreach my $dir (@dirs) {
            my $size = $self->{directory_usage}{$thisHost}{$dir};
            if ( $size * 1000 < $threshold_num ) {
                delete( $self->{directory_usage}{$thisHost}{$dir} );
            }

        }
    }
    return;
}

##############################
sub get_directory_usage {
##############################
    my $self      = shift;
    my $threshold = shift;

    $threshold = RGTools::Conversion::get_number($threshold);    ## enables conversion from '1.5G' (for example) ##

    my @used;
    my @hosts = keys %{ $self->{directory_usage} };
    foreach my $host (@hosts) {
        my @dirs = keys %{ $self->{directory_usage}{$host} };
        foreach my $dir (@dirs) {
            my $size = $self->{directory_usage}{$host}{$dir};
            if ( $size * 1000 > $threshold ) {
                push @used, "$host\t$dir\t$size";
            }
        }
    }
    return @used;
}

#
# Simple wrapper to retrieve disk usage information for system monitoring
#
# This method also stores the usage as a system attribute with the key being the volume and the value being the df result
#
##########################
sub check_disk_usage {
##########################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $host       = $args{-host};
    my $path       = $args{-path};
    my $threshold  = $args{-size_threshold} || 0;
    my $log        = $args{ -log };
    my $df_command = $args{-df_command};
    if ( !$df_command || $df_command eq 'none' ) { return ( ["none"] ); }
    my $scope = $self->find_locality( -host => $host, -volume => $path );
    if ( $path && $self->{disk_usage}{$scope}{$path} ) { Message("already have $path usage..."); return $self->{disk_usage}{$scope}{$path}; }

    if ($path) { $path = "\"$path\"" }    ## DO NOT do this for NULL path ##
    my $command;

    $command = "$df_command $path";
    if ( $host && ( $host ne $self->local_host ) ) { $command = "ssh -n $host $command" }

    my $fback = try_system_command( -command => $command );

    my @output = split "\n", $fback;

    my $header = $output[0];
    ## store as system attribute ##
    my $put_in_filesystem;
    foreach my $line ( 1 .. $#output ) {
        $put_in_filesystem = 1;
        $output[$line] =~ s/\s+/\t/g;
        $output[$line] =~ /^(\S+)/;
        my $volume = $1;
        $output[$line] =~ m/([\/\w]+)$/;
        $volume .= $1;
        foreach my $filesystem ( @{ $self->{unique_filesystem} } ) {
            if ( $filesystem eq $volume . " $host" ) {
                $output[$line] = 'ignored';
                $put_in_filesystem = 0;
                last;
            }

        }
        if ( $put_in_filesystem eq 1 ) {
            my @arr   = @{ $self->{unique_filesystem} };
            my $index = $self->{index};
            $arr[$index] = $volume . " $host";
            $index++;
            $self->{index}             = $index;
            $self->{unique_filesystem} = \@arr;
        }

        if ( $header !~ /No such file or directory/ && $header !~ /Permission denied/ && $output[$line] ne 'ignored' ) {
            $scope = $self->find_locality( -host => $host, -volume => $volume );

            if ( $log && $scope ) { $self->log_dated_file( -path => "$Configs{Sys_monitor_dir}/$scope/vols/", -header => $header, -file => 'size.stats', -append => $output[$line] ) }

            if   ( $self->{disk_usage}{$scope}{$volume} ) { next; }
            else                                          { $self->{disk_usage}{$scope}{$volume} = $output[$line]; }
        }
    }
    return ( \@output );
}

#
# Simple wrapper to retrieve du information for system monitoring
#
# This method also stores the usage as a system attribute with the key being the volume and the value being the du result
#
##########################
sub check_du {
##########################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $host       = $args{-host};
    my $path       = $args{-path};
    my $threshold  = $args{-size_threshold} || 0;
    my $log        = $args{ -log };
    my $du_command = $args{-du_command};

    if ( !$du_command || $du_command eq 'none' ) { return ( ["none"] ); }

    if ($path) { $path = "\"$path\"" }    ## DO NOT do this for NULL path ##
    my $command;

    $command = "$du_command $path";
    if ( $host && ( $host ne $self->local_host ) ) { $command = "ssh -n $host $command" }

    my $fback = try_system_command( -command => $command );

    my @output = split "\n", $fback;
    my $size = @output;
    my $volume;
    foreach my $out (@output) {
        if ( $out =~ /total/ ) {
            $out =~ /^(\S+)/;
            $volume = $1;
        }
    }
    my $header = $output[0];

    if ( $header =~ /No such file or directory/ ) {
        return ( \@output );
    }
    else {
        my $scope = $self->find_locality( -host => "shared", -directory => $path );

        if ( $header =~ /Permission denied/ && $volume ne 0 ) {
            my $exclude = $size - 2;
            if ( $log && $scope ) { $self->log_dated_file( -path => "$Configs{Sys_monitor_dir}/$scope/dirs/", -file => 'size.stats', -header => "Size\tHost\tDir", -append => "$volume\t$host\t$path (excluding $exclude directories)" ) }
        }
        else {
            if ( $log && $scope ) { $self->log_dated_file( -path => "$Configs{Sys_monitor_dir}/$scope/dirs/", -file => 'size.stats', -header => "Size\tDir", -append => "$volume\t$path" ) }
        }
        if   ( $self->{directory_usage}{$scope}{$path} ) { }
        else                                             { $self->{directory_usage}{$scope}{$path} = $volume; }
    }
    return ( \@output );
}

#
# This logs the disk usage to the standard file (using get_stat_file)
#
# Note: while check_disk_usage is run for a given host, it will save shared hosts under the 'shared' key
#  ... so you should run this not only for all explicitly indicated hosts, but also the 'shared' hosts following check_disk_usage calls
#
# Option: -threshold => $threshold to generate threshold specific warnings or error messages as desired.
#
# Return: Array of msg, warnings, errors, details
###########################
sub log_df_usage {
##########################
    my $self            = shift;
    my %args            = filter_input( \@_, -args => 'df_usage,host' );
    my $df_usage        = $args{-df_usage};
    my $path            = $args{-path};
    my $host            = $args{-host};
    my $threshold       = $args{-avail_threshold};                         ## note this is a MINIMUM threshold of available space (as opposed to an upper size limit)
    my $warning_percent = $args{-warning_percent};
    my $error_percent   = $args{-error_percent};
    my $log             = $args{ -log };
    my $df_command      = $args{-df_command};
    my @df              = @$df_usage;
    my ( @normal_msg, @warning_msg, @error_msg, @details );
    my $do = 1;
    my $fix;
    my $msg;

    if ( @df && $df[0] ne 'none' ) {
        $threshold = RGTools::Conversion::get_number($threshold);          ## enables conversion from '1.5G' (for example) ##
        my $headers = shift @$df_usage;                                    ## first line of usage is the df header ...
        if ( $headers =~ /No such file or directory/ || $headers =~ /Permission denied/ ) {
            $headers .= " [$host]";
            push @warning_msg, $headers;
            $do = 0;
        }
        if ( $do eq 1 ) {
            foreach my $usage (@$df_usage) {
                if ( $usage eq 'ignored' ) {next}

                $usage =~ s/\s+/\t/g;
                ## When Path is specified in original df call, this should only go through this loop once ##
                my @cols = split /\s+/, $usage;
                my $line = join "\t", @cols;    # also replaces multiple spaces with tab delimiter

                if ( int(@cols) < 5 && $usage && $do eq 1 ) { $msg = "Unrecognized df output: $usage \nPath: $path \nHost: $host"; $do = 0; $fix = $cols[0]; next; }
                if ( int(@cols) eq 5 && $usage && $do eq 0 ) { unshift( @cols, $fix ); $do = 1; }
                if ( $do eq 0 ) { push @warning_msg, $msg; $do = 1; next; }
                my $volume = $cols[0];

                ## store disk usage for system object ##
                my $scope = $self->find_locality( -volume => $volume, -host => $host );

                ## write disk usage to log file ##
                my $stat_file = $self->get_stat_file( -host => $scope, -volume => $volume );

                #	Message("LOG $scope $volume : $line -> $stat_file");
                if ( $log && $line ne 'ignored' ) {
                    if ( !-e $stat_file ) { append_file( -append => $headers, -file => $stat_file ) }
                    ## <TEMPORARY FIX> ##
                    my @headers = split "\n", `head -2 $stat_file`;

                    if ( $headers[0] !~ /Filesystem/ || $headers[1] =~ /Filesystem/ || $headers[1] =~ /\d[GT]\s/ ) {
                        ## current file does not have a header... or has multiple headers from an earlier bug...or used human readable units (not directly graphable)
                        Message("REGENERATE $stat_file ($volume FROM @cols)");
                        _fix_stat_file( $stat_file, [ 'Filesystem', '1-Kblocks', 'Used', 'Available', 'Use%', 'Mounted_on' ], $line );
                    }
                    #####################
                    &append_file( -append => $line, -file => $stat_file, -datestamp => 1 );
                }

                ## Generate warnings if applicable ##
                my ( $disk, $size, $used, $avail, $used_percent, $mount ) = @cols;
                my $avail_disk;
                if ( $df_command =~ m/-h/ ) {
                    $avail_disk = RGTools::Conversion::get_number($avail);
                    if ( $used_percent =~ /(\d+)\s*%/ ) { $used_percent = $1 }
                    $msg = "$path (mounted on: $mount) (Filesystem: $disk) $used_percent% Used ($avail available) [$host]";
                }
                else {
                    $avail_disk = $avail * 1000;
                    if ( $used_percent =~ /(\d+)\s*%/ ) { $used_percent = $1 }
                    $msg = "$path (mounted on: $mount) (Filesystem: $disk) $used_percent% Used ($avail K available) [$host]";
                }
                my $space_warning = $avail_disk < $threshold;

                if    ( $used_percent > $error_percent   && $space_warning ) { push @error_msg,   $msg }
                elsif ( $used_percent > $warning_percent && $space_warning ) { push @warning_msg, $msg; }
                else                                                         { push @normal_msg,  $msg }
            }
        }
    }
    return ( \@normal_msg, \@warning_msg, \@error_msg, \@details );
}

###########################
sub log_du_usage {
##########################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $path       = $args{-path};
    my $host       = $args{-host};
    my $log        = $args{ -log };
    my $du_usage   = $args{-du_usage};
    my $du_warning = $args{-du_warning};
    my @du         = @$du_usage;
    my $du_command = $args{-du_command};
    my ( @normal_msg, @warning_msg, @error_msg, @details );
    my $do = 1;

    if ( @du && $du[0] ne 'none' ) {
        my $size    = @$du_usage;
        my $line    = $size - 1;
        my $headers = $du[0];
        my $msg;
        my $volume = 0;
        foreach my $out (@du) {
            if ( $out =~ /total/ ) {
                $out =~ /^(\S+)/;
                $volume = $1;
            }
        }
        if ( $headers =~ /No such file or directory/ || $headers =~ /Permission denied/ ) {
            $headers .= " [$host]";
            push @warning_msg, $headers;
            if ( $volume ne 0 ) {
                $headers =~ m/\`([\/\w]+)\'/;
                my $variable = $1;
                if ( !$du_warning ) {
                    $msg = "$path (excluding: $variable) = $volume (Total disk usage) [$host]";
                    push @normal_msg, $msg;
                }
                else {
                    my $du_warn = RGTools::Conversion::get_number($du_warning);
                    my $vol     = RGTools::Conversion::get_number($volume);
                    if ( $vol > $du_warn ) {
                        $msg = "$path (excluding: $variable) = $volume (Total disk usage) exceeded $du_warning [$host]";
                        push @warning_msg, $msg;
                    }
                    else {
                        $msg = "$path (excluding: $variable) = $volume (Total disk usage) [$host]";
                        push @normal_msg, $msg;
                    }
                }
            }
            $do = 0;
        }
        if ( $do eq 1 ) {
            if ( !$du_warning ) {
                $msg = "$path = $volume (Total disk usage) [$host]";
                push @normal_msg, $msg;
            }
            else {
                my $du_warn = RGTools::Conversion::get_number($du_warning);
                my $vol     = RGTools::Conversion::get_number($volume);
                if ( $vol > $du_warn ) {
                    $msg = "$path = $volume (Total disk usage) exceeded $du_warning [$host]";
                    push @warning_msg, $msg;
                }
                else {
                    $msg = "$path = $volume (Total disk usage) [$host]";
                    push @normal_msg, $msg;
                }
            }
        }
    }
    return ( \@normal_msg, \@warning_msg, \@error_msg, \@details );
}

#######################
sub log_dated_file {
#######################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $path   = $args{-path};
    my $name   = $args{-file};
    my $header = $args{-header};
    my $append = $args{-append};
    my $mode   = $args{-mode} || '774';

    ## log all du output in dated directories ## Replaces old Write_to_stat_file_OLD ##
    my $date_dir = create_dir( $path, convert_date( &date_time(), 'YYYY/MM/DD' ), $mode );    ## create subdirectories for date ##

    #    $self->{dbc}->message("Log to $date_dir: $append"); #

    if ( !-e "$date_dir/size.stats" ) { append_file( -append => $header, -file => "$date_dir/size.stats" ) }
    append_file( -append => $append, -file => "$date_dir/size.stats", -mode => $mode );

    # $self->{dbc}->message("LOG to $date_dir/size.stats");

    return;
}

#############################
# Description:
#       Attaches today's info to end of stat file (WRITE)
# Output:
#       NO Output
# Input:
#       - append : text that  will be added to file alongside date
#       - datestamp
##############################
sub append_file {
##############################
    my %args      = filter_input( \@_ );
    my $append    = $args{-append};
    my $file      = $args{-file};
    my $datestamp = $args{-datestamp};
    my $force     = $args{-force};
    my $mode      = $args{-mode} || '774';
    my $grp       = $args{-grp} || 'lims';

    my $file_date;

    my $append_line;
    if ( ref $append eq 'ARRAY' ) { $append_line = join "\t", @$append }    ## allow passing in of array of values making up row
    else                          { $append_line = $append }

    if ($datestamp) {
        my $date         = today();
        my $read_command = "tail -n 1 $file ";
        my $response     = try_system_command($read_command);
        if ( $response =~ /^(\S+)\s/ ) { $file_date = $1 }

        if ( $file_date eq $date ) {

            # skippping (maybe should replace instead)
            return;
        }
        $append_line = $date . "\t$append_line";
    }
    my ($first_column) = split "\t", $append_line;

    if ( !$force && -e $file ) {
        my $repeat = `grep '^$first_column' $file`;

        if ( $repeat =~ /$first_column\t/ ) { return; }    ## do not repeat first column (normally unique) unless specifically requested
    }

    my $command  = "echo '$append_line' >> $file ";
    my $response = try_system_command($command);

    if ($mode) { $response .= `chmod $mode $file` }
    if ($grp)  { $response .= `chgrp $grp $file` }

    return $response;
}

#
# Temporary to fix headers (and column separators) for existing log files.
#
#
#######################
sub _fix_stat_file {
#######################
    my $stat_file = shift;
    my $headers   = shift;
    my $factor    = shift;    ## arbitrary multiplication factor for unitless numbers (converts '125' to '125000' for example) ##
    my $abort     = shift;

    my @current = split "\n", `cat $stat_file`;

    my $temp_file = $Configs{Sys_monitor_dir} . '/tmp.txt';
    `rm -f $temp_file`;

    my $header;
    if ( ref $headers eq 'ARRAY' ) {
        $header = join "\t", @$headers;
    }
    else {
        $headers =~ s/\s+/\t/g;
        $header = $headers;
    }

    open my $TEMP, '>', $temp_file or die "CANNOT OPEN $temp_file";
    append_file( -append => "Date\t$header", -file => $temp_file );

    foreach my $current_line (@current) {
        if ( $abort && ( $current_line =~ /$abort/ ) ) { Message("Abort ($current_line found containing $abort)"); return; }    ## abort
        if ( $current_line =~ /^Date/ ) {next}                                                                                  ## header already in existing file... ###
        my @cols = split /\s+/, $current_line;
        foreach my $col (@cols) {
            if ( $col =~ /^[\d\.]+[GTM]$/ ) { $col = RGTools::Conversion::get_number($col) / 1000 }
            elsif ( $col =~ /\d\d\d\d\-\d\d\-\d\d/ ) { }                                                                        ## date ... ignore ..
            elsif ( $factor && ( $col =~ /^[\d\.e-]+$/ ) ) {
                $col *= $factor;
                if ( $col > 10 ) { $col = int($col) }
            }
        }
        my $new_line = join "\t", @cols;

        append_file( -append => $new_line, -file => $temp_file );
    }
    close $TEMP;

    my $problem = `cp '$temp_file' '$stat_file'`;

    if ($problem) { Message("Problem: $problem") }
    `rm -f $temp_file`;

    return;
}

#############################
# Description:
#    checks to see if host is active
# Output:
#    1 on success 0 on failure
#############################
sub ping_server {
#############################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $host   = $args{-host};
    my $result = try_system_command("ssh -n $host hostname");

    my @output = split '\n', $result;

    if   ( $output[0] =~ /^$host/ ) { return 1 }
    else                            { return 0 }
}

#
# Retrieve Hub information from Database
#######################
sub get_hubs_info {
#######################
    #  <UNDER CONSTRUCTION>
    return;
}

#############################
# Description:
#       gets all printers info
# Output:
#
#############################
sub get_printers_info {
#############################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my %printers = $dbc->Table_retrieve( 'Printer', [qw(Printer_ID Printer_Name Printer_Location Printer_Type)], "WHERE Printer_Output <> 'Off'" );
    my $i        = 0;
    my %Printers;

    while ( defined $printers{Printer_ID}[$i] ) {
        my $id       = $printers{Printer_ID}[$i];
        my $name     = $printers{Printer_Name}[$i];
        my $location = $printers{Printer_Location}[$i];
        my $type     = $printers{Printer_Type}[$i];
        $Printers{$id}{IP}       = $name;
        $Printers{$id}{location} = "$location [$type]";
        $i++;
    }
    return %Printers;
}

#############################
# check printer connectivity
#############################
sub ping_printers {
#############################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $host     = $args{-host};
    my $printers = $args{-printers};
    my %Printers = %$printers if $printers;
    my @printers = sort keys %Printers;

    my ( @success, @warnings, @errors, @details );

    my $print_test_str = "checking lpstat for printers:\n";
    map { $print_test_str .= "$_ : $Printers{$_}{IP} in $Printers{$_}{location}\n"; } @printers;

    $print_test_str .= "\n\n";
    push @details, $print_test_str;

    my $tested = 0;
    foreach my $printer (@printers) {
        my $printer_name = $Printers{$printer}{IP};
        my $check        = try_system_command("ssh -n $host lpstat -v $printer_name");
        $print_test_str .= $check;
        if ( $check =~ /disabled/ ) {
            push @errors, "$printer_name ($Printers{$printer}{location} disabled for $host";
        }
        elsif ( $check =~ /unknown/i ) {
            push @errors, "$printer_name ($Printers{$printer}{location} unknown for $host";
        }
        else {
            push @success, "$printer_name:,$Printers{$printer}{location},OK,$host";

            #print Dumper @success;
        }
        $tested++;
    }

    push @details, "tested $tested printers";

    return ( \@success, \@warnings, \@errors, \@details );
}

#################
sub ping_hub {
#################
    my $self = shift;
    my %args = filter_input( \@_, -mandatory => 'ip' );

    my $host     = $args{-host};
    my $ip       = $args{-ip};
    my $location = $args{-location};
    my $host     = $args{-host};

    my $PING_COUNT = 2;

    my $hub_str = "Pinging $ip ($location)";
    if ($host) { $hub_str .= " from $host." }

    my $ping;
    if ($host) { $ping .= "ssh -n $host " }
    $ping .= "ping -c $PING_COUNT $ip";

    my $fback = try_system_command($ping);

    my @msg = ($hub_str);
    my @detail = ( $ping, $fback );

    my ( @warnings, @errors );
    foreach my $line ( split /\n/, $fback ) {
        if ( $line =~ /Destination Host Unreachable/ ) {
            push @errors, "$ip ($location) Host Unreachable";
            last;
        }
        elsif ( $line =~ /unknown host/ ) {
            push @errors, "Unknown Host: $ip ($location)";
            last;
        }
        elsif ( $line =~ /,\s+(\d+)%\s+packet loss/ ) {
            my $loss = $1;
            if ( $loss == 0 ) {
                @msg = ( $hub_str, 'ok... (0% loss)' );
            }
            else {
                push @warnings, "$loss % packet loss to $ip ($location)";
            }
        }
        else {
            ## OK On this pass
        }
    }

    return ( \@msg, \@warnings, \@errors, \@detail );

}

##########################################################
##      Secondary METHODS
##########################################################

# Description:
#       Given a volume its history is returned
#
# (This method differs from get_stat_file_history in that it retrieves the information from the dated files using grep)
# - This enables retrieval of history for volumes which may not have been previously 'watched', but have been logged with the full du output.
#
# Input:
#       -volume:    volume name
#       -host:      host name
# Output:
#       Hash of arrays
#       each key of hash is for certain info (eg: percentage used)
#       each array contains values corresponding to the key
#####################################
sub retrieve_stat_file_history {
#####################################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $volume    = $args{-volume};
    my $directory = $args{-directory};
    my $host      = $args{-host};

    my $command = "grep '$directory ' -r $Configs{Sys_monitor_dir}/$host/";
    my @response = split "\n", try_system_command($command);
    if ( $response[0] =~ /No such file or directory/ ) { return; }

    my @headers;
    if ( $response[0] =~ /^Date/ ) { @headers = split "\t", shift @response }
    if ( $response[-1] =~ /(.+)\:(.+)$/ ) {
        ## get most recent file since the headers may not be on the first versions ##
        my $filename = $1;
        Message("HEADER from $filename = @headers");
        if ( $headers[0] =~ /^Directory|Date|Volume/ ) {
            @headers = split "\t", $filename;
        }
        elsif ($directory) {
            @headers = ( 'Directory', 'Size' );
        }
        elsif ($volume) {
            @headers = ('');
        }
    }
    else {
        Message("Unrecognized format for $command: $response[0]");
    }

    my %data;
    foreach my $line (@response) {
        my @columns = split "\t", $line;
        foreach my $i ( 0 .. $#columns ) { push @{ $data{ $headers[$i] } }, $columns[$i] }
    }

    return %data;
}

#############################
# Description:
#       Gets all the hosts used for the system
# Output:
#       array of all teh hosts
# Input:
#       - NOT REQUIRES -
#############################
sub get_all_hosts {
#############################
    my $self = shift;
    my @hosts;
    for my $info ( keys %Configs ) {
        my $value = $Configs{$info};
        if ( $info =~ /_HOST/ && !( grep /\b$value\b/, @hosts ) ) {
            push @hosts, $value;
        }
    }
    return @hosts;
}

#############################
sub get_web_hosts {
#############################
    my $self = shift;
    my @hosts = ( 'lims08', 'lims09', 'limsdev02' );

    return @hosts;
}

#############################
# Description:
#       Returns list of directories being logged for a given host
# Input:
#       -host:      host name
#       -limit : array ref (only return directories that match this list)
# Output:
#       Array
#############################
sub get_logged_files_list {
#############################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $host = $args{-host};
    my $type = $args{-type};
    my $file = $self->{vol_size_file};

    my $limit = $args{-limit};
    my @final;
    my @dirs;

    my $target_dir = $Configs{Sys_monitor_dir} . '/' . $host . '/' . "$type" . '/';
    my $command    = "find $target_dir -name *.stats -maxdepth 1";
    my @response   = split "\n", try_system_command($command);

    for my $line (@response) {
        if ( $line =~ /^$target_dir(.+)\.stats/ ) {
            my $temp = $1;
            $temp =~ s/::/\//g;
            if ( $limit && ( $type eq 'dirs' ) ) {
                if ( grep /^$temp/, @$limit ) {
                    push @final, $temp;
                }
            }
            else {
                push @final, $temp;
            }
        }
    }
    return @final;
}

#############################
# Description:
#       Gets the sizes of directory from file
# Output:
#       Array of sizes
# Input:
#       - Date: Does not work at this point
#       - host
#       - dir : direcotry
#############################
sub get_dir_size {
#############################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dir  = $args{-dir};
    my $host = $args{-host};
    my $date = $args{-date};
    my $file = $self->get_stat_file( -host => $host, -dir => $dir );
    my @sizes;
    my @dates;

    if ( !-e $file ) { return ( 'undef', 'undef' ) }

    if ($date) {
        ## MUST BE WRITTEN
    }
    else {
        my $command = "tail $file -n 1";
        my @response = split "\s+", try_system_command($command);

        if ( $response[0] =~ /No such file or directory/ ) { Message "LOG MISSING FOR $file "; return; }
        if ( $response[0] =~ /No such file or directory/ ) { return; }
        if ( $response[0] =~ /^(\S+)\s+(\S+)/ ) {
            @sizes = ( $2, $1 );

            # push @sizes, $2."\t".$1;
        }
    }
    return \@sizes;
}

#############################
# Description:
#       Gets the sizes of directory from file
# Output:
#       Array of sizes
# Input:
#       - Date: Does not work at this point
#       - host
#       - volume : volume
#############################
sub get_vol_info {
#############################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $volume = $args{-volume};
    my $host   = $args{-host};
    my $date   = $args{-date};
    my $file   = $self->get_stat_file( -host => $host, -volume => $volume );

    # Message $file;
    my @sizes;
    my @dates;
    if ($date) {
        ## MUST BE WRITTEN
    }
    else {
        my $command = "tail $file -n 1";

        #Message $command;
        my @response = split "\n", try_system_command($command);

        #print HTML_Dump \@response;
        if ( $response[0] =~ /No such file or directory/ ) { return; }
        if ( $response[0] =~ /^(\S+)\s+(.+)$/ ) {
            push @dates, $1;
            push @sizes, $2;
        }
    }

    return ( \@sizes, \@dates );
}

#############################
# Description:
#       Gets full path of the stat file
# Output:
#       string
# Input:
#       - type:         dir or vol
#       - host
#       - dir:          direcotry or volume
#       - read_only:    if not set it will create the path if not in existance
#############################
sub get_stat_file {
#############################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $host   = $args{-host};
    my $dir    = $args{-dir};
    my $volume = $args{-volume};

    if ( $dir && $volume ) { Message("Only supply directory OR volume (not both)"); return; }

    my $scope = $self->find_locality( -host => $host, -directory => $dir, -volume => $volume );    ## convert to shared if applicable ##

    my $main_dir = $Configs{Sys_monitor_dir};
    my $path;

    my $file_name = $dir || $volume;
    $file_name =~ s/\/$//g;
    $file_name =~ s/\/\//\//g;
    $file_name =~ s/\//::/g;
    $file_name .= '.stats';

    if ($dir) {
        $path = $main_dir . '/' . $scope . '/dirs/';
    }
    else {
        $path = $main_dir . '/' . $scope . '/vols/';
    }

    my $stat_file = $path . $file_name;

    return $stat_file;
}

#
# Retrieve hash or array of directories which are specifically monitored
#
# This includes directories from the config file conf/vol_size.conf
#
# Wildcard directories are listed separately from absolute directories and end in '/*' for both the key and value.
# (wildcard directories are only followed if the follow parameter is supplied - takes a little longer)
#
# Return: hash ref to directories (values = alias for directory) monitored  (also updates System attribute to avoid having to reload)
##################################
sub get_watched_directories {
##################################
    my $self            = shift;
    my %args            = filter_input( \@_, -mandatory => 'scope|host' );
    my $silent          = $args{-silent};
    my $scope           = $args{-scope} || $args{-host};
    my $s_section       = $args{-section};                                   ## limits list to specified section
    my $remote          = $args{-remote};                                    ## run remotely from server other than host indicated
    my $follow          = $args{-follow};                                    ## include subdirectories when specified as a wildcard (ie project_dir/*) - use 'All' to follow all wildcard directories ...
    my $include_configs = $args{-include_configs};                           ## include standard directories defined in configuration file

    if ( $scope ne 'shared' ) { $scope = 'local' }
    my $host = $remote || $self->local_host();                               ## may be supplied when run as a shell script only

    if ( defined $self->{watched} && defined $self->{watched}{$scope} ) {
        if ($follow) {
            if ( defined $self->{watched_subdirectories}{$scope} && defined $self->{watched_subdirectories}{$scope}{$follow} ) { return $self->{watched_subdirectories}{$scope}{$follow} }
        }
        else { return $self->{watched}{$scope} }
    }

    my @secs;

    my @config_dirs;
    if ($include_configs) { @config_dirs = grep /\_dir$/, keys %Configs }    ## included directories listed in Configs hash

    if   ($s_section) { @secs = ("$s_section") }
    else              { @secs = ( 'large', 'medium', 'small', 'skip' ) }

    my $file     = $self->{vol_size_file};                                   ##    my $file        = $Configs{web_dir} . '/../conf/vol_size.conf';  ## xml file storing directories to explicitly watch ##
    my %sections = %{ $self->get_size_limits() };
    my %final;
    foreach my $section (@secs) {
        foreach my $dir ( @{ $sections{$section} } ) {
            $dir =~ s/\/+$//;                                                ## truncate backslash at end  of directory name
            my $recursive = 0;
            my $location;
            if ( $dir =~ /(.+)(\/\*)/ ) {
                my $alias   = $1;
                my $pattern = $2;
                $location = $Configs{$alias} || $alias;
                $location .= $pattern;
                if ( ( $follow eq $dir ) || ( $follow eq $location ) || ( $follow eq 'All' ) ) {    ## && grep /^$location$/, @$follow) {
                    $self->get_watched_subdirectories( -scope => $scope, -dir => $dir, -path => $location, %args, -silent => $silent );
                }
            }
            else {
                $location = $Configs{$dir} || $dir;
            }

            if ( $self->find_locality( -host => $host, -directory => $location ) eq 'shared' ) {
                if ( $scope ne 'shared' ) {next}                                                    ## this directory is not in the scope of interest ...
            }
            else {
                if ( $scope eq 'shared' ) {next}
                elsif ( !$scope ) {next}
            }

            $final{$location} = $dir;
        }
    }

    $self->{watched}{$scope} ||= \%final;

    if ( $follow && ( $follow ne 'All' ) ) {
        my $localscope = $self->find_locality( -host => $scope, -directory => $follow );
        $self->{watched_subdirectories}{$localscope}{$follow} ||= {};
        return $self->{watched_subdirectories}{$localscope}{$follow};
    }
    else { return $self->{watched}{$scope} }
}

######################################
sub get_watched_subdirectories {
######################################
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'dir', -mandatory => 'dir,path' );
    my $scope    = $args{-scope};
    my $silent   = $args{-silent};
    my $dir      = $args{-dir};
    my $remote   = $args{-remote};
    my $quiet    = $args{-quiet};
    my $location = $args{-path};

    if ( defined $self->{watched_subdirectories}{$scope}{$dir} ) { return $self->{watched_subdirectories}{$scope}{$dir} }
    my $path = $location;
    $path =~ s/\/\*$//;

    my $recursive = 1;
    my $dirs      = "find  $path -type d -maxdepth $recursive -mindepth $recursive -follow";
    my $links     = "find  $path -type l -maxdepth $recursive -mindepth $recursive -follow";

    if ($remote) {
        ## allow previous usage if necessary (not sure if needed or not eventually ...)
        $dirs  = "ssh -n $remote $dirs";
        $links = "ssh -n $remote $links";
    }

    my @output_dirs = split "\n", try_system_command($dirs);
    my @link_dirs   = split "\n", try_system_command($links);

    if ( $output_dirs[0] =~ /Permission denied|No such file|Could not create directory|verification_failed/ ) { Message("Could not verify $dirs dir: @output_dirs"); }
    if ( $link_dirs[0]   =~ /Permission denied|No such file|Could not create directory|verification_failed/ ) { Message("Could not verify $links links: @link_dirs"); }

    my %watched;
    for my $direc ( @link_dirs, @output_dirs ) {
        if ( $watched{$direc} ) { Message "For $direc entry $watched{$direc} already exists skipping $dir" unless $quiet }
        else {
            if ( $direc eq $location ) {next}    ## skip pointer to self
            else {
                my $localscope = $self->find_locality( -directory => $direc, -host => $scope );
                $watched{$direc} = $dir;
                $self->{watched_subdirectories}{$localscope}{$location}{$direc} = $dir;
            }                                    ## subdirectories
        }
    }

    return \%watched;
}

#
# Populate size limit hash for System object
#
# Return: hash reference to size limit thresholds (and updates System attribute)
##################################
sub get_size_limits {
##################################
    my $self = shift;
    my %args = filter_input( \@_ );

    if ( defined $self->{size_limits} ) {
        return $self->{size_limits};
    }

    my $file = $self->{vol_size_file};                               ##    my $file        = $FindBin::RealBin . '/../conf/vol_size.conf';  ## xml file storing directories to explicitly watch ##
    my %sections = get_lines_between_tags( -filepath => "$file" );

    my %Sizes;
    foreach my $section ( @{ $sections{'sizes'} } ) {
        my ( $size, $threshold ) = split /\s+/, $section;
        $Sizes{$size} = $threshold;
    }
    $self->{size_limits} = \%sections;
    $self->{size_limits}{sizes} = \%Sizes;
    return $self->{size_limits};
}

#
# Retrieve directory size limitation if applicable
#
# Return: size limit on directory (defaults to small size as specified in configuration)
###########################
sub get_size_from_file {
###########################
    my $self     = shift;
    my $file     = $self->{vol_size_file};                           ##    my $file = $FindBin::RealBin . '/../conf/vol_size.conf';
    my %sections = get_lines_between_tags( -filepath => "$file" );
    my $input    = $sections{sizes};
    my @input    = @$input if $input;
    my %sizes;

    for my $line (@input) {
        my ( $type, $size ) = split "\t", $line;
        my ( $ew,   $lms )  = split '_',  $type;
        $sizes{$lms}{$ew} = $size;
    }
    return %sizes;
}

##############################
sub get_daughter_dirs {
##############################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $list_ref = $args{-list};
    my %list     = %$list_ref if $list_ref;

    my @dirs = ( keys %list );
    my @delete_location;
    my @final_dirs;
    for my $dir (@dirs) {
        if ( grep /^$dir/, @final_dirs ) { next; }
        else {
            for my $fin_dir (@final_dirs) {
                if ( $dir =~ /^$fin_dir/ ) {
                    my $location = _get_array_loc( -name => $fin_dir, -array => \@final_dirs );
                    if ( !( defined($location) ) ) {
                        Message("Error: Internal Script Errors: (Location: $location)");
                        next;
                    }
                    splice( @final_dirs, $location, 1 );
                }
            }
            push @final_dirs, $dir;
        }
    }
    return @final_dirs;
}

#############################
# returns max and warning size for a directory
#############################
sub get_directory_limit {
#############################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'dir,type', -mandatory => 'dir' );
    my $directory = $args{-dir};
    my $host      = $args{-host};
    my $silent    = $args{-silent};
    my $type      = $args{-type} || 'error';                                         ## error or warning
    my $debug     = $args{-debug};

    my $scope = $self->find_locality( -host => $host, -directory => $directory );
    if ( $scope ne 'shared' ) { $scope = 'local' }

    my $default = $self->get_size_limit( 'small', $type );

    my ( $wildcard, $follow );
    if ( $directory =~ /^(.+)(\/\*)$/ ) { $follow = $directory; $directory = $1; $wildcard = $2; }

    if ( defined $Configs{$directory} ) { $directory = $Configs{$directory} }
    $directory .= $wildcard;

    my %directories = %{ $self->get_watched_directories( -scope => $scope, -follow => $follow ) };    ## adjust to return: { 'Large' => {'public_dir' => '/home/aldente/public/', 'mysql_dir' => '/var/lib/mysql'}, 'Medium' => {...} ... }
    my %sizes = %{ $self->get_size_limits() };                                                        ## adjust to return: { 'Large' => {'public_dir' => '/home/aldente/public/', 'mysql_dir' => '/var/lib/mysql'}, 'Medium' => {...} ... }

    if ( !defined $self->{watched}{$scope}{$directory} ) {
        my $dir = $directory;
        if ( $dir =~ s /\/\w+$/\/\*/ ) {
            if ( defined $self->{watched}{$scope}{$dir} ) { $directory = $dir }

            #	    else {  $self->{dbc}->message("$directory ($dir) IS NOT a watched directory") }
        }
        else {
            if ($debug) { $self->{dbc}->message("$directory ($dir) NOT a watched directory") }
            return $default;
        }
    }

    my $alias = $self->{watched}{$scope}{$directory};

    my $threshold_size;
    foreach my $size ( keys %{ $sizes{sizes} } ) {
        if ( !defined $sizes{sizes}{"${type}_small"} ) {next}    ## not a size list
        if ( $size =~ /(\w+)\_(\w+)/ ) {
            $size = $2;
        }
        my @directories = @{ $sizes{$size} };

        foreach my $dir (@directories) {
            ## may wish to clear extra space, double //, trailing / to normalize first ##
            if ( $alias eq $dir ) {
                my $limit = $self->get_size_limit( $size, $type );
                if   ($limit) { return $limit }
                else          { $threshold_size = $limit }
            }
            elsif ( $alias =~ /(\S+)\*/ && !$threshold_size ) {
                my $baseline = $1;
                if ( $directory =~ /$baseline\/(\w+)$/ ) {
                    $threshold_size = $self->get_size_limit( $size, $type );
                }
            }
        }
    }
    $threshold_size ||= $default;
    return $threshold_size;
}

########################
sub get_size_limit {
########################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'size,type' );
    my $size = $args{-size} || $args{-key};                 ## small, medium or large
    my $type = $args{-type};                                ## error or warning if applicable

    my %sizes = %{ $self->get_size_limits() };
    if ($type) {
        return $sizes{sizes}{"${type}_$size"};              ## eg '-size=>large, -type=>warning'
    }
    else {
        return $sizes{sizes}{$size};                        ## eg '-size=>'warning_large'  (explicit)
    }
}

#############################
sub get_size {
#############################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $type   = $args{-type};
    my $size   = $args{-size};
    my $ew_ref = $args{-ew};
    my %ew     = %$ew_ref if $ew_ref;
    return $ew{$size}{$type};
}

##########################################################
##      Internal FUNCTIONS
##########################################################

##############################
sub _get_array_loc {
##############################
    my %args      = filter_input( \@_ );
    my $array_ref = $args{-array};
    my $name      = $args{-name};
    my @array     = @$array_ref if $array_ref;
    my $counter;
    for my $entry (@array) {
        if ( $entry eq $name ) {
            if ( $counter == 0 ) { $counter = '0' }
            return $counter;
        }
        $counter++;
    }
    return;
}

#
# Return: host if not local
######################
sub find_locality {
######################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'host' );
    my $host      = $args{-host};
    my $directory = $args{-directory};
    my $alias     = $args{-alias};
    my $volume    = $args{-volume};
    my $debug     = $args{-debug};

    my $locality;
    if ( $host eq 'shared' ) { return 'shared' }    ## if explicitly specified ##

    if ($alias) { $alias =~ s/\/*$//; $directory = $Configs{$alias}; }

    if ( defined $volume ) {
        if ( $volume =~ /^\// ) { $locality = $host }
        elsif ( $volume eq 'none' ) { $locality = $host }
        else                        { $locality = 'shared' }
        return $locality;
    }
    elsif ($directory) {
        $directory =~ s/\/\*$//;                    # use base directory if looking at wildcard

        my $data_home = $Configs{Data_home_dir};    ##  "/home/aldente"; ## This is the fastest way of determining a shared directory
        if ( $directory =~ /^$data_home\b/ ) {
            $locality = 'shared';
        }
        else {
            if ( !-e $directory ) {
                if ($debug) { $self->{dbc}->message("dir '$directory' NOT FOUND on $host") }
                return;
            }
            my @df_result = split "\n", `df '$directory'`;
            ## check volume for this directory to see if it is on the local machine or referencing a shared disk ##
            if ( $df_result[0] =~ /Filesystem/ ) {
                my $volume = $df_result[1];

                if   ( $volume =~ /^\// ) { $locality = $host }
                else                      { $locality = 'shared' }
            }
        }
    }
    return $locality;
}

#
# Return: 1 if indicated host is currently visible from current host
#####################
sub visible_host {
#####################
    my $self = shift;
    my $host = shift;

    if    ( $host eq $self->local_host() ) { return 1 }
    elsif ( $host eq 'shared' )            { return 1 }
    else                                   { return 0 }
}

#################
sub local_host {
##################
    my $self = shift;

    if ( !$self->{local_host} ) {
        my $host = $ENV{SERVER_NAME} || $ENV{HOSTNAME};
        $host =~ s/\..*//;
        $self->{local_host} = $host;
    }

    return $self->{local_host};
}

1;
