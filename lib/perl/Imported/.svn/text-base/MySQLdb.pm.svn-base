################################################################
# $Id: MySQLdb.pm,v 1.1 2003/04/10 23:59:07 achan Exp $
################################################################
#
# CVS Revision: $Revision: 1.1 $ 
# Commit date:  $Date: 2003/04/10 23:59:07 $
#         Tag:  $Name:  $
#      Author:  $Author: achan $
#
################################################################

package Imported::MySQLdb;

################################################################
# A MySQL database class

=pod

=head1 NAME

MySQLdb - A wrapper module for the DBI Perl interface to a MySQL database.

=head1 SYNOPSIS

This module is actively being developed. The documentation only lists core functionality and is probably somewhat out of date.

The module abstracts the idea of a database, a table, a field and a search. Currently, you cannot use this module to add or update records. Its main function is to cast queries and format them nicely for HTML.

  use Imported::MySQLdb;

  $db = Imported::MySQLdb->new();
  $db->Connect({'user'=>'viewer',
                'server'=>'lims-dbm',
                'pass'=>'******',
                'db'=>'sequence'});

  # Table/field access functions

  # Pull out one table
  $db->GetTable("Run")->Print();
  # Iterate over all the tables
  while($table=$db->ForEachTable) {
     $table->Print;
  }
  # Get an array of all the tables (like iteration above, but
  # gives access to all tables at the same time)
  foreach $table ($db->GetAllTables) {
     $table->Print;
  }
  # Search for a field by name using a regexp.
  foreach $field ($db->FindField("Se.*ce")) {
     $field->Print;
  }

  # Searching
  # Create the search object
  $s1 = $db->CreateSearch("search1");
  # Now you have a search object! You can interrogate the database using 
  # the functionality of the MySQL_Search module. An example of its use
  # is shown below, but the man page of that module contains more information.
  # Assign the primary search table
  $s1->SetTable("Clone_Sequence");
  # Assign any foreign key relationships
  $s1->AddFK({'field'=>'Run.ID'});
  $s1->AddFK({'field'=>'RunBatch.ID'});
  $s1->AddFK({'field'=>'Equipment.ID','fktable'=>'RunBatch'});
  $s1->AddFK({'field'=>'Employee.ID','fktable'=>'RunBatch'});
  # Assign view fields
  $s1->AddViewField({'field'=>'Employee.Employee_Name','alias'=>'Name'});
  $s1->AddViewField({'field'=>'Equipment.Equipment_Name','alias'=>'Sequencer'});
  $s1->AddViewField({'field'=>'Sequence_Length',function=>'avg',alias=>'Average'});
  $s1->AddViewField({'field'=>'FK_Run__ID',function=>'count',alias=>'N_Reads'});
  # Define ordering
  $s1->Order({'field'=>'Equipment.Equipment_Name','order'=>'asc'});
  $s1->Order({'field'=>'Sequence_Length','order'=>'desc'});
  # Define grouping
  $s1->AddGroup({'field'=>'Employee.Employee_Name'});
  $s1->AddGroup({'field'=>'Equipment.Equipment_Name'});
  # Execute the search
  $s1->Execute();
  # Pretty HTML print
  $s1->PrintHTML({
    'title'=>"Test title",
    'summary'=>"Test Summary",
    'center'=>"yes",
    'bench'=>"yes",  
    'excludefields'=>[],
    'excludetypes'=>[],
    'formatfields'=>{'Average'=>'%6.1f'},
    'formattypes'=>{'float'=>'%10.5f','int'=>'%06d'},
    'extratagsfields'=>{'Average'=>'align=center|%%ALL%% bp',
		      'N_Reads'=>'align=center|',
		      'Sequencer'=>'align=center|',
		      'Name'=>'align=right class=vvlightred|',
		      },
    'extratagstypes'=>{'.*text.*'=>'|<b>%%VALUE%%</b>'},
  });

  # Print all the search objects
  while($search=$db->ForEachSearch) {
     $search->Print;
  }


