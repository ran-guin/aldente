#!/usr/bin/perl
## ./template/unit_test_template.txt ##
#####################################
#
# Standard Template for unit testing
#
#####################################

### Template 4.1 ###

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use Test::Differences;
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use alDente::Data_Submission_Config;
############################

############################################


use_ok("alDente::Data_Submission_Config");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_config');
    {
        ## <insert tests for create_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_sample_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_sample_config');
    {
        ## <insert tests for create_sample_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_sample_cell_line_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_sample_cell_line_config');
    {
        ## <insert tests for create_sample_cell_line_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_sample_primary_cell_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_sample_primary_cell_config');
    {
        ## <insert tests for create_sample_primary_cell_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_sample_primary_cell_culture_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_sample_primary_cell_culture_config');
    {
        ## <insert tests for create_sample_primary_cell_culture_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_sample_primary_tissue_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_sample_primary_tissue_config');
    {
        ## <insert tests for create_sample_primary_tissue_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_experiment_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_experiment_config');
    {
        ## <insert tests for create_experiment_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_experiment_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_experiment_config');
    {
        ## <insert tests for create_experiment_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_experiment_lib_layout_single_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_experiment_lib_layout_single_config');
    {
        ## <insert tests for create_experiment_lib_layout_single_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_experiment_lib_layout_paired_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_experiment_lib_layout_paired_config');
    {
        ## <insert tests for create_experiment_lib_layout_paired_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_experiment_platform_illumina_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_experiment_platform_illumina_config');
    {
        ## <insert tests for create_experiment_platform_illumina_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_run_platform_illumina_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_run_platform_illumina_config');
    {
        ## <insert tests for create_run_platform_illumina_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_experiment_platform_ls454_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_experiment_platform_ls454_config');
    {
        ## <insert tests for create_experiment_platform_ls454_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_run_platform_ls454_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_run_platform_ls454_config');
    {
        ## <insert tests for create_run_platform_ls454_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_experiment_platform_solid_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_experiment_platform_solid_config');
    {
        ## <insert tests for create_experiment_platform_solid_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_run_platform_solid_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_run_platform_solid_config');
    {
        ## <insert tests for create_run_platform_solid_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_experiment_spot_decode_spec_single_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_experiment_spot_decode_spec_single_config');
    {
        ## <insert tests for create_experiment_spot_decode_spec_single_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_run_spot_decode_spec_single_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_run_spot_decode_spec_single_config');
    {
        ## <insert tests for create_run_spot_decode_spec_single_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_experiment_spot_decode_spec_paired_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_experiment_spot_decode_spec_paired_config');
    {
        ## <insert tests for create_experiment_spot_decode_spec_paired_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_run_spot_decode_spec_paired_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_run_spot_decode_spec_paired_config');
    {
        ## <insert tests for create_run_spot_decode_spec_paired_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_study_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_study_config');
    {
        ## <insert tests for create_study_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_run_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_run_config');
    {
        ## <insert tests for create_run_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_fastq_run_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_fastq_run_config');
    {
        ## <insert tests for create_fastq_run_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_NCBI_TCGA_analysis_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_NCBI_TCGA_analysis_config');
    {
        ## <insert tests for set_NCBI_TCGA_analysis_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_common_analysis_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_common_analysis_config');
    {
        ## <insert tests for set_common_analysis_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_analysis_ref_alignment_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_analysis_ref_alignment_config');
    {
        ## <insert tests for set_analysis_ref_alignment_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_NCBI_EZH2_analysis_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_NCBI_EZH2_analysis_config');
    {
        ## <insert tests for set_NCBI_EZH2_analysis_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_analysis_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_analysis_config');
    {
        ## <insert tests for create_analysis_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_analysis_analysis_type_assembly_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_analysis_analysis_type_assembly_config');
    {
        ## <insert tests for create_analysis_analysis_type_assembly_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_analysis_analysis_type_refAlignment_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_analysis_analysis_type_refAlignment_config');
    {
        ## <insert tests for create_analysis_analysis_type_refAlignment_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_analysis_analysis_type_seqAnnotation_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_analysis_analysis_type_seqAnnotation_config');
    {
        ## <insert tests for create_analysis_analysis_type_seqAnnotation_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_analysis_analysis_type_abdMeasurement_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_analysis_analysis_type_abdMeasurement_config');
    {
        ## <insert tests for create_analysis_analysis_type_abdMeasurement_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_analysis_analysis_type_report_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_analysis_analysis_type_report_config');
    {
        ## <insert tests for create_analysis_analysis_type_report_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_submission_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_submission_config');
    {
        ## <insert tests for create_submission_config method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_submission_run_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'create_submission_run_config');
    {
        ## <insert tests for create_submission_run_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_MeDIP_seq_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_MeDIP_seq_config');
    {
        ## <insert tests for set_MeDIP_seq_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_MRE_seq_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_MRE_seq_config');
    {
        ## <insert tests for set_MRE_seq_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_ChIP_seq_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_ChIP_seq_config');
    {
        ## <insert tests for set_ChIP_seq_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_ChIP_seq_input_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_ChIP_seq_input_config');
    {
        ## <insert tests for set_ChIP_seq_input_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_Bisulfite_seq_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_Bisulfite_seq_config');
    {
        ## <insert tests for set_Bisulfite_seq_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_mRNA_seq_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_mRNA_seq_config');
    {
        ## <insert tests for set_mRNA_seq_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_smRNA_seq_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_smRNA_seq_config');
    {
        ## <insert tests for set_smRNA_seq_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_RNA_seq_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_RNA_seq_config');
    {
        ## <insert tests for set_RNA_seq_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_WTSS_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_WTSS_config');
    {
        ## <insert tests for set_WTSS_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_common_edacc_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_common_edacc_config');
    {
        ## <insert tests for set_common_edacc_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_common_experiment_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_common_experiment_config');
    {
        ## <insert tests for set_common_experiment_config method here> ##
    }
}

if ( !$method || $method =~ /\bmerge_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'merge_config');
    {
        ## <insert tests for merge_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_NCBI_RNAseq_TCGA_exp_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_NCBI_RNAseq_TCGA_exp_config');
    {
        ## <insert tests for set_NCBI_RNAseq_TCGA_exp_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_NCBI_RNAseq_NBL_exp_config\b/ ) {
    can_ok("alDente::Data_Submission_Config", 'set_NCBI_RNAseq_NBL_exp_config');
    {
        ## <insert tests for set_NCBI_RNAseq_NBL_exp_config method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Data_Submission_Config test');

exit;
