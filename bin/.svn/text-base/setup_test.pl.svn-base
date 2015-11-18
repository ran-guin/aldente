#!/usr/local/bin/perl

sub help {
    print <<END;
######################################################################################################################
#
# This script will generate an initial template for unit testing of a given module
# It will include a can_ok test and a block for future tests for each method / subroutine found in the module
#
# It will dynamically add a connection object if there is a reference in the module to a database connection.
# (This is based upon the inclusion and use of the SDB module set)
# 
######################################################################################################################
#
# Note: this should be run from the base directory of the checked out version (eg. /opt/alDente/versions/production )
#
##########
# Usage: #
##########
#
# setup_test.pl -module [directory::module]
#
# eg:
#
#     ~>./bin/setup_test.pl -module alDente::Barcoding
#
# or...
#
#     ~>./bin/setup_test.pl -module lib/perl/alDente/Barcoding.pm
#
# This would generate a file: ./bin/t/alDente/Barcoding.t that is ready for unit_testing (though empty)
#
# OPTIONS:
#
# -path <base path>     * Indicate base path if not running from base, or running from a symlink (eg '-path /opt/alDente/versions/beta')
#
# -append               * This will only append test blocks to methods not already included in current *.t file (based upon existing 'can_ok' tests)
#
# -directory <dir> -module <module>::<sub-module>    * Explicitly provide the directory and module if using subdirectory modules
#       (eg. '-directory RGTools -module Process_Monitor::Manager')
#
######################################################################################################################
END
}

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Data::Dumper;
use Test::Simple;
use Test::More qw(no_plan);
use Cwd;
use RGTools::RGIO;
use RGTools::Code;

## Get options ##
use vars qw($opt_directory $opt_module $opt_path $opt_append $opt_overwrite $opt_force);

use Getopt::Long;
&GetOptions(
    'directory=s' => \$opt_directory,
    'module=s'    => \$opt_module,
    'path=s'      => \$opt_path,
    'append'      => \$opt_append,
    'overwrite'   => \$opt_overwrite,
);

my $module    = $opt_module;
my $dir       = $opt_directory;
my $path      = $opt_path;
my $append    = $opt_append;
my $create    = !$append;
my $force     = $opt_force;
my $overwrite = $opt_overwrite;

my $pwd = cwd;

if ($path) {
    ## already defined ##
}

#elsif ( $pwd =~ /^(.*)\/versions\/(\w+)/ ) {
#    $path = "$1/versions/$2";
#}
elsif ($pwd) {
    $path = $pwd;
}
else {
    my $continue = Prompt_Input( -prompt => " No path supplied.  Looking in ./lib/perl/ ? (Y/N)" );
    $path = '.';

    unless ( $continue =~ /^y/i ) {
        Message("Aborting by choice");
        exit;
    }

    #    print "run from inside base versions path (eg /opt/alDente/versions/production)\n";
    #    print "(currently in $pwd)\n";
    print "(Alternatively, supply base path: eg -path '/opt/alDente/versions/beta')\n";
}

chdir $path;

my @modules;
$module =~ s/.pm$//;    ## strip extension if included (not needed)

my $package;
if ( $dir && $module ) {
    ## defined explicitly ##
}
elsif ( $module =~ /^(\w+)[\:\/]+(\w+)$/ ) {
    $dir    = "Core/$1";
    $package = $1;
    $module = $2;
}
elsif ( $module =~ /^(\w+)[\:\/]+(\w+)[\:\/]+(\w+)$/ ) {
    $dir    = "$1/$2";
    $package = $2;
    $module = $3;
}
elsif ( $module =~ /lib\/perl\/(.+)\/(\w+)$/ ) {
    $dir    = $1;
    $package = $1;
    $module = $2;
}
elsif ($dir) {
    chdir "lib/perl/$dir" or die "Cannot go to $path/lib/perl/$dir directory";

    @modules = `ls *.pm`;
    unless (@modules) {
        Message("No modules found in $path/lib/perl/$dir");
        exit;
    }

    chdir "../../..";
}
else {
    help();

    exit;
}

