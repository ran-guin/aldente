################################################################################
# Library_Plate.pm
#
# This module handles Container (Plate) based functions
#
###############################################################################
package alDente::Library_Plate;

##############################
# perldoc_header             #
##############################Container_Views::select_wells_on_plate

=head1 NAME <UPLINK>

Library_Plate.pm - This module handles Container (Plate) based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Container (Plate) based functions<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(alDente::Container);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use Data::Dumper;
use RGTools::Barcode;

##############################
# custom_modules_ref         #
##############################
use alDente::Form;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use alDente::Well;
use alDente::ReArray;
use alDente::Container;
use alDente::Run;
use alDente::Tools;
use alDente::Validation;
use SDB::DBIO;
use SDB::Transaction;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
use vars qw($project_dir $Sess $current_plates );
use vars qw($testing);

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

########
sub new {
########
    #
    # Constructor
    #
    my $this = shift;
    my %args = @_;

    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id         = $args{-id};
    my $ids        = $args{-ids};
    my $plate_id   = $args{-plate_id} || 0;
    my $attributes = $args{-attributes};                                                              ## allow inclusion of attributes for new record
    my $encoded    = $args{-encoded} || 0;                                                            ## reference to encoded object (frozen)

    my ($class) = ref($this) || $this;

    #    my $self = SDB::DB_Object->new(-dbc=>$dbc,-table=>'Library_Plate',-id=>$id,-encoded=>$encoded);

    my $self = alDente::Container->new( -dbc => $dbc, -encoded => $encoded );

    $self->{dbc} = $dbc;

    bless $self, $class;

    $self->add_tables('Library_Plate');

    if ($plate_id) {
        $self->{plate_id} = $plate_id;
        $self->primary_value( -table => 'Plate', -value => $plate_id );    ## same thing as above..
        $self->load_Object( -type => 'Library_Plate' );
        $self->{id} = $self->get_data('Library_Plate_ID');
    }
    elsif ($id) {
        ## Library Plate ID supplied ##
        $self->{id} = $id;                                                 ## list of current plate_ids
        $self->primary_value( -table => 'Library_Plate', -value => $id );  ## same thing as above..
        $self->load_Object( -type => 'Library_Plate' );
        $self->{plate_id} = $self->value('Plate.Plate_ID');
    }
    elsif ($attributes) {

        #	$self->add_Record(-attributes=>$attributes);
    }

    return $self;
}

##############################
# public_methods             #
##############################
sub home_page {
    my $self   = shift;
    my %args   = @_;
    my $simple = $args{-simple};

    Call_Stack();
    return "This method has been deprecated... standardize by simply calling \$Plate->View->std_home_page() - edit Container::display_record_views as required if adjustments required";

    #    return alDente::Container_Views->LP_home_page( $self, -simple => $simple );
}

####################
sub reset_SubQuadrants {
####################
    #OLD
    # reset Sub Quadrants available for 384 Well Plates
    #
    # Flags unused wells and enables smart 'transfer' to 96-well (ignores unused quadrants)
    #
    my $self = shift;
    my %args = filter_input( \@_, -args => 'plate_id,quadrants' );

    my $plate_id      = $args{-plate_id} || $self->{plate_id};    # id or barcode of plate
    my $sub_quadrants = $args{-quadrants};                        # specified number of available quadrants
    my $dbc           = $self->{dbc};

    my $quadrants_used = $sub_quadrants;

    ########### set unused wells... ############

    my $unused_list = "";
    foreach my $quad ( 'a' .. 'd' ) {
        unless ( $quadrants_used =~ /$quad/i ) {
            if ($unused_list) { $unused_list .= ","; }
            $unused_list .= join ',', $dbc->Table_find( 'Well_Lookup', 'Upper(Plate_384)', "where Quadrant like '$quad'" );
            Message("marking all wells in Quadrant $quad of Plate $plate_id to Unused");
        }
    }

    my $ok = $dbc->Table_update_array( 'Library_Plate', ['Sub_Quadrants'], [$sub_quadrants], "where FK_Plate__ID = $plate_id", -autoquote => 1 );
    $ok = $dbc->Table_update_array( 'Library_Plate', ['Unused_Wells'], [$unused_list], "where FK_Plate__ID = $plate_id", -autoquote => 1 );

    if   ($ok) { Message("marked Wells as unused"); }
    else       { Message("Wells NOT Re-set (may have already been set)"); }

    return 1;
}

##############################
# public_functions           #
##############################

#########################################
# Get next plate number given Library
#
##############
sub get_next_Plate {
##############

}

##################
sub LP_child_form {
##################

    &alDente::Container::child_form( -end_form => 'no' );

    print "<HR size=2 color='black'>";

    print " (IF Parent Plate is Larger than New Plate)<BR>" . "Quadrant(s): " . textfield( -name => 'Quadrant', -size => 4 ) . " (eg. a-d or a,b) - ONLY for 384 - 96 well transfers.<P>";

    print end_form();
}

#######################
sub show_DNA_info {
#######################
    #
    # Retrieves DNA Quantitation information for selected samples from the Plate home page
    # (Previously marked as OLD)
    #
    my %args = @_;

    my $dbc   = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate = $args{-plate_id};
    my $title = $args{-title} || 'DNA Quantitation_Info';
    my $wells = $args{-well};                                                                    ## highlight specific wells.. (how to do this ?)

    unless ( $dbc && $plate ) { Message("Error: Require database handle and Plate id"); return; }
    my @parents = split ',', alDente::Container::get_Parents( -dbc => $dbc, -id => $plate, -format => 'list' );
    push( @parents, $plate );

    my $found;

    foreach my $thisplate (@parents) {
        unless ( $thisplate =~ /[1-9]/ ) {next}
        my %Info = &Table_retrieve(
            $dbc, 'Plate,Library,Project',
            [ 'Project_Path as Path', 'Library_Name as Lib', 'Plate_Number as Num', 'Plate.Parent_Quadrant as Quad' ],
            "where Plate_ID in ($thisplate) and FK_Library__Name=Library_Name and FK_Project__ID=Project_ID"
        );

        my $proj = $Info{Path}[0];
        my $lib  = $Info{Lib}[0];
        my $num  = $Info{Num}[0];
        my $quad = $Info{Quad}[0];

        my $format = "$project_dir/$proj/DNA_Quantitations/$lib-$num" . uc($quad) . "*.TXT";

        my $found = glob($format);
        print "looking for file: $format" . br();

        if ($found) { return &File_to_HTML( $found, "$title for Plate $thisplate" ); }
        else        { print " (File not found)"; }
    }
    return "No DNA Quantitation Info found" . br();
}

###############
sub show_Map {
###############
    #
    # Display well mapping between 96 and 384 well library plates
    #
    print "<Img src='/$alDente::SDB_Defaults::image_dir/wells.png'>";
    return;
}

############################
## Well Specific methods ###
############################

################
sub show_well_map {
################
    print "<Img src='/$alDente::SDB_Defaults::image_dir/wells.png'>";
    return 1;
}

################################################################################
# Well specification (select status/lookup/reArray)
################################################################################

