################################################################################
#
# Info.pm
#
# This modules provides general info retrieving functions specific to the SeqDB
#
################################################################################
################################################################################
# $Id: Info.pm,v 1.64 2004/12/06 22:02:36 echuah Exp $
################################################################################
# CVS Revision: $Revision: 1.64 $
#     CVS Date: $Date: 2004/12/06 22:02:36 $
################################################################################
package alDente::Info;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>
  
Info.pm - This modules provides general info retrieving functions specific to the SeqDB

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This modules provides general info retrieving functions specific to the SeqDB<BR>

=cut

##############################
# superclasses               #
##############################
use Benchmark;

use base Exporter;

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    GoHome
    Default_Home
    info
    contact_info
    organization_info
    user_info
    table_info
    add_suggestion
    list_suggestions

);
@EXPORT_OK = qw(
    GoHome
    Default_Home
    info
    contact_info
    organization_info
    user_info
    table_info
    add_suggestion
    list_suggestions

);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
# use Test::Simple no_plan;

use alDente::Misc_Item;
use alDente::Form;
use alDente::SDB_Defaults;    ## Temp_dir
use alDente::Contact;
use alDente::Container;
use alDente::Library_Plate;
use alDente::Tube;
use alDente::Employee;
use alDente::Solution;
use alDente::Library;
use Sequencing::Sequencing_Library;
use alDente::RNA_DNA_Collection;
use alDente::Project;
use alDente::Equipment;
use alDente::Box;
use alDente::Source;
use alDente::Original_Source;
use alDente::Chemistry;
use alDente::Inventory;
use alDente::GelRun;
use alDente::Issue;
use alDente::Tray_Views;
use alDente::Protocol_Views;

use SDB::DB_Form_Viewer;    ## view_records
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;    ## basic defaults...
use SDB::DB_Object;
use RGTools::RGIO;
use SDB::HTML;              ## Message
use RGTools::Views;
use alDente::View;

##############################
# global_vars                #
##############################
use vars qw($user $dbc $dbase $scanner_mode);
use vars qw($equipment_id $equipment $solution_id);
use vars qw($URL_temp_dir %Field_Info);
use vars qw(%Settings %Primary_fields);
use vars qw($session_id $Sess);
use vars qw($Connection $Current_Department);

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

