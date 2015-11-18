###################################################################################################################################
# alDente::Scanner_App.pm
# March 2009 : Ash Shafiei
#
#
#
###################################################################################################################################
package alDente::Scanner_App;

use base RGTools::Base_App;
use strict;

## RG Tools
use RGTools::RGIO;
## SDB modules
use SDB::CustomSettings;
use SDB::HTML;
use SDB::Errors;

## alDente modules
use alDente::Scanner_Views;
use alDente::SDB_Defaults;
use alDente::Validation;
use alDente::Info;
use alDente::Tray;
use alDente::Tray_Views;

use alDente::Rack_App;

use LampLite::Bootstrap();

#use CGI::Application::Plugin::Forward;

use vars qw( $Connection %Configs  $Security);

my $BS = new Bootstrap();
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Scanner_App.pm 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

=cut

######################################################
##          Controller                              ##
######################################################
###########################
sub setup {
###########################
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');
    $self->run_modes(
        'default' => 'scan_barcode',
        'Scan'    => 'scan_barcode',

        'Object homepage'           => 'Object_homepage',
        'Display library Home-page' => 'display_Library_homepage',
        'This is not a library'     => 'Object_homepage',
        'List Page'                 => 'list_page',
        'Add Solution to Plate'     => 'add_Solution_to_Plate',
        'Mix Solutions'             => 'mix_Solutions',
        'Pool Sources'              => 'pool_Sources',
        'Validate ReArray Plates'   => 'validate_ReArray_Plates',
        'Show ReArray Request'      => 'show_ReArray_Request',
        'move plate to equipment'   => 'move_plate_to_equipment',
        'move rack to equipment'    => 'move_involve_rack',
        'Source home page'          => 'Source_home_page',
        'Move to Equipment'         => 'move_to_Equipment',

        #        'move to rack'                  =>  'move_items',
        'move rack items' => 'move_rack_items',

        #		     'scanned Racks'                 =>  'scanned_Racks',
        #		     'move Items'  => 'move_Items',
        'move Rack'      => 'move_Rack',
        'Rack home page' => 'Rack_home_page',
    );

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    return 0;
}

######################################################
##          Run Modes: Controlers                   ##
######################################################

