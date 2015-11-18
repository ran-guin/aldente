#!/usr/local/bin/perl

##############################################################33
#
#
#

use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/custom";
use Data::Dumper;
use SRA::ArchiveIO;
use Getopt::Long;
use SDB::DBIO;
use XML::Simple;
use vars qw($opt_help $opt_host $opt_dbase $opt_user $opt_password $opt_changelog $opt_errorlog $opt_timelog);
print "starting script\n";
&GetOptions(
    'help=s'          => \$opt_help,
    'host=s'          => \$opt_host,
    'dbase=s'         => \$opt_dbase,
    'user=s'          => \$opt_user,
    'password=s'      => \$opt_password,
    'errorlog_msg=s'  => \$opt_errorlog,
    'changelog_msg=s' => \$opt_changelog,
    'timelog=s'       => \$opt_timelog
);

my $start_time    = localtime();
my $help          = $opt_help;
my $host          = $opt_host;
my $dbase         = $opt_dbase;
my $user          = $opt_user;
my $pass          = $opt_password;
my $changelog     = $opt_changelog || '/home/jachan/workspace/Submissions/';
my $errorlog      = $opt_errorlog || '/home/jachan/workspace/Submissions/';
my $timelog       = $opt_timelog || '/home/jachan/workspace/Submissions/';
my @errorlog_msg  = ("Error log");
my @changelog_msg = ("Change log");

$errorlog  .= $start_time . "_errorlog.txt";
$changelog .= $start_time . "_changelog.txt";
$timelog   .= $start_time . "_timelog.txt";
$errorlog  =~ s/\s/\_/g;
$changelog =~ s/\s/\_/g;
$timelog   =~ s/\s/\_/g;

my %CGHub_to_Lims = SRA::ArchiveIO::cghub_lims_status();

#print Dumper \%CGHub_to_Lims;

if ($help) {
    _help();
    exit;
}

#print "making dbc\n";
my $dbc = new SDB::DBIO(
    -host     => $host  || "lims07",
    -dbase    => $dbase || "seqbeta",
    -user     => $user  || "manual_tester",
    -password => $pass  || "529.616654777985",
    -connect  => 1,
);

#print "made dbc, finding data\n";

my @id;
my @UI;
my @obj_status;
my @state;
my @centre;

my $index = 0;

