#!/usr/local/bin/perl
# batch create library plates using File_Validator.pm
# only creates plate and library_plate. please add customized code to create sample and plate_sample

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

use vars qw($opt_host $opt_dbase $opt_user $opt_pass $opt_update $opt_delimiter $opt_file $opt_help $opt_ignore);
use Getopt::Long;
&GetOptions(
    'host=s'      => \$opt_host,
    'dbase=s'     => \$opt_dbase,
    'user=s'      => \$opt_user,
    'pass=s'      => \$opt_pass,
    'delimiter=s' => \$opt_delimiter,
    'file=s'      => \$opt_file,
    'ignore=s'    => \$opt_ignore,
    'help'        => \$opt_help,
    'update'      => \$opt_update,
);

if ($opt_help) {
    &_help();
    exit;
}

my $user = $opt_user || 'super_cron';
my $pass = $opt_pass;
my $host = $opt_host;
my $dbase = $opt_dbase;

if(!$pass){
    $pass = SDB::DBIO::get_password_from_file(-host=>$host, -user=>$user);
}

my $delimiter = $opt_delimiter || '\t';
my $update = $opt_update;

my $file   = $opt_file;
my $ignore = $opt_ignore;

my @ignores;
if ( $ignore =~ /\S+/ ) {
    @ignores = split( ",", $ignore );
}

my $template = {
    'Source_ID' => {
        'option'    => 'optional',
        'lims_name' => 'FK_Source__ID',
        'table'     => 'Sample',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Library_Name' => {
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
    'Pipeline' => {
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
    'Employee_ID' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Employee__ID',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Plate_Format' => {
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
    'Rack_ID' => {
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
    'Plate_Class' => {
        'option'    => 'optional',
        'lims_name' => 'Plate_Class',
        'table'     => 'Library_Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Plate_Size' => {
        'option'    => 'mandatory',
        'lims_name' => 'Plate_Size',
        'table'     => 'Plate',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },

};

my $connection = SDB::DBIO->new( -dbase => $dbase, -host => $host, -user => $user, -password => $pass, -connect => 1 );
my $validator = Submission::File_Validator->new( -dbc => $connection );

my $msg;

my $file_string = $validator->clean_file( -file => $file, -delimiter => $delimiter );

my $parsed_file = $validator->parse_submission( -string => $file_string, -delimiter => $delimiter );

#print Dumper $parsed_file;

my ( $failed, $error, $data ) = $validator->validate_submission( -string => $file_string, -delimiter => $delimiter, -template => $template, -ignore_fields => \@ignores );
if ( $error && ref $error eq 'ARRAY' ) {
    $msg .= join( "\n", @$error );
}

if ( $data && $update ) {
    if ( !$failed && ( scalar(@$error) == 0 ) ) {
        $msg .= "\nFile : $file passed validation:\n";
        my $result = $validator->upload_submission( -data => $data );
        $msg .= "Updating database:\n";

        if ( $result && ref $result eq 'ARRAY' ) {
            foreach ( my $i = 0; $i < scalar @$result; $i++ ) {
                my $item      = $result->[$i];
                my $source_id = $parsed_file->[$i]->{Source_ID};
                my $plate_id  = $item->{'Plate.Plate_ID'};
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

sub _help {

    print <<HELP;

File:  library_plate_batch.pl
####################

Options:
##########

  -host: database host. e.g., lims02
  -dbase: database name. e.g., sequence
  -user: database username. e.g., super_cron
  -pass: database password.
  -delimiter: delimiter in the submission file. default: \t
  -file: submission file name
  -ignore: Column names to ignore. comma delimited list. e.g., Source_ID
  -update: if specified, database will be updated
  -help: print this help

Examples:
##########

./library_plate_batch.pl -host lims02 -dbase sequence -user super_cron -p ******* -file /home/echuah/batch_plate1.txt -ignore Source_ID -update

HELP

}

1;
