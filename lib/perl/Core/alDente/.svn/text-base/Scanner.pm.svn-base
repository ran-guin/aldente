################################################################################
#
# Scanner.pm
#
# This module handles routines specific to Sequencing (Sample Sheets set up)
#
###############################################################################
# $Id: Scanner.pm,v 1.57 2004/12/08 18:21:39 jsantos Exp $
################################################################################
# CVS Revision: $Revision: 1.57 $
#     CVS Date: $Date: 2004/12/08 18:21:39 $
################################################################################
package alDente::Scanner;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Scanner.pm - Sequence.pm

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

Sequence.pm<BR>This module handles routines specific to Sequencing (Sample Sheets set up)<BR>

=cut

##############################
# superclasses               #
##############################
use base SDB::DB_Object;

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################

use CGI qw(:standard);
use DBI;

use strict;
##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;    #### HTML_Table generator, Colour Map generator routines
use Data::Dumper;
#### Sequencing Database Handling Routines
use alDente::Form;     ### Set_Parameters
use alDente::SDB_Defaults;
use alDente::Barcoding;

use LampLite::Bootstrap;
use LampLite::Form;

# use alDente::Container;

use alDente::Tray;
use RGTools::RGmath qw(merge_Hash);

my $q  = new CGI;
my $BS = new Bootstrap;

#__DATA__;
##############################
# global_vars                #
##############################
#use vars qw($barcode);
use vars qw(@libraries);
use vars qw($sets);
use vars qw($dbase $testing $Connection $q);
use vars qw($dbase $login_name $login_pass $trace_level);
use vars qw($track_sessions $scanner_mode);
use vars qw(%Parameters %Prefix);
use vars qw($fasta_dir);

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
##########
sub new {
##########
    #
    # Constructor of the object
    #
    my $this = shift;

    my %args     = @_;
    my $id       = $args{-id};
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $retrieve = $args{-retrieve};                                                                 ## retrieve information right away [0/1]
    my $verbose  = $args{-verbose};

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc );
    my $class = ref($this) || $this;
    bless $self, $class;

    $self->{DBobject} = '';                                                                          ## will be set to Solution / Box / Equipment etc.
    $self->{dbc}      = $dbc;

    return $self;
}

##############################
# public_methods             #
##############################

##############################
# public_functions           #
##############################

