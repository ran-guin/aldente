##################################################################################################################################
# primer_plate.pm
#
# A primer plate that is a solution array of primers on a piece of plasticware.  The well mapping is a 96-well Mapping (currently only ordered in 96-well format)
#
#
###################################################################################################################################
package alDente::Primer_Plate;
@ISA = qw(SDB::DB_Object);
use SDB::CustomSettings;
use alDente::SDB_Defaults;
use RGTools::Conversion;
use vars qw( $Benchmark);
use vars qw( $testing $lab_administrator_email $stock_administrator_email $scanner_mode);
use vars qw($yield_reports_dir $Current_Department %Settings %Configs);
use strict;
use Carp;
use RGTools::RGIO;

#########
sub new {
#########
    my $this  = shift;
    my $class = ref $this || $this;
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $self  = {};
    $self->{dbc} = $dbc;

    bless $self, $class;

    return $self;
}

sub apply_primer_plate {
    my $applied_primer_plate;

    return $applied_primer_plate;
}

sub create_primer_plate {
    my $primer_plate_id;

    return $primer_plate_id;
}

sub get_primer_plate_status {
    my $self = shift;
    return $self->{primer_plate_status};
}

sub set_primer_plate_status {
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'status', -mandatory => 'status' );
    my $status = $args{-status};
    $self->{primer_plate_status} = $status;
}

sub remap_primer_plate {

}

##################################
sub _map_primers_on_primer_plate {
##################################
    my $self                        = shift;
    my %args                        = filter_input( \@_, -args => "primers,wells" );
    my $primers                     = $args{-primers};                                 ## primers in the well
    my $wells                       = $args{-wells};                                   ## well mapping on primer plate
    my $parent_primer_plate_well_id = $args{-parent_primer_plate_well_id};             ## <Optional> set when remapping from one primer plate to another

    return 1;
}
###################################################
# Update the primer well status for a primer plate
#
# Example:
# <snip>
#    my $updated = update_primer_well_status(-dbc=>$dbc,-primer_plate_id=>5000,-wells=>['A01','B02','C07'],'Passed');
# </snip>
#
# Return:  results of update
###################################################
sub update_primer_plate_well_status {
###################################################
    my $self               = shift;
    my %args               = filter_input( \@_, -args => "dbc, primer_plate_id, wells, primer_well_status", -mandatory => "dbc, primer_plate_id, wells, primer_well_status" );
    my $dbc                = $args{-dbc};
    my $primer_plate_id    = $args{-primer_plate_id};                                                                                                                            ## Primer Plate to be updated
    my $wells              = $args{-wells};                                                                                                                                      ## Array of wells to set
    my $primer_well_status = $args{-primer_well_status};                                                                                                                         ## Passed, Failed, N/A

    my $primer_wells = Cast_List( -list => $wells, -to => 'String', -autoquote => 1 );
    my $updated = 0;

    $updated = $dbc->Table_update_array( 'Primer_Plate_Well', ['Primer_Plate_Well_Status'], ["$primer_well_status"], "WHERE Primer_Plate_ID = $primer_plate_id and Well IN ($primer_wells)" );

    return $updated;
}

