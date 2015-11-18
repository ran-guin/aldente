#!/usr/local/bin/perl

##############################################################33
# <CONSTRUCTION>
# This script is to be used as a cron job to check if submissions to cghub go through. If they do, change the status of Metadata_Submissions and Analysis_Submission to Accepted
# and have the Metadata_Object reflect cghub state. This script should later be expanded to also sync Trace_Submissions, aka Metadata_Object of type 'Run'.
#

use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/custom";
use Data::Dumper;
use Getopt::Long;
use SDB::DBIO;
use RGTools::RGIO;
use XML::Simple;
use RGTools::Process_Monitor;

use SRA::Data_Submission;
use SRA::ArchiveIO;
use UUID::Tiny;
use List::MoreUtils;

use vars qw($opt_help $opt_host $opt_dbase $opt_user $opt_password $opt_v);

&GetOptions(
    'help=s'     => \$opt_help,
    'host=s'     => \$opt_host,
    'dbase=s'    => \$opt_dbase,
    'user=s'     => \$opt_user,
    'password=s' => \$opt_password,
    'version=s'  => \$opt_v
);

my $start_time = localtime();
my $help       = $opt_help;
my $host       = $opt_host || 'limsdev04';
my $dbase      = $opt_dbase || 'seqdev';
my $user       = $opt_user || 'aldente_admin';
my $pass       = $opt_password;
my $version    = $opt_v;

my $Report = Process_Monitor->new( -variation => $version );

if ($help) {
    _help();
    exit;
}

my $dbc = new SDB::DBIO(
    -host    => $host,
    -dbase   => $dbase,
    -user    => $user,
    -connect => 1,
);

my $Volume = SRA::Data_Submission->new( -dbc => $dbc );

my $fields = [ 'Analysis_MO.Metadata_Object_ID', 'Analysis_Submission.Analysis_Submission_ID', 'Analysis_File.Analysis_File_ID', 'Status.Status_Name', 'Analysis_MO.Unique_Identifier', 'Analysis_Status.Status_Name', ];

print "Getting valid Analysis_Submission entries\n";

my $AS_data = $Volume->get_Analysis_Submission_data(
    -fields             => $fields,
    -required_tables    => 'Organization',
    -condition          => "where Organization.Organization_Name = 'cgHub' and Status.Status_Name not in ('Rejected','Aborted') and Analysis_Status.Status_Name not in ('Rejected','Aborted')",
    -metadata_hierarchy => 'analysis',
    -key                => 'Analysis_MO.Metadata_Object_ID',
);

$fields = [ 'Metadata_Object.Metadata_Object_ID', 'Metadata_Submission.Metadata_Submission_ID', 'Status.Status_Name', 'Metadata_Object.Unique_Identifier', 'Metadata_Object.Alias', ];

print "Getting valid Metadata_Submission entries\n";

my $MS_data = $Volume->get_Metadata_Submission_data(
    -fields          => $fields,
    -required_tables => 'Organization',
    -condition       => "where Organization.Organization_Name = 'cgHub' and Metadata_Object.Object_Type = 'Analysis' and Status.Status_Name not in ('Rejected','Aborted')",
    -key             => 'Metadata_Object.Metadata_Object_ID',
);

my %cgHub_to_LIMS = SRA::ArchiveIO::cghub_lims_status();

my @valid_statuses = values %cgHub_to_LIMS;
my $valid_status_str = Cast_List( -to => 'string', -list => \@valid_statuses, -autoquote => 1 );

my %Status_data = $dbc->Table_retrieve(
    -table     => "Status",
    -fields    => [ "Status_ID", "Status_Name" ],
    -condition => "where Status_Type = 'Submission' and Status_Name in ($valid_status_str)",
);

my %status_id_of;

@status_id_of{ @{ $Status_data{Status_Name} } } = @{ $Status_data{Status_ID} };

print "Comparing and setting statuses\n";

