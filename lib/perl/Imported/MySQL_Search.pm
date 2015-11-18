################################################################
# A MySQL Search class
#
# CVS: $Revision: 1.1 $
# Date: $Date: 2003/04/10 23:59:07 $
#
################################################################

package Imported::MySQL_Search;

=head1 NAME

MySQLdb_Search - A module modelling aspects of a MySQL search operation.

=head1 DESCRIPTION

Searching for records in a database where more than a couple of tables are being used can be tedious: large SQL statements must be cast, with parts of the statements often being boiler-plate text (such as foreign key relationships).

The entire MySQL_X module family was developed with the aim to code searches very quickly. In particular, the strength of the module comes from its very flexible HTML reporting feature, which automatically creates tables with user-defined formatting elements for each search.

=head1 SYNOPSIS

Several search examples are shown below.

  use Imported::MySQLdb;
  my $db = Imported::MySQLdb->new();
  $db->Connect({'user'=>'viewer','server'=>'lims-dbm',
		'pass'=>'******','db'=>'sequence'});


  # Example 1
  # http://www.bcgsc.bc.ca/cgi-bin/intranet/MySQLdb/example-1
  # LISTING ALL FIELDS IN A TABLE

  # This is the simplest type of search object.
  # The object is first created and named.
  $s1 = $db->CreateSearch("s1");
  # The primary search table is defined. This is the table which will form the
  # root of the search. Other tables can be linked to this one using foreign keys.
  $s1->SetTable("Equipment");
  # We now execute this statement. Since nothing else was specified, such as 
  # search fields, everything from the selected table is pulled out.
  $s1->Execute();
  $s1->PrintHTML();

  # Example 1-b
  # http://www.bcgsc.bc.ca/cgi-bin/intranet/MySQLdb/example-1b
  # LISTING FIELDS IN A TABLE SUBJECT TO SEARCH CONDITIONS: value and range
  $s1 = $db->CreateSearch("s1");
  $s1->SetTable("Equipment");
  # If 'value' is passed a single string, then a single equality check will be done.
  # To turn the search into a series of OR statements, pass to 'value' an array reference.
  # Use 'range' to specify a numerical range [min,max]. Leaving out min or max will
  # make it a one-sided range (e.g. [,10] means <=10). Open-sided ranges are 
  # specified using (min,max). Combinations are possible with [min,max).
  $s1->AddField({"field"=>"Equipment_Type","value"=>["Hydra","Centrifuge"]});
  $s1->AddField({"field"=>"Equipment_ID","range"=>"[5,15]"});
  $s1->Execute();
  


  # Example 2
  # http://www.bcgsc.bc.ca/cgi-bin/intranet/MySQLdb/example-2
  # LISTING PROCESSED FIELDS WITH FORMATTING
  $s2 = $db->CreateSearch("s2");
  $s2->SetTable("Clone_Sequence");
  $s2->AddFK({'field'=>'Run.ID'});
  $s2->AddFK({'field'=>'RunBatch.ID'});
  $s2->AddFK({'field'=>'Equipment.ID','fktable'=>'RunBatch'});
  $s2->AddFK({'field'=>'Employee.ID','fktable'=>'RunBatch'});
  $s2->AddViewField({'field'=>'Employee.Employee_Name','alias'=>'Name'});
  $s2->AddViewField({'field'=>'Equipment.Equipment_Name','alias'=>'Sequencer'});
  $s2->AddViewField({'field'=>'Sequence_Length',function=>'avg',alias=>'Average'});
  $s2->AddViewField({'field'=>'FK_Run__ID',function=>'count',alias=>'N_Reads'});
  $s2->Order({'field'=>'Equipment.Equipment_Name','order'=>'asc'});
  $s2->Order({'field'=>'Sequence_Length','order'=>'desc'});
  $s2->AddGroup({'field'=>'Employee.Employee_Name'});
  $s2->AddGroup({'field'=>'Equipment.Equipment_Name'});
  $s2->Execute();
  $s2->PrintHTML({
    'title'=>"Average Run Lengths by Machine and Employee",
    'summary'=>"Test Summary",
    'bench'=>"yes",
    'formatfields'=>{'Average'=>'%6.1f'},
    'extratagsfields'=>{'Average'=>'align=center|%%ALL%% bp',
			'N_Reads'=>'align=center|',
			'Sequencer'=>'align=center|',
			'Name'=>'align=right class=vvlightred|',
		      },
    'extratagstypes'=>{'.*text.*'=>'|<b>%%VALUE%%</b>'},
  });

=head1 DESCRIPTION

This module provides a data framework for searching a MySQL database and manipulating the records produced by the search. The MySQL_Search object serves as a container for retrieved MySQL_Record objects, which themselves are a collection of MySQL_Field objects. The Search object also translates search parameters into SQL statements, obviating the need for typing SQL constructs directly.

=head2 General Usage

Generally one will 

=over

=item *

Connect to a database (using $db->Connect)

=item *

Create a search object ($search = $db->CreateSearch)

=item *

Designate a primary search table ($search->SetTable)

=item *

Define any foreign key relationships (optional) ($search->AddFK)

=item *

Define any search criteria (optional) ($search->AddField)

=item *

Specify table fields to view during reporting (optional) ($search->AddViewField)

=item *

Specify GROUP, ORDER and LIMIT fields (optional) ($search->Group, $search->Order, $search->Limit)

=item *

Execute the search ($search->Execute)

=back

Once the search has been executed and contains a list of retrieved records, one typically

=over

=item *

Prints out all the records in a formatted table ($search->PrintHTML)

=item *

Iterates through all the records, extrating useful data ($search->ForEachRecord)

=back

Some of the terminology such as "view fields" or "search fields" will be defined below.

=head2 Design

As mentioned, the search object provides a container and function-to-SQL translation. Records are retrieved from a database according to criteria:

=over

=item Search Tables

Typically, one searches a subset of all the database tables. There is usually a primary search table, which serves as the foundation of the search. For example, searching for Addresses might mean looking in an Address table. Tables are often related together using foreign-key or lookup relationships. If any two tables are to be used in a search concurrently, their records must somehow be related by way of a lookup field. Adding such relationships is done using the AddFK function in the module, which relates a foreign key field in one table with a lookup field in another. 

Search tables must be defined: one must search some table.

=item Search Criteria

Search criteria can be divided into two broad categories.

LIMITING CRITERIA

These criteria limit the records retrieved from the database. This typically involves some boolean operation that is evaluated with user-input values. For example, search all the addresses in British Columbia.

GROUPING CRITERIA

Grouping criteria involves coalescing retrievied fields according to some common feature. For example, count all the addresses in British Columbia, would involve a COUNT grouping criteria along with a limiting criteria to focus on the province.

One can use grouping criteria without limiting criteria. For example, how many addresses are there in each province? In this case, you want to retrieve all the records, but group them logically according to a common value (province).

=back

In addition to retrieving the correct records, formatted output is necessary. By modelling each search as a collection of records, and a record as a collection of fields, the module can relegate formatted output to the field object. In this design, a user has detailed control over how each field is printed and can invoke name, type or value sensitive formatting options.

=head2 Initializer

The initializer creates a search object.

=over

=item Initializer

To create a search, you need a valid MySQLdb object. Once one is created, it is enough to use $db->CreateSearch(name) to create a search object named 'name'.

=back

=cut

use strict;
use Benchmark;
use Imported::PerlHelper;
use Imported::MySQL_Record;
use Imported::MySQL_Tools;
use POSIX qw();
use Carp;
use vars '$AUTOLOAD';

