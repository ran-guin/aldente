################################################################################
#
# Equipment.pm
#
# This facilitates operations using equipment
#
################################################################################
################################################################################
# $Id: Equipment.pm,v 1.47 2004/11/10 20:09:14 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.47 $
#     CVS Date: $Date: 2004/11/10 20:09:14 $
################################################################################
package alDente::Equipment;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Equipment.pm - This facilitates operations using equipment

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This facilitates operations using equipment<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter SDB::DB_Object);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    equipment_main
    new_equipment
    save_equipment
    equipment_list
    change_matrix
    change_MatrixBuffer
    maintenance_home
    save_maintenance_procedure
    maintenance_stats
);
@EXPORT_OK = qw(
    equipment_main
    new_equipment
    save_equipment
    equipment_list
    change_matrix
    change_MatrixBuffer
    maintenance_home
    save_maintenance_procedure
    maintenance_stats
);

##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);

##############################
# custom_modules_ref         #
##############################
use alDente::Solution;    ## open_bottle
use alDente::Form;
use alDente::Tools;
use Sequencing::Sequence;
use alDente::Rack;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use Sequencing::Sample_Sheet;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::Session;
use SDB::DB_Object;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;
use RGTools::Conversion;
use alDente::Equipment_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs $Sess);
our ( $dbase, $homefile, $Connection );
our ( $parents, $current_plates, $plate_set, $barcode, $user, $equipment_id, $solution );
our ( $full_page,     $default_lib );
our ( @plate_formats, @sequencers, @suppliers, @users );
our ( $libs,          $br );
our ($MenuSearch);    ## from Barcode.pm
our ( $equipment, $testing, $URL_temp_dir, $html_header, $scanner_mode, $Sess, $image_dir, $URL_dir_name );
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

#########
sub new {
#########
    #
    # Constructor of the object
    #
    my $this = shift;
    my $class = ref($this) || $this;

    my %args     = @_;
    my $id       = $args{-id};
    my $dbc      = $args{-dbc} || $Connection->dbh();    # Database handle
    my $stock_id = $args{-stock_id};
    my $Stock    = $args{-Stock};

    my $retrieve = $args{-retrieve};                     ## retrieve information right away [0/1]
    my $verbose  = $args{-verbose};

    my $self;
    if ($Stock) {
        $self = $Stock;
    }
    else {
        $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Equipment,Stock,Stock_Catalog,Organization,Equipment_Category' );

        # if stock id is provided
        if ($stock_id) {
            ($id) = $dbc->Table_find( 'Equipment', 'Equipment_ID', "WHERE FK_Stock__ID = $stock_id" );
            $self->{id} = $id;
        }

        if ($id) {
            $self->{id} = $id;
        }
    }

    $self->load_Object( -force => 1 );

    $self->{id} = $self->get_data('Equipment_ID');

    bless $self, $class;

    $self->{dbc}     = $dbc;
    $self->{records} = 0;      ## number of records currently loaded

    return $self;
}

##############################
# public_methods             #
##############################

###########################
sub home_page {
###########################
    #
    # Basic Info for Equipment at top of home page
    #
    my $self    = shift;
    my $dbc     = $self->{dbc};
    my $ids     = shift;
    my $barcode = shift;

    if ( $ids =~ /equ/i ) { $ids = &get_aldente_id( $dbc, $ids, 'Equipment' ); }

    my @id_list = split ',', $ids;

    my $quiet = 0;    ### less verbose info on equipment...
    if ( $barcode =~ /sol(\d+)/ ) { $quiet = 1; }

    $self->home_info( $id_list[0], $quiet );
    return 1;
}

###########################
sub new_Equipment_trigger {
###########################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    my ($temp_name) = $dbc->Table_find( 'Equipment', 'Equipment_Name', " WHERE Equipment_ID = $id " );
    unless ( $temp_name =~ /^AUTO/ ) {
        return 1;
    }

    my ($category_id) = $dbc->Table_find( 'Equipment,Stock, Stock_Catalog, Equipment_Category',
        'Equipment_Category_ID', " WHERE Equipment_ID = $id and FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Equipment_Category__Id = Equipment_Category_ID and Equipment_Name LIKE 'AUTO_%'" );

    if ($category_id) {

        my ( $prefix, $number ) = _get_equipment_name( -dbc => $dbc, -category_id => $category_id );
        my $name = $prefix . '-' . $number;
        my $ok = $dbc->Table_update( 'Equipment', 'Equipment_Name', $name, "WHERE Equipment_ID = $id", -autoquote => 1 );
        if ($ok) {
            Message "Changed Name of EQU" . $id . " to $name";
        }
    }
    my @results = $dbc->Table_find(
        'Equipment,Stock, Stock_Catalog, Equipment_Category',
        'Equipment_Category_ID,Equipment_Name,Prefix',
        " WHERE Equipment_ID = $id and FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Equipment_Category__Id = Equipment_Category_ID"
    );
    return;

=begin
insert into Trigger values ('','Equipment','Perl',' require alDente::Equipment; my $ok = alDente::Equipment::new_Equipment_trigger(-dbc=>$self,-id=><ID>); ','insert','Active','Changing Equipment_Name for Bulkl insertion','No',NULL);

=cut	

}

