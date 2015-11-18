#!/usr/bin/perl
###################################################################################################################################
# Source.pm
#
###################################################################################################################################
package alDente::Source;

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
use SDB::CustomSettings;
use SDB::HTML;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;

use SDB::DB_Form_Viewer;
use SDB::DB_Form;
use SDB::Session;

use alDente::SDB_Defaults;

use RGTools::RGIO;
use RGTools::RGmath;
use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::Conversion;
use alDente::Form;
use alDente::Tools;
use alDente::Source_Views;

#use alDente::Original_Source;
##############################
# global_vars                #
##############################
use vars qw($dbc $user);
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
sub new {
###########################
    my $this  = shift;
    my %args  = @_;
    my $class = ref($this) || $this;

    my $source_id = $args{-source_id} || $args{-id};                                                       # required
    my $dbc       = $args{-dbc}       || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $tables    = $args{-tables}    || 'Source';

    my $id = $source_id;
    $dbc->Benchmark("new-Source-$id-start");

    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => $tables );
    bless $self, $class;

    if ($source_id) {
        $self->primary_value( -table => 'Source', -value => $source_id );
        my @lims_tables = $dbc->tables();

        ## check the source type and add the table to the object
        my $source_type = $self->get_main_Sample_Type( -id => $source_id, -dbc => $dbc, -find_table => 1 );
        if ( $dbc->table_loaded($source_type) ) {
            $self->add_tables($source_type);
        }

        if ( $dbc->table_loaded('Xenograft') ) {
            my ($xenograft) = $dbc->Table_find( 'Xenograft', 'Xenograft_ID', "WHERE FK_Source__ID IN ($source_id)" );
            if ($xenograft) {
                $self->add_tables( 'Xenograft', 'Xenograft.FK_Source__ID = Source.Source_ID' );
            }
        }
        $self->add_tables('Original_Source', 'Source.FK_Original_Source__ID=Original_Source_ID');

        if ( $source_id !~ /,/ && $dbc->table_loaded('Patient') ) {

            #            my ($patient) = $dbc->Table_find( 'Original_Source, Source, Patient', 'Patient_ID', "WHERE FK_Original_Source__ID = Original_Source_ID AND Source_ID = $source_id and FK_Patient__ID = Patient_ID" );
            my ($patient) = $dbc->Table_find( 'Source, Original_Source', 'FK_Patient__ID', "WHERE FK_Original_Source__ID=Original_Source_ID AND Source_ID = $source_id" );
            if ($patient) {
                $self->add_tables( 'Patient', 'Original_Source.FK_Patient__ID = Patient.Patient_ID' );
            }
        }
    }

    $self->{dbc} = $dbc;
    $self->{id}  = $source_id;

    $dbc->Benchmark("new-Source-$id-preload");
    if ($source_id) {
        $self->load_Object();
    }
    $dbc->Benchmark("new-Source-$id-loaded");
    return $self;

}

############################
sub get_main_Sample_Type {
############################
    # Description:
    #       Return The absolute parent of a sample_type given the source_id
    # Input:
    #       Source_ID
    #       $dbc
    # Output:
    #       Name of the last parent of the sample type of a source which is basically the source type
############################
    my $self        = shift;
    my %args        = filter_input( \@_, -args => 'dbc,id' );
    my $dbc         = $args{-dbc};
    my $id          = $args{-id};
    my $find_table  = $args{-find_table};
    my $sample_type = $args{-sample_type};

    my @result_tables;
    my $parent_type;
    if ( !$sample_type ) {
        my @sample_types = $dbc->Table_find( "Source, Sample_Type", "Sample_Type", "WHERE Source_ID IN ($id) AND FK_Sample_Type__ID = Sample_Type_ID" );
        ($sample_type) = $sample_types[0];
        if ( int @sample_types > 1 ) {
            ## Only works for one sample type
            return;
        }
    }

    if    ( $find_table  && defined $dbc->{map_sample_table}{$sample_type} ) { return $dbc->{map_sample_table}{$sample_type} }
    elsif ( !$find_table && defined $dbc->{map_sample_table}{$sample_type} ) { return $dbc->{map_sample_type}{$sample_type} }

    my $derived_sample_type = $sample_type;
    while ($derived_sample_type) {
        if ( $find_table && $dbc->table_loaded($derived_sample_type) ) {
            $dbc->{map_sample_table}{$sample_type} = $derived_sample_type;
            return $derived_sample_type;
        }
        $parent_type = $derived_sample_type;
        ($derived_sample_type) = $dbc->Table_find( 'Sample_Type as child, Sample_Type as parent', 'parent.Sample_Type', " WHERE parent.Sample_Type_ID = child.FKParent_Sample_Type__ID and child.Sample_Type = '$derived_sample_type'" );
    }

    if ($find_table) {
        return '';
    }

    $dbc->{map_sample_type}{$sample_type} = $parent_type;

    return $parent_type;
}

##############################
# public_methods             #
##############################

############################
sub add_Source {
############################
    #
    # Only to be used if NOT adding via navigator (and sub-type tables not applicable)
    #
    #
    #
############################
    my %args                       = filter_input( \@_, -args => 'dbc,input' );
    my $dbc                        = $args{-dbc};
    my $Input                      = $args{-input};
    my $original_source_attributes = $args{-original_source_attributes};
    my $debug                      = $args{-debug};

    my $field = 'FK_Original_Source__ID';
    my $original_source_id = SDB::HTML::get_Table_Param( -table => 'Source', -field => $field, -dbc => $dbc ) || $Input->{"Source.$field"} || $Input->{$field};

    if ($original_source_attributes) { $original_source_id ||= $original_source_attributes->{Original_Source_ID} }

    my $new_original_source_id;
    if ( !$original_source_id ) {
        $new_original_source_id = $dbc->add_Record( -table => 'Original_Source', -input => $original_source_attributes, -debug => $debug );

        # Message("Adding new Original_Source record ($new_original_source_id)");
        $Input->{'FK_Original_Source__ID'} = $new_original_source_id;
    }
    my $source_id = $dbc->add_Record( -table => 'Source', -input => $Input );

    my $lib = SDB::HTML::get_Table_Param( 'FK_Library__Name', -dbc => $dbc );
    if ($lib) {
        ### add record linking Record with Library ###
    }
    return ( $source_id, $new_original_source_id );
}

##############################
sub source_name {
##############################
    # Gets the name of the source
    #
    # $self->source_name();
    # $source_name($dhb,$src_id);
    #
    # Returns: $name
    #
####################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'id,dbc' );
    my $source_id = $args{-id} || $self->{id};
    my $dbc       = $args{-dbc} || $self->{dbc};
    my ($name)    = $dbc->Table_find_array(
        'Original_Source,Source LEFT JOIN Sample_Type ON FK_Sample_Type__ID = Sample_Type_ID',
        ["concat(Original_Source_Name,' - ',Sample_Type,' #',Source_Number)"],
        "WHERE FK_Original_Source__ID=Original_Source_ID AND Source_ID in ($source_id)"
    );
    return $name;
}

##############################
sub is_reserved {
##############################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'id' );
    my $source_id = $args{-id} || $self->{id};
    my $dbc       = $args{-dbc} || $self->{dbc};
    my @status    = $dbc->Table_find( 'Source', 'Source_Status', "WHERE Source_ID IN ($source_id)", -distinct => 1 );

    if ( grep {/reserved/i} @status ) {
        return 1;
    }
    return;
}

##############################
sub source_type {
##############################
    # Gets the type of the source
    #
    # $self->source_type();
    # $source_type($dhb,$src_id);
    #
    # Returns: $type
    #
##################
    my $source_id = 0;
    my $dbc;

    if ( UNIVERSAL::isa( $_[0], 'alDente::Source' ) ) {
        my $self = shift;
        $dbc = $self->{dbc};
        $source_id = shift || $self->{id};
        return $self->get_main_Sample_Type( -id => $source_id, -dbc => $dbc );

    }
    else {
        $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
        $source_id = shift;
        return get_main_Sample_Type( undef, -id => $source_id, -dbc => $dbc );

    }

}

#######################
sub throw_away_source {
#######################
    my %args = &filter_input( \@_, -args => 'dbc,ids,confirmed', -mandatory => 'ids' );
    my $dbc                = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $ids                = $args{-ids};
    my $confirmed          = $args{-confirmed};
    my $quiet              = $args{-quiet};                                                                   ## suppress feedback messages
    my $thrown_away_status = $args{-status} || 'Thrown Out';                                                  ## used to override the thrown out status limited to Source_Status ENUM

    if ($confirmed) {
        ### Garbage Location
        ( my $garbage ) = $dbc->Table_find( 'Rack', 'Rack_ID', "where Rack_name = 'Garbage'" );
        ### Move to garbage, set status to Thrown Out
        my $ok = $dbc->Table_update_array( 'Source', [ 'FK_Rack__ID', 'Source_Status' ], [ $garbage, $thrown_away_status ], "where Source_ID in ($ids)", -autoquote => 1 );

        if ( !$quiet ) { Message("$ok Source(s) Thrown away") }
        if ($ok) {
            ## <CONSTRUCTION> Record event?
        }
        return $ok;
    }
    else {
        return alDente::Source_Views::throw_away_prompt( $dbc, $ids );
    }
    return;
}

##############################
sub new_source_trigger {
##########################
    #
    # Trigger that gets executed whenever a new source is inserted
    #
##############################
    my $self  = shift;
    my %args = filter_input(\@_);
    my $dbc   = $args{-dbc} || $self->{dbc};
    my $id    = $self->value('Source.Source_ID');
    my $print = $dbc->session->{printer_status};
    my $debug = 0;
    my $force = shift;

    $dbc->Benchmark("triggerpt-$id-0");

    # check if there is a parent. If there is, then use that parents' source number, otherwise increment
    my ($source_info) = $dbc->Table_find(
        "Source",
        "FKParent_Source__ID,FK_Original_Source__ID,Source_Number,FKOriginal_Source__ID,Original_Amount, Storage_Medium_Quantity, Amount_Units, Storage_Medium_Quantity_Units, FK_Sample_Type__ID",
        "WHERE Source_ID=$id",
        -debug => $debug
    );
    my ( $parent_id, $orig_source_id, $source_number, $original, $volume, $medium, $volume_units, $medium_units, $sample_type ) = split ',', $source_info;
    my $maxnum;
    my @update_fields = ();
    my @update_values = ();

    my $user_specified = !$parent_id && ( $source_number =~ /^\d+$/ );    ## user specified for a new original (allowed to specify starting Source Number) - eg start at Src #500
    if ( $force || !$user_specified ) {
        if ($parent_id) {
            my ($source_number) = $dbc->Table_find( "Source", "Source_Number", "WHERE Source_ID=$parent_id" );
            $source_number ||= '0';
            my ($suffix) = $dbc->Table_find( "Source", "Count(Source_ID)", "WHERE FKParent_Source__ID=$parent_id" );
            $maxnum = "$source_number.$suffix";
        }
        else {
            my @src_nums = $dbc->Table_find( "Source", "Source_Number", "WHERE FK_Original_Source__ID=$orig_source_id AND Source_ID <> $id" );    ## newer logic, making numbering independent of Sample_Type ##

            @src_nums = sort { $b <=> $a } @src_nums;
            $maxnum = shift(@src_nums);
            $maxnum =~ /^(\d+)\.?/;
            $maxnum = $1 || '0';
            $maxnum++;
        }
        push @update_fields, 'Source_Number';
        push @update_values, $dbc->dbh()->quote($maxnum);
    }

    ## indicate that a sample is available <CONSTRUCTION> - unless flagged as a background source.
    push @update_fields, 'Sample_Available';
    push @update_values, "\'Yes\'";

    #$dbc->Table_update_array( 'Original_Source', ['Sample_Available'], ['Yes'], "WHERE Original_Source_ID = $orig_source_id", -autoquote => 1 );

    ## update Current_Amount and record creation datetime
    #$dbc->dbh()->do("UPDATE Source SET Current_Amount=Original_Amount, Source_Created = NOW() WHERE Source_ID=$id");
    push @update_fields, ('Source_Created');
    push @update_values, ("NOW()");

    if ($print) {
        require alDente::Barcoding;
        &alDente::Barcoding::PrintBarcode( $dbc, 'Source', $id );
    }

    ## update if replacement Source supplied ##
    $self->is_Replacement($id);

    my $volume_updates = $self->update_source_volume( -volume => $volume, -medium => $medium, -volume_units => $volume_units, -medium_units => $medium_units, -id => $id );
    if ( $volume_updates->{$id}{'Current_Amount'} ) {
        push @update_fields, ( 'Current_Amount', 'Original_Amount' );
        push @update_values, ( $volume_updates->{$id}{'Current_Amount'}, $volume_updates->{$id}{'Original_Amount'} );
    }
    else {
        push @update_fields, ('Current_Amount');
        push @update_values, ('Original_Amount');
    }

    if ($parent_id) {
        $self->_update_parent_source_volumes();

        $self->inherit_Attribute( -child_ids => $id, -parent_ids => [$parent_id], -debug => $debug );

        ## Concentration should be inherited if there is no storage medium and sample type is not changed
        unless ( $medium > 0 ) {
            my %parent_info = $dbc->Table_retrieve( 'Source', [ 'FK_Sample_Type__ID', 'Current_Concentration', 'Current_Concentration_Units', 'Current_Concentration_Measured_by' ], "WHERE Source_ID=$parent_id" );
            if ( $sample_type == $parent_info{FK_Sample_Type__ID}[0] ) {
                push @update_fields, ( 'Current_Concentration', 'Current_Concentration_Units', 'Current_Concentration_Measured_by' );
                push @update_values, ( $dbc->dbh()->quote( $parent_info{Current_Concentration}[0] ), $dbc->dbh()->quote( $parent_info{Current_Concentration_Units}[0] ), $dbc->dbh()->quote( $parent_info{Current_Concentration_Measured_by}[0] ) );
            }
        }

        if ( $dbc->table_loaded('Xenograft') ) {
            $self->inherit_Xenograft( -child_ids => $id, -parent_ids => $parent_id, -debug => $debug );
        }
    }

    ## update FKOriginal_Source__ID if not defined ##
    if ( !defined $original || !$original ) {
        push @update_fields, 'FKOriginal_Source__ID';
        push @update_values, "Source_ID";

        #$dbc->dbh()->do("UPDATE Source SET FKOriginal_Source__ID=Source_ID WHERE Source_ID = $id");
    }
    my $set_string   = $dbc->make_table_update_set_statement( -fields => \@update_fields, -values => \@update_values );
    my $query_string = "UPDATE Original_Source,Source SET $set_string  WHERE Original_Source_ID = Source.FK_Original_Source__ID and Source_ID = $id";
    my $update       = $dbc->query("$query_string");

    $dbc->Benchmark("triggerpt-$id-5");
    return 1;
}

###############################
sub update_source_volume {
###############################
##
    #
###############################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $id   = $args{-id};

    my $volume       = $args{-volume};
    my $medium       = $args{-medium};
    my $units        = $args{-volume_units};
    my $medium_units = $args{-medium_units};

    my %update_info;

    ## only add if both units are volume units ##
    if ( $units =~ /l$/ && $medium_units =~ /l$/ && $medium > 0 ) {
        ## convert all volume to microliters to add
        my ($original_ml) = convert_to_mils( $volume, $units );
        my ($medium_ml)   = convert_to_mils( $medium, $medium_units );
        my $total         = $original_ml + $medium_ml;
        ## convert back to other unit if appropriate
        my ( $final, $final_units ) = convert_units( $total, 'ml', $units );

        #	Message("Resetting current volume to $volume $units + $medium $medium_units = $final $final_units to account for Storage Medium)"); # # . $dbc->{connected});
        #$dbc->Table_update_array( 'Source', [ 'Current_Amount', 'Original_Amount' ], [ $final, $final ], "WHERE Source_ID = '$id'" );

        $update_info{$id}{'Current_Amount'}  = $final;
        $update_info{$id}{'Original_Amount'} = $final;
    }

    return \%update_info;
}

