###########
# Employee.pm #
###########
#
# This module is used to handle 'Employee' objects
#
package alDente::Employee;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Employee.pm - This module is used to handle 'Employee' objects

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module is used to handle 'Employee' objects<BR>

=cut

##############################
# superclasses               #
##############################

use base SDB::User;

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################

use RGTools::RGIO;

##############################
# global_vars                #
##############################
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
#########
#__DATA__;

##############################
# constructor                #
##############################

##############################
# public_functions           #
##############################

## Redirect local calls to SUPER calls ##

   
### object oriented methods ## 
sub new_GrpEmployee_trigger { my $self = shift; return $self->new_GrpUser_trigger(@_) }
sub Employee_home { my $self = shift; return $self->User_home(@_) }
sub get_employee_Groups { my $self = shift; return $self->get_User_Groups(@_) }
sub new_Employee_trigger { my $self = shift; return $self->new_User_trigger(@_) }

##################
sub new {
##################
#
# Constructor of the object
#
    my $this = shift;
    my $class = ref($this) || $this; 
    my %args = filter_input(\@_);
    
    $args{-table} = 'Employee';
    return $this->SUPER::new(%args);
}

##################
sub define_User {
##################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->{dbc};
    my $id  = $args{-id}  || $self->{id};
    
    $self->SUPER::define_User(%args);
    
    return 1;
}

##################
sub load_User_Settings {
##################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->{dbc};
    my $id  = $args{-id}  || $self->{id};
 
    $self->SUPER::load_User_Settings(%args);

#    my $printer_setting = $dbc->session->user_setting('PRINTER_GROUP');
#    if ( $printer_setting ) {
#        use alDente::Barcoding;
#        alDente::Barcoding::reset_Printer_Group( $dbc, -User=>$self, -name => $printer_setting, -quiet => 1 );
#    }

    return 1;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Employee.pm,v 1.23 2004/11/30 23:15:02 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
