###############################################################################################################
# MVC_Exceptions
#
# Handle logic for CGI input paramters used for non-MVC logic
#
# This should be minimized, but may be necessary to support custom legacy code
#
# $Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $
##############################################################################################################
package LampLite::MVC_exceptions;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

=head1 SYNOPSIS <UPLINK>

	Module containing wrapper methods / functions enabling use of non MVC logic (typically old legacy code)

=head1 DESCRIPTION <UPLINK>

=for html
Stores user session<BR>

=cut

use RGTools::RGIO;
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;

use LampLite::CGI;
my $q = new LampLite::CGI();

##############################################################
# Custom method to handle shortcut run modes not in MVC mode
#
# Ideally, these should be phased out and converted to MVC run modes if possible
#
# Any required methods should be dynamically loaded if possible to simplify main script
#
# Exceptions may exist for certain cases which justify alternative to MVC execution
#
# Return: true if run mode found
########################
sub non_MVC_run_modes {
########################
    my $dbc         = shift;
	return 0;
}

#
# PHASE OUT !!
#
# Return: old branching logic to generate table editing pages
#######################
sub special_branches {
#######################
    my $dbc      = shift;
    my $branched = shift;

    return $branched;
}

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

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
