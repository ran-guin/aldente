##############################################################################################################
#alDente::Invoice_Pipeline_App.pm
#
#
#
#
##############################################################################################################
package alDente::Invoice_Pipeline_App;
use base RGTools::Base_App;
use strict;

##############################
#     custom_modules_ref     #
##############################

### Reference to alDente modules

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Object;

use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

use alDente::SDB_Defaults;
use alDente::Invoice_Pipeline;

use vars qw(%Configs);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'home_page'                    => 'home_page',
        'Change Active Status'         => 'change_active_status',
        'Add New Invoiceable Pipeline' => 'new_pipeline',
    );

    my $dbc = $self->param('dbc');
    return $self;
}

##############################
#
# changes the active status of invoice pipeline
# selection between 'Active' or 'Inactive' is mandatory
#
##############################
sub change_active_status {
##############################

    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $requested_status = $q->param('Invoice_Pipeline_Status');    ## get the status enum options
    my $time             = date_time();
    my $from_view        = '';                                      ## A parameter that tells if command is from the views or not.
    my $from_run         = ();                                      ## Just to make sure its not recursively calling each other.
    my @ids_list;

    push( @ids_list, $q->param('ID') );

    ## If there is no param that is called ID then it is from the views and should be called 'Mark'
    if ( !@ids_list ) {
        $from_view = 'Yes';
        @ids_list  = $q->param('Mark');                             ## gets the Invoice_Pipeline IDs
    }

    my $pipeline_ids_string;

    foreach my $id (@ids_list) {

        my ($old_status) = $dbc->Table_find_array( 'Invoice_Pipeline', ['Invoice_Pipeline_Status'], "WHERE Invoice_Pipeline_ID in ($id)" );

        if ( $requested_status eq $old_status ) {
            print Message("Invoice_Pipeline_ID: $id - already has the $old_status status, thus it has not changed!");
            if ($from_view) {
                next;
            }
        }

        my $updated = $dbc->Table_update_array( 'Invoice_Pipeline', ['Invoice_Pipeline_Status'], ["$requested_status"], "WHERE Invoice_Pipeline_ID IN ($id)", -autoquote => 1 );

        if ($updated) {
            $pipeline_ids_string = $pipeline_ids_string . $id . ",";
        }
        print Message("Invoice pipeline status of ID: $id has been changed to '$requested_status'.");
    }
    if ($pipeline_ids_string) {
        $pipeline_ids_string = substr( $pipeline_ids_string, 0, -1 );
        pipeline_status_change_notification( $dbc, -pipeline_ids => $pipeline_ids_string );
    }
    return;
}

############################
sub new_pipeline {
############################

    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $grey   = $q->param('Grey');
    my $preset = $q->param('Preset');

    my %grey;
    my %preset;
    my %hidden;
    my %list;

    my $navigator = 1;
    my $repeat;
    my $append_html = '';    #add html for hidden parameters
    my %button      = ();

    if ($grey)   { %grey   = %$grey }
    if ($preset) { %preset = %$preset }

    my @pipelines = $dbc->get_FK_info( -field => 'Invoice_Pipeline.FK_Pipeline__ID', -list => 1, -condition => "WHERE Pipeline_Type = 'Bioinformatics'" );
    $list{FK_Pipeline__ID} = \@pipelines;
    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Invoice_Pipeline', -target => 'Database', -append_html => $append_html );
    $table->configure( -grey => \%grey, -preset => \%preset, -omit => \%hidden, -list => \%list );

    return $table->generate( -navigator_on => $navigator, -return_html => 1, -repeat => $repeat, -button => \%button );

}

return 1;
