################################################################################
#
# Sample_Sheet.pm
#
# This module handles routines specific to Sample Sheet generation for sequencing
#
################################################################################
# CVS Revision: $Revision: 1.106 $
#     CVS Date: $Date: 2004/11/19 22:29:12 $
################################################################################
package Sequencing::Sample_Sheet;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Sample_Sheet.pm - This module handles routines specific to Sample Sheet generation for sequencing

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles routines specific to Sample Sheet generation for sequencing<BR>

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
    preparess
    genss
    prompt_for_parameters
    genss
    generate_ss
    get_run_version
    check_for_list
    get_primer
    get_premix
    sample_sheets
    remove_ss
);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use Data::Dumper;

#use Storable;

##############################
# custom_modules_ref         #
##############################
use Sequencing::SDB_Status;
use alDente::Form;
use alDente::Solution;
use alDente::Library;
use alDente::Container;
use alDente::SDB_Defaults;
use alDente::Tray;
use alDente::Equipment;
use SDB::DBIO;
use alDente::Validation;
use SDB::Data_Viewer;
use SDB::CustomSettings;
use SDB::DB_Form_Viewer;
use SDB::Session;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
our ( $dbase, $homefile, $homelink, $user, $equipment, $equipment_id );
our ( $parents,  $current_plates, $plate_set );
our ( $plate_id, $testing,        $padding );
our (@libraries);
our ($MenuSearch);    ## from Barcode.pm
our ( $genss_script, $trace_link );

#our ($scanner_mode, $barcode, $last_page, $project_dir, $fasta_dir, $sssdir, $request_dir);
our ( $scanner_mode, $barcode, $last_page, $fasta_dir, $sssdir, $request_dir );
use vars qw($Stats_dir $project_dir);
use vars qw(%Defaults %Settings);
use vars qw($login_name $login_pass $trace_level $Sess);
use vars qw($Connection);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
# Global Variables
# Modular Variables
my $WATER_LIB = 'Water';    ### Define the library name that is used for water runs

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#############################
#  Sample Sheet Routines
#############################

