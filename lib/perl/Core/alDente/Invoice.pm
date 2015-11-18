###################################################################################################################################
# alDente::Invoice.pm
#
# Module to handle invoicing of billable work
#
#
###################################################################################################################################
package alDente::Invoice;
use base SDB::DB_Object;
use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::Progress;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
## alDente modules
use alDente::Invoice_Views;

use vars qw( %Configs );

#####################
sub new {
#####################
    my $this = shift;

    my %args = &filter_input( \@_ );

    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Invoice' );
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        $self->{id} = $id;
        $self->primary_value( -table => 'Invoice', -value => $id );
        $self->load_Object();
    }

    return $self;
}

##############################
# Input: arrayOf Invoiceable_Work_ID
#
# Checks if the Invoiceable_Work has items with a FK_Invoice__ID
# Output: arrayOf Invoiceable_Work_ID that have Invoice_ID. This does not include items that have been pooled.
##############################
sub check_invoiceable_work_invoiced {
##############################
    my %args                 = filter_input( \@_, -args => 'dbc, invoiceable_work_ids' );
    my $dbc                  = $args{-dbc};
    my $invoiceable_work_ids = $args{-invoiceable_work_ids};

    my @invoiceable_work_id = @$invoiceable_work_ids;

    my $invoiceable_works = join( ',', @invoiceable_work_id );

    my @invoiced_items = $dbc->Table_find_array(
        'Invoiceable_Work AS IW, Invoiceable_Work_Reference AS IWR',
        ['Invoiceable_Work_ID'],
        "WHERE IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IW.Invoiceable_Work_ID IN ($invoiceable_works) AND (IWR.Indexed = 0 OR IWR.Indexed IS NULL) AND (IWR.FK_Invoice__ID > 0 OR IWR.FK_Invoice__ID IS NOT NULL)",
        -autoquote => 1
    );

    return \@invoiced_items;
}

##############################
# Input: Invoice_ID, arrayOf Invoiceable_Work_Reference or one Invoiceable_Work_Reference_ID
# Output: number of Invoiceable_Work_ID that was updated
#
# Updates FK_Invoice__ID to Invoice_ID for Invoiceable_Work_Reference_ID's that were provided
# Assumes that checks have already been done and will just overwrite the record
##############################
sub update_invoiceable_work_invoice {
##############################
    my %args       = filter_input( \@_, -args => 'dbc, invoice_id, invoiceable_work_ids,remove' );
    my $dbc        = $args{-dbc};
    my $invoice_id = $args{-invoice_id};
    my $iwr_id     = $args{-iwr_id};                                                                 #for single string values
    my $iwr_ids    = $args{-iwr_ids};                                                                #for inputted arrays
    my @invoiceable_work_reference_id;
    my $updated;
    if ($iwr_ids) { @invoiceable_work_reference_id = @$iwr_ids; }
    if ($iwr_id) { push( @invoiceable_work_reference_id, $iwr_id ); }
    my $invoiceable_reference_works = join ',', @invoiceable_work_reference_id;
    $updated = $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['FK_Invoice__ID'], [$invoice_id], "WHERE Invoiceable_Work_Reference_ID IN ($invoiceable_reference_works)", -autoquote => 1 );

    return $updated;
}

################################
# Input: fields, values
#
# Adds new Invoice record
# Output: newly added invoice_id
################################
sub save_invoice_info {
################################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $fields = $args{-fields};
    my $values = $args{ -values };

    my $invoice_id = $dbc->Table_append_array( 'Invoice', $fields, $values, -autoquote => 1 );
    Message("Added a new invoice, id = $invoice_id");
    return $invoice_id;
}

#############################
# Returns the total count of each work type done on an invoice
#
# Input: array ref of Library_Name, array ref of of Invoice_ID
# Output: array ref where each element is a distinct work type with the total number of times it occurs on the invoice
#############################
sub get_total_work_count {
#############################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'dbc, invoice, library', -mandatory => 'dbc, invoice, library' );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $invoice = $args{-invoice};
    my $library = $args{-library};

    my $prep_summary_ref = &get_prep_summary( -dbc => $dbc, -invoice => $invoice, -library => $library, -total_work_count => 1 );
    my $run_summary_ref  = &get_run_summary( -dbc  => $dbc, -invoice => $invoice, -library => $library, -total_count      => 1 );
    my $analysis_summary_ref = &get_analysis_summary( -dbc => $dbc, -invoice => $invoice, -library => $library );

    my @prep_summary     = @$prep_summary_ref;
    my @run_summary      = @$run_summary_ref;
    my @analysis_summary = @$analysis_summary_ref;

    my @totals;    ## Array where each element is a string '# x <work_type>'

    ## COUNTING PREPS SECTION
    my @all_preps;    ## Array containing all preps done on invoice (has duplicated values -- needed for counting)
    foreach my $prep (@prep_summary) {
        ## Ignore 'library failed...' string
        if ( $prep =~ /^Library Failed - Billing for .*$/ ) {
            my $str = 'Library Failed - Billing for ';
            $prep = substr( $prep, length $str );
        }
        elsif ( $prep =~ /^Library Failed \(Billable\) - Billing for .*$/ ) {
            my $str = 'Library Failed (Billable) - Billing for ';
            $prep = substr( $prep, length $str );
        }
        elsif ( $prep =~ /^Cancelled - Library was not constructed$/ ) {
            $prep = '';
        }
        my @preps = split ', ', $prep;
        push @all_preps, @preps;
    }

    ## Counting
    my %count_preps;
    $count_preps{$_}++ foreach (@all_preps);

    ## Formatting
    foreach my $key ( keys %count_preps ) {
        my $total = $count_preps{$key} . " x " . $key;
        push @totals, $total;
    }

    ## COUNTING RUNS SECTION
    my @runs_with_count;
    ## First split items for each libraries so that each individual run/item is an element in the array
    foreach my $run (@run_summary) {
        my @runs = split ', ', $run;
        push @runs_with_count, @runs;
    }

    ## Split elements into 2 arrays with coordinating indicies where one array contains the
    ## work item and the other contains the count for the individual library
    my ( @run_counts, @all_runs );
    foreach my $r (@runs_with_count) {
        my ( $count, $run ) = split ' x ', $r;
        push @run_counts, $count;
        push @all_runs,   $run;
    }

    ## Counting (unlike preps and analyses, incrementing value associated with key by the number stored in
    ## matching index from run_counts array instead of just by 1)
    my %runs;
    my $index = 0;
    foreach my $r (@all_runs) {
        $runs{$r} += $run_counts[$index];
        $index++;
    }

    ## Formatting
    foreach my $key ( keys %runs ) {
        my $total = $runs{$key} . " x " . $key;
        push @totals, $total;
    }

    ## COUNTING ANALYSES SECTION
    my @all_analyses;    ## Array containing all analyses done on invoice (has duplicated values -- needed for counting)
    foreach my $analysis (@analysis_summary) {
        my @analyses = split ', ', $analysis;
        push @all_analyses, @analyses;
    }

    ## Counting analyses
    my %count_analyses;
    $count_analyses{$_}++ foreach (@all_analyses);

    ## Formatting
    foreach my $key ( keys %count_analyses ) {
        my $total = $count_analyses{$key} . " x " . $key;
        push @totals, $total;
    }

    return \@totals;
}

