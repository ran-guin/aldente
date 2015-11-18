###############################################################################
#
# Sequence.pm
#
# This module handles routines specific to Sequencing (Sample Sheets set up)
#
################################################################################
# CVS Revision: $Revision: 1.45 $
#     CVS Date: $Date: 2004/10/27 18:23:51 $
################################################################################
package Sequencing::Sequence;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Sequence.pm - This module handles routines specific to Sequencing (Sample Sheets set up)

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles routines specific to Sequencing (Sample Sheets set up)<BR>

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
    sequence_home
    sequence_queue
    clone_sequence_status
    check_sequence_runs
    run_status_swap
    fail_runs
    add_comments_to_runs
    phred_score
    well_info
    run_view
    interleaved_run_view
    colour_map
    Bin_counts
);
@EXPORT_OK = qw();

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);

#use Storable;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
#use Carp qw(carp cluck);
use Sequencing::SDB_Status;
use alDente::Form;
use alDente::Solution;
use alDente::Library;
use alDente::Container;
use alDente::SDB_Defaults;
use alDente::Data_Images;
use alDente::Run;
use alDente::Sample;

use SDB::DBIO;
use alDente::Validation;
use SDB::Data_Viewer;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
our ( $dbase, $homefile, $homelink, $user, $equipment, $equipment_id );
our ( $parents, $current_plates, $plate_set );
our ( $plate_id, $testing, $padding, $Connection );
our (@libraries);
our ($MenuSearch);    ## from Barcode.pm
our ( $genss_script, $trace_link );
our ( $scanner_mode, $barcode, $last_page, $project_dir, $fasta_dir, $sssdir );
use vars qw($Stats_dir);
use vars qw(%Defaults);

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

sub new {
    return;
}

##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

########################
sub sequence_home {
########################
    #
    # Home page for Sample Sheet generation...
    # DEPRECATED!

    return;

    my $dbc = $Connection;
    my @sequencers;
    my $equipment     = alDente::Equipment->new( -dbc        => $dbc );
    my $sequencer_ref = $equipment->get_sequencer_list( -dbc => $dbc );
    my @sequencers = @$sequencer_ref if $sequencer_ref;

    print Views::Heading("Sample Sheets Home Page");

    my $default_lib = param('Lib Status');
    foreach my $item (@libraries) {
        if ( $item =~ /^$default_lib/ ) { $default_lib = $item; last; }
    }

    my $default_sequencer = param('Equipment');
    my $lib               = param('Lib Status');
    if ( $lib =~ /(.*):/ ) { $lib = $1 }
    my $plate_num = param('Plate Number');

    my @plate_nums;
    if ($plate_num) { @plate_nums = split ',', &extract_range($plate_num); }
    else {

        #    @plate_nums = $Connection->Table_find('Plate','Plate_Number',"where FK_Library__Name like \"$lib%\"",'Distinct');
        my $condition = 'WHERE 1';
        $condition .= " AND FK_Library__Name like '%$lib%'" if ($lib);
        my ($max_plate_num) = $Connection->Table_find( 'Plate', 'MAX(Plate_Number)', $condition );
        my ($min_plate_num) = $Connection->Table_find( 'Plate', 'MIN(Plate_Number)', $condition );
        @plate_nums = $min_plate_num .. $max_plate_num;
    }

    my @liblist = $Connection->Table_find( 'Plate', 'FK_Library__Name,Max(Plate_Number)', "Group by FK_Library__Name" );
    print start_custom_form( -form => 'Sequence', -parameters => { &Set_Parameters('status') } );

    #print &start_barcode_form('status','Sequence');

    print start_custom_form( -name => 'status', -parameters => { &Set_Parameters('Sequence') } );
    foreach my $plate_max (@liblist) {
        print hidden( -name => "Max:$plate_max" );
    }

    print submit( -name => 'Prepare Sample Sheet', -class => "Std" ), ' <span class=small>(or list possible options if none scanned)</span>';
    print &vspace();

    print "<Table cellpadding=$padding><tr>\n";
    print "<td><b><Font color=red>Machine:</Font></b></td>";
    print "<td>" . popup_menu( -name => 'Equipment', -force => 1, -value => [@sequencers], -default => $default_sequencer ) . "</td>\n";
    print "</tr>\n";
    print "<tr>\n";
    print "<td><B><Font color=red>Library:</Font></B> </td>\n";
    print "<td>";

    #  print textfield(-name=>'String',-size=>10,-onChange=>"SSHome(document.Sequence,1)") .
    #      hidden(-name=>'ForceSearch');
    print popup_menu( -name => 'Library.Library_Name', -value => [@libraries], -force => 1, -default => $default_lib, -onChange => "SSHome(document.Sequence,0)" ), "<span class=small><B> (this should update valid options in Plate Number menu)</B></span>";
    print "</td>\n";
    print "</tr>\n";
    print "<tr>\n";
    print "<td><b><Font color=red>Plate Number:</Font></b> </td>";
    print "<td>" . popup_menu( -name => 'SS Plate Number', -force => 1, -values => [ '', @plate_nums ], -default => '' ) . " <span class=small><B>(just get list of valid Plates)</B> </span>" . "</td>\n";
    print "</tr>\n";
    print "<tr><td>";
    print "<B><Font color=red>(or Scan):</Font></B> ", "</td>\n";
    print "<td>";
    print textfield( -name => 'SS Plate', -size => 15, -default => '', -force => 1 );
    print " (scan single or multiple plates)";
    print "</td>\n";
    print "</tr>\n</table>\n\n";
    print &vspace();

    print checkbox( -name => 'No Vector' ), " <B>(choose from ALL Primers)</B>";

    #Add button links to sample sheet configuration.
    my @Sequencer_Types = $Connection->Table_find( 'Sequencer_Type', 'Sequencer_Type_Name', 'ORDER BY Sequencer_Type_Name', 'Distinct' );
    print "<HR size=2>", submit( -name => 'Configure_SS', -value => "Configure Sample Sheet", -class => "Search" ), &hspace(10), "Sequencer Type: ", popup_menu( -name => 'Sequencer_Type', -values => [@Sequencer_Types], -default => "" );

    print "<HR size=2>";
    print checkbox( -name => 'All Users', -label => " Include sheets generated by all users", -force => 1, -checked => 0 );
    print &vspace();
    print submit( -name => 'Remove Sequence Request', -class => "Std" );
    print " <B>(For Runs Not yet Analyzed)</B>";
    print &vspace();

    print textfield( -name => 'Search String', -size => 15, -force => 1, -default => "" );
    print " <B>Faster if Library Specified</B> (eg. 'TL' or 'RM0034a')";
    print &vspace();

    print "(To delete mistaken entries from Database)";
    print "<HR size=2>";
    print checkbox( -name => 'All Users', -label => " Include sheets generated by all users", -force => 1, -checked => 0 );
    print &vspace();

    print submit( -name => 'Mark Failed Runs', -class => "Std" ), " ";
    print submit( -name => 'Annotate Sequence Comments', -class => "Std" );
    print " <B>(For Runs already Analyzed)</B>";
    print &vspace();

    print textfield( -name => 'Search String', -size => 15, -force => 1, -default => "" );
    print &vspace();

    print " (Search eg. 'CN001*') - List is limited to most recent 20 records matching search";
    print "<HR size=2>";
    print submit( -name => 'Search for', -value => "Search/Edit Sequence Info", -class => "Search" ) . &hspace(10) . checkbox( -name => 'Multi-Record' );

    print hidden( -name => 'Table', -value => 'Run', -force => 1 );
    print "</form>\n";

    return 1;
}

