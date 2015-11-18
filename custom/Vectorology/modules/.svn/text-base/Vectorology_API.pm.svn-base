################################################################################
# Vectorology_API.pm
#
# This module handles data access functions for general alDente objects
# 
# More application specific API's may also be available that inherit the alDente_API object,
# but which may access data more specific to the needs of the application.
# (eg. the Sequencing/Sequencing_API module accesses information pertaining to sequence data)
#
###############################################################################
package Vectorology_API;
##############################
# superclasses               #
##############################

@ISA = qw(alDente::alDente_API);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;
#use AutoLoader;
use Carp;
use strict;
##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::DB_Object;
use SDB::CustomSettings;
use SDB::HTML;

use RGTools::Views;
use RGTools::Conversion;
use RGTools::RGIO;

use alDente::alDente_API;
use alDente::SDB_Defaults qw($project_dir $archive_dir);
use Sequencing::Sequencing_Library;
use alDente::Library;
use alDente::Container;
use alDente::Well;
use alDente::Clone_Sample;
use alDente::Employee;

use vars qw(%Aliases);

$Aliases{Plate}{lab_book_number} = 'Lab_Book_Number';
$Aliases{Plate}{lab_book_page_number} = 'Lab_Book_Page_Number';

###############################
sub get_vectorology_data {
###############################
    my $self = shift;
    $self->log_parameters(@_);

    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    my $lab_page = $args{-page_number};
    my $lab_book = $args{-book_number};
    my $hugo     = $args{-hugo};
    my $type     = $args{-type};           ## this allows calling to specific accessors via the same method call (if blank - call EACH method)

    ### to avoid complicated left joins with all plate content types, call each type individually and collate the results ###

    my  $input_joins;
    $input_joins->{'gDNA'} = 'gDNA.FK_Plate__ID=Plate.Plate_ID';
    $input_joins->{'DNA_fragment'} = 'DNA_fragment.FK_Plate__ID=Plate.Plate_ID';
    $input_joins->{'BAC_clone'} = 'BAC_clone.FK_Plate__ID=Plate.Plate_ID';
    $input_joins->{'Plasmid_clone'} = 'Plasmid_clone.FK_Plate__ID=Plate.Plate_ID';
    $input_joins->{'Vector_only'} = 'Vector_only.FK_Plate__ID=Plate.Plate_ID';

    $input_joins->{'DNA_prep'} = 'DNA_prep.FK_Plate__ID=Plate.Plate_ID';
    $input_joins->{'Purification_gel'} = 'Purification_gel.FK_Plate__ID=Plate.Plate_ID';
    $input_joins->{'Purification_other'} = 'Purification_other.FK_Plate__ID=Plate.Plate_ID';
    $input_joins->{'Ligation'} = 'Ligation.FK_Plate__ID=Plate.Plate_ID';
    $input_joins->{'Digest'} = 'Digest.FK_Plate__ID=Plate.Plate_ID';
    $input_joins->{'gDNA'} = 'gDNA.FK_Plate__ID=Plate.Plate_ID';

    $args{-input_joins} = $input_joins;
    
    return $self->get_plate_data(%args);      ## access method in general
}

###################
sub get_old_gDNA_data {
###################
    my $self = shift;
    $self->log_parameters(@_);

    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $fields = $args{-fields};
    my $condition = $args{-condition} || 1;

    my $organism = $self->get_FK_ID('FK_Organism__ID',$args{-organism},-list=>1) if $args{-organism};   ## organism 
    my $contacts = $self->get_FK_ID('FK_Contact__ID',$args{-source}) if $args{-source};                 ## where sample originated
    my $lab_book = &extract_range($args{-lab_book}) if $args{-lab_book};                                ## lab book number 
    my $lab_book_page = &extract_range($args{-lab_book_page}) if $args{-lab_book_page};                 ## lab book page number
    my $size          = extract_range($args{-size}) if $args{-size};                                    ## avg size of sample

    ## add conditions based upon this particular scope ##
    my @extra_conditions;
    if ($organism) {
	push @extra_conditions, "Organism.Organism_ID IN ($organism)";
    }
    if ($contacts) {
	push @extra_conditions, "Contact.Contact_ID IN ($contacts)";
    }
    if ($lab_book) {
	push @extra_conditions, "gDNA.Lab_Book_Number IN ($lab_book)";
    }
    if ($lab_book_page) {
	push @extra_conditions, "gDNA.Lab_Book_Page_Number IN ($lab_book_page)";
    }
    if ($size) {
	push @extra_conditions, "gDNA.Avg_Size IN ($size)";
    }
    
    my  $input_joins;
    $input_joins->{'gDNA'}         = 'gDNA.FK_Plate__ID=Plate.Plate_ID';
    $input_joins->{'Organism'}     = 'gDNA.FK_Organism__ID=Organism.Organism_ID';
    $input_joins->{'Contact'}      = 'gDNA.FKSupplier_Contact__ID=Contact.Contact_ID';
    $input_joins->{'Organization'} = 'Contact.FK_Organization__ID=Organization.Organization_ID';
    $args{-input_joins} = $input_joins;
    $args{-fields}      = $fields || [ qw(plate_id rack plate_contents plate_created plate_made_by organism contact gDNA.Avg_Size lab_book_number lab_book_page_number) ];
    $args{-condition} = join " AND ", @extra_conditions if @extra_conditions;

    return $self->get_plate_data(%args);      ## access method in general

}
 