#############################
# Since the prep summary in the summary of work can't handle counting each individual prep
# (can't count inside aggregate functions)
# this function returns an array ref of repeated protocols for each library on an invoice
#
# Input: array ref of Library_Name, array ref of Invoice_ID
# Output: array ref of repeated protocols for each library
#############################
sub get_repeated_protocols {
#############################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'dbc, invoice, library' );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $invoice = $args{-invoice};
    my $library = $args{-library};

    my @invoice = @$invoice;
    my @library = @$library;

    ## Checking that only one distinct invoice id is passed in, returns empty array if multiple (warning message returned in get_prep_summary)
    my %unique_invoices_hash = map { $_ => 1 } @invoice;
    my @unique_invoices = keys %unique_invoices_hash;

    if ( scalar @unique_invoices > 1 ) {
        return;
    }

    my $invoice_id = $invoice[0];

    my @repeated_protocols;
    foreach my $lib (@library) {
        ## Finding all invoiceable works for a given library on an invoice - for counting how many times each protocol was done
        my @invoice_protocols = $dbc->Table_find_array(
            'Invoiceable_Work IW, Invoiceable_Work_Reference IWR, Invoiceable_Prep IP, Invoice_Protocol IPtype, Plate PLA',
            [ 'IW.Invoiceable_Work_ID', 'IPtype.Invoice_Protocol_Name' ],
            "WHERE IW.Invoiceable_Work_ID = IWR.FKReferenced_Invoiceable_Work__ID AND IP.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IPtype.Invoice_Protocol_ID = IP.FK_Invoice_Protocol__ID AND IW.FK_Plate__ID = PLA.Plate_ID AND PLA.FK_Library__Name = '$lib' AND IWR.FK_Invoice__ID = $invoice_id AND IWR.Billable = 'Yes'",
            -distinct => 1
        );

        ## Counting number of times each protocol was done
        my %count_protocols;
        foreach my $ip (@invoice_protocols) {
            my ( $iw_id, $ip_name ) = split ',', $ip;
            $count_protocols{$ip_name}++;
        }

        ## If a protocol has been done more than once, append the names of protocols done more than once in brackets
        my @rp;
        foreach my $ip ( keys %count_protocols ) {
            if ( $count_protocols{$ip} > 1 ) {
                $ip = $count_protocols{$ip} . " x " . $ip;
                push @rp, $ip;
            }
        }
        my $rp_string = join ', ', @rp;
        push @repeated_protocols, $rp_string;
    }

    return \@repeated_protocols;

}

#############################
# This returns a summary of all the work that has been done on the libraries in a given invoice
#
# Input: array ref of Library_Name, array ref of Invoice_ID
# Output: array ref of invoiceable work summaries done on each library
#############################
sub summary_of_work_details {
#############################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'dbc, invoice, library', -mandatory => 'dbc, invoice, library' );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $invoice = $args{-invoice};
    my $library = $args{-library};

    my $prep_summary_ref     = &get_prep_summary( -dbc     => $dbc, -invoice => $invoice, -library => $library );
    my $run_summary_ref      = &get_run_summary( -dbc      => $dbc, -invoice => $invoice, -library => $library );
    my $analysis_summary_ref = &get_analysis_summary( -dbc => $dbc, -invoice => $invoice, -library => $library );

    my @prep_summary     = @$prep_summary_ref;
    my @run_summary      = @$run_summary_ref;
    my @analysis_summary = @$analysis_summary_ref;

    my @details;
    my $index = 0;
    foreach my $prep (@prep_summary) {
        my $summary;
        $summary .= $prep;    ## Include prep summary
        if ( $prep && $run_summary[$index] ) {    ## Library has both prep and run summary, separate with comma
            $summary .= ", ";
        }
        $summary .= $run_summary[$index];         ## Include run summary
        if ( $analysis_summary[$index] && ( $prep || $run_summary[$index] ) ) {    ## Library has preps or runs in addition to analyses, separate with comma
            $summary .= ", ";
        }
        $summary .= $analysis_summary[$index];                                     ## Include analysis summary
        push @details, $summary;
        $index++;
    }

    return \@details;
}

