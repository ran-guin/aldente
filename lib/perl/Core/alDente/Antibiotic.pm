###################################################################################################################################
# Antibiotic.pm
#
# Class module that encapsulates a DB_Object that represents a Antibiotic
#
# $Id: Antibiotic.pm,v 1.35 2004/12/03 20:02:42 jsantos Exp $
###################################################################################################################################
package alDente::Antibiotic;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Antibiotic.pm - !/usr/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/bin/perl<BR>!/usr/local/bin/perl56<BR>!/usr/local/bin/perl56<BR>Class module that encapsulates a DB_Object that represents a Antibiotic<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;

#use Storable;
use POSIX qw(log10);

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use alDente::SDB_Defaults;
use alDente::Barcoding;
use alDente::Notification;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Object;
use RGTools::Conversion;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;

##############################
# global_vars                #
##############################
### Global variables
use vars qw($User $Connection $java_bin_dir $templates_dir $bin_home);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
### Modular variables
my $DateTime;
### Constants
my $FONT_COLOUR = 'BLUE';
my ($mypath) = $INC{'alDente/Antibiotic.pm'} =~ /^(.*)alDente\/Antibiotic\.pm$/;
my $TAB_TEMPLATE = $mypath . "/../../conf/templates/Antibiotic Order Form.txt";

##############################
# constructor                #
##############################

############################################################
# Constructor: Takes a database handle and a antibiotic ID and constructs a antibiotic object
# RETURN: Reference to a Antibiotic object
############################################################
sub new {
    my $this = shift;
    my %args = @_;

    my $dbc = $args{-dbc} || $args{-connection} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $antibiotic_id = $args{-antibiotic_id};    # Antibiotic ID of the project
    my $frozen        = $args{-frozen} || 0;      # flag to determine if the object was frozen
    my $encoded       = $args{-encoded};          # flag to determine if the frozen object was encoded
    my $class         = ref($this) || $this;

    my $self;
    if ($frozen) {
        $self = $this->Object::new(%args);
    }
    elsif ($antibiotic_id) {
        $self = SDB::DB_Object->new( -dbc => $dbc, -tables => "Antibiotic,Antibiotic_Customization", -primary => $antibiotic_id );

        #acquire all information necessary for Projects
        $self->load_Object();
        bless $self, $class;
    }
    else {
        $self = SDB::DB_Object->new( -dbc => $dbc, -tables => "Antibiotic,Antibiotic_Customization" );
        bless $self, $class;
    }

    unless ($dbc) {
        Message("Connection not defined");
    }

    $self->{dbc} = $dbc;

    return $self;
}
###########################
sub validate_Antibiotic {
###########################
    my %args         = &filter_input( \@_ );
    my $library      = $args{-library};
    my $object_class = 'Antibiotic';

    my $filter_table = "Vector_TypeAntibiotic";
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $navigator_on = $args{-navigator_on} || 0;
    my %list;
    my %grey;
    $grey{'LibraryApplication.FK_Object_Class__ID'} = $object_class;
    $list{'LibraryApplication.Direction'} = $dbc->get_enum_list( 'LibraryApplication', "Direction" );

    #    $list{'LibraryApplication.Object_ID'} = \@application_values;
    $grey{'LibraryApplication.FK_Library__Name'} = $library;

    my $valid_form = SDB::DB_Form->new( -dbc => $dbc, -table => $filter_table, -target => 'Database' );

    if ( $library && ( $library !~ /,/ ) ) {
        $grey{'Vector_TypeAntibiotic.FK_Library__Name'} = $library;
    }
    elsif ($library) {
        my @lib_list = Cast_List( -list => $library, -to => 'array' ) if $library;
        $list{'Vector_Antibiotic.FK_Library__Name'} = \@lib_list;
    }
    my @valid_vector = $dbc->Table_find( "LibraryVector,Vector,Vector_Type", "Vector_Type_Name", "WHERE FK_Library__Name = '$library' and FK_Vector__ID = Vector_ID and Vector.FK_Vector_Type__ID = Vector_Type_ID" );
    $list{'FK_Vector_Type__ID'} = \@valid_vector;
    $valid_form->configure( -list => \%list, -grey => \%grey );
    return $valid_form->generate( -title => "Valid $object_class for Library", -navigator_on => $navigator_on, -form => 'Valid_Antibiotic', -return_html => 1 );
}
#####################
sub suggest_Antibiotic {
#####################
    my %args         = &filter_input( \@_ );
    my $library      = $args{-library};                                                                 ## already quoted library
    my $object_class = 'Antibiotic';
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $navigator_on = $args{-navigator_on} || 0;

    my $condition
        = "WHERE LibraryVector.FK_Library__Name=Library_Name AND FK_Project__ID=Project_ID AND Vector_TypeAntibiotic.FK_Vector_Type__ID=Vector.FK_Vector_Type__ID and LibraryVector.FK_Vector__ID =Vector.Vector_ID AND Vector_TypeAntibiotic.FK_Antibiotic__ID=Antibiotic_ID";

    my @lib_list = Cast_List( -list => $library, -to => 'array' ) if $library;

    if ($library) {
        my $lib_list = Cast_List( -list => $library, -to => 'string', -autoquote => 1 );
        $condition .= " AND FK_Library__Name IN ($lib_list)";
    }

    my @application_values = $dbc->Table_find( "Library,Project,Vector,LibraryVector,Vector_TypeAntibiotic,Antibiotic", "Antibiotic_Name", $condition, -distinct => 1 );

    my %list;
    my %grey;
    $grey{'LibraryApplication.FK_Object_Class__ID'} = $object_class;
    $list{'LibraryApplication.Direction'}           = $dbc->get_enum_list( 'LibraryApplication', "Direction" );
    $list{'LibraryApplication.Object_ID'}           = \@application_values;
    if ( $library && ( $library !~ /,/ ) ) {
        $grey{'LibraryApplication.FK_Library__Name'} = $library;
    }
    elsif ($library) {
        $list{'LibraryApplication.FK_Library__Name'} = \@lib_list;
    }

    my $suggest_form = SDB::DB_Form->new( -dbc => $dbc, -table => 'LibraryApplication', -target => 'Database' );
    $suggest_form->configure( -list => \%list, -grey => \%grey );
    return $suggest_form->generate( -title => "Suggest $object_class for Library", -navigator_on => $navigator_on, -form => 'LibraryApplication', -return_html => 1 );
}

