#!/usr/local/bin/perl
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use strict;
use Data::Dumper;

use SDB::DBIO;
use Submission::File_Validator;
use File::Find;
use alDente::Notification;
use RGTools::Process_Monitor;

use vars qw($Connection);
use vars qw($opt_host $opt_dbase $opt_debug $opt_user $opt_update $opt_delimiter $opt_file $opt_help);
use Getopt::Long;
&GetOptions(
    'host=s'      => \$opt_host,
    'dbase=s'     => \$opt_dbase,
    'user=s'      => \$opt_user,
    'delimiter=s' => \$opt_delimiter,
    'file=s'      => \$opt_file,
    'update'      => \$opt_update,
    'help'        => \$opt_help,
);

if ($opt_help) {
    &_help();
    exit;
}

my $user  = $opt_user || 'super_cron';
my $host  = $opt_host;
my $dbase = $opt_dbase;

my $delimiter = $opt_delimiter || '\t';
my $update = $opt_update;

my $template = {
    'Original_Source_Name' => {
        'option'    => 'mandatory',
        'lims_name' => 'Original_Source_Name',
        'table'     => 'Original_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'External_Identifier' => {
        'option'    => 'mandatory',
        'lims_name' => 'External_Identifier',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Label' => {
        'option'    => 'optional',
        'lims_name' => 'Label',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Sex' => {
        'option'    => 'optional',
        'lims_name' => 'Sex',
        'table'     => 'Original_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Family_ID' => {
        'option'    => 'optional',
        'lims_name' => 'Family_ID',
        'table'     => 'Original_Source',
        'lookup'    => 0,
        'attribute' => 1,
        'format'    => '',
    },
    'Family_Status' => {
        'option'    => 'optional',
        'lims_name' => 'Family_Status',
        'table'     => 'Original_Source',
        'lookup'    => 0,
        'attribute' => 1,
        'format'    => '',
    },
    'Nature' => {
        'option'    => 'optional',
        'lims_name' => 'Nature',
        'table'     => 'RNA_DNA_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Tissue_Type' => {
        'option'    => 'optional',
        'lims_name' => 'FK_Tissue__ID',
        'table'     => 'Original_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Organism' => {
        'option'    => 'optional',
        'lims_name' => 'FK_Organism__ID',
        'table'     => 'Original_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Notes' => {
        'option'    => 'optional',
        'lims_name' => 'Notes',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Storage_Medium' => {
        'option'    => 'optional',
        'lims_name' => 'Storage_Medium',
        'table'     => 'RNA_DNA_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Storage_Medium_Quantity' => {
        'option'    => 'optional',
        'lims_name' => 'Storage_Medium_Quantity',
        'table'     => 'RNA_DNA_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Storage_Medium_Quantity_Units' => {
        'option'    => 'optional',
        'lims_name' => 'Storage_Medium_Quantity_Units',
        'table'     => 'RNA_DNA_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Sample_Collection_Date' => {
        'option'    => 'optional',
        'lims_name' => 'Sample_Collection_Date',
        'table'     => 'RNA_DNA_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Nucleic_Acid_Isolation_Date' => {
        'option'    => 'optional',
        'lims_name' => 'RNA_DNA_Isolation_Date',
        'table'     => 'RNA_DNA_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Nucleic_Acid_Isolation_Method' => {
        'option'    => 'optional',
        'lims_name' => 'RNA_DNA_Isolation_Method',
        'table'     => 'RNA_DNA_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Nucleic_Acid_Isolation_Performed_By' => {
        'option'    => 'optional',
        'lims_name' => 'Nucleic_Acid_Isolation_Performed_By',
        'table'     => 'RNA_DNA_Source',
        'lookup'    => 0,
        'attribute' => 1,
        'format'    => '',
    },
    'Concentration' => {
        'option'    => 'optional',
        'lims_name' => 'Concentration',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 1,
        'format'    => '',
    },
    'Concentration_Units' => {
        'option'    => 'optional',
        'lims_name' => 'Concentration_Units',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 1,
        'format'    => '',
    },
    'Blood_Sampling_Date' => {
        'option'    => 'optional',
        'lims_name' => 'Blood_Sampling_Date',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 1,
        'format'    => '',
    },
    'Blood_Sampling_Location' => {
        'option'    => 'optional',
        'lims_name' => 'Blood_Sampling_Location',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 1,
        'format'    => '',
    },
    'Blood_Collected_By' => {
        'option'    => 'optional',
        'lims_name' => 'Blood_Collected_By',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 1,
        'format'    => '',
    },

    #added by LIMS:

    'Library_Name' => {
        'option'    => 'mandatory',
        'lims_name' => 'Library_Name',
        'table'     => 'Library',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Obtained_Date' => {
        'option'    => 'optional',
        'lims_name' => 'Library_Obtained_Date',
        'table'     => 'Library',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Library_Full_Name' => {
        'option'    => 'mandatory',
        'lims_name' => 'Library_FullName',
        'table'     => 'Library',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Library_Description' => {
        'option'    => 'optional',
        'lims_name' => 'Library_Description',
        'table'     => 'Library',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Library_Type' => {
        'option'    => 'mandatory',
        'lims_name' => 'Library_Type',
        'table'     => 'Library',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },

    #<CONSTRUCTION> Collection_Type should be removed once all submission files use Experiment_Type
    'Collection_Type' => {
        'option'    => 'mandatory',
        'lims_name' => 'Experiment_Type',
        'table'     => 'RNA_DNA_Collection',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Experiment_Type' => {
        'option'    => 'mandatory',
        'lims_name' => 'Experiment_Type',
        'table'     => 'RNA_DNA_Collection',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Source_Type' => {
        'option'    => 'mandatory',
        'lims_name' => 'Source_Type',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'FK_Grp__ID' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Grp__ID',
        'table'     => 'Library',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Date_Received' => {
        'option'    => 'optional',
        'lims_name' => 'Received_Date',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'FK_Project__ID' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Project__ID',
        'table'     => 'Library',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Contact_ID' => {
        'option'    => 'optional',
        'lims_name' => 'FK_Contact__ID',
        'table'     => 'Library',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },

};

my $msg;

my $connection = SDB::DBIO->new( -dbase => $dbase, -host => $host, -user => $user, -connect => 1 );
my $validator = Submission::File_Validator->new( -dbc => $connection );
my $Report = Process_Monitor->new();

my $user_files = $opt_file;
my %files;

if ($user_files) {

    my @user_files_array = split ",", $user_files;
    foreach my $user_file (@user_files_array) {
        if ( $user_file =~ /\/\s*(\w\w\w-\d\d-\d\d\d\d_\d+_\d+_\d+\.txt)\s*$/ ) {
            $files{$user_file} = $1;
        }
    }
}
else {

    # microarray_submission file folder
    my $submission_dir = "/home/sequence/alDente/uploads/microarray/";
    my %all_files;
    find sub { $all_files{$File::Find::name} = $_ if -f }, $submission_dir;

    foreach my $full_path ( keys %all_files ) {
        if ( $full_path !~ /done$/ ) {
            my $submitted = $full_path . ".done";

            if ( -e $submitted ) {

                # this file is submitted, skipping
            }
            else {
                $files{$full_path} = $all_files{$full_path};
            }
        }
    }
}

foreach my $full_path ( keys %files ) {
    my $file = $files{$full_path};

    if ( $file =~ /(\w\w\w-\d\d-\d\d\d\d)_(\d+)_(\d+)_(\d+)\.txt/ ) {

        my $submitted = $full_path . ".done";

        # cleanup file
        my $file_string = $validator->clean_file( -file => $full_path );

        my $contact = $4;
        my $date    = $1;
        my $project = $3;
        my $group   = $2;

        if ( $file && $contact && $date && $project && $group ) {

            my ( $failed, $error, $data ) = $validator->validate_submission( -string => $file_string, -delimiter => $delimiter, -template => $template, -project_id => $project, -group_id => $group, -received_date => $date, -contact_id => $contact );
            if ( $error && ref $error eq 'ARRAY' ) {
                $msg .= join( "\n", @$error );
            }

            print Dumper $data;

            if ( $data && $update ) {
                if ( !$failed && ( scalar(@$error) == 0 ) ) {
                    $msg .= "\nFile : $file passed validation:\n";
                    my $result = $validator->upload_submission( -data => $data );
                    $msg .= "Updating database:\n";
                    $msg .= Dumper $result;
                    my $command = "cp " . $full_path . " " . $submitted;
                    system($command);
                }
                else {
                    $msg .= "\nFile : $file failed validation:\n";
                    $msg .= join( "\n", @$error );
                }

            }
        }
        else {
            $msg .= "Skipping $file ...\n";
        }
    }

}

print $msg;

# email to susanna

my $to      = 'schan@bcgsc.ca';
my $from    = 'aldente@bcgsc.ca';
my $cc      = 'aldente@bcgsc.ca';
my $subject = "microarray batch submission cronjob";

if ( $msg && $dbase eq 'sequence' ) {

    open( SENDMAIL, "|/usr/lib/sendmail $to" ) or die "Can't sendmail: $!\n";
    print SENDMAIL<<EOF;
From: $from
To: $to
Cc: $cc
Subject: $subject

$msg
EOF
    $Report->set_Message("Email sent.");

    close(SENDMAIL) or warn "sendmail couldn't close";

}

$Report->completed();
$Report->DESTROY();

sub _help {

    print <<HELP;

File:  microarray_batch_submission.pl
####################

Options:
##########

  -host: database host. e.g., lims02
  -dbase: database name. e.g., sequence
  -user: database username. e.g., super_cron
  -delimiter: delimiter in the submission file. default: \t
  -file: submission file name. if this is not specified, the script finds files in '/home/sequence/alDente/uploads/microarray/' that are in the format of date-grpid-projectid-contactid.txt (e.g.,Oct-30-2006_21_109_461.txt) and that are not marked as ".done" (e.g.,Oct-30-2006_21_109_461.txt.done), submits these files, copies them to ".done" so that next time they will not get processed again.
  -update: if specified, database will be updated
  -help: print this help

Examples:
##########

./microarray_batch_submission.pl -host lims02 -dbase sequence -user super_cron -p ****** -file /home/sequence/alDente/uploads/microarray/Oct-30-2006_21_109_461.txt -update

HELP

}

1;
