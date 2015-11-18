################################################################################
#
# Special_Branches.pm
#
# This modules handles custom branching logic
#  (eg. after updating a library it will prompt for Library Format info...
#
################################################################################
# Ran Guin (2001) rguin@bcgsc.bc.ca
#
################################################################################
# $Id: Special_Branches.pm,v 1.122 2004/12/07 19:26:26 mariol Exp $
################################################################################
# CVS Revision: $Revision: 1.122 $
#     CVS Date: $Date: 2004/12/07 19:26:26 $
################################################################################
#
# Improvements to be made:
#
#
################################
#
# Globals variables for custom use:
#
#
################################
package alDente::Special_Branches;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Special_Branches.pm - This modules handles custom branching logic 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

This modules handles custom branching logic <BR>(eg. after updating a library it will prompt for Library Format info...<BR>Ran Guin (2001) rguin@bcgsc.bc.ca<BR>Improvements to be made:<BR>Globals variables for custom use:<BR>

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
    initialize_Form
    Pre_DBForm_Skip
    Post_DBForm_Skip
    DB_Form_Custom_Configs
);
@EXPORT_OK = qw(
);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Conversion;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::DB_Object;
use SDB::DB_Form;
use alDente::Form;
use alDente::Info;
use alDente::Library;
use alDente::SDB_Defaults;
use alDente::Well;
use alDente::Rack;
use alDente::UseCase;

##############################
# global_vars                #
##############################
use vars qw(%Field_Info $testing $dbc $dbase $login_name $trace_level);
use vars qw(%Defaults $Connection $Current_Department $Transaction $Multipage_Form);

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
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#####################################
# Pre-set certain values if required
###########################
sub initialize_Form {
#################
    my $table = shift;

    return;
}

###########################
sub Pre_DBForm_Skip {
###########################
    #
    # escape logic prior to running DB_Form_Branch (special handling of particular cases)
    #
    # return 'skip' if DB_Form module should be skipped (because of customized handling probably)
    # return 'error' if DB_Form module should be skipped (because of detected error)
    # return hash if DB_Form module should be called with more input parameters (customized auto-setting of fields)
    # return 0 if DB_Form module should be checked for branches (normal)
    #
    #
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    if ( param('Delete Record') && !( param('PageName') ) ) {    ### for Record Deletions outside of DB_Form_Viewer...

        if    ( param('TableName') eq 'Run' )      { return 'skip'; }
        elsif ( param('TableName') eq 'Solution' ) { return 'skip'; }
        elsif ( param('TableName') eq 'Plate' )    { return 'skip'; }

    }
    elsif ( param('DBUpdate') ) {                                ## if updating plate, auto-set Plate_Size and Plate_Number
        my %Set;
        foreach my $param ( param() ) {
            $Set{$param} = join ',', param($param);
        }

        return \%Set;
    }

    return 0;                                                    ### no skip ... continue as usual...
}

