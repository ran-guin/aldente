###################################################################################################################################

=pod
alDente::View_App.pm
 	
Description:
Controller for View
Controls View.pm
 
View.pm class is the class responsible for creating the Run (e.g., genechip run, bioanalyzer run, etc.) summary page.
Run specific configuration should be implemented in sub-classes (e.g., Lib_Construction::Genechip_Summary.pm)
This class implements 1) the general logic, and 2) the page layout.
1) Logic:
    Once a HTTP request is received to view a run, alDente::View::request_broker is called upon to create the approperiate type
    of object with its default input/output options (e.g., a Lib_Construction::Genechip_Summary object). 
    This object will be carried over all subsequence actions performed on the page. 
    Depending on actions, the configurations of the object may change.
    Once an object is created, it will perform the following tasks:
    1) Display the input/output/view options
    2) Parse the parameters for input/output/view options selected by the user
    3) Use API calls/SQL queries to retrieve the results
    4) Display the results
    5) Respond to actions performed on selected results
2) Page layout:
    The view page has three major areas:
    1) Input/output/view options
       Input options: searching conditions
       Output options: columns to include in the result table
       View options: saved views to be selected by the user
    2) Results
       Table containing the result set
    3) Actions
       Available actions to be performed on the selected results

 
Written by: Ash Shafiei July 2008
=cut

###################################################################################################################################
package alDente::View_App;

use base RGTools::Base_App;
use strict;

## SDB modules
use SDB::CustomSettings;

#use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Conversion;

#use RGTools::Views;

## alDente modules
use alDente::Tools;
use alDente::SDB_Defaults;
use alDente::View_Views;
use alDente::View;