###########################
sub home_info {
###########################
    #
    # General info supplied by default when equipment is scanned
    #
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'id' );
    my $dbc     = $self->{dbc};                          # || $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $id      = $args{-id} || $self->{id};
    my $quiet   = $args{-quiet};
    my $barcode = $id;

    if ( $id =~ /equ/i ) { $id = &get_aldente_id( $dbc, $id, 'Equipment' ); }
    if ( $id && !$self->{loaded} ) {
        $self->primary_value( -table => 'Equipment', -value => $id );    ## same thing as above..
        $self->load_Object( -left_join_tables => 'Stock,Stock_Catalog' );
    }

    return alDente::Equipment_Views::home_page( -dbc => $dbc, -Equipment => $self, -id => $id, -barcode => $barcode );
}

################################  new
sub assign_category {
###########################     NEW
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc};
    my $catalog_id    = $args{-catalog_id};
    my $equipment_id  = $args{-equipment_id};
    my $category_name = $args{-category};
    my $category_id   = $args{-category_id};

    if ( !$category_id && $category_name ) {
        $category_id = $dbc->get_FK_ID( 'FK_Equipment_Category__ID', $category_name );
    }
    else {
        $dbc->error('Internal Error 51: Please Inform LIMS');
    }

    my @fields = ( 'FK_Equipment_Category__ID', 'Stock_Status' );
    my @values = ( "$category_id", "'Active'" );
    my $ok = $dbc->Table_update_array( -table => 'Stock_Catalog', -fields => \@fields, -values => \@values, -condition => "WHERE Stock_Catalog_ID = $catalog_id" );
    unless ($ok) { $dbc->message('Failed to activate stock catalog record') }

    my @equipment_ids = $dbc->Table_find( 'Equipment,Stock', 'Equipment_ID', "WHERE FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = $catalog_id" );

    for my $equipment_id (@equipment_ids) {
        my ( $prefix, $number ) = _get_equipment_name( -dbc => $dbc, -category_id => $category_id );
        my $equipment_name   = $prefix . '-' . $number;
        my @equipment_fields = ( 'Equipment_Status', 'Equipment_Name' );
        my @equipment_values = ( 'In Use', $equipment_name );

        $ok = $dbc->Table_update_array( -table => 'Equipment', -fields => \@equipment_fields, -values => \@equipment_values, -condition => "WHERE Equipment_ID = $equipment_id", -autoquote => 1 );
        unless ($ok) { $dbc->message('Failed to activate equipment') }

        $dbc->message("Activated equipment: EQU$equipment_id (Name: $equipment_name)");
    }
    return;

}

#################
sub new_site {
#################
    my %args    = filter_input( \@_ );
    my $site_id = $args{-site_id};
    my $dbc     = $args{-dbc};

    my ($virtual_stock) = $dbc->Table_find( 'Stock_Catalog',      'Stock_Catalog_ID',      "WHERE Stock_Catalog_Name = 'Storage Area'" );
    my ($category)      = $dbc->Table_find( 'Equipment_Category', 'Equipment_Category_ID', "WHERE Category = 'Storage' AND Sub_Category = 'Storage_Site'" );
    my ($site_name)     = $dbc->Table_find( 'Site',               'Site_Name',             "WHERE Site_ID = $site_id" );

    ## add generic location for new site ##
    my ($site_location) = $dbc->Table_append_array( 'Location', [ 'Location_Name', 'FK_Site__ID' ], [ "$site_name Site Location", $site_id ], -autoquote => 1 );

    Message("Location for Site added");
    ## Add generic equipment for virtual storage (receiving) for new site ##
    my @fields = qw( Equipment_Name FK_Stock__ID Equipment_Status FK_Location__ID Equipment_Comments);
    my @values = ( 'Site-' . $site_id, $virtual_stock, 'In Use', $site_location, "unspecified storage for $site_name Site" );

    return $dbc->Table_append_array( 'Equipment', \@fields, \@values, -autoquote => 1 );
}

##############################
# public_functions           #
##############################

