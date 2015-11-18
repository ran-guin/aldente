###################################################################################################################################
#
# Wrapper for objects for standard <class>_Views method.
#
#
###################################################################################################################################
package LampLite::Views;

use strict;
use CGI qw(:standard);

use RGTools::RGIO;

###########
sub dbc {
###########
    my $self = shift;
    
    return $self->{dbc};
}

#
#####################
sub new {
#####################
    my $this   = shift;
    my %args   = &filter_input( \@_ );
    my $models = $args{-models} || $args{-model};
    my $dbc    = $args{-dbc};

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ( ref $models eq 'ARRAY' ) {
        ## load models if supplied ... eg   new Object_Views( -dbc=> $dbc, -models => [$object]);
        foreach my $model (@$models) {
            my $type = ref $model;
            if ( $type =~ /(\w+)$/ ) { $type = $1 }    ## convert from 'LampLite::System' to 'System'
            $self->{$type} = $model;
        }
    }
    elsif ( ref $models eq 'HASH' ) {
        ## load models if supplied ... eg   new Object_Views( -dbc=> $dbc, -models => [$object]);
        foreach my $model ( keys %{$models} ) {
            my $type = $model;
            if ( $type =~ /(\w+)$/ ) { $type = $1 }    ## convert from 'LampLite::System' to 'System'
            $self->{$type} = $models->{$model};
        }
    }

    if ($dbc) { $self->{dbc} = $dbc }
    return $self;
}

#
# Simple accessor to Model class
############
sub Model {
############
     my %args = filter_input(\@_, -args=>'class', -self=>'LampLite::Views');
    my $class = $args{-class};  ## optional if view accessing model of different type
    my $self = $args{-self};

    my $dbc = $args{-dbc} || $self->{dbc};
    my $id = $args{-id};
    
    if (!$class) {  $id ||= $self->{id} }    ## include loaded id if applicable

    if (! ref $self) {
        ## scalar only provided ##
        $self = $self->new(-dbc=>$dbc, -id=>$id);
    }
    my $self_class ||= ref $self;
    $self_class =~s/(\b|\_)Views$//;
    
    if ($class) {
        if ( $class !~ /::/ ) {
            my $current = $self_class;
            $current =~ s/::(.+)/::$class/;
            $class = $current;
        }

        if (!$self->{"$class.Model"} ) {
            my $ok = eval "require $class"; 
            if ($ok) { 
                my $model = $class->new(-dbc=>$dbc, -id=>$id);
                $self->{"$class.Model"} =  $model;
             }
            else {
                $dbc->warning("$class class not found");
            }
        }
        
 
        return $self->{"$class.Model"};
    }
    else {
        my $base_class = $self_class;
        if (! $base_class || $base_class =~/::$/) { $base_class .= 'Model' }
        ## standard usage ... ##
        if (! $self->{Model}) {
            my $ok = eval "require $base_class"; 
            if ($ok) { 
                my $model = $base_class->new(-dbc=>$dbc, -id=>$id);
                $self->{Model} = $model;
            }
            else {
                $dbc->warning("$base_class class not found");
            }
        }
        return $self->{Model};
    }
}

###########
sub View {
###########
    my $self = shift;
    my %args = filter_input(\@_, -args=>'class');
    my $class = $args{-class};
    my $dbc   = $args{-dbc} || $self->{dbc};

    my $View;
    
    if (!$class) { 
        if (ref $self) { return $self }
        else {
            $View = $self->new(-dbc=>$dbc);
        }
    }
    else {
        if (my $self_class = ref $self) {
            my $scope = 'LampLite';
            if ($self_class =~/(.*)::(.*)/) {
                $scope = $1;
            }
            $class = $scope . '::'  . $class;
        }
        my $view_class = $class . '_Views';
        $View = $view_class->new(-dbc=>$dbc);

    }
    
    return $View;
    
}

#
#
# Simple accessor to return the name of the App for the current view if applicable.
#
# This enables lower level methods to specify cgi_Apps at a higher level.
# (eg LampLite module may include a form which runs a higher level App (if that is the original class level))
#
# eg ( $q->hidden(-name=>'cgi_application', -value => $self->App ) )
###########
sub App {
###########
    my $self = shift;
    
    my $class = ref $self || $self;
    $class =~s/(\b|\_)Views$/$1App/;
    
    return $class;
}

1
