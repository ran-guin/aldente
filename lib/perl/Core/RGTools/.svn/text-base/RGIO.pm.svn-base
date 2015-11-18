################################################################################
#
# RGIO.pm
#
# RGIO : This stands for Ran Guin Input/Output
#
# This provides a miscellaneous set of tools for use by Perl scripts
#
################################################################################
################################################################################
# $Id: RGIO.pm,v 1.134 2004/11/30 04:42:29 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.134 $
################################################################################
package RGTools::RGIO;

##############################
# perldoc_header             #
##############################
use Carp;
use Time::Local;

=head1 NAME <UPLINK>

RGIO.pm - RGIO : This stands for Ran Guin Input/Output I think -- kteague

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
RGIO : This stands for Ran Guin Input/Output I think -- kteague<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    err
    log_usage
    filter_input
    wildcard_match
    split_arrays
    resolve_range
    convert_to_range
    get_username
    set_difference
    set_operations
    chomp_edge_whitespace
    xchomp
    try_system_command
    create_dir
    date_time
    timestamp
    datestamp
    now
    today
    week_end_date
    Message
    HTML_Comment
    Test_Message
    Note
    get_line_with
    list_contains
    adjust_list
    array_containing
    toggle_colour
    dim_colour
    Link_To
    truncate_string
    Hlink_padded
    Log_Notes
    File_to_HTML
    random_int
    load_Stats
    Prompt_Input
    Get_Current_Dir
    Extract_Values
    Show_Tool_Tip
    Array_Exists
    Popup_Menu
    unique_items
    Call_Stack
    Cast_List
    Safe_Freeze
    Safe_Thaw
    input_error_check
    Parse_CSV_File
    Resolve_Path
    $Sess $session_id $user $dbase $project $banner $homelink $plate_id $plate_set $current_plates $step_name $solution_id $sol_mix $Current_Department
    $MenuSearch
    strim
    autoquote_string
    day_elapsed
    compare_objects
    compare_data
    read_dumper
    log_unit_test
    replace_last_line
    get_lines_between_tags
    get_MD5
    create_file
    deep_compare
    cmp_file_timestamp
    save_diffs
    get_array_index
);
@EXPORT_OK = qw(
    err
    log_usage
    filter_input
    wildcard_match
    split_arrays
    resolve_range
    convert_to_range
    get_username
    set_difference
    set_operations
    chomp_edge_whitespace
    xchomp
    try_system_command
    create_dir
    date_time
    timestamp
    datestamp
    now
    today
    week_end_date
    Message
    Test_Message
    Note
    get_line_with
    list_contains
    adjust_list
    array_containing
    toggle_colour
    dim_colour
    Link_To
    truncate_string
    Hlink_padded
    Log_Notes
    File_to_HTML
    load_Stats
    Prompt_Input
    Get_Current_Dir
    Extract_Values
    Show_Tool_Tip
    Array_Exists
    Popup_Menu
    unique_items
    Call_Stack
    Cast_List
    Safe_Freeze
    Safe_Thaw
    Parse_CSV_File
    Resolve_Path
    $session_id $user $dbase $project $banner $homelink $plate_id $plate_set $current_plates $step_name $solution_id $sol_mix $Current_Department
    $MenuSearch
    autoquote_string
    day_elapsed
    compare_objects
    compare_data
    read_dumper
    replace_last_line
    get_MD5
    create_file
    deep_compare
    cmp_file_timestamp
    save_diffs
    get_array_index
);

##############################
# standard_modules_ref       #
##############################

use Storable qw(store retrieve freeze thaw);
use Benchmark;
use Data::Dumper;
use Cwd 'abs_path';
use URI::Escape;
use POSIX qw(strftime);
use strict;

use File::Basename;
use File::Spec;

##############################
# custom_modules_ref         #
##############################

##############################
# global_vars                #
##############################
use vars qw($style $testing $scanner_mode $Sess $Session $Current_Department);
use vars qw($MenuSearch);
use vars qw($session_id $user $dbase $project $banner $homelink $plate_id $plate_set $current_plates $step_name $solution_id $sol_mix);    ### TEMPORARY
use vars qw($Connection);                                                                                                                  ## <CONSTRUCTION> - remove -temporary
use vars qw(%Benchmark); 
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $colour         = "blue";
my $note_colour    = "yellow";
my $warning_colour = "orange";
my $error_colour   = "red";
my $error_colour2  = "yellow";
my $colour2        = "yellow";
my $header_colour  = "#FF5555";
my $line_colour1   = "lightyellow";
my $line_colour2   = "DDDDDD";

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#===============================================================================================================#
# Method :
# Usage  :
#
# Return :
#===============================================================================================================#

##########
#
# Enable exception handling and return of '0' from methods/functions without dying.
# This returns 0 to be consistent with standard error returns, and generates a carp exception, but does not die.
#
# <snip>
#  Example:
# unless ($ok) { return err("Failed at this step") }
#
# (this generates a carp warning, but continues running, returning a '0' which can be recognized as a 'fail');
#
# If return 1 is used for some reason as a failure, then it can be called using the optional returnval paramater:
#
# unless ($ok) { return err("Failed at this step",1) }
#
# </snip>
#
# Return: 0 (or as specified)
############
sub err {
############
    my $message   = shift;
    my $returnval = shift;    ## optional return value (defaults to 'undef')
    my $verbose   = shift;    ## include details

    my $details = Dumper Call_Stack( -quiet => 1 ) if $verbose;
    Message( "Error: $message", $details );
    carp($message);
    return $returnval;
}

###################
#
# Provide for logging of input / output combinations for possible unit testing.
#
#
###################
sub log_unit_test {
###################
    my %args = &filter_input(
         \@_,
        -args      => 'input,output,file',
        -mandatory => 'input|args,output'
    );
    require YAML;
    my $input      = $args{-input};
    my $output     = $args{-output};
    my $file       = $args{-file};
    my $input_args = $args{-args};
    my $log        = $args{ -log };                                                      ##
    my $path       = $args{-path} || "/home/sequence/alDente/logs/alDente_unit_test";    ## default path <CUSTOM>
    my $debug      = $args{-debug};

    unless ( $log && $file ) {return}

    my $call = Call_Stack( -level => 1 );

    $call =~ s/::/\//g;
    my $caller;
    if ( $call =~ /(\w+)$/ ) { $caller = $1; }

    ## generate YAML for input ##
    my %Input = %{$input} if $input;
    if ($input_args) {
        map { $Input{$_} = $input_args->{$_} if defined $input_args->{$_} }
            keys %{$input_args};
    }
    my $yaml = YAML::Dump( \%Input );

    ## generate YAML for output ##

    my $filename;
    if ( $file =~ /\// ) {
        $filename = $file;
    }    ## if path explicitly defined ##
    else {
        `mkdir -p $path/$call` unless ( -e "$path/$call/" );
        $filename = "$path/$call/$caller.unit_test_" . &timestamp . ".case";
    }    ## standard storage structure (interfaces with viewing tools)

    open( CASE, ">$filename" ) || print "could not open $filename";
    if (<CASE>) {
        print CASE "*** INPUT ***\n" . YAML::Dump( \%Input );
        print CASE "*** OUTPUT ***\n" . YAML::Dump($output) if $output;
        print CASE "*** END ***\n";
        close(CASE);
    }
    Message("SAVED case to $filename");
    print $yaml if $debug;
    return;

}

###########################
#
# Simple function to allow detailed logging of script usage
#
###############
sub log_usage {
###############
    my %args    = @_;
    my $log     = $args{ -log };            ## file to log to
    my $data    = $args{-data};             ##
    my $message = $args{-message};
    my $user    = $args{-user};
    my $include = $args{-include} || '';    ## log inclusion options (eg. source, connection)
    my $object  = $args{-object};
    my $chmod   = $args{ -chmod };
    my $chown   = $args{ -chown };
    my $chgrp   = $args{-chgrp};

    my $include_source = grep /source/, ($include);

    $user ||= `whoami`;
    chomp $user;

    my $file = $0;

    open( FILE, ">>$log" ) or return "Error logging to $log";
    print FILE "\n" . date_time() . "\n";
    print FILE "User: $user\nFile: $0\n**************************\n";
    if ($include_source) {
        print FILE "** Source **\n";
        print FILE join "\n", @{ Call_Stack( -quiet => 1 ) };
        print FILE "\n";
    }
    if ($object) {
        print FILE "** Base Object Dump **\n";
        print FILE Dumper($object);
    }
    if ($data) {
        print FILE "** Data Dump **\n";
        print FILE Dumper($data);
    }
    if ($message) { print FILE "** Message **\n$message\n"; }
    close FILE;

    try_system_command("chmod $chmod $log") if $chmod;
    try_system_command("chown $chown $log") if $chown;
    try_system_command("chown $chgrp $log") if $chgrp;

    return;
}

###########################
# Ensures all arguments are in proper '-key => value' format
# Allows for indication of parameters that should be 'shifted' into arguments
# Allows for indication of defaults if values not supplied
#
# Logs details optionally to file
#
# Sends warning if '-key' detected for as a value
#
# <snip>
# Example:
#
#   ## allows 'func($id_list)' as short form for 'func(-sample_id=>$id_list)' format automatically ##
#
#   my %args = &filter_input(\@_,                   ## shift in all arguments
#                            -args=>'sample_id',    ## default order for shifted in arguments
#                            -mandatory=>'sample_id')
#                                 )
# </snip>
# Return: populated hash of input arguments.  (Error/Warning Message generated if there are any problems)
#
####################
sub filter_input {
####################
    my $args_ref = shift || '';    # first argument should be reference to input hash...
    
    unless ( !$args_ref || ref $args_ref eq 'ARRAY' ) {
        croak( "Error: must pass Array reference to filter_input\n" . Call_Stack( -quiet => 1 ) );
    }
    my @input_arguments = @$args_ref if $args_ref;

    my %output_hash;

    my %args = @_;

    my $params      = $args{-args};        # ordered list of parameters (if NOT already in args format) to be shifted in
    my $default_ref = $args{-defaults};    # ordered list of default values if applicable
    my $format_ref  = $args{-formats};     # ordered list of formats if applicable  (not yet utilized..)

    my $reset       = $args{ -reset } || 1;    # reset all arguments if auto-setting (otherwise maintains)
    my $mandatory   = $args{-mandatory};
    my $log         = $args{ -log };           # log this call in the specified log file...
    my $log_message = $args{-log_message};     # include this message with the standard log information
    my $username    = $args{-user} || '';      # user name (for logging purposes)
    my $quiet       = $args{-quiet};           # less verbose output..
    my $self        = $args{-self};            # Object that a method is called from
    my $verbose     = $args{-verbose};
    my $use_global  = $args{-use_global};      # <construction> - temporary to allow for global Connection object.
    my $fatal       = $args{-fatal};           # die on ERROR -
    my $debug       = $args{-debug};
                                               # (may be able to get rid of this when GSDB , SDB are combined) #
    my @parameters = Cast_List( -list => $params,      -to => 'array' ) if $params;
    my @defaults   = Cast_List( -list => $default_ref, -to => 'array' ) if $default_ref;

    ## allow input formats as array or hash keyed on arguments ##
    my @formats = Cast_List( -list => $format_ref, -to => 'array' ) if ref $format_ref eq 'ARRAY';
    my @format_keys = keys %$format_ref if ref $format_ref eq 'HASH';

    my $index = 0;

    ## Check to see if this method is called as a function or an object (set -self key if object identified) ##
    my ($object, $object_class);
    if ($self) {
        my $type = ref $input_arguments[0];
        if ( UNIVERSAL::isa( $type, "$self" ) || ($self && ($self eq $input_arguments[0])) ) {

            if ( !$type && ($self eq $input_arguments[0]) ) {
                ## (eg Module::Name->method() ) ##
                $object_class = shift @input_arguments if @input_arguments;    ## shift input arguments
             }
            else {
                ## eg ($Module->method()) ##
                $object = shift @input_arguments if @input_arguments;    ## shift input arguments
            }

            ## Object calling this method is recognized (shift the object out of the input arguments) ##            
            shift @$args_ref;                                        ## also remove here to be consistent
            
            ## only shift out first default parameter if it is self or dbc and it is already defined ## 
            if ($params && $parameters[0] =~/^(self|dbc)/) { shift @parameters }                       ## shift input parameter list
            
            shift @defaults    if @defaults;
            shift @formats     if @formats;
            shift @format_keys if @format_keys;
        }
        else {
            my $subtype = ref $type;
            print "Called as a function ($type ne $self) : $subtype.\n" if $verbose;
        }
    }

    ## make number of arguments even to allow mapping to hash
    
    unless ( int( int( @input_arguments / 2 ) ) == int(@input_arguments) / 2 ) {
        push( @$args_ref, '');
    }
    my %input_hash = @$args_ref if $args_ref;

    if ($object_class) {
        eval "require $object_class";
        ## complete object construction using optional standard dbc & id parameters ##
        my $dbc = $input_hash{-dbc};
        my $id = $input_hash{-id};
        $object = $object_class->new(-dbc=>$dbc, -id=>$id);
    }
    
    my @input_parameters;
    my @set_Defaults;
    my @set_Parameters;
    ### If arguments are required, set arguments based on list ###
    my @keys           = keys %input_hash;
    
    #    my @not_args       = grep /^[^-]/, @keys;   ## this didn't handle undef keys properly so was changed to logic below
    my @not_args;
    foreach my $key (@keys) { if ( $key !~ /^\-/) { push @not_args, $key } }

    my @signed_integer = grep /^-[\d\W]/, @keys;
    push( @not_args, @signed_integer ) if (@signed_integer);

    if (@not_args) {
        my @values = ('');
        @values = values %input_hash if %input_hash;
        my @offset = grep /^[-][a-zA-Z]/, @values;
        
        if (@parameters) {    ## shift each value into respective key in arguments hash ##
            $output_hash{-autoset} = 1;    ## set flag to indicate parameters were autoset
            undef @{$args_ref} if $reset;  ## clear arguments and start over (optional)
            my $key = 1;
            foreach my $parameter (@parameters) {
                my $value = $input_arguments[$index];
                
                push( @input_parameters, $value );
                if ( $args_ref && defined $input_arguments[$index] && $input_arguments[$index] =~ /^-([a-zA-Z].+)/ ) {
                    while ( $input_arguments[$index] =~ /^-([a-zA-Z].+)/ ) {
                        my $key = $1;

                        my $value = $input_arguments[ ++$index ];
                        $output_hash{"-$key"} = $value if defined $value;
                        $index++;
                    }
                    last;
                }
                elsif ( $input_hash{"-$parameter"} ) {
                    $output_hash{ERRORS} .= "** Error: $parameter input out of sequence (put all -key=>value pairs at the end)\n";
                }
                ## Set defaults if supplied ##
                unless ( $value || !$default_ref ) {
                    $value = $defaults[$index];
                    push( @set_Defaults, "$parameter => " . $defaults[$index] );
                }
                $output_hash{"-$parameter"} = $value;
                push( @set_Parameters, "$parameter => " . $value ) if defined $value;
                $index++;
            }
            ### get any other key=>value pairs that may be specified after default parameters ###
            while ( @input_arguments && defined $input_arguments[$index] && $input_arguments[$index] =~ /^-([a-zA-Z].+)/ ) {
                my $key   = $1;
                my $value = $input_arguments[ ++$index ];
                $output_hash{"-$key"} = $value;
                $index++;
            }
            if ( defined $input_arguments[$index] ) {
                my $extra = $input_arguments[$index];
                $output_hash{ERRORS} .= "** Error: Extra parameters detected ($extra ?) AFTER recognized parameters\n";
            }
        }
        elsif (@offset) {
            $output_hash{ERRORS} .= "** Error: Possible offset of parameters:\n";    ## check for possible offset keys ##
            foreach my $off (@offset) {
                $output_hash{ERRORS} .= "** Error: $off detected as a VALUE (should this be a key ?)\n";
            }
        }
        else {
            $output_hash{ERRORS} .= "** Error: Incorrect format (or at least supply parameter list)\n";
            foreach my $fail (@not_args) {
                $output_hash{ERRORS} .= "** Error: unrecognized Key: $fail\n";
            }
        }
    }
    else { %output_hash = %input_hash; }

    ## generate '-self' object if object identified ##
    $output_hash{-self} = $object if $object;
    
#    ## Temporarily populate '-self' object with global $Connection object for DBIO object types ##
#    $output_hash{-self} ||= $Connection if ( $use_global && $Connection && $self =~ /\bDBIO/ );    ## <CONSTRUCTION> ##

    my $errors;

    if ($mandatory) {
        my @missed;
        foreach my $required_arg ( Cast_List( -list => $mandatory, -to => 'array' ) ) {
            ## allow one of multiple arguments ##
            if ( $required_arg =~ /\|/ ) {
                my $found = 0;
                foreach my $arg ( split /\Q|/, $required_arg ) {
                    if ( exists $output_hash{"-$arg"} ) {
                        ### check for non-empty array ###
                        if ( $output_hash{"-$arg"} && ( ref( $output_hash{"-$arg"} ) eq 'ARRAY' ) ) {
                            if ( int( @{ $output_hash{"-$arg"} } ) ) {
                                $found++;
                                last;
                            }    ## ok ##
                            else {
                                print "Warning: '-$required_arg=>...' points to an empty array";
                            }
                        }
                        elsif ( $output_hash{"-$arg"} ) {
                            $found++;    ## ok
                            last;
                        }
                    }
                    else { Message("$arg NOT found") if $verbose; }
                }
                unless ($found) {
                    print "Warning: Missed argument (must supply one of: $required_arg)\n";
                    push( @missed, $required_arg );
                }
            }
            ### check for singularly mandatory arguments ###
            else {

                unless ( exists $output_hash{"-$required_arg"} ) {
                    print "Warning: add '-$required_arg=>...' to arguments\n";
                    push( @missed, $required_arg );
                    next;
                }
                if ( $output_hash{"-$required_arg"} && ( ref( $output_hash{"-$required_arg"} ) eq 'ARRAY' ) ) {
                    unless ( int( @{ $output_hash{"-$required_arg"} } ) ) {
                        print "Warning: '-$required_arg=>...' points to an empty array\n";
                        push( @missed, $required_arg );
                    }
                }
            }
        }
        ## generate error if there are any missed mandatory arguments ##
        if ( int(@missed) ) {
            $output_hash{ERRORS} .= "** Error: Missing required argument(s): @missed\n";
        }
    }
    if ($format_ref) {
        if ( @formats && @parameters ) {
            foreach my $index ( 0 .. $#parameters ) {
                my $key   = $parameters[$index];
                my $value = $output_hash{"-$key"};
                unless ( defined $value && $formats[$index] ) {next}
                unless ( $value =~ /$formats[$index]/ ) {
                    $output_hash{ERRORS} .= "** Error: $key ($value) failed format check (should be $formats[$index])\n";
                }
            }
        }
        elsif (@format_keys) {
            foreach my $key (@format_keys) {
                my $format_required = $format_ref->{$key};
                my $value           = $output_hash{"-$key"};
                unless ( defined $value && $format_required ) {next}
                unless ( $value =~ /$format_required/ ) {
                    $output_hash{ERRORS} .= "** Error: $key ($value) failed format check (should be $format_required)\n";
                }
            }
        }
    }

    ### Monitor Input, Defaults set, Parameters set ONLY IF auto-setting used ###
    my $input;
    if (@input_parameters) { $input->{INPUT}          = \@input_parameters; }
    if (@set_Defaults)     { $input->{set_Defaults}   = \@set_Defaults; }
    if (@set_Parameters)   { $input->{set_Parameters} = \@set_Parameters; }

    if ( $output_hash{ERRORS} ) {
        my $stack = join "<br>\n", @{ Call_Stack( -quiet => 1 ) };
        $output_hash{ERRORS} .= "\n** Call Stack **<br>\n$stack";
        $output_hash{ERRORS} .= "\nArgs:\n" . Dumper($args_ref);
        $log_message         .= $output_hash{ERRORS};
        croak( $output_hash{ERRORS} ) if ($fatal);    ## fatal error - abort
        Message( $output_hash{ERRORS} );              ## only goes here if 'no_die' option chosen
        return %output_hash;
    }

    if ($log) {
        unless ($username) {
            $username = `whoami`;
            chomp $username;
        }
        &log_usage(
            -log     => $log,
            -message => $log_message,
            -user    => $username,
            -data    => \%output_hash,
            -object  => $input,
            -include => 'source'
        );
    }

    return %output_hash;
}

