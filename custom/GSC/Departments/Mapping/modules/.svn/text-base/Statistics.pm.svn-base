######################################
#
# Controller Method for Mapping Statistics
#
#
#
######################################

package Mapping::Statistics;

use strict;
use warnings;
use Benchmark;

use RGTools::RGIO;

use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

use vars qw( %Benchmark );

#####################
#
#
#
#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );

    my $self = {};
    $self->{dbc} = $args{-dbc};

    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}

###############################
#
#
#
###############################
sub get_run_info_validation_date {
###############################
    my $self = shift;
    my %args = &filter_input( \@_ ,-mandatory=>'key_field');

    my $debug = $args{-debug};
    my $condition = $args{-condition} || 1;
    my $key_field = $args{-key_field};

    my $run_name = "Replace(Run_Directory,FK_Library__Name,Concat('<input type=\"checkbox\" name=\"FK_Plate__ID\" value=\"',Run_ID,'\" />',FK_Library__Name,'-')) AS Run_Directory";
    my %result = $self->{dbc}->Table_retrieve( 'Plate,Run,GelRun,Branch,Branch_Condition,Change_History',
                                               [ $key_field, $run_name, 'Modified_Date', 'New_Value', 'Run_ID', 'Run_Validation' ],
                                               "WHERE $condition AND Plate_ID=FK_Plate__ID AND FK_Run__ID = Run_ID AND Plate.FK_Branch__Code = Branch_Code AND Branch_Condition.FK_Branch__Code = Branch_Code AND RUN_ID = Change_History.Record_ID AND FK_DBField__ID = 2846 Group By Change_History_ID ORDER BY FK_Library__Name,Plate_Number,Parent_Quadrant,Run_ID,Change_History.Modified_Date",
                                               -debug => $debug, -pad=>1
                                               );

    my ($case_key) = grep (/CASE/, keys %result);

    my %new_result;
    my @diff_validation;
    my @diff_validation_name;
    my $index = -1;
    while(defined $result{Run_ID}[++$index]) {
        my $run_directory = $result{Run_Directory}[$index];
	my $run_key = $result{$case_key}[$index];
	my $run_id = $result{Run_ID}[$index];
	my $run_validation = $result{Run_Validation}[$index];
	my $new_value = $result{New_Value}[$index];
	my $check_index = $index + 1;

	## Reached the last modified validation value, therefore build return hash
	if (!defined $result{Run_ID}[$check_index] || $run_id != $result{Run_ID}[$check_index]) {
	    push @{$new_result{$run_key}}, $run_directory;
	    if ($run_validation ne $new_value) {
		push @diff_validation, $run_id;
		$run_directory =~ s/<.*>//;
		push @diff_validation_name, "$run_directory $new_value to $run_validation";
	    }
	}
    }
    if (@diff_validation) {
	my $run_ids = join (",", @diff_validation);
	my $run_names = join (",", @diff_validation_name);
	$self->{dbc}->{session}->warning("Validation for runs $run_ids ($run_names) have changed since the given time period");
    }
    return %new_result;
}

###############################
#
#
#
###############################
sub get_run_info {
###############################
    my $self = shift;
    my %args = &filter_input( \@_ ,-mandatory=>'key_field');

    my $debug = $args{-debug};
    my $condition = $args{-condition} || 1;
    my $key_field = $args{-key_field};

    my $run_name = "Replace(Run_Directory,FK_Library__Name,Concat('<input type=\"checkbox\" name=\"FK_Plate__ID\" value=\"',Run_ID,'\" />',FK_Library__Name,'-')) AS Run_Directory";
    my %result = $self->{dbc}->Table_retrieve( 'Plate,Run,GelRun,Branch,Branch_Condition',
                                               [ $key_field, $run_name ],
                                               "WHERE $condition AND Plate_ID=FK_Plate__ID AND FK_Run__ID = Run_ID AND Plate.FK_Branch__Code = Branch_Code AND Branch_Condition.FK_Branch__Code = Branch_Code Group By Run_ID ORDER BY FK_Library__Name,Plate_Number,Parent_Quadrant",
                                               -key=>$key_field, -debug => $debug, -pad=>1
                                               );

    foreach my $key (keys %result) {
        $result{$key} = $result{$key}{Run_Directory};
    }
    return %result;
}

