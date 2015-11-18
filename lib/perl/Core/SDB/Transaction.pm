###################################################################################################################################
# Transaction.pm
#
# Object that provides database transaction functionalities
#
# $Id: Transaction.pm,v 1.7 2004/11/30 01:44:11 rguin Exp $
###################################################################################################################################
package SDB::Transaction;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Transaction.pm - Object that provides database transaction functionalities

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Object that provides database transaction functionalities<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;
use RGTools::RGIO;

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use SDB::CustomSettings;
use RGTools::Object;
use RGTools::Conversion;

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

### Modular variables

### Constants

############################################################
# Constructor of the object
# RETURN: The object itself
############################################################
sub new {
############
    my $this = shift;
    my $class = ref($this) || $this;

    my %args    = @_;
    my $frozen  = $args{-frozen} || 0;     # Reference to frozen object if there is any (optional) [Object]
    my $encoded = $args{-encoded} || 0;    # Flag indicate whether object was encoded (optional) [Bool]

    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle (optional) [Object]

    ### Connection parameters ###

    my $self = $this->Object::new( -frozen => $frozen, -encoded => $encoded );
    $self->{dbc} = $dbc;

    unless ($dbc) { Message("Error must supply connection"); return; }

    $self->{saveRaiseError} = $self->dbh()->{RaiseError};
    $self->{savePrintError} = $self->dbh()->{PrintError};
    $self->{saveAutoCommit} = $self->dbh()->{AutoCommit};
    $self->{debug}          = 0;

    $self->reset(0);

    return $self;
}

###########
sub DESTROY {
###########L
    my $self = shift;

    if ( @{ $self->errors } ) {
        foreach my $t_error ( @{ $self->errors } ) {

            #	    $self->transactions("Error: $t_error");
            #	    Message("ERROR: ($t_error)");
        }
    }

    $self->restore();

    return;
}

#############
sub reset {
#############
    my $self    = shift;
    my $started = shift;

    $self->{started}                     = $started;    # Indicate whether a transaction has started
    $self->{errors}                      = [];          # An arrayref to the list of transaction errors
    $self->{error}                       = '';          # Stores latest error of transaction
    $self->{messages}                    = [];          # An arrayref to the list of messages
    $self->{message}                     = '';          # Stores latest message of transaction
    $self->{rolled_back}                 = 0;
    $self->{trans_names}                 = [];
    $self->{start_times}                 = [];
    $self->{completed_transactions}      = [];
    $self->{completed_transaction_times} = [];
    $self->{aborted_transactions}        = [];
    $self->{aborted_transaction_times}   = [];

    ## restore initial settings ##
    $self->dbh()->{RaiseError} = 1;
    $self->dbh()->{PrintError} = 0;
    $self->dbh()->{AutoCommit} = 0;

    $self->{newids} = {};                          # Stores the new IDs created during the transaction
    $self->{origin} = Call_Stack( -quiet => 1 );

    #    Message("Reset Transaction");
    #    Call_Stack();
    return;
}

##############
sub restore {
##############
    my $self = shift;

    ## restore initial settings ##
    $self->dbh()->{RaiseError} = $self->{saveRaiseError};
    $self->dbh()->{PrintError} = $self->{savePrintError};
    $self->dbh()->{AutoCommit} = $self->{saveAutoCommit};

    return;
}
##############################
# public_methods             #
##############################

#############################
# Get dbh
#############################
sub dbh {
    my $self = shift;

    return $self->dbc->dbh();
}

#############################
# Get dbc
#############################
sub dbc {
    my $self = shift;

    return $self->{dbc};
}

