################################################################################
#
# Validation.pmet
#
# This provides input/output checking procedures for Sequencing Database
#
# It may be customized for specific applications...
#
#
################################################################################
################################################################################
# $Id: Validation.pm,v 1.23 2004/08/27 17:58:01 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.23 $
#     CVS Date: $Date: 2004/08/27 17:58:01 $
################################################################################
package alDente::Validation;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Validation.pm - Validation.pmet

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Validation.pmet<BR>This provides input/output checking procedures for Sequencing Database<BR>It may be customized for specific applications... <BR>

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
    Validate_Form_Info
    get_aldente_id
    run_validation_tests
);
@EXPORT_OK = qw(
    Validate_Form_Info
    get_aldente_id
    run_validation_tests
);

##############################
# standard_modules_ref       #
##############################

use strict;

use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;

use SDB::DBIO;
use SDB::CustomSettings;
use alDente::Tools;
use LampLite::CGI;

my $q = new LampLite::CGI;

##############################
# global_vars                #
##############################
use vars qw(%Primary_fields %Mandatory_fields);
use vars qw($user );
use vars qw($testing);
use vars qw($scanner_mode);

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

#
# Accessor to support legacy call to method moved to separate module
#
# 
######################
sub get_aldente_id {
######################
    eval "require alDente::Data_Validation";
    return alDente::Data_Validation::get_aldente_id(@_);
}

