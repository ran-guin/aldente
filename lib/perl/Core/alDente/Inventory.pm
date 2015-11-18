package alDente::Inventory;

@ISA = qw(SDB::DB_Object);

use strict;
use CGI qw(:standard);

## alDente modules
use alDente::Equipment;
use alDente::Rack;
use alDente::Rack_Views;
use alDente::Form;            ## for Set_Parameters();
use alDente::SDB_Defaults;    ## for config paths

## SDB modules
use SDB::DBIO;
use alDente::Validation;
use SDB::HTML;
use SDB::CustomSettings;

## RG Tools
use RGTools::RGIO;
use RGTools::RGmath;
use RGTools::Views;
use vars qw($Connection %Prefix $URL_version);
use vars qw($inventory_dir $inventory_test_dir);

# Constructor method for the Inventory object
#
##########
sub new {
##########
    my $this   = shift;
    my $class  = ref($this) || $this;
    my %args   = filter_input( \@_ );
    my $id     = $args{-id};
    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $tables = 'Maintenance';

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => $tables );

    if ($id) {
        $self->load_Object( -id => $id );
    }
    $self->{dbc}     = $dbc;
    $self->{records} = 0;
    if ( !$dbc->test_mode() ) {

        #$self->{inventory_dir} = "/home/aldente/private/Inventory";
        $self->{inventory_dir} = $inventory_dir;
    }
    else {

        #$self->{inventory_dir} = "/home/aldente/private/Inventory/test";
        $self->{inventory_dir} = $inventory_test_dir;
    }
    bless $self, $class;
    return $self;
}

# Load the information specific to the Inventory object
#
##################
sub load_Object {
##################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'id' );
    my $id   = $args{-id};
    $self->{id} = $id if $id;
    my $tables = 'Maintenance';
    if ($id) {
        $self->{id} = $id;
        $self->primary_value( -table => $tables, -value => $id );

    }
    $self->SUPER::load_Object();
    ## load the running list of items that are in the location (equipment freezer)
    ## Rack -> [Items in rack]
    ## Current number of items scanned

    if ( $self->{id} ) {

        #	$self->load_attributes($self->{id});
        $self->{inventory_file}   = "Inventory_" . $self->{id} . ".txt";
        $self->{FK_Equipment__ID} = $self->get_data('FK_Equipment__ID');
    }
    ## Inventory start date time
    ## Inventory end date time
    ## Inventory Status ('In progress', 'Completed')

    ## Number of items in the location that were not supposed to be there
    ## Number of items not in the location that were supposed to be there
    ## Percentage # of items correctly labelled / # original number of items

    ## Group the inventory is done for

}

# Handle the paramaters for the Inventory module
#
#
#
######################
sub Inventory_Home {
######################

    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $inv  = alDente::Inventory->new( -dbc => $dbc );
    if ( param('Start_Inventory') ) {

        my $equipment = param('FK_Equipment__ID') || param('FK_Equipment__ID Choice');

        #my $rack = param('FK_Rack__ID') || param('FK_Rack__ID Choice');

        my $inventory_id = $inv->create_inventory( -equipment => $equipment );
        $inv->load_Object( -id => $inventory_id );
        $inv->home_page();
    }
    elsif ( param('Update_Inventory_List') ) {
        my $inventory_id      = param('Inventory_ID');
        my $target_item       = param('Target_Item');
        my $item_contents     = param('Item_Contents');
        my $sub_target_item   = param('Sub_Target_Item');
        my $sub_item_contents = param('Sub_Item_Contents');

        #	my $inv = alDente::Inventory->new(-dbc=>$dbc,-id=>$inventory_id);
        $inv->load_Object( -id => $inventory_id );

        $inv->update_inventory( -target_item => $target_item, -item_contents => $item_contents, -sub_target_item => $sub_target_item, -sub_item_contents => $sub_item_contents );
        $inv->home_page();
    }
    elsif ( param('Finish_Inventory_List') ) {
        my $inventory_id = param('Inventory_ID');
        $inv->load_Object( -id => $inventory_id );

        #my $inv = alDente::Inventory->new(-dbc=>$dbc,-id=>$inventory_id);
        $inv->finish_inventory();
    }
    else {
        $inv->home_page();

    }
}

# Home page for the inventory tracker
#
#
#
# Return 1 on success
#################
sub home_page {
#################

    my $self = shift;
    my %args = &filter_input( \@_, -args => 'id' );
    my $id   = $args{-id} || $self->{id};
    my $dbc  = $self->{dbc} || $args{-dbc};

    print alDente::Form::start_alDente_form( $dbc, "Inventory_Form" );
    print hidden( -name => 'Inventory_Home', -value => 1 );

## IF scanner mode
    if ($scanner_mode) {
        ## Display the home page for the scanner
        $self->scanner_home_page( -id => $id );
    }
    else {
        ## Display the home page for the desktop
        $self->desktop_home_page( -id => $id );
    }
    print "</form>";

    return 1;
}

# Display the inventory home page for the desktop
#
#
#
#
#########################
sub desktop_home_page {
#########################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'id' );
    my $id   = $args{-id};

    # Display list of inventories for the group done in the past
    # Display scan field for equipment/freezer for inventory
    if ($id) {
        $self->show_inventory_status();

        ## Display scanner field, update inventory button and finish inventory button
    }
    else {

        $self->display_inventories();
        print "<BR>";
        $self->inventory_form();
    }
    return 1;
}

# Display the inventory home page for the scanner
#
#
#
#
#########################
sub scanner_home_page {
#########################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'id' );
    my $dbc  = $self->{dbc};
    my $id   = $args{-id};

    # Display list of inventories (equipment name and start date time) that are in progress

    # Option to scan in equipment and start from the scanner home page

    # Button to choose the inventory audit to work on

    if ($id) {
        print $self->inventory_scan_page();
    }
    else {
        $dbc->message("Inventory not found");
    }

    return 1;
}

