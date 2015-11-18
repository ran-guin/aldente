################################################################################
# Sample.pm
#
# This module handles Sample objects
#
###############################################################################
package alDente::Sample;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>
Sample.pm - This module handles the Sample object model

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles model methods for the Sample Object

=cut

##############################
# superclasses               #
##############################

@ISA = qw(SDB::DB_Object Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(get_sample_id);

##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use alDente::Validation;
use alDente::Form;
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::DB_Object;
use RGTools::RGIO;
use RGTools::Conversion;
use SDB::HTML;
use RGTools::Views;

use alDente::Attribute_Views;
use alDente::Validation;
use alDente::Container;
use alDente::Run_Views;

##############################
# global_vars                #
##############################
use vars qw($project_dir);
use vars qw($testing $Connection);

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
    my ($class) = ref($this) || $this;
    my %args = @_;
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id         = $args{-id};
    my $ids        = $args{-ids};
    my $plate_id   = $args{-plate_id} || 0;
    my $attributes = $args{-attributes};                                                              ## allow inclusion of attributes for new record
    my $encoded    = $args{-encoded} || 0;                                                            ## reference to encoded object (frozen)

    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => 'Sample', -encoded => $encoded );
    $self->add_tables( 'Sample_Type',     'Sample.FK_Sample_Type__ID = Sample_Type_ID' );
    $self->add_tables( 'Source',          'Source_ID = Sample.FK_Source__ID' );
    $self->add_tables( 'Original_Source', 'Source.FK_Original_Source__ID=Original_Source_ID' );
    bless $self, $class;

    $self->{dbc} = $dbc;
    $self->{analysis_types} = [ 'Sequence', 'GelRun' ];

    if ($id) {
        $self->{id} = $id;
        unless ( $id =~ /,/ ) {
            $self->primary_value( -table => 'Sample', -value => $id );
            $self->load_Object();
        }
    }

    return $self;

}

####################
#
# load sample object - sets DBobject attribute and loads object depending upon type. (eg Equipment / Solution / Box)
#
#################
sub load_Object {
#################
    my $self = shift;
    my $id   = shift || $self->{id};
    my $dbc  = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    unless ($id) { Message("No ID supplied"); return 0; }

    $self->SUPER::load_Object( -include_custom_tables => 'Sample' );
    $self->set( 'loaded', 1 );
    return;
}

##############################
# public_methods             #
##############################

#################################
sub mix_Sample_types {
#################################
    # Description
    #   Takes in 2 sample type aliases and creates a mix of the 2
    #
    #
################################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'dbc,first,second' );
    my $dbc    = $args{-dbc};
    my $first  = $args{-first};
    my $second = $args{-second};

    my ($first_name)  = $dbc->Table_find( 'Sample_Type', 'Sample_Type', "WHERE Sample_Type_Alias = '$first'" );
    my ($second_name) = $dbc->Table_find( 'Sample_Type', 'Sample_Type', "WHERE Sample_Type_Alias = '$second'" );

    my ( $common_parent_id, $common_parent_name ) = $self->find_common_Sample_Type_Parent( -dbc => $dbc, -first => $first, -second => $second );
    my $name = "Mixed $common_parent_name" . ':' . $first_name . '+' . $second_name;

    if ( $first eq $second ) {
        Message "Warning: You do not need to mix sample type with itself";
        return;
    }
    my @fields = ( 'Sample_Type', 'FKParent_Sample_Type__ID' );
    my @values = ( $name, $common_parent_id );
    my $id = $dbc->Table_append_array( "Sample_Type", \@fields, \@values, -autoquote => 1 );
    return $id;
}

#################################
sub find_common_Sample_Type_Parent {
#################################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'dbc,first,second' );
    my $dbc    = $args{-dbc};
    my $first  = $args{-first};
    my $second = $args{-second};

    my @first_ancestry  = $self->get_Ancestry_Array( -alias => $first,  -dbc => $dbc );
    my @second_ancestry = $self->get_Ancestry_Array( -alias => $second, -dbc => $dbc );

    for my $first_id (@first_ancestry) {
        for my $second_id (@second_ancestry) {
            if ( $first_id == $second_id ) {

                my ($name) = $dbc->Table_find( 'Sample_Type', 'Sample_Type', "Where Sample_Type_ID = $first_id" );
                return ( $first_id, $name );
            }
        }
    }

    return ( 0, 'Mix' );
}

