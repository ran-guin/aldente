###################################################################################################################################
# SDB::FAQ.pm
#
# Model in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package SDB::FAQ; 

use base LampLite::DB_Object;

use strict;

use RGTools::RGIO;   ## include standard tools

#####################
sub new {
#####################
        my $this = shift;
            my %args = &filter_input( \@_);

                my $dbc  = $args{-dbc};

                    my $self = {};

                        my ($class) = ref($this) || $this;
                            bless $self, $class;

                                $self->{dbc} = $dbc;
                                    
                                        return $self;
}

1;