## Allow the lab user to start an inventory on an equipment or a rack
#
#
######################
sub inventory_form {
######################
    my $self           = shift;
    my $dbc            = $self->{dbc};
    my $equipment_scan = alDente::Tools->search_list( -dbc => $dbc, -name => 'FK_Equipment__ID', -default => '', -search => 1, -filter => 1, -breaks => 1, -sort => 1 );

    #    my $rack_scan = alDente::Tools->search_list(-dbc=>$dbc,-name=>'FK_Rack__ID',-default=>'',-search=>1,-filter=>1,-breaks=>1);
    my $inventory_form = HTML_Table->new( -title => 'Start a new inventory' );

    my $start_inventory = submit( -name => "Start_Inventory", -value => "Start Inventory", -class => "Std" );

    $inventory_form->Set_Row( [ "Equipment", $equipment_scan ] );

    #    $inventory_form->Set_Row(["Rack", $rack_scan]);
    $inventory_form->Set_Row( [ "", $start_inventory ] );

    return $inventory_form->Printout();
}

# Create the inventory record
#
# Return 1 on success
#########################
sub create_inventory {
#########################
    my $self      = shift;
    my %args      = &filter_input( \@_, -args => 'equipment,rack' );
    my $equipment = $args{-equipment};                                 ## equipment ID

    #    my $rack = $args{-rack};  ##  rack ID
    my $inventory_directory = $self->{inventory_dir};
    my $dbc                 = $self->{dbc};
    my $user_id             = $dbc->get_local('user_id');

    if ($equipment) {
        $equipment = $dbc->get_FK_ID( 'FK_Equipment__ID', $equipment );

    }
    else {
        $dbc->error("Must specify a rack or equipment");
        return 0;
    }
    ## CHECK if the item is already in an inventory that is in process
    my $check_if_exists = check_if_inventory_exists( -equipment => $equipment );

    if ($check_if_exists) {
        $dbc->error("There is already an inventory in progress for this item");
        return 0;
    }
    ## Record:

    ## Status = In Progress
    ## Start Date Time = &date_time()
    ## End Date Time NULL

    ## Transaction start

    my ($inventory) = $dbc->Table_find( 'Maintenance_Process_Type', 'Maintenance_Process_Type_ID', "WHERE Process_Type_Name='Inventory'" );

    $dbc->start_trans( -name => 'Inventory_create_inventory' );
    my $maintenance_id;
    eval {
        my @maintenance_fields = ( 'Maintenance_ID', 'FK_Equipment__ID', 'FK_Employee__ID', 'FK_Maintenance_Process_Type__ID', 'Maintenance_DateTime', 'Maintenance_Finished', 'FKMaintenance_Status__ID' );
        my ($maint_status_id) = $dbc->Table_find( 'Status', 'Status_ID', "WHERE Status_Type = 'Maintenance' and Status_Name = 'In Process'" );

        my @maintenance_values = ( '', $equipment, $user_id, $inventory, &date_time(), '', $maint_status_id );

        #	my ($attribute) = $dbc->Table_find('Status', 'Status_ID', "WHERE Status_Type = 'Event' and Status_Name = 'In Process'");
        ($maintenance_id) = $dbc->Table_append_array( "Maintenance", \@maintenance_fields, \@maintenance_values, -autoquote => 1 );

        #	my @event_attribute_fields = ('Event_Attribute_ID','FK_Event__ID','FK_Attribute__ID','Attribute_Value');
        #	my @event_attribute_values = ('',$event_id) ;

        #	my ($attribute) = $dbc->Table_find('Attribute', 'Attribute_ID', "WHERE Attribute_Name = '$attribute_name' and Attribute_Class = 'Event'");
        #	push (@event_attribute_values, $attribute);
        #	if ($equipment){
        #	    push (@event_attribute_values, $equipment);
        #	} else {
        #	    push (@event_attribute_values, $rack);
        #	}

        #	my $ok = $dbc->Table_append_array("Event_Attribute", \@event_attribute_fields, \@event_attribute_values,-autoquote=>1);
        ## Create the blank inventory file

        my $file_name = $inventory_directory . "/" . "Inventory_" . $maintenance_id . ".txt";
        open( FILE, ">$file_name" ) or die "Cannot find file '$file_name'\n";
        try_system_command("chmod 777 $file_name");
    };
    $dbc->finish_trans( -name => 'Inventory_create_inventory' );
    ## Transaction finish
    return $maintenance_id;
}

