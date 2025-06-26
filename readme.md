# Manuscript of nf-core/viralmetagenome

Jupyter Notebooks can be found in the `analysis` directory, which contains a subset of the pipeline output and the analysis results.

- [analysis/benchmarking/pairwise-globalalignment.ipynb](analysis/benchmarking/pairwise-globalalignment.ipynb)
- [analysis/benchmarking/visualisation.ipynb](analysis/benchmarking/visualisation.ipynb)
- [analysis/nf-core-viralmetagenome/resources.ipynb](analysis/nf-core-viralmetagenome/resources.ipynb)
- [analysis/sequence-download/selection.ipynb](analysis/sequence-download/selection.ipynb)

For reproducibility purposes, run them in a devcontainer.

# Dual-Version Manuscript Setup

This directory contains a LaTeX manuscript setup that can generate two different versions:
1. **bioRxiv preprint version** - formatted for preprint submission
2. **Oxford Bioinformatics journal version** - using the OUP template

## File Structure

### Main Files
- `manuscript-biorxiv.tex` - Main file for bioRxiv version
- `manuscript-oxford.tex` - Main file for Oxford Bioinformatics version
- `Makefile` - Automation for building both versions

### Content Files
- `manuscript-content.tex` - Shared content formatted for OUP template
- `manuscript-content-biorxiv.tex` - Content formatted for bioRxiv

### Supporting Files
- `reference.bib` - Bibliography database (shared between versions)
- `oup-authoring-template.cls` - OUP document class
- `Fig/` - Directory for figures (shared between versions)


# Template
This is OUP's new document class file for typesetting journal articles,
"oup-authoring-template.cls".

oup-authoring-template.cls is based upon the standard LaTeX document class
article.cls. It uses natbib.sty for bibliographical references.

The file manifest.txt provides a list of the files in the oup-authoring-template
bundle.  The following are the main files available:
- oup-authoring-template.tex, Sample template file to start with a new article
- oup-authoring-template.pdf, Sample pdf using the option contemporary, large layout. Please modify the options appropriately in the tex file to get different layouts.
- oup-authoring-template.cls is the class file

The documentation file is oup-authoring-template-doc.tex in the doc directory.  To
compile it:
latex oup-authoring-template-doc.tex

Also, oup-authoring-template-doc.pdf is available in the doc directory.

Copyright 2022 OXFORD UNIVERSITY PRESS.

Documentation and supporting packages are released under the
LATEX Project Public Licence, either version 1.3 or any later
version.