sub new {
  
  my ($class) = $_[0];
  my $self = {
              _db           => $_[1], # MySQLdb object 
	      _record       => undef, # last fetched record object
	      _table        => undef, # primary search table object
	      _fktables     => undef, # lookup table objects
	      _name         => $_[2], # search identifier	
	      _nrecs        => undef, # records produced by select
              _frecs        => undef, # records fetched so far
	      _curr_frec    => undef, # current record pointer
	      _sql          => undef, # search SQL statement
              _sthandle     => undef, # search statement handle
	      _tablename    => undef, # primary search table name
	      _nrecs_lim    => undef, # limit retrieved records
	      _limit_offset => undef, # row offset for limit
	      _limit_num    => undef, # number of rows to return for limit
	      _searchfields => undef, # fields to search
	      _fkfields     => undef, # foreign key fields
	      _groups       => undef, # groups
	      _orderfields  => undef, # fields to order by
	      _viewfields   => undef, # fields to search
	      _benchmark    => undef, # time to execute search
	      _fetchrows    => undef, # array reference to fetched rows
	      _html         => undef, # HTML code for this search
	     };
  bless $self,$class;
  return $self;
}

{
  my %_attrs =
    ( 
     _db           => 'read/write',
     _name         => 'read/write',
     _sql          => 'read/write',
     _nrecs        => 'read/write',
     _frecs        => 'read/write',
     _curr_frec    => 'read/write',
     _record       => 'read/write',
     _sthandle     => 'read/write',
     _tablename    => 'read/write',     
     _table        => 'read/write',     
     _searchfields => 'read/write',
     _groups       => 'read/write',
     _orderfields  => 'read/write',
     _viewfields   => 'read/write',
     _fktables     => 'read/write',
     _fkfields     => 'read/write',
     _nrecs_lim    => 'read/write',
     _limit_offset => 'read/write',
     _limit_num    => 'read/write',
     _benchmark    => 'read/write',
     _fetchrows    => 'read/write',
     _html         => 'read/write',
    );
  sub _accessible {
    my ($self,$attr,$mode) = @_;
    $_attrs{$attr} =~ /$mode/;
  }
}

=pod

=head2 Specifying Search Tables

A search requires a primary search table and may contain accompanying lookup tables.

=over

=item SetTable(tablename)

To create a primary search table, specify the table by name using SetTable.

=item AddFK({'field'=>fieldname,'table'=>table,'fktable'=>fktable})

AddFK is an example of a module function which takes a hash as an argument. The AddFK function requires that three things be defined

1. The table which contains the foreign key (fktable)
2. The table which contains the lookup value (table)
3. The lookup field in the lookup table which (field)

The table and field pair can be defined in two ways:

AddFK({'field'=>"tablename.fieldname",'fktable'=>fktable})
AddFK({'field'=>fieldname,'table'=>tablename,'fktable'=>fktable})

The table.field notation is the same as MySQL\'s own notation. 

If the fktable is the same as the primary search table, it does not need to be specified.

For example, if you are searching an Address table and it contains a lookup field FK_Province__ID which points to the table Province and uses the field Province_ID as a lookup value index, you would use

AddFK({'field'=>"Province.ID",'fktable'=>"Address"});

CAUTION: The AddFK function expects a fixed convention in how fields are named. All foreign key fields must be named FK_LookupTable__LookupField. LookupTable is the name of the table containing the lookup values. LookupField is the last piece of the field name in that table, where the full name is LookupTable_LookupField. For example, in our case above the Address table would have a field FK_Province__ID, and the Province table would have a field Province_ID. When we used AddFK, only the "ID" portion of the field Province_ID had to be specified, because AddFK assumed that the field would be prefixed by the table name.

In order to AddFK to succeed, the search must already have the foreign key table defined. That is, the foreign key table must either be the primary search table or another table already defined by a previous involcation of AddFK.

=back

=cut

################################################################
# Sets the primary table for searching
# This table must be found in the database, otherwise the 
# module croaks.
sub SetTable {

  my $self      = shift;
  my $tablename = shift;
  my $table;
  if(! ($table=$self->get_db->GetTable($tablename))) {
	croak "The table [$table] was not found in the database.\n";
  }
  $self->set_tablename($tablename);
  $self->set_table($table);
}
#
################################################################

################################################################
# Adds a foreign key table dependency to the search.
# If the current table has a FK pointing to table TABLE1's field
# FIELD1 then the appropriate line to add is
#   ADDFK({'table'=>'TABLE1','field'=>'FIELD1'});
#
#   fktable.FK_lookuptable__lookupfield => lookuptable.lookupfield
#
# If one tries to add a FK that is already been added, nothing happens.
sub AddFK {

  my $self = shift;
  my $hash = shift || "";
  my $lookuptable_n;
  my $lookupfield_n;
  my $fktable_n = $self->get_table->get_name;
  my $error = "ERROR: Imported::MySQL_Search::AddFK : ";

  $self->Imported::MySQL_Tools::ArgAssign({'table'=>\$lookuptable_n,
				 'fktable'=>\$fktable_n,
				 'field'=>\$lookupfield_n},
				$hash);

  $self->ParseFieldName(\$lookupfield_n,\$lookuptable_n);

  # For now, the fk table is the primary search table
  my $fktable = $self->get_table;
  # Make sure that the lookup table exists, and that it contains the field that
  # is being looked up. 
  my $lookupfield;
  my $lookuptable;

  if(! ($lookuptable = $self->get_db->GetTable($lookuptable_n))) {
    croak "$error Lookup table $lookuptable_n not found in database.\n";
  }
  if(! ($lookupfield = $lookuptable->GetField($lookuptable_n."_".$lookupfield_n))) {
    croak "$error Lookup table $lookuptable_n does not have the field ${lookuptable_n}_$lookupfield_n.\n";
  }
  # At this point we know that the FK table exists and has the lookup field

  # Add the lookuptable to the list of fk tables, if it's not already in there
  if(! Imported::PerlHelper::IsIn($lookuptable->get_name,$self->GetFKTableNames)) {
    push(@{$self->{_fktables}},$lookuptable);
  } else {
    # If the table is already in the list, just return out of the function. We
    # don't need to add the sql statement chunk that ties this table to others since
    # the previous invocation of AddFK would have done that.
    return;
  }
  my $sql = "($fktable_n.FK_${lookuptable_n}__${lookupfield_n} = $lookuptable_n.${lookuptable_n}_$lookupfield_n)";
  # Add the lookup field to the list of fields
  # 'field' holds the lookup field object
  #         use {'field'}->get_table to find the lookup table object
  # 'fktable' holds the table doing the lookup
  # 'sql' holds the equality condition for the table join
  push(@{$self->{_fkfields}},
       {'field'=>$lookupfield,
	'table'=>$fktable,
	'sql'=>$sql,
      });
}
# AddFK END
################################################################

sub GetRecord {

  my $self   = shift;
  my $recnum = shift;

  if(! defined $recnum && defined $self->get_curr_frec) {
    $recnum = $self->get_curr_frec;
  } 
  my $rec_ref = $self->get_fetchrows->[$recnum];
  my $rec = Imported::MySQL_Record->new($rec_ref,$self);
  $self->set_curr_frec($recnum);
  $self->set_record($rec);
  return $rec;    
}


################################################################
# Iterator over all found records.
#
# The records are stored in the _fetchrows array reference.
# This reference points to a list of references to each record.
#
# _fetchrows->[m]->[n] gives the (n+1)th field of the (m+1)th record
#
# The function cycles through all the elements in the found record
# array and, for each element, creates a MySQL_Record object out of
# it and returns this object.

sub ForEachRecord {
  my $self    = shift;
  my $fetch_idx;
  my $rec = undef;
  if($self->get_frecs < $self->get_nrecs) {
    # If the number of records we've fetched is less than the total 
    # records found by the search, set the fetch_idx (the index
    # of the record currently fetched) and augment the _frecs member.
    $fetch_idx = $self->get_frecs;
    $self->set_frecs($fetch_idx+1);
  } else {
    # Otherwise, set _frecs to zero and set the fetch index to zero, 
    # starting the fetch from the beginning again.
    $fetch_idx = 0;
    $self->set_frecs(0);
    return $rec;
  }
  # Grab the reference to the array holding the record.
  my $rec_ref = $self->get_fetchrows->[$fetch_idx];
  # Create a Record object from this. The Record object stores the search it 
  # beelongs to
  $rec = Imported::MySQL_Record->new($rec_ref,$self);
  # Set this object to be the current record in the Search
  $self->set_record($rec);
#  print "$fetch_idx ";
  return $rec;
}
# ForEachRecord                                              END
################################################################