###############################################################
# Subroutine: orders oligo primers and adds them to the Primer table
#             Warning: You must call send_primer_order() to write
#             out the primer order to disk!
# RETURN: hash reference to the primer plate and primer ids if successful, 0 otherwise
###############################################################
sub order_primers {
    my $self = shift;
    my %args = @_;

    my $primer_well_ref              = $args{-wells};                           # (ArrayRef) array of wells corresponding to each primer
    my $primer_name_ref              = $args{-name};                            # (ArrayRef) array of primer names
    my $primer_sequence_ref          = $args{-sequence};                        # (ArrayRef) array of primer sequences
    my $direction_ref                = $args{-direction};                       # (ArrayRef) Optional: array of primer directions
    my $position_ref                 = $args{-position};                        # (ArrayRef) Optional: array of primer positions.
    my $amplicon_length_ref          = $args{-amplicon_lengths};                # (Arrayref) Optional: array of amplicon lengths
    my $tms_working_ref              = $args{-tm_working};                      # (ArrayRef) array of temperatures. This supersedes the -tm_calc argument
    my $tm_calc                      = $args{-tm_calc};                         # (Scalar) the tm calculator to use. Supports 'MGC Standard'. This is overridden by -tm_working.
    my $emp_name                     = $args{-emp_name};                        # (Scalar) the unix userid of the employee doing the ordering
    my $group_id                     = $args{-group_id};                        # (Scalar) Group ID of the group that is ordering the primers
    my $file_only                    = $args{-file_only};                       # (Scalar) Writes out primer order to file only (not the database). Useful for ordering primers that are already in the database. In general, should not be used.
    my $primer_type                  = $args{-primer_type} || 'Oligo';          # (Scalar) type of primer. One of Standard, Oligo, or Amplicon
    my $notes                        = $args{-notes};                           # (Scalar) Optional: notes to be appended to the primer plate
    my $notify_list                  = $args{-notify_list};                     # (Scalar) Optional: list of emails to be notified on arrival
    my $adapter_index_seq            = $args{-adapter_index_seq};               # (ArrayRef) Optional: array of adapter index sequences
    my $well_notes                   = $args{-well_notes};                      # (ArrayRef) Optional: notes to be appended to the primer plate well
    my $alternate_primer_identifiers = $args{-alternate_primer_identifiers};    # (ArrayRef) Optional: alternate_primer_identifiers to add to primers

    my $dbc = $self->{dbc};
    ### ERROR CHECKING ###
    unless ($primer_well_ref) {
        $self->error("ERROR: Missing parameter: Wells not specified");
    }
    unless ($primer_name_ref) {
        $self->error("ERROR: Missing parameter: Primer names not specified");
    }
    unless ($primer_sequence_ref) {
        $self->error("ERROR: Missing parameter: Primer sequences not specified");
    }
    unless ( $tms_working_ref || $tm_calc ) {
        $self->error("ERROR: Missing parameter: Working temperatures or temp calculator not specified");
    }
    if ( ( $primer_type =~ /Amplicon/i ) && ( !($amplicon_length_ref) ) ) {
        $self->error("ERROR: Missing parameter: Amplicon lengths not defined for Amplicon plate");
    }
    unless ($emp_name) {
        $emp_name = &get_username();
    }

    # get employee id and fullname
    # get employee id of user
    my @emp_id_array = $self->{dbc}->Table_find( 'Employee', 'Employee_ID,Employee_FullName', "where Email_Address='$emp_name'" );
    my ( $emp_id, $employee_fullname ) = split ',', $emp_id_array[0];
    unless ( $emp_id =~ /\d+/ ) {
        $self->error("ERROR: Invalid parameter: Employee $emp_name does not exist in database");
    }

    # Errors checked. Return if errors found
    if ( $self->error() ) {
        $self->success(0);
        return 0;
    }

    # cast references to arrays
    my @primer_wells     = @{$primer_well_ref};
    my @primer_names     = @{$primer_name_ref};
    my @primer_sequences = @{$primer_sequence_ref};

    # array length check
    unless ( scalar(@primer_wells) == scalar(@primer_names) ) {
        $self->error("ERROR: Size mismatch: -wells array does not match -name array size");
    }
    unless ( scalar(@primer_wells) == scalar(@primer_sequences) ) {
        $self->error("ERROR: Size mismatch: -wells array does not match -sequence array size");
    }
    if ($tms_working_ref) {
        unless ( scalar(@primer_wells) == scalar( @{$tms_working_ref} ) ) {
            $self->error("ERROR: Size mismatch: -wells array does not match -tm_working array size");
        }
    }

    # error check
    if ( $self->error() ) {
        $self->success(0);
        return 0;
    }

    # chomp all whitespaces from primer names and primer sequences
    my $chomp_counter = 0;
    foreach my $primer (@primer_names) {
        $primer_names[$chomp_counter]     = &RGTools::RGIO::chomp_edge_whitespace( $primer_names[$chomp_counter] );
        $primer_wells[$chomp_counter]     = &RGTools::RGIO::chomp_edge_whitespace( $primer_wells[$chomp_counter] );
        $primer_sequences[$chomp_counter] = &RGTools::RGIO::chomp_edge_whitespace( $primer_sequences[$chomp_counter] );
        $chomp_counter++;
    }

    # set primers in Primer table through Primer.pm
    my $primer_obj = new alDente::Primer( -dbc => $dbc );

    my $datetime = &date_time();
    my $newids_ref;
    my $new_primer_plate_id;

    # use a placeholder Organization
    my ($organization_id) = $self->{dbc}->Table_find( "Organization", "Organization_ID", "WHERE Organization_Name = 'Unknown'" );

    my %primer_id_hash;

    unless ($file_only) {
        if ($tms_working_ref) {
            ( $new_primer_plate_id, $newids_ref ) = $primer_obj->create_primer_plate(
                -primer_names                 => $primer_name_ref,
                -sequences                    => $primer_sequence_ref,
                -type                         => $primer_type,
                -order_date                   => $datetime,
                -status                       => 'To Order',
                -tm_working                   => $tms_working_ref,
                -primer_wells                 => $primer_well_ref,
                -direction                    => $direction_ref,
                -amplicon_length              => $amplicon_length_ref,
                -notes                        => $notes,
                -notify_list                  => $notify_list,
                -organization_id              => $organization_id,
                -emp_id                       => $emp_id,
                -position                     => $position_ref,
                -adapter_index_seq            => $adapter_index_seq,
                -well_notes                   => $well_notes,
                -alternate_primer_identifiers => $alternate_primer_identifiers,
            );
        }
        else {
            ( $new_primer_plate_id, $newids_ref ) = $primer_obj->create_primer_plate(
                -primer_names                 => $primer_name_ref,
                -sequences                    => $primer_sequence_ref,
                -type                         => $primer_type,
                -order_date                   => $datetime,
                -status                       => 'To Order',
                -tm_calc                      => $tm_calc,
                -primer_wells                 => $primer_well_ref,
                -direction                    => $direction_ref,
                -amplicon_length              => $amplicon_length_ref,
                -notes                        => $notes,
                -notify_list                  => $notify_list,
                -organization_id              => $organization_id,
                -emp_id                       => $emp_id,
                -position                     => $position_ref,
                -adapter_index_seq            => $adapter_index_seq,
                -well_notes                   => $well_notes,
                -alternate_primer_identifiers => $alternate_primer_identifiers,
            );
        }
    }

    # error check
    if ( $newids_ref == 0 ) {
        $self->error( $primer_obj->error() );
        $self->success(0);
        return 0;
    }

    # create solution ID

    # save primer order information into object
    my $counter = 0;

    # the format for the order array is primer_order_number,name,well,sequence
    foreach my $primer (@primer_names) {
        my $row = "";

        # add plate_order_number
        $row .= $self->{plate_order_number} . ",";

        # add primer name
        $row .= "$primer,";

        # add well
        $row .= $primer_wells[$counter] . ",";

        # add sequence
        $row .= $primer_sequences[$counter];
        $counter++;
        push( @{ $self->{order_array} }, $row );
    }
    $self->{plate_order_number} += 1;

    $self->success(1);

    $primer_id_hash{primer_ids}      = $newids_ref;
    $primer_id_hash{primer_plate_id} = $new_primer_plate_id;

    return \%primer_id_hash;

}

