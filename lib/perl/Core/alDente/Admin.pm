################################################################################
# Admin.pm
#
# This modules provides various functions for Administrative Purposes
#
################################################################################
################################################################################
# $Id: Admin.pm,v 1.60 2004/12/08 20:01:41 jsantos Exp $
################################################################################
# CVS Revision: $Revision: 1.60 $
#     CVS Date: $Date: 2004/12/08 20:01:41 $
###############################################################################
package alDente::Admin;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Admin.pm - This modules provides various functions for Administrative Purposes

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This modules provides various functions for Administrative Purposes<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    Admin_page
    ReAnalyzeRuns
);
@EXPORT_OK = qw(
);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use File::stat;
use URI::Escape;

##############################
# custom_modules_ref         #
##############################
use alDente::SDB_Defaults;
use alDente::Form;
use alDente::Library;
use alDente::Security;
use alDente::RNA_DNA_Collection;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::RGmath;
use SDB::HTML;
use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
use vars qw($URL_address $user $dbase $session_id $banner $project $mirror_dir $testing $SDB_submit_image);
use vars qw(%Settings %Configs $Security $Current_Department $Connection);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my %Admin;
$Admin{Admin_Op_Table}     = [ 'Cap_Seq Admin', 'Microarray', 'Mapping Admin', 'Lib_Construction Admin' ];
$Admin{Mirroring}          = ['Cap_Seq'];
$Admin{Submissions}        = [ 'Cap_Seq Admin', 'Microarray', 'Mapping Admin', 'Lib_Construction Admin' ];
$Admin{Seq_Analysis}       = ['Cap_Seq'];
$Admin{Sequencer_Defaults} = ['Cap_Seq'];
$Admin{Lab_Protocols}      = [ 'Lab', 'Cap_Seq', 'Mapping', 'Lib_Construction', 'Microarray', 'Cancer Genetics', 'Biospecimen_Core', 'Prostate_Lab', 'UHTS', 'Instrumentation' ];
$Admin{Std_Chemistries}    = [ 'Cap_Seq', 'Mapping', 'Lib_Construction', 'Microarray', 'Biospecimen_Core', 'Instrumentation' ];
$Admin{Sample_Sheets}      = ['Cap_Seq'];
$Admin{Protocol_Tracking}  = [ 'Lab', 'Cap_Seq', 'Lib_Construction', 'Microarray', 'UHTS', 'Instrumentation' ];
$Admin{Draft_Submissions}  = [ 'Lib_Construction', 'Microarray' ];
$Admin{GCOS_Config}        = ['Microarray'];
$Admin{Branch}             = [ 'Cap_Seq', 'Mapping', 'Lib_Construction', 'Microarray' ];

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

