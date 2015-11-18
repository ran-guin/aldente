################################################################################
# Run_Statistics.pm
#
# This module handles Container (Plate) Set based functions
#
###############################################################################
package alDente::Run_Statistics;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Run_Statistics.pm - This module handles Container (Plate) Set based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Container (Plate) Set based functions<BR>

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
use CGI qw(:standard);
use Data::Dumper;
use Statistics::Descriptive;
use RGTools::Barcode;
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DB_Object;
use alDente::Form;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use alDente::Container;
use alDente::Data_Images;

use SDB::DBIO;
use SDB::Progress;

use alDente::Validation;
use alDente::Container_Views;

use SDB::CustomSettings;
use SDB::DB_Form_Viewer;
use SDB::Data_Viewer;
use Sequencing::Primer;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Conversion;
use RGTools::Views;

##############################
# global_vars                #
##############################
use vars qw($testing $Security $Connection);
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

########
sub new {
########
    #
    # Constructor
    #

    my $this = shift;
    my %args = @_;

    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    ## database handle
    my $ids        = $args{-ids};
    my $attributes = $args{-attributes};                                                               ## allow inclusion of attributes for new record

    my $encoded = $args{-encoded} || 0;                                                                ## reference to encoded object (frozen)

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'SequenceAnalysis' );
    my ($class) = ref($this) || $this;

    bless $self, $class;

    $self->{dbc} = $dbc;

    return $self;
}

##############################
# public_methods             #
##############################

################
sub summary {
################
    #
    # Generate Summary of Run Statistics for a single run or group of runs...
    #
    my $self = shift;

    my %args = @_;

    my $date_min  = $args{-date_min}  || '0000-00-00';    ## get runs starting from ...
    my $date_max  = $args{-date_max}  || '';              ## get runs up until ...
    my $order_by  = $args{-order_by}  || '';              ## order results by ...
    my $group_by  = $args{-group_by}  || 'Run_ID';        ## group runs by ..
    my $condition = $args{-condition} || '';              ## specify more conditions
    my $more_fields = $args{-more_fields};                ## include fields (more than standard fields)
    my $include     = $args{-include} || '';              ## include runs of type: .. (eg 'billable, test')
    my $title       = $args{-title} || '';

    my $show       = $args{-show} || 0;                   ## show errors generated
    my $highlight  = $args{-highlight};                   ## specify field (labels) to highlight
    my $fields     = $args{-fields};
    my $get_unique = $args{-unique_clones};               ## generate list of unique clones

    my $library                = $args{-library};
    my $project                = $args{-project};
    my $summary_field_labels   = $args{-summary_labels};
    my $x_no_grow_field_labels = $args{-no_grow_labels};

    my $include_test   = ( $include =~ /test/i );
    my $billable_yes   = ( $include =~ /billable/i );
    my $billable_techD = ( $include =~ /techD/i );

    my $errors    = ( $show =~ /error/ );
    my $warnings  = ( $show =~ /warning/ );
    my $growth    = ( $show =~ /growth/ );
    my $stats     = ( $show =~ /stats/ );
    my $hist      = ( $show =~ /hist/ );
    my $medianQ20 = ( $show =~ /medianQ20/ );

    my $dbc = $self->{dbc};
    if ( $hist || $medianQ20 ) { $hist = 1; $medianQ20 = 1; }    ## if either are set, include the other by default...

    #check if a library or a project is specified. If they are, automatically generate the conditions
    #to display the project or library. Project takes precedence over library.

    if ($project) {
        my $proj_id = $project;

        # get all libraries associated with the project
        my @libs = $dbc->Table_find_array( "Library", ['Library_Name'], "where FK_Project__ID=$proj_id" );
        my $lib_list = join "','", @libs;
        return $self->summary(
            -condition      => "AND FK_Library__Name IN ('$lib_list')",
            -group_by       => "FK_Library__Name",
            -more_fields    => "FK_Library__Name as Library,sum(AllBPs) as TotalBPs,sum(SLtotal) as TotalLength,sum(Q20total) as TotalQ20",
            -show           => "hist,medianQ20,warning",
            -summary_labels => "Library,Runs,Reads,TotalBPs",
            -no_grow_labels => "TotalQ20,Mean_Q20,TotalLength,Avg_Length"
        );

    }
    elsif ($library) {
        my $lib_name = $library;
        return $self->summary(
            -condition      => "AND FK_Library__Name='$lib_name'",
            -group_by       => "FK_Library__Name",
            -more_fields    => "FK_Library__Name as Library,sum(AllBPs) as TotalBPs,sum(SLtotal) as TotalLength,sum(QLtotal) as TotalQ20",
            -show           => "hist,medianQ20,warning",
            -summary_labels => "Library,Runs,Reads,TotalBPs",
            -no_grow_labels => "TotalQ20,Mean_Q20,TotalLength,Avg_Length"
        );

    }

    my $page = '';

    my $base_columns = 7;
    if ( $group_by =~ /Equipment/ ) { $get_unique = 0; $base_columns--; }

    my @highlighted_fields = @$highlight if $highlight;

    my $order = '';
    if ($order_by) { $order = " ORDER BY $order_by" }
    my $group = '';
    if ($group_by) { $group = " GROUP BY $group_by" }

    $condition .= " AND Run_Status='Analyzed'";

    if ( $billable_yes || $billable_techD ) {
        if ( $billable_yes && $billable_techD ) { $condition .= " AND Billable in ('Yes','TechD')" }
        elsif ($billable_yes)   { $condition .= " AND Billable = 'Yes'" }
        elsif ($billable_techD) { $condition .= " AND Billable = 'TechD'" }
    }
    elsif ( !$include_test ) { $condition .= " AND Run_Test_Status='Production'" }

    if ( $condition && ( $condition !~ /\s*and\s/i ) ) { $condition = " AND $condition" }

    my @warnings = ( 'Sum(PoorQualityWarnings) as Poor_Quality', 'Sum(VectorSegmentWarnings) as Vector_Segment', 'Sum(VectorOnlyWarnings) as Vector_Only', 'Sum(ContaminationWarnings) as Contamination', 'Sum(RecurringStringWarnings) as Recurring_String' );
    my @warning_labels = ( 'Poor_Quality', 'Vector_Segment', 'Vector_Only', 'Contamination', 'Recurring_String' );

    ## Basic Fields
    my @field_list = ( 'count(*) as Runs', 'Sum(Wells) as Read_Count', 'Sum(Q20total)/Sum(Wells) as Mean_Q20', 'Sum(SLtotal)/Sum(Wells) as Avg_Length', 'Sum(Q20total) as Total_Q20', 'Sum(SLtotal) as Total_Length', 'Run_ID' );

    ## (Unique Clones will be replaced by values generated by separate query.. ##
    #if ($get_unique) { push(@field_list,'0 as Unique_Clones') }

    my @hidden = ( 'Total_Q20', 'Total_Length', 'Run_ID' );

    ## Growth Fields ##
    if ($growth) {
        push( @field_list, 'Sum(NGs) as NGs' );
        push( @field_list, 'Sum(SGs) as SGs' );
    }

    ## Warnings ##
    if ($warnings) {
        push( @hidden,     @warning_labels );
        push( @field_list, @warnings );
    }

    ## Extra fields specified ##
    $fields ||= \@field_list;
    if ($more_fields) {
        foreach my $extra ( split ',', $more_fields ) {
            @field_list = ( @field_list, $extra );
        }
    }
    ###
    #Algorithm to order fields
    ###

    #order fields here
    #order using summary_field_labels
    my @temp_fields_first = ();
    my @temp_fields_other = ();
    my @summary_fields    = split ",", $summary_field_labels;
    my @x_no_grow_fields  = split ",", $x_no_grow_field_labels;
    my @ordered_fields    = ();
    push( @ordered_fields, @summary_fields );
    push( @ordered_fields, @x_no_grow_fields );

    #push in fields that exist in @ordered_fields
    foreach my $field (@ordered_fields) {
        foreach my $actual_field (@field_list) {
            if ( $actual_field =~ /$field/ ) {
                push( @temp_fields_first, $actual_field );
            }
        }
    }

    #put in everything else that's not in @ordered_fields
    #uses simple difference formula from Perl Cookbook p 104
    my %seen;    #lookup table
    @seen{@temp_fields_first} = ();
    foreach my $item (@field_list) {
        push( @temp_fields_other, $item ) unless exists $seen{$item};
    }
    push( @temp_fields_first, @temp_fields_other );
    @field_list = @temp_fields_first;

    #    my $tables = 'Clone_Sequence,Sample,Run,RunBatch,Plate,Library_Plate,Equipment left join SequenceAnalysis on SequenceAnalysis.FK_SequenceRun__ID=Run_ID';
    my $tables = 'Run,SequenceRun,RunBatch,Plate,Library_Plate,Equipment left join SequenceAnalysis ON SequenceAnalysis.FK_SequenceRun__ID=SequenceRun_ID';

    #   $condition = "where Clone_Sequence.FK_Sample__ID=Sample_ID AND Clone_Sequence.FK_Run__ID=Run_ID and RunBatch_ID=FK_RunBatch__ID and Run.FK_Plate__ID=Plate_ID AND FK_Equipment__ID=Equipment_ID AND Library_Plate.FK_Plate__ID=Plate_ID $condition";
    $condition = "where SequenceRun.FK_Run__ID=Run_ID and RunBatch_ID=FK_RunBatch__ID and Run.FK_Plate__ID=Plate_ID AND FK_Equipment__ID=Equipment_ID AND Library_Plate.FK_Plate__ID=Plate_ID $condition";

    my %Results = &Table_retrieve( $self->{dbc}, $tables, $fields, "$condition $group $order" );

    if ($get_unique) {
        ## similar query for unique clones in the Clone_Sequence table.. ##
#	my @unique_list = $dbc->Table_find_array('Clone_Sequence,RunBatch,Run,Plate,Library_Plate,Equipment,Sample',['count(Distinct FK_Library__Name,Plate_Number,Parent_Quadrant,Well) as Unique_Clones'],"$condition AND Growth NOT LIKE 'No Grow' $group $order");

        my @unique_list = $dbc->Table_find_array(
            'Clone_Sequence,RunBatch,Run,SequenceRun,Plate,Library_Plate,Equipment',
            ['count(Distinct FK_Library__Name,Plate_Number,Plate.Parent_Quadrant,Well) as Unique_Clones'],
            "$condition AND Clone_Sequence.FK_Run__ID=Run_ID AND Growth IN ('OK','Slow Grow') $group $order"
        );
        ## update the Unique clone values... ##
        my $index = 0;
        foreach my $unique (@unique_list) {
            $Results{Unique_Clones}[$index] = $unique;
            $index++;
        }
    }

    ## histogram ##
    my %histogram;

    #variable that groups histograms, either by run/sequence, project, or library
    my $hist_id;
    if ( $hist || $medianQ20 ) {

        #pull out all the Q20array information needed, unpack into an array
        #grab all Q20 fields and the $group_by field if there is a $group_by field
        #if not, group by sequence_id
        my %hist_results;

        if ($group_by) {
            $hist_id = $group_by;
        }
        else {
            $hist_id = "Run_ID";
        }
        %hist_results = &Table_retrieve( $self->{dbc}, $tables, [ "$hist_id", 'Q20array' ], "$condition" );

        #unpack each member into an array, indexed by group field
        my $counter = 0;
        foreach $group ( @{ $hist_results{"$hist_id"} } ) {
            my @array = unpack "S*", $hist_results{"Q20array"}[$counter];
            if ( defined $histogram{$group} ) {
                my @hist_array = @{ $histogram{$group} };
                push( @hist_array, @array );
                $histogram{$group} = \@hist_array;
            }
            else {
                $histogram{$group} = \@array;
            }
            $counter++;
        }
    }

    ## define subtitles ##
    my %Subtitles;
    my @subtitle_keys = ('Summary');

    #   push(@subtitle_keys,'Excluding No Grows');
    #   if ($warnings) {
    #	push (@subtitle_keys,"Warnings");
    #    }
    $Subtitles{keys} = \@subtitle_keys;

    my $summary_field_num = undef;
    my $x_no_grow_num     = undef;
    my $other_field_num   = undef;

    if (@summary_fields) {
        $summary_field_num = $#summary_fields + 1;
        $x_no_grow_num     = $#field_list - $#summary_fields;
        if ($hist) {
            $other_field_num++;
        }
        if ( $medianQ20 && ( $medianQ20 ne "" ) ) {
            $other_field_num++;
        }
    }

    if ($warnings) {
        $x_no_grow_num -= 1 if $x_no_grow_num;
        unless ($medianQ20) {
            $x_no_grow_num -= 1 if $x_no_grow_num;
        }
        unless ($hist) {
            $x_no_grow_num -= 1 if $x_no_grow_num;
        }
        $other_field_num = $x_no_grow_num + $summary_field_num + 1;
    }

    $Subtitles{sizes} = [ $summary_field_num || $base_columns ];    ##,$x_no_grow_num || 2,$other_field_num || 5];
    $Subtitles{colours} = ['mediumgreenbw'];                        ## ,'lightredbw'];

    my @display_args = (
        -results   => \%Results,
        -fields    => $fields,
        -highlight => $highlight,
        -hidden    => \@hidden,
        -subtitles => \%Subtitles,
        -histogram => \%histogram
    );

    if ($medianQ20) { push( @display_args, -medianQ20 => "1" ); }
    if ( $hist || $medianQ20 ) { push( @display_args, -histogram_key => "$hist_id" ); }
    if ($warnings) { push( @display_args, -warning_labels => \@warning_labels ); }
    $page .= _display( -title => $title, @display_args );

    ### Show Run Failures if desired ###
    if ($errors) {
        $condition =~ s/Run_Status=\'Analyzed/Run_Status=\'Failed/;    ## look for failed runs rather than analyzed
        $page .= "<P>";
        my %Errors = &Table_retrieve( $self->{dbc}, $tables, [ $more_fields, 'count(*) as Failed_Runs' ], "$condition $group $order" );
        if ( $Errors{Failed_Runs}[0] ) { $page .= _display( -title => $title, -results => \%Errors, -fields => [ $more_fields, 'count(*) as Failed_Runs' ] ) }
        else                           { $page .= "<P>(NO failed runs detected)"; }
    }

    return $page;
}