#################
sub GoHome {
#################
    my %args = &filter_input( \@_, -args => 'dbc,table,id', -mandatory => 'table' );
    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table  = $args{-table};
    my $list   = $args{-list};
    my $id     = $args{-id};
    my $name   = $args{-name};
    my $number = $args{-number};
    my $force  = $args{-force};                                                                   ## overrides current home_page if it exists by default.

    my $Sess = $dbc->session();                                                                   ## avoid using global...

    $dbc->Benchmark('GoHome');

    my @upgraded = qw(Source Employee Plate Original_Source Solution Equipment Library Shipment);                                                           
    ## gradually increase this list if possible to include ALL objects... and then phase out messy section below this block ....
    
    $dbc->debug_message("Deprecate use of GoHome for $table.");
        
    if ( grep /^$table$/, @upgraded ) {

        ## Note: This is intended to be moved to a simple block in MVC to enable HomePage parameters to trigger run modes directly
        ##       This block remains here for purposes of transparency and to maintain logic flow consistency temporarily since all other home pages are currently directed through here
        ##
        ##       Once the logic below this block is fully phased out by upgrading the home page generation for all classes requiring customization, the entire method should be removed and this short block installed within the MVC logic.
        ##
        ## This is the much simplified process for navigating to object home pages ##
        ##
        ## This should generate a default home_page for objects without any defined home pages ##
        ##
        ## Required:  MVC modules ( modules should use base alDente::Object MVC modules - especially the View module)
        ##
        ## To customize specific object home pages, include in the Object_Views module the following (optional) methods :
        ##   * single_record_page  ( returns hash including keys for: layers, label, options, details, record - see SDB::DB_Object_Views::std_home_page for default layouts)
        ##   * multiple_record_page ( returns hash including keys for: layers, label ) - used when multiple objects are scanned at one time
        ##   * generic_page ( returns hash including keys for: layers, label ) - used for standard pages not referencing a particular record
        ##
        ## Add new objects to list of upgraded tables to test and redirect logic through this block ##

        ## Use standard Object_App 'Home Page' run mode to generate home page ##
        eval "require alDente::Object_App";
        my $webapp = alDente::Object_App->new( PARAMS => { dbc => $dbc } );
        my $page = $webapp->run();

        return $page;
    }

    ########################################
    ## Section below should be phased out ##
    ########################################

    ## substitute if required..
    if ( $table eq 'Plate' ) {
        $table = 'Container';
    }
    if ( $table eq 'Tray' ) {

        print alDente::Tray_Views::tray_header( -dbc => $dbc, -tray_id => $id );
        ## convert tray to container home page... ##
        $table = 'Container';
        $id = join ',', $dbc->Table_find( 'Plate_Tray', 'FK_Plate__ID', "WHERE FK_Tray__ID IN ($id)" );
    }

##     require Illumina::Flowcell;  ### This cannot be here ... !!!

    my $verbose = param('Verbose');

    #
    # The various options below represent different ways in which home pages have been generated in the past
    #
    # the primary options are:
    #
    # 1 (preferred option) -if object is in @aldente_views;
    # - going directly to <object>_Views::home_page or <object>_Views::list_page
    #

    my @aldente_home_pages = ( 'Library', 'Project', 'UseCase' );

    ## preferred method - via App... #
    my @std_home_pages = (
        'Rack',               'Stock',            'Box',               'Solution',   'Container', 'Tube',        'Library_Plate', 'Array',            'Sample_Request',    'Source',
        'Original_Source',    'Sample',           'Extraction_Sample', 'GelRun',     'Issue',     'WorkPackage', 'Inventory',     'Prep',             'SolexaRun',         'Contact',
        'Illumina::Flowcell', 'Rn',               'Pipeline',          'Microarray', 'QC_Batch',  'Funding',     'Shipment',      'Patient::Patient', 'Submission_Volume', 'Invoice',
        'Employee',           'Invoiceable_Work', 'Contact',           'Employee',   'Process_Deviation',
    );

    if ( $id && $table =~ /Standard Page/ && param('OpenTab') ) {
        my $open_tab = param('OpenTab') if param('OpenTab');

        return &alDente::Web::GoHome( $dbc, $Current_Department, $open_tab );
    }
    elsif ( $id && $table =~ /Standard Page/ ) {
        my $ok = &standard_page( $id, %args ) if $id;

        return $ok;
    }
    elsif ( $id && $table =~ /Department/ ) {
        $Current_Department = get_FK_info( $dbc, 'FK_Department__ID', $id );
        my $open_tab = param('OpenTab') if param('OpenTab');

        return &alDente::Web::GoHome( $dbc, $Current_Department, $open_tab );
    }
    elsif ( param('OpenTab') ) {
        my $open_tab = param('OpenTab') if param('OpenTab');

        return &alDente::Web::GoHome( $dbc, $Current_Department, $open_tab );
    }

    if ( grep /^$table$/, @aldente_home_pages ) {
        $Sess->homepage( "$table=" . $id );
        $table = "alDente::$table";
        my $object = $table->new(
            -dbc  => $dbc,
            -id   => $id,
            -name => $name,
        );

        $object->home_info(
            -brief   => $scanner_mode,
            -verbose => $verbose
        );

        return 1;
    }
    elsif ( ( my ($page) = grep /\b$table\b/, @std_home_pages ) ) {
        my $directory = 'alDente';
        if ( $page =~ /(.+)::(.+)/ ) { $directory = $1; $table = $2; }

        $id ||= param( "FK_" . $table . "__ID" ) || param( $table . "_ID" ) || param('ID');

        $Sess->homepage("$table=$id");

        my $module = $directory . "::" . $table;

        ## Logic flow through this section (via App) should be phased out ##
        my $app       = $module . "_App";
        my %good_apps = (
            'alDente::Run_App'               => 1,
            'alDente::Source_App'            => 1,
            'alDente::Funding_App'           => 1,
            'alDente::Rack_App'              => 1,
            'alDente::Submission_Volume_App' => 1,
            'alDente::Solution_App'          => 1,
            ,
            'alDente::Sample_Request_App' => 1,
            'alDente::Funding_App'        => 1
        );

        ## This is where home pages should go (with home_page in App directing to home_page in Views module)
        my $view       = $module . '_Views';
        my %good_views = (
            'alDente::Shipment_Views'          => 1,
            'alDente::Invoice_Views'           => 1,
            'Patient::Patient_Views'           => 1,
            'alDente::Box_Views'               => 1,
            'alDente::Container_Views'         => 1,
            'alDente::Pipeline_Views'          => 1,
            'alDente::Invoiceable_Work_Views'  => 1,
            'alDente::Employee_Views'          => 1,
            'alDente::Contact_Views'           => 1,
            'alDente::Process_Deviation_Views' => 1,
        );

        if ( $good_views{$view} ) {
            $id ||= $list;

            eval "require $module" or Message("Error loading $module");
            eval "require $view"   or Message("Error loading $view");

            my $object = $module->new( -dbc => $dbc, -id => $id );
            my $View = $view->new( -dbc => $dbc, "-$table" => $object, -model => { $table => $object } );
            my $webview = $View->home_page( -dbc => $dbc, -id => $id );    ## parameters are slightly redundant.. should standardize

            return $webview;
        }

        # if ( can_ok($app, 'home_page') ) {
        if ( ( eval "require $app" ) && $good_apps{$app} ) {
            $id ||= $list;
            my $webapp = $app->new( PARAMS => { dbc => $dbc, id => $id } );

            my $page = $webapp->home_page( -id => $id, -dbc => $dbc );

            #	    my $new_q = CGI->new();
            #	    $id ||= $list;
            #	    $new_q->param(-name=>'ID', -value=>$id);
            #	    $new_q->param('rm' -value => 'Home');
##	    $webapp->query( $new_q );
            #	    my $page = $webapp->run('Home');

            if   ( $ENV{CGI_APP_RETURN_ONLY} ) { return $page }
            else                               { print $page }
            return $page;
        }
        else {

            #	    Message("$Configs{perl_dir}/alDente/${table}_App.pm NOT FOUND");
            eval "require $module";
            my $object = new $module(
                -dbc => $dbc,
                -id  => $id,
            );

            $list ||= $id;

            my $output = $object->home_page(
                -brief   => $scanner_mode,
                -verbose => $verbose,
                -list    => $list,
                -dbc     => $dbc,
            );
            return $output;
        }
        return 1;
    }
    elsif ( $table eq 'GenechipRun' ) {
        $id ||= param( "FK_" . $table . "__ID" ) || param( $table . "_ID" ) || param('ID');

        my $run_name = param("Run_Name");
        if ($run_name) {
            ($id) = $dbc->Table_find( "Run", "Run_ID", "WHERE Run_Directory='$run_name'" );
        }

        $Sess->homepage( "$table=" . $id );
        require Lib_Construction::GenechipRun;
        my $object = new Lib_Construction::GenechipRun(
            -dbc => $dbc,
            -id  => $id
        );

        $object->home_page(
            -brief   => $scanner_mode,
            -verbose => $verbose,
            -list    => $list,
            -dbc     => $dbc,
        );

        return 1;
    }

    elsif ( $table eq 'Template' ) {

        $id ||= param( "FK_" . $table . "__ID" ) || param( $table . "_ID" ) || param('ID');

        $Sess->homepage( "$table=" . $id );
        my $class = "Submission::Template";
        eval "require $class";
        Message($@) if $@;

        #require Submission::Template;
        my $object = new Submission::Template(
            -dbc => $dbc,
            -id  => $id
        );

        $object->home_page( -dbc => $dbc );

        return 1;
    }

    elsif ( $table eq 'LibraryApplication' ) {
        $id ||= param( "FK_" . $table . "__ID" ) || param( $table . "_ID" ) || param('ID');

        my ($library) = $dbc->Table_find( "LibraryApplication", "FK_Library__Name", "WHERE LibraryApplication_ID = $id" );

        my $object = new alDente::Library(
            -dbc  => $dbc,
            -name => $library
        );

        $object->home_info(
            -brief   => $scanner_mode,
            -verbose => $verbose
        );

        return 1;
    }
    elsif ( $table eq 'Pool' ) {
        $id ||= param( "FK_" . $table . "__ID" ) || param( $table . "_ID" ) || param('ID');

        $table = "alDente::Transposon_Pool";
        require alDente::Transposon_Pool;

        my $object = alDente::Transposon_Pool->new(
            -dbc => $dbc,
            -id  => $id
        );

        $object->home_page(
            -brief   => $scanner_mode,
            -verbose => $verbose,
            -list    => $list,
            -dbc     => $dbc
        );

        return 1;
    }
    elsif ( $table eq 'Transposon_Pool' ) {
        $id ||= param( "FK_" . $table . "__ID" ) || param( $table . "_ID" ) || param('ID');

        ($id) = $dbc->Table_find( "Transposon_Pool", "FK_Pool__ID", "WHERE Transposon_Pool_ID=$id" );

        $table = "alDente::Transposon_Pool";
        require alDente::Transposon_Pool;
        my $object = alDente::Transposon_Pool->new( -dbc => $dbc, -id => $id );
        $object->home_page( -brief => $scanner_mode, -verbose => $verbose, -list => $list, -dbc => $dbc );

        return 1;
    }
    elsif ( $table eq 'Equipment' ) {
        ### Equipment
        my $equip = $id || param('FK_Equipment__ID') || param('ID');
        $Sess->homepage( "$table=" . $equip );
        my $object = alDente::Equipment->new( -dbc             => $dbc, -id        => $equip );
        my $page   = alDente::Equipment_Views::home_page( -dbc => $dbc, -Equipment => $object );
        return $page;
    }
    elsif ( $table eq 'Maintenance_Schedule' ) {
        my $schedule_id = $id || param('Maintenance_Schedule_ID') || param('ID');
        print alDente::Equipment_Views::scheduled_maintenance( $dbc, -schedule_id => $schedule_id, -return_html => 1 );

        return 1;
    }

    #    } elsif ($table eq 'Solution') {          ### Equipment
    #	my $id = param('FK_Solution__ID') || param('Solution_ID') || param('ID');
    #	alDente::Solution::home_solution($id);
    #	return 1;
    #    }
    elsif ( $table eq 'Maintenance' ) {
        ### Maintenance
        $equipment_id ||= param('FK_Equipment__ID');

        my $equip = &get_aldente_id( $dbc, $equipment_id, 'Equipment' );
        my $object = alDente::Equipment->new( -dbc => $dbc, -id => $equip );
        $object->home_info( -brief => $scanner_mode );

        return 1;
    }
    elsif ( $table =~ /^(Parameter|Standard_Solution)$/ ) {
        ### Standard Chemistry page for Parameters /  Standard Solutions ###
        if ($id) {
            my $Formula = alDente::Chemistry->new( -dbc => $dbc, -id => $id );
            $Formula->show_Formula();
            return 1;
        }
        else {
            Message("SHOULD CATCH as Chemistry_Event");
        }
        return 1;
    }
    elsif ( $table =~ /^Primer$/ ) {
        ### Special handling for primers
        my $dbo = SDB::DB_Object->new( -dbc => $dbc, -tables => 'Primer' );
        if ($name) {
            ($id) = $dbc->Table_find( 'Primer', 'Primer_ID', "WHERE Primer_Name='$name'" );
        }

        #        my ($id) = &$dbc->Table_find('Primer','Primer_ID',"WHERE Primer_Name='$name'");

        $dbo->value( -field => "Primer_ID", -value => $id );
        $dbo->load_Object();
        my $details = $dbo->display_Record();
        my $info_page = &Link_To( $dbc->config('homelink'), "Info/Edit Page", "&Info=1&Table=$table&Field=Primer_ID&Like=$id", $Settings{LINK_COLOUR} );
        &Views::Table_Print( content => [ [ &Views::Heading("Primer_Name: $name") ], [$info_page], [$details] ] );

        return 1;
    }
    elsif ( $table =~ /^Plate_Set$/ ) {
        if ($number) {
            alDente::Container_Set::home_page( -dbc => $dbc, -set_number => $number, -brief => $scanner_mode );

            return 1;
        }
        elsif ($id) {
            alDente::Container_Set::home_page( -dbc => $dbc, -set_number => $id, -brief => $scanner_mode );
            return 1;
        }
        else {
            Message("Error: No Plate_Set number specified. Please report an issue");
            return 0;
        }
    }
    elsif ( $table =~ /^Lab_Protocol$/ ) {

        if ($id) {
            my $Protocol_View = new alDente::Protocol_Views( -dbc => $dbc );
            print $Protocol_View->view_Protocol( -dbc => $dbc, -id => $id );
            return 1;
        }
        else {
            Message("Error: Missing Lab Protocol ID");
            return 0;
        }
    }
    else {
        ### Display default home page
        #commented out to remove unnecessary pages from being displayed
        $id ||= $list;

        return Default_Home( -dbc => $dbc, -table => $table, -id => $id, -force => $force );
    }

    return 0;    ## nothing found & printed...
}

