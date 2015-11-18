package RGTools::Base_App;

##################################################################################################################################
# This is the standard package to include with alDente modules that wish to use MVC design protocol from CGI_Application package #
# (Recommended for ongoing module development and refactoring)
#
#####################################

use CGI_App::Application;
use base 'CGI::Application';

use RGTools::RGIO;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes( {} );

    my $dbc = $self->param('dbc');

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

###########
sub dbc {
###########
    my $self = shift;

    $self->{dbc} ||= $self->param('dbc');
    return $self->{dbc};
}

#
# Quick accessor to View module
#
#
###########
sub View {
###########
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'id,class' );
    my $id    = $args{-id};
    my $class = $args{-class} || ref $self;
    my $dbc   = $args{ -dbc } || $self->dbc();

    if   ( $class =~ s/(\b|\_)App$/$1Views/ ) { }
    else                                      { $class .= '_Views' }

    my $ok = eval "require $class";
    $args{ -dbc } = $dbc;

    if ( !$ok && $dbc ) { $dbc->warning("Could not load $class class") }

    my $View = $class->new(%args);
    $View->{dbc} = $dbc;

    return $View;
}

#
# Quick accessor to View module
#
#
###########
sub Model {
###########
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $id    = $args{-id};
    my $class = $args{-class} || ref $self;
 
    my %pass_args  = @_;

    my $dbc = $self->dbc();

    $class =~ s/(\b|_)App$//;
    if ( !$class || $class =~ /::$/ ) { $class .= 'Model' }
    elsif ( $class !~ /::/ ) {
        my $current = ref $self;
        $current =~ s/::(.+)/::$class/;
        $class = $current;
    }

    eval "require $class";

    my $Model = $class->new( -dbc => $dbc, -id => $id, %pass_args );

    $Model->{dbc} = $dbc;
    return $Model;

}

#############
sub rm_link {
#############
    my $self = shift;
    my $rm   = shift || $self->get_current_runmode();
    my $link = '&cgi_application=' . ref($self);
    $link .= "&rm=$rm";

    return $link;
}

###########################
#
# Method to allow CGI Application methods to be called as functions.
#
# This allows URL parameter retrieval to work in both cases:
#
# <snip>
# 1 - eg. my $webapp = alDente::Goal->new(PARAMS=>{dbc=>$dbc});  $webapp->show_Progress();
#   # self is a blessed CGI::Application module (ref values vary)
#   # this uses $webapp->query->param()
#
# 2 - eg. alDente::Goal::show_Progress(-dbc=>$dbc);
#   # self is non-blessed
#   # this uses CGI::param()
# </snip>
#
# Note: 'use CGI' will break code since it overrides CGI_App/Application param() method #
################
sub url_param {
################
    my $self = shift;    ##
    my @args = @_;       ## input parameters

    my $type = ref($self);

    if ( ref($self) !~ /::/ ) {
        ## ($self is non-blessed - eg as function call) ##
        eval {"require CGI qw(:standard);"};
        return CGI::param(@args);
    }
    else {
        ## defined CGI Application of some type ##
        return $self->query->param(@args);

    }
}

###################
# This retrieves field value for all the objects for a given field in the form
#
# Example:
#  &get_cell_data(-name => 'ATT2341', -object_ids => \@object_ids)
#
# Options:
#   -name => .. (The field name)
#   -object_ids => ..  (IDs of the objects for the field)
#
##########################
sub get_cell_data {
########################
    my $self       = shift;
    my $q          = $self->query();
    my %args       = filter_input( \@_, -args => 'name,object_ids' );
    my $name       = $args{-name};
    my $object_ids = $args{-object_ids};

    my @field_values;
    my @field_choice_values;

    my $index = 0;
    for my $id (@$object_ids) {
        $id =~ s/\'//g;
        $field_values[$index]        = $q->param("$name-$id") || $q->param("$name.$id");  ## phase out second option ... 
        $field_choice_values[$index] = $q->param("$name-$id Choice") || $q->param("$name.$id Choice");  ## phase out completely ... 
        $index++;
    }

    if ( scalar(@field_values) > 0 && grep /./, @field_values ) {
        return @field_values;
    }
    elsif ( scalar(@field_choice_values) > 0 ) {
        ## phase out .. ##
        return @field_choice_values;
    }

    return;
}

return 1;
