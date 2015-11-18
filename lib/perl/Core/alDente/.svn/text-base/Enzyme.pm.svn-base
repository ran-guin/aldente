###################################################################################################################################
# Enzyme.pm
#
# Class module that encapsulates a DB_Object that represents a Enzyme
#
# $Id: Enzyme.pm,v 1.35 2004/12/03 20:02:42 jsantos Exp $
###################################################################################################################################
package alDente::Enzyme;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Enzyme.pm - !/usr/local/bin/perl56

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl56<BR>!/usr/local/bin/perl56<BR>!/usr/local/bin/perl56<BR>Class module that encapsulates a DB_Object that represents a Enzyme<BR>

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
use Storable;
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
use vars qw($User %Std_Parameters $Connection $java_bin_dir $templates_dir $bin_home);

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
my ($mypath) = $INC{'alDente/Enzyme.pm'} =~ /^(.*)alDente\/Enzyme\.pm$/;
my $TAB_TEMPLATE = $mypath . "/../../conf/templates/Enzyme Order Form.txt";

##############################
# constructor                #
##############################

############################################################
# Constructor: Takes a database handle and a enzyme ID and constructs a enzyme object
# RETURN: Reference to a Enzyme object
############################################################
sub new {
    my $this = shift;
    my %args = @_;

    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $enzyme_id = $args{-enzyme_id};                                                                # Enzyme ID of the project
    my $frozen    = $args{-frozen} || 0;                                                              # flag to determine if the object was frozen
    my $encoded   = $args{-encoded};                                                                  # flag to determine if the frozen object was encoded
    my $class     = ref($this) || $this;

    my $self;
    if ($frozen) {
        $self = $this->Object::new(%args);
    }
    elsif ($enzyme_id) {
        $self = SDB::DB_Object->new( -dbc => $dbc, -tables => "Enzyme,Enzyme_Customization", -primary => $enzyme_id );

        #acquire all information necessary for Projects
        $self->load_Object();
        bless $self, $class;
    }
    else {
        $self = SDB::DB_Object->new( -dbc => $dbc, -tables => "Enzyme,Enzyme_Customization" );
        bless $self, $class;
    }

    unless ($dbc) {
        Message("Connection not defined");
    }

    $self->{"dbc"} = $dbc;

    return $self;
}

##############################
# public_functions           #
##############################
######################
sub list_Enzymes {
######################
    my %args            = &filter_input( \@_, -args => 'dbc' );
    my $dbc             = $args{-dbc};
    my $library         = $args{-library};
    my $project         = $args{-project};
    my $library_type    = $args{-type};
    my $enzyme          = $args{-enzyme};
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
    if ($enzyme) {
        $extra_condition .= " AND Enzyme_Name LIKE '$enzyme'";
    }

    my $all = param('Include All Enzymes');    ### allow viewing of unused enzymes
    my $output;

    # allow only admins to view valid and to validate/suggest enzymes

    my $admin = 0;
    if ( grep( /Admin/i, @{ $dbc->get_local('Access')->{$Current_Department} } ) ) {
        $admin = 1;
    }

    ## Suggested enzymes ##
    $output .= h1('Suggested Enzymes <I>(suggested options based upon Library)</I>');

    #    $output .= &Link_To($homelink,'Add',"&LibraryApplication=1&FK_Library__Name=$library&Object_Class=Enzyme") if $library;
    if ($admin) {
        $output .= create_tree(
            -tree  => { "Suggest New Enzyme" => suggest_Enzyme( -library => $library, -navigator_on => 0 ) },
            -print => 0
        );
    }

    $output .= &Table_retrieve_display(
        $dbc,
        "$tables,Enzyme,LibraryApplication,Object_Class",
        [ 'Library_Name', 'Enzyme_Name' ],
        "$condition AND LibraryApplication.Object_ID=Enzyme_ID AND LibraryApplication.FK_Library__Name=Library_Name AND FK_Object_Class__ID=Object_Class_ID AND Object_Class = 'Enzyme' AND $extra_condition",
        -return_html => 1
    ) if $extra_condition ne '1';

    return $output;
}

#####################
sub suggest_Enzyme {
#####################
    my %args         = &filter_input( \@_ );
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $library      = $args{-library};                                                                 ## already quoted library
    my $object_class = 'Enzyme';
    my $navigator_on = $args{-navigator_on};

    my $condition = "WHERE FK_Project__ID=Project_ID AND LibraryApplication.FK_Library__Name=Library_Name AND LibraryApplication.FK_Object_Class__ID=Object_Class_ID AND Object_Class='Enzyme' AND Object_ID=Enzyme_ID";

    my @lib_list = Cast_List( -list => $library, -to => 'array' ) if $library;

    #    if ($library) {
    #	my $lib_list = Cast_List(-list=>$library,-to=>'string',-autoquote=>1);
    #	$condition .= " AND FK_Library__Name IN ($lib_list)";
    #    }

    #    my @application_values = $dbc->Table_find("Library,Project,LibraryApplication,Object_Class,Enzyme","Enzyme_Name",$condition,-distinct=>1,-debug=>1);

    my @application_values = $dbc->get_FK_info( "FK_Enzyme__ID", -list => 1, -order => 'Enzyme_Name' );
    my %list;
    my %grey;
    $grey{'LibraryApplication.FK_Object_Class__ID'} = $object_class;
    $list{'LibraryApplication.Direction'}           = 'N/A';                  ## &get_enum_list($dbc,'LibraryApplication',"Direction");
    $list{'LibraryApplication.Object_ID'}           = \@application_values;

    if ( $library && ( $library !~ /,/ ) ) {
        $grey{'LibraryApplication.FK_Library__Name'} = $library;
    }
    elsif ($library) {
        $list{'LibraryApplication.FK_Library__Name'} = \@lib_list;
    }

    my $suggest_form = SDB::DB_Form->new( -dbc => $dbc, -table => 'LibraryApplication', -target => 'Database' );
    $suggest_form->configure( -list => \%list, -grey => \%grey );
    return $suggest_form->generate( -title => "Suggest $object_class for Library", -form => 'LibraryApplication', -return_html => 1, -mode => 'Normal', -navigator_on => $navigator_on );
}

return 1;