#
# Test value for wildcard matches... 
#
# Usage:
#
#   wildcard_match(3,[1,2,3,4]);
#   wildcard_match('abc','ab*');
#   wildcard_match(4, '>2'); 
#
# Return: True if match passes
######################
sub wildcard_match {
######################    
    my $value = shift;
    my $format = shift;
    
    my @formats;    ## allow multiple tests at once if desired
    if (ref $format eq 'ARRAY') {
        @formats = @$format;
    }
    else {
        @formats = ($format);
    }
    
    foreach my $format (@formats) {
        if ($format =~/^(.*?)\|(.*)/) {
            $format = $1;
            my @options = split /\|/, $2;
            push @formats, @options;
        }
        
        if ($format eq $value) { return 1}
        elsif ($format =~/[\*]/) {
            $format =~s/\*/\.\*/g;
            ## test for ? or * wildcards ##
            if ($value =~/^$format$/) {
                return 1;
            }
        }
        elsif ($format =~/^([\<\>])\s?(\d+\.?\d*)$/) {
            ## number range ##
            my $op = $1;
            my $limit = $2;
            if ($op eq '>' && $value =~/^(\d+\.?\d*)$/ && $value > $limit) { return 1 }
            if ($op eq '<' && $value =~/^(\d+\.?\d*)$/ && $value < $limit) { return 1 }
        }
    }
    
    return 0;
}

############################################################
# Function: This function takes in an array of arrays, with each array of the same size.
#           The arrays will be broken down into $size-sized arrays.
# RETURN: An arrayref containing length of arrays/$size array references, each one containing
#         a number of array references equal to the original number of arrays.
###########################################################
sub split_arrays {
    my $array_of_arrays_ref = shift;
    my $size                = shift;
    my @array_of_arrays     = @{$array_of_arrays_ref};
    my @done                = ();
    my $counter             = 0;

    my $num_increments = scalar( @{ $array_of_arrays[0] } ) / $size + 1;

    foreach ( 1 .. $num_increments ) {
        my @single_array = ();
        foreach ( 1 .. scalar(@array_of_arrays) ) {
            push( @single_array, [] );
        }
        foreach ( 1 .. $size ) {
            my $index = 0;
            foreach my $arrayref (@array_of_arrays) {
                my $elem = shift( @{$arrayref} );
                unless ($elem) {
                    next;
                }
                push( @{ $single_array[$index] }, $elem );
                $index++;
            }
        }
        push( @done, \@single_array );
    }
    return \@done;
}

############################################################
# Function: This function will quote a comma-delimited string
#           ie A01,A02,A03 will become 'A01','A02','A03'
# Return: A string with each element quoted
############################################################
sub autoquote_string {
############################################################
    my $str = shift;    # (Scalar) a comma-delimited string
    $str = join( ',', map {"'$_'"} split( ',', $str ) );
    return $str;
}

############################################################
# Function: resolves a range of numbers into a full comma-delimited list
# RETURN: the range of numbers in a full comma-delimited list
###########################################################
sub resolve_range {
    my $range = shift;
    while ( ( $range =~ /(\-?\d+)[-](\-?\d+)/ ) && ( $2 >= $1 ) ) {
        my $numlist = join ',', ( $1 .. $2 );
        $range =~ s/$1[-]$2/$numlist/;
    }    
    
    return $range;
}

############################################################
# Function: resolves a full comma_delimited list into a range of numbers
# RETURN: the range of numbers in range format (1-3,5,7-10, etc)
###########################################################
sub convert_to_range {
###########################
    my $range = shift;

    my @array = split ',', $range;
    @array = sort { $a <=> $b } @array;

    my %rangehash;
    foreach my $val (@array) {
        if ( defined $rangehash{ $val - 1 } ) {
            $rangehash{$val} = $rangehash{ $val - 1 };
            delete $rangehash{ $val - 1 };
        }
        else {
            $rangehash{$val} = $val;
        }
    }
    my @complete_range = ();
    foreach my $key ( sort { $a <=> $b } keys %rangehash ) {
        my $range_val = $key;
        if ( $key != $rangehash{$key} ) {
            $range_val = "$rangehash{$key}-$key";
        }
        push( @complete_range, $range_val );
    }

    return join( ',', @complete_range );
}

############################################################
# Function: get the unix username of the user running the script
# RETURN: the unix userid of the user
############################################################
sub get_username {
    my $username = &RGTools::RGIO::try_system_command("whoami");
    chomp $username;
    return $username;
}

###############################
# Subroutine: takes in two array references A, B, and does A - B (set difference
# Return: arrayref of elements in A that are not in B
############################
sub set_difference {
############################
    my $A = shift;    # (Arrayref) first array
    my $B = shift;    # (Arrayref) second array

    my %A_elements;
    foreach ( @{$A} ) {
        $A_elements{$_} = 1;
    }

    foreach ( @{$B} ) {
        if ( defined $A_elements{$_} ) {
            $A_elements{$_}++;
        }
    }
    my @difference = ();
    foreach ( keys %A_elements ) {
        if ( $A_elements{$_} == 1 ) {
            push( @difference, $_ );
        }
    }

    #my @difference = grep { $A_elements{$_} == 1 } keys(%A_elements);
    return \@difference;
}

#######################
sub set_operations {
#######################
    my $A         = shift;
    my $B         = shift;
    my @A         = @{$A};
    my @B         = @{$B};
    my $operation = shift || 'intersect';    ## Union,Intersection

    my @union = ();
    my %union = ();

    my @isect = ();
    my %isect = ();
    my @diff  = ();

    my %count = ();

    foreach my $e ( @A, @B ) { $count{$e}++ }

    foreach my $e ( keys %count ) {
        push( @union, $e );

        if ( $count{$e} == 2 ) {
            push( @isect, $e );
        }
        else {
            push( @diff, $e );
        }
    }

    if ( $operation =~ /intersect/i ) {
        return \@isect;
    }
    elsif ( $operation =~ /union/i ) {
        return \@union;
    }
    elsif ( $operation =~ /diff/i ) {
        return \@diff;
    }
    else { return 0 }
}

###############################
# Subroutine: takes in a string and removes leading and trailing whitespaces
# Return: the string with the leading and trailing whitespaces removed
############################
sub chomp_edge_whitespace {
############################
    my $str = shift;    # (Scalar) a string

    $str =~ s/^\s+//;
    $str =~ s/\s+$//;

    return $str;
}

###############################
# Subroutine: takes in a string and removes trailing whitespaces
# Return: the string with trailing whitespaces removed
############################
sub xchomp (\$) {
############################
    my $str_ref = shift;    # (Scalar) a string
    $$str_ref =~ s/\s+$//;
    return ${$str_ref};
}

###############################
# Subroutine: takes in an array reference, and returns an array reference of that array with duplicates removed
# Return: An array reference with elements identical to the input, but with duplicates removed
############################
sub unique_items {
############################
    my $array = shift;
    ### algorithm from the perl cookbook
    ### page 102
    my %seen = ();
    my @unique = grep { !$seen{$_}++ } @$array;
    return \@unique;
}

###############################
#
# run Shell command (returns STD output)
#
############################
sub try_system_command {
############################
    my %args = &filter_input( \@_, -args => 'command,linefeed,remote' );

    my $command  = $args{-command};                       # command to execute
    my $linefeed = $args{-linefeed};                      # linefeed command (optional) to separate output
    my $remote   = $args{-remote};                        # optional remote login host
    my $include  = $args{-include} || 'stdout,stderr';    # include stderr in output by default
    my $verbose  = $args{-verbose} || 0;
    my $Report   = $args{-report};
    my $host     = $args{-host}; 

    my $separate_errors = 1 if wantarray();               ## separate STDOUT, STDERR in output if array context

    if ($Report) {
        $Report->set_Detail("EXEC: $command");
    }

    my $feedback = "";
    my $errors   = "";
    $linefeed ||= "\n";

    if ($remote) { $command = qq{rsh $remote $command}; }
    if ($host) { $command = qq{ssh $host "$command"}; }

    my $pid;
    my $PROC;
    if ( $separate_errors || $Report ) {    ## STDOUT, STDERR
        $pid = open( PROC, qq{($command | sed 's/^/STDOUT:/') 2>&1 |} );
    }
    elsif ( ( $include =~ /stderr/ ) && ( $include =~ /stdout/ ) ) {    ## STDOUT + STDERR
        $pid = open( PROC, qq{$command 2>&1 |} );
    }
    elsif ( $include =~ /stderr/i ) {                                   ## STDERR only
        $pid = open( PROC, qq{$command 2>&1 1>/dev/null |} );
    }
    else {                                                              ## STDOUT only
        $pid = open( PROC, qq{$command |} );
    }

    while (<PROC>) {
        my $line = chomp_edge_whitespace($_);
        if ( $separate_errors || $Report ) {
            $line .= $linefeed;
            if ( $line =~ s/^STDOUT:// ) {
                $feedback .= $line;                                     ## parse out STDOUT if applicable
            }
            else {
                $errors .= $line;
            }
        }
        else {
            if ( $line =~ /$linefeed$/ ) {
                $feedback .= $line;
            }
            else {
                $feedback .= $line . $linefeed;
            }
        }
    }
    close PROC;

    if ($Report) {
        $Report->set_Error($errors)    if ($errors);
        $Report->set_Detail($feedback) if ($feedback);
    }
    elsif ($verbose) {
        print "SHELL CMD: $command\n";
        print "$feedback\n";
        print "** Errors: **\n$errors\n" if ($separate_errors);
    }

    if ($separate_errors) {
        return ( $feedback, $errors );
    }    ## return (STDOUT,STDERR)
    else {
        return $feedback;
    }    ## return STDERR included in STDOUT.
}