################
sub set_Wells {
################
    #  move to rm in Container_App
    # Save status of wells within multi-well plates
    #
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $select_type = $args{-select_type};
    my $status_type = $args{-status_type};
    my $plate_ids   = $args{-plate_ids};
    my $comments    = $args{-comments};
    my @well_list   = Cast_List( -list => $args{-well_list}, -to => 'array' );
    my @generations = Cast_List( -list => $args{-generations}, -to => 'array' );

    foreach (@well_list) {
        unless ( $_ =~ /^\w\d{1,2}$/ ) {
            Message("Error: Invalid well: $_");
            return 0;
        }
    }

    my $wells = join( ',', @well_list );
    my $LibPlate_field;

    if ( $select_type =~ /No Grow/i ) {
        $LibPlate_field = 'No_Grows';
    }
    elsif ( $select_type =~ /Slow Grow/i ) {
        $LibPlate_field = 'Slow_Grows';
    }
    elsif ( $select_type =~ /Unused/i ) {
        $LibPlate_field = 'Unused_Wells';
    }
    elsif ( $select_type =~ /Problematic/i ) {
        $LibPlate_field = 'Problematic_Wells';
    }
    elsif ( $select_type =~ /Empty/i ) {
        $LibPlate_field = 'Empty_Wells';
    }
    else {
        Message("Error: Invalid select type");
        return 0;
    }

    my ( @plate_fields, @plate_values );
    ###### Set the test status if added #######
    if ($status_type) {
        push( @plate_fields, 'Plate_Test_Status' );
        push( @plate_values, $status_type );
    }

    my ($first_plate) = split( ',', $plate_ids );

    ## Check to see if they want to set wells for a tray (more than 1 plate scanned in)
    if ( alDente::Tray::exists_on_tray( $dbc, 'Plate', $first_plate ) ) {
        if ($LibPlate_field) {

            my @plate_ids = split( ',', $plate_ids );
            my @conv_wells = alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells );
            my %Plate_Info = Table_retrieve( $dbc, 'Plate_Tray', [ 'FK_Plate__ID', 'Plate_Position' ], "WHERE FK_Plate__ID IN ($plate_ids)" );
            my %quad_plates;

            ## Generate a hash of what quadrant each well is located in
            foreach my $conv_well (@conv_wells) {
                if ( $conv_well =~ /([a-zA-Z]\d{1,2})([a-d])/ ) {
                    push( @{ $quad_plates{$2}{wells} }, $1 );
                }
            }

            my $index = 0;
            while ( defined $Plate_Info{FK_Plate__ID}[$index] ) {
                ## IF no wells are specified, check to see if there are any set wells for the plate
                my $plate_id = $Plate_Info{FK_Plate__ID}[$index];
                my ($well_settings) = $dbc->Table_find( 'Library_Plate,Plate', $LibPlate_field, "WHERE FK_Plate__ID = Plate_ID and Plate_ID = $plate_id" );
                my $plate_position = $Plate_Info{Plate_Position}[$index];
                ## If there are, update the plate well mapping to set it to blank
                if ( $well_settings && !defined( $quad_plates{$plate_position}{wells} ) ) {
                    $dbc->Table_update_array( 'Library_Plate', [$LibPlate_field], [''], "where FK_Plate__ID=$plate_id", -autoquote => 1 );
                }

                if ( defined $quad_plates{ $Plate_Info{Plate_Position}[$index] } ) {
                    $quad_plates{ $Plate_Info{Plate_Position}[$index] }{plate_id} = $Plate_Info{FK_Plate__ID}[$index];
                }
                $index++;
            }
            my $lp;
            my @altered_plates;
            foreach my $position ( keys %quad_plates ) {
                if ( $quad_plates{$position}{plate_id} && defined $quad_plates{$position}{wells} ) {
                    $lp += $dbc->Table_update_array( 'Library_Plate', [$LibPlate_field], [ join( ',', @{ $quad_plates{$position}{wells} } ) ], "where FK_Plate__ID=$quad_plates{$position}{plate_id}", -autoquote => 1 );
                    push( @altered_plates, $quad_plates{$position}{plate_id} );
                }
            }

            if ($lp) {
                Message( "Edited $lp Library_Plate entries for Plate(s):" . join( ',', @altered_plates ) . '.' );
            }
            else {
                Message("No Changes made (may already be set ?). $DBI::errstr");
            }
        }

        ## If in single plate mode
    }
    elsif ($plate_ids) {

        ###### add comments if added #######
        if ($comments) {
            push( @plate_fields, 'Plate_Comments' );
            push( @plate_values, $comments );
        }

        my $altered_plates = $plate_ids;

        if (@generations) {
            $altered_plates .= ',' . join( ',', @generations );
        }

        my ( $p, $lp );    ### Counter for the number of fields updated for plate and library_plate

        if (@plate_fields) {
            $p = $dbc->Table_update_array( 'Plate', \@plate_fields, \@plate_values, "where Plate_ID in ($altered_plates)", -autoquote => 1 );
        }
        if ($LibPlate_field) {
            $lp = $dbc->Table_update_array( 'Library_Plate', [$LibPlate_field], [$wells], "where FK_Plate__ID in ($altered_plates)", -autoquote => 1 );
        }

        if ( $p || $lp ) {
            Message("Edited $p Plate and $lp Library_Plate entries for Plate(s) $altered_plates.");
        }
        else {
            Message("No Changes made (may already be set ?). $DBI::errstr");
        }

    }
    else {
        Message( "Error: ", "Failed to select $LibPlate_field for Plate $plate_ids" );
    }
    return "Wells set";
}