if (1) {

    my $tables = 'Metadata_Object, Status as Obj_Status, Status as Sub_Status, Status as Analysis_Status, Metadata_Submission, Submission_Volume, Organization, Analysis_Link, Analysis_Submission';
    my @fields = [ 'Metadata_Object_ID', 'Metadata_Submission_ID', 'Analysis_Submission_ID', 'Unique_Identifier', 'Obj_Status.Status_Name as object_status', 'Sub_Status.Status_Name as submission_status', 'Analysis_Status.Status_Name as analysis_status',
        'Alias' ];

    my $condition = "WHERE Object_Type = 'Analysis' 
				   and Metadata_Object.FK_Status__ID = Obj_Status.Status_ID
				   and Metadata_Submission.FK_Status__ID = Sub_Status.Status_ID
				   and Submission_Volume.FK_Status__ID = Analysis_Status.Status_ID				   
				   and Metadata_Submission.FK_Metadata_Object__ID = Metadata_Object_ID
				   and Metadata_Submission.FK_Submission_Volume__ID = Submission_Volume_ID
				   and Submission_Volume.FK_Organization__ID = Organization_ID
				   and Organization_Name = 'cgHub'
				   and Analysis_Link.FKAnalysis_Metadata_Object__ID = Metadata_Object_ID
				   and Analysis_Submission.FK_Analysis_File__ID = Analysis_Link.FK_Analysis_File__ID
				   order by Metadata_Object_ID desc";

    my %LIMS_data = $dbc->Table_retrieve( $tables, @fields, "$condition", -debug => 0 );
    print "found data\n";

    #print Dumper \%LIMS_data;

    print("Accessing CGHub\n");

    my $total = scalar @{ $LIMS_data{Metadata_Object_ID} };

    open( MYOutFile1, ">>$changelog" );
    open( MYOutFile2, ">>$errorlog" );
    open( MYOutFile3, ">>$timelog" );
    print MYOutFile3 $start_time;
    print MYOutFile3 "\n";

    $index = 0;
    foreach my $obj_id ( @{ $LIMS_data{Metadata_Object_ID} } ) {

        my $state       = "";
        my $centre      = "";
        my $obj_status  = $LIMS_data{object_status}->[$index];
        my $sub_status  = $LIMS_data{submission_status}->[$index];
        my $anal_status = $LIMS_data{volume_status}->[$index];
        my $UI          = $LIMS_data{Unique_Identifier}->[$index];
        my $sub_ID      = $LIMS_data{Metadata_Submission_ID}->[$index];
        my $anal_ID     = $LIMS_data{Analysis_Submission_ID}->[$index];
        my $alias       = $LIMS_data{Alias}->[$index];
        print("\n$obj_id $alias $index / $total \n");

        #	print "$obj_id \t $UI \t $obj_status \t";
        if ( $UI ne 'undef' && $UI ) {
            my $CGHUB_raw  = SRA::ArchiveIO::download_cgHub_metadata( -analysis_id => $UI );
            my $xo         = new XML::Simple();
            my $CGHUB_data = $xo->XMLin("$CGHUB_raw");
            $state  = $CGHUB_data->{Result}{state};
            $centre = $CGHUB_data->{Result}{center_name};

            ####
            #	check metadata_object status with state
            ####
            if ($state) {
                ## if this UI is in CGHub DBase Do this

                unless ( $CGHub_to_Lims{$state} eq $obj_status ) {
                    ##########################################
                    print "\tsyncing object->$obj_status to $state\n";
                    ## if LIMS DB status is out of sync, update

                    my ($new_status_id) = $dbc->Table_find( "Status", "Status_ID", "Where Status_Name = '$CGHub_to_Lims{$state}' AND Status_Type = 'Submission'" );
                    $dbc->Table_update( "Metadata_Object", "FK_Status__ID", "$new_status_id", "Where Metadata_Object_ID = $obj_id" );
                    push @changelog_msg, "Metadata_Object_ID: $obj_id\t\tObject_Status changed from $obj_status to $state";
                    print MYOutFile1 "Metadata_Object_ID: $obj_id\t\tStatus changed from $obj_status to $state\n";
                }

                unless ( $sub_status eq 'Accepted' ) {
                    print "\tsyncing Submission->$sub_status to Accepted\n";
                    my ($new_status_id) = $dbc->Table_find( "Status", "Status_ID", "Where Status_Name = 'Accepted' AND Status_Type = 'Submission'" );
                    $dbc->Table_update( "Metadata_Submission", "FK_Status__ID", "$new_status_id", "Where Metadata_Submission_ID = $sub_ID" );
                    print MYOutFile1 "Metadata_Submission_ID: $sub_ID\t\tStatus changed from $sub_status to Accepted\n";

                }

                unless ( $anal_status eq 'Accepted' ) {
                    print "\tsyncing Analysis->$anal_status to Accepted\n";
                    my ($new_status_id) = $dbc->Table_find( "Status", "Status_ID", "Where Status_Name = 'Accepted' AND Status_Type = 'Submission'" );
                    $dbc->Table_update( "Analysis_Submission", "FK_Status__ID", "$new_status_id", "Where Analysis_Submission_ID = $anal_ID" );
                    print MYOutFile1 "Analysis_Submission: $anal_ID\t\tStatus changed from $anal_status to Accepted\n";

                }

            }
            else {
                ## report an error
                print("\tMissing CGHub entry\n");
                push @errorlog_msg, "Metadata_Object_ID:$obj_id\,UI:$UI\,Missing:CGHub_Entry";
                print MYOutFile2 "Metadata_Object_ID:$obj_id\,UI:$UI\,Missing:CGHub_Entry\n";
            }
        }
        else {
            print("\tMissing UI\n");
            push @errorlog_msg, "Metadata_Object_ID:$obj_id\,Missing:UI";
            print MYOutFile2 "Metadata_Object_ID:$obj_id\,Missing:UI\n";
        }

        $index++;
    }
}

close(MYOutFile1);
close(MYOutFile2);

my $time = localtime();
print MYOutFile3 $time;
close(MYOutFile3);

if (0) {

    my $info = SRA::ArchiveIO::download_cgHub_metadata( -analysis_id => '58deabbf-27b6-4059-875c-83831999a99c' );

    #my $info = SRA::ArchiveIO::download_cgHub_metadata( -center_name => 'BCCAGSC');

    my $xo        = new XML::Simple();
    my $xml_input = $xo->XMLin("$info");

    #print $info;
    print $xml_input->{Result}{state};
    my %info = %{$xml_input};

}

#######################
sub _help {
#######################
    print <<END;

     File:  cghub_diff.pl
     ###################
     Cross references LIMS and CGHub databases to check if all Lims submissions are in fact up to date. 
     
     Usage:
     ###################
     	cghub_diff.pl # no parametres will default to limsdev04 seqdev DB for testing
        cghub_diff.pl -user <viewer> -pass <viewer> -host <limsdev04> -dbase <seqdev>
	
END
    return;
}

