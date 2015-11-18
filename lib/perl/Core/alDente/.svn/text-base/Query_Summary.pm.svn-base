###################################################################################################################################
# alDente::Query_Summary.pm
#
# This class inherits alDente::View. It defines the configurations to query the database directly (vs. through API)
# This object is usually created using alDente::View_Generator, an interface accessible for LIMS admin only.
# It can also be created by modifying an existing YAML file of a query summary view (under Employee/*/general or Group/*/general)
#
#
###################################################################################################################################

package alDente::Query_Summary;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Views;

## alDente modules
use alDente::View;
use vars qw($Connection  );

#use base alDente::View;
our @ISA = qw(alDente::View);

#####################################
# example: plate summary:
# add the following before return statement:
#
#  $self->{config}{title} = "Plate Summary";  ## init title
#  $self->{config}{query_condition}  = 'where 1';  ## API modules to be used
#  $self->{config}{query_tables}    = 'Plate'; ## path to the API module
#  $self->{config}{key_field}   = 'Plate_ID';          ## define the key field in the result set.
#  $self->{config}{record_limit} = 1000;
#
#################################
sub set_general_options {
#################################
    #
    # Set general options for the view
    #
    my $self = shift;
    my %args = filter_input( \@_ );

    $self->SUPER::set_general_options;    ## call super

    return;
}

#####################################
# example: plate summary:
# add the following before return statement:
#
#    $self->{config}{input_options} = {
#				      'Plate.FK_Library__Name'          => {value=>''},
#				      'Plate.Plate_Number'              => {value=>''},
#				      'Plate.Plate_Created'             => {value=>'',type=>'date'},
#				      'Plate.Plate_Type'                => {value=>''},
#				      'Plate.Plate_Status'              => {value=>''},
#				      'Plate.QC_Status'                 => {value=>''},
#				     };
#
#    ## order when appear on the page
#    $self->{config}{input_order} = [
#				    'Plate.FK_Library__Name',
#				    'Plate.Plate_Number',
#				    'Plate.Plate_Created',
#				    'Plate.Plate_Type',
#				    'Plate.Plate_Status',
#				    'Plate.QC_Status',
#				   ];
#
#
################################
sub set_input_options {
################################
    #
    # set input options for the view
    #
    my $self = shift;
    my %args = filter_input( \@_ );
    $self->SUPER::set_input_options;

    return;
}

#####################################
# example: plate summary:
# add the following before return statement:
#
#    ## general output for mapping and expression
#    ## key: aliases in API. you need to add the alias to the API module if necessary
#    ## picked: default picked if set to 1
#    $self->{config}{output_options} = {
#				       'FK_Library__Name'                 => {picked=>1},
#				       'Plate_Status'                     => {picked=>1},
#				       'Plate_Number'                     => {picked=>1},
#				       'Plate_Type'                       => {picked=>1},
#				       'QC_Status'                        => {picked=>1},
#				       'Plate_ID'                         => {picked=>1},
#				       'Plate_Created'                    => {picked=>1},
#				      };
#    ## order as appeared on the page
#    $self->{config}{output_order} = [
#				     'Plate_ID',
#				     'FK_Library__Name',
#				     'Plate_Number',
#				     'Plate_Created',
#				     'Plate_Type',
#				     'Plate_Status',
#				     'QC_Status',
#				    ];
#
#    #$self->{config}{group_by} = { # these need to be the same as they appear in the API as output fields
#				 #'template_group'    => {picked => 1},
#				#};
#
#
#################################
sub set_output_options {
#################################
    #
    # set output options for the view
    #
    my $self = shift;
    my %args = filter_input( \@_ );
    $self->SUPER::set_input_options;

    return;
}