=head1 DESCRIPTION

This module abstracts the DBI routines to facilitate high-level manipulation of a MySQL database and its data. 

=head2 General Usage

The DBI Perl module is used at the GSC to interface Perl scripts with MySQL databases. The DBI module still requires the programmer to pass SQL commands to DBI functions. Constructing large SQL commands can be tedious. This module is designed to obviate such constructs by providing the programmer with high-level functions which synthesize SQL queries, updates, inserts, and deletes.

=head2 Design

Just as the DBI interface creates database and statement handles, so does this module. The user creates a database handle by calling the new() function. All further calls to the module are done through this handle.

Any functions that are defined generally take hashes as arguments to provide an argument naming scheme. For example, a function myfunc can be called like

    myfunc({'var1'=>10,'var2'=>"twenty"});

In this example, myfunc takes two parameters: var1 and var2. They are being assigned the values 10 and "twenty", respectively. 

The order of parameters in the hash is not important. Some functions will hava a set of compulsory parameters, with others being optional. Make sure you provide a complete set of compulsory parameters.

=cut

use Imported::MySQL_Table;
use Imported::MySQL_Field;
use Imported::MySQL_Record;
use Imported::MySQL_Search;
use Imported::MySQL_Tools;
use Imported::PerlHelper;
use strict;
#@@@use Date::Parse;
use POSIX qw(strftime);
use DBI;
use Carp;
use vars '$AUTOLOAD';

=pod 

=head2 Initializer

The initializer creates the database object using the appropriate login information.

=over

=item Connect()

To connect to the MySQL database you use the Connect() function, passing it your server name (or file), user name, password (or file) and database name. If you want to re-connect, you will have to create a new database object using another invocation of Connect(). If you cannot log into the database, make sure that you have your credentials correct. 

Instead of supplying a password, you can supply a file which contains the password (unencrypted) as its sole line. If you make this file readable only by the person that is running the script it''s a little more secure.

Instead of supplying a server, you can supply a file which contains a list of database and server pairs. Your requested database is searched in the file and the associated server(s) are then used to form the connection. The file must be of the form

database1  server1

.*base2    server1,backupserver2

olddata    backupserver2

.*         server1,backupserver2

The first field on a line is a Perl-type regular expression to match against the database name. The second field is a comma-delimited list of servers to use for connections to this database. As soon as a database matches a line, the rest of the file is not processed. The last line is a catch-all case for all databases that did not match any regexps.

=back

=cut

################################################################
# CVS headers and variables: VERSION(=revision), TAG and DATE.
# The date is formatted to the local time zone.
$Imported::MySQLdb::VERSION = q{ $Revision: 1.1 $ };
$Imported::MySQLdb::CVSTAG  = q{ $Name:  $ };
$Imported::MySQLdb::CVSDATE = q{ $Date: 2003/04/10 23:59:07 $ };
if($Imported::MySQLdb::VERSION =~ /\$.*?:\s*(.*?)\s*\$/) {
  $Imported::MySQLdb::VERSION=$1;
}
if($Imported::MySQLdb::CVSDATE =~ /\$.*?:\s*(.*?)\s*\$/) {
  $Imported::MySQLdb::CVSDATE=$1;
}
#@@@$MySQLdb::CVSDATE_gmttime = str2time($MySQLdb::CVSDATE);
$Imported::MySQLdb::CVSDATE_gmttime -= 3600*8;
$Imported::MySQLdb::CVSDATE = strftime "%Y-%b-%d %H:%M",localtime($Imported::MySQLdb::CVSDATE_gmttime);
if($Imported::MySQLdb::CVSTAG =~ /\$.*?:\s*(.*?)\s*\$/) {
  $Imported::MySQLdb::CVSTAG=$1;
}
################################################################

