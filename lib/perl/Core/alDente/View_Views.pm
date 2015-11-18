##################################################################################################################################
# alDente::View_Views.pm
#
#
#
#
###################################################################################################################################
package alDente::View_Views;

use base LampLite::Views;
use strict;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;

use SDB::Progress;

use LampLite::CGI;

my $q = new LampLite::CGI;

#################################
sub display_available_views {
################################
    # Method     : display_available_views()
    # Usage      : $html_form . = $self->display_available_views(-views=>\@views);
    # Purpose    : Display available views (add the display to an html form)
    # Returns    : html form
    # Parameters : -input    : list of views to display
    # Throws     : no exceptions
################################
    my $self = shift;
    my %args      = filter_input( \@_ );
    my $open      = $args{ -open } || [ 'Public', 'Internal', 'Group' ];
    my $labels    = $args{-labels};
    my $tab_width = $args{-tab_width} || 100;
    my $print     = $args{ -print } || 0;
    my $object    = $args{-object};
    my $source    = $args{-source};
    my $views     = $args{-views};

    my %open_option;

    foreach my $view (@$open) {
        $open_option{$view} = 1;
    }

    my $form;

    my $count = 0;
    if ($views) { $count = int(@$views) }

    my $Progress;
    my $monitor = ( $count && grep /Other/, @$views );    ## only monitor progress if loading all ('Other') views ##
    if ($monitor) { $Progress = new SDB::Progress( -title => "Loading Views" ) }

    my $done = 0;
    foreach my $view (@$views) {
        my %view_layer;
        my $title = "$view Views";
        $title = $labels->{$view} if $labels->{$view};

        my $default_open = '';
        $default_open = $title if $open_option{$view};

        my $views = $object->get_view_table( -source => $source, -context => $view );
        
        if (!$views) { next }
        
        $view_layer{$title} = $views;
        
        $form .= create_tree(
            -tree         => \%view_layer,
            -tab_width    => $tab_width,
            -default_open => $default_open,
            -print        => $print
        );
        $done++;
        my $completion = int( 100 * $done / $count );
        if ($monitor) { $Progress->update( $completion, $view ) }
    }

    return $form;
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
    my %args = filter_input(\@_);
    my $scope = $args{-scope};
    my $source = $args{-source};
    my $open_view = $args{-open_view};
    my $empty = $args{-empty};
    my $dept = $args{-department};
    my $sections = $args{-sections};
    my $dbc = $args{-dbc} || $self->dbc();

    my @views = qw(Public Internal Group Employee);                                                                  ## default EXCLUDES Other (to save on load time)
    if ($sections) { @views = Cast_List( -list => $sections, -to => 'array' ) }

    ## if the runmode returns to itself, it means that a save button was pressed and since there is no view being displayed this cannot be
    if ($empty) { $dbc->message('You Cannot save a view when there are no parameters, select a view then save it') }

    my $form = alDente::Form::start_alDente_form( $dbc, "View", $dbc->homelink() );
   
    my $view = alDente::View->new(-scope => $scope, -dbc => $dbc );

    $form .= $self->display_available_views(
        -object => $view,
        -source => $source,
        -views  => \@views,
    );

    if ( !grep /Other/, @views ) { $form .= Link_To( $dbc->config('homelink'), 'All Views (including other Departments)', '&cgi_application=alDente::View_App&Sections=Public,Group,Employee,Other' ) }

    $form .= $q->hidden( -name => "cgi_application",      -value => $source,                    -force => 1 );
    $form .= $q->hidden( -name => "rm",                   -value => "Default Page",             -force => 1 );
    $form .= $q->hidden( -name => "scope",                -value => $view->{config}{API_scope}, -force => 1 );
    $form .= $q->hidden( -name => "Source Call",          -value => $source,                    -force => 1 );
    $form .= $q->hidden( -name => "Empty Save Error",     -value => 1,                          -force => 1 );
    $form .= $q->hidden( -name => "filter_by_department", -value => $dept,            -force => 1 );
    $form .= $q->end_form();
    return $form;

}

