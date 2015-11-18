#!/usr/bin/perl
#############################################################################################################
# Transposon_Pool.pm
#
# Transposon pooling
#
# $Id: Transposon_Pool.pm,v 1.11 2004/11/08 23:10:23 echuah Exp $
#############################################################################################################
package alDente::Transposon_Pool;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Transposon_Pool.pm - !/usr/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

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
use CGI qw(:standard);
use DBI;
use Data::Dumper;

#use Storable;

use strict;
##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use alDente::SDB_Defaults;
use alDente::Form;
use alDente::Tools;

#use alDente::Library_Pool;

use SDB::CustomSettings;
use SDB::DBIO;
use alDente::Validation;

use RGTools::RGIO;
use RGTools::Conversion;
use SDB::HTML;
use SDB::DB_Object;
##############################
# global_vars                #
##############################

use vars qw($Connection $testing $Sess);
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

########
sub new {
########
    #
    # Constructor
    #
    my $this = shift;
    my %args = @_;

    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $id      = $args{-id};
    my $encoded = $args{-encoded} || 0;                                                             ## reference to encoded object (frozen)

    my ($class) = ref($this) || $this;

    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => 'Pool', -encoded => $encoded );

    bless $self, $class;

    $self->add_tables('Transposon_Pool');

    if ($id) {
        $self->{id} = $id;                                                                          ## list of current plate_ids
        $self->primary_value( -table => 'Pool', -value => $id );                                    ## same thing as above..
        $self->load_Object();
    }

    return $self;
}

##############################
# public_methods             #
##############################

##############################################
# Standard Transposon Pool information display
#
#
#
#############
sub home_page {
#############
    #
    # Simple home page for Library_Plate (when id is defined).
    #
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'brief' );
    my $dbc  = $self->{dbc};

    my $brief = $args{-brief};

    print "<Table cellpadding=0 width=100%><TR>";

    # extract pool ID and source ID that was associated with the transposon pool
    my $pool_id   = $self->value('Pool.Pool_ID');
    my $source_id = $self->value('Transposon_Pool.FK_Source__ID');

    my ($pooled_library) = $dbc->Table_find( "Library_Source", "FK_Library__Name", "WHERE FK_Source__ID=$source_id" );

    # display transposon pool ID and library
    print h2("Transposon Pool $pool_id");
    print h3("Pooled into library $pooled_library (Source $source_id)");

    ## Display information regarding the wells adn plates that have been pooled
    print "<TD valign='top'>";
    my $info_table = new HTML_Table();

    $info_table->Set_Title("Source Plates for Pool $pool_id");
    $info_table->Set_Headers( [ 'Plate ID', 'Well' ] );

    # extract the source plate and well that went into this pool
    my @poolinfo = $dbc->Table_find( "PoolSample", "FK_Plate__ID,Well", "WHERE FK_Pool__ID=$pool_id" );
    foreach my $row (@poolinfo) {
        my ( $plate_id, $well ) = split ',', $row;
        my $plate_name = &get_FK_info( $dbc, "Plate_ID", "$plate_id" );
        $info_table->Set_Row( [ $plate_name, $well ] );
    }

    # print out table
    print $info_table->Printout("$alDente::SDB_Defaults::URL_temp_dir/PoolSpec@{[timestamp()]}.html");
    $info_table->Printout();

    print "</TD>";
    print "<TD valign='top'>";
    ## print out general information at the right hand side of the screen ##
    unless ($brief) {
        print $self->display_Record( -tables => [ 'Pool', 'Transposon_Pool' ], -truncate => 40 );
    }

    print "</TD></TR></Table>";
    return 1;
}

