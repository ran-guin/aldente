################################################################################
# Search.pm
#
# A generic Search engine
#
###############################################################################
package alDente::Search;

##############################
# superclasses               #
##############################

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);
use Data::Dumper;
use Statistics::Descriptive;
use RGTools::Barcode;
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DB_Object;
use alDente::Form;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use alDente::Container;
use alDente::Data_Images;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::DB_Form_Viewer;
use SDB::Data_Viewer;
use Sequencing::Primer;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Conversion;
use RGTools::Views;

##############################
# global_vars                #
##############################
use vars qw($testing $Security);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################

##############################
# constructor                #
##############################

###################
#
# provide the form template to facilitate the search
#
#
###################
sub build_Form {
###################
    my $class = shift;                      # the type of object searched for.
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $form  = h2("$class Search form");

    $form .= &alDente::Form::start_alDente_form( $dbc, 'Generic_Search' );
    $form .= &filter_Options($class);
    $form .= hr;

    $form .= &define_Layers(
        -layers => {
            'Table'  => &choose_Fields($class),
            'Matrix' => &choose_Matrix($class)
        }
    );

    $form .= hr;
    $form .= &submit_Form($class);

    $form .= end_form();

    return $form;
}

###################
#
# provide object filtering options
#
#
#####################
sub filter_Options {
#####################
    my $class = shift;

    my $filter = "Retrieve fields that can be used to filter $class object...<P>";
    $filter .= "prompt user with fields (use DB_Form if possible (?))";

    return "put filtering options here";
}

###################
#
# provide object filtering options
#
#
#####################
sub choose_Fields {
#####################
    my $class = shift;

    my $fields = "(include radio button which presets fields for standard views)<P>";
    $fields .= "put list of fields to be extracted here...<P>";

    $fields .= "(sub section should allow for retrieval of Sum() and Avg() values<P>";

    $fields .= "(final section should allow for retrieval of special data (eg images or histograms ?)<P>";

    return $fields;
}

##########################################################
#
# allow output of X vs Y matrix (eg Tissue vs. Organism)
#
#
#####################
sub choose_Matrix {
#####################
    my $class = shift;

    my $fields = "(include radio button which presets fields for standard views - eg  Tissue vs Organism)<P>";

    $fields .= "choose Fields for both X and Y axis (two identical columns)";

    return $fields;
}

###################
#
# provide object filtering options
#
#
#####################
sub submit_Form {
#####################
    my $class = shift;

    return submit( -name => "Perform $class Search", -class => 'search' );
}

return 1;

