#!/usr/bin/perl
###################################################################################################################################
# Primer.pm
#
# Class module that encapsulates a DB_Object that represents a Primer
#
# $Id: Primer.pm,v 1.35 2004/12/03 20:02:42 jsantos Exp $
###################################################################################################################################
package Sequencing::Primer;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Primer.pm - !/usr/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/bin/perl<BR>!/usr/local/bin/perl56<BR>!/usr/local/bin/perl56<BR>Class module that encapsulates a DB_Object that represents a Primer<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(alDente::Primer);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;
use Storable;
use POSIX qw(log10);

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use alDente::SDB_Defaults;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Object;
use RGTools::Conversion;
use SDB::DBIO;
use SDB::DB_Object;
use Sequencing::Primer_Order;

##############################
# global_vars                #
##############################
### Global variables
use vars qw(%Settings $User %Std_Parameters $Connection $java_bin_dir $templates_dir $bin_home);

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

############################################################
# Constructor: Takes a database handle and a primer ID and constructs a primer object
# RETURN: Reference to a Primer object
############################################################
sub new {
    my $this = shift;
    my %args = @_;

    my $dbc       = $args{-dbc} || $Connection;
    my $primer_id = $args{-primer_id};            # Primer ID of the project
    my $frozen    = $args{-frozen} || 0;          # flag to determine if the object was frozen
    my $encoded   = $args{-encoded};              # flag to determine if the frozen object was encoded
    my $class     = ref($this) || $this;

    my $self = $this->alDente::Primer::new(%args);
    bless $self, $class;
    $self->{dbc} = $dbc;

    return $self;
}

##############################
# public_methods             #
##############################

############################################################
# Subroutine: displays the primer order
# RETURN: none
############################################################
sub display_primer_order {
############################################################
    my $self          = shift;
    my %args          = @_;
    my $primer_plates = $args{-primer_plate_range};    # (Scalar) The range of primer plates that this primer order covers in dash-separated values.
    my $dbc           = $self->{dbc} || $Connection;
    my $user_id       = $dbc->get_local('user_id');

    my ($retval) = $dbc->Table_find( 'Employee', 'Employee_FullName,Email_Address', "where Employee_ID='$user_id'" );
    my ( $employee_fullname, $emp_email ) = split ',', $retval;

    # display some information about the primer order <CONSTRUCTION>
    Message("The order file will be sent to ${emp_email}\@bcgsc.ca");

    print alDente::Form::start_alDente_form( $dbc, "Primer Order", $dbc->homelink() );
    print hidden( -name => 'Primer Plate ID', -value => $primer_plates );

    # prompt user for PO, filetype, and if the order is to be split
    my $table = new HTML_Table();
    $table->Set_Title("Additional information (if applicable)");
    $table->Set_Row( [ "PO Number:", &textfield( -name => "PO", -force => 1 ) ] );

    my %type_labels = (
        'Illumina_txt' => 'Invitrogen (csv)',
        'IDT_xls'      => 'IDT (Excel)',
    );
    my @groups = @{ $dbc->get_local('groups') };
    my %group_specific_template;
    $group_specific_template{'MGC_Closure'} = { 'FG_TechD_IDT_xls' => 'FG TechD IDT (Excel)' };
    $group_specific_template{'Cap_Seq'} = { 'IDT_ASP_xls' => 'IDT ASP (Excel)', 'IDT_Sequencing_xls' => 'IDT Sequencing (Excel)', 'IDT_SeqVal_xls' => 'IDT SeqVal (Excel)', 'IDT_SeqVal_500pmole_xls' => 'IDT SeqVal 500pmole (Excel)' };
    foreach my $grp ( keys %group_specific_template ) {

        if ( grep /^$grp$/, @groups ) {
            while ( my ( $k, $v ) = each( %{ $group_specific_template{$grp} } ) ) {
                $type_labels{$k} = $v;
            }
        }
    }

    ## find the available templates based on the user's group

    ## add the group specific templates
    my @primer_order_types;
    @primer_order_types = keys %type_labels;
    $table->Set_Row( [ "File type:", &popup_menu( -name => "Filetype", -values => \@primer_order_types, -labels => \%type_labels ) ] );
    $table->Set_Row( [ "One file per plate:", &checkbox( -name => "Split", -label => '' ) ] );
    $table->Set_Row( [ '', &submit( -name => "Send Primer Email", -class => "Std" ) ] );
    print $table->Printout(0);
    print end_form();
}

