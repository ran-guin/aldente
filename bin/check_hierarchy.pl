#!/usr/local/bin/perl
#######################################################################################
## Standard Template for building cron jobs or scripts that connect to the database ###
#######################################################################################
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/LampLite";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";

########################
## Local Core modules ##
########################
use CGI;
use Data::Dumper;
use Benchmark;

##########################
## Local custom modules ##
##########################
use RGTools::RGIO;

use LampLite::Bootstrap;
use LampLite::Config;

## Globals ##
my $q               = new CGI;
my $BS              = new Bootstrap();
my $start_benchmark = new Benchmark();

$| = 1;
##############################################################
## Temporary - phase out globals gradually as defined below ##
##############################################################

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
        
###################################################
## END OF Standard Module Initialization Section ##
###################################################

## Load input parameter options ## 
#
## (replace section below with required input parameters as required) ##
#
use vars qw($opt_p $opt_m $opt_v $opt_s $opt_w $opt_i $opt_h $opt_l);

use Getopt::Long;
&GetOptions(
    'path|p=s'    => \$opt_p,
    'dir|d=s'  => \$opt_m,
    'verbose|v|debug' => \$opt_v,
    'module|file|script|s=s' => \$opt_s,
    'levels|l=s'   => \$opt_l,
    'watch|w=s'    => \$opt_w,
    'ignore|i'   => \$opt_i,
    'force|f'    => \$opt_f,
    'help|h'     => \$opt_h,
);

my $path = $opt_p || './lib/perl/*';
my $mod_dir = $opt_m;
my $verbose = $opt_v;
my $script = $opt_s;
my $watch = $opt_w;
my $ignore = $opt_i;
my $levels = $opt_l || 10;
my $force = $opt_f;

my $watch_found = 0;
my %Modules_Loaded;

my @ignore;
if ($ignore) { @ignore = Cast_List(-list=>$ignore, -to=>'array') }

# my @internal_directories = qw(RGTools LampLite SDB alDente);
my $std_modules = [];
my %Std_Modules;
my %Std_Referenced;
my %Std_Referrals;
my %Modules;
my %Referenced;
my %Referrals;

unless ($mod_dir || $script) {
    print "\nUsage\n***********\n\n";
    print "check_hierarchy [options]\n\n";
    print "Options:\n\n";
    print "-p(ath) path (specify path for library - eg /home/sequence/lib/perl)\n";
    print "-m(odule) module (eg -m alDente or -m SDB)\n";
    print "-s(cript) script (eg -s ./barcode.pl)\n";
    print "-v(erbose) or d(ebug) (verbose)\n";
    print "-l(evels) N - number of levels to explore (to stop exectution after N levels of subcalls)";
    print "-i(gnore) modules - ignore modules (do not follow subcalls from these modules)";
    print "\n\n";
    exit;
}

my $extension = ".pm";
my $found = 0;
my $Finished;

my @checked;
my @conflicts;

if ($script) {
    print "Check loaded modules from $script\n\n";
    my @modules = get_modules(-file=>$script, -from=>'main', -modules=>[]);
        my @std_modules = sort keys %Std_Modules;
        print int(@std_modules)  . " External Modules loaded \n*******************************\n";
        foreach my $mod (@std_modules) {
            my $references = join ', ', keys %{$Std_Referenced{$mod}};
            my $refers     = join ', ', keys %{$Std_Referrals{$mod}};
            print "$mod\n\tReferenced By: [$references]\n\tReferrals: [$refers]\n";
        }
        print "\n\n";
        
        my @modules = sort keys %Modules;
        print int(@modules)  ." Internal Modules loaded (in order):\n*******************************\n";
        foreach my $mod (@modules) {
            my $references = join ', ', keys %{$Referenced{$mod}};
            my $refers     = join ', ', keys %{$Referrals{$mod}};
            print "$mod\n\tReferenced By: [$references]\n\tReferrals: [$refers]\n";
        }
        
        print "\n";
        print "*"x50;
        print "\nConflicts:\n";
        print "*"x50;
        print "\n";
        print join "\n", @conflicts;
        print "\n";
}
elsif ($path && $mod_dir) {

    my $level = 1;
    my @modules; 
    
    if ($mod_dir =~/^(.+)\/(\w+)\/(\w+)\.pm$/) {
        $path = $1;
        $mod_dir = $2;
        @modules = ($3);
    }
    else {
        @modules = glob("$path/$mod_dir/*.pm");
    }

    print "$path/$mod_dir/*.pm\n******************************************\n";
    print join "\n", @modules;
    print "\n****************************\n";
    
    while (@modules) {
        my @message;
        my $Still_Open;
        print "*****************\nLevel $level\n**********************\n";
        foreach my $thisfile (@modules) {
            if ($thisfile=~/HASH/) {next;}
            elsif (!$thisfile) {next;}
            if ($thisfile=~/(.*)\/(.+)$extension/) { $thisfile = $2; }

            if ($Finished->{$thisfile} == $level) {print "$thisfile\n";}
            elsif (!$Finished->{$thisfile}) {
                my @newcalls = sub_calls($path,$mod_dir,$thisfile,$level);
                foreach my $module (@newcalls) {
                    $Still_Open->{$module}=1;
                }

                $Still_Open->{$thisfile}=1;
#                if ($level > 10) { $watch ||= $thisfile }
                if ($verbose || ($watch =~/$thisfile/)) { $watch_found=1; push(@message,"** $thisfile (still calls @newcalls) **"); }
            }
            #	    else {print "$thisfile ($level)?". $Finished->{$thisfile};}
        }
        @modules = keys %{$Still_Open};
        $level++;
        print join "\n", sort @message;
    }
}

