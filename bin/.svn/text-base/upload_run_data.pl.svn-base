#!/usr/local/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Benchmark;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";

use SDB::DBIO;
use RGTools::RGIO;
use RGTools::FTP;
use SDB::CustomSettings;
use alDente::Submission_Volume;

use vars qw(%Configs $opt_help $opt_host $opt_dbase $opt_user $opt_password $opt_run_dir_suffix);

&GetOptions(
    'help|h|?'         => \$opt_help,
    'host=s'           => \$opt_host,
    'dbase|d=s'        => \$opt_dbase,
    'user|u=s'         => \$opt_user,
    'password|p=s'     => \$opt_password,
    'run_dir_suffix=s' => \$opt_run_dir_suffix,
);

my $help           = $opt_help;
my $host           = $opt_host;
my $dbase          = $opt_dbase;
my $user           = $opt_user;
my $pwd            = $opt_password;
my $run_dir_suffix = $opt_run_dir_suffix || '';

if ($help) {
    &display_help();
    exit;
}

my $pass_file   = $FindBin::RealBin . "/../conf/data_submission.passwd";
my %fasp_config = (
    'NCBI SRA' => {
        'site'            => 'fasp.ncbi.nlm.nih.gov',
        'destination_dir' => 'incoming',
        'data_encryption' => 0,
        'pass'            => 'private_key',
    },

    'NCBI SRA_protected' => {
        'site'            => 'gap-upload.ncbi.nlm.nih.gov',
        'destination_dir' => 'protected',
        'data_encryption' => 1,
        'pass'            => 'private_key',
    },

    'EBI' => {
        'site'            => 'fasp.era.ebi.ac.uk',
        'destination_dir' => '',
        'data_encryption' => 0,
        'pass'            => 'password',
    }
);

my $lock_file = $Configs{data_submission_workspace_dir} . "/.upload_run_data.lock";

# exit if locked
if ( -e "$lock_file" ) {
    print "The script is locked.\n";
    exit;
}

# write a lock file
try_system_command( -command => "touch $lock_file" );

my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};
my $dbc                  = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my @logs     = ();
my $today    = today();
my $LOG_FILE = "$SUBMISSION_WORK_PATH/logs/upload_run_data_$today.log";
if ( !-e $LOG_FILE ) {
    my $log_file_ok = RGTools::RGIO::create_file( -name => "upload_run_data_$today.log", -path => "$SUBMISSION_WORK_PATH/logs", -chgrp => 'lims', -chmod => 'g+w' );
    if ($log_file_ok) {
        &log("Created $LOG_FILE");
    }
    else {
        &log("ERROR: Create $LOG_FILE failed: $!\n");
    }
}

my %uploads    = ();
my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
my @volumes    = $volume_obj->get_volumes( -run_status => "In Process" );
foreach my $volume_id (@volumes) {
    my $target = $volume_obj->get_volume_target( -volume_id => $volume_id );
    my $requests;
    if ( $target =~ /EDACC/i ) {
        $requests = &get_edacc_requests( -volume_id => $volume_id );
    }
    elsif ( $target =~ /NCBI/i ) {
        $requests = &get_upload_requests( -volume_id => $volume_id );
    }
    foreach my $target ( keys %$requests ) {
        if ( exists $uploads{$target} ) {
            foreach my $file ( keys %{ $requests->{$target} } ) {
                $uploads{$target}{$file} = $requests->{$target}{$file};
            }
        }
        else {
            $uploads{$target} = $requests->{$target};
        }
    }
}    # END foreach my $volume_id ( @volumes )
&write_log( -file => $LOG_FILE );

foreach my $target ( keys %uploads ) {
    if ( $target =~ /EDACC/i ) {
        &upload_edacc_run_data( -uploads => $uploads{$target} );
    }
    else {
        &upload_run_data( -target => $target, -uploads => $uploads{$target} );
    }
}

&write_log( -file => $LOG_FILE );

# remove lock file
try_system_command( -command => "rm $lock_file" );
exit;

