################################################################################
#
# This is a general module to provide help via javascript radio buttons....
#
################################################################################
################################################################################
# $Id: HelpButtons.pm,v 1.5 2004/06/17 22:54:45 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.5 $
#     CVS Date: $Date: 2004/06/17 22:54:45 $
################################################################################
package alDente::HelpButtons;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

HelpButtons.pm - This is a general module to provide help via javascript radio buttons....

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This is a general module to provide help via javascript radio buttons....<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    help_button
);

##############################
# standard_modules_ref       #
##############################

use CGI qw(:standard);
use DBI;

##############################
# custom_modules_ref         #
##############################
use SDB::CustomSettings;
use strict;
##############################
# global_vars                #
##############################
use vars qw($Help_Topics);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
$Help_Topics->{StockSource} = 'Stock Source refers to whether this batch of items is an:\n\nOrder - Ordered\nSample - provided as a free Sample\nBox - removed from an existing barcoded Box (or a Kit)\nMade in House - made here (eg. a Solution)';
$Help_Topics->{StockType}
    = 'Stock Type will define how this batch of items is to be stored.\n  Items sharing similar attributes such as Solutions and Reagents are stored in a common table (as are Kits and Boxes).\nEquipment is stored in another table.\nBarcodes are generated for all of these items.\n\nService is used for Warranty and Service Contracts (generally for Equipment), and is handled specially.\n\nOther equipment is currently stored in a Misc_Item table, but may be described here as Computer Equipment, or as a Misc_Item for now.';
$Help_Topics->{BoxID}    = 'This is used if this batch of stock is taken from a Box which has already been barcoded.\n\nNormally this will be achieved by scanning the box and indicating what is to be removed from it.';
$Help_Topics->{OrdersID} = 'This is a reference to the Order ID number for this batch of stock.\nis should be automatically set when an item is clicked as received from the Orders Page.';

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#####################
sub help_button {
#####################
    #
    # supply simple radio-button linked to javascript to give users info
    #
    my $form  = shift;
    my $topic = shift;
    my $label = shift || $topic;
    if ( defined $Help_Topics->{$topic} ) {
        my $message = $Help_Topics->{$topic};

        #	return radio_group(-name=>'HB',-values=>[$label],-onClick=>"SendMessage(document.$form,'$message')");
        return radio_group( -name => 'HB', -values => [$label], -onClick => "ToggleHelpWin('$message')" );
    }
    else { return "(No help)"; }
    return "hello";
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

$Id: HelpButtons.pm,v 1.5 2004/06/17 22:54:45 achan Exp $ (Release: $Name:  $)

=cut

return 1;
