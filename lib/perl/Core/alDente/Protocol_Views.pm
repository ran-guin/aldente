###################################################################################################################################
# alDente::Protocol_Views.pm
#
# Interface generating methods for the Protocol MVC  (associated with Protocol.pm, Protocol_App.pm)
#
###################################################################################################################################
package alDente::Protocol_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use LampLite::CGI;

## Local modules ##

## SDB modules
#use SDB::CustomSettings;
#use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::RGmath;
use RGTools::Views;

use alDente::Security;

## alDente modules

use vars qw( %Configs );

my $q = new LampLite::CGI;

my %Tooltips;
$Tooltips{Step_Type}{Standard}     = 'Steps that do not involve creating of new barcodes';
$Tooltips{Step_Type}{Transfer}     = 'Transfer sample from one container to a new container';
$Tooltips{Step_Type}{Aliquot}      = 'Aliquot sample from one container to a new container';
$Tooltips{Step_Type}{'Pre-Print'}  = 'Pre-print new container barcode to be used at a later transfer/aliquot step';
$Tooltips{Step_Type}{Pool}         = 'Pool samples from multiple containers into a new container';
$Tooltips{Step_Type}{'Setup'}      = 'Prepare empty plate and transfer the sample later';
$Tooltips{Step_Type}{'Throw Away'} = 'Throw away all plates that have been
used in the protocol so far';

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;
    my $dbc   = $args{-dbc};      #   || $self->param('dbc');
    my $admin = $args{-admin};    # || $self->param('admin');

    if ( !$admin ) {              # check the user access in case no Admin param passed in
        my $access = $dbc->get_local('Access');
        if ( ( grep {/Admin/xmsi} @{ $access->{$Current_Department} } ) || $access->{'LIMS Admin'} ) {
            $admin = '1';
        }
    }

    #$self->param( 'dbc'   => $dbc );	# Can't use like this. my $dbc = $self->param('dbc') will always get $dbc = 'dbc'
    #$self->param( 'admin' => $admin );	# Can't use like this. my $admin = $self->param('admin') will always get $admin = 'admin'
    $self->{dbc}   = $dbc;
    $self->{admin} = $admin;

    return $self;
}

##

#############################################
#
# Standard view for single Protocol record
#
#
# Return: html page
###################
sub home_page {
###################
    my $self     = shift;
    my %args     = filter_input( \@_, 'id' );
    my $dbc      = $args{-dbc} || $self->{'dbc'};
    my $user_id  = $dbc->get_local('user_id');
    my $id       = $args{-id};
    my $protocol = $args{-protocol};
    my $admin    = $args{-admin} || $self->{admin};
    my $Security = alDente::Security->new( -dbc => $dbc, -user_id => $user_id, -dbase => $dbase );
    my @protocols;

    my @protocols = @{ $dbc->Security->get_accessible_items( -table => 'Lab_Protocol', -extra_condition => "Lab_Protocol_Status <> 'Archived'" ) };

#    my $page .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Protocol' );
    
    my $page = section_heading("Protocols");
    
#    $page .= $q->submit( -name => 'rm', -value => 'Refresh Protocol List', -class => 'Std', -force => 1 );
#     $page .=  $q->submit( -name => 'rm', -value => 'Create New Protocol', -class => 'Std',    -force => 1 );

     my $Form = new LampLite::Form(-dbc=>$dbc);
#    $Form->append( subsection_heading('Select Protocol');
    $Form->append( $q->submit( -name => 'rm', -value => 'Refresh Protocol List', -class => 'Std', -force => 1 ) );
    $Form->append($q->submit( -name => 'rm', -value => 'Create New Protocol', -class => 'Std',    -force => 1 ) );
    $Form->append( $q->hr );
    $Form->append( $Form->View->prompt(-table=>'Protocol_Step', -field=>'FK_Lab_Protocol__ID') );
     
#        . &alDente::Tools::search_list('Select Protocol')
#        -dbc     => $dbc,
#        -form    => 'Protocol',
#        -field   => 'Prep.FK_Lab_Protocol__ID',
#        -name    => 'Lab_Protocol',
##        -options => \@protocols,
 #       -filter  => 1,
 #       -search  => 1
 #       )
#        . vspace()
    
    $Form->append( $q->submit( -name => 'rm', -value => 'View Protocol', -class => 'Std', -force => 1 ) . $q->checkbox( -name => 'Include Instructions', -label => ' Include Instructions' ) );

    my $include = $q->hidden( -name => 'cgi_application', -value => 'alDente::Protocol_App', -force => 1 );
 
    if ($admin && $user_id ) {
        $Form->append( subsection_heading('Administrative Functions'));
        $Form->append( $q->submit( -name => 'rm', -value => 'Delete Protocol',     -class => 'Action', -force => 1 ) );
        $Form->append( $q->submit( -name => 'rm', -value => 'Edit Protocol Name',       -class => 'Action', -force => 1 ) );
        $Form->append( $q->submit( -name => 'rm', -value => 'Edit Protocol Visibility', -class => 'Std',    -force => 1 ) . " (which groups have access)" );
        $Form->append( $q->submit( -name => 'rm', -value => 'Restrict Access', -class => 'Action', -force => 1 ) );
    }
    else {
        $Form->append( $q->submit( -name => 'Administrative Access', -class => 'Std', -force => 1 ) );        
    }
        
    if (0 && $admin && $user_id ) {
        $page
            .= $q->hr
            . $q->h3("Administrative Functions:")
            . $q->submit( -name => 'rm', -value => 'Create New Protocol', -class => 'Std',    -force => 1 )
            . $q->submit( -name => 'rm', -value => 'Delete Protocol',     -class => 'Action', -force => 1 ) . '<br>'
            . $q->textfield( -name => 'Protocol Name', -size => 20 )
            . &hspace(10)
            . $q->submit( -name => 'rm', -value => 'Edit Protocol Name',       -class => 'Action', -force => 1 ) . '<br>'
            . $q->submit( -name => 'rm', -value => 'Edit Protocol Visibility', -class => 'Std',    -force => 1 )
            . HTML_Comment(" (which groups have access)")
            . $q->submit( -name => 'rm', -value => 'Restrict Access', -class => 'Action', -force => 1 );
    }
    else {
#        $page .= $q->submit( -name => 'Administrative Access', -class => 'Std', -force => 1 );
    }
    
    $page .= $Form->generate(-wrap=>1, -include=>$include);

#    $page .= $q->end_form;
    return $page;
}

#############################################################
# Standard view for multiple Protocol records if applicable
#
#
# Return: html page
#################
sub list_page {
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $id   = $args{-id};

    my $Protocol = $self->param('Protocol');
    my $dbc      = $Protocol->param('dbc');

    my $page;

    return $page;
}

