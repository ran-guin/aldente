################################################################################
# SDB_Status.pm
#
# This modules provides various status feedback for the Sequencing Database
#
################################################################################
################################################################################
# $Id: SDB_Status.pm,v 1.141 2004/12/09 17:38:33 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.85
#     CVS Date: $Date: 2004/12/09 17:38:33 $
################################################################################
package Sequencing::SDB_Status;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

SDB_Status.pm - This modules provides various status feedback for the Sequencing Database

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This modules provides various status feedback for the Sequencing Database<BR>CVS Revision: $Revision: 1.85 <BR>

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
    status_home
    library_status
    all_lib_status
    Project_Stats
    sequencer_stats
    index_warnings
    latest_runs
    quick_view
    mirrored_files
    weekly_status
    capillary_status
    Latest_Runs_Conditions
    Seq_Data_Totals
);
@EXPORT_OK = qw(
    status_home
    library_status
    all_lib_status
    Project_Stats
    sequencer_stats
    index_warnings
    latest_runs
    quick_view
    mirrored_files
    weekly_status
    capillary_status
    Latest_Runs_Conditions
    Seq_Data_Totals
);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use File::stat;
use Statistics::Descriptive;
use Data::Dumper;

#use GD;
#use GD::Graph;
#use GD::Graph::bars; # was GIFgraph::bars
#GD::Graph::colour::read_rgb("/usr/local/apache/site-images/rgb.txt");
use Benchmark;

#use SelfLoader;
#*AUTOLOAD = \&AutoLoader::AUTOLOAD;

##############################
# custom_modules_ref         #
##############################
use Sequencing::Primer;
use alDente::Form;
use alDente::Diagnostics;
use alDente::Summary;
use Sequencing::Sequencing_Data;
use alDente::SDB_Defaults;
use alDente::Run_Statistics;
use alDente::Data_Images;
use SDB::DB_Form_Viewer;
use SDB::DBIO;
use alDente::Validation;
use SDB::Histogram;
use SDB::Data_Viewer;
use SDB::HTML;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
use vars qw($local_drive);
our ( $homefile, $homelink, $plate_id, $scanner_mode, $testing, $dbase );
our ( $parents, $current_plates, $plate_set, $barcode, $user, $equipment_id, $solution );
our ( $full_page,     $default_lib );
our ( @plate_formats, @library_names, @libraries, @locations, @projects );
our ( @rack_info,     @plate_sizes );
our ( $class_size,    $button_colour );
our ($MenuSearch);
our ( $trace_link,  $Track );                                                        ### link to trace files...
our ( $html_header, $URL_dir, $URL_temp_dir, $mirror, $Stats_dir, $run_maps_dir );
our ( $dbsummary,   %all_available_versions );
use vars qw(%Benchmark %Settings $Connection %Sess %Configs);

