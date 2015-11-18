#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Sequencing";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use Sequencing::Post;
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
use_ok("Sequencing::Post");

if ( !$method || $method=~/\bget_run_info\b/ ) {
    can_ok("Sequencing::Post", 'get_run_info');
    {
        ## <insert tests for get_run_info method here> ##
    }
}

if ( !$method || $method=~/\bget_mirrored_data\b/ ) {
    can_ok("Sequencing::Post", 'get_mirrored_data');
    {
        ## <insert tests for get_mirrored_data method here> ##
    }
}

if ( !$method || $method=~/\bget_analyzed_data\b/ ) {
    can_ok("Sequencing::Post", 'get_analyzed_data');
    {
        ## <insert tests for get_analyzed_data method here> ##
    }
}

if ( !$method || $method=~/\bzip_trace_files\b/ ) {
    can_ok("Sequencing::Post", 'zip_trace_files');
    {
        ## <insert tests for zip_trace_files method here> ##
    }
}

if ( !$method || $method=~/\binit_clone_sequence_table\b/ ) {
    can_ok("Sequencing::Post", 'init_clone_sequence_table');
    {
        ## <insert tests for init_clone_sequence_table method here> ##
    }
}

if ( !$method || $method=~/\brun_phred\b/ ) {
    can_ok("Sequencing::Post", 'run_phred');
    {
        ## <insert tests for run_phred method here> ##
    }
}

