##################
# Pipeline.pm #
##################

package alDente::Pipeline;

use base SDB::DB_Object;

use strict;

use CGI qw(:standard);
use Benchmark;
use Data::Dumper;

use RGTools::RGIO;
use RGTools::RGmath;
use RGTools::HTML_Table;

use SDB::HTML;
use SDB::DBIO;
use SDB::CustomSettings qw($Sess $Connection);
use alDente::SDB_Defaults;

use vars qw($Connection $Sess $URL_temp_dir $Current_Department %Benchmark);

$URL_temp_dir = "/opt/alDente/www/dynamic/tmp";

my %pipeline_modules;

$pipeline_modules{'Lab_Protocol'} = "Protocol";

# Load all default config and modify if necessary.
#
#
#########
sub new {
#########
    my $this = shift;
    my %args = filter_input( \@_, -args => "pipeline,dbc", -mandatory => 'dbc' );

    my $pipeline_id = $args{-pipeline} || $args{-id};

    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => ['Pipeline'] );
    my $class = ref($this) || $this;
    bless $self, $class;

    ## Initialization of Attributes

    $self->{pipeline}        = $pipeline_id || '';
    $self->{id}              = $pipeline_id;
    $self->{parent_pipeline} = '';
    $self->{pipeline_steps}  = {};
    ## $self->{pipeline_steps} = {"Pipeline_Step_ID" => "Order"};
    #      					    $self->{pipeline_steps}  = {
    #									1 => {order=>1,parents=>[],object_class=>'Lab_Protocol',object_id=>1},
    #									2 => {order=>2,parents=>[1],object_class=>'Lab_Protocol',object_id=>2},
    #									3 => {order=>2,parents=>[1],object_class=>'Lab_Protocol',object_id=>3},
    #									4 => {order=>3,parents=>[2,3],object_class=>'Lab_Protocol',object_id=>4}
    #									};
    $self->{pipeline_filtering} = [];
    $self->{tracking}           = "Plate_ID";
    $self->{dbc}                = $dbc;

    if ($pipeline_id) {
        $self->{pipeline_id} = $pipeline_id;    ## list of current plate_ids
        $self->primary_value( -table => 'Pipeline', -value => $pipeline_id );    ## same thing as above..
        $self->load_Object();
    }

    $self->load_configuration();
    return $self;
}

# ============================================================================
# Method     : load_configuration()
#
# Usage      : $self->load_configuration();
#
# Purpose    :
# Returns    : none
# Parameters :
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub load_configuration {
    my $self     = shift;
    my %args     = @_;
    my $pipeline = $args{-pipeline} || $self->{pipeline};

    $self->set_pipeline( -pipeline => $pipeline );
    $self->set_pipeline_steps();
    return;
}

# ============================================================================
# Method     : request_broker()
#
# Usage      : request_broker();
#
# Purpose    : Handler
# Returns    : none
# Parameters :
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub request_broker {

    my %args = filter_input( \@_, -args => "dbc,pipeline,pipeline_step" );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $pipeline_search     = param('Search Pipelines');
    my $view_pipeline_steps = param('View_Pipeline_Steps');

    my $pipeline_step = param('Pipeline_Step');
    my @libraries     = @{ _get_library_filter( -dbc => $dbc ) };
    my $libraries     = Cast_List( -list => \@libraries, -to => "String", -autoquote => 1 );

    my $condition = join ' AND ', alDente::Container::parse_plate_filter($dbc);    ## retrieve plate conditions from standard filter
    ## Search for pipelines
    if ($pipeline_search) {
        my $pipelines = &SDB::HTML::get_Table_Param( -table => 'Plate', -field => "FK_Pipeline__ID", -list => 1, -dbc => $dbc );
        my @pipelines = Cast_List( -list => $pipelines, -to => 'Array' );
        @pipelines = map { $dbc->get_FK_ID( 'FK_Pipeline__ID', $_ ) } @pipelines;

        my $display_pipelines = display_pipelines( -pipelines => \@pipelines, -dbc => $dbc, -form => 'Pipeline_Homepage' );

        my $pipeline_obj = alDente::Pipeline->new( -dbc => $dbc );

        #	$pipeline_obj->set_pipeline_filtering(-filtering_options=>"FK_Library__Name IN ($libraries)");

        $pipeline_obj->home_page( -display_pipelines => $display_pipelines, -library_filter => \@libraries, -dbc => $dbc );
    }
    elsif ($view_pipeline_steps) {
        my $pipeline_id       = param('Pipeline_ID');
        my $pipeline_obj      = alDente::Pipeline->new( -pipeline => $pipeline_id, -dbc => $dbc );
        my @pipeline_step     = $dbc->Table_find( 'Pipeline_Step', 'Pipeline_Step_ID', "WHERE FK_Pipeline__ID = $pipeline_id ORDER BY Pipeline_Step_Order" );
        my @pipeline_step_obj = map { $_ = $pipeline_obj->get_pipeline_step_by_id( -pipeline_step_id => $_, -library_filter => \@libraries ) } @pipeline_step;

        $condition = "Plate.Plate_Status = 'Active' AND Plate.Failed = 'No'";

        $pipeline_obj->display_pipeline_steps(
            -pipeline_steps => \@pipeline_step_obj,
            -library_filter => \@libraries,
            -condition      => $condition,
            -dbc            => $dbc,
        );
    }
    elsif ($pipeline_step) {
        my $pipeline_id  = get_pipeline_id_by_pipeline_step( -dbc => $dbc,         -pipeline_step => $pipeline_step );
        my $pipeline_obj = alDente::Pipeline->new( -pipeline      => $pipeline_id, -dbc           => $dbc );

        ## Get the pipeline step and display it
        my $pipeline_step_obj = $pipeline_obj->get_pipeline_step_by_id( -pipeline_step_id => $pipeline_step, -library_filter => \@libraries );

        $condition = "Plate.Plate_Status = 'Active' AND Plate.Failed = 'No'";

        $pipeline_obj->display_pipeline_steps(
            -current_pipeline_step => $pipeline_step,
            -pipeline_steps        => [$pipeline_step_obj],
            -library_filter        => \@libraries,
            -condition             => $condition,
            -display_actions       => 1,
            -dbc                   => $dbc
        );
    }
    else {
        ## Display the default pipeline home page
        my $pipeline_obj = alDente::Pipeline->new( -dbc => $dbc );
        $pipeline_obj->home_page( -dbc => $dbc );
    }

    return;
}