##############################
# Commit a transaction
##############################
sub commit {
###############
    my $self  = shift;
    my %args  = &filter_input( \@_, -args => 'name,error' );
    my $name  = $args{-name} || 'unnamed';
    my $error = $args{-error};                                 # Optional argument if any error found
    my $force = $args{-force};                                 # Force commit even if unmatched with start.
    my $quiet = $args{-quiet};

    ## track stack of transaction names and start times ##
    my @time_stamps = @{ $self->{start_times} };
    my @trans_names = @{ $self->{trans_names} };

    #    Call_Stack();

    if ( !@{ $self->{trans_names} } ) {
        ## no transaction started ##
        Message("Warning closing $name: No transaction started") unless $force;    ## no warning (simply trying to force commit when nothing pending)

        #	Call_Stack();
        if ($force) { Message("Forced commit"); return $self->confirm_commit(); }
    }
    elsif ( $self->{trans_names}->[-1] ne $name ) {
        ## transaction is different from bottom transaction in stack ##
        Message("Warning closing $name: finishing $name transaction before $trans_names[-1]");

        #	Call_Stack();
        if ($force) { Message("Forced commit"); return $self->confirm_commit(); }
    }
    elsif ( int( @{ $self->{trans_names} } ) > 1 ) {
        ## removing transaction (name matches bottom transaction in stack)

        my $started   = pop @{ $self->{start_times} };
        my $completed = pop @{ $self->{trans_names} };

        push @{ $self->{completed_transactions} },      $completed;
        push @{ $self->{completed_transaction_times} }, $started;

        #	Message("Finished $name; still pending: (@{$self->{trans_names}})");
        #	Call_Stack();
        if ($force) { Message("Forced commit"); return $self->confirm_commit(); }
    }
    else {
        ## only one transaction on stack ##
        #  Message("Committing $name") unless $quiet;
        #  print HTML_Dump($self->{trans_names});

        my $started   = pop @{ $self->{start_times} };
        my $completed = pop @{ $self->{trans_names} };

        push @{ $self->{completed_transactions} },      $completed;
        push @{ $self->{completed_transaction_times} }, $started;

        return $self->confirm_commit();
    }

    return $time_stamps[-1];
}

########################
sub confirm_commit {
########################
    my $self = shift;

    #    Message("Committed");
    #    print HTML_Dump $self->{trans_names};
    #    Call_Stack();

    return $self->dbh->commit();
}

##############################
# Commit a transaction
# Argument: The error message (optional)
##############################
sub rollback {
#################
    my $self = shift;

    my $error_list;
    if ( int( @{ $self->{errors} } ) > 0 ) {
        $error_list = '(' . join( "; ", @{ $self->{errors} } ) . ')';
    }
    $self->error("Error: Transaction failed. $error_list Rolling back...");

    my $rollback = $self->dbh->rollback();
    return;
}

##############################
# Starts transaction
##############################
sub start {
#############
    my $self  = shift;
    my %args  = &filter_input( \@_, -args => 'name' );
    my $name  = $args{-name} || 'unnamed';
    my $quiet = $args{-quiet};
    my $debug = $args{-debug};

    if ($debug) { $self->{debug} = 1 }

    unless ( @{ $self->{trans_names} } ) {
        Message("Start $name transaction") if $debug;
        $self->reset(0);

        #	Call_Stack();
    }    ## feedback for first transaction

    if ( @{ $self->{start_times} } ) {
        ## push onto stack of imbedded transactions ##
        push( @{ $self->{start_times} }, timestamp() );
        push( @{ $self->{trans_names} }, $name );
    }
    else {
        $self->{started} = 1;

        ## reset transaction if it has been finished or rolled back and restarted ##
        $self->{start_times} = [ timestamp() ];
        $self->{trans_names} = [$name];
    }

    if ($debug) {
        my $open   = int( @{ $self->{trans_names} } );
        my $prefix = '*' x $open;
        Message("$prefix Starting $name");    ## add bullets to enable tracking of depth of transaction
    }

    #    Call_Stack();
    return $self;
}