################################################################
# Execute the search SQL statement. After the call to Execute
# the _sthandle statement handle is active and the _nrecs member
# contains the number of records returned by the search.
sub Execute {
  my $self = shift;
  my @args = @_;
  
  # If the SQL is defined for this search, then the search
  # statement handle would already have been prepared and
  # can now be executed (see below the IF clause).
  # If not, then we must construct the SQL query from other
  # search object members. This is done in the IF clause below.

  if (! defined $self->get_sql) {
    my $sql = "select ";
    # View fields
    if(defined $self->get_viewfields) {
      my @viewsql;
      my $viewfield;
      foreach $viewfield (@{$self->get_viewfields}) {
	push(@viewsql,$viewfield->{'sql'});
      }
      $sql .= join(",",@viewsql);
    } else {
      my $field;
      # Add all fields of the primary search table to the viewfield list.
      while($field = $self->get_table->ForEachField) {
	push(@{$self->{_viewfields}},
	     {'field'=>$field,
	      'sql'=>""});
      }
      my $fktable;
      if(defined $self->get_fktables) {
	foreach $fktable (@{$self->get_fktables}) {
	  while($field = $fktable->ForEachField) {
	    push(@{$self->{_viewfields}},
		 {'field'=>$field,
		  'table'=>$fktable,
		  'sql'=>""});
	  }
	}
      }
      $sql .= " * ";
    }
    my $tablename = $self->get_tablename;
    $sql .=  " from $tablename";
    # Append any tables used for lookups. This list is kept in the _fktables variable
    if(defined $self->get_fktables) {
      my @fktablenames;
      my $fktable;
      foreach $fktable (@{$self->get_fktables}) {
	push(@fktablenames,$fktable->get_name);
      }
      $sql .= ",".join(",",@fktablenames);
    }
    # Handle any fk fields (lookups), added automatically by AddFK, or regular search
    # fields added by AddField.
    if(defined $self->{_searchfields} || defined $self->{_fkfields}) {
      my $field;
      my $wheresql;
      $sql .= " where ";
      my @conditions;
      # First, handle the fk fields
      foreach $field (@{$self->{_fkfields}},@{$self->{_searchfields}}) {
	push(@conditions,$field->{'sql'});
      }
      $sql .= join(" and ",@conditions);
    }
    if(defined $self->get_groups) {
      $sql .= " group by ";
      my $groupfield;
      my @groupfieldlist;
      foreach $groupfield (@{$self->get_groups}) {
	push(@groupfieldlist,$groupfield->get_name);
      }
      $sql .= join(",",@groupfieldlist);
    }
    # Handle orders. Ordering is done by fields for fields which have no functions
    # associated with them (e.g. select FIELD from ...) and by their aliases if
    # they have functions associated with them (e.g. select count(FIELD) from ...)
    if(defined $self->get_orderfields) {
      $sql .= " order by ";
      my @orderfieldsql;
      my $orderfield;
      foreach $orderfield (@{$self->get_orderfields}) {
	my $ordersql;
	my $ordername = $orderfield->{'ordername'};
	my $function  = $orderfield->{'function'};
	if($function ne "") {
	  $ordersql .= $function."(".$ordername.")";
	} else {
	  $ordersql .= $ordername;
	}
	$ordersql .= " " . $orderfield->{'order'};
	push(@orderfieldsql,$ordersql);
      }
      $sql .= join(",",@orderfieldsql);
    }
    if(defined $self->get_limit_offset || defined $self->get_limit_num) {
      my $off = $self->get_limit_offset;
      my $num = $self->get_limit_num;
      $sql .= " limit $off,$num ";
    }
    # Get rid of any double spaces.
    $sql =~ s/  / /g;
    # Compress spaces after open brackets and before closed brackets.
    $sql =~ s/\(\s+/\(/g;
    $sql =~ s/\s+\)/\)/g;
    # For clarity, capitalize SQL key words.
    $sql =~ s/where/WHERE/g;
    $sql =~ s/from/FROM/g;
    $sql =~ s/select/SELECT/g;
    $sql =~ s/group/GROUP/g;
    $sql =~ s/order/ORDER/g;
    $sql =~ s/regexp/REGEXP/g;
    $sql =~ s/ and / AND /g;
    $sql =~ s/ or / OR /g;
    $sql =~ s/ as / AS /g;
    # Assign the SQL statement to the search.
    $self->SQL($sql);
  }
  my $t0 = new Benchmark;
  $self->get_sthandle->execute(@args);
  my $t1 = new Benchmark;
  my $tdiff = timediff($t1,$t0);
  # Store the time taken to do this search
  $self->set_benchmark(timestr($tdiff));
  # Store the number of records retrieved
  $self->set_nrecs($self->get_sthandle->rows());
  # Store the reference to the array of the records
  $self->set_fetchrows($self->get_sthandle->fetchall_arrayref());
  # Store the number of records fetched from this search (i.e. no records fetched yet 
  # therefore set to 0).
  $self->set_frecs(0);
}
#
################################################################

sub GetAgeUnitMultiplier {

  my $self=shift;
  my $unit=shift;
  my $mult=3600*24;
  if($$unit =~ /^(h|hour|hours)$/i ) {
    $mult = 3600;
    $$unit = "h";

  }
  if($$unit =~ /^(m|min|minutes)$/ ) {
    $mult = 60;
    $$unit = "m";
  }
  if($$unit =~ /^(s|sec|seconds)$/i ) {
    $mult = 1;
    $$unit = "s";
  }
  if($$unit =~ /^(w|week|weeks)$/i ) {
    $mult = 3600*24*7;
    $$unit = "w";
  }
  if($$unit =~ /^(M|mon|months)$/ ) {
    $mult = 3600*24*31;
    $$unit = "M";
  }
  return $mult;
}

################################################################
# Parses a range
#
# This is a helper function. It parses a range which is
# defined, in common notation, for example as
#
#   (min,max]
#
# ( indicates an open end and ] a closed end.
#
# The types of range notations allowed are
#
#   (###unit,###unit) 
#       This is a number range. ### is some integer and unit is an
#       arbitrary non-numeric string. The unit is used for age
#       specification and can be 's','m','d','w','M'
#   (##-##-####,##-##-####)
#       This range is used for age specification by date of the form
#       DD-MM-YYYY

sub ParseRange {
  my $self = shift;
  my $range = shift;
  my $error = "ERROR: Your range string $range is malformed.\n";
  my $errorflag = 0;
  if($range =~ /([\[\(])([\d\-\.\+: ]*)(\D*),([\d\-\.\+: ]*)(\D*)([\]\)])/) {
    my $lb      = $1;
    my $min     = $2;
    my $minunit = $3;
    my $max     = $4;
    my $maxunit = $5;
    my $rb      = $6;
    my $lcond = ">";
    my $rcond = "<";
    
#    if($max !~ /\d{4}\-\d{2}-\d{2}/ && $min !~ /\d{4}\-\d{2}-\d{2}/ && $max < $min) {
#      print "$error Max ($max) must be larger than min ($min).\n";
#      $errorflag = 1;
#    }
    if($max eq "" && $min eq "") {
      print "$error You must define a min or max value.\n";
      $errorflag = 1;
    }
    if ($lb eq "[") {	$lcond = ">="; }
    if ($rb eq "]") {	$rcond = "<="; }
    if(! $errorflag) {
#      print "Range: X $lcond $min($minunit)  X $rcond $max($minunit)\n";
      return ($min,$minunit,$max,$maxunit,$lcond,$rcond);
    }
  } else {
    print "$error Expecting [x,y]\n";
  }
  return ("","","","");
}
# end of ParseRange
################################################################

=pod

=head2 Specifying Search Fields

Search fields are limiting search criteria which are applied to database records and provide boolean-style criteria used to decide whether a record matches the search.

=over

=item AddField({'field'=>"tablename.fieldname",'function',=>'funcname','<criteria>'=>'<value>'});

The field is specified in the same manner as in the AddFK function. You can use the table.field MySQL notation, or specify both 'field' and 'table' entries in the argument hash. If you do not specify the table, it is assumed that the field is in the primary search table.