#####################
sub edit_Protocol_Visibility {
#####################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $admin    = $args{-admin} || $self->{admin};
    my $protocol = $args{-protocol};
    my $page;

    my @defaults = Table_find( $dbc, 'Lab_Protocol,GrpLab_Protocol', 'FK_Grp__ID', "WHERE Lab_Protocol_ID=FK_Lab_Protocol__ID AND Lab_Protocol_Name = '$protocol'" );
    my $default_groups = join ',', @defaults;
    my @default_group_list;
    @default_group_list = $dbc->get_FK_info( -field => "FK_Grp__ID", -list => 1, -condition => "WHERE Grp_ID IN ($default_groups) " ) if $default_groups;
    my ( $valid_groups, $defaults ) = _get_groups_info( -dbc => $dbc, -access => 'Admin' );

    $page .= $q->h1("Editing Protocol $protocol");
    $page .= alDente::Form::start_alDente_form(
        -dbc  => $dbc,
        -name => 'edit_protocol',
        -type => 'start'
        )
        . $q->scrolling_list( -name => 'GrpLab_Protocol', -multiple => 'true', -values => $valid_groups, -default => \@default_group_list, -force => 1 )
        . vspace()
        . $q->hidden( -name => 'Protocol',        -value => "$protocol",             -force => 1 )
        . $q->hidden( -name => 'cgi_application', -value => "alDente::Protocol_App", -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Update Access', -class => 'Action', -force => 1 )
        .

        #  $q -> submit( -name => 'rm', -value => 'Restrict Access', -class => 'Action' ).
        $q->end_form;

}

#####################
sub save_New_Protocol_View {
#####################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $admin    = $args{-admin} || $self->{admin};
    my $protocol = $args{-protocol};

    my @groups = Cast_List( -list => $dbc->get_local('group_list'), -to => 'array' );
    my @valid_groups;
    foreach my $grp (@groups) {
        push @valid_groups, $dbc->get_FK_info( 'FK_Grp__ID', $grp );
    }
    @valid_groups = sort @valid_groups;
    my $table = HTML_Table->new( -colour => 'white', -border => 0 );
    $table->Set_Row( [ $q->h4("New Protocol Name: "), $q->h4("In Group") ] );
    $table->Set_Row( [ $q->textfield( -name => 'New Name', -size => 20 ), $q->popup_menu( -name => "New Group", -values => \@valid_groups ) ] );
    $table->Set_Row( [ $q->checkbox( -name => 'Active' ) ] );
    $table->Set_Row( [ $q->submit( -name => 'rm', -value => 'Confirm Save As New Protocol', -class => 'Action' ) ] );

    my $page = $q->h1("Saving Current Protocol as a New Protocol") . '<BR>';
    $page
        .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'copy_protocol' )
        . $q->hidden( -name => 'cgi_application', -value => "alDente::Protocol_App", -force => 1 )
        . $q->hidden( -name => 'Protocol',        -value => "$protocol",             -force => 1 )
        . $q->hidden( -name => 'Admin',           -value => "$admin",                -force => 1 )
        . set_validator( -name => 'New Name',  -mandatory => 1 )
        . set_validator( -name => 'New Group', -mandatory => 1 )
        . $table->Printout(0)
        . $q->end_form;

    return $page;
}

#####################
sub new_protocol_prompt {
#####################

    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc} || $self->{dbc};
    my $admin = $args{-admin} || $self->{admin};
    my $page;

    $page .= $q->h1("Creating New Protocol");
    $page .= $q->h2("New Protocol Name:");
    $page .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'New_protocol' );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Protocol_App', -force => 1 );
    $page .= $q->textfield( -name => 'New Protocol Name', -size => 40, -default => '', -force => 1 );
    $page .= $q->h2("New Protocol Description:")
        . $q->textarea(
        -name  => 'Protocol Description',
        -rows  => 2,
        -cols  => 60,
        -value => '',
        -force => 1
        );

    # Allow user to specify which group the protocol belongs to.
    # Only show groups that the user has Admin access
    my ( $valid_groups, $defaults ) = _get_groups_info( -dbc => $dbc, -access => 'Admin' );
    my $default;
    if ( $defaults && exists $defaults->[0] ) { $default = $defaults->[0] }
    $page .= $q->h2("Groups:");

    $page .= &alDente::Tools::search_list(
        -dbc     => $dbc,
        -form    => 'New_protocol',
        -name    => 'GrpLab_Protocol',
        -options => $valid_groups,
        -default => $default,
        -filter  => 1,
        -search  => 1,
        -mode    => 'Scroll',
        -sort    => 1
        )
        . vspace()
        . vspace()
        . vspace();

    # Allow user to specify which Invoice_Protocol gets paired with.
    $page .= $q->checkbox( -name => 'invoiced', -label => 'Invoiceable?', -checked => 0 );

    my @invoice_protocol_list = $dbc->Table_find( 'Invoice_Protocol', "Invoice_Protocol_Name",   -distinct => 1 );
    my @Invoice_Type_list     = $dbc->Table_find( 'Invoice_Protocol', "Invoice_Protocol_Type",   -distinct => 1 );
    my @Tracked_Prep_Name     = $dbc->Table_find( 'Invoice_Protocol', "Tracked_Prep_Name",       -distinct => 1 );
    my @Invoice_status        = $dbc->Table_find( 'Invoice_Protocol', "Invoice_Protocol_Status", -distinct => 1 );

    $page .= $q->h2("Matching Invoice Protocol:");
    $page .= &alDente::Tools::search_list(
        -dbc     => $dbc,
        -form    => 'New_protocol',
        -name    => 'Invoice_Protocol',
        -options => \@invoice_protocol_list,
        -default => $defaults,
        -filter  => 1,
        -search  => 1,
        -mode    => 'Scroll',
        -sort    => 1
        )
        . vspace()
        . "To create new Invoice protocol, create new lab_protocol first then go to Invoice_Protocol view to create a matching new Invoice Protocol";

    $page .= $q->h2("Invoice Protocol Type:");
    $page .= &alDente::Tools::search_list(
        -dbc     => $dbc,
        -form    => 'New_protocol',
        -name    => 'Invoice_Protocol_Type',
        -options => \@Invoice_Type_list,
        -default => $defaults,
        -filter  => 1,
        -search  => 1,
        -mode    => 'Scroll',
        -sort    => 1
    ) . vspace();

    $page .= $q->h2("Invoice Protocol Status:");
    $page .= &alDente::Tools::search_list(
        -dbc     => $dbc,
        -form    => 'New_protocol',
        -name    => 'Invoice_status',
        -options => \@Invoice_status,
        -default => $defaults,
        -filter  => 1,
        -search  => 1,
        -mode    => 'Scroll',
        -sort    => 1
    ) . vspace();

    $page .= $q->h2("Tracked Prep Name:");
    $page .= &alDente::Tools::search_list(
        -dbc     => $dbc,
        -form    => 'New_protocol',
        -name    => 'Tracked_Prep_Name',
        -options => \@Tracked_Prep_Name,
        -default => $defaults,
        -filter  => 1,
        -search  => 1,
        -mode    => 'Scroll',
        -sort    => 1
        )
        . vspace()
        . vspace();

    #set certain field(s) mandatory
    $page .= set_validator( -name => "GrpLab_Protocol Choice", -mandatory => 1 );
    $page .= set_validator( -name => "New Protocol Name",      -mandatory => 1 );
    $page .= $q->submit( -name => 'rm', -value => 'Save New Protocol', -class => 'Std', -onClick => "return validateForm(this.form)", -force => 1 );

    #require alDente::Invoice_Protocol;
    #    $page .= submit( -name => 'new', -value => 'Create New Invoice Protocol', -onClick => alDente::Invoice_Protocol::create_protocol_btn());

    $page .= $q->end_form();
    return $page;
}

