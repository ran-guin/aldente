## Template department home page, will need to be adjusted according to needs of the group, Department Name, etc.
## Also, see other alDente::<name_of>_Department modules to guide adjusting the access priveledges of the layers
## This one started out as the Cancer_Genetics_Department.pm module

package alDente::<Department_Name>_Department;

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



use vars qw(%Configs $Connection);

## Specify the icons that you want to appear in the top bar
my @icons_list = qw( Statistics Contacts Equipment);

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
  my %args = filter_input(\@_,-args=>'dbc,open_layer',-mandatory=>'dbc');
  my $dbc = $args{-dbc} || $Connection;
  my $open_layer= $args{-open_layer} || 'Incoming Samples';

  ### Permissions ###
  my %Access = %{$dbc->get_local('Access')};

  my $datetime = &date_time;
  my $user = $dbc->get_local('user_id');
  
  # This user does not have any permissions on Lab
  if (!($Access{'Lab_Department'} || $Access{'LIMS Admin'})) {
    return;
  }
  alDente::Department::set_links();
  
  my ($search_ref,$creates_ref) = get_searches_and_creates(-access=>\%Access);
  my @searches = @$search_ref;
  my @creates = @$creates_ref;

  my ($greys_ref,$omits_ref) = get_greys_and_omits();
  my @grey_fields= @$greys_ref;
  my @omit_fields = @$omits_ref;

  my $grey = join '&Grey=',@grey_fields;
  my $omit = join '&Omit=',@omit_fields;

  my @links;
  my @content_types = qw( Blood Plasma Serum Saliva ); ## Urine);
  my $type;
  my ($srclabel) = $dbc->Table_find('Barcode_Label','Barcode_Label_ID',"WHERE Barcode_Label_Name = 'src_no_barcode'");
  my @rackids = $dbc->Table_find('Rack','Rack_ID',"WHERE Rack_Type = 'Box'");
  my $defaultrack = 1;
  foreach my $rack (@rackids) { 
      if ($rack > $defaultrack) { $defaultrack = $rack; }
  }

## Set source fields
  my $set = '';
  $set .= "&FKReceived_Employee__ID=$user";
  $set .= "&Source_Status=Active";
  $set .= "&Received_Date=$datetime";
  $set .= "&FK_Barcode_Label__ID=$srclabel";
  $set .= "&FK_Plate_Format__ID=Tube";
  $set .= "&FK_Original_Source__ID=1";  
  $set .= "&FK_Library__Name='CGBM1'";
  $set .= "&FK_Rack__ID=$defaultrack";

## Set plate fields
  my $plateset = '';
  $plateset .= "&Plate_Created=$datetime";
  $plateset .= "&FK_Employee__ID=$user";
  $plateset .= "&Plate_Type=Tube";
  $plateset .= "&Plate_Status=Active";

  my $extra;

  my $output;
  $output .= "<h2>Samples</h2>";
  $output .= '<hr>';

  foreach $type ( @content_types ) {
      my $label = "<img src='/$URL_dir_name/images/png/$type.png'/><BR>"."$type";
      my ($type_id) = $dbc->Table_find('Sample_Type','Sample_Type_ID',"WHERE Sample_Type = '$type'");
      $plateset .= "&FK_Sample_Type__ID=$type_id";
      push ( @links, &Link_To($homelink,$label,"&New+Entry=New+Source&Plate_Content_Type=$type$set$plateset&Grey=$grey&Omit=$omit&Source_Type=$type") );
  }
 
## Main table
  my $main_table = HTML_Table->new(-title=>"Department Home Page",
				   -width=>'100%', 
				   -bgcolour=>'white ',
				   -nolink=>1,
				   );  

  my $output = "<h2>Samples</h2>";
  $output .= '<hr>';

  my $centre = HTML_Table->new(-align=>'center ',-width=>'100%');
  $centre->Set_Row(["<B>Click on a new sample to define: <B>",@links]);
  $output .= $centre->Printout(0);

### Solution Section
  my $solution = alDente::Department::solution_box(-choices=>[('Find Stock','Search Solution','Show Applications')]);

### Equipment Section
  my $equip = alDente::Department::equipment_box(-choices=>[('--Select--','Maintenance ','Maintenance History ')]);

## Prep, Protocol, Pipeline summaries

  my $views = alDente::Department::latest_runs_box();
  my $summaries_box = alDente::Department::prep_summary_box();
  my $view_summary = alDente::Department::view_summary_box();

  my $extra_links = '';

## Plates Section
  my %labels;
  $labels{'-'} = '--Select--';
  $labels{'Plate Set'} = 'Grab Plate Set ';
  $labels{'Recover Set'} = 'Recover Plate Set ';
  
  my $plates_box;
  if(grep(/Lab|Bioinformatics/,@{$Access{'Lab'}})) {
    $plates_box = alDente::Department::plates_box(-type=>'Library_Plate',
						  -id_choices=>['-',					
								'View Ancestry',
								'Plate History',
							       ],
						  -access=>$Access{'Lab'},
                                                  -include_rearray=>0,
						  -labels=>\%labels);
  } 

## Lab Layer
  $main_table->Set_Row([ $plates_box . $solution . $equip ]);

  my $search_create_box = alDente::Department::search_create_box(\@searches,\@creates);

  my $libs = join "','", $dbc->Table_find('Library,Grp,Department','Library_Name',"WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('Lab')");


  my $project_list = &alDente::Project::list_projects("Library_Name IN ('$libs')");
  $main_table->Toggle_Colour('off');
  $main_table->Set_Column_Widths(['50%','50%']);
  $main_table->Set_VAlignment('top');

  my $lab_layer = $main_table->Printout(-filename=>0);
  my @order = ('Projects','Incoming Samples','Lab','Summaries','Database');

## Define the layers of the Department 
  my $layers = {
      "Incoming Samples" => $output,
      "Database" => $search_create_box . lbr . $extra_links 
      }; ## June 13 - removed Lab, Summaries, and Database options from

## Define admin layer
  my $admin_table = alDente::Admin::Admin_page($dbc,-reduced=>0,-department=>'Lab',-form_name=>'Admin_layer');
  if (grep(/Admin/i, @{$Access{'Lab'}})) {
      push (@order, 'Admin');
      $layers->{"Admin"} = $admin_table;
  }

  return define_Layers(-layers=>$layers, 
		       -tab_width=>100,
		       -order=>\@order,
                       -default=>$open_layer);
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
    my %Access = %{$args{-access}};

    my @creates = ();
    my @searches = ();

  # Department permissions for searches
    if (grep(/Lab/,@{$Access{Lab_Department}})) {
	push(@searches,qw(Collaboration Contact Equipment Plate Tube Rack));
	push(@creates,qw(Plate Contact Source Equipment Rack));
    }

  # Bioinformatics permissions for searches
    if (grep(/Bioinformatics/,@{$Access{Lab}})) {
	push(@searches,qw(Study));
	push(@creates,qw(Study));
    }

  # Admin permissions for searches
    if (grep(/Admin/,@{$Access{'Lab_Department'}})) {
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