###########################
sub scan_barcode {
###########################
    #   This is the default run mode when scan button is pressed. It decides if the barcode is a library name or a mix of standard scanned objects
    #       If both it prompts user for choice, if only library goes to library homepage,  If mix of objects uses get_run_mode to decide next step
    #       single appearance of a single object goes to homepage, If none it sends warning
    #   Input:
    #       the barcode scanned and databse connection
###########################
    my $self = shift;

    my %args        = @_;
    my $q           = $self->query;
    my $dbc         = $self->param('dbc') || $args{-dbc};
    my $not_library = $self->param('Not Library') || $q->param('Not Library');    ## A flag indicating that we are already sure the barcode is not a library
    my $barcode     = alDente::Scanner::scanned_barcode('Barcode');

    my $detailed = $q->param('Detailed');                                         ## optional parameter for more detailed views

    my @run_modes;

    unless ($barcode) {
        $dbc->message('Please scan in a valid Barcode.');
        return;
    }

    $barcode = RGTools::RGIO::chomp_edge_whitespace($barcode);

    #    if ( !$q->param('Scan') && !( $q->param('Quick_Action_List') eq 'Scan' && $q->param('Quick_Action_Value') ) ) { return 0 }

    my $objects_ref = $self->get_Object_List( -barcode => $barcode, -dbc => $dbc );
    $self->param(
        'Barcode' => $barcode,
        'Objects' => $objects_ref
    );
    
    my %objects = %$objects_ref if $objects_ref;
    my $object_count = $self->get_Object_Count( -object => \%objects );    ## The number of distinct objects

    my $library_match;
    ## check to see if user has scanned in a library explicitly (unless not_library flag has been passed)
    if ($not_library) { $library_match = 0 }                               # It's already been confirmed that object is not a library
    else {
        require alDente::Library;
        my $library_model = alDente::Library->new( -dbc => $dbc );
        $library_match = $library_model->get_Library_match( -barcode => $barcode, -dbc => $dbc );
    }

    if ( $library_match && $object_count ) {
        Message 'The barcode you have entered is both a library name and a list of objects';
        return alDente::Scanner_Views::prompt_Selection( -dbc => $dbc, -barcode => $barcode, -objects => \%objects );
    }
    elsif ($library_match) {
        return $self->display_Library_homepage( -dbc => $dbc, -library => $barcode );
    }
    elsif ( $object_count == 0 ) {
        if ($barcode) {

            # alDente::Info checks extra barcode such as library_name-plate_number
            return alDente::Info::info( $dbc, $barcode );
##            if ($homepage) (
#                return $homepage;
#            }
#            else {
#                &main::home('main');
#            }
        }
        return;
    }

    my $actions = $self->get_Actions_Hash( -dbc => $dbc );

    my $run_modes_ref = $self->get_Run_Mode( -actions_list => $actions, -objects => \%objects );

    if ($run_modes_ref) { @run_modes = @$run_modes_ref }
    my $run_mode_count = @run_modes;

    if ( $run_mode_count == 1 ) {
        return $self->run_mode_handler( -mode => $run_modes[0] );
    }
    elsif ($run_mode_count) {
        return alDente::Scanner_Views::prompt_Selection( -dbc => $dbc, -runmodes => $run_modes_ref, -barcode => $barcode );
    }
    elsif ( $object_count == 1 ) {
        ( my $object_name ) = keys %objects;
        $object_name =~ s/^(\w+)\[(.*)\]/$1/;    ## truncate if sub-type included in object name ...

        my $id = &get_aldente_id( $dbc, $barcode, $object_name, -validate => 0 );

        my $scope       = 'alDente';
        my $module_name = $object_name;
        $module_name =~ s/Plate/Container/;
        if    ( $object_name eq 'Gel_Run' )  { $scope = 'Gel';  $module_name = 'Run' }
        elsif ( $object_name eq 'AATI_Run' ) { $scope = 'AATI'; $module_name = 'Run' }

        my $model  = $scope . '::' . $module_name;
        my $view   = $model . '_Views';
        my $method = $view . '::' . 'display_record_page';

        my $old_method = $view . '::' . 'home_page';
        if ( $id && eval "require $model" && eval "require $view" && defined &{$method} ) {
            ## newest more scalable workflow for generating standard home pages ##
            my $Model = $self->Model( -dbc => $dbc, -class => $module_name, -id => $id );
            my $View = $Model->View();
            $View->{barcode} = $barcode;

            ### Found standard home_page in _Views module ###
            my $block = $View->std_home_page( -id => $id, -detailed => $detailed );    ## model=>{$object_name => $object});
            return $block;
        }
        elsif ( $id && eval "require $model" && eval "require $view" && defined &{$old_method} ) {
            ### This process is deprecated, but may be supported for the time being ###
            my $temp    = $view->new( -dbc       => $dbc, -id => $id, -detailed => $detailed );    ## model=>{$object_name => $object});
            my $webview = $temp->home_page( -dbc => $dbc, -id => $id, -detailed => $detailed );    ## model=>{$object_name => $object});
            $dbc->debug_message("The home_page method should be deprecated and replaced with display_record_page  / generic_page methods");
            return $webview;
        }

        else {
            my $localdept = $dbc->get_local('home_dept');
            $dbc->admin_warning("Refactor Code: Add $model or $view home_page or $method method.");
        }

        ## this should be deprecated (code should go through first block above if possible), but is supported as legacy code for the time being... ##
        return $self->Object_homepage( -barcode => $barcode, -object => $object_name );
    }
    else {
        print $BS->warning('Uknown combination of objects');
    }
    return;
}

