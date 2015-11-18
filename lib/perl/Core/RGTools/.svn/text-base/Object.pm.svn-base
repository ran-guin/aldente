##############################################################################################################
# Object.pm
#
# This object is the superclass of objects, providing a variety of useful functionality that can be used by other objects
#
##############################################################################################################
# $Id: Object.pm,v 1.21 2004/12/09 17:46:59 rguin Exp $
##############################################################################################################
package Object;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Object.pm - This object is the superclass of objects, providing a variety of useful functionality that can be used by other objects

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This object is the superclass of objects, providing a variety of useful functionality that can be used by other objects<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use Data::Dumper;
use Storable;

use YAML qw(thaw freeze);

#use AutoLoader;
use Carp;

##############################
# custom_modules_ref         #
##############################
#BEGIN { *AUTOLOAD = &AutoLoader::AUTOLOAD }
use RGTools::RGIO;
use strict;

##############################
# global_vars                #
##############################
use vars qw($AUTOLOAD);
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

#
# ### Obtaining feedback from the operations
# $dbo->error();       # Returns the latest error
# $dbo->errors();      # Returns the reference to a list of all errors that have occured since the DBIO object was created
# $dbo->warning();     # Returns the latest warning
# $dbo->warnings();    # Returns the reference to a list of all errors that have occured since the DBIO object was created
# $dbo->success();     # Returns whether the last operation was success or fail
#
##################
sub new {
##################
    #
    #Constructor of the object
    #
    my $this = shift;
    my $class = ref($this) || $this;

    my %args = @_;

    my $frozen  = $args{-frozen}  || 0;    ## Reference to frozen object [Object]
    my $encoded = $args{-encoded} || 0;    ## Flag indicate whether the frozen object was encoded [Int]

    my $self;
    if ($frozen) {
        $self = RGTools::RGIO::Safe_Thaw(
            -name    => $frozen,
            -thaw    => 1,
            -encoded => $encoded
        );
    }
    else {
        $self = {};
    }
    $self->{success}   = 1;     # A flag to track if a step fails or succeeds
    $self->{errors}    = [];    # An array of errors (if any) that have occured [ArrayRef]
    $self->{warnings}  = [];    # A list of warnings (if any) that have occured [ArrayRef]
    $self->{messages}  = [];    # A list of messages (if any) that have occured [ArrayRef]
    $self->{messaging} = 0;     # A flag to indicate if messages are dumped directly

    bless $self, $class;
    return $self;
}

##############################
# public_methods             #
##############################

##############
sub AUTOLOADxx {
##############
    no strict "refs";
    my ( $self, $newval ) = @_;
    my $sub = $AUTOLOAD;

    ( my $constname = $sub ) =~ s/.*:://;

    if ( $constname =~ /get_([_\w]+)/ ) {
        my $field = $1;
        if ( defined $self->{$field} ) {
            ### Attribute retrieval subroutine ##
            *{$sub} = sub {
                my $self = shift;
                return $self->{$field};
            };
            goto &$sub;
        }
        else {
            print "** $field not defined attribute.\n";
            return;
        }
    }
    elsif ( $constname =~ /set_([_\w]+)/ ) {
        my $field = $1;
        if ( defined $self->{$field} && defined $newval ) {
            ### Attribute setting subroutine ##
            *{$sub} = sub {
                my ( $self, $newval ) = @_;
                $self->{$field} = $newval;
                return 1;
            };
            goto &$sub;
        }
        else {
            ### Attribute setting subroutine ##
            *{$sub} = sub {
                my ( $self, $newval ) = @_;
                $self->{$field} = $newval;
                return 1;
            };
            goto &$sub;
        }
    }
    else {
        carp "No such method: $constname";
        return;
    }
}

##################
sub clone {
##################
    #
    # Clone an object
    #   Returns a clone of the original object [Object]
    #
    my $self = shift;

    return Storable::dclone($self);
}

##################
sub freeze {
##################
    #
    #Freeze an object
    #Returns the frozen object
    #
    my $self = shift;
    my %args = @_;

    my $encode = $args{-encode} || 0;    ## Flag indicate whether to also encode the object

    my $dbh = '';
    $dbh = $self->{dbh} if ( $self->{dbh} );
    $self->{dbh} = '' if ( $self->{dbh} );
    require MIME::Base32;
    my $retval = $encode ? MIME::Base32::encode( YAML::freeze($self), "" ) : YAML::freeze($self);
    $self->{dbh} = $dbh if ($dbh);
    return $retval;

}