######################
sub Admin_page {
######################
    #
    # Home page for SDB Administration
    #
    my %args = filter_input( \@_, -args => 'dbc' );

    my $dbc        = $args{-dbc};
    my $reduced    = $args{-reduced} || 0;                         # If 'reduced' is specified then only display the portion viewed in departmental page.
    my $newwin     = $args{-newwin} || 0;                          # Whether to display the results in new window.
    my $department = $args{-department} || $Current_Department;    # Department that we are interested in
    my $form_name;
    my $groups = $dbc->get_local("groups");

    # Set security checks.
    my %checks;
    my $output;
    my $admin_op;

    my @depts = $dbc->Table_find( 'Grp,Department', 'Department_Name', "WHERE FK_Department__ID=Department_ID AND Access='Admin' AND Department_Status='Active'" );
    foreach my $dept (@depts) {
        $checks{ADMIN_PAGE}{$dept} = 'Admin';
    }
    $checks{SEQ_ADMIN_OP} = { 'Cap_Seq' => 'Admin' };
    $dbc->Security->security_checks( \%checks );

    #unless ( $dbc->Security->check('ADMIN_PAGE') ) { return "$user has no administrative privileges."; }
    unless ( $dbc->Security->check_permission( $department, 'Admin' ) ) { return "$user has no administrative privileges."; }

    if ($reduced) {
        $form_name ||= 'Department';
        $admin_op = _init_table('Mirroring and Submissions');

    }
    else {
        $output .= &Views::Heading( "$department Administrative Options" . hspace(5) . "<span class=small>" . checkbox( -name => 'NewWin', -label => 'Display results in new window', -checked => 0 ) . "</span>" );
        $admin_op = _init_table('Admin Operations');
    }
    ##################################################################
    ###Admin Operations Section
    ##################################################################

    if ( grep /\b$department\b/, @{ $Admin{Mirroring} } ) {
        my $checkmirror_home = display_Mirroring( -dbc => $dbc );
    }

    my ($valid_sub_list) = &RGmath::intersection( $groups, $Admin{Submissions} );

    if ($reduced) {
        return alDente::Form::start_alDente_form( -dbc => $dbc, -name => $form_name ) . $admin_op->Printout(0) . "</form>";
    }

    ###Re-Analyze Runs###
    my $QA_link = &Link_To( $dbc->config('homelink'), 'Report', "&QA+Report=1", $Settings{LINK_COLOUR} );
    if ( grep /\b$department\b/, @{ $Admin{Seq_Analysis} } ) {
        my $checkboxes
            = checkbox( -name => 'Reverse Orient96', -label => '' )
            . 'Reverse Orient 96 well quadrant(s)'
            . hspace(5)
            . checkbox( -name => 'Reverse Orient384', -label => '' )
            . 'Reverse Orient entire plate<br>'
            . checkbox( -name => 'List Runs', -label => '' )
            . 'List Runs only<br>'
            . checkbox( -name => 'Force Analysis', -label => '' )
            . 'Force Analysis (if quadrant available)'
            . hspace(5)
            . checkbox( -name => 'Full Force Analysis', -label => '' )
            . 'Force Analysis (if well available)';

        $admin_op->Set_Row(
            [         hidden( -name => 'update_sequence', -value => 1 )
                    . RGTools::Web_Form::Submit_Button( -dbc => $dbc, name => 'Re-Analyze Runs', label => 'Re-Analyze Runs', style => "background-color:red" )
                    . hspace(1)
                    . Show_Tool_Tip( textfield( -name => 'RunIDs', -size => 20 ), "Specify the run IDs" )
                    . br
                    . $checkboxes
            ]
        );
        $admin_op->Set_Row( [ "QA: " . $QA_link ] );
    }

    ##################################################################
    ###Define/Configure Section
    ##################################################################
    my $define_config = _init_table('Define/Configure');

    if ( $dbc->package_active('Submissions') ) {
        if ( grep /\b$department\b/, @{ $Admin{Draft_Submissions} } ) {
            $define_config->Set_Row( [ &Link_To( $dbc->config('homelink'), "Check draft submissions", "&Check+Submissions=1&Submission_Status=Draft", $Settings{LINK_COLOUR} ) ] );
        }
    }

    my $gcos_group = $Admin{GCOS_Config}->[0];

    if ( grep( /\b$department\b/, @{ $Admin{GCOS_Config} } ) ) {
        my @choices = ('-');
        my %labels = ( '-' => '--Select--' );

        my @names = $dbc->Table_find( "GCOS_Config", "Template_Name,GCOS_Config_ID" );
        foreach my $row (@names) {
            my ( $name, $id ) = split ',', $row;
            $labels{$id} = $name;
            push( @choices, $id );
        }
        @choices = sort(@choices);

        $define_config->Set_Row(
            [   'GCOS Template Config:',
                RGTools::Web_Form::Popup_Menu( name => 'Configure ID', values => \@choices, labels => \%labels, default => '-', force => 1, width => 100 )
                    . RGTools::Web_Form::Submit_Image( -src => $SDB_submit_image, -name => 'Configure GCOS Config', -value => 1 ),
                ' OR ' . &Link_To( $dbc->config('homelink'), "Search", "&Search+for=1&Table=GCOS_Config", $Settings{LINK_COLOUR} ) . ' / ' . &Link_To( $dbc->config('homelink'), "Create", "&New+Entry=New+GCOS_Config", $Settings{LINK_COLOUR} )
            ]
        );
    }

    ###Lab Protocols Section###
    if ( grep /\b$department\b/, @{ $Admin{Lab_Protocols} } ) {
        show_protocol_chemistry( -dbc => $dbc, -type => 'Lab_Protocol', -html_table => $define_config, -department => $department );
    }
    ###Standard Chemistries Section###
    if ( grep /\b$department\b/, @{ $Admin{Std_Chemistries} } ) {
        show_protocol_chemistry( -dbc => $dbc, -type => 'Standard_Solution', -html_table => $define_config, -department => $department );
    }

    $define_config->Set_Row( [ end_form() . alDente::Form::start_alDente_form( $dbc, '' ) ] );

    ###Sequencer Defaults###
    if ( grep /\b$department\b/, @{ $Admin{Sequencer_Defaults} } ) {
        my @choices = ('-');
        my %labels = ( '-' => '--Select--' );

        push( @choices, 'Machine_Default' );
        push( @choices, 'Dye_Chemistry' );

        $labels{Machine_Default} = 'Sequencer Defaults';
        $labels{Dye_Chemistry}   = 'Chemistry Settings';

        @choices = sort(@choices);
        $define_config->Set_Row(
            [   'Sequencer Defaults:',
                RGTools::Web_Form::Popup_Menu( id => 'Sequencer_Defaults', values => \@choices, labels => \%labels, default => '-', force => 1, width => 100 )
                    . RGTools::Web_Form::Submit_Image( -src => $SDB_submit_image, -onClick => "this.form.appendChild(getInputNode({'type':'hidden','name':'Edit Table','value':document.getElementById('Sequencer_Defaults').value}))" )
            ]
        );

    }

    ###Sample Sheets Configuration Section###
    if ( grep /\b$department\b/, @{ $Admin{Sample_Sheets} } ) {
        my @choices = $dbc->Table_find( 'Sequencer_Type', 'Sequencer_Type_Name', 'ORDER BY Sequencer_Type_Name', 'Distinct' );
        unshift( @choices, '-' );
        my %labels = ( '-' => '--Select--' );

        @choices = sort(@choices);
        $define_config->Set_Row(
            [   "Configure Sample Sheet:",
                RGTools::Web_Form::Popup_Menu( name => 'Sequencer_Type', values => \@choices, labels => \%labels, default => "", force => 1, width => 100 ) . RGTools::Web_Form::Submit_Image( -src => $SDB_submit_image, -name => 'Configure SS Event' )
            ]
        );
    }

    ###Protocol Tracking Details Section###
    if ( grep /\b$department\b/, @{ $Admin{Protocol_Tracking} } ) {
        my @choices = ('-');
        my %labels = ( '-' => '--Select--' );

        push( @choices, 'Protocol_Tracking' );

        $labels{Protocol_Tracking} = 'Protocol Tracking Details';

        @choices = sort(@choices);
        $define_config->Set_Row(
            [   'Protocol Tracking:',
                RGTools::Web_Form::Popup_Menu( id => 'Protocol_Tracking', values => \@choices, labels => \%labels, default => '-', force => 1, width => 100 )
                    . RGTools::Web_Form::Submit_Image( -src => $SDB_submit_image, -onClick => "this.form.appendChild(getInputNode({'type':'hidden','name':'Edit Table','value':document.getElementById('Protocol_Tracking').value}))" )
            ]
        );
    }

    ### Adding Gel Trays ###
    if ( $department =~ /mapping/i && ( grep( /\b$department\b/, @{ $Admin{Gel_Tracking} } ) || 1 ) ) {
        $define_config->Set_Row(
            [   'Gel Trays:',
                textfield( -name => 'Count', -default => 1, -force => 1, -size => 5, -id => 'Count_ID' ) . set_validator( -name => 'Count', -mandatory => 1, -format => '\d+', -prompt => 'New Gel Tray Count' ) . RGTools::Web_Form::Submit_Image(
                    -src     => $SDB_submit_image,
                    -onClick => "
                if (validateForm(this.form)) {
                    goTo('$dbc->config('homelink')','&GelRun_Request=1&Create+New+Gel+Tray=1&Count=' + document.getElementById('Count_ID').value);
                } return false;"
                )
            ]
        );
    }

    ### Adding Branch Codes for Primers/Enzymes
    if ( $dbc->package_active('Genomic') && grep( /\b$department\b/, @{ $Admin{Branch} } ) ) {
        $define_config->Set_Row( [ 'Branch for Primer:', &Link_To( $dbc->config('homelink'), "Create", "&New+Entry=New+Branch&Object_Class=Primer", $Settings{LINK_COLOUR} ) ] );
        $define_config->Set_Row( [ 'Branch for Enzyme:', &Link_To( $dbc->config('homelink'), "Create", "&New+Entry=New+Branch&Object_Class=Enzyme", $Settings{LINK_COLOUR} ) ] );
    }

    #################################################################
    my ($valid_op_list) = &RGmath::intersection( $groups, $Admin{Admin_Op_Table} );

    ###Check Submissions###
    if ( int( @{$valid_op_list} ) > 0 ) {
        $output .= &Views::Table_Print(
            content => [ [ alDente::Form::start_alDente_form( $dbc, 'AdminOpts' ) . $admin_op->Printout(0) . end_form(), alDente::Form::start_alDente_form( $dbc, 'AdminOpts' ) . $define_config->Printout(0) . end_form() ] ],
            padding => 0,
            spacing => 4,
            print   => 0
        );
    }
    else {
        $output .= &Views::Table_Print(
            content => [ [ alDente::Form::start_alDente_form( $dbc, 'AdminOpts' ) . $define_config->Printout(0) . end_form() ] ],
            padding => 0,
            spacing => 4,
            print   => 0
        );

        #$output .= &Views::Table_Print(content=>[[$define_config->Printout(0)]],padding=>0,spacing=>4,print=>0);
    }
    #################################################################

    return $output;
}