##################################################################
# Generate 'Last 24 Hours' page showing details for various runs
#
# Generate status page for particular sequence runs (Last 24 Hours)
#
# (OLD - but still USED !)
#
##########################
sub sequence_status {
##########################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'library,plates,run_ids' );
    my $library   = $args{-library};                                          # library of interest
    my $plates    = $args{-plates};                                           # plates of interest
    my $ids       = $args{-run_ids};                                          ##### OR... ids of interest
    my $chemistry = $args{-chemistry};

    my $dbc      = $self->{dbc};
    my $homelink = $dbc->config('homelink');

    my $order = "FK_RunBatch__ID,Run_ID";
    if ( param('Order By') ) {
        $order = param('Order By') . ",$order";
    }
    elsif ( param('OrderBy') ) {
        $order = param('OrderBy') . ",$order";
    }

    my $page;
    my $dbsummary = 'http://www.bcgsc.bc.ca/cgi-bin/intranet/sequence/summary/dbsummary';    ## retrieve from defaults .. ?

    ########### Retrieve Stats ############
    #    my $Chem = &RGTools::RGIO::load_Stats("ChemistryInfo",$Stats_dir);  ### readable info from chemistry codes..
    my $Chem = &Sequencing::Primer::get_ChemistryInfo();

    my $stamp               = time();
    my $check_mirror_status = 0;

    my @sequences    = ();
    my $good_quality = param('Non-Zero Quality');
    my @plate_nums;

    if ($ids) {
        @sequences = $dbc->Table_find( 'Run,RunBatch,Plate', 'Run_ID', "WHERE FK_Plate__ID=Plate_ID AND FK_RunBatch__ID=RunBatch_ID AND Run_ID in ($ids) Order by $order" );
    }
    elsif ($library) {
        if ( $library =~ /(.*)\s?-\s?(.*)/ ) { $library = $1 . $2 }
        if ( param('Plate List') ) {
            $plates = "";
            foreach my $name ( param() ) {
                my $value = param($name);
                if ( $name =~ /Plate(\d+)(\S*)/i ) { $plates .= "$1$2,"; }
            }
            if ( $plates =~ /,$/ ) { chop $plates; }
        }
        if ( $plates =~ /Pla(\d+)/i ) { $plates = get_aldente_id( $dbc, $plates, 'Plate' ); }

        $page .= h2("Run Read Info for $library Library ($plates)");

        my @new_sequences;
        if ($plates) {
            foreach my $plate ( split ',', $plates ) {
                my $plate_num;
                if ( $plate =~ /(\d+)([a-zA-Z]?)/ ) { $plate_num = $1; }
                my $current_list = join ',', @plate_nums;
                unless ( &list_contains( $current_list, $plate_num ) ) { push( @plate_nums, $plate_num ); }
                push( @new_sequences, $dbc->Table_find( 'Run,RunBatch,Plate', 'Run_ID', "WHERE FK_Plate__ID=Plate_ID AND FK_RunBatch__ID=RunBatch_ID AND FK_Library__Name = '$library' and Plate_Number like '$plate' Order by $order" ) );
            }
        }
        else {
            @new_sequences = join ',', $dbc->Table_find( 'Run,RunBatch,Plate', 'Run_ID', "WHERE FK_Plate__ID=Plate_ID AND FK_RunBatch__ID=RunBatch_ID AND Run_Directory like '$library%' Order by $order" );
        }

        if ( $new_sequences[0] ne 'NULL' ) { push( @sequences, @new_sequences ); }
    }
    else { Message("No records found"); }

    # Run Info table
    my $Runs = HTML_Table->new( -nowrap => 1, -nolink => 1 );
    $Runs->Set_Border(1);
    $Runs->Set_sub_title( "Run Info",                                                                       11, 'mediumgreen' );
    $Runs->Set_sub_title( "Averages<BR><Span class=small>Excluding No Grows<BR>(QV=Quality Vector)</Span>", 2,  'lightredbw' );
    $Runs->Set_sub_title( "Status",                                                                         6,  'mediumyellowbw' );
    $Runs->Set_sub_title( "Comments<BR><Font color=red>(TEST runs in pink)</Font>",                         3,  'mediumgreenbw' );

    #  $Runs->Set_Class('small');

    #   foreach my $id (@sequences) {

    unless ( int(@sequences) > 0 ) {
        Message("No Runs found");
        return 0;
    }

    ### simplify Order specification for display... ###
    $order =~ s/FK_Equipment__ID/Machine/g;
    $order =~ s/Run_DateTime DESC/Date/g;

    $page .= &Views::Heading("Selected Runs (Ordered by $order)");
    my $form = 'Last24Hours';

    $page .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => $form );
    $page .= hidden( -name => 'cgi_application', -value => 'SequenceRun::Run_App', -force => 1 );

    my $sequence_list = join ',', @sequences;

    # only admins can force analyze

    #    if ($dbc->Security->department_access()=~/Admin/i) {
    #	$page .= &Link_To($homelink,"Force Re-Analysis for these runs",
    #		       "&ReAnalyze=$sequence_list",
    #		       $Settings{LINK_COLOUR},['newwin2']);
    $page .= submit( -name => 'rm', -value => 'Force (Re-)Analysis', -class => "Action" );
    $page .= "<span class=small> (re-analyzes <B>SELECTED</B> runs; or ALL runs on this page if none selected)</span>";
    $page .= &vspace();

    #    }
    # anybody in the sequencing lab can re-mirror
    if ( grep /Cap_Seq Production/, @{ $dbc->get_local("groups") } ) {
        $page .= "<span class=small>>";
        $page .= "Re-Mirror: ";
        ##### WARNING :: LINE below should be replaced with a function in Equipment.pm called get sequencers
        my @Sequencers = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
            'Equipment_Name',
            "where Category like 'Sequencer' AND Sub_Category IN (3100,3730) AND Equipment_Status like 'In Use' AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID" );

        foreach my $sequencer (@Sequencers) {
            $page .= &hspace(5);
            $page .= &Link_To( $dbc->config('homelink'), "$sequencer", "&ReMirror=1&ReMirror+Only=$sequencer", $Settings{LINK_COLOUR}, ['newwin2'] );
        }
        $page .= &hspace(5) . &Link_To( $dbc->config('homelink'), "(ALL)", "&ReMirror=1", $Settings{LINK_COLOUR}, ['newwin2'] );
        $page .= "</span>";
    }

    #  $page .= &Link_To($homelink,'ReGenerate Cache for these runs',
    #		 "&Last+24+Hours=1&Last+IDs=$sequence_list&Refresh=1",
    #		 'blue') . '<BR>';

    #  my %CSdata = %{ &get_cached_run_data($dbc,\@sequences,$good_quality) };
    my %CSdata;

    my @data = (
        'Run_ID',
        'RunBatch_ID as Batch',
        'Q20mean as P20_mean',
        'Wells as P20_count',
        'Q20median as P20_median',
        'QLmean as QL',
        'SLmean as SL',
        'QVmean as VQ',
        'Run_DateTime as DT',
        'Run_Directory as Name',
        'Equipment_Name as Equip',
        'Equipment_ID as Equip_ID',
        'FKMaster_Run__ID as Master',
        'Run_Status as State',
        'Run_Test_Status as Status',
        'Run_Comments as Comments',
        'Run.FK_Plate__ID as Plate',
        'RunBatch_Comments as Batch_Comments',
        'NGs',
        'Plate_Class',
        'Run_Validation',
        'Billable',
        'successful_reads',
        'Library_FullName',
        'Library_Description',
        'Plate_Label as Label',
        'Pipeline_Code as pipeline_code',
        'Pipeline_Name as pipeline',
        'Library_Name',
    );

    my %RunData = &Table_retrieve(
        $dbc,
        'RunBatch,Run,Plate,Pipeline,Library,Library_Plate,Equipment,SequenceRun LEFT JOIN SequenceAnalysis on SequenceAnalysis.FK_SequenceRun__ID=SequenceRun_ID LEFT JOIN MultiPlate_Run on MultiPlate_Run.FK_Run__ID=Run_ID',
        \@data,
        "WHERE Run.FK_RunBatch__ID=RunBatch_ID AND Run.FK_Plate__ID=Plate_ID AND Plate.FK_Pipeline__ID=Pipeline_ID AND Plate.FK_Library__Name=Library_Name AND Library_Plate.FK_Plate__ID=Plate_ID AND RunBatch.FK_Equipment__ID=Equipment_ID AND SequenceRun.FK_Run__ID=Run_ID AND Run_ID IN ($sequence_list)",
    );

    my $index = 0;

    while ( defined $RunData{'Run_ID'}[$index] ) {
        my $run           = $RunData{'Run_ID'}[$index];
        my $plate_class   = $RunData{'Plate_Class'}[$index];
        my $validation    = $RunData{'Run_Validation'}[$index];
        my $billable      = $RunData{'Billable'}[$index];
        my $successful    = $RunData{'successful_reads'}[$index];
        my $pipeline_code = $RunData{'pipeline_code'}[$index];
        my $pipeline      = $RunData{'pipeline'}[$index];
        my $plate_label   = $RunData{'Label'}[$index];
        unless ( $run =~ /[1-9]/ ) {next}

        foreach my $key ( keys %RunData ) {
            my $value = $RunData{$key}[$index];
            $CSdata{$run}->{$key} = $value;
        }
        my @vectors = $dbc->Table_find( 'Cross_Match', 'Match_Name', "WHERE Cross_Match.FK_Run__ID = $run", 'Distinct' );
        my $show_vector = $vectors[0];
        if ( int(@vectors) > 1 ) {
            $show_vector = int(@vectors) . " Vectors";
        }

        my ($unused) = $dbc->Table_find( 'Library_Plate', 'Unused_wells', "WHERE FK_Plate__ID = " . $RunData{'Plate'}[$index] );
        my $unused_count = int( my @list = split ',', $unused );
        $CSdata{$run}->{Unused} = $unused_count;

        $CSdata{$run}->{Vectors} = &Link_To( $dbc->config('homelink'), $show_vector, "&Info=1&Table=Cross_Match&Field=FK_Run__ID&Like=$run", $Settings{LINK_COLOUR}, ['newwin'] );

        my $E_threshold = 1 / 10000000;
        my ($contaminants) = $dbc->Table_find( 'Contaminant', 'count(*)', "WHERE Contaminant.FK_Run__ID = $run AND E_value < $E_threshold" );
        if ($contaminants) {
            $CSdata{$run}->{Contaminants}
                = &Link_To( $dbc->config('homelink'), $contaminants . "_wells", "&Info=1&Table=Contaminant&Field=FK_Run__ID&Like=$run&Condition=E_value<$E_threshold", $Settings{LINK_COLOUR}, ['newwin'], -tooltip => "E_value threshold = $E_threshold" );
        }
        else { $CSdata{$run}->{Contaminants} = "-"; }
        $CSdata{$run}->{Plate_Class}    = $plate_class;
        $CSdata{$run}->{Run_Validation} = $validation;
        $CSdata{$run}->{Billable}       = $billable;
        $CSdata{$run}->{Successful}     = $successful;
        $CSdata{$run}->{Pipeline_Code}  = $pipeline_code;
        $CSdata{$run}->{Pipeline}       = $pipeline;

        $index++;
    }

    my $colour = 0;
    my $lib;
    my $lastbatch;
    my $last_master;
    my $lastlib;
    my $plate;
    my $lastplate;

    my $number  = 1;
    my $row_num = 1;

    #     foreach my $well_data (@CSdata) {
    my $NumInBatch = 0;
    my @fields;
    my @interleave_list;
    my @batch_plates;
    my @ids;

    my $total_successful = 0;
    $index = 0;

    my $count = int(@sequences);

    my $progress_count = 20;    ## if more than this many reads found, generate progress bar ... ##
    my $Progress;
    if ( $count > $progress_count ) {
        $Progress = new SDB::Progress( "Retrieving Data for $count Reads", -target => $count );
    }

    my $i = 0;
    foreach my $sequence_id (@sequences) {
        if ($Progress) { $Progress->update($i); $i++; }

        unless ( defined $CSdata{$sequence_id}->{Run_ID} ) { $index++; next; }

        my $id         = $sequence_id;                                         ## $CSdata{$sequence_id}->{ID};
        my $batch      = $CSdata{$sequence_id}->{Batch};
        my $nextmaster = $CSdata{ $sequences[ $index + 1 ] }->{Master} || 0;
        my $count      = $CSdata{$sequence_id}->{P20_count};
        my $unused     = $CSdata{$sequence_id}->{Unused};
        my $NGs        = $CSdata{$sequence_id}->{NGs};
        my $successful = $CSdata{$sequence_id}->{Successful};

        #$page .= hidden(-name=>'Last IDs',-value=>$id) . "\n";
        $page .= "<input type='hidden' name='Last IDs' value='$id'/>\n";

        my $p20            = $CSdata{$sequence_id}->{P20_mean};
        my $ql             = $CSdata{$sequence_id}->{QL};
        my $sl             = $CSdata{$sequence_id}->{SL};
        my $vq             = $CSdata{$sequence_id}->{VQ};
        my $median         = $CSdata{$sequence_id}->{P20_median} || '?';
        my $dt             = $CSdata{$sequence_id}->{DT};
        my $run_name       = $CSdata{$sequence_id}->{Name};
        my $machine        = $CSdata{$sequence_id}->{Equip};
        my $machine_id     = $CSdata{$sequence_id}->{Equip_ID};
        my $master         = $CSdata{$sequence_id}->{Master};
        my $state          = $CSdata{$sequence_id}->{State};
        my $status         = $CSdata{$sequence_id}->{Status};
        my $comments       = $CSdata{$sequence_id}->{Comments};
        my $plate_id       = $CSdata{$sequence_id}->{Plate};
        my $batch_comments = $CSdata{$sequence_id}->{Batch_Comments};
        my $all_reads      = $CSdata{$sequence_id}->{AllReads};
        my $all_BPs        = $CSdata{$sequence_id}->{AllBPs};
        my $class          = $CSdata{$sequence_id}->{Plate_Class};
        my $validation     = $CSdata{$sequence_id}->{Run_Validation};
        my $billable       = $CSdata{$sequence_id}->{Billable};
        my $pipeline_code  = $CSdata{$sequence_id}->{Pipeline_Code};
        my $pipeline       = $CSdata{$sequence_id}->{Pipeline};
        my $plate_label    = $CSdata{$sequence_id}->{Label};
        my $library_name   = $CSdata{$sequence_id}->{Library_FullName};
        my $library_desc   = $CSdata{$sequence_id}->{Library_Description};
        $lib = $CSdata{$sequence_id}->{Library_Name};

        #	$ss_A += $CSdata{sequence_id}->{A_Signal_Strength};

        my $vectors      = $CSdata{$sequence_id}->{Vectors}      || '?';
        my $contaminants = $CSdata{$sequence_id}->{Contaminants} || '?';

        $index++;

        ## also figure out ...

        ## Run status (and associated colour) ..##
        my $quad;
        my $ver;
        my $ss_chem;

        #<CONSTRUCTION> This run directory name parsing needs to be updated
        if ( $run_name =~ /^($lib)\-?(\d+)([a-zA-Z]?)(.*?)(\.\d+$|$)/ ) {
            $lib      = $1;
            $plate    = $2;
            $quad     = $3;
            $ver      = $4 . $5;
            $ss_chem  = $1 . $2 . $3 . $4;          ## just the baseline sequence_subdirectory
            $run_name = "$lib - $plate$quad$ver";
        }

        my $chemistry = $ver;
        if ( $ver =~ /\.(\w+)/ ) {
            my $chem_code = $1;
            if ( $Chem->{Primer}->{$chem_code} ) {
                $chemistry = "<Font color=red>" . $Chem->{Primer}->{$chem_code} . "</Font>";    ## .$Chem->{Chemistry}->{$chem_code}
            }
        }

        my $run_colour = 'blue';
        my ($Run_status) = $dbc->Table_find( 'Run', 'Run_Test_Status', "WHERE Run_ID = $sequence_id" );
        if ( $Run_status =~ /test/i ) { $run_colour = 'red'; }
        my $run_link = &Link_To( $dbc->config('homelink'), "<B>$sequence_id</B>", "&Info=1&Table=Run&Field=Run_ID&Like=$sequence_id", $run_colour, ['newwin'], -tooltip => $run_name );    ### Run_ID column
        ## number of wells found (including no grows)
        my $showcount = $count;
        if ($unused) { $showcount .= "<font color=black>[$unused" . "U]</font>"; }
        if ($NGs)    { $showcount .= "<font color=red>[$NGs" . "NG]</font>"; }

        my $total = $count + $unused + $NGs;
        if ( $total =~ /(96|192|288|384)/ ) {
            $showcount = "<B><Font color=blue>$showcount</font></B>";
        }
        else {
            $showcount = Show_Tool_Tip( "<B><Font color=red>$showcount</font></B>", "Warning: strange totals (reads + unused)\nThis run may require re-analysis" );
            $Runs->Set_Cell_Colour( $row_num, 15, 'yellow' ) if $state =~ /(Analyzed)/;
        }

        push( @ids, $id );

        $comments       ||= '+';
        $batch_comments ||= '+';

        $ql = int($ql);

        ### set quality colour for highlighting Q20 values ###
        my $qcolour = 'black';
        if    ( $p20 < 200 ) { $qcolour = 'red'; }
        if    ( $p20 < 400 ) { $qcolour = 'red'; }
        elsif ( $p20 < 600 ) { $qcolour = 'green'; }
        elsif ( $p20 < 800 ) { $qcolour = 'blue'; }
        else                 { $qcolour = 'purple'; }

        my $p20_text    = "<Font color=$qcolour><B>" . int($p20) . "</B></Font>";
        my $median_text = "<Font color=$qcolour><B>" . int($median) . "</B></Font>";
        $sl = int($sl);
        $vq = int($vq);

        my $MS;
        if ($check_mirror_status) {
            $MS = "<Font color='red'><B>None</B></Font>";
            ( my $check_mirror ) = mirrored_files( $dbc, $id );
            if ($check_mirror) { $MS = $check_mirror; }
        }

        my $HoursMinutes;
        ## format date information ##
        $dt = convert_date( $dt, 'Simple' );
        if ( $dt =~ /(.+\d\d)-\d\d(\d\d)\s(.+)/ ) { $dt = "<B>$1</B><Font size=-3>/$2 $3</Font>"; $HoursMinutes = $3; }

        #	if ($dt=~/^\d\d(\d\d)[-](\d\d-\d\d) (\d\d:\d\d)/) { $dt = "<B>$2/$1</B> $3"; $HoursMinutes = $3; }

        my $plate_name = "PLA$plate_id: $lib-$plate$quad";
        if ($sl) {
            $run_name = &Link_To( $dbc->config('homelink'), $run_name, "&SeqRun_View=$sequence_id", 'black', ['newwin'] );
        }

        #        if ( $batch == $lastbatch ) { }
        if ( $master && $master == $last_master ) {
            $NumInBatch++;
        }
        else { @fields = (); $NumInBatch = 0; }

        my $fieldnum = 0;
        my $nextline;
        my $nextitem;

        # if there is a MultiPlate_Run entry, add to interleave list
        # otherwise, move on
        my @multiplate_run_ids = $dbc->Table_find( "MultiPlate_Run", "MultiPlate_Run_ID", "WHERE MultiPlate_Run.FK_Run__ID=$id" );
        if ( $NumInBatch && ( int(@multiplate_run_ids) > 0 ) ) {
            push( @interleave_list, $id );
            $nextline = "<BR>";
            $nextitem = "<BR><B>*</B>";

            # $dt = '';
            $machine = '';
        }
        else {
            @batch_plates    = ();
            @interleave_list = ($id);
            $nextline        = '';
            $nextitem        = "<BR><B>*</B>";
        }

        my $index_column = checkbox( -name => 'SelectRun', -label => "$number", -value => $sequence_id, -force => 1 );
        $number++;

        #my $validation_column = "<B>" . substr($validation,0,4) . "</B><BR>";

        $Runs->Set_Cell_Colour( $row_num, 2, 'lightgrey' );    ## set background on validation column to ensure it is visible
        my $val_colour = 'lightgrey';                          ## default approved colour
        if    ( $validation =~ /^Pending/ ) { $val_colour = 'yellow' }    ## highlight if 'Pending'
        elsif ( $validation =~ /Rejected/ ) { $val_colour = 'red' }       ## highlight if 'Rejected'
        ## generate small coloured cell to separate quadrants if necessary ##
        my $validation_column = "<Table width=100% cellspacing=0 cellpadding=5><TR><TD bgcolor=$val_colour>";
        $validation_column .= substr( $validation, 0, 4 );
        $validation_column .= "</TD></TR></Table>\n";

        $Runs->Set_Cell_Colour( $row_num, 3, 'lightgrey' );

        #my $show_billable = "<B>" . substr($billable,0,3)  . "</B><BR>";
        my $bill_colour = 'lightgrey';                                    ## default approved colour
        if ( $billable =~ /^No/ ) { $bill_colour = 'red' }                ## highlight if 'Pending'
        ## generate small coloured cell to separate quadrants if necessary ##
        my $bill_column = "<Table width=100% cellspacing=0 cellpadding=5><TR><TD bgcolor=$bill_colour>";
        $bill_column .= $billable;
        $bill_column .= "</TD></TR></Table>\n";

        $fields[ $fieldnum++ ] .= $nextline . $index_column;              ### index column
        $fields[ $fieldnum++ ] .= $nextline . $validation_column;         ### validation column
        $fields[ $fieldnum++ ] .= $nextline . $bill_column;               ### billable column

        $fields[ $fieldnum++ ] .= $nextline . $dt . br();                 ### Date column
        $fields[ $fieldnum++ ] .= $nextline . $run_link . br();

        &SDB::DB_Form_Viewer::info_link( -dbc => $dbc, -id => $id, -field => 'Run_ID', -table => 'Run' );    ### Run column

        my $machine_link = &Link_To( $dbc->config('homelink'), "<B>$machine</B>", "&Info=1&Table=Equipment&Field=Equipment_ID&Like=$machine_id", 'blue', ['newwin'] );
        $fields[ $fieldnum++ ] .= $nextline . $machine_link . br();                                          ### Machine column

        if ( ( $lib eq $lastlib ) && $NumInBatch ) {
            $fields[ $fieldnum++ ] .= $nextline . "''" . br();
        }
        else {
            $lastlib = $lib;
            $fields[ $fieldnum++ ] .= $nextline
                . &Link_To(
                $homelink,
                "<B>$lib</B>",
                "&Scan=1&Barcode=$lib",
                'blue',
                ['newwin'],
                -tooltip   => "<B>$library_name</B><BR>$library_desc",
                -tip_style => "white-space:normal; width:50em"
                ) . br();    ### Library column
                             #<A Href=$homelink&Info=1&Table=Library&Field=Library_Name&Like=$lib><B>$lib</B></A>";
        }

        #     my ($Plate_status) = $dbc->Table_find('Plate','Plate_Test_Status',"WHERE Plate_ID = $plate_id");
        my $Plate_status = $status;    ### temporary
        my $plate_colour = "blue";
        if ( $Plate_status =~ /Test/ ) { $plate_colour = "red"; }

        my $plate_link = alDente::Container_Views::foreign_label( -dbc => $dbc, -plate_id => $plate_id, -type => 'tooltip', -label => "<B>$plate$quad</B>" );

        my $plate_class = substr( $class, 0, 5 );
        if    ( $plate_class =~ /^o/i ) { $plate_class = "<B><Font color=red>$plate_class</Font></B>"; }
        elsif ( $plate_class =~ /^r/i ) { $plate_class = "<B><Font color=blue>$plate_class</Font></B>"; }

        unless ( grep /^$plate$/, @batch_plates ) {
            push( @batch_plates, $plate );
        }

        $fields[ $fieldnum++ ] .= $nextline . $plate_link . br();                                   ### Plate column
        $fields[ $fieldnum++ ] .= $nextline . $plate_class . br();                                  ### Plate Class column
        $fields[ $fieldnum++ ] .= $nextline . Show_Tool_Tip( $pipeline_code, $pipeline ) . br();    ### Pipeline column
        $fields[ $fieldnum++ ] .= $nextline . $plate_label . br();
        if ( $fields[$fieldnum] =~ /^$chemistry \($ver\)[\s|\'}<BR>]*$/ ) {
            $fields[ $fieldnum++ ] .= $nextline . "''" . br();                                      ### Primer/Chem column
        }
        else {
            $fields[ $fieldnum++ ] .= $nextline . "$chemistry ($ver)" . br();                       ### Primer/Chem column
        }
        $fields[ $fieldnum++ ] .= $nextline . "<B>$p20_text" . "[$median_text]/$sl</B>" . br();     ### Read Length column

        #      $fields[$fieldnum++] .= $nextline.$p20_text;  ### Phred 20 column
        $fields[ $fieldnum++ ] .= $nextline . "$vq/$ql" . br();                                     ### Quality Length (contiguous)

        #      $fields[$fieldnum++] .= $nextline.$vq;        ### Vecotor Quality column

        #### Status Columns.. #####

        $fields[ $fieldnum++ ] .= "<Font size=-2>$nextitem$vectors</Font>" . br();                  ### Vectors column

        $fields[ $fieldnum++ ] .= "<Font size=-2>$nextitem$contaminants</Font>" . br();             ### Contaminants column

        $fields[ $fieldnum++ ] .= $nextline . $showcount . br();                                    ### Wells column

        my $break;
        if ( $NumInBatch =~ /^[13579]/ ) {                                                          ## break after every 2nd image (0-indexed)
            $break = "<BR>";
        }

        if ( $lib =~ /^water$/i ) { $fields[ $fieldnum++ ] .= "<A href='$homelink&SeqRun_View=$sequence_id'><Img Src ='/$URL_dir_name/images/wells/Water_Run.png'/></A>$break"; }
        elsif ( ( $state =~ /Analyzed/ ) || ( $state =~ /Failed/ && $count ) ) {
            my $pview        = "<A Href ='$homelink&SeqRun_View=$sequence_id'>";
            my $project_path = &alDente::Run::get_data_path( -dbc => $dbc, -run_id => $id, -simple => 1 );
            my $thumbnail    = "$URL_dir/data_home/private/Projects/$project_path/phd_dir/Run$id.png";
            my $lfile        = &RGTools::RGIO::try_system_command("ls $thumbnail");
            if ( $lfile =~ /no such file/i ) {
                $pview .= &SDB::Data_Viewer::colour_map( $p20, 1200, 12 ) . $break;
            }                                                                                       ### if no map prvide button image based on Phred Quality...
            elsif ( $lfile =~ /.png/ ) {
                $pview .= "<Img Src ='../dynamic/data_home/private/Projects/$project_path/phd_dir/Run$id.png'/>$break";
            }
            else { $pview .= "($id)$break"; }

            #	    $pview .= "<span>View Details for this Run</span></A>\n";
            #push(@fields,$pview);

            $fields[ $fieldnum++ ] .= $pview;                                                       ### Colour Map column

        }
        elsif ( $state =~ /Initiated|In Process|Data Acquired/i ) {
            $fields[ $fieldnum++ ] .= "<A href='' onclick='return false;'><Img Src ='/$URL_dir_name/images/wells/Pending_Run.png'/></A>$break";
        }
        elsif ( $state =~ /Failed/i ) {
            ## just show Failed image...
            $fields[ $fieldnum++ ] .= "<A href='' onclick='return false;'><Img Src ='/$URL_dir_name/images/wells/Failed_Run.png'/></A>$break";
        }
        elsif ( $state =~ /Aborted/i ) {
            $fields[ $fieldnum++ ] .= "<A href='' onclick='return false;'><Img Src ='/$URL_dir_name/images/wells/Aborted_Run.png'/></A>$break";
        }
        elsif ( $state =~ /Expired/i ) {
            $fields[ $fieldnum++ ] .= "<A href='' onclick='return false;'><Img Src ='/$URL_dir_name/images/wells/Expired_Run.png'/></A>$break";
        }
        else { $fields[ $fieldnum++ ] .= "<B>?</B> $break"; }

        my $comment_colour = 'black';

        #### specify cell colours to highlight issues...
        ## primary identifiers: (Library Plate Chemistry)
        $Runs->Set_Cell_Colour( $row_num, 7, 'white' );
        $Runs->Set_Cell_Colour( $row_num, 7, 'white' );
        $Runs->Set_Cell_Colour( $row_num, 9, 'white' );
        if ( $status =~ /Test/ ) {
            $Runs->Set_Cell_Colour( $row_num, 18, 'pink' );
            $comment_colour = 'red';
        }
        elsif ( $status =~ /Production/ ) {
            $Runs->Set_Cell_Colour( $row_num, 18, 'lightgreen' );
            $comment_colour = 'green';
        }
        if ( $vq && ( $vq >= $ql ) ) {    ### if ONLY Vector in run...
            $Runs->Set_Cell_Colour( $row_num, 13, 'red' );
        }

        ###### Links column.. #####
        $fields[$fieldnum] = "";

        #      $fields[$fieldnum] =
        #	      "<br>\n<a href='$dbsummary?scope=runid&scopevalue=$id&option=scorecard&batch=1'>ScoreCard</a><br>\n";
        #      $fields[$fieldnum] .=  "<br><A Href='$dbsummary?scope=runid&scopevalue=$id&option=bpsummary&batch=1'>" .
        #	  "M&amp;M</a>";

        my $batch_plate_list = join ',', @batch_plates;    ### list of plate numbers in batch
        $fields[$fieldnum] .= "<br>\n" . &Link_To( $dbc->config('homelink'), 'Library', "&Prep+Summary=1&Library+Status=$lib", $Settings{LINK_COLOUR}, ['newwin'], -tooltip => 'View Prep Summary for entire Library' );
        $fields[$fieldnum] .= "<br>\n" . &Link_To( $dbc->config('homelink'), 'Plate', "&Prep+Summary=1&Library+Status=$lib&Plate+Number=$batch_plate_list", $Settings{LINK_COLOUR}, ['newwin'], -tooltip => 'View Prep Summary for this batch of Plates' );

        if ( int(@interleave_list) > 1 ) {
            my $list = join ',', @interleave_list;

            # Interleave column
            $fields[$fieldnum] .= '<BR><BR>' . &Link_To( $dbc->config('homelink'), 'I/leave', "&Interleave+View=$list", 'black', ['newwin'], -tooltip => "View interleaved quadrants<BR>(as they really appear on plate)" );
        }
        ## check for reloaded plates ##
        my @newchem_ids  = ($sequence_id);
        my @reloaded_ids = ();
        my @reloaded     = $dbc->Table_find( 'Run', 'Run_ID,FK_Plate__ID', "WHERE Run_Directory like '$ss_chem%' Order by Run_ID" );
        my ( $reloaded_index, $newchem_index ) = ( 0, 0 );
        foreach my $reload (@reloaded) {
            my ( $R_run_id, $R_plate_id ) = split ',', $reload;
            if ( $R_plate_id == $plate_id ) {
                push( @reloaded_ids, $R_run_id );
            }
            else {
                push( @newchem_ids, $R_run_id );
            }
            if ( $R_run_id == $sequence_id ) {
                $reloaded_index = int(@reloaded_ids);
                $newchem_index  = int(@newchem_ids);
            }
        }

        if ( int(@reloaded_ids) > 1 ) {
            my $ids = join ',', @reloaded_ids;
            my $reload_note = 'Reload';
            if ( $reloaded_index == 1 ) { $reload_note = 'R' }    ## just use R if it is the original

            my $reload_status = "$reload_note($reloaded_index/" . int(@reloaded_ids) . ");";
            my $link = &Link_To( $dbc->config('homelink'), $reload_status, "&Last+24+Hours=1&Any+Date=1&Run+ID=$ids", 'red', ['newwin2'] );
            $fields[$fieldnum] .= '<BR>' . $link;
        }
        elsif ( int(@newchem_ids) > 1 ) {
            my $ids = join ',', @newchem_ids;
            my $reload_note = 'Reload';
            if ( $newchem_index == 1 ) { $reload_note = 'R' }     ## just use R if it is the original

            my $reload_status = "$reload_note+($newchem_index/" . int(@newchem_ids) . ");";
            my $link = &Link_To( $dbc->config('homelink'), $reload_status, "&Last+24+Hours=1&Any+Date=1&Run+ID=$ids", 'red', ['newwin2'] );
            $fields[$fieldnum] .= '<BR>' . $link;
        }
        else { $fields[$fieldnum] .= '<BR>' . '-'; }

        $fieldnum++;

        $fields[ $fieldnum++ ] .= &Link_To( $dbc->config('homelink'), 'QC', "&Control Plate Monitoring=1&Plate_ID=$plate_id" ) . '<BR>';

        my @plate_notes = &alDente::Container::get_Notes( -dbc => $dbc, -plate_id => $plate_id );
        my $pNotes = join '<BR>', @plate_notes;
        $pNotes ||= '+';

### convert comments to links to edit pages... ###
        $comments = &Link_To( $dbc->config('homelink'), $comments, "&Edit+Table=Run&Field=FK_RunBatch__ID&Like=$batch", $comment_colour, ['newwin'], -tooltip => "(Edit):\n$comments", -truncate => 20, -tip_style => "left:-40em;" );

        $batch_comments = &Link_To( $dbc->config('homelink'), $batch_comments, "&Edit+Table=RunBatch&Field=RunBatch_ID&Like=$batch", 'blue', ['newwin'], -tooltip => "(Edit):\n$batch_comments", -truncate => 20, -tip_style => "left:-40em;" );

        $pNotes = &Link_To( $dbc->config('homelink'), $pNotes, "&Edit+Table=Plate&Field=Plate_ID&Like=$plate_id", 'blue', ['newwin'], -truncate => 20, -tooltip => "(Edit): $pNotes", -tip_style => "left:-40em;" );

### Comments column
        $fields[ $fieldnum++ ] .= "<Font size=-2>$nextitem$comments</Font>";

### Batch Comments column
        $fields[ $fieldnum++ ] = "<Font size=-2>$batch_comments</Font>";

        #    $fields[$fieldnum] ||= "\n<UL>";
        $fields[ $fieldnum++ ] .= "<Font size=-2>$nextitem$pNotes</Font>";    ### Plate Comments column
                                                                              #	 $fields[$fieldnum++] = join '<BR>', @plate_notes;

        if ($check_mirror_status) { push( @fields, $MS ); }

        ######## change colour if new Batch ########
        if ( ( $master ne $last_master ) ) {
            $colour = &toggle_colour( $colour, 'vlightgrey', 'vlightyellowbw' );
            $last_master = $master;
        }

        if ( $nextmaster && ( $nextmaster == $master ) ) {
            ### wait for last plate in batch (set of 96-well plates on 384-well container) ###
        }
        else {
            $Runs->Set_Row( \@fields, $colour );
            $row_num++;
        }
        $total_successful += $successful;
    }
    if ($Progress) { $Progress->update($i) }

    $page .= br();

    my @headers = ();
    ###### Generate Headers for Last 24 Hours Page ######
    my $id_list = join ',', @ids;
    my $toggle   = radio_group( -name => 'selectall', -value => 'toggle', -onclick => "SetSelection(document.$form,'SelectRun','toggle','$id_list');" );
    my $clearall = checkbox( -name    => 'clearall',  -label => 'clear',  onclick  => "SetSelection(document.$form,'SelectRun',0,'$id_list');" );
    push( @headers, "Select<BR>$toggle<BR>$clearall" );
    push( @headers, "Appr<BR>Rej<BR>" );
    push( @headers, "Bill?" );

    # push(@headers,'Date<BR>Time');
    push( @headers, '<Font color=black>Date<BR>Time</Font>' );
    push( @headers, 'Run ID<BR><Font color=red>(test)</Font>' );

    #  push(@headers,'Machine');
    push( @headers, '<Font color=black>Mach</Font>' );

    #  push(@headers,'Library');
    push( @headers, '<Font color=black>Lib</Font>' );
    push( @headers, '<Font color=black>Plate_#</Font>' );
    push( @headers, 'Class', 'Pipe<BR>Code', 'Label', 'Primer', 'Q20<BR>[Med]/<BR>Length', 'Vector<BR>(QV/QL)', 'X-match', 'ecoli' );
    push( @headers, Show_Tool_Tip( '#<BR><Font color=yellow>REDO</Font>', "If highlighted in bright yellow, the read counts seem to indicate an incomplete <br>quadrant.  (This may indicate that this run needs to be reanalyzed)" ) );

    my $prep = 'Prep_History<BR><span class=small>R - reloaded<BR>R+ (new plate)</span>';
    push( @headers, "Phred_20_Quality_Map<BR><Font color=red>(IF FAILED)</Font>", $prep, 'QC', '<Font color=lightgreen>Run<BR>Note</Font>' );

    my $batch_link = '<Font color=black>Batch Comments</Font>';
    push( @headers, $batch_link );
    push( @headers, 'Plates' );

    if ($check_mirror_status) { push( @headers, 'Mirrored<BR>Files' ); }

    $Runs->Set_Headers( \@headers );

    my $col = 0;
    $Runs->Set_Column_Class( $col++, 'small' );    ## select
    $Runs->Set_Column_Class( $col++, 'small' );    ## approve
    $Runs->Set_Column_Class( $col++, 'small' );    ## billable
    $Runs->Set_Autosort_Columns($col);
    $Runs->Set_Column_Class( $col++, 'small' );    ## date
    $Runs->Set_Column_Class( $col++, 'small' );    ## run_id
    $Runs->Set_Autosort_Columns($col);
    $Runs->Set_Column_Class( $col++, 'small' );    ## machine
    $Runs->Set_Autosort_Columns($col);
    $Runs->Set_Column_Colour( $col++, 'lightblue' );    ## lib
    $Runs->Set_Autosort_Columns($col);
    $Runs->Set_Column_Class( $col++, 'small' );         ## plate
    $Runs->Set_Column_Class( $col++, 'small' );         ## class
    $Runs->Set_Column_Class( $col++, 'small' );         ## pipeline code
    $Runs->Set_Column_Class( $col++, 'small' );         ## label
    $Runs->Set_Column_Class( $col++, 'medium' );        ## primer
    $Runs->Set_Column_Class( $col++, 'small' );         ## Q20
    $Runs->Set_Column_Class( $col++, 'small' );         ## Vector
    $Runs->Set_Column_Class( $col++, 'small' );         ## cross-match
    $Runs->Set_Column_Class( $col++, 'small' );         ## ecoli
    $Runs->Set_Column_Class( $col++, 'small' );         ## wells
    $Runs->Set_Column_Class( $col++, 'small' );         ## quality map
    $Runs->Set_Column_Class( $col++, 'small' );         ## prep history
    $Runs->Set_Column_Class( $col++, 'small' );         ## QC
    $Runs->Set_Column_Class( $col++, 'small' );         ## run notes
    $Runs->Set_Autosort_Columns($col);
    $Runs->Set_Column_Class( $col++, 'small' );         ## batch comments
    $Runs->Set_Column_Class( $col++, 'small' );         ## plate comments

    #  $Runs->Set_Column_Widths([200],[12]);  ### set runmap column width
    $page .= $Runs->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Status$stamp.html", $html_header );
    $page .= $Runs->Printout(0);

    $page .= &vspace(5) . submit( -name => 'rm', -value => 'Troubleshoot Selected Runs', -class => 'Search' );
    if ( $dbc->Security->department_access() =~ /Admin/i ) {
        my $status_table = &vspace(5) . "<Table><TR><TD>";
        $status_table .= submit( -name => 'rm', -value => 'Set Billable Status', -class => 'Action' ) . "</TD><TD>" . popup_menu( -name => 'Billable Status', -values => [ '', 'Yes', 'No', 'TechD' ], -default => '', -force => 1 );

        $status_table .= "</TD></TR>";

        $status_table .= "<TR><TD>" . submit(
            -name    => 'rm',
            -value   => 'Set Validation Status',
            -class   => 'Action',
            -onClick => "
        unset_mandatory_validators(this.form);
        document.getElementById('comments_validator').setAttribute('mandatory',(this.form.ownerDocument.getElementById('validation_status').value=='Rejected') ? 1 : 0)
        return validateForm(this.form)
        "
        );
        $status_table .= "</TD><TD>" . popup_menu( -name => 'Validation Status', -values => [ '', 'Pending', 'Approved', 'Rejected' ], -default => '', -id => 'validation_status' );

        $status_table
            .= "</TD><TD rowspan=2>"
            . set_validator( -name => 'Comments', -id => 'comments_validator' )
            . "<font size=3><B>Comments:&nbsp;</B></font>"
            . textfield( -name => 'Comments', -size => 30, -default => '' )
            . "<i><font size=-1 color=red>&nbsp;mandatory for Rejected and Failed runs</i></font></TD></TR>";
        my $groups = $dbc->get_local('group_list');
        my $reasons = alDente::Fail::get_reasons( -dbc => $dbc, -object => 'Run', -grps => $groups );

        $status_table .= "<TR><TD>" . submit(
            -name    => 'rm',
            -value   => 'Set as Failed',
            -class   => 'Action',
            -onClick => "
        unset_mandatory_validators(this.form);
document.getElementById('failreason_validator').setAttribute('mandatory',1);
document.getElementById('comments_validator').setAttribute('mandatory',1);
return validateForm(this.form)"
        ) . "</TD><TD>" . popup_menu( -name => 'FK_FailReason__ID', -values => [ '', keys %{$reasons} ], -labels => $reasons, -force => 1 ) . set_validator( -name => 'FK_FailReason__ID', -id => 'failreason_validator' ) . "</TD></TR>";

        $status_table .= "</Table>";
        $page         .= $status_table;

    }

    $page .= hr;

    $page .= &summary_stats( -run_ids => $sequence_list, -dbc => $dbc );

    $page .= end_form();
    return $page;
}