###########################                Should be earased
sub save_equipment {
###########################
    #
    # NO LONGER IN USE (saved after save_original_stock('Equip')....
    #
    #
    #  Update database with new equipment
    #

    Message('WArning 101 : You should not be here. Please Inform LIMS');
    Call_Stack();
    return;

    my $dbc      = $Connection;
    my $name     = param('Name');
    my $type     = param('Type');
    my $model    = param('Model');
    my $location = param('Equipment_Location');
    my $supplier = param('Supplier');
    my $s_num    = param('Serial Number');
    my $funding  = param('Funding');

    #    my $warranty = param('Warranty');
    my $comments = param('Comments');

    if ( param('New Supplier') =~ /\w/ ) {
        $supplier = param('New Supplier');
        my $ok = $dbc->Table_append( 'Organization', 'Organization_Name,Organization_Type', "$supplier,Lab Supplier", -autoquote => 1 );
        if   ($ok) { Message("Supplier added to database (fill in other info)"); }
        else       { $dbc->warning( "Couldn't add new supplier (may already exist)", Get_DBI_Error() ); }
    }
    if ( param('New Funding') =~ /\w/ ) { $funding = param('New Funding'); }
    if ( param('New Type')    =~ /\w/ ) { $type    = param('New Type'); }

    my $supplier_id = join ',', $dbc->Table_find( 'Organization', 'Organization_ID', "where Organization_Name = '$supplier'" );
    if ( !$supplier_id ) { Message( "Error:", "Supplier not found" ); }

    #    $dbc->warning("$supplier = $supplier_id");

    my @fields = ( 'Equipment_Name', 'Equipment_ Type', 'Serial_Number', 'Funding', 'Equipment_Comments' );

    #   my $values = "'$name','$type','$model',$supplier_id,'$s_num','$funding','$warranty','$comments'";
    my @values = ( $name, $type, $s_num, $funding, $comments );
    my $ok = $dbc->Table_append_array( 'Equipment', \@fields, \@values, -autoquote => 1 );
    if ($ok) {
        Message("Equipment added to database");

        #	my $id = join',',$dbc->Table_find('Equipment','Equipment_ID',"where Equipment_Name = '$name'");
        &alDente::Barcoding::PrintBarcode( $dbc, 'Equipment', $ok );
    }
    else { Message( "Error:  cannot add equipment to database", Get_DBI_Error() ); }
    return 1;
}

#########################               should be earased
sub equipment_list {
#########################
    my %args = @_;
    my $dbc  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $type = $args{-type};
    Message('Warning 102: You should now be here Inform LIMS');
    return;
    my $condition;
    if ($type) { $condition = "WHERE FK_Location__ID=Location_ID AND Equipment_ Type='$type' ORDER BY Equipment_Name"; }
    else {
        $condition = "WHERE FK_Location__ID=Location_ID AND Equipment_Name NOT LIKE 'TBD' ORDER BY Equipment_T ype,Equipment_Name";
    }
    my $Table = $dbc->Table_retrieve_display(
        'Equipment,Location',
        [   qw( Equipment_ID     Equipment_Name
                Serial_Number Location_Name
                Equipment_Status )
        ],
        $condition,
        -toggle_on_column => 3,
        -return_table     => 1
    );

    print $Table->Printout( "$URL_temp_dir/Equipment_List.html", &date_time() ) . $Table->Printout(0);

    return 1;
}

############################
#  Maintenance Routines
############################

#########################
sub change_matrix {
########################
    #
    # Change matrix (NOT DONE - this is accomplished when sample sheets are generated
    #
    my $dbc          = $Connection;
    my $machine_name = shift;
    my $new_matrix   = shift;
    my $user_id      = $dbc->get_local('user_id');

    my $now = &now();

    if ( $new_matrix =~ /Sol(\d+)/ ) { $new_matrix = $1; }

    #    my $description = shift;

    my $ok = 0;

    #    if ($description=~/Matrix/) {#
    unless ($new_matrix) { Message("No Matrix ID entered!"); return 0; }
    my $machine_id = join ',', $dbc->Table_find( 'Equipment', 'Equipment_ID', "where Equipment_Name like '$machine_name'" );
    my ($process_type_id) = $dbc->Table_find( "Maintenance_Process_Type", "Maintenance_Process_Type_ID", "WHERE Process_Type_Name = 'Change Matrix'" );
    $ok = $dbc->Table_append( 'Maintenance', 'FK_Equipment__ID,FK_Solution__ID,FK_Employee__ID,Maintenance_DateTime,FK_Maintenance_Process_Type__ID', "$machine_id,$new_matrix,$user_id,$now,$process_type_id", -autoquote => 1 );
    if ($ok) { Message("Updated Maintenance Record"); }

    #    }
    return $ok;
}

