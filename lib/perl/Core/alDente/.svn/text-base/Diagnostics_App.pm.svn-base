##################
# Diagnostics_App.pm #
##################
#
# This is a template for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Diagnostics_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##

use RGTools::RGIO;
use SDB::HTML;
use alDente::Diagnostics;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

################
# Dependencies #
################
#
# (document list methods accessed from external models)
#

############
sub setup {
############
    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'home_page'              => 'home_page',
            'show_zoom_in'           => 'show_zoom_in',
            'run_gelrun_diagnostics' => 'run_gelrun_diagnostics'
        }
    );

    my $dbc = $self->param('dbc');
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    ## enable related object(s) as required ##
    my $diagnostic;    # = new alDente::Diagnostics(-dbc=>$dbc);

    $self->param( 'Diagnostic_Model' => $diagnostic, );

    return $self;
}

#####################
#
# home_page (default)
#
# Return: display (table)
#####################
sub home_page {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $home_form = alDente::Form::start_alDente_form( $dbc, -form => 'Diagnostics_home' );
    $home_form .= Views::Heading("Diagnostics Home Page");

    $home_form .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Diagnostics_App', -force => 1 );
    $home_form .= $q->hidden( -name => 'rm', -value => 'home_page', -force => 1 );
    $home_form .= 'Enter Run id(s) to for diagnostics <br>';
    $home_form .= $q->textfield( -name => 'run_ids', -force => 1 );
    $home_form .= RGTools::Web_Form::Submit_Button(
        form         => 'Diagnostics_home',
        name         => 'submit',
        label        => 'Diagnose',
        validate     => 'run_ids',
        validate_msg => 'Please enter a run id first.'
    );
    $home_form .= "<br>\n";
    $home_form .= $q->end_form();

    ## get html output of diagnostics given run ids
    my $run_id = $q->param('run_ids');
    $home_form .= $self->run_diagnostics( -run_id => $run_id );

    return $home_form;
}

sub run_diagnostics {
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $run_id = $args{-run_id};
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $page   = "";

    if ( !$run_id ) { return $page }

    $page .= $run_id;

    my @run_ids = qw(88573 88574 88575 88576 88577 88578 88579 88580 88581);
    my $gelrun  = 1;
    if ($gelrun) {
        @run_ids = qw(86787 86786 86796 86778 87132 87128 87137 87127 87158 87159 87157 87138 87208 87205 87218 87204 87390 87433 87455 87432 87426 87447 87452 87457 87437 87527 87526 87523 87520 87525 87766 87765 87778 87777);
        $page .= $self->run_gelrun_diagnostics( -dbc => $dbc, -run_ids => \@run_ids );
    }
    else {
        $page .= $self->run_sequencing_diagnostics( -dbc => $dbc, -run_ids => \@run_ids );
    }

    #To-Do
    #zoom-in

    return $page;
}

sub run_sequencing_diagnostics {
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'dbc,run_ids' );
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $run_idr = $args{-run_ids};
    my $percent = Extract_Values( [ $args{-percent}, 25 ] );
    my $from    = $args{-from} || '';
    my $upto    = $args{ -until } || '';
            my $debug = 0;

            my @run_ids;
            if ($run_idr) { @run_ids = @{$run_idr} }
    my $add_tables     = 'SequenceRun,SequenceAnalysis';
    my $condition      = "SequenceRun.FK_Run__ID=Run_ID AND SequenceAnalysis.FK_SequenceRun__ID = SequenceRun_ID";
    my $quality        = "Q20mean";
    my @monitor_fields = (
        'FKBuffer_Solution__ID as Buffer',
        'FKMatrix_Solution__ID as Matrix',
        'FKPrimer_Solution__ID as Primer',
        'FK_Equipment__ID as Sequencer',
        'FK_Branch__Code as Branch',
        'FK_Pipeline__ID as Pipeline',
        'RunBatch.FK_Employee__ID as Employee',
        'Wells'
    );
    my $run_link       = "&Run+Department=Cap_Seq&Last+24+Hours=1&Any+Date=1&Run+ID=";    #note this still depends on $homelink in Diagnostics.pm
    my $good_threshold = 850;                                                             ###### (100+$Fpercent)/100;
    my $bad_threshold  = 400;                                                             ######## (100-$Fpercent)/100;

    if ( !@run_ids ) {
        Message "No Selected Runs";
        return;
    }

    ( my $output ) = $self->show_diagnostics(
        -dbc            => $dbc,
        -display_mode   => 'html',
        -condition      => $condition,
        -run_ids        => \@run_ids,
        -add_tables     => $add_tables,
        -quality        => $quality,
        -monitor_fields => \@monitor_fields,
        -run_link       => $run_link,
        -good_threshold => $good_threshold,
        -bad_threshold  => $bad_threshold,
        -debug          => $debug,
        -percent        => $percent,
        -since          => $from,
        -until          => $upto,
    );
    return $output;
}