You can specify a function to evaluate the field before checking the condition. For example, if you want to search by WEEKDAY(table.field) rather than the field itself, use 'function'=>'WEEKDAY'.

There are various <criteria> you can apply, depending on the type of field you are searching against. 
    
<criteria> = "value"
<value>    = string

If you are looking to search a field for a string, use the 'value' hash element. For example, to search for a field containing "John" you would use

AddField({'field'=>'Names.FirstName','value'=>'John'});

If you need to search for a list of values, pass an array reference. 

AddField({'field'=>'Names.FirstName','value'=>['John','Mary','Isaac']});

The module will turn this into a series of OR conditions in your search.

<criteria> = "regexp"
<value>    = regular expression

If you need to use a regular expression search, use the 'regexp' construct. The regular expression is of the type understood by MySQL, not Perl\'s regexp engine. You can pass a single value to "regexp", or an array reference to create a series of OR regexp checks.

<criteria> = "range"
<value>    = range expression of the format [min,max)

A range has four elements: a minimum, a maximum and a condition applied to each of these. Using [ denotes a closed range, where the minimum is included in the range of values and ( denotes an open range, where the minimum is not included. For example,

[10,20)  <=>  10<=x<20

The 'range' directive can be used for either number fields (int, float, double) or date fields. The min,max values can then be either numbers or dates in the form DD-MM-YYYY. So,

["02-03-2000","05-09-2000")

is a valid date range.

You can combine range with the 'function' directive to search for field lengths, for example.

AddField({'field'=>'Names.FirstName','function'=>'length','range'=>[,5]});

will search all first names with a length <= 5.

<criteria> = "agerange"
<value>    = range expression of the format [min(unit),max(unit))

The 'agerange' is used when you want to search by date fields but using relative age of the field rather than the absolute date stamp. For example, to search for records that are between 5 and 10 days old, you would use

'agerange'=>'[5d,10d]'

Units that are understood are h=hours, m=minutes, s=seconds, w=weeks (7 day equivalents), M=months (31 day equivalents).

=back

=cut

################################################################
# Add a Search field
#
#
sub AddField {

  my $self = shift;
  my $hash = shift || "";
  my $field_n;
  my $table_n;
  my $regexp;
  my $value;
  my $function;
  my $agerange;
  my $datefilter;
  my $range;
  my $bool;
  my $sql;
  my $error = "ERROR Imported::MySQL_Search.pm::AddField : ";

  $self->Imported::MySQL_Tools::ArgAssign({'table'=>\$table_n,
				 'field'=>\$field_n,
				 'regexp'=>\$regexp,
				 'value'=>\$value,
				 'bool'=>\$bool,
				 'function'=>\$function,
				 'agerange'=>\$agerange,
				 'datefilter'=>\$datefilter,
				 'range'=>\$range},
				$hash);

  # Parse the field input. If it is of the form text1.text2 then take
  # text1 to be the table and text2 to be the field.
  $self->ParseFieldName(\$field_n,\$table_n,\$function);

  # We first search through all the tables for the field that is being examined.
  # We need to verify that this field actually exists.
  # First, though, make sure that the table is either the primary search table
  # or one of the FK tables
  if(! Imported::PerlHelper::IsIn($table_n,($self->get_table->get_name,$self->GetFKTableNames))) {
    croak "Table [$table_n] is not neither the primary table nor in the list of lookuptables for this search.\n";
  }

  my $fieldtable = $self->get_db->GetTable($table_n);

  # Now that we know the table is in the search, see if the field asked for is
  # in fact in this table.

  my $field = undef;

  if(! ($field = $fieldtable->GetField($field_n))) {
    croak "Table [$table_n] does not contain the search field [$field_n].\n";
  }

  my $fieldtype = $field->get_type;

  # Put together the SQL for this field search

#  print "Adding field ",$field->get_name," from ",$fieldtable->get_name,"\n";
#  print "Field is of type ",$field->get_type,"\n";

  # Search by VALUE
  
  my $sqlfieldstring;
  if(defined $function) {
    if($function =~ /(.*):(.*)/) {
      $sqlfieldstring = "$1($table_n.$field_n,$2)";
    } else {
      $sqlfieldstring = "$function($table_n.$field_n)";
    }
  } else {
    $sqlfieldstring = "$table_n.$field_n";
  }
  if(defined $value) {
    # The value may be a comma-delimited list to construct an OR statement.
    # If the comma is preceeded by a \ (e.g. value="ab\,cd") then 
    # it is treated as a comma and not as a list delimiter.
    if(! defined $bool) {
      $bool = "=";
    }
    if (ref($value) eq "ARRAY") {
      my $valueitem;
      my @valuesql;
      foreach $valueitem (@{$value}) {
	push(@valuesql,"$sqlfieldstring$bool\"$valueitem\"");
      }
      $sql .= " ( ".join(" OR ",@valuesql)." ) ";
    } else {
      # Try to figure out whether quotes are required.
      # If just digits or function present, no quotes
      if($value =~ /^\d+$/ || $value =~ /.*\(.*\).*/) {
	$sql .= " ($sqlfieldstring$bool$value) ";
      } else {
	$sql .= " ($sqlfieldstring$bool\"$value\") ";
      }
    }
    # Search by REGULAR EXPRESSION  
  } elsif (defined $regexp) {
    if(ref($regexp) eq "ARRAY") {
      my $regexpitem;
      my @regexpsql;
      foreach $regexpitem (@{$regexp}) {
	push(@regexpsql,"$sqlfieldstring regexp \"$regexpitem\"");
      }
      $sql .= " ( ".join(" OR ",@regexpsql)." ) ";
    } else {
      $sql .= " ($sqlfieldstring regexp \"$regexp\") ";
    }
    # Search by RANGE over numbers
  } elsif (defined $range) {
    my ($min,$minunit,$max,$maxunit,$lcond,$rcond) = $self->ParseRange($range);
    # Range will only apply if the field is an INT or a FLOAT.
    if($field->get_type !~ /int|float|double|date|time/i && ! defined $function) {
      croak "Attempted to use a numerical range for a non-numerical field.\n",
      "Your field [$field_n] in table [$table_n] is of type [",$field->get_type,"], but only [int] or [float] or [double] are accepted.\n";
    }
    # Both min and max are defined
    if($min ne "" && $max ne "") {
      $sql .= qq{ ($sqlfieldstring $lcond "$min" and $sqlfieldstring $rcond "$max") };
    } elsif ($min ne "") {
      $sql .= qq{ ($sqlfieldstring $lcond "$min") };
    } else {
      $sql .= qq{ ($sqlfieldstring $rcond "$max") };
    }
    # Search by RANGE over dates
  } elsif (defined $agerange) {
    if($field->get_type !~ /datetime|time|date|timestamp/i) {
      croak "Attempted to use a date range for a non-date field.\n",
      "Your field [$field_n] in table [$table_n] is of type [",$field->get_type,"], but only [datetime],[time],[date] or [timestamp] are accepted.\n";
    }
    my ($min,$minunit,$max,$maxunit,$lcond,$rcond) 
	= $self->ParseRange($agerange);
    my $minmult=$self->GetAgeUnitMultiplier(\$minunit);
    my $maxmult=$self->GetAgeUnitMultiplier(\$maxunit);
    my $condition;
    my @agesql;
    foreach $condition ([$min,$minunit,$minmult,$lcond],[$max,$maxunit,$maxmult,$rcond]) {
      my $cutoff = $condition->[0];
      my $unit   = $condition->[1];
      my $mult   = $condition->[2];
      my $bool   = $condition->[3];
      if($cutoff ne "") {
	if($cutoff =~ /\d{4}\-\d{2}\-\d{2}/) {
	  if($fieldtype !~ /datetime|date|timestamp/) {
	    print "You tried to apply a date to a field that contains only time and not a date.\n";
	    next;
	  }
	  push(@agesql," (unix_timestamp($field_n) $bool unix_timestamp(\"$cutoff\")) ");
	} elsif($unit eq "d") {
	  push(@agesql," (to_days(now())-to_days($field_n) $bool $cutoff) ");
	} elsif ($unit eq "M") {
	  $cutoff *= 30;
	  push(@agesql," (to_days(now())-to_days($field_n) $bool $cutoff) ");
	} else {
	  $cutoff*=$mult;
	  push(@agesql," (unix_timestamp(now())-unix_timestamp($field_n) $bool $cutoff) ");
	}
      }
    }
    $sql = join(" and ",@agesql);
    $sql = "($sql)";
  } else {
    croak "You must define a search term for the field [$field_n].\n";
  }
  # Add information about this search field to the search object's list.
  push(@{$self->{_searchfields}},
       {'field'=>$field,
	'sql'=>$sql});
}
# AddField END
################################################################

sub DateRefine {

  my $self = shift;
  my $hash = shift || "";
  my $table_n;
  my $field_n;  
  my $function;
  my $filter;
  my $error = "ERROR: Imported::MySQL_Search::DateRefine : ";

  $self->Imported::MySQL_Tools::ArgAssign({'table'=>\$table_n,
				 'field'=>\$field_n,
				 'function'=>\$function,
				 'filter'=>\$filter},
				$hash);

  $self->ParseFieldName(\$field_n,\$table_n,\$function);

  my $table;
  # Check whether the table requested exists  in the database.
  if (! ($table = $self->get_db->GetTable($table_n))) {
    croak "Table [$table_n] (requested for a view) was not found in the database.\n";
  }
  # Make sure this table is either the primary search table for this search,
  # or in the list of fk tables.
  if(! Imported::PerlHelper::IsIn($table_n,$self->get_table->get_name,$self->GetFKTableNames)) {
    croak "Table [$table_n] (requested for a view) was not found in this search.\n";
  }
  # Check whether the field requested exists in the table.
  my $field;
  if($field_n eq "*" || ($field = $table->GetField($field_n))) {
    # The field exists. The "*" field is a special condition which means "all fields"
  } else {
    croak "Field [$field_n] does not exist in the table [$table_n] requested for view.\n";
  }

  if($field->get_type !~ /datetime|date|timestamp/i) {
    croak "$error Attempted to use a date filter for a non-date field.\n",
    "Your field [$field_n] in table [$table_n] is of type [",$field->get_type,"], but only [datetime],[time],[date] or [timestamp] are accepted.\n";
  }
  if($filter =~ /today/i) {
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"TO_DAYS","value"=>"TO_DAYS(CURDATE())"});
  }
  if($filter =~ /tomorrow/) {
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"TO_DAYS","value"=>"TO_DAYS(CURDATE())+1"});
  }
  if($filter =~ /(\+|\-)(\d+)day(s)?/) {
    my $sign=$1;
    my $delta=$2;
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"TO_DAYS","value"=>"TO_DAYS(CURDATE())$sign$delta"});
  }
  if($filter =~ /thisweek/i) {
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"WEEK:1","value"=>'WEEK(CURDATE(),1)'});
    # Exclude past classes.
    if($filter =~ /nopast/) {
      $self->AddField({"field"=>"$table_n.$field_n","agerange"=>"[,0d]"});
    }
  }
  if($filter =~ /lastweek/) {
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"WEEK:1","value"=>"WEEK(DATE_ADD(CURDATE(),INTERVAL -7 DAY),1)"});
  }
  if($filter =~ /nextweek/) {
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"WEEK:1","value"=>"WEEK(DATE_ADD(CURDATE(),INTERVAL 7 DAY),1)"});
  }
  if($filter =~ /weekofday=(\d{4}\-\d{2}\-\d{2})/) {
    my $day = $1;
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"WEEK:1","value"=>"WEEK(\"$day\",1)"});
  }
  if($filter =~ /(\+|\-)(\d+)week(s)?/) {
    my $sign=$1;
    my $delta=$2;
    my $deltadays=7*$delta;
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"WEEK:1","value"=>"WEEK(DATE_ADD(CURDATE(),INTERVAL $deltadays DAY),1)"});
  }
  if($filter =~ /thismonth/) {
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"MONTH","value"=>"MONTH(CURDATE())"});
    if($filter =~ /nopast/) {
      $self->AddField({"field"=>"$table_n.$field_n","agerange"=>"[,0d]"});
    }
  }
  if($filter =~ /nextmonth/) {
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"MONTH","value"=>"MONTH(DATE_ADD(CURDATE(),INTERVAL 1 MONTH))"});
  }
  if($filter =~ /lastmonth/) {
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"MONTH","value"=>"MONTH(DATE_ADD(CURDATE(),INTERVAL -1 MONTH))"});
  }
  if($filter =~ /(\+|\-)(\d+)month(s)?/) {
    my $sign=$1;
    if($sign eq "+") {$sign=""}
    my $months=$2;
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"MONTH","value"=>"MONTH(DATE_ADD(CURDATE(),INTERVAL $sign$months MONTH))"});
    }
  if($filter =~ /month=(.*) year=(\d+)/) {
    my $month=$1;
    my $year=$2;
    # Handle the year first.
    $self->AddField({"field"=>"$table_n.$field_n","function"=>"YEAR","value"=>"$year"});
    # Handle the month.
    # If the month is non-digit, use the monthname function which makes myS\QL return
    # the text-name of the month. Otherwise, use the digit.
    if($month !~ /\d/) {
      $self->AddField({"field"=>"$table_n.$field_n","function"=>"MONTHNAME","regexp"=>"$month"});
    } else {
      $self->AddField({"field"=>"$table_n.$field_n","function"=>"MONTH","value"=>"$month"});
    }
  }
}