#########################
#
# Retrieves date_time in 'YYYY-MM-DD HH:MM:SS' format
#
# parameter allows you to specify forward or back (-) any number of
# seconds (s), minutes(m), hours(h) or days(d).
#
#  eg. date_time('-1d') retrieves the same time yesterday
#
##################
sub date_time {
##################
    my %args = &filter_input(
         \@_,
        -format => { offset => '^[+\-]?\d+\s?[smhdSMHDwWyY]' },
        -args   => 'offset'
    );
    my $offset = $args{-offset} || '';    # optional other time or +/- number of days
    my $date = $args{-date} || $args{-time};
    
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime();
    
    my $time = time();  ## default to current time ##
    if ( $date =~ /^\d+$/ ) {
        ## assume time is already appropriate mode (seconds from whenever... ?) ##
        $time = $date;
     }
    elsif ($date=~/\d\d\d\d\-\d\d-\d\d/) {
        require RGTools::Conversion;
        my $formatted_time = RGTools::Conversion::convert_time($time, 'SQL');
        if ($date =~/^(\d\d\d\d)\-(\d\d)\-(\d\d)\s*(\d*)\:?(\d*)\:?(\d*)/) {
            $year = $1;
            $mon = $2;
            $mday = $3;
            $hour = $4 || '12';
            $min = $5 || '00';
            $sec = $6 || '00';
        }
        
        $mon--;   ## for some reason timelocal requires zero indexed months ??
           
        $time = timelocal( $sec, $min, $hour, $mday, $mon, $year );  ## reset time variable to specified date/time 
    }
    elsif ($offset =~/^\d+$/ && !$date) {
        ## assume user supplied default date rather than default offset ##
        $time = $offset;
        $offset = '';
    }
    
    ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($time);

    if ( $offset =~ /(\d+)(\s*w)/i ) {
        my $string = $2;
        my $weeks  = $1;
        my $days   = $weeks * 7;
        $offset =~ s/$weeks$string/$days d/;
    }
    if ( $offset =~ /(\d+)(\s*y)/i ) {
        my $string = $2;
        my $years  = $1;
        my $months = $years * 12;
        $offset =~ s/$years$string/$months mo/;
    }

    my $newtime;
    my $addon;
    ## allow offset of months  ##
    if ( $offset =~ /(-)?(\d+)\s*mo/i ) {
        my $plus   = $1;
        my $local_offset = $2;
        if ( $plus eq '-' ) { $local_offset *= -1; }
        $mon = $mon + $local_offset;
        while ( $mon >= 12 ) { $mon = $mon - 12; $year++; }
        while ( $mon < 0 )  { $mon = $mon + 12; $year--; }
    }
    ############# if standard time units are specified... ###########
    elsif ( $offset =~ /^[+\-]?(\d+)\s?([smhdSMHD])/ ) {
        my $adjust = $1;
        my $units  = $2;
        if    ( $units =~ /s/i ) { $addon = $adjust; }
        elsif ( $units =~ /m/i ) { $addon = $adjust * 60; }
        elsif ( $units =~ /h/i ) { $addon = $adjust * 60 * 60; }
        else                     { $addon = $adjust * 60 * 60 * 24; }
        if ( $offset =~ /^\-/ ) { $addon *= -1; }
        
        $time += $addon;        ## adjust time as required... 
        ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($time); 
    }
    ############### otherwise convert from stat time...################
    # <CONSTRUCTION> remove this block after format option is added to filter_input
    # Check for the correct delay time format
    elsif ($offset) {    ## defined delay time, but not recognized (?)
        print "<h3> error: invalid delay ($offset)</h3>";
        Call_Stack();
        return;
        ############### otherwise supply current local time... ############
    }
    else {
        ## use default localtime settings ##
    }

    my $nowtime = sprintf "%02d:%02d", $hour, $min;  ## changed to exclude seconds ... 
    my $nowdate = sprintf "%04d-%02d-%02d", $year + 1900, $mon + 1, $mday;
    $nowdate =~ s/ /0/g;
    $nowtime =~ s/ /0/g;
    my $date_time = $nowdate . " " . $nowtime;

    #    print "TIME: $date_time";
    return ("$date_time");
}

##################
sub timestamp {
##################
    my $time = join '', date_time();
    $time =~ s/[\:\-\s]//g;
    return $time;
}

##################
sub datestamp {
##################
    my ($date) = split ' ', date_time(@_);
    $date =~ s/[\:\-\s]//g;
    return $date;
}

#########################
#
# Returns DateTime (parameter allows you to specify +/- N days)
#
# Format:  YYYY-MM-DD 00:00:00
#
sub now {
    my $offset_days = shift || 0;    # +/- number of days eg. now(-1) for yesterday
    my $today;
    my $nowtime;

    if ($offset_days) {
        ( $today, $nowtime ) = split ' ', &date_time( -offset => "$offset_days" . "d" );
    }
    else { ( $today, $nowtime ) = split ' ', &date_time(); }

    return "$today $nowtime";
}

#########################
#
# Returns Date (parameter allows you to specify +/- N days)
#
# format:  YYYY-MM-DD
#
############
sub today {
############
    my $offset_days = shift || 0;    # (eg &today(-1) for yesterday)
    my $today;
    if ($offset_days) {
        ($today) = split ' ', &date_time( -offset => "$offset_days" . "d" );
    }
    else {
        ($today) = split ' ', &date_time();
    }
    return $today;
}

######################
sub week_end_date {
######################

    my $weeks_ago  = shift;    ## specify weeks ago prior to current week (starting Mon)
    my $week_start = shift;    ## start day (Monday = 1, Tues = 2 ....

    if ( $week_start =~ /^(\d+)$/ && $week_start < 8 && $week_start > 0 ) { }
    elsif ($week_start) {
        Message("Invalid week starting point (should be 1-7)");
    }
    else { $week_start = 1; }

    my $past;
    if ($weeks_ago) { $past = $weeks_ago * 7; }

    my $year;
    my $month;
    my $day;
    if   ($past) { ( $year, $month, $day ) = split '-', &today("-$past"); }
    else         { ( $year, $month, $day ) = split '-', &today(); }

    my $days_ago = $past;
    require Date::Calc;
    while ( Date::Calc::Day_of_Week( $year, $month, $day ) != $week_start ) {
        $days_ago++;
        ( $year, $month, $day ) = split '-', &today("-$days_ago");
    }
    if ( $day < 10 ) {
        $day = sprintf "%2d", $day;
        $day =~ s/ /0/;
    }
    my $week_end = "$year-$month-$day";
    return $week_end;
}

#################
#
# Generates a message
#
###########
sub Message {
###########
    my %args = filter_input( \@_, -args => 'title,message,type,colour' );

    my $title   = $args{-title}   || '';    # message title
    my $message = $args{-message} || '';    # content of message
    my $type   = $args{-type};              # type (eg. 'html' or 'text' or 'hidden') (default = html or global $style variable)
    my $colour = $args{-colour};            # colour of message for html format (optional)
    my $log    = $args{ -log };             # file to log messages into

    my $size     = $args{-size} || '-1';                  # size of message...
    my $brief    = $args{-brief}    || $scanner_mode || 0;
    my $no_print = $args{-no_print} || $args{-return_html};

    ## DEPRECATED - use Bootstrap messaging instead ##
    
    unless ($type) {
        if ( $0 =~ /ajax/i ) {
            $type = 'ajax';
        }
        elsif ( $0 =~ /Web_Service/i ) {
            $type = 'text - web_service';
        }
        elsif ( $0 =~ /\.html$/ || $0 =~ /\/cgi-bin\// ) {
            $type = 'html';
        }
        elsif ( $0 =~ /\.xml$/ ) {
            $type = 'xml';
        }
        else {
            $type = 'text';
        }
    }
    my $output = '';

    if ( !$colour ) {
        if ( $title =~ /^error\b/i ) {
            $colour  = $error_colour;
            $colour2 = $error_colour2;
            $size    = 0;
        }
        elsif ( $title =~ /^warning\b/i ) {
            $colour  = $warning_colour;
            $colour2 = $error_colour2;
            $size    = -1;
        }
        else { $colour = $note_colour; $colour2 = $colour; }
    }

    if ( $type =~ /^t/i ) {    ### print in simple text format
        $output = "$title $message\n";
    }
    elsif ( $type eq 'ajax' ) {
        $output = $title;
    }
    elsif ( $type =~ /hidden/ ) {
        ### no printout if hidden...
    }
    elsif ($brief) {           ### print simple html for scanners...
        if ( $title =~ /^(error|warning)\b/i ) {
            $output = "<B><FONT COLOR='black' style='background-color:$colour'>&nbsp;$title $message</FONT></B><BR>";
        }
        else {
            $output = "<FONT COLOR='black' style='background-color:$colour'>&nbsp;$title $message</FONT><BR>";
        }
    }
    elsif ( $type =~ /html/i ) {
        $message =~ s /\n/<BR>/g;    ## replace linefeeds with br
        $output .= "\n<TABLE cellpadding =3 cellspacing=0><TR><TD bgcolor=$colour align='left'>";
        if ($size) { $output .= "\n<Font size=$size> "; }
        $output .= "<B>$title</B>";
        if ($size) { $output .= "</Font>"; }
        $output .= "</TD><TD bgcolor=$colour2 align = left>";
        if ($size) { $output .= "\n<Font size=$size> "; }
        $output .= " $message";
        if ($size) { $output .= "</Font>"; }
        $output .= "</TD></TR></TABLE>";
    }
    elsif ( $type =~ /xml/i ) {
        $output .= "<message>$title $message</message>\n";
    }

############ Custom Insertion (append log files ##################

    my $prefix;
    if ( $type =~ /hidden/ ) {
        $prefix = "(H):";
    }    ### indicate that this message was hidden

    if ( ( $title =~ /^Warning\b/i ) || ( $message =~ /^Warning\b/i ) ) {
        $prefix = "** WARNING **";
    }
    elsif ( ( $title =~ /^Error\b/i ) || ( $message =~ /^Error\b/i ) ) {

        # Call_Stack();
        $prefix = "***** ERROR *****";

        #	unless ($scanner_mode || $type=~/text/) { &Window_Alert("$title $message"); }
    }
    else { $prefix = "* Message *"; }

    my $session_id;

    ### <CONSTRUCTION> change so that an optional log file is supplied which is appended with message ##
    my $session_dir;
    if ( $Sess && defined $Sess->{session_id} && defined $Sess->{session_dir} ) {
        $session_id  = $Sess->{session_id};
        $session_dir = $Sess->{session_dir};
        my $SESSION;

        create_dir($session_dir);
        
        open( SESSION, ">>$session_dir/$session_id.sess" ) or die("Cannot save session info file: $session_dir/$session_id.sess");
        print SESSION "$prefix $title - $message\n";
        close(SESSION);
    }
    ############ End Custom Insertion (append log files ##################

    if ($log) {
        my $LOG;
        open( LOG, ">>$log" ) or die('Cannot append log file: $log.');
        print LOG "$prefix $title - $message\n";
        close(LOG);
    }
    
    if ($no_print) {
        return $output;
    }
    else {

        if ( $type =~ /web_service/i ) { $output =~ s/\n/\:  /g; }    ## linefeeds break Web Service output ...
        print $output;
    }
    return;
}

###########
sub HTML_Comment {
###########
    my $message = shift;
    my %args    = &filter_input( \@_ );
    my $format  = $args{'-format'} || 'html';

    my $prefix;
    my $suffix;
    if ( $format =~ /html/i ) {
        $prefix = "\n<i><font size=-1>";
        $suffix = "</i></font>\n";
    }

    return $prefix . $message . $suffix;
}

######################
#
# Generates a message only if in 'test mode'
#
sub Test_Message {
    my $message       = shift;         # message
    my $test_mode     = shift || 0;    # test mode
    my $message_level = shift || 0;

    if ( $test_mode > $message_level ) {
        print $message . "<br>\n";
    }
    return 1;
}

###################
#
# outputs Note to screen (like Message without title)
#
sub Note {
    my $message = shift;    ## message content
    my $type    = shift;    # type (defaults to $style or 'text')

    if ( defined $style ) { $type ||= $style; }

    if ( $type =~ /^h/i ) {
        print "<TABLE cellpadding =3><TR><TD bgcolor = $colour>";
        print "<B>Note</B> </TD><TD bgcolor = $colour>";
        print $message;
        print "</TD></TR></TABLE>";
    }
    else {
        print "Note  $message\n";
    }
    return 1;
}

#########################
#
# Retrieves line from multi-line string that contains given search string
#
sub get_line_with {
    my $string   = shift;            # multi-line string
    my $search   = shift;            # search string
    my $linefeed = shift || '\n';    # linefeed separator

    my @lines = split( $linefeed, $string );
    my $return_string = "";
    foreach my $line (@lines) {
        if ( $line =~ /$search/i ) {
            $return_string .= $line . "\n";
        }
    }

    return $return_string;
}

#########################
sub list_contains {
#########################
    #
    # Returns flag indicating whether one string is an element in a delimited string
    # (ie does the string: "abcd,gef,hij,klm" contain the string "hij" ?);
    #
    # (Removes spaces first) - short string should not contain spaces.
    #
    # Returns 0 if not found.
    #(returns index number of string if found (first element returns '1')
    #
    my $longstring  = shift;            #
    my $shortstring = shift;            # search string
    my $separators  = shift || "\,";    # delimiter character (default = ',')

    $longstring =~ s/ //g;              #remove spaces.

    my $found;

    my $count = 0;
    foreach my $element ( split /$separators/, $longstring ) {
        if ( $element eq $shortstring ) { $count++; }
    }
    return $count;

}

