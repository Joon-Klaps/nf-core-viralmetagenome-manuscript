#! /usr/bin/env python3

import glob
import os
from typing import List, Optional, Dict, Set
import pandas as pd
import rich_click as click
import re
from dataclasses import dataclass

GLOBS_OF_INTEREST = {
    "consensus_seqs": "*/consensus/seq/it2/*/*.fasta",
    "cdhit_results": "*/assembly/polishing/cdhitest/*/clusters/*.fa.clstr",
    "centroid_sequences": "*/assembly/polishing/cdhitest/*/references/*.fa",
    "contigs_summary": "*/overview-tables/contigs_overview.tsv",
}

# Regex-based path filters (use normalized paths with forward slashes)
PATH_REGEX = {
    "consensus_seqs": re.compile(r"/consensus/seq/it2/[^/]+/[^/]+\.fasta$"),
    "cdhit_results": re.compile(r"/assembly/polishing/cdhitest/[^/]+/clusters/[^/]+\.fa\.clstr$"),
    "centroid_sequences": re.compile(r"/assembly/polishing/cdhitest/[^/]+/references/[^/]+\.fa$"),
    "contigs_summary": re.compile(r"/overview-tables/contigs_overview\.tsv$"),
}

@dataclass
class Cluster:
    cluster_id: str
    centroid: Optional[str]
    members: list[str]

def combine_tables(files: dict[str, str], output_file: str) -> None:
    """Combine multiple TSV files into a single TSV file."""
    combined_df = pd.DataFrame()
    for reference_dist, file in files.items():
        df = pd.read_csv(file, sep="\t")
        df["reference_distance"] = reference_dist
        combined_df = pd.concat([combined_df, df], ignore_index=True)
    combined_df.to_csv(output_file, sep="\t", index=False)


def combine_fasta(files: dict[str, List[str]], output_file: str) -> None:
    """Combine multiple FASTA files into a single FASTA file."""
    with open(output_file, "w", encoding="utf-8") as outfile:
        for reference_dist, file_list in files.items():
            for file in file_list:
                with open(file, "r", encoding="utf-8") as infile:
                    for line in infile:
                        if line.startswith(">"):
                            outfile.write(f">{reference_dist}_{line[1:]}")
                        else:
                            outfile.write(line)

def parse_cdhit_cluster(clstr_file: str) -> pd.DataFrame:
    """Parse a CD-HIT cluster file and return a DataFrame with relevant information."""
    clusters = []

    current_cluster_id = None
    current_members = []
    current_centroid = None

    with open(clstr_file, "r", encoding="utf-8") as f:
        lines = f.readlines()
        for line in lines:
            if line.startswith(">Cluster"):
                # New cluster detected, add previous Cluster object to the list
                if current_cluster_id is not None:
                    cluster = Cluster(current_cluster_id, current_centroid, current_members)
                    clusters.append(cluster)

                # Extract the cluster cluster_id from the line and reset the members and centroid
                current_cluster_id = f"cl{line.strip().split()[1]}"
                current_members = []
                current_centroid = None
            else:
                # Extract the sequence name between '>' and '...'
                m = re.search(r">([A-z0-9\-\_\.]+)\.\.\.", line)
                if not m:
                    continue
                member_name = m.group(1)

                # Check if the line indicates the centroid member (ends with '*')
                if line.strip().endswith("*"):
                    current_centroid = member_name
                else:
                    # Add the member to the list of members
                    current_members.append(member_name)

    # Create a Cluster object for the last cluster
    if current_cluster_id is not None:
        cluster = Cluster(current_cluster_id, current_centroid, current_members)
        clusters.append(cluster)

    # Convert dataclass list to DataFrame explicitly
    return pd.DataFrame([vars(c) for c in clusters])


def extract_reference_distance(path: str) -> str | None:
    """Extract LVExxxxx-#### or LVExxxxx-RVDB token from a path."""
    m = re.search(r"(LVE\d{5}-(?:\d{4,5}|RVDB))", path)
    return m.group(1) if m else None


def group_files_by_reference(input_dir: str, pattern: str) -> dict[str, List[str]]:
    """Return mapping: reference_distance -> list of files matching the pattern."""
    files: dict[str, List[str]] = {}
    for fp in glob.glob(os.path.join(input_dir, pattern)):
        ref = extract_reference_distance(fp)
        if not ref:
            continue
        files.setdefault(ref, []).append(fp)
    return files


