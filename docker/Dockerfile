# Use Ubuntu as base image
FROM ubuntu:22.04

# Add metadata labels
LABEL org.opencontainers.image.source="https://github.com/stiliajohny/The-Tao-of-Ansible"
LABEL org.opencontainers.image.description="Docker image for building The Tao of Ansible book"
LABEL org.opencontainers.image.authors="John Stilia"
LABEL org.opencontainers.image.licenses="MIT"

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN NONINTERACTIVE=1 \
    apt-get update && apt-get install -y \
    texlive-full \
    texlive-xetex \
    texlive-extra-utils \
    pandoc \
    pdftk \
    imagemagick \
    calibre \
    latexmk \
    tex4ht \
    make \
    && apt-get clean \
    && rm -rf /var/cache/apt/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/texlive/* 
# Configure ImageMagick policy to allow PDF operations
RUN sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml

# Set working directory
WORKDIR /workspace

# Default command
CMD ["make", "all"] 