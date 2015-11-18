###################################################################################################################################
# Template::Run.pm
#
#
#
#
###################################################################################################################################
package Template::Run;

@ISA = qw(SDB::DB_Object);

use strict;
use CGI qw(:standard);
use Data::Dumper;

## aldente modules
use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::DB_Object;
use SDB::DBIO;
use SDB::HTML;
use alDente::Run;
use alDente::Tools;
use Template::Run_Views;

use vars qw($user_id $homelink %Configs);

my $TABLE = 'Template_Run, Run';


#############################
sub new {
#############################
# Description:
#
# Usage: 
#
#############################
    my $this  = shift;
    my $class = ref($this) || $this;
    my %args  = &filter_input(\@_);

    my $lanes_ref     = $args{-lanes        };
    my $equipment_id  = $args{-equipment    };
    my $dbc           = $args{-dbc          };
    my $self = SDB::DB_Object->new( -dbc    => $dbc,
				                    -tables => $TABLE, );

    $self->{dbc          } = $dbc;
    $self->{lanes        } = $lanes_ref;
    $self->{equipment_id } = $equipment_id;

    if ( defined $args{-id} ) {
        $self->{run_id} = $args{-id};
        my ($id)        = $dbc->Table_find( 'Template_Run', 'Template_Run_ID', "WHERE FK_Run__ID = $self->{run_id}");
        $self->{id}     = $id;

        $self->primary_value( -table => 'Template_Run', -value => $id );
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





#############################
sub create_Run {
#############################
# Description:
#
# Usage: 
#
#############################

    my $self = shift;
    my %args = &filter_input(\@_);
    my $run;
    return $run;
}


#############################
sub get_Template_data {
#############################
# Description:
#
# Usage: 
#
#############################

    my $self = shift;
    my %args = &filter_input(\@_);
    my $run;
    return $run;
}