############################
sub Post_DBForm_Skip {
############################

    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $returnval = shift;

    if ( param('Update Table') ) {                               ### special branches after older table updates
        my $table = param('TableName');
        my $found = &alDente::Info::GoHome( $dbc, $table, $returnval );
        return $returnval;                                       ### skip to end...
    }
    elsif ( param('DBUpdate') ) {                                #### special branches after newer table updates...(Dec '02)
        my $home_barcode;                                        # If home page is to be shown, this will store the barcode of the item (e.g. PLA40000)
        if ( $returnval =~ /form/i ) { return $returnval; }      ### already created form...
        my $table         = join ',', param('TableName');
        my $target        = param('Target');
        my %Parameters    = &alDente::Form::_alDente_URL_Parameters($dbc);
        my $submission_id = param('Edit_Submission');
        my $source        = param('Submission_Source');
        my %submission;
        my %preset;
        my %include;

        my $next_table;
        my $mode = param('Mode');
        ### Submission stuff ###
        if ($submission_id) {    # load the info from the submission.
            if ( param('DBUpdate') =~ /Finish/i || param('DBUpdate') =~ /Update\s+(\w+)/ ) {
                return "form";
            }
            else {
                %submission = &SDB::Submission::Load_Submission( $dbc, $submission_id, $source, 'load' );
                $include{Edit_Submission}   = $submission_id;
                $include{Submission_Source} = $source;
            }
            my $lib = get_Table_Param( -field => 'FK_Library__Name', -dbc => $dbc );

            my %grey;
            my %fk_extra;
            my %skip;

            # Grab what's the current table/record that we are deaing with and find what should we do next.
            my $table_index  = param('Table_Index');
            my $record_index = param('Record_Index');
            my $next_table;
            my $next_table_index;
            my $next_record_index;

            #If there are still records to deal with for the current table, then simply go to the next record.
            my $found = 0;    # Whether an appropriate combination of table/record is found
            until ($found) {
                if ( $record_index < keys( %{ $submission{tables}->{$table} } ) ) {
                    $next_table        = $table;
                    $next_table_index  = $table_index;
                    $next_record_index = $record_index + 1;
                }
                else {        #Go to the next table and record 1.
                    $next_table        = $submission{index}->{ $table_index + 1 };
                    $next_table_index  = $table_index + 1;
                    $next_record_index = 1;
                }
                my ($pfield) = get_field_info( $dbc, $next_table, undef, 'Primary' );
                my @uniques = get_field_info( $dbc, $next_table, undef, 'Unique' );
                my $condition = "where 1";
                if ( $pfield && @uniques ) {
                    $condition .= " and ($pfield = '$submission{tables}{$next_table}{$next_record_index}{$pfield}'";
                    foreach my $unique (@uniques) {
                        $condition .= " or $unique = '$submission{tables}{$next_table}{$next_record_index}{$unique}'";
                    }
                    $condition .= ")";
                }
                elsif ($pfield) { $condition .= " and $pfield = '$submission{tables}{$next_table}{$next_record_index}{$pfield}' and $pfield is not null and $pfield <> ''" }
                if ($next_table) {
                    my ($record) = $dbc->Table_find( $next_table, 'Count(*)', $condition );
                    if ($record) {
                        $found = 0;
                        $table_index++;
                        $table        = $submission{index}->{$table_index};
                        $record_index = 1;
                    }
                    else {
                        $found = 1;
                    }

                    #print "RECORD=$record; FOUND=$found for $pfield = '$submission{tables}{$next_table}{$next_record_index}{$pfield}' ($condition)<br>";
                }
            }

            #$include{Library_Name} = $lib;
            $include{Table_Index}  = $next_table_index;
            $include{Record_Index} = $next_record_index;

            ####Determine the appropiate mode automatically.
            if ( $next_table_index == 1 ) {
                $mode = 'Start';
            }
            elsif ( ( $next_table_index > 1 ) && ( $next_table_index < keys( %{ $submission{index} } ) ) ) {
                $mode = 'Continue';
            }
            elsif ( ( $next_table_index == keys( %{ $submission{index} } ) ) && ( $next_record_index < keys( %{ $submission{tables}->{$next_table} } ) ) ) {
                $mode = 'Continue,Finish';
            }
            elsif ( ( $next_table_index == keys( %{ $submission{index} } ) ) && ( $next_record_index == keys( %{ $submission{tables}->{$next_table} } ) ) ) {
                $mode = 'Finish';
            }

            ###################################################Custom handling#########################################################
            my %params = (
                'dbc'            => $dbc,
                'sid'            => $submission_id,
                'source'         => $source,
                'curr_table'     => $table,
                'curr_record'    => $record_index,
                'next_table'     => $next_table,
                'next_record'    => $next_record_index,
                'mode'           => $mode,
                'submission_ref' => \%submission,
                'p_ref'          => \%preset,
                'i_ref'          => \%include,
                'f_ref'          => \%fk_extra,
                'g_ref'          => \%grey,
                's_ref'          => \%skip
            );
            &SDB::Submission::Custom_Submission_Form( \%params );
            ###########################################################################################################################;

            $grey{'FK_Library__Name'}    = $lib if $lib;
            $include{'FK_Library__Name'} = $lib if $lib;

            if ( $returnval =~ /error/i ) {    #If there was error, we don't want to clear the data user has entered.
                my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $next_table, -target => $target, -parameters => \%Parameters, -wrap => 1, -mode => $mode );
                if ($Multipage_Form) {
                    $form->data( $Multipage_Form->data() );    # Get data from previous forms
                }
                $form->configure( -grey => \%grey, -preset => \%preset, -include => \%include, -fk_extra => \%fk_extra, -skip => \%skip );
                $form->generate();
            }
            else {                                             # Else that means we are going to the next primer and let's reset the form to clean state.
                my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $next_table, -target => $target, -parameters => \%Parameters, -wrap => 1, -reset => 1, -mode => $mode );
                if ($Multipage_Form) { $form->data( $Multipage_Form->data() ) }    # Get data from previous forms
                $form->configure( -grey => \%grey, -preset => \%preset, -include => \%include, -fk_extra => \%fk_extra, -skip => \%skip );
                $form->generate();
            }

            return "form";
        }

        #$testing=1;
        #Other forms ### - Wrap inside transaction
        if ( !$Transaction ) {
            $Transaction = SDB::Transaction->new( -dbc => $dbc );
            $Transaction->start();
        }
        elsif ( !$Transaction->started() ) {
            $Transaction->start();
        }

        #	$dbh = $Transaction->dbh();
        if ($dbc) {
            $dbc->transaction($Transaction);
        }

        $Transaction->message("updating $table ($returnval)");

        my $add_source_id = param('Add Plate Source_ID');
        eval {
            if ( $table eq 'GelRun' )
            {

                my $found = &alDente::Info::GoHome( $dbc, $table, $returnval );
                return 1;
            }
            elsif ( $table eq 'Rack' ) {

                # Generate Rack_Name,Rack_Alias,FKParent_Rack__ID for new rack if necessary
                my $ok = &alDente::Rack::Update_Rack_Info( -dbc => $dbc, -rack_id => $returnval );
                unless ($ok) { print "Error updating the Rack table after record creation<BR>" }
            }
            elsif ( $table eq 'Clone_Source' ) {
                _update_clone_source( -dbc => $dbc, -new_ids => $returnval );
            }
            elsif ( $table eq 'PoolSample' && param('DBUpdate') =~ /Finish/i ) {

                # See if we need to print the barcode for the library container
                my $poolsample_id = $returnval;
                my ($source_id) = $dbc->Table_find( 'Transposon_Pool,PoolSample', 'FK_Source__ID', "WHERE Transposon_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND PoolSample_ID=$poolsample_id" );
                if ($source_id) { &alDente::Barcoding::PrintBarcode( $dbc, 'Source', $source_id ) }
            }
            elsif ( $table eq 'UseCase_Step' ) {
                &alDente::UseCase::view_case( -dbc => $dbc, -step_id => $returnval, -table => $table );
            }
            elsif ( $table eq 'UseCase' ) {
                &alDente::UseCase::view_case( -dbc => $dbc, -case_id => $returnval, -table => $table );
            }
            elsif ( $mode eq 'Normal' ) {    # If mode is 'Normal', that means it is a single form and so update is done and so the home info page
                my $found = &alDente::Info::GoHome( $dbc, $table, $returnval );
                return $found;
            }
        };

        if ( $Transaction && $Transaction->started() ) {
            $Transaction->finish($@);
        }

        if ( $Transaction->error() ) {
            return 'error';
        }
        else {

            # Print all the pending messages
            foreach my $message ( @{ $Transaction->messages() } ) {
                $dbc->message( $message, -priority => 2 );
            }

            # Print barcodes as necessary
            my %newids = %{ $Transaction->newids() };

            foreach my $table ( sort keys %newids ) {
                foreach my $newid ( @{ $newids{$table} } ) {
                    if ( $newid && defined $Prefix{$table} ) {
                        &alDente::Barcoding::PrintBarcode( $dbc, $table, $newid );
                    }
                }
            }

            # See if we need to display a home page
            if ($home_barcode) {
                &alDente::Info::info( $dbc, $home_barcode );
                return 1;
            }

            # if a form has finished, then redirect to homepage if necessary
            # if the finished form is a submission, then just return
            if ( ( param('DBUpdate') =~ /Finish/i ) && ( param('Target') eq 'Database' ) ) {

                # check if which sequencing library was created for this original source and go to the original source home page
                my @HomePage = ( 'SAGE_Library', 'Mapping_Library' );
                if ( grep( /$table/, @HomePage ) ) {
                    my $tables = 'Library,Vector_Based_Library,' . $table;
                    my ($original_source_id) = $dbc->Table_find( $tables, 'FK_Original_Source__ID', "where FK_Vector_Based_Library__ID=Vector_Based_Library_ID AND FK_Library__Name=Library_Name AND $table" . "_ID in ($returnval)" );
                    &alDente::Info::GoHome( $dbc, 'Original_Source', $original_source_id );
                }

                # check to see if we need to go to the homepage after creating
                # This applies to Original_Source and endpoints of Source
                my @GoToHome = ( 'Original_Source', 'ReArray_Plate', 'Ligation', 'Microtiter', 'Xformed_Cells' );
                if ( grep( /$table/, @GoToHome ) ) {
                    if ( $table eq 'Original_Source' ) {
                        &alDente::Info::GoHome( $dbc, $table, $returnval );
                    }
                    else {
                        my ($source_id) = $dbc->Table_find( $table, "FK_Source__ID", "WHERE ${table}_ID in ($returnval)" );
                        &alDente::Info::GoHome( $dbc, 'Source', $source_id );
                    }
                }
                return "form";
            }
            ### <CONSTRUCTION> - Reza's change to update field with popup list...
            if ( param('tmpwin') ) {
                my $table = param('Update_Table');
                my $field = param('tmpwin');
                my $value = get_FK_info( $dbc, $field, $returnval );

                print CGI::button( -value => 'Close', -onClick => "opener.document.AutoForm.$field.value='$value';window.close();" );
                &main::leave();
            }
        }

        return 0;    ### skip to end...
    }
    return 0;
}