################################
sub change_MatrixBuffer {
##############################
    #
    # This routine changes the Matrix or Buffer for a Sequencer
    #
################################
    my $dbc     = $Connection;
    my $equip   = shift;
    my $sol     = shift;
    my $now     = &date_time();
    my $user_id = $dbc->get_local('user_id');

    my $sols = &get_aldente_id( $dbc, $sol, 'Solution' );
    my $solution = $sols;    #Keep a copy of the ID for querying buffer/matrix later.

    my $reagents = $sols;
    while ( $reagents =~ /[1-9]/ ) {
        $sols .= ",$reagents";
        $reagents = join ',', $dbc->Table_find( 'Mixture', 'FKUsed_Solution__ID', "where FKMade_Solution__ID in ($reagents)" );
    }

    if ($sols) { alDente::Solution::open_bottle($sols); }

    my $buffer;
    my $matrix;
    if ($solution) {
        ($buffer) = $dbc->Table_find( 'Solution', 'Solution_ID', "where Solution_ID in ($solution) and Solution_Type = 'Buffer'" );
        ($matrix) = $dbc->Table_find( 'Solution', 'Solution_ID', "where Solution_ID in ($solution) and Solution_Type = 'Matrix'" );
    }
    my ($matrix_process_type_id) = $dbc->Table_find( "Maintenance_Process_Type", "Maintenance_Process_Type_ID", "WHERE Process_Type_Name = 'Change Matrix'" );
    my ($buffer_process_type_id) = $dbc->Table_find( "Maintenance_Process_Type", "Maintenance_Process_Type_ID", "WHERE Process_Type_Name = 'Change Buffer'" );
    my @equipment_list = split ',', $equip;
    foreach my $equip_id (@equipment_list) {
        ( my $equip_name ) = $dbc->Table_find( 'Equipment', 'Equipment_Name', "where Equipment_ID=$equip_id" );
        my ($completed) = $dbc->Table_find( 'Status', 'Status_ID', "WHERE Status_Name='Completed' AND Status_Type='Maintenance'" );

        if ( $buffer =~ /\d+/ ) {
            my $ok = $dbc->Table_append_array(
                'Maintenance',
                [ 'FK_Equipment__ID', 'FKMaintenance_Status__ID', 'Maintenance_DateTime', 'FK_Employee__ID', 'FK_Solution__ID', 'FK_Maintenance_Process_Type__ID' ],
                [ $equip_id,          $completed,                 $now,                   $user_id,          $buffer,           $buffer_process_type_id ],
                -autoquote => 1
            );
            if   ($ok) { Message("Changed Buffer on $equip_name (equ$equip_id) to sol$buffer"); }
            else       { Message("Error changing Buffer - check with admin"); }
            &alDente::Solution::open_bottle($buffer);    ### ensure bottle labelled as open...
        }
        if ( $matrix =~ /\d+/ ) {
            my $ok = $dbc->Table_append_array(
                'Maintenance',
                [ 'FK_Equipment__ID', 'FKMaintenance_Status__ID', 'Maintenance_DateTime', 'FK_Employee__ID', 'FK_Solution__ID', 'FK_Maintenance_Process_Type__ID' ],
                [ $equip_id,          $completed,                 $now,                   $user_id,          $matrix,           $matrix_process_type_id ],
                -autoquote => 1
            );
            if   ($ok) { Message("Changed Matrix on $equip_name (equ$equip_id) to sol$matrix"); }
            else       { Message("Error changing Buffer - check with admin"); }
            &alDente::Solution::open_bottle($matrix);    ### ensure bottle labelled as open...
        }
    }
    if   ( ( $buffer =~ /\d/ ) || ( $matrix =~ /\d/ ) ) { return 1; }
    else                                                { Message("No valid Buffer or Matrix found in $sol"); }
}

##############################
sub new_maintenance_trigger {
##############################
    my %args           = &filter_input( \@_ );
    my $dbc            = $args{-dbc};
    my $id             = $args{-id};
    my $maintenance_id = $args{-maintenance_id};

    my $repeat = param('Repeat maintenance');

    if ($repeat) {
        my @equip_list = split ',', $repeat;
        shift @equip_list;
        foreach my $equipment (@equip_list) {
            Message("Copy maintenance $maintenance_id record for Equ $equipment");
            $dbc->Table_copy( -table => 'Maintenance', -condition => "where Maintenance_ID = $maintenance_id", -exclude => [ 'Maintenance_ID', 'FK_Equipment__ID' ], -replace => [ undef, $equipment ], -no_triggers => 1 );
        }
    }
    elsif ($maintenance_id) {
        ($id) = $dbc->Table_find( 'Maintenance', 'FK_Equipment__ID', "WHERE Maintenance_ID=$maintenance_id" );
    }
    $id ||= $repeat;
    my ($since) = split ' ', date_time();

    unless ($scanner_mode) { maintenance_stats( -dbc => $dbc, -id => $id, -since => "$since 00:00:00" ) }

    return 1;
}

