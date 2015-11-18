#!/usr/local/bin/perl
################################################################################
# Container.pm
#
# This module handles Container (Plate) based functions
#
###############################################################################
package alDente::Container;

use base SDB::DB_Object;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Container.pm - This module handles Container (Plate) based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Container (Plate) based functions<BR>

=cut

##############################
# superclasses               #
##############################

#@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT_OK = qw(get_Children get_Parents Check_Library_Plates);

use strict;
##############################
# standard_modules_ref       #
##############################
use CGI::Carp('fatalsToBrowser');
use CGI qw(:standard);
use Data::Dumper;
use URI::Escape;
use RGTools::Barcode;
use Benchmark;

##############################
# custom_modules_ref         #
##############################
use alDente::Library;
use alDente::Barcoding;
use alDente::Form;
use alDente::SDB_Defaults;
use alDente::Solution;
use alDente::Plate_Prep;
use alDente::Protocol;
use alDente::Prep;
use alDente::Container_Set;
use alDente::Tools;
use alDente::Rack;
use alDente::Rack_Views;
use alDente::Invoiceable_Work;
use alDente::Prep;    ## cleans up looping usage calls

#use alDente::Protocol;
use alDente::Fail;
use alDente::Validation;
use SDB::DB_Object;
use SDB::Session;
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::DB_Form_Viewer;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;

use LampLite::Bootstrap;
##############################
# global_vars                #
##############################
use vars qw($current_plates $plate_set $plate_id $Sess);
use vars qw(@plate_formats @plate_info @plate_sizes @libraries $Connection %Std_Parameters $image_dir @protocols);

#use vars qw(%Plate_Contents);
use vars qw(%Benchmark %Prefix);

my $BS = new Bootstrap();
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

my $prefix = $Prefix{Plate};

############
sub new {
############
    # Constructor
    #
    my $this = shift;
    my %args = @_;

    my $id         = $args{-id} || $args{-plate_id};
    my $type       = $args{-type};                          ## type of Plate (ie Tube or Library_Plate)
    my $type_id    = $args{-type_id};                       ## id of subtype if supplied instead...
    my $table      = $args{-table} || 'Plate';
    my $tables     = $args{-tables} || 'Plate';
    my $FK_tables  = $args{-FK_tables} || 'Plate_Format';
    my $quick_load = $args{-quick_load};                    ## ignore child tables, left joins for now.

    my $dbc = $args{-dbc} || $args{-connection} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $attributes = $args{-attributes};                    ## allow inclusion of attributes for new record

    if ( $type_id && $type ) {                              ## or get id based on type & type_id...
        ($id) = $dbc->Table_find( "Plate,$type", 'Plate_ID', "where FK_Plate__ID=Plate_ID AND $type" . "_ID in ($type_id)" );
    }
    elsif ($id) {
        ($type) = $dbc->Table_find( 'Plate', 'Plate_Type', "WHERE Plate_ID in ($id)" );

        if ($type) {
            ($type_id) = $dbc->Table_find( $type, "${type}_ID", "where FK_Plate__ID in ($id)" );
        }
        else {
            $dbc->warning("Container $id record appears to be missing or incomplete (?)");
        }
    }
    my $frozen  = $args{-frozen}  || 0;
    my $encoded = $args{-encoded} || 0;    ## reference to encoded object (frozen)
    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => $tables, -FK_tables => $FK_tables, -frozen => $frozen, -encoded => $encoded );

    my ($class) = ref($this) || $this;

    bless $self, $class;
    $self->{dbc} = $dbc;

    if ( $id =~ /(\d+),/ ) { $self->{list} = $id; $id = $1; }    ## get the first in the list if more than one...
    $self->{prefix} = $Prefix{'Plate'};

    ### Customizable settings ##
    $self->{Tabs} = {
        'Links'     => 1,
        'Summaries' => 1,
        'Extract'   => 0,
        'Transfer'  => 1,
        'Ancestry'  => 1,
        'Data'      => 1,
    };

    if ( $encoded || $frozen ) { return $self }

    if ($id) {
        $self->{id}       = $id;        ## generic attribute ##
        $self->{plate_id} = $id;        ## list of current plate_ids
        $self->{type}     = $type;
        $self->{type_id}  = $type_id;
        $self->primary_value( -table => 'Plate', -value => $id );    ## same thing as above..
        $self->load_Object( -quick_load => $quick_load );
    }
    elsif ($attributes) {
        $self->add_Record( -attributes => $attributes );
    }

    return $self;
}

################################
sub plate_QC_trigger {
################################
    my %args = &filter_input( \@_, -args => 'dbc,id' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my ($status) = $dbc->Table_find( 'Plate', 'QC_Status', "WHERE Plate_ID = $id" );
    my $children = get_Children( -plate_id => $id, -dbc => $dbc, -format => 'list' );

    if ( $status eq 'Failed' && $children ) {
        my $link = &Link_To( $dbc->config('homelink'), "Details", "&cgi_application=alDente::Container_App&ID=$children", 'red', ['newwin'] );
        $dbc->message("Setting QC status to Failed for the following daughter plates: $children $link");
        my $ok = $dbc->Table_update_array( 'Plate', ['QC_Status'], ['Failed'], "WHERE Plate_ID IN ($children)", -no_triggers => 1, -autoquote => 1 );
        return $ok;
    }
    else {
        if ($children) {
            my $count = int( split ',', $children );
            my $link = &Link_To( $dbc->config('homelink'), "$count plates", "&cgi_application=alDente::Container_App&rm=default&ID=$children", 'red', ['newwin'] );
            $dbc->warning("The QC Status for these daughter plates remains unchanged $link");
            return 1;
        }
        else {
            return 1;
        }
    }
}

################################
sub reset_current_plates {
################################
    my %args = &filter_input( \@_, -args => 'dbc,current_plates,plate_set' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-current_plates};
    my $set  = $args{-plate_set};

    my @ids = Cast_List( -list => $id, -to => 'array' );
    $dbc->{current_plates} = \@ids;
    $dbc->{plate_set}      = $set;

    ## temporarily maintain globals until fully phased out.. ##
    $current_plates = join ',', @ids;
    $plate_set = $set;

    return \@ids;
}

################################
sub add_to_current_plates {
################################
    my $dbc = shift;
    my $id  = shift;

    my @ids = Cast_List( -list => $id, -to => 'array' );

    push @{ $dbc->{current_plates} }, @ids;
    return $dbc->{current_plates};
}

#
# Extractor for Plate/Container prefix
#
#############
sub prefix {
#############
    my $self = shift;
    return $self->{prefix};
}

################################
sub batch_Aliquot {
################################
    my %args     = &filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $ids      = $args{-ids};
    my $label    = $args{-label};
    my $pipeline = $args{-pipeline};
    my $format   = $args{'-format'};
    my $values   = $args{ -values };
    my $type     = $args{-type};
    my @ids      = split ',', $ids;
    my $count    = @ids;
    my @new_ids;

    for my $index ( 0 .. $count - 1 ) {
        my $plate_id = $ids[$index];
        my $new_id   = Aliquot_Container(
            -dbc      => $dbc,
            -volume   => $values->{Current_Volume}{$plate_id},
            -units    => $values->{Current_Volume_Units}{$plate_id},
            -format   => $format,
            -pipeline => $pipeline,
            -label    => $label,
            -id       => $ids[$index],
        );
        push @new_ids, $new_id;
    }

    return @new_ids;

}

################################
sub Aliquot_Container {
################################
    my %args              = &filter_input( \@_ );
    my $dbc               = $args{-dbc};
    my $id                = $args{-id};
    my $label             = $args{-label};
    my $pipeline          = $args{-pipeline};
    my $format            = $args{'-format'};
    my $units             = $args{-units};
    my $volume            = $args{-volume};
    my $type              = $args{-type};
    my $ignore_attributes = $args{-ignore_attributes};
    my ($temp_rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name = 'Temporary'" );
    my $user_id = $dbc->get_local('user_id');

    my @fields = ( 'Plate_Number', 'QC_Status', 'Plate_Label', 'FKLast_Prep__ID', 'FKParent_Plate__ID', 'Plate_Status', 'Failed', 'Current_Volume', 'Current_Volume_Units', 'FK_Rack__ID', 'FK_Employee__ID' );
    my @values = ( '', 'N/A', $label, '', $id, 'Active', 'No', $volume, $units, $temp_rack, $user_id );

    unless ($type) {
        ($type) = $dbc->Table_find( 'Plate', 'Plate_Type', "WHERE Plate_ID = $id", -distinct => 1 );
    }
    if ($pipeline) {
        my ($pipeline_id) = $dbc->get_FK_ID( -field => 'FK_Pipeline__ID', -value => $pipeline );
        push @values, $pipeline_id;
        push @fields, 'FK_Pipeline__ID';

    }
    if ($format) {
        my ($format) = $dbc->get_FK_ID( -field => 'FK_Plate_Format__ID', -value => $format );
        push @values, $format;
        push @fields, 'FK_Plate_Format__ID';

    }
    ( my $new_id, my $copy_time ) = $dbc->Table_copy( -table => 'Plate', -condition => "where Plate_ID = $id", -time_stamp => 'Plate_Created', -exclude => \@fields, -replace => \@values, -ignore_attributes => $ignore_attributes );

    if ( $dbc->table_loaded($type) && $type ) {
        my ($primary_id) = $dbc->get_field_info( $type, undef, 'Primary' );
        my ($sec_id) = $dbc->Table_find( $type, $primary_id, "WHERE FK_Plate__ID = $id " );
        my @sec_fields = ( "$primary_id", 'FK_Plate__ID' );
        my @sec_values = ( '',            $new_id );
        ( my $new_secondary_id, my $copy_time ) = $dbc->Table_copy( -table => $type, -condition => "where $primary_id = $sec_id", -exclude => \@sec_fields, -replace => \@sec_values, -ignore_attributes );

    }

    return $new_id;
}

##############################
# update the Plate Number of a Plate
#
# $self->new_container_trigger();
#
#
##############################
sub new_container_trigger {
##############################
    my $self            = shift;
    my $starting_number = param('Starting Plate Number');
    my $dbc             = $self->{dbc};

    $self->load_Object( -quick_load => 1 );    ## -force=>1,   ## redundant ??

    if ( !$self->value('Plate.Plate_ID') ) {
        Message("Error loading simple plate object (requires Sample_Type, Plate_Format, Rack_ID, Library_Name references)");
        return 0;
    }

    #$self->inherit_attributes();	# this part has been moved to new_container_batch_trigger

    my $parent_id = $self->value('Plate.FKParent_Plate__ID');
    my $id = $self->{plate_id} || $self->value('Plate.Plate_ID');

    $self->update_plate_info( -number => $starting_number, -plate_id => $id );    ## also updates rack to default if it is not set.

    my $class   = $self->value('Plate.Plate_Class');
    my $rearray = ( $class =~ /(Rearray|Extraction|Oligo)/i );                    ## flag indicating that this is a rearray plate

    my $action_parameter = param('Plate_Action');
    my $pooling = ( $action_parameter eq 'Pool' );
    if ( $id && !$parent_id && !$rearray && !$pooling ) {
        ## ...previously checked for param('FormNav') ) {

        ## trigger applicable only for original plates only ... exclude rearray plates for now...##
        $self->SB_trigger();
    }

    if ( param('New Plate Contents') ) {
        ## if content type of plate is changing, prompt for new information ##
        my $new_type_id = param('FK_Sample_Type__ID');
        $self->load_Object( -force => 1 );

        my ($content) = $dbc->Table_find( 'Sample_Type', 'Sample_Type', "WHERE Sample_Type_ID = $new_type_id" );
        if ( $Configs{plateContent_tracking} ) {
            if ( grep /^$content$/, $dbc->DB_tables ) {
                ### only generate prompt if the sub table exists in the database ###
                print $self->prompt_for_content_details( $content, $id );
            }
        }
    }

    my $reset_current_plates = 0;    ## skips resetting of current_plates;
    if ( param('Protocol Step Name') =~ / out to / ) { $reset_current_plates = 0 }

    if ( $Sess->{session_id} ) {
        my $id = $self->value('Plate.Plate_ID');
        if ( $Sess->{homepage} =~ /^Plate=\d/i ) {
            ## append to list ##
            $Sess->{homepage} .= ",$id";
            if ($reset_current_plates) {
                alDente::Container::add_to_current_plates( $dbc, $id );
            }
        }
        else {
            $Sess->homepage("Plate=$id");
            if ($reset_current_plates) {
                alDente::Container::reset_current_plates( $dbc, $id );
            }
        }
    }

    ## Upgrade Library from 'Submitted' to 'In Production' if this is the first created plate ##
    my $lib = $self->value('Plate.FK_Library__Name');
    my ($lib_status) = $self->{dbc}->Table_find( 'Library', 'Library_Status', "WHERE Library_Name like '$lib'" );
    if ( $lib_status eq 'Submitted' ) {
        $self->{dbc}->Table_update_array( 'Library', ['Library_Status'], ['In Production'], "WHERE Library_Name like '$lib'", -autoquote => 1 );
        $dbc->message("Marked $lib as 'In Production'");
    }
    return 1;
}

##############################
# Batch trigger for new containers
#
# $self->new_container_batch_trigger();
#
#
##############################
sub new_container_batch_trigger {
##############################
    my %args = &filter_input( \@_, -args => 'dbc,id' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};                                # array ref

    &batch_inherit_attributes( -dbc => $dbc, -id => $id );

    return 1;
}

###############################
#
# Generic Plate Filter form
#
# - options:
#  -form => <form name>   (defaults to 'Plate_Filter')
#  -filter => <filter_list>  (eg "FK_Library__Name, FK_Pipeline__ID, Plate_Status")
#  -default => <hash of preset values> (eg {'FK_Library__Name' => ['AS001','AS002'], 'FK_Pipeline__ID = 4 })
#
# Note: Form is NOT started or ended within this method
#
# return: filter table (HTML)
#########################
sub plate_filter {
#########################
    my %args          = &filter_input( \@_ );
    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $display       = $args{-display};
    my $library       = $args{-library} || get_Table_Params( -field => 'FK_Library__Name', -dbc => $dbc );
    my $pipeline      = $args{-pipeline} || get_Table_Params( -field => 'FK_Pipeline__ID', -dbc => $dbc );
    my $status        = $args{-status} || get_Table_Params( -field => 'Plate_Status', -default => 'Active', -dbc => $dbc );
    my $failed        = $args{-failed} || get_Table_Params( -field => 'Failed', -default => 'No', -dbc => $dbc );
    my $format        = $args{'-format'} || get_Table_Params( -field => 'FK_Plate_Format__ID', -dbc => $dbc );
    my $plate_numbers = $args{-plate_numbers} || get_Table_Params( -field => 'Plate_Number', -dbc => $dbc );
    my $form          = $args{-form} || 'Plate_Filter';
    my $buttons       = $args{-buttons};
    my $title         = $args{-title};
    my $filter        = $args{-filter} || 'Pipeline, Library, Project, Failed, Status';

    my @plate_filters;

    if ( $filter =~ /\bPipeline\b/i ) {
        push @plate_filters, 'Plate.FK_Pipeline__ID';
    }
    if ( $filter =~ /\bPlate_Created\b/ ) {
        push @plate_filters, 'Plate.Plate_Created';
    }
    if ( $filter =~ /\bLibrary\b/i ) {
        push @plate_filters, 'Plate.FK_Library__Name';
    }
    if ( $filter =~ /\bPlate_Number\b/ ) {
        push @plate_filters, 'Plate.Plate_Number';
    }
    if ( $filter =~ /\bFailed\b/i ) {
        push @plate_filters, 'Plate.Failed';
    }
    if ( $filter =~ /\bStatus\b/i ) {
        push @plate_filters, 'Plate.Plate_Status';
    }
    if ( $filter =~ /\bProject\b/ ) {
        push @plate_filters, 'Library.FK_Project__ID';
    }
    if ( $filter =~ /\bPlate_Format\b/ ) {
        push @plate_filters, 'Plate.FK_Plate_Format__ID';
    }

    my $preset = {
        'Plate_Status'        => $status,
        'Failed'              => $failed,
        'FK_Pipeline__ID'     => $pipeline,
        'Plate_Number',       => $plate_numbers,
        'FK_Library__Name'    => $library,
        'FK_Plate_Format__ID' => $format,
    };

    my $plate_filters = new SDB::DB_Form( -dbc => $dbc, -wrap => 0, -fields => \@plate_filters );
    $plate_filters->configure( -preset => $preset );
    my $filter_form = $plate_filters->generate(
        -return_html    => 1,
        -action         => 'search',
        -title          => "Select Filtering Criteria",
        -filter_by_dept => 1,
        -navigator_on   => 0
    );

    my $filter_table = HTML_Table->new( -title => $title );
    $filter_table->Set_Row( [$filter_form] );
    if ($buttons) {
        foreach my $button (@$buttons) {
            $filter_table->Set_Row( [$button] );
        }
    }

    my $filter_page = lbr();
    $filter_page .= $filter_table->Printout(0);

    $filter_page .= hr() . $display if $display;

    return $filter_page;
}

##########################
#
# Use plate_filter input to generate SQL conditions
#
# Return: list of Conditions
#####################
sub parse_plate_filter {
#####################
    my $dbc             = shift;
    my $library         = get_Table_Params( -field => 'FK_Library__Name', -table => 'Plate', -dbc => $dbc );
    my $plate_numbers   = param('Plate_Number') || param('Plate Numbers') || param('Plate Number');
    my $group_name_list = get_Table_Params( -field => 'FK_Grp__ID', -table => 'Library', -dbc => $dbc );
    my $status          = get_Table_Params( -field => 'Plate_Status', -table => 'Plate', -dbc => $dbc );
    my $failed          = get_Table_Params( -field => 'Failed', -table => 'Plate', -dbc => $dbc );
    my $format_id       = get_Table_Params( -field => 'FK_Plate_Format__ID', -dbc => $dbc );
    my $project         = get_Table_Params( -field => 'FK_Project__ID', -table => 'Library', -dbc => $dbc );
    my $pipeline_id     = get_Table_Params( -field => 'FK_Pipeline__ID', -table => 'Plate', -dbc => $dbc );
    my $protocol_id     = param('Protocol_ID') || param('FK_Lab_Protocol__ID') || 0;
    my $ids             = join ',', @{ $dbc->{current_plates} } if $dbc->{current_plates};
    my $days_ago        = param('Days_Ago');
    my @group_list_array;

    if ( !$ids ) { $ids = join ',', param('FK_Plate__ID') }

    my @conditions;

    ## parse group ##
    my $group_list;
    $group_list = $dbc->get_FK_ID( 'FK_Grp__ID', $group_name_list ) if $group_name_list;
    my $group_options;
    $group_options = Cast_List( -list => $group_list, -to => 'string' ) if $group_list;
    if ($group_options) {
        push @conditions, "Library.FK_Grp__ID IN ($group_options)";
    }

    ## parse library ##
    if ( $library =~ /\S/ ) { $library = $dbc->get_FK_ID( 'FK_Library__Name', $library ) }    ## convert if name supplied ##
    my $library_options;
    $library_options = Cast_List( -list => $library, -to => 'string', -autoquote => 1 ) if ( $library =~ /\S/ );
    if ($library_options) {
        push @conditions, "Plate.FK_Library__Name IN ($library_options)";
    }

    ## parse plate numbers ##
    if ($plate_numbers) {
        $plate_numbers = &extract_range($plate_numbers);
        push @conditions, "Plate.Plate_Number in ($plate_numbers)";
    }

    ## parse date range ##
    if ( $days_ago =~ /[1-9]/ ) {
        push @conditions, "Plate.Plate_Created > '" . &date_time("-${days_ago}d") . "'";
    }

    ## parse plate ids ##
    if ($ids) {
        push @conditions, "Plate.Plate_ID IN ($ids)";
    }

    ## parse protocol ##
    if ( $protocol_id =~ /[a-zA-Z]/ ) { $protocol_id = $dbc->get_FK_ID( 'FK_Protocol__ID', $protocol_id ) }    ## convert if name supplied ##
    my $protocol_options;
    $protocol_options = Cast_List( -list => $protocol_id, -to => 'string' ) if ( $protocol_id =~ /[1-9]/ );
    if ($protocol_options) {
        push @conditions, "Prep.FK_Lab_Protocol__ID IN ($protocol_options)";
    }

    ## parse project ##
    if ( $project =~ /[a-zA-Z]/ ) { $project = $dbc->get_FK_ID( 'FK_Project__ID', $project ) }                 ## convert if name supplied ##
    my $project_options;
    $project_options = Cast_List( -list => $project, -to => 'string' ) if ( $project =~ /[1-9]/ );
    if ($project_options) {
        push @conditions, "Library.FK_Project__ID IN ($project_options)";
    }

    ## parse pipeline ##
    if ( $pipeline_id =~ /[a-zA-Z]/ ) { $pipeline_id = $dbc->get_FK_ID( 'FK_Pipeline__ID', $pipeline_id ) }    ## convert if name supplied ##
    my $pipeline_options;
    $pipeline_options = Cast_List( -list => $pipeline_id, -to => 'string' ) if ( $pipeline_id =~ /[1-9]/ );
    if ($pipeline_options) {
        push @conditions, "Plate.FK_Pipeline__ID IN ($pipeline_options)";
    }

    ## parse status ##
    my $status_options;
    $status_options = Cast_List( -list => $status, -to => 'string', -autoquote => 1 ) if $status;
    if ($status_options) {
        push @conditions, "Plate.Plate_Status IN ($status_options)" if $status_options;
    }

    ## parse fail status ##
    my $failed_options;
    $failed_options = Cast_List( -list => $failed, -to => 'string', -autoquote => 1 ) if $failed;
    if ($failed_options) {
        push @conditions, "Plate.Failed IN ($failed_options)" if $failed_options;
    }

    ## parse format ##
    if ( $format_id =~ /[a-zA-Z]/ ) { $format_id = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $format_id ) }    ## convert if name supplied ##
    my $format_options;
    $format_options = Cast_List( -list => $format_id, -to => 'string' ) if ( $format_id =~ /[1-9]/ );
    if ($format_options) {
        push @conditions, "Plate.FK_Plate_Format__ID IN ($format_options)" if $format_options;
    }

    return @conditions;
}

##################################
sub prompt_for_content_details {
##################################
    my $self  = shift;
    my $type  = shift;
    my $plate = shift;

    my $dbc = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $current_plates = Cast_List( -list => param('Current Plates'), -to => 'string' );

    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $type, -target => 'Database', -start_form => 1, -end_form => 1, -form_name => 'Content_Info' );
    my %preset;
    $dbc->merge_data( -tables => "Plate,$type", -primary_list => $current_plates, -primary_field => 'Plate.Plate_ID', -preset => \%preset );
    $preset{'FK_Plate__ID'} = $plate;    ## over-ride reference to this plate.
    my $homepage = "Plate=$plate";
    $form->configure(
        -grey    => { 'FK_Plate__ID'     => $plate },
        -title   => 'Extraction Details',
        -preset  => \%preset,
        -include => { 'Session_homepage' => $homepage },
    );

    #		     -list=>\%list,-include=>\%include,-extra=>\%extra,-omit=>\%omit
    $form->generate();

    return;
}

####################
#
#
# load Plate object - sets DBobject attribute and loads object depending upon type. (eg Tube / Gel_Plate / Library_Plate)
#
# may be called given plate_id or plate_type (in which case the primary field in the associated table should already have been specified - allowing the object to be loaded directly)
#
###################
sub load_Object {
###################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'plate_id' );

    my $dbc      = $args{-dbc}      || $self->{dbc};
    my $type     = $args{-type}     || $self->{type};
    my $plate_id = $args{-plate_id} || $self->{plate_id};
    my $type_id  = $args{-type_id}  || $self->{type_id};

    my $quick_load = $args{-quick_load};    ## ignore child, left join tables
    my $debug      = $args{-debug};
    my $force      = $args{-force};

    if ( $type && ( $type ne 'Plate' ) && $type_id ) {
        ## if Tube type + id or Library_Plate + id supplied
        $plate_id = join ',', $dbc->Table_find( $type, 'FK_Plate__ID', "WHERE $type" . "_ID IN ($type_id)" );
        $self->{plate_id} = $plate_id if $plate_id;
        $self->{type} = $type

            #        $self->{"${type}_id"} = $type_id if $type_id;
            #        $self->{id} = $type_id if $type_id;
    }
    elsif ( $type && ( $type ne 'Plate' && $plate_id ) ) {
        ## if Tube type or Library_Plate, but original plate_ID is supplied ##
        $self->{plate_id} = $plate_id;
        my $type_id = join ',', $dbc->Table_find( $type, $type . '_ID', "WHERE FK_Plate__ID IN ($plate_id)" );
        $self->{type} = $type

            #        $self->{"${type}_id"} = $type_id if $type_id;
            #        $self->{id} = $type_id if $type_id;
    }

    unless ($type) {return}
    unless ($plate_id) {
        Message("Error: No id found for this container $plate_id(?)");
        Call_Stack();
        return 0;
    }
    $plate_id = get_aldente_id( $dbc, $plate_id, 'Plate' );

    if ( !$type ) {
        ($type) = $dbc->Table_find( 'Plate', 'Plate_Type', "WHERE Plate_ID IN ($plate_id)" );
    }

    my $content;
    if ( $Configs{plateContent_tracking} ) {
        ($content) = $dbc->Table_find( 'Plate,Sample_Type', 'Sample_Type', "WHERE FK_Sample_Type__ID=Sample_Type_ID AND Plate_ID IN ($plate_id)" );
    }

    my $additional_condition;
    unless ($quick_load) {
        $self->add_tables($type);
        $self->add_tables($content) if $content;

        if ( $type eq 'Tube' ) {
            my ($plate_parent_well) = $dbc->Table_find( 'Plate', 'Plate_Parent_Well', "WHERE Plate_ID IN ($self->{plate_id})" );
            $additional_condition .= "Plate_ID IN ($self->{plate_id}) AND Plate_Sample.Well = '$plate_parent_well'" if $plate_parent_well;
            $self->add_tables( 'Plate_Sample',    'Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID' );
            $self->add_tables( 'Sample',          'Plate_Sample.FK_Sample__ID=Sample_ID' );
            $self->add_tables( 'Source',          'Sample.FK_Source__ID=Source_ID' );
            $self->add_tables( 'Original_Source', 'Source.FK_Original_Source__ID=Original_Source_ID' );
            $self->add_tables( 'Library',         'Plate.FK_Library__Name=Library_Name' );
        }
        else {
            $self->add_tables( 'Library',         'Plate.FK_Library__Name=Library_Name' );
            $self->add_tables( 'Original_Source', 'Library.FK_Original_Source__ID=Original_Source_ID' );
        }
    }
    $self->add_tables( 'Plate_Format', 'Plate.FK_Plate_Format__ID=Plate_Format_ID' );
    $self->no_joins('Library,Employee,Sample,Plate,Sample_Type');    # Do not join the Library and Employee table (eg. Lib created by..)
    $self->SUPER::load_Object( -quick_load => $quick_load, -debug => $debug, -force => $force, -condition => $additional_condition );
    $self->set( 'DBobject', $type );
    $self->{plate_id} = $self->get_data('Plate_ID');

    if ($plate_id) {
        ## get protocol in which plate was created ##
        my $protocol = get_birth_protocol( -dbc => $dbc, -plate_id => $plate_id );
        $self->{protocol_name} = $protocol->{protocol_name} if ( $protocol && $Configs{protocol_tracking} );
    }

    return;
}

##############################
# public_methods             #
##############################

##################
sub home_page {
##################
    my $self        = shift;
    my %args        = &filter_input( \@_, -args => '-brief' );
    my $brief       = $args{-brief};
    my $hide_header = $args{-hide_header};
    my $simple      = $args{-simple};

    my $dbc  = $self->{dbc};
    my $type = $self->{type} || $self->value('Plate.Plate_Type');
    my $id   = $self->{plate_id} || $self->value('Plate.Plate_ID');
    my $list = $self->{list};

    if ($list) { $id = $list }
    if ( $type && $id ) {
        if ( $type eq 'Array' ) {
            require alDente::Array;
        }
        $type = 'alDente::' . $type;

        my $object = $self;
        if ( $type ne 'Container' ) {
            $object = $type->new( -dbc => $dbc, -Plate => $self, -plate_id => $id );
        }
        return $object->home_page( -brief => $scanner_mode, -hide_header => $hide_header, -simple => $simple );
    }
    else { Message("No Type ($type) or ID ($id)"); Call_Stack(); }
    return;
}