sub get_targets_remain {
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $debug = $args{-debug};
    my $condition = $args{-condition} || 1;
    my %result = %{$args{-result}}; 

    my @library_list = $self->{dbc}->Table_find( 'Plate,Run,GelRun,Branch,Branch_Condition',
                                               'FK_Library__Name',
                                               "WHERE $condition AND Plate_ID=FK_Plate__ID AND FK_Run__ID = Run_ID AND Plate.FK_Branch__Code = Branch_Code AND Branch_Condition.FK_Branch__Code = Branch_Code Group By Run_ID ORDER BY FK_Library__Name,Plate_Number,Parent_Quadrant",
                                               -distinct=>1, -debug => $debug
                                               );
    #print HTML_Dump @library_list;
    my $library_condition = join(",", map {"'$_'"} @library_list);
    my @max_plate_number_list = $self->{dbc}->Table_find( 'Plate', 'MAX(Plate_Number)', "WHERE FK_Library__Name IN ($library_condition) GROUP BY FK_Library__Name ORDER BY FK_Library__Name");
    my @min_plate_number_list = $self->{dbc}->Table_find( 'Plate', 'MIN(Plate_Number)', "WHERE FK_Library__Name IN ($library_condition) GROUP BY FK_Library__Name ORDER BY FK_Library__Name");


    #print HTML_Dump @max_plate_number_list;
    for (my $index = 0; $index <= $#library_list; $index++) {
	my $key; my $key2; my $key3; my $key4;
	if (@library_list == 1) { 
	    $key = 'Targets Remain';
	    $key2 = 'Approved';
	    $key3 = 'Pending';
	    $key4 = 'Pending Re-Test: Gel On Hold';
	}
	else { 
	    $key = "Targets Remain - $library_list[$index] - REPLACEKEY Digest";
	    $key2 = "Approved - $library_list[$index] - REPLACEKEY Digest";
	    $key3 = "Pending - $library_list[$index] - REPLACEKEY Digest";
            $key4 = "Pending Re-Test: Gel On Hold - $library_list[$index] - REPLACEKEY Digest";
	}
	my @digests = qw (Single Double);
	for my $digest (@digests) {
	    my $newkey = $key;
	    my $newkey2 = $key2;
	    my $newkey3 = $key3;
	    my $newkey4 = $key4;
	    $newkey =~ s/REPLACEKEY/$digest/;
	    $newkey2 =~ s/REPLACEKEY/$digest/;
	    $newkey3 =~ s/REPLACEKEY/$digest/;
            $newkey4 =~ s/REPLACEKEY/$digest/;

	    my @all; 
	    if ($result{$newkey2}) { push @all, @{$result{$newkey2}}; }
	    if ($result{$newkey3}) { push @all, @{$result{$newkey3}}; }
	    if ($result{$newkey4}) { push @all, @{$result{$newkey4}}; }
	    if (!@all) { next; }
	    my $check_list = join (",", @all);

	    #from min plate number to max plate number
	    for (my $index2 = $min_plate_number_list[$index]; $index2 <= $max_plate_number_list[$index]; $index2++) {
		#for 96 well gelruns
		if ($check_list =~ /$library_list[$index]-\d+\./) {
		    my $target = "$library_list[$index]-$index2.";
		    if ($check_list !~ /$target/) {
			#print "$target<br>";
			push (@{$result{$newkey}}, $target);
		    }
		}
		#for 384 well gelruns
		else {
		    my @quads = qw(a b c d);
		    for my $quad (@quads) {
			my $target = "$library_list[$index]-$index2$quad";
			if ($check_list !~ /$target/) {
			    #print "$target";
			    push (@{$result{$newkey}}, $target);
			}
		    }
		}
	    }

	    #case of no single and double digest
	    if (@library_list == 1) { last }
	}
    }

    return \%result;
}