def group_single_file_by_reference(input_dir: str, pattern: str) -> dict[str, str]:
    """Return mapping: reference_distance -> single file path (first per ref)."""
    grouped = group_files_by_reference(input_dir, pattern)
    single: dict[str, str] = {}
    for ref, fps in grouped.items():
        # Take the first file deterministically (sorted) if multiple
        fps_sorted = sorted(fps)
        single[ref] = fps_sorted[0]
    return single


def list_all_files(input_dir: str, exclude_dir_names: List[str] | None = None) -> List[str]:
    """List all files under input_dir, pruning excluded directory names (e.g., 'archive')."""
    if exclude_dir_names is None:
        exclude_dir_names = ["archive"]
    out: List[str] = []
    for root, dirs, files in os.walk(input_dir):
        # prune excluded dirs
        dirs[:] = [d for d in dirs if d not in exclude_dir_names]
        for name in files:
            out.append(os.path.join(root, name))
    return out


def group_files_by_reference_regex(input_dir: str, include_regex: re.Pattern[str]) -> dict[str, List[str]]:
    """Map reference_distance -> list of files whose normalized path matches include_regex.

    Additional guard: ignore any path that contains '/archive/'.
    """
    mapping: Dict[str, List[str]] = {}
    for fp in list_all_files(input_dir):
        norm = fp.replace(os.sep, "/")
        if "/archive/" in norm:
            continue
        if not include_regex.search(norm):
            continue
        ref = extract_reference_distance(norm)
        if not ref:
            continue
        mapping.setdefault(ref, []).append(fp)
    return mapping


def group_single_file_by_reference_regex(input_dir: str, include_regex: re.Pattern[str]) -> dict[str, str]:
    grouped = group_files_by_reference_regex(input_dir, include_regex)
    single: Dict[str, str] = {}
    for ref, fps in grouped.items():
        single[ref] = sorted(fps)[0]
    return single


def report_missing_ids(
    label: str,
    allowed_ids: Optional[Set[str]],
    discovered_keys: Set[str],
    final_keys: Set[str],
) -> None:
    """Emit debug information about missing or excluded IDs."""
    if allowed_ids is None:
        excluded = sorted(discovered_keys - final_keys)
        if excluded:
            click.echo(f"[debug] {label}: excluded IDs: {', '.join(excluded)}")
        else:
            click.echo(f"[debug] {label}: no IDs were excluded.")
        return

    missing_allowed = sorted(allowed_ids - discovered_keys)
    excluded_present = sorted(discovered_keys - final_keys)

    if missing_allowed:
        click.echo(
            f"[debug] {label}: allowed IDs with no matching files: {', '.join(missing_allowed)}"
        )
    if excluded_present:
        click.echo(
            f"[debug] {label}: excluded IDs (files present but not in allow-list): {', '.join(excluded_present)}"
        )
    if not missing_allowed and not excluded_present:
        click.echo(f"[debug] {label}: all allowed IDs included.")


def combine_clusters(files: dict[str, List[str]], output_file: str, base_dir: str) -> None:
    """Combine multiple CD-HIT cluster files into a single TSV summary.

    Columns:
    - reference_distance
    - cluster_id
    - centroid
    - member_count
    - members (semicolon-separated)
    - source_file (origin .clstr file)
    """
    combined = []
    for reference_dist, file_list in files.items():
        for clstr in file_list:
            df = parse_cdhit_cluster(clstr)
            if df.empty:
                continue
            df = df.copy()
            df["reference_distance"] = reference_dist
            df["member_count"] = df["members"].apply(lambda x: len(x) if isinstance(x, list) else 0)
            df["members"] = df["members"].apply(lambda x: ";".join(x) if isinstance(x, list) else "")
            df["centroid"] = df["centroid"].fillna("")
            df["source_file"] = os.path.relpath(clstr, start=base_dir)
            combined.append(df)

    if combined:
        out = pd.concat(combined, ignore_index=True)
    else:
        out = pd.DataFrame(columns=[
            "reference_distance", "cluster_id", "centroid", "member_count", "members", "source_file"
        ])
    out.to_csv(output_file, sep="\t", index=False)