################################
# This will return a summary of all the invoiceable preps that have been done on all the libraries for a given invoice
#
# Input: Library_Name, Invoice_ID
# Output: array ref of prep info for each library
################################
sub get_prep_summary {
################################
    my $self             = shift;
    my %args             = &filter_input( \@_, -args => 'dbc,invoice,library', -mandatory => 'dbc,invoice,library' );
    my $dbc              = $args{-dbc} || $self->param('dbc');
    my $invoice          = $args{-invoice};
    my $library          = $args{-library};
    my $total_work_count = $args{-total_work_count};                                                                    ## Parameter to determine whether or not subroutine is being called from get_total_work_count
    ## This changes how the library strategy is appended on to work items for counting

    my @invoice = @$invoice;
    my @library = @$library;
    my @work_summary;

    ## Checking that only one disinct invoice id is passed in, if multiple returns warning message telling user to select one invoice at a time
    my %unique_invoices = map { $_ => 1 } @invoice;
    my @unique_invoices = keys %unique_invoices;

    if ( scalar @unique_invoices > 1 ) {
        foreach (@library) {
            my $too_many_invoices = "Please select one invoice at a time to see summary of works done on each library.";
            push @work_summary, $too_many_invoices;
        }
        return \@work_summary;
    }

    my $invoice_id = $invoice[0];

    foreach my $lib (@library) {
        ## Finding library strategy for all plates for a given library on an invoice
        my ($lib_strategy) = $dbc->Table_find(
            'Plate, Plate_Attribute PA, Library_Strategy, Invoiceable_Work IW, Invoiceable_Work_Reference IWR',
            "GROUP_CONCAT(DISTINCT Library_Strategy_Name SEPARATOR '/')",
            "WHERE Plate_ID = PA.FK_Plate__ID AND FK_Attribute__ID = 246 AND Attribute_Value = Library_Strategy_ID AND IW.FK_Plate__ID = Plate_ID AND IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND FK_Library__Name = '$lib' AND IWR.FK_Invoice__ID = $invoice_id"
        );

        my $field = "CONCAT_WS(' ', CASE WHEN MIN(IPtype.Priority) = 1
                                         THEN CONCAT_WS(', ', GROUP_CONCAT(DISTINCT CASE WHEN IPtype.Priority = 3
                                                                                         THEN IPtype.Invoice_Protocol_Name
                                                                                         END SEPARATOR ', '),
                                                              GROUP_CONCAT(DISTINCT CASE WHEN IPtype.Priority = 2 
                                                                                         THEN IPtype.Abbrev 
                                                                                         WHEN IPtype.Priority = 1
                                                                                         THEN IPtype.Invoice_Protocol_Name
                                                                                         END SEPARATOR ' '))
                                         WHEN (MIN(IPtype.Priority) IN (2, 3))
                                         THEN GROUP_CONCAT(DISTINCT CASE WHEN IPtype.Priority <> 4
                                                                         THEN IPtype.Invoice_Protocol_Name
                                                                         END SEPARATOR ', ')
                                         ELSE GROUP_CONCAT(DISTINCT IPtype.Invoice_Protocol_Name SEPARATOR ', ')
                                         END)";

        if ($total_work_count) {
            $field = "CONCAT_WS(' ', CASE WHEN LIB.Library_Status = 'Cancelled'
                                          THEN 'Cancelled - Library was not constructed'
                                          WHEN MIN(IPtype.Priority) = 1
                                          THEN CONCAT_WS(', ', GROUP_CONCAT(DISTINCT CASE WHEN IPtype.Priority = 3
                                                                                          THEN CONCAT_WS(' ', '$lib_strategy', IPtype.Invoice_Protocol_Name)
                                                                                          END SEPARATOR ', '),
                                                               CONCAT_WS(' ', '$lib_strategy', GROUP_CONCAT(DISTINCT CASE WHEN IPtype.Priority = 2 
                                                                                                                          THEN IPtype.Abbrev
                                                                                                                          WHEN IPtype.Priority = 1
                                                                                                                          THEN IPtype.Invoice_Protocol_Name
                                                                                                                          END SEPARATOR ' ')))
                                          WHEN (MIN(IPtype.Priority) IN (2, 3))
                                          THEN GROUP_CONCAT(DISTINCT CASE WHEN IPtype.Priority <> 4
                                                                          THEN CONCAT_WS(' ', '$lib_strategy', IPtype.Invoice_Protocol_Name)
                                                                          END SEPARATOR ', ')
                                          WHEN (MIN(IPtype.Priority) = 4)
                                          THEN GROUP_CONCAT(DISTINCT CONCAT_WS(' ', '$lib_strategy', IPtype.Invoice_Protocol_Name) SEPARATOR ', ')
                                          ELSE NULL
                                          END)";
        }

        my $tables = "Invoiceable_Work IW
                     LEFT JOIN Plate PLA ON PLA.Plate_ID = IW.FK_Plate__ID
                     LEFT JOIN Library LIB ON LIB.Library_Name = PLA.FK_Library__Name
                     LEFT JOIN Invoiceable_Work_Reference IWR ON IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                     LEFT JOIN Invoiceable_Prep IP ON IP.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                     LEFT JOIN Invoice_Protocol IPtype ON IPtype.Invoice_Protocol_ID = IP.FK_Invoice_Protocol__ID";

        my $condition = "WHERE (IWR.Indexed = 0 OR IWR.Indexed IS NULL)
                        AND IWR.FK_Invoice__ID = $invoice_id
                        AND LIB.Library_Name = '$lib'
                        AND IWR.Billable = 'Yes'
                        ORDER BY TIMESTAMP(IW.Invoiceable_Work_DateTime)";

        ## Getting prep summary for library
        my ($prep_summary) = $dbc->Table_find( $tables, $field, $condition );
        ## Removing trailing commas
        $prep_summary =~ s/,+$//;

        ## Full work summary for library on invoice
        my $ws;
        if ( $prep_summary && !$total_work_count ) {
            $ws = $lib_strategy . " " . $prep_summary;    ## If preps were done for a library, concatenate the library strategy on the front of the summary

            ## If all 3 steps of raindance were done, only show amplicon generation (only applies to summary of work)
            my $rd_template = ( $ws =~ /RD Template Generation/ );
            my $rd_shearing = ( $ws =~ /RD Shearing/ );
            my $rd_amplicon = ( $ws =~ /RD Amplicon Generation/ );

            if ( $rd_template && $rd_shearing && $rd_amplicon ) {
                $ws =~ s/RD Template Generation,//;
                $ws =~ s/RD Shearing,//;
            }
        }
        else {
            $ws = $prep_summary;
        }

        ## Finding library status
        my ($lib_status) = $dbc->Table_find( 'Library', 'Library_Status', "WHERE Library_Name = '$lib'", -distinct => 1 );

        if ( $lib_status eq 'Cancelled' ) {
            $ws = 'Cancelled - Library was not constructed';    ## If a library was cancelled the prep summary for the entire library should just be this string
        }
        elsif ( $lib_status eq 'Failed' ) {
            my ($min_priority) = $dbc->Table_find(
                'Invoiceable_Work IW, Plate PLA, Invoiceable_Work_Reference IWR, Invoiceable_Prep IP, Invoice_Protocol IPtype',
                'MIN(IPtype.Priority)',
                "WHERE IW.FK_Plate__ID = PLA.Plate_ID AND IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IP.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IPtype.Invoice_Protocol_ID = IP.FK_Invoice_Protocol__ID AND PLA.FK_Library__Name = '$lib' AND IWR.FK_Invoice__ID = $invoice_id"
            );
            if ( $min_priority == 4 ) {
                $ws = 'Library Failed - Billing for ' . $ws;    ## If library was failed and only had Sample QC done specify that the library was failed
            }
            else {
                $ws = 'Library Failed (Billable) - Billing for ' . $ws;    ## If library was failed and had more than Sample QC done specify that the library failed but is still billable
            }
        }

        push @work_summary, $ws;
    }

    return \@work_summary;

}