#######################
sub sequence_queue {
#######################
    #
    # print out queue of Sequence requests
    #
    my $library = shift;
    my $plate   = shift;
    my $dbc     = $Connection;
    print "<Table cellpadding=$padding><TR>";
    print "<TD>Plate</TD>";
    print "<TD>Last Prep</TD>";
    print "<TD>Sequenced</TD>";
    print "<TD>(More In Process)</TD>";
    print "</TR><TR>";

    my $condition;
    if ($plate) { $condition = "and Plate_Number = $plate"; }

    #    if (!$plate) {
    my @plates = $dbc->Table_find( 'Plate', 'Plate_Number,Plate.Parent_Quadrant', "where FK_Library__Name like \"$library%\" $condition", 'Distinct' );
    foreach my $plate (@plates) {
        ( my $plate_num, my $quad ) = split ',', $plate;
        print "<TD>$plate_num $quad</TD>";
        my $lastprep = join ',', $dbc->Table_find( 'Plate', 'Max(Plate_Created)', "where Plate_Number = $plate_num and Plate.Parent_Quadrant=$quad" );
        if ( $lastprep =~ /^(\S)\s/ ) { $lastprep = $1; }
        print "<TD>$lastprep</TD>";

        my $sequenced = join ',', $dbc->Table_find( 'Run,Plate', 'Max(Run_DateTime)', "where Run.FK_Plate__ID = Plate_ID and FK_Library__Name = '$library' and Plate_Number = $plate_num and Plate.Parent_Quadrant = '$quad'" );
        if ( $sequenced =~ /^[0]/ ) { print "<TD>In Process</TD>"; }
        elsif ( $sequenced eq 'NULL' ) { print "<TD>..</TD>"; }
        elsif ( $sequenced =~ /^\d\d\d\d/ ) { print "<TD>$sequenced</TD>"; }
        else                                { print "<TD>not sequenced</TD>"; }
        my $inprocess = join ',',
            $dbc->Table_find( 'Run,Plate', 'count(*)',
            "where Run.FK_Plate__ID = Plate_ID and FK_Library__Name = '$library' and Plate_Number = $plate_num and Plate.Parent_Quadrant = '$quad' and (Run_Status IN('Initiated','In Process','Data Acquired') or Run_DateTime like \"0%\")" );
        print "<TD>$inprocess</TD>";
        print "</TR><TR>";
    }

    #    }
    print "</TR></Table>";
    return 1;
}

