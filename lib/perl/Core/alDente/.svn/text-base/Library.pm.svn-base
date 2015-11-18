package alDente::Library;

##############################
# piled_header             #
##############################

=head1 NAME <UPLINK>

Library.pm - 


=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

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

##############################
# custom_modules_ref         #
##############################
use alDente::Form;
use alDente::SDB_Defaults;
use alDente::Security;
use alDente::Goal_App;
use alDente::Tools;
use alDente::Original_Source_Views;
use alDente::Library_Views;
use alDente::Attribute_Views;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::DB_Form_Viewer;
use SDB::DB_Object;
use SDB::DB_Form;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Conversion;
use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::RGmath;
use alDente::Grp;
##############################
# global_vars                #
##############################
use vars qw($homefile $user $barcode $plate_id $last_page $image_dir);
use vars qw(@libraries @plate_info);
use vars qw($MenuSearch $URL_temp_dir);
use vars qw( $project $dbase $user );
use vars qw($testing);
use vars qw(%Settings);
use vars qw($Security $URL_dir_name $Current_Department);
use vars qw($Connection);

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
# Define security checks (alphabetical order please!)
my %Checks;

# Define items that can be viewed(alphabetical order please!)
my %Views;
$Views{'-'} = { 'Cap_Seq' => 'Lab', 'Mapping' => 'Lab', 'Lib_Construction' => 'Lab' };
$Views{Library} = { 'Cap_Seq' => 'Admin', 'Mapping' => 'Admin', 'Lib_Construction' => 'Admin' };

# Define items that can be searched (alphabetical order please!)
my %Searches;
$Searches{'-'} = { 'Cap_Seq' => 'Lab', 'Mapping' => 'Lab', 'Lib_Construction' => 'Lab' };
$Searches{Library} = { 'Cap_Seq' => 'Admin', 'Mapping' => 'Admin', 'Lib_Construction' => 'Admin' };

# Define items that can be created (alphabetical order please!)
my %Creates;
$Creates{'-'} = { 'Cap_Seq' => 'Lab', 'Mapping' => 'Lab', 'Lib_Construction' => 'Lab' };
$Creates{Library} = { 'Cap_Seq' => 'Admin', 'Mapping' => 'Admin', 'Lib_Construction' => 'Admin' };

# Define labels (alphabetical order please!)
my %Labels;
%Labels = ( '-' => '--Select--' );
$Labels{Library} = 'Libraries';

##############################
# constructor                #
##############################

#
# Constructor - initiate with
#
###########
sub new {
###########
    my $this   = shift;
    my %args   = @_;
    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $lib_id = $args{-lib_id} || $args{-id} || $args{-name} || $args{-library};
    my $tables = $args{-tables};
    unless ($tables) { $tables = [ 'Library', 'Original_Source' ] }

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => $tables );

    my $class = ref($this) || $this;
    bless $self, $class;

    $self->{dbc} = $dbc;

    if ($lib_id) {
        $self->primary_value( -table => 'Library', -value => $lib_id );
        $self->{id} = $lib_id;
        $self->load_Object();
    }

    return $self;
}

##############
sub load_Object {
##############
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $id   = $self->{id};
    my $dbc  = $self->{dbc};

    my ($type) = $dbc->Table_find( 'Library', 'Library_Type', "WHERE Library_Name = '$id'" );

    if ( $dbc->table_loaded($type) ) {
        $self->add_tables($type);
    }

    my @linked_sources = $dbc->Table_find( 'Library_Source', 'FK_Source__ID', "WHERE FK_Library__Name = '$id'", -distinct => 1 );
    if ( int(@linked_sources) == 1 ) {
        $self->add_tables( 'Source', "Source_ID = $linked_sources[0]" );
    }

    $self->SUPER::load_Object(%args);
    $self->set( 'DBobject', $type );
    return;
}

##############################
# public_methods             #
##############################

##########
# New accessors/mutators
##########
##############
sub home_info {
##############
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $id   = $self->{id};

    require alDente::Library_App;
    my $library_view = new alDente::Library_Views( -dbc => $dbc, -library => $id );
    print $library_view->home_page( -library => $id, -dbc => $dbc );
    return 1;
}

#####################
sub approve_Project_Change {
#####################
    # Description
    #     checks to see if the project for the library can be changed
    # Input:
    #
    # Output:
    #     (1 for pass NULL for fail)
#####################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $id   = $self->{id};
    unless ($id) {
        $dbc->error("No Library Supplied");
        return;
    }

    my @run_ids = $dbc->Table_find( 'Run, Plate', "Run_ID", "WHERE FK_Plate__ID = Plate_ID AND FK_Library__Name = '$id' " );
    my $list = join ',', @run_ids;

    if ($list) {
        $dbc->warning("Cant change project for library $id since runs have already been created (IDS: $list)");
        return;
    }
    else {
        return 1;
    }

    return;
}

#####################
sub change_Project {
#####################
    # Description
    #     Changes project for library
    #     moves the files only if database is production
    # Input:
    #     project_name
    # Output:
#####################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $self->{dbc};
    my $id      = $self->{id};
    my $project = $args{-project};        ## name

    my $original_proj = $self->value('FK_Project__ID');

    my ($first) = $dbc->Table_find( 'Project', "Project_Path", " WHERE Project_ID =   $original_proj " );
    my ($sec_id) = $dbc->get_FK_ID( "FK_Project__ID", $project );
    my ($second) = $dbc->Table_find( 'Project', "Project_Path", " WHERE Project_ID =   $sec_id " );

    my $origin       = $Configs{project_dir} . '/' . $first;
    my $dest         = $Configs{project_dir} . '/' . $second;
    my $move_command = "mv $origin/$id $dest/";

    my $ok = $dbc->Table_update_array( 'Library', ["FK_Project__ID"], [$sec_id], "where Library_Name = '$id' " );
    my $mode = $dbc->mode();
    if ( $mode eq 'PRODUCTION' && !$dbc->test_mode() ) {
        my $response = try_system_command($move_command);
        Message $response if $response;
    }
    else {
        Message "Not Actually moving files since (MODE: $mode)";
    }

    return;
}

#######################################
#
#######################################
# use DB_Object's update to simulate commits. Might need integrity check to make sure all required
# fields are filled out correctly
sub update {
    my $self = shift;

    # just use SDB::DB_Object->update, but leave a hook for customized integrity checking
    $self->_integrity_check();
    $self->SUPER::update();
}

#######################################
#
#######################################
sub library_plates {
##################
    my $self = shift;

    my %args = &filter_input( \@_, -args => 'library,plate_number,id_list' );
    my $lib  = $args{-library};
    my $num  = $args{-plate_number};
    my $id   = $args{-id_list};
    my $dbc  = $self->{dbc};

    if ( $lib =~ /(.*):/ )     { $lib = $1; }
    if ( $id  =~ /pla(\d+)/i ) { $id  = $1; }

    $num = extract_range($num);

    my $lib_spec;
    my $id_spec;
    my $num_spec;

    if ($lib) { $lib_spec = " and FK_Library__Name = '$lib'"; }
    else      { print "Library Name must be supplied for plate info"; return (); }
    if ( $id  =~ /\d+/ ) { $id_spec  = " and Plate_ID in ($id)"; }
    if ( $num =~ /\d+/ ) { $num_spec = " and Plate_Number in ($num)"; }

    my @plate_info = $dbc->Table_find_array(
        'Plate,Plate_Format,Library_Plate',
        ["concat('Pla',Plate_ID,': ',FK_Library__Name,' ',Plate_Number,' ',Plate.Parent_Quadrant,' ',Plate_Format_Type)"],
        "where FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID=FK_Plate__ID $lib_spec $num_spec $id_spec"
    );

    return @plate_info;
}

