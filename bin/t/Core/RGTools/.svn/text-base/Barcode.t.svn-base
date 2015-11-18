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


my $TEST_DATAFILE = $FindBin::RealBin . "/../../../../conf/barcodes.dat";

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test

## Default settings from Barcode.pm ##
my %Default;
$Default{height} = 0.75;
$Default{width } = 2.25;
$Default{zero_x} = 25;
$Default{zero_y} = 25;
$Default{top} = 15;

## sample values ##
my @names  = ( 'name1',  'name2' );
my @values = ( 'value1', 'value2' );

my ( $posx,  $posy,  $size )  = ( 5, 10, 20 );
my ( $posx2, $posy2, $size2 ) = ( 6, 11, 21 );

my $testlabels = {
    '-name'  => $names[0],
    '-value' => $values[0],
    '-posx'  => $posx,
    '-posy'  => $posy,
    '-size'  => $size,
};

my $testlabels2 = {
    '-value' => $values[1],
    '-posx'  => $posx2,
    '-posy'  => $posy2,
    '-size'  => $size2,
};

sub self {
    my %override_args = @_;
    my %args;

    # Set default values
    $args{-type       } = defined $override_args{-type       } ? $override_args{-type       } : "";
    $args{-id         } = defined $override_args{-id         } ? $override_args{-id         } : "";
    $args{-labels     } = defined $override_args{-labels     } ? $override_args{-labels     } : "";
    $args{-height     } = defined $override_args{-height     } ? $override_args{-height     } : "";
    $args{-width      } = defined $override_args{-width      } ? $override_args{-width      } : "";
    $args{-zero_x     } = defined $override_args{-zero_x     } ? $override_args{-zero_x     } : "";
    $args{-zero_y     } = defined $override_args{-zero_y     } ? $override_args{-zero_y     } : "";
    $args{-top        } = defined $override_args{-top        } ? $override_args{-top        } : "";
    $args{-dpi        } = defined $override_args{-dpi        } ? $override_args{-dpi        } : "";
    $args{-printer_dpi} = defined $override_args{-printer_dpi} ? $override_args{-printer_dpi} : "";

    return new RGTools::Barcode(%args);

}


############################################################
BEGIN { use_ok("RGTools::Barcode"); }


if ( !$method || $method =~ /\bBarcode::DESTROY\b/ ) {
    can_ok("Barcode", 'Barcode::DESTROY');
    {
        ## <insert tests for Barcode::DESTROY method here> ##
    }
}

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Barcode", 'new');
    {
        ## <insert tests for new method here> ##
        
        $barcode = new Barcode( -type => 'undefined_type' ,-datafile=>$TEST_DATAFILE);
        print Dumper $barcode;
        ok( !$barcode->{id}, 'undefined type fails' );

        $barcode = new Barcode( -labels => 'improper label format',-datafile=>$TEST_DATAFILE );
        ok( !$barcode, 'improper label format' );

    }
}

if ( !$method || $method =~ /\bload_from_file\b/ ) {
    can_ok("Barcode", 'load_from_file');
    {
        ## <insert tests for load_from_file method here> ##
        my $barcode = new Barcode(-labels => $testlables,-datafile=>$TEST_DATAFILE);
        my ( $type, $class, $height ) = ( 'tube_solution_2D', 'SOL', '0.60' ); ## sample values

        $barcode->load_from_file($type,$TEST_DATAFILE);
        ok( $barcode, 'loaded correctly from file' );

        is( $barcode->{fields}{'class'}{'sample'}, $class, 'loaded sample barcode label type' );

        is( $barcode->{height}, $height, 'set default height' );

        ok( !$barcode->_validate, 'still undefined values from file failed to validate' );
    }
}

if ( !$method || $method =~ /\bspecify_labels\b/ ) {
    can_ok("Barcode", 'specify_labels');
    {
        ## <insert tests for specify_labels method here> ##



        $barcode = new Barcode(-datafile=>$TEST_DATAFILE);
        ok( $barcode->specify_labels( -labels => [$testlabels] ), 'ran specfiy_labels ok' );

        is( $barcode->{fields}{ $names[0] }{'value'}, $values[0], "set value correctly" );

        ok( $barcode->specify_labels( -labels => [$testlabels2] ), 'ran specfiy_labels ok' );

        is( $barcode->{fields}{'L1'}{'value'}, $values[1], "set default label name with corresponding value" );
    }
}

