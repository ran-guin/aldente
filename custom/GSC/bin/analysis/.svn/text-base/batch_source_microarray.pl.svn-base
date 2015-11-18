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

use vars qw($opt_host $opt_dbase $opt_user $opt_pass $opt_update $opt_delimiter $opt_file);
use Getopt::Long;
&GetOptions(
    'host=s'      => \$opt_host,
    'dbase=s'     => \$opt_dbase,
    'user=s'      => \$opt_user,
    'pass=s'      => \$opt_pass,
    'delimiter=s' => \$opt_delimiter,
    'file=s'      => \$opt_file,
    'update'      => \$opt_update,
);

my $user = $opt_user || 'super_cron';
my $pass = $opt_pass;
my $host = $opt_host;
my $dbase = $opt_dbase;

if(!$pass){
    $pass = SDB::DBIO::get_password_from_file(-host=>$host, -user=>$user);
}

my $delimiter = $opt_delimiter || '\t';
my $update = $opt_update;

my $user_file = $opt_file;

my $template = {
    'Library.FK_Original_Source__ID' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Original_Source__ID',
        'table'     => 'Library',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Source.FK_Original_Source__ID' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Original_Source__ID',
        'table'     => 'Source',
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

    'Nature' => {
        'option'    => 'optional',
        'lims_name' => 'Nature',
        'table'     => 'RNA_DNA_Source',
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

    'Library_Type' => {
        'option'    => 'mandatory',
        'lims_name' => 'Library_Type',
        'table'     => 'Library',
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

};

my $connection = SDB::DBIO->new( -dbase => $dbase, -host => $host, -user => $user, -password => $pass, -connect => 1 );
my $validator = Submission::File_Validator->new( -dbc => $connection );

my $msg;

my $file = $user_file;

my $contact;
my $date;
my $project;
my $group;

# find the info from file name
if ( $file =~ /(\w\w\w-\d\d-\d\d\d\d)_(\d+)_(\d+)_(\d+)\.txt$/ ) {
    $date    = $1;
    $group   = $2;
    $project = $3;
    $contact = $4;
}

if ( $file && $contact && $date && $project && $group ) {

    #my $template = $validator->create_template();
    my ( $failed, $error, $data ) = $validator->validate_submission( -file => $file, -delimiter => $delimiter, -template => $template, -project_id => $project, -group_id => $group, -received_date => $date, -contact_id => $contact );
    if ( $error && ref $error eq 'ARRAY' ) {
        $msg .= join( @$error, "\n" );
    }

    print Dumper $data;

    if ( $data && $update ) {
        if ( !$failed && ( scalar(@$error) == 0 ) ) {
            $msg .= "\nFile : $file passed validation:\n";
            my $result = $validator->upload_submission( -data => $data );
            $msg .= "Updating database:\n";

            if ( $result && ref $result eq 'ARRAY' ) {
                foreach my $item (@$result) {
                    my $plate_id = $item->{'Plate.Plate_ID'};
                    if ($plate_id) {
                        ## update Plate.FKOriginal_Plate__ID
                        $connection->start_trans('update');
                        my $ok = $connection->Table_update_array( "Plate", ['FKOriginal_Plate__ID'], [$plate_id], "where Plate_ID = $plate_id" );
                        if ($ok) {
                            $connection->finish_trans('update');
                        }
                        else {
                            $connection->finish_trans( 'update', -error => 'failed' );
                        }
                    }
                }
            }

            $msg .= Dumper $result;

        }
        else {
            $msg .= "\nFile : $file failed validation:\n";
            $msg .= join( "\n", @$error );
        }

    }
    elsif ($data) {
        print Dumper $data;
    }
}
else {

    #$msg .= "Skipping $file ...\n";
}

print $msg;

