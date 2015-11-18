#!/usr/local/bin/perl

################################
#
# Template for unit testing
################################
##############################
# superclasses               #
##############################
use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use RGTools::RGIO;
use Data::Dumper;
use SDB::CustomSettings qw(%Configs);

##############################
# global_vars                #
##############################
use vars qw($opt_E $opt_G $opt_P $opt_L $opt_T $opt_D $opt_R $opt_Q $opt_O $opt_B $opt_H $opt_U $opt_S);
##############################

require "getopts.pl";
&Getopts('E:G:P:L:U:TDSHR:Q:O:B:');



use alDente::Subscription;
my $host = $Configs{SQL_HOST};
my $dbase = $Configs{TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $help = $opt_H  || 0; #display help if set

my $event = $opt_E; #|| "Submission";      ## monitor Stock levels
my $group = $opt_G ;
my $project = $opt_P ;       ## check Run Quality Diagnostics
my $library = $opt_L ;    ## reset old (unAnalyzed) runs to 'Expired' and temporary solutions to 'Finished'my 
my $equipment= $opt_U ;

my $test = $opt_T || 1; #by default we won't send out the not
my $debug = $opt_D || 0;          ## Data integrity checks...
my $show_log = $opt_S || 1; #display log info on screen by default

my $rg_project = $opt_R;        ## do ALL checks above...          
my $rg_equipment = $opt_Q;      ## force notification even if normally not sent.
my $rg_group= $opt_O;
my $rg_library = $opt_B;
my $none_set;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );

if (!$event) {
    my @event_list = $dbc->Table_find('Subscription_Event','Subscription_Event_Name');
    print "List of available events:\n" ;
    
    print join "\n",@event_list;
    print "\n\n\n";

}
if ((!$event) || ($help ==1)) {
    print<<HELP;
SYNOPSIS
        Test Subscription [OPTION]...
        
DESCRIPTION


        -E
                specify the Event (default is Submission)
        -U
                specify Equipement filter
        -G  
                specify the Group Filter
        -L
                specify the Library Filter for Subscription
        -P
                specify the Project Filter for Subscription
        -T
                set Test flag which send the notification to aldente only (Not the original recipients)
                
        -S
                set Show Log flag will display the contents of the Log file of the current run on the screen
        -D
                specify the Debug Flag which will show the SQL queries executed on the screen
HELP

    exit;
}


#my $tmp = alDente::Subscription->new(-dbc=>$dbc);
#$tmp->set_debug_flag(-value=>$debug);
#$tmp->set_show_log_flag(-value=>$show_log);

#my $ok =    $tmp->send_notification(-name=>$event,-from=>'aldente@bcgsc.bc.ca',-subject=>'Subscription test from TestSubscription.pl',-body=>"Values of the Arguments: EVENT = $event, testing = $test, group = $group, library = $library, project = $ project, equipment = $equipment",-content_type=>'html',-testing=>$test,-group=>$group,-library=>$library,-project=>$project,-equipment=>$equipment);

# This is the alternative way to invoke the wrapper without creating the Subscription object first.

# alDente::Subscription::set_debug_flag(-value=>$debug);
# alDente::Subscription::set_show_log_flag(-value=>$show_log);

my $group_id_list = Cast_List( -list => $group, -to => 'arrayref',-delimiter=>',' );

alDente::Subscription::send_notification(-dbc=>$dbc,-name=>$event,-from=>'aldente@bcgsc.bc.ca',-subject=>'Subscription test from TestSubscription.pl',-body=>"Values of the Arguments: EVENT = $event, testing = $test, group = $group_id_list, library = $library, project = $ project, equipment = $equipment",-content_type=>'html',-testing=>$test,-group=>$group,-library=>$library,-project=>$project,-equipment=>$equipment,-debug=>$debug,-show_log=>$show_log);


exit;