########################################
# overwrite home_page in super class
# if LIMS admin, add a edit button
#
#
########################################
sub home_page {
########################################
    my $self = shift;
    my $dbc  = $self->{dbc};

    my %args = filter_input( \@_ );

    my $page = $self->SUPER::home_page( %args, -dbc => $dbc );

    my $admin;

    if ($dbc) {
        if ( grep /LIMS Admin/, keys %{ $dbc->get_local('Access') } ) {
            $admin = 1;
        }
    }

    # add a Edit button if LIMS admin
    if ($admin) {
        print "<hr/>";
        my $generator_form .= alDente::Form::start_alDente_form( $dbc, "Query Generator Form", $dbc->homelink() );
        ### freeze self at the end and pass as frozen
        my $self_copy = $self;
        $generator_form .= RGTools::RGIO::Safe_Freeze( -name => "Frozen_Config", -value => $self_copy, -format => 'hidden', -encode => 1, -exclude => [ 'API', 'dbc', 'connection', 'transaction' ] );
        $generator_form .= hidden( -name => 'Class', -value => 'View_Generator' );
        $generator_form .= hidden( -name => 'cgi_application', -value => 'alDente::View_App', -force => 1 );
        $generator_form .= submit( -rm => 'Manage View', -value => 'Edit View', -class => 'Action', -force => 1 );
        $generator_form .= end_form();

        ### print the html form
        $page .= $generator_form;
    }
    $page .= 'qs';
    return $page;
}