#########
# HTML generator pages - might be worthwhile to transfer to a perl script to be more object-oriented
# However, might want to include for historical/reverse compatability with other scripts
#########
#
# output HTML for main library page
#
###################
sub library_main {
###################
    #
    # <CONSTRUCTION> - this should be one method here with input parameters if possible to handle differences between Sequencing Library and RNA_DNA_Collection displays.
    #
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $add_views  = $args{-add_views};
    my $add_layers = $args{-layers};
    my $add_links  = $args{-add_links};
    my $sub_types  = $args{-sub_types};

    my $common_objects = $args{-objects}        || [];
    my $view_objects   = $args{-view_objects}   || ['Library'];
    my $search_objects = $args{-search_objects} || [];
    my $add_objects    = $args{-add_objects}    || [];
    my $labels         = $args{-labels};
    my $get_layers     = $args{-get_layers};
    my $return_html = $args{-return_html};    ###If specify, that means this routine will return the content and merged into another form.
    my $form_name   = $args{-form_name};
    my $dbc         = $self->{dbc};

    my $libraries = $args{-libraries};        ## faster if supplied directly
    my $projects  = $args{-projects};

    my $lib_alias;
    if   ( defined $labels->{'Library'} ) { $lib_alias = $labels->{'Library'}; }
    else                                  { $lib_alias = 'Library' }
    my $access = $dbc->get_local('Access')->{ $dbc->config('Target_Department') };

    my $admin = 0;
    if ( grep( /Admin/i, @{$access} ) ) {
        $admin = 1;
    }
    ## add common objects to view / search / add objects
    if ($common_objects) {
        $view_objects   = [ @$common_objects, @$view_objects ];
        $search_objects = [ @$common_objects, @$search_objects ];
        $add_objects    = [ @$common_objects, @$add_objects ];
    }

    ## extract parameters if generated by internally passed parameters ##
    my $project = get_Table_Param( -dbc => $dbc, -field => 'Project_Name', -table => 'Project', -autoquote => 1 );
    my $library = get_Table_Param( -dbc => $dbc, -field => 'Library_Name', -table => 'Library', -autoquote => 1 );
    my $type    = get_Table_Param( -dbc => $dbc, -field => 'Library_Type', -table => 'Library', -autoquote => 1 );

    if ($library) { }
    elsif ($type) {
        $library = join ',', $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Type like '$type'" );
    }
    elsif ($project) {
        $library = join ',', $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID AND Project_Name like '$project'" );
    }

    my $object_class = param('Object_Class');

    my $action = param('Action');
    my $object = param('Library Object');    ## action on this object

    ## Branch as applicable if handling return parameters ... ##
    my $condition = 1;
    if ($project) {
        $condition .= " AND Project_Name IN ($project)";
    }
    if ($library) {
        my $lib_list = $library;
        $lib_list =~ s/,/','/g;
        $condition .= " AND Library_Name IN ('$lib_list')";
    }
    if ($type) {
        $condition .= " AND Library_Type IN ('$type')";
    }

    my $table;
    ## Check for input parameters for viewing / searching / adding records ##
    if ( $action =~ /View/i ) {
        ## Just list the chosen objects ##

        if ( grep /^$object$/, @$view_objects ) {
            Message("View $object records... ($project / $library)");
            $dbc->Table_retrieve_display( $object, '*', $condition );
            return 1;
        }
        else { Message("No views available for $object records"); }

    }
    elsif ( $action =~ /search/i ) {
        ## allow user to search for the chosen object ##
        my $edit = param('Multi-Record');
        Message("Search option chosen... (edit = $edit)");
        if ( grep /^$object$/, @$search_objects ) {
            if ( param('Multi-Record') ) {
                &SDB::DB_Form_Viewer::edit_records( $dbc, $object );
            }
            else {    ## single record search/edit...
                &SDB::DB_Form_Viewer::Table_search( -dbc => $dbc, -tables => $object );
            }

            Message("Search/Edit $object records... ($project / $library)");
            return 1;
        }
        else { Message("No search/editing available for $object records"); }
    }
    elsif ( $action =~ /record/i ) {
        ### Allow user to add new record for chosen object ##
        if ( grep /^$object$/, @$add_objects ) {
            my %config_hash;
            if ($library) {
                my ($vector) = $dbc->Table_find( 'LibraryVector', 'FK_Vector__ID', "WHERE FK_Library__Name IN ($library)" );
                $config_hash{preset}{'FK_Library__Name'} = $library;
                $config_hash{preset}{'FK_Vector__ID'}    = $vector;

                if ( $Current_Department =~ /Cap_Seq/ ) {

                    # why is this here ? #
                    $config_hash{'omit'}{'FKParent_Branch__Code'} = '';
                    $config_hash{'omit'}{'FK_Pipeline__ID'}       = '';
                }
            }

            &SDB::DB_Form_Viewer::add_record(
                 $dbc, $object,
                -groups  => $dbc->get_local('group_list'),
                -configs => \%config_hash
            );
            return 1;
        }
        else {
            Message("Unidentified redirection for Adding $object record.");
        }
    }
    elsif ( param('Check Submissions') ) {
        return $dbc->error("This run mode has been moved... please check with LIMS to correct");
    }
    ### check for parameters returned via this form ###
    elsif ( param('View LibraryApplication') ) {
        my $library_application = alDente::LibraryApplication->new( -dbc => $dbc );
        $library_application->view_application( -library => $library, -object_class => $object_class );
        return 1;
    }
    elsif ( param('List Libraries') ) {

        if ( param('Verbose') ) {
            print SDB::DB_Form_Viewer::view_records( $dbc, 'Library', 'Library_Name', $library );
        }
        elsif ( !$library ) {
            print SDB::DB_Form_Viewer::view_records( $dbc, 'Library' );
        }
        else {
            my ($Lib_Type) = $dbc->Table_find( 'Library', 'Library_Type', "WHERE Library_Name IN ('$library')" );
            my $object = "alDente::Library";
            if ( $Lib_Type =~ /RNA\/DNA/ ) {
                $object = "alDente::RNA_DNA_Collection";

                #} elsif ($Lib_Type =~ /^Mapping/) {
                #$object = "alDente::Mapping_Library";
            }
            else {
                ## if  ($Lib_Type =~ /^Sequencing/)
                $object = "Sequencing::Sequencing_Library";
            }
            my $lib = $object->new( -dbc => $dbc );
            if ( $project || $type ) {
                $lib->library_info( '', $project, $type );
            }
            else {
                $lib->library_info($library);
            }
        }
        return 1;
    }
    elsif ( param('New Library Page') ) {
        my $lib_type;

        if ( param('New Library Page') && $admin ) {
            if    ( $Current_Department eq 'Cap_Seq' )          { $lib_type = 'Sequencing_Library' }
            elsif ( $Current_Department eq 'Lib_Construction' ) { $lib_type = 'RNA_DNA_Collection' }
        }
        ### Prompt for specifics of this case to direct to proper forms ###
        &alDente::Library::initialize_library( -type => $lib_type );

    }

    #    elsif (param('Prompt for Submit Library')) {
    #	my $lo = new alDente::Library(-dbc=>$dbc);
    #	$lo->prompt_for_submit_library();
    #	return 1;
    #    }
    #    elsif (param('Prompt for Resubmit Library')) {
    #	my $lo = new alDente::Library(-dbc=>$dbc);
    #	$lo->prompt_for_resubmit_library();
    #	return 1;
    #    }
    elsif ( param('Prompt for Submit Work Request') ) {

        #		my $lo = new alDente::Library(-dbc=>$dbc);
        #		$lo->prompt_for_work_request();
        #		return 1;
        use alDente::Submission_App;
        my $submission = alDente::Submission_App->new( PARAMS => { dbc => $dbc } );
        $submission->run();
        return 1;
    }
    ##############################################################
    # If not redirected - generate standard Library home page
    ##############################################################
    # Set security checks
    $dbc->Security->security_checks( \%Checks );
    my $prefix;
    if ($return_html) {
        $form_name ||= $return_html;
    }
    else {
        $form_name ||= 'Library_Main';
    }
    $prefix = alDente::Form::start_alDente_form( $dbc, $form_name );

    #    get_enum_list
    my @projects = $dbc->Table_find( 'Library,Project', 'Project_Name', "where Project_ID=FK_Project__ID Order by Project_Name", 'Distinct' );
    my @L_status_types = &SDB::DBIO::get_enum_list( $dbc, 'Library', 'Library_Status' );

    ##################################################################
    # Applicable Layers
    ##################################################################
    my %layers;

    #$layers{"Search for $lib_alias Information"} = &alDente::View::View_Home(-scope=>'library'); ## <CONSTRUCTION> - id temporary..

    my $Libraries = alDente::Form::init_HTML_table("$lib_alias options");
    $Libraries->Set_Column_Widths( [200], [0] );

    my $new_lib_link = '';
    if ( grep /^(admin|bioinf)/i, @$access ) {
        ## Admin users have link to direct database updating ##
        $new_lib_link .= &Link_To( $dbc->config('homelink'), "New $lib_alias", "&New Library Page=1&Target=Database" ) . hspace(40);
    }
    ## non-admin users only get submit for approval option ##
    $new_lib_link .= &Link_To( $dbc->config('homelink'), "Submit for Approval", "&New Library Page=1&Target=Submission" ) . hspace(40);

    $new_lib_link .= "<< use same links to add a <B>Sample_Origin</B>";

    $Libraries->Set_Row( [ "<B>Define New $lib_alias:</B>", $new_lib_link ] );
    $Libraries->Set_sub_header('<hr>');

    my $tip = "Generates more concise info when viewing libraries, library primers, vector/primers and suggesting new library primers";

    my @type_prompt = ();
    if ($sub_types) {
        @type_prompt = (
            "$lib_alias Type:",
            Show_Tool_Tip(
                RGTools::Web_Form::Popup_Menu( name => 'Library_Type', values => [ "", @$sub_types ], default => "", onChange => "SetSelection(document.$form_name,'Library Name',''); SetSelection(document.$form_name,'Project Name','');", -force => 1 ),
                $tip
            )
        );
    }
    my $groups = $dbc->get_local('group_list');

############################
## We want to show all the Libraries for groups in the department of the current tab as well as the child groups of that department.
## Eg. Alan has Mapping and Sequencing priviledge.  When he is in the Mapping tab and goes to Library option, he will see all the Libraries for the Mapping Group as well as Libraries of the parent group (e.g. Public).  When he goes to Library option in the Sequencing tab, he will see the Libraries for the Sequencing and Public but NOT the Mapping ones.
###########################
    my $current_department = $dbc->config('Target_Department');
    my @child_grps         = $dbc->Table_find( 'Grp,Department', 'Grp_ID', -condition => "where department_name = '$current_department' and fk_department__id = department_id", -debug => 0 );
    my $child_groups       = '';

    if (@child_grps) {
        for my $grp (@child_grps) {
            my $child_grp = alDente::Grp->get_child_groups( -group_id => $grp, -dbc => $dbc );
            if   ( $child_groups eq '' ) { $child_groups = $child_grp; }
            else                         { $child_groups = $child_groups . "," . $child_grp; }

        }

    }

    my @child_depts = $dbc->Table_find( 'Department,Grp', 'Department_Name', -condition => "where grp_id in ($child_groups) and department_id = fk_department__id", -debug => 0 );

    push( @child_depts, $Current_Department );
    my $new_list = RGTools::RGIO::unique_items( \@child_depts );
    my $departments = Cast_List( -list => $new_list, -to => 'string', -delimiter => ',', -autoquote => 1 );

    my @library_prompt = (
        "$lib_alias Name:",
        &alDente::Tools::search_list(
            -dbc              => $dbc,
            -form             => $form_name,
            -name             => 'Library.Library_Name',
            -join_tables      => 'Grp,Department',
            -join_condition   => "Library.FK_Grp__ID=Grp_ID AND Grp.FK_Department__ID=Department_ID",
            -option_condition => "Grp_ID IN ($groups) AND Department_Name IN ($departments)",
            -options          => $libraries,
            -default          => '',
            -search           => 1,
            -filter           => 1
        )
    );
###################################

    my @project_prompt = (
        "By Project:",
        &alDente::Tools::search_list(
            -dbc              => $dbc,
            -form             => $form_name,
            -name             => 'Project.Project_Name',
            -join_tables      => "Library,Grp,Department",
            -join_condition   => "Library.FK_Grp__ID=Grp_ID AND Grp.FK_Department__ID=Department_ID AND FK_Project__ID=Project_ID",
            -option_condition => "Grp_ID IN ($groups) AND Department_Name IN ('$Current_Department')",
            -default          => '',
            -search           => 1,
            -filter           => 1
        )
    );

    $Libraries->Set_Row( ['<B>Other options:</B>'] );
    $Libraries->Set_Row( [ '', @project_prompt ] );
    $Libraries->Set_Row( [ 'Filter:', @type_prompt ] );
    $Libraries->Set_Row( [ '', @library_prompt ] );

    #    $libraries->Set_Row(['Filter:',
    #			 &Views::Table_Print(content=>[
    #						       [@project_prompt],
    #						       [@type_prompt],
    #						       [@library_prompt]
    #
    #						       ],
    #					     class=>'small',bgcolour=>'#d8d8d8', print=>0)
    #			 ]);

    $Libraries->Set_Alignment( 'right', 2 );

    my @objects;
    map {
        my $object = $_;
        unless ( grep /\b$object\b/, @objects ) { push( @objects, $object ); }
    } @$view_objects, @$search_objects;

    ### <CONSTRUCTION> - replace automatic loader with Go buttons... ###
    my $views
        = submit( -name => 'List Libraries', -value => "List $lib_alias Info", -class => 'Std' )
        . checkbox( -name => 'Verbose' )
        . &hspace(10)
        . submit( -name => 'View LibraryApplication', -value => "List Associated Reagents", -class => 'Std' )
        . &hspace(10);

    #	    radio_group(-name=>'Object_Class',-values=>['Primer','Antibiotic']) . &hspace(10);
    if ($add_views) {
        foreach my $view (@$add_views) {
            $views .= $view . &hspace(10);
        }
    }
    $Libraries->Set_sub_header( hr . $views );    ## top half of options / form .

    my $Libraries2 = alDente::Form::init_HTML_table('Library associations');
    $Libraries2->Set_Column_Widths( [200], [0] );

    my $search_for_objects = radio_group(
        -name      => 'Library Object',
        -values    => \@objects,
        -labels    => $labels,
        -linebreak => 1
    );

    $Libraries2->Set_Column(
        [ $prefix . hidden( -name => 'Standard Page', -value => 'Library' ) . $search_for_objects . "<br>" . checkbox( -name => 'Multi-Record', -label => 'Edit' ) . lbr . submit( -name => 'Action', -value => 'Search', -class => 'Std' ) . end_form() ] );

    if ($admin) {
        my $add_options = radio_group(
            -name      => 'Table',
            -values    => $add_objects,
            -labels    => $labels,
            -linebreak => 1
        );
        if (@$add_objects) {
            $Libraries2->Set_Column( [ $prefix . $add_options . hidden( -name => 'cgi_application', -value => 'SDB::DB_Object_App', -force => 1 ) . lbr . submit( -name => 'rm', -value => 'Add Record', -class => 'Std' ) . end_form() ] );
        }
    }

    ## Add custom links and/or layers to view ##
    if ($add_links) {
        $Libraries2->Set_Row($add_links);
    }

    $Libraries2->Set_Column_Widths( [ '50%', '50%' ] );

    $layers{"$lib_alias Options"} .= $prefix . $Libraries->Printout(0) . end_form();

    $layers{"$lib_alias Options"} .= $Libraries2->Printout(0) . end_form();

    ## Add links to (re)submit libraries from plates or sources ##
    my $librarysubmissions = '';

    if ( $dbc->package_active('Submissions') ) {

        my $Libraries3 = alDente::Form::init_HTML_table('Library Submissions');

        #    my @seq_lib_formats = ('-','Ligation','Microtiter','Xformed_Cells');
        #    my %labels = ('-'=>'--Select--');
        #    $labels{Microtiter} = 'Microtiter Plates';
        #    $labels{Xformed_Cells} = 'Transformed Cells';

        #    $Libraries3->Set_Row([submit(-name=>'Prompt for Submit Library',-label=>'Submit New Library',-class=>"Std")]);
        #    $Libraries3->Set_Row([submit(-name=>'Prompt for Resubmit Library',-label=>'Resubmit Library',-class=>"Std")]);

        #my $submit_work = submit(-name=>'Prompt for Submit Work Request',-label=>'Submit Sequencing Work Request',-class=>"Std");
        #my $submission = alDente::Submission_App->new( -PARAMS => { -dbc => $dbc } );
        require alDente::Submission_Views;
        my $submission_views = new alDente::Submission_Views( -dbc => $dbc );
        my $submit_work = $submission_views->display_work_request_button( -dbc => $dbc );
        $Libraries3->Set_Row( [$submit_work] );

        #	require alDente::Submission;
        #	my $submission = alDente::Submission->new();
        #	my $submission_search =  $submission->display_submission_search_form(-groups=>$groups);
        #	$Libraries3->Set_Row([$submission_search->Printout(0)]);

        $librarysubmissions = $Libraries3->Printout(0);

        require alDente::Work_Request_Views;
        my $work_request_link = alDente::Work_Request_Views::display_work_request_links($dbc);

        # $Libraries3->Set_Row([$work_request_link]);

        my $submission_search_form = $submission_views->display_submission_search_form( -dbc => $dbc, -groups => $groups );

        # $Libraries3->Set_Row([$submission_search_form]);
        # $librarysubmissions = $Libraries3->Printout(0);
    }
    $layers{"$lib_alias Options"} .= $prefix . hidden( -name => 'Standard Page', -value => 'Library' ) . $librarysubmissions . end_form();

    if ($add_layers) {
        foreach my $layer ( keys %$add_layers ) {
            if ( defined $layers{$layer} ) {
                $layers{$layer} .= hr . $add_layers->{$layer};
            }
            else {
                $layers{$layer} = $add_layers->{$layer};
            }
        }
    }

    ## generate layers ##
    my $content = &define_Layers( -layers => \%layers, -format => 'tab', -default => "$lib_alias Options", -tab_width => 300 );

    ## return appropriate value ##
    if ($return_html) {
        return $content;
    }
    elsif ($get_layers) {
        my %returnLayers;
        ### extract the layers requested ###
        map {
            if ( $get_layers =~ /(1|all|\b$_\b)/i ) { $returnLayers{$_} = $layers{$_} }
        } keys %layers;
        return \%returnLayers;
    }
    else {
        print $content;
        return 1;
    }
}

###################
sub reset_Status {
###################
    my $dbc                 = shift;
    my $lib                 = shift;
    my $set_peripheral_info = shift;    # will run set_work_request_percent_complete as well

    my @library_list = Cast_List( -list => $lib, -to => 'array' );

    my ( $closed, $opened, $messages ) = alDente::Goal::set_Library_Status( -dbc => $dbc, -library => \@library_list, -set_peripheral_info => $set_peripheral_info );
    my @closed_list  = @$closed;
    my @opened_list  = @$opened;
    my @message_list = @$messages;

    my $mail = "Libraries Changed:<UL>\n";
    foreach my $mess (@message_list) {
        $mail .= "<LI>$mess</LI>\n";
    }
    $mail .= "</UL\n";

    if (@message_list) {

        #        alDente::Subscription::send_notification(-dbc=>$dbc,-name=>'Library_Status Updates',-from=>'set_Library_Status <aldente@bcgsc.bc.ca>',
        #            -subject=>"Automated Library Status Updates",
        #            -body=>"",-content_type=>'html');
    }
    return ( $closed, $opened, $messages );
}

