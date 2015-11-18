#!/bin/sh

#$ -S /bin/sh
#$ -cwd
#$ -m e
#$ -M aldente@bcgsc.ca
#$ -N seqbackDB
#$ -P Project

export LD_ASSUME_KERNEL=2.4.1 && /home/sequence/alDente/WebVersions/Production/bin/backup_DB.pl -D sequence -u viewer -p viewer -X Clone_Sequence -m '/usr/bin/' > /home/sequence/alDente/logs/sequence.small_backup.log