##################################
sub check_if_inventory_exists {
##################################
    my %args = filter_input( \@_, -args => 'equipment' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $equipment = $args{-equipment};

    #    my $item_type = $args{-item_type};

    my ($check_if_exists) = $dbc->Table_find( "Maintenance,Status", "Maintenance_ID", "WHERE FKMaintenance_Status__ID = Status_ID and Status_Name = 'In Process' and FK_Equipment__ID = $equipment" );

    return $check_if_exists;
}

# Given the employee, display all the freezers, inventory date, racks, error percentage
# grouped by inventory date and GSC group (ie Sequencing, MGC Closure)
#
#
# Return HTML Table
#############################
sub display_inventories {
#############################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};

    ## FIND Inventories based on group

    ## Inventory information would include:
    ## Freezers audited
    ## Inventory start date time
    ## Inventory end date time
    ## Inventory Status ('In progress', 'Completed')

    ## IF Inventory completed
    ## Number of items in the location that were not supposed to be there
    ## Number of items not in the location that were supposed to be there
    ## Percentage # of items correctly labelled / # original number of items
    ## ELSE
    ## Provide link for the inventory status
    my $past_inventory_info = HTML_Table->new( -title => 'Completed Inventories' );
    my @past_inventory_headers = ( 'Inventory ID', 'Equipment', 'Employee', 'Inventory Started', 'Inventory Finished', 'Status' );
    push( @past_inventory_headers, $self->{Attribute_Name} );
    $past_inventory_info->Set_Headers( \@past_inventory_headers );

    my $current_inventory_info = HTML_Table->new( -title => 'Inventories in progress' );
    my @curr_inventory_headers = ( 'Inventory ID', 'Equipment', 'Employee', 'Inventory Started', 'Status' );

    $current_inventory_info->Set_Headers( \@curr_inventory_headers );

    my %inventory = $dbc->Table_retrieve(
        "Maintenance,Maintenance_Process_Type,Status",
        [ 'Maintenance_ID', 'FK_Equipment__ID', 'FK_Employee__ID', 'Maintenance_DateTime', 'Maintenance_Finished', 'Status_Name' ],
        "WHERE FK_Maintenance_Process_Type__ID=Maintenance_Process_Type_ID AND Process_Type_Name = 'Inventory' and FKMaintenance_Status__ID = Status_ID"
    );

    my $index              = 0;
    my $completed_switch   = 0;
    my $in_progress_switch = 0;
    while ( defined $inventory{'Maintenance_ID'}[$index] ) {
        my $maintenance_id = $inventory{'Maintenance_ID'}[$index];

        my $employee     = $dbc->get_FK_info( 'FK_Employee__ID', $inventory{'FK_Employee__ID'}[$index] );
        my $maint_start  = $inventory{'Maintenance_DateTime'}[$index];
        my $maint_finish = $inventory{'Maintenance_Finished'}[$index];
        my $maint_status = $inventory{'Status_Name'}[$index];

        #	   ## Get the attributes for each event
        #	   my $inv_attributes = $self->get_attribute_record($event_id);
        my $inventory_item = $inventory{'FK_Equipment__ID'}[$index];

        if ( $maint_status eq 'Completed' ) {
            $past_inventory_info->Set_Row( [ $maintenance_id, $inventory_item, $employee, $maint_start, $maint_finish, $maint_status ] );
            $completed_switch = 1;
        }
        elsif ( $maint_status eq 'In Process' ) {
            my $continue_inventory = &Link_To( $dbc->config('homelink'), "Continue", "&HomePage=Inventory&ID=$maintenance_id", $Settings{LINK_COLOUR}, ['newwin'], "Continue inventory for item" );
            $current_inventory_info->Set_Row( [ $maintenance_id, $inventory_item, $employee, $maint_start, $maint_status, $continue_inventory ] );
            $in_progress_switch = 1;
        }

        $index++;
    }

    # detect if tables are empty and display friendly message so that the user knows the system is working as expected
    if ( !$completed_switch ) {
        $past_inventory_info->Set_sub_header("No completed inventories found.");
    }
    if ( !$in_progress_switch ) {
        $current_inventory_info->Set_sub_header("No inventories currently in progress.");
    }
    print Views::Heading("Inventory Main Page");
    create_tree( -tree => { "Inventory Status" => display_inventories_needed( -since => &date_time('-30d'), -printable => 1 ) }, -print => 1 );
    create_tree( -tree => { "Past Inventories" => $past_inventory_info->Printout(0) }, -print => 1 );
    print hr();
    $current_inventory_info->Printout();

    return;
}

# Show the status of the inventory
#
#
###############################
sub show_inventory_status {
###############################
    ## Display inventory info:  Date Time started
    ##                          Original Number of Items (supposed to be in equipment)
    ##                          Number of Items scanned in so far
    ##                          Number of Items that are supposed to be in the equipment but not scanned in yet?
    my $self = shift;
    ## Display rack or equipment contents

    my %layers;

    $layers{'Original Inventory'} = $self->display_item_contents();

    ## Display current list of items that have been scanned in ordered by rack, item type

    #$layers{'Scanned Items'} = $self->display_scanned_items();

    ## Display list of items that were supposed to be in the location but have not been scanned in yet, orderd by rack, item type
    $layers{'Inventory Statistics'} = $self->display_item_stats();

    ## Display items that are inventoried by

    ## Display the scan page for scanning more items for inventory
    $layers{'Scan Page'} = $self->inventory_scan_page();

    print define_Layers( -layers => \%layers, -tab_width => 200 );
}

# Scan page for inventory of items
#
############################
sub inventory_scan_page {
############################
    my $self      = shift;
    my $dbc       = $self->{dbc};
    my $equipment = $self->{FK_Equipment__ID};
    my $item_name = $dbc->get_FK_info( 'FK_Equipment__ID', $equipment );

    my $output;
    my $scan_table = HTML_Table->new( -title => "Inventory for <BR>$item_name" );
    $scan_table->Set_Class('Small');
    $scan_table->Set_Line_Colour( $Settings{LIGHT_BKGD} );

    #$scan_table->Toggle_Colour('off');
    ## Set up textareas and buttons
    my $target_value = textfield( -name => 'Target_Item', -size => 10, -default => "EQU$equipment", -disabled => 1 );
    my $items_list = textarea( -name => 'Item_Contents', -default => '' );
    my $sub_items_target = textfield( -name => 'Sub_Target_Item', -size => 10, -default => "", -force => 1 );
    my $sub_items_list = textarea( -name => 'Sub_Item_Contents', -default => '', -force => 1 );
    my $update_inventory = submit( -name => 'Update_Inventory_List', -value => 'Update Inventory', -class => "Std" );
    my $finish_inventory = submit( -name => 'Finish_Inventory_List', -value => 'Finish Inventory', -class => "Action", -onClick => "sendAlert('All items will be moved to their current location')" );

    print hidden( -name => "Inventory_ID", -value => $self->{id} );

    $scan_table->Set_sub_header( "<B><font color='white'>Shelves and racks or boxes not on a shelf</font></B>", 'lightbluebw' );
    ## Set the labels for the rack or equipment

    $scan_table->Set_Row( [ "Equipment ID :", $target_value ] );
    $scan_table->Set_Row( [ "Contains: ", Show_Tool_Tip( $items_list, "Scan shelves and racks or boxes in $item_name not on a shelf" ) ] );
    $scan_table->Set_sub_header( "<B><font color='white'>Contents of shelf, rack or box</font></B>", 'lightbluebw' );
    $scan_table->Set_Row( [ "Scan shelf,rack or box:", Show_Tool_Tip( $sub_items_target, "Scan shelf, rack or box in $item_name for which you want to inventory contents" ) ] );
    $scan_table->Set_Row( [ "Scan Contents:",          Show_Tool_Tip( $sub_items_list,   "Scan contents of the above scanned shelf, rack or box" ) ] );
    my $access = $dbc->get_local('Access')->{$Current_Department};
    if ( grep /^admin/i, @$access ) {
        $scan_table->Set_Row( [ $update_inventory, $finish_inventory ] );
    }
    else {
        $scan_table->Set_Row( [$update_inventory] );
    }
    $output .= $scan_table->Printout(0);
    return $output;

}

# Display list of current items in the location (freezer)
#
# Return
##############################
sub display_item_contents {
##############################
    ## Display list of plates, solutions, sources, grouped by rack currently in the freezer or rack
    my $self = shift;
    my %args = filter_input( \@_ );

    my $equipment;
    my $output;
    my $dbc = $self->{dbc};
    $equipment = $self->{FK_Equipment__ID};
    ## Find all the racks and shelves on the equipment
    $output .= alDente::Equipment::display_equipment_contents( -dbc => $dbc, -id => $self->{FK_Equipment__ID}, -title => "Equipment Contents before Inventory" );

    return $output;
}

#
#
#
#
##############################
sub display_scanned_items {
##############################
    my $self = shift;
    my $dbc  = $self->{dbc};

    my $output = &Views::sub_Heading( "Items inventoried: " . $dbc->get_FK_info( 'FK_Equipment__ID', $self->{FK_Equipment__ID} ) );

    my $inventory_hash = $self->get_scanned_items();

    $output .= alDente::Rack_Views::show_Contents( -rack_id => $self->{FK_Equipment__ID}, -rack_contents => $inventory_hash, -level => 1, -recursive => 1 ) . lbr();

    return $output;
}

sub get_scanned_items {
    my $self                = shift;
    my $inventory_file      = $self->{inventory_file};
    my $inventory_directory = $self->{inventory_dir};
    open( FILE, "$inventory_directory/$inventory_file" ) or die "Cannot find file '$inventory_directory/$inventory_file'";
    my %inventory_hash = ();
    my @item_racks;
    my %all_racks;
    while (<FILE>) {
        my $line = lc $_;
        chomp $line;
        $line =~ s/([a-z])0+(\d)/$1$2/g;
        my ( $target, $items ) = split ':', $line;
        $inventory_hash{$target} = $items;
        while ( $items =~ /(rac\d+)/gi ) {
            push @item_racks, $1;
            $all_racks{$1} = 1;
        }
        if ( $target =~ /rac/i ) {
            $all_racks{$target} = 1;
        }
    }
    my $orphans = set_difference( [ keys %all_racks ], \@item_racks );
    my $racks_to_scan = Cast_List( -list => $orphans, -to => 'String' );
    if ( length($racks_to_scan) > 0 ) {
        Message("Locations that need to be scanned in: $racks_to_scan");
    }
    my %cleaned_inventory;
    foreach my $item ( keys %inventory_hash ) {
        my $contents = $inventory_hash{$item};
        foreach my $key ( keys %Prefix ) {
            my $prefix       = $Prefix{$key};
            my $lcase_prefix = lc($prefix);
            if ( $item =~ /$prefix/i ) {
                $item =~ s/$lcase_prefix/$prefix/g;
            }
            if ( $contents =~ /$prefix/i ) {
                $contents =~ s/$lcase_prefix/$prefix/g;
            }
        }
        $cleaned_inventory{$item} = $contents;
    }

    return \%cleaned_inventory;

}

# Display Statistics for the Inventory
# Includes:
#   -the items that are only in the original list of items
#   -the items that are only scanned in
#   -the items that are both in the original list and the scanned list
#
# Return output of the items
##########################
sub display_item_stats {
##########################
    my $self    = shift;
    my %args    = filter_input( \@_, -args => 'no_tree' );
    my $dbc     = $self->{dbc};
    my $no_tree = $args{-no_tree};
    my $format  = $args{'-format'} || 'layer';

    ## Get the item information
    my ( $matched, $original_only, $scanned_only ) = $self->get_item_stats();

    my $output = &Views::Heading("Inventory Statistics $self->{item_name}");

    #if ($self->{Inventory_Type} eq 'equ'){
    my %equip_contents = ();
    my @racks = $dbc->Table_find( "Rack", "Rack_ID", "WHERE FKParent_Rack__ID = 0 and FK_Equipment__ID = $self->{FK_Equipment__ID}" );
    my %stats;
    my $total     = 0;
    my $equipment = "Equ" . $self->{FK_Equipment__ID};

    my @scanned_racks = keys %{$scanned_only};

    my @matched_racks = keys %{$matched};

    my @original_racks = keys %{$original_only};
    my @all_racks = @{ unique_items( \@matched_racks, \@scanned_racks ) };
    ### Check for scanned = original
    foreach my $match (@matched_racks) {
        if ( $match eq $equipment ) {
            my @child_racks = @all_racks;

            foreach my $child_rack (@child_racks) {
                if ( $child_rack =~ /rac(\d+)/i ) {
                    my $child_id = $1;

                    my ($parent) = $dbc->Table_find( 'Rack', 'FKParent_Rack__ID', "WHERE Rack_ID = $child_id" );

                    if ( grep /Rac$parent/i, @child_racks ) {
                        next;
                    }

                    my $rack_title = $dbc->get_FK_info( 'FK_Rack__ID', $child_id ) if $child_id;
                    if ($no_tree) {
                        push( @{ $stats{Matched} }, alDente::Rack_Views::show_Contents( -rack_id => $child_id, -rack_contents => $matched, -title => $rack_title, -level => 1, -no_tree => $no_tree, -recursive => 1 ) );
                    }
                    else {
                        push(
                            @{ $stats{Matched} },
                            create_tree( -tree => { $rack_title => alDente::Rack_Views::show_Contents( -rack_id => $child_id, -rack_contents => $matched, -title => $rack_title, -level => 1, -no_tree => $no_tree, -recursive => 1 ) }, -print => 0 )
                        );
                    }
                }

            }

        }

    }
    if ( exists $original_only->{$equipment} ) {
        my @missing_racks = sort keys %{$original_only};
        foreach my $missing (@missing_racks) {
            if ( $missing =~ /rac(\d+)/i ) {
                my $child_id = $1;
                my ($parent) = $dbc->Table_find( 'Rack', 'FKParent_Rack__ID', "WHERE Rack_ID = $child_id" );

                my $rack_title = $dbc->get_FK_info( 'FK_Rack__ID', $child_id );
                if ($no_tree) {
                    push( @{ $stats{Missing} }, alDente::Rack_Views::show_Contents( -rack_id => $child_id, -rack_contents => $original_only, -title => $rack_title, -level => 1, -no_tree => $no_tree, -running_total => \$total, -recursive => 1 ) );
                }
                else {
                    push(
                        @{ $stats{Missing} },
                        create_tree(
                            -tree  => { $rack_title => alDente::Rack_Views::show_Contents( -rack_id => $child_id, -rack_contents => $original_only, -title => $rack_title, -level => 1, -no_tree => $no_tree, -running_total => \$total, -recursive => 1 ) },
                            -print => 0
                        )
                    );
                }
            }
        }
    }
    foreach my $scan_only (@scanned_racks) {
        if ( $scan_only =~ /rac(\d+)/i ) {
            my $child_id = $1;
            my ($parent) = $dbc->Table_find( 'Rack', 'FKParent_Rack__ID', "WHERE Rack_ID = $child_id" );
            my $rack_title = $dbc->get_FK_info( 'FK_Rack__ID', $child_id );
            if ($no_tree) {
                push( @{ $stats{Scan_Only} }, alDente::Rack_Views::show_Contents( -rack_id => $child_id, -rack_contents => $scanned_only, -title => $rack_title, -level => 1, -no_tree => $no_tree, -running_total => \$total, -recursive => 1 ) );
            }
            else {
                push(
                    @{ $stats{Scan_Only} },
                    create_tree(
                        -tree  => { $rack_title => alDente::Rack_Views::show_Contents( -rack_id => $child_id, -rack_contents => $scanned_only, -title => $rack_title, -level => 1, -no_tree => $no_tree, -running_total => \$total, -recursive => 1 ) },
                        -print => 0
                    )
                );
            }
        }
    }
    ## Display the scan page for scanning more items for inventory

    my $inventory_output;
    $inventory_output .= Views::sub_Heading("<B>Inventoried Items</B>");
    unless ( exists $stats{Matched} ) {
        $inventory_output .= "None" . lbr();
    }
    foreach my $matched ( @{ $stats{Matched} } ) {
        $inventory_output .= $matched;
    }

    my $missing_output .= Views::sub_Heading("<B>Missing Items</B>");
    unless ( exists $stats{Missing} ) {
        $missing_output .= "     None" . lbr();
    }
    foreach my $original ( @{ $stats{Missing} } ) {
        $missing_output .= $original;
    }

    my $extra_output .= Views::sub_Heading("<B>Extra items found during inventory</B>");
    unless ( exists $stats{Scanned_Only} ) {
        $extra_output .= "    None" . lbr();
    }
    foreach my $original ( @{ $stats{Scan_Only} } ) {
        $extra_output .= $original;
    }

    foreach my $orphan ( @{ $stats{Scanned_Orphan} } ) {
        $extra_output .= $orphan;
    }
    if ( $format =~ /layer/ ) {

        #	my %layers;
        #	$layers{'Inventoried Items'} = $inventory_output;
        #	$layers{'Missing'} = $missing_output;
        #	$layers{'Extra Items'}  = $extra_output;
        #
        #	return define_Layers(-layers=>\%layers,-tab_width=>200,-name=>"inv_stats",-open=>'Inventoried Items',-order=>['Inventoried Items','Missing','Extra Items'],-format=>'list');

        return create_tree( -tree => { "Inventoried Items" => $inventory_output, "Missing" => $missing_output, "Extra Items" => $extra_output }, -print => 0 );

    }
    else {
        return $inventory_output . $missing_output . $extra_output;
    }

    #return $output;
}

#
#
#
#
#
##################################
sub get_item_stats {
##################################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'matched,original_only,scanned_only' );
    my $dbc  = $self->{dbc};
    my %matched;
    my %original_only;
    my %scanned_only;
    my $equipment = $self->{FK_Equipment__ID};
    my %original_list;

    my @racks = $dbc->Table_find( "Rack", "Rack_ID", "WHERE FKParent_Rack__ID = 0 and FK_Equipment__ID = $equipment" );
    my @rack_barcodes;
    foreach my $rack (@racks) {
        alDente::Rack::get_rack_contents( -rack_id => $rack, -rack_contents => \%original_list, -recursive => 1 );
        push( @rack_barcodes, "Rac$rack" );
    }
    my $rack_list = Cast_List( -list => \@rack_barcodes, -to => 'String' );
    $rack_list =~ s/([a-z])0+(\d)/$1$2/g;
    $original_list{"Equ$equipment"} = $rack_list;
    ## Find the original list of items

    ## Items that have been inventoried
    my $scanned_items = $self->get_scanned_items();
    foreach my $key ( keys %original_list ) {
        if ( exists $scanned_items->{$key} ) {
            my ( $match, $original, $scanned ) = &RGmath::intersection( $original_list{$key}, $scanned_items->{$key} );
            $matched{$key}       = Cast_List( -list => $match,    -to => 'String' );
            $original_only{$key} = Cast_List( -list => $original, -to => 'String' );
            $scanned_only{$key}  = Cast_List( -list => $scanned,  -to => 'String' );
        }
        else {
            $original_only{$key} = $original_list{$key};
        }

    }
    foreach my $scan_key ( keys %$scanned_items ) {
        unless ( grep /^$scan_key$/, keys %original_list ) {
            $scanned_only{$scan_key} = $scanned_items->{$scan_key};
        }
    }

    #print HTML_Dump \%matched, \%original_only, \%scanned_only;
    return ( \%matched, \%original_only, \%scanned_only );
}

# Update the items scanned in during the inventory
#
#########################
sub update_inventory {
#########################
    ## update the running list of items that are in the racks
    my $self              = shift;
    my %args              = filter_input( \@_, -args => 'target_item,item_contents,subtarget_item,sub_item_contents' );
    my $item_contents     = $args{-item_contents};
    my $sub_target_item   = $args{-sub_target_item};
    my $sub_item_contents = $args{-sub_item_contents};
    my $target_item       = $self->{FK_Equipment__ID};
    my $item_barcode      = "equ" . $target_item;

    ## Lower case everything
    $item_contents     = lc($item_contents);
    $sub_target_item   = lc($sub_target_item);
    $sub_item_contents = lc($sub_item_contents);
    $item_barcode      = lc($item_barcode);

    my $inventory_directory = $self->{inventory_dir};

    $item_contents     =~ s/([a-z])0+(\d)/$1$2/g;
    $sub_target_item   =~ s/([a-z])0+(\d)/$1$2/g;
    $sub_item_contents =~ s/([a-z])0+(\d)/$1$2/g;
    $item_barcode      =~ s/([a-z])0+(\d)/$1$2/g;

    ## Count the number of items scanned

    ## check the last item on the line to see if it is the item or a subitem

    ## compare the scanned items to the line and update the file line

    ## Store in a file?

    ## update the current number of items scanned

    my $file_name = $inventory_directory . "/" . "Inventory_" . $self->{id} . ".txt";
    ## open the file
    open( FILE, "$file_name" ) or die "Cannot find file '$file_name'\n";
    my @temp_file;

    while (<FILE>) {
        my $line = $_;
        push( @temp_file, $line );
    }
    close(FILE);

    open( FILE1, ">$file_name" ) or die "Cannot overwrite file '$file_name'\n";

    my @targets_in_file;
    my $number_scanned = 0;
    foreach my $line (@temp_file) {
        my ( $target, $items ) = split ':', $line;
        chomp($items);
        my @items = split ',', $items;

        if ( $target eq $item_barcode ) {
            ## on the item
            ## does it

            while ( $item_contents =~ /(\w{3}\d+)/gi ) {

                my $barcode = $1;

                if ( grep /$barcode/, @items ) {

                }
                else {
                    push( @items, $barcode );

                    $line = "$target:" . Cast_List( -list => \@items, -to => 'String' ) . "\n";
                }
                $number_scanned++;
            }

            print FILE1 $line;
            push( @targets_in_file, $target );
        }
        elsif ( $target eq $sub_target_item ) {
            while ( $sub_item_contents =~ /(\w{3}\d+)/gi ) {

                my $barcode = $1;
                if ( grep /$barcode/, @items ) {

                }
                else {
                    push( @items, $barcode );

                    $line = "$target:" . Cast_List( -list => \@items, -to => 'String' ) . "\n";
                }
                $number_scanned++;
            }
            print FILE1 $line;
            push( @targets_in_file, $target );
        }
        else {
            print FILE1 $line;
        }

    }

    my @scan_array = ( "$item_barcode:$item_contents", "$sub_target_item:$sub_item_contents" );

    foreach my $scanned_item (@scan_array) {
        my ( $item, $contents ) = split ':', $scanned_item;
        my @content_list;

        if ( $item && $contents ) {
            while ( $contents =~ /(\w{3}\d+)/gi ) {
                my $barcode = $1;
                push( @content_list, $barcode );
            }

            if ( grep /^$item$/, @targets_in_file ) {
            }
            else {

                print FILE1 "$item:" . Cast_List( -list => \@content_list, -to => "String" ) . "\n";
            }
        }
    }
    close(FILE1);
    Message("Scanned $number_scanned items");
}

# Complete the inventory for an equipment/freezer
#
# Return 1 on success
##########################
sub finish_inventory {
##########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    $dbc->start_trans('finish_inventory');

    if ( $dbc->package_active('Subscriptions') ) {
        $self->send_inventory_summary();
    }

    ## Set the status of the inventory to Complete
    eval {
        my ($completed) = $dbc->Table_find( "Status", "Status_ID", "Where Status_Type = 'Maintenance' and Status_Name ='Completed'" );
        my $updated = $dbc->Table_update_array( "Maintenance", [ "FKMaintenance_Status__ID", "Maintenance_Finished" ], [ $completed, &date_time() ], "WHERE Maintenance_ID = $self->{id}", -autoquote => 1 );

        ## Find the difference between the original list and the running list
        my ( $matched, $original_only, $scanned_only ) = $self->get_item_stats();

        foreach my $original ( keys %$original_only ) {
            my $original_only = $original_only->{$original};
            $original_only =~ s/,//g;

            if ( $original_only && $original ) {

                #my $barcode = $extra_item . $scanned;
                my @types = ( 'Plate', 'Solution', 'Rack', 'Source', 'Tube', 'Box' );
                my ($target_rack_id) = $dbc->Table_find( "Rack,Equipment", "Rack_ID", "WHERE Equipment_Name='TBD' and Rack_Alias ='TBD (Room Temperature)' AND Equipment_ID=FK_Equipment__ID" );
                my $equip_id;
                foreach my $type (@types) {
                    if ( $type eq 'Tube' ) {
                        $type = 'Plate';
                    }

                    my $item = &get_aldente_id( $dbc, $original_only, $type );

                    #$item =~ s/,//g;
                    unless ($item) {next}

                    if ( $original =~ /equ/i ) {

                        ($equip_id) = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
                            'Equipment_ID', "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Category='Storage' AND Sub_Category <> 'Storage_Site'" );

                        my %source_info = $dbc->Table_retrieve(
                            'Rack,Equipment LEFT JOIN Rack AS PRack ON Rack.FKParent_Rack__ID = PRack.Rack_ID',
                            [ 'Rack.Rack_ID', 'Rack.Rack_Type', 'PRack.Rack_Alias AS Parent_Rack_Alias', 'Rack.Rack_Alias', 'Rack.Movable' ],
                            "WHERE Rack.Rack_ID IN ($item) AND Rack.FK_Equipment__ID=Equipment_ID ORDER BY Rack.Rack_ID",

                            # -debug => 1
                        );
                        alDente::Rack::Move_Racks( -dbc => $dbc, -source_racks => $item, -equip => $equip_id, -confirmed => 1, -no_print => 1 );

                    }
                    elsif ( $type eq 'Rack' ) {

                        my %source_info = $dbc->Table_retrieve(
                            'Rack,Equipment LEFT JOIN Rack AS PRack ON Rack.FKParent_Rack__ID = PRack.Rack_ID',
                            [ 'Rack.Rack_ID', 'Rack.Rack_Type', 'PRack.Rack_Alias AS Parent_Rack_Alias', 'Rack.Rack_Alias', 'Rack.Movable' ],
                            "WHERE Rack.Rack_ID IN ($item) AND Rack.FK_Equipment__ID=Equipment_ID ORDER BY Rack.Rack_ID",

                            #  -debug => 1
                        );
                        my @requested = @{ $source_info{Rack_Type} } if ( $source_info{Rack_Type} );
                        my $avail = alDente::Rack::_get_available_names( -rack_id => $target_rack_id, -list => \@requested );
                        my $i = -1;
                        my %new_names;
                        while ( defined $source_info{Rack_ID}[ ++$i ] ) {
                            my $s_type        = $source_info{Rack_Type}[$i];
                            my $new_rack_name = shift( @{ $avail->{$s_type} } );
                            $new_names{ $source_info{Rack_ID}[$i] } = $new_rack_name;
                        }
                        alDente::Rack::Move_Racks( -dbc => $dbc, -source_racks => $item, -target_rack => $target_rack_id, -confirmed => 1, -new_names => \%new_names, -no_print => 1 );
                    }
                    else {
                        my $id_field = $type . "_ID";
                        my @ids      = $dbc->Table_find( "$type,Rack", $id_field, "WHERE FK_Rack__ID = Rack_ID AND Rack_Type <> 'Slot' AND $id_field IN ($item)" );
                        my $ids      = Cast_List( -list => \@ids, -to => 'String', -autoquote => 1 );

                        #	&move_Items(-dbc=>$dbc,-type=>$type,-ids=>$ids,-rack=>$target_rack_id,-confirmed=>1);

                        my $moved = 0;
                        if ($ids) {
                            $moved = $dbc->Table_update_array( $type, ['FK_Rack__ID'], [$target_rack_id], "where $type" . "_ID IN ($item)", -autoquote => 1, -debug => 1 );
                        }

                    }

                }
            }
            ## move these items to undetermined location (equipment or rack)
            ## Set the items that are not in the equipment into Temporary
        }

        foreach my $scanned ( keys %$scanned_only ) {
            ## move these items to the new location
            ## make the barcode
            my $extra_items = $scanned_only->{$scanned};
            $extra_items =~ s/,//g;
            if ( $extra_items && $scanned ) {

                #my $barcode = $extra_items . $scanned;
                my @types = ( 'Plate', 'Solution', 'Rack', 'Source', 'Tube', 'Box' );
                foreach my $type (@types) {
                    if ( $type eq 'Tube' ) {
                        $type = 'Plate';
                    }
                    my $item = &get_aldente_id( $dbc, $extra_items, $type );

                    #$item =~ s/,//g;
                    if ( $scanned =~ /equ/i ) {
                        my $equip_id = &get_aldente_id( $dbc, $scanned, 'Equipment' );
                        if ( $item && $equip_id ) {
                            alDente::Rack::Move_Racks( -dbc => $dbc, -source_racks => $item, -equip => $equip_id, -confirmed => 1, -no_print => 1 );
                        }
                    }
                    elsif ( $type eq 'Rack' ) {
                        if ( $item && $scanned ) {
                            my $target_rack = get_aldente_id( $dbc, $scanned, 'Rack' );
                            my %source_info = $dbc->Table_retrieve(
                                'Rack,Equipment LEFT JOIN Rack AS PRack ON Rack.FKParent_Rack__ID = PRack.Rack_ID',
                                [ 'Rack.Rack_ID', 'Rack.Rack_Type', 'PRack.Rack_Alias AS Parent_Rack_Alias', 'Rack.Rack_Alias', 'Rack.Movable' ],
                                "WHERE Rack.Rack_ID IN ($item) AND Rack.FK_Equipment__ID=Equipment_ID ORDER BY Rack.Rack_ID"
                            );
                            my @requested = @{ $source_info{Rack_Type} } if ( $source_info{Rack_Type} );
                            my $avail = alDente::Rack::_get_available_names( -rack_id => $target_rack, -list => \@requested );
                            my $i = -1;
                            my %new_names;
                            while ( defined $source_info{Rack_ID}[ ++$i ] ) {
                                my $s_type        = $source_info{Rack_Type}[$i];
                                my $new_rack_name = shift( @{ $avail->{$s_type} } );
                                $new_names{ $source_info{Rack_ID}[$i] } = $new_rack_name;
                            }
                            alDente::Rack::Move_Racks( -dbc => $dbc, -source_racks => $item, -target_rack => $target_rack, -confirmed => 1, -new_names => \%new_names, -no_print => 1 );

                        }
                    }
                    else {
                        my $id_field = $type . "_ID";
                        my @ids;
                        if ($item) {
                            @ids = $dbc->Table_find( "$type,Rack", $id_field, "WHERE FK_Rack__ID = Rack_ID AND Rack_Type <> 'Slot' AND $id_field IN ($item)" );
                        }
                        my $ids = Cast_List( -list => \@ids, -to => 'String', -autoquote => 1 );
                        if ( $ids && $scanned ) {
                            my $target_rack = get_aldente_id( $dbc, $scanned, 'Rack' );
                            ## Find what is already on the rack and move it to undetermined first
                            my ($unknown_rack) = $dbc->Table_find( "Rack,Equipment", "Rack_ID", "WHERE Equipment_Name = 'TBD' and Rack_Alias ='TBD (Room Temperature)' AND FK_Equipment__ID=Equipment_ID" );

                            my @unknown_ids = $dbc->Table_find( "$type,Rack", $id_field, "WHERE FK_Rack__ID = Rack_ID and Rack_ID = $target_rack and $id_field NOT IN ($ids)" );
                            my $unknown_ids = Cast_List( -list => \@unknown_ids, -to => 'string', -autoquote => 1 );
                            if ($unknown_ids) {
                                my $moved_unknown = $dbc->Table_update_array( $type, ['FK_Rack__ID'], [$unknown_rack], "where $type" . "_ID IN ($unknown_ids)", -autoquote => 1 );
                            }
                            my $moved = $dbc->Table_update_array( $type, ['FK_Rack__ID'], [$target_rack], "where $type" . "_ID IN ($ids)", -autoquote => 1 );
                            Message("Moved $moved $type (s)");
                        }
                    }
                }

            }
        }
        ## Move the matched items
        foreach my $match ( keys %$matched ) {
            my $matched_items = $matched->{$match};
            $matched_items =~ s/,//g;
            my @types = ( 'Plate', 'Solution', 'Rack', 'Source', 'Tube', 'Box' );
            foreach my $type (@types) {
                if ( $type eq 'Tube' ) {
                    $type = 'Plate';
                }
                my $item = get_aldente_id( $dbc, $matched_items, $type, -allow_repeats => 1 );
                if ( $matched =~ /equ/i ) {

                }
                elsif ( $type eq 'Rack' ) {

                }
                else {
                    my $id_field = $type . "_ID";
                    my $target_rack = get_aldente_id( $dbc, $match, 'Rack' );
                    if ( $item && $match ) {
                        my $moved = $dbc->Table_update_array( $type, ['FK_Rack__ID'], [$target_rack], "where $type" . "_ID IN ($item)", -autoquote => 1 );
                        Message("Moved $moved $type (s)");
                    }
                }

            }
        }
    };
    ## (these will be thrown out at the end of the day if they are not found on another equipment during invenotry)

    ## Update the contents of the location

    ## Update the statistics for the inventory
    ## Number of items in the location that were not supposed to be there
    ## Number of items not in the location that were supposed to be there
    ## Percentage # of items correctly labelled / # original number of items

    ## send summary report to administrators
    $dbc->finish_trans( 'finish_inventory', -error => $@ );

    $self->{id} = '';
    $self->home_page();
    return 1;
}