###########################
sub Object_homepage {
###########################
    #   Description:
    #       - Generic homepage for any object
###########################
    my $self    = shift;
    my %args    = @_;
    my $dbc     = $self->param('dbc') || $args{-dbc};
    my $barcode = $args{-barcode} || alDente::Scanner::scanned_barcode('Barcode');    ## Barcode Scanned
    my $object  = $args{-object};                                                     ## Reference to a hash containing all objects in barcode and their count
    $object =~ s/\[.*\]//;                                                            #remove object type

    SDB::Errors::log_deprecated_usage('Standard Home Page');

    my $page;
    my $id = &get_aldente_id( $dbc, $barcode, $object, -validate => 0 );

    if ( $object eq 'Plate' && $id ) {
        my @ids = split ',', $id;
        $dbc->{current_plates} = \@ids;
    }

    if ($id) {
        $page = &alDente::Info::GoHome( $dbc, $object, $id );
    }
    else {
        Message "Failed to recognize object: $object";
    }
    return $page;
}

###########################
sub list_page {
###########################
    #   Description:
    #       - Generic list page for a list of single type objects
###########################
    my $self    = shift;
    my %args    = @_;
    my $dbc     = $self->param('dbc');
    my $barcode = alDente::Scanner::scanned_barcode('Barcode');    ## Barcode Scanned

    &alDente::Info::info( $dbc, $barcode );
}

#############################
sub get_Object_List {
#############################
    ## This method takes in a scanned string and return the list of objects and count of their occurance
    # Input: A unseparted string of standard object and their number (eg PLA500PLA501EQU203)
    # Output: Hash reference . Hash contains the name of objects as keys and their count as value
    #
    # Example: my $objects_ref         = $App -> get_Object_List (-barcode=> $barcode);
############################
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->param('dbc');
    my $q        = $self->query;
    my $barcode  = $args{-barcode} || alDente::Scanner::scanned_barcode('Barcode');    ## Barcode Scanned
    my %objects  = ();
    
    my $barcode_prefix = $dbc->config('Barcode_Prefix') || {};
    my @prefixes;
    if ($barcode_prefix) { @prefixes = keys %{$barcode_prefix} };

    my $revised_barcode = $barcode;

    my $page;
    if ( $barcode =~ /$barcode_prefix->{Tray}\d+/i ) {
        ## specific adjustments need to be made in case of Trays being scanned - (converted to simulate multiple PLA scans) ##
        $revised_barcode = alDente::Tray::convert_tray_to_plate( -dbc => $dbc, -barcode => $barcode );

        #        my $tray_id = get_aldente_id( $dbc, $barcode, 'Tray' );
        #        if ($tray_id) {
        #
        #           print alDente::Tray_Views::tray_header( -dbc => $dbc, -tray_id => $tray_id );
        #        }
    }

    for my $obj (@prefixes) {
        if (!$barcode_prefix->{$obj} || $revised_barcode !~/\b$barcode_prefix->{$obj}\b/) { next }
        
        my $id = get_aldente_id( $dbc, $revised_barcode, $obj, -quiet => 1 );
        if ($id) {
            my @ids = split ',', $id;
            my $count = @ids;    ##get the count of $ids
            if ( $obj eq 'Equipment' ) {

                #Expand Equipment
                require alDente::Equipment;
                my $category_ref = alDente::Equipment::get_Equipment_Category( -dbc => $dbc, -Equipment_ids => $id, -return => 'Combo' );
                $objects{"$obj\[$category_ref->[0]]"} = $count;
            }
            else {
                $objects{"$obj"} = $count;
            }
        }
    }
    return \%objects;
}

###########################
sub get_Object_Count {
###########################
    #   Input:
    #       Hash reference of objects and their counts
    #   output:
    #       the count of distinct object with count higher than 0  (integer)
###########################
    my $self       = shift;
    my %args       = &filter_input( \@_ );
    my $object_ref = $args{-object};
    my %objects    = %$object_ref if $object_ref;
    my @obj        = keys %objects;
    my $size       = @obj;
    return $size;
}