###########################################################################################
#
# A wrapper to prompt the user for information to streamline the library creation process.
# Prompts will depend upon:
#  - if the original source is:
#    - already defined (just point to it)
#    - to be defined for the first time (included in form).
#
# AND...
#
#  - if the source is to be:
#    - tracked now (included in forms),
#    - tracked later (not added)
#    - not tracked (populated in the background)
#
#########################
sub initialize_library {
#########################
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $target = $args{-target};

    my @types = $dbc->get_enum_list( 'Library', 'Library_Type' );

    my $default_type;

    #if ($Current_Department eq 'Sequencing') {
    #    $default_type = 'Sequencing';
    #} elsif ($Current_Department eq 'Mapping') {
    if ( $Current_Department eq 'Mapping' ) {
        $default_type = 'Vector_Based';
    }
    elsif ( $Current_Department eq 'Lib_Construction' ) {
        $default_type = 'RNA/DNA';
    }

    #    my $dbc = $dbc;
    print &Views::Heading("Creating a New Library");
    my $form_name = "New_Library_Page";

    my $Page = HTML_Table->new( -colour => 'white' );

    #    $Page->Set_Alignment('left');
    $Page->Set_Padding(10);
    $Page->Set_Spacing(5);
    my $arrow = "<Img src='/$URL_dir_name/$image_dir/right_arrow.png' alt='->'>";
    $Page->Set_Row(
        [   "<B>Sample_Origin (Original_Source)</B><BR>Details of the Origin of the sample.<BR>(eg Tissue, Organism, Strain etc)",
            $arrow,
            "<B>Sample_Material (Source)</B><BR>Library Segment or Physical source material from which samples will be extracted.<BR>(eg. Format, Amount etc)<BR>barcoded as a 'SRC'" . "<BR><img src='/$URL_dir_name/$image_dir/stripe.png'>",
            $arrow,
            "<B>Collection (Library)</B><BR>Numbered group of samples.<BR>(defines labelled names used for plates/tubes)",
            $arrow,
            "<B>Plates / Tubes</B><BR>Samples tracked in the lab.<BR>(named after Library; numbered)<BR>barcoded as a 'PLA'" . "<BR><img src='/$URL_dir_name/$image_dir/stripe.png'>",
        ]
    );

    ## define colour to illustrate forms which will be required ##
    my $on  = "#66ff66";
    my $off = "#999999";
    my $med = "#ffcc33";

    $Page->Set_Cell_Colour( 1, 1, $on );
    $Page->Set_Cell_Colour( 1, 3, $on );
    $Page->Set_Cell_Colour( 1, 4, $on );
    $Page->Set_Cell_Colour( 1, 5, $on );
    $Page->Set_Column_Widths( [ 200, 0, 200, 0, 200, 0, 200 ] );

    my $Legend = HTML_Table->new( -colour => 'white', -padding => 10, -spacing => 10 );
    $Legend->Set_Column( [ "Data to be entered by user", "Data tracked but not entered by user", "Data which is not entered at this stage" ] );
    $Legend->Set_Cell_Colour( 1, 1, $on );
    $Legend->Set_Cell_Colour( 2, 1, $med );
    $Legend->Set_Cell_Colour( 3, 1, $off );

    my $example = $Page->Printout(0);

    $example .= "<P>" . $Legend->Printout(0);
    my @ids = $Page->get_IDs( -row => 1 );    ## keep track of ids for these cells so that they can be highlighted dynamically ##

    ### just get applicable libraries.. ###
    my $group_list = $dbc->get_local('group_list');
    my $condition  = "FK_Grp__ID IN ($group_list) AND Department_Name = '$Current_Department'";

    my %Parameters;
    $Parameters{'Target'} = $target;
    if ( $target =~ /^d(.{0,4})base/i ) {
        Message("New information will be updated into the database upon completion");
    }
    else {
        Message("Form information will be directed to Submission for approval");
    }

    my $start_form = alDente::Form::start_alDente_form( $dbc, $form_name, -parameters => \%Parameters ) . "\n<p ></p>\n";

    my $OS_prompt = "Sample_Origin:<B><i>(select a pre-existing original source)</i></B> " . alDente::Tools->search_list( -dbc => $dbc, -name => 'FK_Original_Source__ID', -default => '', -search => 1, -filter => 1, -breaks => 0 );

    my $SRC_prompt = "<B>Scan Source:</B> <i>(should have a SRC label)</i>" . Show_Tool_Tip( textfield( -name => 'Scanned ID', -size => 10, -default => '', -force => 1 ), "Scan item labelled with SRC or PLA barcode" );

    my $PLA_prompt = "<B>Scan Plate/Tube:</B> <I>(should have PLA label)</i> " . Show_Tool_Tip( textfield( -name => 'Scanned ID', -size => 10, -default => '', -force => 1 ), "Scan item labelled with SRC or PLA barcode" );

    my $type_prompt = "<B>Collection Type:</B>";
    if ( int(@types) >= 1 ) {
        $type_prompt .= Show_Tool_Tip( popup_menu( -name => 'Library_Type', -values => [ '', @types ], -default => $default_type, -force => 1 ), "Indicate if this is a Sequencing Library or an RNA/DNA Collection" );
        $type_prompt .= set_validator( -name => 'Library_Type', -mandatory => 1 );
    }
    else {
        $type_prompt .= hidden( -name => 'Library_Type', -value => $default_type ) . " $default_type";
    }

    my $tracking_prompt = "<B>Source Tracking ?:</B> <i>(Are we barcoding and tracking details for the starting material ?)</i>";

    $tracking_prompt .= Show_Tool_Tip(
        radio_group(
            -name    => 'Source Tracking',
            -value   => 'Yes',
            -default => 'Yes',
            -force   => 1,
            -onClick => set_ID( $ids[2], "style.backgroundColor='$on'" ) . set_ID( $ids[3], "style.backgroundColor='$on'" )
        ),
        "Barcode and enter details for source (eg ligation tube, tissue sample, RNA/DNA sample etc) now."
    );
    $tracking_prompt .= hspace(10);
    $tracking_prompt .= Show_Tool_Tip(
        radio_group(
            -name    => 'Source Tracking',
            -value   => 'Later',
            -default => 'Yes',
            -force   => 1,
            -onClick => set_ID( $ids[2], "style.backgroundColor = '$off'" ) . set_ID( $ids[3], "style.backgroundColor = '$off'" )
        ),

        "Will track at a later date (for now just enter descriptions)"
    );
    $tracking_prompt .= hspace(10);
    $tracking_prompt .= Show_Tool_Tip(
        radio_group(
            -name    => 'Source Tracking',
            -value   => 'No',
            -default => 'Yes',
            -force   => 1,
            -onClick => set_ID( $ids[2], "style.backgroundColor = '$med'" ) . set_ID( $ids[3], "style.backgroundColor = '$med'" )
        ),
        "Ignore source tracking (no barcodes for sources to be created)"
    );

    ## <CONSTRUCTION> - leave this out for now - is it necessary - it may add to the clutter... ##
    my $plates_prompt = '';

    my $source_on  = "document.getElementById($ids[3]).style.backgroundColor = '$on';";
    my $source_off = "document.getElementById($ids[3]).style.backgroundColor = '$off';";

    my $sl_on  = "document.getElementById($ids[4]).style.backgroundColor = '$on';";
    my $sl_off = "document.getElementById($ids[4]).style.backgroundColor = '$off';";

    my $lib_prompt = "<B>Choose Library:<B> "
        . alDente::Tools->search_list(
        -dbc              => $dbc,
        -form             => $form_name,
        -name             => 'FK_Library__Name',
        -default          => '',
        -search           => 1,
        -filter           => 1,
        -option_condition => $condition,
        -breaks           => 0,
        -join_condition   => "Grp.FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID",
        -join_tables      => "Grp,Department"
        );

    my $submit_new = submit( -name => 'Create New Library', -value => 'Create New Library', -class => "Std", -onClick => 'return validateForm(this.form)' ) . end_form();
    my $submit_new_validate_os = set_validator( -name => "FK_Original_Source__ID", -mandatory => 1 ) . submit( -name => 'Create New Library', -value => 'Create New Library',   -class => "Std", -onClick => 'return validateForm(this.form)' ) . end_form();
    my $submit_old             = submit( -name        => 'Create New Library',                                                                -value => 'Associate to Library', -class => "Std" ) . end_form();
    my $submit_assoc_library   = submit( -name        => 'New Library Source',                                                                -value => 'Associate to Library', -class => "Std" ) . end_form();
    my $submit_create_assoc_source = submit( -name => 'Create New Source', -value => 'Associate to Library', -class => "Std" ) . end_form();

    ## define tabs required ##
    my @headers = ( "NEW Organism/Tissue", "from SRC", "from PLA (Plate or Tube from another group/dept)", "New (unlabelled) material", );

    ## define onClick effects on example (illustrating forms that will be required).
    my %onClick;
    $onClick{ $headers[0] } = set_ID( $ids[0], "style.backgroundColor = '$on'" ) . set_ID( $ids[2], "style.backgroundColor = '$med'" ) . set_ID( $ids[3], "style.backgroundColor = '$on'" ) . set_ID( $ids[4], "style.backgroundColor = '$on'" );

    $onClick{ $headers[1] } = set_ID( $ids[0], "style.backgroundColor = '$off'" ) . set_ID( $ids[2], "style.backgroundColor = '$off'" ) . set_ID( $ids[3], "style.backgroundColor = '$on'" ) . set_ID( $ids[4], "style.backgroundColor = '$on'" );

    $onClick{ $headers[2] } = set_ID( $ids[0], "style.backgroundColor = '$off'" ) . set_ID( $ids[2], "style.backgroundColor = '$on'" ) . set_ID( $ids[3], "style.backgroundColor = '$on'" ) . set_ID( $ids[4], "style.backgroundColor = '$on'" );

    $onClick{ $headers[3] } = set_ID( $ids[0], "style.backgroundColor = '$off'" ) . set_ID( $ids[2], "style.backgroundColor = '$on'" ) . set_ID( $ids[3], "style.backgroundColor = '$on'" ) . set_ID( $ids[4], "style.backgroundColor = '$on'" );

    ### options starting from SRC ###
    my %SRC_click;
    $SRC_click{'NEW Library'} = set_ID( $ids[0], "style.backgroundColor = '$off'" ) . set_ID( $ids[2], "style.backgroundColor = '$off'" ) . set_ID( $ids[3], "style.backgroundColor = '$on'" ) . set_ID( $ids[4], "style.backgroundColor = '$on'" );

    $SRC_click{'Re-Submission'} = set_ID( $ids[0], "style.backgroundColor = '$off'" ) . set_ID( $ids[2], "style.backgroundColor = '$off'" ) . set_ID( $ids[3], "style.backgroundColor = '$on'" ) . set_ID( $ids[4], "style.backgroundColor = '$off'" );
    my $src_elements = $start_form . $type_prompt . '<p ></p>' . $SRC_prompt;
    my $src_layers   = {
        'Re-Submission' => $src_elements . '<p ></p>' . $lib_prompt . '<p ></p>' . $submit_assoc_library,
        'NEW Library'   => $src_elements . '<p ></p>' . $submit_new,
    };

    my $SRC_options = define_Layers( -layers => $src_layers, -name => 'SRC', -default => '', -onClick => \%SRC_click, -wrap => 'Src_options' );

    ### options starting from PLA ###
    my %PLA_click;
    $PLA_click{'NEW Library'} = set_ID( $ids[0], "style.backgroundColor = '$off'" ) . set_ID( $ids[2], "style.backgroundColor = '$on'" ) . set_ID( $ids[3], "style.backgroundColor = '$on'" ) . set_ID( $ids[4], "style.backgroundColor = '$on'" );

    $PLA_click{'Re-Submission'} = set_ID( $ids[0], "style.backgroundColor = '$off'" ) . set_ID( $ids[2], "style.backgroundColor = '$on'" ) . set_ID( $ids[3], "style.backgroundColor = '$on'" ) . set_ID( $ids[4], "style.backgroundColor = '$off'" );

    my $pla_elements = $start_form . $type_prompt . hidden( -name => 'Source Tracking', -value => 'Yes' ) . '<p ></p>' . $PLA_prompt;
    my $pla_layers = {
        'NEW Library'   => $pla_elements . '<p ></p>' . $submit_new,
        'Re-Submission' => $pla_elements . '<p ></p>' . $lib_prompt . '<p ></p>' . $submit_create_assoc_source,
    };
    my $PLA_options = define_Layers( -layers => $pla_layers, -name => 'PLA', -default => '', -onClick => \%PLA_click, -wrap => 'Pla_options' );

    ### options starting from PLA ###
    my %UL_click;
    $UL_click{'NEW Library'} = set_ID( $ids[0], "style.backgroundColor = '$off'" ) . set_ID( $ids[2], "style.backgroundColor = '$on'" ) . set_ID( $ids[3], "style.backgroundColor = '$on'" ) . set_ID( $ids[4], "style.backgroundColor = '$on'" );

    $UL_click{'Existing Library (New Segment)'}
        = set_ID( $ids[0], "style.backgroundColor = '$off'" ) . set_ID( $ids[2], "style.backgroundColor = '$on'" ) . set_ID( $ids[3], "style.backgroundColor = '$on'" ) . set_ID( $ids[4], "style.backgroundColor = '$off'" );

    my $ul_elements = $start_form . $type_prompt . '<p ></p>' . $tracking_prompt;
    my $ul_layers   = {
        'NEW Library'                    => $ul_elements . '<p ></p>' . $OS_prompt . '<p ></p>' . $submit_new_validate_os,
        'Existing Library (New Segment)' => $ul_elements . '<p ></p>' . $lib_prompt . '<p ></p>' . $submit_old,
    };
    my $UL_options = define_Layers( -layers => $ul_layers, -name => 'UL', -default => 'NEW Library', -onClick => \%UL_click, -wrap => 'Ul_options' );

    my $new_layer = "<SPAN id='new_options'>" . $start_form . $type_prompt . '<p ></p>' . $tracking_prompt . '<p ></p>' . $plates_prompt . '<p ></p>' . $submit_new . "</SPAN>\n";

    print define_Layers(
        -layers => {
            $headers[0] => $new_layer,
            $headers[1] => $SRC_options,
            $headers[2] => $PLA_options,
            $headers[3] => $UL_options,
        },
        -order     => \@headers,
        -onClick   => \%onClick,
        -height    => 300,
        -tab_width => 250,
        -sub_tab   => ' '
    );

    print '<p ></p>';

    print $example;

    print '<p ></p>';

    return;
}

##########################################################################################
# create new library w/ pool page. Call create_pool to set fields and do integrity check.
##########################################################################################
sub new_pool {
###############
    my $self     = shift;
    my %args     = @_;
    my $pool_lib = $args{-pool_lib};
    my $lib_type = $args{-lib_type};
    my $confs    = $args{-configs};
    my $dbc      = $self->{dbc};
    my $user_id  = $dbc->get_local('user_id');
    my %configs;
    if ($confs) { %configs = %$confs }

    my $retval;

    # Pool table configs
    $configs{'-grey'}{'Pool.FK_Employee__ID'} = &get_FK_info( $dbc, 'FK_Employee__ID', $user_id );
    $configs{'-grey'}{'Pool.Pool_Type'} = 'Library';

    # PoolSample table configs
    $configs{'-omit'}{'PoolSample.FK_Clone__ID'}  = '';
    $configs{'-omit'}{'PoolSample.FK_Sample__ID'} = '';

    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Pool', -target => 'Database' );
    $form->configure(%configs);

    # Generates the form
    #$form->generate(-title=>"Creating New $lib_type Container");
    $form->generate();

    $retval = 1;

    return $retval;
}

######################
sub derived_from {
######################
    my $self  = shift;
    my %args  = &filter_input( \@_, -args => 'id,field' );
    my $lib   = $args{-library} || $self->{id};
    my $field = $args{-field} || "Plate_ID";                 # default to return Plate_ID (alternatively, Library_Name)

    my @derived_from;
    my $src_list = join ',', $self->{dbc}->Table_find( 'Library_Source', 'FK_Source__ID', "WHERE FK_Library__Name = '$lib'" );

    @derived_from = $self->{dbc}->Table_find( 'Source,Plate,Library', $field, "WHERE FKSource_Plate__ID = Plate_ID AND FK_Library__Name=Library_Name AND Source_ID IN ($src_list)", -distinct => 1 ) if $src_list;

    return @derived_from;
}

#######################################
# Get all libraries
# Returns an array of libraries
#######################################
sub get_libraries {
######################
    my %args       = &filter_input( \@_, -self => 'Library' );
    my $self       = $args{-self};                                                                    ## ?
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $study_id   = $args{-study_id};                                                                # Specify a study by ID
    my $study_name = $args{-study_name};                                                              # Specify a study by name
    my $project_id = $args{-project_id};

    my $condition;

    my @by_libraries = $dbc->Table_find_array( 'Study,LibraryStudy', ['FK_Library__Name'], "where Study_ID=FK_Study__ID $condition" );

    my @by_projects = $dbc->Table_find_array( 'Study,ProjectStudy,Project,Library', ['Library_Name'], "where Study_ID=FK_Study__ID and Project_ID=ProjectStudy.FK_Project__ID and Project_ID=Library.FK_Project__ID $condition" );

    ## if project specified ##
    if ( $project_id && $project_id =~ /^\d$/ ) {
        return [ $dbc->Table_find_array( 'Project,Library', ['Library_Name'], "WHERE Project_ID=FK_Project__ID AND Project_ID IN ($project_id)" ) ];
    }
    elsif ( $study_id && $study_id =~ /^\d$/ ) { $condition = " AND Study_ID = $study_id" }
    elsif ($study_name) { $condition = " AND Study_Name = '$study_name'" }
    else                { Message("Please provide a valid Project ID, Study ID or Study Name.\n"); return; }

    my @all_libraries = @{ union( \@by_libraries, \@by_projects ) };
    unless ( @all_libraries > 0 ) { @all_libraries = ('0') }

    return \@all_libraries;
}

################################################
# Get all the library formats of this library
################################################
sub get_library_formats {
    my $self = shift;
    my $dbc = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my %src_info = &Table_retrieve(
        $dbc,
        "Source,Library_Source,Original_Source",
        [ 'Source_Type', 'Source_ID', 'FK_Original_Source__ID', 'Source_Number', 'Original_Source_Name' ],
        "WHERE FK_Source__ID=Source_ID AND FK_Library__Name='$self->{id}' AND FK_Original_Source__ID=Original_Source_ID"
    );

    my %ret;
    my $index = 0;
    while ( exists $src_info{'Source_Type'}[$index] ) {
        my $type          = $src_info{'Source_Type'}[$index];
        my $src_id        = $src_info{'Source_ID'}[$index];
        my $orig_src_id   = $src_info{'FK_Original_Source__ID'}[$index];
        my $orig_src_name = $src_info{'Original_Source_Name'}[$index];
        my $source_number = $src_info{'Source_Number'}[$index];
        my ($type_id) = $dbc->Table_find( "${type}", "${type}_ID", "WHERE FK_Source__ID=$src_id" );
        $ret{$type}{$type_id} = [ $src_id, $orig_src_id, $source_number, $orig_src_name ];

        $index++;
    }
    return \%ret;
}