#######################
sub inherit_Xenograft {
#######################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $child_ids  = $args{-child_ids};
    my $parent_ids = $args{-parent_ids};
    my ($xenograft) = $dbc->Table_find( "Xenograft", "Xenograft_ID", "WHERE FK_Source__ID = $parent_ids" );
    if ($xenograft) {
        my @fields = ( 'Xenograft_ID', 'FK_Source__ID' );
        my @values = ( '',             $child_ids );
        ( my $new_xeno_id, my $copy_time ) = $dbc->Table_copy( -table => 'Xenograft', -condition => "where Xenograft_ID =$xenograft", -exclude => \@fields, -replace => \@values );
        Message "Copied Xenograft info from parent $parent_ids to child $child_ids";
        return $new_xeno_id;
    }

}

#######################
sub array_into_box_btn {
#######################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $form_output;

    my $table = HTML_Table->new();
    $table->Set_Class('small');
    $table->Set_Width('400');
    $table->Toggle_Colour('off');
    $table->Set_Line_Colour('#eeeee8');

    $table->Set_Row( [ "Dilute as required to: ", textfield( -name => 'Target_Concentration_for_Array', -force => 1 ) ] );
    $table->Set_Row( [ "Using: ", textfield( -name => 'Diluting_Solution_ID', -force => 1 ) ] );

    my $onClick = "sub_cgi_app( 'alDente::Source_App')";
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Array into Box', -onClick => $onClick, -class => 'Action', -force => 1 ), "Array into box" ) . lbr();
    $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );
    $form_output .= $table->Printout(0);

    return $form_output;
}

#######################
sub move_to_box_btn {
##############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    #my $onClick = "SetSelection(this.form,'Plate_Action','Aliquot');SetSelection(this.form,'Plate_Event','Go');SetSelection(this.form,'Plate_Type','Tube');";,-onClick=>$onClick
    my $form_output = submit( -name => 'Move to Box', -value => 'Move to Box', -class => 'Action' ) . textfield( -name => 'rack', -size => 8 );

    return $form_output;
}

##########################
sub catch_move_to_box_btn {
##########################
    my %args   = filter_input( \@_, -args => "dbc" );
    my $dbc    = $args{-dbc};
    my $rack   = param('rack');
    my @marked = param('Mark');

    if ( param('Move to Box') ) {
        if ( !$rack ) {
            Message 'No target supplied!';
            return;
        }
        if ( !$marked[0] ) {
            Message 'No Sources Supplied!';
            return;
        }
        my $target_rack;
        my $rack_id = get_aldente_id( $dbc, $rack, 'Rack' );
        my ($rack_type) = $dbc->Table_find( 'Rack', 'Rack_Type', "WHERE Rack_ID = $rack_id" );
        if ( $rack_type eq 'Box' ) {
            $target_rack = $rack_id;
        }
        elsif ( $rack_type eq 'Slot' ) {
            Message("Target rack can not be a slot");
            return;
        }
        else {
            require alDente::Rack;
            ($target_rack) = alDente::Rack::add_rack( -dbc => $dbc, -parent => $rack_id, -type => 'Box', -create_slots => 1, -max_slot_row => 'h', -max_slot_col => 12 );
        }
        print move_Rack_page( -ids => join( ',', @marked ), -rack => $target_rack, -type => 'Source', -dbc => $dbc );

        return;
    }
    return;
}

#######################
sub move_Rack_page {
#######################
    my %args      = filter_input( \@_, 'ids' );
    my $dbc       = $args{-dbc};
    my $rack      = $args{-rack};
    my $type      = $args{-type};
    my $ids       = $args{-ids};
    my $locations = $args{-locations};
    my $q         = new CGI;

    my $page = alDente::Form::start_alDente_form( $dbc, 'confirm_redistribution' );
    $page .= 'Relocating Items:<P>';

    $page .= alDente::Rack::move_Items( -ids => $ids, -rack => $rack, -type => $type, -dbc => $dbc, -locations => $locations );
    $page .= hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );
    $page .= submit(
        -name  => 'rm',
        -value => 'Confirm Re-Distribution',
        -class => 'Action',
        -force => 1
    );
    $page .= end_form();
    return $page;
}

######################################
sub new_library_source_trigger {
######################################
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my ($obtained) = $dbc->Table_find( 'Library_Source,Source', 'min(Received_Date),FK_Library__Name', "WHERE Library_Source_ID = $id  and FK_Source__ID=Source_ID AND Received_Date > '0000-00-00' GROUP BY Received_Date" );
    my ( $obtained_date, $library ) = split ',', $obtained;
    if ( $obtained_date =~ /[1-9]/ ) {
        $dbc->Table_update_array( 'Library', ['Library_Obtained_Date'], [$obtained_date], "WHERE Library_Name = '$library'", -autoquote => 1 );
    }
    return 1;
}

###########################
sub _update_parent_source_volumes {
###########################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $id   = $self->value('Source.Source_ID');

    my %src_info = $dbc->Table_retrieve(
        'Source AS C, Source AS P',
        [ 'P.Source_ID AS Parent_ID', 'P.Current_Amount AS Parent_Amount', 'P.Amount_Units AS Parent_Units', 'C.Original_Amount AS Child_Amount', 'C.Amount_Units AS Child_Units' ],
        "WHERE P.Source_ID=C.FKParent_Source__ID AND C.Source_ID=$id",
    );

    my $parent_id = $src_info{Parent_ID}[0];

    if ($parent_id) {
        &_subtract_source_volume( -dbc => $dbc, -source_id => $parent_id, -amnt => $src_info{Child_Amount}[0], -amnt_units => $src_info{Child_Units}[0] );
    }
}

##############################
sub _subtract_source_volume {
##############################
    my %args = &filter_input( \@_, -args => 'dbc,source_id,amnt,amnt_units' );

    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $source_id  = $args{-source_id};
    my $amnt       = $args{-amnt};
    my $amnt_units = $args{-amnt_units};

    my %src_info = $dbc->Table_retrieve( 'Source', [ 'Current_Amount', 'Amount_Units' ], "WHERE Source_ID=$source_id" );

    my ( $new_amnt, $new_units ) = &alDente::Tools::calculate(
        -action   => 'subtract',
        -p1_amnt  => $src_info{Current_Amount}[0],
        -p1_units => $src_info{Amount_Units}[0],
        -p2_amnt  => $amnt,
        -p2_units => $amnt_units,
    );

    ( $new_amnt, $new_units ) = &RGTools::Conversion::convert_units( $new_amnt, $new_units, $src_info{Amount_Units}[0], 'quiet' );
    unless ($new_amnt) {
        $new_amnt = 0;
    }
    $dbc->Table_update_array( 'Source', ['Current_Amount'], [$new_amnt], "WHERE Source_ID=$source_id" );

    if ( $new_amnt == 0 ) {
        $dbc->message("No More content left in src$source_id, marking it as Inactive ($dbc->{defer_messages})");
        $dbc->Table_update_array( 'Source', ['Source_Status'], ['Inactive'], "WHERE Source_ID=$source_id", -autoquote => 1 );
    }

}

##############################
sub _update_source_number {
##############################
    # update the Source Number of a Source
    #
    # $self->_update_source_number();
    #
    # Returns: none
    #
###########################
    my $self  = shift;
    my $force = shift;

    my $dbc = $self->{dbc};
    my $source_id = $self->primary_value( -table => 'Source' );

    # check if there is a parent. If there is, then use that parents' source number, otherwise increment
    my ($source_info) = $dbc->Table_find( "Source", "FKParent_Source__ID,FK_Original_Source__ID,Source_Number", "WHERE Source_ID=$source_id" );
    my ( $parent_id, $orig_source_id, $source_number ) = split ',', $source_info;
    my $maxnum;

    my $user_specified = !$parent_id && ( $source_number =~ /^\d+$/ );    ## user specified for a new original (allowed to specify starting Source Number) - eg start at Src #500
    if ( $force || !$user_specified ) {
        if ($parent_id) {
            my ($source_number) = $dbc->Table_find( "Source", "Source_Number", "WHERE Source_ID=$parent_id" );
            $source_number ||= '0';
            my ($suffix) = $dbc->Table_find( "Source", "Count(Source_ID)", "WHERE FKParent_Source__ID=$parent_id" );
            $maxnum = "$source_number.$suffix";
        }
        else {
##            my ( $orig_source_id, $type ) = map { split ',', $_ } $dbc->Table_find( "Source LEFT JOIN Sample_Type ON FK_Sample_Type__ID = Sample_Type_ID", "FK_Original_Source__ID,Sample_Type", "WHERE Source_ID=$source_id  " );
##             my @src_nums = $dbc->Table_find( "Source,Sample_Type", "Source_Number", "WHERE FK_Original_Source__ID=$orig_source_id AND Sample_Type ='$type' AND Source_ID <> $source_id AND FK_Sample_Type__ID = Sample_Type_ID" );
            my @src_nums = $dbc->Table_find( "Source", "Source_Number", "WHERE FK_Original_Source__ID=$orig_source_id AND Source_ID <> $source_id" );    ## newer logic, making numbering independent of Sample_Type ##

            @src_nums = sort { $b <=> $a } @src_nums;
            $maxnum = shift(@src_nums);
            $maxnum =~ /^(\d+)\.?/;
            $maxnum = $1 || '0';
            $maxnum++;
        }

        $dbc->Table_update_array( "Source", ['Source_Number'], [$maxnum], "WHERE Source_ID=$source_id", -autoquote => 1 );

        #Message("src$source_id Source_Number is $maxnum");
    }
    ## indicate that a sample is available <CONSTRUCTION> - unless flagged as a background source.
    $dbc->Table_update_array( 'Original_Source', ['Sample_Available'], ['Yes'], "WHERE Original_Source_ID = $orig_source_id", -autoquote => 1 );

    return $maxnum;
}

################################
sub propogate_field {
################################
    #
    #
################################
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $field    = $args{-field};
    my $value    = $args{-value};
    my $ids      = $args{-ids};
    my $children = $args{-children};
    my $confirm  = $args{-confirm};

    my @no_pools_tmp  = $self->source_ancestry( -id => $ids, -direction => 'offspring', -no_pools => 1 );
    my @no_pools      = _simplfy_array( \@no_pools_tmp );
    my @child_ids_tmp = $self->source_ancestry( -id => $ids, -direction => 'offspring' );
    my @children      = _simplfy_array( \@child_ids_tmp );
    my $diff          = RGTools::RGIO::set_difference( \@children, \@no_pools );
    my @pools;
    @pools = @$diff if $diff;
    my $pooled_count = @pools;
    my @all_ids      = @no_pools;
    my @ids          = split ',', $ids;
    push @all_ids, @ids;

    my $pools_list = Cast_List( -list => \@pools,   -to => 'string' );
    my $all_ids    = Cast_List( -list => \@all_ids, -to => 'string' );

    my @plates = $self->get_source_plates( -ids => $all_ids );
    my $plate_list = Cast_List( -list => \@plates, -to => 'string' );
    my $plate_count = @plates;

    my $associated_libs = $self->get_libraries( -ids => $all_ids );
    my @associated_libs;
    @associated_libs = @$associated_libs if $associated_libs;
    my $lib_count = @associated_libs;
    my $library_list = Cast_List( -list => $associated_libs, -to => 'string', -autoquote => 1 );
    ## gotta add check to see how many source lib is related to
    my $confirm_libraries = $self->confirm_Source_Libraries( -library => $library_list, -source => $all_ids );

    my @fields;
    @fields = @$field if $field;
    my @values;
    @values = @$value if $value;
    my $f_size = @fields;
    for my $index ( 0 .. $f_size - 1 ) {
        if ($pooled_count) {
            my $pooled_source_link = &Link_To( $dbc->config('homelink'), "$pooled_count pooled sources", "&cgi_application=SDB::DB_Object_App&rm=Confirm+Propogation&ids=$pools_list&class=Source&field=Source_Status&value=Cancelled", 'blue', ['newwin'] );
            Message "Click here to set $fields[$index] set to '$values[$index]' for Source: $pooled_source_link";
        }
        if ($plate_count) {
            my $plate_link
                = &Link_To( $dbc->config('homelink'), "$plate_count plates", "&cgi_application=SDB::DB_Object_App&rm=Confirm+Propogation&ids=$plate_list&class=Plate&field=Plate_Status&value=Inactive&field=Failed&value=Yes", 'blue', ['newwin'] );
            Message "Click here to set Plate_Status set to 'Inactive', Failed set to 'Yes' for Plate: $plate_link";
        }
        if ($confirm_libraries) {
            my $lib_link = &Link_To( $dbc->config('homelink'), "$lib_count libraries", "&cgi_application=SDB::DB_Object_App&rm=Confirm+Propogation&ids=$library_list&class=Library&field=Library_Status&value=Cancelled", 'blue', ['newwin'] );
            Message "Click here to set Library_Status set to 'Cancelled' for Library: $lib_link";
        }
        elsif ($library_list) {
            Message "The following libraries are linked to sources: $library_list";
        }
    }

    return $self->SUPER::propogate_field( -class => 'Source', -field => $field, -value => $value, -ids => $all_ids, -confirm => $confirm, -dbc => $dbc );
}

######################
sub confirm_Source_Libraries {
######################
    # Checks to see if libraries are assicated with more than sources in given list
    # 0 if there are 1 if not
######################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $libs = $args{-library};
    my $src  = $args{-source};
    my $dbc  = $self->{dbc};

    #  my $library_list =  Cast_List( -list => $libs, -to => 'string');
    my @records = $dbc->Table_find( 'Library_Source', 'FK_Source__ID', " WHERE FK_Library__Name IN ($libs) and FK_Source__ID NOT IN ($src ) " );
    if (@records) {return}
    return 1;
}

######################
sub get_source_plates {
######################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $id     = $args{-ids} || $self->{id};
    my $dbc    = $self->{dbc};
    my @plates = $dbc->Table_find( 'Sample,Plate_Sample', 'Plate_Sample.FKOriginal_Plate__ID', " WHERE FK_Sample__ID = Sample_ID and FK_Source__ID IN ($id ) " );
    return @plates;
}

######################
sub _simplfy_array {
######################
    # puts all main elements of this array into one array
######################
    my $ref = shift;
    my @result;
    my @array;
    @array = @$ref if $ref;
    for my $generation_ref (@array) {
        my @generation;
        @generation = @$generation_ref if $generation_ref;
        for my $list (@generation) {
            my @list;
            @list = @$list if $list;
            push @result, @list;
        }
    }
    return @result;
}

##############################
sub load_Object {
##############################
    # calls the DBObject's load_Object method and performs other object specific actions
    #
    # $self->load_Object();
    #
    # Returns: $self
    #
###################
    my $self = shift;
    $self->SUPER::load_Object();
    
    $self->set( 'original_source_name', $self->get_data('Original_Source.Original_Source_Name') );
    $self->set( 'source_name',          $self->source_name() );

    return $self;
}

######################
sub source_label {
######################
    my $self = shift;

    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $id   = $self->{id} || $args{-id} || 0;

    my $label = alDente::Source_Views::foreign_label( -id => $self->{id}, -dbc => $dbc, -verbose => 1 );

    return $label;
}

###############
sub ancestry {
###############
    my $self              = shift;
    my %args              = &filter_input( \@_ );
    my $dbc               = $args{-dbc} || $self->{dbc};
    my $id                = $self->{id} || $args{-id} || 0;
    my $align             = $args{-align};
    my $detailed_ancestry = 1;

    my ( $parents, $children ) = $self->source_ancestry();
    my $ancestry_view = $self->View->ancestry_view( -parents => $parents, -children => $children, -id => $self->{id}, -dbc => $dbc, -detailed => $detailed_ancestry, -align => $align );

    return $ancestry_view;
}