else {print "Please specify directory where modules exist\n";}
print "\nDone..\n";
exit;

##################
sub found_watch {
##################
    my $source = shift;
    my $target = shift;
    
    my $message = shift || "$source -> $target\n";
    
    if ( $watch &&  ( ($source =~/\b$watch\b/) || ($source =~/\b$watch\b/) ) ) {    
        print "="x50;
        print "\n[Watching $watch] $message\n";
        print "="x50;
        print "\n";
    }
    
    $watch_found = 1;
}

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#
# Recursively loads modules as required... 
#
##################
sub get_modules {
##################
    my %args = filter_input(\@_);
    my $directory = $args{-directory} || '.';
    my $file = $args{-file};
    my $module = $args{-module};
    my $modules = $args{-modules};
    my $generation = $args{-generation} || 0;
    my $checked    = $args{-checked};
    my $from = $args{-from};
    my $verbose = $verbose;
   
    my @core_directories = qw(SDB RGTools LampLite alDente Plugins Experiments);
    
    if ($file !~/\.pl$/) {$file = "$path/$directory/$module.pm" }
    
    my $source = $module || $file;
    
    my $grep = "grep '^use ' $file | grep -v 'use vars' | grep -v 'use lib' | grep -v 'use strict'";
    my @original = split "\n", `$grep`;
    
    if ($generation > $levels) { print "\n*** Aborting after $levels levels ... ***\n"; return (); }
    if ($verbose) {
        print "\n****** Generation $generation ***********\n";
        
        if (!$force || $watch_found) {
            print "Found use of $watch [W:$watch_found : F:$force]\n";
            $watch_found = 0;
            my $c = Prompt_Input(-prompt=>'continue ? Yes/No/All >');
            if ($c =~/^a/i) { print "Skipping prompt confirmation henceforth...\n"; $force = 1; }
            elsif ($c !~/^y/i) { print "aborting... \n"; exit; } 
        }
        
        print "Modules required from $file...\n";
 #       print "$grep\n";
        print new_loads(\@original,'Required');
        print "\n\n";
        print "*"x55;
        print "\nLoaded Modules:\n";
        print new_loads([ keys %Modules ], 'Loaded');
        print "\n";
        print "*"x55;
        print "\nConflicts:\n";
        print "*"x50;
        print "\n";
        print join "\n", @conflicts;
        print "\n";
        print "*"x55;
        print "\nChecked:\n";
        print "*"x50;
        print "\n";
        print join "\n", @checked;
        print "\n\n";
    }
    
    my $added = 0;
    my @total_mods;
    
    foreach my $use (@original) {
        if ($use =~/use\s(base\s|)([\w:]+)[;\s]/) {
            my $scope = $1;
            my $used_module = $2;
            my $used_directory = '';
            my $use_module = '';
            
            foreach my $dir (@core_directories) {
                if ($dir && $used_module =~/^$dir\:\:(\w+)/) {
                    $use_module = $1;
                    $used_directory = $dir;
                    $used_module = $use_module;
                    last;
                }
            }

            if (grep /^$used_directory\:\:$used_module$/, keys %Modules) { 
                if ($verbose > 1) { print "already loaded $used_directory" . "::$used_module...\n" }
            }
            elsif (grep /^$used_module$/, keys %Modules) { 
                if ($verbose > 1) { print "already loaded $used_module...\n" }
            }
            elsif (grep /^$used_directory\:\:$used_module$/, @$checked) { 
                my $conflict_msg = "XXX $used_directory" . "::$used_module should already be loaded.";
                if (! grep /^$conflict_msg/, @conflicts) { 
                    push @conflicts, "$conflict_msg [prior to $directory" . "::$module]"; 
                    print "*** Conflict found: $conflict_msg [prior to $directory" . "::$module]\n";
                }
            }

            $added++;
            
            if (grep /^$used_directory$/, @core_directories) {               
                
                if (! grep /$directory\:\:$module/, @checked) { push @checked, $directory . '::' . $module }

                print "\t"x$generation;  ## indent to make generations more obvious ##
                print "*** $source uses $scope module: $used_directory" . " :: $used_module [gen=$generation] ***\n";
                
                my $modules = [ keys %Modules ];
                my @mods, get_modules(-from=>$source, -directory=>$used_directory, -module=>$used_module, -modules=>$modules, -generation=>$generation+1, -checked=>\@checked);               
                
                foreach my $mod (@mods) {
                    if ( ! grep /^$mod$/, keys %Modules ) {
                        push @total_mods, $mod;
                    }
                }
                
                my $this_module = $used_directory . '::' . $used_module;
                if ($used_module) { 
                    $Modules{$this_module} = 1; 
                }
                $Referenced{$this_module}{$source} = 1;
                $Referrals{$source}{$this_module} = 1;
                found_watch($source, $this_module);
                if ($verbose) { print "** REFER $source -> $this_module **\n" }
            }
            else {
                if (! grep /^$used_module$/, keys %Modules) { 
                    if ($verbose) { print "*** $source requires Std module: $used_module ***\n"; }
                    $Std_Modules{$used_module} = 1; 
                }
                $Std_Referenced{$used_module}{$source} = 1;
                $Std_Referrals{$source}{$used_module} = 1;
                
                found_watch($source, $this_module);
                if ($verbose) { print "*** REFER $source -> $used_module ***\n" }

            }
        }
    }
   
    if (@total_mods) {
        if ($verbose > 1) {
            print "***************\nStill waiting for:\n*******************";
            print join "\n", @total_mods;
            print "\n******\n";
        }
    }
    else {
        if (! grep /$directory\:\:$module$/, keys %Modules) { 
            if ($source ne $module) {
                if ($source) { 
                    $Modules{$directory . '::' . $module} = 1; 
                }
                $Referenced{$directory . '::' . $module}{$source} = 1; 
                $Referrals{$source}{$directory . '::' . $module} = 1; 
                
                found_watch($source, $this_module);
                
                if ($verbose) { print "* REFER $source -> $directory :: $module *\n" }
            }
        }
    }

    return keys %Modules;
}   
    