##################################
sub clone_sequence_status {
################################
    #
    # provide information for a Clone_Sequence run...
    #
    my %args = &filter_input( \@_, -args => 'id', -mandatory => 'id|run_id' );

    my $dbc            = $args{-dbc};
    my $sequence_name  = $args{-name};                    # specify name (Run_Directory)
    my $run_id         = $args{-id} || $args{-run_id};    # specify run id
    my $show_well_info = $args{-well_info};
    my $trimming       = $args{-trimming};                ## allow trimming for quality or trimming for quality & vector
    my $phred_score    = $args{-phred_score} || 20;

    my $homelink = $dbc->homelink();

    my $stamp = time();

    my $library;
    my $size;
    my $plate_id;
    my $path;
    my $L_type;

    my $output;
    if ( $run_id || ( $sequence_name =~ /^(\d+)$/ ) ) {
        $run_id ||= $sequence_name;
        my $info = join ',',
            $dbc->Table_find_array(
            'Run,Plate,Library,Project',
            [ 'Run_Directory', 'Library.Library_Name', 'Plate_ID', 'Plate_Size', 'Project_Path' ],
            "where FK_Plate__ID = Plate_ID and Library_Name=FK_Library__Name AND FK_Project__ID=Project_ID AND Run_ID=$run_id"
            );
        ( $sequence_name, $library, $plate_id, $size, $path ) = split ',', $info;
    }
    elsif ( $sequence_name =~ /(.{5})[\s\-]*(\d+)(.*)$/ ) {    #<CONSTRUCTION> This run directory name parsing needs to be updated (if run_id is mandatory, this is not necessary)
        $library       = $1;
        $sequence_name = $1 . $2 . $3;
        my $info = join ',',
            $dbc->Table_find_array(
            'Run,Plate,Library,Project',
            [ 'Run_ID', 'Plate_Size', 'Plate_ID', 'Project_Path' ],
            "where FK_Plate__ID=Plate_ID and Library_Name=Plate.FK_Library__Name and FK_Project__ID=Project_ID AND Run_Directory like '$sequence_name'"
            );
        ( $run_id, $size, $plate_id, $path ) = split ',', $info;

        #	$output .= "Found $run_id, $size from $sequence_name";
    }
    else { Message("No Sequence specified ($run_id:$sequence_name)"); }

    if ( !$library ) { Message("Invalid sequence name/id ($run_id:$sequence_name) ?"); return 0; }

    $output .= Views::Heading("Sequence Read Info for $sequence_name (Sequence $run_id)");

    $output .= "<Font size=-1><B>ABI filepath: </B>$project_dir/$path/$library/AnalyzedData/$sequence_name/chromat_dir/</Font>" . &vspace(10);

    ###### print out general info.. #######

### Plate Info ###
    #  print &Link_To($homelink,'Plate Info:',"&Info=1&Table=Plate&Field=Plate_ID&Like=$plate_id",$Settings{LINK_COLOUR},['newwin']);

    my $info_1 = $dbc->Table_retrieve_display(
        'Plate,Library_Plate,Run,Library,RunBatch,Equipment,Solution,Stock,Stock_Catalog,SequenceRun',
        [   'FK_Project__ID', 'Library_Name', 'concat(Plate_Number,Plate.Parent_Quadrant) as Plate',
            'Plate_ID', 'Plate_Label as Label',
            'Run_ID', 'Run_DateTime',
            'Equipment_Name as Machine',
            'Stock_Catalog_Name as Primer',
            'Plate_Size as Size',
            'FK_Plate_Format__ID as Plate_Format',
            'Plate_Comments',
            'Plate_Test_Status as Status',
            'Library.Library_Type AS Library_Type',
            'FK_RunBatch__ID',
            'RunBatch_RequestDateTime as Requested',
            'Run_Comments as Run_Comments'
        ],
        "where Library_Plate.FK_Plate__ID=Plate_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Run.FK_Plate__ID=Plate_ID AND Run_ID in ($run_id) AND Plate.FK_Library__Name=Library.Library_Name AND FK_RunBatch__ID=RunBatch_ID AND FK_Equipment__ID=Equipment_ID and FKPrimer_Solution__ID=Solution_ID AND Solution.FK_Stock__ID=Stock_ID and SequenceRun.FK_Run__ID=Run_ID",
        -title       => "Data for Run $run_id",
        -by          => 'row',
        -return_html => 1
    );
    ($L_type) = $dbc->Table_find( 'Vector_Based_Library', 'Vector_Based_Library_Type', "WHERE FK_Library__Name = '$library'" );
    ### Temporary ###
    if ( $L_type =~ /dna/i ) {
        my $sizing_gel_page = "http://ybweb.bcgsc.bc.ca/cgi-bin/intranet/SizingGel.pl";
        $info_1 .= &vspace() . &Link_To( $sizing_gel_page, 'Sizing GelRun Info', "?pl=$plate_id", $Settings{LINK_COLOUR}, ['newwin'] ) . &vspace();
    }

### Brew Info ###
    my $sets = &alDente::Container::get_Sets( -dbc => $dbc, -id => $plate_id );

    $info_1 .= &vspace(2);
    my $set_option;
    ### <CONSTRUCTION> why OR FK_Plate_Set__Number in sets ? will result in multiple solution ID's added distinct
    if ($sets) { $set_option = "OR FK_Plate_Set__Number in ($sets)"; }
    my @brews = $dbc->Table_find( 'Plate_Prep,Prep', 'distinct Plate_Prep.FK_Solution__ID', "where (FK_Plate__ID in ($plate_id) $set_option) AND Prep_ID=FK_Prep__ID AND Prep_Name like 'Dispense Brew'" );
    my $display = "<B>Brew Mix applied:</B>";

    $display .= "<ul>";
    foreach my $brew (@brews) {
        my $brew_info = $dbc->get_FK_info( 'FK_Solution__ID', $brew );
        $display .= '<LI>' . &Link_To( $homelink, $brew_info, "&HomePage=Solution&ID=$brew", $Settings{LINK_COLOUR}, ['newwin'] );
    }
    $display .= "</ul>";
    unless ( int(@brews) ) { $display .= ' (None) '; }

    $info_1 .= $display;

    ### Run Info ###

    $output .= $info_1;

    require alDente::Run_Statistics;
    ## add small icons and links to older pages originally generated by Martin K ##
    my $add_to_view = "<B><span class=darkbluetext> Alternate Views: </span></B>";

    my $statshistImg = qq{<img src="/$URL_dir_name/$image_dir/histogram-s0.png" name=histogram border=0 alt="See the Phred histograms for RunID $run_id" title="See the phred histograms for RunID $run_id">};
    $add_to_view .= &Link_To( $homelink, $statshistImg, "&StatsHistView=$run_id", -mouseover => "select(histogram,1)", -mouseout => "select(histogram,0)" ) . hspace(10);

    my $runcapImg = qq{<img src="/$URL_dir_name/$image_dir/runplate-s0.png" name=runplate border=0 alt="See the run plate view for RunID $run_id" title="See the run list for RunID $run_id">};
    $add_to_view .= &Link_To( $homelink, $runcapImg, "&RunCapPlateView=$run_id", -mouseover => "select(runplate,1)", -mouseout => "select(runplate,0)" ) . hspace(10);

    $output .= alDente::Run::run_view_options( $plate_id, $run_id, -more_options => $add_to_view, -dbc => $dbc );

    $output .= "\n<font size=+2><B><span class=darkbluetext>Run $run_id: ($trimming)</span></b></font>\n" . hspace(180);

    $output .= Views::Table_Print(
        content => [
            [   run_view( -dbc                                => $dbc, -run_id  => $run_id, -phred    => $phred_score, -size        => $size,                                       -trimming => $trimming ),
                &alDente::Run_Statistics::summary_stats( -dbc => $dbc, -run_ids => $run_id, -trimming => $trimming,    -phred_score => $phred_score ) . hr . fasta_block( $library, $run_id,  $dbc )
            ]
        ],
        print => 0
    );

    $output .= hr . alDente::Sample::query_sample_block( $plate_id, -submit => ['DNA Quantitation Info'], -dbc => $dbc );

    return $output;
}

##############################
sub fasta_block {
##############################
    my $library = shift;
    my $run_id  = shift;
    my $dbc     = shift;

    my $fasta_block = &alDente::Form::start_alDente_form( $dbc, 'fasta', $dbc->homelink() );

    $fasta_block .= hidden( -name => 'Library', -value => $library ), $fasta_block .= hidden( -name => 'Run', -value => $run_id ), $fasta_block .= submit( -name => 'Generate Fasta File for Run', -class => "Action" ),
        $fasta_block
        .= checkbox( -name => 'Dump to Screen' )
        . &vspace()
        . checkbox( -name => 'Include Test Runs', -checked => 0 )
        . &hspace(10)
        . checkbox( -name => 'Trim Vector', -checked => 1 )
        . &hspace(10)
        . checkbox( -name => 'Trim Quality', -checked => 1 )
        . &vspace(10)
        . "Force Case to: "
        . radio_group( -name => 'Force Case', -values => [ 'Mixed', 'Lower', 'Upper' ], -default => 'Mixed' )
        . &vspace(10)
        . checkbox( -name => 'Include Redundancies', -checked => 0 )
        . ' (otherwise includes best read for each sample)'
        . &vspace(10)
        . checkbox( -name => 'Include All Wells', -checked => 0 )
        . ' (includes data for empty, unused wells if available)'
        . &vspace(10)
        . "<span class=small>Force into columns of width: "
        . textfield( -name => 'Columnate', -size => 5, -default => 0 )
        . " (set to '0' for no columnation)"
        . &vspace(10);

    $fasta_block .= "Will generate a file named $fasta_dir/Run$run_id.fasta</span>\n";

    $fasta_block .= "</FORM>\n";

    return $fasta_block;
}