##################
sub preparess {
##################
    # Prepare Sample Style Sheets using 'sequence.pl'
    # set default values
    my $dbc        = shift;
    my $barcode    = shift;
    my $ForceInput = shift;

    $dbc->session->clear_all_messages();

    $equipment_id ||= get_aldente_id( $dbc, $barcode, 'Equipment' ) || param('Equipment_ID');

    unless ($scanner_mode) { print h2("Prepare Sample Sheet"); }
    unless ( $equipment_id =~ /[1-9]/ ) { Message("No machine id specified ($equipment-$equipment_id"); return 0; }
    unless ($equipment) { ($equipment) = $Connection->Table_find( 'Equipment', 'Equipment_Name', "WHERE Equipment_ID = $equipment_id" ) }

    ### Ensure Sequencer Defaults have been set ###
    my ($defaults) = $Connection->Table_find( 'Machine_Default', 'count(*)', "where FK_Equipment__ID = $equipment_id" );
    unless ($defaults) {
        $dbc->error("Error: Machine Defaults not set yet - please update before continuing or see administrator");
        return 0;
    }

    my ( $sols, $dmatrix, $dbuffer, $dprimer, $dpremix );

    #
    # This (block below) should NOT be allowed once buffers,matrix and primers are being tracked.
    #

    if ( $barcode =~ /sol/ ) {    ### before tracking matrix/buffers for equipment, allow users to scan for sample sheet creation
        $sols = alDente::Validation::get_aldente_id( $dbc, $barcode, 'Solution' );
        if ($sols) {
            ($dmatrix) = $Connection->Table_find( 'Solution', 'Solution_ID', "where Solution_ID in ($sols) and Solution_Type = 'Matrix'" );
            ($dbuffer) = $Connection->Table_find( 'Solution', 'Solution_ID', "where Solution_ID in ($sols) and Solution_Type = 'Buffer'" );
            $dprimer = join ',', $Connection->Table_find( 'Solution', 'Solution_ID', "where Solution_ID in ($sols) and Solution_Type = 'Primer' Order by Solution_Started desc" );
        }
    }
    unless ( $dmatrix =~ /[1-9]/ ) { $dmatrix = param('Last Matrix') || '' }
    unless ( $dbuffer =~ /[1-9]/ ) { $dbuffer = param('Last Buffer') || '' }
    unless ( $dprimer =~ /[1-9]/ ) { $dprimer = param('Last Primer') || '' }

    ### Get buffer/matrix from Equipment Maintenance procedures... ###
    unless ( $dmatrix =~ /[1-9]/ ) {
        ($dmatrix) = &alDente::Equipment::get_MatrixBuffer( $dbc, 'Matrix', $equipment_id );

        #      Message("<B>Found Matrix: Sol$dmatrix</B>",$testing);
    }
    unless ( $dbuffer =~ /[1-9]/ ) {
        ($dbuffer) = &alDente::Equipment::get_MatrixBuffer( $dbc, 'Buffer', $equipment_id );

        #      Message("<B>Found Buffer: Sol$dbuffer</B>",$testing);
    }

    unless ( $dmatrix =~ /[1-9]/ ) {
        Message("Matrix not found for $equipment");
        $dmatrix = '';
        return 0;
    }
    unless ( $dbuffer =~ /[1-9]/ ) {
        Message("Buffer not found for $equipment ($dbuffer)");
        $dbuffer = '';
        return 0;
    }

    ### get names for matrix/buffer (for feedback only) ###
    ( my $dmatrix_name ) = $Connection->Table_find( 'Solution left join Stock on FK_Stock__ID=Stock_ID, Stock_Catalog', 'Stock_Catalog_Name', "where Solution_ID = $dmatrix AND FK_Stock_Catalog__ID = Stock_Catalog_ID " );
    ( my $dbuffer_name ) = $Connection->Table_find( 'Solution left join Stock on FK_Stock__ID=Stock_ID, Stock_Catalog', 'Stock_Catalog_Name', "where Solution_ID = $dbuffer AND FK_Stock_Catalog__ID = Stock_Catalog_ID " );

    my $condition;
    my $vector;

    my $dplate_id;
    my $lib;
    my @libs = ();
    my $psizes;
    if ($barcode) {
        $dplate_id = &get_aldente_id( $dbc, $barcode, 'Plate' );
        ($psizes) = $Connection->Table_find( 'Plate,Plate_Format', 'Wells', "where FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID in ($dplate_id)", 'Distinct' );
        unless ( $dplate_id =~ /\d/ ) { Message("No valid Plate"); return 0; }
        foreach my $plate ( split ',', $dplate_id ) {
            ( my $nextlib ) = $Connection->Table_find( 'Plate', 'FK_Library__Name', "where Plate_ID=$plate" );
            push( @libs, $nextlib );
        }
        $lib = $libs[0];
    }
    else { $lib = param('Library.Library_Name'); }

    ########## CHECKING FUNDING SOURCE #############
    if ( $dbc->package_active('Funding_Tracking') ) {
        require alDente::Funding;
        my $funding = alDente::Funding->new( -dbc => $dbc );
        unless ( $funding->validate_active_funding( -plates => $dplate_id ) ) {
            $dbc->session->warning("Invalid Funding Source");
            return 0;
        }
    }

    if ( $barcode =~ /\d/ ) { $current_plates = $dplate_id; }    ## update Current Plates..

    my @Plate_ID = split ',', $dplate_id;
    my $plates = scalar(@Plate_ID) || 1;

    my ($seq_info)
        = $Connection->Table_find( 'Machine_Default,Sequencer_Type', 'Sequencer_Type_ID,Sequencer_Type_Name,Default_Terminator,Sliceable,Capillaries,By_Quadrant', "where FK_Sequencer_Type__ID=Sequencer_Type_ID AND FK_Equipment__ID = $equipment_id" );

    my ( $seq_type_id, $seq_type, $dterm, $sliceable, $capillaries, $by_quadrant ) = split ',', $seq_info;
    unless ( $sliceable   =~ /yes/i ) { $sliceable   = 0 }
    unless ( $by_quadrant =~ /yes/i ) { $by_quadrant = 0 }

    if ( scalar(@Plate_ID) != scalar(@libs) ) { Message( "Invalid Plate Listed in: $dplate_id. ($barcode)" . join ',', @libs ); return 0; }

    #
    # Get Primer information if plates have been entered...
    #
    my @Primer;
    my @Primer_name;
    my @Premix;
    my @Premix_name;

    ### Standard variables to track by run ###
    my @DNAVolume;
    my @TotalPrepVolume;
    my @ReactionVolume;
    my @ResuspensionVolume;
    my @BrewMixConcentration;

    my %Emessage;
    my %CVs;    ### generate list of chemistry versions to be used.
    for my $thisplate ( 1 .. $plates ) {
        my $testlib = 0;
        if ( $libs[ $thisplate - 1 ] =~ /\bwater\b/i ) { $testlib = 1; }    ## flag water runs to indicate test library (like Water)
        my %BrewDetails = &get_brew( $dbc, $Plate_ID[ $thisplate - 1 ], -testlib => 1 );

        ( $Primer[ $thisplate - 1 ], $Primer_name[ $thisplate - 1 ] ) = &get_primer( $dbc, $Plate_ID[ $thisplate - 1 ] );
        ( $Premix[ $thisplate - 1 ], $Premix_name[ $thisplate - 1 ] ) = &get_premix( $dbc, $Plate_ID[ $thisplate - 1 ] );
        $DNAVolume[ $thisplate - 1 ]            = $BrewDetails{DNA};
        $TotalPrepVolume[ $thisplate - 1 ]      = $BrewDetails{TotalPrepVolume};
        $ReactionVolume[ $thisplate - 1 ]       = $BrewDetails{ReactionVolume};
        $ResuspensionVolume[ $thisplate - 1 ]   = $BrewDetails{ResuspensionVolume};
        $BrewMixConcentration[ $thisplate - 1 ] = $BrewDetails{BrewMixConcentration};

        ( $Premix[ $thisplate - 1 ], $Premix_name[ $thisplate - 1 ] ) = &get_premix( $dbc, $Plate_ID[ $thisplate - 1 ] );

        if ( $Premix_name[ $thisplate - 1 ] =~ /(.*) v([\d\.]+) premix/i ) {
            my $type    = $1;
            my $version = $2;
            if   ( $type =~ /ET/i ) { $CVs{"ETv$version"} = 1; }
            else                    { $CVs{"BDv3"}        = 1; }
        }

        if ($testlib) { $CVs{"BDv3"} = 1; }    ## <CONSTRUCTION> - establish default version (?) if Dye set required .. (?)
        else {
            unless ( $Primer[ $thisplate - 1 ] =~ /[1-9]/ || $testlib ) {
                $dbc->warning( "Primer not found for Pla" . $Plate_ID[ $thisplate - 1 ] );
                $dprimer = '';
                &main::leave();
            }
        }

        # check if primer is suggested
        if ( $Primer_name[ $thisplate - 1 ] ) {
            my @suggested = $Connection->Table_find( "LibraryApplication,Primer,Plate",
                "LibraryApplication_ID", "WHERE LibraryApplication.FK_Library__Name=Plate.FK_Library__Name AND Object_ID = Primer_ID and Primer_Name='$Primer_name[$thisplate-1]' AND Plate_ID=$Plate_ID[$thisplate-1]" );
            unless ( @suggested || $testlib ) {
                $dbc->warning("Primer $Primer_name[$thisplate-1] is not a suggested primer for $lib");
            }
        }

        ### ok for now.. ###
        unless ( $Premix[ $thisplate - 1 ] =~ /[1-9]/ || $testlib ) {
            $dbc->error( "Premix not found for Plate $thisplate (Pla" . $Plate_ID[ $thisplate - 1 ] . ")", "Water runs only!" );

            #	  $dterm = 'Water';
            $dpremix = '';

            #	  return 0;  ## this one is fatal...
        }
    }
    my $cv;    #### chemistry version (for now require it to be unique single value for batch ####
    my @cvs = keys %CVs;
    if (@cvs) { $cv = $cvs[0]; }
    else      { $dbc->warning("Undefined Chemistry Version"); }
    if ( int(@cvs) > 1 ) { $dbc->warning("Multiple Premix versions found"); return 0; }

    $dprimer = $Primer[0];

    #
    # Get vector
    #
    if ( $lib =~ /(.*):/ ) { $lib = $1; }
    unless ( param('No Vector') ) {
        $vector = join ',', $Connection->Table_find( 'LibraryVector,Vector,Vector_Type', 'Vector_Type_Name', "where FK_Library__Name=\"$lib\" and FK_Vector__ID = Vector_ID and FK_Vector_Type__ID = Vector_Type_ID" );

    }

######## Retrieve Standard Defaults #################
    my $option_condition = "(FK_Equipment__ID= $equipment_id OR SS_Option.FK_Equipment__ID is NULL OR SS_Option.FK_Equipment__ID=0)";
    my %SS_Defaults      = &Table_retrieve(
        $dbc,
        'SS_Config left join SS_Option on SS_Option.FK_SS_Config__ID=SS_Config_ID',
        [ 'SS_Option_ID as PID', 'SS_Option_Value as Value', 'FKReference_SS_Option__ID as Reference', 'SS_Option_Alias as Alias', 'SS_Config_ID as Config', 'SS_Prompt as Type', 'SS_Alias', 'SS_Default', 'SS_Track', 'SS_Option_Status' ],
        "where SS_Prompt not like 'No' AND $option_condition AND FK_Sequencer_Type__ID = '$seq_type_id' AND (SS_Option_ID is null OR SS_Option_Status like 'Active' or SS_Option_Status like 'Default' or SS_Option_Status like 'AutoSet') Order by SS_Section,SS_Order,SS_Option_Order"
    );
    my %Options;
    my $index = 0;
    while ( defined $SS_Defaults{Config}[$index] ) {
        my $CID = $SS_Defaults{Config}[$index];
        if ( $SS_Defaults{Reference}[$index] =~ /[1-9]/ ) { $index++; next; }    ### uses reference from other parameter

        unless ( grep /^$CID$/, @{ $Options{Cids} } ) {
            push( @{ $Options{Cids} }, $CID );                                   ### ordered list
        }
        $Options{$CID}->{Type} = $SS_Defaults{Type}[$index];                     ### radio or text if applicable
        $Options{$CID}->{Count}++;                                               ### number of options
        $Options{$CID}->{Title}   = $SS_Defaults{SS_Alias}[$index];              ### Alias (prompt)
        $Options{$CID}->{Default} = $SS_Defaults{SS_Default}[$index];            ### Default value
        $Options{$CID}->{Track}   = $SS_Defaults{SS_Track}[$index];              ### Foreign key to be stored

        #### Set Standard Brew Mix Parameters #####
        $_ = $Options{$CID}->{Track};
        if ( $Options{$CID}->{Track} =~ /DNA_Volume/ ) {
            $Options{$CID}->{Default} = $DNAVolume[ $Options{$CID}->{Count} - 1 ];
        }
        elsif ( $Options{$CID}->{Track} =~ /Total_Prep_Volume/ ) {
            $Options{$CID}->{Default} = $TotalPrepVolume[ $Options{$CID}->{Count} - 1 ];
        }
        elsif ( $Options{$CID}->{Track} =~ /Reaction_Volume/ ) {
            $Options{$CID}->{Default} = $ReactionVolume[ $Options{$CID}->{Count} - 1 ];
        }
        elsif ( $Options{$CID}->{Track} =~ /Resuspension_Volume/ ) {
            $Options{$CID}->{Default} = $ResuspensionVolume[ $Options{$CID}->{Count} - 1 ];
        }
        elsif ( $Options{$CID}->{Track} =~ /BrewMix_Concentration/ ) {
            $Options{$CID}->{Default} = $BrewMixConcentration[ $Options{$CID}->{Count} - 1 ];
        }

        my $status = $SS_Defaults{SS_Option_Status}[$index];
        if ( $SS_Defaults{SS_Option_Status}[$index] =~ /def/i ) {
            $Options{$CID}->{Option_Default} = $SS_Defaults{Value}[$index];
        }

        #### Custom Hard-coded special cases ####
        # (Force_Default forces defaults based on other info)
        # (Force_Value forces value for CID and suppresses prompt)
        #
        if ( $cv && ( $SS_Defaults{SS_Alias}[$index] eq 'CV' ) ) { $Options{$CID}->{Force_Value} = $cv; }    ### set chemistry version
        if ( ( $psizes =~ /96/ ) && ( $SS_Defaults{SS_Alias}[$index] =~ /Order/ ) && ( $Options{$CID}->{Force_Default} =~ /^[1234]{2,4}$/ ) ) {
            $Options{$CID}->{Default} = '1';                                                                 ### single 96-well plate (Order = '1')
        }
        ### for radio buttons...
        if ( $Options{$CID}->{Type} =~ /radio/i ) {
            push( @{ $Options{$CID}->{Values} }, $SS_Defaults{Value}[$index] );
            $Options{$CID}->{Labels}->{ $SS_Defaults{Value}[$index] } = $SS_Defaults{Alias}[$index];         ### labels for values
        }

        #, $SS_Defaults{Alias}[$index]);  ### add another option..
        $index++;
    }

    #    my $default_FP;
    #    if ($plates==4) {$default_FP = 1;} ### set foil piercing ON if 384-well

    if ( @{ $dbc->errors } ) {
        Message("Aborted");
        Message( @{ $dbc->errors } );
        return;
    }

    ########################
    #  Equipment settings
    ########################
    #

    my %Parameters = Set_Parameters();
    $Parameters{Method} = 'POST';    ### do not allow back button...
    print &alDente::Form::start_alDente_form( $dbc, 'SampleSheet', $dbc->homelink(), \%Parameters ),

        #    hidden(-name=>'Barcode',-value=>"$barcode",-force=>2),
        hidden( -name => 'Equipment', -force => 1, -value => $equipment, -force => 1 ), hidden( -name => 'Equipment_ID', -force => 1, -value => $equipment_id, -force => 1 ),
        hidden( -name => 'Last Page', -force => 1, -value => 'Prepare Sample Sheet', -force => 1 );

    my $links = "LINK LINK LINK";
    if ($scanner_mode) { $links = "LINK"; }    ### no popdown menu for scanners...

    foreach my $index ( 1 .. $plates ) {
        my $thisprimer = $Primer[ $index - 1 ];

        ##### Plate #######
        my $defPlate;
        if ( defined $Plate_ID[ $index - 1 ] ) {
            $defPlate = "Pla" . $Plate_ID[ $index - 1 ];
        }
        my $Plate_Label = SDB::DBIO::get_FK_info( $dbc, 'FK_Plate__ID', $Plate_ID[ $index - 1 ] );

        print hidden( -name => "Plate ID$index", -value => $defPlate, -force => 1 ) . hidden( -name => "Primer$index", -value => "Sol$thisprimer", -force => 1 );

        my $this_primer_name;
        if ( $Primer_name[ $index - 1 ] ) {
            $this_primer_name = $Primer_name[ $index - 1 ];
            unless ($scanner_mode) { $this_primer_name .= " (Sol$Primer[$index-1])"; }
        }
        else {
            $this_primer_name = '?';
        }

        #### Premix Parameters ####
        my $this_premix_name;
        if ( $Premix_name[ $index - 1 ] ) {
            $this_premix_name = $Premix_name[ $index - 1 ];
            unless ($scanner_mode) { $this_premix_name .= " (Sol$Premix[$index-1]) "; }
        }
        else {
            $this_premix_name = '?';
        }

        print "<div class=small> <font color=red>$Plate_Label</font>, Primer: <font color=red>$this_primer_name</font>, Premix: <font color=red>$this_premix_name</font>" . lbr;
        print
            "DNA Vol: <font color=red>$DNAVolume[$index-1]</font>, Total Prep Vol: <font color=red>$TotalPrepVolume[$index-1]</font>, Rxn Vol: <font color=red>$ReactionVolume[$index-1]</font>, Resusp Vol: <font color=red>$ResuspensionVolume[$index-1]</font>, BMC: <font color=red>$BrewMixConcentration[$index-1]</font> </div>";

        unless ( $DNAVolume[ $index - 1 ] )            { $Emessage{DNA_Vol}++ }
        unless ( $ResuspensionVolume[ $index - 1 ] )   { $Emessage{Resusp_Vol}++ }
        unless ( $ReactionVolume[ $index - 1 ] )       { $Emessage{Rxn_Vol}++ }
        unless ( $BrewMixConcentration[ $index - 1 ] ) { $Emessage{BMC}++ }
        unless ( $TotalPrepVolume[ $index - 1 ] )      { $Emessage{Prep_Vol}++ }

    }
    if (%Emessage) {
        my @keys = keys %Emessage;
        $dbc->warning("Missing: @keys (update field(s) below)");
    }

    #
    # Matrix/Buffer MUST be preset...
    #
    print hidden( -name => 'Matrix', -value => $dmatrix ), hidden( -name => 'Buffer', -value => $dbuffer ), hidden( -name => 'CV', -value => $cv ), br();

    print "<span class=small>", "<B>Matrix: Sol$dmatrix - $dmatrix_name</B>", br(), "<B>Buffer: Sol$dbuffer - $dbuffer_name</B>", br();

    print "<B>Terminator:</B> ";
    my @unique_libs = @{ unique_items( \@libs ) };
    if ( $lib =~ /^$WATER_LIB$/i && scalar(@unique_libs) == 1 ) {    ### Water runs
        $dterm = 'Water';
        print radio_group( -name => 'Terminator', -value => ['Water'], -default => $dterm, -force => 1 );
    }
    else {
        print radio_group( -name => 'Terminator', -value => [ get_enum_list( $dbc, 'Sequencer_Type', 'Default_Terminator' ) ], -default => $dterm, -force => 1 );
        print lbr . "(Terminator automatically set to 'Water' for water plates.)";
    }
    print lbr;

    print "<B>Status:</B>";
    if ( $lib =~ /^$WATER_LIB$/i && scalar(@unique_libs) == 1 ) {    ### Water runs are for sure Test runs
        print radio_group( -name => 'Run Status', -values => ['Test'], -default => 'Test', -force => 1 );
    }
    else {
        print radio_group( -name => 'Run Status', -values => [ 'Test', 'Production', '?' ], -default => '?', -force => 1 );
        print lbr . "(Run Status automatically set to 'Test' for water plates.)";
    }
    print hidden( -name => 'SS Plate', -value => $dplate_id ) . lbr;

    ### check for dpremix as well ?
    unless ( $dprimer =~ /[1-9]/ ) {
        print "<B>Primer:</B>";
        if ( $lib =~ /^$WATER_LIB$/i && scalar(@unique_libs) == 1 ) {    ### Water runs
            print radio_group( -name => 'Non Primer', -values => [ 'OK', 'Custom', 'None' ], -default => 'None', -force => 1 ), &vspace();
        }
        else {
            print radio_group( -name => 'Non Primer', -values => [ 'OK', 'Custom', 'None' ], -default => 'OK', -force => 1 ), &vspace();
        }
    }

    prompt_for_parameters( $plates, \%Options, 'radio' );

    print hidden( -name => 'Confirmation', -value => 'Generate Sample Sheet' );
    print submit( -name => 'Generate Sample Sheet', -class => 'Action' ), &vspace();

    #
    # Separate Sliceable and Quadrant specifications (may be either or/and)
    #
    if ($sliceable) {
        if ($capillaries) {
            my $slices = 96 / $capillaries;
            print "Slice(s): " . checkbox_group( -name => 'Slices', -values => [ 1 .. $slices ], -checked => 1 ) . '<BR>' . "<B>(Must be consecutive - Cannot skip slice(s) ($psizes)</B><BR>";
        }
        else {
            $dbc->error("Error: Number of capillaries undefined ($sliceable:$capillaries) - please check with administrator");
        }
    }

    if ($by_quadrant) {
        if ( $psizes > 96 ) {
            print "Quadrant(s): " . checkbox_group( -name => 'Quadrants_Used', -values => [ 'a', 'b', 'c', 'd' ], -checked => 1 ) . lbr;
        }
    }

    print "Comments: " . textfield( -name => 'Comments', -size => 20, -force => 1, -default => "" ) . lbr . "Overwrite Version #:" . textfield( -name => 'Version', -size => 3 ) . lbr . "(enter only to overwrite SS version)";

    ################################
    # Defaults
    ################################

    print h2("Default Settings...");
    print "<span class=small>(May enter comma-delimited list of $plates values if different)</span><P>";

    prompt_for_parameters( $plates, \%Options, 'text' );
    prompt_for_parameters( $plates, \%Options, 'default' );

    #print submit(-name=>'Run',-value=>'Back to Sequencer options',-class=>'Std'),&vspace(),
    print submit( -name => 'Cancel', -value => 'Cancel', -class => 'Std' ), "\n</FORM>";

    $last_page = "Prepare Sample Sheet";

    return 1;
}