############################
sub Validate_Form_Info {
############################
    #
    # Check info PRIOR to updating via DB_Form_Viewer module
    #
    # look for 'Update Table' or 'Append Table' entries first...
    #
    #
    my $dbc       = shift;
    my $thistable = shift;
    my $input     = shift;

    my %Input;
    if ($input) { %Input = %{$input} }
    ### Delete null values from input... ###
    foreach my $key ( keys %Input ) {

        #	if ($key =~/^[\w\.]+$/) {  ## avoid deleting internal references if applicable ##
        ## delete keys which have no value
        unless ( length( $Input{$key} ) > 0 ) {
            delete $Input{$key};      ## delete copy (unnecessary)
            delete $input->{$key};    ## delete original
        }

        #	}
    }

    my $fail = 1;                     ## see if there are any problems...
    my @msgs;

    if ( $q->param('Update Table') =~ /Update (.*) Table/i ) {
        my $table = $1 || $thistable;
        return $fail;
    }
    elsif ( $q->param('DBForm') ) {
        ##### This works for the newer forms included in DBinput.pm ##########

        my $table_list = $q->param('Allowed_Tables');
        my @temp_tables = split ',', $table_list;

        # remove blank entries
        my @tables = ();
        foreach (@temp_tables) {
            if ($_) {
                push( @tables, $_ );
            }
        }
        @tables = @{ unique_items( \@tables ) };
        foreach my $table (@tables) {

            # my $table = $q->param('DBForm');
            my $DBtables  = "DBField,DBTable";
            my $condition = "FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$table' AND Field_Options NOT LIKE '%Hidden%'";
            my $order     = "ORDER BY Field_Order";

            my %Validation = &Table_retrieve( $dbc, $DBtables, [ 'Field_Format', 'Field_Name', 'Field_Options' ], "where $condition AND (Length(Field_Format) > 0 OR Length(Field_Options) > 0)" );
            my $checks = $#{ $Validation{Field_Name} };

            #Query for a list of fields to be skipped.
            my @skip_array = $q->param('Skip');

            my $skip_list = join( ',', @skip_array );
            my %skip;
            if ($skip_list) {
                foreach my $field ( split /,/, $skip_list ) {
                    $skip{$field} = 1;
                }
            }

            ### add dynamically specified required fields if applicable ####
            if ( $q->param('Require') ) {
                my $required_list = join ',', $q->param('Require');
                my @required = split ',', $required_list;
                foreach my $needed (@required) {
                    $Validation{Field_Name}[$checks]    = $needed;
                    $Validation{Field_Options}[$checks] = 'Mandatory';
                    $checks++;
                }
            }

            $fail = 0;
            if    ($fail)         { return $fail; }
            elsif ( $checks < 0 ) { return 0; }

            foreach my $check ( 0 .. $checks ) {
                my $field   = $Validation{Field_Name}[$check];
                my $format  = $Validation{Field_Format}[$check];
                my $options = $Validation{Field_Options}[$check];

                my $value = Extract_Values(
                    [ $q->param($field), $q->param( $field . '_SearchString' ), $q->param("$field Choice"), $Input{$field}, $q->param("$table.$field"), $q->param( "$table.$field" . '_SearchString' ), $q->param("$table.$field Choice"), $Input{"$table.$field"} ] );

                if ( exists $skip{$field} ) {

                    #Skip the validation because the field is skipped.
                    next;
                }

                # Format validation already handled with javascript
                #
                #		if ($format) {      ### Format Validation
                #		    if (my ($rtable,$rfield) = foreign_key_check($field)) {#
                #			$value = get_FK_ID($dbc,$field,$value);
                #		    }
                #		    unless ($value =~ /$format/) { #
                #			push(@msgs,"DBField_Error:$field should be $format ('$value' invalid)");
                #			$fail = 1;
                #		    }
                #		}
                if ($options) {
                    ### Mandatory Validation..
                    # override mandatory field check if it's an FK value and the FK table is in the table list
                    my $override = 0;
                    my ($fktable) = $dbc->foreign_key_check($field);

                    if ( $fktable && grep( /^\b$fktable\b$/, @tables ) ) {
                        $override = 1;
                    }
                    if ( ( !defined $value ) && ( $options =~ /Mandatory/i ) && !$override ) {
                        push( @msgs, "DBField_Error:$field is mandatory" );
                        $fail = 1;
                    }
                    if ( $options =~ /Unique/i ) {
                        my $preset_value = $q->param("Preset:$field");

                        #If the user is not changing the original preset value,then we skip the uniqueness validation.
                        unless ( ( defined $preset_value ) && ( $preset_value eq $value ) ) {
                            my ($count) = $dbc->Table_find( $table, 'count(*)', "where $field='$value'" );
                            unless ( $count == 0 ) {
                                push( @msgs, "DBField_Error:$field should be unique" );
                                $fail = 1;
                            }
                        }
                    }
                }
            }

            #### Custom Validation requirements for DBinput module (generate_form) ########

            if ( $table eq 'Stock' and $q->param('Stock_Type') =~ /Reagent|Solution/ ) {
                ### require rack...
                my $rack = $q->param('FK_Rack__ID Choice') || $q->param('FK_Rack__ID');
                unless ( $rack =~ /[1-9]/ ) {
                    push( @msgs, "Form Error: You MUST enter Rack Location for Reagents" );
                    $fail = 1;
                }
            }
            elsif ( $table eq 'Stock' and $q->param('Stock_Type') =~ /Box/ ) {

            }
            elsif ( $table eq 'Stock' and $q->param('Stock_Type') =~ /Equipment/ ) {
                my $model  = $q->param('Model');
                my $serial = $q->param('Serial_Number');
                my $alias  = $q->param('Equipment_Name');
                my $number = $q->param('Stock_Number_in_Batch');
                my $type   = $q->param('Equipment_Type');

                if ( $model && $serial && $alias ) {
                    my $models  = int( my @list1 = split ',', $model );
                    my $serials = int( my @list2 = split ',', $serial );
                    my $aliases = int( my @list3 = split ',', $alias );

                    unless ( ( $models == $number ) || ( $models == 1 ) ) {
                        push( @msgs, "Please enter either 1 (if all the same) or $number Model Names" );
                        $fail = 1;
                    }
                    unless ( ( $serials == $number ) || ( $serials == 1 ) ) {
                        push( @msgs, "Please enter either 1 (if all the same) or $number Serial Numbers" );
                        $fail = 1;
                    }
                    if ( $aliases == $number ) {
                        my $condition = "WHERE Equipment_Name in ('$alias')";
                        $condition =~ s/,/\',\'/g;

                        my ($found) = $dbc->Table_find( 'Equipment', 'count(*)', $condition );
                        my $repeats = join ',', $dbc->Table_find( 'Equipment', 'Equipment_Name', $condition );

                        if ( $found > 0 ) {
                            push( @msgs, "$repeats NOT unique Aliases" );
                            $fail = 1;
                        }

                        my @list = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
                            'Equipment_Name', "where Category like '$type' AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID" );

                    }
                    else {
                        push( @msgs, "Please enter $number unique Aliases" );
                        $fail = 1;
                    }
                }
                else {
                    push( @msgs, "Please enter Model Name(s), Serial Number(s), and Aliases for each unit" );
                    $fail = 1;
                }

                unless ( $q->param('Equipment_Type') ) {
                    push( @msgs, "Please specify Equipment Type (often same as name) " );
                    $fail = 1;
                }
            }
            elsif ( $table eq 'Rack' ) {
                my $equip     = $q->param('FK_Equipment__ID');
                my $parent    = $q->param('FKParent_Rack__ID');
                my $condition = $q->param('Equipment_Condition');

                if ($parent) {
                    my $eid = get_FK_ID( $dbc, 'FK_Equipment__ID', $equip );
                    my $pid = get_FK_ID( $dbc, 'FK_Rack__ID',      $parent );

                    # Make sure the parent rack is in the same equipment and conditions
                    my ($count) = $dbc->Table_find( 'Rack,Equipment,Stock,Stock_Catalog,Equipment_Category', 'Count(*)',
                        "WHERE Rack_ID = $pid AND FK_Equipment__ID = $eid AND Sub_Category = '$condition' AND FK_Equipment__ID=Equipment_ID AND FK_Stock__ID=Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID"
                    );
                    unless ( $count > 0 ) {
                        push( @msgs, "The new rack and the parent rack must both in the same equipment and have the same conditions." );
                        $fail = 1;
                    }
                }
            }
        }
        my $message;
        if (@msgs) { $message = join "<BR>", @msgs }

        return $message;
    }
    return "Improper parameters for updating ?";
}


