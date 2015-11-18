##############################
# perl_interpreter #
##############################
#####################################################
# Sequencing_Data.pm
#
# This modules provides various status feedback for the Sequencing Database
#
######################################################
######################################################
# $Id: Sequencing_Data.pm,v 1.33 2004/10/18 18:58:18 rguin Exp $
######################################################
# CVS Revision: $Revision: 1.33 $
# CVS Date:     $Date: 2004/10/18 18:58:18 $
######################################################
package Sequencing::Sequencing_Data;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Sequencing_Data.pm - perl_interpreter #

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
perl_interpreter #<BR>This modules provides various status feedback for the Sequencing Database<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    get_custom_data
    get_Histogram
    show_Project_info
    show_Project_libraries
);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use File::stat;
use Statistics::Descriptive;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use SDB::DB_Object;
use SDB::DBIO;
use alDente::Validation;
use SDB::Data_Viewer;
use SDB::CustomSettings;

use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;
use RGTools::Conversion;

use alDente::Data_Images;

##############################
# global_vars                #
##############################
use vars qw(%Settings %Benchmark $html_header);
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

#########
sub new {
#########
    #
    # Constructor
    #
    my $this = shift;
    my %args = @_;

    my $dbc   = $args{-dbc} || $Connection;            # Database handle
    my $id    = $args{-id};
    my $table = $args{-table} || 'SequenceAnalysis';

    my $attributes = $args{-attributes};               ## allow inclusion of attributes for new record

    my $frozen  = $args{-frozen}  || 0;
    my $encoded = $args{-encoded} || 0;                ## reference to encoded object (frozen)

    my ($class) = ref($this) || $this;
    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => $table, -frozen => $frozen, -encoded => $encoded );
    $self->primary_value($id);

    if ( $encoded || $frozen ) { return $self }

    bless $self, $class;

    $self->{dbc}    = $dbc;
    $self->{table}  = $table;
    $self->{run_id} = $id;

    return $self;
}

##############################
# public_methods             #
##############################
################
#
# <CONSTRUCTION>
# Simplify stat generation by loading run info based upon user-specified elements to include
#
################
sub load_RunData {
################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $run_ref   = $args{-runs};           ## arrayref to list of run_ids.
    my $field_ref = $args{-fields} || '';

}

