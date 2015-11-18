package RGTools::Barcode;

use strict;
use Date::Calc qw(Today Add_Delta_Days);
use POSIX qw(strftime);
use Time::HiRes qw(gettimeofday tv_interval);
use Carp;
use Data::Dumper;

use RGTools::RGIO;

##   ####
##   # <SYNOPSIS>
##
##   # initialize, indicating standard type #
##   my $barcode = Barcode->new(-type=>'gelpour_barcode_1D');
##   # set fields required as per defined type #
##   $barcode->set_fields((
##   		      class=>'RUN',
##   		      id=>1234,
##   		      barcode=>'PR123',
##   		      rack=>'RAC123',
##   		      initial=>'abc',
##   		      creation=>'2005-01-01'
##   		      ));
##   # print barcode
##   $barcode->lprprint();
##
##   ###  Alternatively, you can set up a custom barcode: ###
##
##   ## define attributes for 2 items on the label...
##   my $label1 = {
##       '-name' =>'label1',
##       '-posx'   =>5,
##       '-posy'   =>5,
##       '-size'   =>30,
##       '-value'  =>'label1',
##   };
##
##   my $label2 = {
##       '-name'    =>'label2',
##       '-style' =>'code128',
##       '-value' => 'testlabel',
##       '-posx'   =>15,
##       '-posy'   =>15,
##       '-size'   =>40,
##   };
##
##   my $ok = new Barcode(
##   		     -labels=>[$label1,$label2],
##   		     -height=>0.75,
##   		     -width=>2.25,
##   		     -top=>15,
##   		     -zero_x=>25,
##   		     -zero_y=>25,
##   		     );
##   $ok->lprprint();
##

#my $datafile  = "/usr/local/uproj/barcode/prod/barcodes.dat";
#my $logfile   = "/mnt/disk11/barcode/barcode.log";
#my $DATAFILE  = "/home/sequence/alDente/WebVersions/Production/conf/barcodes.dat"

use FindBin;
my $DATAFILE = $FindBin::RealBin . "/../conf/barcodes.dat";    ## <CONSTRUCTION>

#my $LOGFILE  = "/home/sequence/alDente/logs/barcode.log";
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

sub Barcode::DESTROY {
}

###########
sub new {
###########
    my $class    = shift;
    my %args     = @_;
    my $type     = $args{-type};
    my $id       = $args{-id};
    my $labels   = $args{-labels};                  ### allow for custom specification of labels.
    my $datafile = $args{-datafile} || $DATAFILE;
    my $dbc      = $args{-dbc};                     ### optional database connnection parameter

    my $self = {
        id          => $id,
        comment     => undef,
        fields      => undef,
        valid       => 0,
        height      => $args{-height},
        width       => $args{-width},
        zero_x      => $args{-zero_x},
        zero_y      => $args{-zero_y},
        top         => $args{-top},
        scale_DPI   => $args{-dpi} || $Default{DPI},
        printer_DPI => $args{-printer_dpi},
    };

    bless $self, $class;

    $self->{printer} = '';    ## initialize printer setting (may be defined)
    
    if ($dbc) { $self->{dbc} = $dbc }
    
    if ($labels) {            ## labels specified explicitly (custom)
        $self->set_attribute( 'type', $type ) if $type;
        return $self->specify_labels(%args);
    }
    elsif ($type) {           ## standard label initialized (from std file or from database)
        $self->{type} = $type;
        return $self->load_from_file( $type, $datafile );
    }
    else {
        carp('no type or labels specified');
    }

    return $self;             ## still requires label specification ##
}

