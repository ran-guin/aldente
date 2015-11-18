###############################################################
#
#  Reads
#
# This program handles read data
#
###############################################################
package Reads;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Reads.pm - This program handles read data 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This program handles read data <BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use Storable qw(freeze thaw);
use Data::Dumper;
use RGTools::RGIO;

##############################
# custom_modules_ref         #
##############################
use RGTools::Read;

##############################
# global_vars                #
##############################
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################

#######
sub new {
#######
    #
    #Constructor of the Reads object
    #
    my $this = shift;
    my %args = @_;

    my ($class) = ref($this) || $this;
    my ($self) = {};

    $self->{reads_count}           = 0;     #Number of reads found [Int]
    $self->{reads_index}           = {};    #Indexes to the Read objects [Hash]
    $self->{reads}                 = ();    #An array of individual Read objects [Array]
    $self->{phred_output}          = '';    #Output file of phred [String]
    $self->{phred_screened_output} = '';    #Screened output file of phred [string]
    $self->{screen_output}         = '';    #Output file of Cross Match [String]
    $self->{quality_output}        = '';    #Quality output file of phred [String]

    $self->{phd_dir}     = '';              #Location of phd_dir [String]
    $self->{chromat_dir} = '';              #Location of chromat_dir [String]

    $self->{phred_version}       = '';      #Version of the phred bin [String]
    $self->{phred_command}       = '';      #Phred command that will be run [String]
    $self->{cross_match_command} = '';      #Cross Match command that will be run [String]

    bless $self, $class;

    return $self;
}

##############################
# public_methods             #
##############################

#######################
sub parse_directory {
#######################
    #
    #Generate data for chromat files in a given directory
    #
    my $self = shift;
    my %args = @_;

    my $dir     = $args{dir}         || '';    #Working directory [String]
    my $vectors = $args{vector_file} || '';    #Location of vector file [String]
                                               #my $dump = $args{dump};
                                               #my $freeze = $args{freeze};
                                               #my $verbose = $args{verbose};
    my $phredpar        = $args{phredpar};                                           #Location of the phredpar.dat file [String]
    my $phred_bin       = $args{phred_bin} || '/usr/local/bin/phred';                #Location of the phred bin file [String]
    my $cross_match_bin = $args{cross_match_bin} || '/usr/local/bin/cross_match';    # Location of the cross match bin file [String]
    my $trim            = $args{trim};                                               # include phredscores.trimmed file - trimmed for quality and vector
    my $phred_file      = $args{phredfile};

    $self->{dir} = $dir;

    #    $self->{chromat_dir} = $args{chromat_dir} || '';    ## directory for trace files
    $self->{chromat_dir} = "$dir/chromat_dir";

    #    $self->{phd_dir} = $args{phd_dir};             ## directory for phd files
    $self->{phd_dir} = "$dir/phd_dir";

    $self->{phred_output}          = $self->{phd_dir} . "/phredscores";
    $self->{phred_screened_output} = $self->{phd_dir} . "/phredscores.screen";
    $self->{screen_output}         = $self->{phd_dir} . "/screen";

    print "Run Phred -> phredscores \n$self->{phred_command} ...\n";
    print $self->run_phred(
        trim_alt   => 'a',
        dir        => $self->{dir},
        phred_file => 'phredscores',
        run        => 1,
        phredpar   => $phredpar,
        phred_bin  => $phred_bin,
        phredfile  => $phred_file
    );
    print "Run Cross_Match -> phredscores.screen \n$self->{cross_match_command} ...\n\n";
    $self->run_cross_match(
        dir             => $self->{dir},
        phred_file      => 'phredscores',
        screen_file     => 'phredscores.screen',
        vector_file     => $vectors,
        run             => 1,
        cross_match_bin => $cross_match_bin
    );
    $self->parse_reads($trim);

    #if ($dump) {
    #print $self->dump();
    #}
    #elsif ($print) {
    #print $self->print();
    #}
    #elsif ($freeze) {
    #return freeze($self);    ## return frozen copy of object
    #}

    return;
}