###################
sub home_page {
###################
    my $self              = shift;
    my %args              = filter_input( \@_ );
    my $display_pipelines = $args{-display_pipelines};
    my $library_filter    = $args{-library_filter};
    my $dbc               = $self->{dbc} || $args{-dbc};

    my $home_page = Views::Heading('Pipeline Home Page');
    $home_page .= &Link_To( $dbc->config('homelink'), 'Define New Pipeline', "&New+Entry=Pipeline", -newwin => ['newwin'] ) . '<p ></p>';
    if ( $self->{pipeline} ) {
        my $display = $self->display_pipeline( -form => 'Display_Pipeline', -dbc => $dbc );
        if ($display) {
            $home_page .= alDente::Form::start_alDente_form( $dbc, 'Display_Pipeline', $dbc->homelink() );

            my $pipeline_search_button = submit( -name => 'Search Pipelines', -value => "Search Pipelines", -class => 'Search' );
            use alDente::Container;

            $home_page .= create_tree(
                -tree => {
                    'Filter' => alDente::Container::plate_filter(
                        -dbc      => $self->{dbc},
                        -form     => 'Display_Pipeline',
                        -pipeline => $self->{pipeline},
                        -filter   => 'Pipeline,Library,Status,Project,Plate_Number',
                        -library  => $library_filter,
                        -buttons  => [$pipeline_search_button],
                        -display  => $display_pipelines
                    )
                }
            );
            $home_page .= &Link_To( $dbc->config('homelink'), 'View all pipeline steps', "&Pipeline+Summary=1&View_Pipeline_Steps=1&Pipeline_ID=$self->{pipeline}" ) . '<BR>';
            $home_page .= $self->display_pipeline( -form => 'Display_Pipeline', -dbc => $dbc );

            $home_page .= hidden( -name => 'Pipeline Summary', -value => 1 );

            #  		$home_page .= create_tree(-tree=>{Filter=>$self->p_filter(-library_filter=>$library_filter,-display=>$display_pipelines)});
            $home_page .= end_form();
        }
        else {
            $home_page .= "(No Steps defined for this Pipeline)<P>";
        }
    }
    elsif ($display_pipelines) {
        $home_page .= create_tree( -tree => { 'Pipelines' => $self->display_pipeline_list() } );
    }
    else {
        $home_page .= $self->display_pipeline_list();
        if ( $self->{dbc}->package_active('NCBI') ) {
            $home_page .= $self->display_library_strategy();
        }
    }

    if ( $self->{pipeline} ) {
        $home_page .= $self->show_related_pipelines();
        $home_page .= $self->get_leading_plates();
        $home_page .= hr . $self->get_unstarted_plates();
    }
    print $home_page;
    return 1;
}

############################
sub get_leading_plates {
############################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $pipeline = $args{-pipeline} || $self->{pipeline};

    my $group_list      = $dbc->get_local('group_list');
    my $extra_condition = " AND Library.FK_Grp__ID IN ($group_list)";
    my $group_condition = '';
    my $order_condition = 'Prep_DateTime desc';

    my $tables        = 'Plate,Rack,Pipeline, Library,Original_Source, Anatomic_Site LEFT JOIN Plate as Child on Child.FKParent_Plate__ID=Plate.Plate_ID';
    my @output_fields = (
        'Plate.Plate_ID',
        "CASE WHEN Prep_Name LIKE 'Completed %' THEN 'Completed' WHEN Prep_Name IS NULL THEN 'Ready' ELSE 'In Process' END AS Progress",
        'Prep_Name as Last_Step_Completed',
        'Prep_DateTime as Completion_Time',
        "CONCAT(Library_Name,'-',Plate.Plate_Number,Plate.Parent_Quadrant) AS Plate_Name",
        'Plate.Plate_Status as Status',
        'Plate.Failed',
        'FK_Original_Source__ID as Sample_Origin',
        'Library_FullName',
        'Anatomic_Site_Alias as Anatomical_Site',
        'Rack.Rack_Alias as Current_Location',
    );

    if ($pipeline) {
        $extra_condition .= " AND Pipeline_ID IN ($pipeline)";
        $tables          .= ' LEFT JOIN Pipeline_Step ON Pipeline_Step.FK_Pipeline__ID=Pipeline_ID AND Lab_Protocol_ID=Object_ID';
        push @output_fields, "CASE WHEN FK_Lab_Protocol__ID IS NULL THEN 7 WHEN Pipeline_Step_Order IS NULL THEN Lab_Protocol_Name ELSE CONCAT(LPAD(Pipeline_Step_Order,2,0),': ',Lab_Protocol_Name) END as Protocol";
        $order_condition = 'Protocol, Prep_DateTime DESC';    ### In order to order the layers
    }
    else {
        $extra_condition .= " AND Plate.Plate_Created > ADDDATE(NOW(), Interval -30 day)";
        push @output_fields, 'Plate.FK_Pipeline__ID';
        push @output_fields, "CASE WHEN FK_Lab_Protocol__ID IS NULL THEN 7 ELSE FK_Lab_Protocol__ID END as Protocol", Message("No Pipeline specified - Limiting to Plates created in the last 30 days");
    }

    my $condition
        = "WHERE Plate.FK_Rack__ID=Rack_ID AND Plate.FK_Pipeline__ID = Pipeline_ID AND Plate.Failed = 'No' AND Plate.Plate_Status NOT IN ('Inactive','Exported','Thrown Out','Archived') AND Plate.FK_Library__Name=Library_Name AND FK_Original_Source__ID=Original_Source_ID and FK_Anatomic_Site__ID = Anatomic_Site_ID AND Child.Plate_ID is null $extra_condition";

    $tables    .= ",Prep,Lab_Protocol";
    $condition .= " AND Plate.FKLast_Prep__ID = Prep_ID";
    $condition .= " AND FK_Lab_Protocol__ID = Lab_Protocol_ID";

    my $output = hr
        . $dbc->Table_retrieve_display(
        $tables,
        \@output_fields,
        "$condition $group_condition",
        -order            => $order_condition,
        -limit            => 1000,
        -layer            => 'Protocol',
        -show_count       => 1,
        -title            => "Active Plates (Organized by most Recent Protocol)",
        -return_html      => 1,
        -alt_message      => "(No Active Plates in this Pipeline)",
        -highlight_string => 'In Process',
        );

    return $output;
}

