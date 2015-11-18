###################################################################################################################################
# alDente::Run_Views.pm
#
#
#
#
###################################################################################################################################
package alDente::Run_Views;

use strict;
use CGI qw(:standard);

use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use RGTools::RGIO;
use RGTools::Views;
use alDente::Run_App;
use alDente::Run;
use alDente::Tools;

use vars qw( %Configs );

########################
# Display the experimental data for the given plate/sample/run.
# ( This method was implemented in Run.pm originally. It's moved here to tidy up the MVC structure for runs. )
#
# Usage:	my $page = alDente::Run_Views::show_run_data( $dbc, -plate_id => [ @parents, $id ], -title => 'Experimental Data', -quiet => 1 );
#
# Return:	HTML string
########################
sub show_run_data {
########################
    # View experiment data ## sequence and gel runs
    #
    my %args = &filter_input( \@_, -args => 'dbc' );

    my $plate_id  = Cast_List( -list => $args{-plate_id},  -to => 'string' );
    my $sample_id = Cast_List( -list => $args{-sample_id}, -to => 'string' );
    my $run_id    = Cast_List( -list => $args{-run_id},    -to => 'string' );

    my $title     = $args{-title};
    my $dbc       = $args{-dbc};
    my $condition = $args{-condition} || '1';
    my $quiet     = $args{-quiet};              # Don't show condition if no experiments are found
    my $debug     = $args{-debug};

    ## provide list of Run 'end-point' tables that may point to individual samples (only applicable if sample_id provided) ##
    my @run_types = $dbc->Table_find( 'DBTable', 'DBTable_Name', "WHERE DBTable_Type = 'Read'" );    ##  qw(Clone_Sequence GenechipAnalysis SpectRead BioanalyzerRead);

    if ($plate_id) { $condition .= " AND FK_Plate__ID IN ($plate_id)" }

    ## <CONSTRUCTION> - need to expand table list to check for samples.. ###
    elsif ($sample_id) {
        my $runs;
        foreach my $run_type (@run_types) {
            $runs .= join ',', $dbc->Table_find( $run_type, 'FK_Run__ID', "WHERE FK_Sample__ID IN ($sample_id)" );
        }
        $runs ||= '0';
        $condition .= " AND Run_ID in ($runs)";
    }
    elsif ($run_id) {
        my $run_list = Cast_List( -list => $run_id, -to => 'string' );
        $condition .= " AND Run_ID in ($run_list)";
    }
    else {
        Message("Please supply either Plate, Run, or Sample");
        return;
    }

    my %runs = $dbc->Table_retrieve( 'Run', [ 'Run_ID', 'Run_Type' ], "WHERE $condition", );

    my %run_types;
    my $index = 0;
    while ( defined $runs{Run_ID}[$index] ) {
        my $type = $runs{Run_Type}[$index];
        if ( $run_types{$type} ) {
            push @{ $run_types{$type} }, $runs{Run_ID}[$index];
        }
        else {
            $run_types{$type} = [ $runs{Run_ID}[$index] ];
        }
        $index++;
    }
    my $page;

    foreach my $type ( keys %run_types ) {
        my $app = alDente::Run_App::get_app( -run_type => $type );
        if ( $app && ( eval "require $app" ) ) {

            # display show_run_data() of sub run app if exists
            my $sub_run_app = $app->new( PARAMS => { dbc => $dbc } );
            $page .= $sub_run_app->show_run_data( -dbc => $dbc, -type => $type, -run_ids => $run_types{$type}, -title => "$title: $type", -quiet => $quiet, -debug => $debug );
        }
        else {

            #default views if no sub run app exists for the run type
            $page .= &show_default_run_data( -dbc => $dbc, -type => $type, -run_ids => $run_types{$type}, -title => "$title: $type", -quiet => $quiet, -debug => $debug );
        }
        $page .= "<P>";
    }

    return $page;
}

sub display_Run_Directory {
#####################
    #       Description:
    #               - This displays a link to the run directory of the given run id
    #               - Method currently implemented in the Run Model and should move it to here
    #               - This uses the Run Model's get_data_path() to get the run directory
    #
    # <snip>
    # Usage Example:
    #       my $page .= alDente::Run_Views::display_Run_Directory(-run_id=>Run_ID);
    #
    # </snip>
#####################
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || param('dbc');
    my $run_id = $args{-run_id} || param('ID');
    my $link;

    my $path = alDente::Run::get_data_path( -dbc => $dbc, -run_id => $run_id );

    $path =~ /\A.*\/([^\/]*)\z/m;
    my $abbreviated_path = $1;
    if ( -e $path ) {
        $link .= Link_To(
            -link_url  => "directory_list.pl",
            -label     => "../$abbreviated_path",
            -param     => "?base_dir=$path",
            -colour    => 'Blue',                   #$Settings{LINK_COLOUR},
            -method    => 'GET',
            -form_name => "dir_listing",
            -window    => "Directory Listing"
        );
    }
    else {
        $link .= RGTools::RGIO::Show_Tool_Tip( "<i>(empty)</i>", "Nothing in: $path." );
    }

    return $link;
}