######################################################
##               Public Methods                     ##
######################################################
#############################
sub get_Actions_Hash {
#############################
    #   Description:
    #       return the reference to a hash contaning the actions
#############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    # core actions for core objects (e.g. Plate, Equipment, Solution, Source, ReArray_Request)
    my $core_actions = {
        'Plate(1-N)+Solution(1-N)'        => 'Add Solution to Plate',               # Core
        'Solution(2-N)'                   => 'Mix Solutions',                       # Core
        'Source(1-N)'                     => 'Source Homepage',                     # Standard Homepage (Standard home page generation using single_record_page and multiple_record_page from alDente::Source_Views)
        'ReArray_Request(1-N)+Plate(1-N)' => 'Validate ReArray Plates',             # Core
        'ReArray_Request(1-N)'            => 'Show ReArray Request',                # Core
        'Plate(1-N)+Equipment(1-1)'       => 'Move to Equipment',                   # 'move_Items',  # Core, Note need to check Equipment category first before using this one
        'Rack(1-N)+Equipment(1-1)'        => 'move Rack',                           # move rack to equipment',  # Core
        'Rack(1-N)+Plate(1-N)'            => 'alDente::Rack_App::move_Object',      # 'move_Items',                # move to rack',            # Core
        'Rack(1-N)+Solution(1-N)'         => 'alDente::Rack_App::move_Object',      # 'move_Items',                # Core
        'Rack(1-N)+Source(1-N)'           => 'alDente::Rack_App::move_Object',      ## move_Items',                # Core
        'Rack(1-N)+Box(1-N)'              => 'alDente::Rack_App::move_Object',      ## move_Items',                # Core
        'Rack(2-N)'                       => 'alDente::Rack_App::scanned_Racks',    ## 'scanned_Racks',              # Core
        'Rack(1-1)'                       => 'Rack home page',                      # Core, This is due to rack not having a standard homepage should be chnaged after rack.pm is revised
        'Box(1-N)'                        => 'Box Homepage',
    };

    # plugin actions for plugin object if the scan in object is not one of the core object;
    my $plugin_actions = $self->get_available_plugin_actions( -dbc => $dbc );
    my $actions = &RGmath::merge_Hash( -hash1 => $core_actions, -hash2 => $plugin_actions );
    return $actions;
}

################################
sub move_to_Equipment {
################################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my $barcode = alDente::Scanner::scanned_barcode('Barcode');    ## Barcode Scanned

    my $equipment_id = get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1 );
    my @racks = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FK_Equipment__ID = $equipment_id" );
    my $count = @racks;
    if ( int(@racks) == 1 && $racks[0] > 0 ) {
        $barcode =~ s/equ\d+/rac$racks[0]/i;
        my $Rack = new alDente::Rack_App( -dbc => $dbc );
        return $Rack->move_Object( -barcode => $barcode );
    }
    elsif ( int(@racks) > 1 ) {
        Message "Multiple racks for EQU$equipment_id . Please scan rack and plate(s)";
    }
    else {
        Message "Not a valid option";
    }
    return;
}

################################
sub get_available_plugin_actions {
################################
    #   Description:
    #       Given a object, find if plugin install, if install, load object and then
    #       return the reference to a hash contaning the actions for the plugin
################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    # <CONSTRUCTION> Need to have a method to find out available plugins to check (still need to be implemented)
    # Currently loading get_Scanner_Actions from alDente::Equipment_App and alDente::Run_App is enough to cover all available scanner actions
    # In alDente::Run_App, it does have further plugin checking for different type of runs

    my @plugins;
    if ( $dbc->table_loaded('Run') ) {
        push @plugins, 'alDente::Run_App';
        push @plugins, 'alDente::GelRun_App';
    }

    my $actions;

    for my $plugin (@plugins) {
        eval "require $plugin";
        my $cmd            = "$plugin" . "::get_Scanner_Actions(-dbc=>\$dbc)";
        my $plugin_actions = eval "$cmd";
        for my $key ( keys %{$plugin_actions} ) {
            $actions->{$key} = $plugin_actions->{$key};
        }
    }
    return $actions;
}