while ( my ( $MO_id, $AS_attr ) = each(%$AS_data) ) {

    my @unique_submission_ids = List::MoreUtils::uniq( @{ $AS_attr->{'Analysis_Submission.Analysis_Submission_ID'} } );
    my @unique_analysis_files = List::MoreUtils::uniq( @{ $AS_attr->{'Analysis_File.Analysis_File_ID'} } );

    my $MS_attr = $MS_data->{$MO_id};
    my @unique_metadata_submission_ids;

    if ($MS_attr) {
        @unique_metadata_submission_ids = List::MoreUtils::uniq( @{ $MS_attr->{'Metadata_Submission.Metadata_Submission_ID'} } );
    }
    else {
        $Report->set_Error("No Metadata_Submission_ID associated with Metadata_Object_ID $MO_id\n");
    }

    my $analysis_id;

    if ( scalar( @unique_submission_ids > 1 ) and scalar(@unique_analysis_files) == 1 ) {
        my $error_str =  "Multiple valid attempts to submit Metadata_Object_ID $MO_id in Analysis_Submission_IDs: ", join( ',', @unique_submission_ids ), "; all but 1 should be rejected/aborted";
        $Report->set_Error( $error_str );
    }
    elsif ( scalar(@unique_metadata_submission_ids) > 1 ) {
        my $error_str = "Multiple valid attempts to submit metadata for Metadata_Object_ID $MO_id in Metadata_Submission_IDs: ", join( ',', @unique_metadata_submission_ids ), "; all but 1 should be rejected/aborted";
        $Report->set_Error( $error_str );
    }
    else {
        $analysis_id = $AS_attr->{'Analysis_MO.Unique_Identifier'}->[0];

        if ( $analysis_id and UUID::Tiny::is_uuid_string($analysis_id) ) {
            my $cgHub_XML = SRA::ArchiveIO::download_cgHub_metadata( -analysis_id => $analysis_id );
            my $analysis_metadata = XMLin($cgHub_XML);

            $analysis_metadata = $analysis_metadata->{Result};
            my $state = $analysis_metadata->{state};

            if ($state) {

                my $LIMS_state = $cgHub_to_LIMS{$state};
                my $status_id  = $status_id_of{$LIMS_state};

                ###
                ### Setting analysis submission states
                ###

                my @analysis_submission_ids      = @{ $AS_attr->{'Analysis_Submission.Analysis_Submission_ID'} };
                my @analysis_submission_statuses = @{ $AS_attr->{'Status.Status_Name'} };

                my $iterator = List::MoreUtils::each_array( @analysis_submission_ids, @analysis_submission_statuses );
                while ( my ( $AS_id, $AS_status ) = $iterator->() ) {
                    if ( $AS_status ne $LIMS_state ) {

                        $Report->set_Message("Analysis_Submission_ID: $AS_id;\tchange $AS_status -> $LIMS_state");

                        my $records_updated = $dbc->Table_update_array(
                            -table     => "Analysis_Submission",
                            -fields    => ['FK_Status__ID'],
                            -values    => [$status_id],
                            -condition => "where Analysis_Submission_ID = $AS_id",
                        );

                        if ( $records_updated == 1 ) {
                            $Report->set_Message("Update successful");
                        }
                        else {
                            $Report->set_Error("Update failed");
                        }
                    }
                }

                ###
                ### Setting metadata object state
                ###

                my $MO_status = $AS_attr->{'Analysis_Status.Status_Name'}->[0];

                if ( $MO_status ne $LIMS_state ) {
                    $Report->set_Message("Metadata_Object_ID: $MO_id;\tchange $MO_status -> $LIMS_state");

                    my $records_updated = $dbc->Table_update_array(
                        -table     => "Metadata_Object",
                        -fields    => ['FK_Status__ID'],
                        -values    => [$status_id],
                        -condition => "where Metadata_Object_ID = $MO_id",
                    );

                    if ( $records_updated == 1 ) {
                        $Report->set_Message("Update successful");
                    }
                    else {
                        $Report->set_Error("Update failed");
                    }
                }

                ###
                ### Setting metadata submission state
                ###

                my ( $MS_id, $MS_status );

                if ($MS_attr) {
                    $MS_id     = $MS_attr->{'Metadata_Submission.Metadata_Submission_ID'}->[0];
                    $MS_status = $MS_attr->{'Status.Status_Name'}->[0];

                    if ( $MS_status ne $LIMS_state ) {
                        $Report->set_Message("Metadata_Submission_ID: $MS_id;\tchange $MS_status -> $LIMS_state");

                        my $records_updated = $dbc->Table_update_array(
                            -table     => "Metadata_Submission",
                            -fields    => ['FK_Status__ID'],
                            -values    => [$status_id],
                            -condition => "where Metadata_Submission_ID = $MS_id",
                        );

                        if ( $records_updated == 1 ) {
                            $Report->set_Message("Update successful");
                        }
                        else {
                            $Report->set_Error("Update failed");
                        }
                    }
                }

            }

            else {
                $Report->set_Error("No cgHub state info found for analysis ID $analysis_id from Metadata_Object_ID $MO_id");
            }

        }

        else {
            $Report->set_Error("Metadata_Object_ID $MO_id has non-UUID analysis ID: $analysis_id");
        }
    }

}

$Report->completed();
$Report->DESTROY();

#######################
sub _help {
#######################
    print <<END;

     File:  cghub_diff.pl
     ###################
     Cross references LIMS and CGHub databases to check if all Lims submissions are in fact up to date. 
     
     Usage:
     ###################
     	cghub_diff.pl # no parametres will default to limsdev04 seqdev DB for testing
        cghub_diff.pl -user <viewer> -pass <viewer> -host <limsdev04> -dbase <seqdev>
	
END
    return;
}