if ( !$method || $method=~/\brun_crossmatch\b/ ) {
    can_ok("Sequencing::Post", 'run_crossmatch');
    {
        ## <insert tests for run_crossmatch method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_fasta_file\b/ ) {
    can_ok("Sequencing::Post", 'generate_fasta_file');
    {
        ## <insert tests for generate_fasta_file method here> ##
    }
}

if ( !$method || $method=~/\bparse_screen_file\b/ ) {
    can_ok("Sequencing::Post", 'parse_screen_file');
    {
        ## <insert tests for parse_screen_file method here> ##
    }
}

if ( !$method || $method=~/\bscreen_contaminants\b/ ) {
    can_ok("Sequencing::Post", 'screen_contaminants');
    {
        ## <insert tests for screen_contaminants method here> ##
    }
}

if ( !$method || $method=~/\bcreate_colour_map\b/ ) {
    can_ok("Sequencing::Post", 'create_colour_map');
    {
        ## <insert tests for create_colour_map method here> ##
    }
}

if ( !$method || $method=~/\bupdate_datetime\b/ ) {
    can_ok("Sequencing::Post", 'update_datetime');
    {
        ## <insert tests for update_datetime method here> ##
    }
}

if ( !$method || $method=~/\bupdate_source\b/ ) {
    can_ok("Sequencing::Post", 'update_source');
    {
        ## <insert tests for update_source method here> ##
    }
}

if ( !$method || $method=~/\bclear_phred_files\b/ ) {
    can_ok("Sequencing::Post", 'clear_phred_files');
    {
        ## <insert tests for clear_phred_files method here> ##
    }
}

if ( !$method || $method=~/\bparse_phred_scores\b/ ) {
    can_ok("Sequencing::Post", 'parse_phred_scores');
    {
        ## <insert tests for parse_phred_scores method here> ##
    }
}

if ( !$method || $method=~/\bget_run_statistics\b/ ) {
    can_ok("Sequencing::Post", 'get_run_statistics');
    {
        ## <insert tests for get_run_statistics method here> ##
    }
}

if ( !$method || $method=~/\bupdate_run_statistics\b/ ) {
    can_ok("Sequencing::Post", 'update_run_statistics');
    {
        ## <insert tests for update_run_statistics method here> ##
    }
}

if ( !$method || $method=~/\bcheck_phred_version\b/ ) {
    can_ok("Sequencing::Post", 'check_phred_version');
    {
        ## <insert tests for check_phred_version method here> ##
    }
}

if ( !$method || $method=~/\bphred_command\b/ ) {
    can_ok("Sequencing::Post", 'phred_command');
    {
        ## <insert tests for phred_command method here> ##
    }
}

if ( !$method || $method=~/\bcross_match_command\b/ ) {
    can_ok("Sequencing::Post", 'cross_match_command');
    {
        ## <insert tests for cross_match_command method here> ##
    }
}

if ( !$method || $method=~/\badd_note\b/ ) {
    can_ok("Sequencing::Post", 'add_note');
    {
        ## <insert tests for add_note method here> ##
    }
}

if ( !$method || $method=~/\blink_96_to_384\b/ ) {
    can_ok("Sequencing::Post", 'link_96_to_384');
    {
        ## <insert tests for link_96_to_384 method here> ##
    }
}

if ( !$method || $method=~/\bcheck_for_repeating_sequence\b/ ) {
    can_ok("Sequencing::Post", 'check_for_repeating_sequence');
    {
        ## <insert tests for check_for_repeating_sequence method here> ##
    }
}

if ( !$method || $method=~/\bcreate_temp_screen_file\b/ ) {
    can_ok("Sequencing::Post", 'create_temp_screen_file');
    {
        ## <insert tests for create_temp_screen_file method here> ##
    }
}

if ( !$method || $method=~/\bmask_restriction_site\b/ ) {
    can_ok("Sequencing::Post", 'mask_restriction_site');
    {
        ## <insert tests for mask_restriction_site method here> ##

        my @restriction_site      = ('GATG');
         my $mask_restriction_site = 1;
         my $sequence = '';
         ( $sequence, $mask_restriction_site ) = Sequencing::Post::mask_restriction_site( 'ATTGCATAGATAGATGATTTTTTGGGGGCCCCCCG',
                                                                                       \@restriction_site,
                                                                                       $mask_restriction_site );
         
         is( $mask_restriction_site, 0,                                 "Masked restriction_site"               );
         is( $sequence,              "ATTGCATAGATAATTTTTTGGGGGCCCCCCG", "Masked sequence does not contain GATG" );

    }
}

if ( !$method || $method=~/\bparse_vector_file\b/ ) {
    can_ok("Sequencing::Post", 'parse_vector_file');
    {
        ## <insert tests for parse_vector_file method here> ##
        my ($file_name) = $dbc->Table_find( 'Library,LibraryVector,Vector,Vector_Type',
                                            "Vector_Type.Vector_Sequence_File",
                                            "WHERE Library_Name = LibraryVector.FK_Library__Name"
                                            . " and FK_Vector__ID = Vector_ID"
                                            . " and Vector_Type_ID = FK_Vector_Type__ID"
                                            . " LIMIT 1" );

        my ($found_sequence, $header) =  Sequencing::Post::parse_vector_file($file_name);
        ok ($found_sequence, "Vector Sequence found");
        ok ($header, "Header found");
    }
}

## END of TEST ##

ok( 1 ,'Completed Post test');

exit;


=comment

    my $self = shift;
    my %args = filter_input(\@_,-args=>'dbc');
    my $dbc  = $args{-dbc};   
    
    my @restriction_site = ('GATG');
    my $mask_restriction_site = 0;
    my $sequence = '';
    ($sequence,$mask_restriction_site) = mask_restriction_site('ATTGCATAGATAGATGATTTTTTGGGGGCCCCCCG', \@restriction_site,$mask_restriction_site);

    is ($mask_restriction_site, 1, "Masked restriction_site");

    is ($sequence, "ATTGCATAGATAATTTTTTGGGGGCCCCCCG", "Masked sequence does not contain GATG");

    my ($file_name) = $dbc->Table_find('Library,LibraryVector,Vector,Vector_Type', "Vector_Type.Vector_Sequence_File", "WHERE Library_Name = LibraryVector.FK_Library__Name and FK_Vector__ID = Vector_ID and Vector_Type_ID = FK_Vector_Type__ID LIMIT 1");

    my ($found_sequence,$header) =  parse_vector_file($file_name);
    ok ($found_sequence, "Vector Sequence found");
    ok ($header, "Header found");
    
    return 'completed';


=cut

