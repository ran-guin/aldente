#!/bin/sh

#$ -S /bin/sh
#$ -cwd
#$ -m e
#$ -M jsantos@bcgsc.ca
#$ -N LIMSphred
#$ -P Project


# takes one argument: the argument string to update_sequence
export LD_ASSUME_KERNEL=2.4.1 && export PHRED_PARAMETER_FILE='/home/sequence/alDente/WebVersions/Production/conf/phredpar.dat' && /home/sequence/alDente/WebVersions/Production/bin/update_sequence.pl $1