###############################################################################
# Barcoding.pm
#
# These extra functions are added for Standard Laboratory Barcoding
#
#  Tubes are essentially ligation tubes with DNA
#   as well as Agar Plates ('Plated') prior to distribution onto plates
#
################################################################################
# $Id: Barcoding.pm,v 1.96 2004/12/01 18:28:54 jsantos Exp $
################################################################################
# CVS Revision: $Revision: 1.96 $
#     CVS Date: $Date: 2004/12/01 18:28:54 $
################################################################################
package alDente::Barcoding;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Barcoding.pm - These extra functions are added for Standard Laboratory Barcoding

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
These extra functions are added for Standard Laboratory Barcoding<BR>Tubes are essentially ligation tubes with DNA <BR>as well as Agar Plates ('Plated') prior to distribution onto plates<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    barcode_options
    PrintBarcode
    equipment_barcode
    tube_barcode
    employee_barcode
    solution_barcode
    rack_barcode
    box_barcode
    print_multiple_barcode
    print_multiple_plate
    print_barcode
    print_slot_barcodes
    barcode_text
    print_custom_barcode
    get_printer_DPI
    PrintBarcode
);

##############################
# standard_modules_ref       #
##############################

use strict;
use Data::Dumper;
use CGI qw(:standard);
use Barcode::Code128;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::HTML;
use RGTools::RGIO;

use RGTools::Conversion;

use alDente::Barcode;
use alDente::Form;
use alDente::SDB_Defaults;
use alDente::Tray;
use alDente::Rack;
use alDente::CGI_App;
use alDente::Barcode_Views;

# use LampLite::CGI;
##############################
# global_vars                #
##############################
use vars qw($testing $dbase $development $scanner_mode %Settings %User_Setting %Department_Settings %Defaults %Login $current_plates);

my $q = new CGI;
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
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################


##################################
sub Barcode_Home {
##################################
    my %args = &filter_input( \@_, -args => 'label,default' );
    my $label_name = $args{-label}   || param('Label Name');
    my $default    = $args{-default} || 'Pre-configured Labels';
    my $dbc        = $args{-dbc} ;

    my $condition;    # = " AND Barcode_Label_Name = '$label_name'" if ($label_name);

    my %page_layers;
    $page_layers{'Printer Assignment'} = '<HR>Printer Assignment by Group<HR>';

    my $extra_pa_condition;
    my $pg = $dbc->session->{printer_group} if defined $dbc->session->{printer_group};
    if ($pg) {
        $page_layers{'Printer Assignment'} .= "(Your Printer Group is <B>$pg</B>)<P>";
        $page_layers{'Printer Assignment'} .= "(To change printer groups, return to login page;  To change printer group printers please see LIMS Admin)<P>";
    }

    $page_layers{'Printer Assignment'} .= $dbc->Table_retrieve_display(
        'Printer_Assignment,Printer,Printer_Group', [ 'Printer_Group_Name', 'Printer_Assignment.FK_Label_Format__ID as Label_Type', 'FK_Printer__ID as Printer' ],
        "WHERE FK_Printer__ID=Printer_ID and FK_Printer_Group__ID=Printer_Group_ID",
        -toggle_on_column => 1,
        -return_html      => 1,
        -highlight_string => $pg,
        -title            => "$pg Printer Groups"
    );

    my %layer;

    my @labels = $dbc->Table_find( 'Barcode_Label,Label_Format', 'Barcode_Label_Name,Label_Format_Name,Label_Descriptive_Name', "WHERE FK_Label_Format__ID=Label_Format_ID $condition" );
    foreach my $label ( sort @labels ) {
        my ( $label_name, $label_format, $desc ) = split ',', $label;
        if ( $label_name ne 'laser' ) {
            my $page = barcode_label_form( $label_name, -preview => 1, -dbc => $dbc );
            $layer{$label_format} .= create_tree( -tree => { "$label_name" => "<h2>$label_name: $desc</h2>" . $page } );
        }
    }

    $page_layers{'Pre-configured Labels'} = create_tree( -tree => \%layer );

    #    $page_layers{'Custom Barcode'} = '<HR>Custom Text-only Label Generation<HR>';
    $page_layers{'Custom Labels (large)'} .= print_custom_barcodes( -dbc => $dbc, -type => 'large' );
    $page_layers{'Custom Labels (small)'} .= print_custom_barcodes( -dbc => $dbc, -type => 'small' );
    $page_layers{'Custom Labels (2D)'}    .= print_custom_barcodes( -dbc => $dbc, -type => '2D' );

    #    $page_layers{'Custom Barcode'} .= '<HR>Custom Text + Barcode Label Generation<HR>';
    #    $page_layers{'Custom Barcode'} .= &build_custom_barcode(-dbc=>$dbc, -type=>'label1');

    my $output = "<h1>Barcode Home Page</H1>";
    $output .= define_Layers( -layers => \%page_layers, -default => $default, -return_html => 1 );
    return $output;
}

##############################
sub request_broker {
##############################
    my %args = filter_input(\@_, -args=>'dbc,event');
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $event = $args{-event};

    if ( $event eq 'Print Text Label' ) {

        my $text = param('Text Label');
        &alDente::Barcoding::PrintBarcode( $dbc, 'Text', $text );
        return 0;
    }
    elsif ( $event eq 'Print Simple Large Label' ) {

        my $repeat = param('RepeatX') || 1;
        my $field1 = param('Field1');
        my $field2 = param('Field2');
        my $field3 = param('Field3');
        my $field4 = param('Field4');
        my $field5 = param('Field5');
        for ( my $i = 1; $i <= $repeat; $i++ ) { print_simple_large_label( -labels=>[$field1, $field2, $field3, $field4, $field5], -dbc=>$dbc); }
    }
    elsif ( $event eq 'Print Simple Small Label' ) {

        my $repeat = param('RepeatX') || 1;
        my $field1 = param('Field1');
        my $field2 = param('Field2');
        for ( my $i = 1; $i <= $repeat; $i++ ) { &print_simple_small_label( -labels=>[$field1, $field2], -dbc=>$dbc ) }
    }
    elsif ( $event eq 'Print Simple Tube Label' ) {

        my $repeat = param('RepeatX') || 1;
        my $field1 = param('Field1');
        my $field2 = param('Field2');
        my $field3 = param('Field3');
        my $field4 = param('Field4');
        my $field5 = param('Field5');
        for ( my $i = 1; $i <= $repeat; $i++ ) { &print_simple_tube_label( -labels=>[$field1, $field2, $field3, $field4, $field5], -dbc=>$dbc ); }
    }
    elsif ( $event eq 'Print Slot Barcodes' ) {
        my $max_row = param('Max_Row');
        my $max_col = param('Max_Col');
        my $scale   = param('Scale');
        my $height  = param('Height');
        my $vspace  = param('Vspace');

        &print_slot_barcodes( -max_row => $max_row, -max_col => $max_col, -scale => $scale, -height => $height, -vspace => $vspace, -dbc=>$dbc);
    }
    elsif ( $event eq 'Re-Print Source Barcode' ) {
        my $table          = param('table')        || 'Source';
        my $id             = param('id')           || param('Source ID') || param('Source_ID') || param('src_id');
        my $selected_label = param('Barcode Name') || param('FK_Barcode_Label__ID');
        $dbc->message("\nReprinting: $table($id) $selected_label barcode.");
        PrintBarcode( $dbc, $table, $id );
        unless ( $id =~ /,/ ) {
            my $sourceObject = alDente::Source->new( -dbc => $dbc, -id => $id );
            $dbc->session->reset_homepage("Source=$id");
#            $sourceObject->home_page();
        }
        return;
    }
    elsif ( $event =~ /^Re-Print Solution (Label|Barcode)/i ) {

        my $note = param('Mark Note');
        my $marked_solutions = join ',', param('Mark');
        my $scanned;
        if ( param('Solutions') ) {
            $scanned = join ',', param('Solutions');
        }
        elsif ( param('Solution_ID') ) {
            $scanned = join ',', param('Solution_ID');
        }
        elsif ( param('Solution ID') ) {
            $scanned = join ',', param('Solution ID');
        }
        $marked_solutions ||= get_aldente_id( $dbc, $scanned, 'Solution' );
        if ( $marked_solutions =~ /[1-9]/ ) {
            $dbc->message("\nReprinting: $marked_solutions ($note)");
            &PrintBarcode( $dbc, 'Solution', $marked_solutions );
        }
        else { $dbc->warning("Nothing to print"); }
        return 0;
    }
    ###### Barcoding options ###############################
    elsif ( $event eq 'Re-Print Box Barcode' ) {

        #    print h3("print $barcode.");
        my $box_id = param('Box ID') || param('Box_ID');
        &alDente::Barcoding::PrintBarcode( $dbc, 'Box', $box_id );
        return 0;
    }
    elsif ( $event eq 'Re-Print Rack Barcode' ) {
        my $rack_id = param('Rack ID') || param('Rack_ID');
        &alDente::Barcoding::PrintBarcode( $dbc, 'Rack', $rack_id );
        return 0;
    }
    elsif ( $event eq 'Re-Print Small Rack Barcode' ) {

        my $rack_id = param('Rack ID') || param('Rack_ID');
        &alDente::Barcoding::PrintBarcode( $dbc, 'Rack', $rack_id, 'small' );
        return 0;
    }
    elsif ( $event eq 'Re-Print Equipment Barcode' ) {

        my $equip = param('Equipment') || param('Equipment ID') || param('Equipment_ID') || $equipment_id;

        #    print h3("print Equ$equip.");
        &alDente::Barcoding::PrintBarcode( $dbc, 'Equipment', $equip );
        return 0;
    }
    elsif ( $event eq 'Re-Print Employee Barcode' ) {

        my $barcodes = get_Table_Param( -table => 'Employee', -field => 'Employee_ID', -dbc => $dbc );
        &alDente::Barcoding::PrintBarcode( $dbc, 'Employee', $barcodes );
        return 0;
    }
    elsif ( $event eq 'Re-Print Sample Barcode' ) {

        my $barcodes = param('Sample') || param('Sample_ID');
        &alDente::Barcoding::PrintBarcode( $dbc, 'Sample', $barcodes );
        return 0;
    }
    elsif ( $event =~ /Re-Print (Plate|Container) Barcode/ ) {
        my $plate_id = param('Plate ID') || param('Plate_ID');

        my $prefix = $dbc->barcode_prefix('Plate');
        my $barcode;

        if ($plate_id) {
            $barcode = "$prefix$plate_id";
            $barcode =~ s/\,/$prefix/g;
        }

        $current_plates ||= param('Plate_IDs');
        if ( $current_plates =~ /^\d+/ ) {
            $barcode = $prefix . $current_plates;
            $barcode =~ s/\,/$prefix/g;
        }
        if ( param('FK_Plate__ID') ) {
            my @plates = param('FK_Plate__ID');
            map { $_ = $prefix . $_ if $_ !~ /$prefix/i } @plates;
            $barcode = join '', @plates;
        }

        my @ids = split $prefix, $barcode;
        
        # remove first (blank) ID
        shift(@ids);

        my %barcode_list;
        my $i           = 0;
        my $skip_prompt = 'Y';

        #check if plate ids all belong to the same tray and if they are the full set
        my $is_full_tray = 0;
        my $tray_id;
        foreach my $id (@ids) {
            $tray_id = &alDente::Tray::exists_on_tray( $dbc, 'Plate', $id );
            if ($tray_id) { last; }
        }

        if ( defined $tray_id ) {
            my @plate_set = $dbc->Table_find_array( 'Plate_Tray', ['FK_Plate__ID'], "WHERE FK_Tray__ID=$tray_id" );
            my ( $intersec, $a_only, $b_only ) = &RGmath::intersection( \@ids, \@plate_set );

            if ( (@$b_only) && defined( $b_only->[0] ) ) {
                $is_full_tray = 0;
            }
            else {
                $is_full_tray = 1;
            }
        }

        foreach my $id (@ids) {
            my $to_print = '';
            if ( ($is_full_tray) && ( my $tray_id = &alDente::Tray::exists_on_tray( $dbc, 'Plate', $id ) ) ) {
                $to_print = "tra${tray_id}";
                unless ( defined $barcode_list{$to_print} ) {
                    my ($plate_type) = $dbc->Table_find( "Plate", "Plate_Type", "WHERE Plate_ID = $id" );
                    if ( $i == 0 ) {
                        $i = 1;
                        &alDente::Barcoding::PrintBarcode( $dbc, 'Tray', $id, "print, $plate_type" );
                    }
                    else { &alDente::Barcoding::PrintBarcode( $dbc, 'Tray', $id, "print, $plate_type", $skip_prompt ); }
                }
            }
            else {

                $to_print = "$prefix${id}";
                unless ( defined $barcode_list{$to_print} ) {
                    &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $id );
                }
            }
            $barcode_list{"$to_print"} = 1;
        }

        unless ( param('FK_Plate__ID') ) {
            &alDente::Info::info( $dbc, $barcode );
        }
    }
    elsif ( $event =~ /Re-Print (Plate|Container) Labels/ ) {

        my $note = param('Mark Note');
        my $marked_plates = join ',', param('Mark');
        $dbc->message("\nReprinting: $marked_plates ($note)");
        &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $marked_plates );
        return 0;
    }
    elsif ( $event eq 'Re-Print Microarray Barcode' ) {

        my $id = param('id');
        $dbc->message("\nReprinting: Microarray($id) barcode.");
        &alDente::Barcoding::PrintBarcode( $dbc, "Microarray", $id );
        my $mo = alDente::Microarray->new( -dbc => $dbc, -id => $id );
#        $dbc->session->reset_homepage("MicroArray=$id")
        $mo->home_page();
    }
    elsif ( $event =~ /Preview Customized Barcode/ ) {

        my $label_name = param('Label Name');
        my $frozen     = param('Frozen Barcode');
        my $output     = print_custom_barcode( -preview => 1, -frozen => $frozen, -dbc=>$dbc);
        $output .= hr . barcode_label_form( $label_name, -dbc => $dbc ) if $label_name;
        print $output;

        print Barcode_Home();
    }
    elsif ( $event =~ /Print Customized Barcode/ ) {
        my $frozen = param('Frozen Barcode');
        print_custom_barcode( -frozen => $frozen , -dbc=>$dbc);
        print Barcode_Home(-dbc=>$dbc);
        return 1;
    }
    elsif ( $event =~ /Build Customized Barcode/ ) {
        my $frozen = param('Frozen Barcode');
        my $type   = param('Label Name');
        print build_custom_barcode( -dbc => $dbc, -type => $type, -frozen => $frozen );
        return 1;
    }
    elsif ( $event eq 'Print Customized Barcode' ) {

    }
    elsif ( $event eq 'Print Custom Barcode' ) {

        my $text    = param('Header Text');
        my $subtext = param('Small Text');
        my $value   = param('Barcode Value');
        my $type    = param('Barcode Type');
        $type = 'micropdf417' if ( $type eq 'Micro PDF417' );
        $type = 'qrcodebar'   if ( $type eq 'QR Code Bar' );

        &alDente::Barcoding::print_custom_barcode( -text => $text, -subtext => $subtext, -value => $value, -type => $type , -dbc=>$dbc);
        &alDente::Web::GoHome( $dbc, "LIMS Admin" );
    }
    elsif ( $event eq 'Home' ) {
        print Barcode_Home( -dbc => $dbc );
        return 1;
    }
    else {
        $dbc->message("Error: Event ($event) not recognized");
        print Barcode_Home(-dbc=>$dbc);
        return 1;
    }
}