#################################
sub get_Ancestry_Array {
#################################
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'dbc,first,second' );
    my $dbc   = $args{-dbc};
    my $alias = $args{-alias};
    my $id    = $args{-id};
    my @ancestry;

    if ( !$id ) {
        ($id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "Where Sample_Type_Alias = '$alias'" );
    }

    while ($id) {
        push @ancestry, $id;
        ($id) = $dbc->Table_find( 'Sample_Type', 'FKParent_Sample_Type__ID', "Where Sample_Type_ID = $id" );
    }

    return @ancestry;
}

####################
sub home_page {
####################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc,id' );

    my $include_joins = $args{-include_joins} || 1;
    my $dbc           = $args{-dbc}           || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id            = $self->{id}           || $args{-id};

    $self->load_Object() unless ( $self->{loaded} || ( $self->{id} =~ /,/ ) );

    unless ($id) { Message("No sample id "); Call_Stack(); return; }

    my $name = $self->get_data('Sample_Name');
    my $type = $self->get_data('Sample_Type.Sample_Type');

    my $title = &Views::Heading("Sample: $name");

    my @aliases = $Connection->Table_find( 'Sample_Alias', 'Alias_Type,Alias', "WHERE FK_Sample__ID IN ($id)" );
    my $alias;
    if (@aliases) { $alias .= HTML_list( -title => 'Aliases:', -list => \@aliases, -split => ',', -format => 'li' ) }

    my $found = 0;

    # <Construction> - may want to include lineage information here as well...
    #
    #    my @plates = $Connection->Table_find('Plate_Sample','FKOriginal_Plate__ID,Well',"WHERE FK_Sample__ID=$id");
    #   foreach my $plate (@plates) {
    #	print "PLATE: $plate.<BR>";
    #	my ($plate_id,$well) = split ',', $plate;
    #	my %lineage = &alDente::Container::get_Parents(-dbc=>$self->dbc,-id=>$plate_id,-format=>'hash',-well=>$well);
    #	my %child_lineage = &alDente::Container::get_Children(-dbc=>$self->dbc,-id=>$plate_id,-format=>'hash',-include_self=>1);
    #
    #	print HTML_Dump(\%lineage);
    #	print HTML_Dump(\%child_lineage);
    #    }

    ## in case of multiple samples, repeat for each sample in list ##
    my @info;

    foreach my $single_id ( split ',', $id ) {

        my ($thisid) = ($single_id);
        my @ancestors;

        ## show parent ancestry ##
        while ( my ($parent) = $Connection->Table_find( 'Sample, Sample as Parent', 'Parent.Sample_ID,Parent.Sample_Name,Sample.Sample_Name', "WHERE Parent.Sample_ID=Sample.FKParent_Sample__ID AND Sample.Sample_ID = $thisid" ) ) {
            my ( $Pid, $Pname, $thisname ) = split ',', $parent;
            if ( $thisid == $id ) { $thisname = "<B>$thisname</B>" }    ## highlight current sample
            my $source = &Link_To( $dbc->config('homelink'), "$Pname", "&HomePage=Sample&ID=$Pid" );
            push( @ancestors, "$source ($Pid)->$thisname ($thisid)" );
            $thisid = $Pid;
        }

        ## show children ancestry ##
        $thisid = $single_id;
        while ( my ($child) = $Connection->Table_find( 'Sample, Sample as Child', 'Child.Sample_ID,Child.Sample_Name,Sample.Sample_Name', "WHERE Child.FKParent_Sample__ID=Sample.Sample_ID AND Sample.Sample_ID = $thisid" ) ) {
            my ( $Cid, $Cname, $thisname ) = split ',', $child;
            if ( $thisid == $id ) { $thisname = "<B>$thisname</B>" }    ## highlight current sample
            my $target = &Link_To( $dbc->config('homelink'), "$Cname", "&HomePage=Sample&ID=$Cid" );
            push( @ancestors, "$thisname ($thisid)->$target ($Cid)" );
            $thisid = $Cid;
        }

        if (@ancestors) { $alias .= &vspace(5) . HTML_list( -title => 'Ancestry', -list => \@ancestors, -split => '->', -headers => [ 'Parent', 'Sample' ] ) }

        #    my $id   = $self->value('Sample_ID');
        my $name = $self->value('Sample_Name');
        my $type = $self->value('Sample_Type.Sample_Type');

        push @info, "Sample $single_id: " . alDente::Tools::alDente_ref( -dbc => $dbc, -table => 'Sample', -id => $single_id );    ## <BR><B>Name: $name<BR>Type: $type</B>" . &vspace(5);
    }
    my $details;
    if ( $id !~ /,/ ) {
        $info[0] .= &alDente::Attribute_Views::show_attribute_link( 'Sample', $id, -dbc => $dbc );
        $details = $self->display_Record( -include_references => 'Sample' );                                                       ## if include_references = 1, this will hang system due to ref checks on Sample_Type... way slow ##
    }

    my $info = Cast_List( -list => \@info, -to => 'OL' );

    $info .= '<p ></p>' . $alias . '<p ></p>';

    my $refs = alDente::Run_Views::show_run_data( -dbc => $dbc, -sample_id => $id );
    $refs .= '<p ></p>';
    $refs .= show_sample_data( -dbc => $dbc, -sample_id => $id );

    my %colspan;
    $colspan{1}->{1} = 2;                                                                                                          ### Set the Heading to span 2 columns

    my $page = &Views::Table_Print( content => [ [ $info . $refs, $details ] ], -colspan => \%colspan, print => 0 );
    $page .= '<HR>';

    return $page;
}

