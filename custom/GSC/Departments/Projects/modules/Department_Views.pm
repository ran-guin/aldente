package Projects::Department_Views;

use base alDente::Department_Views;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use vars qw(%Configs);

## Specify the icons that you want to appear in the top bar

################
sub home_page {
################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->{dbc};

    return $self->Model->home_page();
}

#####################
sub recent_shipments {
#####################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $last_month = substr( date_time( -offset => '-30d' ), 0, 10 );
    
    my $table = $dbc->Table_retrieve_display(
        "Shipment LEFT JOIN Source ON FK_Shipment__ID = Shipment_ID LEFT JOIN Original_Source ON FK_Original_Source__ID=Original_Source_ID 
                LEFT JOIN Anatomic_Site ON FK_Anatomic_Site__ID=Anatomic_Site_ID ",
        [   'Shipment_ID as Shipment',
            'Shipment_Type',
            'Shipment.FKSupplier_Organization__ID as Supplier',
            'Shipment_Sent',
            'Shipment_Received',
            'FKFrom_Grp__ID as From_Group',
            'FKTarget_Grp__ID as To_Group',
            'FK_Sample_Type__ID',
            'Count(Distinct Source_ID) as Sources',
            'Count(Distinct Original_Source_ID) as Specimens',
            'Min(Original_Source_Name) as First_Sample',
            'Max(Original_Source_Name) as Last_Sample',
            'GROUP_CONCAT(DISTINCT Anatomic_Site_Alias) as Tissues'
        ],
        "WHERE 1 AND Shipment_Sent > '$last_month'
					GROUP BY Shipment_ID  
					ORDER BY Shipment_ID DESC",
        -return_html   => 1,
        -title         => 'Shipments for the last 30 days',
        -total_columns => 'Samples,Sources,Specimens',
        -print_link    => 1,
    );

    return $table;
}

########################################
#
#  Display current list of Qubit runs and thier status
#
##############################
sub Qubit_runs {
##############################
    my %args = filter_input( \@_, -args => 'dbc', -mandatory => 'dbc' );
    my $dbc = $args{-dbc};

    my $table = $dbc->Table_retrieve_display(
        "Run,Qubit_Run,Plate",
        [ 'Run_ID', 'Run_Status', 'Run_DateTime', 'Qubit_Run_Finished', 'FK_Plate__ID', 'FK_Library__Name' ],
        "WHERE FK_Run__ID = Run_ID AND FK_Plate__ID = Plate_ID ORDER BY Run_ID desc",
        -return_html => 1,
        -title       => 'Current Qubit Runs',
        -print_link  => 1,
    );

    return $table;
}

return 1;
