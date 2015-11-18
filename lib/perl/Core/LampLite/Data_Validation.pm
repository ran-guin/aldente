################################################################################
#
# Validation.pm
#
# This provides context specific data validation checks 
#
#
################################################################################

package LampLite::Data_Validation;

push @ISA, 'Exporter';

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    get_valid_id
);
@EXPORT_OK = qw(
    get_valid_id
);

##############################
# standard_modules_ref       #
##############################

use strict;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;

################################
## Data Validation conditions ##
################################
#
#  A list of standard prefixes used for specific tables.
#   (These prefixes are used for barcodes, and keys to these fields should be scannable...)
#
## Conditions to override inherited validation ##
my %Validate_condition = (
    'Employee' => "Employee_Status = 'Active'",
    'User' => "User_Status = 'Active'",
);

## Conditions to be added to inherited validation ## 
## Note: these will NOT be accessed if Validate_condition is expressed above ...## 

my %Add_condition = ( 

);
    
#########################
sub validate_condtion {
#########################
    my $self = shift;
    my $scope = shift;
    my $add_condition = shift;
   
    my $condition;
    if ($Validate_condition{$scope}) { $condition = $Validate_condition{$scope} }   ## override inherited condition
    elsif ($Add_condition{$scope}) { $condition = $self->SUPER::validate_condition($scope, $Add_condition{$scope}) }

    if ($add_condition) { $condition .= " AND $add_condition" }

    return $condition;
}

return 1;