########################
# Retrieves list of barcode labelling options (based upon configuration file)
#  (generally used for populating popdown menu with applicable options)
#
# Return: ARRAY of label names (FK_info for Barcode_Label_ID)
########################
sub barcode_options {
########################
    my %args       = filter_input( \@_, -args => 'stock_type' );
    my $stock_type = $args{-stock_type};
    my $dbc        = $args{-dbc};

    my @options;
    if ( $stock_type =~ /(reagent|solution)/i ) {
        @options = $dbc->get_FK_info( 'FK_Barcode_Label__ID', -condition => "WHERE Label_Descriptive_Name like '%Solution%'", -list => 1 );
    }
    else {
        @options = $dbc->get_FK_info( 'FK_Barcode_Label__ID', -list => 1 );
    }
    return \@options;
}

#####################################################
# Method handling all barcode printing requests.
#
# This simply figures out what you are trying to print and calls the appropriate method
#
######################
sub PrintBarcode {
######################
    my %args = filter_input( \@_, -args => 'dbc,table,id,option,skip_prompt,barcode_label' );
    my $dbc           = $args{-dbc} ;
    my $table         = $args{-table};
    my $id            = $args{-id};
    my $option        = $args{-option};                                                                  ## allow multiple copies..
    my $skip_prompt   = $args{-skip_prompt};
    my $barcode_label = $args{-barcode_label};                                                           ## Barcode Label Name      ONLY DONE FOR SOLUTION
    my $count         = $args{-count};                                                                   ## Count of Same Barcode   ONLY DONE FOR SOLUTION

    if ( $table =~ /^Multiple_Plate$/ && $id =~ /[1-9a-zA-Z,]/ ) {
        &print_multiple_plate( $dbc, $id );
        return 1;
    }

    unless ( $id =~ /[1-9a-zA-Z]/ ) { print "No ID to print ($table - $id) <BR>"; Call_Stack(); return 0; }
    
    if ( $table =~ /Equipment/ ) {
        equipment_barcode( -id=>$id, -option=>$option, -dbc => $dbc );
    }
    elsif ( $table =~ /Solution/ ) {
        solution_barcode( -dbc => $dbc, -id => $id, -option => $option, -barcode_label => $barcode_label, -count => $count );
    }
    elsif ( $table =~ /Employee/ ) {
        employee_barcode( $id, -dbc => $dbc );
    }
    elsif ( $table =~ /Tray/ ) {
        #### generates record in MultiPlate_Barcode...
        my $reprint = ( $option =~ /print/i );
        my $pack    = ( $option =~ /pack/i );
        my $type;
        $type
            = $option =~ /Library_Plate/i ? 'Library_Plate'
            : $option =~ /Tube/i          ? 'Tube'
            : $option =~ /Array/i         ? 'Array'
            :                               undef;
        unless ($type) {
            $dbc->message("Error: Invalid type!");
            return 0;
        }

        &tray_barcode( $id, $reprint, $pack, $type, $skip_prompt, -dbc=>$dbc);
    }
    elsif ( $table =~ /Plate/ ) {

        #	print "Single Barcode..";
        &plate_barcode( $id, $option, -dbc => $dbc );
    }
    elsif ( $table =~ /Tube/ ) {
        &tube_barcode( $id, $option, -dbc => $dbc );
    }
    elsif ( $table =~ /Box/ ) {
        &box_barcode( $id, $option, -dbc => $dbc );
    }
    elsif ( $table =~ /Rack/ ) {
        &rack_barcode( -rack_id => $id, -option => $option, -dbc=>$dbc );
    }
    elsif ( $table =~ /Text/ ) {
        &barcode_text($id, -dbc=>$dbc);
    }
    elsif ( $table =~ /Multiple/ ) {
        ### prints current record in MultiPlate_Barcode
        &print_multiple_barcode( $id, $option , -dbc=>$dbc);
    }
    elsif ( $table =~ /Sample/ ) {
        &sample_barcode( $id, $option, -dbc => $dbc );
    }
    elsif ( $table =~ /Source/ ) {
        &source_barcode( $id, -dbc => $dbc );
    }
    elsif ( $table =~ /^GelRun$/ ) {
        &gelrun_barcode( $id, -dbc => $dbc );
    }
    elsif ( $table =~ /^Run$/ ) {
        &run_barcode( $id, -dbc => $dbc );
    }
    elsif ( $table =~ /^Microarray$/ ) {
        &microarray_barcode( $id, $option, -dbc=>$dbc );
    }
    elsif ( $table =~ /^SOLID$/ ) {
        &solidrun_barcode( $id, -dbc => $dbc );
    }
    elsif ( $table =~ /^EGel_Run$/ ) {
        &Egel_run_barcode( $id, -dbc => $dbc );
    }
    elsif ( $table =~ /^AATI_Run_Batch$/ ) {
        &AATI_run_batch_barcode( $id, -dbc => $dbc );
    }
    else { $dbc->message("Unrecognized table for PrintBarcode routine"); }

    return 1;
}

############################
## Specific barcode types ##
############################

############################
sub equipment_barcode {
############################
    #
    #  Print Barcode for equipment
    #
    my %args = filter_input( \@_, -args => 'id,option' );
    my $id   = $args{-id};
    my $option        = $args{-option};   
    my $dbc  = $args{-dbc};

    my $Eid = get_aldente_id( $dbc, $id, 'Equipment' );
    $id = sprintf "%8.0d", $Eid;
    $id =~ s/ /0/g;

    my %Info;
    if ( $Eid =~ /[1-9]/ ) {
        %Info = $dbc->Table_retrieve(
            'Equipment,Stock,Barcode_Label,Stock_Catalog,Equipment_Category',
            [ 'Equipment_ID', 'Equipment_Name', 'Stock_Catalog.Model', 'Category', 'Barcode_Label_Name' ],
            "where FK_Barcode_Label__ID=Barcode_Label_ID AND FK_Stock__ID=Stock_ID AND Equipment_ID in ($Eid) AND Stock.FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID"
        );
    }
    else { Message("Invalid Equipment_ID ($Eid ?)"); }

    my $index = 0;
    my $barcode;
    while ( defined $Info{Equipment_Name}[$index] ) {
        my $id         = $Info{Equipment_ID}[$index];
        my $equip      = $Info{Equipment_Name}[$index];
        my $model      = $Info{'Stock_Catalog.Model'}[$index];
        my $etype      = $Info{Category}[$index];
        my $label_type = $Info{Barcode_Label_Name}[$index];

        if   ($equip) { $dbc->message("Printing Barcode for $equip $etype"); }
        else          { $dbc->message("Please update Equipment Name,Model,Serial # Now"); return; }
        
        my $prefix = $dbc->barcode_prefix('Equipment');
        $barcode = alDente::Barcode->new( -type => $label_type, -dbc=>$dbc);
        $barcode->set_fields(
            (   'class'   => $prefix,
                'id'      => $id,
                'style'   => "code128",
                'barcode' => "$prefix$id",
                'text'    => "$equip $etype",
            )
        );
         
        $barcode->print();
        $index++;
    }
    
    $barcode->reprint_option( 'Equipment', $Eid, -dbc => $dbc );
    return;
}

############################
sub barcode_label_form {
############################
    my %args       = &filter_input( \@_, -args => 'label', -mandatory => 'label' );
    my $label      = $args{-label};
    my $parameters = $args{-parameters};
    my $preview    = $args{-preview};
    my $dbc        = $args{-dbc};

    my $homelink = $dbc->homelink();

    my $label_details = join ',',
        $dbc->Table_find( 'Barcode_Label,Label_Format', 'Barcode_Label_Name,Barcode_Label_Type,Label_Descriptive_Name,Label_Format_Name,Label_Format_ID', "WHERE FK_Label_Format__ID=Label_Format_ID AND Barcode_Label_Name = '$label'" );

    unless ($label_details) {
        Message("Details not found for $label type");
        return 0;
    }

    my ( $label_name, $label_type, $desc, $label_format, $label_id ) = split ',', $label_details;
    my $page = alDente::Form::start_alDente_form( $dbc, 'Print $label_type', $homelink, $parameters );

    my $Table = HTML_Table->new( -title => "$label_type Barcode ($label_name)", -nolink => 1 );
    $Table->Set_Headers( [ 'label', 'value', 'format', 'posx', 'posy', 'size', 'style', 'example' ] );
    my $bc = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc );

    my $barcode_config;
    my @attributes = ( 'height', 'width', 'scale_DPI', 'zero_x', 'zero_y', 'lab_top' );    ## retrieve these attributes from the defined label type definition ##
    foreach my $attribute (@attributes) {
        my $attribute_value = $bc->get_attribute($attribute);
        $page .= hidden( -name => $attribute, -value => $attribute_value );
        $barcode_config->{$attribute} = $attribute_value;
    }

    my %fields;
    foreach my $field ( sort keys %{ $bc->{fields} } ) {
        push @{ $fields{$field} }, "";
        my $sample = $bc->{fields}{$field}{'sample'};
        $Table->Set_Row(
            [   hidden( -name => "label.name", -value => $field, -force => 1 ) . $field,
                textfield( -name => "label.value", -size => 10, -default => '', -force => 1 ),
                $bc->{fields}{$field}{'format'},
                textfield( -name => "label.posx",   -default => $bc->{fields}{$field}{'posx'},  -force => 1 ),
                textfield( -name => "label.posy",   -default => $bc->{fields}{$field}{'posy'},  -force => 1 ),
                textfield( -name => "label.size",   -default => $bc->{fields}{$field}{'size'},  -force => 1 ),
                textfield( -name => "label.style",  -default => $bc->{fields}{$field}{'style'}, -force => 1 ),
                hidden( -name    => "label.sample", -value   => $sample ) . $sample
            ]
        );
        $barcode_config->{$field} = $bc->{fields}{$field};
    }

    $barcode_config->{label_format_id} = $label_id;
    my $xls_settings;
    my $frozen_barcode = Safe_Freeze( -value => $barcode_config, -format => 'array', -encode => 1, -max_length => 10000 );
    $xls_settings->{config}{"Type"}           = $label_name;
    $xls_settings->{config}{"Frozen Barcode"} = $frozen_barcode->[0];

    my @printers = $dbc->get_FK_info( 'FK_Printer__ID', -list => 1, -condition => "FK_Label_Format__ID=$label_id" );    #'Printer_Name',"WHERE Printer_Type = '$label_format'",-distinct=>1);
    $Table->Set_Row(
        [   "Printer",
            RGTools::Web_Form::Popup_Menu(
                name    => 'Printer',
                values  => [ '', @printers ],
                force   => 1,
                width   => 200,
                default => ''
            )
        ]
    );
    $page .= $Table->Printout(0) . set_validator( 'Printer', -mandatory => 1 );
    $page .= submit( -name => 'Barcode_Event', -value => "Preview Customized Barcode", -class => "Std" );
    $page .= &vspace();
    $page .= submit( -name => 'Barcode_Event', -value => "Print Customized Barcode", -class => "Action", -onClick => 'return validateForm(this.form)' );
    $page .= hspace(5) . "RepeatX  " . textfield( -name => 'RepeatX', default => '', -force => 1, -size => 5 );
    $page .= &vspace(5) . checkbox( -name => 'Use Sample Labels' );
    $page .= hidden( -name => 'Label Name', -value => $label_name );

    #<CONSTRUCTION> Just using excel link for now because the buttons above are not in CGI_APP so need to rewritten codes above first
    my $excel_download_upload = alDente::Barcode_Views::excel_download_upload( -dbc => $dbc, -type => $label_name, -fields => \%fields, -xls_settings => $xls_settings, -excel_link => 1 );

    #my $excel_download_upload = alDente::Barcode_Views::excel_download_upload( -dbc => $dbc, -type=>$label_name, -fields=>\%fields, -xls_settings=>$xls_settings );
    $page .= $excel_download_upload;
    $page .= end_form();

    if ($preview) {
        my $img = "<IMG SRC='/$URL_dir_name/images/png/$label_name.png'/>";
        $img .= " <- <i>Note: text does not exactly align as barcodes printed, but overall layout is accurate</i>";

        $page = $img . '<p ></p>' . $page;
    }

    return $page;
}