sub new {

  my ($class) = @_;
  
  my $self = {
	  _server     => undef,
	  _user       => undef,
	  _password   => undef,
	  _dbname     => undef,    
	  _dbhandle   => undef,
	  _sthandle   => undef,
          _tables     => undef,
          _searches   => undef,
	  _debug      => 0,
	  };
  
  bless $self,$class;

  return $self;

}

{
  my %_attrs =
    ( 
      _server   => 'read/write',
      _user     => 'read/write',
      _password => 'read/write',
      _dbname   => 'read/write',
      _dbhandle => 'read/write',
      _sthandle => 'read/write',
      _tables   => 'read/write',
      _searches => 'read/write',
      _debug    => 'read/write',
    );
  sub _accessible {
    my ($self,$attr,$mode) = @_;
    $_attrs{$attr} =~ /$mode/;
  }
}

=pod

=head2 Iterators

Iterators are functions which loop over every element in a list
of structures which the database contains. It is semantically
equivalent to a 'foreach' Perl statement. For example, a database
will typically contain a list of tables. By using

  while($table = $db->ForEachTable()) {
    ...do something with $table
  }

one loops over all existing tables in the database. 

NOTE: Currently the iterator functionality is primitive. If one quits
in the middle of the iterator, the next time the iterator is used it will
pick up where it left off - not from the first item list.

=over

=item ForEachSearch()

Iterator over all search objects contained in the database.

=back

=cut

################################################################
# A Search Iterator
#
sub ForEachSearch {

  my $self = shift;
  my $idx;
  nextsearch($self);
  sub nextsearch
  {
    my $self = shift;
    if(! defined $idx) {
      $idx = 0;
    }
    elsif ( $idx eq $#{$self->{_searches}}) {
      $idx = -1;
      return 0;
    } else {
      $idx ++;
    }
    return ${$self->{_searches}}[$idx];
  }
}

=pod

=over

=item ForEachTable()

Iterator over all search tables contained in the database.

=back

=cut

################################################################
# A Table Iterator
#
sub ForEachTable {

  my $self = shift;
  my $idx;
  nexttbl($self);
  sub nexttbl
  {
    my $self = shift;
    if(! defined $idx) {
      $idx = 0;
    } elsif ( $idx eq $#{$self->{_tables}}) {
      $idx = -1;
      return 0;
    } else {
      $idx ++;
    }
    return ${$self->{_tables}}[$idx];
  }
}
# end ForEachTable
################################################################

################################################################
# GetX Functions
################################################################

=pod

=head2 Accessors

Data accessors fetch member objects from the database.
Some objects are fetched by name, others by other
uniquely-determining characteristics.

=over

=item GetTable(tablename)

Returns the table named 'tablename' from the database. Returns 
undef if this table does not exist.

=back

=cut

################################################################
# A Table Fetcher
#
# Returns a table with name $tablename, otherwise returns undef.
#
sub GetTable {
  my $self = shift;
  my $tablename = shift;
  my $tbl = undef;
  foreach $tbl (@{$self->{_tables}}) {
    if ($tbl->get_name eq $tablename) {
      return $tbl;
    }
  }
  return undef;
}
#
################################################################

=over

=item GetAllTables

Returns an array of all table objects in the database. Each
element is a MySQL_Table object and can be use to call methods
in that class.

@list = $db->GetAllTables;
foreach $table (@list) {
  print $table->get_name,"\n";
}

This code is equivalent to

while($table=$db->ForEachTable) {
  print $table->get_name,"\n";
}

The GetAllTables accessor is useful if you want to read in the 
table list for manipulation, rather than iterating through the
list everytime with ForEachTable.

=back

=cut


################################################################
# A Table List
#
# Returns an array of all table objects in the database. 
#
sub GetAllTables {
  my $self = shift;
  my $tbl = undef;
  my @tablelist;
  foreach $tbl (@{$self->{_tables}}) {
    push(@tablelist,$tbl);
  }
  return @tablelist;
}
#
################################################################