###########################################################
# Get data for sequencing runs based on flexible specifications
# - special identification of data that should be displayed as histogram or as averages included
# - do NOT choose the same fields for more than one group.  (summations may take place twice)
#
#########################
sub get_custom_data {
#########################
    my $self          = shift;
    my %args          = @_;
    my $dbc           = $args{-dbc} || $self->{dbc} || $Connection;
    my @tables        = @{ $args{-tables} } if $args{-tables};
    my $condition     = $args{-condition} || 1;
    my $run_condition = $args{-run_condition} || 1;
    my $title         = $args{-title} || 'Custom Query results';
    my $project_id    = $args{-project_id} || 0;
    if ($project_id) { $run_condition .= " AND FK_Project__ID in ($project_id)" }
    my $run_ids = $args{-run_ids} || 0;

    my @average_fields = @{ $args{-average} } if $args{-average};
    my @sum_fields     = @{ $args{-sum} }     if $args{-sum};
    my @hist_fields    = @{ $args{-hist} }    if $args{-hist};
    my @dist_fields    = @{ $args{-dist} }    if $args{-dist};
    my @show_fields    = @{ $args{-show} }    if $args{-show};
    my $threshold = $args{-threshold};               #### check for runs that are marked as good (Q20 >= threshold) ###
    my $trends = $args{-trends} || $args{-trend};    #### monitor a trend in one piece of data over each record..

    my $remove_zero = $args{-remove_zero} || 0;      #### check for runs that are marked as good (Q20 >= threshold) ###

    my $denominator_field = $args{-denominator};
    my $denominator_label = $args{-denominator_name} || $denominator_field;

    my $label_field = $args{-group_by};
    my $group_label = $args{-group_name} || $label_field;

    my $count_label = $args{-count_name} || 'Count';

    my $parent_format = $args{-parent_format};

    my $timestamp = timestamp();

    unless ( $self->{dbc}->ping() ) { print "No database handle supplied to get_custom_data"; return; }

    my $group_by = ($label_field);
    my $order_by = $args{-order_by} || $label_field;

    my $parents;
    if ($parent_format) {
        $parents = join ',', $dbc->Table_find( 'Plate,Plate_Format', 'Plate_ID', "WHERE FK_Plate_Format__ID=Plate_Format_ID and Plate_Format_Type like '$parent_format%'" );
        if ( $parents =~ /[1-9]/ ) {
            $run_ids = join ',', $dbc->Table_find( 'Plate,Run,Library', 'Run_ID', "WHERE Run.FK_Plate__ID=Plate_ID AND Plate.FK_Library__Name =Library_Name AND FKParent_Plate__ID in ($parents) AND $run_condition" );
        }
    }

    if ($parents) { print "<P>Parents:" . int( my @list = split ',', $parents ) . "<BR>"; }
    if ($run_ids) { print "Runs: " . int( my @list      = split ',', $run_ids ) . "<BR>"; }

    if ($parent_format) {
        $condition .= " AND FK_Run__ID in ($run_ids)";
        $title     .= " (with $parent_format parent Plates)";
    }
    else {
        $condition .= " AND $run_condition";
    }

    my @all_fields = @show_fields;
    if ($count_label) {
        push( @all_fields, "count(*) as $count_label" );
    }
    foreach my $field (@sum_fields) {
        my $thisfield = "Sum($field) as Total_$field";
        unless ( grep /^$thisfield$/, @all_fields ) {
            push( @all_fields, $thisfield );
        }
    }
    foreach my $field (@average_fields) {
        my $thisfield = "Sum($field) as Average_$field";
        unless ( grep /^$thisfield$/, @all_fields ) {
            push( @all_fields, $thisfield );
        }
    }
    foreach my $field (@hist_fields) {
        unless ( grep /^$field$/, @all_fields ) {
            push( @all_fields, $field );
        }
    }
    push( @all_fields, "Sum($denominator_field) as Denominator" );
    push( @all_fields, "$label_field as Label" );

    my $RunData = SDB::DB_Object->new( -dbc => $dbc, -tables => 'SequenceAnalysis' );
    $RunData->add_tables( \@tables );
    my $results = $RunData->load_Object(
        -fields    => \@all_fields,
        -condition => $condition,
        -group_by  => ['FK_Run__ID'],
        -order_by  => [$order_by]
    );

    print "Found $results Runs<BR>";

    my %values = %{ $RunData->values( -fields => \@all_fields, -multiple => 1 ) };
    my @keys = keys %values;

    my @counts = @{ $values{Denominator} };
    my @labels = @{ $values{Label} };

    my %Count;
    my %Average_Over;
    foreach my $index ( 0 .. $#counts ) {
        $Average_Over{ $labels[$index] } += $counts[$index];
        $Count{ $labels[$index] }++;
    }

    my @unique_fields;
    my @unique_labels;

    my $hist = 1;    ## counter for each histogram file..
    my %Sum;
    my %Hist;
    my %Results;
    foreach my $key (@all_fields) {
        my $field = $key;
        if ( $key =~ /(.+) as (.+)/i ) {
            $field = $2;
        }
        if ( $field eq $label_field ) {next}

        my @field_values = @{ $values{$field} };

        $field =~ s/Total_//;
        $field =~ s/Average_//;
        if ( ( grep /^$field$/, @average_fields ) || ( grep /^$field$/, @sum_fields ) ) {

            #	    $field =~s/total//;
            my $index = 0;
            foreach my $index ( 0 .. $#field_values ) {
                $Sum{$field}->{ $labels[$index] } += $field_values[$index];

                #	 	print "($field of $key) : $labels[$index] += $field_values[$index]<BR>";
            }
        }
        if ( ( grep /^$field$/, @hist_fields ) || ( grep /^$field$/, @dist_fields ) ) {

            #	    $field =~s/total//;
            my $index = 0;
            foreach my $index ( 0 .. $#field_values ) {
                $Hist{$field}->{ $labels[$index] } .= $field_values[$index];
                my $length1 = int( unpack 'S*', $field_values[$index] );
                my $length2 = int( unpack 'S*', $Hist{$field}->{ $labels[$index] } );
            }
        }
        ### constant fields...

        unless ( $Results{$field} ) { push( @unique_fields, $field ); }

        $Results{$field} = {};
        foreach my $index ( 0 .. $#field_values ) {
            unless ( grep /^$labels[$index]$/, @unique_labels ) {
                push( @unique_labels, $labels[$index] );
            }
            $Results{$field}->{ $labels[$index] } = $field_values[$index];
        }
    }

    ### generate list of headers ###
    my @headers;
    foreach my $field (@unique_fields) {
        if ( grep /\b$field$/, @show_fields ) {
            push( @headers, $field );
        }
        if ( grep /^$field$/, @average_fields ) {
            my $thisfield = $field;
            $thisfield =~ s/total//;
            push( @headers, "Average<BR>$thisfield" );
        }
        if ( ( grep /^$field$/, @sum_fields ) || ( grep /^$field$/, @average_fields ) ) {
            my $thisfield = $field;
            $thisfield =~ s/total//;
            push( @headers, "Total<BR>$thisfield" );
        }
        if ( grep /^$field$/, @hist_fields ) {
            push( @headers, "$field<BR>Histogram" );
            push( @headers, "$field<BR>Median" );
            push( @headers, "$field<BR>Mean (Std_Dev)" );
        }
    }

    my $Data = HTML_Table->new( -title => $title );

    $Data->Set_Border(1);
    $Data->Set_Headers( [ $group_label, $count_label, $denominator_label, @headers ] );

    ### extract data from hashes ###
    my %Trend;
    my %Graph_Trend;
    my @trend_data;
    my @total_data = ();
    foreach my $key (@unique_labels) {
        my $column       = 0;
        my $count        = $Count{$key};
        my $average_over = $Average_Over{$key};
        my @data         = ( "<B>$key</B>", "<B>$count</B>", "<B>$average_over</B>" );
        $total_data[ $column++ ] += $count;
        $total_data[ $column++ ] += $average_over;

        #	print "Key : $key<BR>**********<BR>";
        foreach my $field (@unique_fields) {
            my $value = $Results{$field}->{$key};
            my $sum   = $Sum{$field}->{$key};

            #	    prints "** $field : $value -> ($sum / $count)<BR>";
            if ( grep /\b$field$/, @show_fields ) {
                push( @data, "<B>$value</B>" );
                $Trend{$field} = $value;
            }
            if ( grep /^$field$/, @average_fields ) {
                my $avg_value = '(no data to avg)';
                if ( $sum && $average_over ) {
                    $avg_value = sprintf "%0.0f", $sum / $average_over;
                }
                push( @data, "<B>$avg_value</B>" );
                $Trend{ "Avg_" . $field } = $avg_value;
            }
            if ( ( grep /^$field$/, @sum_fields ) || ( grep /^$field$/, @average_fields ) ) {
                my $sum_value = '(no data to sum)';
                if ($sum) {
                    $sum_value = $sum;
                }
                push( @data, $sum_value );
                $Trend{ "Total_" . $field } = $sum_value;
            }
            if ( grep /^$field$/, @hist_fields ) {
                my $hist_value = '(no hist data)';
                my $mean       = 'n/a';
                my $median     = 'n/a';
                my $passed     = 0;
                my $N          = 0;

                if ( $Hist{$field}->{$key} ) {
                    my @array = unpack "S*", $Hist{$field}->{$key};
                    my %results = %{
                        get_Histogram(
                            -data        => \@array,
                            -type        => 'dist',
                            -title       => "CustomHist.$timestamp.$hist",
                            -threshold   => $threshold,
                            -remove_zero => $remove_zero
                        )
                        };

                    $passed     = $results{pass};
                    $N          = $results{N};
                    $mean       = sprintf "<B>%0.0f</B>(+/- %0.0f)", $results{mean}, $results{std_dev};
                    $median     = $results{median};
                    $hist_value = "<B>N=$results{N} ";
                    if ($threshold) {
                        if ( $results{N} ) {
                            my $pass_percentage = sprintf "%0.0f", $passed / $N * 100;
                            $hist_value .= "($passed ($pass_percentage %) >= $threshold)";
                        }
                    }
                    $hist_value .= "<BR>$results{img}";

                    $hist++;
                }
                push( @data, $hist_value );
                push( @data, "<Font color=red>$median</Font>" );
                push( @data, $mean );

                $Trend{pass}         = $passed;
                $Trend{reads}        = $N;
                $Trend{success_rate} = sprintf "%0.0f", $passed / $N * 100;
                $Trend{failure_rate} = sprintf "%0.0f", 100 - $Trend{success_rate};
                $Trend{median}       = $median;
                $Trend{mean}         = $mean;

            }
        }

        if ($trends) {
            foreach my $trend ( split ',', $trends ) {
                $Trend{$trend} ||= 0;
                push( @{ $Graph_Trend{$trend} }, $Trend{$trend} );
            }
        }

        $Data->Set_Row( \@data );
    }
    $Data->Set_Row( [ 'Totals:', @total_data ], 'mediumredbw' );

    ### Printout data ###
    print $Data->Printout( "$alDente::SDB_Defaults::URL_temp_dir/CustomQuery.$timestamp.html", $html_header );
    print $Data->Printout( "$alDente::SDB_Defaults::URL_temp_dir/CustomQuery.$timestamp.xlsx", $html_header );
    $Data->Printout();

    if ($trends) {
        print "<HR><h1>Trends:</h1>";
        foreach my $trend ( split ',', $trends ) {
            my %results = %{
                get_Histogram(
                    -data        => $Graph_Trend{$trend},
                    -type        => 'hist',
                    -title       => "Trend.$trend.$timestamp.$hist",
                    -threshold   => $threshold,
                    -remove_zero => $remove_zero
                )
                };
            my $img = $results{img};

            print "<h2>$trend</h2>";
            print "<BR>$img";
            print "<P>Data: " . join ',', @{ $Graph_Trend{$trend} };
            print "<HR>";
        }
    }

    return;
}