sub get_edacc_requests {
    my %args = filter_input( \@_, -args => 'volume_id' );
    my $volume_id = $args{-volume_id};

    my %uploads;
    my $volume_obj  = new alDente::Submission_Volume( -dbc     => $dbc );
    my $volume_name = $volume_obj->get_volume_name( -volume_id => $volume_id );
    my $volume_name_without_space = $volume_name;
    $volume_name_without_space =~ s| |_|g;    # replace space with underscore
    my $submission_dir = "$SUBMISSION_WORK_PATH/$volume_name_without_space";
    my $command        = "find $submission_dir -name '.upload' -maxdepth 2 -printf \"%p\n\"";
    my ( $output, $stderr ) = try_system_command( -command => $command );
    if ($output) {
        my @uploads = split /\n/, $output;
        foreach my $upload (@uploads) {
            my $status = $upload;
            if ( -f "$upload.done" ) {
                next;
            }
            elsif ( -f "$upload.initiated" ) {    # need to check if the file transfer is done
                $status = "$upload.initiated";
            }

            $command = "head -3 $upload";
            my ( $out, $err ) = try_system_command( -command => $command );
            if ($out) {
                my @lines = split "\n", $out;
                if ( scalar(@lines) < 3 ) {
                    &log("Incorrect format! $upload NOT processed!");
                    next;
                }
                my $target   = $lines[0];
                my $file     = $lines[1];
                my $run_list = $lines[2];
                $uploads{$target}{$file}{volume_id}   = $volume_id;
                $uploads{$target}{$file}{runs}        = $run_list;
                $uploads{$target}{$file}{status_file} = $status;
                ( $out, $err ) = try_system_command( -command => "stat -c %y $upload" );
                my $date_time = substr( $out, 0, 19 );
                $uploads{$target}{$file}{create_time} = $date_time;

                if ( $status =~ /initiated/ ) {
                    &log("Got initiated upload in $status: target=$target; file=$file; runs=$run_list");
                }
                else {
                    &log("Got new upload in $upload: target=$target; file=$file; runs=$run_list");
                }
            }    # END if( $out )
        }    # END foreach my $upload ( @uploads )
    }    # END if( $output )
    return \%uploads;
}