############################
sub maintenance_home {
##############################
    #
    # Home page for carrying out Maintenance Procedure
    #
################################

    my %args = filter_input( \@_, -args => 'dbc,id' );
    my $dbc            = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id             = $args{-id};                                                                      # equipment id or barcode
    my $maintenance_id = $args{-maintenance_id};

    my %Parameters;                                                                                       # = &Set_Parameters();
    my %Include;
    if ( $id =~ /,/ ) {
        $Include{'Repeat maintenance'} = $id;
        Message("This maintenance record will be applied to Equipment: $id");
        ($id) = split ',', $id;                                                                           ## just use the first one initially (trigger copies maintenance for full list)
    }

    my $maintenance_form = SDB::DB_Form->new(
        -dbc        => $dbc,
        -form_name  => 'Maint',
        -target     => 'Database',
        -table      => 'Maintenance',
        -quiet      => 1,
        -wrap       => 0,
        -start_form => 1,
        -title      => 'Equipment Maintenance Procedure',
        -parameters => \%Parameters
    );
    my %preset;
    my %grey;

    $preset{FK_Equipment__ID} = $dbc->get_FK_info( 'FK_Equipment__ID', $id ) if $id;
    my %list;

    my $equip;
    if ($equipment_id) {
        my $spec = "where Equipment_ID=$equipment_id AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID ";
        $equip = join ',', $dbc->Table_find( 'Equipment,', 'Category', $spec, 'distinct' );
    }
    else {
        $equip = join ',', $dbc->Table_find( 'Equipment_Category', 'Category', 'WHERE 1 Order By Category', 'distinct' );
    }

    my @applied_solutions;
    if ( $equip =~ /Sequencer/ ) {

        if ($equipment_id) {
            my ( $dmatrix, $Mtime ) = &get_MatrixBuffer( $dbc, 'Matrix', $equipment_id );
            my ( $dbuffer, $Btime ) = &get_MatrixBuffer( $dbc, 'Buffer', $equipment_id );
            print "Current Matrix: $dmatrix ($Mtime)<BR>";
            print "Current Buffer: $dbuffer ($Btime)<BR>";
        }
        ########## Generate list of matrices ################

        @applied_solutions = get_FK_info( $dbc, 'FK_Solution__ID', -condition => "(Solution_Type='Matrix' or Solution_Type='Buffer') and Solution_Status = 'Open' ORDER BY Solution_ID", -list => 1 );

        #

        #$dbc->Table_find('Solution left join Stock on FK_Stock__ID=Stock_ID','Solution_ID,Stock_N ame,Solution_Number,Solution_Number_in_Batch',"where (Solution_Type='Matrix' or Solution_Type='Buffer') and Solution_Status = 'Open'");
        #	   $testing =0;
        #	   foreach my $thismatrix (@matrix_info) {
        #	       (my $id,my $name,my $bottle,my $bottles) = split ',',$thismatrix;
        #	       push(@matrix,"$id: $name ($bottle/$bottles)");
        #	   }
    }

    my @equipment_options = get_FK_info( $dbc, 'FK_Equipment__ID', -list => 1 );    ## override since it should also include inactive equipment
    my @contact_options = get_FK_info( $dbc, 'FK_Contact__ID', -condition => "(Contact_Type <> 'Collaborator' OR Contact_Type IS NULL)", -list => 1 );
    my @maintenance_options = get_FK_info( $dbc, 'FK_Status__ID', -condition => "Status_Type = 'Maintenance'", -list => 1 );

    $grey{FK_Equipment__ID}         = $preset{FK_Equipment__ID} if $preset{FK_Equipment__ID};
    $list{FK_Contact__ID}           = \@contact_options;
    $list{FK_Solution__ID}          = \@applied_solutions;
    $list{FKMaintenance_Status__ID} = \@maintenance_options;

    $maintenance_form->configure( -preset => \%preset, -grey => \%grey, -list => \%list, -include => \%Include, -omit => { 'FK_Solution__ID' => '' } );
    $maintenance_form->generate( -list => \%list );

    return 1;
}

#########################################
sub save_maintenance_procedure {
#######################################
    #
    # update database with maintenance procedure
    #
## DEPRECATED (*?) ##
################################

    Call_Stack();
    return 0;

    my $dbc     = $Connection;
    my $process = param('New Procedure');
    $process ||= param('Maintenance_Process');

    $equipment_id ||= param('FK_Equipment__ID');
    $equipment_id = &get_aldente_id( $dbc, $equipment_id, 'Equipment' );

    my $desc = param('Maintenance_Description') || param('Description') || '';

    my $DT  = param('DateTime');
    my $emp = param('Employee');
    if ( $emp =~ /emp(\d+)/ ) { $emp = $1; }
    else {
        $emp = join ',', $dbc->Table_find( 'Employee', 'Employee_ID', "where Employee_Name like '$emp'" );
    }

    my $contact = param('New Employee');
    $contact ||= param('Employee');
    if   ( $contact =~ /(\d+)/ ) { $contact = $1; }
    else                         { $contact = "NULL"; }

    my $matrix;
    $matrix = param('Solution Choice') || param('FK_Solution__ID');
    if   ( $matrix =~ /(\d+)/ ) { $matrix = $1; }
    else                        { $matrix = "NULL"; }

    my $process_id = $dbc->get_FK_ID( 'Maintenance_Process_Type__ID', $process );
    my @fields = ( "FK_Equipment__ID", 'FK_Maintenance_Process_Type__ID', 'Maintenance_Description', 'Maintenance_DateTime', 'FK_Employee__ID', 'FK_Contact__ID', 'FK_Solution__ID' );
    my @values = ( $equipment_id, $process_id, $desc, $DT, $emp, $contact, $matrix );

    my $ok = $dbc->Table_append_array( 'Maintenance', \@fields, \@values, -autoquote => 1 );
    if   ($ok) { Message("Appended Maintenance Procedure to Database"); }
    else       { Message( "Database not updated (tried " . join ',', @fields . " = " . join ',', @values ); }

    return 1;
}