##############################
sub check_sequence_runs {
##############################

    #    if (param('Library.Library_Name')) {
    #	push(@conditions,"FK_Library__Name = ".param('Library.Library_Name'));
    #    }
    #
    #    if (param('SS Plate Number')) {
    #	push(@conditions,"FK_Library__Name = ".param('Library.Library_Name'));
    #    }
    return 1;
}

#######################
sub run_status_swap {
#######################
    #
    # Change Run_Test_Status from $search to $replace
    # (used to switch from 'In Process' to 'Analyzed' or 'Failed')
    #  (or from Production to Test ?)
###################################################################
    my $dbc     = shift;
    my $search  = shift;
    my $replace = shift;
    my $notes   = shift;

    my $count        = 0;
    my $total_edited = 0;
    my $value;
    ( my $today ) = split ' ', &date_time();
    if ( $today =~ /(\d\d\d\d)-(\d\d-\d\d)/ ) { $notes .= " - $2"; }    ### note date of edit

    my @ids = param('Mark');
    foreach my $thisid (@ids) {
        my $edits = 0;
        my $status = join ',', $dbc->Table_find( 'Run', 'Run_Test_Status', "where Run_ID = $thisid" );
        if ( $status =~ s /$search/$replace/g ) {
            $edits = $dbc->Table_update_array( 'Run', [ 'Run_Test_Status', 'Run_Comments' ], [ $status, "concat(Run_Comments,'($replace: $notes)')" ], "where Run_ID = $thisid", -autoquote => 1 );

            #	    print "<BR>Replace $search with $replace for: $dvalue.";
        }

        ############ Replace Run_Status as well if applicable...
        my $status2 = join ',', $dbc->Table_find( 'Run', 'Run_Status', "where Run_ID = $thisid" );
        if ( $status2 =~ s /$search/$replace/g ) {
            $edits = $dbc->Table_update_array( 'Run', [ 'Run_Status', 'Run_Comments' ], [ $status2, "concat(Run_Comments,'($replace: $notes)')" ], "where Run_ID = $thisid", -autoquote => 1 );

            #	    print "<BR>Replace $search with $replace for: $dvalue.";
        }

        ############# Replace Run_Status ############################
        my $state = join ',', $dbc->Table_find( 'Run', 'Run_Status', "where Run_ID = $thisid" );
        if ( $state =~ s /$search/$replace/g ) {
            $dbc->Table_update( 'Run', 'Run_Status', "'$state'", "where Run_ID = $thisid" );

            #	    print "<BR>Replace $search with $replace for: $dvalue.";	$count++;
        }
        $total_edited += $edits;
    }
    Message("$count Records changed from $search to $replace. ($total_edited altered)");
    return;
}

#######################
sub run_state_swap {
#######################
    #
    # Change Run_Status from $search to $replace
    # (used to switch from 'In Process' to 'Analyzed' or 'Failed')
###################################################################
    my %args    = &filter_input( \@_, -args => 'dbc,search,replace,notes' );
    my $dbc     = $args{-dbc};
    my $search  = $args{-search};
    my $replace = $args{-replace};
    my $notes   = $args{-notes};
    my $user_id = $dbc->get_local('user_id');
    my @ids     = Cast_List( -list => $args{-ids}, -to => 'array' );

    my $count        = 0;
    my $total_edited = 0;
    my $value;
    ( my $today ) = split ' ', &date_time();
    my $emp = $dbc->get_FK_info( 'FK_Employee__ID', $user_id );
    if ( $today =~ /(\d\d\d\d)-(\d\d-\d\d)/ ) { $notes = "$replace: $notes (On $today By $emp)"; }    ### note date of edit

    $notes = $dbc->dbh()->quote($notes);
    foreach my $thisid (@ids) {
        my $edits = 0;
        my $status = join ',', $dbc->Table_find( 'Run', 'Run_Status', "where Run_ID = $thisid" );
        if ( $status =~ s/$search/$replace/ ) {
            $status = $dbc->dbh()->quote($status);
            $edits = $dbc->Table_update_array( 'Run', [ 'Run_Status', 'Run_Comments' ], [ $status, "CASE WHEN LENGTH(Run_Comments>0) THEN $notes ELSE CONCAT(Run_Comments,'; ',$notes) END" ], "where Run_ID = $thisid" );
        }
        $total_edited += $edits;
    }
    Message("$total_edited Records changed from '$search' to $replace.");
    return;
}

#######################
sub fail_runs {
#######################
    #
    # Set Run_Test_Status to 'Failed'
    #
###################################################################
    my $dbc   = shift;
    my $notes = shift;

    my $count        = 0;
    my $total_edited = 0;
    my $value;
    ( my $today ) = split ' ', &date_time();
    if ( $today =~ /(\d\d\d\d)-(\d\d-\d\d)/ ) { $notes .= " - $2"; }    ### note date of edit

    my @ids = param('Mark');
    foreach my $thisid (@ids) {
        my $edits = 0;

        #	my $state = join ',',$dbc->Table_find('Run','Run_Status',"where Run_ID = $thisid");
        #	$state =~s /In Process/Failed/i;
        #	$state =~s /Analyzed/Failed/i;

        #	$edits =$dbc->Table_update_array('Run',['Run_Status','Run_Comments'],[$state,"concat(Run_Comments,' (Failed: $notes)')"],"where Run_ID = $thisid",-autoquote=>1);

        ################ Update Run_Status ##############################
        my $state = join ',', $dbc->Table_find( 'Run', 'Run_Status', "where Run_ID = $thisid" );
        $state =~ s/Initiated|In Process|Data Acquired|Analyzed/Failed/i;

        $dbc->Table_update( 'Run', 'Run_Status', "$state", "where Run_ID = $thisid", -autoquote => 1 );

        $count++;
        $total_edited += $edits;
    }
    Message("$count Records Set as Failed. ($total_edited altered)");
    return;
}

