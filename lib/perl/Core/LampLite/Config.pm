package LampLite::Config;

################################################################################
#
# Author           : Ran Guin
#
# Purpose          : Configuration Variable Accessor Module
#
#
################################################################################

use RGTools::RGIO qw(filter_input Call_Stack Cast_List);

use LampLite::DB;
use Data::Dumper;

##############################
# perldoc_header             #
##############################

my $Config;

$Config->{scope} = 'LampLite';
$Config->{db} = 'MySQL';

#####################
sub new {
#####################
    my $this = shift;
    my %args = @_;
    my $initialize = $args{-initialize};
    my $root       = $args{-root};         ## root directory 
    my $bootstrap  = defined $args{-bootstrap} ? $args{-bootstrap} : 1;    ## include bootstrap files 
    my $mode  = $args{-mode};    ## connection mode if applicable 
    my $files = $args{-files};
    my $debug = $args{-debug};
    
    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;

    $self->{root} = $root || './';
    
    if ($mode) { $self->{mode} = $mode }
    if ($bootstrap) { $self->{bootstrap} = $bootstrap }
    if ($initialize) { $self->initialize(-files=>$files, -initialize=>$initialize, -debug=>$debug) }
 
    return $self;
}

#############
sub value {
#############
   my $self = shift;
   my $key = shift;

    if ($key) {
        if (defined $Config->{$key}) { return $Config->{$key} }    
        elsif (ref $self && defined $self->{$key}) { return $self->{$key} }
        else { return }
    }
    else {
        return $Config;
    }
}

##################
sub initialize {
##################
    my $self = shift;    
    my %args = filter_input(\@_);
    my $init = $args{'-initialize'};   ## set true to initialize or pass in existing hash to initiate config hash.
    my $debug = $args{-debug};
    my $files = $args{-files} || [];         ## optional additional config files ... 
    my $required = $args{-required};
        
    ## Load config hash explicitly or from YAML file ##
    my $initialize;
    if (ref $init eq 'HASH') {
        ## passed in initialization hash (already loaded) ##
        $initialize = $init;
    }
    elsif ($self->{config} =~/\w/) { }
    else {
        ## load if file supplied ## 
        if ( !-e "$init" ) {
            ## temporary message for other developers to change over their personal config files ##
            print "Content-type: text/html\n\n";
            print "Aborting ... cannot find Initialization config file: $init";
            print Dumper \%args;
            Call_Stack();
            exit;
        }
        $initialize = $self->load_std_yaml_files(-files=>[$init], -debug=>$debug);
    }
   
    my $custom = $initialize->{custom_version_name};
    my $class = ref $self;
    
    if ($custom && $class =~/^LampLite/) {
        ## Dynamically load more specific class to load customized configuration variables as required ##
        my $Custom = $custom . '::Config';
        eval "require $Custom";
#        use Healthbank::Config;
        my $parent = $Custom->new( -bootstrap => 1, -initialize=> $initialize);
        $self->{config} = $parent->{config};
 
        return $self->{config};
    }    
   
    ## Determine root directory settings ##
    my $bin = $FindBin::RealBin;
    if ($bin =~/^(.*?)(\w+)\/(cgi\-bin|bin)\b/) {
        my $path = $1;
        my $v = $2;
        $initialize->{root} = $1.$2;
        $initialize->{root_directory} = $v;
        if ($v ne 'production') { $initialize->{url_suffix} = '_' . $v }
        else { $initialize->{url_suffix} = '' }
        
        $initialize->{url_root} = '/' . $initialize->{url_root} . $initialize->{url_suffix};      ### CUSTOM FOR NOW ...   "/SDB_version/"
    }
    else {
        print "xxx - WARNING - unrecognized bin directory: $bin\n";
    }
                
    ## Load standard custom config file (assume standard location in filesystem unless otherwise specified) ##
     if ($custom) {
        my $std_custom_config_file = $initialize->{root} . "/custom/$custom/conf/system.cfg";
        if (-e $std_custom_config_file) {
            push @$files, $std_custom_config_file;
        }
        else {
            print "WARNING: custom config file: $std_custom_config_file not found\n";
        }
    }
    
        my $directory_spec_file = $initialize->{root} . "/conf/directories.yml";

        if (-e "$directory_spec_file") {
            use LampLite::Build;
            my $Build = new LampLite::Build();
            my ($fs_ok, $message) = $Build->filesystem_check(-config=>$initialize, -create=>['data_root', 'web_root'], -file => $initialize->{root} . '/conf/directories.yml');
            if ($Build->{config}) {
                foreach my $key (keys %{$Build->{config}}) { $initialize->{$key} = $Build->{config}{$key} }
            }
        }
        else {
            print "xxx -  WARNING: could not find directory specification file: $directory_spec_file\n";
        }
    
    $self->{config} = $initialize;
    
    if (@$files) {
        ## exclude this block when running setup ## 
        $initialize = $self->load_std_yaml_files($files);
    }
    
    ## define css / js files as required ##
    $self->{config}{css_files} = [ $self->css_files(-custom=>$custom) ];
    $self->{config}{js_files} = [ $self->js_files(-custom=>$custom) ];
    
    ## define standard config settings ##
    my $mode = $self->{mode} || 'PRODUCTION';
    my $conf_dir = $self->{root} . "/conf";
    my $root = $self->{root};
    
    $self->{mode} = $mode;
    $self->{conf_dir} = $conf_dir;
    $self->{config}{url_params} = [ qw(CGISESSID) ];
    $self->{config}{session_params} = [ qw(session_id session_name user user_id user_name homelink db_user db_pwd version dbase host version path user_settings) ];
       
     ### Load initialization settings from personal config file ###
     my $default_host  = $initialize->{SQL_HOST};
     my $default_dbase = $initialize->{DATABASE};

     ## check for required configuration settings ##
     if ($required) {
         foreach my $reqd (@$required) { 
             if (! $initialize->{$reqd}) { 
                 abort("Configuration file is missing specification for '$reqd'");
                 last;
             }
         }
     }

    if ($debug) {
        print Dumper "Initialized Configuration Settings", $initialize;
    }
    
    return $initialize;  ## equivalent to $self->{config}
}