#########################
sub parse_transfer_options {
#########################
    my $dbc           = $Connection;
    my $source_plates = param('source_plates');

    print alDente::Form::start_alDente_form( $dbc, );
    my $configure_transfer = HTML_Table->new( -title => "Transfer Options" );

    ## new plate will be created
    Message("New plate will be created");

    my ($plate_info) = $dbc->Table_find( "Plate,Library,Plate_Format", "FK_Library__Name,FK_Rack__ID,Library_FullName,Plate_Format_Type", "WHERE Plate_ID IN ($source_plates) and FK_Library__Name = Library_Name and FK_Plate_Format__ID = Plate_Format_ID" );
    my ( $lib, $rack, $lib_name, $format ) = split ',', $plate_info;
    my @plate_formats = &get_FK_info( $dbc, 'FK_Plate_Format__ID', -condition => "WHERE Plate_Format_Style like \'%Plate%\'", -list => 1 );

    my $library_filter = [ "Target Library: ", &alDente::Tools::search_list( -dbc => $dbc, -form => "this.form", -name => 'FK_Library__Name', -filter => 1, -search => 1, -default => "$lib:$lib_name" ) ];

    my @plate_sizes = $dbc->get_enum_list( 'Plate', 'Plate_Size' );

    #    $configure_transfer->Set_Row(["Target Plate Format:", popup_menu(-name=>'Target Plate Format',-force=>1,-values=>['',@plate_formats],-default=>"$size $format")]);
    #    $configure_transfer->Set_Row($library_filter);
    #    $configure_transfer->Set_Row(["Target Plate Size:" . popup_menu(-name=>'Target_Plate_Size',-values=>\@plate_sizes,-force=>1,-default=>$size)]);
    $configure_transfer->Set_Row( [ checkbox( -name => 'Test Plate Only', -label => 'Test Plate Only', -force => 1 ) ] );
    $configure_transfer->Printout();

    my ( $min_row, $max_row, $min_col, $max_col, $size ) = &alDente::Well::get_Plate_dimension( -plate => $plate_id );
    my $req = HTML_Table->new( -title => "Select Wells to Transfer for Pla$plate_id" );
    $req->Set_Row(
        [   &alDente::Container_Views::select_wells_on_plate(
                -dbc        => $dbc,
                -table_id   => 'Select_Wells',
                -max_row    => $max_row,
                -max_col    => $max_col,
                -input_type => 'checkbox'
            )
        ]
    );
    print "Format: $format<BR>";
    $req->Set_Row( [ submit( -name => 'Transfer_Wells', -value => 'Transfer Wells', -class => 'Action', onClick => "return checkWells()" ) ] );
    $req->Set_Row(
        [   hidden( -name => 'source_plates',       -value => $source_plates ),
            hidden( -name => 'rack',                -value => $rack ),
            hidden( -name => 'Target Plate Format', -value => "$size $format" ),
            hidden( -name => 'Target_Plate_Size',   -value => $size ),
            hidden( -name => 'FK_Library__Name',    -value => $lib )
        ]
    );
    print alDente::Form::start_alDente_form( $dbc, 'transfer_select_form', $dbc->homelink() ) . $req->Printout(0) . "</form>";
    print "<script>
function checkWells(){
  // search for form with wells in it
  var f=document.getElementById('Select_Wells');
  while(f.tagName != 'FORM'){
    f=f.parentNode;
  }
  var wells=new Array();
  var checkCount = 0;
  for(var i=0;i<f.Wells.length;i++){
    if(f.Wells[i].checked == 1){
      wells.push(f.Wells[i].value);
      checkCount++;
    }
  }
  var wellslist = wells.join(\",\");
  if(checkCount==0){
    alert('No wells selected!');
    return false;
  }
  if(! confirm('Are you sure you want to select wells '+wellslist+' for transfer to new plate?')){
    return false;
  }
  return true;
}

</script>";
    print "$size $format<BR>";
}

############################
sub parse_transfer_wells {
############################
    my $dbc = $Connection;

    my $source_plates = param('source_plates');
    my @wells         = param('Wells');
    @wells = alDente::Well::Format_Wells( -wells => \@wells );
    my $wells               = join( ",", @wells );
    my $rack                = param('rack');
    my $test_plate          = param('Test Plate Only');
    my $target_plate_size   = param('Target_Plate_Size');
    my $target_plate_format = param('Target Plate Format');
    $target_plate_format = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $target_plate_format );

    #    my $lib = param('FK_Library__Name');

    ### do transfer
    my $Set = alDente::Library_Plate_Set->new( -ids => $source_plates );
    my $id = $Set->transfer( -format => $target_plate_format, -rack => $rack, -type => 'Transfer', -test_plate => $test_plate );

    if ( !$id ) {
        $dbc->error("Failed to transfer wells $wells to new plate.");
    }
    else {
        ### set each of the empty wells as unused
        # figure out which wells are empty (not transferred)
        my @allWells = &alDente::Well::Get_Wells( -size => $target_plate_size );
        my @unused_wells;
        foreach (@allWells) {
            if ( index( $wells, $_, ) == -1 ) {    # well is not used, set to unused
                push( @unused_wells, $_ );
            }
        }
        @unused_wells = map { &format_well( $_, 'nopad' ) } @unused_wells;
        my $unused_wells = join( ",", @unused_wells );
        $dbc->SDB::DBIO::Table_update_array(
            -table     => 'Library_Plate',
            -fields    => ['Empty_Wells'],
            -values    => [$unused_wells],
            -condition => "where FK_Plate__ID=$id",
            -autoquote => 1
        );
        Message("Wells $unused_wells for Pla$id changed to unused");
        require alDente::Info;
        &alDente::Info::GoHome( $dbc, 'Container', $id );
    }
}