=pod

=head2 Specifying Group Criteria
    
Grouping allows for retrieved records to be grouped by common values.
    
=over
    
=item AddGroup({'field'=>"tablename.fieldname"});

This groups the field 'fieldname' in the table 'tablename' by value. Care must be taken when using groups. Make sure that all of the fields you are displaying are being grouped. You cannot do the equivalent of
    
SELECT field1,field2 FROM table1 GROUP BY field1;

because you would be grouping by field1 only. But you could
    
SELECT field1,field2 FROM table1 GROUP BY field1,field2;

which would group by both fields.

=back

=head2 Ordering Retrieved Records

You can specify how the retrieved records will be ordered by the server.

=over

=item Order{'field'=>"tablename.fieldname",'order'=>asc|desc});

Orders by the selected field. The default order is ascending. You can assign the string 'desc' to the 'order' element to make the ordering descending.

=back

=cut

################################################################
# Specifies the order in which the fields are returned.
#
# Viewfields which are acted upon by functions, such as count,
# need to be ordered by their alias. For example,
#
# select count(ID) from ... order by ID         (doesn't work)
# select count(ID) from ... order by count(ID)  (doesn't work)
# select count(ID) as cnt from ... order by cnt (works)
#
sub Order {

  my $self = shift;
  my $hash = shift || "";
      my $field_n;
  my $table_n;
  my $function;
  my $order = "asc";
  $self->Imported::MySQL_Tools::ArgAssign({'field'=>\$field_n,
				 'table'=>\$table_n,
				 'function'=>\$function,
				 'order'=>\$order,
			       },$hash);

  $self->ParseFieldName(\$field_n,\$table_n);

  # Make sure the table is in the database
  my $table;
  if(! ($table = $self->get_db->GetTable($table_n))) {
    croak "Table [$table_n] is not in the database. You cannot order by the field [$field_n] which you said is contained in the table [$table_n].\n";
  }
  # Make sure the table is one of the tables specified in the search
  if(! (Imported::PerlHelper::IsIn($table_n,($self->get_table->get_name,$self->GetFKTableNames)))) {
    croak "Table [$table_n] is not neither the primary table nor in the list of lookuptables for this search. You cannot therefore order by this table.\n";
  }
  my $field;
  # Make sure that the search contains the view field that is asked for. Ordering is done by 
  # view fields. If no view fields are defined, make sure that the database has this field!
  if(! ($self->GetViewFieldNames)) {
    if(! ($field = $table->GetField($field_n))) {
      croak "Your table [$table_n] does not have the field [$field_n] to order by.\n";
    }
  } else {
    if(! ($field = $self->GetViewField($field_n))) {
      croak "Your search does not contain the view field [$field_n].\n";
    }
  }
  # We don't know if we are ordering by the field name or the alias of the field name.
  # The ordername member will let us know.
  push(@{$self->{_orderfields}},
       {'ordername'=>$field_n,
	'field'=>$field,
	'function'=>$function,
	'order'=>$order});
}
# Order END
################################################################

