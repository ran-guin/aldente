###################################################################################################################################
# Template::Run_Stat_View.pm
#
#
#
#
###################################################################################################################################
package Template::Run_Stat_Views;

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
use Template::Run_Stat;

use vars qw($user_id $homelink %Configs);

#########################
#
#
#
#
#########################
sub new {
#########################
    my $this = shift;
    my %args = &filter_input( \@_ );

    my $self = {};
    $self->{dbc} = $args{-dbc};

    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}

#########################
#
#
#
#
#########################
sub display_search_page {
#########################
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc};

    return "hi there!!";

}