#######################
sub plate_barcode {
#######################
    #
    # Note this routine differs in that it prints GROUPS of plates
    #
    my %args   = filter_input( \@_, -args => 'id,option' );
    my $id     = $args{-id};                                  # barcode or list of plate IDs
    my $option = $args{-option};                              ## allow option of printing large or small barcodes (overrides default)

    my $dbc = $args{-dbc};

    $id = get_aldente_id( $dbc, $id, 'Plate' );
    my @ids = split ',', $id;

    my $prefix = $dbc->barcode_prefix('Plate');

    #Message("Printing Container Barcodes");
    my $noscale = '';
    foreach my $thisid (@ids) {

        #	Message("Printing Barcode for Plate $thisid.");
        #	print h3("(currently in Bio-informatics room)");

        my $info = join ',',
            $dbc->Table_find(
            'Employee,Plate_Format,Plate LEFT JOIN Pipeline ON FK_Pipeline__ID=Pipeline_ID',
            'FK_Library__Name,Plate_Number,Parent_Quadrant,Plate_Created,Initials,Plate_Format_Type,left(Pipeline_Code,3),FK_Branch__Code,Plate_Label',
            "where FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID=$thisid and Employee_ID=FK_Employee__ID"
            );
        Test_Message( "INFO:" . $info, $testing );

        my ( $libname, $pnum, $quad, $thisdate, $init, $format, $pipeline_code, $b_code, $plate_label ) = split ',', $info;
        $thisdate = convert_date($thisdate);
        $pipeline_code =~ /(\w)(\w+)/;
        my $p_code  = $1 || '_';
        my $p2_code = $2 || '_';

        # check if the format is virtual. If it's virtual, fail out
        if ( $format =~ /virtual/i ) {
            $dbc->message("Printing Virtual Plate (For reference purposes only)");
            &print_simple_large_label( "Plate ID: $id", "$libname-$pnum$quad", $init, $thisdate, "$format $p_code$p2_code" );
            return;
        }

        ( my $thisday, my $thistime ) = split / /, $thisdate;

        if ( $quad eq 'NULL' ) { $quad = ' '; }
        $quad ||= " ";

        my $thislib = $libname . "-" . $pnum;
        $thisday =~ /\d\d(\d\d)-(\d\d)-(\d\d)/;

        #	$fday = $1.$2.$3;

        #	if ($Login{dbase} =~ /Test|Dev/i) {$p_code = "T";}  ### distinguish TEST plate barcodes..

        my $label_name = "";

        if ( $option =~ /small/ ) {
            $label_name = 'seqnightcult_s';
        }
        elsif ( $option =~ /large/ ) {
            $label_name = 'seqnightcult';
        }
        else {
            my $condition = "where FK_Barcode_Label__ID=Barcode_Label_ID AND Plate_Format_Type like '$format'";
            $condition .= " AND FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID = $thisid";
            ($label_name) = $dbc->Table_find( 'Plate,Plate_Format,Barcode_Label', 'Barcode_Label_Name', $condition );
        }

        ## parameter override
        my $barcode_type_label = param("Barcode Name");
        if ( $barcode_type_label && $barcode_type_label !~ /Select/ ) {
            ($label_name) = $dbc->Table_find( "Barcode_Label", "CASE WHEN Barcode_Label_Status = 'Active' THEN Barcode_Label_Name ELSE 'no_barcode' END", "WHERE Label_Descriptive_Name='$barcode_type_label'" );
        }
        ## <CONSTRUCTION>
        if ( $label_name =~ /seqnightcult_s/ ) {
            $thislib .= $quad;
            $plate_label = substr( $plate_label, 0, 3 );
        }

        if ( $thisday =~ /\d\d(\d\d-\d\d-\d\d)/ ) { $thisday = $1; }    ## shorten day format...

        my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc);

        # check to see if this is a tube barcode
        #        if ( $label_name =~ /no_barcode/i ) {
        #            $dbc->warning("Printing is turned off for $barcode_type_label labels");
        #            ## do not print
        #            next;
        #        }

        if ( $label_name =~ /ge_tube_barcode/ ) {
            my $barcode_type = 'datamatrix';
            if ( $label_name =~ /1D/ ) {
                $barcode_type = 'code128';
            }
            my @tube_info = $dbc->Table_find( "Plate", "CASE WHEN length(Plate_Parent_Well) > 0 THEN concat(Parent_Quadrant,'_',Plate_Parent_Well) ELSE '' END AS Quadwell,FKParent_Plate__ID,Plate_Parent_Well", "WHERE Plate_ID=$thisid" );
            my ( $quadwell, $parent, $well ) = split ',', $tube_info[0];

            # get the first original source
            my ($original_source_name) = $dbc->Table_find( "Plate,Plate_Sample,Sample,Source,Original_Source",
                "Original_Source_Name", "WHERE Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID AND FK_Sample__ID=Sample_ID AND FK_Source__ID=Source_ID AND FK_Original_Source__ID=Original_Source_ID AND Plate_ID=$thisid" );
            unless ($original_source_name) {
                ($original_source_name) = $dbc->Table_find( 'Plate,Library,Original_Source', "Original_source_Name", "WHERE Plate_ID = $thisid  AND Library_Name = FK_Library__Name and FK_Original_Source__ID = Original_Source_ID" );
            }

            # truncate if > 10 chars
            if ( length($original_source_name) > 10 ) {
                $original_source_name = substr( $original_source_name, 0, 10 );
            }
            my $print_plate_label = "";
            $print_plate_label = "'$plate_label'" if $plate_label;
            $barcode->set_fields(
                (   'class'         => $prefix,
                    'id'            => $thisid,
                    'style'         => $barcode_type,
                    'barcode'       => "$prefix$thisid",
                    'plateid'       => $thislib,
                    'quad'          => $quad,
                    'p_code'        => $p_code,
                    'p2_code'       => $p2_code,
                    'b_code'        => $b_code,
                    'date'          => $thisday,
                    'init'          => $init,
                    'quadwell'      => $quadwell,
                    'quadwell_tube' => $quadwell,
                    'plateid_tube'  => $thislib,
                    'init_tube'     => $init,
                    'class_tube'    => $prefix,
                    'id_tube'       => $thisid,
                    'ors_name'      => $original_source_name,
                    'label'         => $print_plate_label,
                    'label_tube'    => $print_plate_label
                )
            );
            $noscale = 'noscale';
        }
        elsif ( $label_name =~ /agar_plate/ ) {

            my @agar_info = $dbc->Table_find( "Plate", "CASE WHEN length(Plate_Parent_Well) > 0 THEN concat(Parent_Quadrant,'_',Plate_Parent_Well) ELSE '' END AS Quadwell,FKParent_Plate__ID,Plate_Parent_Well", "WHERE Plate_ID=$thisid" );
            my ( $quadwell, $parent, $well ) = split ',', $agar_info[0];

            my %ancestry = &alDente::Container::get_Parents( -id => $parent, -well => $well, -dbc => $dbc );
            my $sample_id = $ancestry{sample_id};
            unless ($sample_id) {
                $sample_id = '';
            }

            # if agar barcode, include Plate_Parent_Well and sample id
            $barcode->set_fields(
                (   'class'    => $prefix,
                    'id'       => $thisid,
                    'style'    => "code128",
                    'barcode'  => "$prefix$thisid",
                    'plateid'  => $thislib,
                    'quadwell' => $quadwell,
                    'sample'   => $sample_id,
                    'p_code'   => $p_code,
                    'p2_code'  => $p2_code,
                    'b_code'   => $b_code,
                    'date'     => $thisday,
                    'init'     => $init,
                )
            );
        }
        elsif ( $label_name =~ /custom_2D/ ) {
            Message("2d custom barcode");

            $prefix = 'CNT';    ## use different prefix for 2d containers (temporary ?)

            my %info    = $dbc->Table_retrieve( "Plate,Sample_Type", [ "Plate_Label", "Sample_Type", "Plate_Number" ], "WHERE Plate_ID = $thisid AND FK_Sample_Type__ID = Sample_Type_ID" );
            my $label   = $info{Plate_Label}[0];
            my $content = $info{Sample_Type}[0] || 'unknown';
            my $number  = $info{Plate_Number}[0];
            $barcode->set_fields(
                (   'class'      => $prefix,
                    'id'         => $prefix . $thisid,
                    'id2'        => $prefix . $thisid,
                    'style'      => 'datamatrix',
                    'barcode'    => "$prefix$thisid",
                    'plateid'    => $thislib,
                    'date'       => $thisday,
                    'init'       => $init,
                    'name'       => "$content",
                    'name2'      => "$content",
                    'label'      => $label,
                    'label2'     => $label,
                    'class_tube' => $prefix,
                    'name_tube'  => $label,
                    'name_tube2' => $label,
                    'init2'      => $init,
                    'date2'      => $thisday
                )
            );
        }
        elsif ( $label_name =~ /cg_tube_1D/ ) {
            $barcode->set_fields(
                (   'class'   => $prefix,
                    'id'      => $thisid,
                    'style'   => "code128",
                    'barcode' => "$prefix$thisid",
                    'p_code'  => $p_code,
                    'p2_code' => $p2_code,
                    'b_code'  => $b_code,
                    'date'    => $thisday,
                    'init'    => $init,
                    'label'   => $plate_label
                )
            );
        }
        elsif ( $label_name =~ /cg_tube/ ) {
            my %info = $dbc->Table_retrieve(
                "Plate,Sample,Sample_Type,Plate_Sample,Source,Original_Source,Employee",
                [ 'Original_Source_Name', 'External_Identifier', 'Date(Plate_Created)', 'Employee.Initials as Created_By', 'Sample_Type.Sample_Type' ],
                "WHERE Plate.FK_Sample_Type__ID = Sample_Type_ID AND Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID AND Plate.FK_Employee__ID=Employee_ID AND Plate_ID = $thisid",
                -date_format => 'SQL'
            );

            my $patient_id   = $info{Original_Source_Name}[0];
            my $onyx_barcode = $info{External_Identifier}[0];
            my $barcode_id   = $prefix . $thisid;
            my $init         = $info{Created_By}[0];
            my $created      = $info{'Date(Plate_Created)'}[0];
            my $content      = $info{Sample_Type}[0];

            my $onyx_id;
            my $onyx_type;
            my %onyx_type_hash = (
                T01 => 'SST',
                T02 => 'ACD',
                T03 => 'EDTA',
                T04 => 'U Cup',
                T05 => 'PST',
                T06 => 'EDTA',
                T07 => 'EDTA',
                T09 => 'EDTA',
                T10 => 'FRT Serum',
                T11 => 'EDTA',
                T12 => 'EDTA',
                T14 => 'Saliva'
            );

            my %content_type_hash = ( 'Whole Blood' => 'Blood', 'Blood Serum' => 'Serum', 'Blood Plasma' => 'Plasma', 'Red Blood Cells' => 'RBC', 'White Blood Cells' => 'WBC' );
            if ( $content_type_hash{$content} ) { $content = $content_type_hash{$content} }

            my $patient_id;

            if ( $onyx_barcode =~ /([a-zA-Z]{2}\d+)(T\d+)(.*)/ ) { $onyx_id = $1; $onyx_type = $2; $patient_id = $3; }
            else                                                 { $onyx_id = 'undef' }

            $barcode->set_fields(
                (   'class'     => $prefix,
                    'plate_id'  => $barcode_id,
                    'plate_id2' => $barcode_id,
                    'id'        => "$onyx_type_hash{$onyx_type}",
                    'id2'       => "$onyx_type_hash{$onyx_type}",
                    'style'     => 'datamatrix',
                    'barcode'   => $barcode_id,
                    'barcode2'  => $barcode_id,
                    'label'     => $onyx_id,
                    'label2'    => $onyx_id,
                    'content'   => $content,
                    'content2'  => $content,
                    'date'      => $created,
                    'init'      => $init,

                    #'type'       => $onyx_type_hash{$onyx_type},
                    #'type2'      => $onyx_type_hash{$onyx_type},
                )
            );
        }
        elsif ( $label_name =~ /cg_large/ ) {
            my %info      = $dbc->Table_retrieve( "Plate", [ "Plate_Label", "FK_Sample_Type__ID", "Plate_Number" ], "WHERE Plate_ID = $thisid" );
            my $label     = $info{Plate_Label}[0];
            my ($patient) = $dbc->Table_find( "Patient,Source,Plate,Sample,Plate_Sample",
                "Patient_Identifier", " WHERE Plate_ID=$thisid AND Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source_ID AND Patient.Patient_ID=Source.FK_Patient__ID" );
            my $content_id = $info{FK_Sample_Type__ID}[0] || '0';
            my ($content) = $dbc->Table_find( 'Sample_Type', 'Sample_Type', "WHERE Sample_Type_ID = $content_id" );
            my $number = $info{Plate_Number}[0];
            my ($collecteddate) = $dbc->Table_find(
                'Source,Plate,Sample,Plate_Sample',
                "Collected_Date",
                "WHERE Plate_ID=$thisid AND Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source_ID",
                -date_format => 'SQL'
            );
            $barcode->set_fields(
                (   'class'   => $prefix,
                    'id'      => $thisid,
                    'barcode' => "$prefix$thisid",
                    'plateid' => $thislib,
                    'date'    => "C:$collecteddate",
                    'label'   => "P:$patient",
                    'content' => $content,
                    'init'    => $init
                )
            );

        }
        else {
            $barcode->set_fields(
                (   'class'   => $prefix,
                    'id'      => $thisid,
                    'style'   => "code128",
                    'barcode' => "$prefix$thisid",
                    'plateid' => $thislib,
                    'quad'    => $quad,
                    'p_code'  => $p_code,
                    'p2_code' => $p2_code,
                    'b_code'  => $b_code,
                    'date'    => $thisday,
                    'init'    => $init,
                    'label'   => "'$plate_label'"
                )
            );
        }
        $barcode->print( -noscale => $noscale );
    }

    # require LampLite::Barcode;
    # LampLite::Barcode->reprint_option('Plate',$id,'plate', -dbc=>$dbc);
    return;
}