sub Limit {
  my $self = shift;
  my $hash = shift || "";
  my $range;

  $self->Imported::MySQL_Tools::ArgAssign({'range'=>\$range},$hash);

  my ($min,$minunit,$max,$maxunit,$lcond,$rcond) = $self->ParseRange($range);

  if($lcond eq "(") {
    $min+=1;
  }
  if($lcond eq ")") {
    $max-=1;
  }
  $self->set_limit_offset($min);
  $self->set_limit_num($max);
}

################################################################
# Adds a group for fields
sub AddGroup {
  
  my $self = shift;
  my $hash = shift || "";
  my $field_n;
  my $table_n;
  my $fieldname;

  $self->Imported::MySQL_Tools::ArgAssign({'field'=>\$field_n,
				 'table'=>\$table_n,},
				$hash);

  $self->ParseFieldName(\$field_n,\$table_n);

  my $table;
  if(! ($table = $self->get_db->GetTable($table_n))) {
    croak "Table [$table_n] is not in the database. You cannot group by the field [$field_n] which you said is contained in the table [$table_n].\n";
  }
  # Make sure the table is one of the tables specified in the search
  if(! (Imported::PerlHelper::IsIn($table_n,($self->get_table->get_name,$self->GetFKTableNames)))) {
    croak "Table [$table_n] is not neither the primary table nor in the list of lookuptables for this search. You cannot therefore group by this table.\n";
  }
  my $field;
  # Make sure that the table contains the field that is asked for
  if(! ($field = $table->GetField($field_n))) {
    croak "Group table [$table_n] does not contain the search field [$field_n].\n";
  }
  # Make sure that this field is one of the view fields in this search.
  if(! (Imported::PerlHelper::IsIn($field_n,($self->GetViewFieldNames)))) {
    croak "Group field [$field_n] is not a view field in this search.\n";
  }
  push(@{$self->{_groups}},$field);
}
#
################################################################

=pod

=head2 Specifying View Fields

=over 

=item AddViewField({'field'=>'table.field','alias'=>aliasname,'function:args'=>functionname})

The view field is a field that will be retrieved during the search. For the records in the database that match the search, the user can specify which fields of those records to retrieve. If no view fields are specified, all the records are retrieved. 

A view field can have two optional properties: an alias and a function. An alias is a MySQL AS statement, which simply provides another name tag for the field. This name tag is displayed on the formatted HTML tables. In the future, you will be able to remove the display of the actual field name, which could be large, and display only the alias, which is meant for human parsing. 

The function directive assigns a MySQL function to the field. Typically, this would be either 'count' or 'avg', but any function is possible. For example,

SetTable("table1");
AddViewField({'field'=>'field1.table1','alias'=>'Number','function'=>'count'});

would be equivalent to

SELECT count(field1) from table1;

You can pass the function arguments by using, for example,

'function'=>'func_name:10'

This call will pass 10 as the argument to the function func_name and result in an query like

SELECT func_name(field1,10) from table1;

=item DeleteViewFields()

This deletes all the view fields associated with a search.

=back

=cut
    
################################################################
# Add a view field. A view field corresponds to a column entry
# in the table returned by your select statement.
#
# If you are using a function such as 'count' on a field, it's best
# to include an alias, so that ordering and grouping by this field
# can be performed.
#
sub AddViewField {

  my $self = shift;
  my $hash = shift || "";
  my $table_n;
  my $field_n;
  my $alias;
  my $viewsql;
  my $function;

  $self->Imported::MySQL_Tools::ArgAssign({'table'=>\$table_n,
				 'field'=>\$field_n,
				 'alias'=>\$alias,
				 'function'=>\$function},
				$hash);
  # Parse the field input. If it is of the form text1.text2 then take
  # text1 to be the table and text2 to be the field.
  $self->ParseFieldName(\$field_n,\$table_n);

  my $table;
  # Check whether the table requested exists  in the database.
  if (! ($table = $self->get_db->GetTable($table_n))) {
    croak "Table [$table_n] (requested for a view) was not found in the database.\n";
  }
  # Make sure this table is either the primary search table for this search,
  # or in the list of fk tables.
  if(! Imported::PerlHelper::IsIn($table_n,$self->get_table->get_name,$self->GetFKTableNames)) {
    croak "Table [$table_n] (requested for a view) was not found in this search.\n";
  }
  # Check whether the field requested exists in the table.
  my $field;
  if($field_n eq "*" || ($field = $table->GetField($field_n))) {
    # The field exists. The "*" field is a special condition which means "all fields"
  } else {
    croak "Field [$field_n] does not exist in the table [$table_n] requested for view.\n";
  }

  # Now we make a copy of this field to act as a view field for the search. A deep copy is
  # necessary because a single field in the database may give rise to multiple view fields
  # in the search - each with its own individual "function", "tags", etc.

  my $viewfield = $field->clone();

  if(defined $function) {
    $viewfield->set_function($function);
    # See if the function has any arguments.
    if($function =~ /(.*):(.*)/) {
    my $function = 
      $viewsql = "$1($table_n.$field_n,$2)";
    } else {
      $viewsql = "$function($table_n.$field_n)";
    }
  } else {
    $viewsql = "$table_n.$field_n";
  }
  if(defined $alias) {
    $viewfield->set_alias($alias);
    $viewsql .= " as $alias";
  } 
  push(@{$self->{_viewfields}},
       {'field'=>$viewfield,
	'sql'=>$viewsql});
}
# AddViewField END
################################################################

################################################################
# Resets the search
# Deletes all parameters filled by the Execute function. 
# Essentially, you wind up with the same search object that
# you had just before you called Execute().
sub ResetSearch {

  my $self = shift;
  $self->{_viewfields} = undef;
  $self->{_groups} = undef;
  $self->{_orderfields} = undef;
  $self->{_html} = undef;
  $self->{_sql} = undef;
  $self->{_fetchrows} = undef;
  $self->{_benchmark} = undef;
  $self->{_curr_frec} = undef;
  $self->{_frecs} = undef;
  $self->{_nrecs} = undef;
}
#
################################################################

################################################################
# Delete view fields for a search
sub DeleteViewFields {
  my $self = shift;
  $self->set_viewfields(undef);
}
#
################################################################

=pod

=head2 Formatted HTML Output

=over

=item PrintHTML()

The PrintHTML function encapsulate's this module's usefulness for searching. The function produces a nicely formatted HTML table, appropriate for reporting using a browser. The minimalist call PrintHTML() will produce a simple table with no additional formatting features. 

PrintHTML can take various parameters passed in a hash.

"title" - specifies a title

You can specify a title for the table which will be included as a full-width first row.

"summary" - requests a summary

Reports the name of the primary search table and the number of records retrieved.

"bench" - requests benchmark 

Reports the amount of time taken to perform the MySQL query.

"centre" - requests centering

Outputs a centered table.

"excludefields" - exclude retrieved fields by name
"excludetypes" - exclude retrieved fields by type

You may want to retrieve some fields in the search, but not print them in the table. For example, those extra fields could be either binary and/or only used for post-processing. You can exclude fields by name or field type. Assign an array to the "excludefields" or "excludetypes" hash item.

PrintHTML({...,
	   "excludefields"=>["field1","field2","myfield.*"],
	   "excludetypes"=>[".*int.*"],
	   ...});

The list elements are text or regular expressions (Perl type). If the text contains no regular expression elements, it must match exactly. In the example above, the fields named "field1" and "field2" would not be shown in the table. Any fields beginning with "myfield" would also not be shown. All integer fields which have the text "int" in their type would also be excluded.

"formatfields" - text-format (using sprintf) fields by name
"formattypes" - text-format (using sprintf) fields by type

You can format the way the field is reported by using these elements. By passing a format string understood by sprintf, you can either truncate or numerically cast the field output. For example,
    
