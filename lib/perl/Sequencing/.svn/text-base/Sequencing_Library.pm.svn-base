##################################################################################################################
# Sequencing_Library.pm
#
# Brief description
#
# $Id: Sequencing_Library.pm,v 1.25 2004/11/19 00:20:41 echuah Exp $
##################################################################################################################
package Sequencing::Sequencing_Library;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Sequencing_Library.pm - !/usr/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(alDente::Library);

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

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use alDente::Form;
use alDente::SDB_Defaults;
use alDente::Library;
use alDente::Tools;
use alDente::Antibiotic;
use alDente::Primer;
use alDente::Branch;
use SDB::CustomSettings;
use SDB::DBIO;
use alDente::Validation;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Object;

##############################
# global_vars                #
##############################
use vars qw($Current_Department $Connection);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
### Global variables
### Modular variables
# Define security checks (alphabetical order please!)
my %Checks;
$Checks{VECTOR_PRIMER_CHEMISTRY_BOX} = { 'Sequencing' => 'Lab,Admin' };

# Define items that can be viewed(alphabetical order please!)
my %Views;
$Views{'-'} = { 'Sequencing' => 'Lab', 'Mapping' => 'Lab', 'Lib_Construction' => 'Lab' };
$Views{Library} = { 'Sequencing' => 'Lab', 'Mapping' => 'Lab', 'Lib_Construction' => 'Lab' };
$Views{LibraryPrimer}     = { 'Sequencing' => 'Lab' };
$Views{LibraryAntibiotic} = { 'Sequencing' => 'Lab' };
$Views{Vector_TypePrimer} = { 'Sequencing' => 'Lab' };

# Define items that can be searched (alphabetical order please!)
my %Searches;
$Searches{'-'} = { 'Sequencing' => 'Lab', 'Mapping' => 'Lab', 'Lib_Construction' => 'Lab' };
$Searches{Library} = { 'Sequencing' => 'Lab', 'Mapping' => 'Lab', 'Lib_Construction' => 'Lab' };
$Searches{LibraryApplication}    = { 'Sequencing' => 'Lab' };
$Searches{Vector_TypePrimer}     = { 'Sequencing' => 'Lab' };
$Searches{Vector_TypeAntibiotic} = { 'Sequencing' => 'Lab' };

# Define items that can be created (alphabetical order please!)
my %Creates;
$Creates{'-'} = { 'Sequencing' => 'Lab', 'Mapping' => 'Lab', 'Lib_Construction' => 'Lab' };

$Creates{LibraryPrimer}         = { 'Sequencing' => 'Admin' };
$Creates{LibraryAntibiotic}     = { 'Sequencing' => 'Admin' };
$Creates{Vector_TypeAntibiotic} = { 'Sequencing' => 'Admin' };
$Creates{Vector_TypePrimer}     = { 'Sequencing' => 'Admin' };
$Creates{LibraryVector}         = { 'Sequencing' => 'Admin' };

# Define labels (alphabetical order please!)
my %Labels;
%Labels = ( '-' => '--Select--' );
$Labels{Library}               = 'Libraries';
$Labels{LibraryPrimer}         = 'Suggested Library Primers';
$Labels{LibraryAntibiotic}     = 'Suggested Library Antibiotics';
$Labels{Vector_TypePrimer}     = 'Valid Primers (by Vectors)';
$Labels{Vector_TypeAntibiotic} = 'Valid Antibiotics (by Vectors)';
$Labels{LibraryVector}         = 'Valid Vector for Library';
##############################
# constructor                #
##############################

###########################
# Constructor of the object'table'
###########################
sub new {
    my $this = shift;

    my %args    = @_;
    my $dbc     = $args{-dbc} || $Connection;    # Database handle
    my $frozen  = $args{-frozen};
    my $encoded = $args{-encoded};

    my $self = $this->alDente::Library::new( -dbc => $dbc, -tables => [ 'Library', 'Original_Source', 'Vector_Based_Library' ], -frozen => $frozen, -encoded => $encoded );

    my $class = ref($this) || $this;
    bless $self, $class;

    if ($frozen) {
        $self->{dbc} = $dbc;
        return $self;
    }

    return $self;
}

##############################
# public_methods             #
##############################

#######################################
# Get sequencing library types
#######################################
sub get_library_sub_types {
    my $self = shift;
    my $dbc = shift || $self->{dbc} || $Connection;

    my @types = $dbc->get_enum_list( 'Vector_Based_Library', 'Vector_Based_Library_Type' );
    push( @types, 'PCR_Product' );

    return \@types;
}

