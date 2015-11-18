package alDente::Barcode;

use base LampLite::Barcode;
use strict;

use Date::Calc qw(Today Add_Delta_Days);
use POSIX qw(strftime);
use Time::HiRes qw(gettimeofday tv_interval);
use Carp;
use Data::Dumper;

##   ####
##   # <SYNOPSIS>
#
# used to initialize custom settings only
#
# See Barcode.pm base module
##

my $LOGFILE  = "/home/aldente/public/logs/barcode.log";
my $LPRQUEUE = "zp1";

## Default settings ##
my %Default;
$Default{height} = 0.75;
$Default{width}  = 2.25;
$Default{zero_x} = 25;
$Default{zero_y} = 25;
$Default{top}    = 15;

# Printer resolution - DO NOT CHANGE THIS
$Default{DPI}         = 200;    ## default scale DPI
$Default{printer_DPI} = 200;    ## default printer DPI

my $Large = {
    'label_format_id' => 1,      ## probably better to change to 'LARGE_LABEL_PRINTER', but for testing this is okay...
    'height'          => 0.75,
    'width'           => 2.25,
    'zero_x'          => 10,
    'zero_y'          => 10,
    'top'             => 10,
    'dpi'             => 200,
    'printer_dpi'     => 200,

    'barcode' => {
        'posx'  => 80,
        'posy'  => 0,
        'size'  => 40,
        'style' => 'code128'
    }
};

my $Small = {
    'label_format_id' => 3,
    'height'          => 0.75,
    'width'           => 2.25,
    'zero_x'          => 10,
    'zero_y'          => 10,
    'top'             => 10,
    'dpi'             => 200,
    'printer_dpi'     => 200,

    'barcode' => {
        'posx'  => 20,
        'posy'  => 0,
        'size'  => 20,
        'style' => 'code128'
    }
};

my $Two_D = {
    'label_format_id' => '4',
    'height'          => 0.75,
    'width'           => 2.25,
    'zero_x'          => 10,
    'zero_y'          => 10,
    'top'             => 10,
    'dpi'             => 200,
    'printer_dpi'     => 200,

    'barcode' => {
        'posx'  => 5,
        'posy'  => 0,
        'size'  => 5,
        'style' => 'datamatrix'
    },
};

my $Class = {
    'large' => $Large,
    'small' => $Small,
    '2D'    => $Two_D
};

#  my $Large_Label_Printer = "zp1";

# Screen resolution - ALTER IF REQUIRED. Use 72 for a 1:1 size ratio between
# the label and the screen image. Use > 72 for larger labels on the screen, and
# < 72 for smaller ones. Because the screen DPI is less than the printers, some
# small text will not be clear on the screen if DPIs=72.
my $DPIs = 100;

my @std_keys             = qw(name format style posx posy size opts value barcode sample);
my @mandatory_keys       = qw(posx posy size value);
my @mandatory_attributes = qw(height zero_x zero_y top);

{
    my %_attrs = (
        _id      => 'read',
        _comment => 'read/write',
        _fields  => 'read',
        _height  => 'read/write',
        _width   => 'read/write',
        _valid   => 'read/write',
        _zero_x  => 'read/write',
        _zero_y  => 'read/write',
        _top     => 'read/write',
    );
}

######################
sub Barcode_Prefix {
######################
    my $dbc = shift;
    my $type = shift;
    
    my $prefix = $dbc->config('Barcode_Prefix');
    if ($prefix && $type) {
        if (defined $prefix->{$type}) { return $prefix->{$type} }
    }
    elsif ($prefix) {
        return $prefix;
    }
    
    return;
}

#############################
sub load_standard_classes {
#############################
    my $l_count = shift;                ## number of strings on left side
    my $r_count = shift;    ## number of strings on right side

    if (!defined $l_count ) { $l_count = 2 }
    if (!defined $r_count ) { $r_count = 2 }

    my $Std_Class = $Class;

    ## try to divide available size by number of strings to print
    foreach my $i ( 1 .. $l_count ) {

        ### Extra Large Labels ###
        $Std_Class->{'large'}{"l_text$i"} = {
            'posx' => 0,
            'posy' => 10 + ( $i - 1 ) * ( 100 / $l_count ),
            'size' => 60 - ( $i - 1 ) * 10,
            'style' => 'text'
        };
        ### Extra Small Labels ###
        $Std_Class->{'small'}{"l_text$i"} = {
            'posx' => 20,
            'posy' => 5 + ( $i - 1 ) * ( 100 / $l_count ),
            'size' => 20 - ( $i - 1 ) * 4,
            'style' => 'text'
        };
        ### Extra 2D Labels ###
        $Std_Class->{'2D'}{"l_text$i"} = {
            'posx' => 25,
            'posy' => 10 + ( $i - 1 ) * ( 100 / $l_count ),
            'size' => 5 - ( $i - 1 ) * 2,
            'style' => 'text'
        };
    }

    foreach my $i ( 1 .. $r_count ) {
        $Std_Class->{'large'}{"r_text$i"} = {
            'posx' => 200,
            'posy' => 5 + ( $i - 1 ) * ( 100 / $r_count ),
            'size' => 20 - ( $i - 1 ) * 5,
            'style' => 'text'
        };
        $Std_Class->{'small'}{"r_text$i"} = {
            'posx' => 250,
            'posy' => 0 + ( $i - 1 ) * ( 100 / $r_count ),
            'size' => 20 - ( $i - 1 ) * 4,
            'style' => 'text'
        };
        $Std_Class->{'2D'}{"r_text$i"} = {
            'posx' => 250,
            'posy' => 5 + ( $i - 1 ) * ( 100 / $r_count ),
            'size' => 20 - ( $i - 1 ) * 2,
            'style' => 'text'
        };
    }

    return $Std_Class;

}

return 1;

