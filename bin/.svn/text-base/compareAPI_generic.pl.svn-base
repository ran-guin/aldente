#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use RGTools::RGIO qw(read_dumper);
use YAML qw(Dump);

### get options
use vars qw($opt_lib_path $opt_test_file $opt_type $opt_user $opt_password $opt_dbase $opt_host $opt_debug);

&GetOptions(
	    'lib=s' => \$opt_lib_path,
	    'file=s' => \$opt_test_file,
	    'type=s' => \$opt_type,
	    'user=s' => \$opt_user,
	    'password=s' => \$opt_password,
	    'dbase=s' => \$opt_dbase,
	    'host=s' => \$opt_host,
	    'debug=s' => \$opt_debug
	    );

my $LIMS_user = $opt_user;
my $LIMS_password = $opt_password;
my $dbase = $opt_dbase;
my $host = $opt_host;
my $debug = $opt_debug;

if($opt_lib_path eq undef || $opt_test_file eq undef || $opt_type eq undef){
    die "$0: must specify -lib, -file, -type  ";
}

unshift(@INC,"$opt_lib_path");
require Sequencing::Sequencing_API;

##############################
# Constants
##############################
my $production = "production";
my $beta = "beta";
##############################

####################### load API testing file
my $testFile = $opt_test_file;  # test file
my $type = $opt_type;  # type: "production" or "beta"

print "Using library $opt_lib_path for $opt_type\n";

if($type =~ /^(?:production|beta)$/i){
    my $output = &_run($testFile,$type);
}
else{
    die "$0: unrecognized type: $type.  must be \"production\" or \"beta\"  ";
}

#####################################################################################
##################################  Subroutines #####################################
#####################################################################################

##############################
# main procedure
##############################
sub _run{
    my $testFile = shift;
    my $version = shift;

    die "\$testFile undefined\n" unless defined $testFile;
    die "$0: Unknown API version $version.  " if ($version ne "production" && $version ne "beta");

    my %scope;
    my %connectionSetting;

    open(READ,$testFile)||die "Cannot open file $testFile\n";
    while(<READ>){
	chomp;
	if($_ =~ /\[scope\]/){  #define methods and values to be tested
	    my $scope;  # e.g. sample, library
	    my %required;
	    while(<READ>){	
		chomp;
		if($_ =~ /^\([\w\s]+\)/){  # scope specification
		    %required = undef;
		    $_ =~ /^\(([\w\s]+)\)\s*(.*)$/;
		    $scope = $1;
		    %required = %{&_parse_definition($2)};
		}
		elsif($_ =~ /^====$/){  # end of scope specification
		    last;
		}
		elsif($_ =~ /^\#/ || $_ eq ""){  # skip line for lines beginning with '#' or if line empty
		    next;
		}
		elsif($_ =~ /auto/){  # multiple-line API input arugments generated automatically by script; processed differently than single-line input
		    die "$0: Weird line $_.  " if $_ !~ /^auto\s+[\w\d\-]+/;
		    $_ =~ /^auto\s+([\w\d\-]+)/;
		    $scope = $1;

		    my @inputArray;
		    while(<READ>){
			chomp;
			if($_ =~ /^----$/){  # end of an auto input
			    my $start = 0;
			    my %structure;
			    my $structureRef = &RGTools::RGIO::read_dumper(\@inputArray,\$start,\%structure);
			    if(defined $scope{$scope}){
				push(@{$scope{$scope}},$structureRef);
			    }
			    else{
				my @array = ($structureRef);
				$scope{$scope} = \@array;
			    }			 
			    last;
			}
			elsif($_ =~ /^\#/){
			    next;
			}
			push(@inputArray,$_);
		    }
		}
		elsif($_ =~ /^\S+/){  # individual test case
		    my %args = %{&_parse_definition($_)};
		    %args = (%args,%required) if defined %required;
		    if(defined $scope{$scope}){
			push(@{$scope{$scope}},\%args);
		    }
		    else{
			my @array = (\%args);
			$scope{$scope} = \@array;
		    }
		}
		else{
		    die "Weird line: $_\n";
		}
	    }
	}
	elsif($_ =~ /\[database\]/){  # database setting
	    while(<READ>){
		chomp;
		if($_ =~ /^====$/){  # end of database setting
		    last;
		}
		die "$0: Weird line: $_.  " if $_ !~ /^\(\w+\)\s+/;
		$_ =~ /^\((\w+)\)\s+(.+)$/;
		$connectionSetting{$1} = &_parse_definition($2);
	    }
	}
	elsif($_ =~ /====|/){
	}
	else{
	    die "Weird line: $_\n";
	}
    }
    close(READ);

    my %data;

    # determine correct DB connection to use
    my %tempConnectionSetting;
    if($version eq $production){
	%tempConnectionSetting = %{$connectionSetting{$production}};
    }
    elsif($version eq $beta){
	%tempConnectionSetting = %{$connectionSetting{$beta}};
    }

    ### overwrite connection settings if user specifies them
    $tempConnectionSetting{-LIMS_user} = $LIMS_user if defined $LIMS_user;
    $tempConnectionSetting{-LIMS_password} = $LIMS_password if defined $LIMS_password;
    $tempConnectionSetting{-dbase} = $dbase if defined $dbase;
    $tempConnectionSetting{-host} = $host if defined $host;
    $tempConnectionSetting{-debug} = $debug if defined $debug;

    &_API(\%data,\%scope,\%tempConnectionSetting);
    &_print_output(\%data);
}