#####################
sub display_Step_Page {
#####################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $admin       = $args{-admin} || $self->{admin};
    my $allow_edit  = $args{-allow_edit};
    my $new_step    = $args{-new_step};
    my $step_number = $args{-step_number};
    my $protocol    = $args{-protocol};
    my $preset      = $args{-preset};

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc, ) . $self->display_Step_Top( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -allow_edit => $allow_edit, -new_step => $new_step, -step_number => $step_number );
    $page .= $self->display_Step_Form( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -new_step => $new_step, -step_number => $step_number, -preset => $preset );
    $page .= $self->display_Step_Buttons( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -allow_edit => $allow_edit, -new_step => $new_step, -step_number => $step_number, -preset => $preset ) . $q->end_form;

    return $page;
}

#####################
sub display_Step_Top {
#####################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $admin       = $args{-admin} || $self->{admin};
    my $allow_edit  = $args{-allow_edit};
    my $new_step    = $args{-new_step};
    my $step_number = $args{-step_number};
    my $protocol    = $args{-protocol};

    my $page;
    if ($new_step) {
        $page .= $q->h1("Adding New Step ($step_number) to '$protocol'");
    }
    elsif ($allow_edit) {
        $page .= $q->h1("Editing Step ($step_number) in '$protocol'");
    }
    else {
        $page .= $q->h1("Viewing Step ($step_number) in '$protocol'");
    }

    return $page;
}

#####################
sub display_Step_Form {
#####################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $admin       = $args{-admin} || $self->{admin};
    my $protocol    = $args{-protocol};
    my $preset      = $args{-preset};
    my $step_number = $args{-step_number};

    my $step_name_link = &Link_To( $dbc->config('homelink'), 'Step Name **', "&Online+Help=Protocol+Formats", '', ['newwin'] );
    my $number = $preset->{Protocol_Step_Number}[0] || $step_number;

    my $page = HTML_Table->new( -colour => 'white', -border => 1 );
    $page->Set_Row( [ $q->h3("Step Number **"), $q->textfield( -name => 'Step Number', -size => 5, -value => $number, -force => 1 ) ] );
    $page->Set_Row( [ $q->h3($step_name_link), $self->display_Step_Name( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -preset => $preset ) ] );
    $page->Set_Row( [ $q->h3("Scanner"), Show_Tool_Tip( $q->checkbox( -name => 'Scanner', -checked => $preset->{Scanner}[0], -force => 1, -label => 'Scanner View enabled', -force => 1 ), "Prompt user to indicate when this step is completed" ) ] );
    $page->Set_Row( [ $q->h3("Quality Control"), $self->display_QC( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -preset => $preset ) ] );
    $page->Set_Row( [ $q->h3("Validate"), $self->display_Validate( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -preset => $preset ) ] );
    $page->Set_Row( [ $q->h3("Step Message") . $q->h4("(concise)"), Show_Tool_Tip( $q->textfield( -name => 'Message', -value => $preset->{Protocol_Step_Message}[0], -force => 1, -size => 40 ), "Concise message - will be displayed on handheld scanners" ) ] );
    $page->Set_Row(
        [   $q->h3("Step Instructions"),
            Show_Tool_Tip( $q->textarea( -name => "Step Instructions", -value => $preset->{Protocol_Step_Instructions}[0], -force => 1, -cols => 80, -rows => 5, -wrap => 'virtual' ), "More detailed instructions available to user only if requested" )
        ]
    );
    $page->Set_Row( [ $q->h3("Input"), $self->display_Input_Form( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -preset => $preset ) ] );
    $page->Set_Column_Colour( 1, 'lightblue' );
    $page->Set_Column_Colour( 2, 'lightyellow' );

    return $page->Printout(0);

}