##############################
# public_functions           #
##############################

################
sub get_Histogram {
################
    my %args = @_;

    my $data        = $args{-data};
    my $type        = $args{-type};
    my $title       = $args{-title} || 'histogram';
    my $threshold   = $args{-threshold};
    my $remove_zero = $args{-remove_zero};
    my $path        = $args{-path};

    my @Dataset = @$data;

    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@Dataset);

    my $pass = 0;
    if ($threshold) {
        map {
            if ( $_ >= $threshold ) { $pass++ }
        } @Dataset;
    }

    my $median  = $stat->median();
    my $mean    = $stat->mean();
    my $std_dev = $stat->standard_deviation();
    my $pts     = int(@Dataset);

    my @Dist;
    if ( $type =~ /dist/i ) {
        my %Distribution = $stat->frequency_distribution( $stat->max() - $stat->min() + 1 );
        ### set all values to stat->max (distribution does not work in this case)
        if ( $stat->max() == $stat->min() ) {
            $Distribution{ int( $stat->max() ) } = int(@Dataset);
        }
        @Dist = @{ pad_Distribution( \%Distribution, -binsize => 10 ) };
    }

    my $img;
    if ( int(@Dist) ) {
        ( $img, my $zeros, my $max ) = &alDente::Data_Images::generate_run_hist(
            data        => \@Dist,
            filename    => $title,
            remove_zero => $remove_zero
        );
    }
    elsif ( int(@Dataset) ) {

        my @X_ticks  = ( 12, 24, 36 );
        my @X_labels = ( 12, 24, 36 );
        my @Y_ticks;
        my @Y_labels;
        my $data = $args{'data'};
        my @Bins;
        if ($data) { @Bins = @$data; }    ### add options for Project/Lib data retrieval ?

        my $binwidth = $args{'binwidth'} || 8;    ### width of bin in pixels...
        my $group   = Extract_Values( [ $args{'group'},   12 ] );    ### group N bins together by colour
        my $colours = Extract_Values( [ $args{'colours'}, 8 ] );     ### number of unique colours
        my $x_ticks  = $args{'x_ticks'}  || \@X_ticks;               ## (200,400,600];
        my $x_labels = $args{'x_labels'} || \@X_labels;              ## (200,400,600];
        my $xlabel   = $args{'xlabel'}   || 'Time (months)';

        my $y_ticks  = $args{'y_ticks'};
        my $y_labels = $args{'y_labels'};
        my $ylabel   = $args{'ylabel'} || '';
        my $height   = $args{'height'} || 200;
        my $width    = $args{'width'} || 180;
        my $stamp    = $args{'timestamp'} || '';

        my $yline = $args{'yline'} || 0;                             ### if a line should be drawn at a given y position.

        ( $img, my $zero, my $max ) = Generate_Histogram(
            path        => $path,
            data        => \@Dataset,
            filename    => $title,
            remove_zero => $remove_zero,
            binwidth    => $binwidth,
            group       => $group,
            Ncolours    => $colours,
            x_ticks     => $x_ticks,
            x_labels    => $x_labels,
            xlabel      => $xlabel,
            y_ticks     => $y_ticks,
            y_labels    => $y_labels,
            ylabel      => $ylabel,
            height      => $height,
            width       => $width,
            timestamp   => $stamp,
            yline       => $yline,
        );
        $img = "Max = $max<BR>$img";
    }
    else { $img = "(no data)" }

    my %returnval;
    $returnval{N}       = $pts;
    $returnval{median}  = $median;
    $returnval{mean}    = $mean;
    $returnval{std_dev} = $std_dev;
    $returnval{pass}    = $pass;
    $returnval{img}     = $img;
    return \%returnval;    #$pts,$median,$mean,$std_dev,$img,$pass);
}

