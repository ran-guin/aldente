###############################################################################################################
# MVC.pm
#
# Simple framework for File handling methods and functions
#
# $Id$
##############################################################################################################
package LampLite::File;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

File.pm - Contains simple generic file handling methods / functions 

=head1 SYNOPSIS <UPLINK>

=head1 DESCRIPTION <UPLINK>

=for html
Stores user session<BR>

=cut

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;

use LampLite::Bootstrap;
use RGTools::RGIO qw(filter_input Message xchomp);

use CGI qw(:standard);

my $q  = new CGI();
my $BS = new Bootstrap();

################################
sub archive_data_file {
################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $type = $args{-type};
    my $path = $args{-path};
    my $name = $args{-name};

    my $filehandle = $args{-filehandle};    ##

    my $file_fh;
    my $buffer = '';

    if ($name) { $name = "$path/$name" if $path }
    else { $self->get_unique_temp_file( -type => $type, -path => $path ) }    ### temp file

    open( $file_fh, ">$name" );
    binmode($file_fh);                                                                # change to binary mode

    while ( read( $filehandle, $buffer, 1024 ) ) {
        print $file_fh $buffer;
    }
    close($file_fh);

    # close original filestream
    close($filehandle);

    return $name;
}

#######################
#  Description
#		Return a fully qualified file name the file name will be unique to avoid conflicts
#	Note: NEEDS TO BE MOVED
#
#######################
sub get_unique_temp_file {
#######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $type = $args{-type} || 'tmp';    #
    my $path = $args{-path} || '';       ## $dbc->config('URL_temp_dir');

    my $found;
    my $file;

    ### temp file
    while ( !$file ) {
        my $random = int( rand(1000000) );
        $file = $path . '/' . $random . '.' . $type;
        if ( -e $file ) { $file = 0 }
    }

    return $file;
}

#
# Retrieves data from text file
# This method was originally in SDB::Import. Copied to here with a minor modification.
# The modification is:
#	the -save_copy_to parameter need to give the path that the input file is to be saved to.
#	Even if -input_file is a file handle, -save_copy_to still need to be specified if a copy needs to be saved.
#
# Usage:
#    my ( $headers, $data ) = LampLite::File->parse_text_file(
#            -input_file => $file,
#            -delimiter => ',',
#            -header_row => 2,
#            -skip_lines => 1,
#    );
#
# Return:  Array in the format of ( $headers_array_ref, $data_hash_ref )
#
##########################
sub parse_text_file {
##########################
    my $self            = shift;
    my %args            = filter_input( \@_, -args => 'input_file' );
    my $fields          = $args{-fields};                               ## optional field list (otherwise get fields from header)
    my $deltr           = $args{-delimiter} || "\t";
    my $save_copy       = $args{-save_copy_to};                         ## the path that the input file is to be saved to
    my $input_file_name = $args{-input_file};
    my $header_row      = $args{-header_row} || 1;
    my $skip_lines      = $args{-skip_lines} || $header_row - 1;

    my @lines;
    my $delim = get_delim($deltr);

    #if ( ref $input_file_name eq 'Fh' ) { $save_copy = 1; }	# it has to give the target directory to save in -save_copy_to argument

    my $FILE;
    my $READ;
    my $file = $input_file_name;
    if ($save_copy) {
        my $timestamp = timestamp();

        my $temp_file = "$save_copy/parse.$timestamp.txt";
        open $FILE, '>', $temp_file;
        $file = $temp_file;

        $READ = $input_file_name;
    }
    else {
        my $ok = open $READ, '<', "$input_file_name";
        if ( !$ok ) {
            Message("CANNOT OPEN $input_file_name: $!");
            return 0;
        }
    }

    my %data;
    my @headers = ();
    Message("Parsing File: $input_file_name");

    if ($fields) { @headers = @$fields }

    my $line_count     = 0;
    my $record_count   = 0;
    my $max_column_idx = 0;
    $max_column_idx = int(@headers) - 1;
    while (<$READ>) {
        $line_count++;
        if ( $skip_lines-- > 0 ) {next}
        ~s/\#.*//;    # ignore comments by erasing comment lines
        next if /^(\s)*$/;    # skip blank lines

        my $line = xchomp($_);    # remove trailing newline characters
        push @lines, $line;       # push the data line onto the array
        my @elements = split( $deltr, $line );

        if (@elements) {
            if ( !@headers ) { @headers = @elements; $max_column_idx = int(@headers) - 1 }    ## define first line as header line ##
            else {
                ## add this record to the data hash ##
                foreach my $i ( 0 .. $max_column_idx ) {

                    #my $value = $elements[$i] || '';
                    my $value = $elements[$i];
                    if ( length($value) == 0 ) { $value = '' }                                ## value zero can be kept in this way
                    push @{ $data{ $headers[$i] } }, $value;
                }
                ## <CONSTRUCTION> - could exclude lines with no data in any of the header fields (to get more accurate record count)

                $record_count++;
            }
        }

        if ($save_copy) { print $FILE "$line\n" }
    }

    return ( \@headers, \%data );
}

#
# simple delimiter accessor
#
# Usage:
#	my $delim = get_delim( 'comma' );
#
# Return:
#	Scalar, the symbol of the delimiter if defined in the function. If the delimiter is not defined in the function, the original input string will be returned.
#
##################
sub get_delim {
##################
    my $deltr = shift;

    my $delim = $deltr;

    if ( $deltr =~ /tab/i ) {
        $delim = "\t";
    }
    elsif ( $deltr =~ /comma/i ) {
        $delim = ",";
    }
    return $delim;
}

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