##################################
sub display_Mirroring {
##########################
    ## <CONSTRUCTOIN> It might be a good idea to make it a tool box and put it in the Department.pm -reza
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my @choices = ('-');
    my %labels = ( '-' => '--Select--' );

    my %Sequencers = $dbc->Table_retrieve(
        'Equipment,Machine_Default,Stock,Stock_Catalog,Equipment_Category',
        [ 'Equipment_Name', 'Host', 'Sharename', 'Local_Data_Dir' ],
        "where FK_Equipment__ID=Equipment_ID AND FK_Stock__ID = Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Category = 'Sequencer' AND Equipment_Status like 'In Use'"
    );
    my $lasttype;
    my $machines = int @{ $Sequencers{Equipment_Name} } - 1;
    foreach my $index ( 0 .. $machines ) {
        my $name = $Sequencers{Equipment_Name}[$index];

        #	    my $host = $Sequencers{Host}[$index];
        my $data_dir  = $Sequencers{Local_Data_Dir}[$index];
        my $sharename = $Sequencers{Sharename}[$index];
        $data_dir =~ /(.*?)\//;
        my $type = $1;

        $name =~ /(.*\D)(\d+)$/;
        my $prefix  = $1;
        my $machine = $2;
        my $dir     = $sharename;

        #unless (!$index || ($lasttype eq $type)) {print '</TD><TD>'; }
        $lasttype = $type;

        $index++;

        #unless ($prefix && $dir && $machine && $type) { print "?:$prefix,$dir,$machine,$type ?<BR>"; }

        my $host = $prefix . $machine;
        push( @choices, "$type-$machine" );

        #print &Link_To("$URL_address/checkmirror"," $prefix$machine ","?type=$type&id=$machine&dir=data1&request=1",$Settings{LINK_COLOUR},['newwin']);
        my $status;
        my $info;
        if ( -e "$mirror_dir/request.$type.$machine.$dir" ) {
            my $stats = stat("$mirror_dir/request.$type.$machine.$dir");
            my $stamp = &date_time( $stats->mtime );
            $labels{"$type-$machine"} .= "$prefix$machine <requested $stamp> ";
        }
        elsif ( -e "$mirror_dir/mirrored.$host" ) {
            $info   = &try_system_command("cat $mirror_dir/mirrored.$host");
            $status = 'mirrored';
        }
        elsif ( -e "$mirror_dir/analyzed.$host" ) {
            $info   = &try_system_command("cat $mirror_dir/analyzed.$host");
            $status = 'analyzed';
        }
        else {
            $labels{"$type-$machine"} .= "$prefix$machine <no mirrored info> ";
        }

        if ($status) {
            if ( $info =~ /no such/i ) {
                $labels{"$type-$machine"} .= "$prefix$machine <no $status info> ";
            }
            elsif ( $info =~ /Copied\s+(\d+)\s+/ ) {
                $labels{"$type-$machine"} .= "$prefix$machine <$1 files copied> ";
            }
            if ( $info =~ /status\.(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/ ) {
                $labels{"$type-$machine"} .= "<" . substr( &convert_date( "$1-$2-$3", 'Simple' ), 0, 6 ) . " ($4:$5)" . "> ";
            }
        }
    }

    @choices = sort(@choices);
    my $checkmirror_home = "$URL_address/checkmirror";
    return $checkmirror_home;
}

#####################
sub ReAnalyzeRuns {
#####################
    my $dbc     = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $runs    = shift;
    my $options = shift;

    my $command = "update_sequence.pl -A All";

    if ( $runs =~ /[1-9]/ ) { $command .= " -S $runs"; }
    else                    { Message("No runs specified"); return; }
    ### parse options...

    if ( param('Reverse Orient384') ) {
        $options .= " -R";
    }
    elsif ( param('Reverse Orient96') ) {
        $options .= " -r";
    }

    if ( param('Force Analysis') ) {
        $options .= " -f";
    }
    if ( param('Full Force Analysis') ) {
        $options .= " -F";
    }

    $options ||= " -f";    ## default to soft force ##

    ###### generate analysis request file #######
    if ( param('List Runs') ) {
        $dbc->Table_retrieve_display(
            'Run,SequenceRun,SequenceAnalysis',
            [ 'Run_ID', 'Run_Directory', 'Run_DateTime', 'SequenceAnalysis_DateTime as Analyzed', 'Run_Status,Run_Test_Status' ],
            "where Run_ID in ($runs) AND FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRun_ID"
        );
    }
    else {
        open my $REANALYZE, ">>$mirror_dir/analysis.request" || print "ERROR opening analysis.request";
        print {$REANALYZE} "$command : $options\n";
        foreach my $run ( split ',', $runs ) {
            print {$REANALYZE} "$run\n";
        }
        close($REANALYZE);
        print "wrote request for analysis ($options) to $mirror_dir/analysis.request<BR>";

        open my $ANALYZE_LOG, ">>$mirror_dir/analysis.request.log" || print "Error logging request";
        print {$ANALYZE_LOG} &date_time . '(' . $dbc->get_local('user_name') . ")\n****************************\n$command : $options\n";
        close $ANALYZE_LOG;
    }

    return 1;
}

#################################
#### private_methods            #
#################################
#################################
#### private_functions          #
#################################
###

##########################
sub _init_table {
##########################
    my $title = shift;
    my $right = shift;
    my $class = shift || 'small';

    my $table = HTML_Table->new();

    $table->Set_Class('small');
    $table->Set_Width('100%');
    $table->Toggle_Colour('off');
    $table->Set_Line_Colour('#ddddda');

    $title = "<Table border=0 cellspacing=0 cellpadding=0 width=100%><TR><TD><font size='-1'><b>$title</b></font></TD><TD align=right class=$class><B>$right</B></TD></TR></Table>";

    $table->Set_Title( $title, bgcolour => '#ccccff', fclass => 'small', fstyle => 'bold' );

    return $table;
}

###################################
# Send out status change notification
#
# Input:
#		-dbc	:	database connection
#		-type	:	'Protocol' or 'Standard Solution'
#		-name	:	name of the protocol or chemistry
# Return:
#		1 if success; 0 if failed
##################################
sub send_status_change_notification {
##########################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,type,name' );
    my $dbc  = $args{-dbc};
    my $type = $args{-type};
    my $name = $args{-name};

    my $obj;
    if ( $type =~ /Protocol/i ) {
        $obj = new alDente::Protocol( -dbc => $dbc );
    }
    elsif ( $type =~ /Standard Solution/i ) {
        $obj = new alDente::Chemistry( -dbc => $dbc );
    }
    return if ( !$obj );

    ## check if it belongs to TechD grp
    my $grp_access = $obj->get_grp_access( -dbc => $dbc, -name => $name );
    foreach my $grp ( keys %$grp_access ) {
        my ($info) = $dbc->Table_find( 'Grp', 'Grp_Name,Grp_Type,FK_Department__ID', "Where Grp_ID = $grp" );
        my ( $grp_name, $grp_type, $department ) = split ',', $info;
        if ( ( $grp_type eq 'TechD' ) && ( $grp_access->{$grp} eq 'Admin' ) ) {    # TechD protocol/chemistry becomes active
            require alDente::Subscription;                                         ## Subscription module.
            my $msg = "The following $type has been approved by $grp_name. Please go to Admin page to accept the $type.\n\n";
            $msg .= "<P><B>" . $name . "</B><P>";
            my $subscription_event_name = "Approved TechD $type";
            my $from_name               = 'Genome Sciences Centre LIMS';
            my $from_email              = 'aldente';

            # send notification
            my $ok = alDente::Subscription::send_notification(
                -dbc          => $dbc,
                -name         => $subscription_event_name,
                -from         => "$from_name <$from_email>",
                -subject      => "$subscription_event_name - $name",
                -body         => $msg,
                -content_type => 'html',
                -group        => [$grp],
                -testing      => 1,
            );
            if ($ok) {
                Message("Approved TechD $type notification successfully sent.");
            }
            else {
                Message("Failed to send Approved TechD $type notification to the admins.");
            }
        }
    }
}

##########################
sub show_protocol_chemistry {
##########################
    my %args       = filter_input( \@_ );
    my $type       = $args{-type};
    my $dbc        = $args{-dbc};
    my $html_table = $args{-html_table};
    my $department = $args{-department};

    my $model_module, my $app_module, my $new_link, my $method_name, my $display_name;
    if ( $type eq 'Lab_Protocol' ) {
        $model_module = 'alDente::Protocol';
        $new_link     = &Link_To( $dbc->config('homelink'), "Create", "&Admin=1&cgi_application=alDente::Protocol_App&rm=Create+New+Protocol", $Settings{LINK_COLOUR} );
        $method_name  = "get_protocols";
        $display_name = 'Protocol';
    }
    elsif ( $type eq 'Standard_Solution' ) {
        $model_module = 'alDente::Chemistry';
        $new_link     = &Link_To( $dbc->config('homelink'), "Create", "&New+Entry=New+Standard_Solution", $Settings{LINK_COLOUR} );
        $method_name  = "get_standard_chemistries";
        $display_name = 'Chemistry';
    }
    else {
        $dbc->message("ERROR: Invalid type $type");
        return;
    }
    $app_module = $model_module . '_App';

    my $search_link = &Link_To( $dbc->config('homelink'), "Search", "&cgi_application=SDB::DB_Object_App&rm=Search Records&Table=$type,Grp$type&Condition=FK_$type" . "__ID=$type" . "_ID", $Settings{LINK_COLOUR} );
    $html_table->Set_Row( [ $display_name, "$search_link / $new_link" ] );

    ## display approved techD protocols/chemistries
    my $obj = $model_module->new( -dbc => $dbc );
    my $approved_techD = $obj->$method_name( -dbc => $dbc, -department => $department, -grp_type => 'TechD', -grp_access => 'Admin', -status => 'Active' );
    if ( int(@$approved_techD) ) {
        my ( $choices, $labels ) = $obj->convert_to_labeled_list( -names => $approved_techD );
        my $row = [
            '',
            'Approved TechD',
            alDente::Form::start_alDente_form( -dbc => $dbc, -name => "AdminOpts_Approved_techD_$type" )
                . hidden( -name => 'Admin', -value => '1', -force => 1 )
                . RGTools::Web_Form::Popup_Menu( name => "$type Choice", values => $choices, labels => $labels, default => '-', force => 1 )
                . set_validator( -name => "$type Choice", -mandatory => 1, -force => 1 )
                . space(10)
                . submit( -name => 'rm', -value => "View $display_name", -class => 'std', -onClick => "return validateForm(this.form);" )
                . space(5)
                . submit( -name => 'rm', -value => "Accept TechD $display_name", -class => 'std', -onClick => "return validateForm(this.form);" )
                . hidden( -name => 'cgi_application', -value => $app_module, -force => 1 )
                . end_form(),
        ];
        $html_table->Set_Row($row);
    }
    my $rows = display_protocol_chemistry_dropdown( -dbc => $dbc, -type => $type, -scope => 'Production' );

    foreach my $row (@$rows) {
        $html_table->Set_Row($row);
    }
    if ( !@$rows ) { $html_table->Set_sub_header( "<B>No Production $display_name available - Note: make sure you are in the correct Department</B>", 'lightredbw' ) }
    $html_table->Set_sub_header('<HR>');

    return;
}

##########################
sub display_protocol_chemistry_dropdown {
##########################
    my %args   = filter_input( \@_ );
    my $type   = $args{-type};
    my $scope  = $args{-scope};
    my $status = $args{'-status'};
    my $dbc    = $args{-dbc};

    my $model_module, my $app_module, my $method_name, my $display_name;
    if ( $type eq 'Lab_Protocol' ) {
        $model_module = 'alDente::Protocol';
        $method_name  = "get_protocol_status_options";
        $display_name = 'Protocol';
    }
    elsif ( $type eq 'Standard_Solution' ) {
        $model_module = 'alDente::Chemistry';
        $method_name  = "get_chemistry_status_options";
        $display_name = 'Chemistry';
    }
    else {
        $dbc->message("ERROR: Invalid type $type");
        return;
    }
    $app_module = $model_module . '_App';

    my $obj = $model_module->new( -dbc => $dbc );

    my @statuses;
    if ($status) { @statuses = Cast_List( -list => $status, -to => 'array' ) }
    else         { @statuses = $obj->$method_name( -dbc => $dbc ) }

    my $condition;
    if   ( $scope =~ /TechD/i ) { $condition = " Grp.Grp_Type = 'TechD'  and Grp_Access = 'Admin' " }
    else                        { $condition = " Grp.Grp_Type in ('Lab', 'Production', 'Lab Admin') " }

    my %items;
    my $field = $type . '_Status';
    foreach my $status (@statuses) {
        my @items = @{ $dbc->Security->get_accessible_items( -table => $type, -extra_condition => $condition . " and $field = '$status'" ) };
        $items{$status} = \@items;
    }

    my @rows;
    foreach my $status ( sort keys %items ) {
        if ( int( @{ $items{$status} } ) == 0 ) {next}
        my ( $choices, $labels ) = $obj->convert_to_labeled_list( -names => $items{$status} );
        my $row = [
            '',
            "$status:",
            alDente::Form::start_alDente_form( -dbc => $dbc, -name => $type . '_' . $status )
                . hidden( -name => "cgi_application", -value => $app_module, -force => 1 )
                . hidden( -name => 'Admin', -value => '1', -force => 1 )
                . RGTools::Web_Form::Popup_Menu( name => "$type Choice", values => $choices, labels => $labels, default => '-', force => 1 )
                . set_validator( -name => "$type Choice", -mandatory => 1, -force => 1 )
                . space(10)
                . submit( -name => 'rm', -value => "View $display_name", -class => "Std", -onClick => "return validateForm(this.form);", -force => 1 )
                . end_form(),
        ];
        push @rows, $row;
    }

    return \@rows;
}

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

$Id: Admin.pm,v 1.60 2004/12/08 20:01:41 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