=pod

=over

=item Search(name)

Retrieves a search element named by 'name' from the
database. Returns undef is such element is not found.

=back

=cut

###############################################################
# A search object fetcher
#
sub Search {

  my $self = shift;
  my $searchname = shift;
  my $search = undef;
  foreach $search (@{$self->{_searches}}) {
    if ($search->get_name eq $searchname) {
      return $search;
    }
  }
  return undef;
}
#
################################################################

################################################################
# Find Functions
################################################################

################################################################
# Finds all fields in the database satisfying the supplied
# regular expression (case insensitive). 
#
# Returns an array of MySQLdb_Field objects.

=pod

=head2 Find functions

=over

=item FindField()

This function returns a list of fields in the database whose names match the supplied regular expression. Each field can be polled for its table owner to further refine this. This function is basically a wrapper for the ForEachTable db iterator and a ForEachField table iterator.

=back

=cut

sub FindField {

  my $self = shift;
  my $fieldname = shift;
  my @fieldlist;
  my $tbl   = undef ;
  my $field = undef;
  while($tbl = $self->ForEachTable) {
    while($field = $tbl->ForEachField) {
      if($field->get_name =~ /$fieldname/i) {
	push(@fieldlist,$field);
      }
    }
  }
  return @fieldlist;
}
#
################################################################

################################################################
# Search Functions
################################################################

=pod

=head2 Searching the Database

The module implements the MySQL_Search object, which is
coded in the MySQL_Search.pm module. This object models
a typical search process.

=over

=item CreateSearch(name)

Creates a uniquely 'name'ed search. A database can have
many search processes, or objects.

For a complete description of searching, refer to the
man page for MySQL_Search

=cut 

sub CreateSearch {
  my $self = shift;
  my $name = shift;
  my $search = Imported::MySQL_Search->new($self,$name);
  push(@{$self->{_searches}},$search);
  return $search;
}

################################################################
# Stores the schema of the database. Populates the table objects
# and their field objects. This is automatically called upon
# a successful connect.
sub GetTables {

  my $self = shift;
  my $sql = "show tables";
  my $sth = $self->get_dbhandle->prepare($sql);
  $sth->execute();
  my $table;
  my $ref;
  while ($ref=$sth->fetchrow_hashref()) {
    # Get the table name
    $table = (values %{$ref})[0];
    # Create the table and push it onto the table list
    my $dbtable = Imported::MySQL_Table->new($table);
    push(@{$self->{_tables}},$dbtable);
    # Look up the table in the database and fetch fields
    my $sql = "describe $table";
    my $sth_field = $self->get_dbhandle->prepare($sql);
    $sth_field->execute();
    # For every field in the table, add it to the table object
    my $ref_field;
    while($ref_field=$sth_field->fetchrow_hashref()) {
      $dbtable->AddField($ref_field);
    }
  }
  $sth->finish();
}
#
################################################################

################################################################
# Handle the module's debug flag. Use this function to set
# or fetch the flag:
# 
# MySQLdb->Debug(1) set and fetch
# MySQLdb->Debug    fetch only
sub Debug {
  my $self = shift;
  my $flag = shift;
  if(defined $flag) {
    $self->set_debug($flag);
  }
  return $self->get_debug;
}

sub PrintDebug {
  my $self = shift;
  my $text = shift;
  if($self->Debug()) {
    print "$text\n";
  }
}
################################################################

################################################################
# Connect to the database.
# Set the _server, _password, _dbname and _user members
# Set the _dbhandle member

