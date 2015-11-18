##################################################################################
# alDente::Shipment.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
####################################################################################
package alDente::Shipment;
use base alDente::Object;    ## remove this line if object is NOT a DB_Object

use strict;

## Standard modules ##

## Local modules ##
use alDente::Source;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules
use alDente::Tools;

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id} || $args{-template_id};    ##

    # my $self = {};   ## if object is NOT a DB_Object ... otherwise...
    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Shipment' );
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        $self->{id} = $id;
        ## $self->add_tables();  ## add tables to standard object if applicable
        $self->primary_value( -table => 'Shipment', -value => $id );
        $self->load_Object();
    }

    return $self;
}

#########################################################################
# Script to run whenever a new Shipment record is added to the database
#
###########################
sub new_Shipment_trigger {
###########################
    my $self = shift;

    my %args = filter_input( \@_ );
    my $dbc = $args{-dbc} || $self->{dbc};
    $self->load_Object( -force => 1, -quick_load => 1 );    ## redundant ??

    my $id = $args{-id} || $self->value('Shipment.Shipment_ID');

    my $type   = $self->value('Shipment.Shipment_Type');
    my $status = $self->value('Shipment.Shipment_Status');

    if ( $type eq 'Export' ) {
        ## track material exported (no return receipt expected) ##

    }
    elsif ( $type eq 'Internal' ) {
        ## track material sent or received internally ##
        if ( $status eq 'Sent' ) {
            $self->send_Internal_Shipment();
        }
        elsif ( $status eq 'Received' ) {
            $self->receive_Internal_Shipment();
        }
    }
    else {
        ## Imported items tracked during data upload process only ##

    }

    $dbc->session->reset_homepage( { 'Shipment' => $id } );
    return;
}

#########################
sub define_Shipment {
#########################
    my $self = shift;
    my %args = filter_input( \@_ );

    ### for shipping manifests only ###
    my $target      = $args{-to};
    my $target_site = $args{-target_site};
    my $target_grp  = $args{-target_grp};
    my $source_grp  = $args{-source_grp};
    my $roundtrip   = $args{-roundtrip};
    my $virtual     = $args{-virtual};
    my $content     = $args{-contents};
    my $shipper     = $args{-shipper};
    my $debug       = $args{-debug};
    my $title       = $args{-title};

    my $dbc = $self->{dbc};
    $shipper ||= $dbc->get_local('user_id') || '_________';

    $self->{target_site} = $target_site;
    $self->{target}      = $target;
    $self->{contents}    = $content;
    $self->{shipper}     = $shipper;
    $self->{target_grp}  = $target_grp;
    $self->{source_grp}  = $source_grp;

    my ($external_site) = $dbc->Table_find( 'Site', 'Site_ID', "WHERE Site_Name = 'External'" );
    my ($external_grp)  = $dbc->Table_find( 'Grp',  'Grp_ID',  "WHERE Grp_Name = 'External'" );

    if ($virtual) {
        $self->{type} = 'Virtual';
    }
    elsif ($roundtrip) {
        $self->{type} = 'Roundtrip';
    }
    elsif ( $external_site == $target_site ) {
        $self->{type} = 'Export';
    }
    elsif ( $external_grp == $target_grp ) {
        $self->{type} = 'Export';
    }
    else {
        $self->{type} = 'Internal';
    }

    return 1;
}

#
# simply update shipment record with current user / date and status
#
#
#
############################
sub receive_Shipment {
############################
    my %args        = filter_input( \@_, -args => 'dbc,shipment_id' );
    my $dbc         = $args{-dbc};
    my $shipment_id = $args{-shipment_id};
    my $recipient   = $args{-recipient_id} || $dbc->get_local('user_id');
    my $status      = $args{-status} || 'Received';
    my $date        = $args{-date} || date_time();
    my $debug       = $args{-debug};

    my $received = 0;
    if ($shipment_id) {
        $received += $dbc->Table_update_array(
            'Shipment',
            [ 'Shipment_Status', 'Shipment_Received', 'FKRecipient_Employee__ID' ],
            [ $status,           $date,               $recipient ],
            "WHERE Shipment_ID = $shipment_id",
            -autoquote => 1,
            -debug     => $debug
        );
    }

    return $received;
}

sub Shipment_details {
###########################
    my $self = shift;

}