###############################
sub prompt_for_parameters {
###############################
    my $plates   = shift || 1;
    my $opt      = shift;
    my $showtype = shift || '';
    my $dbc      = $Connection;
    my %Options  = %{$opt};

    my $homelink = $dbc->homelink();

    unless ( %Field_Info && defined $Field_Info{SequenceRun} ) { &SDB::DBIO::initialize_field_info( $dbc, 'SequenceRun' ); }    ### fills in %Field_Info..

    unless ( defined $Options{Cids} ) { return; }

    my @cids = @{ $Options{Cids} };
    unless (@cids) { return; }

    my $cellpadding = 2;
    my $cellspacing = 2;
    if ($scanner_mode) { $cellpadding = 0; $cellspacing = 0; }

    print "<Table cellpadding=$cellpadding cellspacing = $cellspacing class=small>";
    foreach my $CID (@cids) {
        my $title   = $Options{$CID}->{Title};
        my $type    = $Options{$CID}->{Type};
        my $count   = $Options{$CID}->{Count};
        my $default = $Options{$CID}->{Force_Default} || $Options{$CID}->{Default} || $Options{$CID}->{Option_Default} || 0;

        my $track = $Options{$CID}->{Track};
        my $force = $Options{$CID}->{Force_Value};

        ### handle radio buttons..
        my @values;
        my %labels;

        unless ( $type =~ /$showtype/i ) { next; }    ### only show those requested...

        if ( $showtype =~ /default/i ) {
            my $value = Extract_Values( [ $force, $default ] );
            print "<TR><TD><B>"
                . hidden( -name => "SS_Option_$CID",       -value => $value )
                . hidden( -name => "SS_Option_Title_$CID", -value => $title )
                . &Link_To( $homelink, $title, "&Info=1&Table=SS_Option&Field=FK_SS_Config__ID&Like=$CID", $Settings{LINK_COLOUR}, ['newwin'] )
                . ":</B></TD><TD>$value</TD></TR>";
            next;
        }

        if ( $type =~ /radio/i ) {
            if ( $count < 2 ) {    ### set single value option ###
                print "<TR><TD><B>"
                    . hidden( -name => "SS_Option_$CID",       -value => $default )
                    . hidden( -name => "SS_Option_Title_$CID", -value => $title )
                    . &Link_To( $homelink, $title, "&Info=1&Table=SS_Option&Field=FK_SS_Config__ID&Like=$CID", $Settings{LINK_COLOUR}, ['newwin'] )
                    . ":</B></TD><TD>$default</TD></TR>";
                next;              ### skip prompt if only one option
            }
            else {
                @values = @{ $Options{$CID}->{Values} };
                %labels = %{ $Options{$CID}->{Labels} };
            }
        }

        my $csize   = 40;          ### size of textfield
        my $span    = $plates;     ### span all columns if more than one...
        my $columns = 1;
        if ( defined $Field_Info{SequenceRun}{$track} && ( $showtype =~ /text/i ) ) {
            $columns = $plates;    ### add column for each plate
            $csize   = 10;         ### reduce text field size
            $span    = 1;          ### set column span to each plate
        }

        print "<TR><TD><B>";
        print &Link_To( $homelink, $title, "&Info=1&Table=SS_Option&Field=FK_SS_Config__ID&Like=$CID", $Settings{LINK_COLOUR}, ['newwin'] );
        print ":</B>" . hidden( -name => "SS_Track_$CID", -value => $track, -force => 1 ) . "</TD>";

        foreach my $column ( 1 .. $columns ) {
            my $index = $column - 1;
            print "<TD colspan=$span>\n";
            if ( $type =~ /text/i ) {
                print textfield( -name => "SS_Option_$CID", -size => $csize, -default => $default, -force => 1 ) . hidden( -name => "SS_Option_Title_$CID", -value => $title );
            }
            elsif ( $showtype =~ /radio/i ) {    #### multiple values only for Text fields...
                print radio_group( -name => "SS_Option_$CID", -values => \@values, -labels => \%labels, -default => $default, -force => 1 ) . hidden( -name => "SS_Option_Title_$CID", -value => $title );
            }
            print "</TD>";
        }
        print "</TR>";
    }

    print "</Table>";
    my @keys = keys %{ $Field_Info{Run} };

    return;
}

#########################################
# Updates references to run, batch, and hidden settings using references
#########################################
sub update_batch_settings {
#########################################
    my %args                 = @_;
    my $dbc                  = $args{-dbc} || $Connection;
    my $input_ref            = $args{-input};
    my $plates               = $args{-plates};
    my $equipment_id         = $args{-equipment_id};
    my $track_run_details    = $args{-track_run_details};
    my $Track_Run_Attributes = $args{-Track_Run_Attributes};

    my %input = %{$input_ref};
    foreach my $name ( keys %input ) {
        if ( $name =~ /SS_Option_(\d+)/ ) {
            my $id = $1;
            my $name = $input{"SS_Option_Title_$id"}[0] || "cid$id";

            my $track  = $input{"SS_Track_$id"}[0] || '';
            my @values = @{ $input{"SS_Option_$id"} };
            my $value  = $values[0] if ( defined $values[0] );
            next unless ($track);

            my %run_details;
            $run_details{$track} = $value;

            my $equip_cond = "(FK_Equipment__ID=$equipment_id OR FK_Equipment__ID IS NULL OR FK_Equipment__ID = 0)";
            #### also set values for other parameters referencing this same parameter...

            my ($ref) = $Connection->Table_find( 'SS_Option', 'SS_Option_ID', "WHERE FK_SS_Config__ID = $id AND SS_Option_Value = '$value'" );
            if ( $ref =~ /[1-9]/ ) {
                my @references = $Connection->Table_find( 'SS_Option left join SS_Config on FK_SS_Config__ID=SS_Config_ID', 'SS_Track,SS_Option_Value', "where FKReference_SS_Option__ID = $ref AND $equip_cond" );

                # override value
                foreach my $row (@references) {
                    my ( $alias, $pvalue ) = split ',', $row;
                    $run_details{$alias} = $pvalue;
                }
            }

            foreach my $key ( keys %run_details ) {
                my $val = $run_details{$key};

                my $listed = 0;

                if ( defined $val && defined $Field_Info{SequenceRun}{$key} ) {
                    foreach my $plate ( 1 .. $plates ) {
                        my $index = $plate - 1;
                        $track_run_details->{$plate}{$key} = $val || $values[$index];
                    }
                }
                else {
                    $Track_Run_Attributes->{$key} = $val;
                }
            }
        }
    }

}

