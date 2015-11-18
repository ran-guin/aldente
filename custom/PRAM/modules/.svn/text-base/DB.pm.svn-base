###################################################################################################################################
# PRAM::DB.pm
#
# Basic run modes related to logging in (using CGI_Application MVC Framework)
#
###################################################################################################################################
package PRAM::DB;

use base SDB::DBIO;

use strict;

use RGTools::RGIO qw(filter_input);

# This method should be defined for all inherited DB object classes 
#
# Dynamically load the given module at the highest available level.
#  (if not found, it will check inherited classes and load them as required)
#
#
# Return: name of module loaded if found 
######################
sub dynamic_require {
######################
	my $self = shift;
	my %args = filter_input(\@_, -args=>'module');
	
	my $module = $args{-module};
	my $construct = $args{-construct};
	my $id        = $args{-id};       
	my $debug  = $args{-debug};
	
	my $scope = 'PRAM';  ## change this line only depending on scope of method ##
	
	my $test = $scope . '::' . $module;
	my $local = eval "require $test";
	if ($local) {
		if ($construct) {
		    ## return constructed object (passing in optional id) ##
		    my $Object = $test->new(-dbc=>$self, -id=>$id);
    		if ($debug) { $self->message("Loaded Local $test") }
    		return $Object;
		}
		else {
       		if ($debug) { $self->message("Found Local $test") }
		    return $test;
	    }
    }
	else {
		if ($debug) { $self->message("$test not Found... keep looking.... ") }
		return $self->SUPER::dynamic_require(%args);
	}

}
1;

