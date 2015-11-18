package Imported::MySQL_Tools;

################################################################
# Assorted tools for MySQL_X modules
#
# CVS: $Revision: 1.1 $
# Date: $Date: 2003/04/10 23:59:07 $
#
################################################################

=pod

=head1 NAME

MySQLdb_Tools - Assorted, generic functions used by the MySQLdb and other MySQL_X modules.

=head1 DESCRIPTION

This module is not an object, but a collection of functions meant to be used by objects modelling the MySQL database and searches.

=head1 SYNOPSIS

See USAGE

=cut

=pod

=head1 USAGE

=over

=item ArgAssign()

ArgAssign is used to parse values passed to a function. Instead of creating functions which take arguments in a list, e.g. func(a,b,c,..), a more flexible approach is to use a hash. By indexing the input variables with names within the function, one can use a system like func({'var1'=>'a','var2'=>'b',...}). By passing arguments in a hash it is no longer necessary to keep in mind their order. In addition, optional arguments are easily handled - if a hash element is not defined, the argument was not passed.

    func({'var1'=>5,'var2'=>10});
    sub func {
      my $hash=shift;
      my $funcvar1;
      my $funcvar2;
      ArgAssign({'var1'=>\$funcvar1,
		 'var2'=>\$funcvar2}
		,$hash);
      print $var1 # prints 5
    }

The way ArgAssign works above is to match the hash element keyed as 'var1' to the function variable $funcvar. Notice that ArgAssign itself is passed a hash. It goes through the hash and for each key in the hash it looks for that corresponding parameter in the hash passed to the function that uses ArgAssign (this hash is passed to ArgAssign as the second argument). Once the parameter is found, its value is assigned to the variable whose reference is the value of the associated key in the variable-name/variable-reference hash.

=back

=cut

################################################################
# Assigns arguments to a function to the function's internal
# variables.
#
# A function will typically be passed a hash containing the arguments
# and their names of the format
#
# func({arg1=>value1,arg2=>value2,...});
#
# Using the hash notation $hash->{$arg1} is cumbersome. So, in the
# function we define variables like
#
# $arg1, $arg2, ...
#
# and then call
#
# ArgAssign({arg1=>\$arg1,arg2=>\$arg2,...},$hash);
#
# This checks whether argN is a key in the hash passed to the function.
# If so, then it assigns the value of this key to the internal function
# variable $arg1. If not, then ArgAssign croaks.

sub ArgAssign {

  my $self = shift;
  my $args = shift;
  my $hash = shift;

  my $arg_check;

  foreach $arg_check (keys %{$args}) {
    if(defined($hash->{$arg_check})) {
      ${$args->{$arg_check}} = $hash->{$arg_check};
    } else {
      # Nothing
    }
  }
}
#
################################################################


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
