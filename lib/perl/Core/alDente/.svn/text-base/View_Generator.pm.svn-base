###################################################################################################################################
# alDente::View_Generator.pm
# An interface to generate a query_view
#
#
# Example of usage:
#
#  use alDente::View
#  use alDente::View_Generator
#  my $query_generator = alDente::View_Generator->new(-dbc=>$dbc, -generate_view=>$generate_view);
#  $query_generator->home_page();
#
#
###################################################################################################################################

package alDente::View_Generator;

## alDente modules

use strict;
use CGI qw(:standard);
use Data::Dumper;
use File::Find;

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
use alDente::Query_Summary;

use vars qw($Connection $view_directory $Current_Department);    # view_directory = $Configs{'Home_public'}/views

our @ISA = qw(alDente::View);

############################
## Default Configuration settings ##
############################

#####################
sub request_broker {
#####################

    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $generate_view = $args{-generate_view} || param("Generate View");
    my $frozen        = $args{-frozen} || param('Frozen_Config');                                        ## the frozen copy
    my $new_class     = $args{-class} || param('Class');                                                 ## specify class if not View_Generator (accepted value: Query_Summary)

    my $query_generator;
    if ($frozen) {
        my $thawed = Safe_Thaw( -name => 'Frozen_Config', -thaw => 1, -encoded => 1 );
        $query_generator = alDente::View_Generator->new( -thawed => $thawed, -dbc => $dbc, -class => $new_class );
    }
    else {
        $query_generator = alDente::View_Generator->new( -dbc => $dbc, -generate_view => $generate_view );
    }

    $query_generator->home_page();
    return;
}

# create a new View_Generator
#
#
###########
sub new {
###########
    my $inv             = shift;
    my %args            = @_;
    my $dbc             = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # database connection
    my $thawed          = $args{-thawed};                                                                   ## thawed copy
    my $new_class       = $args{-class};                                                                    ## class name. accepted value: Query_Summary
    my $referenced_view = $args{-referenced_view};                                                          ## only defined for customized views which reference primary views

    my $class = ref($inv) || $inv;
    my $self = {};

    if ($thawed) {                                                                                          # a thawed copy is most likely to be used by Query_Summary, unless specified by -class.
        $self = $thawed;                                                                                    # construct object from thawed copy
        $self->{dbc} = $dbc;
        if ( $new_class eq 'View_Generator' ) {
            bless $self, "alDente::View_Generator";
        }
        else {
            require alDente::Query_Summary;
            bless $self, "alDente::Query_Summary";
        }
    }
    else {
        bless( $self, $class );
        $self->{dbc} = $dbc;
        $self->{view_directory} = alDente::Tools::get_directory( -structure => 'DATABASE', -root => $Configs{'views_dir'}, -dbc => $dbc );
    }

    if ($referenced_view) { $self->{referenced_view} = $referenced_view }

    $self->merge_views();

    return $self;
}

