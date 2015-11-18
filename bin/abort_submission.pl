#!/usr/local/bin/perl

use strict;

#use warnings;

use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../custom/GSC/modules";

use RGTools::RGIO;
use RGTools::RGmath;
use SDB::CustomSettings;
use SDB::DBIO;
use SRA::Data_Submission;

our ( $opt_help, $opt_volume_name, $opt_volume_id, $opt_delete, $opt_library, $opt_host, $opt_dbase );

###
### The tables need to be deleted in a certain order so that all referencing FK's
### are deleted first
###

my @TABLE_DELETION_ORDER = qw/Analysis_Link Run_Link Experiment_Link Metadata_Submission Analysis_Submission Analysis_File/;

&GetOptions(
    'help|h|?'      => \$opt_help,
    'volume_name=s' => \$opt_volume_name,
    'volume_id=s'   => \$opt_volume_id,
    'delete|d'      => \$opt_delete,
    'lib|library=s' => \$opt_library,
    'host=s'        => \$opt_host,
    'dbase=s'       => \$opt_dbase,
);

my $help        = $opt_help;
my $volume_name = $opt_volume_name;
my $volume_id   = $opt_volume_id;
my $delete      = $opt_delete;
my $library     = $opt_library;
my $host        = $opt_host || 'limsdev04';
my $dbase       = $opt_dbase || 'seqdev';

if ($help) {
    &display_help();
    exit;
}

my $login_name = 'aldente_admin';
my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name, -connect => 1 );

my $Submission_Volume = SRA::Data_Submission->new( -dbc => $dbc );

if ($volume_id) {
    $Submission_Volume->set_pk_value( -value => $volume_id );
}
elsif ($volume_name) {
    $Submission_Volume->set_field_value( -values => { Volume_Name => $volume_name } );
}
else {
    print "Error: Need to supply submission volume ID or name\n";
    exit;
}

my @volume_fields = ( 'Submission_Volume.Submission_Volume_ID', 'Submission_Volume.Volume_Name', 'Organization.Organization_Name', 'Submission_Template.Template_Name', );

my $Volume_data = $Submission_Volume->get_Volume_data( -fields => \@volume_fields );

my $Volume_name     = Cast_List( -to => 'string', -list => $Volume_data->{'Submission_Volume.Volume_Name'} );
my $Volume_id       = Cast_List( -to => 'string', -list => $Volume_data->{'Submission_Volume.Submission_Volume_ID'} );
my $Volume_template = Cast_List( -to => 'string', -list => $Volume_data->{'Submission_Template.Template_Name'} );
my $Volume_archive  = Cast_List( -to => 'string', -list => $Volume_data->{'Organization.Organization_Name'} );

####
#### Filtering items to remove
####

my @required_tables;
my @conditions = ('1');

if ($library) {
    my $quoted_libs = RGTools::RGIO::autoquote_string($library);
    push @required_tables, "Library";
    push @conditions,      "Library.Library_Name in ($quoted_libs)";
}

my $condition = "WHERE " . join( ' AND ', @conditions );

my %data_to_delete;

my @analysis_input_fields = ( 'Analysis_Submission.Analysis_Submission_ID', 'Analysis_File.Analysis_File_ID', 'Analysis_MO.Metadata_Object_ID', 'Analysis_MO.Alias', 'Analysis_MO.Unique_Identifier', 'Analysis_Link.Analysis_Link_ID', );

my $analysis_data = $Submission_Volume->get_Volume_analyses(
    -fields             => \@analysis_input_fields,
    -required_tables    => \@required_tables,
    -condition          => $condition,
    -metadata_hierarchy => 'analysis',
);

my @run_input_fields = (
    'Analysis_Submission.Analysis_Submission_ID', 'Sample_MO.Metadata_Object_ID', 'Sample_MO.Alias', 'Experiment_MO.Metadata_Object_ID',
    'Experiment_MO.Alias',                        'Run_MO.Metadata_Object_ID',    'Run_MO.Alias',    'Experiment_Link.Experiment_Link_ID',
    'Run_Link.Run_Link_ID',
);

my $run_data = $Submission_Volume->get_Volume_analyses(
    -fields             => \@run_input_fields,
    -required_tables    => \@required_tables,
    -condition          => $condition,
    -metadata_hierarchy => 'run',
);

###
### This is to make sure nothing strange happened with either get_Volume_analyses call
### The Analysis_Submissions that are returned should always be the same, I'm just retrieving
### different sorts of related data.
###

my ( $intersec, $run_only, $analysis_only ) = RGmath::intersection( $run_data->{analysis_submission_id}, $analysis_data->{analysis_submission_id} );

my @run_only_array      = Cast_List( -to => 'array', -list => $run_only );
my @analysis_only_array = Cast_List( -to => 'array', -list => $analysis_only );

if ( scalar(@run_only_array) > 0 or scalar(@analysis_only_array) > 0 ) {
    print "ERROR: Run data call and analysis data call return different analysis submissions!!\n";
    print "Run only:";
    print Dumper $run_only;
    print "Analysis only:";
    print Dumper $analysis_only;
    exit;
}

my @fields_to_change;

