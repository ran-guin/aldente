################################################################################
# GelRun.pm
#
# This module handles Container (Plate) based functions
#
###############################################################################
package alDente::GelRun;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

GelRun.pm - This module handles GelRun based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Container (GelRun Plate) based functions<BR>

=cut

##############################
# superclasses               #
##############################

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
use RGTools::Barcode;

##############################
# custom_modules_ref         #
##############################
use alDente::Form;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use alDente::Well;
use alDente::Container;
use SDB::DBIO;
use SDB::CustomSettings;

use SDB::HTML;
use RGTools::RGIO;
use RGTools::Conversion;
use alDente::Sample;
use alDente::Run;
use alDente::Prep;
use alDente::Barcoding;
use alDente::Rack;
use alDente::Library_Plate_Set;
use alDente::Validation qw(get_aldente_id);

##############################
# global_vars                #
##############################
use vars qw($project_dir $vector_directory $Sess);
use vars qw($testing $current_plates);
use vars qw(%Settings %User_Setting %Department_Settings %Defaults %Login $URL_path %Tool_Tips @libraries);

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

    my $dbc       = $args{-dbc}       || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $gelrun_id = $args{-gelrun_id} || $args{-id};
    my $run_id    = $args{-run_id};
    my $encoded   = $args{-encoded}   || 0;                                                                 ## reference to encoded object (frozen)
    my $attributes = $args{-attributes};
    my $tables = $args{-tables} || 'GelRun';

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => $tables, -encoded => $encoded );
    my ($class) = ref($this) || $this;

    bless $self, $class;
    $self->add_tables('Plate,Run');

    $self->{dbc} = $dbc;
    if ($gelrun_id) {
        $self->{id} = $gelrun_id;                                                                           ## list of current plate_ids
        $self->primary_value( -table => 'GelRun', -value => $gelrun_id );                                   ## same thing as above..
        $self->load_Object();

    }
    elsif ($run_id) {
        $self->primary_value( -table => 'Run', -value => $run_id );
        $self->load_Object();
        $self->{id} = $self->value('GelRun.FK_Run__ID');

    }
    elsif ($attributes) {

        #	$self->add_Record(-attributes=>$attributes);
    }

    return $self;
}

##############################
# public_methods             #
##############################

sub load_gelrun {
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $gelrun_id = $args{-gelrun_id};

    $self->{id} = $gelrun_id;
    $self->primary_value( -table => 'GelRun', -value => $gelrun_id );
    $self->load_Object();

    return 1;
}

############################
sub load_Object {
#########################
    #
    # Load Plate information into attributes from Database
    #
    my $self = shift;
    my %args = @_;

    my $scope    = $args{-scope}    || '';
    my $dbc      = $args{-dbc}      || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id = $args{-plate_id} || $self->{plate_id};

    unless ( $self->primary_value( -table => 'GelRun' ) || $self->primary_value( -table => 'Run' ) ) { $dbc->warning("GP not defined") }
    $self->SUPER::load_Object();

    #$self->{name} = $self->{fields}->{FK_Library__Name}->{value} . '-' .
    #$self->{fields}->{Plate_Number}->{value};

    $self->{plate_id} = $self->value('Run.FK_Plate__ID');

    my $condition;

    if ( $self->{id} ) {
        $condition = "Run.Run_ID=GelRun.FK_Run__ID AND GelRun.GelRun_ID=$self->{id} and Lane.FK_GelRun__ID = GelRun_ID";
    }
    elsif ( $self->primary_value( -table => 'Run' ) ) {
        $condition = "Run.Run_ID = " . $self->primary_value( -table => 'Run' ) . " AND GelRun.FK_Run__ID=Run.Run_ID AND Lane.FK_GelRun__ID = GelRun_ID";
    }

    # Store the lane and gel information in the object
    my @lane_bands = $dbc->Table_find( 'GelRun,Run,Lane JOIN Band ON Band.FK_Lane__ID = Lane.Lane_ID', 'Band_ID,Well,Lane_Number,Band_Number,Band_Size,Band_Intensity,FK_Sample__ID,Run_Comments, Band_Size_Estimate', "WHERE $condition" );

    my %lanes_info = $dbc->Table_retrieve( 'GelRun,Run,Lane,Sample', [qw(Lane_ID Sample_Name Lane_Number Lane_Status Band_Size_Estimate Bands_Count Well Lane_Growth)], "WHERE $condition AND FK_GelRun__ID=GelRun_ID AND Sample_ID=FK_Sample__ID" );

    my %lanes;

    my $index = -1;

    while ( $lanes_info{Lane_ID}[ ++$index ] ) {
        ## Find all the bands form the lane
        my @bands_list = $dbc->Table_find( 'Band', 'Band_Size', "WHERE FK_Lane__ID= $lanes_info{Lane_ID}[$index]" );
        my $bands_list = join ',', @bands_list;
        my $band_count = $lanes_info{Bands_Count}[$index] || scalar(@bands_list);
        $lanes{ $lanes_info{Lane_Number}[$index] } = {
            'Sample_Name'        => $lanes_info{Sample_Name}[$index],
            'Lane_Status'        => $lanes_info{Lane_Status}[$index],
            'Bands_Count'        => $band_count,
            'Bands'              => $bands_list,
            'Lane_Growth'        => $lanes_info{Lane_Growth}[$index],
            'Band_Size_Estimate' => $lanes_info{Band_Size_Estimate}[$index],
            'Well'               => $lanes_info{Well}[$index],
            'Lane_ID'            => $lanes_info{Lane_ID}[$index],
        };
    }

    $self->{lanes} = \%lanes;

    $self->{lane_info} = \@lane_bands;
    if ( scalar(@lane_bands) > 0 ) {
        $self->{bands} = 1;
    }

    return 1;
}

##############################################
# Standard GelRun information display
#
#
#
#############
sub home_page {
#############
    #
    # Simple home page for GelRun (when id is defined).
    #
    my $self = shift;
    my %args = @_;
    $self->load_Object();
    my $brief    = $args{-brief};
    my $plate_id = $self->value('Plate.Plate_ID');

    $current_plates = $self->{plate_id};
    print &alDente::Container::Display_Input( $self->{dbc} );
    print "<Table cellpadding=0><TR><TD valign=top width=100%>";

    if ( $self->{id} ) {
        $self->primary_value( -table => 'GelRun', -value => $self->{id} );
    }
    elsif ( $self->{plate_id} ) {
        $self->primary_value( -table => 'Plate', -value => $self->{plate_id} );
    }
    else { $self->{dbc}->error("NO Plate defined"); }

    $self->add_tables( [ 'Employee', 'GelRun' ] );

    $self->label( -plate_id => $plate_id );

    #my $plate = alDente::Container->new(-id=>$plate_id);
    #print $plate->display_ancestry();

    $self->display_actions( -plate_id => $self->{plate_id} );

    ## print out general information at the right hand side of the screen ##
    unless ($brief) {
        print "</TD><TD align=right valign=top bgcolor=white>";
        print $self->display_Record( -tables => [ 'GelRun', 'Run', 'Plate' ] );
    }

    print "</TD></TR></Table>";

    #$self->display_Gel();
    return 1;
}