###############################################################
# Subroutine: Set a message and send an email about a primer order
# Return: 1 if successful, 0 otherwise
###############################################################
sub send_primer_order {
###################
    my $self     = shift;
    my %args     = @_;
    my $emp_name = $args{-emp_name};
    my $emp_id   = $args{-emp_id};
    my $group    = $args{-group};      ## indicate group (allows filtering of email messages)

    my $req_tag = $args{ -
            request_range }; # (Scalar) The range of rearray_requests that this primer order covers in dash-separated values. For example 1-5. If not defined, the order filename will have a single dash replacing the rearray range, and it will start with a sequential number. Supersedes primer_plate_range
    my $primer_plate_tag = $args{ -
            primer_plate_range }; # (Scalar) The range of primer plates that this primer order covers in dash-separated values. For example 1-5. If not defined, the order filename will have a single dash replacing the range, and it will start with a sequential number. Superseded by -request_range.
    my $notify_list = $args{-notify_list};    # (Scalar) Comma-delimited list of additional emails to send to
    my $debug       = $args{-debug};          ## enables testing (redirects email notifications)

    my $dbc      = $self->{dbc};
    my $homelink = $dbc->homelink();

    my @groups = Cast_List( -list => $group, -to => 'array', -autoquote => 0 );
    $group = $groups[0] if ( int(@groups) );    # use the first one if multiple grps are passed in
    my $group_name = $group;
    if ( $group =~ /^\d+$/ ) {
        ($group_name) = $self->{dbc}->Table_find( "Grp", "Grp_Name", "WHERE Grp_ID=$group" );
    }

    unless ($emp_name) {
        $emp_name = &get_username();
    }

    # get employee id and fullname
    # get employee id of user
    my $employee_fullname = '';
    if ($emp_id) {
        ($employee_fullname) = $self->{dbc}->Table_find( 'Employee', 'Employee_FullName', "where Employee_ID='$emp_id'" );
    }
    else {
        my @emp_id_array = $self->{dbc}->Table_find( 'Employee', 'Employee_ID,Employee_FullName', "where Email_Address='$emp_name'" );
        ( $emp_id, $employee_fullname ) = split ',', $emp_id_array[0];
    }

    unless ( $emp_id =~ /\d+/ ) {
        $self->error("ERROR: Invalid parameter: Employee $emp_name does not exist in database");
        return 0;
    }

    # list of Primer_Plate_IDs
    my @primer_plate_ids = ();

    # find all relevant primer plate ids
    my @primer_array = ();
    if ($primer_plate_tag) {
        my $range = &resolve_range($primer_plate_tag);
        @primer_array = $self->{dbc}->Table_find( "Primer_Plate_Well,Primer", "FK_Primer_Plate__ID", "WHERE FK_Primer__Name=Primer_Name AND FK_Primer_Plate__ID in ($range) ORDER BY FK_Primer_Plate__ID,Well" );
        @primer_plate_ids = @{ &unique_items( \@primer_array ) };
    }
    else {
        @primer_plate_ids = @{ $self->get_primer_plates( -request_range => $req_tag ) };
    }

    my $maker_email = $emp_name;

    #    my @mail = @lab_admin_emails;
    my @mail = @{ &alDente::Employee::get_email_list( $dbc, 'lab admin', -group => $group ) };
    push( @mail, $maker_email );
    push( @mail, split( ',', $notify_list ) );
    my $target_list = join ',', @mail;

    # generate link to primer plates
    my $ids = join( ',', @primer_plate_ids );

    my $id_range = &convert_to_range($ids);
    if ( !$homelink ) {
        my $version = 'SDB';
        $version .= "_$Configs{version_name}" if $Configs{version_name} ne 'production';
        $homelink = "$Configs{URL_domain}/$version/cgi-bin/barcode.pl";
    }
    my $link = Link_To( $homelink, "Primer Order ${id_range} from $employee_fullname", "&View+Primer+Plates=1&Primer+Plate+ID=$id_range", "$Settings{LINK_COLOUR}", ["newwin"] );

    # email supplies with order and write order file to disk at /home/sequence/alDente/Orders/Oligos if it's an Oligo ReArray and it has been ordered
    #    &alDente::Notification::Email_Notification($target_list,'aldente@bcgsc.ca',"Primer Order from $employee_fullname","$link",undef,'html',-append=>"primer_order.txt",-testing=>$debug);

#++++++++++++++++++++++++++++++ Subscription Module version of the Notification
#    my $tmp = alDente::Subscription->new(-dbc=>$dbc);
#append email to a different file than primer_order.txt or else we get duplicates in the bulk email
#    my $ok = $tmp->send_notification(-name=>"Primer Order from Employee",-from=>'aldente@bcgsc.ca',-subject=>"Primer Order from $employee_fullname (from Subscription Module)",-body=>"$link",-content_type=>'html',-testing=>1,-append=>"primer_order_subscription.txt");
    my $ok = alDente::Subscription::send_notification(
        -dbc          => $dbc,
        -to           => $target_list,
        -name         => "Primer Order from Employee",
        -from         => 'aldente@bcgsc.ca',
        -subject      => "Primer Order from $employee_fullname (from Subscription Module)",
        -body         => "$link",
        -content_type => 'html',
        -testing      => 0,
        -append       => "primer_order_subscription.txt"
    );

    #++++++++++++++++++++++++++++++

    my $msg_obj = new alDente::Messaging( -dbc => $dbc );
    my $admin_grp;
    if ( $group_name =~ /MGC/ ) {
        $admin_grp = 'MGC_Closure Admin';
    }
    elsif ( $group_name =~ /Cap_Seq/ ) {
        $admin_grp = 'Cap_Seq Admin';
    }
    elsif ( $group_name =~ /Lib_Construction TechD/ ) {
        $admin_grp = 'Lib_Construction TechD Admin';
    }
    elsif ( $group_name =~ /Lib_Construction/ ) {
        $admin_grp = 'Lib_Construction Admin';
    }

    $msg_obj->add_message( -text => "$link", -user => $emp_id, -type => "Group", -grp_name => $admin_grp );
    return 1;
}

