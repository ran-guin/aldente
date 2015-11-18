################################################################################
# GenechipRun.pm
#
# This module handles GenechipRun based functions
#
###############################################################################
package UHTS::GenechipRun;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

GenechipRun.pm - This module handles GenechipRun based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles GenechipRun based functions<BR>
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
use strict;
use CGI qw(:standard);
use Data::Dumper;
use RGTools::Barcode;
use Imported::XML::Simple;

##############################
# custom_modules_ref         #
##############################
use alDente::Form;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use alDente::Tools;
use SDB::DBIO;
use SDB::CustomSettings;

use SDB::HTML;
use RGTools::RGIO;
use RGTools::Conversion;
use alDente::Sample;
use alDente::Run;
use alDente::Barcoding;
use alDente::Rack;
use alDente::Attribute_Views;

#use vars qw(%Plate_Contents);
##############################
# global_vars                #
##############################
use vars qw($project_dir $Sess $Connection $affy_reports_dir);
use vars qw($testing $current_plates $URL_temp_dir);
use vars qw(%Settings %User_Setting %Configs $user_id %Department_Settings %Defaults %Login $URL_path %Tool_Tips @libraries);
##############################
# modular_vars               #
##############################
my $GCOS_central_upload_dir_test = $Configs{'Data_home_dir'} . "/Trash/GCOS_test/";
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

    my $dbc        = $args{-dbc} || $Connection;    ## database connection
    my $id         = $args{-id};                    ## Run_ID
    my $ids        = $args{-ids};                   ## Run_IDs
    my $encoded    = $args{-encoded} || 0;          ## reference to encoded object (frozen)
    my $attributes = $args{-attributes};

    my $tables = $args{-tables} || 'GenechipRun';
    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => $tables, -encoded => $encoded );
    my ($class) = ref($this) || $this;

    bless $self, $class;
    $self->add_tables('Plate,Run, Library, Project');
    $self->{dbc} = $dbc;

    if ($id) {

        $self->{id} = $id;    ## list of current plate_ids
        $self->primary_value( -table => 'Run', -value => $id );    ## same thing as above..
        $self->load_Object();
        $self->{run_id} = $self->value('GenechipRun.FK_Run__ID');
    }
    elsif ($attributes) {

        #	$self->add_Record(-attributes=>$attributes);
    }

    return $self;
}

##############################
# public_methods             #
##############################

############################
sub load_Object {
#########################
    #
    # Load Plate information into attributes from Database
    #
    my $self = shift;
    my %args = @_;

    my $scope = $args{-scope} || '';
    my $dbc   = $args{-dbc}   || $self->{dbc};

    $self->SUPER::load_Object();

    $self->{plate_id} = $self->value('Run.FK_Plate__ID');

    return 1;
}

##############################################
# Standard Genechip information display
#
#
#
#############
sub home_page {
#############
    #
    # Simple home page for GenechipRun (when id is defined).
    #
    my $self = shift;
    my $dbc  = $self->{dbc} || $Connection;
    my %args = @_;
    $self->load_Object();

    #print HTML_Dump $self;
    my $brief    = $args{-brief};
    my $plate_id = $self->value('Plate.Plate_ID');

    my $run_name     = $self->value('Run.Run_Directory');
    my $library      = $self->value('Plate.FK_Library__Name');
    my $project_path = $self->value('Project.Project_Path');

    print &alDente::Container::Display_Input( -dbc => $dbc );
    print "<Table cellpadding=0><TR><TD valign=top width=100%>";

    if ( $self->{plate_id} ) {
        $self->primary_value( -table => 'Plate', -value => $self->{plate_id} );
    }
    else { $dbc->error("NO Plate defined"); }

    $self->add_tables( [ 'Employee', 'GenechipRun' ] );

    my $run_info = $dbc->get_FK_info( "FK_Run__ID", $self->{id} );
    print "<h2>Experiment File</h2>\n";

    my $file;

    if ( $dbc->{dbase} eq 'sequence' ) {
        my $dir = $project_dir . "/" . $project_path . "/" . $library . "/SampleSheets/";
        $file = $dir . $run_name . ".xml";
    }
    else {    # test case
        my $dir = $project_dir . "/" . $project_path . "/" . $library . "/SampleSheets/";
        $file = $dir . $run_name . ".xml";

        if ( !( -e $file ) ) {
            $dbc->message("not found $file");
            my $dir = $GCOS_central_upload_dir_test . "SampleSheets/";
            $file = $dir . $run_name . ".xml";
        }

    }

    if ( -e $file ) {
        print $self->_display_samplesheet( -file => "$file", -title => $run_info );
    }
    else {
        $dbc->message("Experiment file not found.");
    }
    print "<BR/>";

    #$self->display_actions(-plate_id=>$self->{plate_id});

    my $status = $self->value('Run.Run_Status');
    print "<h2>Run Analysis</h2>\n";
    if ( $status =~ /Analyzed/ ) {
        $self->display_stats();
        $self->display_qc_plot();
    }
    else {
        $dbc->message("Not available");
    }

    ## print out general information at the right hand side of the screen ##
    unless ($brief) {
        print "</TD><TD align=right valign=top bgcolor=white>";
        print $self->display_Record( -tables => [ 'GenechipRun', 'Run', 'Plate' ] );
    }

    print "</TD></TR></Table>";

    return 1;
}