############################
sub maintenance_stats {
############################
    #
    # Show Maintenance history for an equipment of specified type...
    #
    my %args = &filter_input( \@_, -args => 'dbc,type,id' );
    my $dbc            = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $type           = $args{-type};                                                                    ## show maintenance for equipment of a certain type
    my $id             = $args{-id};                                                                      ## show maintenance for specific piece of equipment
    my $since          = $args{-since};
    my $maintenance_id = $args{-maintenance_id};                                                          ## show all maintenance done on a piece of equipment given a maintenance_id

    my $toggle_on = 'Equip';                                                                              ## toggle row colour on first column (Process)
    if ($maintenance_id) {
        ## get equipment if a particular maintenance record is supplied ##
        ($id) = $dbc->Table_find( 'Maintenance', 'FK_Equipment__ID', "WHERE Maintenance_ID=$maintenance_id" );
    }

    my $spec_id = $id ? "" : "and Equipment_ID in (" . get_aldente_id( $dbc, $id, 'Equipment' ) . ")";

    print h2("Maintenance Records");

    print "<UL>";
    foreach my $i ( split ',', $id ) {
        unless ($i) {next}                                                                                ## in case of spurious blanks
        print "<LI>";
        print alDente_ref( -dbc => $dbc, -table => 'Equipment', -id => $i );
        print " : " . Link_To( $dbc->config('homelink'), '(maintenance history)', '&Maintenance History=1&Equipment=$i' );
    }
    print "</ul>";

    my $title     = 'Maintenance Records';
    my @fields    = ( 'Maintenance_ID', 'FK_Maintenance_Process_Type__ID', 'FKMaintenance_Status__ID', 'Maintenance_DateTime', 'FK_Employee__ID as ByEmployee', 'FK_Contact__ID as ByExternal', 'FK_Equipment__ID as Equip', 'Maintenance_Description' );
    my $tables    = 'Maintenance,Equipment';
    my $condition = "where FK_Equipment__ID=Equipment_ID";

    if ($since) {
        $title     .= " (since $since)";
        $condition .= " AND Maintenance_DateTime > '$since'";
    }

    if ($type) {
        $condition .= " and Category = '$type' AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Cateogry__ID = Equipment_Category_ID ";
        $title     .= " (For Equipment of type: $type)";
        $tables    .= ',Stock,Stock_Catalog,Equipment_Category';
    }
    elsif ($id) {

        #        foreach my $single_id (split ',', $id) {
        $title .= ' [' . $dbc->get_FK_info( 'FK_Equipment__ID', $id ) . ']';
        $condition .= " AND Equipment_ID IN ($id)";
        unless ( $id =~ /,/ ) { $toggle_on = 2 }    ## if only one piece of equipment
    }
    elsif ( !$since ) {
        $condition .= " AND Maintenance_DateTime > DATE_SUB(CURDATE(), INTERVAL 1 Month)";
        $title     .= " (within last month)";
    }

    $dbc->Table_retrieve_display( $tables, \@fields, "$condition Order by Equipment_Name ASC,Maintenance_DateTime DESC, Maintenance_ID DESC", -title => $title, -toggle_on_column => $toggle_on );

    return 1;
}

##############################
sub show_cap_stats {
##############################
    my $dbc = $Connection;

    require alDente::alDente_API;

    my $API = new alDente::alDente_API( -dbc => $dbc, -quiet => 1 );

    my $equipment_info = $API->get_equipment_data( -equipment_status => 'In Use', -fields => "equipment_id,latest_maintenance_datetime", -key => "equipment_id", -process_type => 'Change Capillary Array', -quiet => 1 );
    my $table = new HTML_Table( -autosort => 1 );
    $table->Set_Headers( [ "Equipment_Name", "Last Cap Change", "Uses" ] );
    $table->Set_Border('on');
    foreach my $equipment_id ( keys %{$equipment_info} ) {
        my @row         = ();
        my $latest_time = $equipment_info->{$equipment_id}{'latest_maintenance_datetime'};

        $latest_time = &convert_date( $latest_time, 'SQL' );

        my $cap_info = $API->get_run_data( -since => $latest_time, -equipment_id => $equipment_id, -fields => 'equipment_name,capillary_array_count,equipment_id', -key => 'equipment_id', -quiet => 1 );

        my $usage_count    = $cap_info->{$equipment_id}{'capillary_array_count'};
        my $equipment_name = $cap_info->{$equipment_id}{'equipment_name'};
        @row = ( $equipment_name, $latest_time, $usage_count );
        my $colour = '';
        if ( $usage_count > 1000 ) {
            $colour = 'lightredbw';
        }
        elsif ( $usage_count > 500 ) {
            $colour = 'lightyellowbw';
        }

        $table->Set_Row( \@row, -colour => $colour );
    }

    $table->Printout();
    return 1;
}