###########################
# Create pool (DEPRECATED)
### Currently not being used ###
###########################
sub create {
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};

    my $transposon     = $args{-transposon};
    my $OD_id          = $args{-OD_id};
    my $gel_id         = $args{-gel_id};
    my $reads_required = $args{-reads_required};
    my $pipeline       = $args{-pipeline};

    # Check FK values
    my $transposon_id = $dbc->Table_find( "Transposon", 'Transposon_ID', "WHERE Transposon_Name = '$transposon'" );

    push( @{ $self->{errors} }, "Transposon.Transposon_Name = '$transposon' not found in database." ) unless ( $transposon_id =~ /[1-9]/ );

    push( @{ $self->{errors} }, "Optical_Density.Optical_Density_ID = $OD_id not found in database." ) if ( $OD_id && !$dbc->Table_find( 'Optical_Density', 'Optical_Density_ID', "WHERE Optical_Density_ID=$OD_id" ) );
    push( @{ $self->{errors} }, "GelRun.GelRun_ID = $gel_id not found in database." ) if ( $gel_id && !$dbc->Table_find( 'GelRun', 'GelRun_ID', "WHERE GelRun_ID=$gel_id" ) );

    # Check enum values;
    my @enum_list;
    if ($pipeline) {
        @enum_list = &get_enum_list( $self->{dbc}, 'Transposon_Pool', 'Pipeline' );
        local $" = ",";
        push( @{ $self->{errors} }, "'$pipeline' is not a valid enum value for Transposon_Pool.Pipeline. Valid values are: @enum_list." ) unless ( grep /^$pipeline$/, @enum_list );
    }

    # Set values for the Transposon_Pool table
    $self->values(
        -fields => [ 'Transposon_Pool.FK_Transposon__ID', 'Transposon_Pool.FK_Optical_Density__ID', 'Transposon_Pool.FK_GelRun__ID', 'Transposon_Pool.Reads_Required', 'Transposon_Pool.Pipeline' ],
        -values => [ $transposon_id,                      $OD_id,                                   $gel_id,                         $reads_required,                  $pipeline ]
    );

    return $self->SUPER::create(%args);
}