################################
# This will return a summary of all the invoiceable runs that have been done on all the libraries for a given invoice.
# Only SolexaRuns should be reported.
#
# Input: Library_Name, Invoice_ID
# Output: array ref of run info for each library
################################
sub get_run_summary {
################################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'dbc,invoice,library', -mandatory => 'dbc,invoice,library' );
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $invoice = $args{-invoice};
    my $library = $args{-library};
    my $total   = $args{-total_count};                                                                         ## Whether or not the summary is being generated for the 'Total Work Count' table (if so, omit 'Pooled from...' item)

    my @invoice = @$invoice;
    my @library = @$library;
    my @work_summary;

    ## Checking that only one distinct invoice id is passed in, returns empty array if multiple (warning message returned in get_prep_summary)
    my %unique_invoices = map { $_ => 1 } @invoice;
    my @unique_invoices = keys %unique_invoices;

    if ( scalar @unique_invoices > 1 ) {
        return \@work_summary;
    }

    ## use first element in array of invoice ids as invoice id for query (there should only be one distinct element in the array at this point)
    my $invoice_id = $invoice[0];

    foreach my $lib (@library) {
        ## Checking for distinct maximum read lengths for each run in a library
        my @read_lengths = $dbc->Table_find(
            'Plate, Invoiceable_Work IW, Invoiceable_Work_Reference IWR, Invoiceable_Run IR, Solexa_Read SR',
            'SR.Read_Length',
            "WHERE Plate_ID = IW.FK_Plate__ID AND Invoiceable_Work_ID = IR.FK_Invoiceable_Work__ID AND IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IR.FK_Run__ID = SR.FK_Run__ID AND SR.End_Read_Type NOT LIKE 'IDX%' AND IWR.Billable = 'Yes' AND SR.Read_Length IN (SELECT MAX(Sol_Read.Read_Length) FROM Solexa_Read Sol_Read WHERE Sol_Read.FK_Run__ID = IR.FK_Run__ID) AND IWR.FK_Invoice__ID = $invoice_id AND Plate.FK_Library__Name = '$lib' GROUP BY IW.Invoiceable_Work_ID",
            -distinct => 1
        );

        ## Checking for distinct equipment names (unless hiseq or miseq, then just distinct first 5 letters)
        my @equipment = $dbc->Table_find(
            'Plate, Invoiceable_Work IW, Invoiceable_Work_Reference IWR, Run, RunBatch RB, Equipment EQP',
            "CASE WHEN (EQP.Equipment_Name LIKE 'HiSeq%' OR EQP.Equipment_Name LIKE 'MiSeq%') THEN LEFT(EQP.Equipment_Name, 5) ELSE EQP.Equipment_Name END",
            "WHERE Plate_ID = IW.FK_Plate__ID AND IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND Plate_ID = Run.FK_Plate__ID AND RB.RunBatch_ID = Run.FK_RunBatch__ID AND EQP.Equipment_ID = RB.FK_Equipment__ID AND IWR.Billable = 'Yes' AND IWR.FK_Invoice__ID = $invoice_id AND Plate.FK_Library__Name = '$lib' AND IW.Invoiceable_Work_Type = 'Run' GROUP BY IW.Invoiceable_Work_ID",
            -distinct => 1
        );

        my ( $field, $tables, $condition );

        ## Tables are the same for all cases
        $tables = "Invoiceable_Work IW
                   LEFT JOIN Plate PLA ON PLA.Plate_ID = IW.FK_Plate__ID
                   LEFT JOIN Library LIB ON LIB.Library_Name = PLA.FK_Library__Name
                   LEFT JOIN Invoiceable_Work_Reference IWR ON IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                   LEFT JOIN Invoiceable_Run IR ON IR.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                   LEFT JOIN Invoice_Run_Type IRtype ON IRtype.Invoice_Run_Type_ID = IR.FK_Invoice_Run_Type__ID
                   LEFT JOIN Solexa_Read Solread ON Solread.FK_Run__ID = IR.FK_Run__ID
                   LEFT JOIN SolexaRun ON SolexaRun.FK_Run__ID = IR.FK_Run__ID
                   LEFT JOIN Run ON Run.Run_ID = IR.FK_Run__ID
                   LEFT JOIN RunBatch RB ON Run.FK_RunBatch__ID = RB.RunBatch_ID
                   LEFT JOIN Equipment AS EQP ON EQP.Equipment_ID = RB.FK_Equipment__ID
                   LEFT JOIN ReArray_Request ON FKTarget_Plate__ID IN (SELECT DISTINCT Pl.Plate_ID FROM Plate Pl WHERE Pl.FK_Library__Name = '$lib')
                   LEFT JOIN ReArray ON ReArray.FK_ReArray_Request__ID = ReArray_Request.ReArray_Request_ID
                   LEFT JOIN Plate AS Child ON Child.Plate_ID = ReArray.FKSource_Plate__ID";

        ## Multiple read lengths, multiple machines
        if ( int(@equipment) > 1 && int(@read_lengths) > 1 ) {
            my $full_summary;    ## Full run summary for a given library
            my $index = 0;
            foreach my $rl (@read_lengths) {
                foreach my $eqp (@equipment) {
                    $eqp =~ s/,+$//;

                    ## Find equipment ids for equipment. If query can't match exact eqp name, check for names that are LIKE '$eqp%' (applies to HiSeq and MiSeq machines)
                    my @eqp_ids = $dbc->Table_find( 'Equipment EQP', 'EQP.Equipment_ID', "WHERE EQP.Equipment_Name = '$eqp'" );
                    unless (@eqp_ids) { @eqp_ids = $dbc->Table_find( 'Equipment EQP', 'EQP.Equipment_ID', "WHERE EQP.Equipment_Name LIKE '$eqp%'" ) }

                    ## Convert array of equipment ids into a string
                    my $eqp_id_list = Cast_List( -list => \@eqp_ids, -to => 'string', -delimiter => ',', -autoquote => 1 );

                    $field = "CONCAT_WS(' ', ";

                    ## Only include Pooled From at beginning of string
                    if ( $index == 0 && !$total ) {
                        $field .= "CASE WHEN LIB.Library_Name LIKE 'INX%' OR LIB.Library_Name LIKE 'IX%' OR LIB.Library_Name LIKE 'MX%'
                                        THEN CONCAT('Pooled from ', COUNT(DISTINCT Child.FK_Library__Name), ' libraries (', GROUP_CONCAT(DISTINCT Child.FK_Library__Name ORDER BY Child.FK_Library__Name SEPARATOR ', '), ')', ',' )
                                        ELSE NULL 
                                        END,";
                    }

                    $field .= "CASE WHEN (COUNT(DISTINCT IR.Invoiceable_Run_ID) > 0 AND COUNT(DISTINCT SolexaRun.SolexaRun_Type) < 2)
                                    THEN CONCAT_WS(' ', COUNT(DISTINCT IR.Invoiceable_Run_ID), 'x')
                                    ELSE NULL
                                    END,
                               GROUP_CONCAT(DISTINCT CASE WHEN Solread.Read_Length IS NOT NULL AND Run.Run_ID IS NOT NULL
                                                          THEN CONCAT_WS(' ', Solread.Read_Length, 'bp', (CASE WHEN SolexaRun.SolexaRun_Type = 'Single'
                                                                                                               THEN 'SET'
                                                                                                               WHEN SolexaRun.SolexaRun_Type = 'Paired'
                                                                                                               THEN 'PET'
                                                                                                               ELSE NULL 
                                                                                                               END),
                                                                                                         (CASE WHEN LIB.Library_Name LIKE 'INX%' OR LIB.Library_Name LIKE 'IX%' OR LIB.Library_Name LIKE 'MX%'
                                                                                                               THEN 'Indexed'
                                                                                                               ELSE NULL
                                                                                                               END),
                                                                                                         (CASE WHEN EQP.Equipment_Name LIKE 'HiSeq%'
                                                                                                               THEN 'Lane HiSeq'
                                                                                                               WHEN EQP.Equipment_Name LIKE 'MiSeq%'
                                                                                                               THEN 'Run MiSeq'
                                                                                                               ELSE EQP.Equipment_Name
                                                                                                               END))
                                                          WHEN Solread.Read_Length IS NULL AND Run.Run_ID IS NOT NULL
                                                          THEN 'Run(s) Pending'
                                                          ELSE NULL
                                                          END SEPARATOR ' '))";

                    $condition = "WHERE (Solread.End_Read_Type IS NULL OR Solread.End_Read_Type NOT LIKE 'IDX%')
                                    AND IR.FK_Invoice_Run_Type__ID IN (1)
                                    AND (IWR.Indexed = 0 OR IWR.Indexed IS NULL)
                                    AND IWR.FK_Invoice__ID = $invoice_id
                                    AND LIB.Library_Name = '$lib'
                                    AND IWR.Billable = 'Yes'
                                    AND EQP.Equipment_ID IN ($eqp_id_list)
                                    AND (Solread.Read_Length = '$rl' OR Solread.Read_Length IS NULL)
                                    ORDER BY IW.Invoiceable_Work_DateTime";

                    my ($partial_summary) = $dbc->Table_find( $tables, $field, $condition );
                    $partial_summary =~ s/,+$//;
                    unless ( $index == 0 || !$partial_summary ) { $full_summary .= ', ' }
                    $full_summary .= $partial_summary;
                    $index++;
                }
            }
            $full_summary =~ s/,+$//;
            push @work_summary, $full_summary;
        }
        ## One (not null) read length, multiple machines
        elsif ( int(@equipment) > 1 && int(@read_lengths) < 2 && @read_lengths ) {
            my $full_summary;    ## Full run summary for a given library
            my $index = 0;
            foreach my $eqp (@equipment) {
                $eqp =~ s/,+$//;

                ## Find equipment ids for equipment. If query can't match exact eqp name, check for names that are LIKE '$eqp%' (applies to HiSeq and MiSeq machines)
                my @eqp_ids = $dbc->Table_find( 'Equipment EQP', 'EQP.Equipment_ID', "WHERE EQP.Equipment_Name = '$eqp'" );
                unless (@eqp_ids) { @eqp_ids = $dbc->Table_find( 'Equipment EQP', 'EQP.Equipment_ID', "WHERE EQP.Equipment_Name LIKE '$eqp%'" ) }

                ## Convert array of equipment ids into a string
                my $eqp_id_list = Cast_List( -list => \@eqp_ids, -to => 'string', -delimiter => ',', -autoquote => 1 );

                $field = "CONCAT_WS(' ', ";

                ## Only include Pooled From at beginning of string
                if ( $index == 0 && !$total ) {
                    $field .= "CASE WHEN LIB.Library_Name LIKE 'INX%' OR LIB.Library_Name LIKE 'IX%' OR LIB.Library_Name LIKE 'MX%'
                                        THEN CONCAT('Pooled from ', COUNT(DISTINCT Child.FK_Library__Name), ' libraries (', GROUP_CONCAT(DISTINCT Child.FK_Library__Name ORDER BY Child.FK_Library__Name SEPARATOR ', '), ')', ',' )
                                    ELSE NULL 
                                    END,";
                }

                $field .= "CASE WHEN (COUNT(DISTINCT IR.Invoiceable_Run_ID) > 0 AND COUNT(DISTINCT SolexaRun.SolexaRun_Type) < 2)
                                THEN CONCAT_WS(' ', COUNT(DISTINCT IR.Invoiceable_Run_ID), 'x')
                                ELSE NULL
                                END,
                           GROUP_CONCAT(DISTINCT CASE WHEN Solread.Read_Length IS NOT NULL AND Run.Run_ID IS NOT NULL
                                                      THEN CONCAT_WS(' ', Solread.Read_Length, 'bp', (CASE WHEN SolexaRun.SolexaRun_Type = 'Single'
                                                                                                           THEN 'SET'
                                                                                                           WHEN SolexaRun.SolexaRun_Type = 'Paired'
                                                                                                           THEN 'PET'
                                                                                                           ELSE NULL 
                                                                                                           END),
                                                                                                     (CASE WHEN LIB.Library_Name LIKE 'INX%' OR LIB.Library_Name LIKE 'IX%' OR LIB.Library_Name LIKE 'MX%'
                                                                                                           THEN 'Indexed'
                                                                                                           ELSE NULL
                                                                                                           END),
                                                                                                     (CASE WHEN EQP.Equipment_Name LIKE 'HiSeq%'
                                                                                                           THEN 'Lane HiSeq'
                                                                                                           WHEN EQP.Equipment_Name LIKE 'MiSeq%'
                                                                                                           THEN 'Run MiSeq'
                                                                                                           ELSE EQP.Equipment_Name
                                                                                                           END))
                                                      WHEN Solread.Read_Length IS NULL AND Run.Run_ID IS NOT NULL
                                                      THEN 'Run(s) Pending'
                                                      ELSE NULL
                                                      END SEPARATOR ' '))";

                $condition = "WHERE (Solread.End_Read_Type IS NULL OR Solread.End_Read_Type NOT LIKE 'IDX%')
                                 AND IR.FK_Invoice_Run_Type__ID IN (1)
                                 AND (IWR.Indexed = 0 OR IWR.Indexed IS NULL)
                                 AND IWR.FK_Invoice__ID = $invoice_id
                                 AND LIB.Library_Name = '$lib'
                                 AND IWR.Billable = 'Yes'
                                 AND EQP.Equipment_ID IN ($eqp_id_list) 
                                 AND (Solread.Read_Length = '$read_lengths[0]' OR Solread.Read_Length IS NULL)
                                 ORDER BY IW.Invoiceable_Work_DateTime";

                my ($partial_summary) = $dbc->Table_find( $tables, $field, $condition );
                $partial_summary =~ s/,+$//;
                unless ( $index == 0 || !$partial_summary ) { $full_summary .= ', ' }
                $full_summary .= $partial_summary;
                $index++;
            }
            $full_summary =~ s/,+$//;
            push @work_summary, $full_summary;
        }
        ## Multiple read lengths, one machine
        elsif ( int(@read_lengths) > 1 && int(@equipment) < 2 ) {
            my $full_summary;    ## Full run summary for a given library
            my $index = 0;
            foreach my $rl (@read_lengths) {
                $field = "CONCAT_WS(' ', ";

                ## Only include Pooled From at beginning of string
                if ( $index == 0 && !$total ) {
                    $field .= "CASE WHEN LIB.Library_Name LIKE 'INX%' OR LIB.Library_Name LIKE 'IX%' OR LIB.Library_Name LIKE 'MX%'
                                        THEN CONCAT('Pooled from ', COUNT(DISTINCT Child.FK_Library__Name), ' libraries (', GROUP_CONCAT(DISTINCT Child.FK_Library__Name ORDER BY Child.FK_Library__Name SEPARATOR ', '), ')', ',' )
                                    ELSE NULL 
                                    END,";
                }

                $field .= "CASE WHEN (COUNT(DISTINCT IR.Invoiceable_Run_ID) > 0 AND COUNT(DISTINCT SolexaRun.SolexaRun_Type) < 2)
                                 THEN CONCAT_WS(' ', COUNT(DISTINCT IR.Invoiceable_Run_ID), 'x')
                                 ELSE NULL
                                 END,
                                 GROUP_CONCAT(DISTINCT CASE WHEN Solread.Read_Length IS NOT NULL AND Run.Run_ID IS NOT NULL
                                                            THEN CONCAT_WS(' ', Solread.Read_Length, 'bp', (CASE WHEN SolexaRun.SolexaRun_Type = 'Single'
                                                                                                                 THEN 'SET'
                                                                                                                 WHEN SolexaRun.SolexaRun_Type = 'Paired'
                                                                                                                 THEN 'PET'
                                                                                                                 ELSE NULL 
                                                                                                                 END),
                                                                                                           (CASE WHEN LIB.Library_Name LIKE 'INX%' OR LIB.Library_Name LIKE 'IX%' OR LIB.Library_Name LIKE 'MX%'
                                                                                                                 THEN 'Indexed'
                                                                                                                 ELSE NULL
                                                                                                                 END),
                                                                                                           (CASE WHEN EQP.Equipment_Name LIKE 'HiSeq%'
                                                                                                                 THEN 'Lane HiSeq'
                                                                                                                 WHEN EQP.Equipment_Name LIKE 'MiSeq%'
                                                                                                                 THEN 'Run MiSeq'
                                                                                                                 ELSE EQP.Equipment_Name
                                                                                                                 END))
                                                            WHEN Solread.Read_Length IS NULL AND Run.Run_ID IS NOT NULL
                                                            THEN 'Run(s) Pending'
                                                            ELSE NULL
                                                            END SEPARATOR ' '))";

                $condition = "WHERE (Solread.End_Read_Type IS NULL OR Solread.End_Read_Type NOT LIKE 'IDX%')
                                 AND IR.FK_Invoice_Run_Type__ID IN (1)
                                 AND (IWR.Indexed = 0 OR IWR.Indexed IS NULL)
                                 AND IWR.FK_Invoice__ID = $invoice_id
                                 AND LIB.Library_Name = '$lib'
                                 AND IWR.Billable = 'Yes'
                                 AND (Solread.Read_Length = '$rl' OR Solread.Read_Length IS NULL)
                                 ORDER BY IW.Invoiceable_Work_DateTime";

                my ($partial_summary) = $dbc->Table_find( $tables, $field, $condition );
                $partial_summary =~ s/,+$//;
                unless ( $index == 0 || !$partial_summary ) { $full_summary .= ', ' }
                $full_summary .= $partial_summary;
                $index++;
            }
            $full_summary =~ s/,+$//;
            push @work_summary, $full_summary;
        }
        ## One read length, one machine
        else {
            $field = "CONCAT_WS(' ', ";

            ## Only included Pooled From if not for total work count
            unless ($total) {
                $field .= "CASE WHEN LIB.Library_Name LIKE 'INX%' OR LIB.Library_Name LIKE 'IX%' OR LIB.Library_Name LIKE 'MX%'
                                THEN CONCAT('Pooled from ', COUNT(DISTINCT Child.FK_Library__Name), ' libraries (', GROUP_CONCAT(DISTINCT Child.FK_Library__Name ORDER BY Child.FK_Library__Name SEPARATOR ', '), ')', ',' )
                                ELSE NULL 
                                END,"
            }

            $field .= "CASE WHEN (COUNT(DISTINCT SolexaRun.SolexaRun_Type) < 2 AND COUNT(DISTINCT Solread.Read_Length) < 2 AND COUNT(DISTINCT IR.Invoiceable_Run_ID) > 0)
                       THEN CONCAT_WS(' ', COUNT(DISTINCT IR.Invoiceable_Run_ID), 'x')
                       ELSE NULL
                       END,
                       GROUP_CONCAT(DISTINCT CASE WHEN Solread.Read_Length IS NOT NULL AND Run.Run_ID IS NOT NULL
                                                  THEN CONCAT_WS(' ', Solread.Read_Length, 'bp', (CASE WHEN SolexaRun.SolexaRun_Type = 'Single'
                                                                                                       THEN 'SET'
                                                                                                       WHEN SolexaRun.SolexaRun_Type = 'Paired'
                                                                                                       THEN 'PET'
                                                                                                       ELSE NULL 
                                                                                                       END),
                                                                                                 (CASE WHEN LIB.Library_Name LIKE 'INX%' OR LIB.Library_Name LIKE 'IX%' OR LIB.Library_Name LIKE 'MX%'
                                                                                                       THEN 'Indexed'
                                                                                                       ELSE NULL
                                                                                                       END),
                                                                                                 (CASE WHEN EQP.Equipment_Name LIKE 'HiSeq%'
                                                                                                       THEN 'Lane HiSeq'
                                                                                                       WHEN EQP.Equipment_Name LIKE 'MiSeq%'
                                                                                                       THEN 'Run MiSeq'
                                                                                                       ELSE EQP.Equipment_Name
                                                                                                       END))
                                                  WHEN Solread.Read_Length IS NULL AND Run.Run_ID IS NOT NULL
                                                  THEN 'Run(s) Pending'
                                                  ELSE NULL
                                                  END SEPARATOR ' '))";

            $condition = "WHERE (Solread.End_Read_Type IS NULL OR Solread.End_Read_Type NOT LIKE 'IDX%')
                            AND IR.FK_Invoice_Run_Type__ID IN (1)
                            AND (IWR.Indexed = 0 OR IWR.Indexed IS NULL)
                            AND IWR.FK_Invoice__ID = $invoice_id
                            AND LIB.Library_Name = '$lib'
                            AND (Solread.Read_Length = '$read_lengths[0]' OR Solread.Read_Length IS NULL)
                            AND IWR.Billable = 'Yes'
                            ORDER BY IW.Invoiceable_Work_DateTime";

            my ($ws) = $dbc->Table_find( $tables, $field, $condition );
            $ws =~ s/,+$//;
            push @work_summary, $ws;
        }
    }
    return \@work_summary;

}