##############################
# run an API query
##############################
sub _API{
    my $dataRef = shift;
    my $scopeRef = shift;
    my $connectionSettingRef = shift;

    print "Connection:\n";
    foreach (keys %$connectionSettingRef){
	print "\t$_ => $$connectionSettingRef{$_}\n" if $_ !~ /password/i;
    }

    my $API = Sequencing_API->new(%$connectionSettingRef);
    my $dbc = $API->connect_to_DB();

    foreach my $scope (keys %$scopeRef){
	foreach my $argRef (@{$$scopeRef{$scope}}){
	    my ($data,$method,$error) = process_query($scope,$argRef,$API);
	    if($method !~ /\->[\w\-\d]+\(.+\)\;$/){
		die "Weird method format: $method  ";
	    }
	    $method =~ /\->([\w\-\d]+)\((.+)\)\;$/;
	    my $method = "<function>" . $1 . "</function>";
	    my $input = "<argument>" . $2 . "</argument>";
	    $dataRef->{$method}{$input}{data} = $data;
	    $dataRef->{$method}{$input}{arg} = $argRef;
	    $dataRef->{$method}{$input}{error} = $error;
	}
    }
    $dbc->disconnect();
}

##############################
# parse an API test case and return arguments
##############################
sub _parse_definition{
    my $input = shift;

    my @args = split(/\s+/,$input);
    my %args = ();

    foreach my $arg (@args){
	if($arg !~ /^[\w\d-]+\=[\w\d-,]+$/){
	    die "$0: Weird definition format: $arg ";
	}
	else{
	    $arg =~ /^([\w\d-]+)=([\w\d-,]+)$/;
	    my $field = "-" .$1;
	    my $value = $2;
	    if($value !~ /^\d+$/){  # not just digits, put quotes
		$args{$field} = "$value";
	    }
	    else{
		$args{$field} = $value;
	    }
	}
    }
    return \%args;
}

