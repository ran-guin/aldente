###############################
# WorkPackage.pm
###############################
#
# This module is the home page for the WorkPackage Tracker.  It allows the developers to
# view/enter/edit workpackages (e.g. bugs, enhancements) that are submitted.
#
#
###################################################################################
package alDente::WorkPackage;

@ISA = qw(SDB::DB_Object);

use strict;
use CGI qw(:standard);

use SDB::CustomSettings;

use SDB::DBIO;
use alDente::Validation;

use alDente::Issue;
use alDente::SDB_Defaults;

use RGTools::RGIO;

########
sub new {
########
    #
    # constructor
    #
    my $this = shift;
    my ($class) = ref($this) || $this;
    my %args = @_;

    my $Connection     = $args{-connection};
    my $dbc            = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $workpackage_id = $args{-id} || $args{-workpackage_id};    ## database handle

    my $self = $this->alDente::Issue::new( -dbc => $dbc, -tables => [ 'WorkPackage' . 'Issue' ] );
    bless $self, $class;

    $self->{dbc} = $dbc if $dbc;
    $self->{workpackage_id} = $workpackage_id;

    if ($workpackage_id) {

        #	$self->load_workpackage();     ## <CONSTRUCTION> - add...
    }

    return $self;
}

#############
sub home_page {
#############
    my $self           = shift;
    my %args           = @_;
    my $dbc            = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $workpackage_id = $args{-workpackage_id} || $self->{workpackage_id};

    my ($issue_id) = $dbc->Table_find( 'WorkPackage', 'FK_Issue__ID', "WHERE WorkPackage_ID = $workpackage_id" );

    return alDente::Issue::home_page( $self, -issue_id => $issue_id );
}

return 1;