# responsible for creating the input form and parsing the input param by calling set_general_options
#
#
##################
sub home_page {
##################
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $title         = $args{-title};                                                                                   ## title of the view, to be displayed on the view page
    my $generate_view = $args{-generate_view};
    my $type          = $args{-type};                                                                                    ## eg view or custom
    my $query_tables  = $args{-query_tables};                                                                            ## check if query tables is submitted, to determine the resulting page
    my $dbc           = $self->{dbc} || $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $view_choice   = $args{-view_app};
    my $page;

    my $referenced_view = $args{-referenced_view} || $self->{referenced_view};                                           ## only defined for customized views which reference primary views
    my $view            = $args{-view}            || $self->{view};

    if ($referenced_view) {
        require YAML;
        $title ||= "Customize $view";

        my $baseline_view = alDente::View::load_view( -dbc => $dbc, -view => $referenced_view );
        foreach my $setting ( keys %{ $baseline_view->{config} } ) {
            if ( !$self->{config}{$setting} ) {
                $self->{config}{$setting} = $baseline_view->{config}{$setting};
            }
        }
    }
    else {
        $title ||= "Manage $view";
    }

    if ( !$query_tables && $generate_view ) {

        # comes from Edit button, load from object
        my $description             = $self->{config}{view_description};
        my $query_tables            = $self->{config}{query_tables};
        my $left_joins              = $self->{config}{left_joins};
        my $query_fields            = $self->{config}{query_fields};
        my $output_function         = $self->{config}{output_function};
        my $output_function_order   = $self->{config}{output_function_order};
        my $query_condition         = $self->{config}{query_condition};
        my $join_conditions         = $self->{config}{join_conditions};
        my $visible_conditions      = $self->{config}{visible_conditions};
        my $mandatory_fields        = $self->{config}{mandatory_fields};
        my $record_limit            = $self->{config}{record_limit};
        my $distinct                = $self->{config}{distinct};
        my $key                     = $self->{config}{key_field};
        my $order_by                = $self->{config}{query_order};
        my $group_by                = $self->{config}{query_group};
        my $layer_by                = $self->{config}{query_layer};
        my $searchable_fields       = $self->{config}{searchable_fields};
        my $regex_searchable_fields = $self->{config}{regex_searchable_fields};
        my $searchable_attributes   = $self->{config}{searchable_attributes};
        my $actions                 = $self->{config}{actions};
        my $catch_actions           = $self->{config}{catch_actions};
        my $hash_display            = $self->{hash_display};
        my $graph_options           = $self->{config}{graph_options};
        my $cached_links            = $self->{config}{cached_links};

        my $html_form = alDente::Form::start_alDente_form( $dbc, "Generate View", $dbc->homelink() );

        if ( $dbc->get_local('user_name') eq 'Admin' ) {
            ## show configurations settVings for Admin ##
            print create_tree( -tree => { 'View Generator Configs' => HTML_Dump $self->{config} }, -return_html => 1 );
        }

        my $label_class = 'vlightredbw';
        my $section_class = 'vlightbluebw';
        my $sub_section_class = 'vlightyellowbw';
        my $text_class  = 'form-control';
        my $row_class;
        
        ## starts the html table
        my $input_table = HTML_Table->new( -title => $title, -class => 'small', -toggle => 1 );


#        $input_table->Set_Row( ["<font color='blue'>View Description</font>"], $label_class );
#        $input_table->Set_Row( [ textfield( -name => 'View Description', -size => 100, default => $description, -class => $text_class ) ], -repeat => 0 );

        $input_table->Set_Row( ["<B>View Description:</B>", 
                textfield(-name=>'View Description', -class=>$text_class, -default=>$description) ], $sub_section_class);

#        $input_table->Set_Row( ["<font color='blue'>KEY Field (only necessary when records require selection checkboxes for actions)</font>"], $label_class );
        $input_table->Set_Row( [ Show_Tool_Tip("<B>KEY field</B>", "(only necessary when records require selection checkboxes for actions)"),
                textfield( -name => 'Key Field', -size => 50, default => $key, -force=>1) ],  $sub_section_class, -repeat => 0);

        $input_table->Set_sub_header( 'Query Generation', $section_class);

        ## Query Fields ##
        my $clear = radio_group( -name => 'Clear', -value => 'Clear', -onClick => "SetSelection(this.form,'Query Fields','')" );
        my $reset = reset( -name => 'Reset', -class => 'Std' );
# $clear . &hspace(5) . $reset
        $input_table->Set_sub_header("<B>SELECT (one / line)</B> ", $label_class );

        if ( $query_fields && ref $query_fields eq 'ARRAY' ) {
            foreach my $field (@$query_fields) {
                $input_table->Set_Row( [ '', textfield( -name => 'Query Fields', -size => 100, default => $field, -class => $text_class ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ ' ', textfield( -name => 'Query Fields', -size => 100, default => '', -class => $text_class ) ], -repeat => 1 );
        }

        ## Output Methods ## (fields whose values are extracted via methods)
        $input_table->Set_Row( ["<B>SELECT METHODS (Advanced)</B>"], $sub_section_class );
        if ( $output_function && ref $output_function eq 'HASH' ) {
            my @order;
            if   ($output_function_order) { @order = @$output_function_order }
            else                          { @order = keys %{$output_function} }
            foreach my $field (@order) {
                my $string = "$field => $output_function->{$field}";
                $input_table->Set_Row( [ ' ', textarea( -name => "Output Methods", -cols => 100, -rows => 3, default => $string, -class => $text_class ) ], -repeat => 1 );
            }
            $input_table->Set_Row( [ ' ', textarea( -name => "Output Methods", -cols => 100, -rows => 3, default => '', -class => $text_class ) ], -repeat => 1 );
        }
        else {
            $input_table->Set_Row( [ ' ', textarea( -name => 'Output Methods', -cols => 100, -rows => 3, default => '', -class => $text_class ) ], -repeat => 1 );
        }

        ## Distinct option ##
#        $input_table->Set_Row( ["<B>DISTINCT</B>"], $label_class);
        my $default = 'No';
        if ($distinct) { $default = 'Yes' }
        else { $default = 'No' }
        
        $input_table->Set_Row( [ "<B>DISTINCT</B>", popup_menu( -name => 'Distinct', -values => [ 'No', 'Yes' ], -default => $default, -force=>1) ], $label_class);

        if ($referenced_view) {
            ## Only include overriding options (exclude primary tables & join conditions which are defined by the view) ##
#            $input_table->Set_Row( ["<font color='blue'>VIEW:</font>"], 'lightredbw' );
            $input_table->Set_Row( ["<B>View</B>", textfield( -name => 'Referenced_View', -size => 100, -default => $referenced_view, -class => $text_class ) . hidden( -name => 'View', -value => $view, -force => 1 ) ]);
        }
        else {
            ## Full view settings including table and relationship settings ##
            $input_table->Set_Row( ["<B>FROM</B>"], $label_class );
#            $input_table->Set_Row( ["<font color='blue'>FROM (one table per line)</font>"], 'lightredbw' );
            if ( $query_tables && ref $query_tables eq 'ARRAY' ) {
                foreach my $table (@$query_tables) {
                    $input_table->Set_Row( [ '', textfield( -name => 'Query Tables', -size => 100, -default => $table, -class => 'wide-txt' ), ], -repeat => 1 );
                }
            }
            else {
                $input_table->Set_Row( [ '', textfield( -name => 'Query Tables', -size => 100, default => '', -class => 'wide-txt' ) ], -repeat => 1 );
            }

#            $input_table->Set_Row( ["<font color='blue'>LEFT JOIN (one table per line)</font>"], 'lightredbw' );
            $input_table->Set_Row( ["<B>LEFT JOIN</B>"], $label_class );

            if ( $left_joins && ref $left_joins eq 'ARRAY' && scalar @$left_joins > 0 ) {
                foreach my $join (@$left_joins) {
                    $input_table->Set_Row( [ '', textfield( -name => 'Left Joins', -size => 100, -default => $join, -class => $text_class ), ], -repeat => 1 );
                }
            }
            else {
                $input_table->Set_Row( [ '', textfield( -name => 'Left Joins', -size => 100, default => '', -class => $text_class ) ], -repeat => 1 );
            }

            ## Query condition field is deprecated; exists for backward compatibility

            $input_table->Set_Row( ["<B>WHERE (join conditions)</B>"], $label_class );
 #           $input_table->Set_Row( ["<font color='blue'>WHERE (join conditions)</font>"], 'lightredbw' );
            if ($query_condition) {
                $query_condition =~ s/^s*where\s*//i;
                $query_condition =~ s /\bNULL\b/null/;    ## avoids textarea glitch auto-converts uppercase "NULL" to '-'
                $input_table->Set_Row( [ '', textfield( -name => 'Join Conditions', -size => '100', -default => $query_condition, -class => $text_class ) ], -repeat => 1 );
            }

            ## Conditions on which the Query Tables are joined (not visible in the view's condition tree)

            elsif ( $join_conditions && ref $join_conditions eq 'ARRAY' && scalar @$join_conditions > 0 ) {
                foreach my $cond (@$join_conditions) {
                    $input_table->Set_Row( [ '', textfield( -name => 'Join Conditions', -size => '100', -default => $cond, -class => $text_class ) ], -repeat => 1 );
                }
            }
            else {
                $input_table->Set_Row( [ '', textfield( -name => 'Join Conditions', -size => '100', -default => '', -class => $text_class ) ], -repeat => 1 );
            }
        }

        ## Conditions not related to joining the input tables (visible in the view's condition tree)

        $input_table->Set_Row( ["<B>AND (non-join conditions)</B>"], $label_class );
#        $input_table->Set_Row( ["<font color='blue'>WHERE (other conditions) </font>"], 'lightredbw' );
        if ( $visible_conditions && ref $visible_conditions eq 'ARRAY' && scalar @$visible_conditions > 0 ) {
            foreach my $cond (@$visible_conditions) {
                $input_table->Set_Row( [ '', textfield( -name => 'Visible Conditions', -size => '100', -default => $cond, -class => $text_class ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Visible Conditions', -size => '100', -default => '', -class => $text_class ) ], -repeat => 1 );
        }

        $input_table->Set_Row( ["<B>GROUP BY</B>"], $label_class );
#        $input_table->Set_Row( ["<font color='blue'>GROUP BY (one field per line)</font>"], 'lightredbw' );
        if ( $group_by && ref $group_by eq 'ARRAY' && scalar @$group_by > 0 ) {
            foreach my $group (@$group_by) {
                $input_table->Set_Row( [ '', textfield( -name => 'Query Group', -size => 100, -default => $group, -class => 'normal-txt' ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Query Group', -size => 100, -default => '', -class => 'normal-txt' ) ], -repeat => 1 );
        }

#        $input_table->Set_Row( ["<font color='blue'>Separate Tab Options (one aliased field per line)</font>"], 'lightredbw' );
        $input_table->Set_Row( ["<B>LAYER BY (tabs)</B>"], $label_class );
        if ( $layer_by && ref $layer_by eq 'ARRAY' && scalar @$layer_by > 0 ) {
            foreach my $layer (@$layer_by) {
                $input_table->Set_Row( [ '', textfield( -name => 'Query Layer', -size => 100, -default => $layer, -class => 'normal-txt' ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Query Layer', -size => 100, -default => '', -class => 'normal-txt' ) ], -repeat => 1 );
        }
        
        $input_table->Set_Row( ["<B>ORDER BY</B>"], $label_class );
 #       $input_table->Set_Row( ["<font color='blue'>ORDER BY (one field per line)</font>"], 'lightredbw' );
        if ( $order_by && ref $order_by eq 'ARRAY' && scalar @$order_by > 0 ) {
            foreach my $order (@$order_by) {
                $input_table->Set_Row( [ '',textfield( -name => 'Query Order', -size => 100, -default => $order, -class => 'normal-txt' ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Query Order', -size => 100, -default => '', -class => 'normal-txt' ) ], -repeat => 1 );
        }

        $input_table->Set_Row( ["<font color='blue'>LIMIT</font>"], $label_class );
        if ($record_limit) {
            $input_table->Set_Row( [ textfield( -name => 'Record Limit', -size => 5, -default => $record_limit ) ] );
        }
        else {
            $input_table->Set_Row( [ textfield( -name => 'Record Limit', -size => 5, -default => '1000' ) ] );
        }

        $input_table->Set_sub_header( 'View Options<BR><HR>', $section_class );

        $input_table->Set_Row( ["<B>Searchable (fully qualify)</B>"], $sub_section_class );
#        $input_table->Set_Row( ["<font color='blue'>Searchable Fields (fully qualified)</font>"], 'lightbluebw' );
        if ( $searchable_fields && ref $searchable_fields eq 'ARRAY' && scalar @$searchable_fields > 0 ) {
            foreach my $searchable_field (@$searchable_fields) {
                $input_table->Set_Row( [ '', textfield( -name => 'Searchable Fields', -size => 50, -default => $searchable_field, -class => 'wide-txt' ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Searchable Fields', -size => 50, -default => '', -class => 'wide-txt' ) ], -repeat => 1 );
        }

        $input_table->Set_Row( ["<B>Search with REGEXP</B>"], $sub_section_class );
#         $input_table->Set_Row( ["<font color='blue'>Searchable Fields using Regex Match (fully qualified)</font>"], 'lightbluebw' );
        if ( $regex_searchable_fields && ref $regex_searchable_fields eq 'ARRAY' && scalar @$regex_searchable_fields > 0 ) {
            foreach my $regex_searchable_field (@$regex_searchable_fields) {
                $input_table->Set_Row( [ '', textfield( -name => 'Regex Searchable Fields', -size => 50, -default => $regex_searchable_field, -class => 'wide-txt' ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Regex Searchable Fields', -size => 50, -default => '', -class => 'wide-txt' ) ], -repeat => 1 );
        }

#        $input_table->Set_Row( ["<font color='blue'>Searchable Attributes (fully qualified)</font>"], 'lightbluebw' );
        $input_table->Set_Row( ["<B>Searchable Attributes</B>"], $sub_section_class );
        if ( $searchable_attributes && ref $searchable_attributes eq 'ARRAY' && scalar @$searchable_attributes > 0 ) {
            foreach my $searchable_attribute (@$searchable_attributes) {
                $input_table->Set_Row( [ '', textfield( -name => 'Searchable Attributes', -size => 50, -default => $searchable_attribute, -class => 'wide-txt' ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Searchable Attributes', -size => 50, -default => '', -class => 'wide-txt' ) ], -repeat => 1 );
        }

        $input_table->Set_Row( ["<B>Mandatory (fully qualify)</B>"], $sub_section_class);
#        $input_table->Set_Row( ["<font color='blue'>Mandatory fields (fully qualified)</font>"], 'lightbluebw' );
        if ( $mandatory_fields && ref $mandatory_fields eq 'ARRAY' && scalar @$mandatory_fields > 0 ) {
            foreach my $mandatory_field (@$mandatory_fields) {
                $input_table->Set_Row( [ '', textfield( -name => 'Mandatory Fields', -size => 50, -default => $mandatory_field, -class => $text_class ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Mandatory Fields', -size => 50, -default => '', -class => $text_class ) ], -repeat => 1 );
        }

#        $input_table->Set_Row( ["<font color='blue'>Add Actions</font> <i>eg. save_plate_set_btn (look for methods like '..._btn')</i>"], 'lightbluebw' );
        $input_table->Set_sub_header("<B>Add Actions </B> <i>eg. save_plate_set_btn (look for methods like '..._btn')</i>", $sub_section_class );
        if ( $actions && ref $actions eq 'ARRAY' && scalar @$actions > 0 ) {
            foreach my $action ( @{$actions} ) {
                $input_table->Set_Row( [ '', textfield( -name => 'Add Actions', -size => 100, -default => $action, -class => $text_class ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Add Actions', -size => 100, -default => '', -class => $text_class ) ], -repeat => 1 );
        }
        
        $input_table->Set_sub_header("<B>Catch Actions </B> <i>eg. catch_save_plate_set_btn (methods designed to catch action button above)</i>", $sub_section_class );
#        $input_table->Set_Row( ["<font color='blue'>Catch Actions</font> <i>eg. catch_save_plate_set_btn (methods designed to catch action button above)</i>"], 'lightbluebw' );
        if ( $catch_actions && ref $catch_actions eq 'ARRAY' && scalar @$catch_actions > 0 ) {
            foreach my $catch ( @{$catch_actions} ) {
                $input_table->Set_Row( [ '', textfield( -name => 'Catch Actions', -size => 100, -default => $catch, -class => $text_class ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Catch Actions', -size => 100, -default => '', -class => $text_class ) ], -repeat => 1 );
        }

        $input_table->Set_sub_header("<B>Additional Links </B>", $sub_section_class );
#        $input_table->Set_Row( ["<font color='blue'>Additional Links</font> <i></i>"], 'lightbluebw' );
        if ( $cached_links && ref $cached_links eq 'ARRAY' && scalar @$cached_links > 0 ) {
            foreach my $link ( @{$cached_links} ) {
                $input_table->Set_Row( [ '', textfield( -name => 'Additional Links', -size => 100, -default => $link, -class => 'wide-txt' ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Additional Links', -size => 100, -default => '', -class => 'wide-txt' ) ], -repeat => 1 );
        }

        ## prompt for Display Options ##
        $input_table->Set_sub_header("<B>Display Options </B> <i>eg: -selectable_field:Plate_ID or -layer:Library_Nam</i>", $section_class );
#        $input_table->Set_Row( ["<font color='blue'>Display Options</font> <i>eg: -selectable_field:Plate_ID or -layer:Library_Name</i><H>Parameters used for display_hash table generation"], 'lightbluebw' );
        if ( $hash_display && ref $hash_display eq 'HASH' && scalar( keys %$hash_display ) > 0 ) {
            my $created;
            foreach my $key ( keys %$hash_display ) {
                if ( $key =~ /^(\-keys|\-fields|\-group|\-timestamp)$/ ) {next}    ## these are handled separately ##
                my @values;
                if ( ref $hash_display->{$key} eq 'ARRAY' ) {
                    @values = @{ $hash_display->{$key} };
                }
                elsif ( ref $hash_display->{$key} eq 'HASH' ) {
                    @values = ( $hash_display->{$key} );
                }
                else {
                    @values = ( $hash_display->{$key} );
                }
                foreach my $value (@values) {
                    if ( $key && $value && ref $key ne 'ARRAY' && ref $value ne 'ARRAY' && ref $key ne 'HASH' && ref $value ne 'HASH' ) {
                        my $entry = $key . ":" . $value;
                        $created = 1;
                        $input_table->Set_Row( [ '', textfield( -name => 'Display Options', -size => 100, -default => $entry, -class => $text_class ) ], -repeat => 1 );
                    }
                    elsif ( ref $value eq 'HASH' ) {
                        use Data::Dumper;
                        local $Data::Dumper::Terse = 1;
                        my $entry = $key . " :";
                        my %temp  = %$value;
                        my $str   = Dumper($value);    ### Doing this will ensure that all of the hash gets printed out instead of printing hash of hash of... with the memory addresses
                        $str =~ s/\s+/ /g;
                        $entry .= $str;
                        $created = 1;
                        $input_table->Set_Row( [ '', textfield( -name => 'Display Options', -size => 100, -default => $entry, -class => $text_class ) ], -repeat => 1 );
                    }
                }
            }
            if ( !$created ) {
                $input_table->Set_Row( [ '', textfield( -name => 'Display Options', -size => 100, -default => '', -class => $text_class ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Display Options', -size => 100, -default => '', -class => $text_class ) ], -repeat => 1 );
        }

        ## prompt for Graph Options ##
        $input_table->Set_sub_header( "Graph Options<HR><i>eg: Height:480 width:800 xaxis_title:Reads isStacked:true</i><BR>(parameters used for generating charts)", $sub_section_class);
        if ( $graph_options && @$graph_options ) {
            my $created;
            foreach my $option (@$graph_options) {
                $input_table->Set_Row( [ '', textfield( -name => 'Graph Options', -size => 100, -default => $option, -class => 'wide-txt' ) ], -repeat => 1 );
            }
        }
        else {
            $input_table->Set_Row( [ '', textfield( -name => 'Graph Options', -size => 100, -default => '', -class => $text_class ) ], -repeat => 1 );
        }

        #   $input_table->Set_Row([submit(-name=>"Generate View", -value=>"Generate View", -class=>"Std")]);
        $input_table->Set_Row( [ submit( -name => "rm", -value => "Generate View", -class => "Std" ) . hidden( -name => "cgi_application", -value => "alDente::View_App", -force => 1 ) ] , 'white');

 #       $input_table->Set_Line_Colour(['#faa', '#afa']);
        $html_form .= $input_table->Printout(0);
        $html_form .= end_form();

        ### print the html form
        $page .= $html_form;
    }
    elsif ($view_choice) {
        $self->set_general_options();
        $self->set_input_options();
        $self->set_output_options();

        require alDente::Query_Summary;
        bless $self, "alDente::Query_Summary";
        $self->{dbc} = $dbc;
    }
    elsif ($generate_view) {
        ## comes from view generator page: create Query_Summary object as a View

        $self->set_general_options();
        $self->set_input_options();
        $self->set_output_options();

        require alDente::Query_Summary;
        bless $self, "alDente::Query_Summary";
        $self->{dbc} = $dbc;
        $page .= $self->home_page( -generate_results => 1, -dbc => $dbc );
    }

    return $page;
}

# REQUIRED
# -title: view title
# -query_fields: array ref of fields. e.g., ['Plate_ID as pla', 'Library_Name as lib']
# -query_tables: array ref of tables. e.g., ["Library as L", "Plate as p"]
# -query_condition: condition minus the "where" keyword. e.g., "FK_Library__Name = Library_Name and Plate_Type = 'Tube'"
#
# OPTIONAL:
# -group_by: array ref of group by fields. e.g., ['Plate_Status']
# -order_by: array ref of order by fields. e.g., ['pla desc']
# -distinct: 1 or 0
# -record_limit: e.g., 1000
# -searchable_fields: array ref of fully qualified name of fields with which users are allowed to search. e.g., ['Library.Library_FullName']
# -regex_searchable_fields: array ref of fully qualified name of fields that search by regex match. e.g., ['Library.Library_FullName']
# -searchable_attributes: array ref of entries. each entry is in the format of 'Attribute_Table.Attribute_Name:Attribute_join_table'. Attribute_Table and Attribute_join_table need to use table alias name if specified in the query. e.g., ["Attribute.Antibody_Name:Plate_Attribute"]
# -display_options: arrary ref of any args used by hash_display, each in the format of '-option1:value1'. e.g., ['-display:lib']
# -graph_options: array ref of any args used by google_chart in format 'option: value'...
#
###############################
sub set_general_options {
###############################
    my $self  = shift;
    my %args  = @_;
    my $title = $args{-title} || param("Title") || "Query View";

    my @query_fields       = param("Query Fields");
    my @output_function    = param("Output Methods");
    my @query_tables       = param("Query Tables");
    my @left_joins         = param("Left Joins");
    my @join_conditions    = param("Join Conditions");
    my @visible_conditions = param("Visible Conditions");
    my @group_by           = param("Query Group");
    my @order_by           = param("Query Order");
    my @layer_by           = param('Query Layer');
    my @search             = param("Searchable Fields");
    my @regex              = param("Regex Searchable Fields");
    my @attributes         = param("Searchable Attributes");
    my @mandatory          = param("Mandatory Fields");
    my @display            = param("Display Options");
    my @graph              = param('Graph Options');
    my @actions            = param("Add Actions");
    my @catch_actions      = param("Catch Actions");
    my $referenced_view    = param('Referenced_View');
    my $description        = param('View Description');
    my @cached_links       = param('Additional Links');

    # remove blank entries
    @query_fields       = grep /\S/, @query_fields;
    @output_function    = grep /\S/, @output_function;
    @left_joins         = grep /\S/, @left_joins;
    @join_conditions    = grep /\S/, @join_conditions;
    @visible_conditions = grep /\S/, @visible_conditions;
    @query_tables       = grep /\S/, @query_tables;
    @group_by           = grep /\S/, @group_by;
    @order_by           = grep /\S/, @order_by;
    @layer_by           = grep /\S/, @layer_by;
    @search             = grep /\S/, @search;
    @regex              = grep /\S/, @regex;
    @attributes         = grep /\S/, @attributes;
    @mandatory          = grep /\S/, @mandatory;
    @display            = grep /\S/, @display;
    @graph              = grep /\S/, @graph;
    @actions            = grep /\S/, @actions;
    @cached_links       = grep /\S/, @cached_links;

    my $query_fields       = $args{-query_fields}            || \@query_fields;
    my $output_function    = $args{-output_function}         || \@output_function;
    my $query_tables       = $args{-query_tables}            || \@query_tables;
    my $left_joins         = $args{-left_joins}              || \@left_joins;
    my $join_conditions    = $args{-join_conditions}         || \@join_conditions;
    my $visible_conditions = $args{-visible_conditions}      || \@visible_conditions;
    my $group_by           = $args{-group_by}                || \@group_by;
    my $order_by           = $args{-order_by}                || \@order_by;
    my $layer_by           = $args{-layer_by}                || \@layer_by;
    my $distinct           = $args{-distinct}                || param("Distinct") eq 'Yes' ? 1 : 0;
    my $key                = $args{-key_field}               || param('Key Field');
    my $record_limit       = $args{-record_limit}            || param("Record Limit") || 1000;
    my $search             = $args{-searchable_fields}       || \@search;
    my $regex              = $args{-regex_searchable_fields} || \@regex;
    my $attributes         = $args{-searchable_attributes}   || \@attributes;
    my $mandatory          = $args{-mandatory_fields}        || \@mandatory;
    my $display            = $args{-display_options}         || \@display;
    my $graph              = $args{-graph_options}           || \@graph;
    my $actions            = $args{-actions}                 || \@actions;
    my $catch_actions      = $args{-catch_actions}           || \@catch_actions;
    my $cached_links       = $args{-cached_links}            || \@cached_links;

    ## set config settings (if not already defined)

    if ( $search && ref $search eq 'ARRAY' && scalar @$search > 0 ) {
        $self->{config}{searchable_fields} = $search;
        $self->{config}{input_order}       = $search;
    }
    else {
        $self->{config}{searchable_fields} = [];
    }

    if ( $regex && ref $regex eq 'ARRAY' && scalar @$regex > 0 ) {
        $self->{config}{regex_searchable_fields} ||= $regex;
    }
    else {
        $self->{config}{regex_searchable_fields} = [];
    }

    if ( $attributes && ref $attributes eq 'ARRAY' && scalar @$attributes > 0 ) {
        $self->{config}{searchable_attributes} = $attributes;
    }
    else {
        $self->{config}{searchable_attributes} = [];
    }

    if ( $display && ref $display eq 'ARRAY' && scalar @$display > 0 ) {
        foreach my $option (@$display) {
            if ( $option =~ /(-\w+)\s*:\s*(.+)/ ) {
                my $index_field = $1;
                my $value       = $2;
                my $ref         = eval "$value";
                my $link        = $ref || $value;

                if ( ref $self->{hash_display}{$1} eq 'ARRAY' ) {
                    ## add to existing array if applicable ##
                    push @{ $self->{hash_display}{$index_field} }, $link;
                }
                elsif ( $self->{hash_display}{$index_field} ) {
                    ## recast to array if multiple similar keys ##
                    my $scalar = $self->{hash_display}{$index_field};
                    undef $self->{hash_display}{$1};
                    push @{ $self->{hash_display}{$index_field} }, $scalar;
                    push @{ $self->{hash_display}{$index_field} }, $link;
                }
                else {
                    ## store as standard scaler ##
                    $self->{hash_display}{$index_field} = $link;
                }
            }
        }
    }

    ## same as above for graph options
    if ( $graph && ref $graph eq 'ARRAY' && scalar @$graph > 0 ) {
        foreach my $option (@$graph) {
            if ( $option =~ /(-\w+)\s*:\s*(.+)/ ) {
                my $index_field = $1;
                my $link        = $2;
                if ( ref $self->{graph_options}{$1} eq 'ARRAY' ) {
                    ## add to existing array if applicable ##
                    push @{ $self->{graph_options}{$index_field} }, $link;
                }
                elsif ( $self->{graph_options}{$index_field} ) {
                    ## recast to array if multiple similar keys ##
                    my $scalar = $self->{graph_options}{$index_field};
                    undef $self->{graph_options}{$1};
                    push @{ $self->{graph_options}{$index_field} }, $scalar;
                    push @{ $self->{graph_options}{$index_field} }, $link;
                }
                else {
                    ## store as standard scaler ##
                    $self->{graph_options}{$index_field} = $link;
                }
            }
        }
    }

    if ($layer_by) {
        ## ensure that any defined layers are also defined in the default group list ... ##
        foreach my $layer (@$layer_by) {
            if ( !grep /^$layer$/, @$group_by ) { push @$group_by, $layer; }
        }
    }

    ## leave baseline values if not defined in reference view, unless otherwise defined ##
    $self->{config}{query_tables} ||= $query_tables;

    $self->{config}{left_joins}         ||= $left_joins;
    $self->{config}{join_conditions}    ||= $join_conditions;
    $self->{config}{visible_conditions} ||= $visible_conditions;

    $self->{config}{mandatory_fields} ||= $mandatory;
    $self->{config}{display_options}  ||= $display;
    $self->{config}{graph_options}    ||= $graph;
    $self->{config}{output_function}  ||= $output_function;
    $self->{config}{record_limit}     ||= $record_limit;
    $self->{config}{distinct}         ||= $distinct;
    $self->{config}{query_group}      ||= $group_by;
    $self->{config}{query_layer}      ||= $layer_by;
    $self->{config}{actions}          ||= $actions;
    $self->{config}{catch_actions}    ||= $catch_actions;
    $self->{config}{view_description} ||= $description;
    $self->{config}{cached_links}     ||= $cached_links;

    ## override from meta view if defined ##
    if (@$query_fields) { $self->{config}{query_fields} = $query_fields }
    if (@$order_by)     { $self->{config}{query_order}  = $order_by }
    if (@$group_by)     { $self->{config}{query_group}  = $group_by }
    if (@$layer_by)     { $self->{config}{query_layer}  = $layer_by }
    if ($key)           { $self->{config}{key_field}    = $key }

    if ( $self->{dbc}->get_local('user_name') eq 'Admin' ) {
        ## show configurations settVings for Admin ##
        print create_tree( -tree => { 'View Generator configs' => HTML_Dump $self->{config} }, -return_html => 1 );
    }
    return;
}

# construct input_options to be used by the view
#
##################################
sub set_input_options {
#####################################
    my $self = shift;
    my %args = @_;

    my $dbc    = $self->{dbc};
    my $search = $self->{config}{searchable_fields};
    my $regex  = $self->{config}{regex_searchable_fields};

    my @fields       = @$search if ( $search and ref $search eq 'ARRAY' );
    my @regex_fields = @$regex  if ( $regex  and ref $regex  eq 'ARRAY' );

    my @attributes;

    # need table list name for finding out table name from alias
    my $ref_hash = $self->get_table_list();
    $self->{config}{table_list} = $ref_hash;
    my $real_table_name;

    foreach my $field (@fields) {
        if ( $field =~ /(\w+)\.(\w+)/ ) {

            #use table list to find table name from alias $1
            $real_table_name = $self->{config}{table_list}{$1};

            my $name = "$1.$2";
            my ($type) = $dbc->Table_find( "DBField",   "Field_Type",     "where Field_Name = '$2' and Field_Table = '$real_table_name'" );
            my ($attr) = $dbc->Table_find( "Attribute", "Attribute_Name", "where Attribute_Class = '$real_table_name' and Attribute_Name = '$2'" );
            if ( !$type and $attr ) {
                push @attributes, $field;
            }

            elsif ($type) {
                $self->{config}{input_options}{$name}{type} = 'date' if ( $type =~ /date/ );
                $self->{config}{input_options}{$name}{value} = '';
            }
        }
    }

    foreach my $field (@regex_fields) {
        if ( $field =~ /(\w+\.\w+)/ ) {
            my $name = $1;
            $self->{config}{input_options}{$name}{regex} = 1;
        }
    }

    @attributes = ( @attributes, @{ $self->{config}{searchable_attributes} } );
    my @order;

    foreach my $attribute (@attributes) {
        my ( $attr, $name, $alias );
        if ( $attribute =~ /(.+)\s+as\s+(\w+)/i ) {
            $alias = $2;
            $attr  = $1;
        }
        else {
            $attr = $attribute;
        }
        if ( $attr =~ /(\w+)\.(\w+)/ ) {
            $name = $1 . "_Attribute." . $2;
            $alias = $2 unless ($alias);
            push @order, $name;

            my ($type) = $dbc->Table_find( 'Attribute', 'Attribute_Type', "where Attribute_Name = '$2'" );

            $self->{config}{input_attributes}{$name}{value} = '';
            $self->{config}{input_attributes}{$name}{alias} = $alias;
            $self->{config}{input_attributes}{$name}{type}  = $type;
        }
    }

    $self->{config}{input_attribute_order} = \@order;

}

# construct output_options to be used by the view
#
###############################
sub set_output_options {
###############################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};

    $self->get_output_default();
    return;
}

# to be called by set_output_options
#
###########################
sub get_output_default {
###########################
    my $self = shift;
    my %args = @_;

    my $query_fields    = $self->{config}{query_fields};
    my $query_group     = $self->{config}{query_group};
    my $output_function = $self->{config}{output_function};
    my $dbc             = $self->{dbc};

    my $ref_hash = $self->{config}{table_list};

    my $tables_string = Cast_List( -list => [ values %$ref_hash ], -to => 'string', -autoquote => 1 );

    my @fields;

    if ( $query_fields && ref $query_fields eq 'ARRAY' ) {
        @fields = @$query_fields;
    }

    my @order;
    my @display_keys;
    my %sql_aliases;
    my @function_order;

    foreach my $field (@fields) {
        $field =~ s/^\s+//;
        $field =~ s/\s+$//;
        my ( $prompt, $raw_field, $table_name, $field_name, $name, $alias );

        if ( $field =~ /(.+)\s+as\s+(\w+)/i ) {
            $alias     = $2;
            $prompt    = $2;
            $raw_field = $1;
        }
        else {
            $raw_field = $field;
        }

        if ( $raw_field =~ /^(\w+)\.(\w+)$/ ) {
            $table_name = $1;
            $field_name = $2;
            $name       = "$1.$2";
        }
        elsif ( $raw_field =~ /^\w+$/ ) {    ## raw field is a single field, need to find its table name
            ($table_name) = $dbc->Table_find( "DBField, DBTable", "DBTable_Name", "where FK_DBTable__ID = DBTable_ID and DBTable_Name in ($tables_string) and Field_Name = '$raw_field'" );
            $field_name = $raw_field;
            $name       = "$table_name.$field_name";
        }

        else {
            $field_name = $raw_field;
            $name       = $raw_field;
        }

        $alias = $field_name unless $alias;

        if ( !$prompt ) {

            my @field_names = $dbc->Table_find( "DBField", "Field_Name", "where Field_Table = '$table_name'", -distinct => 1 );

            if ( grep /\b$field_name\b/, @field_names ) {
                my $query_table_name = $ref_hash->{$table_name};
                if ($query_table_name) {
                    ($prompt) = $dbc->Table_find( "DBField, DBTable", "Field_Alias", "where FK_DBTable__ID = DBTable_ID and DBTable_Name = '$query_table_name'  and Field_Name = '$field_name'" );
                }
                else {
                    $prompt = $raw_field;
                }
            }

            else {
                $prompt = $field_name;
            }
        }

        $self->{config}{output_options}{$prompt}{picked} = 1;
        $self->{config}{output_labels}{$prompt}          = $prompt;
        $self->{config}{output_params}{$prompt}          = $field;
        $self->{hash_display}{-fields}{$alias}           = $raw_field;
        $self->{config}{name}{$prompt}                   = $name;
        push @display_keys, $alias;
        push @order,        $prompt;
        $sql_aliases{$prompt} = $alias;
    }

    if ($output_function) {
        foreach my $function (@$output_function) {
            my ($function_key) = split /=>/, $function;
            $function_key = chomp_edge_whitespace($function_key);
            push @function_order, $function_key;

            #This may need to be combined with the other code as well
            $self->{config}{output_options}{$function_key}{picked} = 1;
        }

        #This may not be needed anymore
        $self->{config}{output_function_order} = \@function_order;
    }

    my @final_order = ( @order, @function_order );

    $self->{hash_display}{ -keys } = \@display_keys;
    $self->{config}{output_order} = \@final_order;

    ## remove block below ? ##
    my @labels;
    if ( $query_group && int(@$query_group) > 0 ) {
        foreach my $item (@$query_group) {
            my $label = $sql_aliases{$item} || $item;
            $self->{config}{group_by}{$label}{picked} = 1;
            push @labels, $label;
        }
    }
    return;
}

# convert a table list string to a hash ref, keyed by alias (if no alias, table name), value is table name
##############################
sub get_table_list {
##############################
    my $self         = shift;
    my %args         = @_;
    my $query_tables = $self->{config}{query_tables};    ## string passed as table list to Table_retrieve
    my $left_joins   = $self->{config}{left_joins};

    my @tables_array_ori;
    if ( $query_tables && ref $query_tables eq 'ARRAY' ) {
        @tables_array_ori = @$query_tables;
    }

    if ( $left_joins && ref $left_joins eq 'ARRAY' ) {
        @tables_array_ori = ( @tables_array_ori, @$left_joins );
    }

    my @tables_array;

    foreach my $item (@tables_array_ori) {

        if ( $item =~ /\s+(left|right){0,1}\s+join\s+/i ) {
            my @eles = split /\s+join\s+/i, $item;
            foreach my $ele (@eles) {
                $ele =~ s/\s*left\s*//i;
                $ele =~ s/\s*right\s*//i;

                if ( $ele =~ /(.+)\s+on\s+/i ) {
                    push( @tables_array, $1 );
                }
                else {
                    push( @tables_array, $ele );
                }
            }
        }
        elsif ( $item =~ /(.+)\s+on\s+/i ) {
            push( @tables_array, $1 );
        }
        else {
            push( @tables_array, $item );
        }
    }

    my %as;
    foreach my $table (@tables_array) {
        $table =~ s/^\s+//;
        $table =~ s/\s+$//;
        if ( $table =~ /(\w+)\s+as\s+(\w+)/i ) {
            $as{$2} = $1;
        }
        else {
            $as{$table} = $table;

        }
    }

    return \%as;

}

# get a yaml object copy or dump to a yaml file
# usage:
#   my $query_generator = alDente::View_Generator->new(-dbc=>$dbc);
#   # write to a yaml file that is visiable from the web as a group saved view
#   $query_generator->yaml(-group_id=>$group_id, -view_name=>$view_name,%args);

#   # write to a yaml file that is visiable from the web as a user saved view
#   $query_generator->yaml(-user_id=>$user_id, -view_name=>$view_name,%args);
# see set_general_option for a list of %args
#
################
sub yaml {
################
    my $self = shift;
    my %args = @_;

    $self->set_general_options(%args);
    $self->set_input_options();
    $self->set_output_options();

    if ( $args{-view_name} ) {
        $self->write_to_file(%args);
    }
    else {
        return $self->get_yaml_dump();
    }
}

1;