#######################
# Method to parse out the CGI Params. (Execution will reach here if GenechipRun is one of the params)
#
##################
sub request_broker {
##################

}

###########################
# Display general info
###########################
sub display_general {
    my $self   = shift;
    my $dbc    = $self->{dbc} || $Connection;
    my %args   = @_;
    my $run_id = $args{-run_id} || $self->{run_id};    # Run_ID
}

############################################################
# Method to display relevant statistics about a specific run
########################
sub display_stats {
########################
    my $self   = shift;
    my $dbc    = $self->{dbc} || $Connection;
    my %args   = @_;
    my $run_id = $args{-run_id} || $self->{run_id};    # Run_ID
    unless ( ( $run_id =~ /[1-9]/ ) && ( $run_id !~ /,/ ) ) {return}    ## do not allow options unless 1 (and only 1) id given.

    my ($analysis_type) = $dbc->Table_find( "GenechipAnalysis", "Analysis_Type", "WHERE FK_Run__ID=$run_id" );

    # custom code for Mapping runs
    if ( $analysis_type eq 'Mapping' ) {
        $self->display_mapping_stats( -run_id => $run_id );
    }

    # custom code for Expression runs
    elsif ( $analysis_type =~ /Expression/ ) {
        $self->display_expression_stats( -run_id => $run_id );
    }

}

#################################################
# Method to organize statistics for Mapping runs
##############################
sub display_mapping_stats {
###############################
    my $self   = shift;
    my $dbc    = $self->{dbc} || $Connection;
    my %args   = @_;
    my $run_id = $args{-run_id} || $self->{run_id};    ## Run_ID

    my %field_info = $dbc->Table_retrieve( "DBField, DBTable", [ 'Field_Name', 'DBTable_Name' ], "WHERE FK_DBTable__ID = DBTable_ID and DBTable_Name in ('GenechipMapAnalysis') order by Field_Name" );

    my @field_array;
    my $index = 0;
    while ( exists $field_info{Field_Name}->[$index] ) {
        push( @field_array, $field_info{DBTable_Name}->[$index] . "." . $field_info{Field_Name}->[$index] );
        $index++;
    }

    my %info = $dbc->Table_retrieve( "GenechipMapAnalysis", [@field_array], "WHERE GenechipMapAnalysis.FK_Run__ID=$run_id" );

    my $snp_table     = new HTML_Table( -autosort => 1 );
    my $non_snp_table = new HTML_Table( -autosort => 1 );

    my @snp_keys     = ();
    my @non_snp_keys = ();

    foreach my $key ( sort { $a cmp $b } keys %info ) {
        if ( $key =~ /SNP\d+/ ) {
            push( @snp_keys, $key );
        }
        else {
            push( @non_snp_keys, $key );
        }
    }

    # display SNP information
    $snp_table->Set_Title("SNP Information");
    $snp_table->Set_Headers( [ "Field Name", "Value" ] );
    foreach my $key ( sort { substr( $a, 3 ) <=> substr( $b, 3 ) } @snp_keys ) {
        $snp_table->Set_Row( [ $key, $info{$key}[0] ] ) if ( $info{$key}[0] );
    }

    # display the rest of the information
    $non_snp_table->Set_Title("Run Information");
    $non_snp_table->Set_Headers( [ "Name", "Value" ] );
    $non_snp_table->Set_Suffix('');
    foreach my $key ( sort { $a <=> $b } @non_snp_keys ) {
        $non_snp_table->Set_Row( [ $key, $info{$key}[0] ] );
    }

    my %view_layer;
    $view_layer{'Run Information'} = $non_snp_table->Printout(0);
    $view_layer{'SNP Information'} = $snp_table->Printout(0);
    $view_layer{'QC Plot'}         = $self->display_qc_plot();
    return create_tree( -tree => \%view_layer, -tab_width => 100, -default_open => '', -print => 1, -dir => 'horizontal' );

}

