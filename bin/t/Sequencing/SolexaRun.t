#!/usr/local/bin/perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Sequencing";
use lib $FindBin::RealBin . "/../../../lib/perl/Plugins";
use Test::Simple;
use Test::More qw(no_plan);  

use Test::MockModule;
use Test::Differences;
use Test::Exception;
use Test::Output;
use SDB::CustomSettings qw(%Configs);
use DBD::Mock;

BEGIN {
	use_ok("Sequencing::SolexaRun");  
    ### check that the module we're testing can be used
}



my $connection = SDB::DBIO->new( -dbase    => $Configs{UNIT_TEST_DATABASE},
                                 -host     => $Configs{UNIT_TEST_HOST},
                                 -user     => 'unit_tester',
                                 -password => 'unit_tester',
                                 -debug    => 1
                               );


$connection->connect();

use Data::Dumper;

# Run Tests
test_new();
test_request_broker();
test_create_Run();
test__Lanes_are_valid();

test__Flowcell_Code_is_valid();
test__Equipment_type_is_valid();
test_display_SolexaRun_form();
test_create_runs();


can_ok("Sequencing::SolexaRun",'get_taxonomy') ;
{
    my $run_id ='94667';
    my $taxonomy_id = Sequencing::SolexaRun::get_taxonomy(-run_id=>$run_id,-dbc=>$connection); 
    is ($taxonomy_id, "9606", "Taxonomy ID was returned");
}
exit;


# ============================================================================
# Tests
# ============================================================================

sub test_new {
    print "\nnew\n";

    can_ok( 'Sequencing::SolexaRun', 'new' );

    # define tests
    my @tests
        = (
            {
                equip => 1, lanes => 1,     flowcell => 1, expected_result => 1,
                desc  => "all valid args"
            },
            {
                equip => 1, lanes => undef, flowcell => 1, expected_result => 0,
                desc  => "invalid lanes"
            },
          );

    foreach my $test_ref (@tests) {
        my $equip           = $test_ref->{equip          };
        my $lanes           = $test_ref->{lanes          };
        my $flowcell        = $test_ref->{flowcell       };
        my $expected_result = $test_ref->{expected_result};
        my $desc            = $test_ref->{desc           };

        # mock response for valid lanes
        my $validation_module = new Test::MockModule('alDente::Validation');
        $validation_module ->mock( 'get_aldente_id',
                                   sub {
                                       return $lanes ? 1 : 0;
                                   }
                               );

        # mock response for valid equipment type
        my $sdb_module = new Test::MockModule('SDB::DBIO');

        $sdb_module->mock( 'Table_find',
                           sub {
                               return $equip ? 'solexa' : 'foo';
                           }
                         );

        # run test
        my $SolexaRun = Sequencing::SolexaRun->new( -dbc           => $connection,
                                                 -lanes         => [1,2,3,4,5,6,7,8],
                                                 -equipment     => '1234',
                                                 -flowcell_code => $flowcell ? 'FC123' : 'foo',
                                               );
        # check results
        if   ( $expected_result ) { isa_ok( $SolexaRun, 'Sequencing::SolexaRun' ); }
        else                      { ok( !$SolexaRun, $desc );                   }

    }
}

sub test_request_broker {
    print "\nrequest_broker\n";

    can_ok( 'Sequencing::SolexaRun', 'request_broker' );

}

sub test_create_Run {
    print "\ncreate_Run\n";

    can_ok( 'Sequencing::SolexaRun', 'create_Run' );

    {

        # mock response for valid lanes
        my $validation_module = new Test::MockModule('alDente::Validation');
        $validation_module ->mock( 'get_aldente_id', 1 );

        # mock response for valid equipment type
        my $sdb_module = new Test::MockModule('SDB::DBIO');

        $sdb_module->mock( 'Table_find', 'solexa' );

        my $SolexaRun = Sequencing::SolexaRun->new( -dbc    => $connection,
                                                 -lanes         => [
                                                     0,      141562,
                                                     141563, 0,
                                                     0,      0,
                                                     0,      0
                                                 ],
                                                 -equipment     => 1656,
                                                 -flowcell_code => 'FC123',
                                               );

        # turn off Table_find mock sub
        $sdb_module->unmock('Table_find');

        # createRun succeeds, extra attributes valid
        my $run_options
            = {
                "Run.Run_Type"        => 'SolexaRun',
                "Run.FK_Plate__ID"    => '65432',
                "Run.FK_RunBatch__ID" => '12345',
                "Run.Run_DateTime"    => '',
                "Run.Run_Test_Status" => 'Test',
                "Run.Run_Directory"   => '/home/' . time(),
                "SolexaRun.FK_Flowcell__ID" => '122',
                "SolexaRun.Lane"      => '1'
            };

        my $actual_result = $SolexaRun->create_Run( -run_options => $run_options );

        ok( $actual_result, 'valid parameters' );

    }
}

sub test_create_runs {
    print "\ncreate_Runs\n";

	require Sequencing::SolexaRun;
    can_ok( 'Sequencing::SolexaRun', 'create_Runs' );
}

