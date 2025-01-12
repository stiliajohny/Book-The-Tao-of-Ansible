# Main output target
all: book

# Build the PDF with bibliography
book: main.tex
	pdflatex -interaction=nonstopmode main.tex
	-bibtex main
	pdflatex -interaction=nonstopmode main.tex
	pdflatex -interaction=nonstopmode main.tex

# Quick build without bibliography
quick: main.tex
	pdflatex -interaction=nonstopmode main.tex

# Clean auxiliary files
clean:
	rm -f *.aux *.log *.out *.toc *.lof *.lot *.bbl *.blg *.fls *.fdb_latexmk *.log

# Deep clean - removes PDF and all auxiliary files
distclean: clean
	rm -f *.pdf

# Watch for changes and rebuild (requires latexmk)
watch:
	latexmk -pvc -pdf main.tex

# Generate only the bibliography
bib:
	bibtex main

.PHONY: all book quick clean distclean watch bib