########################################################
#
# Display current status (eg. plates / plate sets.. )
#
#############################
sub Display_Input {
##############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $current;
    if ( $dbc->{current_plates} ) { $current = join ',', @{ $dbc->{current_plates} } }
    $current ||= $current_plates;    ## temporary (phasing out..)

    $plate_set ||= $dbc->{plate_set};
    $plate_set ||= param('Plate Set Number');
    $protocol  ||= $dbc->{protocol};
    ### If we have come this far, show Current Plates, Plate Set Status ###
    my $Header = HTML_Table->new( -class => 'small', -padding => '0' );
    $Header->Set_Line_Colour('CCCCCC');

    if ($protocol) {
        $Header->Set_Row( [ 'Protocol:', "<B>$protocol</B>" ] );
    }

    if ( $current =~ /[1-9]/ ) {

        my @list = split ',', $current;

        my ( $tables, $set_order ) = ( 'Plate, Plate_Format', '' );
        if ( $plate_set > 0 ) {
            $Header->Set_Row( [ 'Current Set:', &Link_To( $dbc->config('homelink'), b($plate_set), "&HomePage=Plate_Set&ID=$plate_set", 'red' ) ] );
            $tables    .= ',Plate_Set';
            $set_order .= " AND Plate_Set.FK_Plate__ID=Plate_ID AND Plate_Set_Number = $plate_set ORDER BY Plate_Set_ID";
        }

        my @types = $dbc->Table_find( $tables, 'Plate_ID,Plate_Format_Type,Well_Capacity_mL,Plate_Size', "where FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID in ($current) $set_order", -distinct => 0 );
        my %counts;
        foreach (@types) {
            my ( $id, $type, $format_size, $size ) = split( ',', $_ );
            push( @{ $counts{$type}{ids} }, $id );
            if ( $format_size ne $size && $size ) {

                #	    $counts{$type}{count}++;
                ### Extract the size by dividing (ie. 384/96)
                unless ( $counts{$type}{maxcount} ) {
                    $counts{$type}{maxcount} = [ split( '-', $format_size ) ]->[0] / [ split( '-', $size ) ]->[0];
                }
            }
        }

        my $plate_info;
        foreach ( sort keys %counts ) {
            my @list = @{ $counts{$_}{ids} };
            my $tray_groups = alDente::Tray::group_ids( $dbc, 'Plate', \@list );
            my $display;
            $display .= ' ' . $tray_groups->{physical_plates};
            if ( $tray_groups->{tray_singlets} ) {
                $display .= ' (';
                if ( $tray_groups->{complete_trays} ) {
                    $display .= $tray_groups->{complete_trays} . ' full+';
                }
                $display .= $tray_groups->{tray_singlets} . '/' . $counts{$_}{maxcount} if ( $tray_groups->{tray_singlets} );
                $display .= ')';
            }
            $display .= " $_";
            $plate_info .= &Link_To( $dbc->config('homelink'), $display, "&Info=1&Table=Plate&Field=Plate_ID&Like=" . join( ',', @list ), 'red', ['newwin'] ) . '<br>';
        }
        $Header->Set_Row( [ 'Current Samples:', $plate_info ] );
    }
    return $Header->Printout(0);
}

##########################
sub _init_table {
##########################
    my $title = shift;
    my $width = shift || "100%";

    my $table = HTML_Table->new();
    $table->Set_Class('small');
    $table->Set_Width($width);
    $table->Toggle_Colour('off');
    $table->Set_Line_Colour( '#eeeeff', '#eeeeff' );
    $table->Set_Title( $title, bgcolour => '#ccccff', fclass => 'small', fstyle => 'bold' );

    return $table;
}

# Display the schedule for a given plate
#
#
############################
sub get_plate_schedule_code {
############################
    my %args     = filter_input( \@_, -args => 'dbc,plate_id' );
    my $dbc      = $args{-dbc};
    my $plate_id = $args{-plate_id};
    require alDente::Plate_Schedule;
    use RGTools::RGmath;
    my $plate_schedule = alDente::Plate_Schedule->new( -dbc             => $dbc );
    my $schedule       = $plate_schedule->get_plate_schedule( -plate_id => $plate_id );
    my $pipelines      = $schedule->{FK_Pipeline__ID};
    my $pipeline_codes;

    if ($pipelines) {
        my %Codes;
        map {
            ($_) = $dbc->Table_find( 'Pipeline', 'Pipeline_Code', "WHERE Pipeline_ID = $_" );
            $Codes{$_} = 1;
        } @{$pipelines};

        $pipeline_codes = Cast_List( -list => [ keys %Codes ], -to => 'String' );
    }

    return $pipeline_codes;
}

###############################
# Retrieve list of plates directly above current plate in hierarchy.  (eg parents)
#
# This also retrieves extraction parents, rearray parents, and pooling parents if the -follow flag is set.
# (It will not follow through the above for multi-well plates unless the -extended_follow flag is set.
#
#####################
sub get_prev_gen {
#####################
    my %args = &filter_input( \@_, -args => 'dbc,plate_id,fields,follow' );
    my $dbc             = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id        = $args{-plate_id};
    my $fields          = $args{-fields};
    my $include         = $args{-include};
    my $extended_follow = $args{-extended_follow};                                                         ## follow through rearrays etc even for multi-well plates.
    my $well            = $args{-well};
    my $follow          = $args{-follow} || $extended_follow;                                              ## flag to indicate if we are to follow through extractions, pooling etc.

    my $match            = '';
    my @group            = ();                                                                             ## array to store children (re-grouped if necessary to arrange 96x4 plates together ##
    my $follow_condition = "";                                                                             #" AND Plate_Type like 'Tube'" unless $extended_follow;

    ## form children into groups of mul plates if applicable... ## ie @children = ('1,2,3,4','5,6,7,8');

    my @field_list = Cast_List( -list => $fields, -to => 'array' );
    my %Child;
    $Child{'Child'} = { $dbc->Table_retrieve( 'Plate LEFT JOIN Plate_Tray on FK_Plate__ID=Plate_ID', [ 'FKParent_Plate__ID as Plate_ID', @field_list, 'Plate_Position' ], "WHERE Plate_ID IN ($plate_id) ORDER BY Plate_ID" ) };

    ### also allow tracking through extractions, pooling, rearrays etc. ###
    my $well_condition;
    if ($well) {
        $well_condition = " AND Target_Well = '$well'";
    }

    #@field_list = ("concat(FK_Library__Name,Plate_Number) as Pnum"
    #Message("Plate $plate_id");
    #my $result = $dbc->call_stored_procedure(-sp_name=>'get_prev_rearray_gen',-arguments=>"\"$plate_id\"");
    $Child{'Rearray'} = {
        $dbc->Table_retrieve(
            'Plate,ReArray_Request,ReArray',
            [ 'FKSource_Plate__ID as Plate_ID', @field_list ],
            "WHERE FKTarget_Plate__ID=Plate_ID $well_condition AND FK_ReArray_Request__ID=ReArray_Request_ID AND ReArray_Type <> 'Extraction ReArray' and Plate_ID in ($plate_id) $follow_condition ORDER BY FKTarget_Plate__ID", 'Distinct'
        )
    };

    $Child{'Extraction'} = {
        $dbc->Table_retrieve(
            'Plate,ReArray_Request,ReArray',
            [ 'FKSource_Plate__ID as Plate_ID', @field_list ],
            "WHERE FKTarget_Plate__ID=Plate_ID AND FK_ReArray_Request__ID=ReArray_Request_ID AND ReArray_Type = 'Extraction ReArray' and Plate_ID in ($plate_id) $follow_condition ORDER BY FKTarget_Plate__ID", 'Distinct'
        )
    };

    $Child{'Pooling'} = {
        $dbc->Table_retrieve(
            'Plate,Sample_Pool,PoolSample',
            [ 'FK_Plate__ID as Plate_ID', @field_list ],
            "WHERE FKTarget_Plate__ID=Plate_ID AND Sample_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND Plate_ID in ($plate_id) $follow_condition ORDER BY FKTarget_Plate__ID"
        )
    };

    my $max        = 1000;
    my @variations = ('Child');
    push @variations, ( 'Pooling', 'Rearray', 'Extraction' ) if $follow;
    foreach my $array (@variations) {
        my $index = 0;
        unless ( defined $Child{$array} ) {next}
        my %Array = %{ $Child{$array} };
        if ( $#{ $Array{Plate_ID} } > $max ) { $dbc->warning("Ignored array of more $max samples in case of input error ($#{$Array{Plate_ID}} $array records found)  Please limit to $max if possible or contact LIMS."); next }
        while ( defined $Array{Plate_ID}[$index] ) {
            my $id = $Array{Plate_ID}[$index];
            unless ($id) { $index++; next; }
            if ( $include && $include !~ /\b$id\b/ ) { $index++; next; }    ## skip if not in supplied list
            my $pos    = $Array{Plate_Position}[$index];
            my $number = $Array{Pnum}[$index];
            if ( $pos && $match =~ /^$number$pos$/ ) {
                $group[-1] = "$group[-1],$id" unless ( $group[-1] =~ /\b$id\b/ );
            }                                                               ## include with last plate
            else {
                push( @group, $id ) unless ( grep /^$id$/, @group );
            }
            my $lastpos = $pos;
            $lastpos++;
            $match = "$number$lastpos";                                     ## if this matches the next plate, combine them together...
            $index++;
        }
    }
    return @group;
}

###############################
# Retrieve list of plates directly below current plate in hierarchy.  (eg children)
#
# This also retrieves extraction parents, rearray parents, and pooling parents if the -follow flag is set.
# (It will not follow through the above for multi-well plates unless the -extended_follow flag is set.
#
#####################
sub get_next_gen {
#####################
    my %args = &filter_input( \@_, -args => 'dbc,plate_id,fields,follow' );
    my $dbc      = $args{-dbc}      || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id = $args{-plate_id} || 0;
    my $fields   = $args{-fields};
    my $include  = $args{-include};
    my $extended_follow = $args{-extended_follow};               ## follow through rearrays etc even for multi-well plates.
    my $follow          = $args{-follow} || $extended_follow;    ## flag to indicate if we are to follow through extractions, pooling etc.
    my $debug           = $args{-debug};

    my $match = '';
    my @group = ();                                              ## array to store children (re-grouped if necessary to arrange 96x4 plates together ##
    my $follow_condition;
    $follow_condition = " AND Plate_Type like 'Tube'" unless $extended_follow;

    ## form children into groups of mul plates if applicable... ## ie @children = ('1,2,3,4','5,6,7,8');

    my @field_list = Cast_List( -list => $fields, -to => 'array' );
    my %Child;

    $Child{'Child'} = { $dbc->Table_retrieve( 'Plate LEFT JOIN Plate_Tray on FK_Plate__ID=Plate_ID', [ 'Plate_ID', @field_list, 'Plate_Position' ], "WHERE FKParent_Plate__ID IN ($plate_id) ORDER BY Plate_ID", -debug => $debug ) };

    ### also allow tracking through extractions, pooling, rearrays etc. ###
    $Child{'Rearray'} = {
        $dbc->Table_retrieve(
            'Plate,ReArray_Request,ReArray', [ 'FKTarget_Plate__ID as Plate_ID', @field_list ],
            "WHERE FKSource_Plate__ID=Plate_ID AND FK_ReArray_Request__ID=ReArray_Request_ID AND ReArray_Type <>'Extraction Rearray' AND Plate_ID in ($plate_id) $follow_condition ORDER BY FKTarget_Plate__ID",
            -distinct => 1,
            -debug    => $debug
        )
    };

    $Child{'Extraction'} = {
        $dbc->Table_retrieve(
            'Plate,ReArray_Request,ReArray', [ 'FKTarget_Plate__ID as Plate_ID', @field_list ],
            "WHERE FKSource_Plate__ID=Plate_ID AND FK_ReArray_Request__ID=ReArray_Request_ID AND ReArray_Type = 'Extraction Rearray' AND Plate_ID in ($plate_id) $follow_condition ORDER BY FKSource_Plate__ID",
            -distinct => 1,
            -debug    => $debug
        )
    };

    $Child{'Pooling'} = {
        $dbc->Table_retrieve(
            'Plate,Sample_Pool,PoolSample', [ 'FKTarget_Plate__ID as Plate_ID', @field_list ], "WHERE FK_Plate__ID=Plate_ID AND Sample_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND Plate_ID in ($plate_id) $follow_condition ORDER BY FKTarget_Plate__ID",
            -distinct => 1,
            -debug    => $debug
        )
    };

    my @variations = ('Child');
    push( @variations, 'Pooling', 'Rearray', 'Extraction' ) if $follow;

    foreach my $array (@variations) {
        my $index = 0;
        unless ( $Child{$array} ) {next}
        my %Array = %{ $Child{$array} };
        while ( defined $Array{Plate_ID}[$index] ) {
            my $id = $Array{Plate_ID}[$index];
            unless ($id) { $index++; next }
            if ( $include && $include !~ /\b$id\b/ ) { $index++; next; }    ## skip if not in supplied list
            my $pos    = $Array{Plate_Position}[$index];
            my $number = $Array{Pnum}[$index];
            if ( $pos && $match =~ /^$number$pos$/ ) {
                $group[-1] = "$group[-1],$id" unless ( $group[-1] =~ /\b$id\b/ );
            }                                                               ## include with last plate
            else {
                push( @group, $id ) unless ( grep /^$id$/, @group );
            }
            my $lastpos = $pos;
            $lastpos++;
            $match = "$number$lastpos";                                     ## if this matches the next plate, combine them together...
            $index++;
        }
    }
    return @group;
}

#####################################################
# Simple plate icon showing basic plate information.
#
# <CONSTRUCTION> - need to adapt run example to apply to specific plates (or just show no grows etc.)
#
# Return: label.
##############
sub plate_icon {
##############
    my $self = shift;
    my $id   = shift;
    my %args = &filter_input( \@_, -args => 'highlight' );

    my $dbc = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $highlight = $args{-highlight};

    my @idlist = split ',', $id;

    my $label  = '';
    my $img    = '';
    my $suffix = '';
    my $index  = 1;
    if ( $Configs{protocol_tracking} ) {
        foreach my $id (@idlist) {
            my %details = %{ get_birth_protocol( -dbc => $dbc, -plate_id => $id ) };

            my $runexample = 34447;
            if ( $details{size} =~ /384/ ) { $runexample = 34449; }

            $label .= "$id ";
            my $prefix = '';
            if ( $index == 2 || $index == 4 ) { $prefix = ' '; }
            elsif ( $index == 3 ) { $prefix = "<BR>"; }
            $index++;
            my $project_path = &alDente::Run::get_data_path( -dbc => $dbc, -run_id => $runexample, -simple => 1 );
            $img .= "$prefix<Img Src='../dynamic/data_home/private/Projects/$project_path/phd_dir/Run$runexample.png'>";
            my $created = $details{protocol_name} || '(made o/s protocol)';
            unless ($suffix) {    ## only add this once
                $suffix .= lbr . $created;
                $suffix .= lbr . $details{format};
            }

            #    $label .= "<BR>Format..";
        }
    }

    my $returnval = "$label<BR>$img<BR>$suffix";
    if ($highlight) { $returnval = "<Font color='red'>$returnval</Font>"; }
    return $returnval;
}

##############################
# Inherit parent plate's attributes
#
# $self->inherit_attributes(-parent_id=>$pid,-child_ids=>$cids);
#
# Returns: number of records updated
#
#########################
sub inherit_attributes {
#########################
    my $self       = shift;
    my $dbc        = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my %args       = filter_input( \@_, -args => 'attributes' );
    my $attributes = $args{-attributes};
    my $user_id    = $dbc->get_local('user_id');

    my $plate_id = $self->{plate_id} || $self->primary_value( -table => 'Plate' );

    # check if this plate is an original plate. If it isn't, use parent's plate number

    my @parent = $dbc->Table_find( "Plate", "FKParent_Plate__ID", "WHERE Plate_ID=$plate_id" );

    my $ok = 0;
    if ( scalar(@parent) == 1 && $parent[0] != 0 ) {    # simple case - one parent only
        my $parent_id = $parent[0];

        my $attributes_list = Cast_List( -list => $attributes, -to => 'String', -autoquote => 1 );
        my $attrib_condition = "";
        if ($attributes_list) {
            $attrib_condition = " and Attribute_Name in ($attributes_list) ";
        }
        my %inherited_attributes
            = $dbc->Table_retrieve( "Plate_Attribute,Attribute", [ 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' ], "WHERE FK_Attribute__ID=Attribute_ID AND Inherited = 'Yes' AND FK_Plate__ID = $parent_id $attrib_condition" );
        my @fields = ( 'FK_Plate__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' );
        my %attr_values;
        my $index = 0;
        while ( defined $inherited_attributes{FK_Attribute__ID}[$index] ) {
            my @values = ($plate_id);
            push @values, $inherited_attributes{FK_Attribute__ID}[$index];
            push @values, $inherited_attributes{Attribute_Value}[$index];
            push @values, $inherited_attributes{FK_Employee__ID}[$index];
            push @values, $inherited_attributes{Set_DateTime}[$index];
            $attr_values{ ++$index } = \@values;
        }
        $dbc->smart_append( -tables => "Plate_Attribute", -fields => \@fields, -values => \%attr_values, -autoquote => 1 );
    }
    elsif ( scalar(@parent) > 1 && $parent[0] != 0 ) {
        $ok = $self->inherit_Attribute( -parent_ids => \@parent, -child_ids => $plate_id, -set => { 'FK_Employee__ID' => $user_id }, -attributes => $attributes );
    }
    else {
        my @parent_ids = $dbc->Table_find( "Sample_Pool,PoolSample", "FK_Plate__ID", "WHERE Sample_Pool.FK_Pool__ID = PoolSample.FK_Pool__ID AND FKTarget_Plate__ID=$plate_id" );
        if ( scalar(@parent_ids) == 0 ) {

            # check for rearrays
            @parent_ids = $dbc->Table_find( "ReArray_Request,ReArray", "FKSource_Plate__ID", "WHERE FK_ReArray_Request__ID = ReArray_Request_ID AND FKTarget_Plate__ID=$plate_id" );
        }
        if ( scalar(@parent_ids) > 0 ) {
            $ok = $self->inherit_Attribute( -parent_ids => \@parent_ids, -child_ids => $plate_id, -set => { 'FK_Employee__ID' => $user_id }, -attributes => $attributes );
        }
    }
    return $ok;
}

#
# This function changes the work_request of the plate.
# It takes all selected downstream plates and changes the work_request to the sameone.
# This also updates the Invoiceable_Work items that may be on the plate
#
# Returns: number of plate records updated
#
#########################
sub inherit_funding {
#########################
    my $self     = shift;
    my $dbc      = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my %args     = filter_input( \@_, -args => 'attributes' );
    my $plate_id = $self->{plate_id} || $self->primary_value( -table => 'Plate' );
    my $debug    = $args{-debug};
    $debug = 1;
    my @parent = $dbc->Table_find( "Plate", "FKParent_Plate__ID", "WHERE Plate_ID=$plate_id " );
    my $parents = join ',', @parent;

    my @work_request = $dbc->Table_find( "Plate", "FK_Work_Request__ID", "WHERE Plate_ID IN ($parents) AND FK_Work_Request__ID IS NOT NULL" );
    my $work_requests = join ',', @work_request;
    my ($IW_id) = $dbc->Table_find( "Invoiceable_Work", "Invoiceable_Work_ID", "WHERE FK_Plate__ID = $plate_id" );
    if ( scalar(@work_request) != 1 ) {
        Message("Warning: Cannot inherent Work_Request");
        return;
    }

    my $IW_obj = new alDente::Invoiceable_Work( -dbc => $dbc, -id => $IW_id );

    if ( $IW_obj->validate_IWR_funding_update( -dbc => $dbc, -id => $IW_id ) ) {

        my $ok = $dbc->Table_update_array( 'Plate', ['FK_Work_Request__ID'], ["$work_requests"], "WHERE Plate_ID = $plate_id" );

        if ( $ok && $debug ) { print Message("Plate Updated: $plate_id Parent Plate: @parent Work_Request: $work_requests"); }

        my ($funding) = $dbc->Table_find( "Work_Request", "FK_Funding__ID", "WHERE Work_Request_ID = $work_requests" );

        my @IWRs = $dbc->Table_find( 'Invoiceable_Work_Reference,Invoiceable_Work', 'Invoiceable_Work_Reference_ID', "WHERE FKReferenced_Invoiceable_Work__ID = Invoiceable_Work_ID AND FK_Plate__ID = $plate_id" );
        my $IWR_ids = Cast_List( -list => \@IWRs, -to => 'String' );
        my @ok2 = $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['Invoiceable_Work_Reference.FKApplicable_Funding__ID'], [$funding], "WHERE Invoiceable_Work_Reference_ID IN ($IWR_ids)" );
        if ( @ok2 && $debug ) {
            my ($iw) = $dbc->Table_find( "Invoiceable_Work", "Invoiceable_Work_ID", "WHERE FK_Plate__ID = $plate_id" );
            if ($iw) {
                print Message("Invoiceable_Work Updated: $iw Funding: $funding");
            }

        }

        return $ok;
    }
    else {
        $dbc->Message("Plate not Updated: $plate_id");

    }
}

##############################
# Inherit parent plate's attributes in batch
#
# alDente::Container::batch_inherit_attributes(-ids=>$ids);
#
# Returns: number of records updated
#
#########################
sub batch_inherit_attributes {
#########################
    my %args       = &filter_input( \@_, -args => 'dbc,id' );
    my $dbc        = $args{-dbc};
    my $id         = $args{-id};                                # array ref
    my $attributes = $args{-attributes};
    my $user_id    = $dbc->get_local('user_id');

    my @ids = Cast_List( -list => $id, -to => 'Array' );
    my $plate_list = Cast_List( -list => \@ids, -to => 'String', -autoquote => 1 );
    if ( !$id || $plate_list eq "''" ) {return}                 # empty string

    ## check if this plate is an original plate. If it isn't, use parent's plate number

    ## get parents for each plate
    my @parents = $dbc->Table_find( "Plate", "Plate_ID,FKParent_Plate__ID", "WHERE Plate_ID in ( $plate_list)" );
    my %parents;
    foreach my $parent_info (@parents) {
        my ( $plate_id, $parent_id ) = split ',', $parent_info;
        if ($parent_id) {
            $parents{$plate_id} = $parent_id;                   # no multiple parents in this case
        }
    }

    ## separate plates with a parent and plates without FKParent_Plate__ID
    my @no_FKParent;
    foreach my $id (@ids) {
        if ( !exists $parents{$id} ) {
            push @no_FKParent, $id;
        }
    }

    my $ok = 0;

    ## the plates with a parent go to the simple case
    my @plates_with_parent = keys %parents;
    if ( scalar(@plates_with_parent) ) {
        my $with_parent_list = Cast_List( -list => \@plates_with_parent, -to => 'String', -autoquote => 1 );

        #Message( "list: $with_parent_list");

        my $extra_condition = "";
        if ($attributes) {
            $attributes = Cast_List( -list => $attributes, -to => 'String', -autoquote => 1 );
            $extra_condition .= " AND Attribute_Name IN ($attributes) ";
        }

        ## CANNOT do it in one command since plates may have attributes set already and the existing attributes need to be excluded. Replaced this block with the loop through @plates_with_parent
        ##
        #my $command = "INSERT INTO Plate_Attribute (FK_Plate__ID, FK_Attribute__ID, Attribute_Value, FK_Employee__ID, Set_DateTime)"
        #			. " SELECT Plate_ID, FK_Attribute__ID, Attribute_Value, Plate_Attribute.FK_Employee__ID, Set_DateTime"
        #			. " FROM Plate, Plate_Attribute, Attribute"
        #			. " WHERE Plate_ID in ( $with_parent_list ) AND FKParent_Plate__ID = Plate_Attribute.FK_Plate__ID AND FK_Attribute__ID=Attribute_ID AND Inherited = 'Yes' $extra_condition";
        #$ok = $dbc->execute_command( -command => $command );

        foreach my $plate_id (@plates_with_parent) {
            my $additional_condition = $extra_condition;
            my @existing_attributes = $dbc->Table_find( "Plate_Attribute", "FK_Attribute__ID", "WHERE FK_Plate__ID = $plate_id" );
            if ( int(@existing_attributes) > 0 ) {
                my $existing_attribute_list = Cast_List( -list => \@existing_attributes, -to => 'String', -autoquote => 1 );
                $additional_condition .= " and FK_Attribute__ID not in ($existing_attribute_list)";
            }
            my $command
                = "INSERT INTO Plate_Attribute (FK_Plate__ID, FK_Attribute__ID, Attribute_Value, FK_Employee__ID, Set_DateTime)"
                . " SELECT Plate_ID, FK_Attribute__ID, Attribute_Value, Plate_Attribute.FK_Employee__ID, Set_DateTime"
                . " FROM Plate, Plate_Attribute, Attribute"
                . " WHERE Plate_ID = $plate_id AND FKParent_Plate__ID = Plate_Attribute.FK_Plate__ID AND FK_Attribute__ID=Attribute_ID AND Inherited = 'Yes' $additional_condition";
            my $insert_count = $dbc->execute_command( -command => $command );
            $ok += $insert_count;
        }

    }

    ## handle the plates without FKParent_Plate__ID
    if ( scalar(@no_FKParent) ) {
        foreach my $plate_id (@no_FKParent) {

            # check pools
            my @parent_ids = $dbc->Table_find( "Sample_Pool,PoolSample", "FKTarget_Plate__ID,FK_Plate__ID", "WHERE Sample_Pool.FK_Pool__ID = PoolSample.FK_Pool__ID AND FKTarget_Plate__ID=$plate_id" );
            if ( scalar(@parent_ids) == 0 ) {

                # check rearrays
                @parent_ids = $dbc->Table_find( "ReArray_Request,ReArray", "FKTarget_Plate__ID,FKSource_Plate__ID", "WHERE FK_ReArray_Request__ID = ReArray_Request_ID AND FKTarget_Plate__ID=$plate_id" );
            }
            if ( scalar(@parent_ids) > 0 ) {
                my $plate_obj = new alDente::Container( -dbc => $dbc, -id => $plate_id, -quick_load => 1 );
                $ok = $plate_obj->inherit_Attribute( -parent_ids => \@parent_ids, -child_ids => $plate_id, -set => { 'FK_Employee__ID' => $user_id }, -attributes => $attributes );
            }
        }
    }
    return $ok;
}

##############################
# update the Plate information of a Plate
#
# $self->update_plate_info();
#
# Returns: number of records updated
#
##############################
sub update_plate_info {
##############################
    my $self     = shift;
    my %args     = &filter_input( \@_, -args => 'number,label' );
    my $number   = $args{-number};
    my $plate_id = $args{-plate_id};
    my $label    = $args{-label} || param('Target Plate Label');

    my $dbc = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    # check if this plate is an original plate. If it isn't, use parent's plate number

    my $updated = 0;
    my ($plate_info) = $dbc->Table_find(
        "Plate LEFT JOIN Plate as Parent On Parent.Plate_ID = Plate.FKParent_Plate__ID",
        "Plate.FKParent_Plate__ID, Plate.FK_Rack__ID, Plate.FK_Library__Name, Plate.Plate_Created, Plate.Plate_Label, Parent.FK_Work_Request__ID,Parent.Plate_Number,Parent.Plate_Label",
        "where Plate.Plate_ID=$plate_id"
    );
    my ( $parent_id, $rack_id, $lib, $created, $plate_label, $parent_work_request, $parent_num, $parent_label ) = split ',', $plate_info;

    my @update_fields;
    my @update_values;
    if ($parent_id) {
        ## Inherit the plate scheduling
        require alDente::Plate_Schedule;
        my $plate_schedule = alDente::Plate_Schedule->new( -dbc => $self->{dbc} );
        $plate_schedule->inherit_plate_schedule( -plate_id => $plate_id );

        ## Inherit the plate FK_Work_Request__ID
        ## Find the parent plate

        ## Add the FK_Work_Request__ID for the plate
        if ($parent_work_request) {
            push @update_fields, 'FK_Work_Request__ID';
            push @update_values, $parent_work_request;
        }
        $self->inherit_Parent_fields( -daughter => $plate_id, -parent => $parent_id, -dbc => $dbc );

        push( @update_fields, 'Plate_Number' );
        push( @update_values, $parent_num );

        if ( !$label ) {
            ## inherit label from parent if not specified ##
            $label = $parent_label;
        }
    }
    else {

        # count all original plates in the same library that is not this plate
        my $next_num = alDente::Library::get_next_plate_number( $dbc, $lib, $number, -exclude => $plate_id ) || 1;
        push( @update_fields, 'Plate_Number' );
        push( @update_values, $next_num );
    }

    if ( $label && !$plate_label ) {
        push( @update_fields, 'Plate_Label' );
        push( @update_values, $label );
    }

    unless ($rack_id) {
        my ($tbd_rack) = $dbc->Table_find( 'Rack,Equipment', 'Rack_ID', "WHERE FK_Equipment__ID=Equipment_ID AND Rack_Name='Temporary' LIMIT 1" );
        $tbd_rack ||= 1;
        push( @update_fields, 'FK_Rack__ID' );
        push( @update_values, $tbd_rack );
    }

    unless ($created) {
        ## set plate creation date if not already defined ##
        my $time = date_time();
        push @update_fields, 'Plate_Created';
        push @update_values, $time;
    }

    ################ commented out the block below, need to revisit the logic for this and intended behavior LIMS-8914 #############
    #my $format_id = $self->value('Plate.FK_Plate_Format__ID');
    #my @pipelines = $dbc->Table_find( 'Pipeline', 'Pipeline_ID', "WHERE FKApplicable_Plate_Format__ID = $format_id" );
    #if ( int(@pipelines) == 1 ) {
    #    ## only one defined pipeline for this given plate format ##
    #    push @update_fields, 'FK_Pipeline__ID';
    #    push @update_values, $pipelines[0];
    #}

    if (@update_fields) {
        $updated = $dbc->Table_update_array( "Plate", \@update_fields, \@update_values, "where Plate_ID=$plate_id", -autoquote => 1 );
    }

    #    else { Message("nothing to update") }

    return $updated;
}

############################
sub update_Plate_volumes {
############################
    my %args         = &filter_input( \@_, -args => 'dbc,id', -mandatory => 'self|dbc', -self => 'alDente::Container' );
    my $self         = $args{-self};                                                                                       ## enable use as either method or function
    my $dbc          = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $ids          = $args{-ids} || $self->{plate_id};
    my $volume       = $args{-volume};
    my $volume_units = $args{-units};
    my $status       = $args{-status};
    my $initialize   = $args{-initialize};                                                                                 ## required to update volumes if not currently empty or null
    my $split        = $args{-split} || 1;
    my $force        = $args{-force};                                                                                      ## update volumes even if current volume is zero (otherwise will only update when existing volume is non-zero)
    my $debug        = $args{-debug};
    my $negative;

    my $fields = $args{-fields}   || [];
    my $values = $args{ -values } || [];

    if ( !$volume ) { return 0 }

    my @ids = Cast_List( -list => $ids, -to => 'array' );
    my $pad = $split * int(@ids);

    my @volumes       = Cast_List( -list => $volume,       -to => 'array', -pad => $pad );
    my @volumes_units = Cast_List( -list => $volume_units, -to => 'array', -pad => $pad );
    my $updated       = 0;
    my $index         = 0;

    foreach my $id (@ids) {
        my $condition = "WHERE Plate_ID = $id";
        if ( !$initialize ) { $condition .= " AND Current_Volume > 0" }
        my ($current_qty) = $dbc->Table_find( 'Plate', 'Current_Volume,Current_Volume_Units', $condition, -distinct => 1 );
        my ( $current_volume, $current_volume_units ) = split ',', $current_qty;

        my ( $add_volume, $add_volume_units );
        
        my $initial_volume = "$current_volume $current_volume_units";
        foreach my $i (1..$split) {
            my $volume = $volumes[$index];
            my $volume_units = $volumes_units[$index] || $volumes_units[0];
            if ( !$volume ) {next}

            if ( defined $current_volume && $volume ) {
                ( $add_volume, $add_volume_units ) = RGTools::Conversion::add_amounts( -qty1 => $current_volume, -units1 => $current_volume_units, -qty2 => $volume, -units2 => $volume_units, -check_negative => 1 );
            }
            elsif ($force) {
                ### force volume update even if current volume not defined ##
                ( $add_volume, $add_volume_units ) = ( $volume, $volume_units );
            }
            $current_volume = $add_volume;
            $current_volume_units = $add_volume_units;
            $index++
        }
                
        my @local_fields = @$fields;
        my @local_values = @$values;
        if ( defined $add_volume ) {
            if ($initial_volume =~ /^0 /) { $dbc->message("Setting Initial Volume(s) to $add_volume $add_volume_units") }
            else { $dbc->message("Updating Qty from $initial_volume -> $add_volume $add_volume_units") }

            push @local_fields, ( 'Current_Volume', 'Current_Volume_Units' );
            push @local_values, ( $add_volume, $add_volume_units );
        }

        if (@local_fields) { $updated += $dbc->Table_update_array( 'Plate', \@local_fields, \@local_values, "where Plate_ID = $id", -autoquote => 1, -debug => $debug ) }
    }

    return $updated;
}

######################
#
# A button which is used in the Invoiceable_Work_Missing_Funding view
# Given a plate you set the Work_Request
# Also updates the funding for any Invoiceable_Work item that it is attached to.
#
# returns button
##############################
sub set_work_request_btn {
##############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $work_request_list = "  Work Request: " . &alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Work_Request__ID', -filter_by_dept => 1, -search => 1, -filter => 1 );

    ##Opens a new tab when you click on it
    ##Have read that "_blank" expression might not work with internet explorer
    my $onClick = "sub_cgi_app( 'alDente::Container_App' )";

    my $form_output = "";
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Set Work Request', -class => 'Action', -onClick => $onClick, -force => 1 ), "Add a work request to a plate" );
    $form_output .= $work_request_list;
    $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );

    return $form_output;
}

############################
# Set volume to 0 for all the plates
# Return total volume emptied
############################
sub empty_Plate_volumes {
############################
    my %args       = &filter_input( \@_, -args => 'dbc,id', -mandatory => 'self|dbc', -self => 'alDente::Container' );
    my $self       = $args{-self};                                                                                       ## enable use as either method or function
    my $dbc        = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $ids        = $args{-ids} || $self->{plate_id};                                                                   ## required to update volumes if not currently empty or null
    my $initialize = $args{-initialize};
    my $debug      = $args{-debug};

    my @ids = Cast_List( -list => $ids, -to => 'array' );
    my $pad = int(@ids);

    my $fields = $args{-fields}   || [];
    my $values = $args{ -values } || [];

    my $updated            = 0;
    my $total_volume       = 0;
    my $total_volume_units = 'ml';

    foreach my $id (@ids) {
        my $condition = "WHERE Plate_ID = $id";
        if ( !$initialize ) { $condition .= " AND Current_Volume > 0" }
        my ($current_qty) = $dbc->Table_find( 'Plate', 'Current_Volume,Current_Volume_Units', $condition, -distinct => 1 );
        my ( $current_volume, $current_volume_units ) = split ',', $current_qty;

        if ( !$current_volume ) {next}

        my ( $add_volume, $add_volume_units );
        if ( defined $current_volume ) {
            ( $add_volume, $add_volume_units ) = RGTools::Conversion::add_amounts( -qty1 => $current_volume, -units1 => $current_volume_units, -qty2 => "-$current_volume", -units2 => $current_volume_units, -check_negative => 1 );
            $dbc->message("Updating Qty: $current_volume $current_volume_units - $current_volume $current_volume_units = $add_volume $add_volume_units");
            ( $total_volume, $total_volume_units ) = RGTools::Conversion::add_amounts( -qty1 => $total_volume, -units1 => $total_volume_units, -qty2 => $current_volume, -units2 => $current_volume_units, -check_negative => 1 );
        }

        my @local_fields = @$fields;
        my @local_values = @$values;
        push @local_fields, ( 'Current_Volume', 'Current_Volume_Units' );
        push @local_values, ( 0, $add_volume_units );

        if (@local_fields) { $updated += $dbc->Table_update_array( 'Plate', \@local_fields, \@local_values, "where Plate_ID = $id", -autoquote => 1, -debug => $debug ) }
    }

    return ( $total_volume, $total_volume_units );
}

###################
sub get_source {
###################
    #
    # Retrieve original source information
    #
    my $self = shift;
    my %args = @_;

    my $id  = $args{-id}  || $self->{plate_id};
    my $dbc = $args{-dbc} || $self->{dbc};

    my %Ancestry = get_Parents( -dbc => $dbc, -id => $id );    ## add parents to Ancestry

    return $Ancestry{original};
}

##############################################
#  Defining and Creating New Plates
##############################################

##############################
sub obsolete_add_Record {
##############################
    #
    # Add new Record given hash containing attributes.
    #
    my $self = shift;
    my %args = @_;

    my $dbc = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $attributes = $args{-attributes};

    my %Return = {};
    $Return{errors}   = '';
    $Return{plate_id} = '';

    my %Info = %{$attributes};

    my @fields = ();
    my @values = ();

    foreach my $field ( $self->fields ) {
        if ( defined $Info{$field} ) {
            my $value = $Info{$field};

            if ( check_foreign_key($field) ) {
                $value = get_FK_ID( $dbc, $field, $value );    ## Convert to ID if descriptive FK used
            }
            push( @fields, $field );
            push( @values, $value );
        }
    }

    ### Append database if no errors encountered so far ###
    unless ( $Return{errors} ) {
        if ( int(@fields) ) {
            my $newid = $dbc->Table_append_array( $self->{tables}, \@fields, \@values, -autoquote => 1 );
            if ( $newid =~ /[1-9]/ ) {
                $Return{id} = $newid;
            }
            else {
                $Return{errors} .= "Unable to append Table ($DBI::errstr)";
            }
        }
        else {
            $Return{errors} .= "No Fields entered\n";
        }
    }
    return %Return;
}

#########################
## Extract Information ##
#########################

######################
sub link_source_details {
######################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $file = $args{-file};

    if ($file) {
        ## file provided - open and check information ##
    }
    else {
        ## prompt user to select file ##
        print Views::Heading("Select Source Details file for this plate");

    }
    return;
}

####################
sub get_Solutions {
####################
    #
    # get list of solutions applied to container(s)
    #
    my $self = shift;
    my %args = @_;

    my $ids      = $args{-ids}      || $self->{plate_id} || 0;    ## plate_id (or list)
    my $reagents = $args{-reagents} || 0;                         ## extract original reagents from mixture records
    my $order    = $args{-order}    || '';                        ## not yet set up

    my $Used      = $self->get_Applications(%args);
    my @used_list = keys %$Used;

    return \@used_list;

}

################
sub get_Applications {
################
    #
    # get list of applications to container(s)
    #
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'ids', -mandatory => 'ids' );
    if ( $args{ERRORS} ) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $dbc      = $args{-dbc}      || $self->{dbc};
    my $ids      = $args{-ids}      || $self->{plate_id} || 0;    ## plate_id (or list)
    my $reagents = $args{-reagents} || 0;                         ## extract original reagents from mixture records
    my $order    = $args{-order}    || '';                        ## not yet set up

    my @Applied
        = $dbc->Table_find_array( 'Plate_Prep,Prep', [ 'Plate_Prep.FK_Solution__ID as Solution_ID', 'FK_Prep__ID', 'FK_Plate__ID', 'Plate_Prep.Solution_Quantity', 'Solution_Quantity_Units' ], "WHERE FK_Prep__ID=Prep_ID AND FK_Plate__ID in ($ids)" );

    my %Used;
    if ($reagents) {
        ## look further for original reagent components of solutions...
        foreach my $solution (@Applied) {
            my ( $sol_id, $prep_id, $plate_id, $used, $units ) = split ',', $solution;
            $prep_id ||= '0';
            $used    ||= 0;
            my @reagents = &alDente::Solution::get_original_reagents( $dbc, $sol_id );
            map {
                my $id = $_;
                if ( ( $id != $sol_id ) && ( $id =~ /[1-9]/ ) ) { $Used{$plate_id}{$prep_id}{original_reagent}{$id} = "(?/$used)" }
                else                                            { $Used{$plate_id}{$prep_id}{original_reagent}{0}++; }
            } @reagents;
            $Used{$plate_id}{$prep_id}{applied}{$sol_id} = $used . " " . $units;
        }
    }
    else {
        foreach my $solution (@Applied) {
            my ( $sol_id, $prep_id, $plate_id, $used, $units ) = split ',', $solution;
            $prep_id ||= '0';
            $used    ||= 0;
            $Used{$plate_id}{$prep_id}{applied}{$sol_id} = $used . " " . $units;
            $Used{$plate_id}{$prep_id}{original_reagent}{0}++;
        }
    }
    my @used_list = keys %Used;

    return \%Used;
}

