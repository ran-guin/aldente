## Prostate_Lab department home page, will need to be adjusted according to needs of the group, Department Name, etc.
## Also, see other alDente::<name_of>_Department modules to guide adjusting the access priveledges of the layers
## This one started out as the Cancer_Genetics_Department.pm module

package Prostate_Lab::Department;

use base alDente::Department;

use strict;
use warnings;
use CGI('standard');
use Data::Dumper;
use Benchmark;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use Prostate_Lab::Department_Views;

use vars qw(%Configs);

## Specify the icons that you want to appear in the top bar
my @icons_list = qw(Contacts Equipment);

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
  my %args = filter_input(\@_,-args=>'dbc,open_layer');
  my $dbc = $args{-dbc} || $self->dbc;
  my $open_layer= $args{-open_layer} || '';

  ### Permissions ###
  my %Access = %{$dbc->get_local('Access')};

  my $datetime = &date_time;
  my $user = $dbc->get_local('user_id');
  
  # This user does not have any permissions on Lab
  if (!($Access{'Prostate Lab'} || $Access{'LIMS Admin'})) {
    return;
  }

  return $self->View->home_page();

}
#
#
#
######################
sub get_greys_and_omits {
######################

    my @greys = qw( Source_Type FK_Plate_Format__ID Source_Status Received_Date FKReceived_Employee__ID FK_Barcode_Label__ID Current_Amount Plate_Type Plate_Content_Type FK_Employee__ID Plate_Created Plate_Status FK_Library__Name);
    my @omits = qw( Current_Amount FKOriginal_Plate__ID Plate_Content_Type );

    return (\@greys,\@omits);
    
}

#
#<snip>
#
#</snip>
##################
sub get_searches_and_creates {
##################

    my %args = @_;
    my %Access = %{$args{-access}} if $args{-access};

    my @creates = ();
    my @searches = ();

  # Department permissions for searches
    if (grep(/Lab/,@{$Access{'Prostate Lab'}})) {
	push(@searches,qw(Collaboration Contact Equipment Plate Tube Rack));
	push(@creates,qw(Plate Contact Source Equipment Rack));
    }

  # Bioinformatics permissions for searches
    if (grep(/Bioinformatics/,@{$Access{'Prostate Lab'}})) {
	push(@searches,qw(Study));
	push(@creates,qw(Study));
    }

  # Admin permissions for searches
    if (grep(/Admin/,@{$Access{'Prostate Lab'}})) {
	push(@searches,qw(Employee Organization Contact Rack Tube Rack Plate));
	push(@creates,qw(Collaboration Employee Organization Project));
    }
    @creates = sort @{unique_items([sort(@creates)])};
    @searches = sort @{unique_items([sort(@searches)])};
    
    return (\@searches, \@creates);

}

########################################
#
# Accessor function for the icons list
#
####################
sub get_icons {
####################
  return \@icons_list;
}


return 1;