#################################
sub return_View {
###########################
    # Method     : return_View()
    # Usage      : $self->return_View (-generate_results=>1)
    # Purpose    : Display the page with/without results depending on the parameters.
    #              Retrieve and display options
    #              -retrieve input/output options
    #              Retrieve and display search results
    #              -retrieve search results
    # Returns    : a form in html format
    # Parameters : -generate_results: 1/0
    # Throws     : no exceptions
###########################
    my $self             = shift;
    my %args             = filter_input( \@_ );
    my $generate_results = $args{-generate_results};                                                        ## indicate if to generate results
    my $view             = $args{-view};                                                                    ## object
    my $dbc              = $args{-dbc} || $self->dbc();
    my $source           = $args{-source};
    my $save             = $args{-save};
    my $delete           = $args{ -delete };
    my $title            = $args{-title};
    my $quiet            = $args{-quiet};
    my $filter_dpt       = $args{-filter_dept};
    my $brief            = $args{-brief};
    my $project          = $args{-project};
    my $regroup          = $args{-regroup};
    my $context          = $args{-context};                                                                 ## context of call to this method (used for logging to allow potential debugging of hanging queries)
    my $file_links = $args{-file_links};    ## file links of the result page. Valid options include 'excel', 'print', 'csv'. A combination of these options can be specified. If this is not specified, the default is print and excel links.
    my $validated;

    my $html_form;

    unless ($source) { $dbc->message('debuging return view') }

    ### retrieve input/output options in html format

    my $input  = $view->get_input_options( -return_html  => 1 );
    my $output = $view->get_output_options( -return_html => 1 );

    if ($regroup) {
        $dbc->message("Override Grouping for Graphs from @{$view->{config}{query_group}} to @$regroup");
        $view->{config}{query_group} = $regroup;
    }

    ### allow specific actions:
    $view->do_actions() if ( $view->{config} );

    $validated = $view->validate_mandatory_fields();

    ### add Edit View button
    if ( $dbc->Security->{login}->{LIMS_admin} ) {
        $html_form .= '<HR/>';
        $html_form .= $self->display_edit_view( -view => $view, -dbc => $dbc );
    }

    ### create html form
    $html_form .= alDente::Form::start_alDente_form( $dbc, "View", $dbc->homelink() );

    if ( $view->{config}{title} ) {
        my $link;
        if ( $view->{view} ) {
            my $bam = "&cgi_application=alDente::View_App&rm=Results&File=" . $view->{view};
            $link = &Link_To( $dbc->config('homelink'), $view->{config}{title}, $bam, $Settings{LINK_COLOUR} );
        }
        else {
            $link = $view->{config}{title};
        }
        $html_form .= Views::sub_Heading( $link, -1 );
    }

    ### add the input/output options and available views
    unless ($brief) {
        $html_form .= $self->display_options(
            -input            => $input,
            -output           => $output,
            -object           => $view,
            -generate_results => $generate_results,
            -source           => $source,
            -dbc              => $dbc,
            -validated        => $validated,
            -save             => $save,               #not neccesary
            -delete           => $delete,             #not neccesary
            -title            => $title,              #not neccesary
        );
    }
    $view->convert_output_functions();

    $dbc->Benchmark('io_options_ok');
    ### IF generate_results flag is set
    if ( $validated and $generate_results ) {

        my $start = timestamp();
        ### Generate the results

        ### Log usage of query ##

        my $start      = timestamp();
        my $slow_limit = 0;                            ## track any queries used that take more than a minute to load ##
        my $yml        = $view->{view} || 'unnamed';

        $self->log_usage( "$yml", -no_line_feed => 1, -quiet => 1, -context => $context );

        ## Retrieve Query Results ##
        
        my $result = $view->get_search_results( -quiet => $quiet );

        my $stop  = timestamp();
        my $delay = $stop - $start;

        my $append = "\tload_time: " . $delay;
        $self->log_usage( "$yml", -no_line_feed => 1, -append => $append, -quiet => 1, -context => $context );    ## log load time of filtered view usage ##

        if ( ( $stop - $start ) >= $slow_limit ) {
            ## log details of particularly slow view generation cases ##
            $self->log_usage( "$yml", $stop - $start . "\n" . $view->{SQL_Query}, -context => "$context.$start.slow" );
        }

        $dbc->Benchmark('got_results');
        $html_form .= '<HR/>';

        my $stop = timestamp();
        my $diff = $stop - $start;
        $view->{load_time} = $diff;
        $view->{generated} = date_time();

        ### display results
        my @keys = keys %{$result};
        if (@keys) {
            $html_form .= $self->display_search_results( -search_results => $result, -object => $view, -file_links => $file_links, -quiet => $quiet );
            $html_form .= '<HR/>';
        }
        else {
            $html_form .= $dbc->message(
                "No Results found - try adjusting search criteria\n\n"
                    . "If you are searching by typing a keyword here is some search options:\n"
                    . "* use wildcard (eg *ABC* or ABC0[1-5])\n"
                    . "* indicate numerical range for integers (eg < 25 or 55-62)\n"
                    . "* supply list of options separated by | (eg A|B|C)\n"
                    . "* supply range in square brackets (eg AB_[1-3]a to get AB_1a, AB_2a or AB_3a)\n\n"
                    . "If textarea is supplied for search box, user may also paste list of options on separate lines",
                -hide => 1
            );
        }

        my $stop = timestamp();
        my $diff = $stop - $start;

        $view->{load_time} = $diff;
        $view->{generated} = date_time();

        ### display summary
        $html_form .= $self->display_summary( -object => $view );

        ### get action table if necessary
        my %actions = $view->get_actions();
        $html_form .= '<HR/>';

        ### display action table
        $html_form .= $self->display_actions( -actions => \%actions, -object => $view );
    }
    $dbc->Benchmark('pre_display');
    $html_form .= '<HR/>';

    unless ($brief) {
        $html_form .= $self->display_available_views(
            -views => [ 'Public', 'Internal', 'Group', 'My', 'Employee' ],    ## go to other layers to see Other views if necessary ... , 'Other' ],
            -object => $view,
            -source => $source,
            -open   => []
        );
    }

    ### freeze self at the end and pass as frozen
    $dbc->Benchmark('pre_freeze');
    my $self_copy = $view;
    $html_form .= RGTools::RGIO::Safe_Freeze( -name => "Frozen_Config", -value => $self_copy, -format => 'hidden', -encode => 1, -exclude => [ 'API', 'dbc', 'connection', 'transaction' ] );
    $html_form .= $q->hidden( -name => "filter_by_department", -value => $filter_dpt, -force => 1 );
    $html_form .= $q->end_form();
    $dbc->Benchmark('post_freeze');

    if ( $dbc->Security->{login}->{LIMS_admin} ) {
        $html_form .= '<HR/>';
        $html_form .= $self->display_edit_view( -view => $view, -dbc => $dbc );
    }
    $dbc->Benchmark('post_display');

    return $html_form;
}