##################
sub get_Preps {
##################
    #
    # get list of solutions applied to container(s)
    #
    my $self = shift;
    my %args = filter_input( \@_, -args => 'ids' );

    my $dbc = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id = $args{-plate_id} || $self->{plate_id} || 0;
    my $field_ref = $args{-fields};
    my $reagents  = $args{-reagents} || 0;    ## extract reagents from mixture records
    my $view      = $args{-view} || 0;
    my $step      = $args{-step};             ## allow searching for specific step(s);
    my $history   = $args{-history};
    my $distinct  = $args{-distinct};

    my $extra_condition = '';
    if ($step) {
        if ( $step =~ /,/ ) {
            $step = Cast_List( -list => $step, -to => 'string', -autoquote => 1 );
            $extra_condition .= " AND Prep_Name in ($step)";
            if ( $step =~ /\*/ ) { Message("Warning: cannot handle BOTH list and wildcard simultaneously (using list)"); }
        }
        else {
            $step = convert_to_regexp($step);
            $extra_condition .= " AND Prep_Name LIKE \"$step\"";
        }
    }
    $id = Cast_List( -list => $id, -to => 'string' );

    my %Preps;
    my @fields = ( 'Prep_ID', 'Prep_Name', 'Prep_DateTime', 'FK_Plate__ID' );
    @fields = Cast_List( -list => $field_ref, -to => 'array' ) if $field_ref;

    foreach my $this_id ( split ',', $id ) {
        ## get parents is history flag set
        my $ids = $this_id;
        if ($history) { $ids = get_Parents( -dbc => $dbc, -id => $this_id, -format => 'list' ); }

        ### key on each input id at a time ###
        my %data = $dbc->Table_retrieve( 'Plate_Prep,Prep,Lab_Protocol', \@fields, "where FK_Prep__ID=Prep_ID AND FK_Lab_Protocol__ID=Lab_Protocol_ID AND FK_Plate__ID in ($ids) $extra_condition", -distinct => $distinct );
        $Preps{$this_id} = \%data;
    }

    return %Preps;
}

####################
sub get_Sample {
####################
    my $self = shift;
    my %args = @_;

    my $dbc   = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate = $self->{plate_id};
    my $well  = $args{-well};

    my $sample;
    $well = extract_range( -list => $well ) if $well;

    my $wells = Cast_List( -to => 'string', -autoquote => 1, -list => $well );

    if ( $well && $wells !~ /,/ ) {

        my %Ancestry  = get_Parents( -dbc => $dbc, -id => $plate, -well => $well, -simple => 1 );
        my $sample_id = $Ancestry{sample_id};
        my $original  = $Ancestry{original};
        $sample = alDente::Sample->new( -dbc => $dbc, -id => $sample_id );
        $sample->home_page();

        my $info = $dbc->Table_retrieve( 'Extraction_Sample LEFT JOIN Extraction_Details ON Extraction_Sample_ID=FK_Extraction_Sample__ID', [ 'Extraction_Sample_ID', 'Extraction_Details_ID' ], "WHERE FKOriginal_Plate__ID = $plate", -format => 'RH' );

        my ( $rna_sample_id, $rna_details_id ) = ( $info->{Extraction_Sample_ID}, $info->{Extraction_Details_ID} );

        my %configs;

        if ($rna_details_id) {

            print &Link_To( $dbc->config('homelink'), 'Edit Extraction Details', "&Search=1&Table=Extraction_Details&Search+List=$rna_details_id", $Settings{LINK_COLOUR} );
        }
        else {
            $configs{'-grey'}{FK_Extraction_Sample__ID} = $rna_sample_id;

            # Freeze the configs hash
            my $frozen_configs = Safe_Freeze( -name => "DB_Form_Configs", -value => \%configs, -format => 'url', -encode => 1 );
            print &Link_To( $dbc->config('homelink'), 'Add Extraction Details', "&New+Entry=New+Extraction_Details&$frozen_configs", $Settings{LINK_COLOUR} );
        }
        ### Display recursive list of parent samples: Plate_Content_Type :  Link To Extraction Details

        _get_parent_sample( -dbc => $dbc, -sample_id => $sample_id );
    }
    elsif ($plate) {
        my %Ancestry = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate, -simple => 1 );
        my $original = $Ancestry{original};

        my $condition = "WHERE Plate_Sample.FKOriginal_Plate__ID = $original and Plate_Sample.FK_Sample__ID=Sample_ID";
        if ($well) { $condition .= " AND WELL IN ($wells)" }
        $condition .= " AND FK_Source__ID = Source_ID";
        my $samples = &Table_retrieve_display(
            $dbc,
            'Plate_Sample, Sample, Source',
            [ "Sample_ID as ID", "Sample_Name as Sample", "FKParent_Sample__ID as ParentSample", "Well", 'FK_Source__ID as Source', "FK_Original_Source__ID as Original_Source", 'FK_Sample_Type__ID' ], $condition
        );

    }

    else { Message("No info for this Sample ($plate : $well)") }

    return;
}

#
# A fast direct function to quickly retrieving original plate positions given downstream plate_id & well.
#
# (This is useful for get_sample_id since it enables rapid retrieval of sample_ids from downstream plate specifications)
#
#
# Return:  array reference for original Plate ids, original wells
#################################
sub get_original_locations {
#################################
    my %args        = filter_input( \@_, -args => 'plate_id,well', -mandatory => 'plate_id|plate_ids' );
    my $dbc         = $args{-dbc};
    my $plate_ids   = $args{-plate_id} || $args{-plate_ids};
    my $wells       = $args{-well} || $args{-wells};
    my $generations = $args{-generations} || 0;
    my $debug       = $args{-debug};

    my @plate_ids  = Cast_List( -list => $plate_ids,  -to => 'array' );
    my @wells      = Cast_List( -list => $wells,      -to => 'array' );
    my $plate_list = Cast_List( -list => \@plate_ids, -to => 'string' );

    if ( $debug && !$generations ) { Message("Get original list for $plate_list (@plate_ids) (@wells)"); Call_Stack(); }

    if ( !$plate_list ) { return ( [], [] ) }

    my %Positions = $dbc->Table_retrieve(
        'Plate LEFT JOIN Plate as Parent ON Parent.Plate_ID=Plate.FKParent_Plate__ID',
        [ 'Plate.Plate_ID', 'Plate.FKParent_Plate__ID', 'Plate.Plate_Parent_Well', 'Plate.Parent_Quadrant', 'Plate.Plate_Size', 'Parent.Plate_Size as Parent_Size' ],
        "WHERE Plate.Plate_ID IN ($plate_list)"
    );

    my ( %P, %Q, %W, %PS, %S );
    my $i = -1;
    while ( defined $Positions{Plate_ID}[ ++$i ] ) {
        ## generate hash for quadrant and well position for each plate ##
        my $plate_id    = $Positions{Plate_ID}[$i];
        my $parent      = $Positions{FKParent_Plate__ID}[$i];
        my $well        = $Positions{Plate_Parent_Well}[$i];
        my $quad        = $Positions{Parent_Quadrant}[$i];
        my $size        = $Positions{Plate_Size}[$i];
        my $parent_size = $Positions{Parent_Size}[$i];
        $P{$plate_id}  = $parent;
        $Q{$plate_id}  = $quad;
        $W{$plate_id}  = $well;
        $S{$plate_id}  = $size;
        $PS{$plate_id} = $parent_size;
    }

    my ( @Oplates,         @Owells );
    my ( @daughter_plates, @daughter_wells );

    my @index;
    foreach my $i ( 0 .. $#plate_ids ) {
        if ( $P{ $plate_ids[$i] } ) {
            push @daughter_plates, $P{ $plate_ids[$i] };
            if ( $Q{ $plate_ids[$i] } ) {
                my $well = $wells[$i];    ## convert well to larger mapping position eg d-A01 -> B02 ##
                if ( $well && ( $PS{ $plate_ids[$i] } != $S{ $plate_ids[$i] } ) ) {
                    my $converted_well = alDente::Well::well_convert( -dbc => $dbc, -wells => $well, -source_size => $S{ $plate_ids[$i] }, -quadrant => $Q{ $plate_ids[$i] }, -target_size => $PS{ $plate_ids[$i] } );
                    push @daughter_wells, $converted_well;
                }
                else {
                    ## use same well mapping for parent if same size ... ##
                    push @daughter_wells, $well;
                }
            }
            elsif ( $W{ $plate_ids[$i] } ) {
                my $well = $wells[$i];    ## convert well to plate_parent_well for tube aliquot from plate, check the pass in well is actually tube well, do a size check just in case
                if ( $well eq 'N/A' && ( $PS{ $plate_ids[$i] } != $S{ $plate_ids[$i] } ) ) {
                    push @daughter_wells, $W{ $plate_ids[$i] };
                }
                else {
                    push @daughter_wells, $well;
                }
            }
            else {
                push @daughter_wells, $wells[$i];
            }
            push @Oplates, '';
            push @Owells,  '';
            push @index,   $i;
        }
        else {
            push @Oplates, $plate_ids[$i];
            push @Owells,  $wells[$i];
        }
    }

    if (@daughter_plates) {
        my ( $parent_plates, $parent_wells ) = get_original_locations( -dbc => $dbc, -plate_ids => \@daughter_plates, -wells => \@daughter_wells, -generations => $generations + 1 );

        foreach my $i ( 1 .. int(@$parent_plates) ) {
            ## fill in previously skipped values values ##
            $Oplates[ $index[ $i - 1 ] ] = $parent_plates->[ $i - 1 ];
            $Owells[ $index[ $i - 1 ] ]  = $parent_wells->[ $i - 1 ];
        }
        if ( $generations > 20 ) { last; }    ## abort in case of endless loop bug

    }

    if ( $debug && !$generations ) { print HTML_Dump "*** FINAL ($generations) -> ***", \@Oplates, \@Owells }

    return ( \@Oplates, \@Owells );
}

####################
# Get Protocol History for Plate(s)
#
#
###############################
sub get_protocol_history {
###############################
    my $self = shift;
    my %args = @_;

    my $dbc         = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id     = $dbc->get_local('user_id');
    my $thisplate   = $args{-id} || $self->{plate_id};                                                                 # plate id (or list of plate_ids)
    my $verbose     = $args{-verbose} || 0;                                                                            # 0 for no output, 1 for basic, 2 for garrulous (not yet used)
    my $protocol_id = $args{-protocol_id} || 0;
    my $library     = $args{-library} || '';
    my $generations = Extract_Values( [ $args{-generations}, 20 ] );                                                   # optional limit on # of gen's to search back..

    my %PHistory = {};                                                                                                 ####### object storing various history info..

    my $timestamp = &RGTools::RGIO::timestamp;

    print h3("Protocol History for $library Container(s) $thisplate");
    my $line_sep  = "<BR>";
    my $field_sep = ",";
    my $plate_sets;
    my $thisplate_set;

    #    Future: display original tube source if available.. (or at least provide a link)
    my $parents = $thisplate;
    if ($thisplate) {                                                                                                  ### if plate(s) specified

        #	print "History for $generations generations".br();
        ## get list of all plates in ancestry of 'thisplate'
        $parents = get_Parents( -dbc => $self->{dbc}, -id => $thisplate, -generations => $generations, -format => 'list' );
        ## get list of all applicable Plate Sets including any of above plates
        unless ( $parents =~ /[1-9]/ ) { Message("No valid Ancestry"); return 0; }
        $plate_sets = join ',', $dbc->Table_find( 'Plate_Set', 'Plate_Set_Number', "where FK_Plate__ID in ($parents)", 'Distinct' );

        ## get actual plate set only for 'thisplate' (not including ancestry)
        $thisplate_set = join ',', $dbc->Table_find( 'Plate_Set', 'Plate_Set_Number', "where FK_Plate__ID in ($thisplate)", 'Distinct' );
    }

    #    my $Table = HTML_Table->new(-size=>'small',-colour=>'white',-border=>1);
    my $Prep = Plate_Prep->new( -dbc => $self->{dbc}, -user => $user_id );

    if ($parents) {
        ## if looking at a plate with history...
        $Prep->get_Prep_history( -plate_ids => $parents, -protocol_id => $protocol_id, -view => 1 );
    }
    elsif ($library) {
        ## if looking at whole library...
        $Prep->get_Prep_history( -library => $library, -protocol_id => $protocol_id, -view => 1 );
    }

    return 1;
}

##############################
sub inherit_Parent_fields {
##############################
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $daughter = $args{-daughter};
    my $parent   = $args{-parent};

    if ( !$parent ) {return}    ## don't need to do anything if this is an original plate ##

    my @fields;
    ## Only inherited QC types will be inherited
    my ($inherited) = $dbc->Table_find( 'Plate_QC,QC_Type', 'Inherited', " WHERE FK_QC_Type__ID = QC_Type_ID and FK_Plate__ID = $parent" );
    if ( $inherited eq 'Yes' ) { push @fields, 'QC_Status' }

    my $success;
    if ( int(@fields) ) {
        my ($result) = $dbc->Table_find_array( 'Plate', \@fields, " WHERE Plate_ID = $parent" );
        my @values = split ',', $result;
        $success = $dbc->Table_update_array( 'Plate', \@fields, \@values, " WHERE Plate_ID = $daughter", -no_triggers => 1, -autoquote => 1 );
    }

    return $success;
}

################
sub save_Container {
################
    #
    # save new record.
    #
    my $self = shift;

}

##############################
# public_functions           #
##############################

###################################################################
# The following routines may be called without creating an object #
###################################################################

##############################
sub validate_pool {
##############################
    my %args       = filter_input( \@_, -mandatory => 'dbc,format,plate_ids' );
    my $dbc        = $args{-dbc};
    my $new_format = $args{'-format'};
    my $plate_ids  = $args{-plate_ids};
    my $is_tray    = $args{-is_tray};

    $plate_ids = Cast_List( -list => $plate_ids, -to => 'string' );
    ## Get target size and plate size
    my $format_id = get_FK_ID( $dbc, 'FK_Plate_Format__ID', $new_format );
    my ($target_size) = $dbc->Table_find( 'Plate_Format', 'Wells', "WHERE Plate_Format_ID = '$format_id'" );
    my @plate_sizes = $dbc->Table_find( 'Plate', 'Plate_Size', "WHERE Plate_ID IN ($plate_ids)", -distinct => 1 );
    if ( int(@plate_sizes) != 1 ) { $dbc->session->error("Must have identical plate sizes"); return 0; }
    $plate_sizes[0] =~ s/-well//;

    if ($is_tray) {
        if   ( $target_size > $plate_sizes[0] ) { return 1 }
        else                                    { return 0 }
    }
    return 1;
}

# if target size > plate size then try to pool individual quadrants
# return list of pooled target plates or 0
# usage: target = &pool_tray( -dbc => $dbc, -plate_ids => $current, -format => $new_format, -pack_quadrants => $pack_quadrants, -quadrants=>\@quadrants);
#
###################
sub pool_tray {
###################
    my %args           = filter_input( \@_, -mandatory => 'dbc,format,plate_ids' );
    my $dbc            = $args{-dbc};
    my $new_format     = $args{'-format'};
    my $plate_ids      = $args{-plate_ids};
    my $pack_quadrants = $args{-pack_quadrants};
    my $quadrants_ref  = $args{-quadrants} || [];
    my @quadrants      = @{$quadrants_ref};

    $plate_ids = Cast_List( -list => $plate_ids, -to => 'string' );
    if ( !@quadrants ) {
        ## Use Plate_Position in Plate_Tray to determine quadrants used
        @quadrants = $dbc->Table_find( 'Plate_Tray', 'Distinct Plate_Position', "WHERE FK_Plate__ID in ($plate_ids) Order by Plate_Position" );
        if ( !@quadrants ) {
            $dbc->session->error("Please provide quadrants");
            return 0;
        }
    }

    my $set = alDente::Container_Set->new( -dbc => $dbc, -ids => $plate_ids );

    #try to pool individual quadrants since target size > plate size

    my @plates = split( ",", $plate_ids );
    my @targets;

    #pool plates every n quadrants where n is number of quadrants
    for my $i ( 0 .. $#quadrants ) {
        my @in_plates;
        for ( my $i2 = $i; $i2 <= $#plates; $i2 = $i2 + $#quadrants + 1 ) {
            push @in_plates, $plates[$i2];
        }
        my $in_plate = join( ",", @in_plates );
        my $target = $set->pool_identical_plates( -plate_ids => $in_plate, -format => $new_format, -pool_x => 1, -no_print => 1 );
        if ($target) {
            push @targets, $target;
        }
        else {
            $dbc->session->error("Problem pooling one of the quadrants");
            return 0;
        }
    }

    #create tray
    my @newtrays = alDente::Tray::create_multiple_trays( $dbc, \@targets, $pack_quadrants, -pos_list => \@quadrants );

    ##Tray Barcode
    my $target = join( ',', @targets );
    &alDente::Barcoding::PrintBarcode( $dbc, 'Trays', $target, 'print,library_plate' );
    return $target;
}