##########################################
#   Description:
#           Function to run validation test
#   Input:
#
#   Output:
#       1 on success 0 on failure
#   Details:
#       1- unit test
#       2- unit test (selenium)
#       3- compare_DB (following a full installation from Core_[Verision])
#       4- install_integrity
#
#
#
# <snip>
#  Example:
#
#
# </snip>
#
########################
sub run_validation_tests {
########################
    my %args       = &filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $output_dir = $args{-output_dir};                           # If provided then out put of scripts will be saved there
    my $mode       = $args{-mode} || 'All';
    my $compare_db = $args{-compare_db} || 'limsdev04:GSC_beta';
    my $test_stage = $args{-stage} || 'Commit';                    # Commit, Tag, Update, or Hotfix
    my $module     = $args{-module};                               # e.g. Box,Run
    my $revision   = $args{-revision};                             #svn tag revision
    my $debug      = $args{-debug} || 0;

    my $root = $dbc->config('versions_web_dir') . '/' . $dbc->config('root_directory');

    my $Report;
    my $html_report;
    my $variation;
    my $not_logging = 1;
    if ( $test_stage =~ /Tag|Update|Hotfix/ ) {
        $not_logging = 0;
        $variation   = $test_stage . "_" . $revision;
        my $html_file = "Validation_" . $variation . ".html";
        $Report = Process_Monitor->new( -title => "Validation", -variation => $variation, -quiet => 1 );
        $html_report = "$root/bin/Cron_Summary.pl -variation *$variation -out_file $output_dir/$html_file -copy_dir $output_dir -offset 0d";
    }

    my $out_file;
    if ($output_dir) {
        my $file = ">$output_dir/validation_tests.log";
        if ($test_stage) { $file = ">$output_dir/validation_tests.$test_stage.log"; }
        open $out_file, $file;
    }

    # run tests
    # 1. run unit test
    my $tests;
    if ( $module && $test_stage eq 'Commit' ) { $tests = "-test $module"; }
    my $unit_test_variation = "no_selenium_" . $variation;
    my $unit_test           = "$root/bin/run_unit_tests.pl -no_selenium 1 -testing $not_logging -variation $unit_test_variation $tests";
    my $unit_test_result;

    if ( $mode eq 'All' || $mode eq 'Code' ) {
        $unit_test_result = "Running unit test\n";
        print $unit_test_result;
        $unit_test_result .= try_system_command("$unit_test");
        my $msg;
        my $error;
        if ( $unit_test_result =~ /Looks like you failed|Looks like your test died/ ) {
            $msg   = "Failed unit test\n";
            $error = 1;
        }
        else {
            $msg = "Passed unit test\n";
        }
        print $msg;
        if ($output_dir) { print $out_file "$unit_test_result"; }
        if ($Report) {
            if   ($error) { $Report->set_Error("$msg"); }
            else          { $Report->set_Message("$msg"); }
            $Report->set_Detail("$unit_test_result");
        }
        if ( $error && !$debug ) {
            if ($out_file)    { close($out_file); }
            if ($Report)      { $Report->completed(); $Report->DESTROY(); }
            if ($html_report) { try_system_command("$html_report"); }
            return 0;
        }
    }

    # 2. run unit test selenium
    my $selenium_variation = "selenium_only_" . $variation;
    my $selenium           = "$root/bin/run_unit_tests.pl -test OS_S_Library -testing $not_logging -variation $selenium_variation";
    my $selenium_result;

    if ( ( $mode eq 'All' || $mode eq 'Code' ) && $test_stage ne 'Commit' ) {
        $selenium_result = "Running selenium unit test\n";
        print $selenium_result;
        $selenium_result .= try_system_command("$selenium");
        my $msg;
        my $error;
        if ( $selenium_result =~ /Looks like you failed|Looks like your test died|died!/ ) {
            $msg   = "Failed unit test selenium\n";
            $error = 1;
        }
        else {
            $msg = "Passed selenium test\n";
        }
        print $msg;
        if ($output_dir) { print $out_file "$selenium_result"; }
        if ($Report) {
            if   ($error) { $Report->set_Error("$msg"); }
            else          { $Report->set_Message("$msg"); }
            $Report->set_Detail("$selenium_result");
        }
        if ( $error && !$debug ) {
            if ($out_file)    { close($out_file); }
            if ($Report)      { $Report->completed(); $Report->DESTROY(); }
            if ($html_report) { try_system_command("$html_report"); }
            return 0;
        }
    }

    # 3. run compare_db test
    my $db_host  = $dbc->{host};
    my $db_dbase = $dbc->{dbase};

    #<CONSTRUCTION> Need to figure out which database to compare to
    my $compare_db = "$root/bin/compare_DB.pl -dbase1 $db_host:$db_dbase -dbase2 $compare_db -user super_cron_user -testing $not_logging -v $variation";
    my $compare_db_result;

    if ( ( $mode eq 'All' || $mode eq 'Patch' ) && $test_stage ne 'Commit' ) {
        $compare_db_result = "Running compare_db\n";
        print $compare_db_result;
        $compare_db_result .= try_system_command("$compare_db");
        my $compare_db_errors   = -1;
        my $compare_db_warnings = -1;
        if ( $compare_db_result =~ /compare_DB number of errors: (\d+), compare_DB number of warnings: (\d+)/ ) {
            $compare_db_errors   = $1;
            $compare_db_warnings = $2;
        }
        my $msg;
        my $error;
        if ( $compare_db_errors != 0 || $compare_db_warnings != 0 ) {
            $msg   = "Failed compare db test\n";
            $error = 1;
        }
        else {
            $msg = "Passed compare db test\n";
        }
        print $msg;
        if ($output_dir) { print $out_file "$compare_db_result"; }
        if ($Report) {
            if   ($error) { $Report->set_Error("$msg"); }
            else          { $Report->set_Message("$msg"); }
            $Report->set_Detail("$compare_db_result");
        }
        if ( $error && !$debug ) {
            if ($out_file)    { close($out_file); }
            if ($Report)      { $Report->completed(); $Report->DESTROY(); }
            if ($html_report) { try_system_command("$html_report"); }
            return 0;
        }
    }

    # 4. run install_integrity
    my $install_integrity_result;

    if ( ( $mode eq 'All' || $mode eq 'Patch' ) && $test_stage ne 'Commit' ) {
        $install_integrity_result = "Running install_integrity\n";
        print $install_integrity_result;
        my $tmp_install_integrity_result = check_installation_integrity( -dbase => "$db_host:$db_dbase", -testing => $not_logging, -variation => $variation );
        my $msg;
        my $error;
        if ( $tmp_install_integrity_result =~ /\w+/ ) {
            $install_integrity_result .= $tmp_install_integrity_result;
            $msg   = "Failed install integrity test\n";
            $error = 1;
        }
        else {
            $msg = "Passed install integrity test\n";
            $install_integrity_result .= "Passed intall_integrity test";
        }
        print $msg;
        if ($output_dir) { print $out_file "$install_integrity_result"; }
        if ($Report) {
            if   ($error) { $Report->set_Error("$msg"); }
            else          { $Report->set_Message("$msg"); }
            $Report->set_Detail("$install_integrity_result");
        }
        if ( $error && !$debug ) {
            if ($out_file)    { close($out_file); }
            if ($Report)      { $Report->completed(); $Report->DESTROY(); }
            if ($html_report) { try_system_command("$html_report"); }
            return 0;
        }
    }

    #Pass all test
    if ($Report) {
        $Report->completed();
        $Report->DESTROY();
    }

    if ($html_report) { try_system_command("$html_report"); }

    return 1;
}