#######################
# Method to parse out the CGI Params. (Execution will reach here if Mapping_Gel is one of the params)
#
##################
sub request_broker {
##################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    if ( param('Create_Gel_Runs') ) {

        my $index = 0;
        my %gel_request;
        my @attribs = split ',', param('GelRunAttribs');
        my $agarosepour_equipment = param('AgarosePourEquipment');
        $agarosepour_equipment = &get_aldente_id( $dbc, $agarosepour_equipment, 'Equipment' );

        unless ($agarosepour_equipment) {
            Message("Error: Invalid Media Prep Equipment scanned");
            return 0;
        }

        while ( defined param( "Rack" . ++$index ) ) {
            $gel_request{$index}{Rack}        = param("Rack$index");
            $gel_request{$index}{Comb}        = param("Comb$index");
            $gel_request{$index}{Agarose}     = param("Solution$index");
            $gel_request{$index}{Comments}    = param("Comments$index");
            $gel_request{$index}{AgarosePour} = $agarosepour_equipment if ($agarosepour_equipment);
            map { $gel_request{$index}{Attributes}{$_} = param( "AttribID$_" . "Order$index" ) } @attribs;
        }
        alDente::GelRun::create_gelrun( \%gel_request );

    }
    elsif ( param('Load GelRun') ) {
        my $plate_id = param('FK_Plate__ID');

        my %list;
        my %preset;
        my %grey;

        my ( $run_dirs, $error ) = &alDente::Run::_nextname( -plate_ids => $plate_id, -check_branch => 1 );

        if ($error) {
            Message("Error: Can not determine Run Directory");
            return 0;
        }

        my @gb_ids = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
            'Equipment_ID', "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Category='Gel Box'" );
        my $gb_list = join ',', @gb_ids;
        $list{'RunBatch.FK_Equipment__ID'} = [
            SDB::DBIO::get_FK_info_list(
                -dbc   => $dbc,
                -field => 'FK_Equipment__ID',

                #-condition => "Equipment_Name='TBD' OR Equipment_ID IN ($gb_list)"
                -condition => "Equipment_Name='TBD'"
            )
        ];

        #my @scan_ids = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
        #    'Equipment_ID', "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Category='Gel Imager/Scanner'" );
        #my $scan_list = join ',', @scan_ids;
        #$list{'GelRun.FKScanner_Equipment__ID'} = [
        $list{'GelRun.FKGelBox_Equipment__ID'} = [
            SDB::DBIO::get_FK_info_list(
                -dbc   => $dbc,
                -field => 'FK_Equipment__ID',

                #-condition => "Equipment_ID IN ($scan_list)"
                -condition => "Equipment_ID IN ($gb_list)"
            )
        ];

        my @gc_ids = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
            'Equipment_ID', "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Category='Gel Comb'" );
        my $gc_list = join ',', @gc_ids;
        $list{'GelRun.FKComb_Equipment__ID'} = [
            SDB::DBIO::get_FK_info_list(
                -dbc       => $dbc,
                -field     => 'FK_Equipment__ID',
                -condition => "Equipment_ID IN ($gc_list)"
            )
        ];

        $grey{'FK_Plate__ID'}             = $plate_id;
        $grey{'Run_DateTime'}             = &date_time();
        $grey{'RunBatch_RequestDateTime'} = &date_time();
        $grey{'Run_Type'}                 = "GelRun";
        $grey{'Run_Directory'}            = $run_dirs->[0];

        $preset{'GelRun_Type'}  = 'Other';
        $preset{'Status'}       = 'Active';
        $preset{'FK_Plate__ID'} = $plate_id;

        my %parameters = _alDente_URL_Parameters($dbc);
        my $run_form = SDB::DB_Form->new( -dbc => $dbc, -table => "RunBatch", -target => "Database", -quiet => 1, -wrap => 1, -parameters => \%parameters );
        $run_form->configure( -grey => \%grey, -preset => \%preset, -list => \%list );
        $run_form->generate();

    }
    elsif ( param('Start GelRun') ) {
        my @gelboxes    = param('equipment_id');
        my @runs        = param('run_id');
        my @plates      = param('plate_id');
        my @load_format = param('LoadFormat');
        my @test_status = param('Test_Status');
        my @purposes    = param('GelRun_Purpose');
        my @comments    = param('Run_Comments');

        return &start_gelruns( -gelboxes => \@gelboxes, -plates => \@plates, -gelruns => \@runs, -load_format => \@load_format, -test_status => \@test_status, -gelrun_purpose => \@purposes, -comments => \@comments ) or &main::leave();
    }
    elsif ( param('Define Bands') ) {
        my %parameters = _alDente_URL_Parameters($dbc);
        my $band_fh    = param('Band File');

        my $gel = param('GelRun');

        my $gel_plate = alDente::GelRun->new( -dbc => $dbc, -id => $gel );

        my $bands = $gel_plate->get_Bands( -file => $band_fh );
        unless ($bands) {
            Message("File not found");

            return 0;
        }
        my $file_format = 'Other';
        print &alDente::Form::start_alDente_form( $dbc, );

        my @bands_list = Cast_List( -list => $bands, -to => 'Array' );

        #check the file format
        if ( $band_fh =~ /\.sizes/i ) {
            $file_format = "Sizing Gel";
        }

        #Display the bands
        $gel_plate->update( -fields => ['GelRun_Type'], -values => [$file_format] );
        print $gel_plate->confirm_create_bands( -bands_list => \@bands_list, -file_format => $file_format, -dbc => $dbc );

    }
    elsif ( param('Upload Band file') ) {

        #Display the contents of the file and prompt user to confirm the upload
        print &alDente::Form::start_alDente_form( $dbc, );
        my $file_format = param('File Format');
        my $gel         = param('GelRun');
        my $gel_plate   = alDente::GelRun->new( -dbc => $dbc, -id => $gel );

        $gel_plate->create_Bands( -file_format => $file_format );

    }
    elsif ( param('View GelRun Lanes') ) {

        # View the lanes on the gel
        my $plate         = param('Current Plates');
        my $marker_lanes  = param('Marker_Lanes');
        my $lane_comments = param('Lane_Comments');
        my $lane_growth   = param('Lane_Growth');
        my $gel           = param('GelRun');

        my $gel_plate = alDente::GelRun->new( -dbc => $dbc, -id => $gel );
        print $gel_plate->display_Gel_Lanes( -markers => $marker_lanes, -comments => $lane_comments, -growth => $lane_growth );

    }
    elsif ( param('Edit Lane') ) {

        my $lane      = param('Lane_Number');
        my $gel_plate = param('GelRun');
        &alDente::GelRun::edit_Lane( -lane => $lane, -gel => $gel_plate );

    }
    elsif ( param('Update Lane Status') ) {
        my $lane        = param('Lane_Number');
        my $gel         = param('GelRun');
        my $lane_status = param('Lane_Status');
        unless ( $lane_status eq 'No Comments' ) {
            my $OK = $dbc->Table_update_array( "Lane", ['Lane_Status'], ["'$lane_status'"], "WHERE FK_GelRun__ID=$gel and Lane_Number=$lane" );
            if ($OK) {
                Message("Lane Number $lane updated");
                my $gel = alDente::GelRun->new( -dbc => $dbc, -id => $gel );
                $gel->home_page();

            }
        }
    }
    elsif ( param('Update GelRun Status') ) {
        my $gel_status = param('GelRun Status');
        my $gel_id     = param('GelRun');
        my $gel_plate  = param('GelRun Plate');
        my $run_id     = join ',', $dbc->Table_find( 'GelRun', 'FK_Run__ID', "WHERE GelRun_ID = $gel_id" );
        my $OK         = $dbc->Table_update_array( "Run", ['Run_Status'], ["'$gel_status'"], "WHERE Run_ID = $run_id" );

        if ($OK) {
            Message("GelRun $gel_id updated");

        }
        my $gel_obj = alDente::GelRun->new( -dbc => $dbc, -id => $gel_id );
        $gel_obj->home_page();

    }
    elsif ( param('Pick Bands') ) {

        my $sample_type_id = param('Sample Type ID');
        $sample_type_id = $dbc->get_FK_ID( 'FK_Sample_Type__ID', $sample_type_id );
        my $plate_format = param('Target Plate Format');
        my $library      = param('Target_Library') || param('Library_Name Choice');
        my $pipeline     = param("FK_Pipeline__ID") || param("FK_Pipeline__ID Choice");
        $pipeline = get_FK_ID( $dbc, "FK_Pipeline__ID", $pipeline );
        my $gel = param('GelRun');
        my $rack_id;
        if    ( param('FK_Rack__ID Choice') =~ /Rac(\d+)/ ) { $rack_id = $1; }
        elsif ( param('FK_Rack__ID Choice') =~ /(\d+)/ )    { $rack_id = param('FK_Rack__ID Choice'); }
        my $gel_plate = alDente::GelRun->new( -dbc => $dbc, -id => $gel );

        if ( $plate_format && $sample_type_id ) {

            $gel_plate->confirm_pick_bands( -plate_format => $plate_format, -sample_type_id => $sample_type_id, -rack_id => $rack_id, -library => $library, -pipeline => $pipeline );
        }

        #print &alDente::Form::start_alDente_form($dbc,);
        else {
            $dbc->warning("Plate format and plate comments are mandatory");
            $gel_plate->home_page();

        }
    }
    elsif ( param('Pick Bands To Plate') ) {
        my $plate_id = param('Plate_ID');
        my $gel      = param('GelRun');
        $plate_id = get_aldente_id( $dbc, $plate_id, 'Plate' ) if ( $plate_id =~ /pla/i );
        my $gel_plate = alDente::GelRun->new( -dbc => $dbc, -id => $gel );
        $gel_plate->confirm_pick_bands( -target_plate_id => $plate_id );

    }
    elsif ( param('Extract Bands') ) {

        my @bands          = param('TargetText');
        my $plate_id       = param('Plate ID');
        my $gel            = param('GelRun');
        my $sample_type_id = param('Sample Type ID');
        my $plate_format   = param('Plate_Format');
        my $rack_id        = param('Target_Rack');
        my $existing_plate = param('Existing_Plate');
        my @target_wells   = param('Target_Well');
        my $target_library = param('Target_Library');
        my $pipeline       = param('Pipeline');
        my $gel_plate      = alDente::GelRun->new( -dbc => $dbc, -id => $gel );
        $existing_plate = get_aldente_id( $dbc, $existing_plate, 'Plate' ) if ( $existing_plate =~ /pla/i );
        $gel_plate->extract_Bands(
            -existing_plate => $existing_plate,
            -bands          => \@bands,
            -sample_type_id => $sample_type_id,
            -pipeline       => $pipeline,
            -target_library => $target_library,
            -plate_format   => $plate_format,
            -rack_id        => $rack_id,
            -wells          => \@target_wells
        );

    }
    elsif ( param('Preview GelRun Extraction') ) {
        my $gel          = param('GelRun');
        my @bands        = param('TargetText');
        my @target_wells = param('Target_Well');
        my $gel_plate    = alDente::GelRun->new( -dbc => $dbc, -id => $gel );
        my $display_info = $gel_plate->display_gel_extraction( -target_wells => \@target_wells, -bands => \@bands );
        $display_info->Printout();

    }
    elsif ( param('ReImportGel') ) {
        my $gel = param('GelRun');

        my @lanes = $dbc->Table_find( 'Lane', 'Lane_ID', "WHERE FK_GelRun__ID = $gel" );
        my $lane = Cast_List( -list => \@lanes, -to => 'String' );
        my $transaction = $dbc->start_trans( -name => 'GelRun_delete_lanes' );
        my $ok = $dbc->delete_records( -table => 'Lane', -field => 'Lane_ID', -id_list => $lane, -cascade => get_cascade_tables('Lane'), -transaction => $transaction, -quiet => 1 );
        $dbc->finish_trans('GelRun_delete_lanes');
        if ($ok) {
            my $gel_plate = alDente::GelRun->new( -dbc => $dbc, -id => $gel );
            Message("GelRun reset");
            $gel_plate->home_page();
        }
    }

    elsif ( param('Create New Gel Tray') ) {
        my $count = param('Count');
        &add_geltray( -dbc => $dbc, -count => $count );
    }

    else {
        Message("No Params found :(");
    }

}

######################
# Method to prompt the user for entering GelRun initiation parameters
#
#
# We have 2 methods of entry:
#       1: From request_broker()          -> User enters the number of Gels and an Agarose Solution from Homepage
#       2: From Equipment::HomeInfo()   -> User has scanned a series of Combs and Agarose and potentially Gel Trays (Racks)
#         In this form, if there are no attributes available and GelTrays are provided, the system automatically creates the GelRuns
#
#
######################
sub gel_request_form {
######################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $req  = HTML_Table->new( -title => 'Gel Run Request' );
    my @headers;

    my $sol          = $args{-solution};
    my $agarose_pour = $args{-agarose_pour};
    my @combs        = Cast_List( -list => $args{-combs}, -to => 'Array' );
    my @gel_trays    = Cast_List( -list => $args{-gel_trays}, -to => 'Array' );

    foreach my $rack (@gel_trays) {
        unless ( &_gelrack_available( $dbc, $rack ) ) {
            my $rack_info = $dbc->get_FK_info( 'FK_Rack__ID', $rack );
            Message("Warning: $rack_info is not available to be used for a new Run!");
        }
    }

    my $grp_list = join ',', $dbc->get_local('group_list');
    my %attributes = &Table_retrieve( $dbc, 'Attribute', [ 'Attribute_ID', 'Attribute_Format', 'Attribute_Name' ], "WHERE Attribute_Class='GelRun' AND FK_Grp__ID IN ($grp_list)" );

    my $quant;
    if (@combs) { $quant = scalar(@combs); }

    if ( scalar(@gel_trays) == $quant ) {
        my $field_size = 7;
        my $index      = -1;

        my @extra_fields;
        while ( $attributes{Attribute_ID}->[ ++$index ] ) {
            push( @headers,      $attributes{Attribute_Name}->[$index] );
            push( @extra_fields, $attributes{Attribute_ID}->[$index] );
        }
        push( @headers, 'Comments', 'Details' );

        $req->Set_Headers( \@headers );
        $req->Set_Row( [ 'Media Prep Equipment:' . lbr . textfield( -name => 'AgarosePourEquipment', -value => '', -foce => 1, -size => 10 ) ] );
        foreach my $gel_num ( 1 .. $quant ) {
            my @row = map { textfield( -name => "AttribID$_" . "Order$gel_num", -size => $field_size, -force => 1 ) } @extra_fields;
            push( @row,
                textfield( -name => "Comments$gel_num", -size => $field_size, -force => 1 ),
                $dbc->get_FK_info( 'FK_Rack__ID',            $gel_trays[ $gel_num - 1 ] ) . ', '
                    . $dbc->get_FK_info( 'FK_Equipment__ID', $combs[ $gel_num - 1 ] ) . ', '
                    . $dbc->get_FK_info( 'FK_Solution__ID',  $sol )
                    . $dbc->get_FK_info( 'FK_Equipment__ID', $agarose_pour )
                    . hidden( -name => "Rack$gel_num",     -value => $gel_trays[ $gel_num - 1 ], -force => 1 )
                    . hidden( -name => "Comb$gel_num",     -value => $combs[ $gel_num - 1 ],     -force => 1 )
                    . hidden( -name => "Solution$gel_num", -value => $sol,                       -force => 1 ) );
            $req->Set_Row( \@row );
        }
        $req->Set_Row( [ reset( -class => 'Std' ), submit( -name => 'Create_Gel_Runs', -value => 'Create', -class => 'Action' ) ] );

        print alDente::Form::start_alDente_form( $dbc, 'gel_run_form', $dbc->homelink() ) . hidden( -name => 'GelRunAttribs', -value => join ',', @extra_fields ) . hidden( -name => 'GelRun_Request' ) . $req->Printout(0) . "</form>";
    }
    else {
        print HTML_Dump( \%args );
        Message("Error: Wrong number of Gel Trays and Combs scanned");
    }
}