#####################
sub display_Input_Form {
#####################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $admin    = $args{-admin} || $self->{admin};
    my $protocol = $args{-protocol};
    my $preset   = $args{-preset};
    my $D_plateattr;

    my @plates_unit_list = $dbc->get_enum_list( 'Plate', 'Current_Volume_Units' );
    my @inputs, my @defaults, my @formats, my @prepattr_pos, my @plateattr_pos;
    @inputs        = @{ $preset->{Input} }                    if $preset->{Input};
    @defaults      = @{ $preset->{Defaults} }                 if $preset->{Defaults};
    @formats       = @{ $preset->{Formats} }                  if $preset->{Formats};
    @prepattr_pos  = @{ $preset->{Prep_Attribute_Position} }  if $preset->{Prep_Attribute_Position};
    @plateattr_pos = @{ $preset->{Plate_Attribute_Position} } if $preset->{Plate_Attribute_Position};

    my $equ_pos   = $preset->{Equipment_Position}[0];
    my $quant_pos = $preset->{Quant_Position}[0];
    my $sol_pos   = $preset->{Solution_Position}[0];
    my $split_pos = $preset->{Split_Position}[0];
    my $track_pos = $preset->{Track_Position}[0];
    my $rack_pos  = $preset->{Rack_Position}[0];
    my $label_pos = $preset->{Label_Position}[0];

    my $input = join( ',', @inputs );
    my $Input = HTML_Table->new( -border => 1, -width => '100%' );
    $Input->Set_Headers( [ 'Input', 'Mandatory', 'Format', 'Default' ], 'lightbluebw' );

    #####   Equipment   ####
    my $mand_fk_equ = ( $input =~ /Mandatory_Equipment/ );
    my $E_check     = ( $input =~ /FK_Equipment__ID/ );      ## currently set to checked
    my @E_format    = '';
    if ($E_check) { @E_format = split( '\|', $formats[$equ_pos] ) }
    my @Categories     = $dbc->Table_find( 'Equipment_Category', 'Category',     'ORDER BY Category' -distinct     => 1 );
    my @Sub_Categories = $dbc->Table_find( 'Equipment_Category', 'Sub_Category', 'ORDER BY Sub_Category' -distinct => 1 );

    $Input->Set_Row(
        [   Show_Tool_Tip( $q->checkbox( -name => 'Input', -value => 'FK_Equipment__ID', -label => 'Equipment', -checked => $E_check, -force => 1 ), "Prompt user for equipment used for this step" ),
            $q->checkbox( -name => 'Input', -value => 'Mandatory_Equipment', -checked => $mand_fk_equ, -force => 1, -label => '' ),
            Show_Tool_Tip(
                $q->scrolling_list(
                    -name     => 'MFormat',
                    -values   => [ '', '--- Categories ---', @Categories, '--- Sub_Categories ---', @Sub_Categories ],
                    -default  => \@E_format,
                    -force    => 1,
                    -multiple => 1,
                    -size     => 5
                ),
                "Specify Equipment Category to validate for<BR>* Hold down the Control key to select multiple<BR>* Specific Sub_Categories are listed after main Categories below"
            ),
            '&nbsp'
        ]
    );

    #####   Solution   ####
    my $S_check = ( $input =~ /FK_Solution__ID/ );    ## currently set to checked
    my ( $Qty_default, $Qty_units ) = ( '', 'mL' );
    my $S_format = '';
    if ($S_check) {
        ( $Qty_default, $Qty_units ) = RGTools::Conversion::get_amount_units( lc $defaults[$quant_pos] );
        $S_format = $formats[$sol_pos];
    }
    my $mand_fk_sol = ( $input =~ /Mandatory_Solution/ );
    my $mandatory_sol_check = $q->checkbox( -name => 'Input', -value => 'Mandatory_Solution', -checked => $mand_fk_sol, -force => 1, -label => '' );

    $Input->Set_Row(
        [   Show_Tool_Tip( $q->checkbox( -name => 'Input', -value => 'FK_Solution__ID', -label => 'Solution', -checked => $S_check, -force => 1 ), "Prompt user for reagent/solution used for this step" ),
            $mandatory_sol_check,
            Show_Tool_Tip( $q->textfield( -name => 'SFormat', -default => $S_format, -size => 15, -force => 1 ), "Specify name pattern of solution required.  Stock used must CONTAIN this string.  (use | for multiple possibilities ..eg. 'H20|Water')" )
                . '(optional)',
            "Qty: " . $q->textfield( -name => 'Quantity', -value => $Qty_default, -size => 8, -force => 1 ) . $q->popup_menu( -name => "Quantity_Units", -values => \@plates_unit_list, -default => $Qty_units )
        ]
    );

    #####   Transfer  ######
    my $T_check = ( $input =~ /Track_Transfer/ );
    my ( $T_qty, $T_units ) = ( '', 'mL' );
    if ($T_check) { ( $T_qty, $T_units ) = RGTools::Conversion::get_amount_units( lc $defaults[$track_pos] ) }
    my $split_check = ( $input =~ /Split/ );
    my $split_value = 0;
    if ($split_check) { $split_value = $defaults[$split_pos] }

    $Input->Set_Row(
        [   Show_Tool_Tip(
                $q->checkbox( -name => 'Input', -value => 'Track_Transfer', -label => 'Track Transfer Qty', -checked => $T_check, -force => 1 ),
                "For Transfer/Aliquot/Pool steps only:  Prompt user to supply volume to transfer between containers (if applicable)"
                )
                . "(required for splitting)",
            "&nbsp", "&nbsp",
            "Qty: " . $q->textfield( -name => "Transfer_Quantity", -size => 8, -value => $T_qty, -force => 1 ) . ' ' . $q->popup_menu( -name => "Transfer_Quantity_Units", -values => \@plates_unit_list, -default => $T_units, -force => 1 )
        ]
    );
    $Input->Set_Row( [ $q->checkbox( -name => 'Input', -value => 'Split', -label => 'Split', -checked => $split_check, -force => 1 ), "&nbsp", "&nbsp", "Split:" . $q->textfield( -name => "Split_X", -size => 8, -value => $split_value, -force => 1 ) ] );

    #####   Rack   #####
    my $R_check         = ( $input =~ /Rack/ );
    my $PrepAttr_check  = ( $input =~ /Prep_Attribute/ );
    my $PlateAttr_check = ( $input =~ /Plate_Attribute/ );
    my $Time_check      = ( $input =~ /Time/ );
    my $Comments_check  = ( $input =~ /Comments/ );
    my $Inherited_check = ( $input =~ /Comments/ );
    my $D_rack;
    $D_rack = $formats[$rack_pos] if $R_check;
    my $mand_rack = ( $input =~ /Mandatory_Rack/ );

    $Input->Set_Row(
        [   Show_Tool_Tip( $q->checkbox( -name => 'Input', -value => 'FK_Rack__ID', -label => 'Location', -checked => $R_check, -force => 1 ), "Prompt user for rack on which to place target plates" ),
            $q->checkbox( -name => 'Input', -value => 'Mandatory_Rack', -checked => $mand_rack, -force => 1, -label => '' ),
            "&nbsp", '&nbsp'
        ]
    );

    ##### Prep Conditions #####
    my @prep_attributes = $dbc->Table_find('Attribute', 'Attribute_Name', "Where Attribute_Class='Prep'" );
    unshift( @prep_attributes, '' );
    my $D_prepattr = '';
    my $definePrepAttribute_link
        = &Link_To( $dbc->config('homelink'), 'Define New', "&cgi_application=alDente::Attribute_App&rm=Define+Attribute&Class=Prep", '', ['newwin'], -tooltip => "Please reload the page after defining a new attribute" );

    if ( scalar(@prepattr_pos) > 0 ) {
        my $clone_index;
        my $index = 0;
        foreach my $prepattr_pos (@prepattr_pos) {
            $index++;
            my ( $attr_class, $attr_name ) = split( '=', $inputs[$prepattr_pos] );
            $D_prepattr = $defaults[$prepattr_pos] if $PrepAttr_check;

            my $mand_str                  = 'Mandatory_PrepAttribute_' . $index;
            my $mand_attribute            = ( $input =~ /Mandatory_PrepAttribute_$attr_name/ );
            my $mandatory_attribute_check = $q->checkbox( -name => 'Input', -value => "$mand_str", -checked => $mand_attribute, -force => 1, -label => '' );
            $Input->Set_Row(
                [   Show_Tool_Tip( $q->checkbox( -name => 'Input', -value => "Prep_Attribute_$index", -label => 'Prep Attribute', -checked => $PrepAttr_check, -force => 1 ), "Prompt user to supply Prep Attribute" )
                        . &hspace(5)
                        . Show_Tool_Tip( $q->popup_menu( -name => 'Prep Attributes', -values => \@prep_attributes, -default => $attr_name, -force => 1 ) . "<BR>" . $definePrepAttribute_link, "Prompt user to supply preparation conditions" ),
                    $mandatory_attribute_check,
                    "&nbsp",
                    $q->textfield( -name => 'Prep_Attribute_Def', -size => 15, -default => $D_prepattr, -force => 1 ),
                ],
                -repeat      => 1,
                -clone_index => $clone_index
            );
            $clone_index = $Input->{clone_index}{ $Input->rows() };
        }
    }
    else {
        my $index                     = 1;
        my $mand_str                  = 'Mandatory_PrepAttribute_' . $index;
        my $mandatory_attribute_check = $q->checkbox( -name => 'Input', -value => "$mand_str", -checked => 0, -force => 1, -label => '' );
        $Input->Set_Row(
            [   Show_Tool_Tip( $q->checkbox( -name => 'Input', -value => "Prep_Attribute_$index", -label => 'Prep Attribute', -checked => $PrepAttr_check, -force => 1 ), "Prompt user to supply Prep Attribute" )
                    . &hspace(5)
                    . Show_Tool_Tip( $q->popup_menu( -name => 'Prep Attributes', -values => \@prep_attributes, -default => '', -force => 1 ) . "<BR>" . $definePrepAttribute_link, "Prompt user to supply preparation conditions" ),
                $mandatory_attribute_check,
                "&nbsp",
                $q->textfield( -name => 'Prep_Attribute_Def', -size => 15, -default => $D_prepattr, -force => 1 ),
            ],
            -repeat => 1
        );
    }

    ##### Plate attributes #####
    my $definePlateAttribute_link
        = &Link_To( $dbc->config('homelink'), 'Define New', "&cgi_application=alDente::Attribute_App&rm=Define+Attribute&Class=Plate", '', ['newwin'], -tooltip => "Please reload the page after defining a new attribute" );
    my @plate_attributes = $dbc->Table_find( 'Attribute', 'Attribute_Name', "Where Attribute_Class='Plate'" );
    unshift( @plate_attributes, '' );

    if ( scalar(@plateattr_pos) > 0 ) {
        my $clone_index;
        my $index = 0;
        foreach my $plateattr_pos (@plateattr_pos) {
            $index++;
            my ( $attr_class, $attr_name ) = split( '=', $inputs[$plateattr_pos] );
            $D_plateattr = $defaults[$plateattr_pos] if $PlateAttr_check;

            my $mand_str                  = 'Mandatory_PlateAttribute_' . $index;
            my $mand_attribute            = ( $input =~ /Mandatory_PlateAttribute_$attr_name/ );
            my $mandatory_attribute_check = $q->checkbox( -name => 'Input', -value => "$mand_str", -checked => $mand_attribute, -force => 1, -label => '' );
            $Input->Set_Row(
                [   Show_Tool_Tip( $q->checkbox( -name => 'Input', -value => "Plate_Attribute_$index", -label => 'Plate Attribute', -checked => $PlateAttr_check, -force => 1 ), "Prompt user to supply Plate Attribute" )
                        . &hspace(5)
                        . $q->popup_menu( -name => 'Plate Attributes', -values => \@plate_attributes, -default => $attr_name, -force => 1 )
                        . lbr
                        . $definePlateAttribute_link,
                    $mandatory_attribute_check, '&nbsp;', $q->textfield( -name => 'Plate_Attribute_Def', -size => 15, -default => $D_plateattr, -force => 1 )
                ],
                -repeat      => 1,
                -clone_index => $clone_index
            );

            $clone_index = $Input->{clone_index}{ $Input->rows() };
        }
    }
    else {
        my $index                     = 1;
        my $mand_str                  = 'Mandatory_PlateAttribute_' . $index;
        my $mandatory_attribute_check = $q->checkbox( -name => 'Input', -value => "$mand_str", -checked => 0, -force => 1, -label => '' );
        $Input->Set_Row(
            [   Show_Tool_Tip( $q->checkbox( -name => 'Input', -value => "Plate_Attribute_$index", -label => 'Plate Attribute', -checked => $PlateAttr_check, -force => 1 ), "Prompt user to supply Plate Attribute" )
                    . &hspace(5)
                    . Show_Tool_Tip( $q->popup_menu( -name => 'Plate Attributes', -values => \@plate_attributes, -default => '', -force => 1 ) . "<BR>" . $definePlateAttribute_link, "Specify attribute you want to record" ),
                $mandatory_attribute_check,
                "&nbsp",
                $q->textfield( -name => 'Plate_Attribute_Def', -size => 15, -default => $D_plateattr, -force => 1 )
            ],
            -repeat => 1
        );
    }

    ##### Plate Label #####
    my $label_check = ( $input =~ /Plate_Label/ );
    my $plate_label_def = "";
    $plate_label_def = $defaults[$label_pos] if $defaults[$label_pos];
    $Input->Set_Row(
        [   Show_Tool_Tip( $q->checkbox( -name => 'Input', -value => 'Plate_Label', -label => 'Target Label', -checked => $label_check, -force => 1 ), "Prompt user to supply a label for Target Plate(s) - (only applicable for transfer steps)" ),
            '&nbsp', '&nbsp', $q->textfield( -name => "Plate_Label_def", -size => 15, -value => $plate_label_def, -force => 1 ),
        ]
    );

    #### Comments #####
    $Input->Set_Row(
        [ Show_Tool_Tip( $q->checkbox( -name => 'Input', -value => 'Prep_Comments', -label => 'Comments', -checked => $Comments_check, -force => 1 ), "Prompt user to supply comments as required for this step" ), '&nbsp', '&nbsp', "&nbsp", ] );

    ##### Plates #####  (for reordering or to only use subset of plate set)

    my $P_check = ( $input =~ /FK_Plate__ID/ );
    $Input->Set_Row(
        [   Show_Tool_Tip( $q->checkbox( -name => 'Input', -value => 'FK_Plate__ID', -label => 'Plate', -checked => $P_check, -force => 1 ), "Allow users to scan plates to indicate revised usage order; or to use only a subset of the plate_set" ),
            '&nbsp', '&nbsp'
        ]
    );

    return $Input->Printout(0);
}