###########################
sub load_std_yaml_files {
###########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'files');
    my $files = $args{-files} || [];
    my $debug = $args{-debug};
 
    if (@$files) {
        foreach my $custom_file (@$files) {
            if (-e "$custom_file") {
                require YAML;
                my $init_config = YAML::LoadFile($custom_file);
                
                if ($debug) { print "Loaded $custom_file:\n*********************\n" }
                foreach my $key (keys %$init_config) {
                    $self->{config}{$key} = $init_config->{$key};
                    if ($debug) { print "$key = $init_config->{$key}...\n" }
                }
                push @{$self->{config}{config_files}}, $custom_file;
                $loaded++;
            }
            else {
                print "Content-type: text/html\n\n";
                Call_Stack();
                print "You should have a configuration file called $custom_file.";
            }
        }
    }
    
    return $self->{config};    
}

#################
sub css_files {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    my $custom = $args{-custom};
    my $mobile = $args{-mobile};
    my $dir = $args{-dir};
 
 #   chosen.min
     
    my @css_files = qw(
        jquery-ui.min
        jquery.datetimepicker
        bootstrap-multiselect.min
        bootstrap-formhelpers
        jquery.dataTables.min.css
        LampLite
     ); 
    
    ## Add bootstrap if applicable ##
    my $bootstrap    = 1;
    my $font_awesome = 1;
    
    my $bootstrap_dir = "$dir/bootstrap.v3.0.3";
    my $bootstrap_dir = "$dir/bootstrap-3.1.1-dist";
    my $font_awesome_dir = "$dir/font-awesome-4.0.3";

    if ($bootstrap) {
        push @css_files, ( "bootstrap.min.css", "custom_bootstrap" );
        if ($mobile) { push @css_files, "custom_mobile.css" }

    }
#    push @css_files, $self->{config}->{custom_version_name} . ".css";

    if ($font_awesome) {
        push @css_files, 'font-awesome.css'; ## "$font_awesome_dir/css/font-awesome.css";
    }    

    return @css_files;
}

#################
sub js_files {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my $mobile = $args{-mobile};
    my $dir = $args{-dir};
    
    ## the simpler list below seems to break the layering functionality ... should look into this, but use older jquery for now ##
    #       jquery.v2.0.3.min
    #        underscore-min
    my @js_files = qw(
        DHTML
        Prototype
        json
        jquery-1.11.2.min
        jquery-ui.min
        jquery.floatThead.min
        jquery.datetimepicker
        jquery.dataTables.min.js
        https://ajax.googleapis.com/ajax/libs/angularjs/1.2.16/angular.js
        https://ajax.googleapis.com/ajax/libs/angularjs/1.2.16/angular-resource.js
    );

    ## Add bootstrap if applicable ##
    my $bootstrap    = 1;
    my $bootstrap_dir = "$dir/bootstrap-3.1.1-dist";
    
    if ($bootstrap) {
        push @js_files, "bootstrap.min.js";
    }
    
    ## insert AFTER Bootstrap ##
    push @js_files, (
        'bootstrap-multiselect.old', ## next versionup has a bug that breaks auto-complete (?)   
        'bootstrap-formhelpers.min',
        'LampLite'
    );
    
    push @js_files, "custom_bootstrap";
    # chosen.jquery.min

    return @js_files;
}

#
# Dump configuration settings (used when debug flag is set... )
###########
sub dump {
###########
    my $self = shift;
    
    my $dump;
    foreach my $key ( keys %$self ) {
        my $val = $self->{$key};

        $dump .= "$key = ";
        if ( ref $val eq 'ARRAY' ) {
            if ( $0 =~ /cgi-bin/ ) {
                $dump .= Cast_List( -list => $val, -to => 'UL' );
            }
            else {
                print "\n\t";
                print join "\n\t", @$val;
            }
        }
        elsif ( ref $val eq 'HASH' && $debug > 1 ) {
            if ( $0 =~ /cgi-bin/ ) {
                use SDB::HTML;
                $dump .= HTML_Dump $val;
            }
            else {
                use Data::Dumper;
                $dump .= Dumper $val;
            }
        }
        else {
            $dump .= $self->{$key};
        }

        $dump .= "\n";
    }
    
    return $dump;
}

1;
