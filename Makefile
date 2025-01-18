# Main output targets
all: pdf epub html kindle

# Build the PDF with bibliography
pdf: main.tex
	pdflatex -interaction=nonstopmode main.tex
	-bibtex main
	pdflatex -interaction=nonstopmode main.tex
	pdflatex -interaction=nonstopmode main.tex

# Build ePUB version
epub: pdf
	pandoc main.tex -o book/The-Tao-of-Ansible.epub \
		--toc \
		--toc-depth=3 \
		--epub-cover-image=images/Kindle\ eBook/ebook-cover-1.jpg \
		--metadata title="The Tao of Ansible" \
		--metadata author="John Stilia"

# Build HTML version
html: pdf
	htlatex main.tex "xhtml,charset=utf-8" " -cunihtf -utf8"
	mv main.html book/tao-ansible.html
	mv main.css book/main.css

# Build Kindle version (requires calibre's ebook-convert)
kindle: epub
	ebook-convert book/The-Tao-of-Ansible.epub book/The-Tao-of-Ansible.mobi \
		--output-profile kindle

# Quick build without bibliography
quick: main.tex
	pdflatex -interaction=nonstopmode main.tex

# Clean auxiliary files
clean:
	rm -f *.aux *.log *.out *.toc *.lof *.lot *.bbl *.blg *.fls *.fdb_latexmk *.log
	rm -f *.4ct *.4tc *.idv *.lg *.tmp *.xref *.dvi

# Deep clean - removes all generated files
distclean: clean
	rm -f *.pdf
	rm -f book/*.html book/*.css book/*.epub book/*.mobi

# Watch for changes and rebuild (requires latexmk)
watch:
	latexmk -pvc -pdf main.tex

# Generate only the bibliography
bib:
	bibtex main

# Check dependencies
check-deps:
	@echo "Checking dependencies..."
	@which pdflatex >/dev/null 2>&1 || echo "Missing: pdflatex (texlive)"
	@which pandoc >/dev/null 2>&1 || echo "Missing: pandoc"
	@which htlatex >/dev/null 2>&1 || echo "Missing: htlatex (texlive-extra)"
	@which ebook-convert >/dev/null 2>&1 || echo "Missing: ebook-convert (calibre)"

.PHONY: all pdf epub html kindle quick clean distclean watch bib check-deps