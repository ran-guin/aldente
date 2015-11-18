###################################################################################################################################
# Template::Run_Summary_Views.pm
#
#
#
###################################################################################################################################
package Template::Run_Summary_Views;
@ISA = qw(SDB::DB_Object);


use strict;
use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use alDente::Form;
use Template::Run_Summary;

use vars qw( $user_id $homelink %Configs );


#####################################
sub new {
#####################################
#
#####################################
    my $this  = shift;
    my $class = ref($this) || $this;
    my %args  = @_;

    my $lanes_ref     = $args{-lanes        };
    my $equipment_id  = $args{-equipment    };
    my $dbc           = $args{-dbc          };

    # arguments are valid.  Create the object
    my $self = SDB::DB_Object->new( -dbc    => $dbc	   );

    $self->{dbc          } = $dbc;
    $self->{lanes        } = $lanes_ref;
    $self->{equipment_id } = $equipment_id;

    if ( defined $args{-id} ) {
        $self->{run_id} = $args{-id};
        my ($id)        = $dbc->Table_find( 'Template_Run', 'Template_Run_ID', "WHERE FK_Run__ID = $self->{run_id}");
        $self->{id}     = $id;

        $self->primary_value( -table => 'SOLIDRun', -value => $id );
        $self->load_Object( -quick_load => 1, -id => $id );
    }
    else {
        # validate lanes
        _Lanes_are_valid( -dbc => $dbc,
			 -lanes      => $lanes_ref
			 ) || return err( "Invalid lanes", 0 );

        # validate equipment
        _Equipment_type_is_valid( -dbc          => $dbc,
				 -equipment_id => $equipment_id
				 ) || return err( "Invalid equipment", 0 );
    }

    bless $self, $class;

    return $self;

}