##############################
# Create a set of Clone_Samples for a plate
# return: 1 if successful, 0 if not
# (note different version below - not sure which one is correct)
##############################
sub create_samples {
##############################
    my %args = &filter_input( \@_, -mandatory => 'plate_id' );

    my $dbc                  = $args{-dbc};                            # (ObjectRef) The connection object of the transaction
    my $plate_id             = $args{-plate_id};                       # (Scalar) ID of the plate to add Samples to
    my $source_id            = $args{-source_id};                      # (Scalar) Source ID of the source that this plate is being created from
    my $type                 = $args{-type};                           # type of sample being created
    my $from_rearray_request = $args{-from_rearray_request};
    my $wells                = $args{-wells};
    my $sample_source        = $args{-sample_source} || 'Original';    ## Not sure whether all samples should default to 'Original'

    unless ($source_id) {
        $source_id = '';
    }

    # retrieve properties of the plate
    my ($plate_details) = $dbc->Table_find_array( "Plate,Sample_Type", [ "Plate_Number", "FK_Library__Name", "Plate_Size", "FK_Sample_Type__ID", 'Sample_Type.Sample_Type' ], "WHERE FK_Sample_Type__ID=Sample_Type_ID AND Plate_ID = $plate_id" );

    my ( $plate_number, $lib, $plate_size, $sample_type_id, $plate_contents ) = split ',', $plate_details;
    $plate_contents ||= $type;                                         ## if not defined, use type indicated... ##

    # for Clone_Samples:  create Extracton_Sample, Plate_Sample, and Sample records as necessary
    my $condition;
    my $well_field;

    if ( $plate_size =~ /96/ ) {
        $well_field = 'Plate_96';
        $condition  = "WHERE Quadrant='a'";
    }
    elsif ( $plate_size =~ /384/ ) {
        $well_field = 'Plate_384';
        $condition  = '';
    }
    else {
        $well_field = "N/A";
        $condition  = '';
    }

    # build a hash with all the wells to insert as the key and the quadrant as the value
    my %Map;
    my @wells;

    my @parent_samples;
    my @sources;

    ## if there is a source plate id, determine the sources that need to be linked to each individual sample
    # optimization - if the source plate is a tube, just grab the sample ID ONCE

    my $tube_sample = get_Parent_Sample( -dbc => $dbc, -source_id => $source_id );

    # if necessary, retrieve source sample by searching through the inheritance tree of the source
    if ($from_rearray_request) {
        my %rearray_info = &Table_retrieve(
            $dbc, "ReArray,ReArray_Request",
            [ "Source_Well", "Target_Well", "FKSource_Plate__ID", 'FK_Sample__ID', 'FKTarget_Plate__ID' ],
            "WHERE  FK_ReArray_Request__ID = ReArray_Request_ID and ReArray_Request_ID = $from_rearray_request"
        );
        my $index = 0;
        while ( exists $rearray_info{FKSource_Plate__ID}[$index] ) {
            my $source_well   = $rearray_info{Source_Well}[$index];
            my $target_well   = $rearray_info{Target_Well}[$index];
            my $source_plate  = $rearray_info{FKSource_Plate__ID}[$index];
            my %ancestry      = &alDente::Container::get_Parents( -dbc => $dbc, -id => $source_plate, -well => $source_well, -format => 'hash', -simple => 1 );
            my $parent_sample = $ancestry{sample_id};
            ### update information with Sample, Plate_Sample and Extraction_Sample/Clone_Sample information
            my $source;
            if ($parent_sample) {
                ($source) = $dbc->Table_find( 'Sample', 'FK_Source__ID', "WHERE Sample_ID = $parent_sample" );
            }
            push( @wells,          $target_well );
            push( @parent_samples, $parent_sample );
            push( @sources,        $source );
            $index++;
        }
    }
    elsif ( $well_field ne 'N/A' ) {
        my @well_info = $dbc->Table_find( 'Well_Lookup', "$well_field,Quadrant", "$condition" );
        foreach my $row (@well_info) {
            my ( $well, $quad ) = split ',', $row;
            $well = &format_well($well);
            next if ( $wells && !grep /$well/, @{$wells} );
            push( @wells, $well );
            $Map{$well} = $quad;

            my $parent = $tube_sample || get_Parent_Sample( -dbc => $dbc, -source_id => $source_id, -well => $well );    ## only call if tube sample not already defined
            ## inherit parent sample if applicable ##
            push @parent_samples, $parent;

        }
    }
    else {
        push( @wells, $well_field );
        $Map{$well_field} = '';

        push @parent_samples, get_Parent_Sample( -dbc => $dbc, -source_id => $source_id, -well => $well_field );
    }

    # build insert hash for smart_append
    # inserting into tables Sample,Clone_Sample, and Plate_Sample
    my %sample_info;

    foreach my $i ( 0 .. $#wells ) {
        my $well = $wells[$i];
        my $quad = '';
        if ( $plate_size =~ /384/ ) {
            $quad = $Map{$well};
        }

        # custom code - do not add in a well if there is only one well
        my $sample_name = "$lib-${plate_number}\_$well";
        if ( $well eq 'N/A' ) {
            $sample_name = "$lib-${plate_number}";
        }
        if (@sources) {
            $source_id = $sources[$i];
        }
        $sample_info{ $i + 1 } = [ $sample_name, $sample_type_id, $source_id, $parent_samples[$i], $plate_id, $plate_id, $well, $well, $plate_number, $lib, $sample_source ];
    }

    my $tables = 'Sample,Plate_Sample';
    my ($add_table) = $dbc->Table_find( 'DBField,DBTable', 'DBTable_Name', "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name like '$plate_contents' AND Field_Name like 'FK_Sample__ID'" );
    if ($add_table) { $tables .= ",$add_table" }    ## include sub-table if defined (it will be essentially empty - populate extra fields using Trigger if necessary) ##

    my $ok = $dbc->smart_append(
        -tables => $tables,
        -fields => [
            'Sample.Sample_Name',   'Sample.FK_Sample_Type__ID', 'Sample.FK_Source__ID', 'Sample.FKParent_Sample__ID', 'Plate_Sample.FKOriginal_Plate__ID', 'Sample.FKOriginal_Plate__ID',
            'Sample.Original_Well', 'Plate_Sample.Well',         'Sample.Plate_Number',  'Sample.FK_Library__Name',    'Sample_Source'
        ],
        -values    => \%sample_info,
        -autoquote => 1,
    );
    if ($ok) {
        return 1;
    }
    else {
        return 0;
    }
}

