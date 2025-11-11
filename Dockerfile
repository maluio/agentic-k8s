FROM python:3.12-slim

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install uv
ENV PATH=/root/.local/bin:$PATH
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN uv tool install llm

# Install Python packages for LLM tools
RUN pip install --no-cache-dir pyyaml

# Install kubectl with platform detection
RUN ARCH=$(uname -m) && \
    case ${ARCH} in \
        x86_64) ARCH="amd64" ;; \
        aarch64) ARCH="arm64" ;; \
        armv7l) ARCH="arm" ;; \
    esac && \
    curl -fsSL https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

WORKDIR /workspace

CMD ["bash"]