#
# Standard home page for the mobile version
#
# Return: home page
#################
sub home_page {
#################
    my $dbc = shift;

    require alDente::Solution_Views;
    import alDente::Solution_Views;

    my $plate_set_icon = $BS->icon('archive fa-2x');
    my $solution_icon  = $BS->icon('flask fa-2x');
    my $throw_out_icon = $BS->icon('trash-o fa-2x');
    my $search_icon    = $BS->icon('search fa-2x');

    my $plate_set = alDente::Login_Views->plate_set_button( -dbc        => $dbc );
    my $solutions = alDente::Solution_Views::display_scanner_mode( -dbc => $dbc );
    my $search    = alDente::Login_Views->search_button( -dbc           => $dbc );

    my $plate_set_label = "<BR><BR><B>Retrieve Plate Set</B><BR><BR>" . $plate_set_icon . lbr . lbr . lbr;
    my $plate_set_body  = $plate_set . "<BR>Enter Plate Set Number to retrieve previously defined group of plates/tubes.";
    my $plate_set_modal = $BS->custom_modal(
        -id    => 'plate-set-modal',
        -label => $plate_set_label,
        -title => 'Retrieve Plate Set',
        -body  => $plate_set_body,
        -type  => 'default',
        -size  => 'large',
        -style => 'width:100%; float:left;'
    );

    my $solution_label = "<BR><BR><B>Prepare Standard Solution</B><BR><BR>" . $solution_icon . lbr . lbr . lbr;
    my $solution_modal = $BS->custom_modal(
        -id    => 'solution-modal',
        -label => $solution_label,
        -title => 'Prepare Standard Solution',
        -body  => $solutions,
        -type  => 'default',
        -size  => 'large',
        -style => 'width:100%; float:left;'
    );

    my $form            = new LampLite::Form( -dbc => $dbc, -wrap => 0 );
    my $throw_out_label = "<BR><BR><B>Throw Out</B><BR><BR>" . $throw_out_icon . lbr . lbr . lbr;
    my $throw_out_plate = $form->generate(
        -wrap    => 1,
        -class   => 'nomargin',
        -content => textarea(
            -value       => '',
            -rows        => 8,
            -columns     => 45,
            -force       => 1,
            -id          => 'Plate IDs',
            -name        => 'Plate IDs',
            -placeholder => 'Please enter a list of plates or range of plates to throw out.'
            )
            . lbr
            . lbr
            . $BS->button(
            -id    => 'throw-out-plates',
            -value => 'Throw Out Plates',
            -label => 'Throw Out Plates',
            -class => 'search Action',
            ),
        -include => "<input type='hidden' value='alDente::Container_App' name='cgi_application'></input>"
    );
    my $throw_out_solution = $form->generate(
        -wrap    => 1,
        -class   => 'nomargin',
        -content => textarea(
            -value       => '',
            -rows        => 8,
            -columns     => 45,
            -force       => 1,
            -id          => 'Solution_ID',
            -name        => 'Solution_ID',
            -placeholder => 'Please enter a list of solutions to throw out.'
            )
            . lbr
            . lbr
            . $BS->button(
            -id    => 'throw-out-solution',
            -value => 'Empty Solution(s)',
            -label => 'Empty Solution(s)',
            -class => 'search Action',
            ),
        -include => "<input type='hidden' value='alDente::Solution_App' name='cgi_application'></input>"
    );
    my $throw_out_body  = $throw_out_plate . "<BR>" . $throw_out_solution;
    my $throw_out_modal = $BS->custom_modal(
        -id    => 'throw-out-modal',
        -label => $throw_out_label,
        -title => 'Throw Out',
        -type  => 'default',
        -size  => 'large',
        -style => 'width:100%; float:left;',
        -body  => $throw_out_body,
    );

    my $search_label = "<BR><BR><B>Search Database</B><BR><BR>" . $search_icon . lbr . lbr . lbr;
    my $search_body  = $search . "<BR>Search key fields in the database:<BR>
                                 <ul>
                                     <li>Use * for a wildcard
                                         <ul>
                                             <li>'ABC*' will return items beginning with 'ABC'</li>
                                         </ul>
                                     </li>
                                     <li>Use square brackets to indicate a range
                                         <ul>
                                             <li>'A[1-3]' will return items matching 'A1', 'A2', or 'A3'</li>
                                             <li>'A[a-c]' will return items matching 'Aa', 'Ab', or 'Ac'</li>
                                         </ul>
                                     </li>
                                     <li>Supply list of options separated by '|'
                                         <ul>
                                             <li>'A|B|C' will return items matching A or B or C</li>
                                         </ul>
                                     </li>
                                 </ul>";
    my $search_modal = $BS->custom_modal(
        -id    => 'search-modal',
        -label => $search_label,
        -title => 'Search Database',
        -body  => $search_body,
        -type  => 'default',
        -size  => 'large',
        -style => 'width:100%; float:left;'
    );

    my $page;
    my $page = "<Table width=100% cellpadding=10px>"
        . "<TR><TD align='center'>$solution_modal</TD></TR>"
        . "<TR><TD align='center'>$throw_out_modal</TD></TR>"
        . "</Table>";
##        = "<div style='width:50%; float:left;'>$plate_set_modal</div>"
 #       . "<div style='width:50%; float:left;'>$solution_modal</div>"
 #       . "<div style='width:50%; float:left;'>$throw_out_modal</div>"
 #       . "<div style='width:50%; float:left;'>$search_modal</div>";

}

