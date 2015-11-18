#!/usr/bin/perl
###################################################################################################################################
# LibraryApplication.pm
#
###################################################################################################################################
package alDente::LibraryApplication;

@ISA = qw(SDB::DB_Object);
use strict;
use Data::Dumper;
use SDB::CustomSettings;
use alDente::Primer;
use alDente::Antibiotic;
use alDente::Enzyme;

###################
# Database Mddules
###################
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;
use SDB::HTML;
###################
# Helper Modules
###################
use RGTools::RGIO;

##########
sub new {
##########
    my $this    = shift;
    my $class   = ref($this) || $this;
    my %args    = filter_input( \@_ );
    my $id      = $args{-id};
    my $library = $args{-library};
    ## Create a LibaryApplication database object
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $tables = 'Library,LibraryApplication';

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => $tables );
    if ($id) {
        $self->{id} = $id;
        $self->primary_value( -table => 'LibraryApplication', -value => $id );
        $self->load_Object();
    }
    elsif ($library) {
        $self->{library} = $library;
        $self->primary_value( -table => 'Library', -value => $library );
        $self->load_Object();
    }

    $self->{dbc}     = $dbc;
    $self->{records} = 0;
    bless $self, $class;
    return $self;
}
#################
# Home page allows the user to view current suggested and valid applications (ie Primers, Antibiotics)
#
# Return 1 on success;
#################
sub home_page {
#################
    my $self = shift;
    my %args = filter_input(
        \@_,
        -args => 'library,object_class,valid_object,filter_table',

        # -mandatory=>'library,object_class'
    );
    my $library = $args{-library};                          ## Library Name
    my $object_class = $args{-object_class} || 'Primer';    ## Type of object ie Antibiotic, Primer, Enzyme

    my $valid_object = $args{-valid_object};                ## Type of object to filter the suggested values on, ie Vector
    my $filter_table = $args{-filter_table};                ## || "$valid_object$object_class";

    my $dbc = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id = $self->{id};
    if ($id) {
        ($library) = $dbc->Table_find( 'LibraryApplication', 'FK_Library__Name', "WHERE LibraryApplication_ID=$id" );
    }
    if ( $object_class =~ /primer/i ) {
        print &alDente::Primer::list_Primers(
            -dbc     => $dbc,
            -library => $library
        );
    }
    elsif ( $object_class =~ /antibiotic/i ) {
        print &alDente::Antibiotic::list_Antibiotics(
            -dbc     => $dbc,
            -library => $library
        );
    }
    elsif ( $object_class =~ /enzyme/i ) {
        print &alDente::Enzyme::list_Enzymes(
            -dbc     => $dbc,
            -library => $library
        );
    }
    return 1;    ## <CONSTRUCTION>...

### The connection through vector below is too complicated and should be handled separately <CONSTRUCTION>...
##  some of validation and suggested primer specification options are already available within the Primer.pm module (see alDente::Primer::list_Primers or alDente::Primer::suggest_Primer..)

    my $fk_object_class_id = $dbc->get_FK_ID( "FK_Object_Class__ID", $object_class );

    my $object_id   = $object_class . "_ID";      ## ie Antibiotic_ID
    my $object_name = $object_class . "_Name";    ## Antibiotic_Name

    ### list the current suggested object names for the given library
    print &Views::sub_Heading("Current Suggestions for $library Library");

    my $object_condition = " AND FK_Object_Class__ID = $fk_object_class_id" if $fk_object_class_id;
    &Table_retrieve_display( $dbc, "LibraryApplication", [ "FK_Library__Name as Library", "FK_Object_Class__ID as Type", "Object_ID as Name", "Direction" ], "where FK_Library__Name in ('$library') $object_condition" );

    ### get the available objects for the given library based on the valid object
    my %valid_objects = ();
    my @application_values;

    my $valid_library_join = "Library$valid_object";

    my $fk_valid_id = SDB::DBIO::_get_FK_name( $dbc, $valid_library_join, $valid_object, "$valid_object" . "_ID" );

    my $fk_object_class_field = "FK_" . $object_class . "__ID";

    my @valid_library_values;
    my $tables    = "$valid_library_join,$object_class";
    my $condition = "WHERE $object_id = $fk_object_class_field and FK_Library__Name in ('$library')";

    my $filter_condition = '';
    if ($filter_table) {
        $filter_condition = " AND $valid_library_join.$fk_valid_id = $filter_table.$fk_valid_id";
        $condition .= $filter_condition;
        $tables    .= ", $filter_table";
    }
    $condition .= " ORDER BY $object_name";

    print &Views::sub_Heading("Valid $object_class(s) available for $library Library");

    %valid_objects = &Table_retrieve( $dbc, $tables, [ "$valid_library_join.$fk_valid_id as $fk_valid_id", "$fk_object_class_field as $object_class", "$object_name as Name" ], $condition ) if $fk_valid_id;

    my $valid_table   = HTML_Table->new();
    my @valid_headers = ($valid_object);
    push( @valid_headers, $object_class ) unless grep /$object_class/, @valid_headers;
    $valid_table->Set_Headers( \@valid_headers );

    my $index = 0;
    while ( defined $valid_objects{$fk_valid_id}[$index] ) {
        push( @application_values, $valid_objects{Name}[$index] );
        my $valid_field_value = get_FK_info( $dbc, $fk_valid_id, $valid_objects{$fk_valid_id}[$index] );
        push( @valid_library_values, $valid_field_value ) unless grep /$valid_field_value/, @valid_library_values;
        $valid_table->Set_Row( [ $valid_field_value, $valid_objects{Name}[$index] ] );
        $index++;
    }
    $valid_table->Printout();

    my %list;
    my %grey;
    $grey{'LibraryApplication.FK_Object_Class__ID'} = $object_class;
    $list{'LibraryApplication.Direction'}           = &get_enum_list( $dbc, 'LibraryApplication', "Direction" );
    $list{'LibraryApplication.Object_ID'}           = \@application_values;
    $grey{'LibraryApplication.FK_Library__Name'}    = $library;
    my $suggest_form = SDB::DB_Form->new( -dbc => $dbc, -table => 'LibraryApplication', -target => 'Database' );
    $suggest_form->configure( -list => \%list, -grey => \%grey );
    $suggest_form->generate( -title => "Suggest $object_class for Library", -form => 'LibraryApplication' );

    unless ($filter_table) {
        $filter_table = $valid_library_join;
    }
    ## reinitialize DB Form variables
    my $valid_form = SDB::DB_Form->new( -dbc => $dbc, -table => $filter_table, -target => 'Database' );

    #print HTML_Dump \@valid_library_values;
    $list{$fk_valid_id} = \@valid_library_values;

    #my @valid_list = $dbc->Table_find( $tables, "$object_name", "WHERE $fk_object_class_field = $object_id $filter_condition ORDER BY $object_name",-distinct=>1);
    $grey{"$filter_table.FK_Library__Name"} = $library;

    #$list{$fk_object_class_field} = \@valid_list;
    $valid_form->configure( -list => \%list, -grey => \%grey );
    $valid_form->generate( -title => "Valid $object_class for Library", -form => $valid_library_join );

    ### for each of the valid objects, find the list of available object names
    # DB_Form
    return 1;
}