###############################
#
#
#
###############################
sub get_run_validation_info {
###############################
    my $self = shift;
    my %args = &filter_input( \@_ ,-mandatory=>'key_field');

    my $debug = $args{-debug};
    my $condition = $args{-condition} || 1;
    my $key_field = $args{-key_field};
    my $more = $args{-more};
    my $validation_date = $args{-validation_date};
    
    my $newcondition = $condition;# . " AND Run.QC_Status != 'Re-Test'"; 
    my %result;
    if (!$validation_date) { %result = $self->get_run_info( -condition => $newcondition, -key_field=>$key_field, -debug => $debug ); }
    else { %result = $self->get_run_info_validation_date( -condition => $newcondition, -key_field=>$key_field, -debug => $debug ); }

    my $newcondition2 = $condition . " AND Run.QC_Status = 'Re-Test'";
    my %result2;
    if (!$validation_date) { %result2 = $self->get_run_info( -condition => $newcondition2, -key_field=>$key_field, -debug => $debug ); }
    else { %result2 = $self->get_run_info_validation_date( -condition => $newcondition2, -key_field=>$key_field, -debug => $debug ); }
    
    if ($result{Pending}) {
	#$result{Pending} = set_difference($result{Pending},$result2{Pending});
	#to preseve order
	my %hash = map { $_ => 1; } grep { $_ } @{$result2{Pending}};
	my @newarray;
	for (my $i=0; $i< @{$result{Pending}}; $i++) {
	    if (!$hash{$result{Pending}->[$i]}) { push @newarray, $result{Pending}->[$i]; }
	}
	$result{Pending} = \@newarray;
    }
    elsif ($more) {
	for my $key (keys %result) {
	    if ($key =~ /^Pending/) {
		#$result{$key} = set_difference($result{$key},$result2{$key});
		#to preseve order
		my %hash = map { $_ => 1; } grep { $_ } @{$result2{$key}};
		my @newarray;
		for (my $i=0; $i< @{$result{$key}}; $i++) {
                    if (!$hash{$result{$key}->[$i]}) { push @newarray, $result{$key}->[$i]; }
		}
		$result{$key} = \@newarray;
	    }
	}
    }
    elsif (!$more) { $result{Pending} = [] }

    if ($result2{Pending}) { $result{'Pending Re-Test: Gel On Hold'} = $result2{Pending} }
    elsif ($more) {
        for my $key (keys %result2) {
            if ($key =~ /^Pending/) {
		my $newkey = $key;
		$newkey =~ s/Pending/Pending Re-Test: Gel On Hold/;
		$result{$newkey} = $result2{$key};
	    }
        }
    }
    elsif (!$more) { $result{'Pending Re-Test: Gel On Hold'} = [] }

        %result = %{$self->get_targets_remain(-condition=>$condition,-result=>\%result)} if !$validation_date;
    #print HTML_Dump %result;
    #print HTML_Dump $condition;

    return %result;
}

###############################
#
#
#
#
###############################
sub get_lab_protocol_steps {
###############################
    my $self = shift;
    my %args = &filter_input( \@_, -mandatory => 'lab_protocol' );

    my $Lab_Protocol = $args{-lab_protocol};
    my $condition = $args{-condition} || 1;

    my ($analysis_protocol) = $self->{dbc}->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "WHERE Lab_Protocol_Name='$Lab_Protocol'" );
    my %result =  $self->{dbc}->Table_retrieve(
        'Run,Plate,Plate_Prep,Prep',
        [ 'Prep_Name AS Analysis_Step', 'Run_Directory AS Detail' ],
        "WHERE $condition AND Run.FK_Plate__ID=Plate_ID AND Plate_Prep.FK_Plate__ID=Plate_ID AND FK_Prep__ID=Prep_ID AND
                    FK_Lab_Protocol__ID=$analysis_protocol ORDER BY Plate_Number,Parent_Quadrant,Prep_DateTime",
        -key=>'Analysis_Step'

    );

    foreach my $key (keys %result) {
        $result{$key} = $result{$key}{Detail};
    }
    return %result;
}

##############################
#
#
#
##############################
sub get_run_fail_info {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $condition = $args{-condition} || 1;

    my $run_name = "Replace(Run_Directory,FK_Library__Name,Concat('<input type=\"checkbox\" name=\"FK_Plate__ID\" value=\"',Run_ID,'\" />',FK_Library__Name,'-')) AS Run_Directory";
    my ($plate_class_id) = $self->{dbc}->Table_find( 'Object_Class', 'Object_Class_ID', "where Object_Class='Plate'" );
    my %result = $self->{dbc}->Table_retrieve(
        'Plate,Run,GelRun,Fail,FailReason',
        [ 'failreason_name AS Gel_Fail_Reason', $run_name ],
        "where fk_run__Id=run_id and fk_plate__Id=plate_id and object_id=plate_id and fk_failreason__Id=failreason_id and Fail.fk_object_class__Id=$plate_class_id and $condition ORDER BY Plate_Number,Parent_Quadrant",
        -key=>'Gel_Fail_Reason'

    );

    foreach my $key (keys %result) {
        $result{$key} = $result{$key}{Run_Directory};
    }
    return %result;
}