#######################
sub GoHome_btn {
##############################
    my %args        = filter_input( \@_, -args => 'dbc' );
    my $dbc         = $args{-dbc};
    my $class       = $args{-class};
    my $form_output = submit( -name => 'Go to Home Page', -value => 'Go to Home Page', -class => 'Std' ) . hidden( -name => 'Class', -value => $class, -force => 1 );

    return $form_output;
}

##########################
sub catch_GoHome_btn {
##########################
    my %args   = filter_input( \@_, -args => "dbc" );
    my $dbc    = $args{-dbc};
    my $class  = param('Class');
    my @marked = param('Mark');
    my $ids    = join ',', @marked;

    if ( param('Go to Home Page') ) {
        if ( !$ids || !$class ) { return "No Class ($class) or IDs ($ids) specified." }
        my $page = GoHome( -dbc => $dbc, -id => $ids, -table => $class );
        return $page;
    }
    return;
}

####################
sub standard_page {
####################
    my %args               = &filter_input( \@_, -args => 'page,id' );
    my $page               = $args{-page};
    my $dbc                = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id                 = $args{-id};
    my $Current_Department = $dbc->config('Target_Department');

    if ( $page =~ /library/i ) {
        my $Lib_Type = 'Library';
        if ( $Current_Department =~ /(Cap_Seq|Mapping)/i ) {
            $Lib_Type = 'Sequencing_Library';
        }
        elsif ( $Current_Department =~ /Lib_Construction/i ) {
            $Lib_Type = 'RNA_DNA_Collection';
        }
        my $lib;
        if ( ( $Lib_Type =~ /RNA_DNA|RNA\/DNA/ ) || ( $Current_Department =~ /(Expression|SAGE|Affy)/ ) ) {
            $lib = alDente::RNA_DNA_Collection->new();
        }
        elsif ( ( $Lib_Type =~ /Sequencing/ ) || ( $Current_Department =~ /(Cap_Seq)/ ) ) {
            $lib = Sequencing::Sequencing_Library->new();
        }
        else {
            $lib = alDente::Library->new( -dbc => $dbc );
        }

        if ( $lib->library_main( -dbc => $dbc ) ) { return 1; }    ## exit if page generated
    }
    elsif ( $page =~ /chemistry/i ) {
        &alDente::Chemistry::create_Formula_interface($dbc);
    }
    elsif ( $page =~ /(plate|tube)/i ) {
        my $view_obj = new alDente::Container_Views( -dbc => $dbc );
        print $view_obj->home_plate( -dbc => $dbc );
    }
    elsif ( $page =~ /^source/i ) {
        &alDente::Source::home_source( -dbc => $dbc );
    }
    elsif ( $page =~ /^Solution/ ) {
        &solution_main;
    }
    elsif ( $page =~ /^Equipment/ ) {
        &alDente::Equipment_Views::equipment_main( -dbc => $dbc );
    }
    else {
        Message("Unidentified Standard Page: $page ?");
        return 0;
    }
    return 1;
}