##############################
# Finishes transaction
# Argument: Pass in $@
##############################
sub finish {
################
    my $self  = shift;
    my %args  = &filter_input( \@_, -args => 'name,error' );
    my $name  = $args{-name} || 'unnamed';
    my $error = $args{-error};                                 # Optional argument if any error found
    my $force = $args{-force};                                 # commit regardless unless there are errors ?
    my $quiet = $args{-quiet};                                 # quiet mode for closing transactions with final finish

    my $debug   = $self->{debug};                              # needs to be set at transaction start
    my $success = 0;

    #    print HTML_Dump(\%args);
    if ($error) { $self->error($error) }

    my $open_transactions = int( @{ $self->{trans_names} } );

    if ( int( @{ $self->{errors} } ) > 0 ) {

        # FAILURE #
        if ( $self->{trans_names}->[-1] eq $name ) {
            ## already rolled back .. continue ...
            my $aborted = pop @{ $self->{trans_names} };
            my $started = pop @{ $self->{start_times} };

            $open_transactions--;

            push @{ $self->{aborted_transactions} },      $aborted;
            push @{ $self->{aborted_transaction_times} }, $started;

            Message("Aborted $name") if $debug;
        }
        elsif ( @{ $self->{trans_names} } ) {
            ## closed transaction doesn't match with top of stack ##
            Message("Warning: $name closed prematurely; pending: (@{$self->{trans_names}})");
            Call_Stack();
        }

        if ( $self->{rolled_back} ) {
            ## already rolled back... ##
            Message("Rollback includes $name") if $debug;
        }
        else {
            ## notify the original cause of the rollback problem
            Message("Rollback triggered from $name failure");
            $self->{rolled_back} = 1;

            #           eval { $self->rollback(); };
        }

        ## if this is the last transaction on the stack, provide rollback message ##
        unless ( $quiet || @{ $self->{trans_names} } ) {
            Message("Rolled back all $name transactions") if $debug;

            #	    Call_Stack();
        }

        if ( !$open_transactions ) {
            eval { $self->rollback() };
        }    ## wait until the end to rollback the transaction..
    }
    else {

        # SUCCESS #
        #       Message("Committing $name ($error)") if $debug;
        eval { $self->commit( $name, -error => $error, -force => $force, -quiet => $quiet ); };
        $success = 1;
    }

    if ($debug) {
        my $open   = int( @{ $self->{trans_names} } ) + 1;
        my $prefix = '*' x $open;
        Message("$prefix Finished $name [$success]");
    }

    unless ( @{ $self->{trans_names} } ) { $self->DESTROY }    ## clear errors & messages if commit completed.

    return $success;
}

#################################################
# Execute a bunch of statements in a transaction
# Argument: Arrayref of SQL statements
#################################################
sub execute {
#############
    my $self       = shift;
    my $statements = shift;

    $self->start('execute');
    eval {
        foreach my $statement (@$statements)
        {
            $self->dbh->do($statement);
        }

        #	$self->commit('execute');
    };
    $self->finish( 'execute', -error => $@ );
}

###############################################
# Get/Set transaction error
###############################################
sub error {
    my $self  = shift;
    my $value = shift;

    if ($value) {
        $self->{error} = $value;
        push( @{ $self->{errors} }, $value );

        #	print "Error: $value";
        #	print Call_Stack();
    }

    return $self->{error};
}

###############################################
# Get all errors since transaction started
###############################################
sub errors {
    my $self = shift;

    return $self->{errors};
}

###############################################
# Get/Set whether a transaction has started
###############################################
sub started {
    my $self  = shift;
    my $value = shift;

    if ($value) { $self->{started} = $value }

    return $self->{started};
}

###############################################
# Get/Set message
###############################################
sub message {
###############
    my $self  = shift;
    my $value = shift;

    if ($value) {
        $self->{message} = $value;
        if ( !grep /^$value$/, @{ $self->{messages} } ) { push( @{ $self->{messages} }, $value ) }
    }

    return $self->{message};
}

###############################################
# Get messages during the transaction
###############################################
sub messages {
    my $self = shift;

    return $self->{messages};
}

###############################################
# Get/Set new IDs created during transaction
###############################################
sub newids {
##############
    my $self = shift;
    my %args = @_;

    my $newids = $args{ -newids };    # Specify an existing hash of newids
    my $table  = $args{-table};       # Specify the table
    my $newid  = $args{-newid};       # Specify the new ID

    if ($newids) {
        $self->{newids} = $newids;
    }

    if ( $table && $newid ) {
        unless ( exists $self->{newids}{$table} ) {
            $self->{newids}{$table} = [];
        }
        push( @{ $self->{newids}{$table} }, $newid );
    }

    return $self->{newids};
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
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

Eventually this object will replace the existing GSDB.pm and DB_IO.pm. Also support for transaction will be added in the future.

=head1 AUTHORS <UPLINK>

Ran Guin, Andy Chan, J.R. Santos and Eric Chuah at the Canada's Michael Smith Genome Sciences Centre

=head1 CREATED <UPLINK>

2004-06-15

=head1 REVISION <UPLINK>

$Id: Transaction.pm,v 1.7 2004/11/30 01:44:11 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