#__DATA__;
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
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#################################       done
sub status_home {
#######################
    # Home page for Sequencing Status information
    #
    #  This should not be used in the next release and be phased out
#######################

    Message("WARNING: Please contact LIMS if you are using seeing this page - CODE: SDB Status");
    my $dbc              = shift;
    my $sequencing_stats = shift;    #If passed in then return only Sequencing stats choices.

    my $homelink = $dbc->homelink();

    my $test_runs;
    my $Project;
    my $Ptype;
    my $Library;
    my $Pcondition = "";
    my $Lcondition = "";

    if ( param('ReGenerate Menus') ) {
        $Project = join "','", param('Project Choice');
        $Library = param('Library Status');
        if ( $Library =~ /(.*):/ ) { $Library = $1; }

        if ($Project) {

            # $Pcondition = "WHERE Project_Name in ('$Project')";
            $Lcondition = "AND Project_Name in ('$Project')";
        }
    }
    $Pcondition .= " Order by Project_Name";
    $Lcondition .= " Order by Library_Name";

    my $lib                   = param('Library');
    my @projects              = $dbc->Table_find( 'Project', 'Project_Name', $Pcondition );
    my @pipelines             = $dbc->get_FK_info( 'FK_Pipeline__ID', -list => 1 );
    my @choose_from_libraries = $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID $Lcondition" );

    print start_custom_form( -form => 'NewWinForm' ) . Views::Heading( "Sequencing Status Page" . hspace(5) . "<span class=small>" . checkbox( -name => 'NewWin', -label => 'Display results in new window', -checked => 0 ) . "</span>" ) . "</form>";

    my $specify     = _init_table('Specify Project');
    my $Lib_specify = _init_table('Specify Library (Optional)');
    my @lib_types   = $dbc->get_enum_list( -table => 'Vector_Based_Library', -field => 'Vector_Based_Library_Type', -sort => 1 );
    push( @lib_types, "PCR_Product" );

    my $specify_content = '';

    $specify_content .= checkbox( -name => 'Include Details', -checked => 0 ) . " (eg. Histograms, Medians)" . br . checkbox( -name => 'Remove Zeros', -label => 'Exclude Zeros from Tables / Histograms', -checked => 0 ) . br;

    $specify_content .= &vspace(5);
    $specify_content .= '<B>Group by</B>: <BR>' . radio_group( -name => 'Group By', -values => [ 'Project', 'Library', 'Library_Type', 'Month', 'Machine' ], -default => 'Library', -force => 1 ) . &vspace(2);

    $specify_content .= "<B>Include</B> : <BR>" . radio_group( -name => 'Include Runs', -values => [ 'Production', 'Billable', 'Approved', 'TechD', 'All' ], -default => 'Billable', -force => 1 ) . &vspace(2);

    $specify_content .= "<B>Include Library Types</B> : " . scrolling_list( -name => 'Library Type', -value => [ '', @lib_types ], -default => '', -multiple => 2, -size => 2 ) . &vspace(2);
    $specify_content .= '<B>Order by</B>: ' . radio_group( -name => 'Order By', -values => [ 'Name', 'Date' ], -default => 'Name', -force => 1 ) . &vspace(5);

    $specify_content .= '<hr>';
    $specify_content .= "<B>Project(s):</B>";
    $specify_content .= hspace(140) . Show_Tool_Tip( checkbox( -name => 'Group Projects', -label => 'Combine Projects', -checked => 0 ), "Select to Group all Projects together (eg. if grouping months)" ) . &vspace(5);

    $specify_content .= alDente::Tools::search_list( -dbc => $dbc, -name => 'Project.Project_Name', -search => 1, -filter => 1, -mode => 'scroll', -size => 4 );

    $specify_content .= "<br />";

    # $specify_content .= "<B>Project(s):</B><br>" . scrolling_list(-name=>'Project Choice',-multiple=>2,-size=>5,-values=>['',@projects]) .
    $specify_content .= '<hr>';
    $specify_content .= "<B>Pipeline(s):</B><BR>";
    $specify_content .= alDente::Tools::search_list( -dbc => $dbc, -name => 'Plate.FK_Pipeline__ID', -search => 1, -filter => 1, -mode => 'scroll', -size => 4 );

    # alDente::Tools::search_list(-dbc=>$dbc,-table=>'Plate',-field=>'FK_Pipeline__ID',-values=>['',@pipelines],-default=>'',-mode=>'scroll');
    # popup_menu(-name=>'Pipeline Choice',-values=>['',@pipelines],-default=>'');

    ## Library options

    my $Lib_specify_content
        = "Library:<br>"
        . textfield( -name => 'SearchLib', -size => 10, -onChange => "MenuSearch(document.StatusHome);" )
        . hidden( -name => 'ForceSearch' )
        . " (enter search string to find Library ...)"
        . br
        . RGTools::Web_Form::Popup_Menu( name => 'Library Status', values => [ '', @choose_from_libraries ], default => $Library, onClick => "SetSelection(document.StatusHome,SearchLib,'')", width => 100 );
    $Lib_specify_content
        .= &vspace(30) . Show_Tool_Tip( RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'ReGenerate Menus', class => "Std", newwin_form => 'NewWinForm' ), "(Reset Library choices based on Project selection)" ) . &hspace(10);
    $Lib_specify_content .= Show_Tool_Tip( reset( -name => 'Reset Criteria', -style => "background-color:violet" ),, $Tool_Tips{Reset_Button} );

    # $Lib_specify_content .= &vspace(2) . textfield(-name=>'Extra Condition',-size=>20,-default=>'');

    my $stats_table     = _init_table('Choose Project Statistics to Generate');
    my $Lib_stats_table = _init_table('Choose Library Info to View');
    my $stats_content   = "(Select Project and inclusion options at the left)" . vspace(5);

    my $summary_output;

    unless ($sequencing_stats) {
        ###########################
        print qq{<a href='$homelink&Seq_Data_Totals=1' onClick="goTo('$homelink','&Seq_Data_Totals=1',getElementValue(document.NewWinForm,'NewWin')); return false;">Run Data Totals/Histograms</a>}
            . hspace(5)
            . qq{<a href='http://ybweb.bcgsc.bc.ca/cgi-bin/intranet/Human_cDNA/Pool.pl' onClick="goTo('http://ybweb.bcgsc.bc.ca/cgi-bin/intranet/Human_cDNA/Pool.pl','',getElementValue(document.NewWinForm,'NewWin')); return false;">Transposon Library Status (link to Yaron\'s Page)</a>}
            . vspace(5);

        #                my $selflink = "$homelink&Target_Department=$Current_Department";
        my $selflink = "$homelink&Target_Department=$Current_Department";

        #
        # $stats_content .= "From: " . textfield(-name=>'Since',-size=>10,-default=>'');
        # $stats_content .= "To: " . textfield(-name=>'Until',-size=>10,-default=>&today());
        #$stats_content .= "(over last: " . textfield(-name=>'Days Ago',-size=>5,-default=>'') . " days)" . vspace(5);

        ###### DateFields ############
        my $year   = &date_time();
        my $fiscal = &date_time();
        if ( $fiscal =~ /^(\d\d\d\d)-(\d\d)/ ) {
            if   ( $2 > 5 ) { $fiscal = $1 . "-05-01"; }
            else            { $fiscal = $1 - 1 . "-05-01"; }    ### if we are in the beginning of a new year...
        }
        ( my $today )   = split ' ', &date_time('-1d');
        ( my $last7d )  = split ' ', &date_time('-7d');
        ( my $last30d ) = split ' ', &date_time('-30d');

        ( my $since ) = split ' ', &date_time('-30d');          ### default to last month
        ( my $upto )  = split ' ', &date_time();                ### todays date...

        $year =~ /^(\d\d\d\d)/;
        my $thisyear = $1;
        my $lastyear = $thisyear - 1;

        # checkbox(-name=>'Group By Library',-checked=>1).
        # checkbox(-name=>'Exclude if Empty',-checked=>1).
        # ' .<B> Show: </B>'.
        # radio_group(-name=>'Display_Reads',-values=>['Production','All_Runs','Both'],-default=>'Both');

        my $DC2 .= &vspace(10) . "<B>From:</B>" . textfield( -name => 'Since', -size => 11, -value => $since ) . &hspace(5) . "<B>Until :</B>" . textfield( -name => 'Until', -size => 11, -value => $upto );
        my $DC3
            = "(click below to reset date range)<BR>"
            . radio_group( -name => 'Today', -values => ['Today'], -onClick => "SetSelection(document.StatusHome,'Since','$today');SetSelection(document.StatusHome,'Until','$today')" )
            . &hspace(5)
            . radio_group( -name => '7 days', -values => ['7 days'], -onClick => "SetSelection(document.StatusHome,'Since','$last7d'); SetSelection(document.StatusHome,'Until','$today')" )
            . &hspace(5)
            . radio_group( -name => '30 days', -values => ['30 days'], -onClick => "SetSelection(document.StatusHome,'Since','$last30d'); SetSelection(document.StatusHome,'Until','$today')" )
            . &hspace(5)
            . radio_group( -name => 'Fiscal_Year', -values => ['Fiscal_Year'], -onClick => "SetSelection(document.StatusHome,'Since','$fiscal'); SetSelection(document.StatusHome,'Until','$today')" )
            . &hspace(5)
            . radio_group( -name => 'Calendar_Year', -values => ['Calendar_Year'], -onClick => "SetSelection(document.StatusHome,'Since','$thisyear-01-01'); SetSelection(document.StatusHome,'Until','$today')" )
            . &hspace(5)
            . radio_group( -name => 'Last_Year', -values => ['Last_Year'], -onClick => "SetSelection(document.StatusHome,'Since','$lastyear-01-01'); SetSelection(document.StatusHome,'Until','$lastyear-12-31')" )
            . &hspace(5)
            . radio_group( -name => 'Any Date', -values => ['Any Date'], -onClick => "SetSelection(document.StatusHome,'Since','');SetSelection(document.StatusHome,'Until','')" );

        $stats_content .= $DC2 . &hspace(10) . $DC3;

        $stats_content .= &vspace(5) . "Extra condition: " . Show_Tool_Tip( textfield( -name => 'Extra Condition', -size => 30, -default => '' ), "Add extra SQL condition here if desired" ) . &vspace();
    }

    ###########
    unless ($sequencing_stats) {
        $stats_content .= vspace(2) . RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'Project Stats', class => "Search", newwin_form => 'NewWinForm' ) . " (select Project, viewing options at left)";

        $stats_content .= vspace(4) . RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'Date Range Summary', class => "Search", newwin_form => 'NewWinForm' ) . ' (for projects selected at left)';

        $stats_content .= vspace(4) . RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'Sequencer Stats', class => "Search", newwin_form => 'NewWinForm' ) . " (use 'Include Details' at left to include histograms)";

        $stats_content
            .= vspace(8)
            . RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'Reads Summary', class => "Search", newwin_form => 'NewWinForm' )
            . " (Reads, No Grows/Slow Grows, Warnings) - to be phased out (?)"
            . br()
            . radio_group( -name => 'SummaryType', -values => [ 'Weekly Update', 'Last N Days' ] )
            . &hspace(10)
            . " with N = "
            . textfield( -name => 'N', -size => 5, -default => '7' )
            . " (the longer the slower..)"
            . br()
            . hspace(10)
            . checkbox( -name => 'By Machine' )
            . br()
            . "(Defaults to Summary for all Production Libraries)";
    }

    my $Lib_stats_content = "(Choose Library at left)" . vspace(2);
    $Lib_stats_content .= Show_Tool_Tip( RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'Prep Summary', class => "Search", newwin_form => 'NewWinForm' ),
        'If no library/plates are provided, then plates created/prepared in the last 5 days will be returned.' );

    $Lib_stats_content .= &hspace(10)
        . Show_Tool_Tip( RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'Protocol Summary', class => "Search", newwin_form => 'NewWinForm' ),
        'If no library/plates are provided, then plates created/prepared in the last 5 days will be returned.' );

    $Lib_stats_content .= &vspace(5) . " ...for Plate Number(s):" . textfield( -name => 'Plate Number', -size => 6 ) . " eg: '1,4-6' for 1,4,5,6" . &hspace(5) . checkbox( -name => 'Inclusive', -label => 'Include Completed Plates', -checked => 1 );

    $Lib_stats_content
        .= &vspace(5)
        . '<B>If NO Library:</B> '
        . 'Include plates from last '
        . textfield( -name => 'Days_Ago', -default => 5, -size => 3 )
        . ' Days.'
        . vspace()
        . '<B>If Library chosen:</B> '
        . checkbox( -name => 'Details', -label => 'Include Summary Details', -checked => 1 );

    $Lib_stats_content
        .= vspace(12) . RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'Stock Used', class => "Search", newwin_form => 'NewWinForm' ) . ' (for chosen Project or Library) ' . br . checkbox( -name => 'Include Reagent List' );

    $Lib_stats_content .= "</form>";

    $specify->Set_Row(     [$specify_content] );
    $stats_table->Set_Row( [$stats_content] );

    $Lib_specify->Set_Row(     [$Lib_specify_content] );
    $Lib_stats_table->Set_Row( [$Lib_stats_content] );

    ###Put the stuff into layers...

    # my $stats_output = start_barcode_form('status','StatusHome');
    my $stats_output = start_custom_form( -form => 'StatusHome', -parameters => { &Set_Parameters('status') } );

    $stats_output .= &Views::Table_Print(
        content => [ [ $specify->Printout(0), "<img src='/$URL_dir_name/$image_dir/right_arrow.png'>", $stats_table->Printout(0) ], [ $Lib_specify->Printout(0), "<img src='/$URL_dir_name/$image_dir/right_arrow.png'>", $Lib_stats_table->Printout(0) ] ],
        print => 0,
        valign => 'centre'
    );
    $stats_output .= end_form();

    print $stats_output;

    return 1;
}
#################################       done
sub library_status {
########################
    # Generate Information on Libraries (Reads, No Grows, Slow Grows, Warnings)
    #
    # (displayed header for 'prep_status' - or may be viewed for multi-libraries)
########################
    my %args = &filter_input( \@_, -args => [ 'library', 'plate_number', 'project', 'machine', 'include', 'since', 'until', 'file', 'title' ] );
    my $dbc          = $args{-dbc} || $Connection;
    my $lib          = $args{-library};                                # Library
    my $plate_number = $args{-plate_number};                           # source plate number
    my $Project      = $args{-project};                                # Project name (or type eg. 'EST Projects')
    my $Pipeline     = $args{-pipeline};
    my $machine      = $args{-machine};
    my $include      = $args{-include} || param('Include Details');    # flag indicating whether to include test runs / billable runs etc.
    my $date_min     = $args{-since};                                  # specify Date AFTER date_min
    my $date_max     = $args{ -until };                                # specify Data BEFORE date_max
            my $Fname = $args{-file};                                  # specify Filename for output Graph/Table
            my $title = $args{-title};                                 # specify Title for output
            my $include_details;
            my $note;
            my $output;

            unless ($title) { print HTML_Dump( \%args ); return; }
    Message("(Excluded Failed Runs and No Grows from Summary numbers below)");

    ############### Creating Output Message ##################
    if ($include) {
        $include_details = 'hist, medianQ20';
    }
    if ( $include =~ /(Billable|TechD)/i ) {
        if ( $include =~ /Billable/i && $include =~ /TechD/i ) { $note = "(only Billable Runs - including TechD)" }
        elsif ( $include =~ /Billable/i ) { $note = "(only non-TechD Billable Runs Included)"; }
        else                              { $note = "(only TechD Billable Runs Included)"; }
    }
    elsif ( $include !~ /Test/ ) {
        if ( $Project eq 'All Projects' ) { $Project = "Production Projects"; }
        $note = "(Test Runs NOT included)";
    }
    else { $note = "(Test Runs Included)"; }
    Message($note);
    $Fname ||= "Table";
    my $filename = "$URL_temp_dir/$Fname.html";    # Should be moved to something like /home/sequence/www/htdocs/stats/ ???

    ############### Date Condition ##################
    my $t1 = new Benchmark;
    my $dc_seq;
    $title .= "<BR><span class='small'>";

    if ($date_min) {
        $dc_seq = " and Run_DateTime > \"$date_min\"";
        $title .= " $date_min < ";
    }
    if ($date_max) {
        $dc_seq .= " and Run_DateTime <= \"$date_max\"";
        $title .= " DATE < $date_max ", br();
    }

    ######### Test run inclusion condition ###########
    my $ec;    ## equipment condition...##########
    if ( $machine || param('Sequencer') ) {
        my $equip = $machine || param('Sequencer');
        if ( $equip =~ /equ(\d+)/i ) { $equip = $1; }
        $ec = " and RunBatch.FK_Equipment__ID in ($equip) ";
        $output .= &Heading("Results for Sequencer: Equ$equip");
    }

    my $pc;    ### plate condition
    $plate_number = &extract_range( -list => $plate_number );
    if ($plate_number) { $pc .= "  AND Plate_Number in ($plate_number)"; }

    if ($Pipeline) {
        my $Pipeline_ids = Cast_List( -list => $dbc->get_FK_ID( 'FK_Pipeline__ID', $Pipeline ), -to => 'string' );
        if ($Pipeline_ids) {
            my $daughter_pipelines = join ',', alDente::Pipeline::get_daughter_pipelines( -dbc => $dbc, -id => $Pipeline_ids, -include_self => 1 );
            $pc .= " AND Plate.FK_Pipeline__ID IN ($daughter_pipelines)";
        }
    }

    ########## generate library list if applicable ############

    my $ids;
    my $list_type   = "Library";
    my $id_field    = "FK_Library__Name";              ## Left(Run_Directory,5)";
    my $more_fields = "FK_Library__Name as Library";
    my $order_by    = 'FK_Library__Name';
    if ( param('By Machine') ) {
        $id_field = "RunBatch.FK_Equipment__ID";
        $ids      = join ',',
            $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
            'Equipment_ID', "WHERE Category = \"Sequencer\" AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID" );

        $list_type = "Sequencer";
        $title .= "(By Machine)";
        $more_fields = "Equipment_Name";
        $order_by    = 'Equipment_Name';
    }
    elsif ($lib) {
        $ids = "\"$lib\"";
        $title .= "(By Library)";
    }
    elsif ( $Project eq 'All Projects' ) {
        $ids = join '","', $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID" );
        $ids = "\"$ids\"";
    }
    elsif ( $Project eq 'Production Projects' ) {
        $ids = join '","', $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID" );
        $ids = "\"$ids\"";
    }
    elsif ( $Project =~ /(.*) Projects/ ) {
        my $type = $1;

        #	"Looking for type: $type";
        $ids = join '","', $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID" );
        $ids = "\"$ids\"";
    }
    elsif ($Project) {
        my $project_list = Cast_List( -list => $Project, -to => 'string', -autoquote => 1 );
        if ($project_list) {
            $ids = join '","', $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID and Project_Name IN ($project_list)" );
            $ids = "\"$ids\"";
        }
    }

    my $idc;
    if ($ids) { $idc = " and $id_field in ($ids)"; }

    if ( $id_field =~ /Run_Directory/ ) {
        $output .= h2("$Project");
    }
    else {

        # $output.= br() ."Sequencers: Equ($ids)". br();
    }

    ############### Generate Table ########################3

    my @warnings = get_enum_list( $dbc, 'Clone_Sequence', 'Read_Warning' );
    my @errors   = get_enum_list( $dbc, 'Clone_Sequence', 'Read_Error' );
    $title .= "</span>";

    #  Message("Condition: $idc $pc $ec $dc_seq");

    my $Stats = alDente::Run_Statistics->new( -dbc => $dbc );
    $output .= $Stats->summary(
        -condition   => "$idc $pc $ec $dc_seq",
        -group_by    => $id_field,
        -more_fields => $more_fields,
        -include     => $include,
        -show        => 'warnings,errors,stats,growth',
        -highlight   => [ 'Runs', 'Reads', 'Avg_Q20', 'Lib', 'Equipment_Name', 'NGs' ],
        -order_by    => $order_by,
        -show        => $include_details,
        -title       => $title
    );
    return $output;
}
#################################       done
sub capillary_status {
###############################
    my $machine = shift;
    my $dbc     = $Connection;
    Message("DEACTIVATED... Please inform the LIMS team if you need this page");
    return;

    my $equipment     = alDente::Equipment->new( -dbc        => $dbc );
    my $sequencer_ref = $equipment->get_sequencer_list( -dbc => $dbc );
    my @sequencers = @$sequencer_ref if $sequencer_ref;

    my $stats_file = 'Project_Stats';

    my $billable_only = grep /(billable)/i, param('Include Runs');
    my $include_test = param('Include Test Runs') || ( grep /(everything|test)/i, ( param('Include Runs') ) );

    if ($include_test) {
        $stats_file .= '/All';
    }
    elsif ($billable_only) {
        $stats_file .= '/Billable';
    }
    else {
        $stats_file .= '/Production';
    }

    my $StoreStats = &RGTools::RGIO::load_Stats( $stats_file, $Stats_dir );

    #
    my $remove_zero = param('Remove Zero');

    print h2("Summary of Capillary Read Quality by Machine (over last 4 months)");
    foreach my $machine (@sequencers) {
        my $this_machine;
        my $id;
        if ( $machine =~ /Equ(\d+): (.*)/ ) { $id = $1; $this_machine = $2; }
        else                                { next; }

        my ($changed) = $dbc->Table_find( 'Equipment,Maintenance,Maintenance_Process_Type',
            'max(Maintenance_DateTime)', "WHERE FK_Equipment__ID=Equipment_ID and Equipment_ID=$id and FK_Maintenance_Process_Type__ID=Maintenance_Process_Type_ID AND Process_Type_Name like 'Change Capillary Array'" );
        print &Views::Heading("$this_machine  (Last Changed: $changed)");

        #	print "\n<BR><B>Last Changed: $changed</B>";

        my $LAvg = $StoreStats->{Cap_LAvg};
        my $LSum = $StoreStats->{Cap_LSums};
        my $QAvg = $StoreStats->{Cap_QAvg};
        my $QSum = $StoreStats->{Cap_QSums};

        ( my $img1, my $zeros1, my $max1 ) = &alDente::Data_Images::generate_run_hist(
            data        => $LAvg->{$id},
            filename    => "Cap_LAvg_Equ$id.png",
            remove_zero => $remove_zero
        );
        ( my $img2, my $zeros2, my $max2 ) = &alDente::Data_Images::generate_run_hist(
            data        => $LAvg->{$id},
            filename    => "Cap_LSum_Equ$id.png",
            remove_zero => $remove_zero
        );

        ( my $img3, my $zeros3, my $max3 ) = &alDente::Data_Images::generate_run_hist(
            data        => $LAvg->{$id},
            filename    => "Cap_QAvg_Equ$id.png",
            remove_zero => $remove_zero
        );

        ( my $img4, my $zeros4, my $max4 ) = &alDente::Data_Images::generate_run_hist(
            data        => $LAvg->{$id},
            filename    => "Cap_QSum_Equ$id.png",
            remove_zero => $remove_zero
        );

        if ($max2) {
            print "<P><B>Run Length Average</B> (max = ";
            print sprintf "%0.2f", $max1;
            print ")<BR>$img1", "<P><B>Total Reads</B> (max = " . RGTools::Conversion::number($max2) . ")<BR>";
            print "$img2<BR>";

            print "<HR><BR><B>Quality Length Average</B> (max = ";
            print sprintf "%0.2f", $max1;
            print ")<BR>$img3", "<P><B>Total contiguous Quality Reads</B> (max = " . RGTools::Conversion::number($max2) . ")<BR>";
            print "$img4<BR>";

            my @temp = @{ $StoreStats->{Cap_LAvg}->{$id} };
            my $caps = scalar(@temp);
            print "(capillaries 1..$caps)<BR>";
        }
        else { print "<P>(No capillary Data at this time)<BR>"; }
    }
    return 1;
}
#################################       done
sub all_lib_status {
#################################
    #   Call library_status routine, specifying Projects and/or Libraries chosen
    #   Getting input parameters from param or args
#################################
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $lib  = param('Library Status');
    if ( $lib =~ /(.*):/ ) { $lib = $1; }
    my $Pnum = param('Plate Number');

    my $Project  = get_Table_Param( -dbc => $dbc, -table => 'Project', -field => 'Project_Name' );
    my $Ptype    = param('Project Type');
    my $Pipeline = get_Table_Param( -dbc => $dbc, -table => 'Plate', -field => 'FK_Pipeline__ID' );

    my $include_runs = param('Include Runs') || $args{-include_runs};
    my $billable_yes   = grep /(billable)/i, ($include_runs);
    my $billable_techD = grep /(techD)/i,    ($include_runs);

    my $test_runs    = param('Include Test Runs') || ( grep /(everything|test|all)/i, ($include_runs) );
    my $machine      = param('Sequencer');
    my $summary_type = param('SummaryType');
    my $since        = $args{-from};
    my $until        = $args{-to};
    my $num          = param('N');
    $summary_type = &_get_summary_type( -from => $since, -to => $until, -type => $summary_type, -number => $num, -last_two_days => ( param('Last 2 Days') ) );

    my $output;
    if    ( $Ptype    && !$lib ) { $Project = "$Ptype Projects"; }
    elsif ( !$Project && !$lib ) { $Project = "All Projects"; }
    elsif ($machine) { }
    my $include;
    if ($test_runs)      { $include .= "Test_Runs " }
    if ($billable_yes)   { $include .= "Billable " }
    if ($billable_techD) { $include .= "TechD " }

    ####### deciding out put based on summary type (last 2 weeks, last 2days or last N days)

    if ( $summary_type =~ /Weekly/i ) {
        ( my $week_end ) = &week_end_date();
        $week_end .= " 00:00:00";
        ( my $last_week_end ) = &week_end_date(1);
        $last_week_end .= " 00:00:00";
        ( my $last2_week_end ) = &week_end_date(2);
        $last2_week_end .= " 00:00:00";
        $output         .= h2("Last Weeks Data (until Sunday at midnight)..");
        $output         .= &library_status(
            -library      => $lib,
            -plate_number => $Pnum,
            -project      => $Project,
            -pipeline     => $Pipeline,
            -machine      => $machine,
            -include      => $include,
            -since        => $last_week_end,
            -until        => $week_end,
            -file         => "Table1",
            -title        => "Data from last week (until Sunday at midnight)"
        );

        $output .= h2("The Previous Weeks Data...");
        $output .= &library_status(
            -library      => $lib,
            -plate_number => $Pnum,
            -project      => $Project,
            -pipeline     => $Pipeline,
            -machine      => $machine,
            -include      => $include,
            -since        => $last2_week_end,
            -until        => $last_week_end,
            -file         => "Table2",
            -title        => "Data from Week before Last"
        );
    }
    elsif ( $summary_type eq 'Last 2 Days' ) {
        $output .= h2("Todays Data");
        $output .= &library_status(
            -library      => $lib,
            -plate_number => $Pnum,
            -project      => $Project,
            -pipeline     => $Pipeline,
            -machine      => $machine,
            -include      => $include,
            -since        => &today() . " 00:00:00",
            -until        => &now(),
            -file         => "Table1",
            -title        => "Data from today (from midnight)"
        );
        $output .= h2("Yesterday's Data...");
        $output .= &library_status(
            -library       => $lib,
            -plate_numbeer => $Pnum,
            -project       => $Project,
            -pipeline      => $Pipeline,
            -machine       => $machine,
            -include       => $include,
            -since         => &today(-1) . " 00:00:00",
            -until         => &today() . " 00:00:00",
            -file          => "Table2",
            -title         => "Data from Yesterday (until midnight)"
        );
    }
    elsif ( $summary_type =~ /Last (\d+)/ ) {
        my $days = $1;
        $output .= h2("$Project Reads over Last $days Days");

        $output .= &library_status(
            -library      => $lib,
            -plate_number => $Pnum,
            -project      => $Project,
            -pipeline     => $Pipeline,
            -machine      => $machine,
            -include      => $include,
            -since        => &today( "-$days" . 'd' ) . " 00:00:00",
            -until        => &now(),
            -file         => "Table1",
            -title        => "$Project Data from past $days Days"
        );
    }
    else {
        Message("use 'Project Stats' to get long term statistics");
        $output .= "(or select Time Period for Reads Summary..)";
        return $output;
        library_status(
            -library      => $lib,
            -plate_number => $Pnum,
            -project      => $Project,
            -pipeline     => $Pipeline,
            -machine      => $machine,
            -include      => $include,
            -file         => "Table"
        );
    }

    return $output;
}
#################################       done
sub Project_Stats {
#########################
    #
    # General status of Projects
    #
    # - run this routine daily to generate up-to-date html tables that can be loaded very quickly...
    #
#################################
    my %args            = @_;
    my $dbc             = $args{-dbc} || $Connection;
    my $project_list    = $args{-id};
    my $details         = $args{-details} || param('Include Details');
    my $cached          = $args{-cached} || param('Retrieve from Cache') || 0;
    my $remove_zero     = $args{-remove_zeros} || param('Remove Zero');
    my $library         = $args{-library};
    my $pipeline        = $args{-pipeline};
    my $group_by        = $args{-group_by} || '';
    my $library_type    = param('Library Type') || $args{-library_type};
    my $days_since      = param('Since') || param('from_date_range') || $args{-from};
    my $days_until      = param('Until') || param('to_date_range') || $args{-to};
    my $include         = param('Include Runs') || $args{-include};
    my $group_projects  = $args{-combine} || param('Group Projects') || 0;
    my $extra_condition = $args{-condition} || param('Extra Condition') || 1;
    my $hist            = $details;                                                     ## <CONSTRUCTION> - separate the histogram and warning options from the details
    my $warnings        = 0;                                                            ## <CONSTRUCTION> - separate the histogram and warning options from the details
    my $regenerate      = 0;                                                            # flag to indicate that histograms should be regenerated (even if cached file exists)
                                                                                        #my $tables      = 'SequenceAnalysis,SequenceRun,Run,Project,Plate,Library,Vector_Based_Library,RunBatch,Equipment';
      #my $join_condition = "SequenceAnalysis.FK_SequenceRun__ID=SequenceRun_ID AND FK_Run__ID=Run_ID AND FK_Project__ID=Project_ID AND FK_RunBatch__ID=RunBatch_ID AND FK_Equipment__ID=Equipment_ID AND FK_Plate__ID=Plate_ID AND Plate.FK_Library__Name=Library_Name AND Vector_Based_Library.FK_Library__Name=Library_Name";
    my $tables
        = 'SequenceAnalysis,SequenceRun,Run,Project,Plate,Library,RunBatch,Equipment LEFT JOIN Vector_Based_Library ON Vector_Based_Library.FK_Library__Name=Library_Name LEFT JOIN Work_Request ON Plate.FK_Work_Request__ID=Work_Request_ID LEFT JOIN Funding ON Work_Request.FK_Funding__ID=Funding_ID';
    my $join_condition
        = "SequenceAnalysis.FK_SequenceRun__ID=SequenceRun_ID AND FK_Run__ID=Run_ID AND FK_Project__ID=Project_ID AND FK_RunBatch__ID=RunBatch_ID AND FK_Equipment__ID=Equipment_ID AND FK_Plate__ID=Plate_ID AND Plate.FK_Library__Name=Library_Name";

    if ( $details && !$project_list && !$library && !$library_type && !$days_since ) {
        $dbc->warning("Please select Projects of interest if you are generating details.  (loading time issue)");
        &status_home($dbc);
        return '';
    }

    my $homelink = $dbc->homelink();

    my $title = "Project";
    my $group_order;
    my $group_field = 'Project_Name';    ## default value...
    my $group_label;
    my $group_title = "Project";

    if ( $group_by =~ /library/i ) {
        $group_field = "Library_Name";    #CASE WHEN Library_Status = 'Complete' THEN concat(Library_Name,' - (',Library_Status,': ',Left(Max(Run_DateTime),10),')') ELSE concat(Library_Name,' - (',Library_Status,')') END";
        if ($details) { $group_label = 'Library_Status'; }
        else {
            ## can only use MAX function when grouping, but grouping NOT done when extracting details... ##
            $group_label = "concat(CASE WHEN Library_Status = 'Complete' THEN concat(' (',Library_Status,': ',Left(Max(Run_DateTime),10),')') ELSE concat(' (',Library_Status,')') END , '<BR>', Library_FullName)";
        }

        #$group_label = "Library_FullName";
        $group_title = "Library - (Status)";
    }
    elsif ( $group_by =~ /project/i ) {
        $group_field = "Project_Name";
        $group_label = "";
        $group_title = "Project";
    }
    elsif ( $group_by =~ /month/i ) {
        $group_field = "Left(Run_DateTime,7)";
        $group_label = "Left(Run_DateTime,7)";
        $group_title = "Month";
    }
    elsif ( $group_by =~ /machine/i ) {
        $group_field = "FK_Equipment__ID";
        $group_label = "Equipment_Name";
        $group_title = "Sequencer";
    }
    elsif ( $group_by =~ /sow/i ) {
        $group_field = 'Funding_Name';
        $group_label = 'Funding_Name';
        $group_title = 'SOW';
    }

    my $output      = "(Excluded Failed Runs from Statistics below)";
    my $table_index = 1;
    my $summary     = 0;
    my $suffix;
    if ($details) { $suffix .= ".plus"; }
    else          { $summary = 1; $suffix .= ".plain"; }
    if   ($summary) { $suffix .= ".summary"; }
    else            { $suffix .= ".wlibs"; }

    if ( $details && $project_list =~ /,/ ) {
        $output .= show_Project_info( -dbc => $dbc, -project_id => $project_list, -group_by => 'Project', -include => $include, -include_summary => 1 );
    }

    unless ($project_list) { $project_list = join ',', $dbc->Table_find( 'Project', 'Project_ID' ); }
    my @projects = split ',', $project_list;
    my @warning_options = &get_enum_list( $dbc, 'Clone_Sequence', 'Read_Warning' );
    my %Notes;

    my $base_condition = "Run_Status = 'Analyzed'";

    if ($library) {
        my $lib_list = Cast_List( -list => $library, -to => 'string', -autoquote => 1 );
        $base_condition .= " AND Library_Name in ($lib_list)";
    }
    if ($library_type) {
        my $lib_types = Cast_List( -list => $library_type, -to => 'string', -autoquote => 1 );
        $extra_condition .= " AND (Vector_Based_Library_Type IN ($lib_types) OR Library_Type IN ($lib_types))";
    }
    if ( $pipeline && ( $pipeline !~ /all/i ) ) {
        $title          .= " for selected Pipeline(s)";
        $tables         .= ",Pipeline";
        $base_condition .= " AND Plate.FK_Pipeline__ID=Pipeline_ID";
        my $daughter_pipelines = join ',', alDente::Pipeline::get_daughter_pipelines( -dbc => $dbc, -id => $pipeline, -include_self => 1 );
        $extra_condition .= " AND Plate.FK_Pipeline__ID IN ($daughter_pipelines)";
    }
    else {
        Message("All pipelines included");
    }

    if ($days_since) {

        #	my $since = &date_time('-' . $days_ago .'d');
        $extra_condition .= " AND Run_DateTime >= '$days_since'";
        $title           .= " (since $days_since)";

        #	$regenerate = 1;  ## regenerate histograms since this data is a subset of cached data
    }
    if ($days_until) {
        $extra_condition .= " AND Run_DateTime <= '$days_until'";
        $title           .= " (until $days_until)";
    }

    my ( $run_condition, $run_condition_message, $run_suffix ) = get_run_condition( 1, 'Run_DateTime', -include => $include, -from => $days_since, -to => $days_until );

    if ($run_condition) {
        $extra_condition .= " AND $run_condition";
        $regenerate = 1;
    }
    $title .= $run_condition_message;

    my @project_ids;
    if ( $project_list =~ /^[\d\s\,]+$/ ) {
        ## only id list...
        @project_ids = split ',', $project_list;
    }
    elsif ( !$project_list ) {
        ### first try to get cached version...
        if ($cached) {
            if ( -e "$alDente::SDB_Defaults::URL_temp_dir/Project_All_Status$suffix.html" ) {
                $output .= try_system_command("cat $alDente::SDB_Defaults::URL_temp_dir/Project_All_Status$suffix.html");
                $output .= "<BR><span class='small'>(retrieved from cache..)</span><BR>";
                return $output;
            }
            else {
                Message("Cached Data not available... searching database...<BR>");
            }
        }

        #### otherwise get info for ALL projects... ###
        my @project_info = $dbc->Table_find( 'Project', 'Project_ID,Project_Name', 'Order by Project_Name' );
        foreach my $proj_info (@project_info) {
            my ( $id, $name ) = split ',', $proj_info;
            push( @projects,    $name );
            push( @project_ids, $id );
        }
    }
    else {
        my $project_names = join "','", @projects;
        @project_ids = $dbc->Table_find( 'Project', 'Project_ID', "WHERE Project_Name in ('$project_names') Order by Project_Name" );
    }

    my $project_idlist = join ',', @project_ids;

    unless ( $project_ids[0] =~ /\d+/ ) {
        Message("No Valid Project Specified ($project_list)");
        return 0;
    }

    my @Header = ($group_title);
    push(
        @Header,
        (   'Runs<BR>Completed', 'Total Reads', 'Total BPs',
            'Q20<BR><Font color=red>AVG</Font><BR>total',
            'QLength<BR><Font color=red>AVG</Font><BR>total',
            'QV (vector)<BR><Font color=red>AVG</Font><BR>total',
            'Run Length (BPs)<BR><Font color=red>AVG</Font><BR>total',
            '<Font color=red>Success Rate</Font><BR>(trimmed >= 100)<BR>(Reads)'
        )
    );

    push( @Header, 'Median<BR>Q20' ) if ($details);
    if ($hist) { push( @Header, "Q20 Histogram<BR>(Production Runs)" ) }

    my $Project_Info = HTML_Table->new();
    $extra_condition .= " AND Project_ID IN ($project_idlist)" if $project_idlist;
    my @fields;
    my $condition = "WHERE $join_condition AND $base_condition AND $extra_condition";
    my $group     = "Project_Name,Library_Name";

    $extra_condition =~ s/(^| )1 AND //g;    ## remove unnecessary inclusion of '1' condition for feedback...

    #   $output .= "<P>Conditions: $extra_condition<P>";

    ### can only group results if details NOT required ###
    if ( !$group_projects ) {
        $group_order = " Project_Name";
        $group_order .= ",$group_field" if ($group_field);
    }
    elsif ($group_field) {
        $group_order = $group_field;
    }
    else { $group_order = 'Project_Name'; }

    if ( $details || $warnings ) {
        ### include Median and Histogram in Header.. (but NOT count...
        @fields = (
            'Project_ID', 'Project_Name as Project',
            'Library_Name', 'Library_FullName', 'Wells as Read_Count',
            'NGs as NGs', "SLTotal as Total_BPs",
            "Q20total", "SLtotal", "Q20array", "AllReads", "AllBPs",
            "RecurringStringWarnings as Recur",
            "ContaminationWarnings as Contam",
            "VectorSegmentWarnings as VS",
            "PoorQualityWarnings as PQ",
            "VectorOnlyWarnings as VO",
            'Run_ID', 'QLtotal', 'QVtotal', 'successful_reads as successful'
        );
    }
    else {
        ### forget about Q20array, and group stuff if details not required...
        @fields = (
            'count(*) as Count',
            'Project_ID',
            'Project_Name as Project',
            'Library_Name',
            'Library_FullName',
            'sum(Wells) as Read_Count',
            'sum(NGs) as NGs',
            "sum(SLTotal) as Total_BPs",
            "sum(Q20total) as Q20total",
            "sum(SLtotal) as SLtotal",
            "sum(AllReads) as AllReads",
            "sum(AllBPs) as AllBPs",
            "sum(RecurringStringWarnings) as Recur",
            "sum(ContaminationWarnings) as Contam",
            "VectorSegmentWarnings as VS",
            "PoorQualityWarnings as PQ",
            "VectorOnlyWarnings as VO",
            "sum(QLtotal) as QLtotal",
            "sum(QVtotal) as QVtotal",
            "sum(successful_reads) as successful"
        );
        $condition .= " GROUP BY $group_order" if $group_order;
    }
    $condition .= " ORDER BY $group_order" if $group_order;

    if ($group_by) {
        push( @fields, "$group_field as group_field" ) if ($group_field);
        push( @fields, "$group_label as group_label" ) if ($group_label);
    }
    if ($details) { push( @fields, 'Q20array' ) }

    my %Summary = &Table_retrieve( $dbc, $tables, \@fields, "$condition" );

    $Benchmark{query_done} = new Benchmark;
    my $index           = 0;
    my $lastproject     = $Summary{Project}[0] || '';
    my $lastproject_id  = $Summary{Project_ID}[0] || 0;
    my $last_group      = $Summary{group_field}[0] || '';
    my $last_group_name = $Summary{group_label}[0] || '';

    my @Ldata = ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
    my @Lbins = ();
    my @Pdata = ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
    my @Pbins = ();
    my @Tdata = ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
    my @Tbins = ();

    my $shown = 0;
    if ($lastproject_id) {
        $Project_Info->Set_Headers( \@Header );
        $Project_Info->Set_Class('small');
        if ($details) {
            $Project_Info->Set_Title("$lastproject $title");
            _sub_header( $Project_Info, $details, $warnings );

            #	    $output .= show_Project_info(-dbc=>$dbc,-project_id=>$lastproject_id,-include=>$include,-include_summary=>!$shown++);
        }
        else {
            if   ( int(@project_ids) == 1 ) { $Project_Info->Set_Title("$Summary{Project}[0] $title Summary"); }    ## if only 1 project
            else                            { $Project_Info->Set_Title("$title Summary") }                          ## multiple projects
            _sub_header( $Project_Info, $details, $warnings );
        }
    }
    else {
        Message("No results matching the search criteria");
    }

    ## Define characteristics of output table structure ##
    my @data_list = ( 'Reads', 'Total_Reads', 'No_Grows', 'Runs', 'Q20', 'Qtrimmed', 'QVector', 'SL', 'successful', 'BPs', 'Contamination', 'Recurring_String', 'Poor_Quality', 'Vector_Segment', 'Vector_Only' );
    my @averages = ( 'Q20', 'Qtrimmed', 'QVector', 'BPs', 'SL' );
    my @percentages = ('successful');
    my @medians     = ('Q20');
    my @row         = ( '<<TITLE>>', '<<Runs>>', '<<Reads>> total<BR>(+ <<No_Grows>> NGs)', '<<BPs>>', _avg_view( [ 'Q20', 'Qtrimmed', 'QVector', 'SL' ] ), _percent_view( ['successful'] ) );

    if ($details) { push( @row, "<<MEDIAN_Q20>>" ) }
    if ($hist)    { push( @row, "<<FILE>>" ) }
    if ($warnings) {
        my $warning_msg = "<B><Font color=red>Warning_Msg:</Font></B><BR>";
        $warning_msg .= "<B>Contam</B>:<<Contamination>><BR>";
        $warning_msg .= "<B>Recurring_Str</B>:<<Recurring_String>><BR>";
        $warning_msg .= "<B>Poor_Quality</B>:<<Poor_Quality>><BR>";
        $warning_msg .= "<B>Vector_Only</B>:<<Vector_Only>><BR>";
        $warning_msg .= "<B>Vector_Segment</B>:<<Vector_Segment>><BR>";
        push( @row, $warning_msg );
    }

    my $bytes = 2;    ## unpack with '*S'

    my $bins;
    my @data;
    my @Q20;
    my $projects = 0;

    while ( defined $Summary{Project_ID}[$index] ) {
        my $project_id   = $Summary{Project_ID}[$index];
        my $project_name = $Summary{Project}[$index];
        my $library      = $Summary{Library_Name}[$index] || '';

        #	my $library_name = $Summary{Library_FullName}[$index] || '';
        my $this_group = $Summary{group_field}[$index] || '' if ($group_by);
        my $this_group_name = $Summary{group_label}[$index] if ($group_by);

        my $addruns = Extract_Values( [ $Summary{Count}[$index], 1 ] );
        my $runs += $addruns;
        my $reads    = $Summary{Read_Count}[$index] || 0;
        my $NGs      = $Summary{NGs}[$index]        || 0;
        my $Q20      = $Summary{Q20total}[$index]   || 0;
        my $Qtrimmed = $Summary{QLtotal}[$index]    || 0;
        my $QV       = $Summary{QVtotal}[$index]    || 0;
        my $SL       = $Summary{SLtotal}[$index]    || 0;
        my $Q20array = $Summary{Q20array}[$index] if ( $details || $hist || $warnings );
        my $success = $Summary{successful}[$index] || 0;
        my $success_rate = sprintf "%0.1f", 0;
        $success_rate = sprintf "%0.1f", $success / $reads if $reads;

        my $all_reads = $Summary{AllReads}[$index] || 0;
        my $all_BPs   = $Summary{AllBPs}[$index]   || 0;

        my $Cwarnings  = $Summary{Contam}[$index] || 0;
        my $RSwarnings = $Summary{Recur}[$index]  || 0;
        my $PQwarnings = $Summary{PQ}[$index]     || 0;
        my $VSwarnings = $Summary{VS}[$index]     || 0;
        my $VOwarnings = $Summary{VO}[$index]     || 0;

        $bins = $Q20array;
        $index++;

        ### ensure empty bins above match number ###
        @data = ( $reads, $all_reads, $NGs, $runs, $Q20, $Qtrimmed, $QV, $SL, $success, $all_BPs, $Cwarnings, $RSwarnings, $PQwarnings, $VSwarnings, $VOwarnings );
        #### amalgamate Libraries if last of list ####
        my $hist_file;

        my $condition;
        &SDB::HTML::combine_records(
             undef, undef, \@data, \@Tdata, [$bins], \@Tbins, $Project_Info, 'add', $details,
            -data_list   => \@data_list,
            -averages    => \@averages,
            -percentages => \@percentages,
            -medians     => \@medians,
            -row         => \@row,
            -bytes       => 2
        );
        if ($group_by) {
            if ( $this_group !~ /^$last_group$/ ) {
                my $label = $last_group_name;
                if ( $group_by =~ /library/i ) {
                    $label = &Link_To( $homelink, "<B>$last_group</B>", "&Scan=1&Barcode=$last_group", $Settings{LINK_COLOUR}, ['newwin'] );
                    $label .= " $last_group_name" unless ( $last_group =~ /$last_group_name/ );
                    $hist_file = $regenerate ? "Lib.$last_group." . timestamp . '.png' : "Q20_Distributions/Library/Q20Hist_Lib$last_group.Summary.png";
                    $condition = "= '$last_group'";
                }
                else {
                    $hist_file = "Grp$last_group." . timestamp . ".png";
                }
                unless ( $group_by =~ /project/i ) {
                    &SDB::HTML::combine_records(
                         $hist_file, $label, \@data, \@Ldata, [], \@Lbins, $Project_Info, 'summary', $details,
                        -data_list   => \@data_list,
                        -averages    => \@averages,
                        -percentages => \@percentages,
                        -medians     => \@medians,
                        -row         => \@row,
                        -bytes       => 2,
                        -regenerate  => $regenerate
                    );
                    @Ldata = ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
                    @Lbins = ();
                    &SDB::HTML::combine_records(
                         $hist_file, $label, \@data, \@Ldata, [$bins], \@Lbins, $Project_Info, 'add', $details,
                        -data_list   => \@data_list,
                        -averages    => \@averages,
                        -percentages => \@percentages,
                        -medians     => \@medians,
                        -row         => \@row,
                        -bytes       => 2
                    );
                }
                $last_group      = $this_group;
                $last_group_name = $this_group_name;
                $last_group_name = $this_group_name;
            }
            else {
                &SDB::HTML::combine_records(
                     undef, undef, \@data, \@Ldata, [$bins], \@Lbins, $Project_Info, 'add', $details,
                    -data_list   => \@data_list,
                    -averages    => \@averages,
                    -percentages => \@percentages,
                    -medians     => \@medians,
                    -row         => \@row,
                    -bytes       => 2
                );
            }
        }

        #### amalgamate Projects if last of list ####
        if ( ( $project_name ne $lastproject ) && ( $group_order =~ /^\s*project/i ) ) {

            #	    $hist_file = "Q20_Distributions/Projects/Q20Hist_Proj$lastproject_id.Summary.png";
            $hist_file = $regenerate ? "Proj.$lastproject_id." . timestamp . '.png' : "Q20_Distributions/Projects/Q20Hist_Proj$lastproject_id.Summary.png";
            $condition = "FK_Project__ID = $lastproject_id";
            my $label = &Link_To( $homelink, "<B>$lastproject</B>", "&Info=1&Table=Project&Field=Project_ID&Like=$lastproject_id", $Settings{LINK_COLOUR}, ['newwin'] );
            &SDB::HTML::combine_records(
                 $hist_file, "$label Project", \@data, \@Pdata, [], \@Pbins, $Project_Info, 'summary', $details, 'lightgreenbw',
                -data_list   => \@data_list,
                -averages    => \@averages,
                -percentages => \@percentages,
                -medians     => \@medians,
                -row         => \@row,
                -bytes       => 2,
                -regenerate  => $regenerate
            );
            @Pdata = ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
            @Pbins = ();
            &SDB::HTML::combine_records(
                 $hist_file, "$label Project", \@data, \@Pdata, [$bins], \@Pbins, $Project_Info, 'add', $details,
                -colour      => 'lightgreenbw',
                -data_list   => \@data_list,
                -averages    => \@averages,
                -percentages => \@percentages,
                -medians     => \@medians,
                -row         => \@row,
                -bytes       => 2
            );
            $projects++;
            $lastproject    = $project_name;
            $lastproject_id = $project_id;

            if ( $details && ( $group_by !~ /project/i ) ) {
                #### break up projects if details expected...
                $title = "$project_name $title";
                $output .= $Project_Info->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Project_Stats.$table_index.@{[timestamp()]}.html", $html_header );
                $output .= $Project_Info->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Project_StatsR.$table_index.xlsx",                 $html_header );
                $output .= $Project_Info->Printout(0);
                $table_index++;

                $Project_Info = HTML_Table->new();
                $Project_Info->Set_Headers( \@Header );
                $Project_Info->Set_Title("$project_name $title");
                _sub_header( $Project_Info, $details, $warnings );
                $Project_Info->Set_Class('small');
            }
        }
        else {
            &SDB::HTML::combine_records(
                 undef, undef, \@data, \@Pdata, [$bins], \@Pbins, $Project_Info, 'add', $details,
                -data_list   => \@data_list,
                -averages    => \@averages,
                -percentages => \@percentages,
                -medians     => \@medians,
                -row         => \@row,
                -bytes       => 2
            );
        }
    }

    my $hist_file = '';
    #### amalgamate Totals if last of list ####
    if ($group_by) {
        my $label = $last_group_name;
        if ( $group_by =~ /library/i ) {
            $label = &Link_To( $homelink, "<B>$last_group</B>", "&Scan=1&Barcode=$last_group", $Settings{LINK_COLOUR}, ['newwin'] );
            $label .= " $last_group_name" unless ( $last_group =~ /$last_group_name/ );
            $hist_file = $regenerate ? "Lib.$last_group." . timestamp . '.png' : "Q20_Distributions/Library/Q20Hist_Lib$last_group.Summary.png";
            $condition = "FK_Library__Name = '$last_group'";
        }
        else {
            $hist_file = "Grp$last_group." . timestamp . ".png";
        }
        unless ( $group_by =~ /project/i ) {
            &SDB::HTML::combine_records(
                 $hist_file, $label, \@data, \@Ldata, [], \@Lbins, $Project_Info, 'summary', $details,
                -data_list   => \@data_list,
                -averages    => \@averages,
                -percentages => \@percentages,
                -medians     => \@medians,
                -row         => \@row,
                -bytes       => 2,
                -regenerate  => $regenerate
            );
        }
    }

    my $label = &Link_To( $homelink, "<B>$lastproject</B>", "&Info=1&Table=Project&Field=Project_ID&Like=$lastproject_id", $Settings{LINK_COLOUR}, ['newwin'] );

    $hist_file = "Q20Hist_Proj$lastproject_id." . timestamp . ".Summary.png";
    $condition = "FK_Project__ID = $lastproject_id";

    &SDB::HTML::combine_records(
         $hist_file, $label, \@data, \@Pdata, [], \@Pbins, $Project_Info, 'summary', $details,
        -colour      => 'lightgreenbw',
        -data_list   => \@data_list,
        -averages    => \@averages,
        -percentages => \@percentages,
        -medians     => \@medians,
        -row         => \@row,
        -bytes       => 2,
        -regenerate  => $regenerate
    );

    $hist_file = "Q20Hist_Totals." . timestamp . ".Summary.png";
    &SDB::HTML::combine_records(
         $hist_file, "Totals", \@data, \@Tdata, [], \@Tbins, $Project_Info, 'summary', $details,
        -data_list   => \@data_list,
        -averages    => \@averages,
        -percentages => \@percentages,
        -medians     => \@medians,
        -row         => \@row,
        -bytes       => 2,
        -colour      => 'vvvlightgrey',
        -regenerate  => $regenerate
    ) unless ( $projects < 1 );

    $output .= $Project_Info->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Project_Stats.$table_index.@{[timestamp()]}.html", $html_header );
    $output .= $Project_Info->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Project_Stats.$table_index.@{[timestamp()]}.xlsx", $html_header );
    $output .= $Project_Info->Printout(0);
    $table_index++;

    return $output;

}
#################################       Done
sub get_run_condition {
########################
    #
    # Generate extra run condition based upon input parameters.
    #  eg. Days Ago, Since, Until, Approved, Billable, Production etc.
    #
########################
    my $extra_condition = shift || 1;
    my $date_field      = shift || 'Run_DateTime';
    my %args            = @_;

    my $since    = param('Since')        || $args{-from};
    my $until    = param('Until')        || $args{-to};
    my $inc_runs = param('Include Runs') || $args{-include};

    my $approved   = grep /^approved$/i,   $inc_runs;
    my $production = grep /^production$/i, $inc_runs;
    my $billable   = grep /^billable$/i,   $inc_runs;
    my $techd      = grep /^techD$/i,      $inc_runs;
    my $everything = grep /^everything$/i, $inc_runs;
    my $message    = '';
    my $suffix     = '';

    if ($everything) { $message .= " (Everything including Test Runs)" }
    else {
        if ($approved) {
            $extra_condition .= " AND Run_Validation = 'Approved' AND Run_Test_Status = 'Production'";
            $message         .= " approved";
            $suffix          .= '.appr';
        }
        if ($billable) {
            $extra_condition .= " AND Billable = 'Yes'";
            $message         .= " billable";
            $suffix          .= '.bill';
        }
        if ($production) {
            $extra_condition .= " AND Run_Test_Status = 'Production'";
            $message         .= " production";
            $suffix          .= '.prod';
        }
        if ($techd) {
            $extra_condition .= " AND Run_Test_Status = 'TechD'";
            $message         .= " techD";
            $suffix          .= '.techD';
        }
    }

    $message .= " runs" if $message;

    if ($since) {
        $extra_condition .= " AND $date_field >= '$since'";
        $message         .= " since $since";
    }
    if ($until) {
        $until = &end_of_day($until);
        $extra_condition .= " AND $date_field <= '$until'";
        $message         .= " until $until";
    }

    if ( $extra_condition eq '1' ) { $extra_condition = '' }
    return ( $extra_condition, $message, $suffix );
}
#################################       done
sub display_option_counts {
################################
    my $hash   = shift;
    my $keyref = shift;

    my @keys = @$keyref;

    my @counts;
    foreach my $key (@keys) {
        my $count = $hash->{$key};
        if ($count) {
            push( @counts, "$key:$count" );
        }
    }
    return join '<BR>', @counts;
}
#################################       Done
sub sequencer_stats {
###########################
    #
    # General status of equipment (Maintenance etc.)
    #
#################################
    my %args            = @_;
    my $dbc             = $args{-dbc} || $Connection;
    my $status          = '';
    my $remove_zero     = param('Remove Zero') || $args{-remove_zeros};
    my $hist            = param('Include Details') || $args{-include_details};
    my $from_date       = $args{-from};
    my $to_date         = $args{-to};
    my $extra_condition = param('Extra Condition') || $args{-extra_condition} || 1;
    my @pipeline_ids    = @{ get_Table_Params( -table => 'Plate', -field => 'FK_Pipeline__ID', -dbc => $dbc, -ref_field => 'FK_Pipeline__ID' ) };
    my @project_ids     = @{ get_Table_Params( -table => 'Project', -field => 'Project_Name', -dbc => $dbc, -ref_field => 'FK_Project__ID' ) };
    my $details         = $hist;
    my $title           = "Sequencer Stats (No Grows Excluded) ";
    my $include_runs    = param('Include Runs') || $args{-include_runs};                                                                            ##############
    my $include_test    = param('Include Test Runs') || ( grep /(everything|test)/i, ($include_runs) );
    my $billable_only   = grep /(billable)/i, ($include_runs);
    my $sequencer_eq_id = $args{-equipment_barcode};

    ## overwrite these params if the argument has been passed
    my $pipline_ref = $args{-pipelines};
    my $project_ref = $args{-projects};
    @pipeline_ids = @$pipline_ref if $pipline_ref;
    @project_ids  = @$project_ref if $project_ref;

    if ($include_test) {

    }
    elsif ($billable_only) {
        $status = " AND Billable = 'Yes' ";
        $title .= " (Billable Runs only - TechD EXcluded)";
    }
    else {
        $title  .= " (Production Runs Only)";
        $status .= "AND Run_Test_Status = 'Production'";
    }

    my $title_suffix;
    my $pp_condition = "WHERE FK_Library__Name=Library_Name AND FK_Plate__ID=Plate_ID AND FK_Project__ID=Project_ID";
    if (@project_ids) {
        my $project;
        if   ( int(@project_ids) > 1 ) { $project = 'Selected' }
        else                           { $project = get_Table_Param( -dbc => $dbc, -table => 'Project', -field => 'Project_Name' ) }    ### use actual project chosen if only one

        if ( $project_ids[0] ) {
            my $project_list = join ',', @project_ids;
            $pp_condition .= " AND Project_ID IN ($project_list)";
            $title_suffix .= " for $project Project(s) ($project_list)";
        }
    }
    if (@pipeline_ids) {
        if ( $pipeline_ids[0] ) {
            my $pipeline;
            if   ( int(@pipeline_ids) > 1 ) { $pipeline = 'Selected' }
            else                            { $pipeline = get_Table_Param( -dbc => $dbc, -field => 'FK_Pipeline__ID' ) }                ### use actual project chosen if only one
            if (@pipeline_ids) {

                # Message("Filtering on Pipeline");
                my $daughter_pipelines = join ',', alDente::Pipeline::get_daughter_pipelines( -dbc => $dbc, -id => \@pipeline_ids, -include_self => 1 );
                $pp_condition .= " AND Plate.FK_Pipeline__ID IN ($daughter_pipelines)";
                $title_suffix .= " using $pipeline Pipeline(s) ($daughter_pipelines)";
            }
        }
    }

    my $runs = join ',', $dbc->Table_find( 'Run,Plate,Library,Project', 'Run_ID', $pp_condition );
    $runs ||= 0;
    $status .= " AND Run_ID in ($runs)" if ( @project_ids || @pipeline_ids );

    my $pipeline_condition;
    my $days_since = param('Since') || $args{-from} || date_time( '-' . $alDente::SDB_Defaults::look_back . 'd' );

    ($extra_condition) = get_run_condition(
         $extra_condition, 'Run_DateTime',
        -from    => $from_date,
        -to      => $to_date,
        -include => $include_runs
    );
    $extra_condition ||= 1;

    my $Machine_Info = HTML_Table->new( -title => "$title $title_suffix", -border => 1, -class => 'small' );
    my @headers = ( 'Machine', 'Location', 'Completed', 'Pending', 'Aborted', 'Reads', 'Q20 Avg', 'SL Avg' );
    if ($hist) { push( @headers, 'Histogram (QL)<BR>(Production Runs)', 'Histogram (QL)<BR>(Production Runs)' ) }
    push( @headers, ( 'Runs', 'Reads', 'Avg Q20', 'Avg Length' ) );

    $Machine_Info->Set_sub_title( 'Overall Runs', 5, 'mediumgreenbw' );
    $Machine_Info->Set_sub_title( 'All Reads',    3, 'mediumbluebw' );
    if ($hist) { $Machine_Info->Set_sub_title( '-', 1, 'mediumbluebw' ) }
    $Machine_Info->Set_sub_title( "Filtered Runs Since $days_since", 6, 'lightyellowbw' ) if ($days_since);
    $Machine_Info->Set_Headers( \@headers );

    my $stamp = time();

    my @equipment;
    if ($sequencer_eq_id) {
        @equipment = $dbc->Table_find(
            'Equipment,Location,Stock,Stock_Catalog,Equipment_Category',
            'Equipment_ID,Equipment_Name,Equipment_Status,Location_Name',
            "WHERE FK_Location__ID=Location_ID AND Category='Sequencer' AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID And Equipment_ID IN ($sequencer_eq_id) "
        );
        unless (@equipment) {
            ## have to validate if it is in fact a sequencer
            Message "EQU$sequencer_eq_id is not a sequencer";
            return;
        }
    }
    else {
        @equipment = $dbc->Table_find(
            'Equipment,Location,Stock,Stock_Catalog,Equipment_Category',
            'Equipment_ID,Equipment_Name,Equipment_Status,Location_Name',
            "WHERE FK_Location__ID=Location_ID AND Category='Sequencer' AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID ORDER BY Equipment_Name"
        );
    }
    ######## Creating the table ##########
    foreach my $machine_info (@equipment) {
        my ( $id, $machine, $Estatus, $Elocation ) = split ',', $machine_info;
        my $base_conditions = "Run_Status='Analyzed'";
        my ($all_info) = $dbc->Table_find_array(
            'SequenceAnalysis,Equipment,SequenceRun,Run,RunBatch',
            [ 'count(*)', 'Sum(Wells)', 'Sum(Q20total)/Sum(Wells)', 'Sum(SLtotal)/Sum(Wells)' ],
            "WHERE FK_SequenceRun__ID=SequenceRun_ID AND FK_Run__ID=Run_ID AND RunBatch.FK_Equipment__ID=Equipment_ID and FK_RunBatch__ID=RunBatch_ID AND Run_DateTime like '2%' $status AND Equipment_ID = $id AND $base_conditions"
        );
        my ( $all_runs, $all_reads, $all_q20_avg, $all_sl_avg ) = split ',', $all_info;

        ### info not in SequenceAnalysis table.. ###
        my $runs_ip = join ',',
            $dbc->Table_find( 'Equipment,Run,RunBatch', 'count(*)',
            "WHERE RunBatch.FK_Equipment__ID = Equipment_ID and FK_RunBatch__ID=RunBatch_ID $status and Equipment_ID AND Run_Status IN ('Initiated','In Process','Data Acquired') AND Equipment_ID = $id" );
        my $runs_aborted = join ',', $dbc->Table_find( 'Equipment,Run,RunBatch', 'count(*)', "WHERE RunBatch.FK_Equipment__ID = Equipment_ID and FK_RunBatch__ID=RunBatch_ID and Run_Status like 'Failed' $status AND Equipment_ID = $id" );
        unless ( $runs_aborted =~ /\d+/ ) { $runs_aborted = 0; }

        ### Recent Run info.. ###
        my $recent_run_list = join ',', $dbc->Table_find( 'Run,RunBatch', 'Run_ID', "WHERE FK_RunBatch__ID=RunBatch_ID AND RunBatch.FK_Equipment__ID = $id and Run_Status like 'Analyzed' $status" );
        $recent_run_list ||= 0;
        my ($recent_info) = $dbc->Table_find_array(
            'SequenceAnalysis,SequenceRun,Run',
            [ 'count(*)', 'Sum(Wells)', 'Sum(Q20total)/Sum(Wells)', 'Sum(SLtotal)/Sum(Wells)' ],
            "WHERE FK_SequenceRun__ID=SequenceRun_ID AND FK_Run__ID=Run_ID AND Run_ID in ($recent_run_list) $status AND $base_conditions AND $extra_condition"
        );
        my @fields = ( &Link_To( $dbc->homelink(), $machine, "&HomePage=Equipment&ID=$id" ), "$Elocation", $all_runs, $runs_ip, $runs_aborted, $all_reads, "<B>$all_q20_avg</B>", $all_sl_avg );
        my ( $recent_runs, $recent_reads, $recent_q20_avg, $recent_sl_avg ) = split ',', $recent_info;

        my $img;
        my $median;
        if ($details) {
            my @Q20_values = ();
            foreach my $run ( split ',', $recent_run_list ) {
                my ($q20_data) = $dbc->Table_find_array( 'SequenceRun,SequenceAnalysis', ['Q20array'], "WHERE FK_SequenceRun__ID=SequenceRun_ID AND FK_Run__ID = $run" );
                my @q20_array = unpack "S*", $q20_data;
                push( @Q20_values, @q20_array );
            }

            my $stat = Statistics::Descriptive::Full->new();
            $stat->add_data(@Q20_values);
            $median = $stat->median();

            my $file = "$URL_cache/Q20_Distributions/Equipment/Q20Hist_Equ$id";

            # <construction> - need to add regenerate option to this method as well ?
            if ( -e "$file.Summary.png" ) {
                push( @fields, "<IMG src='/dynamic/cache/Q20_Distributions/Equipment/Q20Hist_Equ$id.Summary.png'>\n" );
            }
            else { push( @fields, "(no summary data)" ); }

            if ( -e "$file.Recent.png" ) {
                push( @fields, "(last 30 days)<BR><IMG src='/dynamic/cache/Q20_Distributions/Equipment/Q20Hist_Equ$id.Recent.png'>\n" );
            }
            else { push( @fields, "(no recent data)" ); }
        }
        if ($details) { push( @fields, ( $img, "<B>$median</B>" ) ) }
        push( @fields, ( $recent_runs, $recent_reads, "<B>$recent_q20_avg</B>", $recent_sl_avg ) );

        ##  Get data from SequenceAnalysis ##

        my $colour = 'mediumgrey' unless ( $Estatus eq 'In Use' );
        $colour = 'lightredbw' if $Estatus eq 'Removed';
        $Machine_Info->Set_Row( \@fields, $colour );
        $stamp++;    ## ensure unique time stamps...
    }

    ########### printing the table ###############
    my $output;

    if ( !$scanner_mode ) {
        $output .= $Machine_Info->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Equipment_Status.html", $html_header );
        $Machine_Info->Printout();
    }

    $output .= &Views::sub_Heading( "Not in Use", -1, "class='mediumgrey'", 100 );
    $output .= &Views::sub_Heading( "Removed",    -1, "class='lightredbw'", 100 );
    return $output;
}
#################################
sub index_warnings {
##########################
    #
    # Display format of quality sequence retrieved that resulted in 'index warning'
    #  eg. 'N(50)X(39)N(500)' - warning since vector fragment (39) should not exist.
    #
#################################

    my $lib = shift || param('Library');    # library
    my $limit = shift;

    my $limit_length = "";
    if ( $limit =~ /(\d+)/ ) { $limit_length = "Limit $1"; }

    my $lib_condition = "";
    if ($lib) { $lib_condition = "and Run_Directory like '$lib%'"; }
    my $dbc  = $Connection;
    my @info = $dbc->Table_find(
        'Run,Clone_Sequence,Note',
        'Run_Directory,Well,Clone_Sequence_Comments,Quality_Left,Quality_Length',
        "WHERE FK_Run__ID=Run_ID $lib_condition and FK_Note__ID=Note_ID and Note_Text like 'Index%' Order by Run_DateTime desc $limit_length"
    );

    print h2("Index Warning Elaboration");

    #    print h2("Conventions used:");
    print h3("N(579) = 579 insert base pairs [a,g,t,c or n]");
    print h3("X(39) = 39 vector base pairs (determined by 'cross_match')");
    print "eg. 'N(579)X(39)N(21)' = insert of 579, vector of 39, insert of 21",     br();
    print "(ONLY for sequence within the 'Quality' region as determined by Phred)", &vspace();

    #    print "('Quality Left' indicates the 1st 'Quality' bp in total sequence)",br();
    #    print "('Quality Length' indicates the length of the 'Quality' region in total sequence)",br();

    if ($limit) { print "Displaying last $limit index errors in $lib Library"; }

    my $Index_Errors = HTML_Table->new();
    $Index_Errors->Set_Title("<B>Index Errors</B>");
    my @headers = ( 'Run', 'Well', 'Vector Position X(#)', 'Quality Left', 'Quality Length' );
    $Index_Errors->Set_Headers( \@headers );

    foreach my $record (@info) {
        my @fields = split ',', $record;
        $Index_Errors->Set_Row( \@fields );
    }
    $Index_Errors->Printout();

    #    print start_barcode_form(undef,'Warnings');
    print start_custom_form( -form => 'Warnings', -parameters => {&Set_Parameters} );

    print "Select Library ", textfield( -name => 'Search', -size => 5, onChange => "MenuSearch(document.Warnings)" ), hidden( -name => 'ForceSearch' ),
        popup_menu( -name => 'Library', -values => [@library_names], -default => $lib, -force => 1, -onChange => "SetSelection(document.Warnings,Search,'')" ), " Limit Search to ", textfield( -name => 'Limit', -size => 5, -default => 20 ), " ",
        submit( -name => 'Index Warning', -value => 'View Index Errors', -class => "Search" ), "\n</FORM>";

    return;
}
#################################
sub latest_runs {
####################
    # Show list of runs that fall within a certain time period.
    # Additional conditions may be applied that filter for specific
    # runs, sequencers, libraries, or plate numbers

    print "This method has been phased out... please redirect code to SequenceRun::Run_App";
    Call_Stack();
    return 1;
}