#######################
sub add_comments_to_runs {
#######################
    #
    # Set Run_Test_Status to 'Failed'
    #
###################################################################
    my $dbc   = shift;
    my $notes = shift;

    my $count        = 0;
    my $total_edited = 0;
    my $value;

    my @ids = param('Mark');
    foreach my $thisid (@ids) {
        my $comments = join ',', $dbc->Table_find( 'Run', 'Run_Comments', "where Run_ID = $thisid" );
        $comments .= " $notes";
        my $ok = $dbc->Table_update_array( 'Run', ['Run_Comments'], ["$comments"], "where Run_ID = $thisid", -autoquote => 1 );

        ################ Update Run_Status ##############################

        $count++;
        $total_edited += $ok;
    }
    Message("$count Records(s) Found. ($total_edited altered)");
    return;
}

###############################
sub phred_score {
##############################
    #
    # Returns the number of base pairs above a certain phred score.
    #  eg phred_score(123,'A05',20) returns the phred20 score for the clone in well 'A05' of run 123.
    #
    my $run_id = shift;
    my $well   = shift;
    my $score  = Extract_Values( [ shift, 20 ] );
    my $dbc    = $Connection;

    #    my @fields = ("ascii(Mid(Phred_Histogram,$score*2+2,1))*256 + ascii(Mid(Phred_Histogram,$score*2+1,1))");
    my @fields = ('Phred_Histogram');
    ( my $num ) = $dbc->Table_find_array( 'Clone_Sequence', \@fields, "where FK_Run__ID = $run_id and Well = '$well'" );
    my @unpacked_num = unpack "S*", $num;
    return $unpacked_num[$score];

    #    return $num;
}

#####################
sub well_info {
#####################
    my $run_id  = shift;
    my $well    = shift;
    my $dbc     = $Connection;
    my $display = &try_system_command("/home/rguin/public/quick_view -R $run_id -W $well");

    $display =~ s /\n/<BR>/g;
    print $display;

    ViewChromatogramApplet( $dbc, $run_id, $well, 500, 300, 0 );
    return 1;
}

####################################################
#
# Displays an HTML view of a run as a
# series of colourful circles, where the
# colours correspond to the number of reads above
# a certain Phred score threshhold
#
###################
sub run_view {
###################
    my %args = filter_input( \@_, -args => [ 'run_id', 'phred', 'size', 'reduce', 'trimming' ], -mandatory => ['run_id'] );

    my $dbc          = $args{-dbc};
    my $run_id       = $args{-run_id};
    my $phred_score  = $args{-phred} || 20;
    my $size         = $args{-size};          ###### size of plate sequenced
    my $mini_version = $args{-reduce};        ###### option for mini-view...
    my $trimming     = $args{-trimming};      ###### option for trimming for quality / vector
    my $range        = $args{-range};

    my $title = "P" . $phred_score . " quality / read";

    if ( $trimming eq 'Amplicon' ) {
        $range = 120;
        $title .= ' (%)';
    }
    else { $range = 1200 }

    my $x_max = $range;                       ## for histograms

    my $MSB = $phred_score * 2;
    my $LSB = $MSB + 1;

    my $run_view = '';

    if ( $run_id =~ /(\d+),/ ) { Message("Only 1st plate shown"); $run_id = $1; }
    my $prevrun = $run_id - 1;
    my $nextrun = $run_id + 1;
    my $linkto  = "$URL_address/dbsummary.pl";

    ### If Trimming, grab lengths from clipped quality lengths ###

    my $Phred;
    my $Growth;
    my $Note;
    my $Length;
    my $Warning;
    my %Info = $dbc->Table_retrieve(
        'Clone_Sequence',
        [ 'Well', 'Quality_Left', 'Quality_Length', 'Vector_Quality', 'Sequence_Length', 'Read_Warning', 'Left(Growth,2) as Growth', 'Phred_Histogram', 'Sequence_Scores', 'Clone_Sequence.FK_Sample__ID' ],
        "where FK_Run__ID = $run_id Order by Well"
    );
    my @data;
    my $index = 0;

    while ( defined $Info{Well}[$index] ) {
        my $well = $Info{Well}[$index];
        $well =~ /([a-zA-Z]{1})(\d+)/;
        my $row = $1;
        my $col = $2;

        my $qleft    = $Info{Quality_Left}[$index];
        my $ql       = $Info{Quality_Length}[$index];
        my $qv       = $Info{Vector_Quality}[$index];
        my $sl       = $Info{Sequence_Length}[$index];
        my $packed20 = $Info{Phred_Histogram}[$index];
        my @scores   = unpack "C*", $Info{Sequence_Scores}[$index];
        my $sample   = $Info{FK_Sample__ID}[$index];

        my ($length) = meta_length( -dbc => $dbc, -qleft => $qleft, -ql => $ql, -qv => $qv, -sl => $sl, -phred_score => $phred_score, -scores => \@scores, -trimming => $trimming, -sample => $sample );
        push( @data, $length );

        $Phred->{$row}[ $col - 1 ] = $length;

        $Growth->{$row}[ $col - 1 ]  = $Info{Growth}[$index];
        $Warning->{$row}[ $col - 1 ] = $Info{Read_Warning}[$index];
        $Length->{$row}[ $col - 1 ]  = $Info{Sequence_Length}[$index];
        $index++;
    }

    my $View     = HTML_Table->new();
    my $qualView = new HTML_Table();
    my $seqView  = new HTML_Table();
    $View->Set_Padding(0);
    $View->Set_Spacing(0);
    $qualView->Set_Padding(0);
    $qualView->Set_Spacing(0);
    $seqView->Set_Padding(0);
    $seqView->Set_Spacing(0);
    ##### Print headers ...

    my $endNumber = 12;
    my $endLetter = 'H';

    ######### make larger image for 384 well plates...
    if ( $size =~ /384/ ) { $endNumber = 24; $endLetter = 'P'; }

    my @headers;
    unless ( $mini_version =~ /mini/ ) {
        @headers = "<Img src='/$URL_dir_name/$image_dir/blank.png' width=25 height=25>";
    }
    foreach my $col ( 1 .. $endNumber ) {
        unless ( $mini_version =~ /mini/ ) {
            push( @headers, "<Img src='/$URL_dir_name/$image_dir/../wells/$col.png' width=25 height=25>" );
        }
    }
    $View->Set_Row(     [@headers] );
    $qualView->Set_Row( [@headers] );
    $seqView->Set_Row(  [@headers] );
    foreach my $row ( 'A' .. $endLetter ) {
        my @row_info;
        my @qualrow_info;
        my @seqrow_info;
        unless ( $mini_version =~ /mini/ ) {
            @row_info     = ("<Img src='/$URL_dir_name/$image_dir/../wells/$row.png' width=25 height=25>");
            @qualrow_info = ("<Img src='/$URL_dir_name/$image_dir/../wells/$row.png' width=25 height=25>");
            @seqrow_info  = ("<Img src='/$URL_dir_name/$image_dir/../wells/$row.png' width=25 height=25>");
        }
        foreach my $col ( 1 .. $endNumber ) {
            my $val;
            if    ( !defined( $Length->{$row}[ $col - 1 ] ) ) { $val = 'N/A'; }
            elsif ( $Length->{$row}[ $col - 1 ] <= 0 )        { $val = 'Null'; }
            else                                              { $val = $Phred->{$row}[ $col - 1 ]; }

            my $map;
            my $qualmap;

            if ( $val =~ /N\/A/ ) {
                $map     = "<Img src='/$URL_dir_name/$image_dir/../colour/black.png' width=25 height=25 alt='Unused' border=0>";
                $qualmap = '';
            }
            else {
                $map = &colour_map( $val, $range, 12, $Growth->{$row}[ $col - 1 ], "$row$col" ) || "($run_id)";
                $qualmap = "$val";
            }

            if ( $mini_version =~ /mini/ ) {
                $map =~ s/s.\.png/pixel\.png/;
                $map =~ s/\=25/\=10/g;
            }
            my $padded_col = $col;
            if ( $col < 10 ) { $padded_col = '0' . $col; }

            my $link = "$trace_link?runid=$run_id&well=$row$padded_col&height=300&width=1000&dbase=$dbc->{dbase}&host=$dbc->{host}";
            push( @row_info, &Link_To( $link, $map, undef, undef, ['newwin'], "onMouseOver='select($row$col,1)' onMouseOut='select($row$col,0)'" ) );
            push( @qualrow_info, &Link_To( $link, $qualmap, undef, undef, ['newwin'] ) );
            push( @seqrow_info, &Link_To( $dbc->homelink(), "$row${padded_col}", "&DisplaySequence=$run_id&Well=$row${padded_col}", undef, ['newwin'] ) );
        }
        $View->Set_Row(     [@row_info] );
        $qualView->Set_Row( [@qualrow_info] );
        $seqView->Set_Row(  [@seqrow_info] );
    }

    $run_view .= "<TABLE>\n" . "<TR>\n<TD>\n";

    my %layers;
    $layers{'Map'}      = $View->Printout(0);
    $layers{"Length"}   = $qualView->Printout(0);
    $layers{"Sequence"} = $seqView->Printout(0);

    my @order = ( "Map", "Length", "Sequence" );

    $run_view .= &define_Layers(
        -layers    => \%layers,
        -tab_width => 20,
        -order     => \@order,
        -default   => 'Map'
    );

    #    $run_view .= &SDB::HTML::create_swap_link(-linkname=>"View Map / $trimming Length",-html=>\@map_tables);

    $run_view .= "</TD>\n<TD>\n";

    $run_view .= &Bin_counts( \@data, 'type' => 'dist,cum', 'title' => $title, x_max => $x_max );
    $run_view .= "</TD></TR><TR><TD colspan = 2>";
    $run_view .= colour_map_legend( $range, 12 );
    $run_view .= "</TD></TR></Table>";

    unless ( $mini_version =~ /mini/i ) {
        $run_view .= start_custom_form( -parameters => {} );
        $run_view .= "Phred Threshold : " . textfield( -name => 'Phred Score', -size => 5, -default => $phred_score ) . " ";
        $run_view .= submit( -name => 'ReDraw using new Phred Score Threshold', -class => "Search" );
        $run_view .= &vspace(5) . ' Trimming: ' . radio_group( -name => 'Trimming', -value => [ 'No Trimming', 'Q20', 'Quality Trimmed', 'Vector/Quality Trimmed', 'Amplicon' ], -label => [ 'None', 'Q20', 'Quality', 'Vector' ], -default => 'Q20' );
        $run_view .= hidden( -name => 'SeqRun_View', -value => $run_id ), $run_view .= "</FORM>";
    }

    return $run_view;
}

