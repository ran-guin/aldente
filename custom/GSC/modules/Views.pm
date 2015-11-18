###################################################################################################################################
# GSC::GSC_View.pm
#
#
#
#
###################################################################################################################################
package GSC::Views;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use Data::Dumper;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use GSC::Model;
## alDente modules
use vars qw( $Connection $homelink %Configs );

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $self = {};
    $self->{dbc} = $dbc;
    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}

# display_genome_reference()
#
# Usage:
#   my $view = $self->display_genome_reference(-library_reference=>$library_reference);
#
# Returns: Formatted view for the raw data
###########################
sub display_genome_reference {
###########################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $library = $args{-library};

    my @library_list = Cast_List( -list => $library, -to => 'Array' );

    my $dbc = $self->{dbc};
    my $gsc = GSC::Model->new( -dbc => $dbc );

    my @results;
    foreach my $libr (@library_list) {

        #push @results, $libr;
        my $linfo;
        $linfo = $gsc->determine_genome_reference( -library => $libr );
        my $output;
        my @library_reference = Cast_List( -list => $linfo, -to => 'Array' );
        my $pooled = 0;
        if ( int(@library_reference) > 1 ) {
            $pooled = 1;
            foreach my $lr (@library_reference) {
                my $lib;
                $lib = $lr->{Library};
                my $genome_id           = $lr->{Genome_ID}           || '';
                my $target_length       = $lr->{Target_Length}       || '';
                my $determination_level = $lr->{determination_level} || '';
                my $genome;
                if ($genome_id) {
                    ($genome) = $dbc->Table_find( 'Genome', 'Genome_Name', "WHERE Genome_ID = $genome_id" );
                }
                $output .= "$lib <br>";
                $output .= "$genome <br>";
                $output .= "<B>$determination_level</B> <br>";
                if ($target_length) {
                    $output .= "Target Length $target_length<br>";
                }

            }
        }
        elsif ( int(@library_reference) == 1 ) {
            my $genome_id           = $library_reference[0]->{Genome_ID};
            my $target_length       = $library_reference[0]->{Target_Length};
            my $determination_level = $library_reference[0]->{determination_level};
            my $genome;
            if ($genome_id) {
                ($genome) = $dbc->Table_find( 'Genome', 'Genome_Name', "WHERE Genome_ID = $genome_id" );
            }
            $output .= "$genome<br>";
            $output .= "<B>$determination_level</B><br>";
            if ($target_length) {
                $output .= "Target Length $target_length<br>";
            }
        }
        else {

        }
        if ($pooled) {
            $output = SDB::HTML::create_tree( -tree => { "$libr" => $output } );
        }
        push @results, $output;
    }
    return \@results;
}

#############################
sub display_Shipments {
#############################
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc} || $self->{dbc};
    my $limit_to_dept = $args{-limit};                 # limits it to shipments sent from and to this department

    require alDente::Shipment_Views;
    my $Shipment_Views = new alDente::Shipment_Views( -dbc => $dbc );

    my $grp_ids;
    if ($limit_to_dept) {
        $grp_ids = join ',', $dbc->Table_find( 'Grp,Department', 'Grp_ID', "WHERE FK_Department__ID = Department_ID and Department_Name LIKE '$limit_to_dept' and Grp_Name <> 'public'", -distinct => 1 );
    }

    my $last_month = substr( date_time( -offset => '-30d' ), 0, 10 );

    my $layers = { 'External Import' => $self->display_BCR_Batch_Shipments( -groups => $grp_ids, -condition => "Shipment_Received >= '$last_month'" ) };

    my $page = $Shipment_Views->display_Shipments( -limit => $limit_to_dept, -layers => $layers );

    return $page;
}

#
# Customized for BCR Batch information .... remove from alDente
#
# Return: printed out table....
####################################
sub display_BCR_Batch_Shipments {
####################################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $grp_ids   = $args{-groups};                # limits it to shipments sent from and to this groups [list of ids comma seperated]
    my $from      = $args{-from};                  # limits it to shipments to sent from this groups [list of ids comma seperated]
    my $to        = $args{-to};                    # limits it to shipments tp sent to and to this groups [list of ids comma seperated]
    my $condition = $args{-condition} || 1;
    my $debug     = $args{-debug};

    $condition .= " AND Shipment_Type = 'Import'";
    my ($batch_attribute) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Source' AND Attribute_Name = 'BCR_Batch'" );
    my ($plate_attribute) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Source' AND Attribute_Name = 'Plate_Identifier'" );
    if ($grp_ids) {
        $condition .= " AND (FKFrom_Grp__ID  IN ($grp_ids) OR FKTarget_Grp__ID IN ($grp_ids) )";
    }
    elsif ($from) {
        $condition .= " AND FKFrom_Grp__ID  IN ($from) ";
    }
    elsif ($to) {
        $condition .= " AND FKTarget_Grp__ID IN ($to) ";
    }

    my $table = $dbc->Table_retrieve_display(
        "Shipment LEFT JOIN Source ON FK_Shipment__ID = Shipment_ID LEFT JOIN Original_Source ON FK_Original_Source__ID=Original_Source_ID 
                LEFT JOIN Anatomic_Site ON FK_Anatomic_Site__ID=Anatomic_Site_ID 
                LEFT JOIN Source_Attribute AS Batch ON Batch.FK_Source__ID=Source_ID AND Batch.FK_Attribute__ID=$batch_attribute 
                LEFT JOIN BCR_Batch ON Batch.Attribute_Value = BCR_Batch.BCR_Batch_ID
                LEFT JOIN Source_Attribute AS Plate_Identifier ON Plate_Identifier.FK_Source__ID=Source_ID AND Plate_Identifier.FK_Attribute__ID=$plate_attribute
                LEFT JOIN Project ON FKReference_Project__ID = Project_ID
                ",
        [   'Shipment_ID as Shipment',
            'Shipment_Status',
            'GROUP_CONCAT(DISTINCT Project_Name) as Project',
            'Shipment.FKSupplier_Organization__ID as Supplier',
            'Shipment_Sent',
            'Shipment_Received',
            'FK_Submission__ID as Submission',
            'Count(Distinct Source_ID) as Sources',
            'Count(Distinct Original_Source_ID) as Specimens',
            'Min(Original_Source_Name) as First_Sample',
            'Max(Original_Source_Name) as Last_Sample',
            'GROUP_CONCAT(distinct BCR_Batch_ID) AS BCR_Batch',
            'GROUP_CONCAT(Distinct Plate_Identifier.Attribute_Value) as Plates',
        ],
        "WHERE  $condition
        GROUP BY Shipment_ID  
        ORDER BY Shipment_ID DESC",
        -return_html     => 1,
        -title           => 'Current Samples',
        -total_columns   => 'Samples,Sources,Specimens',
        -style           => 'font-size:80%',
        -list_in_folders => [ 'BCR_Batch', 'Plates' ],
        -print_link      => 'BCR_Batch_shipments',
        -debug           => $debug,
    );
    return $table;
}

1;
