# Makefile for dual-version manuscript compilation
# Usage: make biorxiv, make oxford, or make all

# Variables
LATEX = pdflatex
BIBTEX = bibtex
BIORXIV_MAIN = manuscript-biorxiv
OXFORD_MAIN = manuscript-oxford
SUPP_METHODS = supplementary-methods
BIBFILE = reference.bib

# Default target
all: biorxiv oxford supplementary diff-biorxiv diff-oxford diff-supplementary

# bioRxiv version
biorxiv: $(BIORXIV_MAIN).pdf

$(BIORXIV_MAIN).pdf: $(BIORXIV_MAIN).tex manuscript-content.tex $(BIBFILE)
	$(LATEX) $(BIORXIV_MAIN)
	-$(BIBTEX) $(BIORXIV_MAIN)
	$(LATEX) $(BIORXIV_MAIN)
	$(LATEX) $(BIORXIV_MAIN)

# Oxford Bioinformatics version
oxford: $(OXFORD_MAIN).pdf

$(OXFORD_MAIN).pdf: $(OXFORD_MAIN).tex manuscript-content.tex $(BIBFILE) oup-authoring-template.cls
	$(LATEX) $(OXFORD_MAIN)
	-$(BIBTEX) $(OXFORD_MAIN)
	$(LATEX) $(OXFORD_MAIN)
	$(LATEX) $(OXFORD_MAIN)

# Supplementary Methods
supplementary: $(SUPP_METHODS).pdf

$(SUPP_METHODS).pdf: $(SUPP_METHODS).tex supplementary-methods-content.tex $(BIBFILE)
	$(LATEX) $(SUPP_METHODS)
	-$(BIBTEX) $(SUPP_METHODS)
	$(LATEX) $(SUPP_METHODS)
	$(LATEX) $(SUPP_METHODS)

# Clean auxiliary files
clean:
	rm -f *.aux *.bbl *.blg *.log *.out *.toc *.lof *.lot *.fls *.fdb_latexmk *.synctex.gz

# Clean everything including PDFs
cleanall: clean
	rm -f $(BIORXIV_MAIN).pdf $(OXFORD_MAIN).pdf $(SUPP_METHODS).pdf


# Diff generation
diff: diff-biorxiv diff-oxford diff-supplementary

diff-biorxiv:
	$(LATEX) manuscript-biorxiv-old
	-$(BIBTEX) manuscript-biorxiv-old
	$(LATEX) manuscript-biorxiv-old
	$(LATEX) manuscript-biorxiv
	-$(BIBTEX) manuscript-biorxiv
	$(LATEX) manuscript-biorxiv
	latexdiff -p preamble.tex --flatten manuscript-biorxiv-old.tex manuscript-biorxiv.tex > manuscript-biorxiv-diff.tex
	$(LATEX) manuscript-biorxiv-diff
	-$(BIBTEX) manuscript-biorxiv-diff
	$(LATEX) manuscript-biorxiv-diff
	$(LATEX) manuscript-biorxiv-diff

diff-oxford:
	$(LATEX) manuscript-oxford-old
	-$(BIBTEX) manuscript-oxford-old
	$(LATEX) manuscript-oxford-old
	$(LATEX) manuscript-oxford
	-$(BIBTEX) manuscript-oxford
	$(LATEX) manuscript-oxford
	latexdiff -p preamble.tex --flatten --append-textcmd="abstract" manuscript-oxford-old.tex manuscript-oxford.tex > manuscript-oxford-diff.tex
	$(LATEX) manuscript-oxford-diff
	-$(BIBTEX) manuscript-oxford-diff
	$(LATEX) manuscript-oxford-diff
	$(LATEX) manuscript-oxford-diff

diff-supplementary:
	$(LATEX) supplementary-methods-old
	-$(BIBTEX) supplementary-methods-old
	$(LATEX) supplementary-methods-old
	$(LATEX) supplementary-methods
	-$(BIBTEX) supplementary-methods
	$(LATEX) supplementary-methods
	latexdiff -p preamble.tex --flatten --exclude-textcmd="citep,cite" supplementary-methods-old.tex supplementary-methods.tex > supplementary-methods-diff.tex
	$(LATEX) supplementary-methods-diff
	-$(BIBTEX) supplementary-methods-diff
	$(LATEX) supplementary-methods-diff
	$(LATEX) supplementary-methods-diff

# Word count
wordcount:
	@echo "Word count from PDF (includes references, captions, etc.):"
	@pdftotext $(OXFORD_MAIN).pdf - | wc -w

# Help
help:
	@echo "Available targets:"
	@echo "  all          - Build all versions"
	@echo "  biorxiv      - Build bioRxiv version"
	@echo "  oxford       - Build Oxford Bioinformatics version"
	@echo "  supplementary - Build supplementary methods"
	@echo "  clean        - Remove auxiliary files"
	@echo "  cleanall     - Remove all generated files"
	@echo "  view-biorxiv - Open bioRxiv PDF"
	@echo "  view-oxford  - Open Oxford PDF"
	@echo "  view-supplementary - Open Supplementary Methods PDF"
	@echo "  help         - Show this help"

.PHONY: all biorxiv oxford supplementary clean cleanall view-biorxiv view-oxford view-supplementary help diff diff-biorxiv diff-oxford