#####################
sub display_Validate {
#####################
    my $self               = shift;
    my %args               = filter_input( \@_ );
    my $dbc                = $args{-dbc} || $self->{dbc};
    my $admin              = $args{-admin} || $self->{admin};
    my $protocol           = $args{-protocol};
    my $preset             = $args{-preset};
    my @validation_options = ( 'Primer', 'Enzyme', 'Antibiotic' );

    my $validate = $preset->{Validate}[0];

    my $page .= Show_Tool_Tip(
        $q->popup_menu(
            -name    => 'Validate',
            -values  => [ '', @validation_options ],
            -default => $validate,
            -force   => 1
        ),
        "Perform real-time validation of associated reagents (eg Enzymes, Primers, Antibiotics)"
    );
    return $page;
}

#####################
sub display_QC {
#####################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $admin    = $args{-admin} || $self->{admin};
    my $protocol = $args{-protocol};
    my $preset   = $args{-preset};

    my @plate_attributes = $dbc->Table_find( 'Attribute', 'Attribute_Name', "Where Attribute_Class='Plate'" );
    unshift( @plate_attributes, '' );

    my $qc_attr      = $preset->{QC_Attribute}[0];
    my $qc_condition = $preset->{QC_Condition}[0];

    my $definePlateAttribute_link
        = &Link_To( $dbc->config('homelink'), 'Define New', "&cgi_application=alDente::Attribute_App&rm=Define+Attribute&Class=Plate", '', ['newwin'], -tooltip => "Please reload the page after defining a new attribute" );

    my $page = 'Attribute: ' 
        . Show_Tool_Tip( $q->popup_menu( -name => 'QC_Attribute', -values => \@plate_attributes, -default => $qc_attr, -force => 1 ), "Select a plate attribute used for QA/QC" ) 
        . &hspace(5) 
        . " <B>MUST BE: </B> "
        . Show_Tool_Tip( $q->textfield( -name => 'QC_Condition', -size => 15, -default => $qc_condition, -force => 1 ),
        "ALL Samples in protocol must have Attribute set to this value to continue <BR>(may enter range or single value.  eg 'YES', '>5', '5-400')" )
        . $q->br
        . $definePlateAttribute_link;

    return $page;

}

