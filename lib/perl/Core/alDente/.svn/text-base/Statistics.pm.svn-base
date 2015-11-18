package alDente::Statistics;

@ISA = qw(alDente::View);

use strict;

use CGI qw(:standard);
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Views;
use alDente::Tools;
use alDente::View;

use vars qw(%Benchmark $Connection);

# Constructor for Statistics page
#
#########
sub new {
#########
    my $this  = shift;
    my $class = ref($this) || $this;
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $type  = $args{-type};

    my $self = {};
    $self         = alDente::View->new();
    $self->{type} = $type;
    $self->{dbc}  = $dbc;

    bless $self, $class;
    return $self;
}

# Preset the run types available (for the run type filter)
#
#####################
sub preset_run_types {
#####################
    my $self = shift;
    my %args = filter_input( \@_, -args => "run_types" );

    my $run_types = $args{-run_types};

    $self->{run_type} = $run_types;
    return 1;
}

##############
sub home_page {
##############
    my $self         = shift;
    my %args         = filter_input( \@_ );
    my $display_page = $args{-display_page};
    my $dbc          = $self->{dbc};

    my $output;

    ## Check the stat type
    if ( $self->{type} eq 'Run' ) {
        ## Run Statistics
        $output .= alDente::Form::start_alDente_form( $dbc, );
        $output .= Views::Heading('Project Statistics');
        $output .= $self->project_statistics_options();
        my %args = $self->parse_project_statistics();

        ## Display the conditions that the statistics are based on
        my $display_conditions = $self->display_conditions_for_stats(%args);
        $output .= lbr() . lbr();
        $output .= $display_conditions->Printout(0);
        $output .= lbr() . lbr();                      ## Get the results
        my $results = $self->calculate_statistics(%args);

        ## Display the results;
        $output .= $self->display_statistics( -statistics => $results, -field_total => 'runs' );

        #	$output .= end_form();
    }
    if ($display_page) {
        print $output;

    }
    else {
        return $output;
    }
}
#############################
sub parse_project_statistics {
#############################
    my $self = shift;
    my %args;
    if ( $self->{type} eq 'Run' ) {
        %args = $self->_get_input_args();
        my @group_by = param('Group_By');
        my $group_by = Cast_List( -list => \@group_by, -to => "String" );
        $args{-group_by} = $group_by;
    }
    return %args;
}

#
#
#
#
#########################
sub calculate_statistics {
#########################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $run_types = $args{-run_type};
    my @run_types = Cast_List( -list => $run_types, -to => "Array" );

    ## Remove run type from the argument;

    delete $args{-run_type};

    my %statistics = ();
    if ( $self->{type} eq 'Run' ) {
        ## calculate statistics for each type of run
        foreach my $run_type (@run_types) {
            ## remove extra quotes
            $run_type =~ s/\'//g;
            if ( $run_type =~ /sequence/i ) {
                $run_type = 'Run';
            }
            ### Determine which method to call!
            my $scope = "get_" . lc($run_type) . "_data";
            my $results;

            ## break down gene chip runs into Mapping and Expression types
            if ( $run_type eq 'GenechipRun' ) {
                $args{-analysis_type} = "Expression";

                #		$args{-fields} = "runs,library,analysis_type,branch_code,nature";
                $args{-fields} = "runs,library,analysis_type,branch_code";

                #$input_joins->{'Source'} = 'Library_Source.FK_Source__ID = Source.Source_ID';
                #$input_joins->{'Library_Source'} = 'Library_Source.FK_Library__Name = Library.Library_Name';
                $args{-field_total} = "runs";

                #$args{-input_joins} = $input_joins;

                $results = $self->{API}->$scope(%args);

                $statistics{"Expression"} = $results;

                $args{-analysis_type} = "Mapping";

                $results = $self->{API}->$scope(%args);

                $statistics{"Mapping"} = $results;
            }
            ### Call the API method to retrieve the results
            else {
                $results = $self->{API}->$scope(%args);

                $statistics{$run_type} = $results;
            }
        }
    }

    return \%statistics;
}

#################################
sub display_conditions_for_stats {
#################################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $conditions_table = HTML_Table->new( -title => "Statistics generated based on:", -class => 'small' );

    $conditions_table->Set_Headers( [ "Condition", "Filter Based on" ] );
    foreach my $filter ( sort keys %args ) {
        $conditions_table->Set_Row( [ $filter, $args{$filter} ] );
    }

    return $conditions_table;
}

########################
sub display_statistics {
########################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $statistics  = $args{-statistics};
    my $field_total = $args{-field_total};
    my @field_total = Cast_List( -list => $field_total, -to => "Array" );

    my $output;

    foreach my $key ( keys %$statistics ) {
        my $statistics_table = HTML_Table->new( -title => "$key Summary Statistics", -class => 'small' );
        my %data = %{ $statistics->{$key} };

        #print HTML_Dump \%data;
        my $index;
        my @headers = keys %data;
        $statistics_table->Set_Headers( \@headers );
        my %calculated_total = ();

        while ( defined $data{'runs'}[$index] ) {
            my @row;
            foreach my $key ( keys %data ) {
                if ( grep /^\Q$key\E$/, @field_total ) {
                    $calculated_total{$key} = $calculated_total{$key} + $data{$key}[$index];
                }
                push( @row, $data{$key}[$index] );
            }
            $statistics_table->Set_Row( \@row );
            $index++;
        }
        foreach my $key ( keys %calculated_total ) {
            $statistics_table->Set_Row( [ "$key total:", $calculated_total{$key} ] );
        }
        my $stamp = int( rand(10000) );
        $output .= $statistics_table->Printout("$URL_temp_dir/view_result$stamp.html");
        $output .= $statistics_table->Printout("$URL_temp_dir/view_result$stamp.xlsx");
        $output .= $statistics_table->Printout(0);
        $output .= lbr();
    }

    return $output;
}
########################
#

################################
sub preset_input_fields {
################################
    my $self          = shift;
    my $preset_inputs = {
        'Library.FK_Project__ID' => { argument => '-project_id' },
        'Run.Run_Type'           => { argument => '-run_type' },
        'Run.Run_Status'         => { argument => '-run_status', default => 'Analyzed' },
        'Run.Run_Validation'     => { argument => '-run_validation', default => 'Approved' },
        'Run.Run_DateTime'       => { argument => '' },
        'Run.Billable'           => { argument => '-billable', default => 'Yes' }
    };
    my @order = qw(
        Library.FK_Project__ID
        Run.Run_Type
        Run.Run_DateTime
        Run.Run_Status
        Run.Run_Validation
        Run.Billable
    );

    $self->configure_input_fields( -fields => $preset_inputs, -order => \@order );
    return 1;
}

###########################
sub project_statistics_options {
###########################
    my $self        = shift;
    my %args        = filter_input( \@_, -args => "" );
    my $add_filters = $args{-add_filters};                ## add run specific filters

    $self->preset_input_fields();

    my $input_options = $self->get_available_input_list();

    my $output;
    ## Add group by;
    my $breakdown = checkbox_group( -name => 'Group_By', -values => [ 'Project', 'library', 'month' ], -default => 'Library' );
    $input_options->Set_Row( [ "Breakdown", $breakdown ] );
    $output .= $input_options->Printout(0);
    $output .= submit( -name => "Project_Statistics", -value => "Generate Project Statistics", -style => "background-color:$Settings{STD_BUTTON_COLOUR}" );

    return $output;
}

return 1;
