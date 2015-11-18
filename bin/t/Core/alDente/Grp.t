#!/usr/local/bin/perl
## ./template/unit_test_template.txt ##
#####################################
#
# Standard Template for unit testing
#
#####################################

### Template 4.1 ###

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use Test::Differences;
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use alDente::Grp;
############################

############################################


## ./template/unit_test_dbc.txt ##
use alDente::Config;
my $Setup = new alDente::Config(-initialize=>1, -root => $FindBin::RealBin . '/../../../../');
my $configs = $Setup->{configs};

my $host   = $configs->{UNIT_TEST_HOST};
my $dbase  = $configs->{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';

print "CONNECT TO $host:$dbase as $user...\n";

require SDB::DBIO;
$dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -connect  => 1,
                        -configs  => $configs,
                        );




use_ok("alDente::Grp");

if ( !$method || $method=~/\bdisplay_groups\b/ ) {
    can_ok("alDente::Grp", 'display_groups');
    {
        ## <insert tests for display_groups method here> ##
    }
}

if ( !$method || $method=~/\bget_parent_groups\b/ ) {
    can_ok("alDente::Grp", 'get_parent_groups');
    {
        ## <insert tests for get_parent_groups method here> ##
        #my @grps = alDente::Grp::get_parent_groups(-dbc=>$dbc,-group_id=>13);

#        print "all parent grp of 13/mapping base: ".Dumper(@grps);
#        my $grp_list = join ',', sort {$a <=> $b} @grps;
 #       is($grp_list,'2,4,5,6,7,12,23','found groups ok');
    }
}

if ( !$method || $method=~/\bget_child_groups\b/ ) {
    can_ok("alDente::Grp", 'get_child_groups');
    {
        ## <insert tests for get_child_groups method here> ##
    }
}

if ( !$method || $method=~/\bget_system_groups\b/ ) {
    can_ok("alDente::Grp", 'get_system_groups');
    {
        ## <insert tests for get_system_groups method here> ##
    }
}

if ( !$method || $method=~/\bget_groups\b/ ) {
    can_ok("alDente::Grp", 'get_groups');
    {
        ## <insert tests for get_groups method here> ##
        my @grps = alDente::Grp::get_groups('Employee',150,-dbc=>$dbc);
        my $grp_list = join ',', sort {$a <=> $b} @grps;
        is($grp_list,'2,4,5,6,7,8,12,23,41,58,61,64,65,77,81','found groups ok');
    }
}

if ( !$method || $method=~/\bget_group_members\b/ ) {
    can_ok("alDente::Grp", 'get_group_members');
    {
        ## <insert tests for get_group_members method here> ##
    }
}

if ( !$method || $method=~/\b_get_Groups_above\b/ ) {
    can_ok("alDente::Grp", '_get_Groups_above');
    {
        ## <insert tests for _get_Groups_above method here> ##

        my $groups_above = join ',', alDente::Grp::_get_Groups_above($dbc,5);
        is( $groups_above, '7,17', ' retrieved Groups above in hierarchy' );

        $groups_above = alDente::Grp::_get_Groups_above( $dbc, 10000000 );
        is( $groups_above, 0, 'undefined group returned 0' );

    }
}

if ( !$method || $method=~/\b_get_Groups_below\b/ ) {
    can_ok("alDente::Grp", '_get_Groups_below');
    {
        ## <insert tests for _get_Groups_below method here> ##
        my $groups_below = join ',', alDente::Grp::_get_Groups_below( $dbc, 5 );
        is( $groups_below, '2,23', ' retrieved Groups below in hierarchy' );
    }
}