#####################
sub display_Step_Name {
#####################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $admin    = $args{-admin} || $self->{admin};
    my $protocol = $args{-protocol};
    my $preset   = $args{-preset};

    my $Disabled_Step_Name = "(Select format from popup menu)";
    my $field_name         = "Step_Name";
    my $step_name          = $preset->{Protocol_Step_Name}[0];
    my $default_type       = 'Standard';
    my $plate_format;
    my $sample_check;
    my $new_sample_type;
    my $new_sample;
    my @sample_types = sort $dbc->Table_find( 'Sample_Type', 'Sample_Type', "WHERE 1" );

    if ($step_name =~ /^
            (Transfer|Aliquot|Extract)\s+     ## special cases
             (\#\d+\s)?                           ## optional for multiple steps with similar name (eg Transfer #2 to ..)
            ([\s\w\-]*)\s*                             ## optional new extraction type
            to\s+                                ## ... to .. (type)
            ([\s\w\.\-]+)                        ## mandatory target type
            (.*)              ## special cases for suffixes (optional)
            $/xi
        )
    {
        $default_type = $1;
        $plate_format = chomp_edge_whitespace($4);
        if ($3) {
            $new_sample      = 1;
            $new_sample_type = chomp_edge_whitespace($3);
        }

        if ( $5 =~ /Track New Sample\)/ ) {
            $sample_check = 1;
        }
    }
    elsif ( $step_name =~ /^(Pre-Print)\s+to\s+(.*)/i || $step_name =~ /^(Pool)\s+to\s+(.*)/i || $step_name =~ /^(Setup)\s+to\s+(.*)/i, $step_name =~ /^(Throw Away)\s+to\s+(.*)/i ) {
        $default_type = $1;
        $plate_format = $2;
    }

    my $Step = HTML_Table->new( -colour => 'lightyellow' );
    $Step->Set_Row(
        [   Show_Tool_Tip(
                qq{<input type='radio' name='Step_Type' value='Standard' onClick="document.thisform.$field_name.value=''; document.thisform.$field_name.disabled = 0; document.thisform.Step_Format.value = ''; document.thisform.Step_Format.disabled = 1; document.thisform.New_Sample_Type.value = ''; document.thisform.New_Sample_Type.disabled = 1;" @{[($default_type eq 'Standard') ? 'checked' : 0]}>Standard</input>},
                $Tooltips{Step_Type}{Standard}
                )
                . hspace(5)
                . Show_Tool_Tip(
                qq{<input type='radio' name='Step_Type' value='Transfer'  onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Transfer') ? 'checked' : 0]}>Transfer</input>},
                $Tooltips{Step_Type}{Transfer}
                )
                . hspace(5)
                . Show_Tool_Tip(
                qq{<input type='radio' name='Step_Type' value='Aliquot'   onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Aliquot') ? 'checked' : 0]}>Aliquot</input>},
                $Tooltips{Step_Type}{Aliquot}
                )
                . hspace(5)
                . Show_Tool_Tip(
                qq{<input type='radio' name='Step_Type' value='Extract'   onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Extract') ? 'checked' : 0]}>Extract</input>},
                $Tooltips{Step_Type}{Extract}
                )
                . hspace(5)
                . Show_Tool_Tip(
                qq{<input type='radio' name='Step_Type' value='Pool'      onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Pool') ? 'checked' : 0]}>Pool</input>},
                $Tooltips{Step_Type}{Pool}
                )
                . hspace(5)
                . Show_Tool_Tip(
                qq{<input type='radio' name='Step_Type' value='Pre-Print' onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Pre-Print') ? 'checked' : 0]}>Pre-Print</input>},
                $Tooltips{Step_Type}{'Pre-Print'}
                )
                . hspace(5)
                . Show_Tool_Tip(
                qq{<input type='radio' name='Step_Type' value='Setup' onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Setup') ? 'checked' : 0]}>Setup</input>},
                $Tooltips{Step_Type}{'Setup'}
                )
                . hspace(5)
                . Show_Tool_Tip(
                qq{<input type='radio' name='Step_Type' value='Throw Away' onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Throw Away') ? 'checked' : 0]}>Throw Away</input>},
                $Tooltips{Step_Type}{'Throw Away'}
                )
        ]
    );

    $Step->Set_Row( [ Show_Tool_Tip( $q->textfield( -name => $field_name, -size => 30, -value => $step_name, -force => 1 ), "Brief (Unique) name for this step." ) . "(Keep BRIEF)" ] );

    $Step->Set_Row(
        [         'Extract Type: '
                . Show_Tool_Tip( $q->popup_menu( -name => 'New_Sample_Type', -values => [ '', @sample_types ], -default => $new_sample_type ), "ONLY select if the sample type is CHANGING during this step." )
                . ' <i>(if extracting new type)</i>'

                #                . Show_Tool_Tip( $q->checkbox( -name => 'Create_New_Sample', -value => 'Create_New_Sample', -label => 'Track New Sample', -checked => $sample_check, -force => 1 ) )
        ]
    );
    $Step->Set_Row(
        [   ' Target Type: '
                .

                Show_Tool_Tip( alDente::Tools::search_list( -name => 'FK_Plate_Format__ID', -dbc => $dbc, -default => $plate_format, -element_name => 'Step_Format' ), "Choose target type when tracking sample transfers" )
        ]
    );

    return $Step->Printout(0);

}

#####################
sub display_Step_Buttons {
#####################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $admin       = $args{-admin} || $self->{admin};
    my $allow_edit  = $args{-allow_edit};
    my $protocol    = $args{-protocol};
    my $new_step    = $args{-new_step};
    my $step_number = $args{-step_number};
    my $preset      = $args{-preset};

    my $step_id = $preset->{Protocol_Step_ID}[0];
    my $defined_format_link = &Link_To( $dbc->config('homelink'), 'Defined format', "&Online+Help=Protocol+Formats", '', ['newwin'] );

    my $page
        = $q->h3("** indicates that the field is required")
        . vspace()
        . $q->h3("The 'Step Name' field must be a unique name for any given protocol and may be limited by a $defined_format_link")
        . vspace(5)
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Protocol_App', -force => 1 )
        . $q->hidden( -name => 'Admin',           -value => $admin,                  -force => 1 )
        . $q->hidden( -name => 'Current_Step',    -value => $step_number,            -force => 1 )
        . $q->hidden( -name => 'Step_ID',         -value => $step_id,                -force => 1 )
        . $q->hidden( -name => 'Protocol',        -value => $protocol,               -force => 1 );
    if ($allow_edit) {
        $page .= $q->submit( -name => 'rm', -value => 'Save Step', -class => 'Action' );

        if ($new_step) {
            $page .= $q->reset( -name => 'Clear Fields', -class => 'Std' );
        }
        else {
            $page .= $q->submit( -name => 'rm', -value => 'Delete Step', -class => 'Action' );
        }
    }

    $page
        .= vspace(2)
        . $q->submit( -name => 'rm', -value => 'View Protocol',, -class => 'Std' )
        . $q->checkbox( -name => 'Include Instructions', -label => ' Include Instructions' )
        . $q->br
        . $q->submit( -name => 'rm', -value => 'Back to Home', -class => 'Std', -label => 'Back to Protocol Admin Page' )
        . $q->br;

    return $page;
}

###################
sub view_Protocol {
###################
    my $self     = shift;
    my %args     = filter_input( \@_, 'id' );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $id       = $args{-id};
    my $admin    = $args{-admin} || $self->{admin};
    my $protocol = $args{-protocol};
    my $instr    = $args{-instructions};
    my $page;
    my $protocol_id;

    if ($id) {
        $protocol_id = $id;
        $protocol = $dbc->get_FK_info( 'FK_Lab_Protocol__ID', $id );
    }
    else {
        $protocol_id = $dbc->get_FK_ID( 'FK_Lab_Protocol__ID', $protocol );
    }

    ## only users with 'Admin' Grp_Access privilege on the protocol can edit the protocol
    my $user_groups  = $dbc->get_local('group_list');
    my $protocol_obj = new alDente::Protocol( -dbc => $dbc, -id => $protocol_id );
    my $grp_access   = $protocol_obj->get_grp_access( -grp_ids => $user_groups );
    my $allow_edit   = 0;
    if ( grep /Admin/, values %$grp_access ) {
        $allow_edit = 1;
    }
    my ($info)  = $dbc->Table_find( 'Protocol_Step,Employee', 'Protocol_Step_Changed, Initials',      "where FK_Lab_Protocol__ID=$protocol_id and FK_Employee__ID = Employee_ID ORDER BY Protocol_Step_Changed DESC LIMIT 1" );
    my ($info2) = $dbc->Table_find( 'Lab_Protocol, Employee', 'Lab_Protocol_Modified_Date, Initials', "where Lab_Protocol_ID=$protocol_id and FK_Employee__ID = Employee_ID" );
    my ( $temp1, $temp2 ) = split ',', $info2;

    $info = $info2 if ($temp1);

    my ( $date, $initials ) = split ',', $info;
    my ($number_steps) = $dbc->Table_find( "Protocol_Step", 'count(*)', "where FK_Lab_Protocol__ID=$protocol_id" );

    ##
    ## Use the modified date on Lab_Protocol instead of Protocol_Step if it has been initiated.
    ## If not stick to old format until this changes.
    ## <CONSTRUCTION> The above code for getting $date should be changed after date modified in lab_protocol gets back filled

    my @fields = ( "Protocol_Step_Number", "Protocol_Step_ID", "Scanner", "Protocol_Step_Name", "Input", "Protocol_Step_Defaults", "Input_Format", "Protocol_Step_Message", "QC_Condition", "Validate" );
    if ($instr) { push @fields, "Protocol_Step_Instructions" }
    my $condition .= " WHERE FK_Lab_Protocol__ID = $protocol_id order by Protocol_Step_Number";
    my %data = $dbc->Table_retrieve( 'Protocol_Step', \@fields, $condition );

    my $table = HTML_Table->new( -width => 400 );

    # $table->Toggle_Colour('off');
    # $table->Set_Title( 'Define a new library', fsize => '-1' );

    my @title_fields = ( $q->h2('Step Number'), $q->h2('Scanner'), $q->h2('Step Name'), $q->h2('Input') );
    if ($instr) {
        push @title_fields, $q->h2('Instructions');
    }
    push @title_fields, $q->h2('Delete');

    $table->Set_Headers( \@title_fields );
    my $size = @title_fields;
    $table->Set_Column_Colour( $size, 'pink' );
    $table->Set_Column_Colour( 1, 'lightblue' );
    $table->Set_Header_Class("Large");

    my $index;
    while ( defined $data{Protocol_Step_ID}[$index] ) {
        my $step         = $data{Protocol_Step_Number}[$index];
        my $protocol_id  = $data{Protocol_Step_ID}[$index];
        my $scanner      = $data{Scanner}[$index];
        my $step_name    = $data{Protocol_Step_Name}[$index];
        my $input        = $data{Input}[$index];
        my $defaults     = $data{Protocol_Step_Defaults}[$index];
        my $formats      = $data{Input_Format}[$index];
        my $message      = $data{Protocol_Step_Message}[$index];
        my $QC           = $data{QC_Condition}[$index];
        my $validate     = $data{Validate}[$index];
        my $instructions = $data{Protocol_Step_Instructions}[$index];

        my $Number = $q->radio_group( -name => 'step_number', -values => [$step], default => '' );
        my $Scanner;
        if ($scanner) {
            my $colour = 'blue';
            $Scanner = "<IMG src='" . $dbc->config('png_url_dir') . "/checkmark.png'>";
        }
        my $Name = $q->submit( -name => 'Step', -label => $step_name, -force => 1 ) . vspace . $message;
        my $Input;
        if ($input) {
            my @formatted_defaults = split ':', $defaults;
            my @formatted_input    = split ':', $input;
            my @input_formats      = split ':', $formats;
            my $index              = 0;

            foreach my $input (@formatted_input) {
                my $Iformat = $input_formats[$index];
                if ( $Iformat =~ /NULL/ ) { $Iformat = ''; }
                $Input .= "<LI>$input ($formatted_defaults[$index]) ($Iformat)";
                $index++;
            }
            if ( $validate || $QC ) {
                my $qc;
                $qc = "Attribute check;" if $QC;
                $qc .= "Validate $validate;" if $validate;
                $Input .= "<LI>" . Show_Tool_Tip( "<B><Font color=red>** QC **", "$qc" );
            }

            $Input .= "</UL>";
            $Input =~ s/FK_Equipment__ID/Equip/g;
            $Input =~ s/Prep_Comments/Comments /g;
            $Input =~ s/Prep_/Prep /g;
            $Input =~ s/Plate_/Plate /g;
            $Input =~ s/FK_Solution__ID/Solution/g;
            $Input =~ s/FK_Plate__ID/Plate/g;
            $Input =~ s/Solution_Quantity/Sol Qty/g;
            $Input =~ s/FK_Rack__ID/Rack/g;
        }

        my $Delete = $q->checkbox( -name => 'Delete_' . $step, -label => "", -force => 1 );

        my @row = ( $Number, $Scanner, $Name, $Input );
        if ($instr) {
            push @row, $instructions;
        }
        push @row, $Delete;

        $table->Set_Row( \@row );

        $index++;
    }

    $page .= $q->h2("Protocol: $protocol");
    $page .= "This protocol has $number_steps Steps." . vspace() . "Last edited by $initials on $date." . vspace();
    $page .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'protocol' );

    $page
        .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Protocol_App', -force => 1 )
        . $q->hidden( -name  => 'Admin',           -value => $admin,                  -force => 1 )
        . $q->hidden( -name  => 'Allow_Edit',      -value => $allow_edit,             -force => 1 )
        . $q->hidden( -name  => 'Protocol',        -value => $protocol,               -force => 1 )
        . $q->hidden( -name  => 'rm',              -value => 'View Step',             -force => 1 )
        . $table->Printout(0)
        . vspace();
    $page .= set_validator( -name => "step_number", -mandatory => 1, -prompt => "Please choose a step" );
    if ( $admin && $allow_edit ) {
        $page
            .= $q->submit( -name => 'Step Details', -value => 'View / Edit Step Details', -class => 'Std', -onClick => "return validateForm(this.form)" )
            . &hspace(10)
            . Show_Tool_Tip( $q->submit( -name => 'Add Step', -class => 'Std' ), "(Will occur before selected step - or at the end if none selected) " )
            . &hspace(10)
            . $q->submit( -name => 'Delete Step(s)', -class => 'Action', -onClick => "return validateForm(this.form)" );
        $page .= $q->hr . $q->end_form();

        $page .= $self->get_buttons( -dbc => $dbc, -protocol_id => $protocol_id, -protocol => $protocol, -admin => $admin );
    }
    else {
        $page .= $q->submit( -name => 'Step Details', -value => 'View Step Details', -class => 'Std', -onClick => "return validateForm(this.form)" ) . $q->end_form();
        $page .= $q->hr;

        ############## To maintain the consistency, TechD personnel need to be administrators in order to copy protocols. So the code block below is commented out ##########
        ## if user is TechD of the current department, allow copy the protocol
        #my $current_department = $dbc->get_local('current_department');
        #my $group_types        = $dbc->get_local('group_type');
        #if ( grep {/TechD/xms} @{ $group_types->{$current_department} } ) {
        #    $page
        #        .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Copy_protocol' )
        #        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Protocol_App', -force => 1 )
        #        . $q->hidden( -name => 'Protocol', -value => $protocol, -force => 1 )
        #        . vspace()
        #        . $q->submit( -name => 'rm', -value => 'Save As New Protocol', -class => 'Action' )
        #        . $q->end_form();
        #}
        #$page .= $q->hr;
    }

    ## use standardized interface for managing join tables ##
    my $filter = "Access IN ('Lab') AND Grp_Status = 'Active'";
    my $Object = new alDente::Object( -dbc => $dbc );
    $page .= $Object->View->join_records(
        -dbc        => $dbc,
        -defined    => "FK_Lab_Protocol__ID",
        -id         => $protocol_id,
        -join       => 'FK_Grp__ID',
        -join_table => "GrpLab_Protocol",
        -filter     => $filter,
        -title      => 'Group Visibility for this Protocol',
        -extra      => 'Grp_Access',
        -editable   => $admin & $allow_edit,
        -edit       => $allow_edit,
    );

    return $page;

}

###################
sub get_buttons {
###################
    my $self        = shift;
    my %args        = filter_input( \@_, 'id' );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $id          = $args{-id};
    my $admin       = $args{-admin} || $self->{admin};
    my $protocol_id = $args{-protocol_id};
    my $protocol    = $args{-protocol};

    my $page;
    my ($state) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_Status', "where Lab_Protocol_ID=$protocol_id" );
    my @status_options = alDente::Protocol::get_protocol_status_options( -dbc => $dbc );
    $page .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'protocol' );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Protocol_App', -force => 1 ) . $q->hidden( -name => 'Admin', -value => $admin, -force => 1 ) . $q->hidden( -name => 'Protocol', -value => $protocol, -force => 1 );
    $page
        .= $q->submit( -name => 'rm', -value => 'Set Groups', -class => 'Std' )
        . &hspace(10)
        . $q->submit( -name => 'rm', -value => 'Save As New Protocol', -class => 'Action' )
        . vspace(10)
        . $q->textfield( -name => 'Protocol Name', -size => 20 )
        . hspace(10)
        . $q->submit( -name => 'rm', -value => 'Edit Protocol Name', -class => 'Action' )
        . vspace(10)
        . $q->scrolling_list( -name => 'State', -values => \@status_options, -default => $state )
        . &hspace(5)
        . $q->submit( -name => 'rm', -value => 'Change Status', -class => 'Action' )
        . $q->hr;

        #     $page .= $q ->submit( -name => 'Restrict Access', -class => 'Action' );
    $page .= $q->submit( -name => 'rm', -value => 'View Protocol', -class => 'Std' ) . $q->checkbox( -name => 'Include Instructions', -label => ' Include Instructions' );
    $page .= &vspace(2) . $q->submit( -name => 'rm', -value => 'Back to Home', -class => 'Std', -label => 'Back to Protocol Admin Page' ) . $q->end_form();

    return $page;
}

##############################
# Get groups of the specified access permission
##############################
sub _get_groups_info {
##############################
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $access = $args{-access};

    my @values;
    my @defaults;
    my %labels;
    my $lims_admin;

    my $local = $dbc->get_local();
    my @grps;
    foreach my $dept ( keys %{ $local->{Access} } ) {
        if ( grep /$access/, @{ $local->{Access}{$dept} } ) {
            push @grps, @{ alDente::Grp::get_dept_groups( -dbc => $dbc, -dept_name => $dept ) };
        }
    }
    my ($valid_grps) = RGmath::intersection( \@grps, $local->{group_list} );
    my $valid_grps_list = join ',', @$valid_grps;
    my @valid_group_names = $dbc->get_FK_info_list( 'FK_Grp__ID', -condition => "WHERE GRP_ID in ($valid_grps_list)" );

    my $target_dept_id = $dbc->get_FK_ID( -field => 'FK_Department__ID', -value => $dbc->config('Target_Department') );
    my @defaults = alDente::Grp::get_Grps( -dbc => $dbc, -type => 'Lab', -access => $access, -department => $target_dept_id );

    return ( \@valid_group_names, \@defaults );
}

1;
