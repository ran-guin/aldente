###################################################################################################################################
# Branch.pm
#
# Class module that encapsulates Branch functionality
#
###################################################################################################################################
package alDente::Branch;

@ISA = qw(SDB::DB_Object);

use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;

### Reference to alDente modules
use alDente::SDB_Defaults;
use alDente::Barcoding;
use alDente::Notification;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Object;
use RGTools::Conversion;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;

use vars qw($Connection);

#################
sub new_Branch {
#################
    my %args = &filter_input( \@_ );
    my $type = $args{-type};

    my $filter_table = "Branch";
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my %list;
    my %grey;

    my $condition = 1;

    my $valid_form = SDB::DB_Form->new( -dbc => $dbc, -table => $filter_table, -target => 'Database' );

    if ( $type =~ /Primer/i ) {
        $grey{"FK_Object_Class__ID"} = 'Primer';
        my @list = $dbc->get_FK_info( 'FK_Primer__Name', -list => 1, -condition => "Primer_Type = 'Standard'" );
        $list{'Object_ID'} = \@list;
    }
    elsif ( $type =~ /Enzyme/i ) {
        $grey{"FK_Object_Class__ID"} = 'Enzyme';
        my @list = $dbc->get_FK_info( 'FK_Enzyme__Name', -list => 1 );
        $list{'Object_ID'} = \@list;
    }

    $valid_form->configure( -list => \%list, -grey => \%grey );

    return $valid_form->generate( -title => "Defining New Library Branch", -form => 'Defined Branch', -return_html => 1 );
}

###################################################
#
# Retrieves possible Branch Codes
#
#
########################
sub list_Branch_Codes {
########################
    my %args = &filter_input( \@_, -args => 'dbc' );

    my $dbc              = $args{-dbc};
    my $code             = $args{-code};
    my $class            = $args{-class};               ## branch on class (eg Primer, Enzyme, Antibiotic)
    my $extra_condition  = $args{-condition} || 1;
    my $library          = $args{-library};
    my $project          = $args{-project};
    my $library_sub_type = $args{-library_sub_type};    ## only valid of library_type also supplied
    my $library_type     = $args{-library_type};
    my $debug            = $args{-debug};

    my $user_groups = $dbc->get_local('group_list');
    my $tables      = "Branch,Branch_Condition,Object_Class,$class LEFT JOIN Pipeline ON Branch_Condition.FK_Pipeline__ID=Pipeline_ID AND (Pipeline.FK_Grp__ID IN ($user_groups) OR Pipeline.Pipeline_ID IS NULL)";
    my $condition   = "WHERE Branch_Condition.FK_Branch__Code=Branch_Code AND Branch_Condition.FK_Object_Class__ID=Object_Class_ID AND Branch_Condition.Object_ID = $class.$class" . "_ID AND Object_Class = '$class'";

    ## filter based upon project & library if applicable (ie only choose from suggested $class objects) ##
    my $lib_condition       = " AND FK_Project__ID=Project_ID";
    my $lib_extra_condition = '';
    my $lib_tables          = "Project,Library,LibraryApplication,$class,Object_Class";
    if ($project) {
        $lib_extra_condition .= " AND Project_Name = '$project'";
    }
    if ( $library_sub_type && $library_type ) {

        #$lib_tables .= ",$library_type";
        #$lib_extra_condition .= " AND $library_type.FK_Library__Name=Library_Name";
        $tables              .= " LEFT JOIN $library_type ON $library_type.FK_Library__Name=Library_Name";
        $lib_extra_condition .= " AND ($library_type" . "_Type = '$library_sub_type' OR Library_Type = '$library_sub_type')";
    }

    if ($library) {
        my $lib_list = Cast_List( -list => $library, -to => 'string', -autoquote => 1 );
        $lib_extra_condition .= " AND Library_Name IN ($lib_list)";
    }
    my $application_condition = "WHERE LibraryApplication.FK_Library__Name=Library_Name AND LibraryApplication.Object_ID=" . $class . "_ID AND LibraryApplication.FK_Object_Class__ID=Object_Class_ID AND Object_Class='$class'";
    my @object_ids = $dbc->Table_find( $lib_tables, $class . '_ID', "$application_condition $lib_condition $lib_extra_condition", -distinct => 1, -debug => $debug ) if $lib_extra_condition;

    if (@object_ids) {
        $extra_condition .= " AND Branch_Condition.Object_ID IN (";
        $extra_condition .= join ',', @object_ids;
        $extra_condition .= ")";
        Message( "Found " . int(@object_ids) . " valid $class options (@object_ids)" ) if ($debug);
    }
    ##

    if ($code) {

        #	$extra_condition .= " AND Chemistry_Code_Name LIKE '$code'";
        $extra_condition .= " AND Branch_Code LIKE '$code'";
    }

    my $admin = 0;
    if ( grep( /Admin/i, @{ $dbc->get_local('Access')->{$Current_Department} } ) ) {
        $admin = 1;
    }

    my $all    = param('Include All Chem_Codes');            ### allow viewing of unused chem_codes
    my $output = h1("Current Chemistry Codes For $class");
    ## Valid chem_codes ##

    #    if ($admin) {
    #	$output .= create_tree(-tree=>{"Define New $class Branch" => new_Branch(-type=>$class)},-print=>0);
    #    }

    $output .= $dbc->Table_retrieve_display(
        "$tables",
        [ 'Branch_Code', "${class}.${class}_Name AS $class",
            'Pipeline_Name', 'Branch_Condition.FKParent_Branch__Code as Parent_Branch' ],
        "$condition AND $extra_condition",
        -return_html => 1,
        -debug       => $debug
    );

    return $output;
}