##############################
# private_methods            #
##############################

####################################
sub check_installation_integrity {
####################################
    my %args      = filter_input( \@_ );
    my $dbase     = $args{-dbase};
    my $debug     = $args{-debug};          # debug flag
    my $testing   = $args{-testing} || 0;
    my $variation = $args{-variation};
    my $login_file = $args{-login_file};
    my $config     = $args{-config};
    my $user = $args{-user};

## REPORT ###
    my $report_variation = 'Integrity_' . $dbase;
    $report_variation .= "_$variation" if $variation;
    my $Report = Process_Monitor->new( -variation => $report_variation, -testing => $testing, -configs=>$config);

    my ( $host, $database ) = split ':', $dbase;

    my $dbc  = new SDB::DBIO( -host => $host, -dbase => $database, -user => $user, -login_file => $login_file, -connect => 1, -config=>$config);
#    my $dbc = SDB::DBIO->new( -host => $source_host, -dbase => $source_db, -user => $user, -login_file=>$login_file, -connect => 1, -config=>$Config->{config});

    check_VT_integrity( -dbc => $dbc, -debug => $debug, -report => $Report );
    check_package_integrity( -dbc => $dbc, -debug => $debug, -report => $Report );
    check_installation_errors( -dbc => $dbc, -debug => $debug, -report => $Report );
    my $errors   = $Report->get_Errors();
    my $warnings = $Report->get_Warnings();
    my @messages = ( @{$errors}, @{$warnings} );
    my $message  = join( "\n", @messages );
    $Report->completed();
    $Report->DESTROY();

    return $message;
}

