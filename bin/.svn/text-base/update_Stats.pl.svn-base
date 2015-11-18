#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

update_Stats.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard fatalsToBrowser);
use Benchmark;
use Date::Calc qw(Day_of_Week);
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use Statistics::Descriptive;
use Data::Dumper;

use Storable;

use SDB::DBIO;
use SDB::Report;
use SDB::CustomSettings;

use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Barcode;
use RGTools::Process_Monitor;

use alDente::Container;
use alDente::SDB_Defaults;
use alDente::Data_Images;
##############################
# custom_modules_ref
#############################
##############################
# global_vars                #
##############################
use vars qw($opt_S $opt_C $opt_D $opt_A $opt_d $opt_R $opt_N $opt_P $opt_Q $opt_q);
use vars qw($Machine_cap_rows $look_back $Web_log_directory $Stats_dir $URL_cache $testing $config_dir %Configs);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
require "getopts.pl";
&Getopts('SCADMNP:d:R:Qq');
unless ( $opt_S || $opt_C || $opt_D || $opt_A || $opt_d || $opt_N || $opt_P || $opt_R || $opt_Q || $opt_q ) {
    print <<HELP
USAGE:
sequence.pl (options)
Options:
********
    -A     updates all statistics
    -D     updates Diagnostics info
    -S     updates Statistics info
    -C     updates configuration info
    -M     updates monthly run info
HELP
}
my $Report = Process_Monitor->new();

my $username = try_system_command("whoami");
chomp $username;
my $log_file = "$Web_log_directory/update_Stats/update_Stats_" . &RGTools::RGIO::timestamp();
my $log      = '';
my $days     = Extract_Values( [ $opt_d, '' ] );
my $runs     = $opt_R || 0;
if ($runs) { $runs = extract_range($runs); print "Runs: $runs.\n"; }
my $default_dbase = "sequence";

my $dbase = $Configs{BACKUP_DATABASE};
my $host  = $Configs{BACKUP_HOST};

my $dbc = SDB::DBIO->new( -dbase => $dbase, -user => 'viewer', -password => 'viewer', -host => $host, -connect => 1 );
my $storage_dir = $Stats_dir;

### generate Q20 histograms - keep
if ($opt_Q) {

    ## standard histogram generation ##
    my $extra_condition = "Run_Test_Status = 'Production' AND Run_Status = 'Analyzed'";

    my $project_count = 0;
    foreach my $project ( $dbc->Table_find( 'Library,Plate,Run', 'FK_Project__ID', "WHERE FK_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name AND $extra_condition ORDER BY FK_Project__ID", -distinct => 1 ) ) {
        print "\n******************\nProject: $project\n******************\n";
        my $result = &alDente::Data_Images::generate_q20_histogram( -dbc => $dbc, -condition => "$extra_condition AND FK_Project__ID=$project", -file => "Projects/Q20Hist_Proj$project", -by_month => 1, -include_recent => 1 );
        if   ($result) { $Report->succeeded(); }
        else           { $Report->set_Error('Errors found while generating histograms for project.  Check /home/aldente/private/logs/update_Stats.err for details.'); }
        $project_count++;
    }
    my $equipment_count = 0;
    foreach my $equipment ( $dbc->Table_find( 'RunBatch,Run', 'FK_Equipment__ID', "WHERE FK_RunBatch__ID=RunBatch_ID AND $extra_condition AND FK_Equipment__ID IS NOT NULL ORDER BY FK_Equipment__ID", -distinct => 1 ) ) {

        print "Equipment: $equipment\n******************\n";
        my $result = &alDente::Data_Images::generate_q20_histogram( -dbc => $dbc, -condition => "$extra_condition AND FK_Equipment__ID=$equipment", -file => "Equipment/Q20Hist_Equ$equipment", -include_recent => 1 );
        if   ($result) { $Report->succeeded(); }
        else           { $Report->set_Error('Errors found while generating histograms for Equipment.  Check /home/aldente/private/logs/update_Stats.err for details.'); }
        $equipment_count++;
    }

    my $library_count = 0;
    foreach my $library ( $dbc->Table_find( 'Plate,Run', 'FK_Library__Name', "WHERE FK_Plate__ID=Plate_ID AND $extra_condition ORDER BY FK_Library__Name", -distinct => 1 ) ) {
        print "Library: $library\n******************\n";
        my $result = &alDente::Data_Images::generate_q20_histogram( -dbc => $dbc, -condition => "$extra_condition AND FK_Library__Name='$library'", -file => "Library/Q20Hist_Lib$library", -include_recent => 1 );
        if   ($result) { $Report->succeeded(); }
        else           { $Report->set_Error('Errors found while generating histograms for Library.  Check /home/aldente/private/logs/update_Stats.err for details.'); }
        $library_count++;
    }

    $Report->set_Message("Total projects: $project_count");
    $Report->set_Message("Total equipment: $equipment_count");
    $Report->set_Message("Total libraries/collections: $library_count");

    print "Combined Totals:\n******************\n";
    &alDente::Data_Images::generate_q20_histogram( -dbc => $dbc, -condition => $extra_condition, -file => "All/Q20Hist", -by_month => 1, -include_recent => 1 );

}

