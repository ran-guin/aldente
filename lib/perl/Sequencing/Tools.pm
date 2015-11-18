################################################################################
## Tools.pm
#
# This module provides tools that enable more powerful usage of functions available in Sequencing
#
################################################################################
package Sequencing::Tools;
##############################
# superclasses               #
##############################
@ISA = qw(Exporter);
##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
             SQL_phred
             );
use strict;

#Moved from alDente::Sequencing, currently used by Lib_Construction/GE_View.pm- alDente/Run_Info.pm* alDente/alDente_API.pm alDente/Sequence.pm-- Vectorology/Vectorology_API.pm- Sequencing/Sequencing_API.pm Sequencing/Views.pm Sequencing/Post.pm Sequencing/Lab_View.pm- Sequencing/Read.pm Sequencing/Seq_Data.pm*
#'-' means that it probably not using the function in the file and removed with this move
#'--' means just a comment
#####################
sub SQL_phred {
#####################
#
# return SQL command for Phred score..
#
    my $threshold = shift;

    my $LSB = $threshold*2 +1;
    my $MSB = $threshold*2 +2;

    my $command = "256*ascii(Left(Substring(Clone_Sequence.Phred_Histogram,$MSB),1)) + ascii(Left(Substring(Clone_Sequence.Phred_Histogram,$LSB),1))";
    return $command;
}


return 1;
