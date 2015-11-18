###################################################################################################################################
# alDente::Invoice_Run_Type.pm
#
#
###################################################################################################################################
package alDente::Invoice_Run_Type;

use base SDB::DB_Object;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
## alDente modules

use vars qw( %Configs );

#####################
sub new {
    #####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Invoice_Run_Type' );
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        $self->{id} = $id;
        $self->primary_value( -table => 'Invoice_Run_Type', -value => $id );
        $self->load_Object();
    }

    return $self;
}

1;