sub upload_edacc_run_data {
    my %args = filter_input( \@_, -args => 'uploads' );
    my $uploads = $args{-uploads};

    ## create the connection to the BIOAPP API server
    require SOAP::XMLRPC::Lite;

    my $target = "BIOAPP";
    my $user   = "limsproxy";
    my $password;

    my $ok = open( PASSFILE, $pass_file );
    if ( !$ok ) {
        &log("ERROR: Couldn't open $pass_file for reading: $!");
        return 0;
    }

    while (<PASSFILE>) {
        if (/^$target:$user:(\S+)/) { $password = $1; last; }
    }
    close(PASSFILE);

    unless ($password) {
        &log("ERROR: Password not found for $target:$login_name in $pass_file\n");
        return 0;
    }

    $user     = 'dcheng';
    $password = 'deanpwd';

    #my $host = "twong.phage.bcgsc.ca";
    #my $port = "8080";
    #my $path = "/test";
    #my $address = "http://$user:$password" . '@' . "$host:$port$path";
    #'http://GINUSER:GINPASSWORD@www.bcgsc.ca/data/sbs/viewer/'
    my $host    = "www.bcgsc.ca";
    my $path    = "/data/sbs/viewer";
    my $address = "http://$user:$password" . '@' . "$host$path";

    my $web_service_client = XMLRPC::Lite->proxy("$address");

    foreach my $file ( keys %$uploads ) {
        ## Get the REMC project ID since only REMC project submit to EDACC currently
        my ($project_id) = $dbc->Table_find( -table => 'Project', -fields => 'Project_ID', -condition => "WHERE Project_Name = 'REMC'" );

        my $run_ids = Cast_List( -list => $uploads->{$file}{runs}, -to => 'arrayref' );
        my $sample_run = $run_ids->[0] if ( scalar(@$run_ids) );
        my $status_file_path;
        my $status_file = $uploads->{$file}{status_file};
        if ( $status_file =~ /(.*)\/([^\/]+)$/ ) {
            $status_file_path = $1;
        }
        if ( $uploads->{$file}{status_file} =~ /initiated/ ) {    # upload has been initiated, check the FTP status
            my $api_args = {
                'lims_run_id'     => $sample_run,
                'lims_project_id' => $project_id,
                'date_notified'   => $uploads->{$file}{create_time},
            };
            my $return_data = $web_service_client->call( 'getFTPQueue', $api_args )->result;
            if ( $return_data->{$sample_run}{ftp_file_copy_date} ) {
                my $max_index = scalar( @{ $return_data->{$sample_run}{ftp_file_copy_date} } ) - 1;
                if ( defined $return_data->{$sample_run}{ftp_file_copy_date}[$max_index] ) {

                    # file tansfer done successfully
                    &log("$file has been copied to FTP server successfully");
                    ## create status file .upload.done
                    my $filename = ".upload.done";
                    my $status_file_ok = RGTools::RGIO::create_file( -name => $filename, -path => "$status_file_path", -chgrp => 'lims', -chmod => 'g+w', -overwrite => 1 );
                    if ($status_file_ok) {
                        &log("Created $status_file_path/$filename");

                        ## create .upload.done in the run data dirs
                        foreach my $run (@$run_ids) {
                            my $run_data_dir = "$Configs{data_submission_workspace_dir}/Run$run";
                            $status_file_ok = RGTools::RGIO::create_file( -name => $filename, -path => "$run_data_dir", -chgrp => 'lims', -chmod => 'g+w', -overwrite => 1 );
                            if ( !$status_file_ok ) {
                                &log("ERROR: Failed in creating $run_data_dir/$filename!");
                            }

                        }
                    }
                    else {
                        &log("ERROR: Failed in creating $status_file_path/$filename!");
                    }
                }
            }
        }
        else {    # initiate the upload
            my $api_args = {
                'lims_run_ids'    => $run_ids,
                'lims_project_id' => $project_id,
                'data_path'       => $file,
            };
            my $return_data = $web_service_client->call( 'setFTPQueue', $api_args )->result;
            if ( $return_data =~ /Successfully added/i ) {
                &log("API upload initiated: $file");

                ## create status file .upload.initiated
                my $status_file_ok = RGTools::RGIO::create_file( -name => ".upload.initiated", -path => "$status_file_path", -chgrp => 'lims', -chmod => 'g+w', -overwrite => 1 );
            }
            else {
                my $dumper_return_data = Dumper $return_data;
                &log("ERROR: API upload failed: $file\n$dumper_return_data");
            }
        }
    }
}

sub get_upload_requests {
    my %args = filter_input( \@_, -args => 'volume_id' );
    my $volume_id = $args{-volume_id};

    my %uploads;
    my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
    my @runs = $volume_obj->get_runs( -dbc => $dbc, -volume_id => $volume_id, -run_status => "In Process" );
    foreach my $run (@runs) {
        my $run_dir = "$SUBMISSION_WORK_PATH/Run$run";
        if ( -f "$run_dir/.upload" ) {
            my $status = "$run_dir/.upload";
            if ( -f "$run_dir/.upload.done" ) {
                next;
            }
            elsif ( -f "$run_dir/.upload.initiated" ) {    # need to check if the file transfer is done
                $status = "$run_dir/.upload.initiated";
            }

            my $command = "head -2 $run_dir/.upload";
            my ( $out, $err ) = try_system_command( -command => $command );
            if ($out) {
                my @lines = split "\n", $out;
                if ( scalar(@lines) < 2 ) {
                    &log("Incorrect format! Run $run NOT processed!");
                    next;
                }
                my %params;
                foreach my $line (@lines) {
                    my @elements = split '=', $line;
                    my $count = scalar(@elements);
                    if ( $count > 0 ) {
                        my $key = $elements[0];
                        my $value;
                        $value = $elements[1] if ( $count > 1 );
                        $params{$key} = $value;
                    }
                }
                my $target    = $params{target};
                my $protected = $params{protected};
                if ($protected) {
                    $target .= "_protected";
                }
                my $run_file_name = "Run$run" . "Lane*.srf";
                my $command       = "find $run_dir -name '$run_file_name' -maxdepth 1 -printf \"%p\n\" ";
                my ( $out2, $err2 ) = try_system_command( -command => $command );
                if ($out2) {
                    my @run_files = split "\n", $out2;
                    foreach my $run_file (@run_files) {
                        $uploads{$target}{$run_file}{volume_id}   = $volume_id;
                        $uploads{$target}{$run_file}{status_file} = $status;
                        $uploads{$target}{$run_file}{run}         = $run;
                    }
                }
                if ( $status =~ /initiated/ ) {
                    &log("Got initiated upload in $status: target=$target");
                }
                else {
                    &log("Got new upload in $status: target=$target");
                }
            }    # END if( $out )
        }    # END if( -f "$run_dir/.upload" )
    }    # END foreach my $run ( @runs )
    return \%uploads;
}

