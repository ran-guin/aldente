package alDente::Config;

################################################################################
#
# Author           : Ran Guin
#
# Purpose          : Configuration Variable Accessor Module
#
#
################################################################################

##############################
# perldoc_header             #
##############################

##############################
# superclasses               #
##############################
use base SDB::Config;

use RGTools::RGIO;

use LampLite::DB;

use strict;


#######################################
# global variables - phase out       #
#######################################

use vars qw(%Prefix);

my $Config;

$Config->{scope}    = 'SDB';
$Config->{database} = 'mysql';

#############
sub value {
#############
    my $self = shift;
    my $key  = shift;

    if ($key) {
        if ( defined $Config->{$key} ) { return $Config->{$key} }
        elsif ( ref $self && defined $self->{$key} )          { return $self->{$key} }
        elsif ( ref $self && defined $self->{configs}{$key} ) { return $self->{configs}{$key} }
        else                                                  { return SDB::Config->value($key) }
    }
    else {
        return $Config;
    }
}

#
# Retrieve standard log file based upon current file being executed
#
# Options:
#  - type (web / data / relative)  - relative generates url relative path (default = data for standard logging)
#  - ext  (file extension) - generally 'log' (default) or 'html'
#
# Return: log file path
####################
sub get_log_file {
####################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $config = $args{-config};         ## config variables required if retrieving web or data logs
    my $ext    = $args{-ext} || 'log';
    my $type   = $args{-type};           ## data / url / web

    my $file_name = $0;
    $file_name =~ s/(.*)\/(.*?)$/$2/;
    $file_name =~ s/\.pl$//;
    my $timestamp = substr( timestamp(), 0, 8 );

    my $log;
    if    ( $type =~ /relative/i ) { $log = "../tmp" }
    elsif ( $type =~ /web/ )       { $log = $config->{Web_log_dir} . "/$file_name" }
    else                           { $log = $config->{data_log_dir} . "/$file_name" }

    $log .= "/$file_name.$timestamp.$ext";

    return $log;
}

################
sub initialize {
################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $debug = $args{-debug};                     ## show config settings (use debug > 1 to show hash details)
    
    my $init_config = $self->SUPER::initialize(%args);

    ## PHASE OUT - or redesign ... ##
    use SDB::CustomSettings;
    use alDente::SDB_Defaults;   
    
    my $mobile = 0;    ## temporarily keep track of mobile option until bootstrap is set up for mobiles...
    use vars qw(%Search_Item);    ## replace with $dbc->config()
    ##############################################################
    my $merged = LampLite::DB::merge_configs( [ $init_config, { 'Search_DB' => \%Search_Item } ] );

    ## <CONSTRUCTION> phase out config variations ##
    my $redundant = {
        'IMAGE_DIR' => 'images_url_dir',
        'session_dir' => 'session_web_dir',
        'png_dir' => 'png_url_dir',
        'url_name' => 'url_root',
        'url_dir' => 'url_root',
        'sessions_dir' => 'sessions_web_dir',
        'session_dir' => 'sessions_web_dir',
        'submission_dir' => 'submissions_data_dir',
    };
    foreach my $key (keys %{$redundant}) { 
        my $same = $redundant->{$key};
        $merged->{$key} = $merged->{$same};
     }
       
    my $configs = $merged;
    $self->{config} = $merged;
    
    my $custom = $init_config->{custom_version_name};
    my $path = "SDB" . $init_config->{url_suffix};

    $self->{path}         = $path;

    ########################
    ## Customized Section ##
    ########################
    my $home = "$domain/$path/cgi-bin/";
    my $file = $0;
    
    $file =~s/(.+)\/(.+)$/$2/;
    $home .= $file;
    
    my $mobile;
    if ( $0 =~ /scanner/ ) {
        $self->{screen_mode} = 'mobile';
        $ENV{DISABLE_TOOLTIPS} = 1;
        $home =~ s/alDente\.pl/scanner\.pl/;
        $mobile = 1;
    }
    else {
        $self->{screen_mode} = 'desktop';
    }
    $self->{home} = $home;

    my $brand_image = "/$path/images/png/alDente_brand.png";
#    $self->{icon} = $brand_image;
    $self->{config}{icon} = $brand_image;

    my @session_params;
    if ($merged->{session_params}) { @session_params = @{$self->{config}{session_params}} }
    push @session_params, qw(access Active_Projects_Only);    ## stored under session as persistent parameters
    
    my @url_params;
    if ($merged->{url_params}) { @url_params = @{$self->{config}{url_params}} }
    push @url_params, qw(Database_Mode);                                                                                                                   ## parameters automatically passed excplicitly within URL

    $self->{config}->{home} = $home;
 
    ### Custom CSS / JS Files ###
    if   ( $self->{config}->{login_type} =~ /Contact/ ) { push @url_params, 'Target_Project' }
    else                              { push @url_params, 'Target_Department' }

    $self->{config}{url_params}     = \@url_params;
    $self->{config}{session_params} = \@session_params;

    ## Initialize CSS & JS files ##

    my @css_files = $self->css_files(-mobile=>$mobile, -dir=>"./..");
    my @js_files = $self->js_files(-mobile=>$mobile, -dir=>"./..");
    
    ## Add bootstrap if applicable ##
    my $bootstrap    = $self->{bootstrap} || 1;

    if ($bootstrap) {
        my $custom_bs = "custom_" . lc($custom) . '_bootstrap.css';
        push @css_files, ( $custom_bs );
    }

    $self->{config}{css_files} = \@css_files;
    $self->{config}{js_files} = \@js_files;

    ## Initialization Errors ##
    my @init_errors;
    if    ( !$init_config )   { push @init_errors, "Missing Initialization Configuration File (personalize.cfg)" }

    $self->{init_errors} = \@init_errors;

    if ($debug) {
        print $self->dump();
    }
     
    ###############################
    ## END OF Customized Section ##
    ###############################
    SDB::CustomSettings::load_config($configs); ## <CONSTRUCTION> - Phase out .. 
    
    ## TEMPORARILY update configuration variables to include root paths ##
    foreach my $key (keys %$configs) {
        if ($configs->{$key} =~ /^\/(private|public|dynamic|images)/) {
            my $type = $1;
            if ($type eq 'private' || $type eq 'public') { $configs->{$key} = $configs->{data_root} . $configs->{$key} }
            if ($type eq 'dynamic') { $configs->{$key} = $configs->{www_web_dir} . $configs->{$key} }
            if ($type eq 'images') { $configs->{$key} = $configs->{url_root} . $configs->{$key} }
        }
    }
    
    $self->{configs} = $configs;
    
    return $configs;
}

############################
sub load_barcode_prefixes {
############################
    my $self = shift;
    my $hash = shift;
    
    if ($hash && defined $hash->{Barcode_Prefix}) {
        %Prefix = %{ $hash->{Barcode_Prefix}};  ## define Barcode Prefixes... 
    }
}

#################
sub css_files {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my @css_files = $self->SUPER::css_files(%args);

    my @local_css = qw(
        alDente
        menu
        custom_text_box
        select2
        owl.carousel
        owl.theme
        owl.transitions
     ); 
     
    push @css_files, @local_css;  
    
    return @css_files;
    
}

#################
sub js_files {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my @js_files = $self->SUPER::js_files(%args);
    
    my @local_js = qw(  
        alDente
        select2
        owl.carousel
    );
    
    push @js_files, @local_js;
    
    return @js_files;
}

1;