#
# Accessor to quickly create shipment record with given fields set.
#
# eg. $shipment_id = $Shipment->initialize_Shipment_record(-data=>{'Shipment_Sent' => date_time(), 'FK_Organization__ID' => 27});
#
# Return: new shipment id
##################################
sub initialize_Shipment {
##################################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $data  = $args{-data};
    my $debug = $args{-debug};

    my $dbc = $self->{dbc};
    my ( @fields, @values );

    if ($data) {
        foreach my $field ( $dbc->get_field_info( -table => 'Shipment' ) ) {
            if ( defined $data->{$field} ) {
                push @fields, $field;
                push @values, $data->{$field};
            }
        }
    }
    my $shipment_id;
    if (@fields) {
        $shipment_id = $dbc->Table_append_array( 'Shipment', \@fields, \@values, -autoquote => 1, -debug => $debug );
        $dbc->message( "Tracked Shipment:  " . alDente::Tools::alDente_ref( 'Shipment', $shipment_id ) );
    }

    return $shipment_id;
}

#
#
#
#
#
#########################
sub get_Shippable_Objects {
#########################
    my %args    = &filter_input( \@_, -self => 'alDente::Shipment' );
    my $self    = $args{-self};
    my $debug   = $args{-debug};
    my $dbc     = $args{-dbc} || $self->{dbc};
    my @objects = ( 'Source', 'Plate', 'Equipment', 'Rack' );

    return \@objects;
}

#
#
#
#
#
#########################
sub ship_Object {
#########################
    my %args     = &filter_input( \@_, -mandatory => 'type,ids,self|shipment', -self => 'alDente::Shipment' );
    my $self     = $args{-self};
    my $type     = $args{-type};
    my $ids      = $args{-ids};
    my $shipment = $args{-shipment} || $self->{id};
    my $debug    = $args{-debug};

    my $dbc = $args{-dbc} || $self->{dbc};

    my @id_list = Cast_List( -list => $ids, -to => 'array' );

    my ($class) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class='$type'" );
    if ( !$class ) { return $dbc->error("'$type' Class not Object_Class") }

    my $index = 1;
    my %values;
    foreach my $id (@id_list) {
        $values{$index} = [ $shipment, $class, $id ];
        $index++;
    }
    my $ok = $dbc->smart_append( -tables => 'Shipped_Object', -fields => [ 'FK_Shipment__ID', 'FK_Object_Class__ID', 'Object_ID' ], -values => \%values, -autoquote => 0 );
}

# generate manifest file name based upon input parameters
#######################
sub manifest_file {
#######################
    my $self = shift;
    my %args      = filter_input( \@_ );
    my $set       = $args{-set};
    my $rack      = $args{-rack};
    my $scope     = $args{-scope};
    my $id        = $args{-id};
    my $timestamp = $args{-timestamp};
    my $dbc       = $args{-dbc} || $self->dbc;

    my $filename;
    my $stamp;

    #    my $manifest_directory = $dbc->config('public_log_dir') . '/shipping_manifests/';

    ## works for internal shipments ##
    my $manifest_directory = alDente::Tools::get_directory( -structure => 'DATABASE', -root => $dbc->config('manifest_logs'), -dbc => $dbc );

    if ( $timestamp =~ /(\d\d\d\d)(\d\d)/ ) {
        ## creating file ##
        my $year  = $1;
        my $month = $2;
        $manifest_directory = create_dir( $manifest_directory, "$year/$month", 777 );
        $stamp = ".$timestamp.html";
    }
    else {
        ### retrieving file ##
        $stamp              = ".*";
        $manifest_directory = "$manifest_directory/*/*/";
    }

    if ($set) {
        $filename = "$manifest_directory/Set${set}_manifest$stamp";
    }
    elsif ($rack) {
        $filename = "$manifest_directory/Rac${rack}_manifest$stamp";
    }
    elsif ($scope) {
        $filename = "$manifest_directory/${scope}${id}_manifest$stamp";
    }

    if ( !$timestamp ) {
        # retrieving file #
        ($filename) = split "\n", `ls -t $filename`;    ## get most recent one if more than one...
        if ( $filename =~ /not found/ ) { Message("Warning: manifest file ($filename) not found") }
    }

    return $filename;

}

# generate manifest file name based upon input parameters
#######################
sub log_files {
#######################
    my %args = filter_input( \@_ );
    my $id   = $args{-id};
    my $dbc  = $args{-dbc};

    ## works for internal shipments ##
    my $log_directory = alDente::Tools::get_directory( -structure => 'DATABASE', -root => $dbc->config('shipment_logs') );
    my $pattern = "$log_directory/Shipment_${id}_*html";

    # retrieving file #

    my @filename = split "\n", `ls -t $pattern`;    ## get most recent one if more than one...
    if ( $filename[0] =~ /No such file/i || $filename[0] =~ /not found/i ) {
        return;
    }

    return @filename;

}

