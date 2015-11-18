#!/usr/bin/perl -w
###################################################################################################################################
# Reciving::Summary_App.pm
#
#
#
# By Ash Shafiei, July 2008
###################################################################################################################################
package Receiving::Summary_App;

use base RGTools::Base_App;
use strict;

use Data::Dumper;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules

use alDente::Form;

use vars qw( $Connection $user_id $homelink %Configs );
use vars qw(%Form_Searches);

###########################
###########################
sub setup {
###########################
    my $self = shift;

    $self->start_mode('default page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'default page'    => 'stat_page',
        'Search Now'      => 'display_stats',
        'Advanced Search' => 'advanced_search'
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    return 0;
}
###########################
sub stat_page {
###########################
    #	Decription:
    # 		- This is the default run mode for Receiving::Summary_App
    #			It displays the received items for the last two days
    #			and it allows user to search for items from the past
    #	Input:
    #		- Note:  Input will be prompted from the user with buttons and ...
    #	output:
    #		- A form to be displayed on webpage
    # <snip>
    # Usage Example:
    #     This is a runmode and it gets called from setup.
    # </snip>
###########################
    my $self = shift;
    my $form;
    my $q   = $self->query;
    my $dbc = $Connection;

    $form .= start_custom_form( -name => 'Stat Search Page', -parameters => { &_alDente_URL_Parameters() } );
    $form .= Views::sub_Heading( "Receiving Summary", -1 );
    $form .= $q->hidden( -name => 'cgi_application', -value => 'Receiving::Summary_App', -force => 1 );
    $form .= $self->return_form( -dbc => $dbc, -daymode => 'recent' ) . vspace();
    $form .= display_date_field(
        -field_name => "date_range",
        -quick_link => [ '7 days', '2 weeks', '1 month', '3 months', '6 months', 'Year to date' ],
        -range      => 1,
        -linefeed   => 1
    ) . vspace();
    $form .= $q->checkbox_group( -name => 'Stat Users', -values => ['All Users'] ) . hspace(10);
    $form .= $q->submit( -name => 'rm', -value => 'Search Now', -class => "Search", -force => 1 ) . vspace();

    #	$form .= " (Note: Limit you date when using ALL USERS)" .vspace () . hr();
    $form .= $q->radio_group( -name => 'search_type', -values => [ 'Solutions', 'Equipment' ] ) . hspace(5);
    $form .= $q->submit( -name => 'rm', -value => 'Advanced Search', -class => "Search", -force => 1 );

    $form .= $q->end_form();

    return $form;
}
###########################
sub display_stats {
###########################
    #	Decription:
    # 		- This page displays the resulting stats from the search
    #	Input:
    #		- using "param()" method we get the date range and
    #			the choice of users (current user or all users)
    #	output:
    #		- In form format to be displayed on webpage
    # <snip>
    # Usage Example:
    #     This is a runmode and it gets called from setup.
    # </snip>
###########################

    my $self = shift;
    my $form;
    my $q            = $self->query;
    my $dbc          = $Connection;
    my $current_user = $q->param('Stat Users');
    my $begin_date   = $q->param('from_date_range');
    my $end_date     = $q->param('to_date_range');

    unless ($current_user) { $current_user = $q->param('User') }    ###  if 'All Users' has not been selected current user will be selected

    $form .= start_custom_form( -name => 'stat results', -parameters => { &_alDente_URL_Parameters() } );
    $form .= Views::sub_Heading( "Receiving Summary", -1 );
    $form .= $self->return_form( -dbc => $dbc, -daymode => 'search', -from => $begin_date, -to => $end_date, -user => $current_user ) . vspace();
    $form .= $q->end_form();

    return $form;
}
###########################
sub advanced_search {
###########################
    #	Decription:
    # 		- This page connects user to advanced search which already exists under diffrent file name
    # <snip>
    # Usage Example:
    #     This is a runmode and it gets called from setup.
    # </snip>
###########################

    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $Connection;
    my $table;

    if    ( $q->param('search_type') =~ /Solutions/ ) { $table = 'Stock' }
    elsif ( $q->param('search_type') =~ /Equipment/ ) { $table = 'Equipment' }

    my %args;
    $args{-dbc}    = $dbc;
    $args{-tables} = $table;
    if ( exists $Form_Searches{$table} ) {
        foreach my $setting ( keys %{ $Form_Searches{$table} } ) {
            my $value = $Form_Searches{$table}->{$setting};
            $args{"-$setting"} = $value;
        }
    }
    &SDB::DB_Form_Viewer::Table_search(%args);

    return;
}
###########################
sub return_form {
###########################
    #	Decription:
    # 		- This function looks up a table in database and returns it in html form
    #	Input:
    #		- date range (from, to) , the mode of search, dbc,
    #	output:
    #		- html table to be attached in a form
    # <snip>
    # Usage Example:
    #  	$form .= $self-> return_form (-dbc => $dbc, -daymode => 'search', -from => $begin_date, -to => $end_date) ;
    # </snip>
###########################

    my $self       = shift;
    my %args       = @_;
    my $dbc        = $args{-dbc};
    my $searchmode = $args{-daymode};
    my $begin_date = $args{-from};
    my $end_date   = $args{-to};
    my $users      = $args{-user};
    my ($today)     = split ' ', &date_time();
    my ($yesterday) = split ' ', &date_time('-1d');
    my $cond;
    my @layers    = qw (Equipment Reagent Solution Kit Box Microarray Computer_Equip Misc_Item Service_Contract Computer_Equip);
    my @fields    = qw (Stock_ID Stock_Catalog_Name Stock_Number_in_Batch Stock_Received FK_Employee__ID  Stock_Catalog.Stock_Type);
    my @keys      = qw (Stock_ID Stock_Catalog_Name Stock_Number_in_Batch Stock_Received FK_Employee__ID);
    my $tableName = 'Stock, Stock_Catalog';
    my $condition = 0;
    my $distinct  = 0;

    my @current_user = $dbc->Table_find( "Employee", "Employee_ID", "WHERE Employee_Name = '$users'" );

    if ( $searchmode eq 'recent' ) {
        $cond = "WHERE (Stock_Received = '$today' or Stock_Received = '$yesterday')";
    }
    elsif ( $searchmode eq 'search' ) {
        $cond = "WHERE Stock_Received <= '$end_date' and Stock_Received >= '$begin_date'";
        unless ( $users eq 'All Users' ) {
            $cond .= "and FK_Employee__ID LIKE '%$current_user[0]%'";
        }
    }
    else {
        Message("Unknown Search Mode");
        return;
    }
    $cond .= " AND FK_Stock_Catalog__ID = Stock_Catalog_ID ";

    my %values = Table_retrieve( $dbc, $tableName, \@fields, $cond, -distinct => $distinct );

    my $table = $dbc->SDB::HTML::display_hash(
        -dbc             => $dbc,
        -keys            => \@keys,
        -hash            => \%values,
        -layer           => 'Stock_Type',
        -average_columns => 'Count',
        -total_columns   => 'Count',
        -return_html     => 1
    );

    return $table;
}

1;