#################################
sub show_related_pipelines {
#################################
    my $self     = shift;
    my %args     = &filter_input( \@_, -args => 'dbc' );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $pipeline = $args{-pipeline} || $self->{pipeline};

    my $output = alDente::Tools::alDente_ref( 'Pipeline', $pipeline ) . hr;
    my $output = Views::Heading( alDente::Tools::alDente_ref( 'Pipeline', $pipeline ) );

    my @parent_list = get_parent_pipelines( -dbc => $dbc, -id => $pipeline );
    if (@parent_list) {
        ## Link to related parent pipelines ##
        my $parents      = int(@parent_list);
        my $parent_links = "<UL>\n";
        foreach my $parent (@parent_list) {
            unless ($parent) {next}
            $parent_links .= '<LI>' . &Link_To( $dbc->config('homelink'), alDente::Tools::alDente_ref( 'Pipeline', $parent ), "&HomePage=Pipeline&ID=$parent" ) . "</LI>\n";
        }
        $parent_links .= "</UL>\n";

        if ( @parent_list > 5 ) {
            $output .= create_tree( -tree => { "Parent Pipelines ($parents)" => $parent_links } );
        }
        else {
            $output .= "<B>Parent Pipelines:</B>\n" . $parent_links;
        }

    }

    my @sibling_list = get_daughter_pipelines( -dbc => $dbc, -id => \@parent_list, -generations => 1 ) if @parent_list;
    if (@sibling_list) {
        ## Link to related sibling pipelines ##
        my $siblings      = int(@sibling_list);
        my $sibling_links = "<UL>\n";
        foreach my $sibling (@sibling_list) {
            unless ( $sibling && ( $sibling != $pipeline ) ) {next}
            $sibling_links .= '<LI>' . &Link_To( $dbc->config('homelink'), alDente::Tools::alDente_ref( 'Pipeline', $sibling ), "&HomePage=Pipeline&ID=$sibling" ) . "</LI>\n";
        }
        $sibling_links .= "</UL>\n";
        if ( @sibling_list > 5 ) {
            $output .= create_tree( -tree => { "Parallel Pipelines ($siblings)" => $sibling_links } );
        }
        else {
            $output .= "<B>Parallel Pipelines:</B>\n" . $sibling_links;
        }
    }

    my @daughter_list = get_daughter_pipelines( -dbc => $dbc, -id => $pipeline );
    if (@daughter_list) {
        ## Link to related daughter pipelines ##
        my $daughters      = int(@daughter_list);
        my $daughter_links = "<UL>\n";
        foreach my $daughter (@daughter_list) {
            unless ($daughter) {next}
            $daughter_links .= '<LI>' . &Link_To( $dbc->config('homelink'), alDente::Tools::alDente_ref( 'Pipeline', $daughter ), "&HomePage=Pipeline&ID=$daughter" ) . "</LI>\n";
        }
        $daughter_links .= "</UL>\n";

        if ( @daughter_list > 5 ) {
            $output .= create_tree( -tree => { "Daughter Pipelines ($daughters)" => $daughter_links } );
        }
        else {
            $output .= "<B>Daughter Pipelines:</B>\n" . $daughter_links;
        }
    }

    return $output;
}

##############################
sub get_unstarted_plates {
##############################
    my $self     = shift;
    my %args     = &filter_input( \@_, -args => 'dbc' );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $pipeline = $args{-pipeline} || $self->{pipeline};

    my $group_list = $dbc->get_local('group_list');
    my $condition .= " AND Library.FK_Grp__ID IN ($group_list)";

    if ($pipeline) {
        $condition .= " AND Pipeline_ID IN ($pipeline)";
    }
    else {
        $condition .= " AND Plate.Plate_Created > ADDDATE(NOW(), Interval -30 day)";
        Message("Limiting to Plates created in the last 30 days");
    }

    $dbc->Benchmark('started_retrieve');
    my $output = $dbc->Table_retrieve_display(
        'Plate,Rack,Pipeline,Library,Original_Source, Anatomic_Site LEFT JOIN Plate as Child on Child.FKParent_Plate__ID=Plate.Plate_ID',
        [   'Pipeline_Name as Pipeline',             'Plate.Plate_ID',   'Library_Name',                               'Plate.Plate_Number',
            'Original_Source_Name as Sample_Origin', 'Library_FullName', 'Anatomic_Site_Alias as Anatomic_Site_Alias', 'Rack.Rack_Alias as Current_Location',
            'Plate.Plate_Status as Status',          'Plate.Failed',
        ],
        "WHERE Plate.FK_Rack__ID=Rack_ID AND Plate.FK_Pipeline__ID = Pipeline_ID and Plate.Failed = 'No' AND Plate.Plate_Status NOT IN ('Inactive','Exported','Thrown Out','Archived') AND Plate.FK_Library__Name=Library_Name AND FK_Original_Source__ID=Original_Source_ID AND FK_Anatomic_Site__ID = Anatomic_Site_ID AND Child.Plate_ID IS NULL AND IF(Plate.FKLast_Prep__ID,0,1) $condition",
        -order       => 'Plate.FK_Library__Name,Plate.Plate_Number',
        -limit       => 1000,
        -show_count  => 1,
        -title       => "Plates awaiting Protocols (no actions yet tracked for this plates)",
        -return_html => 1
    );
    $dbc->Benchmark('completed_retrieve');
    return create_tree( -tree => { 'Pending Plates' => $output }, -print => 0 );
}

###############################
sub display_pipeline_list {
###############################
    my $self       = shift;
    my $department = $self->{dbc}->config('Target_Department');
    my %link_parameters;
    my %static_labels;
    $link_parameters{'Link_1'} = "&HomePage=Pipeline&ID=<VALUE>";
    $static_labels{'Link_1'}   = "Pipeline Page";
    $link_parameters{'Link_2'} = "&cgi_application=alDente::Container_App&rm=Protocol+Summary&Wait=1&FK_Pipeline__ID=<VALUE>";
    $static_labels{'Link_2'}   = "Protocol Summary";

    my $pipeline_list = $self->{dbc}->Table_retrieve_display(
        'Pipeline,Grp,Department LEFT JOIN Pipeline_Step ON Pipeline_Step.FK_Pipeline__ID=Pipeline_ID',
        [ 'Pipeline_ID', 'Grp_Name', 'Pipeline_Name', 'Pipeline_Code', 'Pipeline_Status', 'Pipeline_Description', 'Pipeline_ID AS Link_1', 'Pipeline_ID as Link_2', "count(*) as Steps" ],
        "WHERE FK_Grp__ID = Grp_ID and FK_Department__ID = Department_ID AND Department_Name = '$department'",
        -return_html     => 1,
        -link_parameters => \%link_parameters,
        -static_labels   => \%static_labels,
        -alt_message     => "No Pipelines defined by $department Department",
        -title           => "Current $department Pipelines",
        -group_by        => "Pipeline_ID,Pipeline_Status",
        -layer           => "Pipeline_Status",
        -order_by        => 'Pipeline_Status, Pipeline_Name'
    );
    return $pipeline_list;
}

