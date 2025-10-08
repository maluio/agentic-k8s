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

# Install kubectl
RUN curl -fsSL https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

WORKDIR /workspace

CMD ["bash"]
