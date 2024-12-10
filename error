# Use a base image with Ubuntu
FROM ubuntu:20.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies (curl, kubectl, helm, etc.)
RUN apt-get update && \
    apt-get install -y \
    curl \
    apt-transport-https \
    ca-certificates \
    sudo \
    bash \
    && apt-get clean

# Download kubectl and set it up
RUN curl -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

# Install Helm
RUN curl -O https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Set the working directory to /scripts
WORKDIR /scripts

# Copy the script.sh and modify-values.sh into the container
COPY setup.sh /scripts/setup.sh
COPY modify-values.sh /scripts/modify-values.sh

# Make the scripts executable
RUN chmod +x /scripts/setup.sh /scripts/modify-values.sh

# Define the entrypoint for the container (you can call setup.sh here)
ENTRYPOINT ["/scripts/setup.sh"]

# Run the script
CMD ["bash"]