###############################
sub display_library_strategy {
###############################
    my $self = shift;
    my $dbc  = $self->{dbc};

    my $pipeline_library_strategy_list = vspace(5) . Views::Heading('Library Strategy');

    $pipeline_library_strategy_list .= &Link_To( $dbc->config('homelink'), 'Define New Library Strategy', "&New+Entry=Library_Strategy", -newwin => ['newwin'] ) . vspace(5);

    $pipeline_library_strategy_list .= &Link_To( $dbc->config('homelink'), 'Define New Library Strategy Pipeline', "&New+Entry=Library_Strategy_Pipeline", -newwin => ['newwin'] ) . vspace(5);

    $pipeline_library_strategy_list .= $self->{dbc}->Table_retrieve_display(
        'Pipeline,Library_Strategy_Pipeline,Library_Strategy',
        [ 'Pipeline_ID', 'Pipeline_Name', 'Pipeline_Code', 'Pipeline_Status', 'Pipeline_Description', 'Library_Strategy_Name' ],
        "WHERE Pipeline.Pipeline_ID = Library_Strategy_Pipeline.FK_Pipeline__ID AND Library_Strategy_Pipeline.FK_Library_Strategy__ID = Library_Strategy_ID",
        -return_html => 1,
        -order_by    => 'Library_Strategy_Name,Pipeline_ID',
        -title       => 'Library Strategy And Pipeline Association'
    );
    return $pipeline_library_strategy_list;
}

sub display_pipeline_filtering_options {
    my $self = shift;

    my @input_options = ( 'Library_Name', 'Project_ID', 'Pipeline_ID', 'Grp_ID' );

    ## Use DB Form to create filtering options

    return;
}

sub set_pipeline_filtering {
    my $self              = shift;
    my %args              = filter_input( \@_, -arguments => "filtering_options" );
    my $filtering_options = $args{-filtering_options};
    $self->{pipeline_filtering} = $filtering_options;
    return;
}

sub _get_library_filter {
    my %args = filter_input( \@_ );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $projects = &SDB::HTML::get_Table_Param( -table => 'Library', -field => "FK_Project__ID", -list => 1, -dbc => $dbc );

    my @libraries;
    if ( scalar(@$projects) > 0 ) {
        my @projects = Cast_List( -list => $projects, -to => 'Array' );
        @projects = map { $dbc->get_FK_ID( 'FK_Project__ID', $_ ) } @projects;
        my $project_list = join ',', @projects;
        my @project_libraries = $dbc->Table_find( 'Library', 'Library_Name', "WHERE FK_Project__ID IN ($project_list)" );
        push @libraries, @project_libraries;
    }

    my $libraries_picked = &SDB::HTML::get_Table_Param( -table => 'Plate', -field => "FK_Library__Name", -list => 1, -dbc => $dbc );
    if ( scalar(@$libraries_picked) > 0 ) {
        my @libraries_picked = Cast_List( -list => $libraries_picked, -to => 'Array' );
        @libraries_picked = map { $dbc->get_FK_ID( 'FK_Library__Name', $_ ) } @libraries_picked;
        push @libraries, @libraries_picked;
    }
    return \@libraries;
}

# ============================================================================
# Method     : get_pipeline_steps()
#
# Usage      : $self->get_pipeline_steps();
# Returns    : none
# ============================================================================
sub get_pipeline_steps {
    my $self = shift;
    return $self->{pipeline_steps};
}

# ============================================================================
# Method     : set_pipeline_steps()
#
# Usage      : $self->set_pipeline_steps();
# Returns    : none
# ============================================================================
sub set_pipeline_steps {
    my $self     = shift;
    my %args     = filter_input( \@_, -arguments => 'pipeline_id' );
    my $pipeline = $args{-pipeline_id} || $self->{pipeline};

    ## Get the pipeline steps given the pipeline
    my $tables    = "Pipeline,Pipeline_Step,Object_Class";
    my @fields    = ( 'Pipeline_Step_ID', 'Object_Class', 'Object_ID', 'Pipeline_Step_Order' );
    my $condition = "WHERE Object_Class = 'Lab_Protocol' and Pipeline_ID = FK_Pipeline__ID and FK_Object_Class__ID = Object_Class_ID";
    $condition .= " and Pipeline_ID = $pipeline" if $pipeline;
    $condition .= " ORDER BY Pipeline_Step_Order";

    my %pipeline_steps = $self->{dbc}->Table_retrieve( "$tables", \@fields, "$condition" );

    my $index = 0;
    while ( defined $pipeline_steps{Pipeline_Step_ID}[$index] ) {
        my $pipeline_step_id = $pipeline_steps{Pipeline_Step_ID}[$index];
        my $order            = $pipeline_steps{Pipeline_Step_Order}[$index];
        my $object_class     = $pipeline_steps{Object_Class}[$index];

        my $object_id = $pipeline_steps{Object_ID}[$index];

        ## create new object (ie Lab Protocol)
        my $module = $pipeline_modules{$object_class};

        my $require_class = "alDente::$module";
        eval "require $require_class";

        my $pipeline_step = $require_class->new( -dbc => $self->{dbc}, -id => $object_id, -pipeline_step_id => $pipeline_step_id, -pipeline => $pipeline );

        $pipeline_step->load_configuration();
        ## Find the parent pipeline steps
        my $parent_pipeline_steps = $pipeline_step->get_parent_pipeline_steps();
        $self->{pipeline_steps}{$pipeline_step_id} = {
            order        => $order,
            object_class => $object_class,
            object_id    => $object_id,
            parents      => $parent_pipeline_steps
        };

        $index++;
    }
    ## Set the pipeline steps attributes for the pipeline

    return;
}

sub get_pipeline_id_by_pipeline_step {
    my %args = filter_input( \@_, -args => "dbc,pipeline_step" );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $pipeline_step = $args{-pipeline_step};
    my ($pipeline_id) = $dbc->Table_find( 'Pipeline_Step', 'FK_Pipeline__ID', "WHERE Pipeline_Step_ID = $pipeline_step" );

    return $pipeline_id;
}

# ============================================================================
# Method     : get_pipeline_step_by_id
#
# Usage      : $self->get_pipeline_step_by_id();
# Returns    : Array Ref of Pipeline Steps
# ============================================================================
sub get_pipeline_step_by_id {
    my $self             = shift;
    my %args             = filter_input( \@_, -args => "pipeline_step_id" );
    my $pipeline_step_id = $args{-pipeline_step_id};
    my $library_filter   = $args{-library_filter};

    my $object_class = $self->{pipeline_steps}{$pipeline_step_id}{object_class};
    my $object_id    = $self->{pipeline_steps}{$pipeline_step_id}{object_id};

    ## create new object (ie Lab Protocol)
    my $module = $pipeline_modules{$object_class};

    my $require_class = "alDente::$module";
    eval "require $require_class";
    my $pipeline_step = $require_class->new( -dbc => $self->{dbc}, -id => $object_id, -pipeline_step_id => $pipeline_step_id, -pipeline => $self->{pipeline}, -library_filter => $library_filter );
    $pipeline_step->load_configuration();
    return $pipeline_step;
}