###################################
sub display_equipment_contents {
###################################
    # Display the equipment contents
    #
    #
###################################
    my %args          = filter_input( \@_, -args => 'id' );
    my $dbc           = $args{-dbc};
    my $id            = $args{-id};
    my $title         = $args{-title} || 'Equipment Contents';
    my $show_barcodes = $args{-show_barcodes};                                                                             ## option to display barcodes for Rack items
    my @racks         = $dbc->Table_find( "Rack", "Rack_ID", "WHERE FKParent_Rack__ID = 0 and FK_Equipment__ID = $id" );

    my $output;
    $output .= &Views::sub_Heading( "$title: " . $dbc->get_FK_info( 'FK_Equipment__ID', $id ) );
    foreach my $rack (@racks) {

        my $total = 0;
        $output .= create_tree(
            -tree  => { $dbc->get_FK_info( 'FK_Rack__ID', $rack ) => alDente::Rack_Views::show_Contents( -dbc => $dbc, -rack_id => $rack, -level => 1, -running_total => \$total, -recursive => 1, -show_barcodes => $show_barcodes ) },
            -print => 0
        );
    }
    return $output;
}

###################################     NEW
sub get_equipment_types {
###################################
    my $self      = shift;
    my %args      = @_;
    my $dbc       = $args{-dbc};    # || $self->param ('dbc');
    my $eq_type   = $args{-type};
    my $condition = 1;
    if ($eq_type) {
        $condition = " Category = '$eq_type'";
    }

    my @types = $dbc->Table_find( 'Equipment_Category', 'Equipment_Category_ID', "WHERE $condition Order by Category,Sub_Category" );
    my @list;
    for my $id (@types) {
        my $list_item = $dbc->get_FK_info( -field => 'FK_Equipment_Category__ID', -id => $id );
        push @list, $list_item;
    }

    return \@list;
}

###################################     NEW
sub get_Equipment_Category {
###########################
    #   Description""
    #      return the category and subcategory of a equipment
    #   Input:  Equipment IDs in comma seperated string
    #   Output: Cateogry and SubCategory depending on return_choice (array reference)
############################
    my %args          = &filter_input( \@_ );
    my $dbc           = $args{-dbc};
    my $ids           = $args{-Equipment_ids};             ## Equipment ids seperated by commas
    my $return_choice = $args{ -return } || 'Category';    ## could also be 'Sub_Catgeory' or 'Combo'
    my @result;
    my $output;
    my $order_by;

    if ( $return_choice eq 'Category' ) {
        $output   = 'Category';
        $order_by = 'Category';
    }
    elsif ( $return_choice eq 'Sub_Category' ) {
        $output   = 'Sub_category';
        $order_by = 'Sub_Category';
    }
    elsif ( $return_choice eq 'Combo' ) {
        $output   = "concat(Category,'-',Sub_Category)";
        $order_by = 'Category, Sub_Category';
    }
    else {
        Message "You have entered a false choice for return choice";
        return;
    }

    @result = $dbc->Table_find_array( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
        [$output], " WHERE FK_Stock__ID = Stock_ID AND Stock_Catalog_ID = FK_Stock_Catalog__ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Equipment_ID IN ($ids)" . ' Order by ' . $order_by, 'Distinct' );
    return \@result;
}

###################################     NEW
sub get_equipment_type_ids {
###################################     NEW
    my $self      = shift;
    my %args      = @_;
    my $dbc       = $args{-dbc};     # || $self->param ('dbc');
    my $names_ref = $args{-names};
    my @names     = @$names_ref;

    my @ids;
    for my $name (@names) {
        my $category_id = $dbc->get_FK_ID( -field => 'FK_Equipment_Category__ID', -value => $name );
        push @ids, $category_id;
    }
    return join ',', @ids;
}