############################
sub get_old_BAC_clone_data {
############################
    my $self = shift;
    $self->log_parameters(@_);

    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $fields = $args{-fields};
    my $condition = $args{-condition} || 1;

    my $organism = $self->get_FK_ID('FK_Organism__ID',$args{-organism},-list=>1) if $args{-organism};   ## organism 
    my $contacts = $self->get_FK_ID('FK_Contact__ID',$args{-source}) if $args{-source};                 ## where sample originated
    my $lab_book = &extract_range($args{-lab_book}) if $args{-lab_book};                                ## lab book number 
    my $lab_book_page = &extract_range($args{-lab_book_page}) if $args{-lab_book_page};                 ## lab book page number
    my $size          = extract_range($args{-size}) if $args{-size};                                    ## avg size of sample
    my $name          = $args{-name};     ## name of this clone (according to supplier - if available) -  (may use pattern with * as wildcard)            
    my $source_library = $args{-source_library};  ## name used for library by supplier (if available) -  (may use pattern with * as wildcard)
    my $vector         = $args{-vector};             ## vector used (if available) -  (may use pattern with * as wildcard)
    my $source_plate   = &extract_range($args{-source_plate}) if $args{-source_plate};       ## plate id used by whoever supplied sample
    my $source_well    = &extract_range($args{-source_well}) if  $args{-source_well};        ## well in plate (according to whoever supplied it)
    my $hugo           = $args{-hugo};               ## hugo gene name (may use pattern with * as wildcard)
    my $source_plate   = &extract_range($args{-source_plate}) if $args{-source_plate};       ## plate id used by whoever supplied sample
    my $source_well    = &extract_range($args{-source_well}) if  $args{-source_well};        ## well in plate (according to whoever supplied it)
    my $hugo           = $args{-hugo};               ## hugo gene name (may use pattern with * as wildcard)

    ## add conditions based upon this particular scope ##
    my @extra_conditions;
    if ($organism) {
	push @extra_conditions, "Organism.Organism_ID IN ($organism)";
    }
    if ($contacts) {
	push @extra_conditions, "Contact.Contact_ID IN ($contacts)";
    }
    if ($lab_book) {
	push @extra_conditions, "BAC_clone.Lab_Book_Number IN ($lab_book)";
    }
    if ($lab_book_page) {
	push @extra_conditions, "BAC_clone.Lab_Book_Page_Number IN ($lab_book_page)";
    } 
    if ($size) {
	push @extra_conditions, "BAC_clone.Avg_Size IN ($size)";
    }
    if ($name) {
	$name =~s /\*/%/g;
	push @extra_conditions, "BAC_clone.Source_clone_name LIKE '$name'";
    }
    if ($source_library) {
	$source_library =~s /\*/%/g;
	push @extra_conditions, "Source_library.Source_library_name LIKE '$source_library'";
    }
    if ($vector) {
	$vector =~s /\*/%/g;
	push @extra_conditions, "Vector_Backbone.Vector_Backbone_Name LIKE '$vector'";
    }
    if ($source_plate) {
	push @extra_conditions, "BAC_clone.Source_Plate_ID IN ($source_plate)";
    }
    if ($source_well) {
	push @extra_conditions, "BAC_clone.Source_Plate_Well_ID IN ($source_well)";
    }
    if ($hugo) {
	$hugo =~s /\*/%/g;
	push @extra_conditions, "BAC_clone.HUGO_gene_name LIKE '$hugo'";
    }    
    
    my  $input_joins;
    $input_joins->{'BAC_clone'}         = 'BAC_clone.FK_Plate__ID=Plate.Plate_ID';
    $input_joins->{'Organism'}          = 'BAC_clone.FK_Organism__ID=Organism.Organism_ID';
    $input_joins->{'Contact'}           = 'BAC_clone.FKSupplier_Contact__ID=Contact.Contact_ID';
    $input_joins->{'Organization'}      = 'Contact.FK_Organization__ID=Organization.Organization_ID';
    $input_joins->{'Source_library'}    = 'BAC_clone.FK_Source_library__ID=Source_library.Source_library_ID';
    $input_joins->{'Vector_Backbone'}       = 'BAC_clone.FK_Vector_Backbone__ID=Vector_Backbone.Vector_Backbone_ID';

    $args{-input_joins} = $input_joins;
    $args{-fields}      = $fields || [ qw(plate_id rack plate_contents plate_created plate_made_by organism contact BAC_clone.Avg_Size lab_book_number lab_book_page_number BAC_clone_name source_library vector BAC_clone.HUGO_gene_name) ];
    $args{-condition} = join " AND ", @extra_conditions if @extra_conditions;

    return $self->get_plate_data(%args);      ## access method in general

}  