##############################
# process API command
# This is where the script calls API
##############################
sub process_query{
    my $scope = shift;
    my $argRef = shift;
    my $API = shift;

    my $data;
    my $method;
    my $error;

    $scope =~ s/_/ /g;

    if($scope =~ /application/i){
	$method = &_show_test_method("get_application_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_application_data(%$argRef);
    }
    elsif($scope =~ /concentration/i){
	$method = &_show_test_method("get_concentration_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_concentration_data(%$argRef);
    }
    elsif($scope =~ /clone plate/i){
	$method = &_show_test_method("search_clone_plates",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->search_clone_plates(%$argRef);
    }
    elsif($scope =~ /clone$|sample$|clone data|sample data/i){
	$method = &_show_test_method("get_sample_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_sample_data(%$argRef);
    }
    elsif($scope =~ /direction/i){
	$method = &_show_test_method("get_direction",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_direction(%$argRef);
    }
    elsif($scope =~ /event/i){
	$method = &_show_test_method("get_event_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_event_data(%$argRef);
    }
    elsif($scope =~ /extraction/i){
	$method = &_show_test_method("get_extraction_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_extraction_data(%$argRef);
    }
    elsif($scope =~ /gel/i){
	$method = &_show_test_method("get_Gel_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_Gel_data(%$argRef);
    }
    elsif($scope =~ /libraries/i){
	$method = &_show_test_method("get_libraries",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_libraries(%$argRef);
    }
    elsif($scope =~ /library info/i){
	$method = &_show_test_method("get_Library_info",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_Library_info(%$argRef);
    }
    elsif($scope =~ /library$|library data/i){
	$method = &_show_test_method("get_library_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_library_data(%$argRef);
    }
    elsif($scope =~ /oligo/i){
	$method = &_show_test_method("get_oligo_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_oligo_data(%$argRef);
    }
    elsif($scope =~ /plate count/i){
	$method = &_show_test_method("get_plate_count",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_plate_count(%$argRef);
    }
#    elsif($scope =~ /plate history/i){
#	$method = &_show_test_method("get_plate_history",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
#    }
    elsif($scope =~ /plate lineage/i){
	$method = &_show_test_method("get_plate_lineage",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_plate_lineage(%$argRef);
    }
    elsif($scope =~ /plate list/i){
	$method = &_show_test_method("get_Plate_list",$argRef);
	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_Plate_list(%$argRef);
    }
    elsif($scope =~ /plate read/i){
	$method = &_show_test_method("get_plate_reads",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_plate_reads(%$argRef);
    }
    elsif($scope =~ /plate$|plate data/i){
	$method = &_show_test_method("get_Plate_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_Plate_data(%$argRef);
    }

    elsif($scope =~ /primer$|primer data/i){
	$method = &_show_test_method("get_Primer_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_Primer_data(%$argRef);
    }
    elsif($scope =~ /read count/i){
	$method = &_show_test_method("get_read_count",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_read_count(%$argRef);
    }
    elsif($scope =~ /read$|read data/i){
	$method = &_show_test_method("get_read_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_read_data(%$argRef);
    }
    elsif($scope =~ /rearray location/i){
	$method = &_show_test_method("get_Rearray_locations",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_Rearray_locations(%$argRef);
    }
    elsif($scope =~ /rearray$|rearray data/i){
	$method = &_show_test_method("get_Rearray_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_rearray_data(%$argRef);
    }
    elsif($scope =~ /run$|run data/i){
	$method = &_show_test_method("get_run_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_run_data(%$argRef);
    }
    elsif($scope =~ /sage$|sage data/i){
	$method = &_show_test_method("get_SAGE_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_SAGE_data(%$argRef);
    }
    elsif($scope =~ /sample id/i){
	$method = &_show_test_method("get_sample_ids",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_sample_ids(%$argRef);
    }
    elsif($scope =~ /sample$|sample data/i){
	$method = &_show_test_method("get_sample_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_sample_data(%$argRef);
    }
    elsif($scope =~ /source$|source data/i){
	$method = &_show_test_method("get_source_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_source_data(%$argRef);
    }
    elsif($scope =~ /submission$|submission data/i){
	$method = &_show_test_method("get_submission_data",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_submission_data(%$argRef);
    }
    elsif($scope =~ /trace file/i){
	$method = &_show_test_method("get_trace_files",$argRef);
#	print "\n\n***********\nQuery is:\n$method\n**********\n\n";
	$data = $API->get_trace_files(%$argRef);
    }
    else{
	die "$0: Unknown scope: $scope  ";
    }
    return ($data,$method,$error);
}

##############################
# show the API command being run
##############################
sub _show_test_method{
    my $method = shift;
    my $argRef = shift;

    my @arg;
    foreach my $key (keys %$argRef){
	push(@arg,"$key => $$argRef{$key}");
	
    }
    return "\$API->$method(" . join(",",@arg) . ");";
}

##############################
# print API testing results
##############################
sub _print_output{
    my $output = shift;

    foreach my $method (keys %$output){
	print "*******************************\n$method\n*******************************\n\n";
	foreach my $input (keys %{$$output{$method}}){
	    print "------------  I N P U T  ------------\n";
	    my $inputRef = $$output{$method}->{$input}->{arg};
	    print "<argument>";
	    print YAML::Dump($inputRef);
	    print "</argument>";
	    print "-------------------------------------\n";
	    print "\n------------  R E S U L T  ----------\n";
	    my $dataRef = $$output{$method}->{$input}->{data};
	    print YAML::Dump($dataRef);
	    print "-------------------------------------\n";
	}
    }
}
