################################################################################
#
# Funding.pm
#
# By Ash Shafiei, October 2008
################################################################################
package alDente::Funding;
##############################
# standard_modules_ref       #
##############################
use Carp;
use strict;

#@ISA = qw(SDB::DB_Object);

##############################
# custom_modules_ref         #
##############################
#use alDente::Form;
#use alDente::SDB_Defaults;
#use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::RGmath;
use SDB::HTML;
use alDente::Tools;

#use RGTools::Views;
#use RGTools::Conversion;
##############################
# global_vars                #
##############################
use vars qw( $Connection  %Configs  $Security);
######################################################
##          Public Methods                          ##
######################################################

##############################
# constructor                #
##############################
#########
sub new {
#########
    #
    # Constructor of the object
    #
    my $this = shift;
    my $class = ref($this) || $this;

    my %args = @_;
    my $id   = $args{-id};
    my $dbc  = $args{-dbc};    #|| $Connection->dbh(); # Database handle

    my $self = {};

    bless $self, $class;
    $self->{dbc} = $dbc;

    return $self;
}

#########
sub search_funding_ids {
#########
    my $self       = shift;
    my %args       = @_;
    my $dbc        = $args{-dbc};
    my $library    = $args{-library};
    my $project_id = $args{-project};
    my $goal_id    = $args{-funding};
    my $table      = 'Work_Request';

    ## Building The Search Condition
    my $search_condition = "WHERE 1  ";
    if ($goal_id) {
        $search_condition .= " AND Work_Request.FK_Goal__ID = $goal_id ";
    }
    if ($library) {
        $search_condition .= " AND FK_Library__Name = '$library' ";
    }
    if ($project_id) {
        $search_condition .= " AND FK_Project__ID = $project_id ";
        $table            .= ' ,Library';
        $search_condition .= " AND FK_Library__Name = Library_Name ";
    }

    ##  To get rid of records which are not considered 'Library'. This will be temporary until more clearly defined
    $search_condition .= " AND Scope = 'Library'";

    my @id_list = $dbc->Table_find(
        -table     => $table,
        -fields    => "FK_Funding__ID",
        -condition => "$search_condition " . " Order BY FK_Funding__ID ",
        -distinct  => "distinct"
    );
    return \@id_list;

}

########################
sub get_funding_ids {
########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc};

    ## Getting Search Parameters
    my $keyword     = $args{-keyword};
    my $fields_ref  = $args{-fields};
    my $values_ref  = $args{ -values };
    my $from        = $args{-from};
    my $until       = $args{-to};
    my $source_ref  = _return_value( -fields => $fields_ref, -values => $values_ref, -target => 'Funding_Source' );
    my $status_ref  = _return_value( -fields => $fields_ref, -values => $values_ref, -target => 'Funding_Status' );
    my $type_ref    = _return_value( -fields => $fields_ref, -values => $values_ref, -target => 'Funding_Type' );
    my $org_ref     = _return_value( -fields => $fields_ref, -values => $values_ref, -target => 'FKSource_Organization__ID' );
    my $name_ref    = _return_value( -fields => $fields_ref, -values => $values_ref, -target => 'Funding_Name' );
    my $code_ref    = _return_value( -fields => $fields_ref, -values => $values_ref, -target => 'Funding_Code' );
    my @source      = @$source_ref if $source_ref;
    my @status      = @$status_ref if $status_ref;
    my @type        = @$type_ref if $type_ref;
    my @org         = @$org_ref if $org_ref;
    my @name        = @$name_ref if $name_ref;
    my @code        = @$code_ref if $code_ref;
    my $temp        = $type[0];
    my $type_list   = join "' , '", @$temp if $temp;
    my $temp        = $status[0];
    my $status_list = join "' , '", @$temp if $temp;
    my $temp        = $source[0];
    my $source_list = join "' , '", @$temp if $temp;

    ## Building The Search Condition
    my $search_condition = "WHERE 1  ";

    if ($keyword) {
        $search_condition .= " AND (Funding_Code LIKE '%$keyword%' OR Funding_Name LIKE '%$keyword%' )";
    }
    else {
        if ( $code[0][0] ) {
            $search_condition .= " AND Funding_Code = '$code[0][0]' ";
        }
        if ( $name[0][0] ) {
            $search_condition .= " AND Funding_Name = '$name[0][0]' ";
        }
        if ( $org[0][0] ) {
            $search_condition .= " AND FKSource_Organization__ID = '$org[0][0]' ";
        }
        if ($from) {
            $search_condition .= " AND ApplicationDate >= '$from' ";
        }
        if ($until) {
            $search_condition .= " AND ApplicationDate <= '$until' ";
        }
        if ($type_list) {
            $search_condition .= " AND Funding_Type IN  ('$type_list') ";
        }
        if ($status_list) {
            $search_condition .= " AND Funding_Status IN  ('$status_list') ";
        }
        if ($source_list) {
            $search_condition .= " AND Funding_Source IN ('$source_list') ";
        }
    }
    my @approved_list;

    if ($keyword) {
        my @info = $dbc->Table_find(
            -table     => 'Funding',
            -fields    => "Funding_ID, Funding_Code, Funding_Name",
            -condition => "$search_condition "
        );
        for my $counter ( 0 .. @info - 1 ) {
            ( my $f_id, my $f_code, my $f_name ) = split ',', $info[$counter];

            #if ( ( $f_name =~ /\b$keyword\b/ ) || ( $f_code =~ /\b$keyword\b/ ) ) {
            push @approved_list, $f_id;

            #}
        }
    }
    else {
        @approved_list = $dbc->Table_find(
            -table     => 'Funding',
            -fields    => "Funding_ID",
            -condition => "$search_condition "
        );
    }

    return \@approved_list;
}