##########################
# Print the library info
##########################
sub library_info {
##########################
    my $self = shift;

    my $dbc     = $self->{dbc} || $Connection;
    my $lib     = shift;
    my $project = shift;
    my $Ltype   = shift;

    my $homelink = $dbc->homelink();

    my $library_name;
    my %Parameters = Set_Parameters();

    if ( $lib =~ /(.*):(.*)/ ) { $lib = $1; $library_name = $2; }

    print &Views::Heading("Library Info");

#my $condition = "where FK_Project__ID = Project_ID and Library.Library_Name = Vector_Based_Library.FK_Library__Name and LibraryVector.FK_Library__Name = Library_Name and Vector_ID = LibraryVector.FK_Vector__ID AND Vector.FK_Vector_Type__ID=Vector_Type_ID";
    my $condition = "where FK_Project__ID = Project_ID and LibraryVector.FK_Library__Name = Library_Name and Vector_ID = LibraryVector.FK_Vector__ID AND Vector.FK_Vector_Type__ID=Vector_Type_ID";
    print "<span size=small><B>";
    if ($lib) {
        $condition .= " and Library_Name like \"$lib\"";
        print "Library: $lib. ";
    }

    if ($project) {
        $condition .= " and Project_Name like \"$project\"";
        print "Project: $project. ";
    }
    if ($Ltype) {
        $condition .= " and (Vector_Based_Library_Type like \"$Ltype\" OR Library_Type like \"$Ltype\")";
        print "Library Type: $Ltype. ";
    }
    print "</B></span>";

    if ( param('Order by Library') ) {
        $condition .= " Order by Library_Name";
    }
    elsif ( param('Order by Vector') ) {
        $condition .= " Order by LibraryVector.FK_Vector__ID,Library_Name";
    }
    else { $condition .= " Order by Project_Name,Library_Name"; }

    my @headers = ( 'Select', 'Project', 'Type', 'Name', 'Full Name', 'Goals', 'Status', 'Vector', 'Suggested<BR>Primers', 'Antibiotic Marker', 'Transposon Antibiotic', 'Progress' );
    my @field_list = ( 'Project_Name', 'Vector_Based_Library_Type', 'Library_Name', 'Library_FullName', 'Library_Goals as Goals', 'Library_Status as Status', 'Vector_Type_Name as Vector', 'Vector_Type_ID' );
    if ( param('Include Description') ) {
        push( @field_list, "Library_Description as Description" );
        push( @headers,    'Description' );
    }

    #my %Lib_info = $dbc->Table_retrieve('Library,Project,Vector_Based_Library,LibraryVector,Vector,Vector_Type',\@field_list,$condition);
    my %Lib_info = $dbc->Table_retrieve( 'Library,Project LEFT JOIN Vector_Based_Library ON Library.Library_Name = Vector_Based_Library.FK_Library__Name,LibraryVector,Vector,Vector_Type', \@field_list, $condition );

    my $Table = HTML_Table->new();
    $Table->Set_Class('small');
    $Table->Set_Title("List of $project $Ltype Libraries ");
    $Table->Set_Headers( \@headers );

    print start_custom_form( 'LibInfo', undef, \%Parameters );

    # print start_barcode_form(undef,'LibInfo');
    my $index = 0;
    while ( defined $Lib_info{Library_Name}[$index] ) {
        my $proj           = $Lib_info{'Project_Name'}[$index];
        my $type           = $Lib_info{'Vector_Based_Library_Type'}[$index];
        my $name           = $Lib_info{'Library_Name'}[$index];
        my $fname          = $Lib_info{'Library_FullName'}[$index];
        my $vector         = $Lib_info{'Vector'}[$index];
        my $desc           = $Lib_info{'Description'}[$index];
        my $goals          = $Lib_info{'Goals'}[$index];
        my $status         = $Lib_info{'Status'}[$index];
        my $vector_type_id = $Lib_info{'Vector_Type_ID'}[$index];

        #TABLE FIND CALL! Might want to remove pending object-oriented DB_Object_Set
        my %primer_hash = $dbc->Table_retrieve( "Vector_TypePrimer,Vector_Type", ["Vector_TypePrimer_ID"], "where Vector_TypePrimer.FK_Vector_Type__ID = Vector_Type_ID and Vector_Type_Name='$vector'" );

        my $primer_array = $primer_hash{"Vector_TypePrimer_ID"};
        my $count        = 0;
        foreach (@$primer_array) {
            $count++;
        }
        my $primer_qty = $count;

        $index++;

        my $Aproj = $proj;
        $Aproj =~ s/\s/+/g;
        my @fields;
        push( @fields, checkbox( -name => 'Library', -label => '', -value => $name ) );
        push( @fields, &Link_To( $homelink, $proj, "&Info=1&Table=Project&Field=Project_Name&Like=$Aproj", 'blue', ['newwin'] ) );
        push( @fields, $type );
        my ($runs) = $dbc->Table_find( 'Run', 'count(*)', "where Run_Directory like '$name%'" );
        my $library_link = &Link_To( $homelink, $name, "&Search=1&TableName=Library&Search+List=$name", 'blue', ['newwin'] ) . '<BR>'
            . &Link_To( $homelink, "(view_$runs" . "_runs)", "&Last+24+Hours=1&Library_Name=$name&Run+Department=Cap_Seq&Any+Date=1", 'red', ['newwin'] );
        push( @fields, $library_link );
        push( @fields, $fname );

        push( @fields, $goals );
        push( @fields, $status );

        my $show_vector = &Link_To( $homelink, $dbc->get_FK_info( 'Vector_ID', $vector ), "&Info=1&Table=Vector_Type&Field=Vector_Type_Name&Like=$vector", 'blue', ['newwin'] ) . '<BR>'
            . &Link_To( $homelink, "($primer_qty primers)", "&Info=1&Table=Vector_TypePrimer&Field=FK_Vector_Type__ID&Like=$vector_type_id", 'red', ['newwin'] );
        push( @fields, $show_vector );

        my $primers = join '<LI>', $dbc->Table_find( 'LibraryApplication,Object_Class,Primer', 'Primer_Name', "where FK_Library__Name like '$name' and FK_Object_Class__ID = Object_Class_ID AND Object_ID=Primer_ID and Object_Class = 'Primer'" );
        $primers ||= '-';

        my $antibiotics = join '<BR>',
            $dbc->Table_find( 'LibraryApplication,Object_Class,Antibiotic', 'Antibiotic_Name', "where FK_Library__Name like '$name' and FK_Object_Class__ID = Object_Class_ID AND Object_ID=Antibiotic_ID and Object_Class = 'Antibiotic'" );

        $antibiotics ||= '-';

        my $Tantibiotics = join '<BR>',
            $dbc->Table_find( 'Vector_Based_Library,Pool,Transposon,Transposon_Pool,Library_Source', 'Antibiotic_Marker',
            "where Pool_ID=FK_Pool__ID AND Transposon_Pool.FK_Source__ID=Library_Source.FK_Source__ID AND FK_Transposon__ID=Transposon_ID and Library_Source.FK_Library__Name=Vector_Based_Library.FK_Library__Name and Vector_Based_Library.FK_Library__Name like '$name'"
            );
        $Tantibiotics ||= '-';

        my $newprimer = &Link_To( $homelink, '(add to list)', "&LibraryApplication=1&Object_Class=Primer&FK_Library__Name=$name", 'red', ['newwin'] );

        push( @fields, "<UL><LI>$primers</UL>$newprimer" );
        push( @fields, $antibiotics );
        push( @fields, $Tantibiotics );

        my ($now) = split ' ', &RGTools::RGIO::date_time();
        my $linkProgress = &Link_To( $homelink, 'View_to-date', "&Info=1&Table=LibraryProgress&Field=FK_Library__Name&Like=$name", 'blue', ['newwin'] ) . "<BR>"
            . &Link_To( $homelink, 'Add_Note', "&New+Entry=New+LibraryProgress&FK_Library__Name=$name&LibraryProgress_Date=$now", 'red', ['newwin'] );
        push( @fields, $linkProgress );

        $Table->Set_Row( \@fields );
    }
    print $Table->Printout("$URL_temp_dir/Libraries.html");
    $Table->Printout();

    print submit( -name => 'Generate Fasta File for Library', -class => "Action" ), br(), checkbox( -name => 'Include Poor Quality', -checked => 0, -force => 1 ), checkbox( -name => 'Include Vector', -checked => 0, -force => 1 ), br(),
        checkbox( -name => 'Include Test Runs', -checked => 0, -force => 1 ), "\n</FORM>";

    return 1;
}

