package Mapping::Statistics_View;

use strict;
use warnings;

use CGI qw(:standard);

use RGTools::RGIO;
use RGTools::HTML_Table;

use SDB::HTML;

#########################
#
#
#
#
#########################
sub new {
#########################
    my $this = shift;
    my %args = &filter_input( \@_ );

    my $self = {};
    $self->{dbc} = $args{-dbc};

    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}

#########################
#
#
#
#
#########################
sub display_query_form {
#########################

    my $self = shift;

    my $dbc = $self->{dbc};

    my %Parameters = alDente::Form::_alDente_URL_Parameters($dbc);
    my $form = start_custom_form( 'stats', -parameters => \%Parameters );

    $form .= &SDB::HTML::query_form( -dbc => $dbc, -fields => [ 'Library.FK_Project__ID', 'Plate.FK_Library__Name', 'Run.Run_DateTime' ], -title => 'Enter Search Criteria', -action => 'search', -filter_by_dept => 'Mapping' );
    $form .= hidden( -name => 'cgi_application', -value => 'Mapping::Statistics_App', -force => 1 );
    $form .= hidden( -name => 'rm', -value => 'generate_summary', -force => 1 );
    $form .= submit( -name => 'Generate', -class => 'Std' );
    $form .= checkbox( -name => 'Validation Date', -checked => 0, -force => 1 );
    $form .= end_form();
    return $form;

}

######################
#
#  Receive data strucutre of headers and row values. Displays them in HTML format
#
#
######################
sub append_table {
######################
    my $self = shift;
    my %args = &filter_input( \@_, -mandatory => 'summary,Table' );

    my $summary    = $args{-summary};
    my $keys       = $args{ -keys };
    my $Table      = $args{-Table};
    my $title      = $args{-title};
    my $count_mode = $args{-count_mode};    #1 for regular count, #2 for Run Analysis Pipeline count, #3 for single/double digest count

    $args{-hash} = $summary;

    delete $args{-summary};
    delete $args{-count_mode};

    if ($title) {
        $Table->Set_sub_header( $title, 'vlightblue' );
        delete $args{-title};
    }

    my @keys;
    @keys = $keys ? @{$keys} : sort keys %{$summary};
    my %processed;

    if ($count_mode) {
        foreach my $key (@keys) {
            if ( $count_mode == 1 ) {

                #regular count
                my $list = blind_down_count( $summary->{$key} );
                $Table->Set_Row( [ $key, $list ] );
            }
            elsif ( $count_mode == 2 ) {

                #Run Analysis Pipeline count
                my $count = int( @{ $summary->{$key} } );
                $Table->Set_Row( [ $key, $count ] );
            }
            elsif ( $count_mode == 3 ) {
                my $key_no_digest;
                my $key_single_digest;
                my $key_double_digest;
                if ( $key =~ /(.*?) - Double Digest/ ) {
                    $key_no_digest     = $1;
                    $key_double_digest = $key;
                    $key_single_digest = $key;
                    $key_single_digest =~ s/Double/Single/;
                }
                elsif ( $key =~ /(.*?) - Single Digest/ ) {
                    $key_no_digest     = $1;
                    $key_single_digest = $key;
                    $key_double_digest = $key;
                    $key_double_digest =~ s/Single/Double/;
                }

                #print "$key_no_digest; $key_single_digest; $key_double_digest<BR>";
                if ( !$processed{$key_no_digest} ) {
                    $processed{$key_no_digest} = 1;
                    my $single_list = blind_down_count( $summary->{$key_single_digest} );
                    my $double_list = blind_down_count( $summary->{$key_double_digest} );
                    $Table->Set_Row( [ $key_no_digest, $single_list, $double_list ] );
                }
            }
        }
        return 1;
    }
    else {
        foreach my $title (@keys) {
            my $j = -1;
            while ( $summary->{$title}[ ++$j ] ) {
                if ( $title eq 'Protocol Name' ) {next}
                $summary->{$title}[$j] = blind_down_count( $summary->{$title}[$j] );
            }
        }
        return &SDB::HTML::display_hash(%args);
    }

}

#######################
#
#
#
#######################
sub blind_down_count {
#######################
    my %args = &filter_input( \@_, -args => 'arr' );
    my @arr = Cast_List( -list => $args{-arr}, -to => 'array' );

    my $list = join '<br>', @arr;
    my $randid = rand();
    $randid = 'disp' . substr( $randid, -8 );
    my $count = int @arr;

    if ( $count == 0 ) {
        return '0';
    }

    #elsif ($count == 1) {
    #    return $arr[0];
    #}
    else {
        return "<div onClick='if (document.getElementById(\"$randid\").style.display==\"none\") {Effect.BlindDown(\"$randid\")} else {Effect.BlindUp(\"$randid\")}' style='cursor:pointer;'>$count</div><div id='$randid' style='display:none;'>$list</div>";
    }
}

return 1;
