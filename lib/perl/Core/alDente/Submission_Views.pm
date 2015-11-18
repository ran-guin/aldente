##############################################################################################
# alDente::Shipment_Views.pm
#
# Interface generating methods for the Shipment MVC  (assoc with Shipment.pm, Shipment_App.pm)
#
##############################################################################################
package alDente::Submission_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);
use LampLite::Bootstrap;

## Local modules ##
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::Submission;
use RGTools::String;

use RGTools::RGIO;
use RGTools::Views;

use alDente::Form;
use alDente::Tools;
use alDente::Attribute_Views;
## globals ##
use vars qw( %Configs );

#############################################
#
# Standard view for single Shipment record
#
# Return: html page
###################
sub home_page {
###################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $sid        = $args{-sid};
    my $view_only  = $args{-view_only};
    my $contact_id = $args{-contact_id};
    my $img_dir    = $args{-image_dir};             # (Scalar) Image directory for folder images
    my $q          = new CGI;

    my $external;
    if ( $dbc->config('custom') =~ /external/i ) {
        $external = 1;
    }

    if ( !$contact_id ) {
        if ($sid) {
            ($contact_id) = $dbc->Table_find( 'Submission', 'FK_Contact__ID', "WHERE Submission_ID=$sid" );
        }
    }

    my %sub_info = $dbc->Table_retrieve( 'Submission', [ 'File_Required', 'Submission_Status' ], "WHERE Submission_ID=$sid" );
    my ($file_required) = $sub_info{File_Required}[0];
    my ($status)        = $sub_info{Submission_Status}[0];
    $status ||= 'Submitted';

    if ( $file_required =~ /^yes$/i && $status =~ /draft/i ) {
        $dbc->message("Attaching a file is required to complete this submission");
        $dbc->message("Please attach the file and then press 'Review and Submit Draft' to complete your submission");

    }

    my $email_output;
    my $output = '';
    my $sub_table;
    my $ok;
    my %fields;    #Contains the mapping between field name and field descriptions.
    my $modified = 1;                 #A flag indicating whether the submission has been modified by library admin.
    my $prev_approved_table;          #The previous table that was approved.  Normally this corresponds to the final table of the submission process.
    my $prev_approved_table_index;    #The previous table index that was approved.  Normally this corresponds to the final table of the submission process.
    my $prev_approved_record;         #The previous record that was approved. Normally this corresponds to the final record of the submission process.
    my $submission_ref = &SDB::Submission::Retrieve_Submission( -dbc => $dbc, -sid => $sid );

    unless ($submission_ref) {
        return 0;
    }
    my %submission;
    my $OLD_SUBMISSION_STRUCTURE = 0;
    if ( defined $submission_ref->{'ext_submission_dir'} ) {
        ### For backward compatibility, using an obsolete field to check
        $OLD_SUBMISSION_STRUCTURE = 1;
        %submission               = %{$submission_ref};
    }
    else {

        %submission = %{ &SDB::DB_Form::conv_FormNav_to_DBIO_format( -dbc => $dbc, -data => $submission_ref ) };
    }

    #####################
    # create Library dropdown for all the Projects which the contact is the collaborator. for external submission only
    ####################
    my $lib_list;
    if ($contact_id) {
        my $scope_condition = "FK_Contact__ID = $contact_id";

        my @project_array = $dbc->Table_find( "Collaboration,Project", "Project_ID", "WHERE FK_Project__ID=Project_ID AND $scope_condition" );
        my @complete_library_list;
        foreach my $project_id (@project_array) {

            my @libs = &get_FK_info( -dbc => $dbc, -field => 'FK_Library__Name', -id => undef, -condition => "WHERE FK_Project__ID=$project_id", -list => 1 );
            push( @complete_library_list, @libs );
        }

        #my $lib_list = $q->popup_menu(-name=>'Library',-values=>\@complete_library_list,-default=>$default,-force=>1);
        $lib_list = $q->popup_menu( -name => 'Library', -values => \@complete_library_list, -force => 1 );
    }

    ####################

    # list attachments and their links
    my $attach_ref = &SDB::Submission::get_attachment_list( -dbc => $dbc->dbc(), -sid => $sid );
    my $full_attach_list = &SDB::Submission::get_attachment_list( -dbc => $dbc->dbc(), -sid => $sid, -fullpath => 1 );

    # determine if this is a batch submission
    ### ARE WE SUPPORTING BATCH SUB?
    my $is_batchsub = 0;
    my $batch_file  = '';
    if ( ( int( @{$full_attach_list} ) > 0 ) && ( grep /batchfile\.csv/, @{$full_attach_list} ) ) {
        $is_batchsub = 1;
        my $curr_version = 0;

        # determine which is the latest batch submission file
        foreach my $file ( @{$full_attach_list} ) {
            if ( $file =~ /batchfile\.csv\.(\d+)$/ ) {
                if ( $curr_version < $1 ) {
                    $curr_version = $1;
                    $batch_file   = $file;
                }
            }
            else {
                $batch_file = $file;
            }
        }
    }

    my @headers = ( 'Record #', 'Field', 'Value' );

    # Do the mapping of field names and field descriptions.
    foreach my $table_index ( sort { $a <=> $b } keys( %{ $submission{index} } ) ) {
        my $table = $submission{index}{$table_index};
        my %info  = $dbc->Table_retrieve( 'DBTable,DBField', [ 'Field_Name', 'Prompt' ], "where DBTable_ID = FK_DBTable__ID and DBTable_Name = '$table'", -debug => 0 );
        my $i     = 0;
        while ( defined $info{Field_Name}[$i] ) {
            $fields{$table}->{ $info{Field_Name}[$i] } = $info{Prompt}[$i];
            $i++;
        }
    }

    $sub_table = HTML_Table->new( -toggle => 0, -bgcolour => 'white', -border => 1 );
    $sub_table->Set_Title("Submission ID $sid");

    my $prev_approved_table_found = 0;
    my %newids;
    my %inserted_records;
    my %List;

    # <CUSTOM> do a check to see if LibraryApplication entries (Primer) are valid
    if ( grep( /^LibraryApplication$/, keys( %{ $submission{tables} } ) ) && grep( /^LibraryVector$/, keys( %{ $submission{tables} } ) ) && !$external ) {
        foreach my $count ( keys %{ $submission{tables}{'LibraryApplication'} } ) {
            my $lib             = $submission{tables}{'LibraryApplication'}{$count}{'FK_Library__Name'};
            my $primer_id       = $submission{tables}{'LibraryApplication'}{$count}{'Object_ID'};
            my $object_class_id = $submission{tables}{'LibraryApplication'}{$count}{'FK_Object_Class__ID'};
            my $vector_id       = $submission{tables}{'LibraryVector'}{1}{'FK_Vector__ID'};
            if ( $lib && $primer_id && $object_class_id && $vector_id && ( $vector_id =~ /\d+/ ) ) {
                my ($class) = $dbc->Table_find( "Object_Class", "Object_Class", "WHERE Object_Class_ID=$object_class_id" );
                if ( $class eq 'Primer' ) {
                    my ($primer_name) = $dbc->Table_find( "Primer",             "Primer_Name",      "WHERE Primer_ID=$primer_id" );
                    my ($vector_name) = $dbc->Table_find( "Vector,Vector_Type", "Vector_Type_Name", "WHERE FK_Vector_Type__ID=Vector_Type_ID AND Vector_ID=$vector_id" );
                    my ($valid) = $dbc->Table_find( "Primer,Vector_TypePrimer,Vector_Type,Vector",
                        "Primer_Name", "WHERE FK_Primer__ID=Primer_ID AND Vector_TypePrimer.FK_Vector_Type__ID=Vector_Type_ID AND Vector.FK_Vector_Type__ID=Vector_Type_ID AND Primer_ID = $primer_id AND Vector_ID = $vector_id" );
                    unless ($valid) {
                        Message("Warning: Suggested Primer ($primer_name) is not a valid primer for Vector ($vector_name)");
                    }
                }
            }
        }
    }

    my $discrepancy_noted = '';

    # if viewing, then build the list of tables
    foreach my $table ( sort { $a <=> $b } values %{ $submission{index} } ) {
        my %info = $dbc->Table_retrieve( 'DBField,DBTable', [ 'DBTable_Title', 'Field_Name', 'Prompt' ], "WHERE DBTable_ID=FK_DBTable__ID AND DBTable_Name='$table'" );

        my %prompts;
        my $table_alias = $table;
        if (%info) {
            @prompts{ @{ $info{'Field_Name'} } } = @{ $info{'Prompt'} };
            $table_alias = $info{'DBTable_Title'}->[0];
        }
        else {
            $discrepancy_noted .= ",$table";
            my @fields = keys %{ $submission{tables}{$table} };
            @prompts{@fields} = @fields;
        }

        foreach my $index ( sort { $a <=> $b } keys %{ $submission{tables}{$table} } ) {
            foreach my $field ( keys %{ $submission{tables}{$table}{$index} } ) {
                my $value = $submission{tables}{$table}{$index}{$field};

                # check if the FK exists in the database
                # if it is, give a link
                if ( $value =~ /<\w+\.\w+>/ ) {
                    next;
                }
                my $label;
                if ( $field =~ /^Object_ID$/ ) {
                    my $object_class_id = $submission{tables}{$table}{$index}{'FK_Object_Class__ID'};
                    my ($class) = $dbc->Table_find( "Object_Class", "Object_Class", "WHERE Object_Class_ID=$object_class_id" );
                    $label = $dbc->get_FK_info( $field, $value, -class => $class );
                    $value = &Link_To( -link_url => $dbc->homelink(), -label => $label, -param => "&HomePage=$class&ID=$value" ) unless ($external);

                }
                elsif ( my ( $fk_tablename, $field_name, undef ) = $dbc->foreign_key_check($field) ) {
                    if ($value) {
                        $label = $dbc->get_FK_info( $field, $value );
                        $value = &Link_To( -link_url => $dbc->homelink(), -label => $label, -param => "&HomePage=$fk_tablename&ID=$value" ) unless ($external);
                    }
                }
                $label ||= $value;
                my @row = ( $index + 1, $prompts{$field}, $label );
                unless ( defined $List{$table} ) {
                    $List{$table} = new HTML_Table->new( -title => "$table_alias information", -width => '100%' );
                    $List{$table}->Set_Headers( \@headers );
                    $List{$table}->Toggle_Colour_on_Column(1);
                }
                if ( $label =~ /\w+/ ) { $List{$table}->Set_Row( \@row ); }
            }
        }
    }

    if ($discrepancy_noted) {
        Message("Warning: Note some tables in the original submission ($discrepancy_noted) seem to have been deprecated, so some information may be missing from this view");
    }

    $output .= "<BR>";

    my %super_table = %{ &SDB::Submission::combine_Tables( \%List ) };
    if ($email_output) {
        foreach ( keys %List ) {
            $sub_table->Set_Row( [ $List{$_}->Printout(0) ] );
        }
    }
    elsif ($img_dir) {
        $sub_table->Set_Row( [ SDB::HTML::create_tree( -tree => \%super_table ) ] );
    }
    else {
        $sub_table->Set_Row( [ SDB::HTML::create_tree( -tree => \%super_table ) ] );
    }
    $output .= $sub_table->Printout(0);

    unless ($email_output) {
        unless ($external) {
            $output .= '<P>' . alDente::Attribute_Views::show_attribute_link( -dbc => $dbc, -object => 'Submission', -id => $sid ) . '<br /><br />';
        }
        $output .= "<BR>"
            . $dbc->Table_retrieve_display(
            'Submission',
            [ 'Submission_ID', 'Submission_DateTime', 'Submission_Source', 'Submission_Status', 'FK_Contact__ID', 'FKSubmitted_Employee__ID', 'Submission_Comments', 'FKTo_Grp__ID as To_Grp', 'FKFrom_Grp__ID as From_Grp', 'Reference_Code' ],
            "WHERE Submission_ID=$sid",
            -return_html => 1
            );

        my ( $path, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'submission', -dbc => $dbc );
        $path .= $sub_dir;
        my ($contact_id) = $dbc->Table_find( 'Submission', 'FK_Contact__ID', "WHERE Submission_ID=$sid" );

        my @atts = @$attach_ref if $attach_ref;
        if ( $status =~ /Draft/ || int @atts ) {
            $output .= "<h2>Attachments</h2>";
        }
        foreach my $file (@atts) {
            my $link = &SDB::Submission::get_attachment_link( -dbc => $dbc->dbc(), -sid => $sid, -file => $file );

            # only allow attachment viewing internally (may allow external viewing in the future)
            $output .= vspace() . $file . hspace(5) . "<a href='$link'>View</a>";
            if ( $file =~ /\.xls$/ ) {
                unless ($external) {
                    $output .= hspace(2) . "&nbsp" . &Link_To( $dbc->config('homelink'), 'Upload', "&cgi_application=SDB::Import_App&rm=Upload&FK_Contact__ID=$contact_id&input_file_name=$path/$status/submission_${sid}/attachments/$file", 'blue' );
                    $output .= hspace(2) . "&nbsp"
                        . &Link_To( $dbc->config('homelink'), 'Preview', "&cgi_application=SDB::Import_App&rm=Upload&preview_only=1&FK_Contact__ID=$contact_id&input_file_name=$path/$status/submission_${sid}/attachments/$file", 'blue' ) . "<br>";
                }

            }
            else {
                $output .= hspace(2) . "&nbsp" . "<br>";
            }
        }

        # start multipart form

        ### Actions...

        $output .= "<BR>";

        $output .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => '' );

        $output .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 );
        $output .= $q->hidden( -name => 'Submission_ID',   -value => $sid,                      -force => 1 );
        $output .= $q->hidden( -name => 'Table',           -value => 'Submission',              -force => 1 );
        $output .= $q->hidden( -name => 'Field',           -value => 'Submission_ID',           -force => 1 );
        $output .= $q->hidden( -name => 'Like',            -value => $sid,                      -force => 1 );

        if ($external) {
            if ( $status =~ /Draft/ ) {
                $output .= "<BR>Attach file:" . $q->filefield( -name => 'Submission_Upload', -size => 30, -force => 1 ) . "<BR>";
                $output .= "<BR>" . $q->submit( -name => 'rm', -value => 'Attach File', -class => "Search", -force => 1 ) . "<br>";
            }
        }

        unless ($view_only) {

            $output .= "<ul>";
            if ($external) {
                if ( $status =~ /Draft/ ) {

                    $output .= "<li>" . $q->submit( -name => 'rm', -value => 'Edit submission',         -class => "Search", -force => 1 ) . "<br>";
                    $output .= "<li>" . $q->submit( -name => 'rm', -value => 'Review and Submit Draft', -class => "Action", -force => 1 ) . "<br>";

                    # $output .= "<li>" . $q->submit( -name => 'rm', -value => 'Copy Submission for New Library', -class => "Action", -force => 1 ) . " Choose Library: " . $lib_list;
                }
            }
            else {
                if ( $status =~ /Draft/ ) {

                    $output .= "<li>" . $q->submit( -name => 'rm', -value => 'Edit submission',         -class => "Search", -force => 1 ) . "<br>";
                    $output .= "<li>" . $q->submit( -name => 'rm', -value => 'Review and Submit Draft', -class => "Action", -force => 1 ) . "<br>";

                }
                elsif ( $status =~ /Submitted/i ) {
                    if ( ( $submission{flags}->{isNewLibrary}->{1} && !$modified ) ) {

                        #Do not allow approval yet since library admin need to fill in library name etc.
                    }
                    else {
                        my $prompt = "Are you sure you want to approve submission ID $sid?";
                        $output .= "<li>" . $q->submit( -name => 'rm', -value => 'Approve Submission', -class => "Search", -force => 1, -onClick => "return confirm('$prompt');" ) . "<br>";
                    }

                    $output .= "<li>" . $q->submit( -name => 'rm', -value => 'Edit submission', -class => "Search", -force => 1 ) . "<br>";
                    my $prompt = "Are you sure you want to cancel submission ID $sid?";
                    $output .= "<li>" . $q->submit( -name => 'rm', -value => 'Cancel Submission', -class => "Search", -force => 1, -onClick => "return confirm('$prompt');" ) . "<br>";

                    my $prompt = "Are you sure you want to reject submission ID $sid?";
                    $output .= "<li>" . $q->submit( -name => 'rm', -value => 'Reject Submission', -class => "Search", -force => 1, -onClick => "return confirm('$prompt');" ) . "<br>";

                }
                elsif ( !$view_only && $status =~ /Approved/i ) {
                    my $prompt = "Are you sure you want to complete submission ID $sid?";
                    $output .= "<li>" . $q->submit( -name => 'rm', -value => 'Completed Submission', -class => "Search", -force => 1, -onClick => "return confirm('$prompt');" ) . "<br>";
                }
                elsif ( $status =~ /Completed/i ) {
                    ###Do nothing.
                }
                elsif ( $status =~ /Cancelled/i ) {
                    my $prompt = "Are you sure you want to change submission ID $sid to Submitted?";
                    $output .= "<li>" . $q->submit( -name => 'rm', -value => 'Activate cancelled submission', -class => "Search", -force => 1, -onClick => "return confirm('$prompt');" ) . "<br>";

                }

                if ( !$view_only ) {
                    $output .= "<li>" . $q->submit( -name => 'rm', -value => 'View/Edit Submission Info', -class => "Std" ) . "<BR>";
                }

            }    #external=0 ends

            $output .= "</ul>";
        }
    }

    $output .= $q->hidden( -name => 'external',     -value => $external,      -force => 1 );
    $output .= $q->hidden( -name => 'Require_File', -value => $file_required, -force => 1 );
    $output .= $q->end_form();

    return $output;
}
##############################
# Checks submissions
##############################
sub check_submissions {
######################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = new CGI;
    my $dbc  = $args{-dbc} || $self->{dbc} || $self->param('dbc');

    my $source          = $args{-source};
    my $status          = $args{-status};
    my $submitted_since = $args{-submitted_since};
    my $submitted_until = $args{-submitted_until};
    my $approved_since  = $args{-approved_since};
    my $approved_until  = $args{-approved_until};
    my $table           = $args{-table};
    my $comments        = $args{-comments};
    my $id              = $args{-id};
    my $content         = $args{-content};
    my $form_name       = $args{-form_name} || "Submissions";
    my $groups          = $args{-groups};

    my $submissions = HTML_Table->new();
    $submissions->Set_Class('small');
    $submissions->Set_Title($form_name);

    my $view_only = !$dbc->admin_access();
    if ( $id =~ /^\d+$/ ) { return $self->home_page( -sid => $id, -view_only => $view_only ) }

    if ( ( $form_name eq 'New Account Requests' ) && ( $status eq 'Submitted' ) ) {
        $submissions->Set_Headers(
            [ 'Submission ID', 'From Group', 'To Group', 'New Employee', 'New Dept', 'New Group', 'Submitted At', 'Comments', 'Approve Submission', 'Cancel Submission', 'Delete Submission', 'Edit Submission', 'Reject Submission', 'Reference_Code' ] );
    }
    else {
        $submissions->Set_Headers(
            [   'Submission ID',
                'From Group',
                'To Group',
                'Source',
                'Status',
                'Submitted By',
                'Submitted At',
                'Object',
                'Submitted Identifier',
                'Approved Identifier',
                'Approved By',
                'Approved At',
                'Comments',
                'Approve Submission',
                'Cancel Submission',
                'Edit Submission',
                'Reject Submission',
                'Reference Code'
            ]
        );
    }

    my $condition = "where 1 ";
    if ($id) {

        # ID will override anything else
        $condition .= " AND Submission_ID = $id ";
    }
    else {
        if ($source) { $condition .= " and Submission_Source = '$source' " }
        if ( $status && $status ne 'All' ) { $condition .= " and Submission_Status = '$status' " }
        if ($submitted_since) {
            $condition .= " AND Submission_DateTime >= '$submitted_since' ";
        }
        if ($submitted_until) {
            $condition .= " AND Submission_DateTime <= '$submitted_until' ";
        }
        if ($approved_since) {
            $condition .= " AND Approved_DateTime >= '$approved_since' ";
        }
        if ($approved_until) {
            $condition .= " AND Approved_DateTime <= '$approved_until' ";
        }
        if ($table) {
            $condition .= " AND Table_Name = '$table' ";
        }
        if ( !$groups ) {
            my ($public_grp) = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name='Public'" );
            $groups = $dbc->get_local('group_list');
            $groups .= ",$public_grp";
        }
        $condition .= " AND (FKTo_Grp__ID IN ($groups) OR FKFrom_Grp__ID IN ($groups))";
    }

    $condition .= " ORDER BY Submission_ID";

    my %info = $dbc->Table_retrieve(
        'Submission',
        [   'Submission_ID', 'Submission_Source', 'Submission_Status', 'FK_Contact__ID', 'FKSubmitted_Employee__ID', 'Submission_DateTime', 'FKApproved_Employee__ID', 'Approved_DateTime',
            'FKTo_Grp__ID',  'FKFrom_Grp__ID',    'Table_Name',        'Key_Value',      'Submission_Comments',      'Reference_Code'
        ],
        $condition
    );

    my $reference_code;

    my $i = -1;
    while ( defined $info{Submission_ID}[ ++$i ] ) {
        my $sid = $info{Submission_ID}[$i];

        if ($content) {
            my $sub = &SDB::Submission::Retrieve_Submission( -dbc => $dbc, -sid => $sid, -quiet => 1, -output_format => 'TXT' );
            unless ( $sub =~ /$content/i ) {
                next;
            }
        }

        my $source = $info{Submission_Source}[$i];
        my $status = $info{Submission_Status}[$i];

        my $submitted_by;
        if ( $info{FK_Contact__ID}[$i] ) {
            $submitted_by = $dbc->get_FK_info( 'FK_Contact__ID', $info{FK_Contact__ID}[$i] );
        }
        elsif ( $info{FKSubmitted_Employee__ID}[$i] ) {
            $submitted_by = $dbc->get_FK_info( 'FK_Employee__ID', $info{FKSubmitted_Employee__ID}[$i] );
        }
        my $submission_datetime = $info{Submission_DateTime}[$i];
        my $approved_by         = $dbc->get_FK_info( 'FK_Employee__ID', $info{FKApproved_Employee__ID}[$i] );
        my $approved_datetime   = $info{Approved_DateTime}[$i];

        my $submission_comments = $info{Submission_Comments}[$i];
        my $from_grp            = $dbc->get_FK_info( 'FK_Grp__ID', $info{FKFrom_Grp__ID}[$i] );
        my $to_grp              = $dbc->get_FK_info( 'FK_Grp__ID', $info{FKTo_Grp__ID}[$i] );
        my $table_name          = $info{Table_Name}[$i];
        $reference_code = $info{Reference_Code}[$i];

        # Figure out the submitted and approved name,...
        my $submitted_name;
        my $approved_name;

        if ( $status eq 'Approved' ) {
            my $submission_ref;

            eval { ($submission_ref) = &SDB::Submission::Retrieve_Submission( -dbc => $dbc, -sid => $sid, -quiet => 1 ); };
            if ($@) {
                Message("Error reading Submission $sid");
                $i++;
                next;
            }

            ### For backward compatibility, using an obsolete field to check
            unless ( defined $submission_ref->{'ext_submission_dir'} ) {
                $submission_ref = &SDB::DB_Form::conv_FormNav_to_DBIO_format( -dbc => $dbc, -data => $submission_ref, -validate => 0 );
            }

            if ( exists $submission_ref->{tables}{$table_name} ) {
                my ($primary_field) = $dbc->get_field_info( $table_name, undef, 'Primary' );
                $submitted_name = $submission_ref->{tables}{$table_name}{0}{$primary_field};
            }
            $approved_name = $info{Key_Value}[$i];
        }
        else {
            $submitted_name = $info{Key_Value}[$i];
        }

        if ( ( $form_name eq 'New Account Requests' ) && ( $status eq 'Submitted' ) ) {
            my $submission_ref;
            eval { ($submission_ref) = &SDB::Submission::Retrieve_Submission( -dbc => $dbc, -sid => $sid, -quiet => 1 ) };

            my $dept              = '';
            my $employee_fullname = '';
            my $grp               = '';
            if ( defined $submission_ref ) {
                
                my ($employee_form, @grp_forms);
                my @keys = keys %$submission_ref;
                foreach my $key (@keys) {
                    if ( $submission_ref->{$key}{'0'}{'DBForm'} eq 'Employee') { $employee_form = $key }
                    if ( $submission_ref->{$key}{'0'}{'DBForm'} =~/Grp/) { push @grp_forms, $key }
                 }
                 
                my $new_emp = $submission_ref->{$employee_form}{'0'}{'Employee_FullName'} || $submission_ref->{$employee_form}{'0'}{'Employee_Name'} || $submission_ref->{'Employee_FullName'} || $submission_ref->{'Employee_Name'};
                if ($new_emp) {
                    ## For new account submissions, show the Employee Name & Group ##
                    $dept = $submission_ref->{$employee_form}{'0'}{'FK_Department__ID'} || $submission_ref->{FK_Department__ID};
                    if ( $dept && ref $dept eq 'ARRAY' ) { $dept = $dept->[0] }
                    $dept              = $dbc->get_FK_info( -field => 'FK_Department__ID', -id => $dept );
                    $employee_fullname = $new_emp;
                    $grp               = $submission_ref->{$grp_forms[0]}{'0'}{'FK_Grp__ID'}[0];
                }
            }
            $submissions->Set_Row(
                [   &Link_To( $dbc->config('homelink'), $sid, "&cgi_application=alDente::Submission_App&rm=View&Submission_ID=$sid", 'blue', ['newwin'] ),
                    $from_grp,
                    $to_grp,
                    $employee_fullname,
                    $dept, $grp,
                    $submission_datetime,
                    $submission_comments,
                    &Link_To( $dbc->config('homelink'), 'Approve', "&cgi_application=alDente::Submission_App&rm=Approve&Submission_ID=$sid", 'blue', '', "onclick=\"return confirm('Are you sure you want to approve submission ID $sid?');\"" ),
                    &Link_To( $dbc->config('homelink'), 'Cancel',  "&cgi_application=alDente::Submission_App&rm=Cancel&Submission_ID=$sid",  'blue', '', "onclick=\"return confirm('Are you sure you want to cancel submission ID $sid?');\"" ),
                    &Link_To(
                        $dbc->config('homelink'),
                        'Delete', "&cgi_application=alDente::Submission_App&rm=Delete&Submission_ID=$sid",
                        'blue', '', "onclick=\"return confirm('Are you sure you want to delete submission ID $sid? (No email notification will be sent out)');\""
                    ),
                    &Link_To( $dbc->config('homelink'), 'Edit', "&cgi_application=alDente::Submission_App&rm=Edit&Submission_ID=$sid", 'blue' ),
                    &Link_To( $dbc->config('homelink'), 'Reject', "&cgi_application=alDente::Submission_App&rm=Reject&Submission_ID=$sid", 'blue', '', "onclick=\"return confirm('Are you sure you want to reject submission ID $sid?');\"" ),
                    $reference_code
                ]
            );
        }
        else {
            $submissions->Set_Row(
                [   &Link_To( $dbc->config('homelink'), $sid, "&cgi_application=alDente::Submission_App&rm=View&Submission_ID=$sid", 'blue', ['newwin'] ),
                    $from_grp, $to_grp, $source, $status, $submitted_by, $submission_datetime, $table_name, $submitted_name, $approved_name, $approved_by, $approved_datetime, $submission_comments,
                    &Link_To(
                        $dbc->homelink(),
                        'Approve',
                        "&cgi_application=alDente::Submission_App&rm=Approve&Submission_ID=$sid",
                        'blue', '', "onclick=\"return confirm('Are you sure you want to approve submission ID $sid?');\""
                    ),
                    &Link_To( $dbc->config('homelink'), 'Cancel', "&cgi_application=alDente::Submission_App&rm=Cancel&Submission_ID=$sid", 'blue', '', "onclick=\"return confirm('Are you sure you want to cancel submission ID $sid?');\"" ),
                    &Link_To( $dbc->config('homelink'), 'Edit',   "&cgi_application=alDente::Submission_App&rm=Edit&Submission_ID=$sid",   'blue' ),
                    &Link_To( $dbc->config('homelink'), 'Reject', "&cgi_application=alDente::Submission_App&rm=Reject&Submission_ID=$sid", 'blue', '', "onclick=\"return confirm('Are you sure you want to reject submission ID $sid?');\"" ),
                    $reference_code
                ]
            );
        }
    }

    if ( !$submissions->rows ) { $submissions->Set_sub_header("(None Pending)") }

    my $form .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Submission_Search_Results' ) . $submissions->Printout(0) . $q->end_form();

    return $form;
}

