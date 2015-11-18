package SDB::Questionnaire;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_Questionnaire.pm - This object is the superclass of alDente database objects.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This object is the superclass of alDente database objects.<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;

use CGI qw(:standard);

##############################
# custom_modules_ref         #
##############################
use RGTools::Object;
use RGTools::HTML_Table;
use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::Template;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

my $q = new CGI;
##############################
# constructor                #
##############################

##################
sub new {
##################
    my $this = shift;

    my %args   = @_;
    my $dbc    = $args{-dbc};
    my $frozen = $args{-frozen} || 0;    # Reference to frozen object if there is any. [Object]

    my $self = $this->Object::new( -frozen => $frozen );
    my $class = ref($this) || $this;
    bless $self, $class;
    $self->{dbc} = $dbc;                 # Database handle [ObjectRef]

    my $external;

    return $self;
}

##############################
# public_methods             #
##############################
####################
sub load {
####################
    my $self = shift;
    my $dbc  = $self->{dbc};

    my %args       = &filter_input( \@_, -mandatory => 'file' );
    my $table      = $args{-table};
    my $file       = $args{-file};

    return;
}
##############################
# private_functions          #
##############################

return 1;