#################################
sub quick_view {
###################

    my $ids      = shift;
    my $dbc      = $Connection;
    my $homelink = $dbc->homelink();
    ########### Retrieve Stats ############
    #    my $Chem = &Sequencing::Primer::get_ChemistryInfo();
    #    my $Chem = &RGTools::RGIO::load_Stats("ChemistryInfo",$Stats_dir);#

    my @sequences = @$ids;

    my $View = HTML_Table->new();
    $View->Set_Headers( [ 'Run ID', 'Date', 'Library', 'Plate', 'Primer', 'Phred 20 Map', 'Primer' ] );

    my $lastlib   = "";
    my $lastplate = "";
    my $colour    = 'lightyellowbw';
    foreach my $seq (@sequences) {
        my @quick_list = $dbc->Table_find(
            'Stock_Catalog,Run,SequenceRun,Solution left join Stock on FK_Stock__ID=Stock_ID',
            'Run_ID,Run_DateTime,Run_Directory,Run_Status,Stock_Catalog_Name',
            "WHERE FK_Run__ID=Run_ID Solution_ID=FKPrimer_Solution__ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Run_ID=$seq Order by Run_Directory asc"
        );

        foreach my $info (@quick_list) {
            ( my $id, my $DT, my $subdirectory, my $state, my $primer ) = split ',', $info;
            $subdirectory =~ /(.{5})(\d+)([a-zA-Z])(.*)/;
            my $lib     = $1;
            my $plate   = $2;
            my $quad    = $3;
            my $version = $4;

            my $chemistry = $version;

            #	    if ($version=~/\.(\w+)/) {
            #		$chemistry = $Chem->{Chemistry}->{$1} || $version;
            #	    }

            my $name;
            if ( $subdirectory =~ /^(\S{5})(.*)$/ ) { $name = "$1+-+$2"; }    # format for link...
            my $map = "<A Href ='$homelink&SeqRun_View=$id'>";
            if ( $state eq 'Analyzed' ) {
                $map .= "</A><Center><B>Pending</B></Center>";
            }
            else {
                $map .= "</A><Center><B>$state</B><BR>(temporarily unavailable)</Center>";
            }

            if ( ( $lib ne $lastlib ) || ( $plate ne $lastplate ) ) {
                $colour    = &toggle_colour( $colour, 'lightgrey', 'lightyellowbw' );
                $lastlib   = $lib;
                $lastplate = $plate;
            }
            $View->Set_Row( [ $id, $DT, "<B>$lib</B>", "<B>$plate$quad</B>", "$chemistry ($version)", $map, $primer ], $colour );
        }
    }
    $View->Printout();
    return 1;
}
#################################
sub mirrored_files {
##########################
    my $dbc         = shift;
    my $sequence_id = shift;

    my $info = join ',', $dbc->Table_find( 'Run,Equipment', 'Run_Directory,Equipment_ID,Equipment_Name', "WHERE FK_Equipment__ID=Equipment_ID and Run_ID = $sequence_id" );

    ( my $sequence_name, my $Machine, my $Machine_ID ) = split ',', $info;

    my $basename;
    my $ext;
    if ( $sequence_name =~ /^(.{5}\d+\w?)\.(.*)$/ ) { $basename = $1; $ext = $2; }

    my ($Data_dir) = $dbc->Table_find( 'Machine_Default', 'Local_Data_Dir', "WHERE FK_Equipment__ID = $Machine_ID" );

    my $mirror_directory;
    if ( $Machine =~ /^MB/i ) {
        $mirror_directory = "$mirror/$Data_dir/$sequence_name*/$basename???.$ext" . ".???";
    }
    elsif ( $Machine =~ /3700/ ) {
        $mirror_directory = "$mirror/$Data_dir/*/$basename.$ext" . "_*";
    }

    #   Message("Checking ls $mirror_directory");
    my $count = try_system_command("ls $mirror_directory | wc");
    return split ' ', $count;
}
#################################
sub weekly_status {
#################################
    #
    # not used ??
    #
#################################
    my $frequency = shift;

    my $tc = shift;
    my $qc = shift;

    my $dbc = $Connection;
    $tc ||= "and Run_Test_Status like '%Production%'";
    $qc ||= "and Quality_Length > 0";

    my $unit = "Month";
    my $limit;
    if ( $frequency =~ /d/i ) {
        $unit = "Day";
        ( my $start ) = split ' ', &date_time("-7d");
        $start .= " 00:00:00";
        $limit = " and Run_DateTime > '$start'";
    }

    my @info = $dbc->Table_find(
        'SequenceAnalysis,SequenceRun,Run',
        'Left(Run_DateTime,7),sum(NGs),Sum(QLtotal)/Sum(Wells) as AvgQL,Sum(SLtotal)/Sum(Wells) as AvgSL,Sum(Wells)',
        "WHERE FK_SequenceRun__ID=SequenceRun_ID AND Run_ID=FK_Run__ID $tc $qc and Growth IN ('OK','Slow Grow') group by Left(Run_DateTime,7)"
    );

    my $Table     = HTML_Table->new;
    my $thistitle = $unit . "ly Summary";
    $Table->Set_Title($thistitle);
    ## <construction> - Add Problematic wells
    my @headers = ( "$unit", 'Total No Grows', 'Avg Quality Length', 'Avg Run Length', ' Total Reads' );
    $Table->Set_Headers( \@headers );
    $Table->Set_Alignment("Center");

    #    $Table->Set_Header_Class("Large");
    foreach my $record (@info) {
        my @fields = split ',', $record;
        $Table->Set_Row( \@fields );
    }

    #    print br(),"Generating Table.",br();
    #    print $Table->Printout("/home/rguin/www/htdocs/intranet/Table.html");
    $class_size = "vsmall";
    $Table->Printout;

    return 1;
}