#####################
sub get_Projects {
#####################
    my $self       = shift;
    my %args       = filter_input( \@_, -args => 'funding_id', -mandatory => 'funding_id' );
    my $funding_id = $args{-funding_id};
    my $dbc        = $args{-dbc} || $self->{dbc};

    my @projects = $dbc->Table_find( 'Project,Library,Work_Request', 'Project_ID', "WHERE FK_Project__ID=Project_ID AND Work_Request.FK_Library__Name=Library_Name AND Work_Request.FK_Funding__ID=$funding_id", -distinct => 1 );
    return \@projects;
}

#####################
sub get_Libraries {
#####################
    my $self       = shift;
    my %args       = filter_input( \@_, -args => 'funding_id', -mandatory => 'funding_id' );
    my $funding_id = $args{-funding_id};
    my $dbc        = $args{-dbc} || $self->{dbc};

    my @libraries = $dbc->Table_find( 'Project,Library,Work_Request', 'Library_Name', "WHERE FK_Project__ID=Project_ID AND Work_Request.FK_Library__Name=Library_Name AND Work_Request.FK_Funding__ID=$funding_id", -distinct => 1 );
    return \@libraries;
}

#######################
sub get_detail_ids {
#######################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $id   = $args{-funding_id};

    my @goal_list = $dbc->Table_find(
        -table     => 'Work_Request,Library',
        -fields    => "FK_Goal__ID",
        -distinct  => 'Distinct',
        -condition => "where FK_Funding__ID = $id and FK_Library__Name = Library_Name"
    );
    my @library_list = $dbc->Table_find(
        -table     => 'Work_Request,Library',
        -fields    => "FK_Library__Name",
        -distinct  => 'Distinct',
        -condition => "where FK_Funding__ID = $id and FK_Library__Name = Library_Name"
    );
    my @project_list = $dbc->Table_find(
        -table     => 'Work_Request,Library',
        -fields    => "FK_Project__ID",
        -distinct  => 'Distinct',
        -condition => "where FK_Funding__ID = $id and FK_Library__Name = Library_Name"
    );

    return \@project_list, \@goal_list, \@library_list,;
}

#########
sub get_plate_ids {
#########
    my $self       = shift;
    my %args       = @_;
    my $dbc        = $args{-dbc};
    my $id         = $args{-funding_id};
    my @plate_list = $dbc->Table_find(
        -table     => 'Work_Request,Plate',
        -fields    => "Plate_ID",
        -distinct  => 'Distinct',
        -condition => "WHERE FK_Work_Request__ID = Work_Request_ID and FK_Funding__ID = $id ORDER BY Plate_ID"
    );

    my @untied_plate_list = $dbc->Table_find(
        -table     => 'Work_Request,Plate, Library',
        -fields    => "Plate_ID",
        -distinct  => 'Distinct',
        -condition => "WHERE Plate.FK_Library__Name = Library_Name AND  Work_Request.FK_Library__Name = Library_Name AND  Work_Request.FK_Funding__ID = $id ORDER BY Plate_ID"
    );

    #  require RGTools::RGmath;
    #  my $union_a = &union (\@one,\@two);
    my $final_list = union( \@untied_plate_list, \@plate_list );
    return $final_list;
}

