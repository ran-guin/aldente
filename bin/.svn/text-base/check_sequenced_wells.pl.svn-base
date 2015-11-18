#!/usr/local/bin/perl
use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use DBI;
#use lib "/opt/alDente/versions/production/lib/perl/";

### Helper modules
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::HTML_Table;
use RGTools::Process_Monitor;

### Sequencing
use Sequencing::Sequencing_API;

### alDente Modules;
use alDente::Notification;
use alDente::Employee;
use alDente::Subscription;
use SDB::CustomSettings;

### Parsing Options
#use Getopt::Std;

### Debugging
use Data::Dumper;

use vars qw( $opt_user           $opt_password
             $opt_run            $opt_library
             $opt_plate_number   $opt_plate
             $opt_dbase          $opt_host
             $opt_quiet          $opt_since
             $opt_until          $Connection
             $opt_debug          %Configs
        );

use Getopt::Long;
&GetOptions(
    'user=s'            => \$opt_user,
    'password=s'        => \$opt_password,
    'run=s'             => \$opt_run,
    'library=s'         => \$opt_library,
    'plate_number=s'    => \$opt_plate_number,
    'plate_id'          => \$opt_plate,
    'dbase=s'           => \$opt_dbase,
    'host=s'            => \$opt_host,
    'quiet'             => \$opt_quiet,
    'debug'             => \$opt_debug,
    'since=s'           => \$opt_since,
    'until=s'           => \$opt_until,
    'quiet=s'           => \$opt_quiet,
);

## Connection Information
my $user                = $opt_user     || 'guest';
my $password            = $opt_password || 'pwd';
my $host                = $opt_host     || $Configs{SQL_HOST};
my $dbase               = $opt_dbase    || $Configs{DATABASE};

## Debugging Options
my $debug               = $opt_debug;
my $quiet               = $opt_quiet;

## Run options
my $run                 = $opt_run; 
my $library             = $opt_library;
my $plate_number        = $opt_plate_number;
my $plate_id            = $opt_plate;

## Date Range options
my $since               = $opt_since || &date_time("-7d");
my $until               = $opt_until;

my $API = Sequencing_API->new(-dbase=>$dbase,-host=>$host,-LIMS_user=>$user,-LIMS_password=>$password,-DB_user=>'viewer',-debug=>$debug);
my $dbc = $API->connect_to_DB();

#################### create Process_Monitor object for logging script ############

my $Report = Process_Monitor->new(
                                  -quiet =>   0,
                                  -verbose => 0,
                              );

### find the runs that wells that are set as no grows/empty/problematic and flag them if the sequence quality is above a threshold (100)

### Growth 

### Quality_Length THRESHOLD
my $QUALITY_THRESHOLD = 100;
my $condition         = "Quality_Length > $QUALITY_THRESHOLD and Growth in ('Problematic','Empty', 'Unused')";
my $results           = $API->get_run_data(-fields       => "run_id,sequenced_plate,sequenced_well,Quality_Length,Growth",
                                           -library      => $library, 
                                           -run_id       => $run,
                                           -plate_number => $plate_number,
                                           -plate_id     => $plate_id, 
                                           -since        => $since,
                                           -until        => $until, 
                                           -condition    => $condition,
                                           -group        => "run_id,sequenced_well"
                                       );

if ( defined $results->{run_id}[0] ) {
    my $index   = 0;
    my $title   = "<b>The following runs have wells marked as no grows, empty or problematic wells but have quality sequence data:\n\n</b>";
    my $headers = "Run \t\t Plate \t\t Well \t\t Quality Length \t\t Growth\n";

    ### CREATE HTML Table
    my $table   = new HTML_Table( -title => $title );
    $table->Set_Headers( ['Run','Plate','Well','Quality Length','Growth'] );
    $table->Toggle_Colour_on_Column(1);

    my $output  = $title;
    $output    .= $headers;

    my $warning_runs = '';
    my $message_runs = '';
    while (defined $results->{run_id}[$index]) {
        my $run_id              = $results->{run_id         }[$index];
        my $sequenced_plate     = $results->{sequenced_plate}[$index];
        my $quality_length      = $results->{Quality_Length }[$index];
        my $growth              = $results->{Growth         }[$index];
        my $well                = $results->{sequenced_well }[$index];

        $output .= "$run_id \t\t $sequenced_plate \t\t $well \t\t $quality_length \t\t $growth\n";
        $table->Set_Row([$run_id,$sequenced_plate,$well,$quality_length,$growth]);

        if ($growth eq 'Unused' || $growth eq 'Empty') {
            $warning_runs .= "Run: $run_id, Plate: $sequenced_plate, Well: $well, Quality Length: $quality_length, Growth: $growth\n";
        }
        else {
            $message_runs .= "Run: $run_id, Plate: $sequenced_plate, Well: $well, Quality Length: $quality_length, Growth: $growth\n";
        }

        $index++;
    }

    $Report->set_Warning($warning_runs) if $warning_runs;
    $Report->set_Message($message_runs) if $message_runs;
    
    if ($debug) {
        print $output;
    }
    else {
        my $from_address        = "aldente\@bcgsc.ca";
        my $email_list          = alDente::Employee::get_email_list(-dbc=>$dbc, -list=>'admin', -department=>"Sequencing");

        ## Get list of sequencing admins
        my $recipients          = Cast_List(-list=>$email_list,-to=>"String");
        my $to_address          = $from_address; #$recipients;
        my $header              = "Content-type: text/html\n\n";

        ## Send EMAIL
    my $ok = alDente::Subscription::send_notification(-dbc=>$dbc,-name=>"Sequenced Well Check",-to=>$to_address,-from=>$from_address,-subject=>"Sequenced Well Check (from Subscription Module)",-body=>$table->Printout(0),-content_type=>'html',-bypass=>1);	
    }
}
else {
    print "**** NO results ****\n";
}

$Report->completed();
$Report->DESTROY();

exit;
