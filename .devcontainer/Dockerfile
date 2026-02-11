FROM mcr.microsoft.com/devcontainers/cpp:ubuntu-24.04

COPY setup-linux.sh /tmp/setup-linux.sh

# Enable universe and install build dependencies for Yakety
RUN /tmp/setup-linux.sh \
    && apt-get autoremove -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