#########################
sub parse_rearray_options {
#########################
    #<CONSTRUCTION> this should be in ReArray_App
    my $dbc            = $Connection;
    my $rearray_target = param('Rearray_Option');
    my $target_plate   = param('Existing_Plate');
    my $source_plates  = param('source_plates');
    my $output;
    $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Rearray Wells" );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App' );
    my $configure_rearray = HTML_Table->new( -title => "ReArray Options" );

    #my $create_rearray = submit( -name => "ReArray_Wells", -value => "ReArray Wells", -class => "Std" );
    my $create_rearray = submit( -name => "rm", -value => "ReArray Wells", -class => "Std" );
    my $pool_to_single_tube;
    my $pool_to_tube_by_rows;
    if ( $rearray_target =~ /new/i ) {

        #pooling to tube will create a new tube currently
        $pool_to_single_tube = submit( -name => "rm", -value => "Pool To Single Tube", -class => "Std" );

        #only allow this when target is new since this will create a tube for each row
        $pool_to_tube_by_rows = submit( -name => "rm", -value => "Pool To Tube By Rows", -class => "Std" );
        ## new plate will be created
        Message("New plate will be created");

        my ($plate_info)
            = $dbc->Table_find( "Plate,Library,Plate_Format", "FK_Library__Name,FK_Rack__ID,Plate_Size,Library_FullName,Plate_Format_Type",
            "WHERE Plate_ID IN ($source_plates) and FK_Library__Name = Library_Name and FK_Plate_Format__ID = Plate_Format_ID" );
        my ( $lib, $rack, $size, $lib_name, $format ) = split( /,/, $plate_info );

        #my @plate_formats = &get_FK_info( $dbc, 'FK_Plate_Format__ID', -condition => "WHERE Plate_Format_Style like \'%Plate%\'", -list => 1 );
        my @plate_formats = &get_FK_info( $dbc, 'FK_Plate_Format__ID', -list => 1 );

        my $library_filter = [ "Target Library: ", &alDente::Tools::search_list( -dbc => $dbc, -form => "this.form", -name => 'FK_Library__Name', -filter => 1, -search => 1, -default => "$lib:$lib_name" ) ];

        my @plate_sizes = $dbc->get_enum_list( 'Plate', 'Plate_Size' );

        $configure_rearray->Set_Row( [ "Target Plate Format:", popup_menu( -name => 'Target Plate Format', -force => 1, -values => [ '', @plate_formats ], -default => "$size $format" ) ] );
        $configure_rearray->Set_Row($library_filter);
        $configure_rearray->Set_Row( [ "Target Plate Size:" . popup_menu( -name => 'Target_Plate_Size', -values => \@plate_sizes, -force => 1, -default => $size ) ] );
    }
    elsif ( $rearray_target =~ /exist/i ) {
        ## rearray wells onto existing plate
        Message("Rearray wells onto existing plate");
        $target_plate = get_aldente_id( $dbc, $target_plate, 'Plate' );
    }
    $configure_rearray->Set_Row( [ $create_rearray, $pool_to_single_tube, $pool_to_tube_by_rows ] );
    $output .= $configure_rearray->Printout(0);
    $output .= display_wells_for_rearray( -dbc => $dbc, -plate_id => $source_plates, -return_html => 1 );

    $output .= hidden( -name => 'source_plates',       -value => $source_plates );
    $output .= hidden( -name => 'Existing_Plate',      -value => $target_plate ) if ( $rearray_target =~ /exist/i );
    $output .= hidden( -name => 'ReArray_Option',      -value => $rearray_target );
    $output .= hidden( -name => 'Parse_ReArray_Wells', -value => 1 );

    $output .= end_form();
    print $output;

    #print end_form();
    ## Call create rearray method
}
##########################
sub parse_rearray_wells {
##########################
    my $dbc                 = $Connection;
    my $source_plates       = param('source_plates');
    my $target_plate        = param('Existing_Plate');
    my $rearray_target      = param('Rearray_Option');
    my @wells               = param('Wells');
    my $target_plate_size   = param('Target_Plate_Size');
    my $library             = &SDB::HTML::get_Table_Param( -table => 'Library', -field => 'FK_Library__Name', -dbc => $dbc );
    my $target_plate_format = param('Target Plate Format');
    $library             = $dbc->get_FK_ID( 'FK_Library__Name',    $library );
    $target_plate_format = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $target_plate_format );

    #print alDente::Form::start_alDente_form($dbc,);
    print alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Parse Rearray Wells" );

    my $pick_wells_table = HTML_Table->new( -title => 'Pick Source Wells', -class => 'small' );
    my @sample_names = $dbc->Table_find( 'Plate_Sample,Sample,Plate', 'Sample_Name,Well', "WHERE FK_Sample__ID = Sample_ID and Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID and Plate_ID in ($source_plates)" );
    my %sample_well_names;
    my %converted_wells;
    for my $sample_name (@sample_names) { my ( $sample, $well ) = split( ",", $sample_name ); $sample_well_names{$well} = $sample; }

    # In case of tray, create a new hash with keys converted based on quandrant positions
    my ($first_plate) = split( ',', $source_plates );
    my $tray_flag = alDente::Tray::exists_on_tray( $dbc, 'Plate', $first_plate );

    if ($tray_flag) {
        ## If exists on a tray
        my $tray;
        my $tray_of_tubes = 0;
        my $multi_mode;
        my $size;

        my @plate_info_fields = ( 'Parent_Quadrant', 'Max_Row', 'Max_Col', 'Unused_Wells', 'Empty_Wells', 'Plate.Plate_Class', 'Plate_Tray.Plate_Position AS Position', 'Plate_ID', 'Plate_Size' );
        my %wells = Table_retrieve( $dbc, 'Plate,Library_Plate,Plate_Format LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID=Plate_ID',
            \@plate_info_fields, "WHERE Library_Plate.FK_Plate__ID=Plate_ID AND Plate_Format_ID=FK_Plate_Format__ID AND Plate_ID IN($source_plates)" );

        # 1-well plates are stored as tube now, so need to merge tube info
        my %tray_wells = Table_retrieve(
            $dbc,
            'Plate,Tube,Plate_Format LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID=Plate_ID',
            [ 'Max_Row', 'Max_Col', 'Plate.Plate_Class', 'Plate_Tray.Plate_Position AS Position', 'Plate_ID' ],
            "WHERE Tube.FK_Plate__ID=Plate_ID AND Plate_Format_ID=FK_Plate_Format__ID AND Plate_ID IN($source_plates)"
        );
        require RGTools::RGmath;
        my $merge_wells = RGmath::merge_Hash( -hash1 => \%wells, -hash2 => \%tray_wells );
        %wells = %{$merge_wells};

        $tray = alDente::Tray->new( -dbc => $dbc, -plate_ids => $source_plates );
        if ( scalar( keys %{ $tray->{trays} } ) == 1 ) {
            $multi_mode = 1;
            my $well_check = $wells{Position}->[0];
            ($well_check) = $dbc->Table_find( 'Well_Lookup', 'Plate_96', "WHERE Plate_96 IN ('$well_check')" );
            if ($well_check) {
                $tray_of_tubes = 1;
            }
        }

        if ( $multi_mode && !$tray_of_tubes ) {
            my %quads_included;
            my $total_plates = scalar( my @array = split( ',', $source_plates ) );
            for ( my $i = 0; $i < $total_plates; $i++ ) {
                $size = $wells{Plate_Size}[$i];
                if ( $size != '96-well' ) {
                    ## Check to see if all plates are 96 well or no
                    Message("non-96 well plate ($size) found in a multi plate");
                    Call_Stack();
                }
                elsif ( defined $quads_included{ $wells{Position}[$i] } ) {
                    ## Check to see if two plates with the same positions are not listed
                    Message( "Another plate in Current Plates has the same position (" . $wells{Position}[$i] . ") as  plate " . $wells{Plate_ID}[$i] );
                    Call_Stack();
                }
                else {
                    $quads_included{ $wells{Position}[$i] } = 1;
                    my @wells = &alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells{No_Grows}[$i], -target_size => '384', -quadrant => $wells{Position}[$i] );
                    my @unused_wells = Cast_List( -list => $wells{Unused_Wells}[$i], -to => 'Array' );
                    @unused_wells = map { &format_well($_) } @unused_wells;
                    my $unused_wells_string = Cast_List( -list => \@unused_wells, -to => 'String', -autoquote => 1 );
                    my %used_wells = $dbc->Table_retrieve(
                        'Library_Plate,Plate_Sample,Plate',
                        [ 'Well', 'FK_Sample__ID' ],
                        "WHERE Library_Plate.FK_Plate__ID = Plate_ID and Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID and Plate_ID IN ($source_plates) and Well NOT IN ($unused_wells_string)"
                    );
                    my %sample_well_names_converted;
                    my $sample;
                    my $new_well;

                    foreach my $used_well ( @{ $used_wells{Well} } ) {
                        $sample = $sample_well_names{$used_well};
                        ($new_well) = alDente::Well::Convert_Wells( -dbc => $dbc, -wells => &format_well( $used_well, 'nopad' ), -target_size => '384', -quadrant => $wells{Position}[$i] );
                        $sample_well_names_converted{$new_well} = $sample;
                        $converted_wells{$new_well}             = $used_well;
                    }
                    %sample_well_names = %sample_well_names_converted;
                }
            }
        }
    }

    my @well_list;

    foreach my $well (@wells) {
        $well = &format_well( $well, 'pad' );
        my $old_well = $converted_wells{$well};
        my $well_checkbox;
        if ($old_well) {
            $well_checkbox = checkbox( -name => 'Selected_Wells', -value => $old_well, -label => "$well($old_well)" );
            $pick_wells_table->Set_Row( [ $well_checkbox, $sample_well_names{$well} ] );
            push( @well_list, $old_well );
        }
        else {
            $well_checkbox = checkbox( -name => 'Selected_Wells', -value => $well, -label => $well );
            $pick_wells_table->Set_Row( [ $well_checkbox, $sample_well_names{$well} ] );
            push( @well_list, $well );
        }
    }

    my $select_all_wells = join ',', @well_list;
    my $true             = "SetSelection(this.form,\"Selected_Wells\",1,\"all\");";
    my $false            = "SetSelection(this.form,\"Selected_Wells\",0,\"all\");";

    my $table_action = button( -name => 'Select All Wells', onClick => $true ) . hspace(5) . button( -name => 'Clear All Wells', onClick => $false );
    $pick_wells_table->Set_sub_title( $table_action, 2 );
    $pick_wells_table->Printout();

    print hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App', -force => 1 );
    print Message("Pick source wells above and double click on the well map below to fill in the target well for the picked source wells");
    print lbr() . submit( -name => 'rm', -value => "Create ReArray", -class => "Action" ) . lbr();

    if ($target_plate) {
        ## Print Target Plate info

        print hidden( -name => 'Existing_Plate', -value => $target_plate, -force => 1 );
        ## Find the used wells
        my $target_plate_id = get_aldente_id( $dbc, $target_plate, 'Plate' );

        my @filled_wells = $dbc->Table_find( "Plate_Sample", "Well", "WHERE FKOriginal_Plate__ID = $target_plate_id" );
        @filled_wells = map { &format_well( $_, 'nopad' ) } @filled_wells;

        my %availability;
        foreach my $well (@filled_wells) {
            $availability{$well} = 0;
        }
        my ($plate_id) = $target_plate =~ /pla(\d+)/i;
        my ( $min_row, $max_row, $min_col, $max_col, $size ) = &alDente::Well::get_Plate_dimension( -plate => $plate_id );
        my $plate_view = &alDente::Container_Views::select_wells_on_plate(
            -table_id     => 'Parse_Rearray_Wells',
            -max_row      => $max_row,
            -max_col      => $max_col,
            -input_type   => 'text',
            -action       => 'fill_wells',
            -fill_list    => 'Selected_Wells',
            -availability => \%availability,
            -no_fill      => 1,
        );
        print $plate_view;

    }
    else {
        my ( $min_row, $max_row, $min_col, $max_col, $size ) = &alDente::Well::get_Plate_dimension( -size => $target_plate_size );
        my $plate_view = &alDente::Container_Views::select_wells_on_plate( -table_id => 'Parse_Rearray_Wells', -max_row => $max_row, -max_col => $max_col, -input_type => 'text', -action => 'fill_wells', -fill_list => 'Selected_Wells', -no_fill => 1 );
        print $plate_view;
    }
    print hidden( -name => 'Source_Plate', -value => $source_plates, -force => 1 );

    #print hidden( -name => 'Parse_ReArray_Wells', -value => 1 );
    print hidden( -name => 'Library',           -value => $library,             -force => 1 );
    print hidden( -name => 'Plate_Format',      -value => $target_plate_format, -force => 1 );
    print hidden( -name => 'Target_Plate_Size', -value => $target_plate_size,   -force => 1 );

    print end_form();
}