###################################     NEW
sub get_sequencer_list {
###################################     NEW
    my $self             = shift;
    my %args             = @_;
    my $dbc              = $args{-dbc};
    my $include_inactive = $args{-include_inactive};
    my $return_hash      = $args{-hash};
    my $type             = $args{-type} || 'capillary';    # can be 1.capillary 2.illlumina 3.solid 4.all
    my @sequencers;
    my %sequencers;

    my $condition = "WHERE FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID ";

    $condition .= " AND Category = \"Sequencer\" ";
    unless ($include_inactive) { $condition .= " AND Equipment_Status= 'In Use' " }

    if    ( $type eq 'capillary' ) { $condition .= " AND Sub_Category IN ('3700','3730','3100','MB') " }
    elsif ( $type eq 'illumina' )  { $condition .= " AND Sub_Category IN ('Genome Analyzer') " }
    elsif ( $type eq 'illumina' )  { $condition .= " AND Sub_Category IN ('Solid') " }

    my @equip_ids = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category', 'Equipment_ID,Equipment_Name', "$condition  ORDER BY Equipment_Name" );

    foreach my $equip (@equip_ids) {
        ( my $id, my $name ) = split ',', $equip;
        push( @sequencers, &get_FK_info( $dbc, 'FK_Equipment__ID', $id ) );
        $sequencers{$id} = $name;
    }

    if ($return_hash) {
        return \%sequencers;
    }
    else {
        return \@sequencers;
    }
}

##############################
sub define_demo_category {
##############################
    my $self         = shift;
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc} || $self->{dbc};
    my $equipment_id = $args{-equipment_id} || $self->{id};

    my @equipment_list = $dbc->Table_find(
        'Equipment,Stock,Stock_Catalog, Equipment_Category',
        'Stock_Catalog_ID,FK_Equipment_Category__ID, Stock_Catalog_Name, Prefix, Sub_Category',
        "WHERE FK_Stock__ID=Stock_ID AND FK_Stock_Catalog__ID=Stock_Catalog_ID AND FK_Equipment_Category__ID=Equipment_Category_ID AND Equipment_ID IN ($equipment_id)"
    );

    $dbc->start_trans('define_demo');
    foreach my $current (@equipment_list) {
        my ( $catalog, $category, $catalog_name, $prefix, $sub_category ) = split ',', $current;
        my ($existing) = $dbc->Table_find( 'Stock_Catalog,Equipment_Category', 'Stock_Catalog_Name', "WHERE FK_Equipment_Category__ID=Equipment_Category_ID AND Prefix like '$prefix\_x'" );
        if ($existing) { Message("$existing already exists"); next }

        my ($new_category)
            = $dbc->Table_copy( -table => 'Equipment_Category', -exclude => [ 'Equipment_Category_ID', 'Prefix', 'Sub_Category' ], -replace => [ '', $prefix . '_x', $sub_category . '-DEMO' ], -condition => "WHERE Equipment_Category_ID = '$category'" );

        my $new_catalog = $dbc->Table_copy(
            -table     => 'Stock_Catalog',
            -exclude   => [ 'Stock_Catalog_ID', 'FK_Equipment_Category__ID', 'Stock_Catalog_Name' ],
            -replace   => [ '', $new_category, $catalog_name . ' - DEMO / SAMPLE' ],
            -condition => "WHERE Stock_Catalog_ID = '$catalog'"
        );
    }
    $dbc->finish_trans('define_demo');

    return 1;
}
##########################
sub get_MatrixBuffer {
##########################
    #
    # Extract current Matrix or Buffer from given machine...
    #
    my $dbc     = shift;
    my $type    = shift;
    my $machine = shift;

    my $machine_condition = "AND FK_Equipment__ID=$machine ";
    unless ( $machine =~ /\d+/ ) {
        $dbc->warning("No Machine ID specified ($machine)");
        return;
    }

    if ( $type =~ /Matrix|Buffer/ ) {
        ( my $info ) = $Connection->Table_find(
            'Maintenance,Maintenance_Process_Type',
            'FK_Solution__ID,Maintenance_DateTime',
            "where FK_Maintenance_Process_Type__ID=Maintenance_Process_Type_ID AND Process_Type_Name = 'Change $type' $machine_condition Order by Maintenance_DateTime desc limit 1"
        );

        my ( $id, $time ) = split ',', $info;
        return ( $id, $time );

    }
    else { print "no type chosen..."; return; }
}

##########################
sub _get_equipment_name {
##########################
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $category_id = $args{-category_id};

    my $command = "Concat(Max(Replace(Equipment_Name,concat(Prefix,'-'),'') + 1)) as Next_Name";
    my $name;
    ($name) = $dbc->Table_find_array(
        'Equipment_Category',
        -fields    => ['Prefix'],
        -condition => "WHERE Equipment_Category_ID=$category_id"
    );
    my ($number) = $dbc->Table_find_array( 'Equipment,Equipment_Category,Stock,Stock_Catalog',
        [$command], "WHERE  FK_Stock__ID = Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND  FK_Equipment_Category__ID=Equipment_Category_ID AND Equipment_Category_ID=$category_id" );

    unless ($number) { $number = 1 }
    return ( $name, $number );
}

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

$Id: Equipment.pm,v 1.47 2004/11/10 20:09:14 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