##########################################
# Create single or multiple gel runs
#
# Method to instantiate "empty" Gel Runs (ie do not have any plates associated with them)
#
# request_list is a hash, with keys starting from 1. Minimum requried fields needed to be passed in are Rack,Comb and Agarose
# it could also contain an an Attributes key that contains the attribute_id,value pairs in it
#
# An example for an input parameter:
#
# <snip>
# Example:
# my %gel_run_info = (
#  '1' => {
#		 'Rack' => 'RAC25835',
#		 'Comb' => 'EQU509',
#		 'Attributes' => {
#				   '27' => '21'
#				 },
#		 'Agarose' => 'SOL45178',
#		 'Comments' => ''
#	       },
#  '2' => {
#		 'Rack' => 'RAC25836',
#		 'Comb' => 'EQU510',
#		 'Attributes' => {
#				   '27' => '22'
#				 },
#		 'Agarose' => 'SOL45178',
#		 'Comments' => ''
#	       }
#);
#
#     my $gel = alDente::GelRun->new(-dbc=>$dbc);
#     $gel->create_gelrun(-gel_run_info=>\%gel_run_info);
# </snip>
#
######################
sub create_gelrun {
######################
    my %args = filter_input( \@_, -args => 'gel_run_info' );
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $gel_run_info = $args{-gel_run_info};
    my $user_id      = $dbc->get_local('user_id');

    my %gel_run_info;
    %gel_run_info = %{$gel_run_info} if $gel_run_info;
    my %gel_run;

    my %gelrun_attributes;

    my $now             = &date_time();
    my @runbatch_fields = qw(FK_Employee__ID FK_Equipment__ID RunBatch_RequestDateTime);
    my @run_fields      = qw(Run_Type Run_DateTime Run_Comments Run_Test_Status Run_Status Run_Directory FKPosition_Rack__ID Run_Validation);
    my @gelrun_fields   = qw(FKPoured_Employee__ID FKComb_Equipment__ID FKAgarose_Solution__ID FKAgarosePour_Equipment__ID Agarose_Percentage GelRun_Type);

    my @fields = ( @runbatch_fields, @run_fields, @gelrun_fields );

    my ($tbd_equipment) = $dbc->Table_find( 'Equipment', 'Equipment_ID', "WHERE Equipment_name='TBD'" );
    my ($tbd_employee)  = $dbc->Table_find( 'Employee',  'Employee_ID',  "WHERE Employee_Name='TBD Employee'" );

    foreach my $key ( keys %gel_run_info ) {
        my $rack         = $dbc->get_FK_ID( 'FK_Rack__ID',      $gel_run_info{$key}->{Rack} );
        my $comb         = $dbc->get_FK_ID( 'FK_Equipment__ID', $gel_run_info{$key}->{Comb} );
        my $agar_sol     = $dbc->get_FK_ID( 'FK_Solution__ID',  $gel_run_info{$key}->{Agarose} );
        my $agarose_pour = $dbc->get_FK_ID( 'FK_Equipment__ID', $gel_run_info{$key}->{AgarosePour} );
        my $test_status = $gel_run_info{$key}->{Test_Status} || 'NULL';
        my $gel_comments = "Pour: $gel_run_info{$key}->{Comments}" if ( $gel_run_info{$key}->{Comments} );
        my $agar_percentage = $gel_run_info{$key}->{Agarose_Percentage};

        $gel_run{$key} = [ $tbd_employee, $tbd_equipment, $now, 'GelRun', $now, $gel_comments, $test_status, 'Initiated', 'NULL', $rack, 'Pending', $user_id, $comb, $agar_sol, $agarose_pour, $agar_percentage, 'Sizing Gel' ];
        $gelrun_attributes{$key} = $gel_run_info{$key}->{Attributes};
    }

    my $run_ids = $dbc->smart_append( -tables => 'RunBatch,Run,GelRun', -fields => \@fields, -values => \%gel_run, -autoquote => 1 );

    my @run_ids;
    if ( $run_ids->{Run}->{newids} ) {
        @run_ids = @{ $run_ids->{Run}->{newids} };
        my $new_runs = join ',', @run_ids;
        Message( "Created Run(s): " . &Link_To( $dbc->config('homelink'), $new_runs, "&Info=1&TableName=Run&Field=Run_ID&Like=$new_runs" ) . '<BR>' );
    }
    else {
        Message("Error: Problems appending");
        print HTML_Dump( \@fields, \%gel_run );
        Call_Stack();
        return 0;
    }
    my $index     = 1;
    my $key_index = 1;
    my %attributes;
    my $time = &date_time();
    foreach my $run (@run_ids) {
        &alDente::Barcoding::PrintBarcode( $dbc, 'GelRun', $run );

        foreach my $attr ( keys %{ $gelrun_attributes{$index} } ) {
            $attributes{$key_index} = [ $run, $attr, $gelrun_attributes{$index}->{$attr}, $user_id, $time ];

            $key_index++;
        }
        $index++;
    }

    if (%attributes) {
        my $gelrun_attributes = $dbc->smart_append( -tables => 'Run_Attribute', -fields => [ 'FK_Run__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' ], -values => \%attributes, -autoquote => 1 );
    }

    return $run_ids;
}

########################################################
#
# Method to Start the Gel Runs (ie creation & association with Runs)
#
# Creates a RunBatch of 2 Runs, and associates the already existing GelRuns with these Runs
#
# <snip>
#     alDente::GelRun::start_gelruns(-gelboxes=>$equipment_id, -plates=>\@plate_ids, -gelruns=>\@gel_runs);
# </snip>
#
###################
sub start_gelruns {
###################
    my %args = &filter_input( \@_, -args => 'gelboxes,plates,gelruns' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    if ( $args{ERRORS} ) { Message("Error: $args{ERRORS}") }
    my $user_id = $dbc->get_local('user_id');

    my @plates           = Cast_List( -list => $args{-plates},         -to => 'array' );
    my @gelruns          = Cast_List( -list => $args{-gelruns},        -to => 'array' );
    my @scanned_gelboxes = Cast_List( -list => $args{-gelboxes},       -to => 'array' );
    my @load_format      = Cast_List( -list => $args{-load_format},    -to => 'array' );
    my @test_status      = Cast_List( -list => $args{-test_status},    -to => 'array' );
    my @gelrun_purposes  = Cast_List( -list => $args{-gelrun_purpose}, -to => 'array' );
    my @comments         = Cast_List( -list => $args{-comments},       -to => 'array' );

    my $quiet = $args{-quiet};

    unless ( scalar(@gelruns) == scalar(@plates) ) {
        Message("Error: Incorrect number of Gels/Plates scanned");
        return 0;
    }

    if ( _gel_started( -gelruns => \@gelruns ) ) {
        Message("Error: Some of the Gels have already been started");
        return 0;
    }

    my $gelrun_list = join( ',', @gelruns );

    ### Retrieve the racks so that we can move them to the correct equipment (gel box)
    my %gel_hash = $dbc->Table_retrieve( "Run,GelRun,RunBatch", [ 'Run_ID', 'FKPosition_Rack__ID', 'RunBatch_ID' ], "WHERE RunBatch_ID = FK_RunBatch__ID and Run_ID=FK_Run__ID AND Run_ID IN ($gelrun_list)" );
    my ( @gel_racks, @run_batches );

    if (%gel_hash) {
        %gel_hash = %{ rekey_hash( \%gel_hash, 'Run_ID' ) };
        foreach (@gelruns) {
            push( @gel_racks,   $gel_hash{$_}{FKPosition_Rack__ID}[0] );
            push( @run_batches, $gel_hash{$_}{RunBatch_ID}[0] );
        }
    }
    else {
        Message("Error: Invalid GelRuns ($gelrun_list)");
        return 0;
    }

    ### Plate Format Check
    my $plate_list = join( ',', @plates );
    my @plate_formats = $dbc->Table_find( 'Plate', 'Plate_Size', "WHERE Plate_ID IN ($plate_list) AND Plate_Size='96-well'" );
    if ( int(@plate_formats) != int(@plates) ) {
        Message("Error: All the plates must be in 96-well format");
        return 0;
    }

    my @parent_racks;
    my @gelboxes;
    my %parent_gel_racks = $dbc->Table_retrieve( 'Rack', [ 'Rack_ID', 'FKParent_Rack__ID' ], "WHERE Rack_ID IN (" . join( ',', @gel_racks ) . ")" );
    if (%parent_gel_racks) {
        %parent_gel_racks = %{ rekey_hash( \%parent_gel_racks, 'Rack_ID' ) };
        foreach (@gel_racks) {
            push( @parent_racks, $parent_gel_racks{$_}{FKParent_Rack__ID}[0] );
        }
        if ( int(@scanned_gelboxes) != int(@gel_racks) ) {
            my $parent_rack_count = int( @{ &unique_items( \@parent_racks ) } );
            if ( $parent_rack_count != int(@scanned_gelboxes) ) {
                Message("Error: Invalid number of Gel Boxes scanned");
                return 0;
            }
            else {
                ### Assign the correct gel box to gel trays (same parent racks)
                my $j = 0;
                for ( my $i = 0; $i < int(@gel_racks); $i++ ) {
                    push( @gelboxes, $scanned_gelboxes[$j] );
                    if ( $parent_racks[$i] != $parent_racks[ $i + 1 ] ) {
                        $j++;
                    }
                }
            }
            ### <ASSUMPTION> Two Gels per Tray
            if ( int(@scanned_gelboxes) > int(@gel_racks) / 2 ) {
                my $single_gels = int(@scanned_gelboxes) * 2 - int(@gel_racks);
                Message("Warning: Using $single_gels Single Gels");
            }
        }
        else {
            @gelboxes = @scanned_gelboxes;
        }
    }
    else {
        Message( "Error: Invalid gel racks: " . join( ',', @gel_racks ) );
        return 0;
    }

    my ( $run_dirs, $error ) = &alDente::Run::_nextname( -plate_ids => $plate_list, -check_branch => 1 );
    my @plate_libraries = $dbc->Table_find( 'Plate', 'FK_Library__Name', "WHERE Plate_ID IN ($plate_list)", -distinct => 1 );
    my $plate_libraries = join( "|", @plate_libraries );

    if ($error) {
        Message("Error: Problem starting Gel Runs");
        return 0;
    }

    if (@load_format) {

        my ($tmp_rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name='Temporary'" );

        my %formats_cache;
        foreach my $i ( 0 .. int(@plates) - 1 ) {
            if ( $load_format[$i] <= 0 ) {
                Message("Error: Please select a loading format for all the Gel Runs");
                delete $args{-load_format};
                &start_gelruns(%args);
                return 0;
            }
            elsif ( !$formats_cache{ $load_format[$i] } ) {
                $formats_cache{ $load_format[$i] } = $dbc->get_FK_info( 'FK_Plate_Format__ID', $load_format[$i] );
            }
        }

        my @gel_plates;
        foreach my $i ( 0 .. int(@plates) - 1 ) {

            #my $Set = alDente::Library_Plate_Set->new(-ids=>$plates[$i]);
            #push(@gel_plates, $Set->transfer(-format=>$formats_cache{$load_format[$i]},-rack=>$tmp_rack,-type=>'Aliquot',-no_print=>1));
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $plates[$i], -save => 1, -force => 1 );
            my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id );
            $Prep->{suppress_print} = 1;
            $Prep->Record( -ids => $plates[$i], -protocol => 'MP Loading', -step => "Aliquot to $formats_cache{$load_format[$i]}", -set => $Set->{set_number} );
            $Prep->Record( -ids => $Prep->{plate_ids}, -protocol => 'MP Loading', -step => "Completed Protocol" );
            push @gel_plates, $Prep->{plate_ids};
        }

        my $ok  = 1;
        my $now = &date_time();

        ### Start a transaction
        $dbc->start_trans( -name => 'GelRun_start_gelruns' );

        my %moved;    ## Cache of moved parent racks...
        for ( my $index = 0; $index < int(@gelruns); $index++ ) {
            my $box_id            = $gelboxes[$index];
            my $rack_id           = $parent_racks[$index];
            my $gelrun_purpose_id = $dbc->get_FK_ID( 'FK_GelRun_Purpose__ID', $gelrun_purposes[$index] );
            unless ( $moved{$rack_id} ) {
                &move_geltray_to_equ( $dbc, $rack_id, $box_id );
                $moved{$rack_id} = 1;
            }

            if ( $comments[$index] ) {
                &alDente::Run::annotate_runs( -dbc => $dbc, -run_ids => $gelruns[$index], -comments => "Load: $comments[$index]", -quiet => 1 );
            }

            $ok &= $dbc->Table_update_array(
                'Run', [ 'FK_Plate__ID', 'Run_DateTime', 'Run_Directory', 'Run_Status', 'Run_Test_Status' ], [ $gel_plates[$index], $now, $run_dirs->[$index], 'In Process', $test_status[$index] ], "WHERE Run_ID = $gelruns[$index]",
                -autoquote => 1,
                -testing   => 1
            );
            $ok &= $dbc->Table_update_array( 'RunBatch', ['FK_Employee__ID'], [$user_id], "WHERE RunBatch_ID = $run_batches[$index]", -autoquote => 1, -testing => 1 );
            $ok &= $dbc->Table_update_array( 'GelRun', [ 'FKGelBox_Equipment__ID', 'FK_GelRun_Purpose__ID' ], [ $box_id, $gelrun_purpose_id ], "WHERE FK_Run__ID = $gelruns[$index]", -autoquote => 1, -testing => 1 );

            require alDente::Run;
            my $run_obj = alDente::Run->new( -dbc => $dbc, -id => $gelruns[$index], -quick_load => 1 );
            $run_obj->run_trigger();

            alDente::Barcoding::PrintBarcode( $dbc, 'Run', $gelruns[$index] );
        }

        if ($ok) {
            Message( "Loaded " . int(@gelruns) . " Gels." );
            $dbc->finish_trans('GelRun_start_gelruns');
            return 1;
        }
        else {
            Message("Warning: Not all records updated!");
            $dbc->rollback_trans( 'GelRun_start_gelruns', -error => "problem adding Run or RunBatch or GelRun" );
            return 0;
        }
    }

    else {
        my $confirm = HTML_Table->new( -title => 'Loading following Gels:' );
        $confirm->Toggle_Colour_on_Column(4);    ### Gel Box column
        if ($scanner_mode) {
            $confirm->Set_Class('vsmall');
        }

        my %f = $dbc->Table_retrieve( 'Plate_Format', [ 'Plate_Format_ID', 'Plate_Format_Type' ], "WHERE Plate_Format_Style='Gel'" );
        my %formats;
        @formats{ @{ $f{Plate_Format_ID} } } = @{ $f{Plate_Format_Type} };

        my @run_dirs = split( ',', $run_dirs );

        my @test_status = $dbc->get_enum_list( 'Run', 'Run_Test_Status' );
        my @gelrun_purposes = $dbc->Table_find( 'GelRun_Purpose', 'GelRun_Purpose_Name', "Order By GelRun_Purpose_ID" );
        $confirm->Set_Headers( [ 'Run Name', 'Method', 'Test Status', 'GelRun Purpose', 'Gel Box', 'Load Comments' ] );
        for my $i ( 0 .. int(@gelruns) - 1 ) {
            my $display_run_dir = $run_dirs->[$i];
            $display_run_dir =~ s/($plate_libraries)/$1-/;
            $confirm->Set_Row(
                [   $display_run_dir . hidden( -name => 'run_id', -value => $gelruns[$i], -force => 1 ) . hidden( -name => 'plate_id', -value => $plates[$i], -force => 1 ),

                    #$run_dirs->[$i] . hidden(-name=>'run_id',-value=>$gelruns[$i],-force=>1). hidden(-name=>'plate_id',-value=>$plates[$i],-force=>1),
                    popup_menu( -name => 'LoadFormat',     -value => [ sort keys %formats, '' ],  -labels => \%formats, -force => 1, -default => '' ),
                    popup_menu( -name => 'Test_Status',    -value => \@test_status,        -force => 1,   -default      => 'Production' ),
                    popup_menu( -name => 'GelRun_Purpose', -value => \@gelrun_purposes,    -force => 1,   -default      => 'Production' ),
                    $dbc->get_FK_info( 'FK_Equipment__ID', $gelboxes[$i] ) . hidden( -name => 'equipment_id', -value => $gelboxes[$i], -force => 1 ),
                    textarea( -name => 'Run_Comments', -rows => 2, -cols => 20 )
                ]
            );
        }
        $confirm->Set_Row( [ submit( -name => 'Submit', -class => 'Std' ) ] );
        $confirm->Set_Alignment('center');

        my %parameters = _alDente_URL_Parameters( -dbc => $dbc, -type => 'plate' );

        print alDente::Form::start_alDente_form( $dbc, 'GelRun', undef, \%parameters ) . hidden( -name => 'GelRun_Request', -value => 1 ) . hidden( -name => 'Start GelRun', -value => 1 ) . $confirm->Printout(0) . end_form();
    }
}