#################################################
# Method to organize statistics for Mapping runs
###############################
sub display_expression_stats {
###############################
    my $self   = shift;
    my %args   = @_;
    my $run_id = $args{-run_id} || $self->{run_id};    ## Run_ID
    my $dbc    = $self->{dbc} || $Connection;

    # get the type of analysis (Rat or Human)
    my @analysis_info = $dbc->Table_find( "GenechipAnalysis", "Analysis_Type,GenechipAnalysis_ID", "WHERE FK_Run__ID=$run_id" );
    my ( $analysis_type, $analysis_id ) = split ',', $analysis_info[0];

    my @stats = ( 'Sig3', 'Det3', 'Sig5', 'Det5', 'SigM', 'DetM', 'SigAll', 'Sig35' );

    my %field_info = $dbc->Table_retrieve( "DBField, DBTable", [ 'Field_Name', 'DBTable_Name' ], "WHERE FK_DBTable__ID = DBTable_ID and DBTable_Name in ('GenechipExpAnalysis') order by Field_Name" );

    my @field_array;
    my $index = 0;
    while ( exists $field_info{Field_Name}->[$index] ) {
        push( @field_array, $field_info{DBTable_Name}->[$index] . "." . $field_info{Field_Name}->[$index] );
        $index++;
    }

    my %info = $dbc->Table_retrieve( "GenechipExpAnalysis", [@field_array], "WHERE FK_Run__ID = $run_id" );

    my $exp_analysis_id = $info{"GenechipExpAnalysis_ID"}->[0];

    # retrieve Housekeeping Controls probe set
    my %hc_probe_set_info
        = $dbc->Table_retrieve( "Probe_Set_Value,Probe_Set", [ 'Probe_Set_Name', @stats ], "WHERE FK_Probe_Set__ID=Probe_Set_ID AND Probe_Set_Type='Housekeeping Control' AND FK_GenechipExpAnalysis__ID=$exp_analysis_id", -key => 'Probe_Set_Name' );
    my %sc_probe_set_info
        = $dbc->Table_retrieve( "Probe_Set_Value,Probe_Set", [ 'Probe_Set_Name', @stats ], "WHERE FK_Probe_Set__ID=Probe_Set_ID AND Probe_Set_Type='Spike Control' AND FK_GenechipExpAnalysis__ID=$exp_analysis_id", -key => 'Probe_Set_Name' );

    my $hc_table         = new HTML_Table( -autosort => 1 );
    my $sc_table         = new HTML_Table( -autosort => 1 );
    my $other_info_table = new HTML_Table( -autosort => 1 );

    my @housekeeping_keys = sort { $a cmp $b } keys %hc_probe_set_info;
    my @spike_keys        = sort { $a cmp $b } keys %sc_probe_set_info;
    my @other_keys        = sort { $a cmp $b } keys %info;

    # display Housekeeping Control information
    $hc_table->Set_Title("Housekeeping Control");
    $hc_table->Set_Headers( [ 'Probe_Set', @stats ] );
    foreach my $key ( sort { $a cmp $b } @housekeeping_keys ) {
        my @row = ($key);
        foreach my $stat (@stats) {
            push( @row, $hc_probe_set_info{$key}{$stat}[0] );
        }
        $hc_table->Set_Row( \@row );
    }

    # display Spike Control information
    $sc_table->Set_Title("Spike Control");
    $sc_table->Set_Headers( [ 'Probe_Set', @stats ] );
    foreach my $key ( sort { $a cmp $b } @spike_keys ) {
        my @row = ($key);
        foreach my $stat (@stats) {
            push( @row, $sc_probe_set_info{$key}{$stat}[0] );
        }
        $sc_table->Set_Row( \@row );
    }

    # display the rest of the information
    $other_info_table->Set_Title("Run Information");
    $other_info_table->Set_Headers( [ "Name", "Value" ] );
    foreach my $key ( sort { $a cmp $b } @other_keys ) {
        $other_info_table->Set_Row( [ $key, $info{$key}[0] ] );
    }

    my %view_layer;
    $view_layer{'Run Information'}      = $other_info_table->Printout(0);
    $view_layer{'Housekeeping Control'} = $hc_table->Printout(0);
    $view_layer{'Spike Control'}        = $sc_table->Printout(0);
    $view_layer{'QC Plot'}              = $self->display_qc_plot();
    return create_tree( -tree => \%view_layer, -tab_width => 100, -default_open => '', -print => 1, -dir => 'horizontal' );

}