##############################
sub get_Run_Mode {
###########################
    #   Description:
    #       compares given objects and action and returns an action if the combination of objects match the keys in action
    #       the key has to match both the object and the count has to be in range
    #   Input:
    #       two has references , actions and objects
    #   Output:
    #       name of run modes to be runned (array ref) , ref of empty array on failure
    #   Example:
    #       my $run_modes_ref   = $App -> get_Run_Mode (-actions_list => \%actions , -objects => \%objects);
###########################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $actions = $args{-actions_list};
    my $objects = $args{-objects};
    my @run_modes;
    my %objects = %$objects if $objects;
    my %actions = %$actions if $actions;
    my $object_count = $self->get_Object_Count( -object => \%objects );    ## The number of distinct objects

    for my $action_key ( keys %actions ) {
        my $ok           = 1;
        my $action_count = _get_Action_Count( -key => $action_key );       ## the number of objects in the key of %action
        for my $obj ( keys %objects ) {
            unless ( found_match( -object => $obj, -object_count => $objects{$obj}, -run_mode_condition => $action_key ) ) {
                $ok = 0;
                last;
            }
        }
        if ( $ok && $action_count == $object_count ) {
            push @run_modes, $action_key;                                  #$actions{$action_key} ;
        }
    }

    # Go to the more specific run mode if available
    # <CONSTURCTION> Only Equipment uses this currently and maybe can be done better
    # Example: when have Plate(1-N)+Equipment[Sequencer-3730](1-1) and Plate(1-N)+Equipment(1-1) want to go to Plate(1-N)+Equipment[Sequencer-3730](1-1)
    my $count;
    my $index;
    my %unique_run_mode;
    for ( my $i; $i <= $#run_modes; $i++ ) {
        if ( $run_modes[$i] =~ /\[.*\]/ && !$unique_run_mode{ $actions{ $run_modes[$i] } } ) {
            $count++;
            $index = $i;
            $unique_run_mode{ $actions{ $run_modes[$i] } }++;
        }
    }

    #to get actual run modes
    @run_modes = map { $actions{$_} } @run_modes;

    if ( $count == 1 ) { return [ $run_modes[$index] ]; }
    else               { return unique_items( \@run_modes ); }
}

######################
sub run_mode_handler {
######################
    #   Description:
    #       runs a run mode from Scanner_App if the run mode is in Scanner_App
    #       load the App module and run the run mode if the run mode is not from Scanner_App
################################
    my $self        = shift;
    my %args        = &filter_input( \@_ );
    my $mode        = $args{-mode};
    my $barcode     = alDente::Scanner::scanned_barcode('Barcode');    ## Barcode Scanned
    my $objects_ref = $self->param('Objects');
    my $dbc         = $self->param('dbc');

    my $q       = $self->query();
    my $barcode = $q->param('Barcode');

    #Message('run_mode_handler');

    my ( $App, $Run_mode );
    if ( $mode =~ /(.*)::(.*)$/ ) { $App = $1; $Run_mode = $2; }

    if ( $mode =~ /(\w+) Homepage/ ) {
        ## Use standard home page generator (requires standard home page object views methods: single_record, multiple_record, no_record)

        my ( $table, $id ) = $self->_get_barcode_object($barcode);
        if ( !$table || !$id ) { return "ID: $id not found for $table in database (from $barcode)" }

        my $class = 'alDente' . '::' . $table;
        my $ok    = eval "require $class";

        if ( !$ok ) {
            ## try table alias (eg convert Plate -> Container)
            my ($alias) = $dbc->Table_find( 'DBTable', 'DBTable_Title', "WHERE DBTable_Name = '$table'" );
            if ($alias) {
                $class = 'alDente' . '::' . $alias;
                $ok    = eval "require $class";
            }
        }

        my $Object = $class->new( -dbc => $dbc, -id => $id );
        my $View = $Object->View();
        $View->{barcode} = $barcode;

        my $page = $View->std_home_page( -dbc => $dbc, -id => $id, -class => $table, -detailed => $q->param('Detailed') );    ## std_home_page generates default page, with customizations possible via local single/multiple/no _record_page method ##

        return $page;
    }
    elsif ($Run_mode) {

        # Run mode in other App

        #	Message("going to $App -> $Run_mode)");
        eval "require $App";

        #initializing new sub type Run_App and run that app if it exists

        $App = $App->new( PARAMS => { dbc => $dbc } );
        return $App->$Run_mode( -barcode => $barcode, -dbc => $dbc );
    }
    else {
        ## locally defined run mode ##

        #	$App->forward($mode);  ## using CGI::Plugin::Forward
        my %rms    = $self->run_modes();
        my $method = $rms{$mode};

        #	Message("Go to $method");

        if ($method) {
            return $self->$method;
        }
        else {
            $dbc->session->error("'$mode' is an invalid Scanner_App run mode");
        }
    }

    &main::leave($dbc);
}