############################
sub get_pipeline_step {
############################
    my %args             = filter_input( \@_ );
    my $dbc              = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $pipeline_step_id = $args{-pipeline_step_id};
    my $library_filter   = $args{-library_filter};

    my %object_info = $dbc->Table_retrieve( 'Pipeline,Pipeline_Step,Object_Class', [ 'Object_Class', 'Object_ID', 'Pipeline_ID' ], "WHERE FK_Pipeline__ID = Pipeline_ID and FK_Object_Class__ID = Object_Class_ID and Pipeline_Step_ID = $pipeline_step_id" );

    my $object_class = $object_info{'Object_Class'}->[0];
    my $object_id    = $object_info{'Object_ID'}->[0];
    my $pipeline     = $object_info{'Pipeline_ID'}->[0];

    ## create new object (ie Lab Protocol)
    my $module = $pipeline_modules{$object_class};

    my $require_class = "alDente::$module";
    eval "require $require_class";
    my $pipeline_step = $require_class->new( -dbc => $dbc, -id => $object_id, -pipeline_step_id => $pipeline_step_id, -pipeline => $pipeline, -library_filter => $library_filter );
    $pipeline_step->load_configuration();
    return $pipeline_step;
}

# ============================================================================
# Method     : get_pipeline_step_by_order()
#
# Usage      : $self->get_pipeline_step_by_order();
# Returns    : Array Ref of Pipeline Steps
# ============================================================================
sub get_pipeline_step_by_order {
    my $self  = shift;
    my %args  = filter_input( \@_, -args => "order" );
    my $order = $args{-order};

}

# ============================================================================
# Method     : get_available_pipelines
#
# Usage      : $self->get_available_pipelines();
# Returns    : Array Ref of Pipelines
# ============================================================================
sub get_available_pipelines {
    my $self   = shift;
    my %args   = filter_input( \@_, -arguments => 'groups', -mandatory => 'groups' );
    my $groups = $args{-groups};

    ## get the available pipelines based on the groups of the user
    my @pipelines = $self->{dbc}->Table_find( 'Pipeline', 'Pipeline_ID', "WHERE FK_Grp__ID IN ($groups)" );

    return \@pipelines;
}

# ============================================================================
# Method     : display_available_pipelines
#
# Usage      : $self->display_available_pipelines();
#
# Purpose    : Display list of pipelines
# Returns    : none
# Parameters :
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub display_available_pipelines {
    my $self = shift;

    return;
}

# ============================================================================
# Method     : get_parent_pipelines
#
# Usage      : get_parent_pipeline($dbc,$pipeline_id);
# Returns    : comma delimited list of parent pipelines including self
# ============================================================================
sub get_parent_pipelines {
#########################################
    my %args = &filter_input( \@_, -args => 'dbc,id', -mandatory => 'dbc,id' );

    my $current_id   = $args{-id};
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $generations  = $args{-generations} || 100;                                                      ## ensure it never runs out of generations..
    my $include_self = $args{-include_self};                                                            ## exclude current_id from list

    my @list;

    my @current_ids = Cast_List( -list => $current_id, -to => 'array' );
    @list = @current_ids if $include_self;

    if ( $generations eq '0' ) { return @list }

    my $csv = join ',', @current_ids;
    my @parent_id = $dbc->Table_find( 'Pipeline', 'FKParent_Pipeline__ID', "WHERE Pipeline_ID IN ($csv)" );

    if ( $parent_id[0] =~ /[1-9]/ ) {
        my @parents = get_parent_pipelines( $dbc, \@parent_id, -generations => $generations - 1, -include_self => 1 );
        push @list, @parents if @parents;
    }

    return @list;
}

# ============================================================================
# Method     : get_daughter_pipelines
#
# Usage      : get_daughter_pipeline($dbc,$pipeline_id);
# Returns    : comma delimited list of daughter pipelines including self
# ============================================================================
sub get_daughter_pipelines {
#########################################
    my %args = &filter_input( \@_, -args => 'dbc,id', -mandatory => 'dbc,id|pipeline|step' );

    my $current_id  = $args{-id}          || $args{-pipeline};
    my $dbc         = $args{-dbc}         || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $generations = $args{-generations} || 100;                                                              ## limit generations to look back (eg 1 => only direct children)
    my $include_self = $args{-include_self};                                                                   ## exclude current_id from list
    ## extend to include parallel pipelines from wihtin same step ##
    my $class = $args{-class};                                                                                 ## eg Lab_Protocol
    my $step  = $args{-step};                                                                                  ## eg Lab_Protocol_ID for Lab Protocols
    my $debug = $args{-debug};

    my @list;

    if ($current_id) {
        ## current pipeline specified ##
        my @current_ids = Cast_List( -list => $current_id, -to => 'array' );

        @list = @current_ids if $include_self;
        if ( $generations eq '0' ) { return @list }                                                            ## return nothing if generations set to zero.
        elsif ( !@current_ids ) { return @list }

        my $csv = join ',', @current_ids;
        my @daughter_id = $dbc->Table_find( 'Pipeline', 'Pipeline_ID', "WHERE FKParent_Pipeline__ID IN ($csv) AND Pipeline_Status = 'Active' ORDER BY Pipeline_ID", -debug => $debug );

        if ( $daughter_id[0] =~ /[1-9]/ ) {
            push @list, @daughter_id;

            my @daughters = get_daughter_pipelines( $dbc, \@daughter_id, -generations => $generations - 1, -include_self => 1, -debug => $debug );
            @list = @{ RGmath::union( \@list, \@daughters ) } if @daughters;
        }
    }

    if ( $class && $step ) {
        ## get all pipelines with current step as first step in pipeline ##
        my @parallel_pipelines = $dbc->Table_find(
            'Pipeline,Pipeline_Step,Object_Class', 'Pipeline_ID',
            "WHERE FK_Pipeline__ID=Pipeline_ID AND FK_Object_Class__ID=Object_Class_ID AND Object_Class='$class' AND Object_ID = $step AND Pipeline_Step_Order=1 AND Pipeline_Status = 'Active'",
            -order_by => 'Pipeline_ID',
            -distinct => 1,
            -debug    => $debug
        );
        @list = @{ RGmath::union( \@list, \@parallel_pipelines ) };
    }

    return @list;
}