#
# Retrieve valid plate ids that have been preped within the last N days.
#
#
###########################
sub get_recent_prepped_ids {
###########################
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $days_ago = shift || 1;

    my $since = &date_time( '-' . $days_ago . 'd' );

    my @recent_plates = $dbc->Table_find( 'Plate, Plate_Prep, Prep', 'Plate_ID', "WHERE FK_Plate__ID = Plate_ID and FK_Prep__ID = Prep_ID and Prep_DateTime >= '$since'", -distinct => 1 );
    if (@recent_plates) {
        Message("Found $#recent_plates..since $since..");
        return \@recent_plates;
    }
    else {
        Message("No plates found since $since");
        return [];
    }
}

#
# Retrieve valid plate ids that have been created within the last N days.
#
#
#################
sub get_recent_ids {
#################
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $days_ago = shift || 1;

    my $since = &date_time( '-' . $days_ago . 'd' );

    my @recent_plates = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE Plate_Created >= '$since'" );
    print "found $#recent_plates..since $since..<BR>";
    return \@recent_plates;
}

########################################################################################
# Return: list of plates that have been prepped at the same time as the current plate
########################
sub get_Prep_mates {
########################
    my %args = &filter_input( \@_, -args => 'dbc,plate_id', -mandatory => 'plate_id' );    ## input arguments: ##
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $thisplate = $args{-plate_id};                                                                # id or barcode for current plate
    my $direct    = $args{-direct};                                                                  # get only plates associated to this plate directly (ie not parent plates)
    my $protocol  = $args{-protocol};
    my $field_ref = $args{-fields} || ['FK_Plate__ID'];

    my @fields = Cast_List( -list => $field_ref, -to => 'array' );
    my $mates;

    my $plates = $thisplate;
    $plates = get_Parents( -dbc => $dbc, -id => $thisplate, -format => 'list' ) unless $direct;      ## get list of parent plates

    my $protocol_condition;
    $protocol_condition = " AND FK_Lab_Protocol__ID IN ($protocol)" if $protocol;

    my $preps = join ',', $dbc->Table_find( 'Plate_Prep,Prep', 'Prep_ID', "WHERE FK_Prep__ID=Prep_ID AND FK_Plate__ID IN ($plates) $protocol_condition", -distinct );
    my %mates;
    %mates = $dbc->Table_retrieve( 'Prep,Lab_Protocol,Plate_Prep', \@fields, "WHERE FK_Prep__ID=Prep_ID AND FK_Lab_Protocol__ID=Lab_Protocol_ID AND Prep_ID IN ($preps)", -distinct => 1 ) if $preps;

    return \%mates;
}

#################
sub get_Sets {
################
    #
    # find all plate sets containing current plate
    #
    my %args      = @_;                                                                              ## input arguments: ##
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $thisplate = $args{-id};                                                                      # id or barcode for current plate
    my $direct    = $args{-direct};                                                                  # get only sets containing this plate directly

    my $table    = 'Plate';
    my $rkey     = 'FKParent_Plate__ID';
    my $idfield  = 'Plate_ID';
    my $parents  = get_Parents( -dbc => $dbc, -id => $thisplate, -format => 'list' );
    my @all_sets = $dbc->Table_find( 'Plate_Set', 'Plate_Set_Number', "where FK_Plate__ID in ($parents)", 'Distinct' );
    my $sets     = join ',', @all_sets;

    my @plate_sets = $dbc->Table_find( 'Plate_Set', 'Plate_Set_Number', "where FK_Plate__ID in ($thisplate)", 'Distinct' );
    my $direct_sets = join ',', @plate_sets;

    if ($direct) {
        return $direct_sets;
    }
    else {
        return $sets;
    }

}

############################################################
# Extract various information about the history of a plate
#
# Example:
#   my %ancestry = get_Parents(-dbc=>$dbc,-id=>$plate_id,-well=>'A05');
#   my $sample_id = $ancestry{sample_id};
#   my $original_plate   = $ancestry{original}
#
####################
sub get_Parents {
####################
    #
    # Return ids of containers from which given id originated
    #
    my %args = &filter_input( \@_, -args => 'dbc,id,generations,format' );
    my $dbc = $args{-dbc} || $args{-connection} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $id          = $args{-id}          || $args{-plate_id};    ## plate id
    my $generations = $args{-generations} || 40;                  ## number of generations to go back...
    my $rearrays    = $args{-rearrays}    || 8;                   ## number of generations to go back...
    my $format      = $args{'-format'}    || 'hash';              ## format of output ('hash' or comma-delimited 'list' or 'original')
    my $ancestry         = $args{-ancestry};                      ## include current hash if expanding ...
    my $well             = $args{-well};                          ## specify well (allows full clone traceback through re-arrays)
    my $no_rearray       = $args{-no_rearray} || 0;               ## Don't follow through rearrays even if well is specified
    my $well_lookup_hash = $args{-well_lookup};                   ## (HashRef) [Optional] (Recursion argument) well lookup hash. Used for recursion so it doesn't need to be built again
    my $simple           = $args{-simple} || $no_rearray;         ## option to exclude tracking through pooling, rearrays, extractions etc.
    my $no_sample        = $args{-no_sample};                     ## No need to retrieve sample information if set
    my $generation_only  = $args{-generation_only};               ## Only retrieve information for generations and created
    my $debug            = $args{-debug};
    my $include_source   = $args{-include_source};

    $well = &format_well($well);                                  ## (in case it is in other format) ##

    # if well is N/A, then just don't give a well designation
    $well = '' if ( $well eq 'N/A' );

    my %Ancestry;
    if   ($ancestry) { %Ancestry       = %{$ancestry} }           ## update hash if provided
    else             { $Ancestry{list} = [$id] }

    my $recursion = $args{-recurse};                              ## Flag that determines if the function is an instance of a recursion call. Used for efficiency purposes - DO NOT SET!

    $Ancestry{parent_generations} = 0;
    $Ancestry{well}               = $well;

    my $generation    = $id;
    my $rearray_index = 0;
    my $gen_index     = 0;

    unless ( $generations =~ /\d+/ ) { $generations = 20 }        ## continue until finished...

    my $original_well;
    if ($well) {
        $original_well = $well;
    }

    # build lookup table
    my %well_lookup;
    my %well_384_to_96;
    my %well_96_to_384;
    my $index = 0;
    if ($well) {
        if ( $well_lookup_hash && keys( %{$well_lookup_hash} ) > 0 ) {
            %well_384_to_96 = %{ $well_lookup_hash->{'384_to_96'} };
            %well_96_to_384 = %{ $well_lookup_hash->{'96_to_384'} };
        }
        else {
            %well_lookup = $dbc->Table_retrieve( "Well_Lookup", [ 'Quadrant', 'Plate_96', 'Plate_384' ], 'order by Quadrant,Plate_96' );
            foreach my $well ( @{ $well_lookup{'Plate_96'} } ) {
                $well_lookup{'Plate_384'}[$index]                                                            = &format_well( $well_lookup{'Plate_384'}[$index] );
                $well_96_to_384{ uc( $well_lookup{'Plate_96'}[$index] . $well_lookup{'Quadrant'}[$index] ) } = $well_lookup{'Plate_384'}[$index];
                $well_384_to_96{ $well_lookup{'Plate_384'}[$index] }                                         = uc( $well_lookup{'Plate_96'}[$index] ) . $well_lookup{'Quadrant'}[$index];
                $index++;
            }
        }
    }

    while ($generation) {
        my @elders = $dbc->Table_find( 'Plate', 'FKParent_Plate__ID', "where Plate_ID in ($generation) AND FKParent_Plate__ID > 0", -distinct => 1, -debug => $debug );
        if ( !@elders && $include_source ) {
            @elders = $dbc->Table_find( "Plate,Library_Source,Source", 'FKSource_Plate__ID', "WHERE Plate_ID in ($generation) AND Plate.FK_Library__Name = Library_Source.FK_Library__Name AND FK_Source__ID = Source_ID AND FKSource_Plate__ID > 0" );
        }

        if ( $well && @elders ) {
            ## For now, only retrieve parents up until the 'original plate' (most recent in which new sample defined) ##
            my @size_info = $dbc->Table_find(
                'Plate as Parent, Plate as Target',
                'Target.Parent_Quadrant, Parent.Plate_Size, Target.Plate_Size',
                "WHERE Target.Plate_ID in ($generation) AND Parent.Plate_ID=Target.FKParent_Plate__ID AND Target.Plate_ID != Target.FKOriginal_Plate__ID"
            );
            my ( $position_in_parent, $parent_size, $target_size, $target_parent_well ) = split ',', $size_info[0];
            if ( $parent_size =~ /384/ && $target_size =~ /96/ ) {
                $original_well = $well_96_to_384{ uc( $well . $position_in_parent ) };
                $Ancestry{well} = $original_well;
            }
        }
        elsif (@elders) {

            # handling for plate to tube transfers
            ## For now, only retrieve parents up until the 'original plate' (most recent in which new sample defined) ##
            my @size_info = $dbc->Table_find(
                'Plate as Parent, Plate as Target',
                'Parent.Plate_Size, Target.Plate_Size,Target.Plate_Parent_Well',
                "WHERE Target.Plate_ID in ($generation) AND Parent.Plate_ID=Target.FKParent_Plate__ID AND Target.Plate_ID != Target.FKOriginal_Plate__ID"
            );
            my ( $parent_size, $target_size, $target_parent_well ) = split ',', $size_info[0];
            if ( ( $parent_size !~ /^1-well$/ ) && ( $target_size =~ /^1-well$/ ) ) {
                $original_well = $target_parent_well;
                $Ancestry{well} = $original_well;
            }
        }

        ## Extend tracking to extractions, poolings, rearrays ##
        unless ($simple) {
            my @more_parents = get_prev_gen( -dbc => $dbc, -plate_id => $generation, -well => $original_well, -fields => ["concat(FK_Library__Name,Plate_Number) as Pnum"], -follow => 1 );
            my $add_ons = join ',', @more_parents;    ### ( need to account for ['1', '2,3,4' etc] )
            foreach my $parent ( split ',', $add_ons ) {
                if ( $generation =~ /\b$parent\b/ ) {next}    ## skip plates in current generation
                push @elders, $parent unless ( grep /^$parent$/, @elders );
            }

            if (@more_parents) {
                $Ancestry{notes}{"-$gen_index"} .= "Followed through rearrays;";

                $rearray_index++;
                if ( $rearray_index > $rearrays ) {
                    ## turn off rearray tracking after specified number of rearrays encountered
#                    $dbc->warning("Limited data retrieval to $rearrays generation(s) of rearrayed samples");
                    $simple = 1;
                }
            }

            ### Take the first parent (in case of rearrays)
            my ($first_plate) = split( ',', $generation );
            my $bp = get_birth_protocol( $dbc, $first_plate );
            $Ancestry{birth}{"-$gen_index"} = $bp->{protocol_name} if ( $bp->{protocol_name} );
        }

        # change well if the plate is transferred from a 384-well plate to a 96-well plate
        unless (@elders) { $Ancestry{original} = $generation; last; }
        $generation = join ',', @elders;
        if ( $gen_index++ >= $generations ) { $dbc->warning("Stopping Ancestry Extraction at generation # $gen_index ..."); last; }
        $Ancestry{generation}->{"-$gen_index"} = $generation;

        unless ($generation_only) {

            #my $label_field = "CASE WHEN Well_Capacity_mL > 0 THEN concat(Well_Capacity_mL,' mL ',Plate_Format_Type) ELSE Plate_Format_Type END as PF_Type";
            my $label_field = "CASE WHEN Capacity_Units = 'well' THEN concat(Wells,'-well ',Plate_Format_Type) ELSE CASE WHEN Well_Capacity_mL > 0 THEN concat(Well_Capacity_mL,' mL ',Plate_Format_Type) ELSE Plate_Format_Type END END as PF_Type";
            $label_field = 'Sample_Type' if $Configs{plateContent_tracking};

            my $formats = join ',', $dbc->Table_find_array( 'Plate,Plate_Format,Sample_Type', [$label_field], "where FK_Sample_Type__ID=Sample_Type_ID AND FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID in ($generation)", 'Distinct' );
            $Ancestry{formats}->{"-$gen_index"} = $formats;
        }

        my ($created) = $dbc->Table_find_array( 'Plate', ["MIN(Plate_Created)"], "where Plate_ID in ($generation)" );
        $Ancestry{created}->{"-$gen_index"} = $created;

        push( @{ $Ancestry{list} }, $generation );
        $Ancestry{parent_generations}++;
    }

    if ( !$Ancestry{original} ) {
        ## no original plate found ? ##
        if ( $gen_index > $generations ) {
            $dbc->warning("Generation limit encountered prior to identification of Original Plate... continuing");
        }
        else {
            ## fatal if not because of generation limit ##
            $dbc->warning("No Original plate found ?");
            return;
        }
    }

    unless ($generation_only) {
        ### extract rearray information... ###
        my %rearray_info = $dbc->Table_retrieve( 'ReArray,ReArray_Request', ['FKSource_Plate__ID'], "where FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID in ( " . $Ancestry{original} . ") order by FKSource_Plate__ID", -distinct => 1 );

        my @rearrays;
        my @wells;
        if ( defined $rearray_info{FKSource_Plate__ID} ) {
            @rearrays = @{ $rearray_info{FKSource_Plate__ID} };
        }

        my @rearray_pools = $dbc->Table_find(
            'ReArray_Request,ReArray', 'FKSource_Plate__ID',
            "WHERE FKTarget_Plate__ID in ($id) and 
					    FK_ReArray_Request__ID = ReArray_Request_ID and ReArray_Type = 'Pool Rearray' 
					    ORDER BY FKSource_Plate__ID",
            -distinct => 1
        );
        push @rearrays, @rearray_pools;

        if ( int(@rearrays) ) {
            if ( defined $Ancestry{rearray_sources} ) {
                push( @{ $Ancestry{rearray_sources} }, @rearrays );
            }
            else {
                $Ancestry{rearray_sources} = \@rearrays;
            }
        }

        if ( $well && int(@rearrays) && !$no_rearray ) {
            ## if looking at a specific well and there are clone or reaction rearrays... follow them back... ###
            my $well_spec = " AND Target_Well in ('$original_well')";
            my ($rearray_type) = $dbc->Table_find( "ReArray_Request", "ReArray_Type", "WHERE FKTarget_Plate__ID in ( " . $Ancestry{original} . ")" );
            if ( $rearray_type =~ /Clone|Reaction/i ) {
                my %rearray_info = $dbc->Table_retrieve(
                    'ReArray,ReArray_Request', [ 'FKSource_Plate__ID', 'Source_Well' ], "where FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID in ( " . $Ancestry{original} . ") $well_spec",
                    -distinct => 1,
                    -debug    => $debug
                );

                if ( defined $rearray_info{FKSource_Plate__ID} ) {
                    @rearrays = @{ $rearray_info{FKSource_Plate__ID} };
                    @wells    = @{ $rearray_info{Source_Well} };

                    $Ancestry{original} = $rearrays[0];
                    $Ancestry{well}     = $wells[0];

                    # if the well is N/A or blank, omit the wells
                    my $source_well = $wells[0];
                    if ( ( !$source_well ) || ( $well eq 'N/A' ) ) {
                        $source_well = '';
                    }
                    if ($recursion) {
                        %Ancestry = get_Parents( -dbc => $dbc, -id => $rearrays[0], -well => $source_well, -ancestry => \%Ancestry, -well_lookup => $well_lookup_hash, -recurse => 1, -simple => $simple );
                        return %Ancestry;
                    }
                    else {
                        %Ancestry = get_Parents( -dbc => $dbc, -id => $rearrays[0], -well => $source_well, -ancestry => \%Ancestry, -well_lookup => $well_lookup_hash, -recurse => 1, -simple => $simple );
                    }
                }
                else {
                    print "ERROR: Cannot follow through rearray: Target pla" . $Ancestry{original} . " - $well does not exist in ReArray table\n";
                }
            }
        }

        ### extract extraction information... ###
        #    my $extractions = $dbc->load_Object(-sql=>"SELECT DISTINCT FKSource_Plate__ID FROM Extraction WHERE FKTarget_Plate__ID in ($id) ORDER BY FKSource_Plate__ID",-format=>'CA');
        ## why use retrieve ? (unnecessary) ...
        if ( $dbc->table_loaded('Extraction') ) {
            my @extractions = $dbc->Table_find( 'Extraction', 'FKSource_Plate__ID', "WHERE FKTarget_Plate__ID in ($id) ORDER BY FKSource_Plate__ID", 'Distinct', -debug => $debug );
            if ( $extractions[0] =~ /[1-9]/ ) {
                if ( defined $Ancestry{extraction_sources} ) { push( @{ $Ancestry{extraction_sources} }, @extractions ) }
                else                                         { $Ancestry{extraction_sources} = \@extractions }
            }
        }

        ### extract pooling information... ###
        #    my $poolings = $dbc->load_Object(-sql=>"SELECT FK_Plate__ID FROM Sample_Pool,PoolSample WHERE Sample_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND FKTarget_Plate__ID in ($id) ORDER BY FK_Plate__ID",-format=>'CA');

        my @poolings = $dbc->Table_find( 'Sample_Pool,PoolSample', 'FK_Plate__ID', "WHERE Sample_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND FKTarget_Plate__ID in ($id) ORDER BY FK_Plate__ID" );

        if ( $poolings[0] =~ /[1-9]/ ) {
            if ( defined $Ancestry{pooling_sources} ) {
                push( @{ $Ancestry{pooling_sources} }, @poolings );
            }
            else { $Ancestry{pooling_sources} = \@poolings }
        }
    }
    ## Get Sample ID ##
    #    my $sample = SDB::DB_Object->new(-dbc=>$dbc,-tables=>'Plate_Sample,Sample');

    unless ($no_sample) {
        if ( $Ancestry{original} ) {

            # get plate type of original
            my $orig = $Ancestry{original};
            my ($plate_type) = $dbc->Table_find( "Plate", "Plate_Type", "WHERE Plate_ID IN ($Ancestry{original})" );

            my $condition = " AND Plate_Sample.FKOriginal_Plate__ID IN ($Ancestry{original})";
            if ( ( $plate_type =~ /^Library_Plate$/i ) && ( $Ancestry{well} ) ) {

                # library plate
                $condition .= " AND Well = '$Ancestry{well}'";
            }

            # don't trace back if $plate_type is Library_Plate and has no well - cannot find specific sample
            if ( ( ( $plate_type =~ /^Library_Plate$/i ) && ( $Ancestry{well} ) ) || ( $plate_type =~ /^Tube$/i ) ) {
                my @sample_info = $dbc->Table_find( "Plate_Sample,Sample LEFT JOIN Sample_Type ON FK_Sample_Type__ID=Sample_Type_ID", "FK_Sample__ID,Sample_Type.Sample_Type,Sample_Name", "WHERE FK_Sample__ID=Sample_ID $condition", -debug => $debug );

                if ( int(@sample_info) > 0 ) {
                    my ( $sample_id, $sample_type, $sample_name ) = split ',', $sample_info[0];

                    if ($sample_id) {
                        $Ancestry{sample_id}   = $sample_id;
                        $Ancestry{sample_name} = $sample_name;
                    }
                }
                else {
                    print "Sample not found (Plate " . $Ancestry{original} . "; Well: " . $Ancestry{well} . ")\n";
                }
            }
            else {

                # nothing - cannot find sample for nonspecific well
            }
        }
    }

    if ( $format =~ /hash/ ) {
        return %Ancestry;
    }
    elsif ( $format =~ /list/ && defined $Ancestry{list} ) {
        my $list = join ',', @{ $Ancestry{list} };
        return $list;
    }
    elsif ( $format =~ /original/ && defined $Ancestry{original} ) {
        return $Ancestry{original};
    }
    elsif ( $format =~ /sample_id/ && defined $Ancestry{sample_id} ) {
        return $Ancestry{sample_id};
    }
    elsif ( $format =~ /list/ ) { return '' }
    else                        { return '0' }
}

###############
sub get_Siblings {
###############
    #
    # Return list of sibling containers (spawned from same parent)
    #
    my %args = @_;

    my $dbc      = $args{-dbc} || $args{-connection} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id       = $args{-id};                                                                                            ## plate_id
    my $format   = $args{'-format'} || 'hash';                                                                            ## format of output ('hash' or comma-delimited 'list')
    my $ancestry = $args{-ancestry};                                                                                      ## include hash if expanding

    my %Ancestry;
    if   ($ancestry) { %Ancestry       = %{$ancestry} }                                                                   ## update hash if provided
    else             { $Ancestry{list} = [$id] }

    $Ancestry{generation}->{'+0'} = $id;

    my $parent = join ',', $dbc->Table_find( 'Plate', 'FKParent_Plate__ID', "WHERE Plate_ID in ($id) ORDER BY Plate_ID" );
    my ($created) = $dbc->Table_find( 'Plate', 'Min(Plate_Created)', "WHERE Plate_ID in ($id) ORDER BY Plate_ID" );

    $Ancestry{created}->{'+0'} = $created;

    my $siblings = 0;
    if ( $parent =~ /[1-9]/ ) {
        $siblings = join ',', $dbc->Table_find( 'Plate', 'Plate_ID', "where FKParent_Plate__ID = '$parent' ORDER BY Plate_ID" );
        if ( $siblings =~ /[1-9]/ ) {
            $Ancestry{generation}->{'+0'} = $siblings;
            my @sibling_list = split ',', $siblings;
            $Ancestry{list} = \@sibling_list;
        }
    }

    ## generate list of formats used for this generation ##

    #    my $label_field = "concat(Well_Capacity_mL,' ',Plate_Format_Type)";
    #my $label_field = "CASE WHEN Well_Capacity_mL > 0 THEN concat(Well_Capacity_mL,' mL ',Plate_Format_Type) ELSE Plate_Format_Type END as PF_Type";
    my $label_field = "CASE WHEN Capacity_Units = 'well' THEN concat(Wells,'-well ',Plate_Format_Type) ELSE CASE WHEN Well_Capacity_mL > 0 THEN concat(Well_Capacity_mL,' mL ',Plate_Format_Type) ELSE Plate_Format_Type END END as PF_Type";
    $label_field = 'Sample_Type' if $Configs{plateContent_tracking};

    my $formats = join ',', $dbc->Table_find_array( 'Plate,Plate_Format,Sample_Type', [$label_field], "where FK_Sample_Type__ID=Sample_Type_ID AND FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID in ($siblings,$id)", 'Distinct' );
    $Ancestry{formats}->{"+0"} = $formats;

    ## Return list or expanded hash ##
    if ( $format =~ /hash/ ) {
        return %Ancestry;
    }
    elsif ( $format =~ /list/ && defined $Ancestry{list} ) {
        my $list = join ',', @{ $Ancestry{list} };
        return $list;
    }
    elsif ( $format =~ /list/ ) { return '' }
    else                        { return '0' }
}

#####################
sub get_Children {
#####################
    #
    # Return ids for containers spawned by given id
    #
    my %args = &filter_input( \@_, -args => 'dbc,plate_id' );
    my $dbc         = $args{-dbc}         || $args{-connection} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id          = $args{-id}          || $args{-plate_id};                                                                       ## plate_id
    my $generations = $args{-generations} || 40;
    my $format      = $args{'-format'}    || 'hash';                                                                                 ## format of output ('hash' or comma-delimited 'list')
    my $ancestry     = $args{-ancestry};                                                                                             ## include hash if expanding (for repeated calls)
    my $include_self = $args{-include_self} || 0;                                                                                    ## indicate whether to include the plate ID passed in as children list
    my $simple       = $args{-simple};

    my %Ancestry;
    if ($ancestry) { %Ancestry = %{$ancestry} }                                                                                      ## update hash if provided
    elsif ($include_self) { $Ancestry{list} = [$id]; }

    $Ancestry{child_generations} = 0;

    my $generation = $id;

    my $gen_index = 0;
    while ($generation) {
        my @progeny = $dbc->Table_find( 'Plate', 'Plate_ID', "where FKParent_Plate__ID in ($generation)", 'DISTINCT' );

        ## Extend tracking to extractions, poolings, rearrays ##
        unless ($simple) {
            ## assume follow = 1, but if we need to use extended_follow this should be explicity passed as a separate parameter (and should be similar for get_Parents & get_children)
            my @more_kids = get_next_gen( $dbc, $generation, -fields => ["concat(FK_Library__Name,Plate_Number) as Pnum"], -follow => 1 );
            my $add_ons = join ',', @more_kids;    ## need to account for ['1','2,4,6'...]
            foreach my $child ( split ',', $add_ons ) {
                push @progeny, $child unless ( grep /^$child$/, @progeny );
            }
            $Ancestry{notes}{"-$gen_index"} .= "Followed through rearrays;" if @more_kids;
        }

        unless (@progeny) {last}

        $generation = join ',', @progeny;
        $gen_index++;

        $Ancestry{generation}->{"+$gen_index"} = $generation;

        ## generate list of formats used for this generation ##

        #my $label_field = "CASE WHEN Well_Capacity_mL > 0 THEN concat(Well_Capacity_mL,' mL ',Plate_Format_Type) ELSE Plate_Format_Type END as PF_Type";
        my $label_field = "CASE WHEN Capacity_Units = 'well' THEN concat(Wells,'-well ',Plate_Format_Type) ELSE CASE WHEN Well_Capacity_mL > 0 THEN concat(Well_Capacity_mL,' mL ',Plate_Format_Type) ELSE Plate_Format_Type END END as PF_Type";

        #        my $label_field = "concat(Well_Capacity_mL,' ',Plate_Format_Type)";
        $label_field = 'Sample_Type' if $Configs{plateContent_tracking};    ## change label to content type if tracking ##

        my $formats = join ',', $dbc->Table_find_array( 'Plate,Plate_Format,Sample_Type', [$label_field], "where FK_Sample_Type__ID=Sample_Type_ID AND FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID in ($generation)", 'Distinct' );
        $Ancestry{formats}->{"+$gen_index"} = $formats;

        my ($created) = $dbc->Table_find_array( 'Plate', ["MIN(Plate_Created)"], "WHERE Plate_ID in ($generation)" );
        $Ancestry{created}->{"+$gen_index"} = $created;

        my $test = $Ancestry{list};
        push( @{ $Ancestry{list} }, $generation );
        $Ancestry{child_generations}++;

        if ( $gen_index > $generations ) { $dbc->warning("Stopping Ancestry Extraction after $gen_index generations..."); last; }
    }

    ### extract extraction information... ###
    #    my $extractions = $dbc->load_Object(-sql=>"SELECT DISTINCT FKTarget_Plate__ID FROM Extraction WHERE FKSource_Plate__ID in ($id) ORDER BY FKTarget_Plate__ID",-format=>'CA');
    #    my @extractions = $dbc->Table_find('Extraction','FKTarget_Plate__ID',"WHERE FKSource_Plate__ID in ($id) ORDER BY FKTarget_Plate__ID",'Distinct');
    #    if ($extractions[0] =~/[1-9]/) {
    #	 if (defined $Ancestry{extraction_targets}) {push(@{$Ancestry{extraction_targets}}, @extractions)}
    #	 else {$Ancestry{extraction_targets} = \@extractions}
    #    }
    my @extractions = $dbc->Table_find( 'ReArray_Request,ReArray', 'FKTarget_Plate__ID', "WHERE FK_ReArray_Request__ID=ReArray_Request_ID AND ReArray_Type='Extraction Rearray' AND FKSource_Plate__ID in ($id) ORDER BY FKTarget_Plate__ID", 'Distinct' );

    if ( $extractions[0] =~ /[1-9]/ ) {
        if ( defined $Ancestry{rearray_targets} ) { push( @{ $Ancestry{rearray_targets} }, @extractions ) }
        else                                      { $Ancestry{rearray_targets} = \@extractions }
    }
    my @rearray_pools = $dbc->Table_find(
        'ReArray_Request,ReArray', 'FKTarget_Plate__ID',
        "WHERE FKSource_Plate__ID in ($id) and 
                                        FK_ReArray_Request__ID = ReArray_Request_ID and ReArray_Type = 'Pool ReArray' 
                                        ORDER BY FKTarget_Plate__ID",
        -distinct => 1
    );
    if ( $rearray_pools[0] =~ /[1-9]/ ) {
        if ( defined $Ancestry{rearray_targets} ) {
            push( @{ $Ancestry{rearray_targets} }, @rearray_pools );
        }
        else {
            $Ancestry{rearray_targets} = \@rearray_pools;
        }
    }
    ### extract pooling information... ###
    #    my $poolings = $dbc->load_Object(-sql=>"SELECT FKTarget_Plate__ID FROM Sample_Pool,PoolSample WHERE Sample_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND FK_Plate__ID in ($id) ORDER BY FKTarget_Plate__ID",-format=>'CA');

    my @poolings = $dbc->Table_find( 'Sample_Pool,PoolSample', 'FKTarget_Plate__ID', "WHERE Sample_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND FK_Plate__ID in ($id) ORDER BY FKTarget_Plate__ID" );

    if ( $poolings[0] =~ /[1-9]/ ) {

        #if (defined $Ancestry{pooling_targets}) {push(@{$Ancestry{pooling_targets}}, @$poolings)}
        #else {$Ancestry{pooling_targets} = $poolings}
        foreach my $target (@poolings) {    # Get other pooling parents as well
                #	    my $pooling_parents = $dbc->load_Object(-sql=>"SELECT FK_Plate__ID FROM Sample_Pool,PoolSample WHERE Sample_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND FKTarget_Plate__ID = $target ORDER BY FK_Plate__ID",-format=>'CA');
            my @pooling_parents = $dbc->Table_find( 'Sample_Pool,PoolSample', 'FK_Plate__ID', "WHERE Sample_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND FKTarget_Plate__ID = $target ORDER BY FK_Plate__ID" );
            $Ancestry{pooling_targets}{$target} = \@pooling_parents;
        }
    }

    if ( $format =~ /hash/ ) {
        return %Ancestry;
    }
    elsif ( $format =~ /list/ && defined $Ancestry{list} ) {
        my $list = join ',', @{ $Ancestry{list} };
        return $list;
    }
    elsif ( $format =~ /list/ ) {
        return '';
    }
    else {
        return '0';
    }
}