############
sub run_phred {
############
    #
    #Generate and run phred command ##
    #
    my $self = shift;
    my %args = @_;

    my $trim_alt     = $args{trim_alt};                               #Trim alt [String]
    my $phred_output = $args{phred_file};                             # phred filename [String]
    my $run          = $args{run};                                    # run after generating command [Boolean]
    my $phd_dir      = $args{phd_dir};                                # (optional) - defaults to $dir/phd_dir [String]
    my $chromat_dir  = $args{chromat_dir};                            # (optional) - defaults to $dir/chromat_dir [String]
                                                                      #my $log = $args{log} || "$phd_dir/phred_command.log";
    my $phredpar     = $args{phredpar};                               #Location of the phredpar.dat file [String]
    my $phred_bin    = $args{phred_bin} || '/usr/local/bin/phred';    #Location of the phred bin file [String]

## Generate phred files ##
    $chromat_dir = $self->{dir} . '/chromat_dir';                     # trace dir
    $phd_dir     = $self->{dir} . '/phd_dir';                         # phred dir
    my $qual_file = "$phd_dir/phredscores.qual";

    my $pc = "$phred_bin -V -id $chromat_dir -qa $qual_file";
    $pc .= " -st fasta -sa $phd_dir/$phred_output -qt mix  -pd $phd_dir -p";

    if   ( $trim_alt =~ /[a-zA-Z]+/ ) { $pc .= " -trim_alt $trim_alt "; }
    else                              { $pc .= " -trim_alt \"\""; }

    if ($phredpar) { $pc = "export PHRED_PARAMETER_FILE=$phredpar;\n" . $pc }
    $self->{phred_command} = $pc;

    my $fback = $self->{phred_command};

    if ($run) {
        $fback = try_system_command( $self->{phred_command} );
        $fback =~ /phred version\: (\S+)/ms;
        $self->{phred_version} = $1;
    }

    if ( $fback =~ /unknown chemistry\s+(\S+).*?(\S+\.dat)$/ms ) {
        print "UNKNOWN CHEMISTRY: ($1) in $2\n";
    }

    #if ($log) {`echo \'$fback\' > $log`}

    return $fback;
}

##################
sub run_cross_match {
##################
    #
    #Generate and run phred command ##
    #
    my $self = shift;
    my %args = @_;

    my $phred_file      = $args{phred_file};                                         #Location of the phd file [String]
    my $vector_file     = $args{vector_file};                                        #Location of the vector file [String]
    my $screen_file     = $args{screen_file};                                        #Location of the screen file [Strng]
    my $phd_dir         = $args{phd_dir} || $self->{phd_dir};                        ## optional (defaults to $dir/phd_dir)
    my $run             = $args{run};                                                #run after generating comand [Boolean]
                                                                                     #my $log = $args{log} || "$phd_dir/cross_match_command.log";
    my $cross_match_bin = $args{cross_match_bin} || '/usr/local/bin/cross_match';    # Location of the cross match bin file [String]

    unless ( $phred_file && $vector_file && $screen_file ) {
        print "Require phred_file ($phred_file), vector_file ($vector_file), screen_file ($screen_file)\n";
        return;
    }

## Generate cross_match command ##

    my $options = " -minmatch 12 -minscore 20 -screen ";
    my $cmc     = "$cross_match_bin $phd_dir/$phred_file $vector_file $options > $phd_dir/$screen_file.log";

    $self->{cross_match_command} = "$cross_match_bin $phd_dir/$phred_file $vector_file $options > $phd_dir/$screen_file.log";

    my $fback = $self->{cross_match_command};

    #print "*** $self->{cross_match_command} ***\n";
    if ($run) {
        $fback = try_system_command( $self->{cross_match_command} );
    }

    if ( $fback =~ /^(.*?error.*?)$/ms ) {
        print "ERROR: ($1)\n";
    }

    #if ($log) {`echo \'$fback\' > $log`}

    return $fback;
}