################################
# This will return a summary of all the invoiceable analyses that have been done on all the libraries for a given invoice
#
# Input: Library_Name, Invoice_ID
# Output: array ref of analysis info for each library
#
################################
sub get_analysis_summary {
################################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'dbc,invoice,library', -mandatory => 'dbc,invoice,library' );
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $invoice = $args{-invoice};
    my $library = $args{-library};

    my @invoice = @$invoice;
    my @library = @$library;
    my @work_summary;

    my %unique_invoices = map { $_ => 1 } @invoice;
    my @unique_invoices = keys %unique_invoices;

    if ( scalar @unique_invoices > 1 ) {
        return \@work_summary;
    }

    my $invoice_id = $invoice[0];
    foreach my $lib (@library) {
        my $field;
        my $tables;
        my $condition;

        $field  = "GROUP_CONCAT(DISTINCT IP.Invoice_Pipeline_Name SEPARATOR ', ')";
        $tables = "Invoiceable_Work IW
                   LEFT JOIN Invoiceable_Work_Reference IWR ON IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                   LEFT JOIN Multiplex_Run_Analysis MRA ON MRA.Multiplex_Run_Analysis_ID = IW.FK_Multiplex_Run_Analysis__ID
                   LEFT JOIN Run_Analysis RA ON RA.Run_Analysis_ID = IW.FK_Run_Analysis__ID
                   LEFT JOIN Sample MRA_Sample ON MRA_Sample.Sample_ID = MRA.FK_Sample__ID
                   LEFT JOIN Sample RA_Sample ON RA_Sample.Sample_ID = RA.FK_Sample__ID
                   LEFT JOIN Library ON Library_Name = COALESCE(MRA_Sample.FK_Library__Name, RA_Sample.FK_Library__Name)
                   LEFT JOIN Invoiceable_Run_Analysis IRA ON IRA.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                   LEFT JOIN Invoice_Pipeline IP ON IP.Invoice_Pipeline_ID = IRA.FK_Invoice_Pipeline__ID";

        $condition = "WHERE Library_Name = '$lib' AND IWR.Billable = 'Yes' AND IWR.FK_Invoice__ID = $invoice_id";

        my ($ws) = $dbc->Table_find( $tables, $field, $condition );
        $ws =~ s/,+$//;
        push @work_summary, $ws;
    }

    return \@work_summary;
}