##########################
sub meta_length {
##########################
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $qleft       = $args{-qleft};
    my $ql          = $args{-ql};
    my $sl          = $args{-sl};
    my $qv          = $args{-qv};
    my $phred_score = $args{ -phred_score } || 20;
    my $scores      = $args{-scores};
    my $trimming    = $args{-trimming} || 'Q20';
    my $sample      = $args{-sample};
    my $percent     = $args{-percent};
    my $debug       = $args{-debug};

    my @full_array = @$scores;
    my @array;

    my $sample_trimming = $trimming;
    if ( $trimming eq 'Amplicon' ) {
        $percent = 1;
        ## use region of 1..Amplicon Length if supplied as an attribute ##
        my ($amplicon) = $dbc->Table_find( 'Sample_Attribute,Attribute', 'Attribute_Value', "WHERE FK_Sample__ID=$sample AND FK_Attribute__ID=Attribute_ID AND Attribute_Name LIKE 'Amplicon_Length'" );
        if   ($amplicon) { $sample_trimming = "Q$phred_score % (1-$amplicon)" }
        else             { $sample_trimming = "Q$phred_score % (full length')" }
    }

    my $length = $ql;
    if ( $sample_trimming =~ /(vector|quality)/i ) {    ## trim for quality length (& optionally vector)
        if ( ( $sample_trimming =~ /vector/i ) && ( $qv > 0 ) ) { $length -= $qv; }

        @array = @full_array[ $qleft .. $ql + $qleft - 1 ];
    }
    elsif ( $sample_trimming =~ /^no/i ) {              ## no trimming (use sequence length)
        $length = $sl;
    }
    else {
        ## default shows Q20 count ##
        if ( $sample_trimming =~ /Q(\d+)/ ) {
            $phred_score ||= $1;
        }

        if ( $sample_trimming =~ /(\d+)\-(\d+)/ ) {
            my $start = $1 - 1;
            my $end   = $2 - 1;

            ## only show stats for given region within read (used for amplicon sequencing - only applicable over region of amplicon length)
            @array = @full_array[ $start .. $end ];
        }
        else { @array = @full_array }

        ## recalculate length
        $length = 0;
        foreach my $bp (@array) {
            if ( $bp >= $phred_score ) {
                $length++;
            }
        }
    }

    if ( !int(@array) ) {
        @array           = @full_array;
        $length          = int(@full_array);
        $sample_trimming = 'Off';
    }

    if ($percent) { $length = int( $length / int(@array) * 100 ) }

    return ( $length, \@array, $sample_trimming );
}