PrintHTML({...,
	   "formattypes"=>{"float"=>"%5.1f"},
	 });

would format all floats to numbers with one decimal place and total length 5. "formatfields" and "formattypes" are passed hashes, with keys being either the field name (must match exactly) or field type (can be a substring match) and values being the associated sprintf format text.

"extratagsfields" - assigns additional html tags to the fields by name
"extratagstypes" - assigns additional html tags to the fields by type

These elements are probably the most useful - they allow you to format the field columns or field value cells themselves depending on name and type. Soon, value-based formatting will be implemented. As for "formatfielsd" and "formattypes" these elements are assigned a hash with the values being specifically encoded tag directives. The tag directives are of the format

"column_tag|pre_value_tag%%SCOPE%%post_value_tag"

The "column_tag" is the tag that is incorporated into the field\'s column HTML tag. The HTML column is specified by <td> and this tag goes <td HERE>. For example, to center-align all integers, use

"extratagstypes"=>{"int"=>"align=center|"}

so that columns for integers will show up as <td align=center>.

The pre_value_tag and post_value_tag are html tags that are designed to flank the current value cell contents. If SCOPE=ALL then the tags enclose all contents, including previous extra tags. If SCOPE=VALUE then the tags enclose only the field value and not any tags. 

"column_tag", "pre_value_tag", SCOPE and "post_value_tag" are all optional. If SCOPE is not given then it is assumed to be VALUE.

Some examples should clarify this. Suppose we have a field named "field1", aliased as "myfield", of type "int(4)" and its value is 1234. We will have a table with a column header which will include the field name and the alias. The particular cell for that field will just show 1234 with no formatting and have the HTML code <td>%%VALUE%%></td> = <td>1234</td>.

"extratagsfield"=>{"field1"=>"var1="};

will assign "var1" to the pre_value_tag. Since SCOPE is missing, SCOPE is assumed VALUE. Thus the HTML code for that cell will be <td>var1=1234</td>. If we use SCOPE and specify

"extratagsfield"=>{"field1"=>"var1=%%VALUE%% km"};

then the column will show <td>var1=1234 km</td>. Or possibly just,

"extratagsfield"=>{"myfield"=>"%%VALUE%% km"};

which will make the cell <td>1234 km</td>. Notice that using the alias as well as the field name is equivalent.

Now, let"s examine how SCOPE really becomes useful. Suppose we want to bold all integers.

"extratagstypes"=>{"int"=>"<b>%%VALUE</b>"};

This will make all integer cells into <td><b>%%VALUE</b></td>, or for our particular cell <td><b>1234</b></td>. Now suppose we also want to include the "var1=" and "km" pre_ and post_value fields but we don"t want these bolded. Then we would also include

"extratagsfield"=>{"field1"=>"var1=%%ALL%% km"};

This call would put "var1=" before everything in the cell for that field, including the <b> tag and " km" after everything, which would be after the </b> tag, resulting in a cell <td>var1=<b>1234</b> km</td>. If we had said

"extratagsfield"=>{"field1"=>"var1=%%VALUE%% km"};

we would get <td><b>var1=1234 km</b></td> with the "var1=" and " km" strings being put around the field value and not the cell contents.

SCOPE applies only to the cell format and not the column format. You can add a column format by preceeding the format string with a pipe (|). For example,

"extratagsfield"=>{"field1"=>"class=vdarkblue|var1=%%VALUE%% km"};   

would produce a column <td class=vdarkblue>var1=1234 km</td>.

=back

=cut

################################################################
# Pretty HTML printing
#
sub PrintHTML {

  my $self = shift;
  my $hash = shift || "";
  my $title;
  my $summary;
  my $center;
  my $bench;
  my $links;
  my $printfieldname = 0;
  my $printfieldtype = 0;
  my $excludefields;
  my $excludetypes;
  my $formatfields;
  my $formattypes;
  my $extratagsfields;
  my $extratagstypes;

  $self->Imported::MySQL_Tools::ArgAssign({'title'=>\$title,
				 'summary'=>\$summary,
				 'center'=>\$center,
				 'bench'=>\$bench,
				 'links'=>\$links,
				 'printfieldname'=>\$printfieldname,
				 'printfieldtype'=>\$printfieldtype,
				 'excludefields'=>\$excludefields,
				 'excludetypes'=>\$excludetypes,
				 'formatfields'=>\$formatfields,
				 'formattypes'=>\$formattypes,
				 'extratagsfields'=>\$extratagsfields,
				 'extratagstypes'=>\$extratagstypes,
			       },$hash);

  my $tablename = $self->get_table->get_name;
  if (defined $center) { $self->HTMLAdd("<center>") }
  $self->HTMLAdd("<table border=0 cellspacing=0 cellpadding=0><tr><td class='darkgrey'>");
  $self->HTMLAdd("<table border=0 cellspacing=1 cellpadding=3>");
  # Construct the list of fields used for the columns in the table.
  my @colfields;
  # MINUS the number of excluded fields
  my $viewfield;
  my $field;
  foreach $viewfield (@{$self->get_viewfields}) {
    $field = $viewfield->{'field'};
    # Make sure this field is not to be excluded.
    if($self->IsFieldInNameList($field,@{$excludefields})) {
      next;
    }
    # Make sure that this field's type is not to be excluded.
    if($self->IsFieldInTypeList($field,@{$excludetypes})) {
      next;
    }
    # Check if the field exists (by type) in the extratagstypes hash. If so,
    # assign it the specified tag.
    my $tagtype;
    foreach $tagtype (keys %{$extratagstypes}) {
      if($field->get_type =~ /$tagtype/) {
	# Parse the user tags.
	$field->set_tags($extratagstypes->{$tagtype});
      }
    }
    # Check if the field exists (by name or alias) in the extratagsfields hash. If so,
    # assign it the specified tag. As with the format, tags of names have higher
    # precedence than tags of types.
    my $tags;
    if(defined $extratagsfields->{$field->get_name}) {
      $tags = $extratagsfields->{$field->get_name};
      $field->set_tags($tags);
    } elsif (defined $extratagsfields->{$field->get_alias}) {
      $tags = $extratagsfields->{$field->get_alias};
      $field->set_tags($tags);
    }
    # Check if the field exists (by type) in the formattypes hash. If so,
    # assign it the specified format.
    my $formattype;
    foreach $formattype (keys %{$formattypes}) {
      if($field->get_type =~ /$formattype/) {
	$field->set_format($formattypes->{$formattype});
	last;
      }
    }
    # Check if the field exists (by name or alias) in the formatfields hash.
    # The format-by-name wins over format-by-type, since presumably the latter
    # is more general.
    if(defined $formatfields->{$field->get_name}) {
      $field->set_format($formatfields->{$field->get_name});
    } elsif (defined $formatfields->{$field->get_alias}) {
      $field->set_format($formatfields->{$field->get_alias});
    }
    push(@colfields,$field);
  }
  my $col_n = @colfields;
  # MINUS the number of excluded types
  # If a title is requested, create a long row and print the title.
  if (defined $title) {
    $self->HTMLAdd(
		   "<tr>",
		   "<td align=center colspan=$col_n class=vlightbluebw>",
		   "<span class=vlarger><b>",
		   $title,
		   "</b></span>",
		   "</td>",
		   "</tr>");
  }
  # The summary, if requested, contains the table name and number of records.
  if (defined $summary) {
    $self->HTMLAdd(
		   "<tr>",
		   "<td colspan=$col_n class=vlightgreenbw>",
		   "Table: <b>",$tablename,"</b>",
		   "&nbsp;&nbsp; ",
		   "Batch Size: <b>",$self->get_nrecs,"</b>",
		   "</td>",
		   "</tr>");
  }
  foreach $field (@colfields) {
    my $headerline=0;
    $self->HTMLAdd(
		   "<td class=vdarkblue valign=center align=center style='padding:3px;'>",
		   "<span class=small>");
    if ($printfieldname || ! defined $field->get_alias) {
      $self->HTMLAdd("<span class=$printfieldname><b>", $field->get_name, "</b></span><br>");
      $headerline++;
    }
    if ($field->get_alias) {
      $self->HTMLAdd("<b>", $field->get_alias, "</b><br>");
      $headerline++;
    }
    if ($printfieldtype) {
      $self->HTMLAdd("<span class=$printfieldtype>", $field->get_type, "</span>");
    }
    $self->HTMLAdd("</span></td>");
  }
  $self->HTMLAdd("</tr>");

  while ($self->ForEachRecord()) {
    # "What manner of wizardy is this?"
    # There is another PrintHTML function in MySQL_Record
    $self->HTMLAdd( $self->get_record->PrintHTML($links,@colfields) );
    if($self->get_frecs > 100) {
      last;
    }
  }
  $self->HTMLAdd("</table>");
  $self->HTMLAdd("</td></tr></table>");
  if(defined $bench) {
    $self->HTMLAdd(
		   "<span class=small>Search time: ",
		   $self->get_benchmark,
		   "</span>");
  }
  if(defined $center) { $self->HTMLAdd("</center>") }

  print $self->get_html;

}