##############################
# Function that creates a table for stats on a set of runs
##############################
sub summary_stats {
#######################
    my %args    = @_;
    my $dbc     = $args{-dbc};
    my $run_ids = $args{-run_ids};

    my @fields = qw{ Run_Status Q20array Wells Q20total SLtotal QLtotal QVtotal Wells successful_reads};
    my %RunData = $dbc->Table_retrieve( "Run,SequenceRun,SequenceAnalysis", \@fields, "WHERE FK_SequenceRun__ID=SequenceRun_ID AND FK_Run__ID=Run_ID AND Run_ID in ($run_ids)" );

    my $total_successful = 0;
    my @combined_Q20     = ();
    my ( $analyzed_runs, $analyzed_bps, $analyzed_reads, $total_Q20, $total_SL, $total_QV, $total_QL ) = ( 0, 0 );

    my $index = 0;
    ## accumulate Q20 numbers for summary ##
    while ( defined $RunData{'Run_Status'}[$index] ) {
        if ( $RunData{'Run_Status'}[$index] eq 'Analyzed' ) {
            my @array = unpack 'S*', $RunData{'Q20array'}[$index];
            push( @combined_Q20, @array );
            $analyzed_runs++;
            $analyzed_reads   += $RunData{'Wells'}[$index];
            $total_Q20        += $RunData{'Q20total'}[$index];
            $total_SL         += $RunData{'SLtotal'}[$index];
            $total_QL         += $RunData{'QLtotal'}[$index];
            $total_QV         += $RunData{'QVtotal'}[$index];
            $total_successful += $RunData{'successful_reads'}[$index];
        }
        $index++;
    }

    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@combined_Q20);
    my $median = $stat->median();
    my $avg    = $stat->mean();
    my $stddev = int( $stat->standard_deviation() );

    my $Summary = HTML_Table->new( -title => "Summary Stats for analyzed runs above", -colour => 'lightgrey' );
    $Summary->Set_Row( [ '<B>Runs</B>',  $analyzed_runs ] );
    $Summary->Set_Row( [ '<B>Reads</B>', $analyzed_reads ] );
    my $avg_SL     = sprintf "%0.0f", $total_SL / $analyzed_reads  if $analyzed_reads;
    my $avg_Q20    = sprintf "%0.0f", $total_Q20 / $analyzed_reads if $analyzed_reads;
    my $avg_QL     = sprintf "%0.0f", $total_QL / $analyzed_reads  if $analyzed_reads;
    my $avg_QV     = sprintf "%0.0f", $total_QV / $analyzed_reads  if $analyzed_reads;
    my $QV_percent = sprintf "%0.0f", 100 * $total_QV / $total_QL  if $total_QL;

    my $success_rate = sprintf "%0.0f", $total_successful / $analyzed_reads * 100 if $analyzed_reads;

    $Summary->Set_Row( [ '<B>Avg BPs / Read</B>',                                       $avg_SL ] );
    $Summary->Set_Row( [ '<B>Total BPs</B>',                                            number($total_SL) . " [$total_SL]" ] );
    $Summary->Set_Row( [ '<B>Median Q20</B>',                                           $median ] );
    $Summary->Set_Row( [ '<B>Mean Q20 +/- StdDev</B>',                                  "$avg_Q20 +/- $stddev" ] );
    $Summary->Set_Row( [ '<B>Total Q20 BPs</B>',                                        number($total_Q20) . " [$total_Q20]" ] );
    $Summary->Set_Row( [ '<B>Total Quality Trimmed Length</B>',                         $total_QL ] );
    $Summary->Set_Row( [ '<B>Mean Quality Trimmed Length/Read</B>',                     $avg_QL ] );
    $Summary->Set_Row( [ '<B>Avg Vector BPs identified in Quality Region</B>',          "$avg_QV ($QV_percent%)" ] );
    $Summary->Set_Row( [ '<B>Successful Reads [Rate]</B><BR>(trimmed q length >= 100)', "$total_successful [<B>$success_rate %</B>]" ] );

    my $output = $Summary->Printout( -filename => "$alDente::SDB_Defaults::URL_temp_dir/run_summary_stats" . &timestamp . ".html", -header => $html_header );
    $output .= $Summary->Printout(0);

    if ( $run_ids !~ /,/ ) {
        $output .= '<p ></p>';
        $output .= create_tree( -tree => { 'Well Stats' => run_stats(%args) } );
    }

    return $output;
}