###############################
# Prints the default home page
###############################
sub Default_Home {
###################
    my %args  = @_;
    my $dbc   = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $force = $args{-force};
    my $table = $args{-table};
    my $id    = $args{-id};

    if ( !$force && ( $Sess->{homepage} =~ /(\w+)=(\w+)/ ) ) { return 0; }    ## already a defined home page (and force not set)

    my $app = 'alDente::' . $table . "_App";
    ## Dynamically call home_page in _App module if it exists ... ultimately all standard object home pages should come through this block ##
    if ( -e "$Configs{perl_dir}/alDente/${table}_App.pm" && `grep 'sub home_page' $Configs{perl_dir}/alDente/${table}_App.pm` ) {
        ## Found standard home_page in object _App module ##
        eval "require $app";

        my $webapp = $app->new( PARAMS => { dbc => $dbc, id => $id } );
        my $page = $webapp->home_page( -id => $id, -dbc => $dbc );

        if   ( $ENV{CGI_APP_RETURN_ONLY} ) { print $page }
        else                               { print $page }                    ## for now need to print anyways since this method of calling home_page does not generate the page automatically...
        return $page;
    }

    my $dbo = SDB::DB_Object->new( -dbc => $dbc, -tables => $table );
    $dbo->primary_value( -table => $table, -value => $id );

    my $primary_field = $dbo->primary_field();
    $id = $dbc->get_FK_ID( $primary_field, $id );

    print &SDB::DB_Form_Viewer::view_records( $dbc, $table, $primary_field, $id );

    return 1;

    #    $dbo->load_Object();
    #    my $details = $dbo->display_Record();
    #    my $info_page = &Link_To($homelink,"Info/Edit Page","&Info=1&Table=$table&Field=$primary_field&Like=$id",$Settings{LINK_COLOUR});
    #    &Views::Table_Print(content=>[[&Views::Heading("$table.$primary_field: $id")],[$info_page],[$details]]);
}