sub test__Lanes_are_valid {
    print "\n_Lanes_are_valid\n";

    can_ok( 'Sequencing::SolexaRun', '_Lanes_are_valid');

    # lanes are all valid
    {
        my $module = new Test::MockModule('alDente::Validation');

        $module->mock( 'get_aldente_id', 1 );

        my $expected_result = 1;
        my $actual_result   = Sequencing::SolexaRun::_Lanes_are_valid( -lanes => [ 1, 2, 3, 4, 5, 6, 7, 8 ],
                                                                    -dbc   => $connection
                                                                  );

        ok ($actual_result eq $expected_result, "lanes are all valid");

    }


    # lanes are invalid
    {
        my $module = new Test::MockModule('alDente::Validation');

        $module->mock( 'get_aldente_id', 0 );

        my $expected_result = 0;
        my $actual_result   = Sequencing::SolexaRun::_Lanes_are_valid( -lanes => [ 1, 2, 3, 4, 5, 6, 7, 8 ],
                                                                    -dbc   => $connection
                                                                  );

        ok ($actual_result eq $expected_result, "lanes are all invalid");

    }

    # more than 8 lanes given
    {
        my $expected_result = 0;
        my $actual_result   = Sequencing::SolexaRun::_Lanes_are_valid( -lanes => [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
                                                                    -dbc   => $connection
                                                                  );

        ok ($actual_result eq $expected_result, "too many lanes");

    }

    # fewer than 8 lanes given
    {
        my $expected_result = 0;
        my $actual_result   = Sequencing::SolexaRun::_Lanes_are_valid( -lanes => [ 1, 2, 3, 4, 5, 6, 7 ],
                                                                    -dbc   => $connection
                                                                  );

        ok ($actual_result eq $expected_result, "too few lanes");

    }

}



sub test__Flowcell_Code_is_valid {
    print "\n_Flowcell_Code_is_valid\n";

    can_ok( 'Sequencing::SolexaRun', '_Flowcell_Code_is_valid' );

    my @tests
        = (
# change to new format once only new flowcells are being received           
	    [ 'FC123',  1, 'valid flowcell number'                      ],
        [ undef,    0, 'undefined value'                            ],
        );

    foreach my $test_ref (@tests) {
        my ( $flowcell_code, $expected_result, $desc ) = @{ $test_ref };

        my $actual_result = Sequencing::SolexaRun::_Flowcell_Code_is_valid( $flowcell_code );

        ok( $actual_result eq $expected_result, $desc );
    }
}



sub test__Equipment_type_is_valid {
    print "\n_Equipment_type_is_valid\n";

    can_ok( 'Sequencing::SolexaRun', '_Equipment_type_is_valid' );

    my @tests
        = (
            [ 'Genome Analyzer',  1 ],
            [ 'Genome AnalYzer',  1 ],
            [ 'foo',     0 ],
            [ 'undef',   0 ],
          );

    foreach my $test_ref (@tests) {
        my ( $equipment_type, $expected_result ) = @{$test_ref};

        my $module = new Test::MockModule('SDB::DBIO');

        $module->mock( 'Table_find', $equipment_type );

        my $actual_result = Sequencing::SolexaRun::_Equipment_type_is_valid( -dbc          => $connection,
                                                                          -equipment_id => 5
                                                                        );

        ok( $actual_result eq $expected_result, "equipment type: $equipment_type" );
    }

}

sub test_display_SolexaRun_form {
    print "\ndisplay_SolexaRun_form\n";

    can_ok( 'Sequencing::SolexaRun', 'display_SolexaRun_form' );

    my $SolexaRun = Sequencing::SolexaRun->new( -dbc    => $connection,
                                             -lanes         => [
                                                 0,      141562,
                                                 141563, 0,
                                                 0,      0,
                                                 0,      0
                                             ],
                                             -equipment     => 1,
                                             -flowcell_code => 5,
                                         );

    {
        my $actual_return;
        stdout_like( sub { $actual_return
                               = Sequencing::SolexaRun::display_SolexaRun_form( -equipment_id => 1657,
                                                                             -plate_ids    => [ 141562, 141563 ],
                                                                             -tray_id      => 8918,
                                                                             -dbc          => $connection
                                                                         );
                       },
                     qr/.*/, "catching output");

        ok( $actual_return, "displayed form without error" );
    }

    {
        # return multiple plates with same lane
        my $dbio_module = new Test::MockModule('SDB::DBIO');

        $dbio_module->mock( 'Table_find', 5 );

        stdout_like (
            sub {
                lives_ok (
                    sub {
                        Sequencing::SolexaRun::display_SolexaRun_form( -equipment_id => 1657,
                                                                    -plate_ids    => [ 141562, 141563 ],
                                                                    -tray_id      => 8918,
                                                                    -dbc          => $connection
                                                                )
                      },
                    "multiple plates with same lane"
                );
            },
            qr/.*/, "catching output"
        );
    }

    {
        my $dbio_module = new Test::MockModule('SDB::DBIO');

        my $lane_index = 0;
        $dbio_module->mock( 'Table_find',
                            sub {
                                $lane_index++;
                                return $lane_index;
                            }
                        );

        stdout_like (
            sub {
                lives_ok(
                    sub {
                        Sequencing::SolexaRun::display_SolexaRun_form( -equipment_id => 1657,
                                                                    -plate_ids    => [
                                                                        141562, 141563, 141564, 141565,
                                                                        141566, 141567, 141568, 141569,
                                                                        141570
                                                                    ],
                                                                    -tray_id      => 8918,
                                                                    -dbc   => $connection
                                                                )
                      },
                    "more than 8 lanes"
                );
            },
            qr/.*/, "catching output"
        );
    }
}