#
# Move to Submission_Views... and include display_record on right as standard home pages
#

#########################
sub display_Group_Login {
#########################
    my %args = &filter_input( \@_, -args => 'login_messages' );
    my $dbc = $args{-dbc};

    my $contact_id = $args{-current_contact_id};
    my $grp        = $dbc->get_local('user_name');
    my $q          = new CGI;

    my $login_text = String::format_Text( -text => $grp, -color => 'blue', -italic => 1, -bold => 1 );
    my $button_name = String::format_Text( -text => 'Add New User', -color => 'red', -italic => 1, -bold => 1 );
    my $login_message = String::format_Text( -text => "'$login_text' is a multi-user group account. Please select your name from the list of users associated with '$login_text' in order to continue.", -size => 3 );
    my $user_add_message = String::format_Text( -text => "If you are not on the list of users please add yourself to the list by clicking on the '$button_name' button", -size => 3 );

    my $page = '<hr>' . String::format_Text( -text => "Public Submission Page", -color => '#088A08', -size => 5, -face => "arial" ) . '<hr>' . vspace() . $login_message . vspace();

    #<P>Please identify yourself from the list of members<BR>(you may add yourself as a new group member first if necessary).

    my $user_name     = $dbc->get_local('user_name');
    my $group_contact = $dbc->get_local('group_contact');
    my $id            = $dbc->get_local('userid') || $dbc->get_local('user_id');

    $contact_id ||= $group_contact;

    my @users = $dbc->Table_find( 'Contact_Relation,Contact', "FKMember_Contact__ID", " WHERE Contact_ID = '$contact_id' AND FKGroup_Contact__ID = Contact_ID " );

    if ( !$users[0] ) {
        $page .= '<P>' . String::format_Text( -text => "There are currently no users associated with $login_text", -highlight => 'yellow' ) . vspace;
    }
    my $list = Cast_List( -list => \@users, -to => 'string' );
    $page .= alDente::Form::start_alDente_form( -dbc => $dbc ) . '<P>' . $q->submit( -force => 1, -name => 'Select User', -value => 'Select User', -class => 'Action', -onClick => 'return validateForm(this.form)' );

    if ( !$list ) {
        $page .= $q->popup_menu( -name => 'FK_Contact__ID', -value => [] );
    }
    else {
        $page .= alDente::Tools::search_list( -dbc => $dbc, -field => 'FK_Contact__ID', -condition => "Where Contact_ID IN ($list)" );
    }

    $page .= vspace() . set_validator( -name => 'FK_Contact__ID', -mandatory => 1, -prompt => 'You must specify a user, please add a new user if your name is not in the list' ) . $q->end_form();

    $page .= '<hr>' . vspace();
    $page
        .= alDente::Form::start_alDente_form( -dbc => $dbc )
        . $user_add_message
        . vspace() . '<P>'
        . $q->submit( -force => 1, -name => 'rm', -value => 'Add New User', -class => 'Action' )
        . $q->hidden( -force => 1, -name => 'cgi_application',    -value => 'alDente::Submission_App' )
        . $q->hidden( -force => 1, -name => 'Current Contact_ID', -value => $contact_id )
        . $q->end_form() . '<hr>';

    return $page;

}