#################################
# Add custom configs for DB_Form
#################################
sub DB_Form_Custom_Configs {
#################################

    my %args      = @_;
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $form      = $args{-form};
    my $append_to = $args{-append_to};

    my %configs;
    if ($append_to) { %configs = %$append_to }

    # Configs for FK_Grp__ID
    if ( $Current_Department eq 'Receiving' ) {    # Default it to the sequencing lab group
        my ($grp) = $dbc->Table_find( "Grp", "Grp_ID", "WHERE Grp_Name = 'Cap_Seq Production'" );
        $configs{preset}{FK_Grp__ID} = $grp;
    }
    else {                                         # Default to the lab group of the current department

        #	my @groups = @{$dbc->Security->get_groups(-department_name=>$Current_Department,-return=>'fk_view')};
        my @groups;
        my $local_groups = $dbc->get_local('groups');
        if ($local_groups) {
            @groups = @{ $dbc->get_local('groups') };
        }

        #
        my $def_group;
        foreach my $group (@groups) {
            if ( $group =~ /\blab\b/i ) {
                $def_group = $group;
                last;
            }
        }
        $configs{list}{FK_Grp__ID}   = \@groups;
        $configs{preset}{FK_Grp__ID} = $def_group;
    }

    # Customizations based for particular forms
    my $table;
    if ( param('New Entry') ) { ($table) = param('New Entry') =~ /New (.*)/; }
    elsif ( param('New Entry Table') ) { $table = param('New Entry Table'); }
    elsif ( param('DBAppend') )        { $table = param('DBAppend') }

    if ($table) {
        if ( $table eq 'Rack' ) {
            $configs{grey}{Rack_Alias} = '(TBD)';
        }
        elsif ( $table eq 'Clone_Source' ) {
            if ( param('Plate_ID') ) {    # Grey out Plate ID if already provided
                $configs{grey}{FK_Plate__ID} = param('Plate_ID');
            }

            # Short list organization list to those that are collaborators

            my @collaborators = &get_FK_info( $dbc, 'FK_Organization__ID', -condition => "WHERE Organization_Type = 'Collaborator' Order by Organization_Name", -list => 1 );
            $configs{list}{FKSource_Organization__ID} = \@collaborators;

            # Hide other unnecessary fields
            $configs{omit}{FK_Clone_Sample__ID} = 0;    # Temporary set to zero - will be changed afterwards
            $configs{omit}{Clone_Well}          = '';
            $configs{omit}{Clone_Quadrant}      = '';
            $configs{omit}{Well_384}            = '';
            $configs{omit}{Source_Name}         = '';
            $configs{omit}{Source_Comments}     = '';
            $configs{omit}{Source_Library_ID}   = '';
            $configs{omit}{Source_Library_Name} = '';
            $configs{omit}{Source_Row}          = '';
            $configs{omit}{Source_Col}          = '';
            $configs{omit}{Source_5Prime_Site}  = '';
            $configs{omit}{Source_3Prime_Site}  = '';
            $configs{omit}{FK_Clone__ID}        = '';
            $configs{omit}{Source_Vector}       = '';
            $configs{omit}{Source_Score}        = '';
        }
        elsif ( $table eq 'Original_Source' ) {
            $configs{grey}{Source_Number}       = '(TBD)';
            $configs{omit}{FKParent_Source__ID} = 0;
        }
        elsif ( $table eq 'Source' ) {
            $configs{grey}{Source_Number}       = '(TBD)';
            $configs{omit}{FKParent_Source__ID} = 0;

            # Short list organization list to those that are collaborators
            my @barcodes = &get_FK_info( $dbc, 'FK_Barcode_Label__ID', -condition => "WHERE Label_Descriptive_Name like '% Source %'", -list => 1 );
            $configs{list}{FK_Barcode_Label__ID} = \@barcodes;
        }
    }

    if ($form) {
        my $prev_table = $form->curr_table();    ## Note that at this point the table referred to is actually the table from the previous form

        #	if ( ($prev_table eq 'Plate') || ($prev_table eq 'Tube') ) {
        #	    $configs{include}{DBRepeat} = param('DBRepeat') || 1;  # Make sure we are taking care of the repeat for the following form as well
        #	}

        unless ( $prev_table eq 'LibraryStudy' ) {

            # FK_Library__Name configs
            if ( param('FK_Library__Name') ) {
                $configs{grey}{FK_Library__Name} = param('FK_Library__Name');
            }
        }
    }

    return \%configs;
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

$Id: Special_Branches.pm,v 1.122 2004/12/07 19:26:26 mariol Exp $ (Release: $Name:  $)

=cut

return 1;