##############################
# public_functions           #
##############################
######################
sub list_Antibiotics {
######################
    my %args = &filter_input( \@_, -args => 'dbc' );
    my $dbc             = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $library         = $args{-library};
    my $project         = $args{-project};
    my $library_type    = $args{-type};
    my $antibiotic      = $args{-antibiotic};
    my $extra_condition = $args{-condition} || 1;

    my $tables    = "Project,Library";
    my $condition = "WHERE FK_Project__ID=Project_ID";

    if ($project) {
        $extra_condition .= " AND Project_Name = '$project'";
    }
    if ($library_type) {

        #$tables .= ",Vector_Based_Library";
        #$condition .= " AND Vector_Based_Library.FK_Library__Name=Library_Name";
        $tables          .= " LEFT JOIN Vector_Based_Library ON Vector_Based_Library.FK_Library__Name=Library_Name";
        $extra_condition .= " AND (Vector_Based_Library_Type = '$library_type' OR Library_Type = '$library_type')";
    }
    if ($library) {
        my $lib_list = Cast_List( -list => $library, -to => 'string', -autoquote => 1 ) if $library;
        $extra_condition .= " AND Library_Name IN ($lib_list)";
    }
    if ($antibiotic) {
        $extra_condition .= " AND Antibiotic_Name LIKE '$antibiotic'";
    }

    my $all    = param('Include All Antibiotics');                                      ### allow viewing of unused antibiotics
    my $output = h1('Valid Antibiotics <I>(possible options based upon Vector)</I>');

    # allow only admins to view valid and to validate/suggest antibiotics

    my $admin  = 0;
    my $access = $dbc->get_local('Access');
    if ( ( grep {/Admin/xmsi} @{ $access->{ $dbc->config('Target_Department') } } ) || $access->{'LIMS Admin'} ) {
        $admin = 1;
    }

    ## Valid antibiotics ##
    #    $output .= &Link_To($homelink,'Add',"&LibraryApplication=1&FK_Library__Name=$library&Object_Class=Antibiotic") if $library;
    if ($admin) {
        $output .= create_tree(
            -tree  => { "Validate New Antibiotic" => validate_Antibiotic( -library => $library ) },
            -print => 0
        );
    }

    $output .= $dbc->Table_retrieve_display(
        "$tables,Antibiotic,LibraryVector,Vector,Vector_TypeAntibiotic,Vector_Type",
        [ 'Library_Name', 'Antibiotic_Name', 'Vector_Type_Name' ],
        "$condition AND Vector_TypeAntibiotic.FK_Antibiotic__ID=Antibiotic_ID AND Vector_TypeAntibiotic.FK_Vector_Type__ID=Vector.FK_Vector_Type__ID AND Vector_Type_ID = Vector.FK_Vector_Type__ID AND LibraryVector.FK_Vector__ID=Vector_ID AND LibraryVector.FK_Library__Name=Library_Name AND $extra_condition",
        -return_html => 1
    ) if $extra_condition ne '1';

    ## Suggested antibiotics ##
    $output .= h1('Suggested Antibiotics <I>(suggested options based upon Library)</I>');

    #    $output .= &Link_To($homelink,'Add',"&LibraryApplication=1&FK_Library__Name=$library&Object_Class=Antibiotic") if $library;
    if ($admin) {
        $output .= create_tree(
            -tree  => { "Suggest New Antibiotic" => suggest_Antibiotic( -library => $library ) },
            -print => 0
        );
    }

    $output .= $dbc->Table_retrieve_display(
        "$tables,Antibiotic,LibraryApplication,Object_Class",
        [ 'Library_Name', 'Antibiotic_Name' ],
        "$condition AND LibraryApplication.Object_ID=Antibiotic_ID AND LibraryApplication.FK_Library__Name=Library_Name AND FK_Object_Class__ID=Object_Class_ID AND Object_Class = 'Antibiotic' AND $extra_condition",
        -return_html => 1
    ) if $extra_condition ne '1';

    return $output;
}

return 1;
