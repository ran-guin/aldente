# $Id: Allele.pm,v 1.6.2.1 2002/03/20 13:08:24 heikki Exp $
#
# BioPerl module for Bio::Variation::Allele
#
# Cared for by Heikki Lehvaslaiho <heikki@ebi.ac.uk>
#
# Copyright Heikki Lehvaslaiho
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::Variation::Allele - Sequence object with allele-specific attributes

=head1 SYNOPSIS

  $allele1 = Bio::Variation::Allele->new ( -seq => 'A',
                                           -id  => 'AC00001.1',
                                           -alphabet => 'dna',
                                           -is_reference => 1
                                         );

=head1 DESCRIPTION

List of alleles describe known sequence alternatives in a variable region.
Alleles are contained in Bio::Variation::VariantI complying objects.
See L<Bio::Variation::VariantI> for details.

Bio::Varation::Alleles are PrimarySeqI complying objects which can
contain database cross references as specified in
Bio::DBLinkContainerI interface, too.

A lot of the complexity with dealing with Allele objects are caused by
null alleles; Allele objects that have zero length sequence string.

In addition describing the allele by its sequence , it possible to
give describe repeat structure within the sequence. This done using
methods repeat_unit (e.g. 'ca') and repeat_count (e.g. 7).

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to the 
Bioperl mailing lists  Your participation is much appreciated.

  bioperl-l@bioperl.org                         - General discussion
  http://bio.perl.org/MailList.html             - About the mailing lists

=head2 Reporting Bugs

report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.  Bug reports can be submitted via
 email or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Heikki Lehvaslaiho

Email:  heikki@ebi.ac.uk
Address: 

     EMBL Outstation, European Bioinformatics Institute
     Wellcome Trust Genome Campus, Hinxton
     Cambs. CB10 1SD, United Kingdom 


=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...

package Bio::Variation::Allele;
my $VERSION=1.0;
use vars qw(@ISA);
use strict;

# Object preamble - inheritance

use Bio::PrimarySeq;
use Bio::DBLinkContainerI;

@ISA = qw( Bio::PrimarySeq Bio::DBLinkContainerI );

sub new {
    my($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my($is_reference, $repeat_unit, $repeat_count) =
	   $self->_rearrange([qw(IS_REFERENCE
				 REPEAT_UNIT
				 REPEAT_COUNT
				 )],
			     @args);

    $is_reference && $self->is_reference($is_reference);
    $repeat_unit && $self->repeat_unit($repeat_unit);
    $repeat_count && $self->repeat_count($repeat_count);

    return $self; # success - we hope!
}


=head2 is_reference

 Title   : is_reference
 Usage   : $obj->is_reference()
 Function: sets and returns boolean values. 
           Unset values return false.
 Example : $obj->is_reference()
 Returns : boolean
 Args    : optional true of false value


=cut


sub is_reference {
    my ($self,$value) = @_;
    if( defined $value) {
	$value ? ($value = 1) : ($value = 0);
	$self->{'is_reference'} = $value;
    }
    if( ! exists $self->{'is_reference'} ) {
	return 0;
    } 
    else {
	return $self->{'is_reference'};
    }
}


=head2 add_DBLink

 Title   : add_DBLink
 Usage   : $self->add_DBLink($ref)
 Function: adds a link object
 Example :
 Returns : 
 Args    :


=cut


sub add_DBLink{
   my ($self,$com) = @_;
   if( ! $com->isa('Bio::Annotation::DBLink') ) {
       $self->throw("Is not a link object but a  [$com]");
   }
   push(@{$self->{'link'}},$com);
}

=head2 each_DBLink

 Title   : each_DBLink
 Usage   : foreach $ref ( $self->each_DBlink() )
 Function: gets an array of DBlink of objects
 Example :
 Returns : 
 Args    :


=cut

sub each_DBLink{
   my ($self) = @_;   
   return @{$self->{'link'}}; 
}

=head2 repeat_unit

 Title   : repeat_unit
 Usage   : $obj->repeat_unit('ca');
 Function: 

            Sets and returns the sequence of the repeat_unit the
            allele is composed of.

 Example : 
 Returns : string
 Args    : string

=cut

sub repeat_unit {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'repeat_unit'} = $value;
    }
    if ($self->{'seq'} && $self->{'repeat_unit'} && $self->{'repeat_count'} ) {
	$self->warn("Repeats do not add up!") 
	    if ( $self->{'repeat_unit'} x $self->{'repeat_count'})  ne $self->{'seq'};
    }
    return $self->{'repeat_unit'};
}

=head2 repeat_count

 Title   : repeat_count
 Usage   : $obj->repeat_count();
 Function: 

            Sets and returns the number of repeat units in the allele.

 Example : 
 Returns : string
 Args    : string

=cut


sub repeat_count {
    my ($self,$value) = @_;
    if( defined $value) {
	if (  not $value =~ /^\d+$/ ) {
	    $self->throw("[$value] for repeat_count has to be a positive integer\n");
	} else {
	    $self->{'repeat_count'} = $value;
	}
    }
    if ($self->{'seq'} && $self->{'repeat_unit'} && $self->{'repeat_count'} ) {
	$self->warn("Repeats do not add up!") 
	    if ( $self->{'repeat_unit'} x $self->{'repeat_count'})  ne $self->{'seq'};
    }
    return $self->{'repeat_count'};
}

1;
