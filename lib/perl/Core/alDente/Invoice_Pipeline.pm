###################################################################################################################################
# alDente::Invoice_Pipeline.pm
#
#
###################################################################################################################################
package alDente::Invoice_Pipeline;

use base SDB::DB_Object;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
## alDente modules

use vars qw( %Configs );

#####################
sub new {
    #####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Invoice_Pipeline' );
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        $self->{id} = $id;
        $self->primary_value( -table => 'Invoice_Pipeline', -value => $id );
        $self->load_Object();
    }

    return $self;
}

##################################
# Input: concated Invoice Pipeline ids (should only pass in those with changed status)
# Notification for pipeline status changes
#
#
##################################
sub pipeline_status_change_notification {
##################################
    my %args         = &filter_input( \@_, -args => 'dbc,pipeline_ids', -mandatory => 'dbc,pipeline_ids' );
    my $dbc          = $args{-dbc};
    my $pipeline_ids = $args{-pipeline_ids};

    # fields for the html table
    my @invoice_pipeline_fields = ( 'Invoice_Pipeline_Name', 'Pipeline_Type', 'Invoice_Pipeline_Status' );

    # html table with given Invoice Pipeline IDs
    my $changed_invoiced_pipeline_html = $dbc->Table_retrieve_display( "Invoice_Pipeline", \@invoice_pipeline_fields, "WHERE Invoice_Pipeline_ID IN ($pipeline_ids)", -title => "List of Edited Invoice_Pipeline", -return_html => 1 );

    my $subject_str = "Invoice Pipeline status change notification";
    my $msg         = "<p ></p>The status of the following invoice pipelines has been changed:<br />";
    $msg .= "$changed_invoiced_pipeline_html";

    require alDente::Subscription;
    my $ok = alDente::Subscription::send_notification(
        -dbc          => $dbc,
        -name         => "Invoice Pipeline Status Change",
        -from         => 'aldente@bcgsc.ca',
        -subject      => "$subject_str - (from Pipeline)",
        -body         => $msg,
        -content_type => 'html'
    );

    return $ok;
}

1;

