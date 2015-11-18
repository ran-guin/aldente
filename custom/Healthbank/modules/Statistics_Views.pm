package Healthbank::Statistics_Views;

use base Healthbank::Views;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use Healthbank::Model;
use LampLite::Bootstrap;

my $BS = new Bootstrap;
my $q = new CGI;

my ( $session, $account_name );

##################
sub _admin_page {
##################
    my %args = filter_input(\@_, -args=>'dbc,condition');
    my $dbc = $args{-dbc};
    my $extra_condition = $args{-condition} || 1;

    my $tables    = 'Plate,Plate_Sample,Sample,Source,Original_Source,Patient';
    my $condition = "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source.Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID AND FK_Patient__ID=Patient_ID AND $extra_condition";

    my $yesterday = $dbc->Table_retrieve_display(
        $tables, [ 'Plate.FK_Plate_Format__ID', 'Plate.FK_Sample_Type__ID', 'count(distinct Plate_ID) as Active_Tubes', 'count(distinct Original_Source_Name) as Subjects' ],
        "$condition AND Plate.Plate_Status = 'Active' AND Plate_Created >= SUBDATE(CURDATE(), INTERVAL 1 Day) AND Plate_Created < CURDATE() GROUP BY Plate.FK_Plate_Format__ID,Plate.FK_Sample_Type__ID",
        -title         => 'Samples Generated Yesterday',
        -total_columns => 'Active_Tubes',
        -return_html   => 1
    );

    my $today = $dbc->Table_retrieve_display(
        $tables, [ 'Plate.FK_Plate_Format__ID', 'Plate.FK_Sample_Type__ID', 'count(distinct Plate_ID) as Active_Tubes', 'count(distinct Original_Source_Name) as Subjects' ],
        "$condition AND Plate.Plate_Status = 'Active' AND Plate_Created >= CURDATE() GROUP BY Plate.FK_Plate_Format__ID,Plate.FK_Sample_Type__ID",
        -title         => 'Samples Generated Yesterday',
        -total_columns => 'Active_Tubes',
        -return_html   => 1
    );

    my $collected = $dbc->Table_retrieve_display(
        'Source, Original_Source, Patient',
        [   'Source.FK_Plate_Format__ID as Format',
            'count(DISTINCT Source_ID) as Collected',
            'count(DISTINCT Patient_Identifier) AS Subjects',
            'Min(Patient_Identifier) AS First_Subject',
            'Max(Patient_Identifier) AS Last_Subject'
        ],
        "WHERE FK_Original_Source__ID=Original_Source_ID AND FK_Patient__ID=Patient_ID AND $extra_condition GROUP BY Source.FK_Plate_Format__ID",
        -title         => 'Blood Samples Originally Collected',
        -total_columns => 'Collected,Subjects',
        -return_html   => 1
    );

    my $output = $collected;

    $output .= '<hr>';

    $output .= '<p ></p>';
    $output .= Link_To( $dbc->homelink(), ' View Discrepencies (slow)', '&cgi_application=BC_Generations::Department_App&rm=Missing Samples' );
    $output .= '<p ></p>';

    $output .= create_tree( -tree => { ' Generated as of Yesterday' => $yesterday } );
    $output .= create_tree( -tree => { ' Generated Today'           => $today } );
    $output .= '<hr>';

    $output .= '<p ></p>' . alDente::Form::start_alDente_form($dbc, 'backfill') . hidden( -name => 'cgi_application', -value => 'Healthbank::App', -force => 1 );
    $output .= 'Check ' . textfield( -name => 'Times', -size => 5, -default => 1 ) . 'Subjects; Starting at #' . textfield( -name => 'Start', -size => 5, -default => '' );
    $output .= submit( -name => 'rm', -value => 'Backfill Check', -class => 'Search', -force => 1 );
    $output .= end_form();

    $output .= '<HR>';
    $output .= Link_To( $dbc->homelink(), 'Fix EDTA WBC, Plasma Locations', '&cgi_application=Healthbank::App&rm=Fix EDTA' );

    $output .= '<HR>';
    $output .= Link_To( $dbc->homelink(), 'View Service Centres', '&cgi_application=SDB::DB_Form_App&rm=View+Lookup&Table=Service_Centre' );
    return $output;
}

#############
sub stats {
#############
    my $self = shift;
    my $condition = shift || 1;
    my $layer = shift;
    
    my $dbc = $self->dbc();
    
    my $summary = $dbc->Table_retrieve_display('Plate,Plate_Sample,Sample,Source,Original_Source',["SUM(CASE WHEN Plate_Status='Active' THEN 1 ELSE 0 END) as Active_Tubes","SUM(CASE WHEN Plate_Status='Exported' THEN 1 ELSE 0 END) as Exported_Tubes",'count(distinct Source_ID) as SRC_Records','count(distinct External_Identifier) as Onyx_Samples','count(distinct FK_Patient__ID) as Subjects', 'count(distinct Original_Source_Name) as Distinct_Samples'],
            "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID  AND $condition",
                -title=>'Blood Collection Summary',
                -return_html=>1);

    my $summary2 = $dbc->Table_retrieve_display('Plate,Plate_Sample,Sample,Source,Original_Source,Sample_Type',['Plate.FK_Plate_Format__ID as Format','Plate.FK_Sample_Type__ID as Sample_Type',"SUM(CASE WHEN Plate_Status='Active' THEN 1 ELSE 0 END) as Active_Tubes","SUM(CASE WHEN Plate_Status='Exported' THEN 1 ELSE 0 END) as Exported_Tubes",'count(distinct Original_Source_Name) as Subjects'],
            "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID AND Plate.FK_Sample_Type__ID=Sample_Type_ID AND $condition GROUP BY Plate.FK_Plate_Format__ID,Plate.FK_Sample_Type__ID",
                -title=>'Samples Available',
                -return_html=>1,
                -order => 'Sample_Type, Plate.FK_Plate_Format__ID',
                -total_columns=>['Active_Tubes', 'Exported_Tubes'],
                -toggle_on_column => 2,
                -layer=>$layer);

        my $output = $summary
         . '<hr>'
         . $summary2;
         $output .= '<p ></p>'
         . Link_To($dbc->homelink(),' Samples by Subject ID',"&cgi_application=alDente::View_App&rm=Display&File=/opt/alDente/www/dynamic/cache//Group/2/general/subject_search.yml&Generate+Results=1&Source+Call=alDente::View_App");
        $output .= '<p ></p>'
         . Link_To($dbc->homelink(),' Samples by Content',"&cgi_application=alDente::View_App&rm=Display&File=/opt/alDente/www/dynamic/cache//Group/2/general/content_search.yml&Generate+Results=1&Source+Call=alDente::View_App");

        return $output;
}

return 1;
