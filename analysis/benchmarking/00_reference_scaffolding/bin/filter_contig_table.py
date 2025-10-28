#!/Users/joonklaps/opt/anaconda3/envs/nf-core/bin/python3

import argparse
import pandas as pd

def main(table: str, out: str) -> None:
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


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Filter contig table to retain only the best contig per sample and segment.")
    parser.add_argument('--table', required=True, help='Path to contig table TSV file.')
    parser.add_argument('--out', required=True, help='Path to output filtered contig table TSV file.')
    args = parser.parse_args()
    main(args.table, args.out)