#################################
# overwrite method in View
#################################
sub prepare_query_arguments {
#################################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $dbc         = $self->{dbc};
    my $join_cond   = $self->{config}{join_conditions};
    my $visible     = $self->{config}{visible_conditions};
    my $tables      = join( ",", @{ $self->{config}{query_tables} } );
    my $left_joins  = $self->{config}{left_joins};
    my $distinct    = $self->{config}{distinct};
    my $order_by    = $self->{config}{query_order};
    my $group_order = $self->{config}{query_group};
    my $group_by    = $self->{config}{group_by};
    my $limit       = $self->{config}{record_limit};
    my $attributes  = $self->{config}{input_attributes};

    if ($order_by) { $order_by = Cast_List( -list => $order_by, -to => 'string' ) }

    my %fields = %{ $self->{config}{input_options} } if $self->{config}{input_options};

    my $condition;
    my %left_join_alias;    # Keep track of tables/aliases left joined for attributes

    ## Backward compatibility for query_condition in .yml files

    my @conditions = (1);
    if ( $self->{config}{query_condition} ) {
        $self->{config}{query_condition} =~ s/^where/ /i;
        push @conditions, $self->{config}{query_condition};
    }
    else {
        my @join_array;
        my @visible_array;

        @join_array    = @$join_cond if ( $join_cond and ref $join_cond eq 'ARRAY' );
        @visible_array = @$visible   if ( $visible   and ref $visible   eq 'ARRAY' );

        push @conditions, ( @join_array, @visible_array );
    }

    foreach my $field ( keys %fields ) {
        if ( $field =~ /^(\w+).(\w+)$/ ) {
            my $t     = $1;
            my $f     = $2;
            my $value = $self->{config}{input_options}{$field}{value};
            my $type  = $self->{config}{input_options}{$field}{type};

            # <CONSTRUCTION> Fold date query composition into add_SQL_search_condition

            if ( $type =~ /date/i ) {    # this is a date
                if ( $value =~ /(.+)<=>(.+)/ ) {
                    push @conditions, "($field >= '$1' and $field <= '$2')";
                }
                elsif ( $value =~ /([<>]=?)\s*(.+)/ ) {
                    push @conditions, "($field $1 '$2')";    ## eg ( $field = Rcvd_Date; $value = ' <= 2000-01-01' )
                }
            }
            elsif ( ref $value eq 'ARRAY' && scalar @$value > 0 ) {
                push @conditions, SDB::HTML::add_SQL_search_condition( $dbc, $field, $value, $type );
            }
        }
    }

    if ( $attributes && ref $attributes eq 'HASH' ) {
        foreach my $attr ( keys %$attributes ) {
            if ( $attr =~ /(\w+)\.(\w+)/ ) {
                my $table     = $1;
                my $attribute = $2;
                my $alias     = $attributes->{$attr}{alias};
                my $value     = $attributes->{$attr}{value};
                my $type      = $attributes->{$attr}{type};

                $tables .= " " . $self->_left_join_attribute( -table => $table, -attribute => $attribute, -alias => $alias );
                $left_join_alias{"$table.$attribute"} = $alias;

                if ( ref $value eq 'ARRAY' and scalar @$value > 0 ) {
                    push @conditions, SDB::HTML::add_SQL_search_condition( $dbc, "$alias.Attribute_Value", $value, $type );
                }
            }
        }
    }

    $condition = join ' AND ', @conditions;
    $condition &&= "WHERE $condition";

    if ($left_joins) {
        my @prefixed = map { " LEFT JOIN " . $_ } @$left_joins;
        $tables .= join( "", @prefixed );
    }

    my @group_fields;

    my @keys;
    if   ($group_order) { @keys = @{$group_order} }
    else                { @keys = keys %$group_by }

    foreach my $item (@keys) {
        if ( $group_by->{$item}{picked} == 1 ) {
            push @group_fields, $item;
        }
    }
    my $group;
    if (@group_fields) { $group = join ',', @group_fields }

    my %output_fields = %{ $self->{config}{output_options} } if $self->{config}{output_options};
    my %output_labels = %{ $self->{config}{output_labels} }  if $self->{config}{output_labels};
    my %output_params = %{ $self->{config}{output_params} }  if $self->{config}{output_params};
    my %table_list    = %{ $self->{config}{table_list} }     if $self->{config}{table_list};

    my @field_list;

    foreach my $output_field ( keys %output_fields ) {
        if ( $output_fields{$output_field}{picked} ) {
            ## Check if the output field is an attribute
            my ( $alias, $field_name );
            my $skip = 0;

            if ( $output_params{$output_field} =~ /(.+) as (.+)/i ) {
                $field_name = $1;
                $alias      = $2;
            }
            else {
                $field_name = $output_params{$output_field};
            }

            my $num_matches = 0;
            my @matches;

            while ( $field_name =~ /\b(\w+)\.(\w+)\b/g ) {
                $num_matches++;
                push @matches, [ $1, $2 ];
            }

            foreach my $match (@matches) {
                my $table       = $table_list{ $match->[0] } || $match->[0];
                my $table_match = $match->[0];
                my $field       = $match->[1];

                $alias ||= $match->[1];

                my @field_names     = $dbc->Table_find( "DBField",   "Field_Name",     "where Field_Table = '$table'",     -distinct => 1 );
                my @attribute_names = $dbc->Table_find( "Attribute", "Attribute_Name", "where Attribute_Class = '$table'", -distinct => 1 );
                if ( !grep {/^$field$/} @field_names and $field ne 'Attribute_Value' ) {
                    my $attr_table = $table . "_Attribute";

                    ## Check if attribute table was left joined already

                    if ( exists $left_join_alias{"$attr_table.$field"} ) {
                        $alias = $left_join_alias{"$attr_table.$field"};
                        $output_params{$output_field} =~ s/(\b)$table_match.$field(\b)/\1$alias.Attribute_Value\2/;
                    }

                    elsif ( grep {/^$field$/} @attribute_names ) {

                        # If the attribute found is not in the SELECT statement by itself
                        # (i.e. part of a CASE, GROUP_CONCAT, etc. statement with other attributes),
                        # then disregard the alias

                        my ($type) = $dbc->Table_find( 'Attribute', 'Attribute_Type', "WHERE Attribute_Name = '$field' AND Attribute_Class = '$table_match'" );

                        $alias = $field if ( $num_matches > 1 );

                        $left_join_alias{"$attr_table.$field"} = $alias;

                        $tables .= " " . $self->_left_join_attribute( -table => $attr_table, -attribute => $field, -alias => $alias );
                        if ( my ( $refT, $refF ) = $dbc->foreign_key_check( -field => $type ) ) {
                            ## convert FK attributes to Field_Reference values if applicable ##

                            my ($view) = $dbc->Table_find( 'DBField', 'Field_Reference', "WHERE Field_Name = '${field}_ID'" );
                            $view =~ s/^\w+/$field\.$view/;               ## fully qualify simply defined fields
                            $view =~ s/\b$field\./${field}_Lookup\./g;    ## change domain to Lookup alias

                            ## re-alias attribute with Lookup suffix (to avoid conflict with 'Attribute AS ' alias)

                            $tables .= " LEFT JOIN $refT AS ${refT}_Lookup ON ${refT}_Lookup.${refT}_ID = $field.Attribute_Value";
                            $output_params{$output_field} =~ s/(\b)$table_match.$field(\b)/\1$view\2/;
                        }
                        else {
                            $output_params{$output_field} =~ s/(\b)$table_match.$field(\b)/\1$alias.Attribute_Value\2/;
                        }
                        unless ( $output_params{$output_field} =~ / AS /i ) { $output_params{$output_field} .= " AS $output_field" }
                    }
                    else {

                        #if it breaks, it should show and we should fix the view
                        #$skip = 1;
                        #Message ("$table.$field is not a valid field or attribute. Skipping...");
                        #last;
                    }
                }
            }
            if ( $output_params{$output_field} ) {
                push( @field_list, $output_params{$output_field} ) unless $skip;
            }
        }
    }

    my %Qargs;    ## generate hash to pass to Table_retrieve ##
    $Qargs{-table}     = $tables;
    $Qargs{-fields}    = \@field_list;
    $Qargs{-condition} = $condition;
    $Qargs{-group}     = $group;
    $Qargs{-order}     = $order_by;
    $Qargs{-distinct}  = $distinct;
    $Qargs{-limit}     = $limit;
    $Qargs{-date_format} => 'SQL';

    return %Qargs;    ## ( $tables, \@field_list, $condition, $group, $order_by, $limit, $distinct );

}

