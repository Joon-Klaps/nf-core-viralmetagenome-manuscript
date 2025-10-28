#! /usr/bin/env python

import rich_click as click
import pandas as pd


@click.command()
@click.option('--table', required=True, type=click.Path(exists=True), help='Path to contig table TSV file.')
@click.option('--out', required=True, type=click.Path(), help='Path to output filtered contig table TSV file.')
def main(table, out):
    """
    Filter contig table to retain only the best contig per sample and segment.

    Args:
        table (str): Path to contig table TSV file.
        out (str): Path to output filtered contig table TSV file.
    """
    # Read the contig table
    df = pd.read_csv(table, sep='\t')

    # check difference '(annotation) qlen' towards theoretical length '(annotation) segment' = 'L' to 7.2 Kb for 'S' to 3.4 Kb
    # arrange based on distance to theoretical length, number of reads mapped to contig '(samtools Raw) reads mapped (R1+R2)'

    df['distance_to_theoretical'] = df.apply(lambda row: abs(row['(annotation) qlen'] - (7200 if row['(annotation) segment'] == 'L' else 3400)), axis=1)
    df['reads_mapped'] = df['(samtools Raw) reads mapped (R1+R2)']

    # group by sample,'(annotation) segment', reference_distance,
    # and select the contig with the minimum distance to theoretical length, but reads most reads mapped
    df = df.sort_values(by=['distance_to_theoretical', 'reads_mapped'], ascending=[True, False])
    df = df.drop_duplicates(subset=['sample', '(annotation) segment', 'reference_distance'], keep='first')

    # Subset the number of columns to make manegeable in nextflow
    columns = ['index', 'sample', '(annotation) segment','(checkv) completeness', '(cluster) centroid', 'reference_distance']
    df_filtered = df[columns]
    df_filtered.to_csv(out, sep='\t', index=False)