##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package Prostate_Lab::Department_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base alDente::CGI_App;

use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::HTML;  ##  qw(hspace vspace get_Table_param HTML_Dump display_date_field set_validator);
use SDB::DBIO;
use SDB::CustomSettings;

use alDente::Form;
use alDente::Container;
use alDente::Rack;
use alDente::Validation;
use alDente::Tools;
use alDente::Source;

use Prostate_Lab::Department;

##############################
# global_vars                #
##############################
use vars qw(%Configs  $URL_temp_dir $html_header $debug);  # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

my $q;
my $dbc;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');
    
    $self->run_modes(
		     'Home Page'	       => 'home_page', 
                     'Help'   => 'help',
		     'Summary' => 'summary',
		     'Upload Plate' => 'upload_source_and_plate',
                     'Confirm Upload' => 'upload_source_and_plate',
);

    $dbc = $self->param('dbc');
    $q = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    
    return $self;
}

###############
sub summary {
###############
    my $self = shift;
    my $dbc = $self->param('dbc');
    my $q = $self->query();
    
    my $since = $q->param('from_date_range');
    my $until = $q->param('to_date_range');
    my $debug = $q->param('Debug');
    my $condition = $q->param('Condition') || 1;

    my $page = "summary";
    return $page;
}

# Also, displays some basic statistics relevant to each of the run modes 
##################
sub home_page {
##################
 
   my $self = shift;
   return Prostate_Lab::Department_Views::home_page(-dbc=>$dbc);
}

###########
sub help {
############

my $page;

return $page ;
}


#############################
sub upload_source_and_plate {
#############################
# Description: Upload run result if necessary
#
# Usage: 
#
#############################
    my $self = shift;
    my %args = filter_input( \@_);
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query();

    my $output;

    # get input params                                                      
    my $filename = $q->param('input_file_name');
    my $delimiter = $q->param('Delimiter');
    my $template  = $q->param('template_file') ;
    my $selected  = join ',', $q->param('Select');
    my @selected_headers = $q->param('Select_Headers');
    my $location = $q->param('FK_Rack__ID') || $q->param('Rack_ID');    ## optional location argument for automatic item relocation                                                              
    my $debug     = $q->param('Debug');
    my $suppress_barcodes = $q->param('Suppress_Barcodes');             ## suppress barcodes generated during upload (eg during a trigger)                                                       
    my $header_row = $q->param('Header_Row') || 1;
    my $confirmed = ($q->param('rm') eq 'Confirm Upload');
    my $reload    = ($q->param('rm') eq 'Reload Original File');


    my $run_mode = $q->hidden(-name =>'cgi_application', -value=>'Prostate_Lab::Department_App', -force=>1);
    my %preset;

    my $Import = new SDB::Import( -dbc => $dbc);
    my $Import_View = new SDB::Import_Views( -model => { 'Import' => $Import } );

    $Import->load_DB_data(-dbc=>$dbc, -filename=>$filename, -template=>$template, -selected_records=>$selected, -selected_headers=>\@selected_headers, -location=>$location, -header_row=>$header_row, -confirmed=>$confirmed, -reload=>$reload, -preset=>\%preset);

    if ($Import->{confirmed}) {
        Message("Confirmed: Writing to database... ");
	## Import Data
	$dbc->start_trans('upload');
        my $toggle_printing;
        if ($suppress_barcodes) { $toggle_printing = $dbc->session->toggle_printers('off'); }  # suppresses potential print actions caused by triggers #
        my $updates = $Import->save_data_to_DB(-debug=>0);
        if ($toggle_printing) { $dbc->session->toggle_printers('on') }
        $output .= $Import_View->preview_DB_update(-filename=>$Import->{file}, -confirmed=>$Import->{confirmed},-run_mode => $run_mode);
	$dbc->finish_trans('upload');

	#update source record
	my $user = $Import->{user};
	my ($attribute_ID) = $dbc->Table_find("Attribute","Attribute_ID","WHERE Attribute_Name = 'Redefined_Source_For'");
	my $time = &date_time();

	for (my $index = 0; $index <= $#{$updates->{Source}}; $index++) {
	    my $source = $updates->{Source}[$index];
	    $dbc->Table_update("Source","FKSource_Plate__ID","NULL","WHERE Source_ID = $source");
	    my $plate = $updates->{Plate}[$index];
	    $dbc->Table_append("Plate_Attribute","FK_Plate__ID,FK_Attribute__ID,Attribute_Value,FK_Employee__ID,Set_DateTime","$plate,$attribute_ID,$source,$user,'$time'");
	    $dbc->Table_update("Plate","Plate_Created","'$time'","WHERE Plate_ID = $plate");
	}
	
    }
    else {
	## generate preview of data fields and records for confirmation ##
	$output .= $Import_View->preview_DB_update(-filename=>$Import->{file},-run_mode => $run_mode);

    }

    return $output;
}


return 1;
