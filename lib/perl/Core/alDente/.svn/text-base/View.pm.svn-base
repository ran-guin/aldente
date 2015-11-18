###################################################################################################################################
# alDente::View.pm
#
# This is the class responsible for creating the Run (e.g., genechip run, bioanalyzer run, etc.) summary page.
# Run specific configuration should be implemented in sub-classes (e.g., Lib_Construction::Genechip_Summary.pm)
# This class implements 1) the general logic, and 2) the page layout.
# 1) Logic:
#    Once a HTTP request is received to view a run, alDente::View::request_broker is called upon to create the approperiate type
#    of object with its default input/output options (e.g., a Lib_Construction::Genechip_Summary object).
#    This object will be carried over all subsequence actions performed on the page.
#    Depending on actions, the configurations of the object may change.
#    Once an object is created, it will perform the following tasks:
#    1) Display the input/output/view options
#    2) Parse the parameters for input/output/view options selected by the user
#    3) Use API calls/SQL queries to retrieve the results
#    4) Display the results
#    5) Respond to actions performed on selected results
# 2) Page layout:
#    The view page has three major areas:
#    1) Input/output/view options
#       Input options: searching conditions
#       Output options: columns to include in the result table
#       View options: saved views to be selected by the user
#    2) Results
#       Table containing the result set
#    3) Actions
#       Available actions to be performed on the selected results
#
# This module contains the following functions/methods:
#
# Functions:
# request_broker:               creating run object depending on the HTTP request.
#
# Public Methods:
# new:                          constructor.
# home_page:                    display the homepage; respond to view specific html parameters
# set_input_options:            set the input options.
# set_output_options:           set the output options.
# set_general_options:          set the general options
# parse_input_options:          parse the user specified input options
# parse_output_options:         parse the user specified output options
# get_input_options:            return the input options (in html format if specified)
# get_output_options:           return the output options (in html format if specified)
# get_available_employee_views: get the available employee saved views
# get_available_group_views:    get the available group saved views
# get_view_table:               get HTML table of saved views
# display_io_options:           display input/output options
# display_available_views:      display saved views
# display_options:              display input/output/ options and saved views
# prepare_API_arguments:        prepare the arguments for API calls from input options and user specified values
# prepare_query_arguments:      prepare the arguments to pass to Table_retrieve
# load_API:                     load the correct API call
# get_search_results:           collect the results from API calls/SQL queries
# 		display_search_results:       display the results from API calls/SQL queries
# write_to_file:                write the view to a file (as a saved view)
# get_actions:                  define possible actions to the result set
# 		display_actions:              display the action table
# 		do_actions:                   define the reactions for each action. this function should print html if the actions require so
#
# Example of usage:
#
#
#
###################################################################################################################################

package alDente::View;

## alDente modules

use strict;

use Data::Dumper;
use File::Find;

use LampLite::CGI;

my $q = new LampLite::CGI;

## SDB modules
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::HTML;

## RG Tools
use RGTools::HTML_Table;
use RGTools::RGIO;
use RGTools::RGmath;
use RGTools::Views;
use RGTools::Conversion;

use alDente::alDente_API;

use File::Basename;
use vars qw($Current_Department $Connection );    # view_directory = $Configs{'Home_public'}/views

#####################							Should be eliminated
sub request_broker {
#####################
    my $self             = shift;
    my %args             = filter_input( \@_ );
    my $dbc              = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    ## database connection
    my $generate_results = $args{-view} || $q->param('Generate Results');                                        ## whether to generate results (from $q->param("Generate Results")
    my $file             = $args{-file} || $q->param('File');                                                    ## the saved view file
    my $frozen           = $args{-frozen} || $q->param('Frozen_Config');                                         ## the frozen copy
    my $save             = $args{-save} || $q->param('Save View For');                                           ## indication to save view
    my $delete           = $args{ -delete } || $q->param('Delete_This_View');                                    ## saved view file to be deleted
    my $regenerate       = $args{-regenerate} || $q->param('Regenerate View');
    my $title            = $args{-title};
    my $filter_by_dept   = $args{-filter_by_dept};

    Message("Warning: You are using the old version of View.  Please update your View.pm and copy View_App.pm");
    my $view;

    if ($delete) {
        my $command  = "rm -f '$delete'";
        my $feedback = &try_system_command($command);
        if ($feedback) {
            Message($feedback);
        }
        else {
            Message("$delete deleted");
            return 1;
        }
    }

    # construct the approperiate object
    if ($file) {
        my $thawed = load_view( -dbc => $dbc, -view => $file );

        if ( !$thawed ) {return}
        my $class = ref $thawed;    # find the class of the object
        eval "require $class";

        Message($@) if $@;
        $view = $class->new( -thawed => $thawed, -dbc => $dbc );
    }
    elsif ($frozen) {

        # construct object from a frozen copy
        my $thawed = Safe_Thaw( -name => 'Frozen_Config', -thaw => 1, -encoded => 1 );
        my $class = ref $thawed;    # find the class of the object

        eval "require $class";
        Message($@) if $@;
        $view = $class->new( -thawed => $thawed, -dbc => $dbc );

    }
    elsif ( $title =~ /Genechip.+Summary/i ) {

        # construct object from default
        my $class = "Lib_Construction::Genechip_Summary";

        #my $class = "alDente::Query_Summary";
        eval "require $class";
        Message($@) if $@;
        $view = $class->new( -title => $title );

    }
    elsif ( $title =~ /Mapping.+Summary/i ) {

        # Mapping shows 24 hours results by default
        my $class = "Mapping::Mapping_Summary";
        eval "require $class";
        Message($@) if $@;
        $view = $class->new( -title => $title );
        $view->home_page( -generate_results => $generate_results, -filter_by_dept => $filter_by_dept );
        return;

    }
    elsif ( $title =~ /Bioanalyzer.+Summary/i ) {
        my $class = "Lib_Construction::Bioanalyzer_Summary";
        eval "require $class";
        Message($@) if $@;
        $view = $class->new( -title => $title );

    }
    elsif ( $title =~ /Solexa.+Summary/i ) {
        my $class = "Illumina::SolexaRun_Summary";
        eval "require $class";

        Message($@) if $@;
        $view = $class->new( -title => $title );
        my %highlight;
        $highlight{run_validation}{Pending}{colour}  = '#FFFF66';
        $highlight{run_validation}{Approved}{colour} = 'lightgreen';
        $highlight{run_validation}{Rejected}{colour} = '#FF0033';
        $view->{hash_display}{-highlight_column}     = \%highlight;

    }
    elsif ( $title =~ /Template/i ) {
        my $class = "Submission::Template_Summary";
        eval "require $class";
        Message($@) if $@;
        $view = $class->new( -title => $title );

    }
    elsif ( $title =~ /(\w+)\s+Statistics/i ) {

        #my $class = "Lib_Construction::Genechip_Statistics";
        my $dept = $1;
        my $class;
        if ( $1 =~ /genechip/i ) {
            $class = "Microarray::Genechip_Statistics";
        }
        elsif ( $1 =~ /mapping/i ) {
            $class = "Mapping::Mapping_Statistics";
        }
        eval "require $class";
        Message($@) if $@;
        $view = $class->new( -title => $title );

    }
    else {

        # construct a super class if not specified
        #require alDente::Query_Summary;
        $view = alDente::View->new( -title => $title, -dbc => $dbc );
    }

    if ($regenerate) {
        my $key_field       = $view->{hash_display}->{-selectable_field};
        my @key_values      = $q->param('Mark');
        my $key_values      = Cast_List( -list => \@key_values, -to => 'String', -autoquote => 1 );
        my $qualified_field = $view->{config}{'output_params'}{$key_field};
        if ($qualified_field) {
            $qualified_field =~ s/(.*) AS (.*)/$1/ig;
            $key_field = $qualified_field;
        }
        if ( $view->{config}->{'query_condition'} ) { $view->{config}->{'query_condition'} .= ' AND ' }
        $view->{config}->{'query_condition'} .= "$key_field IN ($key_values)";

    }

    ### parse HTML parameters for input/output options
    $view->parse_input_options();
    $view->parse_output_options();

    ### save a view if necessary
    if ($save) {
        $view->write_to_file();
    }

    # create the homepage
    $view->home_page( -generate_results => $generate_results, -filter_by_dept => $filter_by_dept );
    return;
}

###########
sub new {
###########
    # ============================================================================
    # Method     : new()
    # Usage      : my $view = alDente::View->new(-file=>$file, -thawed=>$thawed, -title=>$title, -dbc=>$dbc)
    # Purpose    : Create a new View object
    # Returns    : View object
    # Parameters : -title     : title of the page
    #              -dbc: DBIO object
    #              -thawed    : if specified, construct an object from a thawed copy
    # Comments   : none
    # See Also   : n/a
    # ============================================================================
    my $this = shift;
    my %args = filter_input( \@_);

    my $view   = $args{-view};      ## name of view file to load
    my $title  = $args{-title};     ## view title
    my $thawed = $args{-thawed};    ## thawed frozen copy (alternative to passing view name)
    my $dbc    = $args{-dbc};       ## db connection
    my $scope  = $args{-scope};     ## API scope

    my $class = ref($this) || $this;

    my $self = {};

    if ($view) {
        $thawed = load_view( -dbc => $dbc, -view => $view );
    }

    my $views_dir = $dbc->config('views_data_dir');
    if ($thawed) {
        $self = $thawed;            # construct object from thawed copy

        $self->{dbc}        = $dbc;
        $self->{API_loaded} = 0;

        #        if ( !$self->{view_directory} ) {
        ## this seems to somehow get set incorrectly sometimes, so leaving reload until it is clarified...
        $self->{view_directory} = alDente::Tools::get_directory( -structure => 'DATABASE', -root => $views_dir, -dbc => $dbc );

        #        }

        bless $self, $class;
    }
    else {
        ## Initialization of Attributes

        $self->{dbc} = $dbc;
        $self->{view_directory} = alDente::Tools::get_directory( -structure => 'DATABASE', -root => $views_dir, -dbc => $dbc );

        $self->{config}{title}     = $title;    # to be set by sub-class
        $self->{config}{key_field} = '';        # to be set by sub-class

        $self->{config}{API_scope}      = $scope || '';    # to be set by sub-class
        $self->{config}{view_tables}    = '';
        $self->{config}{key_field}      = '';
        $self->{config}{input_options}  = {};
        $self->{config}{output_options} = {};
        $self->{config}{record_limit}   = 100;
        $self->{config}{group_by}       = '';              # to be set by sub-class
        $self->{config}{highlight}      = {};

        bless $self, $class;

        $self->set_input_options();
        $self->set_output_options();
        $self->set_general_options();
    }

    return $self;

}

#
# Alternative constructor that enables loading of thawed objects that may be classes of View objects
#
# Return: object class (either View or a class of View)
################
sub load_view {
################
    my %args   = filter_input( \@_ );
    my $file   = $args{-view};
    my $frozen = $args{-frozen};
    my $dbc    = $args{-dbc};

    my $view;

    my $thawed;

    ##  Creating and initializing object
    if ($file) {
        require YAML;
        if ( !-e $file ) { $dbc->warning("File: $file not found (file page)"); return; }
        $thawed = YAML::LoadFile("$file");
    }
    else {

        # construct object from a frozen copy
        $thawed = Safe_Thaw( -name => 'Frozen_Config', -thaw => 1, -encoded => 1 );
    }

    my $class = ref $thawed;    # find the class of the object
    eval "require $class";

    Message($@) if $@;

    $view = $class->new( -thawed => $thawed, -dbc => $dbc );
    if ($file) {
        $view->{view} = $file;
    }

    $view->merge_views();

    return $view;
}

#
# Merges config settings from baseline view with meta view if applicable
#
#
###################
sub merge_views {
###################
    my $self = shift;

    if ( $self->{referenced_view} ) {
        require YAML;
        my $settings = YAML::LoadFile( $self->{referenced_view} );

        if ($settings) {
            my @override_options = keys %{ $settings->{config} };
            foreach my $option (@override_options) {
                if ( !$self->{config}{$option} ) {
                    $self->{config}{$option} = $settings->{config}{$option};
                }
            }
        }
    }

    return $self;
}

###############									Should be eliminated
sub home_page {
###############
    # ============================================================================
    # Method     : home_page()
    # Usage      : $self->home_page(-generate_results=>1)
    # Purpose    : Display the page with/without results depending on the parameters.
    #              Retrieve and display options
    #              -retrieve input/output options
    #              -display input/output options
    #              Retrieve and display search results
    #              -retrieve search results
    #              -display search results
    # Returns    : html
    # Parameters : -generate_results: 1/0
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================
    my $self             = shift;
    my %args             = filter_input( \@_ );
    my $generate_results = $args{-generate_results};      ## indicate if to generate results
    my $filter_by_dept   = $args{-filter_by_dept};
    my $dbc              = $self->{dbc} || $args{-dbc};

    if ($filter_by_dept) { $self->{filter_by_dept} = 1 }    ## turn on filter flag

    ### retrieve input/output options in html format
    my $input       = $self->get_input_options( -return_html  => 1 );
    my $output      = $self->get_output_options( -return_html => 1 );
    my $saved_views = $self->get_view_table( -context         => 'All' );

    ### allow specific actions:
    $self->do_actions() if ( $self->{config} );

    ### create html form

    my $html_form .= alDente::Form::start_alDente_form( $dbc, "View", $dbc->homelink() );
    $html_form .= Views::sub_Heading( $self->{config}{title} );

    ### add the input/output options and available views
    $html_form .= $self->display_options( -input => $input, -output => $output, -views => $saved_views, -generate_results => $generate_results );

    ### IF generate_results flag is set
    if ($generate_results) {
        ### Generate the results
        my $result = $self->get_search_results();
        $html_form .= '<hr />';
        ### display results
        $html_form .= $self->display_search_results( -search_results => $result );
        $html_form .= '<hr />';
        ### display summary
        $html_form .= $self->display_summary();

        ### get action table if necessary
        my %actions = $self->get_actions();
        $html_form .= '<hr />';
        ### display action table
        $html_form .= $self->display_actions( -actions => \%actions );

    }
    ### freeze self at the end and pass as frozen
    my $self_copy = $self;
    $html_form .= RGTools::RGIO::Safe_Freeze( -name => "Frozen_Config", -value => $self_copy, -format => 'hidden', -encode => 1, -exclude => [ 'API', 'dbc', 'connection', 'transaction' ] );
    $html_form .= end_form();

    ### print the html form
    print $html_form;

}