if ( !$method || $method=~/\brelevant_grp\b/ ) {
    can_ok("alDente::Grp", 'relevant_grp');
    {
        
	#Call_Stack();
	my @grp;
        my @expected_grp;
        @expected_grp = (2);
        # equipment="venus" and it belongs to Cap_Seq Base	
        my @id = (1868);

	    my $groups = alDente::Grp::relevant_grp( $dbc,-equipment_ids=>\@id);	
	    eq_or_diff( $groups,\@expected_grp,'relevant_grp test on equipment successful' );

        @expected_grp = (13);
         my @id = (89);

        $groups = alDente::Grp::relevant_grp( $dbc,-project_ids=>\@id);
        eq_or_diff( $groups,\@expected_grp, ' relevant_grp test on project successful' );
    	
        @expected_grp = (2);
        my @eqpts = qw/1868 1869/;
	    my $groups = alDente::Grp::relevant_grp( $dbc,-equipment_ids=>\@eqpts);	
    	eq_or_diff( $groups, \@expected_grp, 'relevant_grp test on equipment with multiple equipment is successful' );
	
	    # project Stickleback2 belongs to Mapping Base	
        @expected_grp = (13);


        @expected_grp = (18);
        @id = qw\ DE0001\;
        $groups = alDente::Grp::relevant_grp( $dbc,-library=>\@id);
        eq_or_diff( $groups, \@expected_grp, ' relevant_grp test on library successful' );
        #Library DE0001 belongs to MGC Closure Base

        @grp_array = (26);
        @expected_grp = (26);

        $groups = alDente::Grp::relevant_grp( $dbc,-group_ids=>\@grp_array);
        eq_or_diff( $groups, \@expected_grp, ' relevant_grp test on group successful' );

        @grp_array = qw\12 29\;
        @expected_grp = qw\12 29\;

        $groups = alDente::Grp::relevant_grp( $dbc, -group_ids=>\@grp_array );
        eq_or_diff( $groups,\@expected_grp ,'found multiple groups from array_ref');
        
        @id = qw\DE0001 DE0002\;
        @expected_grp = (18,9);
	    $groups = alDente::Grp::relevant_grp( $dbc,-library=>\@id);
        eq_or_diff( $groups,\@expected_grp , ' relevant_grp test on multiple libraries successful' );
             
	    #GroupID for Cap_Seq Production is 4
        @expected_grp =(4);
        @grp = (4);

        $groups = alDente::Grp::relevant_grp( $dbc,-group_ids=>\@grp);
        eq_or_diff($groups,\@expected_grp, ' relevant_grp test on group successful' );
        
    	# Parent groups of Cap_Seq Production are Cap_Seq Admin and Cap_Seq Bioinformatics
        @expected_grp = qw\4 7 17\;
        @grp = (4);
	    $groups = alDente::Grp::relevant_grp( $dbc,-group_ids=>\@grp,-include_parent=>1);        
        eq_or_diff($groups,\@expected_grp, ' relevant_grp test on group successful' );

        @expected_grp = qw\40\;
        @grp = (40);
	    $groups = alDente::Grp::relevant_grp( $dbc,-group_ids=>\@grp,-include_parent=>1);        
        eq_or_diff($groups,\@expected_grp, ' relevant_grp test on QA group successful' );
        
        #$groups = alDente::Grp::relevant_grp( $dbc,-group_ids=>"13",-include_parent=>1);
        #print "rg for mapping base(13), include parent = 1: $groups\n";

        #$groups = alDente::Grp::relevant_grp( $dbc,-group_ids=>"13",-include_parent=>0);
        # print "rg for mapping base(13), inc parent = 0: $groups\n";

        #$groups = alDente::Grp::relevant_grp( $dbc,-group_ids=>"6,7",-include_parent=>1);
        #print "rg for seq admin(6,7), include parent = 1: $groups\n";

        #$groups = alDente::Grp::relevant_grp( $dbc,-group_ids=>"6,7",-include_parent=>0);
        #print "rg for mapping admin(6,7), inc parent = 0: $groups\n";

    }
}

if ( !$method || $method=~/\bget_dept_groups\b/ ) {
    can_ok("alDente::Grp", 'get_dept_groups');
    {   my @grp_list;
        my $dept_groups = alDente::Grp::get_dept_groups(-dbc => $dbc, -dept_id => 2);
        @grp_list = qw\2 4 5 6 7 17 64 65\;
        eq_or_diff( $dept_groups, \@grp_list, ' retrieved Groups belong to Department ID 2' );

        $dept_groups = alDente::Grp::get_dept_groups(-dbc => $dbc, -dept_name => 'Cap_Seq');
        @grp_list = qw\2 4 5 6 7 17 64 65\;
        eq_or_diff( $dept_groups, \@grp_list, ' retrieved Groups belong to the Cap_Seq Department' );
    }
}

if ( !$method || $method =~ /\bremove_Grp\b/ ) {
    can_ok("alDente::Grp", 'remove_Grp');
    {
        ## <insert tests for remove_Grp method here> ##
        # my $remove = alDente::Grp::remove_Grp($dbc,'Mapping Base','Mapping Production');
        # is($remove,1,'replaced base with production');

        my $remove2 = alDente::Grp::remove_Grp($dbc,'Systems');
        is($remove2,0,'failed if no replacement group supplied');
    
    }
}
if ( !$method || $method =~ /\brelevant_library\b/ ) {
    can_ok("alDente::Grp", 'relevant_library');
    {
        ## <insert tests for relevant_library method here> ##
    }
}

if ( !$method || $method =~ /\bget_Grps\b/ ) {
    can_ok("alDente::Grp", 'get_Grps');
    {
        ## <insert tests for get_Grps method here> ##
    }
}

if ( !$method || $method =~ /\bget_group_pipeline\b/ ) {
    can_ok("alDente::Grp", 'get_group_pipeline');
    {
        ## <insert tests for get_group_pipeline method here> ##
        my @result = @{alDente::Grp::get_group_pipeline( -dbc => $dbc, -grp => '48,55', -department_name => 'Biospecimen_Core' )};
        my @expected = ( 230, 284, 294 );	# update the expected list when the GrpPipeline records are added
        is_deeply( \@result, \@expected, 'get_group_pipeline( ID returned )' );
        @result = @{alDente::Grp::get_group_pipeline( -dbc => $dbc, -grp => '48,55', -department_name => 'Biospecimen_Core', -return_format => 'Name' )};
        @expected = ('BGA : Biospecimen Core - WGA', 'BBL : Biospecimen Core - Blood lysis', 'BQC : Bispecimen Core - DNA QC' );	# update the expected list when the GrpPipeline records are added
        is_deeply( \@result, \@expected, 'get_group_pipeline( Name returned )' );
        @result = @{alDente::Grp::get_group_pipeline( -dbc => $dbc, -grp => '48,55' )};
        @expected = ( 230, 284, 294 );	# update the expected list when the GrpPipeline records are added
        is_deeply( \@result, \@expected, 'get_group_pipeline( ID returned, No department passed in )' );
    }
}

## END of TEST ##

ok( 1 ,'Completed Grp test');

exit;