###############################
sub display_wells_for_rearray {
###############################source_
    my %args = filter_input( \@_, -args => 'plate_id' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_ids = $args{-plate_id} || $plate_id;
    my $return_html = $args{-return_html};
    ## Look at first plate....
    my ($first_plate) = split( ',', $plate_ids );
    my $tray;
    my $multi_mode;
    my $plate_info;
    my %availability;

    ## Check to see if they want to set wells for a tray (more than 1 plate scanned in)
    #   if($plate_ids=~/,/) {
    my $tray_flag = alDente::Tray::exists_on_tray( $dbc, 'Plate', $first_plate );
    if ($tray_flag) {
        ## If exists on a tray
        $tray = alDente::Tray->new( -dbc => $dbc, -plate_ids => $plate_ids );
        ## And all plates are in the same tray
        if ( scalar( keys %{ $tray->{trays} } ) == 1 ) {
            $multi_mode = 1;
            my @quad_info = $dbc->Table_find( "Plate_Tray,Well_Lookup", "Plate_384", "WHERE Plate_Position=Quadrant AND FK_Plate__ID in ($plate_ids)" );
            foreach my $row (@quad_info) {
                my $well = uc($row);
                $availability{$well} = 1;
            }
        }
    }
    else { Message("Not tray"); }

    #    }

    if ($multi_mode) {
        $plate_info = "TRA" . $tray->{tray_ids};

        #      $plate_info = get_FK_info($dbc,'FK_Tray__ID',$tray->{tray_ids});  this one displays mul|tray500 for example
    }
    else {
        ### If not multi mode, we'll only display wells for first plate
        $plate_ids = $first_plate;
        $plate_info = get_FK_info( $dbc, 'FK_Plate__ID', $first_plate );
    }
    my @plate_info_fields = (
        'Parent_Quadrant', 'Max_Row', 'Max_Col', 'No_Grows', 'Slow_Grows', 'Unused_Wells', ' Problematic_Wells',
        'Empty_Wells', 'Plate_Test_Status', 'Plate_Size', 'Plate_Comments', 'Plate.Plate_Class', 'Plate_Tray.Plate_Position AS Position', 'Plate_Size'
    );

    my %wells = Table_retrieve( $dbc, 'Plate,Library_Plate,Plate_Format LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID=Plate_ID',
        \@plate_info_fields, "WHERE Library_Plate.FK_Plate__ID=Plate_ID AND Plate_Format_ID=FK_Plate_Format__ID AND Plate_ID IN ($plate_ids)" );
    my ( $size, @NGs, @SGs, @Us, @Ps, @Es );

    if ($multi_mode) {
        my %quads_included;
        my $total_plates = scalar( my @array = split( ',', $plate_ids ) );
        for ( my $i = 0; $i < $total_plates; $i++ ) {
            $size = $wells{Plate_Size}[$i];
            if ( $size != '96-well' ) {
                ## Check to see if all plates are 96 well or no
                Message("non-96 well plate found in a multi plate");
                Call_Stack();

            }
            elsif ( defined $quads_included{ $wells{Position}[$i] } ) {
                ## Check to see if two plates with the same positions are not listed
                Message( "Another plate in Current Plates has the same position (" . $wells{Position}[$i] . ") as  plate " . $wells{Plate_ID}[$i] );
                Call_Stack();

            }
            else {
                $quads_included{ $wells{Position}[$i] } = 1;
                my @wells = &alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells{No_Grows}[$i], -target_size => '384', -quadrant => $wells{Position}[$i] );
                push( @NGs, alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells{No_Grows}[$i],          -target_size => '384', -quadrant => $wells{Position}[$i] ) ) if ( $wells{No_Grows}[$i] );
                push( @SGs, alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells{Slow_Grows}[$i],        -target_size => '384', -quadrant => $wells{Position}[$i] ) ) if ( $wells{Slow_Grows}[$i] );
                push( @Us,  alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells{Unused_Wells}[$i],      -target_size => '384', -quadrant => $wells{Position}[$i] ) ) if ( $wells{Unused_Wells}[$i] );
                push( @Ps,  alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells{Problematic_Wells}[$i], -target_size => '384', -quadrant => $wells{Position}[$i] ) ) if ( $wells{Problematic_Wells}[$i] );
                push( @Es,  alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells{Empty_Wells}[$i],       -target_size => '384', -quadrant => $wells{Position}[$i] ) ) if ( $wells{Empty_Wells}[$i] );
            }
        }
    }
    else {
        $size = $wells{Plate_Size}[0];
        @NGs  = split( ',', $wells{No_Grows}[0] );
        @SGs  = split( ',', $wells{Slow_Grows}[0] );
        @Us   = split( ',', $wells{Unused_Wells}[0] );
        @Ps   = split( ',', $wells{Problematic_Wells}[0] );
        @Es   = split( ',', $wells{Empty_Wells}[0] );
    }

    my $max_row       = $wells{Max_Row}[0];
    my $max_col       = $wells{Max_Col}[0];
    my $wellstableid  = "ReArrayWells";
    my $row_colour    = toggle_colour( undef, 'whitesmoke', 'cream' );
    my $highlight     = "red";
    my $dim_highlight = "pink";
    my $U_highlight   = "gray";
    my $P_highlight   = "orange";
    my $E_highlight   = "lightgreen";

    my %preset_colour;
    $preset_colour{$highlight}     = \@NGs;
    $preset_colour{$dim_highlight} = \@SGs;
    $preset_colour{$U_highlight}   = \@Us;
    $preset_colour{$P_highlight}   = \@Ps;
    $preset_colour{$E_highlight}   = \@Es;

    my $output = alDente::Container_Views::select_wells_on_plate(
        -dbc               => $dbc,
        -table_id          => $wellstableid,
        -max_row           => $max_row,
        -max_col           => $max_col,
        -availability      => \%availability,
        -preset_colour     => \%preset_colour,
        -tray_flag         => $tray_flag,
        -background_colour => $row_colour
    );

    if ($return_html) { return $output }
    print $output;

}

