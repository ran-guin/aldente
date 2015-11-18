package RGTools::RGWeb;

use strict;
use Data::Dumper;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);

use SDB::HTML;
use SDB::CustomSettings;
use RGTools::RGIO;

########################################
# Method to create a tab bar
#
# <snip>
# my %tabs_hash = ( 'tab1' => '<h1> content of page 1 </h1>',
#                   'tab2' => '<table><tr><td>A</td><td>B</td></tr></table>'
#                 );
#
# my ($tab,$tabcontent) = RGTools::Web::Create_Tab(-items=>\%tabs_hash, -default=>$default_tab);
#
# print $tab . $tabcontent;
# </snip>
#
# Returns two strings. First one is the tab itself, and second one is the tab content
#
####################
sub Create_Tab {
####################

    my %args = filter_input(
         \@_,
        -args      => 'items,default,order',
        -mandatory => 'items'
    );
    my $items   = $args{-items};
    my $default = $args{-default};    #Default Tab
    my $order   = $args{-order};      #Order array ref

    my %elements = %{$items};

    #Figure out the order
    my @order;
    if ($order) {
        @order = @{$order};
    }
    else {
        @order = sort keys %elements;
    }

    #The tab itself
    my $tab = qq^<div id="tablist">\n^;

    #The content of the tab
    my $tabcontent = qq^<div id="tabcontentcontainer">\n^;
    foreach my $item (@order) {
        if ( !$elements{$item} ) {next}

        $tab .= qq^<li onClick="expandcontent('$item', this)">$item</li>\n^;

        $tabcontent .= qq^<div id='$item' class="tabcontent">\n$elements{$item}\n</div>\n\n^;
    }
    $tab        .= "</div>\n";
    $tabcontent .= "</div>\n";
    $tabcontent .= "<script> do_onload('$default') </script>\n";

    #Return the tab and tab content as two strings
    return ( $tab, $tabcontent );

}

