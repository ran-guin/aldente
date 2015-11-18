###################################################################################################################################
# alDente::Document_Views.pm
#
#
#
#
###################################################################################################################################
package alDente::Document_Views;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use alDente::Attribute_Views;

################
# An HTML document generator to enable automatic viewing of code showing descriptions, arguments etc.
################
sub view_Code {
################
    my %args        = &filter_input( \@_ );
    my $Document    = $args{-Document};
    my $module      = $args{-API} || $args{-module} || param('API');          ## name of module or API to display (eg. DBIO)
    my $dir         = $args{-dir} || param('Directory');                      ## directory within library where module exists (eg SDB)
    my $path        = $args{-path} || param('Path') || $Configs{perl_dir};    ## path where module library is (defaults to alDente's beta perl library)
    my $module_list = $args{-modules} || param('Modules');                    ## optional list of specified modules to enable access to (array ref)
	my $dbc = $args{-dbc};
	
    my ( $path_mod, $error ) = try_system_command("find $path -name $module.pm -follow");
    my @path_mod = split " ", $path_mod;

    if ( $path_mod[0] =~ /\Q$path\E(.+)\/$module/ && !$dir) { $dir = $1; }

    my %layers;
    my $format = 'tab';

    my @exclusions = qw(new DESTROY error warning errors warnings generate_data api_output);    ## exclude documentation on these methods (as well as methods starting with _ )

    my @modules;
    if ($module_list) {
        @modules = Cast_List( -list => $module_list, -to => 'array' );
        $module_list = join ',', @modules;                                                      ## convert to string to use in link.
    }
    else {
        my $found = `ls $path/*/*.pm`;
        @modules = split "\n", $found;
    }
    ## generate general layer with link to all modules ##
    my %Modules;

    foreach my $module (@modules) {
        my $mod;
        my @dirs;

        if ( $module =~ /\/?(\w+)(\/|::)(\w+)(\.pm|)$/ ) {
            $dir = $1;
            $mod = $3;
            push @dirs, $dir unless ( grep /^$dir$/, @dirs );
        }
	elsif ( $dir ) {
	    $mod = $module;
	} 
        else { Message("$module not found (or not in dir::name format)"); next; }

        my ( $path_mod, $error ) = try_system_command("find $path -name $mod.pm -follow");
        my @path_mod = split " ", $path_mod;

        $Modules{$dir} .= '<LI>' . Link_To( $dbc->config('homelink'), $mod, "cgi_application=alDente::Document_App&rm=View Modules&Directory=$dir&API=$mod&Modules=$module_list", -window => ['code'], -tooltip => "View methods" );
        if ( $path_mod[0] =~ /\Q$path\E(.+)\/$mod/ ) { $dir = $1; }
        if ( -e "$Configs{web_dir}/html/perldoc/lib/perl/$dir/$mod.pm.html" ) { $Modules{$dir} .= &Link_To( "../html/perldoc/lib/perl/$dir/$mod.pm.html", "-[pod]", -window => ['pod'], -tooltip => 'View source code' ) }

        #        else { $Modules{$dir} .= Show_Tool_Tip('(no)',"$Configs{web_dir}/html/perldoc/lib/perl/$dir/$mod.pm.html") }
    }

    my $APIs = new HTML_Table( -title => 'alDente Modules', -border => 1 );
    my @headers;
    foreach my $dir ( keys %Modules ) {
        push @headers, $dir;
        $APIs->Set_Column( [ "<UL>\n" . $Modules{$dir} . "\n</UL>\n" ] );
    }
    $APIs->Set_Headers( \@headers );
    $APIs->Set_VAlignment('top');

    my @order;

    if ($module) {
        my @sections = qw(SYNOPSIS DESCRIPTION NAME);
        foreach my $section (@sections) {
            $layers{$section} = alDente::Tools::search_code(
                path        => "$Configs{perl_dir}/$dir",
                filename    => "$module.pm",
                output      => "search.$section" . localtime(),
                search_area => 'routine',
                method      => $section,
                section     => $section
            ) || "($section section not found)";
            push @order, $section;
        }

        ## Get list of methods in each module ##
        my @methods = split "\n", try_system_command("grep '^sub ' $Configs{perl_dir}/$dir/$module.pm");
        if ( $methods[0] =~ /No such file/i ) { Message("cannot find $Configs{perl_dir}/$dir/$module.pm") }
        foreach my $method ( sort @methods ) {
            $method =~ s /^sub\s+(\w+)(.*?)$/$1/;
            ## skip inappropriate methods:  internal ones, excluded ones, old ones etc. ##
            if ( !$method ) {next}
            elsif ( grep /^$method$/, @exclusions ) {next}
            elsif ( $method =~ /^_/ )     {next}
            elsif ( $method =~ /_OLD$/i ) {next}

            my $layer = alDente::Tools::search_code(
                path        => "$Configs{perl_dir}/$dir",
                filename    => "$module.pm",
                output      => "search.$method" . localtime(),
                search_area => 'routine',
                method      => $method,
            );

            #	      if (grep /^$method$/, @highlights) { $method = "<Font color=red>$method</Font>" }   ## highlight methods most commonly used ##
            $layers{$method} = $layer || "(method $method not found in $module)";
            push @order, $method;
        }
    }
    else {
        return $APIs->Printout(0);
    }

    $layers{'other Modules'} = $APIs->Printout(0);
    unshift @order, 'other Modules';

    my $output = SDB::HTML::define_Layers(
        -layers    => \%layers,
        -tab_width => 100,
        -order     => \@order,
        -default   => 'DESCRIPTION',
        -format    => 'list'
    );
    return $output;
}

1;
