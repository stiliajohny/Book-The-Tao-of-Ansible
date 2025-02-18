# Docker configuration
DOCKER_IMAGE := tao-ansible-builder
DOCKER_TAG ?= latest
DOCKER_WORKDIR := /workspace
DOCS_DIR := $(PWD)/docs

# GitHub Container Registry configuration
GHCR_REGISTRY := ghcr.io
DOCKER_REGISTRY ?= $(GHCR_REGISTRY)
DOCKER_OWNER := stiliajohny
DOCKER_REPO := $(DOCKER_REGISTRY)/$(DOCKER_OWNER)/$(DOCKER_IMAGE)
DOCKER_RUN := docker run --rm -v $(PWD):$(DOCKER_WORKDIR) -v $(DOCS_DIR):/docs -w $(DOCKER_WORKDIR) $(DOCKER_REPO):$(DOCKER_TAG)

# Git version information
GIT_SHA := $(shell git rev-parse --short HEAD)
GIT_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "v0.1.0")

# Main output targets
all: docker-build pdf epub html kindle pdf-with-cover epub-with-cover ## Build all formats (PDF, EPUB, HTML, Kindle)

# Docker targets
docker-build: ## Build the Docker image
	@echo "Building Docker image..."
	docker build \
		-t $(DOCKER_IMAGE):$(DOCKER_TAG) \
		-f docker/Dockerfile .
	@echo "Tagging Docker image for GHCR..."
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_REPO):$(DOCKER_TAG)
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_REPO):$(GIT_TAG)
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_REPO):$(GIT_SHA)

docker-all: ## Run all build commands inside Docker
	$(DOCKER_RUN) make pdf epub html kindle pdf-with-cover epub-with-cover

docker-clean: ## Clean Docker images and temporary files
	$(DOCKER_RUN) make clean
	docker rmi $(DOCKER_REPO):$(DOCKER_TAG) || true
	docker rmi $(DOCKER_REPO):$(GIT_TAG) || true
	docker rmi $(DOCKER_REPO):$(GIT_SHA) || true

# Docker publish targets
docker-login: ## Login to GitHub Container Registry
	@echo "Logging into GitHub Container Registry..."
	@if [ -z "$$CR_PAT" ]; then \
		echo "Error: CR_PAT environment variable is not set"; \
		echo "Please run: read CR_PAT"; \
		echo "Then paste your GitHub Personal Access Token"; \
		exit 1; \
	fi
	@echo "$$CR_PAT" | docker login ghcr.io -u $(DOCKER_OWNER) --password-stdin

docker-push: docker-build docker-login ## Push Docker image to GitHub Container Registry
	@echo "Publishing Docker image to $(DOCKER_REPO)..."
	docker push $(DOCKER_REPO):$(DOCKER_TAG)
	docker push $(DOCKER_REPO):$(GIT_TAG)
	docker push $(DOCKER_REPO):$(GIT_SHA)

# Version information
version: ## Display version information
	@echo "Version: $(GIT_TAG)"
	@echo "Commit: $(GIT_SHA)"
	@echo "Docker Image: $(DOCKER_REPO):$(DOCKER_TAG)"

# Build the PDF with bibliography
pdf: docker-build ## Build the PDF with bibliography
	$(DOCKER_RUN) bash -c "cd book && pdflatex -interaction=nonstopmode main.tex && \
		bibtex main && \
		pdflatex -interaction=nonstopmode main.tex && \
		pdflatex -interaction=nonstopmode main.tex && \
		mv main.pdf /docs/The-Tao-of-Ansible.pdf"

# Build PDF with cover page
pdf-with-cover: pdf ## Build PDF with cover page
	$(DOCKER_RUN) bash -c "cd book && convert ../images/Kindle\ eBook/ebook-cover.jpg cover-temp.pdf && \
		pdftk cover-temp.pdf /docs/The-Tao-of-Ansible.pdf cat output /docs/The-Tao-of-Ansible-with-cover.pdf && \
		rm cover-temp.pdf"

# Build ePUB version
epub: pdf ## Build ePUB version
	$(DOCKER_RUN) bash -c "cd book && pandoc main.tex -o /docs/The-Tao-of-Ansible.epub \
		--toc \
		--toc-depth=3 \
		--epub-cover-image=../images/Kindle\ eBook/ebook-cover.jpg \
		--metadata title='The Tao of Ansible' \
		--metadata author='John Stilia'"

# Build ePUB with cover page
epub-with-cover: epub ## Build ePUB with cover page
	$(DOCKER_RUN) bash -c "cp images/Kindle\ eBook/ebook-cover.jpg book/cover.jpg && \
		cd book && pandoc main.tex -o /docs/The-Tao-of-Ansible-with-cover.epub \
		--toc \
		--toc-depth=3 \
		--epub-cover-image=cover.jpg \
		--metadata title='The Tao of Ansible' \
		--metadata author='John Stilia' && \
		rm -f cover.jpg"

# Build HTML version
html: pdf ## Build HTML version
	$(DOCKER_RUN) bash -c "cd book && htlatex main.tex 'xhtml,charset=utf-8' ' -cunihtf -utf8' && \
		mv main.html /docs/index.html && \
		mv *.css /docs/"

# Build Kindle version (requires calibre's ebook-convert)
kindle: epub ## Build Kindle version (requires calibre's ebook-convert)
	$(DOCKER_RUN) bash -c "cd book && ebook-convert /docs/The-Tao-of-Ansible.epub /docs/The-Tao-of-Ansible.mobi \
		--output-profile kindle"

# Quick build without bibliography
quick: book/main.tex ## Quick build without bibliography
	cd book && pdflatex -interaction=nonstopmode main.tex

# Clean auxiliary files
clean: ## Clean auxiliary files
	cd book && rm -f *.aux *.log *.out *.toc *.lof *.lot *.bbl *.blg *.fls *.fdb_latexmk *.log
	cd book && rm -f *.4ct *.4tc *.idv *.lg *.tmp *.xref *.dvi cover-temp.pdf

# Deep clean - removes all generated files
distclean: clean ## Deep clean - removes all generated files
	cd book && rm -f *.pdf *.html *.css *.epub *.mobi *-with-cover.*

# Watch for changes and rebuild (requires latexmk)
watch: ## Watch for changes and rebuild (requires latexmk)
	cd book && latexmk -pvc -pdf main.tex

# Generate only the bibliography
bib: ## Generate only the bibliography
	cd book && bibtex main

# Check dependencies
check-deps: ## Check dependencies
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

# Install dependencies commands are now handled by Dockerfile
install-deps-ubuntu: ## Install dependencies on Ubuntu (handled by Dockerfile)
	@echo "Please use 'make docker-build' instead. Dependencies are managed in the Dockerfile."

install-deps-macos: ## Install dependencies on macOS (handled by Dockerfile)
	@echo "Please use 'make docker-build' instead. Dependencies are managed in the Dockerfile."

# Help target
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: all pdf epub html kindle pdf-with-cover epub-with-cover quick clean distclean watch bib docker-build docker-all docker-clean docker-login docker-push version help