##################
sub info {
##################
    #
    # divert to various info protocols (based on barcode scanned...
    #
    my $dbc       = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $barcode   = shift;
    my $more_info = shift;

    $dbc->Benchmark('info');

    #    print "<BODY width=400 BGCOLOR=red>";

#####  Identify type of unit ########################
    eval "require alDente::Barcode";
    my $prefix_hash = alDente::Barcode::Barcode_Prefix($dbc);
    my %Prefix;
    
    if ($prefix_hash) { %Prefix = %{ $prefix_hash } }
    else { $dbc->warning("Barcode Prefixes not defined") }
    
    my $query = "default";
    my $table;
    my $id;
    my $name;
    $_ = $barcode;

## Equipment barcode ##
    if ( $barcode =~ /Equ(\d+)/i ) {    ### even if not first parameter
        my $id = alDente::Validation::get_aldente_id( $dbc, $barcode, 'Equipment' );

        if ($id) {
            my $object = alDente::Equipment->new( -dbc => $dbc, -id => $id );
            return $object->View->std_home_page(-brief=>$scanner_mode, -dbc=>$dbc, -id=>$equipment_id);
        }
        else {
            return 0;
        }
    }
## Equipment barcode ##
    elsif ( $barcode =~ /^(MB\d)/i ) {
        $table = 'Equipment';
        $name  = $1;
        $query = "select * from $table where $table" . "_Name like \"%$name%\"";
        ( $equipment_id, $equipment ) = split ',', ( join ',', $dbc->Table_find( 'Equipment', 'Equipment_ID,Equipment_Name', "where Equipment_Name like \"$name%\"" ) );
        my $object = alDente::Equipment->new( -dbc => $dbc );
        
        return $object->View->std_home_page(-brief=>$scanner_mode, -dbc=>$dbc, -id=>$equipment_id);
        $object->home_info( $equipment_id, $barcode );
            
        return $object->View->std_home_page(-brief=>$scanner_mode, -dbc=>$dbc, -id=>$equipment_id);
    }
## Equipment barcode ##
    elsif ( $barcode =~ /^(3700[-\s]*\d)/i ) {
        $table = 'Equipment';
        $name  = $1;
        ($equipment_id) = $dbc->Table_find( 'Equipment', 'Equipment_ID', "where Equipment_Name like '%$name%'" );

        my $object = alDente::Equipment->new( -dbc => $dbc );
        return $object->View->std_home_page(-brief=>$scanner_mode, -dbc=>$dbc, -id=>$equipment_id);
    }
## Plate barcode ##
    elsif ( $barcode =~ /^($Prefix{Plate})(\d+)/i ) {
        $table = 'Plate';

        my $plate_id = alDente::Validation::get_aldente_id( $dbc, $barcode, 'Plate' );

        if ($plate_id) {
            my $Plate = alDente::Container->new( -dbc => $dbc, -id => $plate_id );
            if ( !$Plate ) { return 0 }

            $Plate->{table} = 'Plate';
            my ($type) = $dbc->Table_find( 'Plate', 'Plate_Type', "where Plate_ID in ($plate_id)" );
            $type = "alDente::" . $type;
            eval "require $type";
            Message($@) if $@;

            return $Plate->View->std_home_page( -brief => $scanner_mode, -dbc => $dbc, -id=>$plate_id);
        }
    }
    elsif ( $barcode =~ /^Sol(\d+)/i ) {
        $table = 'Solution';

        $solution_id = get_aldente_id( $dbc, $barcode, 'Solution' );

        if ( $solution_id =~ /,/ ) {
            $solution_id = alDente::Validation::get_aldente_id( $dbc, $barcode, 'Solution', -validate => 1 );
            my $sols = int( my @list = split ',', $solution_id );

            my $Sol = alDente::Solution->new( -id => $solution_id, -dbc => $dbc );

            if ($solution_id) { print $Sol->display_solution_options( -dbc => $dbc, -solution_ids => $solution_id ) }

            $solution_id = alDente::Validation::get_aldente_id( $dbc, $barcode, 'Solution', -validate => 1, -qc_check => 1, -fatal_flag => 1 );

            #if ($solution_id) { &alDente::Solution::make_Solution( '', 0, $sols, $solution_id ) }
            #return 1;
            if ($solution_id) {

                #    require alDente::Solution_Views;
                #    return &alDente::Solution_Views::display_mix_solution_page( -dbc=>$dbc, -solutions=> $sols,-ids=> $solution_id ) ;
                #    return;
                eval "require alDente::Solution_App";
                my $webapp = alDente::Solution_App->new( PARAMS => { dbc => $dbc, solutions => $sols, ids => $solution_id } );
                $webapp->start_mode('Mix Standard Solution');
                my $page = $webapp->run();
                print $page;
                return $page;

            }
            return 1;
        }
        elsif ( $solution_id =~ /[1-9]/ ) {
            my $Sol = alDente::Solution->new( -id => $solution_id, -dbc => $dbc );
            $Sol->home_page( -dbc => $dbc );
            return 1;
        }
        else {
            return 0;
        }
    }
## Box/Kit barcode ##
    elsif ( $barcode =~ /^Box(\d+)/i ) {
        $id = get_aldente_id( $dbc, $barcode, 'Box' );
        if ( $id =~ /^(\d+)/ ) {
            my $object = alDente::Box->new( -dbc => $dbc, -id => $id );
            $object->home_page( -brief => $scanner_mode, -dbc => $dbc );
            return 1;
        }
        else {
            return 0;
        }
    }
## Employee with password ?? ##
    elsif (0) {    ### $barcode=~/^Emp(\d+)(\D.*)/i) {
        $id = $1;
        my $pass     = $2;
        my $password = 'pass';    ### Temporary - use stored passwords eventually...
        ### login as new employee ###
        $user_id = $id;
        ($user) = $dbc->Table_find( 'Employee', 'Employee_Name', "where Employee_ID = $id" );
        print "*** Relogin as $user..";
        $session_id = "$user_id:" . localtime();
        &home('main');
        return 1;
    }
    else {
         if ( $barcode =~ /^\w{5,6}$/ ) {    ## see if it is a library...
            my ($lib) = $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Name like '$barcode'" );
            if ($lib) { &GoHome( $dbc, 'Library', $lib ); return 1; }
        }
    
        if ( $barcode =~ /^(\w{5,6})\-(\d+)$/ ) {    ## see if it is a library with a plate number
            my ($lib) = $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Name like '$1'" );
            my $platenum = $2;

            if ( $lib && $platenum ) {

                # find the original, and display the plate page
                my ($orig_plate_id) = $dbc->Table_find( "Plate", "Plate_ID", "WHERE FK_Library__Name='$lib' AND Plate_Number=$platenum AND Plate_ID=FKOriginal_Plate__ID");
                unless ($orig_plate_id) {
                    print "Unrecognized Barcode: '$barcode'";
                    return 0;
                }
                $current_plates = $orig_plate_id;
                $dbc->{current_plates} = [$orig_plate_id];

                #my $Plate = alDente::Container->new( -dbc => $dbc, -id => $orig_plate_id );
                my $Plate = new alDente::Container( -dbc => $dbc, -id => $orig_plate_id );
                print $Plate->View->std_home_page();
                return 1;
            }
        }
        ## Other table barcode ##
        elsif ( $barcode =~ /^([a-zA-Z]{3})(\d+)/i ) {
            my $prefix = $1;

            my $table;
            foreach my $thistable ( keys %Prefix ) {
                if ( $Prefix{$thistable} =~ /^$prefix$/i ) { $table = $thistable; last; }
            }
            unless ($table) { print "Unrecognized $prefix barcode: '$barcode' ?"; return 0; }
            
            my $ids = &get_aldente_id( $dbc, $barcode, $table );

            if ( $ids && ( $ids ne 'NULL' ) ) {
                my $object = 'alDente::' . $table;
                my $Object = $object->new(-dbc=>$dbc, -id=>$ids);
                return $Object->View->std_home_page();
                
                ( my $IDfield ) = &get_field_info( $dbc, $table, undef, 'Primary' );
                print &SDB::DB_Form_Viewer::view_records( $dbc, $table, $IDfield, $ids );
                &main::home();
                return 1;
            }
        }
        elsif ( $barcode eq undef ) {
            &main::home('main');
            return 1;
        }

    }

######## Otherwise:   check for solution catalog number...
    my $lot;    #### optional lot number specification...
    if ( param('Lot') ) { $lot = "and Stock_Lot_Number = '" . param('Lot') . "'"; }

    ( my $solution_id )
        = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Solution_ID', "where FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Stock__ID=Stock_ID and Stock_Catalog.Stock_Catalog_Number='$barcode' $lot order by Stock_Received desc limit 1" );
    unless ( $solution_id =~ /\d+/ ) {
        ($solution_id) = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Solution_ID', "where FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Stock__ID=Stock_ID and Stock_Lot_Number='$barcode' order by Stock_Received desc limit 1" );
    }
    unless ( $solution_id =~ /\d+/ ) {
        RGTools::RGIO::Message("Unrecognized Barcode ($barcode ?)");

        #	&main::check_last_page();
        #	  &main::home('main');
        return;
    }
    my $solution = join ',', $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog_Name', "where FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Stock__ID=Stock_ID and Solution_ID=$solution_id" );
    if ( $more_info =~ /long/i ) {
        my $Sol = alDente::Solution->new( -id => $solution_id );
        $Sol->more_solution_info;

        #	&alDente::Solution::more_solution_info($solution_id,$solution);
    }
    else {
        my $Sol = alDente::Solution->new( -id => $solution_id );
        $Sol->home_page( -dbc => $dbc );

        #	alDente::Solution::home_solution($solution_id);
    }

    return;
}