#############################
sub Latest_Runs_Conditions {
##############################
    print "This method has been phased out... please redirect code to SequenceRun::Run_App";
    Call_Stack();
    return;
}

#################################       done
sub Seq_Data_Totals {
#################################
    my $dbc = shift;
    my $summary_output;
    my $page;

    $page .= Views::Heading("Sequencing Status Page");
    $Benchmark{hist1} = new Benchmark;

    my $Summary = HTML_Table->new();
    $Summary->Set_Class('small');
    $Summary->Set_Title("Run Data Totals (including all Projects)");
    $Summary->Set_Width("95%");
    $Summary->Set_Headers( [ 'Status', 'Runs', 'Total_Reads<BR>[excluding NGs]*', 'Phred_20 bps*', 'Mean_P20*', 'Length (bps)' ] );

    # grab statistics frp, SequenceAnalysis
    my @all_stats_array = $dbc->Table_find(
        "SequenceAnalysis,SequenceRun,Run",
        "Run_Test_Status,count(SequenceAnalysis_ID) as Runs, sum(AllReads) as Read_Count, sum(Q20total) as P20bps, sum(Wells) as NumWells, sum(Q20total)/sum(Wells) as P20mean, sum(SLtotal) as Length",
        "WHERE FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRun_ID AND Run_Status = 'Analyzed' group by Run_Test_Status"
    );
    $Benchmark{hist2} = new Benchmark;

    # sort
    @all_stats_array = sort @all_stats_array;

    # put statistics on the Summary table
    my $total_runs    = 0;
    my $total_reads   = 0;
    my $total_wells   = 0;
    my $total_p20bps  = 0;
    my $total_length  = 0;
    my $total_p20mean = 0;

    foreach my $stats_row (@all_stats_array) {
        my ( $run_status, $runs, $reads, $p20bps, $wells, $p20mean, $length ) = split ',', $stats_row;
        $total_runs   += $runs;
        $total_reads  += $reads;
        $total_p20bps += $p20bps;
        $total_wells  += $wells;
        $total_length += $length;
        my $colour;    ## set colour to match colour scheme in Last 24 Hours page (ie pink for test runs, green for production)
        if    ( $run_status =~ /Production/ ) { $colour = 'vlightgreenbw' }
        elsif ( $run_status =~ /Test/ )       { $colour = 'vlightredbw' }

        $Summary->Set_Row(
            [   $run_status,
                "<B>$runs<B>",
                "<B>" . &RGTools::Conversion::number($reads) . "</B><BR>($reads)<BR>[$wells]",
                "<B>" . &RGTools::Conversion::number($p20bps) . "</B><BR>$p20bps",
                "<B>" . &RGTools::Conversion::number( $p20mean, 2 ) . "</B>",
                "<B>" . &RGTools::Conversion::number($length) . "</B>"
            ],
            $colour
        );
    }
    $total_p20mean = $total_p20bps / $total_wells;

    # put stats for all
    $Summary->Set_Row(
        [   'All', "<B>$total_runs<B>",
            "<B>" . number($total_reads) . "</B><BR>($total_reads)<BR>[$total_wells]",
            "<B>" . number($total_p20bps) . "</B><BR>$total_p20bps",
            "<B>" . number( $total_p20mean, 2 ) . "</B>",
            "<B>" . number($total_length) . "</B>"
        ],
        'vvvlightgrey'
    );

    ### Generate the run Distribution daily... ###
    $Benchmark{hist2a} = new Benchmark;
    my ($failed)  = $dbc->Table_find( 'SequenceAnalysis,SequenceRun,Run', 'count(*)', "WHERE FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRun_ID and Run_Status = 'Failed'" );
    my ($aborted) = $dbc->Table_find( 'SequenceAnalysis,SequenceRun,Run', 'count(*)', "WHERE FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRun_ID and Run_Status = 'Aborted'" );
    my ($water)   = $dbc->Table_find( 'SequenceAnalysis,SequenceRun,Run', 'count(*)', "WHERE FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRun_ID and Run_Status = 'Not Applicable'" );
    $Benchmark{hist2b} = new Benchmark;

    $summary_output .= "<Table><TR valign='top'><TD rowspan='2'>";
    $summary_output .= $Summary->Printout(0);
    $summary_output
        .= "</TD><TD>"
        . "<span class=small>Production Q20 Distribution"
        . "<BR><IMG src='/dynamic/cache/Q20_Distributions/All/Q20Hist.Summary.png'></span></TD><TD>"
        . "<span class=small>(for runs in last 30 days..)<BR>"
        . "<IMG src='/dynamic/cache/Q20_Distributions/All/Q20Hist.Recent.png'></span>"
        . "</TD></TR><TR valign='top'><TD colspan='2'><span class=small><UL>";
    $summary_output .= "<LI>For up to the minute statistics use Project Stats button below";
    $summary_output .= "<LI>'Failed' reads are excluded<LI>No Grows are also excluded from Phred 20 statistics";
    $summary_output .= "<LI>Also excluded from the statistics are:<UL>";
    $summary_output .= "<LI><B>$failed failed run(s)</B>";
    $summary_output .= "<LI><B>$aborted aborted run(s)</B>" if $aborted;
    $summary_output .= "<LI><B>$water Water run(s)</B></UL>" if $water;
    $summary_output .= "</UL><P>";
    $summary_output .= &Link_To( $dbc->homelink(), 'Monthly Histograms', '&Monthly+Histograms=1', $Settings{LINK_COLOUR} );
    $summary_output .= "</TD></TR>";
    $summary_output .= "</Table>";

    $Benchmark{hist3} = new Benchmark;
    $page .= $summary_output;
    return $page;
}
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
sub _percent_view {
##############
    my $fields = shift;
    my @field_list = Cast_List( -list => $fields, -to => 'array' );

    my @views;
    foreach my $field (@field_list) {
        push( @views, "<Font color=red><B><<PERCENT_$field>></B></Font><BR><<$field>>" );
    }
    return @views;
}
################################
#################################
sub _avg_view {
##############
    my $fields = shift;
    my @field_list = Cast_List( -list => $fields, -to => 'array' );

    my @views;
    foreach my $field (@field_list) {
        push( @views, "<Font color=red><B><<AVG_$field>></B></Font><BR><<$field>>" );
    }
    return @views;
}
#################################
sub _sub_header {
#####################
    my $Project_Info = shift;
    my $details      = shift;
    my $warnings     = shift;

    $Project_Info->Set_sub_title( 'Project Summary', 4, 'mediumgreenbw' );

    if ($details) {
        $Project_Info->Set_sub_title( '(Excluding No Grows', 7, 'mediumyellowbw' );    ## one column for Median + 1 for histogram
    }
    else {
        $Project_Info->Set_sub_title( '(Excluding No Grows)', 5, 'mediumyellowbw' );
    }
    if ($warnings) { $Project_Info->Set_sub_title( 'Warnings', 1, 'mediumredbw' ) }

    return;
}
#################################
sub _init_table {
##########################
    my $title = shift;

    my $table = HTML_Table->new();
    $table->Set_Class('small');
    $table->Set_Width('100%');
    $table->Toggle_Colour('off');
    $table->Set_Line_Colour( '#eeeeff', '#eeeeff' );
    $table->Set_Title( $title, bgcolour => '#ccccff', fclass => 'small', fstyle => 'bold' );

    return $table;
}
#################################
sub convert_to_colour {
###########################
    my $number = shift;

    my @colours = ( 'Red', 'Green', 'Blue' );

    my $index = 0;
    if ( $number < 400 ) {
        $index = 0;
    }
    elsif ( $number < 600 ) {
        $index = 1;
    }
    else {
        $index = 2;
    }

    return "<B><Font color=$colours[$index]>$number</Font></B>";
}
#################################
sub RoundSigDig {
#################################
    # Round a number to X significant digits. This function is
    # meant only for integers.
#################################

    my %flags = @_;
    my $num   = $flags{num};
    my $result;

    # Return what we get if num
    #  - is not defined
    #  - is less than 10 (handles num=0) (this function does not handle single digits)
    #  - includes non-digits
    if ( !defined $num || $num < 10 || $num =~ /\D/ ) {
        return $num;
    }
    my $sd        = Extract_Values( [ $flags{sd}, 2 ] );
    my $size      = int( log($num) / log(10) + 1 );
    my $roundsize = $size - $sd;
    if ( $roundsize < 0 ) {
        return $result;
    }
    my $mult = 10**$roundsize;
    my $rem  = ( $num % $mult );

    if ( $rem < $mult / 2 ) {
        $result = $mult * int( $num / $mult );
    }
    else {
        $result = $mult * ( int( $num / $mult ) + 1 );
    }
    return $result;
}
#################################
sub _get_summary_type {
##########################
    # this is a bad function that needs to be removed, it's only temporaray
    #
###########################
    my %args         = @_;
    my $from         = $args{-from};
    my $to           = $args{-to};
    my $summary_type = $args{-type};
    my $day_flag     = $args{-last_two_days};
    my $days         = $args{-number};
    my @diff;

    $summary_type =~ s/Last N Days/Last $days Days/;
    unless ($summary_type) {
        $to =~ /(\d+)-(\d+)-(\d+)/;
        $diff[0] = $1;
        $diff[1] = $2;
        $diff[2] = $3;
        $from =~ /(\d+)-(\d+)-(\d+)/;
        $diff[0] -= $1;
        $diff[1] -= $2;
        $diff[2] -= $3;
        my $difference = 365 * $diff[0] + 31 * $diff[1] + $diff[2];

        if   ( $difference == 7 ) { $summary_type = 'Weekly Updates' }
        else                      { $summary_type = "Last $difference Days" }
    }
    if ($day_flag) { $summary_type = 'Last 2 Days' }

    return $summary_type;
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

$Id: SDB_Status.pm,v 1.141 2004/12/09 17:38:33 rguin Exp $ (Release: $Name:  $)
$Id: SDB_Status.pm,v 1.141 2004/12/09 17:38:33 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