###############################################################
# Subroutine: Processes a filehandle that represents a yield report.
# RETURN: returns the number of records changed
###############################################################
sub process_yield_report {
#######################
    my $self  = shift;
    my %args  = @_;
    my $fh    = $args{-fh};
    my $type  = $args{-type};
    my $debug = $args{-debug};    ## enables testing (redirects email notifications)

    my $dbc     = $self->{dbc};                 # SDB::DBIO->new(-dbh=>$dbh,-connect=>0);
    my $user_id = $dbc->get_local('user_id');

    my %oligo_hash;

    #my $yield_dir = "/home/aldente/private/logs/Orders/Yield_Reports";
    my $yield_dir = $yield_reports_dir;

    my $group          = $args{-group};                                ## specify interested group (to filter email notification lists)
    my $department     = $args{-department} || $Current_Department;    ## specify interested department (to filter email notification lists)
    my $project        = $args{-project};                              ## specify interested project (to filter email notification lists)
    my $suppress_print = $args{-suppress_print};

    # import Primer_Order.pm
    require Sequencing::Primer_Order;

    # save this file first to Yield_Reports
    # save in random file name first
    my $outfile_name = timestamp() . ".temp.xls";
    my $buffer       = '';
    my $outfile;
    open( $outfile, ">$yield_dir/$outfile_name" );
    binmode($outfile);                                                 # change to binary mode
    while ( read( $fh, $buffer, 1024 ) ) {
        print $outfile $buffer;
    }
    close($outfile);

    # close original filestream
    close($fh);

    my $filename = "$yield_dir/$outfile_name";

    # parse yield report to hash format
    if ( $type =~ /Illumina|Invitrogen|IDT/ ) {
        my $oligo_hashref = &Sequencing::Primer_Order::read_yield_report( -type => $type, -file => "$filename" );
        if ( !$oligo_hashref || ( int( keys(%$oligo_hashref) ) == 0 ) ) {
            Message("ERROR: Input Error: Cannot Parse Yield Report");
            $self->error("ERROR: Input Error: Cannot Parse Yield Report");
            return;
        }
        %oligo_hash = %{$oligo_hashref};
    }
    else {
        Message("Cannot process yield report");
        $self->error("ERROR: Input Error: Invalid Yield Report Type");
        return;
    }

    # # check if a primer order matches the yield report
    # if there is no match, then there is an error
    # if there is a match, receive the primer plates and print barcodes
    # look for rearrays that exactly match the primer order and apply them as well
    # send error notifications for partial matches.
    my %notifications;

    my @orders = ();
    foreach my $order_id ( keys %oligo_hash ) {
        my $oligo_order_arrayref = $oligo_hash{$order_id};

        # grab rearray request that is on order that matches this primer order
        my @condition_array   = ();
        my @primer_name_array = ();

        foreach my $primer_row ( @{$oligo_order_arrayref} ) {
            my ( $primer_name, $well, $solution_id ) = @{$primer_row};
            $well = &format_well($well);
            if ($solution_id) {
                push( @condition_array, " (FK_Primer__Name = '$primer_name' AND Well = '$well') and FK_Solution__ID = $solution_id " );
            }
            else {
                push( @condition_array, " (FK_Primer__Name = '$primer_name' AND Well = '$well') " );
            }
            push( @primer_name_array, $primer_name );
        }

        # do query

        my @request_primerplate = $self->{dbc}
            ->Table_find( "Primer_Plate,Primer_Plate_Well", "Primer_Plate_ID", "WHERE (" . join( " OR ", @condition_array ) . ") AND (Primer_Plate_Status = 'Ordered' OR Primer_Plate_Status = 'To Order') AND FK_Primer_Plate__ID=Primer_Plate_ID" );

        # if nothing matches, do not use specific reject this specific yield entry
        if ( scalar(@request_primerplate) == 0 ) {
            Message("ERROR: Input Error: No Ordered primer order matches this Yield Report $order_id");
            $self->error("ERROR: Input Error: No Ordered primer order matches this Yield Report $order_id");
            next;
        }

        @request_primerplate = @{ &unique_items( \@request_primerplate ) };
        if ( scalar(@request_primerplate) > 1 ) {
            my @primer_plate_array = ();
            foreach (@request_primerplate) {
                push( @primer_plate_array, $_ );
            }
            Message( "ERROR: Input Error: More than one Ordered primer order (" . join( ',', @primer_plate_array ) . ") matches this Yield Report" );
            $self->error( "ERROR: Input Error: More than one Ordered primer order (" . join( ',', @primer_plate_array ) . ") matches this Yield Report" );
            next;
        }
        my ($primer_plate_id) = @request_primerplate;

        ## create a solution id for the primer plate if necessary
        my ($solution_id) = $self->{dbc}->Table_find( "Primer_Plate", "FK_Solution__ID", "WHERE Primer_Plate_ID=$primer_plate_id" );
        unless ($solution_id) {

            # get the organization ID
            my ($organization_id) = $self->{dbc}->Table_find( "Organization", "Organization_ID", "WHERE Organization_Name = '$type'" );

            # get the group ID
            my ($grp_id) = $self->{dbc}->Table_find( "Grp", "Grp_ID", "WHERE Grp_Name = 'Cap_Seq Production'" );
            ## For Stock Insert
            my ($notes) = $self->{dbc}->Table_find( "Primer_Plate", "Notes", "WHERE Primer_Plate_ID=$primer_plate_id" );
            my $cat_number = "$order_id";

            #if ($notes) {
            #    $cat_number = "$notes $cat_number";
            #}
            #Message("Cat number $cat_number");
            my ($barcode_id) = $self->{dbc}->Table_find( "Barcode_Label", "Barcode_Label_ID", "WHERE Label_Descriptive_Name='1D Small Solution Labels'" );

            my ($stock_catalog_id) = $self->{dbc}->Table_find( "Stock_Catalog", "Stock_Catalog_ID", "WHERE Stock_Catalog_Name = 'Custom Oligo Plate' AND Stock_Type = 'Reagent' AND FK_Organization__ID = $organization_id AND Stock_Source = 'Order' " );

            unless ($stock_catalog_id) {
                my @catalog_fields = qw(Stock_Catalog_Name Stock_Catalog_Number Stock_Type  Stock_Source    Stock_Size  Stock_Size_Units    FK_Organization__ID FKVendor_Organization__ID   Stock_Status);
                my @catalog_values = ( 'Custom Oligo Plate', $cat_number, 'Reagent', 'Order', 1, 'n/a', $organization_id, $organization_id, 'Active' );
                $stock_catalog_id = $self->{dbc}->Table_append_array( "Stock_Catalog", \@catalog_fields, \@catalog_values, -autoquote => 1 );
            }

            my @fields = ( 'Stock_Catalog_ID', 'Stock_Received', 'Identifier_Number', 'Stock_Lot_Number', 'FK_Employee__ID', 'Stock_Cost', 'Stock_Number_in_Batch', 'FK_Grp__ID', 'FK_Barcode_Label__ID' );
            my @values = ( $stock_catalog_id, &today(), $cat_number, '', $user_id, 0, 1, $grp_id, $barcode_id );

            ## For Solution Info insert
            push( @fields, ( 'nMoles', 'OD', 'micrograms' ) );
            push( @values, ( 0,        0,    0 ) );
            ## For Solution insert
            push( @fields, ( 'Solution_Type', 'Solution_Started', 'Solution_Expiry', 'Quantity_Used', 'FK_Rack__ID', 'Solution_Status', 'Solution_Number', 'Solution_Number_in_Batch' ) );
            push( @values, ( 'Primer', '', '', '', 1, 'Unopened', 1, 1 ) );
            $dbc->smart_append( -tables => "Stock,Solution,Solution_Info", -fields => \@fields, -values => \@values, -autoquote => 1 );

            # get solution id and print barcode
            my $new_sol_id = $dbc->newids( 'Solution', 0 );
            $solution_id = $new_sol_id;
        }

        # assign oligo order without rearray ids
        $self->assign_oligo_order( -order_num => $order_id, -sol_id => "sol$solution_id", -primer_plate_id => $primer_plate_id );
        if ($suppress_print) {
            Message("Generating barcode sol$solution_id, not printing");
        }
        else {
            &alDente::Barcoding::PrintBarcode( $dbc, 'Solution', "$solution_id" );
        }
        push( @orders, $order_id );

        # send out notification to the Notify_List of the Primer_Plate table
        my @emails_array = $self->{dbc}->Table_find_array( 'Primer_Plate', ['Notify_List'], "where Primer_Plate_ID=$primer_plate_id" );

        # split the emails and add to email list
        my @emails = ();
        if ( ( $emails_array[0] != '' ) || ( $emails_array[0] !~ /NULL/ ) ) {
            @emails = split ',', $emails_array[0];
        }

        # compile emails, keyed by email address
        if ( scalar(@emails) > 0 ) {
            my $homelink = $dbc->homelink( -clear => 'CGISESSID' );
            my $url_location = Link_To( $homelink, "$order_id", "&View+Primer+Plate=1&Primer+Plate+ID=$primer_plate_id", "$Settings{LINK_COLOUR}", ["newwin"] );
            foreach my $email (@emails) {
                if ( defined $notifications{$email} ) {
                    push( @{ $notifications{$email} }, "Received Primer Order $order_id (Primer Plate ID $primer_plate_id)\n\n$url_location" );
                }
                else {
                    $notifications{$email} = ["Received Primer Order $order_id (Primer Plate ID $primer_plate_id)\n\n$url_location"];
                }
            }
        }
    }

    foreach my $email ( keys %notifications ) {
        my $body_str = join( '\n<BR>', @{ $notifications{$email} } );

        # &alDente::Notification::Email_Notification($email,'aldente@bcgsc.bc.ca','Received Primer Order',$body_str,undef,'html',-testing=>$debug) if $email;
        if ($email) {

            #++++++++++++++++++++++++++++++ Subscription Module version of the Notification
            #Are we going to do anything about attachments
            # my $tmp = alDente::Subscription->new(-dbc=>$dbc);

            # my $ok = $tmp->send_notification(-name=>"Received Primer Order",-to=>'aldente',-from=>'aldente@bcgsc.ca',-subject=>'Received Primer Order (from Subscription Module)',-body=>$body_str.$email,-content_type=>'html',-testing=>1);
            my $ok = alDente::Subscription::send_notification(
                -dbc          => $dbc,
                -to           => $email,
                -name         => "Received Primer Order",
                -from         => 'aldente@bcgsc.ca',
                -subject      => 'Received Primer Order (from Subscription Module)',
                -body         => $body_str,
                -content_type => 'html',
                -testing      => 0
            );

            #++++++++++++++++++++++++++++++
        }

    }

    # look for rearrays that have been partially ordered - if set of primer plates completed them, set them to Waiting for Preps as well
    my %completed = $dbc->Table_retrieve(
        "ReArray_Request,
											Status,ReArray,
											Plate_PrimerPlateWell,
											Primer_Plate_Well,
											Primer_Plate",
        [ "ReArray_Request_ID", "Primer_Plate_Status" ],
        "WHERE FK_ReArray_Request__ID=ReArray_Request_ID AND 
											(Target_Well=Plate_Well AND 
											FKTarget_Plate__ID=FK_Plate__ID) AND 
											FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND 
											FK_Primer_Plate__ID=Primer_Plate_ID AND 
											FK_Status__ID=Status_ID AND 
											Status_Name='Waiting for Primers'", 'distinct'
    );
    my %check_hash;
    if ( defined $completed{ReArray_Request_ID} ) {
        foreach ( 1 .. scalar( @{ $completed{ReArray_Request_ID} } ) ) {
            my $request_id          = $completed{ReArray_Request_ID}[ $_ - 1 ];
            my $primer_plate_status = $completed{Primer_Plate_Status}[ $_ - 1 ];

            # check to see if the request ID has been defined
            $check_hash{$request_id}{$primer_plate_status} = 1;
        }
    }
    my @completed_ids = ();

    # if all values were received, then switch rearray to reserved status
    foreach my $request_id ( keys %check_hash ) {
        if ( !( ( exists $check_hash{$request_id}{'Ordered'} ) || ( exists $check_hash{$request_id}{'To Order'} ) ) ) {
            push( @completed_ids, $request_id );
        }
    }

    # update into reserved status if necessary
    if ( scalar(@completed_ids) > 0 ) {
        $self->autoset_primer_rearray_status( -rearray_ids => \@completed_ids, -group => $group, -department => $department );
    }

    # rename the yield report
    my $newname = "/home/aldente/public/logs/Orders/Yield_Reports/Yield_Report.P." . join( '.', @orders );
    try_system_command("mv -f $yield_dir/$outfile_name $newname");

    return;
}

