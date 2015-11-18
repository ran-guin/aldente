################################################################################
#
# Progress.pm
#
# Progress Tracker (used simply for generating progress feedback to HTML pages during slow loads)
#
################################################################################
# $Id: HTML.pm,v 1.5 2004/11/30 01:43:42 rguin Exp $
################################################################################
package SDB::Progress;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Progress.pm - Simple progress tracking feedback tool

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
HTML: Misc HTML specific tools <BR>

=cut

##############################
# superclasses               #
##############################

##############################
# standard_modules_ref       #
##############################

use Carp;
use Data::Dumper;
use strict;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use RGTools::Conversion;

use CGI qw(:standard);

use SDB::CustomSettings;
use SDB::HTML;

# use SDB::DBIO;
# use SDB::DB_Form_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################

##############################
# main_header                #
##############################
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
# Usage:
#
# my $Progress = new SDB::Progress("Uploading File", -target=>$count);
#
# foreach my $line (1..$count) {
#    ## slow logic...
#    $Progress->update($line);
# }
#
##########
sub new {
##########
    my $this   = shift;
    my %args   = &filter_input( \@_, -args => 'title' );    ## allow input options
    my $target = $args{-target} || 100;
    my $title  = $args{-title} || "Tracking Progress";
    my $height = $args{-height} || 10;

    my $factor = 100.0 / $target * 1.0;

    my ($class) = ref($this) || $this;
    my ($self) = {};

    my $base_dir = "/$Configs{URL_dir_name}";               ## "eg '/SDB_alpha'

    $self->{target}  = $target;
    $self->{updated} = 0;
    $self->{height}  = $height;
    $self->{title}   = $title;
    $self->{factor}  = $factor;

    $self->{start}          = timestamp();
    $self->{progress_image} = "$base_dir/images/colour/green.png";
    $self->{line_img}       = "$base_dir/images/colour/black.png";
    $self->{blank_img}      = "$base_dir/images/colour/transparent.png";

    my $l_height = 4;    ## width of line in initialize header legend
    $self->{line_width} = $l_height;

    bless $self, $class;

    $self->{auto_buffer} = $|;    ## keep track of existing auto_buffer state so that it can be reverted after progress bar completes

    $| = 1;                       ## turn on real time web browser auto-buffering (to ensure HTML print statements are flushed directly to the browser for real time feedback)

    $self->_initialize();
    return $self;
}

#
# Usage: (see constructor)
#
# Initiate progress bar (in constructor) by generating a line with a 0 - 100% scale
# (initially set percentage to 1 simply to show progress bar as starting...)
#
# Note: This method prints the html code in-line since the purpose is to display this in real time.
# If in-line code also prints before completion of the progress bar, then something may need to be revised.
#
# This may be fixed by using a class for the progress bar with an absolute position that lies on top of the page.
# (though it should be done in such a way that it does not block real time messages if they do appear)
#
# Return: 1
######################
sub _initialize {
######################
    my $self = shift;

    my $height = $self->{height} || $self->{line_width};
    my $title  = $self->{title};

    my $i_height = $self->{line_width};
    my $rand     = rand(10000);
    $self->{id} = $rand;

    $self->{close} = &hspace(20) . "<button onclick=\"HideElement('$self->{id}');\"> Close Progress Bar </button>\n";

    print "\n<!-- " . ( "-" x 1024 ) . " -->\n";
    print "<div id='$self->{id}'>";
    if ($title) {
        print "\n<HR style='width:4px'>\n";
        print "<div class='progress-bar-title'><B>$title ... thanks for your patience...</B></div>\n";
    }
    
    print $self->img_line( $self->{line_img}, -height => $i_height, -width => 100, -inline => 1 );

    my $style = 'padding:2px; margin:0px';
    print "<Table width=100% padding=0 margin=0 style='$style'><TR style='$style'><TD align='left' style='$style' width=30%>0%</TD><TD align=center width=40% style='$style' >50%</TD><TD align=right width=30% style='$style' >100%</TD></TR></Table>";

    print $self->img_line( $self->{line_img}, -height => $i_height, -width => 100, -inline => 1 );

    ## print first 1% to show it has started... ##
    print $self->img_line( $self->{progress_image}, -height => $height, -width => 1, -inline => 1 );
    $self->{displayed_percent} = 1;

    return 1;
}

#
# Usage: (see constructor)
#
# Update progress bar to specified completion percentage
# (If this value hits 100%, the completion method will automatically be called)
#
# Note: This method prints the html code in-line since the purpose is to display this in real time.
# If in-line code also prints before completion of the progress bar, then something may need to be revised.
#
# This may be fixed by using a class for the progress bar with an absolute position that lies on top of the page.
# (though it should be done in such a way that it does not block real time messages if they do appear)
#
# Return: 1
######################
sub update {
######################
    my $self             = shift;
    my $current_progress = shift;
    my $msg              = shift;    ## optional message (this would only be included if printed to a localized css object that could update a message without interrupting the printing of the progress bar).

    my $target            = $self->{target};
    my $displayed_percent = $self->{displayed_percent};

    if ($self->{end}) { return 1 }   ### already completed ... 

    my $height = $self->{height} || $self->{line_width};

    my $total_width = 0;
    while ( $current_progress <= $target && 100 * $current_progress / $target > $displayed_percent ) {
        $total_width ++;
        $displayed_percent++;
    }
    
    print $self->img_line( $self->{progress_image}, -height => $height, -width => $total_width, -inline => 1 );

    $self->{displayed_percent} = $displayed_percent;

    #if    ( $displayed_percent >= 100 )            { $self->complete($displayed_percent) }
    if ( $current_progress >= $self->{target} ) { $self->complete($displayed_percent) }

    return 1;
}

#
# Wrapper to draw basic line using given image (indicating colour)
#
################
sub img_line {
################
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'img_file' );
    my $img_file = $args{-img_file};
    my $height   = $args{-height};
    my $width    = $args{-width};    # in % of full span #
    my $inline   = $args{-inline};

    my $class = 'progress-bar';
    if ($inline) { $class = "inline-" . $class}

    my $img = "<IMG SRC='$img_file' class='$class' height='${height}px' width='${width}%' style='width:${width}%'; height:${height}px' />";

    return $img;
}

#
# Close progress bar and display total execution time
#
# Return: 1
################
sub complete {
################
    my $self              = shift;
    my $displayed_percent = shift;

    print "\n<P>Process Completed ";

    $self->{end} = timestamp();
    my $time = $self->{end} - $self->{start};

    print "$displayed_percent % : [ $time seconds ]\n";
    print &hspace(20) . $self->{close} . "<HR></div>\n";

    $| = $self->{auto_buffer};    ## turn automatic buffering back to default

    return 1;
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

2004-11-29

=head1 REVISION <UPLINK>

$Id: HTML.pm,v 1.5 2004/11/30 01:43:42 rguin Exp $ (Release: $Name:  $)

=cut

1;
