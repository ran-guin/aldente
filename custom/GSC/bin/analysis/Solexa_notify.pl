#!/usr/local/bin/perl

use strict;
use warnings;

use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use SDB::CustomSettings;
use Sequencing::Solexa_Analysis;
use alDente::Run;
use alDente::Subscription;
use alDente::SDB_Defaults;
use alDente::Notification;

my $flowcell = 'FC6330';

my $i;
my $done         = 1;
my $flowcell_dir = '/archive/solexa1_2/data2/070503_SOLEXA1_0035_FC6330/';

for ( $i = 1; $i < 9; $i++ ) {
    unless ( -e "$flowcell_dir/done.L$i" ) { $done = 0; }
}

if ( $done == 1 && !( -e "$flowcell_dir/Email.sent" ) ) {
    my $ok = &alDente::Notification::Email_Notification(
        -to_address   => 'solexa@bcgsc.ca',
        -from_address => 'mingham@bcgsc.ca',
        -subject      => '$flowcell Image Analysis Complete',
        -body_message => 'Image Analysis complete for $flowcell.',
        -verbose      => 0
    );

    #++++++++++++++++++++++++++++++ Subscription Module version of Notification

    my $tmp = alDente::Subscription->new();

#    my $ok = $tmp->send_notification(-name=>"Flowcell FC6330 Image Analysis Complete",-group=>$target_grp,-from=>'mingham@bcgsc.ca',-subject=>"$flowcell Image Analysis Complete (from Subscription Module)",-body=>'Image Analysis complete for $flowcell.',-content_type=>'html',-testing=>1,-to=>'solexa@bcgsc.ca');
    $ok = $tmp->send_notification(
        -name         => "Flowcell FC6330 Image Analysis Complete",
        -from         => 'mingham@bcgsc.ca',
        -subject      => "$flowcell Image Analysis Complete (from Subscription Module)",
        -body         => "Image Analysis complete for $flowcell.",
        -content_type => 'html',
        -testing      => 1,
        -to           => 'solexa@bcgsc.ca'
    );

    open( SENT, ">$flowcell_dir/Email.sent" ) || die "Can't open \n";
    print SENT "Image analysis for finished, email sent";
    close SENT;

}
exit;
