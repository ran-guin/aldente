package SDB::Config;

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
use RGTools::RGIO qw(filter_input);
use base LampLite::Config;

#@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
#require Exporter;
#@EXPORT = qw(
#    
#);

my $Config;

$Config->{scope} = 'SDB';
$Config->{database} = 'mysql';

$Config->{java_header} = "\n<!------------ JavaScript ------------->\n"
    . "\n<script src='/$URL_dir_name/$jsversion/FormNav.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/calendar.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/SDB.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/form.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/onmouse.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/json.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/Prototype.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/alttxt.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/DHTML.js'></script>\n"

    #. "\n<script src='/$URL_dir_name/js/jquery.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/jquery-custom.js'></script>\n" . "\n<script src='/$URL_dir_name/$jsversion/jquery-ui-custom.js'></script>\n" . "<script type=\"text/javascript\">\n" . "jQuery.noConflict();\n" . "</script>";

$Configs->{html_header} = "\n<!------------ CSS ------------->\n"
    . "\n<META HTTP-EQUIV='Pragma' CONTENT='no-cache'>\n"
    . "\n<META HTTP-EQUIV='Expires' CONTENT='-1'>\n"
    . "\n<!------------ Style Sheets ------------->\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/FormNav.css'>\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/calendar.css'>\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/style.css'>\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/cssmenu.css'>\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/colour.css'>\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/jquery-ui-custom.css'>\n";

#############
sub value {
#############
    my $self = shift;
    my $key = shift;

    if ($key) {
        return $Config->{$key} || LampLite::Config->value($key);
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
    
    return $self->SUPER::initialize(%args);
}

#################
sub css_files {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my @css_files = $self->SUPER::css_files(%args);

    my @local_css = qw(
        FormNav
        colour
        menu
        custom_text_box
        SDB
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
        SDB
        form
        onmouse
        alttxt
        FormNav
    );
    
    push @js_files, @local_js;
    
    return @js_files;
}

1;