########################################################
# Options below home_info for GelRun containers
#
#
#################
sub display_actions {
################
    #
    # generate buttons / links that exist as options
    #
    my $self        = shift;
    my %args        = @_;
    my $dbc         = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id    = $args{-plate_id} || $self->{plate_id};
    my $return_html = $args{-return_html};
    my $html;
    unless ( ( $plate_id =~ /[1-9]/ ) && ( $plate_id !~ /,/ ) ) {return}    ## do not allow options unless 1 (and only 1) id given.

    #unless ($scanner_mode) {
    #	print "<HR><TABLE bgcolor=000066 class=mediumheader><TR><TD><FONT color=white size=-1><STRONG>GelRun Options</STRONG></FONT></TD></TR></TABLE>";
    #}

    #print Dumper $self->{gel};

    my %parameters = _alDente_URL_Parameters( -dbc => $dbc, -type => 'plate' );
    my $form = 'plate';
    $html .= alDente::Form::start_alDente_form( $dbc, $form, undef, \%parameters );

    unless ( $scanner_mode || $self->{bands} ) {

        $html
            .= '<TABLE bgcolor=eeeefe width=100%><TR><TD>' . hidden( -name => 'GelRun_Request' ) . submit( -name => 'Define Bands', -class => "Std" ) . &hspace(5) . filefield( -name => 'Band File', -size => 20, -maxlength => 200 ) . '</TD></TR></TABLE>';
        $html .= "<HR size=2 color='black'>";
    }
    my @gel_status = &get_enum_list( $dbc, 'Run', 'Run_Status' );
    $html .= submit( -name => 'Update GelRun Status', -class => "Std" ) . hspace(20);

    my $gel_status = $self->value('Run.Run_Status');

    $html .= popup_menu( -name => 'GelRun Status', -values => [ '', @gel_status ], -default => $gel_status, -force => 1 ) . "<BR><BR>";
    $html .= hidden( -name => 'GelRun', -value => $self->{id} );
    my $access = $dbc->get_local('Access')->{$Current_Department};

    if ( grep( /Admin/i, @{$access} ) ) {
        $html .= submit( -name => 'ReImportGel', -value => 'Re-Import Gel Data', -class => "Std" ) . hspace(20);
    }

    $html .= hidden( -name => 'GelRun_Request' );
    unless ($scanner_mode) {
        if ( $self->{bands} ) {

            $html .= submit( -name => 'View GelRun Lanes', -class => "Std" ) . hspace(20);

            if ( $self->value('File_Extension_Type') eq 'sizes' ) {

                $html .= checkbox( -name => "Marker_Lanes", -label => "Marker Lanes" );
            }
            $html .= checkbox( -name => "Lane_Comments", -label => "Lane Comments" );

            $html .= "<BR><BR>";
            #### Pick bands on to an existing plate

            my $pick_existing_table = HTML_Table->new();
            $pick_existing_table->Set_Title("Pick Bands on to an existing plate");
            $pick_existing_table->Set_Class('small');
            $pick_existing_table->Set_Border(1);
            $pick_existing_table->Set_Row( [ "Scan Plate:" . textfield( -name => 'Plate_ID', -size => 10, -default => '', -force => 1 ) . hspace(10) . submit( -name => 'Pick Bands To Plate', -class => "Std" ) ] );

            $html .= $pick_existing_table->Printout(0);
            #### Pick bands on to a new plate
            $html .= "<BR>";

            my $pick_new_table = HTML_Table->new();
            $pick_new_table->Set_Title("Pick Bands from GelRun to a Plate");
            $pick_new_table->Set_Class('small');
            $pick_new_table->Set_Border(1);
            $pick_new_table->toggle();
            $pick_new_table->Toggle_Colour("off");

            #print "Pick Bands from GelRun to a Plate<BR><BR>";

            my $default_lib = $self->value('Plate.FK_Library__Name');
            my @plate_formats = &get_FK_info( $dbc, 'FK_Plate_Format__ID', -condition => "WHERE Plate_Format_Style like \'%Plate%\'", -list => 1 );

            #print "Target Plate Format:" . hspace(20) . popup_menu(-name=>'Target Plate Format',-force=>1,-values=>['',@plate_formats],default=>'') . "<BR>";

            $pick_new_table->Set_Row( [ "Target Plate Format:", popup_menu( -name => 'Target Plate Format', -force => 1, -values => [ '', @plate_formats ], default => '' ) ] );
            my $library_filter = [ "Target Library: ", &alDente::Tools::search_list( -dbc => $dbc, -form => $form, -name => 'Library_Name', -options => \@libraries, -filter => 1, -search => 1, -default => $default_lib ) ];
            my $pipeline_choice = alDente::Tools->search_list( -dbc => $dbc, -form => $form, -name => 'FK_Pipeline__ID', -default => '', -search => 1, -filter => 1, -breaks => 1, -filter_by_dept => 1 );
            $pick_new_table->Set_Row( [ "Pipeline", $pipeline_choice ] );
            $pick_new_table->Set_Row($library_filter);
            my @plate_contents;

            # Check if the library is a Sequencing Library or RNA/DNA Library

            my $lib_type = &alDente::Library::check_Library_Type( -library => $self->value('Plate.FK_Library__Name') );
            if ( $lib_type eq 'seq_lib' ) {

                @plate_contents = &get_FK_info( $dbc, 'FK_Sample_Type__ID', -condition => "WHERE Sample_Type = 'Clone'", -list => 1 );
            }
            elsif ( $lib_type eq 'rna_lib' ) {
                @plate_contents = &get_FK_info( $dbc, 'FK_Sample_Type__ID', -condition => "WHERE Sample_Type != 'Clone'", -list => 1 );
            }
            my $default_rack = $dbc->get_FK_info( 'FK_Rack__ID', $self->value('Plate.FK_Rack__ID') );
            $pick_new_table->Set_Row( [ "Plate Content Type:", popup_menu( -name => 'Sample Type ID', -force => 1, -values => [ '', @plate_contents ], default => '' ) ] );

            #print "Plate Content Type:" . hspace(25) . popup_menu(-name=>'Plate Content', -force=>1, -values=>['',@plate_contents ], default=>'') . "<BR>";
            my $location_info = textfield( -name => 'FK_Rack__ID', -size => 10, -default => '', -force => 1, -onChange => "MenuSearch(document.plate,1);" ) 
                . hidden( -name => 'ForceSearch', -value => 'Search' )
                . popup_menu(
                -name     => 'FK_Rack__ID Choice',
                -values   => [ '', @locations ],
                -default  => $default_rack,
                -force    => 1,
                -onChange => "SetSelection(document.plate,FK_Rack__ID,'')"
                );

            $pick_new_table->Set_Row( [ "Location:", $location_info ] );
            $pick_new_table->Set_Row( [ hidden( -name => 'GelRun_Request' ) . submit( -name => 'Pick Bands', -class => "Std" ) ] );

            $html .= $pick_new_table->Printout(0);

        }

        #print lbr();
        #print $self->display_gel_image();
    }

    $html .= "</Form>";

    if   ( !$return_html ) { print $html }
    else                   { return $html }

    return;
}

