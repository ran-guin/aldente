###################################################################################################################################
# alDente::QA_Views.pm
#
#
#
#
###################################################################################################################################
package alDente::QA_Views;

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
use vars qw(%Configs );

######################
sub get_qc_prompt {
######################
    my %args            = filter_input( \@_ );
    my $qc_status       = $args{-qc_status};
    my $dbc             = $args{-dbc};
    my $tables          = $args{-tables};
    my $condition       = $args{-condition};
    my $fields          = $args{-fields};
    my $default_qc_type = $args{-default_qc_type};
    my %qc_status;

    if ($qc_status) {
        %qc_status = %{$qc_status};
    }
    elsif ( $tables && $condition ) {
        my @plate_status = $dbc->Table_find( -table => $tables, -fields => $fields, -condition => $condition );
        foreach my $plate_status (@plate_status) {
            my ( $plate_id, $status ) = split ',', $plate_status;
            $qc_status{$plate_id} = $status;
        }
    }
    my @qc_types = $dbc->Table_find( 'QC_Type', 'QC_Type_Name', "WHERE 1" );
    my @failed;
    my @pending;
    my @ready;
    my @passed;
    foreach my $key ( keys %qc_status ) {
        if ( $qc_status{$key} eq 'Failed' ) {
            push @failed, $key;
        }
        if ( $qc_status{$key} eq 'Pending' ) {
            push @pending, $key;
        }
        if ( $qc_status{$key} =~ /(Re-Test|N\/A)/i ) {
            push @ready, $key;
        }
        if ( $qc_status{$key} eq 'Passed' ) {
            push @passed, $key;
        }
    }

    my $admin = ( grep /\bAdmin$/, @{ $dbc->get_local('groups') } );

    my $qc_prompt = '<B>QC: </B>';
    if (@failed) {
        ## don't show the qc_prompt
    }

    if (@pending) {
        my $count = int(@pending);
        my $plate_list = join ',', @pending;
        if ( !$default_qc_type ) {
            ($default_qc_type) = $dbc->Table_find( 'Plate_QC,QC_Type', 'QC_Type_Name', "WHERE FK_QC_Type__ID = QC_Type_ID and FK_Plate__ID in ($plate_list)", -distinct => 1 );    # if multiple qc types, default to the first one
        }
        $qc_prompt .= popup_menu( -name => 'QC_Type', -values => \@qc_types, -default => $default_qc_type, -force => 1 );
        if ($admin) {
            $qc_prompt
                .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Pass QC', -class => 'Action', -onClick => "sub_cgi_app( 'alDente::QA_App' )", -force => 1 ), "Mark $count pending items as Passed QC" )
                . hspace(10)
                . Show_Tool_Tip( submit( -name => 'rm', -value => 'Fail QC', -class => 'Action', -onClick => "sub_cgi_app( 'alDente::QA_App' )", -force => 1 ), "Mark $count pending items as Failed QC" )
                . Show_Tool_Tip( checkbox( -name => 'Throw_Out', -value => 'Throw_Out', -label => 'Throw Out', -checked => 1, -force => 1 ), "Throw out items when QC Failed" )
                . hspace(10);
            my $pending_ids = join( ',', @pending );
            $qc_prompt .= hidden( -name => 'Pending IDs', -value => $pending_ids, -force => 1 );
        }
        else {
            $qc_prompt .= " <B>QC Started for $count Plates</B>";
        }
    }

    if (@ready) {
        my $plate_list = join ',', @ready;
        my ($default_qc_type) = $dbc->Table_find( 'Plate_QC,QC_Type', 'QC_Type_Name', "WHERE FK_QC_Type__ID = QC_Type_ID and FK_Plate__ID in ($plate_list)", -distinct => 1 );    # if multiple qc types, default to the first one
        $qc_prompt .= popup_menu( -name => 'QC_Type', -values => \@qc_types, -default => $default_qc_type, -force => 1 );
        $qc_prompt .= '  '
            . Show_Tool_Tip(
            submit(
                -name    => 'rm',
                -value   => 'Start QC',
                -class   => "Action",
                -onClick => "sub_cgi_app( 'alDente::QA_App' )",
                -force   => 1
            ),
            "Requires samples to be approved prior to use.<BR>(flags all current plates/tubes)"
            );
        $qc_prompt .= '  ' . checkbox( -name => 'QC Gel', -value => 'QC Gel', -label => 'QC Gel', -checked => 0, -force => 1 );
        my $ready_ids = join( ',', @ready );
        $qc_prompt .= hidden( -name => 'Ready IDs', -value => $ready_ids, -force => 1 );
    }

    if (@passed) {
        my $count = int(@passed);
        my $plate_list = join ',', @passed;
        my ($default_qc_type) = $dbc->Table_find( 'Plate_QC,QC_Type', 'QC_Type_Name', "WHERE FK_QC_Type__ID = QC_Type_ID and FK_Plate__ID in ($plate_list)", -distinct => 1 );    # if multiple qc types, default to the first one
        $qc_prompt .= popup_menu( -name => 'QC_Type', -values => \@qc_types, -default => $default_qc_type, -force => 1 );
        if ($admin) {
            $qc_prompt .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Re-Test QC', -class => 'Action', -onClick => "sub_cgi_app( 'alDente::QA_App' )", -force => 1 ), "Mark $count Passed items to be Re-Tested" );
            my $passed_ids = join( ',', @passed );
            $qc_prompt .= hidden( -name => 'Passed IDs', -value => $passed_ids, -force => 1 );
        }
        else {
            $qc_prompt .= " <B>$count plates Passed</B>";
        }
    }

    if ( $tables && $condition ) {
        $qc_prompt .= hidden( -id => 'sub_cgi_application', -force => 1 );
        $qc_prompt .= hidden( -name => 'RUN_CGI_APP', -value => 'AFTER', -force => 1 );
    }

    return $qc_prompt;
}

# Display the qc status for each qc type given an object
####################
sub qc_status_view {
####################
    my %args  = filter_input( \@_ );
    my $table = $args{-table};         ## QC Object table
    my $dbc   = $args{-dbc};
    my $qc_status_view;
    my $id       = $args{-id};
    my $qc_multi = $table . "_QC";
    ## probably a faster way to check this if qc_multi exists
    my $qc_multi_exists = 0;
    ($qc_multi_exists) = $dbc->Table_find( 'DBTable', 'DBTable_Name', "WHERE DBTable_Name ='$qc_multi'" );

    if ($qc_multi_exists) {
        my ($fk_field) = $dbc->foreign_key( -table => $table );
        $qc_status_view = $dbc->Table_retrieve_display(
            "$qc_multi,QC_Type", [ "$fk_field as ID", 'QC_Type_Name as QC_Type', 'QC_Status', 'QC_DateTime as QC_Set' ], "WHERE $fk_field IN ($id) and QC_Type_ID = FK_QC_Type__ID",
            -order_by    => 'ID',
            -return_html => 1
        );
    }
    else {
        my ($primary_field) = SDB::DBIO::get_field_info( $dbc, $table, undef, 'Primary' );
        my ($qc_status) = $dbc->Table_find( $table, 'QC_Status', "WHERE $primary_field = $id" );
        $qc_status_view = "ID: $id" . lbr();
        $qc_status_view = "QC Status: $qc_status" . lbr();
    }
    return $qc_status_view;
}

##################################
sub QC_Control_Plate_button {
##################################
    my $q = new CGI;

    my $button = Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'QC Monitoring', -class => 'Std' ), "Show Quality averages for simultaneously handled plates" );

    return $button;
}
1;