############################################################
# Subroutine: send the order file to the user
# RETURN: none
############################################################
sub send_primer_email {
############################################################
    my $self          = shift;
    my %args          = @_;
    my $primer_plates = $args{-primer_plate_ids};            # (Scalar) The range of primer plates that this primer order covers in dash-separated values.
    my $po_number     = $args{-po_number};                   # (Scalar) The PO Number (if applicable)
    my $type          = $args{-type} || 'Invitrogen_xls';    # (Scalar) the type of order file to be created
    my $split         = $args{ -split };                     # (Scalar) If this is true, each plate will be its own order file.
    my $dbc           = $self->{dbc} || $Connection;
    my $user_id       = $dbc->get_local('user_id');

    my @id_array = split( ',', &resolve_range($primer_plates) );

    my ($retval) = $dbc->Table_find( 'Employee', 'Employee_FullName,Email_Address', "where Employee_ID='$user_id'" );
    my ( $employee_fullname, $emp_email ) = split ',', $retval;

    &Sequencing::Primer_Order::generate_primer_order_file( -dbc => $dbc, -primer_plate_ids => \@id_array, -split => $split, -po_number => $po_number, -type => $type, -email => $emp_email );
    Message("Sent primer order file/s to $emp_email");
}

############################################################
# Subroutine: Build the ChemistryInfo hash - maps primers to chemistry codes
############################################################
sub get_ChemistryInfo {
############################################################
    my %args = @_;
    my %Chem;
    my $Chemistry = {};
    my $Primer    = {};
    my $dbc       = $args{-dbc} || $Connection;

    #my @chemcodes = $dbc->Table_find('Chemistry_Code','Chemistry_Code_Name,FK_Primer__Name,Terminator',undef,'Distinct');
    #foreach my $cc (@chemcodes) {
    #    (my $code, my $primer, my $term) = split ',', $cc;
    #    $Chemistry->{$code} = $term;
    #    $Primer->{$code} = $primer;
    #}

    #$Chem{Chemistry} = $Chemistry;
    #$Chem{Primer   } = $Primer;

    my @chemcodes = $dbc->Table_find( 'Branch_Condition,Primer', 'FK_Branch__Code,Primer_Name', "WHERE Object_ID = Primer_ID AND Branch_Condition_Status = 'Active'" );
    foreach my $cc (@chemcodes) {
        ( my $code, my $primer ) = split ',', $cc;
        $Primer->{$code} = $primer;
    }

    $Chem{Primer} = $Primer;

    return \%Chem;
}