#######################
sub parse_reads {
#######################
    #
    #Go through screen file and phred files
    #
    my $self = shift;
    my $trim = shift;

    my $generate_trimmed_fasta = $self->{phd_dir} . "/phredscores.trimmed" if $trim;

    if ($generate_trimmed_fasta) {
        open( TRIMMED, ">$generate_trimmed_fasta" ) or print "Cannot open $generate_trimmed_fasta file";
    }

    my $p;

    #print "open $self->{screen_output} and parse data in here...\n";
    my $screen = $self->{phred_screened_output};

    open( SCREEN, $screen ) or die("Error opening Screen file: $screen: $!\n");

    my @Q20;    ### array of Phred 20 quality values for each run..
    my @SL;     ### array of sequence length values for each run..
    while (<SCREEN>) {
        my $label = $_;
        $p .= "$label";    # extract header line
        if ( $label =~ /^>(\S*)\s+(\d+)\s+(\d+)\s+(\d+)\s+[a-zA-Z]{3}\s*$/ ) {
            my $clone          = $1;
            my $total_length   = $2;
            my $Ql             = $3;
            my $quality_length = $4;
            my $Qr             = $quality_length + $Ql - 1;
            my $good_length    = 0;
            my @comments       = ();
            my $note_id        = 'NULL';
            my $error          = '';
            my @warnings       = ();

            $p .= "Length (of $clone): $total_length";

            my $line;
            if ($total_length) { $line = <SCREEN>; }
            else {
                $error   = 'Empty Read';
                $note_id = 5;
            }

            chop $line;
            my $total_read   = length($line);
            my $screened_seq = $line;

            # Read the rest of the sequence
            while ( $total_read < $total_length ) {
                $line = <SCREEN>;
                chop $line;
                $screened_seq .= $line;
                $total_read += length($line);
            }

            # Calculate Vector Left, Vector Right
            my $Vl         = -1;
            my $Vr         = -1;
            my $Vq         = 0;
            my $Vt         = 0;
            my $trim_left  = -1;
            my $trim_right = -1;

            if ( $quality_length > 0 ) {
                my $left_seq = substr $screened_seq, 0, $Ql;
                my $right_seq = substr $screened_seq, $Qr + 1;
                if ( $left_seq  =~ /[xX]$/ ) { $Vl = $Ql - 1; }
                if ( $right_seq =~ /^[xX]/ ) { $Vr = $Qr; }
                my $ll = length($left_seq);
                my $rl = length($right_seq);

                #	           print "\nLeft: $left_seq ($ll)\n";
                #	           print "\nRight: $right_seq ($rl)\n";

                ## quality region
                my $mid_seq = substr $screened_seq, $Ql, $quality_length;
                if ( $mid_seq =~ m/^([xX]*)([actgACTGnN]+)([xX]*)$/ ) {
                    $good_length = length($2);
                    if ($1) { $Vl = length($1) + $Ql - 1; }
                    if ($3) { $Vr = $Ql + length($1) + length($2); }
                    $Vq = length($1) + length($3);
                }
                elsif ( $mid_seq =~ m/^([xX]+)$/ ) {
                    $good_length = 0;
                    $Vl          = $total_length - 1;
                    $Vr          = 0;
                    $Vq          = $quality_length;
                    push( @warnings, 'Vector Only' );
                    $note_id = 3;
                }
                else {
                    my $format;
                    $Vq = 0;
                    my $IEseq = $mid_seq;
                    while ($IEseq) {
                        if ( $IEseq =~ /^([agtcAGTCnN]+)(.*)$/ ) {
                            $IEseq = $2;
                            $format .= "N(" . length($1) . ")";
                        }
                        elsif ( $IEseq =~ /^([xX]+)(.*)$/ ) {
                            $Vq += length($1);
                            $IEseq = $2;
                            $format .= "X(" . length($1) . ")";
                        }
                        else {
                            last;
                        }
                    }

                    #print "Vector segment found: $format. (Qleft:$Ql)\n";
                    $note_id = 4;
                    push( @warnings, 'Vector Segment' );
                    push( @comments, $format );
                }

                if ( $Vr > 0 ) { $Vt += $total_length - $Vr + 1; }
                if ( $Vl > 0 ) { $Vt += $Vl + 1; }

                if ( $Vt > $total_length ) {
                    $Vt = $total_length;
                    $Vl = $total_length;
                    $Vr = 0;
                }
            }
            elsif ( $total_length > 0 ) {
                $Vl             = -1;
                $Vr             = -1;
                $Vq             = 0;
                $Vt             = 0;
                $Ql             = -1;
                $Qr             = -1;
                $quality_length = 0;
                $note_id        = 1;
                push( @warnings, 'Poor Quality' );
            }
            else {
                $error          = 'Empty Read';
                $quality_length = 0;
                $total_length   = 0;
            }

            my $phd_file = $self->{phd_dir} . "/$clone.phd.1";
            ## open phd files to get scores
            open( PFILE, $phd_file ) or die("Error opening Phd file: $phd_file: $!\n");

            my @hist = map {0} ( 0 .. 99 );
            my @good = map {0} ( 0 .. 99 );

            while (<PFILE>) {
                $line = $_;
                if (/^TRIM:\s+(\d+)\s+(\d+)\s+(\d+[.]?\d+)/) {
                    $trim_left  = $1;
                    $trim_right = $2;
                }
                if (/^BEGIN_DNA/) {
                    last;
                }
            }

            my $total_score = "";
            my $total_seq   = "";
            my @all_scores;
            my $length = 0;

            my $index      = 1;
            my $good_left  = $Ql;
            my $good_right = $Qr;
            if ( $Vl > $Ql ) { $good_left = $Vl; }
            if ( ( $Vr >= 0 ) && ( $Vr < $Qr ) ) { $good_right = $Vr; }

            while (<PFILE>) {
                ( my $seq_bp, my $score, my $cumulative ) = split /[\s]/, $_;
                if ( $seq_bp =~ m/DNA/ ) {last}
                if ( ( $index >= $good_left ) && ( $index <= $good_right ) ) {
                    $good[$score]++;
                }
                $total_seq .= $seq_bp;
                push( @all_scores, $score );
                $hist[$score]++;
                $length++;
            }

            # Check for Repeating sequences
            my $insert = substr( $total_seq, $Ql, $quality_length );
            my $repeat;
            my $repeat_length = 2;
            while ( !$repeat && $repeat_length < 5 ) {
                $repeat = $self->_check_for_repeating_sequence( $insert, $repeat_length );
                $repeat_length++;
            }

            if ( $repeat && $insert ) {
                $note_id = 6;
                $p .= "** Add note: $repeat\n";
                push( @warnings, 'Recurring String $repeat' );
            }

            $p .= "Tr=$trim_right($Qr), Tl=$trim_left($Ql), Qlength=$quality_length, (trimmed = $good_length), Vl=$Vl, Vr=$Vr, Vq=$Vq; Vt=$Vt\n";

            #my @values = ($total_seq, $length, $Ql, $quality_length, $Vl, $Vr, $Vq, $Vt);

            my $warnings = join ",", @warnings;
            my $comments = join ",", @comments;

            #Populate the Read object
            my $read = Read->new(
                trace_name      => $clone,
                trace_file      => "$self->{chromat_dir}/$clone",
                sequence        => $total_seq,
                quality_scores  => \@all_scores,
                sequence_length => $length,
                quality_length  => $quality_length,
                quality_left    => $Ql,
                vector_left     => $Vl,
                vector_right    => $Vr,
                warnings        => $warnings,
                errors          => $error,
                comments        => $comments
            );
            if ($generate_trimmed_fasta) {
                my $start          = $Ql;
                my $end            = $Ql + $quality_length - 1;
                my $vector_quality = 0;
                if ( $Vl > $Ql ) { $start = $Vl + 1; }
                if ( $Vr > 0 && $Vr < $end ) { $end = $Vr - 1 }
                if ( $start < $end ) {
                    my $t_length         = $end - $start + 1;
                    my $poor_quality     = $length - $quality_length;
                    my $trimmed_sequence = substr( $total_seq, $start, $t_length );
                    my $version          = $self->{phred_version};
                    print TRIMMED ">$clone\t$t_length\t$start-$end / $total_length ($quality_length quality)\t(Trimmed: $poor_quality (poor) + $Vq (vector)) phred $version\n$trimmed_sequence\n";
                }
                else { print TRIMMED "$clone : (no trimmed sequence)\n"; }
            }
            push( @{ $self->{reads} }, $read );
            $self->{reads_index}->{$clone} = $self->{reads_count};
            $self->{reads_count}++;
        }
        close(PFILE);
    }
    close(TRIMMED) if $generate_trimmed_fasta;
    close(SCREEN);

    return $p;
}