# ============================================================================
# Method     : set_parent_pipeline()
#
# Usage      : $self->set_parent_pipeline();
# Returns    : none;
# ============================================================================
sub set_parent_pipeline {
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'pipeline', -mandatory => 'pipeline' );
    my $pipeline = $args{-pipeline};
    $self->{parent_pipeline} = $pipeline;
    return;
}

# ============================================================================
# Method     : set_pipeline()
#
# Usage      : $self->set_pipeline();
# Returns    : none;
# ============================================================================
sub set_pipeline {
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'pipeline', -mandatory => 'pipeline' );
    my $pipeline = $args{-pipeline};
    $self->{pipeline} = $pipeline;
    return;
}

# ============================================================================
# Method     : get_pipeline()
#
# Usage      : $self->get_pipeline();
# Returns    : none;
# ============================================================================
sub get_pipeline {
    my $self = shift;
    return $self->{pipeline};
}

# ============================================================================
# Method     : add_pipeline_step()
#
# Usage      : $self->add_pipeline_step();
#
# Purpose    : Add pipeline step to a pipeline
# Returns    : none
# Parameters :
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub add_pipeline_step {
    my $self             = shift;
    my %args             = filter_input( \@_, -args => 'object_id,object_class,order' );
    my $pipeline_step_id = $args{-object_id};
    my $object_class     = $args{-object_class};
    my $order            = $args{-order};

    return $pipeline_step_id;
}

# ============================================================================
# Method     : delete_pipeline_step()
#
# Usage      : $self->delete_pipeline_step();
#
# Purpose    : Delete pipeline step from a pipeline
# Returns    : none
# Parameters :
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub delete_pipeline_step {
    my $self             = shift;
    my %args             = filter_input( \@_, -args => 'pipeline_step_id' );
    my $pipeline_step_id = $args{-pipeline_step_id};
    my $deleted;

    return $deleted;
}

sub display_pipeline {
    my $self                    = shift;
    my %args                    = filter_input( \@_ );
    my $form                    = $args{-form};
    my $pipeline_output         = "";
    my $pipeline_id             = $self->{pipeline};
    my $highlight_pipeline_step = $args{-highlight_pipeline_step};
    my $no_action               = $args{-no_action};
    my $dbc                     = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $homelink = $dbc->homelink();

    ## Find the maximum pipeline step order
    my ($pipeline_info) = $self->{dbc}->Table_find( 'Pipeline,Pipeline_Step', 'MAX(Pipeline_Step_Order),Pipeline_Name,Pipeline_Code', "WHERE FK_Pipeline__ID = Pipeline_ID" . " and Pipeline_ID = $pipeline_id GROUP BY Pipeline_ID" );
    my ( $max_pipeline_step_order, $pipeline_name, $pipeline_code ) = split ',', $pipeline_info;
    my @pipeline_info;

    $pipeline_output .= hidden( -name => 'Pipeline_Step', -value => '' );

    foreach my $pipeline_step ( sort { $self->{pipeline_steps}{$a}{order} <=> $self->{pipeline_steps}{$b}{order} } keys %{ $self->{pipeline_steps} } ) {
        my $pipeline_step_action = '';
        if ( !$no_action ) {

            #$pipeline_step_action = "SetSelection(document.$form,'Pipeline_Step','$pipeline_step');$form.submit();return false;";
            $pipeline_step_action = "$homelink&Pipeline+Summary=1&Pipeline_Step=$pipeline_step&Pipeline_ID=$pipeline_id";
        }

        my $object_class  = $self->{pipeline_steps}{$pipeline_step}{object_class};
        my $object_id     = $self->{pipeline_steps}{$pipeline_step}{object_id};
        my $display_value = $self->{dbc}->get_FK_info( -field => "Object_ID", -id => $object_id, -class => $object_class );
        push @pipeline_info,
            {
            ID      => $pipeline_step,
            Display => $display_value,
            Gen     => $self->{pipeline_steps}{$pipeline_step}{order},
            Action  => "$pipeline_step_action",
            Parents => $self->{pipeline_steps}{$pipeline_step}{parents}
            };

    }
    unless (@pipeline_info) {return}

    eval "require SDB::GD_Tools";
    $pipeline_output .= SDB::GD_Tools::draw_lineage(
        -dbc         => $self->{dbc},
        -lineage     => \@pipeline_info,
        -max_gen     => $max_pipeline_step_order,
        -title       => $pipeline_name,
        -file        => "$pipeline_code$highlight_pipeline_step",
        -file_path   => $URL_temp_dir,
        -action_type => "GET",
        -highlight   => $highlight_pipeline_step,
        -no_action   => $no_action,
    );

    return $pipeline_output;
}

###########################
sub display_pipelines {
###########################
    my %args      = @_;
    my $pipelines = $args{-pipelines};
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $form      = $args{-form};

    my $display_pipelines = '';

    my $pipeline_summary = HTML_Table->new( -title => "Pipeline Summary" );
    foreach my $pipeline ( @{$pipelines} ) {

        ## create new pipeline
        my $pipeline_obj = alDente::Pipeline->new( -pipeline => $pipeline, -dbc => $dbc );

        my $pipeline_display_output = $pipeline_obj->display_pipeline( -form => $form, -dbc => $dbc );
        ## add to pipelines list
        $pipeline_summary->Set_Row( [$pipeline_display_output] ) if keys %{ $pipeline_obj->get_pipeline_steps };
    }
    if ( $pipeline_summary->{rows} ) {
        $display_pipelines .= $pipeline_summary->Printout(0);
    }
    else {
        $display_pipelines .= "No Protocols currently tied to this Pipeline";
    }

    return $display_pipelines;
}