#########################
# Extracts ancestry info for sources (parents)
#
#########################
sub get_Parents {
#########################
    my %args        = &filter_input( \@_, -mandatory => 'dbc, id' );
    my $dbc         = $args{-dbc};
    my $id          = $args{-id};
    my $generations = $args{-generations} || 40;    ## number of generations to go back
    my $format      = $args{-format} || 'hash';     ## format of output - can be 'hash' or 'list' (comma-delimited string)
    my $ancestry    = $args{-ancestry};             ## include hash if expanding
    my $no_pools    = $args{-no_pools};             ## excludes tracking through pooling
    my $generation_only = $args{-generation_only};  ## only retrieve info for generations key
    my $debug       = $args{-debug};

    my %Ancestry;
    if ($ancestry) { %Ancestry  = %{$ancestry} }
    else           { $Ancestry{list} = [$id] }

    my $curr_gen = $id;     ## current generation

    unless ( $generations =~ /\d+/ ) { $generations = 40 } ## number of generations to go back if incorrect type passed in

    my $gen_index = 0;
    while ($curr_gen) {

        if ($debug) { print Message "on generation $gen_index of limit $generations<BR>current generation: $curr_gen"; }
    
        my @elders = $dbc->Table_find( 'Source', 'FKParent_Source__ID', "WHERE Source_ID IN ($curr_gen) AND FKParent_Source__ID > 0 ORDER BY Source_ID", -distinct => 1 );
        
        unless ($no_pools) {
            push @elders, $dbc->Table_find( 'Source_Pool', 'FKParent_Source__ID', "WHERE FKChild_Source__ID IN ($curr_gen) AND FKParent_Source__ID NOT IN ($curr_gen) ORDER BY FKParent_Source__ID", -distinct => 1 );
        }

        unless (@elders) { last; }
        my $parents = join ',', @elders;
        if ( $gen_index++ >= $generations ) { $dbc->warning("Stopping Ancestry lookup at generation #$gen_index ..."); last; }
        $Ancestry{generation}->{"-$gen_index"} = $parents;
        $Ancestry{parent_generations}++;

        unless ($generation_only) {
            my ($created) = $dbc->Table_find( 'Source', 'MIN(Source_Created)', "WHERE Source_ID IN ($parents)" );
            $Ancestry{created}->{"-$gen_index"} = $created;
            
            push @{ $Ancestry{list} }, $parents;
        }
      
        $curr_gen = get_prev_gen( -dbc => $dbc, -id => $curr_gen, -no_pools => $no_pools );
    }
    
    if ( $format =~ /hash/ ) {
        return %Ancestry;
    }
    elsif ( $format =~ /list/ && defined $Ancestry{list} ) {
        my $list = join ',', @{ $Ancestry{list} };
        return $list;
    }
    elsif ( $format =~ /list/ ) { return '' }
    else { return 0 }

}

#########################
#
#########################
sub get_prev_gen {
#########################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    my $no_pools = $args{-no_pools};

    my @prev_gen = $dbc->Table_find( 'Source', 'FKParent_Source__ID', "WHERE Source_ID IN ($id) AND FKParent_Source__ID > 0 ORDER BY Source_ID", -distinct => 1 );

    unless ($no_pools) {
        push @prev_gen, $dbc->Table_find( 'Source_Pool', 'FKParent_Source__ID', "WHERE FKChild_Source__ID IN ($id) AND FKParent_Source__ID NOT IN ($id) ORDER BY FKParent_Source__ID", -distinct => 1 );
    }

    my $prev_gen = join ',', @prev_gen;

    return $prev_gen;
}

