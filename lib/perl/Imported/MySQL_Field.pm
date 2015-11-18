################################################################
# A MySQL Field class

=head1 NAME

MySQLdb_Field - A module modelling a MySQL table field.

=head1 DESCRIPTION

A field object is a column in a database table row. Each row contains a record and has a number of columns, or fields. A field has typical MySQL properties, such as type and default settings, as well as a value.

=head1 SYNOPSIS

  use Imported::MySQLdb;
  my $db = Imported::MySQLdb->new();
  $db->Connect({'user'=>'viewer','server'=>'lims-dbm',
		'pass'=>'******','db'=>'sequence'});
  $s1 = $db->CreateSearch("s1");
  $s1->SetTable("Primer");
  $s1->Execute();
  while($s1->ForEachRecord()) {
    $record = $s1->GetRecord()->GetField("Purity");
    $field = $record->GetField("Purity");
    print "Important field name: ",$field->get_name,"\n";
    print "Important field type: ",$field->get_type,"\n";
    print "Important field value: ",$field->get_value,"\n";
  }

=head1 DESCRIPTION

This module assists in the infrastructure of the MySQL_X model. By modelling a column entry in a database table row, it forms the fundamental entity from which all other things are built: 

=over

=item *

a Record is a list of fields

=item *

a Search is a list of Records

=item *

a Table is a collection of fields

=item *

a database is a collection of Records.

=back

=head2 General Usage

This module\'s purpose is to provide low-level access to record objects returned by a SELECT statement.

=head2 Design

There are two kinds of 'fields'. In fact, there should be two separate field classes, one derived from the other. 

First, there is the concept of a table field as a data structure which holds user-defined values. One table may have an Address field, with an associated type as "text" for example. It only makes sense to talk about a value of a field in context of a Record. Thus, the primitive class is a

=over

=item *

a field of a table

=back

with the derived class being

=over

=item *

a field of a record

=back

which would have all the functionality of its ancestral class along with other members such as value, html tags and formatting text.

Currently, the design of the MySQL_Field object is such that both types of 'fields' are modelled by the same module. 

The more primitive field object (as a member of a table) can be illustrated like this

   # Prints the names of all fields from all tables in a database.
   while($table = $db->ForEachTable) {
     while($field = $table->ForEachField) {
        print $field->get_name,"\n";
     }
   }

A field as seen as a member of a Record is used as following,

   # Prints the values of all fields in a search
   while($record = $search->ForEachRecord) {
     if ($field = $record->GetField("ID")) {
       print $field->get_value,"\n";
     }
   }

=cut


package Imported::MySQL_Field;

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
                                      # MySQL field properties
	      _name       => undef,   # Name
	      _type       => undef,   # Type
	      _null       => undef,   # Can it be null?
	      _key        => undef,   # KEY
	      _default    => undef,   # Default value
	      _extra      => undef,   # Extra
	                           
	      _table      => undef,   # Table owning the field
	                              # MySQL query properties
	      _alias      => undef,   # Fields AS alias
	      _function   => undef,   # Function evaluating field
	                              # Select result properties
	      _value      => undef,   # Value of field
	                              # HTML printing properties
	      _format     => undef,   # format for sprintf
	      _tags    => undef,      # extra tags, if any
	     };
  
  bless $self,$class;
  
  my $hash = $_[1];
  
  $self->set_name($hash->{Field});
  $self->set_type($hash->{Type});
  $self->set_null($hash->{Null});
  $self->set_extra($hash->{Extra});
  $self->set_default($hash->{Default});
  $self->set_key($hash->{Key});

  my $table = $_[2];

  $self->set_table($table);

  return $self;

}

{
  my %_attrs =
    ( 
     _name     => 'read/write',
     _alias    => 'read/write',
     _type     => 'read/write',
     _null     => 'read/write',
     _key      => 'read/write',
     _default  => 'read/write',
     _extra    => 'read/write',

     _table    => 'read/write',

     _value    => 'read/write',
     _function => 'read/write',
     _tags  => 'read/write',
     _format   => 'read/write',
    );
  sub _accessible {
    my ($self,$attr,$mode) = @_;
    $_attrs{$attr} =~ /$mode/;
  }
}

################################################################
# Deep copy function. 
# This function duplicates the field structure. As long as 
# this class does not contain elements which are references
# this will work. The MySQL_Field object has all members as
# regular non-reference variables.
# The clone function is useful for creating copies of fields,
# each of which has different "values" or "tags" or other
# individual formatting options. The MySQL_Search module uses
# this in the AddViewField function to create multiple instances
# of fields as viewfields.
#
sub clone {
  my ($self) = @_;
  my $class = ref($self);
  bless { %{$self} }, $class;
}
#
################################################################