#
# Retrieve parent sample if applicable for indicated Source
#
# Return: sample_id (or empty string if not uniquely defined)
###########################
sub get_Parent_Sample {
###########################
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc};
    my $source_id = $args{-source_id};
    my $well      = $args{-well};
    my $debug     = $args{-debug};

    my $plate_source;

    if ($source_id) { ($plate_source) = $dbc->Table_find( 'Source', 'FKSource_Plate__ID', "WHERE Source_ID = $source_id" ) }

    if ($plate_source) {
        my %Ancestry = alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_source, -well => $well );
        $dbc->message("$plate_source from SRC $source_id") if ($debug);
        use Data::Dumper;

        #print Dumper \%Ancestry;

        my ($plate_source_type) = $dbc->Table_find( "Plate", "Plate_Type", "WHERE Plate_ID=$plate_source" );
        if ( ( $plate_source_type eq 'Tube' ) || ( $well && $well ne 'N/A' ) ) {
            return $Ancestry{sample_id};
        }
    }

    return;
}

##############################
# Create a set of Clone_Samples for a plate
# return: 1 if successful, 0 if not
##############################
sub create_samples2 {
##############################
    my %args = &filter_input( \@_, -mandatory => 'plate_id' );

    my $dbc           = $args{-dbc};                            # (ObjectRef) The connection object of the transaction
    my $plate_id      = $args{-plate_id};                       # (Scalar) ID of the plate to add Samples to
    my $source_id     = $args{-source_id};                      # (Scalar) Source ID of the source that this plate is being created from
    my $type          = $args{-type};                           # type of sample being created
    my $sample_source = $args{-sample_source} || 'Original';    ## Not sure whether all samples should default to 'Original'

    if ( !$type ) { ($type) = $dbc->Table_find( 'Sample_Type,Plate', 'Sample_Type', "WHERE FK_Sample_Type__ID = Sample_Type_ID AND Plate_ID = $plate_id" ); }

    #Message("Creating Samples from Plate $plate_id (SRC $source_id) - $type");

    unless ($source_id) {
        $source_id = '';
    }

    # retrieve properties of the plate
    my ($plate_details) = $dbc->Table_find_array( "Plate,Sample_Type", [ "Plate_Number", "FK_Library__Name", "Plate_Size", "FK_Sample_Type__ID", 'Sample_Type.Sample_Type' ], "WHERE FK_Sample_Type__ID=Sample_Type_ID AND Plate_ID = $plate_id", );

    my ( $plate_number, $lib, $plate_size, $sample_type_id, $plate_contents ) = split ',', $plate_details;
    $plate_contents ||= $type;    ## if not defined, use type indicated... ##

    # for Clone_Samples:  create Extracton_Sample, Plate_Sample, and Sample records as necessary
    my $condition;
    my $well_field;

    if ( $plate_size =~ /96/ ) {
        $well_field = 'Plate_96';
        $condition  = "WHERE Quadrant='a'";
    }
    elsif ( $plate_size =~ /384/ ) {
        $well_field = 'Plate_384';
        $condition  = '';
    }
    else {
        $well_field = "N/A";
        $condition  = '';
    }

    # build a hash with all the wells to insert as the key and the quadrant as the value
    my %Map;
    my @wells;

    # retrieve the source plate id if this is created from a source that exists in the system
    my $plate_source = '';
    if ($source_id) {
        ($plate_source) = $dbc->Table_find( 'Source', 'FKSource_Plate__ID', "WHERE Source_ID=$source_id" );
    }
    my @parent_samples;

    ## if there is a source plate id, determine the sources that need to be linked to each individual sample
    # optimization - if the source plate is a tube, just grab the sample ID ONCE
    my $plate_source_type = undef;
    my $tube_sample       = undef;
    if ($plate_source) {
        ($plate_source_type) = $dbc->Table_find( "Plate", "Plate_Type", "WHERE Plate_ID=$plate_source" );
        if ( $plate_source_type eq 'Tube' ) {
            my %Ancestry = alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_source );
            $tube_sample = $Ancestry{sample_id};
        }
    }

    # if necessary, retrieve source sample by searching through the inheritance tree of the source
    if ( $well_field ne 'N/A' ) {
        my @well_info = $dbc->Table_find( 'Well_Lookup', "$well_field,Quadrant", "$condition" );
        foreach my $row (@well_info) {
            my ( $well, $quad ) = split ',', $row;
            $well = &format_well($well);
            push( @wells, $well );
            $Map{$well} = $quad;
            if ( $plate_source && ( $plate_source_type eq 'Tube' ) ) {
                push( @parent_samples, $tube_sample );
            }
            elsif ($plate_source) {
                my %Ancestry = alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_source, -well => $well );
                my $sample_id = $Ancestry{sample_id};
                push( @parent_samples, $sample_id );
            }
        }
    }
    else {
        push( @wells, $well_field );
        $Map{$well_field} = '';
    }

    # build insert hash for smart_append
    # inserting into tables Sample,Clone_Sample, and Plate_Sample
    my %sample_info;

    foreach my $i ( 0 .. $#wells ) {
        my $well = $wells[$i];
        my $quad = '';
        if ( $plate_size =~ /384/ ) {
            $quad = $Map{$well};
        }

        # custom code - do not add in a well if there is only one well
        my $sample_name = "$lib-${plate_number}\_$well";
        if ( $well eq 'N/A' ) {
            $sample_name = "$lib-${plate_number}";
        }

        $sample_info{ $i + 1 }
            = [ $sample_name, $sample_type_id, $source_id, $parent_samples[$i], $plate_id, $plate_id, $well, $well, $plate_number, $lib, $sample_source ];    ## ADD $sample_source here? (if yes, also add Sample.Sample_Source in field list below)
    }
    my $tables = 'Sample,Plate_Sample';
    my ($add_table) = $dbc->Table_find( 'DBField,DBTable', 'DBTable_Name', "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name like '$plate_contents' AND Field_Name like 'FK_Sample__ID'" );
    if ($add_table) { $tables .= ",$add_table" }    ## include sub-table if defined (it will be essentially empty - populate extra fields using Trigger if necessary) ##

    my $ok = $dbc->smart_append(
        -tables => $tables,
        -fields => [
            'Sample.Sample_Name',   'Sample.FK_Sample_Type__ID', 'Sample.FK_Source__ID', 'Sample.FKParent_Sample__ID', 'Plate_Sample.FKOriginal_Plate__ID', 'Sample.FKOriginal_Plate__ID',
            'Sample.Original_Well', 'Plate_Sample.Well',         'Sample.Plate_Number',  'Sample.FK_Library__Name',    'Sample_Source'
        ],
        -values    => \%sample_info,
        -autoquote => 1
    );

    if ($ok) {
        return 1;
    }
    else {
        return 0;
    }
}

