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

use POSIX qw(strftime);
use SDB::DBIO;
use RGTools::RGIO;
use SDB::CustomSettings;
use SRA::ArchiveIO;

use File::Basename;
use XML::Simple;
use List::MoreUtils;

use vars qw(%Configs $opt_help $opt_host $opt_dbase $opt_user $opt_password $opt_run_dir_suffix $opt_quiet);

&GetOptions(
    'help|h|?'     => \$opt_help,
    'host=s'       => \$opt_host,
    'dbase|d=s'    => \$opt_dbase,
    'user|u=s'     => \$opt_user,
    'password|p=s' => \$opt_password,
    'quiet|q'      => \$opt_quiet,
);

my $help  = $opt_help;
my $host  = $opt_host || 'lims05';
my $dbase = $opt_dbase || 'sequence';
my $user  = $opt_user || 'super_cron';
my $pwd   = $opt_password;
my $quiet = $opt_quiet;

if ($help) {
    &display_help();
    exit;
}

my %annotation_classification_id_of = (
    Observation  => 1,
    Notification => 3,
    Redaction    => 5,
);

my $dbc = SDB::DBIO->new( -dbase => $dbase, -host => $host, -user => $user, -password => $pwd, -connect => 1 );

my ($aldente_employee_id) = $dbc->Table_find(
    -table     => 'Employee',
    -fields    => 'Employee_ID',
    -condition => "where Employee_Name = 'Admin'",
);

print '-' x 40, "\n";

### CenterNotification isn't included in the classifications that we download
### It is concerned with the QC of the sequence files generated, not information
### about the samples themselves
###
### Categories part of CenterNotification:
### - Center QC failed
### - Item flagged DNU

