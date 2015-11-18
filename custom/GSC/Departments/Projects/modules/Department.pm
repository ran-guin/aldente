package Projects::Department;
use base alDente::Department;

use strict;
use warnings;

#use CGI qw(:standard);
#use Data::Dumper;

#use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use Data::Dumper;

#use SDB::DBIO;
use alDente::Validation;
use alDente::View_App;

#use vars qw($Connection);

## Specify the icons that you want to appear in the top bar
my @icons_list = qw(All_Projects Funding Stat_App Submission_Volume_App Study_App Views Contacts Import Template Subscription);

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    ###Permissions###
    my %Access = %{ $dbc->get_local('Access') };

    #This user does not have any permissions on Gene Expression
    if ( !( $Access{'Projects'} || $Access{'LIMS Admin'} ) ) {
        return;
    }

    #alDente::Department::set_links($dbc);

    ## only show active funding sources  ##
    my $funding = Link_To( $dbc->config('homelink'), 'Define new Funding', '&New+Entry=New+Funding' )
        . $dbc->Table_retrieve_display(
        'Work_Request,Funding', [ 'FK_Funding__ID AS Funding',
            'FKSource_Organization__ID AS Organization', 'Funding_Description',
            'Funding_Source', 'ApplicationDate AS Application_Date', 'count(*) as Work_Requests' ],
        "WHERE Work_Request.FK_Funding__ID=Funding_ID AND Funding_Status = 'Received' Group By FK_Funding__ID ORDER BY Funding_Source,Funding_Code",
        -toggle_on_column => 'Funding_Source',
        -return_html      => 1,
        -title            => 'Active Funding Sources (click on Funding for details)'
        );

    my $reports = report_prompt($dbc);

    my @order = ( 'Reports', 'Funding Sources' );
    my $output = define_Layers(
        -layers    => { 'Reports' => $reports, 'Funding Sources' => $funding },
        -tab_width => 100,
        -order     => \@order,
        -default   => 'Funding Sources'
    );

    return $output;
}

########################################
# Accessor function for the icons list
####################
sub get_icons {
####################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my %Access = %{ $dbc->get_local('Access') };
    if ( grep( /Admin/, @{ $Access{Projects} } ) ) {
        push @icons_list, "Employee";
    }

    return \@icons_list;
}
########################################
#
#
####################
sub get_custom_icons {
####################
    my %images;

    return \%images;

}

#
# Return: Layer prompting users to generate reports directly
#####################
sub report_prompt {
#####################
    my $dbc = shift;

    my $q    = new CGI;
    my $page = '<h2>Generate Reports </h2>';

    #
    # The section below is temporary and should be adapted to provide quick links to primarily used reports ##
    #
    my $Views = {
        'Invoiced_Work'               => 'Work Invoice Report',
        'Capillary_Invoice_Prototype' => 'Capillary Invoice Report'
    };

    my @views = ( 'Invoiced_Work', 'Capillary_Invoice_Prototype' );

    my ( $view_root, $view_sub_path ) = alDente::Tools::get_standard_Path( -type => 'view', -group => 43, -structure => 'DATABASE' );
    my $report = 0;

    foreach my $view (@views) {

        my $view_filepath = $view_root . $view_sub_path . 'general/' . $view . '.yml';

        if ( -e $view_filepath ) {
            $report++;
            my $description = $Views->{$view};

            my $field = 'FK_Funding__ID';

            $page .= alDente::Form::start_alDente_form( -name => "report$report", -dbc => $dbc );
            $page
                .= $q->hidden( -name => 'cgi_application',  -value => 'alDente::View_App', -force => 1 )
                . $q->hidden( -name  => 'rm',               -value => 'Display',           -force => 1 )
                . $q->hidden( -name  => 'Generate Results', -value => 1,                   -force => 1 )
                . alDente::Tools::search_list( -dbc => $dbc, -field => $field, -search => 1, -filter => 1, -prompt => '-- Select Funding --', -breaks => 1, -mode => 'scroll' )
                . $q->submit( -name => "Generate $description", -class => 'Action' )
                . $q->hidden( -name => 'File', -value => $view_filepath, -force => 1 )
                . $q->end_form();

            $page .= '<hr>';
        }
    }

    $page .= '<h2>Invoice Tools</h2>';
    $page .= Link_To( $dbc->config('homelink'), 'Create new Invoice', '&cgi_application=alDente::Invoice_App&rm=New Invoice' ) . '<br /><br />';
    $page .= Link_To( $dbc->config('homelink'), 'Search Invoice', '&cgi_application=SDB::DB_Object_App&rm=Search Records&Table=Invoice' ) . '<br />';
    $page .= '<hr />';

    my $View = new alDente::View( -dbc => $dbc );
    $page .= '<h2>Views</h2>';

    $page .= alDente::View_Views->display_available_views(
        -views => [ 'Public', 'Group', 'Employee' ],    ## go to other layers to see Other views if necessary ... , 'Other' ],
        -object => $View,
        -source => 'alDente::View_App',
        -open   => ['']
    );

    return $page;
}

return 1;