# This is a special member value function. Tags are not just set but appended.
# The format of the tag for a field is the following
#  column_tags|pre_value_tags%value%post_value_tags.
# At time of usage, %value% is replaced with the fields value. %value% can appear
# more than once.
# The column_tags are inserted in <td HERE>tags..value..tags</td>.
# The pre_ and post_value tags are meant to encase the %value% string.

sub set_tags {
  my $self = shift;
  my $newtag = shift;
  my $coltag;
  my $valuetag;
  my ($newtag_col,$newtag_val,$newtag_pre,$newtag_pos);
  if($newtag =~ /\|/) {
    # Case 1. There is a pipe.
    if($newtag =~ /(.*)\|([^%]*)(%%)?(ALL|VALUE)?(%%)?(.*)/) {
      $newtag_col = $1 || "";
      $newtag_pre = $2 || "";
      $newtag_val = $4 || "";
      $newtag_pos = $6 || "";
    }
  } else {
    # Case 2. There is no pipe.
    if($newtag =~ /^([^%]*)(%%)?(ALL|VALUE)?(%%)?(.*)$/) {
      $newtag_col = "";
      $newtag_pre = $1 || "";
      $newtag_val = $3 || "";
      $newtag_pos = $5 || "";
    }
  }
  my $currtag = $self->get_tags;
  # If this is the first time the tag is set, just copy the newtag over.
  if($currtag eq "") {
    $newtag =~ s/%%ALL%%/%%VALUE%%/g;
    if($newtag !~ /%%VALUE%%/) {
      $newtag = "$newtag%%VALUE%%";
    }
    $self->{_tags} = $newtag;
    return;
  }
#  print "[$newtag_col][$newtag_pre][$newtag_val][$newtag_pos]\n";
#  print "Have old tag [$currtag]\n";
  # Otherwise, we'll have to play around a little.
  # First, append the column tags.
  if($newtag_col ne "") {
    if($currtag =~ /\|/) {
      $currtag =~ s/(.*)\|/$newtag_col $1\|/;      
    } else {
      $currtag = "$newtag_col|$currtag";
    } 
  }
  # If we have VALUE tags, insert them in
#  print "Have old tag [$currtag]\n";
  if($newtag_val =~ /value/i) {
    # If there is no value string, make one.
    if($currtag !~ /%%VALUE%%/) {
      $currtag .= "%%VALUE%%";
    }
    $currtag =~ s/%%VALUE%%/$newtag_pre%%VALUE%%$newtag_pos/g;
    $self->{_tags} = $currtag;
    return;
  }
  # If we have ALL tags, insert them in.
  if($newtag_val =~ /all/i) {
    if($currtag =~ /\|/) {
      $currtag =~ s/(.*)\|(.*)/$1\|$newtag_pre$2$newtag_pos/;
    } else {
      $currtag = "$newtag_pre$currtag$newtag_pos";
    }
    $self->{_tags} = $currtag;
    return;
  }
  # We have no value tag. This means that everything is considered to be a pretag.
  if($currtag =~ /\|/) {
    $currtag =~ s/(.*)\|(.*)/$1\|$newtag_pre$2/;
  } else {
    $currtag = "$newtag_pre$currtag";
  }
  $self->{_tags} = $currtag;
  return;
}

=pod

=head2 Formatted Output

=over

=item Print

Prints all the fields in the object. The output contains text of the format
    
    ::: FIELD field_name :::
  property_1: value
  property_2: value
  etc.

with each line listing a MySQL field property. Advanced properties (as derived form Record membership) such as value and tags are not printed.

=back

=cut 

sub Print {

  my $self = shift;

  print sprintf("    ::: FIELD %s :::\n",$self->get_name);
  print sprintf("        Type: %-15s\n",$self->get_type);
  print sprintf("        Null: %-15s\n",$self->get_null);
  print sprintf("     Default: %-15s\n",$self->get_default);
  print sprintf("       Extra: %-15s\n",$self->get_extra);
  print sprintf("       Table: %-15s\n",$self->get_table->get_name);
  print sprintf("       Alias: %-15s\n",$self->get_alias);
  print sprintf("    Function: %-15s\n",$self->get_function);
  print sprintf("      Format: %-15s\n",$self->get_format);
  print sprintf("       Value: %-15s\n",$self->get_value);
  print sprintf("        Tags: %-15s\n",$self->get_tags);

}

################################################################

#
################################################################

sub Imported::MySQL_Field::DESTROY {

}

sub Imported::MySQL_Field::AUTOLOAD {

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

=back

=cut