####################
sub get_Read {
####################
    #
    #Gets a particular read object
    #
    my $self = shift;
    my %args = @_;

    my $trace_name = $args{trace_name} || shift;

    if ( exists $self->{reads_index}->{$trace_name} ) {
        return $self->{reads}[ $self->{reads_index}->{$trace_name} ];
    }
}

####################
sub print {
####################
    #
    #Prints the content of the Reads object
    #
    my $self = shift;

    foreach my $clone ( sort keys %{ $self->{reads_index} } ) {
        my $index = $self->{reads_index}->{$clone};
        $self->{reads}[$index]->print();
        print "\n";
    }

    print "Total Number of Reads: $self->{reads_count}\n";
}

####################
sub dump {
####################
    #
    #Dumps the content of the Reads into a hash
    #
    my $self = shift;

    my %reads;
    foreach my $clone ( sort keys %{ $self->{reads_index} } ) {
        my $index = $self->{reads_index}->{$clone};
        %{ $reads{$clone} } = %{ $self->{reads}[$index] };
    }

    return %reads;
}

#####################
sub create_CSV_file {
#####################
    my $self = shift;
    my $dir = shift || $self->{phd_dir};

    my $output;
    foreach my $clone ( sort keys %{ $self->{reads_index} } ) {
        my $index = $self->{reads_index}->{$clone};
        $output .= $self->{reads}[$index]->{trace_name} . "\t" . $self->{reads}[$index]->{Q20} . "\n";
    }

    open( FILE, ">$dir/Q20.csv" ) or die("Cannot open $dir/Q20.csv");
    print FILE $output;
    close(FILE);
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################

#########################################
sub _check_for_repeating_sequence {
#########################################
    #
    #  Check for repeating string given repetition length.
    #
    #  (ie 'atatatatat' has a repetition length of 2.
    #
    #  To qualify:
    #
    #   Total string length should be at least 5 x the repetition length
    #
    #   The non-repeating portion of the string reduces to less than twice the repetition length
    #
    my $self = shift;

    my $sequence = shift;    ### input sequence string
    my $length   = shift;    ### specify length of repeating sequence to check for

    my $Slength = length($sequence);

    if ( $Slength < $length * 2 ) { return "Very short sequence" }

    my $seq = substr( $sequence, $length, $length );    ### pull out N chars (offset by N)
    $sequence =~ s/$seq//g;

    if ( $Slength > 5 * $length ) {
        if ( length($sequence) < ( $length * 2 ) ) {
            my $times = ( $Slength - length($sequence) ) / $length;
            return "$seq($times)";
        }
        else { return 0; }
    }
    else { return "Too short to check for repeats"; }
}

##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

None.

=head1 FUTURE IMPROVEMENTS <UPLINK>

Add more attributes to the object.

=head1 AUTHORS <UPLINK>

Ran Guin and Andy Chan at the Canada's Michael Smith Genome Sciences Centre.

=head1 CREATED <UPLINK>

2003-07-14

=head1 REVISION <UPLINK>

$Id: Reads.pm,v 1.13 2004/02/27 17:50:35 achan Exp $ (Release: $Name:  $)

=cut

return 1;