###################################################
#
# When a new branch_condition was created, check to see if it will result in ambiguous branch target. If yes, return 0, else return 1.
#
#
########################
sub new_branch_condition_trigger {
########################
    my %args  = filter_input( \@_, -args => 'dbc,id' );
    my $dbc   = $args{-dbc};
    my $BC_ID = $args{-id};
    my $debug = 0;

    my ($BC_fields) = $dbc->Table_find( 'Branch_Condition', 'FK_Branch__Code,Object_ID,FK_Object_Class__ID,FK_Pipeline__ID,FKParent_Branch__Code', "WHERE Branch_Condition_ID = $BC_ID", -debug => $debug );
    my ( $BC_FK_Branch__Code, $BC_Object_ID, $BC_FK_Object_Class__ID, $BC_FK_Pipeline__ID, $BC_FKParent_Branch__Code ) = split( ',', $BC_fields );

    my $parent_branch_cond = "FKParent_Branch__Code = '$BC_FKParent_Branch__Code'";
    if ( !$BC_FKParent_Branch__Code ) { $parent_branch_cond = "($parent_branch_cond OR FKParent_Branch__Code IS NULL)"; }

    my @similar = $dbc->Table_find(
        'Branch_Condition', 'FK_Pipeline__ID',
        "WHERE Object_ID = '$BC_Object_ID' AND FK_Object_Class__ID = '$BC_FK_Object_Class__ID' AND $parent_branch_cond AND Branch_Condition_Status = 'Active' AND Branch_Condition_ID != $BC_ID",
        -debug => $debug
    );

    #print HTML_Dump \@similar;
    #print HTML_Dump $BC_FK_Pipeline__ID;
    my $not_ambiguous = 1;
    if ( $BC_FK_Pipeline__ID > 0 ) {
        for my $pipeline_ID (@similar) {
            if ( !$pipeline_ID ) { $not_ambiguous = 0; last; }
            if ( $pipeline_ID == $BC_FK_Pipeline__ID ) { $not_ambiguous = 0; last; }
        }
    }
    else {
        if (@similar) { $not_ambiguous = 0 }
    }

    if ( !$not_ambiguous ) {

        #delete branch condition and message user
        $dbc->error("Creating an ambiguous branch target, please contact LIMS Admins. Deleting branch $BC_FK_Branch__Code.");
        $dbc->delete_record( -table => 'Branch_Condition', -field => 'Branch_Condition_ID', -value => $BC_ID, -debug => $debug );
    }

    return $not_ambiguous;
}