### Backs up the files - modified to back up only Parameters
my $store_parameters = 1;
if ($store_parameters) {

    my %StoreParams = %{ &alDente::Tools::initialize_parameters( $dbc, 'sequence' ) };

    print "**** Regenerated Basic Parameters ****\n";
    &store( \%StoreParams, "$storage_dir/Params" );
    print "set:\n*****\n";
    my @keys = keys %StoreParams;
    print join "\n", @keys;
    print "\n*****\n\n";

    my $today = &RGTools::RGIO::datestamp();

    #my @Files_saved = ('Params','Statistics','All_Statistics','ChemistryInfo','Diagnostics','Total_Statistics','Project_Stats','Test_Stats','All_Stats','Production_Stats','Run_Statistics','Last24Hours_Statistics');
    my @Files_saved = ('Params');
    foreach my $file (@Files_saved) {
        print "** Backup $file ** ...\n";
        print try_system_command("cp -fR $storage_dir/$file $storage_dir/backups/$file/$file.$today");
    }
}

### connect to default_database (not sure why , but it was here... )
unless ( $default_dbase == $dbase ) {
    $dbc->disconnect();
    $dbc = SDB::DBIO->new( -dbase => $default_dbase, -user => 'viewer', -password => 'viewer', -host => $host, -connect => 1 );
}

unless ( $opt_S || $opt_C || $opt_D || $opt_A || $opt_d || $opt_N || $opt_P || $runs || $days ) {
    exit;
}

### Chemistry Statistics - keep
if ( $opt_C || $opt_A ) {
    my %Chem = {};
    $log .= "**************** Chemistry Statistics ******************\n";
    my $Chemistry = {};
    my $Primer    = {};
    my $status_h  = {};

    #my @chemcodes = $dbc->Table_find( 'Chemistry_Code', 'Chemistry_Code_Name,FK_Primer__Name,Terminator', undef, 'Distinct' );
    my @chemcodes = $dbc->Table_find( 'Branch_Condition,Object_Class', 'FK_Branch__Code,Object_ID,Object_Class,Branch_Condition_Status', 'WHERE FK_Object_Class__ID = Object_Class_ID', 'Distinct' );
    my $cc_count;
    my $active_count;
    foreach my $cc (@chemcodes) {

        #( my $code, my $primer, my $term ) = split ',', $cc;
        ( my $code, my $object_id, my $object_class, my $status ) = split ',', $cc;
        $Chemistry->{$code} = $object_class;
        my ($object_name) = $dbc->Table_find( $object_class, $object_class . "_Name", "WHERE $object_class" . "_ID = $object_id" );
        $Primer->{$code}   = $object_name;
        $status_h->{$code} = $status;
        $cc_count++;
        $active_count++ if $status eq 'Active';
        $Report->succeeded();
    }
    $Report->set_Message("Total branch codes: $cc_count");
    $Report->set_Message("Total active branch codes: $active_count");
    %Chem->{Chemistry} = $Chemistry;
    %Chem->{Branch}    = $Primer;
    %Chem->{Status}    = $status_h;
    my $ok = &store( \%Chem, "$storage_dir/ChemistryInfo" );
}

$Report->completed();

#Report->DESTROY();
$dbc->disconnect();
exit;