##############################
# public_functions           #
##############################

#######################
#
#
#
###################
sub pool_Library {
################
    my $Pool_Lib = shift;
    my %args     = @_;

    ## Mandatory fields ###
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $name     = $args{-name};                                                                    # Library name to be used for new pool (5 characters - unique)
    my $fullname = $args{-full_name};                                                               # brief but descriptive name for this library (unique)
    my $plates   = $args{-plate_id};                                                                # single plate or array
    my $wells    = $args{-wells};                                                                   # array of wells
    my $obtained = $args{-date};                                                                    # Time when this Library was first created..
    my $contact  = $args{-contact_id};
    my $qty      = $args{-quantity};
    my $units    = $args{-units};

    ## Optional fields ###
    my $description     = $args{-description} || '';
    my $status          = $args{-status};
    my $comments        = $args{-comments};
    my $goals           = $args{-goals} || '';
    my $insert_size_avg = $args{-insert_size_avg} || 0;
    my $insert_min      = $args{-insert_min} || 0;
    my $insert_max      = $args{-insert_max} || 0;

    ## For Transposon Pools Only (Mandatory) ###
    my $transposon_id  = $args{-transposon_id};
    my $gel_id         = $args{-gel_id};            # may specify single gel id if only one plate used
    my $clone_gel_id   = $args{-clone_gel_id};      # array of clone_gel_ids used (links to band_size information)
    my $reads_required = $args{-reads_required};    # number of reads required for this pool (-> Library Goal)
    my $pipeline       = $args{-pipeline};          # Standard or Gateway
    my $parent         = $args{-parent_library};    # required only for 'Gateway' types
    my $emp_name       = $args{-emp_name};          # Name of employee who created the library
    my $source_name    = $args{-source_name};       # Library source name
    my $append         = $args{-append};            # append pool to existing Library

    my $quiet = $args{-quiet};                      ## quiet mode (preferable to NOT use this - check feedback if possible)

    ## Error Checking ###
    my @mandatory = ( '-dbc', '-plate_id', '-wells', '-full_name', '-name', '-contact_id', '-insert_size_avg', '-goals', '-insert_min', '-insert_max', '-emp_name' );
    if ($transposon_id) {
        push( @mandatory, '-pipeline', '-reads_required' );    ## also clone_gel_id, but handle below to allow alternative '-gel_id' spec
    }

    $plates = Cast_List( -list => $plates, -to => 'string', -autoquote => 0 );
    my @plate_list    = Cast_List( -list => $plates,       -to => 'array', -autoquote => 0 );
    my @clone_gels    = Cast_List( -list => $clone_gel_id, -to => 'array', -autoquote => 0 );
    my @well_list     = Cast_List( -list => $wells,        -to => 'array', -autoquote => 0 );
    my @quantity_list = Cast_List( -list => $qty,          -to => 'array', -autoquote => 0 );

    ## allow single entry for some fields, but map to array...
    if ( $plates =~ /^\d+$/ ) {
        @plate_list = map {$plates} @well_list;
    }    ## if single plate, map to array of plate_ids
    unless ( $qty =~ /,/ ) {
        @quantity_list = map {$qty} @well_list;
    }    ## if single qty , map to array of quantities

    if ($gel_id) {
        @clone_gels = ();    ## reset to ensure array sizes match
        foreach my $well (@well_list) {
            my ($CG_id) = $dbc->Table_find( 'Clone_Gel', 'Clone_Gel_ID', "WHERE Well='$well' AND FK_GelRun__ID = $gel_id" );
            unless ( $CG_id =~ /[1-9]/ ) { Message("Error: No Clone_Gel records for GelRun $gel_id"); return; }
            push( @clone_gels, $CG_id );
        }
    }
    elsif ( !$clone_gel_id ) { Message("Error: No Clone_Gel_IDs (or Gel_IDs) supplied"); return; }

    ## Error checking ##
    unless ( int(@plate_list) == int(@well_list) )    { Message("Error: size of Plate, Well lists must be identical");         return; }
    unless ( int(@clone_gels) == int(@well_list) )    { Message("Error: size of Clone_Gel_IDs, Well lists must be identical"); return; }
    unless ( int(@quantity_list) == int(@well_list) ) { Message("Error: size of Quantity lists must be identical");            return; }

    ## check for existence of library ##
    my ($found) = $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Name = '$name'" );
    if ( $found && !$append ) { Message("Error: $name already exists - use append switch to enable addition to existing Library/Collection"); return; }
    elsif ( !$found && $append ) { Message("Error: $name does not exist - remove append switch to create new Library/Collection"); return; }

    my %formats = ( -name => q{/^\w{5}$/} );

    my $errors = input_error_check( -input => \%args, -format => \%formats, -mandatory => \@mandatory );
    if ($errors) {

        #	Smart_Message(-message=>$errors,-format=>$SETTINGS{FORMAT});
        print "Error defining Pool\n***********************\n$errors\n";
        return;
    }

    my ($emp_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name='$emp_name'" );
    unless ($emp_id) {
        print "ERROR: Employee name provided ($emp_name) invalid.\n";
        return 0;
    }

    # Need to be adjusted
    # <CONSTRUCTION>
    my ($barcode_label_id) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_ID', "WHERE Barcode_Label_Name='src_tube'" );

    # search if there is only one Original_Source used for the library/ies pooled.
    my @orig_sources = $dbc->Table_find( "Plate,Library_Source,Source", "distinct FK_Original_Source__ID", "WHERE Plate.FK_Library__Name=Library_Source.FK_Library__Name AND FK_Source__ID=Source_ID AND Plate_ID in (" . join( ',', @plate_list ) . ")" );

    # if there is only one, use that Original_Source_Name and increment appropriately
    my $source_tables = 'Source,Ligation';
    my @source_fields = ( 'Notes', 'Source_Status', 'FKParent_Source__ID', 'Source_Type', 'Received_Date', 'FKReceived_Employee__ID', 'FK_Rack__ID', 'Source_Number', 'FK_Barcode_Label__ID' );
    my $source_number = 0;
    $source_name = "";
    my @source_values = ( 'Pooled Library', 'Active', '0', 'Ligation', &date_time(), $emp_id, 1, $source_number, $barcode_label_id );
    if ( scalar(@orig_sources) == 1 ) {
        $source_number = $dbc->Table_find( "Source", "max(Source_Number)", "WHERE FK_Original_Source__ID=$orig_sources[0] AND Source_Type = 'Ligation'" );
        $source_number =~ /^(\d+)\.?/;
        $source_number = $1;

        $source_number++;
    }
    else {

        # if there is more than one (or zero), use the concatenation of the Library names
        $source_number = 1;
        my @source_libraries = $dbc->Table_find( "Plate", "distinct FK_Library__Name", "WHERE Plate_ID in (" . join( ',', @plate_list ) . ")" );
        $source_name = join( '.', @source_libraries );

        # if source_number == 1, then we need to insert Original_Source as well
        $source_tables = "Original_Source,$source_tables";

        push( @source_fields, 'Original_Source_Name', 'Description', 'FK_Contact__ID' );
        push( @source_values, $source_name, $description, $contact );
    }

    my %source_insert;
    $source_insert{1} = \@source_values;

    # insert using smart_append
    my $dbio = new SDB::DBIO( -dbc => $dbc );

    $dbio->smart_append( -tables => $source_tables, -fields => \@source_fields, -values => \%source_insert, -autoquote => 2 );
    my $new_source_id = $dbio->newids( 'Source', 0 );

    unless ($new_source_id) {
        Message("ERROR: Cannot create new Source.<BR>\n");
        return;
    }

    my @common_fields = ( 'Library_Type', 'Host', 'FK_Project__ID', 'FK_Grp__ID', 'FK_Vector_Type__ID' );
    my $CF_list = join ',', @common_fields;

    my %unique_values = &Table_retrieve( $dbc, 'Library,LibraryVector,Vector_Based_Library,Library_Plate,Plate',
        [@common_fields],
        "WHERE Plate.FK_Library__Name=Library_Name AND Vector_Based_Library.FK_Library__Name=Library_Name AND Library_Plate.FK_Plate__ID=Plate_ID AND LibraryVector.FK_Library__Name = Library_Name AND Plate_ID in ($plates) GROUP BY $CF_list" );

    if ( defined $unique_values{FK_Project__ID}[1] ) {
        Message("Error: Non unique information for Pooled libraries (shown below..)");
        print Dumper( \%unique_values );
        return;
    }
    my $lib = $unique_values{Library_Name}[0];

    ### Get 'clone' of the libraries used ##
    $Pool_Lib->primary_value( -table => 'Library', -value => $lib );
    $Pool_Lib->add_tables('Vector_Based_Library');
    $Pool_Lib->load_Object();

    if ($transposon_id) { $Pool_Lib->value( 'Vector_Based_Library_Type', 'Transposon' ); }
    else {
        my $lib_sub_type = $Pool_Lib->value('Vector_Based_Library_Type');
        if ( $lib_sub_type eq 'SAGE' || $lib_sub_type eq 'Mapping' ) {
            $Pool_Lib->add_tables( $lib_sub_type . "_Library" );
            $Pool_Lib->value( 'FK_Vector_Based_Library__ID', 0 );
            ### Temporary - additional checks for consistency ? and/or changed fields in these tables ?? ###
        }
    }

    ## update optional fields ##
    $Pool_Lib->value( 'Library_FullName',       $fullname );
    $Pool_Lib->value( 'Library_Description',    $description );
    $Pool_Lib->value( 'Library_Goals',          $goals );
    $Pool_Lib->value( 'Library_Source',         'Internal Pool' );
    $Pool_Lib->value( 'Library_Source_Name',    "n\/a" );
    $Pool_Lib->value( 'FKCreated_Employee__ID', $emp_id );

    $Pool_Lib->value( 'AvgInsertSize', $insert_size_avg );
    $Pool_Lib->value( 'InsertSizeMin', $insert_min );
    $Pool_Lib->value( 'InsertSizeMax', $insert_max );

    $Pool_Lib->add_tables('Library_Source');
    $Pool_Lib->value( 'FK_Source__ID', $new_source_id );

    ## update other fields ##
    unless ( $obtained =~ /^\d\d\d\d/ ) { ($obtained) = split ' ', &date_time(); }
    my @update_fields = ( 'Library_Name', 'Library_FullName', 'Vector_Based_Library_ID', 'Library_Obtained_Date', 'Library_Goals', 'Vector_Based_Library_Format', 'Library.FK_Contact__ID' );
    print "Add $name ($fullname)\nObtained: $obtained (contact: $contact) $goals; ...\n";
    my @update_values = ( $name, $fullname, 0, $obtained, $goals, 'Ligation', $contact );
    foreach my $index ( 0 .. $#update_fields ) {
        $Pool_Lib->value( $update_fields[$index], $update_values[$index] );
    }

    ## adjust fields that may be different for the current plates ##
    my @hybrid_fields = ( 'FK5Prime_Enzyme__ID', 'FK3Prime_Enzyme__ID' );
    my @hybrid_values = @{ &check_for_hybrid_Libraries( -dbc => $dbc, -fields => \@hybrid_fields, -plates => $plates, -hybrid => 'Hybrid', -quiet => $quiet ) };

    foreach my $index ( 0 .. $#hybrid_fields ) {
        $Pool_Lib->value( $hybrid_fields[$index], $hybrid_values[$index] );
    }
    ## adjust fields in which lists should be constructed if multiple values found ##
    #<ATTN> Remove Tissue from this append
    my @list_fields = ( 'Sex', 'FK_Strain__ID' );
    my @list_values = @{ &check_for_hybrid_Libraries( -dbc => $dbc, -fields => \@list_fields, -plates => $plates, -hybrid => 'list', -quiet => $quiet ) };

    foreach my $index ( 0 .. $#list_fields ) {
        $Pool_Lib->value( $list_fields[$index], $list_values[$index] );

    }
    ### Add new Library record with similar values to the plate source Libraries ###
    $Pool_Lib->insert();
    print "** Added $name Library..**\n";

    ## Add record in Pool  / Transposon Table(s) as applicable
    my $tables            = 'Pool,Transposon_Pool';
    my $pool_type         = 'Library';
    my $library_pool_type = 'Standard';

    # information for Pools
    my @fields = ( 'Pool_Type', 'FK_Employee__ID', 'Pool_Comments', 'Pool_Date' );
    my @values = ( $pool_type, $emp_id, $comments, $obtained );

    # information for Xposon Pools
    push( @fields, 'FK_Transposon__ID', 'Pipeline', 'Reads_Required', 'Status', 'FK_Source__ID' );
    push( @values, $transposon_id, $pipeline, $reads_required, $status, $new_source_id );

    my %Added = %{ $dbc->smart_append( -dbc => $dbc, -tables => $tables, -fields => \@fields, -values => \@values, -autoquote => 1 ) };
    my $pool_id = $Added{Pool}{newids}->[0];

    unless ($pool_id) { Message("Error Adding Pool_Id ?"); return; }
    ### Add PoolSample records for each well ###
    @fields = ( 'FK_Pool__ID', 'FK_Plate__ID', 'Well', 'FK_Sample__ID', 'FK_Clone_Gel__ID', 'Sample_Quantity', 'Sample_Quantity_Units' );
    my $added = 0;
    foreach my $index ( 0 .. $#well_list ) {
        my $well         = $well_list[$index];
        my $plate_id     = $plate_list[$index];
        my $clone_gel_id = $clone_gels[$index];
        my $sample       = &_get_sample_id( -dbc => $dbc, -plate_id => $plate_id, -well => $well );
        my @values       = ( $pool_id, $plate_id, $well, $sample, $clone_gel_id, $qty, $units );

        my $ok = $dbc->Table_append_array( 'PoolSample', \@fields, \@values, -autoquote => 1 );

        if ($ok) { $added++ }
    }
    return $pool_id;
}

#############################
#
# Retrieve list of related libraries (via original source and hybrid original sources)
#
# (this is useful for generating menus that should only include related libraries (such as for defining a rearray target library))
#
# Return: arrayref to related libraries (including input library if supplied)
###########################
sub related_libraries {
###########################
    ## <CONSTRUCTION> - this does still not use parent Library functionality - at this time, there are none declared

    my %args            = @_;
    my $dbc             = $args{-dbc};
    my $library         = $args{-library};
    my $original_source = $args{-original_source};

    my $libs = Cast_List( -list => $library, -to => 'string', -autoquote => 1 );
    if ($library) { $original_source = join ',', $dbc->Table_find( 'Library', 'FK_Original_Source__ID', "WHERE Library_Name IN ($libs)" ); }

    my @related = Cast_List( -list => $original_source, -to => 'array' );
    my $nextgen = join ',', @related;
    while ($nextgen) {
        my @child_libraries = $dbc->Table_find( 'Hybrid_Original_Source', 'FKChild_Original_Source__ID', "WHERE FKParent_Original_Source__ID IN ($nextgen)" );
        if (@child_libraries) {
            my $difference = set_difference( \@child_libraries, \@related );
            if ( !@{$difference} ) {last}    #Break the loop if there are no more new children found

            $nextgen = join ',', @child_libraries;
            push @related, @child_libraries;
        }
        else {
            $nextgen = '';
        }
    }
    my $related_origins = join ',', @related;
    my @libs = $dbc->Table_find( 'Library', 'Library_Name', "WHERE FK_Original_Source__ID IN ($related_origins)" );
    return \@libs;
}

###########################
sub check_for_hybrid_Libraries {
###########################
    my %args         = @_;
    my $dbc          = $args{-dbc};
    my $field_ref    = $args{-fields};
    my $plates       = $args{-plates};
    my $libs         = $args{-libs};
    my $hybrid_value = $args{-hybrid} || 'Hybrid';
    my $quiet        = $args{-quiet};

    my @fields = @$field_ref;

    my $condition = " WHERE Vector_Based_Library.FK_Library__Name=Library_Name";

    my $tables = 'Library,Vector_Based_Library';
    if ($plates) { $tables .= ",Plate"; $condition .= " AND Plate.FK_Library__Name=Library_Name AND Plate_ID in ($plates)"; }
    elsif ($libs) { $condition .= " AND Library_Name in ($libs)"; }

    my %Found = &Table_retrieve( $dbc, $tables, [ @fields, 'Library_Name' ], "$condition GROUP BY Library_Name" );

    my %Return;
    my $index = 0;
    while ( defined $Found{Library_Name}[$index] ) {
        foreach my $field (@fields) {
            my $value = $Found{$field}[$index];
            if ( !$Return{$field} ) { $Return{$field} = $value; next; }    ## first value found for this field
            elsif ( !$value ) { next; }                                    ## no value specified.. ok continue ..
            elsif ( $Return{$field} && ( $Return{$field} =~ /^$value$/ ) ) { next; }    ## same value as before.. ok
            elsif ( $Return{$field} =~ /\b$hybrid_value\b/ ) { next; }                  ## already have hybrid value set
            else {                                                                      ## new value found ...
                if ( $hybrid_value =~ /^list$/i ) {
                    $Return{$field} .= ",$value";                                       ## different values -> return 'value1,value2';
                }
                else {
                    $Return{$field} = $hybrid_value;                                    ## different values -> return 'hybrid'
                }
            }
        }
        $index++;
    }
    unless ($quiet) {
        print "** Checking consistency of Values... **\n";
        print Dumper( \%Return );
    }

    my @returnvals;
    foreach my $field (@fields) {
        push( @returnvals, $Return{$field} );
    }
    return \@returnvals;
}

#######################################
#output HTML for library consumables page
#######################################
sub library_consumables {
#####################
    my $libs     = shift;
    my $projects = shift;
    my $dbc      = $Connection;
    my $homelink = $dbc->homelink();

    #
    # For now simply set estimated plate & run costs...
    #
    #
    my $Plate_costs = {};
    $Plate_costs->{Beck} = 0.644;    #### temporary plate costs
    $Plate_costs->{Gene} = 0.644;
    $Plate_costs->{NUNC} = 4.41;
    $Plate_costs->{Micr} = 4.41;
    my $Run_cost = 150.00;           #### temporary run cost.

    my $overall_cost = 0;

    if    ( $projects =~ /^[\d\,\s]+$/ ) { $libs = join ',', $dbc->Table_find( 'Library',         'Library_Name', "where FK_Project__ID in ($projects)" ); }
    elsif ( $projects =~ /\w/ )          { $libs = join ',', $dbc->Table_find( 'Library,Project', 'Library_Name', "where FK_Project__ID=Project_ID and Project_Name = '$projects'" ); }
    foreach my $lib ( split ',', $libs ) {

        my $Consumed = HTML_Table->new();
        $Consumed->Set_Title("Consumables Used for $lib Library");
        $Consumed->Set_Headers( [ 'Description', 'Used', 'Value' ] );
        $lib = substr( $lib, 0, 5 );    ##### extract first 5 characters (Library Name)

################################ Get Reagent/Solution Info... ###################
#	my %solution_info = &Table_retrieve($dbc,'Plate,Plate_Prep,Plate_Set,Prep,Solution,Stock',['count(*) as Count','Stock_ Name as Name','Sum(Prep.Solution_Quantity) as Quantity','Sum(Stock_Cost*Prep.Solution_Quantity/Stock_Size) as Cost','FK_Library__Name as Library','1000*Sum(Stock_Cost)/Sum(Stock_Size) as CostPerL'],"where FK_Stock__ID=Stock_ID and FK_Prep__ID = Prep_ID AND Plate_Set_Number=FK_Plate_Set__Number and Plate_Set.FK_Plate__ID=Plate_ID and FK_Solution__ID=Solution_ID and FK_Library__Name in ('$lib') group by FK_Library__Name,Stock _Name");
        my %solution_info = &Table_retrieve(
            $dbc,
            'Plate,Plate_Prep,Plate_Set,Prep,Solution,Stock,Stock_Catalog',
            [   'FK_Stock_Catalog__ID as ID',
                'count(*) as Count',
                'Stock_Catalog_Name as Name',
                'Sum(Plate_Prep.Solution_Quantity) as Quantity',
                'Sum(Stock_Cost*Plate_Prep.Solution_Quantity/Stock_Catalog.Stock_Size) as Cost',
                'FK_Library__Name as Library',
                '1000*Sum(Stock_Cost)/Sum(Stock_Catalog.Stock_Size) as CostPerL'
            ],
            "where FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Stock__ID=Stock_ID and FK_Prep__ID = Prep_ID AND Plate_Set_Number=FK_Plate_Set__Number and Plate_Set.FK_Plate__ID=Plate_ID and FK_Solution__ID=Solution_ID and FK_Library__Name in ('$lib') group by FK_Library__Name,Stock_Catalog_Name"
        );

        $Consumed->Set_sub_header( "Reagents/Solutions Used", 'mediumbluebw' );

        #    foreach my $info (@solution_info) {
        #   my $solution_standard_ID = alDente::Stock::get_standard_solution_id($dbc);
        my $index = 0;
        my $total_cost;
        while ( defined $solution_info{Library}[$index] ) {
            my $count        = $solution_info{Count}[$index];
            my $catalog_name = $solution_info{Name}[$index];

            my $solution = $catalog_name;
            my $sol__ID  = $solution_info{ID}[$index];

            #    if ($sol__ID == $solution_standard_ID)  { $solution = $in_house_name }
            #    else                                    { $solution = $catalog_name  }
            my $quantity   = $solution_info{Quantity}[$index];
            my $cost       = $solution_info{Cost}[$index];
            my $library    = $solution_info{Library}[$index];
            my $cost_per_L = sprintf "%0.2f", $solution_info{CostPerL}[$index];

            $total_cost += $cost;
            $cost = sprintf "%0.2f", $cost;    #### round off AFTER totalling...
            $index++;
            $quantity = &get_units( $quantity, 'mL' );

            #	my $units = '';
            #	if ($quantity=~/([a-zA-Z]+)$/) {$units = $1;}
            #	$quantity = sprintf ("%0.2f", $quantity) . $units;

            my @preps = $dbc->Table_find(
                'Prep,Plate_Prep,Plate_Set,Plate,Solution,Stock,Stock_Catalog', 'Prep_ID,Solution_ID',
                "where FK_Solution__ID=Solution_ID and FK_Stock__ID=Stock_ID and Stock_Catalog_Name ='$catalog_name' 
	                AND FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Prep__ID=Prep_ID and FK_Plate_Set__Number=Plate_Set_Number and Plate_ID=Plate_Set.FK_Plate__ID and FK_Library__Name='$library'", 'distinct'
            );
            my @app_array;    #### generate list of preparation ids.
            my @sol_array;    #### generate list of solution ids.
            foreach my $info (@preps) {
                my ( $app, $sol ) = split ',', $info;
                push( @app_array, $app );
                push( @sol_array, $sol );
            }
            my $app_list     = join ',', @app_array;                                                                           ## make comma delimited list
            my $applications = "<A Href=$homelink&Info=1&Table=Prep&Field=Prep_ID&Like=$app_list>($count applications)</A>";
            my $sol_ids      = join ',', @sol_array;                                                                           ## make comma delimited list
            $solution = "<A Href=$homelink&Info=1&Table=Solution&Field=Solution_ID&Like=$sol_ids&>$solution</A>";
            $Consumed->Set_Row( [ $solution, "$quantity $applications", "\$ $cost (\@ \$$cost_per_L/L)" ] );
        }

        ################# Get Plastic-ware info ###########################

        my @plastic_info = $dbc->Table_find_array(
            'Plate,Plate_Format',
            [ 'FK_Library__Name', 'Plate_Format_Type', 'FK_Plate_Format__ID', 'Plate_Size', 'Plate_ID' ],
            "where FK_Plate_Format__ID=Plate_Format_ID AND FK_Library__Name in ('$lib') order by FK_Library__Name,Plate_Format,Plate_Size"
        );

        $Consumed->Set_sub_header( 'Plastic-ware used', 'mediumbluebw' );

        my %Format = {};
        my %Counts = {};
        my %IDlist = {};    ## Initialize

        foreach my $info (@plastic_info) {
            my ( $lib, $format, $format_id, $size, $id ) = split ',', $info;
            my $name = "$lib" . "_F$format_id$size";
            $Format{$name} = "$format ($size)";
            $Counts{$name} ||= 0;
            $Counts{$name}++;
            $IDlist{$name} ||= "";
            $IDlist{$name} .= ",$id";
        }
        foreach my $key ( keys %Counts ) {
            unless ( $Counts{$key} > 0 ) { next; }
            my $id_list        = $IDlist{$key};
            my $format         = "<A Href=$homelink&Info=1&Table=Plate&Field=Plate_ID&Like=$id_list>" . $Format{$key} . "</A>";
            my $plate_type     = substr( $Format{$key}, 0, 4 );
            my $cost_per_plate = $Plate_costs->{$plate_type};
            my $cost           = $Counts{$key} * $cost_per_plate;
            $Consumed->Set_Row( [ $format, $Counts{$key}, "\$ $cost @ \$$cost_per_plate/plate" ] );
            $total_cost += $cost;
        }

        ################## Get Sequencing Run Info ##################
        my @sequence_info = $dbc->Table_find_array( 'Run,Equipment', [ 'Equipment_Name', 'Run_ID' ], "where FK_Equipment__ID=Equipment_ID and Run_Directory like '$lib%' and Run_Status like 'Analyzed' order by Equipment_Name" );
        $Consumed->Set_sub_header( 'Sequencing Reactions Run', 'mediumbluebw' );

        my %Runs   = {};
        my %Seq_ID = {};    ## re-initialize hashes..
        foreach my $info (@sequence_info) {
            my ( $equip, $id ) = split ',', $info;
            $Runs{$equip} ||= 0;
            $Runs{$equip}++;
            $Seq_ID{$equip} ||= "";
            $Seq_ID{$equip} .= ",$id";
        }
        foreach my $key ( keys %Runs ) {
            unless ( $Runs{$key} > 0 ) { next; }
            my $id_list      = $Seq_ID{$key};
            my $machines     = "<A Href=$homelink&Info=1&Table=Equipment&Field=Equipment_Name&Like=$key>$key</A>";
            my $runs         = "<A Href=$homelink&Info=1&Table=Run&Field=Run_ID&Like=$id_list>" . $Runs{$key} . " Runs</A>";
            my $cost_per_run = $Run_cost;
            my $cost         = $Runs{$key} * $cost_per_run;
            $Consumed->Set_Row( [ $machines, $runs, "\$ $cost @ \$$cost_per_run/run" ] );
            $total_cost += $cost;
        }
        $overall_cost += $total_cost;
        $total_cost = sprintf "%0.2f", $total_cost;
        $Consumed->Set_sub_header( "<B>Total Cost in Consumables: \$ $total_cost</B>", 'lightredbw' );
        $Consumed->Printout();
    }
    ########## if more than one library show overall cost ###############
    if ( $libs =~ /,/ ) {
        print &Heading("Overall Cost: \$ $overall_cost");
    }
    return 1;
}

#######################################
#output HTML for library specs page
#######################################
sub get_Library_specs {
    my $lib = shift;
    my $dbc = $Connection;

    my @vectors = $dbc->Table_find( 'LibraryVector,Vector', 'FK_Vector_Type__ID', "where FK_Vector__ID = Vector_ID and Library_Name like '$lib'", 'Distinct' );
    my $vector = Cast_List( -list => \@vectors, -to => 'String', -autoquote => 1 );
    my $valid_primers = join "<LI>", $dbc->Table_find( 'Vector_TypePrimer, Primer', 'Primer_Name', "where Primer_ID = FK_Primer__ID and FK_Vector_Type__ID IN ($vector)", 'Distinct' );

    print Views::sub_Heading("Current Valid Primers");

    if ($valid_primers) {
        print "<UL><LI>$valid_primers</UL>";
    }
    else { print " (none)"; }

    print &vspace();

    my $vector_link = &Link_To( $dbc->config('homelink'), 'Add Valid Primer', "&New+Entry=New+Vector_TypePrimer&FK_Vector_Type__ID=$vector", 'blue', ['newwin'] );

    my $lib_link = &Link_To( $dbc->config('homelink'), 'Add Suggested Primer', "&LibraryApplication=1&Library+Name=$lib&Object_Class=Primer", 'blue', ['newwin'] );

    print $vector_link . &vspace(10) . $lib_link;

    return 1;
}
#########################################
# Check which type of Library (Sequencing_Library or RNA_DNA_Collection)
#
##############
sub check_Library_Type {
##############
    my %args    = @_;
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $library = $args{-library};

    my $seq_lib;
    my $rna_lib;
    my $pcr_lib;

    if ( $dbc->table_loaded('Vector_Based_Library' ) ) {
        ($seq_lib) = $dbc->Table_find( 'Vector_Based_Library', "FK_Library__Name", "WHERE FK_Library__Name = '$library'" );
    }

    if ( $dbc->table_loaded( 'PCR_Product' ) ) {
        ($seq_lib) = $dbc->Table_find( 'Library', "Library_Name", "WHERE Library_Name = '$library' AND Library_Type = 'PCR_Product'" );
    }
    if ( $dbc->table_loaded( 'RNA_DNA_Collection' ) ) {
        ($rna_lib) = $dbc->Table_find( 'RNA_DNA_Collection', "FK_Library__Name", "WHERE FK_Library__Name = '$library'" );
    }

    if ($seq_lib) {
        return 'seq_lib';
    }
    elsif ($rna_lib) {
        return 'rna_lib';
    }
    elsif ($pcr_lib) {
        return 'pcr_product';
    }
    else {
        return 0;
    }
}

########################################################################
# generate DB_Form to create new library (moved from Button_Options)
# return: none
#
# This should be flexible enough to handle all of the various starting points and cases.
#  (eg. brand new original source, using existing SRC, using existing PLA, etc.)
#
#  <snip>
# Eg.
#  print create_new_library(-original_source_id=>$osid,-source_id=>$sid,-plate_id=>$pid);
#
#  </snip>
#
# return initial form (or 0 on error).
#
########################
sub create_new_library {
#######################
    my %args = &filter_input( \@_, -args => 'dbc,orig_source_id,scan_id' );

    my $dbc             = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $orig_source_id  = $args{-orig_source_id};
    my $scanned_id      = $args{-scan_id};
    my $target          = $args{-target};
    my $source_tracking = $args{-source_tracking};

    my %grey;
    my %preset;
    my %hidden;
    my $source_id = 0;
    my $plate_id  = 0;

    $preset{'Goal_Target_Type'} = ['Original Request'];
    $hidden{'Goal_Target_Type'} = 'Original Request';

    ### Figuring out the Original_Source_ID depending on whether a plate or a source scanned in, or nothing scanned in
    if ( $scanned_id =~ /pla/i ) {
        $plate_id = get_aldente_id( $dbc, $scanned_id, "Plate" );
        if ($plate_id) {
            ($orig_source_id) = $dbc->Table_find( 'Plate,Library', 'FK_Original_Source__ID', "WHERE FK_Library__Name=Library_Name AND Plate_ID=$plate_id" );
            my $obj_tables = "Original_Source,Library,Plate";
            my $object     = SDB::DB_Object->new( -dbc => $dbc, -tables => $obj_tables, -load => { 'Plate' => $plate_id } );
            my $lib_type   = $object->get_data("Library_Type");
            if ( $lib_type eq "RNA/DNA" ) {
                $object->add_tables("RNA_DNA_Collection");
            }

            #}elsif ($lib_type eq "Sequencing"){
            #    $object->add_tables("Vector_Based_Library");
            #}
            elsif ($lib_type) {
                my $table = $lib_type . "_Library";
                $object->add_tables("$table");
            }
            $object->load_Object();

            &SDB::DB_Form::preset_fields( -dbc => $dbc, -preset => \%preset, -class => "Plate", -class_id => $plate_id, -object => $object );
        }
        else {
            Message("Error: Invalid plate id $scanned_id");
            return 0;
        }
    }
    elsif ( $scanned_id =~ /src/i ) {
        $source_id = get_aldente_id( $dbc, $scanned_id, "Source" );
        ($orig_source_id) = $dbc->Table_find( 'Source', 'FK_Original_Source__ID', "WHERE Source_ID=$source_id" );
        if ($source_id) {
            my $obj_tables = "Original_Source,Source,Plate,Library";

            my $object = SDB::DB_Object->new( -dbc => $dbc, -tables => $obj_tables, -load => { 'Source' => $source_id } );

            my $lib_type = $object->get_data("Library_Type");
            if ( $lib_type eq "RNA/DNA" ) {
                $object->add_tables( -tables => "RNA_DNA_Collection" );
            }

            #elsif ($lib_type eq "Sequencing"){
            #    $object->add_tables(-tables=>"Vector_Based_Library");
            #}
            elsif ($lib_type) {
                my $table = $lib_type . "_Library";
                $object->add_tables("$table");
            }

            $object->load_Object();

            &SDB::DB_Form::preset_fields( -dbc => $dbc, -preset => \%preset, -class => "Source", -class_id => $source_id, -object => $object );

        }
        else {
            Message("Error: Invalid source id $scanned_id");
            return 0;
        }
    }
    elsif ($scanned_id) {
        Message("Error: Invalid barcode scanned: '$scanned_id'");
        return 0;
    }

    my $tables;
    ### Determine what tables are needed
    if ( !$orig_source_id or $orig_source_id eq 'NULL' ) {
        ### We don't have an Original Source, need to add it
        $tables                                     = 'Original_Source';
        $preset{'Original_Source.Sample_Available'} = $source_tracking;
        $hidden{'Library_Source.FK_Source__ID'}     = "<Source.Source_ID>";    ### Incase Source has been added
    }
    else {
        ### We do have an Original Source and MAYBE a source!
        $grey{'FK_Original_Source__ID'} = $orig_source_id;

        ###  IF we have the Source
        if ($source_id) {
            ###  we ARE doing Source Tracking! So we just need to set the Library_Source.FK_Source__ID
            $tables = 'Library';
            $grey{'Library_Source.FK_Source__ID'} = $source_id;
            if ( $source_tracking ne 'Yes' ) {
                $source_tracking = 'Yes';
            }
        }
        else {
            ###  ELSE we have to figure out if we are source tracking or not
            if ( $plate_id or $source_tracking eq 'Yes' ) {
                ###  IF we are Source Tracking we have to add Source as table
                $tables = 'Source,Library';
                if ($plate_id) {
                    $grey{'Source.FKSource_Plate__ID'} = $plate_id;
                }
            }
            else {
                ###    ELSE if we are NOT
                ###       system will automatically create an External Source
                ###       but we just don't prompt the user with Source table
                $tables = 'Library';
            }

            $grey{'Library_Source.FK_Source__ID'} = "<Source.Source_ID>";
        }
    }

    if ( $source_tracking eq 'Later' ) {
        if ( $tables =~ /Original_Source/ ) {
            $hidden{'Library.Source_In_House'} = 'Yes';
        }
        else {
            $grey{'Library.Source_In_House'} = 'Yes';
        }
    }
    else {
        if ($source_tracking) {
            if ( $tables =~ /Original_Source/ ) {
                $hidden{'Library.Source_In_House'} = $source_tracking;
            }
            else {
                $grey{'Library.Source_In_House'} = $source_tracking;
            }
        }

        $tables .= ',Library_Source';
        $hidden{'Library_Source.FK_Library__Name'} = "<Library.Library_Name>";
    }

    if ( $tables =~ /\bSource\b/ ) {
        ( $preset{'Library.Library_Obtained_Date'} ) = split ' ', date_time();
    }
    else {
        ( $hidden{'Library.Library_Obtained_Date'} ) = split ' ', date_time();
    }
    $hidden{'Library.Library_Completion_Date'} = '0000-00-00';

    $grey{'Library.Library_Status'} = 'Submitted';

    $grey{FKCreated_Employee__ID} = $dbc->get_local('user_id');

    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $tables, -target => $target, -allow_draft => 1 );
    $form->configure( -preset => \%preset, -grey => \%grey, -hidden => \%hidden );
    $form->generate( -navigator_on => 1 );
}

