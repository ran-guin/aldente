# $Id: newick.pm,v 1.7.2.1 2002/04/21 14:30:22 jason Exp $
#
# BioPerl module for Bio::TreeIO::newick
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::TreeIO::newick - TreeIO implementation for parsing 
    Newick/New Hampshire/PHYLIP format.

=head1 SYNOPSIS

  # do not use this module directly
  use Bio::TreeIO;
  my $treeio = new Bio::TreeIO(-format => 'newick', -file => 'tree.dnd');
  my $tree = $treeio->next_tree;

=head1 DESCRIPTION

This module handles parsing and writing of Newick/PHYLIP/New Hampshire format.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to the
Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
email or the web:

  bioperl-bugs@bioperl.org
  http://bioperl.org/bioperl-bugs/

=head1 AUTHOR - Jason Stajich

Email jason@bioperl.org

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::TreeIO::newick;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::TreeIO;
use Bio::Event::EventGeneratorI;
#use XML::Handler::Subs;


@ISA = qw(Bio::TreeIO );

=head2 next_tree

 Title   : next_tree
 Usage   : my $tree = $treeio->next_tree
 Function: Gets the next tree in the stream
 Returns : Bio::Tree::TreeI
 Args    :


=cut

sub next_tree{
   my ($self,@args) = @_;
   local $/ = ";\n";
   return unless $_ = $self->_readline;
   s/\s+//g;
   $self->debug("entry is $_\n");
#   my $empty = chr(20);
 
   # replace empty labels with a tag
#   s/\(,/\($empty,/ig;
#   s/,,/,$empty,/ig;
#   s/,,/,/ig;
#   s/,\)/,$empty\)/ig;
#   s/\"/\'/ig;

   my $chars = '';
   $self->_eventHandler->start_document;
   my $lastevent = '';
   foreach my $ch ( split(//,$_) ) {
       if( $ch eq ';' ) { 	   
	   return $self->_eventHandler->end_document;
       } elsif( $ch eq '(' ) {
	   $chars = '';
	   $self->_eventHandler->start_element( {'Name' => 'tree'} );
	   $lastevent = $ch;
       } elsif($ch eq ')' ) {
	   if( $chars ) {
	       if( $lastevent eq ':' ) {
		   $self->_eventHandler->start_element( { 'Name' => 'branch_length'});
		   $self->_eventHandler->characters($chars);
		   $self->_eventHandler->end_element( {'Name' => 'branch_length'});
	       } else { 
		   $self->debug($chars."\n");
		   $self->_eventHandler->start_element( { 'Name' => 'node' } );
		   $self->_eventHandler->start_element( { 'Name' => 'id' } );
		   $self->_eventHandler->characters($chars);
		   $self->_eventHandler->end_element( { 'Name' => 'id' } );
	       }	   	   
	       $self->_eventHandler->end_element( {'Name' => 'node'} );
	   }
	   $self->_eventHandler->end_element( {'Name' => 'tree'} );
	   $chars = '';
	   $lastevent = $ch;
       } elsif ( $ch eq ',' ) {
	   if( $chars ) {
	       if( $lastevent eq ':' ) {
		   $self->_eventHandler->start_element( { 'Name' => 'branch_length'});
		   $self->_eventHandler->characters($chars);
		   $self->_eventHandler->end_element( {'Name' => 'branch_length'});
	       } else { 
		   $self->_eventHandler->start_element( { 'Name' => 'node' } );
		   $self->_eventHandler->start_element( { 'Name' => 'id' } );
		   $self->_eventHandler->characters($chars);
		   $self->_eventHandler->end_element( { 'Name' => 'id' } );
	       }
	       $self->_eventHandler->end_element( {'Name' => 'node'} );
	   }
	   $chars = '';
	   $lastevent = $ch;
       } elsif( $ch eq ':' ) {
	   $self->_eventHandler->start_element( { 'Name' => 'node' } );
	   $self->_eventHandler->start_element( { 'Name' => 'id' } );	   
	   $self->_eventHandler->characters($chars);
	   $self->_eventHandler->end_element( { 'Name' => 'id' } );	   
	   $chars = '';
	   $lastevent = $ch;
       } else { 	   
	   $chars .= $ch;
       } 
   }
   return undef;
}

=head2 write_tree

 Title   : write_tree
 Usage   : $treeio->write_tree($tree);
 Function: Write a tree out to data stream in newick/phylip format
 Returns : none
 Args    : Bio::Tree::TreeI object

=cut

sub write_tree{
   my ($self,$tree) = @_;      
   my @data = _write_tree_Helper($tree->get_root_node);
   if($data[-1] !~ /\)$/ ) {
       $data[0] = "(".$data[0];
       $data[-1] .= ")";
   }
   $self->_print(join(',', @data), ";\n");   
   return;
}

sub _write_tree_Helper {
    my ($node) = @_;
    return () if (!defined $node);

    my @data;
    
    foreach my $n ( $node->each_Descendent() ) {
	push @data, _write_tree_Helper($n);
    }

    if( @data > 1 && 
	$node->branch_length) {
	$data[0] = "(" . $data[0];
	$data[-1] .= ")";
	$data[-1] .= ":". $node->branch_length;
    } else {
	if( defined $node->id || defined $node->branch_length ) { 
	    push @data, sprintf("%s%s",
				defined $node->id ? $node->id : '', 
				defined $node->branch_length ? ":" .
				$node->branch_length : '');
	}
    }
    return @data;
}


1;