##################
sub sub_calls {
##################
    my $path = shift;
    my $mod_dir = shift;
    my $file = shift;

    my $level = Extract_Values([shift,1]);

    if ($verbose) { print "\nCheck $file\n*********************\n"; }

    if ($level > $levels) { return () }
    
    if (grep /$mod_dir$/, @ignore) { print " ** (ignoring subcalls from $mod_dir) **\n"; return (); }
    
    my $command = "grep \"^use $mod_dir\" $path/$mod_dir/$file$extension";
    my $bases = "grep \"^use base $mod_dir\" $path/$mod_dir/$file$extension";
   
#    print "** $command **\n";
    my @subcalls = split "\n",try_system_command($command);
    my @basecalls = split "\n",try_system_command($bases);
    
    my @modules = ();
    foreach my $call (@subcalls) {
#	print "C: $call...";
	if ($call=~/^use (base |)$mod_dir\:\:(\S+)\b/) {
#	    print "-> $1;\n";
        my $scope = $1;
	    my $module = $2;
	    if ($Finished->{"$module"}) {
		if ($verbose) {print "($module finished)\n";}
	    } else {
		push(@modules,$module);
		if ($verbose) {print "** ($module still open) ** \n";}
	    }
	} else { print "\n **** Wierd format ($call) ***\n"; }
    }
    unless (int(@modules)) {
	$Finished->{$file} = $level;
    }

    return @modules;
}

################
sub new_loads {
################
    my $list = shift;
    my $group = shift;
    
    my $Current = $Modules_Loaded{$group} || {};
    foreach my $item (@$list) {
        if ( grep /^$item$/, keys %$Current ) { next }
        else { 
            print $item . "\n";
            $Current->{$item}++;
        }
    }

    $Modules_Loaded{$group} = $Current;
    return;
}

##############################
# private_methods            #
##############################
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

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: check_hierarchy.pl,v 1.5 2004/03/17 00:39:06 rguin Exp $ (Release: $Name:  $)

=cut

