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

my $delimiter = $opt_delimiter || '\t';
my $update = $opt_update;

my $file  = $opt_file;
my $host  = $opt_host;
my $dbase = $opt_dbase;

if(!$pass){
    $pass = SDB::DBIO::get_password_from_file(-host=>$host, -user=>$user);
}

my $template = {
    'FK_Source__ID' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Source__ID',
        'table'     => 'Sample',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'FK_Library__Name' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Library__Name',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Plate_Comments' => {
        'option'    => 'optional',
        'lims_name' => 'Plate_Comments',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'FK_Pipeline__ID' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Pipeline__ID',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Plate_Created' => {
        'option'    => 'mandatory',
        'lims_name' => 'Plate_Created',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'FK_Employee__ID' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Employee__ID',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'FK_Plate_Format__ID' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Plate_Format__ID',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Plate_Status' => {
        'option'    => 'mandatory',
        'lims_name' => 'Plate_Status',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'FK_Rack__ID' => {
        'option'    => 'optional',
        'lims_name' => 'FK_Rack__ID',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Current_Volume' => {
        'option'    => 'optional',
        'lims_name' => 'Current_Volume',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Current_Volume_Units' => {
        'option'    => 'optional',
        'lims_name' => 'Current_Volume_Units',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Plate_Test_Status' => {
        'option'    => 'mandatory',
        'lims_name' => 'Plate_Test_Status',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },

    'Plate_Content_Type' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Sample_Type__ID',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Plate_Type' => {
        'option'    => 'mandatory',
        'lims_name' => 'Plate_Type',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Concentration_Units' => {
        'option'    => 'optional',
        'lims_name' => 'Concentration_Units',
        'table'     => 'Tube',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Concentration' => {
        'option'    => 'optional',
        'lims_name' => 'Concentration',
        'table'     => 'Tube',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
};

my $connection = SDB::DBIO->new( -dbase => $dbase, -host => $host, -user => $user, -password => $pass, -connect => 1 );
my $validator = Submission::File_Validator->new( -dbc => $connection );

my $msg;

my ( $failed, $error, $data ) = $validator->validate_submission( -file => $file, -delimiter => $delimiter, -template => $template );
if ( $error && ref $error eq 'ARRAY' ) {
    $msg .= join( @$error, "\n" );
}

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
                    $connection->Table_update_array( "Plate", ['FKOriginal_Plate__ID'], [$plate_id], "where Plate_ID = $plate_id" );
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

print $msg;