#################################
sub Check_Input_Parameters {
#################################
    my $dbc = shift;

    my $user_id = $dbc->get_local('user_id');
    my ( $plate_set, $current_plates );
    ######## Get Barcode ########
    my ( $barcode, $plate_id, $solution_id, $equipment, $equipment_id );
    if ( param('Barcode') || param('Plate Ref') ) {
        $barcode = param('Barcode') || param('Plate Ref') || param('Quick_Action_Value');
        $plate_id     = get_aldente_id( $dbc, $barcode, 'Plate' )     if ( $barcode =~ /$Prefix{Plate}|$Prefix{Tray}/i );
        $solution_id  = get_aldente_id( $dbc, $barcode, 'Solution' )  if ( $barcode =~ /$Prefix{Solution}/i );
        $equipment_id = get_aldente_id( $dbc, $barcode, 'Equipment' ) if ( $barcode =~ /$Prefix{Equipment}/i );

        ($equipment) = $dbc->Table_find( 'Equipment', 'Equipment_Name', "WHERE Equipment_ID in ($equipment_id)" ) if $equipment_id;
    }

    if ( param('Print Multiple Barcode') ) {
        $barcode = param('Barcode');
        &alDente::Barcoding::PrintBarcode( $dbc, 'Multiple', $barcode );
    }
    if ( param('Clear Plate Set') ) {
        require alDente::Container;    ## dynamically load module ##
        import alDente::Container;
        &alDente::Container::clear_plate_set();
    }
    elsif ( param('Current Plates') =~ /\d+/ ) {
        ($current_plates) = param('Current Plates');

        #	$dbc->{current_plates} = [split ',', $current_plates];  updated below
    }
    elsif ( $plate_id > 0 ) {
        $current_plates = $plate_id;

        #	$dbc->{current_plates} = [split ',', $current_plates];  updated below
    }

####### generate list of solution_ids or equipment_ids used #################
    if ( param('Solution_ID') ) { $solution_id = join ',', param('Solution_ID'); }
    if ( param('Equipment') ) {
        $equipment = param('Equipment');
        if ( $equipment =~ /equ(\d+):\s?(\S*)/i ) { $equipment = $2; $equipment_id = $1; }
        else                                      { $equipment_id = join ',', $dbc->Table_find( 'Equipment', 'Equipment_ID', "WHERE Equipment_Name like \"$equipment\"" ); }
    }

    if ($testing) {
        print "\n(ps = $plate_set, Equip ID = $equipment_id, User = $user_id)";
    }
    $current_plates =~ s/^[0]+//;
    $current_plates =~ s/,[0]+/,/g;
    $current_plates =~ s/NULL//g;
    $current_plates =~ s/^,//;

    ######## Plate Set ################
    if ( param('Clear Plate Set') ) { }
    elsif ( param('Plate Set') ) {
        $plate_set = param('Plate Set');
        $current_plates = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "WHERE Plate_Set_Number in ($plate_set) ORDER BY Plate_Set_ID" );
    }
    elsif ( param('Plate ID') ) {
        $plate_id = param('Plate ID');
    }

    $current_plates ||= $plate_id;
    $dbc->{current_plates} = [ split ',', $current_plates ];

    if ( param('Grab Plate Set') || param('Quick_Action_List') eq 'Plate Set' ) {
        $plate_set = param('Plate Set Number') || param('Quick_Action_Value') || param('Barcode');

        if ( param('Grab Plate Set') ) { $plate_set ||= param('Barcode') }    ## scanner main page

        if ( $plate_set =~ /^\d+$/ ) {
            $current_plates = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "WHERE Plate_Set_Number=$plate_set ORDER BY Plate_Set_ID" );
            unless ( $current_plates =~ /\d+/ ) {
                Message("INVALID PLATE SET: No Current Plates (?) ");
                return alDente::Web::GoHome( $dbc, $Current_Department, -quiet => 1 );
            }
        }
    }
    elsif ( param('Recover Set') ) {
        my $chosen = param('Chosen Set');
        require alDente::Container_Set;                                       ## dynamically import ##
        import alDente::Container_Set;
        my $Set = alDente::Container_Set->new( -ids => $current_plates, -dbc => $dbc, -recover => 1, -set => $chosen );
        if ( $Set->{set_number} ) {
            $plate_set      = $Set->{set_number};
            $current_plates = $Set->{ids};
        }
    }

    $dbc->{current_plates} = [ split ',', $current_plates ];
    return 1;
}

#
# Accessor to enable conversion of encrypted barcode if necessary (simplifies customization if necessary across multiple use cases)
#
#
######################
sub scanned_barcode {
######################
    my %args    = filter_input( \@_, -args => 'param' );
    my $param   = $args{-param};
    my $barcode = $args{-barcode};

    my $q = new CGI;

    $barcode ||= $q->param($param);

    ## Custom encryption of barcode if necessary ##
    # while ($barcode =~s/Rac(\d+)/Loc$1/i) {}  ## convert old Rac prefix to Loc prefix...

    return $barcode;
}

