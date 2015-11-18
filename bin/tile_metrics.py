#!/usr/local/bin/python2

import illuminate
import pandas
import os
import sys
import optparse


code_legend = '''
Tile metric codes
[Taken from illuminate module documentation]

code 100: cluster density (k/mm2)
code 101: cluster density passing filters (k/mm2)
code 102: number of clusters
code 103: number of clusters passing filters
code (200 + (N - 1) * 2): phasing for read N
code (201 + (N - 1) * 2): prephasing for read N
code (300 + N - 1): percent aligned for read N
code 400: control lane
'''


### Needed so that the help output from optparse doesn't strip the newlines
### from the code legend

optparse.OptionParser.format_epilog = lambda self, formatter: self.epilog

parser = optparse.OptionParser(usage="Usage: %prog [options] flowcell_dir", epilog=code_legend)
parser.add_option("-o", "--output_dir", help="Outputs tile metrics to CSV file in OUTPUT_DIR")
(options, args) = parser.parse_args()

flowcell_dir = args[0]
output_dir   = options.output_dir


myDataset     = illuminate.InteropDataset(flowcell_dir)

### "True" argument not strictly necessary, but I want to make sure
### the metrics are re-read from the .bin files every time, not cached

tile_metrics  = myDataset.TileMetrics(True)

df = pandas.DataFrame(tile_metrics.data)

### Convert the actual phasing values to percents, in order to match SAV output

phasing_percent = df[(df['code'] >= 200) & (df['code'] < 300)]['value'] * 100
df.loc[(df['code'] >= 200) & (df['code'] < 300),'value'] = phasing_percent


### According to Illumina, it is possible that values in
### TileMetricsOut.bin can be repeated for a given code and tile.
###
### If there are duplicates, then the last value reported should be
### considered the correct one

no_dups_df = df.drop_duplicates(subset=['tile','lane','code'], take_last=True)

### Filter off only the phasing/prephasing codes (format: 2xx)

phasing_df = no_dups_df[(no_dups_df['code'] >= 200) & (no_dups_df['code'] < 300)]


### According to Illumina, when reporting a lane-aggregrated value of tile metrics
### you should aggregrate using the mean


mean_per_lane = phasing_df.pivot_table(values='value', index=['lane','code'], aggfunc='mean')


if output_dir:
	flowcell_name = myDataset.meta.rta_run_info['flowcell'];
	output_file   = '.'.join(['tile_metrics', flowcell_name, 'csv'])
	output_path   = os.path.join(output_dir, output_file)
else:
	output_path = sys.stdout

mean_per_lane.to_csv(output_path, header=True)