####################
sub tray_barcode {
####################
    #
    # Note: This function has been rewriten from the old table structor of Multiple_Barcode
    #
    # Input: A string of Plate_IDs, printonly flag, and pack flag
    #        If pack flag is provided, the method will try to fit the plates into as little Trays as possible, otherwise
    #        it will keep their plate_positions intact. Packing _relies_ on the order of plate_ids
    #
    #
####################
    my %args = filter_input(\@_, -args=>'text,print,pack,type,skip');
    my $text        = $args{-text} || $current_plates;
    my $print       = $args{-print};                      ### print barcodes
    my $pack        = $args{-pack};
    my $type        = $args{-type};
    my $skip_prompt = $args{-skip};

    my $dbc = $args{-dbc};
    my $ids = get_aldente_id( $dbc, $text, 'Plate' );

    ### Check to see if these plates are already on a tray or no
    my $tray = alDente::Tray->new( -dbc => $dbc, -plates => $ids );

    if ( !$tray->{tray_ids} ) {
        ### If they are not, create trays for them
        Message("Error: no tray exists to print barcode for. Please report an Issue");
        Call_Stack();
    }

    if ($print) {
        my %trays = %{ $tray->{trays} } if $tray->{tray_ids};
        foreach my $tray_id ( sort { $a <=> $b } keys %trays ) {
            foreach my $quad ( sort keys %{ $trays{$tray_id} } ) {
                ## Basicly only first one, since there is a last statement at the end of this loop!
                my $plate_id = $trays{$tray_id}->{$quad};

                my $info = join ',',
                    $dbc->Table_find(
                    "Plate,$type,Employee",
                    'FK_Library__Name,Plate_Number,Plate.Parent_Quadrant,Plate_Created,Initials,FK_Plate_Format__ID,FK_Branch__Code',
                    "where FK_Plate__ID=Plate_ID AND Plate_ID=$plate_id and Employee_ID=FK_Employee__ID",
                    -date_format => 'SQL'
                    );

                #	Test_Message("INFO:".$info,$testing);

                my $pipeline_code = join( ',', $dbc->Table_find_array( 'Plate_Tray,Plate,Pipeline', ['left(Pipeline_Code,3)'], "WHERE FK_Plate__ID=Plate_ID AND FK_Pipeline__ID=Pipeline_ID AND FK_Tray__ID = $tray_id", -distinct => 1 ) );
                my ($tray_label) = $dbc->Table_find( 'Tray', 'Tray_Label', "WHERE Tray_ID = $tray_id" );

                if ( $pipeline_code =~ /,/ ) { $pipeline_code = 'MIX'; }
                $pipeline_code =~ /(\w)(\w+)/;
                my $p_code  = $1 || '_';
                my $p2_code = $2 || '_';

                if ( $Login{dbase} =~ /Test|Dev/i ) { $p_code = "T"; $p2_code = $p_code; }    ### distinguish TEST plate barcodes..

                my ( $libname, $pnum, $quad, $thisdate, $init, $format, $b_code ) = split( ',', $info );

                my ( $thisday, $thistime ) = split( / /, $thisdate );

                $quad ||= " ";

                my $thislib = $libname . "-" . $pnum;
                $thisday =~ /\d\d(\d\d)-(\d\d)-(\d\d)/;
                my $label_name;
                my $barcode_type_label = param("Barcode Name");
                if ( $barcode_type_label && $barcode_type_label !~ /Select/ ) {
                    ($label_name) = $dbc->Table_find( "Barcode_Label", "Barcode_Label_Name", "WHERE Label_Descriptive_Name='$barcode_type_label'" );
                }
                ($label_name) = $dbc->Table_find( 'Plate_Format,Barcode_Label', 'Barcode_Label_Name', "where FK_Barcode_Label__ID=Barcode_Label_ID AND Plate_Format_ID = $format" ) unless $label_name;

                # Tray labels should be identical to plate labels - use same label format #
                # (removed previous use of $label . '_mult' ) - Dec / 2007

                my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc);
                $barcode->set_fields(
                    (   'class'    => 'Tra',
                        'id'       => "$tray_id",
                        'style'    => "code128",
                        'barcode'  => "Tra$tray_id",
                        'multtext' => "TRA" . $tray_id,
                        'plateid'  => $thislib,
                        'quad'     => $quad,
                        'p_code'   => $p_code,
                        'p2_code'  => $p2_code,
                        'b_code'   => $b_code,
                        'date'     => $thisday,
                        'init'     => $init,
                        'label'    => "'$tray_label'",
                    )
                );
                $barcode->print( -skip_prompt => $skip_prompt );
                last;
            }
        }
    }
}

############################
sub tube_barcode {
############################
    #
    #  NOT USED (remove) ****
    #
    #  Print Barcode for equipment
    #
    my %args = filter_input( \@_, -args => 'id' );
    my $id = $args{-id};    # barcode or list of plate IDs

    my $dbc = $args{-dbc};

    my $Tid = get_aldente_id( $dbc, $id, 'Tube' );
    $id = sprintf "%8.0d", $Tid;
    $id =~ s/ /0/g;

    unless ($Tid) { return 0; }

    #    print h3("(currently in Bio-informatics room)");
    my %Info = $dbc->Table_retrieve( 'Tube', [ 'Tube_ID', 'FK_Library__Name as Library', 'Tube_Status as Status' ], "where Tube_ID = $Tid" );

    my $tube    = $Info{Tube_ID}[0];
    my $library = $Info{Library}[0];
    my $status  = $Info{Status}[0];

    if ( $tube =~ /[1-9]/ ) {
        $dbc->message("Printing Barcode for Tube $tube $library ($status)");
    }
    else {
        $dbc->message("Unidentified Tube");
        return 0;
    }

    my $label_name = 'barcode1';
    my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc);
    $barcode->set_fields(
        (   'class'   => 'Tub',
            'id'      => $Tid,
            'style'   => "code128",
            'barcode' => "Tub$Tid",
            'text'    => "$library $status",
        )
    );
    $barcode->print();

    return 1;
}

#######################
sub box_barcode {
#######################
    my %args = filter_input( \@_, -args => 'id, index' );
    my $id = $args{-id};    # barcode or list of plate IDs
    my $index = $args{-index};
    my $dbc = $args{-dbc};
    my $number = Extract_Values( [ $index, 1 ] );

    if ( $id =~ /Sol(\d+)/i ) { $id = $1; }
    my @ids = split ',', $id;
    foreach my $thisid (@ids) {
        my %info = $dbc->Table_retrieve(
            'Stock_Catalog,Box left join Stock on FK_Stock__ID=Stock_ID left join Barcode_Label on FK_Barcode_Label__ID=Barcode_Label_ID left join Employee on Stock.FK_Employee__ID=Employee_ID',
            [ 'Stock_Catalog_Name', 'Box_Opened', 'Stock_Received', 'Box_Number', 'Box_Number_in_Batch', 'Initials', 'Barcode_Label_Name' ],
            "where Box_ID=$thisid AND FK_Stock_Catalog__ID = Stock_Catalog_ID",
            -date_format => 'SQL'
        );

        my ( $name, $opened, $received, $Boxnumber, $Nof, $init, $label_name ) = map { $_->[0] } @info{ ( 'Stock_Catalog_Name', 'Box_Opened', 'Stock_Received', 'Box_Number', 'Box_Number_in_Batch', 'Initials', 'Barcode_Label_Name' ) };

        my $openday;
        my $opentime;

        my $form = "";
        ############## Display Recieved Date unless Made in House ##############
        if ( $opened =~ /^2/ ) {
            ( $openday, $opentime ) = split / /, $opened;
            $openday = "$openday";
            $form    = "Opened:";
        }
        else {
            ( $openday, $opentime ) = split / /, $received;
            $openday = "$openday";
            $form    = "Rcvd:";
        }

        &Test_Message( "Box$thisid = $name ($Boxnumber of $Nof)<BR>$form: $openday.", $testing );

        my ($box_expiry_date) = $dbc->Table_find( -table => "Box", -fields => "Box_Expiry", -condition => "where Box_ID = $thisid", -date_format => "SQL" );
        my $exp_day;
        if ( $box_expiry_date =~ /[\d\d\d\d|\d\d]\-\d\d\-\d\d/ ) {
            $exp_day = "EXP:$box_expiry_date";
        }
        else {
            $exp_day = "EXP:00-00-00";
        }

        my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc );

        my %field_args = (
            'class'    => 'Box',
            'id'       => $thisid,
            'style'    => "code128",
            'barcode'  => "Box$thisid",
            'exp_date' => $exp_day,
            'date'     => $received,
            'init'     => $init,
            'batch'    => "$Boxnumber/$Nof",
            'solname'  => $name,
            'test'     => '',
            'label'    => ''
        );

        if ( $Login{dbase} =~ /Test|Dev/i ) {
            $field_args{'test'} = 'T';
        }

        $barcode->set_fields(%field_args);

        my $ok;
        foreach ( 1 .. $number ) {
            $ok &= $barcode->print();
        }
        if ($ok) {
            Message("Printed $number barcode(s) for Box(s): $id");
        }
    }
    require LampLite::Barcode;
    LampLite::Barcode->reprint_option( 'Box', $id, -dbc => $dbc );
    return;
}