#######################
sub set_input_options {
#######################
    # ============================================================================
    # Method     : set_input_options()
    # Usage      : $self->set_input_options(-title=>$title)
    # Purpose    : Set input options ($self->{config}{input_options}) for the object
    #              To be implemented in sub-class
    # Returns    : none
    # Parameters : -title: title of the form.
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================
    my $self = shift;
    my %args = @_;

    if ( exists $args{input_options} ) {
        $self->{config}{input_options} = $args{input_options};
    }

    if ( exists $args{input_order} ) {
        $self->{config}{input_order} = $args{input_order};
    }

    return;
}

# Return: 1 on success
##########################
sub set_output_options {
##########################
    # ============================================================================
    # Method     : set_output_options()
    # Usage      : $self->set_output_options(-title=>$title)
    # Purpose    : Set input options ($self->{config}{output_options}) for the object
    #              To be implemented in sub-class
    # Returns    : none
    # Parameters : -title: title of the form.
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================
    my $self = shift;
    my %args = @_;

    if ( exists $args{output_options} ) {
        $self->{config}{output_options} = $args{output_options};
    }

    if ( exists $args{output_order} ) {
        $self->{config}{output_order} = $args{output_order};
    }

    if ( exists $args{output_function} ) {
        $self->{config}{output_function} = $args{output_function};
    }

    if ( exists $args{output_link} ) {
        $self->{config}{output_link} = $args{output_link};
    }

    if ( exists $args{output_value} ) {
        $self->{config}{output_value} = $args{output_value};
    }

    if ( exists $args{display_options} ) {
        $self->{config}{display_options} = $args{-display_options};
    }

    return;

}

##########################
sub set_general_options {
##########################
    # ============================================================================
    # Usage      : $self->set_general_options(-title=>$title)
    # Purpose    : Set general options ($self->{config} except input and output options) for the object
    #              To be implemented in sub-class
    # Returns    : none
    # Parameters : -title: title of the form.
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================
    my $self = shift;
    my %args = @_;

    $self->{config}{API_scope}   = $args{API_scope};     ## API scope
    $self->{config}{key_field}   = $args{key_field};     ## key_field
    $self->{config}{view_tables} = $args{view_tables};

    return;
}

##########################
sub parse_input_options {
##########################
    # ============================================================================
    # Method     : parse_input_options()
    # Usage      : $self->parse_input_options();
    # Purpose    : parse input options specified by the user and corresponding values
    # Returns    : none
    # Parameters : none
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================

    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $is_file_page = $args{-is_file_page} || 0;                                                                       ## determines if first load
    my $result_limit = $q->param('Result_Limit');
    my $dbc          = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    ##### <CONSTRUCTION> Deprecated code?  (possible attribute parameters)
    #my @attr_names    = $q->param('attr_name');
    #my @attr_values   = $q->param('attr_value');
    #my $attr_operator = $q->param('attr_operator');

    #if ( scalar @attr_names > 0 && scalar @attr_names == scalar @attr_values && $attr_operator ) {

    # has valid attribute input
    #$self->{config}{input_attribute}{attribute_names}    = \@attr_names;
    #$self->{config}{input_attribute}{attribute_values}   = \@attr_values;
    #$self->{config}{input_attribute}{attribute_operator} = $attr_operator;
    #}
    #####

    # attributes

    if ( $self->{config}{input_attributes} && ref $self->{config}{input_attributes} eq 'HASH' ) {
        foreach my $name ( keys %{ $self->{config}{input_attributes} } ) {

            #my $value = $q->param($name);
            #$self->{config}{input_attributes}{$name}{value} = $value;
            $name =~ /(\w+)\.(\w+)/i;
            my $table     = $1;
            my $attribute = $2;
            my %attr_info = $self->{dbc}->Table_retrieve( 'Attribute', ['Attribute_Type'], "where Attribute_Name = '$attribute'" );
            my $attr_type;

            if ( $attr_info{Attribute_Type} ) {
                $attr_type = $attr_info{Attribute_Type}[0];
            }

            my $value = &SDB::HTML::get_Table_Param( -table => $table, -field => "$attribute", -list => 1, -dbc => $dbc );
            my @value = Cast_List( -list => $value, -to => 'Array' );

            $self->{config}{input_attributes}{$name}{type}  = $attr_type;
            $self->{config}{input_attributes}{$name}{value} = \@value;
        }
    }

    $self->{config}{record_limit} = $result_limit if $result_limit;

    my %input_list;
    %input_list = %{ $self->{config}{input_options} } if $self->{config}{input_options};

    my @input_elements = sort { $a cmp $b } keys %input_list;

    foreach my $input_field (@input_elements) {
        my $table;
        my $field;
        if ( $input_field =~ /(\w+)\.(\w+)/i ) {
            $table = $1;
            $field = $2;
        }
        my $real_table_name = $self->{config}{table_list}{$table} || $table;

        my %field_info = $self->{dbc}->Table_retrieve( 'DBField,DBTable', [ 'Field_Type', 'Prompt', 'Field_Description' ], "WHERE FK_DBTable__ID = DBTable_ID and Field_Table = '$real_table_name' and Field_Name = '$field'" );
        my ( $field_type, $prompt, $description );

        if ( $field_info{Field_Type} ) {
            $field_type  = $field_info{Field_Type}[0];
            $prompt      = $field_info{Prompt}[0];
            $description = $field_info{Field_Description}[0];
        }

        $self->{config}{input_options}{$input_field}{type}        = $field_type;
        $self->{config}{input_options}{$input_field}{prompt}      = $prompt;
        $self->{config}{input_options}{$input_field}{description} = $description;

        if ( $field_type =~ /date/i ) {
            my $def_from = '';
            my $def_to   = '';

            if ($is_file_page) {    # use yaml values if first load, if not its blank
                ( $def_from, $def_to ) = split( '<=>', $self->{config}{input_options}{$input_field}{value} );
            }

            my $from_date = &SDB::HTML::get_Table_Param( -table => $table, -field => $field, -field_type => "DateFrom", -dbc => $dbc ) || $def_from;
            my $to_date   = &SDB::HTML::get_Table_Param( -table => $table, -field => $field, -field_type => "DateTo",   -dbc => $dbc ) || $def_to;

            if ($from_date) {
                if ( $from_date =~ /^\w+$/ ) {
                    $from_date = &RGTools::Conversion::translate_date( -date => $from_date );
                }
                elsif ( $from_date =~ /^\d+-\d+-\d+$/ ) {
                    $from_date .= " 00:00";    # fix for date without exact time
                }
            }
            if ($to_date) {
                if ( $to_date =~ /^\w+$/ ) {
                    $to_date = &RGTools::Conversion::translate_date( -date => $to_date );
                }
                elsif ( $to_date =~ /^\d+-\d+-\d+$/ ) {
                    $to_date .= " 23:59:59";    # fix for date without exact time
                }
            }

            if ( $from_date && $to_date ) {
                $self->{config}{input_options}{$input_field}{value} = $from_date . "<=>" . $to_date;
            }
            elsif ($from_date) {
                $self->{config}{input_options}{$input_field}{value} = " >= $from_date";
            }
            elsif ($to_date) {
                $self->{config}{input_options}{$input_field}{value} = " <= $to_date";
            }
            else {
                $self->{config}{input_options}{$input_field}{value} = "";
            }
        }
        elsif ( $table && $field ) {
            my $value = &SDB::HTML::get_Table_Param( -table => $table, -field => "$field", -list => 1, -dbc => $dbc );
            my @value = Cast_List( -list => $value, -to => 'Array' );
            $self->{config}{input_options}{$input_field}{value} = \@value;
        }

    }

    return;

}

##########################
sub parse_output_options {
##########################
    # ============================================================================
    # Method     : parse_output_options()
    # Usage      : $self->parse_output_options();
    # Purpose    : parse output options picked by the user and set picked to 1
    # Returns    : none
    # Parameters : none
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================
##########################

    my $self = shift;

    my @picked_fields = $q->param('Picked_Options');
    my @group_by      = $q->param('View_Group_By');
    my $layer_by      = $q->param('Layer_By');
    my $rm            = $q->param('rm');

    my @field_order = @picked_fields;

    my @fields;
    foreach my $field ( @{ $self->{config}{output_order} } ) {
        my $key = $field;
        if ( my $alias = $self->{config}{output_labels}{$key} ) {
            $key = $alias;
        }
        push @fields, $key;
    }

    if ( $rm ne 'Display' ) {
        ##  (user interface form to parse) ##

        my %picked_list;
        my $i = 1;

        foreach my $picked (@picked_fields) {
            $picked_list{$picked} = $i++;
        }

        my %output_list;
        %output_list = %{ $self->{config}{output_options} } if $self->{config}{output_options};

        if ( scalar @picked_fields > 0 ) {
            foreach my $output_field ( keys %output_list ) {
                if ( $picked_list{$output_field} ) {
                    $self->{config}{output_options}{$output_field}{picked} = 1;
                }
                else {
                    $self->{config}{output_options}{$output_field}{picked} = 0;
                }
            }
        }

        my @grouping;
        if ( scalar @group_by > 0 && $self->{config}{group_by} && ref $self->{config}{group_by} eq 'HASH' ) {
            foreach my $item ( keys %{ $self->{config}{group_by} } ) {
                if ( grep { $_ eq $item } @group_by ) {
                    $self->{config}{group_by}{$item}{picked} = 1;
                    push @grouping, $item;
                }
                elsif ( $rm eq 'Display' ) {
                    ## default to yml defined group settings if coming from Link directly ##
                    $self->{config}{group_by}{$item}{picked} = 1;
                }
                else {
                    $self->{config}{group_by}{$item}{picked} = 0;
                }
            }
        }
        elsif ( $self->{hash_display}{-fields} && ref $self->{hash_display}{-fields} eq 'HASH' ) {
            my %sql_aliases = reverse %{ $self->{hash_display}{-fields} };

            foreach my $item ( @{ $self->{config}{query_group} } ) {
                my $label = $sql_aliases{$item} || $item;
                $self->{config}{group_by}{$label}{picked} = 1;
            }
        }

        if ($layer_by) { $self->{hash_display}{-layer} = $layer_by }
        $self->{hash_display}{-group} = \@grouping;
    }
    else {
        ## load settings directly from file config settings (no user interface to parse) ##
        if ( defined $self->{config}{query_group} ) {
            foreach my $group ( @{ $self->{config}{query_group} } ) {
                $self->{config}{group_by}{$group}{picked} = 1;
            }
        }

        $self->{hash_display}{ -keys } = \@fields;
        $self->{hash_display}{-group} = $self->{config}{query_group};
    }

    return;

}