######################
sub adjust_list {
######################
    #
    # Note unique lists may scramble order...
    #
    my $array   = shift;    ## input array
    my @options = @_;       ## array of options - just supply text (eg. adjust_list(\@array,'unique','rev');)

    my $unique   = grep /uni/i,      @options;    ## unique list
    my $maintain = grep /maintain/i, @options;    ## maintain order
    my $sort     = grep /^sort/,     @options;    ## sort
    my $reverse  = grep /^rev/,      @options;    ## reverse sort

    my @new_list;
    if ( $unique && $maintain ) {                 ## generate UNIQUE list but MAINTAIN current order.
        foreach my $item (@$array) {
            unless ( grep /^$item$/, @new_list ) {
                push( @new_list, $item );
            }
        }
    }
    elsif ($unique) {                             ## generate UNIQUE list (order unimportant)
        my %unique_list;
        map { $unique_list{$_} = 1 } @$array;
        @new_list = keys %unique_list;
    }
    else {
        @new_list = @$array;
    }

    #    if ($reverse) { return rnatsort @new_list; }  ## Sorted
    #    elsif ($sort) { return natsort @new_list; }  ## Reverse sorted
    #    else { return @new_list; }                   ## unsorted...

    if ($reverse) {
        return sort { $b <=> $a } @new_list;
    }    ## Sorted
    elsif ($sort) {
        return sort { $a <=> $b } @new_list;
    }    ## Reverse sorted
    else { return @new_list; }    ## unsorted...
}

#########################
sub array_containing {
#########################
    #
    # Returns an array containing only those elements of original array matching expression
    #
    my $original_array = shift;    #
    my $pattern = shift || ",";    # delimiter character (default = ',')

    my @sub_array;

    foreach my $element (@$original_array) {
        if ( $element =~ /$pattern/ ) {
            push( @sub_array, $element );
        }
    }
    return @sub_array;
}

##############################
sub toggle_colour {
##############################
    #
    # this returns the 'other' colour when given 1
    # (repeated calls of $colour=toggle_colour($colour) yields colour toggling)
    #
    my $colour  = shift;    # input colour (normally = line_colour1 or line_colour2)
    my $colour1 = shift;
    my $colour2 = shift;

    $colour1 ||= $line_colour1;
    $colour2 ||= $line_colour2;

    if ( qq{$colour} eq qq{$colour1} ) {
        $colour = $colour2;
    }
    else {
        $colour = $colour1;
    }
    return $colour;
}

##############################
sub dim_colour {
########################
    #
    # Returns 2nd colour if value is zero...(used to dim cells if no value)
    # (eg. $dim_colour($value,$bright,$dim) returns $bright if $value > 0
    #

    my $value       = shift;    # value to test
    my $good_colour = shift;    # colour to return if value > 0
    my $dim_colour  = shift;
    ;                           # colour to return if value = 0

    if   ($value) { return $good_colour; }
    else          { return $dim_colour; }
}


#
# Link label to href...
#
#################
sub Link_To {
#################
    my %args = filter_input( \@_, -args => 'link_url,label,param,colour,window,script,tooltip,style,method,form_name' );

    #read in options as arguments
    my $link_url     = $args{-link_url};
    my $label        = $args{-label};
    my $addons       = $args{-param};                ### add parameters to link
    my $colour       = $args{-colour} || '';
    my $hover_colour = $args{-hover_colour} || '';
    my $new_window   = $args{-window};               ## = ['newWinName','options...']
    my $options      = $args{-window_options};
    my $alt_script   = $args{-script};
    my $tool_tip     = $args{-tooltip};              ### Optional tool tip. If provided then it will override the default tooltips. If provide and value is '', then no tooltip will be displayed.
    my $style        = $args{-style};                ## in-line style of the link.
    my $method       = $args{-method} || "GET";      ## method of sending data - POST or GET
    my $alt          = $args{-alt};                  ## alt script for A Href
    my $formname     = $args{-form_name};            ## Form name the link exists in. Relevant only for POST method
    my $tooltip_placement = $args{-tooltip_placement};  ## for bootstrap tooltip placement 
    my $trigger   = $args{-trigger};
    my $convert_to_HTML = $args{-convert_to_HTML};   ## eg converts \n linefeeds in tooltips to html <BR> tags 
  
    #    my $font_size = "size='$args{-font_size}'" if ($args{-font_size});
    my $uline
        = defined $args{-ul}
        ? $args{-ul}
        : 1;                                         ## allow setting of underline flag off or on (default to on)
    my $mouseover = $args{-mouseover};
    my $mouseout  = $args{-mouseout};
    my $truncate  = $args{'-truncate'};              ## truncate label (appends ...) - shows full label as tooltip unless tooltip already provided.
    my $tip_style = $args{-tip_style};

    $addons =~s/Scan=1/cgi_application=alDente::Scanner_App&rm=Scan/;   ## <CONSTRUCTION> - replace old calls with CGI App call... 

    if   ( $link_url =~ /\?/ ) { $addons =~ s/^\?/\&/ }
    else                       { $addons =~ s/^\&/\?/ }

    my $TT_width;

    $label =~ s /<BR>/\n/ig;                         ## convert break tags to allow ...
    if ( $truncate && $label !~ /<.*>/ ) {           ## do not truncate if it contains tags (more complicated)
        $TT_width = '50em';
        unless ($tool_tip) { $tool_tip = $label; }
        $label = &truncate_string( $label, $truncate );
    }

    ## add style elements to link object as required ##
    $style .= " text-decoration:none; " if ( !$uline || ( $uline =~ /(no|false)/ ) );    ## remove underline effect
    $style .= " color:$colour; " if $colour;
    if ($style) {
        $style = " style=\"$style\"";
    }
    else {
        $style = '';
    }
    ##

    unless ($tool_tip) {                                                                 #
        $mouseover .= " this.style.color='$hover_colour';" if $hover_colour;
        $mouseout  .= " this.style.color='$colour';"       if $colour;
    }

    if ( $mouseover && !$tool_tip ) {
        $mouseover = "onMouseOver=\"$mouseover\"";
    }
    else {
        $mouseover = '';
    }

    if ( $mouseout && !$tool_tip ) {
        $mouseout = "onMouSeOut=\"$mouseout\"";
    }
    else {
        $mouseout = '';
    }

    my $in_form = 0;
    if ($formname) {
        $in_form = 1;
    }
    my $wname = RGTools::RGIO::Cast_List( -list => $new_window, -to => 'string' );

    if ( $addons =~ /\s/ ) { $addons = URI::Escape::uri_unescape($addons) }
    $addons =~ s /\s+/\%20/g;

    if ( $link_url =~ /\s/ ) {
        $link_url = URI::Escape::uri_unescape($link_url);
    }
    $link_url =~ s /\s+/\%20/g;

    my $default_options = "height=800,width=1000,scrollbars=yes,resizable=yes,toolbar=yes,location=no,directories=no";

    my $show = $label;

    #    if ($style) { $show = "\n<span style=$style>\n$show\n</span>\n" }

    if ( !( defined $tool_tip ) && !$scanner_mode && !$mouseover && !$mouseout ) {
        if ( $addons =~ /Info=1.*Table=([a-zA-Z0-9_]+)&*/ ) {
            $tool_tip = "View $1";
        }
        elsif ( ( $addons =~ /Edit\+Table=([a-zA-Z0-9_]+)&*/ ) && !$mouseover && !$mouseout ) {
            $tool_tip = "Edit $1";
        }
    }

    my $addon_string_hidden = undef;
    my $rand_num            = undef;
    if ( $method eq "POST" ) {

        # create the hidden declarations
        $addon_string_hidden = "";

        # remove leading question mark
        $addons =~ s/^\?(.*)/$1/;

        # split on &
        my @arguments = split( /&/, $addons );
        foreach my $arg (@arguments) {

            # split on the first = sign
            my ( $name, $value ) = split( /=/, $arg, 2 );

            #remove + and replace with spaces
            $value =~ tr/+/ /;
            $addon_string_hidden .= "<input type=\"hidden\" name=\"$name\" value=\"$value\"/>";
        }

        # get a random number
        $rand_num = int( rand(100000) );
        $formname ||= "linksubmit$rand_num";
    }

    ## generate return value ##
    my $tt_prefix = '';    ## "\n<div id='divToolTip' class='toolTipCont'><!--Empty div--></div>\n" .  ## this causes a linebreak - can we remove that effect ?
##	"<script type='text/javascript'>setToolTip()</script>\n" if $show_tool_tip;

    my $output = '';
    if ($new_window) {
        unless ( $options =~ /[a-z]/ ) {
            $options = $default_options;
        }
        ### leave out line returns to prevent padding...
        if ( $method eq "POST" ) {

            # if in a form, do not create form tags
            if ($in_form) {
                $output .= qq{$tt_prefix$addon_string_hidden<A Href="$link_url" $style $mouseover $mouseout $alt_script onclick="document.$formname.submit();return false;">$show</A>};
            }
            else {
                $output
                    .= qq{$tt_prefix<form name="$formname" method="post" action="$link_url" $style target="$wname">$addon_string_hidden</form><A Href="$link_url" style=$style $mouseover $mouseout $alt_script onclick="document.$formname.submit();return false;">$show</A>};
            }
        }
        else {
            chomp $addons;
            $output .= qq{$tt_prefix<A Href="$link_url$addons" $style $mouseover $mouseout onClick="window.open('$link_url$addons','$wname','$options'); return false;" $alt_script>$show</A>};
        }
    }
    else {
        if ( $method eq "POST" ) {
            if ($in_form) {
                $output .= qq{$tt_prefix\n$addon_string_hidden\n<A Href="$link_url" $style $mouseover $mouseout $alt_script onclick="document.$formname.submit();return false;">$show</A>};    ## maintain dark font
            }
            else {
                $output
                    .= qq{$tt_prefix<form name="$formname" method="post" action="$link_url" $style $mouseover $mouseout target="">$addon_string_hidden</form><A Href="$link_url" style=$style onclick="document.$formname.submit();return false;" $alt_script>$show</A>}
                    ;                                                                                                                                                                          ## maintain dark font
            }
        }
        else {
            $output .= qq{$tt_prefix<A Href="$link_url$addons" $style $mouseover $mouseout $alt_script>$show</A>};                                                                             ## maintain dark font
        }
    }

    if ($tool_tip) {
#        $tip_style .= "width:$TT_width;" if ( $TT_width && ( $tip_style !~ /width:/ ) );
#        $tip_style .= "white-space:normal;" if ($TT_width);
#        $tip_style = "style=\"$tip_style\"" if $tip_style;
#        ## use simple hover in css to handle tool tips ##
#        #	$output =~s/<A (.*?)<\/A>/<A class='info' $1<span $tip_style>$tool_tip<\/span><\/A>/i unless $scanner_mode;
        $output = &Show_Tool_Tip( $output, $tool_tip, -placement=>$tooltip_placement, -trigger=>$trigger, -convert_to_HTML=>$convert_to_HTML);
    }

    return $output;
}
      
#####################
sub make_thumbnail {
#####################
    my %args = &filter_input( \@_, -args => 'input,output' );

    my $input  = $args{-input};
    my $output = $args{-output};
    my $text   = $args{-text};
    my $rotate = $args{-rotate};
    my $resize = $args{-resize};    # format is 100x100 (in pixel)

    my $extra_args = "";

    if ($rotate) {
        $extra_args .= " -rotate $rotate ";
    }
    if ($resize) {
        $extra_args .= " -scale $resize ";
    }

    if ($text) {
        my $pointsize = 32;
        Message("Writing $text");
        $extra_args .= " -fill black -draw 'text 10,50 \"$text\"' $output -pointsize $pointsize";
    }

    my $command = "/usr/X11R6/bin/convert $input $extra_args $output";

    #    Message("Running $command");
    try_system_command($command);
}

#####################
sub Hlink_padded {
#####################
    #
    # pad spaces with + signs for hyperlinks...
##

    my $string = shift;

    $string =~ s/\s/+/g;
    return $string;
}

#################################
#
# Generate Sequencing Notes and write to Error log file
#
sub Log_Notes {
################
    my $preface    = shift;    # Preface message with this text
    my $message    = shift;    # message content
    my $LocalStyle = shift;    # defaults to $style (global variable) or 'text'
    my $LocalFile  = shift;    # file to write to (defaults to $error_directory/Err(date)
    my $rewrite    = shift;    # rewrite log file (default = append)

    ( my $nowdate, my $nowtime ) = split / /, &date_time();
    $LocalStyle ||= $style;
    $LocalStyle ||= "text";

    #   $LocalFile ||= "$error_directory/Err$nowdate";
    my $ERROR;
    if ( $LocalStyle =~ /h/i ) {
        if ($rewrite) {
            open ERROR, ">$LocalFile" or print "\nCannot open $ERROR\n";
        }
        else {
            open ERROR, ">>$LocalFile" or print "\nCannot open $ERROR\n";
        }
        print ERROR "$preface $nowtime\n$message\n";
        close ERROR;
    }
    else {
        print "$preface\n$message\n";
    }

    return;
}

########################
sub File_to_HTML {
########################
    my $filename  = shift;
    my $title     = shift || 'Info';
    my $separator = shift || "\t";

    my $output;

    if ($filename) {
        my $SEQFILE;
        open( SEQFILE, "$filename" ) or print "Error opening $SEQFILE ($filename)";
        my $Table = HTML_Table->new();
        $Table->Set_Title($title);
        my $index = 0;
        while (<SEQFILE>) {
            my $line = $_;
            $index++;
            if ( $line =~ /$separator/ ) {
                my @row = ();
                while ( $line =~ /^(.*?)$separator(.*)/ ) {
                    $line = $2;
                    push( @row, $1 );
                }
                push( @row, $line );
                $Table->Set_Row( \@row );
            }
            else {
                if ( $Table->{rows} > 0 ) {
                    $Table->Set_sub_header( "$line", 'lightredbw' );
                }
                else {
                    $Table->Set_sub_header( $line, 'lightredbw' );
                }
            }
        }
        $output .= $Table->Printout(0);
    }
    else { print "Nothing Found"; }

    return $output;
}

########################
sub random_int {
    my $min = shift || 0;
    my $max = ( defined $_[0] ) ? $_[0] : 100;

    # Assumes that the two arguments are integers themselves!
    return $min if $min == $max;

    ( $min, $max ) = ( $max, $min ) if $min > $max;
    return $min + int rand( 1 + $max - $min );
}

###################
sub load_Stats {
###################
    my $load_file = shift || 'Statistics';
    my $Stats_dir = shift;
    my $lock      = shift;
    my $quiet     = shift || 1;              ### with feedback  ?

    my %check;

    my $pre_load_time = new Benchmark;

    my $Stats;

    if ($lock) {

        #	if (-e "$Stats_dir/$load_file.lock") {
        #	    unless ($quiet) {print "$load_file locked (waiting...)";}
        #	    my $index=0;
        #	    while (-e "$Stats_dir/$load_file.lock") {
        #		sleep 2;
        #	    }
        #	}
        &Lock_File("$Stats_dir/$load_file");
    }

    if ( -e "$Stats_dir/$load_file" ) {
        print "retrieve $Stats_dir/$load_file..\n" unless $quiet;
        $Stats = &Storable::retrieve("$Stats_dir/$load_file");
        my $post_load_time = new Benchmark;

        my $load_time = &timediff( $post_load_time, $pre_load_time );
        unless ($quiet) {
            print "<BR>\n<Font size=-2>";
            print "$load_file Retrieval Time: " . timestr($load_time);
            print "</Font><BR>\n";
        }

        #	return &retrieve("$Stats_dir/$load_file");
        return $Stats;
    }
    else {

        #	$Stats = {};
        #	Message("Error: $load_file File Not found !");
        #	Call_Stack();
        return;
    }
}