#####################
sub rack_barcode {
#####################
    my %args    = filter_input( \@_, -args => 'rack_id,option,text' );
    my $rack_id = $args{-rack_id};
    my $option  = $args{-option};
    my $dbc = $args{-dbc};

    my $prefix       = $dbc->barcode_prefix('Rack');

    # optional replacement for the automatically generated equipment name
    my $text = $args{-text};

    my $force = $args{-force};

    #
    #  Print Barcode for equipment
    #
    my $Rid = get_aldente_id( $dbc, $rack_id, 'Rack' );
    my $Rack_id = sprintf "%8.0d", $Rid;
    $Rack_id =~ s/ /0/g;

    my $prefix = $dbc->barcode_prefix('Rack');

    my %Info = $dbc->Table_retrieve(
        'Rack,Equipment,Stock,Stock_Catalog,Equipment_Category',
        [ 'Equipment_Name', 'Sub_Category', 'Rack_Name', 'Movable', 'Rack_Alias', 'Rack_Type' ],
        "WHERE FK_Equipment__ID=Equipment_ID AND Rack_ID = $Rack_id AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID"
    );

    my $equip     = $Info{Equipment_Name}[0];
    my $cond      = alDente::Rack::validate_rack_condition( -dbc => $dbc, -condition => $Info{Sub_Category}[0] );
    my $movable   = $Info{Movable}[0];
    my $rack_name = $Info{Rack_Name}[0];
    my $alias     = $Info{Rack_Alias}[0];
    my $type      = $Info{Rack_Type}[0];

    my $label_name = $option || 'barcode1';

    my ($status) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_Status', "WHERE Barcode_Label_Name = '$label_name'" );
    if ( $type eq 'Slot' && !$force ) {
        $dbc->message('Slot labels suppressed');
        return;
    }
    if ( $status ne 'Active' ) {
        $dbc->message("Warning: $label_name labels are turned off");
        return;
    }

    my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc);

    #    if ( $movable eq 'Y' ) {
    if ($text) {
        $barcode->set_fields(
            (   'class'   => $prefix,
                'id'      => $Rack_id,
                'style'   => "code128",
                'barcode' => "$prefix$Rack_id",
                'text'    => "$text",
            )
        );
    }
    else {
        $barcode->set_fields(
            (   'class'   => $prefix,
                'id'      => $Rack_id,
                'style'   => "code128",
                'barcode' => "$prefix$Rack_id",
                'text'    => $alias,
            )
        );
    }

    $barcode->print( );

    require LampLite::Barcode;
    LampLite::Barcode->reprint_option( 'Rack', $Rack_id, -dbc => $dbc );
    return 1;
}

###########################
sub employee_barcode {
###########################
    my %args    = filter_input( \@_, -args => 'dbc,id' );
    my $id      = $args{-id};
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id = $dbc->get_local('user_id');

    if ( $id =~ /Emp(\d+)/ ) { $id = $1; }

    my $details = join ',', $dbc->Table_find( 'Employee', 'Employee_FullName,Initials', "where Employee_ID = $id" );
    my ( $name, $init ) = split ',', $details;

    if (1) {    ## } $user =~ /admin/i ) {
        ### print out password barcode if administrator.. ###
        my ($pwd) = $dbc->Table_find( 'Employee', 'Password', "WHERE Employee_ID = '$user_id'" );

        my $label_name = "password";
        my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc);
        $barcode->set_fields(
            (   'class'    => 'Emp' . $id,
                'id'       => "$pwd",
                'name'     => $name,
                'initials' => $init,
                'style'    => "code128",
                'barcode'  => "Emp$id\t$pwd\t\n",
            )
        );

        my ( $printer, $printer_id ) = $barcode->get_printer( -label_type => $label_name, -label_height => $barcode->get_attribute('height'), -dbc => $dbc );

        unless ( $barcode->lprprint( -printer => $printer, -dpi => $barcode->get_printer_DPI( -printer => $printer, -dbc => $dbc ) ) ) {    ### can't tie message generated if problem...
            Message("Error printing ?");
            $barcode->print;
        }
        Message("Printed barcode (with password) for $name ($id).");
    }
    else {
        my $label_name = "employee";
        my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc );
        $barcode->set_fields(
            (   'class'   => 'Emp',
                'id'      => $id,
                'barcode' => "Emp$id",
                'style'   => "code128",
                'init'    => $init,
                'name'    => $name,
            )
        );
        $barcode->print();
    }

    return;
}

##########################
sub solution_barcode {
##########################
    my %args = filter_input( \@_, -args => 'dbc,id' );
    my $dbc           = $args{-dbc};
    my $table         = $args{-table};
    my $id            = $args{-id};
    my $option        = $args{-option};                                                                  ## allow multiple copies..
    my $barcode_label = $args{-barcode_label};
    my $count         = $args{-count} || 1;

    $id = get_aldente_id( $dbc, $id, 'Solution' );

    my $prefix = $dbc->barcode_prefix('Solution');

    my @ids = split ',', $id;
    foreach my $thisid (@ids) {
        my %info = $dbc->Table_retrieve(
            'Stock_Catalog, Solution left join Stock on Stock_ID=FK_Stock__ID left join Barcode_Label on FK_Barcode_Label__ID=Barcode_Label_ID left join Employee on Stock.FK_Employee__ID=Employee_ID',
            [   'Stock_Catalog_Name',       'Solution_Started',         'Solution_Expiry', 'Stock_Received',                 'Initials',           'Solution_Number',
                'Solution_Number_in_Batch', 'Stock_Catalog.Stock_Type', 'Solution_Type',   'Stock_Catalog.Stock_Size_Units', 'Barcode_Label_Name', 'Stock_Catalog.Stock_Catalog_Number',
                'Solution_Label'
            ],
            "where Solution_ID=$thisid AND FK_Stock_Catalog__ID = Stock_Catalog_ID",
            -date_format => 'SQL'
        );

        my ( $name, $mixdate, $exp_date, $received, $initials, $bottle, $bottles, $type, $sol_type, $stock_units, $label_name, $cat_number, $solution_label ) = map { $_->[0] } @info{
            (   'Stock_Catalog_Name',       'Solution_Started',         'Solution_Expiry', 'Stock_Received',                 'Initials',           'Solution_Number',
                'Solution_Number_in_Batch', 'Stock_Catalog.Stock_Type', 'Solution_Type',   'Stock_Catalog.Stock_Size_Units', 'Barcode_Label_Name', 'Stock_Catalog.Stock_Catalog_Number',
                'Solution_Label'
            )
            };

        if ($barcode_label) {
            $label_name = $barcode_label;
        }

        my $mixday;
        my $mixtime;

        ### Convert it to 0000-00-00 format from Feb-00-0000 format
        $received = &convert_date( $received, 'SQL' );

        ############## Display Recieved Date unless Made in House ##############
        my $form = '';
        if ( $mixdate =~ /[1-9]/ ) {
            ($mixday) = split ' ', $mixdate;
            if   ( $type =~ /Reagent/ ) { $mixday = "$mixday"; $form = "Opened"; }    ### opened
            else                        { $mixday = "$mixday"; $form = "Made"; }      ### mixed
        }
        elsif ( $received =~ /^[1-9]/ ) {
            $mixday = "$received";
            $form   = "Rcvd";                                                         ### received
        }
        else {
            $form   = "?";
            $mixday = "0000-00-00";
        }

        ### Display expiry date
        my $exp_day;
        if ( $exp_date =~ /[1-9]/ ) {
            $exp_day = $exp_date;
        }
        else {
            $exp_day = "0000-00-00";
        }
        my $app = '';

        # special rule for Agar Solutions - might want to take out once clear that it is going to work
        if ( ( $name =~ /Agar/i ) && ( $type =~ /Solution/i ) ) { $label_name = 'agar_solution'; }

        # special rules for Primer_plate - name is actually the catalog number plus Custom Oligo Plate - need a more general fix
        if ( $name =~ /Custom Oligo Plate/ ) {
            my %data = $dbc->Table_retrieve( 'Primer_Plate', [ 'Primer_Plate_Name', 'Arrival_DateTime', 'Notes' ], "WHERE FK_Solution__ID = $thisid" );
            my $primer_plate_name = $data{Primer_Plate_Name}[0];
            $mixday = $data{Arrival_DateTime}[0];
            my $notes = $data{Notes}[0];

            if ($notes) {
                $name .= " $notes";
            }
            $name .= " $cat_number";
            $primer_plate_name =~ s/Diluted/D/;
            if ( length($primer_plate_name) <= 30 ) {
                $name .= " $primer_plate_name" if ( $primer_plate_name && ( $name !~ /$primer_plate_name/ ) );
            }

            $name =~ s/Custom Oligo Plate/CBO/;

            # query for what primer types each Primer_Plate contains
            my @contains = $dbc->Table_find( "Primer_Plate,Primer_Plate_Well,Primer", "distinct Primer_Type", "WHERE FK_Primer_Plate__ID=Primer_Plate_ID AND FK_Primer__Name=Primer_Name AND FK_Solution__ID=$thisid" );
            my $contains_str = join( ',', @contains );

            # if multiple types, just put M for mixed
            if ( $contains_str =~ /,/ ) {
                $app = "M";
            }
            else {
                $app = substr( $contains_str, 0, 1 );
            }
        }
        $mixday  = &convert_date( $mixday,  'SQL' );
        $exp_day = &convert_date( $exp_day, 'SQL' );
        if ( $mixday  =~ /\d\d(\d\d-\d\d-\d\d)/ ) { $mixday  = $1; }    ### shorten date..
        if ( $exp_day =~ /\d\d(\d\d-\d\d-\d\d)/ ) { $exp_day = $1; }    ### shorten date..
        $exp_day = "EXP:$exp_day";

        my $barcode_type_label = param("Barcode Name");
        if ( $barcode_type_label && $barcode_type_label !~ /Select/ ) {
            ($label_name) = $dbc->Table_find( "Barcode_Label", "Barcode_Label_Name", "WHERE Label_Descriptive_Name='$barcode_type_label'" );
        }

        if ( $label_name =~ /solution_small/ && $solution_label ) { $name .= " '$solution_label'"; }
        if ( $Login{dbase} =~ /Test|Dev/i ) { $app = "T"; }             ### distinguish TEST plate barcodes..

        if ( $option !~ /Solution_Label/ ) { $solution_label = $name; }

        my $barcode = alDente::Barcode->new( -type => "$label_name", -dbc=>$dbc);
        if ( $label_name =~ /tube_solution/i ) {
            $barcode->set_fields(
                (   'class'        => $prefix,
                    'id'           => $thisid,
                    'style'        => "datamatrix",
                    'barcode'      => "$prefix$thisid",
                    'solname'      => $name,
                    'exp_date'     => $exp_day,
                    'date'         => $mixday,
                    'init'         => $initials,
                    'batch'        => "$bottle/$bottles",
                    'solname_tube' => $solution_label,
                    'init_tube'    => $initials,
                    'class_tube'   => $prefix,
                    'id_tube'      => $thisid,
                    'app'          => $app
                )
            );
        }
        else {
            $barcode->set_fields(
                (   'class'    => $prefix,
                    'id'       => $thisid,
                    'barcode'  => "$prefix$thisid",
                    'style'    => 'code128',
                    'exp_date' => $exp_day,
                    'date'     => $mixday,
                    'init'     => $initials,
                    'batch'    => "$bottle/$bottles",
                    'solname'  => $name,
                    'test'     => $app,
                    'label'    => "'$solution_label'",
                )
            );
        }
        foreach ( 1 .. $count ) {
            $barcode->print( );
        }

    }

    require LampLite::Barcode;
    LampLite::Barcode->reprint_option( 'Solution', $id, 'solution', -dbc => $dbc );
    return;
}

#################################
sub print_multiple_barcode {
#################################
    my %args = filter_input( \@_, -args => 'dbc,id' );
    my $id  = $args{-id};
    my $dbc = $args{-dbc};

    if ( $id =~ /enc(\d+)/ ) { $id = $1; }
    ( my $text ) = $dbc->Table_find( 'Multiple_Barcode', 'Multiple_Text', "where Multiple_Barcode_ID = $id" );

    $text =~ s/,//g;

    my $label_name = "barcode2";
    my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc );
    $barcode->set_fields(
        (   'class'   => 'enc',
            'id'      => $id,
            'barcode' => "enc$id",
            'style'   => "code128",
            'string'  => "ENC$id",
            'type'    => "$text",
            'secid'   => "",
        )
    );

    $barcode->print();
    return 1;
}