##############################
# public_functions           #
##############################

##########################
sub show_sample_data {
##########################
    my %args      = &filter_input( \@_, -args => 'dbc,sample_id' );
    my $dbc       = $args{-dbc};
    my $sample_id = $args{-sample_id};

    my $output = '<P>' . Views::Heading("Sample(s) $sample_id referenced by:");
    my @referring_tables = $dbc->Table_find( 'DBField,DBTable', "DBTable_Name", "WHERE FK_DBTable__ID=DBTable_ID AND Field_Name = 'FK_Sample__ID'" );
    foreach my $table (@referring_tables) {
        my $reference = $dbc->Table_retrieve_display( $table, ['*'], "WHERE FK_Sample__ID in ($sample_id)", -title => "$table Records", -alt_message => '', -return_html => 1 );
        $output .= "$reference\n<HR>" if $reference;
    }
    return $output;
}

#######################
sub get_sample_id {
#######################
    my $self = shift;

    my %args       = @_;
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $plate_id   = $args{-plate_id} || $self->{plate_id};
    my $well       = $args{-well};
    my $plate_type = $args{-plate_type};

    my $info;
    my $size;
    my $original_id;
    my $quadrant;

    if ( $plate_type =~ /Library_Plate/i ) {
        ($info) = $dbc->Table_find( 'Plate,Library_Plate', 'Plate_Size,FKOriginal_Plate__ID,Plate.Parent_Quadrant', "WHERE FK_Plate__ID=Plate_ID AND Plate_ID in ($plate_id)" );
        ( $size, $original_id, $quadrant ) = split ',', $info;
    }
    elsif ( $plate_type =~ /Tube/i ) {
        $well = 'n/a';
        ($original_id) = $dbc->Table_find( 'Plate', 'FKOriginal_Plate__ID', "WHERE Plate_ID in ($plate_id)" );
    }

    my $sample_id;
    if ($quadrant) {
        ($sample_id) = $dbc->Table_find( 'Plate_Sample,Well_Lookup', 'FK_Sample__ID', "WHERE FKOriginal_Plate__ID=$original_id AND Well=Plate_384 AND Plate_96='$well' AND Quadrant='$quadrant'" );
    }
    else {
        ($sample_id) = $dbc->Table_find( 'Plate_Sample', 'FK_Sample__ID', "WHERE FKOriginal_Plate__ID=$original_id AND Well='$well' " );
    }

    return $sample_id;
}