##########################################
# resubmit a library
##########################################
sub resubmit_library {
#####################
    my $self = shift;
    my $dbc  = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my %args = @_;

    my $lib_format  = $args{-lib_format};
    my $source_id   = $args{-source_id};
    my $plate_id    = $args{-plate_id};
    my $lib         = $args{-library};
    my $orig_src_id = $args{-original_source_id};

    my $print       = defined $args{ -print } ? $args{ -print } : 1;
    my $ext_configs = $args{-configs};
    my $more_opts   = $args{-options};
    my @more_options;
    @more_options = @{$more_opts} if ($more_opts);

    # insert Library_Source and Source
    # if original source is blank, then insert the original source branch in the insert.

    my $main_table;
    my @other_tables = ();

    my %grey;
    my %mask;
    my %preset;
    my %hidden;
    my %list;
    my $original_source_id;

    if ($source_id) {
        ($original_source_id) = $dbc->Table_find( "Source", "FK_Original_Source__ID", "WHERE Source_ID=$source_id" );
        $grey{"FK_Source__ID"} = $source_id;
        $main_table = 'Submission';

        #	@other_tables = ('Submission_Table_Link','Library_Source','LibraryApplication','LibraryGoal');
    }
    elsif ($plate_id) {
        $hidden{"FKSource_Plate__ID"} = $plate_id;
        $hidden{"FKParent_Plate__ID"} = $plate_id;

        my ($amount) = $dbc->Table_find( 'Plate', 'Current_Volume',       "where Plate_ID=$plate_id" );
        my ($units)  = $dbc->Table_find( 'Plate', 'Current_Volume_Units', "where Plate_ID=$plate_id" );

        $grey{'Current_Amount'}    = $amount;
        $hidden{'Original_Amount'} = $amount;
        $grey{'Amount_Units'}      = $units;

        $main_table = 'Source';
    }
    else {
        $hidden{'Library_Source.FK_Source__ID'} = "<Source.Source_ID>";
        $main_table = 'Source';
    }

    $grey{"Vector_Based_Library_Format"} = $lib_format;
    $grey{"Source_Type"}                 = $lib_format;
    $grey{'FK_Object_Class__ID'}         = 2;
    my @barcode_list = &get_FK_info( $dbc, "FK_Barcode_Label__ID", -condition => "WHERE Barcode_Label_Type='source'", -list => 1 );
    $list{'FK_Barcode_Label__ID'} = \@barcode_list;

    $lib = $dbc->get_FK_ID( 'FK_Library__Name', $lib ) if ( length($lib) > 5 );

    $hidden{'FK_Rack__ID'}            = 1;
    $preset{'Source_Number'}          = 'TBD';
    $hidden{'FKParent_Source__ID'}    = 0;
    $hidden{'Table_Name'}             = 'Library';
    $hidden{'Key_Value'}              = $lib;
    $hidden{'FK_Original_Source__ID'} = $orig_src_id;
    $hidden{'Source_Status'}          = 'Active';
    $hidden{'FK_Library__Name'}       = $lib;

    my $configs = {};
    if ($ext_configs) {
        $configs = $ext_configs;
    }
    else {
        $configs->{grey}   = \%grey;
        $configs->{omit}   = \%hidden;
        $configs->{preset} = \%preset;
        $configs->{list}   = \%list;
        $configs->{mask}   = \%mask;
    }

    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $main_table, -add_branch => \@other_tables, -wrap => 1, -target => 'Submission', @more_options );

    $form->configure(%$configs);
    return $form->generate( -return_html => 1 );
}
##########################################
# resubmit a library
##########################################
sub submit_work_request {
##########################################
    my $self = shift;
    my $dbc  = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my %args = @_;

    my $lib = $args{-library};

    my $print       = defined $args{ -print } ? $args{ -print } : 1;
    my $ext_configs = $args{-configs};
    my $more_opts   = $args{-options};
    my @more_options;
    @more_options = @{$more_opts} if ($more_opts);

    my $main_table = 'Work_Request';

    my %grey;
    my %mask;
    my %preset;
    my %hidden;
    my %list;

    $lib = $dbc->get_FK_ID( 'FK_Library__Name', $lib ) if ( length($lib) > 5 );

    $hidden{'Table_Name'}       = 'Library';
    $hidden{'Key_Value'}        = $lib;
    $hidden{'FK_Library__Name'} = $lib;

    $list{'Goal_Target_Type'} = [ 'Add to Original Target', 'Included in Original Target' ];
    $preset{'Goal_Target_Type'} = ['Add to Original Target'];

    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $main_table, -wrap => 1, -target => 'Submission', @more_options );

    my $configs = {};
    if ($ext_configs) {
        $configs = $ext_configs;
    }
    else {
        $configs->{grey}   = \%grey;
        $configs->{omit}   = \%hidden;
        $configs->{preset} = \%preset;
        $configs->{list}   = \%list;
        $configs->{mask}   = \%mask;
    }

    $form->configure(%$configs);

    return $form->generate( -return_html => 1 );
}