if ( !$method || $method =~ /\bset_fields\b/ ) {
    can_ok("Barcode", 'set_fields');
    {
        ## <insert tests for set_fields method here> ##
    }
}

if ( !$method || $method =~ /\bget_fields\b/ ) {
    can_ok("Barcode", 'get_fields');
    {
        ## <insert tests for get_fields method here> ##
    }
}

if ( !$method || $method =~ /\bmake_zpl\b/ ) {
    can_ok("Barcode", 'make_zpl');
    {
        ## <insert tests for make_zpl method here> ##
        my $barcode = new Barcode( -top=>$Default{top},-labels => [$testlabels] ,-datafile=>$TEST_DATAFILE);
        ok( $barcode->make_zpl(), 'make zpl works correctly' );

        $barcode->{fields}{'name1'}{'posx'} = undef; ## remove posx setting
        ok( !$barcode->make_zpl, 'make_zpl fails if missing field' );

        my $bctext                       = $values[1]; ## look at second label ##
        $barcode->{fields}{'name1'}{'posx'} = $posx2;
        my $barcode_posy2                = $posy2 + $Default{top};
    
        $barcode->specify_labels( -labels => [$testlabels2] );
        ok( $barcode->make_zpl =~ /\^FO$posx2,$posy2\^A0N,$size2\^FH\+\^FD$bctext\^FS/,
            "found standard string ($bctext) text at $posx2,$posy2 ($size2)" );

## Barcode positions are NOT (?) relative to top but absolute (may wish to check this, but the code implies this) ##
        ok(
            !( $barcode->make_zpl =~ /\^FO$posx2,(\S+)\^BCN,$size2,N,N,N,N\^FD$bctext\^FS/ ),
            " NOT code128 style ($posx2,$posy2^BCN,$size2,N,N,N,N^FD$bctext^FS)" );

        ok(
            !( $barcode->make_zpl =~ /\^FO$posx2,(\S+)\^BXN,$size2,200,,,,\^FD$bctext^FS/ ),
            'NOT datamatrix style' );

        $barcode->{fields}{'L1'}{'style'} = 'code128';
        my $zpl = $barcode->make_zpl;
        ok( $barcode->make_zpl =~ /\^FO$posx2,(\S+)\^BCN,$size2,N,N,N,N\^FD$bctext\^FS/,
            "code128 style ($posx2, $posy2, $size2, $bctext)") || print $barcode->make_zpl;

        $barcode->{fields}{'L1'}{'style'} = 'datamatrix';
        ok( $barcode->make_zpl =~ /\^FO$posx2,(\S+)\^BXN,$size2,200,,,,\^FD$bctext\^FS/,
            "datamatrix style at $posx2,$posy2 (size=$size2; value=$bctext)") || $barcode->make_zpl;   ## y position is increased by top + screensize
    }
}

if ( !$method || $method =~ /\blprprint\b/ ) {
    can_ok("Barcode", 'lprprint');
    {
        ## <insert tests for lprprint method here> ##
    }
}

if ( !$method || $method =~ /\bmakepng\b/ ) {
    can_ok("Barcode", 'makepng');
    {
        ## <insert tests for makepng method here> ##
    }
}

if ( !$method || $method =~ /\bprintpng\b/ ) {
    can_ok("Barcode", 'printpng');
    {
        ## <insert tests for printpng method here> ##
    }
}

if ( !$method || $method =~ /\bget_attribute\b/ ) {
    can_ok("Barcode", 'get_attribute');
    {
        ## <insert tests for get_attribute method here> ##
    }
}

if ( !$method || $method =~ /\bset_attribute\b/ ) {
    can_ok("Barcode", 'set_attribute');
    {
        ## <insert tests for set_attribute method here> ##
    }
}

if ( !$method || $method =~ /\bget_field_attribute\b/ ) {
    can_ok("Barcode", 'get_field_attribute');
    {
        ## <insert tests for get_field_attribute method here> ##
    }
}

if ( !$method || $method =~ /\bset_field_attribute\b/ ) {
    can_ok("Barcode", 'set_field_attribute');
    {
        ## <insert tests for set_field_attribute method here> ##
    }
}

if ( !$method || $method =~ /\bestablish_printer\b/ ) {
    can_ok("Barcode", 'establish_printer');
    {
        ## <insert tests for establish_printer method here> ##
    }
}

if ( !$method || $method =~ /\bdump_format\b/ ) {
    can_ok("Barcode", 'dump_format');
    {
        ## <insert tests for dump_format method here> ##
    }
}