#############################
sub Check_Scan_Options {
#############################
    #
    # Sets various parameters if a new 'Barcode' is 'Scanned'
    #
    #  may set new:
    #    - $barcode
    #    - $current_plates
    #    - $plate_id
    #    - $solution_id
    #    - $equipment_id
    #
    #
############################
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    $dbc->warning("This method should be phased out and handled via the Scanner_App");
    Call_Stack();

    my ( $barcode, $current_plates );
    if ( param('Scan') || ( param('Quick_Action_List') eq 'Scan' && param('Quick_Action_Value') ) ) {
        $barcode = param('Barcode') || param('Quick_Action_Value');    ### Scan button should be accompanied by 'Barcode' textfield

        if ( $barcode =~ /$Prefix{Tray}\d+/i ) {                       ## moved
            $current_plates = get_aldente_id( $dbc, $barcode, 'Plate' );
            $dbc->{current_plates} = [ split ',', $current_plates ];

            unless ($current_plates) { Message("Invalid barcode $barcode, tray not available"); return 0; }
            my $plates_barcode = join '', map {"pla$_"} split( ',', $current_plates );
            print h2( 'Trays: ' . join ', ', map { $_ = get_FK_info( $dbc, 'FK_Tray__ID', $_ ) } split ',', get_aldente_id( $dbc, $barcode, 'Tray' ) );
            ### Remove all the tray barcodes from the barcode and replace it with the pla barcodes
            while ( $barcode =~ s/($Prefix{Tray})\d+-($Prefix{Tray})\d+(\D|$)/$3/i )   { }
            while ( $barcode =~ s/($Prefix{Tray})\d+(\D|$)/$2/i )                      { }
            while ( $barcode =~ s/($Prefix{Tray})\d+\([a-d,\-1-8]+\)(\D|$)/$2/i )      { }
            while ( $barcode =~ s/($Prefix{Plate})\d+-($Prefix{Plate})\d+(\D|$)/$3/i ) { };    ## should match pattern in DBIO.pm, Tray.pm
            while ( $barcode =~ s/($Prefix{Plate})\d+(\D|$)/$2/i )                     { }
            $barcode .= $plates_barcode;
        }
        elsif ( $barcode =~ /enc(\d+)/i ) {                                                    ## ?????
            ### if 'Mul' barcode used (compresses multiple plates/equipment onto one barcode)
            my $expanded;
            while ( $barcode =~ /enc(\d+)/i ) {
                ### if multiple plates used - expand to list of plates
                ($expanded) = $dbc->Table_find( 'Multiple_Barcode', 'Multiple_Text', "WHERE Multiple_Barcode_ID=$1" );
                if ($expanded) {
                    $barcode =~ s /enc$1/$expanded/i;
                }
                else {
                    Message("Invalid barcode enc$1");
                    return 0;
                }
            }
            print alDente::Form::start_alDente_form( $dbc, '', undef );
            print $q->submit( -name => 'Print Multiple Barcode', -value => 'Print Multiple Barcode', -style => "background-color:lightblue" ), hidden( -name => 'Barcode', -value => $barcode ), lbr, "\n</Form>";
        }

        ## Special Handling for Rearrays (rry)
        if ( $barcode =~ /^(rry)(\d+)(.*)/i ) {    ## all moved
            require Sequencing::ReArray;
            my $rearray_id = $2;
            my $plates     = $3;
            $plates = &get_aldente_id( $dbc, $plates, 'Plate' );
            if ($plates) {                         ## Moved
                ## validate plates against source plate list
                my $seq_rearray_obj = new Sequencing::ReArray( -dbc => $dbc );
                $seq_rearray_obj->validate_source_plates( -request_ids => $rearray_id, -source_plates => $plates );
            }
            else {                                 ## Moved
                ## display rearray view
                if ($scanner_mode) {
                    Message("Rearrays should be viewed with desktop, aborting...");
                }
                else {
                    require alDente::ReArray_Views;
                    print alDente::ReArray_Views::view_rearrays( -dbc => $dbc, -request_ids => $rearray_id );
                }
            }
            &main::leave();
        }
        elsif ( ( $barcode =~ /Pla\d+/i ) && ( $barcode =~ /mry\d+/i ) ) {    ## Moved
            my $microarray_id = &get_aldente_id( $dbc, $barcode, 'Microarray', -validate => 1 );
            my $plate_id      = &get_aldente_id( $dbc, $barcode, 'Plate',      -validate => 1 );

            require alDente::Array;
            my $mo = new alDente::Array( -dbc => $dbc );
            my $new_plate_id = $mo->create_array( -plate_id => $plate_id, -microarray_id => $microarray_id );
            if ($new_plate_id) {
                &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $new_plate_id );
                &alDente::Info::GoHome( $dbc, -table => 'Plate', -id => $new_plate_id );
            }
            &main::leave();
        }
        elsif ( $barcode =~ /mry\d+/i ) {    ## Moved
            my $id = &get_aldente_id( $dbc, $barcode, 'Microarray', -validate => 1 );
            require alDente::Microarray;
            my $mo = new alDente::Microarray( -dbc => $dbc, -id => $id );
            $mo->home_page();
            &main::leave();
        }
        elsif ( ( $barcode =~ /Pla\d+/i ) && ( $barcode =~ /Sol\d+/i ) ) {    ## Moved
            &alDente::Scanner_Views::Validate_Solution( $dbc, $barcode );
            &main::leave();
        }
        ###### Go to sample sheet preparation if Plate AND Equipment... ###########
        elsif ( $barcode =~ /Equ\d+/i ) {

            my $validate = 1;                                                 #
            if ( $barcode =~ /^Equ(\d+)$/i ) { $validate = 0 }                ## exclude validation if equipment scanned alone ##
            my $equipment_list = &get_aldente_id( $dbc, $barcode, 'Equipment', -validate => $validate, -quiet => 1 );
            my @equipment_ids = split ',', $equipment_list;
            unless ($equipment_list) { Message("Warning: Equipment invalid or Inactive ($barcode)."); return 0; }
            my $type = join ',',
                $dbc->Table_find(
                'Equipment,Stock,Stock_Catalog,Equipment_Category',
                'Category',
                "where Equipment_ID in ($equipment_list) AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID",
                -distinct => 1
                );
            my $sub_category = join ',',
                $dbc->Table_find(
                'Equipment,Stock,Stock_Catalog,Equipment_Category',
                'Sub_Category',
                "where Equipment_ID in ($equipment_list) AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID",
                -distinct => 1
                );

            if ( $type =~ /,/ || $type =~ /,/ ) {    ## ????
                Message("Warning: Different types of equipment scanned");
                return 0;
            }

            if ( $barcode =~ /Pla/i ) {              ## All moved

                $current_plates = &get_aldente_id( $dbc, $barcode, 'Plate', -validate => 1 );
                $dbc->{current_plates} = [ split ',', $current_plates ];

                unless ($current_plates) { Message("No Valid Plates in $barcode"); return 0; }

                ## moved
                my $possible_move = 0;
                if ( $equipment_list !~ /,/ ) {

                    # check to see if the equipment has a single rack
                    # if it does, it is possible to move the rack to that equipment
                    my @rack_id = $dbc->Table_find( "Rack", "Rack_ID", "WHERE FK_Equipment__ID = $equipment_list" );
                    if ( int(@rack_id) == 1 && $rack_id[0] > 0 ) {
                        $possible_move = $rack_id[0];
                    }
                }

                # check if equipment id a Sequencer or a Genechip Scanner
                if ( $type =~ /Sequencer/i && ( $sub_category =~ /3100/i || $sub_category =~ /3700/i || $sub_category =~ /3730/i ) || $sub_category =~ /MB/i ) {    ## Moved

                    if ( int(@equipment_ids) > 1 ) {
                        Message("Error: Cannot use multiple equipment on plates at once");
                        return 0;
                    }

                    require Sequencing::Sample_Sheet;                                                                                                               ## dynamically load module ##
                    import Sequencing::Sample_Sheet;

                    require Sequencing::Sequence;                                                                                                                   ## dynamically load module ##
                    import Sequencing::Sequence;

                    require alDente::Container;

                    print &alDente::Container::Display_Input($dbc);
                    unless ( &Sequencing::Sample_Sheet::preparess( $dbc, $barcode ) ) {
                        ### returns value if successful
                        &Sequencing::Sequence::sequence_home();
                    }
                }
                elsif ( $type =~ /Sequencer/i && ( $sub_category =~ /Genome Analyzer/i || $sub_category =~ /HiSeq/i ) ) {                                           ## Moved
                    require Sequencing::SolexaRun;
                    my @plate_ids = split ',', $current_plates;
                    Sequencing::SolexaRun::display_SolexaRun_form( -dbc => $dbc, -equipment_id => $equipment_list, -plate_ids => \@plate_ids );
                }
                elsif ( $type =~ /Sequencer/i && $sub_category =~ /SOLID/i ) {                                                                                      ## Moved
                    require SOLID::SOLIDRun;
                    my @plate_ids = split ',', $current_plates;
                    SOLID::SOLIDRun::display_SOLIDRun_form( -dbc => $dbc, -equipment_id => $equipment_list, -plate_ids => \@plate_ids );
                }
                elsif ( $type =~ /Sequencer/i && $sub_category =~ /Cluster Station/i ) {                                                                            ## Moved
                    ## require Flowcell
                    ## add flowcell information to the tray
                    require Illumina::Flowcell;
                    my ($tray_id) = $dbc->Table_find( "Plate_Tray", "FK_Tray__ID", "WHERE FK_Plate__ID IN ($current_plates)" );
                    Illumina::Flowcell::display_flowcell_form( -dbc => $dbc, -tray_id => $tray_id );

                }
                elsif ( $type =~ /Sequencer/i && $sub_category =~ /cBot Cluster Generation System/i ) {                                                             ## Moved
                    ## require Flowcell
                    ## add flowcell information to the tray
                    require Illumina::Flowcell;
                    my ($tray_id) = $dbc->Table_find( "Plate_Tray", "FK_Tray__ID", "WHERE FK_Plate__ID IN ($current_plates)" );
                    Illumina::Flowcell::display_flowcell_form( -dbc => $dbc, -tray_id => $tray_id );

                }
                elsif ( $type =~ /GeneChip System/i && $sub_category =~ /Scanner/i ) {                                                                              ## Moved
                    require Lib_Construction::GCOS_SS;
                    import Lib_Construction::GCOS_SS;

                    my $ss = new Lib_Construction::GCOS_SS( -dbc => $dbc );
                    $ss->assign_scanner( -plate_id => $current_plates, -equipment_id => $equipment_list );
                }
                elsif ( $sub_category =~ /Hyb Oven/ ) {                                                                                                             ## Moved
                    require Lib_Construction::GCOS_SS;
                    import Lib_Construction::GCOS_SS;

                    my $ss = new Lib_Construction::GCOS_SS( -dbc => $dbc );
                    $ss->prompt_ss( -plate_id => $current_plates, -equipment_id => $equipment_list );
                }
                elsif ( $type =~ /Gel Box/i ) {                                                                                                                     ## Moved
                    Message("Starting Gel Runs");
                    require alDente::GelRun;
                    my @plate_ids = split ',', $current_plates;
                    my @runs = split ',', get_aldente_id( $dbc, $barcode, 'Run' );
                    alDente::GelRun::start_gelruns( -gelboxes => \@equipment_ids, -plates => \@plate_ids, -gelruns => \@runs ) or &main::leave();
                }
                elsif ( $type =~ /Spectrophotometer/i ) {                                                                                                           ## Moved
                    require alDente::SpectRun;
                    &alDente::SpectRun::spect_request_form( -plate => $current_plates, -scanner => $equipment_list );
                }
                elsif ( $type =~ /Bioanalyzer/i ) {                                                                                                                 ## Moved
                    require alDente::BioanalyzerRun;
                    &alDente::BioanalyzerRun::bioanalyzer_request_form( -plate => $current_plates, -scanner => $equipment_list );
                }
                elsif ($possible_move) {                                                                                                                            ## Moved

                    # if not a scanner or a sequencer and the equipment has one rack, the plate should be
                    # moved to that single rack.
                    require alDente::Rack;                                                                                                                          ## dynamically load module ##
                    import alDente::Rack;

                    # replace equ with rack
                    $barcode =~ s/equ\d+/rac${possible_move}/i;
                    print &alDente::Rack_Views::Rack_home( $dbc, $possible_move, $barcode );
                    &main::leave();
                }
                else {
                    Message("Warning: Cannot apply plate to any equipment type (only some). Please use a protocol");
                }
            }
            elsif ( $barcode =~ /sol/i ) {                                                                                                                          ## all moved

                # check to see if equipment and solution are scanned together,
                # and that they are sequencer and matrix/buffer
                # prompt for confirmation if they are
                if ( $type =~ /sequencer/i ) {                                                                                                                      ## moved
                    my $sols              = &get_aldente_id( $dbc,        $barcode,      'Solution' );
                    my @matrixbuffers     = $dbc->Table_find( "Solution", "Solution_ID", "WHERE Solution_Type in ('Matrix','Buffer') AND Solution_ID in ($sols)" );
                    my @not_matrixbuffers = $dbc->Table_find( "Solution", "Solution_ID", "WHERE Solution_Type not in ('Matrix','Buffer') AND Solution_ID in ($sols)" );
                    if ( int(@not_matrixbuffers) > 0 ) {
                        Message("solutions @not_matrixbuffers are not Matrices or Buffers. Ignoring...");
                    }
                    require alDente::Equipment;
                    alDente::Equipment::confirm_MatrixBuffer( -equipment_id => $equipment_list, -sol_id => \@matrixbuffers );

                }
                elsif ( $type =~ /Gel Comb/i ) {                                                                                                                    ## Moved
                    my @gel_trays;
                    my $solutions = &get_aldente_id( $dbc, $barcode, 'Solution' );

                    unless ($solutions) {
                        return 0;
                    }

                    my $agarose_pattern = "(Stock_Catalog_Name like '%Agarose%' OR Stock_Catalog_Name like '%Mediaprep%')";
                    my @agarose = $dbc->Table_find( "Solution,Stock,Stock_Catalog", 'Solution_ID', "WHERE FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_ID=FK_Stock__ID AND Solution_ID =$solutions AND $agarose_pattern" );

                    unless (@agarose) {
                        Message("Error: Solution $solutions : is not an Agarose Solutions");
                    }
                    else {
                        @gel_trays = split ',', &get_aldente_id( $dbc, $barcode, 'Rack' ) if ( $barcode =~ /rac/i );

                        if ( @gel_trays && scalar(@gel_trays) != scalar(@equipment_ids) ) {
                            Message("Error: Incorrect number of Comb and GelRun Tray scanned");

                            #Testing
                            #print HTML_Dump(\@gel_trays,\@equipment_ids);
                        }
                        else {
                            require alDente::GelRun;
                            alDente::GelRun::gel_request_form( -gel_trays => \@gel_trays, -solution => $solutions, -combs => \@equipment_ids );
                        }
                    }
                }
                else {
                    Message("You can not apply solution to equipment of type: $type - $sub_category");
                }
            }
            elsif ( $barcode =~ /$Prefix{Rack}(\d+)(\w?\d?)/i ) {
                my $rack_id = $1;
                my $slot    = $2;
                require alDente::Rack;    ## dynamically load module ##
                print alDente::Rack_Views::Rack_home( $dbc, $rack_id, $barcode, -slot_choice => $slot );

            }
            else {                        ## moved
                $equipment_list =~ s /,/Equ/g;
                require alDente::Info;    ## dynamically load module ##
                import alDente::Info;
                &alDente::Info::info( $dbc, 'Equ' . $equipment_list );
            }
            &main::leave();
        }

        ### Rack Handling (may move Racks or Move Plates/Tubes/Solutions onto Rack)
        elsif ( $barcode =~ /$Prefix{Rack}(\d+)/i ) {
            ## remove slot option as a suffix (prompted anyways if slots available)

            #	    print Scanner_version_temp($dbc,$barcode);

            #	    print alDente::Rack_Views::Rack_home( $dbc, -original_barcode=> $barcode); ##\@racks, \@items);   ## , -slot_choice => $slot );
            &main::leave();
        }
        ###### Standard Tube Home Page ##############
        elsif ( $barcode =~ /tub\d+/i ) {    ## ???, alDente::Tube::home_tube not there anymroe
            my $tube_id   = &get_aldente_id( $dbc, $barcode, 'Tube' );
            my $solutions = &get_aldente_id( $dbc, $barcode, 'Solution' );

            require alDente::Tube;           ## dynamically load module ##
            import alDente::Tube;

            if ( $tube_id =~ /[0-9]/ ) {
                &alDente::Tube::home_tube( $tube_id, $solutions, $barcode );
            }
            else {
                Message("Invalid Tube listed in $barcode");
                &main::home('main');
            }
            &main::leave();
        }

        ######## Standard Plate Home Page...
        elsif ( $barcode =~ /($Prefix{Plate})(\d+)/i ) {    ## Moved

            my $prefix = $1;

            # $barcode =~ s/$Prefix{Plate}/Pla/gi;
            $current_plates = &get_aldente_id( $dbc, $barcode, 'Plate', undef, undef, 'feedback' );
            $dbc->{current_plates} = [ split ',', $current_plates ];

            require alDente::Info;                          ## dynamically load module ##
            import alDente::Info;
            if ( $current_plates =~ /^(\d+)/ ) {
##		print &alDente::Container::Display_Input;  ## displayed below in home page for plate...
                $plate_id  = $1;                            ### set plate id to FIRST plate if more than one
                $barcode   = $prefix . $plate_id;
                $plate_set = "";

                #&alDente::Info::info($dbc,$barcode); ## using this call does not use the HomePage Session variable to go back
                &alDente::Info::GoHome( $dbc, -table => 'Plate', -id => $plate_id );
            }
            else {
                &main::home('main');
            }
            &main::leave();
        }

        ###### Standard Solution Home Page ...
        elsif ( $barcode =~ /Sol(\d+)/i ) {    ## Moved
            $solution_id = &get_aldente_id( $dbc, -barcode => $barcode, -table => 'Solution' );
            require alDente::Info;             ## dynamically load module ##
            import alDente::Info;
            if ( $solution_id =~ /[1-9]/ ) {
                &alDente::Info::info( $dbc, $barcode );
            }
            else {
                Message("Invalid Solution ID ($barcode)");
                &main::home('main');
            }
            &main::leave();
        }

        ##### Re-Login by scanning employee ID and password.
        elsif ( $barcode =~ /Emp(\d+)$/i ) {    ## Moved
            $user_id = $1;
            require alDente::Info;              ## dynamically load module ##
            import alDente::Info;
            &alDente::Info::GoHome( $dbc, 'Employee', $user_id );
            return 1;
        }
        elsif ( $barcode =~ /Emp(\d+)([a-zA-Z]\w*)/i ) {    ## ???
            $user_id = $1;

            #$password = $2; #password
            unless ( $user_id =~ /[1-9]/ ) {
                Message("Not Valid User ($user_id)");
                &leave();
            }

            #Eedirect back to home page.
            &main::home('main');
            return 1;
        }

        ##### Sample home page ....
        elsif ( $barcode =~ /Sam(\d+)/i ) {    ## Moved
            require alDente::Info;             ## dynamically load module ##
            &alDente::Info::GoHome( $dbc, 'Sample', $1 );
            &main::leave();
        }

        ##### Library container page ....
        elsif ( $barcode =~ /Src(\d+)/i ) {    ## Moved
            my $table = 'Source';
            my $list = get_aldente_id( $dbc, $barcode, $table );

            require alDente::Info;             ## dynamically load module ##
            import alDente::Info;
            if ( $list =~ /^(\d+)/ ) {
                &alDente::Info::GoHome( $dbc, 'Source', $1, -list => $list );
            }
            else {
                Message("Invalid Source ID ($barcode)");
                &main::home('main');
            }
            &main::leave();
        }
        elsif ( $barcode =~ /testmatrix/i ) {
            TestRoutine( -dbc => $dbc );
            &main::home('main');
            &main::leave();
        }
        ###### clear non-specified parameters
        else {
            $current_plates = "";
            $dbc->{current_plates} = [ split ',', $current_plates ];

            require alDente::Info;    ## dynamically load module ##
            import alDente::Info;
            unless ( &alDente::Info::info( $dbc, $barcode ) ) {
                ### try retrieving info
                &main::home('main');
            }
            &main::leave();
        }
    }
    elsif ( param('Info') ) {
        my $table = param('Table');
        my $field = param('Field') || '';
        my $value = param('Like') || 0;
        ############ Custom for Plates ? #####################################
        if ( ( $table eq 'Plate' ) && ( $field eq 'Plate_ID' ) && $value ) {

            require alDente::Container;    ## dynamically load module ##
            import alDente::Container;
            my $sets = alDente::Container::get_Sets( -dbc => $dbc, -id => $value ) || 0;
            my $parents = alDente::Container::get_Parents( -dbc => $dbc, -id => $value, -format => 'list', -simple => 1 );

            my %prep_comments = &Table_retrieve(
                $dbc, 'Prep,Plate_Prep',
                [ 'FK_Plate_Set__Number as Plate_Set', 'Prep_Comments as Comment', 'FK_Plate__ID as Plate' ],
                "where Length(Prep_Comments) > 0 AND FK_Prep__ID = Prep_ID AND FK_Plate_Set__Number in ($sets) AND (FK_Plate__ID in ($parents) OR FK_Plate__ID is NULL)", 'Distinct'
            );

            print "<span class=small><B>Sets: $sets.</B><BR>";
            my @parent_list = split ',', $parents;
            if ( int(@parent_list) > 16 ) {
                $parents = '(' . int(@parent_list) . ' distinct plates..)';
            }
            print "<B>Parents: $parents.</B><BR>";
            my $Comments = HTML_Table->new();
            $Comments->Set_Title("<B>Comments during Prep:</B>");
            $Comments->Set_Headers( [ 'Set', 'Plate', 'Comment' ] );
            my $index = 0;
            while ( defined $prep_comments{Plate_Set}[$index] ) {
                my $set     = $prep_comments{Plate_Set}[$index];
                my $comment = $prep_comments{Comment}[$index];
                my $plate   = $prep_comments{Plate}[$index];
                $index++;
                if   ( $plate =~ /[1-9]/ ) { $plate = "Pla$plate"; }
                else                       { $plate = '(all)'; }
                $Comments->Set_Row( [ $set, $plate, $comment ] );
            }
            if ($index) {
                $Comments->Printout();
            }
            else {
                print "(No comments during Preparation)";
            }
            print "</span>";
            print &vspace(10);

            return 0;    ## still print out the rest of the stuff...
        }
    }