###########################################
# generate page for prompting work requests
###########################################
sub prompt_for_work_request {
###########################################
    my $self      = shift;
    my $dbc       = $self->{dbc};
    my $form_name = "PromptWorkRequest";

    print alDente::Form::start_alDente_form( $dbc, $form_name );
    my $table = new HTML_Table();
    $table->Set_Title("Work Request Information");
    $table->Set_Row( [ 'Library:' . &alDente::Tools::search_list( -dbc => $dbc, -form => $form_name, -foreign_key => 'FK_Library__Name', -name => 'Library_Name', -default => '', -search => 1, -filter => 1, -breaks => 0 ) ] );

    # textfield(-name=>'List search2',-size=>10,-onChange=>$MenuSearch) . hidden(-name=>'ForceSearch2',-value=>'Search') . popup_menu(-name=>'Library_Name',-values=>["",@libraries],-default=>"")]);
    $table->Set_Row( [ submit( -name => 'Submit Work Request', -class => "Std" ) ] );
    $table->Printout();

    print end_form();

}

###########################################
# generate page for prompting library submission
###########################################
sub prompt_for_submit_library {
###########################################
    my $self = shift;
    my $dbc  = $self->{dbc};

    print alDente::Form::start_alDente_form( $dbc, 'PromptLibrarySubmission' );

    my $table = new HTML_Table();
    $table->Set_Title("Library Submission Information");

    $table->Set_Row( [ "Scan source plate: " . Show_Tool_Tip( textfield( -name => 'Scanned ID' ), "Scan barcode of final ligation product (src or pla)" ) ] );

    #print hidden(-name=>'Library_Type',-value=>'Sequencing',-force=>1);
    print hidden( -name => 'Target', -value => 'Submission', -force => 1 );

    $table->Set_Row( [ submit( -name => 'New Library Page', -label => 'Submit New Library', -class => "Std" ) ] );
    $table->Printout();

    print end_form();

}

###########################################
# generate page for prompting library resubmissions
###########################################
sub prompt_for_resubmit_library {
###########################################
    my $self      = shift;
    my $dbc       = $self->{dbc};
    my $form_name = "PromptResubmit";
    print alDente::Form::start_alDente_form( $dbc, $form_name );

    my @seq_lib_formats = ( '-', 'Ligation', 'Microtiter', 'Xformed_Cells' );
    my %labels = ( '-' => '--Select--' );
    $labels{Microtiter}    = 'Microtiter Plates';
    $labels{Xformed_Cells} = 'Transformed Cells';

    my $table = new HTML_Table();
    $table->Set_Title("Resubmission Information");
    $table->Set_Row( [ 'Select Library :', &alDente::Tools::search_list( -dbc => $dbc, -form => $form_name, -foreign_key => 'FK_Library__Name', -name => 'Library_Name', -default => '', -search => 1, -filter => 1, -breaks => 0 ) ] );

    #textfield(-name=>'List search2',-size=>10,-onChange=>$MenuSearch) . hidden(-name=>'ForceSearch2',-value=>'Search') . popup_menu(-name=>'Library_Name',-values=>["",@libraries],-default=>"",-force=>1)]);
    $table->Set_Row( [ 'Select Format :', RGTools::Web_Form::Popup_Menu( name => 'Resubmit_Sequencing_Library', values => \@seq_lib_formats, labels => \%labels, default => '-', force => 1 ) ] );

    $table->Set_Row( [ submit( -name => 'Resubmit Library', -class => "Std" ) ] );
    $table->Printout();

    print end_form();
}

##############################
# private_methods            #
##############################

########
# Private functions that might be useful
########

#######################################
# does an integrity check of the data. MUST be used before committing data to database.
# also might be useful to integrity check before creating a library.
#######################################
sub _integrity_check {
    my $self = shift;
}

#############################
###sub _init_table {
#############################
###    my $self = shift;
###    my $title = shift;
###
###    my $table = HTML_Table->new();
###    $table->Set_Class('small');
###    $table->Set_Width('100%');
###    $table->Toggle_Colour('off');
###    $table->Set_Line_Colour('#eeeeff','#eeeeff');
###    $table->Set_Title($title,bgcolour=>'#ccccff',fclass=>'small',fstyle=>'bold');
###
###    return $table;
###}