##############
sub genss {
##############
    #    Generate Sample Style Sheet using 'genss.pl'
    #    my $plates = shift;  ### number of plates sequenced together (4 for 384
    #
    my %args = &filter_input( \@_, -args => 'dbc,plate_id,equipment_id' );
    my $dbc = $args{-dbc} || $Connection;
    my $plate_list = $args{-plate_id};    #### list of plates to be sequenced in batch
    $equipment_id ||= $args{-equipment_id};    #### Equipment ID for run batch
    my $run_status     = $args{-run_status} || param('Run Status');
    my $external_run   = $args{-external}   || 0;
    my $quadrants_used = $args{-quadrants}  || 'abcd';
    my $now            = $args{-timestamp}  || &date_time();
    my $user_id = $dbc->get_local('user_id');

    my $homelink = $dbc->homelink();

    $dbc->session->clear_all_messages();

    foreach my $table ( 'Run', 'RunBatch', 'SequenceRun' ) {
        unless ( %Field_Info && defined $Field_Info{$table} ) { &SDB::DBIO::initialize_field_info( $dbc, $table ); }    ### fills in %Field_Info..
    }

### Equipment Info ###
    my %Equipment_info = &Table_retrieve( $dbc, 'Equipment,Machine_Default,Sequencer_Type', [ 'Equipment_Name', 'SS_Extension' ], "where FK_Sequencer_Type__ID=Sequencer_Type_ID AND FK_Equipment__ID=Equipment_ID AND Equipment_ID = $equipment_id" );
    my $ssext          = $Equipment_info{SS_Extension}[0];
    my $equipment      = $Equipment_info{Equipment_Name}[0];

    my @given_plates = ();
    my $given_number = 0;
    if ($plate_list) {
        $plate_list = &get_aldente_id( $dbc, $plate_list, 'Plate' );
        unless ( $plate_list =~ /\d/ ) {
            Message("No valid Plates Entered ($plate_list).");
            return 0;
        }
        @given_plates = split ',', $plate_list;
        $given_number = scalar(@given_plates);
    }

    my $plate_num;
    my $library;
    my $quadrant;

    my $test_run;
    my $select_wells;

    my $comments = param('Comments') || '';

    # check if the plate is active. If it is not, prevent the generation of a sample sheet

    my $plate_status_list = join ',', $Connection->Table_find( "Plate", "Plate_Status", "WHERE Plate_ID in ($plate_list)", 'distinct' );
    if ( $plate_status_list !~ /^Active$/ && !$external_run ) {
        Message("Invalid Plate Status! Please set all plates to Active");
        return 0;
    }

    my $convert_96x4_to_384 = 0;
    my $Pformat_size        = join ',', $Connection->Table_find( 'Plate,Plate_Format', 'Wells', "where FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID in ($plate_list)", 'distinct' );
    my $Psize               = join ',', $Connection->Table_find( 'Plate', 'Plate_Size', "where Plate_ID in ($plate_list)", 'distinct' );

    if ( $Pformat_size =~ /,/ ) { Message("Inconsistent Plate Formats($Pformat_size) !"); return 0; }
    elsif ( $Psize =~ /,/ ) { Message("Inconsistent Plate Sizes !"); return 0; }

    my $Run_format;

    if ( $Pformat_size =~ /384/ ) {
        if ( $Psize =~ /384/ ) {
            $Run_format = '384';
        }    ## translate 96 to 384 format
        else {
            $convert_96x4_to_384 = 1;
            $Run_format          = '96x4';
        }
    }
    elsif ( $Pformat_size =~ /96/ ) {
        $Run_format = '96';
    }
    elsif ( $Pformat_size =~ /16/ ) {
        $Run_format = '16xN';
    }
    else { Message("No Well Format Size detected ?"); return 0; }

    Message("Generating $Run_format format SS");

    ### make sure all the data is available... ###

    if    ( $run_status =~ /Test/ )       { $test_run = 1; }
    elsif ( $run_status =~ /Production/ ) { $test_run = 0; }
    else                                  { Message("Please choose 'Test' or 'Production'"); return 0; }

    my @Primer;
    my @Buffer;
    my @Matrix;
    my $primers = 0;
    my @Primer_name;
    my @Label;
    my @Library;
    my @Plate;

    my $lastprimer;
    my $lastbuffer;
    my $lastmatrix;

    my $lastPrimerName;

    my $plate  = 1;
    my $escape = 0;

    my %plateids;

    #### repeat this for each Plate in Batch.. ####
    while ( ( defined param("Plate ID$plate") ) || ( defined param("Plate Ref$plate") ) || ( $given_number >= $plate ) ) {
        ########## Plate Information...
        my $thisplate = param("Plate ID$plate") || param("Plate Ref$plate") || $given_plates[ $plate - 1 ];

        # $Plate[$plate-1] = &get_aldente_id($dbc,$thisplate,'Plate');

        $Plate[ $plate - 1 ] = &get_aldente_id( $dbc, $thisplate, 'Plate', 1 );
        my ($platepos) = $Connection->Table_find( "Plate_Tray", "Plate_Position", "WHERE FK_Plate__ID=$Plate[$plate-1]" );
        $plateids{$plate} = $platepos;

        if ( $Plate[ $plate - 1 ] =~ /,/ ) {
            Message("Only one Plate allowed in Plate field");
            $escape = 1;
            last;
        }

        ( my $found ) = $Connection->Table_find( 'Plate,Library_Plate', 'Plate_Number,FK_Library__Name,Plate.Parent_Quadrant', "WHERE Plate_ID=FK_Plate__ID AND Plate_ID=$Plate[$plate-1]" );
        ( $plate_num, $library, $quadrant ) = split ',', $found;
        $Library[ $plate - 1 ] = $library;

        # sanity check - if quadrant is 0, then set quadrant to ''
        $quadrant = '' unless ( $quadrant =~ /[a-dA-D]/ );
        $Label[ $plate - 1 ] = "$library-$plate_num$quadrant";

        my $testlib = 0;
        if ( $library =~ /\bwater\b/i ) { $testlib = 1 }    ## Flag Water Library runs as simply test runs

        my ( $primer_id, $primer_name ) = &get_primer( $dbc, $Plate[ $plate - 1 ] );
        my ( $premix_id, $premix_name ) = &get_premix( $dbc, $Plate[ $plate - 1 ] );
        ######### get Primer Name.. ############
        $Primer_name[ $plate - 1 ] = $primer_name;

        if ( $Primer_name[ $plate - 1 ] ne $lastPrimerName ) {
            $primers++;
        }
        $lastPrimerName = $Primer_name[ $plate - 1 ];

        ####### generate error message if not found... #######

        unless ( $primer_id =~ /[1-9]/ || $testlib || $external_run ) {
            $dbc->error( "Primer not found for Pla$Plate[$plate-1]", "(select Custom/None if applicable)" );
            $escape = 1;
            last;
        }
        unless ( $premix_id =~ /[1-9]/ || $testlib || $external_run ) {
            $dbc->error("Premix not found for Pla$Plate[$plate-1] (only Water runs may exclude premix)");
            $escape = 1;
            last;
        }

        $Primer[ $plate - 1 ] = $primer_id;

        $plate++;
    }

    if ($escape) { return 0; }    ## primer not found associated with plate(s)...

    my $plates = $plate - 1;

    #
    # Get Buffer / Matrix Information...
    #

    my $buffer_id = param('Buffer');
    my $matrix_id = param('Matrix');
    my $cv        = param('CV');       ### chemistry version (temporary)

    unless ($external_run) {
        unless ( $buffer_id =~ /[1-9]/ && $matrix_id =~ /[1-9]/ ) {
            $dbc->error("Invalid Matrix or Buffer currently associated with this machine. Buffer($buffer_id), Matrix($matrix_id)");
            return 0;
        }

        #
        # Ensure they are both found successfully...
        #

        ( my $buffer_name ) = $Connection->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog_Name', "where FK_Stock__ID=Stock_ID and Solution_Type='Buffer' and Solution_ID=$buffer_id  AND FK_Stock_Catalog__ID = Stock_Catalog_ID " );
        ( my $matrix_name ) = $Connection->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog_Name', "where FK_Stock__ID=Stock_ID and Solution_Type='Matrix' and Solution_ID=$matrix_id  AND FK_Stock_Catalog__ID = Stock_Catalog_ID " );
        unless ( $buffer_name && !( $buffer_name =~ /NULL/ ) ) { $dbc->error( "Buffer not found", "(Please pick one of the listed buffer solutions) found $buffer_name" ); return 0; }
        unless ( $matrix_name && !( $matrix_name =~ /NULL/ ) ) { $dbc->error( "Matrix not found", "(Please pick one of the listed matrix solutions) found $matrix_name" ); return 0; }
    }

##### Add selected options #####

    my %Input;
    foreach my $name ( param() ) {
        my @result = param($name);
        $Input{$name} = \@result;
    }
    my $options = '';
    my %Track_Run_Details;    ### enable storing of details for the batch
    my %Track_Run_Attributes;

    &update_batch_settings( -dbc => $dbc, -equipment_id => $equipment_id, -plates => $plates, -input => \%Input, -track_run_details => \%Track_Run_Details, -Track_Run_Attributes => \%Track_Run_Attributes );

    ############# ensure not overwriting sample sheet which has been analyzed #############
    my @Quadrants = alDente::Library_Plate::get_available_quadrants( -dbc => $dbc, -plates => \@Plate );

    my @new_file;

    my @Batch_fields = ( 'FK_Employee__ID', 'FK_Equipment__ID', 'RunBatch_RequestDateTIme', 'RunBatch_Comments' );
    my @Batch_values = ( $user_id, $equipment_id, $now, $comments );

    ############ Update Info for Batch of Runs... ###########################
    my $run_details;    ### update it when you get to the successive plate_run

    ############ Show Hidden Info for Batch of Runs... ###########################
    my $hidden_details;
    foreach my $detail ( keys %Track_Run_Attributes ) {
        $hidden_details .= $Track_Run_Attributes{$detail} . '<BR>';
    }

    my %sequence_inserts;
    my @fields    = qw(FK_Plate__ID Run_Type Run_DateTime Run_Test_Status Run_Status Run_Directory FK_Branch__Code FKPrimer_Solution__ID FKMatrix_Solution__ID FKBuffer_Solution__ID Slices Run_Format);
    my @optionals = qw(DNA_Volume Total_Prep_Volume BrewMix_Concentration Reaction_Volume Resuspension_Volume Run_Module Run_Time Run_Voltage Run_Temperature Injection_Time Injection_Voltage PlateSealing Run_Direction);

    ########### ... and for individual Runs (96 well plates) ##############
    my @new_requests;    ## generate list of new Run_IDs generated...

    my $notes;
    my $firstfile = '';
    foreach my $plate ( 1 .. $plates ) {
        ### use mul barcode for sample sheet ### ADJUST for more than one 384-well plate...

        my $barcode = alDente::Tray::exists_on_tray( $dbc, 'Plate', $Plate[ $plate - 1 ] );
        if ($barcode) { $barcode = 'TRA' . sprintf( "%010d", $barcode ); }

        ######### Group together plates in sets of 4... ##################################
        my $group = int( ( $plate - 1 ) / 4 );
        my $plateList       = join ',', @Plate[ 4 * $group .. 4 * $group + 3 ];
        my $plate_name_list = join ',', @Label[ 4 * $group .. 4 * $group + 3 ];
        my %primerList = map { $_, 1 } $Primer_name[ 4 * $group .. 4 * $group + 3 ];
        my $primer_list = join ',', keys %primerList;    ### unique list...

        my $status;
        my $test_status;
        my $terminator;
        my $water_run;

        # Set terminator, run state and run status for each invidividual plates
        if ( $Library[ $plate - 1 ] =~ /$WATER_LIB/i ) {    # For water plates, set terminator to 'Water', state to 'Applicable' and status to 'Test'
            $terminator  = 'Water';
            $status      = 'Not Applicable';
            $test_status = 'Test';
            $water_run   = 1;
        }
        else {
            $terminator = param('Terminator');
            $status     = 'In Process';
            if   ($test_run) { $test_status = "Test"; }
            else             { $test_status = "Production"; }
        }

        ### figure out if only some slices are used.. ###
        my @slices = param('Slices');
        my $slice_list = join ',', @slices;
        my $reads;

        my $auto_comment = "$plate/$plates: $plate_name_list ($primer_list) $cv.";

        unless ( $Plate[ $plate - 1 ] ) { next; }

        # check quadrant if this is a Tray, and omit plates that are not selected
        if ($barcode) {
            my @quads_used = split //, $quadrants_used;
            my $curr_quad = $Quadrants[ ( $plate - 1 ) % 4 ];
            unless ( grep( /$curr_quad/, @quads_used ) ) {
                Message("Skipping quadrant $curr_quad of PLA $Plate[$plate-1]");
                next;
            }
        }

        my $Nof4;
        if ( $plates > 1 ) { $Nof4 = "$plate/$plates"; }

        #### Generate Sample Sheet ####
        my ( $sspath, $basename, $cc, $version ) = get_run_version( -plate_id => $Plate[ $plate - 1 ] );

        if ( !$cc && $water_run ) {
            my $water_code = 'BW';    ## <CONSTRUCTION> - set water branch code in configuration or list of static variables (?)
            ## no chemistry code - set for water run and set plate branch code ##
            $cc = $water_code;
            $dbc->Table_update( 'Plate', 'FK_Branch__Code', $water_code, "WHERE Plate_ID = $Plate[$plate-1]", -autoquote => 1 );
        }

        ######## check for version specification to overwrite ###########
        my $overwrite = 0;
        if ( param('Version') || param('Version') eq '0' ) {
            $version   = "." . param('Version');
            $overwrite = 1;
        }
        ### call new sample sheet generator module ###
        my $fback;
        my $user  = $dbc->session->param('user_id');
        my $dbase = $dbc->{dbase};
        if ( $dbase && $Plate[ $plate - 1 ] && $equipment_id && $user && $cc ) {
            my $plateid = $barcode || "Pla" . sprintf( "%010d", $Plate[ $plate - 1 ] );
            my %Parameters = (
                'USERNAME'      => $user,
                'COMMENTSTRING' => $comments,
                'AUTOCOMMENT'   => $auto_comment,
                'CHEMISTRYCODE' => $cc,
                'VERSION'       => $version,
                'RUNFORMAT'     => $Run_format,
                'FILENAME'      => "$sspath/$basename.$cc$version$ssext",
                'PLATENAME'     => "$basename",
                'PLATEID'       => $plateid,
                'TERMINATOR'    => param('Terminator') . " Terminators",
            );
            ( $reads, $fback, $notes ) = generate_ss( $dbc, $dbase, $Plate[ $plate - 1 ], $equipment_id, \%Parameters );
        }
        else {
            print "Sorry - not enough info: (U:$user,P:$Plate[$plate-1],E:$equipment_id,C:$cc)\n";
            return 0;
        }

        print "<BR>";

        $new_file[ $plate - 1 ] = '';
        my $original;

        if ( $fback =~ /(.*)\.(plt|psd|txt)/ ) {    ## extract name from feedback (REQUIRES FORMATTED output)
            $new_file[ $plate - 1 ] = $1;
        }

        if ( !$new_file[ $plate - 1 ] ) {
            Message("No Directory Found. Sample Sheet Created: $fback ?");
            return 0;
        }

        #
        # Overwriting current Sample Sheet ?...
        #

        if ( $overwrite || ( $Configs{PRODUCTION_DATABASE} && ( $Configs{PRODUCTION_DATABASE} ne $Connection->{dbase} ) ) ) {
            my $analyzed = join ',', $Connection->Table_find( 'Run', 'count(*)', "where Run_Directory=\"$new_file[$plate-1]\" and Run_Status IN ('Data Acquired','Analyzed')" );
            if ( $analyzed > 0 ) {
                $dbc->warning(" cannot overwrite the sample sheet for a Run which has already been analyzed.");
                return 0;
            }
        }
        else {

            my $in_process = join ',', $Connection->Table_find( 'Run', 'count(*)', "where Run_Directory=\"$new_file[$plate-1]\" and Run_Status NOT IN ('Aborted','Not Applicable')" );

            if ( $in_process > 0 ) {
                Message("Warning: Run $new_file[$plate-1] already exists, chose Overwrite option if you intend to proceed with this version");
                return 0;
            }

        }

        ##############  Generate error message feedback ##############
        if ( $fback =~ /Error/i ) {
            $dbc->error($fback);
        }
        elsif ( !$convert_96x4_to_384 ) {
            $fback =~ s/\s+/<Br>/g;
            print "Created <B><Font color=red>$new_file[$plate-1]</Font></B>", br();
        }

        my ($matrix_solution_id) = &alDente::Equipment::get_MatrixBuffer( $dbc, 'Matrix', $equipment_id );
        my ($buffer_solution_id) = &alDente::Equipment::get_MatrixBuffer( $dbc, 'Buffer', $equipment_id );

        my $record = int( keys %sequence_inserts ) + 1;
        ## record keeps track of records inserted.  (not same as $plate if some quadrants are skipped)..
        my $pla_id = $Plate[ $plate - 1 ];

        my ($direction) = &Table_find_array( $dbc, 'Library, Plate, LibraryApplication, Primer, Branch_Condition AS Primer_Branch, Object_Class as Primer_Object', ['LibraryApplication.Direction'],
            " where Plate.FK_Library__Name = Library.Library_Name and LibraryApplication.FK_Library__Name = Library.Library_Name and LibraryApplication.FK_Object_Class__ID = 2 and LibraryApplication.Object_ID = Primer.Primer_ID AND Primer.Primer_ID = Primer_Branch.Object_ID AND Plate.FK_Branch__Code = Primer_Branch.FK_Branch__Code AND Primer_Object.Object_Class='Primer' AND Primer_Branch.FK_Object_Class__ID=Primer_Object.Object_Class_ID and LibraryApplication.Direction is not NULL and Plate.Plate_ID = $pla_id"
        );

        $sequence_inserts{$record} = [ $Plate[ $plate - 1 ], 'SequenceRun', $now, $test_status, $status, $new_file[ $plate - 1 ], $cc, $Primer[ $plate - 1 ], $matrix_solution_id, $buffer_solution_id, $slice_list, $Run_format ];
        $Track_Run_Details{$plate}{Run_Direction} = $direction;
        foreach (@optionals) {
            push( @{ $sequence_inserts{$record} }, $Track_Run_Details{$plate}{$_} );
        }

        ############################### OVERWRITE old SampleSheet ###########################

        if ($overwrite) {
            my $ok = $Connection->Table_update_array( 'Run', [ 'Run_Status', 'Run_Directory' ], [ "'Aborted'", "CONCAT('Aborted_',FK_RunBatch__ID,'_',Run_Directory)" ], "where Run_Directory='$new_file[$plate-1]'" );
            if ($ok) {
                Message("Sample Sheet overwritten - Old Run Record being aborted, update $ok runs.");
            }
        }

        # Generating new Sample Sheet...
        #
        ################################################################################################

        my $transfer = 1;
        if ( ( $plate > 1 ) && $convert_96x4_to_384 ) {
            ### transfer first quadrant ss only (others are only copies...)
            $transfer = 0;
        }

        #	if ($convert_96x4_to_384) {
        #	    if ( $new_file[$plate-1] ) {
        #		$transfer = 1;
        #	    }
        #        }

        # dispplay file to be transferred
        my $Plate_Label = SDB::DBIO::get_FK_info( $dbc, 'FK_Plate__ID', $Plate[ $plate - 1 ] );
        if ( $fback && $transfer ) {
            print "$Plate_Label <Font color=red><b>$fback</b></Font>";
        }
        elsif ( $fback && !$transfer ) {
            print "$Plate_Label <Font color=red>$fback</Font>";
        }

        # request transfer
        unless ( $notes =~ /Error/ ) {
            my $ssname = $fback;

            if ($transfer) {
                if ( $Connection->{dbase} eq 'sequence' ) {
                    &generate_SS_request( "$sspath/$ssname", $equipment_id );
                }
                else {
                    &generate_SS_request( "$sspath/$ssname", $equipment_id, '.test' );
                }
            }
        }
    }

    ### Create the batch entry
    my $batch_id = $Connection->Table_append_array( 'RunBatch', \@Batch_fields, \@Batch_values, -autoquote => 1 );
    unless ($batch_id) { $dbc->warning("see admin (Batch value problem)"); $batch_id = 'NULL'; return 0; }
    unshift( @fields, 'FK_RunBatch__ID' );
    foreach ( keys %sequence_inserts ) { unshift( @{ $sequence_inserts{$_} }, $batch_id ); }
    Message( "New RunBatch: " . &Link_To( $homelink, $batch_id, "&Info=1&Table=RunBatch&Field=RunBatch_ID&Like=$batch_id", $Settings{LINK_COLOUR}, ['newwin'] ) );

    ### Insert the experiment entries in the database
    my $new_runs = $Connection->smart_append( 'Run,SequenceRun', [ @fields, @optionals ], \%sequence_inserts, -autoquote => 1 );

    if ( $new_runs->{Run}{newids} ) {

        push( @new_requests, join ',', @{ $new_runs->{Run}{newids} } );

        if (%Track_Run_Attributes) {
            my %new_attributes;

            my $attribute_names = "'" . join( "','", keys %Track_Run_Attributes ) . "'";
            my $grp_list = join ',', $Connection->get_local('group_list');
            my %attributes = &Table_retrieve( $dbc, 'Attribute', [ 'Attribute_ID', 'Attribute_Name' ], "WHERE Attribute_Class='SequenceRun' AND Attribute_Name IN($attribute_names) AND FK_Grp__ID IN ($grp_list)" );
            my $attribute_count = scalar( keys %Track_Run_Attributes );
            my $count;
            my $time = &date_time();
            if (%attributes) {
                foreach my $seqrun_id ( @{ $new_runs->{SequenceRun}{newids} } ) {
                    for ( my $int = 0; $int < $attribute_count; $int++ ) {
                        $new_attributes{ ++$count } = [ $seqrun_id, $attributes{Attribute_ID}->[$int], $Track_Run_Attributes{ $attributes{Attribute_Name}->[$int] }, $user_id, $time ];
                    }
                }
                $Connection->smart_append( 'Run_Attribute', [ 'FK_Run__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' ], \%new_attributes, -autoquote => 1 );
            }
        }

    }
    else {
        $dbc->warning( "Run Table not updated: " . Get_DBI_Error() );
        return 0;
    }

    if ($convert_96x4_to_384) {
        my $new_run_ids = join ',', @{ $new_runs->{Run}{newids} };
        my %runs = &Table_retrieve( $dbc, 'Run,Plate_Tray', [ 'Run_ID', 'FK_Tray__ID', 'Plate_Position' ], "WHERE Run.FK_Plate__ID=Plate_Tray.FK_Plate__ID AND Run_ID IN ($new_run_ids)" );
        my $i = 0;
        my %master_list;
        while ( defined $runs{Run_ID}->[$i] ) {
            $master_list{ $runs{FK_Tray__ID}->[$i] } = $runs{Run_ID}->[$i] if ( !$master_list{ $runs{FK_Tray__ID}->[$i] } );
            $i++;
        }
        my %mp_entries;
        $i = 0;
        my @mp_fields = qw(FKMaster_Run__ID FK_Run__ID MultiPlate_Run_Quadrant);
        while ( defined $runs{Run_ID}->[$i] ) {
            $mp_entries{ $i + 1 } = [ $master_list{ $runs{FK_Tray__ID}->[$i] }, $runs{Run_ID}->[$i], $runs{Plate_Position}->[$i] ];
            $i++;
        }
        my $new_mps = $Connection->smart_append( 'MultiPlate_Run', \@mp_fields, \%mp_entries, -autoquote => 1 );
        unless ( $new_mps->{MultiPlate_Run}{newids} && scalar( @{ $new_mps->{MultiPlate_Run}{newids} } ) == scalar( @{ $new_runs->{Run}{newids} } ) ) {
            $dbc->warning("Problems adding entries to MultiPlate_Run");
            print HTML_Dump($new_runs);
            print HTML_Dump($new_mps);
            Call_Stack();
            return 0;
        }
    }

    my $new_ss = int(@new_requests);
    Message("Wrote $new_ss $Run_format SampleSheet(s) for $equipment");
    $new_runs = join ',', @new_requests;
    Message( "New Runs: " . &Link_To( $homelink, $new_runs, "&Info=1&TableName=Run&Field=Run_ID&Like=$new_runs" ) . '<BR>' );

    ############ Show Details for Batch of Runs... ###########################
    if ( exists $Track_Run_Details{1} ) {
        foreach my $detail ( keys %{ $Track_Run_Details{1} } ) {
            $run_details .= $detail . " -> " . $Track_Run_Details{1}{$detail} . '<BR>';
        }
    }

    if ( !$scanner_mode ) {
        if ($run_details)    { Message( "Run Details <BR> for first plate:<BR>(saved to DB)", "$run_details",    undef, 'lightblue' ); }
        if ($hidden_details) { Message( "Hidden Details:",                                    "$hidden_details", undef, 'lightblue' ); }
        if ($notes)          { Message( "Referenced:",                                        "$notes",          undef, 'lightblue' ); }
    }
    else {    ### more succinct
        Message($run_details);
        Message($hidden_details);
        Message($notes);
    }

    if ($escape) {
        return 0;
    }
    else {
        return 1;
    }
}