####################################################
#
# Displays an HTML view of a run as a
# series of colourful circles, where the
# colours correspond to the number of reads above
# a certain Phred score threshhold
#
# In this case the quadrants are interleaved as they actually appear on the plate.
#  (rather than being separated by quadrant)
#
###############################
sub interleaved_run_view {
###############################
    my %args = filter_input( \@_, -args => [ 'run_id', 'phred', 'reduce', 'trimming' ], -mandatory => ['run_id'] );

    my $run_ids      = $args{-run_id};
    my $phred_score  = $args{-phred} || 20;
    my $mini_version = $args{-reduce};        ###### option for mini-view...
    my $trimming     = $args{-trimming};
    my $dbc          = $args{-dbc};
    my $MSB          = $phred_score * 2;
    my $LSB          = $MSB + 1;
    my $range        = $args{-range};

    my $title = "P" . $phred_score . " quality / read";
    if ( $trimming eq 'Amplicon' ) {
        $range = 120;
        $title .= ' (%)';

    }
    else { $range = 1200 }
    my $x_max = $range;    ## for histograms

    my @runs_list = split ',', $run_ids;
    my @reordered_list;
    my $error_flag = 0;
    foreach my $quad ( 'a' .. 'd' ) {
        my $run_id = join ',', $dbc->Table_find( 'MultiPlate_Run', 'FK_Run__ID', "where MultiPlate_Run_Quadrant = '$quad' and FK_Run__ID in ($run_ids)" );
        if ( $run_id =~ /\d+/ ) {
            push( @reordered_list, $run_id );
        }
        else {
            Message("NOTE: Quadrant $quad MISSING from Runs: $run_ids.");
            push( @reordered_list, '0' );
            $error_flag = 1;
        }
    }

    # if there is an error, return
    if ($error_flag) {
        Message("ERROR: Cannot interleave specified runs");
    }
    print "<Font size=+2><B><span class=darkbluetext>Runs @reordered_list ($trimming): </span></B></Font> ";

    unless ( int(@runs_list) > 1 ) { Message("Can only interleave 4 plates"); return 0; }

    my %Info = &Table_retrieve(
        $dbc, 'Clone_Sequence',
        [ 'FK_Run__ID as ID', 'Well', 'Phred_Histogram', 'Sequence_Scores', 'Sequence_Length', 'Left(Growth,2) as Growth', 'Quality_Length', 'Vector_Quality', 'FK_Sample__ID' ],
        "where FK_Run__ID in ($run_ids) Order by Well"
    );

    my $Phred         = {};
    my $Growth        = {};
    my $Warning       = {};
    my $Length        = {};
    my $Run           = {};
    my $Original_Well = {};

    my @data;
    my $index = 0;
    while ( defined $Info{Well}[$index] ) {
        ####### get Quadrant #######

        my $quadrant;
        if ( $Info{ID}[$index] == $reordered_list[0] ) { $quadrant = 'a'; }
        if ( $Info{ID}[$index] == $reordered_list[1] ) { $quadrant = 'b'; }
        if ( $Info{ID}[$index] == $reordered_list[2] ) { $quadrant = 'c'; }
        if ( $Info{ID}[$index] == $reordered_list[3] ) { $quadrant = 'd'; }

        ( my $well ) = $dbc->Table_find( 'Well_Lookup', 'Plate_384', "where Plate_96 = '" . $Info{Well}[$index] . "' and Quadrant = '$quadrant'" );

        my $row;
        my $col;
        if ( $well =~ /([a-zA-Z]{1})(\d+)/ ) { $row = uc($1); $col = $2; }

        my $packed20 = $Info{Phred_Histogram}[$index];
        my @unpacked_val = unpack "S*", $packed20;

        my $scores = $Info{Sequence_Scores}[$index];
        my @unpacked_scores = unpack "C*", $scores;

        my $p20 = $unpacked_val[$phred_score];

        my $ql     = $Info{Quality_Length}[$index];
        my $qv     = $Info{Vector_Quality}[$index];
        my $sl     = $Info{Sequence_Length}[$index];
        my $sample = $Info{FK_Sample__ID}[$index];

        my ($length) = meta_length( -dbc => $dbc, -ql => $ql, -qv => $qv, -sl => $sl, -phred => $phred_score, -scores => \@unpacked_scores, -trimming => $trimming, -sample => $sample );
        $Phred->{$row}[ $col - 1 ] = $length;

        push( @data, $length );

        $Growth->{$row}[ $col - 1 ]        = $Info{Growth}[$index];
        $Warning->{$row}[ $col - 1 ]       = $Info{Read_Warning}[$index];
        $Length->{$row}[ $col - 1 ]        = $Info{Sequence_Length}[$index];
        $Run->{$row}[ $col - 1 ]           = $Info{ID}[$index];
        $Original_Well->{$row}[ $col - 1 ] = $Info{Well}[$index];
        $index++;
    }

    my $View     = HTML_Table->new();
    my $qualView = new HTML_Table();
    my $seqView  = new HTML_Table();
    $View->Set_Padding(0);
    $View->Set_Spacing(0);
    $qualView->Set_Padding(0);
    $qualView->Set_Spacing(0);
    $seqView->Set_Padding(0);
    $seqView->Set_Spacing(0);
    ##### Print headers ...

### set limits for 384 well plate.
    my $endNumber = 24;
    my $endLetter = 'P';

    my @headers;
    unless ( $mini_version =~ /mini/ ) {
        @headers = "<Img src='/$URL_dir_name/$image_dir/blank.png' width=25 height=25>";
    }
    foreach my $col ( 1 .. $endNumber ) {
        unless ( $mini_version =~ /mini/ ) {
            push( @headers, "<Img src='/$URL_dir_name/$image_dir/../wells/$col.png' width=25 height=25>" );
        }
    }
    $View->Set_Row(     [@headers] );
    $qualView->Set_Row( [@headers] );
    $seqView->Set_Row(  [@headers] );
    foreach my $row ( 'A' .. $endLetter ) {
        my @row_info;
        my @qualrow_info;
        my @seqrow_info;
        unless ( $mini_version =~ /mini/ ) {
            @row_info     = ("<Img src='/$URL_dir_name/$image_dir/../wells/$row.png' width=25 height=25>");
            @qualrow_info = ("<Img src='/$URL_dir_name/$image_dir/../wells/$row.png' width=25 height=25>");
            @seqrow_info  = ("<Img src='/$URL_dir_name/$image_dir/../wells/$row.png' width=25 height=25>");
        }
        foreach my $col ( 1 .. $endNumber ) {
            my $val;
            if    ( !defined( $Length->{$row}[ $col - 1 ] ) ) { $val = 'N/A'; }
            elsif ( $Length->{$row}[ $col - 1 ] <= 0 )        { $val = 'Null'; }
            else                                              { $val = $Phred->{$row}[ $col - 1 ]; }

            my $map;
            my $qualmap;
            if ( $val =~ /N\/A/ ) {
                $map     = "<Img src='/$URL_dir_name/$image_dir/../colour/black.png' width=25 height=25 alt='Unused' border=0>";
                $qualmap = '';
            }
            else {
                $map = &colour_map( $val, $range, 12, $Growth->{$row}[ $col - 1 ], "$row$col" );
                $qualmap = $val;
            }

            if ( $mini_version =~ /mini/ ) {
                $map =~ s/s.\.png/pixel\.png/;
                $map =~ s/\=25/\=10/g;
            }

            my $run_id = $Run->{$row}[ $col - 1 ];
            my $Owell  = $Original_Well->{$row}[ $col - 1 ];
            if ( $run_id =~ /\d+/ ) {
                my $link = "$trace_link?runid=$run_id&well=$Owell&height=300&width=1000";
                push( @row_info, &Link_To( $link, $map, '', $Settings{LINK_COLOUR}, ['newwin'], "onMouseOver='select($row$col,1)' onMouseOut='select($row$col,0)'" ) );
                push( @qualrow_info, &Link_To( $link, $qualmap, undef, undef, ['newwin'] ) );
                push( @seqrow_info, &Link_To( $dbc->homelink(), "$row$col", "&DisplaySequence=$run_id&Well=$Owell", undef, ['newwin'] ) );
            }
            else { push( @row_info, $map ); }    ### no run_id for this quadrant..
        }
        $View->Set_Row(     [@row_info] );
        $qualView->Set_Row( [@qualrow_info] );
        $seqView->Set_Row(  [@seqrow_info] );
    }

    #    $View->Printout();
    #    print &vspace(),
    #    &colour_map_legend($range,12),&vspace();

    print "<Table>" . "<TR><TD>";

    my %layers;
    $layers{'Map'}      = $View->Printout(0);
    $layers{"Length"}   = $qualView->Printout(0);
    $layers{"Sequence"} = $seqView->Printout(0);

    my @order = ( "Map", "Length", "Sequence" );

    print &define_Layers(
        -layers    => \%layers,
        -tab_width => 20,
        -order     => \@order,
        -default   => 'Map'
    );

    print "</TD><TD>";

    #  my @Results = $Connection->Table_find_array('Clone_Sequence,Run',[SQL_phred($phred_score)],
    #				  "where FK_Run__ID=Run_ID AND Growth != 'No Grow' AND Run_ID=$run_id");
    print &Bin_counts( \@data, 'type' => 'dist,cum', 'title' => $title, x_max => $x_max );

    print "</TD></TR><TR><TD colspan = 2>";
    print colour_map_legend( $range, 12 );
    print "</TD></TR></Table>";

    #    unless ($mini_version=~/mini/i) {
    #    print start_barcode_form(),
    print start_custom_form( -parameters => { &Set_Parameters() } );
    print "Phred Threshold : ", textfield( -name => 'Phred Score', -size => 5, -default => $phred_score ), " ", submit( -name => 'ReDraw using new Phred Score Threshold', -class => "Search" ), &vspace(5), ' Trimming: ',
        radio_group( -name => 'Trimming', -value => [ 'No Trimming', 'Q20', 'Quality Trimmed', 'Vector/Quality Trimmed' ], -label => [ 'None', 'Q20', 'Quality', 'Vector' ], -default => 'Q20' ), hidden( -name => 'SeqRun_View', -value => $run_ids ),
        hidden( -name => 'Interleave View', -value => $run_ids ), "\n</FORM>\n";
    require alDente::Run_Statistics;
    print &alDente::Run_Statistics::summary_stats( -run_ids => $run_ids, -dbc => $dbc );

    #    }
    return;
}