sub run_gelrun_diagnostics {
    my $self    = shift;
    my $q       = $self->query;
    my %args    = &filter_input( \@_, -args => 'dbc,run_ids' );
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $run_idr = $args{-run_ids};
    my @run_ids = $q->param('FK_Plate__ID');
    my $percent = Extract_Values( [ $args{-percent}, 25 ] );
    my $from    = $args{-from} || '';
    my $upto    = $args{ -until } || '';
            my $debug = 0;

            if ($run_idr) { @run_ids = @{$run_idr} }
    my $add_tables     = 'GelRun,GelAnalysis';
    my $condition      = "GelRun.FK_Run__ID=Run_ID AND GelAnalysis.FK_Run__ID = Run_ID";
    my $quality        = "CASE WHEN Run_Status = 'Failed' THEN 0 ELSE 1 END";
    my @monitor_fields = (
        'RunBatch.FK_Employee__ID as Start_Run_Employee',
        'FK_Equipment__ID as Fluorimager',
        'FKPoured_Employee__ID as Poured_Employee',
        'FKComb_Equipment__ID as Comb',
        'FKAgarose_Solution__ID as Argarose_Solution',
        'FKAgarosePour_Equipment__ID as Poured_Equipment',
        'FKGelBox_Equipment__ID as GelBox',
        'Date(Run_DateTime) as Run_Date',
        'Run_Comments'
    );
    my $run_link       = "&cgi_application=Mapping::Summary_App&rm=Results&Run_ID=";    #note this still depends on $homelink in Diagnostics.pm
    my $good_threshold = 0.75;
    my $bad_threshold  = 0.25;

    if ( !@run_ids ) {
        Message "No Selected Runs";
        return;
    }

    ( my $output ) = $self->show_diagnostics(
        -dbc            => $dbc,
        -display_mode   => 'html',
        -condition      => $condition,
        -run_ids        => \@run_ids,
        -add_tables     => $add_tables,
        -quality        => $quality,
        -monitor_fields => \@monitor_fields,
        -run_link       => $run_link,
        -good_threshold => $good_threshold,
        -bad_threshold  => $bad_threshold,
        -debug          => $debug,
        -percent        => $percent,
        -since          => $from,
        -until          => $upto,
    );
    return $output;
}

# This method is meant to replace show_sequencing_diagnostics in Diagnostics.pm by removing sequencing specific infomation and move it to app
########################################
sub show_diagnostics {
########################################
    my $self    = shift;
    my $q       = $self->query;
    my %args    = &filter_input( \@_, -args => 'dbc,percent,since,until,display_mode' );
    my $dbc     = $args{-dbc};
    my $percent = $args{-percent};                                                         #### percentage above/below average for flagging.
    my $since   = $args{-since};
    my $until   = $args{ -until };
            my $display_mode      = $args{-display_mode};                                  #### flag for html format or email format.
            my $include_test_runs = $args{-include_test} || 0;
            my $condition         = $args{-condition} || 1;                                ## optional additional condition
            my $id_ref            = $args{-run_ids};
            my $debug             = $args{-debug};
            my $add_tables        = $args{-add_tables};
            my $quality           = $args{-quality};
            my $monitor_fieldsr   = $args{-monitor_fields};
            my $run_link          = $args{-run_link};
            my $good_threshold    = $args{-good_threshold};
            my $bad_threshold     = $args{-bad_threshold};

            my $add_conditions = $condition;
            my $ids = join ', ', @$id_ref if $id_ref;
            $condition .= " AND Run_ID IN ($ids)" if $ids;

            # get diagnostics output in display_mode format
            my ( $output, $html ) = get_diagnostics(
         $dbc, $percent, $since, $until, $display_mode, $include_test_runs,
        -condition      => $condition,
        -add_tables     => $add_tables,
        -add_conditions => $add_conditions,
        -quality        => $quality,
        -monitor_fields => $monitor_fieldsr,
        -run_link       => $run_link,
        -good_threshold => $good_threshold,
        -bad_threshold  => $bad_threshold,
        -debug          => $debug
            );

    # format diagnostics output to highlight good/bad runs, only apply to html output

    my $returnval = "<A Name=Top></A>";

    #    my $Verbose=HTML_Table->new();
    #    $Verbose->Set_Title('Item by Item Correlations with Run Quality');
    #    $Verbose->Set_Headers(['Using:','Quality Length','Runs']);

    my $show_poor = 0;    ### flag used to display poor runs..
    my $poor_runs = '';
    my $colour;
    foreach my $line ( split "\n", $output ) {
        if ( $line =~ /^Correlations/i ) {
        }
        if ( $line =~ /^Overall/ ) {
            $returnval .= "\n<A Name=Overall></A>\n";
            $returnval .= $q->h3($line);
        }
        elsif ( $line =~ /^Good/ ) {
            my $state = 'good';

            #	    print h3($line);
            $colour = 'mediumgreenbw';

            #	    $Diagnostics->Set_sub_header("Good Runs (Quality > $percent % above Average)",$color);
        }
        elsif ( $line =~ /^Poor/ ) {
            my $state     = 'bad';
            my $show_poor = 1;       ###### turn on poor runs display.

            #	    print h3($line);
            $colour = 'lightredbw';

            #	    $Diagnostics->Set_sub_header("Poorer Runs (Quality > $percent % above Average)",'lightredbw');
        }
        elsif ( $line =~ /\*/ ) { next; }
        elsif ( $line =~ /^Using(.*):\t(.*)%(.*?)(\d+)/i ) {
            my $item    = $1;
            my $average = $2;
            my $counts  = $4;
            $poor_runs .= "$item\t$average\t$counts\n";
        }
        elsif ( $line =~ /^(.*):(.*?)([\d]+)(.*?(\d+))/i ) {
            my $item    = $1;
            my $average = $2;
            my $counts  = $4;

            #	    $Verbose->Set_Row([$item,$average,$counts],$colour);
        }
        elsif ( $line =~ /^Latest Run:(.*)$/ ) {

            #	    print h3("Latest Recorded Run: $1");
        }
    }
    $returnval .= $q->hr;
    if ($display_mode) { $returnval .= $html; }
    else {
        $output =~ s/\n/<BR>/g;
        $returnval = $output;
    }

    #    if ($verbose) {$Verbose->Printout();}
    return ( $returnval, $poor_runs );    #### return html page and poor_runs listing
}