########################
sub get_run_version {
########################
    #
    # Check SampleSheet Directory to retrieve next version to be generated
    # (better to use database ?)
    #
    ## <CONSTRUCTION> use the _get_next_name in Run module!
    my %args = &filter_input( \@_, -args => 'dbc,plate_id' );
    my $dbc = $args{-dbc} || $Connection;
    my $plate_id = $args{-plate_id};

### get basename ###
    my ( $proj_id, $project_path, $library, $plate_num, $quadrant, $position, $chemcode ) = split ',',
        [
        $dbc->Table_find(
            'Plate,Library,Project LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID=Plate.Plate_ID',
            'Project.Project_ID,Project.Project_Path,Library.Library_Name,Plate.Plate_Number,Plate.Parent_Quadrant,Plate_Position,FK_Branch__Code',
            "WHERE FK_Library__Name=Library_Name AND Project_ID=FK_Project__ID AND Plate_ID=$plate_id"
        )
        ]->[0];

    #    if(!$quadrant) {
    #        $quadrant = $position;
    #    }

    # sanity check - if $quadrant ==0, then set it to the blank string
    $quadrant = '' unless ( $quadrant =~ /[a-dA-D]/ );

    my $path     = "$project_dir/$project_path/$library";
    my $basename = $library . '-' . $plate_num . lc($quadrant);    ## force to lower case

    ### get subdirectory ###
    my $basedir = "$path/$sssdir";

    unless ( $dbc->{dbase} eq 'sequence' ) {

        #$basedir = "/home/aldente/public/Projects/Test_files";
        $basedir = "$project_dir/Test_files";
        Message("Not using production database - writing samplesheets to $basedir");
    }

    my @files = split "\n", try_system_command("ls $basedir/$basename.$chemcode*");

    my $maxversion = 0;
    my $found      = 0;
    foreach my $thisfilename (@files) {
        if ( $thisfilename =~ /No such file/i ) { return ( $basedir, $basename, $chemcode, '' ); }    ## no files found...

        if ( $thisfilename =~ /$basename/ ) {
            $found++;
        }
        if ( $thisfilename =~ /$basename\.$chemcode\.(\d+)/ ) {
            my $thisversion = $1;
            if ( $thisversion > $maxversion ) { $maxversion = $thisversion; }
        }
    }
    my $nextversion = $maxversion + 1;
    if ( ( $nextversion > 1 ) || $found ) {
        return ( $basedir, $basename, $chemcode, ".$nextversion" );
    }
    else {
        return ( $basedir, $basename, $chemcode, '' );
    }
}