#########################
sub display_Add_User {
#########################
    my %args     = &filter_input( \@_, -args => 'login_messages' );
    my $dbc      = $args{-dbc};
    my $grp_user = $args{-grp_user};

    #    my $new_contact_id = $args{-new_contact_id};
    my $new_contact_id     = $args{-new_contact_id};
    my $current_contact_id = $args{-current_contact_id};
    my $phone              = $args{-phone};
    my $gc                 = $args{-gc};

    my $q             = new CGI;
    my $button_prompt = 'Submit User Info';    ## Name of run mode button at bottom of page

    my $group_contact = $dbc->get_local('group_contact');
    my $grp           = $dbc->get_local('user_name');
    my $login_text    = String::format_Text( -text => $grp, -color => 'yellow', -italic => 1, -bold => 1 );

    my $page = '<hr>' . String::format_Text( -text => "Public Submission Page", -color => '#088A08', -size => 5, -face => "arial" ) . '<hr>' . alDente::Form::start_alDente_form( -dbc => $dbc );

    my %info = $dbc->Table_retrieve( 'Contact', ['FK_Organization__ID as Org'], "WHERE Contact_ID = $current_contact_id" );

    my ( $Preset, $Hidden, $Require, $Grey );
    $Hidden = { 'Canonical_Name' => '', 'Contact_Fax' => '', 'Contact_Type' => 'Collaborator', 'contact_status' => 'Active', 'FK_Organization__ID' => $info{Org}->[0], 'Group_Contact' => 'No', 'Contact_Notes' => ' ' };
    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Contact', -db_action => 'append', -wrap => 0 );

    my ( $def_name, $def_email, $def_phone );
    my $def_gc = 'No';
    if ($new_contact_id) {
        ## If contact supplied, allow user to edit current details rather than adding duplicate record ##
        $button_prompt = 'Save User';
        my ($default) = $dbc->Table_find( 'Contact', 'Contact_Name, Contact_Email, Contact_Phone, Group_Contact, Canonical_Name', "WHERE Contact_ID = $new_contact_id" );
        ( $def_name, $def_email, $def_phone, $def_gc ) = split ',', $default;
        if ($phone) { $def_phone = $phone }    ## give precedence to entered value in this case ...
        if ($gc)    { $def_gc    = $gc }       ## give precedence to entered value in this case ...

        $Preset = { 'Contact_Name' => $def_name, 'Contact_Email' => $def_email, 'Contact_Phone' => $def_phone };    ##  'Group_Contact' => $def_gc };
    }

    $form->configure( -preset => $Preset, -omit => $Hidden );
    $page .= String::format_Text( -text => "Fields in red are mandatory", -color => 'red', -bold => 1 ) . vspace();
    $page .= $form->generate( -title => "Add New User to $login_text", -submit => 1, -mode => 'no button', -end_form => 0, -start_form => 0, -form => 'Append', -return_html => 1, -navigator_on => 0 );

    $page
        .= $q->hidden( -name => 'Current Contact_ID', -value => $current_contact_id,       -force => 1 )
        . $q->hidden( -name  => 'New Contact_ID',     -value => $new_contact_id,           -force => 1 )
        . $q->hidden( -name  => 'cgi_application',    -value => 'alDente::Submission_App', -force => 1 )
        . hspace(15)
        . $q->hidden( -name => 'Confirmed', -value => 1, -force => 1 )
        . $q->submit( -name => 'rm', -value => $button_prompt, -class => 'Action', -onClick => 'return validateForm(this.form)' );
    $page .= $q->end_form() . '<hr>' . vspace(2);

    return $page;
}

