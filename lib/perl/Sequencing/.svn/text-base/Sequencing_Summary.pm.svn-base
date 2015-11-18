package Sequencing::Sequencing_Summary;

@ISA = qw(alDente::View);

use strict;
use CGI qw('standard');

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules
use alDente::View;
use alDente::Run;
use alDente::Fail;

use vars qw($Connection $homelink);

##############################################
# Constructor for the Sequencing Summary Page
#
##############
sub new {
##############
    my $this  = shift;
    my $class = ref($this) || $this;
    my %args  = filter_input( \@_ );

    my $self = {};

    $self                  = alDente::View->new();
    $self->{scope}         = 'run';
    $self->{view_tables}   = 'Run,SequenceRun,Plate,RunBatch';
    $self->{view_name}     = "Sequencing Run Summary Page";
    $self->{key_field}     = 'run_id';
    $self->{link}{library} = "&Scan=1&Barcode=<value>";
    $self->{dbc} = $args{-dbc} || $Connection;

    bless $self, $class;
    return $self;
}

################################
sub preset_input_fields {
################################
    my $self          = shift;
    my $dbc           = $self->{dbc};
    my $preset_inputs = {
        'Library.FK_Project__ID' => { argument => '-project_id' },
        'Run.Run_ID'             => { argument => '-run_id' },
        'Run.Run_Status'         => { argument => '-run_status', default => [ 'Initiated', 'In Process', 'Data Acquired', 'Analyzed' ] },
        'Run.Run_Validation'     => { argument => '-run_validation', default => [ 'Approved', 'Pending' ] },
        'Plate.FK_Library__Name' => { argument => '-library' },
        'Plate.Plate_Number'     => { argument => '-plate_number' },
        'Run.Run_DateTime' => { argument => '', default => '<TODAY>' },
    };
    my @order = qw(
        Library.FK_Project__ID
        Plate.FK_Library__Name
        Plate.Plate_Number
        Run.Run_DateTime
        Run.Run_ID
        Run.Run_Status
        Run.Run_Validation
    );

    $self->configure_input_fields( -fields => $preset_inputs, -order => \@order );
    return 1;
}

#################################
sub preset_output_fields {
#################################
    my $self = shift;

    my @allow = qw(
        run_time
    );

    my @output_field_order = qw(
        run_id
        run_name
        validation
        run_status
        run_comments
    );

    ## set the defaults
    $self->configure_output_fields( -tables => $self->{view_tables}, -prepick => \@output_field_order, -fields => [ @output_field_order, @allow ] );
    $self->{view_defaults} = $self->{view_outputs};

    return 1;
}

#
#
#################
sub home_page {
#################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'display_results,dbc' );

    my $display_results = $args{-display_results};
    my $dbc             = $args{-dbc};
    my $output          = '';

    my $return_string = '';    ## parse_input_parameters();

    if ($return_string) {
        $output = $return_string;
    }
    else {

        ## Display the search options
        my $search_options = $self->display_input_options();

        ## Display the output options with the preset fields
        my $output_options = $self->display_output_options();

        my $search_for_run = $self->get_command_option( -command_name => 'Sequencing_Summary', -value => 'Search for Sequence Runs' );

        my $summary_table = HTML_Table->new( -title => 'Sequencing Summary Page', -colour => 'white' );
        $summary_table->Set_Row( [$search_for_run] );
        $summary_table->Set_Row( [ $search_options, $output_options ] );

        $summary_table->Set_VAlignment('top');

        my %view_layers;
        $view_layers{"Configure Options"} = $summary_table->Printout(0);

        my $configure_options = create_tree( -tree => \%view_layers, -tab_width => 100, -default_open => "Configure Options", -print => 0, -dir => 'horizontal' );

        my $param = { 'Sequencing_Summary' => 1 };
        ## Display the results at the bottom of the page
        my $homelink = $dbc->homelink();
        $output = start_custom_form( 'Searching', $homelink, $param ) . $configure_options . end_form() . start_custom_form( 'Result', $homelink, $param ) . $self->display_summary() . end_form();

    }

    if ($display_results) {
        print $output;
    }
    else {
        return $output;
    }
}

###############################
sub display_input_options {
###############################
    my $self = shift;
    $self->preset_input_fields();
    my $input_options = $self->get_available_input_list();
    return $input_options->Printout(0);
}

################################
sub display_output_options {
################################
    my $self = shift;
    $self->preset_output_fields();

    my $output_options = $self->get_available_output_list();
    return $output_options->Printout(0);
}

################################
#
#
#
#################
sub get_actions {
#################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %actions;

    $actions{1} = submit(
        -name    => 'Set Validation Status',
        -class   => 'Action',
        -onClick => "
        unset_mandatory_validators(this.form);
        document.getElementById('comments_validator').setAttribute('mandatory',(this.form.ownerDocument.getElementById('validation_status').value=='Rejected') ? 1 : 0)
        return validateForm(this.form)
        "
        )
        . '&nbsp;'
        . popup_menu( -name => 'Validation Status', -values => [ '', get_enum_list( $dbc, 'Run', 'Run_Validation' ) ], -default => '', -id => 'validation_status', -force => 1 );

    $actions{2}
        = set_validator( -name => 'Comments', -id => 'comments_validator' )
        . submit( -name => 'Annotate Runs', -class => 'Action', -onClick => "return validateForm(this.form)" )
        . Show_Tool_Tip( textfield( -name => 'Comments', -size => 30, -default => '' ), "Mandatory for Rejected and Failed runs" );

    my $groups = $dbc->get_local('group_list');
    my $reasons = alDente::Fail::get_reasons( -dbc => $dbc, -object => 'Run', -grps => $groups );

    $actions{3} = submit(
        -name    => 'Set as Failed',
        -class   => 'Action',
        -onClick => "
        unset_mandatory_validators(this.form);
document.getElementById('failreason_validator').setAttribute('mandatory',1);
document.getElementById('comments_validator').setAttribute('mandatory',1);
return validateForm(this.form)"
        )
        . '&nbsp;'
        . popup_menu( -name => 'FK_FailReason__ID', -values => [ '', sort keys %{$reasons} ], -labels => $reasons, -force => 1 )
        . set_validator( -name => 'FK_FailReason__ID', -id => 'failreason_validator' );

    return %actions;
}