sub upload_run_data {
    my %args    = filter_input( \@_, -args => 'target,uploads' );
    my $target  = $args{-target};
    my $uploads = $args{-uploads};

    my $protocol    = 'FASP';
    my $pass_method = $fasp_config{$target}{pass};

    ## get user name and password/private key
    my $user;
    my $pass;
    my $ok = open my $IN, "$pass_file";
    if ( !$ok ) {
        &log("ERROR: Couldn't open $pass_file for reading: $!");
        return 0;
    }
    while (<$IN>) {
        if (/^$target:([^:]+):([^:]+)/) {
            $user = $1;
            $pass = $2;
            chomp($pass);
            last;
        }
    }
    if ( !$user || !$pass ) {
        &log("ERROR: Couldn't find user name and/or pass in $pass_file");
        return 0;
    }

    my @files    = keys %{$uploads};
    my $uploaded = &upload(
        -protocol         => $protocol,
        -site             => $fasp_config{$target}{site},
        -user             => $user,
        -$pass_method     => $pass,
        -target_directory => $fasp_config{$target}{destination_dir},
        -files            => \@files,
        -data_encryption  => $fasp_config{$target}{data_encryption},
    );

    #			-test	=> 1,
    foreach my $file (@$uploaded) {
        my $volume_id = $uploads->{$file}{volume_id};

        ## create status file .upload.done
        my $status_file_path;
        my $status_file = $uploads->{$file}{status_file};
        if ( $status_file =~ /(.*)\/([^\/]+)$/ ) {
            $status_file_path = $1;
        }
        my $filename = ".upload.done";
        my $status_file_ok = RGTools::RGIO::create_file( -name => $filename, -path => "$status_file_path", -chgrp => 'lims', -chmod => 'g+w', -overwrite => 1 );
        if ($status_file_ok) {
            &log("Created $status_file_path/$filename");
        }
        else {
            &log("ERROR: Failed in creating $status_file_path/$filename!");
        }
    }
}

#########
sub log {
########
    my %args = filter_input( \@_, -args => 'log' );
    my $log = $args{ -log };

    my $timestamp = &date_time();
    push @logs, "$timestamp: $log" if ($log);
    print "$timestamp: $log\n";
    return;
}

################
sub write_log {
################
    my %args = filter_input( \@_, -args => 'file' );
    my $file = $args{-file};

    my $logs = join "\n", @logs;
    if ( open my $LOG, '>>', "$file" ) {
        print $LOG "$logs\n";
        close($LOG);
        @logs = ();    ## cleanup the log array
    }
    else {
        print "ERROR: open log file $file failed: $!\n";
    }

    return;
}

##################
sub display_help {
##################
    print <<HELP;

Syntax
======
upload_run_data.pl - This script uploads the run data files to their destination.

Arguments:
=====

-- required arguments --
-host			: specify database host, ie: -host limsdev02 
-dbase, -d		: specify database, ie: -d seqdev. 
-user, -u		: specify database user. 
-passowrd, -p		: password for the user account

-- optional arguments --
-help, -h, -?		: displays this help. (optional)

Example
=======
upload_run_data.pl -host lims05 -d seqtest -u user -p xxxxxx 

HELP

}