# RETURN: returns the number of records changed
###############################################################
sub assign_oligo_order {
######################
    my $self            = shift;
    my %args            = @_;
    my $oligo_order     = $args{-order_num};
    my $rearray_id      = $args{-rearray_id};
    my $primer_plate_id = "";
    $primer_plate_id = $args{-primer_plate_id};
    my $sol_id = $args{-sol_id};
    my $dbc    = $self->{dbc};

    my $group           = $args{-group};    ## indicate group (allows filtering of email messages)
    my $num_rec_changed = 0;                # set the oligo name if necessary
    if ( $oligo_order && $sol_id && ( $rearray_id || $primer_plate_id ) ) {

        # error check
        unless ($sol_id) {
            Message("No solution id defined..");
            $sol_id = 0;
            return 0;
        }
        unless ($oligo_order) {
            Message("No external order number defined..");
            return 0;
        }

        $sol_id =~ s/sol//;

        my $datetime = &date_time();

        ### if no rearray_id is given, just assign the Primer_Plate (a primer plate ID has to be given)
        # update the primer_external_order number
        # if the primer_external_order number is not set, update the Primer_Plate record
        # otherwise skip
        if ($rearray_id) {

            # get the primer names (from Primer_ReArray)
            ($primer_plate_id) = $self->{dbc}->Table_find_array(
                'ReArray_Request,ReArray,Plate_PrimerPlateWell,Primer_Plate_Well', ['FK_Primer_Plate__ID'], "where FK_ReArray_Request
__ID=ReArray_Request_ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND Plate_Well=Target_Well AND FKTarget_Plate__ID=FK_Plate__ID AND ReArray_Request_ID=$rearray_id lim
it 1"
            );
        }

        my $ok = 0;
        my ($primer_plate_name) = $self->{dbc}->Table_find( "Primer_Plate", "Primer_Plate_Name", "where Primer_Plate_ID=$primer_plate_id" );
        if ( $primer_plate_name eq "" ) {
            $primer_plate_name = $oligo_order;
        }
        $ok = $self->{dbc}
            ->Table_update_array( 'Primer_Plate', [ 'Primer_Plate_Name', 'Arrival_DateTime', 'Primer_Plate_Status', 'FK_Solution__ID' ], [ "'$primer_plate_name'", "'$datetime'", "'Received'", $sol_id ], "where Primer_Plate_ID=$primer_plate_id" );

        $num_rec_changed += $ok;
        unless ($rearray_id) {
            return $num_rec_changed;
        }
    }

    if ($rearray_id) {
        $self->autoset_primer_rearray_status( -rearray_ids => [$rearray_id] );
    }
    return $num_rec_changed;
}
##########################################
# Function: autosets primer rearray status, and sends emails if necessary
# Return: 1 if successful, 0 otherwise.
##########################################
sub autoset_primer_rearray_status {
##########################################
    my $self = shift;

    my %args        = &filter_input( \@_ );
    my $rearray_ids = $args{-rearray_ids};
    my $group       = $args{-group};
    my $department  = $args{-department};
    my $debug       = $args{-debug};          ## enables testing (redirects email notifications)

    my $dbc = $self->{dbc};

    unless ($rearray_ids) {
        Message("No rearray ids defined");
        return 0;
    }
    if ( int(@$rearray_ids) == 0 ) {
        Message("No rearray ids defined");
        return 0;
    }

    my @links       = ();
    my @email_list  = ();
    my @prep_list   = ();
    my @ready_list  = ();
    my @primer_list = ();

    foreach my $request_id ( sort { $a <=> $b } @$rearray_ids ) {
        my $ready_rearray           = 0;
        my @undefined_source_plates = $self->{dbc}->Table_find( 'ReArray', "FKSource_Plate__ID", "WHERE FK_ReArray_Request__ID = $request_id AND FKSource_Plate__ID=0" );
        my @ordered_primer_plates   = $self->{dbc}->Table_find(
            "ReArray,ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well,Primer_Plate",
            "distinct Primer_Plate_ID",
            "WHERE FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID=FK_Plate__ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND FK_Primer_Plate__ID=Primer_Plate_ID AND (Primer_Plate_Status='To Order' OR Primer_Plate_Status='Ordered') AND ReArray_Request_ID = $request_id"
        );

        # if there are both no undefined source plates and all primer plates have been received, then set to Ready
        if ( ( int(@undefined_source_plates) == 0 ) && ( int(@ordered_primer_plates) == 0 ) ) {
            my ($status_id) = $self->{dbc}->Table_find( "Status", "Status_ID", "WHERE Status_Name = 'Ready for Application'" );
            $self->{dbc}->Table_update_array( "ReArray_Request", ['FK_Status__ID'], [$status_id], "WHERE ReArray_Request_ID = $request_id" );
            push( @ready_list, $request_id );
            $ready_rearray = 1;
        }

        # if there are undefined source plates but no more primer plates to order, then set to Waiting for Preps
        elsif ( ( int(@undefined_source_plates) > 0 ) && ( int(@ordered_primer_plates) == 0 ) ) {
            my ($status_id) = $self->{dbc}->Table_find( "Status", "Status_ID", "WHERE Status_Name = 'Waiting for Preps'" );
            $self->{dbc}->Table_update_array( "ReArray_Request", ['FK_Status__ID'], [$status_id], "WHERE ReArray_Request_ID = $request_id" );
            push( @prep_list, $request_id );
        }

        # if there are still primer plates on order, set to Waiting for Primers
        else {
            my ($status_id) = $self->{dbc}->Table_find( "Status", "Status_ID", "WHERE Status_Name = 'Waiting for Primers'" );
            $self->{dbc}->Table_update_array( "ReArray_Request", ['FK_Status__ID'], [$status_id], "WHERE ReArray_Request_ID = $request_id" );
            push( @primer_list, $request_id );
        }

        # if a rearray has been set to ready, then send emails
        if ($ready_rearray) {

            # get employee name and email
            my @employee_info = $self->{dbc}->Table_find_array( 'Employee,ReArray_Request', [ 'Employee_FullName', 'Email_Address' ], "where FK_Employee__ID=Employee_ID and ReArray_Request_ID=$request_id" );
            my ( $emp_name, $emp_email ) = split ",", $employee_info[0];

            # get the other emails of interested people from ReArray_Notify
            my @other_emails_array = $self->{dbc}->Table_find_array( 'ReArray_Request', ['ReArray_Notify'], "where ReArray_Request_ID=$request_id" );

            # split the emails and add to email list
            my @other_emails = ();
            if ( ( $other_emails_array[0] != '' ) || ( $other_emails_array[0] !~ /NULL/ ) ) {
                @other_emails = split ',', $other_emails_array[0];
            }

            # send email to lab_administrators that a rearray is ready to be applied
            my @emails = @{ &alDente::Employee::get_email_list( $dbc, 'lab admin', -group => $group, -department => $department, -project => $project ) };
            push( @emails, @other_emails, $emp_email );

            push( @email_list, @emails );
            @email_list = @{ &unique_items( \@email_list ) };
            my $url_location .= Link_To( $dbc->config('homelink'), "Rearray $request_id", "Request_ID=$request_id&Expand+ReArray+View=1&Order=Target_Well", "$Settings{LINK_COLOUR}" );
            push( @links, $url_location );
        }
    }

    my $target_list = join ',',    @email_list;
    my $message     = join '<BR>', @links;
    &alDente::Notification::Email_Notification( $target_list, 'aldente@bcgsc.bc.ca', 'Primer ReArray ready for application', "Primer Rearrays ready to be applied: <BR> $message", undef, 'html', -append => "rearray_ready.txt", -testing => $debug );

    #++++++++++++++++++++++++++++++ Subscription Module version of the Notification
    #Are we going to do anything about attachments
    my $tmp = alDente::Subscription->new( -dbc => $dbc );

    my $ok = $tmp->send_notification(
        -name         => "Primer ReArray ready for application",
        -from         => 'aldente@bcgsc.ca',
        -subject      => 'Primer ReArray ready for application (from Subscription Module)',
        -body         => "Primer Rearrays ready to be applied: <BR> $message",
        -content_type => 'html',
        -testing      => 1,
        -append       => "rearray_ready_subscription.txt"
    );

    #++++++++++++++++++++++++++++++

    if ( int(@prep_list) > 0 ) {
        Message("The following rearrays have been set to Waiting for Preps");
        Message( join( ',', @prep_list ) );
    }
    if ( int(@ready_list) > 0 ) {
        Message("The following rearrays have been set to Ready for Appplication");
        Message( join( ',', @ready_list ) );
    }
    return 1;
}