##############################
sub show_Project_info {
##############################
    my %args = @_;

    my $dbc             = $args{-dbc} || $Connection;
    my $proj_ids        = $args{-project_id};
    my $project_name    = $args{-project_name};
    my $pipeline        = $args{-pipeline};
    my $show_stats      = $args{-stats} || 1;            ### show statistics
    my $title           = $args{-title} || '';
    my $extra_condition = $args{-condition} || 1;        ### condition should apply to Run table only...
    my $group_by        = $args{-group_by} || '';
    my $details         = $args{-details} || '';         ### show details for each project..
    my $order           = $args{-order_by} || 'Name';    ### order by name or date...
    my $days_ago        = $args{-days_ago} || 0;
    my $since           = $args{-since} || 0;
    my $until           = $args{ -until } || 0;
            my $project_totals     = $args{-project_totals}     || 0;
            my $accumulated_totals = $args{-accumulated_totals} || 1;
            my $include            = $args{-include}            || param('Include Runs');
    my $include_libraries = $args{-include_libraries} || 0;
    my $group_projects    = $args{-group_projects}    || param('Group Projects');
    my $include_summary   = $args{-include_summary}   || 0;
    my $lib_type          = $args{-lib_type};

    my $homelink = $dbc->homelink();

    my $stamp = $args{-timestamp} || RGTools::RGIO::timestamp();

    if ( $pipeline =~ /all/i ) { Message("All piplines included"); $pipeline = 0; }
    my $remove_zero = param('Remove Zeros') || $args{-remove_zeros};

    my $zeros = !$remove_zero;

    my $output = '';

    my $proj_list = $proj_ids;
    unless ($proj_list) { $proj_list = join ',', $dbc->Table_find( 'Project', 'Project_ID' ); }

    my $projects = join ',', $dbc->Table_find( 'Project', 'Project_Name', "WHERE Project_ID in ($proj_list)" );
    if ($title) { }
    elsif ( $proj_list =~ /,/ ) { $title = "Stats"; }              ## if more than one project displayed..
    else                        { $title = "$projects Stats"; }    ## if only one project show name in title

    my $order_by;
    if ( $order =~ /Date/i ) {
        $order_by = 'Library_Obtained_Date';
    }
    else {
        $order_by = 'Library_Name';
    }

    if ($include_libraries) { $include_libraries = $include }

    my $show_production = $include =~ /production/i;
    my $show_all_runs   = $include =~ /all|everything/i;
    my $show_billable   = $include =~ /billable/i;
    my $show_approved   = $include =~ /approved/i;
    my $show_techD      = $include =~ /techD/i;

    my $condition = " Run_Status='Analyzed'";    ### All Stats should exclude Failed runs...
    if ($pipeline) {
        $title .= "<BR>$pipeline Pipeline";
        my $pipeline_list = $dbc->get_FK_ID( 'FK_Pipeline__ID', $pipeline );
        if ($pipeline_list) {

            # Message("Filtering on Pipeline");
            my $daughter_pipelines = join ',', alDente::Pipeline::get_daughter_pipelines( -dbc => $dbc, -id => $pipeline_list, -include_self => 1 );
            $extra_condition .= " AND Plate.FK_Pipeline__ID IN ($daughter_pipelines)";
        }
    }

    if ($days_ago) {
        ( my $since ) = split ' ', &date_time( '-' . $days_ago . 'd' );    ### default to last month
        $extra_condition .= " AND Run_DateTime > '$since'";
    }

    if ($since) {
        $extra_condition .= " AND Run_DateTime >= '$since'";
        $title           .= "<BR> (Runs from $since";
    }
    if ($until) {
        $until = &end_of_day($until);
        $extra_condition .= " AND Run_DateTime <= '$until'";
        $title           .= " Until $until)";
    }

    if ($lib_type) {
        $lib_type = Cast_List( -list => $lib_type, -to => 'string', -autoquote => 1 );
        $extra_condition .= " AND (Vector_Based_Library_Type in ($lib_type) OR Library_Type in ($lib_type))";
    }

    ### Determine runs to include / exclude (eg. Test Runs, non-Billable Runs)
    if ( $show_billable || $show_techD ) {
        if ( $show_billable && $show_techD ) { $title .= "<BR>(Billable only - including TechD runs)"; }
        elsif ($show_billable) { $title .= "<BR>(Billable only - excluding TechD runs)"; }
        else                   { $title .= "<BR>(Billable TechD runs only)"; }
    }
    elsif ($show_production) {
        $title .= "<BR>(Test Runs Excluded)";
    }
    else {
        $title .= "<BR>(Test Runs and NON-Billable Runs Included)";
    }

    my $group_list;
    my $group_field = 'Project_Name';
    my @group;
    unless ($group_projects) { push( @group, "Project_Name" ) }
    if ( $group_by =~ /^library$/i ) {
        $group_field = "Library_Name";
    }
    elsif ( $group_by =~ /^month$/i ) {
        $group_field = "DATE_FORMAT(Run_DateTime,'%Y-%m')";
    }
    elsif ( $group_by =~ /^project$/i ) {
        $group_projects = 1;    ## to disable the project summary at the end of every project ##
    }
    elsif ( $group_by =~ /^library type$/i ) {
        $group_field = 'Vector_Based_Library_Type';
    }
    elsif ( $group_by =~ /^sow$/i ) {
        $group_field = 'Funding_Name';
    }
    else { $group_field = $group_by if $group_by; }

    push( @group, $group_field ) if $group_field;
    $group_list = join ',', @group;

    $extra_condition .= " AND Library.FK_Project__ID in ($proj_list)";
    $condition       .= " AND $extra_condition";
    my %Info = &Table_retrieve(
        $dbc,
        'Project,Library,Plate,Run LEFT JOIN Vector_Based_Library ON Vector_Based_Library.FK_Library__Name=Library_Name LEFT JOIN Work_Request ON Plate.FK_Work_Request__ID=Work_Request_ID LEFT JOIN Funding ON Work_Request.FK_Funding__ID=Funding_ID',
        [ 'Project_ID', 'Project_Name', 'Project_Description', 'Library_Name', "$group_field as Group_Label" ],
        "WHERE Plate.FK_Library__Name=Library_Name AND Run.FK_Plate__ID=Plate_ID AND FK_Project__ID=Project_ID AND $condition GROUP BY $group_list ORDER BY $group_list"
    );
    my %Accumulated         = {};
    my %Project_Accumulated = {};
    my $index               = 0;
    my $Stats;

    ##### First summarize Projects ######
    foreach my $Pid ( split ',', $proj_ids ) {
        my ($name) = $dbc->Table_find( 'Project', 'Project_Name',        "WHERE Project_ID = $Pid" );
        my ($desc) = $dbc->Table_find( 'Project', 'Project_Description', "WHERE Project_ID = $Pid" );
        my $projectlink = &Link_To( $homelink, $name, "&HomePage=Project&ID=$Pid", $Settings{LINK_COLOUR}, ['newwin'] );
        my $prefix = "<P><span class=small>" . "<B>Project</B>: " . $projectlink . '<BR>' . "<B>Description</B>: " . $desc . '<BR>' . "<B>Libraries</B>: ";
        $output .= $prefix;
        $output .= "<UL>";
        foreach my $lib_type ( get_enum_list( $dbc, 'Library', 'Library_Type' ) ) {
            my @libs = $dbc->Table_find( 'Library', 'Library_Name', "WHERE FK_Project__ID=$Pid AND Library_Type = '$lib_type' ORDER BY $order_by" );
            my $lib_list .= "<LI>$lib_type : " . &Link_To( $homelink, int(@libs), "&Show+Project+Libraries=1&Project_ID=$Pid&Library_Type=$lib_type", $Settings{LINK_COLOUR}, ['newwin'] );
            $lib_list .= &hspace(5) . "<- <i>(click here to view)</i>";
            $output .= $lib_list if @libs;
        }
        $output .= "</UL>";
        $output .= hr;
    }
    ######## Now get the data #################
    while ( defined $Info{Project_Name}[$index] ) {
        my $Pid   = $Info{Project_ID}[$index];
        my $name  = $Info{Project_Name}[$index];
        my $desc  = $Info{Project_Description}[$index];
        my $label = $Info{Group_Label}[$index];
        my $lib   = $Info{Library_Name}[$index];          ## Temp...
        my $Rid   = $Info{Run_ID}[$index];
        $index++;
        if ($group_projects) { $name = "Accumulated" }    ## Only label the final record as a total of all rows...
        my $highlight;
        my $colour;

        if ($show_stats) {
            ## show summaries for each Project as it comes up...
            my $group_condition = " AND $group_field = '$label'";    ## establish group condition for sequenced plates to include...
            $group_condition .= " AND FK_Project__ID = $Pid" unless $group_projects;    ##

            my @run_list = $dbc->Table_find(
                'Run,Plate,Library,Project LEFT JOIN Vector_Based_Library ON Vector_Based_Library.FK_Library__Name=Library_Name  LEFT JOIN Work_Request ON Plate.FK_Work_Request__ID=Work_Request_ID LEFT JOIN Funding ON Work_Request.FK_Funding__ID=Funding_ID',
                'Run_ID',
                "WHERE Plate.FK_Library__Name = Library_Name AND Run.FK_Plate__ID=Plate_ID AND Library.FK_Project__ID=Project_ID $group_condition AND $condition"
            );
            my $stats = &_run_list_statistics(
                -dbc        => $dbc,
                -runs       => \@run_list,
                -label      => $label,
                -table      => $Stats,
                -accumulate => \%Accumulated,
                -group      => $Pid,
                -include    => $include,
                -colour     => $colour
            );
            %Accumulated               = %{ $stats->{accumulated} }  if $stats->{accumulated};
            $Project_Accumulated{$Pid} = $stats->{accumulated}{$Pid} if $stats->{accumulated}{$Pid};
            $colour                    = $stats->{colour};
            $Stats                     = $stats->{table};
            ## continue with the next section ONLY if the next record is from a different project (or EOF) ##

            #	    print "$Pid <> $Info{Project_ID}[$index] && $group_projects ?";
            if ( !defined $Info{Project_ID}[$index] || ( ( $Pid != $Info{Project_ID}[$index] ) && !$group_projects ) ) {
                ### print out accumulated totals from _run_list_statistics
                #		print "Y1.<BR>";
                my @show;
                unless ( $group_projects || ( $proj_ids =~ /^\d+$/ ) ) { push( @show, $name ); }    ## unless grouping projects or only one project
                if ( !defined $Info{Project_ID}[$index] ) { push( @show, 'Accumulated' ); }
                foreach my $name (@show) {
                    my %Data;
                    my $colour = 'mediumgreenbw';
                    if ( $name eq 'Accumulated' ) {
                        ## display totals at the bottom ...
                        %Data   = %Accumulated;
                        $colour = 'mediumredbw';
                    }
                    else {
                        %Data = %{ $Project_Accumulated{$Pid} };
                    }

                    if ( defined $Data{Wells} ) {
                        if ($show_production) {
                            my $avgSL  = $Data{P_Wells} ? sprintf "%0.0f", number( $Data{P_SLtotal} / $Data{P_Wells} )  : "n/a";
                            my $avgQ20 = $Data{P_Wells} ? sprintf "%0.0f", number( $Data{P_Q20total} / $Data{P_Wells} ) : "n/a";
                            if ( $Data{P_count} || $zeros ) {
                                $Stats->Set_Row( [ "$name Totals (Production)", $Data{P_count}, $Data{P_AllReads}, number( $Data{P_AllBPs}, 0, '<BR>' ), $Data{P_Wells}, $avgSL, $avgQ20, number( $Data{P_Q20total}, 0, '<BR>' ) ], $colour );
                            }
                        }
                        if ($show_billable) {
                            my $avgSL  = $Data{B_Wells} ? sprintf "%0.0f", number( $Data{B_SLtotal} / $Data{B_Wells} )  : "n/a";
                            my $avgQ20 = $Data{B_Wells} ? sprintf "%0.0f", number( $Data{B_Q20total} / $Data{B_Wells} ) : "n/a";
                            if ( $Data{B_count} || $zeros ) {
                                $Stats->Set_Row( [ "$name Totals (Billable)", $Data{B_count}, $Data{B_AllReads}, number( $Data{B_AllBPs}, 0, '<BR>' ), $Data{B_Wells}, $avgSL, $avgQ20, number( $Data{B_Q20total}, 0, '<BR>' ) ], $colour );
                            }
                        }
                        if ($show_approved) {
                            my $avgSL  = $Data{A_Wells} ? sprintf "%0.0f", number( $Data{A_SLtotal} / $Data{A_Wells} )  : "n/a";
                            my $avgQ20 = $Data{A_Wells} ? sprintf "%0.0f", number( $Data{A_Q20total} / $Data{A_Wells} ) : "n/a";
                            if ( $Data{A_count} || $zeros ) {
                                $Stats->Set_Row( [ "$name Totals (Approved)", $Data{A_count}, $Data{A_AllReads}, number( $Data{A_AllBPs}, 0, '<BR>' ), $Data{A_Wells}, $avgSL, $avgQ20, number( $Data{A_Q20total}, 0, '<BR>' ) ], $colour );
                            }
                        }
                        if ($show_all_runs) {
                            my $avgSL  = $Data{Wells} ? sprintf "%0.0f", number( $Data{SLtotal} / $Data{Wells} )  : "n/a";
                            my $avgQ20 = $Data{Wells} ? sprintf "%0.0f", number( $Data{Q20total} / $Data{Wells} ) : "n/a";
                            if ( $Data{count} || $zeros ) {
                                $Stats->Set_Row( [ "$name Totals (All Runs)", $Data{count}, $Data{AllReads}, number( $Data{AllBPs}, 0, '<BR>' ), $Data{Wells}, $avgSL, $avgQ20, number( $Data{Q20total}, 0, '<BR>' ) ], $colour );
                            }
                        }
                    }
                }
            }
        }
    }

    if ( $title && $Stats ) { $Stats->Set_Title($title); }
    if ($Stats) {
        my $file_name = "Dated_Run_report_" . $stamp;
        $output .= $Stats->Printout( "$alDente::SDB_Defaults::URL_temp_dir/$file_name.html", $html_header );
        $output .= $Stats->Printout("$alDente::SDB_Defaults::URL_temp_dir/$file_name.xlsx");
        $output .= $Stats->Printout(0);
    }
    else {
        Message("No Data found as requested ($extra_condition)");
    }

    if ($include_summary) {
        $Stats = 0;    ## clear stats

        if ( $extra_condition || $group_projects ) {
            ## otherwise this may be redundant (?)
            foreach my $Pid ( split ',', $proj_ids ) {
                #### show project totals (without conditions) #####
                my @project_runs = $dbc->Table_find( 'SequenceAnalysis,SequenceRun,Run,Library,Plate',
                    'Run_ID', "WHERE FK_SequenceRun__ID=SequenceRun_ID AND SequenceRun.FK_Run__ID=Run_ID and Run.FK_Plate__ID =Plate_ID AND Library_Name= Plate.FK_Library__Name AND FK_Project__ID = $Pid" );
                my ($name) = $dbc->Table_find( 'Project', 'Project_Name', "where Project_ID = $Pid" );
                my $project_stats = &_run_list_statistics( -dbc => $dbc, -runs => \@project_runs, -label => "Entire $name Project", -table => $Stats, -total => 1, -include => $include, -highlight => 'lightgreenbw' );
                $Stats = $project_stats->{table};    ## ??
            }
        }

        ### Print show stats with various run_status / billable status
        if (0) {
            my @fields = ( 'count(*) as Runs', 'Sum(Wells) as Read_Count', 'Sum(AllReads) as AllReads', 'Sum(Q20total) as Q20_count', 'Sum(SLtotal) as SL_count', 'Run_Test_Status', 'Billable', 'Sum(AllBPs) as AllBPs' );
            my %sums = &Table_retrieve( $dbc, 'Run,SequenceRun,SequenceAnalysis,Plate,Library',
                \@fields, "WHERE FK_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name AND FK_Run__ID=Run_ID AND SequenceRun_ID=FK_SequenceRun__ID AND FK_Project__ID IN ($proj_ids) GROUP BY Run_Test_Status,Billable" );
            my $index = -1;
            while ( defined $sums{Run_Test_Status}[ ++$index ] ) {
                my $q20_avg = sprintf "%0.0f", $sums{Q20_count}[$index] / $sums{Read_Count}[$index];
                my $sl_avg  = sprintf "%0.0f", $sums{SL_count}[$index] / $sums{Read_Count}[$index];
                my $billable = $sums{Billable}[$index];
                if    ( $billable =~ /no/i )    { $billable = "NOT Billable" }
                elsif ( $billable =~ /yes/i )   { $billable = "Billable" }
                elsif ( $billable =~ /techD/i ) { $billable = "Billable TechD" }
                my $prefix;
                if ( $proj_ids =~ /,/ ) { $prefix = 'All Listed Projects' }
                $Stats->Set_Row(
                    [   "<B>$prefix ($sums{Run_Test_Status}[$index] - $billable )</B>", "<B>$sums{Runs}[$index]</B>", number( $sums{AllReads}[$index], 0,                                '<BR>' ), number( $sums{AllBPs}[$index], 0, '<BR>' ),
                        $sums{Read_Count}[$index],                                      $q20_avg,                     $sl_avg,                         number( $sums{Q20_count}[$index], 0,        '<BR>' )
                    ],
                    'mediumredbw'
                );
            }
        }
        if ($proj_ids) {
            $output .= &Project_overview( -condition => "FK_Project__ID IN ($proj_ids)", -title => "All acquired data from chosen projects to date", -name => "Projects.$proj_ids", -since => $since, -until => $until, -pipeline => $pipeline );
        }
    }

    $Benchmark{statushome_end} = new Benchmark;
    return $output;
}