########################
sub check_for_list {
########################
    my $values = shift;
    my $number = shift;
    my $index  = shift;

    unless ( $values =~ /,/ ) { return $values; }
    my @list = split ',', $values;

    if ( $number == int(@list) ) {
        return $list[ $index - 1 ];
    }
    else {
        Message("Warning:List Unexpected size");
        return $list[0];
    }
}

#####################
sub get_primer {
#####################
    #
    # Return the primer associated with a given plate.
    #
    my $dbc   = shift;
    my $plate = shift;
    my $quiet = shift;    ## supress feedback

    #    my $parents = &alDente::Container::get_Parents(-dbc=>$dbc,-id=>$plate,-format=>'list');
    #    my $sets = &alDente::Container::get_Sets(-dbc=>$dbc,-id=>$plate);

    #    my $set_spec;
    #    if ($sets=~/\d/) { $set_spec = "(FK_Plate__ID in ($parents) OR (FK_Plate__ID is NULL AND FK_Plate_Set__Number in ($sets)))"; }
    #    else { $set_spec = "FK_Plate__ID in ($parents)" }

    #    my $solutions_used = join ',', $Connection->Table_find('Prep,Plate_Prep,Solution','Plate_Prep.FK_Solution__ID',"where FK_Prep__ID=Prep_ID AND Plate_Prep.FK_Solution__ID=Solution_ID AND $set_spec ORDER by Prep_DateTime desc",'Distinct');

    my @solutions_used;

    my %parent_ancestry = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate, -format => 'hash', -simple => 1 );

    $parent_ancestry{'generation'}{0} = $plate;

    my ($plate_created) = Table_find( $dbc, 'Plate', 'Plate_Created', "WHERE Plate_ID = $plate" );
    $plate_created = convert_date( $plate_created, 'SQL' );
    $parent_ancestry{'created'}{0} = $plate_created;
    ## go through each generation and get the preps that are applicable to the plate
    foreach my $generation ( sort { $a <=> $b } keys %{ $parent_ancestry{'generation'} } ) {

        my $generation_plate       = $parent_ancestry{'generation'}{$generation};
        my $generation_created     = $parent_ancestry{'created'}{$generation};
        my $daughter_plate_created = $parent_ancestry{'created'}{ $generation + 1 };
        my $extra_condition        = "FK_Plate__ID IN ($generation_plate) ";
        ## Get only the preps that apply to the plate when it was created and before it was aliquoted
        if ( $generation_created && $daughter_plate_created ) {
            $extra_condition .= "AND Prep_DateTime between '$generation_created' and '$daughter_plate_created'";
        }
        else {
            $extra_condition .= "AND Prep_DateTime >= '$generation_created'";
        }
        ## Get the plate prep information for the plate
        my @solutions_found = &Table_find( $dbc, 'Prep,Plate_Prep', 'Plate_Prep.FK_Solution__ID', "WHERE FK_Prep__ID=Prep_ID AND $extra_condition AND Plate_Prep.FK_Solution__ID IS NOT NULL Group by Prep_ID ORDER BY Prep_DateTime" );
        if (@solutions_found) {
            push( @solutions_used, @solutions_found );
        }
    }
    my $solutions_used = join ',', @solutions_used;

    my @used;
    for ( my $index = $#solutions_used; $index >= 0; $index-- ) {
        if ( $solutions_used[$index] ) {
            push( @used, &alDente::Solution::get_original_reagents( $dbc, $solutions_used[$index], -type => 'Primer' ) );
        }
    }
    @used = adjust_list( \@used, 'unique', 'maintain order' );

    #previously without loop then it is not order by Prep_DateTime anymore
    #my @used = &get_original_reagents($dbc,$solutions_used,-type=>'Primer');

    my $primer = join ',', @used;

    # custom logic
    # ignore Amplicon primers
    unless ($primer) {
        ####    This is to avoid the sql breaking
        $primer = 0;
    }
    my @amplicon_primers = $dbc->Table_find_array( "Stock,Solution,Primer,Stock_Catalog",
        ['Solution_ID'], "WHERE FK_Stock__ID=Stock_ID  AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog_Name = Primer_Name AND Solution_ID in ($primer) AND Primer_Type = 'Amplicon'" );
    my $amplicon_primers = join( "|", @amplicon_primers );
    if ($amplicon_primers) {
        my @new_used = grep( !/^$amplicon_primers$/, @used );
        $primer = join ',', @new_used;
    }

    # if there are multiple primers and their names are all Custom or Custom Oligo Plate
    # use the ID of 'Custom'
    if ( int(@used) > 1 ) {
        my @id = $Connection->Table_find( "Stock,Solution,Stock_Catalog", "Solution_ID", "WHERE FK_Stock__ID=Stock_ID  AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Solution_ID in ($primer) AND Stock_Catalog_Name='Custom'" );
        if ( int(@id) == 1 ) {
            $primer = $id[0];
        }
    }

    my $found = 1;
    if ( $primer =~ /,/ ) {
        my ($same_primer) = $dbc->Table_find( "Stock,Solution,Stock_Catalog", "Count(Distinct Stock_Catalog_Name)", "WHERE FK_Stock__ID=Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Solution_ID in ($primer)" );
        if ( $same_primer > 1 ) {
            print &Link_To( $dbc->homelink(), '<span class=small>Check Primers Applied</span>', "&Info=1&Table=Solution&Field=Solution_ID&Like=$primer", $Settings{LINK_COLOUR}, ['newwin'] );
            print &vspace();
            $dbc->warning("more than one Primer detected for Plate $plate<BR>(using last used of $primer)");
        }
        $found = int( my @list = split ',', $primer );
        ($primer) = split ',', $primer;    ### use only the last one used
    }

    my $primer_name;
    if ( $primer =~ /[1-9]/ ) {
        ($primer_name) = $Connection->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog_Name', "where FK_Stock__ID=Stock_ID  AND FK_Stock_Catalog__ID = Stock_Catalog_ID and Solution_ID = $primer" );
        Test_Message( "Associated Primer $primer_name ($primer) found", $testing );
    }
    elsif ( param('Non Primer') =~ /Custom/ ) {
        ($primer) = $Connection->Table_find( 'Solution,Stock,Stock_Catalog', 'Solution_ID', "where FK_Stock__ID=Stock_ID  AND FK_Stock_Catalog__ID = Stock_Catalog_ID and Solution_Type='Primer' and Stock_Catalog_Name like 'Custom'" );
        $primer_name = 'elsif';
    }
    elsif ( param('Non Primer') =~ /No/ ) {
        ($primer) = $Connection->Table_find( 'Solution,Stock,Stock_Catalog', 'Solution_ID', "where FK_Stock__ID=Stock_ID  AND FK_Stock_Catalog__ID = Stock_Catalog_ID and Solution_Type='Primer' and Stock_Catalog_Name like 'None'" );
        $primer_name = 'None';
    }
    else {

        #	unless ($quiet) {
        #	    $dbc->warning("Primer NOT found for Pla $plate<BR>(or choose Custom/None below)");
        #	}
        return ();
    }
    return ( $primer, $primer_name, $found );
}

##############################
## <CONSTRUCTION> - take the custom information extraction and put it in a custom trigger or shell executable (?)
####################
sub get_brew {
####################
    #
    # Requires 'Dispense Brew' step, using chemistry calculator using parameters: 'DNA','Total','Premix'
    #
    my %args = &filter_input( \@_, -args => 'dbc,plate,quiet,testlib' );
    my $dbc     = $args{-dbc} || $Connection;
    my $plate   = $args{-plate};
    my $quiet   = $args{-quiet};
    my $testlib = $args{-testlib};

    my %Details;

    my $Emessage;
    my $brew_step      = 'Dispense Brew';
    my $resuspend_step = 'Resuspend DNA';
    my $sets           = &alDente::Container::get_Sets( -dbc => $dbc, -id => $plate, -direct => 1 );
    my $set_spec;
    if ( $sets =~ /\d/ ) { $set_spec = "AND FK_Plate_Set__Number in ($sets)"; }

    my @brews;
    my @Rvolumes;

    my %parent_ancestry = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate, -format => 'hash', -simple => 1 );

    $parent_ancestry{'generation'}{0} = $plate;

    my ($plate_created) = Table_find( $dbc, 'Plate', 'Plate_Created', "WHERE Plate_ID = $plate" );
    $plate_created = convert_date( $plate_created, 'SQL' );
    $parent_ancestry{'created'}{0} = $plate_created;
    ## go through each generation and get the preps that are applicable to the plate
    foreach my $generation ( sort { $a <=> $b } keys %{ $parent_ancestry{'generation'} } ) {

        my $generation_plate       = $parent_ancestry{'generation'}{$generation};
        my $generation_created     = $parent_ancestry{'created'}{$generation};
        my $daughter_plate_created = $parent_ancestry{'created'}{ $generation + 1 };
        my $extra_condition        = "FK_Plate__ID IN ($generation_plate) ";
        ## Get only the preps that apply to the plate when it was created and before it was aliquoted
        if ( $generation_created && $daughter_plate_created ) {
            $extra_condition .= "AND Prep_DateTime between '$generation_created' and '$daughter_plate_created'";
        }
        else {
            $extra_condition .= "AND Prep_DateTime >= '$generation_created'";
        }
        ## Get the plate prep information for the plate
        my @brews_found = $Connection->Table_find_array(
            'Prep,Plate_Prep,Solution,Stock,Stock_Catalog',
            [ 'Solution_ID', 'Stock_Catalog_Name', 'Plate_Prep.Solution_Quantity', 'FK_Plate_Set__Number' ],
            "WHERE FK_Prep__ID=Prep_ID  AND FK_Stock__ID=Stock_ID  AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Plate_Prep.FK_Solution__ID=Solution_ID AND Prep_Name like '$brew_step' AND $extra_condition $set_spec Group by Prep_ID ORDER BY Prep_DateTime"
        );
        my @rvolume = $Connection->Table_find( 'Prep,Plate_Prep', 'Plate_Prep.Solution_Quantity', "where FK_Prep__ID=Prep_ID AND $extra_condition and Prep_Name like '$resuspend_step'" );
        push( @Rvolumes, @rvolume ) if ( int(@rvolume) > 0 );
        push( @brews, @brews_found );
    }