##############################
# Validate different types of reagents ie Primers, Enzymes, Antibiotics, Vectors
#
# Return 1 on success
##############################
sub validate_application {
##############################
    my $self         = shift;
    my %args         = filter_input( \@_, -args => 'library,object_class,value,valid_values' );
    my $dbc          = $self->{dbc};
    my $library      = $args{-library} || $self->{library};                                       ## Library Name
    my $object_class = $args{-object_class};                                                      ## Type of object ie Antibiotic, Primer, Enzyme
    $library = Cast_List( -list => $library, -to => 'String', -autoquote => 1 );

    ## Get the name of the object type
    my $object_class_id = get_FK_ID( $dbc, 'FK_Object_Class__ID', $object_class );
    my @values;
    if ( $args{-value} ) {
        @values = Cast_List( -list => $args{-value}, -to => 'array' );                            ## value to test against
    }
    else {
        ### Nothing to check for...
        return 1;
    }

    my $valid_values_ref = $args{-valid_values};                                                  ## valid values (optional, usually not necessary).

    my $fk_object_class_field = "FK_" . $object_class . "__ID";
    ## Find all the valid values associated with the library and the object_class
    my @valid_values;
    if ($valid_values_ref) {
        @valid_values = @{$valid_values_ref};
    }
    else {
        my @libs = split( ',', $library );
        my $lib_count = scalar(@libs);
        ## Ensure that ALL current libraries have the same valid reagent. ###
        @valid_values = $dbc->Table_find( "LibraryApplication,$object_class", "${object_class}_Name",
            "WHERE FK_Library__Name IN ($library) and FK_Object_Class__ID = $object_class_id AND Object_ID=${object_class}_ID GROUP BY Object_ID having count(*) >= $lib_count" );

        $self->{valid_values} = \@valid_values;
    }

    my $ok = 1;
    foreach my $value (@values) {
        unless ( grep /^\Q$value\E$/, @valid_values ) {
            $ok = 0;
            last;
        }
    }

    return $ok;
}
#########################
# View Library Application information
# Return: HTML table
#########################
sub view_application {
#########################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'library,object_class,value', -mandatory => 'library' );
    if ( $args{ERRORS} ) { return 0; }
    my $dbc = $self->{dbc};

    ## <CONSTRUCTION> - add option to supply project or library type...
    my $library = $args{-library};
    $library = Cast_List( -list => $library, -to => 'String', -autoquote => 1 );

    my $object_class = $args{-object_class};
    my $condition = $args{-condition} || 1;

    my $object_class_id = get_FK_ID( $dbc, 'FK_Object_Class__ID', $object_class );
    $object_class_id ||= join ',', $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = '$object_class'" );

    if ($library) { $condition .= " AND FK_Library__Name in ($library)"; }
    if ($object_class) {
        $condition .= " AND FK_Object_Class__ID IN ($object_class_id)";
    }
    $condition .= " AND FK_Object_Class__ID=Object_Class_ID";

    my %library_application = $dbc->Table_retrieve( "LibraryApplication,Object_Class", [ "FK_Library__Name as Library", "Object_Class As Type", "Object_ID as ID", "Direction" ], "WHERE $condition" );

    my $lib_app_table = HTML_Table->new( -title => 'List Associated Reagents' );
    $lib_app_table->Set_Headers( [ 'Library', 'Type', 'Name', 'Direction' ] );
    my $index = 0;
    while ( defined $library_application{ID}[$index] ) {
        my $id   = $library_application{ID}[$index];
        my $type = $library_application{Type}[$index];
        my $name = $dbc->get_FK_info( -field => "FK_$type" . "__ID", -id => $id );
        my $lib  = $library_application{Library}[$index];

        my $direction = $library_application{Direction}[$index];
        $lib_app_table->Set_Row( [ $lib, $type, $name, $direction ] );
        $index++;
    }

    return $lib_app_table->Printout();
}

