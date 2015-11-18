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
use RGTools::RGIO;

use vars qw($opt_host $opt_dbase $opt_user $opt_pass $opt_update $opt_delimiter $opt_file $opt_help);
use Getopt::Long;
&GetOptions(
    'host=s'      => \$opt_host,
    'dbase=s'     => \$opt_dbase,
    'user=s'      => \$opt_user,
    'pass=s'      => \$opt_pass,
    'delimiter=s' => \$opt_delimiter,
    'file=s'      => \$opt_file,
    'update'      => \$opt_update,
    'help'        => \$opt_help,
);

my $user  = $opt_user || 'super_cron_user';
my $pass  = $opt_pass;
my $host  = $opt_host;
my $dbase = $opt_dbase;

my $delimiter = $opt_delimiter || '\t';
my $update = $opt_update;

my $user_file = $opt_file;
my $help      = $opt_help;

if ( !$pass ) {
    $pass = SDB::DBIO::get_password_from_file( -host => $host, -user => $user );
}

if ( !( $user && $host && $dbase && $user_file ) || $help ) {
    _help();
    exit();
}

my $template = {
    'Original_Source_ID' => {
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
    'Original_Amount' => {
        'option'    => 'optional',
        'lims_name' => 'Original_Amount',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Current_Amount' => {
        'option'    => 'optional',
        'lims_name' => 'Current_Amount',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Amount_Units' => {
        'option'    => 'optional',
        'lims_name' => 'Amount_Units',
        'table'     => 'Source',
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

    'Isolation_Method' => {
        'option'    => 'optional',
        'lims_name' => 'RNA_DNA_Isolation_Method',
        'table'     => 'RNA_DNA_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Isolation_Date' => {
        'option'    => 'optional',
        'lims_name' => 'RNA_DNA_Isolation_Date',
        'table'     => 'RNA_DNA_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },

    'Original_Concentration' => {
        'option'    => 'optional',
        'lims_name' => 'Concentration',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 1,
        'format'    => '',
    },
    'Original_Concentration_Units' => {
        'option'    => 'optional',
        'lims_name' => 'Concentration_Units',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 1,
        'format'    => '',
    },

    'BCCA_Number' => {
        'option'    => 'optional',
        'lims_name' => 'BCCA_Number',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 1,
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
    'Barcode_Label' => {
        'option'    => 'mandatory',
        'lims_name' => 'FK_Barcode_Label__ID',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Received_Date' => {
        'option'    => 'optional',
        'lims_name' => 'Received_Date',
        'table'     => 'Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },
    'Library_Name' => {
        'option'    => 'optional',
        'lims_name' => 'FK_Library__Name',
        'table'     => 'Library_Source',
        'lookup'    => 0,
        'attribute' => 0,
        'format'    => '',
    },

};

my $connection = SDB::DBIO->new( -dbase => $dbase, -host => $host, -user => $user, -password => $pass, -connect => 1 );
my $validator = Submission::File_Validator->new( -dbc => $connection );

my $msg;

my $file = $user_file;

if ($file) {

    my $file_string = $validator->clean_file( -file => $file );

    #my $template = $validator->create_template();
    my ( $failed, $error, $data ) = $validator->validate_submission( -string => $file_string, -delimiter => $delimiter, -template => $template );
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

sub _help {

    print <<HELP;

File:  atm_batch_submission.pl
####################

Options:
##########

  -host: database host. e.g., lims02
  -dbase: database name. e.g., sequence
  -user: database username. e.g., super_cron
  -pass: database password.
  -delimiter: delimiter in the submission file. default: \t
  -file: submission file name.
  -update: if specified, database will be updated
  -help: print this help

Examples:
##########

./atm_batch_submission.pl -host lims02 -dbase sequence -user super_cron -p **** -file /home/sequence/aldente/uploads/atm.txt -update

HELP

}