#
# This method will set work to Invoices if the work previously had no invoices attached
# If the work had an Invoice attached then it will give a warning message
# The warning message will ask if you would like to create a credit for these work items for the selected Invoice.
#
# input: Array of Invoiceable_Work
# returns: HTML Message if it is associated with a different Invoice
# returns: null if the work is not associated with an Invoice
# returns: count of records updated
################################
sub add_invoice_check {
################################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $ids     = $args{-ids};
    my $debug   = $args{-debug};
    my @iwr_ids = @$ids;

    my $invoice_id = $self->{id};
    my @invoiced_list;
    my $invoiced_search_list;
    my $updated;
    my $message;
    my @updatable_iwr_ids;

    ## Getting either the invoice_code or the draft name.
    ## If there is no Invoice code then it selects the draft name
    my $invoice_code = $self->{fields}->{Invoice}->{Invoice_Code}->{values}->[0];

    unless ($invoice_code) {
        $invoice_code = $self->{fields}->{Invoice}->{Invoice_Draft_Name}->{values}->[0];
    }
    foreach my $iwr_id (@iwr_ids) {
        my ($invoiced) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FK_Invoice__ID', "WHERE Invoiceable_Work_Reference_ID = $iwr_id AND Invoiceable_Work_Reference_Invoiced = 'Yes'" );

        if ( !$invoiced ) {

            #$updated += $self->update_invoiceable_work_invoice( -dbc => $dbc, -invoice_id => $invoice_id, -iwr_id => $iwr_id );
            push @updatable_iwr_ids, $iwr_id;
            next;
        }
        elsif ( $invoiced == $invoice_id ) {
            print Message("Work_Reference ID $iwr_id has already been added to this invoice!") if $debug;
            next;
        }
        push( @invoiced_list, $iwr_id );
    }
    if (@updatable_iwr_ids) {
        $updated += $self->update_invoiceable_work_invoice( -dbc => $dbc, -invoice_id => $invoice_id, -iwr_ids => \@updatable_iwr_ids );

        # if ( $updated > 0 ) { print Message("$updated records have been added to invoice $invoice_code") }
        if ( $updated > 0 && $debug ) { print Message("Records have been added to invoice $invoice_code") }
    }
    else {
        print Message("There are no updatable Invoiceable Work Reference IDs/No works have been selected") if $debug;
    }

    $invoiced_search_list = join ',', @invoiced_list;

    if ($invoiced_search_list) {
        my $message_table = $dbc->Table_retrieve_display(
            "Invoiceable_Work_Reference AS IWR
         LEFT JOIN Invoiceable_Work AS IW ON IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
         LEFT JOIN Plate ON Plate.Plate_ID = IW.FK_Plate__ID",
            [ 'IW.Invoiceable_Work_ID AS Work_ID', 'IWR.Invoiceable_Work_Reference_ID AS Reference_ID', 'Plate.FK_Library__Name AS Library', 'IWR.FK_Invoice__ID AS Conflicting_Invoice' ],
            "WHERE IWR.Invoiceable_Work_Reference_ID in ($invoiced_search_list)",
            -title            => 'Work and Conflicting Invoices',
            -return_html      => 1,
            -selectable_field => 'Reference_ID',
            -alt_message      => "No conflicting invoices"
        );

        $message .= "Warning: ";
        $message .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Adding_Credit' );
        $message
            .= "You tried to add these work items to invoice $invoice_code.<br> The following work items have been selected but are already attached to Invoices.<br>You are able to assign a credit to an Invoice by selecting the \"Create Credit\" button.<br> $message_table<br>";
        $message .= alDente::Invoice_Views::credit_invoice_btn( -dbc => $dbc, -id => $invoice_id );
        $message .= end_form();
        print Message($message);
    }

    return $updated;
}