###############################
sub Store_run_statistics {
###############################
    my $Run     = shift;         ## reference to hash with info
    my $file    = shift;         ## stored file name...
    my $rewrite = shift || 0;    ### (otherwise just updates)

    my %Run_Stats;
    if ($rewrite) {
        print "OVERWRITING ORIGINAL $file\n";
    }
    else {
        %Run_Stats = %{ &load_Stats( $file, $Stats_dir, 'lock' ) };    ## load with current data...
    }

    print "Storing Run Statistics..\n";
    unless ($Run) {return}
    foreach my $run_id ( keys %{$Run} ) {
        print "Run $run_id.";
        %Run_Stats->{$run_id}->{OK}          = $Run->{$run_id}->{OK};
        %Run_Stats->{$run_id}->{'No Grow'}   = $Run->{$run_id}->{'No Grow'};
        %Run_Stats->{$run_id}->{'Slow Grow'} = $Run->{$run_id}->{'Slow Grow'};
        %Run_Stats->{$run_id}->{Reads}       = $Run->{$run_id}->{Reads};
        %Run_Stats->{$run_id}->{Status}      = $Run->{$run_id}->{Status};
        %Run_Stats->{$run_id}->{Library}     = $Run->{$run_id}->{Library};
        %Run_Stats->{$run_id}->{Time}        = $Run->{$run_id}->{Time};
        %Run_Stats->{$run_id}->{Sequencer}   = $Run->{$run_id}->{Sequencer};
        %Run_Stats->{$run_id}->{TotalLength} = $Run->{$run_id}->{Length};        ## including No Grows...
        ### exclude No Grows from the following values... ###
        %Run_Stats->{$run_id}->{GoodReads}  = $Run->{$run_id}->{GoodReads};
        %Run_Stats->{$run_id}->{SumLength}  = $Run->{$run_id}->{GoodLength};
        %Run_Stats->{$run_id}->{AvgLength}  = $Run->{$run_id}->{GoodLength} / $Run->{$run_id}->{GoodReads};
        %Run_Stats->{$run_id}->{SumQLength} = $Run->{$run_id}->{GoodLength};
        %Run_Stats->{$run_id}->{AvgQLength} = $Run->{$run_id}->{GoodLength} / $Run->{$run_id}->{GoodReads};

        ### accumulate stats for Q20 ###
        print '.';
        my $Rstat = Statistics::Descriptive::Full->new();
        print '.';

        #	$Rstat->add_data(@{$Run->{$run_id}->{P20_Data}});
        print '.';
        %Run_Stats->{$run_id}->{P20_count}   = $Rstat->count();
        %Run_Stats->{$run_id}->{P20_median}  = $Rstat->median();
        %Run_Stats->{$run_id}->{P20_mean}    = $Rstat->mean();
        %Run_Stats->{$run_id}->{P20_sum}     = $Rstat->sum();
        %Run_Stats->{$run_id}->{P20_std_dev} = $Rstat->standard_deviation();
        print '.';
    }
    my $Rok;
    print "Store";
    $Rok = &store( \%Run_Stats, "$storage_dir/$file" );
    &RGTools::RGIO::Unlock_File("$Stats_dir/$file");

    if ($Rok) { print "*** Saved Run Statistics in $storage_dir/$file ***\n"; }
    return $Rok;
}

######################
sub generate_hist {
######################
    #
    # Temporary - unfinished... store histograms for libraries/projects automatically... (?)
    #
    my %args        = @_;
    my $data        = $args{'data'};
    my $filename    = $args{'file'};
    my @Bins        = @{ $args{'data'} };
    my $binsiZe     = Extract_Values( [ $args{'binsize'}, 10 ] );
    my $remove_zero = shift;
    my $binsize     = Extract_Values( [ shift, 2 ] );               ### width of bin in pixels...
    my $group_bins  = Extract_Values( [ shift, 10 ] );              ### group N bins together by colour
    my $Ncolours    = Extract_Values( [ shift, 9 ] );               ### number of unique colours

    my $num_bins = scalar(@Bins);

    my @x_ticks = ( 200, 400, 600, 800 );
    my $Hist = SDB::Histogram->new( -path => $URL_cache );
    $Hist->Set_Bins( \@Bins, $binsize );
    $Hist->Set_X_Axis( ' Phred20 Quality / Read', 10, \@x_ticks );    ### each bin is 10 units wide..
    $Hist->Number_of_Colours($Ncolours);
    $Hist->Group_Colours($group_bins);

    # $Hist->Set_Height(40);
    ( my $scale, my $max1 ) = $Hist->DrawIt( $filename, height => 100 );

}

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: update_Stats.pl,v 1.42 2004/10/18 18:59:28 rguin Exp $ (Release: $Name:  $)

=cut