### Allow uploading of sample aliases through an input file
############################
sub get_sample_alias {
############################
    my %args        = &filter_input( \@_ );
    my $file_handle = $args{-file};
    my $plate       = $args{-plate};
    my $dbc         = $args{-dbc};

    print &alDente::Form::start_alDente_form( $dbc, );

    #print "file: $file_handle";
    my @file_contents = ();

    my @fields = ( 'Well', 'Alias', 'Alias_Type' );
    my $sample_alias = &RGTools::RGIO::Parse_CSV_File( -file_handle => $file_handle, -format => 'AofH', -fields => \@fields, -delimiter => ',' );

    return $sample_alias;
}

##############
sub id_by_Plate {
##############
    #
    # Identify Sample given Plate information (plate id & well)
    #
    my $self  = shift;
    my %args  = &filter_input( \@_, -args => 'plate,well', -mandatory => 'plate' );
    my $plate = $args{-plate};                                                        ## plate id
    my $well  = $args{-well};                                                         ## well position in plate
    my $found = 0;                                                                    ## flag to indicate if Clone identified

    my ($sample_id) = $Connection->Table_find( 'Plate_Sample,Plate', 'FK_Sample__ID', "where Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID AND Plate_ID = $plate AND Well = '$well'" );
    if ($sample_id) {
        $found = 1;
        $self->primary_value( -table => 'Sample', -value => $sample_id );
        $self->{id} = $sample_id;
        $self->load_Object();
    }
    else {
        print "No sample found for Plate $plate ($well)";
        return 0;
    }

    return $self;
}

