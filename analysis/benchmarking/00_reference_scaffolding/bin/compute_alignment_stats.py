#!/usr/bin/env python3

"""
Compute basic alignment statistics for a two-sequence alignment FASTA.

Input
-----
- --aln: Path to an alignment FASTA file (optionally gzipped). Must contain exactly 2 sequences
		 of equal aligned length (typical output from MAFFT with two inputs).

Output
------
- TSV with one header row and one data row containing:
  seq1_id, seq2_id, alignment_length, comparable_sites, matches, mismatches,
  mismatch_rate, seq1_gaps, seq2_gaps, seq1_Ns, seq2_Ns

Notes
-----
- Comparable sites are positions where both characters are A/C/G/T (case-insensitive).
- mismatch_rate is mismatches / comparable_sites; when comparable_sites == 0, prints NA.
"""

from __future__ import annotations

import argparse
import gzip
import sys
from pathlib import Path
from typing import List, Tuple


def read_fasta_two_sequences(path: Path) -> List[Tuple[str, str]]:
    """Minimal FASTA reader that returns [(id, seq), ...]. Supports .gz files.

    Expects exactly two records. Sequences are returned as uppercase strings.
    """

    opener = gzip.open if path.suffix == ".gz" else open
    records: List[Tuple[str, str]] = []
    header: str | None = None
    chunks: List[str] = []
    try:
        with opener(path, "rt", encoding="utf-8") as handle:
            for line in handle:
                if not line:
                    continue
                if line.startswith(">"):
                    # flush previous
                    if header is not None:
                        records.append((header, "".join(chunks).upper()))
                    header = line[1:].strip().split()[0]
                    chunks = []
                else:
                    chunks.append(line.strip())
            # flush last
            if header is not None:
                records.append((header, "".join(chunks).upper()))
    except FileNotFoundError as exc:
        raise SystemExit(f"Alignment file not found: {path}") from exc

    if len(records) != 2:
        raise SystemExit(
            f"Alignment must contain exactly 2 sequences, found {len(records)} in: {path}"
        )
    if len(records[0][1]) != len(records[1][1]):
        raise SystemExit("Aligned sequences have different lengths; is this an alignment?")

    return records


def compute_stats(seq1: str, seq2: str) -> dict:
    valid = {"A", "C", "G", "T"}

    aln_len = len(seq1)
    comparable = 0
    matches = 0
    mismatches = 0

    for a, b in zip(seq1, seq2):
        if a in valid and b in valid:
            comparable += 1
            if a == b:
                matches += 1
            else:
                mismatches += 1

    mismatch_rate = (mismatches / comparable) if comparable else None

    return {
        "alignment_length": aln_len,
        "comparable_sites": comparable,
        "matches": matches,
        "mismatches": mismatches,
        "mismatch_rate": mismatch_rate,
        "seq1_length": seq1.count("A") + seq1.count("C") + seq1.count("G") + seq1.count("T") + seq1.count("N"),
        "seq2_length": seq2.count("A") + seq2.count("C") + seq2.count("G") + seq2.count("T") + seq2.count("N"),
        "seq1_gaps": seq1.count("-"),
        "seq2_gaps": seq2.count("-"),
        "seq1_Ns": seq1.count("N"),
        "seq2_Ns": seq2.count("N"),
    }


def write_tsv(out_path: Path | None, header: list[str], row: list[str]) -> None:
    line_header = "\t".join(header) + "\n"
    line_row = "\t".join(row) + "\n"

    if out_path:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with out_path.open("w", encoding="utf-8") as fh:
            fh.write(line_header)
            fh.write(line_row)
    else:
        sys.stdout.write(line_header)
        sys.stdout.write(line_row)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--aln", required=True, help="Path to two-sequence alignment FASTA (.fa/.fasta[.gz])")
    p.add_argument("--out", required=False, default=None, help="Output TSV path; defaults to STDOUT when omitted")
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv)
    aln_path = Path(args.aln)
    out_path = Path(args.out) if args.out else None

    records = read_fasta_two_sequences(aln_path)
    if len(records) != 2:
        raise SystemExit(f"Expected 2 sequences in alignment, found {len(records)}")
    id1, seq1 = records[0]
    id2, seq2 = records[1]
    stats = compute_stats(seq1, seq2)

    header = [
        "seq1_id",
        "seq2_id",
        "alignment_length",
        "comparable_sites",
        "matches",
        "mismatches",
        "mismatch_rate",
        "seq1_length",
        "seq2_length",
        "seq1_gaps",
        "seq2_gaps",
        "seq1_Ns",
        "seq2_Ns",
    ]

    row = [
        id1,
        id2,
        str(stats["alignment_length"]),
        str(stats["comparable_sites"]),
        str(stats["matches"]),
        str(stats["mismatches"]),
        (f"{stats['mismatch_rate']:.6f}" if stats["mismatch_rate"] is not None else "NA"),
        str(stats["seq1_length"]),
        str(stats["seq2_length"]),
        str(stats["seq1_gaps"]),
        str(stats["seq2_gaps"]),
        str(stats["seq1_Ns"]),
        str(stats["seq2_Ns"]),
    ]

    write_tsv(out_path, header, row)


if __name__ == "__main__":
    main()