####################################
sub check_VT_integrity {
####################################
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $debug  = $args{-debug};         # debug flag
    my $Report = $args{-report};

    my %vt_patches = _get_vt_patch_hash( -report => $Report, -dbc => $dbc, -debug => $debug );
    my %db_patches = _get_db_patch_hash( -report => $Report, -dbc => $dbc, -debug => $debug );

    for my $patch ( keys %db_patches ) {

        if ( !$vt_patches{$patch}{package} || !$vt_patches{$patch}{number} ) {
            $Report->set_Error("$patch is missing from version tracker file!");
        }
        elsif ( $vt_patches{$patch}{package} ne $db_patches{$patch}{package} ) {
            $Report->set_Warning("For patch $patch database package does not match version tracker package ($vt_patches{$patch}{package} <> $db_patches{$patch}{package})");
        }
        elsif ( $vt_patches{$patch}{number} ne $db_patches{$patch}{number} ) {
            $Report->set_Warning("Patch version is inconsistant  for $patch ($vt_patches{$patch}{number} <> $db_patches{$patch}{number})");
        }
    }
    return;
}

####################################
sub _get_db_patch_hash {
####################################
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $debug  = $args{-debug};         # debug flag
    my $Report = $args{-report};
    my %patches;
    my @results = $dbc->Table_find( 'Patch,Package', 'Patch_Name,Package_Name,Patch_Version', "WHERE FK_Package__ID= Package_ID and  Install_Status LIKE 'Installed%'" );
    for my $line (@results) {
        my ( $name, $package, $number ) = split ",", $line;
        $patches{$name}{package} = $package;
        $patches{$name}{number}  = $number;
    }
    return %patches;

}