#################################
#
# Display the GelRun <Construction>
#
#################################
sub display_Gel {
    my $self = shift;
    my %args = &filter_input( \@_ );

    my @lane_bands = Cast_List( -list => $self->{lane_info}, -to => 'Array' );

    my @wells = ();
    my @sizes = ();
    foreach my $row (@lane_bands) {
        my ( $band_id, $well, $lane_no, $band_no, $band_size, $band_intensity, $sample_id ) = split ',', $row;
        push( @wells, $lane_no );
        push( @sizes, $band_size );
    }

    #print Dumper @sizes;
    my $max;
    map { $max = $_ if $_ > $max } @sizes;

    #    my $graph = GD::Graph::points->new(1100, 700);
    my @data = ( [@wells], [@sizes] );

}

##############################
# Display the lane information
# Optional :  show marker lane and comments
#
# <snip>
# Example:
#
# my $gel_plate = alDente::GelRun->new(-dbc=>$dbc,-plate_id=>$plate);
# print $gel_plate->display_Gel_Lanes(-markers =>$marker_lanes, -comments=>$lane_comments);
#
# </snip>
# Return 1 on success
#######################
sub display_Gel_Lanes {
#######################
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $gel_plate_id = $self->{id};

    my $markers = $args{-markers};    # OPTIONAL include marker lanes

    my $lane_table = HTML_Table->new( -class => 'small', -autosort => 1 );
    my @lane_header = ();

    $lane_table->Set_Title( "Lanes for Run: " . $self->primary_value( -table => 'Run' ) );
    $lane_table->Set_Class('small');
    $lane_table->Set_Border(1);
    $lane_table->Set_Headers( [ 'Lane Number', 'Sample Name', 'Well', 'Lane Status', 'Lane Growth', 'Band Count', 'Band Size Estimate' ] );
    $lane_table->Toggle_Colour_on_Column(2);

    my @lane_bands = Cast_List( -list => $self->{lane_info}, -to => 'Array' );

    my $index         = 0;
    my $add_marker    = 0;
    my $marker_colour = "yellow";

    my @growth = ( '', get_enum_list( $dbc, 'Lane', 'Lane_Growth' ) );
    my @status = get_enum_list( $dbc, 'Lane', 'Lane_Status' );

    if ( $self->{lanes} and keys %{ $self->{lanes} } ) {
        foreach my $lane_number ( sort { $a <=> $b } keys %{ $self->{lanes} } ) {
            my $lane_id = $self->{lanes}{$lane_number}->{Lane_ID};

            $lane_table->Set_Row(
                [   $lane_number,                              $self->{lanes}{$lane_number}->{Sample_Name}, $self->{lanes}{$lane_number}{Well}, $self->{lanes}{$lane_number}{Lane_Status},
                    $self->{lanes}{$lane_number}{Lane_Growth}, $self->{lanes}{$lane_number}{Bands_Count},   $self->{lanes}{$lane_number}{Band_Size_Estimate},
                ]
            );
            if ( $self->{lanes}{$lane_number}{Status} eq 'Marker' ) {
                $lane_table->Set_Row_Colour( $lane_table->{rows}, $marker_colour );
            }
        }
        return $lane_table->Printout(0);
    }
    else {
        return Message( "No Lane entries for Run" . $self->primary_value( -table => 'Run' ), -no_print => 1 );
    }

=comment
    if ($markers)
    { 
        $lane_table->Set_Row([0, '&nbsp', '&nbsp', '&nbsp']);
	$lane_table->Set_Row_Colour($add_marker+1, $marker_colour);
	$add_marker=4;
    }

 
    my @bands;
    foreach my $row (@lane_bands){
	my ($band_id,$well,$lane_no,$band_no,$band_size,$band_intensity, $sample_id, $comments,$lane_size_estimate) = split ',',$row;
	my ($n_band_id,$n_well,$n_lane_no,$n_band_no,$n_band_size) = split ',',$lane_bands[$index+1];
	unless (grep /$band_size/, @bands){
	    push (@bands, $band_size);
	}
	unless ($comments)
	{
	    $comments= "&nbsp";
	}
	if ($n_lane_no eq $lane_no){
	   
	}
	else
	{
	    my $list_bands = Cast_List(-list=>\@bands, -to=>'String');
	    if ($lane_comments){
		$lane_table->Set_Row([&Link_To($dbc->homelink(),$lane_no,"&GelRun_Request=1&Edit+Lane=1&Lane_Number=$lane_no&GelRun=$gel_plate_id",$Settings{LINK_COLOUR},undef,undef,$Tool_Tips{Edit_Lane_Link}), $well, $list_bands, $lane_size_estimate, $comments]); 
		
	    
	    }
	    else{
		$lane_table->Set_Row([&Link_To($dbc->homelink(),$lane_no,"&GelRun_Request=1&Edit+Lane=1&Lane_Number=$lane_no&GelRun=$gel_plate_id",$Settings{LINK_COLOUR},undef,undef,$Tool_Tips{Edit_Lane_Link}) ,$well, $list_bands, $lane_size_estimate]);
	    }
	    @bands=();
	}
	if ($lane_no eq $add_marker && $n_well ne $well)
	{
	    if ($lane_comments){
		$lane_table->Set_Row([$lane_no+1, '&nbsp', '&nbsp', '&nbsp', '&nbsp']);
	    }
	    else{
		$lane_table->Set_Row([$lane_no+1, '&nbsp', '&nbsp', '&nbsp']);
	    }
	    $lane_table->Set_Row_Colour($add_marker+2, $marker_colour);
	    $add_marker += 5;
	}
	
	$index++;
    }

=cut

}
###############################
# Display GelRun Image
#
# <snip>
# Example:
#
#
#
# </snip>
#
# Return: 1 on success
###############################
sub display_gel_image {
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $gel_id   = $self->{id};            # GelRun ID
    my $plate_id = $self->{plate_id};

    ## find the gel directory
    my $gel_directory = $self->value('Run_Directory');
    my $title         = "Gel Run Images";

    my $gel_image_table = HTML_Table->new( -title => $title );

    ## Find the gel image name in the gel directory
    my @gel_images = split '\n', try_system_command("find $gel_directory -type f -iregex .*$plate_id.*\.png -o -iregex .*$plate_id.*\.tif -o -iregex .*$plate_id.*\.gel");

    foreach my $gel (@gel_images) {

        ## copy over to the temporary directory for display
        try_system_command("cp $gel $URL_temp_dir");
        ( undef, my $gel_name ) = &Resolve_Path($gel);
        $gel_image_table->Set_Row( [ Link_To( "/dynamic/tmp/$gel_name", "View GelRun ($gel_name)", "", $Settings{LINK_COLOUR}, ['newwin'] ) ] );
    }

    return $gel_image_table->Printout(0);
}

###############################
# Edit the comments for a lane
#
# <snip>
# Example:
#
# &alDente::GelRun::edit_Lane(-lane => $lane, -gel=>$gel_plate);
#
# </snip>
#
# Return: 1 on success
###############################
sub edit_Lane {
    my %args      = &filter_input( \@_ );
    my $gel_plate = $args{-gel};                                                                     # GelRun plate ID
    my $lane      = $args{-lane};                                                                    # Lane Number
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    ###  Matches the enum in the comments of Lane, change to Status Type Table in future
    my @choices = get_enum_list( $dbc, 'Lane', 'Lane_Status' );

    print alDente::Form::start_alDente_form( $dbc, );
    print hidden( -name => 'GelRun_Request' ) . submit( -name => 'Update Lane Status', -class => "Std" );
    print RGTools::Web_Form::Popup_Menu( name => 'Lane_Status', values => \@choices, default => 'No Comments', width => 120 ) . "<BR>";
    print hidden( -name => "Lane_Number", -value => $lane );
    print hidden( -name => "GelRun",      -value => $gel_plate );
    return 1;
}

####################################################
# Allow uploading band information for a GelRun
# Can read a .sizes file or a file with default fields Well, Band_Size, Band_Intensity
#
# <snip>
# Example:
#
# my $gel_plate = alDente::GelRun->new(-dbc=>$dbc,-plate_id=>$plate);
# my $bands = $gel_plate->get_Bands(-file=>$band_fh, -plate=>$plate);
#
# </snip>
# Return:  An array of bands
####################################################
sub get_Bands {
############################
    my $self        = shift;
    my %args        = &filter_input( \@_ );
    my $file_handle = $args{-file};
    my $plate       = $args{-plate} || $self->{plate_id};

    unless ($file_handle) {
        return 0;
    }
    my @file_contents = ();

    my @fields = ( 'Well', 'Intensity', 'Size' );    # default fields to read in
    if ( $file_handle =~ /\.sizes/i ) {

        my $bands = &_read_sizes( -file => $file_handle, -plate => $plate );    # process .sizes file

        return $bands;
    }

    my $bands = &RGTools::RGIO::Parse_CSV_File( -file_handle => $file_handle, -format => 'AofH', -delimiter => ',' );
    return $bands;
}

###############################
# Create bands for a gel plate based on uploaded Bands file
#
# <snip>
# Example:
#
# my $gel_plate = alDente::GelRun->new(-dbc=>$dbc,-plate_id=>$plate);
# $gel_plate->create_Bands(-file_format=>$file_format);
#
# </snip>
#
# Return:  1 on success
###############################
sub create_Bands {
###############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $file_format  = $args{-file_format}  || $self->value('GelRun_Type');    ## the type of file extension (.sizes, none)
    my $gel_plate_id = $args{-gel_plate_id} || $self->{plate_id};              ## ID
    my $gel          = $self->{id};
    my $thawed_sample = Safe_Thaw( -name => 'Bands', -thaw => 1, -encoded => 1 );    ## Get the Band information

    my @bands_list = Cast_List( -list => $thawed_sample, -to => 'Array' );

    #my ($parent) = $dbc->Table_find('Plate','FKParent_Plate__ID',"WHERE Plate_ID=$self->{plate_id}");
    my @wells = $dbc->Table_find( 'Well_Lookup', 'Plate_96', "WHERE Quadrant = 'a'" );

    my %lane_well;
    for my $band ( 0 .. $#bands_list ) {

        my $prev_well;
        my $curr_well;
        if ( $file_format eq 'Sizing Gel' ) {
            $curr_well = $bands_list[$band]{'Well'};
            $prev_well = $bands_list[ $band - 1 ]{'Well'};
        }
        else {
            $prev_well = $bands_list[ $band - 1 ]{'Oligo well ID'};    # get the previous well
            $curr_well = $bands_list[$band]{'Oligo well ID'}           # current well
        }
        if ( $curr_well eq $prev_well ) {
            next;
        }

        if ( $bands_list[$band]{'PCR plate ID'} eq '$gel_plate_id' ) {
            $lane_well{ $bands_list[$band]{'Well'} } = [ $bands_list[$band]{Lane_Number}, $bands_list[$band]{Size_Estimate} ];
        }
        elsif ( $file_format eq 'Sizing Gel' ) {
            $lane_well{ $bands_list[$band]{'Well'} } = [ $bands_list[$band]{Lane_Number}, $bands_list[$band]{Size_Estimate} ];
        }
    }

    my %lane_info;
    my $index = 1;

    # get the parent plate and sample ancestry

    foreach my $well (@wells) {
        my %ancestry = &alDente::Container::get_Parents( -dbc => $dbc, -id => $self->{plate_id}, -well => $well, -simple => 1 );
        my $sample_id = $ancestry{sample_id};
        my $lane_no;
        my $size_estimate = ' ';
        if ( $file_format eq 'Sizing Gel' ) {
            $lane_no       = $lane_well{$well}[0];
            $size_estimate = $lane_well{$well}[1];
        }
        else {
            $lane_no = $index;
        }

        $lane_info{$index} = [ $gel, $sample_id, $well, $lane_no, $size_estimate ];
        $index++;
    }

    my $ok = $dbc->smart_append( -tables => 'Lane', -fields => [ 'FK_GelRun__ID', 'FK_Sample__ID', 'Well', 'Lane_Number', 'Band_Size_Estimate' ], -values => \%lane_info, -autoquote => 1 );

    # add the Band entries

    my @lanes = $dbc->Table_find( 'Lane', 'Well, Lane_ID', "WHERE FK_GelRun__ID=$gel" );

    my %lane_hash;
    my $well;
    my $lane_id;
    foreach my $lane (@lanes) {
        ( $well, $lane_id ) = split ',', $lane;
        $lane_hash{$well} = $lane_id;
    }
    my %band_info;
    my $band_index = 1;
    my $band_num   = 1;

    for my $band ( 0 .. $#bands_list ) {

        my $prev_well;
        my $curr_well;
        if ( $file_format eq 'Sizing Gel' ) {
            $curr_well = $lane_hash{ &format_well( $bands_list[$band]{'Well'} ) };
            $prev_well = $lane_hash{ &format_well( $bands_list[ $band - 1 ]{'Well'} ) };
        }
        else {
            $prev_well = $lane_hash{ &format_well( $bands_list[ $band - 1 ]{'Oligo well ID'} ) };    # get the previous well
            $curr_well = $lane_hash{ &format_well( $bands_list[$band]{'Oligo well ID'} ) };          # current well
        }

        if ( $curr_well eq $prev_well ) {
            $band_num++;                                                                             # add to the band number if it is the from the same lane
        }
        else {
            $band_num = 1;                                                                           # reset the band number
        }
        if ( $bands_list[$band]{'Size'} && $bands_list[$band]{'PCR plate ID'} eq $gel_plate_id ) {
            $band_info{$band_index} = [ $curr_well, $bands_list[$band]{'Size'}, $bands_list[$band]{'Intensity'}, $band_num ];
            $band_index++;
        }
        elsif ( $file_format eq 'Sizing Gel' ) {
            $band_info{$band_index} = [ $curr_well, $bands_list[$band]{'Size'}, $bands_list[$band]{'Intensity'}, $band_num ];
            $band_index++;
        }
    }

    # create the Bands
    my $ok1 = $dbc->smart_append( -tables => 'Band', -fields => [ 'FK_Lane__ID', 'Band_Size', 'Band_Intensity', 'Band_Number' ], -values => \%band_info, -autoquote => 1 );

    if ($ok1) {
        $dbc->message("Bands added for gel");
        $self->home_page();
    }
    return 1;
}