##################
sub get_Notes {
##################
    #
    #
    my %args = &filter_input( \@_, -args => 'dbc,plate_id' );
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id = $args{-plate_id};
    my $output   = $args{-output} || 'list';

    my $generations = Extract_Values( [ shift, 10 ] );

    my $plates = $plate_id;
    my %ancestry;
    if ($generations) {
        %ancestry = get_Parents( -dbc => $dbc, -id => $plate_id, -simple => 1 );
    }
    my ($self_info) = $dbc->Table_find( 'Plate,Plate_Format', 'Plate_Comments,Plate_Format_Type', "where FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID IN ($plate_id)" );    ### since get_Parents doesn't include self :(
    my ( $self_comments, $self_format ) = split( ',', $self_info );
    $ancestry{comments}{"0"}   = $self_comments;
    $ancestry{generation}{"0"} = $plate_id;
    $ancestry{formats}{"0"}    = $self_format;

    if ( $output eq 'list' ) {
        my @comments;
        foreach my $generation ( sort { $a <=> $b } keys %{ $ancestry{comments} } ) {
            my $comment   = $ancestry{comments}{$generation};
            my $thisplate = $ancestry{generation}{$generation};
            if ( $thisplate =~ /,/ ) { $thisplate = 'prior to pool/rearray'; }                                                                                                  ## dissociate notes from full generation list if > 1 (pooled / rearrayed)
            if ( $comment && !( $comment eq 'NULL' ) ) {

                # the grep'd comment is qq'd so that the contents of the comment are not interpreted as a regexp.

                my $quoted_comment = qq{comment};
                unless ( grep /\Q$quoted_comment\E/, @comments ) {
                    push( @comments, "$thisplate: $comment." );
                }
            }
        }
        return @comments;
    }
    elsif ( $output eq 'tooltip' ) {
        my @comments;
        foreach my $generation ( sort { $a <=> $b } keys %{ $ancestry{comments} } ) {
            my $comment = $ancestry{comments}{$generation};
            my $format  = $ancestry{formats}{$generation};
            if ( $comment && !( $comment eq 'NULL' ) ) {
                push( @comments, "$format: $comment" );
            }
        }

        if (@comments) {
            return Show_Tool_Tip( 'Comments', join( lbr, @comments ) );
        }
        else {
            return '-';
        }
    }
    else {
        Message("Error: Unknown output format '$output'");
    }
}

###############
sub get_Reagents {
###############
    #
    # get list of original reagents applied to container(s)
    #

}

###################################################################################################################
# Withdraw sample from tube or plate and update quantity used
# Returns a hash that indicates whether the withdraw is OK and update Current_Volume.
# - If choose to update, then the number of records updated will be returned as well
###################################################################################################################
sub withdraw_sample {
    ########################
    my $self              = shift;
    my %args              = @_;
    my $dbc               = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $withdraw_quantity = $args{-quantity};                                                                                # Quantity to be withdrwan  (for plates - quantity is per well)
    my $withdraw_units    = $args{-units};
    my $update            = $args{-update} || 0;                                                                             # Whether to update the databas with the new Quantity_Used and new Quantity_Used_Units
    my $empty             = $args{-empty};                                                                                   # flag to empty current plate (and throw away plate)

    my $current_volume       = $self->value('Plate.Current_Volume');
    my $current_volume_units = $self->value('Plate.Current_Volume_Units');

    if ($empty) {
        $withdraw_quantity = $current_volume;
        $withdraw_units    = $current_volume_units;
        Message("emptying $self->{plate_id}");
        throw_away( -dbc => $dbc, -ids => $self->{plate_id}, -confirmed => 1 );
    }

    my %retval;

    # Normalize the units
    my $withdraw_base_units;
    my $current_volume_base_units;

    if ( $withdraw_units       =~ /(l|g)$/i ) { $withdraw_base_units       = $1 }
    if ( $current_volume_units =~ /(l|g)$/i ) { $current_volume_base_units = $1 }

    ( $withdraw_quantity, $withdraw_units )       = &convert_to_mils( $withdraw_quantity, $withdraw_units );
    ( $current_volume,    $current_volume_units ) = &convert_to_mils( $current_volume,    $current_volume_units );

    if ( $current_volume_base_units =~ /g/ && !$empty ) {
        $dbc->message("Not tracking sample qty (g)");
    }
    elsif ( !$withdraw_base_units ) {    ## undefined withdrawal volume units
        $dbc->error("Units required for amount to withdraw");
        $retval{error} = 1;
    }
    elsif ( !$current_volume_base_units && defined $current_volume ) {    ## undefined current volume units
        $dbc->error("current volume has no units ??");
        $retval{error} = 1;
    }
    elsif ( lc($current_volume_base_units) ne lc($withdraw_base_units) ) {    ## do not track g if l removed (and visa versa)
        $dbc->warning("Not tracking withdrawal of $withdraw_base_units (current qty in $current_volume_units)");
    }
    elsif ( !( defined $current_volume ) ) {                                  ## not tracking source volume
        $dbc->message("Note: Current Volume not being tracked in Source Container");
    }
    else {
        if ( $withdraw_quantity > $current_volume ) {
            ( $withdraw_quantity, $withdraw_units ) = &Get_Best_Units( -amount => $withdraw_quantity, -units => $withdraw_units );
            $dbc->warning(
                "Not enough sample to be withdrawn from $self->{prefix}$self->{plate_id}. (Current quantity: $current_volume $current_volume_units; Quantity attemped to withdraw: $withdraw_quantity $withdraw_units) Setting current volume to zero.");
            $current_volume = '0';
            ## leave units as they were.. ##
        }
        else {
            ## we need to track the amount ... ##
            $current_volume -= $withdraw_quantity;
            ( $current_volume, $current_volume_units ) = &Get_Best_Units( -amount => $current_volume, -units => $current_volume_units );
        }

        $retval{error} = 0;
        $dbc->session->message("reset volume for $self->{prefix}$self->{plate_id} to $current_volume ($current_volume_units) (used $withdraw_quantity)") if ($update);
        if ($update) {
            my $updated = $self->update( -fields => [ 'Current_Volume', 'Current_Volume_Units' ], -values => [ $current_volume, $current_volume_units ] );
            if ( $updated->{Plate} ) {
                $retval{updated} = $updated->{Plate};
            }
            else {
                $retval{error} = 1;
            }
        }

        ( $retval{quantity_used}, $retval{quantity_used_units} ) = &Get_Best_Units( -amount => $withdraw_quantity, -units => $withdraw_units );
    }

    ( $retval{quantity_used}, $retval{quantity_used_units} ) = &Get_Best_Units( -amount => $withdraw_quantity, -units => $withdraw_units );

    $retval{quantity_available}       = $current_volume;
    $retval{quantity_available_units} = $current_volume_units;

    return \%retval;
}

#################################################
# Gets the remaining quantity of a tube or plate
# Returns an array of quantity and units
#################################################
sub get_remaining_quantity {
    my $self = shift;
    my %args = @_;

    my ( $quantity, $quantity_units ) = ( $self->value('Current_Volume'), $self->value('Current_Volume_Units') );

    ( $quantity, $quantity_units ) = &Get_Best_Units( -amount => $quantity, -units => $quantity_units );
    return ( $quantity, $quantity_units );

}

#########################
sub get_Plate_notes {
#########################

    my $dbc         = shift;
    my $plate       = shift;
    my $generations = Extract_Values( [ shift, 10 ] );

    my $plates;
    if ($generations) {

        #$plates = &get_Plate_parents($dbc,$plate,$generations);
        $plates = get_Parents( -dbc => $dbc, -id => $plate, -format => 'list', -generations => $generations );
    }

    my @comments = ();
    foreach my $thisplate ( split ',', $plates ) {
        my $comment = join '; ', $dbc->Table_find( 'Plate', 'Plate_Comments', "where Plate_ID=$thisplate" );
        if ( $comment && !( $comment eq 'NULL' ) ) {
            unless ( grep /$comment/, @comments ) {
                push( @comments, "$thisplate: $comment." );
            }
        }
    }
    return @comments;
}

#
# Part 1: Trigger to warn users that inherited plate attributes are not applied to existing daughters.
# part 2: to update sample records if Source ID is not set
# part 3: to calculate and update plate volumes if the attribute name is "Measured_Tube_Weight_in_g" and Plate_Format.Wells = 1 AND Container Format has defined Empty_Container_Weight_in_g.
#
###############################
sub Plate_Attribute_trigger {
###############################
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc};
    my $record_id = $args{-id};

    my %info = $dbc->Table_retrieve( 'Plate_Attribute,Attribute', [ 'FK_Plate__ID', 'Attribute_Name', 'Attribute_Value', 'Inherited' ], "WHERE FK_Attribute__ID=Attribute_ID AND Plate_Attribute_ID = $record_id" );

    #print Dumper \%info;
    if ( !defined $info{FK_Plate__ID}[0] || !$info{FK_Plate__ID}[0] ) {return}

    my $plate_id = $info{FK_Plate__ID}[0];

    ## PART 1
    if ( $info{Inherited}[0] =~ /Yes/xms ) {
        my $daughters = get_Children( -dbc => $dbc, -plate_id => $plate_id, -format => 'list', -include_self => 0 );
        if ($daughters) { Message("Warning = Daughter plates exist that will not inherit this attribute ($daughters)") }
    }
    ## PART 2
    if ( $info{Attribute_Name}[0] eq 'Redefined_Source_For' && $info{Attribute_Value}[0] ) {
        my $source_id = $info{Attribute_Value}[0];
        $dbc->Table_update( -table => 'Sample', -fields => 'FK_Source__ID', -values => $source_id, -condition => "WHERE FKOriginal_Plate__ID = $plate_id" );
    }

    ## PART 3
    if ( $info{Attribute_Name}[0] eq 'Measured_Tube_Weight_in_g' ) {
        my %plate_format = $dbc->Table_retrieve( 'Plate,Plate_Format', [ 'Wells', 'Empty_Container_Weight_in_g' ], "WHERE Plate.FK_Plate_Format__ID = Plate_Format_ID AND Plate_ID = $plate_id" );
        if ( defined $plate_format{Wells}[0] && $plate_format{Wells}[0] == 1 && defined $plate_format{Empty_Container_Weight_in_g}[0] ) {
            my $content_weight_in_g = $info{Attribute_Value}[0] - $plate_format{Empty_Container_Weight_in_g}[0];
            ## convert to volume unit ( g -> ml )
            my $content_volume_in_ml = $content_weight_in_g;
            if ( $content_volume_in_ml >= 0 ) {
                my ( $amount, $units ) = Get_Best_Units( -amount => $content_volume_in_ml, -units => 'ml', -base => 'l' );
                my $ok = $dbc->Table_update( -table => 'Plate', -fields => 'Current_Volume,Current_Volume_Units', -values => "$amount,$units", -condition => "WHERE Plate_ID = $plate_id", -autoquote => 1 );
                if ($ok) {
                    $dbc->message("Calculated volume as $amount $units (assuming water density)");
                }
            }

        }
    }
    return;
}

######################################
# Function for deleting containers
######################################
sub Delete_Container {
##########################
    my %args    = &filter_input( \@_, -args => 'dbc,id', -mandatory => 'self|dbc', -self => 'alDente::Container' );
    my $self    = $args{-self};                                                                                       ## enable use as either method or function
    my $dbc     = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $ids     = $args{-ids} || $self->{plate_id};
    my $replace = $args{-replace};
    my $cascade = $args{-cascade};                                                                                    ## additional tables to include in cascade delete if desired
    my $force   = $args{-force};                                                                                      ## force deletion even if Plate_Prep records exist
    my $confirm = $args{-confirm};
    my $user_id = $dbc->get_local('user_id');

    my $force_hours = 4;                                                                                              ## force deletion if plate created within this number of hours (and current user created plate)
    my @info = $dbc->Table_find_array( 'Plate', [ 'FK_Employee__ID', "CASE WHEN NOW() < ADDTIME(Plate_Created,'$force_hours:00') THEN 'ON' ELSE 'OFF' END as Force_Expiry" ], "WHERE Plate_ID IN ($ids)", -distinct => 1 );

    if ( int(@info) == 1 ) {
        ## all plates associated with the same user and have the same force expiry status ##
        my ( $emp, $forced ) = split ',', $info[0];
        if ( ( $emp == $dbc->get_local('user_id') ) && ( $forced eq 'ON' ) ) {
            ## current user created plate, and plate created within the last hour ##
            $force = 1;
        }
    }

    my @cascade = ( 'Library_Plate', 'Tube', 'Array', 'Plate_Set', 'Plate_Attribute', 'Plate_Schedule', 'Plate_Tray', 'Invoiceable_Work' );
    if ($force) {
        @cascade = ( 'Plate_Prep', @cascade );
    }
    if ($cascade) {
        push @cascade, @$cascade;
    }

    if ( $dbc->check_permissions( $user_id, 'Plate', 'delete', 'Plate_ID', $ids ) ) {    # First see whether user has permission to delete at the DBTable level

        if ( !$confirm ) {
            if ( defined $dbc->{session} ) {
                $dbc->warning( "Are you sure you want to delete these plate(s) ($ids) ?", -now => 1 );
            }
            else {
                ## Command-line
                my $ok = Prompt_Input( -prompt => "Are you sure you want to delete these plate(s) ($ids) ?", -type => 'c' );
                if ( $ok !~ /^y/i ) { return "Aborting deletion\n"; }
            }
        }

        # Find out whether there are any original plates.  If so, then special handling is needed and only lab admins should be able to delete them
        my %info = $dbc->Table_retrieve(
            'Plate LEFT JOIN ReArray_Request ON ReArray_Request.FKTarget_Plate__ID=Plate_ID LEFT JOIN Sample_Pool ON Sample_Pool.FKTarget_Plate__ID=Plate_ID',
            [ 'Plate_ID', 'FKOriginal_Plate__ID', 'Group_Concat(ReArray_Request_ID) as ReArrays', 'Group_Concat(FK_Pool__ID) as Pools' ],
            "WHERE Plate_ID IN ($ids) GROUP BY Plate_ID"
        );

        if ( !@info ) {
            $dbc->warning( "No plates found to delete (?)", -session => $Sess );
        }

        my $index = 0;
        while ( defined $info{Plate_ID}[$index] ) {
            my $pid     = $info{Plate_ID}[$index];
            my $opid    = $info{FKOriginal_Plate__ID}[$index];
            my $rearray = $info{ReArrays}[$index];
            my $pool    = $info{Pools}[$index];
            $index++;

            my $original = 0;
            my @sids;
            my $ok  = 0;
            my $ok2 = 0;

            # check if the current plate is an original palte
            if ( $pid == $opid ) {
                $original = 1;
            }

            # ensure that original plates can only be deleted by Administrators
            if ( $original && $Security && !$dbc->Security->department_access($Current_Department) =~ /\bAdmin\b/i ) {
                $dbc->error("ERROR: Cannot delete Plate ($pid). Original plates can only be deleted by lab admins.");
                next;
            }
            else {
                if ($original) {
                    @sids = $dbc->Table_find( 'Plate,Sample,Plate_Sample', "Sample_ID", "WHERE Sample.Sample_ID = Plate_Sample.FK_Sample__ID AND Plate.Plate_ID = Plate_Sample.FKOriginal_Plate__ID AND Plate_Sample.FKOriginal_Plate__ID in ($pid)" );
                }

                $dbc->start_trans( -name => "delete_container $pid" );

                Message("Deleting (O: $original; R: $rearray; P: $pool) $pid vs $opid ");

                # Delete the plate
                my $plate_cascade;
                if ($rearray) {
                    my $clear_rearray_ok = $dbc->delete_records( -table => 'ReArray_Request', -id_list => $rearray, -cascade => get_cascade_tables( 'ReArray_Request', 'ReArray_Request' ), -quiet => 0 );
                    $dbc->message("Removed ReArray Request ($rearray) for plate $pid.");
                    $plate_cascade = get_cascade_tables( 'Plate', 'Rearray' );
                }
                elsif ($pool) {
                    my $clear_pool_ok = $dbc->delete_records( -table => 'Pool', -id_list => $pool, -cascade => get_cascade_tables('Pool'), -quiet => 0 );
                    $dbc->message("Removed Pool ($pool) for plate $pid.");
                    $plate_cascade = get_cascade_tables( 'Plate', 'Original' );
                }
                elsif ($original) {
                    $plate_cascade = get_cascade_tables( 'Plate', 'Original' );
                }
                else {
                    $plate_cascade = get_cascade_tables( 'Plate', 'Daughter' );
                }

                if ($force) {
                    push @$plate_cascade, 'Plate_Prep';
                }

                my $invoiceable_work_cascade = get_cascade_tables('Invoiceable_Work');
                my %cascade_list             = (
                    'Invoiceable_Work' => $invoiceable_work_cascade,
                    'Plate'            => $plate_cascade,
                );

                my %cascade_condition = ( 'Invoiceable_Work' => { 'Invoiceable_Work_Reference' => 'Invoiceable_Work_Reference.FK_Invoice__ID IS NULL', }, );

                $ok = $dbc->delete_records( -table => 'Plate', -field => 'Plate_ID', -id_list => $pid, -cascade => \%cascade_list, -quiet => 1, -replace => $replace, -cascade_condition => \%cascade_condition );

                #if the plate was deleted successfully
                if ($ok) {
                    $dbc->message( -text => "Plate $pid deleted successfully", -session => $Sess );

                    # if the plate has samples associated with it delete them
                    if ( ( scalar(@sids) > 0 ) && !$rearray ) {

                        # Delete the sample records
                        my $ids = join ',', @sids;
                        $ok2 = $dbc->delete_records( -table => 'Sample', -field => 'Sample_ID', -id_list => $ids, -quiet => 1 );
                        if ($ok2) {
                            ## deleted samples successfully ##
                            $dbc->finish_trans("delete_container $pid");
                        }
                        else {
                            $dbc->finish_trans( "delete_container $pid", 'Failed to delete associated samples' );
                        }
                    }
                    else {
                        $dbc->finish_trans("delete_container $pid");
                    }
                }
                else {
                    $dbc->finish_trans( "delete_container $pid", -error => "Failed to delete $self->{prefix} $pid" );
                }
            }
        }
    }
    else { $dbc->message("User does not have permission to delete these plates"); return; }
    return 1;
}

############################################################
# Function that handles the deletion of plate set and plate
############################################################
sub _delete {
    my %args = @_;
    my $dbc  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $ids  = $args{-ids};
    $dbc->delete_records( 'Plate', undef, $ids );

}

#############################
## Act on current Plate(s) ##
#############################

###############
sub add_Note {
###############
    #
    # Add comments for this plate
    #
    my $self     = shift;
    my %args     = &filter_input( \@_, -args => 'plate_id,notes', -mandatory => 'plate_id' );
    my $dbc      = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id = $args{-plate_id};
    my $notes    = $args{-notes};

    my $ok_msg     = "Annotated ";
    my @field_list = ('Plate_Comments');

    my $new_notes  = $dbc->dbh()->quote("; $notes");
    my $first_note = $dbc->dbh()->quote("; $notes");

    my @value_list = ("CASE WHEN Plate_Comments IS NULL THEN $first_note ELSE CONCAT(Plate_Comments,$new_notes) END");

    my $ok = $dbc->Table_update_array( 'Plate', \@field_list, \@value_list, "where Plate_ID in ($plate_id)" );
    if ($ok) {
        return "$ok_msg $ok Plate(s)";
    }
    else {
        return "No changes made to database";
    }
}

# Creates a record in the Fail table
#
########################
sub fail_container {
##########################
    my %args = &filter_input( \@_, -args => 'dbc,plate_ids,reason_id,notes,throw_out', -mandatory => 'dbc,plate_ids,reason_id' );
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_ids  = $args{-plate_ids};                                                               ## (string) list of plate ids
    my $reason_id  = $args{-reason_id};                                                               ## FK_FailReason__ID
    my $notes      = $args{-notes};
    my $throw_away = $args{-throw_out};
    my $user_id    = $dbc->get_local('user_id');

    my $started;
    $started = $dbc->start_trans( -name => 'fail_container' ) if $dbc;                                ### start transaction

    ## Find the list of plates that have been thrown out or failed in the given list of plates
    my @plate_list = $dbc->Table_find( "Plate", "Plate_ID", "WHERE Plate_ID IN ($plate_ids) and (Failed = 'Yes')" );

    ## With Plate.Failed used, I don't think the following check is needed as long as we make sure the integrity of the data
    #my @failed_plates = $dbc->Table_find(
    #    "Fail,FailReason,Object_Class", "Object_ID",
    #    "WHERE Object_ID IN ($plate_ids) and FK_FailReason__ID = FailReason_ID and
    #                                      Object_Class_ID = Fail.FK_Object_Class__ID and Object_Class = 'Plate'"
    #);
    #if ( @plate_list && @failed_plates ) {

    if (@plate_list) {
        my $failed_plates = Cast_List( -list => \@plate_list, -to => 'String' );
        $dbc->warning("The following plates ($failed_plates) have been failed already");
    }

    ## Create the failure prep
    ## Should be done this way, but Record does not support Transactions just yet <CONSTRUCTION>
    #    my %input;
    #    $input{'Current Plates'} = $ids;
    #    $input{'Prep_Comments'} = $fail_reason
    #    $Prep->Record(-ids=>$ids,-protocol=>'Standard',-step=>'Fail Plate',-input=>\%input);

    my ($std_id) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "WHERE Lab_Protocol_Name = 'Standard'" );

    my ($failreason_name) = $dbc->Table_find( 'FailReason', 'FailReason_Name', "WHERE FailReason_ID=$reason_id" );

    my $prep_id = $dbc->Table_append_array( 'Prep', [ 'Prep_Name', 'FK_Employee__ID', 'Prep_DateTime', 'Prep_Comments', 'FK_Lab_Protocol__ID' ], [ "Fail Plate: $failreason_name;", $user_id, &date_time(), $notes, $std_id ], -autoquote => 1 );
    my $index;
    my %plate_prep_inserts;
    map { $plate_prep_inserts{ ++$index } = [ $_, $prep_id ] } split( ',', $plate_ids );

    my $pp_newids = $dbc->smart_append( -tables => 'Plate_Prep', -fields => [ 'FK_Plate__ID', 'FK_Prep__ID' ], -values => \%plate_prep_inserts, -autoquote => 1 );

    my $new_pps;
    $new_pps = scalar( @{ $pp_newids->{Plate_Prep}->{newids} } ) if ( $pp_newids->{Plate_Prep}->{newids} );

    my $fails_ref = alDente::Fail::Fail( -ids => $plate_ids, -object => 'Plate', -fail_status_field => 'Failed', -fail_status_value => 'Yes', -reason => $reason_id, -comments => $notes, );
    my $count = 0;
    if ($fails_ref) {
        $count = scalar @{$fails_ref};
    }

    if ($throw_away) {
        throw_away( -dbc => $dbc, -ids => $plate_ids, -notes => $notes, -confirmed => 1 );
    }
    else {
        $dbc->Table_update_array( 'Plate', ['Plate_Status'], ['Inactive'], "where Plate_ID in ($plate_ids)", -autoquote => 1 );
    }

    if ( $count && $started && $prep_id && $new_pps ) {
        $dbc->finish_trans('fail_container');
        return "Failed plate(s): $plate_ids";
    }
    else {

        #      Call_Stack();
        $dbc->rollback_trans( 'fail_container', -error => 'No plates failed' );
        return "An error has occured!";
    }
}

# Button and setting the pipeline for a plate
#
# Returns:  button and dropdown list
######################
sub set_pipeline_btn {
######################
    my %args = filter_input( \@_, -args => 'dbc', -mandatory => 'dbc' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $pipeline_set = submit( -name => 'Set Pipeline for Plate', -value => 'Set Pipeline for Plate', -class => 'Action' );
    $pipeline_set .= &alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Pipeline__ID', -filter_by_dept => 1, -search => 1, -filter => 1 );
    return $pipeline_set;
}

# Catches the parameters for a pipeline
#
# Returns: None
########################
sub catch_pipeline_btn {
########################
    my %args = filter_input( \@_, -args => 'dbc,quiet' );
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my @plates   = param('Mark');
    my $pipeline = get_Table_Param( -field => 'FK_Pipeline__ID', -dbc => $dbc );
    if ( param('Set Pipeline for Plate') ) {
        my $container = alDente::Container->new( -dbc => $dbc );
        my $updated = $container->set_pipeline( -dbc => $dbc, -plate_id => \@plates, -pipeline => $pipeline );
        Message("Updated pipeline to $pipeline for $updated records");
    }
    return;
}

# Set the pipeline for a given set of plates
#
# Returns: Number of plates updated
##################
sub set_pipeline {
##################
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'dbc,plate_id,pipeline' );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $pipeline = $dbc->get_FK_ID( 'FK_Pipeline__ID', $args{-pipeline} );
    my $plate_id = Cast_List( -list => $args{-plate_id}, -to => "String" );
    my $ok       = $dbc->Table_update_array( 'Plate', ['FK_Pipeline__ID'], [$pipeline], "WHERE Plate_ID IN ($plate_id)", -autoquote => 1 );
    return $ok . " plate ($plate_id)";
}

# Save the plate set for given set of plates
#
# Usage: alDente::Container::save_plate_set_btn(-dbc=>$dbc,-admin_only=>1, -plate_set_label=>"Save Plate Set");
# Return: Plate Set Button
########################
sub save_plate_set_btn {
########################
    my %args       = filter_input( \@_, -args => 'dbc, plate_set_label,admin_only' );
    my $admin_only = $args{-admin_only};
    my $dbc        = $args{-dbc};

    if ($admin_only) {
        my $access = $dbc->get_local('Access')->{$Current_Department};
        unless ( grep /Admin/, @$access ) {
            return;
        }
    }
    my $plate_set_label = $args{-plate_set_label} || 'Save Plate Set';

    my $plate_set_button;

    $plate_set_button = submit( -name => 'Save Plate Set', -value => $plate_set_label, -class => 'Action' );

    return $plate_set_button;
}

