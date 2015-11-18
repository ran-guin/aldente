##################
# Object_App.pm #
##################
#
# This is a template for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Object_App;

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

#use base SDB::Object_App;
use base SDB::DB_Object_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use alDente::Object_Views;
use alDente::Validation;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

################
# Dependencies
################
#
# (document list methods accessed from external models)
#

###########################################################
# Previous methods that were here, but now commented out
###########################################################

############
sub setup {
############
    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   
            'Scan'         => 'scanned_home_page',
            'Home Page'    => 'home_page',
            'home_page'    => 'home_page',
            'Update Links' => 'update_link',
            'Reset Links'  => 'update_link',
            'Add Link'     => 'add_link'
        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

#########################
sub _get_barcode_object {
#########################
    my $self = shift;
    my $barcode = shift;
    my $dbc = $self->param('dbc');
    
    my ($table) = SDB::CustomSettings::barcode_class($barcode);
    
    if ($table) {
        use alDente::Validation;
        my $id = get_aldente_id( $dbc, $barcode, $table);
        if ($id =~/\d/) { return ($table, $id) }
        else { return ($table) }
    }

}

## PHASE OUT - should be handled in Scanner_App ##
#
# Go directly to any standardized home page 
#
# (requires standard object view methods: single_record_page / multiple_record_page )
# 
# Return: applicable home page 
########################
sub scanned_home_page {
########################
    my $self = shift;

    my $q = $self->query();
    my $dbc = $self->param('dbc');
    
    my $barcode = $q->param('Barcode');

    my ($table, $id) =  $self->_get_barcode_object($barcode);
    
    if (!$table || !$id) { return "ID: $id not found for $table in database (from $barcode)" }
      
    my $class = 'alDente' . '::' . $table;
    my $ok = eval "require $class"; 

    if (!$ok) {
        ## try table alias (eg convert Plate -> Container)
        my ($alias) = $dbc->Table_find('DBTable','DBTable_Title',"WHERE DBTable_Name = '$table'");
        if ($alias) { $class = 'alDente' . '::' . $alias;
            $ok = eval "require $class";
        }
    }

    my $Object = $class->new(-dbc=>$dbc, -id=>$id);    
    my $page = $Object->View->std_home_page(-dbc=>$dbc, -id=>$id);   ## std_home_page generates default page, with customizations possible via local single/multiple/no _record_page method ##
     
    return $page;
}

###############
sub home_page {
###############
    my $self = shift;

    my $q = $self->query();
    my $dbc = $self->param('dbc');
    
    my $table = $q->param('HomePage');
    my $id    = $q->param('ID');
    
    my $class = $self->class($table);
    my $ok = eval "require $class"; 

    my $Object = $class->new(-dbc=>$dbc, -id=>$id);    
    my $page = $Object->View->std_home_page(-dbc=>$dbc, -table=>$table, -id=>$id);   ## std_home_page generates default page, with customizations possible via local single/multiple/no _record_page method ##
     
    return $page;
}

return 1;