##########################
# call in views to get list of shipment information given. This takes in an array of library names or source ids
#
# Example:
# Shipment_ID => require alDente::Shipment; alDente::Shipment_App::viewGet_shipment_Info(-dbc=>$self->{dbc}, -library=>$results->{Library_Name}); will return shipment IDs
# Received_Date => require alDente::Shipment; alDente::Shipment_App::viewGet_shipment_Info(-dbc=>$self->{dbc}, -source=>$results->{Source_ID}, -column=>'Shipment_Received'); will return shipment received
#
#
# Return: array of shipment info. Depending on what is in the $column field. If there are no items specified, then it returns a list of Shipment_IDs
#
# This method does not check whether the column exists in the database, so if the column does not exist, there will be a syntax error
#
#
##########################
sub viewGet_shipment_Info {
#########################

    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $library = $args{-library};        # a parameter passed in which will get the shipment info of a library
    my $source  = $args{-source};         # a parameter passed in which will get the shipment info of a source
    my $column  = $args{-column};         # input which is used to describe the column info which you want from the shipment info eg. Shipment_Received
    my $export  = $args{-export};         # if true, gets the export/roundtrip shipment info of the original source (initial source)
    my $debug   = $args{-debug};

    my $initial_source;
    my $max_shipment;                     # stores the max shipment id
    my @all_shipments;                    # stores all the shipments and then will push the max value
    my @shipment_info;                    # list of key shipment info
    my @shipment_IDs;                     # list of key shipment_IDs
    my @libraries;
    my @sources;
    my @original_sources;

    use List::Util qw(min max);           # used to get the max value in an array
    if ($debug) {

        print "Input Source: $source \n";
        print "Export: $export \n";
        print "Input Library: $library \n";
        print HTML_Dump($source);
    }

    if ($export) {
        if ($library) {
            @libraries = @$library;
            foreach my $libraries (@libraries) {
                my @library_source = $dbc->Table_find_array( 'Library_Source', ['FK_Source__ID'], "WHERE FK_Library__Name = '$libraries'" );
                foreach my $ls (@library_source) {
                    my ($original_source) = $dbc->Table_find( 'Source', 'MAX(Source_ID)', "WHERE FKOriginal_Source__ID = $ls" );
                    push @original_sources, $original_source;
                }
            }
        }
        elsif ($source) {

            #@sources = Cast_List( -list => $source, -to => 'Array' );
            @sources = @$source;
            foreach my $source (@sources) {
                my ($original_source) = $dbc->Table_find( 'Source', 'MAX(Source_ID)', "WHERE FKOriginal_Source__ID = $source" );
                push @original_sources, $original_source;
            }
        }

        foreach my $original_source (@original_sources) {
            my ($shipment)
                = $dbc->Table_find(
                'Source LEFT JOIN Shipped_Object ON Source.Source_ID = Shipped_Object.Object_ID LEFT JOIN Shipment ON (Shipped_Object.FK_Shipment__ID = Shipment.Shipment_ID AND Shipment.FKFrom_Grp__ID = 48 AND Shipment.FKTarget_Grp__ID = 28)',
                'MAX(Shipment_ID)', "WHERE Source_ID = $original_source" );
            push @shipment_IDs, $shipment;
        }
    }
    else {
        if ($library) {
            @libraries = Cast_List( -list => $library, -to => 'Array' );

            foreach my $libraries (@libraries) {
                my @library_source = $dbc->Table_find_array( 'Library_Source', ['FK_Source__ID'], "WHERE FK_Library__Name = '$libraries'" );

                foreach my $ls (@library_source) {
                    $initial_source = alDente::Source::getSource_IDs( -dbc => $dbc, -source => $ls );

                    my ($shipment) = $dbc->Table_find( 'Source', 'FK_Shipment__ID', "WHERE Source_ID = $initial_source" );
                    print Message("Column: $column, Library: $libraries, Source: $ls, Initial_Source: $initial_source, Shipment: $shipment") if $debug;
                    push @all_shipments, $shipment;
                }
                $max_shipment  = max(@all_shipments);
                @all_shipments = ();                    #clearing all elements in array
                push @shipment_IDs, $max_shipment;
            }
        }
        elsif ($source) {
            @sources = Cast_List( -list => $source, -to => 'Array' );

            #            @sources = @$source;
            foreach my $sources (@sources) {
                $initial_source = alDente::Source::getSource_IDs( -dbc => $dbc, -source => $sources );
                my ($shipment) = $dbc->Table_find( 'Source', 'FK_Shipment__ID', "WHERE Source_ID = $initial_source" );
                push @shipment_IDs, $shipment;
            }
        }
    }
    if ($column) {
        foreach my $ids (@shipment_IDs) {
            my ($info) = $dbc->Table_find( 'Shipment', "$column", "WHERE Shipment.Shipment_ID = $ids" );
            my ($fk_info) = get_FK_info( $dbc, "$column", "$info" );

            if ($fk_info) {
                push @shipment_info, $fk_info;
            }
            else {
                push @shipment_info, $info;
            }
        }
    }
    else {
        @shipment_info = @shipment_IDs;
    }

    return \@shipment_info;
}

1;
