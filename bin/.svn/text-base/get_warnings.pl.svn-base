#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use Getopt::Long;

# Get arguments
use vars qw($opt_m $opt_x $opt_i $opt_f $opt_h);
&GetOptions(
    'm=s' => \$opt_m,
    'i=s' => \$opt_i,
    'f=s' => \$opt_f,
    'h'   => \$opt_h,
    'x'   => \$opt_x,
);

if ($opt_h) {
    _print_help_info();
    exit;
}

my $current_dir = $0;
$current_dir =~ s/(.*)\/get_warnings\.pl/$1/;

#my @module_dirs = ('SDB','RGTools','alDente','Sequencing','Lib_Construction','Mapping','Submission');

my %module_paths = (
    'SDB'             => "$current_dir/../lib/perl/Core/",
    'RGTools'         => "$current_dir/../lib/perl/Core/",
    'alDente'         => "$current_dir/../lib/perl/Core/",
    'Sequencing'      => "$current_dir/../lib/perl/",
    'Lib_Construction' => "$current_dir/../lib/perl/Departments/",
    'Mapping'         => "$current_dir/../lib/perl/Departments/",
    'Submission'      => "$current_dir/../lib/perl/Plugins/",
);

# These modules do not compile so leave them out for now
my @exclude_modules = ( 'Fasta', 'ChromatogramHTML', 'Graph', 'gdchart' );
my @include_modules;
if ($opt_m) { @include_modules = split /,/, $opt_m }

foreach my $module (@include_modules) {
    $module =~ s/^(.*)\b(\w+)\.pm$/$2/;
}

my $perl_interpreter = $opt_i || `which perl`;
chomp $perl_interpreter;

my $output_format = $opt_f || 'summary';

my $output;
$output .= "#!$perl_interpreter -w\n\n";
$output .= "use FindBin;\n";
$output .= 'use lib $FindBin::RealBin . "/../lib/perl/";' . "\n\n";
$output .= 'use lib $FindBin::RealBin . "/../lib/perl/Core/";' . "\n\n";
$output .= 'use lib $FindBin::RealBin . "/../lib/perl/Imported/";' . "\n\n";
$output .= 'use lib $FindBin::RealBin . "/../lib/perl/Plugins/";' . "\n\n";
$output .= 'use lib $FindBin::RealBin . "/../lib/perl/Departments/";' . "\n\n";

print "Including modules: @include_modules\n";
foreach my $module_dir ( keys %module_paths ) {
    my $module_path = $module_paths{$module_dir};
    my @modules     = glob("$module_path/$module_dir/*.pm");
    foreach my $module (@modules) {
        $module =~ s/.*\/(\w+)\.pm$/$1/;

        #	print "check $module.\n";
        if ( @include_modules && !grep /^$module$/, @include_modules ) { next; }
        elsif ( @exclude_modules && grep /^$module$/, @exclude_modules ) { next; }
        print "checking $module.\n";
        $output .= "use $module_dir\:\:$module;\n";
    }
}

my $test_file = "$current_dir/warnings.pl";

open my $FILE, '>', $test_file or die;
print $FILE $output;
close $FILE;

`chmod +x $test_file`;

#`$test_file 2> $current_dir/warnings.log`;
my $fback = `$test_file 2>&1`;
`rm -f $test_file` if ( $test_file && -f $test_file );
print "TEST: $test_file";

print "Using $perl_interpreter perl interpreter...\n";

if ( $output_format !~ /^summary|raw$/i ) {
    print "Invalid output format. Please type 'get_warnings.pl -h' for more info.";
    exit;
}

elsif ( $output_format =~ /^raw$/i ) {
    print $fback;
    exit;
}