foreach my $annotation_classification ( keys %annotation_classification_id_of ) {

    my $annotation_classification_id = $annotation_classification_id_of{$annotation_classification};

    print "Downloading $annotation_classification XML metadata from DCC\n";

    my $annotation_XML = SRA::ArchiveIO::download_TCGA_annotation_metadata( -classificationId => $annotation_classification_id );
    my $annotation_hash = XMLin( $annotation_XML, ForceArray => [ 'dccAnnotation', 'notes' ] );

    ### $alert_reason_pk is the Alert_Reason primary key that identifies the particular
    ### alert reason, NOT the categoryId the DCC uses.

    my ( %alert_reason_pk_of, %alert_type_of );

    my %alert_reason_data = $dbc->Table_retrieve(
        -table     => "Alert_Reason",
        -fields    => [ 'Alert_Reason_ID', 'Alert_Type', 'Alert_Reason' ],
        -condition => "",
    );

    my $iterator = List::MoreUtils::each_arrayref( $alert_reason_data{'Alert_Reason_ID'}, $alert_reason_data{'Alert_Type'}, $alert_reason_data{'Alert_Reason'} );

    while ( my ( $alert_reason_id, $alert_type, $alert_reason ) = $iterator->() ) {
        $alert_reason_pk_of{$alert_reason} = $alert_reason_id;
    }

    ### Warning: There can be multiple annotations ID's for the exact same item
    ###
    ### Because you don't know in advance how many annotation ID's will be
    ### relevant for a source, you have to loop through all the annotations
    ### first, gather everything by source, and then loop through each source
    ### editing the DB
    ###
    ### Alert_Comments will contain all the relevant DCC notes, in annotation ID order

    my @annotation_ids = sort { $a <=> $b } keys %{ $annotation_hash->{dccAnnotation} };

    ### DB_source_alerts: all alerts existing in Source_Alert table
    ### WS_source_alerts: all alerts returned from DCC web service

    my ( %DB_source_alerts, %WS_source_alerts );

    print "Processing annotations\n";

    foreach my $annotation_id (@annotation_ids) {

        my $annotation = $annotation_hash->{dccAnnotation}->{$annotation_id};

        if ( $annotation->{approved} eq 'true' and $annotation->{rescinded} eq 'false' ) {

            ### Alert reason

            my $annotation_alert_reason = $annotation->{annotationCategory}->{categoryName};

            ### Alert type

            my $annotation_alert_type      = $annotation->{annotationCategory}->{annotationClassification}->{annotationClassificationName};
            my $annotation_alert_reason_pk = $alert_reason_pk_of{$annotation_alert_reason};

            ### Alert date

            my $annotation_date_created = $annotation->{dateCreated};

            ### Alert notes

            my $annotation_notes = $annotation->{notes};
            my @alert_note_texts;

            foreach my $note ( @{$annotation_notes} ) {

                my $note_text = $note->{noteText};

                ### Sometimes, the DCC annotation note will have unnecessary space characters
                ### Strip those out

                $note_text =~ s/\x{a0}//g;
                $note_text =~ s/^\s+//;
                $note_text =~ s/\s+$//;
                $note_text =~ s/[\r\n]+/ /g;

                push @alert_note_texts, $note_text;
            }

            my $note_string = join( ' | ', @alert_note_texts );

            ###
            ### Add new alert reason if it hasn't been used in the DB yet
            ###

            if ( !defined($annotation_alert_reason_pk) ) {
                my $new_id = $dbc->Table_append_array(
                    -table  => "Alert_Reason",
                    -fields => [ 'Alert_Reason', 'Alert_Type' ],
                    -values => [ "'$annotation_alert_reason'", "'$annotation_alert_type'" ],
                );

                $alert_reason_pk_of{$annotation_alert_reason} = $new_id;
                $alert_type_of{$new_id}                       = $annotation_alert_type;

                $annotation_alert_reason_pk = $new_id;
            }

            my $barcode = $annotation->{items}->{item};

            my %source_data = $dbc->Table_retrieve(
                -table     => "Source LEFT JOIN Source_Alert ON Source_Alert.FK_Source__ID = Source_ID",
                -fields    => [ 'Source_ID', 'FK_Alert_Reason__ID', 'Alert_Comments' ],
                -condition => "where External_Identifier like '$barcode%'",
                -distinct  => 1,
            );

            ### If the annotation barcode matches any Sources we have...

            if (%source_data) {

                my @source_ids           = @{ $source_data{'Source_ID'} };
                my @fk_alert_reason__ids = @{ $source_data{'FK_Alert_Reason__ID'} };
                my @alert_comments       = @{ $source_data{'Alert_Comments'} };

                ### Gather all existing DB alerts for the relevant sources

                my $iterator = List::MoreUtils::each_array( @source_ids, @fk_alert_reason__ids, @alert_comments, );

                while ( my ( $source_id, $fk_alert_reason__id, $alert_comments ) = $iterator->() ) {

                    if ( defined($fk_alert_reason__id) ) {
                        $DB_source_alerts{$source_id}{$fk_alert_reason__id}{'comments'} = $alert_comments;
                    }

                }

                ### Map the web service alerts to the right source ID's

                foreach my $source_id ( List::MoreUtils::uniq(@source_ids) ) {

                    if ( defined( $WS_source_alerts{$source_id}{$annotation_alert_reason_pk}{'comments'} ) ) {
                        push @{ $WS_source_alerts{$source_id}{$annotation_alert_reason_pk}{'comments'} }, $note_string;
                    }
                    else {
                        $WS_source_alerts{$source_id}{$annotation_alert_reason_pk}{'comments'} = [$note_string];
                    }

                    $WS_source_alerts{$source_id}{$annotation_alert_reason_pk}{'date'}         = $annotation_date_created;
                    $WS_source_alerts{$source_id}{$annotation_alert_reason_pk}{'alert reason'} = $annotation_alert_reason;
                    $WS_source_alerts{$source_id}{$annotation_alert_reason_pk}{'alert type'}   = $annotation_alert_type;
                }

            }
        }

    }    ### End loop annotation ids

    foreach my $source_id ( keys %WS_source_alerts ) {
        foreach my $alert_reason_pk ( keys %{ $WS_source_alerts{$source_id} } ) {

            ### Processing comments

            my $WS_comments = join( ' | ', List::MoreUtils::uniq( @{ $WS_source_alerts{$source_id}{$alert_reason_pk}{'comments'} } ) );

            my $sql_comment_string = $WS_comments;
            $sql_comment_string =~ s/'/\\'/g;

            ### Processing date

            my $WS_date = $WS_source_alerts{$source_id}{$alert_reason_pk}{'date'};
            my ( $date, $timezone, $sql_date_string );

            if ( $WS_date =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(.*)$/ ) {

                $date            = strftime( "%Y-%m-%d %H:%M:%S", $6, $5, $4, $3, $2 - 1, $1 - 1900 );
                $timezone        = $7;
                $sql_date_string = "CONVERT_TZ('$date', '$timezone', 'SYSTEM')";
            }
            else {
                $sql_date_string = strftime( "%Y-%m-%d %H:%M:%S", localtime );
            }

            ### Getting alert attributes

            my $WS_alert_type   = $WS_source_alerts{$source_id}{$alert_reason_pk}{'alert type'};
            my $WS_alert_reason = $WS_source_alerts{$source_id}{$alert_reason_pk}{'alert reason'};

            ### Check if the alert entry already exists in the DB

            my $DB_comments = undef;

            if ( defined( $DB_source_alerts{$source_id} ) and defined( $DB_source_alerts{$source_id}{$alert_reason_pk} ) ) {
                $DB_comments = $DB_source_alerts{$source_id}{$alert_reason_pk}{'comments'};
            }

            if ( !defined($DB_comments) ) {
                ### Using manual SQL insert instead of Table_append because:
                ###
                ### - No datetime manipulation modules are installed, so date conversion can't be done easily/correctly in Perl
                ### - The CONVERT_TZ function in the date value gets clobbered in Table_append

                my $table  = "Source_Alert";
                my $fields = "FK_Source__ID,Alert_Type,FK_Alert_Reason__ID,FK_Employee__ID,Alert_Notification_Date,Alert_Comments";
                my $values = "$source_id, '$WS_alert_type', $alert_reason_pk, $aldente_employee_id, $sql_date_string, '$sql_comment_string'";

                my $query = "INSERT INTO $table ($fields) VALUES ($values)";

                print "Source $source_id: Inserting reason: $WS_alert_reason\n";
                print "Note text: ", $sql_comment_string, "\n";

                my $dbh            = $dbc->{dbh};
                my $num_rows_added = $dbh->do($query);

                if ( !defined($num_rows_added) ) {
                    print $dbh->errstr, "\n";
                }
                elsif ( $num_rows_added == 1 ) {
                    print "Insert successful\n";
                }
                else {
                    print "$num_rows_added rows added; insert unsuccessful\n";
                }

                print '-' x 10, "\n";
            }
            elsif ( $DB_comments ne $WS_comments ) {
                my $table = "Source_Alert";
                my $field = "Alert_Comments";
                my $value = "'$sql_comment_string'";

                ### Using manual SQL update instead of Table_update because:
                ### - even though Alert_Comments is 'text' in the DB schema, Table_update enforces an arbitrary 255 character limit

                my $query = "UPDATE $table SET $field = $value WHERE FK_Source__ID = $source_id AND FK_Alert_Reason__ID = $alert_reason_pk";

                print "Source $source_id, Alert reason: $WS_alert_reason,\n";
                print "Changing note text to: ", $sql_comment_string, "\n";

                my $dbh              = $dbc->{dbh};
                my $num_rows_changed = $dbh->do($query);

                if ( !defined($num_rows_changed) ) {
                    print $dbh->errstr, "\n";
                }
                elsif ( $num_rows_changed == 1 ) {
                    print "Update successful\n";
                }
                else {
                    print "$num_rows_changed rows added; check update\n";
                }

                print '-' x 10, "\n";
            }
        }
    }

    print '-' x 40, "\n";
}

exit;

##################
sub display_help {
##################
    print <<HELP;

Syntax
======
update_source_alert.pl - This script retrieves TCGA annotations and updates the Source_Alert table with this info

Arguments:
=====

-- required arguments --
-host           : specify database host, ie: -host limsdev02 
-dbase, -d      : specify database, ie: -d seqdev. 
-user, -u       : specify database user. 

-- optional arguments --
-help, -h, -?		: displays this help. (optional)

Example
=======
update_source_alert.pl -host lims05 -dbase sequence -user super_cron


HELP

}
