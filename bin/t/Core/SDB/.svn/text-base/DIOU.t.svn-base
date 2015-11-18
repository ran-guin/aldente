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

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use SDB::DIOU;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("SDB::DIOU");

if ( !$method || $method=~/\bparse_delimited_file\b/ ) {
    can_ok("SDB::DIOU", 'parse_delimited_file');
    {
        ## <insert tests for parse_delimited_file method here> ##
    }
}

if ( !$method || $method=~/\bfind_Row1\b/ ) {
    can_ok("SDB::DIOU", 'find_Row1');
    {
        ## <insert tests for find_Row1 method here> ##
    }
}

if ( !$method || $method=~/\bpreview\b/ ) {
    can_ok("SDB::DIOU", 'preview');
    {
        ## <insert tests for preview method here> ##
    }
}

if ( !$method || $method=~/\bedit_submission_file\b/ ) {
    can_ok("SDB::DIOU", 'edit_submission_file');
    {
        ## <insert tests for edit_submission_file method here> ##
    }
}

if ( !$method || $method=~/\badd_column_to_submission\b/ ) {
    can_ok("SDB::DIOU", 'add_column_to_submission');
    {
        ## <insert tests for add_column_to_submission method here> ##
    }
}

if ( !$method || $method=~/\badd_values_to_submission\b/ ) {
    can_ok("SDB::DIOU", 'add_values_to_submission');
    {
        ## <insert tests for add_values_to_submission method here> ##
    }
}

if ( !$method || $method=~/\bbatch_validate_file\b/ ) {
    can_ok("SDB::DIOU", 'batch_validate_file');
    {
        ## <insert tests for batch_validate_file method here> ##
    }
}

if ( !$method || $method=~/\bbatch_append_file\b/ ) {
    can_ok("SDB::DIOU", 'batch_append_file');
    {
        ## <insert tests for batch_append_file method here> ##
    }
}

if ( !$method || $method=~/\bwrite_to_db\b/ ) {
    can_ok("SDB::DIOU", 'write_to_db');
    {
        ## <insert tests for write_to_db method here> ##
    }
}

if ( !$method || $method=~/\bextract_attribute_fields\b/ ) {
    can_ok("SDB::DIOU", 'extract_attribute_fields');
    {
        ## <insert tests for extract_attribute_fields method here> ##
    }
}

if ( !$method || $method=~/\bget_data_headers\b/ ) {
    can_ok("SDB::DIOU", 'get_data_headers');
    {
        ## <insert tests for get_data_headers method here> ##
    }
}

if ( !$method || $method=~/\bvalidate_file_headers\b/ ) {
    can_ok("SDB::DIOU", 'validate_file_headers');
    {
        ## <insert tests for validate_file_headers method here> ##
    }
}

if ( !$method || $method=~/\bget_selected_headers\b/ ) {
    can_ok("SDB::DIOU", 'get_selected_headers');
    {
        ## <insert tests for get_selected_headers method here> ##
    }
}

if ( !$method || $method=~/\bparse_file\b/ ) {
    can_ok("SDB::DIOU", 'parse_file');
    {
        ## <insert tests for parse_file method here> ##
    }
}

if ( !$method || $method=~/\bparse_file_to_array\b/ ) {
    can_ok("SDB::DIOU", 'parse_file_to_array');
    {
        ## <insert tests for parse_file_to_array method here> ##
    }
}

if ( !$method || $method=~/\bparse_file_to_hash\b/ ) {
    can_ok("SDB::DIOU", 'parse_file_to_hash');
    {
        ## <insert tests for parse_file_to_hash method here> ##
    }
}

if ( !$method || $method=~/\bhash_to_array\b/ ) {
    can_ok("SDB::DIOU", 'hash_to_array');
    {
        ## <insert tests for hash_to_array method here> ##
    }
}

if ( !$method || $method=~/\bget_header_data\b/ ) {
    can_ok("SDB::DIOU", 'get_header_data');
    {
        ## <insert tests for get_header_data method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DIOU test');

exit;


=comment

    my $self = shift;
    my %args = @_;

    use Test::Simple;
    use Test::More; use SDB::CustomSettings qw(%Configs);
    use RGTools::Unit_Test;
    
    my $dbc = $args{-dbc} || $Connection;

    my @headers = @{ validate_file_headers(-headers=>['Primer_Name'],-table=>'Primer') };
#    my @headers = @{ validate_file_headers(-headers=>['Buffer_Name'],-table=>'Buffer') };
    is($headers[0],'Primer_Name');
    
    my @headers2 = @{ validate_file_headers(-headers=>['Primer'],-table=>'Primer') };
    is($headers2[0],undef, 'undefined if invalid');

    ## unit test new methods ##

    ## parse_file_to_array
    ## parse_file_to_hash
    ## hash_to_array

    my $start = {'C1'=>[1,2,3,4,5],'C2'=>[6,7,8,9,10]};
    my @finish = ('C1,C2','1,6','2,7','3,8','4,9','5,10');
    my @new_array = hash_to_array($start,',');
    my @reverse_array = hash_to_array($start,',',['C2','C1']);
    my @reverse = ('C2,C1','6,1','7,2','8,3','9,4','10,5');

    is_deeply( \@new_array, \@finish, 'converts hash to array sorted by keys');
    is_deeply( \@reverse_array, \@reverse, 'converts hash to array with specified order');
    ## dump_to_file  (either array of rows or hash (keys -> headers))
    
    my @lines = ("an extra comment line\n","C1\tC2\tC3\n","1\t2\t3");
    is (find_Row1(\@lines,"\t"), 2, 'found start of data');
    return 'completed';


=cut