#############################################
# Confirm the creation of Bands for the GelRun
#
# <snip>
# Example:
#
# my $gel_plate = alDente::GelRun->new(-dbc=>$dbc,-plate_id=>$plate);
# $gel_plate->confirm_create_bands(-bands_list=>\@bands_list, -file_format=>$file_format);
# </snip>
#
# Return 1 on success
#############################################
sub confirm_create_bands {
############################
    my $self        = shift;
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $page        = alDente::Form::start_alDente_form( $dbc, 'confirm_create_bands' );
    my $bands_list  = $args{-bands_list};                                                                              ## a List of band sizes, array reference
    my $plate       = $self->{plate_id};                                                                               ## the plate ID of the GelRun
    my $file_format = $self->value('GelRun_Type');                                                                     ## Type of file format

    my @bands_list  = Cast_List( -list => $bands_list, -to => 'Array' );
    my $band_table  = HTML_Table->new();
    my @band_header = ();
    my @picked_bands;
    if ( $file_format eq 'Sizing Gel' ) {
        @band_header = ( 'Lane Number', 'Source Well', 'Band Size', 'Size Estimate' );

    }
    else {
        @band_header = ( 'Source Well', 'Band Size', 'Band Intensity' );
    }
    $band_table->Set_Title("Bands File");
    $band_table->Set_Class('small');
    $band_table->Set_Border(1);
    $band_table->Set_Headers( \@band_header );

    for my $band ( 0 .. $#bands_list ) {
        if ( $file_format eq 'Sizing Gel' ) {
            $band_table->Set_Row( [ $bands_list[$band]{'Lane_Number'}, $bands_list[$band]{'Well'}, $bands_list[$band]{'Size'}, $bands_list[$band]{'Size_Estimate'} ] );
        }
        else {

            if ( $bands_list[$band]{'PCR plate ID'} eq $plate && $bands_list[$band]{'Size'} ) {
                $band_table->Set_Row( [ $bands_list[$band]{'Oligo well ID'}, $bands_list[$band]{'Size'}, $bands_list[$band]{'Intensity'} ] );

            }
            else {

                #splice(@bands_list, $bands_list[$band], 1);
            }

        }
    }

    $band_table->Printout();

    # Display the confirmation
    $page .= "<BR>Are you sure you want to upload the Band file? <BR>";
    $page .= submit( -name => 'Upload Band file', -class => "Std" );
    $page .= hidden( -name => 'plate_id', -value => $plate ) . hidden( -name => 'GelRun_Request' );
    $page .= hidden( -name => 'GelRun',      -value => $self->{id} );
    $page .= hidden( -name => 'File Format', -value => $file_format );
    my $frozen_sample = Safe_Freeze( -name => "Bands", -value => \@bands_list, -format => 'hidden', -encode => 1 );
    $page .= $frozen_sample . end_form();
    return $page;
}

#################################################################
# Allow the user to pick from Bands on the gel to another plate
#
# <snip>
# Example:
#
# my $gel_plate = alDente::GelRun->new(-dbc=>$dbc,-plate_id=>$plate);
# $gel_plate->confirm_pick_bands(-plate_format=>$plate_format,-plate_content=>$plate_contents, -rack_id =>$rack_id);
# </snip>
# Return: 1 on success
#################################################################
sub confirm_pick_bands {
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    #### Check if a plate is scanned in

    my $target_plate_id = $args{-target_plate_id};    ### target plate exists already

    ### Create a new plate

    my $plate_format   = $args{-plate_format};                                            # New Plate Format
    my $sample_type_id = $args{-sample_type_id};                                          # New Plate Contents
    my $rack_id        = $args{-rack_id};                                                 # New Rack ID
    my $target_library = $args{-library};
    my $pipeline       = $args{-pipeline};
    my %parameters     = _alDente_URL_Parameters( -dbc => $dbc, -type => 'gel_plate' );
    print alDente::Form::start_alDente_form( $dbc, 'gel_plate', undef, \%parameters );

    my $format_id;

    my $target_plate_title;
    my @used_wells;
    if ($target_plate_id) {
        ($format_id) = $dbc->Table_find( 'Plate', 'FK_Plate_Format__ID', "WHERE Plate_ID = $target_plate_id" );
        $target_plate_title = get_FK_info( $dbc, 'FK_Plate__ID', $target_plate_id );
        print hidden( -name => 'Existing_Plate', -value => $target_plate_id );
        @used_wells = $dbc->Table_find( 'Sample, Plate_Sample', 'Well', "WHERE FKParent_Sample__ID !=0 and Sample_ID=FK_Sample__ID and Plate_Sample.FKOriginal_Plate__ID=$target_plate_id" );
    }
    else {
        print "New plate format: $plate_format<BR>";
        print "Plate Contents:   Sample_Type_ID $sample_type_id<BR>";
        print "Target Library:   $target_library<BR>";
        $format_id = get_FK_ID( $dbc, 'FK_Plate_Format__ID', $plate_format );
        $target_plate_title = "Target Plate";
    }
    my @lane_bands = Cast_List( -list => $self->{lane_info}, -to => 'Array' );

    my $get_checked = "check_all_boxes(document.gel_plate, document.gel_plate.Num_Wells, 'Band', 'Toggle_Rows');set_Band(document.gel_plate,document.gel_plate.TargetText,'Toggle_Rows');";
    my $fill_link = "Select all<br>" . checkbox( -name => "Toggle_Rows", -label => '', -onClick => $get_checked );

    #print $q->header("text/html");

    my $last_letter = "H";
    my $last_num    = 12;
    my $height      = 300;
    my $width       = 450;

    my ($size) = $dbc->Table_find( 'Plate_Format', 'Wells', "WHERE Plate_Format_ID=$format_id" );

    if ( $size =~ /384/ ) { $last_letter = "P"; $last_num = 24; $height *= 2; $width *= 2; }
    my $label_colour = "yellow";
    my $target_plate = HTML_Table->new();

    $target_plate->Set_Title("<B>$target_plate_title</B>");
    $target_plate->Set_Width('450');
    $target_plate->Set_Class('small');
    $target_plate->Set_Border(1);

    foreach my $col ( 0 .. $last_num ) {
        my $col_list = join ',', map { $_ . $col } ( 'A' .. $last_letter );

        if ($col) {
            $target_plate->Set_Column( ["$col "] );
            $target_plate->Set_Column_Colour( $col + 1, $label_colour );
        }
        else {
            $target_plate->Set_Column( [""] );
            $target_plate->Set_Column_Colour( $col + 1, $label_colour );
        }
    }
    my @input_targets = param('TargetText');
    my $row_index     = 2;
    my $index         = 0;

    #### IF an existing plate disable the wells that have bands associated to them

    my $num_filled_wells = scalar(@used_wells);

    foreach my $row ( 'A' .. $last_letter ) {

        my @textboxes = ();
        $target_plate->Set_Column_Colour( 1, $label_colour );

        foreach my $col ( 1 .. $last_num ) {

            my $default = $input_targets[$index] if $#input_targets >= $index;
            ##  translate row and column to well
            my $well = format_well("$row$col");
            ##  check if the well is already filled
            if ( grep /^$well$/, @used_wells ) {
                push( @textboxes, textfield( -name => "Filled", -value => $default, -size => 4, -disabled => 1, -style => 'background-color:grey' ) );

                # push (@textboxes, textfield(-name=>"TargetText",-value=>'',-force=>1,-size=>4));
            }
            else {
                print hidden( -name => 'Target_Well', -value => "$well" );
                push( @textboxes, textfield( -name => "TargetText", -value => $default, -force => 1, -size => 4 ) );
            }
            $index++;
        }
        $target_plate->Set_Row( [ "$row", @textboxes ] );
        $row_index++;
    }
    $target_plate->Set_Column_Colour( 1, $label_colour );

    my $pick_band_table = HTML_Table->new();
    my @band_header = ( 'Band ID', 'Source Well', 'Lane', 'Band Number', 'Band Size', 'Band Intensity', $fill_link );
    $pick_band_table->Set_Title("Pick Bands");
    $pick_band_table->Set_Class('small');
    $pick_band_table->Set_Border(1);
    $pick_band_table->Set_Row( \@band_header );
    $pick_band_table->Set_Row_Colour( 1, 'lightgreen' );
    $pick_band_table->Toggle_Colour_on_Column(2);
    my $i = 1;

    foreach my $row ( sort @lane_bands ) {
        my ( $band_id, $well, $lane_no, $band_no, $band_size, $band_intensity, $sample_id ) = split ',', $row;

        unless ($band_intensity) {
            $band_intensity = "&nbsp";
        }
        $pick_band_table->Set_Row(
            [   $band_id, $well, $lane_no, $band_no,
                $band_size,
                $band_intensity,
                checkbox(
                    -name    => "Band",
                    -value   => "$band_id",
                    -label   => "",
                    -onClick => "num_check_box(document.gel_plate, document.gel_plate.Num_Wells, 'Band', 'Toggle_Rows',$num_filled_wells);set_Band(document.gel_plate,document.gel_plate.TargetText,'Toggle_Rows')"
                )
            ]
        );
        $i++;
    }

    $target_plate->Printout();
    print hidden( -name => 'Num_Filled_Wells', -value => $num_filled_wells ) . hidden( -name => 'GelRun_Request' );
    print "Number of wells filled:" . textfield( -name => 'Num_Wells', -value => $num_filled_wells, -size => 12, -onClick => "" ) . "<BR>";

    print submit( -name => 'Extract Bands', -style => "background-color:lightgreen" ) . hspace(10);
    print submit( -name => 'Preview GelRun Extraction', -style => "background-color:lightgreen", -onClick => "this.form.target='_blank';return true;" );
    print hidden( -name => 'Existing_Plate', -value => $target_plate_id );
    print hidden( -name => 'GelRun',         -value => $self->{id} );
    print hidden( -name => 'Plate_Format',   -value => $plate_format );
    print hidden( -name => 'Sample Type ID', -value => $sample_type_id );
    print hidden( -name => 'Target_Rack',    -value => $rack_id );
    print hidden( -name => 'Target_Library', -value => $target_library );
    print hidden( -name => 'Pipeline',       -value => $pipeline );
    $pick_band_table->Printout();
    print end_form();
    return 1;
}