#######################
sub Project_overview {
#######################
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc} || $Connection;
    my $title     = $args{-title} || 'overview';
    my $condition = $args{-condition} || 1;
    my $name      = $args{-name} || 'ProjectOverview';
    my $pipeline  = $args{-pipeline};
    my $since     = $args{-since};
    my $until     = $args{ -until };
            ## generate overview for ALL Projects as well - same as above with Project condition removed ##

            my $extra_condition;
            if ($since) {
        $extra_condition .= " AND Run_DateTime >= '$since'";
        $title           .= "<BR> Runs from $since";
    }
    if ($until) {
        $until = &end_of_day($until);
        $extra_condition .= " AND Run_DateTime <= '$until'";
        $title           .= " Until $until;";
    }

    if ($pipeline) {
        $title .= "<BR>$pipeline Pipeline";
        my $pipeline_list = $dbc->get_FK_ID( 'FK_Pipeline__ID', $pipeline );

        if ($pipeline_list) {

            # Message("Filtering on Pipeline");
            my $daughter_pipelines = join ',', alDente::Pipeline::get_daughter_pipelines( -dbc => $dbc, -id => $pipeline_list, -include_self => 1 );
            $extra_condition .= " AND Plate.FK_Pipeline__ID IN ($daughter_pipelines)";
        }
    }

    my $stamp = RGTools::RGIO::timestamp();

    my $output;
    my @fields = ( 'count(*) as Runs', 'Sum(Wells) as Read_Count', 'Sum(AllReads) as AllReads', 'Sum(Q20total) as Q20_count', 'Sum(SLtotal) as SL_count', 'Run_Test_Status', 'Billable', 'Sum(AllBPs) as AllBPs' );

    my %sums = $dbc->Table_retrieve( 'Run,SequenceRun,SequenceAnalysis,Plate,Library',
        \@fields, "WHERE FK_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name AND FK_Run__ID=Run_ID AND SequenceRun_ID=FK_SequenceRun__ID AND $condition $extra_condition GROUP BY Run_Test_Status,Billable" );
    my $index = -1;
    my $Summary = HTML_Table->new( -title => "$title - as of " . &today(), -border => 1 );
    $Summary->Set_sub_title( "Totals",               4, 'mediumgreenbw' );
    $Summary->Set_sub_title( "(excluding No Grows)", 4, 'mediumyellowbw' );
    $Summary->Set_Headers( [ 'Group', 'Runs', 'Reads', 'Base Pairs', 'Reads', 'Q20_avg', 'Length_avg', 'Q20_total' ] );
    while ( defined $sums{Run_Test_Status}[ ++$index ] ) {
        my $q20_avg = sprintf "%0.0f", $sums{Q20_count}[$index] / $sums{Read_Count}[$index];
        my $sl_avg  = sprintf "%0.0f", $sums{SL_count}[$index] / $sums{Read_Count}[$index];
        my $billable = $sums{Billable}[$index];
        if    ( $billable =~ /no/i )    { $billable = "NOT Billable" }
        elsif ( $billable =~ /yes/i )   { $billable = "Billable" }
        elsif ( $billable =~ /techD/i ) { $billable = "Billable TechD" }
        $Summary->Set_Row(
            [   "<B>All Projects ($sums{Run_Test_Status}[$index] - $billable )</B>", "<B>$sums{Runs}[$index]</B>", number( $sums{AllReads}[$index], 0,                                '<BR>' ), number( $sums{AllBPs}[$index], 0, '<BR>' ),
                $sums{Read_Count}[$index],                                           $q20_avg,                     $sl_avg,                         number( $sums{Q20_count}[$index], 0,        '<BR>' )
            ],
            'mediumredbw'
        );
    }

    if ($Summary) {
        $output .= $Summary->Printout( "$alDente::SDB_Defaults::URL_temp_dir/$name.$stamp.html", $html_header );
        $output .= $Summary->Printout( "$alDente::SDB_Defaults::URL_temp_dir/$name.$stamp.xlsx", $html_header );
        $output .= $Summary->Printout(0);
    }
    else { $output .= "<i>(Individual stats not shown or available)</i>"; }

    return $output;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

