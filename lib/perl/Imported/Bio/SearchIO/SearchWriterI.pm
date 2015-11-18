#-----------------------------------------------------------------
# $Id: SearchWriterI.pm,v 1.5 2002/02/26 07:33:19 jason Exp $
#
# BioPerl module Bio::SearchIO::SearchWriterI
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

=head1 NAME

Bio::SearchIO::SearchWriterI - Interface for outputting parsed Search results

=head1 SYNOPSIS

Bio::SearchIO::SearchWriterI objects cannot be instantiated since this
module defines a pure interface.

Given an object that implements the Bio::SearchIO::SearchWriterI interface,
you can do the following things with it:

    print $writer->to_string( $result_obj, @args );

=head1 DESCRIPTION

This module defines abstract methods that all subclasses must implement
to be used for outputting results from B<Bio::Search::Result::ResultI>
objects.

=head1 AUTHOR

Steve Chervitz E<lt>sac@bioperl.orgE<gt>

=head1 DISCLAIMER

This software is provided "as is" without warranty of any kind.

=head1 APPENDIX

The rest of the documentation details each of the object methods.

=cut

package Bio::SearchIO::SearchWriterI;

use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

=head2 to_string

 Purpose   : Produces data for each Search::Result::ResultI in a string.
           : This is an abstract method. For some useful implementations,
           : see ResultTableWriter.pm, HitTableWriter.pm, 
           : and HSPTableWriter.pm.
 Usage     : print $writer->to_string( $result_obj, @args );
 Argument  : $result_obj = A Bio::Search::Result::ResultI object
           : @args = any additional arguments used by your implementation.
 Returns   : String containing data for each search Result or any of its
           : sub-objects (Hits and HSPs).
 Throws    : n/a

=cut

sub to_string {
    my ($self, $result, @args) = @_;
    $self->throw_not_implemented;
}


1;