#<CONSTRUCTION>
###################
sub view_plate {
###################
    my $self                     = shift;
    my $dbc                      = $self->{dbc};
    my %args                     = filter_input( \@_, -args => 'plate_id' );
    my $plate_ids                = $args{-plate_id} || $plate_id;
    my $printable_page_link_only = $args{-printable_page_link_only};
    my $suppress_sample_display  = $args{-suppress_sample_display};
    my $action                   = $args{-action};

    ## color categories base on plate status
    my %colors;
    $colors{'Thrown Out'} = 'gray';
    $colors{'Failed'}     = 'red';

    my ($first_plate) = split( ',', $plate_ids );
    my $tray_flag = alDente::Tray::exists_on_tray( $dbc, 'Plate', $first_plate );
    my $tray;
    my $tray_of_tubes = 0;
    my $size;
    my @Us;
    my @Es;
    my $multi_mode;
    my %availability;

    my @plate_info_fields = ( 'Parent_Quadrant', 'Max_Row', 'Max_Col', 'Unused_Wells', 'Empty_Wells', 'Plate.Plate_Class', 'Plate_Tray.Plate_Position AS Position', 'Plate_ID', 'Plate_Size' );
    my %wells = Table_retrieve( $dbc, 'Plate,Library_Plate,Plate_Format LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID=Plate_ID',
        \@plate_info_fields, "WHERE Library_Plate.FK_Plate__ID=Plate_ID AND Plate_Format_ID=FK_Plate_Format__ID AND Plate_ID IN($plate_ids)" );

    # 1-well plates are stored as tube now, so need to merge tube info
    my %tray_wells = Table_retrieve(
        $dbc,
        'Plate,Tube,Plate_Format LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID=Plate_ID',
        [ 'Max_Row', 'Max_Col', 'Plate.Plate_Class', 'Plate_Tray.Plate_Position AS Position', 'Plate_ID' ],
        "WHERE Tube.FK_Plate__ID=Plate_ID AND Plate_Format_ID=FK_Plate_Format__ID AND Plate_ID IN($plate_ids)"
    );
    require RGTools::RGmath;
    my $merge_wells = RGmath::merge_Hash( -hash1 => \%wells, -hash2 => \%tray_wells );
    %wells = %{$merge_wells};

    ### For sample alias/attribute tool tip
    my %sample_info = Table_retrieve(
        $dbc,
        'Plate,Plate_Sample,Sample LEFT JOIN Sample_Alias ON Sample_Alias.FK_Sample__ID=Sample_ID',
        [ 'Well', 'Alias', 'Alias_Type' ],
        "where Plate_Sample.FK_Sample__ID=Sample.Sample_ID and Plate_ID IN ($plate_ids) and Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID ORDER by Alias_Type"
    );

    my $index = 0;
    my %samples;
    while ( defined $sample_info{Well}[$index] ) {
        my $well        = $sample_info{Well}[$index];
        my $alias       = $sample_info{Alias}[$index];
        my $alias_type  = $sample_info{Alias_Type}[$index];
        my $sample_name = $sample_info{Sample_Name}[$index];

        if ($alias) {
            push( @{ $samples{$well} }, "$alias_type: $alias" );
        }
        $index++;
    }

    if ($tray_flag) {
        ## If exists on a tray
        $tray = alDente::Tray->new( -dbc => $dbc, -plate_ids => $plate_ids );

        if ( scalar( keys %{ $tray->{trays} } ) == 1 ) {
            $multi_mode = 1;
            my $well_check = $wells{Position}->[0];
            ($well_check) = $dbc->Table_find( 'Well_Lookup', 'Plate_96', "WHERE Plate_96 IN ('$well_check')" );
            if ($well_check) {
                $tray_of_tubes = 1;
                my $index;
                foreach my $well ( @{ $wells{Position} } ) {
                    my $tube = $wells{Plate_ID}->[$index];
                    $well = &format_well( $well, 'nopad' );
                    my ($status_info) = $dbc->Table_find( 'Plate', 'Plate_Status, Failed', "WHERE Plate_ID = $tube" );
                    my ( $tube_status, $failed ) = split ',', $status_info;
                    my $color = $colors{$failed};
                    if ( !$color ) { $color = $colors{$tube_status} }
                    Message("tube=$tube, status=$tube_status, color=$color") if ($color);
                    if ($suppress_sample_display) {
                        my $plate_info = $dbc->get_FK_info( "FK_Plate__ID", $tube );
                        if   ($color) { $availability{$well} = "<Font color=$color>" . $plate_info . "</Font>" }
                        else          { $availability{$well} = $plate_info }
                    }
                    else {
                        my $PLAlink = alDente::Container_Views::foreign_label( -dbc => $dbc, -plate_id => $tube, -type => 'tooltip', -text_colour => $color );
                        $availability{$well} = $PLAlink;
                        my ($sample) = $dbc->Table_find( 'Plate_Sample,Plate', 'FK_Sample__ID', "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_ID=$tube GROUP BY Plate_ID HAVING COUNT(*)=1" );
                        if ($sample) {
                            my ($sample_info) = $dbc->Table_find( 'Sample,Source', 'External_Identifier', "WHERE FK_Source__ID=Source_ID AND Sample_ID = $sample" );
                            foreach my $result ( @{ $samples{$well} } ) {
                                $sample_info .= $result . "<BR>";
                            }
                            $availability{$well} .= '<BR>' . alDente::Tools::alDente_ref( 'Sample', $sample, -dbc => $dbc, -tooltip => $sample_info );
                        }
                    }
                    $index++;
                }
            }
        }

    }

    if ( $multi_mode && !$tray_of_tubes ) {
        my %quads_included;
        my $total_plates = scalar( my @array = split( ',', $plate_ids ) );
        for ( my $i = 0; $i < $total_plates; $i++ ) {
            $size = $wells{Plate_Size}[$i];
            if ( $size != '96-well' ) {
                ## Check to see if all plates are 96 well or no
                Message("non-96 well plate ($size) found in a multi plate");
                Call_Stack();

            }
            elsif ( defined $quads_included{ $wells{Position}[$i] } ) {
                ## Check to see if two plates with the same positions are not listed
                Message( "Another plate in Current Plates has the same position (" . $wells{Position}[$i] . ") as  plate " . $wells{Plate_ID}[$i] );
                Call_Stack();

            }
            else {
                $quads_included{ $wells{Position}[$i] } = 1;
                my @wells = &alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells{No_Grows}[$i], -target_size => '384', -quadrant => $wells{Position}[$i] );
                my @unused_wells = Cast_List( -list => $wells{Unused_Wells}[$i], -to => 'Array' );
                @unused_wells = map { &format_well($_) } @unused_wells;
                my $unused_wells_string = Cast_List( -list => \@unused_wells, -to => 'String', -autoquote => 1 );
                my %used_wells = $dbc->Table_retrieve(
                    'Library_Plate,Plate_Sample,Plate',
                    [ 'Well', 'FK_Sample__ID' ],
                    "WHERE Library_Plate.FK_Plate__ID = Plate_ID and Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID and Plate_ID IN ($plate_ids) and Well NOT IN ($unused_wells_string)"
                );
                my ($original_plate_size) = $dbc->Table_find( "Plate,Plate AS Original_Plate", "Original_Plate.Plate_Size", "WHERE Plate.Plate_ID IN ($plate_ids) AND Plate.FKOriginal_Plate__ID = Original_Plate.Plate_ID" );
                my $source_size;
                if ( $original_plate_size eq '384-well' ) { $source_size = '384' }
                my $uindex = 0;

                foreach my $used_well ( @{ $used_wells{Well} } ) {
                    my $sample = $used_wells{FK_Sample__ID}[$uindex];

                    ($used_well) = alDente::Well::Convert_Wells( -dbc => $dbc, -wells => &format_well( $used_well, 'nopad' ), -target_size => '384', -quadrant => $wells{Position}[$i], -source_size => $source_size );
                    $used_well = &format_well( $used_well, 'nopad' );
                    $availability{$used_well} = alDente::Tools::alDente_ref( 'Sample', $sample, -dbc => $dbc );    # &Link_To( $dbc->config('homelink'), $sample, "&HomePage=Sample&ID=$sample", $Settings{LINK_COLOUR}, ['newwin']);
                    $uindex++;
                }
                push( @Us, alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells{Unused_Wells}[$i], -target_size => '384', -quadrant => $wells{Position}[$i], -source_size => $source_size ) ) if ( $wells{Unused_Wells}[$i] );
                push( @Es, alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells{Empty_Wells}[$i],  -target_size => '384', -quadrant => $wells{Position}[$i], -source_size => $source_size ) ) if ( $wells{Empty_Wells}[$i] );
            }
        }
    }
    else {
        $size = $wells{Plate_Size}[0];
        @Us   = split( ',', $wells{Unused_Wells}[0] );
        @Es   = split( ',', $wells{Empty_Wells}[0] );
    }

    #availability{$well} = &Link_To($dbc->homelink(),$tube,"&HomePage=Plate&ID=$tube",$Settings{LINK_COLOUR},['newwin']);

    my %attribute_info = Table_retrieve(
        $dbc,
        'Plate,Plate as Original, Plate_Sample, Sample_Attribute,Attribute',
        [ 'Well', 'Attribute_Name', 'Attribute_Value', 'Plate.Plate_Size as Plate_Size', 'Plate.Parent_Quadrant', 'Original.Plate_Size as Original_Size' ],
        "where Plate_Sample.FK_Sample__ID=Sample_Attribute.FK_Sample__ID and FK_Attribute__ID=Attribute_ID and Plate.Plate_ID IN ($plate_ids) and Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID and Plate.FKOriginal_Plate__ID=Original.Plate_ID ORDER by Attribute_Name"
    );

    my $a_index = 0;
    while ( defined $attribute_info{Well}[$a_index] ) {
        my $well            = $attribute_info{Well}[$a_index];
        my $attribute_name  = $attribute_info{Attribute_Name}[$a_index];
        my $attribute_value = $attribute_info{Attribute_Value}[$a_index];
        if ( $attribute_info{Plate_Size}[$a_index] ne $attribute_info{Original_Size}[$a_index] ) {
            my @converted_wells = &alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $well, -target_size => $attribute_info{Plate_Size}[$a_index], -source_size => $attribute_info{Original_Size}[$a_index] );
            $well = $converted_wells[0] if (@converted_wells);
            if ( $well =~ /^([A-Za-z][0-9]{2})$attribute_info{Parent_Quadrant}[$a_index]$/xms ) {    # 384-well format converted to 96-well format, remove the quadrant
                $well = $1;
            }
        }
        if ($attribute_name) {
            push( @{ $samples{$well} }, "$attribute_name: $attribute_value" );
        }
        $a_index++;
    }
    ### End for sample alias/attribute tool tip

    if ( !$tray_flag ) {

      #my %used_wells
      #    = $dbc->Table_retrieve( 'Library_Plate,Plate_Sample,Plate', [ 'Well', 'FK_Sample__ID' ], "WHERE Library_Plate.FK_Plate__ID = Plate_ID and Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID and Plate_ID IN ($plate_ids)", -debug=>1 );
        my ($plate_size) = $dbc->Table_find( 'Plate', 'Plate_Size', "WHERE Plate_ID IN ($plate_ids)" );
        my @wells = &alDente::Well::Get_Wells( -size => $plate_size );
        @wells = &alDente::Well::Format_Wells( -wells => \@wells, -input_format => 'Mixed' );
        my @plates = ( ($plate_ids) x @wells );
        my $sample = &alDente::Container::get_sample_id( -dbc => $dbc, -plate_ids => \@plates, -wells => \@wells );
        my %used_wells;
        @{ $used_wells{Well} }          = keys %{ $sample->{$plate_ids} };
        @{ $used_wells{FK_Sample__ID} } = values %{ $sample->{$plate_ids} };

        my $index = 0;
        foreach my $well ( @{ $used_wells{Well} } ) {
            my $sample_info;
            foreach my $result ( @{ $samples{$well} } ) {
                $sample_info .= $result . "<BR>";
            }

            $well = format_well( $well, 'nopad' );
            my $sample = $used_wells{FK_Sample__ID}[$index];

            $availability{$well} = alDente::Tools::alDente_ref( 'Sample', $sample, -dbc => $dbc, -tooltip => $sample_info );    # &Link_To( $dbc->config('homelink'), $sample, "&HomePage=Sample&ID=$sample", $Settings{LINK_COLOUR}, ['newwin']);
            $index++;
        }
    }

    my $max_row = $wells{Max_Row}[0];
    my $max_col = $wells{Max_Col}[0];

    # remove zeropads
    @Us = map { &format_well( $_, 'nopad' ) } @Us;
    @Es = map { &format_well( $_, 'nopad' ) } @Es;

    my $wellstableid = 'Well_Table';

    my %preset_colour;

    my $highlight     = "red";
    my $dim_highlight = "pink";
    my $U_highlight   = "gray";
    my $P_highlight   = "orange";
    my $E_highlight   = "lightgreen";
    $preset_colour{$U_highlight} = \@Us;
    $preset_colour{$E_highlight} = \@Es;

    print &alDente::Container_Views::select_wells_on_plate(
        -table_id                 => $wellstableid,
        -max_row                  => $max_row,
        -max_col                  => $max_col,
        -availability             => \%availability,
        -tray_flag                => $tray_flag,
        -preset_colour            => \%preset_colour,
        -input_type               => 'link',
        -printable_page_link_only => $printable_page_link_only,
        -display_simple           => 1,
        -action                   => $action
    );

    return 1;
}

