#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported/SOAP";
use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);
use YAML;
use MIME::Base32;

my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';


use_ok('XMLRPC::Lite');

## Create a web service client

my $version_name = "SDB";
$version_name = "SDB_$Configs{version_name}" if $Configs{version_name} ne 'production'; 
print "V: $version_name\n";


my $web_service_client =  XMLRPC::Lite ->proxy("$Configs{URL_domain}/$version_name/cgi-bin/Web_Service.pl");
isa_ok($web_service_client, 'XMLRPC::Lite');

## Call the login method using the client (returns a login object)
{
	## Login with no username and password
	my $login = $web_service_client->call('lims_web_service.login',{'username' =>'', 'password' =>''})-> result;
	is($login->{errors},1, "Errors exist");
	is($login->{error_reason}, 'No Username/password', "Username/password not supplied");
}

{
	## Login with an invalid username/password
	my $login = $web_service_client->call('lims_web_service.login',{'username' =>'Rob', 'password' =>'Homer'})-> result;
	is($login->{errors},1, "Errors exist");
	is($login->{error_reason}, 'Username/password not recognized', "Username/password not recognized");	
	
}

{
	## Login as a collaborator with valid username/password
	my $login = $web_service_client->call('lims_web_service.login',{'username' =>'ccullis', 'password' =>'78tt99tt'})-> result;
	$login = MIME::Base32::decode($login);
	$login = YAML::thaw($login);

	is($login->{access}, 1, "Successfully logged in");
	## Errors is set to blank 
	is($login->{errors}, '', "No errors");
	
	is($login->{user_type}, 'Collaborator', "User Type is set to Collaborator");
}


## Call the get_projects method using the client (returns a hash of project ids)
{
	my $login = $web_service_client->call('lims_web_service.login',{'username' =>'ccullis', 'password' =>'78tt99tt'})-> result;

	my $projects_list = $web_service_client->call('lims_web_service.get_projects',{'login' => $login})-> result;
	my $project_count = scalar(@{$projects_list->{project_ids}});
	
	ok ($project_count > 0, "Projects exist");		
}