################################################################
# Associates an SQL statement with the search object and
# prepares the object's statement handle. The statement handle
# is created using the objects' MySQLdb object (get_db) which
# is then polled for its handle (get_dbhandle). The DBI
# prepare() function is then executed, which returns a statement
# handle stored in MySQL_Search::_sthandle.
sub SQL {
  my $self = shift;
  my $sth;
  if (defined $_[0]) {
    $self->set_sql($_[0]);
    $sth = $self->get_db->get_dbhandle->prepare($self->get_sql);
    $self->set_sthandle($sth);
  }
  $self->get_sql();
} 
#
################################################################

sub HTMLAdd {
  my $self = shift;
  my $newline;
  foreach $newline (@_) {
    $self->set_html($self->get_html . $newline . "\n");
  }
}

=pod

=head2 Formatted Console Output

This prints diagnostics about the search element. It lists things such as the search\'s SQL statement, search fields, FK fields, view fields, benchmark information, records found etc.

=over

=item Print()

Prints the elements of a search object. For example,

    ##### Search ###############################
    Name : s1
    SQL : SELECT * FROM Equipment
    Table : Equipment
    View Fields : Equipment_ID,Equipment_Name
    Status : executed
    Search Time :  0 wallclock secs 
    Records found : 45
    Records fetched : 0
    ############################################

=back

=cut

################################################################
# Pretty print for stdout. 
#
sub Print {

  my $self = shift;
  my $flag = shift || "";

  if($flag =~ /html/) {print "<pre>";}
  print "##### Search ###############################\n";
      print "            Name : ",$self->get_name,"\n";
  if($self->get_sql) {
    my $sql = $self->get_sql;
    $sql =~ s/(.{50,100}\s)/$1\n/g;
    print "             SQL : ",$sql,"\n";
  }
  if(defined $self->get_tablename) {
    print "           Table : ",$self->get_tablename,"\n";
  } 
  if(defined $self->get_fktables) {
    print "       FK Tables : ",join(",",$self->GetFKTableNames),"\n";
  }
  if(defined $self->get_searchfields) {
    print "   Search Fields : ",join(",",$self->GetSearchFieldNames),"\n";
  }
  # Print the view fields.
  if(defined $self->get_viewfields) {
    my $viewfield;
    my @viewfieldlist;
    my $field;
    foreach $viewfield (@{$self->get_viewfields}) {
      $field = $viewfield->{'field'};
      # If there is an alias for this view field then print alias=fieldname
      if(defined $field->get_alias) {
	# If there is a function that evaluates this field, such as avg or count,
	# print alias=function(fieldname).
	if(defined $field->get_function) {
	  push(@viewfieldlist,
	       $field->get_function."(".$field->get_name.")=".$field->get_alias);
	} else {
	  push(@viewfieldlist,$field->get_name."=".$field->get_alias);
	}
      } else {
	if(defined $field->get_function) {
	  push(@viewfieldlist,
	       $field->get_function."(".$field->get_name.")");
	} else {
	  push(@viewfieldlist,$field->get_name);
	}
      }
    }
    print "     View Fields : ",join(",",@viewfieldlist),"\n";
  }
  # Print groups
  if(defined $self->get_groups) {
    my $groupfield;
    my @groupfieldlist;
    foreach $groupfield (@{$self->get_groups}) {
      push(@groupfieldlist,$groupfield->get_name);
    }
    print "    Group fields : ",join(",",@groupfieldlist),"\n";
  }
  if(defined $self->get_nrecs) {
    print "          Status : executed\n";
    print "     Search Time : ",$self->get_benchmark,"\n";
    print "   Records found : ",$self->get_nrecs,"\n";
    print " Records fetched : ",$self->get_frecs,"\n";
  } else {
    print "          Status : not executed\n";
  }
  print "############################################\n";
  if($flag =~ /html/) {print "</pre>";}

}
#
################################################################

################################################################
# 
#
sub IsFieldInNameList {
  my $self  = shift;
  my $field = shift;
  my $fieldname;
  foreach $fieldname (@_) {
    if($field->get_name =~ /^$fieldname$/i || (
					       defined $field->get_alias &&
					       $field->get_alias =~ /^$fieldname$/i)) {
      return 1;
    }
  }
  return 0;
}
sub IsFieldInTypeList {
  my $self  = shift;
  my $field = shift;
  my $fieldtype;
  foreach $fieldtype (@_) {
    if($field->get_type =~ /^$fieldtype$/i) {
      return 1;
    }
  }
  return 0;
}
#
################################################################

################################################################
# Checks whether the supplied fieldname belongs to one of the
# view fields.
sub IsViewField {
  my $self = shift;
  my $field_n = shift;
  my $field;
  foreach $field (@{$self->get_viewfields}) {
    if($field->get_name eq $field_n || (defined $field->get_alias && 
					$field->get_alias eq $field_n)) {
      return 1;
    }
  }
  return 0;
}

################################################################
# Parses the the fieldname and extracts the field/table
# from it. If the fieldname is passed to it (first argument)
# of th form text1.text2 then text1 is taken to be the table
# and text2 to be the field.
sub ParseFieldName {
  my $self = shift;
  my $field_n_r=shift;
  my $table_n_r=shift;
  my $function_r=shift;
  # If the field is of the form text1.text2, then chop this up and
  # treat it as table.field
  if($$field_n_r =~ /(.*?)\.(.*)/) {
    $$table_n_r = $1;
    $$field_n_r = $2;
  }
  # If the field is not of this form, and the table name is not
  # defined, then set the table name to be the primary table
  # of this search
  elsif (! defined $$table_n_r || $$table_n_r eq "") {
    $$table_n_r = $self->get_table->get_name;
  }
}
#
################################################################


sub GetFKTableNames {

  my $self = shift;
  my @fktablenames; 
  if(defined $self->get_fktables) {
    my $fktable;
    foreach $fktable (@{$self->get_fktables}) {
      push(@fktablenames,$fktable->get_name);
    }
  }
  return @fktablenames;
}


sub GetSearchFieldNames {

  my $self = shift;
  my @fieldnames; 
  if(defined $self->get_searchfields) {
    my $searchfield;
    foreach $searchfield (@{$self->get_searchfields}) {
      push(@fieldnames,$searchfield->{'field'}->get_name);
    }
  }
  return @fieldnames;
}

sub GetViewField {

  my $self = shift;
  my $fieldname = shift;
  my $field = undef;
  my $viewfield;
  foreach $viewfield (@{$self->{_viewfields}}) {
    $field = $viewfield->{'field'};
    if ($field->get_name eq $fieldname || 
	$field->get_alias eq $fieldname) {
      return $field;
    }
  }
  return undef;
}

sub GetViewFieldNames {

  my $self = shift;
  my @viewfieldnames; 
  if(defined $self->get_viewfields) {
    my $viewfield;
    foreach $viewfield (@{$self->get_viewfields}) {
      push(@viewfieldnames,$viewfield->{'field'}->get_name);
    }
  }
  return @viewfieldnames;

}

#
################################################################

sub Imported::MySQL_Search::DESTROY {

  my $self = shift;

}

sub Imported::MySQL_Search::AUTOLOAD {

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