@click.command()
@click.argument("input_dir", type=click.Path(exists=True), default=".")
@click.argument("ref_pool_csv", type=click.Path(exists=True), default="../reference_pools.csv")
@click.option(
    "--debug",
    "debug",
    is_flag=True,
    default=False,
    help="Print IDs that were excluded or missing from combined outputs.",
)
def main(
    input_dir: str = ".",
    ref_pool_csv: str = "../reference_pools.csv",
    debug: bool = False,
) -> None:
    """Combine outputs across pools under INPUT_DIR.

    INPUT_DIR: base directory containing per-pool outputs.
    REF_POOL_CSV: CSV mapping IDs to samples/sequences (used to filter IDs).
    """
    input_dir = os.path.abspath(input_dir)

    # Load allowed IDs (e.g., LVE00050-9092, LVE00050-RVDB) from CSV to filter results
    try:
        ref_df = pd.read_csv(ref_pool_csv)
        allowed_ids = set(ref_df["id"].astype(str).unique())
        click.echo(f"Filtering to {len(allowed_ids)} allowed reference pool IDs from {ref_pool_csv}")
        if debug:
            click.echo(f"[debug] Allowed IDs: {', '.join(sorted(allowed_ids))}")
    except (FileNotFoundError, pd.errors.EmptyDataError, KeyError) as e:
        click.echo(f"Warning: failed to read {ref_pool_csv}: {e}. Proceeding without filtering.")
        allowed_ids = None

    out_dir = os.path.join(input_dir, "combined")
    os.makedirs(out_dir, exist_ok=True)

    # 1) Combine consensus FASTA sequences
    cons_map = group_files_by_reference_regex(input_dir, PATH_REGEX["consensus_seqs"])
    cons_discovered = set(cons_map.keys())
    if allowed_ids is not None:
        cons_map = {k: v for k, v in cons_map.items() if k in allowed_ids}
    if debug:
        report_missing_ids(
            "consensus FASTA",
            allowed_ids,
            cons_discovered,
            set(cons_map.keys()),
        )
    if cons_map:
        combine_fasta(cons_map, os.path.join(out_dir, "all_consensus.fasta"))
        click.echo(f"Wrote combined consensus FASTA for {len(cons_map)} pools")
    else:
        click.echo("No consensus FASTA files found to combine.")

    # 2) Combine contigs overview tables
    contig_map = group_single_file_by_reference_regex(input_dir, PATH_REGEX["contigs_summary"])
    contig_discovered = set(contig_map.keys())
    if allowed_ids is not None:
        contig_map = {k: v for k, v in contig_map.items() if k in allowed_ids}
    if debug:
        report_missing_ids(
            "contigs overview",
            allowed_ids,
            contig_discovered,
            set(contig_map.keys()),
        )
    if contig_map:
        combine_tables(contig_map, os.path.join(out_dir, "contigs_overview.tsv"))
        click.echo(f"Wrote combined contigs overview for {len(contig_map)} pools")
    else:
        click.echo("No contigs overview tables found to combine.")

    # 3) Combine CD-HIT cluster summaries
    clstr_map = group_files_by_reference_regex(input_dir, PATH_REGEX["cdhit_results"])
    clstr_discovered = set(clstr_map.keys())
    if allowed_ids is not None:
        clstr_map = {k: v for k, v in clstr_map.items() if k in allowed_ids}
    if debug:
        report_missing_ids(
            "CD-HIT clusters",
            allowed_ids,
            clstr_discovered,
            set(clstr_map.keys()),
        )
    if clstr_map:
        combine_clusters(clstr_map, os.path.join(out_dir, "cdhit_clusters.tsv"), base_dir=input_dir)
        click.echo(f"Wrote combined CD-HIT clusters for {len(clstr_map)} pools")
    else:
        click.echo("No CD-HIT cluster files found to combine.")

    # 4) Combine centroid sequences from CD-HIT
    centroid_map = group_files_by_reference_regex(input_dir, PATH_REGEX["centroid_sequences"])
    centroid_discovered = set(centroid_map.keys())
    if allowed_ids is not None:
        centroid_map = {k: v for k, v in centroid_map.items() if k in allowed_ids}
    if debug:
        report_missing_ids(
            "CD-HIT centroids",
            allowed_ids,
            centroid_discovered,
            set(centroid_map.keys()),
        )
    if centroid_map:
        combine_fasta(centroid_map, os.path.join(out_dir, "cdhit_centroids.fasta"))
        click.echo(f"Wrote combined CD-HIT centroids for {len(centroid_map)} pools")
    else:
        click.echo("No CD-HIT centroid files found to combine.")


if __name__ == "__main__":
    main()  # type: ignore[call-arg]


