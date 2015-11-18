#!/gsc/software/linux-x86_64-centos6/python-2.7.8/bin/python


import string
import sets
import argparse
import re


parser = argparse.ArgumentParser(description='Search for runs in SRA')
parser.add_argument('-c','--center',      type=str, nargs='*', help='Valid NCBI center name abbreviations')
parser.add_argument('-s', '--submission', type=str, nargs='*', help='Submission volume accession OR submission alias')
parser.add_argument('--study',            type=str, nargs='*', help='Study accession OR study alias')
parser.add_argument('--sample',           type=str, nargs='*', help='Sample accession OR sample alias')
parser.add_argument('-e','--experiment',  type=str, nargs='*', help='Experiment accession OR experiment alias')
parser.add_argument('-r','--run',         type=str, nargs='*', help='Run accession OR run alias')
parser.add_argument('--status',           type=str, nargs='*', help='NCBI status [live, suppressed]')
parser.add_argument('--regex', action='store_true', help='Interpret alias input as regular expression')

args = vars(parser.parse_args())


center     = args['center']     or ['BCCAGSC']
status     = args['status']     or ['live']
submission = args['submission'] or []
study      = args['study']      or []
sample     = args['sample']     or []
experiment = args['experiment'] or []
run        = args['run']        or []
regex      = args['regex']


if regex:
    submission_regex = map(lambda x: re.compile(x), submission)
    study_regex      = map(lambda x: re.compile(x), study)
    sample_regex     = map(lambda x: re.compile(x), sample)
    experiment_regex = map(lambda x: re.compile(x), experiment)
    run_regex        = map(lambda x: re.compile(x), run)

accession_file = '/home/aldente/public/NCBI/SRA_Accessions.tab'

input_submission_attributes = {}
input_study_attributes      = {}
input_sample_attributes     = {}
input_experiment_attributes = {}
input_run_attributes        = {}



### I do multiple passes instead of slurping the whole file, since the accession file
### is nearly 1 GB. Slurping the whole file into a giant dict takes up to 5 GB of RAM with
### all the included overhead. As well, the execution times is not significantly longer 
### than keeping the file in memory.


### The first pass over the file is to convert all the aliases that might be
### given as input into accessions


with open(accession_file, 'r') as f:
    header       = f.readline()
    column_names = header.rstrip().split()

    for line in f:
        cols = line.rstrip().split()

        if cols[6] == 'RUN':
            if regex:
                input_match = any(regex.match(cols[9]) for regex in run_regex)
            else:
                input_match = cols[0] in run or cols[9] in run

            if input_match:
                input_run_attributes[cols[0]] = dict(zip(column_names, cols))

        elif cols[6] == 'EXPERIMENT':
            if regex:
                input_match = any(regex.match(cols[9]) for regex in experiment_regex)
            else:
                input_match = cols[0] in experiment or cols[9] in experiment

            if input_match:
                input_experiment_attributes[cols[0]] = dict(zip(column_names, cols))

        elif cols[6] == 'SAMPLE':
            if regex:
                input_match = any(regex.match(cols[9]) for regex in sample_regex)
            else:
                input_match = cols[0] in sample or cols[9] in sample

            if input_match:
                input_sample_attributes[cols[0]] = dict(zip(column_names, cols))

        elif cols[6] == 'STUDY':
            if regex:
                input_match = any(regex.match(cols[9]) for regex in study_regex)
            else:
                input_match = cols[0] in run or cols[9] in run

            if input_match:
                input_study_attributes[cols[0]] = dict(zip(column_names, cols))

        elif cols[6] == 'SUBMISSION':
            if regex:
                input_match = any(regex.match(cols[9]) for regex in submission_regex)
            else:
                input_match = cols[0] in submission or cols[9] in submission

            if input_match:
                input_submission_attributes[cols[0]] = dict(zip(column_names, cols))



### The second pass is to retrieve all the run entries that
### match the input criteria


matched_run_attributes = {}
matched_experiments    = sets.Set()
matched_samples        = sets.Set()
matched_studies        = sets.Set()
matched_submissions    = sets.Set()

with open(accession_file, 'r') as f:
    header       = f.readline()
    column_names = header.rstrip().split()

    for line in f:
    	cols = line.rstrip().split()

        if (cols[6] == 'RUN'):
            match = True

            if (center):
                match = match and (cols[7] in center)
            if (len(submission) > 0):
                match = match and (cols[1] in input_submission_attributes)
            if (len(study) > 0):
                match = match and (cols[12] in input_study_attributes)
            if (len(sample) > 0):
                match = match and (cols[11] in input_sample_attributes)
            if (len(experiment) > 0):
                match = match and (cols[10] in input_experiment_attributes)
            if (len(run) > 0):
                match = match and (cols[0] in input_run_attributes)
            if (status):
                match = match and (cols[2] in status)

            if match:
                matched_run_attributes[cols[0]] = dict(zip(column_names, cols))
                matched_experiments.add(cols[10])
                matched_samples.add(cols[11])
                matched_studies.add(cols[12])
                matched_submissions.add(cols[1])

### The third pass retrieves all the related experiment/sample/study metadata
### of the runs that passed the matching criteria.

matched_experiment_attributes = {}
matched_sample_attributes     = {}
matched_study_attributes      = {}
matched_submission_attributes = {}

with open(accession_file, 'r') as f:
    header       = f.readline()
    column_names = header.rstrip().split()

    for line in f:
    	cols = line.rstrip().split()


    	if cols[6] == 'EXPERIMENT' and cols[0] in matched_experiments:
    		matched_experiment_attributes[cols[0]] = dict(zip(column_names, cols))

    	elif cols[6] == 'SAMPLE' and cols[0] in matched_samples:
    		matched_sample_attributes[cols[0]]     = dict(zip(column_names, cols))

    	elif cols[6] == 'STUDY' and cols[0] in matched_studies:
    		matched_study_attributes[cols[0]]      = dict(zip(column_names, cols))

        elif cols[6] == 'SUBMISSION' and cols[0] in matched_submissions:
            matched_submission_attributes[cols[0]]      = dict(zip(column_names, cols))


for run, run_attrs in matched_run_attributes.iteritems():

    experiment_attrs = matched_experiment_attributes.get(run_attrs['Experiment'], {})
    sample_attrs     = matched_sample_attributes.get(run_attrs['Sample'], {})
    study_attrs      = matched_study_attributes.get(run_attrs['Study'], {})
    submission_attrs = matched_submission_attributes.get(run_attrs['Submission'], {})


    experiment_alias = experiment_attrs.get('Alias', '-')
    sample_alias     = sample_attrs.get('Alias', '-')
    study_alias      = study_attrs.get('Alias', '-')
    submission_alias = submission_attrs.get('Alias','-')


    experiment_acc = run_attrs['Experiment']
    sample_acc     = run_attrs['Sample']
    study_acc      = run_attrs['Study']
    submission_acc = run_attrs['Submission']

    print '\t'.join([run,run_attrs['Alias'],experiment_acc,experiment_alias,sample_acc,sample_alias,study_acc,study_alias,submission_acc,submission_alias])