#########
# HTML generator pages - might be worthwhile to transfer to a perl script to be more object-oriented
# However, might want to include for historical/reverse compatability with other scripts
#########
#
# output HTML for main library page
#
###################
sub library_main {
###################
    my $self        = shift;
    my %args        = &filter_input( \@_, -args => 'dbc' );
    my $dbc         = $args{-dbc} || $self->{dbc} || $Connection;
    my $get_layers  = $args{-get_layers};
    my $form_name   = $args{-form_name};
    my $return_html = $args{-return_html};

    # Set security checks
    $dbc->config("Security")->security_checks( \%Checks );

    my $admin = 0;
    if ( grep( /Admin/i, @{ $dbc->get_local('Access')->{ $dbc->config('Target_Department') } } ) ) {
        $admin = 1;
    }

    ##################################################################
    ### Customized for Sequencing Libraries:
    ##################################################################
    my $sub_types = $self->get_library_sub_types();

    ## Check for Sequencing specific branches ##
    my $project = get_Table_Param( -field => 'Project_Name', -table => 'Project', -autoquote => 1, -dbc => $dbc );
    my $library = get_Table_Param( -field => 'Library_Name', -table => 'Library', -autoquote => 1, -dbc => $dbc );
    my $type    = get_Table_Param( -field => 'Library_Type', -table => 'Library', -autoquote => 1, -dbc => $dbc );
    if ($library) { }
    elsif ($type) {
        $library = join ',', $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Type like '$type'" );
    }
    elsif ($project) {
        $library = join ',', $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID AND Project_Name like '$project'" );
    }

    if ( param('List Vectors') ) {
        print &alDente::Vector::list_Vectors(
             $dbc,
            -project => $project,
            -library => $library,
            -type    => $type
        );
        return 1;
    }    ### catch validate primer option ###
    elsif ( param('New Valid Primers') ) {
        print &alDente::Primer::list_Primers(
             $dbc,
            -project => $project,
            -library => $library,
            -type    => $type
        );
        return 1;
    }    ### catch validate antibiotics option ###
    elsif ( param('New Valid Antibiotics') ) {
        print &alDente::Antibiotic::list_Antibiotics(
             $dbc,
            -project => $project,
            -library => $library,
            -type    => $type
        );
        return 1;
    }
    elsif ( param('New Valid Branch Codes') ) {
        my %layers;
        $layers{Primer} = &alDente::Branch::list_Branch_Codes(
             $dbc,
            -project          => $project,
            -library          => $library,
            -library_sub_type => $type,
            -library_type     => 'Vector_Based_Library',
            -class            => 'Primer'
        );
        $layers{Enzyme} = &alDente::Branch::list_Branch_Codes(
             $dbc,
            -project          => $project,
            -library          => $library,
            -library_sub_type => $type,
            -library_type     => 'Vector_Based_Library',
            -class            => 'Enzyme'
        );
        print &define_Layers( -layers => \%layers, -format => 'tab' );
        return 1;
    }

    ## Continue to generic library_main page ##
    my $add_link = [ &Link_To( $dbc->homelink(), "Search Vector/String for Restriction Site / Primer", "&Search+Vector=1", $Settings{LINK_COLOUR}, ['newwin1'] ) ];
    my @add_views_list = ();
    if ($admin) {
        @add_views_list = (
            Show_Tool_Tip(
                submit(
                    -name  => 'New Valid Primers',
                    -label => 'Valid/Suggested Primers',
                    -class => 'Std'
                ),
                "Associated to Vector or Library"
            ),
            Show_Tool_Tip(
                submit(
                    -name  => 'New Valid Antibiotics',
                    -label => 'Valid/Suggested Antibiotics',
                    -class => 'Std'
                ),
                "Associated to Vector"
            ),
            Show_Tool_Tip(
                submit(
                    -name  => 'New Valid Branch Codes',
                    -label => 'Branch Codes',
                    -class => 'Std'
                ),
                "Associated to Primer"
            )
        );
    }
    my @add_objects = ( 'Primer', 'Enzyme', 'Antibiotic', 'Vector_TypePrimer', 'Vector_TypeAntibiotic', 'Vector_Type', 'LibraryVector' );

    #my @view_objects =('Library');
    my @view_objects = ();

    return $self->SUPER::library_main(
        -dbc          => $dbc,
        -add_links    => $add_link,
        -sub_types    => $sub_types,
        -objects      => \@add_objects,
        -view_objects => \@view_objects,
        -labels       => {
            'Vector_TypePrimer'     => 'Valid Primer',
            'Vector_TypeAntibiotic' => 'Valid Antibiotic',
            'LibraryVector'         => 'Library - Vector Association',
            'Vector_Type'           => 'Vector',
        },
        -get_layers  => $get_layers,
        -form_name   => $form_name,
        -return_html => $return_html,
        -add_views   => \@add_views_list
    );
}

################################
# Get typical library info
# Returns a hash of library info
################################
sub get_library_info {
########################
    my $self = shift;
    my %args = @_;

    my $name = $args{-name};
    my $fields = $args{-fields} || [ 'Library_Name', 'Library_Source', 'Library_Description', 'Library_Obtained_Date', 'Taxonomy_Name' ];

    my %info;

    my %values = %{ $self->SUPER::retrieve( -condition => "Library.Library_Name='$name'" ) };
    $fields = Cast_List( -list => $fields, -to => 'arrayref' );

    @info{@$fields} = @values{ ( 'Library.Library_Name', 'Library.Library_Source', 'Library.Library_Description', 'Library.Library_Obtained_Date', 'Taxonomy.Taxonomy_Name' ) };

    return \%info;
}

##############################
# public_functions           #
##############################
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

$Id: Sequencing_Library.pm,v 1.25 2004/11/19 00:20:41 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
