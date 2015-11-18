################################################################
# A MySQL Record class
#
# CVS: $Revision: 1.1 $
# Date: $Date: 2003/04/10 23:59:07 $
#
################################################################

=head1 NAME

MySQL_Record - A module modelling a MySQL Record object.

=head1 DESCRIPTION

A 'record' is considered to be the record residing in a table returned by a SELECT query. Such a record is not necessarily the same as a record in the database, because some of its fields may not have been returned by the query. Furthermore, if any processing during the SELECT are is done, such as COUNT, then the returned record does not have a direct equivalent in the database.

=head1 SYNOPSIS

Typically, the record object is called by a search object.

  use Imported::MySQLdb;
  my $db = Imported::MySQLdb->new();
  $db->Connect({'user'=>'viewer','server'=>'lims-dbm',
		'pass'=>'******','db'=>'sequence'});
  $s1 = $db->CreateSearch("s1");
  $s1->SetTable("Primer");
  $s1->Execute();
  while($s1->ForEachRecord()) {
    $record = $s1->GetRecord();
    $field = $record->GetField("Purity");
    print "Important field: ",$record->GetFieldValue("Purity"),"\n";
    print "Important field type: ",$field->get_type,"\n";
    $record->Print(); 

=head1 DESCRIPTION

This module assists the MySQL_Search module in modelling the data structre returned by a SELECT statement. Effectively, a MySQL_Record object is a collection of MySQL_Field objects. The MySQL_Record module has functionality to pull out and print fields and field values.

=head2 General Usage

The MySQL_Record module is not strictly meant to be used directly, although it can be useful for iterating through all the returned objects from a SELECT statement. For example, one may want to post-process a particular field in a SELECT record set. 

=head2 Design

The MySQL_Record object contains a list of MySQL_Field objects and information about how to print this particular record in HTML format.

=cut

package Imported::MySQL_Record;

use strict;
use Imported::MySQL_Tools;
use POSIX qw();
use Carp;
use vars '$AUTOLOAD';

=pod 

=head2 Initializer

The initializer of this module should never be called directly.

=cut 

sub new {
  
  my ($class) = $_[0];
  
  my $self = {
	      _search     => undef,
	      _fields     => undef,
	      _html       => undef,
	     };
  bless $self,$class;

  my $rec_ref = $_[1];
  if(defined $_[2]) {
    $self->{_search} = $_[2];
  }
  my $field_idx = 0;
  # Store the field value in the _fields entry.
  foreach my $fieldvalue (@{$rec_ref}) {
    my $field = $self->get_search->get_viewfields->[$field_idx]->{'field'};
    $field->set_value($fieldvalue);
    push(@{$self->{_fields}},$field);
    $field_idx++;
  } 
  return $self;
}

{
  my %_attrs =
    ( 
     _fields   => 'read/write',
     _search   => 'read/write',
     _html     => 'read/write',
    );
  sub _accessible {
    my ($self,$attr,$mode) = @_;
    $_attrs{$attr} =~ /$mode/;
  }
}

=pod 

=head2 Accessors

These functions retrieve fields or field values from the record object.

=over

=item GetFieldValue(name)

Fetch the value of a field named 'name' from the record. If a field has an alias, such as the kind specified by an AS construct in a SELECT statement, 'name' can also correspond to the alias of the field.

=back

=cut 

################################################################
# Fetch a field value by either name or alias
#
sub GetFieldValue {

  my $self = shift;
  my $name = shift;
  my $field;
  my $viewfield_idx=0;
  if (! defined $self->get_fields) {
    confess "I bet you got some bad SQL!";
  }
  foreach $field (@{$self->get_fields}) {
    if($field->get_name eq $name || 
       (defined $field->get_alias &&
	$field->get_alias eq $name)) {
      if(defined $field->get_value) {
	return $field->get_value;
      } else {
	return undef;
      }
    }
  }
  carp "The record field named [$name] does not exist in the search [",$self->get_search->get_name,"]";
  return undef;
}
#
################################################################

=pod

=over

=item GetField(name)

Fetch the field object named 'name' from the record. If a field has an alias, such as the kind specified by an AS construct in a SELECT statement, 'name' can also correspond to the alias of the field.

=back

=cut 

################################################################
# Fetch a field object by either name or alias.
sub GetField {

  my $self = shift;
  my $name = shift;
  my $field;
  my $viewfield_idx=0;
  foreach $field (@{$self->get_fields}) {
    if($field->get_name eq $name || 
       (defined $field->get_alias &&
	$field->get_alias eq $name)) {
      return $field;
    }
  }
  carp "The record field named [$name] does not exist in the search [",$self->get_search->get_name,"]";
  return undef;
}
#
################################################################

################################################################
# Fancy print the record in HTML format as a single row in a
# table. The list of fields to be printed is passed to the
# function as an arry @printfields.

sub PrintHTML {

  my $self = shift;
  my $links = shift;
  my @colfields = @_;
  my $value;   # This is the MySQL database value
  my $value_f; # This is the formatted value for HTML
  my $field;
  $self->HTMLAdd("<tr class='vvvlightgrey'>");
  foreach $field (@colfields) {
    my $link = $links->{$field->get_name};
    $value_f = $value = $field->get_value;
    # If the field is not defined, then grey out the table box.
    if(! defined $value || $value eq "") {
      $self->HTMLAdd("<td class=vvlightgrey>&nbsp;</td>");
      next;
    }
    if($field->get_type =~ /blob/) {
      $self->HTMLAdd("<td class=vvlightred valign=center align=center>binary</td>");
      next;
    }
    # See if the field has a column class tag. The field tag is of the format
    # "column_tag|fieldtag1%value%fieldtag2"
    # 
    if(defined $field->get_tags) {
      if($field->get_tags =~ /(.*)\|/) {
	my $coltag = $1;
	$self->HTMLAdd("<td $coltag>");
      } else {
	$self->HTMLAdd("<td>");
      }
    } else {
      $self->HTMLAdd("<td>");
    }
    if(defined $link) {
      my $linkfield;
      my $linkfieldvalue;
      while($link =~ /%(.*?)%/g) {
	$linkfield = $1;
	$linkfieldvalue = $self->GetFieldValue($linkfield);
	$link =~ s/%$linkfield%/$linkfieldvalue/g;
      }
      $self->set_html($self->get_html . "<a href=\"$link\">");
    }
    # For very large fields - crop, make small, and add ellipsis
    # For smaller fields - make small
    if(length($value) > 200) {
      $value_f = substr($value,0,15)."...";
    } elsif (length($value) > 30) {
      $value_f = $value;
      $value_f =~ s/(.{30,50}(\,|\b))/$1<br>/g;
      $value_f = "<span class=small>$value_f</span>";
    }
    # Apply formatting to this field value, if the field object contains any format
    # information
    if(defined $field->get_format) {
      $value_f = sprintf($field->get_format,$value_f);
    }
    # Apply any extra tags to this value, if the field object contains any tag information
    if(defined $field->get_tags) {
      my $tagstring = $field->get_tags;
      $tagstring =~ s/.*\|(.*)/$1/;
      $tagstring =~ s/%%value%%/$value_f/ig;
      $value_f = $tagstring;
    }
    $self->set_html($self->get_html . $value_f);
#   $self->HTMLAdd($value_f);
    if(defined $link) {
      $self->HTMLAdd("</a>");
    }
    $self->HTMLAdd("</td>");
  }
  $self->HTMLAdd("</tr>");
  return $self->get_html;
}
# end of PrintHTML
################################################################

=pod

=head2 Formatted Output

=over

=item Print

Prints all the fields in the object. The output contains text of the format
    
    Field name: value

with one line representing a field in the record object.

=back

=cut 

################################################################
# Pretty screen print the record
sub Print {

  my $self = shift;
  my $field_idx = 0;
  my $field;
  my $value;
  my $label;
  foreach $field (@{$self->get_fields}) {
    # This is the field that corresponds to the value. It is a MySQL_Field object.
    $value = $field->get_value;
    # Label for the field
    if(defined $field->get_alias) {
      $label = $field->get_alias;
    } else {
      $label = $field->get_name;
    }
    if($field->get_type =~ /blob/) {
      print sprintf(" %25s: %-15s\n",$label,"BINARY");
    } else {
      my $length = length($value);
      if($length > 100) {
	$value = substr($value,0,15)."...<".($length-30).">...".substr($value,length($value)-15,15);
      }
      print sprintf(" %25s: %-15s\n",$label,$value);
    }
    $field_idx++;
  }
}
#
################################################################

sub Imported::MySQL_Record::DESTROY {

}

sub Imported::MySQL_Record::AUTOLOAD {

  no strict "refs";
  my ($self,$newval) = @_;

  if ($AUTOLOAD =~ /.*::get(_\w+)/ && (
				       $self->_accessible($1,'read') ||
				       $self->_accessible($1,'read/write'))) {
    my $attr_name = $1;
    *{$AUTOLOAD} = sub { return $_[0]->{$attr_name} };
    return $self->{$attr_name}
  }
  if ($AUTOLOAD =~ /.*::set(_\w+)/ && $self->_accessible($1,'worm')) {
    my $attr_name = $1;
    *{$AUTOLOAD} = sub { carp "$attr_name already set\n"; $_[0]->{$attr_name};};
    $self->{$1} = $newval;
    return $self->{$1}
  }
  if ($AUTOLOAD =~ /.*::set(_\w+)/ && $self->_accessible($1,'write')) {
    my $attr_name = $1;
    *{$AUTOLOAD} = sub { $_[0]->{$attr_name} = $_[1]; return };
    $self->{$1} = $newval;
    return $self->{$1}
  }

  carp "No such method: $AUTOLOAD";

}

sub HTMLAdd {

  my $self = shift;
  my $newline;
  foreach $newline (@_) {
    $self->set_html($self->get_html . $newline . "\n");
  }
}


1;

=pod

=head1 FILES

=over

=item MySQLdb.pm

This is the main module code.

=item MySQL_Search.pm

This defines a search object. A database can have multiple search objects which represent active select queries.

=item MySQL_Record.pm

This defines a record as retrieved by a select query. It does not model the record the way it is stored in the database, but rather the way it was retrieved by the Search object. For example, if some of the fields of the db record set were not retrieved, then the Record objects will not have those fields defined.

=item MySQL_Table.pm

This sub-module defines a table object. A database object will typically have many such 'Tables'.

=item MySQL_Field.pm

This sub-module defines a field. A Table object will typically have many such 'Fields'.

=item MySQL_Tools.pm

This is a helper package which contains some miscellaneous functions.

=back

=head1 SEE ALSO

MySQL_Record, MySQL_Table, MySQL_Field, MySQL_Search

"Programming the Perl DBI" by Alligator Descartes & Tim Bunce (O'Reilly) is a good reference. We have this book.

"MySQL" by Paul DuBois (New Riders) is a superlative and very accessible MySQL reference.

=head1 NOTES

This module is actively being developed. Please report any problems
to martink@bcgsc.bc.ca.

=head1 BUGS

Find'em and crush'em.

=head1 AUTHOR

Martin Krzywinski

=head1 HISTORY

=over

=item 18 July 2000

pod documentation added

=item 2 August 2000

I have added a MySQL_Search object which
abstracts the search process - basically a wrapper for the SELECT 
statement. 

=item 5 September 2000

There was some problems with using fields in conjunction with functions on fields, such as avg or count. I have fixed the way that search and view fields are stored so that this isn't a problem any more. Make sure you understand how ordering and grouping is done on fields which are evaluated by such functions!

=back

=cut