###############################################
# Extract the bands onto a new original plate
#
# <snip>
# Example:
#
# my $gel_plate = alDente::GelRun->new(-dbc=>$dbc,-plate_id=>$plate_id);
# $gel_plate->extract_Bands(-bands=>\@bands,-plate_contents=>$plate_contents, -plate_format=>$plate_format, -rack_id=> $rack_id);
# </snip>
#
# Return: 1 on success
###############################################
sub extract_Bands {
#####################
    my $self             = shift;
    my %args             = &filter_input( \@_ );
    my $dbc              = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_format     = $args{-plate_format};                                                            # New Plate Format
    my $sample_type_id   = $args{-sample_type_id};                                                          # New Plate Contents
    my $picked_bands     = $args{-bands};                                                                   # Bands picked for extraction
    my $plate_id         = $self->{plate_id};                                                               # Plate ID of the GelRun
    my $rack_id          = $args{-rack_id};                                                                 # New Rack ID
    my $library          = $args{-target_library};                                                          # New Library Name
    my $pipeline         = $args{-pipeline};
    my $existing_plate   = $args{-existing_plate};
    my $target_wells     = $args{-wells};
    my $target_well_list = Cast_List( -list => $target_wells, -to => 'String', -autoquote => 1 );
    my @target_wells     = Cast_List( -list => $target_wells, -to => 'Array' );
    my $format_id;
    my $plate_application;                                                                                  ## REMOVED ##
    my $user_id = $dbc->get_local('user_id');

    if ($existing_plate) {
        ($format_id) = $dbc->Table_find( 'Plate', 'FK_Plate_Format__ID', "WHERE Plate_ID = $existing_plate" );
        unless ($sample_type_id) {
            ($sample_type_id) = $dbc->Table_find( 'Plate', 'FK_Sample_Type__ID', "WHERE Plate_ID = $existing_plate" );
        }

        #$target_plate_title = get_FK_info($self->{dbc}, 'FK_Plate__ID', $target_plate_id);
        #print hidden(-name=>'Existing_Plate', -value=>$target_plate_id);
        my ($library) = $dbc->Table_find( 'Plate', "FK_Library__Name", "where Plate_ID = $plate_id" );
    }
    else {
        $format_id = get_FK_ID( $dbc, 'FK_Plate_Format__ID', $plate_format );
    }

    my @picked_bands = Cast_List( -list => $picked_bands, -to => 'Array' );

    my ($plate_size) = $dbc->Table_find( 'Plate_Format', 'Wells', "WHERE Plate_Format_ID=$format_id" );

    ### Error Check :  Bands picked cannot be < 1 or > the plate size
    if ( $plate_size < scalar(@picked_bands) || scalar(@picked_bands) <= 0 ) {
        $dbc->warning("Number of picked bands must be greater than 0 and less than $plate_size");

        #print alDente::Form::start_alDente_form($dbc,);
        my @lane_bands = $dbc->Table_find( 'GelRun,Lane,Band', 'Band_ID,Well,Lane_Number,Band_Number,Band_Size,Band_Intensity,FK_Sample__ID', "WHERE FK_Plate__ID=$plate_id and GelRun_ID = FK_GelRun__ID and Band.FK_Lane__ID =Lane.Lane_ID" );

        $self->confirm_pick_bands( -target_plate_id => $existing_plate, -plate_format => $plate_format, -sample_type_id => $sample_type_id, -rack_id => $rack_id, -lane_bands => \@lane_bands );
        return 0;
    }
    print alDente::Form::start_alDente_form( $dbc, );

    my $band_id_list = join ',', @picked_bands;

    #  Determine the sample type to be created

    my $target_plate_id = $existing_plate;
    my @target_plate_wells;
    my $rearray = alDente::ReArray->new( -dbc => $dbc );
    my @source_wells = ();
    my $band_index;
    foreach my $band (@picked_bands) {
        if ($band) {
            my ($source_well) = $dbc->Table_find( 'GelRun,Run,Lane,Band', 'Well', "WHERE FK_Run__ID = Run_ID and FK_Plate__ID=$plate_id and GelRun_ID = FK_GelRun__ID and Band.FK_Lane__ID =Lane.Lane_ID and Band_ID in ($band)" );
            push( @source_wells,       $source_well );
            push( @target_plate_wells, $target_wells[$band_index] );
        }
        $band_index++;
    }
    my @source_plates = ($plate_id) x scalar(@source_wells);

    my $type             = 'Extraction Rearray';
    my $status           = 'Completed';
    my $target_size      = $plate_size;
    my $rearray_comments = "Extraction";
    my $rearray_request;
    my $target_plate;
    my $sample_type;
    if ($sample_type_id) {
        $sample_type = $sample_type_id;
        ($sample_type_id) = $dbc->get_FK_ID( -field => 'FK_Sample_Type__ID', -value => $sample_type );
    }

    ### Create the rearray records for the extraction
    if ($existing_plate) {
        ( $rearray_request, $target_plate ) = $rearray->create_rearray(
            -source_plates    => \@source_plates,
            -source_wells     => \@source_wells,
            -target_wells     => \@target_plate_wells,
            -target_plate_id  => $existing_plate,
            -employee         => $user_id,
            -request_type     => $type,
            -status           => $status,
            -target_size      => $target_size,
            -rearray_comments => $rearray_comments,
            -target_library   => $library,
            -plate_format     => $format_id,
            -sample_type_id   => $sample_type_id,
            -plate_status     => 'Active',
            -create_plate     => 0,
            -plate_class      => 'ReArray',
        );
    }
    else {
        my $create_plate = 1;

        ( $rearray_request, $target_plate ) = $rearray->create_rearray(
            -pipeline         => $pipeline,
            -source_plates    => \@source_plates,
            -source_wells     => \@source_wells,
            -target_wells     => \@target_plate_wells,
            -employee         => $user_id,
            -request_type     => $type,
            -status           => $status,
            -target_size      => $target_size,
            -create_plate     => $sample_type,
            -rearray_comments => $rearray_comments,
            -target_library   => $library,
            -plate_format     => $format_id,
            -sample_type_id   => $sample_type_id,
            -plate_status     => 'Active',
            -target_rack      => $rack_id,
            -plate_class      => 'ReArray',
        );

    }

    #my $sample_info = $rearray->create_sample( -request_id => $rearray_request, -sample_type => 'Extraction' );
    my $Sample = alDente::Sample::create_samples( -dbc => $dbc, -plate_id => $target_plate, -from_rearray_request => $rearray_request, -type => 'Extraction' );
    my @rearrays = $dbc->Table_find( 'ReArray', 'ReArray_ID', "WHERE FK_ReArray_Request__ID = $rearray_request" );
    my ($attribute) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name='ReArray_FK_Band__ID'" );
    my $rearray_index = 0;
    my %extracted_bands;
    my @rearray_attr_fields = ( 'FK_Attribute__ID', 'FK_ReArray__ID', 'Attribute_Value' );

    foreach my $rearray (@rearrays) {
        $extracted_bands{ $rearray_index + 1 } = [ $attribute, $rearray, $picked_bands[$rearray_index] ];
        $rearray_index++;
    }

    ### add the band attributes to the rearray
    my $ok = $dbc->smart_append( -tables => 'ReArray_Attribute', -fields => \@rearray_attr_fields, -values => \%extracted_bands, -autoquote => 1 );

    my $home_barcode = "PLA$target_plate";
    if ($home_barcode) {
        unless ($existing_plate) {
            &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $target_plate );
        }
        &alDente::Info::info( $dbc, $home_barcode );
    }
    print end_form();
    return 1;
}

# Allow the user to preview the gel extraction information (from gel to extracted plate)  before creating the plate
# <snip>
# Example:
#     my $gel_plate = alDente::GelRun->new(-dbc=>$dbc,-id=>$gel);
#     my $display_info = $gel_plate->display_gel_extraction(-target_wells=>\@target_wells, -bands=>\@bands);
#     display_info->Printout();
# </snip>
# Return:  HTML Table
################################
sub display_gel_extraction {
################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $target_wells = $args{-target_wells};    ## Target wells to be filled on the target extraction plate
    my $bands        = $args{-bands};           ## Bands to be picked on to the the target extraction plate

    my @target_wells = Cast_List( -list => $target_wells, -to => 'Array' );
    my @bands_list   = Cast_List( -list => $bands,        -to => 'Array' );

    ## find out the source plate given the band ID from the Lane info
    ## Create the gel extraction table
    my $gel_extraction_info = HTML_Table->new();
    $gel_extraction_info->Set_Title("Preview GelRun Extraction");
    $gel_extraction_info->Set_Class('small');
    $gel_extraction_info->Set_Border(1);
    ## Display a list for each well the band, source plate, source well and the target well that it is going into
    my @gel_extraction_headers = ( 'Source Plate', 'Source Well', 'Band', 'Size', 'Intensity', 'Target Well' );
    $gel_extraction_info->Set_Headers( \@gel_extraction_headers );
    my $index = 0;
    ##  For each of the target plate wellls...
    foreach my $well (@target_wells) {
        ## check if the band exists
        if ( $bands_list[$index] ) {
            my @extraction_info
                = $dbc->Table_find( 'Run,GelRun, Lane, Band', 'FK_Plate__ID,Well,Band_ID, Band_Size, Band_Intensity', "WHERE Run.Run_ID  = FK_Run__ID and GelRun_ID = FK_GelRun__ID and FK_Lane__ID = Lane_ID and Band_ID = $bands_list[$index] " );
            my ( $source_plate, $source_well, $band_id, $band_size, $band_intensity ) = split ',', $extraction_info[0];
            $gel_extraction_info->Set_Row( [ $source_plate, $source_well, $band_id, $band_size, $band_intensity, $target_wells[$index] ] );
        }
        $index++;
    }
    return $gel_extraction_info;
}

###################################
# Custom function to add Gel Trays
#
# Gel Trays consist of a single Rack of type 'Rack' and two Racks of type 'Box' whitin it
# The two boxes will be named Top & Bottom and will be marked as non-movable
#
#
#################
sub add_geltray {
#################
    my %args = &filter_input( \@_, -args => 'dbc,count', -mandatory => 'dbc,count' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $count = $args{-count};

    if ($count) {
        my ($storage_id) = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
            'Equipment_ID', "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Category='Storage'" );

        unless ($storage_id) {
            Message("Error: Can not find an storage equipment in the system");
            return 0;
        }

        my $avail = &alDente::Rack::_get_available_names( -equ_id => $storage_id, -list => [ ('Rack') x $count ] );

        unless ($avail) {
            Message("Error: Failed");
            return 0;
        }

        my @newracks;
        for my $i ( 1 .. $count ) {
            my $parent = $dbc->smart_append(
                -table     => 'Rack',
                -fields    => [ 'Rack_Type', 'FK_Equipment__ID', 'Rack_Name', 'Movable', 'FKParent_Rack__ID' ],
                -values    => [ 'Rack', $storage_id, $avail->{Rack}[ $i - 1 ], 'Y', 0 ],
                -autoquote => 1
            );

            my $parent_id = $parent->{Rack}{newids}[0];

            my $childs = $dbc->smart_append(
                -table  => 'Rack',
                -fields => [ 'Rack_Type', 'FK_Equipment__ID', 'Rack_Name', 'Movable', 'FKParent_Rack__ID' ],
                -values => {
                    1 => [ 'Box', $storage_id, 'Top',    'N', $parent_id ],
                    2 => [ 'Box', $storage_id, 'Bottom', 'N', $parent_id ]
                },
                -autoquote => 1
            );
            push( @newracks, $parent_id, @{ $childs->{Rack}{newids} } );
        }

        foreach (@newracks) {
            &alDente::Barcoding::PrintBarcode( $dbc, 'Rack', $_ );
        }
    }
    else {
        Message("Warning: Unknown number of new Gel Trays requested.");
    }
}