unless (@modules) {
    @modules = ($module);
}

Message( "Found Modules: ($dir:$module) \n" . join "", @modules );

foreach my $module (@modules) {
    chomp $module;
    $module =~ s/(.*)\.pm$/$1/;    ## strip off extension if supplied
    $module =~ s/::/\//g;          ## remove separator if supplied

    unless ($module) {
        next;
    }

    my $file = $FindBin::RealBin . "/t/$dir/$module.t";
    unless ( -e "$file" ) {
        $create++;
    }                              ## set create flag if file does not exist

    my $template;
    if ($create) {
        $template .= `cat $path/template/unit_test_template.t`;

        $template =~ s/<dir>/$dir/ig;
        $template =~ s/<module>/$module/ig;
    }

    my @methods     = `grep '^sub ' $path/lib/perl/$dir/$module.pm`;
    my $constructor = `grep '^sub new ' $path/lib/perl/$dir/$module.pm`;
    my @run_modes;
    my %Run_mode;
    if ($module =~/_App\b/) {
        %Run_mode = %{ Code::get_run_modes("$path/lib/perl/$dir/$module.pm") };
        @run_modes = keys %Run_mode;
    }
   
    my ($object) = `grep ^package $path/lib/perl/$dir/$module.pm`;
    if ( $object =~ /package (.*);/i ) {
        $object = $1;
    }
    else {
        Message("Warning: no package detected");
        next;
    }

    Message("Warning: $path/lib/perl/$dir/$module.pm NOT FOUND\n") unless @methods;

    my $dbc_required = `grep '^use SDB' $path/lib/perl/$dir/$module.pm`;

    my $param = '';
    if ( $dbc_required && $create ) {
        print "Including database connection\n";
        $template .= `cat $path/template/dbc_template.txt`;
        $param = "-dbc=>\$dbc";    ## pass in connection object to constructor
    }

    my $sub_dir = '';

    if ( $dir =~ /\w+\/\w+.*/ ) {
        $dir =~ /(\w+)\/(\w+.*)/;
        $sub_dir = $2;
    }

    # if it's an object, create a self() subroutine for the default object creation
    my $type;
    if ( $create && $constructor ) {
        $type = 'dbc+';
        $template .= "sub self {\n";
        $template .= '    my %override_args = @_;' . "\n";
        $template .= '    my %args;' . "\n\n";
        $template .= "    # Set default values\n";
        $template .= "    # Example: " if !$dbc_required;                                                        # this comments out the next line if no DBC is required.
        $template .= '    $args{-dbc} = defined $override_args{-dbc} ? $override_args{-dbc} : $dbc;' . "\n\n";
        $template .= "    return new $sub_dir" . "::" . "$module(%args);\n\n";
        $template .= "}\n\n";
    }

    $template .= '#' x 60 . "\n" if $create;

    ### Establish whether the method has a constructor.  Also clarify what the object name should be (eg DBIO or SDB::DBIO) ###

    $template .= "<!-- END OF STANDARD BLOCK $type -->\n";
    $template .= "use_ok(\"" . $sub_dir . "::" . $module . "\");\n\n" if $create;

    # don't need to do this.  It just breaks the test if the constructor requires anything other than $dbc
    # $template .= "my \$self = new $object($param);\n" if $create && $constructor;    ## define new object if applicable

    my @included;
    if ($append) {
        ## generate list of methods already included (via a can_ok statement) ##
        if ($file =~ /_App\./) {
            ## Controller Module - test run modes only ##
            Message("Test Controller");
            my @tested = `grep test_run_mode $file`;
            map {
                if (/\-rm=>\'(.+?)\'/) { push @included, $1 }
                else { print "$_ not recognized test\n" }
            } @tested;
        }
        else {
            ## standard module - test methods individually ##
            my @can_oks = `grep 'can_ok' $file`;
            map {
                if (/ can_ok\(\"$object\", \'(.+?)\'\);/) { push @included, $1 }
                else                                      { print "$_ not recognized\n" }
            } @can_oks;
        }
        Message( "Already testing for: " . int(@included) . ' methods/run_modes' );
    }
    else {
        Message("Creating");
    }
      
    my $methods = 0;
    my $run_modes = 0;
    ### Add section for each run mode ###
    if (@run_modes) { 
        if (! `grep 'Add Run Mode Tests' $file`) {
            $template .= "########################\n## Add Run Mode Tests ##\n########################\n";
            $template .= "my \$page;    ## output from respective run mode (Use RGTools::Unit_Test methods to check for output tables etc)\n\n";
        }
        
        map {
            my $run_mode = $_;
            my $regex =  $run_mode;
            $regex =~s /([\(\)])/\\$1/g;
            unless ( grep { /^$regex$/ } @included ) {    ## method already included in current test file ##
                Message("Add '$run_mode' to @included");
                $template .= "### $run_mode ###\n";
                $template .= "\$page = Unit_Test::test_run_mode(-dbc=>\$dbc, -cgi_app=>'$sub_dir\:\:$module',-rm=>'$run_mode', -Params=> {});";
                $template .= "\n\n";
                $run_modes++;
            }
        } @run_modes;
    }
    else {
        ### Add section for each method ###
      map {
        if (/sub\s+(.*)\s+\{/)
        {    # added the first \s+ to take care of any extra spaces between the "sub" and the method name
            my $method = $1;

            unless ( grep /^$method$/, @included ) {    ## method already included in current test file ##
                $template .= "if ( !\$method || \$method =~ /\\b$method\\b/ ) {\n";
                $template .= "    can_ok(\"$object\", '$method');\n";
                $template .= "    {\n";
                $template .= "        ## <insert tests for $method method here> ##\n";
                $template .= "    }\n";
                $template .= "}\n\n";
                $methods++;
            }
        }
        else {
            print "Improperly defined method in $module ?:$_\n";
        }
      } @methods;
    }
    
    my $end_line = "## END of TEST ##\n";
    $template .= $end_line;
    $template .= "\nok( 1 ,'Completed $module test');\n";
    $template .= "\nexit;\n";

    my $file = $FindBin::RealBin . "/t/$dir/$module.t";
    my $path = $FindBin::RealBin . "/t/$dir/";

    if ($create) {
        if ( ( -e "$file" ) && !$overwrite ) {
            Message("** Warning: $module.t already exists [$file] **");
            print "\n (to add new tests to existing file -> abort and run using -append option\n\n";

            my $continue = Prompt_Input( -prompt => " Continue ? (will OVERWRITE current $module test file)\n (Yes / No / All) " );
            if ( $continue =~ /^A/i ) {
                Message("Overwriting ALL files");
                $overwrite = 1;
            }
            elsif ( $continue =~ /y/i ) {
                ## continue ... ##
            }
            else {
                Message("Aborting $module by choice");
                next;
            }
        }

        unless ( -e "$path" ) {
            try_system_command("mkdir $path");
        }
        open my $FILE, ">$file" or die "Cannot generate file: bin/t/$dir/$module.t : $!\n";
        print {$FILE} $template;
    }
    else {
        my $current_file = '';
        open my $FILE, "$file" or die "Cannot append to file: $file : $!\n";
        while (<$FILE>) {
            if   (/^$end_line/) { last; }
            else                { $current_file .= $_; }
        }

        close $FILE;

        ## Reopen to over write ##
        open my $FILE, ">$file" or die "Cannot overwrite file: $file : $!\n";
        print {$FILE} $current_file;
        print {$FILE} $template;
        close $FILE;
    }

    if ($run_modes) { print "Added $run_modes run modes in $module\n" }
    print "Generated test template for $module template ($methods new methods found)\n";
}

exit;