############################
sub contact_info {
############################
    #
    # print out basic contact info...
    #
    my $dbc          = $Connection;
    my $contact      = shift;
    my $organization = shift;

    my $Ctype = param('Contact Type')      || "";
    my $Otype = param('Organization Type') || "";

    print &Views::Heading("Contact Info");

    my $condition = "where FK_Organization__ID = Organization_ID";
    if ($organization) { $condition .= " and Organization_Name like \"$organization\""; }
    if ($Ctype)        { $condition .= " and Contact_Type like \"$Ctype\""; }
    if ($Otype)        { $condition .= " and Organization_Type like \"$Otype\""; }

    $condition .= " Order by Organization_Name,Contact_Name";

    my @headers = ( 'Organization', 'Type', 'Name', 'Position', 'Type', 'Phone', 'Email', 'Fax' );
    my @field_list = ( 'Organization_Name', 'Organization_Type', 'Contact_Name', 'Position', 'Contact_Type', 'Phone', 'Email_Address', 'Fax' );

    my @contact_info = $dbc->Table_find_array( 'Organization,Contact', \@field_list, $condition );

    my $Table = HTML_Table->new();
    $Table->Set_Title("List of $Otype $Ctype Contacts");
    $Table->Set_Headers( \@headers );
    foreach my $data (@contact_info) {
        my @fields = split ',', $data;
        $Table->Set_Row( \@fields );
    }
    print $Table->Printout("$URL_temp_dir/Contacts.html");
    $Table->Printout();
    return 1;
}

