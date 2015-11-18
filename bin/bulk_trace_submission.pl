#!/usr/local/bin/perl
##############################
# This is a wrapper script to generate bulk trace submissions using the trace_bundle.pl script.
#
#####################
use strict;
use CGI qw(:standard fatalsToBrowser);
use DBI;
use Benchmark;
use Date::Calc qw(Day_of_Week);
use Storable;
use Statistics::Descriptive;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
 
use SDB::DBIO;
use alDente::Run;
use Sequencing::Read;
use alDente::Container;
use alDente::Clone;
use Sequencing::Sequencing_API;
use RGTools::RGIO;
use RGTools::Conversion;
use alDente::SDB_Defaults;
use SDB::CustomSettings;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($testing $Connection);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $pass;
my $API = Sequencing_API->new(-dbase=>'seqtest',-host=>'lims02',-LIMS_user=>'rguin',-LIMS_password=>'aldentepwd',-connect=>1);
my $dbc = $API->dbc();

my $offset = 306;
my $group_size = 6;
my $index = 3;           ## already generated # 1.. 
my $path = "/home/sequence/Submissions/ncbi";

## make sure you are in the appropriate directory (makes tar file paths cleaner) ##
    
foreach my $group (0..28) {
    my $start = $offset + $group*$group_size;
    my $stop = $offset + $group*$group_size + $group_size - 1;
    print "$start ... $stop \n************************\n";
    `/opt/alDente/versions/rguin/bin/trace_bundle.pl -library BE000 -plate $start-$stop -xml 1 -force 1 -path $path -name BE000_$index`;
    `tar -zcvf BE000_$index.tar.gz BE000_$index/`;       ## Zip em up... 
    $index++;
}


### Now ftp them to the appropriate Site ###

&leave();

print "DBC: $dbc";
print Dumper($API);
print "\n**************************\n";

my @sols = &Table_find($dbc,'Solution LEFT JOIN Stock ON FK_Stock__ID = Stock_ID','Solution_ID',"WHERE Stock_ID is null");
foreach my $sol (@sols) { 
    my $ok = &delete_records($dbc,'Solution','Solution_ID',$sol);
    print "$sol : $ok.\n";
}

&leave();

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

sub leave {
    $API->disconnect() if $API;
    exit;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

#########################
sub _execute_sql {
#########################
    my $sql = shift;

    print "\nExecuting '$sql'...(" . now() . ")\n";
    my $rows = $dbc->dbh()->do(qq{$sql});

    if (!$rows) {
        print "*** ERROR executing SQL: $DBI::err ($DBI::errstr)(" . now() . ").\n";
    }
    else {
        $rows += 0;
        print "--- Executed SQL successfully ($rows row(s) affected)(" . now() . ").\n";
    }

    #Returns the number of rows affected and also the newly created primary key ID.
    return ($rows,$dbc->{'mysql_insertid'});
}

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

2004-06-28

=head1 REVISION <UPLINK>

$Id: bulk_trace_submission.pl,v 1.2 2004/10/21 02:36:25 rguin Exp $ (Release: $Name:  $)

=cut