##############################
#
#  Method to create bands for already existing gel runs and lanes.
#
#  %bands = (
#               'run_id' => {
#                         'lane' => {
#                                    'mobilities' => [mobilities_array],
#                                    'sizes' = [sizes_array]
#                                  }
#               },
#
#
#
##############################
sub update_gel_bands {
##############################
    my %args = &filter_input( \@_, -args => 'dbc,bands', -mandatory => 'bands' );

    my $dbc   = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $force = $args{-force};
    my $quiet = $args{-quiet};
    my %bands = %{ $args{-bands} };

    my @run_ids = keys %bands;
    my $run_ids_list = join( ',', @run_ids );

    my %Gel_Info = $dbc->Table_retrieve( 'Run,GelRun,Lane', [ 'Run_ID', 'Lane_ID', 'Lane_Number' ], "WHERE Run_ID IN ($run_ids_list) AND FK_Run__ID=Run_ID AND FK_GelRun__ID=GelRun_ID" );

    unless (%Gel_Info) {
        Message("Error: Incomplete or invalid Gel Runs.") unless $quiet;
        return 0;
    }
    ### Check to see whether all the runs requested have their Lane entries created
    my @existing_gel_lanes = @{ RGTools::RGIO::unique_items( $Gel_Info{Run_ID} ) };
    if ( int(@existing_gel_lanes) != int(@run_ids) ) {
        Message("Error: Incomplete or invalid Gel Runs.") unless $quiet;
        return 0;
    }

    ### Check to see whether any band information is already present
    my $existing_lanes = join( ',', @{ $Gel_Info{Lane_ID} } );
    my @existing_bands = $dbc->Table_find( 'Band', 'Band_ID', "WHERE FK_Lane__ID IN ($existing_lanes)" );

    if (@existing_bands) {
        if ($force) {
            my $existing_band_ids = join( ',', @existing_bands );
            my $ok = $dbc->delete_records( 'Band', 'Band_ID', -id_list => $existing_band_ids, -quiet => $quiet );
            if ($ok) { Message("Deleted $ok Band entries") unless $quiet }
        }
        else {
            Message("Error: Some Bands have already been created. Please use 'force' option to overwrite all band information.") unless $quiet;
            return 0;
        }
    }

    my %Gel_Details;
    my $index = -1;
    while ( $Gel_Info{Run_ID}[ ++$index ] ) {
        $Gel_Details{ $Gel_Info{Run_ID}[$index] }{ $Gel_Info{Lane_Number}[$index] } = $Gel_Info{Lane_ID}[$index];
    }

    my %band_values;
    my @band_fields = qw(Band_Size Band_Mobility Band_Number FK_Lane__ID Band_Type);
    my $band_index  = 0;

    foreach my $gel_id ( keys %bands ) {
        foreach my $lane_number ( keys %{ $bands{$gel_id} } ) {
            my $lane_id = $Gel_Details{$gel_id}{$lane_number};
            unless ( $lane_id or $bands{$gel_id}{$lane_number}{mobilities} or $bands{$gel_id}{$lane_number}{sizes} ) {
                Message("Warning: Invalid data for Lane $lane_number of Run $gel_id") unless $quiet;
                next;
            }

            my @mobs  = @{ $bands{$gel_id}{$lane_number}{mobilities} };
            my @sizes = @{ $bands{$gel_id}{$lane_number}{sizes} };

            unless ( int(@mobs) == int(@sizes) ) {
                Message("Error: Count of mobilities and sizes do not match for Lane $lane_number of Run $gel_id") unless $quiet;
                next;
            }

            my $band_count;
            for ( $band_count = 0; $band_count < int(@mobs); $band_count++ ) {
                $band_values{ ++$band_index } = [ $sizes[$band_count], $mobs[$band_count], $band_count + 1, $lane_id, 'Insert' ];
            }

            my $total_sizes = &RGmath::get_sum( -values => $bands{$gel_id}{$lane_number}{sizes} );
            $dbc->Table_update_array( 'Lane', [ 'Bands_Count', 'Band_Size_Estimate' ], [ $band_count, $total_sizes ], "WHERE Lane_ID=$lane_id", -autoquote => 1 );
        }
    }
    my $b = $dbc->smart_append( -tables => 'Band', -fields => \@band_fields, -values => \%band_values, -autoquote => 1 );
    return $b;

}

################################
#
#
#########################
sub move_geltray_to_equ {
#########################
    my %args = &filter_input( \@_, -args => 'dbc,rack_id,equ_id' );

    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $rack_id = $args{-rack_id};
    my $equ_id  = $args{-equ_id};

    my %rack_info = $dbc->Table_retrieve( 'Rack', [ 'FK_Equipment__ID', 'FKParent_Rack__ID AS Parent', 'Movable', 'Rack_Type' ], "WHERE Rack_ID=$rack_id" );

    if ( $rack_info{FK_Equipment__ID}[0] eq $equ_id ) {
        return 1;
    }
    elsif ( $rack_info{Movable}[0] eq 'N' ) {
        &move_geltray_to_equ( $dbc, $rack_info{Parent}[0], $equ_id );
    }
    else {
        my $type = $rack_info{Rack_Type}[0];
        my $names = &alDente::Rack::_get_available_names( -dbc => $dbc, -equ_id => $equ_id, -list => [$type] );
        &alDente::Rack::Move_Racks( -dbc => $dbc, -source_racks => $rack_id, -equip => $equ_id, -confirmed => 1, -new_names => { $rack_id => $names->{$type}[0] }, -no_print => 1 );
    }
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

###############################################################
# Get the size of the vector associated with the library plate
# <snip>
#
# Example:
#
# my $vector_size = _get_Vector_Size(-plate=>$plate);
# </snip>
#
# Return: Size of the Vector
###############################################################
sub _get_Vector_Size {
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate = $args{-plate};                                                                   ## Plate ID of the Library Plate

    #my $vector_size = `cat /home/aldente/public/VECTOR/$vector_file | grep -v ">" | fold -1 | grep -v \"/\s\" | wc -w`;
    my ($vector_file) = $dbc->Table_find(
        'Vector, Vector_Type,LibraryVector,Plate',
        'Vector_Type.Vector_Sequence_File',
        "where LibraryVector.FK_Vector__ID = Vector_ID and Vector_Type_ID = Vector.FK_Vector_Type__ID and Plate.FK_Library__Name = LibraryVector.FK_Library__Name and Plate_ID = $plate"
    );
    my ($vector_size) = split "\n", try_system_command(qq{cat /home/sequence/VECTOR/$vector_file | grep -v \> | fold -1 | grep -v ^$ | wc -w});
    return $vector_size;
}
###############################################################
# Lane and Well Mapping for .sizes file
# <snip>
#
# Example:
#
# my ($well,$lane_no) = _Lane121Lookup($bands{$band}{clone});
# </snip>
# Return: Well and corresponding Lane Number
###############################################################
sub _Lane121Lookup {

    # this is the 'clone' number in the pla_number.sizes file -- not really the actual lane in the gel
    # returns the lane number from the gel and the associated 96-well id
    my $clone = shift;
    my $m     = int( $clone / 4 );
    my $s     = $clone - 4 * $m;

    # get the lane number
    my $lane = $clone + $m;
    if ( $s == 0 ) {
        $lane--;
    }
    my ( $col, $row );

    if ( $clone < 49 ) {
        if ( $s == 1 ) {
            $row = "A";
            $col = $m + 1;
        }
        elsif ( $s == 2 ) {
            $row = "B";
            $col = $m + 1;
        }
        elsif ( $s == 3 ) {
            $row = "C";
            $col = $m + 1;
        }
        elsif ( $s == 0 ) {
            $row = "D";
            $col = $m;
        }
    }
    elsif ( $clone > 48 ) {
        if ( $s == 1 ) {
            $row = "E";
            $col = $m + 1 - 12;
        }
        elsif ( $s == 2 ) {
            $row = "F";
            $col = $m + 1 - 12;
        }
        elsif ( $s == 3 ) {
            $row = "G";
            $col = $m + 1 - 12;
        }
        elsif ( $s == 0 ) {
            $row = "H";
            $col = $m - 12;
        }
    }

    $col = sprintf "%.2d", $col;
    my $well = $row . $col;
    return $well, $lane;
}

#######################
# Parse a .SIZES file
# <snip>
# Example:
#
# my $bands = &_read_sizes(-file=>$file_handle, -plate=>$plate); # process .sizes file
# </snip>
# Return: an array of Band sizes
#######################
sub _read_sizes {
#####################################
    my %args = &filter_input( \@_ );

    my $file  = $args{-file};     ## file handle of the .sizes file
    my $plate = $args{-plate};    ## the Plate ID of the gel
    my $SIZES = $file;
    my @clones;
    my %bands;
    my $clone_no;
    my $c = 1;

    my $band_no = 1;
    while (<$SIZES>) {

        if ( $_ =~ m/([0-9]+)\s([0-9]+)\s([0-9]+)\-?\d?$/ ) {
            $clone_no = $c;
            $c++;

        }
        else {

            $_ =~ m/^([0-9]+)/;
            my $size = chomp_edge_whitespace($1);
            if ($size) {
                $clones[ $clone_no - 1 ] += $size;

                #store the bands in a hash
                $bands{$band_no} = { clone => $clone_no, band_size => $size };

                #print "band no: $band_no values : \$bands{$band_no} " . "<BR>";
                $band_no++;
            }
        }
    }

    my @sizes = ();

    my $vector_size = _get_Vector_Size( -plate => $plate );    # get the vector size

    foreach my $band ( sort { $a <=> $b } keys %bands ) {
        my ( $well, $lane_no );
        ( $well, $lane_no ) = _Lane121Lookup( $bands{$band}{clone} );

        my $size_estimate = $clones[ $bands{$band}{clone} - 1 ] - $vector_size;
        if ( $size_estimate < 0 ) { $size_estimate = 0; }

        $sizes[ $band - 1 ] = { Well => $well, Lane_Number => $lane_no, Clone => $bands{$band}{clone}, Size => $bands{$band}{band_size}, Size_Estimate => $size_estimate };
    }
    return \@sizes;
}

####################
#
#
##################
sub _gel_started {
##################
    my %args = &filter_input( \@_, -args => 'gelruns' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $gelruns = Cast_List( -list => $args{-gelruns}, -to => 'string' );
    my @gels = $dbc->Table_find( 'GelRun,Run', 'FK_Plate__ID', "WHERE Run_ID=FK_Run__ID AND Run_ID IN ($gelruns) AND FK_Plate__ID IS NOT NULL" );

    if (@gels) {
        return 1;
    }
    else {
        return 0;
    }
}

####################
# Ensures whether the given Rack does not have any 'Initiated' nor 'In Process' Gel Runs on it
#
##################
sub _gelrack_available {
##################

    my $dbc     = shift;
    my $rack_id = shift;
    my $count   = join ',', $dbc->Table_find( 'Run,GelRun', 'Run_ID', "WHERE Run_ID=FK_Run__ID AND Run_Type='GelRun' AND Run_Status IN ('Initiated','In Process') AND FKPosition_Rack__ID=$rack_id" );
    return $count ? 0 : 1;
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

$Id: GelRun.pm,v 1.6 2004/11/30 17:19:21 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