# Notify administrators with a summary of the inventory
#
#
###########################
sub send_inventory_summary {
###########################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $self->{dbc};
    my $user_id = $dbc->get_local('user_id');
    $dbc->message("Sending inventory summary email");

    my @email = $dbc->Table_find_array( 'Employee', [ 'Employee_Name', 'Email_Address' ], "where Employee_ID = $user_id" );

    my ( $to_name, $to_address ) = split /,/, $email[0];
    my $group_list = $dbc->get_local('group_list');

    my $current_user_email = $to_address;

    $to_address .= join ', ', @{ &alDente::Employee::get_email_list( $dbc, 'admin', -group => $group_list ) };

    #	my $to_address = get_email_list();

    my $from_address = "alDente LIMS <alDente\@bcgsc.ca>";

    my $msg = $self->display_item_stats( -no_tree => 1, -format => 'normal' );

    #my $header = "html";
    my $header = "Content-type: text/html\n\n";

    ## find the admins based on the group
    my $ok = &alDente::Notification::Email_Notification(
        -to_address   => $to_address,
        -from_address => $from_address,
        -subject      => "Inventory Summary",
        -body_message => $msg,
        -header       => $header,
        -verbose      => 0,
        -testing      => $dbc->test_mode()
    );

    #++++++++++++++++++++++++++++++ Subscription Module version of the Notification
    my $tmp = alDente::Subscription->new( -dbc => $dbc );

    my $ok = $tmp->send_notification( -name => "Inventory Summary", -to => $current_user_email, -from => $from_address, -subject => 'Inventory Summary (from Subscription Module)', -body => $msg, -content_type => 'html', -testing => 1 );

    #++++++++++++++++++++++++++++++

    ## Create inventory summary

    ## Send email to admins

    return 1;
}