###########################
sub setup {
###########################
    my $self = shift;

    $self->start_mode('Default Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Default Page'       => 'search_page',
        'Main'               => 'main_page',
        'Display'            => 'file_page',
        'Frozen'             => 'frozen_page',
        'Generate Results'   => 'results_page',
        'Results'            => 'results_page',
        'Generate View'      => 'generate_form_results',
        'Track Progress'     => 'view_Project_Report',
        'Manage View'        => 'manage_View',
        'Customize View'     => 'manage_View',
        'Save Public View'   => 'save_View',               ## all save view run modes pass through same method logic ##
        'Save Internal View' => 'save_View',
        'Save Group View'    => 'save_View',
        'Save Employee View' => 'save_View',
        'Save My View'       => 'save_View',
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    $self->param( 'Model' => alDente::View->new( -dbc => $dbc ) );

    return 0;
}

###########################
sub search_page {
###########################
    #  Default Page => search_page
    #
    #	This is the default page if no information is supplied to the View_App
    #	It is used by department.pm
    #	This runmode simply displays a full list of saved views
###########################
    my $self           = shift;
    my $q              = $self->query;
    my $dbc            = $self->param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $scope          = $self->param('Scope') || $q->param('Scope');                                             #gotta figure out
    my $source         = $self->param('Source Call') || $q->param('Source Call') || 'alDente::View_App';
    my $open           = $self->param('Open View') || $q->param('Open View');
    my $empty     = $q->param('Empty Save Error');
    my $filter_by_dept = defined $q->param('filter_by_department') ? $q->param('filter_by_department') : 1;

    my $sections = $q->param('Sections');                                                                         ## options include: Public, Group, Employee, Other

    my $dept;
    if ($filter_by_dept) { $dept = $dbc->config('Target_Department') }
    return $self->View->search_page(-scope=>$scope, -source=>$source, -open=>$open, -empty=>$empty, -dept=>$dept, -sections=>$sections);
    
    # my @views = qw(Public Internal Group Employee);                                                               ## default EXCLUDES Other (to save on load time)
    #    if ($sections) { @views = Cast_List( -list => $sections, -to => 'array' ) }

}

#################################
sub main_page {
###########################
    #	Main => main_page
    #	This run mode takes in a view object (or inherited view object) and returns an html form to be printed
    #
###########################
    my $self             = shift;
    my $q                = $self->query;
    my $dbc              = $self->param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $generate_results = $self->param('Generate Results');                                                        ## whether to generate results (from param("Generate Results")
    my $object           = $self->param('Object');                                                                  ## the object used, the view
    my $source           = $self->param('Source Call') || 'alDente::View_App';                                      ## the Application that calls View.pm
    my $delete           = $q->param('Delete_This_View') || $self->param('Delete_This_View');                       ## saved view file to be deleted
    my $save             = $q->param('Save View For') || $self->param('Save View For');                             ## indication to save view
    my $filter_by_dept   = defined $q->param('filter_by_department') ? $q->param('filter_by_department') : 1;

    if ($delete) { delete_View( -delete => $delete ) }
    if ($save) {
        $dbc->message("Writing into file ...");
        $object->write_to_file( -dbc => $dbc );
    }
    my $form = $self->View->return_View(
        -view             => $object,
        -generate_results => $generate_results,
        -source           => $source,
        -filter_dept      => $filter_by_dept,
        -dbc              => $dbc,
        -context          => 'main',
        -log              => 1,
    );

    return $form;
}

####################
sub manage_View {
####################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    #    my $generate_view = $args{-generate_view} || $q->param("Generate View");
    my $frozen          = $args{-frozen}          || $q->param('Frozen_Config');     ## the frozen copy
    my $new_class       = $args{-class}           || $q->param('Class');             ## specify class if not View_Generator (accepted value: Query_Summary)
    my $referenced_view = $args{-referenced_view} || $q->param('Referenced_View');
    my $file            = $args{-file}            || $q->param('File');
    my $run_mode        = $q->param('rm');

    my $title        = $q->param("Title");
    my $query_tables = $q->param('Query Tables');

    #my $query_generator;
    my $thawed;

    if ($frozen) {
        $thawed = Safe_Thaw( -name => 'Frozen_Config', -thaw => 1, -encoded => 1 );
    }
    elsif ($file) {
        $thawed = alDente::View::load_view( -view => $file, -dbc => $dbc );
    }

    ## if not in production mode, check if there is a production version with a more recent timestamp
    if ( $Configs{default_mode} !~ /production/i ) {
        my $current_file = $thawed->{view};
        my $view_dir     = $thawed->{view_directory};
        $current_file =~ s|//|/|g;
        $view_dir     =~ s|//|/|g;
        my $local_name;
        my $prod_file;
        if ( $current_file =~ /$view_dir\/?(.+)/ ) {
            $local_name = $1;
        }
        if ($local_name) {
            $prod_file = "$Configs{'views_dir'}/$Configs{PRODUCTION_DATABASE}/$local_name";
        }
        if ( cmp_file_timestamp( $prod_file, $current_file ) >= 1 ) {
            $dbc->message("This view has a newer version in PRODUCTION version --- $prod_file");
            $dbc->message("Please update your working copy first before continue!");
        }
    }

    if ( $run_mode !~ /Customize/ ) { $referenced_view = '' }
    
    eval "require alDente::View_Generator";
    my $query_generator = alDente::View_Generator->new( -thawed => $thawed, -dbc => $dbc, -class => $new_class, -referenced_view => $referenced_view );

    my $page = $query_generator->home_page( -generate_view => 1, -title => $title, -query_tables => $query_tables );

    return $page;
}

#################################
sub view_Project_Report {
###########################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $file      = $self->param('File') || $q->param('File');
    my $source    = $q->param('Source Call') || $self->param('Source Call') || 'alDente::View_App';          ## the Application that calls View.pm
    my $view_name = $q->param('View');                                                                       ## fully qualified view name to for standard views (eg View='sequence/Group/2/general/SLX_Queued_Report.yml)
    my $project   = $q->param('project');                                                                    ## fully qualified view name to for standard views (eg View='sequence/Group/2/general/SLX_Queued_Report.yml)

    my $timestamp = $q->param('Timestamp');
    if ($timestamp) { $self->{timestamp} = $timestamp }

    my $view = alDente::View::load_view( -dbc => $dbc, -view => $file );

    $view->parse_input_options();
    $view->parse_output_options();

    unless ( $view->{view_directory} ) {
        $view->{view_directory} = alDente::Tools::get_directory( -structure => 'DATABASE', -root => $Configs{'views_dir'}, -dbc => $dbc );
    }

    my $form .= $self->View->return_View(
        -view             => $view,
        -project          => $project,
        -brief            => 1,
        -generate_results => 1,
        -source           => $source,
        -dbc              => $dbc,
        -context          => 'project',
        -log              => 1,

    );
    return $form;

}

#################################
sub file_page {
###########################
    #	Display => file_page
    #	This run mode takes in a file name creates a view object form it and returns an html form to be printed
    #
###########################
    my $self = shift;

    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $file = $self->param('File') || $q->param('File');
    my $settings;    ##          = $self->param('File_Settings') || $q->param('Reference_View');
    my $regenerate       = $self->param('Regenerate View') || $q->param('Regenerate View');
    my $delete           = $q->param('Delete_This_View')   || $self->param('Delete_This_View');                      ## saved view file to be deleted
    my $save             = $q->param('Save View For')      || $self->param('Save View For');                         ## indication to save view
    my $generate_results = $q->param('Generate Results')   || $self->param('Generate Results');                      ## whether to generate results (from param("Generate Results")
    my $source           = $q->param('Source Call')        || $self->param('Source Call') || 'alDente::View_App';    ## the Application that calls View.pm
    my $filter_by_dept = defined $q->param('filter_by_department') ? $q->param('filter_by_department') : 1;
    my $view_name      = $q->param('View');                                                                          ## fully qualified view name to for standard views (eg View='sequence/Group/2/general/SLX_Queued_Report.yml)
    my $cache          = $q->param('Cache');                                                                         ## optional cache parameter to save output to cache file
    my $file_links = $q->param('File_Links');    ## file links of the result page. Valid options include 'excel', 'print', 'csv'. A combination of these options can be specified. If this is not specified, the default is print and excel links.

    if ( $view_name && !$file ) {
        ## simplified call using View parameter instead of File ##
        $file = $Configs{views_dir} . "/$view_name";
    }

    my $timestamp = $q->param('Timestamp');
    if ($timestamp) { $self->{timestamp} = $timestamp }

    my $view;
    require YAML;

    if ($delete) {
        unless ( -e $delete ) { $dbc->warning("File: $delete not found (file page)"); return; }

        $view = alDente::View::load_view( -dbc => $dbc, -view => $delete );

        delete_View( -delete => $delete );
        $generate_results = 0;
    }
    else {
        $view = alDente::View::load_view( -dbc => $dbc, -view => $file );
    }

    my $is_file_page = 1;    # when doing file page, set this to 1 - used to find out if this is views first load in parse_input_options

    if ( !$view ) { $dbc->error("View $file not found - aborting "); return; }
    $view->parse_input_options( -is_file_page => $is_file_page );
    $view->parse_output_options();
    unless ( $view->{view_directory} ) {
        $view->{view_directory} = alDente::Tools::get_directory( -structure => 'DATABASE', -root => $Configs{'views_dir'}, -dbc => $dbc );
    }

    if ($save) { $view->write_to_file( -dbc => $dbc ) }    ## resave YAML template

    if ($cache) { $view->{hash_display}{-timestamp} = 'cached' }    ## override automated timestamp ##

    $source ||= 'alDente::View_App';

    my $form .= $self->View->return_View(
        -view             => $view,
        -generate_results => $generate_results,
        -source           => $source,
        -filter_dept      => $filter_by_dept,
        -dbc              => $dbc,
        -log              => !$delete,
        -context          => 'filtered',
        -file_links       => $file_links
    );

    return $form;
}

################
sub log_usage {
################
    my $self         = shift;
    my %args         = filter_input( \@_, -args => 'file,time' );
    my $file         = $args{-file};
    my $load_time    = $args{ -time };
    my $no_line_feed = $args{-no_line_feed};
    my $append       = $args{-append};
    my $context      = $args{-context};
    my $quiet        = $args{-quiet};                               ## suppress logging message

    my $dbc = $self->param('dbc');

    ## log usage of view if called from the interface (but NOT from the cron job) ##
    my $log = $file;
    $log =~ s /\.yml$/\.$context\.log/;

    my $date = date_time();
    my $user = $dbc->get_local('user_id');

    my $string;

    if   ($append) { $string = $append }            ## append to existing line (use in conjunction with initialize)
    else           { $string = "\n$user\t$date" }

    my $options .= '-e';

    if ($load_time)    { $string .= "\t$load_time" }
    if ($no_line_feed) { $string .= '\c' }             ## do not add newline at end ##

    try_system_command("echo $options \"$string\" >> \"$log\"");

    if ( !$quiet ) { $dbc->debug_message("Log usage to $log") }

    return;
}

#######################
sub get_latest_usage {
#######################
    my %args = &filter_input( \@_ );
    my $file = $args{-file};

    my $log = $file;
    $log =~ s /\.yml$/\.log/;

    my $stdout = try_system_command("tail -1 \"$log\"") if $log;

    if ($stdout) {
        my ( $user, $usage_time, $load_time ) = split( "\t", $stdout );
        return $usage_time;
    }
}

#################################
sub frozen_page {
###########################
    #	Display => frozen_page
    #	This run mode takes in a file name creates a view object form it and returns an html form to be printed
    #
###########################
    my $self             = shift;
    my $q                = $self->query;
    my $dbc              = $self->param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $file             = $self->param('File') || $q->param('File');
    my $regenerate       = $self->param('Regenerate View') || $q->param('Regenerate View');
    my $delete           = $q->param('Delete_This_View') || $self->param('Delete_This_View');                       ## saved view file to be deleted
    my $save             = $q->param('Save View For') || $self->param('Save View For');                             ## indication to save view
    my $generate_results = $q->param('Generate Results') || $self->param('Generate Results');                       ## whether to generate results (from param("Generate Results")
    my $source           = $q->param('Source Call') || $self->param('Source Call') || 'alDente::View_App';          ## the Application that calls View.pm

    my $view = alDente::View::load_view( -dbc => $dbc );

    $view->parse_input_options();
    $view->parse_output_options();
    return $view;
}

#################################
sub results_page {
################################
    #	Results => result_page
    #	This run mode takes in a view object (or inherited view object) and returns an html form to be printed
    #		Since the generate_results falg is turned on here, this run mode will generate results and close the tabs for
    #		io options and saved views
################################
    my $self             = shift;
    my %args             = @_;
    my $q                = $self->query;
    my $dbc              = $self->param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $generate_results = $self->param('Generate Results') || 'Generate Results';                                  ## whether to generate results (from param("Generate Results")
    my $object           = $self->param('Object') || $args{-object};                                                ## the object used, the view
    my $source           = $q->param('Source Call') || $self->param('Source Call') || 'alDente::View_App';          ## the Application that calls View.pm
    my $delete           = $q->param('Delete_This_View') || $self->param('Delete_This_View');                       ## saved view file to be deleted
    my $save             = $q->param('Save View For') || $self->param('Save View For');                             ## indication to save view
    my $file             = $self->param('File') || $q->param('File');
    my $regenerate       = $q->param('Regenerate') || $q->param('Mark');
    my $save_plate       = $q->param('Save Plate Set');
    my $quiet            = $q->param('Quiet') || $self->param('Quiet');
    my $filter_by_dept   = defined $q->param('filter_by_department') ? $q->param('filter_by_department') : 1;
    my $graph_type       = $q->param('Graph_Type');
    my $xaxis            = $q->param('xaxis');
    my $merge            = $q->param('merge');
    my $view_redirect    = $q->param('ViewRedirect');

    #    my @selected         = $q->param('Mark');

    if ($view_redirect) {
        my $redirect_file = $q->param($view_redirect);
        if ( -e $redirect_file ) {
            $file = $q->param($view_redirect) || $file;
        }
        else {
            $dbc->message('View redirection failed... file path for view does not exist');
        }
    }

    my $form;

    my $regroup;
    if ( $graph_type && $graph_type !~ /^No / && $xaxis ) {
        ## override grouping for graphs ##
        $regroup = [$xaxis];
        if ($merge) { push @$regroup, $merge }
    }

    if ($file) {
        my $view = alDente::View::load_view( -view => $file, -dbc => $dbc );
        $view->parse_input_options();
        $view->parse_output_options();

        my $form .= $self->View->return_View(
            -view             => $view,
            -generate_results => $generate_results,
            -source           => $source,
            -filter_dept      => $filter_by_dept,
            -dbc              => $dbc,
            -regroup          => $regroup,
            -log              => 1,
            -context          => 'file',
        );

        return $form;
    }

    if ($delete) { delete_View( -delete => $delete ) }

    unless ($object) {
        $object = $self->frozen_page();
    }

    if ($save) { $object->write_to_file( -dbc => $dbc ) }

    if ($regenerate) {
        my $key_field  = $object->{hash_display}->{-selectable_field};
        my @key_values = $q->param('Mark');
        my $key_values = Cast_List( -list => \@key_values, -to => 'String', -autoquote => 1 );
        for my $alias ( values %{ $object->{config}{'output_params'} } ) {
            if ( $alias =~ /(.+) AS $key_field$/i ) {
                $key_field = $1;
            }
        }

        my @conditions;
        if ( $object->{config}->{'query_condition'} ) { push @conditions, $object->{config}->{query_condition} }
        if ( $object->{config}->{join_conditions} )   { push @conditions, @{ $object->{config}->{join_conditions} } }
        if ( $object->{config}{visible_conditions} )  { push @conditions, @{ $object->{config}{visible_conditions} } }
        push @conditions, "$key_field IN ($key_values)";
        $object->{config}->{'query_condition'} = join ' AND ', @conditions;
    }
    elsif ($save_plate) {
        my @plates           = $q->param('FK_Plate__ID');
        my $force            = $q->param('Force Plate Set');
        my $default_protocol = $q->param('Lab_Protocol');
        my $plates           = Cast_List( -list => \@plates, -to => 'String' ) || $current_plates;
        unless ($plates) { $dbc->error("No plates specified") }
        my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $plates );
        $Set->save_Set( -force => $force );
        return $Set->Set_home_info( -brief => $scanner_mode, -default_protocol => $default_protocol );
    }

    $form .= $self->View->return_View(
        -view             => $object,
        -generate_results => 'Generate Results',
        -source           => $source,
        -quiet            => $quiet,
        -filter_dept      => $filter_by_dept,
        -regroup          => $regroup,
        -dbc              => $dbc,
        -log              => 1,
        -context          => 'filtered',
    );

    return $form;
}