########################################
#
#  Method to display a list of plates that are going to be failed, and prompting the user with a
#   Fail reason
#
####################
sub confirm_fail {
####################
    my %args      = &filter_input( \@_, -args => 'dbc,marked,notes', -mandatory => 'dbc,marked,notes' );
    my $dbc       = $args{-dbc};
    my @marked    = @{ $args{-marked} };                                                                   ### (array) List of plates selected to be failed
    my $notes     = $args{-notes};
    my $reason_id = $args{-reason_id};

    my $container = new alDente::Container( -dbc => $dbc );
    my @fail_list;

    foreach (@marked) {                                                                                    ## Retrieve the offsprings of each of the selected plates
        push( @fail_list, split( ',', &get_Children( -dbc => $dbc, -plate_id => $_, -format => 'list', -include_self => 1 ) ) );
    }

    ## Make the list a unique list
    @fail_list = @{ RGTools::RGIO::unique_items( \@fail_list ) };

    #    my $marked_list= join (',', @marked);
    my $plates = join( ',', @fail_list );

    $dbc->warning("Please confirm the failing of these plates");

    return alDente::Container_Views::fail_toolbox( -dbc => $dbc, -plates => $plates, -tree => 1 );
}

########
sub move {
########
    #
    # Move location
    #

}

# Create an On hold button
#
# Returns: HTML Button
######################
sub onhold_plate_btn {
######################
    my $onhold_btn = submit( -name => 'Set Onhold Plate', -value => 'Set Plate Status to On Hold', -class => 'Std' );
    my $plate_comment_field = " Add to plate comments (Optional) " . textfield( -name => 'Plate_Comments', -size => 20 );
    return $onhold_btn . $plate_comment_field;
}

# Catches the on hold plate btn, sets the status of plates to On Hold
# Added the ability to set the status of plates to Failed when param('Set Failed Plate') is set
# Returns: none
############################
sub catch_onhold_plate_btn {
############################
    my %args   = filter_input( \@_, -args => 'dbc' );
    my $dbc    = $args{-dbc};
    my @plates = param('Mark');
    unless (@plates) {
        @plates = param('FK_Plate__ID');
    }
    my $num_updated    = 0;
    my $status         = '';
    my $plate_comments = '';
    if ( param('Set Onhold Plate') ) {
        $status         = 'On Hold';
        $plate_comments = param('Plate_Comments');
    }

    #    if (param('Set Failed Plate')) {
    #        $status = 'Failed';
    #        $plate_comments = param('Failed_Plate_Comments');
    #    }

    if ( $status ne '' ) {
        $num_updated = set_plate_status( -dbc => $dbc, -plate_id => \@plates, -status => $status );
        if ($plate_comments) {
            my $plates = Cast_List( -list => \@plates, -to => 'String' );
            my $container_obj = alDente::Container->new( -dbc => $dbc );
            $container_obj->add_Note( -plate_id => $plates, -notes => $plate_comments, -dbc => $dbc );
        }
        $dbc->message("$num_updated plates were set to '$status'");
    }
    return;
}

##################################
# Set the plate status
#
# Returns: number of plates updated
######################
sub set_plate_status {
######################
    my %args     = filter_input( \@_, -args => 'dbc,plate_id,status', -mandatory => 'plate_id' );
    my $dbc      = $args{-dbc};
    my $plate_id = $args{-plate_id};
    my $status   = $args{-status};

    my $plate_ids = Cast_List( -list => $plate_id, -to => 'String' );
    my @available_statuses = get_plate_status_list( -dbc => $dbc );

    my $num_plates_updated;
    if ( grep /^$status$/, @available_statuses ) {
        if ( $status eq 'Inactive' ) {
            my @not_failed = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE Plate_ID in ($plate_ids) and Failed = 'No'" );
            if ( int(@not_failed) ) {
                my $list = join ',', @not_failed;
                $dbc->message("These plates are not Failed. Inactive status is for failed plates. Please fail the plates instead. ($list)");
                return 0;
            }
        }
        $num_plates_updated = $dbc->Table_update_array( 'Plate', ['Plate_Status'], [$status], "WHERE Plate_ID IN ($plate_ids)", -autoquote => 1 );
    }
    else {
        $dbc->message("Status was not in available list of plate statuses");
        return 0;
    }
    return $num_plates_updated;
}

# Create an On hold button
#
# Returns: HTML Button
######################
sub plate_archive_btn {
######################
    my $archive_btn = submit( -name => 'Set Plate Archive', -value => 'Set Plate Status to Archived', -class => 'Std' );
    return $archive_btn;
}

# Catches the on hold plate btn, sets the status of plates to On Hold
#
# Returns: none
############################
sub catch_plate_archive_btn {
############################
    my %args   = filter_input( \@_, -args => 'dbc' );
    my $dbc    = $args{-dbc};
    my @plates = param('Mark');
    unless (@plates) {
        @plates = param('FK_Plate__ID');
    }
    my @library_plate_number = param('library_plate_number');
    if (@library_plate_number) {
        my $condition = join( ",", map {"'$_'"} @library_plate_number );
        @plates = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE Plate_Status = 'Active' AND CONCAT(FK_Library__Name,'-',Plate_Number) IN ($condition)" );
    }
    my $plate_comments = param('Plate_Comments');
    my $num_updated    = 0;
    if ( param('Set Plate Archive') ) {
        $num_updated = set_plate_archive_status( -dbc => $dbc, -plate_id => \@plates );
        if ($plate_comments) {
            my $plates = Cast_List( -list => \@plates, -to => 'String' );
            my $container_obj = alDente::Container->new( -dbc => $dbc );
            $container_obj->add_Note( -plate_id => $plates, -notes => $plate_comments, -dbc => $dbc );
        }
        $dbc->message("$num_updated plates were set to 'Archived'");
    }
    return;
}

# Set the plates to archived
#
# Returns: number of plates archived
##############################
sub set_plate_archive_status {
##############################
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'dbc,plate_id' );
    my $dbc      = $args{-dbc};
    my $plate_id = $args{-plate_id};

    my $plate_ids = Cast_List( -list => $plate_id, -to => 'String' );

    ### Find the current locations of the plates <CONSTRUCTION>
    #my @current_locations = $dbc->Table_find( 'Plate', 'FK_Rack__ID', "WHERE Plate_ID IN ($plate_ids)" );
    ### Check if the plate is in temporary rack or not...
    #my @temporary_racks = $dbc->Table_find( 'Rack,Equipment', "Rack_ID", "WHERE FK_Equipment__ID = Equipment_ID and Equipment_Name = 'TBD'" );
    #my ( $intersec, $a_only, $b_only ) = &RGmath::intersection( \@current_locations, \@temporary_racks );
    #if ( int(@$intersec) > 0 ) {
    #$dbc->error("One or more plates is located in a temporary storage location");
    #return 0;
    #}

    #get a list of tmp location
    my ($temporary_racks) = $dbc->Table_find( 'Rack,Equipment', "Group_Concat(Rack_ID)", "WHERE FK_Equipment__ID = Equipment_ID and Equipment_Name = 'TBD'" );

    #see if any plate in tmp location
    my ($tmp_plates) = $dbc->Table_find( 'Plate', 'Group_Concat(Plate_ID)', "WHERE Plate_ID IN ($plate_ids) AND FK_Rack__ID IN ($temporary_racks)" );

    if ($tmp_plates) {
        my $tmp_plates_link = &Link_To( $dbc->config('homelink'), $tmp_plates, "&Info=1&Table=Plate&Field=Plate_ID&Like=$tmp_plates", -window => ['newwin'] );
        $dbc->error("One or more plates ($tmp_plates_link) is located in a temporary storage location");
        return 0;
    }

    my @plates_in_TBD = $dbc->Table_find( 'Plate,Rack,Equipment', 'Plate_ID', "WHERE Rack_ID = FK_Rack__ID AND FK_Equipment__ID = Equipment_ID AND Equipment_Name = 'TBD' AND Plate_ID IN ($plate_ids)" );
    my $plates_in_TBD = join( ",", map { $self->prefix . $_ } @plates_in_TBD );

    if ($plates_in_TBD) { Message("Warning: The following plate(s) is located in a temporary storage location but still archived: $plates_in_TBD") }

    my $archived = set_plate_status( -dbc => $dbc, -plate_id => $plate_ids, -status => 'Archived' );
    return $archived;
}

# Get a list of available plate statuses
#
# Returns: Array of plate statuses
###########################
sub get_plate_status_list {
###########################
    my %args         = filter_input( \@_, -args => 'dbc' );
    my $dbc          = $args{-dbc};
    my @plate_status = $dbc->get_enum_list( 'Plate', 'Plate_Status' );
    return @plate_status;
}

#################################################################
# The methods are essentially externally available routines
# Generally they may act on more than one container at a time
#################################################################

##########
{
    no warnings;

    sub home {
        ##########
        #
        # home page for Containers...
        #
        use warnings;
        print "home page for Containers under construction..";

        return;
    }
}

#################
sub throw_away {
#################
    #
    # Throw away containers listed
    # If a plate is being thrown out, there will be a Thrown Out prep recorded for it and it will be moved to garbage rack
    #

    my %args = &filter_input( \@_, -args => 'dbc,ids,notes' );

    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $ids       = $args{-ids};
    my $no_record = $args{-no_record};                                                               ## suppress tracking of record in prep table (specifically used when a throw away step within a protocol already tracked)
    my $user_id   = $dbc->get_local('user_id');

    my $notes     = $args{-notes};
    my $confirmed = $args{-confirmed};

    if ($confirmed) {
        ### Garbage Location
        ( my $garbage ) = $dbc->Table_find( 'Rack', 'Rack_ID', "where Rack_name = 'Garbage'" );
        ### Move to garbage, set status to Thrown Out
        my $ok = $dbc->Table_update_array( 'Plate', ['FK_Rack__ID'], [$garbage], "where Plate_ID in ($ids)", -autoquote => 1 );
        $dbc->Table_update_array( 'Plate', ['Plate_Status'], ['Thrown Out'], "where Plate_ID in ($ids) AND Plate_Status NOT IN ('Exported')", -autoquote => 1 );

        #      Message("$ok container(s) Thrown away ");
        if ( $ok && !$no_record ) {
            my $myPrep = alDente::Prep->new( -dbc => $dbc, -user => $user_id );

            # flag plates to be thrown away as 'current plates' for now
            my %input;
            $input{'Current Plates'} = $ids;
            $input{'Prep Step Name'} = 'Throw Away';
            $myPrep->Record( -ids => $ids, -protocol => 'Standard', -input => \%input, -change_location => 0, -local_focus => 1 );
            return $ok;
        }
        else {
            return $ok;
        }
    }
    else {
        alDente::Container_Views::confirm_event( -dbc => $dbc, -ids => $ids, -event => 'Throw Out', -notes => $notes );
    }
    return;
}

###################
sub export_Plate {
###################
    #
    # Export containers listed
    #
    my %args = &filter_input( \@_, -args => 'dbc,ids', -mandatory => 'ids,dbc' );

    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id = $dbc->get_local('user_id');
    my $ids     = $args{-ids};

    my $notes     = $args{-notes};       ## mandatory to ensure we know where it went...
    my $confirmed = $args{-confirmed};
    my $comments  = $args{-comments};

    if ( $notes =~ /untracked/i ) { $notes = '' }    ## place holder for dropdown menu - defaults to std export rack..

    my $default_location = 'untracked export rack';
    unless ( $notes || $comments ) { Message("comments (destination details) required"); return 0; }
    unless ($ids) { Message("List of plate ids required"); return 0; }

    $ids = Cast_List( -list => $ids, -to => 'string' );

    if ($confirmed) {

        #   (my $exported) = $dbc->Table_find('Rack','Rack_ID',"where Rack_Name like 'Exported'");
        my $exported;

        if ( $notes && !( $notes =~ /not tracked/i ) ) {
            ($exported) = $dbc->Table_find( 'Location,Equipment,Rack', 'Rack_ID', "WHERE FK_Location__ID = Location_ID AND FK_Equipment__ID = Equipment_ID AND Location_Name='$notes' " );
        }
        else {
            ($exported) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name = 'Exported'" );
        }

        my $ok = $dbc->Table_update_array( 'Plate', [ 'FK_Rack__ID', 'Plate_Status' ], [ $exported, 'Exported' ], "where Plate_ID in ($ids)", -autoquote => 1 );
        Message("Updated $ok records");

        $notes .= $default_location;
        if ($ok) {
            my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id );
            $Prep->Record( -ids => $ids, -protocol => 'Standard', -step => 'Export', -notes => 'To: ' . $notes . " - Comments: $comments", -change_location => 0, -local_focus => 1 );
        }

        return;
    }
    else {
        $dbc->Table_retrieve_display(
            'Plate,Rack',
            [ 'Plate_ID', 'FK_Library__Name as Library', 'Plate_Number as Number', 'Rack_Alias as Current_Location', 'Plate_Status as Current_Status', 'Failed as Current_Failed' ],
            "WHERE FK_Rack__ID=Rack_ID AND Plate_ID in ($ids)"
        );

        my $stats = alDente::Tray::group_ids( $dbc, 'Plate', $ids );
        Message("Warning: Are you sure?");

        print alDente::Form::start_alDente_form( $dbc, 'ExportPlates' )
            . hidden( -name => 'rm', -value => 'Export Plates' )
            . hidden( -name => 'cgi_application', -value => 'alDente::Container_App' )
            . submit( -name => "Export Plates", -value => "Confirm Export of these  $stats->{physical_plates} Container(s)", -class => 'Action' )
            . hidden( -name => 'Move_Plate_IDs',  -value => $ids )
            . hidden( -name => 'Export_Comments', -value => $comments )
            . hidden( -name => 'Destination',     -value => $notes )
            . hidden( -name => 'Confirmed',       -value => 1 )
            . "</form>";

        print create_tree( -tree => { 'Shipping Manifest' => alDente::Rack_Views::shipping_manifest( -dbc => $dbc, -id_list => $ids, -key => 'Original_Source_Name as Subject', -group => 'Sample_Type.Sample_Type' ) } );

        $notes ||= $default_location;
        Message("Exporting to '$notes'.  Note: $notes $comments");

        &main::leave();
    }

    return;
}

#######################
sub activate_Plate {
#######################
    #
    # Export containers listed
    #
    my %args = &filter_input( \@_, -args => 'dbc,ids', -mandatory => 'ids,dbc' );

    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $ids     = $args{-ids};
    my $rack_id = $args{-rack_id};
    my $confirm = $args{-confirm};
    $ids = Cast_List( -list => $ids, -to => 'string' );

    if ( !$rack_id ) {
        $rack_id = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Alias = 'In Use'" );
    }

    if ($confirm) {
        my $ok = $dbc->Table_update_array( 'Plate', [ 'Plate_Status', 'Failed' ], [ 'Active', 'No' ], "where Plate_ID in ($ids)", -autoquote => 1 );
        $dbc->message("Re-activated $ok plate(s): $ids.");
        if ($rack_id) {
            use alDente::Rack;
            &alDente::Rack::move_Items( -dbc => $dbc, -type => 'Plate', -ids => $ids, -rack => $rack_id, -confirmed => 1 );
        }
    }
    else {
        $dbc->Table_retrieve_display(
            'Plate,Rack',
            [ 'Plate_ID', 'FK_Library__Name as Library', 'Plate_Number as Number', 'Rack_Alias as Current_Location', 'Plate_Status as Current_Status', 'Failed as Current_Failed' ],
            "WHERE FK_Rack__ID=Rack_ID AND Plate_ID in ($ids)"
        );

        print alDente::Form::start_alDente_form($dbc);
        print hidden( -name => 'Plate_ID',        -value => $ids );
        print hidden( -name => 'rm',              -value => 'Re-Activate' );
        print hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 );
        print hidden( -name => 'Rack_ID',         -value => $rack_id, -force => 1 );
        print submit( -name => 'Confirm Re-Activation', -class => "Action" );

        print end_form();
        &main::leave();
    }
}

##################
sub thaw_Plate {
##################
    my %args = filter_input( \@_, -args => 'ids', -mandatory => 'ids' );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id = $dbc->get_local('user_id');
    my $ids     = $args{-ids};
    Message( "Thawing Plate(s): " . $ids );
    my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id );
    $Prep->Record( -ids => $ids, -protocol => 'Standard', -step => 'Thaw', -local_focus => 1 );

    my $object = alDente::Container->new( -dbc => $dbc, -id => $ids );
    $object->home_page( -brief => $scanner_mode );

}

################################################################################
#  Functions relating to Library
################################################################################

################################################################################
# General Plate Functions  (barcode, info)
################################################################################

##############################
sub Check_Library_Plates {
##############################
    #
    # OLD
    #
    my $library = shift;
    my $plate   = shift;
    my $dbc     = $Connection;

    print "Old ?" . Call_Stack();

    if ($library) {
        my %Status;
        my %Plates
            = $dbc->Table_retrieve( 'Plate', [ 'count(*) as Count', 'Plate_Number as Number', 'FK_Plate_Format__ID as Format' ], "where FK_Library__Name like '$library' GROUP BY Plate_Number,FK_Plate_Format__ID Order by Plate_Number,Plate_Created ASC" );

        my %Counts;
        my @formats;
        my @numbers;
        my $index = 0;
        while ( defined $Plates{Count}[$index] ) {
            my $count  = $Plates{Count}[$index];
            my $number = $Plates{Number}[$index] || 0;
            my $format = $Plates{Format}[$index];
            unless ( grep /^$format$/, @formats ) { push( @formats, $format ); }
            unless ( grep /^$number$/, @numbers ) { push( @numbers, $number ); }
            $Counts{$format}{$number} = $count;
            $index++;
        }

        print &vspace(10);
        my $Show = HTML_Table->new();
        $Show->Set_Title( "$library Plates>", fsize => '-1' );

        my @headers = ("Plate Number");
        foreach my $format (@formats) {
            my ($format_info) = &get_FK_info( $dbc, 'FK_Plate_Format__ID', $format );
            $format_info =~ s /well\s/well<BR>/;
            push( @headers, $format_info );
        }

        $Show->Set_Headers( \@headers );

        foreach my $number (@numbers) {
            my @line = ($number);
            foreach my $format (@formats) {
                my $count = $Counts{$format}{$number} || 0;
                push( @line, $count );
            }
            $Show->Set_Row( \@line );
        }
        $Show->Printout();
    }
    else { Message("Need to choose Library"); }
    return 1;
}

############
sub store {
############
    #OLD..
    # Save plate Storage location to database
    #
    my %args = filter_input( \@_, -args => 'plate_id,rack', -mandatory => 'plate_id' );

    my $plates  = $args{-plate_id};                                                                # list of plates
    my $rack    = $args{-rack};                                                                    # rack id or barcode;
    my $event   = $args{-event};
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id = $dbc->get_local('user_id');
    my $quiet   = $args{-quiet};

    $rack ||= param('Rack Choice');

    my $num_plates = int( my @list = split ',', $plates );

    my $current_plate_set = join ',', $dbc->Table_find( 'Plate_Set', 'Plate_Set_Number', "where FK_Plate__ID in ($plates) group by Plate_Set_Number having count(*) = $num_plates" );

    if ( $current_plate_set =~ /,/ ) {
        Message("Plate Set possibilities not unique Possible Plate Sets:($current_plate_set)");
        $current_plate_set = 'NULL';
    }
    $current_plate_set ||= 'NULL';

    my $rack_id;
    if    ( $rack =~ /Rac(\d+)/i ) { $rack_id = $1; }
    elsif ( $rack =~ /(\d+)/ )     { $rack_id = $rack; }
    else {
        Message("Error Storing on Rack $rack");
        return 0;
    }

    ####### if this is during Protocol steps ...
    if ( param('Step Name') ) {
        my $current_date = &date_time();
        print "Storing Plates: $plates";
        my $protocol = param('Protocol');
        my $Lprotocol_id = get_FK_ID( $dbc, 'FK_Lab_Protocol__ID', $protocol );
        foreach my $thisplate ( split ',', $plates ) {
            my $ok = $dbc->Table_append_array(
                'Prep',
                [ 'FK_Plate__ID', 'FK_Plate_Set__Number', 'FK_Employee__ID', 'Prep_DateTime', 'Prep_Name',       'FK_Lab_Protocol__ID' ],
                [ $thisplate,     $current_plate_set,     $user_id,          $current_date,   'Store Plate Set', $Lprotocol_id ],
                -autoquote => 1
            );
            if ($ok) { Test_Message( "Stored Plate $thisplate", $testing ); }
            else     { Message("Error saving Storage Step"); }
        }
    }

    my @fields = ('FK_Rack__ID');
    my @values = ($rack_id);

    #### Change status to Exported if moved to 'Exported' rack... ###
    my ($rack_name) = $dbc->Table_find( 'Rack', 'Rack_Name', "WHERE Rack_ID = $rack_id" );
    if ( $rack_name =~ /Export/ ) {
        push( @fields, 'Plate_Status' );
        push( @values, 'Exported' );
    }

    my $ok = $dbc->Table_update_array( 'Plate', \@fields, \@values, "where Plate_ID in ($plates)", -autoquote => 1 );
    if ( $ok > 0 ) {
        if ( $rack_name !~ /In Use/ ) { Message("Stored $ok plates ($plates) on Rack $rack_id ($rack_name)") }
        clear_plate_set($dbc);
    }
    else {
        $dbc->warning("plates $plates not moved");
        return 0;
    }

    if ($event) {
        my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id );
        $Prep->Record( -ids => $plates, -protocol => 'Standard', -step => $event, -change_location => 0, -local_focus => 1 );
    }

    return $rack_id;
}

##################################
# generates the plate name from a plate_id
# return: the plate name
##################################
sub get_plate_name {
    ##################################
    # First handle method VS function call
    unless ( UNIVERSAL::isa( $_[0], 'alDente::Container' ) ) {
        my %args = &filter_input( \@_, -args => 'dbc,id' );
        my $dbc  = $args{-dbc};
        my $id   = $args{-id};
        my $obj  = alDente::Container->new( -dbc => $dbc, -id => $id );
        return $obj->get_plate_name(%args);
    }
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc,id' );

    my $dbc = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $id = $args{-id};

    my ($name_str) = $dbc->Table_find( "Plate", "FK_Library__Name,Plate_Number,Parent_Quadrant,Plate_Parent_Well", "WHERE Plate_ID=$id" );
    my ( $libname, $platenum, $quad, $well ) = split ',', $name_str;
    my $name = "$libname-$platenum";
    if ( $quad && ( $quad ne '' ) ) {
        $name .= $quad;
    }
    if ( $well && ( $well ne '' ) ) {
        $name .= "_${well}";
    }
    return $name;
}

##################################
sub clear_plate_set {
##################################
    #
    # Clears Defined Plate Set
    #
    my $dbc = shift;

    $current_plates = "";
    $plate_set      = "";
    $plate_id       = "";

    alDente::Container::reset_current_plates( $dbc, '' );
    $dbc->{plate_set} = '';
    $dbc->{plate_id}  = '';
    $dbc->{step_name} = '';
    return;
}

########################################
# A function to retrieve the birth protocol of a plate
#
# <snip>
# Eg. my %info = get_birth_protocol($dbc,$plate_id);
#
# </snip>
#
# Options: -dbc (database handle)
#          -plate_id
#
# Return: Returns a hash ref info about birth protocol of this plate
#
############################
sub get_birth_protocol {
############################
    my %args = &filter_input( \@_, -args => 'dbc,plate_id' );
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id = $args{-plate_id};
    my $interval = $args{-interval} || 2000;                                                        ## optional interval in seconds (plates created within N seconds of prep)

    my %Result;
    my %Data = $dbc->Table_retrieve( 'Plate,Plate_Format', [ 'Plate_ID', 'FKParent_Plate__ID', 'Plate_Created', 'Plate_Size', 'Plate_Format_Type' ], "WHERE FK_Plate_Format__ID=Plate_Format_ID AND Plate.Plate_ID IN ($plate_id)" );

    unless ( $Data{Plate_ID}[0] ) {
        $dbc->session->warning("No Plate ($plate_id) found in database (?)");
        $dbc->Table_retrieve( 'Plate,Plate_Format', [ 'Plate_ID', 'FKParent_Plate__ID', 'Plate_Created', 'Plate_Size', 'Plate_Format_Type' ], "WHERE FK_Plate_Format__ID=Plate_Format_ID AND Plate.Plate_ID IN ($plate_id)" );
        return;
    }                                                                                               ## return if not found...

    $Result{parent}  = $Data{FKParent_Plate__ID}[0];
    $Result{created} = $Data{Plate_Created}[0];
    $Result{size}    = $Data{Plate_Size}[0];
    $Result{format}  = $Data{Plate_Format_Type}[0];

    unless ( $Result{parent} ) {
        ### If a plate has been pooled
        my @poolings = $dbc->Table_find( 'Sample_Pool,PoolSample', 'FK_Plate__ID', "WHERE Sample_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND FKTarget_Plate__ID in ($plate_id) ORDER BY FK_Plate__ID" );
        if (@poolings) {
            $Result{parent} = join( ',', @poolings );
        }
        else {
            ## original plate - (not created within protocol)
            $Result{protocol_name} = "Original Plate";
            return \%Result;
        }
    }

    ## check if plate is created within a protocol ##
    # Figure out if the prep date time of the transfer step is whitin 3 seconds of the creation of the plate

    my $sql_date = convert_date( $Result{created}, 'SQL' );
    my $prep_condition = "Plate_Prep.FK_Plate__ID IN($Result{parent}) AND Prep.Prep_DateTime BETWEEN DATE_SUB('$sql_date',INTERVAL $interval SECOND) AND DATE_ADD('$sql_date',INTERVAL $interval SECOND)";

    my %Found = $dbc->Table_retrieve(
        'Prep,Plate_Prep,Lab_Protocol',
        [ 'Prep_Name', 'Prep.FK_Employee__ID', 'Lab_Protocol_Name', 'Lab_Protocol_ID' ],
        "WHERE Lab_Protocol.Lab_Protocol_ID=Prep.FK_Lab_Protocol__ID AND Prep.Prep_ID=Plate_Prep.FK_Prep__ID AND $prep_condition"
    );

    my $index = 0;
    while ( defined $Found{Lab_Protocol_ID}[$index] ) {
        my $step_name = $Found{Prep_Name}[$index];

        #    unless ($step_name) { next }
        if ( &alDente::Protocol::new_plate($step_name) ) {    ## IF this is a transfer step...
            $Result{protocol_name} = $Found{'Lab_Protocol_Name'}[$index];
            $Result{employee}      = $Found{'FK_Employee__ID'}[$index];
            last;
        }
        $index++;
    }

    ### If we could not find the birth protocol, look to see if this plate has been preprinted, and if it has, what protocol was it at?
    if ( !$Result{protocol_name} ) {

        #   if(alDente::Protocol::new_plate($step_name,-step_type=>'Pre-Print')) { <CONSTRUCTION> when check_if_new_plate() is fixed, use this line instead
        $index = 0;
        while ( defined $Found{Lab_Protocol_ID}[$index] ) {
            my $step_name = $Found{Prep_Name}[$index];
            if ( $step_name =~ /^Pre-Print/ ) {
                $Result{protocol_name} = 'Pre-Printed in ' . $Found{'Lab_Protocol_Name'}[$index];
                $Result{employee}      = $Found{'FK_Employee__ID'}[$index];
                last;
            }
            $index++;
        }
    }

    return \%Result;
}