#########################################
sub display_submission_search_form {
#########################################
    my $self   = shift;
    my %args   = &filter_input( \@_, -args => 'groups' );                #,-mandatory=>'groups');
    my $groups = $args{-groups};
    my $dbc    = $args{-dbc} || $self->{'dbc'} || $self->param('dbc');

    my $q  = new CGI;
    my $BS = new Bootstrap;
    my $group_list;

    ## get list of submission statuses
    my @choices = $dbc->get_enum_list( 'Submission', 'Submission_Status' );
    @choices = sort(@choices);
    unshift( @choices, 'All' );

    my $submission_search_table = HTML_Table->new( -title => "Submission Search" );
    $submission_search_table->Toggle_Colour('off');

    $submission_search_table->Set_Row( [ ("Submission Search:") ] );
    $submission_search_table->Set_Row(
        [   "Submitted Since:",
            $q->textfield( -name => 'Submitted_Since', -id => 'Submitted_Since', -value => &date_time('-30d'), -onclick => $BS->calendar( -id => 'Submitted_Since' ) ),
            "Approved Since:",
            $q->textfield( -name => 'Approved_Since', -id => 'Approved_Since', -onclick => $BS->calendar( -id => 'Approved_Since' ) )
        ]
    );

    $submission_search_table->Set_Row(
        [   "Submitted Until:",
            $q->textfield( -name => 'Submitted_Until', -id => 'Submitted_Until', -onclick => $BS->calendar( -id => 'Submitted_Until' ) ),
            "Approved Until:",
            $q->textfield( -name => 'Approved_Until', -id => 'Approved_Until', -onclick => $BS->calendar( -id => 'Approved_Until' ) )
        ]
    );
    $submission_search_table->Set_Row( [ "Submission ID: ", $q->textfield( -name => 'Submission_ID' ), "Status: ", $q->popup_menu( -name => 'Submission_Status', -value => \@choices, -default => 'Submitted' ) ] );
    $submission_search_table->Set_Row( [ "Comments:", $q->textfield( -name => 'Comments' ) ] );
    $submission_search_table->Set_Row( [ "Submission Contains:", Show_Tool_Tip( $q->textfield( -name => 'Submission_Content' ), "Searches the entire content of the submission" ) ] );

    $submission_search_table->Set_Row( [ $q->submit( -name => 'rm', -value => 'Check Submissions', -class => "Search", -force => 1 ) . $q->hidden( -name => 'Groups', -value => $group_list ) ] );

    my $form = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Submission_Search' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 ) . $submission_search_table->Printout(0) . $q->end_form();
    return $form;

}

###################################
#  This method creates a button for the submit Sequencing Work Request run mode
###################################
sub display_work_request_button {
###################################
    my $self = shift;
    my $q    = new CGI;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{'dbc'} || $self->param('dbc');

    my $submit_work = $q->submit( -name => 'rm', -value => 'Submit Sequencing Work Request', -class => "Std" );
    my $form .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Submission_Search' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 ) . $submit_work . $q->end_form();
    return $form;

}

return 1;