########################################
# Method to create an expandable input
#
# <snip>
#
# my @elements = (101..105);
# my %labels=> { '1' => 'first',
#	         '2' => 'second',
#	         '3' => 'third'
#	       };
# print expandable_input(-name=>'myTxt3', -type=>'text', -elements=>\@elements, -options=>\%labels, -default=>[1,1,2,3,3], -propagate=>3);
#
# </snip>
#
# Returns an HTML string that can be printed out
#
####################
sub expandable_input {
####################

    my %args = filter_input( \@_, -args => 'name', -mandatory => 'name' );

    my $elements = join( "','", @{ $args{-elements} } );    #Elements array. Array ref
    my $fieldtype  = $args{-type} || 'text';                             #Type of this input field. Either text or hidden (button)
    my $fieldname  = $args{-name};                                       #Name of this input field.
    my $opt_header = $args{-opt_header} || [ 'Element ID', 'Value' ];    #Headers for options input field. Array ref of size 2
    my $opt_type   = $args{-opt_type} || 'dropdown';                     #Type of options input field. dropdown or text
    my $options    = $args{-options};                                    #List of Options available. An array ref or a hash ref
    my $propagate  = $args{-propagate} || 0;                             #0: No propagate (default), 1: Normal Propagate, 2:Incremental Propagate, 3:Propagate All
    my $default    = $args{ - default };                                 #Default value for this input. Either a string or array of size elements

    if ( $opt_type ne 'dropdown' && $opt_type ne 'text' ) {
        return 'Error: Invalid options type';
    }

    my ( $labels, $keys ) = ' ';

    if ( $opt_type eq 'text' ) {
        if ( $propagate == 2 ) {
            return "Error: Does not make sense to use incremental propagate when opt_type is 'text'";
        }
        if ($options) {
            return "Error: Does not make sense to specify options when opt_type is 'text', perhaps you want defaults";
        }
    }
    else {

        #Populate the options lists
        if ( ref($options) =~ /ARRAY/ ) {
            $keys = "','" . join( "','", sort @{$options} );
            $labels = $keys;
        }
        elsif ( ref($options) =~ /HASH/ ) {
            foreach ( sort keys %{$options} ) {
                $keys   .= "','" . $_;
                $labels .= "','" . $options->{$_};
            }
        }
        else {
            return 'Error: Invalid options list type' . ref($options) . $options . '!';
        }
    }

    if ($opt_header) {
        $opt_header = join( "','", @{$opt_header} );
    }

    if ($default) {
        if ( !ref($default) ) {
            $default = "$default," x scalar( @{ $args{-elements} } );
            $default =~ s/,$//;
        }
        elsif ( ref($default) =~ /ARRAY/ ) {
            if ( scalar( @{ $args{-elements} } ) == scalar( @{$default} ) ) {
                $default = join( ',', @{$default} );
            }
            else {
                return "Error: Length of elements (" . scalar( @{ $args{-elements} } ) . ") does not match the length of defaults (" . scalar( @{$default} ) . ")";
            }
        }
    }

    #A flag to keep track of whether the window is open or closed (default closed)
    my $flag = "<input type='hidden' id='$fieldname" . "_windowOpen' value=0>";
    ## for some reason CGI.pm doesn't print the id attribute, so we have to write the hidden tag by hand
    #  my $flag = hidden(-name=>$fieldname . "_windowOpen", -id=>"fieldname_windowOpen", -value=>0);
    my $onClickScript = qq^get_options('$fieldname',['$elements'],'$opt_type',['$keys'],['$labels'],['$opt_header'],$propagate)^;

    if ( $fieldtype eq 'text' ) {
        return textfield(
            -name     => $fieldname,
            -id       => $fieldname,
            -value    => $default,
            -size     => 15,
            -readonly => 1,
            -onClick  => $onClickScript
        ) . "\n$flag\n";

    }
    elsif ( $fieldtype =~ /hidden|button/i ) {
        my $onClick = qq^onClick="this.value='Modify $fieldname';$onClickScript"^;

        #    my $hidden = hidden(-name=>$fieldname, -id=>$fieldname, -value=>$default);
        my $hidden = "<input type='hidden' id='$fieldname' value='$default'>";
        return button(
            -name    => "$fieldname button",
            -value   => "Set $fieldname",
            -onClick => "this.value='Modify $fieldname';$onClickScript"
        ) . "\n$hidden\n$flag\n";
    }
    else {
        return 'Invalid input type.';
    }
}

sub get_parameters {

    my %hash;
    foreach ( param() ) {
        unless ( $_ =~ /Database|Value|Method|User|Name|Time|url|Session|Project/i ) {
            $hash{$_} = join( ',', param($_) );
        }
    }
    return \%hash;
}

#######################
# This subroutine creates a html link to a file
#
# Usage:
#	my $link = RGTools::RGWeb::create_file_link( -file => $file_full_name, -label => 'Download Template' );
#
# Return:
#	HTML
#######################
sub create_file_link {
#######################
    my %args  = filter_input( \@_, -args => 'file,label', -mandatory => 'file' );
    my $file  = $args{-file};
    my $label = $args{-label};
    my $path = $args{-path};
    my $debug = $args{-debug};
    my $link;

    $file =~ /\/([^\/]*)$/;
    my $local_name = $1;
    my $link_file  = $path . "/$local_name";
    my $command    = "cp $file $link_file";
    if ($debug) { Message("$command") }
    my ( $stdout, $stderr ) = try_system_command( -command => $command );
    if ( -f $link_file ) {
        my $URL_path;
        if   ( $link_file =~ m|\/(dynamic\/.*)| ) { $URL_path = $1; }
        else                                      { $URL_path = $link_file; }

        $URL_path = URI::Escape::uri_unescape($URL_path);
        $URL_path =~ s /\s/\%20/g;
        if ( !$label ) { $label = $local_name }
        $link = "<a href='/$URL_path'><b>$label</b></a>";
    }

    return $link;
}

return 1;