######################
sub delete_primer_plate_orders {
######################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $dbc        = $self->{dbc};
    my $ids        = $args{-ids};
    my $original   = $self->is_primer_plate_orginal( -ids => $ids );
    my $rearray_id = $self->get_rearray_id_if_new( -ids => $ids );
    my $error;    ## Begin with no erros

    #####   Start transaction   ####
    $dbc->start_trans( -name => 'delete_primer_plate' );

    if ($rearray_id) {
        Message "tryin to delete $rearray_id";

        my $ok = $dbc->delete_records( -table => 'ReArray_Request', -field => 'Rearray_Request_ID', -id_list => $rearray_id, -cascade => get_cascade_tables('ReArray_Request'), -quiet => 1 );
        unless ($ok) { $error = 'cant delete rearray request record' }
    }
    if ($original) {
        my $success = $self->delete_primers_for_plate( -id => $ids );
        unless ($success) { $error = 'cant delete primer' }
    }

    my ($stock_id) = $dbc->Table_find( 'Primer_Plate,Solution', 'FK_Stock__ID', " WHERE Primer_Plate_ID = $ids AND FK_Solution__ID = Solution_ID " );

    my $ok = $dbc->delete_records( -table => 'Stock', -field => 'Stock_ID', -id_list => $stock_id, -quiet => 1, -cascade => get_cascade_tables( 'Stock', 'Primer' ) );

    unless ($ok) { $error = 'cant delete stock' }
    $dbc->finish_trans( 'delete_primer_plate', -error => $error );
    #####   End transaction   ####

    if   ($ok) { Message "deleted primer plate $ids and related records" }
    else       { Message "Failed to deleted $ids and related records" }
    return;
}