############################################################
# Generate a view which summarizes primer plates used for a remap
# RETURN: 1 if successful, 0 otherwise
############################################################
sub view_source_remap_primer_plates {
############################################################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $dbc = $self->{dbc} || $Connection;
    my $primer_plate_ids = $args{-primer_plate_ids};    # (Scalar) primer plate to view

    unless ($primer_plate_ids) {
        Message("ERROR: No primer plate ids provided.");
        return 0;
    }
    ## ERROR CHECK ##
    # Make sure all primer plates are remapped
    $primer_plate_ids = &Cast_List( -list => $primer_plate_ids, -to => "arrayref" );
    my $primer_plate_id_str = join( ',', @{$primer_plate_ids} );

    my @zero_count = $dbc->Table_find( "Primer_Plate_Well", "FKParent_Primer_Plate_Well__ID", "WHERE (FKParent_Primer_Plate_Well__ID = 0 OR FKParent_Primer_Plate_Well__ID IS NULL) AND FK_Primer_Plate__ID in ($primer_plate_id_str)" );

    if ( int(@zero_count) > 0 ) {
        Message("ERROR: One or more primer plates have not been remapped");
        return 0;
    }

    ## END ERROR CHECK

    my @primer_rows = $dbc->Table_find(
        'Primer_Plate as Source,Primer_Plate_Well as Source_Well,Primer_Plate_Well as Target_Well,Solution as Source_Solution,Rack as Source_Rack,Equipment as Source_Equip,Equipment as rack_equ',
        "Source.Primer_Plate_ID,Source.Primer_Plate_Name,Source.FK_Solution__ID,rack_equ.Equipment_Name,Rack_Alias as Rack_Name",
        "WHERE Source_Well.FK_Primer_Plate__ID=Source.Primer_Plate_ID AND Target_Well.FKParent_Primer_Plate_Well__ID=Source_Well.Primer_Plate_Well_ID AND Source_Solution.Solution_ID=Source.FK_Solution__ID AND FK_Rack__ID=Rack_ID AND FK_Equipment__ID=Source_Equip.Equipment_ID AND Target_Well.FK_Primer_Plate__ID in ($primer_plate_id_str) and Source_Rack.FK_Equipment__ID=rack_equ.Equipment_ID"
    );

    my %primer_info;
    foreach my $row (@primer_rows) {
        my ( $source_plate, $source_plate_name, $solution_id, $equip_name, $rack ) = split ',', $row;
        if ( defined $primer_info{$source_plate} ) {

        }
        else {
            $primer_info{$source_plate} = {
                'source_plate_name' => $source_plate_name,
                'solution_id'       => $solution_id,
                'equipment_name'    => $equip_name,
                'rack'              => $rack
            };
        }
    }

    my %primer_plate_info = $dbc->Table_retrieve( "Primer_Plate", [ 'Primer_Plate_ID', 'Primer_Plate_Name', 'FK_Solution__ID', 'Order_DateTime', 'Arrival_DateTime' ], "WHERE Primer_Plate_ID in ($primer_plate_id_str)" );
    ### set title
    # split Primer_Plate_Name into 35-character chunks
    my $name    = $primer_plate_info{Primer_Plate_Name}[0];
    my $name_br = '';
    while ( $name =~ /^(.{35})(.*)/ ) {
        $name_br .= $1 . br();
        $name = $2;
    }

    my $title = "";
    $title .= "$name_br<BR>";
    $title .= "Primer Plate $primer_plate_info{Primer_Plate_ID}[0]<BR>";
    if ( defined $primer_plate_info{FK_Solution__ID}[0] ) {
        $title .= "sol$primer_plate_info{FK_Solution__ID}[0]<BR>";
    }
    else {
        $title .= "Unassigned solution<BR>";
    }

    $title .= "<font size=2>";
    $title .= "Ordered $primer_plate_info{Order_DateTime}[0]<BR>";
    $title .= "Arrived $primer_plate_info{Arrival_DateTime}[0]<BR><BR>";
    $title .= "$rack<BR>";
    $title .= "</font>";

    my $table = new HTML_Table( -autosort => 1 );
    $table->Set_HTML_Header($html_header);
    $table->Toggle_Colour('off');
    $table->Set_Border('on');
    $table->Set_Title($title);

    $table->Set_Headers( [ 'Primer Plate Name', 'Solution ID', "Equipment", "Rack" ] );
    $table->Set_sub_title( 'Primer Plate', 2, 'mediumgreenbw' );
    $table->Set_sub_title( 'Location',     2, 'mediumredbw' );
    foreach my $primer_plate_id ( keys %primer_info ) {
        my $primer_plate_name = $primer_info{$primer_plate_id}{'source_plate_name'};
        my $equipment_name    = $primer_info{$primer_plate_id}{'equipment_name'};
        my $solution_id       = $primer_info{$primer_plate_id}{'solution_id'};
        my $rack              = $primer_info{$primer_plate_id}{'rack'};

        $table->Set_Row( [ $primer_plate_name, $solution_id, $equipment_name, $rack ] );

    }
    print $table->Printout("$alDente::SDB_Defaults::URL_temp_dir/Primer_Remap_Summary@{[timestamp()]}.html");
    $table->Printout();
    return 1;
}

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

2003-09-26

=head1 REVISION <UPLINK>

$Id: Primer.pm,v 1.35 2004/12/03 20:02:42 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