########################
sub get_input_options {
########################

    # ============================================================================
    # Method     : get_input_options()
    # Usage      : my $input = $self->get_input_options(-html=>1);
    #              my $input = $self->get_input_options(-html=>0);
    # Purpose    : Get input options ($self->{config}{input_options}) in hash reference or html table
    # Returns    : hash reference or html table
    # Parameters : -return_html: 1/0.
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================
    my $self        = shift;
    my $dbc         = $self->{dbc};
    my %args        = &filter_input( \@_ );
    my $return_html = $args{-return_html};    ## if return html

    my $filter_by_dept = $self->{filter_by_dept};

    my %input_list;
    %input_list = %{ $self->{config}{input_options} } if $self->{config}{input_options};
    my $attribute_tables = $self->{config}{input_attribute}{tables};

    #my $attr_names    = $self->{config}{input_attribute}{attribute_names};
    #my $attr_values   = $self->{config}{input_attribute}{attribute_values};
    #my $attr_operator = $self->{config}{input_attribute}{attribute_operator};

    my $attributes      = $self->{config}{input_attributes};
    my $attribute_order = $self->{config}{input_attribute_order};

    my %attribute_default;

    #if ( $attr_names && ref $attr_names eq 'ARRAY' && $attr_values && ref $attr_values eq 'ARRAY' && scalar @$attr_names == scalar @$attr_values && scalar @$attr_names > 0 ) {
    #    $attribute_default{names}    = $attr_names;
    #    $attribute_default{values}   = $attr_values;
    #    $attribute_default{operator} = $attr_operator;
    #}

    my %preset;    # default values
    my %list;      # customized list

    foreach my $key ( keys %input_list ) {
        $key =~ /(.*)\.(.*)/i;
        my $field = $2;
        if ( defined $input_list{$key}{value} && $field ) {
            my $value;

            if ( $dbc->foreign_key_check( -field => $key ) ) {
                $value = $dbc->get_FK_ID( -field => $field, -value => $input_list{$key}{value}, -validate => 0 );
            }
            else {
                $value = $input_list{$key}{value};
            }

            ##both as key, and field just incase there is alias vs no alias.
            $preset{$key} = $value;
            $list{$key}   = $input_list{$key}{list};

            #$preset{$field} = $value;						## Not necessary, if no problem remove in 3.7
            #$list{$field}   = $input_list{$key}{list};
        }
    }

    # Generate the table which contains the textfields/scrolling lists etc.
    if ($return_html) {

        my @rows;
        my @fields;
        my @order;
        my %aliases;
        my %real_table_names;

        if ( $self->{config}{input_order} && ref( $self->{config}{input_order} ) eq 'ARRAY' ) {
            @order = @{ $self->{config}{input_order} };
        }
        else {
            @order = sort { $a cmp $b } keys %input_list;
        }

        while ( my $field = shift @order ) {

            if ( $field =~ /(.+) AS (.+)/i ) {
                $field = $1;
                $aliases{$field} = $2;
            }

            if ( $field =~ /(\w+)\.(\w+)/i ) {
                my $table           = $1;
                my $real_table_name = $self->{config}{table_list}{$table};
                $real_table_names{$table} = $real_table_name;
            }
            push @fields, $field;
        }

        if ( scalar @fields > 0 ) {
            my $html_form = new SDB::DB_Form( -dbc => $self->{dbc}, -wrap => 0, -fields => \@fields, -aliases => \%aliases, -real_table_names => \%real_table_names );
            $html_form->configure( -preset => \%preset, -list => \%list );

            my $returned = $html_form->generate(
                -preset          => \%preset,
                -return_html     => 1,
                -action          => 'search',
                -title           => "Select Filtering Criteria",
                -navigator_on    => 0,
                -attributes      => $attributes,
                -attribute_order => $attribute_order,
                -form_name       => 'View',
                -submit          => 0,
                -filter_by_dept  => $filter_by_dept
            );
            my $all_inputs;

            #if ( $self->{config}{input_attributes} ) {
            #my $attribute_table = $self->get_input_attribute_options();
            #$all_inputs = $returned . "<br/>" . $attribute_table;
            #}
            #else {
            $all_inputs = $returned;

            #}
            return $all_inputs;
        }
        else {
            my $empty_table = HTML_Table->new( -title => 'Input Options', -colour => 'lightgrey' );
            $empty_table->Set_Row( ["N.A."] );
            my $all_inputs;
            if ( $self->{config}{input_attributes} ) {
                my $attribute_table = $self->get_input_attribute_options();
                $all_inputs = $empty_table->Printout(0) . "<br/>" . $attribute_table;
            }
            else {
                $all_inputs = $empty_table->Printout(0);
            }
            return $all_inputs;
        }

    }
    else {
        return \%input_list;
    }

}

## Functionality moved to get_input_options (DB_Form)
######################################
sub get_input_attribute_options {
######################################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = &filter_input( \@_ );

    my $html       = HTML_Table->new( -title => 'Input Attribute Options', -colour => 'lightgrey' );
    my $attributes = $self->{config}{input_attributes};
    my $order      = $self->{config}{input_attribute_order};

    if ( $attributes && ref $attributes eq 'HASH' ) {
        foreach my $attribute (@$order) {
            my $attribute_name;
            my $table_name;
            if ( $attribute =~ /(\w+)\.(\w+)/ ) {
                $table_name     = $1;
                $attribute_name = $2;
            }

            my $list  = $attributes->{$attribute}{list};
            my $value = $attributes->{$attribute}{value};
            my $alias = $attributes->{$attribute}{alias};

            my @ids = $dbc->Table_find( "Attribute", "Attribute_ID", "where Attribute_Name = '$attribute_name'", -distinct => 1 );
            my ( $prompt, $query ) = alDente::Attribute_Views::prompt_for_attribute( -dbc => $dbc, -attribute_id => $ids[0], -action => 'search', -name => $attribute_name );
            $html->Set_Row( [ $alias, $query ] );
        }
    }

    return $html->Printout(0);
}

##########################
sub get_output_options {
##########################
    # ============================================================================
    # Method     : get_output_options()
    # Usage      : my $output = $self->get_output_options(-html=>1);
    #              my $output = $self->get_output_options(-html=>0);
    # Purpose    : Get output options ($self->{config}{output_options}) in hash reference or html table
    # Returns    : hash reference or html table
    # Parameters : -return_html: 1/0.
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================
    my $self        = shift;
    my $dbc         = $self->{dbc};
    my %args        = filter_input( \@_ );
    my $return_html = $args{-return_html};

    ## if return html
    my %output_list  = %{ $self->{config}{output_options} } if $self->{config}{output_options};
    my %output_label = %{ $self->{config}{output_labels} }  if $self->{config}{output_labels};
    my %group_list   = %{ $self->{config}{group_by} }       if $self->{config}{group_by};
    my @group_order  = @{ $self->{config}{query_group} }    if $self->{config}{query_group};

    my %hash_display = %{ $self->{hash_display} } if $self->{hash_display};

    if ( !@group_order ) { @group_order = keys %group_list }

    if ($return_html) {

        my @output_field_order;
        if ( $self->{config}{output_order} && ref( $self->{config}{output_order} ) eq 'ARRAY' ) {
            @output_field_order = @{ $self->{config}{output_order} };
        }
        else {
            @output_field_order = sort { $a cmp $b } keys %output_list;
        }

        my @default_picked_fields;
        foreach my $output_option (@output_field_order) {
            if ( $output_list{$output_option}{picked} ) {
                push( @default_picked_fields, $output_option );
            }
        }

        if ( ( scalar keys %output_label ) == 0 ) {

            foreach my $field_name (@output_field_order) {

                my %field_info  = $dbc->Table_retrieve( 'DBField,DBTable', [ 'Field_Type', 'Prompt', 'Field_Description' ], "WHERE FK_DBTable__ID = DBTable_ID AND Field_Name = '$field_name'" );
                my $field_type  = $field_info{Field_Type}[0];
                my $prompt      = $field_info{Prompt}[0];
                my $description = $field_info{Field_Description}[0];
                $output_label{$field_name} = $prompt;
            }
        }

        my $output_table = HTML_Table->new( -class => 'small' );

        my $option_selector = SDB::HTML::option_selector(
            -form          => $self->{form},
            -avail_list    => \@output_field_order,
            -avail_labels  => \%output_label,
            -picked_list   => \@default_picked_fields,
            -picked_labels => \%output_label,
            -title         => "Select output columns to display",
            -avail_header  => 'Available Fields',
            -picked_header => 'Picked Fields',
            -sort          => 1
        );
        $output_table->Set_Row( [ $option_selector->Printout(0) ] );

        if ( scalar @group_order > 0 ) {
            my ( @set_list, @defaultset, @layer_list, $default_layer );

            foreach my $item (@group_order) {
                push( @set_list, $item );
                if ( $item !~ /\./ ) {
                    ## fully qualified fields do NOT appear as Layer options for now ##
                    push @layer_list, $item;
                }

                my $picked = $group_list{$item}->{picked};

                if ($picked) {
                    push( @defaultset, $item );
                }
            }

            my $group_by_element = alDente::Tools::search_list(
                -dbc          => $dbc,
                -name         => "View_Group_By",
                -element_name => "View_Group_By",
                -options      => \@set_list,
                -default      => \@defaultset,
                -breaks       => 1,
                -id           => "group_by",
                -mode         => 'checkbox',
                -class        => '',     ## define class to override form-control default ... 
            );

            $output_table->Set_sub_header( 'Group Results By', 'lightredbw' );
            $output_table->Set_Row( [$group_by_element] );

            if (@layer_list) {
                my $default_layer = $self->{hash_display}{"-layer"};
                if ( $default_layer && !( grep /$default_layer/, @layer_list ) ) { push @layer_list, $default_layer }

                 ## generate option to layer results ##
                my $layer_by_element = alDente::Tools::search_list(
                    -dbc          => $dbc,
                    -name         => "Layer_By",
                    -element_name => "Layer_By",
                    -options      => [ 'No Layers', @layer_list ],
                    -default      => $default_layer,
                    -breaks       => 1,
                    -id           => "layer_by",
                    -mode         => 'radio',
                    -class        => '',     ## define class to override form-control default ... 
                );

                $output_table->Set_sub_header( 'Generate Separate Tabs by', 'lightredbw' );
                $output_table->Set_Row( [$layer_by_element] );
            }

            #	    if ($self->{hash_display}{'-graph'}) {

            my $graph_options = $self->{config}{graph_options};

            use RGTools::GGraph;
            my $Graph = new GGraph();
            $graph_options = $Graph->options_interface( -fields => \@output_field_order, -graph_options => $graph_options );

            $output_table->Set_sub_header( 'Graphing Options', 'lightredbw' );
            $output_table->Set_Row( [ create_tree( -tree => { 'Graph Options' => $graph_options } ) ] );

            #	    }
        }

        #my $group_options = $self->{config}{group_by};
        #$output_table->Set_Row([ $group_options->Printout(0) ]) if $group_options;

        return $output_table->Printout(0);

    }
    else {
        return \%output_list;
    }
}

