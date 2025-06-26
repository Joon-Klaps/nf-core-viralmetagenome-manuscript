# Makefile for dual-version manuscript compilation
# Usage: make biorxiv, make oxford, or make all

# Variables
LATEX = pdflatex
BIBTEX = bibtex
BIORXIV_MAIN = manuscript-biorxiv
OXFORD_MAIN = manuscript-oxford
BIBFILE = reference.bib

# Default target
all: biorxiv oxford

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

# Clean auxiliary files
clean:
	rm -f *.aux *.bbl *.blg *.log *.out *.toc *.lof *.lot *.fls *.fdb_latexmk *.synctex.gz

# Clean everything including PDFs
cleanall: clean
	rm -f $(BIORXIV_MAIN).pdf $(OXFORD_MAIN).pdf

# Open PDFs (macOS)
view-biorxiv: $(BIORXIV_MAIN).pdf
	open $(BIORXIV_MAIN).pdf

view-oxford: $(OXFORD_MAIN).pdf
	open $(OXFORD_MAIN).pdf

# Help
help:
	@echo "Available targets:"
	@echo "  all          - Build both versions"
	@echo "  biorxiv      - Build bioRxiv version"
	@echo "  oxford       - Build Oxford Bioinformatics version"
	@echo "  clean        - Remove auxiliary files"
	@echo "  cleanall     - Remove all generated files"
	@echo "  view-biorxiv - Open bioRxiv PDF"
	@echo "  view-oxford  - Open Oxford PDF"
	@echo "  help         - Show this help"

.PHONY: all biorxiv oxford clean cleanall view-biorxiv view-oxford help