######################
sub delete_primers_for_plate {
######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $ids  = $args{-id};
    my $error;
    my @primer_names = $dbc->Table_find( 'Primer_Plate_Well', 'FK_Primer__Name', " WHERE FK_Primer_Plate__ID = $ids " );
    my $primer_obj = new alDente::Primer( -dbc => $dbc );

    for my $name (@primer_names) {
        my $ok = $primer_obj->delete_Primer( -name => $name );
        unless ($ok) { $error = 1 }
    }
    return !($error);
}

######################
sub is_primer_plate_orginal {
######################
    # returns:
    #       0 if not original
    #       1 if original
######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $ids  = $args{-ids};
    ## If the wells have parents they are not original
    my $parent_ids_found = $dbc->Table_find( 'Primer_Plate_Well', 'distinct FKParent_Primer_Plate_Well__ID', " WHERE FK_Primer_Plate__ID = $ids and FKParent_Primer_Plate_Well__ID is NOT NULL and FKParent_Primer_Plate_Well__ID > 0" );
    if   ($parent_ids_found) {return}
    else                     { return 1 }
}

######################
sub confirm_deletion_validity {
######################
    # return 0 if not accepted 1 if givin permission to delete
######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $ids  = $args{-ids};           ## one single id

    my $session_user_id = $dbc->get_local('user_id');
    my ($primer_user_id) = $dbc->Table_find( 'Primer_Plate,Solution,Stock', "FK_Employee__ID",     "WHERE FK_Solution__ID = Solution_ID and Primer_Plate_ID = $ids and FK_stock__ID =Stock_ID" );
    my $lims_admin       = $dbc->Security->{login}->{LIMS_admin};
    my ($status)         = $dbc->Table_find( 'Primer_Plate',                "Primer_Plate_Status", "WHERE Primer_Plate_ID = $ids" );

    if ( $status ne 'To Order' ) {
        Message "Primer Plate $ids has status $status and can not be deleted using this method";
        return;
    }
    if ( ( $session_user_id == $primer_user_id ) || $lims_admin ) {
        ## make sure of primer order belonging to the person running the session
        return 1;
    }
    else {
        my ($employee_name) = $dbc->Table_find( 'Employee', "Employee_Name", "WHERE Employee_ID = '$primer_user_id'" );
        Message "Primer Plate $ids belongs to $employee_name and can only be deleted by them or LIMS admin.";
        return;
    }
}