##################################
# Input: List of emails to send this to
# Output: Emails people on the emailing list
#
# This method should be called once every release and will be sent to the lab leaders to inform them about this list
# The intent of this email is to make sure that the Invoice_Protocol list remians updated.
#
##################################
sub invoice_protocol_email {
##################################
    my %args    = &filter_input( \@_, -args => 'dbc' );
    my $dbc     = $args{-dbc};
    my $emails  = $args{-emails} || 'aldente@bcgsc.ca';
    my $subject = 'Current Tracking List of Invoiceable Items';
    my $contact = 'ProjectsInvoicing@bcgsc.ca';
    my $msg;

    my $invoice_protocol_table_upstream_library_construction = $dbc->Table_retrieve_display(
        "Invoice_Protocol",
        [ 'FK_Lab_Protocol__ID AS Lab_Protocol', 'Invoice_Protocol_Type AS Protocol_Type', 'Invoice_Protocol_Name AS Shown_As', 'Invoice_Protocol_Status' ],
        "WHERE Invoice_Protocol_Status = 'Active' AND Invoice_Protocol_Type = 'Upstream_Library_Construction'",
        -title       => 'List of Upstream Library Construction Invoice Protocols',
        -return_html => 1,
        -alt_message => "No records found for Upstream Library Construction",
    );

    my $invoice_protocol_table_library_construction = $dbc->Table_retrieve_display(
        "Invoice_Protocol",
        [ 'FK_Lab_Protocol__ID AS Lab_Protocol', 'Invoice_Protocol_Type AS Protocol_Type', 'Invoice_Protocol_Name AS Shown_As', 'Invoice_Protocol_Status' ],
        "WHERE Invoice_Protocol_Status = 'Active' AND Invoice_Protocol_Type = 'Library_Construction'",
        -title       => 'List of Library Construction Invoice Protocols',
        -return_html => 1,
        -alt_message => "No records found for Library Construction",
    );

    my $invoice_protocol_table_qc = $dbc->Table_retrieve_display(
        "Invoice_Protocol",
        [ 'FK_Lab_Protocol__ID AS Lab_Protocol', 'Invoice_Protocol_Type AS Protocol_Type', 'Invoice_Protocol_Name AS Shown_As', 'Invoice_Protocol_Status' ],
        "WHERE Invoice_Protocol_Status = 'Active' AND Invoice_Protocol_Type = 'Sample_QC'",
        -title       => 'List of Sample QC Invoice Protocols',
        -return_html => 1,
        -alt_message => "No records found for Sample QC",
    );

    my $invoice_protocol_table_rd = $dbc->Table_retrieve_display(
        "Invoice_Protocol",
        [ 'FK_Lab_Protocol__ID AS Lab_Protocol', 'Invoice_Protocol_Type AS Protocol_Type', 'Invoice_Protocol_Name AS Shown_As', 'Invoice_Protocol_Status' ],
        "WHERE Invoice_Protocol_Status = 'Active' AND Invoice_Protocol_Type = 'RD_Qubit'",
        -title       => 'List of Raindance Invoice Protocols',
        -return_html => 1,
        -alt_message => "No records found for Raindance",
    );

    my $invoice_run_type_table = $dbc->Table_retrieve_display(
        "Invoice_Run_Type",
        [ 'Invoice_Run_Type_Name AS Run_Name', 'Invoice_Run_Type_Status AS Invoice_Run_Status' ],
        "WHERE Invoice_Run_Type_Status = 'Active'",
        -title       => 'List of Invoice Run Types',
        -return_html => 1,
        -alt_message => "No records found for Invoice Run Type",
    );

    my $invoice_pipeline_table = $dbc->Table_retrieve_display(
        "Invoice_Pipeline",
        [ 'Invoice_Pipeline_Name', 'FK_Pipeline__ID AS Pipeline', 'Invoice_Pipeline_Status' ],
        "WHERE Invoice_Pipeline_Status ='Active'",
        -title       => 'List of Invoice Pipelines',
        -return_html => 1,
        -alt_message => "No records found for Invoice Pipeline",
    );

    $msg = "<p ></p>The following lab protocols are being tracked as invoiceable<br />";
    $msg .= "Please email <a href=\"mailto:$contact\">$contact</a> if the list needs to be updated.<br /></p>";
    $msg .= "$invoice_protocol_table_upstream_library_construction<br />";
    $msg .= "$invoice_protocol_table_library_construction<br />";
    $msg .= "$invoice_protocol_table_qc<br />";
    $msg .= "$invoice_protocol_table_rd<br />";
    $msg .= "$invoice_run_type_table<br />";
    $msg .= "$invoice_pipeline_table<br />";

    require alDente::Subscription;
    my $ok = alDente::Subscription::send_notification(
        -dbc          => $dbc,
        -name         => "Invoice Tracking List",
        -from         => 'aldente@bcgsc.ca',
        -subject      => "$subject",
        -body         => $msg,
        -content_type => 'html',
        -to           => "$emails",
    );

    return $ok;
}