##############################
# Generate table showing libraries given a reference to a list of libraries
#
# Return HTML_Table object with libraries
##################################
sub _generate_library_list_old {
#################################
    my %args = @_;

## unnecessary with Table_retrieve_display...
    my $dbc        = $args{-dbc};
    my $lib_ref    = $args{-libraries};
    my $field_ref  = $args{-fields};
    my $title      = $args{-title};
    my $order_by   = $args{-order_by};
    my $details    = $args{-details} || 0;
    my $project_id = $args{-project_id};
    my $lib_type   = $args{-lib_type};

    my $homelink = $dbc->homelink();

    my $stamp = timestamp();

    my @libraries = @$lib_ref;
    my $libs = join "','", @libraries;

    unless ( grep /Library_Name/, @$field_ref ) { $field_ref = [ 'Library_Name', @$field_ref ]; }

    my $condition = "Library_Name IN ('$libs')";
    $condition .= " AND Library_Type = '$lib_type'" if $lib_type;

    my $Lib_Info = alDente::Library->new( -dbc => $dbc );
    my $found = $Lib_Info->load_Object( -condition => $condition, -order_by => $order_by, -multiple => 1 );

    my $output = '';

    my $Info = HTML_Table->new();
    $Info->Set_Class('small');
    $Info->Set_Line_Colour('white');
    $Info->Set_Title($title);

    my @headers;
    foreach my $index ( 1 .. $Lib_Info->record_count() ) {
        my $lib = $Lib_Info->value( -field => 'Library.Library_Name', -index => $index - 1 );
        my @row;
        foreach my $key ( @{$field_ref} ) {
            my ( $rtable, $rfield ) = $key =~ /(\w+)\.(\w+)/;
            if ( !$details && ( $key =~ /description/i ) ) {next}    ## exclude description from table
            if ( $key =~ /Project__ID/i ) {next}                     ## exclude description from table
            if ( $index == 1 ) {                                     ## set headers on first pass...
                my $label = $Lib_Info->{fields}->{$rtable}->{$rfield}->{prompt} || $key;
                my $lib_list = join ',', @libraries;
                if ($project_id) { $lib_list .= "&Project_ID=$project_id"; }
                my $link = &Link_To( $homelink, $label, "&Show+Project+Libraries=1&Library_Type=Sequencing&Order+By=$key&Libraries=$lib_list", 'black', ['newwin'] );
                push( @headers, $link );
            }

            my $value = $Lib_Info->value( -field => $key, -index => $index - 1 );

            ## put hyperlink at Library Name ##
            if ( $key =~ /\bLibrary_Name$/ ) {
                push(
                    @row,
                    &Link_To(
                        $homelink, $value,
                        "&HomePage=Library&ID=$value",

                        #				    "&Info=1&Table=Library&Field=Library_Name&Like=$value",
                        $Settings{LINK_COLOUR}, ['newwin']
                    )
                );
            }
            elsif ( $rfield =~ /\bFK/ ) {
                my ( $foreign_table, $foreign_field ) = foreign_key_check($rfield);
                my $link = get_FK_info( $dbc, $rfield, $value ) if $value;
                push( @row, &Link_To( $homelink, $link, "&Info=1&Table=$foreign_table&Field=$foreign_field&Like=$value", $Settings{LINK_COLOUR}, ['newwin'] ) );

            }
            else { push( @row, $value ); }
        }
        $Info->Set_Row( \@row );
        $index++;
    }
    $Info->Set_Headers( \@headers );
    $Info->Set_Border(1);
    return $Info;
}