# Show status for freezers that have not been inventoried recently
#
#
###############################
sub display_inventories_needed {
###############################
    my %args = filter_input( \@_, -args => 'since' );
    my $dbc                = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $finished_date_time = $args{-since};                                                                   ## Threshold date for any equipments that have not been inventoried
    my $printable          = $args{-printable};                                                               ## show printable page
    my @fields             = ( 'Equipment_ID', 'Equipment_Name' );

    my @equipment_ids = $dbc->Table_find( "Maintenance,Status,Maintenance_Process_Type", 'FK_Equipment__ID',
        "WHERE FK_Maintenance_Process_Type__ID=Maintenance_Process_Type_ID AND Process_Type_Name = 'Inventory' and Maintenance_Finished > '$finished_date_time' and FKMaintenance_Status__ID = Status_ID OR Status_Name = 'In Process' and FK_Equipment__ID !=0 and FK_Equipment__ID is NOT NULL"
    );

    my $condition;
    my $ignore_equipment_list = '';
    $ignore_equipment_list = Cast_List( -list => \@equipment_ids, -to => 'String' );

    if (@equipment_ids) {
        $condition .= "and Equipment_ID not in ($ignore_equipment_list) ";
    }
    my %equipments = $dbc->Table_retrieve( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
        ['Equipment_ID'], "WHERE 1 $condition and FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Category='Freezer' ORDER By Equipment_Name" );

    my $index = 0;

    my $equipments_table = HTML_Table->new( -title => "Equipment that have not been inventoried since $finished_date_time" );

    while ( defined $equipments{Equipment_ID}[$index] ) {
        my $equip_id = $equipments{Equipment_ID}[$index];
        my $equip_name = $dbc->get_FK_info( 'FK_Equipment__ID', $equip_id );

        my $equip_link = &Link_To( $dbc->config('homelink'), 'Start Inventory', "&Inventory_Home=1&Start_Inventory=1&FK_Equipment__ID=$equip_id" );
        $equipments_table->Set_Row( [ $equip_name, $equip_link ] );

        $index++;
    }
    if ($printable) {
        return $equipments_table->Printout( "$alDente::SDB_Defaults::URL_temp_dir/InventoryEquipmentlist_@{[timestamp()]}.html", "$java_header\n$html_header" ) . $equipments_table->Printout(0);
    }
    else {
        return $equipments_table->Printout(0);
    }
}