#################################
sub print_multiple_plate {
#################################
    my %args = filter_input( \@_, -args => 'dbc,id' );
    my $dbc = $args{-dbc};
    my $plate_list = $args{-id};

    foreach ( split( ',', $plate_list ) ) {
        &plate_barcode($_);
    }

    return 1;
}

#####################
sub sample_barcode {
#####################
    my %args = filter_input( \@_, -args => 'dbc,id' );
    my $dbc = $args{-dbc};
    my $sample_id = $args{-id};

    #
    #  Print Barcode for equipment
    #
    my $label_name = "barcode1";
    my $sid = get_aldente_id( $dbc, $sample_id, 'Sample' );
    $sid = sprintf "%8.0d", $sid;
    $sid =~ s/ /0/g;

    #    print h3("(currently in Bio-informatics room)");
    my %Info = $dbc->Table_retrieve( 'Sample', ['Sample_Name'], "where Sample_ID = $sample_id" );
    my $name = $Info{Sample_Name}[0];

    print h3("Printing Barcode for Sample $sample_id");

    my $barcode_type_label = param("Barcode Name");
    if ( $barcode_type_label && $barcode_type_label !~ /Select/ ) {
        ($label_name) = $dbc->Table_find( "Barcode_Label", "Barcode_Label_Name", "WHERE Label_Descriptive_Name='$barcode_type_label'" );
    }

    my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc);
    $barcode->set_fields(
        (   'class'   => 'Sam',
            'id'      => $sid,
            'style'   => "code128",
            'barcode' => "Sam$sid",
            'text'    => "$name",
        )
    );
    $barcode->print();
    if ( $URL_version =~ /Production|Beta/i ) {
        require LampLite::Barcode;
        LampLite::Barcode->reprint_option( 'Sample', $sid, 'original source', -dbc => $dbc );
        barcode_text("Sam$sid");
    }
    return 1;
}

#####################
sub source_barcode {
#####################
    my %args = filter_input( \@_, -args => 'id' );
    my $source_id = $args{-id};    # barcode or list of plate IDs
    my $dbc = $args{-dbc};
    #
    #  Print Barcode for library container
    #
    $source_id = get_aldente_id( $dbc, $source_id, 'Source' );
    my @source_ids = split ',', $source_id;
    foreach my $source_id (@source_ids) {
        $source_id = sprintf "%8.0d", $source_id;
        $source_id =~ s/ /0/g;

        my $selected_label = param('Barcode Name') || param('FK_Barcode_Label__ID');
        my ($selected_label_name) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_Name', "where Barcode_Label_Type like 'source' AND Barcode_Label_Status ='Active' and Label_Descriptive_Name = '$selected_label'" );
        my ($default_label_names) = $dbc->Table_find( 'Source,Barcode_Label', 'Barcode_Label_Name,Label_Descriptive_Name', "where FK_Barcode_Label__ID=Barcode_Label_ID AND Source_ID = $source_id" );
        my ( $label_name, $label_descriptive_name ) = split ',', $default_label_names;
        
        if ( $selected_label_name && $label_name && $selected_label_name ne $label_name ) {
            $dbc->warning("Note: requested barcode label '$selected_label' is different from the default barcode label '$label_descriptive_name'!");
        }
        $label_name = $selected_label_name if ($selected_label_name);

        if ( $label_name =~ /no_barcode/i ) {
            # $dbc->{session}->warning("No Barcode generated for $selected_label_name");
            ## do not print
            next;
        }

        $dbc->message("Printing Barcode for Source $source_id");

        # Get label type and symbology

        my $symbology;
        if   ( $label_name =~ /src_tube/i ) { $symbology = 'datamatrix' }    # 2D
        else                                { $symbology = 'code128' }       # 1D

        # Get needed information
        my %info = $dbc->Table_retrieve(
            'Original_Source,Taxonomy,Source left join Employee on Source.FKReceived_Employee__ID=Employee_ID',
            [ 'Taxonomy_Name as Organism', 'Original_Source_Name', 'Initials', 'Received_Date', 'Original_Amount', 'Amount_Units', 'Source_Number', 'Source_Label', 'External_Identifier' ],
            "WHERE Source_ID=$source_id AND FK_Taxonomy__ID=Taxonomy_ID AND FK_Original_Source__ID=Original_Source_ID"
        );

        my $name   = $info{Label}[0] || $info{Original_Source_Name}[0] || '-';
        my $date   = $info{Received_Date}[0];
        my $init   = $info{Initials}[0] || 'N/A';
        my $amnt   = $info{Original_Amount}[0];
        my $ext_id = $info{Source_Label}[0] || $info{External_Identifier}[0] || 'no ext_id';    # it uses source label over ext id if available

        if ( defined $amnt ) {
            $amnt = join '', &RGTools::Conversion::Get_Best_Units( -amount => $amnt );
            $amnt .= $info{Amount_Units}[0];
        }
        else {
            $amnt = '';
        }
        my $num = $info{Source_Number}[0] || '';
        my $organism = $info{Organism}[0];

        # convert date
        $date = &convert_date( $date, 'SQL' );

        my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc);
        $barcode->set_fields(
            (   'class'     => 'SRC',
                'id'        => $source_id,
                'style'     => $symbology,
                'barcode'   => "SRC$source_id",
                'name'      => $name,
                'date'      => $date,
                'init'      => $init,
                'organism'  => $organism,
                'name_tube' => $name,
                'name_2d'   => $name,
                'number_2d' => $num,
                'amount'    => $amnt,
                'number'    => $num,
                'ext_id'    => $ext_id
            )
        );

        $barcode->print();
    }
    return 1;
}

#####################
sub barcode_text {
#####################
    my %args = filter_input(\@_, -args=>'text,label_name');
    my $text = $args{-text};
    my $label_name = $args{-label_name} || "proc_med";
    my $dbc = $args{-dbc};

    my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc );
    $barcode->set_fields(
        (   'class'   => $text,
            'id'      => "",
            'barcode' => $text,
            'style'   => 'code39',
        )
    );
    $barcode->print();

    return;
}

###########################
# Print slot barcodes
###########################
sub print_slot_barcodes {
###########################
    my %args = @_;

    my $max_row = $args{-max_row} || 'i';
    my $max_col = $args{-max_col} || 9;
    my $scale   = $args{-scale}   || 1;
    my $height  = $args{-height}  || 30;
    my $vspace  = $args{-vspace}  || 5;

    my $object = new Barcode::Code128;
    $object->option( "scale",  $scale );
    $object->option( "height", $height );

    # Generate the barcodes
    foreach my $row ( 'a' .. $max_row ) {
        foreach my $col ( 1 .. $max_col ) {
            open( PNG, ">$URL_temp_dir/code128_$row$col.png" ) or die "Can't write code128_$row$col.png: $!\n";
            binmode(PNG);

            print PNG $object->png("$row$col");
            close(PNG);
        }
    }

    # Display the barcodes
    my $barcodes_output = "<table border=1 cellpadding=2>";
    foreach my $row ( 'a' .. $max_row ) {
        $barcodes_output .= "<tr>";
        foreach my $col ( 1 .. $max_col ) {
            $barcodes_output .= "<td><img src='/dynamic/tmp/code128_$row$col.png'></img>" . vspace($vspace) . "</td>";
        }
        $barcodes_output .= "</tr>";
    }
    $barcodes_output .= "</table>";

    # Create the printable page
    open( PPG, ">$URL_temp_dir/print_slot_barcodes.html" ) or die "Can't write print_slot_barcodes.html: $!\n";
    print PPG "<html><head><title>Print Slot Barcodes</title></head>";
    print PPG "<body>$barcodes_output</body></html>";
    close(PPG);

    print &Link_To( "$URL_domain/$URL_dir_name/dynamic/tmp/print_slot_barcodes.html", "Printable Page", undef, 'blue' ) . " <span class='small'>(Please print in Landscape mode)</span>" . vspace(5) . $barcodes_output;
}

#################################
sub print_simple_large_label {
#################################
    my %args = filter_input(\@_, -args=>'labels');
    my $labels =  $args{-labels};
    my ($field1, $field2, $field3, $field4, $field5) = Cast_List(-list=>$labels, -to=>'array');
 
    my $dbc = $args{-dbc};

    my $barcode = alDente::Barcode->new( -type => "label1", -dbc=>$dbc );
    $barcode->set_fields(
        (   'field1' => $field1,
            'field2' => $field2,
            'field3' => $field3,
            'field4' => $field4,
            'field5' => $field5
        )
    );
    $barcode->print();

    return 1;
}

#################################
sub print_simple_small_label {
#################################
    my %args = filter_input(\@_, -args=>'labels');
    my $labels =  $args{-labels};
    my ($field1, $field2) = Cast_List(-list=>$labels, -to=>'array');
 
    my $dbc = $args{-dbc};

    my $label_name = "label2";
    my $barcode    = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc );
    $barcode->set_fields(
        (   'field1' => $field1,
            'field2' => $field2
        )
    );

    # my $printer = $barcode-> get_printer(-dbc=>$dbc, -label_type=>$label_name,-label_height=>$barcode->get_attribute('height'));
    # unless ($barcode->lprprint(-printer=>$printer,-dpi=> $barcode->get_printer_DPI(-printer=>$printer, -dbc=>$dbc))) {   ### can't tie message generated if problem...
    # Message("Error printing: " . $barcode->dump_format);

    $barcode->print();
    return 1;
}

#################################
sub print_simple_tube_label {
#################################
    my %args = filter_input(\@_, -args=>'labels');
    my $labels = $args{-labels};
    my ($field1, $field2, $field3, $field4, $tube_field) = Cast_List(-list=>$labels, -to=>'array');
    my $dbc = $args{-dbc};
    my $label_name = "plain_tube";

    my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc );
    $barcode->set_fields(
        (   'text1'     => $field1,
            'text2'     => $field2,
            'text3'     => $field3,
            'text4'     => $field4,
            'text_tube' => $tube_field
        )
    );
    $barcode->print(-dpi=>'200');

    return 1;
}

#################################
#
# Print Barcode For Runs
#
#################################
sub run_barcode {
#################
    my %args = filter_input( \@_, -args => 'id' );
    my $id         = $args{-id};
    my $label_name = 'run_barcode_1D';
    my $dbc        = $args{-dbc};

    my $run_name = "Run_Directory";
    my ($row) = $dbc->Table_find(
        'RunBatch,Run,Equipment,Employee,Plate LEFT JOIN Rack ON FKPosition_Rack__ID=Rack_ID LEFT JOIN Pipeline ON FK_Pipeline__ID=Pipeline_ID',
        "Equipment_Name,DATE_FORMAT(Run_DateTime,'%e-%b-%Y'),Initials,$run_name,left(Pipeline_Code,3),Rack_Alias,LEFT(Run_Type,3),FK_Library__Name,Plate_Number,Parent_Quadrant",
        "WHERE Run.FK_RunBatch__ID=RunBatch_ID AND RunBatch.FK_Equipment__ID=Equipment_ID AND RunBatch.FK_Employee__ID=Employee_ID AND FK_Plate__ID=Plate_ID AND Run_ID=$id"
    );
    my ( $equip_name, $date, $emp_init, $dir, $pipeline_code, $position, $type, $lib, $p_num, $quad ) = split( ',', $row );

    my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc );
    $barcode->set_fields(
        (   'class'    => 'RUN',
            'id'       => $id,
            'barcode'  => "Run$id",
            'box'      => $equip_name,
            'position' => $position,
            'creation' => $date,
            'initial'  => $emp_init,

            #'name'     => "$lib-$p_num$quad",
            'name'   => $dir,
            'p_code' => $pipeline_code,
            'type'   => $type
        )
    );
    $barcode->print();
    return;
}

#################################
#
# Print Barcode For Gel Runs
#
#################################
sub gelrun_barcode {
#################
    my %args = filter_input( \@_, -args => 'id' );
    my $id         = $args{-id};
    my $dbc        = $args{-dbc};
    my $label_name = 'gelpour_barcode_1D';

    my ($row) = $dbc->Table_find(
        'RunBatch,Run,GelRun,Employee,Rack',
        "DATE_FORMAT(RunBatch_RequestDateTime,'%e-%b-%Y'),Initials,Rack_ID,Rack_Name",
        "WHERE RunBatch_ID=FK_RunBatch__ID AND FK_Run__ID=Run_ID AND FKPoured_Employee__ID=Employee_ID AND FKPosition_Rack__ID=Rack_ID AND Run_ID = $id"
    );
    my ( $date, $emp_init, $rack_id, $alias ) = split( ',', $row );
    my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc );
    $barcode->set_fields(
        (   'class'    => 'RUN',
            'id'       => $id,
            'barcode'  => "Run$id",
            'rack'     => "RAC $rack_id $alias",
            'creation' => $date,
            'initial'  => $emp_init
        )
    );
    $barcode->print();
    return;
}