############################################################
# Get or set the latest error. Also add the error to the list of errors
# RETURN: The latest error
############################################################
sub error {
    my $self   = shift;
    my $value  = shift;             ## Error to be added [String]
    my %args   = @_;
    my $ignore = $args{-ignore};    ## option to ignore error (do not set success to 0)

    if ($value) {
        $value = caller() . ": $value";
        push( @{ $self->{errors} }, $value );
        unless ($ignore) {
            $self->{success} = 0;
        }                           # do not turn success off if error is ignored specifically
        return $value;
    }
    else {
        if ( $self->{errors} ) {
            my @errors = @{ $self->{errors} };
            return $errors[ $#errors - 1 ];
        }
        else {
            return '';
        }
    }
}

############################################################
# Get or set the errors
# RETURN: The errors occured (array ref)
############################################################
sub errors {
    my $self = shift;
    @_ ? ( $self->{errors} = $_[0] ) : $self->{errors};
}

#    if (@_) { ( $self->{errors} = $_[0] ); }
#
#    require MIME::Base32;
#    $encode
#      ? ( return MIME::Base32::encode( freeze($self), "" ) )
#      : ( return freeze($self) );
#}

############################################################
# Get or set the latest warning. Also add the error to the list of warnings
# RETURN: The latest warning
############################################################
sub warning {
    my $self  = shift;
    my $value = shift;    # Value to be set [String

    if ($value) {
        $value = caller() . ": $value";
        push( @{ $self->{warnings} }, $value );
        return $value;
    }
    else {
        if ( $self->{warnings} ) {
            my @warnings = @{ $self->{warnings} };
            return $warnings[ $#warnings - 1 ];
        }
        else {
            return '';
        }
    }
}

############################################################
# Get or set the warnings
# RETURN: The warnings occured (array ref)
############################################################
sub warnings {
    my $self = shift;
    @_ ? ( $self->{warnings} = $_[0] ) : $self->{warnings};
}

#################
sub clear_messages {
#################
    my $self = shift;

    $self->{messages} = [];
    return;
}

############################################################
# Get or set the messages
# RETURN: The message sent
############################################################
sub messages {
    my $self      = shift;
    my %args      = @_;
    my $format    = $args{'-format'} || 'text';
    my $priority  = $args{-priority} || 0;
    my $separator = "\n";
    my @messages;

    if    ( $format =~ /html/i ) { $separator = "<BR>" }
    elsif ( $format =~ /text/i ) { $separator = "\n" }

    my $i = 0;
    foreach my $message ( @{ $self->{messages} } ) {
        if ( $priority >= $self->{message_priority}->{ $i++ } ) {
            push( @messages, $message );
        }
    }
    return join "$separator", @messages;
}

############################################################
# Get or set the latest message. Also add the error to the list of messages
#
# Priority levels (optional) allow specification of priority (0 = always show ... 5 = very verbose)
#
# RETURN: The latest message
############################################################
sub message {
##############
    my $self     = shift;
    my $value    = shift;                                     # Value to be set [String
    my %args     = @_;
    my $no_print = $args{-no_print} || $args{-return_html};

    my $priority = $args{-priority} || 0;

    my $index = int( @{ $self->{messages} } );
    $self->{message_priority}->{$index} = $priority;

    my $returnval;

    #if ($self->{messaging} >= $priority) { &RGTools::RGIO::Call_Stack(-line_break=>"\n"); print "$self->{messaging} >= $priority\n" }
    if ( $self->{messaging} >= $priority && $value ) { $returnval = &RGTools::RGIO::Message( $value, -no_print => $no_print ) }

    if ($value) {
        $value = caller() . ": $value";
        push( @{ $self->{messages} }, $value );
        $returnval ||= $value;
    }
    else {
        if ( $self->{messages} ) {
            my @messages = @{ $self->{messages} };
            $returnval = $messages[ $#messages - 1 ];
        }
        else {
            $returnval = '';
        }
    }

    return $returnval;
}

############################################################
# Get or set whether the last operation was succcess/fail
# RETURN: Whether the last operation was success/fail [Bool]
############################################################
sub success {
############
    my $self = shift;
    @_ ? ( $self->{success} = $_[0] ) : $self->{success};
}

##############################
# public_functions           #
##############################

#####################################################
# Reset messaging priority level.
# Set to :
#    0 - default - prints only the most high priority messages
#
#    5 - print all (testing , debug) messages
#
######################
sub set_message_priority {
######################
    my $self     = shift;
    my $priority = shift;

    $self->{messaging} = $priority;
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

$Id: Object.pm,v 1.21 2004/12/09 17:46:59 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