if ( !$method || $method =~ /\b_is_valid\b/ ) {
    can_ok("Barcode", '_is_valid');
    {
        ## <insert tests for _is_valid method here> ##
    }
}

if ( !$method || $method =~ /\b_ZPLtoScreenScale\b/ ) {
    can_ok("Barcode", '_ZPLtoScreenScale');
    {
        ## <insert tests for _ZPLtoScreenScale method here> ##
    }
}

if ( !$method || $method =~ /\b_ZPLtoScreen\b/ ) {
    can_ok("Barcode", '_ZPLtoScreen');
    {
        ## <insert tests for _ZPLtoScreen method here> ##
    }
}

if ( !$method || $method =~ /\b_Accounting\b/ ) {
    can_ok("Barcode", '_Accounting');
    {
        ## <insert tests for _Accounting method here> ##
    }
}

if ( !$method || $method =~ /\b_Message\b/ ) {
    can_ok("Barcode", '_Message');
    {
        ## <insert tests for _Message method here> ##
    }
}

if ( !$method || $method =~ /\b_validate\b/ ) {
    can_ok("Barcode", '_validate');
    {
        ## <insert tests for _validate method here> ##
    }
}

if ( !$method || $method =~ /\b_validate_field\b/ ) {
    can_ok("Barcode", '_validate_field');
    {
        ## <insert tests for _validate_field method here> ##
    }
}