##############
sub id_by_Name {
##############
    #
    # Identify Clone given Name... (eg. 'CN001-1a')
    #
    my $self = shift;

    my %args = @_;
    my $run  = $args{-name};    ## plate id

    my $found = 0;              ## flag to indicate if Clone identified

    return $found;
}

#############
sub id_by_Run {
#############
    #
    # Identify Clone given Run information (run id & well)
    #
    my $self = shift;

    my %args = @_;
    my $run  = $args{-run};     ## plate id
    my $well = $args{-well};    ## well position in plate

    my $found = 0;              ## flag to indicate if Clone identified

    return $found;
}

###########################
## HTML specific blocks ##
##########################

##############################
# private_methods  #################################################################################
# Return: block form allowing access to sample specific information for a plate
##############################
sub query_sample_block {
##############################
    my %args           = &filter_input( \@_, -args => 'plate_id' );
    my $plate_id       = $args{-plate_id};
    my $submit_options = $args{-submit};
    my $dbc            = $args{-dbc};

    my $sample_info_block = alDente::Form::start_alDente_form( $dbc, -name => 'status' );
    $sample_info_block .= submit( -name => 'Get Sample Info', -class => "Search" ) . " for Well: " . textfield( -name => 'Well', -size => 10 ) . " (eg. 'E05,E06' or 'A01-A08')";
    $sample_info_block .= hidden( -name => 'Sample Plate', -value => $plate_id );

    if ($submit_options) {
        ## add optional submit buttons as supplied ##
        foreach my $option (@$submit_options) {
            $sample_info_block .= &hspace(20) . submit( -name => $option, -class => "Search" );
        }
    }

    $sample_info_block .= end_form();
    return $sample_info_block;
}

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

$Id: Sample.pm,v 1.24 2004/12/02 20:30:08 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
