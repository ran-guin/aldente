##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package Lib_Construction::Department_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base alDente::CGI_App;

use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::HTML;    ##  qw(hspace vspace get_Table_param HTML_Dump display_date_field set_validator);
use SDB::DBIO;
use SDB::CustomSettings;

use Lib_Construction::Department_Views;
use Lib_Construction::Department;

##############################
# global_vars                #
##############################
use vars qw(%Configs  $URL_temp_dir $html_header $debug);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

my $q;
my $dbc;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home'    => 'home',
        'Summary' => 'summary',
        'RNA_DNA' => 'rna_dna_options',
        'Database'  => 'display_Database',
    );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

###############
sub summary {
###############
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    return Lib_Construction::Department_Views::summary_page( -dbc => $dbc );
}

# Also, displays some basic statistics relevant to each of the run modes
##################
sub home {
##################

    my $self = shift;

    return 'newhome';

    #    return Lib_Construction::Department_Views::home_page(-dbc=>$dbc);
}

##################
sub display_Database {
##################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    my ( $search_ref, $creates_ref, $conversion_ref, $custom ) = Lib_Construction::Department::get_searches_and_creates( -access => \%Access );
    my @searches    = @$search_ref;
    my @creates     = @$creates_ref;
    my @conversions = @$conversion_ref;

    my $search_create_box = alDente::Department::search_create_box($dbc, -search => \@searches, -create => \@creates, -convert => \@conversions, -custom_search => $custom );
}

######################
sub rna_dna_options {
######################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    return Lib_Construction::Department_Views::RNA_DNA_Collection_Options($dbc);
}

return 1;