#################################
#
# Print Barcode For E-Gel Run. The id printed is Gel_Run_ID
#
#################################
sub Egel_run_barcode {
#################
    my %args = filter_input( \@_, -args => 'id' );
    my $id         = $args{-id};
    my $dbc        = $args{-dbc};
    my $label_name = 'E-Gel_barcode_1D';

    my ($row) = $dbc->Table_find(
        'RunBatch,Run,Gel_Lane,Gel_Run,Employee',
        "DATE_FORMAT(RunBatch_RequestDateTime,'%e-%b-%Y'),Initials,FKGel_Solution__ID",
        "WHERE RunBatch_ID=FK_RunBatch__ID AND Gel_Lane.FK_Run__ID=Run_ID AND Gel_Lane.FK_Gel_Run__ID = Gel_Run_ID AND RunBatch.FK_Employee__ID=Employee_ID AND Gel_Run_ID = $id"
    );
    my ( $date, $emp_init, $gel_solution_id ) = split( ',', $row );
    my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc );
    $barcode->set_fields(
        (   'class'    => 'GRN',
            'id'       => $id,
            'barcode'  => "GRN$id",
            'solution' => "Sol$gel_solution_id",
            'creation' => $date,
            'initial'  => $emp_init
        )
    );
    $barcode->print();
    return;
}

#################################
#
# Print Barcode For AATI Run Batch. The id printed is AATI_Run_Batch_ID
#
#################################
sub AATI_run_batch_barcode {
#################
    my $id         = shift;
    my $dbc        = $Connection;
    my $label_name = 'AATI_Run_barcode_1D';

    my ($row) = $dbc->Table_find(
        'RunBatch,Run,AATI_Run,AATI_Run_Batch,Employee',
        "DATE_FORMAT(RunBatch_RequestDateTime,'%e-%b-%Y'),Initials",
        "WHERE RunBatch_ID=FK_RunBatch__ID AND AATI_Run.FK_Run__ID=Run_ID AND AATI_Run.FK_AATI_Run_Batch__ID = AATI_Run_Batch_ID AND RunBatch.FK_Employee__ID=Employee_ID AND AATI_Run_Batch_ID = $id"
    );
    my ( $date, $emp_init ) = split( ',', $row );
    my $barcode = Barcode->new( -type => $label_name );
    $barcode->set_fields(
        (   'class'    => 'ARN',      # AATI Run Batch
            'id'       => $id,
            'barcode'  => "ARN$id",
            'creation' => $date,
            'initial'  => $emp_init
        )
    );
    _print( $barcode, -dbc => $dbc );
    return;
}

#################################
#
# Print Barcode For Solid Runs
#
#################################
sub solidrun_barcode {
#################
    my %args = filter_input( \@_, -args => 'id' );
    my $id         = $args{-id};
    my $dbc        = $args{-dbc};
    my $label_name = 'run_barcode_1D';

    my $prefix = $dbc->barcode_prefix('Plate');
    
    my $position_field = "CONCAT(Equipment_Name, ' ',CASE WHEN FK_Tray__ID IS NOT NULL THEN CONCAT('Tra',FK_Tray__ID, ' - L', Plate_Position) ELSE CONCAT('$prefix', Plate_ID, ' - L1') END)";
    my ($row) = $dbc->Table_find(
        'RunBatch,Run,Equipment,Employee,Plate LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID = Plate_ID LEFT JOIN Pipeline ON FK_Pipeline__ID=Pipeline_ID',
        "DATE_FORMAT(Run_DateTime,'%e-%b-%Y'),Initials,Run_Directory,Pipeline_Code,$position_field,LEFT(Run_Type,5)",
        "WHERE Run.FK_RunBatch__ID=RunBatch_ID AND RunBatch.FK_Equipment__ID=Equipment_ID AND RunBatch.FK_Employee__ID=Employee_ID AND Run.FK_Plate__ID=Plate_ID AND Run_ID=$id"
    );
    my ( $date, $emp_init, $dir, $pipeline_code, $position, $type ) = split( ',', $row );

    my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc );
    $barcode->set_fields(
        (   'class'    => 'RUN',
            'id'       => $id,
            'barcode'  => "$dir",
            'position' => $position,
            'creation' => $date,
            'initial'  => $emp_init,
            'name'     => $dir,
            'p_code'   => $pipeline_code,
            'type'     => $type,
        )
    );
    $barcode->print();
    return;
}

##########################
sub microarray_barcode {
##########################
    my %args = filter_input( \@_, -args => 'id' );
    my $id         = $args{-id};
    my $dbc        = $args{-dbc};
    my $number = Extract_Values( [ shift, 1 ] );

    $id = get_aldente_id( $dbc, $id, 'Microarray' );

    my @ids = split ',', $id;
    foreach my $thisid (@ids) {
        my %info = $dbc->Table_retrieve(
            "Stock_Catalog,Stock,Microarray,Employee,Barcode_Label",
            [ "Stock_Catalog_Name", "Used_DateTime", "Expiry_DateTime", "Stock_Received", "Initials", "Microarray_Number", "Microarray_Number_In_Batch", "Microarray_Type", "Barcode_Label_Name", "Stock_Catalog.Stock_Catalog_Number" ],
            "WHERE Microarray.FK_Stock__ID=Stock_ID AND Stock.FK_Employee__ID=Employee_ID AND Stock.FK_Barcode_Label__ID=Barcode_Label_ID AND Microarray_ID=$thisid AND FK_Stock_Catalog__ID = Stock_Catalog_ID"
        );

        my ( $name, $mixdate, $exp_date, $received, $initials, $bottle, $bottles, $type, $label_name, $cat_number )
            = map { $_->[0] }
            @info{ ( "Stock_Catalog_Name", "Used_DateTime", "Expiry_DateTime", "Stock_Received", "Initials", "Microarray_Number", "Microarray_Number_In_Batch", "Microarray_Type", "Barcode_Label_Name", "Stock_Catalog.Stock_Catalog_Number" ) };

        if ( $initials =~ /NULL/ ) { $initials = '---'; }
        my $mixday;
        my $mixtime;

        ### Convert it to 0000-00-00 format from Feb-00-0000 format
        $received = &convert_date( $received, 'SQL' );

        ############## Display Recieved Date unless Made in House ##############
        my $form = '';
        if ( $mixdate =~ /[1-9]/ ) {
            ($mixday) = split ' ', $mixdate;
            if   ( $type =~ /Reagent/ ) { $mixday = "$mixday"; $form = "Opened"; }    ### opened
            else                        { $mixday = "$mixday"; $form = "Made"; }      ### mixed
        }
        elsif ( $received =~ /^[1-9]/ ) {
            $mixday = "$received";
            $form   = "Rcvd";                                                         ### received
        }
        else {
            $form   = "?";
            $mixday = "0000-00-00";
        }

        ### Display expiry date
        my $exp_day;
        if ( $exp_date =~ /[1-9]/ ) {
            $exp_day = $exp_date;
        }
        else {
            $exp_day = "0000-00-00";
        }

        $mixday  = &convert_date( $mixday,  'SQL' );
        $exp_day = &convert_date( $exp_day, 'SQL' );
        if ( $mixday  =~ /\d\d(\d\d-\d\d-\d\d)/ ) { $mixday  = $1; }    ### shorten date..
        if ( $exp_day =~ /\d\d(\d\d-\d\d-\d\d)/ ) { $exp_day = $1; }    ### shorten date..
        $exp_day = "EXP:$exp_day";

        my $barcode_type_label = param("Barcode Name");
        if ( $barcode_type_label && $barcode_type_label !~ /Select/ ) {
            ($label_name) = $dbc->Table_find( "Barcode_Label", "Barcode_Label_Name", "WHERE Label_Descriptive_Name='$barcode_type_label'" );
        }
        my $app = '';
        if ( $Login{dbase} =~ /Test|Dev/i ) { $app = "T"; }             ### distinguish TEST plate barcodes..
        my $barcode = alDente::Barcode->new( -type => "$label_name", -dbc=>$dbc );

        $barcode->set_fields(
            (   'class'    => 'MRY',
                'id'       => $thisid,
                'barcode'  => "MRY$thisid",
                'exp_date' => $exp_day,
                'date'     => $mixday,
                'init'     => $initials,
                'batch'    => "$bottle/$bottles",
                'solname'  => $name,
                'test'     => $app
            )
        );

        foreach ( 1 .. $number ) {
            $barcode->print();
        }

    }
    
    require LampLite::Barcode;
    LampLite::Barcode->reprint_option( 'Microarray', $id, 'microarray', -dbc => $dbc );
    return;
}

###########################
## Other Barcode Methods ##
###########################

#######################
sub print_barcode {
#######################
    my %args  = filter_input( \@_, -args => 'table' );
    my $table = $args{-table};
    my $dbc   = $args{-dbc};

    print h3("Print New Barcodes");

    print alDente::Form::start_alDente_form($dbc);

    print hidden( -name => 'Table', -value => "$table" ), submit( -name => 'Barcode_Event', -value => 'Reprint', -class => "Std" ),    ## where is this captured ??
        submit( -name => 'Print Next', -value => "Add new type", -class => "Std" ), textfield( -name => 'Copies', -value => '1', -size => 3 ), submit( -name => 'Home', -style => "background-color:violet" ), "\n</FORM>";

    return;
}

#########################
## Customized Barcodes ##
#########################

####################################################################
# 1 / 3 associated methods (build, preview, print _custom_barcode)
#
# provide form for editing label information and previewing barcode
#
#
#################################
sub build_custom_barcode {
#################################
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $type   = $args{-type};                                                                    ## class of barcode
        my $frozen = $args{-frozen};                                                                  ## frozen barcode supplied (under construction..)

################################
# prompt user for custom labels
################################
        my $name = 1;

### change so that default parameters are set (may be options for small / medium / large / textonly) ##

    my @std_keys = qw(name value posx posy size opts format style sample);

    my %Defaults;
    $Defaults{posx}  = 10;
    $Defaults{posy}  = 10;
    $Defaults{size}  = 20;
    $Defaults{value} = 'enter_text_here';

    my $output = section_heading("Custom Barcode Generation");

    $output .= $dbc->message( "To generate multiple labels, use 'Regenerate Custom Label Form' button below after indicating number of labels required and number of sections desired", -return_html => 1 );

    $output .= alDente::Form::start_alDente_form($dbc);

    my $form = new HTML_Table( -title => 'Custom Barcode Parameters' );
    $form->Set_Headers( \@std_keys );

    my @names;
    if ( $name =~ /^(\d)$/ ) { @names = ( 1 .. $1 ); $name = join ',', @names; }
    else                     { @names = split ',', $name }

    foreach my $row_name (@names) {
        my @row;
        foreach my $key (@std_keys) {
            my $default = $Defaults{$key} if defined $Defaults{$key};
            if ( $key =~ /name/ ) {
                if ( $type eq 'custom' ) {
### custom barcode ... include barcode in single line as required... ###
                    push @row, $row_name . hidden( -name => "label.$key", -value => $row_name, -force => 1 );
                }
                else {
                    push @row, $row_name . hidden( -name => "label.$key", -value => $row_name, -force => 1 );
                }
            }
            else {
                push @row, textfield( -name => "label.$key", -size => 6, -default => $default, -force => 1 );
            }
        }
        $form->Set_Row( \@row, -repeat => 1 );
    }

    my @printers = $dbc->get_FK_info( 'FK_Printer__ID', -list => 1 );    #'Printer_Name',"WHERE Printer_Type = '$label_format'",-distinct=>1);
    $form->Set_Row(
            [   "Printer",
            alDente::Tools::search_list( -name => 'FK_Printer__ID', -element_name => 'Printer', -condition => 'FK_Label_Format__ID=1' )    ## only allow large labels for custom barcodes
            . set_validator( 'Printer', -mandatory => 1 ) . hidden( -name => 'Label Name', -value => $type, -force => 1 )

            ]
            );

    $form->Set_sub_header( submit( -name => 'Barcode_Event', -value => 'Preview Customized Barcode', -class => 'std' ) );
    $form->Set_sub_header( submit( -name => 'Barcode_Event', -value => 'Print Customized Barcode', -class => 'action', -onClick => 'return validateForm(this.form)' ) );

    $output .= $form->Printout(0);

    $output .= hidden( -name => "label names", -value => $name );
    $output .= end_form();
    return $output;
}