######################
sub get_rearray_id_if_new {
######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $ids  = $args{-ids};
    my @approved_rr_ids;
    my @rr_info = $dbc->Table_find(
        'ReArray_Request, Plate_PrimerPlateWell, Primer_Plate_Well',
        "Request_DateTime, ReArray_Request_ID",
        "WHERE  FKTarget_Plate__ID = FK_Plate__ID  and FK_Primer_Plate_Well__ID = Primer_Plate_Well_ID and FK_Primer_Plate__ID = $ids group by ReArray_Request_ID"
    );

    my ($pp_datetime) = $dbc->Table_find( 'Primer_Plate', "Order_DateTime", "WHERE  Primer_Plate_ID = $ids" );
    my $size = @rr_info;

    for my $rr_info_line (@rr_info) {
        my ( $rr_datetime, $rr_id )   = split ',', $rr_info_line;
        my ( $rr_date,     $rr_time ) = split " ", $rr_datetime;
        my ( $pp_date,     $pp_time ) = split " ", $pp_datetime;
        my $diff = _diff_time( $pp_time, $rr_time );

        if ( $diff < 60 && $rr_date eq $pp_date ) { push @approved_rr_ids, $rr_id }

    }

    my $approved = RGTools::RGIO::unique_items( \@approved_rr_ids );
    return join ',', @approved_rr_ids;
}

##############################
# private_functions          #
##############################
sub _diff_time {
    my $a_time = shift;
    my $b_time = shift;
    my ( $a_hour, $a_min, $a_sec ) = split ":", $a_time;
    my ( $b_hour, $b_min, $b_sec ) = split ":", $b_time;
    my $a_total = $a_sec + $a_min * 60 + $a_hour * 360;
    my $b_total = $b_sec + $b_min * 60 + $b_hour * 360;
    my $diff    = $a_total - $b_total;                    ## in seconds
    if   ( $diff > 0 ) { return $diff }
    else               { return $diff * -1 }

}

return 1;

__END__;
##############################
# perldoc_header             #
##############################
=head1 NAME <UPLINK>

<module_name>

=head1 SYNOPSIS <UPLINK>


## Primer Plate Handling ##################################

## Primer Plate Object
	##  Primer Plate
	##  Primer Plate Well
		##  Primers - Mapping of Primers to Wells
	##  Application to of Primer Plate to a Plate Object (Plate_PrimerPlateWell)
		## 384-well vs 96-well mapping
	##  Summary for Primer Plates
	##  Remapping (ReArraying) of Primers on Primer Plates to create new Primer Plates
	##  Solution/Stock Record

Primer_Plate

`Primer_Plate_ID` int(11) NOT NULL auto_increment,
`Primer_Plate_Name` text,
`Primer_Plate_Type` enum('Primer_Plate','') default '',
`Order_DateTime` datetime default NULL,
`Arrival_DateTime` datetime default NULL,
`Primer_Plate_Status` enum('To Order','Ordered','Received','Inactive') default NULL,
`FK_Solution__ID` int(11) default NULL,
`Notes` varchar(40) default NULL,
`Notify_List` text,
`FK_Lab_Request__ID` int(11) default NULL,

Notes:

- Primer Plates have a solution id and are barcoded
- Notify List should be replaced by subscriptions
- Lab_Request is used to associate a set of ordered primer plates with the ReArray of samples 
- Notes field can appear on the barcode
- Add Primer_Plate_Type 

Primer_Plate_Well

`Primer_Plate_Well_ID` int(11) NOT NULL auto_increment,
`Well` char(3) default NULL,
`FK_Stock_Item__ID` int(11) NOT NULL default 0,
`FK_Primer_Plate__ID` int(11) default NULL,
`FKParent_Primer_Plate_Well__ID` int(11) NOT NULL default '0',

Notes: 

- Details of what primer is mapped to which well on the primer plate
- Can be remapped onto another primer plate  
- FK_Primer__Name to FK_Stock_Item__ID



Usage:

=head1 DESCRIPTION <UPLINK>

<description>

=for html

=head1 KNOWN ISSUES <UPLINK>
    
None.    

=head1 FUTURE IMPROVEMENTS <UPLINK>
    
=head1 AUTHORS <UPLINK>
    
    

=head1 CREATED <UPLINK>
    
    <date>

=head1 REVISION <UPLINK>
    
    <version>

=cut