########################################################
# Options below home_info for GenechipRun containers
#
#
######################
sub display_actions {
######################
    #
    # generate buttons / links that exist as options
    #
    my $self   = shift;
    my %args   = @_;
    my $run_id = $args{-run_id} || $self->{run_id};    # Run_ID
    unless ( ( $run_id =~ /[1-9]/ ) && ( $run_id !~ /,/ ) ) {return}    ## do not allow options unless 1 (and only 1) id given.

    my %parameters = _alDente_URL_Parameters();
    my $form       = 'genechiprun';
    print start_custom_form( $form, undef, \%parameters );

    print "<BR><B>Set Attributes for Genechip Run:</B><BR>";
    print &alDente::Attribute_Views::show_attribute_link( "Run", $self->{run_id} ) . br() . br();

    print "</Form>";

    return;
}

########################################################
# Display QC plot for a genechip run
#
#
########################
sub display_qc_plot {
########################
    my $self    = shift;
    my %args    = @_;
    my $run_id  = $args{-run_id} || $self->{run_id};    # Run_ID
    my $dbc     = $self->{dbc} || $Connection;
    my $run_ids = $args{-run_ids};                      # string of run ids for plotting multiple runs of the same graph.
                                                        # they need to be the same analysis type. e.g., 1,2,3 (will overwrite run_id if specified)

    my $title  = $args{-graph_title};                   # title of the plot
    my $width  = $args{-graph_width} || 500;            # width of the plot
    my $height = $args{-graph_height} || 300;           # height of the plot
    my $layout = $args{-layout} || 'horizontal';        # layout for the two expression graphs

    my $return;

    require RGTools::Graphs;
    my $file_name;
    if ( length $run_ids > 20 ) {
        $file_name = "genechiprun_summary";
    }
    else {
        $file_name = $run_ids . "_summary";
    }

    if ( $run_id && ( !$run_ids ) ) {
        $run_ids = $run_id;
    }

    my ($analysis_type) = $dbc->Table_find( "GenechipAnalysis", "Analysis_Type", "WHERE FK_Run__ID in ($run_ids)" );
    if ( !$title ) {
        $title = $analysis_type . " Analysis";
    }

    if ( $analysis_type =~ /mapping/i ) {    # mapping plot
        my %data;
        $data{'x_axis'} = [ 'QC_AFFX_5Q_456', 'QC_AFFX_5Q_123', 'QC_AFFX_5Q_789', 'QC_AFFX_5Q_ABC' ];
        my @array = $dbc->Table_find( "GenechipMapAnalysis", "FK_Run__ID, QC_AFFX_5Q_456, QC_AFFX_5Q_123, QC_AFFX_5Q_789, QC_AFFX_5Q_ABC", "where FK_Run__ID in ($run_ids)" );

        foreach my $line (@array) {
            my @items = split( ",", $line );
            my $set_name = $items[0];
            $data{$set_name} = [ $items[1], $items[2], $items[3], $items[4] ];
        }

        my $graph = Graphs->new( -height => $height, -width => $width );

        $graph->set_config( -data => \%data, -title => $title, -x_label => 'QC Items', -y_label => 'Values', -show_values => 1 );
        $graph->create_graph( -type => 'line' );

        #my $table_title = $analysis_type ." for Run ".$run_ids;
        #print "<h1>$table_title</h1>";

        $return .= $graph->get_PNG_HTML( -file_path => $URL_temp_dir . "/" . $file_name . ".png", -file_url => "/SDB/dynamic/tmp/" . $file_name . ".png" );

    }
    elsif ( $analysis_type =~ /expression/i ) {    # exp plot
        my @array_humgapdh = $dbc->Table_find(
            "Probe_Set_Value, Probe_Set, GenechipExpAnalysis",
            "FK_Run__ID, Sig3, SigM, Sig5, Sig35",
            " where FK_GenechipExpAnalysis__ID = GenechipExpAnalysis_ID and FK_Run__ID in ($run_ids) and FK_Probe_Set__ID = Probe_Set_ID and Probe_Set.Probe_Set_Name = 'AFFX-HUMGAPDH/M33197'",
            "order by FK_Run_ID"
        );
        my @array_hsac07 = $dbc->Table_find(
            "Probe_Set_Value, Probe_Set, GenechipExpAnalysis",
            "FK_Run__ID, Sig3, SigM, Sig5, Sig35",
            " where FK_GenechipExpAnalysis__ID = GenechipExpAnalysis_ID and FK_Run__ID in ($run_ids) and FK_Probe_Set__ID = Probe_Set_ID and Probe_Set.Probe_Set_Name = 'AFFX-HSAC07/X00351'",
            "order by FK_Run_ID"
        );

        my %data_humgapdh;

        $data_humgapdh{x_axis} = [ "Sig3", "SigM", "Sig5", "Sig35" ];
        foreach my $item (@array_humgapdh) {
            my @items = split( ",", $item );
            $data_humgapdh{ $items[0] } = [ $items[1], $items[2], $items[3], $items[4] ];
        }

        my %data_hsac07;
        $data_hsac07{x_axis} = [ "Sig3", "SigM", "Sig5", "Sig35" ];
        foreach my $item (@array_hsac07) {
            my @items = split( ",", $item );
            $data_hsac07{ $items[0] } = [ $items[1], $items[2], $items[3], $items[4] ];
        }

        if ( scalar( keys %data_humgapdh ) > 1 && scalar( keys %data_hsac07 ) > 1 ) {

            my $graph1 = Graphs->new( -height => $height, -width => $width );

            $graph1->set_config( -data => \%data_humgapdh, -title => $title . ": AFFX-HUMGAPDH/M33197", -x_label => 'QC Items', -y_label => 'Values', -show_values => 1 );
            $graph1->create_graph( -type => 'line' );

            my $graph2 = Graphs->new( -height => $height, -width => $width );
            $graph2->set_config( -data => \%data_hsac07, -title => $title . ": AFFX-HSAC07/X00351", -x_label => 'QC Items', -y_label => 'Values', -show_values => 1 );
            $graph2->create_graph( -type => 'line' );

            my $table_title = $analysis_type . " for Run " . $run_ids;

            #print "<h1>$table_title</h1>";

            if ( $layout eq 'horizontal' ) {

                $return .= $graph1->get_PNG_HTML( -file_path => $URL_temp_dir . "/" . $file_name . "_gapdh.png", -file_url => "/SDB/dynamic/tmp/" . $file_name . "_gapdh.png" );
                $return .= $graph2->get_PNG_HTML( -file_path => $URL_temp_dir . "/" . $file_name . "_hsac.png",  -file_url => "/SDB/dynamic/tmp/" . $file_name . "_hsac.png" );
            }
            else {
                $return .= $graph1->get_PNG_HTML( -file_path => $URL_temp_dir . "/" . $file_name . "_gapdh.png", -file_url => "/SDB/dynamic/tmp/" . $file_name . "_gapdh.png" );
                $return .= "</br>";
                $return .= $graph2->get_PNG_HTML( -file_path => $URL_temp_dir . "/" . $file_name . "_hsac.png",  -file_url => "/SDB/dynamic/tmp/" . $file_name . "_hsac.png" );
            }
        }
        else {
            $return .= "<b>No Data</b>";
        }

    }

    return $return;
}