###################
sub Lock_File {
###################
    my $file = shift;

    my $details = &date_time() . "\t" . $ENV{USER} . " : " . $0;

    my $ok = try_system_command("echo $details > $file.lock");
    $ok .= try_system_command("chmod 777 $file.lock");
    return $ok;
}

###################
sub Unlock_File {
###################
    my $file = shift;

    my $ok = try_system_command("rm -f $file.lock");
    return $ok;
}

#################
sub Show_ENV {
#################
    #
    # just display environment variables...
    #
    my $linefeed = shift || "\n";

    my @keys = keys %ENV;

    foreach my $key (@keys) {
        print "$key = " . $ENV{$key};
        print $linefeed;
    }
    return;
}

##################
sub Prompt_Input {
##################
    #
    #Takes command-line input from user and returns the input.
    #
    my %args = &filter_input( \@_, -args => 'type,prompt' );    # Options can be: 'single', 'passwd'

    my $type   = $args{-type}   || 'string';
    my $prompt = $args{-prompt} || '';
    my $format = $args{-format};            ## optional formatting requirement (regexp) - eg '\d\d\d\d' or 'y|n'

    my $ans;

    use Term::ReadKey;

    while (!$ans) {
	print "$prompt>";
	if ( $type =~ /^(single|c)/ ) {                             #Just read one key without the need to press the return key.
	    ReadMode('cbreak');
	    $ans = ReadKey(0);
	    ReadMode('normal');
	    print "$ans\n";                                         #Display input and then go to next line.
	}
	elsif ( $type =~ /^pass/ ) {                                #For password inputs - do not display the input characters.
	    ReadMode('noecho');
	    $ans = ReadLine(0);
	    chomp($ans);
	    ReadMode('normal');
	    print "\n";
	}
	else {                                                      # Regular input
	    $ans = <STDIN>;
	    chomp($ans);
	}

	if ($format && $ans !~/$format/i) {
	    $format =~s/\|/ OR /g; 
	    print "response must be '$format'";
	    $ans = '';
	}
	else { last }                                              # allow return of empty string if no format supplied...
	    
    }
    

    return $ans;
}

########################
sub Get_Current_Dir {
########################
    #
    #This function returns the current directory.
    #
    my $current_dir;
    if ( -l $0 ) {

        #if the file name is indeed a symlink then need to dereference.
        my $realfile = readlink $0;
        $realfile =~ /^(.*)\//;
        $current_dir = $1;
    }
    elsif ( $0 =~ /^(.*)\// ) {
        $current_dir = $1;
    }
    else {
        $current_dir = cwd();
    }

    return $current_dir;
}

#######################
sub Extract_Values {
#######################
    #
    # This function receives a list of values in an array format and return the first defined value.
    # Future enhancement:  Add switches to test for value as well (e.g. >10, alphanumeric, etc)
    #
    my $values_ref = shift;

    my $retval;

    foreach my $value ( @{$values_ref} ) {
        if ( defined $value && $value ne '' ) {
            $retval = $value;
            last;
        }
    }

    return $retval;
}

########################################
#
#  Tool tip that will only show up in mozilla, not recommended (returns nothing right now since it is disabled)
#
#
####################
sub Show_Moz_Tool_Tip {
####################
    my $html_tag     = shift;
    my $tool_tip_msg = shift;    #The message of the tooltip.
    my $no_tips      = shift;

    if ( $no_tips || $scanner_mode ) { return $html_tag }

    my $output;

    if ( ( defined $tool_tip_msg ) && ( $tool_tip_msg ne '' ) && ( $tool_tip_msg ne '0' ) ) {
        $output = "\n<tooltip>\n  $html_tag\n  <span class='tip'>$tool_tip_msg</span>\n</tooltip>\n";
    }
    else {
        $output = $html_tag;     #Just return what was passed in
    }

    #  return $output;
    return undef;
}