####################################
sub _get_vt_patch_hash {
####################################
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $debug  = $args{-debug};         # debug flag
    my $Report = $args{-report};
    my %patches;
    my $install = new SDB::Installation( -dbc => $dbc, -simple => 1 );
    my $files = $install->get_Version_Tracker_Files( -report => $Report, -dbc => $dbc, -debug => $debug );

    for my $vt_file (@$files) {
        open( VERSION_CONTROL, "<$vt_file " ) or die "Could not open version control file for read: $vt_file ";
        my @lines = <VERSION_CONTROL>;
        close VERSION_CONTROL;
        for my $line (@lines) {
            chomp $line;
            my ( $number, $name, $package ) = split "\t", $line;
            $patches{$name}{package} = $package;
            $patches{$name}{number}  = $number;
        }
    }
    return %patches;
}

####################################
sub check_package_integrity {
####################################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $debug   = $args{-debug};                                                                                                                                                                        # debug flag
    my $Report  = $args{-report};
    my @results = $dbc->Table_find( 'Patch,Package', 'Patch_Name,Package_Name', "WHERE FK_Package__ID= Package_ID and  Install_Status LIKE 'Installed%' and Package_Install_Status <> 'Installed'" );
    for my $line (@results) {
        my ( $patch, $package ) = split ',', $line;
        $Report->set_Warning("Patch $patch is installed without it's Package being installed");
    }
    return;
}

####################################
sub check_installation_errors {
####################################
    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc};
    my $debug         = $args{-debug};                                                                                 # debug flag
    my $Report        = $args{-report};
    my @error_patches = $dbc->Table_find( 'Patch', 'Patch_Name', "WHERE Install_Status = 'Installed with errors'" );
    for my $patch (@error_patches) {
        $Report->set_Warning("$patch has been installed but contains errors");
    }
    return;
}

################################
sub validate_move_object {
################################
    # Description:
    #   Validate objects before they can be moved.
    # Input:
    #   - dbc       	database connection
    #   - barcode       scanned barcode
    #   - objects       object types to validate, e.g. Plate,Solution
    #   - racks         destination racks
    # output:
    #   returns 1 on failure 0 on success
    # <snip>
    # 	my $failure = alDente::Validation::validate_move_object(-dbc => $dbc, -barcode => $barcode, -objects => $objects, -rack_id => $racks);
    # </snip>
################################
    my %args    = &filter_input( \@_, -args => 'dbc,barcode,objects', -mandatory => 'dbc,barcode,objects' );
    my $dbc     = $args{-dbc};
    my $barcode = $args{-barcode};
    my $objects = $args{-objects};
    my $debug   = $args{-debug};
    my $racks   = $args{-racks};

    ################
    # For solution
    ################
    if ( $objects =~ /Solution/xmsi ) {
        my $solutions = get_aldente_id( $dbc, $barcode, 'Solution' );
        if ( $solutions =~ /[1-9]/ ) {
            my @solution_status = $dbc->Table_find( 'Solution', 'Solution_Status', "WHERE Solution_ID IN ($solutions)", 'Distinct' );
            if ( grep /^Finished$/i, @solution_status ) {

                #Sess->message("Warning: Some of these solutions are marked as Finished and cannot be moved");
                #print end_form();
                return alDente::Solution::activate_Solution( -dbc => $dbc, -ids => $solutions, -rack_id => $racks );
                return 1;
            }
        }
    }

    ################
    # For plate
    ################
    if ( $objects =~ /Plate/xmsi ) {
        my $plates = get_aldente_id( $dbc, $barcode, 'Plate' );
        if ( $plates =~ /[1-9]/ ) {
            my @failed = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE Plate_ID IN ($plates) AND Failed = 'Yes'", 'Distinct' );
            if (@failed) {
                my %return;
                $return{'Failed'}{'Plate'} = \@failed;
                return \%return;
            }
        }
    }

    ################
    # For .......
    ################

    return 0;
}

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

$Id: Validation.pm,v 1.23 2004/08/27 17:58:01 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