#################################
sub regenerate_view_btn {
#################################
    my $self = shift;
    return $q->submit(
        -name    => "Regenerate",
        -value   => "View with selected records",
        -class   => "Std",
        -onClick => "this.form.target='_blank';return true;",    ## un-comment if you want it to open in new page
        -force   => 1
    );
}

#################################
sub display_actions {
#################################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $actions = $args{-actions};
    my $object  = $args{-object};
    my $html;
    my $action_table = HTML_Table->new( -title => 'Actions' );

    if ( $actions && ( ref $actions ) =~ /HASH/ ) {
        foreach ( sort keys %$actions ) {
            $action_table->Set_Row( [ $actions->{$_} ] );
        }
    }

    if ( $object->{hash_display}->{-selectable_field} ) {
        $action_table->Set_Row( [ regenerate_view_btn($self) ] );

        ## pass the selectable field name to action buttons
        my $key_field = $object->{hash_display}->{-selectable_field};
        for my $alias ( values %{ $object->{config}{'output_params'} } ) {
            if ( $alias =~ /(.+) AS $key_field$/i ) {
                $key_field = $1;
            }
        }
        $html .= $q->hidden( -name => "MARK_FIELD", -value => $key_field, -force => 1 );
    }
    $html .= $action_table->Printout(0) if $action_table->{rows};

    return $html;
}