#
# This prompt users to generate custom labels.
#
# This does NOT use barcodes.dat, but uses label configuration settings defined in alDente::Barcode.pm
#
#
############################
sub print_custom_barcodes {
############################
    my %args                 = filter_input( \@_ );
    my $dbc                  = $args{-dbc};
    my $type                 = $args{-type};                                    ## class of barcode
    my $frozen               = $args{-frozen};                                  ## frozen barcode supplied
    my $l_count              = defined $args{-l_count} ? $args{-l_count} : 3;
    my $r_count              = defined $args{-r_count} ? $args{-r_count} : 3;
    my $rows                 = $args{-rows} || 1;                               ## starting number of rows...
    my $data                 = $args{-data};
    my $open                 = $args{ -open };
    my $exclude_excel_upload = $args{-exclude_upload};                          ## excludes section at bottom for uploading excel files
    my $collapse_form        = $args{-collapse_form};                           ## collapses customization form into accordion
    ## preview and print buttons still contained outside of accordion

################################
# prompt user for custom labels
################################
    my $name = 1;

    my $output;
    if ($collapse_form) {
        $output
            .= qq(\n<div class="panel-group" id="custom-barcode-accordion" role="tablist" aria-multiselectable="true">\n)
            . qq(\t<div class="panel panel-default">\n)
            . qq(\t\t<div class="panel-heading" role="tab" id="custom-barcode-generation">\n)
            . qq(\t\t\t<a data-toggle="collapse" data-parent="#custom-barcode-accordion" href="#collapse-barcoding" aria-expanded="false" aria-controls="collapse-barcoding">\n)
            . qq(\t\t\t\tCustom Barcode Parameters (click to expand)\n)
            . qq(\t\t\t</a>\n)
            . qq(\t\t</div>\n)
            . qq(<div id="collapse-barcoding" class="panel-collapse collapse" role ="tabpanel" aria-labelledby="custom-barcode-generation">\n);
    }
    
    $output .= section_heading("Custom Barcode Generation");
    
    unless ($exclude_excel_upload) {
    $output .= $dbc->message( "To generate multiple labels, use 'Regenerate Custom Label Form' button below after indicating number of labels required", -return_html => 1 );
    }

    $output .= alDente::Form::start_alDente_form($dbc);

    my $form = new HTML_Table( -title => 'Custom Barcode Parameters', -width => '100%', -border => 1 );
    my @row;
    my $Class;
    my @labels;

    if ( !$frozen ) {
        $Class = alDente::Barcode::load_standard_classes( $l_count, $r_count );
        @labels = ('barcode');
        foreach my $key ( sort keys %{ $Class->{large} } ) {
            if ( $key =~ /^(l|r)_text\d$/ ) { push @labels, $key }
        }
    }
    else {
        my $barcode_config = RGTools::RGIO::Safe_Thaw( -encoded => 1, -value => $frozen );
        for my $key ( sort keys %{$barcode_config} ) {
            if ( ref $barcode_config->{$key} eq 'HASH' ) {
                push @labels, $key;
            }
        }
        $Class->{$type} = $barcode_config;
    }

    my @headers = map { subsection_heading($_) } @labels;

    my @prompts;
    my @repeat_rows;
    my %fields;
    foreach my $i ( 0 .. $#labels ) {
        my $label = $labels[$i];
        push @{ $fields{$label} }, "";
        my %Specs = %{ $Class->{$type}{$label} };
        my @keys  = keys %Specs;

        my $options;
        foreach my $key ( sort @keys ) {
            $options .= "$key: " . textfield( -name => "$label.$key", -size => 10, -value => $Specs{$key}, -force => 1 ) . '<BR>';
        }

        my @default_open;
        if ($open) {
            push @default_open, 'Advanced Options';
        }
        $headers[$i] .= create_tree( -tree => { 'Advanced Options' => $options }, -default_open => \@default_open );
        push @row, create_tree( -tree => { 'Advanced Options' => $options }, -default_open => \@default_open );
        my $value;
        $value = $data->{$label}[0] if defined $data->{$label}[0];
        push @prompts, textfield( -name => $label, -size => 20, -force => 1, -id => "$label.1", -value => $value );
        push @repeat_rows, textfield( -name => $label, -size => 20, -force => 1, -id => "$label.INDEX", -default => "''" );
    }

    my $label_format = $Class->{$type}{label_format_id} || 1;

    $form->Set_Row( \@prompts, -repeat => 0 );    ## remove repeat since it is redundant with (and interferes with AutoFill & ClearForm ...

            if ( $rows > 1 ) {
            foreach my $i ( 2 .. $rows ) {
            my @row;
            foreach my $prompt (@repeat_rows) {
            my $row = $prompt;
            $row =~ s /\.INDEX\b/\.$i/g;      ## replace index value to enable distinct element ids (for autofill)
            my $label;
            if ( $row =~ /name=\"(.*?)\"/ ) {
            $label = $1;
            }
            if ( defined $data->{$label}[ $i - 1 ] ) {
            $row =~ s/value=\".*?\"/value=\"$data->{$label}[$i-1]\"/;
            }
            push @row, $row;
            }
            $form->Set_Row( \@row );
            }
            }

            my $xls_settings;
            my $frozen_barcode = Safe_Freeze( -value => $Class->{$type}, -format => 'array', -encode => 1 );
            $xls_settings->{config}{"Type"}           = $type;
            $xls_settings->{config}{"Frozen Barcode"} = $frozen_barcode->[0];

    my $excel_download_upload;
    unless ($exclude_excel_upload) {
        $excel_download_upload = alDente::Barcode_Views::excel_download_upload( -dbc => $dbc, -type => $type, -fields => \%fields, -xls_settings => $xls_settings );
    }

### change so that default parameters are set (may be options for small / medium / large / textonly) ##
            my $printers = alDente::Tools::search_list( -name => "FK_Printer__ID", -element_name => 'Printer', -condition => "FK_Label_Format__ID=$label_format", -force => 1, -dbc => $dbc );

            my $image_path = '/' . $dbc->config('URL_dir_name') . "/images/icons/";
            $form->Set_Headers( \@headers, -paste_reference => 'name', -paste_icon => "$image_path/paste.png", -clear_icon => "$image_path/erase.jpg" );
            $output .= $form->Printout(0);

## Add autofill button ##
            my $x_list = join ',', @labels;
            my $y_list = join ',', ( 1 .. $rows );
            $output .= &vspace() . CGI::button( -name => 'AutoFill', -value => 'AutoFill', -onClick => "autofillForm(this.form, '$x_list', '$y_list')", -class => "Std" );
            $output .= &vspace() . Show_Tool_Tip( CGI::button( -name => 'ClearForm', -value => 'Clear Form', -onClick => "clearForm(this.form,'$x_list', '$y_list')", -class => "Std" ), define_Term('ClearForm') );

## Prompt to regenerate custom label form ##
            $output .= hr
                . Show_Tool_Tip( submit( -name => 'rm', -value => 'Regenerate Custom Label Form', -class => 'Std' ),
                        'This will adjust number of text fields on left and right & default label count as specified.<BR><BR>It will also re-calibrate the default positions' )
                . &hspace(20)
                . "Labels: "
                . Show_Tool_Tip( textfield( -name => 'Label_Count', -class => 'narrow-txt', -default => 1 ), 'Indicate number of labels / rows for this form' )
                . &hspace(20)
                . "Text on Left Side: "
                . Show_Tool_Tip( textfield( -name => 'Lcount', -class => 'narrow-txt', -default => $l_count ), 'number of text fields to appear on the left side of the label' )
                . &hspace(20)
                . "Text on Right Side: "
                . Show_Tool_Tip( textfield( -name => 'Rcount', -class => 'narrow-txt', -default => $r_count ), 'number of text fields to appear on the right side of the label (starting near the centre)' )
                if !$frozen;

            if ($frozen) {
                $output .= hidden( -name => "rows", -value => $rows, -force => 1 );
            }

#Still freeze standard class so that easier to update excel customization
            $output .= hidden( -name => "Frozen Config", -value => $frozen_barcode->[0], -force => 1 );
            $output .= hidden( -name => 'Barcode_Type',  -value => $type,                -force => 1 );
            $output .= hidden( -name => "label names",   -value => $name );

## Prompt for barcode generation ##
            $output .= '<hr>';

    if ($collapse_form) {
        $output .= qq(\t\t</div>\n) . qq(\t</div>\n) . qq(</div>\n);
    }

    $output .= "<B>Printer:</B>" . $printers . set_validator( 'Printer', -mandatory => 1 ) . hidden( -name => 'Label Name', -value => $type, -force => 1 ) . hidden( -name => 'cgi_application', -value => 'alDente::Barcode_App', -force => 1 );

    $output .= &vspace(5) . submit( -name => 'rm', -value => 'Preview Customized Barcode', -class => 'std', -force => 1 );
    $output .= &vspace(5) . submit( -name => 'rm', -value => 'Print Customized Barcode', -class => 'action', -onClick => "return validateForm(this.form,0,'','Printer')", -force => 1 );

            $output .= '<hr>';
            $output .= $excel_download_upload;
            $output .= end_form();

            return $output;

}

####################################################################
# 2 of 3 associated methods (build, preview, print _custom_barcode)
#
# generate preview (png) of defined barcode
#################################
sub preview_custom_barcode {
#################################
    my $self = shift;

    Message("print to png");
    $self->printpng;

    return;
}

##############################
#
# Generate barcode label
#
# Input:
#   -labels => [\%label1,\%label2...] (where %label1 = {-name=>'L1',-posx=>5,-posy=>5,-size=>20,-value=>'label1'}  (-barcode => 'code128' if barcode type).
#
#
#
#
##############################
        sub print_custom_barcode {
##############################
#
#  customized barcode maker that allows the user to create barcodes that encode different information than the label
#
        my %args = @_;

#    my $barcode_value = $args{-barcode_value};             # the value being encoded by the barcode
#    my $barcode_type = $args{-barcode_type} || 'code128';  # type of the barcode. Can do code128,code39,datamatrix,micropdf417,and qrcodebar
        my $labels     = $args{-labels};                               ## hash of individual labels including text, size, and optionally: pos_x, pos_y, format.
        my $label_name = $args{-label_name} || param('Label Name');    ## indication of standard label type (if supplied, only text required for labels)
        my $height     = $args{-height} || param('height');
        my $width      = $args{-width} || param('width');
        my $top        = $args{-top} || param('top');
        my $zero_x     = $args{-zero_x} || param('zero_x');
        my $zero_y     = $args{-zero_y} || param('zero_y');
        my $dpi        = $args{-dpi} || param('scale_DPI');
        my $preview    = $args{-preview};
        my $frozen     = $args{-frozen};
        my $use_sample = param('Use Sample Labels') || 0;
        my $printer    = param('Printer') || 'urania';
        my $repeat     = $args{-repeat} || param('RepeatX') || 1;

        my $dbc = $args{-dbc};

        my @keys = qw(name format posx posy size opts value sample style);
        if ($labels) {
##
        }
        elsif ( param('label.size') ) {
            my @sizes       = param('label.size');
            my $label_count = int(@sizes);
            my %hash;
            foreach my $key (@keys) {
                my @values  = param("label.$key");
                my @samples = param("label.sample");
                foreach my $i ( 1 .. $label_count ) {
                    my $value = $values[ $i - 1 ];
                    $value ||= $samples[ $i - 1 ] if ( $key eq 'value' && $use_sample );    ## use sample (except in the case of barcode parameter)
                        if ( $key eq 'name' ) { $value = "label.$i" }
                    $hash{$i}{"-$key"} = $value;
                }
            }
            foreach my $key ( keys %hash ) {
                push @{$labels}, $hash{$key};
            }
        }

        my $barcode;
        if ($frozen) {
            $barcode = RGTools::RGIO::Safe_Thaw( -encoded => 1, -name => 'Frozen Barcode' );
        }
        elsif ($labels) {
## each label generates a separate barcode ##
            $barcode = alDente::Barcode->new(
                    -dbc => $dbc
                    -type   => $label_name,
                    -labels => $labels,
                    -height => $height,
                    -width  => $width,
                    -zero_x => $zero_x,
                    -zero_y => $zero_y,
                    -top    => $top,
                    -dpi    => $dpi,
                    );
        }

        my $output = '';

        if ($preview) {
            $barcode->makepng( '', "/opt/alDente/www/dynamic/tmp/test_barcode.png" );

#	$barcode->printpng();
            if ( -e "/opt/alDente/www/dynamic/tmp/test_barcode.png" ) {
                $output .= "Barcode Sample: <BR>" . "<Img src='/dynamic/tmp/test_barcode.png'>.<BR>";
            }
            else {
                Message("Sorry - the current installed version of perl does not support png image generation");
            }
            $output .= create_tree( -tree => { "configuration_settings" => HTML_Dump($barcode) } );
        }
        else {

#	Message("Print Barcode");
            $barcode->makepng;
            for ( my $i = 0; $i < $repeat; $i++ ) {
                $output .= $barcode->print( -printer => $printer );
            }
        }

        return $output;
        }

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

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Barcoding.pm,v 1.96 2004/12/01 18:28:54 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