##########################
sub funding_analysis_trigger {
##########################
    my $self = shift;

    my %args                      = filter_input( \@_ );
    my $dbc                       = $args{-dbc} || $self->{dbc};
    my $run_analysis_id           = $args{-run_analysis_id};
    my $multiplex_run_analysis_id = $args{-multiplex_run_analysis_id};
    my $genome_id;
    my $ok;
    my $datetime = &date_time();

    if ($run_analysis_id) {

        ## check if it's part of the plate work request

        ($genome_id) = $dbc->Table_find( 'Run_Analysis,Run,Plate LEFT JOIN Work_Request ON Plate.FK_Work_Request__ID = Work_Request_ID JOIN Funding_Attribute ON Work_Request.FK_Funding__ID = Funding_Attribute.FK_Funding__ID',
            'Attribute_Value', "WHERE Run_Analysis.FK_Run__ID = Run_ID and Plate_ID = Run.FK_Plate__ID and Run_Analysis_Id = $run_analysis_id" );

        unless ($genome_id) {
            $dbc->Table_find( 'Run_Analysis,Run,Plate LEFT JOIN Work_Request ON Work_Request.FK_Library__Name = Plate.FK_Library__Name  JOIN Funding_Attribute ON Work_Request.FK_Funding__ID = Funding_Attribute.FK_Funding__ID',
                'Attribute_Value', "WHERE Run_Analysis.FK_Run__ID = Run_ID and Plate_ID = Run.FK_Plate__ID and Run_Analysis_Id = $run_analysis_id" );
        }
        if ($genome_id) {
            my ($attribute_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = 'FKAnalysis_Genome__ID' and Attribute_Class = 'Run_Analysis'" );
            $ok = $dbc->Table_append_array( 'Run_Analysis_Attribute', [ 'FK_Run_Analysis__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' ], [ $run_analysis_id, $attribute_id, $genome_id, 141, $datetime ], -autoquote => 1 );
        }

    }
    elsif ($multiplex_run_analysis_id) {
        ($genome_id) = $dbc->Table_find(
            'Multiplex_Run_Analysis,Sample,ReArray,Plate as SP LEFT JOIN Work_Request ON SP.FK_Work_Request__ID = Work_Request_ID JOIN Funding_Attribute ON Work_Request.FK_Funding__ID = Funding_Attribute.FK_Funding__ID',
            'Attribute_Value',
            "WHERE Multiplex_Run_Analysis.FK_Sample__ID = Sample_ID and ReArray.FK_Sample__ID = Sample_ID and ReArray.FKSource_Plate__ID = SP.Plate_ID and Multiplex_Run_Analysis_ID = $multiplex_run_analysis_id "
        );
        unless ($genome_id) {
            ($genome_id) = $dbc->Table_find( 'Multiplex_Run_Analysis,Sample JOIN Work_Request ON Sample.FK_Library__Name = Work_Request.FK_Library__Name JOIN Funding_Attribute ON Work_Request.FK_Funding__ID = Funding_Attribute.FK_Funding__ID',
                'Attribute_Value', "WHERE Multiplex_Run_Analysis.FK_Sample__ID = Sample_ID and Multiplex_Run_Analysis_ID = $multiplex_run_analysis_id " );
        }
        if ($genome_id) {
            my ($attribute_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = 'FKAnalysis_Genome__ID' and Attribute_Class = 'Multiplex_Run_Analysis'" );

            $ok = $dbc->Table_append_array(
                'Multiplex_Run_Analysis_Attribute',
                [ 'FK_Multiplex_Run_Analysis__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' ],
                [ $multiplex_run_analysis_id,      $attribute_id,      $genome_id,        141,               $datetime ],
                -autoquote => 1
            );
        }
    }

}
##########################

##################################
sub get_funding_genome_reference {
##################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $library = $args{-library};               ## input is plate

    ## check specific work request for plate

    ## if pooled

    ## check library work request
    my %funding;
    %funding = $dbc->Table_retrieve(
        'Plate LEFT JOIN Work_Request ON Plate.FK_Work_Request__ID = Work_Request.Work_Request_ID LEFT JOIN Work_Request LWR ON LWR.FK_Library__Name = Plate.FK_Library__Name',
        [ 'coalesce(Work_Request.FK_Funding__ID,LWR.FK_Funding__ID) as FK_Funding__ID', 'Plate.FK_Library__Name as Library' ],
        "WHERE  Plate.FK_Library__Name = '$library'"
    );

    my %genome;
    foreach my $lib ( keys %funding ) {
        my $funding_id = $funding{FK_Funding__ID}[0];
        my $genome_id;
        my @library_strategy = $dbc->Table_find(
            'Plate_Attribute,Attribute,Library_Strategy,Plate', 'distinct Library_Strategy_Name',
            "WHERE Plate_Attribute.FK_Plate__ID = Plate_ID and FK_Attribute__ID = Attribute_ID and Attribute_Name = 'Library_Strategy' and Attribute_Value = Library_Strategy_ID
                    and Plate.FK_Library__Name = '$lib'"
        );
        if ( $library_strategy[0] =~ /^RNA.Seq$/ ) {
            ($genome_id) = $dbc->Table_find( 'Funding_Attribute,Attribute', 'Attribute_Value', "WHERE FK_Attribute__ID = Attribute_ID and FK_Funding__ID = $funding_id  and Attribute_Name = 'FKAnalysis_Transcriptome__ID'" );
        }
        if ( !$genome_id ) {
            ($genome_id) = $dbc->Table_find( 'Funding_Attribute,Attribute', 'Attribute_Value', "WHERE FK_Attribute__ID = Attribute_ID and FK_Funding__ID = $funding_id and Attribute_Name = 'FKAnalysis_Genome__ID'" );
        }
        if ($genome_id) {
            $genome{Library}   = $library;
            $genome{Genome_ID} = $genome_id;
        }
    }

    return \%genome;
}

sub get_funding_analysis_reference {
##########################
    my $self                      = shift;
    my %args                      = filter_input( \@_ );
    my $dbc                       = $args{-dbc} || $self->{dbc};
    my $run_analysis_id           = $args{-run_analysis_id};
    my $multiplex_run_analysis_id = $args{-multiplex_run_analysis_id};
    my $genome_id;
    my $funding_id;
    my $plate_id;

    if ($run_analysis_id) {

        ## check if it's part of the plate work request

        # get the library strategy

        my ($funding_info) = $dbc->Table_find(
            'Run_Analysis,Run,Plate LEFT JOIN Work_Request ON Plate.FK_Work_Request__ID = Work_Request_ID',
            'Work_Request.FK_Funding__ID,Plate_ID',
            "WHERE Run_Analysis.FK_Run__ID = Run_ID and Plate_ID = Run.FK_Plate__ID and Run_Analysis_Id = $run_analysis_id"
        );
        unless ($funding_info) {
            ($funding_info) = ($genome_id) = $dbc->Table_find(
                'Run_Analysis,Run,Plate LEFT JOIN Work_Request ON Work_Request.FK_Library__Name = Plate.FK_Library__Name',
                'Work_Request.FK_Funding__ID,Plate_ID',
                "WHERE Run_Analysis.FK_Run__ID = Run_ID and Plate_ID = Run.FK_Plate__ID and Run_Analysis_Id = $run_analysis_id"
            );
        }
        ( $funding_id, $plate_id ) = split ',', $funding_info;

    }
    elsif ($multiplex_run_analysis_id) {

        my ($funding_info) = $dbc->Table_find(
            'Multiplex_Run_Analysis,Sample,ReArray,Plate as SP LEFT JOIN Work_Request ON SP.FK_Work_Request__ID = Work_Request_ID',
            'Work_Request.FK_Funding__ID,SP.Plate_ID',
            "WHERE Multiplex_Run_Analysis.FK_Sample__ID = Sample_ID and ReArray.FK_Sample__ID = Sample_ID and ReArray.FKSource_Plate__ID = SP.Plate_ID and Multiplex_Run_Analysis_ID = $multiplex_run_analysis_id"
        );
        ( $funding_id, $plate_id ) = split ',', $funding_info;
        unless ($funding_id) {
            ($funding_info) = $dbc->Table_find(
                'Multiplex_Run_Analysis,Run_Analysis,Run,Plate,Sample JOIN Work_Request ON Sample.FK_Library__Name = Work_Request.FK_Library__Name',
                'Work_Request.FK_Funding__ID,Plate_ID',
                "WHERE Multiplex_Run_Analysis.FK_Sample__ID = Sample_ID and Multiplex_Run_Analysis_ID = $multiplex_run_analysis_id and Run_Analysis_ID = Multiplex_Run_Analysis.FK_Run_Analysis__ID and Run_ID = Run_Analysis.FK_Run__ID and FK_Plate__ID = Plate_ID"
            );
        }
        ( $funding_id, $plate_id ) = split ',', $funding_info;
    }
    if ($funding_id) {

        #print "Funding $funding_id\n";
        require alDente::Container;
        my $list = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_id, -list => 1, -include_self => 1, -format => 'list' );
        my @library_strategy = $dbc->Table_find(
            'Plate_Attribute,Attribute,Library_Strategy', 'distinct Library_Strategy_Name',
            "WHERE FK_Attribute__ID = Attribute_ID and Attribute_Name = 'Library_Strategy' and Attribute_Value = Library_Strategy_ID
                    and FK_Plate__ID in ($list) "
        );
        my $library_strategy = $library_strategy[0];
        if ( $library_strategy =~ /^RNA.Seq$/ ) {
            ($genome_id) = $dbc->Table_find( 'Funding_Attribute,Attribute', 'Attribute_Value', "WHERE FK_Attribute__ID = Attribute_ID and FK_Funding__ID = $funding_id  and Attribute_Name = 'FKAnalysis_Transcriptome__ID'" );
        }
        if ( !$genome_id ) {
            ($genome_id) = $dbc->Table_find( 'Funding_Attribute,Attribute', 'Attribute_Value', "WHERE FK_Attribute__ID = Attribute_ID and FK_Funding__ID = $funding_id and Attribute_Name = 'FKAnalysis_Genome__ID'" );
        }
    }

    return $genome_id;
}
######################
sub get_db_object {
######################
    my $self       = shift;
    my %args       = @_;
    my $dbc        = $args{-dbc};
    my $funding_id = $args{-id};

    my $db_obj = SDB::DB_Object->new( -dbc => $dbc );
    $db_obj->add_tables('Funding');
    $db_obj->{funding_id} = $funding_id;
    $db_obj->primary_value( -table => 'Funding', -value => $funding_id );    ## same thing as above..
    $db_obj->load_Object( -type => 'Funding' );

    return $db_obj;
}

#########
sub validate_work_request {
#########
    my $self       = shift;
    my %args       = @_;
    my $dbc        = $args{-dbc};
    my $funding_id = $args{-id};

    my @work_request = $dbc->Table_find(
        -table     => 'Work_Request',
        -fields    => "Work_Request_ID",
        -distinct  => 'Distinct',
        -condition => "WHERE FK_Funding__ID = $funding_id"
    );
    if (@work_request) {
        return 1;
    }
    else {
        return;
    }
}

###############################
# Description:
#	- This method checks if the given plates have active funding
#
# Input arguments:
#	- 'fatal':
#		Can be one of three types: 'protocol', 'run', and 'analysis'.
#		If fatal argument is passed in, it checks if the given type is invoiceable. If invoiceable but no active funding, it doesn't pass the validation check and thus returns 0. It returns 1 in all other cases.
#	- 'value':
#		If fatal type is 'protocol', lab protocol ID should be passed in as value.
#		If fatal type is 'run', run type should be passed in as value.
#		If fatal type is 'analysis', pipeline step ID should be passed in as value.
#	- 'multiple_allowed':
#		if this flag is on, multiple active fundings for a single plate is considered valid.
#		if this flag is off, multiple active fundings for a single plate is considered invalid.
# <snip>
#	Usage example:
#		my $pass = $fundingobj->validate_active_funding( -dbc => $dbc, -plates => $plates, -fatal => 'protocol', -value => $protocol_id );
#		my $pass = $fundingobj->validate_active_funding( -dbc => $dbc, -plates => $plates, -fatal => 'run', -value => $run_type );
#		my $pass = $fundingobj->validate_active_funding( -dbc => $dbc, -plates => $plates, -fatal => 'analysis', -value => $pipeline_step_id );
#
#	Return:
#		Scalar. 0 if not pass validation check; 1 if pass.
# </snip>
#################################
sub validate_active_funding {
#################################
    my $self             = shift;
    my %args             = filter_input( \@_, -args => 'plates,fatal,value,multiple_allowed', -mandatory => 'plates' );
    my $dbc              = $args{-dbc} || $self->{dbc};
    my $fatal            = $args{-fatal};                                                                                 # one of 'protocol', 'run', 'analysis'. If fatal argument is passed in, it checks if the given type is invoiceable
    my $value            = $args{-value};
    my $multiple_allowed = 1;
    if ( defined $args{-multiple_allowed} ) { $multiple_allowed = $args{-multiple_allowed} }

    my $validation_passed = 1;

    if ( $Configs{mandatory_funding} eq 'no' ) { return 1 }

    my $plate_ids = $args{-plates};

    unless ($plate_ids) { return; }

    my @plates = split ',', $plate_ids;
    for my $plate (@plates) {
        unless ($plate) {next}
        my ($funding_info) = $dbc->Table_find(
            -table     => 'Plate,Work_Request,Funding',
            -fields    => "Funding_ID,Funding_Status",
            -distinct  => 'Distinct',
            -condition => "WHERE Plate_ID = $plate and FK_Work_Request__ID = Work_Request_ID and FK_Funding__ID = Funding_ID"
        );

        if ($funding_info) {
            my ( $funding_id, $funding_status ) = split ',', $funding_info;
            if ( $funding_status ne "Received" ) {
                $validation_passed = 0;
                $dbc->{session}->warning( "Funding Source " . alDente_ref( 'Funding', $funding_id, -dbc => $dbc ) . " is $funding_status (for plate: " . alDente_ref( 'Plate', $plate, -dbc => $dbc ) . ")" ) if $dbc->{session};
            }
        }
        else {
            ## try to get funding though library
            my @info = $dbc->Table_find(
                -table     => 'Plate,Work_Request,Funding',
                -fields    => "Funding_ID,Funding_Status",
                -distinct  => 'Distinct',
                -condition => "WHERE Plate.FK_Library__Name = Work_Request.FK_Library__Name and FK_Funding__ID =Funding_ID and Plate_ID = $plate"
            );
            my $size = @info;
            if ( !$size ) {
                $validation_passed = 0;
                $dbc->{session}->warning( "Plate " . alDente_ref( 'Plate', $plate, -dbc => $dbc ) . " is not tied to a funding source" ) if $dbc->{session};
            }
            else {
                my $count = grep /,Received\b/, @info;
                if ( $count == 1 ) {
                }
                elsif ( $count > 1 ) {
                    if ( !$multiple_allowed ) {
                        $validation_passed = 0;
                        my $message;
                        foreach my $line (@info) {
                            my ( $funding_id, $funding_status ) = split ',', $line;
                            $message .= " (Funding Source " . alDente_ref( 'Funding', $funding_id, -dbc => $dbc ) . " is $funding_status) ";
                        }
                        $dbc->{session}->warning( "Ambiguous Funding Source for plate: " . alDente_ref( 'Plate', $plate, -dbc => $dbc ) . $message ) if $dbc->{session};
                    }
                }
                else {
                    $validation_passed = 0;
                    for my $line (@info) {
                        my ( $funding_id, $funding_status ) = split ',', $line;
                        $dbc->{session}->warning( "Funding Source " . alDente_ref( 'Funding', $funding_id, -dbc => $dbc ) . " is $funding_status (for plate: " . alDente_ref( 'Plate', $plate, -dbc => $dbc ) . ")" ) if $dbc->{session};
                    }
                }
            }

        }
    }
    ##### For now we return 1 , when ready it will cause an error
    #return 1;
    ###

    if ( $validation_passed == 0 && $fatal && defined $value ) {
        require alDente::Invoice;
        my $invoiceable = alDente::Invoice::is_invoiceable( -dbc => $dbc, -type => $fatal, -value => $value );
        if ( !$invoiceable ) { $validation_passed = 1 }
    }
    else {
        $validation_passed = 1;    # always return 1 otherwise
    }

    return $validation_passed;
}

##################################
# Input: arrayref of prep_ids,run_ids or plate_ids
#	Creates a hash with the form of (key)Plate_ID -> Funding_ID(value)
# Only will return funding, either from Plate level or Library level work request IFF there is 1 funding source...
# We can change this method if there is another way we can determine a funding if there were multiple
#	Output: Hash of Plate_ID and associated Funding_ID
##################################
sub determine_plate_funding {
##################################
    my %args      = &filter_input( \@_, -args => 'dbc,prep_ids|run_ids|plate_ids', -mandatory => 'dbc,prep_ids|run_ids|plate_ids' );
    my $dbc       = $args{-dbc};
    my $prep_ids  = $args{-prep_ids};
    my $run_ids   = $args{-run_ids};
    my $plate_ids = $args{-plate_ids};

    my $plate_id_string = '';
    if ($prep_ids) {
        my $prep_id_string = Cast_List( -list => $prep_ids, -to => 'String' );
        ($plate_id_string) = $dbc->Table_find( 'Plate_Prep', 'GROUP_CONCAT( DISTINCT FK_Plate__ID)', "WHERE FK_Prep__ID IN ($prep_id_string)" );
    }
    elsif ($run_ids) {
        my $run_id_string = Cast_List( -list => $run_ids, -to => 'String' );
        ($plate_id_string) = $dbc->Table_find( 'Run', 'GROUP_CONCAT( DISTINCT FK_Plate__ID)', "WHERE Run_ID IN ($run_id_string)" );
    }
    elsif ($plate_ids) {
        $plate_id_string = Cast_List( -list => $plate_ids, -to => 'String' );
    }
    else {
        Message('Mandatory inputs not found');
        return;
    }

    if ( $plate_id_string eq '' ) {
        return {};
    }

    my @plate_funding_arr = $dbc->Table_find_array(
        'Plate 
						LEFT JOIN Library ON Plate.FK_Library__Name = Library_Name 
						LEFT JOIN Work_Request WRlib ON  WRlib.FK_Library__Name = Library_Name 
						LEFT JOIN Work_Request WRpl ON Plate.FK_Work_Request__ID = WRpl.Work_Request_ID',
        [   'Plate_ID',
            'CASE WHEN COUNT(DISTINCT WRlib.FK_Funding__ID) = 1 THEN WRlib.FK_Funding__ID 
									WHEN COUNT(DISTINCT WRpl.FK_Funding__ID) = 1 THEN WRpl.FK_Funding__ID END AS Funding'
        ],
        " WHERE (WRlib.FK_Funding__ID > 0 OR WRlib.FK_Funding__ID IS NULL) 
							AND (WRpl.FK_Funding__ID > 0 OR WRpl.FK_Funding__ID IS NULL) 
							AND Plate_ID IN ($plate_id_string)
							GROUP BY Plate_ID 
							HAVING COUNT(DISTINCT WRpl.FK_Funding__ID) = 1 
							OR COUNT(DISTINCT WRlib.FK_Funding__ID) = 1 "
    );

    my %plate_funding = ();
    if ( !@plate_funding_arr ) {
        return \%plate_funding;
    }

    foreach my $plate_fund (@plate_funding_arr) {
        my ( $plate_id, $funding_id ) = split ',', $plate_fund;
        $plate_funding{$plate_id} = $funding_id;
    }

    return \%plate_funding;
}

######################################################
##          Private Functions                       ##
######################################################
###########################
sub _return_value {
##########################
    my %args         = &filter_input( \@_ );
    my $fields_ref   = $args{-fields};
    my $values_ref   = $args{ -values };
    my $target       = $args{-target};
    my $index_return = $args{-index_return};

    my $value;
    my @fields = @$fields_ref if $fields_ref;
    my @values = @$values_ref if $values_ref;
    my $counter = 0;

    foreach my $field_name (@fields) {
        if ( $field_name eq $target ) {
            if ($index_return) {
                return $counter;
            }
            else {
                return $values[$counter];
            }
        }
        $counter++;
    }
    return;
}

###########################
sub union {
##############
    #
    # return the union of two arrays as an array
    #
    my $ref    = shift;
    my @result = @{$ref};

    while ( my $nextref = shift ) {
        my @nextArray = @{$nextref};
        foreach my $element (@nextArray) {
            unless ( grep /^$element$/, @result ) { push( @result, $element ) }
        }
    }
    return \@result;
}

###########################

return 1;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

<module_name>

=head1 SYNOPSIS <UPLINK>

Usage:

=head1 DESCRIPTION <UPLINK>

<description>

=for html

=head1 KNOWN ISSUES <UPLINK>
    
None.    

=head1 FUTURE IMPROVEMENTS <UPLINK>
    
=head1 AUTHORS <UPLINK>
    
    Ran Guin, Andy Chan and J.R. Santos at the Michael Smith Genome Sciences Centre, Vancouver, BC
    

=head1 CREATED <UPLINK>
    
    <date>

=head1 REVISION <UPLINK>
    
    <version>

=cut