#########################
# returns list of sibling sources (derived from the same parent)
#
#########################
sub get_Siblings {
#########################
    my %args = &filter_input( \@_, -mandatory => 'dbc, id' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    my $format = $args{-format} || 'hash';  ## format of output - can be 'hash' or 'list' (comma-delimited string)
    my $ancestry = $args{-ancestry};    ## include hash if expanding

    my %Ancestry;
    if ($ancestry) { %Ancestry  = %{$ancestry} }
    else           { $Ancestry{list} = [$id] }

    $Ancestry{generation}->{'+0'} = $id;

    my $parent = join ',', $dbc->Table_find( 'Source', 'FKParent_Source__ID', "WHERE Source_ID IN ($id) ORDER BY FKParent_Source__ID", -distinct => 1 );
    my ($created) = $dbc->Table_find( 'Source', 'MIN(Source_Created)', "WHERE Source_ID IN ($id)" );
    
    my $siblings = 0;
    if ( $parent =~ /[1-9]/ ) {
        $siblings = join ',', $dbc->Table_find( 'Source', 'Source_ID', "WHERE FKParent_Source__ID IN ($parent) ORDER BY Source_ID", -distinct => 1 );
        if ( $siblings =~ /[1-9]/ ) {
            $Ancestry{generations}->{'+0'} = $siblings;
            my @sibling_list = split ',', $siblings;
            $Ancestry{list} = \@sibling_list;
        }
    }
    
    if ( $format =~ /hash/ ) {
        return %Ancestry;
    }
    elsif ( $format =~ /list/ && defined $Ancestry{list} ) {
        my $list = join ',', @{ $Ancestry{list} };
        return $list;
    }
    elsif ( $format =~ /list/ ) { return '' }
    else { return 0 }
}

#########################
# returns ids for sources derived from a given source
#
#########################
sub get_Children {
#########################
    my %args        = &filter_input( \@_, -mandatory => 'dbc, id' );
    my $dbc         = $args{-dbc};
    my $id          = $args{-id};
    my $generations = $args{-generations} || 40;    ## number of generations to go back
    my $format      = $args{-format} || 'hash';     ## format of output - can be 'hash' or 'list' (comma-delimited string)
    my $ancestry    = $args{-ancestry};             ## include hash if expanding
    my $no_pools    = $args{-no_pools};             ## excludes tracking through pooling
    my $generation_only = $args{-generation_only};  ## only retrieve info for generations key
    my $debug       = $args{-debug};

    my %Ancestry;
    if ($ancestry) { %Ancestry  = %{$ancestry} }
    else           { $Ancestry{list} = [$id] }

    my $curr_gen = $id;     ## current generation

    unless ( $generations =~ /\d+/ ) { $generations = 40 } ## number of generations to go back if incorrect type passed in

    my $gen_index = 0;
    while ($curr_gen) {

        if ($debug) { print Message "on generation $gen_index of limit $generations<BR>current generation: $curr_gen"; }
    
        my @progeny = $dbc->Table_find( 'Source', 'Source_ID', "WHERE FKParent_Source__ID IN ($curr_gen) ORDER BY Source_ID", -distinct => 1 );
        
        unless ($no_pools) {
            push @progeny, $dbc->Table_find( 'Source_Pool', 'FKChild_Source__ID', "WHERE FKParent_Source__ID IN ($curr_gen) AND FKChild_Source__ID NOT IN ($curr_gen) ORDER BY FKChild_Source__ID", -distinct => 1 );
        }

        unless (@progeny) { last; }
        my $children = join ',', @progeny;
        if ( $gen_index++ >= $generations ) { $dbc->warning("Stopping Ancestry lookup at generation #$gen_index ..."); last; }
        $Ancestry{generation}->{"+$gen_index"} = $children;
        $Ancestry{child_generations}++;

        unless ($generation_only) {
            my ($created) = $dbc->Table_find( 'Source', 'MIN(Source_Created)', "WHERE Source_ID IN ($children)" );
            $Ancestry{created}->{"+$gen_index"} = $created;
            
            push @{ $Ancestry{list} }, $children;
        }
      
        $curr_gen = get_next_gen( -dbc => $dbc, -id => $curr_gen, -no_pools => $no_pools );
    }
    
    if ( $format =~ /hash/ ) {
        return %Ancestry;
    }
    elsif ( $format =~ /list/ && defined $Ancestry{list} ) {
        my $list = join ',', @{ $Ancestry{list} };
        return $list;
    }
    elsif ( $format =~ /list/ ) { return '' }
    else { return 0 }
}

#########################
#
#########################
sub get_next_gen {
#########################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    my $no_pools = $args{-no_pools};

    my @next_gen = $dbc->Table_find( 'Source', 'Source_ID', "WHERE FKParent_Source__ID IN ($id) ORDER BY Source_ID", -distinct => 1 );

    unless ($no_pools) {
        push @next_gen, $dbc->Table_find( 'Source_Pool', 'FKChild_Source__ID', "WHERE FKParent_Source__ID IN ($id) AND FKChild_Source__ID NOT IN ($id) ORDER BY FKChild_Source__ID", -distinct => 1 );
    }

    my $next_gen = join ',', @next_gen;

    return $next_gen;
}

#########################
sub source_ancestry {
########################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $source_id = $args{-id} || $self->{id};
    my $direction = $args{-direction} || 'parents, offspring';
    my $no_pools  = $args{-no_pools};
    my $loop      = $args{-loop} || 0;                           ## index to allow abort if recursive process get stuck
    my $ancestry;

    my $dbc = $self->{dbc};
    $loop++;

    if ( $loop > 5 ) { $dbc->warning('Only showing 5 generations for Source Ancestry'); return ( [] ); }
    my @ancestry;

    my @parents;
    if ( $direction =~ /parents/i ) {
        my $parents;
        my @pooled_srcs = ();
        if ( !$no_pools ) {
            push @pooled_srcs, $dbc->Table_find( 'Source_Pool', 'FKParent_Source__ID', "where FKChild_Source__ID IN ($source_id) AND FKParent_Source__ID NOT IN ($source_id)", -distinct => 1 );
        }
        push @pooled_srcs, $dbc->Table_find( 'Source', 'FKParent_Source__ID', "WHERE Source_ID IN ($source_id) AND FKParent_Source__ID > 0", -distinct => 1 );

        if (@pooled_srcs) {
            my $ids = join ',', @pooled_srcs;
            ($parents) = $self->source_ancestry( -id => $ids, -direction => 'parents', -loop => $loop, -no_pools => $no_pools );
            if ( $parents && @$parents ) { @parents = @$parents }
            push @parents, \@pooled_srcs;
        }
        push @ancestry, \@parents;
    }

    my @offspring;
    if ( $direction =~ /offspring/i ) {
        my $offspring;
        my @pooled_offspring = ();
        if ( !$no_pools ) {
            push @pooled_offspring, $dbc->Table_find( 'Source_Pool', 'FKChild_Source__ID', "where FKParent_Source__ID IN ($source_id) AND FKChild_Source__ID NOT IN ($source_id)", -distinct => 1 );
        }
        push @pooled_offspring, $dbc->Table_find( 'Source', 'Source_ID', "WHERE FKParent_Source__ID IN ($source_id) AND FKParent_Source__ID > 0", -distinct => 1 );

        if (@pooled_offspring) {
            my $ids = join ',', @pooled_offspring;
            ($offspring) = $self->source_ancestry( -id => $ids, -direction => 'offspring', -loop => $loop, -no_pools => $no_pools );
            if ( $offspring && @$offspring ) { @offspring = @$offspring }
            unshift @offspring, \@pooled_offspring;
        }
        push @ancestry, \@offspring;
    }
    return @ancestry;
}
####################################
# This subroutine is to retrieve the ancestry tree and the original starting sources for the given sources
#
# Usage:	 my ( $originals, $tree ) = get_ancestry_tree( -id => $ids, -no_pools => $no_pools );
#
# Return:	Array. The first Item is the array ref of the original starting source ids; the second item is the hash ref of the ancestry tree, with the input source as the root and its original starting sources as the leaves.
#
#           An example:
#        	my ($originals, $parents) = $self->get_ancestry_tree( -id => '60513', -no_pools => 0 );
#        	Dump of $original:
#			['60234','60210','60202','60214','60208','60232','60206','60204','60236','60212'];
#        	Dump of $parents:
#			{
#          	'60513' => {
#                       '60512' => {
#                                    '60498' => {
#                                                 '60436' => {
#                                                              '60210' => 0,
#                                                              '60202' => 0,
#                                                              '60214' => 0,
#                                                              '60208' => 0,
#                                                              '60206' => 0,
#                                                              '60204' => 0,
#                                                              '60212' => 0
#                                                            },
#                                                 '60442' => {
#                                                              '60234' => 0,
#                                                              '60232' => 0,
#                                                              '60236' => 0
#                                                            }
#                                               }
#                                  }
#                     }
#        	};
####################################
sub get_ancestry_tree {
####################################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $source_id = $args{-id} || $self->{id};    # comma separated list of source ids
    my $no_pools  = $args{-no_pools};             # flag to whether to get pooled parents
    my $dbc       = $self->{dbc};

    my @source_ids = split ',', $source_id;

    my @originals;
    my %ancestry;
    my %source_info;
    my $index;
    my %parents;                                  # to store all the unique parent source ids

    ## get pooled parents
    if ( !$no_pools ) {
        %source_info = $dbc->Table_retrieve(
            -table     => 'Source_Pool',
            -fields    => [ 'FKParent_Source__ID', 'FKChild_Source__ID' ],
            -condition => "where FKChild_Source__ID IN ($source_id) AND FKParent_Source__ID NOT IN ($source_id)",
            -distinct  => 1
        );
        $index = 0;
        while ( defined $source_info{FKChild_Source__ID}[$index] ) {
            $ancestry{ $source_info{FKChild_Source__ID}[$index] }{ $source_info{FKParent_Source__ID}[$index] } = 0;
            $parents{ $source_info{FKParent_Source__ID}[$index] }++;
            $index++;
        }
    }

    ## get direct parent
    %source_info = $dbc->Table_retrieve(
        -table     => 'Source',
        -fields    => [ 'FKParent_Source__ID', 'Source_ID' ],
        -condition => "WHERE Source_ID IN ($source_id) AND FKParent_Source__ID > 0",
        -distinct  => 1
    );
    $index = 0;
    while ( defined $source_info{Source_ID}[$index] ) {
        $ancestry{ $source_info{Source_ID}[$index] }{ $source_info{FKParent_Source__ID}[$index] } = 0;
        $parents{ $source_info{FKParent_Source__ID}[$index] }++;
        $index++;
    }

    foreach my $sid (@source_ids) {
        if ( !exists $ancestry{$sid} ) {
            $ancestry{$sid} = 0;
            push @originals, $sid;
        }
    }

    if (%parents) {
        my $ids = join ',', keys %parents;
        my ( $original_srcs, $parents ) = $self->get_ancestry_tree( -id => $ids, -no_pools => $no_pools );
        if ( $original_srcs && int(@$original_srcs) ) {
            push @originals, @$original_srcs;
            foreach my $child ( keys %ancestry ) {
                if ( $ancestry{$child} ) {
                    foreach my $parent ( keys %{ $ancestry{$child} } ) {
                        if ( $parents->{$parent} ) { $ancestry{$child}{$parent} = $parents->{$parent} }
                    }
                }
            }
        }
    }

    return ( \@originals, \%ancestry );
}

##################
sub home_source {
##################
    my %args = &filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    print Views::Heading("Source Home Page");
    my $create_block;
    $create_block = alDente::Form::start_alDente_form( $dbc, 'SourcePage_Create' );

    my $create_header = h3('Add New:') . "<BR><img src='/$URL_dir_name/$image_dir/NEW.png'>";

    # Source creation
    my $source_tab = HTML_Table->new();
    $source_tab->Set_Line_Colour( $Settings{WHITE_BKGD} );
    $source_tab->Set_Row( [ submit( -name => "Create New Library", -value => "New Original_Source", -class => "Action" ), "If previously undefined and no previous Sources received<BR>e.g. defining tissue/organism information for the first time" ] );
    $source_tab->Set_Row( [ submit( -name => "Create New Source",  -value => "New Source",          -class => "Action" ), "If you have previously defined an Original_Source<BR>e.g. receiving additional material for an alrady defined tissue/organism" ] );

    $create_block .= $source_tab->Printout(0) . hidden( -name => 'FKCreated_Employee__ID', -value => $dbc->get_local('user_id') ) . end_form();

    my %source;
    my $search_header = h3('Search:') . "<BR><img src='/$URL_dir_name/$image_dir/flashlight.png'>";

    my $search_block;
    $search_block .= create_tree( -tree => { "Find Sources" => alDente::Rack_Views::find_in_rack( -dbc => $dbc, -find => 'Source' ) }, -print => 0 );
    $search_block .= alDente::Form::start_alDente_form( $dbc, 'SourcePage' );
    $search_block .= submit(
        -name  => 'Search for',
        -value => "Search/Edit Source",
        -class => "Search"
        )
        . &hspace(10)
        . checkbox( -name => 'Multi-Record' );
    $search_block .= hidden( -name => 'Table', -value => 'Source', -force => 1 ) . end_form();

    my $db_header = h3('Database Definitions:') . "<BR><img src='/$URL_dir_name/$image_dir/flashlight.png'>";

    my $db_block .= "";

    my $source_options_header = h3('Source Options');

    my $source_options_block .= "";

    &Views::Table_Print( content => [ [ $create_header, $create_block ], [ hr(), '&nbsp' ], [ $search_header, $search_block ], [ hr(), '&nbsp' ] ] );

    return 1;
}

##############################
sub make_into_source {
##############################
    #  Sets up the page for making a plate/tube into a source
    #
    #  Ex: $source_obj->make_into_source(-dbc=>$dbc,-plate_id=>$plate_id,-type=>$source_type,-submission=>1)
    #
    #  Returns:
    #
##############################

    my %args        = @_;
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id    = $args{-plate_id};
    my $type        = $args{-type};
    my $sub         = $args{-submission} || 0;                                                         ## pass 1 if new library, library_name if resubmission, 0 if not a submission
    my $orig_src_id = $args{-orig_src_id};
    my $check_orig  = $args{-check_original};
    my $tables      = 'Original_Source,Source';
    my $date        = &date_time();

    my $make_pg = '<Table><TR><TD width=375 bgcolor=#eeeefe>Create a source</TD></TR></Table><BR><span class=small>';

    my @src_ids = $dbc->Table_find( 'Plate,Plate_Sample,Sample', 'FK_Source__ID', "where Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample.Sample_ID AND Plate.Plate_ID IN ($plate_id)", -distinct => 1 );
    my @osrc_ids;
    my $src_id_list = join ',', @src_ids;

    if ( scalar(@src_ids) == 1 && $check_orig ) {
        ($orig_src_id) = $dbc->Table_find( 'Source', 'FK_Original_Source__ID', "WHERE Source_ID = $src_ids[0]" );
        ### Start Form ###
        print alDente::Form::start_alDente_form( $dbc, -form => 'MkSrc' );
        print "<BR>";
        my $use_current_orig = submit( -name => 'Make', -value => "Use Current Sample_Origin", -class => "Std" );
        my $create_new_orig  = submit( -name => 'Make', -value => "Define New Sample_Origin",  -class => "Std" ) . "<BR>";
        my $orig_src_form = HTML_Table->new();
        $orig_src_form->Set_Title( "Select original source", fsize => '-1' );
        $orig_src_form->Toggle_Colour('off');
        $orig_src_form->Set_Row( [ $use_current_orig, $create_new_orig ] );
        $orig_src_form->Printout();
        print hidden( -name => 'Original_Source_ID', -value => $orig_src_id );

        print hidden( -name => 'id', -value => "$current_plates", -force => 1 );
        print hidden( -name => 'type', -value => $type );

        #print end_form();
        ### End Form ###
        return 1;
    }
    elsif (@src_ids) {
        @osrc_ids = $dbc->Table_find( 'Source', 'FK_Original_Source__ID', "WHERE Source_ID IN ($src_id_list)" );
    }

    my @presets = ( 'FK_Strain__ID', 'Sex', 'Host', 'FK_Anatomic_Site__ID', 'FK_Taxonomy__ID', 'FK_Contact__ID', 'FK_Barcode_Label__ID' );

    my ($amount) = $dbc->Table_find( 'Plate', 'Current_Volume',       "where Plate_ID IN ($plate_id)" );
    my ($units)  = $dbc->Table_find( 'Plate', 'Current_Volume_Units', "where Plate_ID IN ($plate_id)" );
    my ($format) = $dbc->Table_find( 'Plate', 'FK_Plate_Format__ID',  "WHERE Plate_ID IN ($plate_id)" );

    my $target = 'Database';
    $target = 'Submission' if $sub;

    if ($orig_src_id) {
        my $src_form = SDB::DB_Form->new( -dbc => $dbc, -form_name => 'MkSrc', -table => 'Source', -target => $target, -quiet => 1, -wrap => 0, -start_form => 1, -end_form => 1 );

        #    $src_form->configure(-list=>\%list,-extra=>\%extra,-grey=>\%grey,-omit=>\%hidden);
        my %preset;
        ## preset based on existing source_ids
        $dbc->merge_data(
            -tables        => "Source",
            -primary_field => 'Source.Source_ID',
            -primary_list  => [$src_id_list],
            -preset        => \%preset,
            -skip_list     => [qw(Received_Date FK_Rack__ID FKReceived_Employee__ID Source_Number Current_Amount Original_Amount)]
        );
        my %grey;
        $grey{'Source.FKSource_Plate__ID'} = $dbc->get_FK_info( 'FK_Plate__ID', $plate_id ) if $plate_id;
        $grey{'FK_Rack__ID'} = 1;
        if ( $amount && $units ) {
            $grey{'Source.Current_Amount'}  = $amount if $amount;
            $grey{'Source.Original_Amount'} = $amount if $amount;
            $grey{'Source.Amount_Units'}    = $units  if $units;
        }
        else {
            $preset{'Source.Current_Amount'}  = $amount if $amount;
            $preset{'Source.Original_Amount'} = $amount if $amount;
            $preset{'Source.Amount_Units'}    = $units  if $units;
        }

        $preset{'Source.FK_Plate_Format__ID'} = $format if $format;
        $preset{'Source.FKReceived_Employee__ID'} = $dbc->get_local('user_id');

        $src_form->configure( -preset => \%preset, -grey => \%grey );
        $src_form->generate( -freeze => 0, -submit => 0, -navigator_on => 1 );
    }
    else {
        my $osrc_form = SDB::DB_Form->new( -dbc => $dbc, -form_name => 'MkOsrc', -table => 'Original_Source', -target => $target, -quiet => 1, -start_form => 1, -end_form => 1 );
        my %preset;
        ## preset based on existing source_ids
        $dbc->merge_data(
            -tables        => "Original_Source",
            -primary_field => 'Original_Source.Original_Source_ID',
            -primary_list  => \@osrc_ids,
            -preset        => \%preset,
            -skip_list     => [qw(Received_Date FK_Rack__ID FKReceived_Employee__ID Source_Number Current_Amount Original_Amount)]
        );

        $osrc_form->generate( -freeze => 0, -preset => \%preset, -submit => 0, -navigator_on => 1 );

    }
    return;
}

##############################
sub Pool {
##############################
    #  Creates all apropriate entries in the Hybrid_Original_Source table
    #
    #  Ex: $source_obj->pool(-ids=>\@source_ids);
    #
    #  return: pooled source ID
    #
##############
    my %args = &filter_input( \@_, -args => 'dhb,tables,info,hos_id,target_library_name,merge,on_conflict', -mandatory => 'dbc,info' );

    my $dbc                 = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $tables              = $args{-tables};
    my $pool_info           = $args{-info};
    my $HOS_id              = $args{-hos_id} || 0;
    my $source_id           = $args{-source_id};
    my $no_volume           = $args{-no_volume};
    my $no_html             = $args{-no_html};
    my $target_library_name = $args{-target_library_name};
    my $merge               = $args{-merge};                                                                   # flag to indicate merging sources automatically
    my $on_conflict         = $args{-on_conflict};                                                             # values to use in case of conflicts when merging records
    my $assign              = $args{-assign};                                                                  # values to assign to specified fields when creating merged records
    my $debug               = $args{-debug};

    my %pool_info;

    if ($pool_info) {
        %pool_info = %{$pool_info};
    }

    my @pool_ids = Cast_List( -list => $pool_info->{src_ids}, -to => 'array' );
    my $source_ids = join ',', @pool_ids;

    #remove the library name from the array of src ids to pool
    my $pool_ids = Cast_List( -list => \@pool_ids, -to => 'string', -autoquote => 1 );
    my $parent_originals = join ',', $dbc->Table_find( 'Source', 'FK_Original_Source__ID', "WHERE Source_ID IN ($source_ids)", -distinct => 1 );

    my $pool_obj;
    my $new_source_id;

    if ( !$source_id ) {
        $pool_obj = alDente::Source->new( -dbc => $dbc, -tables => $tables );
        if ($no_html) {
            my $target_original_source_id;
            my @os_ids = $dbc->Table_find( 'Source', 'FK_Original_Source__ID', "WHERE Source_ID IN ($source_ids)", -distinct => 1 );

            if    ( int(@os_ids) == 1 )           { $target_original_source_id = $os_ids[0] }
            elsif ( $pool_info{original_source} ) { $target_original_source_id = $pool_info{original_source} }
            elsif ($target_library_name) {
                ($target_original_source_id) = $dbc->Table_find( 'Library', 'FK_Original_Source__ID', "WHERE Library_Name = '$target_library_name'" );
            }

            $new_source_id = $pool_obj->create_source( -dbc => $dbc, -from_sources => \@pool_ids, -target_original_source_id => $target_original_source_id, -pooled => 1, -merge => 1, -on_conflict => $on_conflict, -assign => $assign, -debug => $debug )
                if ($no_html);
            if     ($new_source_id) {
                ## redefine $pool_obj
                $pool_obj = alDente::Source->new( -dbc => $dbc, -id => $new_source_id );
                ## insert Library_Source record
                if ($target_library_name) {
                    my ($existing_source_id) = $dbc->Table_find( 'Library_Source', 'FK_Source__ID', "WHERE FK_Library__Name = '$target_library_name' AND FK_Source__ID = $new_source_id" );
                    if ( !$existing_source_id ) {
                        $dbc->Table_append( "Library_Source", 'FK_Source__ID,FK_Library__Name', "$new_source_id,$target_library_name", -autoquote => 1 );
                    }
                }
            }
            else {

                # failed in creating new source
                # $dbc->error didn't work properly if this is called within a loop
                my $Bootstrap = new Bootstrap;
                $Bootstrap->error( "Failed to create source", -print => 1 );
                return;
            }
        }
        else {
            $pool_obj->load_object_from_form( -insert => 1 );
        }
    }
    else {
        $pool_obj = alDente::Source->new( -dbc => $dbc, -id => $source_id );
    }

    my $this_src_id = $pool_obj->value( -field => 'Source_ID' );

    #my $orig_source = $pool_obj->value( -field => 'FK_Original_Source__ID' );	# Not working, not sure why this value is not loaded. Get the value from database in the line below
    my ($orig_source) = $dbc->Table_find( 'Source', 'FK_Original_Source__ID', "WHERE Source_ID = $this_src_id" );

    ###############################################################
    ## volume tracking
    ###############################################################
    if ( !$no_volume ) {

        #my $pool_amount = $pool_obj->value( -field => 'Current_Amount' );
        #my $pool_unit   = $pool_obj->value( -field => 'Amount_Units' );
        my ($amount_unit) = $dbc->Table_find( 'Source', 'Current_Amount,Amount_Units', "WHERE Source_ID = $this_src_id" );
        my ( $pool_amount, $pool_unit ) = split ',', $amount_unit;
        my $different;

        # subtract source volume
        foreach my $src_id (@pool_ids) {
            &_subtract_source_volume( -dbc => $dbc, -source_id => $src_id, -amnt => $pool_info{$src_id}{amnt}, -amnt_units => $pool_info{$src_id}{unit} );
            if ($different) {next}
            if ( !$pool_unit ) { $pool_unit = $pool_info{$src_id}{unit} }
            else {
                if ( $pool_info{$src_id}{unit} ne $pool_unit ) {
                    $different = 1;
                    next;
                }
            }

            $pool_amount += $pool_info{$src_id}{amnt};
        }

        # update pooled source volume
        if ($different) {
            $dbc->warning("Amount_Units are different. Pooled volume is not tracked!");
        }
        else {
            my @fields = ( 'Current_Amount', 'Amount_Units' );
            my @values = ( $pool_amount, $pool_unit );

            my ($original_amount) = $dbc->Table_find( 'Source', 'Original_Amount', "WHERE Source_ID = $this_src_id" );
            if ( !$original_amount ) {
                push @fields, 'Original_Amount';
                push @values, $pool_amount;
            }
            $dbc->Table_update_array( 'Source', \@fields, \@values, "WHERE Source_ID = $this_src_id", -autoquote => 1 );
        }

    }
    ################################################################

    my $source_name;
    ##	comment out the if condition below, because even when $orig_source != $parent_originals the $orig_source could have more than one pooled sources. e.g. src39680 and scr39681
    #if ( $orig_source == $parent_originals ) {
    my @source_numbers = $dbc->Table_find( 'Source', 'Source_Number', "WHERE FK_Original_Source__ID=$orig_source" );

    if ( grep( /P/i, @source_numbers ) ) {
        ### if any pools involved....
        my @pooled_src_nums;
        foreach my $num (@source_numbers) {
            if ( $num =~ /P(\d+)/i ) {
                push( @pooled_src_nums, $1 );
            }
        }
        @pooled_src_nums = sort { $b <=> $a } @pooled_src_nums;
        my $max_num = shift(@pooled_src_nums);
        $source_name = 'P' . ++$max_num;
    }
    else {
        $source_name = 'P1';
    }

    #}

    $dbc->Table_update_array( "Source", ['Source_Number'], ["'$source_name'"], "WHERE Source_ID=$this_src_id" );

    # record Source_Pool details
    my @parents;
    foreach my $pool_src (@pool_ids) {

        #my $source_id = $pool_obj->value( -field => 'Source_ID' );
        my ($duplicate) = $dbc->Table_find( "Source_Pool", "Source_Pool_ID", "WHERE FKParent_Source__ID = $pool_src AND FKChild_Source__ID = $this_src_id" );
        my $ok;
        $ok = $dbc->Table_append_array( "Source_Pool", [ 'FKParent_Source__ID', 'FKChild_Source__ID' ], [ $pool_src, $this_src_id ] ) if ( !$duplicate && $pool_src != $this_src_id );
        push @parents, $pool_src;
    }

    $pool_obj->inherit_Attribute( -child_ids => $this_src_id, -parent_ids => \@parents, -table => 'Source' );    ## make sure daughter source inherits pooled parent attributes if applicable

    # if user chose to create a new HOS
    if ( !$HOS_id && !$pool_info->{os_id} ) {
        my $pool_tables         = 'Hybrid_Original_Source';
        my $HOS                 = SDB::DB_Object->new( -dbc => $dbc, -tables => $pool_tables );
        my @original_source_ids = $dbc->Table_find( 'Source', 'FK_Original_Source__ID', "where Source_ID IN ($pool_ids)" );

        # record Hybrid_Original_Source details
        foreach my $original_source (@original_source_ids) {

            #my $child_original_source_id = $pool_obj->value( -field => 'Original_Source_ID' );
            my $child_original_source_id = $orig_source;
            if ( $original_source != $child_original_source_id ) {
                my ($duplicate) = $dbc->Table_find( "Hybrid_Original_Source", "Hybrid_Original_Source_ID", "WHERE FKParent_Original_Source__ID = $original_source AND FKChild_Original_Source__ID = $child_original_source_id" );
                my $ok;
                $ok = $dbc->Table_append_array( "Hybrid_Original_Source", [ 'FKParent_Original_Source__ID', 'FKChild_Original_Source__ID' ], [ $original_source, $child_original_source_id ] ) if !$duplicate;
            }
        }
    }
    else {

        # add Original_Source table for the purposes of displaying a complete Source home page
        $pool_obj->add_tables( 'Original_Source', 'Source.FK_Original_Source__ID=Original_Source_ID' );

        # associate the newly created Source with the library that is associated with its HOS
        my $FK_src_id = $pool_obj->value( -field => 'Source_ID' );
        my $FK_lib_name = $pool_info{HOS_lib}{lib_name};
        if ($FK_lib_name) {
            $dbc->Table_append( "Library_Source", 'FK_Source__ID,FK_Library__Name', "$FK_src_id,$FK_lib_name", -autoquote => 1 );
        }
    }

    #$pool_obj->home_page();
    #alDente::Source_Views::home_page($dbc,$pool_obj) if !$no_html;
    $new_source_id ||= $this_src_id;
    return $new_source_id;
}

#########################
sub create_source {
###############################################
    # Create the Source records from the input sources
    #
    # Usage:	create_source( -dbc => $dbc, -from_sources=> \@pool_ids, -target_original_source_id => $target_original_source_id ); # created multiple sources
    # Usage:	create_source( -dbc => $dbc, -from_sources=> \@pool_ids, -target_original_source_id => $target_original_source_id, -pooled => 1 ); # created one pooled source
    #
    # Return:	Array ref of the newly created Source_IDs if not pooled
    #			Scalar of the newly created Source_ID if pooled
#########################
    my %args = &filter_input( \@_, -args => 'dbc,from_sources,target_original_source_id,pooled, merge', -mandatory => 'dbc,from_sources' );
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $source_ids  = $args{-from_sources};
    my $target_OS   = $args{-target_original_source_id};
    my $pooled      = $args{-pooled};
    my $merge       = $args{-merge};                                                                   # flag to indicate merging sources automatically
    my $on_conflict = $args{-on_conflict};                                                             # values to use in case of conflicts when merging records
    my $assign      = $args{-assign};                                                                  # values to assign to the fields
    my $debug       = $args{-debug};

    my @fields = ( 'FKParent_Source__ID', 'External_Identifier', 'FK_Sample_Type__ID', 'Source_Status', 'Source_Label', 'FK_Original_Source__ID', 'Received_Date', 'FKReceived_Employee__ID', 'FK_Rack__ID', 'FK_Barcode_Label__ID', 'FK_Plate_Format__ID' );

    ## presets
    my $today   = today();
    my $user_id = $dbc->get_local('user_id');
    my ($plate_format_id)  = $dbc->Table_find( 'Plate_Format',  'Plate_Format_ID',  "WHERE Plate_Format_Type = 'Undefined - To Be Determined'" );
    my ($barcode_label_id) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_ID', "WHERE Label_Descriptive_Name = 'No Barcode'" );
    my %preset             = (
        'Source_Status'           => 'Active',
        'FK_Plate_Format__ID'     => $plate_format_id,
        'FK_Rack__ID'             => 1,                                                                # temporary rack
        'FK_Barcode_Label__ID'    => $barcode_label_id,
        'Received_Date'           => $today,
        'FKReceived_Employee__ID' => $user_id,
    );
    if ($target_OS) {
        $preset{'Source.FK_Original_Source__ID'} = $target_OS;
    }

    if ($pooled) {
        if ($merge) {                                                                                  # new way of creating pooled source by merging the data automatically
            my %unresolved;
            return merge_sources( -dbc => $dbc, -from_sources => $source_ids, -unresolved => \%unresolved, -on_conflict => $on_conflict, -assign => $assign );
        }
        else {                                                                                         # old way of creating pooled source
            return create_pool_source( -dbc => $dbc, -from_sources => $source_ids, -target_original_source_id => $target_OS, -fields => \@fields, -preset => \%preset, -debug => $debug );
        }
    }

    ## insert new Source records
    my @new_sources;

    foreach my $source (@$source_ids) {
        my %source_info = $dbc->Table_retrieve(
            -table     => 'Source',
            -fields    => [ 'Source_ID', 'External_Identifier', 'Source_Label', 'FK_Sample_Type__ID' ],
            -condition => "WHERE Source_ID = $source",
        );
        if ( defined $source_info{Source_ID}[0] ) {
            my @values = (
                $source_info{Source_ID}[0], $source_info{External_Identifier}[0], $source_info{FK_Sample_Type__ID}[0], $preset{Source_Status},        $source_info{Source_Label}[0], $target_OS,
                $today,                     $user_id,                             $preset{FK_Rack__ID},                $preset{FK_Barcode_Label__ID}, $preset{FK_Plate_Format__ID},
            );
            my $new_id = $dbc->Table_append_array(
                -dbc       => $dbc,
                -table     => 'Source',
                -fields    => \@fields,
                -values    => \@values,
                -autoquote => 1
            );

            push @new_sources, $new_id;
            Message("Created new Source $new_id");

            #<CONSTRUCTION> This bypass mandatory fields in the source type table

            my $sample_type = get_main_Sample_Type( undef, -id => $source, -dbc => $dbc, -find_table => 1 );

            if ( $dbc->table_loaded($sample_type) && $sample_type && $dbc->get_fields( -table => $sample_type, -like => 'FK_Source__ID' ) ) {

                my $new_src_type_id = $dbc->Table_append_array(
                    -dbc       => $dbc,
                    -table     => $sample_type,
                    -fields    => ['FK_Source__ID'],
                    -values    => [$new_id],
                    -autoquote => 1
                );
                Message("Created new $sample_type $new_src_type_id");

            }

        }    # END if( defined $source_info{Source_ID}[0] )
    }

    return \@new_sources;
}

#########################
sub create_pool_source {
###############################################
    # Create pooled Source record from the input sources. It should be called from create_source().
    #
    # Usage:	create_source( -dbc => $dbc, -from_sources=> \@pool_ids, -target_original_source_id => $target_original_source_id, -fields => \@fields, -preset => \%preset ); # created one pooled source
    #
    # Return:	Scalar, the newly created Source_ID
#########################
    my %args = &filter_input( \@_, -args => 'dbc,from_sources,target_original_source_id,fields,preset', -mandatory => 'dbc,from_sources,target_original_source_id' );
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $source_ids = $args{-from_sources};
    my $target_OS  = $args{-target_original_source_id};

    #    my $fields	= $args{-fields};
    my $preset = $args{-preset};

    my $today   = today();
    my $user_id = $dbc->get_local('user_id');

    my %common;

    ## get sample type for the pooled source
    my $pooled_type = get_pooled_sample_type( -dbc => $dbc, -sources => $source_ids );
    my ($pooled_sample_type_id) = $dbc->Table_find( "Sample_Type", "Sample_Type_ID", "WHERE Sample_Type = '$pooled_type'" );
    $common{FK_Sample_Type__ID} = $pooled_sample_type_id;

    ## get common values from input sources
    foreach my $source (@$source_ids) {
        my ($source_data) = $dbc->Table_find( 'Source', 'External_Identifier,Source_Label,FKReference_Project__ID', "WHERE Source_ID = $source" );
        my ( $external_id, $source_label, $project_id ) = split ',', $source_data;
        if ( !defined $common{External_Identifier} ) {
            $common{External_Identifier} = $external_id;
        }
        elsif ( $common{External_Identifier} ne $external_id ) {
            $common{External_Identifier} = '';
        }

        if ( !defined $common{Source_Label} ) {
            $common{Source_Label} = $source_label;
        }
        elsif ( $common{Source_Label} ne $source_label ) {
            $common{Source_Label} = '';
        }

        if ( !defined $common{FKReference_Project__ID} ) {
            $common{FKReference_Project__ID} = $project_id;
        }
        elsif ( $common{FKReference_Project__ID} ne $project_id ) {
            $common{FKReference_Project__ID} = '';
        }
    }

    ## insert new Source record
    my @add_fields;
    my @fields = $dbc->get_fields( -table => 'Source' );

    my @values;
    foreach my $field (@fields) {
        if ( $preset->{$field} ) {
            push @add_fields, $field;
            push @values,     $preset->{$field};
        }
        elsif ( param('$field') ) {
            push @add_fields, $field;
            push @values,     $common{$field};
        }
        for my $preset_field ( keys %${preset} ) {
            if ( $field =~ $preset_field ) {
                push @add_fields, $preset_field;
                push @values,     $preset->{$preset_field};
            }
        }
        for my $common_field ( keys %common ) {
            if ( $field =~ $common_field ) {
                push @add_fields, $common_field;
                push @values,     $common{$common_field};
            }
        }
    }

    my $new_id = $dbc->Table_append_array(
        -dbc       => $dbc,
        -table     => 'Source',
        -fields    => \@add_fields,
        -values    => \@values,
        -autoquote => 1
    );
    Message("Created new Source $new_id");
    my $sub_table = get_main_Sample_Type( -dbc => $dbc, -id => $new_id, -find_table => 1 );
    if ( $dbc->table_loaded($sub_table) && $sub_table && $dbc->get_fields( -table => $sub_table, -like => 'FK_Source__ID' ) ) {
        my $sub_src_id = $dbc->Table_append_array(
            -dbc       => $dbc,
            -table     => $sub_table,
            -fields    => ['FK_Source__ID'],
            -values    => [$new_id],
            -autoquote => 1
        );
        Message("Created new $sub_table $sub_src_id");
    }
    return $new_id;
}

################################
sub get_pooled_sample_type {
################################
    # Get the sample type of the pooled source
    #
    # Usage:	get_pooled_sample_type( -dbc => $dbc, -sources=> \@source_ids
    #
    # Examples:
    # 	'Tissue' + 'Total RNA' -> 'Mixed'
    # 	'Nucleic Acid' + 'Nucleic Acid - RNA' -> Nucleic Acid
    # 	'Nucleic Acid - DNA' + 'Nucleic Acid - RNA' -> Nucleic Acid
    # 	'Tissue' + 'Tissue' => Tissue
    #	'Nucleic Acid - RNA - Total RNA' + 'Nucleic Acid - RNA' -> 'Nucleic Acid - RNA'
    #	'Nucleic Acid - RNA - Total RNA' + 'Nucleic Acid - RNA - Total RNA' -> 'Nucleic Acid - RNA - Total RNA'
    #
    # Return:	Scalar, the sample type of the pooled source
################################
    my %args = &filter_input( \@_, -args => 'dbc,sources,', -mandatory => 'dbc,sources' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $source_ids = Cast_List( -list => $args{-sources}, -to => 'string', -autoquote => 0 );

    my $pooled_type;
    my @sample_types = $dbc->Table_find( "Source, Sample_Type", "Sample_Type", "WHERE Source_ID IN ($source_ids) AND FK_Sample_Type__ID = Sample_Type_ID", -distinct => 1 );
    my $count = int(@sample_types);
    if ( !$count ) {
        return;
    }
    elsif ( int(@sample_types) == 1 ) {
        return $sample_types[0];
    }

    # find the most common sample type
    my $common_type = shift @sample_types;
    while ( int(@sample_types) ) {
        my $type1 = $common_type;
        my $type2 = shift @sample_types;
        $common_type = '';
        my @p_type1 = get_parent_sample_types( -dbc => $dbc, -type => $type1 );
        my @p_type2 = get_parent_sample_types( -dbc => $dbc, -type => $type2 );
        if ( grep /^$type1$/, @p_type2 ) { $common_type = $type1 }    # type1 is a parent of type2
        elsif ( grep /^$type2$/, @p_type1 ) { $common_type = $type2 } # type2 is a parent of type1
        else {
            ## check if they have a common parent type
            foreach my $t (@p_type1) {                                # should start from the closest parent of type1
                if ( grep /^$t$/, @p_type2 ) { $common_type = $t; last }
            }
            if ( !$common_type ) { $common_type = 'Mixed' }
        }
        last if ( $common_type eq 'Mixed' );
    }
    return $common_type;
}

############################
sub get_parent_sample_types {
############################
    # Description:
    #       Return all the parents of a sample_type
    # Input:
    #       Sample_Type
    #       $dbc
    # Output:
    #       Array of the parent sample types with the nearest parent being first and the farthest parent being the last
############################
    my $self        = shift;
    my %args        = filter_input( \@_, -args => 'dbc,type' );
    my $dbc         = $args{-dbc};
    my $sample_type = $args{-type};

    my @parents;
    while ($sample_type) {
        ($sample_type) = $dbc->Table_find( 'Sample_Type as child, Sample_Type as parent', 'parent.Sample_Type', " WHERE parent.Sample_Type_ID = child.FKParent_Sample_Type__ID and child.Sample_Type = '$sample_type'" );
        push @parents, $sample_type if ($sample_type);
    }

    return @parents;
}

##############################
sub delete_source {
##############################
    # Deletes sources contained in $ids, as well as records with FK_Source__ID in $ids.
    #
    #  Example:
    #   $Source->delete_source( -dbc => $dbc, -ids => "100,101", -confirm => $confirm);
    #
    #  Options:
    #   -confirm => 1 (Performs cascade delete and returns delete status)
    #   -confirm => 0 (Displays confirmation page for sources/referenced records to be deleted)
    #
    #  Returns:
    #   See options
    #
##############################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $ids     = $args{-ids};
    my $confirm = $args{-confirm} || 0;

    my ( $ref_tables, $details, $ref_fields ) = $dbc->get_references(
        -table    => 'Source',
        -field    => 'Source_ID',
        -value    => $ids,
        -indirect => 1
    );

    $ref_tables = $ref_tables . "," . $details if $details;

    if ($confirm) {
        my @cascade;
        my %fields;
        %fields = %$ref_fields if $ref_fields;

        for my $field ( keys %fields ) {
            if ( $field =~ /(.+)\..+/ ) {
                push @cascade, $1;
            }
        }

        #push @cascade, 'Source';
        my $ok = $dbc->delete_records(
            -table   => 'Source',
            -dfield  => 'Source_ID',
            -id_list => $ids,
            -confirm => 1,
            -cascade => \@cascade
        );

        return "Source " . $ids . " was deleted successfully." if $ok;
    }

    else {
        return alDente::Source_Views::delete_confirmation_page(
            -dbc        => $dbc,
            -ids        => $ids,
            -ref_tables => $ref_tables,
            -ref_fields => $ref_fields,
        );
    }
}

##############################
sub get_Original_Sources {
##############################
    # Get ids of all Original_Sources given a Library_Name or Source_ID
    #
    #  Example:
    #	&get_Original_Sources(-dbc=>$dhb,-lib=>$lib,-src=>$src);
    #
    #  Options:
    #   -format => 1 (include all Original_Sources in ancestry)
    #   -format => 0 (include only most immediate Original_Source in ancestry) - default
    #
    #  Returns:
    #	\@original_source_ids;
    #
##############################

    my %args = &filter_input( \@_, -args => 'dbc,lib,src,Osrc,frmt', -mandatory => 'dbc' );

    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $lib    = $args{-lib};
    my $src    = $args{-src};
    my $Osrc   = $args{-Osrc};
    my $format = $args{-frmt} || 0;
    my $tables;

    my $OS = "";

    if ($Osrc) {    ## if Original_Source specified...
        $OS = $Osrc;
    }
    elsif ($src) {    ## if Source spcified...
        $src    = Cast_List( -list => $src, -to => 'string' );
        $tables = 'Source';
        $OS     = join ',', $dbc->Table_find( $tables, 'FK_Original_Source__ID', "where Source_ID IN ($src)" );
    }
    elsif ($lib) {
        ## if Library specified...
        $lib    = Cast_List( -list => $lib, -to => 'string', -autoquote => 1 );
        $tables = 'Library';
        $OS     = join ',', $dbc->Table_find( $tables, 'FK_Original_Source__ID', "where Library_Name IN ($lib)" );
    }

    unless ( $OS =~ /[1-9]/ ) { $dbc->warning("No original source found"); Message('No original source found'); return; }

## if user wants a short list (immediate Original_Source)
    unless ($format) { my @OS_list = split ',', $OS; return \@OS_list; }

    $tables = 'Hybrid_Original_Source';
    my @parent_original_sources = $dbc->Table_find( $tables, 'FKParent_Original_Source__ID', "where FKChild_Original_Source__ID in ($OS)" );

    my @OS_list = split ',', $OS;
    unless (@parent_original_sources) { return \@OS_list }    ## Not a hybrid source

    push( @OS_list, @{ get_Original_Sources( -dbc => $dbc, -Osrc => \@parent_original_sources ) } );
    return \@OS_list;

}

##############################
sub associate_library {
##############################
    #  Associate a library with this source
    #
    #  Ex: $source_obj->associate_library();
    #
    #  Returns: $self
    #
############################

    my $self             = shift;
    my %args             = @_;
    my $source_id        = $self->value('Source_ID');
    my $lib_name         = $args{-library_name};
    my $dbc              = $self->{dbc};
    my $display_src_home = defined $args{-display_src_home} ? $args{-display_src_home} : 1;
    my @lib_OS           = @{ &get_Original_Sources( -dbc => $dbc, -lib => $lib_name, -frmt => 1 ) };
    my @src_OS           = @{ &get_Original_Sources( -dbc => $dbc, -src => $source_id, -frmt => 0 ) };
    my ( $res, $lib, $src ) = RGmath::intersection( \@lib_OS, \@src_OS );

    my @result   = @{$res};
    my @lib_only = @{$lib};
    my @src_only = @{$src};

    if ( $result[0] ) {
    }
    else {
        my ($lib_orig_src) = $dbc->Table_find( 'Library', 'FK_Original_Source__ID', "WHERE Library_Name = '$lib_name'" );
        if ($lib_orig_src) {
            foreach my $orig_src (@src_only) {
                my $ok = $dbc->Table_append_array( 'Hybrid_Original_Source', [ 'FKParent_Original_Source__ID', 'FKChild_Original_Source__ID' ], [ $orig_src, $lib_orig_src ] );
            }
        }

    }
    my $tables = 'Library_Source';
    my $dbo = SDB::DB_Object->new( -dbc => $dbc, -tables => $tables );

    $dbo->value( 'Library_Source.FK_Source__ID',    $source_id );
    $dbo->value( 'Library_Source.FK_Library__Name', $lib_name );
    my $ok = $dbo->insert();
    if ($ok) {
        Message("Library $lib_name associated to source $source_id");
    }
    else {
        Message("Problem associating Library $lib_name");
    }
    if ($display_src_home) {
        print alDente::Source_Views::home_page( -dbc => $dbc, -Source => $self, -id => $source_id );
    }
    return $self;
}

##############################
sub receive_source {
##############################
    #  Receive Source
    #
    #  Ex: $source_obj->receive_source();
    #
    #  Returns: $self
    #
##############################
    my $self = shift;
    my %args = @_;

    my %grey;      ## DB_Form customization - greyed out parameters
    my %preset;    ## DB_Form customization - preset parameters
    my %hidden;    ## DB_Form customization - hidden parameters
    my %list;
    my %extra;
    my %include;
    ## set the date and source number for the new source
    my $date                  = &date_time();
    my $fkparent_source_id    = param('src_id');
    my $dbc                   = $args{-dbc} || $self->param('dbc');
    my $fk_original_source_id = $self->value( 'Source.FK_Original_Source__ID' || '' );
    my $amount                = $args{-amount};                                          ## amount to transfer/aliquot
    my $units                 = $args{-units};                                           ## units of amount
    my $repeat                = $args{-repeat} || 1;                                     ## number of received sources
    my $source_type           = $args{ -source_type };
    my $c_format              = $args{-cont_format};
    my $user_id               = $dbc->get_local('user_id');

    require SDB::Errors;
    SDB::Errors::log_deprecated_usage('receive_source');
    ## this method should no longer be used... instead, we should tweak source_split below if necessary ##

    ##grey out the appropriate fields
    $grey{Original_Amount}    = $amount      if ($amount);
    $grey{Amount_Units}       = $units       if ($units);
    $grey{Current_Amount}     = $amount      if ($amount);
    $grey{FK_Rack__ID}        = 1;
    $grey{FK_Sample_Type__ID} = $source_type if ($source_type);

    # hide appropriate fields
    $hidden{FK_Original_Source__ID}  = $fk_original_source_id;
    $hidden{Source_ID}               = '';
    $hidden{Source_Number}           = 'TBD';
    $hidden{Source_Status}           = 'Active';
    $hidden{FKReceived_Employee__ID} = $user_id;
    $hidden{FKSource_Plate_ID}       = 0;
    my $source_form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Source', -target => 'Database', -wrap => 1 );
    ## preset appropriate fields
    ## Prevent querying from a table that doesn't exist
    my $merge_tables = 'Source';
    my @sub_tables = $self->get_sub_tables( -id => $fkparent_source_id, -dbc => $dbc );
    for my $table (@sub_tables) {
        if ( $dbc->table_loaded($table) && $table ) {
            $merge_tables .= ",$table";
        }
    }
    ## preset appropriate fields
    $dbc->merge_data(
        -table         => $merge_tables,
        -primary_list  => $fkparent_source_id,
        -primary_field => 'Source.Source_ID',
        -preset        => \%preset,
        -clear         => [qw(Received_Date FK_Plate_Format__ID FK_Rack__ID FKReceived_Employee__ID Source_Number Current_Amount Original_Amount FKParent_Source__ID Source_Status FK_Shipment__ID)],
    );

    $preset{FK_Plate_Format__ID} = $dbc->get_FK_ID( -field => 'FK_Plate_Format__ID', -value => $c_format ) if ($c_format);
    $preset{Received_Date} = &date_time();

    $include{'DBRepeat'} = $repeat;
    $source_form->configure( -list => \%list, -grey => \%grey, -preset => \%preset, -omit => \%hidden, -include => \%include );
    $source_form->generate();

    return $self;
}

##############################
sub batch_Aliquot {
##############################
    #  Receive Source
    #
    #
##############################
    my $self        = shift;
    my %args        = &filter_input( \@_ );
    my $dbc         = $self->{dbc};
    my $values      = $args{'-values'};
    my $ids         = $args{-ids};
    my $label       = $args{-label};
    my $format      = $args{'-format'};
    my $split_type  = $args{-split_type};
    my $DBRepeat    = $args{-DBRepeat};
    my $sample_type = $args{-sample_type};
    my @ids         = split ',', $ids;
    my $count       = @ids;
    my @new_sources;

    for my $id (@ids) {
        my @new = $self->brief_split_source(
            -id                  => $id,
            -amount              => $values->{Current_Amount}{$id},
            -units               => $values->{Amount_Units}{$id},
            -split_type          => $split_type,
            -label               => $label,
            -cont_format         => $format,
            -source_type         => $sample_type,
            -repeat              => $DBRepeat,
            -storage_medium      => $values->{FK_Storage_Medium__ID}{$id},
            -sm_units            => $values->{Storage_Medium_Quantity_Units}{$id},
            -sm_quantity         => $values->{Storage_Medium_Quantity}{$id},
            -concentration       => $values->{Current_Concentration}{$id},
            -concentration_units => $values->{Current_Concentration_Units}{$id},
        );
        push @new_sources, @new;
    }

    return @new_sources;
}

##############################
sub brief_split_source {
##############################
    #  Receive Source
    #
    #
##############################
    my $self                = shift;
    my %args                = &filter_input( \@_ );
    my $date                = &date_time();
    my $source_id           = $self->value('Source.Source_ID') || param('src_id') || $args{-id};
    my $dbc                 = $args{-dbc} || $self->{dbc};
    my $amount              = $args{-amount};                                                      ## amount to transfer/aliquot
    my $units               = $args{-units};                                                       ## units of amount
    my $repeat              = $args{-repeat} || 1;                                                 ## number of received sources
    my $source_type         = $args{ -source_type };
    my $c_format            = $args{-cont_format};
    my $sm_units            = $args{-sm_units};
    my $sm_quantity         = $args{-sm_quantity} || '0';
    my $storage_medium      = $args{-storage_medium};
    my $split_type          = $args{-split_type};
    my $label               = $args{-label};
    my $concentration       = $args{-concentration};
    my $concentration_units = $args{-concentration_units};
    my $user_id             = $dbc->get_local('user_id');

    my @new_ids;
    my @fields = (
        'Original_Amount',         'Amount_Units',          'Current_Amount',              'FK_Rack__ID', 'Source_Number',       'Source_Status',
        'FKReceived_Employee__ID', 'FKSource_Plate__ID',    'FK_Shipment__ID',             'Source_ID',   'FKParent_Source__ID', 'Storage_Medium_Quantity_Units',
        'Storage_Medium_Quantity', 'Current_Concentration', 'Current_Concentration_Units', 'Current_Concentration_Measured_by'
    );
    my @values = ( $amount, $units, $amount, 1, 'TBD', 'Active', $user_id, 0, 0, '', $source_id, $sm_units, $sm_quantity, $concentration, $concentration_units, '' );

    if ($c_format) {
        my ($c_format_id) = $dbc->get_FK_ID( -field => 'FK_Plate_Format__ID', -value => $c_format );
        push @values, $c_format_id;
        push @fields, 'FK_Plate_Format__ID';
    }
    if ($storage_medium) {
        my ($storage_medium_id) = $dbc->get_FK_ID( -field => 'FK_Storage_Medium__ID', -value => $storage_medium );
        push @values, $storage_medium_id;
        push @fields, 'FK_Storage_Medium__ID';

    }
    if ( $source_type && $split_type ne 'Aliquot' && $split_type ne 'Transfer' ) {
        my ($sample_type_id) = $dbc->get_FK_ID( -field => 'FK_Sample_Type__ID', -value => $source_type );
        push @values, $sample_type_id;
        push @fields, 'FK_Sample_Type__ID';

    }

    if ($label) {
        push @values, $label;
        push @fields, 'Source_Label';
    }

    ## check for inactive sources ? ## (shouldn't really prompt for this action if it is not active in the first place)

    my $ignore_attributes;
    if ( $split_type =~ /^Receive/ ) { $ignore_attributes = 1 }

    for my $index ( 1 .. $repeat ) {
        my @temp_fields = @fields;
        push @temp_fields, 'Source_ID';

        ( my $new_src_id, my $copy_time ) = $dbc->Table_copy( -table => 'Source', -condition => "where Source_ID = $source_id", -time_stamp => 'Received_Date', -exclude => \@fields, -replace => \@values, -ignore_attributes => $ignore_attributes );
        push @new_ids, $new_src_id;

        my $sample_type        = $self->get_main_Sample_Type( -id => $new_src_id, -dbc => $dbc, -find_table => 1 );
        my $parent_sample_type = $self->get_main_Sample_Type( -id => $source_id,  -dbc => $dbc, -find_table => 1 );
        if ( $split_type eq 'Aliquot' || $split_type eq 'Transfer' ) {
            $sample_type = $parent_sample_type;
        }

        if ( $dbc->table_loaded($sample_type) && $sample_type ) {
            my ( $to, $from ) = $dbc->schema_references( -seed => 'Source', -tables => $sample_type );
            if ( $from->[0] ) {
                if ( $sample_type eq $parent_sample_type ) {
                    my ($primary_id) = $dbc->get_field_info( $sample_type, undef, 'Primary' );
                    my ($sec_id) = $dbc->Table_find( $sample_type, $primary_id, "WHERE FK_Source__ID = $source_id " );
                    my @sec_fields = ( "$primary_id", 'FK_Source__ID' );
                    my @sec_values = ( '',            $new_src_id );
                    ( my $new_secondary_id, my $copy_time ) = $dbc->Table_copy( -table => $sample_type, -condition => "where $primary_id = $sec_id", -exclude => \@sec_fields, -replace => \@sec_values, -ignore_attributes );
                }
                else {
                    $dbc->Table_append( $sample_type, 'FK_Source__ID', "$new_src_id", -autoquote => 1 );
                }
            }
        }

    }
    return @new_ids;

}

##############################
sub split_source {
##############################
    # Splits the source and sets the FKParent_Source_ID
    #
    #  Ex: $source_obj->split_source();
    #
    #  Returns: $self
    #
##############################
    my $self = shift;
    my %args = @_;

    my %grey;       ## DB_Form customization - greyed out parameters
    my %preset;     ## DB_Form customization - preset parameters
    my %hidden;     ## DB_Form customization - hidden parameters
    my %include;    ## Submit parameters

    ## set new parameter for the child source
    my $date                  = &date_time();
    my $source_type           = $args{ -source_type };
    my $fk_original_source_id = $args{-original_source_id};
    my $parent_id             = $args{-parent_id} || param('src_id');
    my $amount                = $args{-amount};                         ## amount to transfer/aliquot
    my $new_units             = $args{-units};                          ## units of amount to transfer
    my $repeat                = $args{-repeat} || 1;                    ## number or transfers/aliquots
    my $dbc                   = $args{-dbc} || $self->{dbc};
    my $c_format              = $args{-cont_format};
    my $user_id               = $dbc->get_local('user_id');

    my ( $current_amt, $current_units, $source_status );

    #
    #    may need to adjust to include option for new samples (to replace retrieve_source method above which should be deprecated)
    #    if (!$new) {
    $parent_id ||= $self->primary_value( -table => 'Source' );
    $current_amt           ||= $self->value('Current_Amount');
    $current_units         ||= $self->value('Amount_Units');
    $fk_original_source_id ||= $self->value('FK_Original_Source__ID');
    $source_status         ||= $self->value('Source_Status');
    $source_type           ||= $self->value('FK_Sample_Type__ID');

    #    }

    ###############################################
    ## Update current source details based on the options selected
    ###############################################
    if ( defined $current_amt && defined $amount && ( $new_units eq $current_units ) ) {
        ## calculate new volumes
        my $transfer_amnt = $amount * $repeat;
        my $new_curr_amnt = $current_amt - $transfer_amnt;

        if ( $transfer_amnt > $current_amt ) {
            Message("The amount of current source ($current_amt $new_units) is not sufficient for this action, please reduce the amount.");
            $self->home_page();
            return 0;
        }
        else {
            ## update the source volume after the transfer/aliquot
            $current_amt = $new_curr_amnt;
        }
    }

    ###############################################
    ## Setup new source details
    ###############################################

    ## grey out appropriate fields
    $grey{Original_Amount}    = $amount      if ($amount);
    $grey{Amount_Units}       = $new_units   if ($new_units);
    $grey{Current_Amount}     = $amount      if ($amount);
    $grey{FK_Rack__ID}        = 1;
    $grey{FK_Sample_Type__ID} = $source_type if ($source_type);

    ## hide appropriate fields
    $hidden{Source_ID}               = '';
    $hidden{Source_Number}           = 'TBD';
    $hidden{Source_Status}           = 'Active';
    $hidden{Defined_Date}            = $date;
    $hidden{FKReceived_Employee__ID} = $user_id;
    $hidden{FK_Original_Source__ID}  = $fk_original_source_id;
    $hidden{FKParent_Source__ID}     = $parent_id;
    $hidden{FKSource_Plate_ID}       = 0;

    ## display the form for the new source with custom configuration (grey,preset,omit)
    my $source_form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Source', -target => 'Database' );

    ## Prevent querying from a table that doesn't exist
    my $merge_tables = 'Source';
    my $sample_type = $self->get_main_Sample_Type( -id => $parent_id, -dbc => $dbc, -find_table => 1 );
    if ( $dbc->table_loaded($sample_type) && $sample_type ) {
        $merge_tables .= ",$sample_type";
    }

    ## preset appropriate fields
    $dbc->merge_data(
        -table         => $merge_tables,
        -primary_list  => $parent_id,
        -primary_field => 'Source.Source_ID',
        -preset        => \%preset,
        -skip_list     => [qw(Received_Date FK_Rack__ID FKReceived_Employee__ID Source_Number Current_Amount Original_Amount)]
    );

    if ($new_units) {
        $preset{Amount_Units} = $new_units;
    }

    $preset{Received_Date} = &date_time();
    $preset{FK_Plate_Format__ID} = $dbc->get_FK_ID( -field => 'FK_Plate_Format__ID', -value => $c_format ) if ($c_format);
    delete $preset{FKParent_Source__ID};
    delete $preset{Source_Status};
    delete $preset{FK_Shipment__ID};

    $include{'DBRepeat'} = $repeat;
    $source_form->configure( -grey => \%grey, -preset => \%preset, -omit => \%hidden, -include => \%include );
    $source_form->generate( -navigator_on => 1 );

    return $self;
}

##############################
sub get_offspring {
##############################
    # Get ids of all sources associated with the same original source
    #
    #  Ex: $source_obj->get_offspring(-dbc=>$dhb,-id=>$ids);
    #
    #  Returns: \%sources;
    #
##############################

    my %args               = @_;
    my $dbc                = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $original_source_id = $args{-id};
    my $tables             = 'Original_Source,Source';
    my @offspring_ids;

    my %sources = &Table_retrieve( $dbc, $tables, [ 'Source_ID', 'Original_Source_Name', 'Source_Number' ], "WHERE FK_Original_Source__ID=$original_source_id AND Original_Source_ID = $original_source_id" );

    return \%sources;
}
##############################

##############################
sub get_source_formats {
##############################
    # Get details of the offspring sources for a particular Sample_Origin (plates, etc)
    #
    #  Ex: $source_obj->get_offspring_details(-dbc=>$dhb,-id=>$ids,-include_inactive=>1);
    #
    #  Returns:
    #
##############################

    my %args           = @_;
    my $dbc            = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $source_ids_ref = $args{-ids} || '';                                                               ## list or sources for the library home page table

    my $tables = 'Source';

    if ($source_ids_ref) {
        ## check if an array of source ids has been passed in if yes use it instead of the %
        my @source_ids = @{$source_ids_ref};

        if ( scalar(@source_ids) > 0 ) {
            my $src_link;

            my $src_list = join ',', @source_ids;

            return $dbc->Table_retrieve_display(
                'Source', [ 'Source_ID as Source_ID', 'FK_Sample_Type__ID as Type', 'Source_Number as Number', 'Source_Label as Label', 'External_Identifier as Ext_ID' ],
                "WHERE Source_ID IN ($src_list)",
                -title       => 'Starting Material Received',
                -return_html => 1
            );
        }
    }
    else {
        print "<FONT SIZE=2 COLOR=RED>NO ASSOCIATED SOURCES</FONT>";
        return;
    }
}

##############################
sub get_offspring_details {
##############################
    # Get details of the offspring sources for a particular Sample_Origin (plates, etc)
    #
    #  Ex: $source_obj->get_offspring_details(-dbc=>$dhb,-id=>$ids,-include_inactive=>1);
    #
    #  Returns:
    #
##############################

    my %args                    = @_;
    my $dbc                     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $original_source_id      = $args{-id};                                                                      ## original source for which to find sources
    my $include_inactive_plates = $args{-include_inactive};                                                        ## includes all plates in addition to the active ones
    my $source_ids_ref          = $args{-ids} || '';                                                               ## list of sources for the library home page table
    my $extra_condition         = $args{-extra_condition};

    my $tables = 'Source,Sample,Plate_Sample,Plate,Sample_Type';
    $extra_condition .= " AND Plate_Status='Active'" unless $include_inactive_plates;
    my $name_view = "concat(Plate.FK_Library__Name,'-',Plate.Plate_Number)";
    my @offspring_ids;

    if ($source_ids_ref) {                                                                                         ## check if an array of source ids has been passed in if yes use it instead of the %
        @offspring_ids = @{$source_ids_ref};

    }
    else {

        my %offspring_srcs = %{ get_offspring( -dbc => $dbc, -id => $original_source_id ) };

        ## check if the original source has any associated sources
        if ( exists $offspring_srcs{Source_ID}[0] ) {
            @offspring_ids = @{ $offspring_srcs{Source_ID} };
        }
        else {
            @offspring_ids = ();
        }
    }
    if ( scalar(@offspring_ids) ) {

        my @ids;
        my $off_link;
        my $plate_link;
        my @names;
        my @plate_ids = ();
        my @plate_name;
        my @plate_type;
        my @plate_status;
        my @failed;
        my @rack_id;
        my @number;
        my @racks;
        my @Pnumber;
        my @libs;

        ## generate wrapper table containing sub-tables (showing individual plates)
        my $Source_list = HTML_Table->new( -width => '100%' );
        $Source_list->Set_Title( "Associated Sources and Plates/Tubes", fsize => '-1' );

        ## generate tree link for each of the available sources ##
        foreach my $offspring_id (@offspring_ids) {

            my $detail_table = HTML_Table->new( -width => '100%' );
            $detail_table->Set_Line_Colour( $Settings{LIGHT_BKGD} );
            $detail_table->Set_Alignment( 'center', 2 );
            $detail_table->Set_Alignment( 'center', 3 );
            $detail_table->Set_Alignment( 'center', 4 );

            my $src_name = source_name( undef, -dbc => $dbc, -id => $offspring_id );
            $off_link = &Link_To( $dbc->config('homelink'), "<SPAN class=small>$src_name</SPAN>", "&HomePage=Source&ID=$offspring_id", $Settings{LINK_COLOUR} ) . ' ';
            $off_link .= "<SPAN class=small> ID: $offspring_id </SPAN>";

            my %plates = &Table_retrieve(
                $dbc, $tables,
                [   'count(DISTINCT Plate_ID) as Number', 'count(DISTINCT Plate.FK_Rack__ID) as Racks', 'Plate_ID',                  'Sample_Type.Sample_Type',
                    'Plate_Status',                       'Failed',                                     "Plate.FK_Rack__ID as Rack", "$name_view AS Plate_Name",
                    'Plate.FK_Library__Name',             'Plate.Plate_Number'
                ],
                "WHERE Sample.FK_Source__ID = $offspring_id AND Sample.FK_Source__ID = Source.Source_ID AND Plate_Sample.FK_Sample__ID=Sample.Sample_ID 
                AND Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate.FK_Sample_Type__ID = Sample_Type.Sample_Type_ID $extra_condition 
                GROUP BY Plate.FK_Library__Name,Plate.Plate_Number,Sample_Type.Sample_Type,Plate_Status ORDER BY Plate.FK_Library__Name,Plate.Plate_Number",
                -distinct => 1
            );

            ## check if the source has any associated plates
            if ( exists $plates{Plate_ID}[0] ) {

                @plate_ids    = @{ $plates{Plate_ID} };
                @plate_type   = @{ $plates{Sample_Type} };
                @plate_status = @{ $plates{Plate_Status} };
                @failed       = @{ $plates{Failed} };
                @plate_name   = @{ $plates{Plate_Name} };
                @rack_id      = @{ $plates{Rack} };
                @number       = @{ $plates{Number} };
                @racks        = @{ $plates{Racks} };
                @libs         = @{ $plates{FK_Library__Name} };
                @Pnumber      = @{ $plates{Plate_Number} };

            }
            else {

                @plate_ids    = ();
                @plate_type   = ();
                @plate_status = ();
                @failed       = ();
                @plate_name   = ();
                @rack_id      = ();
                @number       = ();
                @racks        = ();
                @libs         = ();
                @Pnumber      = ();
            }

            ## setup the table of sources and associated plates/tubes
            $detail_table->Set_sub_header( $off_link, $Settings{HIGHLIGHT_CLASS} );

            if ( scalar(@plate_ids) ) {
                $detail_table->Set_Row( [ '<B>Plate/Tube</B>', '<B>Type</B>', '<B>Number</B>', '<B>Rack</B>', '<B>Status</B>' ], "lightbluebw" );
            }

            for ( my $i = 0; $i < scalar(@plate_ids); $i++ ) {

                my $plate_name = $plate_name[$i];
                $plate_link = &Link_To( $dbc->config('homelink'), $plate_name, "&HomePage=Plate&ID=$plate_ids[$i]", $Settings{LINK_COLOUR}, ['newwin'] );
                push @names, $plate_link;
                my $rack = '*';
                ## include Rack if there are not multiple values.. ##
                if ( $racks[$i] < 2 ) { $rack = get_FK_info( $dbc, 'FK_Rack__ID', $rack_id[$i] ) }

                if ( $number[$i] > 1 ) {
                    $plate_link = &Link_To(
                        $dbc->homelink(),
                        "$plate_name+",
                        "&Quick_Action_List=Table_retrieve_display&Table=Plate,Sample_Type&Fields=Plate_ID,FK_Library__Name,Plate_Number,FK_Rack__ID as Rack,Sample_Type as Type,Plate_Status,Failed&Condition=WHERE 
                        Plate.FK_Sample_Type__ID = Sample_Type.Sample_Type_ID AND Plate_Number=$Pnumber[$i] AND FK_Library__Name='$libs[$i]' $extra_condition",
                        $Settings{LINK_COLOUR},
                        ['newwin']
                    );
                }

                $detail_table->Set_Row( [ $plate_link, $plate_type[$i], $number[$i], $rack, $plate_status[$i], $failed[$i] ] );
            }
            if ( scalar(@plate_ids) ) {
                $Source_list->Set_Row( [ create_tree( -tree => { $src_name => $detail_table->Printout(0) } ) ] );
            }
            else {
                $Source_list->Set_sub_header($off_link);
            }

        }

        if ( $source_ids_ref and ( @{$source_ids_ref} eq '' ) ) {
            return;
        }
        else {
            return $Source_list->Printout(0);
        }
    }
    print "<FONT SIZE=2 COLOR=RED>NO ASSOCIATED SOURCES</FONT>";
    return;
}

########################
sub get_downstream_sources {
########################
    my %args  = @_;
    my $dbc   = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $s_ids = $args{-source_ids} || '0';                                                       ## list of sources for the library home page table

    my $source_ids = &Cast_List( -list => $s_ids, -to => 'string' );

    return &SDB::DB_Form_Viewer::view_records(
         $dbc, 'Source,Plate,Library',
        -fields    => [ 'FKSource_Plate__ID', 'Source_ID', 'Library_Name' ],
        -condition => "WHERE FKSource_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name AND Source_ID in ($source_ids)"
    );
}

##############################
sub get_siblings {
##############################
    # Get ids of other sources associated with the same original source
    #
    #  Ex: $source_obj->get_siblings();
    #
    #  Returns: \%sources;
    #
##############################

    my $self = shift;
    my $dbc  = $self->{dbc};

    my @offspring_ids;

    ## retrieve all offspring sources
    my $source_id = $self->primary_value( -table => 'Source' );
    my $tables = 'Original_Source,Source';

    my ($original_source_id) = $dbc->Table_find( $tables, 'FK_Original_Source__ID', "where Source_ID=$source_id" );

    my %sources = &Table_retrieve( $dbc, $tables, [ 'Source_ID', 'Original_Source_Name', 'Source_Number' ], "WHERE FK_Original_Source__ID=$original_source_id AND Original_Source_ID = $original_source_id" );

    return \%sources;
}

##############################
sub get_associated_libs {
##############################
    # Get names of libraries associate with source ids passed
    #
    #  Ex: %source_obj=get_associated_libs(-dbc=>$dbc,-ids=>\@ids);
    #
    #  Returns: \%lib_names;
    #
##############################

    my %args = &filter_input( \@_, -args => 'dhb,ids', -mandatory => 'dbc,ids' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $ids = $args{-ids};
    my @ids = @{$ids};
    my %associated_libs;

    my $tables = 'Library_Source';
    my $id_list = join ',', @ids;

    ## retrieve all library names that are associated with this source based on FK_Source__ID
    my %libs = &Table_retrieve( $dbc, $tables, [ 'FK_Source__ID as Source_ID', 'FK_Library__Name as Library_Name' ], "WHERE FK_Source__ID in ($id_list)" );
    if ( exists $libs{Source_ID}[0] ) {

        my @sources = @{ $libs{Source_ID} };

        for ( my $i = 0; $i < scalar(@sources); $i++ ) {

            push @{ $associated_libs{ $sources[$i] } }, $libs{Library_Name}[$i];
        }
    }
    return \%associated_libs;
}

##############################
sub get_libraries {
##############################
    # Get names of libraries associate with this source
    #
    #  Ex: $source_obj->get_libraries();
    #
    #  Returns: \@lib_names;
    #
##############################

    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $self->{dbc};
    my $srcid = $args{-ids} || $self->value('Source_ID') || 0;

    ## retrieve all library names that are associated with this source based on FK_Source__ID
    my $tables = 'Library_Source';
    my @lib_names = $dbc->Table_find( $tables, 'FK_Library__Name', "WHERE FK_Source__ID in ($srcid)" );
    return \@lib_names;
}

##############################
sub related_sources_HTML {
##############################
    #  Generates a table for related sources
    #
    #  Ex: $source_obj->related_sources_HTML();
    #
    #  Returns:
###############################

    my $self      = shift;
    my $source_id = $self->primary_value( -table => 'Source' );
    my $dbc       = $self->{dbc};

    my %offspring      = %{ $self->get_siblings() };
    my $source_id_list = Cast_List( -list => $offspring{Source_ID}, -to => 'string' );
    my @fields         = ( 'Source_ID', "concat(Original_Source_Name,' - ',Sample_Type,' #',Source_Number) AS Name", 'GROUP_CONCAT( FK_Library__Name ) AS Library', 'FK_Shipment__ID AS Shipment' );
    my $tables         = "Original_Source,Source LEFT JOIN Sample_Type ON FK_Sample_Type__ID = Sample_Type_ID ";
    $tables .= "LEFT JOIN Library_Source ON Library_Source.FK_Source__ID = Source_ID ";
    my $conditions = " WHERE Source.FK_Original_Source__ID = Original_Source_ID ";
    $conditions .= " AND Source_ID in ($source_id_list) ";
    my $result = $dbc->Table_retrieve_display(
        -title           => "Sample_Material from same Sample_Origin",
        -table           => $tables,
        -fields          => \@fields,
        -condition       => $conditions,
        -group           => 'Source_ID',
        -order           => 'Source_ID,Library',
        -distinct        => 1,
        -list_in_folders => ['Library'],
        -return_html     => 1,
    );
    return $result;
}

#################
sub export_sources {
##################
    #
    # Method to export sources
    #
################

    my %args = &filter_input( \@_, -args => 'id,destination' );

    my $ids      = $args{-id};
    my $dest     = $args{-destination};
    my $comments = $args{-comments};
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id  = $dbc->get_local('user_id');

    $ids = Cast_List( -list => $ids, -to => 'string' );

    #    my ($exprack_id) = join(',',$dbc->Table_find('Rack','Rack_ID',"WHERE Rack_Name='Exported'"));
    my ($exprack_id) = $dbc->Table_find( 'Location,Equipment,Rack', 'Rack_ID', "WHERE FK_Location__ID = Location_ID AND FK_Equipment__ID = Equipment_ID AND Location_Name='$dest' " );

    &alDente::Rack::move_Items( -dbc => $dbc, -type => 'Source', -ids => $ids, -rack => $exprack_id, -force => 1, -confirmed => 1 );

    my $message = "Exported to '$dest' by " . $dbc->get_FK_info( 'FK_Employee__ID', $user_id ) . ", on " . &date_time() . '.';
    $message .= " - Comments: $comments ." if $comments;
    $message = $dbc->dbh()->quote($message);
    my $status = 'Inactive';
    $status = $dbc->dbh()->quote($status);
    $dbc->Table_update_array( 'Source', [ 'Notes', 'Source_Status' ], [ "CASE WHEN Notes IS NULL THEN $message ELSE CONCAT(Notes,' ',$message) END", "$status" ], "WHERE Source_ID in ($ids)" );
    $Sess->homepage("Source=$ids");
    return 0;
}

##############################
sub request_Replacement {
##############################
    my %args = &filter_input( \@_, -args => 'id' );

    my $ids      = $args{-id};
    my $reason   = $args{-reason};
    my $comments = $args{-comments};
    my $dbc      = $args{-dbc};

    my @list = Cast_List( -list => $ids, -to => 'array' );

    my $reason_id = $dbc->get_FK_ID( 'FK_Replacement_Source_Reason__ID', $reason );

    my $requests = 0;
    foreach my $id (@list) {

        my $request = alDente::Attribute::set_attribute( -dbc => $dbc, -object => 'Source', -attribute => 'Replacement_Source_Status', -id => $id, -value => 'Requested', -on_duplicate => 'Replace' );
        if ($request) {
            $request = $dbc->Table_append_array(
                'Replacement_Source_Request',
                [ 'Replacement_Source_Requested', 'Replacement_Source_Status', 'FK_Source__ID', 'FK_Replacement_Source_Reason__ID', 'Replacement_Source_Request_Comments' ],
                [ date_time(),                    'Requested',                 $id,             $reason_id,                         $comments ],
                -autoquote => 1
            );
        }
    }

    return $requests;
}

##########################
sub is_Replacement {
##########################
    # Quickly check to see if this source matches an existing source for which there is a replacement request
    #  (must be same Original_Source from same Supplier Organization (and both have a shipping reference)
    #
    # if a replacement, update the replacement request and status...
    #
    # (also track unsolicited replacement samples ?)...
    #
    # Return: 1 if replacement
##########################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'id' );

    my $id       = $args{-id} || $self->{id};
    my $reason   = $args{-reason};
    my $comments = $args{-comments};
    my $dbc      = $args{-dbc} || $self->{dbc};

    my @equivalent = $dbc->Table_find_array(
        'Source, Shipment, Source as Duplicate, Shipment as Duplicate_Shipment, Replacement_Source_Request',
        [ 'Source.Source_ID', 'Duplicate.Source_ID', 'Replacement_Source_Request_ID', 'Replacement_Source_Status' ],
        "WHERE Duplicate.FK_Original_Source__ID=Source.FK_Original_Source__ID AND Source.FK_Shipment__ID=Shipment.Shipment_ID AND Duplicate.FK_Shipment__ID=Duplicate_Shipment.Shipment_ID AND Shipment.FKSupplier_Organization__ID=Duplicate_Shipment.FKSupplier_Organization__ID AND Source.Source_ID != Duplicate.Source_ID and Duplicate.Source_ID = $id AND Replacement_Source_Request.FK_Source__ID=Source.Source_ID AND Replacement_Source_Status = 'Requested' Order by Replacement_Source_Requested"
    );

    if ( int(@equivalent) > 1 ) {
        $dbc->warning("Multiple possible replacement requests - using first one...");
        $dbc->warning("(Ignoring: $equivalent[1]");
    }

    my $replacements = 0;
    if (@equivalent) {
        my ( $original, $replacement, $request_id, $status ) = split ',', $equivalent[0];
        my $replacement_found = $dbc->Table_update_array(
            'Replacement_Source_Request',
            [ 'Replacement_Source_Status', 'FKReplacement_Source__ID', 'Replacement_Source_Received' ],
            [ 'Received',                  $replacement,               date_time() ],
            "WHERE Replacement_Source_Request_ID = $request_id",
            -autoquote => 1,
        );

        if ($replacement_found) {
            $replacements += alDente::Attribute::set_attribute( -dbc => $dbc, -object => 'Source', -attribute => 'Replacement_Source_Status', -id => $replacement, -value => 'Replacement', -on_duplicate => 'Replace' );
            &alDente::Attribute::set_attribute( -dbc => $dbc, -object => 'Source', -attribute => 'Replacement_Source_Status', -id => $original, -value => 'Received', -on_duplicate => 'Replace' );
        }

        $dbc->message("Replacement sample identified");
    }

    return $replacements;

}

#
# Wrapper to merge original sources given a list of sources
# - If the OS is common among the input sources, return the the common OS;
# - If the OS is different, prompt a multi form for user to enter and confirm
#
#
#
# Return: new original source ID
#################
sub merge_OS {
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $source_id   = Cast_List( -list => $args{-source_id}, -to => 'string' );
    my $on_conflict = $args{-on_conflict};
    my $test        = $args{-test};                                               ## suppress messages (use this flag if calling only to retrieve conflict values first)

    ## CUSTOM PRESET VARIOUS On_Conflict Settings ##
    #Original Source
    #$on_conflict->{FK_Taxonomy__ID}        = '<Taxonomy_Name=mixed libraries';
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

    ######################################

    ## hash input references for feedback ##
    my $unresolved = $args{-unresolved} || {};
    my $preset     = $args{-preset}     || {};
    my $debug      = $args{-debug};

    my $tables         = 'Original_Source,Source';
    my @fields         = ( 'Group_Concat(DISTINCT Source_ID) as Source', 'Group_Concat(DISTINCT Original_Source_ID) as Original_Source' );
    my $join_condition = "Source.FK_Original_Source__ID=Original_Source_ID";
    my %Distinct       = $dbc->Table_retrieve( $tables, \@fields, "WHERE $join_condition AND Source_ID IN ($source_id)", -debug => $debug );

    my $OSid;
    foreach my $table ('Original_Source') {
        my @diff_values = Cast_List( -list => $Distinct{$table}[0], -to => 'array' );
        if ( int(@diff_values) == 1 ) {
            $dbc->message("Common Original Source - $diff_values[0]");
            return $Distinct{$table}[0];    # common OS for all sources, return
        }

        my $list = Cast_List( -list => $Distinct{$table}[0], -to => 'string', -autoquote => 1 );

        my $id = $dbc->create_merged_data( -table => $table, -primary_list => $list, -preset => $preset, -unresolved_conflict => $unresolved, -on_conflict => $on_conflict, -debug => $debug, -test => $test );
        if ($id) {
            ## add reference to new hybrid OS ##
            $OSid = $id;
            $on_conflict->{FK_Original_Source__ID} = $id;
            $dbc->message("Creating Merged Hybrid Records for OS = $OSid");
        }
        elsif ( !$test ) {
            $dbc->warning("Failed to create merged $table");
            if ( %{$unresolved} ) {
                $dbc->warning("Unresolved conflicts remain");
                my $msg = HTML_Dump 'Unresolved', $unresolved, 'Preset', $preset, 'OC', $on_conflict;
                $dbc->debug_message($msg);
            }
        }
    }

}

#########################
# Create merged source for a list of pooling sources
#
# Usage:
#	merge_sources( -dbc => $dbc, -from_sources => $pools{$batch}{src_ids}, -unresolved => \%unresolved, -on_conflict => $on_conflicts{$batch}, -assign => \%assign_for_batch, -need_input => \%need_input, -test => 1, -debug => $debug );
#
# Return:
#	Scalar, new source ID
########################
sub merge_sources {
########################
    my %args = &filter_input( \@_, -args => 'dbc,from_sources,assign', -mandatory => 'dbc,from_sources' );
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $from_sources = $args{-from_sources};
    my $test         = $args{-test};                                                                    ## suppress messages (use this flag if calling only to retrieve conflict values first)
    my $debug        = $args{-debug};

    my $unresolved = $args{-unresolved} || {};
    my $preset     = $args{-preset}     || {};
    my $input      = $args{-need_input} || {};

    my $on_conflict = $args{-on_conflict} || {};
    my $assign      = $args{-assign}      || {};

    my $source_ids = Cast_List( -list => $from_sources, -to => 'string' );

    ## get pool configs
    ( $assign, $input, $on_conflict ) = get_pool_config( -dbc => $dbc, -assign => $assign, -input => $input, -on_conflict => $on_conflict, -ids => $source_ids );

    print HTML_Dump "assign:",      $assign      if ($debug);
    print HTML_Dump "input:",       $input       if ($debug);
    print HTML_Dump "on_conflict:", $on_conflict if ($debug);

    my $tables         = 'Original_Source,Source';
    my @fields         = ( 'Group_Concat(DISTINCT Source_ID) as Source', 'Group_Concat(DISTINCT Original_Source_ID) as Original_Source' );
    my $join_condition = "Source.FK_Original_Source__ID=Original_Source_ID";
    my %Distinct       = $dbc->Table_retrieve( $tables, \@fields, "WHERE $join_condition AND Source_ID IN ($source_ids)", -debug => $debug );

    my ( $OSid, $src_id );
    my @tables;
    if ( $assign->{FK_Original_Source__ID} ) {
        @tables = ('Source');
        $OSid   = $assign->{FK_Original_Source__ID};
    }
    else {
        @tables = ( 'Original_Source', 'Source' );
    }

    foreach my $table (@tables) {
        my $list = Cast_List( -list => $Distinct{$table}[0], -to => 'string', -autoquote => 1 );
        my @arr = split ',', $Distinct{$table}[0];

        my $id;
        if ( int(@arr) == 1 ) {
            $id = $arr[0];
        }
        else {
            $id = $dbc->create_merged_data(
                -table               => $table,
                -primary_list        => $list,
                -preset              => $preset,
                -unresolved_conflict => $unresolved,
                -on_conflict         => $on_conflict,
                -assign              => $assign,
                -need_input          => $input,
                -debug               => $debug,
                -test                => $test
            );
        }

        if ($id) {
            if ( $table eq 'Original_Source' ) {
                ## add reference to new hybrid OS ##
                $OSid = $id;
                $on_conflict->{FK_Original_Source__ID} = $id;
            }
            elsif ( $table eq 'Source' ) {
                $src_id = $id;

                ## insert sub sample type table record
                my $sub_table = get_main_Sample_Type( -dbc => $dbc, -id => $src_id, -find_table => 1 );
                if ( $dbc->table_loaded($sub_table) && $sub_table && $dbc->get_fields( -table => $sub_table, -like => 'FK_Source__ID' ) ) {
                    ## insert if not exist
                    my ($exist) = $dbc->Table_find( $sub_table, 'FK_Source__ID', "WHERE FK_Source__ID = $src_id" );
                    if ( !$exist ) {
                        my $sub_src_id = $dbc->Table_append_array(
                            -dbc       => $dbc,
                            -table     => $sub_table,
                            -fields    => ['FK_Source__ID'],
                            -values    => [$src_id],
                            -autoquote => 1
                        );
                        $dbc->message("Created new $sub_table $sub_src_id");
                    }
                }
            }
        }
        elsif ( !$test ) {
            $dbc->error("Failed to create merged $table for $source_ids");
            last;
        }
    }

    if ( %{$unresolved} && !$test ) {
        $dbc->error("Unresolved conflicts remain");
        my $msg = HTML_Dump 'Unresolved', $unresolved, 'Preset', $preset, 'OC', $on_conflict;
        $dbc->debug_message($msg);
    }
    elsif ( $src_id && !$test ) {
        $dbc->message("Creating Merged Record for Source $src_id [OS = $OSid]");
    }

    return $src_id;
}

##############################
#
# Given a source ID, find the pooled source information
# This is a recursive function and once $pooled_source returns nothing from the search the rercursion ends
#
# Input: Source_ID
# Returns: PrePooled Source_ID
#
##############################
sub getSource_IDs {
##############################

    my $self   = shift;
    my %args   = &filter_input( \@_, -args => 'dbc,source', -mandatory => 'dbc,source' );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $source = $args{-source};
    my $debug  = $args{-debug};
    my $pooled_source;
    my $parent_source;

    # checks for parent source first
    # the assumption is that this is always filled in (which it is)
    # if it isnt filled in then the record doesnt exist
    ($parent_source) = $dbc->Table_find( 'Source', 'FKOriginal_Source__ID', "WHERE Source_ID = $source" );

    #if the parent source doesnt exist, then the source doesnt exist
    if ( !$parent_source ) { $parent_source = $source; }

    # Getting the source with the earliest Recieved_Date
    ($pooled_source) = $dbc->Table_find( 'Source_Pool, Source', 'Source.Source_ID', "WHERE Source.Source_ID = Source_Pool.FKParent_Source__ID AND Source_Pool.FKChild_Source__ID = $parent_source HAVING MAX(Source.Received_Date)" );

    if ($debug) {
        print "Source: $source\n";
        print "Parent Source: $parent_source\n";
        print "Pooled Source: $pooled_source\n";
    }

    if ($pooled_source) {
        my $initial = getSource_IDs( -dbc => $dbc, -source => $pooled_source, -debug => $debug );
        $pooled_source = $initial;
    }
    else {
        $pooled_source = $parent_source;
    }

    return $pooled_source;
}

########################
# This method initializes the default source pooling configuration.
# The configs include:
#	'assign'		- pre assigned values
#	'input'			- fields that need user input
#	'on_conflict'	- values to use when on conflict
#
#
# Usage:
#	my %config = %{initialize_pool_config( -dbc => $dbc )};
#
# Return:
#	Hash reference
########################
sub initialize_pool_config {
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc' );
    my $dbc = $args{-dbc};

    ###################### default configs ######################
    #### fields and values to be assigned
    my $today   = today();
    my $user_id = $dbc->get_local('user_id');
    my ($plate_format_id)  = $dbc->Table_find( 'Plate_Format',  'Plate_Format_ID',  "WHERE Plate_Format_Type = 'Undefined - To Be Determined'" );
    my ($barcode_label_id) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_ID', "WHERE Label_Descriptive_Name = 'No Barcode'" );
    my %assigned_values    = (

        # Source
        'Source_Status'           => 'Active',
        'FK_Rack__ID'             => 10,         # in use rack
        'Received_Date'           => $today,
        'FKReceived_Employee__ID' => $user_id,
        'Source_Number'           => '',
        'FKParent_Source__ID'     => '',
        'FK_Shipment__ID'         => '',
        'Source_Created'          => $today,
        'Current_Amount'          => '',
        'Original_Amount'         => '',

        # Original_Source
        'FKCreated_Employee__ID' => $user_id,
        'Defined_Date'           => $today,
    );

    #### fields to let user choose each time
    my %user_input;
    $user_input{FK_Plate_Format__ID}{'Source'}  = 1;
    $user_input{FK_Barcode_Label__ID}{'Source'} = 1;

    #### On conflict values
    my %on_conflict_default;
    ## Source
    $on_conflict_default{FK_Original_Source__ID} = '';    # set the on_conflict value to avoid showing conflict before the merged OS id being generated
    $on_conflict_default{External_Identifier}    = '';
    $on_conflict_default{Source_Label}           = '';

    #$on_conflict_default{Amount_Units}                      = '';	# need user input if on conflict
    $on_conflict_default{Notes}              = '';
    $on_conflict_default{FKSource_Plate__ID} = '';

    #$on_conflict_default{FKReference_Project__ID}           = '';	# need user input if on conflict
    $on_conflict_default{FK_Storage_Medium__ID}             = '';
    $on_conflict_default{Xenograft}                         = '';
    $on_conflict_default{Storage_Medium_Quantity}           = '';
    $on_conflict_default{Storage_Medium_Quantity_Units}     = '';
    $on_conflict_default{Sample_Collection_Date}            = '';
    $on_conflict_default{Sample_Collection_Time}            = '';
    $on_conflict_default{FK_Sample_Type__ID}                = '';
    $on_conflict_default{FKOriginal_Source__ID}             = '';
    $on_conflict_default{Current_Concentration}             = '';
    $on_conflict_default{Current_Concentration_Units}       = '';
    $on_conflict_default{Current_Concentration_Measured_by} = '';
    $on_conflict_default{Factory_Barcode}                   = '';

    ## Original Source
    $on_conflict_default{Original_Source_Type} = 'Mixed';
    $on_conflict_default{FK_Anatomic_Site__ID} = '<Anatomic_Site_Name=Mixed>';
    $on_conflict_default{FK_Cell_Line__ID}     = '<Cell_Line_Name=Mixed>';
    $on_conflict_default{Sex}                  = 'Mixed';
    $on_conflict_default{FK_Stage__ID}         = '<Stage_Name=Mixed>';
    $on_conflict_default{Host}                 = '';
    $on_conflict_default{FK_Contact__ID}       = '<clear>';
    $on_conflict_default{Description}          = 'hybrid OS';
    $on_conflict_default{FK_Patient__ID}       = '<clear>';
    $on_conflict_default{FK_Strain__ID}        = '<Strain_Name=Mixed>';
    $on_conflict_default{Disease_Status}       = 'Mixed';
    $on_conflict_default{FK_Pathology__ID}     = '';
    $on_conflict_default{Pathology_Type}       = '<clear>';
    $on_conflict_default{Pathology_Grade}      = '<distinct concat>';
    $on_conflict_default{Pathology_Stage}      = '<clear>';
    $on_conflict_default{Invasive}             = '<clear>';
    $on_conflict_default{Pathology_Occurrence} = 'Unspecified';

    my %pool_config = (
        'assign'      => \%assigned_values,
        'input'       => \%user_input,
        'on_conflict' => \%on_conflict_default,
    );
    return \%pool_config;
}

########################
# This method retrieves the source pooling configuration. It merges the custom config with the default config.
# The configs include:
#	'assign'		- pre assigned values
#	'input'			- fields that need user input
#	'on_conflict'	- values to use when on conflict
#
#
# Usage:
#
#	( $assign, $input, $on_conflict ) = get_pool_config( -dbc => $dbc, -assign => $assign, -input => $input, -on_conflict => $on_conflict, -ids => '123,456,789' );
#
# Return:
#	Array of hash references.
########################
sub get_pool_config {
    my %args        = &filter_input( \@_, -args => 'dbc,assign,input,on_conflict', -mandatory => 'dbc' );
    my $dbc         = $args{-dbc};
    my $assign      = $args{-assign} || {};                                                                 # hash ref, keep the merged infor in this ref
    my $input       = $args{-input} || {};                                                                  # hash ref, keep the merged infor in this ref
    my $on_conflict = $args{-on_conflict} || {};                                                            # hash ref, keep the merged infor in this ref
    my $source_ids  = $args{-ids};

    ## get default pool configs
    my $pool_config_default = initialize_pool_config( -dbc => $dbc );

    ################### merge custom config with default config ######################
    ## merge fields need user input
    if ( $pool_config_default && $pool_config_default->{input} ) {
        foreach my $key ( keys %{ $pool_config_default->{input} } ) {
            unless ( $assign && defined $assign->{$key} ) {                                                 # if a default input field has custom assigned value, then user input is not needed
                $input->{$key} = $pool_config_default->{input}{$key};
            }
        }
    }

    ## merge fields and values to be assigned
    if ( $pool_config_default && $pool_config_default->{assign} ) {
        foreach my $key ( keys %{ $pool_config_default->{assign} } ) {
            if ( !defined $assign->{$key} && !defined $input->{$key} ) {                                    # Do not override the custom assigned values, and do not assign default value if this field is specified as custom input
                $assign->{$key} = $pool_config_default->{assign}{$key};
            }
        }
    }

    ## merge on conflict
    if ( $pool_config_default && $pool_config_default->{on_conflict} ) {
        foreach my $key ( keys %{ $pool_config_default->{on_conflict} } ) {
            if ( !defined $on_conflict->{$key} ) {
                $on_conflict->{$key} = $pool_config_default->{on_conflict}{$key};
            }
        }
    }

    # determine sample type for the pooled source if source ids are given
    if ($source_ids) {
        my $pooled_type = get_pooled_sample_type( -dbc => $dbc, -sources => $source_ids );
        my ($pooled_sample_type_id) = $dbc->Table_find( "Sample_Type", "Sample_Type_ID", "WHERE Sample_Type = '$pooled_type'" );
        $assign->{FK_Sample_Type__ID} = $pooled_sample_type_id;
    }

    return ( $assign, $input, $on_conflict );
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