#################################
sub display_summary {
##########################
    # Method     : display_summary()
    # Usage      : $self->display_summary();
    # Purpose    : get the summary of the search result
    # Returns    : summary table
    # Parameters : none
    # Throws     : no exceptions
##########################
    my $self             = shift;
    my %args             = filter_input( \@_ );
    my $object           = $args{-object};
    my $key_field_values = $object->{result}{key_field_values};
    my $count            = 0;

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

#################################
sub display_search_results {
###########################
    # Method     : display_search_results()
    # Usage      : $self->display_search_results();
    # Purpose    :
    # Returns    :
    # Parameters :
    # Throws     : no exceptions
###########################
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $results       = $args{-search_results};               ## output from get_search_results()
    my $results_title = $args{-results_title} || "Results";
    my $quiet         = $args{-quiet};
    my $object        = $args{-object};
    my $file_links    = $args{-file_links};                   ## file links of the result page. Valid options include 'excel', 'print', 'csv'. A combination of these options can be specified. If this is not specified, the default is print and excel links.
    my $dbc           = $self->param('dbc');

    my %output_label = %{ $object->{config}{output_labels} } if $object->{config}{output_labels};
    my $limit        = $object->{config}{record_limit};
    my $api_type     = $object->{config}{API_type};
    my $key_field    = $object->{config}{key_field};

    $key_field =~ s/.*?AS(.*)/$1/ig;
    $key_field = chomp_edge_whitespace($key_field);

    my $output;
    my $result_table;
    my $num_records;

    if ( !$api_type ) {

        my $generated = convert_date( $object->{generated}, 'Simple' );
        my $load_time = $object->{load_time};
        my $footer;
        if ( defined $generated && defined $load_time ) { $footer = "[ Generated: $generated;  Load Time: $load_time s ]" }

        $result_table = $object->display_query_results( -dbc => $dbc, -object => $object, -search_results => $results, -return_html => 1, -timestamp => $self->{timestamp}, -file_links => $file_links, -limit => $limit, -footer => $footer );

        return $result_table;
    }
    else {
        unless ($key_field) {
            my @keys = keys %$results;
            $key_field = $keys[0];
            ## default to key on the first field returned (NOT preferable, but avoids crashing).
        }
        my $index = 0;
        $result_table = HTML_Table->new(
            -title    => $results_title,
            -autosort => 1,
            -class    => 'small',
            %{ $object->{hash_display}{param} },
        );

        ## Process the fields and inputs
        my @picked_output_options;
        if ( $object->{config}{output_order} && ref $object->{config}{output_order} eq 'ARRAY' ) {
            foreach my $option ( @{ $object->{config}{output_order} } ) {
                if ( $object->{config}{output_options}{$option}{picked} ) {
                    push( @picked_output_options, $option );
                }
            }
        }
        else {
            foreach my $option ( sort { $a cmp $b } keys %{ $object->{config}{output_options} } ) {
                if ( $object->{config}{output_options}{$option}{picked} ) {
                    push( @picked_output_options, $option );
                }
            }
        }

        my $form_name = $object->{config}{title};
        my @output_field_list;

        if ( $api_type =~ /data/i ) {

            # create a toggle checkbox to go with the key field
            my $toggle = $q->checkbox(
                -name    => 'Toggle',
                -label   => 'Select All',
                -onClick => "ToggleNamedCheckBoxes(document.View,'Toggle','$key_field');",
                -force   => 1
            );

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

            $result_table->Set_Headers( \@output_field_list, -space_words => $object->{hash_display}{param}{-space_words} );
            $result_table->Set_Row( \@sub_headers );

        }
        elsif ( $api_type =~ /summary/i || !$api_type ) {

            # add group by to picked_options
            my @group_by;
            if ( $object->{config}{group_by} && ref $object->{config}{group_by} eq 'HASH' ) {
                foreach my $item ( keys %{ $object->{config}{group_by} } ) {
                    if ( $object->{config}{group_by}{$item}{picked} ) {
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
                $result_table->Set_Headers( \@output_field_list, -space_words => $object->{hash_display}{param}{-space_words} );
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
                $result_table->Set_Headers( \@labels, -space_words => $object->{hash_display}{param}{-space_words} );
            }
        }

        # check if $self->{config}{output_value} exists. if yes, use the values as results
        my $result_set;
        if ( $object->{config}{output_value}{$key_field} && ( ref $object->{config}{output_value}{$key_field} ) =~ /ARRAY/ ) {
            $result_set = $object->{config}{output_value};
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
                if ( $object->{hash_display}{-highlight_column}{$output_field} ) {
                    push @{ $object->{hash_display}{-highlight_column}{$output_field}{$output_value}{rowcol} }, "$index,$column_count";
                }
                if ( $object->{config}{output_function}{$output_field} ) {

                    # overwrite result with function return
                    my $function = $object->{config}{output_function}{$output_field};
                    $output_value = $object->$function( -key_field_value => $key_field_value, -output_value => $output_value );
                }
                elsif ( $object->{config}{output_link}{$output_field} ) {
                    my $url = $object->{config}{output_link}{$output_field};
                    if ( $url =~ /<VALUE>/i ) {
                        $url =~ s/<VALUE>/$output_value/ig;
                    }

                    if ( $url =~ /<FUNCTION:(\S+)>/i ) {
                        my $function = $1;
                        my $replace = $object->$function( -key_field_value => $key_field_value );
                        $url =~ s/<FUNCTION:\S+>/$replace/ig;
                    }
                    $output_value = &Link_To( $dbc->config('homelink'), $output_value, $url, $Settings{LINK_COLOUR} );
                }
                if ( $output_field eq $key_field && $api_type =~ /data/i ) {
                    my $key_checkbox = $q->checkbox(
                        -name  => $key_field,
                        -value => $results->{$output_field}[$index],
                        -label => '',
                        -force => 1
                    ) . $output_value;
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

        foreach my $column ( keys %{ $object->{hash_display}{-highlight_column} } ) {
            foreach my $value ( keys %{ $object->{hash_display}{-highlight_column}{$column} } ) {
                my $colour = $object->{hash_display}{-highlight_column}{$column}{$value}{colour};
                my @coordinates = @{ $object->{hash_display}{-highlight_column}{$column}{$value}{rowcol} } if defined $object->{hash_display}{-highlight_column}{$column}{$value}{rowcol};

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
        $object->{result}{key_field_values} = \@key_field_values;

        my $stamp = int( rand(10000) );
        my ( $html_output, $csv_output, $xls_output );
        $html_output = $result_table->Printout("$URL_temp_dir/view_result.$stamp.html");

        $csv_output = $result_table->Printout("$URL_temp_dir/view_result.$stamp.csv");
        $xls_output = $result_table->Printout("$URL_temp_dir/view_result.$stamp.xls");

        if ( $num_records == $limit ) {
            $dbc->warning("Warning: output limited to $limit records (change limit to find all records or adjust filter options)");
            return $html_output . $csv_output . $xls_output . $result_table->Printout(0);    ## return table object
        }
        elsif ($num_records) {
            $dbc->message("Found $num_records records") unless $quiet;
            ### If any records have been found...
            return $html_output . $csv_output . $xls_output . $result_table->Printout(0);    ## return table object
        }
        else {
            $result_table->Set_Row( ['No Results'] );
            return $result_table->Printout(0);
        }
    }

}

#################################
sub display_options {
##########################
    # Method     : display_options()
    # Usage      : $html_form . = $self->display_options(-view => $view, -input=>$input, -output=>$output, -html_form=>$html_form);
    # Purpose    : Display io options (add the display to an html form)
    # Returns    : html form
    # Parameters : -input    : input table
    #              -output   : output table
    #              -html_form: html form to add the display to
    #				-object	: object
    # Throws     : no exceptions
    # Note:		 : most parameters passed to this object are not used here, they are just passed so they can be passed to the next run mode
##########################
    my $self             = shift;
    my %args             = filter_input( \@_ );
    my $dbc              = $args{-dbc} ;
    my $input            = $args{-input};
    my $output           = $args{-output};
    my $object           = $args{-object};
    my $generate_results = $args{-generate_results};
    my $source           = $args{-source};
    my $save             = $args{-save};
    my $delete           = $args{ -delete };
    my $regenerate       = $args{-regenrate};
    my $validated        = $args{-validated};
    my $title            = $args{-title};
    my $open;

    if ( !$validated ) {
        $open = 1;
    }
    elsif ($generate_results) {
        $open = 0;
    }
    else {
        $open = defined $object->{config}{show_io_options} ? $object->{config}{show_io_options} : 1;
    }
    my $form;
    $form .= $self->description( -object => $object );
    $form .= $self->buttons();

    # display available input/output
    $form .= $self->display_io_options(
        -input_options  => $input,
        -output_options => $output,
        -object         => $object,
        -open           => $open
    );
    $form .= "<br/>";

    ## Display a GO button
    $form .= $self->display_custom_cached_links( -object => $object );

    $form .= $q->hidden( -name => "cgi_application", -value => $source,                      -force => 1 );
#    $form .= $q->hidden( -name => "rm",              -value => "Results",                    -force => 1 );
    $form .= $q->hidden( -name => "scope",           -value => $object->{config}{API_scope}, -force => 1 );
    $form .= $q->hidden( -name => "Delete_This_View", -value => $delete );
    $form .= $q->hidden( -name => "Regenerate View",  -value => $regenerate );

    return $form;
}

#################################
sub display_custom_cached_links {
################################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $object = $args{-object};

    my $cached_links_table;
    my $cached_links = $object->get_custom_cached_links();
    my @cached_links;

    if ( defined $cached_links ) {
        @cached_links = @{$cached_links};

        my $cached_links_table = HTML_Table->new( -title => 'Custom Links' );
        $cached_links_table->Toggle_Colour('off');

        my @links = $object->get_saved_views_links( -saved_view_list => \@cached_links );
        foreach my $link (@links) {
            $cached_links_table->Set_Row( [$link] );
        }
        return $cached_links_table->Printout(0);
    }
    return;
}

#################################
sub description {
#################################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $brief  = $args{-brief};
    my $object = $args{-object};
    my $colour = '#cccccc';

    my $description .= $object->{config}{view_description};
    unless ($description) {return}

    my $open_wrapper  = "<Table cellspacing=0 cellpadding=2 border=1><TR><TD bgcolor='$colour' nowrap>";
    my $close_wrapper = "</TD></TR></Table>";

    my $form .= lbr() . $open_wrapper . vspace() . hspace(5) . $description . hspace(5) . vspace() . vspace() . $close_wrapper;
    return $form;
}

#################################
sub buttons {
#################################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $brief = $args{-brief};
    my $buttons .= lbr();
    unless ($brief) {
        $buttons .= "Max Number of Results" 
            . hspace(5)
            . $q->textfield(
            -name => "Result_Limit",
            -size => 10
            ) . hspace(5);
    }
    $buttons .= $q->submit(
        -name => 'rm',
        -command_name => 'Generate Results',
        -value        => 'Generate Results',
        -onClick      => "select_all_options('Picked_Options'); return;",
        -class        => 'Search',
        -force        => 1
    ) . hspace(5);

    $buttons .= $q->reset( -name => 'Reset Form', -class => "Std" ) . vspace() . vspace(2);
    return $buttons;
}

#################################
sub display_io_options {
#################################
    # Method     : display_io_options()
    # Usage      : $html_form . = $self->display_io_options(-input=>$input, -output=>$output);
    # Purpose    : Display io options (add the display to an html form)
    # Returns    : html form
    # Parameters : -input    : input table
    #              -output   : output table
    #				-object	:	object
    # Throws     : no exceptions
#################################
    my $self           = shift;
    my %args           = filter_input( \@_ );
    my $open           = $args{ -open };
    my $input_title    = $args{-input_title} || "Configure Input Options";
    my $output_title   = $args{-output_title} || "Configure Output Options";
    my $tab_width      = $args{-tab_width} || 100;
    my $direction      = $args{-direction} || 'horizontal';
    my $print          = $args{ -print } || 0;
    my $object         = $args{-object};
    my $input_options  = $args{-input_options} || $object->get_input_options( -return_html => 1 );
    my $output_options = $args{-output_options} || $object->get_output_options( -return_html => 1 );

    my $open_option;
    if ($open) {
        $open_option = $input_title . "," . $output_title;
    }
    else {
        $open_option = "";
    }
    my %view_layer;
    $view_layer{$input_title} = $input_options . $self->buttons( -brief => 1 );
    $view_layer{$output_title} = $output_options;

    return create_tree(
        -tree         => \%view_layer,
        -tab_width    => $tab_width,
        -default_open => $open_option,
        -print        => $print,
        -dir          => $direction
    );

}

#############################
sub display_query_results {
###############################
    my $self                = shift;
    my %args                = filter_input( \@_ );
    my $results             = $args{-search_results};                                                      ## output from get_search_results()
    my $dbc                 = $args{-dbc};
    my $object              = $args{-object};
    my $timestamp           = $args{-timestamp} || $self->{timestamp};
    my $limit               = $args{-limit};
    my %output_label        = %{ $object->{config}{output_labels} } if $object->{config}{output_labels};
    my %hash_display_params = %{ $object->{hash_display} } if $object->{hash_display};

    # display only what is in results
    my $keys = $hash_display_params{ -keys };
    my @new_keys;

    if ( $keys && ref $keys eq 'ARRAY' ) {
        @new_keys = grep exists $results->{$_}, @$keys;
    }
    my $key_field;
    my @key_field_values = ();
    if ( $object->{config}{key_field} ) {
        $key_field        = $object->{config}{key_field};
        @key_field_values = @{ $results->{$key_field} };
    }

    if ( defined $object->{config}{output_function} ) {
        my @output_function_order = ();
        foreach my $output_field ( keys %{ $object->{config}{output_function} } ) {
            my $function      = $object->{config}{output_function}{$output_field};
            my $output_values = eval "$function";
            $results->{$output_field} = $output_values;
            push @output_function_order, $output_field;
        }
        if ( defined $object->{config}{output_function_order} ) {
            @output_function_order = @{ $object->{config}{output_function_order} };
        }
        push @new_keys, @output_function_order;
    }

    $hash_display_params{ -keys } = \@new_keys;

    my $page;
    my ($count_key) = keys %$results;
    my $count = int( @{ $results->{$count_key} } );
    if ( $limit == $count ) { $page = $self->{dbc}->warning( "Results LIMITED to $limit records - reset Limit if required", -hide => 1 ) }

    my $title     = $object->{config}{title};
    my $generated = $object->{generated};
    my $load_time = $object->{load_time};
    my $footer;

    if ( defined $generated && defined $load_time ) { $footer = "Generated: $generated;  Load Time: $load_time" }

    $page .= SDB::HTML->display_hash(
        -dbc       => $dbc,
        -hash      => $results,
        -title     => $title,
        -timestamp => $timestamp,
        %hash_display_params,
        -return_html => 1,
        -excel_link  => $title,
        -print_link  => $title,
        -footer      => $footer
    );

    return $page;
}

#################################
sub display_edit_view {
#################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $view = $args{-view};

    my $generator_form .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Query Generator Form" );
    ### freeze self at the end and pass as frozen
    my $view_copy = Clone::clone($view);

    $generator_form .= RGTools::RGIO::Safe_Freeze( -name => "Frozen_Config", -value => $view_copy, -format => 'hidden', -encode => 1, -exclude => [ 'API', 'dbc', 'connection', 'transaction' ] );
    $generator_form .= $q->hidden( -name => 'Class', -value => 'View_Generator' );
    $generator_form .= $q->hidden( -name => 'cgi_application', -value => 'alDente::View_App', -force => 1 );
    $generator_form .= $q->submit( -name => 'rm', -value => 'Manage View', -class => 'Std', -force => 1 );
    $generator_form .= &hspace(5) . $q->submit( -name => 'rm', -value => 'Customize View', -class => 'Std', -force => 1 );
    $generator_form .= $q->hidden( -name => 'Referenced_View', -value => $view->{view} );
    $generator_form .= $q->end_form();

    return $generator_form;
}
1;