#################################
sub display_pipeline_steps {
#################################
    my $self                  = shift;
    my %args                  = filter_input( \@_ );
    my $current_pipeline_step = $args{-current_pipeline_step};
    my $pipeline_steps        = $args{-pipeline_steps};
    my $library_filter        = $args{-library_filter};
    my $condition             = $args{-condition};
    my $display_actions       = $args{-display_actions};
    my $dbc                   = $self->{dbc} || $args{-dbc};

    my $display_pipeline_output;

    return if ( !$pipeline_steps );

    my $form = 'Pipeline';

    $display_pipeline_output .= alDente::Form::start_alDente_form( $dbc, $form, $dbc->homelink() );
    $display_pipeline_output .= hidden( -name => 'Pipeline Summary', -value => 1 );

    my @pipeline_step_filters = ( 'Plate.Plate_Number', 'Plate.FK_Plate_Format__ID', 'Plate.Plate_Created' );

    my $pipeline_step_filters = new SDB::DB_Form( -dbc => $self->{dbc}, -wrap => 0, -fields => \@pipeline_step_filters, );
    my $filter_form = $pipeline_step_filters->generate(
        -return_html  => 1,
        -action       => 'search',
        -title        => 'Select Criteria for Ready Plates',
        -navigator_on => 0
    );

    $display_pipeline_output .= create_tree(
        -tree => {
            'Adjust Filter' => alDente::Container::plate_filter(
                -dbc     => $self->{dbc},
                -form    => $form,
                -filter  => 'Pipeline,Library,Status,Project,Plate_Number,Plate_Format',
                -buttons => ["Click on Protocol Below to Regenerate"],
            )
        }
    );

    my $view_all_pipeline_steps = &Link_To( $dbc->config('homelink'), 'View all pipeline steps', "&Pipeline+Summary=1&View_Pipeline_Steps=1&Pipeline_ID=$self->{pipeline}", -colour => 'white' );
    my $pipeline_table = HTML_Table->new( -title => "Pipeline Step Summary ($view_all_pipeline_steps)" );

    ## Display the pipeline with the pipeline step highlighted
    my $pipeline_display = $self->display_pipeline( -form => $form, -highlight_pipeline_step => $current_pipeline_step, -dbc => $dbc );
    my @pipeline_steps = @{$pipeline_steps};
    $pipeline_table->Set_Row( [$pipeline_display] );
    $display_pipeline_output .= hidden( -name => 'Plate.FK_Library__Name', -value => $library_filter, -force => 1 );
    $display_pipeline_output .= $pipeline_table->Printout(0);
    $display_pipeline_output .= end_form();
    my $pipeline_step_output = HTML_Table->new( -class => 'small', -title => '' );

    foreach my $pipeline_step (@pipeline_steps) {
        my $column = $pipeline_step->display_pipeline_step( -condition => $condition, -display_actions => $display_actions );

        $pipeline_step_output->Set_Column( [$column] );
    }
    $pipeline_step_output->Set_VAlignment('top');
    $display_pipeline_output .= $pipeline_step_output->Printout(0);
    $display_pipeline_output .= create_tree( -tree => { 'Condition' => $condition } );

    print $display_pipeline_output;
}

# Trigger on inserting a pipeline step
#
#
#
###########################
sub pipeline_step_trigger {
###########################
    my %args             = filter_input( \@_, -args => 'dbc,pipeline_step_id' );
    my $pipeline_step_id = $args{-pipeline_step_id};                               ## ID of the Pipeline Step
    my $dbc              = $args{-dbc};
    my $debug            = 0;

    #<Construction> previous trigger not very robust
    #my ($pipeline) = $dbc->Table_find('Pipeline_Step','FK_Pipeline__ID', "WHERE Pipeline_Step_ID = $pipeline_step_id");
    #update_pipeline_step_order(-pipeline_step_id=>$pipeline_step_id, -pipeline_id=>$pipeline,-dbc=>$dbc);

    ## Add the pipeline_step relationship (Assumes linear relationship)
#my @pipeline_step_info = $dbc->Table_find('Pipeline_Step,Pipeline LEFT JOIN Pipeline_Step as Parent ON (Parent.FK_Pipeline__ID = Pipeline_ID AND Parent.Pipeline_Step_Order = Pipeline_Step.Pipeline_Step_Order - 1)', "Parent.Pipeline_Step_ID,Pipeline_Step.Pipeline_Step_ID", "WHERE Pipeline_Step.Pipeline_Step_ID = $pipeline_step_id and Pipeline_Step.FK_Pipeline__ID = Pipeline_ID");

    #my ($parent_pipeline_step,$child_pipeline_step) = split ',', $pipeline_step_info[0];

    #if ($parent_pipeline_step && $child_pipeline_step) {
    #    my $ok = $dbc->Table_append_array('Pipeline_StepRelationship',['FKParent_Pipeline_Step__ID','FKChild_Pipeline_Step__ID'], [$parent_pipeline_step,$child_pipeline_step]);
    #}

    my @pipeline_step_info = $dbc->Table_find( 'Pipeline_Step', 'FK_Pipeline__ID,Pipeline_Step_Order', "WHERE Pipeline_Step_ID = $pipeline_step_id", -debug => $debug );
    my ( $pipeline, $pipeline_step_order ) = split ',', $pipeline_step_info[0];

    #check for parent pipeline_step
    my @parent_pipeline_step_info = $dbc->Table_find(
        'Pipeline_Step LEFT JOIN Pipeline_StepRelationship ON Pipeline_Step_ID = FKParent_Pipeline_Step__ID',
        'Pipeline_Step_ID, FKParent_Pipeline_Step__ID',
        "WHERE Pipeline_Step_Order = ($pipeline_step_order - 1) and FK_Pipeline__ID = $pipeline",
        -debug => $debug
    );
    my ( $parent_pipeline_step, $FKparent_pipeline_step ) = split ',', $parent_pipeline_step_info[0];

    #if parent step present but the relationship not present then update
    if ( $parent_pipeline_step && !$FKparent_pipeline_step ) {
        my $ok = $dbc->Table_append_array( 'Pipeline_StepRelationship', [ 'FKParent_Pipeline_Step__ID', 'FKChild_Pipeline_Step__ID' ], [ $parent_pipeline_step, $pipeline_step_id ] );
    }

    #check for child pipeline_step
    my @child_pipeline_step_info = $dbc->Table_find(
        'Pipeline_Step LEFT JOIN Pipeline_StepRelationship ON Pipeline_Step_ID = FKChild_Pipeline_Step__ID',
        'Pipeline_Step_ID, FKChild_Pipeline_Step__ID',
        "WHERE Pipeline_Step_Order = ($pipeline_step_order + 1) and FK_Pipeline__ID = $pipeline",
        -debug => $debug
    );
    my ( $child_pipeline_step, $FKchild_pipeline_step ) = split ',', $child_pipeline_step_info[0];

    #if child step present but the relationship not present then update
    if ( $child_pipeline_step && !$FKchild_pipeline_step ) {
        my $ok = $dbc->Table_append_array( 'Pipeline_StepRelationship', [ 'FKParent_Pipeline_Step__ID', 'FKChild_Pipeline_Step__ID' ], [ $pipeline_step_id, $child_pipeline_step ] );
    }

    return 1;
}
################################
sub update_pipeline_step_order {
################################
    my %args             = filter_input( \@_, -args => 'pipeline_step_id,pipeline_id' );
    my $pipeline_step_id = $args{-pipeline_step_id};                                       # Plate Schedule ID
    my $pipeline_id      = $args{-pipeline_id};
    my $dbc              = $args{-dbc};
    my ($pipeline_step_order) = $dbc->Table_find( 'Pipeline_Step', 'MAX(Pipeline_Step_Order)', "WHERE FK_Pipeline__ID = $pipeline_id" );

    my $ok = $dbc->Table_update_array( 'Pipeline_Step', ["Pipeline_Step_Order"], [ ++$pipeline_step_order ], "WHERE Pipeline_Step_ID = $pipeline_step_id" );

    return 1;
}