#
# Generate Run stats for a single run, showing details on a lane by lane basis
#
#
#
# Return: HTML Table of results with median, Mean, Count and Start / End range of interest (default to using quality trimmed region)
#####################
sub run_stats {
#####################
    my %args        = @_;
    my $dbc         = $args{-dbc};
    my $run_ids     = $args{-run_ids};
    my $phred_score = $args{-phred_score} || 20;
    my $trimming    = $args{-trimming};
    my $debug       = $args{-debug};

    my @fields = qw{ Sequence_Scores Well FK_Sample__ID Quality_Left Quality_Length Vector_Quality Sequence_Length};
    my %RunData = $dbc->Table_retrieve( "Run,Clone_Sequence", \@fields, "WHERE FK_Run__ID=Run_ID AND Run_ID in ($run_ids)" );

    my $total_successful = 0;
    my @combined_Q20     = ();
    my ($scores) = ( 0, 0 );

    my $metric;    ## title for metric which we are retrieving for meta_length (below) ##
    if   ( $trimming eq 'Amplicon' ) { $metric = "Q$phred_score %" }
    else                             { $metric = 'Length' }

    my $Summary = HTML_Table->new( -title => "Summary Stats for analyzed runs above", -colour => 'lightgrey' );
    $Summary->Set_Headers( [ 'Well', 'Sample', 'Median', 'Mean', 'Count', 'Start', $metric, 'Filter' ] );    ##  = HTML_Table->new( -title => "Summary Stats for analyzed runs above", -colour => 'lightgrey' );

    my @combined_scores = ();
    my $analyzed_reads  = 0;

    use alDente::Tools;

    my $index = 0;
    ## accumulate Q20 numbers for summary ##
    while ( defined $RunData{'Well'}[$index] ) {
        my $lane   = $RunData{'Well'}[$index];
        my $sample = $RunData{'FK_Sample__ID'}[$index];
        my $qleft  = $RunData{'Quality_Left'}[$index];
        my $ql     = $RunData{'Quality_Length'}[$index];
        my $qv     = $RunData{'Vector_Quality'}[$index];
        my $sl     = $RunData{'Sequence_Length'}[$index];

        if   ( $index < 1 ) { $debug = 1; }
        else                { $debug = 0 }

        require Sequencing::Sequence;

        my @array = unpack 'C*', $RunData{'Sequence_Scores'}[$index];

        my ( $length, $array, $filter ) = Sequencing::Sequence::meta_length( -dbc => $dbc, -qleft => $qleft, -ql => $ql, -qv => $qv, -sl => $sl, -phred_score => $phred_score, -scores => \@array, -trimming => $trimming, -sample => $sample );

        push( @combined_scores, @$array );

        my $read_stat = Statistics::Descriptive::Full->new();
        $read_stat->add_data(@$array);

        $Summary->Set_Row( [ $lane, alDente_ref( 'Sample', $sample, -dbc => $dbc ), $read_stat->median, int( $read_stat->mean ), $read_stat->count(), $qleft, $length, $filter ] );

        $analyzed_reads++;
        $index++;
    }

    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@combined_scores);
    my $median = $stat->median();
    my $avg    = $stat->mean();
    my $total  = $stat->sum();
    my $count  = $stat->count();
    my $stddev = int( $stat->standard_deviation() );

    my $success_rate = sprintf "%0.0f", $total_successful / $analyzed_reads * 100 if $analyzed_reads;

    $Summary->Set_Row( [ 'Totals', '', 'Median', 'Mean', 'Count' ], 'mediumbluebw' );                     ##  = HTML_Table->new( -title => "Summary Stats for analyzed runs above", -colour => 'lightgrey' );
    $Summary->Set_Row( [ '', '-', $stat->median, int( $stat->mean ), $stat->count() ], 'lightredbw' );

    my $output = $Summary->Printout( -filename => "$alDente::SDB_Defaults::URL_temp_dir/run_stats" . &timestamp . ".html", -header => $html_header );
    $output .= $Summary->Printout(0);
    return $output;
}