#######################
# Subroutine: prompts for information on creating a transposon pool
#######################
sub prompt_create_transposon_pool {
#######################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $plate_ids = $args{-plate_ids};
    my $newlib    = $args{-new_library};
    my $dbc       = $self->{dbc};

    my @plate_ids = split ',', $plate_ids;
    my $form_name = 'PromptTransposonPool';

    my $library_str   = '';
    my $validator_str = '';

    my $library_table = new HTML_Table();
    $library_table->Set_Title("Transposon Pooling Details");

    ## If the new library flag is set, then prompt the user for new library information
    if ($newlib) {
        my %grey;
        my %hidden;
        my %preset;

        # extract original source of the library that the source plate/s came from
        # use this for the original source of the library that will be created
        my ($ors_id) = $dbc->Table_find( "Library,Plate", "FK_Original_Source__ID", "WHERE FK_Library__Name=Library_Name AND Plate_ID = $plate_ids[0]" );

        # set fields that are known or don't need to be prompted for
        $hidden{'FK_Library__Name'}            = "<Library.Library_Name>";
        $hidden{'Library_Status'}              = 'In Production';
        $hidden{'FK_Grp__ID'}                  = 2;
        $hidden{'FK_Original_Source__ID'}      = $ors_id;
        $hidden{'Library_URL'}                 = '';
        $hidden{'Library_Type'}                = "Vector_Based";
        $hidden{'Starting_Plate_Number'}       = 1;
        $hidden{'Source_In_House'}             = 'Yes';
        $hidden{'Vector_Based_Library_Type'}   = 'Transposon';
        $hidden{'Colonies_Screened'}           = '';
        $hidden{'Clones_NoInsert_Percent'}     = '';
        $hidden{'Source_RNA_DNA'}              = '';
        $hidden{'FK_Vector_Based_Library__ID'} = "<Vector_Based_Library.Vector_Based_Library_ID>";
        $hidden{'FK_Pool__ID'}                 = '';

        # create DB_Form tables for Library, Vector_Based_Library, and Transposon Library.
        my $libform = SDB::DB_Form->new( -dbc => $dbc, -form_name => $form_name, -table => 'Library', -target => 'Database', -quiet => 1, -wrap => 0, -start_form => 0, -end_form => 0 );
        $libform->configure();
        my $seqlibform = SDB::DB_Form->new( -dbc => $dbc, -form_name => $form_name, -table => 'Vector_Based_Library', -target => 'Database', -quiet => 1, -wrap => 0, -start_form => 0, -end_form => 0 );
        $seqlibform->configure();

        my $xposonform = SDB::DB_Form->new( -dbc => $dbc, -form_name => $form_name, -table => 'Transposon_Library', -target => 'Database', -quiet => 1, -wrap => 0, -start_form => 0, -end_form => 0 );
        $xposonform->configure();

        my $libraryvector = SDB::DB_Form->new( -dbc => $dbc, -form_name => $form_name, -table => 'LibraryVector', -target => 'Database', -quiet => 1, -wrap => 0, -start_form => 0, -end_form => 0 );
        $libraryvector->configure();

        my %db_form_args = ( -print => 0, -grey => \%grey, -omit => \%hidden, -preset => \%preset, -freeze => 0, -submit => 0 );

        # generate concatenated DB_Form
        my $libtable = new HTML_Table();
        $libtable->Set_Border('on');
        $libtable->Set_Column( [ $libform->generate(%db_form_args)->Printout(0), $seqlibform->generate(%db_form_args)->Printout(0), $xposonform->generate(%db_form_args)->Printout(0), $libraryvector->generate(%db_form_args)->Printout(0) ] );
        $library_str = $libtable->Printout(0);
        $library_str .= hidden( -name => 'HasForm', -value => 1 );
    }
    else {
        ## Don't need to create a transposon library, but we still need to prompt for transposon, and the library that it will be associated to
        # prompt for transposon library parameters
        my @transposons = $dbc->Table_find( "Transposon", "Transposon_Name" );
        $library_table->Set_Row( [ 'Library Name', alDente::Tools->search_list( -dbc => $dbc, -form => $form_name, -name => 'Library_Name', -default => '', -search => 1, -filter => 1, -breaks => 1, -options => \@libraries ) ] );
        $library_table->Set_Row( [ 'Transposon', popup_menu( -name => 'Transposon', -values => \@transposons ) ] );
    }
    ## prompt for generic transposon pool information
    $library_table->Set_Row( [ 'Pool Description', textarea( -name => 'Pool_Description', -row => 5, -col => 10 ) ] );
    $library_table->Set_Row( [ 'Pool Comments',    textarea( -name => 'Pool_Comments',    -row => 5, -col => 10 ) ] );
    $library_table->Set_Row( [ 'Reads Required', textfield( -name => 'Reads_Required' ) ] );
    $library_table->Set_Row( [ 'Pipeline', popup_menu( -name => 'Transposon_Pipeline', -values => [ 'Standard', 'Gateway', 'PCR/Gateway (pGATE)' ] ) ] );
    $library_str .= $library_table->Printout(0);

    my $well_table = new HTML_Table( -add_empty_cells => 0 );
    $well_table->Set_Title('Set Wells to Pool');

    # ask for wells for each plate scanned in
    my %wellwindows;
    my $rowcount = 1;
    ## for each plate, prompt for the wells that will be pooled
    foreach my $plate_id (@plate_ids) {
        my $platename = &get_FK_info( $dbc, "Plate_ID", $plate_id );
        my $wellwindow = &alDente::Tools::show_well_table( -plate_id => $plate_id, -form => 0, -dbc => $dbc );
        $well_table->Set_Row( [ "$platename", textfield( -name => "WellsForPlate${plate_id}", -id => "WellsForPlate${plate_id}", -readonly => 1 ) ] );
        $well_table->Set_Row( [ &SDB::HTML::create_collapsible_link( -linkname => 'Assign Wells', -html => $wellwindow ) ] );

        # this is to make sure the well window spans the whole well_table table
        $well_table->Set_Cell_Spec( $rowcount + 1, 1, "colspan='2'" );
        $rowcount = $rowcount + 2;

        # this is to make sure that at least one well is filled in
        $validator_str .= "<validator name='WellsForPlate${plate_id}' format='' mandatory='1'> </validator>\n";
    }

    # print out tables
    my $str = alDente::Form::start_alDente_form( $dbc, $form_name );
    $str .= $validator_str;
    $str .= $well_table->Printout(0);
    $str .= br();
    $str .= $library_str;
    $str .= submit( -name => 'Create Transposon Pool', -style => "background-color:red", -onClick => 'return validateForm(this.form)' );
    $str .= "\n" . hidden( -name => "Platelist", -value => $plate_ids );

    $str .= "</FORM>";
    return $str;
}