#########################
sub _get_barcode_object {
#########################
    my $self    = shift;
    my $barcode = shift;
    my $dbc     = $self->param('dbc');

    my ($table) = SDB::CustomSettings::barcode_class($barcode);

    if ($table) {
        use alDente::Validation;
        my $id = get_aldente_id( $dbc, $barcode, $table );
        if ( $id =~ /\d/ ) { return ( $table, $id ) }
        else               { return ($table) }
    }
    return;
}

##############################
# public_functions           #
##############################

#############################
sub found_match {
#############################
    #   Description:
    #       This function decides weather the Object entered and its count match the condition
    #   Input:
    #       Object (database objects or categoires of those objects) + Count (count of that object) + Condition line (which is a '+' seperated list of object and their allowed range in paranthesis)
    #   Output:
    #       Bolean: 1 on match, 0 on no match
    #   Example:
    #       found_match ( -object => 'Plate' ,-object_count => 3, -run_mode_condition => 'Plate(1-N)+Sequencer-MB(1-1)')
#############################
    my %args        = &filter_input( \@_ );
    my $action      = $args{-run_mode_condition};
    my $object      = $args{-object};
    my $count       = $args{-object_count};
    my $found_match = 0;

    #assume objects in action separate by +
    my @run_mode_objects = split( /\+/, $action );

    #check object_type first
    my $object_type;
    if ( $object =~ /\[(.*)\]/ ) {
        $object_type = $1;
        $object =~ s/\[.*\]//;
    }

    my @run_mode_object_types = map {
        my $out = $_;
        if   ( $out =~ /\[(.*)\](.*)/ ) { $out = "$1$2"; }
        else                            { $out = ''; }
        $out;
    } @run_mode_objects;
    @run_mode_objects = map {
        my $out = $_;
        if ( $out =~ /\[.*\]/ ) { $out = ''; }    #if object type available, need to be matched on object type, can't be match on object
        else                    { $out =~ s/\[.*\]//; }
        $out;
    } @run_mode_objects;

    my $match_object;

    #check object_type, run mode object type first to give priority to more specific match
    #use grep to find object, \b to avoid partial match
    if ($object_type) {
        ($match_object) = grep( /\b$object_type\b/, @run_mode_object_types );

        #check for category/subcategory match for object_type, only allow this if run mode object type is not specific
        if ( !$match_object ) {
            @run_mode_object_types = map {
                my $out = $_;
                if ( $out =~ /.*-.*-/ ) { $out = ''; }    # i.e. take out full category/subcategory entry
                $out;
            } @run_mode_object_types;

            #start matching object_type_parts
            my @object_type_parts = split( /-/, $object_type );
            for my $object_type_part (@object_type_parts) {
                ($match_object) = grep( /\b$object_type_part\b/, @run_mode_object_types ) if $object_type_part;
                last if $match_object;
            }
        }
    }

    #lastly, check object
    if ( !$match_object ) {
        ($match_object) = grep( /\b$object\b/, @run_mode_objects );
    }

    #found object, checking count range
    if ($match_object) {

        #assume range in (*-*) format
        if ( $match_object =~ /\((.*)-(.*)\)/ ) {
            my $low  = $1;
            my $high = $2;
            if ( $count >= $low && ( $count <= $high || $high eq 'N' ) ) { $found_match = 1 }
        }
    }

    return $found_match;
}

#############################
sub _get_Action_Count {
#############################
    my %args  = &filter_input( \@_ );
    my $key   = $args{-key};
    my $count = 1;
    while ( $key =~ s/\+/ / ) { $count++ }
    return $count;

}

######################################################
##          Run Modes : Actions                     ##
######################################################
###########################
sub validate_ReArray_Plates {
###########################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my $barcode = alDente::Scanner::scanned_barcode('Barcode');    ## Barcode Scanned

    my $rearray = &get_aldente_id( $dbc, $barcode, 'ReArray_Request' );
    my $plates  = &get_aldente_id( $dbc, $barcode, 'Plate' );

    require Sequencing::ReArray;
    my $seq_rearray_obj = new Sequencing::ReArray( -dbc => $dbc );
    $seq_rearray_obj->validate_source_plates( -request_ids => $rearray, -source_plates => $plates );

}

###########################
sub show_ReArray_Request {
###########################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my $barcode = alDente::Scanner::scanned_barcode('Barcode');    ## Barcode Scanned

    my $rearray_id = my $solution_id = get_aldente_id( $dbc, $barcode, 'ReArray_Request', -validate => 1 );

    my $page;
    if ($scanner_mode) {
        Message("Rearrays should be viewed with desktop, aborting...");
    }
    else {
        require alDente::ReArray_Views;
        $page .= alDente::ReArray_Views::view_rearrays( -dbc => $dbc, -request_ids => $rearray_id );
    }

    return $page;
}

###########################
sub display_Library_homepage {
###########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query;

    my $barcode = $args{-library} || $q->param('Barcode');    ## Barcode Scanned (NOT decrypted !)

    require alDente::Library_App;
    my $library_view = new alDente::Library_Views( -dbc => $dbc, -library => $barcode );
    return $library_view->home_page( -library => $barcode, -dbc => $dbc );
}

###########################
sub mix_Solutions {
###########################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my $barcode = alDente::Scanner::scanned_barcode('Barcode');    ## Barcode Scanned

    my $solution_id = get_aldente_id( $dbc, $barcode, 'Solution', -validate => 1 );
    my $page;
    if ( $solution_id =~ /,/ ) {
        my $sols = int( my @list = split ',', $solution_id );

        my $Sol = alDente::Solution->new( -id => $solution_id, -dbc => $dbc );
        $page .= $Sol->display_solution_options( -dbc => $dbc, -solution_ids => $solution_id );

        $solution_id = alDente::Validation::get_aldente_id( $dbc, $barcode, 'Solution', -validate => 1, -qc_check => 1, -fatal_flag => 1 );
        if ($solution_id) {
            eval "require alDente::Solution_App";
            my $webapp = alDente::Solution_App->new( PARAMS => { dbc => $dbc, solutions => $sols, ids => $solution_id } );

            #            $webapp->start_mode('Mix Standard Solution');
            $page .= $webapp->display_standard_solution_page;    ## run();
        }
    }
    return $page;
}

###########################
sub pool_Sources {
###########################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my $barcode = alDente::Scanner::scanned_barcode('Barcode');    ## Barcode Scanned

    if ( $barcode =~ /Src(\d+)/i ) {
        my $list = get_aldente_id( $dbc, $barcode, 'Source' );

        require alDente::Info;                                     ## dynamically load module ##
        if ( $list =~ /^(\d+)/ ) {
            &alDente::Info::GoHome( $dbc, 'Source', $1, -list => $list );
        }
        else {
            Message("Invalid Source ID ($barcode)");
            &main::home('main');
        }
        &main::leave($dbc);
    }
}

################################
sub add_Solution_to_Plate {
################################
    my $self    = shift;
    my %args    = @_;
    my $dbc     = $self->param('dbc') || $args{-dbc};
    my $barcode = alDente::Scanner::scanned_barcode('Barcode');    ## Barcode Scanned

    &alDente::Scanner_Views::Validate_Solution( $dbc, $barcode );
    return '<hr>';
}

##############################
sub move_plate_to_equipment {
##############################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my $barcode = alDente::Scanner::scanned_barcode('Barcode');    ## Barcode Scanned

    my $possible_move = 0;
    my $equipment_list = &get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1, -quiet => 1 );
    if ( $equipment_list !~ /,/ ) {

        # check to see if the equipment has a single rack
        # if it does, it is possible to move the rack to that equipment
        my @rack_id = $dbc->Table_find( "Rack", "Rack_ID", "WHERE FK_Equipment__ID = $equipment_list" );
        if ( int(@rack_id) == 1 && $rack_id[0] > 0 ) {
            $possible_move = $rack_id[0];
        }
    }

    if ($possible_move) {
        $barcode =~ s/equ\d+/rac$possible_move/i;
        $self->param( 'Barcode' => $barcode );

        #&alDente::Rack::Rack_home( $dbc, $possible_move, $barcode );

        my $Rack_App = alDente::Rack_App->new( PARAMS => { dbc => $dbc } );
        $Rack_App->move_Object();
    }
    else {
        Message("Warning: Cannot apply plate to any equipment type (only some). Please use a protocol");
    }
}