if ($delete) {
    @fields_to_change = (
        'Analysis_Submission.Analysis_Submission_ID', 'Analysis_File.Analysis_File_ID', 'Experiment_MO.Metadata_Object_ID', 'Run_MO.Metadata_Object_ID',
        'Experiment_Link.Experiment_Link_ID',         'Run_Link.Run_Link_ID',           'Analysis_MO.Metadata_Object_ID',   'Analysis_Link.Analysis_Link_ID',
    );
}
else {
    @fields_to_change = ( 'Analysis_Submission.Analysis_Submission_ID', 'Experiment_MO.Metadata_Object_ID', 'Run_MO.Metadata_Object_ID', 'Analysis_MO.Metadata_Object_ID', );
}

my %data_to_modify;

foreach my $input_field (@fields_to_change) {
    $input_field =~ /(\w+)\.(\w+)/i;

    my $table = $1;
    my $field = $2;

    my $data_ref = $run_data->{$input_field} || $analysis_data->{$input_field};
    my @unique_data_values = List::MoreUtils::uniq( @{$data_ref} );

    if ( $table =~ /^(\w+?)_MO$/ and $field eq 'Metadata_Object_ID' ) {

        my $MO_data = $data_to_modify{Metadata_Object}{Metadata_Object_ID}         || [];
        my $MS_data = $data_to_modify{Metadata_Submission}{FK_Metadata_Object__ID} || [];

        push @{$MO_data}, @unique_data_values;
        push @{$MS_data}, @unique_data_values;

        $data_to_modify{Metadata_Object}{Metadata_Object_ID}         = $MO_data;
        $data_to_modify{Metadata_Submission}{FK_Metadata_Object__ID} = $MS_data;
    }

    else {
        $data_to_modify{$table}{$field} = \@unique_data_values;
    }
}

print "\n";
print( $delete ? "Items to DELETE:\n" : "Items to ABORT:\n" );
print "-" x 16 . "\n";

foreach my $table ( keys %data_to_modify ) {

    my %field_hashes = %{ $data_to_modify{$table} };

    foreach my $field ( keys %field_hashes ) {
        my @field_values = Cast_List( -to => 'array', -list => $field_hashes{$field} );

        print "$table [$field]: " . join( ',', @field_values ) . "\n";
    }
}

my @dirs_to_delete;

if ( $Volume_archive eq 'cgHub' ) {

    print "\ncgHub directories to delete:\n";

    my @analysis_ids = Cast_List( -to => 'array', -list => $analysis_data->{'Analysis_MO.Unique_Identifier'} );

    my @unique_analysis_ids = List::MoreUtils::uniq(@analysis_ids);

    foreach my $analysis_id (@unique_analysis_ids) {

        my $dir = File::Spec->catdir( $Submission_Volume->{submission_dir}, 'cgHub', $analysis_id );
        print $dir. "\n";
        push @dirs_to_delete, $dir;
    }
}

print "\n";
my $confirm = RGTools::RGIO::Prompt_Input( -prompt => ( $delete ? "Delete" : "Abort" ) . " items Y/N ? ", -type => 'char' );

if ( $confirm =~ /^y/i ) {

    if ( $Volume_archive eq 'cgHub' ) {
        print "\nDeleting cgHub directories:\n";

        foreach my $analysis_dir (@dirs_to_delete) {
            File::Path::remove_tree( $analysis_dir, { verbose => 1 } );
        }
    }

    if ($delete) {
        foreach my $table (@TABLE_DELETION_ORDER) {

            my %field_hashes = (
                ref( $data_to_modify{$table} ) eq 'HASH'
                ? %{ $data_to_modify{$table} }
                : ()
            );

            my ($primary_field) = $dbc->get_field_info(
                -table => $table,
                -type  => 'Primary'
            );

            foreach my $field ( keys %field_hashes ) {

                ### Just for convenience, rows can only be
                ### deleted if the primary key is given

                if ( $field eq $primary_field ) {

                    my @field_values = Cast_List( -to => 'array', -list => $field_hashes{$field} );

                    my $ok = $dbc->delete_records(
                        -table   => $table,
                        -dfield  => $field,
                        -id_list => \@field_values,
                        -confirm => 1,
                    );
                }

            }
        }
    }
    else {
        my ($status_id) = $dbc->Table_find(
            -fields    => "Status_ID",
            -table     => "Status",
            -condition => "WHERE Status_Type = 'Submission' AND Status_Name = 'Aborted'",
        );

        foreach my $table ( keys %data_to_modify ) {

            my %field_hashes = %{ $data_to_modify{$table} };

            foreach my $field ( keys %field_hashes ) {

                my @field_values = Cast_List( -to => 'array', -list => $field_hashes{$field} );
                my $num_values = scalar(@field_values);

                my $quoted_values = Cast_List( -to => 'string', -list => \@field_values, -autoquote => 1 );

                my $num_update = $dbc->Table_update(
                    -table     => $table,
                    -fields    => 'FK_Status__ID',
                    -values    => $status_id,
                    -condition => "WHERE $field in ($quoted_values)",
                );

                if ( $num_update eq $num_values ) {
                    print "Successfully updated status of $num_update values in $table\n";
                }

                else {
                    print "ERROR: Updated $num_update values in $table, should have updated $num_values\n";
                }
            }
        }
    }

}