##############################
# public_functions           #
##############################

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

##############
sub _display {
##############
    #
    # Display retrieved Results...
    #
    my %args = @_;

    my $title   = $args{-title} || "Data:";
    my $fields  = $args{-fields};
    my $results = $args{-results};            ## hash returned from retrieve command..

    my $file      = $args{-file}      || 0;
    my $highlight = $args{-highlight} || '';
    my $hidden    = $args{-hidden}    || '';

    my $histogram     = $args{-histogram};
    my $histogram_key = $args{-histogram_key};
    my $medianQ20     = $args{-medianQ20};
    my @warnings      = ();
    if ( $args{-warning_labels} ) {
        @warnings = @{ $args{-warning_labels} };
    }
    my $subtitles = $args{-subtitles};

    my @hidden_fields = ();
    @hidden_fields = @$hidden if $hidden;

    my @highlighted_fields = ();
    @highlighted_fields = @$highlight if $highlight;

    my %Results;
    %Results = %$results if $results;

    my %Subtitles;
    %Subtitles = %$subtitles if $subtitles;

    my %Label;
    my @headers = ();

    # save warning information to be appended to the end of a row
    my %warning_values;

    foreach my $field (@$fields) {
        my $label = $field;
        if ( $field =~ /(.*) as (.*)/ ) {
            $field = $1;
            $label = $2;
        }
        $Label{$field} = $label;
        unless ( grep /^$label$/, @hidden_fields ) {
            push( @headers, $label );    ## add headers
        }
    }

    # add median, histogram, and warning headers if necessary
    if ($medianQ20) {
        push( @headers, "Median<br>Q20" );
    }
    if ($histogram_key) {
        push( @headers, "Q20 Histogram" );
    }
    if ( scalar(@warnings) > 0 ) {
        push( @headers, "(by type)" );
    }

    my $Table = HTML_Table->new( -title => $title );
    $Table->Set_Headers( \@headers );
    $Table->Set_Class('small');
    my $index = 0;
    my %Total;
    while ( defined $Results{ $Label{ @$fields[0] } }[$index] ) {
        my @row;
        my $hist_key;
        foreach my $field (@$fields) {
            my $label = $Label{$field};
            my $value = $Results{$label}[$index];

            #get the histogram key (this needs to be BEFORE the value is converted to a link)
            if ( $field eq $histogram_key ) {
                $hist_key = $value;
            }

            if ( $value =~ /^\d+\.?\d*$/ ) {
                $Total{$label} += $value;
            }

            if ( $label =~ /array/ ) {
                $value = unpack_to_array( $value, 2 );
            }

            if ( grep /^$label$/, @highlighted_fields ) {
                $value = "<B><Font color=blue>$value</Font></B>" if $value;
            }

            # hide hidden fields (?)
            unless ( ( $label =~ /^Total_/ ) || ( $label =~ /^Run_ID$/ ) || ( _find_in_array( $label, @warnings ) == 1 ) ) {

                #if numeric, truncate
                if ( $value =~ /^\d*.$/ ) {
                    push( @row, "<B>" . number($value) . "</B><BR>($value)" );
                }
                else {
                    push( @row, $value );
                }
            }

            # save warning values
            if ( _find_in_array( $label, @warnings ) == 1 ) {
                $warning_values{$label} = $value;
            }
        }
        unless (@row) {next}
        ;    ##

        my $hist;
        my $median;
        if ( defined $histogram_key || defined $medianQ20 ) {

            my %hist_hash = %$histogram;
            my @keys      = keys %hist_hash;

            my $stat = Statistics::Descriptive::Full->new();
            my @hist_array = @{ $hist_hash{$hist_key} } if $histogram;
            $stat->add_data(@hist_array);
            $median = $stat->median();

            my %Distribution = $stat->frequency_distribution( $stat->max() - $stat->min() + 1 );
            ### set all values to stat->max (distribution does not work in this case)
            if ( $stat->max() == $stat->min() ) {
                $Distribution{ int( $stat->max() ) } = int(@hist_array);
            }

            my @Dist = @{ pad_Distribution( \%Distribution, -binsize => 10 ) };

            $file = "RunStatHist$index" . time() . ".gif";

            ($hist) = &alDente::Data_Images::generate_run_hist( data => \@Dist, filename => $file, height => 80, remove_zero => "on" );
            if ($medianQ20) {
                push( @row, "<B>$median</B>" );
            }
            if ($histogram_key) {
                push( @row, $hist );
            }
        }

        # push warning column into table
        if (%warning_values) {
            my $warning_string = "<br><b>";
            foreach my $warning_key ( keys %warning_values ) {
                $warning_string .= $warning_key . ":" . $warning_values{$warning_key};
                $warning_string .= "<br>";
            }
            $warning_string .= "</b><br>";
            push( @row, $warning_string );
        }

        $Table->Set_Row( \@row );
        $index++;
    }
    my @totals;
    foreach my $field (@$fields) {
        my $label = $Label{$field} || '';
        my $value = $Total{$label} || '';
        if ( $label =~ /^Total_(.*)/ && ( grep /Total_$1/, @hidden_fields ) ) {next}
        elsif ( $label =~ /Avg_(.*)/ && ( grep /Total_$1/, @hidden_fields ) ) {
            unless ( $Total{Read_Count} ) {next}
            $value = sprintf "%0d", $Total{"Total_$1"} / $Total{Read_Count};
        }

        # omit sequence ID and warnings
        unless ( ( $field =~ /^Run_ID$/ ) || ( $field =~ /Warnings/ ) ) {

            #if numeric, truncate
            if ( $value =~ /^\d*.$/ ) {
                push( @totals, "<B>" . number($value) . "</B><BR>($value)" );
            }
            elsif ($value) {
                push( @totals, "<B>$value</B>" );
            }
            else {
                push( @totals, '' );
            }
        }
    }

    if ( $totals[1] > 0 ) {    ## if runs found.. ##
        $Table->Set_Row( \@totals, 'lightredbw' );
    }

    if ($subtitles) {
        my $index = 0;
        while ( defined $Subtitles{keys}[$index] ) {
            my $key    = $Subtitles{keys}[$index];
            my $length = $Subtitles{sizes}[$index];
            my $colour = $Subtitles{colours}[$index];
            $Table->Set_sub_title( $key, $length, $colour );
            $index++;
        }
    }
    my $returnval = '';
    if ( $Table->{rows} ) {
        $returnval .= $Table->Printout( -filename => "$alDente::SDB_Defaults::URL_temp_dir/stats" . &timestamp . ".html", -header => $html_header );
        $returnval .= $Table->Printout(0);
    }
    else {
        $returnval .= "(No Runs found)";
    }
    return $returnval;
}

# private function that finds an element in an array
# returns 0 if it is not found, 1 if it is
# format: _find_in_array($scalar,@array);
######################
sub _find_in_array {
######################
    my ( $scalar, @array ) = @_;
    foreach my $member (@array) {
        if ( $member eq $scalar ) {
            return 1;
            last;
        }
    }
    return 0;
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

$Id: Run_Statistics.pm,v 1.49 2004/10/18 18:58:04 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