sub Connect {

  my $self = shift;
  my $hash = shift || "";
  my $server; 
  my $db    ;
  my $user  ;
  my $pass  ;
  my $servdbfile;
  my $errormsg = "ERROR: Imported::MySQLdb::Connect :";
  my $error=0;

  $self->Imported::MySQL_Tools::ArgAssign({'user'=>\$user,'pass'=>\$pass,
				 'server'=>\$server,'db'=>\$db},
				$hash);

  # There are two ways of passing your password to the script. One is through
  # a file. In this case, the 'pass' field is a filename. The other is to
  # pass the password as a string by using the 'pass' parameter
  #
  # e.g. 'pass'=>'/path/to/my/password'  # point to a file
  #      'pass'=>'mypassword'            # just write the password

  if(-e $pass) {
    if (-r $pass) {
      open(PASS,$pass);
      while(<PASS>) {
	if(/^\s*\#/) {next}
	$pass = $_;
	$pass =~ s/\n//g;
	last;
      }
    } else {
      $error=1;
      $self->PrintDebug("$errormsg You have no read access to the password file.");
      return undef;
    }
  }
  
  # There are two ways of figuring out what the server is.
  # One is to pass a file to 'server' which contains a list of database-server
  # pairs. The script will then choose what server to pick based on the database.
  # The other is to pass the server name to the parameter directly.

  my ($dsn,$dbh);
  if(-e $server) {
    if(-r $server) {
      open(FILE,$server);
      my @servers;
      while(<FILE>) {
	if(m|^\#|) {next}
	# grab the database regexp and server string
	my ($dbstring,$servlist) = split(/\s+/,$_);
	# if the database we want matches the regexp, parse the server string
	if($db =~ $dbstring) {
	  @servers = split(",",$servlist);
	  $self->PrintDebug("$db matched : [$dbstring]");
	  $self->PrintDebug("served by ".($#servers+1)." servers: ".join(" ",@servers));
	  last;
	}
      }
      close(FILE);
      # We've now found the server set that we want.
      # for every server in the server set, try connecting
      foreach $server (@servers) {
	$dsn = "DBI:mysql:database=$db:$server";
	$dbh = DBI->connect($dsn,$user,$pass,{PrintError=>0,RaiseError=>0});
	if(! $dbh) {
	  $self->PrintDebug("Connection error: [$server] ",$DBI::errstr);
	  return undef;
	}
	if($dbh) {
	  # successful connection. return the database handle
	  $self->PrintDebug("Connected to $server");
	  $self->set_server($server);
	  last;
	}
      }
    } else {
      $error=1;
      $self->PrintDebug("$errormsg You have no read access to the database-server file.");
      return undef;
    }
  } else {
    $dsn = "DBI:mysql:database=$db:$server";
    $dbh = DBI->connect($dsn,$user,$pass,{PrintError=>0,RaiseError=>0});
    if(! $dbh) {
      $self->PrintDebug("$errormsg Could not connect to the database.");
      return undef;
    }
    $self->set_server($server);
  }
  $self->set_dbname($db);
  $self->set_password($pass);
  $self->set_user($user);
  $self->set_dbhandle($dbh);
  $self->GetTables;
  return $dbh;
}
#
################################################################


################################################################
# Old code. This isn't used anymore
sub Prepare {
  my $self = shift;
  my $sql  = shift;
  $self->set_sthandle($self->get_dbhandle->prepare($sql));
}
sub Execute {
  my $self = shift;
  my @arg  = @_;
  $self->get_sthandle->execute(@arg);
}
#
################################################################


################################################################
# Automated functions. 
# Do not edit below this point, unless you know what you are
# doing.
sub Imported::MySQLdb::DESTROY {

  my $self = shift;
  $self->get_dbhandle()->disconnect();

}

sub Imported::MySQLdb::AUTOLOAD {

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
# END
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

Find''em and crush''em.

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

There was some problems with using fields in conjunction with functions on fields, such as avg or count. I have fixed the way that search and view fields are stored so that this isn''t a problem any more. Make sure you understand how ordering and grouping is done on fields which are evaluated by such functions!

=back

=cut