############################
sub organization_info {
############################
    #
    # print out basic organization info
    #
    my $dbc          = $Connection;
    my $contact      = shift;
    my $organization = shift;

    my $Otype = param('Organization Type') || "";

    print &Views::Heading("Organization Info");

    my $condition = "where FK_Organization__ID = Organization_ID";
    if ($organization) { $condition .= " and Organization_Name like \"$organization\""; }
    if ($Otype)        { $condition .= " and Organization_Type like \"$Otype\""; }

    my @headers = ( 'Organization', 'Type', 'Phone', 'Fax' );
    my @field_list = ( 'Organization_Name', 'Organization_Type', 'Phone', 'Fax' );
    if ($contact) {
        push( @field_list, ( 'Contact_Name', 'Contact_Type', 'Phone', 'Email_Address' ) );
        $condition .= "and (Contact_Name like \"$contact\" or Contact_ID = \"$contact\") Order by Organization_Name, Contact_Name";
        push( @headers, ( 'Contact', 'Position', 'Phone', 'Email' ) );
    }
    else {
        $condition .= " Group by Organization_Name Order by Organization_Name";
    }
    my @contact_info = $dbc->Table_find_array( 'Organization,Contact', \@field_list, $condition, 'Distinct' );

    my $Table = HTML_Table->new();
    $Table->Set_Title("List of $Otype Contacts");
    $Table->Set_Headers( \@headers, 'mediumyellow' );
    foreach my $data (@contact_info) {
        my @fields = split ',', $data;
        $Table->Set_Row( \@fields );
    }
    print $Table->Printout("$URL_temp_dir/Organizations.html");
    $Table->Printout();
    return 1;
}

##################
sub table_info {
##################
    my $table             = shift;
    my $dbc               = $Connection;
    my %Table_Description = (
        Project => "
This table stores basic information relating to a general Project which may consist of a number of libraries.",
        Library => " 
The Library Table stores information regarding an individual library of clones.  By definition each library must be defined by a single Vector.",
        Vector => "
Details regarding the Vectors used are stored in the Vector table.  When Vector sequences are modified slightly, this should correspond to a new record with a new unique name indicating the modification.  Vector sequence information is stored in a directory as a file, and only the filename stored in the actual Vector table.",
        Clone => "
The Clone Table is used primarily to identify specific clones.  Generally these are received from an external source, where they may have a differing name.  These clones are then cross-referenced to their position within our own system so that their source may be identified.",
        Primer => "
The primer table stores information on general primers that are used within the lab.  Included in this table are both 'Standard' Primers which are used as well as Custom Primers or Oligos that are made specifically for use within the lab.",
        Solution => "
All reagents and solutions used within the lab are stored in the 'Solution' Table, which tracks when bottles are opened, and how much has been used.  In addition this allows stock monitoring to ensure that a specified number of unopened bottles of various reagents are always in store.",
        Stock => "
The Stock table ties Orders to actual stock items within the lab.  All Equipment, Reagents etc are originally entered as stock items, and their details stored in the separate 'Equipment' or 'Solution' databases.  For example if a batch of 100 bottles come in, there is a single record in the Stock table added with details relating to the batch (source, date, number, item description etc).  In addition, 100 separate records are added to the Solution Table in which the specifics for each bottle are tracked (ID number, Opening date, Amount Used etc.).",
        Run => "
The Run Table stores information for each sequence run requested (by plate).<BR>
Information that is common to a number of plates which may be run at the same time is stored in the " . &Link_To( $dbc->config('homelink'), 'RunBatch', "&Table+Info=RunBatch", $Settings{LINK_COLOUR} ),
        RunBatch => "
The RunBatch Table stores information that is common to all runs generated together.  Some 384-well plates are also tracked as 4 separate runs (associated with possibly 4 different libraries), and thus a run using a single 384-well plate may produce 4 Run records and one RunBatch record.",
        Clone_Sequence => "
This is the largest component of the database in terms of size, and this table contains all of the basepairs in a read as well as the associated quality scores.  For speed of extraction purposes, this table also maintains a binary storage of the phred histograms (both individual and cumulative) for the read as a whole and a number of index values corresponding to quality regions and vectors.",
        Plate => "
This Table stores information on individual plates in the lab.  By definition a plate may be defined by one and only one library, though plates may be combined (ie 96 -> 384 well) onto one actual piece of plasticware.  (In this case, the 96 well plates continue to be tracked within the 384 well plate).",

    );

    unless ( %Field_Info && defined $Field_Info{$table} ) { &SDB::DBIO::initialize_field_info( $dbc, $table ); }    ### fills in %Field_Info..

    if ( defined $Table_Description{$table} ) {
        print "<P><Indent><span=small><B>" . $Table_Description{$table} . "</B><P>";
    }
    my $dfield = $Primary_fields{$table} || join ',', &get_field_info( $dbc, $table, undef, 'Primary' );

    my $desc_condition = '';
    if ( $dfield && defined $Field_Info{$table}{$dfield} ) {
        $desc_condition = "&Order+By=$dfield+DESC";
    }

    print &Link_To( $dbc->config('homelink'), 'View Sample Data', "&List+Entries=1&Table=$table&List+Limit=10$desc_condition", $Settings{LINK_COLOUR}, ['newwin'] ) . &vspace(10);

    my $TableInfo = HTML_Table->new();
    $TableInfo->Set_Border(1);

    #   $TableInfo->Set_Line_Colour('white','white');

    my %Table_Info = %{ $Field_Info{$table} };

    my @headers = @{ $Field_Info{Fields} };    ### list of headers...
    $TableInfo->Set_Headers( \@headers );

    #    my @fields = keys %{ $Field_Info{$table} };
    #    print "KEYS: @keys";

    my @fields = get_fields( $dbc, $table, undef, 'defined' );    ## (was get_defined_fields ) ##

    foreach my $field (@fields) {
        if ( $field =~ /(.*) as (.*)/ ) {
            $field = $1;
        }
        my @thisrow;
        foreach my $header (@headers) {
            my $value = $Field_Info{$table}{$field}{$header};
            if ( ( $header eq 'Field' ) && ( $value =~ /^FK[a-zA-Z0-9]*_(.*)__(.*)/ ) ) {
                my $ref_table = $1;
                push( @thisrow, &Link_To( $dbc->config('homelink'), $value, "&Table+Info=$ref_table", $Settings{LINK_COLOUR} ) );
            }
            else { push( @thisrow, $value ); }
        }
        $TableInfo->Set_Row( \@thisrow );
    }
    $TableInfo->Printout();

    return 1;
}