###############
sub save_View {
###############
    my $self             = shift;   
    my %args             = @_;
    my $object           = $self->param('Object') || $args{-object};                                                ## the object used, the view
    my $q                = $self->query;
    
    my $source           = $q->param('Source Call') || $self->param('Source Call') || 'alDente::View_App';          ## the Application that calls View.pm
    
    my $q = $self->query();
    my $dbc = $self->dbc();
    my $rm  = $q->param('rm');

    my $context;
    if ( $rm =~ /Save (\w+) View/ ) { $context = $1 }

    my $view_name = $q->param("${context}_View_Name");

    my ( $emp_id, $group_id );
    if ( $context =~ /(Public|Internal|Group)/ ) {
        $group_id = $q->param("Saved_${context}_ID");
    }
    else {
        $emp_id = $q->param("Saved_${context}_ID");
    }

    unless ($object) {
        $object = $self->frozen_page();
    }

    $object->write_to_file( -dbc => $dbc, -context => $context, -view_name => $view_name, -user_id => $emp_id, -group_id => $group_id );
    
    my $form = $self->View->return_View( 
        -view => $object,
        -source => $source,
    );

    $dbc->message( "Saved View", -type => 'success' );
    return $form;
}

sub delete_View {
###########################
##	Decription:
    # 		- This function deletes a view
    #	Input:
    #		- file : name of the file to be deleted
    #	output:
    #		- Message will be outputed to screen allowing the user to know wether the delete was successful or not
    # <snip>
    # Usage Example:
    #  	delete_View (-delete => $delete) ;
    # </snip>
###########################
    my %args     = filter_input( \@_ );
    my $delete   = $args{ -delete };                ## saved view file to be deleted
    my $command  = "rm -f '$delete'";
    my $feedback = &try_system_command($command);
    if ($feedback) {
        Message($feedback);
    }
    else {
        Message("$delete deleted");
        return 1;
    }
    return;
}

################################
sub generate_form_results {
################################
    my $self = shift;

    my $q    = $self->query;
    my $dbc  = $self->dbc();

    eval "require alDente::View_Generator";

    my $referenced_view = $q->param('Custom_View') || $q->param('Referenced_View');

    my $generator_object = alDente::View_Generator->new( -dbc => $dbc, -view_app => 'view_app', -referenced_view => $referenced_view );
    $generator_object->home_page( -view_app => 'view_app', -referenced_view => $referenced_view );

    my $form = $self->View->return_View(
        -view             => $generator_object,
        -generate_results => 'Generate Results',
        -source           => 'alDente::View_App',
        -dbc              => $dbc,
        -context          => 'generate',
        -log              => 1,
    );
    return $form;
}
################################

1;