###################
sub Bin_counts {
###################
    #
    # show histogram of results using specified bin_size and number of bins...
    #
    my $data_ref = shift;
    my %args     = @_;

    my $remove_zero = $args{'remove_zero'} || 0;
    my $title       = $args{'title'}       || 'P20 quality / Read';
    my $type        = $args{'type'}        || '';
    my $x_max       = $args{'x_max'};

    my $cum = 0;    ### include cumulative distribution
    if ( $type =~ /cum/i ) {
        $cum = 1;
    }
    my $dist = 0;    ### include standard distribution
    if ( $type =~ /dist/i ) {
        $dist = 1;
    }

    my $binsize = 10;

    # generate a random number to use as part of the name
    my $randname = rand();

    # get the eight least significant figures
    $randname = substr( $randname, -5 );

    my $stamp = &RGTools::RGIO::timestamp() . $randname;

    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@$data_ref);
    my %Distribution = $stat->frequency_distribution( $stat->max() - $stat->min() );
    ### set all values to stat->max (distribution does not work in this case)
    if ( $stat->max() == $stat->min() ) {
        $Distribution{ int( $stat->max() ) } = int(@$data_ref);
    }

    my @Dist = @{ pad_Distribution( \%Distribution, -binsize => 10 ) };

    my ( $DistHist, $Dzeros, $Dmax ) = &alDente::Data_Images::generate_run_hist(
        x_max => $x_max,

        data        => \@Dist,
        filename    => "DistBin.$stamp.png",
        xlabel      => $title,
        remove_zero => $remove_zero
    );
    my @Cum = @Dist;
    foreach my $index ( 1 .. $#Dist ) {
        $Cum[ $#Dist - $index ] = $Dist[ $#Dist - $index ] + $Cum[ $#Dist - $index + 1 ];
    }
    my ( $CumHist, $Czeros, $Cmax ) = &alDente::Data_Images::generate_run_hist(
        x_max       => $x_max,
        data        => \@Cum,
        filename    => "CumBin.$stamp.png",
        xlabel      => $title,
        remove_zero => $remove_zero,
        yline       => 50
    );
    my $output = "<Table>";
    if ($dist) {
        $output .= "<TR><TD class=small><B>$title Distribution:</B></TD></TR>" . "<TR><TD>$DistHist</TD></TR>";
    }
    if ($cum) {
        $output .= "<TR><TD class=small><B>Cumulative Distribution:</B></TD></TR>" . "<TR><TD>$CumHist</TD></TR>";
    }
    $output .= "</Table>";

    return $output;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
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

$Id: Sequence.pm,v 1.45 2004/10/27 18:23:51 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