########################
# Display a link to the sample sheet of the given run id
# ( This method was implemented in Run.pm originally. It's moved here to tidy up the MVC structure for runs. )
#
# Usage:	my $page = alDente::Run_Views::display_Sample_Sheets( -dbc    => $dbc,    -run_id => $run_id  );
#
# Return:	HTML string
########################
#########################
sub display_Sample_Sheets {
#########################
    my %args   = @_;
    my $run_id = $args{-run_id};
    my $dbc    = $args{-dbc};

    my $link_to_ss = '';
    my $run_data_path = alDente::Run::get_data_path( -dbc => $dbc, -run_id => $run_id );

    $run_data_path =~ /\A(.*\/)([^\/]*)\z/m;
    my $parent_path = $1;
    my $filter_on   = $2;

    $parent_path =~ /\A(.*)\/AnalyzedData\/[^\/]*\z/m;
    my $ss_path = "$1/SampleSheets";
    my $exists  = `ls $ss_path/$filter_on*`;

    if ($exists) {
        $link_to_ss = Link_To(
            -link_url  => "directory_list.pl",
            -label     => "../$filter_on",
            -param     => "?base_dir=$ss_path&file_filter=$filter_on",
            -colour    => $Settings{LINK_COLOUR},
            -method    => 'GET',
            -form_name => "ss_listing",
            -window    => "Sample Sheets",
        );
    }
    else {
        $link_to_ss = '(none)';
    }

    return $link_to_ss;
}

