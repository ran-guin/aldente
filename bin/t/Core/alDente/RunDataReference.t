#!/usr/bin/perl
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
use alDente::RunDataReference;
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




use_ok("alDente::RunDataReference");

my $obj = alDente::RunDataReference->new(-dbc=>$dbc);

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::RunDataReference", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bsave_annotations\b/ ) {
    can_ok("alDente::RunDataReference", 'save_annotations');
    {
        my $result;

        $result = $obj->save_annotations(-reference=> ['70001:A01'], -annot_type=>'Sulston Score',-annot_value=>'0.0003');
        is($result,1,'Stored annotation between one run/well');

        $result = $obj->save_annotations(-reference=> ['70001:A01','70002:A01'], -annot_type=>'Sulston Score',-annot_value=>'70001');
        is($result,1,'Stored annotation between two run/wells');

        $result = $obj->save_annotations(-reference=> ['70001:A01','70003:A01'], -annot_type=>'Sulston Score',-annot_value=>'80');
        is($result,1,'Stored annotation between two run/wells');

        $result = $obj->save_annotations(-reference=> ['70002:A01','70003:A01'], -annot_type=>'Sulston Score',-annot_value=>'30');
        is($result,1,'Stored annotation between two run/wells');

        $result = $obj->save_annotations(-reference=> ['70001:A01','70002:A01','70003:A01'], -annot_type=>'Sulston Score',-annot_value=>'29.234');
        is($result,1,'Stored annotation between three run/wells');

        $result = $obj->save_annotations(-reference=> ['70001:A01','70001:A01'], -annot_type=>'Sulston Score',-annot_value=>'0.3');
        is($result,1,'Stored annotation between two run/wells');

        $result = $obj->save_annotations(-reference=> ['70001:A01','70002:A01','70003:A01'], -annot_type=>'NON EXISTING TYPE',-annot_value=>'29.234');
        is($result,0,'Failed on non-existing type');


    }
}
TODO: {
if ( !$method || $method =~ /\bget_annotation_sets\b/ ) {
    can_ok("alDente::RunDataReference", 'get_annotation_sets');
    {
        $result = $obj->get_annotation_sets(-run_id=>79275, -annot_type=>'NON EXISTING TYPE');
        is($result,undef,'Non-existing type');
        
        $result = $obj->get_annotation_sets(-run_id=>79275,-well=>'A03',-annot_type=>'Sulston Score');
        my $ref = [
          {
            'annotation_id' => '186',
            'employee' => '120',
            'value' => '9e-36',
            'runs' => [
                        '79118',
                        '79275'
                      ],
            'type' => 'Sulston Score',
            'comments' => 'expected',
            'datetime' => '2008-02-22 16:40:17',
            'wells' => [
                         'G03',
                         'A03'
                       ]
          },
          {
            'annotation_id' => '455',
            'employee' => '120',
            'value' => '9e-36',
            'runs' => [
                        '79118',
                        '79275'
                      ],
            'type' => 'Sulston Score',
            'comments' => 'expected',
            'datetime' => '2008-02-22 17:54:55',
            'wells' => [
                         'G03',
                         'A03'
                       ]
          },
          {
            'annotation_id' => '7009',
            'employee' => '120',
            'value' => '9e-36',
            'runs' => [
                        '79118',
                        '79275'
                      ],
            'type' => 'Sulston Score',
            'comments' => 'expected',
            'datetime' => '2008-04-08 16:43:35',
            'wells' => [
                         'G03',
                         'A03'
                       ]
          }
        ];
        is_deeply($result,$ref,'Retrieved proper annotation value');

        $result = $obj->get_annotation_sets(-run_id=>79275,-well=>'C01',-annot_type=>'Sulston Score');
        $ref = [
          {
            'annotation_id' => '188',
            'employee' => '120',
            'value' => '0.5',
            'runs' => [
                        '79118',
                        '79275'
                      ],
            'type' => 'Sulston Score',
            'comments' => 'loading',
            'datetime' => '2008-02-22 16:40:20',
            'wells' => [
                         'G03',
                         'C01'
                       ]
          },
          {
            'annotation_id' => '457',
            'employee' => '120',
            'value' => '0.5',
            'runs' => [
                        '79118',
                        '79275'
                      ],
            'type' => 'Sulston Score',
            'comments' => 'loading',
            'datetime' => '2008-02-22 17:54:58',
            'wells' => [
                         'G03',
                         'C01'
                       ]
          },
          {
            'annotation_id' => '7011',
            'employee' => '120',
            'value' => '0.5',
            'runs' => [
                        '79118',
                        '79275'
                      ],
            'type' => 'Sulston Score',
            'comments' => 'loading',
            'datetime' => '2008-04-08 16:43:38',
            'wells' => [
                         'G03',
                         'C01'
                       ]
          }
        ];
        is_deeply($result,$ref,'Retrieved proper annotation value');


    }
}

if ( !$method || $method =~ /\b_get_annotation_id\b/ ) {
    can_ok("alDente::RunDataReference", '_get_annotation_id');
    {
        $result = $obj->_get_annotation_id(-reference=>['79118:G03','79275:C01'], -annot_type=>'Sulston Score');
        is($result,188,'Got correct annotation id');

        $result = $obj->_get_annotation_id(-reference=>['79118:G03','79275:A03'], -annot_type=>'Sulston Score');
        is($result,186,'Got correct annotation id');
    }
}

}
## END of TEST ##

ok( 1 ,'Completed RunDataReference test');

exit;