##############################
sub get_lane_fail_info {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $condition = $args{-condition} || 1;

    my $run_name = "Replace(Run_Directory,FK_Library__Name,Concat('<input type=\"checkbox\" name=\"FK_Plate__ID\" value=\"',Run_ID,'\" />',FK_Library__Name,'-'))";
    my ($lane_class_id) = $self->{dbc}->Table_find( 'Object_Class', 'Object_Class_ID', "where Object_Class='Lane'" );
    my %result = $self->{dbc}->Table_retrieve(
        'Plate,Run,GelRun,Lane,Fail,FailReason',
        [ 'failreason_name AS Lane_Fail_Reason', "CONCAT($run_name,' (',Well,':',Lane_Number,')') AS Detail" ],
        "where fk_gelrun__Id=gelrun_id and fk_run__Id=run_id and fk_plate__Id=plate_id and object_id=lane_id and fk_failreason__Id=failreason_id and Fail.fk_object_class__Id=$lane_class_id and Run_Validation = 'Approved' and Run_Test_Status = 'Production' and $condition  ORDER BY Plate_Number,Parent_Quadrant",
        -key=>'Lane_Fail_Reason'
    );
    my %totalhash;
    my %totalhash2;
    foreach my $key (keys %result) {
	#push (@{$result{Total}}, @{$result{$key}{Detail}});
	map { $totalhash{$_}++ } @{$result{$key}{Detail}};
	map { $totalhash2{$_}{$key}++ } @{$result{$key}{Detail}};
        $result{$key} = $result{$key}{Detail};
    }
    push (@{$result{Total}}, sort keys %totalhash);
    for my $key (keys %totalhash2) {
	if (keys %{$totalhash2{$key}} > 1) {
	    my $all = join ("; ", keys %{$totalhash2{$key}});
	    my $num = 0;
	    for my $key2 (keys %{$totalhash2{$key}}) {$num += $totalhash2{$key}{$key2};}
	    #print "$key: $all: $num<br>";
	}
	#if ($totalhash{$key} > 1) {print "$key here $totalhash{$key}<br>";}
    }
    return %result;

}

###############################
#
#
#
###############################
sub get_pipeline_protocol_plate_counts {
###############################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $condition = $args{-condition} || 1;

    my %return;

    my $PIPELINE_NAME = 'Mapping Pipeline';
    my $dbc = $self->{dbc};
    my %pipelines = $dbc->Table_retrieve( 'Pipeline AS Parent LEFT JOIN Pipeline AS Child ON Child.FKParent_Pipeline__ID = Parent.Pipeline_ID ', [ 'Child.Pipeline_ID', 'Child.Pipeline_Name' ], "WHERE Parent.Pipeline_Name='$PIPELINE_NAME'" );
    if (%pipelines) {

        my ($lab_protocol_object_id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class='Lab_Protocol'" );
        %pipelines = %{ rekey_hash( \%pipelines, 'Pipeline_ID' ) };

        foreach my $pipe ( keys %pipelines ) {
            my %Result;

            #$stat->Set_sub_header(b("Pipeline "),'lightblue');
            my %protocols = $dbc->Table_retrieve( 'Pipeline_Step,Lab_Protocol',
                    [ 'Lab_Protocol_ID', 'Lab_Protocol_Name', 'Pipeline_Step_ID' ],
                    "WHERE FK_Object_Class__ID=$lab_protocol_object_id AND Object_ID=Lab_Protocol_ID AND FK_Pipeline__ID = $pipe ORDER BY Pipeline_Step_Order" );
            unless (%protocols) { next }

            my $i = -1;
            while ( $protocols{Lab_Protocol_ID}[ ++$i ] ) {
                my $progress = alDente::Protocol->new( -dbc => $dbc, -pipeline => $pipe, -id => $protocols{Lab_Protocol_ID}[$i], -pipeline_step_id=>$protocols{Pipeline_Step_ID}[$i], -library_condition => $condition );
                $progress->get_progress();
                push @{ $Result{'Protocol Name'} }, $protocols{Lab_Protocol_Name}[$i];
                push @{ $Result{'Ready'} },         alDente::Protocol::_get_plate_information($dbc,$progress->{ready_plates},-check_box=>0,-brief=>1       ) if ( $progress->{ready_plates} );
                push @{ $Result{'In Progress'} },   alDente::Protocol::_get_plate_information($dbc,$progress->{in_progress_plates},-check_box=>0,-brief=>1 ) if ( $progress->{in_progress_plates} );
                push @{ $Result{'Failed'} },        alDente::Protocol::_get_plate_information($dbc,$progress->{failed_plates},-check_box=>0,-brief=>1      ) if ( $progress->{failed_plates} );
                push @{ $Result{'Completed'} },     alDente::Protocol::_get_plate_information($dbc,$progress->{completed_plates},-check_box=>0,-brief=>1   ) if ( $progress->{completed_plates} );
            }

            $return{ $pipelines{$pipe}{Pipeline_Name}[0] } = \%Result;
        } ## end foreach my $pipe ( keys %pipelines)0
    } ## end if (%pipelines)

    #-keys=>['Protocol Name','Ready','In Progress','Completed','Failed'];
    return %return;
} ## end sub get_pipeline_protocol_plate_counts
1;