#my @brews = $Connection->Table_find_array('Prep,Plate_Prep,Solution,Stock',['Solution_ID','Stock _Name','Plate_Prep.Solution_Quantity','FK_Plate_Set__Number'],"where FK_Prep__ID=Prep_ID AND FK_Stock__ID=Stock_ID AND Plate_Prep.FK_Solution__ID=Solution_ID AND Prep_Name like '$brew_step' AND $set_spec ORDER by Prep_DateTime desc",'Distinct');

    if    ( int(@brews) > 1 ) { $dbc->error("More than one brew detected! check defaults.") }
    elsif ($testlib)          { }                                                               ## skip message if test library (Water)
    elsif ( int(@brews) < 1 ) { $dbc->error("No brew detected! check defaults.") }

    if ( int(@Rvolumes) > 1 ) { $Emessage .= "..more than one Resuspension found" }
    my ( $brewid, $brewname, $brewqty, $brewset ) = split ',', $brews[0];
    my @parameters = $Connection->Table_find_array( 'Parameter,Standard_Solution', [ 'Parameter_Prompt', 'Parameter_Value' ], "where FK_Standard_Solution__ID=Standard_Solution_ID and Standard_Solution_Name = '$brewname'" );

    unless (@parameters) {
        if ($testlib) {                                                                         ## set for Water library..
            $Details{DNA}    = 0;
            $Details{Premix} = 0;
            $Details{Total}  = 0;
        }
        else {
            $dbc->warning( "No information for Standard Brew: $brewname -> DNA/Premix/Total Volumes cannot be determined", "You will need to add it to the Standard Solution records to auto-generate these values in the future" );
            return %Details;
        }
    }
    foreach my $parameter (@parameters) {
        my ( $Pname, $Pvalue ) = split ',', $parameter;
        if ( $Pname =~ /^DNA/i )   { $Details{DNA}    = $Pvalue }
        if ( $Pname =~ /mix$/i )   { $Details{Premix} = $Pvalue }
        if ( $Pname =~ /^Total/i ) { $Details{Total}  = $Pvalue }
    }
    if ( $Details{Total} ) {
        $Details{BrewMixConcentration} = $Details{Premix} / $Details{Total} * 4 / 20;    ### 1x concentration = 4/20 - Standard
    }
    else {
        $Details{BrewMixConcentration} = 0;
    }
    $Details{ReactionVolume}     = $Details{Total};                                      ### 1x concentration = 4/20 - Standard
    $Details{DNAVolume}          = $Details{DNA};
    $Details{ResuspensionVolume} = $Rvolumes[0];

    if ( $brewset =~ /[1-9]/ ) {
        my @sizes = $Connection->Table_find( 'Plate_Set,Plate', 'Plate_Size', "where FK_Plate__ID=Plate_ID AND Plate_Set_Number = $brewset" );
        my $wells = 0;
        foreach my $size (@sizes) {
            if ( $size =~ /(\d+)/ ) { $wells += $1 }
        }
        if ($wells) {
            $Details{TotalPrepVolume} = 1000 * $brewqty / $wells;                        ### saving in uL
        }
    }

    # removed check for DNA, as it is not something that can be changed by the GTs
    unless ( defined $Details{Premix} && defined $Details{Total} ) {
        $Emessage .= "..undefined Premix/Total value";
    }

    if ($Emessage) { $dbc->error("$Emessage - check defaults") }

    return %Details;
}

####################
#
# Highly customized... clarify requirements / limitations / protocol expected. <construction>
#
#
#####################
sub get_premix {
#####################
    #
    # Return the primer associated with a given plate.
    #
    my $dbc   = shift;
    my $plate = shift;
    my $quiet = shift;    ## supress feedback

    my $parents = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate, -format => 'list', -simple => 1 );
    my $sets = &alDente::Container::get_Sets( -dbc => $dbc, -id => $plate );

    my $set_spec;
    if   ( $sets =~ /\d/ ) { $set_spec = "(FK_Plate__ID in ($parents) OR (FK_Plate__ID is NULL AND FK_Plate_Set__Number in ($sets)))"; }
    else                   { $set_spec = "FK_Plate__ID in ($parents)" }

    my $solutions_used = join ',', $Connection->Table_find( 'Prep,Plate_Prep,Solution', 'Plate_Prep.FK_Solution__ID', "where FK_Prep__ID=Prep_ID AND Plate_Prep.FK_Solution__ID=Solution_ID AND $set_spec ORDER by Prep_DateTime desc", 'Distinct' );

    my @used = &alDente::Solution::get_original_reagents( $dbc, $solutions_used, -format => '%v%Premix' );

    my $premix = join ',', @used;

    my $found = 1;
    if ( $premix =~ /,/ ) {
        print &Link_To( $dbc->homelink(), '<span class=small>Check Premixes Applied</span>', "&Info=1&Table=Solution&Field=Solution_ID&Like=$premix", $Settings{LINK_COLOUR}, ['newwin'] );
        print &vspace();

        #	$dbc->warning("more than one Premix detected for Plate $plate<BR>(using last used of $premix)",!$quiet);
        $found = int( my @list = split ',', $premix );
        my $message = "Using last of the identified premixes found";    ## Connection
        $dbc->warning($message);
        ($premix) = split ',', $premix;                                 ### use only the last one used
    }

    my $premix_name;
    if ( $premix =~ /[1-9]/ ) {
        ($premix_name) = $Connection->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog_Name', "where FK_Stock__ID=Stock_ID  AND FK_Stock_Catalog__ID = Stock_Catalog_ID and Solution_ID = $premix" );
        Test_Message( "Associated Premix $premix_name ($premix) found", $testing );
    }
    elsif ( param('Non Primer') =~ /Custom/ ) {
        ($premix) = $Connection->Table_find( 'Solution,Stock,Stock_Catalog', 'Solution_ID', "where FK_Stock__ID=Stock_ID  AND FK_Stock_Catalog__ID = Stock_Catalog_ID  and Solution_Type='Primer' and Stock_Catalog_Name like 'Custom'" );
        $premix_name = 'Custom';
    }
    elsif ( param('Non Primer') =~ /No/ ) {
        ($premix) = $Connection->Table_find( 'Solution,Stock,Stock_Catalog', 'Solution_ID', "where FK_Stock__ID=Stock_ID  AND FK_Stock_Catalog__ID = Stock_Catalog_ID and Solution_Type='Primer' and Stock_Catalog_Name like 'None'" );
        $premix_name = 'None';
    }
    else {
        return ();
    }
    return ( $premix, $premix_name, $found );
}

######################
sub sample_sheets {
######################
    #
    #  list sample sheets matching optional pattern..
    #
    my $search_string = shift;

    my $command = "ls -tr $project_dir/*/*/SampleSheets/*$search_string*.p?? ";
    Message( "Found: ", try_system_command( $command, "<BR>" ), 'Sample Sheets' );

    return;
}

######################
sub remove_ss {
######################
    #
    #  Remove NON-Analyzed Sample Sheets from Queue;
    #
    my %args      = &filter_input( \@_, -args => 'condition,dbc', -mandatory => 'condition,dbc' );
    my $condition = $args{-condition};
    my $dbc       = $args{-dbc};

    my @filenames = $dbc->Table_find( 'Run,Project,Library,Plate', 'Library_Name,Run_Directory,Project_Path,Run_ID', "$condition and Plate.Plate_ID = Run.FK_Plate__ID and Project_ID=FK_Project__ID and Plate.FK_Library__Name=Library_Name " );

    foreach my $ss (@filenames) {
        ( my $Spath, my $file, my $Ppath, my $Sid ) = split ',', $ss;
        my ($count) = $dbc->Table_find( 'Clone_Sequence', 'count(*)', "where FK_Run__ID = $Sid" );
        if ($count) {
            Message("Analysis records seem to be present ! - Aborting Deletion of Run $Sid");
            next;
        }

        if ( $file =~ /\S{8,}/ ) {
            my $ss_file = "$project_dir/$Ppath/$Spath/SampleSheets/$file.???";
            if ( $Spath && $file ) {
                if ( -e $ss_file ) {
                    if ( $Connection->{dbase} eq 'sequence' ) {
                        Test_Message( "Deleting: $ss_file", 1 - $scanner_mode );
                        my $command = "rm -f $project_dir/$Ppath/$Spath/SampleSheets/$file.???";
                        my $ok      = try_system_command($command);
                        if ($ok) { Message($ok); }
                    }
                    else {
                        print "Not deleting file ($file) - (using test database?)";
                    }
                }
            }
            else {
                Message("Invalid Spath or filename ($Spath/$file)");
            }
        }
    }
    return 1;
}