###############################
# Subroutine: takes a plate id and a well, and returns
#             the corresponding plate id and well for
#             the original plate
# Return: hashref, keyed on PLATE=> and WELL=>, or undef (if cannot resolve)
################################
sub convert_to_original {
################################
    my %args     = @_;
    my $plate_id = $args{-plate};
    my $well     = $args{-well};
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my %retval;
    $retval{PLATE}         = "";
    $retval{WELL}          = "";
    $retval{ORIGINAL_SIZE} = "";
    $retval{CURRENT_SIZE}  = "";

    # get the original plate and the size
    my ($retstr) = $dbc->Table_find(
        "Plate as Current_Plate, Plate as Original_Plate",
        "Current_Plate.Plate_Size,Original_Plate.Plate_ID,Original_Plate.Plate_Size",
        "WHERE Original_Plate.Plate_ID=Current_Plate.FKOriginal_Plate__ID AND Current_Plate.Plate_ID=$plate_id"
    );
    my ( $current_size, $original, $original_size ) = split ',', $retstr;
    $retval{ORIGINAL_SIZE} = $original_size;
    $retval{CURRENT_SIZE}  = $current_size;

    # if the sizes are the same, just return
    if ( $current_size eq $original_size ) {
        $retval{PLATE} = $original;
        $retval{WELL}  = $well;
        return \%retval;
    }

    # if the sizes are different, the original size must be larger than the current size. Otherwise, there is a database error
    if ( ( $current_size eq "384-well" ) && ( $original_size eq "96-well" ) ) {

        # db error, return null
        return undef;
    }

    # get quadrant information
    my ($current_quad) = $dbc->Table_find( "Plate", "Plate.Parent_Quadrant", "WHERE Plate_ID=$plate_id" );

    # if quadrant info is blank, cannot resolve back, return undef
    unless ($current_quad) {
        return undef;
    }

    # call function to resolve well to 384-well format
    my $original_well = &alDente::Well::well_convert( -dbc => $dbc, -wells => $well, -quadrant => $current_quad, -source_size => 96, -target_size => 384 );
    $retval{PLATE} = $original;
    ( $retval{WELL} ) = &alDente::Well::Format_Wells( -wells => $original_well );
    return \%retval;
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
    my $class         = $args{-class}               || $args{-plate_class} || 'Standard';    ### Set only if Regular or Oligo Re-Array.
    my $sub_quadrants = $args{-quadrants_available} || 'a,b,c,d';                            ### (optional) - use if only some quadrants of 384 are used.
    my $unused_wells  = $args{-Unused_Wells}        || $args{-unused_wells};                 ### (optional)
    my $dbc           = $self->{dbc};

    my $returnval  = $self->SUPER::add_Plate(%args);
    my $plate_size = $args{-plate_size};
    my $quiet      = $args{-quiet};

    if ( $plate_size =~ /96/ ) {

        #$dbc->Table_update_array( "Library_Plate", ['Plate_Class'], [$class], "WHERE FK_Plate__ID=$returnval", -autoquote => 1 );
    }
    elsif ( $plate_size =~ /384/ ) {
        $sub_quadrants =~ s/\'//g;

        #$dbc->Table_update_array( "Library_Plate", [ 'Plate_Class', 'Sub_Quadrants' ], [ $class, $sub_quadrants ], "WHERE FK_Plate__ID=$returnval", -autoquote => 1 );
        $dbc->Table_update_array( "Library_Plate", ['Sub_Quadrants'], [$sub_quadrants], "WHERE FK_Plate__ID=$returnval", -autoquote => 1 );
    }

    my ($newplate) = $dbc->Table_find( 'Library_Plate,Plate', 'FK_Plate__ID,FKParent_Plate__ID,FK_Library__Name,Plate.Plate_Number', "where FK_Plate__ID=Plate_ID AND Plate_ID=$returnval" );

    my ( $plate_id, $parent, $lib, $number ) = split ',', $newplate;
    Message("Added library plate $lib-$number with Plate ID: $plate_id") unless $quiet;

    return $returnval;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

#########################
sub not_wells {
#########################
    my $wells = shift;
    my $size  = shift;

    if ( $wells !~ /[a-zA-Z]\d+/ ) { return () }

    my @all_wells = ();
    if ( $size =~ /^96/ ) {
        foreach my $letter ( 'A' .. 'H' ) {
            foreach my $number ( 1 .. 12 ) {
                push( @all_wells, &format_well( $letter . $number ) );
            }
        }
    }
    elsif ( $size =~ /^384/ ) {
        foreach my $letter ( 'A' .. 'P' ) {
            foreach my $number ( 1 .. 24 ) {
                push( @all_wells, &format_well( $letter . $number ) );
            }
        }
    }

    my @given_wells = split( ',', $wells );
    my $unused = &RGTools::RGIO::set_difference( \@all_wells, \@given_wells );
    my @sorted_unused = sort { $a cmp $b } @{$unused};

    return @sorted_unused;
}

# Get available quadrants given a list of plates
#
#
############################
sub get_available_quadrants {
############################
    my %args   = filter_input( \@_, -args => 'plates' );
    my $plates = $args{-plates};
    my $dbc    = $args{-dbc};
    $plates = Cast_List( -list => $plates, -to => 'String' );
    my @tray_available_quadrants = $dbc->Table_find( 'Plate LEFT JOIN Plate_Tray ON (Plate_ID = Plate_Tray.FK_Plate__ID)', 'distinct Plate_Position', "WHERE Plate_ID in ($plates)" );
    my ($sub_quadrants) = $dbc->Table_find( 'Plate,Library_Plate', 'Sub_Quadrants', "WHERE Plate_ID = FK_Plate__ID and Plate_ID IN ($plates)" );
    my @sub_quadrants = split ',', $sub_quadrants;
    my @available_quadrants = @{ unique_items( [ @sub_quadrants, @tray_available_quadrants ] ) };
    return @available_quadrants;
}

#
#
#
######################
sub set_unused_wells {
######################
    my %args         = filter_input( \@_, -args => 'unused_wells' );
    my $unused_wells = $args{-unused_wells};
    my $plate        = $args{-plate};
    my $dbc          = $args{-dbc};
    my $updated_wells;
    if ($unused_wells) {
        $updated_wells = $dbc->Table_update_array( 'Library_Plate', ['Unused_Wells'], ["'$unused_wells'"], "where FK_Plate__ID = $plate" );
    }
    return $updated_wells;
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

$Id: Library_Plate.pm,v 1.79 2004/11/29 23:57:36 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
