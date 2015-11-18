###################################################################################################################################
#
###################################################################################################################################
package alDente::Priority_Object_Views;

use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::RGmath;

use SDB::HTML;
use SDB::DBIO;
use SDB::CustomSettings;

use alDente::Validation;
use alDente::SDB_Defaults;
use alDente::Tools;

use alDente::Priority_Object;

use LampLite::Bootstrap;
use CGI qw(:standard);
use strict;

use vars qw(%Configs $Security);
my %PRIORITY_COLORS = ( '5 Highest' => 'red', '4 High' => 'orange', '3 Medium' => 'lightgreen', '2 Low' => 'lightyellow', '1 Lowest' => 'lightgrey', '0 Off' => 'white' );

my $q  = new CGI;
my $BS = new Bootstrap;

sub set_priority_view {
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $object = $args{-object};
    if ( !$object ) {return}

    my $prompt;
    if ( grep( /Admin/i, @{ $dbc->get_local('Access')->{$Current_Department} } ) ) {    # visible to admin only
        my $app;

        #if ( $object =~ /^Plate$/i ) {
        #    $app = 'alDente::Container_App';
        #}
        #else {
        #    $app = 'alDente::' . $object . '_App';
        #}
        $app = 'alDente::Priority_Object_App';
        my $priority_obj = new alDente::Priority_Object( -dbc => $dbc );
        my @valid_priorities = $priority_obj->get_valid_priorities();
        $prompt .= "<P><hr>";
        $prompt .= Show_Tool_Tip( popup_menu( -name => 'Priority', -value => \@valid_priorities, -default => "Medium", -force => 1 ), 'Select priority level' );
        $prompt .= hspace(10);

        $prompt .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Set Priority', -class => 'Action', -onClick => "sub_cgi_app( '$app' )", -force => 1 ), "Set priority for $object" );

        #$prompt .= Show_Tool_Tip( submit( -name => 'Set Priority', -value => 'Set Priority', -class => 'Action', -force => 1 ), "Set priority for $object" );
        $prompt .= hspace(10);
        my $element_id = int( rand(1000) ) . "_" . int( rand(1000) );
        $prompt .= Show_Tool_Tip( textfield( -name => "Priority_Date_$element_id", -size => 20, -id => "Priority_Date_$element_id", -onclick => $BS->calendar( -id => "Priority_Date_$element_id", -format => 'Y-m-d', -show_time => 'false' ) ),
            'Set priority date' );
        $prompt .= "<P>";
        $prompt .= hidden( -name => 'Object', -value => $object, -force => 1 );

        $prompt .= hidden( -id => 'sub_cgi_application', -force => 1 );
        $prompt .= hidden( -name => 'RUN_CGI_APP', -value => 'AFTER', -force => 1 );
    }

    return $prompt;
}

#######################
#sub catch_set_priority {
#######################
#    my %args          = filter_input( \@_, -args => "dbc" );
#    my $dbc           = $args{-dbc};
#    my $object        = $q->param('Object');
#    my $priority      = $q->param('Priority');
#    my $priority_date = $q->param('Priority_Date');
#    my @libs          = $q->param('Collection') || $q->param('Mark');
#
#    if ( param('Set Priority') ) {
#        if ( @libs && ( $priority || $priority_date ) ) {
#            my $priority_obj = new alDente::Priority_Object( -dbc => $dbc );
#            foreach my $lib (@libs) {
#                my $ok = $priority_obj->update_priority( -priority => $priority, -priority_date => $priority_date, -object_class => $object, -object_id => $lib, -override => 1, -quiet => 1 );
#                if ( !$ok ) {
#                    $ok = $priority_obj->set_priority( -priority => $priority, -priority_date => $priority_date, -object_class => $object, -object_id => $lib );
#                }
#                if ( !$ok ) {
#                    $dbc->error("Set Priority failed for $object $lib!");
#                }
#            }
#        }
#    }
#    return;
#}

####################################
# This method displays the coloured priority value
#
# Usage:
#		my $label = priority_label( -dbc => $dbc, -object => 'Plate', -id => $plate_id );
#
# Return:
#		Scalar - HTML string
####################################
sub priority_label {
####################################
    my %args   = filter_input( \@_, -args => 'dbc,object,id' );
    my $dbc    = $args{-dbc};
    my $object = $args{-object};                                  # the object class
    my $id     = $args{-id};                                      # object ID

    my ($priority_info) = $dbc->Table_find( 'Priority_Object,Object_Class', 'Priority_Value,Priority_Description', "WHERE FK_Object_Class__ID = Object_Class_ID and Object_Class = '$object' and Object_ID = '$id' " );
    if ($priority_info) {
        my ( $priority, $note ) = split ',', $priority_info;
        my $table = HTML_Table->new();
        if ($note) {
            $note = "( $note )";
            $table->Set_Row( [ 'Priority: ', $priority, $note ] );
        }
        else {
            $table->Set_Row( [ 'Priority: ', $priority ] );
        }
        $table->Set_Cell_Colour( 1, 2, $PRIORITY_COLORS{$priority} );
        my $label = $table->Printout(0);
        return $label;
    }
    else {
        return;
    }

}

1;