##########################
sub _init_table {
##########################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'title,right,class' );

    my $title   = $args{-title};
    my $right   = $args{-right};
    my $class   = $args{-class} || 'small';
    my $width   = $args{-width} || '100%';
    my $toggle  = $args{-toggle} || 'off';
    my $colour  = $args{-colour} || '#ddddda';
    my $colour2 = $args{-colour2} || '#eeeee8';

    my $table = HTML_Table->new();

    $table->Set_Class($class);
    $table->Set_Width($width);
    $table->Toggle_Colour($toggle);
    $table->Set_Line_Colour( $colour, $colour2 );

    $title = "<Table border=0 cellspacing=0 cellpadding=0 width=100%><TR><TD><font size='-1'><b>$title</b></font></TD><TD align=right class=$class><B>$right</B></TD></TR></Table>" if $title;

    $table->Set_Title( $title, bgcolour => '#ccccff', fclass => 'small', fstyle => 'bold' ) if $title;

    return $table;
}
##############################
# private_functions          #
##############################

#
# MOVE TO Sample.pm module !! (Temporary here)..
#############################################################
# Simple fast extraction of sample_id given plate_id, well
#
# Return: Sample_id (if found)
#################
sub _get_sample_id {
#################
    my %args     = @_;
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id = $args{-plate_id};
    my $well     = $args{-well};

    my ($info) = $dbc->Table_find( 'Plate,Library_Plate', 'Plate_Size,FKOriginal_Plate__ID,Plate.Parent_Quadrant', "WHERE FK_Plate__ID=Plate_ID AND Plate_ID in ($plate_id)" );
    my ( $size, $original_id, $quadrant ) = split ',', $info;

    my $sample_id;
    if ($quadrant) {
        ($sample_id)
            = $dbc->Table_find( 'Plate_Sample,Well_Lookup', 'FK_Sample__ID', "WHERE FKOriginal_Plate__ID=$original_id AND Left(Well,1)=Left(Plate_384,1) AND Substring(Well,2)+0=Substring(Plate_384,2)+0 AND Plate_96='$well' AND Quadrant='$quadrant'" );
    }
    else {
        ($sample_id) = $dbc->Table_find( 'Plate_Sample', 'FK_Sample__ID', "WHERE FKOriginal_Plate__ID=$original_id AND Well='$well' " );
    }
    return $sample_id;
}

#########################
# Trigger:  Tie the library/original source to an external source if the source is not received/barcoded
#########################
sub new_library_trigger {
#########################
    my $self    = shift;
    my $dbc     = $self->{dbc};
    my $library = $self->{id};

    initialize_external_source( -dbc => $self->{dbc}, -library => $library );

    ## reset Project status if required ##
    require alDente::Project;
    alDente::Project::set_Project_status( -dbc => $dbc, -library => $library );

    return 1;
}

#########################
# Trigger:  remove record if it's dumplicate (LibraryApplication)
#########################
sub new_library_assoc_trigger {
#########################
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    my $last;
    if ($id) {
        $last = $id;
    }
    else {
        ($last) = $dbc->Table_find( 'LibraryApplication', 'max(LibraryApplication_ID)' );
    }

    remove_duplicate_LA_records( -dbc => $dbc, -id => $last );
    return 1;
}

#
# Triggered (if set up in Triggers table) events when Library status is updated
#
#
# Return: 1 if success (or non-fatal trigger)
################################
sub update_Status_trigger {
################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $library = $args{-id} || $self->{id};
    my $debug   = $args{-debug} || $self->{debug};

    my $library_list = Cast_List( -list => $library, -to => 'string', -autoquote => 1 );

    my $comment = $args{-comment};
    ## Comments shouldn't be appended to JIRA tickets if not in PRODUCTION mode
    if ( $Configs{PRODUCTION_DATABASE} ne $Configs{DATABASE} ) { $dbc->message("skipping trigger (in $Configs{DATABASE} Database)"); return; }

    use alDente::Work_Request;
    use alDente::Work_Request_Views;

    my %library_funding = $dbc->Table_retrieve(
        'Work_Request,Funding', [ 'group_concat(FK_Library__Name) AS libraries', 'Funding_ID' ], "WHERE FK_Funding__ID=Funding_ID AND FK_Library__Name IN ($library_list)",
        -group => 'Funding_ID',
        -key   => 'Funding_ID',
        -debug => $debug
    );
    my $funding_list = join ',', keys %library_funding;

    if ( !$funding_list ) {return}    ## no current funded work request tied to this library
    my %existing_tickets;

    %existing_tickets = $dbc->Table_retrieve(
        'Work_Request,Funding,Jira', [ 'Jira_Code', 'FK_Funding__ID' ],
        "WHERE FK_Jira__ID=Jira_ID AND FK_Funding__ID = Funding_ID AND (FK_Library__Name IN ($library_list) OR FK_Funding__ID IN ($funding_list)) AND Scope = 'Library'"
        ,
        -debug    => $debug,
        -key      => 'Jira_Code',
        -distinct => 1
    );

    if ( int( keys(%existing_tickets) ) > 0 ) {
        ## ok - SOW already has a tracked ticket ##

        ## file for storing comments while the comments are not sent out to the JIRA tickets
        #my $log_file = $Configs{data_log_dir} . '/update_Status_trigger.log';
        #open my $LOG, ">>$log_file";
        #my $datetime = &date_time();

        my $jira = alDente::Work_Request::setup_jira();
        my $links;
        foreach my $jira_ticket ( keys %existing_tickets ) {
            my $funding_id, my $libraries_changed, my $ticket_comment;
            $funding_id = $existing_tickets{$jira_ticket}{FK_Funding__ID}[0] if ( defined $existing_tickets{$jira_ticket}{FK_Funding__ID} && exists $existing_tickets{$jira_ticket}{FK_Funding__ID}[0] );
            $libraries_changed = join ',', @{ $library_funding{$funding_id}{libraries} } if ( defined $library_funding{$funding_id}{libraries} );
            if ($libraries_changed) {
                $ticket_comment = $comment;
                if ( !$ticket_comment && $libraries_changed ) {
                    $ticket_comment = "Library/Collection status changed for $libraries_changed";
                }

                my $library_progress = alDente::Work_Request_Views::display_Progress_list( -id => $libraries_changed, -dbc => $dbc, -legend => 0, -title => "Current Progress for $libraries_changed Work Request(s)", -status => 'All' );
                $ticket_comment .= alDente::Work_Request::html_to_wiki($library_progress);

                my $link = Jira::get_link( -issue_id => $jira_ticket );
                Message("Appending JIRA Ticket $jira_ticket: $link");

                my $ok = $jira->add_comment( -issue_id => $jira_ticket, -comment => $ticket_comment );

                #if ($LOG) {
                #    print $LOG "Date Time: $datetime\n";
                #    print $LOG "Appending JIRA ticket $jira_ticket:\n";
                #    print $LOG "$ticket_comment\n\n";
                #}

                $links .= "$link; ";
            }
        }

        #if ($LOG) { close($LOG) }
    }

    return;
}