###############################
# Description:
#	- This method checks if a given lab protocol/run/analysis is invoiceable
#	- input argument 'type':  can be one of 'protocol', 'run', 'analysis'
#	- input argument 'value':
#		If type is 'protocol', lab protocol ID should be passed in as value.
#		If type is 'run', run type should be passed in as value.
#		If type is 'analysis', pipeline ID should be passed in as value.
#
# <snip>
#	Usage example:
#		my $invoiceable = alDente::Invoice::is_invoiceable( -dbc => $dbc, -type => 'protocol', -value => $protocol_id );
#		my $invoiceable = alDente::Invoice::is_invoiceable( -dbc => $dbc, -type => 'run', -value => $run_id );
#		my $invoiceable = alDente::Invoice::is_invoiceable( -dbc => $dbc, -type => 'analysis', -value => $analysis_id );
#
#	Return:
#		Scalar. non-zero if invoiceable; 0 if not.
# </snip>
###############################
sub is_invoiceable {
###############################
    my %args  = &filter_input( \@_, -args => 'dbc,type,value', -mandatory => 'dbc,type,value' );
    my $dbc   = $args{-dbc};
    my $type  = $args{-type};
    my $value = $args{-value};
    my $invoiceable;

    if ( $type =~ /protocol/xmsi ) {
        ($invoiceable) = $dbc->Table_find( 'Invoice_Protocol', 'Invoice_Protocol_ID', "WHERE FK_Lab_Protocol__ID = $value and Invoice_Protocol_Status = 'Active'" );
    }
    elsif ( $type =~ /run/xmsi ) {
        ($invoiceable) = $dbc->Table_find( 'Invoice_Run_Type', 'Invoice_Run_Type_ID', "WHERE Invoice_Run_Type_Name = '$value' AND Invoice_Run_Type_Status = 'Active'" );
    }
    elsif ( $type =~ /analysis/xmsi ) {
        ($invoiceable) = $dbc->Table_find( 'Invoice_Pipeline', 'Invoice_Pipeline_ID', "WHERE FK_Pipeline__ID = $value and Invoice_Pipeline_Status = 'Active'" );
    }

    return $invoiceable;
}

1;
