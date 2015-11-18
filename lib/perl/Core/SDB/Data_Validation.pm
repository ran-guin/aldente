################################################################################
#
# Validation.pm
#
# This provides context specific data validation checks 
#
#
################################################################################

package SDB::Data_Validation;

use base LampLite::Data_Validation;

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

################################
## Data Validation conditions ##
################################
#
#  A list of standard prefixes used for specific tables.
#   (These prefixes are used for barcodes, and keys to these fields should be scannable...)
#
## Conditions to override inherited validation ##
my %Validate_condition = (
    Plate      => "Plate_Status IN ('Active')",   
    Solution   => " Solution_Status IN ('Open','Unopened','Temporary')",
    Equipment  => " Equipment_Status = 'In Use'",
    Department => "Department_Status = 'Active'",
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


########################
# Wrapper for get_id()
##########################################
#
# Simple query to extract ID based on name for:
#
#  Employee
#  Contact
#  Organization
#  Project
#  Transposon
#  Contact
#
# <snip>
#  Example:  (find project_id for Xenopus project)
#
#   my $project_id = $API->get_aldente_id($dbc,-table=>'Project',-pattern=>'Xeno*');             ## should start with Xeno..
#   my $org ; $org = $API->get_aldente_id($dbc,-table=>'Organization',-name=>'Xenopus full length');    ## if you know exact name
#
#  Note (if using pattern matching you should check to make sure a UNIQUE id is returned - just check for a ',').
#
#   if ($project_id =~ /,/) { print "multiple projects found like this" }  ## check to see if more than one returned.
#   elsif ($project_id !~ /[1-9]/) { print "No valid id found" }           ## check to see if id returned.
#
#  Shortcut example (also valid - assumes two parameters sent are table, pattern):
#
#   my $project_id =  $API->get_aldente_id($dbc,'Project','Xeno*');
#
# </snip>
#
########################
sub get_valid_id {
########################
    my %args = &filter_input( \@_, -args => 'dbc,barcode,table', -mandatory => 'dbc,table' );
    if ( $args{ERRORS} ) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $dbc     = $args{-dbc};
    my $barcode = $args{-barcode};
    my $table   = $args{-table};      ## table to extract id from
    my $name    = $args{-name};       ## specify exact name
    my $pattern = $args{-pattern};    ## specify pattern (eg. 'Human*')

    my $validate   = $args{-validate};
    my $qc_check   = $args{-qc_check};     ##
                                           # my $fatal_validate = $args{-fatal_validate};  ## FLAG, causes return if any id is not valid
    my $fatal_flag = $args{-fatal_flag};

    # my $barcode = Cast_List(-list=>$args{-ids},-to=>'string',-autoquote=>1);   ### ids to check
    my $condition = $args{-condition} || 1;    ## optional extra condition
    my $quiet     = $args{-quiet} || 0;        ## quiet mode (suppress feedback unless errors)

    $pattern = convert_to_regexp($pattern) if $pattern;
    $pattern ||= $name;

    if ( $name || $pattern ) {                 ## search for the name of certain items to return an id.  (allow pattern (eg TL00*) ##
           my ($primary_field) = $dbc->get_field_info( $table, -type=>'Primary' );
           my ($name_field) = $dbc->get_field_info($table, -field=>'%name');      
            
            if ($primary_field && $name_field) {
                $condition .= " AND $name_field like '$pattern'";
                unless ($quiet) { print "SELECT $primary_field FROM $table WHERE $condition\n"; }

                my $found = join ',', $dbc->Table_find( $table, $table . "_ID", "WHERE $condition" );
                return $found;
            }
            else {
                if (!$quiet) { $dbc->warning("$primary_field not available for $name_field LIKE '$pattern'") }
            }
    }
    elsif ( $table ) {    ## this variation returns id for standard table types (wrapper for SDB::get_id) ##
        
        my $validate_condition = validate_condition($table);
        ## if validate option chosen and extra validation conditions exist for this object, include them ##
        if ( $validate && defined $validate_condition ) {
            $condition .= " AND $validate_condition";
        }
        
        $args{-condition} = $condition;
        my $valid_items = $dbc->get_id(%args);
        
        return $valid_items;
    }
    elsif ( $barcode ) {
        return $dbc->get_id(%args);
    }
    else { $dbc->warning("trying to retrieve id without passing name/pattern or barcode"); return; }
}


return 1;