##############################
sub library_analysis_trigger {
##############################
    my $self = shift;

    my %args                      = filter_input( \@_ );
    my $dbc                       = $args{-dbc} || $self->{dbc};
    my $run_analysis_id           = $args{-run_analysis_id};
    my $multiplex_run_analysis_id = $args{-multiplex_run_analysis_id};
    my $genome_id;
    my $ok;
    my $datetime = &date_time();
    if ($run_analysis_id) {
        ($genome_id) = $dbc->Table_find( 'Attribute,Library_Attribute,Run,Plate,Run_Analysis', 'Attribute_Value',
            "WHERE Library_Attribute.FK_Library__Name = Plate.FK_Library__Name and Run.FK_Plate__ID = Plate_ID and Run_Analysis.FK_Run__ID = Run_ID and Run_Analysis_Id = $run_analysis_id and Run_Analysis.Run_Analysis_Type = 'Secondary' AND Library_Attribute.FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'FKAnalysis_Genome__ID'"
        );
        my ($attribute_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = 'FKAnalysis_Genome__ID' and Attribute_Class = 'Run_Analysis'" );
        if ($genome_id) {
            $ok = $dbc->Table_append_array( 'Run_Analysis_Attribute', [ 'FK_Run_Analysis__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' ], [ $run_analysis_id, $attribute_id, $genome_id, 141, $datetime ], -autoquote => 1 );
        }

    }
    elsif ($multiplex_run_analysis_id) {

        ($genome_id) = $dbc->Table_find( 'Run_Analysis,Multiplex_Run_Analysis,Sample,Library_Attribute,Attribute', 'Attribute_Value',
            "WHERE Run_Analysis.Run_Analysis_ID = Multiplex_Run_Analysis.FK_Run_Analysis__ID and Run_Analysis.Run_Analysis_Type = 'Secondary' and Multiplex_Run_Analysis.FK_Sample__ID = Sample_ID  and Multiplex_Run_Analysis_ID = $multiplex_run_analysis_id and Library_Attribute.FK_Library__Name = Sample.FK_Library__Name AND Library_Attribute.FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'FKAnalysis_Genome__ID'"
        );
        if ($genome_id) {
            my ($attribute_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = 'FKAnalysis_Genome__ID' and Attribute_Class = 'Multiplex_Run_Analysis'" );

            $ok = $dbc->Table_append_array(
                'Multiplex_Run_Analysis_Attribute',
                [ 'FK_Multiplex_Run_Analysis__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' ],
                [ $multiplex_run_analysis_id,      $attribute_id,      $genome_id,        141,               $datetime ],
                -autoquote => 1
            );
        }
    }

    return;
}

sub get_library_genome_reference {
    my $self = shift;

    my %args    = filter_input( \@_ );
    my $library = $args{-library};
    my $dbc     = $args{-dbc};

    # check if the library is a pool

    my %genome;
    my @genome = $dbc->Table_find(
        'Attribute,Library_Attribute,Genome',
        'distinct Genome_ID',
        "WHERE Library_Attribute.FK_Library__Name = '$library' AND Library_Attribute.FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'FKAnalysis_Genome__ID' and Attribute_Value = Genome_ID"
    );
    if (@genome) {
        $genome{Library}   = $library;
        $genome{Genome_ID} = $genome[0];
    }
    return \%genome;
}

####################################
sub get_library_analysis_reference {
####################################
    my $self                      = shift;
    my %args                      = filter_input( \@_ );
    my $dbc                       = $args{-dbc} || $self->{dbc};
    my $run_analysis_id           = $args{-run_analysis_id};
    my $multiplex_run_analysis_id = $args{-multiplex_run_analysis_id};
    my $genome_id;
    my $ok;
    if ($run_analysis_id) {
        ($genome_id) = $dbc->Table_find( 'Attribute,Library_Attribute,Run,Plate,Run_Analysis', 'Attribute_Value',
            "WHERE Library_Attribute.FK_Library__Name = Plate.FK_Library__Name and Run.FK_Plate__ID = Plate_ID and Run_Analysis.FK_Run__ID = Run_ID and Run_Analysis_Id = $run_analysis_id and Run_Analysis.Run_Analysis_Type = 'Secondary' AND Library_Attribute.FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'FKAnalysis_Genome__ID'"
        );

    }
    elsif ($multiplex_run_analysis_id) {

        ($genome_id) = $dbc->Table_find( 'Run_Analysis,Multiplex_Run_Analysis,Sample,Library_Attribute,Attribute', 'Attribute_Value',
            "WHERE Run_Analysis.Run_Analysis_ID = Multiplex_Run_Analysis.FK_Run_Analysis__ID and Run_Analysis.Run_Analysis_Type = 'Secondary' and Multiplex_Run_Analysis.FK_Sample__ID = Sample_ID  and Multiplex_Run_Analysis_ID = $multiplex_run_analysis_id and Library_Attribute.FK_Library__Name = Sample.FK_Library__Name AND Library_Attribute.FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'FKAnalysis_Genome__ID'"
        );
    }

    return $genome_id;
}

#######################################
sub remove_duplicate_LA_records {
#######################################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $last = $args{-id};

    my ($info) = $dbc->Table_find( 'LibraryApplication', 'FK_Library__Name,Object_ID,FK_Object_Class__ID', " WHERE LibraryApplication_ID = $last" );
    my ( $library, $object, $class ) = split ',', $info;
    my $duplicates = $dbc->Table_find( 'LibraryApplication', 'LibraryApplication_ID', " WHERE  FK_Library__Name = '$library' and Object_ID = '$object' and FK_Object_Class__ID = $class AND LibraryApplication_ID <> $last" );
    if ($duplicates) {
        $dbc->delete_record( 'LibraryApplication', -field => 'LibraryApplication_ID', -value => $last );
    }

    return 1;

}
###################################
# Trigger:  Tie the library/original source to an external source if the source is not received/barcoded
# ie.  Library Plates are directly supplied from an external collaborator or from another department
#
#
# return:  1
######################################
sub initialize_external_source {
######################################
    my %args = filter_input( \@_, -args => 'library', -mandatory => 'library' );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id = $dbc->get_local('user_id');
    my $library = $args{-library};

    ### find the original_source_info
    my @library_info = $dbc->Table_find( 'Library,Original_Source', 'FK_Original_Source__ID,Source_In_House,Sample_Available', "WHERE Library_Name = '$library' AND FK_Original_Source__ID=Original_Source_ID" );
    my ($sample_type_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = 'undefined'" );

    my $ok;
    my ( $original_source, $source_in_house, $sample_available ) = split ',', $library_info[0];

    if ( $source_in_house eq 'No' or $sample_available eq 'No' ) {
        ### create source record with prefilled external info, library and original source filled in, create library_source record as well
        my @fields = ( 'External_Identifier', 'FK_Sample_Type__ID', 'Source_Status', 'Received_Date', 'Source.FK_Original_Source__ID', 'FKReceived_Employee__ID', 'FK_Rack__ID', 'FK_Barcode_Label__ID' );

        my %values;
        my ($source_label) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_ID', "WHERE Barcode_Label_Name = 'src_no_barcode'" );
        ## Find the exported rack
        my ($exported_rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name = 'Exported'" );
        $values{1} = [ "External Source: $library", $sample_type_id, 'Active', '0000-00-00', $original_source, $user_id, $exported_rack, $source_label ];
        $ok = $dbc->smart_append( -tables => 'Source', -fields => \@fields, -values => \%values, -autoquote => 1 );
        return $ok;
    }
    else {
        return 1;
    }
}

########################################
#
#  Gets the next plate number available in the library
#
################################
sub get_next_plate_number {
################################
    my %args = filter_input( \@_, -args => 'dbc,library,minimum', -mandatory => 'dbc,library' );

    my $dbc        = $args{-dbc};
    my $lib        = $args{-library};
    my $minimum    = $args{-minimum} || 0;
    my $excludeids = $args{-exclude};        ##list of ids that are being updated

    my ($L_minimum) = $dbc->Table_find( 'Library', 'Starting_Plate_Number', "WHERE Library_Name = '$lib'" );

    my $number;
    if ($minimum) {
        $number = $minimum;
        ## get first number that is available above minimum ##
        my $exclude_cond;
        $exclude_cond = "AND Plate_ID NOT IN ($excludeids)" if $excludeids;
        my ($used) = $dbc->Table_find( 'Plate', 'count(*)', "WHERE FK_Library__Name='$lib' AND Plate_Number = $minimum $exclude_cond" );
        while ($used) {
            $minimum++;
            ($used) = $dbc->Table_find( 'Plate', 'count(*)', "WHERE FK_Library__Name='$lib' AND Plate_Number = $minimum" );
        }
        $number = $minimum;
    }
    else {
        ## get one above highest plate number ##
        my $cond = "WHERE FK_Library__name='$lib'";
        $cond .= " AND Plate_ID NOT IN ($excludeids)" if $excludeids;
        my ($max_num) = $dbc->Table_find( 'Plate', 'MAX(Plate_Number)', $cond );
        if ($max_num) {
            $number = $max_num + 1;
        }
        else {
            my ($spn) = $dbc->Table_find( 'Library', 'Starting_Plate_Number', "WHERE Library_Name='$lib'" );
            $number = $spn;
        }
    }
    if ( $number < $L_minimum ) { $number = $L_minimum }

    return $number;
}

#############################
sub set_Library_Status {
#############################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $reason = $args{-reason};
    my $status = $args{-status};
    my $libs   = $args{-libs};
    my $debug  = $args{-debug};
    my @libs   = @$libs if $libs;

    my $library = Cast_List( -list => \@libs, -to => 'String', -autoquote => 1 );
    my @fields  = ('Library_Status');
    my @values  = ("'$status'");
    my $ok;
    if ($reason) {
        push @fields, 'Library_Notes';
        my @libs_with_null_notes = $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Name in ($library) AND Library_Notes is NULL" );
        if ( int(@libs_with_null_notes) ) {
            ## set Library_Notes to $reason
            my $set_notes_list = Cast_List( -list => \@libs_with_null_notes, -to => 'String', -autoquote => 1 );
            my @set_notes_values = ( @values, "'$reason'" );
            $ok = $dbc->Table_update_array( 'Library', \@fields, \@set_notes_values, "where Library_Name in ($set_notes_list)", -debug => $debug );

            ## append $reason to Library_Notes for the libraries with non NULL notes
            my @append_notes_libs = RGmath::minus( \@libs, \@libs_with_null_notes );
            if ( int(@append_notes_libs) ) {
                my $append_notes_list = Cast_List( -list => \@append_notes_libs, -to => 'String', -autoquote => 1 );
                push @values, "Concat(Library_Notes,' ; ','$reason')";
                $ok = $dbc->Table_update_array( 'Library', \@fields, \@values, "where Library_Name in ($append_notes_list)", -debug => $debug );
            }
        }
        else {
            push @values, "Concat(Library_Notes,' ; ','$reason')";
            $ok = $dbc->Table_update_array( 'Library', \@fields, \@values, "where Library_Name in ($library)", -debug => $debug );
        }
    }
    else {
        $ok = $dbc->Table_update_array( 'Library', \@fields, \@values, "where Library_Name in ($library)", -debug => $debug );

    }
}

#############################
sub get_Library_match {
#############################
    #   Input:
    #       a scanned barcode
    #   Output:
    #       bolean indicating if the barcode is a name of a library or not (1 if match)
############################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $barcode = $q->param('Barcode');                 ## Barcode Scanned
    my ($library_name) = $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Name = '$barcode'" );
    if ($library_name) { return 1 }

    #    $barcode =~ s/(\D+)\|(\D+)(\d+)/$1$3\|$2$3/g;  ##   converts AB|CD123 -> AB123|CD123 .. not sure why ?
    #    if ( grep { /$barcode/i } @library_names ) {return 1}
    return;
}

###########################
sub get_Published_files {
###########################
    my %args     = &filter_input( \@_, -self => 'alDente::Library' );
    my $self     = $args{-self};
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $library  = $args{-library} || $self->{id};
    my $proj_Dir = $Configs{project_dir};

    require RGTools::Directory;
    my ($project_name) = $dbc->Table_find( 'Library,Project', 'Project_Path', "WHERE Library_Name = '$library' and FK_Project__ID = Project_ID" );
    unless ($project_name) {
        Message "Failed to find project for library $library";
        return;
    }

    ## FIND Library Published
    my $pattern = $proj_Dir . '/' . $project_name . '/' . $library . '/published/*';
    my @files = Directory::find_Files( -pattern => $pattern );
    @files = sort(@files);
    return \@files;
}

# Wrapper get the tray ids that library construction happened on given a list of libraries
# Returns tray_ids
#
###########################################
sub get_construction_tray_id_info {
###########################################
    my %args            = filter_input( \@_, -args => 'dbc,library' );
    my $dbc             = $args{-dbc};
    my $library         = $args{-library};
    my $id_marker       = $args{-id_marker};                                                  #passed if you want to recieve the tray_id
    my $protocol_marker = $args{-protocol_marker};                                            #passed if you want the construction protocol name
    my $library_list    = Cast_List( -list => $library, -to => 'String', -autoquote => 1 );
    my $limit           = 1;

    my @info;

    my @invoice_protocols = $dbc->Table_find_array( 'Invoice_Protocol', ['Invoice_Protocol_ID'], "WHERE Invoice_Protocol_Type in ('Upstream_Library_Construction','Library_Construction')" );

    my $invoice_protocol_ids = Cast_List( -list => \@invoice_protocols, -to => 'string' );

    my $grouping_field = "Plate.FK_Library__Name as Library";
    my $fields         = "GROUP_CONCAT(DISTINCT Plate_Tray.FK_Tray__ID) AS Tray_ID";
    my $tables         = " 
	    Plate
	    LEFT JOIN Invoiceable_Work ON Invoiceable_Work.FK_Plate__ID = Plate.Plate_ID
	    LEFT JOIN Invoiceable_Prep ON Invoiceable_Prep.FK_Invoiceable_Work__ID = Invoiceable_Work.Invoiceable_Work_ID  AND Invoiceable_Prep.FK_Invoice_Protocol__ID in ($invoice_protocol_ids)
	    LEFT JOIN Plate_Prep ON Invoiceable_Prep.FK_Prep__ID = Plate_Prep.FK_Prep__ID
	    LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID = Plate_Prep.FK_Plate__ID
    ";
    my $condition = "WHERE FK_Library__Name IN ($library_list)";

    my %lib_info = $dbc->Table_retrieve( $tables, [ 'Plate.FK_Library__Name as Library', $fields ], "$condition", -key => 'Library', -group_by => 'Library' );
    my @library_list = Cast_List( -list => $library, -to => 'Array' );
    my @trays;
    foreach my $lib (@library_list) {
        if ( $lib_info{$lib}{Tray_ID}[0] ) {
            push @trays, $lib_info{$lib}{Tray_ID}[0];
        }
        else {
            push @trays, undef;
        }
    }
    return \@trays;

    #   return alDente::View::merge_data_for_table_column( %args, -dbc => $dbc, -data_hash => \%results, -key_list => \@lib_array, -grouping_field => $grouping_field, -field_order => \@fields );
}

# To be used in Invoiced_Work view - returns list of libraries that a library was pooled from
#
# Input: Library_Name
# Output: Array of Library_Name that the input library was pooled with
##############################
sub get_libraries_pooled_from {
#############################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'dbc, library' );
    my $dbc       = $args{-dbc};
    my $libraries = $args{-library};
    my $debug     = $args{-debug};

    my @libraries = @$libraries;
    if ($debug) { print Message "Inside get_libraries_pooled_from for libraries @libraries" }
    return if ( int(@libraries) == 0 );

    my @libraries_pooled_from;
    foreach my $library (@libraries) {
        if ($debug) { print Message "Getting libraries pooled into $library" }

        my ($target_plate) = $dbc->Table_find( 'Plate', 'GROUP_CONCAT(DISTINCT Plate_ID)', "WHERE FK_Library__Name = '$library'", -distinct => 1 );
        if ($debug) { print Message "Plates associated with $library : $target_plate" }

        my ($rearray_request) = $dbc->Table_find( 'ReArray_Request', 'GROUP_CONCAT(DISTINCT ReArray_Request_ID)', "WHERE FKTarget_Plate__ID IN ($target_plate)", -distinct => 1 ) if $target_plate;
        if ($debug) { print Message "ReArray Requests to pool into $library : $rearray_request" }

        my ($source_plate) = $dbc->Table_find( 'ReArray', 'GROUP_CONCAT(DISTINCT FKSource_Plate__ID)', "WHERE FK_ReArray_Request__ID IN ($rearray_request)", -distinct => 1 ) if $rearray_request;
        if ($debug) { print Message "Source plates for ReArray: $source_plate" }

        my ($pooled_from) = $dbc->Table_find( 'Plate', 'GROUP_CONCAT(DISTINCT FK_Library__Name)', "WHERE Plate_ID IN ($source_plate)", -distinct => 1 ) if $source_plate;
        if ($debug) { print Message "Libraries pooled into $library : $pooled_from" }

        push @libraries_pooled_from, $pooled_from;
    }

    return \@libraries_pooled_from;
}

# To be used in Invoice_Work view - returns list of libraries that a library was pooled into
#
# Input: Library_Name
# Output: Array of Library_Name that the input library was pooled into
##############################
sub get_libraries_pooled_into {
##############################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'dbc, library' );
    my $dbc       = $args{-dbc};
    my $libraries = $args{-library};
    my $debug     = $args{-debug};

    my @libraries = @$libraries;
    if ($debug) { print Message "Inside get_libraries_pooled_into for libraries @libraries" }
    return if ( int(@libraries) == 0 );

    my @libraries_pooled_into;
    foreach my $library (@libraries) {
        if ($debug) { print Message "Getting libraries pooled from library $library" }

        my ($source_plate) = $dbc->Table_find( 'Plate', 'GROUP_CONCAT(DISTINCT Plate_ID)', "WHERE FK_Library__Name = '$library'", -distinct => 1 );
        if ($debug) { print Message "Plates associated with $library : $source_plate" }

        my ($rearray_request) = $dbc->Table_find( 'ReArray', 'GROUP_CONCAT(DISTINCT FK_ReArray_Request__ID)', "WHERE FKSource_Plate__ID IN ($source_plate)", -distinct => 1 ) if $source_plate;
        if ($debug) { print Message "ReArray Requests to pool from $library : $rearray_request" }

        my ($target_plate) = $dbc->Table_find( 'ReArray_Request', 'GROUP_CONCAT(DISTINCT FKTarget_Plate__ID)', "WHERE ReArray_Request_ID IN ($rearray_request)", -distinct => 1 ) if $rearray_request;
        if ($debug) { print Message "Target plates for ReArray: $target_plate" }

        my ($pooled_into) = $dbc->Table_find( 'Plate', 'GROUP_CONCAT(DISTINCT FK_Library__Name)', "WHERE Plate_ID IN ($target_plate)", -distinct => 1 ) if $target_plate;
        if ($debug) { print Message "Libraries pooled into from $library : $pooled_into" }

        push @libraries_pooled_into, $pooled_into;
    }

    return \@libraries_pooled_into;
}

#############################
# Given a list of libraries that are about to approve, return their pooled libraries that are ready for approval
#
# Usage:
#	  my $pooled_lib_to_approve = get_pooled_library_for_QC( -library => \@libraries, -attribute => $attribute, -status => $sample_qc_status );
#
# Return:
#	Hash reference. Key is the QC status to set for the pooled libraries, value is a list of pooled libraries ready for QC
###############################
sub get_pooled_library_for_QC {
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->{'dbc'};
    my $library   = $args{-library};                 # array ref of libraries that are about to set library QC status
    my $attribute = $args{-attribute};               # the library QC status attribute. It should be 'Library_QC_Status'
    my $status    = $args{-status};                  # the library QC status that the libraries specified in -library are about to set to
    my $debug     = $args{-debug};

    my %pooled_lib_to_qc;
    $pooled_lib_to_qc{'Approved'}                         = [];
    $pooled_lib_to_qc{'Failed - Proceed with sequencing'} = [];

    if ( $status =~ /Approved/ || $status =~ /Failed - Proceed/ ) {
        ## get all pooled libraries
        my $lib_obj = new alDente::Library( -dbc => $dbc );
        my $pooled_lib = $lib_obj->get_libraries_pooled_into( -dbc => $dbc, -library => $library, -debug => $debug );
        ## get unique pooled libraries
        my @pooled = ();
        foreach my $pl_list (@$pooled_lib) {
            my @pls = split ',', $pl_list;
            foreach my $pl (@pls) {
                if ( !grep /^$pl$/, @pooled ) {
                    push @pooled, $pl;
                }
            }
        }
        if ($debug) { print HTML_Dump "pooled libraries:", \@pooled }

        ##check if all the sublibraries have been approved or in the approve list
        my $sub_libs = $lib_obj->get_libraries_pooled_from( -dbc => $dbc, -library => \@pooled, -debug => $debug );
        my $max_idx = int(@$sub_libs) - 1;
        for my $idx ( 0 .. $max_idx ) {    # loop through each pooled library
            my ($pooled_QC) = $dbc->Table_find( 'Library_Attribute,Attribute', 'Attribute_Value', "WHERE FK_Attribute__ID=Attribute_ID AND Attribute_Class = 'Library' AND Attribute_Name = '$attribute' AND FK_Library__Name = '$pooled[$idx]' " );
            if ($pooled_QC) {next}         # the pooled library has been QCed - ignore

            my @sub = split ',', $sub_libs->[$idx];
            my $not_QCed = 0;
            my %sub_statuses;
            my ( $intersec, $a_only, $b_only ) = &RGmath::intersection( \@sub, $library );
            if ( int(@$intersec) ) { $sub_statuses{"$status"} = int(@$intersec) }
            if ( int(@$a_only) ) {         # a_only is the libraries not in the approve list. check their attribute to see if they have been approved
                my $a_only_str = Cast_List( -list => $a_only, -to => 'string', -autoquote => 1 );
                my %QCed_sub_lib = $dbc->Table_retrieve(
                    -table     => "Library_Attribute,Attribute",
                    -fields    => [ 'FK_Library__Name', 'Attribute_Value' ],
                    -condition => "WHERE FK_Attribute__ID=Attribute_ID AND Attribute_Class = 'Library' AND Attribute_Name = '$attribute' AND FK_Library__Name in ($a_only_str)",
                    -key       => 'FK_Library__Name'
                );
                if ($debug) {
                    print HTML_Dump "QCed sub libraries:", \%QCed_sub_lib;
                }

                my @QC_set = ();
                foreach my $lib ( keys %QCed_sub_lib ) {
                    if ( $QCed_sub_lib{$lib}{Attribute_Value}[0] ) {
                        $sub_statuses{ $QCed_sub_lib{$lib}{Attribute_Value}[0] }++;
                        push @QC_set, $lib;
                    }
                }
                if ( int(@$a_only) > int(@QC_set) ) { $not_QCed = int(@$a_only) - int(@QC_set) }
            }

            if ($debug) {
                print HTML_Dump "sub libraries:", \@sub;
                Message("not_QCed=$not_QCed");
                print HTML_Dump "sub library QC statuses:", \%sub_statuses;
            }

            if ($not_QCed) {next}    # some sub libraries not QCed yet, this pooled library shouldn't be QCed
            elsif ( $sub_statuses{'Failed'} || $sub_statuses{'Approved - On Hold'} ) {next}    # This situation has not been defined yet
            else {
                if ( $sub_statuses{'Approved'} ) {
                    push @{ $pooled_lib_to_qc{'Approved'} }, $pooled[$idx];
                }
                else {
                    push @{ $pooled_lib_to_qc{'Failed - Proceed with sequencing'} }, $pooled[$idx];
                }
            }
        }    # END # loop through each pooled library
    }

    return \%pooled_lib_to_qc;
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

$Id: Library.pm,v 1.115 2004/12/06 23:32:26 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
