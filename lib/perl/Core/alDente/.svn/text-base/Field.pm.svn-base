#!/usr/bin/perl
###################################################################################################################################
# Field.pm
#
###################################################################################################################################
package alDente::Field;

##############################
# perldoc_header             #
##############################

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use Data::Dumper;

#use Benchmark;

##############################
# custom_modules_ref         #
##############################
use alDente::Tools;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::HTML;
use SDB::DBIO;
use SDB::DB_Object;
use SDB::DB_Form_Viewer;
use SDB::DB_Form;
use SDB::Session;
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;
##############################
# global_vars                #
##############################
use vars qw( $user $table);
use vars qw($MenuSearch $scanner_mode %Settings $Connection);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################

### Global variables

### Modular variables

###########################
# Constructor of the object
###########################

##############################
# public_methods             #
##############################

##############################
# Home page for individual sources
##############################
sub home_page {

    my $field_id   = shift;
    my $field_name = shift;
    my $primary    = shift;
    my $table      = shift;

    my $summary_info = &view_info( $field_id, $field_name, $primary, $table );
    print "<BR>$summary_info<BR>";

    my $field_history = &view_history( $field_id, $field_name, $primary, $table );

    if ( !$field_history ) {
        Message("Field Change History not available");
    }

}

##############################
# view_info for each trackable field
##############################
sub view_info {

    my $dbc        = $Connection;
    my $field_id   = shift;
    my $field_name = shift;
    my $primary    = shift;
    my $table      = shift;

    my %info;
    if ($table) {
        %info = $dbc->Table_retrieve(
            'DBField,DBTable',
            [ 'DBTable_Name', 'Field_Name', 'Field_Description', 'Field_Alias', 'Field_Options', 'Editable', 'Tracked' ],
            "WHERE DBTable_Name = '$table' AND FK_DBTable__ID=DBTable_ID AND Field_Name = '$field_name'"
        );
    }
    else {

        %info = $dbc->Table_retrieve( 'DBField,DBTable', [ 'DBTable_Name', 'Field_Name', 'Field_Description', 'Field_Alias', 'Field_Options', 'Editable', 'Tracked' ], "WHERE DBField_ID = $field_id AND FK_DBTable__ID=DBTable_ID", -autoquote => 1 );
    }

    if ( exists $info{Field_Name}[0] ) {
        $table = $info{DBTable_Name}[0];
        my $description = $info{Field_Description}[0];
        my $alias       = $info{Field_Alias}[0];
        my $reference   = $info{Field_Reference}[0];
        my $editable    = $info{Editable}[0];
        my $tracked     = $info{Tracked}[0];
        my $foptions    = $info{Field_Options}[0];
        my $foptions_field;
        my $editable_field = $editable;
        my $tracked_field  = $tracked;
        my $desc_field     = $description;
        my @options        = ( 'yes', 'no' );
        my $update_btn     = '';
        my @fdefaults      = split ',', $foptions;
        print alDente::Form::start_alDente_form( $dbc, -form => 'field_details' );

        if ( $dbc->LIMS_admin() ) {
            $update_btn = submit( -name => 'Change Field Details', -label => "Update", -class => 'Action', -force => 1 );
            $update_btn .= hidden( -name => "field_id", value => "$field_id", -force => 1 );
            $desc_field = textarea( -name => 'field_description', -value => $description, -cols => 40, -rows => 2, -force => 1 );
            $foptions_field = checkbox_group(
                -name     => 'field_options',
                -values   => [ 'Hidden', 'Mandatory', 'Primary', 'Searchable', 'Unique', 'ViewLink', 'NewLink', 'Obsolete' ],
                -defaults => \@fdefaults,
                -force    => 1
            );
            $editable_field = radio_group( -name => 'field_editable', -values => [ 'yes', 'admin', 'no' ], -default => $editable, -force => 1 );
            $tracked_field = radio_group( -name => 'field_tracked', -values => \@options, -default => $tracked, -force => 1 );
        }

        my $Summary = HTML_Table->new( -width => 400 );
        $Summary->Toggle_Colour('off');
        $Summary->Set_Title( "Summary information for field \'$field_name\'", fsize => '-1' );
        $Summary->Set_Row( [ "<B>Alias: </B>",       $alias ] );
        $Summary->Set_Row( [ "<B>Reference: </B>",   $reference ] );
        $Summary->Set_Row( [ "<B>Table: </B>",       $table ] );
        $Summary->Set_Row( [ "<B>Description: </B>", $desc_field ] );
        $Summary->Set_Row( [ "<B>Options: </B>",     $foptions_field ] );
        $Summary->Set_Row( [ "<B>Editable: </B>",    $editable_field ] );
        $Summary->Set_Row( [ "<B>Tracked: </B>",     $tracked_field ] );
        $Summary->Set_Row( [$update_btn] );

        return $Summary->Printout(0);
        print end_form();
    }
    return "No information found for \'$field_name\'";

}

##############################
# view_all_changes for the record
##############################
sub view_history {
    my $dbc        = $Connection;
    my $field_id   = shift;
    my $field_name = shift;
    my $primary    = shift;
    my $table      = shift;

    if ($primary) {

        if ($table) {
            my $ok = $dbc->Table_retrieve_display(
                'Change_History, DBField, DBTable', [ 'Old_Value', 'New_Value', 'FK_Employee__ID', 'Modified_Date' ],
                "WHERE DBTable_Name = '$table' AND Field_Name = '$field_name' AND FK_DBTable__ID = DBTable_ID AND FK_DBField__ID = DBField_ID AND Record_ID = '$primary' ORDER BY Modified_Date DESC",
                -alt_message => "No history found for this field",
                -title       => "\'$field_name\' field change history for $table $primary"
            );
            if ($ok) {
                return 1;
            }
        }
        else {

            my $ok = $dbc->Table_retrieve_display(
                'Change_History', [ 'Old_Value', 'New_Value', 'FK_Employee__ID', 'Modified_Date' ],
                "WHERE FK_DBField__ID = $field_id AND Record_ID = '$primary' ORDER BY Modified_Date DESC",
                -autoquote   => 1,
                -alt_message => "No history found for this field",
                -title       => "\'$field_name\' field change history for $table $primary"
            );
            if ($ok) {
                return 1;
            }
        }
    }
    return 0;
}

##############################
# view_history for each trackable field
##############################
sub view_history_for_all {
    my $dbc     = $Connection;
    my $primary = shift;

    my $ok = $dbc->Table_retrieve_display(
        'Change_History,DBTable,DBField',
        [ 'DBTable_Name', 'Field_Name', 'Old_Value', 'New_Value', 'FK_Employee__ID', 'Modified_Date' ],
        "WHERE FK_DBTable__ID=DBTable_ID AND FK_DBField__ID=DBField_ID AND Record_ID='$primary' ORDER BY Field_Name,Modified_Date DESC",
        -autoquote   => 1,
        -alt_message => "No history found for this field",
        -title       => "Table edit history"
    );
    if ($ok) {
        return 1;
    }
    else {
        return 0;
    }
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################
return 1;