# PHASE OUT ... use standard home page generator instead ... ##
##########################
sub Source_home_page {
##########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $barcode = alDente::Scanner::scanned_barcode('Barcode');

    my $ids = get_aldente_id( $dbc, $barcode, 'Source' );

    return $self->View( -class => 'alDente::Source_Views', -id => $ids )->home_page( -dbc => $dbc, -id => $ids );

}

###### Rack run modes accessible directly via Scanner_App ######

########################
sub Rack_home_page {
###################
    my $self    = shift;
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $barcode = alDente::Scanner::scanned_barcode('Barcode');

    my ( $action, $Found ) = alDente::Rack::determine_action( $dbc, $barcode );

    my $Rack_App = alDente::Rack_App->new( PARAMS => { dbc => $dbc } );
    return $Rack_App->home_page( $Found->{Rack}[0] );
}

##################
sub move_Rack {
##################
    my $self    = shift;
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $barcode = alDente::Scanner::scanned_barcode('Barcode');

    my ( $action, $Found ) = alDente::Rack::determine_action( $dbc, $barcode );

    my @racks = grep /$Prefix{Rack}(\d+)/, @{ $Found->{Rack} };
    my $rack_list = join ',', @racks;
    $rack_list =~ s/$Prefix{Rack}//g;

    my $equip = &get_aldente_id( $dbc, $Found->{Equipment}[0], 'Equipment', -validate => 0 );
    my $page = alDente::Rack_Views::move_Rack( -dbc => $dbc, -source_racks => $rack_list, -equip => $equip );
    return $page;
}

###################
sub move_Items {
###################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $Rack_App = alDente::Rack_App->new( PARAMS => { dbc => $dbc } );
    return $Rack_App->move_Object();

}

#######################
sub scanned_Racks {
#######################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $Rack_App = alDente::Rack_App->new( PARAMS => { dbc => $dbc } );
    return $Rack_App->scanned_Racks();
}

1;
