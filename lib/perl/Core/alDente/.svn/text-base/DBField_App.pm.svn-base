###################################################################################################################################

=pod
alDente::DBField_App.pm
 	
Written by: Patrick Plettner October 2010
=cut

###################################################################################################################################
package alDente::DBField_App;

use base RGTools::Base_App;
use strict;

## SDB modules
use SDB::CustomSettings;

#use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;

## alDente modules
use alDente::Tools;
use alDente::Web;
use alDente::SDB_Defaults;
use alDente::Patch;

use vars qw($Current_Department $Connection %Configs $Security);

###########################
sub setup {
###########################
    my $self = shift;

    $self->start_mode('Main Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Main Page' => 'main_page',
        'Add Field' => 'add_field',
        'Add Entry' => 'add_entry'
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');
    my $q   = $self->query;

    return 0;
}

###############################
sub main_page {
###############################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $id = $q->param('ID');

    if ($id) {
        return alDente::Info::GoHome( $dbc, -table => 'DBField', -id => $id, -force => 1 );
    }

    my $page = &Views::Heading("DBField Main Page");
    $page .= $self->display_new_dbfield_block();
    $page .= $self->display_search_block();

    return $page;
}

###########################
sub add_field {
###########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my @patches = alDente::Patch::get_available_patches( -dbc => $dbc );

    ## creating the table
    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'DBField', -target => 'Database', -wrap => 0 );
    $table->configure();

    my $page .= alDente::Form::start_alDente_form( $dbc, 'DBField Form' );

    $page .= $q->radio_group( -name => 'Patch', -values => [ 'Patched', 'Unpatched' ], -default => 'Patched', -force => 1 ) . $q->br();

    $page .= "Existing patches:" . hspace(20) . $q->popup_menu( -name => 'Patch_List', -values => [ '', @patches ], -force => 1 ) . $q->br();

    $page .= "New patch name:" . hspace(20) . $q->textfield( -name => 'Patch_File', -size => 20, -default => '' ) . $q->br();
    $page .= $table->generate( -button => { 'rm' => 'Add Entry' }, -navigator_on => 0, -return_html => 1 );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::DBField_App', -force => 1 );
    $page .= $q->end_form();

    return $page;
}

###########################
sub add_entry {
###########################
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $q        = $self->query;
    my $dbc      = $args{-dbc} || $self->param('dbc');
    my $type     = $args{-type};
    my $category = $args{-category};

    my $patch          = $q->param('Patch');
    my $selected_patch = $q->param('Patch_List');
    my $new_patch      = $q->param('Patch_File');

    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => 'DBField', -object => $self, -dbc => $dbc );

    if ($patch) {
        my %entry;
        @entry{@$fields} = @$values;

        my ( $patch_file, $action );

        if ($selected_patch) {
            $patch_file = "$selected_patch.pat";
            $action     = 'append';
        }
        else {
            $patch_file = "$new_patch.pat";
            $action     = 'create';
        }

        my $ok = alDente::Patch::patch_DB( -file => $patch_file, -table => 'DBField', -entry => \%entry, -action => $action, -dbc => $dbc );
        Message("Record successfully patched in $patch_file") if $ok;
    }

    else {
        my @null_ok = $dbc->Table_find( -table => 'DBField', -fields => "Null_ok", -condition => "WHERE Field_Table = 'DBField'" );

        for ( my $i = 0; $i < $#null_ok; $i++ ) {
            if ( !defined $values->[$i] and $null_ok[$i] eq 'NO' ) {
                $values->[$i] = '';
            }
        }

        my $ok;
        ##  starting the transaction (to avoid writing information partially)
        $dbc->start_trans( -name => 'Saving_Info' );
        $ok = $dbc->Table_append_array( 'DBField', $fields, $values, -autoquote => 1 );

        ## All tables have been filled now, time to make sure there was no errors
        if ($ok) {
            $dbc->finish_trans('Saving_Info');
            Message('Records successfully added');
        }
        else {
            $dbc->rollback_trans( 'Saving_Info', -error => "problem adding info" );
            return 0;
        }
    }

    return $self->add_field();
}

###########################
sub search {
###########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    ## creating the table
    my $table = SDB::DB_Form->new( -dbc => $dbc, -fields => [ 'DBField.FK_DBTable__ID', 'DBField.Field_Name' ], -target => 'Database', -action => 'search', -wrap => 0 );
    $table->configure();

    my $page .= alDente::Form::start_alDente_form( $dbc, 'DBField Form' );
    $page .= $table->generate( -navigator_on => 0, -return_html => 1 );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::DBField_App', -force => 1 );
    $page .= $q->submit( -name => 'rm', -value => "Results", -class => "Std", -force => 1 );
    $page .= $q->end_form();

    return $page;
}

###########################
sub display_new_dbfield_block {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $args{-dbc} || $self->param('dbc');

    my $new_block = alDente::Form::start_alDente_form( $dbc, 'New DBField Form' );
    $new_block .= $q->hidden( -name => 'cgi_application', -value => 'alDente::DBField_App', -force => 1 );
    $new_block .= $q->submit( -name => 'rm', -value => "Add Field", -class => "Std", -force => 1 );
    $new_block .= $q->end_form();

    my $table = alDente::Form::init_HTML_table( "Add DBField entry", -margin => 'on' );
    $table->Set_Row( [ '', $new_block ] );
    my $add_block = $table->Printout(0);

    return $add_block;
}

###########################
sub display_search_block {
###########################
    my $self          = shift;
    my %args          = @_;
    my $q             = $self->query;
    my $dbc           = $args{-dbc} || $self->param('dbc');
    my $search_header = LampLite::Login_Views->icons( 'Search', -dbc => $dbc );

    my $search = alDente::Form::start_alDente_form( $dbc, 'DBField Search' );

    $search .= $q->hidden( -name => 'cgi_application', -value => 'SDB::DB_Object_App', -force => 1 );
    $search .= $q->submit( -name => 'rm', -value => "Search Records", -class => "Search", -force => 1 );
    $search .= $q->hidden( -name => 'Table', -value => 'DBField', -force => 1 );
    $search .= $q->end_form();

    my $table = alDente::Form::init_HTML_table( "Search/Edit Records", -margin => 'on' );
    $table->Set_Row( [ $search_header, $search ] );

    return $table->Printout(0);
}

1;