#############################
sub _run_list_statistics {
#############################
    my %args = @_;

    my $dbc          = $args{-dbc};
    my $run_list_ref = $args{-runs};
    my $label        = $args{-label};
    my $Summary      = $args{-table};                             #### allow list to be concatenated by providing current table...
    my $highlight    = $args{-highlight};
    my $accumulate   = $args{-accumulate};
    my $total        = $args{-total};
    my $include      = $args{-include};
    my $group        = $args{-group};
    my $colour       = $args{-colour};
    my @colours      = @{ $args{-colours} } if $args{-colours};

    my $no_zeros = param('Remove Zeros');
    my $zeros    = !$no_zeros;

    unless (@colours) { @colours = ( 'vlightyellowbw', 'vlightbluebw' ) }

    my $show_production = ( $include =~ /production/i );
    my $show_all_runs   = ( $include =~ /(both|all|everything)/i );
    my $show_billable   = ( $include =~ /billable/i );
    my $show_approved   = ( $include =~ /approved/i );
    my $show_techD      = ( $include =~ /techD/i );

    my @run_list = @$run_list_ref;

    #    my $stats_file = "Run_Statistics";
    ### replace with stats from SequenceAnalysis...

    my %Accumulated = %{$accumulate} if $accumulate;

    my $runs = join ',', @run_list;
    $runs ||= 0;

    my @int_fields = ( 'Wells', 'AllReads', 'SLtotal', 'Q20total', 'AllBPs', 'Q20total' );

    if ($total) {
        foreach my $field (@int_fields) {
            $_ = "Sum($_) as $_";
        }
    }

    my %stats
        = &Table_retrieve( $dbc, 'SequenceAnalysis,SequenceRun,Run', [ 'FK_Run__ID', 'Run_Status', 'Run_Test_Status', 'Billable', 'Run_Validation', @int_fields ], "WHERE FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRun_ID AND FK_Run__ID in ($runs)" );
    my ( $test_runs, $production_runs, $billable_runs, $all_runs, $approved_runs ) = ( 0, 0, 0, 0, 0 );

    my ( $runs_found, $q20_count, $sl_count, $all_count, $reads, $good_reads ) = map {0} ( 1 .. 6 );
    my ( $Q20_average, $SL_average ) = ( 0, 0 );

    ### Track for Production Runs ###
    my ( $P_runs_found, $P_q20_count, $P_sl_count, $P_all_count, $P_reads, $P_good_reads ) = map {0} ( 1 .. 6 );
    my ( $P_Q20_average, $P_SL_average ) = ( 0, 0 );

    ### Track for Billable Runs ###
    my ( $B_runs_found, $B_q20_count, $B_sl_count, $B_all_count, $B_reads, $B_good_reads ) = map {0} ( 1 .. 6 );
    my ( $B_Q20_average, $B_SL_average ) = ( 0, 0 );

    ### Track for Approved Runs ###
    my ( $A_runs_found, $A_q20_count, $A_sl_count, $A_all_count, $A_reads, $A_good_reads ) = map {0} ( 1 .. 6 );
    my ( $A_Q20_average, $A_SL_average ) = ( 0, 0 );

    my $index = 0;

    while ( defined $stats{FK_Run__ID}[$index] ) {
        my $run            = $stats{FK_Run__ID}[$index];
        my $status         = $stats{Run_Test_Status}[$index];
        my $state          = $stats{Run_Status}[$index];
        my $billable_field = $stats{Billable}[$index];
        my $run_validation = $stats{Run_Validation}[$index];
        my $billable       = 0;
        if ( $include =~ /billable/i ) { $billable ||= $billable_field =~ /yes/i }     ## billable flag may depend on whether techd is included..
        if ( $include =~ /techD/i )    { $billable ||= $billable_field =~ /techD/i }
        $all_runs++;
        $reads      += $stats{AllReads}[$index];
        $good_reads += $stats{Wells}[$index];
        $q20_count  += $stats{Q20total}[$index];
        $sl_count   += $stats{SLtotal}[$index];
        $all_count  += $stats{AllBPs}[$index];

        unless ( $state =~ /Analyzed/i ) { $index++; next; }
        if ( $status =~ /Test/i ) {
            $test_runs++;
        }
        elsif ( $status =~ /Production/i ) {
            $production_runs++;
            $P_reads      += $stats{AllReads}[$index];
            $P_good_reads += $stats{Wells}[$index];
            $P_q20_count  += $stats{Q20total}[$index];
            $P_sl_count   += $stats{SLtotal}[$index];
            $P_all_count  += $stats{AllBPs}[$index];
        }
        if ( $run_validation =~ /Approved/i ) {
            $approved_runs++;
            $A_reads      += $stats{AllReads}[$index];
            $A_good_reads += $stats{Wells}[$index];
            $A_q20_count  += $stats{Q20total}[$index];
            $A_sl_count   += $stats{SLtotal}[$index];
            $A_all_count  += $stats{AllBPs}[$index];
        }
        if ($billable) {
            $billable_runs++;
            $B_reads      += $stats{AllReads}[$index];
            $B_good_reads += $stats{Wells}[$index];
            $B_q20_count  += $stats{Q20total}[$index];
            $B_sl_count   += $stats{SLtotal}[$index];
            $B_all_count  += $stats{AllBPs}[$index];
        }
        $index++;
    }
    if ($good_reads) {
        $Q20_average = sprintf "%0.2f", $q20_count / $good_reads;
        $SL_average  = sprintf "%0.2f", $sl_count / $good_reads;
    }
    if ($P_good_reads) {
        $P_Q20_average = sprintf "%0.2f", $P_q20_count / $P_good_reads;
        $P_SL_average  = sprintf "%0.2f", $P_sl_count / $P_good_reads;
    }
    if ($B_good_reads) {
        $B_Q20_average = sprintf "%0.2f", $B_q20_count / $B_good_reads;
        $B_SL_average  = sprintf "%0.2f", $B_sl_count / $B_good_reads;
    }
    if ($A_good_reads) {
        $A_Q20_average = sprintf "%0.2f", $A_q20_count / $A_good_reads;
        $A_SL_average  = sprintf "%0.2f", $A_sl_count / $A_good_reads;
    }
    if ($accumulate) {
        $Accumulated{count}    += $all_runs;
        $Accumulated{AllReads} += $reads;
        $Accumulated{Wells}    += $good_reads;
        $Accumulated{Q20total} += $q20_count;
        $Accumulated{SLtotal}  += $sl_count;
        $Accumulated{AllBPs}   += $all_count;

        $Accumulated{P_count}    += $production_runs;
        $Accumulated{P_AllReads} += $P_reads;
        $Accumulated{P_Wells}    += $P_good_reads;
        $Accumulated{P_Q20total} += $P_q20_count;
        $Accumulated{P_SLtotal}  += $P_sl_count;
        $Accumulated{P_AllBPs}   += $P_all_count;

        $Accumulated{B_count}    += $billable_runs;
        $Accumulated{B_AllReads} += $B_reads;
        $Accumulated{B_Wells}    += $B_good_reads;
        $Accumulated{B_Q20total} += $B_q20_count;
        $Accumulated{B_SLtotal}  += $B_sl_count;
        $Accumulated{B_AllBPs}   += $B_all_count;

        $Accumulated{A_count}    += $approved_runs;
        $Accumulated{A_AllReads} += $A_reads;
        $Accumulated{A_Wells}    += $A_good_reads;
        $Accumulated{A_Q20total} += $A_q20_count;
        $Accumulated{A_SLtotal}  += $A_sl_count;
        $Accumulated{A_AllBPs}   += $A_all_count;

        if ($group) {
            $Accumulated{$group}{count}    += $all_runs;
            $Accumulated{$group}{AllReads} += $reads;
            $Accumulated{$group}{Wells}    += $good_reads;
            $Accumulated{$group}{Q20total} += $q20_count;
            $Accumulated{$group}{SLtotal}  += $sl_count;
            $Accumulated{$group}{AllBPs}   += $all_count;

            $Accumulated{$group}{P_count}    += $production_runs;
            $Accumulated{$group}{P_AllReads} += $P_reads;
            $Accumulated{$group}{P_Wells}    += $P_good_reads;
            $Accumulated{$group}{P_Q20total} += $P_q20_count;
            $Accumulated{$group}{P_SLtotal}  += $P_sl_count;
            $Accumulated{$group}{P_AllBPs}   += $P_all_count;

            $Accumulated{$group}{B_count}    += $billable_runs;
            $Accumulated{$group}{B_AllReads} += $B_reads;
            $Accumulated{$group}{B_Wells}    += $B_good_reads;
            $Accumulated{$group}{B_Q20total} += $B_q20_count;
            $Accumulated{$group}{B_SLtotal}  += $B_sl_count;
            $Accumulated{$group}{B_AllBPs}   += $B_all_count;

            $Accumulated{$group}{A_count}    += $approved_runs;
            $Accumulated{$group}{A_AllReads} += $A_reads;
            $Accumulated{$group}{A_Wells}    += $A_good_reads;
            $Accumulated{$group}{A_Q20total} += $A_q20_count;
            $Accumulated{$group}{A_SLtotal}  += $A_sl_count;
            $Accumulated{$group}{A_AllBPs}   += $A_all_count;
        }
    }

    unless ($Summary) {
        $Summary = HTML_Table->new( -border => 1 );
        $Summary->Toggle_Colour('off');
        $Summary->Set_Title("$label");
        $Summary->Set_Headers( [ 'Group', '<B>Runs</B>', '<B>Reads</B>', 'Base Pairs', 'Reads**', 'Avg Read Length**', 'Q20 mean**', 'Q20 total**' ] );
        $Summary->Set_sub_title( "Total",                4, 'mediumgreenbw' );
        $Summary->Set_sub_title( "(excluding No Grows)", 4, 'mediumyellowbw' );
    }

    ##### Now Display the data we have acquired.. #####

    my @data;

    $colour = $highlight || toggle_colour( $colour, @colours );

    if ($show_production) {
        @data = ( "<B>$label</B> (Production)", "<B>$production_runs</B>", "<B>$P_reads</B>", number( $P_all_count, 0, '<BR>' ), $P_good_reads, $P_SL_average, "<B>$P_Q20_average</B>", number( $P_q20_count, 0, '<BR>' ) );

        $Summary->Set_Row( \@data, $colour );
    }

    if ( $show_billable || $show_techD ) {
        @data = ( "<B>$label</B> (Billable)", "<B>$billable_runs</B>", "<B>$B_reads</B>", number( $B_all_count, 0, '<BR>' ), $B_good_reads, $B_SL_average, "<B>$B_Q20_average</B>", number( $B_q20_count, 0, '<BR>' ) );

        if ( $zeros || $billable_runs ) { $Summary->Set_Row( \@data, $colour ) }
    }
    if ($show_approved) {
        @data = ( "<B>$label</B> (Approved)", "<B>$approved_runs</B>", "<B>$A_reads</B>", number( $A_all_count, 0, '<BR>' ), $A_good_reads, $A_SL_average, "<B>$A_Q20_average</B>", number( $A_q20_count, 0, '<BR>' ) );

        if ( $zeros || $approved_runs ) { $Summary->Set_Row( \@data, $colour ) }
    }
    if ($show_all_runs) {
        @data = ( "<B>$label</B> (All Runs)", "<B>$all_runs</B>", "<B>$reads</B>", number( $all_count, 0, '<BR>' ), $good_reads, $SL_average, "<B>$Q20_average</B>", number( $q20_count, 0, '<BR>' ) );

        if ( $zeros || $all_runs ) { $Summary->Set_Row( \@data, $colour ) }
    }
    $Summary->Set_Class('small');

    my %feedback;
    $feedback{colour}                = $colour;
    $feedback{table}                 = $Summary;
    $feedback{accumulated}           = \%Accumulated;
    $feedback{accumulated}->{$label} = \%Accumulated;

    return \%feedback;
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

$Id: Sequencing_Data.pm,v 1.33 2004/10/18 18:58:18 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
