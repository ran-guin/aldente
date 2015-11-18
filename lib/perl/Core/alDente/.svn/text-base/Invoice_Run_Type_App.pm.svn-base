##############################################################################################################
#alDente::Invoice_Run_Type_App.pm
#
#
#
#
##############################################################################################################
package alDente::Invoice_Run_Type_App;
use base RGTools::Base_App;
use strict;

##############################
#     custom_modules_ref     #
##############################

### Reference to alDente modules

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Object;

use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

use alDente::SDB_Defaults;
use alDente::Invoice_Run_Type;

use vars qw(%Configs);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'home_page'                    => 'home_page',
        'Add New Invoiceable Run Type' => 'new_run_type',
    );

    my $dbc = $self->param('dbc');
    return $self;
}

############################
sub new_run_type {
############################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $grey   = $q->param('Grey');
    my $preset = $q->param('Preset');

    my %grey;
    my %preset;
    my %hidden;
    my %list;

    my $navigator = 1;
    my $repeat;
    my $append_html = '';    #add html for hidden parameters
    my %button      = ();

    if ($grey)   { %grey   = %$grey }
    if ($preset) { %preset = %$preset }

    my @invoice_run_types = $dbc->Table_find( 'Invoice_Run_Type', 'Invoice_Run_Type_Name' );
    my ($run_types) = $dbc->Table_find( 'DBField', 'Field_Type', "WHERE DBField_ID = 2836" );

    $run_types =~ s/enum\(\'//;
    $run_types =~ s/\'\)//;

    my @run_types = split "','", $run_types;

    my %diff;
    foreach my $type ( @run_types, @invoice_run_types ) {
        $diff{$type}++;
    }

    my @available_run_types;
    foreach my $key ( keys %diff ) {
        if ( $diff{$key} == 1 ) {
            push @available_run_types, $key;
        }
    }

    $list{Invoice_Run_Type_Name} = \@available_run_types;
    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Invoice_Run_Type', -target => 'Database', -append_html => $append_html );
    $table->configure( -grey => \%grey, -preset => \%preset, -omit => \%hidden, -list => \%list );

    return $table->generate( -navigator_on => $navigator, -return_html => 1, -repeat => $repeat, -button => \%button );

}

return 1;