#######################
sub Show_Tool_Tip {
#######################
    my %args                = &filter_input( \@_, -args => 'element,tip,notip,break_on' );
    my $html_tag            = $args{-element};
    my $tool_tip_msg        = $args{-tip};                                                   # The message of the tooltip.
    my $no_tips             = $args{-notip};
    my $type               = $args{-type} || 'tooltip';                    ## tooltip or popover 
    my $onclick             = $args{-onclick};                                           ## onclick spec
    my $tag_options         = $args{-tag_options};                                        ## optional non-standard html tag options 
    ## Bootstrap specific options ##
    my $html                = $args{-html} || 'true';
    my $title               = $args{-title};
    my $placement           = $args{-placement};                                              ## position (based upon Bootstrap tooltip object)
    my $animation           = $args{-animation};                                              ## position (based upon Bootstrap tooltip object)
    my $trigger             = $args{-trigger};                                               ## trigger - click | hover | focus | manual.
    my $convert_to_HTML     = defined $args{-convert_to_HTML} ? $args{convert_to_HTML} : 1;                ## Automatically reformat linefeeds to html line breaks (set to 0 to leave formatting as is)
    my $delay               = $args{-delay};
    my $style   = $args{-style};
    my $help_button = $args{-help_button};									## flag to indicate that the message to be displayed as tooltip/popover of of a help button
   
    if ($ENV{DISABLE_TOOLTIPS} ){
       return $html_tag;
    }

	## if help_button flag is on, the message will be automatically displayed as clickable popover of a question mark button
	if( $help_button ) {		
		$type = 'popover';
		$trigger = 'click';
	}
	 
    $tool_tip_msg =~ s/[\'\"]/\'/g;
    $tool_tip_msg =~ s/\r//g;
    
    if ($convert_to_HTML) { $tool_tip_msg =~ s/\n/<br>/g; }
    my $attributes;
   
    my $options;
    ## Include custom html tags ##
    if ($onclick) { $options .= qq( onclick="$onclick") } 
    if ($tag_options) { $options .= qq ( $tag_options) }              ## support any additional non-standard html tag input 
    
    ## Include Bootstrap tooltip options ##
    if ($title && $type =~/pop/) { $options .= qq( data-title="$title") }
    if ($html) { $options .= qq( data-html="$html") }
    if ($placement) { $options .= qq( data-placement="$placement") }
    if ($animation) { $options .= qq( data-animation="$animation") }
    if ($trigger) { $options .= qq( data-trigger="$trigger") }
    if ($delay) { $options .= qq( data-delay="$delay") }

    if ($type =~/tip/) { $attributes = qq(rel="tooltip" data-content="$tool_tip_msg" title="$tool_tip_msg" $options) }
    if ($type =~/pop/) { $attributes = qq(rel="popover" data-original-title="$title" data-content="$tool_tip_msg" $options) }
    
    if ( !( $scanner_mode || $no_tips ) && $tool_tip_msg ) {
    	if( $help_button ) {
	    	my $msg_button = qq(<A>);
	    	$msg_button .= qq(<SPAN $attributes style='$style'>);
	    	$msg_button .= qq(<BUTTON type="button" class="fa fa-question-circle"></BUTTON>);
	    	$msg_button .= qq(</SPAN>);
	    	$msg_button .= qq(</A>);
	    	$html_tag .= $msg_button;
    	}
        elsif ($html_tag =~/<.*>/) {
            ## use span as a wrapper tag - tooltip handled via css / js (bootstrap standard) ## .. may even be able to remove entire above to simplif
            $html_tag = "<SPAN $attributes style='$style'>\n$html_tag\n</SPAN>";                       
        }
        else {
            ## use A Href as a wrapper tag if no other embedded tags - tooltip handled via css / js (bootstrap standard) ## .. may even be able to remove entire above to simplif
            $html_tag = "<A Href='#' $attributes style='$style' onclick='return false;'>\n$html_tag\n</A>";           
        }
    }
    
    return $html_tag;
}

#######################
sub Array_Exists {
#######################
    #
    #Search an array for existance of a given element.
    #
    my $array_ref = shift;    #Pass in reference to the array to be searched.
    my $search    = shift;    #Pass in the element searching for.

    my $found = 0;
    foreach my $element ( @{$array_ref} ) {
        if ( $element =~ /^$search$/ ) {
            $found = 1;
            last;
        }
    }

    return $found;
}

############################
# Displays the call stack
#
# Returns an arrayref
############################
sub Call_Stack {
##############
    my %args = &filter_input( \@_, -args => 'level' );

    my $level      = $args{-level};         # Maximum level of calls to go
    my $line_break = $args{-line_break};    # Linebreak character
    my $quiet      = $args{-quiet};
    my $debug      = $args{-debug};

    if ($args{-debug}) { print "Content-type: text/html\n\n" } ## avoid internal server errors...

    my $type;
    if    ( $0 =~ /\.html$/ )     { $type = 'html'; $line_break ||= '<BR>'; }
    elsif ( $0 =~ /\/cgi-bin\// ) { $type = 'html'; $line_break ||= '<BR>'; }
    else                          { $type = 'text'; $line_break ||= "\n"; }

    my %calls;
    my $retval;

    push( @$retval, "M => $0" );
    my $i = 0;
    unless ($quiet) { print "*** Call Stack *** " . $line_break; }
    while (1) {
        my ( $package, $file, $line ) = caller($i);
        my ( undef, undef, undef, $calling_function ) = caller( $i + 1 );
        $calling_function ||= '';
        $package          ||= '';

        $calling_function =~ s/.*::(\w+)/$1/;
        if ( $level && ( $i == $level ) ) {
            return $package . "::" . $calling_function;
        }
        elsif ($package) {
            my $info = "$i => '$package\:\:$calling_function()' ($line)";
            push( @$retval, $info );
            unless ($quiet) {
                if ( $type =~ /html/ ) {
                    print "<Font size=-2>";
                    print "$info$line_break";
                    print "</Font>";
                }
                else {
                    print $info. $line_break;
                }
            }
        }
        else {
            last;
        }
        $i++;
    }

    return $retval;
}

#############################
# Cast a string or an array ref
# to the desired output
#############################
sub Cast_List {
#################
    my %args = @_;
    my $list                = $args{-list};                     # The list to be casted
    my $delimiter           = $args{-delimiter} || ",";    # The delimiter used for the string list
    my $to                  = $args{-to};    # The format to cast to (i.e. 'array','arrayref','string')
    my $autoquote           = $args{-autoquote};    # put each element in quotes
    my $pad                 = $args{-pad} || 0;    # if single value supplied, pad array to list of length $pad
    my $pad_mode            = $args{-pad_mode};
    my $default             = defined $args{-default} ? $args{-default} : '';
    my $limit               = $args{-limit}|| 1000;                   # limit to length of auto-expanded ranges (eg 1-4 -> 1,2,3,4)
    my $trim_leading_zeros  = $args{-trim_leading_zeros};    # Remove leading zeros (and leading spaces) 
    my $trim_leading_spaces  = $args{-trim_leading_spaces} || $trim_leading_zeros;    # Remove leading spaces (will not trim zeros unless specified) 
    my $no_split            = $args{-no_split};    # suppress splitting on delimiter (just casts between ref types)
    my $sort                = $args{ -sort } || 0;
	my $resolve_range		= defined( $args{-resolve_range} ) ? $args{-resolve_range} : 1;	# flag to resolve range. This flag should be 0 by default. But for backword compatibility, it's set to 1 for now so that it doesn't affect the existing functions.
	
    my @arr = ();
    my $retval;

    if ( ref($list) eq 'ARRAY' ) {
        @arr = @$list;
    }
    elsif ( defined $list ) {
    	if( $resolve_range ) {
        	while ( $list =~ /(^|,)(\-?\d+)\s*\-\s*(\-?\d+)(,|$)/ ) {   ## replace range specification with list
            	my $replace = &resolve_range("$2-$3");
            	$list =~ s /(^|,)$2\s*\-\s*$3(,|$)/$1$replace$2/g;

            	last unless $limit--;    ## just in case this is somehow way too long...
        	}
    	}
	    ### Trim leading and trailing spaces... ##
	    $list =~s/^\s+//;
	    $list =~s/\s+$//;
        if   ($no_split) { @arr = ($list) }
        else             {  @arr = split /\s*$delimiter\s*/, $list }

        unless ($list) { @arr = ($default); }
    }
    else {
        return;
    }

    if ( ( int(@arr) == 1 ) && $pad ) {    
        ## pad to list of similar values #
        @arr = map { $arr[0] } ( 1 .. $pad );
    }
    elsif ( int(@arr) == $pad ) {

    }
    elsif ($pad && int(@arr)) {
        my $repeat = $pad / int(@arr);
        unless ( $repeat == int($repeat) ) {
            Message("Warning: Invalid number in array ($list) $pad / @arr : " . int(@arr));
            Call_Stack();
#            use Data::Dumper
#            print Dumper \%args;
            
            return;
        }
        if ( $pad_mode eq 'Stretch' ) {
            my @temp_arr = @arr;
            @arr = ();
            foreach my $value (@temp_arr) {
                for ( my $i; $i < $repeat; $i++ ) {
                    push( @arr, $value );
                }
            }
        }
        elsif ( $pad_mode eq 'Zero' ) {
            @arr = map {
                my $size = length($_);
                if ( $size < $pad ) { $_ = '0' x ( $pad - $size ) . $_ }
            } @arr;
        }
    }

    if ($trim_leading_spaces) {
        @arr = map {
            my $item = $_;
            $item =~ s/^\s+(\w)/$1/;    ## remove leading spaces
            $item =~ s/(\w)\s+$/$1/;    ## remove trailing spaces
            if ($trim_leading_zeros) {
                if ( $item =~ /^\d+$/ ) {   ## If all digits
                    $item =~ s/^0+//;       ## Remove leading zeros
                    if ( $item =~ /^$/ ) { $item = '0'; }    ## If all zeros, put one zero back
                }
            }
            $_ = $item;
        } @arr;
    }

    ## autoquote ##

    if ($autoquote) {
        @arr = map {
            my $element = $_;
            unless ( $element =~ /^[\'\"]/) { $element = "'$element'" }
            $element;
        } @arr;
    }

    my @sorted = @arr;
    if ( $sort =~ /desc/i ) {
        @sorted = sort { $b <=> $a } @arr;
    }
    elsif ($sort) {
        @sorted = sort { $b <=> $a } @arr;
    }

    if ( $to =~ /\barray\b/i ) {
        return @sorted;
    }
    elsif ( $to =~ /\barrayref\b/i ) {
        return \@sorted;
    }
    elsif ( $to =~ /\bstring\b/i ) {
        return join "$delimiter", @sorted;
    }
    elsif ($to =~ /^(OL|UL)/i) {
        ## cast to an HTML Ordered or Unordered list 
        my $list_type = $1;
        my $html = "<$list_type><LI>";
        $html .= join '</LI><LI>', @sorted;
        $html .= "</$list_type>";
        if (@sorted) { return $html }
        else { return }
    }
    else { print "target list format not specified" }
    return;
}

########################################################################################################
# Safely perform the freeze/encode function
# Make sure does not exceed the Windows CE limit on URL params in POST of 2083 characters
# Return:
# - ArrayRef ('-format'=>'array'): An array of the param chopped in pieces
# - String ('-format'=>'hidden'):  A string of the param chopped in pieces embedded in HTML hidden fields
# - String ('-format'=>'url'):     A string of the param chopped in URL parameters format
#
# eg.
#
#  $hyperlink .= "&paramy=$valy" . '&' . Safe_Freeze(-name=>'paramx', -value=>$value, -format=>'url', -encode=>1);
#
#  $page .= $q->hidden(-name=>'paramy', -value=>$valy) . Safe_Freeze(-name=>'paramx', -value=>$valx, -format=>'hidden', -encode=>1);
#
# Return: string value to be used as applicable based on format
########################################################################################################
sub Safe_Freeze {
#####################
    my %args = @_;

    my $value   = $args{-value};                                                      # The param to be encoded
    my $format  = $args{'-format'};                                                   # Specify the return format
    my $encode  = defined $args{-encode} ? $args{-encode} : 0;                        # Whether to encode as well
    my $name    = $args{-name} || 'Frozen_Param';                                     # The name of the param to be frozen (only needed if format is 'hidden' or 'url')
    my $exclude = defined $args{-exclude} ? $args{-exclude} : 'dbh,connection,dbc';
    my $debug = $args{-debug};
    my $MAX_LENGTH = $args{-max_length} || 1000; # Just playing safe; give it some leeway instead of going 2083, only applicable to HTML param

    require MIME::Base32;

    if ( $exclude && ref($value) =~ /(HASH|\:\:)/ ) {
        ## frozen value should be a hash or an object ##
        my @excluded = Cast_List( -list => $exclude, -to => 'array' );
        ### Since we can't freeze/thaw the DBI::db objects, we have to kill 'em all
        foreach my $exclude_key (@excluded) {
            if ( $value->{$exclude_key} ) {
                delete $value->{$exclude_key};
            }
        }
    }

    if ($debug) { print Dumper 'ARGS', \%args }
    
    require YAML;
    my $frozen = YAML::freeze($value);
    
    if ($debug) { Message("Frozen: $frozen") }
    
    if ($encode) { $frozen = MIME::Base32::encode($frozen) }

    if ($debug) { Message("Encoded: $frozen") }

    my $pos = 0;
    my $retval;
    while ($frozen) {
        my $chopped = substr( $frozen, $pos, $MAX_LENGTH );
        my $chopped_length = length($chopped);

        if ( $format =~ /hidden/i ) {
            $retval .= "<input type='hidden' name='$name' value='$chopped'/>\n";
        }
        elsif ( $format =~ /array/i ) {
            push( @$retval, $chopped );
        }
        elsif ( $format =~ /url/i ) {
            if   ($retval) { $retval .= "&$name=$chopped" }
            else           { $retval .= "$name=$chopped" }
        }

        $frozen = substr( $frozen, $pos + $chopped_length );
    }
    if ($debug) { Message("Returned: $retval") }
    return $retval;
}

########################################################################################################
# Safely perform the thaw/decode function on a param frozen/encoded by the Safe_Freeze function
# Return: The original param string
########################################################################################################
sub Safe_Thaw {
####################
    my %args = @_;

    my $name = $args{-name} || 'Frozen_Param';    # The name of the param to be thaw
    my $thaw = defined $args{-thaw} ? $args{-thaw} : 1;    # Whether to thaw the string now
    my $encoded
        = defined $args{-encoded}
        ? $args{-encoded}
        : 0;                                               # Whether to the param was encoded
    my $retval = $args{-value};
    my $bless = $args{ -bless };
    my $debug = $args{-debug};

    require MIME::Base32;
    my $q = new CGI;
    
    if ( !$retval && $q->param($name) ) {
        my @input = $q->param($name);
        $retval = join "", @input;
    }

    if ($debug) { Message("Original (pre thaw): $retval"); print Dumper \%args }
    
    if ($retval) {
        my $decoded = $retval;

        require YAML;
        if ($encoded) { $decoded = MIME::Base32::decode($retval) }
        
        if ($debug) { Message("Decoded: $decoded") }
        
        if ($thaw)    { $retval  = YAML::thaw($decoded) }
        if ($debug) { Message("Thawed"); print Dumper $decoded; }
    }
    else { $retval = {} }

    if ($bless) { $retval = bless $retval, $bless }
    return $retval;
}

#############################################
# Automatic formatting check
#
# Return : list of errors (\n separated list)
#############################################
sub input_error_check {
###################
    my %args       = @_;
    my $input_ref  = $args{-input};
    my $format_ref = $args{'-format'};
    my $mandatory  = $args{-mandatory};

    my %input_args = %{$input_ref};

    my @errors;
    if ($mandatory) {
        foreach my $key (@$mandatory) {
            unless ( defined $input_args{$key} ) {
                push( @errors, "No $key argument supplied." );
            }
        }
    }

    if ($format_ref) {
        foreach my $key ( keys %{$format_ref} ) {
            my $format = $format_ref->{$key};
            my $value  = $input_args{$key};
            if ( $format =~ /^\/(.*)\/$/ ) {    ## REGEXP Check ##
                my $pattern = $1;
                unless ( $input_args{$key} =~ /$pattern/ ) {
                    push( @errors, "$key argument should be regexp : $pattern." );
                }
            }
        }
    }

    my $error_list = join "\n", @errors;
    return $error_list;
}

##########################################################################################
# Wrapper to easily create a directory (including recursive subdirectories) as required
#
# <snip>
# (add subdirectories to path (if required) - eg $path/2008/12/31/ )
#
# my $new_path = create_dir($path,-mode=>751);  ## create path directory (no subdirectories)
# my $new_path = create_dir($path, convert_date( &date_time(),'YYYY/MM/DD'),'777');  ## create subdirectories for date ##
#
# </snip>
#
# Returns final path (0 if permission denied to create any of subdirectories)
#################
sub create_dir {
#################
    my %args   = filter_input( \@_, -args => 'path,subdirectory,mode,chgrp' );
    my $path   = $args{-path};
    my $subdir = $args{-subdirectory};
    my $mode   = $args{-mode} || '777';
    my $grp		= $args{-chgrp};

    my @dirs = ('');    ## base directory
    if ($subdir) {
        push @dirs, ( split '/', $subdir );
    }

    my $LOGBASE = $path;
    foreach my $sub (@dirs) {
        $LOGBASE .= "/$sub" if $sub;
        if ( !-e "$LOGBASE" ) {
            my $ok = try_system_command("mkdir '$LOGBASE' -p -m $mode");
            if ( $ok =~ /cannot create directory/i ) { Call_Stack(); return err ("Cannot create $LOGBASE");  }

            if( $grp ) {
	            my ( $out, $err ) = try_system_command("chgrp $grp '$LOGBASE'");
	            return err( "Cannot change group", 0, $err ) if( $err );
            }
        }
    }
    
    return $LOGBASE;
}

##############################
# Resolve a file/directory into 2 components
# Return an array:
# - first element: fully qualified path except the file or directory itself
# - second element: the file or directory itself
##############################
sub Resolve_Path {
    my $path = shift;

    my $prefix;
    my $dir;

    $path =~ s/\/\//\//go;    # Replace '//' by '/'
    if ( $path =~ /(.*\/)(.*)/o ) {
        $prefix = $1;
        $dir    = $2;
    }
    else {
        $dir = $path;
    }

    return ( $prefix, $dir );
}

##############################################
# Parse CSV file
#
# Return formats supported are:
#
# - AofH (The default format):
#   $retval[0] = ('Field1' => 'Value1 of first record', 'Field2' => 'Value2 of first record')
#   $retval[1] = ('Field1' => 'Value1 of second record', 'Field2' => 'Value2 of second record')
#
# - HofH (Use ONE of the retrieved fields as the key to the record hash, or use the reocrd number as the key to the record hash):
#   a) User specified 'Field1' as the keyfield:
#      $retval{'Value1 of first record'}{'Field2'} = 'Value2 of first record'
#      $retval{'Value1 of second record'}{'Field2'} = 'Value2 of second record'
#   b) User did not specified any keyfield:
#      $retval{1}{'Field1'} = 'Value1 of first record'
#      $retval{1}{'Field2'} = 'Value2 of first record'
#      $retval{2}{'Field1'} = 'Value1 of second record'
#      $retval{2}{'Field2'} = 'Value2 of second record'
#
##############################################
sub Parse_CSV_File {
    my %args = @_;

    my $file         = $args{-file};                  # The file to be parsed [String]
    my $file_handle  = $args{-file_handle};
    my $columns_ref  = $args{-columns};               # The fields (field numbers) to be extraced from the file [ArrayRef of Int]
    my $fields_ref   = $args{-fields};                # The name of the fields extracted [ArrayRef of String] - If not specified then use the name provided in the file
    my $header_lines = $args{-header};                # The number of lines that the column header span [Int]
    my $delimiter    = $args{-delimiter};             # The separator/delimiter to separate the columns
    my $exclude      = $args{-exclude};               # Lines to exclude from parsing
    my $replace      = $args{-replace};               # Replace character with blank
    my $format       = $args{'-format'} || 'AofH';    # Return format
    my $keyfield     = $args{-keyfield};              # The keyfield to be used if return format is 'HofH'
    my $CSV_FILE;

    if ($file) {
        open( $CSV_FILE, "$file" ) or die "Error opening file: '$file'";
        print ">>Parsing '$file'...<br>\n";
    }
    elsif ($file_handle) {

        $CSV_FILE = $file_handle;

        #print $CSV_FILE;
    }
    else {
        return 0;
    }
    my $added = 0;
    my $tried = 0;
    my @failed;
    my $line_num = 0;
    my $skipped  = 0;
    my @columns;
    my @fields;

    if ($columns_ref) {
        $columns_ref = Cast_List( -list => $columns_ref, -to => 'arrayref' );
        @columns = @$columns_ref;
    }
    if ($fields_ref) {
        $fields_ref = Cast_List( -list => $fields_ref, -to => 'arrayref' );
        @fields = @$fields_ref;
    }

    #if ($columns_ref){

    #    }

    #   if ($fields_ref)
    #  {

    #    }
    my $i = 0;
    my $retval;

    while (<$CSV_FILE>) {

        my $line = $_;

        if ( $exclude && $line =~ /^$exclude/ ) { $skipped++; next; }
        if ($replace) {
            $line =~ s/$replace//g;
        }    ## replace character with blank.
        if ( $line =~ /(.*\S)/ ) {
            $line = $1;
        }    ## clear NT linebreak (chomp doesn't seem to do it ??)

        if ( !$delimiter && !( $line =~ /\t/ ) ) {
            next;

            #if (!($line=~/\S/)) {next;}
            #print "\nWarning:  Line $i contains no tabs\n\n";
        }
        $line_num++;

        if ( $header_lines >= $line_num ) {
            print "skipping line $line_num (header)\n";
            next;
        }
        if ( !( $line =~ /\S/ ) ) { next; }

        my @values;
        if ( int(@fields) < 1 ) {
            ####### Get fields from first row of data ########
            @fields = &_get_CSV_data( $line, \@columns, 0, $delimiter );
            print "Extracting fields: ";
            print join ',', @fields;
            print "\n";
        }
        else {
            @values = &_get_CSV_data( $line, \@columns, 1, $delimiter );    # add quotes if nec.
                                                                            #print @values;

            my %data = map { $fields[$_], $values[$_] } ( 0 .. $#fields );

            #print Dumper \%data;
            if ( $format =~ /\bAofH\b/io ) {
                push( @$retval, \%data );
            }
            elsif ( $format =~ /\bHofH\b/io ) {
                if ( $keyfield && exists $data{$keyfield} ) {
                    $retval->{ $data{$keyfield} } = \%data;
                }
                else {
                    $retval->{ $i + 1 } = \%data;
                }
            }
            $i++;
        }
    }

    close($CSV_FILE);

    return $retval;
}

sub strim {
    my $string = shift;
    my $size = shift || 10;

    if ( length($string) > $size ) {
        return substr( $string, 0, $size ) . '...';
    }
    else {
        return $string;
    }
}

###################
#
# Truncates a string given a length argument. If longer than length appends ... to the end of string
#  (only cuts off at the end of a word, not in the middle)
#
###################
sub truncate_string {
###################
    my %args            = &filter_input( \@_, -args => 'string,length,tip' );
    my $original_string = $args{-string};
    my $length          = $args{ -length };
    my $link            = $args{-tip};                                          ## show full string as tool tip

    my $size   = length $original_string;
    my $string = $original_string;
    if ( $size > $length ) {
        $string = substr( $string, 0, $length );
        ### If the string is not one giant word ...
        if ( $string =~ /\W/ ) {
            $string =~ s/\w+$//;                                                ### cut off the last word
        }
        $string .= "...";

        #	$string .= "($size)";
        if ($link) {
            return Show_Tool_Tip( $string, $original_string );
        }
    }
    return $string;
}
#############################
#
#  Encodes a variable reference
#
#
#############################
sub encode_var {
    my $data = shift;
    my $type = ref($data);

    my @list;
    if ( $type =~ /HASH/ ) {
        @list = %{$data};
    }
    elsif ( $type =~ /ARRAY/ ) {
        @list = @{$data};
    }
    elsif ( $type =~ /SCALAR/ ) {
        push( @list, $$data );
    }
    else {
        push( @list, $data );
    }

    my @encoded = ($type);

    foreach (@list) {
        my $ascii = unpack( "H*", $_ );
        $ascii =~ s/[a-zA-Z0-9\-\(\) :\.]//g;
        push( @encoded, $ascii );
    }
    return \@encoded;
}

############################
#
#  Decodes an encoded array into its proper variable
#
#
############################
sub decode_var {
############################
    my $data = shift;
    my @encoded;

    if ( ref($data) =~ /ARRAY/ ) {
        @encoded = @{$data};
    }
    else {
        print "Invalid encoded list\n";
        return 0;
    }

    my $type = shift(@encoded);

    if ( $type =~ /HASH/ ) {
        my %decode;
        while (@encoded) {
            my $key   = shift(@encoded);
            my $value = shift(@encoded);
            $decode{ pack( "H*", $key ) } = pack( "H*", $value );
        }
        return \%decode;
    }
    elsif ( $type =~ /ARRAY/ ) {
        my @decode;
        while (@encoded) {
            push( @decode, pack( "H*", shift(@encoded) ) );
        }
        return \@decode;
    }
    elsif ( $type =~ /SCALAR/ ) {
        my $decode = pack( "H*", shift(@encoded) );
        return \$decode;
    }
    else {
        return pack( "H*", shift(@encoded) );
    }
}

##############################
# check the number of days elapsed since a date
# date format: yyyy-mm-dd-hh-mm-ss
##############################
sub day_elapsed {
##############################
    my $day = shift;
    Message("Error: $0: wrong date format: $day  ") if $day !~ /^\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d/;
    $day =~ /^(\d\d\d\d)-(\d\d)-(\d\d)-(\d\d)-(\d\d)-(\d\d)/;

    my $year  = $1 - 1900;
    my $month = $2 - 1;

    $day = $3;

    my $hour   = $4;
    my $minute = $5;
    my $second = $6;

    my $pastTime = Time::Local::timelocal( $second, $minute, $hour, $day, $month, $year );
    my $daysElapsed = ( time - $pastTime ) / 86400;
    return $daysElapsed;
}

#########################
sub compare_objects {
#########################
    #    my %args = @_;
    #    my $object1 = $args{1};
    #    my $object2 = $args{2};

    my $object1 = shift;
    my $object2 = shift;

    $Data::Dumper::Sortkeys = 1;
    my $string1 = Dumper($object1);
    my $string2 = Dumper($object2);

    ## clear quotes to remove issues with quoting integers ##
    $string1 =~ s/\'//g;
    $string2 =~ s/\'//g;

    if   ( $string1 eq $string2 ) { return 1; }
    else                          { return 0; }
}

########################
#  Method compares 2 data structures recursively
#
#  e.g.  In this example 2 data structures were read in from 2 files, converted to objects, and compared
#
#  open(READ1,"$file1")||die "Cannot open file $file1\n";
#  open(READ2,"$file2")||die "Cannot open file $file2\n";
#  my @data1 = <READ1>;
#  my @data2 = <READ2>;
#  close(READ1);
#  close(READ2);
#  my $start1 = 0;
#  my $start2 = 0;
#  my %struct1;
#  my %struct2;
#  my $struct1 = read_dumper(\@data1,\$start1,\%struct1);
#  my $struct2 = read_dumper(\@data2,\$start2,\%struct2);
#
#  my @comments;
#  my $same = compare_data(1=>$struct1,
#  			2=>$struct2,
#  			-comment=>\@comments,
#  			-case_insensitive=>1
#  );

#####################
sub compare_data {
#####################
    my %args        = @_;
    my $struct1     = $args{1};                         # first data structure
    my $struct2     = $args{2};                         # second data structure
    my $comment     = $args{-comment};                  # reference to array for storing comments of where the differences are
    my $ignore_case = $args{-case_insensitive} || 0;    # option to ignore case difference
    my $no_sort     = $args{-no_sort} || 0;

    ########################
    ## different data type
    ########################
    if ( ref($struct1) ne ref($struct2) ) {
        _record_diff_struct( $struct1, $struct2, $comment, "Different data structures: " . ref($struct1) . ", " . ref($struct2) );
        return 0;
    }

    ########################
    ## comparing arrays
    ########################
    # limitation of array comparison: reference elments have to be in same order in array
    if ( ref($struct1) eq "ARRAY" ) {
        if ( scalar(@$struct1) != scalar(@$struct2) ) {    # different sizes
            _record_diff_struct( $struct1, $struct2, $comment, "Different array sizes: " . scalar(@$struct1) . ", " . scalar(@$struct2) );
            return 0;
        }

        # first check the number of reference elements in both arrays
        # sort elements by non-ref and ref
        my @non_ref1;
        my @non_ref2;
        my @ref1;
        my @ref2;
        for ( my $i = 0; $i < scalar(@$struct1); $i++ ) {
            push( @non_ref1, $$struct1[$i] ) if ( ref( $$struct1[$i] ) eq "" );
            push( @non_ref2, $$struct2[$i] ) if ( ref( $$struct2[$i] ) eq "" );
            push( @ref1, $$struct1[$i] ) if ( ref( $$struct1[$i] ) ne "" );
            push( @ref2, $$struct2[$i] ) if ( ref( $$struct2[$i] ) ne "" );
        }
        if ( scalar(@ref1) != scalar(@ref2) ) {    # different sizes
            _record_diff_struct( \@ref1, \@ref2, $comment, "Different reference element sizes: " . scalar(@ref1) . ", " . scalar(@ref2) );
            return 0;
        }

        # compare non-ref arrays
	if (!$no_sort) {
	    @non_ref1 = sort @non_ref1;
	    @non_ref2 = sort @non_ref2;
	}
        for ( my $i = 0; $i < scalar(@non_ref1); $i++ ) {
            my $elem1 = $non_ref1[$i];
            my $elem2 = $non_ref2[$i];
            if ($ignore_case) {
                $elem1 = lc($elem1);
                $elem2 = lc($elem2);
            }
            if ( $elem1 ne $elem2 ) {
                _record_diff_struct( \@non_ref1, \@non_ref2, $comment, "Different non-reference elements at index $i: $elem1, $elem2" );
                return 0;
            }
        }

        # compare arrays of references
        # this is tricky because can't be sure which element to be compared with which element in 2 arrays
        # (1) compare array 1 to itself and array 2 to itself, form non-redundant set and keep track of the number of copies for each non-redundant element

        my %array1;
        my $keyCount = 0;
        foreach (@ref1) {
            my $found = 0;
            foreach my $key ( keys %array1 ) {
                my @comments;
                if (compare_data(
                        1                 => $_,
                        2                 => $array1{$key}{value},
                        -comment          => \@comments,
                        -case_insensitive => $ignore_case,
			-no_sort          => $no_sort
                    )
                    )
                {
                    $array1{$key}{count}++;
                    $found = 1;
                }
            }
            if ( !$found ) {
                $array1{$keyCount}{value} = $_;
                $array1{$keyCount}{count} = 1;
                $keyCount++;
            }
        }

        my %array2;
        $keyCount = 0;
        foreach (@ref2) {
            my $found = 0;
            foreach my $key ( keys %array2 ) {
                my @comments;
                if (compare_data(
                        1                 => $_,
                        2                 => $array2{$key}{value},
                        -comment          => \@comments,
                        -case_insensitive => $ignore_case,
			-no_sort          => $no_sort
                    )
                    )
                {
                    $array2{$key}{count}++;
                    $found = 1;
                }
            }
            if ( !$found ) {
                $array2{$keyCount}{value} = $_;
                $array2{$keyCount}{count} = 1;
                $keyCount++;
            }
        }

        # (2) compare non-redundant arrays 1 and 2, each element should have exactly 1 match
        # (2.1) first check non-redundant sizes
        if ( scalar( keys %array1 ) != scalar( keys %array2 ) ) {
            _record_diff_struct( \%array1, \%array2, $comment, "Different non-redundant array sizes: " . scalar( keys %array1 ) . ", " . scalar( keys %array2 ) );
            return 0;
        }

        # (2.2) compare elements
        foreach my $key ( keys %array1 ) {
            my $found_match = 0;
            foreach ( keys %array2 ) {
                my @comments;
                if (compare_data(
                        1                 => $array1{$key}{value},
                        2                 => $array2{$_}{value},
                        -comment          => \@comments,
                        -case_insensitive => $ignore_case,
                        -no_sort          => $no_sort
                    )
                    )
                {

                    # if there is a match, check to see if the # of copies of each non-redundant element in each array is same
                    if ( $array1{$key}{count} != $array2{$_}{count} ) {
                        _record_diff_struct( \%array1, \%array2, $comment, "Matching non-redundant elements in array 1 (key $key) and array 2 (key $_) have different # of copies of redundant elements: $array1{$key}{count}, $array2{$_}{count}" );
                        return 0;
                    }
                    $found_match = 1;
                    last;
                }
            }
            if ( !$found_match ) {
                _record_diff_struct( \%array1, \%array2, $comment, "Element (key $key) in array 1 has no match in array 2" );
                return 0;
            }
        }
        return 1;
    }

    ########################
    ## comparing hashes
    ########################
    elsif ( ref($struct1) eq "HASH" ) {
        ### first compare keys
        my @struct1keys = sort ( keys %$struct1 );
        my @struct2keys = sort ( keys %$struct2 );
        if ( scalar(@struct1keys) != scalar(@struct2keys) ) {    # different key size
            _record_diff_struct( \@struct1keys, \@struct2keys, $comment, "Different hash key sizes: " . scalar(@struct1keys) . ", " . scalar(@struct2keys) );
            return 0;
        }

        for ( my $i = 0; $i < scalar(@struct1keys); $i++ ) {

            # compare keys
            if ( $struct1keys[$i] ne $struct2keys[$i] ) {
                _record_diff_struct( \@struct1keys, \@struct2keys, $comment, "Different hash keys: $struct1keys[$i], $struct2keys[$i]" );
                return 0;
            }
            my $elem1 = $$struct1{ $struct1keys[$i] };
            my $elem2 = $$struct2{ $struct2keys[$i] };

            # compare element types
            if ( ref($elem1) ne ref($elem2) ) {
                _record_diff_struct( $struct1, $struct2, $comment, "Different hash element types: " . ref($elem1) . ", " . ref($elem2) );
                return 0;
            }

            # compare non-ref elements
            if ( ref($elem1) eq "" ) {
                if ($ignore_case) {
                    $elem1 = lc($elem1);
                    $elem2 = lc($elem2);
                }
                if ( $elem1 ne $elem2 ) {
                    _record_diff_struct( $struct1, $struct2, $comment, "Different hash elements on key $struct1keys[$i]: $elem1, $elem2" );
                    return 0;
                }
            }

            # compare ref elements
            else {
                my $same = compare_data(
                    1                 => $elem1,
                    2                 => $elem2,
                    -comment          => $comment,
                    -case_insensitive => $ignore_case,
		    -no_sort          => $no_sort
                );
                if ( !$same ) {

                    #		    _record_diff_struct($struct1,$struct2,$comment,"Hash values (ref) on key $struct1keys[$i] are different");
                    return 0;
                }
            }
        }
        return 1;
    }

    ########################
    ## comparing scalars
    ########################
    elsif ( ref($struct1) eq "SCALAR" ) {
        if ( $$struct1 ne $$struct2 ) {
            _record_diff_struct( $struct1, $struct2, $comment, "Different scalars" );
            return 0;
        }
        return 1;
    }

    ########################
    ## comparing non-reference scalars
    ########################
    elsif ( ref($struct1) eq "" ) {
        if ( $struct1 ne $struct2 ) {
            _record_diff_struct( $struct1, $struct2, $comment, "Different non-ref scalars" );
            return 0;
        }
        return 1;
    }

    ########################
    ## other types
    ########################
    else {
        die "Error:  Invalid type: " . ref($struct1);
    }
}

##############################
# read Data::Dumper output (as array of lines) and regenerate original data structure
#
#  my $start = 0;                                                          # line index for @inputArray, which contains data dump
#  my %structure;
#  my $structureRef = &read_dumper(\@inputArray,\$start,\%structure);
#
#  e.g.
#  $VAR1 = {
#            'library_started' => [
#                                   'Sep-07-2000',
#                                   'Sep-07-2000'
#                                 ]
#  Put this into @inputArray:
#
#  [0]            'library_started' => [
#  [1]                                   'Sep-07-2000',
#  [2]                                   'Sep-07-2000'
#  [3]                                 ]
#
#  Known bug: Alteration to structure when parsing a string with multiple lines
###############
sub read_dumper {
#########################
    my $dataRef = shift;    # reference to array containing data dump
    my $lineRef = shift;    # line index for @inputArray, which contains data dump
    my $self    = shift;    # data structure

    my $line;

    while (1) {
        my $dataSize = @$dataRef - 1;
        if ( $$lineRef > $dataSize ) {
            return $self;
        }
        $line = $$dataRef[$$lineRef];
        $$lineRef++;
        if ( $line =~ /(?:\[|\{)(?:\]|\})/ ) {    # empty hash or array
        }
        elsif ( $line =~ /\]|\}/ ) {              # end of an array or hash
            return $self;
        }
        elsif ( $line =~ /\[|\{/ ) {              # start of an array or hash
            if ( $line =~ /\[/ ) {                # array
                $line =~ /\'([\w\d\-]+)\' \=\>/;
                my @newArray    = ();
                my $newArrayRef = \@newArray;
                $newArrayRef = &read_dumper( $dataRef, $lineRef, $newArrayRef );
                $$self{$1} = $newArrayRef;
            }
            elsif ( $line =~ /\{/ ) {             # hash
                $line =~ /\'([\w\d\-]+)\' \=\>/;
                my %newHash    = ();
                my $newHashRef = \%newHash;
                $newHashRef = &read_dumper( $dataRef, $lineRef, $newHashRef );
                $$self{$1} = $newHashRef;
            }
            else {
                die "$0: unknown line $line ";
            }
        }
        elsif ( $line =~ /\=\>/ ) {               # part of a hash
            $line =~ /\'([\w\d\-]+)\' \=\> \'?(.*?)\'?,?$/;
            if ( $2 eq "undef" ) {
                $$self{$1} = undef;               # comment this line if you don't want to create an undef element
            }
            else {
                my $value = $2;
                my $key   = $1;
                $value =~ s/\\\'/\'/g;
                $$self{$key} = $value;
            }
        }
        elsif ( $line =~ /\'?.*\'?,?$/ ) {        # part of an array
            $line =~ /^\s*\'?(.*?)\'?,?$/;
            if ( $1 eq "undef" ) {
                push( @$self, undef );            # comment this line if you don't want to create an undef element
            }
            else {
                my $value = $1;
                $value =~ s/\\\'/\'/g;
                push( @$self, $value );
            }
        }
        else {
            print "Line $$lineRef\t$line\nSelf:\n";
            print Dumper $self;
            die "$0: Unable to process line.  ";
        }
    }
}

# Remove files in a given directory that haven't been accessed for a given number of days
#
# Usage: unlink_old_file(-dir=>$rysnc_dir,-days=>30);
#
# Example: unlink_old_file(-dir=>"/home/aldente/public/logs/File_Transfers/rsync",-days=>30);
############################
sub unlink_old_file {
############################
    my %args         = filter_input( \@_, -args => 'dir,days', -mandatory => 'dir,days' );
    my $dir          = $args{-dir};
    my $days         = $args{-days};
    my @files        = glob("$dir/*");
    my $cut_off_date = strftime "%Y%m%d%H%M%S", localtime( time - ( 86400 * $days ) );
    for my $file (@files) {
        my ($access_time) = ( stat($file) )[8];
        my $file_date = strftime "%Y%m%d%H%M%S", localtime($access_time);
        if ( -f $file && $file_date < $cut_off_date ) {
            print "unlink $file\n";
            unlink($file);
        }
    }
}

#<snip>
#Usage: my $success = replace_last_line(-file=>"$full_path",-newline=>"$new_line");
#</snip>
########################
sub replace_last_line {
########################
    my %args    = filter_input( \@_, -mandatory => "file,newline" );
    my $file    = $args{-file};
    my $newline = $args{-newline};

    if ( -f "$file" ) {
        open( INFH, "<$file" ) or die "Error opening file: '$file'";
    }
    else {
        Message "Requested file cannot be altered because it does exist: '$file'";
    }

    my @lines = <INFH>;
    close INFH;
    open( OUTFH, ">$file" ) or die "Could not open file for writing: '$file'";
    my $last_redone_line_num = scalar(@lines) - 2 if ( scalar(@lines) >= 2 );
    $last_redone_line_num = 0 if ( scalar(@lines) < 2 );
    foreach my $line ( @lines[ 0 .. $last_redone_line_num ] ) {
        print OUTFH "$line";
    }
    if ( $newline !~ /\n$/ ) {
        $newline = "$newline\n";
    }
    print OUTFH $newline;

    my $success;
    if ( try_system_command("tail -n 1 $file") =~ /^$newline$/ ) {
        $success = 1;
    }
    else {
        $success = 0;
    }

    return $success;

}

# <snip>
# e.g. my $lines_ref = get_lines_between_tags(-filepath=>"$full_path",-tag=>"$tag_name");
# OR my %lines = get_lines_between_tags(-filepath=>"$full_path");
#  so $lines{TAG1} = \@lines_within_TAG1;
#  $lines{TAG2} = \@lines_within_TAG2;
# </snip>
###########################
sub get_lines_between_tags {
###########################
    my %args     = filter_input( \@_, -args => 'filepath', -mandatory => 'filepath' );
    my $filepath = $args{-filepath};
    my $tag_name = $args{-tag} || $args{-tag_name};

    return if ( !( -f $filepath ) );

    my %lines;

    open( FH, "<$filepath" );
    my $begin  = 0;
    my $middle = 0;
    my @lines_btw_tags;
    my $tag;    ## dynamic, tracks current tag
    foreach my $line (<FH>) {
        chomp $line;
        next if ( $line =~ /^\s*\#/ );
        next if ( $line =~ /^\s*$/ );
        if ( $begin == 1 ) {
            $middle = 1;
            $begin  = 0;
        }
        if ( $line =~ /^\s*\<(\w+)\>/ ) {
            $tag = $1;
            if ( $tag_name && ( $tag eq $tag_name ) || ( !$tag_name ) ) {
                $begin = 1;
            }
        }
        next if ( $begin == 1 );
        if ( $middle == 1 ) {
            if ( $line =~ /\/$tag\>/ ) {
                my @lines_copy = @lines_btw_tags;
                $lines{$tag}    = \@lines_copy;
                @lines_btw_tags = ();
                $middle         = 0;
                next;
            }
            push @lines_btw_tags, $line;
        }
    }

    if ($tag_name) {
        return $lines{$tag_name};
    }
    return %lines;

}

#<snip>
#Usage: my $md5 = get_MD5( -file=>$file_name );
#</snip>
########################
sub get_MD5 {
########################
    my %args    = filter_input( \@_, -mandatory => "file" );
    my $file = $args{-file};

    eval "require Digest::MD5";
    
    my $digest = Digest::MD5->new;
    open(FILE,"$file");
    $digest->addfile(*FILE);
    close(FILE);
    my $md5 = $digest->hexdigest;
    return $md5;
}

##############################
# Create a file or directory 
#
# Usage:	my $ok = create_file( -name => 'test.txt', -content => 'This is a test.', -path => '/home/aldente/tmp' ); 
# 			my $ok = create_file( -name => 'test.txt', -content => 'This is a test.', -path => '/home/aldente/tmp', -chgrp => 'lims', -chmod => 'g+w', -overwrite => 1 ); 
# 			my $ok = create_file( -name => 'test.txt', -path => '/home/aldente/tmp', -chgrp => 'lims', -chmod => 'g+w', -overwrite => 1 );
# 			my $ok = create_file( -path => '/home/aldente/tmp', -chgrp => 'lims', -chmod => 'g+w' ); 
#
# Return:	1 on success; 0 on failure
##############################
sub create_file {
    my %args    = filter_input( \@_, -args => 'name,content,path,dir,chmod,chgrp,overwrite', -mandatory => "path" );
    my $name = $args{-name};
	my $content = $args{-content};
    my $path = $args{-path};
	my $dir = $args{-dir};
	my $mode = $args{-chmod};
	my $grp = $args{-chgrp};
	my $overwrite = $args{-overwrite}; # only applicable to file, not dir
    
    if( $dir ) {
		if( ! -e "$path/$dir" ) {
	    	&create_dir( -path => $path, -subdirectory => $dir, -mode => $mode, -chgrp => $grp );
		}
    }
	
	return 1 if( !$name );
	
    my $full_name;
    if( $dir ) { 
    	$full_name = "$path/$dir/$name";
    }
    else {
    	$full_name = "$path/$name";
    }
	
	if( -f "$full_name" ) {
			if( !$overwrite ) {
				return err( "$full_name already exists!" );
			}
			else {
				try_system_command( -command => "rm -f $full_name" );
			}
	}
		
	if ( open my $OUT, '>', "$full_name" ) {
	        print $OUT $content if( $content );
    	    close($OUT);

        	## change group
        	if( $grp ) {
		        my $command = "chgrp $grp $full_name";
        		my( $out, $err ) = try_system_command( -command => $command );
        		return err ("Error occurred when running command $command: $err") if( $err );
        	}
        	
        	## change mode
        	if( $mode ) {
		        my $command = "chmod $mode $full_name";
        		my( $out, $err ) = try_system_command( -command => $command );
        		return err ("Error occurred when running command $command: $err") if( $err );
        	}

	}
	else {
			return err( "ERROR: Couldn't open file $full_name for writing! $!" );
	}
	
	return 1;
}


##############################
# Compare the timestamp of file a and file b. 
#
# Usage:	my $result = cmp_file_timestamp( '/opt/alDente/tmp/file1', '/opt/alDente/tmp/file2' ); 
#
# Return:	 1	-	if a is newer than b
#			 0	-	if a is the same as b 
#			-1	-	if a is older than b
##############################
sub cmp_file_timestamp {
	my $file1	= shift;
	my $file2	= shift;
	
	my $time1 = 0;
	my $time2 = 0;	
	if( -e $file1 ) {
		my $cmd = "stat -c %Y \"$file1\"";	# works for file names that contain spaces
		my $stderr1;
		( $time1, $stderr1 ) = try_system_command( "$cmd" );
		if( !$stderr1 ) {
			chomp $time1;
		}
	}
	if( -e $file2 ) {
		my $cmd = "stat -c %Y \"$file2\"";	# works for file names that contain spaces
		my $stderr2;
		( $time2, $stderr2 ) = try_system_command( "$cmd" );
		if( !$stderr2 ) {
			chomp $time2;
		}
	}
	
    return $time1 <=> $time2;
}

##############################
# Save the diff between the new and old yml files, and then save the file.
#
# Usage:	my $diff = save_diffs( -yml => $new, -file => $file, -log => $diff_log_file, -user => $user ); 
# 			my $diff = save_diffs( -yml => $new, -file => $file, -log => $diff_log_file ); 
# 			my $diff = save_diffs( -yml => $new, -file => $file );
# 			my $diff = save_diffs( -temp_file => $ttempfile, -file => $file );
#			if -log is not passed in, the diffs will be saved as $file.diff.log
##############################
sub save_diffs {
    my %args    = filter_input( \@_, -args => 'yml,file,log,user,temp_file', -mandatory => "file" );
    my $yml = $args{-yml};
    my $file = $args{-file};
    my $log = $args{-log} || "$file.diff.log";
    my $user = $args{-user};
    my $tempfile = $args{-temp_file};
    my $quiet = $args{-quiet};
    
	my $timestamp = timestamp();
	if( ! -e $file ) {
		`echo "\n$timestamp [$user]\nCreated new file $file\n" >> "$log"`;
		if( $tempfile && -e $tempfile ) {
			my $cmd = "cp \"$tempfile\" \"$file\"";
			my ( $stdout, $stderr ) = try_system_command( "$cmd" );
			if( $stderr ) {
				Message( "Error running command: $cmd" ); 
				Message( "$stderr " );
			}
			else {
		    	Message( "Saved to $file") unless ($quiet);
			}
		}
		elsif( $yml ) {
    		require YAML;
    		&YAML::DumpFile( ">$file", $yml );
	    	Message( "Saved to $file") unless ($quiet);
		}
		return;
	}
	
	my $new_tempfile;
	if( !$tempfile && $yml ) { 
		$new_tempfile = "$file.tmp_" .$timestamp;
		$tempfile = $new_tempfile;
    	## YAML serialize the object
    	require YAML;
    	&YAML::DumpFile( ">$tempfile", $yml );
	}
	
	my $diff = `diff "$file" "$tempfile"`;
	if( $diff ) {
		my $cmd = "cp \"$tempfile\" \"$file\"";
		my ( $stdout, $stderr ) = try_system_command( "$cmd" );
		if( $stderr ) {
			Message( "Error running command: $cmd" ); 
			Message( "$stderr " );
		}
		else {
			Message( "Saved to $file" ) unless ($quiet);
		}

		`echo "\n$timestamp [$user]\n$diff" >> "$log"`;
		Message( "Difference saved to $log") unless ($quiet);
	}
	else {
		Message( "No changes made to $file" ) unless ($quiet);
	}
	
	## clean up
	if( $new_tempfile ) {
		`rm -f "$new_tempfile"`;
	}
	return;
}

####################
sub deep_compare {
####################
    my $v1 = shift;
    my $v2 = shift;
    
    if (ref $v1 ne ref $v2) { return 0 }
    
    if (ref $v1) {
        ## if hash or array (scalar ref is blank) ##
        my $v1_dump = Dumper $v1;
        my $v2_dump = Dumper $v2;
        
        if ($v1_dump eq $v2_dump) { return 1 }
        else { return 0 }
    }
    else {
        ## scalar values ##
        if ($v1 eq $v2) { return 1 }
        else { return 0 }
    }
}

####################
sub create_link {
####################
	my %args = &filter_input( \@_, -args=>'file,link_path');

	my $link_path     = $args{-link_path};
	my $file          = $args{-file};
	my $relative_link = $args{-relative_link}; ### The symlink will point to the relative path, not the full path
    
	my $target;
	if ($relative_link) {
		my ( $alias, $link_dir ) = File::Basename::fileparse($link_path);
		$target = File::Spec->abs2rel( $file, $link_dir ) ;
	}
	else {
		$target = $file;
	}

	if (-l $link_path) {
		my $link_target = readlink($link_path);
		if ($link_target ne $target) {
			Message("ERROR: Symlink $link_target doesn't point to $target\n");
			return 0;
		}
		else {
			Message("Symlink $link_path to $target already exists\n");
			return 1;
		}
	}

	else {
		Message("Creating symlink $link_path for $target\n");
		return symlink($target,$link_path);
	}
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

###############################################
# method used by compare_data() to record differences between data structures
###############################################
sub _record_diff_struct {
    my $struct1  = shift;
    my $struct2  = shift;
    my $comments = shift;
    my $message  = shift;

    push( @$comments, [ $message, $struct1, $struct2 ] );
}

###############################################
# Private helper function for Parse_CSV_File()
###############################################
sub _get_CSV_data {
    my $line        = shift;
    my $columns_ref = shift;
    my $quote       = shift;
    my $delim       = shift || "\t";
    my $default     = shift || 'NULL';

    if ( $delim =~ /s/i ) { $line =~ s/\s{2,}/\t/g; }

    my @columns = @$columns_ref if $columns_ref;

    #print "\nseparate (with $delim):\n$line\n";
    my @data_line = split $delim, $line;

    #print "-> @data_line\n";
    my $col_num  = 1;
    my $included = 0;
    ####### Get data from line ###########
    my @fields;

    unless (@columns) { @columns = 1 .. int(@data_line) }

    #    foreach my $col (@data_line) {
    foreach my $col_num (@columns) {
        my $col = $data_line[ $col_num - 1 ];
        unless ($col) { $col = $default }
        if ($quote) {
            if ( $col =~ /^[\'\"](.*)[\'\"]$/ ) { $col = $1; }
        }
        push( @fields, $col );

        #print "col $col_num : " . $fields[$included] . " = $col.\n";
        $included++;
    }
    unless ( $included == $#fields + 1 ) {
        print "** Warning: columns ($included) equal fields ($#fields + 1) ? **\n";
    }

    if ( int(@fields) > $included ) {
        for ( $included .. $#fields ) {
            push( @fields, $default );

            #print "** Added " . int(@fields) - $included . " default fields\n";
        }
    }
    return @fields;
}

sub get_array_index {
	my $array_ref = shift;
	my $element = shift;
	
	if( !$array_ref ) { return -1 }
	
	my @array = @$array_ref;
	foreach my $index ( 0 .. $#array ) {
		if( $array[$index] eq $element ) { return $index }
	}
	return '-1';
}


######################
# 
# Simple wrapper to check for existence of module 
#
# Return: true on success
######################
sub module_defined {
######################
    my $module = shift;
    
    my $ok = eval "require $module";
    
    if ($@) { return; }
    else { return 1; }
}

############################################
# Standardize text input value:
#   1. Remove leading and trailing whitespaces
#   2. ...
#
# Input parameters:
#   - text
#
# Example:
#
# my $value = RGTools::RGIO::standardize_text_value($value);
#
#
# Return: text
#############################
sub standardize_text_value {
##############################

    my $text = shift;
      
    ## Truncate leading and trailing white spaces   
    if (ref $text eq 'ARRAY') {
        foreach my $string (@$text) {
            $string = standardize_text_value($string);
        }
        return $text;
    }
    else{
        my $str_ref = \$text;
        $$str_ref =~ s/\s+$//;
        $$str_ref =~ s/\s+\'$/\'/; 
        $$str_ref =~ s /^\s+//;
        $$str_ref =~ s /^\'\s+/\'/;
        return ${$str_ref};
    }
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

$Id: RGIO.pm,v 1.134 2004/11/30 04:42:29 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