########################################
# Generates a small label describing the container
#
# Returns a string containing info about a container
####################
sub label {
####################
    my $self      = shift;
    my %args      = &filter_input( \@_, -args => "plate_id,highlight" );
    my $dbc       = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id  = $args{-plate_id} || $self->{plate_id};
    my $highlight = $args{-highlight};                                                                               ## highlight plates (eg direct ancestorss
    my $colour    = $args{-colour} || 'White';

    if ( $highlight && !$colour ) { $colour = 'lightgreen'; }

    my $P;
    if ( $P->{id} == $plate_id ) {
        $P = $self;
    }
    else {
        $P = alDente::Container->new( -dbc => $dbc, -id => $plate_id );
    }

    my $fk_os_id = $P->value('Library.FK_Original_Source__ID');
    my ($os_name) = $dbc->Table_find( 'Original_Source', 'Original_Source_Name', "where Original_Source_ID = " . $P->value('Library.FK_Original_Source__ID') );

    my ($rac_name) = $dbc->Table_find( 'Rack', 'Rack_Name', "where Rack_ID = " . $P->value('Plate.FK_Rack__ID') );

    my @plate_info;
    push( @plate_info, $P->value('Plate.Plate_Class') )              if ( $P->value('Plate.Plate_Class') );
    push( @plate_info, $P->value('Plate_Format.Well_Capacity_mL') )  if ( $P->value('Plate_Format.Well_Capacity_mL') );
    push( @plate_info, $P->value('Plate_Format.Plate_Format_Type') ) if ( $P->value('Plate_Format.Plate_Format_Type') );
    push( @plate_info, $P->value('Library_Plate.Plate_Position') )   if ( $P->value('Library_Plate.Plate_Position') );

    my $name;
    $name .= $P->value('Plate.Plate_Type') if ( $P->value('Plate.Plate_Type') );
    $name .= ' (' . $P->value('Plate.Plate_Size') . ')' if ( $P->value('Plate.Plate_Size') );
    $name .= lbr . $P->value('Plate.FK_Library__Name') . '-' . $P->value('Plate.Plate_Number');
    $name .= $P->value('Plate.Parent_Quadrant') if ( $P->value('Plate.Parent_Quadrant') );
    $name .= $P->value('Plate.Parent_Well') if $P->value('Plate.Parent_Well');
    $name .= ' (' . join( ',', @plate_info ) . ')' if (@plate_info);
    $name .= lbr . $P->value('Library.Library_FullName')                           if ( $P->value('Library.Library_FullName') );
    $name .= lbr . '<i>' . $P->value('Employee.Initials') . '</i>'                 if ( $P->value('Employee.Initials') );
    $name .= ' (' . $P->value('Plate.Plate_Created') . ')'                         if ( $P->value('Plate.Plate_Created') );
    $name .= lbr . $P->{protocol_name}                                             if ( $P->{protocol_name} );
    $name .= lbr . 'RAC' . $P->value('Plate.FK_Rack__ID') . ' (' . $rac_name . ')' if ($rac_name);
    $name .= lbr . $P->value('Tube.Position')                                      if $P->value('Tube.Position');
    $name .= lbr . $os_name if ( $P->value('Plate.Plate_Type') eq 'Tube' );

    #comments... should it be added?

    return "<Table cellspacing=0 cellpadding=0 nowrap><TR><TD bgcolor='$colour'>$name</TD></TR></Table>";
}

####################################
# Add Plate record to the database.
#  (requires specification of ALL mandatory fields)
#
# <snip>
#
# Examples:
#
# To make a plate with Clone Samples for Sequencing:
#&Library_Plate::add_Plate(-plate_size=>$plate_size, -library=>$library_name, -rack_id=>'1', -employee=>$user_id, -plate_format_id=>$format_id, -plate_status=>'Active', -plate_type=>'Library_Plate', -plate_test_status=>'Production',-add_samples=>'clone', -plate_contents=>$plate_contents, -parent_plate_id=>$plate_id,-plate_comments=>'Test comments');
#
# To make a plate with Extraction Samples for Lib_Construction:
#
#&Library_Plate::add_Plate(-plate_size=>$plate_size, -library=>$library_name, -rack_id=>'1', -employee=>$user_id, -plate_format_id=>$format_id, -plate_status=>'Active', -plate_type=>'Library_Plate', -plate_test_status=>'Production',-add_samples=>$extraction, -plate_contents=>$plate_contents, -parent_plate_id=>$plate_id,-plate_comments=>'Test comments');
#
# </snip>
#
# Return: 0 on failure, 1 if success
####################################
sub add_Plate {
#############
    my $self = shift;
    my %args = &filter_input( \@_ );
    if ( $args{ERRORS} ) { Message("Input Errors Found: $args{ERRORS}"); return; }

    my $input = $args{-input};
    if ($input) {
        foreach my $key ( keys %{$input} ) {
            $args{"-$key"} = $input->{$key};
        }
    }
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $plate_size  = $args{-plate_size};                 ### size of new plate (96 or 384)
    my $created     = $args{-created} || &date_time();    ### default to now..
    my $library     = $args{-library};                    ### library (must be unique, 5 alpha-num characters)
    my $rack_id     = $args{-rack_id};                    ### rack_id
    my $employee_id = $args{-employee_id};                ### employee (id) requesting new plate
    my $employee    = $args{-employee};                   ### employee (name) requesting new plate

    my $comments          = $args{-comments};                             ### (optional)
    my $plate_status      = $args{-plate_status} || 'Active';             ### (generally 'Active' or 'Reserved' (for later ReArray)
    my $failed            = $args{-failed} || 'No';                       ###
    my $plate_test_status = $args{-plate_test_status} || 'Production';    ### (optional: production or test) - default to production
    my $format            = $args{'-format'};                             ### (format in text format)
    my $plate_format_id   = $args{-plate_format_id};                      ### (format_id if known)

    my $plate_type = $args{-type}  || 'Library_Plate';
    my $quiet      = $args{-quiet} || 0;                                  ### quiet output (generate no stdout print statements)
    my $sample_alias = $args{-sample_alias_hash};                         ### hashref that defines the sample aliases
    ### in the form { '<well>' => {'alias' => '<aliasname>', 'type' => '<aliastype>' .... } }
    my $parent_plate_id = $args{-parent_plate_id};                        ### optional set parent plate ID

    my $plate_contents = $args{-plate_contents} || 'clone';               ### optional set plate contents.. defaults to 'clone'
    my $sample_type_id = $args{-sample_type_id};
    my $add_samples    = $args{-add_samples} || 'n';                      ### optionally add clone samples, extraction samples or none (defaults to 'n')
    my $pipeline_id    = $args{-pipeline_id};                             ### pipeline id of the plate
    my $source_id      = $args{-source_id};                               ### add source ID for clones
    my $qc_status      = $args{-qc_status} || 'N/A';
    $args{-qc_status}         ||= 'N/A';
    $args{-plate_status}      ||= 'Active';
    $args{-failed}            ||= 'No';
    $args{-current_vol_units} ||= 'uL';
    my %Aliases;
    $Aliases{Plate}{plate_id}          = 'Plate.Plate_ID';
    $Aliases{Plate}{original_plate_id} = 'Plate.FKOriginal_Plate__ID';
    $Aliases{Plate}{parent_plate_id}   = 'Plate.FKParent_Plate__ID';
    $Aliases{Plate}{employee}          = 'Plate.FK_Employee__ID';
    $Aliases{Plate}{plate_number}      = 'Plate.Plate_Number';
    $Aliases{Plate}{library}           = 'Plate.FK_Library__Name';
    $Aliases{Plate}{rack_id}           = 'Plate.FK_Rack__ID';
    $Aliases{Plate}{plate_format_id}   = 'Plate.FK_Plate_Format__ID';
    $Aliases{Plate}{plate_status}      = 'Plate.Plate_Status';
    $Aliases{Plate}{failed}            = 'Plate.Failed';
    $Aliases{Plate}{plate_size}        = 'Plate.Plate_Size';
    $Aliases{Plate}{sample_type_id}    = 'Plate.FK_Sample_Type__ID';

    #    $Aliases{Plate}{plate_contents}    = 'Plate.Plate_Content_Type';

    #    $Aliases{Plate}{plate_application} = 'Plate.Plate_Application';
    $Aliases{Plate}{plate_type}        = 'Plate.Plate_Type';
    $Aliases{Plate}{plate_test_status} = 'Plate.Plate_Test_Status';
    $Aliases{Plate}{plate_comments}    = 'Plate.Plate_Comments';
    $Aliases{Plate}{parent_quadrant}   = 'Plate.Parent_Quadrant';
    $Aliases{Plate}{plate_position}    = 'Plate_Tray.Plate_Position';
    $Aliases{Plate}{plate_class}       = 'Plate.Plate_Class';
    $Aliases{Plate}{unused_wells}      = 'Library_Plate.Unused_Wells';
    $Aliases{Plate}{problematic_wells} = 'Library_Plate.Problematic_Wells';
    $Aliases{Plate}{empty_wells}       = 'Library_Plate.Empty_Wells';
    $Aliases{Plate}{NGs}               = 'Library_Plate.No_Grows';
    $Aliases{Plate}{SGs}               = 'Library_Plate.Slow_Grows';
    $Aliases{Plate}{plate_created}     = 'Plate.Plate_Created';
    $Aliases{Plate}{qc_status}         = 'Plate.QC_Status';
    $Aliases{Plate}{pipeline_id}       = 'Plate.FK_Pipeline__ID';
    $Aliases{Plate}{current_vol_units} = 'Plate.Current_Volume_Units';
    $Aliases{Plate}{sample_type_id}    = 'Plate.FK_Sample_Type__ID';
    $Aliases{Plate}{plate_label}       = 'Plate.Plate_Label';

    ## Set values ##
    $args{-type} = 'Library_Plate';

    # if pipeline_id is not defined, set it now
    if ( !$args{-pipeline_id} ) {
        ( $args{-pipeline_id} ) = $dbc->Table_find( "Pipeline", "Pipeline_ID", "WHERE Pipeline_Name='TBD'" );
    }
    ### Error Checking ###
    unless ($dbc) { print "No Database handle supplied"; return 0; }

    ### Ensure all info is available ###
    my $failed          = '';
    my @mandatory_input = ( 'plate_size', 'library', 'rack_id', 'sample_type_id', 'employee', 'plate_format_id', 'plate_status', 'plate_type', 'qc_status', 'pipeline_id' );
    my @optional_input  = ( 'plate_class', 'plate_test_status', 'plate_comments', 'parent_plate_id', 'plate_contents', 'current_vol_units', 'plate_label', 'failed' );

    foreach my $input (@mandatory_input) {
        if ( $args{"-$input"} ) {
            unless ($quiet) { print "$input = " . $args{"-$input"} . "\n" }
        }
        else { $failed .= "$input\n" }
    }

    if ($failed) {
        unless ($quiet) { print "Failed - Missing Data:\n***********************\n$failed\n" }
        return 0;
    }

    foreach my $input (@mandatory_input) {
        my $value = $args{"-$input"};
        if ( defined $Aliases{Plate}{$input} ) { $input = $Aliases{Plate}{$input} }
        elsif ( $input =~ /(.*)\.(.+)/ ) { }                            ## table spec already supplied...
        else                             { $input = "Plate.$input" }    ## add table to field specficiation

        if ( defined $value ) {

            #print "input: $input value: $value\n";
            $self->value( $input, $value );
        }
    }

    foreach my $input (@optional_input) {
        my $value = $args{"-$input"};
        if ( defined $Aliases{Plate}{$input} ) { $input = $Aliases{Plate}{$input} }
        elsif ( $input =~ /(.*)\.(.+)/ ) { }                            ## table spec already supplied...
        else                             { $input = "Plate.$input" }    ## add table to field specficiation

        if ( defined $value ) {

            #print "input: $input value: $value\n";
            $self->value( $input, $value );
        }
    }

    $self->insert();                                                    ## trigger logic handled specifically in new_container_trigger  -no_triggers=>1);# insert plate record

    my ($returnval) = @{ $self->newids('Plate') };

    # insert original plate id (pointing to itself)
    $dbc->Table_update_array( "Plate", [ 'FKOriginal_Plate__ID', 'Plate_Created' ], [ $returnval, $created ], "WHERE Plate_ID=$returnval", -autoquote => 1 );

    # line below moved somewhere else ... (Eric)
    #    my $Sample = alDente::Sample::create_samples( -dbc => $dbc, -plate_id => $returnval, -source_id => $source_id, -type => $add_samples );

    return $returnval;
}