if ( !$method || $method =~ /\bPause\b/ ) {
    can_ok("Barcode", 'Pause');
    {
        ## <insert tests for Pause method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Barcode test');

exit;


=comment
##################
    my $self = shift;

    my $barcode;

    ## test new ##
    $barcode = new Barcode( -type => 'undefined_type' ,-datafile=>$TEST_DATAFILE);
    ok( !$barcode, 'undefined type fails' );

    $barcode = new Barcode( -labels => 'improper label format',-datafile=>$TEST_DATAFILE );
    ok( !$barcode, 'improper label format' );


    ## test load_from_file
    $barcode = new Barcode(-datafile=>$TEST_DATAFILE);
    my ( $type, $class, $height ) =
      ( 'tube_solution_2D', 'SOL', '0.60' );    ## sample values

    $barcode->load_from_file($type);
    ok( $barcode, 'loaded correctly from file' );
    is( $barcode->{fields}{'class'}{'sample'},
        $class, 'loaded sample barcode label type' )
      or carp Dumper($barcode);
    is( $barcode->{height}, $height, 'set default height' );
    ok( !$barcode->_validate,
        'still undefined values from file failed to validate' )
      or carp Dumper($barcode);


## test specify_labels

    ## sample values ##
    my @names  = ( 'name1',  'name2' );
    my @values = ( 'value1', 'value2' );
    my ( $posx,  $posy,  $size )  = ( 5, 10, 20 );
    my ( $posx2, $posy2, $size2 ) = ( 6, 11, 21 );
    my $testlabels = {
        '-name'  => $names[0],
        '-value' => $values[0],
        '-posx'  => $posx,
        '-posy'  => $posy,
        '-size'  => $size,
    };

    my $testlabels2 = {
        '-value' => $values[1],
        '-posx'  => $posx2,
        '-posy'  => $posy2,
        '-size'  => $size2,
    };
    ###

    $barcode = new Barcode(-datafile=>$TEST_DATAFILE);
    ok( $barcode->specify_labels( -labels => [$testlabels] ),
        'ran specfiy_labels ok' );
    is( $barcode->{'top'}, $Default{top}, 'set attribute to default value' )
      or carp Dumper($barcode);
    is( $barcode->{fields}{ $names[0] }{'value'},
        $values[0], "set value correctly" )
      or carp Dumper($barcode);

    ok( $barcode->specify_labels( -labels => [$testlabels2] ),
        'ran specfiy_labels ok' );
    is( $barcode->{fields}{'L1'}{'value'},
        $values[1], "set default label name with corresponding value" )
      or carp Dumper($barcode);


    ## test make_zpl ##
    ok( $barcode->make_zpl, 'make zpl works correctly' );
    $barcode->{fields}{'L1'}{'posx'} = undef;    ## remove posx setting
    ok( !$barcode->make_zpl, 'make_zpl fails if missing field' )
      or carp Dumper($barcode);

    my $bctext = $values[1];                     ## look at second label ##
    $barcode->{fields}{'L1'}{'posx'} = $posx2;

    my $barcode_posy2 = $posy2 + $Default{top};

    ok(
        $barcode->make_zpl =~ /\^FO$posx2,$posy2\^A0N,$size2\^FD$bctext\^FS/,
        "found standard string ($bctext) text at $posx2,$posy2 ($size2)"
    ) or carp Dumper( $barcode, $barcode->make_zpl );
    ok(
        !(
            $barcode->make_zpl =~
            /\^FO$posx2,$barcode_posy2\^BCN,$size2,N,N,N,N\^FD$bctext\^FS/
        ),
        ' NOT code128 style'
    ) or carp Dumper( $barcode, $barcode->make_zpl );
    ok(
        !(
            $barcode->make_zpl =~
            /\^FO$posx2,$barcode_posy2\^BXN,$size2,200,,,,\^FD$bctext^FS/
        ),
        'NOT datamatrix style'
    ) or carp Dumper( $barcode, $barcode->make_zpl );
    $barcode->{fields}{'L1'}{'style'} = 'code128';
    ok(
        $barcode->make_zpl =~
          /\^FO$posx2,$barcode_posy2\^BCN,$size2,N,N,N,N\^FD$bctext\^FS/,
        "code128 style ($posx2,$barcode_posy2,$size2,$bctext"
    ) or carp Dumper( $barcode, $barcode->make_zpl );
    $barcode->{fields}{'L1'}{'style'} = 'datamatrix';
    ok(
        $barcode->make_zpl =~
          /\^FO$posx2,(\S+)\^BXN,$size2,200,,,,\^FD$bctext\^FS/,
        "datamatrix style at $posx2,$barcode_posy2 (size=$size2; value=$bctext)"
      )
      or carp Dumper( $barcode, $barcode->make_zpl )
      ;    ## y position is increased by top + screensize


    ## test actual barcode sample output ##
    $barcode = new Barcode( -type => 'ge_tube_barcode_2D' ,-datafile=>$TEST_DATAFILE);
    ok( $barcode->set_fields( -sample => 1 ), "set fields with sample" )
      or print Dumper $barcode;
    my $top_pos = 20;
    my $top_xy  = "10,0";

    my %Label;
    $Label{id}    = [ 110, 30, 20, 432 ];
    $Label{class} = [ 70,  30, 20, 'PLA' ];

    print Dumper $barcode;
    my $zpl = $barcode->make_zpl;
    ok( $zpl =~ /\^LT(\S+)\^LH([\d\,]+)/, "top position and x,y zero set" );
    is( $1, $top_pos, " top position set correctly" ) or carp Dumper $zpl;
    is( $2, $top_xy,  " top x,y zero set correctly" ) or carp Dumper $zpl;

    foreach my $field ( keys %Label ) {
        ok(
            $zpl =~
/\^FO$Label{$field}[0]\,$Label{$field}[1]\^A0N,(\d+)\^FD(\S+?)\^FS/,
            "$field label found"
        );
        my $size  = $1;
        my $value = $2;
        ok( $size && $value,
            "size, value found for label at specified x,y position" );
        is( $size, $Label{$field}[2],
"Size set correctly for $field at $Label{$field}[0],$Label{$field}[1]"
        ) or carp Dumper($zpl);
        is( $value, $Label{$field}[3], "Value set correctly for $field" )
          or carp Dumper($zpl);
    }

    $Label{barcode} = [ 10, 0, 4, 'Pla432' ];
    ok( $zpl =~ /\^BY2,3.0,10\^FO(\d+),(\d+)\^BXN,(\d+),200,,,,\^FD(\S+)\^FS/,
        "datamatrix label generated" );
    my $xpos  = $1;
    my $ypos  = $2;
    $size  = $3;
    my $value = $4;
    print "** X,Y = $xpos, $ypos (-$barcode->{screensize}) ($size; $value)\n";
    ok( $xpos && $ypos && $size && $value, "barcode found in zpl" );
    is( $xpos, $Label{barcode}[0], "x position correct for barcode" );
    is( $ypos, $Label{barcode}[1] + $top_pos,
        "y position correct for barcode" );
    is( $size,  $Label{barcode}[2], "size correct for barcode" );
    is( $value, $Label{barcode}[3], "value correct for barcode" );

#  class         [a-zA-Z0-9]{3}                70,30     20      caps,s="PLA"
#  id            [0-9]{1,10}                   110,30    20      s="432",nopad
#  barcode       [a-zA-Z]{3}\d{1,9}          10,0        4       s="Pla432",zeropad=10   datamatrix
#  plateid       [a-zA-Z0-9]{5,6}(_|\-)\d{1,4} 70,0      28      caps,s="cn001_232"
#  p_code        \w{0,1}         13,60     30    caps,s="Sq"
#  p2_code       \w{0,2}         32,60     20    caps,s="q"
#  b_code        \w{0,5}         13,90     20    caps,s="T7"
#  date          \d{2,4}-\d{2}-\d{2}           70,53     23      caps,s="today"
#  init          [a-zA-Z]{1,3}                 200,53    23      caps,s="jrs"
#  ors_name      .{1,10}                       70,78     23      caps,s="ors"
#  plateid_tube  [a-zA-Z0-9]{5,6}(_|\-)\d{1,4} 295,42    25      caps,s="cn001_232"
#  init_tube     [a-zA-Z]{2,3}                 340,75    20      caps,s="jrs"
#  class_tube    [a-zA-Z0-9]{3}                317,12    20      caps,s="PLA"
#  id_tube       [0-9]{1,10}                   349,12    20      s="432",nopad
#

    ## test loading of standard label type directly from object constructor ##
    $barcode = new Barcode( -type => $type ,-datafile=>$TEST_DATAFILE);
    ok( $barcode, 'loaded correctly from file' );
    is( $barcode->{fields}{'class'}{'sample'},
        $class, 'loaded sample barcode label type' )
      or carp Dumper($barcode);
    is( $barcode->{height}, $height, 'set to default height' )
      or carp Dumper($barcode);
    ok( !$barcode->_validate,
        'undefined values from standard type failed to validate' )
      or carp Dumper($barcode);

    $barcode = new Barcode( -labels => [ 1, 2 ] ,-datafile=>$TEST_DATAFILE);
    ok( !$barcode, 'improper label format' );

    $barcode = new Barcode(
        -labels => [
            {
                'name'  => 'label1',
                'value' => 'hello',
                'style' => 'code39',
            },
        -datafile=>$TEST_DATAFILE
        ]
    );
    ok( $barcode, 'proper label format' );

    $barcode = new Barcode(-datafile=>$TEST_DATAFILE);
    ok( $barcode, 'empty but successful' );

    ## test validate script ##
    ok( !$barcode->_validate, 'empty barcode NOT valid' )
      or carp Dumper($barcode);
    foreach my $field (@mandatory_keys) {
        $barcode->{fields}{'L1'}{$field} = '1';
    }
    foreach my $field (@mandatory_attributes) {
        $barcode->{$field} = '1';
    }
    ok( $barcode->_validate,
        'valid as long as mandatory fields and attributes are set' )
      or carp Dumper($barcode);
    $barcode->{fields}{'L1'}{'value'} = undef;
    ok( !$barcode->_validate,
        'invalid as long as mandatory fields and attributes are set' )
      or carp Dumper($barcode);
    $barcode->{fields}{'L1'}{'value'} = '1';
    $barcode->{fields}{'L1'}{'format'} =
      "[a-z]";    ## set format that will fail for current value
    ok( !$barcode->_validate, 'invalid format fails validation' )
      or carp Dumper($barcode);
    $barcode->{fields}{'L1'}{'format'} =
      "[1-9]";    ## set format that will fail for current value
    ok( $barcode->_validate, 'format now agrees with value' )
      or carp Dumper($barcode);

    ## test set_attributes ##
    ok( !$barcode->set_attribute( '', 'hello' ), 'attribute must have name' );
    ok( $barcode->set_attribute( 'test', 'hello' ), 'set_attribute passes' );
    is( $barcode->{'test'}, 'hello', 'set attribute correctly' )
      or carp Dumper($barcode);

    ## test set_fields with sample ##
    $barcode->set_fields( -sample => 1 );
    ok( $barcode->_validate, 'sample label validated' )
      or carp Dumper($barcode);

    ## test set_fields with actual fields ##
    $barcode = new Barcode(-datafile=>$TEST_DATAFILE);    ## this type requires class,id, barcode, text
    ok(
        !$barcode->set_fields(
            'id'      => 5,
            'class'   => 'TST',
            'barcode' => '123',
            'text'    => 'hellow',
        ),
        'no type specified generates failure in set_fields fails'
    );

    $barcode =
      new Barcode( -type => 'barcode1',-datafile=>$TEST_DATAFILE )
      ;    ## this type requires class,id, barcode, text
    ok(
        !$barcode->set_fields(
            'id'      => 5,
            'class'   => 'TST',
            'barcode' => '123',
            'text'    => 'hellow',
        ),
        'invalid format in set_fields fails'
    );

    ok(
        $barcode->set_fields(
            'id'      => 5,
            'class'   => 'TST',
            'barcode' => 'Pla123',
            'text'    => 'hello',
        ),
        'valid format in set_fields passes'
    );

    is( $barcode->{fields}{'class'}{'value'}, 'TST' ) or carp Dumper($barcode);

    #    ok( !$barcode->set_fields(), 'set_fields fails - no fields set');

    #    $barcode->set_fields(('id'=>5));
    is( $barcode->{fields}{'class'}{'value'}, 'TST', 'value set as specified' )
      or carp Dumper($barcode);
    is( $barcode->{fields}{'id'}{'value'}, 5, 'value set as specified' )
      or carp Dumper($barcode);

    ## test explicit label specification ##
    my $label1 = {
        '-posx' => 5,
        '-posy' => 5,
        '-size' => 30,
    };
    my $label2 = {
        '-name'  => 'label2',
        '-style' => 'code128',
        '-value' => 'testlabel',
        '-posx'  => 15,
        '-posy'  => 15,
        '-size'  => 40,
    };

    $barcode = new Barcode( -labels => [ $label1, $label2 ],-datafile=>$TEST_DATAFILE );
    ok( $barcode, 'incomplete, but still defined successfully' );
    ok( !$barcode->_validate, "Incomplete input" )
      or carp Dumper($barcode);    ## missing value for label1

    ## fill in missing value ##
    $barcode->{fields}{'L1'}{'value'} = 'setvalue';
    ok( $barcode->_validate, 'defined label' ) or carp Dumper($barcode);

    ## test get_fields ##
    my $field_list = join ',', $barcode->get_fields;
    is( $field_list, 'label2,L1', 'field names extracted correctly' )
      or carp Dumper($barcode);

    ## test set_field_attribute ##
    ok(
        !$barcode->set_field_attribute( '', 'value', 'FL' ),
        'set_field_attribute fails - invalid field'
    );
    ok(
        !$barcode->set_field_attribute( 'class', '', 'FL' ),
        'set_field_attribute fails - invalid attribute'
    );
    ok( $barcode->set_field_attribute( 'class', 'value', 'FL' ),
        'set_field_attribute succeeds' );    ## reset class field value to fail

    is( $barcode->{fields}{'class'}{'value'},
        'FL', 'set field attribute correctly' )
      or carp Dumper($barcode);

    ## test get_field_attribute ##
    my $attr;
    $barcode->{fields}{'class'}{'format'} = '[abc]';
    ok( !($attr = $barcode->get_field_attribute( '', 'format' ) ),
        'get_field_attribute fails - no field' );
    ok( !($attr = $barcode->get_field_attribute( 'class', '' ) ),
        'get_field_attribute fails - no attribute' );
    ok( ($attr = $barcode->get_field_attribute( 'class', 'format' ) ),
        'get_field_attribute runs' );
    is( $barcode->get_field_attribute( 'class', 'format' ),
        '[abc]', 'correctly retrieved field attribute' )
      or carp Dumper($barcode);

    ## test get_attribute ##
    $barcode->{'junk_attribute'} = 123;
    ok(
        !($attr = $barcode->get_attribute('') ),
        'get_field_attribute fails - no attribute'
    );
    ok( ($attr = $barcode->get_attribute('junk_attribute') ),
        'get_field_attribute runs' );
    is( $barcode->get_attribute('junk_attribute'),
        '123', 'attribute retrieved correctly' )
      or carp Dumper($barcode);
    is( $barcode->get_attribute('junk_attribute2'),
        undef, 'attribute retrieved correctly' )
      or carp Dumper($barcode);

    ## test establish printer method ##
    ok( !$barcode->establish_printer(''),        'blank printer fails' );
    ok( !$barcode->establish_printer('garbage'), 'invalid printer name fails' );
    ok( !$barcode->establish_printer,            'undef printer name fails' );
    ok( $barcode->establish_printer('orbita'),   'valid printer succeeds' );
    is( $barcode->get_attribute('printer'), 'orbita', 'printer set correctly' )
      or carp Dumper($barcode);

    return 'completed';
}
=cut