##############################
# Retrieve pipeline IDs with the specified name
#
# Usage:	my @pipelines = @{get_pipeline_by_name( -name => $name )};
#
# Return:	Array ref
#############################
sub get_pipeline_by_name {
#############################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $name = $args{-name};
    my $dbc  = $args{-dbc} || $self->{dbc};

    my @ids = ();
    push @ids, $dbc->Table_find( 'Pipeline', 'Pipeline_ID', "WHERE Pipeline_Name = '$name'" );
    return \@ids;
}

##############################
# Craete new pipeline. This adds records to Pipeline and Pipeline_Step tables
#
# Usage:	my $new_pipeline = add_pipeline( -name => $pipeline_name, -steps => \%steps );
#
# Return:	Scalar, the new pipeline ID
#############################
sub add_pipeline {
#############################
    my $self          = shift;
    my %args          = filter_input( \@_, -args => 'dbc,pipeline,steps', -mandatory => 'pipeline' );
    my $dbc           = $args{-dbc} || $self->{dbc};
    my $pipeline_info = $args{-pipeline};                                                               # hash ref
    my $steps         = $args{-steps};                                                                  # hash ref

    my @fields = ( 'Pipeline_Name', 'FK_Grp__ID', 'Pipeline_Description', 'Pipeline_Code', 'FKParent_Pipeline__ID', 'FK_Pipeline_Group__ID', 'Pipeline_Status', 'FKApplicable_Plate_Format__ID', 'Pipeline_Type' );
    my @values = (
        $pipeline_info->{name},           $pipeline_info->{group}, $pipeline_info->{description},             $pipeline_info->{code}, $pipeline_info->{parent_pipeline},
        $pipeline_info->{pipeline_group}, 'Active',                $pipeline_info->{applicable_plate_format}, $pipeline_info->{type}
    );
    my $new_id = $dbc->Table_append_array(
        -dbc       => $dbc,
        -table     => 'Pipeline',
        -fields    => \@fields,
        -values    => \@values,
        -autoquote => 1
    );

    if ($new_id) {
        Message("Created new Pipeline $new_id");
    }
    else {
        Message("Create new Pipeline failed ( $pipeline_info->{name} )");
        return 0;
    }

    return $new_id if ( !$steps );

    ## add pipeline steps
    my @step_fields = ( 'FK_Object_Class__ID', 'Object_ID', 'Pipeline_Step_Order', 'FK_Pipeline__ID' );
    foreach my $step ( keys %$steps ) {
        my @step_values = ( $steps->{$step}{object_class_id}, $steps->{$step}{object_id}, $step, $new_id );
        my $new_step_id = $dbc->Table_append_array(
            -dbc       => $dbc,
            -table     => 'Pipeline_Step',
            -fields    => \@step_fields,
            -values    => \@step_values,
            -autoquote => 1
        );
        if ($new_step_id) {
            Message("Created new Pipeline_Step $new_step_id");
        }
        else {
            Message("Create new Pipeline_Step failed ( Pipeline $new_id step $step )");
        }
    }

    return $new_id;
}

##############################
# Get the last pipeline code for a specified pipeline type
#
# Usage:	my $last_code = get_last_pipeline_code( -type => 'Illumina' );
#
# Return:	Scalar
###############################
sub get_last_pipeline_code {
###############################
    my $self            = shift;
    my %args            = filter_input( \@_, -args => 'dbc,type', -mandatory => 'type' );
    my $dbc             = $args{-dbc} || $self->{dbc};
    my $type            = $args{-type};
    my $extra_condition = $args{-condition} || '1';

    my ($last_code) = $dbc->Table_find(
        -table     => 'Pipeline',
        -fields    => 'Pipeline_Code',
        -condition => "WHERE Pipeline_Type = '$type' AND $extra_condition",
        -order_by  => 'Pipeline_Code desc limit 1',
    );
    return $last_code;
}

##########################
# Get the Grp_Access privileges for the specified pipeline
#
# Example:	my @access = get_grp_access( -dbc => $dbc, -id => $id, -grp_ids => '8,9' );
#
# Return:	Hash Ref of Grp ID and Grp_Access
##########################
sub get_grp_access {
##########################
    my $self        = shift;
    my %args        = filter_input( \@_, -args => 'dbc,id,grp_ids' );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $pipeline_id = $args{-id} || $self->{id};
    my $grp_ids     = $args{-grp_ids};

    if ( !$pipeline_id ) { return $dbc->error("No pipeline selected!") }

    ## get all the group access privileges
    my %grp_access;
    my %access_info = $dbc->Table_retrieve( 'GrpPipeline', [ 'FK_Grp__ID', 'Grp_Access' ], "WHERE FK_Pipeline__ID = $pipeline_id" );
    my $index = 0;
    while ( defined $access_info{FK_Grp__ID}[$index] ) {
        $grp_access{ $access_info{FK_Grp__ID}[$index] } = $access_info{Grp_Access}[$index];
        $index++;
    }

    ## the group of Pipeline.FK_Grp__ID always has Admin access
    my ($home_grp) = $dbc->Table_find( 'Pipeline', 'FK_Grp__ID', "WHERE Pipeline_ID = $pipeline_id" );
    $grp_access{$home_grp} = 'Admin';

    ## extend to the derived groups
    foreach my $grp ( keys %grp_access ) {
        my @derived_grps = alDente::Grp::_get_Groups_above( $dbc, $grp );    # get all the derived groups
        foreach my $derived_grp (@derived_grps) {
            if ( !$grp_access{$derived_grp} ) {                              # only inherit when this derived group doesn't have privilege set explicitly
                $grp_access{$derived_grp} = $grp_access{$grp};
            }
        }
    }

    ## filter the groups
    if ($grp_ids) {
        my %selected_grp_access;
        my @grp_list = Cast_List( -list => $grp_ids, -to => 'array' );
        foreach my $grp (@grp_list) {
            if ( $grp_access{$grp} ) { $selected_grp_access{$grp} = $grp_access{$grp} }
        }
        return \%selected_grp_access;
    }
    else { return \%grp_access }
}

return 1;