##################################################################################
# Record Source record for a given plate (used during extraction of new samples)
#
# Options: -format (defaults to virtual)
#
# <snip>
# eg.
# my $new_source_id = alDente::Container::define_Plate_as_Source($dbc,$plate_id);
#</snip>
#
# Return: Source_ID
##################################
sub define_Plate_as_Source {
##################################
    my %args          = filter_input( \@_, -args => 'dbc,plate_id' );
    my $dbc           = $args{-dbc};
    my $plate_id      = $args{-plate_id};
    my $format        = $args{'-format'};
    my $sample_type   = $args{-sample_type};
    my $parent_source = $args{-parent_source};
    my $debug         = $args{-debug};

    ## retrieve sample_type, parent plate, parent source information from plate
    my @plate_info
        = $dbc->Table_find( 'Plate,Library', 'Plate_ID,Plate.FK_Sample_Type__ID,FKParent_Plate__ID,FK_Plate_Format__ID,FK_Original_Source__ID', "WHERE Plate.FK_Library__Name=Library_Name AND Plate_ID IN ($plate_id)", -distinct => 1, -debug => $debug );

    my $rack = 1;
    my $user = $dbc->get_local('user_id');
    my $now  = &date_time();
    my ($label) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_ID', "WHERE Barcode_Label_Name = 'src_no_barcode'" );

    my $new_source_id;
    if ( int(@plate_info) == 1 ) {
        ## unambiguous source ##
        my ( $plate, $sample, $parent, $plate_format, $os ) = split ',', $plate_info[0];
        $sample_type ||= $sample;
        $format      ||= $plate_format;

        $new_source_id = $dbc->Table_append_array(
            'Source',
            [ 'FKParent_Source__ID', 'FK_Sample_Type__ID', 'FK_Original_Source__ID', 'Received_Date', 'FKReceived_Employee__ID', 'FK_Rack__ID', 'FKSource_Plate__ID', 'FK_Plate_Format__ID', 'FK_Barcode_Label__ID' ],
            [ $parent_source,        $sample_type,         $os,                      $now,            $user,                     $rack,         $plate,               $format,               $label ],
            -autoquote => 1,
            -debug     => $debug
        );
    }
    else {
        Message("Source information ambiguous for this plate ($plate_id)");
    }

    ## define format if applicable (along with barcode option if applicable)

    ## set amounts only if tracked (if format supplied) - otherwise set to null (virtual)

    ## add Source record
    return $new_source_id;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

############################
sub _get_parent_sample {
############################
    # Display link and description of child issues given a parent issue ID, recursive
    #
    # <snip>
    #
    # </snip>
    # Return: 1 on success

    my %args = &filter_input( \@_ );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $sample_id = $args{-sample_id};    #  Parent Issue ID

    # Find the list of child issues

    if ($sample_id) {
        my ($parent_sample) = $dbc->Table_find( 'Sample', 'FKParent_Sample__ID', "WHERE Sample_ID = $sample_id" );

        if ($parent_sample) {

            #  get the issue description for each child issue
            my @parent_info = $dbc->Table_find( 'Sample,Sample_Type', 'Sample_Name,Sample_Type', "WHERE FK_Sample_Type__ID=Sample_Type_ID and Sample_ID=$parent_sample" );

            my ( $sample_name, $sample_type ) = split ',', $parent_info[0];

            my $sample_info = "<BR>" . hspace(20) . "Parent Sample Name: $sample_name, Extraction Type: $sample_type ";

            print $sample_info;

            # recursive call to find the children for each child issue
            _get_parent_sample( -dbc => $dbc, -sample_id => $parent_sample );

        }
        else {
            return 0;
        }
    }

    return 1;
}

#### Moved from Special Branches
##################
sub SB_trigger {
##################
    my $self = shift;

    my $dbc       = $self->{dbc};
    my $type      = $self->value('Plate.Plate_Type');
    my $plate_id  = $self->value('Plate.Plate_ID');
    my $returnval = $plate_id;
    my $home_barcode;
    my $sample_type_id = $self->value('Plate.FK_Sample_Type__ID');
    my $sample_type    = $self->value('Sample_Type.Sample_Type');

    my $add_source_id = param('Add Plate Source_ID');
    my $pipeline_id   = $self->value('Plate.FK_Pipeline__ID');
    my $library       = $self->value('Plate.FK_Library__Name');

    my $lib_type = &alDente::Library::check_Library_Type( -dbc => $dbc, -library => $library );

    my $added_source = "";

    if ( $dbc->transaction->newids->{'Source'}[0] ) {
        $added_source = $dbc->transaction->newids->{'Source'}[0];
    }
    $add_source_id ||= $added_source;

    ($sample_type)    = $dbc->Table_find( 'Sample_Type', 'Sample_Type',    "WHERE Sample_Type_ID = $sample_type_id" ) if !$sample_type;
    ($sample_type_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = '$sample_type'" )     if !$sample_type_id;

    #    require alDente::Plate_Schedule;
    #    my $plate_schedule = alDente::Plate_Schedule->new(-dbc=>$self->{dbc});
    #    $plate_schedule->add_plate_schedule(-plate_id => $plate_id,-pipeline_id=>$pipeline_id);

    my %src_info;
    if ($add_source_id) {
        %src_info = $dbc->Table_retrieve( 'Source', [ 'Current_Amount', 'Amount_Units' ], "WHERE Source_ID = $add_source_id" );
    }

    if ( $type eq 'Library_Plate' ) {
        $lib_type ||= 'seq_lib';
        if ( $lib_type eq 'seq_lib' ) {
            $home_barcode = _update_seq_plate( -dbc => $dbc, -new_ids => $returnval, -add_source_id => $add_source_id );
        }
        elsif ( $lib_type eq 'rna_lib' ) {
            ### Where's param('New') coming from?? can't find it, maybe old? (reza)
            $home_barcode = _update_rna_plate( -dbc => $dbc, -new_ids => $returnval, -add_source_id => $add_source_id );
        }

        if ($add_source_id) {

            # volume tracking for tubes
            my $source_vol   = $src_info{Current_Amount}[0];
            my $source_units = $src_info{Amount_Units}[0];
            my %plate_info   = $dbc->Table_retrieve( "Plate,Plate_Format", [ 'Current_Volume', 'Current_Volume_Units', 'Wells' ], "WHERE Plate_ID IN ($plate_id) AND FK_Plate_Format__ID = Plate_Format_ID" );
            my $plate_vol    = $plate_info{Current_Volume}[0];
            my $plate_units  = $plate_info{Current_Volume_Units}[0];
            my $plate_size   = $plate_info{Wells}[0];

            if ( $source_vol && ( $source_units eq 'ml' || $source_units eq 'ul' ) && $plate_vol && $plate_units && $plate_size ) {
                my $total_plate_vol = $plate_size * $plate_vol;
                &alDente::Source::_subtract_source_volume( -dbc => $dbc, -source_id => $add_source_id, -amnt => $total_plate_vol, -amnt_units => $plate_units );
            }
        }
    }
    elsif ( $type eq 'Tube' ) {    # Create a RNA sample for type other than rearrays
        my $library = param('FK_Library__Name');

        ## <CONSTRUCTION> - hack fix - remove all logic in special branches if possible ... way to funky...
        $home_barcode = _update_tube( -dbc => $dbc, -Plate => $self, -new_ids => $plate_id, -add_source_id => $add_source_id, -type => $sample_type );

        if ($add_source_id) {

            # volume tracking for tubes
            my $source_vol   = $src_info{Current_Amount}[0];
            my $source_units = $src_info{Amount_Units}[0];
            my %plate_info   = $dbc->Table_retrieve( "Plate,Plate_Format", [ 'Current_Volume', 'Current_Volume_Units', 'Wells' ], "WHERE Plate_ID IN ($plate_id) AND FK_Plate_Format__ID = Plate_Format_ID" );

            my $plate_vol   = $plate_info{Current_Volume}[0];
            my $plate_units = $plate_info{Current_Volume_Units}[0];
            my $plate_size  = $plate_info{Wells}[0];

            if ( $source_vol && ( $source_units eq 'ml' || $source_units eq 'ul' ) && $plate_vol && $plate_units && $plate_size ) {
                my $total_plate_vol = $plate_size * $plate_vol;
                &alDente::Source::_subtract_source_volume( -dbc => $dbc, -source_id => $add_source_id, -amnt => $total_plate_vol, -amnt_units => $plate_units );
            }
        }
    }
    &alDente::Barcoding::PrintBarcode( $self->dbc(), 'Plate', $plate_id );

    return;
}

############################################
sub manually_generate_Plate_records {
#############################################
    my %args                       = filter_input( \@_ );
    my $dbc                        = $args{-dbc};
    my $Formats                    = $args{'-formats'};
    my $attributes                 = $args{-attributes};
    my $source_id                  = $args{-source_id};
    my $source_attributes          = $args{-source_attributes};
    my $original_source_attributes = $args{-original_source_attributes};
    my $debug                      = $args{-debug};

    $dbc->start_trans('barcode_plates');

    my @added_formats;
    if ($Formats) {
        @added_formats = keys %{$Formats};
    }
    else {
        @added_formats = $attributes->{FK_Plate_Format__ID};
    }

    ## add Source Record ##
    if ( !$source_id ) {
        $dbc->Benchmark("first-add-Src");
        ( $source_id, my $original_source_id ) = alDente::Source::add_Source( $dbc, -input => $source_attributes, -original_source_attributes => $original_source_attributes );
        $dbc->Benchmark("added-Src-$source_id");
        if ( $attributes->{FK_Library__Name} ) {
            ## if the library is defined for this plate, then link this library automatically to the new source generated.
            my $lib = $attributes->{FK_Library__Name};
            $dbc->Table_append_array( 'Library_Source', [ 'FK_Library__Name', 'FK_Source__ID' ], [ $lib, $source_id ], -autoquote => 1 );

            # Message("Linked new Library_Source");

            my ($lib_OS_id) = $dbc->Table_find( 'Library', 'FK_Original_Source__ID', "WHERE Library_Name = '$lib'" );
            if ( $original_source_id && ( $original_source_id != $lib_OS_id ) ) {
                ## OS for source needs to be added to the hybrid original source defined for the library ##
                $dbc->Table_append_array( 'Hybrid_Original_Source', [ 'FKParent_Original_Source__ID', 'FKChild_Original_Source__ID' ], [ $lib_OS_id, $original_source_id ] );

                # Message("Added Hybrid OS");
            }
        }
        &alDente::Source::throw_away_source( $dbc, $source_id, -confirmed => 1, -quiet => 1 );    ## source is only created for tracking purposes; actual container will be tracked as a container defined below....
        $dbc->Benchmark("tossed-Src-$source_id");
    }

    ## link to Library Record ##
    my ($sample_type_id) = $dbc->Table_find( 'Source,Sample_Type', 'Sample_Type_ID', "WHERE Source_ID = $source_id AND FK_Sample_Type__ID = Sample_Type_ID" );    ## assume that Source_Type options are a subset of Sample_Type options
    $attributes->{'FK_Sample_Type__ID'} = $sample_type_id;                                                                                                        ## $dbc->get_FK_info('FK_Sample_Type__ID',$sample_type_id);

    if ( !$sample_type_id ) {
        $dbc->session->error("No Sample Type for Src$source_id");
        return 0;
    }

    ## Create Plates ##
    my @new_ids;
    foreach my $format (@added_formats) {
        my $format_id = $format;
        if ( $format_id !~ /^\d+$/ ) {
            ## if format key is NOT a simple integer, assume it is the Format name... ##
            ($format_id) = $dbc->Table_find( 'Plate_Format', 'Plate_Format_ID', "WHERE Plate_Format_Type = '$format'" );
        }

        my ($wells) = $dbc->Table_find( 'Plate_Format', 'Wells', "WHERE Plate_Format_ID = $format_id", -debug => $debug );
        if ( $wells > 1 ) {
            $attributes->{'Plate_Type'} = 'Library_Plate';
        }
        else {
            $attributes->{'Plate_Type'} = 'Tube';
        }

        #	Message("Adding $Formats->{$format} x " . $dbc->get_FK_info('FK_Plate_Format__ID',$format_id)  . ' record(s)');
        my ($format_size) = $dbc->Table_find( 'Plate_Format', 'Wells', "WHERE Plate_Format_ID = $format_id", -debug => $debug );

        if   ( $format_size > 1 ) { $attributes->{Plate_Type} = 'Library_Plate' }
        else                      { $attributes->{Plate_Type} = 'Tube' }

        $attributes->{FK_Plate_Format__ID} = $format_id;

        #	my $Plate = new alDente::Container(-dbc=>$dbc);
        #	my $new_id = $Plate->manual_add_Container(-attributes=>$attributes,-repeat=>$Formats->{$format});

        my $repeat = 1;
        if ($Formats) { $repeat = $Formats->{$format} }

        $dbc->Benchmark('"ADD_PLA_FOR_$source_id"');
        my $new_id = $dbc->add_Record( -table => 'Plate', -input => $attributes, -repeat => $repeat, -debug => $debug );
        $dbc->Benchmark("ADDED_PLA_FOR_$source_id");

        push @new_ids, $new_id;
    }
    $dbc->finish_trans('barcode_plates');

    $dbc->{session}{homepage} = '';    ## clear homepage to prevent going to plates home page
    ## generate barcodes

    my $ids = join ',', @new_ids;
    return $ids;
}

############################
sub _update_rna_plate {
############################
    my %args          = @_;
    my $new_plate_ids = $args{-new_ids};
    my $dbc           = $args{-dbc} || $args{-connection} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $add_source_id = $args{-add_source_id};

    #my $new_plate_ids = $returnval;

    my ($first_plate_id) = $new_plate_ids =~ /^(\d+)/;
    my $new_plate_count = 0;

    $dbc->start_trans('update_rna_plate');

    foreach my $new_plate_id ( split /,/, $new_plate_ids ) {
        my $name = $dbc->get_FK_info( 'FK_Plate__ID', $new_plate_id );

        my $Plate = alDente::Library_Plate->new( -dbc => $dbc, -plate_id => $new_plate_id );
        my $plate_id = $Plate->value('Plate.Plate_ID');    ## (returnval is Library_Plate_ID )

        # Get plate size of the newly create plate
        my ($plate_size) = $dbc->Table_find( 'Plate,Plate_Format', 'Wells', "WHERE FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID=$new_plate_id" );

        # 	$plate_size =~ s/(\d+)-well/$1/i;
        my $sub_quadrants;
        if   ( $plate_size =~ /384/ ) { $sub_quadrants = "a,b,c,d" }
        else                          { $sub_quadrants = "" }

        # Create the Library_Plate record
        #my $returnval = $dbc->Table_append_array( 'Library_Plate', [ 'FK_Plate__ID', 'Plate_Class', 'Sub_Quadrants' ], [ $new_plate_id, 'Standard', $sub_quadrants ], -autoquote => 1 );
        my $returnval = $dbc->Table_append_array( 'Library_Plate', [ 'FK_Plate__ID', 'Sub_Quadrants' ], [ $new_plate_id, $sub_quadrants ], -autoquote => 1 );

        # insert original plate id (pointing to itself)
        ### set plate size based on plate format ###

        $plate_size .= '-well';
        $Plate->update( -fields => [ 'Plate.Plate_Size', 'Plate.Parent_Quadrant', 'FKOriginal_Plate__ID' ], -values => [ $plate_size, '', $plate_id ] );

        ### set unused wells if sub_quadrants chosen ###
        if ( param('Sub_Quadrants') ) {
            my $sub_quadrants = join ',', param('Sub_Quadrants');
            unless ( $sub_quadrants =~ /a,b,c,d/ ) {
                $Plate->reset_SubQuadrants( -quadrants => $sub_quadrants );
                print "Reset subquadrants for $returnval to $sub_quadrants (rest marked as unused)";
            }
        }

        my ($newplate) = $dbc->Table_find( 'Library_Plate,Plate', 'FKParent_Plate__ID,Plate.Plate_Status,Plate.FK_Sample_Type__ID', "where FK_Plate__ID=Plate_ID AND Library_Plate_ID=$returnval" );
        my ( $parent, $plate_status, $sample_type ) = split ',', $newplate;

        if ( $new_plate_id && ( $parent !~ /[1-9]/ ) ) {
            my ($rearrayed) = $dbc->Table_find( 'ReArray_Request', 'count(*)', "where FKTarget_Plate__ID = $new_plate_id" );
            if ($rearrayed) {

                # Message("Rearrayed Plate Detected : link to Clone")
            }
            elsif ( $plate_status eq 'Reserved' ) {
                ### Do not create plate_samples/samples
            }
            else {
                $dbc->message("Saved extraction info for plate $new_plate_id");
                alDente::Sample::create_samples( -dbc => $dbc, -plate_id => $new_plate_id, -source_id => $add_source_id, -type => $sample_type );
            }
        }
        $new_plate_count++;
    }

    # If more than one plate created then show links for multi-edit of plates
    if ( $new_plate_count > 1 ) {

        # Plate table
        $dbc->message( &Link_To( $dbc->config('homelink'), "Multi-record edit of new Plate records", "&Edit+Table=Plate&Field=Plate_ID&Like=$new_plate_ids", 'blue', ['newwin'] ) );

        # Library_Plate table
        $dbc->message( &Link_To( $dbc->config('homelink'), "Multi-record edit of new Library_Plate records", "&Edit+Table=Library_Plate&Field=FK_Plate__ID&Like=$new_plate_ids", 'blue', ['newwin'] ) );
    }

    $dbc->finish_trans('update_rna_plate');

    return _home_barcode( $new_plate_ids, $prefix );
}

################################
sub _update_seq_plate {
################################
    my %args          = @_;
    my $new_plate_ids = $args{-new_ids};
    my $dbc           = $args{-dbc} || $args{-connection} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $add_source_id = $args{-add_source_id};

    #my $new_plate_ids = $returnval;
    my $new_plate_count = 0;

    $dbc->start_trans('update_seq_plate');

    foreach my $new_plate_id ( split /,/, $new_plate_ids ) {
        my $name = $dbc->get_FK_info( 'FK_Plate__ID', $new_plate_id );

        my $Plate = alDente::Library_Plate->new( -dbc => $dbc, -plate_id => $new_plate_id );
        my $plate_id = $Plate->value('Plate.Plate_ID');    ## (returnval is Library_Plate_ID )

        # Get plate size of the newly create plate
        my ($plate_size) = $dbc->Table_find( 'Plate,Plate_Format', 'Wells', "WHERE FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID=$new_plate_id" );

        #$plate_size =~ s/(\d+)-well/$1/i
        my $sub_quadrants;
        if   ( $plate_size =~ /384/ ) { $sub_quadrants = "a,b,c,d" }
        else                          { $sub_quadrants = "" }

        # Create the Library_Plate record
        #my $returnval = $dbc->Table_append_array( 'Library_Plate', [ 'FK_Plate__ID', 'Plate_Class', 'Sub_Quadrants' ], [ $new_plate_id, 'Standard', $sub_quadrants ], -autoquote => 1 );
        my $returnval = $dbc->Table_append_array( 'Library_Plate', [ 'FK_Plate__ID', 'Sub_Quadrants' ], [ $new_plate_id, $sub_quadrants ], -autoquote => 1 );

        # insert original plate id (pointing to itself)

        ### set plate size based on plate format ###

        $plate_size .= '-well';
        $Plate->update( -fields => [ 'Plate.Plate_Size', 'Plate.Parent_Quadrant', 'FKOriginal_Plate__ID' ], -values => [ $plate_size, '', $plate_id ] );

        ### set unused wells if sub_quadrants chosen ###
        if ( param('Sub_Quadrants') ) {
            my $sub_quadrants = join ',', param('Sub_Quadrants');
            unless ( $sub_quadrants =~ /a,b,c,d/ ) {
                $Plate->reset_SubQuadrants( -quadrants => $sub_quadrants );
                print "Reset subquadrants for $returnval to $sub_quadrants (rest marked as unused)";
            }
        }
        my ($newplate) = $dbc->Table_find( 'Library_Plate,Plate', 'FKParent_Plate__ID,Plate_Status,FK_Sample_Type__ID', "where FK_Plate__ID=Plate_ID AND Library_Plate_ID=$returnval" );
        my ( $parent, $plate_status, $sample_type ) = split ',', $newplate;

        if ( $new_plate_id && ( $parent !~ /[1-9]/ ) ) {
            my ($rearrayed) = $dbc->Table_find( 'ReArray_Request', 'count(*)', "where FKTarget_Plate__ID = $new_plate_id" );
            if ($rearrayed) { $dbc->message("Rearrayed Plate Detected : link to Clone") }
            elsif ( $plate_status eq 'Reserved' ) {
                ### Do not create plate_samples/samples
            }
            else {
                alDente::Sample::create_samples( -dbc => $dbc, -plate_id => $new_plate_id, -source_id => $add_source_id, -type => $sample_type );
            }
        }
        $new_plate_count++;
    }

    # If more than one plate created then show links for multi-edit of plates
    if ( $new_plate_count > 1 ) {

        # Plate table
        $dbc->message( &Link_To( $dbc->config('homelink'), "Multi-record edit of new Plate records", "&Edit+Table=Plate&Field=Plate_ID&Like=$new_plate_ids", 'blue', ['newwin'] ) );

        # Library_Plate table
        $dbc->message( &Link_To( $dbc->config('homelink'), "Multi-record edit of new Library_Plate records", "&Edit+Table=Library_Plate&Field=FK_Plate__ID&Like=$new_plate_ids", 'blue', ['newwin'] ) );
    }

    $dbc->finish_trans('update_seq_plate');

    return _home_barcode( $new_plate_ids, $prefix );
}
########################
sub _update_tube {
########################
    my %args          = @_;
    my $dbc           = $args{-dbc} || $args{-connection} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $add_source_id = $args{-add_source_id};
    my $new_plate_ids = $args{-new_ids};
    my $Plate         = $args{-Plate};

    #    my $contents      = $args{-contents};
    my @new_plate_ids;
    my $first_plate_id;
    my $new_plate_count;
    my $lib_type = $args{-lib_type};

    $dbc->start_trans('update_tube');

    foreach my $new_plate_id ( split /,/, $new_plate_ids ) {
        if ( !$Plate || $new_plate_ids =~ /,/ ) {
            $Plate = alDente::Tube->new( -dbc => $dbc, -plate_id => $new_plate_id, -quick_load => 1 );
        }

        my $plate_id = $Plate->value('Plate.Plate_ID');    ## (returnval is Tube_ID )

        #  Tube SHOULD be created at the same time as the plate.  IF NOT, then the logic below needs to be more specific.
        #  (ie this loop should not need to be executed, but some plate creation processes may require tube record additions (?) - check using DB_Integrity.
        #
        my ($tube_id) = $dbc->Table_find( 'Tube', 'Tube_ID', "WHERE FK_Plate__ID='$plate_id'" );
        if ( !$tube_id && !param('FormNav') && param('rm') ne 'Confirm Upload' ) {
            ## Tube doesn't exist yet... so create it ##
            $dbc->Table_append_array( 'Tube', ['FK_Plate__ID'], [$new_plate_id] );
        }

        if ( $new_plate_count == 0 ) { $first_plate_id = $plate_id }
        push( @new_plate_ids, $plate_id );

        # insert original plate id (pointing to itself)
        $dbc->Table_update_array( "Plate", ["FKOriginal_Plate__ID"], ["$plate_id"], "WHERE Plate_ID=$plate_id", -no_triggers=>1);

        ### set plate size based on plate format ###
        my ($plate_size) = $dbc->Table_find( 'Plate,Plate_Format', 'Wells', "WHERE FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID = $plate_id" );
        $plate_size .= '-well';
        $Plate->update( -fields => ['Plate.Plate_Size'], -values => [$plate_size], -no_triggers=>1);

        my ($newplate) = $dbc->Table_find( 'Tube,Plate,Sample_Type', 'FKParent_Plate__ID,FK_Library__Name,Plate.Plate_Number, Sample_Type', "where FK_Sample_Type__ID=Sample_Type_ID AND FK_Plate__ID=Plate_ID AND Plate_ID=$new_plate_id" );
        my ( $parent, $lib, $number, $plate_content_type ) = split ',', $newplate;

        if ( $new_plate_id && ( $parent !~ /[1-9]/ ) ) {
            ## Original ##
            my ($rearrayed)  = $dbc->Table_find( 'ReArray_Request', 'count(*)',             "where FKTarget_Plate__ID = $new_plate_id" );
            my ($extraction) = $dbc->Table_find( 'Plate',           'Plate_ID,Plate_Class', "WHERE Plate_ID = $new_plate_id AND Plate_Class like 'Extraction'" );
            if ($rearrayed) { Message("Rearrayed Plate Detected : link to RNA") }
            else {
                my $condition;

                my @plate_sample_rows;
                my $sample_id;
                my $rna_sample_id;
                my $clone_sample_id;
                if ($extraction) {
                    Message("Track source of new sample from $plate_id ($add_source_id)");
                    $add_source_id = define_Plate_as_Source( $dbc, $new_plate_id, -parent_source => $add_source_id );
                }

                my $Sample = alDente::Sample::create_samples( -dbc => $dbc, -plate_id => $new_plate_id, -source_id => $add_source_id );    # ,-type=>$contents);

            }
        }
        $new_plate_count++;
    }

    # If more than one plate created then show links for multi-edit of plates
    if ( $new_plate_count > 1 ) {

        # Plate table
        Message( &Link_To( $dbc->config('homelink'), "Multi-record edit of new Plate records", "&Edit+Table=Plate&Field=Plate_ID&Like=" . join( ",", @new_plate_ids ), 'blue', ['newwin'] ) );

        # Library_Plate table
        Message( &Link_To( $dbc->config('homelink'), "Multi-record edit of new Tube records", "&Edit+Table=Tube&Field=FK_Plate__ID&Like=" . join( ",", @new_plate_ids ), 'blue', ['newwin'] ) );
    }

    $dbc->finish_trans('update_tube');

    return _home_barcode( $new_plate_ids, $prefix );
}

#
# simply returns barcode equivalent when new plates are being generated
# Input: list of new ids
#
# Output: text string of equivalent barcode (eg Pla9Pla10) for new containers
####################
sub _home_barcode {
####################
    my $new_plate_ids = shift;
    my $prefix        = shift;    ## prefix for the container objects

    my $max_show = 20;            ## variable - maximum plates to pull up on home page by default after generation

    # Go to the plate's home page after creation

    my ($first_plate_id) = $new_plate_ids =~ /^(\d+)/;

    if ( !$first_plate_id ) {return}    ## no new barcodes generated ..
    my $home_barcode;
    if ( int( split ',', $new_plate_ids ) > $max_show ) {
        $home_barcode = $prefix . $first_plate_id;
    }
    else {
        $home_barcode = $new_plate_ids;
        $home_barcode =~ s /,/$Prefix{Plate}/g;
        $home_barcode = $prefix . $home_barcode;
    }
    return $home_barcode;
}

#############################
# When entering this routine, a single record was added for a plate.
#  This will update that record, and add new similar records for each sample on the plate
#
# <CONSTRUCTION> Custom method...
#############################
sub _update_clone_source {
#############################
    my %args = @_;

    my $dbc = $args{-dbc} || $args{-connection} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $new_id = $args{-new_ids};

    my $prefix = $Prefix{Plate};

    $dbc->start_trans('update_clone_source');

    # Get information regarding this new clone source
    my %info = $dbc->Table_retrieve( 'Clone_Source,Plate', [ 'Source_Description', 'FK_Plate__ID', 'Plate_Size', 'FKSource_Organization__ID', 'Source_Collection', 'Source_Plate' ], "WHERE Plate_ID=FK_Plate__ID AND Clone_Source_ID = $new_id" );
    my ( $sd, $pid, $ps, $oid, $sc, $sp ) = ( $info{Source_Description}[0], $info{FK_Plate__ID}[0], $info{Plate_Size}[0], $info{FKSource_Organization__ID}[0], $info{Source_Collection}[0], $info{Source_Plate}[0] );

    my @wells = &alDente::Well::Get_Wells( -size => $ps );
    my @fields = ( 'Source_Description', 'FK_Plate__ID', 'FKSource_Organization__ID', 'Source_Collection', 'Source_Plate', 'FK_Clone_Sample__ID', 'Clone_Well', 'Source_Row', 'Source_Col' );
    my %values;

    # Obtain Clone_Sample info as well
    %info = $dbc->Table_retrieve( 'Clone_Sample', [ 'Clone_Sample_ID', 'Original_Well' ], "WHERE FKOriginal_Plate__ID=$pid" );
    my %cs_info;
    my $i = 0;
    while ( defined $info{Clone_Sample_ID}[$i] ) {
        $cs_info{ $info{Original_Well}[$i] } = $info{Clone_Sample_ID}[$i];
        $i++;
    }

    my @converted_wells;
    if ( $ps =~ /384/ ) {
        push( @fields, 'Clone_Quadrant' );
        push( @fields, 'Well_384' );

        # Get the 96-size designation of the wells
        @converted_wells = $dbc->Table_find_array( 'Well_Lookup', [ 'Plate_96', 'Quadrant' ] );
    }

    for ( my $i = 0; $i <= $#wells; $i++ ) {
        my @vals = ();
        if ( $ps =~ /384/ ) {
            my $well_384 = $wells[$i];
            my ( $well_96, $quadrant ) = split /,/, $converted_wells[$i];
            @vals = ( $sd, $pid, $oid, $sc, $sp, $cs_info{ format_well($well_384) }, $well_96, substr( $well_384, 0, 1 ), substr( $well_384, 1, 2 ), $quadrant, $well_384 );
        }
        else {
            my $well = $wells[$i];
            @vals = ( $sd, $pid, $oid, $sc, $sp, $cs_info{$well}, $well, substr( $well, 0, 1 ), substr( $well, 1, 2 ) );
        }
        if ( $i == 0 ) {    # Update the first one
            my $ok = $dbc->Table_update_array( 'Clone_Source', \@fields, \@vals, "WHERE Clone_Source_ID = $new_id", -autoquote => 1 );
            if ( !$ok ) {
                Message("Failed to update to Clone Source for $prefix$pid!");
            }
            else {
                Message("Updated Clone Source for $prefix$pid");
            }
        }
        else {              # All other ones - insert
            $values{$i} = \@vals;

            #print ">>Set values hash ($i) to " . join ",", @vals;
            #print br;
        }
    }

    # Insert the new clone sources,no triggers for the rest of these clone source records!
    my $ok = $dbc->smart_append( -tables => 'Clone_Source', -fields => \@fields, -values => \%values, -autoquote => 1, -no_triggers => 1 );
    if ( !$ok ) {
        Message("Failed to insert to Clone Source for $prefix$pid!");
    }
    else {
        Message("Added Clone Source for $prefix$pid");
    }
    $dbc->finish_trans('update_clone_source');
    return 1;
}

#
#
# Map tray & position specs to plate / well specs
#
# Return hash of plate_id(s), well(s)
#######################
sub map_tray_to_plates {
#######################
    my %args     = &filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my @tray_ids = Cast_List( -list => $args{-tray_ids}, -to => 'array' );
    my @tray_pos = Cast_List( -list => $args{-tray_pos}, -to => 'array' );
    my $debug    = $args{-debug};

    my $tray_list = Cast_List( -list => \@tray_ids, -to => 'string' );
    my $well_list = Cast_List( -list => \@tray_pos, -to => 'string', -autoquote => 1 );

    ## get all positions for indicated tray & well combinations ##
    my %Found = $dbc->Table_retrieve( 'Plate_Tray,Plate,Plate_Format', [ 'FK_Tray__ID', 'Plate_ID', 'Plate_Position', 'Plate_Size', 'Wells' ], "WHERE FK_Plate__ID=Plate_ID AND FK_Plate_Format__ID=Plate_Format_ID AND FK_Tray__ID IN ($tray_list)" );

    my %Map;
    my $i = -1;
    while ( defined $Found{Plate_ID}[ ++$i ] ) {
        my $tray     = $Found{FK_Tray__ID}[$i];
        my $position = $Found{Plate_Position}[$i];
        my $size     = $Found{Plate_Size}[$i];
        my $format   = $Found{Wells}[$i];
        my $plate    = $Found{Plate_ID}[$i];

        $Map{$tray}{$position} = "$plate";
    }

    ## generate well map hash once (quicker than converting each time ##
    my %map = alDente::Well::map_wells( -dbc => $dbc, -target_size => 96 );

    ## generate the new ordered plate / well hashes ##
    $i = 0;
    my ( @plates, @wells );
    foreach my $tray (@tray_ids) {
        my $well = $tray_pos[$i];

        if ( $Map{ $tray_ids[$i] }{$well} =~ /^(\d+)/ ) {
            ## Mapped actual wells in Tray to tube ##
            push @plates, $1;
            push @wells,  'A01';
        }
        else {
            ## Mapped quadrants in Tray ##
            my $mapped = $map{$well};
            if ( $mapped =~ /^(\w\d+)([abcd])$/ ) {
                my $position = $1;
                my $quadrant = $2;

                my $plate = $Map{$tray}{$quadrant};
                push @plates, $plate;
                push @wells,  $position;
            }
            else {
                $dbc->warning("Cannot determine mapping for plate $tray_ids[$i]");
                push @plates, '';
                push @wells,  '';
            }
        }
        $i++;
    }

    if ($debug) { $dbc->message("Mapped @tray_ids (@tray_pos) -> @plates (@wells)") }
    return \@plates, \@wells;
}

#
# Return sample ids for the given wells on plates
# Input: array of plate ids / tray ids
#        array of wells
#
# Output: A hash ref with plate id as key 1 and well position as key 2 and sample id as value
########################
sub get_sample_id {
########################
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc};
    my $plate_ids = $args{-plate_ids};
    my $wells     = $args{-wells};
    my $tray_ids  = $args{-tray_ids};
    my $tray_pos  = $args{-wells};
    my $debug     = $args{-debug};

    my %Tray_map;    ## keep track of tray mapping to make reversion faster at the end ...
    my $use_NA;      ## flag to keep track of wells which are defined as 'N/A' - as opposed to 'A01' for tubes ##
    if ($tray_ids) {
        ## if input uses tray ids, first map tray positions to plate / well combinations ##
        ( $plate_ids, $wells ) = map_tray_to_plates( -dbc => $dbc, -tray_ids => $tray_ids, -tray_pos => $tray_pos );
        foreach my $i ( 1 .. int(@$tray_ids) ) {
            $Tray_map{ $plate_ids->[ $i - 1 ] }{ $wells->[ $i - 1 ] } = "$tray_ids->[$i-1]-$tray_pos->[$i-1]";
        }

        if ($debug) { print HTML_Dump "REMAPPED TO ", $plate_ids, $wells, ' FROM ', $tray_ids, $tray_pos; }
    }

    my ( $original_plates, $original_wells ) = get_original_locations( -dbc => $dbc, -plate_ids => $plate_ids, -wells => $wells, -debug => $debug );

    my @list;
    my %Map;
    foreach my $i ( 1 .. int( @{$original_plates} ) ) {
        my $plate = $original_plates->[ $i - 1 ];
        my $well  = $original_wells->[ $i - 1 ];

        if ( $well eq 'N/A' ) { $use_NA++ }

        if ($plate) { push @list, "$plate-$well" }

        #if ( $plate != $plate_ids->[ $i - 1 ] ) {
        $Map{"$plate-$well"} .= "$plate_ids->[ $i - 1 ]-$wells->[ $i - 1 ];";

        #}
    }
    if ($debug) { print HTML_Dump "MAPPED", \%Map; }

    my $original_plate_list = Cast_List( -list => $original_plates, -to => 'string' );

    my $q_list = Cast_List( -list => [@list], -to => 'string', -autoquote => 1 );

    my %Samples;
    if ( !$q_list ) { return \%Samples }

    my %Sample_info = $dbc->Table_retrieve(
        'Plate_Sample,Plate',
        [ 'FK_Sample__ID', 'Plate_ID', 'Well', 'Plate_Size' ],
        "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate_ID AND Plate_ID IN ($original_plate_list) AND ( CONCAT(Plate_ID,'-',Well) IN ($q_list) OR Well = 'N/A')"
    );

    if ($debug) { print HTML_Dump \%Map }
    my $i = -1;
    while ( defined $Sample_info{'FK_Sample__ID'}[ ++$i ] ) {
        my $original_plate = $Sample_info{Plate_ID}[$i];
        my $original_well  = $Sample_info{Well}[$i];
        my $size           = $Sample_info{Plate_Size}[$i];

        my $plate = $original_plate;
        my $well  = $original_well;

        if ( !$use_NA ) {
            if ( ( $size =~ /^1\b/ ) && ( $well eq 'N/A' ) ) { $well = 'A01' }
        }

        ## get originally specified plate / wells from mapping hash ##
        my $input_plates = $Map{"$plate-$well"};
        while ( $input_plates =~ /(\d+)\-(.*?)\;/g ) {
            $plate = $1;
            $well  = $2;
            if ( ( ( $size =~ /^1\b/ ) && $well =~ /^(N\/A|A01)/ ) ) {
                if   ($use_NA) { $well = 'N/A' }
                else           { $well = 'A01' }
            }

            if ($tray_ids) {
                if ( $Tray_map{$plate}{$well} =~ /(\d+)\-(.*)/ ) {
                    my $tray     = $1;
                    my $position = $2;
                    if ($debug) { Message("Map $plate $well back to Tray $tray $position.") }
                    $Samples{$tray}{$position} = $Sample_info{FK_Sample__ID}[$i];
                }
                else {
                    $dbc->message("Could not find mapping for Tray to PLA $plate $well");
                }
            }
            else {
                $Samples{$plate}{$well} = $Sample_info{FK_Sample__ID}[$i];
            }
        }
    }
    if ($debug) { print HTML_Dump \%Samples }

    return \%Samples;
}

##############################
# displays button for create new Tray from selected plate items
#
##############################
sub set_plate_info_btn {
##############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    ##Opens a new tab when you click on it
    ##Have read that "_blank" expression might not work with internet explorer
    my $onClick = "this.form.target='_blank';sub_cgi_app( 'alDente::Container_App' )";

    my $form_output = "";
    $form_output .= "Tray Label:" . textfield( -name => 'Tray Label', -size => 20, -force => 1 );
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Create New Tray', -class => 'Action', -onClick => $onClick, -force => 1 ), "Create new tray from selected plate items" );

    $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );

    return $form_output;
}

#
# Wrapper to merge libraries from a list of plates into a new hybrid library
#
#
#
# Return: new library name
#################
sub merge_libs {
#################
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $plate_id    = Cast_List( -list => $args{-plate_id}, -to => 'string' );
    my $on_conflict = $args{-on_conflict};
    my $test        = $args{-test};                                              ## suppress messages (use this flag if calling only to retrieve conflict values first)

    ## CUSTOM PRESET VARIOUS On_Conflict Settings ##
    #Original Source
    $on_conflict->{FK_Taxonomy__ID}        = '<Taxonomy_Name=mixed libraries';
    $on_conflict->{Original_Source_Type}   = 'Mixed';
    $on_conflict->{FK_Anatomic_Site__ID}   = '<Anatomic_Site_Name=Mixed>';
    $on_conflict->{FK_Cell_Line__ID}       = '<Cell_Line_Name=Mixed>';
    $on_conflict->{Sex}                    = 'Mixed';
    $on_conflict->{FK_Stage__ID}           = '<Stage_Name=Mixed>';
    $on_conflict->{Host}                   = '';
    $on_conflict->{FK_Contact__ID}         = '<clear>';
    $on_conflict->{FKCreated_Employee__ID} = $dbc->get_local('user_id');
    $on_conflict->{Defined_Date}           = &today();
    $on_conflict->{Description}            = 'hybrid OS';
    $on_conflict->{FK_Patient__ID}         = '<clear>';
    $on_conflict->{FK_Strain__ID}          = '<Strain_Name=Mixed>';
    $on_conflict->{Disease_Status}         = 'Mixed';
    $on_conflict->{FK_Pathology__ID}       = '';
    $on_conflict->{Pathology_Type}         = '<clear>';
    $on_conflict->{Pathology_Grade}        = '<distinct concat>';
    $on_conflict->{Pathology_Stage}        = '<clear>';
    $on_conflict->{Invasive}               = '<clear>';
    $on_conflict->{Pathology_Occurrence}   = 'Unspecified';

    # Library
    $on_conflict->{Library_Obtained_Date}     = &today();
    $on_conflict->{External_Library_Name}     = '<clear>';
    $on_conflict->{Library_Description}       = 'pooled hybrid library';
    $on_conflict->{Library_Status}            = 'In Production';
    $on_conflict->{Requested_Completion_Date} = '<clear>';
    $on_conflict->{FKConstructed_Contact__ID} = '<clear>';
    $on_conflict->{Library_Completion_Date}   = '<clear>';
    $on_conflict->{Library_Analysis_Status}   = '<clear>';
    $on_conflict->{Library_Notes}             = '<clear>';

    # RNA_DNA_Collection
    $on_conflict->{Experiment_Type} = '<clear>';
    ######################################

    ## hash input references for feedback ##
    my $unresolved = $args{-unresolved} || {};
    my $preset     = $args{-preset}     || {};
    my $debug      = $args{-debug};

    my $tables = 'Plate,Library,Original_Source,Plate_Sample,Sample';
    my @merge_tables = ( 'Original_Source', 'Library');
    my @fields = (
        'Group_Concat(DISTINCT Plate_ID) as Plate',
        'Group_Concat(DISTINCT FK_Source__ID) as Source',
        'Group_Concat(DISTINCT Library_Name) as Library',
        'Group_Concat(DISTINCT Original_Source_ID) as Original_Source',
    );
    my $join_condition = "Plate.FK_Library__Name=Library_Name AND Library.FK_Original_Source__ID=Original_Source_ID AND Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID";
    
    my @lib_types = $dbc->Table_find('Library,Plate','Library_Type',"WHERE FK_Library__Name=Library_Name AND Plate_ID IN ($plate_id)", -distinct=>1);
    
    if (int(@lib_types) == 1) { 
        ## dynamically include library type specific table if defined ##
        my $lib_type = $lib_types[0];
        $tables .= ",$lib_type";
        push @fields, "Group_Concat(DISTINCT ${lib_type}_ID AS $lib_type";
        $join_condition .=  " AND $lib_type.FK_Library__Name = Library_Name";
        push @merge_tables, $lib_type;
    }
    
    my %Distinct       = $dbc->Table_retrieve( $tables, \@fields, "WHERE $join_condition AND Plate_ID IN ($plate_id)", -debug => $debug );

    my @retrieved = split ',', $Distinct{Plate}[0];
    my @input     = split ',', $plate_id;

    my ( $OSid, $Lib );
    foreach my $table (@merge_tables) {
        my $list = Cast_List( -list => $Distinct{$table}[0], -to => 'string', -autoquote => 1 );

        my $id = $dbc->create_merged_data( -table => $table, -primary_list => $list, -preset => $preset, -unresolved_conflict => $unresolved, -on_conflict => $on_conflict, -debug => $debug, -test => $test );
        if ($id) {
            if ( $table eq 'Original_Source' ) {
                ## add reference to new hybrid OS ##
                $OSid = $id;
                $on_conflict->{FK_Original_Source__ID} = $id;
            }
            elsif ( $table eq 'Library' ) {
                $Lib = $id;
                $on_conflict->{FK_Library__Name} = $id;
            }
        }
        elsif ( !$test ) {
            $dbc->warning("Failed to create merged $table");
        }
    }

    if ( %{$unresolved} && !$test ) {
        $dbc->error("Unresolved conflicts remain");
        my $msg = HTML_Dump 'Unresolved', $unresolved, 'Preset', $preset, 'OC', $on_conflict;
        $dbc->debug_message($msg);
    }
    elsif ( !$test ) {
        $dbc->message("Creating Merged Hybrid Records for Libray $Lib [OS = $OSid]");
    }

    return $Lib;
}

###########################
# retrieve plate IDs given various criteria
#
# Arguments: Below is the mapping between the supported arguments and the fields
#	rack		- rack ID
#	failed		- Failed
#	status		- Plate_Status
#	QC			- QC_Status
#	library		- FK_Library__Name
#	test		- Plate_Test_Status
#	plate_type	- Plate_Type
#	id			- Plate_ID
#
# Usage:
#	my $ids = $Container_Obj->get_plates( -failed => 'Yes', -rack => '12345' );
#
# Return:
#	Array ref of Plate IDs
##########################
sub get_plates {
##########################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc} || $self->{dbc};
    my $debug = $args{-debug};

    my $conditions = "WHERE 1";
    if ( $args{-id} ) {
        my $list = Cast_List( -list => $args{-id}, -to => 'string' );
        $conditions .= " AND Plate_ID in ( $list )";
    }
    if ( $args{-rack} ) {
        my $list = Cast_List( -list => $args{-rack}, -to => 'string' );
        $conditions .= " AND FK_Rack__ID in ( $list )";
    }
    if ( $args{-failed} ) {
        $conditions .= " AND Failed = '$args{-failed}'";
    }

    if ( $args{-status} ) {
        my $list = Cast_List( -list => $args{-status}, -to => 'string', -autoquote => 1 );
        $conditions .= " AND Plate_Status in ( $list )";
    }

    if ( $args{-QC} ) {
        my $list = Cast_List( -list => $args{-QC}, -to => 'string', -autoquote => 1 );
        $conditions .= " AND QC_Status in ( $list )";
    }

    if ( $args{-library} ) {
        my $list = Cast_List( -list => $args{-library}, -to => 'string', -autoquote => 1 );
        $conditions .= " AND FK_Library__Name in ( $list )";
    }

    if ( $args{-test} ) {
        $conditions .= " AND Plate_Test_Status = '$args{-test}'";
    }

    if ( $args{-plate_type} ) {
        my $list = Cast_List( -list => $args{-plate_type}, -to => 'string', -autoquote => 1 );
        $conditions .= " AND Plate_Type in ( $list )";
    }

    my @plates = $dbc->Table_find( 'Plate', 'Plate_ID', $conditions, -distinct => 1, -debug => $debug );
    return \@plates;
}

##############################################
#  Defining and Creating New Plates
##############################################

##################################################
# Layers in main plate page (plate object loaded)
##################################################

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Container.pm,v 1.169 2004/12/03 20:10:19 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