# This method and get_zoom_in in Diagnostics.pm is meant to replace zoom_in in Diagnostics.pm by removing sequencing specific infomation and move displays to app
#############
sub show_zoom_in {
#############
    my $self           = shift;
    my %args           = &filter_input( \@_ );
    my $dbc            = $args{-dbc} || $self->param('dbc');
    my $q              = $self->query;
    my $zoom_type      = $args{-type} || $q->param('Zoom_Type');
    my $zoom_value     = $args{-value} || $q->param('Zoom');
    my $zoom_condition = $args{-zoom_condition} || $q->param('ZoomCondition') || 'Prep_DateTime > DATE_SUB(CURDATE(), INTERVAL 1 month)';    ## default to last 6 months ##
    my $add_tables     = $args{-add_tables} || $q->param('add_tables');
    my $add_conditions = $args{-add_conditions} || $q->param('add_conditions');
    my $quality        = $args{-quality} || $q->param('quality');
    my $debug          = $args{-debug} || 0;

    my %Hash = get_zoom_in(
        -dbc            => $dbc,
        -zoom_type      => $zoom_type,
        -zoom_value     => $zoom_value,
        -zoom_condition => $zoom_condition,
        -add_tables     => $add_tables,
        -add_conditions => $add_conditions,
        -quality        => $quality,
        -debug          => $debug
    );

    my ($check_field_alias) = grep( /^FK/, keys %Hash );
    print SDB::HTML::display_hash(
        -dbc              => $dbc,
        -title            => "Data results downstream from '$zoom_value' step (by $zoom_type)",
        -hash             => \%Hash,
        -return_html      => 1,
        -toggle_on_column => 'FK_Equipment__ID',
        -keys             => [ $check_field_alias, 'Count', 'Run_Validation', 'Quality' ],
        -average_columns  => 'Quality',
        -total_columns    => 'Count',
        -highlight_string => { 'Rejected' => 'lightred', 'Approved' => 'lightgreen', 'n/a' => 'lightgrey', 'Pending' => 'lightyellow' },
    );

    print &vspace(5);
    print alDente::Form::start_alDente_form( $dbc, -form => "Diagnostics_App" );
    print $q->hidden( -name => 'cgi_application', -value => 'alDente::Diagnostics_App', -force => 1 );
    print $q->hidden( -name => 'rm',              -value => 'show_zoom_in',             -force => 1 );
    print $q->hidden( -name => 'Zoom',            -value => $zoom_value );
    print $q->hidden( -name => 'Zoom_Type',       -value => $zoom_type );
    print $q->hidden( -name => 'add_tables',      -value => $add_tables );
    print $q->hidden( -name => 'add_conditions',  -value => $add_conditions );
    print $q->hidden( -name => 'quality',         -value => $quality );
    print Show_Tool_Tip( $q->textfield( -name => 'ZoomCondition', -size => 120, -default => $zoom_condition ), "optional SQL condition (referencing Plate or Prep fields) - available for rapid customization - see LIMS Admin if needed" );
    print lbr;
    print $q->submit( -name => 'Diagnostics_App', -value => 'Regenerate with extra condition', -class => 'Search' );
    print $q->end_form();

    return;
}

return 1;
