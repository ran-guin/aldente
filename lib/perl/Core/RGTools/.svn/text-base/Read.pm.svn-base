###############################################################
#
#  Read
#
# Read object that represents a record in the Clone_Sequence table.
#
###############################################################
package Read;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Read.pm - Read object that represents a record in the Clone_Sequence table.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Read object that represents a record in the Clone_Sequence table.<BR>

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
use strict;
use Storable qw(freeze thaw);
use Data::Dumper;
use CGI qw(:standard);

##############################
# custom_modules_ref         #
##############################
use RGTools::Views;

##############################
# global_vars                #
##############################
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

#######
sub new {
#######
    #
    #Constructor for the Read object
    #
    my $this = shift;
    my %args = @_;

    my ($class) = ref($this) || $this;
    my ($self) = {};

    $self->{trace_name} = $args{trace_name} || '';    #Name of the trace file[String]
    $self->{trace_file} = $args{trace_file} || '';    #Location of the trace file [String]
    $self->{sequence}
        = ( defined $args{sequence} )
        ? $args{sequence}
        : '';                                         #The sequence of the clone [String]
    $self->{quality_scores} = $args{quality_scores};  #Reference to an array of quality scores [ArrayRef]
    $self->{sequence_length}
        = ( defined $args{sequence_length} )
        ? $args{sequence_length}
        : 0;                                          #The length of sequence [String]
    $self->{quality_length}
        = ( defined $args{quality_length} )
        ? $args{quality_length}
        : -2;                                         #Quality length [Int]
    $self->{quality_left}
        = ( defined $args{quality_left} )
        ? $args{quality_left}
        : -2;                                         #Quality left [Int]
    $self->{vector_left}
        = ( defined $args{vector_left} )
        ? $args{vector_left}
        : -2;                                         #Vector left [Int]
    $self->{vector_right}
        = ( defined $args{vector_right} )
        ? $args{vector_right}
        : -2;                                         #Vector right [Int]
    $self->{warnings} = $args{warnings};              #Warnings [String]
    $self->{errors}   = $args{errors} || '';          #Errors [String]
    $self->{comments} = $args{comments};              #Comments [String]

    bless $self, $class;

    $self->{Q20} = $self->_get_Q20();

    return $self;
}

##############################
# public_methods             #
##############################

########
sub print {
########
    #
    #Prints the content of the Read object
    #
    my $self = shift;

    print '-' x 50 . "\n";
    print ">Name: $self->{name}\n";
    print '-' x 50 . "\n";
    print ">Trace File: $self->{trace_file}\n";
    print ">Sequence: $self->{sequence}\n";
    print ">Quality scores: " . join( " ", @{ $self->{quality_scores} } ) . "\n";
    print ">Sequence Length: $self->{sequence_length}\n";
    print ">Quality Length: $self->{quality_length}\n";
    print ">Quality Left: $self->{quality_left}\n";
    print ">Vector Left: $self->{vector_left}\n";
    print ">Vector Right: $self->{vector_right}\n";
    print ">Warnings: $self->{warnings}\n";
    print ">Errors: $self->{errors}\n";
    print ">Comments: $self->{comments}\n";
    print ">Q20: $self->{Q20}\n";
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################

##############
#sub draw_map {
##############
#my $self = shift;

##### make 60 x 40 map... ####
#&RGTools::Views::Draw_Map($colour_file,undef,undef,\@matrix,5,1); ## 5 pixels/well, last parameter for border
#}

##############
sub _get_Q20 {
##############
    my $self = shift;

    my $phred_thresold = shift || 20;

    my $count = 0;
    foreach my $score ( @{ $self->{quality_scores} } ) {
        if ( $score >= $phred_thresold ) { $count++ }
    }

    return $count;
}

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

None.

=head1 FUTURE IMPROVEMENTS <UPLINK>

Add more attributes to the object.

=head1 AUTHORS <UPLINK>

Ran Guin

Andy Chan

=head1 CREATED <UPLINK>

2003-07-14

=head1 REVISION <UPLINK>

$Id: Read.pm,v 1.11 2004/08/12 00:11:41 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