#########################################################################
# load barcode object from configuration file given barcode label name
#
#
# Return: $self (barcode object) on success [undef on failure]
########################
sub load_from_file {
########################
    my $self       = shift;
    my $label_name = shift;                 ## label name
    my $file       = shift || $DATAFILE;    ## label configuration file
    my $debug      = shift;

    unless ($label_name) {
        print "** user must specify a label name to use **\n";
        return;
    }

    if ( !-e $file || !-r _ ) {
        carp "Can't open barcode data file $file";
    }

    ## set default settings ##
    foreach my $attribute (@mandatory_attributes) {
        $self->set_attribute( $attribute, $Default{$attribute} );
    }

    open my $FILE, '<', $file or print "$file NOT FOUND";
    my $found = 0;
    while (<$FILE>) {
        chop;
        if (/^\#/)   {next}    ## skip comment lines
        if (/^\s*$/) {next}    ## skip blank lines

        my $line = $_;
        if ($found) {
            ## after having found the specfied label ##
            if (/^\[(.*)\]/) {last}    ## next label found -> escape now.
            s/^\s*(.*)\s*$/$1/g;
            my @line = split( /\s+/, $_ );
            ## check for general label attributes ##
            if ( $line[0] eq "HEIGHT" ) {
                $self->set_attribute( 'height', $line[1] );
                next;
            }
            elsif ( $line[0] eq "WIDTH" ) {
                $self->set_attribute( 'width', $line[1] );
                next;
            }
            elsif ( $line[0] eq "TOP" ) {
                $self->set_attribute( 'top', $line[1] );
                next;
            }
            elsif ( $line[0] eq "ZERO" ) {
                my ( $zero_x, $zero_y ) = split( /,/, $line[1] );
                $self->set_attribute( 'zero_x', $zero_x );
                $self->set_attribute( 'zero_y', $zero_y );
                next;
            }
            elsif ( $line[0] eq "DPI" ) {
                $self->set_attribute( 'scale_DPI', $line[1] );
                next;
            }
            else {
                ## if not standard label attributes, above, the line should contain individual label elements ##
                if ( @line < 4 ) {
                    print "Incorrect number of fields in $file $label_name label.\n(@line)\n";
                    return;
                }
                my $field  = $line[0];
                my $format = $line[1];
                my $pos    = $line[2];
                my ( $posx, $posy );
                if ( $pos =~ /(.*),(.*)/ ) {
                    $posx = $1;
                    $posy = $2;
                }
                else {
                    print "X,Y coordinates incorrectly specified in $label_name.$field.\n";
                    return;
                }
                my $size  = $line[3];
                my $opts  = $line[4] || "";
                my $style = $line[5] || 'text';
                $self->{fields}{$field}{'format'} = $format;
                $self->{fields}{$field}{'posx'}   = $posx;
                $self->{fields}{$field}{'posy'}   = $posy;
                $self->{fields}{$field}{'size'}   = $size;
                $self->{fields}{$field}{'style'}  = $style;
                $self->{fields}{$field}{'opts'}   = $opts;

                if ( $opts =~ /s=\"(.*?)\"/ ) {
                    my $samplevalue;
                    if ( $1 eq "today" ) {
                        $samplevalue = strftime( "%Y-%m-%d", localtime );
                    }
                    else {
                        $samplevalue = $1;
                    }
                    $self->{fields}{$field}{'sample'} = $samplevalue;
                }
                else {
                    $self->{fields}{$field}{'sample'} = "-";
                }
            }
        }
        if ( $line =~ /\[$label_name\]\s*(.*)\s*/ ) {
            $self->set_attribute( 'comment', $1 );
            $found = 1;
        }
    }
    close $FILE;

    if (!$found ) { 
        ## if label_name does not exist in file
        if ($label_name !~ /no_barcode/) { print "Label: '$label_name' not found in barcode data file";}
        return $self; 
    }    
    
    $self->set_attribute( 'type',  $label_name );
    $self->set_attribute( 'valid', 1 );
    return $self;
}

#################
# build zpl string from scratch
#
# Generally, this method should be called indirectly when the object is created by including a -labels parameter as in the following example:
#
# <SNIP>
#
#    my $label1 = {
#	'-name' =>'label1',
#        '-value' =>'label text',
#	'-posx'   =>5,
#	'-posy'   =>5,
#	'-size'   =>30,
#	'-opts'   =>'',
#	'-format' => '',
#        '-style'  => 'text',
#    };
#    my $label2 = {
#	'-name'    =>'barcode',
#	'-value' =>'code128',
#	'-barcode' => 'testlabel',
# 	'-posx'   =>15,
#	'-posy'   =>15,
#	'-size'   =>40,
#	'-opts'   =>'',
#	'-format' => '',
#    };
#
#    my $ok = new Barcode(
#		-labels=>[$label1,$label2],
#		-height=>0.75,
#		-width=>2.25,
#		-top=>15,
#		-zero_x=>25,
#		-zero_y=>25,
#		);
#
#   $ok->lprprint(-printer=>'urania');
#
#   </SNIP>
#
# Return: barcode object ($self) or undef on error]
#######################
sub specify_labels {
#######################
    my $self      = shift;
    my %args      = @_;
    my $labels    = $args{-labels} if defined $args{ - labels };    ## mandatory array of hashes (each hash containing keys: format, posx, posy, size, opts, text
    my $zero_x    = $args{-zero_x} || $Default{zero_y};
    my $zero_y    = $args{-zero_y} || $Default{zero_x};
    my $height    = $args{-height} || $Default{height};
    my $width     = $args{-width} || $Default{width};
    my $top       = $args{-top} || $Default{top};
    my $scale_DPI = $args{-dpi} || $Default{DPI};

    my @keys;

    if ( $labels && ref $labels eq 'ARRAY' ) {
        @keys = @$labels;
    }
    elsif ( $labels && ref $labels eq 'HASH' ) {
        @keys = ($labels);
    }
    else {
        carp "Labels should be ARRAY instead of " . ref $labels;
        return;
    }
    ## set overall label settings (as defined or to default settings) ##
    $self->set_attribute( 'height',    $height );
    $self->set_attribute( 'width',     $width );
    $self->set_attribute( 'top',       $top );
    $self->set_attribute( 'zero_x',    $zero_x );
    $self->set_attribute( 'zero_y',    $zero_y );
    $self->set_attribute( 'scale_dpi', $scale_DPI );

    unless ( ref $keys[0] eq 'HASH' ) {
        my $ref = ref $keys[0];
        print carp "Array should contain hash references (found $ref).";
        return;
    }

    my @labels;
    my $index = 1;    ## start with 'L1' for unnamed labels ...
    foreach my $label (@keys) {
        my %hash       = %$label;
        my @label_keys = keys %$label;
        my $label_name = $label->{-name} || "L" . $index++;
        unless ($label_name) {
            _Message("** No name specified for label");
            next;
        }
        push( @labels, $label_name );
        foreach my $std_key (@std_keys) {
            $self->{fields}{"$label_name"}{"$std_key"} = $hash{"-$std_key"} if defined $hash{"-$std_key"};
        }

        #	if (defined $label->{barcode}) { $self->{fields}{barcode}{barcode} = $label->{barcode} }
        #	if (defined $hash{'-barcode'}) { $self->{fields}{barcode}{barcode} = $label->{barcode} }
        $self->{fields}{"$label_name"}{'style'} ||= 'text';    ## set default style
    }

    ## ensure mandatory fields entered ##
    my $incomplete = 0;
    foreach my $mandatory_key (@mandatory_keys) {
        foreach my $label_name (@labels) {
            unless ( defined $self->{fields}{"$label_name"}{$mandatory_key} ) {
                carp("Missing mandatory $mandatory_key (in $label_name)");
                $incomplete++;
            }
        }
    }
    if ($incomplete) { carp("still missing mandatory fields"); }
    $self->set_attribute( 'valid', 1 );
    return $self;
}

###################
#
# Set up object fields based upon type or input
#
# <snip>
# Example:
#   # $bc->set_fields(
#
#
###################
sub set_fields {
###################
    my $self  = shift;
    my %input = @_;

    my $use_sample = $input{-sample};
    my $valid      = 1;
    my $field;

    unless ( $self->get_fields ) {
        return !carp("* Error - must specify labels or upload type details first");
    }

    my @keys = keys %input;
    foreach $field ( $self->get_fields ) {

        # Check if each of the fields defined for the label is present in the arguments
        my $input_value = '';
        if ( $input{$field} ) {
            ## defined input ...
        }
        elsif ($use_sample) {
            $self->{fields}{$field}{'value'} ||= $self->{fields}{$field}{'sample'};
            $input{$field} = $self->{fields}{$field}{'sample'};

            #	    if ($self->{fields}{$field}{'value'} =~/^code/) { ## barcode ##
            #		$self->{fields}{$field}{'barcode'} = 'code128';
            #	    }
            #	    elsif ($self->{fields}{$field}{'value'} =~/^code/) { ## barcode ##
            #		$self->{fields}{$field}{'barcode'} = 'datamatrix';
            #	    }
            next;
        }
        elsif ( ( defined $input{$field} ) || ( $self->get_field_attribute( $field, "opts" ) =~ /optional/ ) ) {
            ## ok if nothing defined in this case...  ##
        }
        elsif ( ( defined $input{$field} ) || ( $self->get_field_attribute( $field, "format" ) eq '.*' ) ) {
            ## ok if nothing defined in this case...  ##
        }
        elsif ( defined $self->{fields}{$field}{value} ) {
            ## ok - it may have been defined earlier ##
        }
        else {
            print "Field '$field' not defined in arguments.";
            print Dumper( $self->{fields}{$field} );
            $valid = 0;
            next;
        }

        $input_value = $input{$field} if ( defined $input{$field} );

        if ( defined $input_value && !( $self->_validate( -field => $field, -value => $input_value ) ) ) {
            _Message("$field value ($input_value) not valid");

            $self->{fields}{$field}{'value'} = "-";
            $valid = 0;
        }
        else {

            # The field has been validated.
            $self->{fields}{$field}{'value'} = $input_value;
        }
    }
    return $self->set_attribute( 'valid', $valid );
}

###################
sub get_fields {
###################
    my $self = shift;

    if ( defined $self->{fields} ) {
        my $field_hash = $self->{fields};
        unless ( ref $field_hash eq 'HASH' ) {
            return ref $field_hash . " found where HASH expected.";
        }
        my @keys = keys %$field_hash;
        return @keys;
    }
    else {
        carp("no labels defined for barcode");
        return ();    ## return empty array (ok)
    }
}

################################################################
#
# Constructs the ZPL commands required to print the label.
# Returns the string containing the ZPL commands.
################################################################
sub make_zpl {
################################################################
    my $self        = shift;
    my %args        = @_;
    my $scale_DPI   = $args{-scale_DPI} || $self->{scale_DPI} || $Default{DPI};
    my $printer_DPI = $args{-printer_DPI} || $self->{printer_DPI} || $Default{printer_DPI};
    my $verbose     = $args{-verbose};

    my $scale_factor = 1;
    if ($scale_DPI) {
        $scale_factor = $printer_DPI / $scale_DPI;
    }

    if ( !$self->_validate ) {
        carp "Label failed validation";
        return 0;
    }

    my $zpl    = "";
    my $zero_x = int( ( $self->get_attribute('zero_x') ) * $scale_factor );
    my $zero_y = int( ( $self->get_attribute('zero_y') ) * $scale_factor );
    my $top    = int( ( $self->get_attribute('top') ) * $scale_factor );

    my $field;
    $zpl .= "^XA\n";
    $zpl .= "^LT$top\n";
    $zpl .= "^LH$zero_x,$zero_y\n";

    foreach $field ( keys %{ $self->{fields} } ) {
        my ( $value, $size, $posx, $posy, $opts, $barcode_type );

        # skip barcode_value, not necessary
        if ( $field eq "barcode_value" ) {
            next;
        }
        $value = $self->get_field_attribute( $field, "value" );
        $size = int( ( $self->get_field_attribute( $field, "size" ) ) * $scale_factor );
        $posx = int( ( $self->get_field_attribute( $field, "posx" ) ) * $scale_factor );
        $posy = int( ( $self->get_field_attribute( $field, "posy" ) ) * $scale_factor );
        $opts = $self->get_field_attribute( $field, "opts" );
        $barcode_type = $self->get_field_attribute( $field, "style" ) || 'text';

        if ( $barcode_type ne 'text' ) {

            #Code 128
            my $bczpl = "";

            #	  my $bctext = $self->get_field_attribute("barcode","barcode");
            my $bctext = $value;
            $size =~ s/(.*),(.*)/$2/;

            if ( $self->get_field_attribute( $field, "opts" ) =~ /dense/ ) {
                $zpl .= "^BY1,3.0,10\n";
            }
            elsif ( ( $self->get_field_attribute( $field, "opts" ) =~ /large/ ) ) {
                $zpl .= "^BY3,3.0,10\n";
            }
            elsif ( ( $self->get_field_attribute( $field, "opts" ) =~ /scale/ ) && $scale_factor > 1 ) {
                $zpl .= "^BY3,3.0,10\n";
            }
            else {
                $zpl .= "^BY2,3.0,10\n";
            }

            if ( $self->get_field_attribute( $field, "opts" ) =~ /caps/ ) {
                $bctext =~ tr/a-z/A-Z/;
            }

            #print "Printing '$bctext'...<br>\n";
            $posy += $top;    ## barcodes positions are not normally relative to top

            if ( $barcode_type =~ /^code128/ ) {
                $bczpl = "^FO$posx,$posy^BCN,$size,N,N,N,N^FD$bctext^FS\n";
            }
            elsif ( $barcode_type eq "datamatrix" ) {
                $bczpl = "^FO$posx,$posy^BXN,$size,200,,,,^FD$bctext^FS\n";
            }
            elsif ( $barcode_type eq "code39" ) {
                $bczpl = "^FO$posx,$posy^B3N,N,$size,N,N^FD$bctext^FS\n";
            }
            elsif ( $barcode_type eq "micropdf417" ) {
                $bczpl = "^FO$posx,$posy^BFN,5,2^FD$bctext^FS\n";
            }
            elsif ( $barcode_type eq "qrcodebar" ) {
                $bczpl = "^FO$posx,$posy^BQN,2,3^FDQA,$bctext^FS\n";
            }
            else {
                return !carp("unrecognized barcode type: $barcode_type");
            }
            $zpl .= $bczpl;
        }
        else {
            if ( $opts =~ /noprint/ ) {

            }
            else {
                if ( ( $opts =~ /box/ ) && $value ) {
                    $zpl .= "^FO$posx,$posy^A0N,$size^FD^GB$size,$size,2^FS\n";
                }
                elsif ( ( $opts =~ /rect/ ) && $value ) {
                    $zpl .= "^FO$posx,$posy^A0N,$size^FD^GB$value,$size,3^FS\n";
                }
                elsif ( ( $opts =~ /uline/ ) && $value ) {
                    my $lineposy = $posy + $size;
                    $zpl .= "^FO$posx,$lineposy^A0N,$size^FD^GB$value,0,2^FS\n";
                }
                else {

                    #$zpl .= "^FO$posx,$posy^A0N,$size^FD$value^FS\n";
                    $value =~ s/\_/+5F/g;
                    $value =~ s/\(/+28/g;
                    $value =~ s/\)/+29/g;
                    $zpl .= "^FO$posx,$posy^A0N,$size^FH+^FD$value^FS\n";
                }
            }
        }
    }
    $zpl .= "^XZ\n";

    return $zpl;
}
################################################################
#
# Print the label to the barcode printer. The spool is defined
# as a class variable LPRQUEUE
#
#################
sub lprprint {
#################
    my $self = shift;
    my %args = @_;

    #    print Call_Stack;
    my $printer_DPI = $args{-printer_DPI} || $self->{printer_DPI};
    my $printer     = $args{-printer}     || $self->{printer};
    my $verbose     = $args{-verbose}     || 0;
    my $noscale     = $args{-noscale}     || 0;                      ## Prevent automatic scaling
    my $debug       = $args{-debug};
    my $file = $args{-file};                                         ## redirect lpr file to indicated file rather than into tmp/ directory

    my $t0 = [gettimeofday];
    my $now = strftime( "%Y-%m-%d %H:%M:%S", localtime );

    my $log = "$now: lprprint called\n";

    #  $log   .= "$stack\n";

    unless ( $printer || $debug ) { croak('no printer specified') }

    my $fieldsvalues;
    foreach my $field ( keys %{ $self->{fields} } ) {
        my $value = $self->get_field_attribute( $field, "value" );
        if ( defined $value && $value ne "" ) {
            $fieldsvalues .= $field . "[$value] ";
        }

        ## ensure all mandatory field attributes are defined ##
        my $size  = $self->{fields}{$field}{'size'};
        my $posx  = $self->{fields}{$field}{'posx'};
        my $posy  = $self->{fields}{$field}{'posy'};
        my $style = $self->{fields}{$field}{'style'};

        $log .= "$field: $value; Size=$size; PosX=$posx; PosY=$posy; Style=$style)\n";
        unless ( defined $size && ( defined $posx ) && ( defined $posy ) && $style ) {
            print "Incomplete Information supplied for $field (Size=$size; X,Y=$posx,$posy; Style=$style)\n";

            $log .= "Incomplete Information supplied for $field (Size=$size; X,Y=$posx,$posy; Style=$style)\n";
            if ($LOGFILE) {
                open my $LOG, ">>$LOGFILE" or print "No logging";
                print {$LOG} $log;
                close $LOG;
            }
            return 0;
        }
    }
    unless ($fieldsvalues) { croak( "no items in label" . Dumper($self) ) }

    $log .= "$fieldsvalues\n";

    unless ( $self->_is_valid ) {
        $log .= "ERROR barcode not valid\n";
        print "Invalid barcode - not printed";

        if ($LOGFILE) {
            open my $LOG, ">>$LOGFILE" or print "No logging";
            print {$LOG} $log;
            close $LOG;
        }
        return 0;
    }

    my $LPRQUEUE;    ## define target printer
    if ( $self->establish_printer($printer) ) {
        $LPRQUEUE = $printer;
    }
    else {

        open my $LOG, ">>$LOGFILE" or print "No logging";
        print {$LOG} $log;
        close $LOG;
        return 0;
    }

    # $self->_Accounting();  ## if set up...

    my $zpl = $self->make_zpl( -verbose => $verbose, -printer_DPI => $printer_DPI );

    #  my $zpl = "";
    #  if ( $dpi == 300 ) {
    #      print "**** 21 ***<BR><PRE>" . Dumper($self) . '</PRE>';
    #      if ( (!($noscale)) && $self->get_field_attribute("barcode","value") !~ "datamatrix") {
    #	  # scale up to 300dpi if not 2d barcode (which is programmed for 300dpi already)
    #	  $log .=  "Scaling up to $dpi dpi\n";
    #    print "**** 22 ***<BR><PRE>" . Dumper($self) . '</PRE>';
    #	  $zpl = $self->make_zpl(-dpi=>$dpi,-verbose=>$verbose);
    #      }
    #      else {
    #    print "**** 23 ***<BR><PRE>" . Dumper($self) . '</PRE>';
    #          $zpl = $self->make_zpl(-verbose=>$verbose);
    #      }
    #  }
    #  else {
    #      $zpl = $self->make_zpl(-verbose=>$verbose);
    #  }

    $log .= "$now: lprqueue -> $LPRQUEUE\n";
    if ($zpl) {
        my $randfilename = "zpl." . sprintf( "%08d", rand(1000000) ) . "." . time;

        #      _Message("printing to /tmp/$randfilename..");
        my $filename = $file || "/tmp/$randfilename";
        open my $RAND, ">$filename" || carp "Could not open $filename";
        print {$RAND} $zpl;
        close $RAND;

        if ($debug) {
            $log .= "** Debug mode ** (not printing)\n";
        }
        else {
            ## skip actual lpr command if in debug mode ##
            open my $FILE, "| lpr -P$LPRQUEUE" or $log .= "$now: ERROR: Could not open a pipe to lpr -P$LPRQUEUE: $!\n";
            $log .= "$now: paused " . Pause(0.25) . " after opening pipe.\n";
            print {$FILE} $zpl;
            $log .= "$now: paused " . Pause(0.25) . " before closing pipe.\n";
            close $FILE or $log .= "$now: ERROR: Could not close pipe to lpr: $! :: $?\n";
        }

        $log .= "$now: zpl sent to printer\n$zpl";

        # Rest so that the printer can catch up.
        my $elapsed = sprintf( "%.3f s", tv_interval($t0) );
        $log .= "$now: lprprint done [$elapsed]\n\n";
        $log .= "printed $randfilename to $LPRQUEUE.\n";

        #sleep 1;
    }
    else {
        $log .= "$now: ERROR could not open lpr process\n";
        print "Could not print to printer.";

        if ($LOGFILE) {
            open my $LOG, ">>$LOGFILE" or print "No logging";
            print {$LOG} $log;
            close $LOG;
        }
        return 0;
    }

    if ($LOGFILE) {
        open my $LOG, ">>$LOGFILE" or print "No logging";
        print {$LOG} $log;
        close $LOG;
    }
    if ($debug) {
        $log =~ s/\n/<BR>/ if $0 =~ /(cgi-bin|html)/;
        print $log;    ## debug to screen ##
    }

    return 1;
}

###################
#
# Generate png for label and save to file
#
#
# Return: target filename on success
################
sub makepng {
################

    my ( $self, $outflag, $file ) = @_;

    # Label width in printed pixels
    # The Z600 printer has a resolution of 203DPI. Adust the DPIs at the top of this
    # file to increase/decrease screen label size.
    my ( $width, $height ) = ( $self->_ZPLtoScreenScale( $self->{scale_DPI} * $self->get_attribute('width') ), $self->_ZPLtoScreenScale( $self->{scale_DPI} * $self->get_attribute('height') ) );

    use GD;
    
    my $im   = new GD::Image( $width, $height + 15 );    ##
    my $bcim = new GD::Image( $width, $height );         ## barcode image

    my $dark          = 1.1;
    my $c_bkground    = $im->colorAllocate( int( 51 / $dark ), int( 88 / $dark ), int( 158 / $dark ) );
    my $c_bkground_bc = $bcim->colorAllocate( int( 51 / $dark ), int( 88 / $dark ), int( 158 / $dark ) );
    my $c_foreground  = $im->colorAllocate( 255, 225, 82 );
    $bcim->colorAllocate( 255, 225, 82 );
    my $c_lbkground  = $im->colorAllocate( 215,  224, 240 );
    my $c_barcode    = $im->colorAllocate( 73,   124, 226 );
    my $c_barcode_bc = $bcim->colorAllocate( 73, 124, 226 );
    my $dgrey        = $im->colorAllocate( 220,  220, 220 );
    my $white        = $im->colorAllocate( 255,  255, 255 );
    my $black        = $im->colorAllocate( 0,    0,   0 );
    my $red          = $im->colorAllocate( 150,  0,   0 );
    my $green        = $im->colorAllocate( 0,    150, 0 );

    my $fontpath = "/usr/tmp/ttf";

    # my $fontpath = "/home/aldente/public/fonts";    ## <CONSTRUCTION> - establish standard fonts/ttf directory ##

    $bcim->filledRectangle( 0, 0,       $width, $height,      $c_bkground_bc );
    $im->filledRectangle( 0,   0,       $width, $height - 15, $c_bkground );
    $im->filledRectangle( 0,   $height, $width, $height + 15, $c_lbkground );

    my $top    = $self->get_attribute('top');
    my $zero_x = $self->get_attribute('zero_x');
    my $zero_y = $self->get_attribute('zero_y');

    my $field;
    my ( $value, $size, $posx, $posy, $font, $style );
    foreach $field ( keys %{ $self->{fields} } ) {
        if ( $self->get_field_attribute( $field, "opts" ) =~ /short/ ) {
            $value = $field;
        }
        else {
            $value = $self->get_field_attribute( $field, "value" );
        }
        $size = $self->get_field_attribute( $field, "size" );
        my $screensize = int( 0.85 * $self->_ZPLtoScreenScale($size) );

        $self->{screensize} = $screensize;

        $posx = $self->get_field_attribute( $field, "posx" );
        $posy = $self->get_field_attribute( $field, "posy" );
        ( $posx, $posy ) = $self->_ZPLtoScreen( $posx, $posy + $top );

        $style = $self->get_field_attribute( $field, "style" );

        # Use the futuramc font.
    SWITCH: {
            if ( $size <= 10 ) {
                $font = "zurch.ttf";
                last SWITCH;
            }
            if ( $size <= 20 ) {
                $font = "zurch.ttf";
                last SWITCH;
            }
            if ( $size <= 30 ) {
                $font = "zurch.ttf";
                last SWITCH;
            }
            $font = "futuramc.ttf";
        }

        # If the field is a barcode, print the barcode using the code39 symbology to the png.
        # I couldn't find a real code128 font (only demos with characters missing)
        $value =~ s/_/ /g;
        $value ||= '__________';    # 'noText';

        #    if ($field =~ /barcode/) {
        #    if (my $barcode_type = $self->{fields}{$field}{'barcode'}) {

        my $font = 'arialbd';

        my $y = $posy + $screensize;    ## added screensize (?)
        if ( $style && ( $style ne 'text' ) ) {
            ## generate barcode instead of text ##

            my $bc_height = $self->_ZPLtoScreenScale($size);
            my $bctext    = $value;

            $font = 'code39';
            my @bc = $im->stringFT( $c_barcode_bc, "$fontpath/$font.ttf", $screensize, 0, $posx, $y, $value );    ## should replace code39 with $style, but some may be unavailable (?)

            #	my @bc = $bcim->stringTTF("$fontpath/$font.ttf",$posx,$y+13,$bctext,13,0,$c_barcode_bc);
            #  stringFT seems to work better (could not get stringTTF to output anything (?) #

            my $bc_screen_w = $bc[2] - $bc[6];
            my $bc_screen_h = $bc[3] - $bc[7];
            $im->copyResized( $bcim, $posx, $y, $posx, $y, $bc_screen_w, $bc_height, $bc_screen_w, $bc_screen_h );
        }
        else {
            if ( $screensize <= 5 ) {
                $font = gdTinyFont;
            }
            elsif ( $screensize <= 8 ) {
                $font = gdSmallFont;
            }
            elsif ( $screensize <= 10 ) {
                $font = gdMediumBoldFont;
            }
            else {
                $font = gdLargeFont;
            }

            $im->string( $font, $posx, $posy, $value, $white );

            ## line below doesn't seem to work ...
            # $im->stringFT( $white, "$fontpath/$font.ttf", $screensize, 0, $posx, $y, $value );
            #
            #	$im->stringTTF("$fontpath/$font",$posx,$posy,$value,$screensize,20,$c_foreground);
            #
            #  stringFT seems to work better in some cases, but is finicky (could not get stringTTF to output anything (?) #

        }
    }

    if ( $self->_is_valid ) {

        #        ## show image with VALID label if identified ##
        $im->string( gdTinyFont, 5, $height + 2, "VALID", $green );
    }
    else {

        #        ## show image with INVALID label if not recognized ##
        $im->string( gdTinyFont, 5, $height + 2, "NOT VALID", $red );
    }

    my $text = $self->get_attribute('comment');
    $im->string( gdTinyFont, $width - length($text) * 5, $height + 2, $text, $black );

    if ( $outflag eq "html" ) {
        print "Content-type: image/png\n\n";
    }
    elsif ( $outflag eq 'img' ) {
        return $im->gif;
    }

    $file ||= "/tmp/test.barcode";    ## <CONSTRUCTION>
    open( FILE, ">$file" ) or return;
    binmode FILE;
    print FILE $im->gif;
    close FILE;

    return $file;
}

#
# <CONSTRUCTION>
# not sure if this is working ??
#
#################
sub printpng {
#################
    my ( $self, $flag ) = @_;
    my $sample = 0;
    if ( defined $flag && $flag =~ /sample/ ) {
        $sample = 1;
    }
    my $url = "/cgi-bin/intranet/barcode/makepng?";
    $url .= "id=" . $self->get_attribute('id');
    my $field;
    foreach $field ( keys %{ $self->{fields} } ) {
        my $value;
        if ($sample) {
            $value = $self->get_field_attribute( $field, "sample" );
        }
        else {
            $value = $self->get_field_attribute( $field, "value" );
        }
        $url .= "&field_$field=" . $value;
    }
    print qq{<img src="$url">};
    return;
}

#### Accessors ####

######################
sub get_attribute {
######################
    my $self      = shift;
    my $attribute = shift;
    return $self->{$attribute} if $attribute && defined $self->{$attribute};
    return;
}

######################
sub set_attribute {
######################
    my $self      = shift;
    my $attribute = shift;
    my $value     = shift;
    
    $self->{$attribute} = $value;
    
    return $value if $attribute && defined $value;
    
    return !carp("Attribute '$attribute' or Value ('$value') undefined");
}

##############################
sub get_field_attribute {
##############################
    my $self      = shift;
    my $field     = shift;
    my $attribute = shift;
    return $self->{fields}{$field}{$attribute} if $field && $attribute && defined $self->{fields}{$field}{$attribute};
    return;
}

##############################
sub set_field_attribute {
##############################
    my $self      = shift;
    my $field     = shift;
    my $attribute = shift;
    my $value     = shift;
    return ( $self->{fields}{$field}{$attribute} = $value ) if $field && $attribute && defined $value;
    return;
}

##########################################################
# Define printer
#
# Return true if printer is identified (uses lpstat to identify)
############################
sub establish_printer {
############################
    my $self    = shift;
    my $printer = shift;
    my $dpi     = shift;

    unless ($printer) { return !carp('no printer specified') }
    $self->{printer} = $printer;
    $self->{'printer_DPI'} = $dpi if $dpi;
    my $validate = `lpq -P $printer`;    ## ping printer once
    if ( $validate =~ /^$printer is ready/ ) {
        ## return true if packet received ##
        return 1;
    }
    elsif ( $validate =~ /\bnot ready\b/ ) {
        ## printer not ready - network problem or printer is off (?) ##
        print "Printer $printer NOT READY - ensure printer is ON and report issue to Systems";
        return 0;
    }
    else {
        print "Failed to find printer '$printer'.";
        ## else packet not received or host unknown ##
        return 0;
    }
}
######################
#
# Text dump of current label configuration settings.
#
#
# Return: string
######################
sub dump_format {
######################
    my ($self) = @_;

    my $dump;
    $dump .= sprintf( "%10s: %s\n",                    "Class",      $self->get_attribute('id') );
    $dump .= sprintf( "%10s: %s\n\n",                  "Descriptor", $self->get_attribute('comment') );
    $dump .= sprintf( "%10s %35s %3s,%3s %4s %-10s\n", "fieldname",  "regexp format", "x", "y", "size", "options" );
    $dump .= sprintf("---------------------------------------------------------------------------------\n");
    my $field;
    foreach $field ( sort keys %{ $self->{fields} } ) {
        $dump .= sprintf(
            "%10s %35s %3d,%3d %3d (%s) %s\n",
            $field,
            $self->get_field_attribute( $field, "format" ),
            $self->get_field_attribute( $field, "posx" ),
            $self->get_field_attribute( $field, "posy" ),
            $self->get_field_attribute( $field, "size" ),
            $self->get_field_attribute( $field, "style" ),
            $self->get_field_attribute( $field, "opts" )
        );
    }
    return $dump;
}

######################################################
# Return boolean confirming valid label identified
#
#
################
sub _is_valid {
################
    my $self  = shift;
    my $value = $self->get_attribute('valid');

    return $value;
}

################################################################
#
# Creates a PNG image of the current label.
# as a class variable LPRQUEUE
#
# Convert from ZPL dot unit to screen unit.
#
################################################################
sub _ZPLtoScreenScale {
################################################################

    my $self = shift;
    my $x    = shift;
    my $dpi  = $self->{scale_DPI};

    my $u = int( $x * ( $DPIs / $dpi ) );
    return $u;
}

################################################################
sub _ZPLtoScreen {
################################################################
    my $self = shift;
    my ( $x, $y ) = @_;
    my $u = int( ( $x + $self->get_attribute('zero_x') ) * ( $DPIs / $self->{scale_DPI} ) );
    my $v = int( ( $y + 0.5 * $self->get_attribute('zero_y') ) * ( $DPIs / $self->{scale_DPI} ) );

    return ( $u, $v );
}

###################
#
# method to keep track of barcodes printed
# (eg tiny files maintaining a print count for each label type ?)
#
###################
sub _Accounting {
###################
    # <CONTSTRUCTION> - optional - low priority

    return;
}

#
# local message generator
#
################
sub _Message {
################
    my $message = shift;
    print "$message\n";
    return;
}

#
# Validate input fields for labels as required.
# Options:
#   1 - supply field and value arguments to validate a particular field
#   2 - no fields (validates current fields to ensure mandatory fields are supplied for all defined label items)
#
#
##################
sub _validate {
##################
    my $self  = shift;
    my %args  = @_;
    my $field = $args{-field} if defined $args{-field};
    my $value = $args{-value} if defined $args{-value};

    if ( defined $field && defined $value ) {
        return $self->_validate_field( -field => $field, -value => $value );
    }
    elsif ( !( defined $field ) && !( defined $value ) ) {
        ## no input arguments -> validate entire label
        foreach my $field ( $self->get_fields() ) {
            unless ( $self->_validate_field( -field => $field ) ) {
                return !carp("$field Field failed validation");
            }
        }
        foreach my $attribute (@mandatory_attributes) {
            unless ( defined $self->{$attribute} ) {
                return !carp("$attribute attribute not set ($self->{type}) - failed validation");
            }
        }
        $self->set_attribute( 'valid', 1 );
        return 1;    ## passed both mandatory sets of checks with no returns ##
    }
    else {
        carp("Field validation requires field and value parameters");
        return 0;
    }
}

##########################
sub _validate_field {
##########################
    my $self  = shift;
    my %args  = @_;
    my $field = $args{-field};
    my $value = defined $args{-value} ? $args{-value} : $self->{fields}{$field}{value};

    my $format = $self->get_field_attribute( $field, "format" );
    my $opts   = $self->get_field_attribute( $field, "opts" );

    # Validation is done using the regular expression (format) of the field.
    # Some fields can have other specific values which do not fit their regular
    # expression. For example, a date is usually \d{4}-\d{2}-\d{2} (e.g. 2000-07-07)
    # but can have the value 'today', 'tomorrow' or '+n days'

    foreach my $attribute (@mandatory_keys) {
        unless ( defined $self->{fields}{$field}{$attribute} || ( $attribute eq 'value' && defined $value ) ) {
            _Message("$attribute NOT defined for $field.");
            carp("$field $attribute undefined");
            return 0;
        }
    }
    ## also check format if required ##
    unless ($format) { return 1 }    ##  no specified format ...

    # Handle special cases first.
    if ( $field eq "date" ) {
        if ( $value eq "today" ) {
            $value = sprintf( "%04d-%02d-%02d", Today() );
        }
        if ( $value eq "tomorrow" ) {
            $value = sprintf( "%04d-%02d-%02d", Add_Delta_Days( Today(), 1 ) );
        }
        if ( $value =~ /\+(\d+)\s*days/ ) {
            my $ndays = $1;
            $value = sprintf( "%04d-%02d-%02d", Add_Delta_Days( Today(), $ndays ) );
        }
    }
    if ( $value =~ /$format/ ) {
        if ( $opts =~ m/caps/ ) {
            $value =~ tr/a-z/A-Z/;    ### WHY ? Commented out (rguin Nov 28/2002)
        }

        if ( $opts =~ m/zeropad=(\d+)/ ) {
            my $zeropad = $1;
            $value =~ /([a-zA-Z]*)(\d+)/;
            $value = sprintf( "${1}%0${zeropad}d", $2 );
        }
        $self->set_field_attribute( $field, 'value', $value );
        return 1;
    }
    else {
        print "'$value' does not adhere to format: $format.";
        return 0;
    }
}

sub Pause {
    my $time = shift;
    my $t0   = [gettimeofday];
    foreach ( 0 .. 1e7 ) {
        if ( tv_interval($t0) > $time ) {
            last;
        }
    }
    return tv_interval($t0);
}

##############################
# private_functions          #
##############################

#
# Accessor for barcode attributes
#
################
sub _get_value {
################
    my $self      = shift;
    my $attribute = shift;

    if ( defined $self->{fields} && defined $self->{fields}{$attribute} ) {
        return $self->{fields}{$attribute}{value};
    }
    else {
        return;
    }
}

return 1;