# Define the fixes
my %Warnings;
$Warnings{Deprecated_Use_of_Defined}{fix}              = q{Remove the call to the defined() function.};
$Warnings{Deprecated_Use_of_Reference}{fix}            = 'Replace "@array->[$index]" with "$array[$index]" and "%hash->{$index}" with "$hash{$index}".';
$Warnings{Implicit_Split}{fix}                         = q{Replace "int(split ',', $ids)" with "int(my @array = split ',', $ids)".};
$Warnings{My_Variable_Masks_Earlier_Declaration}{fix}  = q{Take away the 'my' or remove earlier declaration of the variable.};
$Warnings{Our_Variable_Masks_Earlier_Declaration}{fix} = q{Take away the 'our' or remove earlier declaration of the variable.};
$Warnings{Print_Function}{fix}                         = q{Remove parenthesis when calling 'print'.};
$Warnings{Scalar_Value_Better_Rewritten}{fix}          = q{Rewrite the scalar variable as suggested by the warning.};
$Warnings{Separate_Words_with_Commas}{fix}             = q{If comma is unnecessary then remove it.};
$Warnings{Subroutine_Redefined}{fix}                   = q{Check to see if the subroutine is exported/defined in another module and if so remove that.};
$Warnings{Unquoted_String}{fix}                        = q{Add parenthesis to the end of string if it is function call. Otherwise quote the string.};
$Warnings{Unrecognized_Escape}{fix}                    = q{See if the escape was necessary or was it a typo.};
$Warnings{Use_of_Uninit_Value}{fix}                    = q{Initialize the item first prior to the operation.};
$Warnings{Useless_Use_of_Function}{fix}                = q{Check if the functional call is needed and if not then remove it.};
$Warnings{Useless_Use_of_Item}{fix}                    = q{Check if the item should be assigned some value and if not then remove the item. Also look for concats with comma instead of dot.};
$Warnings{Variable_Not_Stay_Shared}{fix}
    = q{Either replace the 'my' with 'local our', or actually pass the variable into the inner subroutine. For other ways to resolve this problem, please refer to <http://perl.apache.org/docs/general/perl_reference/perl_reference.html#Remedies_for_Inner_Subroutines>.};

# Parse the warnings
my ($started,$ended);

foreach my $line ( split /\n/, $fback ) {

    if ($opt_m && !$opt_x) {
        ## only include warnings from local module itself ##
        my $alt_m = $opt_m;
        $alt_m =~s/\/\//\//;  ## for some reason warning references file like 'lib/perl//SDB/Module.pm'  
        
        if ($line =~/^\[(.+)\]\s+(\w+\.\w+)/xms) {
            my $mod = $2;
            ## found start of next module ##
            if ($opt_m =~ /\b$mod$/) { $started = 1 }
            else {
                if ($started) { $ended=1 }
                next;
            }
        }
        elsif ($line =~ /\b$opt_m\b/) { }
        elsif ($line =~ /\b$alt_m\b/) { }
        elsif (!$started || $ended) { next }    ## module of interest has not yet started... or it is finished     
    }
   
    $line =~ s/^\[.*\] //;    ### Remove timestamp
    unless ( $line =~ /(.*) at (.*\.p.) line (\d+)(.*)$/ ) {

        #        print "SKIPPING: $line\n";
        next;
    }
    my $warning  = $1;
    my $module   = $2;
    my $line_num = $3;
    my $suffix   = $4;        ## not used
    my $item;
    my $item_type;
    my %replace;
    my $ri = 1;
    my $key;

    # Handling of different type of warnings
    if ( $warning =~ /\"my\" (variable) (.*) masks earlier declaration in same scope/ ) {
        $replace{$ri}{item_type} = $1;
        $replace{$ri}{item}      = $2;
        $key                     = 'My_Variable_Masks_Earlier_Declaration';
    }
    elsif ( $warning =~ /\"our\" (variable) (.*) masks earlier declaration in same scope/ ) {
        $replace{$ri}{item_type} = $1;
        $replace{ $ri++ }{item}  = $2;
        $key                     = 'Our_Variable_Masks_Earlier_Declaration';
    }
    elsif ( $warning =~ /(Variable) \"(.*)\" will not stay shared/ ) {
        $replace{$ri}{item_type} = $1;
        $replace{ $ri++ }{item}  = $2;
        $key                     = 'Variable_Not_Stay_Shared';
    }
    elsif ( $warning =~ /(Subroutine) (.*) redefined/ ) {
        $replace{$ri}{item_type} = $1;
        $replace{ $ri++ }{item}  = $2;
        $key                     = 'Subroutine_Redefined';
    }
    elsif ( $warning =~ /Useless use of (.*) in void context/ ) {
        $replace{$ri}{item_type} = 'ITEM';
        $replace{ $ri++ }{item}  = $1;
        $key                     = 'Useless_Use_of_Item';
    }
    elsif ( $warning =~ /Use of uninitialized value in (.*)$/ ) {
        $replace{$ri}{item_type} = 'OPERATION';
        $replace{ $ri++ }{item}  = $1;
        $key                     = 'Use_of_Uninit_Value';
    }
    elsif ( $warning =~ /defined\((.*)\) is deprecated/ ) {
        $replace{$ri}{item_type} = 'VARIABLE_TYPE';
        $replace{ $ri++ }{item}  = $1;
        $key                     = 'Deprecated_Use_of_Defined';
    }
    elsif ( $warning =~ /Scalar value (.*) better written as (.*)$/ ) {
        $replace{$ri}{item_type} = 'VARIABLE';
        $replace{ $ri++ }{item}  = $1;
        $replace{$ri}{item_type} = 'VARIABLE';
        $replace{ $ri++ }{item}  = $2;
        $key                     = 'Scalar_Value_Better_Rewritten';
    }
    elsif ( $warning =~ /Unrecognized escape (.*) passed through/ ) {
        $replace{$ri}{item_type} = 'ESCAPE_CHARACTER';
        $replace{ $ri++ }{item}  = $1;
        $key                     = 'Unrecognized_Escape';
    }
    elsif ( $warning =~ /Using (.*) as a reference is deprecated/ ) {
        $replace{$ri}{item_type} = 'VARIABLE_TYPE';
        $replace{ $ri++ }{item}  = $1;
        $key                     = 'Deprecated_Use_of_Reference';
    }
    elsif ( $warning =~ /Useless use of (.*) with no values/ ) {
        $replace{$ri}{item_type} = 'FUNCTION';
        $replace{ $ri++ }{item}  = $1;
        $key                     = 'Useless_Use_of_Function';
    }
    elsif ( $warning =~ /Unquoted string \"(.*)\" may clash with future reserved word/ ) {
        $replace{$ri}{item_type} = 'STRING';
        $replace{ $ri++ }{item}  = $1;
        $key                     = 'Unquoted_String';
    }
    elsif ( $warning eq 'Use of implicit split to @_ is deprecated' )      { $key = 'Implicit_Split' }
    elsif ( $warning eq 'print (...) interpreted as function' )            { $key = 'Print_Function' }
    elsif ( $warning eq 'Possible attempt to separate words with commas' ) { $key = 'Separate_Words_with_Commas' }
    elsif ( $warning && $module && $line_num ) {    # Unknown warnings
        $key = $warning;
    }

    if ($warning) {
        if ( keys %replace ) {
            foreach my $i ( sort { $a <=> $b } keys %replace ) {
                my $item_type = uc( $replace{$i}{item_type} );
                my $item      = $replace{$i}{item};
                $warning =~ s/\Q$item\E/\<$item_type\>/;
                $line_num .= "[$item]";
            }
        }

        if   ( exists $Warnings{$key}{count} ) { $Warnings{$key}{count}++ }
        else                                   { $Warnings{$key}{count} = 1 }

        $Warnings{$key}{warning} = $warning;
        push( @{ $Warnings{$key}{modules}{$module} }, $line_num );
    }
}

# Report the warnings
my $total_warnings = 0;
foreach my $key ( sort keys %Warnings ) {
    if ( $Warnings{$key}{count} ) {
        print "\n" . "*" x 100 . "\nWARNING: $Warnings{$key}{warning} (Count: $Warnings{$key}{count})\n";
        print "FIX: $Warnings{$key}{fix}\n";
        print "*" x 100 . "\n";
        foreach my $module ( sort keys %{ $Warnings{$key}{modules} } ) {
            print "- '$module' (Lines: " . join( ", ", @{ $Warnings{$key}{modules}{$module} } ) . ")\n";
        }
        $total_warnings += $Warnings{$key}{count};
    }
}
print "\n" . "*" x 100 . "\nTotal Number of Warnings: $total_warnings\n";
print "*" x 100 . "\n";

#########################
sub _print_help_info {
#########################
    print <<HELP;

File:  get_warnings.pl
####################
This script gets the Perl warnings (if any) generated from modules.

Options:
##########

-m     Specify a comma-delimited list of modules to inspect. By default it includes all modules.
-i     Specify the perl interpreter. By default it is '/usr/local/bin/perl'.
-f     Specify the format of reporting the warnings. By default it is 'summary':
       - summary : Warnings are grouped together with suggested fixes.
       - raw : Warnings are displayed in the raw format generated by Perl
-h     Print help information

Examples:
###########

Inspect Sequencing_API.pm                   get_warnings.pl -m Sequencing_API
(alternate command - equivalent)            get_warnings.pl -m lib/perl/Sequencing/Sequencing_API.pm

Inspect with '/usr/local/bin/perl58'        get_warnings.pl -i /usr/local/bin/perl58
Inspect with raw output                     get_warnings.pl -f raw

HELP
}

