# Main output targets
all: pdf epub html kindle pdf-with-cover epub-with-cover

# Build the PDF with bibliography
pdf: book/main.tex
	cd book && pdflatex -interaction=nonstopmode main.tex
	cd book && bibtex main
	cd book && pdflatex -interaction=nonstopmode main.tex
	cd book && pdflatex -interaction=nonstopmode main.tex

# Build PDF with cover page
pdf-with-cover: pdf
	cd book && convert ../images/Kindle\ eBook/ebook-cover-1.jpg cover-temp.pdf
	cd book && pdftk cover-temp.pdf main.pdf cat output The-Tao-of-Ansible-with-cover.pdf
	cd book && rm cover-temp.pdf

# Build ePUB version
epub: pdf
	cd book && pandoc main.tex -o The-Tao-of-Ansible.epub \
		--toc \
		--toc-depth=3 \
		--epub-cover-image=../images/Kindle\ eBook/ebook-cover-1.jpg \
		--metadata title="The Tao of Ansible" \
		--metadata author="John Stilia"

# Build ePUB with cover page
epub-with-cover: epub
	cp "images/Kindle eBook/ebook-cover-1.jpg" book/cover.jpg
	cd book && pandoc main.tex -o The-Tao-of-Ansible-with-cover.epub \
		--toc \
		--toc-depth=3 \
		--epub-cover-image=cover.jpg \
		--metadata title="The Tao of Ansible" \
		--metadata author="John Stilia"
	rm -f book/cover.jpg

# Build HTML version
html: pdf
	cd book && htlatex main.tex "xhtml,charset=utf-8" " -cunihtf -utf8"

# Build Kindle version (requires calibre's ebook-convert)
kindle: epub
	cd book && ebook-convert The-Tao-of-Ansible.epub The-Tao-of-Ansible.mobi \
		--output-profile kindle

# Quick build without bibliography
quick: book/main.tex
	cd book && pdflatex -interaction=nonstopmode main.tex

# Clean auxiliary files
clean:
	cd book && rm -f *.aux *.log *.out *.toc *.lof *.lot *.bbl *.blg *.fls *.fdb_latexmk *.log
	cd book && rm -f *.4ct *.4tc *.idv *.lg *.tmp *.xref *.dvi cover-temp.pdf

# Deep clean - removes all generated files
distclean: clean
	cd book && rm -f *.pdf *.html *.css *.epub *.mobi *-with-cover.*

# Watch for changes and rebuild (requires latexmk)
watch:
	cd book && latexmk -pvc -pdf main.tex

# Generate only the bibliography
bib:
	cd book && bibtex main

# Check dependencies
check-deps:
	@echo "Checking dependencies..."
	@which pdflatex >/dev/null 2>&1 || echo "Missing: pdflatex (texlive)"
	@which pandoc >/dev/null 2>&1 || echo "Missing: pandoc"
	@which htlatex >/dev/null 2>&1 || echo "Missing: htlatex (texlive-extra)"
	@which ebook-convert >/dev/null 2>&1 || echo "Missing: ebook-convert (calibre)"
	@which pdftk >/dev/null 2>&1 || echo "Missing: pdftk"
	@which convert >/dev/null 2>&1 || echo "Missing: convert (imagemagick)"
	@which bibtex >/dev/null 2>&1 || echo "Missing: bibtex (texlive)"
	@which latexmk >/dev/null 2>&1 || echo "Missing: latexmk (texlive)"
	@echo "All dependency checks completed."

# Install dependencies on macOS using Homebrew
install-deps-macos:
	@echo "Installing dependencies for macOS..."
	@which brew >/dev/null 2>&1 || { echo "Homebrew is required. Install from https://brew.sh"; exit 1; }
	brew install \
		mactex \
		pandoc \
		pdftk-java \
		imagemagick \
		calibre
	brew tap homebrew/cask && brew install --cask basictex
	sudo tlmgr update --self
	sudo tlmgr install \
		latexmk \
		tex4ht \
		collection-fontsrecommended \
		collection-latexextra
	@echo "macOS dependencies installed. You may need to restart your terminal."

# Install dependencies on Ubuntu/Debian
install-deps-ubuntu:
	@echo "Installing dependencies for Ubuntu..."
	sudo apt-get update
	sudo apt-get install -y \
		texlive-full \
		texlive-xetex \
		texlive-extra-utils \
		pandoc \
		pdftk \
		imagemagick \
		calibre \
		latexmk \
		tex4ht
	@echo "Ubuntu dependencies installed."

.PHONY: all pdf epub html kindle pdf-with-cover epub-with-cover quick clean distclean watch bib check-deps install-deps-macos install-deps-ubuntu