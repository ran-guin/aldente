###################################################################################################################################
# alDente::Document_App.pm
#
#
###################################################################################################################################
package alDente::Document_App;

use base RGTools::Base_App;

use Benchmark;
use strict;

## SDB modules
use SDB::CustomSettings;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;

## alDente modules
#use alDente::Form;
use alDente::Document;
use alDente::Document_Views;

use alDente::Tools;
use alDente::Work_Request_Views;

#use alDente::SDB_Defaults;

use vars qw( %Configs  $Security);

###########################
sub setup {
###########################

    my $self = shift;

    $self->start_mode('Home');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home'         => 'home_page',
        'View Modules' => 'home_page',
    );

    $ENV{CGI_APP_RETURN_ONLY} = 0;
    my $dbc = $self->param('dbc');

    $self->{dbc} = $dbc;
    return 0;

}

#
# Show Links to all available Modules
#
#
# Return: web page block
################
sub home_page {
################
    my $self   = shift;
    my $q      = $self->query();
    my $module = $q->param('API') || $q->param('Module');
    my $dbc    = $self->{dbc};

    my @modules;

    if ($module) { @modules = Cast_List( -list => $module, -to => 'array' ) }
    else {
        @modules = sort qw(Sequencing::Sequencing_API Illumina::Solexa_API alDente::alDente_API Lib_Construction::Microarray_API Mapping::Mapping_API);    ## list of applicable modules

        if ( $self->{dbc}->admin_access() ) { push @modules, ( 'SDB::DBIO', 'SDB::HTML', 'SDB::DB_Form', 'Submission::Template', 'alDente::ReArray', 'alDente::Subscription' ); }
    }

    my $page = alDente::Document_Views::view_Code( -dbc => $dbc, -modules => [@modules] );

    $dbc->Benchmark('loaded_modules');
    return $page;
}

1;