#######################
# Function: creates a Transposon_Pool library.
# Return: a Pool_ID for the transposon pool.
#
###################
sub create_transposon_pool {
################
    my $self = shift;
    my %args = &filter_input( \@_ );
    ## Mandatory fields ###
    my $name     = $args{-name};         # Library name to be used for new pool (5 characters - unique)
    my $fullname = $args{-full_name};    # brief but descriptive name for this library (unique)
    my $plates   = $args{-plate_id};     # single plate or array
    my $wells    = $args{-wells};        # array of wells
    my $qty      = $args{-quantity};
    my $units    = $args{-units};

    ## Optional fields ###
    my $description      = $args{-description}      || '';
    my $pool_description = $args{-pool_description} || '';
    my $status           = $args{-status};
    my $comments         = $args{-comments};
    my $goals            = $args{-goals}            || '';
    my $insert_size_avg  = $args{-insert_size_avg}  || 0;
    my $insert_size_min  = $args{-insert_min}       || 0;
    my $insert_size_max  = $args{-insert_max}       || 0;
    my $test_status      = $args{-test_status};

    ### For Transposon Pools Only (Mandatory) ###
    my $transposon = $args{-transposon};
    my $append     = $args{-append};       ## append pool to existing Library

    my $gel_id            = $args{-gel_id};              ## may specify single gel id if only one plate used
    my $reads_required    = $args{-reads_required};      ## number of reads required for this pool (-> Library Goal)
    my $pipeline          = $args{-pipeline};            ## Standard or Gateway
    my $emp               = $args{-emp};                 ## Name of employee who created the library
    my $contact_id        = $args{-contact_id};
    my $library_form_data = $args{-library_form_data};
    my $quiet             = $args{-quiet};               ## quiet mode (preferable to NOT use this - check feedback if possible)
    my $dbc               = $self->{dbc};

    ## ERROR CHECK ##

    # get employee ID
    my $emp_id;

    if ( $emp =~ /^\d+$/ ) {
        $emp_id = $emp;
    }
    else {
        ($emp_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name='$emp'" );
        unless ($emp_id) {
            $dbc->error("Employee name provided ($emp) invalid.");
        }
    }
    if ($library_form_data) {
        $name = $library_form_data->{tables}{Library}{1}{Library_Name};
    }

    # get transposon ID
    my $transposon_id = 0;
    if ($library_form_data) {
        $transposon_id = $library_form_data->{tables}{Transposon_Library}{1}{FK_Transposon__ID};
    }
    else {
        ($transposon_id) = $dbc->Table_find( "Transposon", "Transposon_ID", "WHERE Transposon_Name='$transposon'" );
    }
    unless ($transposon_id) {
        $dbc->error("ERROR: Transposon name provided ($transposon) invalid");
    }

    # check if wells and plates have the same size
    unless ( scalar( @{$plates} ) == scalar( @{$wells} ) ) {
        $dbc->error("ERROR: Number of plates do not match number of wells.");
    }

    # check if wells and quantities have the same size
    unless ( scalar( @{$qty} ) == scalar( @{$wells} ) ) {
        $dbc->error("ERROR: Number of quantity elements do not match number of wells.");
    }

    # check if wells and units have the same size
    unless ( scalar( @{$units} ) == scalar( @{$wells} ) ) {
        $dbc->error("ERROR: Number of unit elements do not match number of wells.");
    }

    my @sample_ids = ();
    {
        my $index = 0;

        # find sample ID of all wells
        foreach my $plate_id ( @{$plates} ) {
            my $well = $wells->[$index];
            my %ancestry = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_id, -well => $well );
            unless ( exists $ancestry{sample_id} ) {
                $dbc->error("ERROR: sample ID could not be found for pla$plate_id:$well");
                last;
            }
            push( @sample_ids, $ancestry{sample_id} );
            $index++;
        }
    }

    ## check for existence of library ##
    my ($found) = $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Name = '$name'" );
    if ( $found && !$append ) {
        $dbc->error("Error: $name already exists - use append switch to enable addition to existing Library/Collection");
    }

    # figure out restriction sites, organism, sex, strain, and tissue from the original libraries
    my @source_libraries = $dbc->Table_find( "Plate", "FK_Library__Name", "WHERE Plate_ID in (" . join( ',', @{$plates} ) . ")" );

    # make sure restriction sites/organism/sex/strain/tissue are all the same. Return an error if it is not
    my $source_lib_str = &autoquote_string( join( ',', @source_libraries ) );
    my %libinfo = &Table_retrieve(
        $dbc,
        "Original_Source,Library,Vector_Based_Library,Taxonomy,Anatomic_Site",
        [ "FK3Prime_Enzyme__ID", "FK5Prime_Enzyme__ID", "Original_Source_ID", "Taxonomy_Name as Organism", "Original_Source.Sex", "Original_Source.FK_Strain__ID", "Anatomic_Site.Anatomic_Site_Alias as Anatomic_Site" ],
        "WHERE FK_Original_Source__ID=Original_Source_ID AND FK_Taxonomy__ID=Taxonomy_ID AND FK_Anatomic_Site__ID=Anatomic_Site_ID AND FK_Library__Name=Library_Name AND Library_Name in ($source_lib_str)"
    );

    # check uniqueness of all elements by passing it through unique_items
    # if it has only one item left, it passes
    # if it doesn't, error out
    foreach my $key ( keys %libinfo ) {
        my $info_ref = &unique_items( $libinfo{$key} );
        if ( int( @{$info_ref} ) > 1 ) {
            $dbc->error("ERROR: There should only be one source library");
        }
    }

    if ( ( !$append ) && ( !$library_form_data ) ) {
        $dbc->error("ERROR: Cannot create library. Please ask a lab admin to create this library");
    }

    # get original source ID
    my $original_source_id = $libinfo{"Original_Source_ID"}[0];

    # get barcode label id
    my ($barcode_label_id) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_ID', "WHERE Barcode_Label_Name='src_tube'" );

    # At this point, error checking is done, return if there is at least one error
    if ( $dbc->error() ) {
        $self->success(0);
        return 0;
    }

    # Start Transaction
    $dbc->start_trans('transposon_pool');
    my $pool_id = 0;

    eval {
        ## create Original_Source,Library,Vector_Based_Library, and Transposon_Library if necessary
        # this is to create the Source that will be attached to the Transposon_Pool record
        my $transposon_library_id = 0;
        if ($append) {

            # get the Original_Source ID from the append library
            ($original_source_id) = $dbc->Table_find( "Library", "FK_Original_Source__ID", "WHERE Library_Name = '$name'" );
        }
        elsif ($library_form_data) {

            # batch append library form
            my $newids = $dbc->Batch_Append( -data => $library_form_data );
            $transposon_library_id = $newids->{"Transposon_Library.Transposon_Library_ID"};
        }
        else {

            # sanity check
            $dbc->error("ERROR: Cannot create library. Please ask a lab admin to create this library");
            return 0;
        }

        ## insert into Pool
        $pool_id = $dbc->Table_append_array( "Pool", [ 'Pool_Description', 'FK_Employee__ID', 'Pool_Date', 'Pool_Comments', 'Pool_Type' ], [ $pool_description, $emp_id, &today(), $comments, 'Transposon' ], -autoquote => 1 );

        # update Transposon_Library

        $dbc->Table_update_array( "Transposon_Library", ["FK_Pool__ID"], [$pool_id], "WHERE Transposon_Library_ID=$transposon_library_id" );
        ## insert into PoolSample
        # build smart_append hash and insert
        {

            my $index = 1;
            my %append_hash;
            foreach my $plate_id ( @{$plates} ) {
                my $sample_id   = $sample_ids[ $index - 1 ];
                my $source_well = $wells->[ $index - 1 ];
                my $quantity    = $qty->[ $index - 1 ];
                my $unit        = $units->[ $index - 1 ];
                $append_hash{$index} = [ $pool_id, $plate_id, $source_well, $sample_id, $quantity, $unit ];
                $index++;
            }

            # insert using smart_append
            $dbc->smart_append( -tables => 'PoolSample', -fields => [ 'FK_Pool__ID', 'FK_Plate__ID', 'Well', 'FK_Sample__ID', 'Sample_Quantity', 'Sample_Quantity_Units' ], -values => \%append_hash, -autoquote => 1 );
        }

        ## insert new source
        my $source_tables = 'Source,Ligation,Library_Source';
        my @source_fields = ( 'FK_Original_Source__ID', 'Notes', 'Source_Status', 'FKParent_Source__ID', 'Source_Type', 'Received_Date', 'FKReceived_Employee__ID', 'FK_Rack__ID', 'Source_Number', 'FK_Barcode_Label__ID', 'FK_Library__Name' );
        my @source_values = ( $original_source_id, 'Transposon Pool', 'Active', '0', 'Ligation', &date_time(), $emp_id, 1, 1, $barcode_label_id, $name );

        my %source_insert;
        $source_insert{1} = \@source_values;

        $dbc->smart_append( -tables => $source_tables, -fields => \@source_fields, -values => \%source_insert, -autoquote => 1 );

        my $new_source_id = $dbc->newids( 'Source', 0 );

        # insert into Transposon_Pool
        my ($transposon_pool_id) = $dbc->Table_append_array(
            "Transposon_Pool",
            [ 'FK_Transposon__ID', 'FK_GelRun__ID', 'Reads_Required', 'Pipeline', 'Test_Status', 'Status', 'FK_Source__ID', 'FK_Pool__ID' ],
            [ $transposon_id,      $gel_id,         $reads_required,  $pipeline,  $test_status,  $status,  $new_source_id,  $pool_id ],
            -autoquote => 1,
        );
    };
    $dbc->finish( 'transposon_pool', -error => $@ );

    return $pool_id;
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

$Id: Transposon_Pool.pm,v 1.11 2004/11/08 23:10:23 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