############## End Custom section.. ##################################
    else { return 0; }    ### nothing new scanned.... (continue)
    return 0;
}

###################################
sub parse_items_from_barcode {
###################################
    my %args    = filter_input( \@_, -args => 'barcode,dbc' );
    my $barcode = $args{-barcode};
    my $dbc     = $args{-dbc};
    my @items;

    for my $object ( keys %Prefix ) {
        my $ids = get_aldente_id( $dbc, $barcode, $object );
        my @ids;
        @ids = split ',', $ids;
        for my $id (@ids) {
            push @items, $Prefix{$object} . $id;
        }
    }

    return @items;
}

####################
sub convert_to_id {
####################
    my %args    = filter_input( \@_, -args => 'dbc,barcode,table' );
    my $dbc     = $args{-dbc};
    my $barcode = $args{-barcode};
    my $table   = $args{-table};

    my $value;
    if   ( $barcode =~ /^([A-Za-z]){3}(\d+)$/ ) { $value = $2 }         ## <CONSTRUCTION> - fix this for library ... need to retrieve from a better wrapper method in DBIO
    else                                        { $value = $barcode }

    return $value;
}

####################
sub TestRoutine {
####################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $rows = 10;
    my $cols = 6;

    print "Generate $rows x $cols form...";

    print start_form( -action => $dbc->homelink() );
    my $Form = HTML_Table->new();
    $Form->Set_Padding(0);

    #    $Form->Set_Spacing(0);
    foreach my $row ( 1 .. $rows ) {
        my @row = ("Row$row");
        foreach my $col ( 1 .. $cols ) {
            push( @row, textfield( -name => "R$row" . "C$col", -size => 15, default => "Row$row" . "Col$col" ) );
        }
        $Form->Set_Row( \@row );
    }
    $Form->Printout();
    print end_form();

    return 1;
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

$Id: Scanner.pm,v 1.57 2004/12/08 18:21:39 jsantos Exp $ (Release: $Name:  $)

=cut

1;