##################
sub generate_ss {
##################
    #
    #  Get arguments
    #
    my $dbc          = shift || $Connection;
    my $dbase        = shift;
    my $plate_id     = shift;
    my $equipment_id = shift;
    my $parameters   = shift;

    my $homelink = $dbc->homelink();

    my $notes;

    my %arguments = %{$parameters};

    my $target = $arguments{'Target'} || 'file';    ### optional target may be screen  or example ###

    my $sep = "\t";                                 ### column separator..

    my $File = $arguments{'FILENAME'} || 'template.txt';

    my $tables    = 'Sequencer_Type,Machine_Default,Equipment';
    my @fields    = ( 'Sequencer_Type_ID', 'Sequencer_Type_Name', 'Well_Ordering', 'Zero_Pad_Columns', 'Capillaries', 'Sliceable' );
    my $condition = "WHERE Sequencer_Type.Sequencer_Type_ID = Machine_Default.FK_Sequencer_Type__ID AND Equipment.Equipment_ID = Machine_Default.FK_Equipment__ID AND Equipment.Equipment_ID = $equipment_id";

    my %info = &Table_retrieve( $dbc, $tables, \@fields, $condition );

    my $seq_type_id      = $info{Sequencer_Type_ID}[0];
    my $seq_type_name    = $info{Sequencer_Type_Name}[0];
    my $well_ordering    = $info{Well_Ordering}[0];
    my $zero_pad_columns = $info{Zero_Pad_Columns}[0];
    my $max_rows         = $info{Max_Columns}[0];
    my $max_cols         = $info{Max_Rows}[0];
    my $capillaries      = $info{Capillaries}[0];
    my $sliceable        = $info{Sliceable}[0];
    unless ( $sliceable =~ /yes/i ) { $sliceable = 0 }

    @fields = ( 'Wells', 'Max_Row', 'Max_Col', 'Slice' );
    $condition = "WHERE FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID=FK_Plate__ID AND Plate_ID = $plate_id";

    #
    my %plate_info = &Table_retrieve( $dbc, 'Plate,Plate_Format,Library_Plate', \@fields, $condition );
    my $plate_size = $plate_info{Wells}[0];
    if ( $plate_size =~ /(\d+)/ig ) {    ### sequencer requires upper case W to work...
        $arguments{'PLATESIZE'} = "$1-Well";    ### replace in SS if appropriate..
    }

    #    if ($plate_size =~ /^(\d+)/) {$plate_size = $1; }   ### may differ from above if 16xN / 96-well
    my $max_row = $plate_info{Max_Row}[0];
    my $max_col = $plate_info{Max_Col}[0];
    my $slice   = $plate_info{Slice}[0];

    #    if ($slice =~/^(\d+)/) { $plate_size *= length($1) }  ## set 16xN to proper size...

    # Now retrieve the values and prepare to generate the sameple sheet.
    $tables    = 'SS_Config';
    @fields    = ( 'SS_Config_ID', 'SS_Title', 'SS_Section', 'SS_Order', 'SS_Default', 'SS_Orientation', 'SS_Type' );
    $condition = "WHERE FK_Sequencer_Type__ID=$seq_type_id ORDER BY SS_Section, SS_Order";
    my %ss_info = &Table_retrieve( $dbc, $tables, \@fields, $condition );
### Check for parameters sent by users (overriding defaults) ####
    my %Parameter;
    foreach my $parameter ( param() ) {
        if ( $parameter =~ /SS_Option_(\d+)/ ) {
            my $CID = $1;
            unless ($CID) { next; }
            my ( $value, $title ) = ( '', "cid$CID" );
            if ( defined param("SS_Option_$CID") ) { $value = param("SS_Option_$CID"); $title = param("SS_Option_Title_$CID"); }
            $Parameter{$CID} ||= $value;

            my $equip_cond = "(FK_Equipment__ID=$equipment_id OR FK_Equipment__ID IS NULL OR FK_Equipment__ID = 0)";

            #### also set values for other parameters referencing this same parameter...
            my ($ref) = $Connection->Table_find( 'SS_Option', 'SS_Option_ID', "WHERE FK_SS_Config__ID = $CID AND SS_Option_Value = '$value'" );

            unless ( $ref =~ /[1-9]/ ) { next; }

            #my @references = $Connection->Table_find('SS_Option','FK_SS_Config__ID,SS_Option_Value',"where SS_Option_ID = $ref");
            my @references = $Connection->Table_find( 'SS_Option,SS_Config', 'FK_SS_Config__ID,SS_Option_Value,SS_Alias', "where FK_SS_Config__ID=SS_Config_ID AND FKReference_SS_Option__ID = $ref AND $equip_cond" );

            foreach my $reference (@references) {
                my ( $cid, $pvalue, $alias ) = split ',', $reference;
                $Parameter{$cid} = $pvalue;

                $notes .= "<B>$alias -> $pvalue</B><BR>";
            }
        }
    }

### Now loop through the records.###
    my @Rows;
    my $row          = 0;
    my $nextrow      = 0;
    my $HiddenFields = "<Table>";
    my $prev_section = 1;
    my $index        = 0;

    while ( defined $ss_info{SS_Title}[$index] ) {
        my $Cid         = $ss_info{SS_Config_ID}[$index];
        my $parameter   = $ss_info{SS_Title}[$index];
        my $section     = $ss_info{SS_Section}[$index];
        my $column      = $ss_info{SS_Order}[$index];
        my $default     = $ss_info{SS_Default}[$index];
        my $orientation = $ss_info{SS_Orientation}[$index];
        my $column_type = $ss_info{SS_Type}[$index];
        $index++;

        unless ($default) { $default = ' '; }    ### add space character...

        ### replace defaults with given values if specified ###
        if ( defined $Parameter{$Cid} ) { $default = $Parameter{$Cid}; }

        if ( $column_type =~ /hidden/i ) {
            unless ( $target =~ /screen/i ) { next; }
            $HiddenFields .= "<TR><TD>" . &Link_To( $homelink, $parameter, "&Search=1&TableName=SS_Config&Search+List=$Cid", $Settings{LINK_COLOUR}, ['newwin'] ) . "</TD><TD>(default=$default)<BR></TD></TR>";
            next;
        }

        if ( $section ne $prev_section ) {
            $row = $nextrow;
        }

        if ( $target =~ /screen/i ) {    ### generate links for each parameter if piped to the screen...
            $parameter =~ s / /_/g;
            $parameter = &Link_To( $homelink, $parameter, "&Info=1&Table=SS_Config&Field=SS_Config_ID&Like=$Cid", $Settings{LINK_COLOUR}, ['newwin'] );
            if ( $column_type =~ /untitled/i ) {
                $default = &Link_To( $homelink, $default, "&Info=1&Table=SS_Config&Field=SS_Config_ID&Like=$Cid", 'red', ['newwin'] );
            }
        }

        # Use arrays to store values for outputs.

        if ( $orientation =~ /col/i ) {
            my $skip_row = 0;
            unless ( $column_type =~ /untitled/i ) {    ### do not print the title for these columns..
                if ( $Rows[$row] ) { $Rows[$row] .= "$sep$parameter"; }
                else               { $Rows[$row] = "$parameter"; }
                $skip_row = 1;
            }

            if   ( $Rows[ $row + $skip_row ] ) { $Rows[ $row + $skip_row ] .= "$sep$default"; }
            else                               { $Rows[ $row + $skip_row ] .= "$default"; }
            $nextrow = $row + $skip_row + 1;
        }
        elsif ( $orientation =~ /row/i ) {
            if ( $column_type =~ /untitled/i ) {        ### do not print the title for these columns..
                $Rows[ $row++ ] = "$default";
            }
            else {
                $Rows[ $row++ ] = "$parameter$sep$default";
            }
            $nextrow = $row;
        }
        $prev_section = $section;
    }
    $HiddenFields .= "</Table>";

    my $output    = "";                                 # String containing the output;
    my $start_row = 'A';
    my $start_col = '1';

    my $slice_cols = 2;

    my $start_slice = 0;
    my $end_slice   = $max_col;

    my @quadrants  = param('Quadrants_Used');
    my $slice_list = join ",", param('Slices');
    my @slices     = split /,/, $slice_list;

    my $reads;
    if ($sliceable) {
        if ( int(@quadrants) ) {
            $slice_cols  *= 2;
            $capillaries *= int(@quadrants);
        }    ## multiply rows by quadrants...
        if ( $slices[0] =~ /^(\d+)/ ) {    ## If generate run for specified slice(s) from a plate
            $start_slice = $slice_cols * ( $1 - 1 ) + 1;
            $end_slice   = $start_slice + int(@slices) * $slice_cols - 1;
            $reads       = $capillaries * int(@slices);                     ## set 16xN to proper size...
        }
    }

    if ( $sliceable && @slices )    { print "Using slices: @slices"; }
    if ( $sliceable && @quadrants ) { print " (Quadrants: @quadrants)<BR>"; }

    foreach my $row (@Rows) {
        if ( $row =~ /WELL/ ) {                                             ### repeat WELL rows X plate_size... ###
            my $well_col = $start_col;
            my $well_row = $start_row;

            for ( my $i = 0; $i < $plate_size; $i++ ) {
                if ( $target =~ /screen/i ) {                               ### just show 1st, 2nd,... last well lines
                    if ( $i > 2 ) { next; }                                 ### skip middle rows...
                    elsif ( $i == 2 ) { $output .= "...\n"; $i = $plate_size; $well_row = $max_row; $well_col = $max_col; }
                }

                my $well = $well_row . ( $zero_pad_columns eq 'YES' ? sprintf( "%02d", $well_col ) : $well_col );

                unless ( ( $well_col >= $start_slice ) && ( $well_col <= $end_slice ) ) {    ## skip if this slice excluded
                    ( $well_row, $well_col ) = _next_well(
                        $well_row, $well_col,
                        fill      => $well_ordering,
                        start_row => $start_row,
                        start_col => $start_col,
                        max_row   => $max_row,
                        max_col   => $max_col
                    );
                    next;
                }

### SPECIFIC to 384- well plates with  96 well quadrants	 #######
                if ( int(@quadrants) && ( int(@quadrants) < 4 ) ) {
                    my ($quadrant) = $Connection->Table_find( 'Well_Lookup', 'Quadrant', "where Plate_384 like '$well_row$well_col'" );

                    unless ( grep /$quadrant/, @quadrants ) {    ## skip this well unless this quadrant is chosen
                        ( $well_row, $well_col ) = _next_well(
                            $well_row, $well_col,
                            fill      => $well_ordering,
                            start_row => $start_row,
                            start_col => $start_col,
                            max_row   => $max_row,
                            max_col   => $max_col
                        );
                        next;
                    }
                }

                # Replace occurance of special values.
                $arguments{WELL} = $well;
                my $newrow = &replace_special_ss_default( $row, \%arguments );
                $output .= "$newrow\n";

                ( $well_row, $well_col ) = _next_well(
                    $well_row, $well_col,
                    fill      => $well_ordering,
                    start_row => $start_row,
                    start_col => $start_col,
                    max_row   => $max_row,
                    max_col   => $max_col
                );

            }
        }
        else {
            $arguments{WELL} = "well";
            my $newrow = &replace_special_ss_default( $row, \%arguments );
            $output .= "$newrow\n";
        }
    }

    if ( $target =~ /file/i ) {
        open( FILE, ">$File" ) || return ( $reads, $File, "Error Opening File: $File.\n" );
        print FILE $output;
        close FILE;
        if ( -f $File ) {

            # suppress message for brevity
            #	    Message("'$File' found");
        }
        else {
            Message("'$File' NOT found");
        }

        $output =~ s/\n/<BR>/g;

        if ( $File =~ /(.*)\/(.+)/ ) {
            $File = $2;    ### just return name (ignore path)
        }
        return ( $reads, $File, $notes );
    }
    elsif ( $target =~ /screen/i ) {
        print &Views::Heading("An example of a $plate_size-wells Sample Sheet for $seq_type_name Sequencers") . &vspace(10);
        my @lines = split "\n", $output;

        my $table = HTML_Table->new();
        $table->Set_Class('small');
        $table->Toggle_Colour('off');

        foreach my $line (@lines) {
            my @columns = split $sep, $line;
            $table->Set_Row( \@columns );
        }

        print &Views::sub_Heading( "Notes:", -1 );
        print "<UL>", "<LI>links in blue refer to headings for samplesheet rows/columns", "<LI>links in red refer to heading values (with actual headings hidden)", "<LI>click on red or blue links to edit defaults or add/edit options", "</UL><P>";

        $table->Printout();

        print "<P>";
        print &Views::sub_Heading( 'Hidden Fields: (not in samplesheets, but may be stored in database for each samplesheet request)', -1 );
        print $HiddenFields;

        print "<P>";
        print &Views::sub_Heading( 'Special Variables: (to be replaced by specific values)', -1 );
        my $Special = HTML_Table->new();
        $Special->Set_Class('small');
        $Special->Set_Title('Special Characters used in SS_Config Table');
        $Special->Set_Headers( [ 'Default', 'Description', 'Example' ] );
        $Special->Set_Row( [ 'USERNAME',      'Name of User setting up sequencer',                           'Duane' ] );
        $Special->Set_Row( [ 'WELL',          'Well name',                                                   'A01' ] );
        $Special->Set_Row( [ 'PLATEID',       'Barcode for plate',                                           'MUL000123 or PLA0125' ] );
        $Special->Set_Row( [ 'PLATESIZE',     'plate size/format',                                           '96-Well' ] );
        $Special->Set_Row( [ 'PLATENAME',     'Name of Plate',                                               'CN0011a' ] );
        $Special->Set_Row( [ 'CHEMISTRYCODE', 'Chemistry Branch (indicating Primer chemistry)',              'E7' ] );
        $Special->Set_Row( [ 'VERSION',       'Version (applicable for multiple runs using same chemistry)', '.2' ] );
        $Special->Set_Row( [ 'COMMENTSTRING', 'Specially added comments',                                    '' ] );
        $Special->Set_Row( [ 'AUTOCOMMENT',   'Automatically generated comments',                            '' ] );
        $Special->Set_Row( [ 'TERMINATOR',    'Terminator',                                                  'Big Dye' ] );
        $Special->Printout();
        return;
    }
    return ($reads);
}

#############################
sub generate_SS_request {
#############################
    #
    # generate request file to automatically copy to NT machines...
    #
    my $file         = shift;
    my $equipment_id = shift;
    my $suffix       = shift || '';    ### generally leave blank (allows for test files to be created)..

    my $REQUEST;
    open( REQUEST, ">>$request_dir/Request$suffix.$equipment_id" ) or return "Error opening  request file: $request_dir/Request$suffix.$equipment_id";
    print REQUEST "$file\n";
    return "Request$suffix.$equipment_id";
}

#############################
sub replace_special_ss_default {
#############################
    # Replace the special SS_Default values.
    #
    my $ss_default = shift;            #Pass in the value by reference.
    my $arguments  = shift;
    my %values     = %{$arguments};    #Values to be used; passed in a hash format.

    my $target = $values{'Target'} || 'file';

    foreach my $key ( keys %values ) {
        my $value = $values{$key};
        if ( $target =~ /screen/i ) { $value =~ s /\s/_/g; }
        $ss_default =~ s /$key/$value/g;
    }
    return $ss_default;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

##############
sub _next_well {
##############
    my $well_row = shift;
    my $well_col = shift;
    my %args     = @_;

    my $direction = $args{fill};
    my $start_row = $args{start_row};
    my $start_col = $args{start_col};
    my $max_row   = $args{max_row};
    my $max_col   = $args{max_col};

    if ( $direction =~ /col/i ) {    ### list in columns...
        if ( $well_row eq $max_row ) {

            #Only want to print up to "P" for x-coordinate.
            $well_row = $start_row;
            $well_col++;
        }
        else {
            $well_row++;
        }
    }
    elsif ( $direction =~ /row/i ) {    ### list in rows...
        if ( $well_col eq $max_col ) {

            #Only want to print up to "P" for x-coordinate.
            $well_col = $start_col;
            $well_row++;
        }
        else {
            $well_col++;
        }
    }
    return ( $well_row, $well_col );
}

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

$Id: Sample_Sheet.pm,v 1.106 2004/11/19 22:29:12 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
