################################################################
# A MySQL Table class

=head1 NAME

MySQLdb - A wrapper for the DBI Perl interface to a MySQL database.

=head1 DESCRIPTION

This module abstracts the DBI routines to facilitate high-level manipulation of MySQL data.

=head1 SYNOPSIS

  use Imported::MySQLdb;

  $db = Imported::MySQLdb->new();

=cut

package Imported::MySQL_Table;

use Imported::MySQL_Field;
use Imported::MySQL_Tools;
use Imported::PerlHelper;
use strict;
use POSIX qw();
use Carp;
use vars '$AUTOLOAD';

sub new {

  my ($class) = $_[0];
  
  my $self = {
	  _name       => $_[1],
	  _fields     => (),
	  };
  
  bless $self,$class;

  return $self;

}

sub AddField {

  my $self = shift;
  my $hash = shift;
  
  my $field = Imported::MySQL_Field->new($hash,$self);
  push(@{$self->{_fields}},$field);

}

{
  my %_attrs =
    ( 
      _name     => 'read/write',
      _fields   => 'read/write',
    );
  sub _accessible {
    my ($self,$attr,$mode) = @_;
    $_attrs{$attr} =~ /$mode/;
  }
}

################################################################
# A Field Iterator
#

sub ForEachField {

  my $self = shift;
  my $idxfield;
  nextfield($self);
  sub nextfield
  {
    my $self = shift;
    if(! defined $idxfield) {
      $idxfield = 0;
    } elsif ( $idxfield eq $#{$self->{_fields}}) {
      $idxfield = -1;
      return 0;
    } else {
      $idxfield ++;
    }
    return ${$self->{_fields}}[$idxfield];
  }
}

sub GetField {
  my $self = shift;
  my $fieldname = shift;
  my $field = undef;
  foreach $field (@{$self->{_fields}}) {
    if ($field->get_name eq $fieldname || 
	$field->get_alias eq $fieldname) {
      return $field;
    }
  }
  return undef;
}

sub Print {

  my $self = shift;
  my $nfields = @{$self->{_fields}};
  print sprintf("::: TABLE: %s ::: (%d) :::\n",$self->{_name},$nfields);
  my $field;
  while ($field = $self->ForEachField) {
    $field->Print();
  }
  print "\n";

}

sub Imported::MySQL_Table::DESTROY {

  my $self = shift;
#  print "Closing table ".$self->{_name}."\n";

}

sub Imported::MySQL_Table::AUTOLOAD {

  no strict "refs";
  my ($self,$newval) = @_;

  if ($AUTOLOAD =~ /.*::get(_\w+)/ && ($self->_accessible($1,'read'))) {
    my $attr_name = $1;
    *{$AUTOLOAD} = sub { return $_[0]->{$attr_name} };
    return $self->{$attr_name}
  }
  if ($AUTOLOAD =~ /.*::set(_\w+)/ && $self->_accessible($1,'write')) {
    my $attr_name = $1;
    *{$AUTOLOAD} = sub { $_[0]->{$attr_name} = $_[1]; return };
    $self->{$1} = $newval;
    return $self->{$1}
  }
  carp "No such method: $AUTOLOAD";
}

1;