# display the experiment xml files

##################################
sub _display_samplesheet {
##################################
    my $self  = shift;
    my %args  = @_;
    my $file  = $args{-file};                ## file path
    my $title = $args{-title};               ## table title
    my $data  = XML::Simple::XMLin($file);

    my $sample_template  = $data->{SAMPLE}{template};
    my $exp_template     = $data->{EXPERIMENT}{template};
    my $sample_attribute = $data->{SAMPLE}{ATTRIBUTE};
    my $exp_attribute    = $data->{EXPERIMENT}{ATTRIBUTE};

    my $ss_table = HTML_Table->new( -title => $title, -autosort => 1, -class => 'small' );

    $ss_table->Set_sub_header( "<B>Sample Template: $sample_template</B>", "lightblue" );
    if ( $sample_attribute && ref $sample_attribute eq 'HASH' ) {
        foreach my $key ( sort { $a cmp $b } keys %$sample_attribute ) {
            my $value = $sample_attribute->{$key}{value};
            $ss_table->Set_Row( [ $key, $value ] );
        }
    }
    $ss_table->Set_sub_header( "<B>Experiment Template: $exp_template</B>", "lightblue" );

    if ( $exp_attribute && ref $exp_attribute eq 'HASH' ) {
        foreach my $key ( sort { $a cmp $b } keys %$exp_attribute ) {
            my $value = $exp_attribute->{$key}{value};
            $ss_table->Set_Row( [ $key, $value ] );
        }
    }
    my $stamp = int( rand(10000) );
    return $ss_table->Printout("$URL_temp_dir/samplesheet$stamp.html") . $ss_table->Printout("$URL_temp_dir/samplesheet$stamp.csv") . lbr . $ss_table->Printout(0);

    #return $ss_table->Printout(0);
}

return 1;