######################
sub get_gDNA_data {
########################
     my $self = shift;
     $self->log_parameters(@_);

     my %args = &filter_input(\@_); 

     $args{-content_type} = 'gDNA';
     return $self->get_Vtype_data(%args);
 }

######################
sub get_BAC_clone_data {
########################
    my $self = shift;
    $self->log_parameters(@_);

    my %args = &filter_input(\@_);
    
    $args{-content_type} = 'BAC_clone';
    return $self->get_Vtype_data(%args);
}

######################
sub get_BAC_clone_data {
########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    
    $args{-content_type} = 'BAC_clone';
    return $self->get_Vtype_data(%args);
}

########################
sub get_Vtype_data {
########################
     my $self = shift;
     $self->log_parameters(@_);

     my %args = &filter_input(\@_);
     if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
     my $fields = $args{-fields};
     my $condition = $args{-condition} || 1;
     my $content_type = $args{-content_type};            ## specific plate content type from which to extract data

     ## primary sample info ##
     my $organism = $self->get_FK_ID('FK_Organism__ID',$args{-organism},-list=>1) if $args{-organism};   ## organism 
     my $contacts = $self->get_FK_ID('FK_Contact__ID',$args{-source}) if $args{-source};                 ## where sample originated
     my $lab_book = &extract_range($args{-lab_book}) if $args{-lab_book};                                ## lab book number 
     my $lab_book_page = &extract_range($args{-lab_book_page}) if $args{-lab_book_page};                 ## lab book page number
     my $size          = extract_range($args{-size}) if $args{-size};                                    ## avg size of sample
     my $name          = $args{-name};     ## name of this clone (according to supplier - if available) -  (may use pattern with * as wildcard)            
     my $source_library = $args{-source_library};  ## name used for library by supplier (if available) -  (may use pattern with * as wildcard)
     my $vector         = $args{-vector};             ## vector used (if available) -  (may use pattern with * as wildcard)
     my $source_plate   = &extract_range($args{-source_plate}) if $args{-source_plate};       ## plate id used by whoever supplied sample
     my $source_well    = &extract_range($args{-source_well}) if  $args{-source_well};        ## well in plate (according to whoever supplied it)
     my $hugo           = $args{-hugo};               ## hugo gene name (may use pattern with * as wildcard)
     ## secondary sample info ##
     my $primer = $args{-primer};
     my $enzyme = $args{-enzyme};
     my $cell_type = $args{-cell_type};
     my $prep_method = $args{-prep_method};
     my $band_size   = $args{-band_size};
     my $purification_method = $args{-purification_method};

     ## merge all tables together with left joins... ##
     my @primary_types = qw(gDNA BAC_clone Plasmid_clone DNA_fragment Vector_only);
     my @all_content_types = qw(gDNA BAC_clone Plasmid_clone DNA_fragment Vector_only
			    PCR Digest Ligation Glycerol DNA_prep Purification_gel Purification_other);

     my @content_types = Cast_List(-list=>$content_type,-to=>'array');
     unless (@content_types) { @content_types = @all_content_types }

     ## add conditions based upon this particular scope ##
     my @extra_conditions;
     if ($organism  && $content_type =~/\b(BAC_clone|Plasmid_clone|DNA_fragment|)\b/ ) {
	 push @extra_conditions, "Organism.Organism_ID IN ($organism)";
     }
     if ($contacts && $content_type =~ /\b(gDNA|BAC_clone|Plasmid_clone|DNA_fragment|Vector_only|)\b/) {
	 push @extra_conditions, "Contact.Contact_ID IN ($contacts)";
     }
     if ($source_library && $content_type =~/\b(BAC_clone|Plasmid_clone|)\b/) {
	 $source_library =~s /\*/%/g;
	 push @extra_conditions, "Source_library.Source_library_name LIKE '$source_library'";
     }
     if ($vector  && $content_type =~/\b(BAC_clone|Plasmid_clone|)\b/) {
	 $vector =~s /\*/%/g;
	 push @extra_conditions, "Vector_Backbone.Vector_Backbone_name LIKE '$vector'";
     }
     ## content specific fields ##
     my %Add_conditions;
     foreach my $type (@content_types) {
	 if ($type =~ /(\w+)/) { $type = $1 }  ## strip quotes 
	 if ($lab_book) {
	     push @{$Add_conditions{book}}, "$type.Lab_Book_Number IN ($lab_book)";
	 }
	 if ($lab_book_page) {
	     push @{$Add_conditions{page}}, "$type.Lab_Book_Page_Number IN ($lab_book_page)";
	 }
	 if ($size) {
	     push @{$Add_conditions{size}}, "$type.Avg_Size IN ($size)" if (grep /\b$type\b/, @primary_types);
	 }
	 if ($name  && $type =~/^(BAC_clone|Plasmid_clone|)$/ ) {
	     $name =~s /\*/%/g;
	     push @{$Add_conditions{source_name}}, "$type.Source_clone_name LIKE '$name'";
	 }
	 if ($source_plate && $type =~/^(BAC_clone|Plasmid_clone|)$/) {
	     push @{$Add_conditions{source_plate}}, "$type.Source_Plate_ID IN ($source_plate)";
	 }
	 if ($source_well  && $type =~/^(BAC_clone|Plasmid_clone|)$/) {
	     push @{$Add_conditions{source_well}}, "$type.Source_Plate_Well_ID IN ($source_well)";
	 }
	 if ($hugo) {
	     $hugo =~s /\*/%/g;
	     push @{$Add_conditions{hugo}}, "$type.HUGO_gene_name LIKE '$hugo'";
	 }
     }
     foreach my $key (keys %Add_conditions) {
	 ### generate (type1.attribute=value OR type2.attribute=value) condition for each content type ### 
	 my $add_condition = join ' OR ', @{ $Add_conditions{$key}};
	 push @extra_conditions, "($add_condition)";
     }
     ## 

     my  $input_joins;
     my $left_joins;
     if (int(@content_types) == 1) {
	 $input_joins->{$content_type}  = "$content_type.FK_Plate__ID=Plate.Plate_ID";
     } 

     my @organism_joins;
     my @contact_joins;
     my @source_joins;
     my @vector_joins;
     foreach my $type (@content_types) {
	 $left_joins->{$type}  = "$type.FK_Plate__ID=Plate.Plate_ID" unless (int(@content_types) == 1);
	 push @organism_joins, "$type.FK_Organism__ID=Organism.Organism_ID" if ($type =~/(clone|DNA_frag|gDNA)/);
	 push @contact_joins, "$type.FKSupplier_Contact__ID=Contact.Contact_ID" if (grep /\b$type\b/, @primary_types);
	 if ($type =~/^(BAC_clone|Plasmid_clone)$/) {
	     push @source_joins, "$type.FK_Source_library__ID=Source_library.Source_library_ID";
	     push @vector_joins, "$type.FK_Vector_Backbone__ID=Vector_Backbone.Vector_Backbone_ID";
	 }
     }
     my $organism_join = join " OR ", @organism_joins;
     my $contact_join  = join ' OR ', @contact_joins;
     my $vector_join   = join ' OR ', @vector_joins;
     my $source_join   = join ' OR ', @source_joins;
     
     ## ensure these are set (even if only to a record indicating undefined) ##
     $input_joins->{"Organism"}     = "($organism_join)";
     $input_joins->{"Contact"}      = "($contact_join)";
     $input_joins->{"Organization"} =  "Contact.FK_Organization__ID=Organization.Organization_ID";
     $input_joins->{"Source_library"} = "($source_join)";
     $input_joins->{"Vector_Backbone"}    = "($vector_join)"; 
     
     if ($content_type =~/\b(BAC_clone|Plasmid_clone)\b/) {
	 $input_joins->{"Source_library"} = "$content_type.FK_Source_library__ID=Source_library.Source_library_ID";
	 $input_joins->{"Vector_Backbone"}    = "$content_type.FK_Vector_Backbone__ID=Vector_Backbone.Vector_Backbone_ID";
     }

     $args{-input_joins} = $input_joins;
     $args{-input_left_joins} = $left_joins;
     $args{-fields}      = $fields || [ qw(plate_id rack plate_contents plate_created plate_made_by contact lab_book_number lab_book_page_number source_library vector) ];

     $args{-condition} = join " AND ", @extra_conditions if @extra_conditions;
     
     return $self->get_plate_data(%args);      ## access method in general
}  

#############################
sub get_allVtypes_data { 
#############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);

    my @types = qw(gDNA BAC_clone Plasmid_clone DNA_fragment Vector_only
		   PCR Digest Ligation Glycerol DNA_prep Purification_gel Purification_other);

    my $data = $self->get_Vtype_data(%args);
    
    return $self->api_output(-data=>$data,-log=>1,-customized_output=>1);
}

return 1;