########################
sub add_suggestion {
########################
    #
    # add suggestion to suggestion box
    #

    my $dbc      = $Connection;
    my $username = $dbc->get_local('user_email');

    # cheap-o hack-o to account for an oversight when setting up the manager role in Zope
    # Kevin's CMF User Account should be kteague, but instead it is kevint
    $username =~ s/kteague/kevint/;

    print << "HereBugForm";

<table width="100%" cellpadding="3">
<tr>
<td class="lightheader">Submit a New Bug or Feature Request</td>
</tr>
</table>
&nbsp;<br>

<table bgcolor="#FFFFFF" border="0" cellpadding="0"
       cellspacing="0">

<span>

  <form name="submit_issue_form" method="post" action="http://gin.bcgsc.ca/issues/submit_issue">
  <input type="hidden" name="category" value="SeqDB"/>

    <tr><td><b>Type</b></td>
        <td><b>Submitted by: $username</b></td>
   </tr>
   <tr>
        <td><input type="radio" name="group" value="bug" checked/> Bug
	  <input type="radio" name="group" value="feature request"/> Feature Request
	</td>
        <td>$username</td>
    </tr>
   <tr>
       <td><b>Email me when the issue changes?</b></td>
       <td colspan="2">&nbsp;</td>
   </tr>
    <tr>
        <td nowrap><input name="notify_state:int" value="1" type="radio" checked />yes&nbsp;&nbsp;
                   <input name="notify_state:int" value="0" type="radio" />no
        </td>
        <td colspan="2">&nbsp;</td>
    </tr>
    <tr><td colspan="3"><b>Title</b></td></tr>
    <tr><td colspan="3"><input name="summary" type="text" size="82" /></td></tr>
    <tr><td colspan="3"><b>Description</b>
(use <a href="http://www.zope.org//Members/jim/StructuredTextWiki/StructuredTextRules">structured text</a>)</td></tr>
    <tr><td colspan="3"><textarea name="comment" wrap="hard" rows="20" cols="80"></textarea></td></tr>
    <tr><td colspan="3"><input class="submit" type="submit" name="submit" value="Submit Issue" style="background-color:red" /></td>
    </tr>
  </form>

</span>

</table>
&nbsp;<br>

<table width="100%" cellpadding="3">
<tr>
<td class="lightheader">SeqDB Bugs and Feature Requests</td>
</tr>
</table>
&nbsp;<br>
<p ></p>View all SeqDB issues which are:</p>
<ul>
<li> <a href="http://gin.bcgsc.bc.ca/issues/issue_summary_screen?id=&summary%3Astr=&sub_time=&lc_time=&priority%3Aint=1&status%3Alist=open&submitted_by%3Alist=any&assigned_to%3Alist=any&category%3Alist=SeqDB&group%3Alist=any">Open</a> : Currently assigned to someone and 
is possibly being actively worked on.
<li> <a href="http://gin.bcgsc.bc.ca/issues/issue_summary_screen?id=&summary%3Astr=&sub_time=&lc_time=&priority%3Aint=1&status%3Alist=pending&submitted_by%3Alist=any&assigned_to%3Alist=any&category%3Alist=SeqDB&group%3Alist=any">Pending</a> : Has not yet been reviewed or
assigned.
<li> <a href="http://gin.bcgsc.bc.ca/issues/issue_summary_screen?id=&summary%3Astr=&sub_time=&lc_time=&priority%3Aint=1&status%3Alist=closed&submitted_by%3Alist=any&assigned_to%3Alist=any&category%3Alist=SeqDB&group%3Alist=any">Closed</a> : Issue has been resolved.
</ul>

HereBugForm

    # TO DO: Make older suggestions visible somehow
    # &list_suggestions();

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

$Id: Info.pm,v 1.64 2004/12/06 22:02:36 echuah Exp $ (Release: $Name:  $)

=cut

1;
