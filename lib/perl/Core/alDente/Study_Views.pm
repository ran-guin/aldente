###################################################################################################################################
# alDente::Study_Views.pm
#
# Interface generating methods for the Study MVC ( associate with Study.pm, Study_App.pm )
#
###################################################################################################################################
package alDente::Study_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use CGI qw( :standard );

## Local modules ##
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;

## globals ##
use vars qw( %Configs );
my $q = new CGI;
######################
# Constructor
##############
sub new {
##############
    my $this  = shift;
    my %args  = filter_input( \@_ );
    my $model = $args{-model};
    my $dbc   = $args{-dbc};

    my $self = {};
    $self->{'dbc'} = $dbc;
    my ($class) = ref $this || $this;
    bless $self, $class;

    return $self;
}
################
#
# Standard view for single Study record
#
###################
sub home_page {
###################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{'dbc'}

}
######################################
# Standard view for single Study record
#
# Return: html page
######################################
sub search_page {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};

    my $simple_search = $self->display_simple_search( -dbc => $dbc );
    my $new = alDente::Form::init_HTML_table( 'New Study', -margin => 'on' );
    $new->Set_Row( [ '', $self->display_new_study_button() ] );

    my $search = alDente::Form::init_HTML_table( 'Search Study', -margin => 'on' );
    $search->Set_Row( [ LampLite::Login_Views->icons('Search'), $simple_search ] );

    my $page = $new->Printout(0) . '<hr>' . $search->Printout(0);

    return $page;
}

################################
# Display the new study button
#
# Return: html page
#####################################
sub display_new_study_button {
#####################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};

    my $page
        = alDente::Form::start_alDente_form( $dbc, 'Study Home' )
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Define New Study', -force => 1, -class => "Std" )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Study_App', -force => 1 )
        . $q->end_form();

    return $page;
}

########################
# Display the search page
#
# Return html page
##############################
sub display_simple_search {
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};

    my $output;
    $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Study_Search" );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Study_App' );

    ### search options table

    # init study name search
    my $study_name_spec = "<B> Study Name: </B>" 
        . lbr()
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -name    => 'Study.Study_Name',
        -default => '',
        -search  => 1,
        -filter  => 1,
        -breaks  => 1,
        -width   => 390,
        -mode    => 'Scroll',
        -force   => 1,
        );

    # init study id search
    my $study_id_spec = '<B>Study IDs:</B><BR>' . textfield( -name => 'Study IDs', -size => 20, -force => 1 );

    my $study_search = HTML_Table->init_table( -title => "Study Search", -width => 600, -toggle => 'on' );
    $study_search->Set_Border(1);
    $study_search->Set_Row( [$study_name_spec] );
    $study_search->Set_Row( [$study_id_spec] );
    $study_search->Set_Row( [ RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => "Study_Search", name => "rm", value => "View Studies" ) ] );
    $study_search->Set_VAlignment('top');
    $output .= $study_search->Printout(0);
    $output .= "<BR>";

    $output .= end_form();
    return $output;
}

sub view_studies {
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $dbc         = $self->{dbc};
    my $debug       = $args{-debug};
    my @study_names = @{ $args{-study_names} };
    my @study_ids   = @{ $args{-study_ids} };

    my $condition = "WHERE 1";

    if (@study_names) {
        my $study_names = Cast_List( -list => \@study_names, -to => 'string', -autoquote => 1 );
        $condition .= " AND Study_Name in ($study_names) " if ($study_names);
    }

    if (@study_ids) {
        my $study_ids = Cast_List( -list => \@study_ids, -to => 'string', -autoquote => 1 );
        $condition .= " AND Study_ID in ($study_ids) " if ($study_ids);
    }

    my @field_list = ( "Study_ID", "Study_Name", "Study_Description", "Study_Initiated", );

    my $tables = "Study";
    print "Condition: $condition\n\n" if ($debug);
    return $dbc->Table_retrieve_display(
        -title       => 'Study',
        -return_html => 1,
        -table       => $tables,
        -fields      => \@field_list,
        -condition   => $condition,
        -debug       => $debug,
    );

}

return 1;