## Call get_read_data method (returns hash of sequencing data)
{
	{
	## Check for login access to method
	my $invalid_login = $web_service_client->call('lims_web_service.login',{'username' =>'limsprox', 'password' =>'noyou'})-> result;
	my $no_access_to_method = $web_service_client->call('lims_web_service.get_read_data',$invalid_login,
												 {
												  'library' => 'MGL01', 
												  'plate_number' => 1}
												)-> result;

	is($no_access_to_method->{error_reason}, "No permission to use this method", "Check for login access");
    }

	
	
	## Check for method usage via help <CONSTRUCTION> check why limsproxy doesn't work
	my $valid_login = $web_service_client->call('lims_web_service.login',{'username' =>'testlims', 'password' =>'testlims'})-> result;

	my $help = $web_service_client->call('lims_web_service.get_read_data',$valid_login,
												 {
												  'help' => 1, 
												 }
												)-> result;

	ok (length($help->{usage}) > 0, "Help message is returned");
	

												
=pod
	SKIP: {
			my $api_read_data;
			eval {
				

				require Sequencing::Sequencing_API;
				
				my $API = Sequencing_API->new(-dbase=>$dbase,-host=>$host,-DB_user=>$user,-DB_password=>$pwd);
				
				$API->connect();
		
				$api_read_data = $API->get_read_data(-quiet=>1,-library=>'MGL01',-plate_number=>1,-limit=>10);
			};				
			skip "Sequencing API call failed", 1 if $@;	
			## Use valid login and retrieve the data from the API
			my $valid_login = $web_service_client->call('lims_web_service.login',{'username' =>'testlims', 'password' =>'testlims'})-> result;

			my $valid_read_data = $web_service_client->call('lims_web_service.get_read_data',$valid_login,
														 {
														  'library' => 'MGL01', 
														  'plate_number' => 1,
														 }
														)-> result;
	
			SKIP: {
				eval {
					require 'Test::Differences';
				};	
		
				skip "Don't use eq_or_diff if test::differences doesn't exist", 1 if $@;
				eq_or_diff($valid_read_data, $api_read_data,'API output matches!');	
			}
			skip "Undef causing the output of the API to be different (through web service), returns blank", 1;								
			is_deeply($valid_read_data, $api_read_data, "API output matches the output from web service");
	}
	
	SKIP: {
        local $TODO = "Note ccullis should not be able to access MGL01 information if permissions are working";
		my $login = $web_service_client->call('lims_web_service.login',{'username' =>'ccullis', 'password' =>'78tt99tt'})-> result;
		my $library = 'MGL01';
		my $plate_number = 1;
		my $read_data = $web_service_client->call('lims_web_service.get_read_data',$login,
												 {
												  'library' => $library, 
												  'plate_number' => $plate_number,
												  
												}
												)-> result;
		skip "Collaborator authentication check not in place yet", 1;										
		is($read_data->{error_reason}, "Permission denied", "No permission for $library, $plate_number");

	}

=cut	
#	TODO: {
#		local $TODO = "Enter parameters that are invalid, should return error saying invalid parameters";
#		my $valid_login = $web_service_client->call('lims_web_service.login',{'username' =>'ccullis', 'password' =>'78tt99tt'})-> result;
#
#		my $read_data_invalid_values = $web_service_client->call('lims_web_service.get_read_data',
#												 {'login' => $valid_login,
#												  'library' => 'blah', 
#												  'plate_number' => '99999.2'}
#												)-> result;
#		is($read_data_invalid_values->{error_reason}, "Invalid values entered for parameters", "Invalid values entered for params");										
												
#		my $read_data_invalid_keys = $web_service_client->call('lims_web_service.get_read_data',
#												{'login' => $valid_login,
#												 'beertype' => 'budweiser', 
#											    }
#												 )-> result;
#		is($read_data_invalid_keys->{error_reason}, "Invalid parameters", "Invalid parameters");
												
		## Plate number with no library										
#		my $plate_number_no_library = $web_service_client->call('lims_web_service.get_read_data',
#												{'login' => $valid_login,
#												 'plate_number' => 2, 
#												}
#												)-> result;
#		is($plate_number_no_library->{error_reason}, "Incomplete query", "Incomplete query");										

																								
#	}
	my $api_plate_data;

		
	eval {
		require Sequencing::Sequencing_API;
				
		my $API = Sequencing_API->new(-dbase=>$dbase,-host=>$host,-DB_user=>$user,-DB_password=>$pwd);
		
		$API->connect(-sessionless=>1);
	
		$api_plate_data = $API->get_plate_data(-quiet=>1,-library=>'MGL01',-plate_number=>1,-limit=>2,-plate_type =>'library',-fields=>'plate_id,library_name,plate_number,plate_status');
	};				
	skip "Sequencing API call failed", 1 if $@;


        my $valid_login = $web_service_client->call('lims_web_service.login',{'username' =>'testlims', 'password' =>'testlims'})-> result;

	my $plate_data = $web_service_client->call('lims_web_service.get_plate_data',$valid_login,
														 {
														  'library' => 'MGL01', 
														  'plate_number' => '1',
														   'fields' => 'plate_id,library_name,plate_number,plate_status',
														   'plate_type' =>'library',
														   'limit' => '2'
														 }) -> result;
													
	is_deeply($plate_data,$api_plate_data,"Web Service output matches API output for get_plate_data");												

}

{
        my $valid_login = $web_service_client->call('lims_web_service.login',{'username' =>'testlims', 'password' =>'testlims'})-> result;

        my $plates = [282465, 282466, 282467];
        my $plates = '282465,282466,282467';
	    my $applications_list = $web_service_client->call('lims_web_service.get_application_data',$valid_login, 
            {
                'key' => 'plate_id',
                'plate_id' => $plates, 
                'include_parents' => 1,
                'add_fields' => 'primer, primer_sequence',
                'include'   => 'production,approved',
                'fields' => 'solution_id, event',
                })-> result;
                
        print Dumper $applications_list;	
}

ok( 1 ,'Completed Web_Service test');
exit;