######################################
sub validate_mandatory_fields {
######################################

    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = filter_input( \@_ );

    my %input_list       = %{ $self->{config}{input_options} }    if $self->{config}{input_options};
    my @input_order      = @{ $self->{config}{input_order} }      if $self->{config}{input_order};
    my @mandatory_fields = @{ $self->{config}{mandatory_fields} } if $self->{config}{mandatory_fields};

    my $validated = 1;
    my @missing;

    foreach my $m_field (@mandatory_fields) {
        my $or_value = 0;
        my @fields = split /\|/, $m_field;
        @fields = map { s/^\s+//; s/\s+$//; $_; } @fields;
        my @prompts;

        foreach my $field (@fields) {
            if ( $field =~ /(\w+).(\w+)/ ) {
                my ($select) = grep {/$field/} @input_order;
                my $prompt;

                if ( $select =~ /(.+) AS (\w+)/i ) {
                    $prompt = $2;
                }
                else {
                    ($prompt) = $dbc->Table_find( 'DBField', 'Prompt', "WHERE Field_Table = '$1' and Field_Name = '$2'" );
                }

                push @prompts, $prompt;

                my $type  = $input_list{$field}{type};
                my $value = $input_list{$field}{value};

                if ( ( $type =~ /date/ and $value =~ /(.+)<=>(.+)/ ) or ( ref $value eq 'ARRAY' and scalar @$value > 0 ) ) {
                    $or_value = 1;
                }
            }
        }

        if ( !$or_value ) {
            my $reqd = join "' or '", @prompts;
            push @missing, "'$reqd'";
            $validated = 0;
        }
    }

    $dbc->message( "Search filtering input required for:" . Cast_List(-list=>@missing, -to=>'UL') ) unless $validated;

    return $validated;
}

#######################################
sub get_all_user_available_views {
######################################

    my $self = shift;
    my %args = filter_input( \@_ );

    my $scope = $args{-scope} || $self->{config}{API_scope};
    my $type  = $args{-type}  || $self->{config}{API_type};
    my $view_dir = $self->{view_directory};

    my %users;
    if ( $scope && $type ) {
        find sub { $users{$_} = $self->{view_directory} . "/Employee/" . $_ . "/" . $scope . "/" . $type . "/" if ( -d $_ && $_ =~ /^\d+$/ ) }, $self->{view_directory} . "/Employee/";
    }
    else {
        find sub { $users{$_} = $self->{view_directory} . "/Employee/" . $_ . "/general/" if ( -d $_ && $_ =~ /^\d+$/ ) }, $self->{view_directory} . "/Employee/";
    }

    my %user_views;

    foreach my $user ( keys %users ) {
        my $value = $users{$user};
        find sub {
            if ( ( -f $_ ) && ( my $tmp = $_ ) && ( $_ =~ s/.yml$// ) ) { $user_views{$user}{ $value . $tmp } = $_ }
        }, $value;
    }

    return \%user_views;

}

#####################################
sub get_all_group_available_views {
#####################################

    my $self = shift;
    my %args = filter_input( \@_ );

    my $scope = $self->{config}{API_scope};
    my $type  = $self->{config}{API_type};

    my %groups;
    if ( $scope && $type ) {
        find sub { $groups{$_} = $self->{view_directory} . "/Group/" . $_ . "/" . $scope . "/" . $type . "/" if ( -d $_ && $_ =~ /^\d+$/ ) }, $self->{view_directory} . "/Group/";
    }
    else {
        find sub { $groups{$_} = $self->{view_directory} . "/Group/" . $_ . "/general/" if ( -d $_ && $_ =~ /^\d+$/ ) }, $self->{view_directory} . "/Group/";
    }

    my %group_views;

    foreach my $group ( keys %groups ) {
        my $value = $groups{$group};
        find sub {
            if ( ( -f $_ ) && ( my $tmp = $_ ) && ( $_ =~ s/.yml$// ) ) { $group_views{$group}{ $value . $tmp } = $_ }
        }, $value;
    }

    return \%group_views;

}

###########################
sub get_view_table {
###########################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $source  = $args{-source};
    my $context = $args{-context} || 'Internal';
    my $dbc     = $self->{dbc} || $args{-dbc};     # can explicitly pass dbc

    my $views;
    my @group_names;
    my $admin = 0;

    my $found_view = 0;
    my %labels;

    my $form;
    my $save_table = HTML_Table->new( -class => 'small' );
    my $dept = $dbc->config('Target_Department');

    my $access = $dbc->get_local('Access');
    if ( $access && ( grep /LIMS Admin/, keys %$access ) ) { $admin = 1; }

    my $note;
    if ( $context eq 'My' ) {
        $views = $self->get_available_employee_views;

        $note = "These are my personal saved views";
        $save_table->Set_Headers( [ 'User', 'View', 'Cached', 'Options' ] );

        foreach my $emp ( keys %$views ) {
            my ($emp_name) = $dbc->Table_find( 'Employee', "Employee_Name", "WHERE Employee_ID = '$emp'" );
            $labels{$emp} = $emp_name;
        }
    }
    elsif ( $context eq 'Employee' ) {
        ## views for all employees - only available to LIMS staff ##
        if ($admin) {
            $views = $self->get_all_user_available_views;
        }
        else {
            return;
        }

        $note = "Admin Access - Personal views for all staff";
        $save_table->Set_sub_header( $self->{dbc}{LocalAttribute}{user_email}, 'mediumblue' );

        foreach my $emp ( keys %$views ) {
            my ($emp_name) = $dbc->Table_find( 'Employee', "Employee_Name", "WHERE Employee_ID = '$emp'" );
            $labels{$emp} = $emp_name;
        }
    }
    else {
        my ($dept_id) = $dbc->Table_find( "Department", "Department_ID", "WHERE Department_Name = '$dept'" );
        $save_table->Set_Headers( [ 'Group', 'View', 'Cached', 'Options' ] );

        my @local_groups = @{ $self->{dbc}{LocalAttribute}{groups} } if $self->{dbc}{LocalAttribute}{groups};
        @local_groups = grep { $_ ne 'Public' } @local_groups;    ## Deal with public views separately
        my $list = Cast_List( -list => \@local_groups, -to => "String", -autoquote => 1 );

        if ( $context eq 'Public' ) {
            @group_names = ('Public');
            $note        = "<B>Public</B> - These views are potentially available to guest users and should only contain non-sensitive summary data for public distribution.";
        }

        if ( $context eq 'Internal' ) {
            @group_names = ( $dbc->config('custom_version_name') . '_Internal' );
            $note        = "<B>Internal</B> - These views are for internal staff only, but not limited to specific departments or groups.";
        }

        elsif ( $context eq 'Group' ) {
            @group_names = $dbc->Table_find( "Grp", "Grp_Name", "WHERE FK_Department__ID = '$dept_id' AND Grp_Name IN ($list)" ) if $list;
            $note = "<B>Group</B> - These views are visible to only specific groups.";
        }

        elsif ( $context eq 'Other' ) {
            @group_names = $dbc->Table_find( "Grp", "Grp_Name", "WHERE FK_Department__ID <> '$dept_id' AND Grp_Name IN ($list)" ) if $list;
        }

        $views = $self->get_available_group_views( -group_names => \@group_names );
        foreach my $group_name (@group_names) {
            my ($gid) = $dbc->Table_find( 'Grp', "Grp_ID", "WHERE Grp_Name = '$group_name'" );
            $labels{$gid} = $group_name;
        }
    }

    if ( $views && ( ref $views ) =~ /HASH/ ) {
        my %view_hash = %{$views};
        my @sorted_groups = sort { $labels{$a} cmp $labels{$b} } keys %view_hash;

        foreach my $id (@sorted_groups) {
            if ( $views->{$id} && ( ref $views->{$id} ) =~ /HASH/ ) {
                my %file_paths = %{ $views->{$id} };
                my @sorted_paths = sort { $file_paths{$a} cmp $file_paths{$b} } keys %file_paths;

                foreach my $file_path (@sorted_paths) {
                    my $filename = $views->{$id}{$file_path};

                    my $filelink = &Link_To( $dbc->config('homelink'), $filename, "&cgi_application=alDente::View_App&rm=Display&File=$file_path&Generate+Results=1&Source+Call=$source&Cache=1", $Settings{LINK_COLOUR} );

                    my @row = ($filelink);
                    if ( $labels{$id} ) {    ## }$context eq 'Group' or $context eq 'Other' ) {
                        @row = ( $labels{$id}, @row );
                    }

                    my ( $cache_file, $dir ) = File::Basename::fileparse( $file_path, '.yml' );

                    my $cache_path = "$Configs{URL_domain}" . "/dynamic/tmp/$cache_file.cached.html";

                    my $cache_path2 = "/opt/alDente/www/dynamic/tmp/$cache_file.cached.html";
                    if ( -e $cache_path2 ) {
                        $cache_file =~ s/\s/\\ /g;
                        my $command = "grep 'Load Time' /opt/alDente/www/dynamic/tmp/$cache_file.cached.html";
                        my $output  = try_system_command($command);
                        my $tool_word;
                        my $load_time;
                        if ( $output =~ /No such file/ ) {
                            @row = ( @row, " " );
                        }
                        else {
                            if ( $output =~ /\[(.+)\]/ ) {
                                $tool_word = $1;
                            }
                            my $cache_link = RGTools::RGIO::Show_Tool_Tip( &Link_To( $cache_path, "[cached]", '', $Settings{LINK_COLOUR} ), "$tool_word" );
                            @row = ( @row, $cache_link );
                        }
                    }
                    else {
                        @row = ( @row, " " );
                    }
                    if ( $admin || $context eq 'Employee' ) {
                        my $delete_link = &Link_To( $dbc->config('homelink'), "Delete This View", "&cgi_application=alDente::View_App&rm=Display&Delete_This_View=$file_path&Generate+Results=1&Source+Call=$source", $Settings{LINK_COLOUR} );
                        @row = ( @row, $delete_link );
                        my $edit_link = &Link_To( $dbc->config('homelink'), "Edit View", "&cgi_application=alDente::View_App&rm=Display&File=$file_path&Generate+Results=0&Source+Call=$source", $Settings{LINK_COLOUR} );
                        @row = ( @row, $edit_link );
                    }

                    $save_table->Set_Row( \@row );
                    $found_view = 1;
                }
            }
        }
    }

    if ( !$found_view ) {
        $save_table->Set_Row( ['No Saved Views'] );
    }

    ##
    ## Do not change to rm for now since it still shares the rm "Results" with other buttons and the Save View rm is the second rm.
    ## In order to change to rm, we need to generate this button in a self contained form, which means it has its own cgi-application
    ##
    #my @save_row = (
    #    'View Name:',
    #    textfield( -name => "${context}_View_Name", -size => 40, -default => '' ),
    #    submit( -name => "rm", -value => "Save $context View", -class => 'Action', -onClick => " select_all_options('Picked_Options'); return validateForm(this.form);", -force => 1 )
    #);
    my @save_row = (
        "View Name: " . $q->textfield( -name => "View_Name_$context", -size => 40, -default => '' ),
        $q->submit( -name => "Save View For", -value => "Save $context View", -class => 'Action', -onClick => "select_all_options('Picked_Options');return;", -force => 1 )
    );

    my ( $save_group, $ref );
    my @sorted_groups = sort { $labels{$a} cmp $labels{$b} } keys %labels;

    if   ( $context =~ /(Internal|Public|Group)/ ) { $ref = 'Grp' }
    else                                           { $ref = 'Employee' }

    if ( int(@sorted_groups) == 1 ) { $save_group = "For: " . alDente::Tools::alDente_ref( $ref, $sorted_groups[0], -dbc => $dbc ) . $q->hidden( -name => "Saved_${context}_ID", -value => $sorted_groups[0], -force => 1 ) }
    else                            { $save_group = "For: " . $q->popup_menu( -name => "Saved_${context}_ID", -values => [ '', @sorted_groups ], -labels => \%labels, -force => 1 ) }

    push @save_row, $save_group;

    $save_table->Set_Row( \@save_row );

    $form .= subsection_heading($note);
    $form .= $save_table->Printout(0);

    return $form;
}

###################################
sub get_available_employee_views {
###################################
    # responsible for getting all availabel employee views for the view panel
    # return hash ref, keyed by uid and file name (including path), valued by view name
###################################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $uid   = $self->{dbc}{LocalAttribute}{user_id} || $args{-user_id};    # can explicitly pass array ref of user name
    my $scope = $self->{config}{API_scope} || $args{-scope};                 # can explicitly pass API_scope
    my $type  = $self->{config}{API_type};

    my $search_dir;
    if ( $scope && $type ) {
        $search_dir = $self->{view_directory} . "/Employee/" . $uid . "/" . $scope . "/" . $type;
    }
    else {
        $search_dir = $self->{view_directory} . "/Employee/" . $uid . "/general";
    }

    my %members;

    if ( -d $search_dir ) {
        my @files = glob("$search_dir/*.yml");
        foreach my $files (@files) {
            if ( $files =~ /.*\/(.+)\.yml/ ) { $members{$uid}{$files} = $1 }
        }
    }

    return \%members;

}

###############################
sub get_available_group_views {
###############################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $scope = $self->{config}{API_scope} || $args{-scope};                                                      # can explicitly pass API_scope
    my $type  = $self->{config}{API_type};
    my $dbc   = $self->{dbc} || $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # can explicitly pass dbc

    my $group_names_array_ref = $args{-group_names};                                                              # can explicitly pass array ref of group names
    my $group_ids_array_ref   = $args{-group_ids};                                                                # can explicitly pass array ref of group ids
    my $dept                  = $args{-department};
    my $condition             = $args{-condition} || 1;

    if ( $dept eq 'Public' ) { $condition .= " AND Grp_Name = 'Public'" }
    elsif ( $dept eq 'Internal' ) {
        my $internal_group = $dbc->config('custom_version_name') . '_Internal';                                   ## this could be changed to Internal to simplify things or sync up with the saving feature in View_App
        $condition .= " AND Grp_Name = '$internal_group'";
    }
    elsif ($dept) { $condition .= " AND Department_Name = '$dept'" }

    my %members;
    my $is_id = 0;

    my @group_names;
    if ( $group_names_array_ref && ( ref $group_names_array_ref ) =~ /ARRAY/ ) {
        @group_names = @$group_names_array_ref;
    }
    elsif ( $group_ids_array_ref && ( ref $group_ids_array_ref ) =~ /ARRAY/ ) {
        @group_names = @$group_ids_array_ref;
        $is_id       = 1;
    }
    elsif ($dept) {
        @group_names = $dbc->get_db_array(-table=>'Grp, Department', -field=>'Grp_Name', -condition=>"FK_Department__ID=Department_ID AND Department_Name = '$dept'");
    }
    elsif ( $dbc->{LocalAttribute}{groups} && ( ref $dbc->{LocalAttribute}{groups} ) =~ /ARRAY/ ) {
        @group_names = @{ $dbc->{LocalAttribute}{groups} };
    }

    my $title;
    my $group_name_list = Cast_List( -list => \@group_names, -to => 'string', -autoquote => 1 );
    $group_name_list ||= "''";

    if ( $dept !~ /Public|Internal/ ) { $condition .= " AND Grp_Name IN ($group_name_list)" }

    my @group_ids = $dbc->Table_find( 'Grp,Department', "Grp_ID", "WHERE FK_Department__ID=Department_ID AND $condition" );
    foreach my $gid (@group_ids) {
        my $search_dir;
        if ( $scope && $type ) {
            $search_dir = $self->{view_directory} . "/Group/" . $gid . "/" . $scope . "/" . $type;
        }
        else {
            $search_dir = $self->{view_directory} . "/Group/" . $gid . "/general";
        }
        if ( -d $search_dir ) {
#            my @files = split "\n", `ls $search_dir/*.yml`;
#            if ($files[0] =~/no such file/) { @files = () }
            
            my @files = glob("$search_dir/*.yml");
            foreach my $files (@files) {
                if ( $files =~ /.*\/(.+)\.yml/ ) { $members{$gid}{$files} = $1 }
            }
        }
    }

    return \%members;
}

#######################
sub get_saved_views_links {
#######################
    my $self            = shift;
    my %args            = filter_input( \@_ );
    my $saved_view_list = $args{-saved_view_list};

    my $dbc = $self->{dbc};

    my @saved_views = Cast_List( -list => $saved_view_list, -to => 'Array' );
    my $search_dir = $self->{view_directory} . "/Group";
    my @saved_views_links;

    foreach my $saved_view (@saved_views) {
        my $command = " find  $search_dir/ -name '$saved_view\.yml' ";

        my @results   = split "\n", try_system_command($command);
        my $view_path = chomp_edge_whitespace( $results[0] );
        my $filelink  = &Link_To( $dbc->config('homelink'), $saved_view, "&cgi_application=alDente::View_App&rm=Results&File=$view_path", $Settings{LINK_COLOUR} );
        push @saved_views_links, $filelink;
    }

    return @saved_views_links;
}

#################################
sub prepare_query_arguments {
################################
    # ============================================================================
    # Method     : prepare_query_arguments()
    # Usage      : $self->prepare_query_arguments();
    # Purpose    : prepare the arguments for querying the database
    # Returns    : array_ref of table list; array_ref of field_list, string of join condition
    # Parameters : none
    # Throws     : no exceptions
    # Comments   : to be implemented in Query_Summary.pm
    # See Also   : n/a
    # ============================================================================
    my $self = shift;
    return $self->alDente::Query_Summary::prepare_query_arguments;
}

###############################
sub prepare_API_arguments {
###############################
    # ============================================================================
    # Method : prepare_API_arguments()
    # Usage : $self->prepare_API_arguments();
    # Purpose : prepare the arguments for API call, set $self->{API_args}.
    # Returns : none
    # Parameters : none
    # Throws : no exceptions
    # Comments : none
    # See Also : n/a
    # ============================================================================
    my $self = shift;

    my $dbc      = $self->{dbc};
    my $api_type = $self->{config}{API_type};

    my %input_list = %{ $self->{config}{input_options} } if $self->{config}{input_options};
    my %arguments;
    my @input_elements = sort { $a cmp $b } keys %input_list;

    foreach my $input_field (@input_elements) {

        $input_field =~ /(\w+)\.(\w+)/i;
        my $table = $1;
        my $field = $2;

        my $type        = $self->{config}{input_options}{$input_field}{type};
        my $prompt      = $self->{config}{input_options}{$input_field}{prompt};
        my $description = $self->{config}{input_options}{$input_field}{description};

        my $value = $self->{config}{input_options}{$input_field}{value};

        my $argument = $self->{config}{input_options}{$input_field}{argument};

        if ( $type =~ /date/i ) {    # this is a date
            if ( $value =~ /(.+)<=>(.+)/ ) {
                $arguments{-since} = $1;
                $arguments{ -until } = $2;
                }
            }
            elsif ( $value && ref $value eq 'ARRAY' && scalar @$value > 0 ) {
                    my @value = @$value;
                    my $list;

                    if ( my ($fk) = foreign_key_check( -dbc => $dbc, -field => $field ) ) {
                    ## Foreign key references ##
                    my @newvalue;
                    my $autoquote = 0;
                    ### Mass get_fk_ids
                    my @valids = @{ $self->{dbc}->get_FK_ID( $field, \@value ) };
                    for ( my $index = 0; $index < scalar(@value); $index++ ) {
                        my $newvalue = $valids[$index];
                        next unless ($newvalue);
                        if ( $newvalue =~ /(\d+):/ ) {
                            $newvalue = $1;
                        }
                        elsif ( $newvalue =~ /^[\"\']*(\d+)[\"\']*$/ ) {
                            $newvalue = $1;
                        }
                        push( @newvalue, $newvalue );
                    }
                    if (@newvalue) {
                        $list = Cast_List( -list => \@newvalue, -to => "String", -autoquote => $autoquote );
                    }
                }
                elsif ( $type =~ /^int/i ) {
                    my @values;
                    foreach my $i ( 0 .. $#value ) {
                        ## account for either array of values or delimited string ##
                        unless ( $value[$i] =~ /[1-9]/ ) { $dbc->warning("Invalid $input_field: '$value[$i]'"); next; }
                        my $values = extract_range( $value[$i] );
                        push @values, $values;
                    }
                    $list = Cast_List( -list => \@values, -to => "String" );
                }
                else {
                    my @newvalue;
                    my $autoquote = 0;
                    foreach my $value (@value) {
                        push( @newvalue, $value );
                    }
                    $list = Cast_List( -list => \@newvalue, -to => "String", -autoquote => 1 );
                }
                $arguments{$argument} = $list if ($list);
        }
        elsif ( ( !ref($value) && $value ) || ( ref($value) eq 'SCALAR' && $value ) ) {

            $arguments{$argument} = $value;
        }
    }

    # get the group_by data
    my @group_by;
    if ( $self->{config}{group_by} && ref $self->{config}{group_by} eq 'HASH' ) {
        foreach my $item ( keys %{ $self->{config}{group_by} } ) {
            if ( $self->{config}{group_by}{$item}{picked} ) {
                push( @group_by, $item );
            }
        }
    }
    $arguments{-group_by} = Cast_List( -list => \@group_by, -to => "String" );

    $arguments{-limit} = $self->{config}{record_limit};

    ## Process the output fields
    my @picked_output_options;
    if ( $self->{config}{output_order} && ref( $self->{config}{output_order} ) eq 'ARRAY' ) {
        foreach my $option ( @{ $self->{config}{output_order} } ) {
            if ( $self->{config}{output_options}{$option}{picked} && $option !~ /edit_comments/ ) {
                push( @picked_output_options, $option );
            }
        }
    }
    else {
        foreach my $option ( sort { $a cmp $b } keys %{ $self->{config}{output_options} } ) {
            if ( $self->{config}{output_options}{$option}{picked} && $option !~ /edit_comments/ ) {
                push( @picked_output_options, $option );
            }
        }
    }

    # add group_by fields if not in
    foreach my $group_by_item (@group_by) {
        if ( !( grep /^\b$group_by_item$/, @picked_output_options ) ) {
            push( @picked_output_options, $group_by_item );
        }
    }

    if ( $api_type =~ /data/i ) {    # when api type is data

        ## add key_field if not already included
        my $key_field = $self->{config}{key_field} || '';
        if ( $key_field && !( grep /^\b$key_field$/, @picked_output_options ) ) {
            push( @picked_output_options, $key_field );
        }

    }
    elsif ( $api_type =~ /summary/i ) {    # when api type is summary
        my %stats_hash;

        for ( my $index = 0; $index < scalar @picked_output_options; $index++ ) {
            my $picked_output_option = $picked_output_options[$index];
            if ( $picked_output_option =~ /(.+)_((count)|(avg)|(min)|(max)|(stddev))/ ) {    # this is a function(xxx)
                push( @{ $stats_hash{ "-" . $2 } }, $1 );

                #delete $picked_output_options[$index];
                splice( @picked_output_options, $index, 1 );
                $index--;
            }
        }

        foreach my $key ( keys %stats_hash ) {
            $arguments{$key} = $stats_hash{$key};
        }

    }

    $arguments{-fields} = \@picked_output_options;

    $arguments{-customized_output} = 1;

    # set $self->{API_args}
    # delete non-preset API args
    if ( $self->{API_args} && ( ref $self->{API_args} ) =~ 'HASH' ) {
        foreach my $field ( keys %{ $self->{API_args} } ) {
            if ( $self->{API_args}{$field}{preset} == 0 ) {
                delete $self->{API_args}{$field};
            }
        }
    }

    # set new API args
    foreach my $key ( keys %arguments ) {
        $self->{API_args}{$key}{value}  = $arguments{$key};    # save the api args in self for quick load but not overwriting exsiting api args
        $self->{API_args}{$key}{preset} = 0;
    }

}

#################
sub load_API {
#################
    # ============================================================================
    # Method     : load_API()
    # Usage      : $self->load_API();
    # Purpose    : helper function to load API
    # Returns    : 1 on sucess, 0 on failure
    # Parameters : none
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================
    my $self = shift;

    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $api   = $args{-API_module} || $self->{config}{API_module} || "alDente::alDente_API";
    my $path  = $args{-API_path} || $self->{config}{API_path};                                                   ## <CONSTRUCTION> - get config path ..
    my $quiet = $args{-quiet};

    my $full_path = $path;
    if ( $0 =~ /(.*\/versions\/\w+)\// ) {
        $full_path = "$1/lib/perl/$path";
    }

    unless ( $api =~ /alDente_API/ ) {
        my $api_file = $api;
        $api_file =~ s /::/\//g;
        my $required = "$full_path/$api.pm";
        Message("Use $required to extract data") unless $quiet;
        require $required;
    }

    $self->{API} = $api->new(
        -dbc   => $dbc,
        -dbase => $dbc->{dbase},
        -host  => $dbc->{host},
        -user  => $self->{user},
    );
    if ( $self->{API} ) {
        $self->{API_loaded} = 1;
    }
    else {
        $self->{API_loaded} = 0;
    }

    return $self->{API_loaded};
}

############################
sub get_search_results {
############################
    # ============================================================================
    # Method     : get_search_results()
    # Usage      : $self->get_search_results();
    # Purpose    : retrieve the search results by calling API
    # Returns    : hash returned by the API
    # Parameters : none
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================

    # call API based on arguments
    my $self      = shift;
    my %args      = @_;
    my $api_type  = $self->{config}{API_type};
    my $dbc       = $self->{dbc};
    my $condition = $self->{config}{join_conditions} || $self->{config}{visible_conditions} || $self->{config}{query_condition};

    my $quiet = $args{-quiet};

    my $results;

    my $page;
    if ($api_type) {
        $self->prepare_API_arguments();

        my %api_arguments;
        if ( $self->{API_args} && ref $self->{API_args} eq 'HASH' ) {
            map { $api_arguments{$_} = $self->{API_args}{$_}{value} } keys %{ $self->{API_args} };
        }
        my $api_args = HTML_Dump 'Search Results', \%api_arguments;

        ## Determine which method to call!
        my $scope = "get_" . $self->{config}{API_scope} . "_" . $api_type;

        $self->load_API( -quiet => $quiet ) unless $self->{API_loaded};    ## reload API

        ## Call the API method to retrieve the results

        my $access;
        $results = $self->{API}->$scope( %api_arguments, -quiet => 1 );
        $access = $self->{dbc}->get_local('Access');

        unless ($quiet) {
            $page .= $q->br . $q->hr;
            my $query = SDB::Query::deconstruct_query( $self->{API}->{last_query} );

            $page .= create_tree( -tree => { 'Query' => $query }, -print => 0 );
            $self->{SQL_Query} = $query;    ## keep track of SQL Query so log can show exact query generated ##
            $page .= create_tree( -tree => { 'API call' => "<h3>\$API->$scope</h3>$api_args" }, -print => 0 );
        }
    }
    elsif ($condition) {

        my %Query_args = $self->prepare_query_arguments();    # ( $tables, $fields, $conditions, $grouping, $order, $limit, $distinct )  $tables, $fields, $conditions, -group=>$grouping, -order=>$order, -limit=>$limit, -distinct => $distinct,

        
        ### Force SQL format for dates to enable these columns to be sortable ###
        my %data = $dbc->Table_retrieve(%Query_args);
        $results = \%data;

        my $query = $dbc->{SQL};
        
        if ($query) {
            use SDB::Query;
            my $cleaned_query = SDB::Query::deconstruct_query($query);

            $query =~ s/\\\'/\'/g;
            $self->{SQL_Query} = $query;    ## keep track of SQL Query so log can show exact query generated ##

            $page .= create_tree( -tree => { 'Query' => $cleaned_query }, -print => 0 ) unless $quiet;
        }

        my @condition_list;

        my @visible;
        @visible = @{ $self->{config}{visible_conditions} } if $self->{config}{visible_conditions};

        foreach my $cond (@visible) {
            push @condition_list, $cond;
        }

        my ( %input_list, %input_attr );
        %input_list = %{ $self->{config}{input_options} }    if $self->{config}{input_options};
        %input_attr = %{ $self->{config}{input_attributes} } if $self->{config}{input_attributes};

        my %input = ( %input_list, %input_attr );

        foreach my $field ( keys %input ) {
            my $value = $input{$field}{value};
            my $type  = $input{$field}{type};

            ## synchronize logic below with Query_Summary ... These should be done together and not in separate modules (!!)
            if ( $type =~ /date/i and $value =~ /(.+)<=>(.+)/ ) {
                push @condition_list,  "($field >= '$1' and $field <= '$2')";
            }
            elsif ( $type =~ /date/i and $value =~ /([<>]=?)\s*(.+)/ ) {
                push @condition_list, "($field $1 '$2')";    ## eg ( $field = Rcvd_Date; $value = ' <= 2000-01-01' )
            }
            elsif ( ref $value eq 'ARRAY' && scalar @$value > 0 ) {
                push @condition_list, SDB::HTML::add_SQL_search_condition( $dbc, $field, $value, $type );
            }
        }
        if (@condition_list) {
            $page .= create_tree( -tree => { 'Extra Conditions' => Cast_List(-list=>\@condition_list, -to=>'UL') }, -print => 0 );
        }
    }

    print $page;

    return $results;

}

# to be implemented in Query_Summary.pm
#############################
sub display_query_results {
###############################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $results    = $args{-search_results};                 ## output from get_search_results()
    my $footer     = $args{-footer};
    my $timestamp  = $args{-timestamp};
    my $file_links = $args{-file_links} || 'print,excel';    ## file links of the result page. Valid options include 'excel', 'print', 'csv'. A combination of these options can be specified. If this is not specified, the default is print and excel links.
    my $limit      = $args{-limit};
    my %output_label = %{ $self->{config}{output_labels} } if $self->{config}{output_labels};
    my %hash_display_params = %{ $self->{hash_display} } if $self->{hash_display};

    #enable fixed header
    $hash_display_params{-fixed_header} = 1;

    # display only what is in results
    my $keys = $hash_display_params{ -keys };
    my @new_keys;
    my @temp_keys;

    my $key_field;
    my @key_field_values = ();
    if ( $self->{config}{key_field} ) {
        $key_field = $self->{config}{key_field};
        if ( defined $results->{$key_field} ) { @key_field_values = @{ $results->{$key_field} } }
        else                                  { Message("Warning: $key_field not found in output; buttons may not work") }
    }

    if ( defined $self->{config}{output_function} ) {
        foreach my $output_field ( keys %{ $self->{config}{output_function} } ) {
            my $function      = $self->{config}{output_function}{$output_field};
            my $output_values = eval "$function";
            $results->{$output_field} = $output_values;
        }
    }

    # This is for the older views
    foreach my $function_name ( @{ $self->{config}{output_function_order} } ) {
        if ( !( grep( /^$function_name$/, @$keys ) ) ) {
            push( @$keys, $function_name );
        }
    }

    if ( $keys && ref $keys eq 'ARRAY' ) {
        @temp_keys = grep exists $results->{$_}, @$keys;
    }

    #NOT IMPLEMENTED YET. All of the views should be changed to reflect this but currently they are not.
    # Removes the elements that have not been picked. This also includes method generated columns
    #    foreach my $picked_key ( @temp_keys ){
    #        if ( $self->{config}{output_options}{$picked_key}{picked} == 1 ) {
    #            push(@new_keys, $picked_key);
    #        }
    #    }

    #This code is here only until the above commented code is worked on. Then you can remove this stuff
    @new_keys = @temp_keys;

    $hash_display_params{ -keys } = \@new_keys;
    my $title = $self->{config}{title};
    my $page;

    my ($count_key) = keys %$results;
    my $count = int( @{ $results->{$count_key} } );
    if ( $limit == $count ) { $page = $self->{dbc}->warning( "Results LIMITED to $limit records - Reset limit if required", -hide => 1 ) }

    $title = $self->{config}{title};

    my $graph_type = $q->param('Graph_Type') || $hash_display_params{-graph};

    if ( $hash_display_params{-fields} ) {
        $hash_display_params{-field_info} = $self->get_field_descriptions_for_table_header( -fields => $hash_display_params{-fields} );
    }
    for my $key ( keys %hash_display_params ) {
        if ( $key =~ /^(\-keys|\-fields|\-group|\-timestamp)$/ ) {next}    ## these are handled separately ##
        if ( $hash_display_params{$key} =~ /\{(.+)\}/ ) {
            ## Changing format from string to hash
            my @lines = split ';', $1;
            my %temp;
            for my $line (@lines) {
                if ( $line =~ /^(.+)\=\>(.+)$/ ) {
                    $temp{$1} = $2;
                }
            }
            $hash_display_params{$key} = \%temp;
        }
    }
    if ( $graph_type && $graph_type !~ /^No/i ) {
        if ( $graph_type =~ /^(1|graph)/ ) { $graph_type = 'Column' }

        my $Chart = new GGraph();
        my @order = $q->param('Picked_Options');
        $Chart->parse_output_parameters( -order => \@order );

        my $copy = $title . '.' . timestamp() . '.html';
        $page .= $Chart->google_chart( -name => 'viewChart', -data => $results, -type => $graph_type, -file => "$Configs{URL_temp_dir}/$copy" );

        $page .= Link_To( "$Configs{URL_domain}/$Configs{URL_dir_name}/dynamic/tmp/$copy", 'Printable Page' );

    }
    else {
        my @file_links = Cast_List( -list => $file_links, -to => 'array' );
        my %file_links = map { $_, $title } @file_links;

        $page .= SDB::HTML->display_hash(
            -dbc         => $self->{dbc},
            -hash        => $results,
            -title       => $title,
            -return_html => 1,
            -excel_link  => $file_links{'excel'},
            -print_link  => $file_links{'print'},
            -csv_link    => $file_links{'csv'},
            -timestamp   => $timestamp,
            -footer      => $footer,
            -table_class => 'dataTable',
            %hash_display_params,
        );
    }
    return $page;
}

#######################
sub write_to_file {
########################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $dbc       = $args{-dbc};
    my $group_id  = $args{-group_id};                       ## group id if save as group view
    my $uid       = $args{-user_id};                        ## user id if save as user
    my $view_name = $args{-view_name} || $self->{title};    ## view file name
    my $context   = $args{-context};

    my $scope = $self->{config}{API_scope};
    my $type  = $self->{config}{API_type};

    my $sub_dir;
    if ( $scope && $type ) {
        $sub_dir = $scope . "/" . $type;
    }
    else {
        $sub_dir = "general";
    }

    if ( !$context ) {    # this part is for the save view buttons that are not as rm
        my $save_for = param("Save View For");
        $save_for =~ /Save (\w+) View/;
        $context = $1;
        $view_name = param("View_Name_$context") unless $view_name;
    }

    my ( $group_dir, $id );

    if ( $context =~ /(Group|Internal|Public|Other)/i ) {    ##} or $context eq 'Other' ) {
        $group_dir = "Group";
        $id = $group_id || param("Saved_${context}_ID");
    }
    else {
        $group_dir = "Employee";
        $id        = $uid;
    }

    my $save_dir = $self->{view_directory};

    ## Create the view directory for the user if necessary
    create_dir( $save_dir, "/$group_dir/$id/$sub_dir", -mode => '777' );

    $save_dir .= '/' . $group_dir . "/" . $id . "/" . $sub_dir;

    if ( !$view_name ) {
        Message("You must specify a View Name");
        return 0;
    }

    my $file = $save_dir . "/" . $view_name . ".yml";

    ## if not in production mode, check if there is a production version with a more recent timestamp
    if ( $Configs{default_mode} !~ /production/i ) {
        my $prod_file = "$Configs{'views_dir'}/$Configs{PRODUCTION_DATABASE}/$group_dir/$id/$sub_dir/$view_name.yml";
        if ( -e "$prod_file" ) {
            if ( !-e "$file" || cmp_file_timestamp( $prod_file, $file ) >= 1 ) {
                Message("This view has a newer version in PRODUCTION version --- $prod_file");
                Message("Please update your working copy first before continue!");
                return;
            }
        }
    }

    # construct a view without dbc to save
    my %thawed_view;

    foreach my $key ( keys %$self ) {
        if ( $key ne 'dbc' ) {
            $thawed_view{$key} = $self->{$key};
        }
    }

    $thawed_view{config}{title} = $view_name;
    my $thawed_view_ref = \%thawed_view;
    my $class           = ref $self;

    bless $thawed_view_ref, $class;
    save_diffs( -yml => $thawed_view_ref, -file => $file, -user => $uid );
    `chmod 774 $file`;

    return;

}

########################
sub get_yaml_dump {
########################
    my $self = shift;

    # construct a view without dbc to save
    my %thawed_view;

    foreach my $key ( keys %$self ) {
        if ( $key ne 'dbc' ) {
            $thawed_view{$key} = $self->{$key};
        }
    }

    my $thawed_view_ref = \%thawed_view;
    my $class           = ref $self;

    bless $thawed_view_ref, $class;
    return $thawed_view_ref;

}

#
# A method that can be used to tweak the views as required.
#
# This can be adjusted and customized to clean up existing views or modify the way in which the configuration values are stored
#
##################
sub fix_views {
##################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $filename = $args{-file} || $q->param('File') || '*';
    my $prompt   = $args{-prompt};                                 ## prompt to continue ...
    my $fix      = $args{-fix} || $q->param('Fix');                    ## flag to execute fix (otherwise just generates messages)
    my $grp      = $args{-group_id} || $q->param('Grp_ID');            ## optional if using Group scope
    my $emp      = $args{-employee_id} || $q->param('Employee_ID');    ## optional if using Employee scope
    my $scope    = $args{-scope} || $q->param('Scope') || '*';         ## may choose Group or Employee;
    my $debug    = $args{-debug} || $q->param('Debug');

    ## load YML files ##
    require YAML;
    use SDB::Query;

    my @files;

    my $path;
    if ($emp) {
        $path = "Employee/$emp/general/";
    }
    elsif ($grp) {
        $path = "Group/$grp/general/";
    }
    elsif ($scope) {
        $path = "$scope/*/general/";
    }

    if ( $filename =~ /\// ) {
        ## full path supplied - skip search ##
        @files = ($filename);
        Message("Checking '$filename'");
    }
    else {
        ## search for applicable files ##
        my $search = $Configs{views_dir} . '/' . $dbc->{dbase} . "/$path/$filename.yml";
        @files = glob("$search");
        Message("ls $search");
        Message( "Found " . int(@files) . ' files' );
    }

    foreach my $file (@files) {
        if ($debug) { $dbc->message("Checking $file") }

        my @corrections;
        my ( $context, $local_filename, $grp_id, $emp_id );
        if ( $file =~ /(Employee|Group)\/(\d+)\/(.+?)\/(.+)\.yml$/ ) {
            $context = $1;
            my $id = $2;
            $local_filename = $4;

            if ( $context =~ /Group/ ) {
                $grp_id = $id;
            }
            elsif ( $context =~ /Employee/ ) {
                $emp_id = $id;
            }
        }
        else {
            Message("Warning: invalid file format: $file");
            next;
        }

        unless ( -e $file ) { $dbc->warning("File: $file not found (view)"); next; }

        # my $thawed = $self->load_view(-dbc=>$dbc, -view=>$file);
        # my $view = new alDente::View( -thawed => $thawed, -dbc => $dbc );

        ## use new method to load views.. #
        my $view = $self->load_view( -dbc => $dbc, -view => $file );

        my $previous = HTML_Dump $view;

        my $groups    = $view->{config}{query_group};
        my $layers    = $view->{config}{query_layer};
        my $fields    = $view->{config}{query_fields};
        my $tables    = $view->{config}{query_tables};
        my $condition = $view->{config}{query_condition};
        my $key       = $view->{config}{key_field};
        my $labels    = $view->{config}{output_labels};

        my $default_layer = $view->{hash_display}{-layer};

        ## remove inappropriately added group (no grouping previously, but layer included - should NOT have grouping ##;
        if ( $groups && $layers && ( int(@$groups) == 1 ) && ( $groups->[0] eq $layers->[0] ) ) {
            $view->{config}{query_group} = [];
            $dbc->warning("$file: Clear group @$layers");

            #$view->write_to_file(-dbc=>$dbc, -view_name=>"$local_filename", -user_id=>$emp_id, -group_id=>$grp_id);
        }
        if ( grep /^(No Layers|No)$/, @$groups ) {
            my ( @regroup, @relayer );
            foreach my $grp (@$groups) {
                if ( $grp =~ /^(No|No Layers)$/ ) {
                    $dbc->warning("$file: skip no layering");
                }
                else {
                    push @regroup, $grp;
                }
            }
            $view->{config}{query_group} = \@regroup;

            foreach my $grp (@$layers) {
                if ( $grp =~ /^(No|No Layers)$/ ) {
                    $dbc->warning("$file: skip no layering");
                }
                else {
                    push @relayer, $grp;
                }
            }
            $view->{config}{query_layer} = \@relayer;
            $view->write_to_file( -dbc => $dbc, -view_name => "$local_filename", -user_id => $emp_id, -group_id => $grp_id );
        }
        next;

        my $warnings = 0;
        foreach my $group (@$groups) {
            my $found = 0;
            my ( @suggest, @possible );
            foreach my $field (@$fields) {
                if ( $field =~ /\sAS $group$/i ) {
                    if ( $field =~ /(SUM|MAX|MIN|AVG|COUNT|GROUP_CONCAT)/i ) {
                        ## look for illegal group_concat grouping ##
                        $dbc->warning("Illegal Grouping of Group_Concat field: $group - remove from Group list");
                        last;
                    }
                    else { $found++; last; }
                }
                elsif ( $field eq $group || ( $field =~ /\.$group$/ ) ) {
                    ## check for ambiguities ##
                    $found++;
                    last;
                }
                elsif ( $field =~ /^(\w*)\.?$group AS (.*)/i ) {
                    push @suggest, $2;
                }
                elsif ( $field =~ /\b$group\b (.*)AS (.*)/i ) {
                    push @possible, $2;
                }
            }

            if ( !@suggest && @possible ) { push @suggest, @possible }    ## use possible matches if no good matches found ##
            if ( !$found && int(@suggest) == 1 ) {

                #		$dbc->message("$file: GROUP $group missing from field list (Replacing with $suggest[0] ?) @$groups");
                $group                       = $suggest[0];
                $view->{config}{query_group} = $groups;                   ## replaced grouping with alias ##
            }
            elsif ( !$found ) {

                #		if (@suggest) { $dbc->message("$file: GROUP $group missing from field list.  Options: @suggest ?"); }
                #		else { $dbc->message("$file: GROUP $group missing from field list (no recommendations) Remove from layer options") }
                $warnings++;
            }
        }

        #	if ($warnings) { print HTML_Dump $fields}

        if ( $default_layer && ( $default_layer ne 'No Layers' ) ) {
            if ( !( grep /^$default_layer$/, @$groups ) ) {
                if ( !@$groups ) {
                    $dbc->message("Do not add layer since there is no grouping");
                }
                elsif ( grep /(GROUP_CONCAT)(.*)AS $default_layer$/i, @$fields ) {
                    $dbc->message("Do not add $default_layer to groups...");
                }
                else {

                    # ensure default layer is in group list #
                    push @{ $view->{config}{query_group} }, $default_layer;
                    push @corrections, "Add $default_layer to groups...";
                }
            }
            if ( !( grep /^$default_layer$/, @$layers ) ) {

                # ensure default layer is in group list #
                push @{ $view->{config}{query_layer} }, $default_layer;
                push @corrections, "Add $default_layer to layer options...";
            }
        }

        if ( $key && !defined $labels->{$key} ) {

            # should not be a problem, but should confirm...
            #		$dbc->warning("$file warning: $key not in output field list; Action buttons may not work.");
        }

        ## use alias for groups ##
        if ( my @fix = grep /(.+)\.(.+)/, @$groups ) {

            my @new_groups;
            foreach my $group (@$groups) {
                $group =~ s/(.+)\.(.*)/$2/;
                push @new_groups, $group;
            }

            $view->{config}{query_group} = \@new_groups;
            push @corrections, "rename groups as required.  Use aliases instead of @fix";
        }

        #=pod
        #	if (0) {
        #	    ## tidy up ##
        #	    if ( my @fix = grep /LEFT JOIN/i, @$tables) {
        #		foreach my $fixed (@fix) {
        #		    Message("Separate LEFT JOINS");
        #		    my $split_condition = SDB::Query::split_fields($fixed, -split=>'LEFT JOIN');
        #		    print HTML_Dump $fixed, '->', $split_condition;
        #		}
        #	    }
        #
        #	    if (ref $condition eq 'ARRAY') {
        #	    }
        #	    else {
        #		my $split_condition = SDB::Query::split_fields($condition, -split=>'AND', -trim=>'WHERE');
        #		Message("Split up basic condition");
        #		print HTML_Dump $condition,  '->', $split_condition;
        #	    }
        #	}
        #=cut

        if ( $corrections[0] ) {
            if ($fix) {
                $dbc->message("{code:title='$local_filename'}\n G: $grp_id; E: $emp_id");
                $dbc->warning("Correct Potential Problem with $file");

                #	    print $previous;

                my $error = try_system_command("cp '$file' '$file.bak'");
                my $ok    = try_system_command("ls '$file.bak'");

                if ( $ok =~ /$file\.bak/ ) {
                    $view->write_to_file( -dbc => $dbc, -view_name => "$local_filename", -user_id => $emp_id, -group_id => $grp_id );

                    my $diff = try_system_command("diff --ignore-all-space '$file' '$file.bak'");
                    $diff =~ s/\n/<BR>/g;
                    Message("Diff:<P>$diff\n");

                    if ($prompt) {
                        my $prompt_char = Prompt_Input( -type => 'char', -prompt => 'Accept and continue..? (y/n)  ' );
                        if   ( $prompt_char =~ /y/i ) {next}
                        else                          {last}
                    }
                }
                else {
                    $dbc->warning("Failed to save copy of $file");
                }

            }
            foreach my $correction (@corrections) {
                $dbc->message("$correction ($file)");
            }
            $dbc->message("fixed $file\n{code}\n");
        }
    }

    return;
}

################################
sub get_actions {
#################
    #
    #
    # to be implemented in subclass
#################
    my $self = shift;
    my %actions;
    my $index = 0;
    foreach my $key ( @{ $self->{config}{actions} } ) {
        my $display_action;
        if ($key) {
            $display_action = eval($key);
        }

        $actions{$index} = $display_action;
        $index++;
    }
    return %actions;
}

################################
sub do_actions {
##################
    #
    # to be implemented in subclass
###################
    my $self = shift;
    foreach my $key ( @{ $self->{config}{catch_actions} } ) {
        eval($key);
    }
}

#######################
sub get_custom_cached_links {
#############################
    # Get the list of links to custom cached views
    #
    # Usage:
    #
    # my @list_of_links = @{$self->get_custom_cached_links()};
    #
    # Returns: Arrayref of custom link names
#############################
    my $self = shift;

    return $self->{config}{cached_links};
}

#######################
sub set_custom_cached_links {
#############################
    # Set the config for links to custom cached views
    #
    # Usage:
    # my @list_of_links = ('link1','link2');
    # $self->set_custom_cached_links(-cached_links=>\@list_of_links);
    # Returns: none
#############################
    my $self         = shift;
    my %args         = &filter_input( \@_, -args => 'cached_links' );
    my $cached_links = $args{-cached_links};
    $self->{config}{cached_links} = $cached_links;
    return;
}

#######################                                             should be eliminated
sub display_custom_cached_links {
#######################
    my $self = shift;
    my $cached_links_table;
    my $cached_links = $self->get_custom_cached_links();
    my @cached_links;

    Message("warning: you should not be here at display custom cached links");
    if ( defined $cached_links ) {
        @cached_links = @{$cached_links};
        my $cached_links_table = HTML_Table->new( -title => 'Custom Links' );
        $cached_links_table->Toggle_Colour('off');

        my @links = $self->get_saved_views_links( -saved_view_list => \@cached_links );

        foreach my $link (@links) {
            $cached_links_table->Set_Row( [$link] );
        }
        return $cached_links_table->Printout(0);
    }
    return;
}

###########################											should be eliminated
sub display_search_results {
###########################
    # ============================================================================
    # Method     : display_search_results()
    # Usage      : $self->display_search_results();
    # Purpose    : display the API results in html
    # Returns    : an HTML_Table object if there are any results or a printable string if no results found
    # Parameters : -results          : result hash from get_search_results()
    #              -output_field_list: order in which it displays the results
    #              -key_field        : key field from the result hash
    #              -limit            : limit of the records for the search results
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $results       = $args{-search_results};               ## output from get_search_results()
    my $results_title = $args{-results_title} || "Results";
    my $quiet         = $args{-quiet};

    my $dbc = $self->{dbc};
    Message("warning:  you should not be here at the wrong display_search results");

    my %output_label = %{ $self->{config}{output_labels} } if $self->{config}{output_labels};

    my $api_type  = $self->{config}{API_type};
    my $key_field = $self->{config}{key_field};
    $key_field =~ s/.+ AS (.+)/$1/ig;
    $key_field = chomp_edge_whitespace($key_field);
    my $limit = $self->{config}{record_limit};
    my $output;

    my $result_table;
    my $num_records;

    if ( !$api_type ) {
        $result_table = $self->display_query_results( -search_results => $results );
        return $result_table;
    }
    else {

        unless ($key_field) {
            my @keys = keys %$results;
            $key_field = $keys[0];    ## default to key on the first field returned (NOT preferable, but avoids crashing).
        }

        my $index = 0;

        $result_table = HTML_Table->new( -title => $results_title, -autosort => 1, -class => 'small' );

        ## Process the fields and inputs
        my @picked_output_options;

        if ( $self->{config}{output_order} && ref $self->{config}{output_order} eq 'ARRAY' ) {
            foreach my $option ( @{ $self->{config}{output_order} } ) {
                if ( $self->{config}{output_options}{$option}{picked} ) {
                    push( @picked_output_options, $option );
                }
            }
        }
        else {
            foreach my $option ( sort { $a cmp $b } keys %{ $self->{config}{output_options} } ) {
                if ( $self->{config}{output_options}{$option}{picked} ) {
                    push( @picked_output_options, $option );
                }
            }
        }

        my $form_name = $self->{config}{title};
        my @output_field_list;

        if ( $api_type =~ /data/i ) {

            # create a toggle checkbox to go with the key field
            my $toggle = checkbox( -name => 'Toggle', -label => 'Select All', -onClick => "ToggleNamedCheckBoxes(document.View,'Toggle','$key_field');", -force => 1 );
            ## add key_field if not already included
            if ( $key_field && !( grep /^\b$key_field$/, @picked_output_options ) ) {
                unshift( @picked_output_options, $key_field );
            }

            @output_field_list = map {
                if   (/(.+) as (.+)/i) {$2}
                else                   {$_}
            } @picked_output_options;
            my @sub_headers = map {
                if   (/$key_field/) {$toggle}
                else                {""}
            } @output_field_list;

            $result_table->Set_Headers( \@output_field_list );
            $result_table->Set_Row( \@sub_headers );

        }
        elsif ( $api_type =~ /summary/i || !$api_type ) {

            # add group by to picked_options
            my @group_by;
            if ( $self->{config}{group_by} && ref $self->{config}{group_by} eq 'HASH' ) {
                foreach my $item ( @{ $self->{config}{query_group} } ) {
                    if ( $self->{config}{group_by}{$item}{picked} ) {
                        push( @group_by, $item );
                    }
                }
            }

            # add group_by fields if not in
            foreach my $group_by_item (@group_by) {
                if ( !( grep /^\b$group_by_item$/, @picked_output_options ) ) {
                    unshift( @picked_output_options, $group_by_item );
                }
            }

            @output_field_list = @picked_output_options;
            if ( ( scalar keys %output_label ) == 0 ) {
                $result_table->Set_Headers( \@output_field_list );
            }
            else {
                my @labels;
                foreach my $item (@output_field_list) {
                    if ( exists $output_label{$item} ) {
                        push( @labels, $output_label{$item} );
                    }
                    else {
                        push( @labels, $item );
                    }
                }
                $result_table->Set_Headers( \@labels );
            }
        }

        # check if $self->{config}{output_value} exists. if yes, use the values as results
        my $result_set;
        if ( $self->{config}{output_value}{$key_field} && ( ref $self->{config}{output_value}{$key_field} ) =~ /ARRAY/ ) {
            $result_set = $self->{config}{output_value};
        }
        else {
            $result_set = $results;
        }

        my @key_field_values;

        while ( exists $result_set->{$key_field}[$index] ) {
            my $key_field_value = $result_set->{$key_field}[$index];
            push( @key_field_values, $key_field_value );
            my @row;
            my $column_count = 0;
            foreach my $output_field (@output_field_list) {
                my $output_value = $result_set->{$output_field}[$index];
                if ( !$output_value && $output_field =~ /(\w+)\.(\w+)/ ) {

                    # fully qualified vs not fully qualified
                    $output_value = $result_set->{$2}[$index];
                }
                if ( $self->{config}{highlight}{$output_field} ) {
                    push @{ $self->{config}{highlight}{$output_field}{$output_value}{rowcol} }, "$index,$column_count";
                }
                if ( $self->{config}{output_function}{$output_field} ) {

                    # overwrite result with function return
                    my $function = $self->{config}{output_function}{$output_field};
                    $output_value = $self->$function( -key_field_value => $key_field_value, -output_value => $output_value );
                }
                elsif ( $self->{config}{output_link}{$output_field} ) {
                    my $url = $self->{config}{output_link}{$output_field};
                    if ( $url =~ /<VALUE>/i ) {
                        $url =~ s/<VALUE>/$output_value/ig;
                    }

                    if ( $url =~ /<FUNCTION:(\S+)>/i ) {
                        my $function = $1;
                        my $replace = $self->$function( -key_field_value => $key_field_value );
                        $url =~ s/<FUNCTION:\S+>/$replace/ig;
                    }
                    $output_value = &Link_To( $dbc->config('homelink'), $output_value, $url, $Settings{LINK_COLOUR} );
                }
                if ( $output_field eq $key_field && $api_type =~ /data/i ) {
                    my $key_checkbox = checkbox( -name => $key_field, -value => $results->{$output_field}[$index], -label => '', -force => 1 ) . $output_value;
                    push @row, $key_checkbox;
                }
                else {
                    push @row, $output_value;
                }
                $column_count++;
            }
            $result_table->Set_Row( \@row );
            $index++;
        }

        foreach my $column ( keys %{ $self->{config}{highlight} } ) {
            foreach my $value ( keys %{ $self->{config}{highlight}{$column} } ) {
                my $colour = $self->{config}{highlight}{$column}{$value}{colour};
                my @coordinates = @{ $self->{config}{highlight}{$column}{$value}{rowcol} } if defined $self->{config}{highlight}{$column}{$value}{rowcol};

                foreach my $set (@coordinates) {
                    my @rowcol = split ',', $set;
                    my $row = ++$rowcol[0];
                    $row++;
                    my $col = ++$rowcol[1];
                    $result_table->Set_Cell_Colour( $row, $col, $colour );
                }
            }
        }

        $num_records = $index;
        $self->{result}{key_field_values} = \@key_field_values;

        my $stamp = int( rand(10000) );

        my ( $html_output, $csv_output, $xls_output );

        $html_output = $result_table->Printout("$URL_temp_dir/view_result.$stamp.html");
        $csv_output  = 'cba';                                                              # $result_table->Printout("$URL_temp_dir/view_result.$stamp.csv");
        $xls_output  = 'fde';                                                              # $result_table->Printout("$URL_temp_dir/view_result.$stamp.xls");
        if ( $num_records == $limit ) {
            Message("Warning: output limited to $limit records (change limit to find all records or adjust filter options)");
            return $html_output . $csv_output . $xls_output . $result_table->Printout(0);    ## return table object
        }
        elsif ($num_records) {
            Message("Found $num_records records") unless $quiet;
            ### If any records have been found...
            return $html_output . $csv_output . $xls_output . $result_table->Printout(0);    ## return table object
        }
        else {
            $result_table->Set_Row( ['No Results'] );
            return $result_table->Printout(0);
        }
    }

}

##########################											should be eliminated
sub display_summary {
##########################
    # ============================================================================
    # Method     : display_summary()
    # Usage      : $self->display_summary();
    # Purpose    : get the summary of the search result
    # Returns    : summary table
    # Parameters : none
    # Throws     : no exceptions
    # Comments   : can be overwritten in sub-class
    # See Also   : n/a
    # ============================================================================
    my $self = shift;
    my %args = filter_input( \@_ );

    Message('Warning: You should not be using the old versions of the code, please update your files');

    my $key_field_values = $self->{result}{key_field_values};

    my $count = 0;

    if ( $key_field_values && ref $key_field_values eq 'ARRAY' ) {
        $count = scalar @$key_field_values;
    }

    if ($count) {
        my $summary = HTML_Table->new( -title => 'Summary', -colour => 'lightgrey' );
        $summary->Set_Row( [ '<B>Records</B>', $count ] );

        my $stamp = int( rand(10000) );
        return $summary->Printout("$URL_temp_dir/summary.$stamp.csv") . lbr . $summary->Printout(0);
    }
    else {
        return '';
    }

}

###############################				                    	Should be eliminated
sub display_io_options {
#################################
    # ============================================================================
    # Method     : display_io_options()
    # Usage      : $html_form . = $self->display_io_options(-input=>$input, -output=>$output);
    # Purpose    : Display io options (add the display to an html form)
    # Returns    : html form
    # Parameters : -input    : input table
    #              -output   : output table
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================
    my $self           = shift;
    my %args           = filter_input( \@_ );
    my $open           = $args{ -open };
    my $input_title    = $args{-input_title} || "Configure Input Options";
    my $output_title   = $args{-output_title} || "Configure Output Options";
    my $tab_width      = $args{-tab_width} || 100;
    my $direction      = $args{-direction} || 'horizontal';
    my $print          = $args{ -print } || 0;
    my $input_options  = $args{-input_options} || $self->get_input_options( -return_html => 1 );
    my $output_options = $args{-output_options} || $self->get_output_options( -return_html => 1 );

    Message("warning:  you should not be here at the wrong display_io_options, update your files");
    my $open_option;
    if ($open) {
        $open_option = $input_title . "," . $output_title;
    }
    else {
        $open_option = "";
    }

    my %view_layer;
    $view_layer{$input_title}  = $input_options;
    $view_layer{$output_title} = $output_options;

    return create_tree( -tree => \%view_layer, -tab_width => $tab_width, -default_open => $open_option, -print => $print, -dir => $direction );

}

################################									Should be eliminated
sub display_available_views {
################################
    # ============================================================================
    # Method     : display_available_views()
    # Usage      : $html_form . = $self->display_available_views(-view=>$view);
    # Purpose    : Display available views (add the display to an html form)
    # Returns    : html form
    # Parameters : -input    : views table
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================

    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $open      = $args{ -open };
    my $title     = $args{-title} || "Saved Views";
    my $tab_width = $args{-tab_width} || 100;
    my $print     = $args{ -print } || 0;
    my $view      = $args{-view} || $self->get_view_table( -context => 'All' );

    Message("warning:  you should not be here at the wrong display_available_views, update your files");

    my $open_option;
    if ($open) {
        $open_option = $title;
    }
    else {
        $open_option = "";
    }

    my %view_layer;
    $view_layer{$title} = $view;

    return create_tree( -tree => \%view_layer, -tab_width => $tab_width, -default_open => $open_option, -print => $print );

}

##########################											should be eliminated
sub display_options {
##########################
    # ============================================================================
    # Method     : display_options()
    # Usage      : $html_form . = $self->display_options(-input=>$input, -output=>$output, -html_form=>$html_form);
    # Purpose    : Display io options (add the display to an html form)
    # Returns    : html form
    # Parameters : -input    : input table
    #              -output   : output table
    #              -html_form: html form to add the display to
    # Throws     : no exceptions
    # Comments   : none
    # See Also   : n/a
    # ============================================================================

    my $self             = shift;
    my %args             = @_;
    my $input            = $args{-input};
    my $output           = $args{-output};
    my $views            = $args{-views};
    my $generate_results = $args{-generate_results};

    Message("warning:  you should not be here at the wrong display_options");

    my $open;
    if ($generate_results) {
        $open = 0;
    }
    else {
        $open = defined $self->{config}{show_io_options} ? $self->{config}{show_io_options} : 1;
    }

    my $form;

    # display available input/output
    $form .= $self->display_io_options( -input_options => $input, -output_options => $output, -open => $open );

    $form .= "<br/>";

    # display available saved views
    $form .= $self->display_available_views( -view => $views, -open => $open );

    ## Display a GO button
    $form .= $self->display_custom_cached_links();
    $form .= lbr() . $q->submit( -name => 'rm', -value => 'Generate Results', -onClick => "select_all_options('Picked_Options'); return;", -class => 'Std', -force => 1 );
    $form .= hspace(10) . "Max Number of Results" . hspace(10) . $q->textfield( -name => "Result_Limit", -size => 10 );

    $form .= $q->hidden( -name => "Generate Results", -value => "Generate Results" );

    #$form .= $q->hidden(-name=>"View_Home", -value=>1);
    $form .= $q->hidden( -name => "scope", -value => $self->{config}{API_scope} );
    return $form;
}

#######################												should be eliminated
sub display_actions {
#######################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $actions = $args{-actions};
    my $html;
    my $action_table = HTML_Table->new( -title => 'Actions' );
    if ( $actions && ( ref $actions ) =~ /HASH/ ) {
        foreach ( sort keys %$actions ) {
            $action_table->Set_Row( [ $actions->{$_} ] );
        }
    }
    if ( $self->{hash_display}->{-selectable_field} ) {
        $action_table->Set_Row( [ regenerate_view_btn() ] );
    }
    $html .= $action_table->Printout(0) if $action_table->{rows};

    return $html;
}

#######################                                             should be eliminated
sub regenerate_view_btn {
#######################
    my $self = shift;
    return $q->submit( -name => "Regenerate View", -value => "View with selected records", -class => "Std", -onClick => "this.form.target='_blank';return true;" );
}

#
# If output_functions defined as array - convert to hash
#
#
####################################
sub convert_output_functions {
####################################
    my $self = shift;

    if ( $self->{config}{output_function} && ref $self->{config}{output_function} eq 'ARRAY' ) {

        my @output_functions;
        my %output_function_hash;

        my $index = 0;
        foreach my $function ( @{ $self->{config}{output_function} } ) {
            if ( $function =~ /^(.+?)\s*=>\s*(.*)$/xms ) {
                my $label = $1;
                my $code  = $2;

                #		my $label = $index++; my $code = $function;

                push @output_functions, $label;
                $output_function_hash{$label} = $code;
            }
            else {
                Message("Function format mismatch (should be 'label' => 'code'");
            }
        }
        $self->{config}{output_function}       = \%output_function_hash;
        $self->{config}{output_function_order} = \@output_functions;
    }

    return;
}

##############################
sub _left_join_attribute {
##############################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = filter_input( \@_ );

    my $table     = $args{-table};
    my $attribute = $args{-attribute};
    my $alias     = $args{-alias};

    my $parent = $table;
    $parent =~ s/(\w+)_Attribute/$1/;

    my ($id) = $dbc->Table_find( "Attribute", "Attribute_ID", "WHERE Attribute_Name = '$attribute'" );
    my $query = "LEFT JOIN $table ";

    if ($alias) {
        $query .= "AS $alias ";
    }
    else {
        $alias = $table;
    }

    $query .= "ON $alias.FK_" . $parent . "__ID = $parent." . $parent . "_ID AND $alias.FK_Attribute__ID = $id";

    return $query;
}

#
# reusable method to use in view functions
# Groups hash by a key and transforms hash into an array of display_hashes ordered by group
# If hash is from DB retieve all special functions in SELECT must use an alias
# Usage:
#   my %hash = $dbc->Table_retrieve(...);
#   my @extra_column = merge_data_for_table_column(\%hash, \@lib_names, -grouping_field=>'Work_Request.FK_Library__Name',\@fields);
#
#  passes arguments to display_hash
#
# Return: array of display_hash outputs (which show up as sub-tables in views)
#####################
sub merge_data_for_table_column {
#####################
    my %args = &filter_input( \@_, -args => 'dbc, data_hash, key_list, grouping_field, field_order', -mandatory => 'dbc, data_hash, key_list, grouping_field' );

    my $dbc                = $args{-dbc};
    my $data_hash_ref      = $args{-data_hash};                  #contains data_hash with groups of data defined by grouping key -- hash should be ordered by grouping key
    my $key_list_ref       = $args{-key_list};
    my $grouping_field     = $args{-grouping_field};
    my $field_order_ref    = $args{-field_order};
    my $disable_auto_links = $args{-disable_auto_links} || 0;    #enables fields to be passed to display hash to generate links based on DBField references (By default there will be linking)
    my @field_order;

    my %field_lookup;
    if ($field_order_ref) {
        @field_order = Cast_List( -list => $field_order_ref, -to => 'array' );

        #Parse field order if provided, alias vs non-alias
        foreach my $field (@field_order) {
            if ( $field =~ /(.+) AS (.+)/i ) {
                $field_lookup{$2} = $1;
                $field = $2;
            }
            elsif ( $field =~ /^(\w+)\.(\w+)$/i ) {
                $field_lookup{$2} = $field;
                $field = $2;
            }
            else {
                $field_lookup{$field} = $field;
            }
        }
    }

    #parse grouping key
    my $grouping_key;
    if ( $grouping_field =~ /(.+) AS (.+)/i ) {
        $grouping_key = $2;
    }
    elsif ( $grouping_field =~ /^(\w+)\.(\w+)$/i ) {
        $grouping_key = $2;
    }
    else {
        $grouping_key = $grouping_field;
    }

    my %data_hash = %$data_hash_ref;
    my @key_list = Cast_List( -list => $key_list_ref, -to => 'Array' );

    # utilize build_ref_lookup to replace linkable fields
    my %ref_links = ();
    if ( !$disable_auto_links && ( keys %field_lookup ) ) {
        %ref_links = %{ SDB::HTML::build_ref_lookup( -dbc => $dbc, -hash => \%data_hash, -fields => \%field_lookup, -enable_csv_check => 1 ) };
    }

    my %group_table_hash;

    my @group_array    = Cast_List( -list => $data_hash{$grouping_key}, -to => 'Array' );
    my $hash_array_len = @group_array;
    my $group_value    = @group_array[0];
    my %group_hash;
    my %result_hashes;

    ### Begin building look up hash (key is grouping_key value)
    #goes through hash by value length
    for ( my $i = 0; $i < $hash_array_len; $i++ ) {
        my $curr_group_value;
        my %temp_hash;

        # for each value in hash at index i copy to temporary hash
        foreach my $key ( keys %data_hash ) {
            if ( $key ne $grouping_key ) {
                my $value = $data_hash{$key}[$i];

                #replace value with link if it is a linkable field
                if ( $ref_links{$key}{$value} ) {
                    $value = $ref_links{$key}{$value};
                }

                push @{ $temp_hash{$key} }, $value;
            }
        }

        $curr_group_value = @group_array[$i];

        if ( $curr_group_value eq $group_value ) {
            foreach my $key ( keys %temp_hash ) {
                push @{ $group_hash{$key} }, $temp_hash{$key}[0];
            }
        }
        else {

            # finish off previous group, add to hash with key - group value
            $result_hashes{$group_value} = {%group_hash};

            #for the current temp hash start new group and group hash
            undef %group_hash;
            $group_value = $curr_group_value;

            foreach my $key ( keys %temp_hash ) {
                push @{ $group_hash{$key} }, $temp_hash{$key}[0];
            }
        }
        undef %temp_hash;
    }

    #Add last group to result hash
    $result_hashes{$group_value} = {%group_hash};

    ## End (finish building look up hash)
    ###########################

    #build array of tables using key list to lookup 'group_table'
    my @results_array;

    my $num_of_fields = @field_order;    # used to determine if return should be a list of values, or table

    if ( $num_of_fields > 1 ) {
        ## set default args for call to display_hash... ##
        $args{-return_html}    = 1;
        $args{ -keys }         = \@field_order;
        $args{-no_footer}      = 1;
        $args{-border}         = defined $args{-border} ? $args{-border} : 1;
        $args{-collapse_limit} = defined $args{-collapse_limit} ? $args{-collapse_limit} : 2;
        $args{-no_links}       = 1;                                                             # note: always set this if building links here, also do not pass in $args{-fields} if not necessary (slow)
        $args{-width}          = 'auto';

        foreach my $key (@key_list) {
            my $key_table = '';
            if ( $result_hashes{$key} ) {
                $args{-hash} = $result_hashes{$key};
                $key_table = SDB::HTML::display_hash(%args);
            }

            push @results_array, $key_table;
        }
    }
    else {
        foreach my $key (@key_list) {
            my $key_data = '';

            if ( defined $result_hashes{$key} ) {
                $key_data = join( ', ', @{ $result_hashes{$key}{ $field_order[0] } } );
            }

            push @results_array, $key_data;
        }
    }

    return \@results_array;
}

#
# Obtains description for fields right before being passed to display hash
# The descriptions are from DBField, they will be shown as tool tips for table column headers
# Usage:
#   my %field_descriptions = get_field_descriptions_for_table_header(\%hash, \@lib_names, -grouping_field=>'Work_Request.FK_Library__Name',\@fields);
#	  $self->{config}{table_list} must exist in order to find
#
# Return: hash of table_alias, real_table, field and description for each key(field_alias) in the fields hash
#####################
sub get_field_descriptions_for_table_header {
#####################

    my $self = shift;
    my $dbc  = $self->{dbc};

    my %args = &filter_input( \@_, -args => 'fields', -mandatory => 'fields' );
    my $fields = $args{-fields};    #fields from the fields hash passed into display_hash

    my %field_desc;
    my @fields;

    #parse table and field name from SQL fields
    #This is for non method generated fields
    foreach my $key ( keys %{$fields} ) {
        my $temp = $fields->{$key};
        if ( $temp =~ /(.*)\b(\w+)\.(\w+)\b(.*)/ ) {
            if ( $3 ne $temp ) {
                push @fields, $3;
                $field_desc{$key}{field}       = $3;
                $field_desc{$key}{alias_table} = $2;
                $field_desc{$key}{real_table}  = $self->{config}{table_list}{$2};
                my $preset_desc = $self->{config}{heading_descriptions}{$key};
                if ($preset_desc) {
                    $field_desc{$key}{description} = $preset_desc;
                }
            }
        }
    }

    #Attaches tooltips to method generated fields
    foreach my $key ( keys %{ $self->{config}{output_function} } ) {
        if ( $self->{config}{heading_descriptions}{$key} ) {
            $field_desc{$key}{description} = $self->{config}{heading_descriptions}{$key};
        }
    }

    my $s_fields = join "', '", @fields;
    my $s_tables = join "', '", ( values %{ $self->{config}{table_list} } );

    # get descriptions from database
    my %raw_descriptions = $dbc->Table_retrieve(
        'DBField DBF1, DBField DBF2',
        [ 'DBF1.Field_Table', 'DBF1.Field_Name', 'DBF1.Field_Description' ],
        "WHERE DBF1.DBField_ID = DBF2.DBField_ID AND DBF1.Field_Name IN ('$s_fields') AND LENGTH(DBF1.Field_Description) != 0 AND DBF2.Field_Table IN ('$s_tables')"
    );

    my $records = $#{ $raw_descriptions{Field_Name} };

    #match descriptions to table.field in %field_desc
    foreach my $key ( keys %field_desc ) {
        foreach my $index ( 0 .. $records ) {
            my $table       = $raw_descriptions{Field_Table}[$index];
            my $field       = $raw_descriptions{Field_Name}[$index];
            my $description = $raw_descriptions{Field_Description}[$index];
            $description =~ s/([\'\"\\])/\\$1/g;

            if ( ( $field_desc{$key}{real_table} eq $table ) && ( $field_desc{$key}{field} eq $field ) && ( !defined( $field_desc{$key}{description} ) ) ) {
                $field_desc{$key}{description} = $description;
            }
        }
    }

    return \%field_desc;
}

1;