############################
# default views for run types without sub run app
#
# Usage:	my $page = alDente::Run_Views::show_default_run_data( -dbc => $dbc, -type => 'SequenceRun', -run_ids => \@run_ids, -title => 'Experimental Data: SequenceRun', -quiet => $quiet, -debug => $debug );
#
# Return:	HTML string
###########################
sub show_default_run_data {
###########################
    my %args  = @_;
    my $dbc   = $args{-dbc};
    my $ids   = $args{-run_ids};
    my $type  = $args{-type};
    my $title = $args{-title};
    my $quiet = $args{-quiet};
    my $debug = $args{-debug};

    my $run_ids = Cast_List( -list => $ids, -to => 'string', -autoquote => 0 );

    my $table = 'Project,Library,Plate,Run';
    $table .= " LEFT JOIN $type on $type.FK_Run__ID=Run_ID";
    my @field_list = ( 'Run_ID', 'FK_Plate__ID', 'Project_Path', 'Library_Name', 'FK_Original_Source__ID', 'Run_Directory', 'Run_Type', 'Run_Status', 'Run_Validation' );
    push @field_list, $type . "_ID";
    my $condition = "WHERE Run_ID in ($run_ids)" . " AND Project.Project_ID=Library.FK_Project__ID" . " AND Library.Library_Name=Plate.FK_Library__Name" . " AND Plate.Plate_ID=Run.FK_Plate__ID";

    my %runs = $dbc->Table_retrieve( $table, [@field_list], $condition, -debug => $debug );

    ## <CONSTRUCTION> Could expand this to generate 'line' similar to that showing up on last 24 hours page ##
    my $analysis_table = HTML_Table->new( -class => 'small', -title => $title );
    my @headers       = ( 'Run Type', 'Experiment', 'Run Status', 'Validation', 'Library', 'Original Source', 'Plate/Tube', '', 'Run Directory', 'Sample Sheets', '' );
    my @added_headers = ();
    my $S_index       = 0;
    while ( defined $runs{'Run_ID'}[$S_index] ) {
        my $run_id   = $runs{'Run_ID'}[$S_index];
        my $plate_id = $runs{'FK_Plate__ID'}[$S_index];

        my $run_name   = get_FK_info( $dbc, 'FK_Run__ID',   $run_id );
        my $plate_name = get_FK_info( $dbc, 'FK_Plate__ID', $plate_id );

        my $plate = &Link_To( $dbc->config('homelink'), $plate_name, "&HomePage=Plate&ID=$plate_id", $Settings{LINK_COLOUR} );
        my $library            = get_FK_info( $dbc, 'FK_Library__Name', $runs{'Library_Name'}[$S_index] );
        my $original_source_id = $runs{'FK_Original_Source__ID'}[$S_index];
        my $original_source    = get_FK_info( $dbc, 'FK_Original_Source__ID', $original_source_id );

        my $thumbnail, my $thumbnail_link_param, my $link_param;
        my @added_rows;
        my $project_path = &alDente::Run::get_data_path( -dbc => $dbc, -run_id => $run_id, -simple => 1 );
        if ( $runs{SequenceRun_ID}[$S_index] ) {
            my $image_file = "data_home/private/Projects/$project_path/phd_dir/Run$run_id.png";
            if ( -e "$URL_dir/$image_file" ) {
                $thumbnail            = "<Img Src ='../dynamic/$image_file'>";
                $thumbnail_link_param = "&SeqRun_View=$run_id";
                $link_param           = "&HomePage=Run&ID=$run_id";
            }
        }
        elsif ( $runs{GelRun_ID}[$S_index] ) {
            ## get run image if available (could be used for any type of experimental results image)
            my $gelrun_id = $runs{GelRun_ID}[$S_index];
            $link_param = "&HomePage=Run&ID=$run_id";
            $thumbnail  = "<img src=../dynamic/data_home/private/Projects/" . $runs{Project_Path}[$S_index] . "/" . $runs{Library_Name}[$S_index] . "/AnalyzedData/" . $runs{Run_Directory}[$S_index] . '/thumb.jpg width=100 height=50>';    ### Gel Image
            $thumbnail_link_param = "&cgi_application=Mapping::Summary_App&rm=Results&Run_ID=$run_id";
        }
        elsif ( $runs{SolexaRun_ID}[$S_index] ) {
            $link_param = "&HomePage=Run&ID=$run_id";
            my @solexarun_info = $dbc->Table_find( 'SolexaRun', 'Lane,FK_Flowcell__ID', "WHERE FK_Run__ID = $run_id" );
            my ( $lane, $flowcell ) = split ',', $solexarun_info[0];
            push @added_rows, $lane;
            push @added_rows, alDente_ref( 'Flowcell', $flowcell, -dbc => $dbc );
            push @added_headers, 'Lane'     unless grep /^Lane$/,     @added_headers;
            push @added_headers, 'Flowcell' unless grep /^Flowcell$/, @added_headers;
        }

        my $link_to_run_directory = display_Run_Directory( -run_id => $run_id, -dbc    => $dbc );
        my $link_to_ss_data       = display_Sample_Sheets( -dbc    => $dbc,    -run_id => $run_id );
        my $thumbnail_display = $thumbnail ? &Link_To( $dbc->config('homelink'), $thumbnail, $thumbnail_link_param, $Settings{LINK_COLOUR} ) : "(no img)";

        my @rows = (
            $runs{Run_Type}[$S_index],
            &Link_To( $dbc->config('homelink'), $run_name, $link_param, $Settings{LINK_COLOUR} ),
            $runs{Run_Status}[$S_index],
            $runs{Run_Validation}[$S_index],
            $library, $original_source, $plate, $thumbnail_display, $link_to_run_directory, $link_to_ss_data, "<- <i>Click to view directory contents</i>"
        );
        $analysis_table->Set_Headers( [ @added_headers, @headers ] );
        $analysis_table->Set_Row( [ @added_rows, @rows ] );

        $S_index++;
    }

    unless ($S_index) {
        if ($quiet) {
            $analysis_table->Set_Row( ["(no experimental data found)"] );
        }
        else {
            $analysis_table->Set_Row( ["No experimental data found"] );
        }
    }

    my $output = $analysis_table->Printout(0);

    ## show process deviation
    if ($S_index) {
        $output .= show_process_deviation( -dbc => $dbc, -run_ids => $run_ids );
    }
    return $output;

}

##########################
# Display process deviations that are associated with the given runs
#
# Usage:	my $page = alDente::Run_Views::show_process_deviation( -dbc => $dbc, -run_ids => '12344,8764' );
#
# Return:	HTML string
##########################
sub show_process_deviation {
##########################
    my %args    = @_;
    my $dbc     = $args{-dbc};
    my $run_ids = $args{-run_ids};                                                                                                                                                                                # comma separated list of run ids
    my @pds     = $dbc->Table_find( 'Process_Deviation_Object,Object_Class', 'FK_Process_Deviation__ID', "WHERE FK_Object_Class__ID = Object_Class_ID and Object_Class = 'Run' and Object_ID in ($run_ids) " );
    my $output  = '';
    if ( int(@pds) ) {
        require alDente::Process_Deviation_Views;
        my $deviation_label = alDente::Process_Deviation_Views::deviation_label( -dbc => $dbc, -deviation_ids => \@pds );
        $output .= '<BR>' . $deviation_label;
    }
    return $output;
}
1;
