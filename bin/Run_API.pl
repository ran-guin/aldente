#!/usr/local/bin/perl
use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use Data::Dumper;
use Getopt::Std;
use MIME::Base32;
use YAML;
use vars qw($opt_c $opt_i $opt_t $opt_m $opt_r $opt_d);
getopts('c:i:t:m:r:d');

my $connection     = $opt_c;
my $input          = $opt_i;
my $API_type       = $opt_t;
my $API_method     = $opt_m;
my $require_module = $opt_r;
my $debug          = $opt_d;

#Decode and thaw the pass in connection hash ref
my $decode_c = MIME::Base32::decode($connection);
my $thaw_c   = YAML::thaw($decode_c);

#Decode and thaw the pass in input hash ref
my $decode_i = MIME::Base32::decode($input);
my $thaw_i   = YAML::thaw($decode_i);
if ($debug) {
    $thaw_i->{-quiet} = 0;
    $thaw_i->{-debug} = 1;
}

#Load the API module
$require_module =~ s/\//::/;
$require_module =~ s/\.pm//;
eval "require $require_module;";

#Create API object and run the method
my $API_obj     = $API_type->new(%$thaw_c);
my $api_results = $API_obj->$API_method(%$thaw_i);

#Freeze and encode the api result hash ref and print it so that it can catch by try_system_command. If debugging, don't freeze and encode, just dump result out
if ( !$debug ) {
    my $freeze_results = YAML::freeze($api_results);
    my $encode_results = MIME::Base32::encode($freeze_results);
    print "\n$encode_results";
}
else { print "\n" . Dumper $api_results }

exit;