###############################
# Use method in view instead...
#
###############################
sub display_query_results2 {
###############################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $results   = $args{-search_results};    ## output from get_search_results()
    my $timestamp = $args{-timestamp};
    my $footer    = $args{-footer};
    my $limit     = $args{-limit};

    my %output_label        = %{ $self->{config}{output_labels} } if $self->{config}{output_labels};
    my %hash_display_params = %{ $self->{hash_display} }          if $self->{hash_display};

    # display only what is in results
    my $keys = $hash_display_params{ -keys };
    my @new_keys;

    if ( $keys && ref $keys eq 'ARRAY' ) {
        @new_keys = grep exists $results->{$_}, @$keys;
    }
    my $key_field;
    my @key_field_values = ();
    if ( $self->{config}{key_field} ) {
        $key_field = $self->{config}{key_field};
        if ( defined $results->{$key_field} ) {
            @key_field_values = @{ $results->{$key_field} };
        }
    }

    if ( defined $self->{config}{output_function} ) {
        my @output_function_order = ();
        foreach my $output_field ( keys %{ $self->{config}{output_function} } ) {
            my $function      = $self->{config}{output_function}{$output_field};
            my $output_values = eval "$function";
            $results->{$output_field} = $output_values;
            push @output_function_order, $output_field;
        }
        if ( defined $self->{config}{output_function_order} ) {
            @output_function_order = @{ $self->{config}{output_function_order} };
        }
        push @new_keys, @output_function_order;
    }

    my $page;

    $hash_display_params{ -keys } = \@new_keys;
    my ($count_key) = keys %$results;
    my $count = int( @{ $results->{$count_key} } );
    if ( $limit == $count ) { $page = $self->{dbc}->warning( "Results LIMITED to $limit records - reset limit if required", -hide => 1 ) }

    my $title = $self->{config}{title};

    my $graph_type = param('Graph_Type') || $hash_display_params{-graph};

    if ( $graph_type && $graph_type !~ /^No/i ) {
        if ( $graph_type =~ /^(1|graph)/ ) { $graph_type = 'Column' }

        my $Chart = new GGraph();
        my @order = param('Picked_Options');
        $Chart->parse_output_parameters( -order => \@order );

        $page .= $Chart->google_chart( -name => 'viewChart', -data => $results, -type => $graph_type );
    }
    else {
        $page .= SDB::HTML->display_hash(
            -dbc       => $self->{dbc},
            -hash      => $results,
            -title     => $title,
            -timestamp => $timestamp,
            %hash_display_params,
            -return_html => 1,
            -excel_link  => $title,
            -csv_link    => $title,
            -print_link  => $title,
            -footer      => $footer
        );
    }

    return $page;
}

1;

